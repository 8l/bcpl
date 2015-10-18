/*

This is a simple demonstration of drawing in 3D.  It was also used as
a test harness to help design a 3d model of a Tigermoth for the flight
simulator.  This version attempts to use the OpenGL Graphics library
in the hope of gettting substantially improved graphics performance.

Implemented by Martin Richards (c) February 2012
*/

GET "libhdr"
GET "sdl.h"
GET "sdl.b"          // Insert the library source code
.
GET "libhdr"
GET "sdl.h"

MANIFEST {
  One = 1_000000     // Direction cosines scaling factor
                     // ie 6 decimal digits after the decimal point.
  Sps = 20           // Steps per second
}

GLOBAL {
  done:ug

  object       // =0 for an aircraft, =1 for a hollow cube
               // =2 coloured triangles, =3 for the tiger moth

  stepping     // =FALSE if not rotating the object

  c_elevator   // Controls
  c_aileron
  c_rudder
  c_thrust

  ctx; cty; ctz    // Direction cosines of direction t
  cwx; cwy; cwz    // Direction cosines of direction w
  clx; cly; clz    // Direction cosines of direction l

  cetx; cety; cetz // Eye direction cosines of direction t
  cewx; cewy; cewz // Eye direction cosines of direction w
  celx; cely; celz // Eye direction cosines of direction l

  eyex; eyey; eyez // Relative position of the eye
  eyedist          // Eye x or y distance from aircraft

  rtdot; rwdot; rldot // Rotation rates about t, w and l axes

  // Rotational forces are scaled with 6 digits after the decimal point
  // as are direction cosines.
  rft     // Rotational force about t axis
  rfw     // Rotational force about w axis
  rfl     // Rotational force about l axis

  cdrawquad3d
  cdrawtriangle3d
}

// Insert the definitition of drawtigermoth()
GET "drawtigermoth.b"

AND inprod(a,b,c, x,y,z) =
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

LET step() BE
{ // Apply rotational forces
  rtdot := -c_aileron  * 200 / Sps
  rwdot := -c_elevator * 200 / Sps
  rldot :=  c_rudder   * 200 / Sps

  rotate(rtdot/Sps, rwdot/Sps, rldot/Sps)
}

AND plotcraft() BE
{ IF depthscreen FOR i = 0 TO screenxsize*screenysize-1 DO
    depthscreen!i := maxint

  IF object=0 DO
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
    cdrawtriangle3d(-9_000,0,0_600, -12_000,0,0,  -13_000,0,4_000)

  }

  IF object=1 DO
  { // Create a coloured cube with side length 2s
    LET s = 10_000

    setcolour(maprgb(0,0,0))                // Front
    cdrawquad3d(s,-s,s, s,s,s, s,s,-s, s,-s,-s)
    setcolour(maprgb(255,255,255))          // Back
    cdrawquad3d(-s,-s,s, -s,s,s, -s,s,-s, -s,-s,-s)
    setcolour(maprgb(255,0,0))              // Left
    cdrawquad3d( s,s,s,  s,s,-s, -s,s,-s, -s,s,s)
    setcolour(maprgb(0,255,0))              // Right
    cdrawquad3d( s,-s,s,  s,-s,-s, -s,-s,-s, -s,-s,s)
  }

  IF object=2 DO
  { LET s = 10_000
    LET r =  muldiv(s, c_thrust, 32768)

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

  IF object=3 DO
  { // Tigermoth
    drawtigermoth()
  }
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

//writef("screencoords: x=%9.3d  y=%9.3d  z=%9.3d*n", x,y,z)
//writef("cetx=%9.6d  cety=%9.6d  cetz=%9.6d*n", cetx,cety,cetz)
//writef("cewx=%9.6d  cewy=%9.6d  cewz=%9.6d*n", cewx,cewy,cewz)
//writef("celx=%9.6d  cely=%9.6d  celz=%9.6d*n", celx,cely,celz)
//writef("eyex=%9.3d  eyey=%9.3d  eyez=%9.3d*n", eyex,eyey,eyez)
  // Test that the point is in view, ie at least 1.000ft in front
  // and no more than about 27 degrees (inverse tan 1/2) from the
  // direction of view.
  IF sz<1_000 &
    muldiv(sz, sz, 2000) >= muldiv(sx, sx, 1000) + muldiv(sy, sy, 1000)
    RESULTIS FALSE

  // A point screensize pixels away from the centre of the screen is
  // 45 degrees from the direction of view.
  // Note that many pixels in this range are off the screen.
  v!0 := -muldiv(sx, screensize, sz)*2  + screenxsize/2
  v!1 := +muldiv(sy, screensize, sz)*2  + screenysize/2
  v!2 := sz // This distance into the screen in arbitrary units, used
            // for hidden surface removal.
//writef("in view  position=(x=%i4  y=%i4  depth=%n)*n", v!0, v!1, sz)
//abort(1119)
  RESULTIS TRUE
}

AND plotscreen() BE
{ fillsurf(maprgb(100,100,255))
  seteyeposition()
  plotcraft()
}

AND seteyeposition() BE
{ cetx, cety, cetz :=  One,   0,   0
  cewx, cewy, cewz :=    0, One,   0
  celx, cely, celz :=    0,   0, One
  eyex, eyey, eyez :=  -eyedist,   0, 0   // Relative eye position
}

AND processevents() BE WHILE getevent() SWITCHON eventtype INTO
{ DEFAULT:
    LOOP

  CASE sdle_keydown:
    SWITCHON capitalch(eventa2) INTO
    { DEFAULT:  LOOP

      CASE 'Q': done := TRUE
                LOOP

      CASE 'S': // Select next object to display
                object := (object + 1) MOD 4
                LOOP

      CASE 'P': // Toggle stepping
                stepping := ~stepping
                LOOP

      CASE 'R': // Reset the orientation and rotation rate
                ctx, cty, ctz := One,   0,   0
                cwx, cwy, cwz :=   0, One,   0
                clx, cly, clz :=   0,   0, One
                rtdot, rwdot, rldot := 0, 0, 0
                LOOP

      CASE 'N': // Reduce eye distance
                eyedist := eyedist*5/6
                IF eyedist<65_000 DO eyedist := 65_000
                LOOP

      CASE 'F': // Increase eye distance
                eyedist := eyedist*6/5
                LOOP

      CASE 'Z': c_thrust := c_thrust-2048
                IF c_thrust<0 DO c_thrust := 0
                writef("c_thrust=%n*n", c_thrust)
                LOOP

      CASE 'X': c_thrust := c_thrust+2048
                IF c_thrust>32768 DO c_thrust := 32768
                writef("c_thrust=%n*n", c_thrust)
                LOOP

      CASE ',':
      CASE '<': c_rudder := c_rudder - 4096
                IF c_rudder<-32768 DO c_rudder := -32768
                writef("c_rudder=%n*n", c_rudder)
                LOOP

      CASE '.':
      CASE '>': c_rudder := c_rudder + 4096
                IF c_rudder> 32768 DO c_rudder := 32768
                writef("c_rudder=%n*n", c_rudder)
                LOOP

      CASE sdle_arrowup:
                c_elevator := c_elevator+4096
                IF c_elevator> 32768 DO c_elevator := 32768
                writef("c_elevator=%n*n", c_elevator)
                LOOP
      CASE sdle_arrowdown:
                c_elevator := c_elevator-4096
                IF c_elevator< -32768 DO c_elevator := -32768
                writef("c_elevator=%n*n", c_elevator)
                LOOP
      CASE sdle_arrowright:
                c_aileron := c_aileron+4096
                IF c_aileron> 32768 DO c_aileron := 32768
                writef("c_aileron=%n*n", c_aileron)
                LOOP
      CASE sdle_arrowleft:
                c_aileron := c_aileron-4096
                IF c_aileron< -32768 DO c_aileron := -32768
                writef("c_aileron=%n*n", c_aileron)
                LOOP
    }

  CASE sdle_quit:
    writef("QUIT*n");
    done := TRUE
    LOOP
}

LET start() = VALOF
{ // The initial direction cosines giving the orientation of
  // the object.
  ctx, cty, ctz := One,   0,   0  // The cosines are scaled with
  cwx, cwy, cwz :=   0, One,   0  // six decimal digits
  clx, cly, clz :=   0,   0, One  // after to decimal point.

  eyedist := 120_000  // Eye distance from the object.
  object := 3  // Tigermoth
  stepping := TRUE
  // Initial rate of rotation about each axis
  rtdot, rwdot, rldot := 0, 0, 0
  c_elevator, c_aileron, c_rudder, c_thrust := -4096*4, 4096*3, 4096*5, 10240

  initsdl()
  mkscreen("Draw 3D Demo", 800, 500)

  done := FALSE

  UNTIL done DO
  { processevents()
    IF stepping DO step()
    plotscreen()
    updatescreen()
    sdldelay(50)
  }

  writef("*nQuitting*n")
  sdldelay(1_000)
  closesdl()
  RESULTIS 0
}


