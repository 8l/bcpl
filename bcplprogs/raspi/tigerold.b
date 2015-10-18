/*
########### THIS IS UNDER DEVELOPMENT ###############################

This is a flight simulator based on Jumbo that ran interactively on a
PDP 11 generating the pilots view on a Vector General Display.

Originally implemented by Martin Richards in mid 1970s.

Substantially modified my Martin Richards (c) October 2012.

It has been extended to use 32 rather than 16 bit arithmetic.

It is planned that this will simulate the flying characterists of
a De Havilland D.H.82A Tiger Moth which I learnt to fly as a teenager.


Change history

25/01/2013
Name changed to tiger.b

Controls

Either use a USB Joystick for elevator, ailerons and throttle, or
use the keyboard as follows:

Up arrow      Trim joystick forward a bit
Down arrow    Trim joystick backward a bit
Left arrow    Trim joystick left a bit
Right arrow   Trim joystick right a bit

, or <        Trim rudder left
. or >        Trim rudder right
x             Trim more thrust
z             Trim less thrust

0             Display the pilot's view
1,2,3,4,5,6,7,8 Display the aircraft viewed from various angles

f             View aircraft from a greater distance
n             View aircraft from a closer position

p             pause/unpause the simulation

g             Reset the aircraft on the glide path
t             Reset the aircraft ready for take off -- default
              ie stationary on the ground at the end of the runway

b             brake on/off -- not available
u             undercarriage up/down -- not available

q             Quit

There are joystick buttons equivalent to Up arrow, Down arrow, Left
Arrow and Right arrow. There are also joystick buttons to trim the
rudder left and right, useful for streering on the runway. There are
also joystick buttons to toggle gear up/down and brakes on/off.

The display shows various beacons on the ground including the lights
on the sides and the ends of the runway.

The display also shows various flight instruments including the
artificial horizon, the height and speed and various navigational aids
to help the pilot find the runway.

*/

GET "libhdr"
GET "sdl.h"
GET "sdl.b"
.
GET "libhdr"
GET "sdl.h"

MANIFEST {
  One = 1_000000     // Direction cosines scaling factor
                     // ie 6 decimal digits after the decimal point.
  D45 = 0_707107     // cosine of pi/4
  Sps = 10           // Steps per second

  // Most measurements are in feet scaled with 3 digits after the decimal point
  k_g = 32_000       // Acceleration due to gravity, 32 ft per sec per sec
                     // Scaled with 3 digits after the decimal point.
  k_drag = k_g/15    // Acceleration due to drag as 100 ft per sec
                     // The drag is proportional to the square of the speed.

  // Conversion factors
  mph2fps   = 5280_000/(60*60)
  mph2knots = 128_000/147
}

GLOBAL {
  done:ug

  aircraft      // Select which aircraft to simulate

  stepping     // =FALSE if not stepping the simulation
  crashed      // =TRUE if crashed
  debugging
  plotusage
  done

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

  c_thrust;   c_trimthrust
  c_aileron;  c_trimaileron
  c_elevator; c_trimelevator
  c_rudder;   c_trimrudder

  c_geardown // TRUE or FALSE
  c_brakeson // TRUE or FALSE

  ctx; cty; ctz   // Direction cosines of direction t
  cwx; cwy; cwz   // Direction cosines of direction w
  clx; cly; clz   // Direction cosines of direction l

  cetx; cety; cetz // Eye direction cosines of direction t
  cewx; cewy; cewz // Eye direction cosines of direction w
  celx; cely; celz // Eye direction cosines of direction l

  cockpitz        // Height of the pilots eye

  cgx; cgy; cgz   // Coordinates of the CG of the aircraft
                  // in feet with 3 digits after the decimal point
                  // eg cgz=1000_000 represents a height of 1000 ft

  eyex; eyey; eyez // Relative position of the eye
  eyedist          // Eye x or y distance from aircraft

  hatdir           // Hat direction
  hatmsecs         // msecs of last hat change
  eyedir           // Eye direction
                   // 0 = cockpit view
                   // 1,...,8 view from behind, behind-left, etc

  cdrawtriangle3d
  cdrawquad3d

  // Speed in various directions is measured in ft/s scaled
  // with 3 digits after the decimal point
  // eg 146_666 represents 146.666 ft/s = 100 mph
  tdot; wdot; ldot // Speed in t, w and l directions
  tdotsq; wdotsq; ldotsq // Speed squared in t, w and l directions

  mass          // Mass of the aircraft

  mit; miw; mil // Moment of inertia about t, w and l axes

  rtdot; rwdot; rldot // Rotation rates about t, w and l axes
  rdt;   rdw;   rdl   // Rotational damping about t, w and l axes

  //Linear forces are scaled with 3 digits after the decimal point
  ft; ft1       // Force and previous force in t direction
  fw; fw1       // Force and previous force in w direction
  fl; fl1       // Force and previous force in l direction

  // Rotational forces are scaled with 6 digits after the decimal point
  // as are direction cosines.
  rft; rft1     // Current and previous moment about t axis
  rfw; rfw1     // Current and previous moment about w axis
  rfl; rfl1     // Current and previous moment about l axis

  atl; atw; awl // Angle of air flow in planes tl, tw and wl

  // Table interpolated by rdtab(angle, tab)
  rtltab; rtwtab; rwltab  // Rotational tables
  tltab;  twtab;  wltab   // Linear tables

  usage         // 0 to 100 percentage cpu usage
}

// Insert the definition of drawtigermoth()
GET "drawtigermoth.b"

LET inprod(a,b,c, x,y,z) =
  // Return the cosine of the angle between two unit vectors.
  muldiv(a, x, One) + muldiv(b, y, One) + muldiv(c, z, One)

AND rotate(t, w, l) BE
{ // Rotate the orientation of the aircraft
  // t, w and l are assumed to be small and cause
  // rotation about axis t, w, l. Positive values cause
  // anti-clockwise rotations about their axes.

  LET tx = inprod(One, -l,  w, ctx,cwx,clx)
  LET wx = inprod(  l,One, -t, ctx,cwx,clx)
  LET lx = inprod( -w,  t,One, ctx,cwx,clx)

  LET ty = inprod(One, -l,  w, cty,cwy,cly)
  LET wy = inprod(  l,One, -t, cty,cwy,cly)
  LET ly = inprod( -w,  t,One, cty,cwy,cly)

  LET tz = inprod(One, -l,  w, ctz,cwz,clz)
  LET wz = inprod(  l,One, -t, ctz,cwz,clz)
  LET lz = inprod( -w,  t,One, ctz,cwz,clz)

  ctx, cty, ctz := tx, ty, tz
  cwx, cwy, cwz := wx, wy, wz
  clx, cly, clz := lx, ly, lz

  adjustlength(@ctx);      adjustlength(@cwx);      adjustlength(@clx) 
  adjustortho(@ctx, @cwx); adjustortho(@ctx, @clx); adjustortho(@cwx, @clx)
}

AND adjustlength(v) BE
{ // This helps to keep vector v of unit length
  LET x, y, z = v!0, v!1, v!2
  LET corr = One + (inprod(x,y,z, x,y,z) - One)/2
  v!0 := muldiv(x, One, corr)
  v!1 := muldiv(y, One, corr)
  v!2 := muldiv(z, One, corr)
}

AND adjustortho(a, b) BE
{ // This helps to keep the unit vector b orthogonal to a
  LET a0, a1, a2 = a!0, a!1, a!2
  LET b0, b1, b2 = b!0, b!1, b!2
  LET corr = inprod(a0,a1,a2, b0,b1,b2)
  b!0 := b0 - muldiv(a0, corr, One)
  b!1 := b1 - muldiv(a1, corr, One)
  b!2 := b2 - muldiv(a2, corr, One)
}

AND rdtab(a, tab) = VALOF
{ // Perform linear interpolation between appropriate entries
  // in the given table. The first and last entries must be for
  // angles -180.000 and +180.000, repectively.
  // The angle a is scaled with three digits after the decimal point.
  LET p = tab
  LET a0, r0, a1, r1 = ?, ?, ?, ?
  IF a<-180_000 DO a := -180_000
  IF a>+180_000 DO a := +180_000
  WHILE a>!p DO p := p+2
  IF a=!p RESULTIS p!1
  a0, r0 := p!-2, p!-1
  a1, r1 := p! 0, p! 1
  RESULTIS r0 + muldiv(r1-r0, a-a0, a1-a0)
}

AND angle(x, y) = x=0 & y=0 -> 0, VALOF
{ // Calculate an approximation to the angle in degrees between
  // point (x,y) and the x axis. The result is a scaled number with
  // three digits after the decimal point.
  // Points above the x axis have positive angles and
  // points below the x axis have negative angles.
  LET px, py = ABS x, ABS y
  LET t = muldiv(90_000, y, px+py)
  IF x>=0 RESULTIS t
  IF y>=0 RESULTIS 180_000 - t
  RESULTIS -(180_000 + t)
}

LET step() BE
{ // Update the aircraft position, orientation and motion.

  LET cgxdot, cgydot, cgzdot = ?, ?, ?

  // Calculate the linear and rotational forces on the aircraft
  // In directions t, w and l
  ft,  fw,  fl  := 0, 0, 0 // Initialise all to zero
  rft, rfw, rfl := 0, 0, 0

  // Air flow angles
  atl := angle(tdot, ldot)
  atw := angle(tdot, wdot)
  awl := angle(wdot, ldot)

  // Calculate speed squared in the three direction
  // scaled so that 100 ft/s squared gives 1.000 scaled
  // with 3 digits after the decimal point.
  tdotsq := muldiv(tdot, tdot, 10_000_000)
  wdotsq := muldiv(wdot, wdot, 10_000_000)
  ldotsq := muldiv(ldot, ldot, 10_000_000)

//writef("tdot=%8.3d ldot=%8.3d atl=%7.3d*n", tdot, ldot, atl)
//writef("tdot=%8.3d wdot=%8.3d atw=%7.3d*n", tdot, wdot, atw)
//writef("wdot=%8.3d ldot=%8.3d awl=%7.3d*n", wdot, ldot, awl)

//writef("tdotsq=%8.3d wdotsq=%8.3d ldotsq=%8.3d*n", tdotsq, wdotsq, ldotsq)

  // Rotational damping
  // rtdot, rwdot and rldot are in radians per second.
  rtdot := muldiv(rtdot, rdt, 1_000*Sps)
  rwdot := muldiv(rwdot, rdw, 1_000*Sps)
  rldot := muldiv(rldot, rdl, 1_000*Sps)

  // Rotational aerodynamic forces on fixed surfaces

  // Dihedral effect
  rft := rft + muldiv(-10, wdotsq, 100)

  // Stabiliser effect 
  rfw := rfw + muldiv(-10, ldot, 100)

  // Fin effect
  rfl := rfl + muldiv(-10, wdotsq, 100)
  
  // Aileron effect
  rft :=  rft + muldiv(-c_aileron, tdot, 200)

  // Elevator effect
  rfw :=  rfw + muldiv(c_elevator, tdot+c_thrust, 100)

  // Rudder effect
  rfl :=  rft + muldiv(c_rudder, tdot+c_thrust, 100)

//writef("rft=%9.6d rft1=%9.6d*n", rft, rft1)  
//writef("rfw=%9.6d rfw1=%9.6d*n", rft, rft1)  
//writef("rfl=%9.6d rfl1=%9.6d*n", rft, rft1)  

  // Apply rotational effects using the trapizoidal rule
  // for integration.
  rtdot := rtdot + (rft+rft1)/2/Sps
  rwdot := rwdot + (rfw+rfw1)/2/Sps
  rldot := rldot + (rfl+rfl1)/2/Sps

  rft1, rfw1, rfl1 := rft, rfw, rfl // Save previous values

  // Linear forces

  // Gravity effect
  ft := ft + muldiv(-k_g, ctz, One) // Gravity in direction t
  fw := fw + muldiv(-k_g, cwz, One) // Gravity in direction w
  fl := fl + muldiv(-k_g, clz, One) // Gravity in direction l

  // Drag effect
  ft := ft - muldiv(-k_drag, tdot, 1000000)

  // Side effect
  fw := fw - muldiv(wdot, 100, 1000)

  // Lift effect
  { // Lift is proportions to speed squared (= tdot**2 + ldot**2)
    // multiplied by rdtab(angle, tltab)
    // When angle=0 and speed=100 ft/sec lift is k_g
    // angle(0, tltab) = 267
    // so lift = k_g * (rdtab(angle, tltab)/267) * (speed*speed/(100*100)
    LET tab = TABLE -180_000,    0,
                     -90_000,  500,
                     -15_000,  200,
                     -11_000, 1000,
                           0,  267, // Lift factor when ldot=0
                       4_000,    0,
                      19_000, -600,
                      24_000, -100,
                      90_000, -500,
                     180_000,    0
    LET a = muldiv(k_g, rdtab(atl, tab), 267)
    fl := fl + muldiv(a, tdotsq+ldotsq, 1000)
  }

  // Thrust effect
  ft := ft + muldiv(c_thrust, k_g/8, 2*32768)
  
  //writef("ft=%9.3d fw=%9.3d fl=%9.3d*n", ft, fw, fl)

  // Apply linear effects using the trapizoidal rule
  // for integration.
  tdot := tdot + (ft+ft1)/2/Sps
  wdot := wdot + (fw+fw1)/2/Sps
  ldot := ldot + (fl+fl1)/2/Sps

  ft1, fw1, fl1 := ft, fw, fl  // Save the previous values

  // Calculate x, y and z speeds
  cgxdot := inprod(ctx,cwx,clx, tdot,wdot,ldot)
  cgydot := inprod(cty,cwy,cly, tdot,wdot,ldot)
  cgzdot := inprod(ctz,cwz,clz, tdot,wdot,ldot)

  // Calculate new x, y and z positions.
  cgx := cgx + cgxdot/Sps
  cgy := cgy + cgydot/Sps
  cgz := cgz + cgzdot/Sps

  //rotate(rldot, rwdot, rtdot) // rudder, elevator, aileron
  // Anti-clockwise rotation rates in radians per second
  // about axes t, w and l.
  rotate(rtdot/Sps, rwdot/Sps, rldot/Sps)

  // Compute the new values of tdot, wdot and ldot
  // from cgxdot, cgydot and cgzdot using the new orientation

  tdot := inprod(cgxdot,cgydot,cgzdot, ctx,cty,ctz)
  wdot := inprod(cgxdot,cgydot,cgzdot, cwx,cwy,cwz)
  ldot := inprod(cgxdot,cgydot,cgzdot, clx,cly,clz)
//writef("cgx=%9.3d  cgy=%9.3d  cgz=%9.3d*n", cgx, cgy, cgy)
//abort(1003)

  IF cgz < 10_000 DO
  { // The aircraft is near the ground

    IF cgz < 2_000 | clz<0_800000 DO
    { crashed := TRUE
      stepping := FALSE
      RETURN
    }

    
  }
}

AND plotcraft() BE
{ // 
  //cetx, cety, cetz  := One,   0,   0
  //cewx, cewy, cewz  :=   0, One,   0
  //celx, cely, celz  :=   0,   0, One

  //eyex, eyey, eyez := -1000_000, 0, 60_000

  IF depthscreen FOR i = 0 TO screenxsize*screenysize-1 DO
    depthscreen!i := maxint

  IF aircraft=0 DO
  { // Simple aircraft
    setcolour(maprgb(64,128,64))  // Fuselage
    cdrawtriangle3d(6_000,0,0,  2_000,0,-1_000, -2_000,0,2_000)
    setcolour(maprgb(40,100,40))
    cdrawtriangle3d(2_000,0,-1_000, -2_000,0,2_000, -12_000,0,0)
    setcolour(maprgb(255,255,255))
    cdrawtriangle3d(2_000,0, 1_000, -2_000,0,2_000, 0_800,0,2_000)

    setcolour(maprgb(255,0,0))  // Port wing -- Red
    cdrawtriangle3d(2_500,0,0, -2_500,0,0,  -2_000, 18_000,2_000)
    setcolour(maprgb(0,255,0))  // Starboard wing -- Green
    cdrawtriangle3d(2_500,0,0, -2_500,0,0,  -2_000,-18_000,2_000)

    setcolour(maprgb(255,0,255))  // Stabliser
    cdrawtriangle3d(-9_000,0,0, -12_000,0,0,  -13_000,-4_000,0)
    setcolour(maprgb(255,255,0))
    cdrawtriangle3d(-9_000,0,0, -12_000,0,0,  -13_000, 4_000,0)

    setcolour(maprgb(0,255,255))  // Fin
    cdrawtriangle3d(-9_000,0,0, -12_000,0,0,  -13_000,0,4_000)
  }

  IF aircraft=1 DO
  { // Draw a Tigermoth
    drawtigermoth()
  }

  IF aircraft=2 DO
  { LET s = 10_000
    LET r =  3_000

    // top
    setcolour(maprgb(0,0,0))
    cdrawquad3d( r,0,s,  0,r,s,  -r,0,s,  0,-r,s)

    // top wings
    setcolour(maprgb(255,0,0))
    cdrawtriangle3d( r, 0, s,  s, 0, s,  s, 0, r) // N
    setcolour(maprgb(0,255,0))
    cdrawtriangle3d( 0, r, s,  0, s, s,  0, s, r) // W
    setcolour(maprgb(255,0,0))
    cdrawtriangle3d(-r, 0, s, -s, 0, s, -s, 0, r) // S
    setcolour(maprgb(0,255,0))
    cdrawtriangle3d( 0,-r, s,  0,-s, s,  0,-s, r) // E

    // Sides  
    setcolour(maprgb(128,0,0))
    cdrawquad3d(s,0,r,  s,r,0,  s,0,-r,  s,-r,0)     // N

    setcolour(maprgb(255,128,0))
    cdrawquad3d(0,s,r,  r,s,0,  0,s,-r,  -r,s,0)     // W

    setcolour(maprgb(255,0,128))
    cdrawquad3d(-s,0,r,  -s,r,0,  -s,0,-r,  -s,-r,0) // S

    setcolour(maprgb(255,128,128))
    cdrawquad3d(0,-s,r,  r,-s,0,  0,-s,-r,  -r,-s,0) // W

    // Centre wings
    setcolour(maprgb(255,128,0))
    cdrawtriangle3d( s, s, 0,  r, s, 0,  s, r, 0) // NW
    setcolour(maprgb(0,255,128))
    cdrawtriangle3d(-s, s, 0, -s, r, 0, -r, s, 0) // SW
    setcolour(maprgb(128,0,255))
    cdrawtriangle3d(-s,-s, 0, -r,-s, 0, -s,-r, 0) // SE
    setcolour(maprgb(127,255,255))
    cdrawtriangle3d( s,-s, 0,  s,-r, 0,  r,-s, 0) // NE

    // bottom wings
    setcolour(maprgb(255,0,0))
    cdrawtriangle3d( r, 0,-s,  s, 0,-s,  s, 0,-r) // N
    setcolour(maprgb(0,255,0))
    cdrawtriangle3d( 0, r,-s,  0, s,-s,  0, s,-r) // W
    setcolour(maprgb(255,0,255))
    cdrawtriangle3d(-r, 0,-s, -s, 0,-s, -s, 0,-r) // S
    setcolour(maprgb(0,255,255))
    cdrawtriangle3d( 0,-r,-s,  0,-s,-s,  0,-s,-r) // E

    // Bottom
    setcolour(maprgb(128,128,128))
    cdrawquad3d( r,0,-s,  0,r,-s,  -r,0,-s,  0,-r,-s)
  }

/*
  setcolour(col_white)
  // Fuselage

  
  cmoveto(-200, 0, 7); cdrawto(-150, 5,12)
  cdrawto(-40, 20,20);cdrawto(30, 20,20);cdrawto(40, 20,10);cdrawto(90, 10,7)
  cmoveto(-200, 0, 7); cdrawto(-150,-5,12)
  cdrawto(-40,-20,20);cdrawto(30,-20,20);cdrawto(40,-20,10);cdrawto(90,-10,7)

  setcolour(col_black)
  cmoveto(90, 10,7)
  cdrawto(90,-10,7);cdrawto(90,-10,-10);cdrawto(90,10,-10);cdrawto(90,10,7)

  setcolour(col_white)
  cmoveto(-200, 0,  0);cdrawto(-160,  4, -3)
  cdrawto(-40, 20,-20);cdrawto(  30, 20,-20);cdrawto(90, 10,-10)
  cmoveto(-200, 0,  0);cdrawto(-160, -4, -3)
  cdrawto(-40,-20,-20);cdrawto(  30,-20,-20);cdrawto(90,-10,-10)

  cmoveto(-40, 20,20)
  cdrawto(-40,-20,20);cdrawto(-40,-20,-20);cdrawto(-40, 20,-20);cdrawto(-40,20,20)
  cmoveto( 40, 20,10)
  cdrawto( 40,-20,10);cdrawto( 30,-20,-20);cdrawto( 30, 20,-20);cdrawto( 40,20,10)

  cmoveto(  30,20, 20);cdrawto(  30,-20, 20)
  cmoveto(  30,20,-20);cdrawto(  30,-20,-20)
  cmoveto(-200, 0,  0);cdrawto(-200,  0,  7)

  // Fin
  setcolour(col_white)
  cmoveto(-200,0,7);cdrawto(-210,0,60);cdrawto(-190,0,60);cdrawto(-150,0,12);cdrawto(-200,0,7)
  // Tail plane
  setcolour(col_red)
  cmoveto(-190,0,0); cdrawto(-200, 70,0);cdrawto(-170, 70,0);cdrawto(-150,0,0)
  setcolour(col_green)
  cdrawto(-190,0,0); cdrawto(-200,-70,0);cdrawto(-170,-70,0);cdrawto(-150,0,0)
  // Port wing
  setcolour(col_red)
  //cmoveto(-40, 20,-20);cdrawto(-50, 200,10);cdrawto(-10, 200,10);cdrawto(30, 20,-20)
  //cdrawto(-40, 20,-20)
  cmoveto(-40, 20,20);cdrawto(-50, 200,50);cdrawto(-10, 200,50);cdrawto(30, 20,20)
  cdrawto(-40, 20,20)
  // Starboard wing
  setcolour(col_green)
  cmoveto(-40,-20,20);cdrawto(-50,-200,50);cdrawto(-10,-200,50);cdrawto(30,-20,20)
  cdrawto(-40,-20,20)

//writef("plotcraft*n")
//updatescreen()
//abort(1000)
*/
//  cetx, cety, cetz  := ctx, cty, ctz
//  cewx, cewy, cewz  := cwx, cwy, cwz
//  celx, cely, celz  := clx, cly, clz
}
/*
AND cmoveto(x, y, z) BE
{ LET sx, sy = 0, 0

  LET rx = inprod(x, y, z, ctx,cwx,clx)
  LET ry = inprod(x, y, z, cty,cwy,cly)
  LET rz = inprod(x, y, z, ctz,cwz,clz)

  screencoords(541*rx-eyex, 541*ry-eyey, 541*rz-eyez, @sx)
  moveto(sx, sy)
//writef("moveto: x=%n, y=%n*n", sx, sy)
}

AND cdrawto(x, y, z) BE
{ LET sx, sy = 0, 0

  LET rx = inprod(x, y, z, ctx,cwx,clx)
  LET ry = inprod(x, y, z, cty,cwy,cly)
  LET rz = inprod(x, y, z, ctz,cwz,clz)

  screencoords(541*rx-eyex, 541*ry-eyey, 541*rz-eyez, @sx)
  drawto(sx, sy)
//writef("drawto: x=%n, y=%n*n", sx, sy)
}
*/



AND gdrawquad3d(x1,y1,z1, x2,y2,z2, x3,y3,z3, x4,y4,z4) BE
{ // Draw a 3D quad (not rotated)
  LET sx1,sy1,sz1 = ?,?,?
  LET sx2,sy2,sz2 = ?,?,?
  LET sx3,sy3,sz3 = ?,?,?
  LET sx4,sy4,sz4 = ?,?,?

  UNLESS screencoords(x1-eyex, y1-eyey, z1-eyez, @sx1) RETURN
  UNLESS screencoords(x2-eyex, y2-eyey, z2-eyez, @sx2) RETURN
  UNLESS screencoords(x3-eyex, y3-eyey, z3-eyez, @sx3) RETURN
  UNLESS screencoords(x4-eyex, y4-eyey, z4-eyez, @sx4) RETURN

  //drawquad3d(sx1,sy1,sz1, sx2,sy2,sz2, sx3,sy3,sz3, sx4,sy4,sz4)
}

AND cdrawquad3d(x1,y1,z1, x2,y2,z2, x3,y3,z3, x4,y4,z4) BE
{ LET rx1 = inprod(x1,y1,z1, ctx,cwx,clx)
  LET ry1 = inprod(x1,y1,z1, cty,cwy,cly)
  LET rz1 = inprod(x1,y1,z1, ctz,cwz,clz)

  LET rx2 = inprod(x2,y2,z2, ctx,cwx,clx)
  LET ry2 = inprod(x2,y2,z2, cty,cwy,cly)
  LET rz2 = inprod(x2,y2,z2, ctz,cwz,clz)

  LET rx3 = inprod(x3,y3,z3, ctx,cwx,clx)
  LET ry3 = inprod(x3,y3,z3, cty,cwy,cly)
  LET rz3 = inprod(x3,y3,z3, ctz,cwz,clz)

  LET rx4 = inprod(x4,y4,z4, ctx,cwx,clx)
  LET ry4 = inprod(x4,y4,z4, cty,cwy,cly)
  LET rz4 = inprod(x4,y4,z4, ctz,cwz,clz)

  LET sx1,sy1,sz1 = ?,?,?
  LET sx2,sy2,sz2 = ?,?,?
  LET sx3,sy3,sz3 = ?,?,?
  LET sx4,sy4,sz4 = ?,?,?

  UNLESS screencoords(rx1-eyex, ry1-eyey, rz1-eyez, @sx1) RETURN
  UNLESS screencoords(rx2-eyex, ry2-eyey, rz2-eyez, @sx2) RETURN
  UNLESS screencoords(rx3-eyex, ry3-eyey, rz3-eyez, @sx3) RETURN
  UNLESS screencoords(rx4-eyex, ry4-eyey, rz4-eyez, @sx4) RETURN

  drawquad3d(sx1,sy1,sz1, sx2,sy2,sz2, sx3,sy3,sz3, sx4,sy4,sz4)
}

AND cdrawtriangle3d(x1,y1,z1, x2,y2,z2, x3,y3,z3) BE
{ LET rx1 = inprod(x1,y1,z1, ctx,cwx,clx)
  LET ry1 = inprod(x1,y1,z1, cty,cwy,cly)
  LET rz1 = inprod(x1,y1,z1, ctz,cwz,clz)

  LET rx2 = inprod(x2,y2,z2, ctx,cwx,clx)
  LET ry2 = inprod(x2,y2,z2, cty,cwy,cly)
  LET rz2 = inprod(x2,y2,z2, ctz,cwz,clz)

  LET rx3 = inprod(x3,y3,z3, ctx,cwx,clx)
  LET ry3 = inprod(x3,y3,z3, cty,cwy,cly)
  LET rz3 = inprod(x3,y3,z3, ctz,cwz,clz)

  LET sx1,sy1,sz1 = ?,?,?
  LET sx2,sy2,sz2 = ?,?,?
  LET sx3,sy3,sz3 = ?,?,?

  UNLESS screencoords(rx1-eyex, ry1-eyey, rz1-eyez, @sx1) RETURN
  UNLESS screencoords(rx2-eyex, ry2-eyey, rz2-eyez, @sx2) RETURN
  UNLESS screencoords(rx3-eyex, ry3-eyey, rz3-eyez, @sx3) RETURN

  drawtriangle3d(sx1,sy1,sz1, sx2,sy2,sz2, sx3,sy3,sz3)
}

AND screencoords(x,y,z, v) = VALOF
{ // If the point (x,y,z) is in view, set v!0, v!1 and v!2 to
  // the screen coordinates and depth and return TRUE
  // otherwise return FALSE
  LET sx = inprod(x,y,z, cewx,cewy,cewz) // Horizontal
  LET sy = inprod(x,y,z, celx,cely,celz) // Vertical
  LET sz = inprod(x,y,z, cetx,cety,cetz) // Depth
  LET screensize = screenxsize>=screenysize -> screenxsize, screenysize

  // Test that the point is in view, ie at least 1.000ft in front
  // and no more than 45 degrees from the direction of view.
  IF sz<1_000 &
    muldiv(sz, sz, 1000) >= muldiv(sx, sx, 1000) + muldiv(sy, sy, 1000) DO
  { 
    RESULTIS FALSE
  }

  // screensize pixel away from the centre of the screen is
  // 45 degrees from the direction of view.
  // Note that many pixels in this range are off the screen.
  v!0 := -muldiv(sx, screensize, sz)  + screenxsize/2
  v!1 := +muldiv(sy, screensize, sz)  + screenysize/2
  v!2 := sz
  RESULTIS TRUE
}

AND screencoords1(px, py, pz, v) = VALOF
{ // If the point (px,py,pz) is in the pilot's field of view
  // set v!0 and v!1 to the screen coordinates and return TRUE
  // otherwise return FALSE
//writef("px=%9.3d  py=%9.3d  pz=%9.3d*n", px, py, pz)
//writef("v_t!0=%9.6d v_t!1=%9.6d v_t!2=%9.6d*n", v_t!0, v_t!1, v_t!2)
//writef("v_w!0=%9.6d v_w!1=%9.6d v_w!2=%9.6d*n", v_w!0, v_w!1, v_w!2)
//writef("v_l!0=%9.6d v_l!1=%9.6d v_l!2=%9.6d*n", v_l!0, v_l!1, v_l!2)

  LET x = inprod(px,py,pz, cewx,cewy,cewz)
  LET y = inprod(px,py,pz, celx,cely,celz)
  LET z = inprod(px,py,pz, cetx,cety,cetz)
  //writef("x=%9.3d y=%9.3d z=%9.3d*n", x, y, z)
  // Test that the point is in front of the aircraft
  // and no more than 45 degrees from the direction of thrust.
  UNLESS z>20 &
    muldiv(z, z, maxint) > muldiv(x, x, maxint) + muldiv(y, y, maxint) DO
  { //abort(1001)
    RESULTIS FALSE
  }
  v!0 := -muldiv(x, screenxsize, z) / 2  + screenxsize/2
  v!1 := +muldiv(y, screenxsize, z) / 2  + screenysize/2
//writef("v!0=%4i v!1=%4i*n", v!0, v!1)

  RESULTIS TRUE
}

AND draw_artificial_horizon() BE
{ LET hl = VEC 1
  LET hr = VEC 1
  LET x, y, z = ctx, cty, ctz
  setcolour(col_cyan)
  screencoords1(x, y, z, hl)
  drawrect(hl!0, hl!1, hl!0+1, hl!1+1)
  IF screencoords(x-y/2, y+x/2, 0, hl) &
     screencoords(x+y/2, y-x/2, 0, hr) DO
  { moveto(hl!0, hl!1)
    drawto(hr!0, hr!1)
  }
}

AND draw_ground_point(x, y) BE
{ LET gx, gy = ?, ?
//newline()
//writef("draw_ground_point: x=%n y=%n*n", x, y)
//writef("draw_ground_point: cgx=%n cgy=%n cgz=%n*n", cgx, cgy, cgz)
  IF screencoords1(x-cgx, y-cgy, -cgz-cockpitz, @gx) DO
  { drawrect(gx, gy, gx+1, gy+1)
    //updatescreen()
  }
}

AND drawgroundpoints() BE
{

  FOR x = 0 TO 200_000 BY 20_000 DO
  { FOR y = -50_000 TO 45_000 BY 5_000 DO
    { LET r = ABS(3*x + 5*y) MOD 23
      setcolour(maprgb(30+r,30+r,30+r))
      gdrawquad3d(x,        y,       0,
                  x+20_000, y,       0,
                  x+20_000, y+5_000, 0,
                  x,        y+5_000, 0)
    }
  }
    

  setcolour(col_white)
  draw_ground_point(      0,       0)
  FOR x = 0 TO 3000_000 BY 100_000 DO
  { draw_ground_point(x, -50_000)
    draw_ground_point(x, +50_000)
  }
  draw_ground_point(3000_000, 0)

  FOR k = 1000_000 TO 10000_000 BY 1000_000 DO
  { setcolour(col_lightmajenta)
    IF k>3000_000 DO draw_ground_point( k,  0)
    setcolour(col_white)
    draw_ground_point(-k,  0)
    setcolour(col_red)
    draw_ground_point( 0,  k)
    setcolour(col_green)
    draw_ground_point( 0, -k)
  }
}

AND initposition(n) BE SWITCHON n INTO
{ DEFAULT:

  CASE 1: // Take off position
    cgx, cgy, cgz    := 100_000,  0,  100_000  // 

    tdot, wdot, ldot :=   0,  0,     0      // Stationary
    rtdot, rwdot, rldot := 0, 0, 0

    ctx, cty, ctz := One,   0,   0  // Direction cosines with
    cwx, cwy, cwz :=   0, One,   0  // six decimal digits
    clx, cly, clz :=   0,   0, One  // after to decimal point.

    ft1,  fw1,  fl1  := 0, 0, 0 // Previous linear forces
    rft1, rfw1, rfl1 := 0, 0, 0 // Previous rotational forces

    stepping := TRUE
    crashed := FALSE
    RETURN

  CASE 2: // Position on the glide slope
    cgx, cgy, cgz    := -4000_000,  0,  1000_000  // height of 1000 ft

    tdot, wdot, ldot :=   100_000,  0,     0      // 100 ft/s in direction x
    rtdot, rwdot, rldot := 0, 0, 0

    ctx, cty, ctz := One,   0,   0  // Direction cosines with
    cwx, cwy, cwz :=   0, One,   0  // six decimal digits
    clx, cly, clz :=   0,   0, One  // after to decimal point.

    ft1,  fw1,  fl1  := 0, 0, 0 // Previous linear forces
    rft1, rfw1, rfl1 := 0, 0, 0 // Previous rotational forces

    stepping := TRUE
    crashed := FALSE
    RETURN

}

LET start() = VALOF
{ initposition(1) // Get ready for take off

  cetx, cety, cetz := ctx, cty, ctz
  cewx, cewy, cewz := cwx, cwy, cwz
  celx, cely, celz := clx, cly, clz

  eyex, eyey, eyez := 0, 0, 0   // Relative eye position
  //hatdir, hatmsecs, eyedir := 0, 0, 0
  hatdir, hatmsecs := #b0001, 0 // From behind
  eyedir := 1
  eyedist := 100_000  // Eye x or y distance from aircraft

  cockpitz := 6_000   // Cockpit 8 feet above the ground

  c_thrust, c_elevator, c_aileron, c_rudder := 0, 0, 0, 0
  c_trimthrust, c_trimelevator, c_trimaileron, c_trimrudder := 0, 0, 0, 0

  // Set rotational damping parameters 
  rdt,   rdw,  rdl := 500, 500, 950

  ft,      fw,    fl  := 0, 0, 0
  ft1,    fw1,   fl1  := 0, 0, 0
  rft,    rfw,   rfl  := 0, 0, 0
  rft1,  rfw1,  rfl1  := 0, 0, 0
  rtdot, rwdot, rldot := 0, 0, 0
  //writef("%i7 %i7 %i7*n", cgx/1000,   cgy/1000, cgz/1000)

  usage := 0

  initsdl()
  mkscreen("Tiger Moth", 800, 600)

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

  plotscreen()

  done := FALSE
  debugging := FALSE
  plotusage := FALSE

  IF FALSE DO
  { // Test rdtab
    FOR a = -180_000 TO 180_000 BY 1000 DO
    { LET t = TABLE -180_000,0, 0,360, 180_000,0
      IF a MOD 6_000 = 0 DO writef("*n%i4:", a/1000)
      writef(" %8.3d", rdtab(a, tltab))
    }
    newline()
    abort(1009)
  }

  IF FALSE DO
  { // The the angle function
    writef("x=%i5  y=%i5    angle=%9.3d*n", 1000, 1000, angle(1000, 1000))
    writef("x=%i5  y=%i5    angle=%9.3d*n",    0, 1000, angle(   0, 1000))
    writef("x=%i5  y=%i5    angle=%9.3d*n",-1000, 1000, angle(-1000, 1000))
    writef("x=%i5  y=%i5    angle=%9.3d*n",-1000,-1000, angle(-1000,-1000))
    writef("x=%i5  y=%i5    angle=%9.3d*n", 1000,-1000, angle( 1000,-1000))
    writef("x=%i5  y=%i5    angle=%9.3d*n",-1000,    0, angle(-1000,    0))
    writef("x=%i5  y=%i5    angle=%9.3d*n",   60,    1, angle(   60,    1))
    writef("x=%i5  y=%i5    angle=%9.3d*n",   60,   -1, angle(   60,   -1))

    writef("x=%i5  y=%i5    angle=%9.3d*n",-1000,    1, angle(-1000,    1))
    writef("x=%i5  y=%i5    angle=%9.3d*n",-1000,   -1, angle(-1000,   -1))
    abort(1009)
  }

  aircraft := 1 // The default aircraft -- the tiger moth

  UNTIL done DO
  { // Read joystick and keyboard events
    LET t0 = sdlmsecs()
    LET t1 = ?

    processevents()

    IF stepping DO step()

    //writef("x=%9.3d y=%9.3d h=%9.3d %9.3d*n", cgx, cgy, cgz, cgtdot)
    plotscreen()

    updatescreen()

    t1 := sdlmsecs()
//writef("time %9.3d  %9.3d  %9.3d %9.3d*n", t0, t1, t1-t0, t0+100-t1)
    usage := 100*(t1-t0)/100

    //IF t0+100 < t1 DO
      //sdldelay(t0+100-t1)
      sdldelay(100)
      //sdldelay(900)
//abort(1111)
  }

  writef("*nQuitting*n")
  sdldelay(1_000)
  closesdl()
  RESULTIS 0
}

AND plotscreen() BE
{ LET mx = screenxsize/2
  LET my = screenysize - 70

  fillscreen(col_blue)

  setcolour(col_lightcyan)
  
  drawstring(240, 50, done -> "Quitting", "Tiger Moth Flight Simulator")

  setcolour(col_gray)
  moveto(mx, my)
  drawby(0, cgz/100_000)

  setcolour(col_darkgray)
  drawfillrect(screenxsize-20-100, screenysize-20-100,
               screenxsize-20,     screenysize-20)
  drawfillrect(screenxsize-50-100, screenysize-20-100,
               screenxsize-30-100, screenysize-20)
  drawfillrect(screenxsize-20-100, screenysize-50-100,
               screenxsize-20,     screenysize-30-100)

  IF crashed DO
  { setcolour(col_red)
    plotf(mx-50, my+10, "CRASHED")
  }

  setcolour(col_red)
  moveto(mx, my)
  drawby(cgx/100_000, cgy/100_000)

  { LET pos = muldiv(40, c_thrust, 32768)
    setcolour(col_red)
    drawfillrect(screenxsize-45-100, pos+screenysize-15-100,
                 screenxsize-35-100, pos+screenysize- 5-100)
  }

  { LET pos = muldiv(45, c_rudder, 32768)
    setcolour(col_red)
    drawfillrect(pos+screenxsize-25-50, -5+screenysize-40-100,
                 pos+screenxsize-15-50, +5+screenysize-40-100)
  }

  { LET posx = muldiv(45, c_aileron,  32768)
    LET posy = muldiv(45, c_elevator, 32768)
    setcolour(col_red)
    drawfillrect(posx+screenxsize-25-50, posy+screenysize-25-50,
                 posx+screenxsize-15-50, posy+screenysize-15-50)
  }

  setcolour(col_majenta)
  moveto(mx+200, my)
  drawby(ctx/20_000, cty/20_000)


  setcolour(col_lightblue)

  IF debugging DO
  { plotf(20, my,     "Thrust=%6i Elevator=%6i Aileron=%6i Rudder=%6i",
                      c_thrust, c_elevator, c_aileron, c_rudder)
    plotf(20, my- 15, "x=%9.3d  y=%9.3d  z=%9.3d", cgx, cgy, cgz)
    plotf(20, my- 30, "tdot=%9.3d wdot=%9.3d ldot=%9.3d", tdot, wdot, ldot)
    plotf(20, my- 45, "atl=%9.3d atw=%9.3d awl=%9.3d",  atl, atw, awl)
    plotf(20, my- 60, "ct   %9.6d %9.6d %9.6d", ctx,cty,ctz)
    plotf(20, my- 75, "cw   %9.6d %9.6d %9.6d", cwx,cwy,cwz)
    plotf(20, my- 90, "cl   %9.6d %9.6d %9.6d", clx,cly,clz)
    plotf(20, my-105, "ft  =%8.3d fw =%8.3d fl =%8.3d", ft, fw, fl)
    plotf(20, my-120, "rft =%9.6d rfw=%9.6d rfl=%9.6d", rft,rfw,rfl)
  }

  IF plotusage DO
  { plotf(20, my-135, "CPU usage = %3i%%", usage)
  }

  draw_artificial_horizon()

  drawgroundpoints()
  IF eyedir DO plotcraft()
  updatescreen()
}

AND seteyeposition1() BE
{ cetx, cety, cetz :=  One,   0,   0
  cewx, cewy, cewz :=    0, One,   0
  celx, cely, celz :=    0,   0, One
  eyex, eyey, eyez :=  -eyedist,   0, 0   // Relative eye position
}

AND seteyeposition() BE
{ LET d1 = eyedist
  LET d2 = d1*707/1000
  LET d3 = d2/3

  cetx, cety, cetz :=  One,   0,   0
  cewx, cewy, cewz :=    0, One,   0
  celx, cely, celz :=    0,   0, One
  eyex, eyey, eyez :=  -eyedist,   0, 0   // Relative eye position


UNLESS 0<=eyedir<=8 DO eyedir := 1

  IF hatdir & sdlmsecs()>hatmsecs+100 DO
  { eyedir := ((angle(ctx, cty)+360_000+22_500) / 45_000) & 7
    // dir = 0  heading N
    // dir = 1  heading NE
    // dir = 2  heading E
    // dir = 3  heading SE
    // dir = 4  heading S
    // dir = 5  heading SW
    // dir = 6  heading W
    // dir = 7  heading NW
    SWITCHON hatdir INTO
    { DEFAULT:
      CASE #b0001:                     ENDCASE // Forward
      CASE #b0011: eyedir := eyedir+1; ENDCASE // Forward right
      CASE #b0010: eyedir := eyedir+2; ENDCASE // Right
      CASE #b0110: eyedir := eyedir+3; ENDCASE // Backward right
      CASE #b0100: eyedir := eyedir+4; ENDCASE // Backward
      CASE #b1100: eyedir := eyedir+5; ENDCASE // Backward left
      CASE #b1000: eyedir := eyedir+6; ENDCASE // Left
      CASE #b1001: eyedir := eyedir+7; ENDCASE // Forward left
    }
    eyedir := (eyedir & 7) + 1
    hatdir := 0

writef("ctx=%9.6d cty=%9.6d eyedir=%n*n", ctx, cty, eyedir)
//abort(1009) 
  }

  SWITCHON eyedir INTO
  { DEFAULT:

    CASE 0: // Pilot's view
      cetx, cety, cetz := ctx, cty, ctz
      cewx, cewy, cewz := cwx, cwy, cwz
      celx, cely, celz := clx, cly, clz

      eyex, eyey, eyez := 0, 0, 0   // Relative eye position
      RETURN

     CASE 1: // North
       cetx, cety, cetz :=  One,   0,   0
       cewx, cewy, cewz :=    0, One,   0
       celx, cely, celz :=    0,   0, One
       eyex, eyey, eyez :=  -d1,   0,  d3   // Relative eye position
       RETURN

     CASE 2: // North east
       cetx, cety, cetz :=  D45, D45,   0
       cewx, cewy, cewz := -D45, D45,   0
       celx, cely, celz :=    0,   0, One
       eyex, eyey, eyez :=  -d2, -d2,  d3   // Relative eye position
       RETURN

     CASE 3: // East
       cetx, cety, cetz :=    0, One,   0
       cewx, cewy, cewz := -One,   0,   0
       celx, cely, celz :=    0,   0, One
       eyex, eyey, eyez :=    0, -d1,  d3   // Relative eye position
       RETURN

     CASE 4: // South east
       cetx, cety, cetz := -D45, D45,   0
       cewx, cewy, cewz := -D45,-D45,   0
       celx, cely, celz :=    0,   0, One
       eyex, eyey, eyez :=   d2, -d2,  d3   // Relative eye position
       RETURN

     CASE 5: // South
       cetx, cety, cetz := -One,   0,   0
       cewx, cewy, cewz :=   0, -One,   0
       celx, cely, celz :=   0,    0, One
       eyex, eyey, eyez :=  d1,    0,  d3   // Relative eye position
       RETURN

     CASE 6: // South west
       cetx, cety, cetz :=-D45,-D45,   0
       cewx, cewy, cewz := D45,-D45,   0
       celx, cely, celz :=   0,   0, One
       eyex, eyey, eyez :=  d2,  d2,  d3   // Relative eye position
       RETURN

     CASE 7: // West
       cetx, cety, cetz :=   0,-One,   0
       cewx, cewy, cewz := One,   0,   0
       celx, cely, celz :=   0,   0, One
       eyex, eyey, eyez :=   0,  d1,  d3   // Relative eye position

       RETURN

     CASE 8: // North west
       cetx, cety, cetz := D45,-D45,   0
       cewx, cewy, cewz := D45, D45,   0
       celx, cely, celz :=   0,   0, One
       eyex, eyey, eyez := -d2,  d2,  d3   // Relative eye position
       RETURN
  }
}

AND processevents() BE WHILE getevent() SWITCHON eventtype INTO
{ DEFAULT:
    //writef("Unknown event type = %n*n", eventtype)
    LOOP

  CASE sdle_keydown:
    SWITCHON capitalch(eventa2) INTO
    { DEFAULT:                                     LOOP

      CASE 'Q':  done := TRUE;                     LOOP

      CASE 'D':  debugging := ~debugging;          LOOP

      CASE 'U':  plotusage := ~plotusage;          LOOP

      CASE 'G': // Position aircraft on the glide path
                initposition(2)
                ctx, cty, ctz := One,   0,   0
                cwx, cwy, cwz :=   0, One,   0
                clx, cly, clz :=   0,   0, One
                rtdot, rwdot, rldot := 0_020000, 0_030000, 0_050000
                LOOP

      CASE 'L': // Position the aircraft ready for take off
                initposition(1)
                LOOP

      CASE 'N': // Reduce eye distance
                eyedist := eyedist*5/6
                IF eyedist<60_000 DO eyedist := 60_000
                LOOP

      CASE 'F': // Increase eye distance
                eyedist := eyedist*6/5
                LOOP
      CASE 'S': aircraft := (aircraft+1) MOD 3;   LOOP

      CASE 'Z': c_trimthrust := c_trimthrust - 500
                c_thrust := c_thrust-500;         LOOP
      CASE 'X': c_trimthrust := c_trimthrust + 500
                c_thrust := c_thrust+500;         LOOP

      CASE ',':
      CASE '<': c_trimrudder := c_trimrudder - 500
                c_rudder := c_rudder - 500;       LOOP

      CASE '.':
      CASE '>': c_trimrudder := c_trimrudder + 500
                c_rudder := c_rudder + 500;       LOOP

      CASE '0': eyedir, hatdir := 0, 0;        LOOP // Pilot's view
      CASE '1': hatdir, hatmsecs := #b0001, 0; LOOP // From behind
      CASE '2': hatdir, hatmsecs := #b0011, 0; LOOP // From behind right
      CASE '3': hatdir, hatmsecs := #b0010, 0; LOOP // From right
      CASE '4': hatdir, hatmsecs := #b0110, 0; LOOP // From in front right
      CASE '5': hatdir, hatmsecs := #b0100, 0; LOOP // From in front
      CASE '6': hatdir, hatmsecs := #b1100, 0; LOOP // From in front left
      CASE '7': hatdir, hatmsecs := #b1000, 0; LOOP // From left
      CASE '8': hatdir, hatmsecs := #b1001, 0; LOOP // From behind left

      CASE sdle_arrowup:    c_trimelevator := c_trimelevator+500
                            c_elevator := c_elevator+500;         LOOP
      CASE sdle_arrowdown:  c_trimelevator := c_trimelevator-500
                            c_elevator := c_elevator-500;         LOOP
      CASE sdle_arrowright: c_trimaileron  := c_trimaileron +500
                            c_aileron := c_aileron+500;           LOOP
      CASE sdle_arrowleft:  c_trimaileron  := c_trimaileron -500
                            c_aileron := c_aileron-500;           LOOP
    }
    LOOP

  CASE sdle_joyaxismotion:    // 7
  { LET which = eventa1
    LET axis  = eventa2
    LET value = eventa3
//writef("axismotion: which=%n axis=%n value=%n*n", which, axis, value)
    SWITCHON axis INTO
    { DEFAULT:                                           LOOP
      CASE 0:   c_aileron  := c_trimaileron+value;       LOOP // Aileron
      CASE 1:   c_elevator := c_trimaileron-value;       LOOP // Elevator
      CASE 2:   c_thrust   := c_trimthrust-value+32768;  LOOP // Throttle
      CASE 3:   c_rudder   := c_trimrudder+value;        LOOP // Rudder
      CASE 4:                                            LOOP // Right throttle
    }
  }

  CASE sdle_joyhatmotion:
  { LET which = eventa1
    LET axis  = eventa2
    LET value = eventa3

    //writef("joyhatmotion %n %n %n*n", eventa1, eventa2, eventa3)

    SWITCHON value INTO
    { DEFAULT:   
      CASE #b0000: // None                                        LOOP
      CASE #b0001: // North
      CASE #b0011: // North east
      CASE #b0010: // East
      CASE #b0110: // South east
      CASE #b0100: // South
      CASE #b1100: // South west
      CASE #b1000: // West
      CASE #b1001: // North west
             IF value>hatdir DO
             { hatdir, hatmsecs := value, sdlmsecs()
//writef("hatdir=%b4  %n msecs*n", hatdir, hatmsecs)
             }
             LOOP
    }
  }

  CASE sdle_joybuttondown:    // 10
    //writef("joybuttondown %n %n %n*n", eventa1, eventa2, eventa3)
    SWITCHON eventa2 INTO
    { DEFAULT:   LOOP
      CASE  7:     // Left rudder trim
              c_trimrudder := c_trimrudder - 500
              c_rudder := c_rudder - 500;          LOOP
      CASE  8:     // Right rudder trim
              c_trimrudder := c_trimrudder + 500
              c_rudder := c_rudder + 500;          LOOP
      CASE 11:     // Reduce eye distance
              eyedist := eyedist*5/6
              IF eyedist<400_000 DO eyedist := 400_000
//writef("eyedist=%9.3d*n", eyedist)
              LOOP
      CASE 12:     // Increase eye distance
              eyedist := eyedist*6/5
//writef("eyedist=%9.3d*n", eyedist)
              LOOP
      CASE 13:     // Set pilot view
              eyedir, hatdir := 0, 0;              LOOP
    }
    LOOP

  CASE sdle_joybuttonup:      // 11
    //writef("joybuttonup*n", eventa1, eventa2, eventa3)
    LOOP

  CASE sdle_quit:             // 12
    writef("QUIT*n");
    LOOP

  CASE sdle_videoresize:      // 14
    //writef("videoresize*n", eventa1, eventa2, eventa3)
    LOOP
}
