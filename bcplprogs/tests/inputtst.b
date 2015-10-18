GET "libhdr"

LET start() = VALOF
{
  sawritef("*nType some characters terminated by '.'*n")

  { LET ch = rdch()
    IF ch=endstreamch | ch='.' BREAK
    sawritef("ch=%i3 '%c'*n", ch, ch)
  } REPEAT

  sawritef("*nEnd of test*n")
  RESULTIS 0
}
