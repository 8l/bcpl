/*
This is a tautology checker based on the analysis of the
conjunction of a set of relations over 8 Boolean variables.

Implemented in BCPL by Martin Richards (c) May 2006
*/

SECTION "chk8"

GET "libhdr"
GET "chk8.h"

LET start() = VALOF
{ // Set the default data file name
  //LET name = "data/a.rel"
  //LET name = "data/tst2.rel"
  //LET name = "data/greaves.rel"
  //LET name = "data/mul4.rel"
  LET name = "data/m4.rel"
  LET res, res2 = 0, 0
  LET argv = VEC 50

  UNLESS rdargs("DATA,CHECK/K,-t/s", argv, 50) DO
  { writef("Bad arguments for chk8*n")
    RESULTIS 20
  }

  IF argv!0 DO name := argv!0             // DATA

  TEST argv!1 & string.to.number(argv!1)  // CHECK
  THEN checkno := result2
  ELSE checkno := 0

  tracing := argv!2                       // -t

  imptab := 0

  idvecs   := 0
  idcountv := 0
  id2prev  := 0   // Mapping from current ids to original ids
  varinfo  := 0   //

  rellist  := 0    // List of relations that have recently changed

  mat      := 0
  matprev  := 0

  spacev   := getvec(spaceupb)
  spacet   := spacev+spaceupb
  spacep   := spacev

  relv     := 0    // Will be a vector of pointers to relation nodes

  UNLESS spacev DO
  { writef("More memory needed*n")
    GOTO fin
  }

  setimptab()

  IF checkno DO
  { sawritef("Calling selfcheck(%n)*n", checkno)
    selfcheck(checkno) // Defined in debug.b
    GOTO fin
  }

  writef("chk8: processing file %s*n", name)

  // Read the relations
  { LET p = rdrels(name)  // The list of relation nodes
    LET n = 0             // To hold the number of relations

    UNLESS p DO
    { writef("Format of file %s wrong*n", name)
      GOTO fin
    }

    // Allocate the vector relv.
    relv := spacep

    WHILE p DO
    { n := n+1
      spacep := spacep+1 // Allocate relv!n
      relv!n := p
      p!r_relno := n
      p := r_link!p
    }
    relv!0 := n         // UPB of relv
    relcount := n       // Count of non-deleted relations
    spacep := relv+n+1  // Allocate n+1 words for relv
  }

  //writef("The given set of relations are:*n")

  //wrrels(relv, TRUE)
  
  // relv!0 (=n) is the number of relations.
  // relv!1 .. relv!n are the pointers to the relation nodes

  // Rename the identifiers in the given set of relations and
  // replace id2prev by the new version.

  maxid := renameidentifiers(relv)
  // maxid is the largest identifier number now used.

  //writef("maxid=%n*n", maxid)
  //writef("After renaming the identifiers they are:*n")
  //wrrels(relv, TRUE)
  //wrvars()
  //newline()

  mat     := bm_mk(maxid)
  matprev := bm_mk(maxid)

  //writef("maxid = %n*n", maxid)
//writef("relv=%n idcountv=%n id2prev=%n varinfo=%n idvecs=%n*n",
//        relv,   idcountv,   id2prev,   varinfo,   idvecs)
//writef("mat=%n matprev=%n spacep=%n*n",
//        mat,   matprev,   spacep)

  // Start of algorithm

  FOR md = 0 TO 0 DO
  { maxdepth := md       // Set the current maximum depth

//    writef("Calling explore(0) with reln=%n maxdepth=%n*n", relv!0, maxdepth)

//    // Allocate an empty stack
//    stackv := spacep
//    stackp := 0
//    stackt := spacet-stackv

    // Push all the current relations onto the stack
    rellist := 0
    FOR relno = relv!0 TO 1 BY -1 DO pushrel(relv!relno)

    // Explore the current set of relations
    result2 := 0
    res  := explore(0)
    res2 := result2

    IF res BREAK

    writef("The answer could not be determined with maxdepth=%n*n",
            maxdepth)
  }

  TEST res
  THEN writef("*nThe relations are %ssatisfiable*n",
               result2 -> "", "not ")
  ELSE writef("*nUnable to determine the answer using maxdepth=%n*n",
               maxdepth)

  writef("The final set of relations are:*n")

  wrrels(relv, TRUE)
  wrvars()

fin:
  IF spacev   DO freevec(spacev)
  IF imptab   DO freevec(imptab)

  RESULTIS 0
}

.

// Transformations on a single relation

// exchargs(rel, i, j)     exchange the positions of arguments i and j
// ignorearg(rel, i)       remove arg i, assuming it is unconstrained
// isunconstrained(rel, i) returns TRUE if the relation places no
//                         constraint on arg i
// standardise(rel)        sort arguments and remove duplicates

// split(rel)              split rel into two if possible

SECTION "trans1"

GET "libhdr"
GET "chk8.h"

// Exchange arguments i and j in a relation
LET exchargs(rel, argi, argj) BE
// Assume i and j are in the range 0..7
{ LET w0, w1, w2, w3 = rel!r_w0, rel!r_w1, rel!r_w2, rel!r_w3
  LET w4, w5, w6, w7 = rel!r_w4, rel!r_w5, rel!r_w6, rel!r_w7
  LET v = @rel!r_a
  LET t = v!argi
//newline()
//wrrel(rel)
//writef("exchargs: args %n %n*n", argi, argj)
  v!argi := v!argj    // Swap variable identifiers
  v!argj := t

  // Adjust the bit pattern
  SWITCHON argi*8 + argj INTO
  { DEFAULT:
      ENDCASE  // Either i=j or an error
    CASE #76: CASE #67:
      rel!r_w2, rel!r_w3, rel!r_w4, rel!r_w5 := w4, w5, w2, w3
      ENDCASE
    CASE #75: CASE #57:
      rel!r_w1, rel!r_w3, rel!r_w4, rel!r_w6 := w4, w6, w1, w3
      ENDCASE
    CASE #74: CASE #47:
      rel!r_w0 := w0&#x0000FFFF | w4<<16
      rel!r_w1 := w1&#x0000FFFF | w5<<16
      rel!r_w2 := w2&#x0000FFFF | w6<<16
      rel!r_w3 := w3&#x0000FFFF | w7<<16
      rel!r_w4 := w4&#xFFFF0000 | w0>>16
      rel!r_w5 := w5&#xFFFF0000 | w1>>16
      rel!r_w6 := w6&#xFFFF0000 | w2>>16
      rel!r_w7 := w7&#xFFFF0000 | w3>>16
      ENDCASE
    CASE #73: CASE #37:
      rel!r_w0 := w0&#x00FF00FF | w4<<8 & #xFF00FF00
      rel!r_w1 := w1&#x00FF00FF | w5<<8 & #xFF00FF00
      rel!r_w2 := w2&#x00FF00FF | w6<<8 & #xFF00FF00
      rel!r_w3 := w3&#x00FF00FF | w7<<8 & #xFF00FF00
      rel!r_w4 := w4&#xFF00FF00 | w0>>8 & #x00FF00FF
      rel!r_w5 := w5&#xFF00FF00 | w1>>8 & #x00FF00FF
      rel!r_w6 := w6&#xFF00FF00 | w2>>8 & #x00FF00FF
      rel!r_w7 := w7&#xFF00FF00 | w3>>8 & #x00FF00FF
      ENDCASE
    CASE #72: CASE #27:
      rel!r_w0 := w0&#x0F0F0F0F | w4<<4 & #xF0F0F0F0
      rel!r_w1 := w1&#x0F0F0F0F | w5<<4 & #xF0F0F0F0
      rel!r_w2 := w2&#x0F0F0F0F | w6<<4 & #xF0F0F0F0
      rel!r_w3 := w3&#x0F0F0F0F | w7<<4 & #xF0F0F0F0
      rel!r_w4 := w4&#xF0F0F0F0 | w0>>4 & #x0F0F0F0F
      rel!r_w5 := w5&#xF0F0F0F0 | w1>>4 & #x0F0F0F0F
      rel!r_w6 := w6&#xF0F0F0F0 | w2>>4 & #x0F0F0F0F
      rel!r_w7 := w7&#xF0F0F0F0 | w3>>4 & #x0F0F0F0F
      ENDCASE
    CASE #71: CASE #17:
      rel!r_w0 := w0&#x33333333 | w4<<2 & #xCCCCCCCC
      rel!r_w1 := w1&#x33333333 | w5<<2 & #xCCCCCCCC
      rel!r_w2 := w2&#x33333333 | w6<<2 & #xCCCCCCCC
      rel!r_w3 := w3&#x33333333 | w7<<2 & #xCCCCCCCC
      rel!r_w4 := w4&#xCCCCCCCC | w0>>2 & #x33333333
      rel!r_w5 := w5&#xCCCCCCCC | w1>>2 & #x33333333
      rel!r_w6 := w6&#xCCCCCCCC | w2>>2 & #x33333333
      rel!r_w7 := w7&#xCCCCCCCC | w3>>2 & #x33333333
      ENDCASE
    CASE #70: CASE #07:
      rel!r_w0 := w0&#x55555555 | w4<<1 & #xAAAAAAAA
      rel!r_w1 := w1&#x55555555 | w5<<1 & #xAAAAAAAA
      rel!r_w2 := w2&#x55555555 | w6<<1 & #xAAAAAAAA
      rel!r_w3 := w3&#x55555555 | w7<<1 & #xAAAAAAAA
      rel!r_w4 := w4&#xAAAAAAAA | w0>>1 & #x55555555
      rel!r_w5 := w5&#xAAAAAAAA | w1>>1 & #x55555555
      rel!r_w6 := w6&#xAAAAAAAA | w2>>1 & #x55555555
      rel!r_w7 := w7&#xAAAAAAAA | w3>>1 & #x55555555
      ENDCASE
    CASE #65: CASE #56:
      rel!r_w1, rel!r_w2, rel!r_w5, rel!r_w6 := w2, w1, w6, w5
      ENDCASE
    CASE #64: CASE #46:
      rel!r_w0 := w0&#x0000FFFF | w2<<16
      rel!r_w1 := w1&#x0000FFFF | w3<<16
      rel!r_w2 := w2&#xFFFF0000 | w0>>16
      rel!r_w3 := w3&#xFFFF0000 | w1>>16
      rel!r_w4 := w4&#x0000FFFF | w6<<16
      rel!r_w5 := w5&#x0000FFFF | w7<<16
      rel!r_w6 := w6&#xFFFF0000 | w4>>16
      rel!r_w7 := w7&#xFFFF0000 | w5>>16
      ENDCASE
    CASE #63: CASE #36:
      rel!r_w0 := w0&#x00FF00FF | w2<<8 & #xFF00FF00
      rel!r_w1 := w1&#x00FF00FF | w3<<8 & #xFF00FF00
      rel!r_w2 := w2&#xFF00FF00 | w0>>8 & #x00FF00FF
      rel!r_w3 := w3&#xFF00FF00 | w1>>8 & #x00FF00FF
      rel!r_w4 := w4&#x00FF00FF | w6<<8 & #xFF00FF00
      rel!r_w5 := w5&#x00FF00FF | w7<<8 & #xFF00FF00
      rel!r_w6 := w6&#xFF00FF00 | w4>>8 & #x00FF00FF
      rel!r_w7 := w7&#xFF00FF00 | w5>>8 & #x00FF00FF
      ENDCASE
    CASE #62: CASE #26:
      rel!r_w0 := w0&#x0F0F0F0F | w2<<4 & #xF0F0F0F0
      rel!r_w1 := w1&#x0F0F0F0F | w3<<4 & #xF0F0F0F0
      rel!r_w2 := w2&#xF0F0F0F0 | w0>>4 & #x0F0F0F0F
      rel!r_w3 := w3&#xF0F0F0F0 | w1>>4 & #x0F0F0F0F
      rel!r_w4 := w4&#x0F0F0F0F | w6<<4 & #xF0F0F0F0
      rel!r_w5 := w5&#x0F0F0F0F | w7<<4 & #xF0F0F0F0
      rel!r_w6 := w6&#xF0F0F0F0 | w4>>4 & #x0F0F0F0F
      rel!r_w7 := w7&#xF0F0F0F0 | w5>>4 & #x0F0F0F0F
      ENDCASE
    CASE #61: CASE #16:
      rel!r_w0 := w0&#x33333333 | w2<<2 & #xCCCCCCCC
      rel!r_w1 := w1&#x33333333 | w3<<2 & #xCCCCCCCC
      rel!r_w2 := w2&#xCCCCCCCC | w0>>2 & #x33333333
      rel!r_w3 := w3&#xCCCCCCCC | w1>>2 & #x33333333
      rel!r_w4 := w4&#x33333333 | w6<<2 & #xCCCCCCCC
      rel!r_w5 := w5&#x33333333 | w7<<2 & #xCCCCCCCC
      rel!r_w6 := w6&#xCCCCCCCC | w4>>2 & #x33333333
      rel!r_w7 := w7&#xCCCCCCCC | w5>>2 & #x33333333
      ENDCASE
    CASE #60: CASE #06:
      rel!r_w0 := w0&#x55555555 | w2<<1 & #xAAAAAAAA
      rel!r_w1 := w1&#x55555555 | w3<<1 & #xAAAAAAAA
      rel!r_w2 := w2&#xAAAAAAAA | w0>>1 & #x55555555
      rel!r_w3 := w3&#xAAAAAAAA | w1>>1 & #x55555555
      rel!r_w4 := w4&#x55555555 | w6<<1 & #xAAAAAAAA
      rel!r_w5 := w5&#x55555555 | w7<<1 & #xAAAAAAAA
      rel!r_w6 := w6&#xAAAAAAAA | w4>>1 & #x55555555
      rel!r_w7 := w7&#xAAAAAAAA | w5>>1 & #x55555555
      ENDCASE
    CASE #54: CASE #45:
      rel!r_w0 := w0&#x0000FFFF | w1<<16
      rel!r_w2 := w2&#x0000FFFF | w3<<16
      rel!r_w4 := w4&#x0000FFFF | w5<<16
      rel!r_w6 := w6&#x0000FFFF | w7<<16
      rel!r_w1 := w1&#xFFFF0000 | w0>>16
      rel!r_w3 := w3&#xFFFF0000 | w2>>16
      rel!r_w5 := w5&#xFFFF0000 | w4>>16
      rel!r_w7 := w7&#xFFFF0000 | w6>>16
      ENDCASE
    CASE #53: CASE #35:
      rel!r_w0 := w0&#x00FF00FF | w1<<8 & #xFF00FF00
      rel!r_w1 := w1&#xFF00FF00 | w0>>8 & #x00FF00FF
      rel!r_w2 := w2&#x00FF00FF | w3<<8 & #xFF00FF00
      rel!r_w3 := w3&#xFF00FF00 | w2>>8 & #x00FF00FF
      rel!r_w4 := w4&#x00FF00FF | w5<<8 & #xFF00FF00
      rel!r_w5 := w5&#xFF00FF00 | w4>>8 & #x00FF00FF
      rel!r_w6 := w6&#x00FF00FF | w7<<8 & #xFF00FF00
      rel!r_w7 := w7&#xFF00FF00 | w6>>8 & #x00FF00FF
      ENDCASE
    CASE #52: CASE #25:
      rel!r_w0 := w0&#x0F0F0F0F | w1<<4 & #xF0F0F0F0
      rel!r_w1 := w1&#xF0F0F0F0 | w0>>4 & #x0F0F0F0F
      rel!r_w2 := w2&#x0F0F0F0F | w3<<4 & #xF0F0F0F0
      rel!r_w3 := w3&#xF0F0F0F0 | w2>>4 & #x0F0F0F0F
      rel!r_w4 := w4&#x0F0F0F0F | w5<<4 & #xF0F0F0F0
      rel!r_w5 := w5&#xF0F0F0F0 | w4>>4 & #x0F0F0F0F
      rel!r_w6 := w6&#x0F0F0F0F | w7<<4 & #xF0F0F0F0
      rel!r_w7 := w7&#xF0F0F0F0 | w6>>4 & #x0F0F0F0F
      ENDCASE
    CASE #51: CASE #15:
      rel!r_w0 := w0&#x33333333 | w1<<2 & #xCCCCCCCC
      rel!r_w1 := w1&#xCCCCCCCC | w0>>2 & #x33333333
      rel!r_w2 := w2&#x33333333 | w3<<2 & #xCCCCCCCC
      rel!r_w3 := w3&#xCCCCCCCC | w2>>2 & #x33333333
      rel!r_w4 := w4&#x33333333 | w5<<2 & #xCCCCCCCC
      rel!r_w5 := w5&#xCCCCCCCC | w4>>2 & #x33333333
      rel!r_w6 := w6&#x33333333 | w7<<2 & #xCCCCCCCC
      rel!r_w7 := w7&#xCCCCCCCC | w6>>2 & #x33333333
      ENDCASE
    CASE #50: CASE #05:
      rel!r_w0 := w0&#x55555555 | w1<<1 & #xAAAAAAAA
      rel!r_w1 := w1&#xAAAAAAAA | w0>>1 & #x55555555
      rel!r_w2 := w2&#x55555555 | w3<<1 & #xAAAAAAAA
      rel!r_w3 := w3&#xAAAAAAAA | w2>>1 & #x55555555
      rel!r_w4 := w4&#x55555555 | w5<<1 & #xAAAAAAAA
      rel!r_w5 := w5&#xAAAAAAAA | w4>>1 & #x55555555
      rel!r_w6 := w6&#x55555555 | w7<<1 & #xAAAAAAAA
      rel!r_w7 := w7&#xAAAAAAAA | w6>>1 & #x55555555
      ENDCASE
    CASE #43: CASE #34:
      rel!r_w0 := w0&#xFF0000FF | w0<<8 & #x00FF0000 | w0>>8 & #x0000FF00
      rel!r_w1 := w1&#xFF0000FF | w1<<8 & #x00FF0000 | w1>>8 & #x0000FF00
      rel!r_w2 := w2&#xFF0000FF | w2<<8 & #x00FF0000 | w2>>8 & #x0000FF00
      rel!r_w3 := w3&#xFF0000FF | w3<<8 & #x00FF0000 | w3>>8 & #x0000FF00
      rel!r_w4 := w4&#xFF0000FF | w4<<8 & #x00FF0000 | w4>>8 & #x0000FF00
      rel!r_w5 := w5&#xFF0000FF | w5<<8 & #x00FF0000 | w5>>8 & #x0000FF00
      rel!r_w6 := w6&#xFF0000FF | w6<<8 & #x00FF0000 | w6>>8 & #x0000FF00
      rel!r_w7 := w7&#xFF0000FF | w7<<8 & #x00FF0000 | w7>>8 & #x0000FF00
      ENDCASE
    CASE #42: CASE #24:
      rel!r_w0 := w0&#xF0F00F0F | w0<<12 & #x0F0F0000 | w0>>12 & #x0000F0F0
      rel!r_w1 := w1&#xF0F00F0F | w1<<12 & #x0F0F0000 | w1>>12 & #x0000F0F0
      rel!r_w2 := w2&#xF0F00F0F | w2<<12 & #x0F0F0000 | w2>>12 & #x0000F0F0
      rel!r_w3 := w3&#xF0F00F0F | w3<<12 & #x0F0F0000 | w3>>12 & #x0000F0F0
      rel!r_w4 := w4&#xF0F00F0F | w4<<12 & #x0F0F0000 | w4>>12 & #x0000F0F0
      rel!r_w5 := w5&#xF0F00F0F | w5<<12 & #x0F0F0000 | w5>>12 & #x0000F0F0
      rel!r_w6 := w6&#xF0F00F0F | w6<<12 & #x0F0F0000 | w6>>12 & #x0000F0F0
      rel!r_w7 := w7&#xF0F00F0F | w7<<12 & #x0F0F0000 | w7>>12 & #x0000F0F0
      ENDCASE
    CASE #41: CASE #14:
      rel!r_w0 := w0&#xCCCC3333 | w0<<14 & #x33330000 | w0>>14 & #x0000CCCC
      rel!r_w1 := w1&#xCCCC3333 | w1<<14 & #x33330000 | w1>>14 & #x0000CCCC
      rel!r_w2 := w2&#xCCCC3333 | w2<<14 & #x33330000 | w2>>14 & #x0000CCCC
      rel!r_w3 := w3&#xCCCC3333 | w3<<14 & #x33330000 | w3>>14 & #x0000CCCC
      rel!r_w4 := w4&#xCCCC3333 | w4<<14 & #x33330000 | w4>>14 & #x0000CCCC
      rel!r_w5 := w5&#xCCCC3333 | w5<<14 & #x33330000 | w5>>14 & #x0000CCCC
      rel!r_w6 := w6&#xCCCC3333 | w6<<14 & #x33330000 | w6>>14 & #x0000CCCC
      rel!r_w7 := w7&#xCCCC3333 | w7<<14 & #x33330000 | w7>>14 & #x0000CCCC
      ENDCASE
    CASE #40: CASE #04:
      rel!r_w0 := w0&#xAAAA5555 | w0<<15 & #x55550000 | w0>>15 & #x0000AAAA
      rel!r_w1 := w1&#xAAAA5555 | w1<<15 & #x55550000 | w1>>15 & #x0000AAAA
      rel!r_w2 := w2&#xAAAA5555 | w2<<15 & #x55550000 | w2>>15 & #x0000AAAA
      rel!r_w3 := w3&#xAAAA5555 | w3<<15 & #x55550000 | w3>>15 & #x0000AAAA
      rel!r_w4 := w4&#xAAAA5555 | w4<<15 & #x55550000 | w4>>15 & #x0000AAAA
      rel!r_w5 := w5&#xAAAA5555 | w5<<15 & #x55550000 | w5>>15 & #x0000AAAA
      rel!r_w6 := w6&#xAAAA5555 | w6<<15 & #x55550000 | w6>>15 & #x0000AAAA
      rel!r_w7 := w7&#xAAAA5555 | w7<<15 & #x55550000 | w7>>15 & #x0000AAAA
      RETURN
      ENDCASE
    CASE #32: CASE #23:
      rel!r_w0 := w0&#xF00FF00F | w0<<4 & #x0F000F00 | w0>>4 & #x00F000F0
      rel!r_w1 := w1&#xF00FF00F | w1<<4 & #x0F000F00 | w1>>4 & #x00F000F0
      rel!r_w2 := w2&#xF00FF00F | w2<<4 & #x0F000F00 | w2>>4 & #x00F000F0
      rel!r_w3 := w3&#xF00FF00F | w3<<4 & #x0F000F00 | w3>>4 & #x00F000F0
      rel!r_w4 := w4&#xF00FF00F | w4<<4 & #x0F000F00 | w4>>4 & #x00F000F0
      rel!r_w5 := w5&#xF00FF00F | w5<<4 & #x0F000F00 | w5>>4 & #x00F000F0
      rel!r_w6 := w6&#xF00FF00F | w6<<4 & #x0F000F00 | w6>>4 & #x00F000F0
      rel!r_w7 := w7&#xF00FF00F | w7<<4 & #x0F000F00 | w7>>4 & #x00F000F0
      RETURN
      ENDCASE
    CASE #31: CASE #13:
      rel!r_w0 := w0&#xCC33CC33 | w0<<6 & #x33003300 | w0>>6 & #x00CC00CC
      rel!r_w1 := w1&#xCC33CC33 | w1<<6 & #x33003300 | w1>>6 & #x00CC00CC
      rel!r_w2 := w2&#xCC33CC33 | w2<<6 & #x33003300 | w2>>6 & #x00CC00CC
      rel!r_w3 := w3&#xCC33CC33 | w3<<6 & #x33003300 | w3>>6 & #x00CC00CC
      rel!r_w4 := w4&#xCC33CC33 | w4<<6 & #x33003300 | w4>>6 & #x00CC00CC
      rel!r_w5 := w5&#xCC33CC33 | w5<<6 & #x33003300 | w5>>6 & #x00CC00CC
      rel!r_w6 := w6&#xCC33CC33 | w6<<6 & #x33003300 | w6>>6 & #x00CC00CC
      rel!r_w7 := w7&#xCC33CC33 | w7<<6 & #x33003300 | w7>>6 & #x00CC00CC
      RETURN
      ENDCASE
    CASE #30: CASE #03:
      rel!r_w0 := w0&#xAA55AA55 | w0<<7 & #x55005500 | w0>>7 & #x00AA00AA
      rel!r_w1 := w1&#xAA55AA55 | w1<<7 & #x55005500 | w1>>7 & #x00AA00AA
      rel!r_w2 := w2&#xAA55AA55 | w2<<7 & #x55005500 | w2>>7 & #x00AA00AA
      rel!r_w3 := w3&#xAA55AA55 | w3<<7 & #x55005500 | w3>>7 & #x00AA00AA
      rel!r_w4 := w4&#xAA55AA55 | w4<<7 & #x55005500 | w4>>7 & #x00AA00AA
      rel!r_w5 := w5&#xAA55AA55 | w5<<7 & #x55005500 | w5>>7 & #x00AA00AA
      rel!r_w6 := w6&#xAA55AA55 | w6<<7 & #x55005500 | w6>>7 & #x00AA00AA
      rel!r_w7 := w7&#xAA55AA55 | w7<<7 & #x55005500 | w7>>7 & #x00AA00AA
      RETURN
      ENDCASE
    CASE #21: CASE #12:
      rel!r_w0 := w0&#xC3C3C3C3 | w0<<2 & #x30303030 | w0>>2 & #x0C0C0C0C
      rel!r_w1 := w1&#xC3C3C3C3 | w1<<2 & #x30303030 | w1>>2 & #x0C0C0C0C
      rel!r_w2 := w2&#xC3C3C3C3 | w2<<2 & #x30303030 | w2>>2 & #x0C0C0C0C
      rel!r_w3 := w3&#xC3C3C3C3 | w3<<2 & #x30303030 | w3>>2 & #x0C0C0C0C
      rel!r_w4 := w4&#xC3C3C3C3 | w4<<2 & #x30303030 | w4>>2 & #x0C0C0C0C
      rel!r_w5 := w5&#xC3C3C3C3 | w5<<2 & #x30303030 | w5>>2 & #x0C0C0C0C
      rel!r_w6 := w6&#xC3C3C3C3 | w6<<2 & #x30303030 | w6>>2 & #x0C0C0C0C
      rel!r_w7 := w7&#xC3C3C3C3 | w7<<2 & #x30303030 | w7>>2 & #x0C0C0C0C
      RETURN
      ENDCASE
    CASE #20: CASE #02:
      rel!r_w0 := w0&#xA5A5A5A5 | w0<<3 & #x50505050 | w0>>3 & #x0A0A0A0A
      rel!r_w1 := w1&#xA5A5A5A5 | w1<<3 & #x50505050 | w1>>3 & #x0A0A0A0A
      rel!r_w2 := w2&#xA5A5A5A5 | w2<<3 & #x50505050 | w2>>3 & #x0A0A0A0A
      rel!r_w3 := w3&#xA5A5A5A5 | w3<<3 & #x50505050 | w3>>3 & #x0A0A0A0A
      rel!r_w4 := w4&#xA5A5A5A5 | w4<<3 & #x50505050 | w4>>3 & #x0A0A0A0A
      rel!r_w5 := w5&#xA5A5A5A5 | w5<<3 & #x50505050 | w5>>3 & #x0A0A0A0A
      rel!r_w6 := w6&#xA5A5A5A5 | w6<<3 & #x50505050 | w6>>3 & #x0A0A0A0A
      rel!r_w7 := w7&#xA5A5A5A5 | w7<<3 & #x50505050 | w7>>3 & #x0A0A0A0A
      RETURN
    CASE #10: CASE #01:
      rel!r_w0 := w0&#x99999999 | w0<<1 & #x44444444 | w0>>1 & #x22222222
      rel!r_w1 := w1&#x99999999 | w1<<1 & #x44444444 | w1>>1 & #x22222222
      rel!r_w2 := w2&#x99999999 | w2<<1 & #x44444444 | w2>>1 & #x22222222
      rel!r_w3 := w3&#x99999999 | w3<<1 & #x44444444 | w3>>1 & #x22222222
      rel!r_w4 := w4&#x99999999 | w4<<1 & #x44444444 | w4>>1 & #x22222222
      rel!r_w5 := w5&#x99999999 | w5<<1 & #x44444444 | w5>>1 & #x22222222
      rel!r_w6 := w6&#x99999999 | w6<<1 & #x44444444 | w6>>1 & #x22222222
      rel!r_w7 := w7&#x99999999 | w7<<1 & #x44444444 | w7>>1 & #x22222222
      RETURN
  }
}

// ignorearg(rel, argi)  Remove argi, assuming it is unconstrained
//                       typically because it is used only once.
//                       Set v!argi to zero.
AND ignorearg(rel, argi) = VALOF
{ LET w0, w1, w2, w3 = rel!r_w0, rel!r_w1, rel!r_w2, rel!r_w3
  LET w4, w5, w6, w7 = rel!r_w4, rel!r_w5, rel!r_w6, rel!r_w7
  LET all = w0|w1|w2|w3|w4|w5|w6|w7
  LET sh, mask = ?, ?
  LET id = origid(rel!(r_a+argi))
  LET res0 = FALSE   // TRUE means the argument must be 0
  LET res1 = FALSE   // TRUE means the argument must be 1

//newline()
//wrrel(rel)
//writef("ignorearg: %n*n", argi)
  SWITCHON argi INTO
  { DEFAULT:  RETURN
    CASE 7: UNLESS w0 | w1 | w2 | w3 DO res1 := TRUE // arg 7 must be 1
            UNLESS w4 | w5 | w6 | w7 DO res0 := TRUE // arg 7 must be 0
            rel!r_w0, rel!r_w1, rel!r_w2, rel!r_w3 := w0|w4, w1|w5, w2|w6, w3|w7
            rel!r_w4, rel!r_w5, rel!r_w6, rel!r_w7 :=    0,  0,   0,   0
            GOTO ret
    CASE 6: UNLESS w0 | w1 | w4 | w5 DO res1 := TRUE // arg 6 must be 1
            UNLESS w2 | w3 | w6 | w7 DO res0 := TRUE // arg 6 must be 0
            rel!r_w0, rel!r_w1, rel!r_w4, rel!r_w5 := w0|w2, w1|w3, w4|w6, w5|w7
            rel!r_w2, rel!r_w3, rel!r_w6, rel!r_w7 :=   0,   0,   0,   0
            GOTO ret
    CASE 5: UNLESS w0 | w2 | w4 | w5 DO res1 := TRUE // arg 5 must be 1
            UNLESS w1 | w3 | w5 | w7 DO res0 := TRUE // arg 5 must be 0
            rel!r_w0, rel!r_w2, rel!r_w4, rel!r_w6 := w0|w1, w2|w3, w4|w5, w6|w7
            rel!r_w1, rel!r_w3, rel!r_w5, rel!r_w7 :=   0,   0,   0,   0
            GOTO ret
    CASE 4: sh, mask := 16, #x0000FFFF; ENDCASE
    CASE 3: sh, mask :=  8, #x00FF00FF; ENDCASE
    CASE 2: sh, mask :=  4, #x0F0F0F0F; ENDCASE
    CASE 1: sh, mask :=  2, #x33333333; ENDCASE
    CASE 0: sh, mask :=  2, #x55555555
  }
//writef("ignorearg: argi=%n sh=%n mask=%x8*n", argi, sh, mask)
  IF (all &  mask)=0 DO res1 := TRUE
  IF (all & ~mask)=0 DO res0 := TRUE
//IF res1 DO writef("ignorearg: argument %n must be 1*n", argi)
//IF res0 DO writef("ignorearg: argument %n must be 0*n", argi)

  // Update the relation bit pattern
  rel!r_w0 := (w0 | w0>>sh) & mask
  rel!r_w1 := (w1 | w1>>sh) & mask
  rel!r_w2 := (w2 | w2>>sh) & mask
  rel!r_w3 := (w3 | w3>>sh) & mask
  rel!r_w4 := (w4 | w4>>sh) & mask
  rel!r_w5 := (w5 | w5>>sh) & mask
  rel!r_w6 := (w6 | w6>>sh) & mask
  rel!r_w7 := (w7 | w7>>sh) & mask

ret:
  rel!(r_a+argi) := 0
  //wrrel(rel)
//abort(4444)
  TEST res0
  THEN TEST res1
       THEN { writef("ignorearg: v%n = X*n", id)
              RESULTIS -3
            }
       ELSE { writef("ignorearg: v%n = 0*n", id)
              RESULTIS 0
            }
  ELSE TEST res1
       THEN { writef("ignorearg: v%n = 1*n", id)
              RESULTIS 1
            }
       ELSE { writef("ignorearg: v%n = Z*n", id)
              RESULTIS -2
            }
}

AND isunconstrained(rel, i) = VALOF
{ // Return TRUE if the relation places no constraint on arg i
  LET w0, w1, w2, w3 = rel!r_w0, rel!r_w1, rel!r_w2, rel!r_w3
  LET w4, w5, w6, w7 = rel!r_w4, rel!r_w5, rel!r_w6, rel!r_w7
  LET sh, mask = ?, ?

//wrrel(rel);newline()
//writef("isunconstrained: %n*n", i)
  SWITCHON i INTO
  { DEFAULT:  bug("isunconstrained: Bad argument number %n*n", i)
              RESULTIS FALSE
    CASE 7:   RESULTIS w0=w4 & w1=w5 & w2=w6 & w3=w7 -> TRUE, FALSE
    CASE 6:   RESULTIS w0=w2 & w1=w3 & w4=w6 & w5=w7 -> TRUE, FALSE
    CASE 5:   RESULTIS w0=w1 & w2=w3 & w4=w5 & w6=w7 -> TRUE, FALSE
    CASE 4:   sh, mask := 16, #x0000FFFF; ENDCASE
    CASE 3:   sh, mask :=  8, #x00FF00FF; ENDCASE
    CASE 2:   sh, mask :=  4, #x0F0F0F0F; ENDCASE
    CASE 1:   sh, mask :=  2, #x33333333; ENDCASE
    CASE 0:   sh, mask :=  1, #x55555555
  }
//writef("isunconstrained: i=%n sh=%n mask=%n*n", i, sh, mask)

  RESULTIS ((w0 XOR w0>>sh) & mask) = 0 &
           ((w1 XOR w1>>sh) & mask) = 0 &
           ((w2 XOR w2>>sh) & mask) = 0 &
           ((w3 XOR w3>>sh) & mask) = 0 &
           ((w4 XOR w4>>sh) & mask) = 0 &
           ((w5 XOR w5>>sh) & mask) = 0 &
           ((w6 XOR w6>>sh) & mask) = 0 &
           ((w7 XOR w7>>sh) & mask) = 0 -> TRUE, FALSE
}

AND standardised(rel) = VALOF
{ LET n = 0        // To hold the number of non-zero arguments
  LET bad = FALSE
  LET w0, w1, w2, w3 = rel!r_w0, rel!r_w1, rel!r_w2, rel!r_w3
  LET w4, w5, w6, w7 = rel!r_w4, rel!r_w5, rel!r_w6, rel!r_w7
  FOR argi = 0 TO 7 IF rel!(r_a+argi) DO n := n+1
  UNLESS n=rel!r_args RESULTIS FALSE
  //writef("args=%n -- ok*n", n)
  // Check the bit pattern
  SWITCHON n INTO
  {
    CASE 0: UNLESS (w0&#xFFFFFFFE)=0 DO bad := TRUE
    CASE 1: UNLESS (w0&#xFFFFFFFC)=0 DO bad := TRUE
    CASE 2: UNLESS (w0&#xFFFFFFF0)=0 DO bad := TRUE
    CASE 3: UNLESS (w0&#xFFFFFF00)=0 DO bad := TRUE
    CASE 4: UNLESS (w0&#xFFFF0000)=0 DO bad := TRUE
    CASE 5: IF w1                    DO bad := TRUE
    CASE 6: IF w2 | w3               DO bad := TRUE
    CASE 7: IF w4 | w5 | w6 | w7     DO bad := TRUE
    CASE 8:
  }
  IF bad RESULTIS FALSE
  //writef("bit pattern ok*n")

  // Check the arguments are in decreasing order.
  FOR argi = 0 TO 6 DO
  { LET vi = rel!(r_a+argi)
    LET vj = rel!(r_a+argi+1)
    IF vi & vi<=vj RESULTIS FALSE
    IF vi=0 FOR argj = argi+1 TO 7 IF rel!(r_a+argj) DO
      RESULTIS FALSE
  }
  //writef("The arguments are sorted*n")
  RESULTIS TRUE
}

AND standardise(rel) BE
{ LET v = @rel!r_a

//wrvars()

writef("standardise:*n")
wrrel(rel, TRUE)

  // Remove arguments not constrained by this relation
  FOR i = 0 TO 7 IF v!i & isunconstrained(rel, i) DO
  { 
writef("standardise: remove unconstrained variable v%n*n", origid(v!i))
    //rmref(rel, v!i)
    v!i := 0
  }

  FOR i = 0 TO 6 DO
  { // Find the next largest variable
    LET max, p = v!i, i
    FOR j = i TO 7 DO
    { LET var = v!j
      IF var & var>max DO max, p := var, j
    }
writef("max = %n*n", max)
    UNLESS max BREAK // No more variables

    UNLESS i=p DO
    { writef("exchange arg%n=v%n with arg%n=v%n*n", 
               i, origid(v!i), p, origid(v!p))
      exchargs(rel, i, p)
    }
    // Check whether there are any repetitions
    FOR j = p+1 TO 7 IF v!j=max DO
    { apeq(rel, i, j)
      ignorearg(rel, j)
writef("arg%n = arg%n = v%n*n", i, j, origid(v!i))
    }
  }

  rel!r_args := 0
  FOR argi = 7 TO 0 IF rel!(r_a+argi) DO
  { rel!r_args := argi+1
    BREAK
  }
writef("standardise: setting args=%n*n", rel!r_args)

writef("standardise: clear unused bits in the bit pattern*n")
  
  // Clear unused bits of the bit pattern
  SWITCHON rel!r_args INTO
  { CASE 0: rel!r_w0 := rel!r_w0 & #x00000001
    CASE 1: rel!r_w0 := rel!r_w0 & #x00000003
    CASE 2: rel!r_w0 := rel!r_w0 & #x0000000F
    CASE 3: rel!r_w0 := rel!r_w0 & #x000000FF
    CASE 4: rel!r_w0 := rel!r_w0 & #x0000FFFF
    CASE 5: rel!r_w1 := 0
    CASE 6: rel!r_w1, rel!r_w1 := 0, 0
    CASE 7: rel!r_w1, rel!r_w1, rel!r_w1, rel!r_w1 := 0, 0, 0, 0
    CASE 8:
  }
  wrrel(rel, TRUE)
}

// Split attempts to factorise rel into the conjunction of
// two relations each containing at least 3 variables and
// having no variables in common. It return TRUE if successful.
AND split(rel) = VALOF
{ standardise(rel)
  IF rel!r_args<6 RESULTIS FALSE // Too few variables

// The search is based on the following sequence of quartets

// 4567 4067 4167 4267 4207 4217 4237 4037 4057 5047 7045 7145 7105 7125 7135
// 7035 7065 7061 7021 7321 7301 7341 7340 7320 7420 7460 7462 7432 7532 7542
// 7546 7536 7534 7634 7630 7631 7621 7651 7641 7041 7241 2741 2701 2731 2751
// 2753 2743 2763 7263 7260 7250 7256 6257 6457 6427 2467

// 05 0123 4567  67  567  4567
  IF cansplit2(rel) | cansplit3(rel) | cansplit4(rel) RESULTIS TRUE
  exchargs(rel, 0, 5)
// 15 5123 4067      067  0467
  IF cansplit3(rel) | cansplit4(rel) RESULTIS TRUE
  exchargs(rel, 1, 5)
// 25 5023 4167      167  1467
  IF cansplit3(rel) | cansplit4(rel) RESULTIS TRUE
  exchargs(rel, 2, 5)
// 16 5013 4267      267  2467
  IF cansplit3(rel) | cansplit4(rel) RESULTIS TRUE
  exchargs(rel, 1, 6)
// 26 5613 4207  07  027  0247
  IF cansplit2(rel) | cansplit3(rel) | cansplit4(rel) RESULTIS TRUE
  exchargs(rel, 2, 6)
// 36 5603 4217  17  127  1247
  IF cansplit2(rel) | cansplit3(rel) | cansplit4(rel) RESULTIS TRUE
  exchargs(rel, 3, 6)
// 25 5601 4237  37  237  2347
  IF cansplit2(rel) | cansplit3(rel) | cansplit4(rel) RESULTIS TRUE
  exchargs(rel, 2, 5)
// 06 5621 4037      037  0347
  IF cansplit3(rel) | cansplit4(rel) RESULTIS TRUE
  exchargs(rel, 0, 6)
// 46 3621 4057  57  057  0457
  IF cansplit2(rel) | cansplit3(rel) | cansplit4(rel) RESULTIS TRUE
  exchargs(rel, 4, 6)
// 47 3621 5047  47  047
  IF cansplit2(rel) | cansplit3(rel) RESULTIS TRUE
  exchargs(rel, 4, 7)
// 35 3621 7045  45  045
  IF cansplit2(rel) | cansplit3(rel) RESULTIS TRUE
  exchargs(rel, 3, 5)
// 36 3620 7145      145  1457
  IF cansplit3(rel) | cansplit4(rel) RESULTIS TRUE
  exchargs(rel, 3, 6)
// 26 3624 7105  05  015  0157
  IF cansplit2(rel) | cansplit3(rel) | cansplit4(rel) RESULTIS TRUE
  exchargs(rel, 2, 6)
// 06 3604 7125  25  125  1257
  IF cansplit2(rel) | cansplit3(rel) | cansplit4(rel) RESULTIS TRUE
  exchargs(rel, 0, 6)
// 25 2604 7135  35  135  1357
  IF cansplit2(rel) | cansplit3(rel) | cansplit4(rel) RESULTIS TRUE
  exchargs(rel, 2, 5)
// 16 2614 7035      035  0357
  IF cansplit3(rel) | cansplit4(rel) RESULTIS TRUE
  exchargs(rel, 1, 6)
// 27 2314 7065  56  056  0567
  IF cansplit2(rel) | cansplit3(rel) | cansplit4(rel) RESULTIS TRUE
  exchargs(rel, 2, 7)
// 06 2354 7061  16  016  0167
  IF cansplit2(rel) | cansplit3(rel) | cansplit4(rel) RESULTIS TRUE
  exchargs(rel, 0, 6)
// 15 6354 7021  12  012  0127
  IF cansplit2(rel) | cansplit3(rel) | cansplit4(rel) RESULTIS TRUE
  exchargs(rel, 1, 5)
// 16 6054 7321      123  1237
  IF cansplit3(rel) | cansplit4(rel) RESULTIS TRUE
  exchargs(rel, 1, 6)
// 36 6254 7301  01  013  0137
  IF cansplit2(rel) | cansplit3(rel) | cansplit4(rel) RESULTIS TRUE
  exchargs(rel, 3, 6)
// 37 6250 7341  14  134  1347
  IF cansplit2(rel) | cansplit3(rel) | cansplit4(rel) RESULTIS TRUE
  exchargs(rel, 3, 7)
// 16 6251 7340  04  034
  IF cansplit2(rel) | cansplit3(rel) RESULTIS TRUE
  exchargs(rel, 1, 6)
// 15 6451 7320  02  023  0237
  IF cansplit2(rel) | cansplit3(rel) | cansplit4(rel) RESULTIS TRUE
  exchargs(rel, 1, 5)
// 06 6351 7420      024
  IF cansplit3(rel) RESULTIS TRUE
  exchargs(rel, 0, 6)
// 07 2351 7460  06  046
  IF cansplit2(rel) | cansplit3(rel) RESULTIS TRUE
  exchargs(rel, 0, 7)
// 16 0351 7462  26  246
  IF cansplit2(rel) | cansplit3(rel) RESULTIS TRUE
  exchargs(rel, 1, 6)
// 25 0651 7432  23  234
  IF cansplit2(rel) | cansplit3(rel) RESULTIS TRUE
  exchargs(rel, 2, 5)
// 26 0641 7532      235  2357
  IF cansplit3(rel) | cansplit4(rel) RESULTIS TRUE
  exchargs(rel, 2, 6)
// 17 0631 7542  24  245  2457
  IF cansplit2(rel) | cansplit3(rel) | cansplit4(rel) RESULTIS TRUE
  exchargs(rel, 1, 7)
// 26 0231 7546  46  456  
  IF cansplit2(rel) | cansplit3(rel) RESULTIS TRUE
  exchargs(rel, 2, 6)
// 27 0241 7536  36  356  3567
  IF cansplit2(rel) | cansplit3(rel) | cansplit4(rel) RESULTIS TRUE
  exchargs(rel, 2, 7)
// 25 0261 7534  34  345  3457
  IF cansplit2(rel) | cansplit3(rel) | cansplit4(rel) RESULTIS TRUE
  exchargs(rel, 2, 5)
// 07 0251 7634      346  3467
  IF cansplit3(rel) | cansplit4(rel) RESULTIS TRUE
  exchargs(rel, 0, 7)
// 37 4251 7630  03  036  0367
  IF cansplit2(rel) | cansplit3(rel) | cansplit4(rel) RESULTIS TRUE
  exchargs(rel, 3, 7)
// 16 4250 7631  13  136  1367
  IF cansplit2(rel) | cansplit3(rel) | cansplit4(rel) RESULTIS TRUE
  exchargs(rel, 1, 6)
// 26 4350 7621      126  1267
  IF cansplit3(rel) | cansplit4(rel) RESULTIS TRUE
  exchargs(rel, 2, 6)
// 06 4320 7651  15  156  1567
  IF cansplit2(rel) | cansplit3(rel) | cansplit4(rel) RESULTIS TRUE
  exchargs(rel, 0, 6)
// 35 5320 7641      146
  IF cansplit3(rel) RESULTIS TRUE
  exchargs(rel, 3, 5)
// 25 5326 7041      014  0147
  IF cansplit3(rel) | cansplit4(rel) RESULTIS TRUE
  exchargs(rel, 2, 5)
// 45 5306 7241      124
  IF cansplit3(rel) RESULTIS TRUE
  exchargs(rel, 4, 5)
// 26 5306 2741      147
  IF cansplit3(rel) RESULTIS TRUE
  exchargs(rel, 2, 6)
// 16 5346 2701      017
  IF cansplit3(rel) RESULTIS TRUE
  exchargs(rel, 1, 6)
// 06 5046 2731      137
  IF cansplit3(rel) RESULTIS TRUE
  exchargs(rel, 0, 6)
// 07 3046 2751      157
  IF cansplit3(rel) RESULTIS TRUE
  exchargs(rel, 0, 7)
// 26 1046 2753      357
  IF cansplit3(rel) RESULTIS TRUE
  exchargs(rel, 2, 6)
// 36 1056 2743      347
  IF cansplit3(rel) RESULTIS TRUE
  exchargs(rel, 3, 6)
// 45 1054 2763      367  2367
  IF cansplit3(rel) | cansplit4(rel) RESULTIS TRUE
  exchargs(rel, 4, 5)
// 17 1054 7263      236
  IF cansplit3(rel) RESULTIS TRUE
  exchargs(rel, 1, 7)
// 26 1354 7260      026  0267
  IF cansplit3(rel) | cansplit4(rel) RESULTIS TRUE
  exchargs(rel, 2, 6)
// 27 1364 7250      025  0257
  IF cansplit3(rel) | cansplit4(rel) RESULTIS TRUE
  exchargs(rel, 2, 7)
// 47 1304 7256      256  2567
  IF cansplit3(rel) | cansplit4(rel) RESULTIS TRUE
  exchargs(rel, 4, 7)
// 35 1304 6257      257
  IF cansplit3(rel) RESULTIS TRUE
  exchargs(rel, 3, 5)
// 36 1302 6457      457
  IF cansplit3(rel) RESULTIS TRUE
  exchargs(rel, 3, 6)
// 46 1305 6427  27  247
  IF cansplit2(rel) | cansplit3(rel) RESULTIS TRUE
  exchargs(rel, 4, 6)
//    1305 2467      467
  IF cansplit3(rel) RESULTIS TRUE
  RESULTIS FALSE
}

AND cansplit2(rel, sw) = VALOF
{ LET w = @rel!r_w0
  LET x, y, i = ?, ?, 0
  // set x,y to first non zero pair
  UNTIL i>7 DO
  { x, y := w!i, w!(i+1)
    IF x | y BREAK
    i := i+2
  }

  // Check all other words are either zero or
  // equal to first
  FOR j = i+2 TO 7 BY 2 DO
  { LET a, b = w!j, w!(j+1)
//writef("cansplit2: x=%x8 y=%x8   a=%x8 b=%x8*n", x, y, a, b)
    UNLESS (a|b)=0 | a=x & b=y RESULTIS FALSE
  }
//writef("Split2 possible*n")
//wrrel(rel); newline()
//abort(1002)
  RESULTIS TRUE
}

AND cansplit3(rel, sw) = VALOF
{ LET w = @rel!r_w0
  LET x, i = ?, 0
  // set first to first non zero wi
  UNTIL i>7 DO
  { x := w!i
    IF x BREAK
    i := i+1
  }

  // Check all other words are either zero or
  // equal to first
  FOR j = i+1 TO 7 DO
  { LET a = w!j
//writef("cansplit3: x=%x8 a=%x8*n", x, a)
    UNLESS a=0 | a=x RESULTIS FALSE
  }
writef("Split3 possible*n")
wrrel(rel); newline()
abort(1003)
  RESULTIS TRUE
}

AND cansplit4(rel, sw) = VALOF
{ LET w = @rel!r_w0
  LET x, y, z, i = ?, ?, ?, 0
  // set x to first non zero value
  UNTIL i>7 DO
  { x := w!i
    IF x BREAK
    i := i+1
  }
  // Form three pair
  x := (x | x>>16) & #x0000FFFF     // 0000abcd
  y := x <<16                       // abcd0000
  z := x | y                        // abcdabcd

  // Check all other words are either zero or
  // equal to first
  FOR j = i TO 7 DO
  { LET a = w!j
//writef("cansplit4: x=%x8 y=%x8 z=%x8   a=%x8*n", x, y, z, a)
    UNLESS a=0 | a=x | a=y | a=z RESULTIS FALSE
  }

//writef("Split4 possible*n")
//wrrel(rel); newline()
//abort(1004)
  RESULTIS TRUE
}

.

SECTION "apfns"

// The apply functions on a single relation

// apnot(rel, i)         apply the NOT operator to argument i

// apset1(rel, i)        apply  ai  =   1,   eliminate ai
// apset0(rel, i)        apply  ai  =   0,   eliminate ai
// apeq(rel, i, j)       apply  ai  =  aj,   eliminate aj
// apne(rel, i, j)       apply  ai  = ~aj,   eliminate aj

// apimppp(rel, i, j)    apply  ai ->  aj
// apimppn(rel, i, j)    apply  ai -> ~aj
// apimpnp(rel, i, j)    apply ~ai ->  aj
// apimpnn(rel, i, j)    apply ~ai -> ~aj

GET "libhdr"
GET "chk8.h"

// Update the relations bits corresponding to argument argi
// being complemented, eg: R11010110(x,y,z) => R01101101(x,y,~z)

// x 10101010
// y 11001100
// z 11110000

//   11010110 means xyz = 111 or 011 or 001 or 010 or 100
//   01101101 means xyz = 110 or 010 or 000 or 011 or 101
LET apnot(rel, argi) BE
{ LET w0, w1, w2, w3 = rel!r_w0, rel!r_w1, rel!r_w2, rel!r_w3
  LET w4, w5, w6, w7 = rel!r_w4, rel!r_w5, rel!r_w6, rel!r_w7
  LET sh, m1, m2 = ?, ?, ?

  //wrrel(rel, TRUE)
  //writef("apnot: arg %n*n", argi)

  SWITCHON argi INTO
  { DEFAULT: writef("apnot: Bad argi=%n*n", argi); abort(999)
             RETURN

    CASE 7:  rel!r_w0, rel!r_w1, rel!r_w2, rel!r_w3 := w4, w5, w6, w7
             rel!r_w4, rel!r_w5, rel!r_w6, rel!r_w7 := w0, w1, w2, w3
             wrrel(rel, TRUE)
             RETURN
    CASE 6:  rel!r_w0, rel!r_w1, rel!r_w2, rel!r_w3 := w2, w3, w0, w1
             rel!r_w4, rel!r_w5, rel!r_w6, rel!r_w7 := w6, w7, w4, w5
             wrrel(rel, TRUE)
             RETURN
    CASE 5:  rel!r_w0, rel!r_w1, rel!r_w2, rel!r_w3 := w1, w0, w3, w2
             rel!r_w4, rel!r_w5, rel!r_w6, rel!r_w7 := w5, w4, w7, w6
             wrrel(rel, TRUE)
             RETURN
    CASE 4:  rel!r_w0 := w0<<16 | w0>>16 // Assume 32-bit implementation
             rel!r_w1 := w1<<16 | w1>>16
             rel!r_w2 := w2<<16 | w2>>16
             rel!r_w3 := w3<<16 | w3>>16
             rel!r_w4 := w4<<16 | w4>>16
             rel!r_w5 := w5<<16 | w5>>16
             rel!r_w6 := w6<<16 | w6>>16
             rel!r_w7 := w7<<16 | w7>>16
             wrrel(rel, TRUE)
             RETURN
    CASE 3:  sh := 8
             m1 := #xFF00FF00
             m2 := #x00FF00FF
             ENDCASE
    CASE 2:  sh := 4
             m1 := #xF0F0F0F0
             m2 := #x0F0F0F0F
             ENDCASE
    CASE 1:  sh := 2
             m1 := #xCCCCCCCC
             m2 := #x33333333
             ENDCASE
    CASE 0:  sh := 1
             m1 := #xAAAAAAAA
             m2 := #x55555555
             ENDCASE
  }
  rel!r_w0 := w0<<sh & m1 | w0>>sh & m2
  rel!r_w1 := w1<<sh & m1 | w1>>sh & m2
  rel!r_w2 := w2<<sh & m1 | w2>>sh & m2
  rel!r_w3 := w3<<sh & m1 | w3>>sh & m2
  rel!r_w4 := w4<<sh & m1 | w4>>sh & m2
  rel!r_w5 := w5<<sh & m1 | w5>>sh & m2
  rel!r_w6 := w6<<sh & m1 | w6>>sh & m2
  rel!r_w7 := w7<<sh & m1 | w7>>sh & m2
  //wrrel(rel, TRUE)
}

// Apply:  Argument i is known to have value 1
// eg: R11010110(x,y,z) => R00001101(x,y,0)

// x 10101010
// y 11001100
// z 11110000

//   11010110 means xyz = 111 or 011 or 001 or 010 or 100
//   00001101 means xy  = 11  or 01  or 00
AND apset1(rel, argi) BE
{ LET v = @rel!r_a

  //wrrel(rel, TRUE)
  //writef("apset1: arg%n*n", argi)
  SWITCHON argi INTO
  { DEFAULT: bug("Error in apset1: argi=%n*n", argi)
             RETURN
    CASE 7:  rel!r_w0, rel!r_w1, rel!r_w2, rel!r_w3 := 0, 0, 0, 0
             ENDCASE
    CASE 6:  rel!r_w0, rel!r_w1, rel!r_w4, rel!r_w5 := 0, 0, 0, 0
             ENDCASE
    CASE 5:  rel!r_w0, rel!r_w2, rel!r_w4, rel!r_w6 := 0, 0, 0, 0
             ENDCASE
    CASE 4:  andrelbits1(rel, #xFFFF0000); ENDCASE
    CASE 3:  andrelbits1(rel, #xFF00FF00); ENDCASE
    CASE 2:  andrelbits1(rel, #xF0F0F0F0); ENDCASE
    CASE 1:  andrelbits1(rel, #xCCCCCCCC); ENDCASE
    CASE 0:  andrelbits1(rel, #xAAAAAAAA); ENDCASE
  }
  apnot(rel, argi)
  //rmref(rel, v!argi)
  v!argi := 0
  //wrrel(rel, TRUE)
}

// Apply:  Argument argi is known to have value 0
// eg: R11010110(x,y,z) => R00001101(x,y,0)

// x 10101010
// y 11001100
// z 11110000

//   11010110 means xyz = 111 or 011 or 001 or 010 or 100
//   00000110 means xy  =                      01  or 10
AND apset0(rel, argi) BE
{ LET v = @rel!r_a

  //wrrel(rel, TRUE)
  //writef("apset0: arg%n*n", argi)
//abort(1000)
  SWITCHON argi INTO
  { DEFAULT: bug("Error in apset0: argi=%n*n", argi)
             RETURN
    CASE 7:  rel!r_w4, rel!r_w5, rel!r_w6, rel!r_w7 := 0, 0, 0, 0
             ENDCASE
    CASE 6:  rel!r_w2, rel!r_w3, rel!r_w6, rel!r_w7 := 0, 0, 0, 0
             ENDCASE
    CASE 5:  rel!r_w1, rel!r_w3, rel!r_w5, rel!r_w7 := 0, 0, 0, 0
             ENDCASE
    CASE 4:  andrelbits1(rel, #x0000FFFF); ENDCASE
    CASE 3:  andrelbits1(rel, #x00FF00FF); ENDCASE
    CASE 2:  andrelbits1(rel, #x0F0F0F0F); ENDCASE
    CASE 1:  andrelbits1(rel, #x33333333); ENDCASE
    CASE 0:  andrelbits1(rel, #x55555555); ENDCASE
  }
  //rmref(rel, v!argi)

  //wrrel(rel, TRUE)
}

// Apply:  ai = aj
// eg: R11010110(x,y,z) with y=z gives R00001110(x,y,0)

// x 10101010
// y 11001100
// z 11110000

//   11010110 means xyz = 111 or 011 or 001 or 010 or 100
//   00001110 means xy  = 11  or 01                or 10
AND apeq(rel, argi, argj) BE
{ LET v = @rel!r_a

  //newline()
  //wrrel(rel, TRUE)
  //writef("apeq: args %n %n*n", argi, argj)

  SWITCHON argi*8+argj INTO
  { DEFAULT:            ENDCASE  // Either i=j or an error
    CASE #76: CASE #67: rel!r_w2, rel!r_w3, rel!r_w4, rel!r_w5 := 0, 0, 0, 0
                        ENDCASE
    CASE #75: CASE #57: rel!r_w1, rel!r_w3, rel!r_w4, rel!r_w6 := 0, 0, 0, 0
                        ENDCASE
    CASE #74: CASE #47: andrelbits8v(rel, TABLE #x0000FFFF, #x0000FFFF,
                                                #x0000FFFF, #x0000FFFF,
                                                #xFFFF0000, #xFFFF0000,
                                                #xFFFF0000, #xFFFF0000)
                        ENDCASE
    CASE #73: CASE #37: andrelbits8v(rel, TABLE #x00FF00FF, #x00FF00FF,
                                                #x00FF00FF, #x00FF00FF,
                                                #xFF00FF00, #xFF00FF00,
                                                #xFF00FF00, #xFF00FF00)
                        ENDCASE
    CASE #72: CASE #27: andrelbits8v(rel, TABLE #x0F0F0F0F, #x0F0F0F0F,
                                                #x0F0F0F0F, #x0F0F0F0F,
                                                #xF0F0F0F0, #xF0F0F0F0,
                                                #xF0F0F0F0, #xF0F0F0F0)
                        ENDCASE
    CASE #71: CASE #17: andrelbits8v(rel, TABLE #x33333333, #x33333333,
                                                #x33333333, #x33333333,
                                                #xCCCCCCCC, #xCCCCCCCC,
                                                #xCCCCCCCC, #xCCCCCCCC)
                        ENDCASE
    CASE #70: CASE #07: andrelbits8v(rel, TABLE #x55555555, #x55555555,
                                                #x55555555, #x55555555,
                                                #xAAAAAAAA, #xAAAAAAAA,
                                                #xAAAAAAAA, #xAAAAAAAA)
                        ENDCASE

    CASE #65: CASE #56: rel!r_w1, rel!r_w2, rel!r_w5, rel!r_w6 := 0, 0, 0, 0
                        ENDCASE
    CASE #64: CASE #46: andrelbits4(rel, #x0000FFFF, #x0000FFFF,
                                         #xFFFF0000, #xFFFF0000); ENDCASE
    CASE #63: CASE #36: andrelbits4(rel, #x00FF00FF, #x00FF00FF,
                                         #xFF00FF00, #xFF00FF00); ENDCASE
    CASE #62: CASE #26: andrelbits4(rel, #x0F0F0F0F, #x0F0F0F0F,
                                         #xF0F0F0F0, #xF0F0F0F0); ENDCASE
    CASE #61: CASE #16: andrelbits4(rel, #x33333333, #x33333333,
                                         #xCCCCCCCC, #xCCCCCCCC); ENDCASE
    CASE #60: CASE #06: andrelbits4(rel, #x55555555, #x55555555,
                                         #xAAAAAAAA, #xAAAAAAAA); ENDCASE

    CASE #54: CASE #45: andrelbits2(rel, #x0000FFFF, #xFFFF0000); ENDCASE
    CASE #53: CASE #35: andrelbits2(rel, #x00FF00FF, #xFF00FF00); ENDCASE
    CASE #52: CASE #25: andrelbits2(rel, #x0F0F0F0F, #xF0F0F0F0); ENDCASE
    CASE #51: CASE #15: andrelbits2(rel, #x33333333, #xCCCCCCCC); ENDCASE
    CASE #50: CASE #05: andrelbits2(rel, #x55555555, #xAAAAAAAA); ENDCASE

    CASE #43: CASE #34: andrelbits1(rel, #xFF0000FF);             ENDCASE
    CASE #42: CASE #24: andrelbits1(rel, #xF0F00F0F);             ENDCASE
    CASE #41: CASE #14: andrelbits1(rel, #xCCCC3333);             ENDCASE
    CASE #40: CASE #04: andrelbits1(rel, #xAAAA5555);             ENDCASE

    CASE #32: CASE #23: andrelbits1(rel, #xF00FF00F);             ENDCASE
    CASE #31: CASE #13: andrelbits1(rel, #xCC33CC33);             ENDCASE
    CASE #30: CASE #03: andrelbits1(rel, #xAA55AA55);             ENDCASE

    CASE #21: CASE #12: andrelbits1(rel, #xC3C3C3C3);             ENDCASE
    CASE #20: CASE #02: andrelbits1(rel, #xA5A5A5A5);             ENDCASE

    CASE #10: CASE #01: andrelbits1(rel, #x99999999);             ENDCASE
  }
  //wrrel(rel, TRUE)
  ignorearg(rel, argj)
}

// Apply:  ai ~= aj
// eg: R11010110(x,y,z) with y=~z gives R00000101(x,y,0)

// x 10101010
// y 11001100
// z 11110000

//   11010110 means xyz = 111 or 011 or 001 or 010 or 100
//   00000101 means xy  =               00  or 01
AND apne(rel, argi, argj) BE
{ LET v = @rel!r_a

  //newline()
  //wrrel(rel, TRUE)
  //writef("apne: args %n %n*n", argi, argj)

  SWITCHON argi*8+argj INTO
  { DEFAULT:            ENDCASE  // an error

    CASE #77: CASE #66:
    CASE #55: CASE #44:
    CASE #33: CASE #22:
    CASE #11: CASE #00:  andrelbits1(rel, #x00000000);            ENDCASE

    CASE #76: CASE #67: rel!r_w0, rel!r_w1, rel!r_w6, rel!r_w7 := 0, 0, 0, 0
                        ENDCASE
    CASE #75: CASE #57: rel!r_w0, rel!r_w2, rel!r_w5, rel!r_w7 := 0, 0, 0, 0
                        ENDCASE
    CASE #74: CASE #47: andrelbits8v(rel, TABLE #xFFFF0000, #xFFFF0000,
                                                #xFFFF0000, #xFFFF0000,
                                                #x0000FFFF, #x0000FFFF,
                                                #x0000FFFF, #x0000FFFF)
                        ENDCASE
    CASE #73: CASE #37: andrelbits8v(rel, TABLE #xFF00FF00, #xFF00FF00,
                                                #xFF00FF00, #xFF00FF00,
                                                #x00FF00FF, #x00FF00FF,
                                                #x00FF00FF, #x00FF00FF)
                        ENDCASE
    CASE #72: CASE #27: andrelbits8v(rel, TABLE #xF0F0F0F0, #xF0F0F0F0,
                                                #xF0F0F0F0, #xF0F0F0F0,
                                                #x0F0F0F0F, #x0F0F0F0F,
                                                #x0F0F0F0F, #x0F0F0F0F)
                        ENDCASE
    CASE #71: CASE #17: andrelbits8v(rel, TABLE #xCCCCCCCC, #xCCCCCCCC,
                                                #xCCCCCCCC, #xCCCCCCCC,
                                                #x33333333, #x33333333,
                                                #x33333333, #x33333333)
                        ENDCASE
    CASE #70: CASE #07: andrelbits8v(rel, TABLE #xAAAAAAAA, #xAAAAAAAA,
                                                #xAAAAAAAA, #xAAAAAAAA,
                                                #x55555555, #x55555555,
                                               #x55555555, #x55555555)
                        ENDCASE

    CASE #65: CASE #56: rel!r_w0, rel!r_w3, rel!r_w4, rel!r_w7 := 0, 0, 0, 0
                        ENDCASE
    CASE #64: CASE #46: andrelbits4(rel, #xFFFF0000, #xFFFF0000,
                                         #x0000FFFF, #x0000FFFF); ENDCASE
    CASE #63: CASE #36: andrelbits4(rel, #xFF00FF00, #xFF00FF00,
                                         #x00FF00FF, #x00FF00FF); ENDCASE
    CASE #62: CASE #26: andrelbits4(rel, #xF0F0F0F0, #xF0F0F0F0,
                                         #x0F0F0F0F, #x0F0F0F0F); ENDCASE
    CASE #61: CASE #16: andrelbits4(rel, #xCCCCCCCC, #xCCCCCCCC,
                                         #x33333333, #x33333333); ENDCASE
    CASE #60: CASE #06: andrelbits4(rel, #xAAAAAAAA, #xAAAAAAAA,
                                         #x55555555, #x55555555); ENDCASE

    CASE #54: CASE #45: andrelbits2(rel, #xFFFF0000, #x0000FFFF); ENDCASE
    CASE #53: CASE #35: andrelbits2(rel, #xFF00FF00, #x00FF00FF); ENDCASE
    CASE #52: CASE #25: andrelbits2(rel, #xF0F0F0F0, #x0F0F0F0F); ENDCASE
    CASE #51: CASE #15: andrelbits2(rel, #xCCCCCCCC, #x33333333); ENDCASE
    CASE #50: CASE #05: andrelbits2(rel, #xAAAAAAAA, #x55555555); ENDCASE

    CASE #43: CASE #34: andrelbits1(rel, #x00FFFF00);             ENDCASE
    CASE #42: CASE #24: andrelbits1(rel, #x0F0FF0F0);             ENDCASE
    CASE #41: CASE #14: andrelbits1(rel, #x3333CCCC);             ENDCASE
    CASE #40: CASE #04: andrelbits1(rel, #x5555AAAA);             ENDCASE

    CASE #32: CASE #23: andrelbits1(rel, #x0FF00FF0);             ENDCASE
    CASE #31: CASE #13: andrelbits1(rel, #x33CC33CC);             ENDCASE
    CASE #30: CASE #03: andrelbits1(rel, #x55AA55AA);             ENDCASE

    CASE #21: CASE #12: andrelbits1(rel, #x3C3C3C3C);             ENDCASE
    CASE #20: CASE #02: andrelbits1(rel, #x5A5A5A5A);             ENDCASE

    CASE #10: CASE #01: andrelbits1(rel, #x66666666);             ENDCASE
  }
  //wrrel(rel, TRUE)
  ignorearg(rel, argj)
}

// Apply:  ai -> aj
// eg: R11010110(x,y,z) with y->z gives R11010010(x,y,z)

// x 10101010
// y 11001100
// z 11110000

//   11010110 means xyz = 111 or 011 or 001 or 010 or 100
//   11010010 means xyz = 111 or 011 or 001        or 100
AND apimppp(rel, argi, argj)  BE
{ LET v = @rel!r_a

  //newline()
  //wrrel(rel, TRUE)
  writef("apimppp: args %n %n*n", argi, argj)

  SWITCHON argi*8+argj INTO
  { DEFAULT:  ENDCASE  // an error

    CASE #77:                                                  ENDCASE
    CASE #76: rel!r_w4, rel!r_w5 := 0, 0;                      ENDCASE
    CASE #75: rel!r_w4, rel!r_w6 := 0, 0;                      ENDCASE
    CASE #74: andrelbits8v(rel, TABLE #xFFFFFFFF, #xFFFFFFFF,
                                      #xFFFFFFFF, #xFFFFFFFF,
                                      #xFFFF0000, #xFFFF0000,
                                      #xFFFF0000, #xFFFF0000); ENDCASE
    CASE #73: andrelbits8v(rel, TABLE #xFFFFFFFF, #xFFFFFFFF,
                                      #xFFFFFFFF, #xFFFFFFFF,
                                      #xFF00FF00, #xFF00FF00,
                                      #xFF00FF00, #xFF00FF00); ENDCASE
    CASE #72: andrelbits8v(rel, TABLE #xFFFFFFFF, #xFFFFFFFF,
                                      #xFFFFFFFF, #xFFFFFFFF,
                                      #xF0F0F0F0, #xF0F0F0F0,
                                      #xF0F0F0F0, #xF0F0F0F0); ENDCASE
    CASE #71: andrelbits8v(rel, TABLE #xFFFFFFFF, #xFFFFFFFF,
                                      #xFFFFFFFF, #xFFFFFFFF,
                                      #xCCCCCCCC, #xCCCCCCCC,
                                      #xCCCCCCCC, #xCCCCCCCC); ENDCASE
    CASE #70: andrelbits8v(rel, TABLE #xFFFFFFFF, #xFFFFFFFF,
                                      #xFFFFFFFF, #xFFFFFFFF,
                                      #xAAAAAAAA, #xAAAAAAAA,
                                      #xAAAAAAAA, #xAAAAAAAA); ENDCASE

    CASE #67: rel!r_w2, rel!r_w3 := 0, 0;                      ENDCASE
    CASE #66:                                                  ENDCASE
    CASE #65: rel!r_w2, rel!r_w6 := 0, 0;                      ENDCASE
    CASE #64: andrelbits4(rel, #xFFFFFFFF, #xFFFFFFFF,
                               #xFFFF0000, #xFFFF0000);        ENDCASE
    CASE #63: andrelbits4(rel, #xFFFFFFFF, #xFFFFFFFF,
                               #xFF00FF00, #xFF00FF00);        ENDCASE
    CASE #62: andrelbits4(rel, #xFFFFFFFF, #xFFFFFFFF,
                               #xF0F0F0F0, #xF0F0F0F0);        ENDCASE
    CASE #61: andrelbits4(rel, #xFFFFFFFF, #xFFFFFFFF,
                               #xCCCCCCCC, #xCCCCCCCC);        ENDCASE
    CASE #60: andrelbits4(rel, #xFFFFFFFF, #xFFFFFFFF,
                               #xAAAAAAAA, #xAAAAAAAA);        ENDCASE

    CASE #57: rel!r_w1, rel!r_w3 := 0, 0;                      ENDCASE
    CASE #56: rel!r_w1, rel!r_w5 := 0, 0;                      ENDCASE
    CASE #55:                                                  ENDCASE
    CASE #54: andrelbits2(rel, #xFFFFFFFF, #xFFFF0000);        ENDCASE
    CASE #53: andrelbits2(rel, #xFFFFFFFF, #xFF00FF00);        ENDCASE
    CASE #52: andrelbits2(rel, #xFFFFFFFF, #xF0F0F0F0);        ENDCASE
    CASE #51: andrelbits2(rel, #xFFFFFFFF, #xCCCCCCCC);        ENDCASE
    CASE #50: andrelbits2(rel, #xFFFFFFFF, #xAAAAAAAA);        ENDCASE

    CASE #47: andrelbits8v(rel, TABLE #x0000FFFF, #x0000FFFF,
                                      #x0000FFFF, #x0000FFFF,
                                      #xFFFFFFFF, #xFFFFFFFF,
                                      #xFFFFFFFF, #xFFFFFFFF); ENDCASE
    CASE #46: andrelbits4(rel, #x0000FFFF, #x0000FFFF,
                               #xFFFFFFFF, #xFFFFFFFF);        ENDCASE
    CASE #45: andrelbits2(rel, #x0000FFFF, #xFFFFFFFF);        ENDCASE
    CASE #44:                                                  ENDCASE
    CASE #43: andrelbits1(rel, #xFF00FFFF);                    ENDCASE
    CASE #42: andrelbits1(rel, #xF0F0FFFF);                    ENDCASE
    CASE #41: andrelbits1(rel, #xCCCCFFFF);                    ENDCASE
    CASE #40: andrelbits1(rel, #xAAAAFFFF);                    ENDCASE

    CASE #37: andrelbits8v(rel, TABLE #x00FF00FF, #x00FF00FF,
                                      #x00FF00FF, #x00FF00FF,
                                      #xFFFFFFFF, #xFFFFFFFF,
                                      #xFFFFFFFF, #xFFFFFFFF); ENDCASE
    CASE #36: andrelbits4(rel, #x00FF00FF, #x00FF00FF,
                               #xFFFFFFFF, #xFFFFFFFF);        ENDCASE
    CASE #35: andrelbits2(rel, #x00FF00FF, #xFFFFFFFF);        ENDCASE
    CASE #34: andrelbits1(rel, #xFFFF00FF);                    ENDCASE
    CASE #33:                                                  ENDCASE
    CASE #32: andrelbits1(rel, #xF0FFF0FF);                    ENDCASE
    CASE #31: andrelbits1(rel, #xCCFFCCFF);                    ENDCASE
    CASE #30: andrelbits1(rel, #xAAFFAAFF);                    ENDCASE

    CASE #27: andrelbits8v(rel, TABLE #x0F0F0F0F, #x0F0F0F0F,
                                      #x0F0F0F0F, #x0F0F0F0F,
                                      #xFFFFFFFF, #xFFFFFFFF,
                                      #xFFFFFFFF, #xFFFFFFFF); ENDCASE
    CASE #26: andrelbits4(rel, #x0F0F0F0F, #x0F0F0F0F,
                               #xFFFFFFFF, #xFFFFFFFF);        ENDCASE
    CASE #25: andrelbits2(rel, #x0F0F0F0F, #xFFFFFFFF);        ENDCASE
    CASE #24: andrelbits1(rel, #xFFFF0F0F);                    ENDCASE
    CASE #23: andrelbits1(rel, #xFF0FFF0F);                    ENDCASE
    CASE #22:                                                  ENDCASE
    CASE #21: andrelbits1(rel, #XCFCFCFCF);                    ENDCASE
    CASE #20: andrelbits1(rel, #xAFAFAFAF);                    ENDCASE

    CASE #17: andrelbits8v(rel, TABLE #x33333333, #x33333333,
                                      #x33333333, #x33333333,
                                      #xFFFFFFFF, #xFFFFFFFF,
                                      #xFFFFFFFF, #xFFFFFFFF); ENDCASE
    CASE #16: andrelbits4(rel, #x33333333, #x33333333,
                               #xFFFFFFFF, #xFFFFFFFF);        ENDCASE
    CASE #15: andrelbits2(rel, #x33333333, #xFFFFFFFF);        ENDCASE
    CASE #14: andrelbits1(rel, #xFFFF3333);                    ENDCASE
    CASE #13: andrelbits1(rel, #xFF33FF33);                    ENDCASE
    CASE #12: andrelbits1(rel, #xF3F3F3F3);                    ENDCASE
    CASE #11:                                                  ENDCASE
    CASE #10: andrelbits1(rel, #xBBBBBBBB);                    ENDCASE

    CASE #07: andrelbits8v(rel, TABLE #x55555555, #x55555555,
                                      #x55555555, #x55555555,
                                      #xFFFFFFFF, #xFFFFFFFF,
                                      #xFFFFFFFF, #xFFFFFFFF); ENDCASE
    CASE #06: andrelbits4(rel, #x55555555, #x55555555,
                               #xFFFFFFFF, #xFFFFFFFF);        ENDCASE
    CASE #05: andrelbits2(rel, #x55555555, #xFFFFFFFF);        ENDCASE
    CASE #04: andrelbits1(rel, #xFFFF5555);                    ENDCASE
    CASE #03: andrelbits1(rel, #xFF55FF55);                    ENDCASE
    CASE #02: andrelbits1(rel, #xF5F5F5F5);                    ENDCASE
    CASE #01: andrelbits1(rel, #xDDDDDDDD);                    ENDCASE
    CASE #00:                                                  ENDCASE
  }
  wrrel(rel, TRUE)
}

// Apply  ai -> ~aj
// eg: R11010110(x,y,z) with y->~z gives R00010110(x,y,z)

// x 10101010
// y 11001100
// z 11110000

//   11010110 means xyz = 111 or 011 or 001 or 010 or 100
//   00010110 means xyz =               001 or 010 or 100
AND apimppn(rel, argi, argj) BE
{ LET v = @rel!r_a

  //newline()
  //wrrel(rel, TRUE)
  writef("apimppn: args %n %n*n", argi, argj)

  SWITCHON argi*8+argj INTO
  { DEFAULT:  ENDCASE  // an error

    CASE #77: rel!r_w4,rel!r_w5,rel!r_w6,rel!r_w7 := 0,0,0,0;  ENDCASE
    CASE #76: rel!r_w6, rel!r_w7 := 0, 0;                      ENDCASE
    CASE #75: rel!r_w5, rel!r_w7 := 0, 0;                      ENDCASE
    CASE #74: andrelbits8v(rel, TABLE #xFFFFFFFF, #xFFFFFFFF,
                                      #xFFFFFFFF, #xFFFFFFFF,
                                      #x0000FFFF, #x0000FFFF,
                                      #x0000FFFF, #x0000FFFF); ENDCASE
    CASE #73: andrelbits8v(rel, TABLE #xFFFFFFFF, #xFFFFFFFF,
                                      #xFFFFFFFF, #xFFFFFFFF,
                                      #x00FF00FF, #x00FF00FF,
                                      #x00FF00FF, #x00FF00FF); ENDCASE
    CASE #72: andrelbits8v(rel, TABLE #xFFFFFFFF, #xFFFFFFFF,
                                      #xFFFFFFFF, #xFFFFFFFF,
                                      #x0F0F0F0F, #x0F0F0F0F,
                                      #x0F0F0F0F, #x0F0F0F0F); ENDCASE
    CASE #71: andrelbits8v(rel, TABLE #xFFFFFFFF, #xFFFFFFFF,
                                      #xFFFFFFFF, #xFFFFFFFF,
                                      #x33333333, #x33333333,
                                      #x33333333, #x33333333); ENDCASE
    CASE #70: andrelbits8v(rel, TABLE #xFFFFFFFF, #xFFFFFFFF,
                                      #xFFFFFFFF, #xFFFFFFFF,
                                      #x55555555, #x55555555,
                                      #x55555555, #x55555555); ENDCASE

    CASE #67: rel!r_w6, rel!r_w7 := 0, 0;                      ENDCASE
    CASE #66: rel!r_w2,rel!r_w3,rel!r_w6,rel!r_w7 := 0,0,0,0;  ENDCASE
    CASE #65: rel!r_w3, rel!r_w7 := 0, 0;                      ENDCASE
    CASE #64: andrelbits4(rel, #xFFFFFFFF, #xFFFFFFFF,
                               #x0000FFFF, #x0000FFFF);        ENDCASE
    CASE #63: andrelbits4(rel, #xFFFFFFFF, #xFFFFFFFF,
                               #x00FF00FF, #x00FF00FF);        ENDCASE
    CASE #62: andrelbits4(rel, #xFFFFFFFF, #xFFFFFFFF,
                               #x0F0F0F0F, #x0F0F0F0F);        ENDCASE
    CASE #61: andrelbits4(rel, #xFFFFFFFF, #xFFFFFFFF,
                               #x33333333, #x33333333);        ENDCASE
    CASE #60: andrelbits4(rel, #xFFFFFFFF, #xFFFFFFFF,
                               #x55555555, #x55555555);        ENDCASE

    CASE #57: rel!r_w5, rel!r_w7 := 0, 0;                      ENDCASE
    CASE #56: rel!r_w3, rel!r_w7 := 0, 0;                      ENDCASE
    CASE #55: rel!r_w1,rel!r_w3,rel!r_w1,rel!r_w7 := 0,0,0,0;  ENDCASE
    CASE #54: andrelbits2(rel, #xFFFFFFFF, #x0000FFFF);        ENDCASE
    CASE #53: andrelbits2(rel, #xFFFFFFFF, #x00FF00FF);        ENDCASE
    CASE #52: andrelbits2(rel, #xFFFFFFFF, #x0F0F0F0F);        ENDCASE
    CASE #51: andrelbits2(rel, #xFFFFFFFF, #x33333333);        ENDCASE
    CASE #50: andrelbits2(rel, #xFFFFFFFF, #x55555555);        ENDCASE

    CASE #47: andrelbits8v(rel, TABLE #xFFFFFFFF, #xFFFFFFFF,
                                      #xFFFFFFFF, #xFFFFFFFF,
                                      #x0000FFFF, #x0000FFFF,
                                      #x0000FFFF, #x0000FFFF); ENDCASE
    CASE #46: andrelbits4(rel, #xFFFFFFFF, #xFFFFFFFF,
                               #x0000FFFF, #x0000FFFF);        ENDCASE
    CASE #45: andrelbits2(rel, #xFFFFFFFF, #x0000FFFF);        ENDCASE
    CASE #44: andrelbits1(rel, #xFFFF0000);                    ENDCASE
    CASE #43: andrelbits1(rel, #x00FFFFFF);                    ENDCASE
    CASE #42: andrelbits1(rel, #x0F0FFFFF);                    ENDCASE
    CASE #41: andrelbits1(rel, #x3333FFFF);                    ENDCASE
    CASE #40: andrelbits1(rel, #x5555FFFF);                    ENDCASE

    CASE #37: andrelbits8v(rel, TABLE #xFFFFFFFF, #xFFFFFFFF,
                                      #xFFFFFFFF, #xFFFFFFFF,
                                      #x00FF00FF, #x00FF00FF,
                                      #x00FF00FF, #x00FF00FF); ENDCASE
    CASE #36: andrelbits4(rel, #xFFFFFFFF, #xFFFFFFFF,
                               #x00FF00FF, #x00FF00FF);        ENDCASE
    CASE #35: andrelbits2(rel, #xFFFFFFFF, #x00FF00FF);        ENDCASE
    CASE #34: andrelbits1(rel, #x00FFFFFF);                    ENDCASE
    CASE #33: andrelbits1(rel, #xFF00FF00);                    ENDCASE
    CASE #32: andrelbits1(rel, #x0FFF0FFF);                    ENDCASE
    CASE #31: andrelbits1(rel, #x33FF33FF);                    ENDCASE
    CASE #30: andrelbits1(rel, #x55FF55FF);                    ENDCASE

    CASE #27: andrelbits8v(rel, TABLE #xFFFFFFFF, #xFFFFFFFF,
                                      #xFFFFFFFF, #xFFFFFFFF,
                                      #x0F0F0F0F, #x0F0F0F0F,
                                      #x0F0F0F0F, #x0F0F0F0F); ENDCASE
    CASE #26: andrelbits4(rel, #xFFFFFFFF, #xFFFFFFFF,
                               #x0F0F0F0F, #x0F0F0F0F);        ENDCASE
    CASE #25: andrelbits2(rel, #xFFFFFFFF, #x0F0F0F0F);        ENDCASE
    CASE #24: andrelbits1(rel, #x0F0FFFFF);                    ENDCASE
    CASE #23: andrelbits1(rel, #x0FFF0FFF);                    ENDCASE
    CASE #22: andrelbits1(rel, #XF0F0F0F0);                    ENDCASE
    CASE #21: andrelbits1(rel, #X3F3F3F3F);                    ENDCASE
    CASE #20: andrelbits1(rel, #x5F5F5F5F);                    ENDCASE

    CASE #17: andrelbits8v(rel, TABLE #xFFFFFFFF, #xFFFFFFFF,
                                      #xFFFFFFFF, #xFFFFFFFF,
                                      #x33333333, #x33333333,
                                      #x33333333, #x33333333); ENDCASE
    CASE #16: andrelbits4(rel, #xFFFFFFFF, #xFFFFFFFF,
                               #x33333333, #x33333333);        ENDCASE
    CASE #15: andrelbits2(rel, #xFFFFFFFF, #x33333333);        ENDCASE
    CASE #14: andrelbits1(rel, #x3333FFFF);                    ENDCASE
    CASE #13: andrelbits1(rel, #x33FF33FF);                    ENDCASE
    CASE #12: andrelbits1(rel, #x3F3F3F3F);                    ENDCASE
    CASE #11: andrelbits1(rel, #xCCCCCCCC);                    ENDCASE
    CASE #10: andrelbits1(rel, #x77777777);                    ENDCASE

    CASE #07: andrelbits8v(rel, TABLE #xFFFFFFFF, #xFFFFFFFF,
                                      #xFFFFFFFF, #xFFFFFFFF,
                                      #x55555555, #x55555555,
                                      #x55555555, #x55555555); ENDCASE
    CASE #06: andrelbits4(rel, #xFFFFFFFF, #xFFFFFFFF,
                               #x55555555, #x55555555);        ENDCASE
    CASE #05: andrelbits2(rel, #xFFFFFFFF, #x55555555);        ENDCASE
    CASE #04: andrelbits1(rel, #x5555FFFF);                    ENDCASE
    CASE #03: andrelbits1(rel, #x55FF55FF);                    ENDCASE
    CASE #02: andrelbits1(rel, #x5F5F5F5F);                    ENDCASE
    CASE #01: andrelbits1(rel, #x77777777);                    ENDCASE
    CASE #00: andrelbits1(rel, #xAAAAAAAA);                    ENDCASE
  }
  wrrel(rel, TRUE)
}


// Apply ~ai -> aj
// eg: R11010110(x,y,z) with ~y->z gives R11010010(x,y,z)

// x 10101010
// y 11001100
// z 11110000

//   11010110 means xyz = 111 or 011 or 001 or 010 or 100
//   11010010 means xyz = 111 or 011 or 001        or 100
AND apimpnp(rel, argi, argj) BE
{ LET v = @rel!r_a

  //newline()
  //wrrel(rel, TRUE)
  writef("apimpnp: args %n %n*n", argi, argj)

  SWITCHON argi*8+argj INTO
  { DEFAULT:  ENDCASE  // an error

    CASE #77: rel!r_w0,rel!r_w1,rel!r_w2,rel!r_w3 := 0,0,0,0;  ENDCASE
    CASE #76: rel!r_w0, rel!r_w1 := 0, 0;                      ENDCASE
    CASE #75: rel!r_w0, rel!r_w2 := 0, 0;                      ENDCASE
    CASE #74: andrelbits8v(rel, TABLE #xFFFF0000, #xFFFF0000,
                                      #xFFFF0000, #xFFFF0000,
                                      #xFFFFFFFF, #xFFFFFFFF,
                                      #xFFFFFFFF, #xFFFFFFFF); ENDCASE
    CASE #73: andrelbits8v(rel, TABLE #xFF00FF00, #xFF00FF00,
                                      #xFF00FF00, #xFF00FF00,
                                      #xFFFFFFFF, #xFFFFFFFF,
                                      #xFFFFFFFF, #xFFFFFFFF); ENDCASE
    CASE #72: andrelbits8v(rel, TABLE #xF0F0F0F0, #xF0F0F0F0,
                                      #xF0F0F0F0, #xF0F0F0F0,
                                      #xFFFFFFFF, #xFFFFFFFF,
                                      #xFFFFFFFF, #xFFFFFFFF); ENDCASE
    CASE #71: andrelbits8v(rel, TABLE #xCCCCCCCC, #xCCCCCCCC,
                                      #xCCCCCCCC, #xCCCCCCCC,
                                      #xFFFFFFFF, #xFFFFFFFF,
                                      #xFFFFFFFF, #xFFFFFFFF); ENDCASE
    CASE #70: andrelbits8v(rel, TABLE #xAAAAAAAA, #xAAAAAAAA,
                                      #xAAAAAAAA, #xAAAAAAAA,
                                      #xFFFFFFFF, #xFFFFFFFF,
                                      #xFFFFFFFF, #xFFFFFFFF); ENDCASE

    CASE #67: rel!r_w0, rel!r_w1 := 0, 0;                      ENDCASE
    CASE #66: rel!r_w0,rel!r_w1,rel!r_w4,rel!r_w5 := 0,0,0,0;  ENDCASE
    CASE #65: rel!r_w0, rel!r_w4 := 0, 0;                      ENDCASE
    CASE #64: andrelbits4(rel, #xFFFF0000, #xFFFF0000,
                               #xFFFFFFFF, #xFFFFFFFF);        ENDCASE
    CASE #63: andrelbits4(rel, #xFF00FF00, #xFF00FF00,
                               #xFFFFFFFF, #xFFFFFFFF);        ENDCASE
    CASE #62: andrelbits4(rel, #xF0F0F0F0, #xF0F0F0F0,
                               #xFFFFFFFF, #xFFFFFFFF);        ENDCASE
    CASE #61: andrelbits4(rel, #xCCCCCCCC, #xCCCCCCCC,
                               #xFFFFFFFF, #xFFFFFFFF);        ENDCASE
    CASE #60: andrelbits4(rel, #xAAAAAAAA, #xAAAAAAAA,
                               #xFFFFFFFF, #xFFFFFFFF);        ENDCASE

    CASE #57: rel!r_w1, rel!r_w3 := 0, 0;                      ENDCASE
    CASE #56: rel!r_w0, rel!r_w4 := 0, 0;                      ENDCASE
    CASE #55: rel!r_w0,rel!r_w2,rel!r_w4,rel!r_w6 := 0,0,0,0;  ENDCASE
    CASE #54: andrelbits2(rel, #xFFFF0000, #xFFFFFFFF);        ENDCASE
    CASE #53: andrelbits2(rel, #xFF00FF00, #xFFFFFFFF);        ENDCASE
    CASE #52: andrelbits2(rel, #xF0F0F0F0, #xFFFFFFFF);        ENDCASE
    CASE #51: andrelbits2(rel, #xCCCCCCCC, #xFFFFFFFF);        ENDCASE
    CASE #50: andrelbits2(rel, #xAAAAAAAA, #xFFFFFFFF);        ENDCASE

    CASE #47: andrelbits8v(rel, TABLE #xFFFF0000, #xFFFF0000,
                                      #xFFFF0000, #xFFFF0000,
                                      #xFFFFFFFF, #xFFFFFFFF,
                                      #xFFFFFFFF, #xFFFFFFFF); ENDCASE
    CASE #46: andrelbits4(rel, #xFFFF0000, #xFFFF0000,
                               #xFFFFFFFF, #xFFFFFFFF);        ENDCASE
    CASE #45: andrelbits2(rel, #xFFFF0000, #xFFFFFFFF);        ENDCASE
    CASE #44: andrelbits1(rel, #x0000FFFF);                    ENDCASE
    CASE #43: andrelbits1(rel, #xFFFFFF00);                    ENDCASE
    CASE #42: andrelbits1(rel, #xFFFFF0F0);                    ENDCASE
    CASE #41: andrelbits1(rel, #xFFFFCCCC);                    ENDCASE
    CASE #40: andrelbits1(rel, #xFFFFAAAA);                    ENDCASE

    CASE #37: andrelbits8v(rel, TABLE #xFF00FF00, #xFF00FF00,
                                      #xFF00FF00, #xFF00FF00,
                                      #xFFFFFFFF, #xFFFFFFFF,
                                      #xFFFFFFFF, #xFFFFFFFF); ENDCASE
    CASE #36: andrelbits4(rel, #xFF00FF00, #xFF00FF00,
                               #xFFFFFFFF, #xFFFFFFFF);        ENDCASE
    CASE #35: andrelbits2(rel, #xFF00FF00, #xFFFFFFFF);        ENDCASE
    CASE #34: andrelbits1(rel, #xFFFFFF00);                    ENDCASE
    CASE #33: andrelbits1(rel, #x00FF00FF);                    ENDCASE
    CASE #32: andrelbits1(rel, #xFFF0FFF0);                    ENDCASE
    CASE #31: andrelbits1(rel, #xFFCCFFCC);                    ENDCASE
    CASE #30: andrelbits1(rel, #xFFAAFFAA);                    ENDCASE

    CASE #27: andrelbits8v(rel, TABLE #xF0F0F0F0, #xF0F0F0F0,
                                      #xF0F0F0F0, #xF0F0F0F0,
                                      #xFFFFFFFF, #xFFFFFFFF,
                                      #xFFFFFFFF, #xFFFFFFFF); ENDCASE
    CASE #26: andrelbits4(rel, #xF0F0F0F0, #xF0F0F0F0,
                               #xFFFFFFFF, #xFFFFFFFF);        ENDCASE
    CASE #25: andrelbits2(rel, #xF0F0F0F0, #xFFFFFFFF);        ENDCASE
    CASE #24: andrelbits1(rel, #xFFFFF0F0);                    ENDCASE
    CASE #23: andrelbits1(rel, #xFFF0FFF0);                    ENDCASE
    CASE #22: andrelbits1(rel, #X0F0F0F0F);                    ENDCASE
    CASE #21: andrelbits1(rel, #XFCFCFCFC);                    ENDCASE
    CASE #20: andrelbits1(rel, #xFAFAFAFA);                    ENDCASE

    CASE #17: andrelbits8v(rel, TABLE #xCCCCCCCC, #xCCCCCCCC,
                                      #xCCCCCCCC, #xCCCCCCCC,
                                      #xFFFFFFFF, #xFFFFFFFF,
                                      #xFFFFFFFF, #xFFFFFFFF); ENDCASE
    CASE #16: andrelbits4(rel, #xCCCCCCCC, #xCCCCCCCC,
                               #xFFFFFFFF, #xFFFFFFFF);        ENDCASE
    CASE #15: andrelbits2(rel, #xCCCCCCCC, #xFFFFFFFF);        ENDCASE
    CASE #14: andrelbits1(rel, #xFFFFCCCC);                    ENDCASE
    CASE #13: andrelbits1(rel, #xFFCCFFCC);                    ENDCASE
    CASE #12: andrelbits1(rel, #xFCFCFCFC);                    ENDCASE
    CASE #11: andrelbits1(rel, #x33333333);                    ENDCASE
    CASE #10: andrelbits1(rel, #xEEEEEEEE);                    ENDCASE

    CASE #07: andrelbits8v(rel, TABLE #xAAAAAAAA, #xAAAAAAAA,
                                      #xAAAAAAAA, #xAAAAAAAA,
                                      #xFFFFFFFF, #xFFFFFFFF,
                                      #xFFFFFFFF, #xFFFFFFFF); ENDCASE
    CASE #06: andrelbits4(rel, #xAAAAAAAA, #xAAAAAAAA,
                               #xFFFFFFFF, #xFFFFFFFF);        ENDCASE
    CASE #05: andrelbits2(rel, #xAAAAAAAA, #xFFFFFFFF);        ENDCASE
    CASE #04: andrelbits1(rel, #xFFFFAAAA);                    ENDCASE
    CASE #03: andrelbits1(rel, #xFFAAFFAA);                    ENDCASE
    CASE #02: andrelbits1(rel, #xFAFAFAFA);                    ENDCASE
    CASE #01: andrelbits1(rel, #xEEEEEEEE);                    ENDCASE
    CASE #00: andrelbits1(rel, #x55555555);                    ENDCASE
  }
  wrrel(rel, TRUE)
}


// Apply: ~ai -> ~aj
// eg: R11010110(x,y,z) with ~y->~z gives R11010010(x,y,z)

// x 10101010
// y 11001100
// z 11110000

//   11010110 means xyz = 111 or 011 or 001 or 010 or 100
//   11000110 means xyz = 111 or 011        or 010 or 100
AND apimpnn(rel, argi, argj) BE apimppp(rel, argj, argi)

AND setunconstrainedarg(rel, argi) BE
{ // This is used by combine when adding a new variable to a relation
  SWITCHON argi INTO
  { CASE 0: rel!r_w0 := (rel!r_w0 & #x55555555) * #x00000003 
            rel!r_w1 := (rel!r_w1 & #x55555555) * #x00000003
            rel!r_w2 := (rel!r_w2 & #x55555555) * #x00000003 
            rel!r_w3 := (rel!r_w3 & #x55555555) * #x00000003
            rel!r_w4 := (rel!r_w4 & #x55555555) * #x00000003
            rel!r_w5 := (rel!r_w5 & #x55555555) * #x00000003
            rel!r_w6 := (rel!r_w6 & #x55555555) * #x00000003
            rel!r_w7 := (rel!r_w7 & #x55555555) * #x00000003
            RETURN
    CASE 1: rel!r_w0 := (rel!r_w0 & #x33333333) * #x00000005 
            rel!r_w1 := (rel!r_w1 & #x33333333) * #x00000005 
            rel!r_w2 := (rel!r_w2 & #x33333333) * #x00000005 
            rel!r_w3 := (rel!r_w3 & #x33333333) * #x00000005 
            rel!r_w4 := (rel!r_w4 & #x33333333) * #x00000005 
            rel!r_w5 := (rel!r_w5 & #x33333333) * #x00000005 
            rel!r_w6 := (rel!r_w6 & #x33333333) * #x00000005 
            rel!r_w7 := (rel!r_w7 & #x33333333) * #x00000005 
            RETURN
    CASE 2: rel!r_w0 := (rel!r_w0 & #x0F0F0F0F) * #x00000011 
            rel!r_w1 := (rel!r_w1 & #x0F0F0F0F) * #x00000011 
            rel!r_w2 := (rel!r_w2 & #x0F0F0F0F) * #x00000011 
            rel!r_w3 := (rel!r_w3 & #x0F0F0F0F) * #x00000011 
            rel!r_w4 := (rel!r_w4 & #x0F0F0F0F) * #x00000011 
            rel!r_w5 := (rel!r_w5 & #x0F0F0F0F) * #x00000011 
            rel!r_w6 := (rel!r_w6 & #x0F0F0F0F) * #x00000011 
            rel!r_w7 := (rel!r_w7 & #x0F0F0F0F) * #x00000011 
            RETURN
    CASE 3: rel!r_w0 := (rel!r_w0 & #x00FF00FF) * #x00000101 
            rel!r_w1 := (rel!r_w1 & #x00FF00FF) * #x00000101 
            rel!r_w2 := (rel!r_w2 & #x00FF00FF) * #x00000101 
            rel!r_w3 := (rel!r_w3 & #x00FF00FF) * #x00000101 
            rel!r_w4 := (rel!r_w4 & #x00FF00FF) * #x00000101 
            rel!r_w5 := (rel!r_w5 & #x00FF00FF) * #x00000101 
            rel!r_w6 := (rel!r_w6 & #x00FF00FF) * #x00000101 
            rel!r_w7 := (rel!r_w7 & #x00FF00FF) * #x00000101 
            RETURN
    CASE 4: rel!r_w0 := (rel!r_w0 & #x0000FFFF) * #x00010001 
            rel!r_w1 := (rel!r_w1 & #x0000FFFF) * #x00010001 
            rel!r_w2 := (rel!r_w2 & #x0000FFFF) * #x00010001 
            rel!r_w3 := (rel!r_w3 & #x0000FFFF) * #x00010001 
            rel!r_w4 := (rel!r_w4 & #x0000FFFF) * #x00010001 
            rel!r_w5 := (rel!r_w5 & #x0000FFFF) * #x00010001 
            rel!r_w6 := (rel!r_w6 & #x0000FFFF) * #x00010001 
            rel!r_w7 := (rel!r_w7 & #x0000FFFF) * #x00010001 
            RETURN
    CASE 5: rel!r_w1 := rel!r_w0
            rel!r_w3 := rel!r_w2
            rel!r_w5 := rel!r_w4
            rel!r_w7 := rel!r_w6
            RETURN
    CASE 6: rel!r_w2 := rel!r_w0
            rel!r_w3 := rel!r_w1
            rel!r_w6 := rel!r_w4
            rel!r_w7 := rel!r_w5
            RETURN
    CASE 7: rel!r_w4 := rel!r_w0
            rel!r_w5 := rel!r_w1
            rel!r_w6 := rel!r_w2
            rel!r_w7 := rel!r_w3
            RETURN
  }
}

AND sortargs(rel) BE
{ LET v = @rel!r_a
//wrrel(rel, TRUE)
//sawritef("sortargs:  Sorting arguments into decreasing order*n")

  // Sort arguments into decreasing order
  FOR argi = 0 TO 6 DO
  { LET k = argi // Will be the position of the largest identifier
    FOR argj = argi+1 TO 7 IF v!k < v!argj DO k := argj
    // k is the argument number of the largest remaining variable
    // swap i with k if necessary
    UNLESS k=argi DO
    {
//sawritef("sortargs:  Swapping arg%n with arg%n*n", argi, k)
      exchargs(rel, argi, k)
    }
  }
//wrrel(rel, TRUE)
}

AND combine(rel1, rel2) = VALOF
// Tries to combine rel1 and rel2, returning TRUE if successful.
{ LET vars1 = @rel1!r_a
  LET vars2 = @rel2!r_a
  LET v = VEC 7  // For the variables in both rel1 and rel2
  LET n = 0      // Count of variables in common
  LET i, j = 0, 0
  LET id1, id2 = vars1!i, vars2!j
  //writef("combine: Trying to combine the following relations*n")
  //wrrel(rel1, TRUE)
  //wrrel(rel2, TRUE)

  // Collect the shared variables in v
  { LET max = id1>id2 -> id1, id2
    IF id1=0 | id2=0 BREAK // There can be no more shared variables
    IF id1=id2 DO
    { v!n := id1 // A shared variable has been found
      n := n+1
    }
    IF id1=max DO
    { i := i+1
      id1 := i>7 -> 0, vars1!i
    }
    IF id2=max DO
    { j := j+1
      id2 := j>7 -> 0, vars2!j
    }
  } REPEAT

  i := rel1!r_args
  j := rel2!r_args

  //writef("combine: i=%n j=%n vars=%n n=%n", i, j, i+j-n, n)
  //FOR a = 0 TO n-1 DO writef(" v%n", origid(v!a))
  //newline()
  IF i+j-n<=8 DO
  { // The relations can be combined.
    // rel1 will be the combined relation and rel2 will be deleted.
    // idvecs will be updated appropriately
    //writef("combine: the relations can be combined*n")

    // First add variables from rel2 into rel1.
    FOR argj = 0 TO rel2!r_args-1 DO
    { LET id = vars2!argj
      //writef("combine: v%n is in relation %n*n", origid(id), rel2!r_relno)
      IF invec(id, v, n) DO
      { // This variables was already in rel1 so just remove its
        // reference to rel2.
        FOR p = idvecs!id TO idvecs!(id+1)-1 DO
          IF !p=rel2 DO !p := 0
        idcountv!id := idcountv!id - 1
        LOOP
      }
      // The variable was not in rel1 so add it to rel1.
      FOR p = idvecs!id TO idvecs!(id+1)-1 DO
        IF !p=rel2 DO !p := rel1
      vars1!i := id
      setunconstrainedarg(rel1, i)
      i := i+1
    //  writef("combine: added v%n to relation %n*n", origid(id), rel1!r_relno)
    //  wrrel(rel1, TRUE)
    //  abort(5555) 
    }

    // Now add variables from rel1 into rel2.
    FOR argi = 0 TO rel1!r_args-1 DO
    { LET id = vars1!argi
      //writef("combine: v%n is in relation %n*n", origid(id), rel1!r_relno)
      IF invec(id, v, n) DO
      { // This variables was already in rel2 so do nothing.
        LOOP
      }
      // The variable was not in rel2 so add it.
      vars2!j := id
      setunconstrainedarg(rel2, j)
      j := j+1
      //writef("combine: added v%n to relation %n*n", origid(id), rel2!r_relno)
      //abort(5556) 
    }
    rel1!r_args := i
    rel2!r_args := j
    sortargs(rel1)
    sortargs(rel2)
    // 'and' relation bits of rel2 into rel1.
    SWITCHON i INTO
    { CASE 8: rel1!r_w7 := rel1!r_w7 & rel2!r_w7
              rel1!r_w6 := rel1!r_w6 & rel2!r_w6
              rel1!r_w5 := rel1!r_w5 & rel2!r_w5
              rel1!r_w4 := rel1!r_w4 & rel2!r_w4
      CASE 7: rel1!r_w3 := rel1!r_w3 & rel2!r_w3
              rel1!r_w2 := rel1!r_w2 & rel2!r_w2
      CASE 6: rel1!r_w1 := rel1!r_w1 & rel2!r_w1
      CASE 5:
      CASE 4:
      CASE 3:
      CASE 2:
      CASE 1:
      CASE 0: rel1!r_w0 := rel1!r_w0 & rel2!r_w0
    }
    rel2!r_deleted := TRUE
    writef("combine: relations %n and %n give:*n", rel1!r_relno, rel2!r_relno)
    wrrel(rel1, TRUE)
    wrrel(rel2, TRUE)
    //wrvars()
abort(6666)
    RESULTIS TRUE // Successfuly combined
  }
  RESULTIS FALSE // Relations not combined
}
.

// The apply newly discovered information about a variable
// or a pair of variables

// These apply to all relations

// ignorevar(rel, i)   vi is used only once so can be eliminated

// apvarset1(i)        apply  vi  =   1 and eliminate vi
// apvarset0(i)        apply  vi  =   0 and eliminate vi

// apvareq(i, j)       apply  vi  =  vj and eliminate vj, i<j
// apvarne(i, j)       apply  vi  = ~vj and eliminate vj, i<j

// apvarimppp(i, j)    apply  vi ->  vj
// apvarimppn(i, j)    apply  ai -> ~vj
// apvarimpnp(i, j)    apply  vi ->  vj
// apvarimpnn(i, j)    apply ~vi -> ~vj

SECTION "apvar"

GET "libhdr"
GET "chk8.h"

LET ignorevar(id) BE
{ // id is used only once and so can be eliminated
  FOR p = idvecs!id TO idvecs!(id+1)-1 DO
  { LET rel = !p // Either zero or the relation using id.
    IF rel DO
    { LET v = @rel!r_a
      LET argi = 0
      !p := 0
wrrel(rel)
writef("ignorevar: ignoring v%n*n", origid(id))
      WHILE argi<=7 DO
      { IF v!argi=id DO
        { // Set varfinfo!id to
          //   0     if rel forces id to be 0
          //   1     if rel forces id to be 1
          //  -2     otherwise (= don't care or inconsistent).
          varinfo!id := ignorearg(rel, argi)
          // Shuffle the later arguments down
          FOR argj = argi TO 6 IF v!(argj+1) DO
            exchargs(rel, argj, argj+1)
          LOOP
        }
        argi := argi+1
      }
      rel!r_args := rel!r_args - 1 // One argument has gone
      pushrel(rel)  // This relation has changed
      wrrel(rel, TRUE)
    }
  }
  idcountv!id := 0
abort(2222)
}

LET apvarset1(id) BE
{ // Set the varinfo entry for id,
  // remove id from every relation using it
  // and push the relation onto the stack if it is not already there.

  writef("apvarset1: v%n = 1*n", origid(id))
  varinfo!id := 1  // Remember that vi=1

  // Find and eliminate all occurrences of vi
  FOR p = idvecs!id TO idvecs!(id+1)-1 DO
  { LET rel = !p
    !p := 0         // id is being removed from rel
//writef("apvarset1: v%n is used in:*n", origid(id))
//wrrel(rel, TRUE)

    IF rel DO
    { LET v = @rel!r_a
      FOR argi = 0 TO 7 IF id=v!argi DO
      { // Remove the argument variable
        v!argi := 0
        //wrrel(rel, TRUE)
        // Modify the relation bit pattern
        apset1(rel, argi)
        // Shift down the remaining arguments
        WHILE argi<7 & v!(argi+1) DO
        { exchargs(rel, argi, argi+1)
          argi := argi+1
        }
        // Decrement the number of arguments
        rel!r_args := rel!r_args-1
        // Ensure this relation is on the stack
        pushrel(rel)
        BREAK
      }
    }
// wrrel(rel, TRUE)
  }
  idcountv!id := 0
//  wrvars()
}

AND apvarset0(id) BE
{ // Set the varinfo entry for id, ie varinfo!id := 0
  // Push every relation using id onto the stack, if it is not already there.

  writef("apvarset0: v%n = 0*n", origid(id))
  varinfo!id := 0  // Remember that vi=0

  // Find and eliminate all occurrences of vi
  FOR p = idvecs!id TO idvecs!(id+1)-1 DO
  { LET rel = !p
    !p := 0         // id will soon be removed from rel
//writef("apvarset0: v%n is used in:*n", origid(id))
//wrrel(rel, TRUE)

    IF rel UNLESS rel!r_deleted DO
    { //LET v = @rel!r_a
      pushrel(rel)
      //FOR argi = 0 TO 7 IF id=v!argi DO
      //{ // Remove the argument variable
        //wrrel(rel, TRUE)
        //v!argi := 0
        // Modify the relation bit pattern
        //apset0(rel, argi)
        // Shift down the remaining arguments
        //WHILE argi<7 & v!(argi+1) DO
        //{ exchargs(rel, argi, argi+1)
        //  argi := argi+1
        //}
        // Decrement the number of arguments
        //rel!r_args := rel!r_args-1
        // Ensure this relation is on the stack
        //pushrel(rel)
        //sawritef("apvarset0: after setting v%n=0*n", origid(id))
        //wrrel(rel, TRUE)
        //BREAK
      //}
    }
// wrrel(rel, TRUE)
  }
  idcountv!id := 0
//  wrvars()
}

AND apvareq(i, j) BE
{ // Assume i<j
  // For every relation involving vi and vj
  // set vj=vi and remove vj from the relation
  // and push the relation onto the stack if it is not already there.
  LET rl = idvecs!i
writef("apvareq: v%n =  v%n*n", origid(i), origid(j))

  varinfo!i := 2*j  // Remember that vi=vj

  WHILE FALSE & rl DO
  { // rl -> [argno, next, prev, rel]
    LET rel = rl!1
    LET v = @rel!r_a
    LET a, b = 7, 7
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
  idcountv!j := 0
}

AND apvarne(i, j) BE
{ // Assume i<j
  // For every relation involving vi and vj
  // set vj=~vi and remove vj from the relation
  // and push the relation onto the stack if it is not already there.
  LET rl = idvecs!i
writef("apvarne: v%n =  v%n*n", origid(i), origid(j))

  varinfo!i := 2*j + 1  // Remember that vi = ~vj

  WHILE FALSE & rl DO
  { // rl -> [argno, next, prev, rel]
    LET rel = rl!1
    LET v = @rel!r_a
    LET a, b = 7, 7
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
  idcountv!j := 0
}

AND apvarimppp(i, j) BE
{ // Assume i<j
  // For every relation involving vi and vj
  // impose the constraint vi->vj
  // and push the relation onto the stack if it is not already there.
  LET rl = idvecs!i
writef("apvarimppp:  v%n ->  v%n*n", origid(i), origid(j))

  RETURN
  WHILE rl DO
  { // rl -> [argno, next, prev, rel]
    LET rel = rl!1
    LET v = @rel!r_a
    LET a, b = 7, 7
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
  idcountv!j := 0
abort(3333)
}


AND apvarimppn(i, j) BE
{ // Assume i<j
  // For every relation involving vi and vj
  // impose the constraint vi->~vj
  // and push the relation onto the stack if it is not already there.
writef("apvarimppn:  v%n -> ~v%n*n", origid(i), origid(j))
//  abort(8888)
  RETURN
}

AND apvarimpnp(i, j) BE
{ // Assume i<j
  // For every relation involving vi and vj
  // impose the constraint ~vi->vj
  // and push the relation onto the stack if it is not already there.
writef("apvarimpnp: ~v%n ->  v%n*n", origid(i), origid(j))
//  abort(8888)
  RETURN
}

AND apvarimpnn(i, j) BE
{ // Assume i<j
  // For every relation involving vi and vj
  // impose the constraint ~vi->~vj
  // and push the relation onto the stack if it is not already there.
writef("apvarimpnn: ~v%n -> ~v%n*n", origid(i), origid(j))
//  abort(8888)
  RETURN
}

.

// Tests on relations chk8

SECTION "relimps"

GET "libhdr"
GET "chk8.h"

MANIFEST {
  upb = 32*256*4-1 // 32 byte positions, 256 byte values
                   // 4 words of implication bit patterns
}

LET setimptab() BE
{ imptab := getvec(upb)

  UNLESS imptab DO
  { writef("Cannot allocate %n words for imptab*n", upb)
    abort(999)
    RETURN
  }

  FOR i = 0 TO upb DO
    imptab!i := #b_1111111_111111_11111_1111_111_11_1
//                 hhhhhhh gggggg fffff eeee ddd cc b
//                 gfedcba fedcba edcba dcba cba ba a
  FOR h = 0 TO 1
    FOR g = 0 TO 1
      FOR f = 0 TO 1
        FOR e = 0 TO 1
          FOR d = 0 TO 1 DO
          { LET bytepos = d + 2*e + 4*f + 8*g + 16*h
            LET subtab = imptab + bytepos*256*4
//sawritef("bytepos=%i2*n", bytepos)
            // Fill in the sub table for all possible
            // byte values as position bytepos.
            FOR byte = 0 TO 255 DO
            { LET p = subtab+4*byte
              FOR c = 0 TO 1 FOR b = 0 TO 1 FOR a = 0 TO 1 DO
              { LET pos = a + 2*b +4*c
                LET bit = (byte>>pos) & 1
                IF bit DO
                { // abcdefgh is a valid setting of the arguments.
                  // Note that, if g=1 and c=0 then g->c is not true
                  // so we clear the gc bit (bit 17) of the pp bit
                  // pattern (p!0). Similarly, if g=1 and c=1 then
                  // g->~c is not true so we clear the gc bit (17)
                  // of the pn bit pattern (p!1). The np and nn bit
                  // patterns are in p!2 and p!3,
//sawritef("bytepos=%i2 pos=%n byte=%b8*n", bytepos, pos, byte)
                  setimps( 0, b, a, p)
                  setimps( 1, c, a, p)
                  setimps( 2, c, b, p)
                  setimps( 3, d, a, p)
                  setimps( 4, d, b, p)
                  setimps( 5, d, c, p)
                  setimps( 6, e, a, p)
                  setimps( 7, e, b, p)
                  setimps( 8, e, c, p)
                  setimps( 9, e, d, p)
                  setimps(10, f, a, p)
                  setimps(11, f, b, p)
                  setimps(12, f, c, p)
                  setimps(13, f, d, p)
                  setimps(14, f, e, p)
                  setimps(15, g, a, p)
                  setimps(16, g, b, p)
                  setimps(17, g, c, p)
                  setimps(18, g, d, p)
                  setimps(19, g, e, p)
                  setimps(20, g, f, p)
                  setimps(21, h, a, p)
                  setimps(22, h, b, p)
                  setimps(23, h, c, p)
                  setimps(24, h, d, p)
                  setimps(25, h, e, p)
                  setimps(26, h, f, p)
                  setimps(27, h, g, p)
                }
              }
            }
          }
}

AND setimps(bitno, x, y, p) BE
{ LET mask = ~(1<<bitno)
//sawritef("setimp: bitno=%i2 x=%n y=%n p=%n*n", bitno, x, y, p)
//abort(1000)
  TEST x
  THEN TEST y
       THEN p!1 := p!1 & mask // xy=11 so disallow  x -> ~y
       ELSE p!0 := p!0 & mask // xy=10 so disallow  x ->  y
  ELSE TEST y
       THEN p!3 := p!3 & mask // xy=01 so disallow ~x -> ~y
       ELSE p!2 := p!2 & mask // xy=00 so disallow ~x ->  y
  IF FALSE DO
  { primps(p)
    abort(1000)
  }
}

// Discover all the relations of the form 
// vi -> vj, vi->~vj, ~vi->vj and ~vi->~vj
// implied by relation rel. For any such discovery it calls
// bm_imppp(vi, vj), bm_imppp(vi, vj), bm_imppp(vi, vj)
// bm_impnn(vi, vj).

AND findimps(rel, impv) BE
// rel need not be in standard form, ie the variables can be
// in any order and any may be zero.
// Put the implication bits implied by this relation
// in impv!0, impv!1, impv!2 and impv!3
{ LET bits = @rel!r_w0
  LET all = #b_1111111_111111_11111_1111_111_11_1
  LET a = all  // The pp bits --   x ->  y
  LET b = all  // The pn bits --   x -> ~y
  LET c = all  // The np bits --  ~x ->  y
  LET d = all  // The nn bits --  ~x -> ~y

  // bit  0  = 1 if a1->a0 is possible and a1 and a0 are non zero 

  // bit  1  = 1 if a2->a0 is possible 
  // bit  2  = 1 if a2->a1 is possible 

  // bit  3  = 1 if a3->a0 is possible 
  // bit  4  = 1 if a3->a1 is possible 
  // bit  5  = 1 if a3->a2 is possible 

  // ..

  // bit  21  = 1 if a7->a0 is possible 
  // bit  22  = 1 if a7->a1 is possible 
  // bit  23  = 1 if a7->a2 is possible 
  // bit  24  = 1 if a7->a3 is possible 
  // bit  25  = 1 if a7->a4 is possible 
  // bit  26  = 1 if a7->a5 is possible 
  // bit  27  = 1 if a7->a6 is possible

  // The implication table consists of 32 subtables each
  // holding 256 entries of 4 words.

  FOR i = 0 TO 7 DO
  { LET word = bits!i  // Get next word from the relation bit pattern
    LET subtab = imptab + i*16*256
    IF word DO         // Are any bits set in the next 4 bytes
    { LET byte = word&255
      IF byte DO
      { LET p = subtab + byte*4 
        a := a & p!0
        b := b & p!1
        c := c & p!2
        d := d & p!3
//writef("byte=%b8 at bytepos=%n*n", byte, 4*i+0)
//writef("So ANDing with*n")
//primps(p)
//writef("giving*n")
//primps(@a)
//newline()
      }
      byte := (word>>8)&255
      IF byte DO
      { LET p = subtab + 4*256 + byte*4 
        a := a & p!0
        b := b & p!1
        c := c & p!2
        d := d & p!3
//writef("byte=%b8 at bytepos=%n*n", byte, 4*i+1)
//writef("So ANDing with*n")
//primps(p)
//writef("giving*n")
//primps(@a)
//newline()
      }
      byte := (word>>16)&255
      IF byte DO
      { LET p = subtab + 8*256 + byte*4 
        a := a & p!0
        b := b & p!1
        c := c & p!2
        d := d & p!3
//writef("byte=%b8 at bytepos=%n*n", byte, 4*i+2)
//writef("So ANDing with*n")
//primps(p)
//writef("giving*n")
//primps(@a)
//newline()
      }
      byte := (word>>24)&255
      IF byte DO
      { LET p = subtab + 12*256 + byte*4 
        a := a & p!0
        b := b & p!1
        c := c & p!2
        d := d & p!3
//writef("byte=%b8 at bytepos=%n*n", byte, 4*i+3)
//writef("So ANDing with*n")
//primps(p)
//writef("giving*n")
//primps(@a)
//newline()
      }
    }
  } 

ret:
  impv!0, impv!1, impv!2, impv!3 := a, b, c, d

  //wrrel(rel, TRUE)
  //writef("findimps: found the following implication bits*n")
  //primps(impv)
  //abort(1000)
}

AND primps(p) BE
{ LET a, b, c, d = p!0, p!1, p!2, p!3
  writef("p->p: %b7 %b6 %b5 %b4 %b3 %b2 %b1*n",
          a>>21, a>>15, a>>10, a>>6, a>>3, a>>1, a)
  writef("p->n: %b7 %b6 %b5 %b4 %b3 %b2 %b1*n",
          b>>21, b>>15, b>>10, b>>6, b>>3, b>1, b)
  writef("n->p: %b7 %b6 %b5 %b4 %b3 %b2 %b1*n",
          c>>21, c>>15, c>>10, c>>6, c>>3, c>>1, c)
  writef("n->n: %b7 %b6 %b5 %b4 %b3 %b2 %b1*n",
          d>>21, d>>15, d>>10, d>>6, d>>3, d>>1, d)
}


// Attempts to factorise a relation over 6 or more variables into
// the conjunction of two relations one of which is over 3 variables.
// If successful it returns TRUE and permutes the variables
// so that one of the factors is over variables v0, v1 and v2.
// The bit pattern then consists of 32 sub-bit patterns each of
// length 8 that are each either zero or equal to the same non zero
// value.
// If a relation can be factorised, it can be usefully split into
// two independent relations.
AND factor3(rel) = VALOF
{
  RESULTIS FALSE
}

// Attempts to factorise a relation over 8 variables into
// the conjunction of two relations over 4 variables.
// If successful it returns TRUE and permutes the variables
// so that one of the factors is over variables v0, v1, v2 and v3.
// The bit pattern then consists of 16 sub-bit patterns each of
// length 16 that are each either zero or equal to the same non zero
// value.
// If a relation can be factorised, it can be usefully split into
// two independent relations.
AND factor4(rel) = VALOF
{
  RESULTIS FALSE
}

.

// Boolean matrix functions for chk8

// bm_mk(n)
// bm_set(val, m)
// bm_copy(m1, m2)
// bm_and(m1, m2)
// bm_or(m1, m2)
// bm_imppp(i, j)
// bm_imppn(i, j)
// bm_impnp(i, j)
// bm_impnn(i, j)
// bm_setvar0(i)
// bm_setvar1(i)
// bm_impa(i, j)
// bm_impb(i, j)
// bm_impc(i, j)
// bm_impd(i, j)
// bm_warshall(m)
// bm_prmat(m)
// bm_findnewinfo(m, mprev)

SECTION "bmat"

GET "libhdr"
GET "chk8.h"

LET bm_mk(n) = VALOF
{ // n is the largest variable number (=maxid)
  // It returns a vector holding n and the four nxn submatices.
  LET nw  = n/bitsperword + 1 
  LET upb = 4*n*nw // The UPB of m. The word holding n plus four
                   // matrices ocuppying n*nw words.
  LET m   = spacep
  spacep := spacep + upb + 1

  IF spacep>spacet DO
  { writef("bm_mkmat: more store needed*n")
    abort(999)
    RESULTIS 0
  }
  m!0 := n
bm_set(0, m)
  RESULTIS m
}

AND bm_set(val, m) BE
{ // Set every element of m to 1 if val=TRUE
  //                    and to 0 if val=FALSE
  LET n   = m!0               // A, B, C and D are nxn boolean matrices
  LET nw  = n/bitsperword + 1 // Number of words in a row of A, B, C or D.
  LET upb = 4*n*nw // The UPB of m. The word holding n plus four
                   // matrices ocuppying n*nw words.
  FOR i = 1 TO upb DO m!i := val
}

AND bm_copy(m1, m2) BE
{ // Copy matrix m1 into m2
  LET n   = m1!0              // A, B, C and D are nxn boolean matrices
  LET nw  = n/bitsperword + 1 // Number of words in a row of A, B, C or D.
  LET upb = 4*n*nw // The UPB of m1. The word holding n plus four
                   // matrices ocuppying n*nw words.
  FOR i = 0 TO upb DO m2!i := m1!i
}

AND bm_and(m1, m2) BE
{ // AND matrix m1 into m2
  LET n   = m1!0              // A, B, C and D are nxn boolean matrices
  LET nw  = n/bitsperword + 1 // Number of words in a row of A, B, C or D.
  LET upb = 4*n*nw // The UPB of m1. The word holding n plus four
                   // matrices ocuppying n*nw words.
  FOR i = 1 TO upb DO m2!i := m1!i & m2!i
}

AND bm_or(m1, m2) BE
{ // OR matrix m1 into m2
  LET n  = m1!0              // A, B, C and D are nxn boolean matrices
  LET nw = n/bitsperword + 1 // Number of words in a row of A, B, C or D.
  LET upb = 4*n*nw // The UPB of m1. The word holding n plus four
                   // matrices ocuppying n*nw words.
  FOR i = 1 TO upb DO m2!i := m1!i | m2!i
}

AND bm_imppp(i, j) BE
{ // Set the bits in mat corresponding to vi -> vj
  writef("bm_imppp:  v%n ->  v%n*n", origid(i), origid(j))
  IF varinfo!i=-1 DO varinfo!i := -3
  IF varinfo!j=-1 DO varinfo!j := -3
  bm_impa(i, j)         //  vi ->  vj
  bm_impd(j, i)         // ~vj -> ~vi
  bm_pr(mat)
}

AND bm_imppn(i, j) BE
{ // Set the bits in mat corresponding to vi -> ~vj
  writef("bm_imppn:  v%n -> ~v%n*n", origid(i), origid(j))
  IF varinfo!i=-1 DO varinfo!i := -3
  IF varinfo!j=-1 DO varinfo!j := -3
  bm_impb(i, j)         //  vi -> ~vj
  bm_impb(j, i)         //  vj -> ~vi
  bm_pr(mat)
}

AND bm_impnp(i, j) BE
{ // Set the bits in mat corresponding to ~vi -> vj
  writef("bm_impnp: ~v%n ->  v%n*n", origid(i), origid(j))
  IF varinfo!i=-1 DO varinfo!i := -3
  IF varinfo!j=-1 DO varinfo!j := -3
  bm_impc(i, j)         // ~vi ->  vj
  bm_impc(j, i)         // ~vj ->  vi
  bm_pr(mat)
}

AND bm_impnn(i, j) BE
{ // Set the bits in mat corresponding to ~vi -> ~vj
  writef("bm_impnn: ~v%n -> ~v%n*n", origid(i), origid(j))
  IF varinfo!i=-1 DO varinfo!i := -3
  IF varinfo!j=-1 DO varinfo!j := -3
  bm_impd(i, j)         // ~vi -> ~vj
  bm_impa(j, i)         //  vj ->  vi
  bm_pr(mat)
}

AND bm_set0(i) BE
{ // Set the bits in mat corresponding to vi = 0
writef("bm_set0:  v%n = 0*n", origid(i))
  bm_impb(i, i)         //  vi -> ~vi
  bm_pr(mat)
}

AND bm_set1(i) BE
{ // Set the bits in mat corresponding to vi = 1
sawritef("bm_set1:  v%n = 1*n", origid(i))
  bm_impc(i, i)         // ~vi -> vi
  bm_pr(mat)
}

AND bm_seteq(i, j) BE
{ // Set the bits in mat corresponding to vi = vj
writef("bm_seteq:  v%n =  v%n*n", origid(i), origid(j))
  bm_impa(i, j)         // vi -> vj
  bm_impa(j, i)         // vj -> vi
  bm_pr(mat)
}

AND bm_setne(i, j) BE
{ // Set the bits in mat corresponding to vi  ~vj
writef("bm_setne:  v%n = ~v%n*n", origid(i), origid(j))
  bm_impb(i, j)         // vi -> ~vj
  bm_impb(j, i)         // vj -> ~vi
  bm_pr(mat)
}

AND bm_impa(i, j) BE IF i DO
{ // Set Aij = 1
  LET n  = mat!0
  LET nw = n/bitsperword + 1
  LET p  = mat+1 +               // Start of sub-matrix A
           (i-1)*nw +            // Start of row i of A
           (j-1)/bitsperword     // Word position in the row
  LET sh = (j-1) REM bitsperword // The bit position in the word
//writef("bm_impa:  v%n ->  v%n*n", origid(i), origid(j))
  !p := !p | 1<<sh               // Set the bit
}

AND bm_impb(i, j) BE IF i DO
{ // Set Bij = 1
  LET n  = mat!0
  LET nw = n/bitsperword + 1
  LET p  = mat+1 + n*nw +        // Start of sub-matrix B
           (i-1)*nw +            // Start of row i of B
           (j-1)/bitsperword     // Word position in the row
  LET sh = (j-1) REM bitsperword // The bit position in the word
//writef("bm_impb:  v%n -> ~v%n*n", origid(i), origid(j))
  !p := !p | 1<<sh               // Set the bit
}

AND bm_impc(i, j) BE IF i DO
{ // Set Cij = 1
  LET n  = mat!0
  LET nw = n/bitsperword + 1
  LET p  = mat+1 + 2*n*nw +      // Start of sub-matrix C
           (i-1)*nw +            // Start of row i of C
           (j-1)/bitsperword     // Word position in the row
  LET sh = (j-1) REM bitsperword // The bit position in the word
//writef("bm_impc: ~v%n ->  v%n*n", origid(i), origid(j))
  !p := !p | 1<<sh               // Set the bit
}

AND bm_impd(i, j) BE IF i DO
{ // Set Dij = 1
  LET n  = mat!0
  LET nw = n/bitsperword + 1
  LET p  = mat+1 + 3*n*nw +      // Start of sub-matrix D
           (i-1)*nw +            // Start of row i of D
           (j-1)/bitsperword     // Word position in the row
  LET sh = (j-1) REM bitsperword // The bit position in the word
//writef("bm_impd: ~v%n -> ~v%n*n", origid(i), origid(j))
  !p := !p | (1<<sh)             // Set the bit
}

AND bm_warshall(m) BE
{ // Perform Warshall's algorithm on the given 2n x 2n matrix
  // where n = m!0
  // m is composed of into four nxn sub-matrices A, B, C, and D.

  //   m = ( A B )
  //       ( C D )

  // The number of words in a sub-matrix row is nw (=n/bitsperword+1)
  // Each sub-matrix occupies n*nw consecutive words.

  LET n   = m!0               // A, B, C and D are nxn boolean matrices
  LET nw  = n/bitsperword + 1 // Number of words in a row of A, B, C or D.
  LET nnw = n*nw      // The size of a sub-matrix in words
  LET a   = m+1       // Start of sub-matrix A
  LET b   = a+nnw     // Start of sub-matrix B
  LET c   = b+nnw     // Start of sub-matrix C
  LET d   = c+nnw     // Start of sub-matrix D

//writef("bm_warshall: n=%n nw=%n*n", n, nw)

  FOR k = 0 TO n-1 DO // Go down column k of sub-matrices A and C
  { LET offk = k/bitsperword            // Word offset within a row
    LET bitk = 1 << (k REM bitsperword) // The bit within the word 
    LET rowka = a + k*nw
    LET rowkb = b + k*nw
    FOR i = 0 TO n-1 DO   // Inspect bits in col k of A and C
    { LET inw = i*nw
      LET rowia = a + inw
      LET rowib = b + inw
      LET rowic = c + inw
      LET rowid = d + inw
      UNLESS (rowia!offk & bitk)=0 DO // Test if A[i,k]=1
      { // Yes it does, so OR row k of (A B) into row i of (A B)
        FOR j = 0 TO nw-1 DO
        { rowia!j := rowia!j | rowka!j
          rowib!j := rowib!j | rowkb!j
        }
      }
      UNLESS (rowic!offk & bitk)=0 DO // Test if C[i,k]=1
      { // Yes it does, so OR row k of (A B) into row i of (C D) 
        FOR j = 0 TO nw-1 DO
        { rowic!j := rowic!j | rowka!j
          rowid!j := rowid!j | rowkb!j
        }
      }
    }
  }

  FOR k = 0 TO n-1 DO // Go down column k of matrices B and D
  { LET offk = k/bitsperword               // Word offset within a row
    LET bitk = 1 << (k REM bitsperword)    // 
    LET rowkc = c + k*nw
    LET rowkd = d + k*nw
    FOR i = 0 TO n-1 DO    // Inspect bits in col k of b and d
    { LET inw = i*nw
      LET rowia = a + inw
      LET rowib = b + inw
      LET rowic = c + inw
      LET rowid = d + inw
      UNLESS (rowib!offk & bitk)=0 DO // Test if B[i,k]=1
      { // Yes it does, so OR row k of (A B) into row i of (A B)
        FOR j = 0 TO nw-1 DO
        { rowia!j := rowia!j | rowkc!j
          rowib!j := rowib!j | rowkd!j
        }
      }
      UNLESS (rowid!offk & bitk)=0 DO // Test if D[i,k]=1
      { // Yes it does, so OR row k of (C D) into row i of (C D) 
        FOR j = 0 TO nw-1 DO
        { rowic!j := rowic!j | rowkc!j
          rowid!j := rowid!j | rowkd!j
        }
      }
    }
  }
}

AND bm_pr(m) BE
{ LET n  = m!0
  LET nw = n/bitsperword + 1
  LET a  = m+1       // Start of sub-matrix A
  LET b  = a + n*nw  // Start of sub-matrix B
  LET c  = b + n*nw  // Start of sub-matrix C
  LET d  = c + n*nw  // Start of sub-matrix D

  FOR i = 0 TO n-1 DO
  { writef("%i2: ", i+1)
    prmatrow(a + i*nw, n) // Row of A
    wrch('*s')
    prmatrow(b + i*nw, n) // Row of B
    newline()
  }
  newline()
  FOR i = 0 TO n-1 DO
  { writef("%i2: ", i+1)
    prmatrow(c + i*nw, n) // Row of C
    wrch('*s')
    prmatrow(d + i*nw, n) // Row of D
    newline()
  }
//abort(1000)
}

AND prmatrow(r, n) BE FOR j = 0 TO n-1 DO
{ LET p   = r + j/bitsperword
  AND bit = 1 << j REM bitsperword
  wrch((!p & bit) = 0 -> '.', '**')
}

AND bm_apnewinfo() = VALOF
{ // This applies applies any new equalities or implications
  // found in the matrix.

  // It returns:
  //   TRUE,  result2=FALSE if an inconsistency is found
  //   TRUE,  result2=TRUE  if the set of relations becomes empty.
  //   FALSE, result2=FALSE if no new information was found.
  //   FALSE, result2=TRUE  if something changed.

  LET newinfo = FALSE
  LET n  = mat!0
  LET nw = n/bitsperword + 1

  LET a  = mat+1     // Start of sub-matrix A
  LET b  = a + n*nw  // Start of sub-matrix B
  LET c  = b + n*nw  // Start of sub-matrix C
  LET d  = c + n*nw  // Start of sub-matrix D

  LET ap = matprev+1 // Start of previous sub-matrix A
  LET bp = ap + n*nw // Start of previous sub-matrix B
  LET cp = bp + n*nw // Start of previous sub-matrix C
  LET dp = cp + n*nw // Start of previous sub-matrix D

  // Look for new information of the form vi=0 or vi=1

  FOR i = 1 TO n UNLESS 0<=varinfo!i<=1 DO
  { // The setting of the variable is not already known.
    LET i1 = i-1
    LET ri = i1*nw                 // offset to start of row i
    LET j  = i1/bitsperword        // offset to start of col i
    LET sh = i1 REM bitsperword    // shift for bit in the row
    LET w = b!(ri+j) XOR bp!(ri+j) // 
//writef("i=%n j=%n sh=%n w=%bF*n", i, j, sh, w)
//writef("Testing to see if v%n=0*n", origid(i))
    // See if vi->~vi ie vi=0 is new info
    UNLESS ((w>>sh)&1)=0 DO
    { writef("bm_apnewinfo:  v%n = 0*n", origid(i))
      newinfo := newinfo | apvarset0(i)
    }
    w := c!(ri+j) XOR cp!(ri+j)
//writef("i=%n j=%n sh=%n w=%bF*n", i, j, sh, w)
//writef("Testing to see if v%n=1*n", origid(i))
    // See if ~vi->vi ie vi=1 is new info
    UNLESS ((w>>sh)&1)=0 DO
    { writef("bm_apnewinfo:  v%n = 1*n", origid(i))
      newinfo := newinfo | apvarset1(i)
    }
  }

  // Look for new information of the form vi=vj or vi=~vj, i<j

  FOR i = 1 TO n IF varinfo!i=-1 DO
  { // The setting of vi is unknown.
    // Look for any vj whose setting is unknown, and
    // for which vi=vj, vi=~vj.

    //// vi->vj, vi->~vj,~vi->vj or ~vi->~vj is new information
    //// preferring vi=vj, vi=~vj, if possible.

    LET ri = (i-1)*nw
    FOR r = 0 TO nw-1 DO
    { LET k = r+ri
      LET aw, apw = a!k, ap!k
      AND bw, bpw = b!k, bp!k
      AND cw, cpw = c!k, cp!k
      AND dw, dpw = d!k, dp!k
      AND w = ?

      w := (aw XOR apw) | (dw XOR dpw)

      // Each bit in w corresponds to either or both
      // Aij=1 or Dij=1 being new information implying that
      // one or more of: vi=vj, vi->vj or ~vi->~vj are new.

//writef("i=%n r=%n w=%bF*n", i, r, w)
//writef("Testing to see if v%n=vj or v%-%n~=vj for some j*n", origid(i))

      IF w DO 
      { LET bit, j = 1, 1 + r*bitsperword
        LET wad = aw & dw          // A[i,j]=D[i,j]=1 

        { // Iterate through the ones in w
          IF (w&bit)~=0 DO
          {  w := w - bit
            // One of vi=vj, vi->vj and/or ~vi->~vj is new
            IF varinfo!j=-1 & i>=j DO
              // i<j and vj is not yet known
              TEST (wad&bit)~=0
              THEN { // (A&D)[i,j] = 1 is new
                     UNLESS i=j DO
                     { writef("bm_apnewinfo:  v%n = v%n*n",
                                  origid(i), origid(j))
                       newinfo := newinfo | apvareq(i, j)
                     }
                   }
              ELSE TEST ((apw XOR aw)&bit)~=0
                   THEN { // A[i,j] = 1 is new
                          writef("bm_apnewinfo:  v%n -> v%n*n",
                                  origid(i), origid(j))
                          newinfo := newinfo | apvarimppp(i, j)
                        }
                   ELSE { // D[i,j] = 1 is new
                          writef("bm_apnewinfo:  ~v%n -> ~v%n*n",
                                  origid(i), origid(j))
                          newinfo := newinfo | apvarimpnn(i, j)
                        }
          }
          bit, j := bit<<1, j+1
        } REPEATWHILE w
      }

  // Look for new information of the form
  // vi->vj, vi->~vj, ~vi=vj or ~vi->~vj, i<j
 
      w := (bw XOR bpw) | (cw XOR cpw) // Bij=1 or Cij=1 new

      // Each bit in w corresponds to either or both
      // Bij=1 or Cij=1 being new information implying that
      // one or more of: vi=~vj, vi->~vj and ~vi->vj are new.

      IF w DO 
      { LET bit, j = 1, 1 + r*bitsperword
        LET wbc = bw & cw          // (B&C)[i,j]=1 

        { // Iterate through the ones in w
          IF (w&bit)~=0 DO
          { w := w - bit
            // One of vi=~vj, vi->~vj and/or ~vi->vj is new
            IF varinfo!j=-1 & i>=j DO
              // i<j and the setting of vj is unknown.
              TEST (wbc&bit)~=0
              THEN { // (B&C)[i,j] = 1 is new
                     IF i=j DO
                     { writef("apnewinfo:  v%n ~= v%n -- Inconsistent*n",
                               origid(i), origid(i))
                       RESULTIS TRUE
                     }
                     writef("v%n ~= v%n*n",
                             origid(i), origid(j))
                     newinfo := newinfo | apvarne(i, j)
                   }
              ELSE TEST ((bpw XOR bw)&bit)~=0
                   THEN { // B[i,j] = 1 is new
                          writef("apnewinfo:  v%n -> ~v%n*n",
                                  origid(i), origid(j))
                          newinfo := newinfo | apvarimppn(i, j)
                        }
                   ELSE { // C[i,j] = 1 is new
                          writef("apnewinfo:  ~v%n -> v%n*n",
                                  origid(i), origid(j))
                          newinfo := newinfo | apvarimpnp(i, j)
                        }
          }
          bit, j := bit<<1, j+1
        } REPEATWHILE w
      }
    }
  }

  // Remember the current state of the matrices
  bm_copy(mat, matprev)

  result2 := newinfo
  RESULTIS FALSE        // Not inconsistent
}

.

/*

This is the main recursive search engine of the tautology checker
based on the analysis of the conjunction of a set of relations over up
to 8 Boolean variables.

Implemented in BCPL by Martin Richards (c) April 2006
*/

SECTION "engine"

GET "libhdr"
GET "chk8.h"

/*

explore(depth)

Argument
  depth is the current recursion depth, 0<=depth<=maxdepth.

Returns
  TRUE, result2=FALSE   if the relations are not satisfiable
  TRUE, result2=TRUE    if the relations are satisfiable
  FALSE                 if there is no answer using this
                        maximum depth of recursion.

Algorithm:

On entry
  relv     relv!0  The number of relations.
           relv!i  1<=i<=relv!0
                   This points to the relation node for relation i.
                   Each relation will be in standard form, ie its
                   arguments will be in decreasing order and all its
                   non zero arguments will be distinct. The args field
                   will hold the number of non zero arguments.

  idvecs   idvecs!0 = the number of variables
           idvecs!i, idvecs!i+1,..., idvecs!(i+1)-1 point to
           locations holding the pointers to the relations nodes
           that use variable i. Some of these pointers may become null.

  idcountv idcountv!0 = the UPB of idcountv and id2prev
           idcountv!i = the number uses of variable i.

  id2prev  id2prev=0      there is no mapping, otherwise
           id2prev!0 ~= 0 points to the mapping vector one level out.
                          Note that origid(id) uses this chain to map
                          an identifier to its original number.
           id2prev!id =   the previous number for this identifier

  varinfo  varinfo!i  1<=i<=maxid
                   = -3    vi not yet set, but there is info
                           about it in mat
                   = -2    vi was eliminated since it was only
                           used in one relation.
                   = -1    nothing known about vi
                   =  0    vi = false
                   =  1    vi = true
                   = 2j    vi = vj
                   = 2j+1  vi = ~vj

  rellist  is a list of relation nodes that require processing.
           Each relation in this list has inrellist set TRUE.

  mat       holds the four nxn implication matrices A, B, C and D,
            holding implications of the form: x->y, x->~y, ~x->y
            and ~x->~y, respectively. mat!0 is equal to n.

  matprev   a previous copy of mat
 
explore() performs the following steps:

(0)  Allocate matprev and copy mat into it so that newly found
     implications can be discovered.

(1)  For each variable
     (1.0) Optionally check the data structures.
     (1.1) If it is used only one relation and has no information
           about it in the matrix, eliminate it.
     (1.2) If it is used exactly two relations, try to apply COMBINE
           to them and if successful eliminate the variable.

(2)  Inspect each non-deleted relation in rellist without dequeueing it,
     (2.1) Check to see if the relation has an argument which is
           not constrained by the relation. If so remove that argument.
     (2.2) If the relation is unsatisfiable return from explore
           with result TRUE and result2=FALSE.
     (2.3) If the relations is true for all setting of its
           variables, delete it.
     (2.4) Insert any new implications found into the matrix.
     (2.5) If the relation has two or fewer variables delete it.

(3)  For each relation in relist
     (3.1) Dequeue a relation, rel say, from rellist and
           apply COMBINE to rel and any other relation having three or more
           variables in common. If COMBINE is unsuccessful apply RESTRICT.
           In either case put any new implications found into the matrix.

(4)  (4.1) Apply Warshall's algorithm to form the transitive closure of
           the matrix.
     (4.2) Apply all the newly discovered equalities and implications
           to the relations, leaving them in standard form. Any relation
           changed by this process is put into rellist.
     (4.3) If the rellist is non empty goto (1).

(5)  If depth=maxdepth return FALSE indicating that the solution
     has not yet been found but there may be new information in the matrix.

(6)  Split every relation that can be factorised into two relations
     over disjoint variables, and try to combine its factors with other
     relations. No new implications will be found by this process.

(7)  Choose the relation, rel say, with the greatest weight (influence
     and fewest ones in its relation bit pattern).
     (7.1) Save relv, idvecs, idcountv, mat and matprev.
     (7.2) Allocate intermat, filled with ones, to eventually hold the
           intersection of all the matrices left by calls of explore
           that returned FALSE.
     (7.3) Allocate new versions of relv, varinfo and mat.

(8)  For each possible setting of the variables of rel
     (8.1) copy the old varinfo into the new version.
     (8.2) update entries in varinfo to specify the selected values of
           the variables in the current id current setting. Copy all
           the relations except rel into the new relv applying this
           mapping. Any relation changed by this process is pushed onto
           rellist for further processing.
     (8.3) Allocate and initialise new versions of idcountv and idvecs.
     (8.4) Call explore(depth+1).
     (8.5) If explore returned FALSE, 'And' mat into intermat.

(9)  'Or' intermat into the previous version of mat. If this does
     not add new information to the matrix return from explore with
     result FALSE.

(10) (10.1) Apply Warshall's algorithm to form the transitive closure
            of mat.
     (10.1) Apply all the new information it contains to relations.
     (10.2) If the rellist is now non empty goto (1)

(11) Return from explore with result FALSE, indicating the no
     solution has been found with this setting of maxdepth.

*/

LET explore(depth) = VALOF
// explore is called with a new sub problem represented by
//    relv, maxid, idvecs, idcountv, id2prev, mat and stack.
// relv!0 id the UPB of relv
// relcount is the number of non-deleted relations.
// Relations that need to be inspected will be in rellist.

{ LET oldspacep = spacep
  LET oldmatprev = matprev

  writef("explore entered, depth=%n reln=%n relv!0=%n mat!0=%n*n",
          depth, relcount, relv!0, mat!0)

  //writef("calling checkrelstruct()*n")
  checkrelstruct()

  // Output the relations and variables of the current state.
  //newline()
  //wrrels(relv, TRUE)

//  writef("*nexplore: There %p\is\are\ %-%n relation%-%ps in rellist*n*n",
//          length(rellist))

  //wrvars()
  //newline()

  writef("explore: Processing the following set of relations:*n")
  wrrels(relv, TRUE)

step0:
  writef("explore: Step (0)    -- Allocating and setting matprev*n")
  matprev := bm_mk(mat!0)  
  bm_copy(mat, matprev)

step1:
  // Check that all relations are in standard form.
  writef("explore: Step (1.0)*n")
//relv!1!r_b := relv!1!r_b + 1
//idvecs!1!0 := 0
//writef("relv!0=%n*n", relv!0)

step1.1:
  writef("explore: Step (1.1)  -- Dealing with variables used once or twice*n")
  //wrvars()
  checkrelstruct()

  FOR id = 1 TO mat!0 DO
  { LET count = idcountv!id

    //IF FALSE DO
    IF count=1 & varinfo!id=-1 DO
    {
      writef("Eliminating v%n since it is only used once*n", origid(id))
      abort(1100)
      ignorevar(id)
      LOOP
    }

step1.2:
    //IF FALSE DO
    IF count=2 DO
    { LET p = idvecs!id
      LET q = idvecs!(id+1)
      LET rel1 = 0     // One relation using id
      LET rel2 = 0     // The other relation using id
      FOR t = p TO q-1 DO
      { LET r = !t
        IF r UNLESS r!r_deleted DO
        { IF rel1 DO { rel2 := r; BREAK }
          rel1 := r
        }
      }
      UNLESS rel1 & rel2 DO
      { writef("System error: There should be two relations using: v%n*n",
                origid(id))
        abort(999)
      }
      //writef("Variable v%n is used in just two relations:*n", origid(id))
      //writef("Applying COMBINE or RESTRICT*n")
      IF combine(rel1, rel2) GOTO step1.1
    }
  }

  // Perform simplifications and find implications here

step2:
  //writef(
  // "*nexplore: Step (2)    *
  // *-- Applying simplification rules to each relation*n")

  { LET rel     = rellist
    LET changed = FALSE // Gets set to TRUE if anything changes

    WHILE rel DO
    { LET nextrel = rel!r_link
      LET v    = @rel!r_a
      LET impv = VEC 3

      IF rel!r_deleted DO
      { rel := nextrel
        LOOP
      }

      changed := FALSE
      writef("explore: Step (2)    -- Considering the following relation:*n")
      wrrel(rel, TRUE)

/*
step2.1:
      writef("explore: Step (2.1)  -- Deal with new equalities*n")
      // Check to see is any of its variable are now set.
      // Ie test if vi=0, vi=1, vi=vj or vi=~vj for every
      // argument variable vi. Modify the relation if necessary.
      // Leave the relation with its variables in sorted order
      // and with no duplicates.

      FOR argi = 0 TO rel!r_args - 1 DO
      { LET id = v!argi
        LET info = varinfo!id
        IF info<0 LOOP // Cannot eliminate this variable
writef("Relation %n arg %n: v%n  info=%n*n",
        rel!r_relno, argi, origid(id), info)
        IF info=0 DO                         // vi = 0
        {
writef("Applying v%n=0 to the following relation:*n", origid(id))
          wrrel(rel, TRUE)
          apset0(rel, argi)
          FOR argj = argi+1 TO rel!r_args DO
          { IF v!argj DO
            { exchargs(rel, argj-1, argj)
            }
          }
          changed := TRUE
          rel := nextrel
          LOOP
        }

        IF info=1 DO                         // vi = 1
        {
writef("Applying v%n=1 to the following relation:*n", origid(id))
          wrrel(rel, TRUE)
          apset1(rel, argi)
          FOR argj = argi+1 TO rel!r_args DO
          { IF v!argj DO
            { exchargs(rel, argj-1, argj)
            }
          }
          changed := TRUE
          rel := nextrel
          LOOP
        }

        IF (info & 1) = 0 DO                 // vi = vj
        { LET vj = info/2
          writef("Applying v%n=v%n to the following relation:*n",
                 origid(id), origid(vj))
          wrrel(rel, TRUE)
          v!argi := vj
          wrrel(rel, TRUE)
        }

        IF (info & 1) = 1 DO                 // vi = ~vj
        { LET vj = info/2
          writef("Applying v%n=~v%n to the following relation:*n",
                 origid(id), origid(vj))
          wrrel(rel, TRUE)
          apnot(rel, argi)
          v!argi := vj
          wrrel(rel, TRUE)
        }

        writef("System error: bad info=%n*n", info)
        abort(999)
      }
*/

step2.1:
      writef("explore: Step (2.1)  -- Removing unconstrained arguments*n")
      //IF FALSE DO
      FOR argi = 0 TO rel!r_args-1 IF isunconstrained(rel, argi) DO
      { LET id = v!argi
        writef("explore: v%n is unconstrained in relation:*n", origid(v!argi))
        wrrel(rel, TRUE)
        v!argi := 0
        FOR p = idvecs!id TO idvecs!(id+1)-1 DO
        { IF !p=rel DO !p := 0 // Remove id's reference to this rel
        }
        idcountv!id := idcountv!id - 1
        standardise(rel)
wrvars()
        GOTO step2.1
      }
      abort(2100)

step2.2:
      writef("explore: Step (2.2)  -- Is the rel always false?*n")
      checkrelstruct()
      //IF FALSE DO
      IF rulefalse(rel) DO
      { writef("explore: The following relation is always false*n")
//writef("explore: rel=%n*n", rel)
        wrrel(rel)
        wrvars()
//abort(1000)
        result2 := FALSE
        RESULTIS TRUE     // Problem solved -- unsatisfiable
      }
      //abort(2200)

step2.3:
      writef("explore: Step (2.3)  -- Is the rel always true?*n")
      checkrelstruct()
      //IF FALSE DO
      IF ruletrue(rel) DO
      { writef("explore: Deleting the following relation *
               *because it is always true*n")
        wrrel(rel)

        FOR argi = 0 TO 7 DO
        { LET id = rel!(r_a+argi)
          IF id DO idcountv!id := idcountv!id - 1
        }

        rel!r_deleted := TRUE
        relcount := relcount - 1  // Update count of non-deleted relations.
      }
      checkrelstruct()
      abort(2300)
/*
step2.3a:
      writef("explore: Step (2.3a) -- Sort the arguments *
             *and remove duplicates*n")
      FOR argi = 0 TO rel!r_args-2 DO
      { LET argj = argi+1
        LET vi = v!argi
        AND vj = v!argj
        // Find the largest remaining argument
        FOR t = argj+1 TO rel!r_args-1 IF v!t>vj DO
        { argj := t
          vj := v!argj
        }
        IF vi<=vj DO
        { // Argument out of order or duplicated
          IF vi=vj DO
          { apeq(rel, argi, argj)
            GOTO step2.3a
          }
          exchargs(rel, argi, argj)
        }
      }

      FOR argi = 7 TO 0 BY -1 IF v!argi DO
      { rel!r_args := argi+1
        BREAK
      }

      SWITCHON rel!r_args INTO
      { CASE 0: rel!r_w0 := rel!r_w0 & #x00000001
        CASE 1: rel!r_w0 := rel!r_w0 & #x00000003
        CASE 2: rel!r_w0 := rel!r_w0 & #x0000000F
        CASE 3: rel!r_w0 := rel!r_w0 & #x000000FF
        CASE 4: rel!r_w0 := rel!r_w0 & #x0000FFFF
        CASE 5: rel!r_w1 := 0
        CASE 6: rel!r_w2 := 0
                rel!r_w3 := 0
        CASE 7: rel!r_w4 := 0
                rel!r_w5 := 0
                rel!r_w6 := 0
                rel!r_w7 := 0
        CASE 8:
      }
*/

step2.4:
      writef("explore: Step (2.4)  -- Find implications*n")
      checkrelstruct()
//abort(1000)
      IF rel!r_deleted DO
      { writef("explore: The relation was deleted*n")
        GOTO step2.5
      }
      writef("explore: Calling findimps(..) on the following relation*n")
      wrrel(rel, TRUE)
      findimps(rel, impv)
      writef("findimps(..) found the following implications:*n*n")
      //primps(impv)

      // Put the newly found vi=0 or vi=1 into the matrix
      { LET a,b,c,d,e,f,g,h = v!0,v!1,v!2,v!3,v!4,v!5,v!6,v!7
        LET bits = ?

        IF a DO
        { bits := (impv!1 & impv!3) //& ~(rel!r_prevpn & rel!r_prevnn)
          // (x->~y & ~x->~y)  => y=0
          //writef("(x->~y & ~x->~y) => y=0 bits=%b7 %b6 %b5 %b4 %b3 %b2 %b1*n",
          //     bits>>21, bits>>15, bits>>10, bits>>6, bits>>3, bits>>1, bits)

          IF (bits & #b0000000_000000_00000_0000_000_00_1) > 0 DO bm_set0(a)

          bits := (impv!0 & impv!2) //& ~(rel!r_prevpp & rel!r_prevnp)
          // (x->y & ~x->y)  => y=1
          //sawritef("(x->y & ~x->y)   => y=1 bits=%b7 %b6 %b5 %b4 %b3 %b2 %b1*n",
          //   bits>>21, bits>>15, bits>>10, bits>>6, bits>>3, bits>>1, bits)

          IF (bits & #b0000000_000000_00000_0000_000_00_1) > 0 DO bm_set1(a)
        }

        bits := (impv!0 & impv!1) //& ~(rel!r_prevpp & rel!r_prevpn)
        // (x->y & x->~y)  => x=0
        //sawritef("(x->y & x->~y)   => x=0 bits=%b7 %b6 %b5 %b4 %b3 %b2 %b1*n",
        //    bits>>21, bits>>15, bits>>10, bits>>6, bits>>3, bits>>1, bits)

        // (b->a & b->~a)  => b=0
        IF b & (bits & #b0000000_000000_00000_0000_000_00_1) > 0 DO bm_set0(b)
        // (c->a & c->~a)  => c=0
        IF c & (bits & #b0000000_000000_00000_0000_000_01_0) > 0 DO bm_set0(c)
        // (d->a & d->~a)  => d=0
        IF d & (bits & #b0000000_000000_00000_0000_001_00_0) > 0 DO bm_set0(d)
        // (e->a & e->~a)  => e=0
        IF e & (bits & #b0000000_000000_00000_0001_000_00_0) > 0 DO bm_set0(e)
        // (f->a & f->~a)  => f=0
        IF f & (bits & #b0000000_000000_00001_0000_000_00_0) > 0 DO bm_set0(f)
        // (g->a & g->~a)  => g=0
        IF g & (bits & #b0000000_000001_00000_0000_000_00_0) > 0 DO bm_set0(g)
        // (h->a & h->~a)  => h=0
        IF h & (bits & #b0000001_000000_00000_0000_000_00_0) > 0 DO bm_set0(h)

        bits := (impv!2 & impv!3) //& ~(rel!r_prevnp & rel!r_prevnn)
        //writef("(~x->y & ~x->~y) => x=1 bits=%b7 %b6 %b5 %b4 %b3 %b2 %b1*n",
        //    bits>>21, bits>>15, bits>>10, bits>>6, bits>>3, bits>>1, bits)

        // (~b->a & ~b->~a)  => b=1
        IF b & (bits & #b0000000_000000_00000_0000_000_00_1) > 0 DO bm_set1(b)
        // (~c->a & ~c->~a)  => c=1
        IF c & (bits & #b0000000_000000_00000_0000_000_01_0) > 0 DO bm_set1(c)
        // (~d->a & ~d->~a)  => d=1
        IF d & (bits & #b0000000_000000_00000_0000_001_00_0) > 0 DO bm_set1(d)
        // (~e->a & ~e->~a)  => e=1
        IF e & (bits & #b0000000_000000_00000_0001_000_00_0) > 0 DO bm_set1(e)
        // (~f->a & ~f->~a)  => f=1
        IF f & (bits & #b0000000_000000_00001_0000_000_00_0) > 0 DO bm_set1(f)
        // (~g->a & ~g->~a)  => g=1
        IF g & (bits & #b0000000_000001_00000_0000_000_00_0) > 0 DO bm_set1(g)
        // (~h->a & ~h->~a)  => h=1
        IF h & (bits & #b0000001_000000_00000_0000_000_00_0) > 0 DO bm_set1(h)
      }

      writef("*nexplore: Putting the newly found implications, if any, *
              *into the matrix*n")
      //wrrel(rel, TRUE)
      //primps(impv)
      //newline()
      //bm_pr(mat)

      // Put the newly found implications into the matrix
      //  x ->  y
      changed := changed | putimps(impv!0 & ~rel!r_prevpp, v, bm_imppp)
      //  x -> ~y
      changed := changed | putimps(impv!1 & ~rel!r_prevpn, v, bm_imppn)
      // ~x ->  y
      changed := changed | putimps(impv!2 & ~rel!r_prevnp, v, bm_impnp)
      // ~x -> ~y
      changed := changed | putimps(impv!3 & ~rel!r_prevnn, v, bm_impnn)

      // Remember these implications
      rel!r_prevpp := impv!0
      rel!r_prevpn := impv!1
      rel!r_prevnp := impv!2
      rel!r_prevnn := impv!3
      abort(2400)

step2.5:
      UNLESS rel!r_deleted IF rel!r_args<=2 DO
      { // For any relation over two or fewer variables, all the information
        // it contains will have been transferred to the matrix so the
        // relation can be deleted.
        writef("Deleting relation %n after transferring its *
               *implications to the matrix*n", rel!r_relno)
        // Decrement the counts of the variables it uses.
        FOR argi = 0 TO rel!r_args-1 DO
        { LET id = v!argi
          IF id DO
          { LET p = idvecs!id
            AND q = idvecs!(id+1)
            FOR t = p TO q-1 IF !t=rel DO !t := 0
            idcountv!id := idcountv!id - 1
          }
        }
        rel!r_deleted := TRUE
        wrrels(relv, TRUE)
        wrvars()
        abort(2222)
      }
      abort(2500)

      // Look at the next relation in rellist, if any.
      rel := nextrel
      // The LOOP command jumps here
    }

step3:
    writef("explore: Doing step (3.1)  -- Applying COMBINE and RESTRICT*n")
    checkrelstruct()

    WHILE rellist DO
    { LET rel = rellist
      UNLESS rel LOOP
      rellist := rel!r_link
      rel!r_inrellist := FALSE
      writef("NOT applying COMBINE to relation %n with others*n", rel!r_relno)
      writef("NOT applying RESTRICT to relation %n with others*n", rel!r_relno)
    }
    abort(3100)

    UNLESS changed BREAK
    writef("There were changes so repeat from step (2)*n")
  } REPEAT

step4.1:
  writef("explore: Doing step (4.1) *
         *-- Find and apply newly discovered information*n")
  checkrelstruct()

  // Apply Warshall's algorithm
  newline()
  bm_pr(mat)
  writef("*nApplying Warshall*n")
  bm_warshall(mat)
  bm_pr(mat)
  newline()
 abort(4100)

step4.2:
  writef("explore: Step (4.2)  -- Applyin new info*n")
  checkrelstruct()
  IF bm_apnewinfo() DO
  { // bm_apnewinfo returns:
    //   TRUE,  result2=FALSE if an inconsistency is found
    //   TRUE,  result2=TRUE  if the set of relations becomes empty.
    //   FALSE, result2=FALSE if no new information was found.
    //   FALSE, result2=TRUE  if something changed.

    UNLESS result2 DO
    { writef("apnewinfo discovered an inconsistency*n")
      result2 := FALSE
      RESULTIS TRUE
    }
  }
  abort(4200)

  IF rellist DO
  {
  writef("explore: Step (4.3)  -- Repeat from step 1 because rellist is non empty*n")
    GOTO step1
  }
  sawritef("engine: no new information found*n")
  abort(4300)

step5:
  writef("explore: Doing step (5)  -- Checking depth*n")
  checkrelstruct()
  writef("explore: No more implication can be found*n")
  // No more simplification can be made and there are no
  // more implications to be found, so explore the children
  // if the depth allows.
  IF depth>=maxdepth DO
  { result2 := TRUE
    writef("explore: Maximum depth=%n reached so return*n", depth)
    RESULTIS TRUE    // Cannot solve the problem with this setting of maxdepth
  }
  abort(5000)

step6:
  writef("explore: Doing step (6)   -- Trying to factorise relations*n")
  FOR i = 0 TO relv!0 DO
  { LET rel = relv!i
    IF rel=0 | rel!r_deleted LOOP
    writef("NOT trying to factorise relation %n*n", rel!r_relno)
  }
  abort(6000)

step7:
  { LET relno = 1 // Choose a pivot relation somehow.
    LET changed = FALSE
    writef("explore: Doing step (7)   -- *
           *Explore children of relation %n*n", relno)
    explorechildrenof(relno, depth+1)

    result2 := changed
    RESULTIS FALSE
  }
}

AND checkrelstruct() BE
{ // This checks the relations structure for consistency
  // First check idcountv!id matches the entries in idvecs!id
  FOR id = 1 TO mat!0 DO
  { LET n = 0
    FOR p = idvecs!id TO idvecs!(id+1)-1 DO
    { LET rel = !p
      LET count = 0
      UNLESS rel LOOP
      IF rel!r_deleted LOOP
      FOR i = 0 TO 7 IF rel!(r_a+i)=id DO count := count+1
      UNLESS count=1 DO
      { writef("checkrelstruct: v%n not in relation %n*n",
                origid(id), rel!r_relno)
        wrrel(rel, TRUE)
        abort(999)
      }
      n := n+1
    }
    UNLESS n=idcountv!id DO
    { writef("checkrelstruct: Bad idcountv!%n=%n, n=%n*n",
              origid(id), idcountv!id, n)
      abort(999)
    }
    
  }
  // Check that all relation arguments are in sorted order
  // with no duplicates and that the args and relno fields are correctly set.
  FOR relno = 1 TO relv!0 DO
  { LET rel = relv!relno
    UNLESS rel LOOP
    IF rel!r_deleted LOOP
    UNLESS relno=rel!r_relno DO
    { writef("checkrelstruct: rel!r_relno=%n relno=%n*n", rel!relno, relno)
      wrrel(rel, TRUE)
      abort(999)
    }
    FOR argi = 0 TO 6 DO
    { LET id1 = rel!(r_a+argi)
      LET id2 = rel!(r_a+argi+1)
      UNLESS id1=0=id2 | id1>id2 DO
      { writef("checkrelstruct: arguments not sorted*n")
        wrrel(rel, TRUE)
        abort(999)
      }
    }
    // Check the args field
    { LET args = 0
      FOR i = 0 TO 7 IF rel!(r_a+i) DO args := args+1
      UNLESS rel!r_args=args DO
      { writef("checkrelstruct: rel!r_args=%n args=%n*n", rel!r_args, args)
        wrrel(rel, TRUE)
        abort(999)
      }
    }
  }
  writef("The relation structure is OK*n")
}

AND rulefalse(rel) = VALOF SWITCHON rel!r_args INTO
// Return TRUE if rel can never be satisfied
{ CASE 0:
  CASE 1:
  CASE 2:
  CASE 3:
  CASE 4:
  CASE 5: RESULTIS rel!r_w0 = 0
  CASE 6: RESULTIS rel!r_w0 = 0 &
                   rel!r_w1 = 0
  CASE 7: RESULTIS rel!r_w0 = 0 &
                   rel!r_w1 = 0 &
                   rel!r_w2 = 0 &
                   rel!r_w3 = 0
  CASE 8: RESULTIS rel!r_w0 = 0 &
                   rel!r_w1 = 0 &
                   rel!r_w2 = 0 &
                   rel!r_w3 = 0 &
                   rel!r_w4 = 0 &
                   rel!r_w5 = 0 &
                   rel!r_w6 = 0 &
                   rel!r_w7 = 0
}

AND ruletrue(rel) = VALOF SWITCHON rel!r_args INTO
// Return TRUE if rel is always satisfied
{ CASE 0: RESULTIS rel!r_w0 = #b00000001
  CASE 1: RESULTIS rel!r_w0 = #b00000011
  CASE 2: RESULTIS rel!r_w0 = #b00001111
  CASE 3: RESULTIS rel!r_w0 = #b11111111
  CASE 4: RESULTIS rel!r_w0 = #x0000FFFF
  CASE 5: RESULTIS rel!r_w0 = #xFFFFFFFF
  CASE 6: RESULTIS rel!r_w0 = #xFFFFFFFF &
                   rel!r_w1 = #xFFFFFFFF
  CASE 7: RESULTIS rel!r_w0 = #xFFFFFFFF &
                   rel!r_w1 = #xFFFFFFFF &
                   rel!r_w2 = #xFFFFFFFF &
                   rel!r_w3 = #xFFFFFFFF
  CASE 8: RESULTIS rel!r_w0 = #xFFFFFFFF &
                   rel!r_w1 = #xFFFFFFFF &
                   rel!r_w2 = #xFFFFFFFF &
                   rel!r_w3 = #xFFFFFFFF &
                   rel!r_w4 = #xFFFFFFFF &
                   rel!r_w5 = #xFFFFFFFF &
                   rel!r_w6 = #xFFFFFFFF &
                   rel!r_w7 = #xFFFFFFFF
}

AND putset(bits, v, val) = VALOF
{ LET a, b, c, d, e, f, g, h = v!0, v!1, v!2, v!3, v!4, v!5, v!6, v!7

  IF a DO
  { IF (bits & #b1111111_111111_11111_1111_111_11_1) > 0 DO bm_set(a, val)
  }
}

AND putimps(bits, v, bmfn) = VALOF
{ LET a, b, c, d, e, f, g, h = v!0, v!1, v!2, v!3, v!4, v!5, v!6, v!7
  LET changed = FALSE

  IF b DO
  { IF ((1<< 0)&bits) > 0 & a DO changed := changed | bmfn(b, a)
  }
  IF c DO
  { IF ((1<< 1)&bits) > 0 & a DO changed := changed | bmfn(c, a)
    IF ((1<< 2)&bits) > 0 & b DO changed := changed | bmfn(c, b)
  }
  IF d DO
  { IF ((1<< 3)&bits) > 0 & a DO changed := changed | bmfn(d, a)
    IF ((1<< 4)&bits) > 0 & b DO changed := changed | bmfn(d, b)
    IF ((1<< 5)&bits) > 0 & c DO changed := changed | bmfn(d, c)
  }
  IF e DO
  { IF ((1<< 6)&bits) > 0 & a DO changed := changed | bmfn(e, a)
    IF ((1<< 7)&bits) > 0 & b DO changed := changed | bmfn(e, b)
    IF ((1<< 8)&bits) > 0 & c DO changed := changed | bmfn(e, c)
    IF ((1<< 9)&bits) > 0 & d DO changed := changed | bmfn(e, d)
  }
  IF f DO
  { IF ((1<<10)&bits) > 0 & a DO changed := changed | bmfn(f, a)
    IF ((1<<11)&bits) > 0 & b DO changed := changed | bmfn(f, b)
    IF ((1<<12)&bits) > 0 & c DO changed := changed | bmfn(f, c)
    IF ((1<<13)&bits) > 0 & d DO changed := changed | bmfn(f, d)
    IF ((1<<14)&bits) > 0 & e DO changed := changed | bmfn(f, e)
  }
  IF g DO
  { IF ((1<<15)&bits) > 0 & a DO changed := changed | bmfn(g, a)
    IF ((1<<16)&bits) > 0 & b DO changed := changed | bmfn(g, b)
    IF ((1<<17)&bits) > 0 & c DO changed := changed | bmfn(g, c)
    IF ((1<<18)&bits) > 0 & d DO changed := changed | bmfn(g, d)
    IF ((1<<19)&bits) > 0 & e DO changed := changed | bmfn(g, e)
    IF ((1<<20)&bits) > 0 & f DO changed := changed | bmfn(g, f)
  }
  IF h DO
  { IF ((1<<21)&bits) > 0 & a DO changed := changed | bmfn(h, a)
    IF ((1<<22)&bits) > 0 & b DO changed := changed | bmfn(h, b)
    IF ((1<<23)&bits) > 0 & c DO changed := changed | bmfn(h, c)
    IF ((1<<24)&bits) > 0 & d DO changed := changed | bmfn(h, d)
    IF ((1<<25)&bits) > 0 & e DO changed := changed | bmfn(h, e)
    IF ((1<<26)&bits) > 0 & f DO changed := changed | bmfn(h, f)
    IF ((1<<27)&bits) > 0 & g DO changed := changed | bmfn(h, g)
  }

  RESULTIS changed
}

AND explorechildrenof(relno, depth) = VALOF
// relno   is the position in relv of the pivot relation.
// depth   is the current depth (<=maxdepth).

// On entry the current state is replesented by
// relv    with relv!0(=n) the number of relations
//         and  relv!1 .. relv!n  are the relations
//         The pivot relation is relv!relno

// maxid   is the maximum identifier used.
// id2prev is the current id to previous id mapping vector.
// mat     is the current matrix

// For each possible setting of the variables of the pivot relation,
//   copy the relations (other than pivot and the deleted ones),
//   setting the variables specified by the selected setting.

{ // First save the current state
  LET oldspacep = spacep
  LET oldrelv   = relv
  LET oldmat    = mat
  LET varsetv   = getvec(maxid) // Used to hold the selected setting.

  LET pivot = relv!relno
  LET v     = @pivot!r_a
  LET n     = mat!0
  LET nw    = n/bytesperword + 1
  LET upb   = 4*n*nw

  LET v0, v1, v2, v3 = v!0,  v!1,  v!2,  v!3
  LET v4, v5, v6, v7 = v!4,  v!5,  v!6,  v!7 

  // Allocate new mat, matprev and relv vectors.
  mat     := spacep; spacep := spacep+upb+1
  matprev := spacep; spacep := spacep+upb+1
  intmat  := spacep; spacep := spacep+upb+1
  relv    := spacep

  IF spacep>=spacet DO
  { sawritef("More space needed*n")
    GOTO fin
  }

  bm_copy(oldmat, mat)

  // Set the intersection matrix to all ones
  bm_set(#xFFFFFFFF, intmat)

  UNLESS varsetv DO
  { sawritef("explorechildren: more space needed*n")
    RESULTIS FALSE
  }
  // varsetv holds the variable setting for the current child.
  // varsetv!id = -1 if the variable is not being set
  // varsetv!id =  0 if the variable is being set to 0
  // varsetv!id =  1 if the variable is being set to 1
  FOR i = 0 TO maxid DO varsetv!0 := -1

//wrrel(r)

  { LET a7, p7 = 0, @pivot!r_w0
    { LET a6, p6 = 0, p7
      varsetv!v7 := a7
      { LET a5, p5 = 0, p6
        varsetv!v6 := a6
        { LET a4, w4 = 0, !p5
sawritef("%n%n%n      %bW*n", a7, a6, a5, w4)
          IF w4 DO
          { varsetv!v5 := a5
            { LET a3, w3 = 0, w4&#xFFFF
              IF w3 DO
              { varsetv!v4 := a4
                { LET a2, w2 = 0, w3&#xFF
                  IF w2 DO
                  { varsetv!v3 := a3
                    { LET a1, w1 = 0, w2&#xF
                      IF w1 DO
                      { varsetv!v2 := a2
                        { LET a0, w0 = 0, w1&#x3
                          IF w0 DO
                          { varsetv!v1 := a1
                            { IF (w0&1)>0 DO
                              { varsetv!v0 := a0

sawritef("exploring: bits=%b8 %-%i3*n",
          a0+2*a1+4*a2+8*a3+16*a4+32*a5+64*a6+128*a7)
/*
sawritef("exploring: *
         *v%n=%n v%n=%n v%n=%n v%n=%n *
         *v%n=%n v%n=%n v%n=%n v%n=%n*n",
          origid(v0), a0,
          origid(v1), a1,
          origid(v2), a2,
          origid(v3), a3,
          origid(v4), a4,
          origid(v5), a5,
          origid(v6), a6,
          origid(v7), a7)
abort(1000)
*/
                                IF explorenewstate(pivot, varsetv, depth+1) DO
                                { // This child is either known
                                  // to be satisfiable or inconsistant
                                  RESULTIS TRUE
                                }
                                IF bm_and(intmat, mat) DO
                                { // The intersection is all zeroes,
                                  // so nothing new has been found and
                                  // there is no point in exploring the
                                  // other children.
                                  RESULTIS FALSE
                                }
                              }
                   
                              IF a0 | v0=0 BREAK
                              a0, w0 := 1, w0>>1
                            } REPEAT
                          }
                          IF a1 | v1=0 BREAK
                          a1, w1 := 1, w1>>2
                        } REPEAT
                      }
                      IF a2 | v2=0 BREAK
                      a2, w2 := 1, w2>>4
                    } REPEAT
                  }
                  IF a3 | v3=0 BREAK
                  a3, w3 := 1, w3>>8
                } REPEAT
              }
              IF a4 | v4=0 BREAK
              a4, w4 := 1, w4>>16
            } REPEAT
          }
          IF a5 | v5=0 BREAK
          a5, p5 := 1, p5+1
        } REPEAT
        IF a6 | v6=0 BREAK
        a6, p6 := 1, p6+2
      } REPEAT
      IF a7 | v7=0 BREAK
      a7, p7 := 1, p7+4
    } REPEAT
  }

fin:
  IF varsetv DO freevec(varsetv)
}

AND explorenewstate(pivot, varsetv, depth) = VALOF
{
  sawritef("explorenewstate: entered, depth=%n*n", depth)
  RESULTIS FALSE
}

.

SECTION "utils"

GET "libhdr"
GET "chk8.h"

LET bug(mess, a,b,c) BE
{ writef(mess, a, b, c)
  abort(999)
}

/*
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
*/

LET rdrels(name) = VALOF
{ // Reads the specified file of relations. Each relation consists of
  // up to hex numbers for the pattern followed by up to 8 variables
  // of the form v<num> (eg v36 or v0).
  // The result is the list of relations, or zero if there is an error.

  LET list = 0      // This will be the resulting list of relations
  LET last = @list
  LET oldin = input()
  LET data = findinput(name)
  LET value = ?

  lineno := 1

  UNLESS data DO
  {  writef("Unable to open data file: %s*n", name)
     GOTO fin
  }
  selectinput(data)
  ch := rdch()
  lex()

  UNTIL token=s_eof DO
  { LET rel = spacep  // Position of next relation node
    LET w   = @rel!r_w0
    LET v   = @rel!r_a
    UNLESS token=s_bits BREAK

    // Allocate a new relation (in spacev).
    spacep := spacep + r_upb + 1
    IF spacep > spacet DO
    { writef("More space needed*n")
      BREAK
    }

    FOR i = 0 TO r_upb DO rel!i := 0

    w!0 := lexval
    lex()

    FOR i = 1 TO 7 DO      // Read the bit pattern words
    { UNLESS token=s_bits BREAK
      w!i := lexval
      lex()
    }

    UNLESS token=s_var DO
    { writef("Bad relation data -- variable expected*n")
      BREAK
    }

    FOR i = 0 TO 7 DO      // Read the variable identifiers
    { UNLESS token=s_var BREAK
      v!i := lexval
      lex()
    }

    // Fill in the relation properties
    rel!r_inrellist := FALSE  // Not in the stack.
    rel!r_args := 0         // Not set yet.
    rel!r_link := 0         // Append rel to the list
    !last := rel
    last := rel

    //wrrel(rel, TRUE)
//sawritef("rdrels:  removing duplicates and dealing with zero args*n")

    // Remove duplicate variables and deal with zero arguments.
    FOR argi = 0 TO 6 DO
    { LET id = v!argi
      TEST id
      THEN { FOR argj = argi+1 TO 7 IF id=v!argj DO
             { // Two arguments refer to the same variable
//sawritef("rdrels:  arg%n same as arg%n = v%n*n", argi, argj, origid(id))
               apeq(rel, argi, argj)
             }
           }
      ELSE { // argi is v0 so has value zero
//sawritef("rdrels:  arg%n is zero*n", argi)
             apset0(rel, argi)
           }
    }
    // Check whether arg7 is v0
    UNLESS v!7 DO apset0(rel, 7)

    //wrrel(rel, TRUE)
//sawritef("rdrels:  Sort arguments into decreasing order*n")

    // Sort arguments into decreasing order
    FOR argi = 0 TO 6 DO
    { LET k = argi // Will be the position of the largest identifier
      FOR argj = argi+1 TO 7 IF v!k < v!argj DO k := argj
      // k is the argument number of the largest remaining variable
      // swap i with k if necessary
      UNLESS k=argi DO
      {
//sawritef("rdrels:  Swapping arg%n with arg%n*n", argi, k)
        exchargs(rel, argi, k)
      }
    }
    // Set the number of arguments in rel.
    rel!r_args := 0
    FOR argi = 7 TO 0 BY -1 IF v!argi DO { rel!r_args := argi+1; BREAK }
    //wrrel(rel, TRUE)
//abort(1000)
  }

fin:
  IF data UNLESS data=oldin DO endread()
  selectinput(oldin)
  RESULTIS list
}

AND lex() BE
{ SWITCHON ch INTO
  { DEFAULT:  writef("Line %i3: Bad relation data, ch=%n '%c'*n", lineno, ch, ch)

    CASE endstreamch:
               token := s_eof
               RETURN

    CASE '*n':                              // White space
               lineno := lineno+1
    CASE '*s': ch := rdch()
               LOOP

    CASE '#':                               // Comment
              ch := rdch() REPEATUNTIL ch='*n' | ch=endstreamch
              LOOP

    CASE 'v':                               // A variable
    CASE 'V': ch := rdch()
              lexval := rdnum()
              token := s_var
              RETURN

    CASE 'a':CASE 'b':CASE 'c':CASE 'd':CASE 'e':CASE 'f':
    CASE 'A':CASE 'B':CASE 'C':CASE 'D':CASE 'E':CASE 'F':
    CASE '0':CASE '1':CASE '2':CASE '3':CASE '4':
    CASE '5':CASE '6':CASE '7':CASE '8':CASE '9':
              lexval := rdhex()
              token := s_bits
              RETURN
  }
} REPEAT


// Read a hexadecimal number
AND rdhex() = VALOF
{ LET res = 0

  { LET dig = -1
    IF '0'<=ch<='9' DO dig := ch - '0'
    IF 'A'<=ch<='F' DO dig := ch - 'A' + 10
    IF 'a'<=ch<='f' DO dig := ch - 'a' + 10
    IF dig<0 BREAK
    res := (res<<4) + dig
    ch := rdch()
  } REPEAT

  RESULTIS res
} REPEAT

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
AND wrrels(rv, verbose) BE
{ //writef("wrrels: rv=%n rv!0=%n*n", rv, rv!0)
  FOR i = 1 TO rv!0 DO wrrel(rv!i, verbose)
  newline()
}

// Write out a particular relation
AND wrrel(rv, verbose) BE
{ LET upb = 7

  // Find the highest non zero argument.
  WHILE upb>0 DO
  { IF rv!(r_a+upb) BREAK
    upb := upb-1
  }

  writef("*n%i3: ", rv!r_relno)

  FOR i = r_a TO r_a+upb DO writef("v%n ",  origid(rv!i))

  IF verbose DO
    writef(" instack=%n weight=%n args=%n",
            rv!r_inrellist, getweight(rv), rv!r_args)
  IF rv!r_deleted DO writef("  deleted")

  newline()
  FOR i = r_w7 TO r_w0 BY -1 DO writef("%x8 ", rv!i)
  newline()

  IF FALSE DO
  {
  writes("AAAAAAAA AAAAAAAA AAAAAAAA AAAAAAAA AAAAAAAA AAAAAAAA AAAAAAAA AAAAAAAA a0*n")
  writes("CCCCCCCC CCCCCCCC CCCCCCCC CCCCCCCC CCCCCCCC CCCCCCCC CCCCCCCC CCCCCCCC a1*n")
  writes("F0F0F0F0 F0F0F0F0 F0F0F0F0 F0F0F0F0 F0F0F0F0 F0F0F0F0 F0F0F0F0 F0F0F0F0 a2*n")
  writes("FF00FF00 FF00FF00 FF00FF00 FF00FF00 FF00FF00 FF00FF00 FF00FF00 FF00FF00 a3*n")
  writes("FFFF0000 FFFF0000 FFFF0000 FFFF0000 FFFF0000 FFFF0000 FFFF0000 FFFF0000 a4*n")
  writes("FFFFFFFF 00000000 FFFFFFFF 00000000 FFFFFFFF 00000000 FFFFFFFF 00000000 a5*n")
  writes("FFFFFFFF FFFFFFFF 00000000 00000000 FFFFFFFF FFFFFFFF 00000000 00000000 a6*n")
  writes("FFFFFFFF FFFFFFFF FFFFFFFF FFFFFFFF 00000000 00000000 00000000 00000000 a7*n")
  }
}

AND wrvars() BE
{ FOR id = 1 TO maxid DO
  { LET p     = idvecs!id
    LET q     = idvecs!(id+1)
    LET count = idcountv!id
    LET info  = varinfo!id
    LET i     = info/2
    writef("%i3: v%z2 ", id, origid(id))
    SWITCHON info INTO
    { DEFAULT:  IF info>0 DO
                { writef("= %cv%z2 ", info REM 2 -> '~', ' ', origid(info/2))
                  ENDCASE
                }
                writef("????    "); ENDCASE
      CASE -3:  writef("= I     "); ENDCASE // There is info about id
                                            // in the matrix
      CASE -2:  writef("= Z     "); ENDCASE // id = 0 or 1
      CASE -1:  writef("= ?     "); ENDCASE // value of id unknown
      CASE  0:  writef("= 0     "); ENDCASE // id = 0
      CASE  1:  writef("= 1     "); ENDCASE // id = 1
    }
    writef("  %i3  rels:", count)
    //writef("wrvars: p=%n q=%n*n", p, q)
    FOR ptr = p TO q-1 IF !ptr DO
    { LET rel = !ptr
      writef(" %i3", rel!r_relno)
    }
    newline()
//abort(3333)
  }
}

AND origid(id) = VALOF
// Return the original identifier number for given id.
{ LET tab = id2prev
  IF id WHILE tab DO
  { id := tab!id
    tab := !tab
  }
  RESULTIS id
}

AND renameidentifiers(rv)= VALOF
// This routine sets maxid to the number of distinct
// identifiers used in the given set of relations. It
// renames the identifiers to be in the range 1 to maxid
// and then creates and initialises the following vectors.

// idcountv    idcountv!id holds the number of uses of
//             each identifier.
// idvecs      idvecs!id is a vector holding the idcounts!id
//             relations that use the id.
// id2prev     a vector mapping new ids to the previous ids.
//             This is used by the function origid.
// varinfo     a vector holding information about each new ids

// On entry
// rv!0 (= n)      the number of relations
// rv!1 to rv!n    the given relations
{ LET n        = rv!0
  LET iduses   = 0
  LET old2new  = 0

  // Find the largest identifier used used in any relation.
  LET maxoldid = 0
  LET maxnewid = 0
  FOR i = 1 TO n DO
  { LET rel = rv!i
    LET v = @rel!r_a
    FOR j = 0 TO 7 DO
    { LET id = v!j  // Look at every variable used by every relation
      UNLESS id LOOP
      IF maxoldid<id DO maxoldid := id  // Maximum old identifier
    }
  }
  //writef("Max old id = %n*n", maxoldid)

  old2new   := getvec(maxoldid)

  UNLESS old2new DO
  { writef("More space needed for old2new*n")
    abort(999)
    GOTO fin
  }

  FOR id = 0 TO maxoldid DO old2new!id := 0

  // Mark all identifiers that have been used
  FOR r = 1 TO n DO // Look at every relation
  { LET rel = rv!r
    LET v = @rel!r_a
    FOR argi = 0 TO 7 DO // Look at every relation argument
    { LET id = v!argi
      IF id DO old2new!id := -1 // This old id has been used
    }
  }

  // Fill in the old2new table entries and
  // calculate maxid -- the number of identifiers used.
  // Replace all elements with value -1 with consecutive
  // integers from 1 to maxid.
  maxnewid     := 0
  old2new!0 := 0 // Identifier 0 always maps to zero
  FOR id = 1 TO maxoldid IF old2new!id DO
  { maxnewid := maxnewid+1
    old2new!id := maxnewid
  }

  //writef("Max new id = %n*n", maxid)

  // Allocate various vectors with upb maxid.
  idcountv := spacep; spacep := spacep+maxnewid+1
  id2prev  := spacep; spacep := spacep+maxnewid+1
  varinfo  := spacep; spacep := spacep+maxnewid+1

  // idvecs has one extra element to point just past the end.
  idvecs   := spacep; spacep := spacep+maxnewid+1+1

  UNLESS spacep<=spacet DO
  { writef("More space needed*n")
    abort(999)
    GOTO fin
  }

  // Fill in id2prev
  id2prev!0 := 0              // No previous mapping vector.
  FOR id = 1 TO maxoldid IF old2new!id DO
    id2prev!(old2new!id) := id

  FOR id = 0 TO maxnewid DO
    varinfo!id, idvecs!id, idcountv!id := -1, 0, 0

  // Renumber the variable identifiers and fill in the
  // counts in idcountv.
  FOR r = 1 TO n DO // Look at every relation
  { LET rel = rv!r
    LET v = @rel!r_a
    FOR argi = 0 TO 7 DO // Look at every relation argument
    { LET id = v!argi
      IF id DO
      { LET newid = old2new!id
        v!argi := newid       // Renumber identifier in situ.
        idcountv!newid := idcountv!newid + 1
      }
    }
  }

  // Allocate the idvec for each identifier
  FOR id = 1 TO maxnewid DO
  { idvecs!id := spacep
    spacep := spacep + idcountv!id // Leave room for the
                                   // required number of
                                   // references
  }
  idvecs!(maxnewid+1) := spacep       // Fill in the end marker

  // Fill in each idvec
  FOR id = 1 TO maxnewid DO idcountv!id := 0

  FOR r = 1 TO n DO // Look at every relation
  { LET rel = rv!r
    LET v = @rel!r_a
    FOR argi = 0 TO 7 DO // Look at every relation argument
    { LET id = v!argi
      IF id DO
      { LET n = idcountv!id   // The number of times this id
                              // has been used so far.
        idvecs!id!n := rel    // Fill in the idvec reference
                              // to this relation.
        idcountv!id := n + 1
      }
    }
  }

//writef("*nrenameidentifiers: calling wrrels*n")
//wrrels(rv, TRUE)
//abort(1111)

fin:
  IF old2new DO freevec(old2new)
  RESULTIS maxnewid
}

AND invec(x, v, n) = VALOF
{ FOR i = 0 TO n-1 IF x=v!i RESULTIS TRUE
  RESULTIS FALSE
}

AND length(p) = VALOF
{ LET res = 0
  WHILE p DO res, p := res+1, !p
  RESULTIS res
}

/*
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
*/

AND getweight(rel) = VALOF
{ LET v = @rel!r_a
  LET weight, count = 0, 0
  FOR arg = 0 TO 7 DO
  { LET id = v!arg
    UNLESS id LOOP
    count := count + 1
    IF idcountv DO weight := weight + idcountv!id
  }
  RESULTIS weight
}

AND pushrel(rel) BE UNLESS rel!r_inrellist DO
{ //writef("pushrel: pushing the following relation into rellist*n")
  //wrrel(rel)
  rel!r_link := rellist
  rellist := rel
  rel!r_inrellist := TRUE
}

AND poprel() = VALOF
{ LET rel = rellist
  IF rel DO
  { rellist := rel!r_link
    rel!r_inrellist := FALSE
  }
  //TEST rel
  //THEN { writef("poprel: Popped the following relation from rellist*n")
  //       wrrel(rel, TRUE)
  //     }
  //ELSE  writef("poprel: Returning 0 (rellist was empty)*n")
  RESULTIS rel
}

// Unlink one reference to rel in refs!id
AND rmref(rel, id) BE
{ LET p = idvecs!id
  AND q = idvecs!(id+1)  // Start of the next idvec
  //wrrel(rel, TRUE)
  //writef("rmref: rel %n v%n*n", rel!r_relno, id)
//abort(5555)
  WHILE p<q DO
  { IF rel = !p DO
    { !p := 0      // Remove the reference to rel for this id. 
      idcountv!id := idcountv!id-1 
      RETURN
    }
    p := p+1
  }

  writef("rmrel: error v%n not used in relation %n*n",
          id, rel!r_relno)
  abort(999)
}

AND andrelbits1(rel, w0) BE
{ LET w = @rel!r_w0
  w!0 := w!0 & w0
  w!1 := w!1 & w0
  w!2 := w!2 & w0
  w!3 := w!3 & w0
  w!4 := w!4 & w0
  w!5 := w!5 & w0
  w!6 := w!6 & w0
  w!7 := w!7 & w0
}

AND andrelbits2(rel, w0, w1) BE
{ LET w = @rel!r_w0
  w!0 := w!0 & w0
  w!1 := w!1 & w1
  w!2 := w!2 & w0
  w!3 := w!3 & w1
  w!4 := w!4 & w0
  w!5 := w!5 & w1
  w!6 := w!6 & w0
  w!7 := w!7 & w1
}

AND andrelbits4(rel, w0, w1, w2, w3) BE
{ LET w = @rel!r_w0
  w!0 := w!0 & w0
  w!1 := w!1 & w1
  w!2 := w!2 & w2
  w!3 := w!3 & w3
  w!4 := w!4 & w0
  w!5 := w!5 & w1
  w!6 := w!6 & w2
  w!7 := w!7 & w3
}

AND andrelbits8v(rel, v) BE
{ LET w = @rel!r_w0
  w!0 := w!0 & v!0
  w!1 := w!1 & v!1
  w!2 := w!2 & v!2
  w!3 := w!3 & v!3
  w!4 := w!4 & v!4
  w!5 := w!5 & v!5
  w!6 := w!6 & v!6
  w!7 := w!7 & v!7
}

.

/*
This module contains debugging aids to test various  functions
in the a tautology checker.

Implemented in BCPL by Martin Richards (c) July 2003
*/

SECTION "debug"

GET "libhdr"
GET "chk8.h"

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
  CASE  8:  check8(); RETURN
  CASE  9:  check9(); RETURN
  CASE 10:  check10(); RETURN
}

AND check1() BE
{ 
  writef("Testing the Boolean matrix functions*n")

  maxid := 36
  varinfo := getvec(2*maxid+1)
  FOR i = 0 TO 2*maxid+1 DO varinfo!i := -1
  

  writef("maxid = %n*n", maxid)

  mat     := bm_mk(maxid)
  matprev := bm_mk(maxid)
  bm_set(0, mat)
  bm_copy(mat, matprev)


  bm_imppn(5,  6)
  bm_impnp(1,  1)
  bm_imppp(3,  4)
  bm_imppp(4,  1)
  //bm_set0(1)
  //bm_set0(2)
  //bm_imppp(3,  4)
  bm_imppn(6,  2)

  bm_impnp( 5, 34)
  bm_imppp(34, 35)
  bm_imppn(35, 36)
  bm_impnp(36,  1)

  //bm_pr(mat)
  writef("*ncalling bm_warshall()*n")
  bm_warshall(mat)
  //bm_pr(mat)

  writef("*ncalling bm_apnewinfo()*n")
  bm_apnewinfo()
}

AND check2() BE
{ // test the exchargs function
  writef("Testing the exchargs function*n")


  FOR b = 0 TO 255 DO
  { LET r1 = VEC r_upb  // A relation node
    LET r2 = VEC r_upb  // A relation node
    LET ws = VEC 7
    // Set up a (random) relation data
    FOR i = 0 TO 7 DO ws!i := 0
    { setbit(b, ws, 1) 
    }

    //IF FALSE DO // Comment out to set random data
    { // Only do the random data test 20 times
      IF b>20 RETURN
      FOR i = 0 TO 7 DO
      { LET word = randno(1000000) XOR randno(1000000)<<16
        ws!i := word
      }
    }

    // Copy the test relation node

    FOR argi = 0 TO 7 FOR argj = 0 TO 7 DO
    { LET ok = TRUE
      FOR i = 0 TO r_upb DO r1!i, r2!i := 0, 0
      r1!r_relno := 1
      r2!r_relno := 2
      r1!r_args  := 8
      r2!r_args  := 8
      FOR i = 0 TO 7 DO
      { r1!(r_w0+i) := ws!i
        r1!(r_a+i)  := i+1    // Set the args to v1,...,v8
        r2!(r_w0+i) := ws!i
        r2!(r_a+i)  := i+1    // Set the args to v1,...,v8
      }

      //IF argi=0 & argj=0 DO
      //{ writef("Doing exchange test with b=%n*n", b)
      //  //wrrel(r2, TRUE); newline()
      //}

      //wrrel(r2, TRUE); newline()
      //writef("calling exchargs(r2, %n, %n)*n", argi, argj)
      exchargs(r2, argi, argj)
      //wrrel(r2, TRUE); newline()

      TEST checkeqv(r1, r2)
      THEN SKIP //writef("OK*n")
      ELSE { writef("###### exchargs(r2, %n, %n) failed ######*n", argi, argj)
             wrrel(r1); newline()
             wrrel(r2); newline()
             abort(999)
           }
      //abort(2000)
    }
  }
}

AND setb(p, b) BE
{ LET i = b/32
  AND sh = b REM 32
  p!i := p!i | (1<<sh)
}

AND check3() BE
{ 
  writef("Testing findimps*n")
  RETURN

  FOR i = 1 TO 10 DO
  { LET r1, r2 = relv!1, relv!2
    FOR j = 0 TO r_upb DO r2!j := r1!j
    bm_set(0, mat)
    bm_set(0, matprev)
    IF i=1 DO {
      wrrel(r2); newline()
      apeq(r2, 7, 6)
      wrrel(r2); newline()
    }
    findimps(r2)
    bm_apnewinfo()
  }
}

AND check4() BE
{ // Test standardise and split
  writef("Testing standardise and split*n")
  RETURN

  FOR a = 0 TO 7 DO
  FOR b = 1 TO 7 DO
  FOR c = 2 TO 7 DO
  FOR d = 3 TO 7 DO
  FOR e = 4 TO 7 DO
  FOR f = 5 TO 7 DO
  FOR g = 6 TO 7 DO
  { LET r = relv!1
    LET x = #x1C340000
    LET y = #x00001C34
    LET z = #x1C341C34
    LET t = #xACBDEF01
    FOR i = 0 TO 7 DO r!(r_w0+i) := 0
    //r!r_w1, r!r_w2, r!r_w4, r!r_w5, r!r_w6 := x,z,y,y,x  // split4
    //r!r_w1, r!r_w2, r!r_w4, r!r_w5, r!r_w6 := t,t,t,t,t  // split3
    r!r_w0, r!r_w1, r!r_w6, r!r_w7 := z,t,z,t              // split2

    exchargs(r, 0, a)
    exchargs(r, 1, b)
    exchargs(r, 2, c)
    exchargs(r, 3, d)
    IF a=5 & b=3 & c=3 & d=7 & e=6 & f=6 & g=7 DO
      r!r_w5 := r!r_w5 + 1  // stop one of them being splitable
    exchargs(r, 4, e)
    exchargs(r, 5, f)
    exchargs(r, 6, g)
    FOR i = 0 TO 7 DO r!(r_a+i) := 20+i
    //wrrel(r); newline()
    //standardise(r)
    //wrrel(r); newline()
    UNLESS split(r) DO
    { writef("Can't split*n")
      wrrel(r); newline()
      abort(9999)
    }
    //wrrel(r); newline()
  }
}

AND check5() BE
{ LET rel = relv!1
  LET v, w = @rel!r_a, @rel!r_w0
  LET wv = VEC 7
  writef("Testing apimppp, apimppn, apimpnp and apimpnn*n")
  RETURN

  FOR i = 0 TO 7 DO
  { LET word = randno(1000000) XOR randno(1000000)<<16
    wv!i := word
   }

  // test apimppp, apimppn, apimpnp and apimpnn
  FOR i = 0 TO 7 FOR j = 0 TO 7 DO
  { // Set up a relation
    FOR i = 0 TO 7 DO v!i, w!i := 10+i, wv!i
    bm_set(0, mat)
    bm_set(0, matprev)
    apimppp(rel, i, j)
    writef("testing v%n -> v%n*n", i, j)
    wrrel(rel, FALSE)
    findimps(rel)//; bm_apnewinfo()
    newline()

    FOR i = 0 TO 7 DO v!i, w!i := 10+i, wv!i
    bm_set(0, mat)
    bm_set(0, matprev)
    apimppn(rel, i, j)
    writef("testing v%n ->~v%n*n", i, j)
    wrrel(rel, FALSE)
    findimps(rel)//; bm_apnewinfo()
    newline()

    FOR i = 0 TO 7 DO v!i, w!i := 10+i, wv!i
    bm_set(0, mat)
    bm_set(0, matprev)
    apimpnp(rel, i, j)
    writef("testing ~v%n -> v%n*n", i, j)
    wrrel(rel, FALSE)
    findimps(rel)//; bm_apnewinfo()
    newline()

    FOR i = 0 TO 7 DO v!i, w!i := 10+i, wv!i
    bm_set(0, mat)
    bm_set(0, matprev)
    apimpnn(rel, i, j)
    writef("testing ~v%n -> ~v%n*n", i, j)
    wrrel(rel, FALSE)
    findimps(rel)//; bm_apnewinfo()
    newline()
    abort(1000)
  }
}

AND check6() BE
{ LET rel = relv!1
  LET v, w = @rel!r_a, @rel!r_w0
  LET wv = VEC 7
  FOR i = 0 TO 7 DO
  { LET word = randno(1000000) XOR randno(1000000)<<16
    wv!i := word
   }

  writef("Testing exchargs with apimppp, apimppn, apimpnp and apimpnn*n")
  RETURN

  // test exchargs with apimppp, apimppn, apimpnp and apimpnn
  FOR i = 0 TO 7 FOR j = 0 TO 7 DO
  { // Set up a relation
    FOR i = 0 TO 7 DO v!i, w!i := 10+i, wv!i
    bm_set(0, mat)
    bm_set(0, matprev)
    apimppp(rel, i, j)
    exchargs(rel, i, j)
    writef("testing v%n -> v%n*n", i, j)
    wrrel(rel, FALSE)
    findimps(rel)//; bm_apnewinfo()
    newline()

    FOR i = 0 TO 7 DO v!i, w!i := 10+i, wv!i
    bm_set(0, mat)
    bm_set(0, matprev)
    apimppn(rel, i, j)
    exchargs(rel, i, j)
    writef("testing v%n ->~v%n*n", i, j)
    wrrel(rel, FALSE)
    findimps(rel)//; bm_apnewinfo()
    newline()

    FOR i = 0 TO 7 DO v!i, w!i := 10+i, wv!i
    bm_set(0, mat)
    bm_set(0, matprev)
    apimpnp(rel, i, j)
    exchargs(rel, i, j)
    writef("testing ~v%n -> v%n*n", i, j)
    wrrel(rel, FALSE)
    findimps(rel)//; bm_apnewinfo()
    newline()

    FOR i = 0 TO 7 DO v!i, w!i := 10+i, wv!i
    bm_set(0, mat)
    bm_set(0, matprev)
    apimpnn(rel, i, j)
    exchargs(rel, i, j)
    writef("testing ~v%n -> ~v%n*n", i, j)
    wrrel(rel, FALSE)
    findimps(rel)//; bm_apnewinfo()
    newline()
    abort(1000)
  }
}

AND check7() BE
{ LET rel1 = VEC r_upb
  LET rel2 = VEC r_upb

  writef("Measuring the cost of standardise*n")
  RETURN

  FOR i = 0 TO r_upb DO rel1!i := 0
  FOR i = 0 TO 7 DO
  { rel1!(r_w0+i) := randno(1000000) XOR randno(1000000)<<16
    //rel1!(r_a+i) := i+1             // 1..8
    rel1!(r_a+i) := randno(9) - 1 // 0..8 random
  }
  wrrel(rel1, FALSE)
  FOR a = 0 TO 7 FOR b = 0 TO 7 DO
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

AND evalrel(rel, env) = VALOF
{ // Evaluate the relation assuming the variable settings set in env.
  // For each variable vi, env!vi holds its value (0 or 1).
  // The UPB of env is assumed to be large enough.
  LET a, b, c, d = rel!r_a, rel!r_b, rel!r_c, rel!r_d
  LET e, f, g, h = rel!r_e, rel!r_f, rel!r_g, rel!r_h
  LET i = env!f + 2*env!g + 4*env!h
  LET s = env!a + 2*env!b + 4*env!c + 8*env!d + 16*env!e
  RESULTIS rel!(r_w0+i)>>s & 1
}

AND checkeqv(rel1, rel2) = VALOF
{ LET env = VEC 8
  env!0 := 0
  FOR h = 0 TO 1 DO
  { env!8 := h
    FOR g = 0 TO 1 DO
    { env!7 := g
      FOR f = 0 TO 1 DO
      { env!6 := f
        FOR e = 0 TO 1 DO
        { env!5 := e
          FOR d = 0 TO 1 DO
          { env!4 := d
            FOR c = 0 TO 1 DO
            { env!3 := c
              FOR b = 0 TO 1 DO
              { env!2 := b
                FOR a = 0 TO 1 DO
                { LET res1, res2 = 0, 0
                  env!1 := a
                  res1 := evalrel(rel1, env)
                  res2 := evalrel(rel2, env)
                  UNLESS res1=res2 DO
                  { writef("*nhgfedcba=%n%n%n%n%n%n%n%n rel1=>%n rel2=>%n*n",
                            h,g,f,e,d,c,b,a, res1, res2)
                    //wrrel(rel1, FALSE)
                    //wrrel(rel2, FALSE)
                    //newline()
                    RESULTIS FALSE
                  }
                }
              }
            }
          }
        }
      }
    }
  }
  RESULTIS TRUE
}

AND check8()  BE writef("No check8 yet*n")
AND check9()  BE writef("No check9 yet*n")
AND check10() BE writef("No check10 yet*n")
