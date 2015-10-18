/* 
This is a simple demonstration of the event loop using the SDL library
to read keyboard, mouse and joystick events.

Implemented by (c) Martin Richards   October 2012

It displays a coloured circle in a window. The colour may be set to
red, green or blue by pressing R, G or B on the keyboard. It can be
moved up, down, left or richt using the arrow keys. It may be moved to
the cursor position by pressing the left mouse button. It may also be
moved using the joystick. You can exit the program by pressing Q.

*/

GET "libhdr"
GET "sdl.h"
GET "sdl.b"                 // Insert the library source code
.
GET "libhdr"
GET "sdl.h"

GLOBAL {
  done:ug
  xpos; ypos; xdot; ydot

  col_blue; col_green; col_red
  col_cyan; col_white; col_gray
}

LET start() = VALOF
{ initsdl()
  mkscreen("Events Test", 600, 400)
  runtest()
  closesdl()
  RESULTIS 0
}

AND runtest() = VALOF
{ // Declare a few colours in the pixel format of the screen
  col_blue        := maprgb(  0,   0, 255)
  col_green       := maprgb(  0, 255,   0)
  col_red         := maprgb(255,   0,   0)
  col_cyan        := maprgb(255, 255,   0)
  col_white       := maprgb(255, 255, 255)
  col_gray        := maprgb(128, 128, 128)

  fillsurf(col_gray)

  xpos, ypos := 1000*screenxsize/2, 1000*screenysize/2
  xdot, ydot := 0, 0
  setcolour(col_red) // Set the initial circle colour
  done := FALSE

  UNTIL done DO
  { step()
    displayall()
    sdldelay(20)
  }

  RESULTIS 0
}

AND step() BE
{ WHILE getevent() SWITCHON eventtype INTO
  { DEFAULT: LOOP

    CASE sdle_keydown:          // 2
      SWITCHON capitalch(eventa2) INTO
      { DEFAULT:                                  LOOP

        CASE sdle_arrowup:    ypos := ypos+8_000; LOOP
        CASE sdle_arrowdown:  ypos := ypos-8_000; LOOP
        CASE sdle_arrowright: xpos := xpos+8_000; LOOP
        CASE sdle_arrowleft:  xpos := xpos-8_000; LOOP

        CASE 'R': setcolour(col_red);             LOOP
        CASE 'G': setcolour(col_green);           LOOP
        CASE 'B': setcolour(col_blue);            LOOP
        CASE 'Q': done := TRUE;                   LOOP
      }

    CASE sdle_keyup:                              LOOP

    CASE sdle_mousemotion:
      UNLESS eventa1 LOOP

    CASE sdle_mousebuttonup:
    CASE sdle_mousebuttondown:    
      xpos, ypos := 1000*eventa2, 1000*(screenysize-eventa3)
      LOOP

    CASE sdle_joyaxismotion:
      SWITCHON eventa2 INTO  // Which axis
      { DEFAULT:                        LOOP
        CASE 0: xdot := +eventa3/2;     LOOP // Aileron
        CASE 1: ydot := -eventa3/2;     LOOP // Elevator
      }

    CASE sdle_joybuttonup:              LOOP
    CASE sdle_joybuttondown:    
      SWITCHON eventa2 INTO
      { DEFAULT:
        CASE  0:  setcolour(col_red);   LOOP
        CASE  1:  setcolour(col_blue);  LOOP
        CASE  2:  setcolour(col_green); LOOP
      }

    CASE sdle_quit:      done := TRUE;  LOOP
  }
  xpos, ypos := xpos+xdot, ypos+ydot
}

AND displayall() BE
{ LET x, y = xpos/1000, ypos/1000
  LET minx, miny = 20, 20
  LET maxx, maxy = screenxsize-20, screenysize-20
  fillsurf(col_gray)

  IF x<minx DO x, xpos := minx, minx*1000
  IF y<miny DO y, ypos := miny, miny*1000
  IF x>maxx DO x, xpos := maxx, maxx*1000
  IF y>maxy DO y, ypos := maxy, maxy*1000

  drawfillcircle(x, y, 20)
  updatescreen()
}

