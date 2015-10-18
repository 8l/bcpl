GET "libhdr"

STATIC { m1 = -1 }

LET start() = VALOF
{ LET x,y = 10, 11
  LET z = x+y
  LET a = BITSPERBCPLWORD
  LET b = B2Wsh
  LET c = 1 + BITSPERBCPLWORD/32
  writef("%n %n %n m1=%n*n", a, b, c, m1)
  RESULTIS b
}


