// This is the skeleton of a simulatator for clients, resource providers
// and brokers on a network.  It is based on a discrete event simulator
// using coroutines.

// Implemented by Martin Richards  (c) June 2000

GET "libhdr"

GLOBAL {
 spacev:ug; spacep; spacet  // Space for events, etc
 heap; heapn; heapt         // The priority queue
 agentv; agentp; agentt     // Vector of coroutines
 simtime; count; seed
 tracing
}

MANIFEST { 
E_nxt=0; E_time; E_id; E_a1; E_a2; E_a3; E_a4  // Selectors in event blocks
E_size
}

LET start() = VALOF
{ LET argv = VEC 50

  UNLESS rdargs("-c,-a,-h,-s,-t/s", argv, 50) DO
  { writef("Bad arguments for events*n")
    RESULTIS 0
  }

  count    := 1000      // Number of events left to process
  agentt   := 1000      // Max Number of agents
  heapt    := 100000    // Max number of events in the queue
  spacet   := 1000000   // Size of workspace

  IF argv!0 DO count    := str2numb(argv!0)  // -c
  IF argv!1 DO agentt   := str2numb(argv!1)  // -a
  IF argv!2 DO heapt    := str2numb(argv!2)  // -h
  IF argv!3 DO spacet   := str2numb(argv!3)  // -s
  tracing := argv!4                          // -t

  spacev, spacep := getvec(spacet), 0
  heap, heapn    := getvec(heapt), 0
  agentv := getvec(agentt)

  UNLESS spacev & heap & agentv DO
  { writef("Insufficient memory*n")
    GOTO fin
  }

  simtime := 0
  seed := 12345 // Must be non zero

  configure()  // Set the initial configuration

  writef("count=%n*n", count)

  { LET e := getevent()
    writef("Instruction count %n*n",
            instrcount(callco, agentv!(E_id!e), e))
  }

  FOR i = 1 TO agentt IF agentv!i DO deleteco(agentv!i)

fin:
  IF spacev DO freevec(spacev)
  IF heap   DO freevec(heap)
  IF agentv DO freevec(agentv)
  RESULTIS 0
}

AND configure() BE
{ // Create some resources
  FOR i = 1 TO 10 DO agentv!i := initco(resourcefn, 100, i)
  // Create some brokers
  FOR i = 101 TO 110 DO agentv!i := initco(brokerfn, 100, i, 1, 10)
  // Create some clients
  FOR i = 201 TO 210 DO agentv!i := initco(clientfn, 100, i, 101, 110)

//  FOR i = 1 TO maxEv DO putevent(mkevent(rndno(maxDelay), rndno(maxId)))
}

AND resourcefn(args) BE
{ LET n = args!0
  // End of initialisation
  LET e = cowait()                // Wait for first event

  { LET a = E_a1!e                // Id of sender
    LET t = simtime + rndno(100)  // Resource provider delay
    IF tracing DO
      writef("Resource %i3: %iB/%i2 => %iB/%i2*n", n, E_t!e, E_a!e, t, a)
    E_t!e, E_a!e := t, a          // return to sender
    putevent(e)
    e := schedule() // Wait for next event for this agent
  } REPEAT
}

AND brokerfn(args) BE
{ LET n  = args!0
  LET r1 = args!1 // First resource
  LET r2 = args!2 // Last resource
  LET rn = r2-r1+1
  // End of initialisation

  LET e = cowait()  // Wait for first event

  { LET a = r1 + rndno(rn)
    LET t = simtime + rndno(maxDelay)
    IF tracing DO
      writef("Broker %i3: %iB/%i2 => %iB/%i2*n", n, E_t!e, E_a!e, t, a)
    E_t!e, E_a!e := t, a
    putevent(e)
    e := schedule() // Wait for next event for this agent
  } REPEAT
}

AND clientfn(args) BE
{ LET n = args!0
  LET b1 = args!1 // First broker
  LET b2 = args!2 // Last broker
  // End of initialisation

  LET e = cowait()  // Wait for first event

  { LET a = rndno(maxId)
    LET t = simtime + rndno(maxDelay)
    IF tracing DO
      writef("Client %i2: %iB/%i2 => %iB/%i2*n", n, E_t!e, E_a!e, t, a)
    E_t!e, E_a!e := t, a
    putevent(e)
    e := schedule() // Wait for next event for this agent
  } REPEAT
}

AND schedule() = VALOF
{ currevent := getevent()
  count := count-1
  UNLESS count & currevent DO cowait() // Return to main program
  simtime := E_t!currevent
  RESULTIS resumeco(agentv!(E_a!currevent), currevent)
}

// Heap implementation of the priority queue
AND getevent() = VALOF
{ LET e = heap!1
  UNLESS heapn DO 
  { writef("Event queue is empty*n")
    abort(1000)
  }
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
}

AND pr() BE
{ FOR i = 1 TO heapn DO
  { LET e = heap!i
    writef(" %i7/%i2", E_t!e, E_a!e)
    IF i REM 10 = 0 DO newline()
  }
  newline()
}

AND mkevent(t, a) = VALOF
{ LET e = @spacev!spacep
  spacep := spacep+E_size
  IF spacep>spacet DO
  { writef("Insufficient space %n %n*n", spacep, spacet)
    abort(1000)
    stop(0)
  }
  E_nxt!e, E_t!e, E_a!e := 0, t, a
  RESULTIS e
}

AND mkpkt(type, a1) = VALOF
{ LET p = @spacev!spacep
  spacep := spacep+P_size
  IF spacep>spacet DO
  { writef("Insufficient space %n %n*n", spacep, spacet)
    abort(1000)
    stop(0)
  }
  P_nxt!p, P_type!e, P_a1!e := 0, type, a1
  RESULTIS e
}

// Machine independent random numbers
// based on Irreducible polynomial 21042107357(E) of degree 31
// Peterson,W.W. and Weldon,E.J. Error Correcting Codes, p.492
AND rndno(upb) = VALOF // 31 bit CRC random numbers
{ TEST (seed&1)=0 THEN  seed := seed>>1
                  ELSE  seed := seed>>1 NEQV #x7BB88888
  RESULTIS seed REM upb + 1
}

AND rndno1(upb) = randno(upb)

// Insert an event into the priority queue
// The event's delay must be less than maxint/2
// (note the time comparisons)
AND downheap(v, e, i, last) BE
{ LET j = i+i                         // pos of left son

  IF j<last DO                        // Test if there are 2 sons
  { LET p = v+j
    LET x = p!0                       // The left son
    LET y = p!1                       // The other son
    TEST E_t!x - E_t!y < 0            // Promote earlier son
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
{ LET t = E_t!e                   // The event's time

  { LET p = i/2                   // pos of parent
    // v!i is currently empty
    IF p=0 | E_t!(v!p) - t <= 0 DO { v!i := e; RETURN }
    v!i := v!p                    // Demote parent
    i := p
  } REPEAT
}

/* typical output:

760> events -c 20 -a 50 -e 10 -d 1000 -t
count=20 maxId=50  maxEv=10 maxDelay=1000
Agent  3         205/ 3 =>         726/44
Agent 31         226/31 =>         322/41
Agent 45         266/45 =>         898/32
Agent 43         294/43 =>         744/12
Agent 37         302/37 =>         867/29
Agent 41         322/41 =>         964/33
Agent 37         373/37 =>         880/13
Agent 42         583/42 =>        1086/ 4
Agent 44         726/44 =>        1616/ 2
Agent 12         744/12 =>        1043/47
Agent 15         850/15 =>        1357/50
Agent 29         867/29 =>        1078/ 4
Agent  6         872/ 6 =>        1191/ 6
Agent 13         880/13 =>        1430/10
Agent 32         898/32 =>        1516/35
Agent 33         964/33 =>        1011/43
Agent 46         991/46 =>        1103/24
Agent 43        1011/43 =>        1947/30
Agent 47        1043/47 =>        1723/48
Agent  4        1078/ 4 =>        1894/26
Instruction count 50630
10> 
0> events -c 20 -a 50 -e 10 -d 1000
count=20 maxId=50  maxEv=10 maxDelay=1000
Instruction count 4800
0> events -c 10000 -a 99 -e 10000 -d 1000
count=10000 maxId=99  maxEv=10000 maxDelay=1000
Instruction count 5169397
410> 

*/


