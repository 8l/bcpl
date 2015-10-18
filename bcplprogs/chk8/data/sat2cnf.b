/*
This program converts .sat terms into .cnf terms.

The command:

sat2cnf x.sat to x.cnf

will, for instance, convert the file x.sat:

5 4
5  100  1 -2  3  4 -5
3  212  2  3 -4
4  133  3 -4  5
6   98 -1 -2  3 -4  5

to the file x.cnf:

  1 -2  3  4 -5 0
  2  3 -4 0
  3 -4  5 -6 0
 -1 -2  3 -4  5  6 0


Implemented in BCPL by Martin Richards (c) July 2003
*/

/*

The sat file starts with the number of variables and the number of
terms which are ignored. Then follows by the terms each consisting of:
the number of variables in the term, the weight of the term, and the n
variables as signed integers. Comments are introduced by #.

Each cnf term is a sequence of signed integers terminated by a zero.

*/

GET "libhdr"

GLOBAL {
  cnfv1 : ug
}

LET start() = VALOF
{ LET retcode = 0
  LET satname = "jnh307.sat"
  LET cnfname = "jnh307.cnf"
  LET oldin = input()
  LET oldout = output()
  LET satstream = 0
  LET cnfstream = 0

  LET argv = VEC 50
  LET cnfv = VEC 200

  UNLESS rdargs("from,to/k",argv, 50) DO
  { writef("Bad arguments for cnf2rel*n")
    RESULTIS 0
  }

  IF argv!0 DO satname := argv!0
  IF argv!1 DO cnfname := argv!1

  writef("Converting %s to %s*n", satname, cnfname)
  satstream := findinput(satname)
  cnfstream := findoutput(cnfname)

  UNLESS satstream DO
  { writef("Unable to open %s*n", satname)
    RESULTIS FALSE
  }

  UNLESS cnfstream DO
  { writef("Unable to open %s*n", cnfname)
    RESULTIS FALSE
  }

  selectinput(satstream)
  selectoutput(cnfstream)

  rdn() // Read the number of terms
  rdn() // Read the number of variables

  WHILE sat2cnf() LOOP

fin:
  IF satstream DO { selectinput(satstream); endread() }
  IF cnfstream DO { selectoutput(cnfstream); endwrite() }

  selectinput(oldin)
  selectoutput(oldout)

  writef("*nAll done*n")
  RESULTIS retcode
}

AND sat2cnf() = VALOF
{ LET n = 0
  LET val = 0

  UNLESS rdn() RESULTIS FALSE
  n := result2  // the number of variables in the term
  rdn()         // Ignore the weight
  FOR i = 1 TO n DO
  { UNLESS rdn() RESULTIS FALSE
    writef("%n ", result2)
    IF i REM 50 = 0 DO newline()
  }
  writes("0*n")
  RESULTIS TRUE
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

