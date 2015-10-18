GET "libhdr"

LET start() = VALOF
{ writef("Unicode Character Set*n*n")

  FOR code = 0 TO #x3FFF DO
  { IF code MOD 16 = 0 DO writef( "*n%x4: ", code)
    writef(" %#", code)
  }
  newline()
  RESULTIS 0
}
