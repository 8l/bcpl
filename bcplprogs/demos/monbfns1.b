// This program calculates the number of monadic boolean 
// functions of n boolean variables

GET "libhdr"

GLOBAL {
  w:     200
  count: 201
  mask:  202
}

MANIFEST { Upb=500000 }

LET start() = VALOF
{ LET argv = VEC 50
  LET stdout = output()
  LET outfile = 0

  UNLESS rdargs("TO/K", argv, 50) DO
  { writes("Bad argument for monfns1*n")
    RESULTIS 20
  }

  IF argv!0 DO outfile := findoutput(argv!0)
  IF outfile DO selectoutput(outfile)

  w := getvec(Upb)
  mask := 0
  FOR n = 0 TO 6 DO // Number of variables
  { count := 0
    w!Upb := 0              // Initially the rim contains just one vertex
    try(0, Upb, Upb, Upb+1) // Start exploring with tset and fset empty
                            // and the rim containing just the origin.
    writef("There are %i7 monotonic boolean fns of %i2 variables*n",
                               count,          n)
    mask := mask<<1 | 1  // mask = 2**n - 1
  }
  freevec(w)

  IF outfile & outfile~=stdout DO endwrite()
  selectoutput(stdout)
  writef("End of run*n")
  RESULTIS 0
}

AND try(p, q, r, s) BE
{ // This function explores the lattice of vertices on an
  // n-dimensional cube.

  // w!0 ... w!(p-1)  (the tset) vertices assigned to true (T).
  // w!q ... w!(r-1)  (the fset) vertices assigned F at this level.
  // w!r ... w!(s-1)  (the rim)  vertices to be assigned.

  // The rim and fset vertices are the same distance from the origin.

  // The exploration allocates the rim vertices to the tset and fset
  // in all possible ways.

  // If the rim and fset are both empty, a new monotonic function
  // has been found causing count is incremented,
  // otherwise try is called again with all distinct successors of
  // the fset that are not forced to be T by the tset.
/*
  writef("tset: ")                         // Debugging output
  FOR i = 0 TO p-1 DO writef("%b4 ", w!i)
  writes("fset: ")
  FOR i = q TO r-1 DO writef("%b4 ", w!i)
  writes("rim: ")
  FOR i = r TO s-1 DO writef("%b4 ", w!i)
  newline()
*/
  IF r<s DO
  { LET x = w!r
    w!p := x
    w!r := w!q
    try(p+1, q+1, r+1, s)  // Try with x assigned to T
    w!q := w!r
    w!r := x
    try(p, q, r+1, s)      // Try with x assigned to F
    RETURN
  }

  IF q>=r
  { count := count+1  // A new monotonic function has been found
//  IF count REM 1000000 = 0 DO writef("count= %i7*n", count)
    RETURN
  }

  // Now construct the new rim consisting of all distinct
  // successors of the fset vertices that are not forced to T
  // by vertices in the tset.

  { LET nq, ns  = q, q

    { LET bit = 1
      UNTIL (bit & mask)=0 DO
      { FOR i = q TO s-1 DO
        { LET x = w!i
          LET y = x | bit
          UNLESS x=y DO
          { LET newvertex = TRUE
//            writef("considering %b4->%b4 bit %b4*n", x, y, bit)
            FOR j = nq TO ns-1 IF y=w!j DO // All rim vertices must be distinct
            { newvertex := FALSE
//              writef("already considered*n")
              BREAK
            }
            IF newvertex FOR j = 0 TO p-1 DO
            { LET t = w!j                // A vertex already assigned T
              IF (t&y)=t DO              // Is y as descendent of t
              { newvertex := FALSE
//                writef("%b4->%b4 forced T by %b4*n", x, y, t)
                BREAK
              }
            }
            IF newvertex DO { nq := nq-1  // Add a vertex to the new rim
                              w!nq := y
//                              writef("new rim vertex: %b4*n", y)
                            }
          }
        }
        bit := bit<<1
      }
    }
    try(p, nq, nq, ns)  // Explore the next level
  }
}

