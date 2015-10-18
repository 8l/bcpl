SECTION "prog"

GET "libhdr"

LET start() = VALOF {
  LET argv = VEC 50
  LET buf  = VEC 50
  LET len  = 0

  UNLESS rdargs("x,y/K,sw/S", argv, 50) DO
  { writes("Bad arguments for PROG*n")
    RESULTIS 20
  }
  writes("The arguments were:*n*n")

  writef("arg1: keyword x:    %s*n", argv!0 -> argv!0, "<not given>")
  writef("arg1: keyword y/K:  %s*n", argv!1 -> argv!1, "<not given>")
  writef("arg1: keyword sw/S: %s*n", argv!2 -> "TRUE", "FALSE")

  writes("*nType a line of input: ")
  deplete(cos)

  { LET ch = rdch()
    IF ch='*n' | ch=endstreamch BREAK
    len := len+1
    buf%len := ch
  } REPEAT

  buf%0 := len

  writef("You typed: %s*n*n", buf)
  RESULTIS 0
}
