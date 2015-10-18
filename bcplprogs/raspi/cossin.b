 // Insert the SDL library source code as a separate section

GET "libhdr"
GET "sdl.h"
GET "sdl.b"
.
GET "libhdr"
GET "sdl.h"

GLOBAL {
  x0:ug  // The scaling parameters
  y0
  scale
  col_white; col_blue; col_green; col_red; col_gray; col_black
}

MANIFEST { upb = 4 }

LET start() = VALOF
{ initsdl()
  mkscreen("Cosine and sine curves", 800, 400)

  // Declare a few colours in the pixel format of the screen
  col_white := maprgb(255, 255, 255)
  col_black := maprgb(  0,   0,   0)
  col_blue  := maprgb(  0,   0, 225)
  col_green := maprgb(  0, 185,   0)
  col_red   := maprgb(195,   0,   0)
  col_gray  := maprgb(228, 228, 228)

  fillsurf(col_gray)
  updatescreen()    //Update the screen hardware

  setscaling()      // Set the scaling parameters for smoveto etc.

  setcolour(col_black);     plotgraphpaper()
  setcolour(col_red);       plot_fn(cosine)
  setcolour(col_green);     plot_fn(sine)
  setcolour(col_blue);      plotcircle()

  updatescreen()   //Update the screen hardware
  sdldelay(20_000) //Pause for 20 secs

  closesdl()
  RESULTIS 0
}

AND smoveto(x, y) BE
{ LET screenx = x0 + muldiv(x, scale, 1_000_000) 
  AND screeny = y0 + muldiv(y, scale, 1_000_000) 
  moveto(screenx, screeny)
}

AND sdrawto(x, y) BE
{ LET screenx = x0 + muldiv(x, scale, 1_000_000) 
  AND screeny = y0 + muldiv(y, scale, 1_000_000) 
  drawto(screenx, screeny)
  updatescreen()  //Update the screen
  sdldelay(20)    // So we can see the curves being drawn
}

AND setscaling() BE
{ // Set the scaling parameters x0, y0 and scale used by smoveto
  // and sdrawto so that the drawing area from x = 0 to 2 pi and
  // y = -1.0 to +1.0 appears centered in the window.
  // The convertion from graph coordinates (x, y) to
  // screen coordinates will be as follows

  // screenx = x0 + muldiv(x, scale, 1_000_000) 
  // screeny = y0 + muldiv(y, scale, 1_000_000) 

  x0    := screenxsize / 20
  y0    := screenysize / 2
  scale := muldiv(screenxsize*9/10, 1_000_000, 2 * 3_1415)
}

AND plotgraphpaper() BE
{ FOR i = -1 TO +1 DO
  { // Draw horizontal lines at -1.0000, 0 and 1.0000
    smoveto(         0, i * 1_0000)
    sdrawto(  2*3_1415, i * 1_0000)
  }
  FOR i = 0 TO 4 DO
  { // Draw vertical lines at 0, pi/2, pi 3pi/2 and 2pi
    smoveto(  i*3_1415/2, -1_0000)
    sdrawto(  i*3_1415/2, +1_0000)
  }
}

AND plot_fn(f) BE FOR n = 0 TO 100 DO
{ // Plot f(theta) from theta = 0 to 2 pi
  LET theta = VEC upb
  LET pi = TABLE 3,1415,9265,3589,7932
  FOR j = 0 TO upb DO theta!j := pi!j // Set theta = pi
  mulbyk(theta, 2*n)
  divbyk(theta, 100)
  TEST n=0
  THEN smoveto(10000*theta!0+theta!1, f(theta))
  ELSE sdrawto(10000*theta!0+theta!1, f(theta))
}

AND plotcircle() BE FOR n = 0 TO 100 DO
{ LET theta = VEC upb
  LET pi = TABLE 3,1415,9265,3589,7932
  FOR i = 0 TO upb DO theta!i := pi!i // Set theta = pi
  mulbyk(theta, 2*n)
  divbyk(theta, 100)
  TEST n=0
  THEN smoveto(cosine(theta)+3_1415, sine(theta))
  ELSE sdrawto(cosine(theta)+3_1415, sine(theta))
}

AND sumseries(theta, n) = VALOF
{ // n=0  return cosine theta as a scaled number with 4 decimal
  //      digits after the decimal point
  // n=1  return sine theta as a scaled number with 4 decimal
  //      digits after the decimal point
  LET sum   = VEC upb
  LET term  = VEC upb    // Next term to add, x^n/n!
  LET negt2 = VEC upb    // To hold -theta^2

  FOR i = 0 TO upb DO sum!i, term!i := 0, 0 // Set sum and term to zero
  term!0 := 1                               // Set sum to 1.0000

  IF n DO mult(term, term, theta)           // Set term for sine
  
  FOR i = 0 TO upb DO negt2!i := theta!i    // Set negt2 = theta
  mult(negt2, negt2, negt2)                 // negt2 now holds theta^2
  neg(negt2, negt2)                         // negt2 now hold -theta^2

  UNTIL iszero(term) DO
  { add(sum, sum, term)     // Accumulate the current term
    mult(term, term, negt2) // Calculate the next term in the series
    divbyk(term, n+1)
    divbyk(term, n+2)
    n := n+2
  }

  RESULTIS 1_0000*sum!0 + sum!1 // Return a fix point scaled number
}

AND iszero(v) = VALOF
{ FOR i = 0 TO upb IF v!i RESULTIS FALSE
  RESULTIS TRUE
} 

AND cosine(theta) = sumseries(theta, 0)

AND sine(theta)   = sumseries(theta, 1)

AND mult(x, y, z) BE
{ // Set x to the product of y and z
  // x, y and z need not be distinct, so copies are made.
  LET res    = VEC upb+3 // res includes some guard digits
  LET cy     = VEC upb   // cy and cz will hold copies of y and z
  LET cz     = VEC upb
  LET resneg = FALSE

  // Make copies of y and z
  FOR i = 0 TO upb DO cy!i, cz!i := y!i, z!i
  // Set res to zero

  FOR i = 0 TO upb+3 DO res!i := 0
  // Rounding of the result is done by adding 1/2 to the last digit
  res!(upb+1) := 5000

  IF cy!0<0 DO { neg(cy, cy); resneg := ~resneg }
  IF cz!0<0 DO { neg(cz, cz); resneg := ~resneg }

  // cy and cz now both reprent positive numbers
  FOR i = 0 TO upb IF cy!i FOR j = 0 TO upb+3-i DO
  { LET p = i + j                  // Destination in range 0 to upb+3
    LET d = res!p + cy!i * cz!j 
    LET carry = d / 10000
    IF p=0 DO { res!0 := d; LOOP } // res!0 is allowed to be >= 10000
    res!p := d MOD 10000

    // Deal with the carry, if any
    WHILE carry DO
    { p := p-1                  // Position of next digit to the left
      d := res!p + carry
      IF p=0 DO { res!0 := d; BREAK }
      carry := d  /  10000
      res!p := d MOD 10000
    }
  }
  TEST resneg
  THEN neg(x, res)                       // Set x = -res
  ELSE FOR i = 0 TO upb DO x!i := res!i  // Set x =  res
}

AND neg(x, y) BE
{ // Set x to -y
  LET carry = 1
  FOR i = upb TO 1 BY -1 DO 
  { LET d = 9999 - y!i + carry
    x!i   := d MOD 10000
    carry := d  /  10000
  }
  x!0 := carry - y!0 -1
}

AND add(x, y, z) BE
{ LET carry = 0
  FOR i = upb TO 1 BY -1 DO
  { LET d = y!i + z!i + carry
    x!i   := d MOD 10000
    carry := d  /  10000
  }
  x!0 := y!0 + z!0 + carry
}

AND sub(x, y, z) BE
{ // Set x = y - z
  // Copy z because it might be the same as y
  LET cz = VEC upb
  neg(cz, z)
  add(x, y, cz)
}

AND mulbyk(v, k) BE
{ LET carry = 0
  LET resneg = FALSE
  IF v!0<0 DO { neg(v, v); resneg := ~resneg }
  IF k<0   DO { k := -k;   resneg := ~resneg }

  FOR i = upb TO 1 BY -1 DO
  { LET d = v!i * k + carry
    v!i   := d MOD 10000
    carry := d  /  10000
  }
  v!0 := v!0 * k + carry

  IF resneg DO neg(v, v)
}

AND divbyk(v, k) BE
{ LET carry  = 0
  LET resneg = FALSE
  IF v!0<0 DO { neg(v, v); resneg := ~resneg }
  IF k<0   DO { k := -k;   resneg := ~resneg }

  FOR i = 0 TO upb DO
  { LET d = carry*10000 + v!i
    v!i   := d  /  k
    carry := d MOD k
  }
  IF resneg DO neg(v, v)
}
