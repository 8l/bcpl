/*
This is a program to find the best sequence of tests to find the median
of N integers. N = 5 or 7.

Implemented in BCPL by Martin Richards (c) October 2005
*/

SECTION "medfind"

GET "libhdr"

MANIFEST { 
 // Bit patterns representing the test
 t12 = 1<< 0  //  v1 <= v2
 t13 = 1<< 1  //  v1 <= v3
 t23 = 1<< 2  //  v2 <= v3
 t14 = 1<< 3  //  v1 <= v4
 t24 = 1<< 4  //  v2 <= v4
 t34 = 1<< 5  //  v3 <= v4
 t15 = 1<< 6  //  v1 <= v5
 t25 = 1<< 7  //  v2 <= v5
 t35 = 1<< 8  //  v3 <= v5
 t45 = 1<< 9  //  v4 <= v5

 t16 = 1<<10  //  v1 <= v6
 t26 = 1<<11  //  v2 <= v6
 t36 = 1<<12  //  v3 <= v6
 t46 = 1<<13  //  v4 <= v6
 t56 = 1<<14  //  v5 <= v6

 t17 = 1<<15  //  v1 <= v7
 t27 = 1<<16  //  v2 <= v7
 t37 = 1<<17  //  v3 <= v7
 t47 = 1<<18  //  v4 <= v7
 t57 = 1<<19  //  v5 <= v7
 t67 = 1<<20  //  v6 <= v7

 t2bits = t12
 t3bits = t13+t23
 t4bits = t14+t24+t34
 t5bits = t15+t25+t35+t45
 t6bits = t16+t26+t36+t46+t56
 t7bits = t17+t27+t37+t47+t57+t67

 t12bits      = t2bits
 t123bits     = t3bits + t12bits
 t1234bits    = t4bits + t123bits
 t12345bits   = t5bits + t1234bits
 t123456bits  = t6bits + t12345bits
 t1234567bits = t7bits + t123456bits

 maxdepth = 14  // Maximum number of comparisons allowed
                // It equals the depth of the heap, counting
                // node 1 as depth 0.
 tvupb = 1<<(maxdepth+1) // upb of tv, ie the number of nodes in the heap

 stkupb = 100_000
}

GLOBAL {
 permupb:ug // The upb of permv etc.
 all        // Bit pattern representing all the tests on N variables.

 permv      // permv!i is the permutation in hex,         eg #x_15243
 tstv       // tstv!i the test results for permutation i  eg #b_0101_101_01_1
            //                                                  |||| ||| || |
            //                                                  |||| ||| || 1<5
            //                                                  |||| ||| |1<2
            //                                                  |||| ||| 5<2
            //                                                  |||| ||1<4
            //                                                  |||| |5<4
            //                                                  |||| 2<4
            //                                                  |||1<3
            //                                                  ||5<3
            //                                                  |2<3
            //                                                  4<3
 medv       // medv!i is the position of the median,      eg 5

// A binary heap-like structure is used to represent the test tree
// If i is the subscript of a node,
//     2i   is the subscript of its left  child
// and 2i+1 is the subscript of its right child.

 tv         // A binary heap-like vector holding the test nodes and
            // leaves of an optimum decision tree. If tv!i>0 it
            // holds a test, if tv!i<0, -tv!i is the position of
            // the median. The elements of tv are set by try(..).

 stkv       // A stack holding permutation numbers used by try(..)

 tostream   // The TO stream, if specified.

 N          // The number of variables, = 5 or 7

 trycount   // Count of test nodes tried by trytest()
 tracing    // Controls tracing output
 cases      // Controls the output of the CASEs code.
}

LET fact(n)      = n=0 -> 1, n*fact(n-1)

LET testcount(n) = // Calculates the number of pairwise comparisons
                   // between n variables.
  n<2 -> 0, n-1+testcount(n-1)

LET start() = VALOF
{ LET argv = VEC 50

  UNLESS rdargs("-n,-o/K,-t/S,-c/S", argv, 50) DO
  { writef("Bad arguments for medfind*n")
    RESULTIS 0
  }

  N := 5
  IF argv!0 & string.to.number(argv!0) DO N := result2  // -n <num>
  UNLESS N=7 DO N := 5
  writef("medfind called with N=%n*n", N)

  tostream := 0
  IF argv!1 DO                                        // -o <filename>
  { tostream := findoutput(argv!1)
    UNLESS tostream DO
    { writef("Unable to open stream %s*n", argv!1)
      RESULTIS 0
    }
    writef("sending the results to file %s*n", argv!1)
  }

  tracing := argv!2                                  // -t
  cases   := argv!3                                  // -c

  permupb := fact(N)
  all     := (1<<testcount(N)) - 1
  tv := getvec(tvupb)
  stkv := getvec(stkupb)
  permv, tstv, medv := getvec(permupb), getvec(permupb), getvec(permupb)

  UNLESS tv & stkv & permv & tstv & medv DO
  { writef("*nGetvec failure*n")
    GOTO fin
  }

  TEST N=5 THEN initperms5()
           ELSE initperms7()

  //FOR p = 1 TO permupb TEST N=5
  //THEN writef("%i3: %n %x5 %bA*n", p, medv!p, permv!p, tstv!p)
  //ELSE writef("%i4: %n %x7 %bL*n", p, medv!p, permv!p, tstv!p)

  // Initialise the stack
  FOR i = 1 TO permupb DO stkv!i := i
  
  trycount := 0

  // Without loss of generality try a<b and assume the result is true.
  FOR i = 0 TO tvupb DO tv!i := 0

  { LET score = try(1, 0, 0, 0, @stkv!1, @stkv!permupb, 10_000_000)
    LET average = score*1000/permupb

    IF tostream DO selectoutput(tostream)

    writef("Test nodes tried = %n*n", trycount)

    writef("*nAverage number of tests to find the median of %n is %n.%z3*n",
           N, average/1000, average MOD 1000)
  }
  newline()
  TEST cases
  THEN prcases(1)
  ELSE prtree(1, 0, 0, 0)

fin:
  IF tostream DO endwrite()
  IF tv       DO freevec(tv)
  IF permv    DO freevec(permv)
  IF tstv     DO freevec(tstv)
  IF medv     DO freevec(medv)
  RESULTIS 0
}

AND initperms5() BE
{ LET p, t, m = permv, tstv, medv
  LET medpos = ?
  FOR v1 = 1 TO N DO
  { IF v1=3 DO medpos := 1
    FOR v2 = 1 TO N UNLESS v2=v1 DO
    { IF v2=3 DO medpos := 2
      FOR v3 = 1 TO N UNLESS v3=v2|v3=v1 DO
      { IF v3=3 DO medpos := 3
        FOR v4 = 1 TO N UNLESS v4=v3|v4=v2|v4=v1 DO
        { IF v4=3 DO medpos := 4
          FOR v5 = 1 TO N UNLESS v5=v4|v5=v3|v5=v2|v5=v1 DO
          { LET bits = 0
            IF v5=3 DO medpos := 5
            IF v1 < v2 DO bits := bits + t12
            IF v1 < v3 DO bits := bits + t13
            IF v2 < v3 DO bits := bits + t23
            IF v1 < v4 DO bits := bits + t14
            IF v2 < v4 DO bits := bits + t24
            IF v3 < v4 DO bits := bits + t34
            IF v1 < v5 DO bits := bits + t15
            IF v2 < v5 DO bits := bits + t25
            IF v3 < v5 DO bits := bits + t35
            IF v4 < v5 DO bits := bits + t45
            t, p, m := t+1, p+1, m+1
            !t := bits
            !p := (((v1<<4|v2)<<4|v3)<<4|v4)<<4|v5
            !m := medpos
          }
        }
      }
    }
  }
}

AND initperms7() BE
{ LET p, t, m = permv, tstv, medv
  LET medpos = ?
  FOR v1 = 1 TO N DO
  { IF v1=4 DO medpos := 1
    FOR v2 = 1 TO N UNLESS v2=v1 DO
    { IF v2=4 DO medpos := 2
      FOR v3 = 1 TO N UNLESS v3=v2|v3=v1 DO
      { IF v3=4 DO medpos := 3
        FOR v4 = 1 TO N UNLESS v4=v3|v4=v2|v4=v1 DO
        { IF v4=4 DO medpos := 4
          FOR v5 = 1 TO N UNLESS v5=v4|v5=v3|v5=v2|v5=v1 DO
          { IF v5=4 DO medpos := 5
            FOR v6 = 1 TO N UNLESS v6=v5|v6=v4|v6=v3|v6=v2|v6=v1 DO
            { IF v6=4 DO medpos := 6
              FOR v7 = 1 TO N UNLESS v7=v6|v7=v5|v7=v4|v7=v3|v7=v2|v7=v1 DO
              { LET bits = 0
                IF v7=4 DO medpos := 7
                IF v1 < v2 DO bits := bits + t12
                IF v1 < v3 DO bits := bits + t13
                IF v2 < v3 DO bits := bits + t23
                IF v1 < v4 DO bits := bits + t14
                IF v2 < v4 DO bits := bits + t24
                IF v3 < v4 DO bits := bits + t34
                IF v1 < v5 DO bits := bits + t15
                IF v2 < v5 DO bits := bits + t25
                IF v3 < v5 DO bits := bits + t35
                IF v4 < v5 DO bits := bits + t45
                IF v1 < v6 DO bits := bits + t16
                IF v2 < v6 DO bits := bits + t26
                IF v3 < v6 DO bits := bits + t36
                IF v4 < v6 DO bits := bits + t46
                IF v5 < v6 DO bits := bits + t56
                IF v1 < v7 DO bits := bits + t17
                IF v2 < v7 DO bits := bits + t27
                IF v3 < v7 DO bits := bits + t37
                IF v4 < v7 DO bits := bits + t47
                IF v5 < v7 DO bits := bits + t57
                IF v6 < v7 DO bits := bits + t67
                t, p, m := t+1, p+1, m+1
                !t := bits
                !p := (((((v1<<4|v2)<<4|v3)<<4|v4)<<4|v5)<<4|v6)<<4|v7
                !m := medpos
              }
            }
          }
        }
      }
    }
  }
}

AND try(node, depth, tests, results, p, q, lim) = VALOF
// The root node is numbered 1 and its depth is zero.
// tests is the bit pattern representing the tests that have been
// made to reach this node.
// results is the bit pattern representing which tests passed.
// !p .. !q are the numbers of those permutations that have passed the tests.
// q+1 is the next available position on the stack.
// If try finds it will return a value no smaller than lim it stops the
// search and returns a value larger than lim.
{ LET permcount = q-p+1 // The number of permutations that have passed
                        // the current tests.
  LET isleaf, medpos = TRUE, -1

  tv!node := 0 // No test or leaf value yet

  // For debugging
  IF tracing & depth<-5 DO
  { TEST N=5
    THEN writef("node %i2: depth=%n tests=%bA results=%bA  permcount=%n*n",
           node, depth, tests, results, permcount)
    ELSE writef("node %i3: depth=%i2 tests=%bL results=%bL  permcount=%n*n",
           node, depth, tests, results, permcount)
    FOR m = 1 TO N FOR a = p TO q DO
    { LET n = !a
      IF medv!n=m TEST N=5
        THEN writef("%i3: %n %x5 %bA*n", n, m, permv!n, tstv!n)
        ELSE writef("%i4: %n %x7 %bL*n", n, m, permv!n, tstv!n)
    }
    //abort(1000)
  }

  // Determine whether this node is a leaf node
  FOR a = p TO q DO
  { LET mp = medv!(!a)
    UNLESS mp=medpos TEST medpos<0 THEN medpos := mp    // First time
                                   ELSE { isleaf := FALSE; BREAK }
  }
    
  IF isleaf DO
  { tv!node := -medpos
    //writef("node %i3: is a leaf at depth %n   median pos = %n  score=%n*n",
    //       node, depth, medpos, depth*permcount)
    RESULTIS depth*permcount
  }

  // Build in the first choice, ie at depth zero
  // Without loss of generality assume the first test is a<b
  // and that it is true.
  IF depth=0 RESULTIS trytest(t12, node, depth, tests, results, p, q, lim)

  // The following is good for the best average, but does not
  // minimise the worst case. Comment out this line if not allowing
  // depth > 6.
  //IF depth=1 RESULTIS trytest(t13, node, depth, tests, results, p, q, lim)

//  IF depth=1 RESULTIS trytest(t34, node, depth, tests, results, p, q, lim)

//  IF node=4  RESULTIS trytest(t24, node, depth, tests, results, p, q, lim)
//  IF node=5  RESULTIS trytest(t23, node, depth, tests, results, p, q, lim)
//  IF node=6  RESULTIS trytest(t14, node, depth, tests, results, p, q, lim)
//  IF node=7  RESULTIS trytest(t13, node, depth, tests, results, p, q, lim)

//  IF depth=3 RESULTIS trytest(t56, node, depth, tests, results, p, q, lim)
  //IF depth=4 RESULTIS trytest(t26, node, depth, tests, results, p, q, lim)

  //IF FALSE SWITCHON node INTO
  IF N=8 SWITCHON node INTO
  { // Use the decision tree to find the median of 5
    // then compare its median with the next variable (=f).
    // These cases are generated by medfind using the -c option.
    DEFAULT:  ENDCASE

    CASE   2: RESULTIS trytest(t13, node, depth, tests, results, p, q, lim)
    CASE   4: RESULTIS trytest(t23, node, depth, tests, results, p, q, lim)
    CASE   8: RESULTIS trytest(t24, node, depth, tests, results, p, q, lim)
    CASE  16: RESULTIS trytest(t25, node, depth, tests, results, p, q, lim)
    CASE  32: RESULTIS trytest(t34, node, depth, tests, results, p, q, lim)
    CASE  64: RESULTIS trytest(t35, node, depth, tests, results, p, q, lim)
    CASE 128: RESULTIS trytest(t36, node, depth, tests, results, p, q, lim)
    CASE 129: RESULTIS trytest(t56, node, depth, tests, results, p, q, lim)
    CASE  65: RESULTIS trytest(t45, node, depth, tests, results, p, q, lim)
    CASE 130: RESULTIS trytest(t46, node, depth, tests, results, p, q, lim)
    CASE 131: RESULTIS trytest(t56, node, depth, tests, results, p, q, lim)
    CASE  33: RESULTIS trytest(t26, node, depth, tests, results, p, q, lim)
    CASE  17: RESULTIS trytest(t25, node, depth, tests, results, p, q, lim)
    CASE  34: RESULTIS trytest(t26, node, depth, tests, results, p, q, lim)
    CASE  35: RESULTIS trytest(t14, node, depth, tests, results, p, q, lim)
    CASE  70: RESULTIS trytest(t45, node, depth, tests, results, p, q, lim)
    CASE 140: RESULTIS trytest(t56, node, depth, tests, results, p, q, lim)
    CASE 141: RESULTIS trytest(t46, node, depth, tests, results, p, q, lim)
    CASE  71: RESULTIS trytest(t15, node, depth, tests, results, p, q, lim)
    CASE 142: RESULTIS trytest(t56, node, depth, tests, results, p, q, lim)
    CASE 143: RESULTIS trytest(t16, node, depth, tests, results, p, q, lim)
    CASE   9: RESULTIS trytest(t34, node, depth, tests, results, p, q, lim)
    CASE  18: RESULTIS trytest(t35, node, depth, tests, results, p, q, lim)
    CASE  36: RESULTIS trytest(t24, node, depth, tests, results, p, q, lim)
    CASE  72: RESULTIS trytest(t25, node, depth, tests, results, p, q, lim)
    CASE 144: RESULTIS trytest(t26, node, depth, tests, results, p, q, lim)
    CASE 145: RESULTIS trytest(t56, node, depth, tests, results, p, q, lim)
    CASE  73: RESULTIS trytest(t45, node, depth, tests, results, p, q, lim)
    CASE 146: RESULTIS trytest(t46, node, depth, tests, results, p, q, lim)
    CASE 147: RESULTIS trytest(t56, node, depth, tests, results, p, q, lim)
    CASE  37: RESULTIS trytest(t36, node, depth, tests, results, p, q, lim)
    CASE  19: RESULTIS trytest(t35, node, depth, tests, results, p, q, lim)
    CASE  38: RESULTIS trytest(t36, node, depth, tests, results, p, q, lim)
    CASE  39: RESULTIS trytest(t14, node, depth, tests, results, p, q, lim)
    CASE  78: RESULTIS trytest(t45, node, depth, tests, results, p, q, lim)
    CASE 156: RESULTIS trytest(t56, node, depth, tests, results, p, q, lim)
    CASE 157: RESULTIS trytest(t46, node, depth, tests, results, p, q, lim)
    CASE  79: RESULTIS trytest(t15, node, depth, tests, results, p, q, lim)
    CASE 158: RESULTIS trytest(t56, node, depth, tests, results, p, q, lim)
    CASE 159: RESULTIS trytest(t16, node, depth, tests, results, p, q, lim)
    CASE   5: RESULTIS trytest(t14, node, depth, tests, results, p, q, lim)
    CASE  10: RESULTIS trytest(t15, node, depth, tests, results, p, q, lim)
    CASE  20: RESULTIS trytest(t24, node, depth, tests, results, p, q, lim)
    CASE  40: RESULTIS trytest(t25, node, depth, tests, results, p, q, lim)
    CASE  80: RESULTIS trytest(t26, node, depth, tests, results, p, q, lim)
    CASE  81: RESULTIS trytest(t56, node, depth, tests, results, p, q, lim)
    CASE  41: RESULTIS trytest(t45, node, depth, tests, results, p, q, lim)
    CASE  82: RESULTIS trytest(t46, node, depth, tests, results, p, q, lim)
    CASE  83: RESULTIS trytest(t56, node, depth, tests, results, p, q, lim)
    CASE  21: RESULTIS trytest(t16, node, depth, tests, results, p, q, lim)
    CASE  11: RESULTIS trytest(t15, node, depth, tests, results, p, q, lim)
    CASE  22: RESULTIS trytest(t16, node, depth, tests, results, p, q, lim)
    CASE  23: RESULTIS trytest(t34, node, depth, tests, results, p, q, lim)
    CASE  46: RESULTIS trytest(t45, node, depth, tests, results, p, q, lim)
    CASE  92: RESULTIS trytest(t56, node, depth, tests, results, p, q, lim)
    CASE  93: RESULTIS trytest(t46, node, depth, tests, results, p, q, lim)
    CASE  47: RESULTIS trytest(t35, node, depth, tests, results, p, q, lim)
    CASE  94: RESULTIS trytest(t56, node, depth, tests, results, p, q, lim)
    CASE  95: RESULTIS trytest(t36, node, depth, tests, results, p, q, lim)
    CASE   3: RESULTIS trytest(t13, node, depth, tests, results, p, q, lim)
    CASE   6: RESULTIS trytest(t14, node, depth, tests, results, p, q, lim)
    CASE  12: RESULTIS trytest(t15, node, depth, tests, results, p, q, lim)
    CASE  24: RESULTIS trytest(t34, node, depth, tests, results, p, q, lim)
    CASE  48: RESULTIS trytest(t35, node, depth, tests, results, p, q, lim)
    CASE  96: RESULTIS trytest(t36, node, depth, tests, results, p, q, lim)
    CASE  97: RESULTIS trytest(t56, node, depth, tests, results, p, q, lim)
    CASE  49: RESULTIS trytest(t45, node, depth, tests, results, p, q, lim)
    CASE  98: RESULTIS trytest(t46, node, depth, tests, results, p, q, lim)
    CASE  99: RESULTIS trytest(t56, node, depth, tests, results, p, q, lim)
    CASE  25: RESULTIS trytest(t16, node, depth, tests, results, p, q, lim)
    CASE  13: RESULTIS trytest(t15, node, depth, tests, results, p, q, lim)
    CASE  26: RESULTIS trytest(t16, node, depth, tests, results, p, q, lim)
    CASE  27: RESULTIS trytest(t24, node, depth, tests, results, p, q, lim)
    CASE  54: RESULTIS trytest(t45, node, depth, tests, results, p, q, lim)
    CASE 108: RESULTIS trytest(t56, node, depth, tests, results, p, q, lim)
    CASE 109: RESULTIS trytest(t46, node, depth, tests, results, p, q, lim)
    CASE  55: RESULTIS trytest(t25, node, depth, tests, results, p, q, lim)
    CASE 110: RESULTIS trytest(t56, node, depth, tests, results, p, q, lim)
    CASE 111: RESULTIS trytest(t26, node, depth, tests, results, p, q, lim)
    CASE   7: RESULTIS trytest(t23, node, depth, tests, results, p, q, lim)
    CASE  14: RESULTIS trytest(t34, node, depth, tests, results, p, q, lim)
    CASE  28: RESULTIS trytest(t35, node, depth, tests, results, p, q, lim)
    CASE  56: RESULTIS trytest(t14, node, depth, tests, results, p, q, lim)
    CASE 112: RESULTIS trytest(t15, node, depth, tests, results, p, q, lim)
    CASE 224: RESULTIS trytest(t16, node, depth, tests, results, p, q, lim)
    CASE 225: RESULTIS trytest(t56, node, depth, tests, results, p, q, lim)
    CASE 113: RESULTIS trytest(t45, node, depth, tests, results, p, q, lim)
    CASE 226: RESULTIS trytest(t46, node, depth, tests, results, p, q, lim)
    CASE 227: RESULTIS trytest(t56, node, depth, tests, results, p, q, lim)
    CASE  57: RESULTIS trytest(t36, node, depth, tests, results, p, q, lim)
    CASE  29: RESULTIS trytest(t35, node, depth, tests, results, p, q, lim)
    CASE  58: RESULTIS trytest(t36, node, depth, tests, results, p, q, lim)
    CASE  59: RESULTIS trytest(t24, node, depth, tests, results, p, q, lim)
    CASE 118: RESULTIS trytest(t45, node, depth, tests, results, p, q, lim)
    CASE 236: RESULTIS trytest(t56, node, depth, tests, results, p, q, lim)
    CASE 237: RESULTIS trytest(t46, node, depth, tests, results, p, q, lim)
    CASE 119: RESULTIS trytest(t25, node, depth, tests, results, p, q, lim)
    CASE 238: RESULTIS trytest(t56, node, depth, tests, results, p, q, lim)
    CASE 239: RESULTIS trytest(t26, node, depth, tests, results, p, q, lim)
    CASE  15: RESULTIS trytest(t24, node, depth, tests, results, p, q, lim)
    CASE  30: RESULTIS trytest(t25, node, depth, tests, results, p, q, lim)
    CASE  60: RESULTIS trytest(t14, node, depth, tests, results, p, q, lim)
    CASE 120: RESULTIS trytest(t15, node, depth, tests, results, p, q, lim)
    CASE 240: RESULTIS trytest(t16, node, depth, tests, results, p, q, lim)
    CASE 241: RESULTIS trytest(t56, node, depth, tests, results, p, q, lim)
    CASE 121: RESULTIS trytest(t45, node, depth, tests, results, p, q, lim)
    CASE 242: RESULTIS trytest(t46, node, depth, tests, results, p, q, lim)
    CASE 243: RESULTIS trytest(t56, node, depth, tests, results, p, q, lim)
    CASE  61: RESULTIS trytest(t26, node, depth, tests, results, p, q, lim)
    CASE  31: RESULTIS trytest(t25, node, depth, tests, results, p, q, lim)
    CASE  62: RESULTIS trytest(t26, node, depth, tests, results, p, q, lim)
    CASE  63: RESULTIS trytest(t34, node, depth, tests, results, p, q, lim)
    CASE 126: RESULTIS trytest(t45, node, depth, tests, results, p, q, lim)
    CASE 252: RESULTIS trytest(t56, node, depth, tests, results, p, q, lim)
    CASE 253: RESULTIS trytest(t46, node, depth, tests, results, p, q, lim)
    CASE 127: RESULTIS trytest(t35, node, depth, tests, results, p, q, lim)
    CASE 254: RESULTIS trytest(t56, node, depth, tests, results, p, q, lim)
    CASE 255: RESULTIS trytest(t36, node, depth, tests, results, p, q, lim)
  }

  // It is not worth searching too deeper
  //IF N=5 & depth=6  RESULTIS 100_000_000  // Gives average 6.000
  IF N=5 & depth=7  RESULTIS 100_000_000  // Gives average 5.966
  //IF N=7 & depth=10 RESULTIS 100_000_000  // Gives average ?.???
  IF N=7 & depth=11 RESULTIS 100_000_000  // Gives average 9.390
  //IF N=7 & depth=12 RESULTIS 100_000_000  // Gives average 9.352
  //IF N=7 & depth=13 RESULTIS 100_000_000  // Gives no improvement


  // Search for best test for this node
  { LET besttest, bestscore = 0, 10_000_000
    //LET poss = all - tests  // Bit pattern of unused tests
    LET poss = ?  // Bit pattern to hold unused useful tests
    LET orbits, andbits = 0, -1

    FOR a = p TO q DO
    { LET bits = tstv!(!a)
      orbits, andbits := orbits | bits, andbits & bits
    }
    // For a test to be useful it must not yield the same result
    // for every available permutation. ie it must fail at least
    // once and succeed at least once.
    poss := orbits & ~andbits

    // Only allow useful comparisons between variables that have already
    // been tested, or one of those and the least variable that has not
    // been tested, or the two least variables that have not been tested.

    //IF tracing & depth<=3 DO
    //{ writef("tests=%bL poss=%bL (useful)*n", tests, poss)
    //  //sys(Sys_quit, 0)
    //}


    TEST (tests & t6bits)~=0
    THEN poss := poss & t1234567bits
    ELSE TEST (tests & t5bits)~=0
         THEN poss := poss & (t67 | t123456bits)
         ELSE TEST (tests & t4bits)~=0
              THEN poss := poss & (t56 | t12345bits)
              ELSE TEST (tests & t3bits)~=0
                   THEN poss := poss & (t45 | t1234bits)
                   ELSE TEST (tests & t2bits)~=0
                        THEN poss := poss & (t34 | t123bits)
                        ELSE poss := poss & t12 

    //IF tracing & depth<=3 DO
    //{ writef("tests=%bL poss=%bL (restricted)*n", tests, poss)
    //  //sys(Sys_quit, 0)
    //}

    UNLESS poss RESULTIS lim+1 // No useful tests to try

    WHILE poss DO
    { LET t = poss & -poss
      LET x = VALOF
      { IF FALSE & tracing & depth<N-2 DO
        { writef("node %i3: ", node)
          writef("poss=%bL  %s*n", poss, test2str(t))
          writef("node %i3: ", node)
          prpath(node/2, results)
          writef("perms=%i4 trying %s*n", permcount, test2str(t))
        }
        RESULTIS 0
      }
      LET score = trytest(t, node, depth, tests, results, p, q, bestscore)
      IF bestscore>score DO besttest, bestscore := t, score
      poss := poss-t
    }

    // Call trytest on the best to set the tv entries correctly
    trytest(besttest, node, depth, tests, results, p, q, bestscore)

    tv!node := besttest
    IF tracing & depth < N-2 DO
    { writef("node %i3: ", node)
      prpath(node/2, results)
      writef("perms=%i4 %s score=%n*n",
              permcount, test2str(tv!node), bestscore)
    }
    RESULTIS bestscore
  }
}

AND prpath(node, results) BE IF node DO
{ LET test = tv!node
  LET b = test & results
  prpath(node/2, results)
  writef("%s:%c ", test2str(tv!node), b->'T','F')
}

AND trytest(test, node, depth, tests, results, p, q, lim) = VALOF
{ LET l, r = q+1, ? // Next free position in the stack
                    // l .. r will hold the numbers of permutations
                    // satisfying the test
  LET scpass, scfail = ?, ?

  tv!node := test
  trycount := trycount+1

  // Select the permutations that pass the test
  r := q
  FOR a = p TO q IF (tstv!(!a) & test) ~= 0 DO { r := r+1; !r := !a }

  IF r<l | r-l=q-p RESULTIS lim+1 // The test was no good

  scpass := try(2*node,   depth+1, tests+test, results+test, l, r, lim)

  // If the score is bad enough give up.
  IF scpass>=lim RESULTIS lim+1 // A value larger than lim

  // At node=1 the test is a<b and the two subtrees are similar.
  // Only explore both subtrees if the -c option is specified.
  IF node=1 & ~cases RESULTIS 2*scpass

  // Select the permutations that fail the test
  r := q
  FOR a = p TO q IF (tstv!(!a) & test)  = 0 DO { r := r+1; !r := !a }
  scfail := try(2*node+1, depth+1, tests+test, results,      l, r, lim-scpass)

  RESULTIS scpass + scfail
}

AND prtree(node, depth, tests, results) BE
{ // The indentation line has already been written.
  LET chv = TABLE 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
  LET t = tv!node

  UNLESS t DO { writef("(symmetric)*n"); RETURN } // This subtree is not present

  TEST t<0
  THEN { writef("=>  %c", 'a'-1-t)
         FOR p = 1 TO permupb IF (tstv!p & tests)=results DO
         { writef(" ")
           writehex(permv!p, N)
         }
         newline()
       }
  ELSE { writef("%s ", test2str(t))
         chv!depth := '|'
         prtree(2*node,   depth+1, tests+t, results+t)
         FOR i = 0 TO depth-1 DO writef("%c   ", chv!i)
         writef("**-- ")
         chv!depth := ' '
         prtree(2*node+1, depth+1, tests+t, results)
       }
}

AND prcases(node) BE
{ LET t = tv!node

  UNLESS t RETURN // This subtree is not present

  IF t<0 DO
  { // Deal with a leaf node
    writef("    CASE %i3:*
           * RESULTIS trytest(t%n%n, node, depth, tests, results, p, q, lim)*n",
           node, -t, N+1) // Compare the current median with the next variable
    RETURN
  }
  // Deal with a compare node
  writef("    CASE %i3:*
         * RESULTIS trytest(%s, node, depth, tests, results, p, q, lim)*n",
         node, test2name(t))
  prcases(2*node)
  prcases(2*node+1)
}

AND test2name(t) = VALOF SWITCHON t INTO
{ DEFAULT:  RESULTIS "??"

  CASE   0: RESULTIS "  0"  // No test or leaf value

  CASE t12: RESULTIS "t12"

  CASE t13: RESULTIS "t13"
  CASE t23: RESULTIS "t23"

  CASE t14: RESULTIS "t14"
  CASE t24: RESULTIS "t24"
  CASE t34: RESULTIS "t34"

  CASE t15: RESULTIS "t15"
  CASE t25: RESULTIS "t25"
  CASE t35: RESULTIS "t35"
  CASE t45: RESULTIS "t45"

  CASE t16: RESULTIS "t16"
  CASE t26: RESULTIS "t26"
  CASE t36: RESULTIS "t36"
  CASE t46: RESULTIS "t46"
  CASE t56: RESULTIS "t56"

  CASE t17: RESULTIS "t17"
  CASE t27: RESULTIS "t27"
  CASE t37: RESULTIS "t37"
  CASE t47: RESULTIS "t47"
  CASE t57: RESULTIS "t57"
  CASE t67: RESULTIS "t67"
}

AND test2str(t) = VALOF SWITCHON t INTO
{ DEFAULT:  TEST N=5
            THEN writef("*ntest2str: bad t=%bA*n", t)
            ELSE writef("*ntest2str: bad t=%bL*n", t)
            abort(999)
            RESULTIS "??"

  CASE   0: RESULTIS "   "  // No test or leaf value

  CASE t12: RESULTIS "a<b"

  CASE t13: RESULTIS "a<c"
  CASE t23: RESULTIS "b<c"

  CASE t14: RESULTIS "a<d"
  CASE t24: RESULTIS "b<d"
  CASE t34: RESULTIS "c<d"

  CASE t15: RESULTIS "a<e"
  CASE t25: RESULTIS "b<e"
  CASE t35: RESULTIS "c<e"
  CASE t45: RESULTIS "d<e"

  CASE t16: RESULTIS "a<f"
  CASE t26: RESULTIS "b<f"
  CASE t36: RESULTIS "c<f"
  CASE t46: RESULTIS "d<f"
  CASE t56: RESULTIS "e<f"

  CASE t17: RESULTIS "a<g"
  CASE t27: RESULTIS "b<g"
  CASE t37: RESULTIS "c<g"
  CASE t47: RESULTIS "d<g"
  CASE t57: RESULTIS "e<g"
  CASE t67: RESULTIS "f<g"
}

/*
0> medfind -n 7 -o tree7.txt -t
creates tree7.tx as follows:

Test nodes tried = 175164

Average number of tests to find the median of 5 is 5.866 (5+13/15, Knuth Vol 3 p218)

a<b a<c b<c b<d b<e c<d c<e =>  c 12345 12354
|   |   |   |   |   |   *-- =>  e 12453
|   |   |   |   |   *-- d<e =>  d 12435 12534
|   |   |   |   |       *-- =>  e 12543
|   |   |   |   *-- =>  b 13452 13542 23451 23541
|   |   |   *-- b<e =>  b 13425 13524 23415 23514
|   |   |       *-- a<d d<e =>  e 14523
|   |   |           |   *-- =>  d 14532 24531
|   |   |           *-- a<e =>  e 24513
|   |   |               *-- =>  a 34512 34521
|   |   *-- c<d c<e b<d b<e =>  b 13245 13254
|   |       |   |   |   *-- =>  e 14253
|   |       |   |   *-- d<e =>  d 14235 15234
|   |       |   |       *-- =>  e 15243
|   |       |   *-- =>  c 14352 15342 24351 25341
|   |       *-- c<e =>  c 14325 15324 24315 25314
|   |           *-- a<d d<e =>  e 15423
|   |               |   *-- =>  d 15432 25431
|   |               *-- a<e =>  e 25413
|   |                   *-- =>  a 35412 35421
|   *-- a<d a<e b<d b<e =>  b 23145 23154
|       |   |   |   *-- =>  e 24153
|       |   |   *-- d<e =>  d 24135 25134
|       |   |       *-- =>  e 25143
|       |   *-- =>  a 34152 34251 35142 35241
|       *-- a<e =>  a 34125 34215 35124 35214
|           *-- c<d d<e =>  e 45123
|               |   *-- =>  d 45132 45231
|               *-- c<e =>  e 45213
|                   *-- =>  c 45312 45321
*-- (symmetric)

0> medfind -n 7 -o tree7.txt -t  (with depth limit of 11)
creates tree7.tx as follows:

Test nodes tried = 953180444     (it ran for 4 days using natbcpl)

Average number of tests to find the median of 7 is 9.320 (not 9+32/105, Knuth Vol 3 p218)

a<b c<d a<c c<e c<f d<e d<g b<f b<d d<f =>  d 1234567 1234576 1234657 1234675 
1234756 1234765 1324567 1324576 1324657 1324675 1324756 1324765
|   |   |   |   |   |   |   |   |   *-- =>  f 1235647 1235746 1325647 1325746
|   |   |   |   |   |   |   |   *-- b<e b<g =>  b 1423567 1423576 1423657 
1423675 1423756 1423765
|   |   |   |   |   |   |   |       |   *-- =>  g 1523674 1523764
|   |   |   |   |   |   |   |       *-- e<g =>  e 1523467 1523476 1623475
|   |   |   |   |   |   |   |           *-- =>  g 1623574
|   |   |   |   |   |   |   *-- d<f e<f e<g =>  e 1623457 1723456 1723465
|   |   |   |   |   |   |       |   |   *-- =>  g 1723564
|   |   |   |   |   |   |       |   *-- f<g =>  f 1523647 1523746 1623547 
1623745 1723546 1723645
|   |   |   |   |   |   |       |       *-- =>  g 1623754 1723654
|   |   |   |   |   |   |       *-- b<d =>  b 1425637 1425736
|   |   |   |   |   |   |           *-- =>  d 1524637 1524736 1624537 
1624735 1724536 1724635
|   |   |   |   |   |   *-- b<d b<g f<g b<f =>  f 1236745 1326745
|   |   |   |   |   |       |   |   |   *-- =>  b 1426735
|   |   |   |   |   |       |   |   *-- c<g =>  g 1235674 1235764 1236754 
1325674 1325764 1326754
|   |   |   |   |   |       |   |       *-- =>  c 1245673 1245763 1246753
|   |   |   |   |   |       |   *-- b<f b<c =>  c 1345672 1345762 1346752 
2345671 2345761 2346751
|   |   |   |   |   |       |       |   *-- =>  b 1425673 1425763 1426753 
1435672 1435762 1436752 2435671 2435761 2436751
|   |   |   |   |   |       |       *-- f<g =>  g 1526734
|   |   |   |   |   |       |           *-- =>  f 1526743 1536742 2536741
|   |   |   |   |   |       *-- d<f =>  d 1524673 1524763 1534672 1534762 
1624573 1624753 1634572 1634752 1724563 1724653 1734562 1734652 2534671 
2534761 2634571 2634751 2734561 2734651
|   |   |   |   |   |           *-- f<g =>  g 1625734 1725634
|   |   |   |   |   |               *-- =>  f 1625743 1635742 1725643 1735642 
2635741 2735641
|   |   |   |   |   *-- e<g b<f b<e e<f =>  e 1235467 1235476 1236457 1236475 
1237456 1237465 1325467 1325476 1326457 1326475 1327456 1327465
|   |   |   |   |       |   |   |   *-- =>  f 1236547 1237546 1326547 1327546
|   |   |   |   |       |   |   *-- b<d b<g =>  b 1425367 1425376 1426357 1426375 
1427356 1427365
|   |   |   |   |       |   |       |   *-- =>  g 1526374 1527364
|   |   |   |   |       |   |       *-- d<g =>  d 1524367 1524376 1624375
|   |   |   |   |       |   |           *-- =>  g 1625374
|   |   |   |   |       |   *-- e<f d<f d<g =>  d 1624357 1724356 1724365
|   |   |   |   |       |       |   |   *-- =>  g 1725364
|   |   |   |   |       |       |   *-- f<g =>  f 1526347 1527346 1625347 1627345 
1725346 1726345
|   |   |   |   |       |       |       *-- =>  g 1627354 1726354
|   |   |   |   |       |       *-- b<e =>  b 1426537 1427536
|   |   |   |   |       |           *-- =>  e 1526437 1527436 1625437 1627435 
1725436 1726435
|   |   |   |   |       *-- b<e b<g f<g b<f =>  f 1237645 1327645
|   |   |   |   |           |   |   |   *-- =>  b 1427635
|   |   |   |   |           |   |   *-- c<g =>  g 1236574 1237564 1237654 1326574 
1327564 1327654
|   |   |   |   |           |   |       *-- =>  c 1246573 1247563 1247653
|   |   |   |   |           |   *-- b<f b<c =>  c 1346572 1347562 1347652 2346571 
2347561 2347651
|   |   |   |   |           |       |   *-- =>  b 1426573 1427563 1427653 1436572 
1437562 1437652 2436571 2437561 2437651
|   |   |   |   |           |       *-- f<g =>  g 1527634
|   |   |   |   |           |           *-- =>  f 1527643 1537642 2537641
|   |   |   |   |           *-- e<f =>  e 1526473 1527463 1536472 1537462 1625473 
1627453 1635472 1637452 1725463 1726453 1735462 1736452 2536471 2537461 2635471 
2637451 2735461 2736451
|   |   |   |   |               *-- f<g =>  g 1627534 1726534
|   |   |   |   |                   *-- =>  f 1627543 1637542 1726543 1736542 
2637541 2736541
|   |   |   |   *-- c<g b<d b<c =>  c 1245637 1245736 1246537 1246735 1247536 
1247635 1345627 1345726 1346527 1346725 1347526 1347625 2345617 2345716 2346517 
2346715 2347516 2347615
|   |   |   |       |   |   *-- b<e b<g =>  b 1435627 1435726 1436527 1436725 
1437526 1437625 2435617 2435716 2436517 2436715 2437516 2437615
|   |   |   |       |   |       |   *-- =>  g 1536724 1537624 2536714 2537614
|   |   |   |       |   |       *-- e<g =>  e 1536427 1537426 1637425 2536417 
2537416 2637415
|   |   |   |       |   |           *-- =>  g 1637524 2637514
|   |   |   |       |   *-- d<e d<g =>  d 1534627 1534726 1634527 1634725 1734526 
1734625 2534617 2534716 2634517 2634715 2734516 2734615

etc ...


*/

