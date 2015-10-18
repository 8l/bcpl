GET "libhdr"

LET start() = VALOF
{ wrch := sawrch // Temporary fudge until wrch works
  FOR i = 1 TO 5 DO writef("fact(%n) = %i4*n", i, fact(i))
  RESULTIS 0
}

AND fact(n) = n=0 -> 1, n*fact(n-1)
