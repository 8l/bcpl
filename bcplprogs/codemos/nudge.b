GET "libhdr"

GLOBAL {
  cov: ug
  av
}

MANIFEST {
  upb = 4
}

LET mem(x, set) = VALOF
{ FOR i = 1 TO set!0 IF x=set!i RESULTIS TRUE
  RESULTIS FALSE
}

LET nudgefn(k) BE
{ LET m = upb/2
  LET k1, k2 = k+1, k+2
  IF (k&1)=0 DO k1, k2 := k+2, k+1

  writef("k=%n k1=%n*n", k, k1)
  cowait() // Wait to be nudged

  IF av!k=1 GOTO awake1

  { 
awake0:
    IF k1<=upb WHILE callco(cov!k1) DO cowait(TRUE)
    av!k := 1
    cowait(TRUE)
    IF k2<=upb WHILE callco(cov!k2) DO cowait(TRUE)
    cowait(FALSE)

awake1:
    IF k2<=upb WHILE callco(cov!k2) DO cowait(TRUE)
    av!k := 0
    cowait(TRUE)
    IF k1<=upb WHILE callco(cov!k1) DO cowait(TRUE)
    cowait(FALSE)
  } REPEAT
}

LET start() = VALOF
{ LET v1 = VEC upb
  LET v2 = VEC upb
  cov, av := v1, v2

  FOR i = 1 TO upb DO cov!i, av!i := 0, (i-1)/3 & 1

  FOR i = 1 TO upb DO
  { LET co = createco(nudgefn, 200)
    callco(co, i)
    cov!i := co
  }
  writef("%n coroutines created*n", upb)
 
  FOR i = 1 TO 16 DO
  { FOR i = 1 TO upb DO writef("%n", av!i)
    newline()
    callco(cov!1)
  }

fin:
  FOR i = 1 TO upb IF cov!i DO deleteco(cov!i)
  writef("End of test*n")
  RESULTIS 0
}
