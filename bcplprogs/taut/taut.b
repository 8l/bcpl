GET "libhdr"

GLOBAL {
work:       150
workp:      151
workt:      152
tree:       153

worksize:   154
retcode:    155
retp:       156
retl:       157

stdin:      160
stdout:     161
datastream: 162
tostream:   163
termp:      164
termq:      165
count:      166
}

MANIFEST { BPW = bitsperword }

LET start() = VALOF
{ LET argv = VEC 50
  LET filename = "DATA"

  retcode := 0

  retp, retl := level(), ret
  stdin := input()
  stdout := output()

  datastream := 0
  tostream := 0
  work := 0

  IF rdargs("DATA,SIZE,TO/K", argv, 50)=0 DO
     error("Bad arguments for TORT*n")

  UNLESS argv!0=0 DO filename := argv!0

  worksize := 100000

  UNLESS argv!1=0 DO worksize := str2numb(argv!1)

  work := getvec(worksize)
  workt := work + worksize
  workp := workt

  IF work=0 DO
     error("Unable to allocate workspace of size %n", worksize)

  UNLESS argv!2=0 DO
  { tostream := findoutput(argv!2)
    IF tostream=0 DO error("Unable to open file '%s'", argv!2)
  }

  datastream := findinput(filename)
  IF datastream=0 DO error("Cannot open file %s", filename)
   
  writef("Tort entered, data file %s, size = %n*n", filename, worksize)

  selectinput(datastream)
  UNLESS tostream=0 DO selectoutput(tostream)

  tree := 0
  rdterms()
  writef("*nThe tree is:*n*n")
  prtree(tree, 0)
  writes("*n*n")

  termp := work
  !termp := tree
  termq := termp+1
  !termq := 0

  count := 0
  try(termp, 0, 0, 0, 0) // search for solutions

  writef("Number of solutions is %n*n", count)

ret:
  UNLESS datastream=0 DO { selectinput(datastream); endread() }
  UNLESS tostream=0 DO { selectoutput(tostream); endwrite() }
  selectinput(stdin)
  selectoutput(stdout)
  UNLESS work=0 DO freevec(work)
  RESULTIS retcode
}

AND rdn() = VALOF
{ LET res = 0
  LET neg = FALSE

  LET ch = rdch()

  UNTIL '0'<=ch<='9' | ch='-' | ch=')' | ch=endstreamch DO
  { IF ch='p' | ch='c' | ch=';' DO // a comment
    { UNTIL ch='*n' | ch=endstreamch DO ch := rdch()
      LOOP
    }
    ch := rdch()
  }

  IF ch=')' RESULTIS 0

  IF ch='-' DO { neg := TRUE; ch := rdch() }

  WHILE '0'<=ch<='9' DO { res := 10*res + ch - '0'; ch := rdch() }
  unrdch()
  RESULTIS neg -> -res, res
}

AND rdterms() BE
{ LET hwm = 0
  LET p = @ tree

  // read in a term into work
  { LET var = rdn()
    LET bitno = ABS var - 1
    LET i = 2 * (bitno / BPW)
    LET bitpos = bitno REM BPW
//writef("rdterms: var=%i4 bitno=%i4 i=%n bitpos=%n*n", var, bitno, i, bitpos)
    IF var=0 BREAK
    UNTIL hwm>i DO { work!hwm := 0; work!(hwm+1) := 0; hwm := hwm+2 }
    IF var<0 DO i := i+1
    work!i := work!i | 1<<bitpos
  } REPEAT

  // test whether another term present
  IF hwm=0 RETURN // no more terms

  // add the term to the term tree
  FOR i = 0 TO hwm-4 BY 2 TEST p=0
    THEN BREAK
    ELSE p := insert(work!i, work!(i+1), p, FALSE) // non final word
  // insert final word of the term
  p := insert(work!(hwm-2), work!(hwm-1), p, TRUE)
} REPEAT

AND insert(posbits, negbits, p, last) = p=0 -> 0, VALOF
{ LET den = bits(posbits|negbits)
//  writef("insert: %x8 %x8  bits=%n p=%i7*n", posbits, negbits, den, p)

  UNTIL !p=0 DO
  { LET a = !p
    LET pbits, nbits = a!0, a!1
    LET aden = bits(pbits|nbits)

    IF posbits=pbits & negbits=nbits DO
    { IF a!2=0 RESULTIS 0 // existing term is shorter
      UNLESS last RESULTIS @ a!2
      a!2 := 0 // this term is shorter
      RESULTIS 0
    }

    IF den>aden BREAK
    IF den=aden IF posbits>pbits | 
                   posbits=pbits & negbits>nbits BREAK
    p := @ a!3
  }

  !p := getblk(posbits, negbits, 0, !p)
  RESULTIS @ (!p)!2
}

AND bits(w) = w=0 -> 0, 1 + bits(w & (w-1))

AND getblk(a, b, c, d) = VALOF
{ LET p = workp-4
  IF p<work DO error("Larger work space needed")
  p!0, p!1, p!2, p!3 := a, b, c, d
  workp := p
//  writef("getblk %i7: %x8 %x8 %n %i7*n", p, a, b, c, d)
  RESULTIS p
}

AND prtree(t, d) BE UNLESS t=0 DO
{ writef("%x8-%x8  ", t!0, t!1)
  prtree(t!2, d+19)
  UNLESS t!3=0 DO
  { newline()
    FOR i = 1 TO d DO wrch(' ')
    prtree(t!3, d)
  }
}

AND error(form, a, b, c) BE
{ selectoutput(stdout)
  writef(form, a, b, c)
  newline()
  retcode := 20
  longjump(retp, retl)
}

// Every time try recurses it has set the value of one or more variables
// and so the maximum depth or recursion is no more that the number
// of variables in the expression under test.

// Try to satisfy term at p in a context in which
// the variables in posbits are already assigned to TRUE
// and the variables in negbits are already assigned to FALSE 
// If p=0 there are no more terms to satisfy in this group
AND try(tp, p, posbits, negbits, d) BE
{ LET pbits, nbits = ?, ?

//writef("try %i2: tp=%i7  p=%i7  %x8-%x8*n", d, tp, p, posbits, negbits)

  IF p=0 DO
  { // end of current group
    p := !tp
    tp := tp+1

    IF p=0 DO
    { // no more groups at this word position

      IF tp>termq  DO // any groups at next position?
      { count := count + 1 // no, so solution found
        writef("Solution %n*n", count)
        RETURN  // backtrack
      }
          
      // there is at least one more group of terms at this position
      termq := termq+1
      !termq := 0      // end of position marker

      // explore the groups in !tp ... !termq at new word position

      posbits, negbits := 0, 0
      LOOP
    }

    // explore the next group at this word position
    LOOP
  }

  // found a term, get its variables at this word position
  pbits, nbits := p!0, p!1

  UNLESS (posbits&pbits)=0 & (negbits&nbits)=0 DO
  { // the term already satisfied
    p := p!3  // find next term
    LOOP
  }


  // this term still has to be satisfied
writef("%x8-%x8  set %x8-%x8  |", p!0, p!1, posbits, negbits)
FOR i = 1 TO d DO wrch('+')
newline()

  // first, try all ways in which the term can be satisfied
  // at this position
  { LET tq = termq
    LET vars = (pbits|nbits) & ~(posbits|negbits)
    // each of the variables in vars could be used to satisfy
    // the term at this word position

    UNTIL vars=0 DO // select each variable in turn
    { LET var = vars & -vars // select a variable

//writef("vars=%x8  var=%x8*n", vars, var)
      vars := vars - var     // the remaining (later) variables

      // try satisfying the term using this variable,
      // setting the later variables so that none of
      // them cause the term to be satified.
      // these are all mutually exclusive trials. 
      try(tp, p!3, posbits | nbits&vars | pbits&var,
                   negbits | pbits&vars | nbits&var, d+1)
      termq := tq
    }
  }

  // The only other possibility is not to satisfy the term at 
  // this word position

  IF p!2=0 RETURN // backtrack, if there are more words in this term

  termq := termq+1
  !termq := p!2    // save the rest of the term for later exploration

//writef("save: %x8-%x8*n", termq, p!2!0, p!2!1)
  // set the variables so that this term is not satisfied 
  // at this position
  posbits := posbits|nbits
  negbits := negbits|pbits
  p := p!3                 // explore next term
} REPEAT

