GET "libhdr"

LET start() = VALOF
{ LET x, y = 11, 12
  x := x + 9*y 
  x := 1234


  FOR i = 5 TO 10 DO
    writef("f(%i2) = %i6*n", i, f(i))
  RESULTIS 0
}

AND f(n) = n=0 -> 0, n + f(n-1)
