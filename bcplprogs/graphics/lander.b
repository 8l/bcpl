/* This is a re-inplementation of a moon lander program
   I originally wrote in BCPL in September 1973 for the PDP-7
   and the Vector General display.

   This implementation is intended to run on a handheld PC
   and will be tested under the BCPL Cintcode System for
   Windows CE running on an HP 620LX

   (c) Martin Richards   Oct 2000

****** UNDER DEVELOPMENT *******************

// The graphics features of the BCPL Cintcode system only
// only available under Windows CE -- Now obsolete

// Interactive graphics now use the SDL or GL libraries.
// See for instance: bcplprogs/raspi/lander.b
// described in bcpl4raspi.pdf
*/

GET "libhdr"

STATIC {
craftsize=0;    w3=10
shape=0;        w4=9111
rotforce=0;     w6=50

/*  Perfect landing 1 slow
cgx=0;          w7  = 322855260
cgy=0;          w8  = 129712464
theta=0;        w9  = 3232
cgxdot=0;       w10 = -526837
cgydot=0;       w11 = -357
thetadot=0;     w12 = 32
*/

/*  Perfect landing 2 quicker
cgx=0;          w7  = 66691582
cgy=0;          w8  = 32153766
theta=0;        w9  = 0
cgxdot=0;       w10 = -286010
cgydot=0;       w11 =   13981
thetadot=0;     w12 = 64
*/

///*  Perfect landing 3 very quick
cgx=0;          w7  = 5396122
cgy=0;          w8  = 13314191
theta=0;        w9  = 0
cgxdot=0;       w10 = -182934 
cgydot=0;       w11 =    8679 
thetadot=0;     w12 = 100
//*/

/* Take off
cgx=0;          w7=-37000000
cgy=0;          w8=28001
theta=0;        w9=64*1000
cgxdot=0;       w10=0
cgydot=0;       w11=1
thetadot=0;     w12=-100
*/

fuel=0;         w13=1000000
thrust=0;       w14=450
dthrust=0;      w15=50
target=0;       w16=-37000000
scale=4
weight=0;       w23=300
mass=0;         w24=1
costheta=0
sintheta=0
flamelength=0
x0=0
y0=0
thrustmax=2000
thrustmin=100
single=FALSE
novice=FALSE
delay=1
offscreen=TRUE
ch=0
tracing=FALSE
}

MANIFEST { // Graphics interface
  gr_hide    = 3
  gr_show    = 4
  gr_cx      = 5
  gr_cy      = 6
  gr_bpr     = 7
  gr_display = 8
  gr_palette = 9

// The arguments of moveto and drawto have the following ranges
// x range is gr_xl to gr_xh
// y range is gr_yl to gr_yh
  gr_xl=0; gr_xh=2223; gr_xsize=gr_xh-gr_xl
//  gr_xl=0; gr_xh=8888; gr_xsize=gr_xh-gr_xl
  gr_yl=0; gr_yh=1024; gr_ysize=gr_yh-gr_yl
//  gr_yl=0; gr_yh=4000; gr_ysize=gr_yh-gr_yl
}

GLOBAL {
  prevx:400;   prevy;  prevdrawn
  cx;   cy;  colour
  bv;   bitmap
  bpr
}

LET start() = VALOF
{ LET count = 0

  writes("*nMoon Lander*n")
  
  sys(34, gr_show)        // Make the graphics window visible
  cx  := sys(34, gr_cx)   // Find its size (cx, cy)
  cy  := sys(34, gr_cy)
  bpr := sys(34, gr_bpr)  // and find the size of the pixel map
  bitmap := getvec(cx*bpr/4 + 3)  // alloc a private pixel map

//  writef("cx=%n cy=%n bpr=%n*n", cx, cy, bpr)
  UNLESS bitmap DO {
    writef("Unable to allocate bitmap*n")
    RESULTIS 20
  }

  bv := bitmap + 3
  bitmap!0 := cx
  bitmap!1 := cy
  bitmap!2 := bpr

  { LET v = VEC 63
    FOR j = 0 TO 63 DO v!j := #xFFFFFF
    v!0  := #x000000  // Black
    v!1  := #x0000FF  // Blue
    v!2  := #x00FF00  // Green
    v!3  := #x00FFFF  // Yellow
    v!4  := #xFF0000  // Red
    v!5  := #xFF00FF  // Majenta
    v!6  := #xFFFF00  // Cyan
    v!7  := #xFFFFFF  // White
    v!8  := #x404040  // Dark gray
    v!9  := #x000080  // Dark Blue
    v!10 := #x008000  // Dark Green
    v!11 := #x008080  // Dark Yellow
    v!12 := #x800000  // Dark Red
    v!13 := #x800080  // Dark Majenta
    v!14 := #x808000  // Dark Cyan
    v!15 := #x808080  // Gray

    sys(34, gr_palette, 64, v)
  }

  cls()
  display()

  lander() 

  closeGraphics()
  RESULTIS 0
}

AND lander() BE
{ reset()
  single := TRUE
  delay := 0

  UNTIL intflag() DO step()
}

AND closeGraphics() BE
{ cls()
  display()
  sys(34, gr_hide)
  freevec(bitmap)
}

AND setcolour(col) BE colour, prevdrawn := col, FALSE

AND smoveto(x, y) BE
  prevx, prevy, prevdrawn := x, y, FALSE

AND sdrawto(x, y) BE 
{ LET mx, my = ?, ?
  IF x<0 & prevx<0     |
     y<0 & prevy<0     |
     x>=cx & prevx>=cx |
     y>=cy & prevy>=cy DO { prevx, prevy, prevdrawn := x, y, FALSE
                            RETURN
                          }

  UNLESS prevdrawn DO spoint(prevx, prevy)
 
  mx := (x+prevx)/2
  my := (y+prevy)/2
  TEST (mx=prevx | mx=x) & (my=prevy | my=y)
  THEN spoint(x, y)
  ELSE { sdrawto(mx, my)
         sdrawto(x, y)
       } 
}

AND spoint(x, y) BE
{ prevdrawn := FALSE
  IF 0<=x<cx & 0<=y<cy DO
  { bv%(y*bpr+x) := colour
    prevdrawn := TRUE
  }
  prevx, prevy := x, y
}

// x range is gr_xl to gr_xh,  gr_xsize = gr_xh-gr_xl
// y range is gr_yl to gr_yh,  gr_ysize = gr_yh-gr_yl
AND moveto(x, y)   BE smoveto(muldiv(x-gr_xl,cx,gr_xsize),
                              muldiv(y-gr_yl,cy,gr_ysize))
AND drawto(x, y)   BE sdrawto(muldiv(x-gr_xl,cx,gr_xsize),
                              muldiv(y-gr_yl,cy,gr_ysize))
AND moveby(dx, dy) BE smoveto(prevx+muldiv(dx,cx,gr_xsize),
                              prevy+muldiv(dy,cy,gr_ysize))
AND drawby(dx, dy) BE sdrawto(prevx+muldiv(dx,cx,gr_xsize),
                              prevy+muldiv(dy,cy,gr_ysize))

AND point(x, y)    BE spoint (muldiv(x-gr_xl,cx,gr_xsize),
                              muldiv(y-gr_yl,cy,gr_ysize))
AND line(x, y)     BE { drawto(x, y)/*; display(); abort(999)*/ }

AND cls() BE
{ FOR i = 0 TO (cx*bpr)/4 DO bv!i := #x01010101  // all blue
  //display()
}

AND display(p) BE sys(34, gr_display, bitmap)


// End of graphics library


AND window() BE
{ LET s, x, y = 250, x0, y0
  LET h = height(cgx)
  AND relheight = ABS(cgy - h)
  UNTIL relheight < gr_ysize*s DO s := 3*s/2
  s := 3*s/2
//  IF tracing DO
//  { writef("rh=%n ys*s=%n*n", relheight, gr_ysize*s)
//    writef("scale=%n s=%n*n", scale, s)
//  }
  UNLESS s <= scale <= 3*s/2 DO scale := s
  IF scale<350 DO scale := 250
  // scale = no of units per pixel
  TEST scale<=2000 THEN craftsize := 20
                   ELSE craftsize := 10

  IF cgx-x0 <         500*scale DO x0 := cgx-(gr_xsize-800)*scale
  IF cgx-x0 > (gr_xh-500)*scale DO x0 := cgx + 800*scale

  UNLESS 150*scale < h-y0 < 300*scale  DO y0 := h - 270*scale
}

AND step() BE
{ // Read controls

  WHILE kbflag()=0 DO
  { LET ch = sys(10)
    newline()
    SWITCHON capitalch(ch) INTO
    { DEFAULT:  BREAK
      CASE '.': thetadot := thetadot-rotforce; ENDCASE
      CASE ',': thetadot := thetadot+rotforce; ENDCASE
      CASE 'Z': thrust   := thrust - dthrust;  ENDCASE
      CASE 'X': thrust   := thrust + dthrust;  ENDCASE

      CASE 'T': tracing := ~tracing;           ENDCASE
      CASE 'S': rdcontrols();                  BREAK
    }
  }

  theta := theta + thetadot
  IF novice DO theta, thetadot := theta+15*thetadot, 0

  costheta := cosine(theta)
  sintheta := sine(theta)

  IF thrust > thrustmax DO thrust := thrustmax
  IF thrust < thrustmin DO thrust := thrustmin
  IF fuel>0 DO { fuel := fuel - thrust
                 IF fuel<0 DO fuel := 0
               }
  IF fuel<=0 DO thrust := 0
  flamelength := thrust*300/thrustmax
  cgxdot := cgxdot + (thrust*costheta/1000         )/mass
  cgydot := cgydot + (thrust*sintheta/1000 - weight)/mass
  cgx := cgx + cgxdot
  cgy := cgy + cgydot

  displayall()

  IF tracing DO
  { writef("*nxydot= %n, %n*n", cgxdot, cgydot)
    writef("t,tdot = %n, %n*n", theta, thetadot)
    writef("xy= %n, %n*n", cgx, cgy)
    writef("h = %n*n", height(cgx))
//    writef("x0y0= %n, %n*n", x0, y0)
//    writef("scale = %n*n", scale)
  }

  IF cgy <= height(cgx)+16000 DO
  { LET good = TRUE
    thrust := 0
    displayall()
    writes("*nLanded*n")
    writef("xdot = %n  ydot = %n*n", cgxdot, cgydot)
    UNLESS 0 < cgxdot*cgxdot+cgydot*cgydot < 2000000 DO
    { good := FALSE
      writef("Too fast*n")
    }
    UNLESS ABS(height(cgx-30000) - height(cgx)) +
           ABS(height(cgx+30000) - height(cgx)) < 1000 DO
    { good := FALSE
      writef("Bad landing site*n")
    }
    UNLESS sintheta>950 DO
    { good := FALSE
      writes("Bad orientation*n")
    }
    IF good DO writes("Perfect, Well done!!*n")
    WHILE kbflag()=0 DO sys(10)
    writes("*nPress any key*n")
    sys(10)
    newline()
    reset()
  }
}

AND height(x) = VALOF
{ IF -100000 < x-target < 100000 DO x := target

  x := x/8000

  { LET ra, rb, rc = x&#777, x&#77, x&#7
    LET a, b, c = x-ra, x-rb, x-rc
    LET h = (hf(a)*(#777-ra) + hf(a+#1000)*ra +
             hf(b)*(#77 -rb) + hf(b+#100) *rb +
             hf(c)*(#7  -rc) + hf(c+#10)  *rc)/512
    h := h*h/100
    IF (hf(x&-2)&#71)=0 DO h := h+4
    RESULTIS h*6*1000
  }
}

AND hf(n) = VALOF
{ LET a = n NEQV shape
  LET b = a*(a NEQV #4132)/100 + a
  RESULTIS (b*b/313*a) & 255
}

AND cline(x, y) BE
{ LET tx = x * craftsize / 16
  AND ty = y * craftsize / 16
//writef("cline: %n,%n ", x, y)
  x := (+tx*sintheta + ty*costheta)/1000 + (cgx-x0)/scale
  y := (-tx*costheta + ty*sintheta)/1000 + (cgy-y0)/scale
//writef(" %n,%n*n", x, y)
  line(x, y)
}

AND cpoint(x, y) BE
{ LET tx = x * craftsize / 16
  AND ty = y * craftsize / 16
  x := (+tx*sintheta + ty*costheta)/1000 + (cgx-x0)/scale
  y := (-tx*costheta + ty*sintheta)/1000 + (cgy-y0)/scale
  point(x, y)
}

AND plotcraft() BE
{ setcolour(4)
  cpoint( -30, -20)
  cline (  30, -20)
  cline (  30,   0)
  cline ( -30,   0)
  cline ( -30, -20)
  cpoint(  10,   0)
  cline (  20,  10)
  cline (  20,  30)
  cline (  10,  40)
  cline ( -10,  40)
  cline ( -20,  30)
  cline ( -20,  10)
  cline ( -10,   0)
  cpoint( -30, -10)
  cline ( -50, -30)
  cpoint( -60, -30)
  cline ( -40, -30)
  cpoint(  30, -10)
  cline (  50, -30)
  cpoint(  40, -30)
  cline (  60, -30)

  setcolour(6)
  IF thrust DO
  { cpoint(  0, -30)
    cline ( -20, -flamelength-30)
    cline (   0, -flamelength/2-30)
    cline (  20, -flamelength-30)
    cline (   0, -30)
  }
}

AND plotmoon() BE
{ setcolour(6)
  point(gr_xl, (height(x0)-y0)/scale)
  FOR x = gr_xl TO gr_xh BY gr_xsize/128 DO
    line(x, (height(x0+scale*x)-y0)/scale)

  setcolour(3)
  point((cgx-30000-x0)/scale, (cgy-16000-y0)/scale)
  line ((cgx+30000-x0)/scale, (cgy-16000-y0)/scale)
}

AND displayall() BE
{ MANIFEST { xm = (gr_xl+gr_xh)/2
             targy = gr_yh - 100
             fuely = gr_yh - 30
             fuelxl = xm - 100
             fuelxh = xm + 100
           }
  LET fuelx = fuelxl + muldiv(200, fuel, w13)
  LET targx = xm + (target-cgx)/100000
  LET tdotx = xm - thetadot/8
  LET tdoty = fuely-20
  LET flx0, fly0 = xm, fuely-200
  LET flxs, flys = flamelength*costheta/1000, flamelength*sintheta/1000

  window()
  cls()
  setcolour(6)        // Fuel
  point(fuelxl, fuely)
  drawby(200, 0)
  point(fuelx, fuely)
  drawby(0, 20)

  point(targx-10, targy)  // Target
  drawby(20, 0)

  point(xm, fuely)
  drawby(0, -20)
  point(tdotx, tdoty) // Thetadot
  drawby(0, -20)

  setcolour(2)        // Acceleration
  point(flx0, fly0)
  drawby(flxs, flys)

  setcolour(4)       // Velocity
  point(flx0, fly0)
  drawby(cgxdot/400, cgydot/400)

  point(flx0, fly0)
  moveby(cgxdot/40, cgydot/40)
  drawby(0, 20)

  plotcraft()
  plotmoon()
  display()
}

AND rdjoystick() = 0

AND kbflag() = VALOF
{ LET f = sys(35)
  RESULTIS f
}

AND set(s, p) BE
{ writef(" %s = %n  ", s, !p)
  ch := sys(10)
  IF ch='=' DO { !p := rdn(); reset() }
  newline()
}

AND reset() BE
{ craftsize := w3
  shape     := w4
  rotforce  := w6
  cgx       := w7
  cgy       := w8
  theta     := w9
  cgxdot    := w10
  cgydot    := w11
  thetadot  := w12
  fuel      := w13
  thrust    := w14
  dthrust   := w15
  target    := w16
  weight    := w23
  mass      := w24
}

AND rdcontrols() BE
{ writef("*n# ", ch)
  ch := capitalch(sys(10))
  
  SWITCHON ch INTO
  { DEFAULT:  ENDCASE

    // Options
    CASE 'I': reset();               ENDCASE
    CASE 'A': set("dthrust",  @w15); ENDCASE
    CASE 'H': set("shape",     @w4); ENDCASE
    CASE 'T': set("target",   @w16); ENDCASE
    CASE 'C': set("craftsize", @w3); ENDCASE
    CASE 'R': set("rotforce",  @w6); ENDCASE
    CASE 'S': single := ~single;     ENDCASE
    CASE 'N': novice := ~novice;     ENDCASE
    CASE 'Q': delay  := rdn();       ENDCASE
    CASE 'M': set("mass",     @w24); ENDCASE
    CASE 'E': set("weight",   @w23); ENDCASE
    CASE 'P': set("thrust",   @w14); ENDCASE
    CASE 'U': set("cgxdot",   @w10); ENDCASE
    CASE 'V': set("cgydot",   @w11); ENDCASE
    CASE 'W': set("thetadot", @w12); ENDCASE
    CASE 'X': set("cgx",       @w7); ENDCASE
    CASE 'Y': set("cgy",       @w8); ENDCASE
    CASE 'Z': set("theta",     @w9); ENDCASE
    CASE '?': writef("xdot=%i5 ydot=%i5*n", cgxdot, cgydot)
              writef("theta = %i5  thetadot = %i5*n",
                      theta,       thetadot)
              writef("cgx=%i5 cgy=%i5*n", cgy, cgy)
              writef("height=%i5*n", height(cgx))
              ENDCASE
    CASE '*n': newline();            RETURN
    CASE '*s': ENDCASE
  }

  reset()
  costheta := cosine(theta)
  sintheta := sine(theta)
  window()
  displayall()
} REPEAT

AND rdn() = VALOF
{ LET res = 0
  ch := sys(10)
  WHILE '0'<=ch<='9' DO { res := 10*res + ch - '0'
                          ch := sys(10)
                        }
  RESULTIS res
}

AND sine(theta) = VALOF
// theta =     0 for 0 degrees
//       = 64000 for 90 degrees
// Returns a value in range -1000 to 1000
{ LET a = theta / 1000
  LET r = theta REM 1000
  LET s = rawsine(a)
  RESULTIS s + (rawsine(a+1)-s)*r/1000
}

AND cosine(x) = sine(x+64000)

AND rawsine(x) = VALOF
{ LET t = TABLE   0,   25,   49,   74,   98,  122,  147,  171,
                195,  219,  243,  267,  290,  314,  337,  360,
                383,  405,  428,  450,  471,  493,  514,  535,
                556,  576,  596,  615,  634,  653,  672,  690,
                707,  724,  741,  757,  773,  788,  803,  818,
                831,  845,  858,  870,  882,  893,  904,  914,
                924,  933,  942,  950,  957,  964,  970,  976,
                981,  985,  989,  992,  995,  997,  999, 1000,
               1000

  LET a = x&63
  UNLESS (x&64)=0  DO a := 64-a
  a := t!a
  UNLESS (x&128)=0 DO a := -a
  RESULTIS a
}
