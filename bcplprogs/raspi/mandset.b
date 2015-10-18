 // Insert the SDL library source code as a separate section

GET "libhdr"
GET "sdl.h"
GET "sdl.b"
.
GET "libhdr"
GET "sdl.h"

GLOBAL {
  a:ug
  b
  size
  limit    // The iteration limit
  v
  col_white; col_gray; col_black
}

MANIFEST {
  One = 100_000_000 // The number representing 1.00000000
  width=512
  height=width      // Ensure the window is square
}

LET start() = VALOF
{ LET s = 0           // Region selector
  LET argv = VEC 50

  UNLESS rdargs("s/n,a/n,b/n,size/n,limit/n", argv, 50) DO
  { writes("Bad arguments for mandset*n")
    RESULTIS 0
  }

  v := 0

  // Default settings
  a, b, size := -50_000_000, 0, 180_000_000
  limit := 38

  IF argv!0 DO s     := !argv!0        // s/n
  IF argv!1 DO a     := !argv!1        // a/n 
  IF argv!2 DO b     := !argv!2        // b/n
  IF argv!3 DO size  := !argv!3        // size/n
  IF argv!4 DO limit := !argv!4        // limit/n

  IF 1<=s<=7 DO
  { LET limtab = TABLE  38,  38,  38,  54,  70,  //  0 
                        80,  90, 100, 100, 110,  //  5 
                       120, 130, 140, 150, 160,  // 10 
                       170, 180, 190, 200, 210,  // 15 
                       220                       // 20 
    limit := limtab!s
    a, b, size := -52_990_000, 66_501_089,  50_000_000
    FOR i = 1 TO s DO size := size / 10
  }

  initsdl()
  mkscreen("Mandelbrot Set", width, height)

  // Declare a few colours in the pixel format of the screen
  col_white := maprgb(255, 255, 255)
  col_gray  := maprgb(128, 128, 128)
  col_black := maprgb(  0,   0,   0)

  v := getvec(width*height-1)
  // Initialise v
  FOR i = 0 TO width*height - 1 DO v!i := i
  // Random shuffle v so that the screen pixels are filled in
  // in random order.
  FOR i = width*height - 1 TO 1 BY -1 DO
  { LET j = randno(i+1) - 1 // Random number in range 0 .. i
    LET t = v!j
    v!j := v!i
    v!i := t
  }

  plotset()

  setcolour(col_white)
  plotf(5, 50, "s     = "); plotf(50, 50, " %i4*n", s)
  plotf(5, 35, "a     = %11.8d b = %11.8d size = %11.8d", a, b, size)
  plotf(5, 20, "limit = "); plotf(50, 20, " %i4*n", limit)
  updatescreen()

  sdldelay(60_000) //Pause for 60 secs
  closesdl()
  IF v DO freevec(v)
  RESULTIS 0
}

AND colfill(p, m, col1, col2) BE
{ //writef("colfill: p=%i5 m=%i3 col1=%o9 col2=%o9*n", p, m, col1, col2)
  //abort(1000)
  TEST m<=1
  THEN { putcolour(p, 0, col1)
       }
  ELSE { // Fill p!0 to p!(m-1) with colours using linear
         // interpolation.
         LET m2 = m/2             // Midpoint
         LET midcol = (col1+col2)/2 // Midpoint colour
         colfill(p, m2, col1, midcol)
         colfill(p+m2, m-m2, midcol, col2)
       }
}

AND putcolour(p, i, col) BE
{ LET r, g, b = (col>>18)&255, (col>>9)&255, col&255
//  writef("putcolour: p=%i6 i=%i3 col=%o9 r=%i3 g=%i3 b=%i3*n",
//          p, i, col, r, g, b)
//abort(1000)
  p!i := maprgb(r, g, b)
}

AND setpalette(p, lim, colv, n) BE
{ // Fill in colours in p!0 to p!lim based on
  // the colours in colv!0 to colv!n
//writef("setpalette: p=%i5 lim=%i3 colv=%i5 n=%i3*n", p, lim, colv, n)
//abort(1000)
  IF lim<=n DO
  { FOR i = lim TO 0 BY -1 DO { putcolour(p, i, colv!n); n := n-1 }
    RETURN
  }
  IF lim - lim/4 >= n DO
  { LET m = lim/4
    colfill(p, m, colv!0, colv!1)
    setpalette(p+m, lim-m, colv+1, n-1)
    RETURN
  }
  // Copy colours from colv! to colv!n to p!(lime-n+1) to p!lim
  WHILE n>0 DO
  { putcolour(p, lim, colv!n)
    lim, n := lim-1, n-1
  }
  colfill(p, lim+1, colv!0, colv!1)
}

AND plotset() BE
{ // The following table hold 8-bit rgb colours packed
  // in three 9-bit fields. It is used to construct a palette
  // of colours depending on the current limit setting.
  LET coltab = TABLE
      #300_300_377, #200_200_377, #100_100_377, #000_000_377, //  0
      #040_040_300, #070_140_300, #070_110_260, #100_170_260, //  4
      #120_260_260, #150_277_240, #120_310_200, #120_340_200, //  8
      #120_377_200, #100_377_150, #177_377_050, #270_377_070, // 12
      #350_377_200, #350_300_200, #340_260_200, #377_260_140, // 16
      #377_220_100, #377_170_100, #347_200_100, #360_100_000, // 20
      #240_300_000, #100_277_000, #000_377_000, #230_350_230, // 24
      #340_340_377, #377_377_377, #377_377_200, #377_377_100, // 28
      #377_377_000                                            // 32
 
  LET mina = a - size
  LET minb = b - size

  LET colourv = VEC 500

  setpalette(colourv, limit, coltab, 32)

  fillsurf(col_gray)

  // Draw a small white square at the centre
  setcolour(col_white)
  drawrect(width*45/100, height*45/100,
           width*55/100, height*55/100)

  // Draw the colour bar
  FOR x = 0 TO width-1 DO
  { LET i = ((limit+1) * x) / width
    LET p, q = x, 6
    setcolour(colourv!i)
    moveto(p, q)
    drawby(0, 6)
  }
  updatescreen()

  FOR i = 0 TO width*height - 1 DO // Number of points to plot
  { LET vi = v!i
    LET colour = ?
    LET itercount = ?
    LET x, y, p, q = ?, ?, ?, ?

    // Periodically update the screen as the pixels are drawn
    IF i MOD 100 = 0 DO updatescreen()

    // Find the coordinates of the next random pixel
    x := vi      & #x1FF     // 0 .. 511
    y := (vi>>9) & #x1FF     // 0 .. 511

    // Calculate c = p + iq corresponding to pixel (x,y)
    p := mina + muldiv(2*size, x, 511)
    q := minb + muldiv(2*size, y, 511)

    itercount := mandset(p, q, limit)
    TEST itercount<0 
    THEN colour := col_black
    ELSE colour := colourv!itercount

    setcolour(colour)
    drawpoint(x, y)
  }

  // Draw the colour bar
  FOR x = 0 TO width DO
  { LET i = (limit * x) / width
    LET p, q = x, 6
    setcolour(colourv!i)
    moveto(p, q)
    drawby(0, 6)
  }
  updatescreen()
}

AND mandset(a, b, n) = VALOF
{ LET x, y = 0, 0  // z = x + iy is initially zero
                   // c = a + ib is the point we are testing
  FOR i = 0 TO n DO
  { LET t = ?
    LET x3, y3 = x/3, y/3 // To avoid possible overflow
    LET rsq = muldiv(x3, x3, One) + muldiv(y3, y3, One)

    // Test whether z is diverging, ie is x^2+y^2 > 9
    IF rsq > One RESULTIS i

    // Square z and add c
    // Note that (x + iy)^2 = (x^2-y^2) + i(2xy)
    t := muldiv(2*x, y, One) + b
    x := muldiv(x, x, One) - muldiv(y, y, One) + a
    y := t 
  }

  // z did not diverge after n iterations
  RESULTIS -1
}
