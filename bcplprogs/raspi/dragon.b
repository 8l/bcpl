GET "libhdr"
GET "sdl.h"
GET "sdl.b"
.
GET "libhdr"
GET "sdl.h"

GLOBAL {
  col_blue: ug
  col_white
  col_lightcyan
}

LET start() = VALOF
{ initsdl()
  mkscreen("Dragon Curve", 600, 600)

  col_blue        := maprgb(  0,   0, 255)
  col_white       := maprgb(255, 255, 255)
  col_lightcyan   := maprgb(255, 255, 100)

  fillsurf(col_blue)

  setcolour(col_lightcyan)
  plotf(240, 50, "The Dragon Curve")

  setcolour(col_white)
  moveto(260, 200)
  dragon(1024, 6)

  updatescreen()
  sdldelay(20_000)
  closesdl()
  RESULTIS 0
}

AND gray(n) = n XOR n>>1

AND bits(w) = w=0 -> 0, 1 + bits(w & w-1)

AND dragon(n, size) BE FOR i = 0 TO n-1 DO
{ LET dir = bits(gray(i))
  SWITCHON dir & 3 INTO
  { CASE 0: drawby( size,   0); ENDCASE  // Right
    CASE 1: drawby(  0,  size); ENDCASE  // Up
    CASE 2: drawby(-size,   0); ENDCASE  // Left
    CASE 3: drawby(  0, -size); ENDCASE  // Down
  }
  updatescreen() // Show the curve as it is drawn
  sdldelay(20)
}
