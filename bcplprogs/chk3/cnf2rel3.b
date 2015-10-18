/*
This program was implemented in BCPL
by Martin Richards (c) October 2005

It converts .cnf terms into .rel terms where the relations are over no
more than 3 variables.

For instance, the command:

cnf2rel3 x.cnf to x.rel

will convert the file x.cnf:

 1 -2  0
 2  3 -4  0
-4  5 -6  0
-3  5  6  0

to the file x.rel:

# 1 -2
00001011 v1 v2 

# 2 3 -4
11101111 v2 v3 v4 

# -4 5 -6
11011111 v4 v5 v6 

# -3 5 6
11111101 v3 v5 v6 

This is suitable input for the chk3 satisfiability tester.

If the a cnf term contains more than three variables, it is
split into simpler terms using extra variables. For instance
the term 

1 -2 3 4 -5 0

is split into

4 -5 1000 0  and 1 -2 3 -1000 0

which in turn splits into

3 -1000 1001 0 and 1 -2 -1001 0

The resulting rel terms are:

# 1 -2 3 4 -5
11111011 v4 v5 v1000 
11111011 v3 v1000 v1001 
10111111 v1 v2 v1001 


The first extra variable is by default numbered 1000 but can be
specified using the argument xvar, as in:

cnf2rel3 data/tst2.cnl xvar 10

Unless all variable numbers in the cnf are less than the xvar value,
the program complains.

Each cnf term is a sequence of signed integers terminated by a zero.

A rel term is a 8-bit pattern followed by three non negative integers.

eg:  [relbits, x, y, z]

where relbits is an 8-bit pattern abcdefgh defined as follows:

  abcdefgh
x 01010101
y 00110011
z 00001111

ie if relbits = 10110100
   xyz can only be one of: 111, 101, 100 or 010
   so the relation is equivalent to: x=(y->z)
*/

GET "libhdr"

GLOBAL {
  nextvar : ug
  maxinputvar    // The largest variable number allowed in the input file.
  maxvar
}

MANIFEST {
  cnfvupb = 200 // The maximum number of literals in a cnf term
}

LET start() = VALOF
{ LET retcode = 0
  LET cnfname = "data/t1.cnf"   // The default cnf filename
  LET len = 0
  LET relname = VEC 50
  LET oldin = input()
  LET oldout = output()
  LET cnfstream = 0
  LET relstream = 0

  LET argv = VEC 50
  LET cnfv = VEC cnfvupb

  UNLESS rdargs("from,xvar,to/k,help/S",argv, 50) DO
  { writef("Bad arguments for cnf2rel3*n")
    RESULTIS 0
  }

  IF argv!3 DO
  { writef("*nArgument format: from,xvar,to/k,help/S*n*n")
    writef("from:  the name of the cnf file*n")
    writef("xvar:  the number of the first variable for cnf2rel3 to use*n")
    writef("to:    the name of the rel file*n")
    writef("help:  output this help information*n*n")

    writef("If the 'to' argument is not given, the output filename is the*n")
    writef("same as the cnf filename with its extension changed to .rel*n*n")

    RESULTIS 0
  }

  IF argv!0 DO cnfname := argv!0
  len := cnfname%0
  FOR i = 1 TO 4 UNLESS cnfname%(len-4+i)=".cnf"%i DO
  { writef("cnfname %s does not end in .cnf*n", cnfname)
    RESULTIS 0
  }
  FOR i = 0 TO len DO relname%i := cnfname%i
  FOR i = 1 TO 4 DO relname%(len-4+i) := ".rel"%i
  
  nextvar := 1000
  IF argv!1 & string.to.number(argv!1) DO nextvar := result2
  maxinputvar := nextvar-1

  IF argv!2 DO relname := argv!2

  writef("Converting %s to %s with xvar=%n*n", cnfname, relname, nextvar)

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

  maxvar := 0
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

AND rdcnf(v, vupb) = VALOF
{ LET n = 0
  LET val = 0

  WHILE rdn() & result2 DO
  { n := n+1
    IF n<=vupb DO v!n := result2
  }
  v!0 := n
  IF 1<=n<=maxinputvar RESULTIS TRUE
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

AND cnf2rel(v, upb) BE // Cnf variables are in v!0 to v!upb
{ wrch('#')
  FOR i = 0 TO upb DO writef(" %n", v!i)
  newline()

  WHILE upb>2 DO
  { LET newvar = nextvar
    nextvar := nextvar+1
    upb := upb-1
    v!(upb+2) := newvar
    cnf2rel3(v+upb, 2)
    v!upb := -newvar
  }
  cnf2rel3(v, upb)
  newline()
}

AND cnf2rel3(v, upb) BE // upb is known to be less than 3
{ LET relbits = 0
  FOR i = upb+1 TO 2 DO v!i := 0

  IF upb>=0 DO
  { // Variable v0
    LET bits = #xAA
    IF v!0<0 DO v!0, bits := -v!0, #xFF XOR bits
    relbits := relbits | bits
  }

  IF upb>=1 DO
  { // Variable v1
    LET bits = #xCC
    IF v!1<0 DO v!1, bits := -v!1, #xFF XOR bits
    relbits := relbits | bits
  }

  IF upb>=2 DO
  { // Variable v2
    LET bits = #xF0
    IF v!2<0 DO v!2, bits := -v!2, #xFF XOR bits
    relbits := relbits | bits
  }

  UNLESS v!2 DO relbits := relbits & #x0F
  UNLESS v!1 DO relbits := relbits & #x33
  UNLESS v!0 DO relbits := relbits & #x55


  writef("%b8 ", relbits)
  FOR i = 0 TO upb DO writef("v%n ", v!i)
  newline()
}


