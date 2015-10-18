GET "libhdr"

MANIFEST {
modulus = #x10000001 // modulus is 2**28 + 1
}

LET dv(a, m, b, n) = a=1 -> m,
                     a=0 -> m-n,
                     a<b -> dv(a, m, b REM a, add(mul(m,b/a),n)),
                     dv(a REM b, add(m,mul(n,a/b)), b, n)


AND inv(x) = dv(x, 1, modulus-x, 1)

AND add(x, y) = VALOF
{ LET a = x+y
  IF 0<=a<modulus RESULTIS a
  RESULTIS a-modulus
}

AND sub(x, y) = add(x, neg(y))

AND neg(x)    = x=0 ->0, modulus-x

AND mul(x, y) = x=0 -> 0,
                (x&1)=0 -> mul(x>>1, add(y,y)),
                add(y, mul(x>>1, add(y,y)))

AND ovr(x, y) = mul(x, inv(y))

LET start() = VALOF
{ LET a, b = 0, 0

  { writes("*nGive number to square root: ")
    a := rdbn()
    writes("*nGive initial guess: ")
    b := rdbn()
    UNLESS 0<a<modulus & 0<b<modulus BREAK
  
    writes("*nNumber to square root:                  ")
    wrbn(a)
    newline()
    newline()

    FOR i = 1 TO 32 DO
    { writef("%i2:  ", i)
      wrbn(b)
      writes("   ")
      wrbn(mul(b,b))
      newline()
      IF a = mul(b,b) DO
      { writes("This is a solution*n")
        BREAK
      }
      b := ovr(sub(b,ovr(a,b)), 2)

    }
  } REPEAT

  writes("*nEnd of test*n")
  RESULTIS 0
}

AND wrbn(b) BE FOR j = 31 TO 0 BY -1 TEST (b>>j & 1) = 0 
                                     THEN wrch('.')
                                     ELSE wrch('1')



AND rdbn() = VALOF
{ LET a, ch = 0, rdch()

  UNTIL ch='0' | ch='1' | ch=endstreamch DO ch := rdch()

  WHILE ch='0' | ch='1' DO
  { a := a<<1
    IF ch='1' DO a := a + 1
    ch := rdch()
  }

  wrbn(a); newline()
  RESULTIS a
}







