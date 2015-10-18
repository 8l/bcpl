
/*

This program plots a selected region of the Mandelbrot set using
arbitrary high precision arithmetic. Currently it uses numbers with 48
decimal digits after the decimal point, so it can accurately plot
regions much smaller than a proton assuming one corresponds to a
metre.

Implemented by Martin Richards (c) January 2014
*/


// Insert the SDL library source code as a separate section

SECTION "hdmandset"
GET "libhdr"
GET "sdl.h"
GET "sdl.b"
//.
//SECTION "hdmandset"
//GET "libhdr"
//GET "sdl.h"

GLOBAL {
  limit:ug    // The iteration limit
  v

  // High precision numbers
  av; bv; sizev
  v1; v2; v3
  minav; minbv
  pv; qv
  tv

  // Some colours
  col_white; col_gray; col_black
}

MANIFEST {
  width=512
  height=width      // Ensure the window is square
  upb = 10          // Upb of high precision numbers
  upb1 = upb+1
}

LET start() = VALOF
{ LET s = 0           // Region selector
  LET argv = VEC 50
  LET spacev = VEC 11*upb1+1 // +1 since tv has one guard digit

  UNLESS rdargs("s/n,a,b,size,limit/n", argv, 50) DO
  { writes("Bad arguments for mandset*n")
    RESULTIS 0
  }

  v := 0

  // Allocate high precision number vectors
  // They all have a guard digit at subscript upb1 used for rounding
  av    := spacev + 0*upb1
  bv    := spacev + 1*upb1
  sizev := spacev + 2*upb1
  v1    := spacev + 3*upb1
  v2    := spacev + 4*upb1
  v3    := spacev + 5*upb1
  minav := spacev + 6*upb1
  minbv := spacev + 7*upb1
  pv    := spacev + 8*upb1
  qv    := spacev + 9*upb1
  tv    := spacev +10*upb1

// Test the arithmetic
/*
writef("*nnumfromstr(v1, upb,*
       *1234.1234_2345_3456_4567_5678_6789_7890_8901_9012_9999)*n")
numfromstr(v1, upb,
       "1234.1234_2345_3456_4567_5678_6789_7890_8901_9012_9999")
print(v1)
writef("*nnumfromstr(v2, upb,*
       *-1234.1234_2345_3456_4567_5678_6789_7890_8901_9012_9999)*n")
numfromstr(v2, upb,
       "-1234.1234_2345_3456_4567_5678_6789_7890_8901_9012_9999")
print(v2)

writef("divbyk(v3, v1, 100)*n")
divbyk(v3, v1, 100); print(v3)

writef("divbyk(v3, v3, 100)*n")
divbyk(v3, v3, 100); print(v3)

writef("divbyk(v3, v1, -100)*n")
divbyk(v3, v1, -100); print(v3)

writef("divbyk(v3, v3, -100)*n")
divbyk(v3, v3, -100); print(v3)

writef("divbyk(v3, v2, 100)*n")
divbyk(v3, v2, 100); print(v3)

writef("divbyk(v3, v2, -100)*n")
divbyk(v3, v2, -100); print(v3)

writef("neg(v3, v1)*n")
neg(v3, v1); print(v3)

writef("neg(v3, v2)*n")
neg(v3, v2); print(v3)

writef("add(v3, v1, v2)*n")
add(v3, v1, v2); print(v1); print(v2); print(v3)

writef("mulbyk(v3, v1, 1)*n")
mulbyk(v3, v1, 1); print(v3)

writef("mulbyk(v3, v1, -1)*n")
mulbyk(v3, v1, -1); print(v3)

writef("mulbyk(v3, v2, 1)*n")
mulbyk(v3, v2, 1); print(v3)

writef("mulbyk(v3, v2, -1)*n")
mulbyk(v3, v2, -1); print(v3)


writef("divbyk(v3, v1, 100)*n")
divbyk(v3, v1, 100); print(v3)

writef("divbyk(v1, v1, 100)*n")
divbyk(v1, v1, 100); print(v1)

writef("divbyk(v2, v2, 100)*n")
divbyk(v2, v2, 100); print(v2)

writef("mul(v3, v1, v1)*n")
mul(v3, v1, v1); print(v1); print(v1); print(v3)

writef("mul(v3, v1, v2)*n")
mul(v3, v1, v2); print(v1); print(v2); print(v3)
*/

  // Default settings
  numfromstr(   av, upb, "-0.500_000_00")
  numfromstr(   bv, upb, " 0.000_000_00")
  numfromstr(sizev, upb, " 1.800_000_00")
  limit := 38

  IF argv!0 DO s     := !argv!0               // s/n

  IF 1<=s<=39 DO
  { LET limtab = TABLE  38,  38,  38,  54,  70,  //  0 
                        80,  90, 100, 100, 110,  //  5 
                       120, 130, 140, 150, 160,  // 10 
                       170, 180, 190, 200, 210,  // 15 
                       220, 230, 240, 250, 260,  // 20 
                       270, 280, 290, 300, 310,  // 25 
                       320, 330, 340, 350, 360,  // 30 
                       370, 380, 385, 390, 395   // 35 

    limit := limtab!s
                         // s= 000 000 000 111 111 111 122_222 222 223 333 333 333 4
                         //    123 456 789 012 345 678 901 234 567 890 123 456 789 0
    numfromstr(   av, upb, "-0.529_899_999_999_998_948_805_000_900_100_099_901_340_0")
    numfromstr(   bv, upb, " 0.665_010_889_500_000_000_000_629_209_407_380_001_010_2")
    numfromstr(sizev, upb, " 0.500_000_000_000_000_000_000_000_000_000_000_000_000_3")
    // Multiply size by 10^-s
    FOR i = 1 TO s DO divbyk(sizev, sizev, 10)
    
  }

  IF argv!1 DO numfromstr(   av, upb, argv!1) // a 
  IF argv!2 DO numfromstr(   bv, upb, argv!2) // b 
  IF argv!3 DO numfromstr(sizev, upb, argv!3) // size 
  IF argv!4 DO limit := !argv!4               // limit/n

  newline()
  writef("s     = %i6*n", s)
  writef("a     = "); print(av)
  writef("b     = "); print(bv)
  writef("size  = "); print(sizev)
  writef("limit = %i6*n", limit)

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
  plotf(5, 80, "s     = "); plotf(50, 80, " %i5*n", s)
  plotf(5, 65, "a     = "); plotv(50, 65, av)
  plotf(5, 50, "b     = "); plotv(50, 50, bv)
  plotf(5, 35, "size  = "); plotv(50, 35, sizev)
  plotf(5, 20, "limit = "); plotf(50, 20, " %i5*n", limit)

  updatescreen()

  FOR i = 1 TO 12*60 DO   // Pause for 12 hours
    sdldelay(60_000)      // Pause for 60 secs
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
 
  LET colourv = VEC 500

  setpalette(colourv, limit, coltab, 32)
//abort(1003)
/*  { LET r, dr = 100, 23
    LET g, dg = 200,  4
    LET b, db = 180,  8

    FOR i = 0 TO limit DO
    { r := r + dr
      IF r > 255 DO r, dr := 255, -dr
      IF r <   0 DO r, dr :=   0, -dr
      g := g + dg
      IF g > 255 DO g, dg := 255, -dg
      IF g <   0 DO g, dg :=   0, -dg
      b := b + db
      IF b > 255 DO b, db := 255, -db
      IF b <   0 DO b, db :=   0, -db
      colourv!i := maprgb(r, g, b)
   }
  }
*/
  sub(minav, av, sizev)
  sub(minbv, bv, sizev)
//writef("sizev="); print(sizev)
//writef("av=   "); print(av)
//writef("bv=   "); print(bv)
//writef("minav="); print(minav)
//writef("minbv="); print(minbv)

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
//writef("pixel address: (%i3, %i3)*n", x, y)
    divbyk(pv, sizev, 511) // p := mina + 2*size*x / 511
//writef("size/511=         "); print(pv)
    mulbyk(pv, pv, 2*x)
//writef("2**size**x/511=     "); print(pv)
    add(pv, pv, minav)
//writef("mina+2**size**x/511="); print(pv)

    divbyk(qv, sizev, 511) // q := minb + 2*size*y / 511
//writef("size/511=         "); print(qv)
    mulbyk(qv, qv, 2*y)
//writef("2**size**y/511=     "); print(qv)
    add(qv, qv, minbv)
//writef("minb+2**size**y/511="); print(qv)

//abort(1000)

    itercount := mandset(pv, qv, limit)
    TEST itercount<0 
    THEN colour := col_black
    ELSE colour := colourv!itercount

    setcolour(colour)
    drawpoint(x, y)
  }

  // Draw the colour bar
  FOR x = 0 TO width-1 DO
  { LET i = ((limit+1) * x) / width
    LET p, q = x, 6
    setcolour(colourv!i)
    moveto(p, q)
    drawby(0, 6)
  }
  updatescreen()
}

AND mandset(av, bv, n) = VALOF
{ LET xv  = VEC upb  // z = x + iy is initially zero
  LET yv  = VEC upb
  LET x2v = VEC upb
  LET y2v = VEC upb
  LET sqv = VEC upb

  // Set z = x + iy to zero
  settok(xv, 0, upb)
  settok(yv, 0, upb)

  // c = a + ib is the point we are testing

  FOR i = 0 TO n DO
  { mul(x2v, xv, xv)
    mul(y2v, yv, yv)
    add(sqv, x2v, y2v) // v3 = x^2 + y^2

//writef("%i2: *n", i)
//writef("a=  "); print(av)
//writef("b=  "); print(bv)
//writef("x=  "); print(xv)
//writef("y=  "); print(yv)
//writef("x^2="); print(x2v)
//writef("y^2="); print(y2v)
//writef("r^2="); print(sqv)
//abort(1000)
    // Test whether z is diverging, ie is x^2+y^2 > 9
    IF sqv!0 > 9 RESULTIS i

    // Square z and add c
    // Note that (x + iy)^2 = (x^2-y^2) + i(2xy)

    mul(yv, xv, yv)     // y := 2xy + b
    mulbyk(yv, yv, 2)
    add(yv, yv, bv)

    sub(xv, x2v, y2v)   // x := x^2 - y^2 + a
    add(xv, xv, av)
  }

  // z did not diverge after n iterations
  RESULTIS -1
}

AND settok(v, k, upb) BE
{ v!0 := k                     // Set the integer part
  FOR i = 1 TO upb DO v!i := 0 // Clear all fractional digits
}

AND move(a, b) BE FOR i = 0 TO upb DO a!i := b!i

AND print(v) BE
{ //writef("v -> [%z4 %z4 %z4]*n", v!0, v!1, v!2)
  TEST v!0<0
  THEN { LET t = VEC upb
         neg(t, v)
         pr(t, TRUE)
       }
  ELSE { pr(v, FALSE)
       }
}

AND pr(v, negative) BE
{ //writef("v -> [%z4 %z4 %z4]*n", v!0, v!1, v!2)
  TEST v!0=0 & negative
  THEN writef("    -0.")
  ELSE writef(" %i5.", negative -> -v!0, v!0)
  FOR i = 1 TO upb DO
  { IF i MOD 15 = 0 DO writes("*n ")
    wrpn(v!i, 4)
    wrch('*s')
  }
  newline()
} 
 
AND wrpn(n, d) BE
{ IF d>1 DO wrpn(n/10, d-1)
  n := n MOD 10
  wrch(n+'0')
}

AND plotv(x, y, v) BE
{ //writef("v => [%z4 %z4 %z4]*n", v!0, v!1, v!2)
  TEST v!0<0
  THEN { LET t = VEC upb
         neg(t, v)
         prv(x, y, t, TRUE)
       }
  ELSE { prv(x, y, v, FALSE)
       }
}

AND prv(x, y, v, negative) BE
{ LET xpos = x
  //writef("v => [%z4 %z4 %z4]  negative=%n*n", v!0, v!1, v!2, negative)
  TEST v!0=0 & negative
  THEN plotf(xpos, y, "    -0.")
  ELSE plotf(xpos, y, " %i5.", negative -> -v!0, v!0)
  xpos := xpos+8*8
  FOR i = 1 TO upb DO
  { IF i MOD 15 = 0 DO xpos, y := x, y+15
    xpos := plotpn(xpos, y, v!i, 4)
    plotf(xpos, y, "*s")
    xpos := xpos+8
  }
} 
 
AND plotpn(x, y, n, d) = VALOF
{ IF d>1 DO x := plotpn(x, y, n/10, d-1)
  n := n MOD 10
  plotf(x, y, "%c", n+'0')
  RESULTIS x+8
}

// The high precision numeric functions below other than
// mul do not perform rounding of results. If greater
// precision is required just increase the length of the
// numbers.

AND numfromstr(v, upb, s) BE
{ LET p, k, val = 0, 0, 0
  LET negative = FALSE

  FOR i = 1 TO s%0 DO
  { LET ch = s%i
//writef("p=%n k=%n val=%n ch=%c*n", p, k, val, ch)
    IF ch='-' DO { negative := ~negative; LOOP }
    IF '0'<=ch<='9' DO val, k := 10*val + ch - '0', k+1
    IF k=4 | (ch='.' & k>0) DO
    { IF p<=upb DO v!p := val
      p, k, val := p+1, 0, 0
      LOOP
    }
  }
  UNTIL k=4 DO val, k := 10*val, k+1
  IF p<=upb DO v!p := val
  // Pad on the right with zeroes
  UNTIL p>=upb DO { p := p+1; v!p := 0  }
  IF negative DO neg(v, v)
//  writef("numfromstr: %s => [%z4 %z4 %z4]*n", s, v!0, v!1, v!2)
}

AND mul(x, y, z) BE
{ // Beware is x=y, y is destroyed
  // Beware is x=z, z is destroyed
  LET negative = FALSE

  //IF y=z DO writef("mul: y=[%z4 %z4 %z4]*n", y!0, y!1, y!2)
  //IF y=z DO writef("by   z=[%z4 %z4 %z4]*n", z!0, z!1, z!2)

  IF y!0<0 DO { negative := ~negative; neg(v1, y); y := v1 }
  IF z!0<0 DO { negative := ~negative; neg(v2, z); z := v2 }

  settok(tv, 0, upb1)
  //IF y=z DO writef("after sign changes*n")
  //IF y=z DO writef("mul: y=[%z4 %z4 %z4]*n", y!0, y!1, y!2)
  //IF y=z DO writef("by   z=[%z4 %z4 %z4]*n", z!0, z!1, z!2)
  // Round by adding a half to the last digit position.
  tv!upb1 := 5000
  FOR i = 0 TO upb IF y!i FOR j = 0 TO upb1-i DO
  { LET p = i + j
    LET carry = y!i*z!j 
    WHILE carry DO
    { LET w = tv!p + carry
      IF p=0 DO { tv!0 := w; BREAK }
      tv!p, carry := w MOD 10000, w/10000
      p := p-1
    }
  }
  FOR i = 0 TO upb DO x!i := tv!i
  //IF y=z DO writef("=>   x=[%z4 %z4 %z4]*n", x!0, x!1, x!2)
  IF negative DO neg(x, x)
  //IF y=z DO writef("res  x=[%z4 %z4 %z4]*n", x!0, x!1, x!2)
}

AND add(x, y, z) BE
{ LET c = 0
  FOR i = upb TO 1 BY -1 DO
  { LET d = c + y!i + z!i
//writef("%i2: c=%n yi=%i4 zi=%i4 d=%n", i, c, y!i, z!i, d)
    x!i := d MOD 10000
    c   := d  /  10000
//writef(" => c=%n xi=%i4*n", c, x!i)
  }
//writef("%i2: c=%n yi=%i4 zi=%i4 d=%n", 0, c, y!0, z!0, c+y!0+z!0)
  x!0 := c + y!0 + z!0 
//writef(" => c=%n xi=%i4*n", c, x!0)
//abort(1000)
}
 
AND sub(x, y, z) BE
{ neg(x, z)
  add(x, x, y)
}

AND mulbyk(x, y, k) BE
{ LET c = 0
  LET negative = FALSE
  IF k<0 DO { negative := TRUE; k := - k }
  IF y!0<0 DO
  { negative := ~negative
    neg(tv, y)
    y := tv
  }
  
  FOR i = upb TO 1 BY -1 DO
  { LET d = c + y!i * k
//writef("%i2: c=%n yi=%i4 k=%i4 d=%n", i, c, y!i, k, d)
    x!i := d MOD 10000
    c   := d  /  10000
//writef(" => c=%n xi=%i4*n", c, x!i)
  }
//writef("%i2: c=%n yi=%i4 k=%i4 d=%n", 0, c, y!0, k, c +y!0*k)
  x!0 := c + y!0 * k 
//writef(" =>      xi=%i4*n", x!0)
//abort(1000)

  IF negative DO neg(x, x)
}

AND divbyk(x, y, k) BE
{ LET c = 0
  LET negative = FALSE
  IF k < 0 DO negative, k := TRUE, -k
  IF y!0 < 0 DO
  { negative := ~negative
    neg(tv, y)
    y := tv
  }
  
  FOR i = 0 TO upb DO
  { LET d = c*10000 + y!i
    x!i := d  /  k
    c   := d MOD k
  }

  IF negative DO neg(x, x)
//writef("divbyk: => ")
//print(a)
//abort(1001)
}
 
AND neg(a, b) BE
{ LET carry = 1
  FOR i = upb TO 1 BY -1 DO
  { LET d = 9999 - b!i + carry
    a!i := d MOD 10000
    carry := d / 10000
  }
  a!0 := carry - b!0 - 1
}
