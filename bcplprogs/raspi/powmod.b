GET "libhdr"

LET add(x, y, m) = VALOF
{ LET a = x+y

  IF x<0 & y<0 & a>0 RESULTIS a-m

  IF a-m<0 RESULTIS a // Unsigned comparison
  RESULTIS a-m
}

AND mul(x, y, m) = y=0 -> 0,
                   (y&1)=0 -> mul(add(x,x,m), y>>1, m),
                   add(x,     mul(add(x,x,m), y>>1, m), m)

AND pow(x, y, m) = y=0 -> 1,
                   (y&1)=0 -> pow(mul(x,x,m), y>>1, m),
                   mul(x,     pow(mul(x,x,m), y>>1, m), m)

LET start() = VALOF
{ LET a, n, m = 7, 25, 19
  writef("%n****%n modulo %n = %n*n", a, n, m, pow(a, n, m))

  a, n, m := #x0ABCDEF0, 10000691, 1576280161 // Should give #x5AF3EBFE
  writef("%8x****%n modulo %n = %8x*n", a, n, m, pow(a, n, m))
  RESULTIS 0
}
