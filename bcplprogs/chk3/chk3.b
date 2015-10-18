/*

This is an experimental tautology checker based on the analysis of the
conjunction of a set of relations. It is loosely related to Stalmark's
Algorithm.

Implemented in BCPL by Martin Richards (c) November 2005


In this implementation the relations are over 3 boolean variables.
The variable numbered 0 is permanently set to 0 (=false) and all other
variables have numbers greater than 0 and can take either value.

A term is represented by a 4-tuple [hgfedcba, x, y, z], where x, y and z
are non negative variable numbers and hgfedcba is an 8-bit pattern
representing the relation. These bits are defined as follows:


x    1 0 1 0 1 0 1 0
y    1 1 0 0 1 1 0 0
z    1 1 1 1 0 0 0 0
     h g f e d c b a
                   a=1  <=>  xyz = 000 is allowed
                 b=1  <=>    xyz = 100 is allowed
               c=1  <=>      xyz = 010 is allowed
             d=1  <=>        xyz = 110 is allowed
           e=1  <=>          xyz = 001 is allowed
         f=1  <=>            xyz = 101 is allowed
       g=1  <=>              xyz = 011 is allowed
     h=1  <=>                xyz = 111 is allowed

So, for example, the relation:  x = (y -> z) could be represented by:

        [#b10100110, x, y, z]
         x 1 1  01
         y 1 0  10
         z 1 1  00

implying that xyz can only be one of 111, 101, 010 or 100.

which corresponds to:        x     y    z
                             1 = ( 1 -> 1 )
                             1 = ( 0 -> 1 )
                             0 = ( 1 -> 0 )
                             1 = ( 0 -> 0 )

The ordering of the bits and the variables is chosen for compatibility
with implementations of this algorithm using relations over 5 (chk5)
and 8 (chk8) variables.

Any boolean expression can be converted into the conjunction of such
relations which in this implementation consists of a vector of pointers to
4-tuples.

Term Canonicalisation

A term specifies what pattern of values its variables may take. Of the
different terms that specify the same constraints, it is always
possible to find a unique 'canonical' version. This is done by
removing repeated variables and redundant variables from the relation
and then arranging the remaining variables in increasing variable
number order, adjusting the relation bit pattern appropriately. For
example, consider the following relation:

11010101  v3 v3 v7
|| | | |
|| | | *- 0  0  0
|| | *--- 0  1  0 <- Disallowed because the first two arguments are the same
|| *----- 0  0  1
|*------- 0  1  1 <- Disallowed because the first two arguments are the same
*-------- 1  1  1

The relation bit pattern can thus be simplified by anding with
10011001, giving:

10010001  v3 v3 v7
|  |   |
|  |   *- 0  0  0
|  *----- 0  0  1
*-------- 1  1  1

The second argument now performs no useful purpose and so can be replaced by 0
with a suitable change to the relation bit pattern.

00110001  v3 0 v7
  ||   |
  ||   *- 0  0  0
  |*----- 0  0  1
  *------ 1  0  1

Arguments two and three may now be swapped, with a suitable
change to the relation bit pattern.

00001101  v3 v7 0
    || |
    || *- 0  0  0
    |*--- 0  1  0
    *---- 1  1  0

Notice that this relation and the original one both equivalent to; v3->v7.

Note the canonical form of true is: [0000001, 0, 0, 0], and of false is:
[00000000, 0, 0, 0].
*/

SECTION "chk3"

GET "libhdr"
GET "chk3.h"

LET start() = VALOF
{ //LET name = "data/tst2.rel"
  LET name = "data/e1.rel"
  //LET name = "data/greaves.rel"
  //LET name = "data/mul4.rel"
  LET argv = VEC 50

  relspace := 0
  relv := 0
  refs := 0
  refcount := 0
  id2orig := 0
  varinfo := 0
  relstack := 0
  pairblks := 0
  freepairs := 0

  // Mata will hold nxn Boolean matrix, where n is the highest
  // numbered variable identifier currently in use. Aij=1 if Vi->Vj
  // Matb, matc and matd are similar matrices for the relations:
  // Vi->~Vj, ~Vi->Vj and ~Vi->~Vj, respectively.
  // mataprev,..., matdprev hold copies of the previous versions of
  // mata,...,matd, so that recent changes can be detected.
  mata, mataprev := 0, 0
  matb, matbprev := 0, 0
  matc, matcprev := 0, 0
  matd, matdprev := 0, 0

  UNLESS rdargs("-f,-d,-t/S,-s/S", argv, 50) DO
  { writef("Bad arguments for chk3*n")
    RESULTIS 20
  }

  IF argv!0 DO name := argv!0                // -f <file>

  debug := 0
  IF argv!1 & string.to.number(argv!1) DO    // -d <num>
    debug := result2

  tracing := argv!2                          // -t

  selftesting := argv!3                      // -s

  writef("chk3 processing file %s*n", name)

  relspaceupb := 50000
  relspace    := getvec(relspaceupb)
  relspacep   := 0
  relvupb     := 10000
  relv        := getvec(relvupb)
  relstackupb := 10000
  relstack    := getvec(relstackupb)
  relstackp   := 0

  UNLESS relspace & relv & relstack DO
  { writef("More memory needed*n")
    GOTO fin
  }

  IF selftesting DO // Ie -s given
  { // Test all the auxiliary functions
    selftest()
    GOTO fin
  }

  UNLESS rdrels(name) DO
  { writef("Format of file %s wrong*n", name)
    GOTO fin
  }

  writef("Number of relations read = %n*n", reln)

  formlists(relv, reln)

  newline()
  wrrels(TRUE)
  wrvars()
  newline()

  IF debug DO
  { selfcheck(debug) // Defined in debug.b
    GOTO fin
  }

  IF FALSE DO
  { LET rel = relv!1
    FOR i = 0 TO 2 DO rel!(r_a0+i) := i+1
    rel!r_w0 := #b_1101_0110
    wrrel(rel, FALSE)
    findimps(rel)
    bm_findnewinfo()

    writef("End of test*n")
    GOTO fin
  }

  //bm_prmat(mata,matb,matc,matd)

  //writef("*nApplying Warshall*n")
  //bm_warshall(mata, matb, matc, matd)
  //bm_prmat(mata,matb,matc,matd)

  // Start of algorithm

  FOR i = 1 TO reln DO standardise(relv!i)

  writef("*n*nThe resulting relations are*n*n")

  wrrels(TRUE)
  wrvars()

abort(1000)

writef("calling explore %n*n", explore)
  explore(relv, reln, maxid, mata, matb, matc, matd)

  writef("*n*nThe resulting relations are*n*n")

  wrrels(TRUE)
  wrvars()

fin:
  WHILE pairblks DO
  { LET next = !pairblks
    //writef("Freeing pair block %n*n", pairblks)
    freevec(pairblks)
    pairblks := next
  }

  // Free the space allocated by formlists
  IF refs     DO freevec(refs)
  IF refcount DO freevec(refcount)
  IF id2orig  DO freevec(id2orig)
  IF varinfo  DO freevec(varinfo)
  IF mata     DO freevec(mata)
  IF matb     DO freevec(matb)
  IF matc     DO freevec(matc)
  IF matd     DO freevec(matd)
  IF mataprev DO freevec(mataprev)
  IF matbprev DO freevec(matbprev)
  IF matcprev DO freevec(matcprev)
  IF matdprev DO freevec(matdprev)


  // Free the permanent
  IF relspace DO freevec(relspace)
  IF relv     DO freevec(relv)
  IF relstack DO freevec(relstack)

  RESULTIS 0
}

.

// Transformations on a single relation

// exchargs(rel, i, j)  exchange the positions of arguments i and j
// ignorearg(rel, i)    remove arg i, assuming it is unconstrained
// dontcare(rel, i)     return TRUE iff the relation does not depend
//                                      on arg i.
// standardise(rel)     remove irrelevant and duplicate arguments and
//                      sort those that are remain.


SECTION "trans1"

GET "libhdr"
GET "chk3.h"

// Exchange arguments i and j and make the corresponding change to
// the relation bit pattern.
LET exchargs(rel, i, j) BE
// Assume i and j are in the range 0..2
{ LET w0 = rel!r_w0
  LET a  = @rel!r_a0
  LET t  = a!i
  a!i := a!j    // Swap the variable identifiers
  a!j := t

  // Adjust the bit pattern
  SWITCHON i*8 + j INTO
  { DEFAULT:  ENDCASE  // Either i=j or an error

    CASE #21:
    CASE #12: rel!r_w0 := w0&#xC3 | w0<<2 & #x30 | w0>>2 & #x0C
              ENDCASE
    CASE #20:
    CASE #02: rel!r_w0 := w0&#xA5 | w0<<3 & #x50 | w0>>3 & #x0A
              ENDCASE
    CASE #10:
    CASE #01: rel!r_w0 := w0&#x99 | w0<<1 & #x44 | w0>>1 & #x22
              ENDCASE
  }
}

AND testexchargs() BE
{ LET rel = 0
  writef("Testing exchargs*n")
  inittest()
  rel := mkrel(1, 0, 0, 0, 0)

  FOR relbits = 0 TO #b11111111 DO
    FOR i = 0 TO 2 FOR j = 0 TO 2 DO
    { LET va, vb, vc = 1, 2, 3

      IF i=0 & j=1 DO va, vb, vc := 2, 1, 3
      IF i=1 & j=0 DO va, vb, vc := 2, 1, 3
      IF i=0 & j=2 DO va, vb, vc := 3, 2, 1
      IF i=2 & j=0 DO va, vb, vc := 3, 2, 1
      IF i=1 & j=2 DO va, vb, vc := 1, 3, 2
      IF i=2 & j=1 DO va, vb, vc := 1, 3, 2

      FOR a = 0 TO 1 FOR b = 0 TO 1 FOR c = 0 TO 1 DO
      { LET res1, res2 = ?, ?
        rel!r_w0, rel!r_a0, rel!r_a1, rel!r_a2 := relbits, 1, 2, 3
        res1 := evalrel(rel, 0, a, b, c)
        exchargs(rel, i, j)
        res2 := evalrel(rel, 0, a, b, c)
        // Check that the standardises relation is equivalent
        // to the original.
        IF res1=res2 & rel!r_a0=va & rel!r_a1=vb & rel!r_a2=vc LOOP

        writef("ERROR: exchargs(rel, %n, %n)*
               * environment v1=%n v2=%n v3=%n*n", i, j, a, b, c)
        writef("%b8 v%n v%n v%n => %n*n", relbits, 1, 2, 3, res1)
        writef("%b8 v%n v%n v%n => %n*n",
                rel!r_w0, rel!r_a0, rel!r_a1, rel!r_a2, res2)
        abort(999)
      }
    }
}

AND ignorearg(rel, i) BE
{ // Remove arg i, assuming it is unconstrained.
  // Update rel bits corresponding to argument i being freely able
  // to be set to either 0 or 1. This is useful if, for instance,
  // that argument is not used in any other relation.

  // eg, if i=2: R11010110(x,y,z) => R00001110(x,y,0)
  //                                 ie xy = 11, 01 or 10

  // or  R00001110(x,y,0) = R11010110(x,y,0) | R11010110(x,y,1)
  // and R00001110(x,y,1) = 0

  // Only the rel bits are changed, the arguments are not touched.

  // x 10101010
  // y 11001100
  // z 11110000

  //   11000110 means xyz = 111, 011, 010 or 100
  //   01101101 means xyz = 11*, 01*, 01* or 10*
  //   00001110 means xyz = 110, 010, 010 or 100
  //               ie xy = 11, 01 or 10

  LET w0 = rel!r_w0

  SWITCHON i INTO
  { DEFAULT: bug("ignorearg: Bad i=%n*n", i); RETURN
    CASE 2:  rel!r_w0 := (w0 | w0>>4) & #x0F; ENDCASE
    CASE 1:  rel!r_w0 := (w0 | w0>>2) & #x33; ENDCASE
    CASE 0:  rel!r_w0 := (w0 | w0>>1) & #x55; ENDCASE
  }
}

AND testignorearg() BE
{ LET rel = 0
  writef("Testing ignoreargs*n")
  inittest()
  rel := mkrel(1, 0, 0, 0, 0)

  FOR relbits = 0 TO #b11111111 DO
    FOR i = 0 TO 2 DO
    { LET na, nb, nc = ?, ?, ?
      LET p = ?

      IF i=0 DO p := @na
      IF i=1 DO p := @nb
      IF i=2 DO p := @nc

      FOR a = 0 TO 1 FOR b = 0 TO 1 FOR c = 0 TO 1 DO
      { LET res1, res2, res3, res4 = ?, ?, ?, ?

        rel!r_w0, rel!r_a0, rel!r_a1, rel!r_a2 := relbits, 1, 2, 3
        na, nb, nc := a, b, c

        !p := 0
        res1 := evalrel(rel, 0, na, nb, nc)
        !p := 1
        res2 := evalrel(rel, 0, na, nb, nc)
        ignorearg(rel, i)
        !p := 0
        res3 := evalrel(rel, 0, na, nb, nc)
        !p := 1
        res4 := evalrel(rel, 0, na, nb, nc)
        // Check that the standardises relation is equivalent
        // to the original.
        IF (res1|res2)=res3 & res4=0 LOOP

bad:
        writef("ERROR: ignorearg(rel, %n)*n", i)

        rel!r_w0 := relbits
        !p := 0
        res1 := evalrel(rel, 0, na, nb, nc)
        writef("%b8 %n %n %n => %n*n", rel!r_w0, na, nb, nc, res1)
        !p := 1
        res2 := evalrel(rel, 0, na, nb, nc)
        writef("%b8 %n %n %n => %n*n", rel!r_w0, na, nb, nc, res2)
        ignorearg(rel, i)
        !p := 0
        res3 := evalrel(rel, 0, na, nb, nc)
        writef("%b8 %n %n %n => %n*n", rel!r_w0, na, nb, nc, res3)
        !p := 1
        res4 := evalrel(rel, 0, na, nb, nc)
        writef("%b8 %n %n %n => %n*n", rel!r_w0, na, nb, nc, res4)
        abort(999)
      }
    }
}

AND dontcare(rel, i) = VALOF
{ // Return TRUE if the relation does not depend on the arg i.
  LET a = rel!r_w0

  SWITCHON i INTO
  { DEFAULT:  bug("dontcase: Bad argument number %n*n", i)
              RESULTIS FALSE
    CASE 2:  RESULTIS ((a XOR a>>4) & #x0F) = 0 -> TRUE, FALSE
    CASE 1:  RESULTIS ((a XOR a>>2) & #x33) = 0 -> TRUE, FALSE
    CASE 0:  RESULTIS ((a XOR a>>1) & #x55) = 0 -> TRUE, FALSE
  }
}

AND testdontcare() BE
{ LET rel = 0
  writef("Testing dontcare*n")
  inittest()
  rel := mkrel(1, 0, 0, 0, 0)

  FOR relbits = 0 TO #b11111111 DO
    FOR i = 0 TO 2 DO
    { LET na, nb, nc = ?, ?, ?
      LET p = ?
      LET dc = TRUE // dont care is TRUE until found otherwise
      IF i=0 DO p := @na
      IF i=1 DO p := @nb
      IF i=2 DO p := @nc

      FOR a = 0 TO 1 FOR b = 0 TO 1 FOR c = 0 TO 1 DO
      { LET res1, res2, res3, res4 = ?, ?, ?, ?
        rel!r_w0, rel!r_a0, rel!r_a1, rel!r_a2 := relbits, 1, 2, 3
        na, nb, nc := a, b, c
        IF !p=1 LOOP

        !p := 0
        res1 := evalrel(rel, 0, na, nb, nc)
        !p := 1
        res2 := evalrel(rel, 0, na, nb, nc)
        UNLESS res1=res2 DO dc := FALSE
      }

      IF dc = dontcare(rel, i) LOOP

      writef("ERROR: dontcare(rel, %n) should give %n*n", i, dc)

      FOR a = 0 TO 1 FOR b = 0 TO 1 FOR c = 0 TO 1 DO
      { LET res1, res2, res3, res4 = ?, ?, ?, ?
        rel!r_w0, rel!r_a0, rel!r_a1, rel!r_a2 := relbits, 1, 2, 3
        na, nb, nc := a, b, c

        IF !p=1 LOOP

        writef("%b8: ", rel!r_w0)

        !p := 0
        res1 := evalrel(rel, 0, na, nb, nc)
        writef("%n %n %n => %n, ", na, nb, nc, res1)
        !p := 1
        res2 := evalrel(rel, 0, na, nb, nc)
        writef("%n %n %n => %n*n", na, nb, nc, res2)
      }
      abort(999)
    }
}

AND standardise(rel) BE
// Standardise a relation
{ LET w0, a = ?, @rel!r_a0
  LET t, x, y, z = ?, a!0, a!1, a!2

  // Remove arguments not constrained by this relation
  IF x & dontcare(rel, 0) DO x := 0
  IF y & dontcare(rel, 1) DO y := 0
  IF z & dontcare(rel, 2) DO z := 0

  // Remove duplicate non zero arguments
  IF x DO
  { IF x=y   DO { apeq(rel, 0, 1); ignorearg(rel, 1); y := 0 }
    IF x=z   DO { apeq(rel, 0, 2); ignorearg(rel, 2); z := 0 }
  }
  IF y & y=z DO { apeq(rel, 1, 2); ignorearg(rel, 2); z := 0 }

  // All non zero arguments are unique.
  // Sort the arguments.

  IF x=0 DO
  { // 0??
    IF z DO
    { // 0?z => z?0
      exchargs(rel, 0, 2)
      // z?0
      IF y & y<z DO
      { // zy0, y<z
        exchargs(rel, 0, 1)
        // yz0
        x := y
        y := z
        z := 0
        GOTO clean      // yz0
      }
      // z00 or zy0
      x := z
      z := 0
      GOTO clean        // z00 or zy0
    }
    // 0?0
    IF y DO
    { // 0y0 => y00
      exchargs(rel, 0, 1)
      x := y
      y := 0
      z := 0
    }
    GOTO clean          // 000 or y00
  }
  // x??
  IF y=0 DO
  { // x0?
    IF z=0 GOTO clean  // x00
    // x0z
    exchargs(rel, 1, 2)
    // xz0
    IF x<z DO
    { y := z
      z := 0
      GOTO clean       // xz0
    }
    exchargs(rel, 0, 1)
    // zx0
    y := x
    x := z
    z := 0
    GOTO clean         // zx0
  }
  // xy?
  IF z=0 DO
  { // xy0
    IF x<y GOTO clean  // xy0
    exchargs(rel, 0, 1)
    t := x
    x := y
    y := t
    GOTO clean        // yx0
  }
  // xyz
  IF x<y DO
  { // xyz, x<y
    IF y<z GOTO clean  // xyz
    // xyz, x<y, z<y
    IF x<z DO
    { // xyz, x<z<y
      exchargs(rel, 1, 2)
      // yx0 or yxz
      t := y
      y := z
      z := t
      GOTO clean       // xzy
    }
    // xyz, z<x<y
    exchargs(rel, 0, 2)
    exchargs(rel, 1, 2)
      // zyx
    t := x
    x := z
    z := y
    y := t
    GOTO clean         // zxy
  }
  // xyz, y<x
  IF z<y DO
  { // xyz, z<y<x
    exchargs(rel, 0, 2)
    t := x
    x := z
    z := t
    GOTO clean  // zyx
  }
  // xyz, y<x, y<z
  exchargs(rel, 0, 1)
  // yxz, y<x, y<z
  IF x<z DO
  { // yxz, y<x<z
    t := x
    x := y
    y := t
    GOTO clean           // yxz
  }
  // yxz, y<z<x
  exchargs(rel, 1, 2)
  t := x
  x := y
  y := z
  z := t                 // yzx

clean:
  // Plant the newly positioned arguments.
  a!0, a!1, a!2 := x, y, z

  // Clear unused bits in the bit pattern
  IF z RETURN                                     // xyz
  IF y DO { rel!r_w0 := rel!r_w0 & #x0F; RETURN } // xy0
  IF x DO { rel!r_w0 := rel!r_w0 & #x03; RETURN } // x00
  rel!r_w0 := rel!r_w0 & #x01                     // 000
}

AND teststandardise() BE
{ LET rel = 0
  writef("Testing standardise*n")
  inittest()
  rel := mkrel(1, 0, 0, 0, 0)

  FOR relbits = 0 TO #b11111111 DO
    FOR va = 0 TO 3 FOR vb = 0 TO 3 FOR vc = 0 TO 3 DO
      FOR a = 0 TO 1 FOR b = 0 TO 1 FOR c = 0 TO 1 DO
      { LET res1, res2 = ?, ?
        rel!r_w0, rel!r_a0, rel!r_a1, rel!r_a2 := relbits, va, vb, vc
        res1 := evalrel(rel, 0, a, b, c)
        standardise(rel)
        res2 := evalrel(rel, 0, a, b, c)
        // Check that the standardises relation is equivalent
        // to the original.
        UNLESS res1=res2 GOTO bad

        // Check that the arguments are sorted and that there are
        // no duplicates.
        IF rel!r_a0=0 { UNLESS rel!r_a1 | rel!r_a2 LOOP // 000
                        GOTO bad                        // 0y0 00z 0yz
                      }
        IF rel!r_a1=0 { UNLESS rel!r_a2 LOOP            // x00
                        GOTO bad                        // x0z
                      }
        UNLESS rel!r_a0 < rel!r_a1 GOTO bad             // xy?  x>=y
        IF rel!r_a2=0 LOOP                              // xy0
        IF rel!r_a1 < rel!r_a2 LOOP                     // xyz

bad:
        writef("ERROR: standardise(rel)*
               * environment v1=%n v2=%n v3=%n*n", a, b, c)
        writef("%b8 v%n v%n v%n => %n*n", relbits, va, vb, vc, res1)
        writef("%b8 v%n v%n v%n => %n*n",
                rel!r_w0, rel!r_a0, rel!r_a1, rel!r_a2, res2)
        abort(999)
      }
}

AND testtrans1() BE
{ writef("*nTesting all functions in module: trans1*n")
  testexchargs()
  testignorearg()
  testdontcare()
  teststandardise()
}

.

SECTION "apfns"

// The apply functions on a single relation

// apnot(rel, i)         apply the NOT operator to argument i
// ignore(rel, i)        remove arg i assuming it is unconstrained

// apis1(rel, i)         apply  ai  =   1,   eliminate ai
// apis0(rel, i)         apply  ai  =   0,   eliminate ai
// apeq(rel, i, j)       apply  ai  =  aj,   eliminate aj
// apne(rel, i, j)       apply  ai  = ~aj,   eliminate aj

// apimppp(rel, i, j)    apply  ai ->  aj
// apimppn(rel, i, j)    apply  ai -> ~aj
// apimpnp(rel, i, j)    apply ~ai ->  aj
// apimpnn(rel, i, j)    apply ~ai -> ~aj

GET "libhdr"
GET "chk3.h"



// Update rel bits corresponding to argument i being complemented
// eg, if i=2: R11010110(x,y,z) => R01101101(x,y,~z)
// Only the rel bits are changed, the arguments are not touched.

// x 10101010
// y 11001100
// z 11110000

//   11010110 means xyz = 111, 011, 001, 010 or 100
//   01101101 means xyz = 110, 010, 000, 011 or 101
LET apnot(rel, i) BE
{ LET a = rel!r_w0
  SWITCHON i INTO
  { DEFAULT: writef("apnot error*n"); abort(999);   RETURN
    CASE 2:  rel!r_w0 := a<<4 & #xF0 | a>>4 & #x0F; ENDCASE
    CASE 1:  rel!r_w0 := a<<2 & #xCC | a>>2 & #x33; ENDCASE
    CASE 0:  rel!r_w0 := a<<1 & #xAA | a>>1 & #x55; ENDCASE
  }
}

AND testapnot() BE
{ writef("Testing apnot*n")
  FOR rel = 0 TO #b_1111_1111 DO
  { LET r1 = 0
    inittest()
    r1 := mkrel(rel, 1, 2, 3)
    FOR a = 0 TO 1 FOR b = 0 TO 1 FOR c = 0 TO 1 DO
    { LET res1, res2, i = ?, ?, ?
      LET v1, v2, v3 = a, b, c
      r1!r_w0 := rel
      res1 := evalrel(r1, 0, v1, v2, v3)
      i, r1!r_w0 := 0, rel
      apnot(r1, i)
      v1, v2, v3 := 1-a, b, c
      res2 := evalrel(r1, 0, v1, v2, v3)
      UNLESS res1=res2 GOTO bad
      i, r1!r_w0 := 1, rel
      apnot(r1, i)
      v1, v2, v3 := a, 1-b, c
      res2 := evalrel(r1, 0, v1, v2, v3)
      UNLESS res1=res2 GOTO bad
      i, r1!r_w0 := 2, rel
      apnot(r1, i)
      v1, v2, v3 := a, b, 1-c
      res2 := evalrel(r1, 0, v1, v2, v3)
      UNLESS res1=res2 GOTO bad
//abort(2222)
      LOOP

bad:  writef("ERROR: apnot(r1, %n)*n", i)
      r1!r_w0 := rel
      writef("%b8 v1=%n v2=%n v3=%n => %n*n", rel,     a,   b,  c, res1)
      r1!r_w0 := rel
      apnot(r1, i)
      writef("%b8 v1=%n v2=%n v3=%n => %n*n", r1!r_w0, v1, v2, v3, res2)
      abort(999)
    }
  }
}

// Argument i is known to have value 1
// eg, if i=2: R11010110(x,y,z) => R11010000(x,y,z)
// (It does not change any arg value).

// x 10101010
// y 11001100
// z 11110000

//   11010110 means xyz = 111, 011, 001 or 010 or 100
//   11010000 means xyz = 111, 011, 001

// ie: select only the patterns corresponding to vk=1
// where arg_i = k.
AND apis1(rel, i) BE SWITCHON i INTO
{ DEFAULT: bug("Error in apis1: i=%n*n", i); RETURN
  CASE 2:  rel!r_w0 := rel!r_w0 & #xF0;      ENDCASE
  CASE 1:  rel!r_w0 := rel!r_w0 & #xCC;      ENDCASE
  CASE 0:  rel!r_w0 := rel!r_w0 & #xAA;      ENDCASE
}

AND testapis1() BE
{ writef("Testing apis1*n")
  FOR rel = 0 TO #b_1111_1111 DO
  { LET r1 = 0
    inittest()
    r1 := mkrel(rel, 1, 2, 3)
    FOR a = 0 TO 1 FOR b = 0 TO 1 FOR c = 0 TO 1 DO
    { LET res1, res2, i = ?, ?, ?
      r1!r_w0 := rel
      res1 := evalrel(r1, 0, a, b, c)
      i, r1!r_w0 := 0, rel
      apis1(r1, i)
      res2 := evalrel(r1, 0, a, b, c)
      UNLESS res2 = (a=0 -> 0 , res1) GOTO bad
      i, r1!r_w0 := 1, rel
      apis1(r1, i)
      res2 := evalrel(r1, 0, a, b, c)
      UNLESS res2 = (b=0 -> 0 , res1) GOTO bad
      i, r1!r_w0 := 2, rel
      apis1(r1, i)
      res2 := evalrel(r1, 0, a, b, c)
      UNLESS res2 = (c=0 -> 0 , res1) GOTO bad
//abort(2222)
      LOOP

bad:  writef("ERROR: apis1(r2, %n)*n", i)
      writef("%b8 v1=%n v2=%n v3=%n => %n*n", rel,     a, b, c, res1)
      r1!r_w0 := rel
      apis1(r1, i)
      writef("%b8 v1=%n v2=%n v3=%n => %n*n", r1!r_w0, a, b, c, res2)
      abort(999)
    }
  }
}

// Argument i is known to have value 0
// eg, if i=2: R11010110(x,y,z) => R00001101(x,y,z)
// (It does not change any arg value).

// x 10101010
// y 11001100
// z 11110000

//   11010110 means xyz = 111 or 011 or 001 or 010 or 100
//   00000110 means xyz =                      010 or 100
AND apis0(rel, i) BE SWITCHON i INTO
{ DEFAULT: bug("Error in apis0: i=%n*n", i); RETURN
  CASE 2:  rel!r_w0 := rel!r_w0 & #x0F;      ENDCASE
  CASE 1:  rel!r_w0 := rel!r_w0 & #x33;      ENDCASE
  CASE 0:  rel!r_w0 := rel!r_w0 & #x55;      ENDCASE
}

AND testapis0() BE
{ writef("Testing apis0*n")
  FOR rel = 0 TO #b_1111_1111 DO
  { LET r1 = 0
    inittest()
    r1 := mkrel(rel, 1, 2, 3)
    FOR a = 0 TO 1 FOR b = 0 TO 1 FOR c = 0 TO 1 DO
    { LET res1, res2, i = ?, ?, ?
      r1!r_w0 := rel
      res1 := evalrel(r1, 0, a, b, c)
      i, r1!r_w0 := 0, rel
      apis0(r1, i)
      res2 := evalrel(r1, 0, a, b, c)
      UNLESS res2 = (a=1 -> 0 , res1) GOTO bad
      i, r1!r_w0 := 1, rel
      apis0(r1, i)
      res2 := evalrel(r1, 0, a, b, c)
      UNLESS res2 = (b=1 -> 0 , res1) GOTO bad
      i, r1!r_w0 := 2, rel
      apis0(r1, i)
      res2 := evalrel(r1, 0, a, b, c)
      UNLESS res2 = (c=1 -> 0 , res1) GOTO bad
//abort(2222)
      LOOP

bad:  writef("ERROR: apis0(r2, %n)*n", i)
      writef("%b8 v1=%n v2=%n v3=%n => %n*n", rel,     a, b, c, res1)
      r1!r_w0 := rel
      apis0(r1, i)
      writef("%b8 v1=%n v2=%n v3=%n => %n*n", r1!r_w0, a, b, c, res2)
      abort(999)
    }
  }
}

// Apply:  ai = aj, i ~= j
// eg: R11010110(x,y,z) with y=z gives R11000010(x,y,z)
// ie disallow any triplet for which Vai ~= Vaj

// x 10101010
// y 11001100
// z 11110000

//   11010110 means xyz = 111 or 011 or 001 or 010 or 100
//   11000010 means xyz = 111 or 011               or 100
AND apeq(rel, i, j) BE SWITCHON i*8+j INTO
{ DEFAULT: bug("Bad apeq(..,%n,%n)*n", i, j);      ENDCASE
  CASE #21: CASE #12: rel!r_w0 := rel!r_w0 & #xC3; ENDCASE
  CASE #20: CASE #02: rel!r_w0 := rel!r_w0 & #xA5; ENDCASE
  CASE #10: CASE #01: rel!r_w0 := rel!r_w0 & #x99; ENDCASE
}

AND testapeq() BE
{ writef("Testing apeq*n")
  FOR i = 0 TO 2 FOR j = 0 TO 2 UNLESS i=j DO
    FOR rel = 0 TO #b_1111_1111 DO
    { LET r1 = 0
      inittest()
      r1 := mkrel(rel, 1, 2, 3)
      FOR a = 0 TO 1 FOR b = 0 TO 1 FOR c = 0 TO 1 DO
      { LET res1, res2 = ?, ?
        LET v1, v2, v3 = a, b, c
        LET v = @v1
        r1!r_w0 := rel
        res1 := evalrel(r1, 0, a, b, c)
        r1!r_w0 := rel
        apeq(r1, i, j)
        res2 := evalrel(r1, 0, a, b, c)
        UNLESS res2 = (v!i~=v!j -> 0 , res1) GOTO bad
//abort(2222)
        LOOP

bad:    writef("ERROR: apeq(r1, %n, %n)*n", i, j)
        writef("%b8 v1=%n v2=%n v3=%n => %n*n", rel,     a, b, c, res1)
        r1!r_w0 := rel
        apeq(r1, i, j)
        writef("%b8 v1=%n v2=%n v3=%n => %n*n", r1!r_w0, a, b, c, res2)
        abort(999)
      }
  }
}



// Apply:  ai ~= aj
// eg: R11010110(x,y,z) with y=~z gives R00000101(x,y,0)

// x 10101010
// y 11001100
// z 11110000

//   11010110 means xyz = 111 or 011 or 001 or 010 or 100
//   00000101 means xy  =               00  or 01
AND apne(rel, i, j) BE SWITCHON i*8+j INTO
{ DEFAULT: bug("Bad apne(..,%n,%n)*n", i, j);      ENDCASE

  CASE #21: CASE #12: rel!r_w0 := rel!r_w0 & #x3C; ENDCASE
  CASE #20: CASE #02: rel!r_w0 := rel!r_w0 & #x5A; ENDCASE
  CASE #10: CASE #01: rel!r_w0 := rel!r_w0 & #x66; ENDCASE
}

AND testapne() BE
{ writef("Testing apne*n")
  FOR i = 0 TO 2 FOR j = 0 TO 2 UNLESS i=j DO
    FOR rel = 0 TO #b_1111_1111 DO
    { LET r1 = 0
      inittest()
      r1 := mkrel(rel, 1, 2, 3)
      FOR a = 0 TO 1 FOR b = 0 TO 1 FOR c = 0 TO 1 DO
      { LET res1, res2 = ?, ?
        LET v1, v2, v3 = a, b, c
        LET v = @v1
        r1!r_w0 := rel
        res1 := evalrel(r1, 0, a, b, c)
        r1!r_w0 := rel
        apne(r1, i, j)
        res2 := evalrel(r1, 0, a, b, c)
        UNLESS res2 = (v!i=v!j -> 0 , res1) GOTO bad
//abort(2222)
        LOOP

bad:    writef("ERROR: apne(r1, %n, %n)*n", i, j)
        writef("%b8 v1=%n v2=%n v3=%n => %n*n", rel,     a, b, c, res1)
        r1!r_w0 := rel
        apne(r1, i, j)
        writef("%b8 v1=%n v2=%n v3=%n => %n*n", r1!r_w0, a, b, c, res2)
        abort(999)
      }
  }
}

// Apply:  ai -> aj
// eg: R11010110(x,y,z) with y->z gives R11010010(x,y,z)

// x 10101010
// y 11001100
// z 11110000
//   yyyy  yy

//   11010110 means xyz = 111 or 011 or 001 or 010 or 100
//   11010010 means xyz = 111 or 011 or 001        or 100
AND apimppp(rel, i, j) BE SWITCHON i*8+j INTO
{ DEFAULT:  bug("Bad apimppp(..,%n,%n)*n", i, j); ENDCASE

  CASE #22:                                       ENDCASE
  CASE #21: rel!r_w0 := rel!r_w0 & #xCF;          ENDCASE
  CASE #20: rel!r_w0 := rel!r_w0 & #xAF;          ENDCASE

  CASE #12: rel!r_w0 := rel!r_w0 & #xF3;          ENDCASE
  CASE #11:                                       ENDCASE
  CASE #10: rel!r_w0 := rel!r_w0 & #xBB;          ENDCASE

  CASE #02: rel!r_w0 := rel!r_w0 & #xF5;          ENDCASE
  CASE #01: rel!r_w0 := rel!r_w0 & #xDD;          ENDCASE
  CASE #00:                                       ENDCASE
}

AND testapimppp() BE
{ writef("Testing apimppp*n")
  FOR i = 0 TO 2 FOR j = 0 TO 2 DO
    FOR rel = 0 TO #b_1111_1111 DO
    { LET r1 = 0
      inittest()
      r1 := mkrel(rel, 1, 2, 3)
      FOR a = 0 TO 1 FOR b = 0 TO 1 FOR c = 0 TO 1 DO
      { LET res1, res2 = ?, ?
        LET v1, v2, v3 = a, b, c
        LET v = @v1
        r1!r_w0 := rel
        res1 := evalrel(r1, 0, a, b, c)
        r1!r_w0 := rel
        apimppp(r1, i, j)
        res2 := evalrel(r1, 0, a, b, c)
        UNLESS res2 = (v!i=1 & v!j=0 -> 0 , res1) GOTO bad
//abort(2222)
        LOOP

bad:    writef("ERROR: apimppp(r1, %n, %n)*n", i, j)
        writef("%b8 v1=%n v2=%n v3=%n => %n*n", rel,     a, b, c, res1)
        r1!r_w0 := rel
        apimppp(r1, i, j)
        writef("%b8 v1=%n v2=%n v3=%n => %n*n", r1!r_w0, a, b, c, res2)
        abort(999)
      }
  }
}

// Apply  ai -> ~aj
// eg: R11010110(x,y,z) with y->~z gives R00010110(x,y,z)

// x 10101010
// y 11001100
// z 11110000
//     yyyyyy

//   11010110 means xyz = 111 or 011 or 001 or 010 or 100
//   00010110 means xyz =               001 or 010 or 100
AND apimppn(rel, i, j) BE SWITCHON i*8+j INTO
{ DEFAULT:  bug("Bad apimppn(..,%n,%n)*n", i, j); ENDCASE

  CASE #22: rel!r_w0 := rel!r_w0 & #x0F;          ENDCASE
  CASE #21: rel!r_w0 := rel!r_w0 & #x3F;          ENDCASE
  CASE #20: rel!r_w0 := rel!r_w0 & #x5F;          ENDCASE

  CASE #12: rel!r_w0 := rel!r_w0 & #x3F;          ENDCASE
  CASE #11: rel!r_w0 := rel!r_w0 & #x33;          ENDCASE
  CASE #10: rel!r_w0 := rel!r_w0 & #x77;          ENDCASE

  CASE #02: rel!r_w0 := rel!r_w0 & #x5F;          ENDCASE
  CASE #01: rel!r_w0 := rel!r_w0 & #x77;          ENDCASE
  CASE #00: rel!r_w0 := rel!r_w0 & #x55;          ENDCASE
}

AND testapimppn() BE
{ writef("Testing apimppn*n")
  FOR i = 0 TO 2 FOR j = 0 TO 2 DO
    FOR rel = 0 TO #b_1111_1111 DO
    { LET r1 = 0
      inittest()
      r1 := mkrel(rel, 1, 2, 3)
      FOR a = 0 TO 1 FOR b = 0 TO 1 FOR c = 0 TO 1 DO
      { LET res1, res2 = ?, ?
        LET v1, v2, v3 = a, b, c
        LET v = @v1
        r1!r_w0 := rel
        res1 := evalrel(r1, 0, a, b, c)
        r1!r_w0 := rel
        apimppn(r1, i, j)
        res2 := evalrel(r1, 0, a, b, c)
        UNLESS res2 = (v!i=1 & v!j=1 -> 0 , res1) GOTO bad
//abort(2222)
        LOOP

bad:    writef("ERROR: apimppn(r1, %n, %n)*n", i, j)
        writef("%b8 v1=%n v2=%n v3=%n => %n*n", rel,     a, b, c, res1)
        r1!r_w0 := rel
        apimppn(r1, i, j)
        writef("%b8 v1=%n v2=%n v3=%n => %n*n", r1!r_w0, a, b, c, res2)
        abort(999)
      }
  }
}


// Apply ~ai -> aj
// eg: R11010110(x,y,z) with ~y->z gives R11010010(x,y,z)

// x 10101010
// y 11001100
// z 11110000
//   yyyyyy

//   11010110 means xyz = 111 or 011 or 001 or 010 or 100
//   11010010 means xyz = 111 or 011 or 001        or 100
AND apimpnp(rel, i, j) BE SWITCHON i*8+j INTO
{ DEFAULT:  bug("Bad apimppn(..,%n,%n)*n", i, j); ENDCASE

  CASE #22: rel!r_w0 := rel!r_w0 & #xF0;          ENDCASE
  CASE #21: rel!r_w0 := rel!r_w0 & #xFC;          ENDCASE
  CASE #20: rel!r_w0 := rel!r_w0 & #xFA;          ENDCASE

  CASE #12: rel!r_w0 := rel!r_w0 & #xFC;          ENDCASE
  CASE #11: rel!r_w0 := rel!r_w0 & #xCC;          ENDCASE
  CASE #10: rel!r_w0 := rel!r_w0 & #xEE;          ENDCASE

  CASE #02: rel!r_w0 := rel!r_w0 & #xFA;          ENDCASE
  CASE #01: rel!r_w0 := rel!r_w0 & #xEE;          ENDCASE
  CASE #00: rel!r_w0 := rel!r_w0 & #xAA;          ENDCASE
}

AND testapimpnp() BE
{ writef("Testing apimpnp*n")
  FOR i = 0 TO 2 FOR j = 0 TO 2 DO
    FOR rel = 0 TO #b_1111_1111 DO
    { LET r1 = 0
      inittest()
      r1 := mkrel(rel, 1, 2, 3)
      FOR a = 0 TO 1 FOR b = 0 TO 1 FOR c = 0 TO 1 DO
      { LET res1, res2 = ?, ?
        LET v1, v2, v3 = a, b, c
        LET v = @v1
        r1!r_w0 := rel
        res1 := evalrel(r1, 0, a, b, c)
        r1!r_w0 := rel
        apimpnp(r1, i, j)
        res2 := evalrel(r1, 0, a, b, c)
        UNLESS res2 = (v!i=0 & v!j=0 -> 0 , res1) GOTO bad
//abort(2222)
        LOOP

bad:    writef("ERROR: apimpnp(r1, %n, %n)*n", i, j)
        writef("%b8 v1=%n v2=%n v3=%n => %n*n", rel,     a, b, c, res1)
        r1!r_w0 := rel
        apimpnp(r1, i, j)
        writef("%b8 v1=%n v2=%n v3=%n => %n*n", r1!r_w0, a, b, c, res2)
        abort(999)
      }
  }
}


// Apply: ~ai -> ~aj
// eg: R11010110(x,y,z) with ~y->~z gives R11010010(x,y,z)

// x 10101010
// y 11001100
// z 11110000

//   11010110 means xyz = 111 or 011 or 001 or 010 or 100
//   11000110 means xyz = 111 or 011        or 010 or 100
AND apimpnn(rel, i, j) BE apimppp(rel, j, i)

AND testapimpnn() BE
{ writef("Testing apimpnn*n")
  FOR i = 0 TO 2 FOR j = 0 TO 2 DO
    FOR rel = 0 TO #b_1111_1111 DO
    { LET r1 = 0
      inittest()
      r1 := mkrel(rel, 1, 2, 3)
      FOR a = 0 TO 1 FOR b = 0 TO 1 FOR c = 0 TO 1 DO
      { LET res1, res2 = ?, ?
        LET v1, v2, v3 = a, b, c
        LET v = @v1
        r1!r_w0 := rel
        res1 := evalrel(r1, 0, a, b, c)
        r1!r_w0 := rel
        apimpnn(r1, i, j)
        res2 := evalrel(r1, 0, a, b, c)
        UNLESS res2 = (v!i=0 & v!j=1 -> 0 , res1) GOTO bad
//abort(2222)
        LOOP

bad:    writef("ERROR: apimpnn(r1, %n, %n)*n", i, j)
        writef("%b8 v1=%n v2=%n v3=%n => %n*n", rel,     a, b, c, res1)
        r1!r_w0 := rel
        apimpnn(r1, i, j)
        writef("%b8 v1=%n v2=%n v3=%n => %n*n", r1!r_w0, a, b, c, res2)
        abort(999)
      }
  }
}

AND testapfns() BE
{ // Test all the functions in this module
  writef("*nTesting all functions in module: apfns*n")
  testapnot()
  testapis1()
  testapis0()
  testapeq()
  testapne()
  testapimppp()
  testapimppn()
  testapimpnp()
  testapimpnn()
}

.

// The apply newly discovered information about a variable
// or a pair of variables

// These apply to all relations

// apvarset1(i)        apply  vi  =   1 and eliminate vi
// apvarset0(i)        apply  vi  =   0 and eliminate vi

// apvareq(i, j)       apply  vi  =  vj and eliminate vj, i<j
// apvarne(i, j)       apply  vi  = ~vj and eliminate vj, i<j

// apvarimppp(i, j)    apply  vi ->  vj
// apvarimppn(i, j)    apply  ai -> ~vj
// apvarimpnp(i, j)    apply  vi ->  vj
// apvarimpnn(i, j)    apply ~vi -> ~vj

SECTION "applyfns"

GET "libhdr"
GET "chk3.h"

LET ignorevar(rel, id) BE
{ 
  IF rel!r_a0=id DO ignorearg(rel, 0)
  IF rel!r_a1=id DO ignorearg(rel, 1)
  IF rel!r_a2=id DO ignorearg(rel, 2)
}

LET apvarset1(i) BE
{ // For every relation involving vi
  // set it to 1,
  // remove that variable from the relation
  // and push the relation onto the stack if it is not already there.
  LET rl = refs!i
  writef("apvarset1: v%n = 1*n", origid(i))

  varinfo!i := 1  // Remember that vi=1

  WHILE rl DO
  { LET rel = rl!1
    LET v = @rel!r_a0
    LET a = 7
    rl := !rl

    // Find the argument number of vi
    UNTIL a<0 | v!a=i DO a := a-1
    IF a<0 DO
    { wrrel(rel, TRUE)
      bug("apvarset1: v%n is not in this relation*n", origid(i))
      LOOP
    }
    // Find and eliminate all occurrences of vi
    { IF v!a=i DO
      { newline()
        wrrel(rel, TRUE)
        apis1(rel, a)
        //standardise(rel)
        pushrel(rel)
      }
      a := a-1
    } REPEATUNTIL a<0
  }
  refcount!i := 0
abort(3333)
}

AND apvarset0(i) BE
{ // For every relation involving vi
  // set it to 0,
  // remove that variable from the relation
  // and push the relation onto the stack if it is not already there.
  LET rl = refs!i
  writef("apvarset0: v%n = 0*n", origid(i))

  varinfo!i := 0  // Remember that vi=0

  WHILE rl DO
  { LET rel = rl!1
    LET v = @rel!r_a0
    LET a = 7
    rl := !rl


    // Find the argument number of vi
    UNTIL a<0 | v!a=i DO a := a-1
    IF a<0 DO
    { wrrel(rel, TRUE)
      bug("apvarset0: v%n is not in this relation*n", origid(i))
      LOOP
    }

    // Find and eliminate all occurrences of vi
    { IF v!a=i DO
      { newline()
        wrrel(rel, TRUE)
        apis0(rel, a)
        //standardise(rel)
        pushrel(rel)
      }
      a := a-1
    } REPEATUNTIL a<0
    //wrrel(rel, TRUE)
  }
  refcount!i := 0
abort(3333)
}

AND apvareq(i, j) BE
{ // Assume i<j
  // For every relation involving vi and vj
  // set vj=vi and remove vj from the relation
  // and push the relation onto the stack if it is not already there.
  LET rl = refs!i
writef("apvareq: v%n =  v%n*n", origid(i), origid(j))

  varinfo!i := 2*j  // Remember that vi=vj

  WHILE rl DO
  { LET rel = rl!1
    LET v = @rel!r_a0
    LET a, b = 2, 2
    rl := !rl

    // Find the argument number of vj if it occurs
    UNTIL b<0 | v!b=j DO b := b-1

    IF b<0 LOOP // vj is not in this relation
//wrrel(rel, TRUE)
    // Find the argument number of vi
    UNTIL a<0 | v!a=i DO a := a-1
    IF a<0 DO
    { wrrel(rel, TRUE)
      bug("apvareq: v%n is not in this relation*n", origid(i))
      LOOP
    }
    newline()
    wrrel(rel, TRUE)

    // Find and eliminate all occurrences of vj
    { IF v!b=j DO apeq(rel, a, b)
      b := b-1
    } REPEATUNTIL b<0

    pushrel(rel)
//    wrrel(rel, TRUE)
  }
  refcount!j := 0
abort(3333)
}

AND apvarne(i, j) BE
{ // Assume i<j
  // For every relation involving vi and vj
  // set vj=~vi and remove vj from the relation
  // and push the relation onto the stack if it is not already there.
  LET rl = refs!i
writef("apvarne: v%n =  v%n*n", origid(i), origid(j))

  varinfo!i := 2*j + 1  // Remember that vi = ~vj

  WHILE rl DO
  { LET rel = rl!1
    LET v = @rel!r_a0
    LET a, b = 2, 2
    rl := !rl

    // Find the argument number of vj if it occurs
    UNTIL b<0 | v!b=j DO b := b-1

    IF b<0 LOOP // vj is not in this relation
//wrrel(rel, TRUE)
    // Find the argument number of vi
    UNTIL a<0 | v!a=i DO a := a-1
    IF a<0 DO
    { wrrel(rel, TRUE)
      bug("apvarne: v%n is not in this relation*n", origid(i))
      LOOP
    }
    newline()
    wrrel(rel, TRUE)

    // Find and eliminate all occurrences of vj
    { IF v!b=j DO apne(rel, a, b)
      b := b-1
    } REPEATUNTIL b<0

    pushrel(rel)
//wrrel(rel, TRUE)
  }
  refcount!j := 0
abort(3333)
}

AND apvarimppp(i, j) BE
{ // Assume i<j
  // For every relation involving vi and vj
  // impose the constraint vi->vj
  // and push the relation onto the stack if it is not already there.
  LET rl = refs!i
writef("apvarimppp:  v%n ->  v%n*n", origid(i), origid(j))

  WHILE rl DO
  { LET rel = rl!1
    LET v = @rel!r_a0
    LET a, b = 2, 2
    rl := !rl

    // Find the argument number of vj if it occurs
    UNTIL b<0 | v!b=j DO b := b-1
    IF b<0 LOOP // vj is not in this relation
    //wrrel(rel, TRUE)
    // Find the argument number of vi
    UNTIL a<0 | v!a=i DO a := a-1
    IF a<0 DO
    { newline()
      wrrel(rel, TRUE)
      bug("apvarne: v%n is not in this relation*n", origid(i))
      LOOP
    }
    newline()
    wrrel(rel, TRUE)
    // Apply vi->vj for all occurrences of vj ???????????????
    { IF v!b=j DO apimppp(rel, a, b)
      b := b-1
    } REPEATUNTIL b<0
    //wrrel(rel, TRUE)
  }
  refcount!j := 0
abort(3333)
}


AND apvarimppn(i, j) BE
{ // Assume i<j
  // For every relation involving vi and vj
  // impose the constraint vi->~vj
  // and push the relation onto the stack if it is not already there.
writef("apvarimppn:  v%n -> ~v%n*n", origid(i), origid(j))
  abort(8888)
  RETURN
}

AND apvarimpnp(i, j) BE
{ // Assume i<j
  // For every relation involving vi and vj
  // impose the constraint ~vi->vj
  // and push the relation onto the stack if it is not already there.
writef("apvarimpnp: ~v%n ->  v%n*n", origid(i), origid(j))
  abort(8888)
  RETURN
}

AND apvarimpnn(i, j) BE
{ // Assume i<j
  // For every relation involving vi and vj
  // impose the constraint ~vi->~vj
  // and push the relation onto the stack if it is not already there.
writef("apvarimpnn: ~v%n -> ~v%n*n", origid(i), origid(j))
  abort(8888)
  RETURN
}

AND testapvar() BE
{ // Test all the functions in this module
  writef("*nTesting all functions in module: apvar*n")
}

.

// Find all implications of a given relation

SECTION "findimps"

GET "libhdr"
GET "chk3.h"

// Discover all the relations of the form:
// vi = 0, vi = 1, vi = vj, vi = ~vj,
// vi -> vj, vi->~vj, ~vi->vj and ~vi->~vj
// implied by the given relation. For any such discovery, call
// the appropriate bmat functions
// 
// bm_setbitpp(vi, vj), bm_setbitpp(vi, vj), bm_setbitpp(vi, vj)
// bm_setbitnn(vi, vj).

LET findimps(rel) BE
// rel need not be in standard form, ie the variables can be
// in any order and any may be zero

// The relation bits are defined as follows:

//     [hgfedcba, v0, v1, v2]

// x    1 0 1 0 1 0 1 0
// y    1 1 0 0 1 1 0 0
// z    1 1 1 1 0 0 0 0
//      h g f e d c b a
//                    a=1  <=>  xyz = 000 is allowed
//                  b=1  <=>    xyz = 100 is allowed
//                c=1  <=>      xyz = 010 is allowed
//              d=1  <=>        xyz = 110 is allowed
//            e=1  <=>          xyz = 001 is allowed
//          f=1  <=>            xyz = 101 is allowed
//        g=1  <=>              xyz = 011 is allowed
//      h=1  <=>                xyz = 111 is allowed


{ LET w0 = rel!r_w0
  LET a, b, c = rel!r_a0, rel!r_a1, rel!r_a2

  IF c DO
  { IF (w0&#xF0)=0 DO bm_setvar0(c)       //  vc =  0
    IF (w0&#x0F)=0 DO bm_setvar1(c)       //  vc =  1
    IF b DO // Find implications involving vc and vb
    { IF (w0&#x0C)=0 DO bm_setbitpp(b, c) //  vb -> vc
      IF (w0&#xC0)=0 DO bm_setbitpn(b, c) //  vb ->~vc
      IF (w0&#x03)=0 DO bm_setbitnp(b, c) // ~vb -> vc
      IF (w0&#x30)=0 DO bm_setbitnn(b, c) // ~vb ->~vc
    }
    IF a DO // Find implications involving vc and va
    { IF (w0&#x0A)=0 DO bm_setbitpp(a, c) //  va -> vc
      IF (w0&#xA0)=0 DO bm_setbitpn(a, c) //  va ->~vc
      IF (w0&#x05)=0 DO bm_setbitnp(a, c) // ~va -> vc
      IF (w0&#x50)=0 DO bm_setbitnn(a, c) // ~va ->~vc
    }
  }
  IF b DO
  { IF (w0&#xCC)=0 DO bm_setvar0(b)       //  vb =  0
    IF (w0&#x33)=0 DO bm_setvar1(b)       //  vb =  1
    IF (w0&#x66)=0 DO bm_setvareq(b, a)   //  vb =  va
    IF (w0&#x99)=0 DO bm_setvarne(b, a)   //  vb = ~va
    IF a DO // Find implications involving vb and va
    { IF (w0&#x22)=0 DO bm_setbitpp(a, b) //  va -> vb
      IF (w0&#x88)=0 DO bm_setbitpn(a, b) //  va ->~vb
      IF (w0&#x11)=0 DO bm_setbitnp(a, b) // ~va -> vb
      IF (w0&#x44)=0 DO bm_setbitnn(a, b) // ~va ->~vb
    }
  }
  IF a DO
  { IF (w0&#xAA)=0 DO bm_setvar0(a)       // va = 0
    IF (w0&#x55)=0 DO bm_setvar1(a)       // va = 1
  }
}

AND testfindimps() BE
{ // Test all the functions in module: findimps
  //LET sv0, sv1 = bm_setvar0, bm_setvar1
  //AND seq, sne = bm_setvareq, bm_setvarne
  //AND spp = bm_setbitpp
  //AND spn = bm_setbitpn
  //AND snp = bm_setbitnp
  //AND snn = bm_setbitnn
  LET rel = VEC r_upb

  writef("*nTesting all functions in module: findimps*n")

  // Allocate some 3x3 boolean matrices
  bm_setmatsize(3)

  mata     := bm_mkmat()
  matb     := bm_mkmat()
  matc     := bm_mkmat()
  matd     := bm_mkmat()

  mataprev := bm_mkmat()
  matbprev := bm_mkmat()
  matcprev := bm_mkmat()
  matdprev := bm_mkmat()


  // Replace the bmat functions by testing versions
  //bm_setvar0, bm_setvar1 := tv0, tv1
  //bm_setvareq, bm_setvarne := teq, tne
  //bm_setbitpp := tpp
  //bm_setbitpn := tpn
  //bm_setbitnp := tnp
  //bm_setbitnn := tnn 

  FOR relbits = 0 TO #b_1111_1111 DO
  { rel!r_w0, rel!r_a0, rel!r_a1, rel!r_a2 := relbits, 1, 2, 3
    bm_clrmat(mata, matb, matc, matd)

    findimps(rel)
    writef("%b8:*n", relbits)
    bm_prmat(mata, matb, matc, matd)
    newline()
    bm_warshall(mata, matb, matc, matd)
    writef("after warshall:*n")
    bm_prmat(mata, matb, matc, matd)
    newline()
  }

  // Restore the original bmat functions.
  //bm_setvar0, bm_setvar1 := sv0, sv1
  //bm_setvareq, bm_setvarne := seq, sne
  //bm_setbitpp := spp
  //bm_setbitpn := spn
  //bm_setbitnp := snp
  //bm_setbitnn := snn  
}

AND tv0(a) BE
{ writef(" v%n=0", a)
}

AND tv1(a) BE
{ writef(" v%n=1", a)
}

AND teq(a, b) BE
{ writef(" v%n=v%n", a, b)
}

AND tne(a, b) BE
{ writef(" v%n=v%n", a, b)
}

AND tpp(a, b) BE
{ writef(" v%n->v%n", a, b)
}

AND tpn(a, b) BE
{ writef(" v%n->~v%n", a, b)
}

AND tnp(a, b) BE
{ writef(" ~v%n->v%n", a, b)
}

AND tnn(a, b) BE
{ writef(" ~v%n->~v%n", a, b)
}
.

SECTION "bmat"

// Boolean matrix functions for chk3

// bm_setmatsize(n)
// bm_mkmat()
// bm_clrmat(a, b, c, d)
// bm_setbitpp(i, j)
// bm_setbitpn(i, j)
// bm_setbitnp(i, j)
// bm_setbitnn(i, j)
// bm_setvar0(i)
// bm_setvar1(i)
// bm_setbit(m, i, j)
// bm_warshall(a, b, c, d)
// bm_prmat(a, b, c, d)
// bm_findnewinfo(a,b,c,d)

GET "libhdr"
GET "chk3.h"

LET bm_setmatsize(n) BE
{ matn := n                  // Rows and columns are numbered 1..n
  matnw := n/bitsperword + 1 // Number of words in a row
}

AND bm_mkmat() = VALOF
{ LET upb = matnw * matn - 1
  LET mat = getvec(upb)
  UNLESS mat DO
  { writef("bm_mkmat: more store needed*n")
    abort(999)
    RESULTIS 0
  }
  FOR i = 0 TO upb DO mat!i := 0
//writef("bm_mkmat => %n*n", mat)
  RESULTIS mat
}

AND bm_clrmat(a, b, c, d) BE
{ LET upb = matnw * matn - 1
  FOR i = 0 TO upb DO a!i, b!i, c!i, d!i := 0, 0, 0, 0
}

AND bm_setbitpp(i, j) BE
{ bm_setbit(mata, i, j)         //  vi ->  vj
  bm_setbit(matd, j, i)         // ~vj -> ~vi
//wrvars(); abort(1111)
//  UNLESS varinfo!i=1 | varinfo!j=1 DO
//    writef(" v%n -> v%n*n", origid(i), origid(j))
}

AND bm_setbitpn(i, j) BE
{ bm_setbit(matb, i, j)         //  vi -> ~vj
  bm_setbit(matb, j, i)         //  vj -> ~vi
//wrvars(); abort(1111)
//  UNLESS varinfo!i=0 | varinfo!j=0 DO
//    writef(" v%n ->~v%n*n", origid(i), origid(j))
}

AND bm_setbitnp(i, j) BE
{ bm_setbit(matc, i, j)         // ~vi ->  vj
  bm_setbit(matc, j, i)         // ~vj ->  vi
//wrvars(); abort(1111)
//  UNLESS varinfo!i=1 | varinfo!j=1 DO
//    writef("~v%n -> v%n*n", origid(i), origid(j))
}

AND bm_setbitnn(i, j) BE
{ bm_setbit(matd, i, j)         // ~vi -> ~vj
  bm_setbit(mata, j, i)         //  vj ->  vi
//wrvars(); abort(1111)
//  UNLESS varinfo!i=1 | varinfo!j=0 DO
//    writef("~v%n ->~v%n*n", origid(i), origid(j))
}

AND bm_setvar0(i) BE
{ //writef(" v%n = 0*n", origid(i))
  //varinfo!i := 0
  bm_setbit(matb, i, i)         //  vi -> ~vi
}

AND bm_setvar1(i) BE
{ //writef(" v%n = 1*n", origid(i))
  //varinfo!i := 1
  bm_setbit(matc, i, i)         // ~vi -> vi
}

AND bm_setvareq(i, j) BE
{ writef(" v%n = v%n*n", origid(i), origid(j))
  varinfo!i := 2*j
  bm_setbit(mata, i, j)         // vi -> vj
  bm_setbit(mata, j, i)         // vj -> vi
}

AND bm_setvarne(i, j) BE
{ //writef(" v%n = ~v%n*n", origid(i), origid(j))
  //varinfo!i := 2*j+1
  bm_setbit(matb, i, j)         // vi -> ~vj
  bm_setbit(matb, j, i)         // vj -> ~vi
}

AND bm_setbit(m, i, j) BE IF i DO
{ LET p = m + ((i-1)*matnw) + (j-1)/32 // Ptr to word containing bit
  AND bit = 1<<((j-1) & 31)
  !p := !p | bit                       // Set the bit
}

AND bm_warshall(a, b, c, d) BE
{ // Perform Warshall's algorithm on the 2n x 2n matrix:
  //     ( a b )
  //     ( c d )

  FOR k = 1 TO matn DO // Go down column k of matrices a and c
  { LET offk = (k-1)/32               // Word offset within a row
    LET bitk = 1 << ((k-1) REM 32)    // 
    LET rowka = a + (k-1)*matnw
    LET rowkb = b + (k-1)*matnw
    FOR i = 1 TO matn DO              // Inspect bits in col k of a
    { LET rowia = a + (i-1)*matnw
      LET rowib = b + (i-1)*matnw
      UNLESS (rowia!offk & bitk)=0 DO
      { // a[i,k]=1 so OR row k of (a b) into row i of (a b)
        //writef("ORing row %n of (a b) into row %n of (a b)*n", k, i) 
        FOR j = 0 TO matnw-1 DO
        { rowia!j := rowia!j | rowka!j
          rowib!j := rowib!j | rowkb!j
        }
      }
    }
    FOR i = 1 TO matn DO              // Inspect bits in col k of c
    { LET rowic = c + (i-1)*matnw
      LET rowid = d + (i-1)*matnw
      UNLESS (rowic!offk & bitk)=0 DO
      { // c[i,k]=1 so OR row k of (a b) into row i of (c d) 
        //writef("ORing row %n of (a b) into row %n of (c d)*n", k, i) 
        FOR j = 0 TO matnw-1 DO
        { rowic!j := rowic!j | rowka!j
          rowid!j := rowid!j | rowkb!j
        }
      }
    }
  }

  FOR k = 1 TO matn DO // Go down column k of matrices b and d
  { LET offk = (k-1)/32               // Word offset within a row
    LET bitk = 1 << ((k-1) REM 32)    // 
    LET rowkc = c + (k-1)*matnw
    LET rowkd = d + (k-1)*matnw
    FOR i = 1 TO matn DO              // Inspect bits in col k of b
    { LET rowia = a + (i-1)*matnw
      LET rowib = b + (i-1)*matnw
      UNLESS (rowib!offk & bitk)=0 DO
      { // b[i,k]=1 so OR row k of (c d) into row i of (a b) 
        //writef("ORing row %n of (c d) into row %n of (a b)*n", k, i) 
        FOR j = 0 TO matnw-1 DO
        { rowia!j := rowia!j | rowkc!j
          rowib!j := rowib!j | rowkd!j
        }
      }
    }
    FOR i = 1 TO matn DO              // Inspect bits in col k of d
    { LET rowic = c + (i-1)*matnw
      LET rowid = d + (i-1)*matnw
      UNLESS (rowid!offk & bitk)=0 DO
      { // d[i,k]=1 so OR row k of (c d) into row i of (c d) 
        //writef("ORing row %n of (c d) into row %n of (c d)*n", k, i) 
        FOR j = 0 TO matnw-1 DO
        { rowic!j := rowic!j | rowkc!j
          rowid!j := rowid!j | rowkd!j
        }
      }
    }
  }
}

AND bm_prmat(a, b, c, d) BE
{ FOR i = 1 TO matn DO
  { prmatrow(a, i)
    writef("  ")
    prmatrow(b, i)
    newline()
  }
  newline()
  FOR i = 1 TO matn DO
  { prmatrow(c, i)
    writef("  ")
    prmatrow(d, i)
    newline()
  }
}

AND prmatrow(m, i) BE FOR j = 1 TO matn DO
{ LET p   = m + (i-1)*matnw + (j-1)/32
  AND bit = 1 << (j-1) REM 32
  writef(" %c", (!p & bit) = 0 -> '.', '**')
}

AND bm_findnewinfo() BE
{ // First make the transitive closure
  bm_warshall(mata, matb, matc, matd)

//  FOR i = 1 TO maxid IF 0<=varinfo!i<=1 DO
//    writef("v%n=%n ", origid(i), varinfo!i)
//  newline()

  // For each i,
  // look for new information of the form vi=0 or vi=1
  // then new information of the form vi=vj or vi=~vj, i<j
  // then new information of the form vi->vj, vi->~vj, ~vi=vj or ~vi->~vj, i<j
 
  // Look for new ones in Bii and Cii
//  FOR i = 1 TO matn UNLESS 0<=varinfo!i<=1 DO
  FOR i = 1 TO matn DO
  { // vi not known to be 0 or 1
    LET row = (i-1)*matnw
    LET j, sh = (i-1)/32, (i-1) REM 32
    LET w = matbprev!(row+j) XOR matb!(row+j)

    // See if vi->~vi ie vi=0 is new info
    UNLESS ((w>>sh)&1)=0 DO
    { //writef("findnewinfo:  v%n = 0*n", origid(i))
      apvarset0(i)
    }
    w := matcprev!(row+j) XOR matc!(row+j)
    // See if ~vi->vi ie vi=1 is new info
    UNLESS ((w>>sh)&1)=0 DO
    { //writef("findnewinfo:  v%n = 1*n", origid(i))
      apvarset1(i)
    }
  }

  FOR i = 1 TO matn UNLESS 0<=varinfo!i<=1 DO
  { // Provided vi is not already known to be 0 or 1
    // look for any vj that is not already set to 0 or 1
    // for which vi=vj, vi=~vj,
    // vi->vj, vi->~vj,~vi->vj or ~vi->~vj is new information
    // preferring vi=vj, vi=~vj, if possible.

    LET row = (i-1)*matnw
    FOR r = 0 TO matnw-1 DO
    { LET k = row+r
      LET awold, awnew = mataprev!k, mata!k
      AND bwold, bwnew = matbprev!k, matb!k
      AND cwold, cwnew = matcprev!k, matc!k
      AND dwold, dwnew = matdprev!k, matd!k
      AND w = ?

      w := (awold XOR awnew) | (dwold XOR dwnew)

      // Each bit in w corresponds to either or both
      // Aij=1 or Dij=1 being new information implying that
      // one or more of: vi=vj, vi->vj and ~vi->~vj are new.

      IF w DO 
      { LET bit, j = 1, 1 + r*32
        LET wad = awnew & dwnew          // (A^D)ij =1 

        { // Iterate through the ones in w
          IF (w&bit)~=0 DO
          {  w := w - bit
            // One of vi=vj, vi->vj and/or ~vi->~vj is new
            UNLESS i>=j | 0<=varinfo!j<=1 DO
              // i<j and vj is not 0 or 1
              TEST (wad&bit)~=0
              THEN apvareq(i, j)         // (A^D)ij = 1 is new
              ELSE TEST ((awold XOR awnew)&bit)~=0
                   THEN apvarimppp(i, j) // Aij = 1 is new
                   ELSE apvarimpnn(i, j) // Dij = 1 is new
          }
          bit, j := bit<<1, j+1
        } REPEATWHILE w
      }

      w := (bwold XOR bwnew) | (cwold XOR cwnew) // Bij=1 or Cij=1 new

      // Each bit in w corresponds to either or both
      // Bij=1 or Cij=1 being new information implying that
      // one or more of: vi=~vj, vi->~vj and ~vi->vj are new.

      IF w DO 
      { LET bit, j = 1, 1 + r*32
        LET wbc = bwnew & cwnew          // (B^C)ij =1 

        { // Iterate through the ones in w
          IF (w&bit)~=0 DO
          { w := w - bit
            // One of vi=~vj, vi->~vj and/or ~vi->vj is new
            UNLESS i>=j | 0<=varinfo!j<=1 DO
              // i<j and vj is not 0 or 1
              TEST (wbc&bit)~=0
              THEN apvarne(i, j)         // (B^C)ij = 1 is new
              ELSE TEST ((bwold XOR cwnew)&bit)~=0
                   THEN apvarimppn(i, j) // Bij = 1 is new
                   ELSE apvarimpnp(i, j) // Cij = 1 is new
          }
          bit, j := bit<<1, j+1
        } REPEATWHILE w
      }
    }
  }

  // Remember the current state of the matrices
  FOR i = 0 TO matn-1 DO
  { LET row = i*matnw
     FOR k = row TO row+matnw-1 DO
     { mataprev!k := mata!k
       matbprev!k := matb!k
       matcprev!k := matc!k
       matdprev!k := matd!k
     }
   }
}

.

/*

This is the main recursive search engine of the tautology checker
based on the analysis of the conjunction of a set of relations over 3
Boolean variables.

Implemented in BCPL by Martin Richards (c) October 2005
*/

SECTION "engine"

GET "libhdr"
GET "chk3.h"

/*

explore(rv, n, vn, ma, mb, mc, md)

The function returns FALSE if the relations are inconsitent otherwise it
returns TRUE with the boolean matrices set with any information
about implications between pairs of variables.
The relations are in rv!1 to rv!n.
Variables identifiers are between 1 and vn.
The matrices are of size vn x vn

Algorithm:

save old mata,... matd, prevmata,.. prevmatd,
         refs, refcount, varval
etc

formlists
standardise all relations
put them all into the relation stack

(1) pop each relation from the stack and apply findimps to it
(2) Apply findnewinfo putting any relation that is changed onto
    the stack
If stack non empty goto (1)

(3) For each variable
    (3.1) If it is used only once eliminate it
    (3.2) If it is used exactly twice and the two relations
          can be combined, combine them and eliminate the variable
    (3.3) For each pair of relations sharing this variable and
          have >= 3 variables in common, let each restrict the other.
    Any relation changed by this process is put onto the stack.

If stack non empty goto (1)

(4) Combine any combinable relations preferring those with the
    greatest number of variables in common, putting the resulting
    relations on the stack.

If stack non empty goto (1)

(5) Split any relation that can be factorised into the conjunction
    of two relations over disjoint variables, puting the factors
    into the stack.

If stack non empty goto (1)

At this point no progress can be made by simple means so the problem
must split into sub problems.

(6) Choose a relations with the greatest influence and fewest ones
    in its relation bit pattern. Form two sub-problems by anding
    its bit pattern with a random bit pattern and its complement.
    Recursively call explore on these two sub problems. If neither
    is satisfiable the the original problem was not satisfiable.
    If just one is potentially satisfiable return its set of matrices.
    If both are potentially satisfiable return the intersection of its
    set of matrices.

(7) Apply findnewinfo putting any relation that is changed onto
    the stack

If stack non empty goto (1)

Either give up,
or arrange to recurse to a greater depth,
or do the recursion based on a different relation,
or split the relation into more mutually exclusive relations,
   possibly one for each of the <255 possible settings of its
   variables.
or split pairs, triple or more relations simultaneously.
*/

LET explore(rv, n, vval, vmax, ba, bb, bc, bd) = VALOF
{ 
  writef("explore entered*n")

  FOR i = 1 TO reln DO pushrel(relv!i)

  WHILE relstackp DO // Iterate through the contents of the stack
  { 
    // Eliminate any variables that are only used once
    FOR id = 1 TO maxid IF refcount!id=1 DO
    { LET rel = refs!id!1
//writef("eliminating v%n from relation %n*n", origid(id), rel!r_numb)
      ignorevar(rel, id)
      refs!id := 0
      refcount!id := 0
      varinfo!id := -2
    }

    writef("*nRelation Stack size %n:*n", relstackp)
    FOR i = 1 TO relstackp DO wrrel(relstack!i, TRUE)
    newline()
    abort(6666)

    WHILE relstackp DO // Iterate through the contents of the stack
    { LET rel = poprel()
      newline()
      wrrel(rel, TRUE)
      //newline()
      writef("cost of standardise is %n*n", instrcount(standardise, rel))
//abort(1111)
      newline()
      wrrel(rel, TRUE)
      writef("cost of findimps:  %i8*n", instrcount(findimps, rel))
    }

    writef("*n*nCalling bm_findnewinfo()*n*n")
    bm_findnewinfo()
    abort(1111)
  }

  RESULTIS FALSE
}

.

GET "libhdr"
GET "chk3.h"

LET bug(mess, a,b,c) BE
{ writef(mess, a, b, c)
  abort(999)
}

AND mk2(x, y) = VALOF
{ LET res = ?
//writef("mk2: x=%n y=%n*n", x,y)
  UNLESS freepairs DO
  { freepairs := getvec(4000)
    UNLESS freepairs DO
    { writef("out of space*n")
      abort(999)
      RESULTIS 0
    }
    !freepairs := pairblks
    pairblks := freepairs

    //writef("pair block %n allocated*n", pairblks)
    // Form free list of pairs
    res := pairblks+4000-1
    freepairs := 0
    UNTIL res<=pairblks DO
    { res!0, res!1 := freepairs, 0
      freepairs := res
      res := res-2
    }
  }
  res := freepairs
  freepairs := !freepairs
  res!0, res!1 := x, y
  RESULTIS res
}

AND unmk2(p) BE
{ !p := freepairs
  freepairs := p
}

LET rdrels(name) = VALOF
{ // Reads the specified file of relations. Each relation consists of 8
  // hex numbers for the 256-bit pattern followed by 8 non negative
  // integers specifying the variables.
  // The result is TRUE if successful, FALSE otherwise.
  // reln is set to the number of relations read
  // relv!1 to relv!reln pointer to the relation nodes.
  // The relation nodes are placed in relspace.
  LET res = FALSE
  LET p = 1 // The position in relspace of the next relation.
  LET oldin = input()
  LET data = findinput(name)
  LET value = ?

  reln := 0  // Number of relations read

  UNLESS data GOTO fin
  selectinput(data)
  ch := rdch()
  lex()

  UNTIL token=s_eof DO
  { LET rel = newrel()
    LET v, w = @rel!r_a0, @rel!r_w0
    UNLESS token=s_bits BREAK

    w!0 := lexval
    lex()

    FOR i = 1 TO 1 DO      // Read the bit pattern words
    { UNLESS token=s_bits BREAK
      w!i := lexval
      lex()
    }

    UNLESS token=s_var DO
    { writef("Bad relation data -- variable expected*n")
      BREAK
    }

    FOR i = 0 TO 2 DO      // Read the variable identifiers
    { UNLESS token=s_var BREAK
      v!i := lexval
      lex()
    }

    // Fill in the relation properties
    rel!r_instack := FALSE  // changed -- no
    rel!r_weight := 9999    // weight -- dummy value
    rel!r_varcount := 3     // varcount
    rel!r_numb := reln      // Relation number
  }

fin:
  IF data UNLESS data=oldin DO endread()
  selectinput(oldin)
  RESULTIS reln>0
}

AND newrel() = VALOF
// Allocate a blank relation
{ LET rel = @relspace!relspacep

  // Allocate a new relation
  relspacep := relspacep + r_upb + 1
  IF relspacep > relspaceupb DO
  { writef("Insufficient space*n")
    RESULTIS 0
  }
  reln := reln+1
  relv!reln := rel
  FOR i = 0 TO r_upb DO rel!i := 0
  RESULTIS rel
}

AND mkrel(bits, a, b, c) = VALOF
{ LET rel = newrel()
  rel!r_w0 := bits
  rel!r_a0 := a
  rel!r_a1 := b
  rel!r_a2 := c
  RESULTIS rel  
}

AND lex() BE
{ SWITCHON ch INTO
  { DEFAULT:  writef("Bad relation data, ch=%n '%c'*n", ch, ch)

    CASE endstreamch:
               token := s_eof
               RETURN

    CASE '*s':                              // White space
    CASE '*n': ch := rdch()
               LOOP

    CASE '#':                               // Comment
              ch := rdch() REPEATUNTIL ch='*n' | ch=endstreamch
              LOOP

    CASE 'v':                               // A variable
    CASE 'V': ch := rdch()
              lexval := rdnum()
              token := s_var
              RETURN

    CASE '0':CASE '1':                      // Relation bit pattern
              lexval := rdbin()
              token := s_bits
              RETURN
  }
} REPEAT


// Read a relation bit pattern
AND rdbin() = VALOF
{ LET res = 0

  WHILE '0'<=ch<='1' DO
  { res := (res<<1) + ch - '0'
    ch := rdch()
  }

  RESULTIS res
}

// Read a decimal number
AND rdnum() = VALOF
{ LET res = 0

  { LET dig = -1
    IF '0'<=ch<='9' DO dig := ch - '0'
    IF dig<0 BREAK
    res := res*10 + dig
    ch := rdch()
  } REPEAT

  RESULTIS res
} REPEAT

// Write out all the relations
AND wrrels(verbose) BE
{ FOR i = 1 TO reln DO wrrel(relv!i, verbose)
  newline()
}

// Write out a particular relation
AND wrrel(rel, verbose) BE
{ LET upb = 2

  IF FALSE DO
  { writes("*na2  ")
    FOR i = 0 TO upb DO writef("10101010 ")
    newline()
  }

  IF verbose DO writef("%i2: ", rel!r_numb)

  writef("%b8 ", rel!r_w0)

  upb := 2
  WHILE upb>0 DO
  { IF rel!(r_a0+upb) BREAK
    upb := upb-1
  }

  FOR i = r_a0 TO r_a0+upb DO writef("v%n ",  origid(rel!i))

  IF tracing DO writef(" S:%n W:%n N:%n",
                        rel!r_instack,  rel!r_weight, rel!r_varcount)
  newline()
}

AND wrvars() BE
{ // varinfo!i holds information about new variable Vi
  // = -2     means the variable is not used in any relation
  // = -1     means the variable is used in exactly one relation
  // = 0      means the variable is known to have value 0
  // = 1      means the variable is known to have value 1
  // = 2j     means Vi =  Vj, 0<j<i
  // = 2j+1   means Vi = ~Vj, 0<j<i

  FOR id = 1 TO maxid DO
  { LET rl, count = refs!id, refcount!id
    LET info = varinfo!id
    LET i = info/2
    writef("v%n: ", origid(id))
    SWITCHON info INTO
    { DEFAULT:  IF info>0 DO
                { writef("%cv%n ", info REM 2 -> '~', ' ', origid(info/2))
                  ENDCASE
                }
                writef("???? "); ENDCASE
      CASE -2:  writef("X    "); ENDCASE
      CASE -1:  writef("     "); ENDCASE
      CASE  0:  writef("0    "); ENDCASE
      CASE  1:  writef("1    "); ENDCASE
    }
    WHILE rl DO
    { writef("  %i3", rl!1!r_numb)
      rl := !rl
    }
    newline()
  }
}

AND origid(id) = VALOF
{ LET tab = id2orig
  WHILE tab DO
  { id := tab!id
    tab := !tab
  }
  RESULTIS id
}

// formlists allocates and initialises the following vectors from
// the given set of relations.

// refs        refs!id is the list of relations using id
// refcount    refcount!id hold the number of uses of each new id
// id2orig     a vector mapping new ids to old ids
// varinfo     a vector holding information about each new ids

// It also allocates and clears mata,..,matd and mataprev,...,matdprev

AND formlists(rv, n) BE // rv!1 to rv!n are the given relations
{ LET maxoldid, old2new = 0, 0

  // Find maxoldid
  FOR i = 1 TO n DO
  { LET rel = rv!i
    LET v = @rel!r_a0
    FOR j = 0 TO 2 DO
    { LET id = v!j  // Look at every variable used by every relation
      IF maxoldid<id DO maxoldid := id  // Maximum old identifier
    }
  }
  writef("Maximum old variable number = %n*n", maxoldid)

  old2new := getvec(maxoldid)

  UNLESS old2new DO
  { writef("More space needed for old2new*n")
    abort(999)
    GOTO fin
  }
  // Re-number the variables keeping them in the same order.

  // Mark all variables that have been used
  FOR id = 0 TO maxoldid DO old2new!id := 0
  FOR r = 1 TO n DO // Look at every relation
  { LET rel = rv!r
    LET v = @rel!r_a0
    FOR arg = 0 TO 2 DO // Look at every relation argument
    { LET id = v!arg
      IF id DO old2new!id := -1 // This old id has been used
    }
  }

  // Allocate new variable numbers, filling in the old2new table entries
  // and calculating maxid (the maximum new variable number).
  maxid := 0
  old2new!0 := 0 // Identifier 0 always maps to zero
  FOR id = 1 TO maxoldid IF old2new!id DO
  { maxid := maxid+1
    old2new!id := maxid
  }

  writef("Maximum new variable number = %n*n", maxid)

  // Allocate the refs vector and others
  refs     := getvec(maxid)
  refcount := getvec(maxid)
  id2orig  := getvec(maxid)
  varinfo  := getvec(maxid)

  UNLESS refs & refcount & id2orig & varinfo DO
  { writef("More space needed*n")
    abort(999)
    GOTO fin
  }

  FOR id = 0 TO maxid DO
  { id2orig!id  := 0    // Later set to the original variable number
    varinfo!id  := -1   // Nothing known
    refs!id     := 0    // List of relation containing this variable
    refcount!id := 0    // The length of refs!id
  }

  // Construct the refs lists
  FOR r = 1 TO n DO // Look at every relation
  { LET rel = rv!r
    LET v = @rel!r_a0
    FOR arg = 0 TO 2 DO // Look at every relation argument
    { LET id = v!arg    // Look at every variable used in the relation
      IF id DO
      { LET newid = old2new!id
        v!arg := newid       // Renumber the variable in the relation
        id2orig!newid := id  // Remember the mapping
        refs!newid := mk2(refs!newid, rel) // add to refs list
        refcount!newid := refcount!newid + 1 // Increment its ref count
      }
    }
  }

  setweights()

  // Allocate the boolean matrices

  bm_setmatsize(maxid<32 -> 32, maxid)

  mata     := bm_mkmat()
  matb     := bm_mkmat()
  matc     := bm_mkmat()
  matd     := bm_mkmat()

  mataprev := bm_mkmat()
  matbprev := bm_mkmat()
  matcprev := bm_mkmat()
  matdprev := bm_mkmat()

fin:
  IF old2new  DO freevec(old2new)
}

AND length(p) = VALOF
{ LET res = 0
  WHILE p DO res, p := res+1, !p
  RESULTIS res
}

AND sortpairs(v, w, upb) BE  // (v!i,w!i) is the key for item i
{ LET m = 1
  UNTIL m>upb DO m := m*3 + 1  // Find first suitable value in the
                               // series:  1, 4, 13, 40, 121, 364, ...
  { m := m/3
    FOR i = m+1 TO upb DO
    { LET vi, wi = v!i, w!i
      LET j = i
      { LET k = j - m
        IF k<=0 | v!k < vi | v!k=vi & w!k<wi BREAK
        v!j, w!j := v!k, w!k
        j := k
      } REPEAT
      v!j, w!j := vi, wi
    }
  } REPEATUNTIL m=1
}

AND prpairs(v, w, upb) BE FOR i = 1 TO upb DO
  writef("%i3:  %i4  %i4*n", i, v!i, w!i)

AND setweights() BE FOR r = 1 TO reln IF relv!r DO
{ LET rel = relv!r
  LET v = @rel!r_a0
  LET weight, count = 0, 0
  FOR arg = 0 TO 2 DO
  { LET id = v!arg
    UNLESS id LOOP
    count := count + 1
    weight := weight + refcount!id
  }
  rel!r_varcount := count
  rel!r_weight   := weight
}

AND pushrel(r) BE UNLESS r!r_instack DO
{ // Push a relation onto the stack if it is not already there
  // because the relation has changed and must be inspected.
  r!r_instack := TRUE
  IF relstackp>=relstackupb DO
  { writef("relstack too small*n")
    abort(999)
    RETURN
  }
  relstackp := relstackp + 1
  relstack!relstackp := r

  //newline()
  //wrrel(r, TRUE)
  //writef("pushrel:  ")
  //FOR i = 1 TO relstackp DO writef(" %n", relstack!i!r_numb)
  //newline()
//abort(4444)
}

AND poprel() = VALOF
{ // Pop a relation from the stack, returning 0 if the stack is empty
  LET rel = relstack!relstackp
  UNLESS relstackp RESULTIS 0
  rel!r_instack := FALSE

  //writef("*npoprel:   ")
  //FOR i = 1 TO relstackp DO writef(" %n", relstack!i!r_numb)
  //newline()
//wrrel(rel, TRUE)
//abort(4444)
  relstackp := relstackp -1
  RESULTIS rel
}

// Unlink one reference to rel in refs!id
AND rmref(rel, id) BE
{ LET a = @refs!id
  //wrrel(rel, TRUE)
  //writef("rmref: rel %n v%n*n", rel!r_numb, id)
//abort(5555)
  WHILE !a DO
  { LET rl = !a
    LET next = !rl
    IF rl!1=rel DO
    { // Reference to rel found
      !a, refcount!id := next, refcount!id -1 
      RETURN
    }
    rl := !next
  }
  writef("rmrel: relation not found, numb=%n v%n*n", rel!r_numb, id)
  abort(999)
}

.

/*
This module contains debugging aids to test various  functions
in the a tautology checker.

Implemented in BCPL by Martin Richards (c) October 2005
*/

SECTION "debug"

GET "libhdr"
GET "chk3.h"

LET selfcheck(debug) BE SWITCHON debug INTO
{ DEFAULT: writef("Unknown self check number: %n*n", debug)
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
    LET v, w = @rel!r_a0, @rel!r_w0
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
    FOR i = 0 TO 2 DO r!(r_a0+i) := 20+i
    //wrrel(r); newline()
    //standardise(r)
    //wrrel(r); newline()
    //wrrel(r); newline()
  }
}

AND check5() BE
{ LET rel = relv!1
  LET v, w = @rel!r_a0, @rel!r_w0
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
  LET v = @rel!r_a0
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
    //rel1!(r_a0+i) := i+1             // 1..8
    rel1!(r_a0+i) := randno(9) - 1 // 0..8 random
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

AND evalrel(r, z, a, b, c) = VALOF
{ // Evaluate relation r assuming v0, v1, v2 and v3 have values z, a, b and c.
  LET v   = @r!r_a0
  LET env = @z
  LET s   = v!2!env*4 + v!1!env*2 + v!0!env
  LET res = r!r_w0>>s & 1
  //writef("evalrel: %b8 v1=%n v2=%n v3=%n s=%n => %n*n", r!r_w0, a, b, c, s, res)
//abort(1111)
  RESULTIS res
}

AND checkeqv(rel1, rel2) BE
  FOR a = 0 TO 1 DO
    FOR b = 0 TO 1 DO
      FOR c = 0 TO 1 DO
        UNLESS evalrel(rel1, 0, a, b, c)=evalrel(rel2, 0, a, b, c) DO
        { writef("abc=%n%n%n rel1=>%n rel2=>%n*n",
                  a,b,c,
                  evalrel(rel1, 0, a, b, c), evalrel(rel2, 0, a, b, c))
          wrrel(rel1, FALSE)
          wrrel(rel2, FALSE)
          newline()
          abort(999)
        }

AND testallvars(f) BE
// Call f(a, b, c) all a, b, c in range 0 to 3
  FOR a = 0 TO 3 FOR b = 0 TO 3 FOR c = 0 TO 3 DO f(a, b, c)

AND selftest() BE
{ // Call all the selftest functions
  writef("*nSelf Testing*n")
  //testtrans1()
  //testapfns()
  //testapvar()
  testfindimps()
  writef("*nAll self testing done*n")
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

