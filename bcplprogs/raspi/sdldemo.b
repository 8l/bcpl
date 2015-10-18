/*
This is a simple demo of the BCPL interface to the SDL Graphics library.

Implemented by Martin Richards (c) July 2012
*/

GET "libhdr"
GET "sdl.h"
GET "sdl.b"
.
GET "libhdr"
GET "sdl.h"

GLOBAL {
  hello:ug
  fmt
}

LET start() = VALOF
{ LET mes = VEC 256/bytesperword

  initsdl()
  mkscreen("SDL Demo", 640, 480)

  //Load image
  hello := sys(Sys_sdl, sdl_loadbmp, "demo.bmp")

  //Apply image to screen
  blitsurfrect(hello, 0, screen, 0, 0)
  
  // Draw some shapes
  drawdemo(format)

  //Update screen
  updatescreen()

  //Pause for 5 secs
  sdldelay(5000);

  //Free the loaded image
  freesurface(hello);

  //Quit SDL
  sys(Sys_sdl, sdl_quit)

  writef("Success!*n")

  RESULTIS 0
}

AND drawdemo(format) BE
{ LET c_white = maprgb(255, 255, 255)
  LET c_gray  = maprgb(200, 200, 200)
  LET c_dgray = maprgb( 64,  64,  64)
  LET c_cyan  = maprgb( 32, 255, 255)
  LET c_red   = maprgb(255,   0,   0)

  //writef("*ndrawdemo: colours %8x %8x %8x %8x*n", c_white, c_gray, c_dgray, c_cyan)

  //sawritef("*ndrawdemo: calling fillrect screen=%n rect=%n col=%8x*n", screen, 0, c_cyan)
  //delay(1000)
  sys(Sys_sdl, sdl_fillrect, screen, 0, c_cyan)
  updatescreen()
  //delay(1000)

  //sawritef("*ndrawdemo: calling drawline screen=%n %n %n %n %n col=%8x*n",
  //                             screen, 100, 100,  30,   0, c_gray)
  //delay(1000)
  sys(Sys_sdl, sdl_drawline, screen, 100, 100,  30,   0, c_gray)
  updatescreen()

  //delay(1000)
  sys(Sys_sdl, sdl_drawline, screen,  30,   0, 100, 100, c_white)
  sys(Sys_sdl, sdl_drawline, screen, 100, 100,  30,   0, c_white)
  sys(Sys_sdl, sdl_drawline, screen,   0,   0, 300, 200, c_white)

  setcolour(c_red)
  drawtriangle(300,400, 250,20, 400,450)
  updatescreen()
}
