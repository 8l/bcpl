GET "libhdr"

LET start() = VALOF
{ LET timeout = 2500 // msecs
  LET filename = "xxx"
  LET rc = 0
  LET v = getvec(5)
  LET days, msecs = 0, 0
  LET dstrings = VEC 14
  LET argv = VEC 50

  // Test getvec and freevec
  { LET v = getvec(5)
    FOR i = 0 TO 7 DO v!i := #xBBBB0000+i
    FOR i = -1 TO 16 DO writef("%2i: %8x*n", i, v!i)
    freevec(v)
  }

  UNLESS rdargs("FILE/A", argv, 50) DO
  { writef("Bad args for T1*n")
    RESULTIS 0
  }
  IF argv!0 DO filename := argv!0

  //FOR ch = 'A' TO 'Z' DO
  //{ sendpkt(-1, -3, 0, 0, 0, ch/0)
  //  sendpkt(-1, -3, 0, 0, 0, '*n')
  //}
  //sawritef("t1: calling sys(Sys_delay, %n)*n", timeout)
  //sys(Sys_delay, timeout)
  //sawritef("t1: returned from sys(Sys_delay, %n)*n", timeout)

  rc := sys(Sys_filemodtime, filename, @days);
  writef("t1: file %s rc=%n days=%n msecs=%n*n", filename, rc, days, msecs)
  
  dat_to_strings(@days, dstrings)
  writef("t1: file %s %s %s*n", filename, dstrings, dstrings+5)

  RESULTIS 0
}
