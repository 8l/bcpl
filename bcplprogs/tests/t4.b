GET "libhdr"

MANIFEST {
 a = SLCT 1
 b = SLCT 8:1
 c = SLCT 8:13:1
}

LET start() = VALOF
{ LET v = VEC 4
  LET x, y, z = 111, 222, 333
//writef("t4 starting*n")
  //sys(Sys_tracing, TRUE)
  x := 1234

  v!0 := #xA1B2C3D4
  v!1 := #b01100011_00101000_11111111_10110111
  x := a OF v
  y := b :: v
  z := c OF v
  //sys(Sys_tracing, FALSE)

  newline()
  writef("          %bW*n", v!1)
  writef("%x8: %bW*n", a, x)
  writef("%x8: %bW*n", b, y)
  writef("%x8: %bW*n", c, z)
/*
  a OF v := 10
  b::v := 11
  c::v := 12
  writef("          %bW*n", v!1)

  a OF v +:= 13
  b::v -:= 14
  c::v XOR:= 15
  writef("          %bW*n", v!1)

  a OF v #+:= 16
  b::v +:= 17
  c::v +:= 18
  writef("          %bW*n", v!1)

*/
  RESULTIS 0
}
