SECTION "ECHO"

GET "libhdr"

LET start() = VALOF
{ LET tostream = 0
  LET toname = 0
  LET appending = ?
  LET nonewline = ?
  LET text = 0
  LET argv = VEC 80

  IF rdargs("TEXT,TO/K,APPEND/S,N/S", argv, 80)=0 DO
  { writes("Bad argument for ECHO*n")
    RESULTIS 20
  }

  IF argv!0 DO text := argv!0    // TEXT
  IF argv!1 DO toname := argv!1  // TO/K
  appending := argv!2            // APPEND/S
  nonewline := argv!3            // N/S

  IF toname DO
  { TEST appending
    THEN tostream := findappend(toname)
    ELSE tostream := findoutput(toname)
    UNLESS tostream DO
    { writef("Unable to open file: %s*n", toname)
      result2 := 100
      RESULTIS 20
    }
    selectoutput(tostream)
  }

  IF text DO writes(text)
  UNLESS nonewline DO newline()

  IF tostream DO endstream(tostream)
  RESULTIS 0
}
