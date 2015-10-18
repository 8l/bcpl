/*
This is a test simulation of a collection of clients sending
messages to several brokers.

Implemented in BCPL by Martin Richards  (c) October 2000
*/

GET "libhdr"

GLOBAL {
 spacev:ug; spacep; spacet  // Space for events
 ecount                     // Current number of event blocks allocated
 freelist; currevent
 heap; heapn; heapt         // The priority queue
 time; count; seed
 tracing
// mark
 stdout
 tostream
 Cv               // vector of clients
 Bv               // vector of brokers
 Cn               // Number of clients
 Bn               // Number of brokers
 MaxComDelay      // The maximum delay for an event
                  // must be less than maxint/2 for the priority
                  // queue to work.
 MaxCComp         // Maximum client compute time
 MaxCTimeout      // Maximum time a client will wait for a reply
 MaxBComp         // Maximum broker compute time
}

MANIFEST { 
 E_nxt=0          // Link to next block (queues, freelist, etc)
 E_type           // type of event
 E_t              // event time
 E_to             // destination coroutine
 E_fromId           // Source id (broker or client id)
 E_data           // Message data, depends on the type
 E_size           // Number of words in an event block

 ReplyTimeout=100   // An event sent to self to implement a wait
 ComputeDone
 Request    // A request from a client to a broker
 Reply      // A reply from a broker to a client

 Markupb=500
}

LET start() = VALOF
{ LET argv = VEC 50

  UNLESS rdargs("-c,-b,-cp, -bp,-d,-k,-t/s,-o/k", argv, 50) DO
  { writef("Bad arguments for events*n")
    RESULTIS 0
  }

  Cn               := 12     // Number of client
  Bn               := 5      // Number of brokers
  MaxCComp         := 60000  // Maximum client compute time
  MaxCTimeout      := 1500   // Maximum client wait for response
  MaxBComp         := 1000   // Maximum broker compute time
  MaxComDelay      := 500    // Maximum communication delay
  count            := 200    // Number of events to process

  IF argv!0 DO Cn               := str2numb(argv!0)  // -c
  IF argv!1 DO Bn               := str2numb(argv!1)  // -b
  IF argv!2 DO MaxCComp         := str2numb(argv!2)  // -cp
  IF argv!3 DO MaxBComp         := str2numb(argv!3)  // -bp
  IF argv!4 DO MaxComDelay      := str2numb(argv!4)  // -d
  IF argv!5 DO count            := str2numb(argv!5)  // -k
  tracing := argv!6                                  // -t

  stdout := output()
  tostream := stdout
  IF argv!7 DO tostream := findoutput(argv!7)        // -o
  UNLESS tostream DO
  { writef("Unable to open file %s*n", argv!7)
    tostream := stdout
  }
  selectoutput(tostream)
  Cv, Bv := getvec(Cn), getvec(Bn)
  spacet := Cn*(2*Bn)*E_size + 1000     // Space for event blocks 
  spacev, spacep := getvec(spacet), 0
  heapn, heapt := 0, Cn*Bn+1000 
  heap := getvec(heapt)

  UNLESS spacev & heap & Cv & Bv DO
  { writef("Insufficient memory*n")
    GOTO fin
  }

  ecount := 0
  freelist, time := 0, 0
  seed := 12345 // Seed for the random number generator, must be non zero

  // Create the brokers
  FOR i = 1 TO Bn DO
    Bv!i := initco(brokerfn, Markupb+200,
                   i, MaxBComp, MaxComDelay)

  // Create the clients
  FOR i = 1 TO Cn DO
    Cv!i := initco(clientfn, Markupb+200,
                   i, MaxCComp, MaxCTimeout, MaxComDelay)

  writef("Client-Broker Smulation.*n")

  writef("count=%n Cn=%n  Bn=%n MaxCComp=%n MaxBComp=%n MaxComDelay=%n*n",
          count,   Cn,    Bn,   MaxCComp,   MaxBComp,   MaxComDelay)

  currevent := getevent()
 
//  writef("Instruction count %n*n",
//          instrcount(callco, E_to!currevent, currevent))
  callco(E_to!currevent, currevent)

  FOR i = 1 TO Cn DO // Delete all the clients
  { callco(Cv!i, 0)
    deleteco(Cv!i)
  }

  FOR i = 1 TO Bn DO // Delete all the brokers
  { callco(Bv!i, 0)
    deleteco(Bv!i)
  }

fin:
  UNLESS tostream=stdout DO endwrite()
  selectoutput(stdout)
  IF Cv     DO freevec(Cv)
  IF Bv     DO freevec(Bv)
  IF spacev DO freevec(spacev)
  IF heap   DO freevec(heap)
  RESULTIS 0
}

AND clientfn(args) BE
{ MANIFEST {
    Idle
    WaitingForReplies
    Computing
  }
  LET myId        = args!0  // Id of this client
  LET MaxCompTime = args!1
  LET MaxTimeout  = args!2
  LET MaxComDelay = args!3
  LET state       = Idle
  LET jobno       = 0       // Current job number
  LET replyCount  = 0       // Count of replies for current job
  LET q           = 0       // Queue of events that arrived while waiting
  LET v = VEC Markupb

//  FOR i = 0 TO 15 DO mark(v, i)

  { LET t = time + randno(MaxCComp)
    putevent(mkEvent(ComputeDone, t, currco, myId, jobno))
    IF tracing DO
       writef("%iB: Client %i2/%n computing until %iB*n",
               time, myId, jobno, t)
    state := Computing        // Wait for end of compute time
    mark(v, 15)
  }

  { LET e = cowait(0)  // End of initialisation

    WHILE e DO
    { // Main client event loop
      SWITCHON E_type!e INTO
      { DEFAULT:
          writef("Unexpected event type %n received by client %n*n",
                                         E_type!e,             myId)
          freeEvent(e)
          ENDCASE

        CASE ComputeDone: 
          IF tracing DO
            writef("%iB: Client %i2 job %i3 ComputeDone*n",
                    time, myId, jobno)
          UNLESS jobno=E_data!e DO
          { freeEvent(e)  // Ignore this event
            mark(v, 5)
            ENDCASE
          }
          freeEvent(e)
          // Client has just completed its compute time
          // so send off request to every broker for a new job
          jobno := jobno+1
          FOR id = 1 TO Bn DO
          { e := mkEvent(Request,
                         time + rndno(MaxComDelay),
                         Bv!id,
                         myId,
                         jobno
                        )
            putevent(e)  // Send a request to every broker

            IF tracing DO
              writef("%iB: Client %i2 job %i3 rqest to broker %i2 arr %iB*n",
                      time, myId, jobno, id, E_t!e)
          }
          state := WaitingForReplies
          mark(v, 6)
          replyCount := 0
          ENDCASE
                 
        CASE Reply:           // Reply from a broker
          UNLESS state=WaitingForReplies & jobno=E_data!e DO
          { IF tracing DO
              writef("%iB: Client %i2 ignoring reply from %i2 job %n*n",
                      time, myId, E_fromId!e, E_data!e)
            freeEvent(e)      // Ignore late replies
            mark(v, 10)
            ENDCASE
          }
          IF tracing DO
            writef("%iB: Client %i2 good reply from %i2 job %n*n",
                    time, myId, E_fromId!e, E_data!e)
          mark(v, 12)
          freeEvent(e)
          replyCount := replyCount+1
          IF replyCount<3 ENDCASE

          // Sufficient replies received 
          { LET t = time + randno(MaxCComp)
            putevent(mkEvent(ComputeDone, t, currco, myId, jobno))
            IF tracing DO
               writef("%iB: Client %i2 computing until %iB*n",
                       time, myId, t)
          }
          state := Computing   // Wait for end of compute time
          mark(v, 15)
          ENDCASE
      }

      e := schedule()
    }
  }

  writef("*nStatistics for client %n:*n", myId)
  mark(v, 0)
  cowait(0)
}

AND mark(v, a) BE
{ LET x = 0
  LET n = 4   // a is an n bit number
  LET h = Markupb/n
  LET s = h/2
  FOR i = 1 TO 500 LOOP
  FOR k = 1 TO 8 FOR i = 0 TO n-1 DO
  { LET p = v + i*h
    x := v!0 + v!Markupb
    FOR j = 0 TO s BY 4 UNLESS ((a>>i) & 1) = 0 DO x := p!j
  }
}

AND brokerfn(args) BE
{ MANIFEST {
    Idle
    WaitinForRequest
    Computing
  }
  LET myId        = args!0  // Id of this client
  LET MaxCompTime = args!1
  LET MaxComDelay = args!2
  LET state       = Idle
  LET clientId    = 0
  LET job         = 0
  LET q           = 0       // Queue of events that arrived while waiting
  LET v = VEC Markupb

  { LET e = cowait(0)  // End of initialisation, wait for first request

    WHILE e DO
    { // Main broker event loop
      SWITCHON E_type!e INTO
      { DEFAULT:
          writef("Unexpected event type %n received by broker %n*n",
                                        E_type!e,             myId)
          freeEvent(e)
          ENDCASE

        CASE ComputeDone:
          // Broker has just completed its compute time
          // so send off reply to the client
          
          E_type!e   := Reply
          E_t!e      := time + rndno(MaxComDelay)
          E_to!e     := Cv!clientId
          E_fromId!e := myId
          E_data!e   := job
          putevent(e)
          state := Idle
          mark(v, 6)

          IF tracing DO
            writef("%iB: Broker %i2 reply to client %i2/%n arr %iB*n",
                    time, myId, clientId, job, E_t!e)
          ENDCASE
                 
        CASE Request:        // Request from client
            UNLESS state=Idle DO
            { E_nxt!e := q   // Put this event into the queue
              q := e
              mark(v, 14)
              ENDCASE
            }
            clientId, job := E_fromId!e, E_data!e
            state := Computing   // Wait for end of compute time
            E_type!e := ComputeDone
            E_t!e    := time + randno(MaxCompTime)
            E_to!e   := currco
            putevent(e)

            IF tracing DO
              writef("%iB: Broker %i2 computing for %n/%n until %iB*n",
                      time, myId, clientId, job, E_t!e)
            mark(v, 15)
            ENDCASE
      }

      IF state=Idle & q DO
      { e := q          // Deal with a queued request
        q := E_nxt!q
// writef("brokerfn: dequeued event %n*n", e)
//writef("broker %i2 qlen=%n*n", myId, qlen(q))
        mark(v, 7)
        LOOP
      }

      e := schedule()
    }
  }

  writef("*nStatistics for broker %n:*n", myId)
  writef("queue length %n*n", qlen(q))
  mark(v, 0)
  cowait(0)
}

AND qlen(q) = VALOF
{ LET len = 0
  WHILE q DO len, q := len+1, E_nxt!q
  RESULTIS len
}

AND schedule() = VALOF
{ getevent()
  RESULTIS resumeco(E_to!currevent, currevent)
}

// Heap implementation of the priority queue
AND getevent() = VALOF
{ LET e = heap!1
//writef("getevent: heapn = %n*n", heapn)
  UNLESS heapn DO 
  { writef("Event queue is empty*n")
    abort(1000)
  }
  // heap!1 is now empty
  downheap(heap, heap!heapn, 1, heapn-1)
  heapn := heapn-1
  currevent := e
  time := E_t!currevent
  count := count-1
//writef("getevent: count=%n*n", count)
  IF count<=0 | currevent=0 DO cowait(0) // Return to main program
//writef("getevent: time=%n*n", time)
  RESULTIS e
}

// Insert an event into the priority queue
// The event's delay must be less than maxint/2
AND putevent(e) BE
{ heapn := heapn + 1
//writef("putevent: %n %n %n %n*n", E_type!e, E_t!e, E_to!e, E_fromId!e)
  upheap(heap, e, heapn)
//writef("heap: ")
//FOR i = 1 TO heapn DO writef(" %i5", E_t!(heap!i))
//newline()
}

AND mkEvent(type, t, to, fromId, data) = VALOF
// type = Wait, Request or reply
// t    = time scheduled
// to   = coroutine to activate
// from = id of sender
{ LET e = freelist

  TEST e THEN freelist := E_nxt!e
  ELSE { e := @spacev!spacep
         spacep := spacep+E_size
         IF spacep>spacet DO
         { writef("Insufficient space %n %n*n", spacep, spacet)
           abort(1000)
           stop(0)
         }
       }
  E_nxt!e, E_type!e, E_t!e := 0, type, t
  E_to!e, E_fromId!e, E_data!e := to, fromId, data
  ecount := ecount+1
//  writef("mkEvent: ecount=%n freelist length=%n*n", ecount, qlen(freelist))
  RESULTIS e
}

AND freeEvent(e) BE IF e DO
{ E_nxt!e := freelist
  freelist := e
  ecount := ecount-1
//  writef("freeEvent: ecount=%n freelist length=%n*n", ecount, qlen(freelist))
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


*/


