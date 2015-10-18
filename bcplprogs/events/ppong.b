// This is similar to events.b being a discrete event simulator
// using coroutines. It is based on random.c written by Joerg Lepler
// to run under GTW++.

// Reimplemented in BCPL by Martin Richards  (c) June 2000

GET "libhdr"

GLOBAL {
 spacev:ug; spacep; spacet  // Space for events
 eventlist; currevent
 heap; heapn; heapt         // The priority queue
 LPv                        // Vector of players
 time; count; seed
 tracing
 NumberLPs        // Number of players
 NumberInitEvents // Initial number of events in the queue events
 MaxDelay         // The maximum delay for an event
                  // must be less than maxint/2 for the priority
                  // queue to work.
}

MANIFEST { 
 E_nxt=0; E_c; E_t; E_to  // Selectors in event blocks
 Black=0; White; Red; Blue; NumColours
}

LET start() = VALOF
{ LET argv = VEC 50

  UNLESS rdargs("-c,-p,-e,-d,-t/s", argv, 50) DO
  { writef("Bad arguments for events*n")
    RESULTIS 0
  }

  count            := 1000   // Number of events to process
  NumberLPs        := 99     // Number of players
  NumberInitEvents := 10     // Initial number of events per player
  MaxDelay         := 2000   // The maximum delay for an event

  IF argv!0 DO count            := str2numb(argv!0)  // -c
  IF argv!1 DO NumberLPs        := str2numb(argv!1)  // -p
  IF argv!2 DO NumberInitEvents := str2numb(argv!2)  // -e
  IF argv!3 DO MaxDelay         := str2numb(argv!3)  // -d
  tracing := argv!4                                  // -t

  spacet := NumberLPs*NumberInitEvents*4   // Space for event blocks 
  spacev, spacep := getvec(spacet), 0
  heapn, heapt := 0, NumberLPs*NumberInitEvents 
  heap := getvec(heapt)
  LPv := getvec(NumberLPs)

  UNLESS spacev & heap & LPv DO
  { writef("Insufficient memory*n")
    GOTO fin
  }

  eventlist, time := 0, 0
  seed := 12345 // Seed for the random number generator, must be non zero

  // Create the players
  FOR i = 1 TO NumberLPs DO
   LPv!i := initco(playerfn, 100, NumberInitEvents, MaxDelay, i)

  writef("Random Ball Game initialized.*n")

  writef("count=%n NumberLPs=%n  NumberInitEvents=%n MaxDelay=%n*n",
          count,   NumberLPs,    NumberInitEvents,   MaxDelay)

  currevent := getevent()
 
  writef("Instruction count %n*n",
          instrcount(callco, LPv!(E_to!currevent), currevent))
//  callco(LPv!(E_to!currevent), currevent)

  FOR i = 1 TO NumberLPs DO
  { callco(LPv!i, 0)
    deleteco(LPv!i)
  }

  WHILE eventlist DO
  { LET p = E_nxt!eventlist
    freevec(eventlist)
    eventlist := p
  }
fin:
  IF spacev DO freevec(spacev)
  IF heap   DO freevec(heap)
  IF LPv    DO freevec(LPv)
  RESULTIS 0
}

AND playerfn(args) BE
{ LET NumberInitEvents = args!0
  LET MaxDelay         = args!1
  LET this             = args!2
  LET Colour           = White
  LET BallCount = VEC Blue

  FOR col = Black TO Blue DO BallCount!col := 0

  // Preload the event queue with NumberInitEvents random events
  FOR i = 1 TO NumberInitEvents DO
  { LET sendto = rndno(NumberLPs)
    LET timeGap = rndno(MaxDelay)
    putevent(mkevent(Colour, timeGap, sendto))
    Colour := (Colour+1) REM NumColours
  }

  // End of initialisation

  { LET e = cowait()  // Wait for first event

    WHILE e DO
    { LET c = E_c!e
      LET p = rndno(NumberLPs)
      LET t = time + rndno(MaxDelay)
      BallCount!c := BallCount!c + 1
      c := (c+1) REM NumColours
      IF tracing DO
        writef("Player %i2: %iB/%i2/%n => %iB/%i2/%n*n",
                this, E_t!e, E_to!e, E_c!e, t, p, c)
      E_c!e, E_t!e, E_to!e := c, t, p
      putevent(e)
      e := schedule() // Wait for next event for this player
    }
  }

  writef("*nStatistics for player %n:*n", this)
  FOR c = 0 TO NumColours-1 DO 
    writef("    #Balls of colour %n = %i5*n", c, BallCount!c)
  cowait(0)
}

AND schedule() = VALOF
{ currevent := getevent()
  count := count-1
  UNLESS count & currevent DO cowait() // Return to main program
  time := E_t!currevent
  RESULTIS resumeco(LPv!(E_to!currevent), currevent)
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

AND mkevent(c, t, p) = VALOF
{ LET e = @spacev!spacep
  spacep := spacep+4
  IF spacep>spacet DO
  { writef("Insufficient space %n %n*n", spacep, spacet)
    abort(1000)
    stop(0)
  }
  E_nxt!e, E_c!e, E_t!e, E_to!e := eventlist, c, t, p
  eventlist := e
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

0> ppong -c 20 -p 5 -t
Random Ball Game initialized.
count=20 NumberLPs=5  NumberInitEvents=10 MaxDelay=2000
Player  2:           4/ 2/3 =>        1719/ 2/0
Player  5:          13/ 5/2 =>         551/ 5/3
Player  3:          47/ 3/2 =>         810/ 5/3
Player  1:          96/ 1/2 =>         375/ 2/3
Player  4:         112/ 4/3 =>        1758/ 5/0
Player  3:         292/ 3/0 =>        1240/ 5/1
Player  2:         299/ 2/2 =>        1428/ 4/3
Player  2:         356/ 2/0 =>         639/ 5/1
Player  2:         375/ 2/3 =>        2322/ 2/0
Player  3:         397/ 3/2 =>        1960/ 4/3
Player  2:         450/ 2/0 =>         809/ 2/1
Player  1:         486/ 1/3 =>        1948/ 5/0
Player  4:         503/ 4/0 =>        1285/ 3/1
Player  5:         507/ 5/1 =>        1983/ 1/2
Player  3:         507/ 3/3 =>        2120/ 3/0
Player  5:         550/ 5/0 =>        2454/ 2/1
Player  5:         551/ 5/3 =>        2027/ 1/0
Player  4:         565/ 4/1 =>        1758/ 4/2
Player  2:         587/ 2/2 =>        2386/ 2/3
Player  5:         603/ 5/1 =>        1773/ 5/2
Instruction count 60059

Statistics for player 1:
    #Balls of colour 0 =     0
    #Balls of colour 1 =     0
    #Balls of colour 2 =     1
    #Balls of colour 3 =     1

Statistics for player 2:
    #Balls of colour 0 =     2
    #Balls of colour 1 =     0
    #Balls of colour 2 =     2
    #Balls of colour 3 =     2

Statistics for player 3:
    #Balls of colour 0 =     1
    #Balls of colour 1 =     0
    #Balls of colour 2 =     2
    #Balls of colour 3 =     1

Statistics for player 4:
    #Balls of colour 0 =     1
    #Balls of colour 1 =     1
    #Balls of colour 2 =     0
    #Balls of colour 3 =     1
Player  5:         618/ 5/1 =>         903/ 4/2
10> 

*/


