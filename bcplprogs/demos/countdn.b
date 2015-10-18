/*
This program finds the set of numbers that can be computed from a
given set of up to 6 numbers using only the operations plus, minus,
times and divide. Each number can only be used once and all numbers
and intermediate results must be integral and in the range 0 to 999.

Written in BCPL by Martin Richards (c) February 2000
*/

GET "libhdr"

GLOBAL   { v:200; resv; opstr; vala; valb; change; outstream }

MANIFEST { Upb=999 }

LET start() = VALOF
{ LET argv = VEC 50
  LET oldout = output()

  UNLESS rdargs(",,,,,,TO/K", argv, 50) DO
  { writes("Bad arguments for COUNTDN*n")
    RESULTIS 20
  }

  v, resv := getvec(63), getvec(Upb)
  UNLESS v & resv DO
  { writes("Insufficient space*n")
    GOTO fin
  }

  FOR i = 0 TO 63 DO v!i := 0 
  FOR i = 0 TO Upb DO resv!i := 0

  FOR i = 0 TO 63 DO 
  { LET p = getvec(Upb)
    UNLESS p DO
    { writes("Insufficient space*n")
      GOTO fin
    }
    FOR j = 0 TO Upb DO p!j := 0
    v!i := p
  }

  outstream := 0
  IF argv!6 DO outstream := findoutput(argv!6)
  IF outstream DO selectoutput(outstream)

  FOR i = 0 TO 5 IF argv!i DO
  { LET k = str2numb(argv!i)
    UNLESS 0<=k<=Upb DO
    { writef("Bad number %n given*n", k)
      GOTO fin
    }
    opstr, vala, valb := "num", k, 0
    setbit(1<<i, k)
  }

  writef("*nThe given numbers are:*n*n")
  pr()

  writef("*nDoing closure*n")
  doclosure()

  writes("The following numbers can be computed:*n*n")
  pr()

fin:
  IF outstream & outstream ~= oldout DO endwrite()
  selectoutput(oldout)
 
  FOR i = 0 TO 63 IF v!i DO freevec(v!i)
  IF resv DO freevec(resv)
  IF v    DO freevec(v)
  RESULTIS 0
}

AND doclosure() BE
{ change := FALSE
  FOR i = 0 TO 63 FOR j = i+1 TO 63 IF (i&j)=0 DO
  { LET p, q = v!i, v!j
    FOR a = 0 TO Upb IF p!(a>>5) & getbit(i, a) DO
      FOR b = 0 TO Upb IF q!(b>>5) & getbit(j, b) DO
      { LET bits, k = i+j, 0
        vala, valb, opstr := a, b, "add"
        k := a+b
        IF k<=Upb DO setbit(bits, k)
        k := a-b
        opstr := "sub"
        IF k<0 DO vala, valb, k := b, a, -k
        IF k<=Upb DO setbit(bits, k)
        k := a*b
        opstr := "mul"
        IF k<=Upb DO setbit(bits, k)
        IF b & a REM b = 0 DO
        { k := a/b
          vala, valb, opstr := a, b, "div"
          IF k<=Upb DO setbit(bits, k)
        }
        IF a & b REM a = 0 DO
        { k := b/a
          vala, valb, opstr := b, a, "div"
          IF k<=Upb DO setbit(bits, k)
        }
      }
  } 
} REPEATWHILE change

AND pr() BE
{ LET k = 0
  FOR n = 0 TO Upb DO
  { LET inset = VALOF
    { FOR i = 0 TO 63 IF getbit(i, n) RESULTIS TRUE
      RESULTIS FALSE
    }
    UNLESS inset LOOP
    writef(" %i4", n)
    k := k+1
    UNLESS k REM 10 DO newline()
  }
  newline()
}

AND setbit(bits, n) BE
{ LET p, i = n/32, n REM 32
  LET bitv = v!bits
  LET old = bitv!p
  LET new = old | 1<<i
  IF new=old RETURN
  bitv!p, change := new, TRUE
  UNLESS resv!n DO
    writef("adding %i4 to set %b6   %s %n %n*n",
               n, bits, opstr, vala, valb)
    
  resv!n := TRUE
}

AND getbit(bits, n) = VALOF
{ LET p, i = n/32, n REM 32
  LET bitv = v!bits
  RESULTIS ((bitv!p>>i)&1)
}

