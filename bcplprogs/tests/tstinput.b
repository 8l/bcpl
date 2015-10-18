GET "libhdr"

LET start() = VALOF
{ writef("Read characters from so called standard input*n")

  FOR i = 1 TO 50 DO
  { LET ch = rdch()
    TEST ch=endstreamch
    THEN { writef("ch=endstreamch*n")
           BREAK
         }
    ELSE writef("ch= %i3 '%c'*n", ch, ch)
    IF ch='.' | ch=endstreamch BREAK
  }

  writef("*nEnd of test*n")
}
