GET "libhdr"

MANIFEST {
 a = SLCT 1
 b = SLCT 8:1
 c = SLCT 8:13:1
}

LET start() = VALOF
{ LET v = VEC 10
  LET x, y, z = 0, 0, 0
  LET opts = "abc"
  FOR i = 0 TO 10 DO v!i := 0
  FOR i = 0 TO opts%0 DO v!i := 0
  v!1 := #b11100011_00101000_11111111_10110111
  x := a OF v
  y := b :: v
  z := c OF v

  writef("          %bW*n", v!1)
  writef("%x8: %bW*n", a, x)
  writef("%x8: %bW*n", b, y)
  writef("%x8: %bW*n", c, z)

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



  RESULTIS 0
}
