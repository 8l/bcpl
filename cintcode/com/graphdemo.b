GET "libhdr"

// Insert the graphics library
MANIFEST { graphicsgbase=400 }

GET "graphics"
GET "graphics.b"


LET start() = VALOF
{ LET stdout = output()
  LET xsize, ysize = 1000, 700

  UNLESS opengraphics(xsize, ysize) DO
  { writef("Unable to open the graphics library*n")
    GOTO fin
  }

  FOR x = 1 TO xsize-2 DO
  { wrpixel33(x, 1, col_r)
    wrpixel33(x, ysize-2, col_r)
    moveto(x, 4)
    plotcolour := 255*x/xsize
    drawby(0, 20)    
  }

  FOR y = 1 TO ysize-2 DO
  { wrpixel33(1, y, col_r)
    wrpixel33(xsize-2, y, col_r)
  }

  moveto(10, ysize-20)
  plotcolour := col_black
  FOR ch = 33 TO 127 DO
  { IF ch='A' | ch='0' | ch='a' DO plotch('*n')
    plotch(ch)
  }

  plotcolour := col_rb
  fillcircle(300, 200, 65)
  plotcolour := col_b
  drawcircle(350, 250, 65)

  plotcolour := col_rb
  fillrect(150, 40, 200, 140)
  plotcolour := col_gb
  drawrect(180, 50, 240, 110)

  plotcolour := col_b
  fillrndrect(350, 40, 400, 140, 10)
  plotcolour := col_g
  drawrndrect(380, 50, 440, 110, 11)

  plotcolour := col_r
  fillrndrect(580, 60, 660, 230, 120)
  plotcolour := col_g
  drawrndrect(620, 70, 790,  110, 130)

  moveto(200, 150)
  plotcolour := col_g
  drawby(-10,  40)
  drawby(-40,  10)
  drawby(-40, -10)
  drawby(-10, -40)
  drawby( 10, -40)
  drawby( 40, -10)
  drawby( 40,  10)
  drawby( 10,  40)
  plotcolour := col_r
  drawby(50, 40)
  plotstr("Hello There")
  moveby(-9*11, -13)
  plotstr("good day!")

  { // Plot a trajectory
    LET g = 25_000_000
    LET xc, yc = 700, 300 // The centre
    LET x, y = 700, 100
    LET xdot, ydot = 12_000, 0_000
    plotcolour := col_r
    fillcircle(xc, yc, 20)
    FOR i = 1 TO 185 DO 
    { LET dx = x-xc
      LET dy = y-yc
      LET dist = ABS dx + ABS dy
      LET d2 = dx*dx + dy*dy
      wrpixel33(x, y, col_black)
      xdot := xdot*996/1000 - muldiv(g, dx, dist*d2)
      ydot := ydot*996/1000 - muldiv(g, dy, dist*d2)
      x := x + xdot/1000
      y := y + ydot/1000
    }
  }

  wrgraph("pic.bmp")

fin:
  closegraphics()

  RESULTIS 0
}
