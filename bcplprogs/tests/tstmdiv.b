GET "libhdr"

GLOBAL { errors:ug; verbose }

LET start() = VALOF
{ LET a, b, c, count = 0, 0, 0, 0
  LET argv = VEC 50

  UNLESS rdargs("COUNT,V/S", argv, 50) DO
  { writef("Bad arguments for TSTMDIV*n")
    RESULTIS 20
  }

  errors := 0

  UNLESS argv!0 DO
  { { writes("*nType three numbers for muldiv:  ")
      a := readn()
      b := readn()
      c := readn()
      IF c=0 BREAK
      writef("    muldiv(%n, %n, %n) gives %n  ", a, b, c, muldiv(a, b, c))
      writef("remainder %n*n", result2)
      writef("old muldiv(%n, %n, %n) gives %n  ", a, b, c, sys(26, a, b, c))
      writef("remainder %n*n", result2)
    } REPEAT

    writef("*nEnd of test*n")
    RESULTIS 0
  }

  count := str2numb(argv!0)
  verbose := argv!1

  FOR i = 0 TO count DO
  { LET rana = randno(1000000000) 
    LET ranb = randno(1000000000)
    LET ranc = randno(1000000000)

    IF verbose DO writef("*ntest %n/%n*n", i, count)

    try(maxint+i, maxint+i, maxint+i)
    try(maxint+i, maxint+i, maxint-i)
    try(maxint+i, maxint-i, maxint+i)
    try(maxint+i, maxint-i, maxint-i)
    try(maxint-i, maxint+i, maxint+i)
    try(maxint-i, maxint+i, maxint-i)
    try(maxint-i, maxint-i, maxint+i)
    try(maxint-i, maxint-i, maxint-i)

    try( rana,  ranb,  ranc)
    try( rana,  ranb, -ranc)
    try( rana, -ranb,  ranc)
    try( rana, -ranb, -ranc)
    try(-rana,  ranb,  ranc)
    try(-rana,  ranb, -ranc)
    try(-rana, -ranb,  ranc)
    try(-rana, -ranb, -ranc)

    try( maxint+i,  ranb,  ranc)
    try( maxint+i,  ranb, -ranc)
    try( maxint+i, -ranb,  ranc)
    try( maxint+i, -ranb, -ranc)
    try(-maxint+i,  ranb,  ranc)
    try(-maxint+i,  ranb, -ranc)
    try(-maxint+i, -ranb,  ranc)
    try(-maxint+i, -ranb, -ranc)

    try( maxint-i,  ranb,  ranc)
    try( maxint-i,  ranb, -ranc)
    try( maxint-i, -ranb,  ranc)
    try( maxint-i, -ranb, -ranc)
    try(-maxint-i,  ranb,  ranc)
    try(-maxint-i,  ranb, -ranc)
    try(-maxint-i, -ranb,  ranc)
    try(-maxint-i, -ranb, -ranc)
  }

  TEST errors
  THEN writef("There were %n errors*n", errors)
  ELSE writef("There were no errors*n")
  RESULTIS 0
}

AND try(a, b, c) BE
{ try1(a,b,c)
  try1(a,c,b)
  try1(b,a,c)
  try1(b,c,a)
  try1(c,a,b)
  try1(c,b,a)
}

AND try1(a, b, c) BE
{ LET q1, r1, q2, r2 = 0, 0, 0, 0
  IF c=0 RETURN
  IF verbose DO writef("%x8 ** %x8 / %x8", a, b, c)    
  q1 := muldiv(a, b, c)
  r1 := result2
  IF verbose DO writef(" => %x8 remainder %x8*n", q1, r1)
  q2 := sys(26, a, b, c)
  r2 := result2

  IF q1~=q2 | r1~=r2 DO
  { writef("    muldiv(%x8, %x8, %x8) => %x8  ", a, b, c, q1)
    writef("remainder %x8*n", r1)
    writef("old muldiv(%x8, %x8, %x8) => %x8  ", a, b, c, q2)
    writef("remainder %x8*n", r2)
    errors := errors+1
  }
}
