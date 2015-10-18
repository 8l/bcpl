/*
This is a simple implementation of the Miller Rabin test.

Implemented in BCPL by Martin Richards (c) November 2001

The program is a direct translation of the C program on pages 255-257
of "Number Theory A Progrmmer's Guide" by Mark Herkommer.
*/

GET "libhdr"

LET millerrabin(n, b) = VALOF
{ LET e, q, r, t = ?, ?, ?, 0

  IF (n&1)=0 RESULTIS TRUE   // n even - composite (except 2)

  b := b REM n
  UNLESS b DO                    // choose: 1 < b < n
    b := randno(n-2) + 1

  IF gcd(b, n) > 1 RESULTIS TRUE // lucky guess -- composite

  q := n-1
  WHILE (q & 1)=0 DO t, q := t+1, q>>1   // while q even

  r := PowMod(b, q, n)
  UNLESS r=1 FOR e = 0 TO t-2 DO
  { IF r = n-1 BREAK
    r := MulMod(r, r, n)
  }

  IF r=1 | r=n-1 RESULTIS FALSE   // Probably prime
  RESULTIS TRUE                   // composite
}

AND PowMod(a, n, m) = VALOF
{ LET r = 1
  WHILE n>0 DO
  { IF (n&1)>0 r := MulMod(r, a, m)
    a := MulMod(a, a, m)          // Square
    n := n>>1                     // Divide by 2
  }
  RESULTIS r
}

AND MulMod(a, b, m) = m=0 -> a*b, VALOF
{ LET r = 0
  WHILE a DO
  { IF (a&1)>0 DO r := (r+b) REM m
    a := a>>1
    b := (b<<1) REM m
  }
  RESULTIS r
}

AND gcd(a, b) = VALOF
{ WHILE b>0 DO
  { LET r = a REM b
    a := b
    b := r
  }
  RESULTIS a
}

LET start() = VALOF
{ LET argv = VEC 50
  LET n, b = 257, 43
  UNLESS rdargs("N,B", argv, 50) DO
  { writes("Bad args for milrabin*n")
    RESULTIS 20
  }
  IF argv!0 DO n := str2numb(argv!0)
  IF argv!1 DO b := str2numb(argv!1)

  writef("*nTest compositemenss using the miller-Rabin test ")
  writef("with n=%n and b=%n*n", n, b)

  writef("*n%n is %s*n", n,
          millerrabin(n, b) -> "composite", "probably prime")

  RESULTIS 0
}
