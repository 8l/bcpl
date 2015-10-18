SECTION "ECHO"

GET "libhdr"

LET start() = VALOF
{ LET argv = VEC 80

  IF rdargs("TEXT,N/S", argv, 80)=0 DO
  { writes("Bad argument for ECHO*n")
    RESULTIS 20
  }

  UNLESS argv!0=0 DO writes(argv!0)

  UNLESS argv!1 DO newline()

  RESULTIS 0
}
