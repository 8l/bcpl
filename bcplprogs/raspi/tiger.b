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

Up arrow      Trim joystick forward
Down arrow    Trim joystick backward
Left arrow    Trim joystick left
Right arrow   Trim joystick right

, or <        Trim rudder left
. or >        Trim rudder right
x/z           More/Less throttle

0             Display the pilot's view
1,2,3,4,5,6,7,8 Display the aircraft viewed from various angles

f             View aircraft from a greater distance
n             View aircraft from a closer distance

p             pause/unpause the simulation

g             Reset the aircraft on the glide path
t             Reset the aircraft ready for take off -- default
              ie stationary on the ground at the end of the runway

a             Select aircraft

s             Start/Stop engine
b             Brake on/off -- not available
u             Toggle CPU usage

t             testing mode
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

SECTION "sdllib"
GET "libhdr"
GET "sdl.h"
GET "sdl.b"
.
SECTION "tiger"
GET "libhdr"
GET "sdl.h"

MANIFEST {
  One = 1_000000     // Direction cosines scaling factor
                     // ie 6 decimal digits after the decimal point.
  D45 = 0_707107     // cosine of pi/4
  Sps = 10           // Steps per second
  Sps2 = 2*Sps

  // Most measurements are in feet scaled with 3 digits after the decimal point
  k_g = 32_000       // Acceleration due to gravity, 32 ft per sec per sec
                     // Scaled with 3 digits after the decimal point.
  k_drag = 30000    // Acceleration due to drag as 100 ft per sec
                     // The drag is proportional to the square of the speed.

  // Conversion factors
  mph2fps   = 5280_000/(60*60)
  mph2knots = 128_000/147
}

GLOBAL {
  aircraft:ug  // Select which aircraft to simulate

  stepping     // =FALSE if not stepping the simulation
  crashed      // =TRUE if crashed
  debugging
  testing      // Toggle testing mode
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

  c_throttle; c_trimthrottle //      0 .. 65535
  c_aileron;  c_trimaileron  // -32768 .. 32767
  c_elevator; c_trimelevator // -32768 .. 32767
  c_rudder;   c_trimrudder   // -32768 .. 32767

  enginestarted
  rpm; targetrpm
  thrust

  rateofclimb  // In ft/min

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

  cgxdot; cgydot; cgzdot // These are set by step()

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
  tdot;   wdot;   ldot   // Speed in t, w and l directions
  tdotsq; wdotsq; ldotsq // Speed squared in t, w and l directions

  mass                   // Mass of the aircraft

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

AND rdtab(x, tab) = VALOF
{ // Perform linear interpolation between appropriate entries
  // in the given table which must have at least two entries
  // and their x positions must be different.
  // It returns the first value is x is too small
  // It returns the last value is x is too big
  // otherwise it interpolates between the nearest two entries.
  LET upb = tab!0 // = subscript of last pos value pair
                  // eg tab -> [7,  800,   0_000,
                  //               1200,  10_000,
                  //               1700,  50_000,
                  //               2000,   0_000]
  LET p = tab+1
  LET x0, r0, x1, r1 = ?, ?, ?, ?
  IF x<=tab!1   RESULTIS tab!2
  IF x>=tab!upb RESULTIS tab!(upb+1)
  WHILE x>!p DO p := p+2
  IF x=!p RESULTIS p!1
  x0, r0 := p!-2, p!-1
  x1, r1 := p! 0, p! 1
  RESULTIS r0 + muldiv(r1-r0, x-x0, x1-x0)
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

  LET lwheelz = inprod( -1_000, +2_100, -4_500, ctz,cwz,clz)+cgz
  // lwheelz is height of left wheel above/below the ground
  LET rwheelz = inprod( -1_000, -2_100, -4_500, ctz,cwz,clz)+cgz
  // rwheelz is height of right wheel above/below the ground
  LET skidz   = inprod(-16_000,      0, -0_667-0_400, ctz,cwz,clz)+cgz
  // skidz is height of tail skid above/below the ground

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

  // Calculate the engine RPM and thrust
  targetrpm := 0
  IF enginestarted DO
  { targetrpm := 600 + muldiv(1500, c_throttle, 65536) +
                 muldiv(500, tdot, 208_000) // + air speed effect
  }

  rpm := rpm + (targetrpm-rpm)/Sps - 1
  IF rpm < 0 DO rpm := 0

  thrust := VALOF
  { LET vmax = muldiv(200_000, rpm, 2500) // Speed at which thrust=0
    LET vmaxby2 = vmax/2 // use linear interpolation between vmax and vmaxby2
    LET tmax = k_g/8
    LET t = ?
    IF rpm<600 | tdot>vmax RESULTIS 0
    t := muldiv(tmax, (rpm-600)*(rpm-600), (2500-600)*(2500-600))
    IF tdot<vmaxby2 RESULTIS t
    RESULTIS muldiv(t, vmax-tdot, vmaxby2)
  }

  writef("rpm=%4i tdot=%9.3d thrust=%9.3d*n",
          rpm, tdot, thrust)

//writef("tdotsq=%8.3d wdotsq=%8.3d ldotsq=%8.3d*n", tdotsq, wdotsq, ldotsq)

  // Rotational damping
  // rtdot, rwdot and rldot are in radians per second.
  rtdot := muldiv(rtdot, rdt, 1_000*Sps)
  rwdot := muldiv(rwdot, rdw, 1_000*Sps)
  rldot := muldiv(rldot, rdl, 1_000*Sps)

  // Rotational aerodynamic forces on fixed surfaces

  // Dihedral effect
  rft := rft + muldiv(-50_000, wdot, 10000)

  // Stabiliser effect 
  rfw := rfw + muldiv(28000, ldot, 100)

  // Fin effect
  rfl := rfl + muldiv(-10_000, wdot, 1000)
  
  // Aileron effect
  rft :=  rft + muldiv(-c_aileron, tdot, 2000)

  // Elevator effect
  rfw :=  rfw - muldiv(c_elevator-15000, tdot+thrust, 2000)

  // Rudder effect
  rfl :=  rfl + muldiv(c_rudder, tdot+thrust, 2000)

  // Ground effects, wheels and skid  
  IF cgz < 10_000 DO
  { // The aircraft is near the ground

    IF lwheelz<0 DO
    { LET lwforce = -lwheelz*60
      fl := fl + muldiv(lwforce, clz, One)
      ft := ft + muldiv(lwforce, ctz, One)
      fw := fw + muldiv(lwforce, cwz, One)
      IF skidz>0 DO rfw := rfw - lwheelz*3000
      rft := rft + lwheelz*5000
    }
    IF rwheelz<0 DO
    { LET rwforce = -rwheelz*60
      fl := fl + muldiv(rwforce, clz, One)
      ft := ft + muldiv(rwforce, ctz, One)
      fw := fw + muldiv(rwforce, cwz, One)
      IF skidz>0 DO rfw := rfw - rwheelz*3000
      rft := rft - rwheelz*5000
    }

    //writef("lwheelz=%9.3d rwheelz=%9.3d  skidz=%9.3d rft=%9.3d*n",
    //        lwheelz, rwheelz, skidz, rft)

    IF skidz<-0_500 skidz := -0_500
    IF skidz<0 DO
    { //rfw := skidz*10000
      rfw1 := 0
      rwdot := skidz*10000
      IF skidz>-0_200 DO rwdot := 0
      IF rwdot<0 DO rwdot := rwdot/Sps2
      tdot := muldiv(tdot, 95, 100)/Sps2
    }

    IF cgz<4_000 DO cgz := 4_000

  }


//writef("rft=%9.6d rft1=%9.6d*n", rft, rft1)  
//writef("rfw=%9.6d rfw1=%9.6d*n", rft, rft1)  
//writef("rfl=%9.6d rfl1=%9.6d*n", rft, rft1)  

  // Linear forces

  // Gravity effect
  ft := ft + muldiv(-k_g, ctz, One) // Gravity in direction t
  fw := fw + muldiv(-k_g, cwz, One) // Gravity in direction w
  fl := fl + muldiv(-k_g, clz, One) // Gravity in direction l

  // Drag effect
  ft := ft - muldiv(k_drag, tdot, 500_000)

  // Side effect
  fw := fw - muldiv(wdot, 100, 1000)

  // Lift effect
  { // Lift is proportions to speed squared (= tdot**2 + ldot**2)
    // multiplied by rdtab(angle, tltab)
    // When angle=0 and speed=100 ft/sec lift is k_g
    // angle(0, tltab) = 267
    // so lift = k_g * (rdtab(angle, tltab)/267) * (speed*speed/(100*100)
    LET tab = TABLE       19,
                    -180_000,    0,
                     -90_000,  500,
                     -15_000,  200,
                     -11_000,  800,
                           0,  267, // Lift factor when ldot=0
                       4_000,    0,
                      19_000, -500,
                      24_000, -100,
                      90_000, -500,
                     180_000,    0
    LET a = muldiv(k_g, rdtab(atl, tab), 267)
    LET lift = muldiv(a, tdot, 200_000) //*2
    fl := fl + lift
    rfw := rfw - lift*20
  }

  // Thrust effect
  ft := ft + thrust*10

  //writef("ft=%9.3d fw=%9.3d fl=%9.3d*n", ft, fw, fl)

  UNLESS testing DO
  { // Do not apply the forces in testing mode

    // Apply rotational effects using the trapizoidal rule
    // for integration.
    rtdot := rtdot + (rft+rft1)/Sps2
    rwdot := rwdot + (rfw+rfw1)/Sps2
    rldot := rldot + (rfl+rfl1)/Sps2

    rft1, rfw1, rfl1 := rft, rfw, rfl // Save previous values

    // Apply linear effects using the trapizoidal rule
    // for integration.
    tdot := tdot + (ft+ft1)/Sps2
    wdot := wdot + (fw+fw1)/Sps2
    ldot := ldot + (fl+fl1)/Sps2

    IF lwheelz<0_100 | rwheelz<0_100 DO
    { // Limit ldot
      IF ldot> 0_100 DO ldot :=  0_100
      IF ldot<-0_100 DO ldot := -0_100

      // Damp out speed in the w direction
      TEST wdot>=0
      THEN { wdot := wdot - wdot/Sps2 - 0_100 
             IF wdot<0 DO wdot, fw := 0, 0
           }
      ELSE { wdot := wdot - wdot/Sps2 + 0_100 
             IF wdot>0 DO wdot, fw := 0, 0
           }
      // Damp out speed in the l direction
      TEST ldot>=0
      THEN { ldot := ldot - ldot/Sps2 - 0_100 
             IF ldot<0 DO ldot, fw := 0, 0
           }
      ELSE { ldot := ldot - ldot/Sps2 + 0_100 
             IF ldot>0 DO ldot, fw := 0, 0
           }
    }

    ft1, fw1, fl1 := ft, fw, fl  // Save the previous values

    // Calculate x, y and z speeds
    cgxdot := inprod(ctx,cwx,clx, tdot,wdot,ldot)
    cgydot := inprod(cty,cwy,cly, tdot,wdot,ldot)
    cgzdot := inprod(ctz,cwz,clz, tdot,wdot,ldot)

    // Calculate new x, y and z positions.
    cgx := cgx + cgxdot/Sps
    cgy := cgy + cgydot/Sps
    cgz := cgz + cgzdot/Sps

    IF cgz < 0 DO cgz := 0

    rotate(rtdot/Sps, rwdot/Sps, rldot/Sps)

    // Compute the new values of tdot, wdot and ldot
    // from cgxdot, cgydot and cgzdot using the new orientation

    tdot := inprod(cgxdot,cgydot,cgzdot, ctx,cty,ctz)
    wdot := inprod(cgxdot,cgydot,cgzdot, cwx,cwy,cwz)
    ldot := inprod(cgxdot,cgydot,cgzdot, clx,cly,clz)
    //writef("cgx=%9.3d  cgy=%9.3d  cgz=%9.3d*n", cgx, cgy, cgy)
    //abort(1003)
  }
}

AND plotcraft() BE
{ IF depthscreen FOR i = 0 TO screenxsize*screenysize-1 DO
    depthscreen!i := maxint

  //seteyeposition()
  tarmac()

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
}

AND gdrawquad3d(x1,y1,z1, x2,y2,z2, x3,y3,z3, x4,y4,z4) BE
{ // Draw a 3D quad (not rotated)
  LET sx1,sy1,sz1 = ?,?,?
  LET sx2,sy2,sz2 = ?,?,?
  LET sx3,sy3,sz3 = ?,?,?
  LET sx4,sy4,sz4 = ?,?,?
  LET abseyex = cgx+eyex
  LET abseyey = cgy+eyey
  LET abseyez = cgz+eyez

//writef("abseyex=%9.3d abseyey=%9.3d abseyez=%9.3d*n", abseyex,abseyey,abseyez)
  UNLESS screencoords(x1-abseyex, y1-abseyey, z1-abseyez, @sx1) RETURN
  UNLESS screencoords(x2-abseyex, y2-abseyey, z2-abseyez, @sx2) RETURN
  UNLESS screencoords(x3-abseyex, y3-abseyey, z3-abseyez, @sx3) RETURN
  UNLESS screencoords(x4-abseyex, y4-abseyey, z4-abseyez, @sx4) RETURN

  drawquad3d(sx1,sy1,sz1, sx2,sy2,sz2, sx3,sy3,sz3, sx4,sy4,sz4)
}

AND cdrawquad3d(x1,y1,z1, x2,y2,z2, x3,y3,z3, x4,y4,z4) BE
{ // Draw a quad of the aircraft viewed from a relative eye position
  // First rotate the aircraft
  LET rx1 = inprod(x1,y1,z1, ctx,cwx,clx)
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

  // Then calculate the screen coordinates of the vertices as
  // viewed from the relative eye position.
  LET sx1,sy1,sz1 = ?,?,?
  LET sx2,sy2,sz2 = ?,?,?
  LET sx3,sy3,sz3 = ?,?,?
  LET sx4,sy4,sz4 = ?,?,?
//writef("cdrawquad3d called*n")
  UNLESS screencoords(rx1-eyex, ry1-eyey, rz1-eyez, @sx1) RETURN
  UNLESS screencoords(rx2-eyex, ry2-eyey, rz2-eyez, @sx2) RETURN
  UNLESS screencoords(rx3-eyex, ry3-eyey, rz3-eyez, @sx3) RETURN
  UNLESS screencoords(rx4-eyex, ry4-eyey, rz4-eyez, @sx4) RETURN
//writef("calling drawquad3d*n")
//writef("sx1=%i5  sy1=%i5 sz1=%i5*n", sx1,sy1,sz1)
//writef("sx2=%i5  sy2=%i5 sz2=%i5*n", sx2,sy2,sz2)
//writef("sx3=%i5  sy3=%i5 sz3=%i5*n", sx3,sy3,sz3)
//writef("sx4=%i5  sy4=%i5 sz4=%i5*n", sx4,sy4,sz4)

  // Finally plot the quad on the screen.
  drawquad3d(sx1,sy1,sz1, sx2,sy2,sz2, sx3,sy3,sz3, sx4,sy4,sz4)
//writef("returned from drawquad3d*n")
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
//writef("screencoords: x=%9.3d  y=%9.3d  z=%9.3d*n",  x, y, z)
//writef("screencoords:sx=%9.3d sy=%9.3d sz=%9.3d*n", sx,sy,sz)
//writef("cetx=%9.6d  cety=%9.6d  cetz=%9.6d*n", cetx,cety,cetz)
//writef("cewx=%9.6d  cewy=%9.6d  cewz=%9.6d*n", cewx,cewy,cewz)
//writef("celx=%9.6d  cely=%9.6d  celz=%9.6d*n", celx,cely,celz)
//writef("eyex=%9.3d  eyey=%9.3d  eyez=%9.3d*n", eyex,eyey,eyez)

  // Test that the point is in view, ie at least 1.000ft in front
  // and no more than about 27 degrees (inverse tan 1/2) from the
  // direction of view.
  IF sz < ABS x | sz < ABS sy DO
  { 
//writef("screencoords: x=%9.3d  y=%9.3d  z=%9.3d*n",  x, y, z)
//writef("screencoords:sx=%9.3d sy=%9.3d sz=%9.3d*n", sx,sy,sz)
    RESULTIS FALSE
  }
  // A point screensize pixels away from the centre of the screen is
  // 45 degrees from the direction of view.
  // Note that many pixels in this range are off the screen.
  v!0 := -muldiv(sx, screensize, sz)  + screenxsize/2
  v!1 := +muldiv(sy, screensize, sz)  + screenysize/2
  v!2 := sz // This distance into the screen in arbitrary units, used
            // for hidden surface removal.

//writef("in view  position=(x=%i4  y=%i4  depth=%n)*n", v!0, v!1, sz)
//abort(1119)
  RESULTIS TRUE
}

AND screencoords2(px, py, pz, v) = VALOF
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
    muldiv(z, z, 2000) > muldiv(x, x, 1000) + muldiv(y, y, 1000) DO
  { //abort(1001)
    RESULTIS FALSE
  }
  v!0 := -muldiv(x, screenxsize, z) / 1  + screenxsize/2
  v!1 := +muldiv(y, screenxsize, z) / 1  + screenysize/2
//writef("v!0=%4i v!1=%4i*n", v!0, v!1)

  RESULTIS TRUE
}

AND draw_artificial_horizon() BE
{ LET lx, ly, lz = ?, ?, ?
  LET rx, ry, rz = ?, ?, ?
  LET x, y, z = ctx, cty, ctz

  // Draw flight direction circle
  setcolour(col_cyan)
  screencoords(cgxdot, cgydot, cgzdot, @lx)
  drawcircle(lx, ly, 15)

  // Draw artificial horizon
  IF screencoords(x-y/4, y+x/4, z, @lx) &
     screencoords(x+y/4, y-x/4, z, @rx) DO
  { moveto(lx, ly)
    drawto(rx, ry)
  }
}

AND draw_ground_point(x, y) BE
{ LET gx, gy, gz = ?, ?, ?
//newline()
//writef("draw_ground_point: x=%n y=%n*n", x, y)
//writef("draw_ground_point: cgx=%n cgy=%n cgz=%n*n", cgx, cgy, cgz)
  IF screencoords(x-cgx-eyex, y-cgy-eyey, -cgz-eyez, @gx) DO
  { drawrect(gx, gy, gx+1, gy+1)
    //updatescreen()
  }
}

AND tarmac() BE
{ LET cx, cy = (cgx/5_000) * 5_000, ((cgy-2_500)/5_000) * 5_000
//writef("tarmac: cx=%9.3d  cy=%9.3d*n", cx, cy)
  FOR x = cx-20_000 TO cx+150_000 BY 10_000 DO
  { FOR y = cy-10_000 TO cy+5_000 BY 5_000 DO
    { LET r = ABS(3*x + 5*y) MOD 67
      TEST 0<=x<3000_000 & -50_000 <= y < 50_000
      THEN setcolour(maprgb(180+r,180+r,180+r))
      ELSE setcolour(maprgb( 80+r,180+r, 40+r))
      gdrawquad3d(x,        y,       0,
                  x+10_000, y,       0,
                  x+10_000, y+5_000, 0,
                  x,        y+5_000, 0)
    }
  }
}

AND drawgroundpoints() BE
{ 
  setcolour(col_white)
  draw_ground_point(       0, 0)  // Start of runway
  FOR x = 0 TO 3000_000 BY 100_000 DO
  { draw_ground_point(x, -50_000) // Runway side lights
    draw_ground_point(x, +50_000)
  }
  draw_ground_point(3000_000, 0)  // End of runway

  FOR k = 1000_000 TO 10000_000 BY 1000_000 DO
  { // Draw beacon lights
    setcolour(col_lightmajenta)
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
    cgx, cgy, cgz    := 30_000,  0,  5_000

    tdot, wdot, ldot    := 0, 0, 0      // Stationary
    rtdot, rwdot, rldot := 0, 0, 0

    ctx, cty, ctz := One,      0,      0  // Direction cosines with
    cwx, cwy, cwz :=   0,    One, 100000  // six decimal digits
    clx, cly, clz :=   0,-100000,    One  // after to decimal point.

    ft1,  fw1,  fl1  := 0, 0, 0 // Previous linear forces
    rft1, rfw1, rfl1 := 0, 0, 0 // Previous rotational forces

    stepping := TRUE
    crashed := FALSE
    enginestarted, rpm := FALSE, 0
    targetrpm := rpm
    RETURN

  CASE 2: // Position on the glide slope
    cgx, cgy, cgz    := -10_000_000,  0,  1000_000  // height of 1000 ft

    tdot, wdot, ldot :=   100_000,  0,     0      // 100 ft/s in direction t
    rtdot, rwdot, rldot := 0, 0, 0

    ctx, cty, ctz := One,   0,   0  // Direction cosines with
    cwx, cwy, cwz :=   0, One,   0  // six decimal digits
    clx, cly, clz :=   0,   0, One  // after to decimal point.

    ft1,  fw1,  fl1  := 0, 0, 0 // Previous linear forces
    rft1, rfw1, rfl1 := 0, 0, 0 // Previous rotational forces

    stepping := TRUE
    crashed := FALSE
    enginestarted, rpm := TRUE, 1600
    targetrpm := rpm
    RETURN
}

LET start() = VALOF
{ done := FALSE

  cetx, cety, cetz := ctx, cty, ctz
  cewx, cewy, cewz := cwx, cwy, cwz
  celx, cely, celz := clx, cly, clz

  eyex, eyey, eyez := 0, 0, 0   // Relative eye position
  //hatdir, hatmsecs, eyedir := 0, 0, 0
  hatdir, hatmsecs := #b0001, 0 // From behind
  eyedir := 1
  eyedist := 60_000  // Eye x or y distance from aircraft

  cockpitz := 6_000   // Cockpit 8 feet above the ground

  c_throttle, c_elevator, c_aileron, c_rudder := 0, 0, 0, 0
  c_trimthrottle, c_trimelevator, c_trimaileron, c_trimrudder := 0, 0, 0, 0

  // Set rotational damping parameters 
  rdt,   rdw,  rdl := 500, 500, 950

  ft,      fw,    fl  := 0, 0, 0
  ft1,    fw1,   fl1  := 0, 0, 0
  rft,    rfw,   rfl  := 0, 0, 0
  rft1,  rfw1,  rfl1  := 0, 0, 0
  rtdot, rwdot, rldot := 0, 0, 0
  //writef("%i7 %i7 %i7*n", cgx/1000,   cgy/1000, cgz/1000)

  usage := 0
  testing := FALSE

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

  initposition(1) // Ready for takeoff
  //initposition(2) // On glide slope

  plotscreen()

  done := FALSE
  debugging := FALSE
  plotusage := FALSE

  IF FALSE DO
  { // Test rdtab
    FOR a = -180_000 TO 180_000 BY 1000 DO
    { LET t = TABLE 5, -180_000,0, 0,360, 180_000,0
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
  //aircraft := 0 // The default aircraft -- the dart
  done := FALSE

  UNTIL done DO
  { // Read joystick and keyboard events
    LET t0 = sdlmsecs()
    LET t1 = ?

//writef("Calling processevents*n")
    processevents()

    IF c_elevator<-32767 DO c_elevator := -32767
    IF c_elevator> 32767 DO c_elevator :=  32767
    IF c_aileron <-32767 DO c_aileron  := -32767
    IF c_aileron > 32767 DO c_aileron  :=  32767
    IF c_rudder  <-32767 DO c_rudder   := -32767
    IF c_rudder  > 32767 DO c_rudder   :=  32767
    IF c_throttle  <     0 DO c_throttle :=     0
    IF c_throttle  > 65535 DO c_throttle := 65535

    IF stepping DO step()

    //writef("x=%9.3d y=%9.3d h=%9.3d tdot=%9.3d*n", cgx, cgy, cgz, tdot)
    plotscreen()
//writef("Calling updatescreen*n")
    updatescreen()

    IF cgz<0 | (cgz < 2_000 & clz<0_850000) DO
    { crashed := TRUE
      stepping := FALSE
    }

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
  LET my = screenysize - 70 - 100

  seteyeposition()

  fillsurf(col_blue)

  setcolour(col_lightcyan)
  
  //writef("done=%n*n", done)
  drawstring(240, 50, done -> "Quitting", "Tiger Moth Flight Simulator")


  setcolour(col_white) // Draw runway line
  moveto(mx-1, my)
  drawby(0, 3000_000/100_000)
  moveto(mx,   my)
  drawby(0, 3000_000/100_000)
  moveto(mx+1, my)
  drawby(0, 3000_000/100_000)

  { LET dx, dy = ctx/50_000, cty/50_000
    LET x, y = mx-cgy/100_000, my+cgx/100_000
    setcolour(col_red) // Draw aircraft symbol
    moveto(x-dy/4, y+dx/4) // Fuselage
    drawby(+dy, -dx)
    setcolour(col_green)
    moveto( x-dx/2,  y-dy/2) // Wings
    drawby(+dx, +dy)
  }

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

  { LET pos = muldiv(40, c_throttle, 32768)
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

  //setcolour(col_majenta)
  //moveto(mx+200, my)
  //drawby(ctx/20_000, cty/20_000)


  setcolour(col_white)

  { LET heading = angle(cgxdot, -cgydot)/1000
    IF heading<0 DO heading := heading +360
    plotf(20, screenysize-20,
          "%i5 MPH  %i6 ft rate %i4  Heading %i3",
           muldiv(tdot, 60*60, 5280_000), cgz/1000, cgzdot/1000, heading)
    plotf(20, screenysize-40, "%i5 RPM", rpm)
  }

  IF debugging DO
  { plotf(20, my,     "Throttle=%6i Elevator=%6i Aileron=%6i Rudder=%6i",
                      c_throttle, c_elevator, c_aileron, c_rudder)
    plotf(20, my- 15, "x=   %9.3d y=   %9.3d z=   %9.3d", cgx,  cgy,  cgz)
    plotf(20, my- 30, "tdot=%9.3d wdot=%9.3d ldot=%9.3d", tdot, wdot, ldot)
    plotf(20, my- 45, "atl= %9.3d atw= %9.3d awl= %9.3d", atl,  atw,  awl)
    plotf(20, my- 60, "ct   %9.6d %9.6d %9.6d", ctx,cty,ctz)
    plotf(20, my- 75, "cw   %9.6d %9.6d %9.6d", cwx,cwy,cwz)
    plotf(20, my- 90, "cl   %9.6d %9.6d %9.6d", clx,cly,clz)
    plotf(20, my-105, "ft  =%9.3d fw =%9.3d fl =%9.3d", ft, fw, fl)
    plotf(20, my-120, "rft =%9.6d rfw=%9.6d rfl=%9.6d", rft,rfw,rfl)
  }

  IF plotusage DO
  { plotf(20, my-135, "CPU usage = %3i%%", usage)
  }

  drawgroundpoints()
  IF eyedir DO plotcraft()

  // Set pilot's view
  cetx, cety, cetz := ctx, cty, ctz
  cewx, cewy, cewz := cwx, cwy, cwz
  celx, cely, celz := clx, cly, clz
  eyex, eyey, eyez := 0, 0, 0   // Relative eye position

  draw_artificial_horizon()

  updatescreen()
}

AND seteyeposition0() BE
{ cetx, cety, cetz :=  One,   0,   0
  cewx, cewy, cewz :=    0, One,   0
  celx, cely, celz :=    0,   0, One
  // Set eye position relative to CG of the aircraft
  eyex, eyey, eyez :=  -eyedist,   0, 0
}

AND seteyeposition() BE
{ LET d1 = eyedist
  LET d2 = d1*707/1000
  LET d3 = d2/9

  cetx, cety, cetz :=  One,   0,   0
  cewx, cewy, cewz :=    0, One,   0
  celx, cely, celz :=    0,   0, One
  // Set eye position relative to CG of the aircraft
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

//writef("ctx=%9.6d cty=%9.6d eyedir=%n  eyedist=%9.3d*n", ctx, cty, eyedir, eyedist)
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

      CASE 'T':  testing := ~testing;              LOOP

      CASE 'U':  plotusage := ~plotusage;          LOOP

      CASE 'G': // Position aircraft on the glide path
                initposition(2)
                LOOP

      CASE 'L': // Position the aircraft ready for take off
                initposition(1)
                LOOP

      CASE 'N': // Reduce eye distance
                eyedist := eyedist*5/6
                IF eyedist<10_000 DO eyedist := 10_000
                LOOP

      CASE 'F': // Increase eye distance
                eyedist := eyedist*6/5
                LOOP

      CASE 'A': aircraft := (aircraft+1) MOD 2;   LOOP

      CASE 'S': enginestarted := ~enginestarted;  LOOP

      CASE 'Z': IF c_throttle>=5000 DO
                { c_trimthrottle := c_trimthrottle - 5000
                  c_throttle := c_throttle-5000
                }
                LOOP
      CASE 'X': IF c_throttle<65536-5000 DO
                { c_trimthrottle := c_trimthrottle + 5000
                  c_throttle := c_throttle+5000
                }
                LOOP

      CASE ',':
      CASE '<': c_trimrudder := c_trimrudder - 2000
                c_rudder := c_rudder - 2000;       LOOP

      CASE '.':
      CASE '>': c_trimrudder := c_trimrudder + 2000
                c_rudder := c_rudder + 2000;       LOOP

      CASE '0': eyedir, hatdir := 0, 0;        LOOP // Pilot's view
      CASE '1': hatdir, hatmsecs := #b0001, 0; LOOP // From behind
      CASE '2': hatdir, hatmsecs := #b0011, 0; LOOP // From behind right
      CASE '3': hatdir, hatmsecs := #b0010, 0; LOOP // From right
      CASE '4': hatdir, hatmsecs := #b0110, 0; LOOP // From in front right
      CASE '5': hatdir, hatmsecs := #b0100, 0; LOOP // From in front
      CASE '6': hatdir, hatmsecs := #b1100, 0; LOOP // From in front left
      CASE '7': hatdir, hatmsecs := #b1000, 0; LOOP // From left
      CASE '8': hatdir, hatmsecs := #b1001, 0; LOOP // From behind left

      CASE sdle_arrowup:    c_trimelevator := c_trimelevator+2000
                            c_elevator := c_elevator+2000;         LOOP
      CASE sdle_arrowdown:  c_trimelevator := c_trimelevator-2000
                            c_elevator := c_elevator-2000;         LOOP
      CASE sdle_arrowright: c_trimaileron  := c_trimaileron +2000
                            c_aileron := c_aileron+2000;           LOOP
      CASE sdle_arrowleft:  c_trimaileron  := c_trimaileron -2000
                            c_aileron := c_aileron-2000;           LOOP
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
      CASE 2:   c_throttle := c_trimthrottle-value+32768;LOOP // Throttle
      CASE 3:   c_rudder   := c_trimrudder+value;        LOOP // Rudder
      CASE 4:                                            LOOP // Right throttle
    }
  }

  CASE sdle_joyhatmotion:
  { LET which = eventa1
    LET axis  = eventa2
    LET value = eventa3

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
    SWITCHON eventa2 INTO
    { DEFAULT:   LOOP
      CASE  7:     // Left rudder trim
              c_trimrudder := c_trimrudder - 1000
              c_rudder := c_rudder - 1000;          LOOP
      CASE  8:     // Right rudder trim
              c_trimrudder := c_trimrudder + 1000
              c_rudder := c_rudder + 1000;          LOOP
      CASE 11:     // Reduce eye distance
              eyedist := eyedist*5/6
              IF eyedist<10_000 DO eyedist := 10_000
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
