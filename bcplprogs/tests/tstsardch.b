GET "libhdr"

GLOBAL { nullfn:200; f }

LET start() = VALOF
{ LET v = VEC 10
  LET n = 0
  writef("*nType 10 characters, or terminate with a dot(.)*n*n")

  { LET ch = sardch()
    n := n+1
    v!n := ch
    IF ch='.' BREAK
  } REPEATUNTIL n>=10

  writef("*n*n%n characters were received as follows:*n*n", n)
  FOR i = 1 TO n DO writef("%i2: %i3  <%c>*n", i, v!i, v!i)

  RESULTIS 0
}
