GET "libhdr"

GLOBAL {
  cov: ug
  av
  sete
}

MANIFEST {
  upb = 6
}

LET mem(x, set) = VALOF
{ FOR i = 1 TO set!0 IF x=set!i RESULTIS TRUE
  RESULTIS FALSE
}

LET ebumpfn(k) BE
{ LET m = upb/2
  LET k1 = VALOF
  { IF k>1 FOR i = 2 TO sete!0 IF k=sete!i RESULTIS sete!(i-1)
    RESULTIS 0
  }
  writef("k=%n k1=%n*n", k, k1)
  cowait() // Wait to be ebumped

  { UNLESS k=upb | mem(k+1, sete) WHILE callco(cov!(k+1)) DO cowait(TRUE)
    av!k := 1
    cowait(TRUE)
    cowait(k1 -> callco(cov!k1), FALSE)
    av!k := 0
    cowait(TRUE)
    UNLESS k=upb | mem(k+1, sete) WHILE callco(cov!(k+1)) DO cowait(TRUE)
    cowait(k1 -> callco(cov!k1), FALSE)
  } REPEAT
}

LET start() = VALOF
{ LET v1 = VEC upb
  LET v2 = VEC upb
  cov, av := v1, v2
  sete := TABLE 3, 1, 3, 4 // Corresponding to {1, 3, 4}
                           // ie a1<=a2 and a4<=a5<=a6

  FOR i = 1 TO upb DO cov!i, av!i := 0, 0

  FOR i = 1 TO upb DO
  { LET co = createco(ebumpfn, 200)
    callco(co, i)
    cov!i := co
  }
  writef("%n coroutines created*n", upb)
 
  FOR i = 1 TO 48 DO
  { FOR i = 1 TO upb DO writef("%n", av!i)
    TEST i REM 8 = 0 THEN newline() ELSE wrch(' ')
    callco(cov!(sete!(sete!0)))
  }

fin:
  FOR i = 1 TO upb IF cov!i DO deleteco(cov!i)
  writef("End of test*n")
  RESULTIS 0
}
