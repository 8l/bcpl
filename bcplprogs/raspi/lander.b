/* 
############### UNDER DEVELOPMENT #####################

   This is a re-inplementation of a moon lander program
   I originally wrote in BCPL in September 1973 for the PDP-7
   and the Vector General display.

   This implementation is a modification of a version of moon lander
   for the handheld HP 620LX machine running Windows CE. It now uses
   the SDL graphics library and runs under Linux, the Raspberry Pi and
   Windows (in due course).

   (c) Martin Richards   Sep 2012

****** UNDER DEVELOPMENT *******************
*/

GET "libhdr"
GET "sdl.h"
GET "sdl.b"                 // Insert the library source code
.
GET "libhdr"
GET "sdl.h"

MANIFEST {
  fuelmax=4000000
}

STATIC {
shape=9111
rotforce=0//50

///*  Perfect landing
cgx= 322_855_260 // in millimetres
cgy= 129_712_464 -16000 +3000
theta= 3232
cgxdot=-526_837    // in millimetres per second
cgydot=  -0_357
thetadot= 32
//*/


/* Take off
cgx=-37000000
cgy=28001
theta=64*1000
cgxdot=0
cgydot=1
thetadot=-32
*/

minscale = 400

fuel=fuelmax
thrust=450
dthrust=50
target=-37000000
halftargetsize=30_000 // in millimetres
scale=4
weight=300
mass=1
moonradius = 8000*#x1000 * 7 / 22 // circumference/pi
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

GLOBAL {
  done:ug
  rotleft
  rotright

  landed      // Quality of the landing
  toofast     // Quality of the landing
  badsite
  badorientation
  goodlanding
  stepping

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
{ LET mes = VEC 256/bytesperword

  writes("*nMoon Lander*n")

  initsdl()

  mkscreen("Moon Lander", 640, 480)

  rotleft, rotright := FALSE, TRUE

  startlander(format)

  //Update screen
  updatescreen()

  //Pause for 10 secs
  sdldelay(10_000);

  //Quit SDL
  closesdl()

  writef("Done!*n")

  RESULTIS 0
}


AND startlander(fmt) = VALOF
{ LET count = 0

  // Declare a few colours in the pixel format of the screen
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
  col_darkred     := maprgb( 64,   0,   0)
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

  IF FALSE DO
  { LET days, msecs, flag = ?, ?, ?
    datstamp(@days)
    // Draw some random coloured lines rapidly
    setcolour(col_blue)
    drawpoint(screenxsize/2, screenysize/2)
    FOR i = 1 TO 100_000 DO
    { LET col = maprgb(randno(255),randno(255),randno(255))
      LET x, y = randno(screenxsize)-1, randno(screenysize)-1
      IF i=10 DO setcaption("Hello World Again")
      setcolour(col)
      drawto(x, y)
      updatescreen()
      //sdldelay(100)
      IF i MOD 100 = 99 DO
      { LET d, m, f = ?, ?, ?
        datstamp(@d)
        writef("%8.3d frames per second*n", 100000_000/(m-msecs))
        days, msecs, flag := d, m, f
      }
    }
    RESULTIS 0
  }

  lander() 
  RESULTIS 0
}

AND lander() BE
{ single := TRUE
  delay := 0
  landed := FALSE
  stepping := TRUE

  done := FALSE
  UNTIL done DO
  { readcontrols()
    IF stepping DO step()
    sdldelay(100)
  }

  WHILE sys(Sys_pollsardch)=pollingch LOOP
  writes("*nPress any key*n")
  sys(Sys_sardch)
  newline()
}

AND setwindow() BE
{ // Set the position and scale of the window to display
  // ie set x0, y0 and scale.
  LET x, y = x0, y0
  LET h = height(cgx)
  LET relheight = ABS(cgy-h)

  // Choose scale so that relheight appears no larger that half screenysize
  LET s = relheight*2/screenysize
  scale := minscale
  UNTIL scale > s DO scale := scale*2

  // Adjust y so that the moon's surface is suitably places 
  UNLESS screenysize*2/10 < (h-y)/scale < screenysize*4/10 DO
    y := h - (screenysize*3/10)*scale

  UNLESS screenysize/ 8 <  (h-y0)/scale  < screenysize/3 &
         screenysize/10 < (cgy-y0)/scale < screenysize*9/10 DO y0 := y

  IF screenxsize/4   > (cgx-x0)/scale DO x0 := cgx - (screenxsize*3/5)*scale
  IF screenxsize*3/4 < (cgx-x0)/scale DO x0 := cgx - (screenxsize*2/5)*scale

  IF tracing DO
  { writef("cgx=%n cgy=%n h=%n scale=%n x=%n y=%n*n",
            cgx, cgy, h, scale, (cgx-x0)/scale, (cgy-y0)/scale)
    writef("screenxsize=%n screenysize=%n*n", screenxsize, screenysize)
  }
}

AND readcontrols() BE
{ WHILE getevent(@eventtype) SWITCHON eventtype INTO
  { DEFAULT:
      writef("Unknown event type = %n*n", eventtype)
      LOOP

    CASE sdle_active:           // => 1
      //writef("active %d %d*n", eventa1, eventa2)
      LOOP

    CASE sdle_keydown:          // => 2 mod ch 
      SWITCHON capitalch(eventa2) INTO
      { DEFAULT:  LOOP
        CASE '.': rotforce := rotforce - 1
                  IF rotforce<-1 DO rotforce := -1
                  LOOP
        CASE ',': rotforce := rotforce + 1
                  IF rotforce>1 DO rotforce := 1
                  LOOP
        CASE 'Z': thrust   := thrust - dthrust;  LOOP
        CASE 'X': thrust   := thrust + dthrust;  LOOP
        CASE 'T': tracing := ~tracing;           LOOP
        CASE 'P': stepping := ~stepping          LOOP
        CASE 'Q': done := TRUE;                  LOOP
      }
      LOOP

    CASE sdle_keyup:            // => 3 mod ch 
      //writef("keyup %d %d*n", eventa1, eventa2)
      LOOP

    CASE sdle_mousemotion:      // 4
      //writef("mousemotion %n %n %n*n", eventa1, eventa2, eventa3)
      LOOP

    CASE sdle_mousebuttondown:  // 5
      //writef("mousebuttondown*n", eventa1, eventa2, eventa3)
      LOOP

    CASE sdle_mousebuttonup:    // 6
      //writef("mousebuttonup*n", eventa1, eventa2, eventa3)
      LOOP

    CASE sdle_joyaxismotion:    // 7
    { LET which = eventa1
      LET axis  = eventa2
      LET value = eventa3
      //writef("joyaxismotion %n %n %n*n", eventa1, eventa2, eventa3)

      SWITCHON axis INTO
      { DEFAULT:
          LOOP

        CASE 0: // Aileron
          rotforce := 0
          IF value > 0 DO rotforce := -1
          IF value < 0 DO rotforce := +1
          LOOP

        CASE 1: // Elevator
          LOOP

        CASE 2: // Throttle
          thrust := thrustmax - muldiv(thrustmax-thrustmin, value+32769, 32768+32767)
          LOOP
      }
    }

    CASE sdle_joyballmotion:    // 8
      //writef("joyballmotion*n", eventa1, eventa2, eventa3)
      LOOP

    CASE sdle_joyhatmotion:     // 9
      //writef("joyhatmotion*n", eventa1, eventa2, eventa3)
      LOOP

    CASE sdle_joybuttondown:    // 10
      //writef("joybuttondown*n", eventa1, eventa2, eventa3)
      LOOP

    CASE sdle_joybuttonup:      // 11
      //writef("joybuttonup*n", eventa1, eventa2, eventa3)
      LOOP

    CASE sdle_quit:             // 12
      writef("QUIT*n");
      LOOP

    CASE sdle_syswmevent:       // 13
      //writef("syswmevent*n", eventa1, eventa2, eventa3)
      LOOP

    CASE sdle_videoresize:      // 14
      //writef("videoresize*n", eventa1, eventa2, eventa3)
      LOOP

    CASE sdle_userevent:        // 15
      //writef("userevent*n", eventa1, eventa2, eventa3)
      LOOP
  }
}

AND step() BE
{ thetadot := thetadot + 20*rotforce

  theta := theta + thetadot
  IF novice DO theta, thetadot := theta+15*thetadot, 0

  costheta := cosine(theta)  // scaled d.ddd
  sintheta := sine(theta)

  IF thrust > thrustmax DO thrust := thrustmax
  IF thrust < thrustmin DO thrust := thrustmin
  IF fuel>0 DO { fuel := fuel - thrust
                 IF fuel<0 DO fuel := 0
               }
  IF fuel<=0 DO thrust := 0
  flamelength := thrust*30000/thrustmax
  cgxdot := cgxdot + (thrust*costheta/1000         )/mass
  cgydot := cgydot + (thrust*sintheta/1000 - weight)/mass
  // Add the effect of centrifugal force.
  // This should allow the lander to remain in orbit, if cgxdot large enough.
  ///cgydot := cgydot + muldiv(cgxdot, cgxdot, cgy+moonradius)

  cgx := cgx + cgxdot
  cgy := cgy + cgydot

  //writef("x=%n, y=%n*n", cgx, cgy)

  IF tracing DO
  { writef("*nxydot= %n, %n*n", cgxdot, cgydot)
    writef("t,tdot = %n, %n*n", theta, thetadot)
    writef("x=%n, y=%n*n", cgx, cgy)
    writef("h = %n*n", height(cgx))
//    writef("x0y0= %n, %n*n", x0, y0)
//    writef("scale = %n*n", scale)
  }

  // The CG of the lander is 3 metre above the feet.
  IF cgy <= height(cgx)+3_000 DO
  { toofast := FALSE
    badsite := FALSE
    badorientation := FALSE
    goodlanding := TRUE
    landed, thrust := TRUE, 0
    stepping := FALSE
    writes("*nLanded*n")
    writef("xdot = %7.3d  ydot = %7.3d*n", cgxdot, cgydot)
    UNLESS 0 < cgxdot*cgxdot+cgydot*cgydot < 1_500*1_500 DO
    { goodlanding := FALSE // Speed greater than 1.5 metre per second
      toofast := TRUE
      writef("Too fast*n")
    }
    // The craft width is 12 metres
    UNLESS ABS(height(cgx-6_000) - height(cgx)) +
           ABS(height(cgx+6_000) - height(cgx)) < 1000 DO
    { // Not level enough
      goodlanding := FALSE
      badsite := TRUE
      writef("Bad landing site*n")
    }
    UNLESS sintheta>950 DO
    { // Bad orientation
      goodlanding := FALSE
      badorientation := TRUE
      writes("Bad orientation*n")
    }
    IF goodlanding DO writes("Perfect, Well done!!*n")
  }

  displayall()
}

AND height(x) = VALOF
{ IF -halftargetsize < x-target < halftargetsize DO x := target

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
{ LET a = n XOR shape
  LET b = a*(a XOR #4132)/100 + a
  RESULTIS (b*b/313*a) & 255
}

AND cdrawto(x, y) BE
{ LET tx = x / minscale
  AND ty = y / minscale
//writef("cdrawto: %n,%n ", x, y)
  x := (+tx*sintheta + ty*costheta)/1000 + (cgx-x0)/scale
  y := (-tx*costheta + ty*sintheta)/1000 + (cgy-y0)/scale
//writef(" %n,%n*n", x, y)
  drawto(x, y)
}

AND cpoint(x, y) BE
{ LET tx = x / minscale
  AND ty = y / minscale
  x := (+tx*sintheta + ty*costheta)/1000 + (cgx-x0)/scale
  y := (-tx*costheta + ty*sintheta)/1000 + (cgy-y0)/scale
  drawpoint(x, y)
}

AND plotcraft() BE
{ setcolour(col_white)

  // The units are millimetres
  // The craft width is 12 metres (-6 to +6)
  cpoint( -3000, -2000) // The base
  cdrawto (  3000, -2000)
  cdrawto (  3000,     0)
  cdrawto ( -3000,     0)
  cdrawto ( -3000, -2000)

  cpoint(  1000,     0) // The return module
  cdrawto (  2000,  1000)
  cdrawto (  2000,  3000)
  cdrawto (  1000,  4000)
  cdrawto ( -1000,  4000)
  cdrawto ( -2000,  3000)
  cdrawto ( -2000,  1000)
  cdrawto ( -1000,     0)

  cpoint( -3000, -1000) // Lhe legs
  cdrawto ( -5000, -3000)
  cpoint( -6000, -3000)
  cdrawto ( -4000, -3000)
  cpoint(  3000, -1000)
  cdrawto (  5000, -3000)
  cpoint(  4000, -3000)
  cdrawto (  6000, -3000)

  setcolour(col_cyan)
  IF thrust DO
  { cpoint(    0, -3000) // The flame
    cdrawto ( -2000, -flamelength-3000)
    cdrawto (     0, -flamelength/2-3000)
    cdrawto (  2000, -flamelength-3000)
    cdrawto (     0, -3000)
  }



  IF thrust DO
  { IF rotforce>0 DO
    { setcolour(col_yellow)
      cpoint(-3000,    0) // Rotate left jets
      cdrawto( -3500, 2000)
      cdrawto( -2500, 2000)
      cdrawto( -3000,    0)
      cpoint( 3000,-2000)
      cdrawto(  2500,-4000)
      cdrawto(  3500,-4000)
      cdrawto(  3000,-2000)
    }

    IF rotforce<0 DO
    { setcolour(col_yellow)
      cpoint( 3000,    0) // Rotate right jets
      cdrawto(  3500, 2000)
      cdrawto(  2500, 2000)
      cdrawto(  3000,    0)
      cpoint(-3000,-2000)
      cdrawto( -2500,-4000)
      cdrawto( -3500,-4000)
      cdrawto( -3000,-2000)
    }
  }


}

AND plotmoon() BE
{ LET x, dx = 0, 4//screenxsize/128

  setcolour(col_lightblue)

  drawpoint(x, (height(x0)-y0)/scale)
  WHILE x<screenxsize DO
  { x := x+dx
    drawto(x, (height(x0+scale*x)-y0)/scale)
  }

  setcolour(col_lightmajenta)
  drawpoint((target-halftargetsize-x0)/scale, (height(target)-y0)/scale)
  drawto   ((target+halftargetsize-x0)/scale, (height(target)-y0)/scale)
}

AND displayall() BE
{ LET xm = screenxsize/2
  LET targy = screenysize - 60
  LET fuely = screenysize - 30
  LET fuelxl = xm - 100
  LET fuelxh = xm + 100
  LET fuelx = fuelxl + muldiv(200, fuel, fuelmax)
  LET targx = xm + (target-cgx)/100000
  LET targx1 = xm + (target-cgx)/1000000
  LET tdotx = xm - thetadot/8
  LET tdoty = fuely-15
  LET flx0, fly0 = xm, fuely-100
  LET flxs, flys = flamelength*costheta/1000, flamelength*sintheta/1000

  fillsurf(col_darkgray)
  setwindow()

  setcolour(col_cyan)         // Fuel
  drawpoint(fuelxl, fuely)
  drawby(200, 0)
  setcolour(col_red)
  drawpoint(fuelx, fuely)
  drawby(0, 20)

  setcolour(col_lightmajenta) // Target
  drawpoint(targx-10, targy)
  drawby(20, 0)
  drawpoint(targx1-5, targy-2)
  drawby(5, 0)

  setcolour(col_cyan)         // Thetadot
  drawpoint(xm, fuely)
  drawby(0, -15)
  setcolour(col_red)
  drawpoint(tdotx, tdoty)
  drawby(0, -15)

  setcolour(col_lightgreen)      // Acceleration
  drawpoint(flx0, fly0)
  drawby(flxs/200, flys/200)

  setcolour(col_red)             // Velocity
  drawpoint(flx0, fly0)
  drawby(cgxdot/10_000, cgydot/10_000)

  { LET x = flx0+cgxdot/200-1
    LET y = fly0+cgydot/200-1
    drawfillrect(x, y, x+3, y+3) // Velocity/200
  }

  setcolour(col_white)
  plotf(10, 75, "target %11.3d", target-cgx)
  plotf(10, 60, "cgx=   %11.3d xdot=%9.3d", cgx, cgxdot)
  plotf(10, 45, "cgy=   %11.3d ydot=%9.3d", cgy, cgydot)
  plotf(10, 30, "fuel=  %11.3d", fuel)
  //plotf(10, 15, "scale= %11.3d", scale)

  IF landed DO
  { LET x = screenxsize/2
    LET y = screenysize/2
    plotf(x, y, "Landed") 
    IF toofast        DO { y := y-15; plotf(x, y, "Too fast") }
    IF badsite        DO { y := y-15; plotf(x, y, "Bad site") }
    IF badorientation DO { y := y-15; plotf(x, y, "Bad orientation") }
    IF goodlanding    DO { y := y-15; plotf(x, y, "Perfect landing -- well done!") }
  }

  plotmoon()
  plotcraft()

ret1:
  updatescreen()
}

AND rdjoystick() = 0

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

AND cosine(x) = sine(x+64_000)

AND rawsine(x) = VALOF
{ // x is scaled d.ddd with 64.000 representing 90 degrees
  // The result is scalled d.ddd, ie 1000 represents 1.000
  LET t = TABLE   0,   25,   49,   74,   98,  122,  147,  171,
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
