// This is the BCPL translation of a Simula-67 program given on
// pages 304 to 311 of "Simula BEGIN" by Birtwistle, G.M. et al

// Martin Richards  (c) 5 July 2000

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

The bank clerk takes exactly 3 minutes.

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
ie 1.0 minutes is represented by 1000.
*/

GET "libhdr"

GLOBAL {
 spacev:ug; spacep; spacet
 heap; heapn; heapt
 time; seed
 tracing
 freeblklist

 chk1clerksfree;     chk1q; chk1qlen; chk1maxqlen
 chk1clerkused;      chk1clerkserved; chk1served
 chk2clerksfree;     chk2q; chk2qlen; chk2maxqlen
 chk2clerkused;      chk2clerkserved; chk2served
 tels1free;          tel1q; tel1qlen; tel1maxqlen
 tels2free;          tel2q; tel2qlen; tel2maxqlen
 bankclerksfree;     bankq; bankqlen; bankmaxqlen
 bankclerkused;      bankclerkserved; bankserved
 kioskclerksfree;    kioskq; kioskqlen; kioskmaxqlen
 kioskclerkused;     kioskclerkserved; kioskserved
 passportclerksfree; passportq; passportqlen; passportmaxqlen
 passportclerkused;  passportclerkserved; passportserved

 // Coroutines
 domgen; chartgen; intgen  // Passenger generators
 intlobby; domlobby        // Passenger removal coroutines
 report                    // Report generator

 // The passenger coroutines are dynamically created and deleted

 // statistics
 simperiod; repperiod
 totalflowin; totalflowout; timespent
}

MANIFEST { 
S_nxt=0; S_t; S_c  // Selectors  for fields in blocks

Passportclerks = 1
Bankclerks     = 1
Kioskclerks    = 2
Tels1          = 1
Chk1clerks     = 2
Tels2          = 1
Chk2clerks     = 4
}

/*
The function negexp() returns random deviates from the exponential
distribution with a mean of 1.0. The result is in a fixed point
scaled number with 1.0 represented by 1000000.

It is based on the algorithm given on page 128 of Knuth, Art of 
Programming, Vol 2.
*/

GLOBAL {
  q:300; ln2; neseed
}

MANIFEST { One = 1000000 }

LET nernd() = VALOF {
  neseed := 2147001325 * neseed + 715136305
  RESULTIS neseed & #x7fffffff
}

AND uniform(a, b) = VALOF
{ LET w = nernd()
  RESULTIS a + w REM (b-a+1)
}

AND negexp() = VALOF // Exponential distribution mean 1.0
{ LET u = nernd()
  LET v, w = ?, ?
  LET j = 0

  { u := u<<1
    IF u>=0 BREAK
    j := j+1
  } REPEAT

  IF u<q!1 RESULTIS j*ln2 + muldiv(One, u, maxint)

  v := nernd()
  FOR i = 2 TO 10 DO
  { LET w = nernd()
    IF v>=w DO v := w
    IF u<q!i BREAK
  }

  RESULTIS muldiv(ln2, (j*One+muldiv(One, v, maxint)), One)  
}

AND initnegexp(seed) = VALOF
{ neseed := seed
  FOR i = 1 TO 10 DO nernd()
  q := TABLE 0,
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
  ln2 := muldiv(One, #x58b90bfb, maxint) // ln 2.0
}
 
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

// draw returns TRUE for the given percentage of times
AND draw(percentage) = uniform(0, 100) <= percentage

/*****************************************************/

// Clerks and telephones have bits patterns to indicate
// which are free. The bits are numbered from 1 to 32 from
// the least significant end. A one indicates that the specified
// clerk or telephone is free.

LET setfree(p, n) BE !p := !p | (1 << n-1)

LET isfree(p, n)  = (!p & (1 << n-1)) ~= 0

LET setbusy(p, n) BE !p := !p & ~(1 << n-1)

LET selectfree(p) = VALOF
{ LET bits = !p
  LET bit = 1
  LET n = 1
  UNLESS bits RESULTIS 0   // to indicate no clerk or telephone is free
  WHILE (bits&bit)=0 DO bit, n := bit<<1, n+1
  !p := bits - bit
  RESULTIS n // The number of a free clerk or telephone
}

LET bank() BE
{ // The bank has just one clerk who takes 3.0 minutes per passenger
  LET clerk = selectfree(@bankclerksfree)
  IF clerk DO                   // Is a bank clerk free?
  { LET delay = 3000            // Delay for 3.0 minutes
    IF tracing DO
      writef("%i7: passenger %n being served the bank until %n*n",
              time, currco, time+delay)
    hold(time+delay)
    IF tracing DO
      writef("%i7: passenger %n leaves the bank*n", time, currco)
    setfree(@bankclerksfree, clerk)
    bankclerkused!clerk := bankclerkused!clerk + delay
    bankclerkserved!clerk := bankclerkserved!clerk + 1
    bankserved := bankserved+1
    IF bankq DO                // Activate next in bank queue, if any
    { LET e = dequeue(@bankq)
      bankqlen := bankqlen-1
      activate(S_c!e)          // Schedule item to run now
      freeblk(e)
    }
    RETURN
  }
  IF tracing DO
    writef("%i7: passenger %n joins the bank queue*n", time)
  bankqlen := bankqlen+1
  IF bankmaxqlen<bankqlen DO bankmaxqlen := bankqlen
  appendblk(@bankq, 0, currco) // Put passenger in the bank q
  schedule()                   // Wait until the bank clerk is free
} REPEAT                       // Try again to service this passenger

AND kiosk() BE
{ // The kiosk has two clerks
  // they take between 1.0 and 2.0 minutes per passenger
  // and need to make a 1.0 minute call on a shared telephone
  LET clerk = selectfree(@kioskclerksfree)
  IF clerk DO          // Is a kiosk clerk free?
  { LET delay = uniform(1000, 2000)
    IF tracing DO
      writef("%i7: passenger %n being served at kiosk until %n*n",
              time, currco, time+delay)
    hold(time+delay)            // Hold self for delay period
    IF tracing DO
      writef("%i7: passenger %n leaves the kiosk*n", time, currco)
    setfree(@kioskclerksfree, clerk)
    kioskclerkused!clerk := kioskclerkused!clerk + delay
    kioskclerkserved!clerk := kioskclerkserved!clerk + 1
    kioskserved := kioskserved+1
    IF kioskq DO                // Activate next in kiosk queue item, if any
    { LET e = dequeue(@kioskq)
      kioskqlen := kioskqlen-1
      activate(S_c!e)          // Schedule item to run now
      freeblk(e)
    }
    RETURN
  }
  IF tracing DO
    writef("%i7: passenger %n joins the kiosk queue*n", time)
  kioskqlen := kioskqlen+1
  IF kioskmaxqlen<kioskqlen DO kioskmaxqlen := kioskqlen
  appendblk(@kioskq, 0, currco) // Put passenger in the kiosk q
  schedule()                    // Wait until a kiosk clerk is free
} REPEAT                        // Try again to service this passenger

AND telephone1() BE
{ // Checkin1 has only one telephone
  // call take exactly 1.0 minutes
  // passengers may need to wait in tel1q
  LET tel = selectfree(@tels1free)
  IF tel DO              // Is a telephone free?
  { LET delay = 1000
    IF tracing DO
      writef("%i7: passenger %n using telephone 1 until %n*n",
              time, currco, time+delay)
    hold(time+delay)           // Hold self for delay period
    IF tracing DO
      writef("%i7: passenger %n finished with telephone 1*n", time, currco)
    setfree(@tels1free, tel)
    IF tel1q DO                // Activate next in tel1 queue, if any
    { LET e = dequeue(@tel1q)
      activate(S_c!e)          // Schedule item to run now
      freeblk(e)
    }
    RETURN
  }
  IF tracing DO
    writef("%i7: passenger %n joins the queue for telephone 1*n", time)
  appendblk(@tel1q, 0, currco) // Put passenger in the tel1 q
  schedule()                   // Wait until telephone 1 is free
} REPEAT                       // Try again to service this passenger

AND telephone2() BE
{ // Checkin2 has only one telephone
  // call take exactly 1.0 minutes
  // passengers may need to wait in tel2q
  LET tel = selectfree(@tels2free)
  IF tel DO              // Is a telephone free?
  { LET delay = 1000
    IF tracing DO
      writef("%i7: passenger %n using telephone 2 until %n*n",
              time, currco, time+delay)
    hold(time+delay)           // Hold self for delay period
    IF tracing DO
      writef("%i7: passenger %n finished with telephone 2*n", time, currco)
    setfree(@tels2free, tel)
    IF tel2q DO                // Activate next in tel2 queue, if any
    { LET e = dequeue(@tel2q)
      activate(S_c!e)          // Schedule item to run now
      freeblk(e)
    }
    RETURN
  }
  IF tracing DO
    writef("%i7: passenger %n joins telephone 2 queue*n", time, currco)
  appendblk(@tel2q, 0, currco) // Put passenger in the tel2 q
  schedule()                   // Wait until telephone 2 is free
} REPEAT                       // Try again to service this passenger

AND passport() BE
{ // similar to bank but hold for 1.0 to 3.0 minutes
  LET clerk = selectfree(@passportclerksfree)
  IF clerk DO
  { LET delay = uniform(1000, 3000)  // Delay from 1.0 to 3.0 minutes
    IF tracing DO
      writef("%i7: passenger %n at passport control until %n*n",
              time, currco, time+delay)
    hold(time+delay) //    hold self for 1.0 to 3.0 minutes
    IF tracing DO
      writef("%i7: passenger %n leaves passport control*n",
              time, currco)
    passportclerkused!clerk := passportclerkused!clerk + delay
    passportclerkserved!clerk := passportclerkserved!clerk + 1
    setfree(@passportclerksfree, clerk)
    passportserved := passportserved+1
    IF passportq DO              // Is anyone in the passport q?
    { LET e = dequeue(@passportq)
      passportqlen := passportqlen-1
      activate(S_c!e)            // Schedule item to run now
      freeblk(e)
    }
    RETURN
  }
  IF tracing DO
    writef("%i7: passenger %n joins passport queue*n", time, currco)
  passportqlen := passportqlen+1
  IF passportmaxqlen<passportqlen DO passportmaxqlen := passportqlen
  appendblk(@passportq, 0, currco)
  schedule()
} REPEAT

AND checkin1() BE
{ // wait for a clerk
  // hold for 2.0 to 4.0 minutes
  // wait for telephone
  // hold for 1.0 minutes
  LET clerk = selectfree(@chk1clerksfree)
  IF clerk DO            // Is a checkin clerk free
  { LET delay = uniform(2000, 4000)  // Delay of 2.0 to 4.0 minutes
    IF tracing DO
      writef("%i7: passenger %n with checkin 1 clerk %n*n",
              time, currco, clerk)
    hold(time+delay)
    telephone1()
    IF tracing DO
      writef("%i7: passenger %n leaves checkin 1*n", time, currco)
    setfree(@chk1clerksfree, clerk)
    chk1clerkused!clerk := chk1clerkused!clerk + delay
    chk1clerkserved!clerk := chk1clerkserved!clerk + 1
    chk1served := chk1served+1
    IF chk1q DO                  // Is anyone in the queue?
    { LET e = dequeue(@chk1q)
      chk1qlen := chk1qlen - 1
      activate(S_c!e)            // Schedule item to run now
      freeblk(e)
    }
    RETURN
  }
  IF tracing DO
    writef("%i7: passenger %n joins checkin 1 queue*n", time, currco)
  chk1qlen := chk1qlen+1
  IF chk1maxqlen<chk1qlen DO chk1maxqlen := chk1qlen
  appendblk(@chk1q, 0, currco)
  schedule()
} REPEAT

AND checkin2() BE
{ // wait for a clerk
  // hold for 2.0 to 4.0 minutes
  // wait for telephone
  // hold for 1.0 minutes
  LET clerk = selectfree(@chk2clerksfree)
  IF clerk DO            // Is a checkin clerk free
  { LET delay = uniform(2000, 4000)  // Delay of 2.0 to 4.0 minutes
    IF tracing DO
      writef("%i7: passenger %n with checkin 2 clerk %n*n",
              time, currco, clerk)
    hold(time+delay)
    telephone2()
    IF tracing DO
      writef("%i7: passenger %n leaves checkin 2*n", time, currco)
    setfree(@chk2clerksfree, clerk)
    chk2clerkused!clerk := chk2clerkused!clerk + delay
    chk2clerkserved!clerk := chk2clerkserved!clerk + 1
    chk2served := chk2served+1
    IF chk2q DO                  // Is anyone in the queue?
    { LET e = dequeue(@chk2q)
      chk2qlen := chk2qlen - 1
      activate(S_c!e)            // Schedule item to run now
      freeblk(e)
    }
    RETURN
  }
  IF tracing DO
    writef("%i7: passenger %n joins checkin 2 queue*n", time, currco)
  chk2qlen := chk2qlen+1
  IF chk2maxqlen<chk2qlen DO chk2maxqlen := chk2qlen
  appendblk(@chk2q, 0, currco)
  schedule()
} REPEAT

AND dompassengerfn(args) BE
{ // initialise
  cowait()

  { LET literate  = draw(50) // 50%
    LET penniless = draw(20) // 20%
    LET timein = time
    totalflowin := totalflowin + 1
    IF tracing DO writef("%i7: new domestic passenger %n*n", time, currco)
    checkin2()
    IF penniless DO bank()
    IF literate  DO kiosk()
    totalflowout := totalflowout + 1
    timespent := timespent + time - timein
    resumeco(domlobby, currco)         // Deletes this coroutine
    writef("dompassenger: error*n")
    abort(999)
  }
}

AND intpassengerfn(args) BE
{ // initialise
  cowait()

  { LET literate  = draw(50) // 50%
    LET penniless = draw(20) // 20%
    LET timein = time
    totalflowin := totalflowin + 1
    IF tracing DO writef("%i7: new international passenger %n*n", time, currco)
    checkin2()
    IF penniless DO bank()
    IF literate  DO kiosk()
    passport()
    totalflowout := totalflowout + 1
    timespent := timespent + time - timein
    resumeco(intlobby, currco)         // Deletes this coroutine
    writef("intpassenger: error*n")
    abort(999)
  }
}

AND chapassengerfn(args) BE
{ // initialise
  cowait()

  { LET penniless = draw(70) // 70%
    LET timein = time
    totalflowin := totalflowin + 1
    IF tracing DO writef("%i7: new charter passenger %n*n", time, currco)
    checkin1()
    IF penniless DO bank()
    passport()
    totalflowout := totalflowout + 1
    timespent := timespent + time - timein
    resumeco(intlobby, currco)         // Deletes this coroutine
    writef("chartpassenger: error*n")
    abort(999)
  }
}

AND intlobbyfn(args) BE
{ LET passenger = cowait()  // Wait to be resumeco-ed

  { IF tracing DO writef("%i7: passenger %n leaves via int lobby*n",
                        time, passenger)
    deleteco(passenger)
    IF tracing DO
      writef("%i7: passenger %n deleted*n", time, passenger)
    passenger := schedule()
  } REPEAT
}

AND domlobbyfn(args) BE
{ LET passenger = cowait()  // Wait to be resumeco-ed

  { IF tracing DO writef("%i7: passenger %n leaves via dom lobby*n",
                        time, passenger)
    deleteco(passenger)
    IF tracing DO
      writef("%i7: passenger %n deleted*n", time, passenger)
    passenger := schedule()
  } REPEAT
}

AND reportfn(args) BE
{ LET period = args!0
  cowait()      // Wait to be activated

  { hold(time + period)
    newline()
    writef("Status Report at time               = %i9*n", time/1000)
    FOR i = 1 TO 47 DO wrch('**')
    writes("*n*n")
    writef("No. of customers who have entered   = %i9*n", totalflowin)
    writef("No. of customers through the system = %i9*n", totalflowout)
    IF totalflowout=0 DO totalflowout := 1
    writef("Av. Total time spent by customers   = ")
      prnum(muldiv(One, timespent, totalflowout*1000), 9, 3)
    newline()

    writef("*n****Passport Statistics *n")
    writef("No. of customers served  = %i6*n", passportserved)
    writef("No. of customers waiting = %i6*n", passportqlen)
    writef("Max. queue length        = %i6*n", passportmaxqlen)
    writef("    Clerk activities*n")
    writef("Clerk/ %% use /Busy/Served*n")
    FOR i = 1 TO Passportclerks DO
    {  writef("    %n  ", i )
       prnum(muldiv(passportclerkused!i,100*One, time), 5, 2)
       writes(isfree(@passportclerksfree, i) -> "   No", "  Yes")
       writef("%i6*n", passportclerkserved!i)
    }

    writef("*n****Bank Statistics *n")
    writef("No. of customers served  = %i6*n", bankserved)
    writef("No. of customers waiting = %i6*n", bankqlen)
    writef("Max. queue length        = %i6*n", bankmaxqlen)
    writef("    Clerk activities*n")
    writef("Clerk/ %% use /Busy/Served*n")
    FOR i = 1 TO Bankclerks DO
    {  writef("    %n  ", i )
       prnum(muldiv(bankclerkused!i,100*One, time), 5, 2)
       writes(isfree(@bankclerksfree, i) -> "   No", "  Yes")
       writef("%i6*n", bankclerkserved!i)
    }

    writef("*n****Kiosk Statistics *n")
    writef("No. of customers served  = %i6*n", kioskserved)
    writef("No. of customers waiting = %i6*n", kioskqlen)
    writef("Max. queue length        = %i6*n", kioskmaxqlen)
    writef("    Clerk activities*n")
    writef("Clerk/ %% use /Busy/Served*n")
    FOR i = 1 TO Kioskclerks DO
    {  writef("    %n  ", i )
       prnum(muldiv(kioskclerkused!i,100*One, time), 5, 2)
       writes(isfree(@kioskclerksfree, i) -> "   No", "  Yes")
       writef("%i6*n", kioskclerkserved!i)
    }

    writef("*n****Checkin1 Statistics *n")
    writef("No. of customers served  = %i6*n", chk1served)
    writef("No. of customers waiting = %i6*n", chk1qlen)
    writef("Max. queue length        = %i6*n", chk1maxqlen)
    writef("    Clerk activities*n")
    writef("Clerk/ %% use /Busy/Served*n")
    FOR i = 1 TO Chk1clerks DO
    {  writef("    %n  ", i )
       prnum(muldiv(chk1clerkused!i,100*One, time), 5, 2)
       writes(isfree(@chk1clerksfree, i) -> "   No", "  Yes")
       writef("%i6*n", chk1clerkserved!i)
    }

    writef("*n****Checkin2 Statistics *n")
    writef("No. of customers served  = %i6*n", chk2served)
    writef("No. of customers waiting = %i6*n", chk2qlen)
    writef("Max. queue length        = %i6*n", chk2maxqlen)
    writef("    Clerk activities*n")
    writef("Clerk/ %% use /Busy/Served*n")
    FOR i = 1 TO Chk2clerks DO
    {  writef("    %n  ", i )
       prnum(muldiv(chk2clerkused!i,100*One, time), 5, 2)
       writes(isfree(@chk2clerksfree, i) -> "   No", "  Yes")
       writef("%i6*n", chk2clerkserved!i)
    }
  } REPEAT
}

// Customer generators
AND charterfn() BE
{ // do initialisation
  cowait()       // Wait to be activated

  { // hold for negexp time mean 4 minutes
    LET delay = muldiv(4000, negexp(), One)
    hold(time+delay)
    // activate new charter passenger
    activate(initco(chapassengerfn, 200))
  } REPEAT
}

AND domesticfn() BE
{ // do initialisation
  cowait()       // Wait to be activated

  { // hold for negexp time mean 5 minutes
    LET delay = muldiv(5000, negexp(), One)
    hold(time+delay)
    // activate new domestic passenger
    activate(initco(dompassengerfn, 200))
  } REPEAT
}

AND internationalfn() BE
{ // do initialisation
  cowait()       // Wait to be activated

  { // hold for negexp time mean 4 minutes
    LET delay = muldiv(4000, negexp(), One)
    hold(time+delay)
    // activate new international passenger
    activate(initco(intpassengerfn, 200))
  } REPEAT
}

// Mechanism for holding a coroutine until time t
AND hold(t) BE
{ activateat(currco, t)
  schedule()
}

AND dequeue(p) = VALOF
{ LET blk = !p
  IF blk DO !p := S_nxt!blk
  RESULTIS blk
}

AND appendblk(p, t, c) BE
{ WHILE !p DO p := !p  // Find the end of the list
  !p := mkblk(0, t, c) // Append a block
}

AND activate(cptr) BE putevent(mkblk(0, time, cptr))

AND activateat(cptr, t) BE putevent(mkblk(0, t, cptr))

AND start() = VALOF
{ LET argv = VEC 50
  LET stdout = output()
  LET tostream = 0
  LET seed = 0

  UNLESS rdargs("-p/k,-r/k,-t/s,-s/k,-o/k", argv, 50) DO
  { writef("Bad arguments for airport*n")
    RESULTIS 0
  }

  simperiod := 200*1000 // Simulation period in Milli-minutes
  repperiod := simperiod

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

  spacet := 50000   // Space for event blocks 
  spacev, spacep := getvec(spacet), 0
  freeblklist := 0
  heapn, heapt := 0, 10000 
  heap := getvec(heapt)

  UNLESS spacev & heap DO
  { writef("Insufficient memory*n")
    GOTO fin
  }

  time := 0
  initnegexp(seed)

/*
  FOR i = 0 TO 199 DO
  { IF i REM 5 = 0 DO newline()
//    writef(" %i9", uniform(1000, 2000))
    prnum(negexp(), 10, 6)
  }
  newline()
  { LET sum = 0
    FOR i = 1 TO 1000 DO sum := sum + negexp()
    writef("mean of 1000 numbers: ")
    prnum(sum/1000, 9, 6)
    newline()
  }
RESULTIS 0
*/

  totalflowin  := 0
  totalflowout := 0
  timespent    := 0

  chk1clerksfree := 0
  FOR clerk = 1 TO Chk1clerks DO setfree(@chk1clerksfree, clerk)
  chk1served := 0
  chk1q, chk1qlen, chk1maxqlen := 0, 0, 0
  chk1clerkused   := TABLE 0, 0, 0, 0, 0
  chk1clerkserved := TABLE 0, 0, 0, 0, 0

  chk2clerksfree := 0
  FOR clerk = 1 TO Chk2clerks DO setfree(@chk2clerksfree, clerk)
  chk2served := 0
  chk2q, chk2qlen, chk2maxqlen := 0, 0, 0
  chk2clerkused   := TABLE 0, 0, 0, 0, 0
  chk2clerkserved := TABLE 0, 0, 0, 0, 0

  tels1free := 0
  FOR tel = 1 TO Tels1 DO setfree(@tels1free, tel)
  tel1q := 0

  tels2free := 0
  FOR tel = 1 TO Tels2 DO setfree(@tels2free, tel)
  tel2q := 0

  bankclerksfree := 0
  FOR clerk = 1 TO Bankclerks DO setfree(@bankclerksfree, clerk)
  bankserved := 0
  bankq, bankqlen, bankmaxqlen := 0, 0, 0
  bankclerkused   := TABLE 0, 0, 0, 0, 0
  bankclerkserved := TABLE 0, 0, 0, 0, 0

  kioskclerksfree := 0
  FOR clerk = 1 TO Kioskclerks DO setfree(@kioskclerksfree, clerk)
  kioskserved := 0
  kioskq, kioskqlen, kioskmaxqlen := 0, 0, 0
  kioskclerkused   := TABLE 0, 0, 0, 0, 0
  kioskclerkserved := TABLE 0, 0, 0, 0, 0

  passportclerksfree := 0
  FOR clerk = 1 TO Passportclerks DO setfree(@passportclerksfree, clerk)
  passportserved := 0
  passportq, passportqlen, passportmaxqlen := 0, 0, 0
  passportclerkused   := TABLE 0, 0, 0, 0, 0
  passportclerkserved := TABLE 0, 0, 0, 0, 0

  { LET domg = initco(domesticfn, 200)
    LET intg = initco(internationalfn, 200)
    LET chag = initco(charterfn, 200)
    LET rep  = initco(reportfn, 200, repperiod)

    domlobby := initco(domlobbyfn, 200)
    intlobby := initco(intlobbyfn, 200)

    activate(domg)
    activate(intg)
    activate(chag)
    activate(rep)

    { LET e = getevent()
      IF e DO callco(S_c!e)
    }

    deleteco(domg)
    deleteco(intg)
    deleteco(chag)
    deleteco(rep)
    deleteco(domlobby)
    deleteco(intlobby)
  }


fin:
  IF spacev DO freevec(spacev)
  IF heap   DO freevec(heap)
  IF tostream & tostream~=stdout DO endwrite()
  selectoutput(stdout)
  RESULTIS 0
}

AND schedule() =
 VALOF
{ LET e = getevent()
  LET cptr = ?
//writef("schedule:*n")
  UNLESS e DO cowait() // No events left -- return to main program
  time, cptr := S_t!e, S_c!e
  freeblk(e)
//  IF tracing DO
//     writef("%i7: Event for coroutine: %n*n", time, cptr)
  IF time>simperiod DO cowait() // Return to main program
  RESULTIS resumeco(cptr)
}

// Heap implementation of the priority queue
AND getevent() = VALOF
{ LET e = heap!1
  UNLESS heapn RESULTIS 0  // If no more events
//  writef("getevent: %i6 %i7/%i6*n", e, S_t!e, S_c!e)

  // heap!1 is now empty
  downheap(heap, heap!heapn, 1, heapn-1)
  heapn := heapn-1
  RESULTIS e
}

// Insert an event into the priority queue
// The event's delay must be less than maxint/2
AND putevent(event) BE
{ heapn := heapn + 1
  upheap(heap, event, heapn)
//  writef("putevent: %i6 %i7/%i6*n", event, S_t!event, S_c!event)
}

AND pr() BE
{ FOR i = 1 TO heapn DO
  { LET e = heap!i
    writef(" %i6/%i5", S_t!e, S_c!e)
    IF i REM 10 = 0 DO newline()
  }
  newline()
}

AND mkblk(nxt, t, c) = VALOF
{ LET p = freeblklist
  TEST p
  THEN freeblklist := S_nxt!p
  ELSE { p := @spacev!spacep
         spacep := spacep+3
         IF spacep>spacet DO
         { writef("mkblk: Insufficient space %n %n*n", spacep, spacet)
           abort(999)
           stop(0)
         }
       }
  S_nxt!p, S_t!p, S_c!p := nxt, t, c
  RESULTIS p
}

AND freeblk(p) BE
{ S_nxt!p := freeblklist
  freeblklist := p
}

// Machine independent random numbers
// based on Irreducible polynomial 21042107357(E) of degree 31
// Peterson,W.W. and Weldon,E.J. Error Correcting Codes, p.492
AND rndno1(upb) = VALOF // 31 bit CRC random numbers
{ TEST (seed&1)=0 THEN  seed := seed>>1
                  ELSE  seed := seed>>1 NEQV #x7BB88888
  RESULTIS seed REM upb + 1
}


// Insert an event into the priority queue
// The event's delay must be less than maxint/2
// (note the time comparisons)
AND downheap(v, e, i, last) BE
{ LET j = i+i                         // pos of left son

  IF j<last DO                        // Test if there are 2 sons
  { LET p = v+j
    LET x = p!0                       // The left son
    LET y = p!1                       // The other son
    TEST S_t!x - S_t!y < 0            // Promote earlier son
    THEN { v!i := x; i := j   }
    ELSE { v!i := y; i := j+1 }
    LOOP
  }
  IF j=last DO { v!i := v!j; i := j } // Promote only son
  upheap(v, e, i)
  RETURN
} REPEAT

// Insert an event into the priority queue
// The event's delay must be less than maxint/2
// (note the time comparisons)
AND upheap(v, e, i) BE
{ LET t = S_t!e                   // The event's time

  { LET p = i/2                   // pos of parent
    // v!i is currently empty
    IF p=0 | S_t!(v!p) - t <= 0 DO { v!i := e; RETURN }
    v!i := v!p                    // Demote parent
    i := p
  } REPEAT
}

/* typical output:


*/


