GLOBAL { f:234 }

LET f(n) = n+1

.

GET "libhdr"

GLOBAL { f:234 }

LET start() = VALOF
{ LET n = 100
  writef("f(%n) = %n*n", n, f(n))
  RESULTIS 0
}

.

