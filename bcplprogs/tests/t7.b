GET "libhdr"

MANIFEST {
 S1 = SLCT 1
 S81 = SLCT 8:1
 S8131 = SLCT 8:13:1
}

LET start() = VALOF
{ LET v = VEC 4
  LET a, b = -5, -5
  { v!0, v!1 := 0, 0
    S1::v := S1::v + 1
    S1::v +:= 1
    S8131::v := 15
    a := FABS b
  }
  RESULTIS 0
}
