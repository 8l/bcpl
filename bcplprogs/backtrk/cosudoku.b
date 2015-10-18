// This is a coroutine based program to solve Su Doku problems
// as set in the Times.

// Implemented in BCPL by Martin Richards (c) February 2005

// It consists of a 9x9 grid of cells. Each cell should contain
// a digit in the range 1..9. Every row, column and major 3x3
// square should contain all the digits 1..9. Some cells have
// given values. The problem is to find digits to place in
// the unspecified cells satisfying the constraints.

// A typical problem is:

//  - - -   6 3 8   - - -
//  7 - 6   - - -   3 - 5
//  - 1 -   - - -   - 4 -

//  - - 8   7 1 2   4 - -
//  - 9 -   - - -   - 5 -
//  - - 2   5 6 9   1 - -

//  - 3 -   - - -   - 1 -
//  1 - 5   - - -   6 - 8
//  - - -   1 8 4   - - -

SECTION "cosudoku"

GET "libhdr"

MANIFEST { // Placement bits
N1=1<<0
N2=1<<1
N3=1<<2
N4=1<<3
N5=1<<4
N6=1<<5
N7=1<<6
N8=1<<7
N9=1<<8

a1=0; a2; a3; a4; a5; a6; a7; a8; a9
b1;   b2; b3; b4; b5; b6; b7; b8; b9
c1;   c2; c3; c4; c5; c6; c7; c8; c9
d1;   d2; d3; d4; d5; d6; d7; d8; d9
e1;   e2; e3; e4; e5; e6; e7; e8; e9
f1;   f2; f3; f4; f5; f6; f7; f8; f9
g1;   g2; g3; g4; g5; g6; g7; g8; g9
h1;   h2; h3; h4; h5; h6; h7; h8; h9
i1;   i2; i3; i4; i5; i6; i7; i8; i9


// Coroutine node fields
c_co=0  // Holds the coroutine pointer
c_flag  // =TRUE iff in the stack
c_n     // Number of possible placement for a cell
c_hp    // position in the heap if there, zero otherwise
c_type  // =1, 2, 3 or 4 for a row, column, square and cell coroutines
c_p     // The top leftmost cell covered by this coroutine.

// Coroutine node types
t_row=1; t_col; t_sq; t_cell
}

GLOBAL { count:ug

val            // Vector of current known setting of the cells
               // val!p = 0 if the value for cell p is not yet set
               // otherwise it is the cell value
poss           // Vector of possible placement bit patterns
               // poss!p is the bit pattern of possible setting for
               // cell p, 0 is the value of cell p is already set
cellnode       // cellnode!p is the coroutines for cell p
rownode        // rownode!r is the coroutine for row r
colnode        // colnode!c is the coroutine for column c
sqnode         // sqnode!s is the coroutine for square s
 
heap;  heapn   // The binary heap of nodes
stack; stackp  // Stack of coroutine nodes waiting to be called
fail           // TRUE when no solution possible
}

LET start() = VALOF
{ LET valv      = VEC 80
  AND possv     = VEC 80
  AND cellnodev = VEC 80
  AND rownodev  = VEC  8
  AND colnodev  = VEC  8
  AND sqnodev   = VEC  8
  AND heapv     = VEC 80
  AND stackv    = VEC 3*9 // Only holds row, column and square nodes

  val, poss := valv, possv
  cellnode, rownode, colnode, sqnode := cellnodev, rownodev, colnodev, sqnodev
  heap,  heapn := heapv, 0
  stack, stackp := stackv, 0
  count, fail := 0, FALSE

  FOR p = 0 TO 80 DO val!p, poss!p, cellnode!p := 0, #777, 0
  FOR i = 0 TO  8 DO rownode!i, colnode!i, sqnode!i := 0, 0, 0

  initboard()

  // Create the row coroutines
  FOR row = 0 TO 8 UNLESS initco(linecofn, 400, t_row, 9*row, row) DO
  { writef("Unable to create coroutine for row %n*n", row)
    GOTO ret
  }

  // Create the column coroutines
  FOR col = 0 TO 8 UNLESS initco(linecofn, 400, t_col, col, col)
  { writef("Unable to create coroutine for column %n*n", col)
    GOTO ret
  }

  // Create the square coroutines
  FOR y = 0 TO 2 FOR x = 0 TO 2 DO
  { LET num = 3*y+x
    UNLESS initco(sqcofn, 400, t_sq, 27*y + 3*x, num) DO
    { writef("Unable to create coroutine for square %n*n", num)
      GOTO ret
    }
  }

  // Create the cell coroutines
  FOR p = 0 TO 80 UNLESS initco(cellcofn, 400, t_cell, p) DO
  { writef("Unable to create coroutine for cell %n*n", p)
    GOTO ret
  }

  writef("*n*nCalling search*n")

  search() // Find and print solution(s)

  writef("*n*nTotal number of solutions: %n*n", count)

ret:

  FOR pos = 0 TO 80 IF cellnode!pos DO deleteco(cellnode!pos!c_co)
  FOR row = 0 TO  8 IF rownode!row  DO deleteco(rownode!row!c_co)
  FOR col = 0 TO  8 IF colnode!col  DO deleteco(colnode!col!c_co)
  FOR sq  = 0 TO  8 IF sqnode!sq    DO deleteco(sqnode!sq!c_co)
  RESULTIS 0
}

AND initboard() BE
{
LET v = val
  
v!a1,v!a2,v!a3,v!a4,v!a5,v!a6,v!a7,v!a8,v!a9 :=  0, 0, 0, N6,N3,N8,  0, 0, 0
v!b1,v!b2,v!b3,v!b4,v!b5,v!b6,v!b7,v!b8,v!a9 := N7, 0,N6,  0, 0, 0, N3, 0,N5
v!c1,v!c2,v!c3,v!c4,v!c5,v!c6,v!c7,v!c8,v!a9 :=  0,N1, 0,  0, 0, 0,  0,N4, 0
v!d1,v!d2,v!d3,v!d4,v!d5,v!d6,v!d7,v!d8,v!a9 :=  0, 0,N8, N7,N1,N2, N4, 0, 0
v!e1,v!e2,v!e3,v!e4,v!e5,v!e6,v!e7,v!e8,v!a9 :=  0,N9, 0,  0, 0, 0,  0,N5, 0
v!f1,v!f2,v!f3,v!f4,v!f5,v!f6,v!f7,v!f8,v!a9 :=  0, 0,N2, N5,N6,N9, N1, 0, 0
v!g1,v!g2,v!g3,v!g4,v!g5,v!g6,v!g7,v!g8,v!a9 :=  0,N3, 0,  0, 0, 0,  0,N1, 0
v!h1,v!h2,v!h3,v!h4,v!h5,v!h6,v!h7,v!h8,v!a9 := N1, 0,N5,  0, 0, 0, N6, 0,N8
v!i1,v!i2,v!i3,v!i4,v!i5,v!i6,v!i7,v!i8,v!a9 :=  0, 0, 0, N1,N8,N4,  0, 0, 0

//FOR p = 0 TO 80 DO v!p := 0
//v!a1 := N1
//v!c1,v!c2,v!c3,v!c4,v!c5,v!c6,v!c7,v!c8,v!c9 := N1,N2,N3, N4,N5,N6,  0, N8,N9
//v!e4, v!e5 := N3, N4

prboard()
}


AND prboard() BE
{ LET t = TABLE
       0,1,2,0,3,0,0,0, 4,0,0,0,0,0,0,0, 5,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 
       6,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 
       7,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 
       0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 
       8,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 
       0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 
       0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 
       0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,
       9

  writef("*ncount = %n*n", count)

  FOR y = 0 TO 8 DO
  { IF y MOD 3 = 0 DO newline()
    FOR x = 0 TO 8 DO
    { LET p = 9*y + x
      IF x MOD 3 = 0 DO wrch(' ')
      writef(" %n", t!(val!p))
    }
    newline()
  }
  newline()
}

AND prpas() BE
{ FOR y = 0 TO 8 DO
  { IF y MOD 3 = 0 DO newline()
    FOR x = 0 TO 8 DO
    { LET p = 9*y + x
      IF x MOD 3 = 0 DO wrch(' ')
      writef(" %o3", poss!p)
    }
    newline()
  }
  newline()
}

AND search() BE
{ 
  writef("search: entered*n")

  { LET node = pop()
    //writef("search: node %n popped*n", node)

    UNLESS node BREAK

    //writef("search: calling cortn %n stackp=%n*n", node!c_co, stackp)
    //writef("search: type=%n pos=%n*n", node!c_type, node!c_p)
    callco(node!c_co)
    //writef("search: returned from cortn %n*n*n", node!c_co)
    //IF stackp=0 DO abort(5555)
  } REPEAT

//prheap()
//writef("About to call getheap*n")
//abort(1000)
  { LET node = getheap()
    //writef("Node %n from heap*n", node)
    TEST node
    THEN { callco(node!c_co)
         }
    ELSE { //writef("*nHeap empty*n")
           //prboard()
           //prpas()
           RETURN
         }
  }
} REPEAT

AND linecofn(args) BE
{ // The following variables form a coroutine node
  // for placement in the stack for later execution
  LET co, flag, n, hp, type, pos = currco, FALSE, 0, 0, args!0, args!1
  LET num = args!2 // row or column number
  LET str, step = "???", 0

  TEST type=t_row
  THEN str, step, rownode!num := "row", 1, @co
  ELSE str, step, colnode!num := "col", 9, @co
  //writef("Coroutine started for %s %n*n", str, num)

  push(@co) // Push this line coroutine node onto the stack for later
            // processing when all other coroutines have been initialised.

  { LET all   = 0 // For all possible setting in this line
    AND multi = 0 // For possible setting that occur more than once in the line
    LET p = pos

    //writef("Coroutine %n for %s %n going to sleep*n", co, str, num)

    cowait() // Wait until invoked by the driver (in search)

    //writef("Coroutine for %s %n waking up*n", str, num)

    // Does any cell in this line have a forced setting
    FOR i = 0 TO 8 DO
    { LET bits = poss!p
      multi := multi | all & bits
      all := all | bits
      p := p + step
    }

    { LET forced = all - multi // Setting that only occur once in this line
      WHILE forced DO
      { // There are cell(s) with forced settings in this line
        LET bit = forced & -forced
        forced := forced - bit
        p := pos
        FOR i = 0 TO 8 DO
        { IF (poss!p & bit)>0 DO
          { poss!p := poss!p & bit // This cell may have two forced settings!
    //writef("Coroutine for %s %n found cell %n forced %o3*n", str, num, p, bit)
//prboard()
//prpas()
//abort(1000)
            upheap(cellnode!p)         // Schedule the cell coroutine
          }
          p := p + step
        }
      }
    }
  } REPEAT
}

AND sqcofn(args) BE
{ // The following variables form a coroutine node
  // for placement in the stack for later execution
  LET co, flag, n, hp, type, pos = currco, FALSE, 0, 0, args!0, args!1
  LET num = args!2
  LET row, col = pos/9, pos MOD 9

  sqnode!num := @co

  //writef("Coroutine %n started for square %n*n", co, num)
  push(@co) // Push this square coroutine node onto the stack for later
            // processing when all other coroutines have been initialised.


  { LET bits, forced, all, multi = ?, ?, 0, 0

    //writef("Coroutine for square %n going to sleep*n", num)
    cowait()
    //writef("Coroutine for square %n has woken up*n", num)

    // Does any cell in this square have a forced setting
    
    bits := poss!(pos+00) ; multi := multi | all & bits; all := all | bits
    bits := poss!(pos+01) ; multi := multi | all & bits; all := all | bits
    bits := poss!(pos+02) ; multi := multi | all & bits; all := all | bits
    bits := poss!(pos+09) ; multi := multi | all & bits; all := all | bits
    bits := poss!(pos+10) ; multi := multi | all & bits; all := all | bits
    bits := poss!(pos+11) ; multi := multi | all & bits; all := all | bits
    bits := poss!(pos+18) ; multi := multi | all & bits; all := all | bits
    bits := poss!(pos+19) ; multi := multi | all & bits; all := all | bits
    bits := poss!(pos+20) ; multi := multi | all & bits; all := all | bits

    // First look for force settings of cells within the square
    forced := all - multi // Setting that only occur once in this line

//    IF forced DO
//      writef("Coroutine for square %n found forced %o3*n", num, forced)

    WHILE forced DO
    { // There are cell(s) with forced settings in this line
      LET w = forced & -forced // One of the forced bits
      LET p, x = ?, ?
      forced := forced - w

      p := pos+00; x := poss!p & w; IF x DO { poss!p := x; upheap(cellnode!p) }
      p := pos+01; x := poss!p & w; IF x DO { poss!p := x; upheap(cellnode!p) }
      p := pos+02; x := poss!p & w; IF x DO { poss!p := x; upheap(cellnode!p) }
      p := pos+09; x := poss!p & w; IF x DO { poss!p := x; upheap(cellnode!p) }
      p := pos+10; x := poss!p & w; IF x DO { poss!p := x; upheap(cellnode!p) }
      p := pos+11; x := poss!p & w; IF x DO { poss!p := x; upheap(cellnode!p) }
      p := pos+18; x := poss!p & w; IF x DO { poss!p := x; upheap(cellnode!p) }
      p := pos+19; x := poss!p & w; IF x DO { poss!p := x; upheap(cellnode!p) }
      p := pos+20; x := poss!p & w; IF x DO { poss!p := x; upheap(cellnode!p) }

//      prboard()
//      prpas()
//abort(6666)
    }

    // Now look for setting that must be set somewhere in the three
    // cells of a row (or column) in the square. Such setting will be
    // disallowed elsewhere in the row (or column)
    { LET a,b,c = poss!(pos+00), poss!(pos+01), poss!(pos+02)
      AND d,e,f = poss!(pos+09), poss!(pos+10), poss!(pos+11)
      AND g,h,i = poss!(pos+18), poss!(pos+19), poss!(pos+20)

      forced := forcedbits(a,b,c)
      IF forced FOR i = 0 TO 6 BY 3 UNLESS i=col DO
                { LET j = 9*row + i
                  FOR p = j TO j+2 DO
                  { LET w = poss!p & forced
                    IF w DO { poss!p := poss!p - w
                              upheap(cellnode!p)
//prboard(); prpas(); abort(7777)
                            }
                  }
                }
      forced := forcedbits(d,e,f)
      IF forced FOR i = 0 TO 6 BY 3 UNLESS i=col DO
                { LET j = 9*(row+1) + i
                  FOR p = j TO j+2 DO
                  { LET w = poss!p & forced
                    IF w DO { poss!p := poss!p - w
                              upheap(cellnode!p)
//prboard(); prpas(); abort(7777)
                            }
                  }
                }
      forced := forcedbits(g,h,i)
      IF forced FOR i = 0 TO 6 BY 3 UNLESS i=col DO
                { LET j = 9*(row+2) + i
                  FOR p = j TO j+2 DO
                  { LET w = poss!p & forced
                    IF w DO { poss!p := poss!p - w
                              upheap(cellnode!p)
//prboard(); prpas(); abort(7777)
                            }
                  }
                }

      forced := forcedbits(b,e,h)
      IF forced FOR i = 0 TO 6 BY 3 UNLESS i=row DO
                { LET j = col +1 + 9*i
                  FOR p = j TO j+18 BY 9 DO
                  { LET w = poss!p & forced
                    IF w DO { poss!p := poss!p - w
                              upheap(cellnode!p)
//prboard(); prpas(); abort(7777)
                            }
                  }
                }

      forced := forcedbits(c,f,i)
      IF forced FOR i = 0 TO 6 BY 3 UNLESS i=row DO
                { LET j = col + 2 + 9*i
                  FOR p = j TO j+18 BY 9 DO
                  { LET w = poss!p & forced
                    IF w DO { poss!p := poss!p - w
                              upheap(cellnode!p)
//prboard(); prpas(); abort(7777)
                            }
                  }
                }

      forced := forcedbits(a,d,g)
      IF forced FOR i = 0 TO 6 BY 3 UNLESS i=row DO
                { LET j = col + 9*i
                  FOR p = j TO j+18 BY 9 DO
                  { LET w = poss!p & forced
                    IF w DO { poss!p := poss!p - w
                              upheap(cellnode!p)
//prboard(); prpas(); abort(7777)
                            }
                  }
                }

    }
  } REPEAT
}

AND forcedbits(a,b,c) = VALOF
{ LET w = a|b|c
  LET n = bits(w)
  IF n=2 | n=3 DO
  {
//writef("forcedbits: %o3 %o3 %o3 => %o3  n=%n*n", a, b, c, w, n)
//abort(8888)
    RESULTIS w
  }
  RESULTIS 0
} 

AND cellcofn(args) BE
{ // The following variables form a coroutine node
  // for placement in the stack for later execution
  LET co, flag, n, hp, type, pos = currco, FALSE, 0, 0, args!0, args!1
  LET rowno, colno = pos/9, pos MOD 9
  LET sqno = 3*(rowno/3) + colno/3
  LET nv = VEC 8+6+6 // Vector of related positions
                     // 8 others cells in the current square
                     // 6 in current row not in current square
                     // 6 in current column in current square.

  cellnode!pos := @co
                     
  // Initialise the related positions vector
  { LET k = 0
    FOR p = 0 TO 80 DO UNLESS p=pos DO
    { LET rno, cno = p/9, p MOD 9
      LET sno = 3*(rno/3) + cno/3
      IF rno=rowno | cno=colno | sno=sqno DO
      { k := k+1
        nv!k := p
        //writef("nv!%i2: pos=%i2  p=%i2*n", k, pos, p)
      }
    }
  }

  //writef("cellco coroutine %n started, pos=%n row=%n, col=%n, sq=%n*n",
  //        co, pos, rowno, colno, sqno)

  IF val!pos DO poss!pos := val!pos

  heapinsert(@co)

  {
    //writef("Coroutine for cell %n going to sleep*n", pos)
    cowait()
    // The node for this coroutine has just been extracted from the heap
    //writef("Coroutine for cell %n has woken up*n", pos)

    n := bits(poss!pos)

    writef("Cell %n bits=%o3 n=%n*n", pos, poss!pos, n)

    IF n=1 DO
    { LET bit = poss!pos
      LET mask = bit XOR #777
      val!pos := bit
      poss!pos := 0
      writef("Cell %n set to %o3*n", pos, bit)
      prboard()
      prpas()
abort(7777)
      // Stop this setting from being used anywhere else in the
      // current row, column or square.
      FOR i = 1 TO 8+6+6 DO
      { LET p = nv!i
        LET w = poss!p & bit
        //writef("Cell %n i=%i2*n", pos, i)
        //writef("Cell %n consider poss!%n = %o3*n", pos, p, poss!p)
        IF w DO { LET node = cellnode!p
                  poss!p := poss!p - w
                  //writef("Cell %n changing poss!%n to %o3*n", pos, p, poss!p)
//writef("node=%n co=%n flag=%n n=%n hp=%n type=%n pos=%n*n",
//        node, node!c_co, node!c_flag,
//        node!c_n, node!c_hp, node!c_type, node!c_p)
                  upheap(node)
                  //prboard(); prpas()
                  //abort(3333)
                }
      }

      // Tell related row, column and square coroutines to wakeup
      push(rownode!rowno)
      push(colnode!colno)
      push(sqnode!sqno)

      cowait()
      // This coroutine will not wake up

    }

    prboard()
    prpas()
    prheap()
    writef("minimum choice was pos=%n bits=%o3 n=%n*n", pos, poss!pos, n)
    abort(9999)
    cowait()

  } REPEAT
}

AND push(node) BE UNLESS node!c_flag DO
{ node!c_flag := TRUE      // Mark as on the stack
  stackp :=stackp+1
  stack!stackp := node
  //writef("push: node=%n*n", node)
  //writef("push: co=%n flag=%n n=%n hp=%n type=%n pos=%n*n",
  //        node!c_co, node!c_flag, node!c_n, node!c_hp, node!c_type, node!c_p)
  //abort(1111)
}

AND pop() = VALOF
{ LET node = 0
  //writef("pop: stackp=%n*n", stackp)
  IF stackp DO { node := stack!stackp
                 node!c_flag := FALSE
                 //writef("pop: node=%n*n", node)
                 //writef("pop: co=%n flag=%n n=%n hp=%n type=%n pos=%n*n",
                 //        node!c_co, node!c_flag,
                 //        node!c_n, node!c_hp,
                 //        node!c_type, node!c_p)
                 stackp := stackp-1
               }
  //abort(1111)
  RESULTIS node
}

AND bits(w) = w=0 -> 0, 1 + bits(w & w-1)

AND checkheap() BE
{ FOR i = heapn TO 2 BY -1 DO
  { LET p = i/2
    LET np = heap!p
    AND ni = heap!i
    UNLESS np!c_hp=p & ni!c_hp=i & np!c_n<=ni!c_n DO
    { prboard()
      prpas()
      prheap()
      writef("Bad heap p=%n i=%n hp links %n %n *n", p, i, np!c_hp, ni!c_hp)
      abort(999)
    }
  }
  IF heap!1!c_n=0 DO 
      writef("Bad heap root node for cell %n has n=0*n", heap!1!c_p)
}

AND heapinsert(node) BE
{ heapn := heapn+1
  heap!heapn := node
  node!c_hp := heapn
  upheap(node)
}

AND upheap(node) BE
{ LET i = node!c_hp
  LET pos = node!c_p
  LET n = bits(poss!pos)
  node!c_n := n
//prheap()
//writef("upheap: node=%n i=%i2 pos=%i2 n=%n*n", node, i, pos, n)

  UNTIL i=1 DO
  { LET p = i/2         // The parent
    LET nodep = heap!p
    IF nodep!c_n <= n BREAK
    //writef("upheap: swapping nodes at p=%i2 and i=%i2*n", p, i)
    heap!i := nodep
    nodep!c_hp := i
    i := p
  }

  //writef("upheap: node stored at i=%i2*n", i)
  heap!i := node   // Store the node in its proper place
  node!c_hp := i
  checkheap()
  //prheap()
//abort(1000)
}

AND getheap() = heapn=0 -> 0, VALOF
// Extract the smallest element from the heap, if any.
{ LET res = heap!1
  LET node= heap!heapn
//prheap()
//writef("getheap: extracting node for pos=%n n=%n*n", res!c_p, res!c_n)
  heapn := heapn-1
  downheap(node, 1)
  //prheap()
//abort(1000)
  RESULTIS res  
}

AND downheap(node, i) BE
{ LET n = node!c_n
//writef("downheap: called with node for pos=%n n=%n*n", node!c_p, n)

  { LET j = 2*i // Left child position
    LET k = j+1 // Right child position
    IF k<=heapn & heap!j!c_n > heap!k!c_n DO j := k
    //writef("downheap: i=%i2 j=%i2 k=%i2 heapn=%i2*n", i, j, k, heapn)
    // j is the right child if it exists and is better.
    IF j>heapn | heap!j!c_n >= n BREAK
    // The smaller child exits and is better than node.
    heap!i := heap!j
    heap!i!c_hp := i
    i := j
  } REPEAT
    
  //writef("downheap: node for %n placed in i=%n*n", node!c_p, i)
  heap!i := node
  node!c_hp := i
  checkheap()
  //prheap()
}

AND prheap() BE
{ FOR i = 1 TO heapn DO
  { LET node = heap!i
    writef(" %i2:%i2/%n", i, node!c_p, node!c_n)
    IF i MOD 9 = 0 DO newline()
  }
  newline()
}
