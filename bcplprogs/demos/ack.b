GET "libhdr"

LET f(x) = x

LET ack(x, y) = x=0 -> y+1,
                y=0 -> ack(x-1, 1),
                ack(x-1, ack(x, y-1))

LET start() = VALOF
{ writef("Ackermann's function*n*n")

  FOR i = 0 TO 5 DO
  { writef("a(%n, **): ", i)
    FOR j = 0 TO 6 DO
      writef(" %i8*n", ack(i, j))
    newline()
  }
  RESULTIS 0
}
