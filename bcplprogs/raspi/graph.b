GET "libhdr"
GET "sdl.h"
GET "sdl.b"
.
GET "libhdr"
GET "sdl.h"

GLOBAL {
  col_red: ug
  col_green
  col_blue
  col_lightgray
  col_black
}

LET start() = VALOF
{ initsdl()
  mkscreen("Three curves", 500, 500)

  col_red         := maprgb(255,   0,   0)
  col_green       := maprgb(  0, 255,   0)
  col_blue        := maprgb(  0,   0, 255)
  col_lightgray   := maprgb(180, 180, 180)
  col_black       := maprgb(  0,   0,   0)

  fillsurf(col_lightgray)

  // We will use scales numbers with three digits after the
  // decimal point and the $x$ and $y$ ranges will both be
  // between -3.000 and +3.000

  // Draw the axes
  setcolour(col_black)
  FOR x = -3_000 TO 3_000 BY 1_000 DO
  { cmoveto(x, -3_000)
    cdrawto(x,  3_000)
  }
  FOR y = -3_000 TO 3_000 BY 1_000 DO
  { cmoveto(-3_000, y)
    cdrawto( 3_000, y)
  }

  plotfn(f1, -3_000, 3_000, col_red)
  plotfn(f2, -3_000, 3_000, col_green)
  plotfn(f3, -3_000, 3_000, col_blue)

  updatescreen()
  sdldelay(20_000)
  closesdl()
  RESULTIS 0
}

AND plotfn(f, x1, x2, col) BE
{ setcolour(col)
  cmoveto(x1, f(x1))
  FOR i = 1 TO 100 DO
  { LET x = (x1*(100-i) + x2*i)/100
    cdrawto(x, f(x))
  }
}

AND f1(x) = x*x/3_000

AND f2(x) = f1(x)*x/3_000 - x

AND f3(x) = f1(x) - f2(x)

AND cmoveto(x,y) BE
{ // Convert to screen coordinates
  LET sx = screenxsize/2 + x/15
  LET sy = screenysize/2 + y/15
  moveto(sx, sy)
}

AND cdrawto(x,y) BE
{ // Convert to screen coordinates
  LET sx = screenxsize/2 + x/15
  LET sy = screenysize/2 + y/15
  drawto(sx, sy)
}
