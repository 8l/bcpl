// This is the BCPL translation of a Simula-67 program given on
// pages 304 to 311 of "Simula BEGIN" by Birtwistle, G.M. et al

// Martin Richards  (c) 13 July 2000

// This version is based on airport.b, but uses an object oriented
// style of programming.

/******** STILL UNDER DEVELOPMENT ******************/

/*
The airport has:

Checkin1 with 2 clerks 1 telephone for charter passengers
Checkin2 with 4 clerks 1 telephone for other passengers
Bank with 1 clerk
Kiosk with 2 clerks
Passport control with 1 clerk
IntLobby   for charter and international passengers
DomLobby   for domestic passengers

Passengers spend between 2 and 4 minutes (uniformly distributed)
with a checkin clerk plus 1 minute for a confirmation telephone
call. There is only one telephone per checkin and so the clerk
may have to wait for it to become free.

Kiosk clerks take between 1 and 2 minutes (uniformly distributed).

The bank clerk takes exactly 3 minutes, and the passport control clerk
take between 1 and 3 minutes (uniformly distributed).

There are three type of passenger, charter, domestic and international.
They take the following routes:

charter:       checkin1,
               bank(optional, 70%),
               passportcontrol,
               intlobby

domestic:      checkin2,
               bank(optional, 20%),
               kiosk(optional, 50%),
               domlobby

international: checkin2,
               bank(optional, 20%),
               kiosk(optional, 50%),
               passportcontrol,
               intlobby

The gap between       charter passengers is NegExp(0.25)
The gap between      domestic passengers is NegExp(0.25)
The gap between international passengers is NegExp(0.20)

A report is generated every 200 minutes

In this implementation time is measure in milli-minutes,
so 1.0 minute is represented by 1000.
*/

GET "libhdr"

GLOBAL {

 tracing:ug

 // statistics
 totalflowin; totalflowout; timespent

 // Object instances
 blks            // Event block allocator
 sim             // The priority queue and scheduling
 rand            // The random number generators

 checkin1        // Checkin for charter passengers
 checkin2        // Checkin for dom or int passengers
 telephone1      // Telphone used by clerks of checkin 1
 telephone2      // Telphone used by clerks of checkin 2
 bank            // The bank with one clerk
 kiosk           // The kiosk with two clerks
 passport        // Passport control with 1 clerk

 // Coroutines
 domgen; chartgen; intgen  // Passenger generators
 intlobby; domlobby        // Passenger removal coroutines
 report                    // Report generator

 // The passenger coroutines are dynamically created and deleted

}

MANIFEST { 
Passportclerks = 1
Bankclerks     = 1
Kioskclerks    = 2
Tels1          = 1
Chk1clerks     = 2
Tels2          = 1
Chk2clerks     = 4
}

/****************** The object: Blks **************************/

/*
This object implements the allocation of event blocks.

Its constructor and destructor functions are mkBlks() and
freeBlks(blks), respectively.

Its methods are:

InitObj#(blks, size)    Initialise the event block allocator.
CloseObj#(blks)         Close the event block allocator.
MkBlk#(blks, nxt, t, c) Allocate an event block.
FreeBlk#(blks, b)       Free an event block.

Its fields are:

Spacev       Space for blocks.
Spacep       Position of next unused location in spacev.
Spacet       The size of spacev
Freelist     List of free blocks

Constants:

BlksFnsUpb   Upb of the methods vector
BlksUpb      Upb of the fields vector
*/

MANIFEST {

  MkBlk=2; FreeBlk                    // Methods
  BlksFnsUpb=FreeBlk

  Spacev=1; Spacep; Spacet; Freelist  // Fields
  BlksUpb=Freelist

  S_nxt=0; S_t; S_c  // Selectors  for fields in blocks
}

LET mkBlks(size) = VALOF
{ LET fns = getvec(BlksFnsUpb)
  fns!InitObj  := initblks
  fns!CloseObj := closeblks
  fns!MkBlk    := mkblk
  fns!FreeBlk  := freeblk
  RESULTIS mkobj(BlksUpb, fns, size)
}

AND freeBlks(r) BE
{ CloseObj#(r)
  freevec(!r)       // free the methods vector
  freevec(r)        // Free the fields vector
}

AND initblks(r, args) BE
{ LET size = args!0
  r!Spacev := getvec(size)
  r!Spacep, r!Spacet := 0, size
  r!Freelist := 0
}

AND closeblks(r) BE freevec(r!Spacev)

AND mkblk(r, nxt, t, c) = VALOF
{ LET p = r!Freelist
  TEST p
  THEN r!Freelist := S_nxt!p
  ELSE { LET sv, sp, st = r!Spacev, r!Spacep, r!Spacet
         p := @sv!sp
         sp := sp+3
         IF sp>st DO
         { writef("mkblk: Insufficient space %n*n", st)
           abort(999)
           stop(0)
         }
         r!Spacep := sp
       }
  S_nxt!p, S_t!p, S_c!p := nxt, t, c
  RESULTIS p
}

AND freeblk(r, p) BE
{ S_nxt!p := r!Freelist
  r!Freelist := p
}


/******************  The object: Sim  **************************/

/*
This object implements the discrete event priority queue and
scheduling primitives. 

Its constructor and destructor functions are mkSim() and
freeSim(sim), respectively.

Its methods are:

InitObj#(sim)          Initialise the priority queue.
CloseObj#(sim)         Close the priority queue.
PutEvent#(sim, e)      Put an event into the priority queue.
e := GetEvent#(sim)    Get the earliest event from the priority queue.
e := Schedule#(sim)    Suspend the current coroutine until
                       reactivated by an event.
Hold#(sim, t)          Suspend current coroutine until time t.
Activate#(sim, c)      Activate coroutine c.
Activateat#(sim, c, t) Activate coroutine c at time t.
Downheap#(sim, e)      Insert an event into the root of the heap.
Upheap#(sim, e, i)     Insert an event at the end of the heap.
Pr#(sim)               Output the events in heap.

Its fields are:

Heap        The heap holding the scheduled events
Heapn       The number of events in the heap
Heapt       The size of heap
Simperiod   The simulation end time
Time        The current simulated time

Constants:

SimFnsUpb
SimUpb
*/

MANIFEST {

  PutEvent=2; GetEvent                     // Methods
  Schedule; Hold; Activate; Activateat
  Downheap; Upheap; Pr
  SimFnsUpb=Pr

  Heap=1; Heapn; Heapt                     // Fields
  Simperiod; Time
  SimUpb=Time
}

LET mkSim(size, simperiod) = VALOF
{ LET fns = getvec(SimFnsUpb)
  fns!InitObj    := initsim
  fns!CloseObj   := closesim
  fns!PutEvent   := putevent
  fns!GetEvent   := getevent
  fns!Schedule   := schedule
  fns!Hold       := hold
  fns!Activate   := activate
  fns!Activateat := activateat
  fns!Downheap   := downheap
  fns!Upheap     := upheap
  fns!Pr         := pr
  RESULTIS mkobj(SimUpb, fns, size, simperiod)
}

AND freeSim(r) BE
{ CloseObj#(r)
  freevec(!r)       // free the methods vector
  freevec(r)        // Free the fields vector
}

AND initsim(r, args) = VALOF
{ LET size, simperiod = args!0, args!1
  r!Heap := getvec(size)
  r!Heapn, r!Heapt := 0, size
  r!Simperiod := simperiod
  r!Time := 0
}

AND closesim(r) BE IF r!Heap DO freevec(r!Heap)

AND schedule(r) = VALOF
{ LET e = GetEvent#(r)
  LET cptr = ?
  UNLESS e DO cowait() // No events left -- return to main program
  r!Time, cptr := S_t!e, S_c!e
  FreeBlk#(blks, e)
  IF r!Time>r!Simperiod DO cowait() // Return to main program
  RESULTIS resumeco(cptr)
}

// Suspend the current coroutine until time t
AND hold(r, t) BE
{ Activateat#(r, currco, t)
  Schedule#(r)
}

// Activate coroutine cptr to run now.
AND activate(r, cptr) BE PutEvent#(r, MkBlk#(blks, 0, r!Time, cptr))

// Activate coroutine cptr to run at time t.
AND activateat(r, cptr, t) BE PutEvent#(r, MkBlk#(blks, 0, t, cptr))

// Heap implementation of the priority queue
AND getevent(r) = VALOF
{ LET heap, n = r!Heap, r!Heapn
  LET e = heap!1
  UNLESS n RESULTIS 0  // If no more events
  // heap!1 is now empty
  r!Heapn := n-1
  Downheap#(r, heap!n)
  RESULTIS e
}

// Insert an event into the priority queue
// The event's delay must be less than maxint/2
AND putevent(r, e) BE
{ LET n = r!Heapn + 1
  r!Heapn := n
  Upheap#(r, e, n)
}

// Insert an event into the priority queue
// The event's delay must be less than maxint/2
// (note the time comparisons)
AND downheap(r, e) BE
{ LET v, i, n = r!Heap, 1, r!Heapn

  { LET j = i+i                       // pos of left son
    IF j<n DO                         // Test if there are 2 sons
    { LET p = v+j
      LET x = p!0                     // The left son
      LET y = p!1                     // The other son
      TEST S_t!x - S_t!y < 0          // Promote earlier son
      THEN { v!i := x; i := j   }
      ELSE { v!i := y; i := j+1 }
      LOOP
    }
    IF j=n DO { v!i := v!j; i := j }  // Promote only son
    Upheap#(r, e, i)
    RETURN
  } REPEAT
}

// Insert an event into the priority queue
// The event's delay must be less than maxint/2
// (note the time comparisons)
AND upheap(r, e, i) BE
{ LET v = r!Heap
  LET t = S_t!e                   // The event's time
  WHILE i>1 DO
  { LET p = i/2                   // Position of parent
    LET vp = v!p
    // v!i is currently empty
    IF S_t!vp - t <= 0 BREAK
    v!i := vp                     // Demote parent
    i := p
  }

  v!i := e
}

AND pr(r) BE
{ LET v = r!Heap
  FOR i = 1 TO r!Heapn DO
  { LET e = v!i
    writef(" %i6/%i5", S_t!e, S_c!e)
    IF i REM 5 = 0 DO newline()
  }
  newline()
}



/****************** The object: Rand **************************/

/*
This object contains various random number generators.

Its constructor and destructor functions are:

mkRand(seed)
freeRand(obj)

Its methods are:

InitObj#(obj)     Initialise the generators.
CloseObj#(obj)    Close the object.
Rnd#(obj)         Return a uniformly distributed number in the
                  range 0 to #x7FFFFFFF, using a congruential
                  method.
Uniform#(obj,a,b) Return a uniformly distributed number in the
                  range a to b.
Draw#(obj,percentage)
                  Return TRUE or FALSE with TRUE occurring the
                  given percentage of times.
Negexp#(obj)      Return the a random deviate from the exponential
                  distribution with a mean of 1.0. The result is in
                  a fixed point scaled number with 1.0 represented
                  by 1000000. It is based on the algorithm given on
                  page 128 of Knuth, Art of Programming, Vol 2.

Its fields are:

Q         Vector of Q values
Ln2       Ln 2 in scaled arithmetic
Seed      The seed for Rnd

Constants

One       = 1000000 the scaling factor for Negexp.
*/

MANIFEST {

  Rnd=2; Uniform; Draw; Negexp          // Methods

  Q=1; Ln2; Seed                        // Fields
  Randupb=Seed

  One=1000000                           // Constants
}

LET mkRand(seed) = VALOF
{ LET fns = TABLE 0,0,0,0,0,0,0
  fns!InitObj  := initrnd
  fns!CloseObj := closernd
  fns!Rnd      := rnd
  fns!Uniform  := uniform
  fns!Draw     := draw
  fns!Negexp   := negexp
  RESULTIS mkobj(Randupb, fns, seed)
}

AND freeRand(r) BE
{ CloseObj#(r)
  freevec(r)
}

AND initrnd(r, args) = VALOF
{ r!Seed    := args!0
  FOR i = 1 TO 10 DO Rnd#(r)
  r!Q := TABLE 0,
               #x58b90bfb, // 0.693147181
               #x7778c9fa, // 0.933373688
               #x7e938c30, // 0.988877796
               #x7fceb6e7, // 0.998495925
               #x7ffa67e6, // 0.999829281
               #x7fff740b, // 0.999983316
               #x7ffff3fe, // 0.999998569
               #x7fffff14, // 0.999999891
               #x7fffffee, // 0.999999992
               #x7ffffffd  // 1.000000000
  r!Ln2 := muldiv(One, #x58b90bfb, maxint) // ln 2.0
}

AND closernd(r) BE RETURN

AND rnd(r) = VALOF {
  r!Seed := 2147001325 * r!Seed + 715136305
  RESULTIS r!Seed & #x7fffffff
}

AND uniform(r, a, b) = VALOF
{ LET w = rnd(r)
  RESULTIS a + w REM (b-a+1)
}

// draw returns TRUE for the given percentage of times
AND draw(r, percentage) = uniform(r, 0, 100) <= percentage

AND negexp(r) = VALOF // Exponential distribution mean 1.0
{ LET u = rnd(r)
  LET q = r!Q
  LET v, w = ?, ?
  LET j = 0

  { u := u<<1
    IF u>=0 BREAK
    j := j+1
  } REPEAT

  IF u<q!1 RESULTIS j*r!Ln2 + muldiv(One, u, maxint)

  v := rnd(r)
  FOR i = 2 TO 10 DO
  { LET w = rnd(r)
    IF v>=w DO v := w
    IF u<q!i BREAK
  }

  RESULTIS muldiv(r!Ln2, (j*One+muldiv(One, v, maxint)), One)  
}

/******************** End of Rand ***************************/


/******************** Scaled Number Output ******************/
 
// Print in width w, f digits after decimal point
// x is scales so that 1.0 is 1000000 (One)
AND prnum(x, w, f) BE
{ LET px = ABS x
  IF f<0 DO f := 0
  IF f>6 DO f := 6
  IF f<6 DO
  { LET r = 5
    FOR i = f TO 4 DO r := r*10
    px := px + r  // Round up, if necessary
  }
  wripart(px/One, w-f-1, x<0) // output the integer part

  FOR i = f TO 5 DO px := px/10

  wrch('.')                   // output the fractional part
  wrfpart(px, f)
}

AND wripart(x, w, neg) BE
{ IF x < 10 DO
  { IF neg DO w := w-1
    FOR i = 2 TO w DO wrch(' ')
    IF neg DO wrch('-')
    wrch(x+'0')
    RETURN
  }
  wripart(x/10, w-1, neg)
  wrch(x REM 10 + '0')
}

AND wrfpart(x,n) BE
{ IF n>1 DO wrfpart(x/10, n-1)
  IF n>0 DO wrch(x REM 10 + '0')
}

/************** End of Scaled Number Output ******************/



/****************** Object: Qda  *****************************/

/*
This implement an activity served by a number of service providers.
When all the service providers are busy, activity requests are held
in a FIFO queue. Statistics are maintained about the queue length,
the maximum queue length, and how busy each service provider has
been. This information can be output using the Report method.

The constructor and destructor functions are:

act := mkQda(name, n, actfn)
     Create a new queued activity object, where
     name  is the name of the queue,
     n     is the number of service providers (clerks or telephones),
     actfn is the function to simulate the activity to be done with
           a service provider.

freeQda(obj)
     Free a queued activity object.

The methods are:

InitObj#(r, args)   Initialise a new queued activity
CloseObj#(r)        Close down a queued activity
EnterQda#(r)        Simulate entering a queued activity
ReportQda#(r)       Output the statistics of this queued activity
Actfn#(r, provider) Simulate the activity with the given provider 

Variables:

Name              The queue name, a string
Providers         The number of providers (clerks or telephones)
Providersfree     Bit pattern indicating which providers are free
Queue             The queue of current requests
Qlen              The current queue length
Maxqlen           The maximum queue length so far
Usedv             Vector of time used by each provider
Servedv           Vector holding throughput of each provider
TotalServed       Total throughput
Telephone         The telephone, if any

Constants:

QdaFnsUpb         Upperbound of the fns vector
QdaUpb            Upperbound of the fields vector
*/

MANIFEST {
  EnterQda=2; ReportQda; Actfn; QdaFnsUpb=Actfn

  Name=1; Providers; Providersfree; Queue; Qlen; Maxqlen
  Usedv; Servedv; TotalServed; Telephone; QdaUpb=Telephone
}

LET mkQda(name, n, actfn, phone) = VALOF  // The constructor
{ LET fns = getvec(QdaFnsUpb)
  fns!InitObj   := initQda
  fns!CloseObj  := closeQda
  fns!EnterQda  := enterQda
  fns!ReportQda := reportQda
  fns!Actfn     := actfn      // The activity function for this Qda
  RESULTIS mkobj(QdaUpb, fns, name, n, phone)
}

AND freeQda(r) BE                  // The destructor
{ CloseObj#(r)
  freevec(r!0)  // Free the methods vector
  freevec(r)    // Free the fields vector
}

AND initQda(r, args) BE
{ LET n = args!1
  r!Name := args!0
  r!Providers := n
  r!Providersfree := 0
  r!Queue := 0
  r!Qlen, r!Maxqlen := 0, 0
  r!Usedv   := getvec(n)
  r!Servedv := getvec(n)
  r!TotalServed := 0
  FOR i = 1 TO n DO
  { setfree(@r!Providersfree, i)
    r!Usedv!i, r!Servedv!i := 0, 0
  }
  r!Telephone := args!2
}

AND closeQda(r) BE
{ freevec(r!Usedv)  // Free the space allocated by initQda
  freevec(r!Servedv)
}

AND enterQda(r) BE
{ LET provider = selectfree(@r!Providersfree)
  IF provider DO          // Is a provider free?
  { LET t0 = sim!Time  // t0 = time the provider starts work
    LET usedv = r!Usedv
    LET servedv = r!Servedv

    Actfn#(r, provider)   // Simulate the activity with this provider

    // Gather statistics
    usedv!provider := usedv!provider + sim!Time - t0
    servedv!provider := servedv!provider + 1
    r!TotalServed := r!TotalServed+1

    setfree(@r!Providersfree, provider) // This provider is now free
    IF r!Queue DO                // Activate next queue item, if any
    { LET e = dequeue(@r!Queue)
      r!Qlen := r!Qlen-1
      Activate#(sim, S_c!e)   // Schedule the item to run now
      FreeBlk#(blks, e)
    }
    RETURN
  }
  IF tracing DO writef("%i7: passenger %n joins %s queue*n",
                       sim!Time, currco, r!Name)
  r!Qlen := r!Qlen+1
  IF r!Maxqlen<r!Qlen DO r!Maxqlen := r!Qlen
  appendblk(@r!Queue, 0, currco) // Put passenger in the queue
  Schedule#(sim)              // Wait until a provider is free
} REPEAT                         // Try again to service this passenger


AND reportQda(r) BE
{ writef("*n**** Statistics for %s*n", r!Name)
  writef("No. of customers served  = %i6*n", r!TotalServed)
  writef("No. of customers waiting = %i6*n", r!Qlen)
  writef("Max. queue length        = %i6*n", r!Maxqlen)
  writef("    Provider activities*n")
  writef("Clerk/ %% use /Busy/Served*n")
  FOR i = 1 TO r!Providers DO
  { writef("    %n  ", i )
    prnum(muldiv(r!Usedv!i,100*One, sim!Time), 5, 2)
    writes(isfree(@r!Providersfree, i) -> "   No", "  Yes")
    writef("%i6*n", r!Servedv!i)
  }
}

// Providers (clerks or telephones) have bits patterns to indicate
// which are free. The bits are numbered from 1 to 32 from the
// least significant end. A provider is free if its bit is a one.

AND setfree(p, n) BE !p := !p | (1 << n-1)

AND isfree(p, n)  = (!p & (1 << n-1)) ~= 0

AND setbusy(p, n) BE !p := !p & ~(1 << n-1)

AND selectfree(p) = VALOF
{ LET bits, bit, n = !p, 1, 1
  UNLESS bits RESULTIS 0   // Indicating that no provider is free.
  WHILE (bits&bit)=0 DO bit, n := bit<<1, n+1
  !p := bits - bit
  RESULTIS n               // The number of a free provider.
}

AND dequeue(p) = VALOF
{ LET blk = !p
  IF blk DO !p := S_nxt!blk
  RESULTIS blk
}

AND appendblk(p, t, c) BE
{ WHILE !p DO p := !p  // Find the end of the list
  !p := MkBlk#(blks, 0, t, c) // Append a block
}

AND prq(q) BE
{ LET k = 0
  WHILE q DO
  { writef(" %i5", S_c!q)
    k := k+1
    IF k REM 10 = 0 DO newline()
    q := S_nxt!q
  }
  newline()
}

/******************  End of QdActivity  **************************/


LET bankact(r, provider) BE
{ LET delay = 3000 // Bank service time = 3.0 minutes
  IF tracing DO
    writef("%i7: passenger %n being served at the bank until %n*n",
            sim!Time, currco, sim!Time+delay)
  Hold#(sim, sim!Time+delay)
  IF tracing DO
    writef("%i7: passenger %n leaves the bank*n", sim!Time, currco)
}

AND kioskact(r, provider) BE
{ // The kiosk has two clerks
  // they take between 1.0 and 2.0 minutes per passenger
  LET delay = Uniform#(rand, 1000, 2000)
  IF tracing DO
    writef("%i7: passenger %n being served at kiosk until %n*n",
            sim!Time, currco, sim!Time+delay)
  Hold#(sim, sim!Time+delay)            // Hold self for delay period
  IF tracing DO
    writef("%i7: passenger %n leaves the kiosk*n", sim!Time, currco)
}

AND telephoneact(r, provider) BE
{ // Telephone calls take exactly 1.0 minute
  LET delay = 1000  // Telephone calls take exactly 1.0 minutes
  IF tracing DO
    writef("%i7: passenger %n using %s until %n*n",
            sim!Time, currco, r!Name, sim!Time+delay)
  Hold#(sim, sim!Time+delay)           // Hold self for delay period
  IF tracing DO writef("%i7: passenger %n finished with %s*n",
                       sim!Time, currco, r!Name)
}

AND passportact(r, clerk) BE
{ // similar to bank but hold for 1.0 to 3.0 minutes
  LET delay = Uniform#(rand, 1000, 3000)  // Delay from 1.0 to 3.0 minutes
  IF tracing DO
    writef("%i7: passenger %n at %s until %n*n",
            sim!Time, currco, r!Name, sim!Time+delay)
  Hold#(sim, sim!Time+delay) //    hold self for 1.0 to 3.0 minutes
  IF tracing DO
    writef("%i7: passenger %n leaves %s*n",
            sim!Time, currco, r!Name)
}

AND checkinact(r, clerk) BE
{ // hold for 2.0 to 4.0 minutes
  // wait for telephone
  // hold for 1.0 minutes
  LET delay = Uniform#(rand, 2000, 4000)  // Delay of 2.0 to 4.0 minutes
  IF tracing DO
    writef("%i7: passenger %n with %s clerk %n*n",
            sim!Time, currco, r!Name, clerk)
  Hold#(sim, sim!Time+delay)
  EnterQda#(r!Telephone)
  IF tracing DO
    writef("%i7: passenger %n leaves %s*n", sim!Time, currco, r!Name)
}


AND dompassengerfn(args) BE
{ // initialise
  cowait()

  { LET literate  = Draw#(rand, 50) // 50%
    LET penniless = Draw#(rand, 20) // 20%
    LET timein = sim!Time
    totalflowin := totalflowin + 1
    IF tracing DO writef("%i7: new domestic passenger %n*n",
                          sim!Time, currco)
    EnterQda#(checkin2)
    IF penniless DO EnterQda#(bank)
    IF literate  DO EnterQda#(kiosk)
    totalflowout := totalflowout + 1
    timespent := timespent + sim!Time - timein
    resumeco(domlobby, currco)         // Deletes this coroutine
    writef("dompassenger: error*n")
    abort(999)
  }
}

AND intpassengerfn(args) BE
{ // initialise
  cowait()

  { LET literate  = Draw#(rand, 50) // 50%
    LET penniless = Draw#(rand, 20) // 20%
    LET timein = sim!Time
    totalflowin := totalflowin + 1
    IF tracing DO writef("%i7: new international passenger %n*n",
                          sim!Time, currco)
    EnterQda#(checkin2)
    IF penniless DO EnterQda#(bank)
    IF literate  DO EnterQda#(kiosk)
    EnterQda#(passport)
    totalflowout := totalflowout + 1
    timespent := timespent + sim!Time - timein
    resumeco(intlobby, currco)         // Deletes this coroutine
    writef("intpassenger: error*n")
    abort(999)
  }
}

AND chapassengerfn(args) BE
{ // initialise
  cowait()

  { LET penniless = Draw#(rand, 70) // 70%
    LET timein = sim!Time
    totalflowin := totalflowin + 1
    IF tracing DO writef("%i7: new charter passenger %n*n", 
                          sim!Time, currco)
    EnterQda#(checkin1)
    IF penniless DO EnterQda#(bank)
    EnterQda#(passport)
    totalflowout := totalflowout + 1
    timespent := timespent + sim!Time - timein
    resumeco(intlobby, currco)         // Deletes this coroutine
    writef("chapassenger: error*n")
    abort(999)
  }
}

AND lobbyfn(args) BE
{ LET lobbyname = args!0
  LET passenger = cowait()  // Wait to be resumeco-ed

  { IF tracing DO writef("%i7: passenger %n leaves via %s lobby*n",
                        sim!Time, passenger, lobbyname)
    deleteco(passenger)
    IF tracing DO
      writef("%i7: passenger %n deleted*n", sim!Time, passenger)
    passenger := Schedule#(sim)
  } REPEAT
}

AND reportfn(args) BE
{ LET period = args!0
  cowait()      // Wait to be activated

  { Hold#(sim, sim!Time + period)
    newline()
    writef("Status Report at time               = %i9*n", sim!Time/1000)
    FOR i = 1 TO 47 DO wrch('**')
    writes("*n*n")
    writef("No. of customers who have entered   = %i9*n", totalflowin)
    writef("No. of customers through the system = %i9*n", totalflowout)
    IF totalflowout=0 DO totalflowout := 1
    writef("Av. Total time spent by customers   = ")
      prnum(muldiv(One, timespent, totalflowout*1000), 9, 3)
    newline()

    ReportQda#(passport)
    ReportQda#(bank)
    ReportQda#(kiosk)
    ReportQda#(checkin1)
    ReportQda#(checkin2)
  } REPEAT
}

// Customer generators
AND charterfn() BE
{ // do initialisation
  cowait()       // Wait to be activated

  { // hold for negexp time mean 4 minutes
    LET delay = muldiv(4000, Negexp#(rand), One)
    Hold#(sim, sim!Time+delay)
    // activate new charter passenger
    Activate#(sim, initco(chapassengerfn, 200))
  } REPEAT
}

AND domesticfn() BE
{ // do initialisation
  cowait()       // Wait to be activated

  { // hold for negexp time mean 5 minutes
    LET delay = muldiv(5000, Negexp#(rand), One)
    Hold#(sim, sim!Time+delay)
    // activate new domestic passenger
    Activate#(sim, initco(dompassengerfn, 200))
  } REPEAT
}

AND internationalfn() BE
{ // do initialisation
  cowait()       // Wait to be activated

  { // hold for negexp time mean 4 minutes
    LET delay = muldiv(4000, Negexp#(rand), One)
    Hold#(sim, sim!Time+delay)
    // activate new international passenger
    Activate#(sim, initco(intpassengerfn, 200))
  } REPEAT
}

AND start() = VALOF
{ LET argv = VEC 50
  LET stdout = output()
  LET tostream = 0
  LET seed = 0
  LET simperiod = 200*1000 // Simulation period in Milli-minutes
  LET repperiod = simperiod


  UNLESS rdargs("-p,-r/k,-t/s,-s/k,-o/k", argv, 50) DO
  { writef("Bad arguments for airport*n")
    RESULTIS 0
  }

  IF argv!0 DO simperiod := str2numb(argv!0)*1000  // -p n
  IF argv!1 DO repperiod := str2numb(argv!1)*1000  // -r n
  IF repperiod>simperiod DO repperiod := simperiod
  tracing := argv!2                                // -t
  IF argv!3 DO seed      := str2numb(argv!3)       // -s n

  IF argv!4 DO                                     // -o file
  { tostream := findoutput(argv!4)
    IF tostream=0 DO
    { writef("Trouble with file %s*n", argv!4)
      RESULTIS 20
    }
    selectoutput(tostream)
  }

  blks   := mkBlks(50000)              // Space for event blocks 
  sim := mkSim(10000, simperiod) // Create the priority queue object 
  rand   := mkRand(seed)

  UNLESS blks & sim & rand DO
  { writef("Insufficient memory*n")
    GOTO fin
  }

/*
  FOR i = 0 TO 199 DO
  { IF i REM 5 = 0 DO newline()
//    writef(" %i9", Uniform#(rand, 1000, 2000))
    prnum(Negexp#(rand), 10, 6)
  }
  newline()
  { LET sum = 0
    FOR i = 1 TO 1000 DO sum := sum + Negexp#(rand)
    writef("mean of 1000 numbers: ")
    prnum(sum/1000, 9, 6)
    newline()
  }
RESULTIS 0
*/

  totalflowin  := 0
  totalflowout := 0
  timespent    := 0

  telephone1 := mkQda("Telephone 1", Tels1, telephoneact, 0)
  telephone2 := mkQda("Telephone 2", Tels2, telephoneact, 0)
  checkin1   := mkQda("Checkin 1",   Chk1clerks, checkinact, telephone1)
  checkin2   := mkQda("Checkin 2",   Chk2clerks, checkinact, telephone2)
  bank       := mkQda("The Bank",    Bankclerks, bankact, 0)
  kiosk      := mkQda("The Kiosk",   Kioskclerks, kioskact, 0)
  passport   := mkQda("Passport Control",
                                     Passportclerks, passportact, 0)

  { LET domgen    = initco(domesticfn, 200)
    LET intgen    = initco(internationalfn, 200)
    LET chagen    = initco(charterfn, 200)
    LET reporter  = initco(reportfn, 200, repperiod)

    domlobby := initco(lobbyfn, 200, "dom")
    intlobby := initco(lobbyfn, 200, "int")

    Activate#(sim, domgen)
    Activate#(sim, intgen)
    Activate#(sim, chagen)
    Activate#(sim, reporter)

    { LET e = GetEvent#(sim)
      IF e DO callco(S_c!e)
    }

    deleteco(domgen)
    deleteco(intgen)
    deleteco(chagen)
    deleteco(reporter)
    deleteco(domlobby)
    deleteco(intlobby)
  }


fin:
  freeQda(checkin1)
  freeQda(checkin2)
  freeQda(telephone1)
  freeQda(telephone2)
  freeQda(bank)
  freeQda(kiosk)

  freeRand(rand)
  freeSim(sim)
  freeBlks(blks)
  IF tostream & tostream~=stdout DO endwrite()
  selectoutput(stdout)
  RESULTIS 0
}

/* typical output:


*/


