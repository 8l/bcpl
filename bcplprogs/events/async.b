// This is a discrete event simulator of a ring circuit containing
// Muller C gates. It is intended as a benchmark test for discrete
// discrete event simulators.

// Martin Richards  (c) 13 July 2000

/*
The circuit to be simulated is a ring composed of elements formed
out of Muller C gates as follows:




      Ri -----*   *-----------*------------ R(i+1)
              |   |           |
              |   o           |
              -----           ^
             |     |        /   \
             |  C  |       |  C  |
              \   /        |     |
                v           -----
                |           |   o
                |           |   |
     Ai --------*-----------*   *--------- A(i+1)

where the Muller C gate has the following definition:

     C' = X.Y + C.(X+Y)

It state table is:

      X Y  C'
      ------
      0 0  0
      0 1  C
      1 0  C
      1 1  1

and its implementation is:

                  -----
    X -----*-----|     |         P
           |     | And |-------------------*
           |  *--|     |                   |     -----
           |  |   -----       Q   -----    *----|     |
           |  |   -----    *-----|     |        | Or  |--*------> C
           *--|--|     |   |     | And |--------|     |  |
              |  | Or  |---*  *--|     |   R     -----   |
    Y --------*--|     |      |   -----                  |
                  -----       *--------------------------*

In this simulation the signals an wires are represented by integers in
the range 0 to 5 and output of the And, Or and Not gates are delayed
functions of their inputs. Each gate is implemented by a coroutine.

*/

GET "libhdr"

GLOBAL {
 spacev:ug; spacep; spacet
 heap; heapn; heapt
 time; seed
 tracing
 freeblklist

 cellv; celln   // The vector of cells from 0 to celln

 // Coroutines

 // statistics
 simperiod; repperiod; mindt; maxdt
}

MANIFEST {
  S_nxt=0; S_t; S_c

  // Signals on the wires of a cell
  C_Id=0
  C_delay; C_pt
  C_R; C_A
  C_XN1; C_P1; C_Q1; C_R1
  C_XN2; C_P2; C_Q2; C_R2

  // Gate coroutines for the cell
  C_gXN1; C_gP1; C_gQ1; C_gR1; C_gC1
  C_gXN2; C_gP2; C_gQ2; C_gR2; C_gC2

  C_upb=C_gC2   // Upb of the cell vector
}


LET reportfn(args) BE
{ LET period = args!0
  cowait()      // Wait to be activated

  { LET c = cellv!1
    hold(time + period)
    //prreport()
    //LOOP
    writef("%i5: %i5 %i5 ", time, mindt, maxdt)
    FOR i = 1 TO celln DO
    { LET ci = cellv!i
      LET r, a = ci!C_R+'0', ci!C_A+'0'
      IF r='0' DO r := ' '
      IF r='5' DO r := '**'
      IF a='0' DO a := ' '
      IF a='5' DO a := '**'
      writef(" %c%c", r, a)
    }
    newline()
/*
//    writef("%n%n%n%n%n ", c!C_R,c!C_XN1,c!C_P1,c!C_Q1,c!C_R1)
    FOR i = 1 TO celln DO writef("%n", cellv!i!C_R)
    newline()
//    writef("%n%n%n%n%n ", c!C_A,c!C_R2,c!C_Q2,c!C_P2,c!C_XN2)
    FOR i = 1 TO celln DO writef("%n", cellv!i!C_A)
    newline()
*/
  } REPEAT
}

AND prreport() BE
{ newline()
  FOR i = 1 TO celln DO
  { LET c = cellv!i
    writef("%n%n%n%n%n ", c!C_R,c!C_XN1,c!C_P1,c!C_Q1,c!C_R1)
  }
  newline()
  FOR i = 1 TO celln DO
  { LET c = cellv!i
    writef("%n%n%n%n%n ", c!C_A,c!C_R2,c!C_Q2,c!C_P2,c!C_XN2)
  }
  newline()
}

// Mechanism for holding a coroutine until time t
AND hold(t) BE
{ activateat(currco, t)
  schedule()
}

AND activate(cptr) BE putevent(mkblk(0, time, cptr))

AND activateat(cptr, t) BE putevent(mkblk(0, t, cptr))

AND mkcircuit(n) BE
{ cellv, celln := getvec(n+1), n
  FOR i = 1 TO n DO cellv!i := mkcell(i)
  cellv!0 := cellv!n
  cellv!(n+1) := cellv!1
  FOR i = 1 TO n DO mkcortns(i)
  setcell(1,       5)
  setcell((n+1)/3, 5)
  FOR i = 1 TO n DO initcortns(i)
}

AND freecircuit() BE
{ FOR i = 1 TO celln DO freecell(i)
  freevec(cellv)
}

AND mkcell(id) = VALOF
{ LET c = getvec(C_upb)
  IF c=0 DO
  { writef("Insufficient space*n")
    abort(999)
    RESULTIS 0
  }
  FOR i = 0 TO C_upb DO c!i := 0
  c!C_Id := id
//writef("mkcell: id=%n*n", id)
  RESULTIS c
}

AND freecell(i) BE
{ LET c = cellv!i
  FOR i = C_gXN1 TO C_gC2 DO deleteco(c!i)
  freevec(c)
}

AND mkcortns(i) BE
{ LET curr = cellv!i

  curr!C_gXN1 := createco(gXN1fn, 100)

  curr!C_gP1  := createco(gP1fn,  100) // First Muller gate
  curr!C_gQ1  := createco(gQ1fn,  100)
  curr!C_gR1  := createco(gR1fn,  100)
  curr!C_gC1  := createco(gC1fn,  100)

  curr!C_gXN2 := createco(gXN2fn, 100)

  curr!C_gP2  := createco(gP2fn,  100) // Second Muller gate
  curr!C_gQ2  := createco(gQ2fn,  100)
  curr!C_gR2  := createco(gR2fn,  100)
  curr!C_gC2  := createco(gC2fn,  100)

  FOR i = C_gXN1 TO C_gC2 UNLESS curr!i DO
  { writef("Insufficient space*n")
    abort(999)
  }
}

AND initcortns(i) = VALOF
{ LET curr = cellv!i
  FOR g = C_gXN1 TO C_gC2 DO 
  { callco(curr!g, i)
    activate(curr!g)    // Every gate is initially activated
  }
}

AND setcell(i, s) BE
{ LET curr = cellv!i
  LET prev = cellv!(i-1)
  curr!C_Q1 := s
  curr!C_R1 := s
  curr!C_A  := s
}

AND gXN1fn(i) BE
{ LET curr = cellv!i     // Current cell
  LET next = cellv!(i+1) // Next cell
  LET ip = @next!C_R     // Input signal
  LET op = @curr!C_XN1   // Output signal
  LET g1 = curr!C_gP1    // gates to activate
  LET g2 = curr!C_gQ1    // when output changes
  LET no = !op           // Next output signal
  LET nt = 0             // Time to update the output signal
  LET pt = 0             // Time of last change to 5
  // End of initialisation
  cowait()               // Wait to be resumeco-ed

  { // The input signal may have changed
    // or the output signal is due to change
    // or both
    LET x  = !ip
    LET po = !op                  // Previous output signal
    IF no~=po & nt=time DO
    { !op, po, nt := no, no, 0    // Update the output signal
      IF no=5 DO pt := time
      activateat(g1, time+1)      // and activate gates that
      activateat(g2, time+1)      // depend on it
      IF tracing & curr!C_Id=1 DO
        writef("%i7: Cell %i2 gate XN1 o=%n*n", time, curr!C_Id, no)
    }
    UNLESS nt DO
    { no := notfn(po, x)          // Calculate new output signal
      IF tracing & curr!C_Id=1 DO
        writef("%i7: Cell %i2 gate XN1  ~%n  %n=>%n*n",
                time, curr!C_Id,         x,  po, no)
      UNLESS no=po DO
      { LET d = time-pt
        LET delay = 8 + d/200
        IF delay>10 DO delay := 10
//      IF i=1 DO writef("d=%i6 cell %i2 XN1 gate delay = %n*n", d, i, delay)
        nt := time+delay          // gate propagation delay
        activateat(currco, nt)
      }
    }
    schedule()                    // Wait to be activated
  } REPEAT
}

AND gXN2fn(i) BE
{ LET prev = cellv!(i-1) // Previous cell
  LET curr = cellv!i     // Current cell
  LET next = cellv!(i+1) // Next cell
  LET ip = @next!C_A
  LET op = @curr!C_XN2
  LET g1 = curr!C_gP2
  LET g2 = curr!C_gQ2
  LET no = !op           // Next output signal
  LET nt = 0             // time to update the output signal
  LET pt = 0             // Time of last change to 5
  // End of initialisation
  cowait()               // Wait to be resumeco-ed

  { // The input signal may have changed
    // or the output signal is due to change
    // or both
    LET x = !ip
    LET po = !op
    IF no~=po & nt=time DO
    { !op, po, nt := no, no, 0    // Update the output signal
      IF no=5 DO pt := time
      activateat(g1, time+1)      // and activate gates that
      activateat(g2, time+1)      // depend on it
      IF tracing & curr!C_Id=1 DO
        writef("%i7: Cell %i2 gate XN2 o=%n*n", time, curr!C_Id, no)
    }
    UNLESS nt DO
    { no := notfn(po, x)          // Calculate new output signal
      IF tracing & curr!C_Id=1 DO
        writef("%i7: Cell %i2 gate XN2  ~%n  %n=>%n*n",
                time, curr!C_Id,         x,  po, no)
      UNLESS no=po DO
      { LET d = time-pt
        LET delay = 8 + d/200
        IF delay>10 DO delay := 10
//      IF i=1 DO writef("d=%i6 cell %i2 XN2 gate delay = %n*n", d, i, delay)
        nt := time+delay          // gate propagation delay
        activateat(currco, nt)
      }
    }
    schedule()                    // Wait to be activated
  } REPEAT
}

AND gP1fn(i) BE
{ LET prev = cellv!(i-1) // Previous cell
  LET curr = cellv!i     // Current cell
  LET next = cellv!(i+1) // Next cell
  LET ip1 = @next!C_XN1
  LET ip2 = @curr!C_R
  LET op = @curr!C_P1
  LET g1 = curr!C_gC1
  LET no = !op           // Next output signal
  LET nt = 0             // time to update the output signal
  LET pt = 0             // Time of last change to 5
  // End of initialisation
  cowait()               // Wait to be resumeco-ed

  { // The input signal may have changed
    // or the output signal is due to change
    // or both
    LET x = !ip1
    LET y = !ip2
    LET po = !op
    IF no~=po & nt=time DO
    { !op, po, nt := no, no, 0    // Update the output signal
      IF no=5 DO pt := time
      activateat(g1, time+1)      // and activate gates that depend on it
      IF tracing & curr!C_Id=1 DO
        writef("%i7: Cell %i2 gate P1  o=%n*n", time, curr!C_Id, no)
    }
    UNLESS nt DO
    { no := andfn(po, x, y)       // Calculate new output signal
      IF tracing & curr!C_Id=1 DO
        writef("%i7: Cell %i2 gate P1  %n&%n  %n=>%n*n",
                time, curr!C_Id,       x, y,  po, no)
      UNLESS no=po DO
      { LET d = time-pt
        LET delay = 8 + d/200
        IF delay>10 DO delay := 10
//      IF i=1 DO writef("d=%i6 cell %i2 P1  gate delay = %n*n", d, i, delay)
        nt := time+delay          // gate propagation delay
        activateat(currco, nt)
      }
    }
    schedule()                    // Wait to be activated
  } REPEAT
}

AND gP2fn(i) BE
{ LET prev = cellv!(i-1) // Previous cell
  LET curr = cellv!i     // Current cell
  LET next = cellv!(i+1) // Next cell
  LET ip1 = @curr!C_A
  LET ip2 = @curr!C_XN2
  LET op = @curr!C_P2
  LET g1 = curr!C_gC2
  LET no = !op           // Next output signal
  LET nt = 0            // time to update the output signal
  LET pt = 0             // Time of last change to 5
  // End of initialisation
  cowait()               // Wait to be resumeco-ed

  { // The input signal may have changed
    // or the output signal is due to change
    // or both
    LET x = !ip1
    LET y = !ip2
    LET po = !op
    IF no~=po & nt=time DO
    { !op, po, nt := no, no, 0    // Update the output signal
      IF no=5 DO pt := time
      activateat(g1, time+1)      // and activate gates that depend on it
      IF tracing & curr!C_Id=1 DO
        writef("%i7: Cell %i2 gate P2  o=%n*n", time, curr!C_Id, no)
    }
    UNLESS nt DO
    { no := andfn(po, x, y)       // Calculate new output signal
      IF tracing & curr!C_Id=1 DO
        writef("%i7: Cell %i2 gate P2  %n&%n  %n=>%n*n",
                time, curr!C_Id,       x, y,  po, no)
      UNLESS no=po DO
      { LET d = time-pt
        LET delay = 8 + d/200
        IF delay>10 DO delay := 10
//      IF i=1 DO writef("d=%i6 cell %i2 P2  gate delay = %n*n", d, i, delay)
        nt := time+delay          // gate propagation delay
        activateat(currco, nt)
      }
    }
    schedule()                    // Wait to be activated
  } REPEAT
}

AND gQ1fn(i) BE
{ LET prev = cellv!(i-1) // Previous cell
  LET curr = cellv!i     // Current cell
  LET next = cellv!(i+1) // Next cell
  LET ip1 = @curr!C_XN1
  LET ip2 = @curr!C_R
  LET op = @curr!C_Q1
  LET g1 = curr!C_gR1
  LET no = !op           // Next output signal
  LET nt = 0             // time to update the output signal
  LET pt = 0             // Time of last change to 5
  // End of initialisation
  cowait()               // Wait to be resumeco-ed

  { // The input signal may have changed
    // or the output signal is due to change
    // or both
    LET x = !ip1
    LET y = !ip2
    LET po = !op
    IF no~=po & nt=time DO
    { !op, po, nt := no, no, 0    // Update the output signal
      IF no=5 DO pt := time
      activateat(g1, time+1)      // and activate gates that depend on it
      IF tracing & curr!C_Id=1 DO
        writef("%i7: Cell %i2 gate Q1  o=%n*n", time, curr!C_Id, no)
    }
    UNLESS nt DO
    { no := orfn(po, x, y)        // Calculate new output signal
      IF tracing & curr!C_Id=1 DO
        writef("%i7: Cell %i2 gate Q1  %n|%n  %n=>%n*n",
                time, curr!C_Id,       x, y,  po, no)
      UNLESS no=po DO
      { LET d = time-pt
        LET delay = 8 + d/200
        IF delay>10 DO delay := 10
//      IF i=1 DO writef("d=%i6 cell %i2 Q1  gate delay = %n*n", d, i, delay)
        nt := time+delay          // gate propagation delay
        activateat(currco, nt)
      }
    }
    schedule()                    // Wait to be activated
  } REPEAT
}

AND gQ2fn(i) BE
{ LET prev = cellv!(i-1) // Previous cell
  LET curr = cellv!i     // Current cell
  LET next = cellv!(i+1) // Next cell
  LET ip1 = @curr!C_XN2
  LET ip2 = @curr!C_A
  LET op  = @curr!C_Q2
  LET g1  =  curr!C_gR2
  LET no = !op           // Next output signal
  LET nt = 0             // time to update the output signal
  LET pt = 0             // Time of last change to 5
  // End of initialisation
  cowait()               // Wait to be resumeco-ed

  { // The input signal may have changed
    // or the output signal is due to change
    // or both
    LET x = !ip1
    LET y = !ip2
    LET po = !op
    IF no~=po & nt=time DO
    { !op, po, nt := no, no, 0    // Update the output signal
      IF no=5 DO pt := time
      activateat(g1, time+1)      // and activate gates that depend on it
      IF tracing & curr!C_Id=1 DO
        writef("%i7: Cell %i2 gate Q2  o=%n*n", time, curr!C_Id, no)
    }
    UNLESS nt DO
    { no := orfn(po, x, y)        // Calculate new output signal
      IF tracing & curr!C_Id=1 DO
        writef("%i7: Cell %i2 gate Q2  %n|%n  %n=>%n*n",
                time, curr!C_Id,       x, y,  po, no)
      UNLESS no=po DO
      { LET d = time-pt
        LET delay = 8 + d/200
        IF delay>10 DO delay := 10
//      IF i=1 DO writef("d=%i6 cell %i2 Q2  gate delay = %n*n", d, i, delay)
        nt := time+delay          // gate propagation delay
        activateat(currco, nt)
      }
    }
    schedule()                    // Wait to be activated
  } REPEAT
}

AND gR1fn(i) BE
{ LET prev = cellv!(i-1) // Previous cell
  LET curr = cellv!i     // Current cell
  LET next = cellv!(i+1) // Next cell
  LET ip1 = @curr!C_Q1
  LET ip2 = @curr!C_A
  LET op = @curr!C_R1
  LET g1 = curr!C_gC1
  LET no = !op           // Next output signal
  LET nt = 0             // time to update the output signal
  LET pt = 0             // Time of last change to 5
  // End of initialisation
  cowait()               // Wait to be resumeco-ed

  { // The input signal may have changed
    // or the output signal is due to change
    // or both
    LET x = !ip1
    LET y = !ip2
    LET po = !op
    IF no~=po & nt=time DO
    { !op, po, nt := no, no, 0    // Update the output signal
      IF no=5 DO pt := time
      activateat(g1, time+1)      // and activate gates that depend on it
      IF tracing & curr!C_Id=1 DO
        writef("%i7: Cell %i2 gate R1  o=%n*n", time, curr!C_Id, no)
    }
    UNLESS nt DO
    { no := andfn(po, x, y)       // Calculate new output signal
      IF tracing & curr!C_Id=1 DO
        writef("%i7: Cell %i2 gate R1  %n&%n  %n=>%n*n",
                time, curr!C_Id,       x, y,  po, no)
      UNLESS no=po DO
      { LET d = time-pt
        LET delay = 8 + d/200
        IF delay>10 DO delay := 10
//      IF i=1 DO writef("d=%i6 cell %i2 R1  gate delay = %n*n", d, i, delay)
        nt := time+delay          // gate propagation delay
        activateat(currco, nt)
      }
    }
    schedule()                    // Wait to be activated
  } REPEAT
}

AND gR2fn(i) BE
{ LET prev = cellv!(i-1) // Previous cell
  LET curr = cellv!i     // Current cell
  LET next = cellv!(i+1) // Next cell
  LET ip1 = @curr!C_Q2
  LET ip2 = @next!C_R
  LET op = @curr!C_R2
  LET g1 = curr!C_gC2
  LET no = !op           // Next output signal
  LET nt = 0             // time to update the output signal
  LET pt = 0             // Time of last change to 5
  // End of initialisation
  cowait()               // Wait to be resumeco-ed

  { // The input signal may have changed
    // or the output signal is due to change
    // or both
    LET x = !ip1
    LET y = !ip2
    LET po = !op
    IF no~=po & nt=time DO
    { !op, po, nt := no, no, 0    // Update the output signal
      IF no=5 DO pt := time
      activateat(g1, time+1)      // and activate gates that depend on it
      IF tracing & curr!C_Id=1 DO
        writef("%i7: Cell %i2 gate R2  o=%n*n", time, curr!C_Id, no)
    }
    UNLESS nt DO
    { no := andfn(po, x, y)       // Calculate new output signal
      IF tracing & curr!C_Id=1 DO
        writef("%i7: Cell %i2 gate R2  %n&%n  %n=>%n*n",
                time, curr!C_Id,       x, y,  po, no)
      UNLESS no=po DO
      { LET d = time-pt
        LET delay = 8 + d/200
        IF delay>10 DO delay := 10
//      IF i=1 DO writef("d=%i6 cell %i2 R2  gate delay = %n*n", d, i, delay)
        nt := time+delay          // gate propagation delay
        activateat(currco, nt)
      }
    }
    schedule()                    // Wait to be activated
  } REPEAT
}

AND gC1fn(i) BE
{ LET prev = cellv!(i-1) // Previous cell
  LET curr = cellv!i     // Current cell
  LET next = cellv!(i+1) // Next cell
  LET ip1 = @curr!C_P1
  LET ip2 = @curr!C_R1
  LET op = @curr!C_A
  LET g1 = curr!C_gP2
  LET g2 = curr!C_gQ2
  LET g3 = prev!C_gXN2
  LET no = !op           // Next output signal
  LET nt = 0             // time to update the output signal
  LET pt = 0             // Time of last change to 5
  // End of initialisation
  cowait()               // Wait to be resumeco-ed

  { // The input signal may have changed
    // or the output signal is due to change
    // or both
    LET x = !ip1
    LET y = !ip2
    LET po = !op
    LET delay = 15
    IF no~=po & nt=time DO
    { !op, po, nt := no, no, 0    // Update the output signal
      IF no=5 DO pt := time
      activateat(g1, time+1)      // and activate gates that depend on it
      activateat(g2, time+1)
      activateat(g3, time+1)
      IF tracing & curr!C_Id=1 DO
        writef("%i7: Cell %i2 gate C1  o=%n*n", time, curr!C_Id, no)
    }
    UNLESS nt DO
    { no := orfn(po, x, y)        // Calculate new output signal
      IF tracing & curr!C_Id=1 DO
        writef("%i7: Cell %i2 gate C1  %n|%n  %n=>%n*n",
                time, curr!C_Id,       x, y,  po, no)
      UNLESS no=po DO
      { LET d = time-pt
        LET delay = 8 + d/200
        IF delay>10 DO delay := 10
//      IF i=1 DO writef("d=%i6 cell %i2 C1  gate delay = %n*n", d, i, delay)
        nt := time+delay          // gate propagation delay
        activateat(currco, nt)
      }
    }
    schedule()                    // Wait to be activated
  } REPEAT
}

AND gC2fn(i) BE
{ LET prev = cellv!(i-1) // Previous cell
  LET curr = cellv!i     // Current cell
  LET next = cellv!(i+1) // Next cell
  LET ip1 = @curr!C_P2
  LET ip2 = @curr!C_R2
  LET op  = @next!C_R
  LET g1  =  curr!C_gXN1
  LET g2  =  next!C_gP1
  LET g3  =  next!C_gQ1
  LET no  = !op          // Next output signal
  LET nt  = 0            // time to update the output signal
  LET pt  = 0            // Time last set to 5
  // End of initialisation
  cowait()               // Wait to be resumeco-ed

  { // The input signal may have changed
    // or the output signal is due to change
    // or both
    LET x = !ip1
    LET y = !ip2
    LET po = !op
    IF no~=po & nt=time DO
    { !op, po, nt := no, no, 0    // Update the output signal
      IF no=5 DO pt := time
      activateat(g1, time+1)      // and activate gates that depend on it
      activateat(g2, time+1)
      activateat(g3, time+1)
      IF tracing & curr!C_Id=1 DO
        writef("%i7: Cell %i2 gate C2  o=%n*n", time, curr!C_Id, no)
    }
    UNLESS nt DO
    { no := orfn(po, x, y)        // Calculate new output signal
      IF tracing & curr!C_Id=1 DO
        writef("%i7: Cell %i2 gate C2  %n|%n  %n=>%n*n",
                time, curr!C_Id,       x, y,  po, no)
      UNLESS no=po DO
      { LET d = time-pt
        LET delay = 8 + d/200
        IF delay>10 DO delay := 10
//      IF i=1 DO writef("d=%i6 cell %i2 C2  gate delay = %n*n", d, i, delay)
        nt := time+delay          // gate propagation delay
        activateat(currco, nt)
      }
    }
    schedule()                    // Wait to be activated
  } REPEAT
}

AND notfn(oldr, x) = VALOF
{ LET t = TABLE 5,5,4,1,0,0
  RESULTIS (4*oldr+5*t!x+4)/9
} 

AND andfn(oldr, x, y) = VALOF
{ LET t = TABLE 0,0,1,4,5,5
  LET r = (t!x*t!y+3)/5
  RESULTIS (4*oldr + 5*r + 4)/9
}

AND orfn(oldr, x, y) = VALOF
{ LET t = TABLE 5,5,4,1,0,0
  LET r = 5 - (t!x*t!y+3)/5
  RESULTIS (4*oldr + 5*r + 4)/9
}

AND start() = VALOF
{ LET argv = VEC 50
  LET stdout = output()
  LET tostream = 0
  LET celln = 20

  UNLESS rdargs("-p/k,-r/k,-t/s,-n/k,-o/k", argv, 50) DO
  { writef("Bad arguments for async*n")
    RESULTIS 0
  }

  simperiod := 10000       // Simulation period
  repperiod :=   100

  IF argv!0 DO simperiod := str2numb(argv!0)       // -p n
  IF argv!1 DO repperiod := str2numb(argv!1)       // -r n
  IF repperiod>simperiod DO repperiod := simperiod
  tracing := argv!2                                // -t
  IF argv!3 DO celln     := str2numb(argv!3)       // -n n

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
  mindt := 10000
  maxdt := 0

  mkcircuit(celln)
/*
  writef("And function*n")
  FOR x = 0 TO 5 DO
  { writef("%i3: ", x)
    FOR y = 0 TO 5 DO
    { LET r = 0
      FOR i = 0 TO 4 DO
      { writef("%n", r)
        r := andfn(r, x, y)
      }
      wrch(' ')
      r := 5
      FOR i = 0 TO 4 DO
      { writef("%n", r)
        r := andfn(r, x, y)
      }
      wrch(' ')
    }
    newline()
  }
  writef("Or function*n")
  FOR x = 0 TO 5 DO
  { writef("%i3: ", x)
    FOR y = 0 TO 5 DO
    { LET r = 0
      FOR i = 0 TO 4 DO
      { writef("%n", r)
        r := orfn(r, x, y)
      }
      wrch(' ')
      r := 5
      FOR i = 0 TO 4 DO
      { writef("%n", r)
        r := orfn(r, x, y)
      }
      wrch(' ')
    }
    newline()
  }
  writef("Not function*n")
  FOR x = 0 TO 5 DO
  { writef("%i3: ", x)
    { LET r = 0
      FOR i = 0 TO 4 DO
      { writef("%n", r)
        r := notfn(r, x)
      }
      wrch(' ')
      r := 5
      FOR i = 0 TO 4 DO
      { writef("%n", r)
        r := notfn(r, x)
      }
      wrch(' ')
    }
    newline()
  }
*/

  { LET rep  = initco(reportfn, 200, repperiod)

    activateat(rep, 1)

    { LET e = getevent()
      IF e DO callco(S_c!e)
    }

    deleteco(rep)
  }

fin:
  IF cellv DO freecircuit()
  IF spacev DO freevec(spacev)
  IF heap   DO freevec(heap)
  IF tostream & tostream~=stdout DO endwrite()
  selectoutput(stdout)
  RESULTIS 0
}

AND schedule() = VALOF
{ LET e = getevent()
  LET cptr = ?
//STATIC { prevt=0 }
//UNLESS prevt=S_t!e DO
//{ writef("%i7: schedule*n", time)
//  prreport()
//  prevt := S_t!e
//}
  UNLESS e DO cowait() // No events left -- return to main program
  time, cptr := S_t!e, S_c!e
  freeblk(e)
  IF time>simperiod DO cowait() // Return to main program
  RESULTIS resumeco(cptr)
}

// Heap implementation of the priority queue
AND getevent() = VALOF
{ LET e = heap!1
  UNLESS heapn RESULTIS 0  // If no more events
  // heap!1 is now empty
  downheap(heap, heap!heapn, 1, heapn-1)
  heapn := heapn-1
//writef("getevent: t=%n c=%n*n", e!S_t, e!S_c)
//pr()
  RESULTIS e
}

// Insert an event into the priority queue
// The event's delay must be less than maxint/2
AND putevent(e) BE
{ heapn := heapn + 1
  upheap(heap, e, heapn)
//writef("putevent: t=%n c=%n*n", e!S_t, e!S_c)
//pr()
//IF e!S_c=0 DO abort(1111)
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


