GET "libhdr"

GLOBAL {
  cov: ug
  av
}

MANIFEST {
  upb = 3
}

LET bumpfn(k) BE
{ cowait() // Wait to be bumped

  { IF k<upb WHILE callco(cov!(k+1)) DO cowait(TRUE)
    av!k := 1
    cowait(TRUE)
    cowait(FALSE) // av!k=..=a!upb=1
    av!k := 0
    cowait(TRUE)
    IF k<upb WHILE callco(cov!(k+1)) DO cowait(TRUE)
    cowait(FALSE) // av!k=..=a!upb=0
  } REPEAT
}

LET start() = VALOF
{ LET v1 = VEC upb
  LET v2 = VEC upb
  cov, av := v1, v2
  FOR i = 1 TO upb DO cov!i, av!i := 0, 0

  FOR i = 1 TO upb DO
  { LET co = createco(bumpfn, 200)
    callco(co, i)
    cov!i := co
  }
  writef("%n coroutines created*n", upb)
 
  FOR i = 1 TO 20 DO
  { FOR i = 1 TO upb DO writef("%n", av!i)
    newline()
    callco(cov!1)
  }

fin:
  FOR i = 1 TO upb IF cov!i DO deleteco(cov!i)
  writef("End of test*n")
  RESULTIS 0
}
