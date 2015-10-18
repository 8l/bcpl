GET "libhdr"

LET f(x) = x+1

LET start() = VALOF
{ LET count = instrcount(f, 1234)
  writef("count = %n*n", count)
  RESULTIS 0
}
