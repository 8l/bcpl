GET "libhdr"

LET start() = VALOF
{ LET argv = VEC 10
  LET rc = 0

  UNLESS rdargs("RETCODE/N", argv, 10) DO
  { writef("Bad arguments for rctest*n")
    RESULTIS 0
  }
  IF argv!0 DO rc := !(argv!0)
  writef("start: returning value %n*n", rc)
  RESULTIS rc
}
