/*
This module contains debugging aids to test various  functions
in the a tautology checker.

Implemented in BCPL by Martin Richards (c) October 2005
*/

SECTION "debug"

GET "libhdr"
GET "chk3.h"

LET selfcheck(checkno) BE SWITCHON checkno INTO
{ DEFAULT: writef("Unknown self check number: %n*n", checkno)
           RETURN
  CASE  1:  check1(); RETURN
  CASE  2:  check2(); RETURN
  CASE  3:  check3(); RETURN
  CASE  4:  check4(); RETURN
  CASE  5:  check5(); RETURN
  CASE  6:  check6(); RETURN
  CASE  7:  check7(); RETURN
//  CASE  8:  check8(); RETURN
//  CASE  9:  check9(); RETURN
//  CASE 10:  check10(); RETURN
}

AND check1() BE
{ bm_setbitpp(1,  2);   bm_findnewinfo()
  bm_setbitpp(2,  3);   bm_findnewinfo()
  bm_setbitpp(4,  5);   bm_findnewinfo()
  bm_setbitpp(5,  6);   bm_findnewinfo()
  bm_setvar1(1);        bm_findnewinfo()
  bm_setbitpp(3,  4);   bm_findnewinfo()
  bm_setbitpn(6,  2);   bm_findnewinfo()
  bm_setbitnp(33, 34);  bm_findnewinfo()
  bm_setbitnp(33, 35);  bm_findnewinfo()
  bm_setbitpn(35, 33);  bm_findnewinfo()
}

AND check2() BE
{ // test the exchargs function
  FOR i = 1 TO 100 DO
  { LET rel = relv!1
    LET v, w = @rel!r_v0, @rel!r_w0
    LET ws = VEC 7
    // Set up a relation
    FOR i = 0 TO 2 DO v!i := i+10
    rel!r_w0 := (randno(1000000) XOR randno(1000000)<<16)>>10 & #xFF

    FOR a = 0 TO 2 FOR b = 0 TO 2 DO
    { LET ok = TRUE
//wrrel(rel); newline()
//writef("*nexch  %n and %n*n", 2, a)
      exchargs(rel, 2, a)
//wrrel(rel); newline()
//writef("*nexch  %n and %n*n", a, b)
      exchargs(rel, a, b)
//wrrel(rel); newline()
//writef("*nexch  %n and %n*n", 2, b)
      exchargs(rel, 2, b)
//wrrel(rel); newline()
//writef("*nexch  %n and %n*n", a, b)
      exchargs(rel, a, b)
//wrrel(rel); newline()
      FOR i = 0 TO 2 UNLESS v!i=10+i & w!i=ws!i DO ok := FALSE
      UNLESS rel!r_w0 = ws!0 DO ok := FALSE
      UNLESS ok DO writef("error: a=%n b=%n*n", a, b)
    }      
  }
}

AND check3() BE
{ FOR i = 1 TO 10 DO
  { LET r1, r2 = relv!1, relv!2
    FOR j = 0 TO r_upb DO r2!j := r1!j
    bm_clrmat(mata, matb, matc, matd)
    bm_clrmat(mataprev, matbprev, matcprev, matdprev)
    IF i=1 DO {
      wrrel(r2); newline()
      apeq(r2, 2, 1)
      wrrel(r2); newline()
    }
    findimps(r2); bm_findnewinfo()
  }
}

AND check4() BE
{ // Test standardise
  FOR a = 0 TO 2 DO
  FOR b = 1 TO 2 DO
  FOR c = 2 TO 2 DO
  { LET r = relv!1
    LET x = #x5C
    FOR i = 0 TO 7 DO r!(r_w0+i) := 0
    r!r_w0 := x

    exchargs(r, 0, a)
    exchargs(r, 1, b)
    exchargs(r, 2, c)
    FOR i = 0 TO 2 DO r!(r_v0+i) := 20+i
    //wrrel(r); newline()
    //standardise(r)
    //wrrel(r); newline()
    //wrrel(r); newline()
  }
}

AND check5() BE
{ LET rel = relv!1
  LET v, w = @rel!r_v0, @rel!r_w0
  LET relbits = (randno(1000000) XOR randno(1000000)<<16)>>10 & #xFF

  // test apimppp, apimppn, apimpnp and apimpnn
  FOR i = 0 TO 2 FOR j = 0 TO 2 DO
  { // Set up a relation
    FOR i = 0 TO 2 DO v!i := 10+i
    rel!r_w0 := relbits

    bm_clrmat(mata, matb, matc, matd)
    bm_clrmat(mataprev, matbprev, matcprev, matdprev)
    apimppp(rel, i, j)
    writef("testing v%n -> v%n*n", i, j)
    wrrel(rel, FALSE)
    findimps(rel)//; bm_findnewinfo()
    newline()

    FOR i = 0 TO 2 DO v!i := 10+i
    rel!r_w0 := relbits

    bm_clrmat(mata, matb, matc, matd)
    bm_clrmat(mataprev, matbprev, matcprev, matdprev)
    apimppn(rel, i, j)
    writef("testing v%n ->~v%n*n", i, j)
    wrrel(rel, FALSE)
    findimps(rel)//; bm_findnewinfo()
    newline()

    FOR i = 0 TO 2 DO v!i := 10+i
    rel!r_w0 := relbits

    bm_clrmat(mata, matb, matc, matd)
    bm_clrmat(mataprev, matbprev, matcprev, matdprev)
    apimpnp(rel, i, j)
    writef("testing ~v%n -> v%n*n", i, j)
    wrrel(rel, FALSE)
    findimps(rel)//; bm_findnewinfo()
    newline()


    bm_clrmat(mata, matb, matc, matd)
    bm_clrmat(mataprev, matbprev, matcprev, matdprev)
    apimpnn(rel, i, j)
    writef("testing ~v%n -> ~v%n*n", i, j)
    wrrel(rel, FALSE)
    findimps(rel)//; bm_findnewinfo()
    newline()
    abort(1000)
  }
}

AND check6() BE
{ LET rel = relv!1
  LET v = @rel!r_v0
  LET relbits = (randno(1000000) XOR randno(1000000)<<16)>>10 &#xFF

  // test exchargs with apimppp, apimppn, apimpnp and apimpnn
  FOR i = 0 TO 2 FOR j = 0 TO 2 DO
  { // Set up a relation
    FOR i = 0 TO 2 DO v!i := 10+i
    rel!r_w0 := relbits

    bm_clrmat(mata, matb, matc, matd)
    bm_clrmat(mataprev, matbprev, matcprev, matdprev)
    apimppp(rel, i, j)
    exchargs(rel, i, j)
    writef("testing v%n -> v%n*n", i, j)
    wrrel(rel, FALSE)
    findimps(rel)//; bm_findnewinfo()
    newline()

    FOR i = 0 TO 2 DO v!i := 10+i
    rel!r_w0 := relbits

    bm_clrmat(mata, matb, matc, matd)
    bm_clrmat(mataprev, matbprev, matcprev, matdprev)
    apimppn(rel, i, j)
    exchargs(rel, i, j)
    writef("testing v%n ->~v%n*n", i, j)
    wrrel(rel, FALSE)
    findimps(rel)//; bm_findnewinfo()
    newline()

    FOR i = 0 TO 2 DO v!i := 10+i
    rel!r_w0 := relbits

    bm_clrmat(mata, matb, matc, matd)
    bm_clrmat(mataprev, matbprev, matcprev, matdprev)
    apimpnp(rel, i, j)
    exchargs(rel, i, j)
    writef("testing ~v%n -> v%n*n", i, j)
    wrrel(rel, FALSE)
    findimps(rel)//; bm_findnewinfo()
    newline()

    FOR i = 0 TO 2 DO v!i := 10+i
    rel!r_w0 := relbits

    bm_clrmat(mata, matb, matc, matd)
    bm_clrmat(mataprev, matbprev, matcprev, matdprev)
    apimpnn(rel, i, j)
    exchargs(rel, i, j)
    writef("testing ~v%n -> ~v%n*n", i, j)
    wrrel(rel, FALSE)
    findimps(rel)//; bm_findnewinfo()
    newline()
    abort(1000)
  }
}

AND check7() BE
{ LET rel1 = VEC r_upb
  LET rel2 = VEC r_upb
  FOR i = 0 TO r_upb DO rel1!i := 0
  FOR i = 0 TO 7 DO
    //rel1!(r_v0+i) := i+1             // 1..8
    rel1!(r_v0+i) := randno(9) - 1 // 0..8 random
  rel1!r_w0 := (randno(1000000) XOR randno(1000000)<<16)>>10 & #xFF

  wrrel(rel1, FALSE)
  FOR a = 0 TO 2 FOR b = 0 TO 2 DO
  { FOR i = 0 TO r_upb DO rel2!i := rel1!i
    //writef("Testing exchargs %n %n*n", a, b)
    exchargs(rel2, a, b)
    //writef("Testing standardise*n", a, b)
    //wrrel(rel2, FALSE)
    //writef("Cost of standardise %n*n", instrcount(standardise, rel2))
    standardise(rel2)
    //writef("Cost of standardise %n*n", instrcount(standardise, rel2))
    //wrrel(rel2, FALSE)
    //rel2!r_w0 := rel2!r_w0  XOR #X00040000
 
    checkeqv(rel1, rel2)
    //abort(2222)
  }   
}

AND evalrel(r, a, b, c) = VALOF
{ // Evaluate relation r assuming v1, v2 and v3 have values a, b and c.
  LET v = @rel!r_v0
  LET env = @r
  LET s = v!2!env*4 + v!1!env*2 + v!0!env
  RESULTIS rel!r_w0>>s & 1
}

AND checkeqv(rel1, rel2) BE
{ LET env = VEC 3
  env!0 := 0
  FOR a = 0 TO 1 DO
  { env!1 := a
    FOR b = 0 TO 1 DO
    { env!2 := b
      FOR c = 0 TO 1 DO
      { env!3 := b
        UNLESS evalrel(rel1, env)=evalrel(rel2, env) DO
        { writef("abc=%n%n%n rel1=>%n rel2=>%n*n",
                  a,b,c,
                  evalrel(rel1, env), evalrel(rel2, env))
          wrrel(rel1, FALSE)
          wrrel(rel2, FALSE)
          newline()
          abort(999)
        }
      }
    }
  }  
}

AND testallvars(f) BE
// Call f(a, b, c) all a, b, c in range 0 to 3
  FOR a = 0 TO 3 FOR b = 0 TO 3 FOR c = 0 TO 3 DO f(a, b, c)

AND selftest() BE
{ // Call all the selftest functions
  writef("Self Testing*n")
  testallvars(teststandardise)
}

AND inittest() BE
// Reset the global environment
{ // Remove all previous relations
  FOR i = 0 TO relvupb DO relv!i := 0
  relspacep := 0
  reln := 0              // No relations yet

  // Release all the pair blocks, if any.
  WHILE pairblks DO
  { LET next = !pairblks
    //writef("Freeing pair block %n*n", pairblks)
    freevec(pairblks)
    pairblks := next
  }
  freepairs := 0

  IF mata     DO { freevec(mata);     mata := 0 }
  IF matb     DO { freevec(matb);     matb := 0 }
  IF matc     DO { freevec(matc);     matc := 0 }
  IF matd     DO { freevec(matd);     matd := 0 }
  IF mataprev DO { freevec(mataprev); mataprev := 0 }
  IF matbprev DO { freevec(matbprev); matbprev := 0 }
  IF matcprev DO { freevec(matcprev); matcprev := 0 }
  IF matdprev DO { freevec(matdprev); matdprev := 0 }

  //IF relspace DO { freevec(relspace); relspace := 0 }
  //IF relv     DO { freevec(relv);     relv     := 0 }
  //IF relstack DO { freevec(relstack); relstack := 0 }

  IF refs     DO { freevec(refs);     refs     := 0 }
  IF refcount DO { freevec(refcount); refcount := 0 }
  IF id2orig  DO { freevec(id2orig);  id2orig  := 0 }
  IF varinfo  DO { freevec(varinfo);  varinfo  := 0 }


}

