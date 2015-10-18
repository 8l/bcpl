GET "libhdr"

GLOBAL {
  cov: ug
  av
}

MANIFEST {
  upb = 3
}

LET pokefn(k) BE
{ cowait() // Wait to be poked

  { av!k := 1 - av!k
    cowait(TRUE)
    cowait(k>1 -> callco(cov!(k-1)), FALSE)
  } REPEAT
}

LET start() = VALOF
{ LET v1 = VEC upb
  LET v2 = VEC upb
  cov, av := v1, v2
  FOR i = 1 TO upb DO cov!i, av!i := 0, 0

  FOR i = 1 TO upb DO
  { LET co = createco(pokefn, 200)
    callco(co, i)
    cov!i := co
  }
  writef("%n coroutines created*n", upb)
 
  FOR i = 1 TO 20 DO
  { FOR i = 1 TO upb DO writef("%n", av!i)
    newline()
    callco(cov!upb)
  }

fin:
  FOR i = 1 TO upb IF cov!i DO deleteco(cov!i)
  writef("End of test*n")
  RESULTIS 0
}
