GET "libhdr"

LET start() = VALOF
{ LET x, y, z = 5, 36, 1004
  LET p = @x
  p!2 := p!0 + p!1  // Equivalent to z := x + y
  writef("x=%n y=%n z=%n*n", x, y, z)
  RESULTIS 0
}
