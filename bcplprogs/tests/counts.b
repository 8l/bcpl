GET "libhdr"

GLOBAL { nullfn:200; f }

LET nullfn(x) = 2*x+1

LET f(n) = n=0 -> 1, n*f(n-1)

LET start() = VALOF
{ writef("%i7*n", instrcount(nullfn, 23))
  FOR i = 1 TO 8 DO writef("%i7*n", instrcount(f, i))
  RESULTIS 0
}

