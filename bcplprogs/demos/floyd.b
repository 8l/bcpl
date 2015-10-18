/*
A demonstration program implemented in BCPL
by Martin Richards (c) June 2005

This is a simple implementation of Floyd's Algorithm to find
the cost of the cheapest path from any vertex i to any vertex j
in a directed graph where the cost of a direct edge i->j is c!i!j.
The algorthm also fills in the matrix r so that if there is a path
from i->j then r!i!j to the first vertex to goto on a cheapest path.

Usage:

floyd n <number of vertices> e <number of edges out of each vertex>
      seed <the random number seed>

eg:

floyd n 16 e 2 seed 1234

The costs are randomly chosen in the range 0 to 100.

The program checks the correctness of the entries in r.
*/
GET "libhdr"

MANIFEST {
  Inf = maxint/2  // Special value indication no edge
}

GLOBAL {
  spacev:ug  // Space for the matrices
  spacep     // Pointer to next position in spacev
  c          // c!i!j = Inf  if no edge from -->j
             // else  = cost of direct edge i->j
  r          // The routes matrix
             // r!i!j = first node to pass through in a cheapest path i->j
             //  else = 0
  n          // The number of vertices
  e          // The number of edges per vertex

  initseed     // Random number seed
}

LET start() = VALOF
{ LET argv = VEC 50

  UNLESS rdargs("n,e,seed", argv, 50) DO
  { writef("Bad argument*n")
    RESULTIS 0
  }

  n, e, initseed := 5, 2, 1
  IF argv!0 & string.to.number(argv!0) DO n        := result2
  IF argv!1 & string.to.number(argv!1) DO e        := result2
  IF argv!2 & string.to.number(argv!2) DO initseed := result2

  IF n<2 DO n := 2
  IF e>n DO e := n

  writef("*nn=%n  e=%n  seed=%n*n", n, e, initseed)

  spacev := getvec(2*(n+1)*(n+1) + 2*(n+1)) // Get space for 2 nxn matrices
  UNLESS spacev DO
  { writef("Unable to allocate the matrices*n")
    RESULTIS 0
  }

  spacep := spacev
  c := spacep; spacep := spacep+n+2
  r := spacep; spacep := spacep+n+2
  FOR i = 1 TO n DO
  { c!i := spacep; spacep := spacep+n+2
    r!i := spacep; spacep := spacep+n+2
  }

  writef("allocated=%n out of %n*n", spacep-spacev, 2*(n+1)*(n+1) + 2*(n+1))
  FOR i = 1 TO n FOR j = 1 TO n DO c!i!j := Inf
  setseed(initseed)
  FOR i = 1 TO 80 DO writef("%n", randno(5))
  newline()

  FOR i = 1 TO n DO // Fill in a random cost matrix
  { LET k, p = 0, ?
    UNTIL k=e DO
    { p := randno(n) REPEATUNTIL c!i!p=Inf
      c!i!p := randno(100)
      k := k+1
    }
  }

  prmat("Cost matrix", c, n)

  floyd(c, r, n)

  prmat("Min cost matrix", c, n)
  prmat("Route matrix",    r, n)
  check(c, r, n)

  IF spacev DO freevec(spacev)
  RESULTIS 0  
}

AND prmat(mess, m, n) BE
{ writef("*n%s:*n", mess)
  FOR i = 1 TO n DO
  { FOR j = 1 TO n DO TEST m!i!j=Inf
                      THEN writef("    -")
                      ELSE writef(" %i4", m!i!j)
    newline()
  }
}

AND floyd(c, r, n) BE
{ FOR i = 1 TO n FOR j = 1 TO n DO r!i!j := c!i!j=Inf -> 0, j 

  FOR k = 1 TO n FOR i = 1 TO n FOR j = 1 TO n DO
  { LET cost = c!i!k + c!k!j
    IF c!i!j > cost DO 
    { c!i!j := cost
      r!i!j := r!i!k
    }
  }
}

AND check(c, r, n) BE
{ FOR i = 1 TO n FOR j = 1 TO n DO
  TEST c!i!j=Inf
  THEN { writef("No path %n->%n*n", i, j)
         UNLESS r!i!j=0 DO writef("ERROR: route element not zero*n") 
       }
  ELSE { LET p, q = r!i!j, ?
         LET cost = c!i!p
         LET total = 0
         writef("%i3:  %n", c!i!j, i)

         { writef("-(%n)->%n", cost, p)
           total := total+cost
//abort(1000)
           IF p=j | p=0 BREAK
           q := r!p!j
           cost := c!p!q
           p := q
         } REPEAT
         writef("   total=%n*n", total)
         UNLESS total=c!i!j DO writef("ERROR: The above total is wrong*n") 
       }
}

