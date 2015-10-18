GET "libhdr"

MANIFEST {
 a = SLCT 1
 b = SLCT 8:1
 c = SLCT 8:13:1
}

LET start() = VALOF
{ LET v = VEC 4
  FOR a = -5 TO 5 FOR b = -5 TO 5 DO
  //LET a, b = -5, -5
  { v!0, v!1 := 0, 0
    //abort(1000)
    { v%5 := a; v%5 |:= b; v%6 := v%5 | b
        UNLESS v%5=v%6 DO
          writef("a=%i2 b=%i2 v%%5=%i3 v%%6=%i3*n", a, b, v%5, v%6)
    }
  }
  RESULTIS 0
}
