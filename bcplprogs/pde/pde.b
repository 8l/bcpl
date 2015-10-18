SECTION "pde"

GET "libhdr"

LET start() = VALOF
{ LET n, k = 22, 100000
  LET tracing = ?
  LET iterations = 0
  LET gridv, gridupb = ?, ?
  LET argv = VEC 50
  
  UNLESS rdargs("-n/N,-k/N,-t/S", argv, 50) DO
  { writes("Bad arguments for pde*n")
    RESULTIS 0
  }

  IF argv!0 DO n := argv!0!0 // -n The size of the grid
  IF argv!1 DO k := argv!1!0 // -k The maximum number of iterations
  tracing := argv!2          // -t

  gridupb := (n+2)*(n+2)-1
  gridv := getvec(gridupb)
  UNLESS gridv DO
  { writef("Unable to allocate gridv*n")
    RESULTIS 0
  }
  // Solve Laplace's equation over the square region with
  // the left hand edge set to 0.000 and the other three
  // edges set to 100.000

  // Use scaled arithmetic with 3 digits after the decimal point.

  // Clear the whole grid including the left hand edge.
  FOR i = 0 TO gridupb DO gridv!i := 0
  // Set the top edge to 100.000
  FOR i = 1 TO n+1 DO gridv!i := 100000
  // Set the right hand edge to 100.000
  FOR i = 1 TO n   DO (gridv + i * (n+2))!(n+1) := 100000
  // Set the bottom edge to 100.000
  FOR i = 1 TO n+1 DO (gridv + (n+1) * (n+2))!i := 100000
  
 // Try setting the mid point to 100.000
 //(gridv + ((n+1)/2) * (n+2))!((n+1)/2) := 100000

  FOR i = 1 TO k DO
  { LET maxerr = ?
    IF tracing DO pr(gridv, n)
    maxerr := pde(gridv, n)
    writef("*nIteration %i3  maxerror = %7.3d*n", i, maxerr)
    IF maxerr=0 BREAK
    iterations := i
  }
  writef("*nFinal result*n")
  pr(gridv, n)

  writef("*n%n iterations were required*n", iterations)

  freevec(gridv)
  RESULTIS 0
}

AND pr(v, n) BE
{ FOR j = 0 TO n+1
  { LET row = @ v!(j * (n+2))
    FOR i = 0 TO n+1 DO
    { IF i REM 12 = 0 TEST i=0
      THEN writef("%i4: ", j)
      ELSE writef("*n      ")
      writef(" %7.3d", row!i)
    }
    newline()
  }
  newline()
}

AND pde(v,n) = VALOF
{ // Apply successive over relation (SOR)
  LET maxerror = 0
  FOR j = 0 TO n-1 DO
  { LET row1 = v + (j * (n+2))
    LET row2 = row1 + (n+2)
    LET row3 = row2 + (n+2)
    FOR i = 1 TO n DO
    { // Pattern:     a
      //            b x c
      //              d
      // Estimated new value for x is (a+b+c+d)/4
      LET new   = (row1!i + row2!(i-1) + row2!(i+1) + row3!i)/4
      // The change is delta
      LET delta = new - row2!i
      LET error = ABS delta
      // Number of iterations required for convergence
      // (with n=22 or n=64) depends on the value of factor (which
      // gives the percentage of over relaxation)

      //                      iterations for
      //                     n=8  n=22   n=64
      //LET factor =  0 //    85  474    2940
      //LET factor = 25 //    58  346    2278
      //LET factor = 48 //    33  249    1740
      //LET factor = 49 //    32  246    1729
      //LET factor = 50 //    21  207    1408 -- the best for n=8
      //LET factor = 51 //    21  205    1401
      //LET factor = 52 //    24  203    1389
      //LET factor = 53 //    23  199    1377
      //LET factor = 54 //    25  197    1361
      //LET factor = 75 //    41  105     935
      //LET factor = 76 //    41  103     925
      //LET factor = 77 //    45   64     915
      //LET factor = 78 //    44   63     898
      LET factor = 79 //    45   63     885 -- the best for n=22
      //LET factor = 80 //    48   63     850
      //LET factor = 81 //    52   71     842
      //LET factor = 90 //    90   99     628
      //LET factor = 91 //    96  109     544
      //LET factor = 92 //   110  120     179 -- ?????????????
      //LET factor = 93 //   123  143     303
      //LET factor = 94 //   137  148     300
      //LET factor = 95 //   163  197     263 -- the best for n=64?
      //LET factor = 96 //   199  208     321
      //LET factor = 97 //   255  270     376
      //LET factor = 98 //   357  371     440
      //LET factor = 99 //   646  649     698

      IF maxerror < error DO maxerror := error
      // For n=22 
      row2!i := new + delta*factor/100
    }
  }
  RESULTIS maxerror
}
