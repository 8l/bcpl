/*
This is a simple program to help explore the Tag problem
described in Minsky's book "Computation, Finite and Infinite
Machines"

*/

GET "libhdr"

GLOBAL
{ p:ug    // Subscript of first byte of the string
  q       // Subscript just after the end of the string
  str     // Circular buffer of 0s and 1s
  len     // Length of current string
  r       // Sample string
  rlen    // Length of sample string
  range   // Maximum loop length currently being tested
  looplen // Current loop length under test
  tostream
  stdout
}

MANIFEST
{ strsize = 1<<16 // Number of words in str
  strupb  = strsize-1
  mask    = (strsize<<2) - 1
}

LET start() = VALOF
{ LET argv  = VEC 50
  //LET data  = "10010"
  //LET data  = "100100100100100100100"
  //LET data  = "111111111111111111111111111111111111111"
  //LET data  = "11111111111111111111111111111111111111111"
  LET data  = "01111111111111111111111111111111111111111"
  LET count = 100000
  LET trace = FALSE

  stdout := output()
  tostream := 0

  UNLESS rdargs("DATA,COUNT,TO/K,TRACE/S", argv, 50) DO
  { writef("Bad arguments for TAG*n")
    RESULTIS 20
  }
  IF argv!0 DO data  := argv!0
  IF argv!1 DO count := str2numb(argv!1)

  IF argv!2 DO
  { tostream := findoutput(argv!2)
    UNLESS tostream DO
    { writef("Can't open file %s*n", argv!2)
      RESULTIS 20
    }
  }
  trace := argv!3

  str := getvec(strupb)

  UNLESS str DO
  { writef("Need more store*n")
    RESULTIS 20
  }

  p, q := 0, 0

  FOR i = 1 TO data%0 DO push(data%i)
  len := q-p
  r, rlen, range := p, len, 0

  writef("count=%n*n*n", count)

  IF tostream DO selectoutput(tostream)

  pr(p, q)

  FOR i = 1 TO count DO
  { IF len<3 DO
    { writef("*nString length less than 3*n")
      pr(p, q)
      BREAK
    }

    step()
    IF trace DO pr(p, q)

    IF chkloop() DO
    { writef("*nRepeated string encountered*n")
      pr(p, q)
      BREAK
    }
  }

  IF tostream UNLESS stdout=tostream DO endwrite()
  selectoutput(stdout)
  freevec(str)
  RESULTIS 0
}

AND step() BE
{ LET ch = str%(p&mask)
  p := p+3
  TEST ch='0'
  THEN { push('0'); push('0'); len := len-1 }
  ELSE { push('1'); push('1') ; push('0'); push('1'); len := len+1 }
}

AND push(ch) BE
{ str%(q&mask) := ch
  q := q+1
}

AND chkloop() = VALOF
{ LET looplen = q-r
  IF looplen>=range DO
  { r, rlen := p, len
    range := range * 3 / 2 + 1
    writef("*nNew sample string at r=%n rlen=%n range=%n*n", r, rlen, range)
    pr(r, r+rlen)
    newline()
    RESULTIS FALSE
  }
 
  // Compare current string with the one at position r
  IF rlen=len DO
  { FOR i = 0 TO len-1 UNLESS str%(r+i & mask)=str%(p+i & mask) RESULTIS FALSE
    writef("*nStrings at %n and %n of length %n are equal*n", r, p, len)
    RESULTIS TRUE // Repeated string found
  }
  RESULTIS FALSE
}

AND pr(p, q) BE
{ writef("%i4: ", p)
  UNTIL p=q DO
  { wrch(str%(p&mask))
    p := p+1
  }
  newline()
}
