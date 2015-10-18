GET "libhdr"
GET "sdl.h"
GET "sdl.b"                 // Insert the library source code
.
GET "libhdr"
GET "sdl.h"


GLOBAL {
  done:ug
  rotleft
  rotright

  col_black
  col_blue
  col_green
  col_yellow
  col_red
  col_majenta
  col_cyan
  col_white
  col_darkgray
  col_darkblue
  col_darkgreen
  col_darkyellow
  col_darkred
  col_darkmajenta
  col_darkcyan
  col_gray
  col_lightgray
  col_lightblue
  col_lightgreen
  col_lightyellow
  col_lightred
  col_lightmajenta
  col_lightcyan
}

LET start() = VALOF
{ 
  initsdl()
  mkscreen("First SDL Demo", 600, 400)

  col_black       := maprgb(  0,   0,   0)
  col_blue        := maprgb(  0,   0, 255)
  col_green       := maprgb(  0, 255,   0)
  col_yellow      := maprgb(  0, 255, 255)
  col_red         := maprgb(255,   0,   0)
  col_majenta     := maprgb(255,   0, 255)
  col_cyan        := maprgb(255, 255,   0)
  col_white       := maprgb(255, 255, 255)
  col_darkgray    := maprgb( 64,  64,  64)
  col_darkblue    := maprgb(  0,   0,  64)
  col_darkgreen   := maprgb(  0,  64,   0)
  col_darkyellow  := maprgb(  0,  64,  64)
  col_darkred     := maprgb(128,   0,   0)
  col_darkmajenta := maprgb( 64,   0,  64)
  col_darkcyan    := maprgb( 64,  64,   0)
  col_gray        := maprgb(128, 128, 128)
  col_lightblue   := maprgb(128, 128, 255)
  col_lightgreen  := maprgb(128, 255, 128)
  col_lightyellow := maprgb(128, 255, 255)
  col_lightred    := maprgb(255, 128, 128)
  col_lightmajenta:= maprgb(255, 128, 255)
  col_lightcyan   := maprgb(255, 255, 128)

  fillsurf(col_gray)

  setcolour(col_cyan)
  plotf(250, 30, "First Demo")

  setcolour(col_red)               // Rails
  moveto( 100,  80)
  drawby( 400,   0)
  drawby(   0, -10)
  drawby(-400,   0)
  drawby(0,     10)

  setcolour(col_black)             // Wheels
  drawfillcircle(250, 100, 25)
  drawfillcircle(350, 100, 25)
  setcolour(col_green)
  drawfillcircle(250, 100, 20)
  drawfillcircle(350, 100, 20)

  setcolour(col_blue)              // Base
  drawfillrect(200, 110, 400, 130)

  setcolour(col_majenta)           // Boiler
  drawfillrect(225, 135, 330, 170)

  setcolour(col_darkred)           // Cab
  drawfillroundrect(340, 135, 400, 210, 15)
  setcolour(col_lightyellow)
  drawfillroundrect(350, 170, 380, 200, 10)

  setcolour(col_lightred)          // Funnel
  drawfillrect(235, 175, 255, 210)

  setcolour(col_white)             // Smoke
  drawfillcircle(265, 235, 15)
  drawfillcircle(295, 250, 12)
  drawfillcircle(325, 255, 10)
  drawfillcircle(355, 260,  7)

  updatescreen()   //Update the screen
  sdldelay(20_000) //Pause for 20 secs
  closesdl()       //Quit SDL

  RESULTIS 0
}
