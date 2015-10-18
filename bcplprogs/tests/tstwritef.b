SECTION "tstwritef"

GET "libhdr"

GLOBAL { g:ug }

MANIFEST { }

STATIC {}

GLOBAL {}

LET start() = VALOF
{ //LET a = ""
  //LET b = "A"
  //LET c = "AB"
  //LET d = "ABC"
  //LET e = "ABCD"
  //LET f = "ABCDE"
  //LET g = "ABCDEF"
  //LET h = "ABCDEFG"
  //LET i = "ABCDEFGH"
  //LET j = "ABCDEFGHI"
  LET plat = sys(Sys_platform)
  writef("Platform number = %n*n", plat)

  writef("Test new writef formats*n")

  writef("%10i*n", 1234)
  writef("%iA*n", 1234)
  writef("%10.2d*n", 1234)
  writef("%10.2d*n", -1234)
  writef("%10.0d*n", 1234)
  writef("%10.0d*n", -1234)

  FOR d = 100 TO 500 BY 25 DO // Scaled decimal with 2 digit after
                              // the decimal point
  { writef("Delay for %4.2d seconds*n", d)
    sys(Sys_delay, (tickspersecond*d)/100)
  }

  RESULTIS 0
}

