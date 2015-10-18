GET "libhdr"
GET "sdl.h"
GET "sdl.b"
.
GET "libhdr"
GET "sdl.h"

MANIFEST {
  nlim = 10000
  clim =   250
}

GLOBAL {
  col_red: ug
  col_green
  col_blue
  col_lightgray
  col_black
}

LET start() = VALOF
{ initsdl()
  mkscreen("Collatz Diagram", 700, 500)

  col_red         := maprgb(180,   0,   0)
  col_green       := maprgb(  0, 255,   0)
  col_blue        := maprgb(  0,   0, 255)
  col_lightgray   := maprgb(180, 180, 180)
  col_black       := maprgb(  0,   0,   0)

  fillsurf(col_lightgray)

  // Draw the axes
  setcolour(col_black)

  cmoveto(   0,     0)
  cdrawto(nlim,     0)
  cdrawto(nlim,  clim)
  cdrawto(   0,  clim)
  cdrawto(   0,     0)

  FOR x = 1 TO nlim DO
  { LET y = try(x)
    TEST y>=0
    THEN setcolour(col_red)
    ELSE { setcolour(col_blue)
           y := -y
         }
    cdrawpoint(x, y)
  updatescreen()
  }

  updatescreen()
  sdldelay(20_000)
  closesdl()
  RESULTIS 0
}

AND cdrawpoint(x,y) BE
{ // Convert to screen coordinates
  LET sx = 10 + muldiv(screenxsize-20, x, nlim)
  LET sy = 10 + muldiv(screenysize-20, y, clim)
  drawfillcircle(sx, sy, 1)
}

AND cmoveto(x,y) BE
{ // Convert to screen coordinates
  LET sx = 10 + muldiv(screenxsize-20, x, nlim)
  LET sy = 10 + muldiv(screenysize-20, y, clim)
  moveto(sx, sy)
}

AND cdrawto(x,y) BE
{ // Convert to screen coordinates
  LET sx = 10 + muldiv(screenxsize-20, x, nlim)
  LET sy = 10 + muldiv(screenysize-20, y, clim)
  drawto(sx, sy)
}

AND try(n) = VALOF
{ LET count = 0
  LET lim = (maxint-1)/3

  { count := count+1
    //writef("%5i: %10i*n", count, n)
    IF n=1 RESULTIS count
    TEST n MOD 2 = 0
    THEN { n := n/2
         }
    ELSE { IF n > lim RESULTIS -count
           n := 3*n+1
         }
  } REPEAT
}
