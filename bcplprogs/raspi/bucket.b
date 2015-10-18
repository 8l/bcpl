/* This is a simple bat and ball game

Implemented by Martin Richards (c) February 2013

History:

17/02/2013
Successfully reimplemented the first version, bucket0.b, to
make it much more efficient.
*/

SECTION "sdllib"
GET "libhdr"
GET "sdl.h"
GET "sdl.b"          // Insert the library source code
.
SECTION "bucket"
GET "libhdr"
GET "sdl.h"

MANIFEST {
  One  =    1_00000 // The constant 1.000 scaled with 5 decimal
                    // digits after the decimal point.
  OneK = 1000_00000

  batradius       = 12_00000
  ballradius      = 25_00000
  endradius       = 15_00000
  bucketthickness = 2 * endradius

  ag = 50_00000     // Gravity acceleration
}

GLOBAL {
  done:ug

  help         // Display help information
  stepping     // =FALSE if not stepping
  starting     // Trap door open
  started
  finished
  randombat    // If TRUE the bat is given random accelerations
  randbattime
  randbatx

  starttime    // Set when starting becomes FALSE
  displaytime  // Time to display
  usage
  displayusage
  debugging

  sps             // Steps per second, adjusted automatically

  bucketwallsurf  // Surface for the bucket walls
  bucketbasesurf  // Surface for the bucket base
  ball1surf       // Surfaces for the three balls
  ball2surf
  ball3surf
  batsurf         // Surface for the bat

  backcolour      // Background colour
  bucketcolour
  bucketendcolour
  ball1colour
  ball2colour
  ball3colour
  batcolour

  wall_lx      // Left wall
  wall_rx      // Right wall
  floor_yt     // Floor
  ceiling_yb   // Ceiling

  screen_xc

  bucket_lxl; bucket_lxc; bucket_lxr // Bucket left wall
  bucket_rxl; bucket_rxc; bucket_rxr // Bucket right wall
  bucket_tyb; bucket_tyc; bucket_tyt // Bucket top
  bucket_byb; bucket_byc; bucket_byt // Bucket base

  // Ball bounce limits
  xlim_lwall; xlim_rwall
  ylim_floor; ylim_ceiling
  xlim_bucket_ll; xlim_bucket_lc; xlim_bucket_lr 
  xlim_bucket_rl; xlim_bucket_rc; xlim_bucket_rr
  ylim_topt
  ylim_baseb; ylim_baset 
  ylim_bat

   // Positions, velocities and accelerations of the balls
  cgx1; cgy1; cgx1dot; cgy1dot; ax1; ay1
  cgx2; cgy2; cgx2dot; cgy2dot; ax2; ay2
  cgx3; cgy3; cgx3dot; cgy3dot; ax3; ay3

   // Position, velocity and acceleration of the bat
  batx; baty; batxdot; batydot; abatx; abaty
}

LET incontact(p1,p2, d) = VALOF
{ LET x1, y1 = p1!0, p1!1
  LET x2, y2 = p2!0, p2!1
  // (x1,y1) and (x2,y2) are the centres of two circles
  // The result is TRUE if these centres are less than d apart.
  LET dx, dy = x1-x2, y1-y2
  IF ABS dx > d | ABS dy > d RESULTIS FALSE
  IF muldiv(dx,dx,One) + muldiv(dy,dy,One) >
     muldiv(d,d,One) RESULTIS FALSE
  RESULTIS TRUE
}

AND cbounce(p1, p2, m1, m2) BE
{ // p1!0 and p1!1 are the x and y coordinates of a ball, bat or bucket end.
  // p1!2 and p1!3 are the corresponding velocities
  // p2!0 and p2!1 are the x and y coordinates of a ball.
  // p2!2 and p2!3 are the corresponding velocities
  // m1 and m2 are the masses of the two objects in arbitrary units
  // m2 = 0 if p1 is a bucket end.
  // m1=m2  if the collition is between two balls
  // m1=5 and m2=1 is for collisions between the bat and ball assuming the bat
  // has five times the mass of the ball.

  LET c = cosines(p2!0-p1!0, p2!1-p1!1) // Direction p1 to p2
  LET s = result2

  IF m2=0 DO
  { // Object 1 is fixed, ie a bucket corner
    LET xdot = p2!2
    LET ydot = p2!3
    // Transform to (t,w) coordinates
    // where t is in the direction of the two centres
    LET tdot = inprod(xdot,ydot,  c, s)
    LET wdot = inprod(xdot,ydot, -s, c)

    IF tdot>0 RETURN

    // Object 2 is getting closer so reverse tdot (but not wdot)
    // and transform back to world (x,y) coordinates.
    tdot := rebound(tdot) // Reverse tdot with some loss of energy
    // Transform back to real world (x,y) coordinates
    p2!2 := inprod(tdot, wdot, c, -s)
    p2!3 := inprod(tdot, wdot, s,  c)

    RETURN
  }

  IF m1=m2 DO
  { // Objects 1 and 2 are both balls of equal mass
    // Find the velocity of the centre of gravity
    LET cgxdot = (p1!2+p2!2)/2
    LET cgydot = (p1!3+p2!3)/2
    // Calculate the velocity of object 1
    // relative to the centre of gravity
    LET rx1dot = p1!2 - cgxdot
    LET ry1dot = p1!3 - cgydot
    // Transform to (t,w) coordinates
    LET t1dot = inprod(rx1dot,ry1dot,  c,s)
    LET w1dot = inprod(rx1dot,ry1dot, -s,c)

    IF t1dot<=0 RETURN

    // Reverse t1dot with some loss of energy
    t1dot := rebound(t1dot)

    // Transform back to (x,y) coordinates relative to cg
    rx1dot := inprod(t1dot,w1dot,  c,-s)
    ry1dot := inprod(t1dot,w1dot,  s, c)

    // Convert to world (x,y) coordinates
    p1!2 :=  rx1dot + cgxdot
    p1!3 :=  ry1dot + cgydot
    p2!2 := -rx1dot + cgxdot
    p2!3 := -ry1dot + cgydot

    // Apply a small repulsive force between balls
    p1!0 := p1!0 - muldiv(0_40000, c, One)
    p1!1 := p1!1 - muldiv(0_40000, s, One)
    p2!0 := p2!0 + muldiv(0_40000, c, One)
    p2!1 := p2!1 + muldiv(0_40000, s, One)

    RETURN
  }

  { // Object 1 is the bat and object 2 is a ball
    // Find the velocity of the centre of gravity
    LET cgxdot = (p1!2*m1+p2!2*m2)/(m1+m2)
    LET cgydot = (p1!3*m1+p2!3*m2)/(m1+m2)
    // Calculate the velocities of the two objects
    // relative to the centre of gravity
    LET rx1dot = p1!2 - cgxdot
    LET ry1dot = p1!3 - cgydot
    LET rx2dot = p2!2 - cgxdot
    LET ry2dot = p2!3 - cgydot
    // Transform to (t,w) coordinates
    LET t1dot = inprod(rx1dot,ry1dot,  c,s)
    LET w1dot = inprod(rx1dot,ry1dot, -s,c)
    LET t2dot = inprod(rx2dot,ry2dot,  c,s)
    LET w2dot = inprod(rx2dot,ry2dot, -s,c)

    IF t1dot<=0 RETURN

    // Reverse t1dot and t2dot with some loss of energy
    t1dot := rebound(t1dot)
    t2dot := rebound(t2dot)

    // Transform back to (x,y) coordinates relative to cg
    rx1dot := inprod(t1dot,w1dot,  c,-s)
    ry1dot := inprod(t1dot,w1dot,  s, c)
    rx2dot := inprod(t2dot,w2dot,  c,-s)
    ry2dot := inprod(t2dot,w2dot,  s, c)

    // Convert to world (x,y) coordinates
    p1!2 := rx1dot + cgxdot
    p1!3 := ry1dot + cgydot // The bat cannot move vertically
    p2!2 := rx2dot + cgxdot
    p2!3 := ry2dot + cgydot

    // Apply a small repulsive force
    p1!0 := p1!0 - muldiv(0_05000, c, One)
    p1!1 := p1!1 - muldiv(0_05000, s, One)
    p2!0 := p2!0 + muldiv(0_05000, c, One)
    p2!1 := p2!1 + muldiv(0_05000, s, One)

    RETURN
  }
}

AND rebound(vel) = vel/7 - vel // Returns the rebound speed of a bounce

AND cosines(dx, dy) = VALOF
{ LET d = ABS dx + ABS dy
  LET c = muldiv(dx, One, d)  // Approximate cos and sin
  LET s = muldiv(dy, One, d)  // Direction good, length not.
  LET a = muldiv(c,c,One)+muldiv(s,s,One) // 0.5 <= a <= 1.0
  d := 1_00000 // With this initial guess only 3 iterations
               // of Newton-Raphson are required.
//writef("a=%8.5d  d=%8.5d  d^2=%8.5d*n", a, d, muldiv(d,d,One))
  d := (d + muldiv(a, One, d))/2
//writef("a=%8.5d  d=%8.5d  d^2=%8.5d*n", a, d, muldiv(d,d,One))
  d := (d + muldiv(a, One, d))/2
//writef("a=%8.5d  d=%8.5d  d^2=%8.5d*n", a, d, muldiv(d,d,One))
  d := (d + muldiv(a, One, d))/2
//writef("a=%8.5d  d=%8.5d  d^2=%8.5d*n", a, d, muldiv(d,d,One))

  s := muldiv(s, One, d) // Corrected cos and sin
  c := muldiv(c, One, d)
//writef("dx=%10.5d  dy=%10.5d => cos=%8.5d sin=%8.5d*n", dx, dy, c, s)

  result2 := s
  RESULTIS c
}

AND inprod(dx, dy, c, s) = muldiv(dx, c, One) + muldiv(dy, s, One)

AND ballbounces(pv) BE 
{ // This function deals with bounces between the ball whose position
  // and velocity is specified by pv and the bat or any fixed surface.
  // It does not deal with ball on ball bounces.
  LET cx, cy, vx, vy = pv!0, pv!1, pv!2, pv!3
  TEST xlim_bucket_ll <= cx <= xlim_bucket_rr &
       ylim_baseb     <= cy <= ylim_topt
  THEN { // The ball cannot be in contact with the cieling, floor or
         // either wall so we only need to check for contact with
         // the bucket

         IF cy > bucket_tyc DO
         { LET ecx, ecy, evx, evy = bucket_lxc, bucket_tyc, 0, 0
           IF incontact(@ecx, pv, endradius+ballradius) DO
           { cbounce(@ecx, pv, 1, 0)
             // No other bounces possible
             RETURN
           }
           ecx := bucket_rxc
           IF incontact(@ecx, pv, endradius+ballradius) DO
           { cbounce(@ecx, pv, 1, 0)
             // No other bounces possible
             RETURN
           }
           // No other bounces possible
           RETURN
         }

         IF cy >= bucket_byc DO
         { // Possibly bouncing with bucket walls

           IF cx <= bucket_lxc DO
           { // Bounce with outside of bucket left wall
             pv!0 := xlim_bucket_ll
             IF vx>0 DO pv!2 := rebound(vx)
           }
           IF bucket_lxc < cx <= xlim_bucket_lr DO
           { // Bounce with inside of bucket left wall
             pv!0 := xlim_bucket_lr
             IF vx<0 DO pv!2 := rebound(vx)
           }
           IF xlim_bucket_rl <= cx < bucket_rxc DO
           { // Bounce with inside of bucket right wall
             pv!0 := xlim_bucket_rl
             IF vx>0 DO pv!2 := rebound(vx)
           }
           IF bucket_rxc < cx DO
           { // Bounce with outside of bucket right wall
             pv!0 := xlim_bucket_rr
             IF vx<0 DO pv!2 := rebound(vx)
           }
         }

         // Bounce with base
         UNLESS starting DO
         { // The bucket base is present
           IF bucket_lxc <= cx <= bucket_rxc DO
           {
             IF cy < bucket_byc DO
             { // Bounce on the outside of the base
               pv!1 := ylim_baseb
               IF vy>0 DO pv!3 := rebound(vy)
               // No other bounces are possible
               RETURN
             }
             IF bucket_byc <= cy <= ylim_baset DO
             { // Bounce on the top of the base
               pv!1 := ylim_baset
               IF vy<0 DO pv!3 := rebound(vy)
               // No other bounces are possible
               RETURN
             }
           }
         }

         // Bounces with the bottom corners
         IF cy < bucket_byc DO
         { LET ecx, ecy, evx, evy = bucket_lxc, bucket_byc, 0, 0
           IF incontact(@ecx, pv, endradius+ballradius) DO
           { // Bounce with bottom left corner
             cbounce(@ecx, pv, 1, 0)
             // No other bounces are possible
             RETURN
           }
           ecx := bucket_rxc
           IF incontact(@ecx, pv, endradius+ballradius) DO
           { // Bounce with bottom right corner
             cbounce(@ecx, pv, 1, 0)
             // No other bounces are possible
             RETURN
           }
         }
       }
  ELSE { // The ball can only be in contact with the bat, side walls,
         // ceiling or floor

         // Bouncing with the bat
         IF incontact(@batx, pv, batradius+ballradius) DO
         { pv!4, pv!5 := 0, 0
           cbounce(@batx, pv, 5, 1)
           batydot := 0 // Immediately damp out the bat's vertical motion
         }

         // Left wall bouncing
         IF cx <= xlim_lwall DO
         { pv!0 := xlim_lwall
           IF vx<0 DO pv!2 := rebound(vx)
         }

         // Right wall bouncing
         IF cx >= xlim_rwall DO
         { pv!0 := xlim_rwall
           IF vx>0 DO pv!2 := rebound(vx)
         }

         // Ceiling bouncing
         IF cy >= ylim_ceiling DO
         { pv!1 := ylim_ceiling
           IF vy>0 DO pv!3 := rebound(vy)
           // No other bounces are possible
           RETURN
         }

         // Floor bouncing
         IF cy <= ylim_floor DO
         { pv!1 := ylim_floor
           IF vy<0 DO pv!3 := rebound(vy)
         }

         // No other bounces are possible
         RETURN
       }
}

LET step() BE
{ IF started UNLESS finished DO
    displaytime := sdlmsecs() - starttime

  // Check whether to close the base
  WHILE starting DO
  { IF ylim_baseb < cgy1 & bucket_lxc < cgx1 < bucket_rxc BREAK  
    IF ylim_baseb < cgy2 & bucket_lxc < cgx2 < bucket_rxc BREAK  
    IF ylim_baseb < cgy3 & bucket_lxc < cgx3 < bucket_rxc BREAK
    starting := FALSE
    started := TRUE
    finished := FALSE
    starttime := sdlmsecs()
    displaytime := 0
    BREAK  
  }

  IF started UNLESS finished DO
    IF bucket_byt < cgy1 < bucket_tyb &
       bucket_lxc < cgx1 < bucket_rxc &
       bucket_byt < cgy2 < bucket_tyb &
       bucket_lxc < cgx2 < bucket_rxc &
       bucket_byt < cgy3 < bucket_tyb &
       bucket_lxc < cgx3 < bucket_rxc &
       ABS cgy1dot < 2_00000 &
       ABS cgy2dot < 2_00000 &
       ABS cgy3dot < 2_00000 DO finished := TRUE

  // Calculate the accelerations of the balls
  // Initialise as apply gravity
  ax1, ay1 := 0, -ag
  ax2, ay2 := 0, -ag
  ax3, ay3 := 0, -ag

  // Add a little random horizontal motion
  ax1 := ax1 + randno(2001) - 1001
  ax2 := ax2 + randno(2001) - 1001
  ax3 := ax3 + randno(2001) - 1001

  ballbounces(@cgx1)
  ballbounces(@cgx2)
  ballbounces(@cgx3)

  // Ball on ball bounce
  IF incontact(@cgx1, @cgx2, ballradius+ballradius) DO
  { ay1, ay2 := 0, 0
    cbounce(@cgx1, @cgx2, 1, 1)
  }

  IF incontact(@cgx1, @cgx3, ballradius+ballradius) DO
  { ay1, ay3 := 0, 0
    cbounce(@cgx1, @cgx3, 1, 1)
  }

  IF incontact(@cgx2, @cgx3, ballradius+ballradius) DO
  { ay2, ay3 := 0, 0
    cbounce(@cgx2, @cgx3, 1, 1)
  }

  // Apply forces to the balls
  cgx1dot := cgx1dot + ax1/sps
  cgy1dot := cgy1dot + ay1/sps
  cgx2dot := cgx2dot + ax2/sps
  cgy2dot := cgy2dot + ay2/sps
  cgx3dot := cgx3dot + ax3/sps
  cgy3dot := cgy3dot + ay3/sps

  cgx1, cgy1 := cgx1 + cgx1dot/sps, cgy1 + cgy1dot/sps
  cgx2, cgy2 := cgx2 + cgx2dot/sps, cgy2 + cgy2dot/sps
  cgx3, cgy3 := cgx3 + cgx3dot/sps, cgy3 + cgy3dot/sps

  IF randombat DO
  { LET t = sdlmsecs()
    IF t > randbattime + 0_500 DO
    { // Choose a new random target x position every 1/10 second
      LET xmax = screenxsize*One
      randbatx := randno(xmax)
      IF randno(1000)<500 DO
      { // About 50% of the time choose as target the x position
        // depending on the position of the lowest ball to the bat.
        LET miny = cgy1
        randbatx := cgx1
        IF cgy2<miny DO randbatx, miny := cgx2, cgy2
        IF cgy3<miny DO randbatx, miny := cgx3, cgy3
      }
      randbattime := t
    }
    TEST batx > randbatx THEN abatx := -500_00000
                         ELSE abatx :=  500_00000
  }

  // Apply forces to the bat
  batxdot := batxdot + abatx/sps
  IF batxdot> 600_00000 DO batxdot :=  600_00000
  IF batxdot<-600_00000 DO batxdot := -600_00000

  batx := batx + batxdot/sps

  IF batx+batradius > wall_rx DO
  { batx := wall_rx - batradius
    batxdot := -batxdot
  }
  IF batx-batradius < 0 DO
  { batx := batradius
    batxdot := -batxdot
  }

  // Slowly correct baty
  baty := baty - (baty - batradius)/10
}

AND initbucketwallsurf() = VALOF
{ // Allocate a surface for the bucket walls
  LET width  = 2*endradius/One + 1
  LET height = (bucket_tyt - bucket_byb)/One + 2
  LET surf = mksurface(width, height)

  selectsurface(surf, width, height)
  fillsurf(backcolour)

  // Draw the ends
  TEST debugging
  THEN setcolour(bucketendcolour)
  ELSE setcolour(bucketcolour)
  drawfillcircle(endradius/One, endradius/One, endradius/One-1)
  drawfillcircle(endradius/One, height-endradius/One, endradius/One-1)

  // Draw the wall
  setcolour(bucketcolour)
  drawfillrect(0, endradius/One, width, height-endradius/One)
  RESULTIS surf
}

AND initbucketbasesurf(col) = VALOF
{ // Allocate the bucket base surface
  LET height  = 2*endradius/One + 1
  LET width = (bucket_rxc - bucket_lxc)/One + 1
  LET surf = mksurface(width, height)

  selectsurface(surf, width, height)
  fillsurf(backcolour)
  setcolour(bucketcolour)
  drawfillrect(0, 0, width, height)
  RESULTIS surf
}

AND initballsurf(col) = VALOF
{ // Allocate a ball surface
  LET height = 2*ballradius/One + 2
  LET width  = height
  LET colkey = maprgb(64,64,64)
  LET surf = mksurface(width, height)

  selectsurface(surf, width, height)
  fillsurf(colkey)
  setcolourkey(surf, colkey)

  setcolour(col)
  drawfillcircle(ballradius/One, ballradius/One+1, ballradius/One)

  RESULTIS surf
}

AND initbatsurf(col) = VALOF
{ // Allocate a bat surface
  LET height = 2*batradius/One + 2
  LET width  = height
  LET surf = mksurface(width, height)
  selectsurface(surf, width, height)
  fillsurf(backcolour)

  setcolour(batcolour)
  drawfillcircle(batradius/One, batradius/One+1, batradius/One)

  RESULTIS surf
}

AND plotscreen() BE
{ selectsurface(screen, screenxsize, screenysize)
  fillsurf(backcolour)

  // Allocate the surfaces if necessary
  UNLESS bucketwallsurf DO bucketwallsurf := initbucketwallsurf()
  UNLESS starting |
         bucketbasesurf DO bucketbasesurf := initbucketbasesurf()
  UNLESS ball1surf      DO ball1surf      := initballsurf(ball1colour)
  UNLESS ball2surf      DO ball2surf      := initballsurf(ball2colour)
  UNLESS ball3surf      DO ball3surf      := initballsurf(ball3colour)
  UNLESS batsurf        DO batsurf        := initbatsurf(batcolour)

  // Left bucket wall
  blitsurf(bucketwallsurf, screen, bucket_lxl/One, bucket_tyt/One)
  // Right bucket wall
  blitsurf(bucketwallsurf, screen, bucket_rxl/One, bucket_tyt/One)

  IF bucketbasesurf DO
     blitsurf(bucketbasesurf, screen, bucket_lxc/One, bucket_byt/One-1)

  // The bat
  blitsurf(batsurf, screen, (batx-batradius)/One, (baty+batradius)/One)

  IF debugging & randombat DO
  { setcolour(bucketcolour)
    drawfillcircle(randbatx/One, baty/One, 7)
  }

  // Finally, the three balls
  blitsurf(ball1surf, screen, (cgx1-ballradius)/One, (cgy1+ballradius)/One)
  blitsurf(ball2surf, screen, (cgx2-ballradius)/One, (cgy2+ballradius)/One)
  blitsurf(ball3surf, screen, (cgx3-ballradius)/One, (cgy3+ballradius)/One)

  setcolour(maprgb(255,255,255))
  
  IF finished DO
    plotf(30, 300, "Finished -- Well Done!")

  IF started | finished DO
    plotf(30, 280, "Time %9.2d", displaytime/10)

  IF help DO
  { plotf(30, 150, "R  -- Reset")
    plotf(30, 135, "S  -- Start the game")
    plotf(30, 120, "P  -- Pause/Continue")
    plotf(30, 105, "H  -- Toggle help information")
    plotf(30,  90, "B  -- Toggle bat random motion")
    plotf(30,  75, "D  -- Toggle debugging")
    plotf(30,  60, "U  -- Toggle usage")
    plotf(30,  45, "Left/Right arrow -- Control the bat")
  }

  IF displayusage DO
    plotf(30, 245, "CPU usage = %i3%% sps = %n", usage, sps)

  IF debugging DO
  { plotf(30, 220, "Ball1 x=%10.5d  y=%10.5d xdot=%10.5d  ydot=%10.5d",
          cgx1, cgy1, cgx1dot, cgy1dot)
    plotf(30, 205, "Ball2 x=%10.5d  y=%10.5d xdot=%10.5d  ydot=%10.5d",
          cgx2, cgy2, cgx2dot, cgy2dot)
    plotf(30, 190, "Ball3 x=%10.5d  y=%10.5d xdot=%10.5d  ydot=%10.5d",
          cgx3, cgy3, cgx3dot, cgy3dot)
    plotf(30, 175, "Bat   x=%10.5d  y=%10.5d xdot=%10.5d",
          batx, baty, batxdot)
  }
}

AND resetballs() BE
{ cgy1 := bucket_byt+ballradius   + 10_00000
  cgy2 := bucket_byt+3*ballradius + 20_00000
  cgy3 := bucket_byt+5*ballradius + 30_00000
  cgx1, cgx2, cgx3 := screen_xc, screen_xc, screen_xc 
  cgx1dot, cgx2dot, cgx3dot :=  0, 0, 0
  cgy1dot, cgy2dot, cgy3dot :=  0, 0, 0

  starting    := FALSE
  started     := FALSE
  finished    := FALSE
  displaytime := -1
}

AND processevents() BE WHILE getevent() SWITCHON eventtype INTO
{ DEFAULT:
    LOOP

  CASE sdle_keydown:
    SWITCHON capitalch(eventa2) INTO
    { DEFAULT:  LOOP

      CASE 'Q': done := TRUE
                LOOP

      CASE '?':
      CASE 'H': help := ~help
                LOOP

      CASE 'D': debugging := ~debugging
                IF bucketwallsurf DO
                { freesurface(bucketwallsurf)
                  bucketwallsurf := 0
                }
                LOOP

      CASE 'U': displayusage := ~displayusage
                LOOP

      CASE 'B': randombat := ~randombat
                abatx := 0
                randbatx := screen_xc
                randbattime := 0
                LOOP

      CASE 'S': // Start again
                UNLESS ylim_baseb < cgy1 & bucket_lxc < cgx1 < bucket_rxc &
                       ylim_baseb < cgy2 & bucket_lxc < cgx2 < bucket_rxc &
                       ylim_baseb < cgy3 & bucket_lxc < cgx3 < bucket_rxc DO
                  resetballs()
                starting := TRUE
                started := FALSE
                finished := FALSE
                starttime := -1
                displaytime := -1
                IF bucketbasesurf DO
                { freesurface(bucketbasesurf)
                  bucketbasesurf := 0
                }
                LOOP

      CASE 'P': // Toggle stepping
                stepping := ~stepping
                LOOP

      CASE 'R': // Reset the balls
                resetballs()
                finished := FALSE
                starting := FALSE
                displaytime := -1
                LOOP

      CASE sdle_arrowright:
                abatx := abatx + 750_00000; LOOP
      CASE sdle_arrowleft:
                abatx := abatx - 750_00000; LOOP
    }

  CASE sdle_keyup:
    SWITCHON capitalch(eventa2) INTO
    { DEFAULT:  LOOP

      CASE sdle_arrowright:
                abatx := abatx - 750_00000; LOOP
      CASE sdle_arrowleft:
                abatx := abatx + 750_00000; LOOP
    }


  CASE sdle_quit:
    writef("QUIT*n");
    done := TRUE
    LOOP
}

LET start() = VALOF
{ LET stepmsecs = ?
  LET comptime  = 0 // Amount of cpu time per frame

  UNLESS sys(Sys_sdl, sdl_avail) DO
  { writef("*nThe SDL features are not available*n")
    RESULTIS 0
  }

  bucketwallsurf := 0
  bucketbasesurf := 0
  ball1surf := 0
  ball2surf := 0
  ball3surf := 0
  batsurf := 0

  IF FALSE DO
  { // Code to test the cosines function
    LET e1, e2 = One, One
    FOR dy = 0 TO One BY One/100 DO
    { LET c, s, rsq = ?, ?, ?
      c := cosines(One, dy)
      s := result2
      rsq := muldiv(c,c,One) + muldiv(s,s,One)
      writef("dx=%9.5d  dy=%9.5d cos=%9.5d sin=%9.5d rsq=%9.5d*n",
              One, dy, c, s, rsq)
      IF e1 < rsq DO e1 := rsq
      IF e2 > rsq DO e2 := rsq
    }
    writef("Errors +%6.5d  -%7.5d*n", e1-One, One-e2)
    RESULTIS 0
  }

  initsdl()
  mkscreen("Ball and Bucket", 800, 500)

  help := TRUE

  randombat := FALSE
  randbatx := screen_xc
  randbattime := 0

  stepping := TRUE     // =FALSE if not stepping
  starting := TRUE     // Trap door open
  started := FALSE
  finished := FALSE
  starttime := -1
  displaytime := -1
  usage := 0
  debugging := FALSE
  displayusage := FALSE
  sps := 40 // Initial setting
  stepmsecs := 1000/sps

  backcolour      := maprgb(120,120,120)
  bucketcolour    := maprgb(170, 60,  30)
  bucketendcolour := maprgb(140, 30,  30)
  ball1colour     := maprgb(255,  0,   0)
  ball2colour     := maprgb(  0,255,   0)
  ball3colour     := maprgb(  0,  0, 255)
  batcolour       := maprgb( 40, 40,  40)

  wall_lx := 0
  wall_rx := (screenxsize-1)*One      // Right wall

  floor_yt   := 0                     // Floor
  ceiling_yb := (screenysize-1)*One   // Ceiling

  screen_xc := screenxsize*One/2
  bucket_tyt := ceiling_yb - 6*ballradius
  bucket_tyc := bucket_tyt - endradius
  bucket_tyb := bucket_tyt - bucketthickness

  bucket_lxr := screen_xc  - ballradius * 5 / 2
  bucket_lxc := bucket_lxr - endradius
  bucket_lxl := bucket_lxr - bucketthickness

  bucket_rxl := screen_xc  + ballradius * 5 / 2
  bucket_rxc := bucket_rxl + endradius
  bucket_rxr := bucket_rxl + bucketthickness

  bucket_byt := bucket_tyt - 6*ballradius
  bucket_byc := bucket_byt - endradius
  bucket_byb := bucket_byt - bucketthickness

  xlim_lwall     := wall_lx    + ballradius
  xlim_rwall     := wall_rx    - ballradius
  ylim_floor     := floor_yt   + ballradius
  ylim_ceiling   := ceiling_yb - ballradius
  xlim_bucket_ll := bucket_lxl - ballradius
  xlim_bucket_lc := bucket_lxc - ballradius
  xlim_bucket_lr := bucket_lxr + ballradius
  xlim_bucket_rl := bucket_rxl - ballradius
  xlim_bucket_rc := bucket_rxc - ballradius
  xlim_bucket_rr := bucket_rxr + ballradius
  ylim_topt      := bucket_tyt + ballradius
  ylim_baseb     := bucket_byb - ballradius
  ylim_baset     := bucket_byt + ballradius

  resetballs()

  ax1, ay1 := 0, 0   // Acceleration of ball 1
  ax2, ay2 := 0, 0   // Acceleration of ball 2
  ax3, ay3 := 0, 0   // Acceleration of ball 3

  batx := screen_xc  // Position of bat
  baty := floor_yt + batradius   // Position of bat
  ylim_bat := floor_yt + batradius + ballradius

  batxdot, batydot := 150_00000, 0 // Velocity of bat
  abatx := 0         // Acceleration of bat

  done := FALSE

  UNTIL done DO
  { LET t0 = sdlmsecs()
    LET t1 = ?

    processevents()

    IF stepping DO step()

    usage := 100*comptime/stepmsecs
    plotscreen()
    updatescreen()
    UNLESS 80<usage<95 DO
    { TEST usage>90
      THEN sps := sps-1
      ELSE sps := sps+1
      stepmsecs := 1000/sps
    }

    t1 := sdlmsecs()

    comptime := t1 - t0
    IF t0+stepmsecs > t1 DO sdldelay(t0+stepmsecs-t1)
  }

  writef("*nQuitting*n")
  sdldelay(1_000)

  IF bucketwallsurf DO freesurface(bucketwallsurf)
  IF bucketbasesurf DO freesurface(bucketbasesurf)
  IF ball1surf      DO freesurface(ball1surf)
  IF ball2surf      DO freesurface(ball2surf)
  IF ball3surf      DO freesurface(ball3surf)
  IF batsurf        DO freesurface(batsurf)

  closesdl()
  RESULTIS 0
}


