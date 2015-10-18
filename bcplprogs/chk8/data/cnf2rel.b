/*
This program converts .cnf terms into .rel terms.

Implemented in BCPL by Martin Richards (c) July 2003

18/05/06
Changed the order of the hex numbers representing the relation
bit pattern. They are now a left to right representation of
the bit pattern.

The command:

cnf2rel x.cnf to x.rel

will, for instance, convert the file x.cnf:

1 -2 3 4 -5 0
2 3 -4 0
3 -4 5 -6 0
-1 -2 3 -4 5 6 0

to the file x.rel:

1287681723 1231876 12873612 187631 128733  287613 817263 18763
v1 v2 v3 v4 v5

1287681723 1231876 12873612 187631 128733  287613 817263 18763
v1 v2 v3 v4 v5

1287681723 1231876 12873612 187631 128733  287613 817263 18763
v1 v2 v3 v4 v5

1287681723 1231876 12873612 187631 128733  287613 817263 18763
v1 v2 v3 v4 v5

This is suitable input for the chk8 satisfiability tester.


*/

/*
Each cnf term is a sequence of signed integers terminated by a zero.

A rel term is a 256-bit pattern followed by eight non negative integers.
The bit pattern words are given from left to right, ie w7,w6,...,w0.
Leading zero words are omitted.

eg:
                   w7                  ..                 w0
a 10101010 10101010 10101010 10101010 .. 10101010 10101010 10101010 10101010
b 11001100 11001100 11001100 11001100 .. 11001100 11001100 11001100 11001100
c 11110000 11110000 11110000 11110000 .. 11110000 11110000 11110000 11110000
d 11111111 00000000 11111111 00000000 .. 11111111 00000000 11111111 00000000
e 11111111 11111111 00000000 00000000 .. 11111111 11111111 00000000 00000000
  |                                /      \                                |
  |         ----------------------          ----------------------         |
  |  w7   /   w6       w5       w4          w3       w2       w1   \   w0  |
f FFFFFFFF 00000000 FFFFFFFF 00000000    FFFFFFFF 00000000 FFFFFFFF 00000000 
g FFFFFFFF FFFFFFFF 00000000 00000000    FFFFFFFF FFFFFFFF 00000000 00000000 
h FFFFFFFF FFFFFFFF FFFFFFFF FFFFFFFF    00000000 00000000 00000000 00000000

The bits are numbered 0-255 from the right. Bit i (where i = hgfedcba) is
a one iff the pattern hgfedcba is in the relation. 
*/

GET "libhdr"

GLOBAL {
  nextvar : ug
  maxvar
}

MANIFEST {
  cnfvupb = 200
  all     = #xFFFFFFFF
}

LET start() = VALOF
{ LET retcode = 0
  LET cnfname = "t1.cnf"
  LET relname = "t1.rel"
  LET oldin = input()
  LET oldout = output()
  LET cnfstream = 0
  LET relstream = 0

  LET argv = VEC 50
  LET cnfv = VEC cnfvupb

  UNLESS rdargs("from,to/k",argv, 50) DO
  { writef("Bad arguments for cnf2rel*n")
    RESULTIS 0
  }

  IF argv!0 DO cnfname := argv!0
  IF argv!1 DO relname := argv!1

  writef("*nConverting %s to %s*n", cnfname, relname)

  cnfstream := findinput(cnfname)
  relstream := findoutput(relname)

  UNLESS cnfstream DO
  { writef("Unable to open %s*n", cnfname)
    RESULTIS FALSE
  }

  UNLESS relstream DO
  { writef("Unable to open %s*n", relname)
    RESULTIS FALSE
  }

  selectinput(cnfstream)
  selectoutput(relstream)

  maxvar, nextvar := 0, 10000 // May need to be larger
  //Generated variables are given numbers 9999, 9998, ...

  WHILE rdcnf(cnfv, cnfvupb) DO cnf2rel(cnfv+1, cnfv!0-1)

fin:
  IF cnfstream DO { selectinput(cnfstream); endread() }
  IF relstream DO { selectoutput(relstream); endwrite() }

  selectinput(oldin)
  selectoutput(oldout)

  writef("*nAll done*n")
  RESULTIS retcode
}

AND rdcnf(v, upb) = VALOF
{ // read the next CNF term into v!1 ... v!upb
  // v!0 is set to the number of literals in the term.
  LET n = 0
  LET val = 0

  WHILE rdn() & result2 DO
  { n := n+1
    IF n<=upb DO v!n := result2
  }
  v!0 := n
//sawritef("term: ")
//FOR i = 1 TO n DO sawritef(" %n", v!i)
//sawritef("*n")
  IF 1<=n<=upb RESULTIS TRUE
  RESULTIS FALSE
}

AND rdn() = VALOF
{ LET res, neg = 0, FALSE
  LET ch = ?

  // Ignore white space
  ch := rdch() REPEATWHILE ch=' ' | ch='*n' 

  // Ignore comments
  IF ch='#' | 'A'<=ch<='Z' | 'a'<=ch<='z' DO
  { UNTIL ch='*n' | ch=endstreamch DO ch := rdch()
    LOOP
  }

  IF ch=endstreamch RESULTIS FALSE

  IF ch='-' DO { neg := TRUE; ch := rdch() }
  UNLESS '0'<=ch<='9' RESULTIS FALSE

  { res := 10*res + ch - '0'
    ch := rdch()
  } REPEATWHILE '0'<=ch<='9'

  unrdch()
  IF neg DO res := -res
  result2 := res
  RESULTIS TRUE
} REPEAT

AND cnf2rel(v, upb) BE
{ // Output the CNF term as one or more relations over no more
  // than eight variables.
  // The CNF variables are in v!0 to v!upb
  // and v!(upb+1) is known to be available.

  // First write the term as a comment.
  wrch('#')
  FOR i = 0 TO upb DO writef(" %n", v!i)
  newline()

  // Break up large terms into ones that have no more
  // than eight variables.
  WHILE upb>7 DO
  { // The term has more than 8 variables so must be split.
    // For example:

    // a b c ... h i j k l m n o p

    // is split into

    // a b c ... h i ~x   and   j k l m n o p x

    // where x is a newly allocated variable number.

    LET x = nextvar-1    // Choose a new variable x
    nextvar := x
    v!(upb+1) := x
    cnf2rel8(v+upb-6, 7) // Convert:  j k l m n o p  x
    upb := upb-6         // Convert:  a b c ... h i ~x
    v!upb := -x

  }

  // The CNF term has no more than 8 variables and so
  // can be converted into a single relation.
  cnf2rel8(v, upb)
  newline()
}

AND cnf2rel8(v, upb) BE // upb <= 8
{ // The CNF literals are v!0 ... v!upb
  LET w = VEC 7
  LET bits = 0
  FOR i = 0 TO 7 DO w!i := 0
  FOR i = upb+1 TO 7 DO v!i := 0  // Pad the variables with 0s

  // w!0 will hold bits   0 to  31 of the relation
  // w!1 will hold bits  32 to  63 of the relation
  // ...
  // w!7 will hold bits 224 to 255 of the relation

  TEST v!0<0 THEN bits := bits | #x55555555     // v0=0 is allowed
             ELSE bits := bits | #xAAAAAAAA     // v0=1 is allowed

  TEST v!1<0 THEN bits := bits | #x33333333     // v1=0 is allowed
             ELSE bits := bits | #xCCCCCCCC     // v1=1 is allowed

  TEST v!2<0 THEN bits := bits | #x0F0F0F0F     // v2=0 is allowed
             ELSE bits := bits | #xF0F0F0F0     // v2=1 is allowed

  TEST v!3<0 THEN bits := bits | #x00FF00FF     // v3=0 is allowed
             ELSE bits := bits | #xFF00FF00     // v3=1 is allowed

  TEST v!4<0 THEN bits := bits | #x0000FFFF     // v4=0 is allowed
             ELSE bits := bits | #xFFFF0000     // v4=1 is allowed

  FOR i = 0 TO 7 DO w!i := w!i | bits

  TEST v!5<0
  THEN w!0, w!2, w!4, w!6 := all, all, all, all // v5=0 is allowed
  ELSE w!1, w!3, w!5, w!7 := all, all, all, all // v5=1 is allowed

  TEST v!6<0
  THEN w!0, w!1, w!4, w!5 := all, all, all, all // v6=0 is allowed
  ELSE w!2, w!3, w!6, w!7 := all, all, all, all // v6=1 is allowed

  TEST v!7<0
  THEN w!0, w!1, w!2, w!3 := all, all, all, all // v7=0 is allowed
  ELSE w!4, w!5, w!6, w!7 := all, all, all, all // v7=1 is allowed

  UNLESS v!7 DO w!4, w!5, w!6, w!7 := 0, 0, 0, 0
  UNLESS v!6 DO w!2, w!3, w!6, w!7 := 0, 0, 0, 0
  UNLESS v!5 DO w!1, w!3, w!5, w!7 := 0, 0, 0, 0
  UNLESS v!4 FOR i = 0 TO 7 DO w!i := w!i & #x0000FFFF
  UNLESS v!3 FOR i = 0 TO 7 DO w!i := w!i & #x00FF00FF
  UNLESS v!2 FOR i = 0 TO 7 DO w!i := w!i & #x0F0F0F0F
  UNLESS v!1 FOR i = 0 TO 7 DO w!i := w!i & #x33333333
  UNLESS v!0 FOR i = 0 TO 7 DO w!i := w!i & #x55555555

  newline()
  IF upb>=7 DO writef("%x8 %x8 %x8 %x8 ", w!7, w!6, w!5, w!4)
  IF upb>=6 DO writef("%x8 %x8 ",         w!3, w!2)
  IF upb>=5 DO writef("%x8  ",            w!1)
  writef("%x8 ", w!0)
  IF upb>=7 DO newline()
  FOR i = 0 TO upb DO writef("v%n ", ABS v!i)
  newline()
}
