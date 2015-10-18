/*
Graphics Library for BCPL
Implemented by Martin Richards (c) December 2011

The header file is g/graphics.h

This file should be included (by GET) after libhdr has been included
and after the manifest gaphicsgbase has been declared if the default value declared in libhdr
is not suitable. This library uses region of the global vector from graphicsbase upwards.

This library provides and interface with the SDL grapics library.

09/12/11
Started inplementation
*/

//GET "graphics"

LET opengraphics(xmax, ymax) = VALOF
{ // Allocate the rectangular pixel array and colour map.
  // Return TRUE if successful
  xsize, ysize := xmax, ymax
  canvas, colourtab := 0, 0

  plotcolour := col_black
  plotx, ploty := 0, 0
  rowlen := (ysize+3) & -4 // Round up to a multiple of 4 bytes
  canvassize := xsize * rowlen           // Number of bytes
  canvasupb := canvassize/bytesperword   // UPB in words

  canvas := getvec(canvasupb)
  UNLESS canvas RESULTIS FALSE
  colourtab := initcolourtab()

  FOR i = 0 TO canvasupb DO canvas!i := 0//randno(1000000)

  RESULTIS TRUE
}

AND closegraphics() BE
{ IF canvas DO freevec(canvas)
}

AND wrgraph(filename) BE
{ // Output .pbm format file to filename scale to 15x25cms.

  LET xres  = muldiv(xsize, 100, 15)  // 15 cms horizontal 
  LET yres  = xres//muldiv(ysize, 100, 25)  // 25 cms vertical
  LET hdrsize     = 14
  LET infohdrsize = 40
  LET paletsize   = 4*256
  LET dataoffset = hdrsize + infohdrsize + paletsize
  LET stream = findoutput(filename)
  LET ostream = output()

  UNLESS stream DO
  { writef("Trouble with file: %s*n", filename)
    RETURN
  }

  selectoutput(stream)

  // Write the header
  wr1('B'); wr1('M') // "BM"
  //wr4(hdrsize + infohdrsize + pixeldatasize) // File size in bytes
  wr4(dataoffset + canvassize) // File size in bytes
  wr4(0)             // Unused
  wr4(dataoffset)    // File offset of pixel data

  // Write the Info header
  wr4(40)             // Size of info header = 40
  wr4(ysize)          // Bitmap width
  wr4(xsize)          // Bitmap height
  wr2(1)              // Number of planes = 1
  wr2(8)              // 8 bits per pixel
  wr4(0)              // No compression
  //wr4(pixeldatasize)  // Size of image
  wr4(0)              // Size of image =0 valid if no compression
  wr4(yres)           // Horizontal resolution in pixels per meter
  wr4(xres)           // Vertical   resolution in pixels per meter
  wr4(256)            // Number of colours actually used
  wr4(0)              // All colours are important

  // Write the colour table
  FOR i = 0 TO 255 DO wr4(colourtab!i)

//sawritef("*nwrgraph: writing picture %nx%n*n", xsize, ysize)
  FOR x = 0 TO xsize-1 DO
  { LET xrow = x*rowlen 
    IF x MOD 100 = 0 DO sawritef("raster line %i4 of %i4*n", x, xsize-1)

    FOR y = ysize-1 TO 0 BY -1 DO
    { LET a = canvas%(xrow + y)
      wr1(a)
    }
    FOR y = ysize+1 TO rowlen DO wr1(0) // Pad up to next 32-bit boundary
  }

fin:
  IF stream DO endstream(stream)
  selectoutput(ostream)
}

AND initcolourtab() = VALOF
{ LET colours = TABLE
  //    //   n    red    green    blue
  //         0,   255,    255,    255,  // White
  //        28,   150,    150,    150,  // Light grey
  //        56,     0,    150,    150,  // 
  //        85,     0,      0,    190,  // Blue
  //       113,   130,      0,    130,  //
  //       142,   150,      0,      0,  // Red
  //       170,   140,    140,      0,  // 
  //       199,     0,    180,      0,  // Green
  //       227,   100,    100,    100,  // Dark grey
  //       256,     0,      0,      0   // Black

      //   n        red    green    blue
             0,     255,    255,    255,  // White
          col_rb,   255,      0,    255,  // red-blue
          col_b,      0,      0,    255,  // blue
          col_gb,     0,    255,    255,  // blue-green
          col_g,      0,    255,      0,  // green
          col_rg,   255,    255,      0,  // green-red
          col_r,    255,      0,      0,  // red 
          255,        0,      0,      0   // black
  LET t = colours
  LET ctab = getvec(255)
  UNLESS ctab RESULTIS 0

  WHILE !t<255 DO
  { LET p, r1, g1, b1 = t!0, t!1, t!2, t!3
    LET q, r2, g2, b2 = t!4, t!5, t!6, t!7
//sawritef("p=%i3  q=%i3  %i3 %i3 %i3  %i3 %i3 %i3*n",
//            p, q, r1, g1, b1, r2, g2, b2)
    FOR i = p TO q DO
    { LET r = (r1*(q-i)+r2*(i-p))/(q-p)
      LET g = (g1*(q-i)+g2*(i-p))/(q-p)
      LET b = (b1*(q-i)+b2*(i-p))/(q-p)
      ctab!i := r<<16 | g<<8 | b
      //sawritef("%i3: %x6*n", i, ctab!i)
    }
    //sawritef("*n")
    //abort(1000)
    t := t+4
  }
  //sawritef("*nColour table*n")
  //FOR i = 0 TO 255 DO
  //{ IF i MOD 8 = 0 DO sawrch('*n')
  //  sawritef(" %x6", ctab!i)
  //}
  //sawrch('*n')
  RESULTIS ctab    
}


AND wr1(b) BE
{ binwrch(b)
}

AND wr2(w) BE
{ LET s = @w
  binwrch(s%0)
  binwrch(s%1)
}

AND wr4(w) BE
{ LET s = @w
  binwrch(s%0)
  binwrch(s%1)
  binwrch(s%2)
  binwrch(s%3)
}

AND wrpixel(x, y, col) BE IF 0<=x<xsize & 0<=y<ysize DO
{ // Plot a 3x3 point
  LET p = x*rowlen + y
//sawritef("wrpixel: x=%i4  y=%i4  col=%i3*n", x, y, col)
  canvas%p := col
}

AND wrpixel33(x, y, col) BE
{ // Plot a 3x3 point
  FOR i = -1 TO 1 FOR j = -1 TO 1 DO wrpixel(x+i, y+j, col)
}

AND plotch(ch) BE TEST ch='*n'
THEN { plotx, ploty := 10, ploty-14
     }
ELSE { LET x, y = plotx+1, ploty
       FOR line = 0 TO 11 DO
         write_ch_slice(plotx, ploty+11-line, ch, line)
       plotx := plotx+9
     }


AND write_ch_slice(x, y, ch, line) BE
{
  // Writes the horizontal slice of the given character.

  LET i = (ch&#x7F) - '*s'
  LET charbase = TABLE // Needs correction !!!
         #X00000000, #X00000000, #X00000000, // space
         #X18181818, #X18180018, #X18000000, // !
         #X66666600, #X00000000, #X00000000, // "
         #X6666FFFF, #X66FFFF66, #X66000000, // #
         #X7EFFD8FE, #X7F1B1BFF, #X7E000000, // $
         #X06666C0C, #X18303666, #X60000000, // %
         #X3078C8C8, #X7276DCCC, #X76000000, // &
         #X18181800, #X00000000, #X00000000, // '
         #X18306060, #X60606030, #X18000000, // (
         #X180C0606, #X0606060C, #X18000000, // )
         #X00009254, #X38FE3854, #X92000000, // *
         #X00000018, #X187E7E18, #X18000000, // +
         #X00000000, #X00001818, #X08100000, // ,
         #X00000000, #X007E7E00, #X00000000, // -
         #X00000000, #X00000018, #X18000000, // .
         #X06060C0C, #X18183030, #X60600000, // /
         #X386CC6C6, #XC6C6C66C, #X38000000, // 0
         #X18387818, #X18181818, #X18000000, // 1
         #X3C7E6206, #X0C18307E, #X7E000000, // 2
         #X3C6E4606, #X1C06466E, #X3C000000, // 3
         #X1C3C3C6C, #XCCFFFF0C, #X0C000000, // 4
         #X7E7E6060, #X7C0E466E, #X3C000000, // 5
         #X3C7E6060, #X7C66667E, #X3C000000, // 6
         #X7E7E0606, #X0C183060, #X40000000, // 7
         #X3C666666, #X3C666666, #X3C000000, // 8
         #X3C666666, #X3E060666, #X3C000000, // 9
         #X00001818, #X00001818, #X00000000, // :
         #X00001818, #X00001818, #X08100000, // ;
         #X00060C18, #X30603018, #X0C060000, // <
         #X00000000, #X7C007C00, #X00000000, // =
         #X00603018, #X0C060C18, #X30600000, // >
         #X3C7E0606, #X0C181800, #X18180000, // ?
         #X7E819DA5, #XA5A59F80, #X7F000000, // @
         #X3C7EC3C3, #XFFFFC3C3, #XC3000000, // A
         #XFEFFC3FE, #XFEC3C3FF, #XFE000000, // B
         #X3E7FC3C0, #XC0C0C37F, #X3E000000, // C
         #XFCFEC3C3, #XC3C3C3FE, #XFC000000, // D
         #XFFFFC0FC, #XFCC0C0FF, #XFF000000, // E
         #XFFFFC0FC, #XFCC0C0C0, #XC0000000, // F
         #X3E7FE1C0, #XCFCFE3FF, #X7E000000, // G
         #XC3C3C3FF, #XFFC3C3C3, #XC3000000, // H
         #X18181818, #X18181818, #X18000000, // I
         #X7F7F0C0C, #X0C0CCCFC, #X78000000, // J
         #XC2C6CCD8, #XF0F8CCC6, #XC2000000, // K
         #XC0C0C0C0, #XC0C0C0FE, #XFE000000, // L
         #X81C3E7FF, #XDBC3C3C3, #XC3000000, // M
         #X83C3E3F3, #XDBCFC7C3, #XC1000000, // N
         #X7EFFC3C3, #XC3C3C3FF, #X7E000000, // O
         #XFEFFC3C3, #XFFFEC0C0, #XC0000000, // P
         #X7EFFC3C3, #XDBCFC7FE, #X7D000000, // Q
         #XFEFFC3C3, #XFFFECCC6, #XC3000000, // R
         #X7EC3C0C0, #X7E0303C3, #X7E000000, // S
         #XFFFF1818, #X18181818, #X18000000, // T
         #XC3C3C3C3, #XC3C3C37E, #X3C000000, // U
         #X81C3C366, #X663C3C18, #X18000000, // V
         #XC3C3C3C3, #XDBFFE7C3, #X81000000, // W
         #XC3C3663C, #X183C66C3, #XC3000000, // X
         #XC3C36666, #X3C3C1818, #X18000000, // Y
         #XFFFF060C, #X183060FF, #XFF000000, // Z
         #X78786060, #X60606060, #X78780000, // [
         #X60603030, #X18180C0C, #X06060000, // \
         #X1E1E0606, #X06060606, #X1E1E0000, // ]
         #X10284400, #X00000000, #X00000000, // ^
         #X00000000, #X00000000, #X00FFFF00, // _
         #X30180C00, #X00000000, #X00000000, // `
         #X00007AFE, #XC6C6C6FE, #X7B000000, // a
         #XC0C0DCFE, #XC6C6C6FE, #XDC000000, // b
         #X00007CFE, #XC6C0C6FE, #X7C000000, // c
         #X060676FE, #XC6C6C6FE, #X76000000, // d
         #X00007CFE, #XC6FCC0FE, #X7C000000, // e
         #X000078FC, #XC0F0F0C0, #XC0000000, // f
         #X000076FE, #XC6C6C6FE, #X7606FE7C, // g
         #XC0C0DCFE, #XC6C6C6C6, #XC6000000, // h
         #X18180018, #X18181818, #X18000000, // i
         #X0C0C000C, #X0C0C0C7C, #X38000000, // j
         #X00C0C6CC, #XD8F0F8CC, #XC6000000, // k
         #X00606060, #X6060607C, #X38000000, // l
         #X00006CFE, #XD6D6D6D6, #XD6000000, // m
         #X0000DCFE, #XC6C6C6C6, #XC6000000, // n
         #X00007CFE, #XC6C6C6FE, #X7C000000, // o
         #X00007CFE, #XC6FEFCC0, #XC0000000, // p
         #X00007CFE, #XC6FE7E06, #X06000000, // q
         #X0000DCFE, #XC6C0C0C0, #XC0000000, // r
         #X00007CFE, #XC07C06FE, #X7C000000, // s
         #X0060F8F8, #X6060607C, #X38000000, // t
         #X0000C6C6, #XC6C6C6FE, #X7C000000, // u
         #X0000C6C6, #X6C6C6C38, #X10000000, // v
         #X0000D6D6, #XD6D6D6FE, #X6C000000, // w
         #X0000C6C6, #X6C386CC6, #XC6000000, // x
         #X0000C6C6, #XC6C6C67E, #X7606FE7C, // y
         #X00007EFE, #X0C3860FE, #XFC000000, // z
         #X0C181808, #X18301808, #X18180C00, // {
         #X18181818, #X18181818, #X18181800, // |
         #X30181810, #X180C1810, #X18183000, // }
         #X00000070, #XD1998B0E, #X00000000, // ~
         #XAA55AA55, #XAA55AA55, #XAA55AA55  // rubout

  IF i>=0 DO charbase := charbase + 3*i

  { LET col = plotcolour
    LET w = VALOF SWITCHON line INTO
    { CASE  0: RESULTIS charbase!0>>24
      CASE  1: RESULTIS charbase!0>>16
      CASE  2: RESULTIS charbase!0>> 8
      CASE  3: RESULTIS charbase!0
      CASE  4: RESULTIS charbase!1>>24
      CASE  5: RESULTIS charbase!1>>16
      CASE  6: RESULTIS charbase!1>> 8
      CASE  7: RESULTIS charbase!1
      CASE  8: RESULTIS charbase!2>>24
      CASE  9: RESULTIS charbase!2>>16
      CASE 10: RESULTIS charbase!2>> 8
      CASE 11: RESULTIS charbase!2
    }
    TEST ((w >> 7) & 1) = 1
    THEN wrpixel(x, y, col)
    ELSE wrpixel(x, y, 0)

    TEST ((w >> 6) & 1) = 1
    THEN wrpixel(x+1, y, col)
    ELSE wrpixel(x+1, y, 0)

    TEST ((w >> 5) & 1) = 1
    THEN wrpixel(x+2, y, col)
    ELSE wrpixel(x+2, y, 0)

    TEST ((w >> 4) & 1) = 1
    THEN wrpixel(x+3, y, col)
    ELSE wrpixel(x+3, y, 0)

    TEST ((w >> 3) & 1) = 1
    THEN wrpixel(x+4, y, col)
    ELSE wrpixel(x+4, y, 0)

    TEST ((w >> 2) & 1) = 1
    THEN wrpixel(x+5, y, col)
    ELSE wrpixel(x+5, y, 0)

    TEST ((w >> 1) & 1) = 1
    THEN wrpixel(x+6, y, col)
    ELSE wrpixel(x+6, y, 0)

    TEST (w & 1) = 1
    THEN wrpixel(x+7, y, col)
    ELSE wrpixel(x+7, y, 0)

    wrpixel(x+8, y, 0)
  }
}

AND plotstr(s) BE FOR i = 1 TO s%0 DO plotch(s%i)

AND moveto(x, y) BE
{ plotx, ploty := x, y
}

AND moveby(dx, dy) BE
{ plotx, ploty := plotx+dx, ploty+dy
}

AND drawto(x, y) BE
{ // This is Bresenham's algorithm
  LET dx = ABS(x-plotx)
  AND dy = ABS(y-ploty)
  LET sx = plotx<x -> 1, -1
  LET sy = ploty<y -> 1, -1
  LET err = dx-dy
  LET e2 = ?

  { wrpixel(plotx, ploty, plotcolour)
    IF plotx=x & ploty=y RETURN
    e2 := 2*err
    IF e2 > -dy DO
    { err := err - dy
      plotx := plotx+sx
    }
    IF e2 < dx DO
    { err := err + dx
      ploty := ploty + sy
    }
  } REPEAT
}

AND drawby(dx, dy) BE drawto(plotx+dx, ploty+dy)

AND drawrect(x0, y0, x1, y1) BE
{ LET xmin, xmax = x0, x1
  LET ymin, ymax = y0, y1
  IF xmin>xmax DO xmin, xmax := x1, x0
  IF ymin>ymax DO ymin, ymax := y1, y0
//sawritef("drawrect: %i4 %i4 %i4 %i4*n",xmin,ymin,xmax,ymax)
  FOR x = xmin TO xmax DO
  { wrpixel(x, ymin, plotcolour)
    wrpixel(x, ymax, plotcolour)
  }
  FOR y = ymin+1 TO ymax-1 DO
  { wrpixel(xmin, y, plotcolour)
    wrpixel(xmax, y, plotcolour)
  }
  plotx, ploty := x0, y0
}

AND fillrect(x0, y0, x1, y1) BE
{ LET xmin, xmax = x0, x1
  LET ymin, ymax = y0, y1
  IF xmin>xmax DO xmin, xmax := x1, x0
  IF ymin>ymax DO ymin, ymax := y1, y0
//sawritef("fillrect: %i4 %i4 %i4 %i4*n",xmin,ymin,xmax,ymax)
  FOR x = xmin TO xmax FOR y = ymin TO ymax DO
  { wrpixel(x, y, plotcolour)
    //sawritef("fillrect: x=%i4  y=%i4*n", x, y)
  }
  plotx, ploty := x0, y0
}

AND drawrndrect(x0,y0,x1,y1,radius) BE
{ LET xmin, xmax = x0, x1
  LET ymin, ymax = y0, y1
  LET r = radius
  LET f, ddf_x, ddf_y, x, y = ?, ?, ?, ?, ?

  IF xmin>xmax DO xmin, xmax := x1, x0
  IF ymin>ymax DO ymin, ymax := y1, y0
  IF r<0 DO r := 0
  IF r+r>xmax-xmin DO r := (xmax-xmin)/2
  IF r+r>ymax-ymin DO r := (ymax-ymin)/2

//sawritef("drawrndrect: %i4 %i4 %i4 %i4 %i4*n",xmin,ymin,xmax,ymax,radius)
  FOR x = xmin+r TO xmax-r DO
  { wrpixel(x, ymin, plotcolour)
    wrpixel(x, ymax, plotcolour)
  }
  FOR y = ymin+r+1 TO ymax-r-1 DO
  { wrpixel(xmin, y, plotcolour)
    wrpixel(xmax, y, plotcolour)
  }
  // Now draw the rounded corners
  // This is commonly called Bresenham's circle algorithm since it
  // is derived from Bresenham's line algorithm.
  f := 1 - r
  ddf_x := 1
  ddf_y := -2 * r
  x := 0
  y := r

  wrpixel(xmax, ymin+r, plotcolour)
  wrpixel(xmin, ymin+r, plotcolour)
  wrpixel(xmax, ymax-r, plotcolour)
  wrpixel(xmin, ymax-r, plotcolour)

  WHILE x<y DO
  { // ddf_x = 2*x + 1
    // ddf_y = -2 * y
    // f = x*x + y*y - radius*radius + 2*x - y + 1
    IF f>=0 DO
    { y := y-1
      ddf_y := ddf_y + 2
      f := f + ddf_y
    }
    x := x+1
    ddf_x := ddf_x + 2
    f := f + ddf_x
    wrpixel(xmax-r+x, ymax-r+y, plotcolour) // octant 2
    wrpixel(xmin+r-x, ymax-r+y, plotcolour) // Octant 3
    wrpixel(xmax-r+x, ymin+r-y, plotcolour) // Octant 7
    wrpixel(xmin+r-x, ymin+r-y, plotcolour) // Octant 6
    wrpixel(xmax-r+y, ymax-r+x, plotcolour) // Octant 1
    wrpixel(xmin+r-y, ymax-r+x, plotcolour) // Octant 4
    wrpixel(xmax-r+y, ymin+r-x, plotcolour) // Octant 8
    wrpixel(xmin+r-y, ymin+r-x, plotcolour) // Octant 5
  }

  plotx, ploty := x0, y0
}

AND fillrndrect(x0, y0, x1, y1, radius) BE
{ LET xmin, xmax = x0, x1
  LET ymin, ymax = y0, y1
  LET r = radius
  LET f, ddf_x, ddf_y, x, y = ?, ?, ?, ?, ?
  LET lastx, lasty = 0, 0

  IF xmin>xmax DO xmin, xmax := x1, x0
  IF ymin>ymax DO ymin, ymax := y1, y0
  IF r<0 DO r := 0
  IF r+r>xmax-xmin DO r := (xmax-xmin)/2
  IF r+r>ymax-ymin DO r := (ymax-ymin)/2

//sawritef("fillrndrect: %i4 %i4 %i4 %i4 %i4*n",xmin,ymin,xmax,ymax,radius)
  FOR x = xmin TO xmax FOR y = ymin+r TO ymax-r DO
  { wrpixel(x, y, plotcolour)
    wrpixel(x, y, plotcolour)
  }

  // Now draw the rounded corners
  // This is commonly called Bresenham's circle algorithm since it
  // is derived from Bresenham's line algorithm.
  f := 1 - r
  ddf_x := 1
  ddf_y := -2 * r
  x := 0
  y := r

  wrpixel(xmax, ymin+r, plotcolour)
  wrpixel(xmin, ymin+r, plotcolour)
  wrpixel(xmax, ymax-r, plotcolour)
  wrpixel(xmin, ymax-r, plotcolour)

  WHILE x<y DO
  { // ddf_x = 2*x + 1
    // ddf_y = -2 * y
    // f = x*x + y*y - radius*radius + 2*x - y + 1
    IF f>=0 DO
    { y := y-1
      ddf_y := ddf_y + 2
      f := f + ddf_y
    }
    x := x+1
    ddf_x := ddf_x + 2
    f := f + ddf_x
    wrpixel(xmax-r+x, ymax-r+y, plotcolour) // octant 2
    wrpixel(xmin+r-x, ymax-r+y, plotcolour) // Octant 3
    wrpixel(xmax-r+x, ymin+r-y, plotcolour) // Octant 7
    wrpixel(xmin+r-x, ymin+r-y, plotcolour) // Octant 6
    wrpixel(xmax-r+y, ymax-r+x, plotcolour) // Octant 1
    wrpixel(xmin+r-y, ymax-r+x, plotcolour) // Octant 4
    wrpixel(xmax-r+y, ymin+r-x, plotcolour) // Octant 8
    wrpixel(xmin+r-y, ymin+r-x, plotcolour) // Octant 5

    UNLESS x=lastx DO
    { FOR fx = xmin+r-y+1 TO xmax-r+y-1 DO
      { wrpixel(fx, ymax-r+x, plotcolour)
        wrpixel(fx, ymin+r-x, plotcolour)
      }
      lastx := x
    }
    UNLESS y=lasty DO
    { FOR fx = xmin+r-x+1 TO xmax-r+x-1 DO
      { wrpixel(fx, ymax-r+y, plotcolour)
        wrpixel(fx, ymin+r-y, plotcolour)
      }
    }
  }

  plotx, ploty := x0, y0
}

AND drawcircle(x0, y0, radius) BE
{ // This is commonly called Bresenham's circle algorithm since it
  // is derived from Bresenham's line algorithm.
  LET f = 1 - radius
  LET ddf_x = 1
  LET ddf_y = -2 * radius
  LET x = 0
  LET y = radius
  wrpixel(x0, y0+radius, plotcolour)
  wrpixel(x0, y0-radius, plotcolour)
  wrpixel(x0+radius, y0, plotcolour)
  wrpixel(x0-radius, y0, plotcolour)

  WHILE x<y DO
  { // ddf_x = 2*x + 1
    // ddf_y = -2 * y
    // f = x*x + y*y - radius*radius + 2*x - y + 1
    IF f>=0 DO
    { y := y-1
      ddf_y := ddf_y + 2
      f := f + ddf_y
    }
    x := x+1
    ddf_x := ddf_x + 2
    f := f + ddf_x
    wrpixel(x0+x, y0+y, plotcolour)
    wrpixel(x0-x, y0+y, plotcolour)
    wrpixel(x0+x, y0-y, plotcolour)
    wrpixel(x0-x, y0-y, plotcolour)
    wrpixel(x0+y, y0+x, plotcolour)
    wrpixel(x0-y, y0+x, plotcolour)
    wrpixel(x0+y, y0-x, plotcolour)
    wrpixel(x0-y, y0-x, plotcolour)
  }
}

AND fillcircle(x0, y0, radius) BE
{ // This is commonly called Bresenham's circle algorithm since it
  // is derived from Bresenham's line algorithm.
  LET f = 1 - radius
  LET ddf_x = 1
  LET ddf_y = -2 * radius
  LET x = 0
  LET y = radius
  LET lastx, lasty = 0, 0
  wrpixel(x0, y0+radius, plotcolour)
  wrpixel(x0, y0-radius, plotcolour)
  FOR x = x0-radius TO x0+radius DO wrpixel(x, y0, plotcolour)

  WHILE x<y DO
  { // ddf_x = 2*x + 1
    // ddf_y = -2 * y
    // f = x*x + y*y - radius*radius + 2*x - y + 1
    IF f>=0 DO
    { y := y-1
      ddf_y := ddf_y + 2
      f := f + ddf_y
    }
    x := x+1
    ddf_x := ddf_x + 2
    f := f + ddf_x
    wrpixel(x0+x, y0+y, plotcolour)
    wrpixel(x0-x, y0+y, plotcolour)
    wrpixel(x0+x, y0-y, plotcolour)
    wrpixel(x0-x, y0-y, plotcolour)
    wrpixel(x0+y, y0+x, plotcolour)
    wrpixel(x0-y, y0+x, plotcolour)
    wrpixel(x0+y, y0-x, plotcolour)
    wrpixel(x0-y, y0-x, plotcolour)
    UNLESS x=lastx DO
    { FOR fx = x0-y+1 TO x0+y-1 DO
      { wrpixel(fx, y0+x, plotcolour)
        wrpixel(fx, y0-x, plotcolour)
      }
      lastx := x
    }
    UNLESS y=lasty DO
    { FOR fx = x0-x+1 TO x0+x-1 DO
      { wrpixel(fx, y0+y, plotcolour)
        wrpixel(fx, y0-y, plotcolour)
      }
      lasty := y
    }
  }
}
