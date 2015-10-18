GET "libhdr"

LET fib(n) = n=0 -> 0,
             n=1 -> 1,
             fib(n-1) + fib(n-2)

LET start() = VALOF
{ FOR i = 0 TO 50 DO
    writef("Position %2i  Value %12u*n", i, fib(i))

  RESULTIS 0
}
