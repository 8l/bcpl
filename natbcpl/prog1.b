SECTION "prog"

GET "libhdr"

LET start() = VALOF
{ LET argv = VEC 50
  writef("*nprog entered*n")

  writef("prog: args: %s*n", sys(137))

  UNLESS rdargs("X,Y", argv, 50) DO
  { writef("Bad arguments for prog*n")
    RESULTIS 20
  }
  IF argv!0 DO writef("X = %s*n", argv!0)
  IF argv!1 DO writef("Y = %s*n", argv!1)
RESULTIS 0

  writef("*nReading from standard input*n")
  { LET ch = rdch()
    IF ch=endstreamch BREAK
    writef("ch = %i3 '%c'*n", ch, ch)
  } REPEAT
  writef("*nEOF read*n")

  FOR i = 0 TO 10 DO writef("i = %i2*n", i)
  //stop(0)
  RESULTIS 0
}

