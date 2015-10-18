/* This is a program that displays a number of robots designed to
pick up bottles with their grabbers and deposit them in a pit.

Implemented by Martin Richards (c) February 2015

History:

02/02/2015
Initial implementation started based on bucket.b.

*/

SECTION "sdllib"
GET "libhdr"
GET "sdl.h"
GET "sdl.b"          // Insert the library source code
.
SECTION "robots"
GET "libhdr"
GET "sdl.h"

MANIFEST {
  One  =    1_00000 // The constant 1.000 scaled with 5 decimal
                    // digits after the decimal point.
  OneK = 1000 * One

  spacevupb = 100000

  pitradius       = 50_00000
  bottleradius    =  5_00000
  robotradius     = 18_00000
  shoulderradius  =  3_00000
  tipradius       =  2_00000
  grablen         = 12_00000

  // bottle selectors
  b_cgx=0; b_cgy       // The first six must be in positions 0 to 5
  b_cgxdot; b_cgydot
  b_costheta; b_sintheta
  b_prevcgx; b_prevcgy
  b_grabbed
  b_robot     // 0 or the grabbing robot
  b_dropped
  b_id        // The bottle number

  b_size
  b_upb=b_size

  // robot selectors
  r_cgx=0;     r_cgy       // The first six must be in positions 0 to 5
  r_cgxdot;    r_cgydot
  r_costheta;  r_sintheta  // Changed every time cgxdot or cgydot changes
  r_grabpos;   r_grabposdot
  r_colour;    r_tipcolour
  r_bottle                 // =0 or the grabbed bottle
  // Coords of rotated robot shoulders
  r_lex;  r_ley;   r_rex;  r_rey  //    le       re
  r_lcx;  r_lcy;   r_rcx;  r_rcy  //    lc       rc
  // Coords of rotated robot arms
  r_ltax; r_ltay;  r_rtax; r_rtay //  ltd ltp ltc   rtc rtp rtd
  r_ltbx; r_ltby;  r_rtbx; r_rtby //
  r_ltcx; r_ltcy;  r_rtcx; r_rtcy //
  r_ltdx; r_ltdy;  r_rtdx; r_rtdy //
  r_ltpx; r_ltpy;  r_rtpx; r_rtpy //  lta     ltb   rtb     rta

  r_bcx;  r_bcy  // Centre of gripped bottle

  // The velocity of 
  r_id        // The robot number

  r_motionco
  r_strategyco

  r_size
  r_upb=r_size

  // Low level robot command
  com_turnleft=1
  com_turnleftslow
  com_gostraight
  com_turnrightslow
  com_turnright
  com_speedstop
  com_speedveryslow
  com_speedfast

  com_speedslower
  com_speedfaster

  com_grab
  com_release

  com_grabbottle      // Go and grab a specified bottle

}

GLOBAL {
  done:ug

  help         // Display help information
  stepping     // =FALSE if not stepping
  finished

  usage
  displayusage
  debugging

  sps             // Steps per second, adjusted automatically
  
  bottles
  bottlev
  robots
  robotv
  // coords of the pit centre
  pit_x; pit_y; pit_xdot; pit_ydot; pit_costheta; pit_sintheta
  thepit // -> [ pitx, pity, pit_xdot, pit_ydot, pit_costheta, pit_sintheta]
  xsize  // Window size in pixels
  ysize
  seed

  spacev; spacep; spacet
  mkvec

  bottlecount     // Decreases as bottle fall into the pit
  robotcount      // Set by the -r command argument

  bottlesurfR     // Surface for a red bottle
  bottlesurfK     // Surface for a black bottle (number 1)
  bottlesurfB     // Surface for a brown bottle (grabbed)
  pitsurf         // Surface for the bucket base
  
  backcolour      // Background colour
  col_red; col_black; col_brown
  pitcolour
  robotcolour
  robot1colour
  grabcolour

  wall_wx         // West wall
  wall_ex         // East wall
  wall_sy         // South wall
  wall_ny       // North wall

  motioncofn      // eg deal with requests like grab bottle b
  strategycofn    // eg find a bottle to grab, avoid other
                  // robots and walls, choose a rout to the pit,

  priq        // Heap structure for the time queue
  priqn       // Number of items in priq
  priqupb     // Upb of priq

  msecsnow    // Updated by step, possibly releasing
              // events in the priority queue
  msecs0      // Starting time since midnight
}

LET mkvec(upb) = VALOF
{ LET p = spacep
  spacep := spacep+upb+1
  IF spacep>spacet DO
  { writef("Insufficient space*n")
    abort(999)
    RESULTIS 0
  }
  //writef("mkvec(%n) => %n*n", upb, p)
  RESULTIS p
}

AND mk2(a, b) = VALOF
{ LET p = mkvec(1)
  p!0, p!1 := a, b
  RESULTIS p
}

LET incontact(p1,p2, d) = VALOF
{ // THis return TRUE if points p1 and p2 are less than d apart.
  LET x1, y1 = p1!0, p1!1
  LET x2, y2 = p2!0, p2!1
  // (x1,y1) and (x2,y2) are the centres of two circles
  // The result is TRUE if these centres are less than d apart.
  LET dx, dy = x1-x2, y1-y2
IF d=pitradius & ABS dx <= d+100000 & ABS dy <= d+100000 DO
{ writef("p1=(%n,%n) p2=(%n,%n) dx=%n dy=%n d=%n*n",
         x1,y1, x2,y2, dx,dy, d)
}
  IF ABS dx > d | ABS dy > d RESULTIS FALSE
  IF muldiv(dx,dx,One) + muldiv(dy,dy,One) >
     muldiv(d,d,One) RESULTIS FALSE
  RESULTIS TRUE
}

AND bouncerr(p1, p2) BE
{ // This deals with robot-robot bounces.
  LET c = cosines(p2!0-p1!0, p2!1-p1!1) // Direction p1 to p2
  LET s = result2
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
  t1dot := -t1dot/10

  // Transform back to (x,y) coordinates relative to cg
  rx1dot := inprod(t1dot,w1dot,  c,-s)
  ry1dot := inprod(t1dot,w1dot,  s, c)

  // Convert to world (x,y) coordinates
  p1!0 := p1!0 + 5*rx1dot/sps
  p1!1 := p1!1 + 5*ry1dot/sps
  //p1!2 :=  rx1dot + cgxdot
  //p1!3 :=  ry1dot + cgydot
  //p1!4 := cosines(p1!2, p1!3)
  //p1!5 := result2

  p2!0 := p2!0 - 5*rx1dot/sps
  p2!1 := p2!1 - 5*ry1dot/sps
  //p2!2 := -rx1dot + cgxdot
  //p2!3 := -ry1dot + cgydot
  //p2!4 := cosines(p2!2, p2!3)
  //p2!5 := result2
}

AND cbounce(p1, p2, m1, m2) BE
{ // p1!0 and p1!1 are the x and y coordinates of two circular object.
  // p1!2 and p1!3 are the corresponding velocities
  // p1!4 and p1!5 are the corresponding direction cosines
  // p2!0 and p2!1 are the x and y coordinates of another object.
  // p2!2 and p2!3 are the corresponding velocities
  // p2!4 and p3!5 are the corresponding direction cosines
  // m1 and m2 are the masses of the two objects in arbitrary units
  // m1=m2  if the collition is between two bottles or two robots.
  // m1=5 and m2=1 then p1 is a robot and p2 is a bottle.

  LET c = cosines(p2!0-p1!0, p2!1-p1!1) // Direction p1 to p2
  LET s = result2

  IF m2=0 DO
  { // Object 1 is a robot and object 2 is a bottle.
    // Robots are treated as infinitely heavy.
    LET xdot = p2!2 - p1!r_cgxdot
    LET ydot = p2!3 - p1!r_cgydot
    // Transform to (t,w) coordinates
    // where t is in the direction of the two centres
    LET tdot = inprod(xdot,ydot,  c, s)
    LET wdot = inprod(xdot,ydot, -s, c)

//writef("robot-bottle bounce tdot=%n wdot=%n*n", tdot, wdot)
    IF tdot>0 RETURN

    // Object 2 is getting closer so reverse tdot (but not wdot)
    // and transform back to world (x,y) coordinates.
    tdot := rebound(tdot) // Reverse tdot with some loss of energy
    // Transform back to real world (x,y) coordinates
    p2!2 := inprod(tdot, wdot, c, -s) + p1!r_cgxdot
    p2!3 := inprod(tdot, wdot, s,  c) + p1!r_cgydot
    p2!4 := cosines(p2!2, p2!3)
    p2!5 := result2
    RETURN
  }

  IF m1=m2 DO
  { // This deals with bottle-bottle and robot-robot bounces.
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
    p1!4 := cosines(p1!2, p1!3)
    p1!5 := result2

    p2!2 := -rx1dot + cgxdot
    p2!3 := -ry1dot + cgydot
    p2!4 := cosines(p2!2, p2!3)
    p2!5 := result2

    // Apply a small repulsive force between the objects.
    // This may not be necessary since there is no gravity.
    p1!0 := p1!0 - muldiv(0_40000, c, One)
    p1!1 := p1!1 - muldiv(0_40000, s, One)
    p2!0 := p2!0 + muldiv(0_40000, c, One)
    p2!1 := p2!1 + muldiv(0_40000, s, One)

    RETURN
  }

  { // Object 1 is a robot and object 2 is a bottle
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

//IF t1dot<=0 DO
IF FALSE DO
{ 
  writef("dir  =(%10.5d,%10.5d)*n", c, s)
  writef("p1   =(%10.5d,%10.5d)*n", p1!0, p1!1)
  writef("p2   =(%10.5d,%10.5d)*n", p2!0, p2!1)
  writef("p1dot=(%10.5d,%10.5d) m1=%n*n", p1!2, p1!3, m1)
  writef("p2dot=(%10.5d,%10.5d) m2=%n*n", p2!2, p2!3, m2)
  writef("cgdot=(%10.5d,%10.5d)*n", cgxdot, cgydot)
  writef("r1dot=(%10.5d,%10.5d)*n", rx1dot, ry1dot)
  writef("r2dot=(%10.5d,%10.5d)*n", rx2dot, ry2dot)
  writef("t1dot=(%10.5d,%10.5d)*n", t1dot, w1dot)
  writef("t2dot=(%10.5d,%10.5d)*n", t2dot, w2dot)
  writef("t1dot=%10.5d is the speed of the robot towards the centre of gravity*n", t1dot)
  abort(1000)
}
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
    p1!3 := ry1dot + cgydot
    // Calculate cosine and sine of new direction of motion
    p1!4 := cosines(p1!2, p1!3)
    p1!5 := result2

    p2!2 := rx2dot + cgxdot
    p2!3 := ry2dot + cgydot
    // Calculate cosine and sine of new direction of motion
    p2!4 := cosines(p2!2, p2!3)
    p2!5 := result2
  }
}

AND rebound(vel) = vel/10 - vel // Returns the rebound speed of a bounce

AND setdir(p) BE
{ // p -> [x, y, xdot, ydot, costheta, sintheta]
  // It sets costheta and sintheta based on xdot and ydot.
  // If xdot=ydot=0, costheta and sintheta remain unchanged.
  LET xdot, ydot = p!2, p!3
  IF xdot=0=ydot RETURN
  p!4 := cosines(xdot, ydot)
  p!5 := result2
}

AND cosines(x, y) = VALOF
{ // This function returns the cosine and sine of the angle between
  // the line from (0,0) to (x, y) and the x axis.
  // The result is the cosine and result2 is the sine. 
  LET d = ABS x + ABS y
  LET c = muldiv(x, One, d)  // Approximate cos and sin
  LET s = muldiv(y, One, d)  // Direction good, length not.
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

LET step() BE
{ msecsnow := sdlmsecs() - msecs0
  // Deal with crossing midnight assuming now is no more than
  // 24 hours since the start of the run.
  IF msecsnow<0 DO msecsnow := msecsnow + (24*60*60*1000)

  //writef("step: entered*n")
  IF bottlecount=0 DO finished := TRUE

  // Robots always point in their directions of motion given by
  // cgxdot and cgydot. The direction cosines costheta and sintheta
  // are calculated using setdir by robotcoords before returning from
  // step.  Interaction between robots and the walls, the pit, and
  // other robots affect cgxdot and cgydot.
 
  // Bottle bounces
  FOR i = 1 TO bottlev!0 DO
  { LET bi = bottlev!i  // bi -> [cgx, cgy, cgxdot, cgydot, costheta, sintheta]

    UNLESS bi!b_dropped DO
    { LET xi = bi!b_cgx
      LET yi = bi!b_cgy
      // Test for bottle west wall bounces
      IF xi < wall_wx + bottleradius + 2*robotradius DO
      { IF xi < wall_wx + bottleradius DO
        { xi := wall_wx + bottleradius
          bi!b_cgx := xi
         bi!b_cgxdot := - bi!b_cgxdot
        }
        bi!b_cgxdot := bi!b_cgxdot + 20_00000/sps
      }
      // Test for bottle east wall bounces
      IF xi > wall_ex - bottleradius - 2*robotradius DO
      { IF xi > wall_ex - bottleradius DO
        { xi := wall_ex - bottleradius
          bi!b_cgx := xi
          bi!b_cgxdot := - bi!b_cgxdot
        }
        bi!b_cgxdot := bi!b_cgxdot - 20_00000/sps
      }
      // Test for bottle south wall bounces
      IF yi < wall_sy + bottleradius + 2*robotradius DO
      { IF yi < wall_sy + bottleradius DO
        { yi := wall_sy + bottleradius
          bi!b_cgy := yi
          bi!b_cgydot := - bi!b_cgydot
        }
        bi!b_cgydot := bi!b_cgydot + 20_00000/sps
      }
      // Test for bottle north wall bounces
      IF yi > wall_ny - bottleradius - 2*robotradius DO
      { IF yi > wall_ny - bottleradius DO
        { yi := wall_ny - bottleradius
          bi!b_cgy := yi
          bi!b_cgydot := - bi!b_cgydot
        }
        bi!b_cgydot := bi!b_cgydot - 20_00000/sps
      }
      // Test for bottle-bottle bounces
      FOR j = i+1 TO bottlev!0 DO
      { LET bj = bottlev!j
        IF bj!b_dropped LOOP
        IF incontact(bi, bj, bottleradius+bottleradius) DO
          cbounce(bi, bj, 1, 1)
      }
    }
  }

  // Test for robot bounces
  FOR i = 1 TO robotv!0 DO
  { LET r = robotv!i
    LET x = r!r_cgx
    LET y = r!r_cgy

    // Test for robot west wall bounces
    IF x < wall_wx + 3*robotradius DO
    { IF x < wall_wx + robotradius DO
      { r!r_cgx := wall_wx + robotradius
        r!r_cgxdot :=  - r!r_cgxdot
      }
      r!r_cgxdot := r!r_cgxdot + 12_00000/sps
    }

    // Test for robot east wall bounces
    IF x > wall_ex - 3*robotradius DO
    { IF x > wall_ex - robotradius DO
      { r!r_cgx := wall_ex - robotradius
        r!r_cgxdot :=  - r!r_cgxdot
      }
      r!r_cgxdot := r!r_cgxdot - 12_00000/sps
    }
    // Test for robot south wall bounces
    IF y < wall_sy + 3*robotradius DO
    { IF y < wall_sy + robotradius DO
      { r!r_cgy := wall_sy + robotradius
        r!r_cgydot :=  - r!r_cgydot
      }
      r!r_cgydot := r!r_cgydot + 12_00000/sps
    }
    // Test for robot north wall bounces
    IF y > wall_ny - 3*robotradius DO
    { IF y > wall_ny - robotradius DO
      { r!r_cgy := wall_ny - robotradius
        r!r_cgydot :=  - r!r_cgydot
      }
      r!r_cgydot := r!r_cgydot - 12_00000/sps
    }
    // Test for robot pit bounces
    IF FALSE & incontact(r, thepit, 3*robotradius+pitradius) DO
    { LET dx = r!r_cgx - pit_x
      LET dy = r!r_cgy - pit_y
      // Calculate the dirction from the pit centre to the robot.
      LET c = cosines(dx, dy)
      LET s = result2
      r!r_cgxdot := r!r_cgxdot + muldiv(2_00000/sps, c, One)
      r!r_cgydot := r!r_cgydot + muldiv(2_00000/sps, s, One)
      IF i=-1 DO
      { writef("Robot %n is near the pit*n", i)
        writef("Robot %n cg (%10.5d,%10.5d)*n", i, r!r_cgx, r!r_cgy)
        writef("Pit centre  (%10.5d,%10.5d)*n", pit_x, pit_y)
      }
    }

    // Test for robot-bottle bounces
    FOR j = 1 TO bottlev!0 DO
    { LET b = bottlev!j
      UNLESS b!b_dropped DO
      { UNLESS incontact(r, b, 8*robotradius) LOOP
        // This robot is near this bottle
IF i=0 DO writef("robot %n near bottle %n*n", i, j)

        // Test for robot body-bottle bounce
        IF incontact(r, b, robotradius+bottleradius) DO
        { // They are in contact so make the bottle bounce off
          //IF i=1 DO writef("Robot %n in contact with bottle %n*n", i, j)
          //cbounce(r, b, 10, 1) // Robot is 10 times heavier than a bottle
          cbounce(r, b, 1, 0) // Robot is heavy
        }

        // Test for left shoulder-bottle bounce
        { LET sx, sy, sxdot, sydot, sct, sst =
              r!r_lcx, r!r_lcy,
              r!r_cgxdot, r!r_cgydot, 0, 0
          LET s = @sx
          IF incontact(s, b, shoulderradius+bottleradius) DO
          { // They are in contact so make the bottle bounce off
            //IF i=1 DO writef("Robot %n in contact with bottle %n*n", i, j)
            cbounce(s, b, 1, 0) // Robot is heavy
          }
        }

        // Test for right shoulder-bottle bounce
        { LET sx, sy, sxdot, sydot, sct, sst =
              r!r_rcx, r!r_rcy,
              r!r_cgxdot, r!r_cgydot, 0, 0
          LET s = @sx 
          IF incontact(s, b, shoulderradius+bottleradius) DO
          { // They are in contact so make the bottle bounce off
            //IF i=1 DO writef("Robot %n in contact with bottle %n*n", i, j)
            //cbounce(s, b, 10, 1) // Shoulder is 10 times heavier than a bottle
            cbounce(s, b, 1, 0) // Robot is heavy
          }
        }

        // Test for robot left tip bounce
        { LET sx, sy, sxdot, sydot, sct, sst =
              r!r_ltcx, r!r_ltcy,
              r!r_cgxdot, r!r_cgydot, 0, 0
          LET s = @sx 
          IF incontact(s, b, tipradius+bottleradius) DO
          { // They are in contact so make the bottle bounce off
            //IF i=1 DO writef("Robot %n in contact with bottle %n*n", i, j)
            cbounce(s, b, 1, 0) // Robot is heavy
          }
        }

        // Test for robot right tip bounce
        { LET sx, sy, sxdot, sydot, sct, sst =
              r!r_rtcx, r!r_rtcy,
              r!r_cgxdot, r!r_cgydot, 0, 0
          LET s = @sx 
          IF incontact(s, b, tipradius+bottleradius) DO
          { // They are in contact so make the bottle bounce off
            //IF i=1 DO writef("Robot %n in contact with bottle %n*n", i, j)
            //cbounce(s, b, 10, 1) // Shoulder is 10 times heavier than a bottle
            cbounce(s, b, 1, 0) // Robot is heavy
          }
        }

        // Test for robot grabber bounces
        { // Make the robot's centre to origin
          LET bx = b!b_cgx - r!r_cgx
          LET by = b!b_cgy - r!r_cgy
          LET c = r!r_costheta // Direction cosines of the robot
          LET s = r!r_sintheta
          // Rotate clockwise the bottle position about the new origin
          LET tx = inprod(bx, by,  c,  s)
          LET ty = inprod(bx, by, -s,  c)
          // Deal with bounces of the arm edges
          LET thickness = 2*tipradius // Arm thickness
          // Calculate the y position of the right edge of the left arm
          LET y3 = muldiv(robotradius-shoulderradius-thickness,
                          r!r_grabpos, One)
          LET y4 = y3 + thickness  // Left edge of left arm
          LET y2 = -y3             // Left edge of right arm
          LET y1 = y2 - thickness  // Rightt edge of right arm
IF i=0 DO // Debugging aid
{ writef("robot  %i2 cg=(%10.5d %10.5d)*n", i, r!r_cgx, r!r_cgy)
  writef("bottle %i2 cg=(%10.5d %10.5d)*n", j, b!b_cgx, b!b_cgy)
  writef("bx=%10.5d by=%10.5d*n", bx, by)
  writef("tx=%9.5d grablen=%9.5d*n", tx, grablen)
  writef("ty=%9.5d*n", ty)
  writef("y1=%9.5d y1=%9.5d y1=%9.5d y1=%9.5d*n", y1, y2, y3, y4)
}
          IF robotradius <= tx <= robotradius+grablen DO
          { // Bounces and grabbing are both possible
            IF y1 - bottleradius <= ty <= y1 DO
            { // Bottle collision with right edge of right arm
              //LET rtdot = inprod(r!r_cgxdot, r!r_cgydot, c, s)
              LET rwdot = inprod(r!r_cgxdot, r!r_cgydot,-s, c)
              LET btdot = inprod(b!b_cgxdot, b!b_cgydot, c, s)
              LET bwdot = inprod(b!b_cgxdot, b!b_cgydot,-s, c)
              LET v = bwdot-rwdot
              IF v>0 DO
              { bwdot := rebound(v) + rwdot
                // Trandform bottle velocity to world coords
                b!b_cgxdot := inprod(btdot,bwdot, c, -s)
                b!b_cgydot := inprod(btdot,bwdot, s,  c)
              }
IF i=0 DO
{ writef("robot %n collision bottle %n right edge of right arm*n", i, j)
  abort(1000)
}
            }
            IF y2 <= ty <= y2 + bottleradius DO
            { // Bottle collision with left edge of right arm
              //LET rtdot = inprod(r!r_cgxdot, r!r_cgydot, c, s)
              LET rwdot = inprod(r!r_cgxdot, r!r_cgydot,-s, c)
              LET btdot = inprod(b!b_cgxdot, b!b_cgydot, c, s)
              LET bwdot = inprod(b!b_cgxdot, b!b_cgydot,-s, c)
              LET v = bwdot-rwdot
              IF v<0 DO
              { bwdot := rebound(v) + rwdot
                // Trandform bottle velocity to world coords
                b!b_cgxdot := inprod(btdot,bwdot, c, -s)
                b!b_cgydot := inprod(btdot,bwdot, s,  c)
              }
              //IF tydot>0 DO tydot := rebound(tydot)
IF i=0 DO
{ writef("robot %n collision bottle %n left edge of right arm*n", i, j)
  abort(1000)
}
            }
            IF y3 - bottleradius <= ty <= y3 DO
            { // Bottle collision with right edge of left arm
              //LET rtdot = inprod(r!r_cgxdot, r!r_cgydot, c, s)
              LET rwdot = inprod(r!r_cgxdot, r!r_cgydot,-s, c)
              LET btdot = inprod(b!b_cgxdot, b!b_cgydot, c, s)
              LET bwdot = inprod(b!b_cgxdot, b!b_cgydot,-s, c)
              LET v = bwdot-rwdot
              IF v>0 DO
              { bwdot := rebound(v) + rwdot
                // Trandform bottle velocity to world coords
                b!b_cgxdot := inprod(btdot,bwdot, c, -s)
                b!b_cgydot := inprod(btdot,bwdot, s,  c)
              }
IF i=0 DO
{ writef("robot %n collision bottle %n right edge of left arm*n", i, j)
  abort(1000)
}
            }
            IF y4 <= ty <= y4 + bottleradius DO
            { // Bottle collision with left edge of left arm
              //LET rtdot = inprod(r!r_cgxdot, r!r_cgydot, c, s)
              LET rwdot = inprod(r!r_cgxdot, r!r_cgydot,-s, c)
              LET btdot = inprod(b!b_cgxdot, b!b_cgydot, c, s)
              LET bwdot = inprod(b!b_cgxdot, b!b_cgydot,-s, c)
              LET v = bwdot-rwdot
              IF v<0 DO
              { bwdot := rebound(v) + rwdot
                // Trandform bottle velocity to world coords
                b!b_cgxdot := inprod(btdot,bwdot, c, -s)
                b!b_cgydot := inprod(btdot,bwdot, s,  c)
              }
IF i=0 DO
{ writef("robot %n collision bottle %n left edge of left arm*n", i, j)
  abort(1000)
}
            }
            IF y2 <= ty <= y3 DO
            { // Bottle is the grab area
              // First test for a bounce off the grabber base
              IF robotradius <= tx <= robotradius+bottleradius DO
              { LET rtdot = inprod(r!r_cgxdot, r!r_cgydot, c, s)
                LET btdot = inprod(b!b_cgxdot, b!b_cgydot, c, s)
                LET bwdot = inprod(b!b_cgxdot, b!b_cgydot,-s, c)
                LET v = btdot-rtdot
                IF v<0 DO
                { btdot := rebound(v) + rtdot
                  // Trandform bottle velocity to world coords
                  b!b_cgxdot := inprod(btdot,bwdot, c, -s)
                  b!b_cgydot := inprod(btdot,bwdot, s,  c)
                }
              }
              IF y3-y2 <= 2*bottleradius & r!r_grabposdot<0 DO
              { // The bottle has just been grabbed
                grabbottle(r, b)
              }
IF i=0 DO
{ writef("robot %n bottle %n in grab area*n", i, j)
  abort(2000)
}
            }
          } 


        }

        
      }
    }

    // Test for robot-robot interaction
    FOR j = i+1 TO robotv!0 DO
    { LET p = robotv!j
      IF incontact(r, p, 6*robotradius) DO
      { // If robots get close they repel each other
        LET x1, y1 = r!r_cgx, r!r_cgy
        LET x2, y2 = p!r_cgx, p!r_cgy
        LET c = cosines(x1-x2, y1-y2)
        LET s = result2
        IF i=-1 DO
        { writef("Robot %n in contact with robot %n*n", i, j)
          writef("Robot %n cg (%10.5d,%10.5d)*n", i, r!r_cgx, r!r_cgy)
          writef("Robot %n cg (%10.5d,%10.5d)*n", j, p!r_cgx, p!r_cgy)
        }
        r!r_cgxdot := r!r_cgxdot +
                      inprod(20_00000, 0,  c, -s)/sps
        r!r_cgydot := r!r_cgydot +
                      inprod(20_00000, 0,  s,  c)/sps
        p!r_cgxdot := p!r_cgxdot -
                      inprod(20_00000, 0,  c, -s)/sps
        p!r_cgydot := p!r_cgydot -
                      inprod(20_00000, 0,  s,  c)/sps
        robotcoords(r)
        robotcoords(p)
      }
    }
  }
  
  // Robot motion
  FOR i = 1 TO robotv!0 DO
  { LET r = robotv!i  // r -> [cgx, cgy, cgxdot, cgydot, costheta, sintheta]
    LET grabposdot = r!r_grabposdot
    LET grabpos    = r!r_grabpos + grabposdot/sps

    r!r_cgx      := r!r_cgx + r!r_cgxdot/sps
    r!r_cgy      := r!r_cgy + r!r_cgydot/sps

    IF grabpos < 0_10000 DO grabpos, grabposdot := 0_10000, 0
    IF grabpos > 1_00000 DO grabpos, grabposdot := 1_00000, 0
    r!r_grabpos, r!r_grabposdot := grabpos, grabposdot    
  }

  // Bottle motion
  FOR i = 1 TO bottlev!0 DO
  { LET b = bottlev!i  // b -> [cgx, cgy, cgxdot, cgydot]
    UNLESS b!b_dropped DO
    { LET cgxdot = b!b_cgxdot
      LET cgydot = b!b_cgydot
      b!b_cgx := b!b_cgx + cgxdot/sps
      b!b_cgy := b!b_cgy + cgydot/sps

      IF incontact(b, thepit, 2*pitradius-bottleradius) DO
      { // Deal with bottle-pit interactions
        // Calculate the direction from the pit centre to the bottle.
        LET dir_x = cosines(b!b_cgx-pit_x, b!b_cgy-pit_y)
        LET dir_y = result2
//writef("bottle=%n dx=%10.5d dy=%10.5d  dir_x=%10.5d dir_y=%10.5d*n",
//        i, b!b_cgx-pit_x, b!b_cgy-pit_y, dir_x, dir_y)

        // Apply a constant force away from the pit centre.
        b!b_cgxdot := cgxdot + muldiv(2_00000, dir_x, One)
        b!b_cgydot := cgydot + muldiv(2_00000, dir_y, One)
      }
      UNLESS  b!b_grabbed IF incontact(b, thepit, pitradius-bottleradius) DO
      { b!b_dropped := TRUE
        bottlecount := bottlecount-1
      }
    }
  }
}

AND grabbottle(r, b) BE
{ LET mx = robotradius = 3*bottleradius/2
  LET my = 0
  LET c = cosines(r!r_cgxdot, r!r_cgydot)
  LET s = result2

  // Set the bottle's position and velocity
  b!b_cgx    := inprod(mx,my,  c, s) + r!r_cgx
  b!b_cgy    := inprod(mx,my, -s, c) + r!r_cgy
  b!b_cgxdot := r!r_cgxdot
  b!b_cgydot := r!r_cgydot

  b!b_grabbed    := TRUE
  b!b_robot      := r     // The grabbing robot
  r!r_bottle     := b     // The grabbed bottle
  r!r_grabposdot := 0     // Stop the grabber 
writef("Robot %n grabbed Bottle %n*n", r!r_id, b!b_id)
//abort(3000)
}

AND releasebottle(r) BE IF r!r_bottle DO
{ LET b = r!r_bottle
  LET mx = robotradius + 3*bottleradius/2
  LET my = 0
  LET c = cosines(r!r_cgxdot, r!r_cgydot)
  LET s = result2

  // Set the bottle's position and velocity
  b!b_cgx    := inprod(mx,my, c,-s) + r!r_cgx
  b!b_cgy    := inprod(mx,my, s, c) + r!r_cgy
  b!b_cgxdot := r!r_cgxdot
  b!b_cgydot := r!r_cgydot

  b!b_grabbed    := FALSE
  b!b_robot      := 0     // No grabbing robot
  r!r_bottle     := 0     // No grabbed bottle
writef("Robot %n released Bottle %n*n", r!r_id, b!b_id)
//abort(4000)
 }

AND initpitsurf(col) = VALOF
{ // Allocate the pit surface
  LET height = 2*pitradius/One + 2
  LET width  = height
  LET colkey = maprgb(64,64,64)
  LET surf = mksurface(width, height)

  selectsurface(surf, width, height)
  fillsurf(colkey)
  setcolourkey(surf, colkey)

  setcolour(col)
  drawfillcircle(pitradius/One, pitradius/One+1, pitradius/One)

  RESULTIS surf
}

AND initbottlesurf(col) = VALOF
{ // Allocate a bottle surface
  LET height = 2*bottleradius/One + 2
  LET width  = height
  LET colkey = maprgb(64,64,64)
  LET surf = mksurface(width, height)

  selectsurface(surf, width, height)
  fillsurf(colkey)
  setcolourkey(surf, colkey)

  setcolour(col)
  drawfillcircle(bottleradius/One, bottleradius/One+1, bottleradius/One)

  RESULTIS surf
}

AND sine(theta) = VALOF
// theta =     0 for 0 degrees
//       = 64000 for 90 degrees
// Returns a value in range -1000 to 1000
{ LET a = theta  /  1000
  LET r = theta MOD 1000
  LET s = rawsine(a)
  RESULTIS s + (rawsine(a+1)-s)*r/1000
}

AND cosine(x) = sine(x+64_000)

AND rawsine(x) = VALOF
{ // x is scaled d.ddd with 64.000 representing 90 degrees
  // The result is scaled d.ddddd, ie 1_00000 represents 1.00000
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
  RESULTIS a * 100
}

AND robotcoords(r) BE
{ // This function calculates the orientation of the robot
  // and the coordinates of all its key points
  LET c, s, ns  = ?, ?, ?
  LET x, y = r!r_cgx, r!r_cgy
  LET r1 = robotradius
  LET r2 = shoulderradius
  LET r3 = tipradius
  LET d1 = 2*r3
  LET d2 = muldiv(r!r_grabpos, r1-r2-d1, One)
  LET d3 = grablen
  setdir(r)
  c := r!r_costheta
  s := r!r_sintheta
  ns := -s

  r!r_lcx  := x + inprod( c,ns, r1-r2, r1-r2) // Left side
  r!r_lcy  := y + inprod( s, c, r1-r2, r1-r2)
  r!r_lex  := x + inprod( c,ns,    r1, r1-r2)
  r!r_ley  := y + inprod( s, c,    r1, r1-r2)

  r!r_rcx  := x + inprod( c,ns, r1-r2, r2-r1) // Right side
  r!r_rcy  := y + inprod( s, c, r1-r2, r2-r1)
  r!r_rex  := x + inprod( c,ns,    r1, r2-r1)
  r!r_rey  := y + inprod( s, c,    r1, r2-r1)

  r!r_ltax := x + inprod( c,ns,    r1, d1+d2) // Left arm
  r!r_ltay := y + inprod( s, c,    r1, d1+d2)
  r!r_ltbx := x + inprod( c,ns,    r1,    d2)
  r!r_ltby := y + inprod( s, c,    r1,    d2)
  r!r_ltcx := x + inprod( c,ns, r1+d3,    d2)
  r!r_ltcy := y + inprod( s, c, r1+d3,    d2)
  r!r_ltdx := x + inprod( c,ns, r1+d3, d1+d2)
  r!r_ltdy := y + inprod( s, c, r1+d3, d1+d2)
  r!r_ltpx := x + inprod( c,ns, r1+d3, d2+r3)
  r!r_ltpy := y + inprod( s, c, r1+d3, d2+r3)

  r!r_rtax := x + inprod( c,ns,    r1,-d1-d2) // Right arm
  r!r_rtay := y + inprod( s, c,    r1,-d1-d2)
  r!r_rtbx := x + inprod( c,ns,    r1,   -d2)
  r!r_rtby := y + inprod( s, c,    r1,   -d2)
  r!r_rtcx := x + inprod( c,ns, r1+d3,   -d2)
  r!r_rtcy := y + inprod( s, c, r1+d3,   -d2)
  r!r_rtdx := x + inprod( c,ns, r1+d3,-d1-d2)
  r!r_rtdy := y + inprod( s, c, r1+d3,-d1-d2)
  r!r_rtpx := x + inprod( c,ns, r1+d3,-d2-r3)
  r!r_rtpy := y + inprod( s, c, r1+d3,-d2-r3)

  // Centre of grabbed bottle
  r!r_bcx  := x + inprod( c,ns, robotradius+2*bottleradius, 0)
  r!r_bcy  := y + inprod( s, c, robotradius+2*bottleradius, 0)
}

AND drawrobot(i) BE
{ LET r = robotv!i
  robotcoords(r)

  setcolour(r!r_colour)
  // Body
  drawfillcircle(r!r_cgx/One, r!r_cgy/One, robotradius/One)
  // Left shoulder
  drawfillcircle(r!r_lcx/One, r!r_lcy/One, shoulderradius/One)
  // Right shoulder
  drawfillcircle(r!r_rcx/One, r!r_rcy/One, shoulderradius/One)

  setcolour(grabcolour)
  // Grabber base
  drawquad(r!r_lcx/One, r!r_lcy/One,
           r!r_lex/One, r!r_ley/One,
           r!r_rex/One, r!r_rey/One,
           r!r_rcx/One, r!r_rcy/One)
  // Left arm
  drawquad(r!r_ltax/One, r!r_ltay/One,
           r!r_ltbx/One, r!r_ltby/One,
           r!r_ltcx/One, r!r_ltcy/One,
           r!r_ltdx/One, r!r_ltdy/One)
  drawfillcircle(r!r_ltpx/One, r!r_ltpy/One, tipradius/One)
  // Right arm
  drawquad(r!r_rtax/One, r!r_rtay/One,
           r!r_rtbx/One, r!r_rtby/One,
           r!r_rtcx/One, r!r_rtcy/One,
           r!r_rtdx/One, r!r_rtdy/One)
  drawfillcircle(r!r_rtpx/One, r!r_rtpy/One, tipradius/One)
}

AND drawbottle(i) BE
{ LET b = bottlev!i
  LET bottlesurf = bottlesurfR  // Normally red
  IF b!b_dropped RETURN

  IF i=1 DO bottlesurf := bottlesurfK

  IF b!b_grabbed DO
  { LET r = b!b_robot
    bottlesurf := bottlesurfB
    // Set the bottle coords
    b!b_cgx := r!r_bcx 
    b!b_cgy := r!r_bcy 
  }

  blitsurf(bottlesurf, screen, (b!b_cgx-bottleradius)/One,
                               (b!b_cgy+bottleradius)/One)
}

AND plotscreen() BE
{ selectsurface(screen, screenxsize, screenysize)
  fillsurf(backcolour)

  // Allocate the surfaces if necessary
  UNLESS bottlesurfR DO bottlesurfR := initbottlesurf(col_red)
  UNLESS bottlesurfK DO bottlesurfK := initbottlesurf(col_black)
  UNLESS bottlesurfB DO bottlesurfB := initbottlesurf(col_brown)
  UNLESS pitsurf DO pitsurf := initpitsurf(pitcolour)

  selectsurface(screen, xsize, ysize)

  // The pit
  blitsurf(pitsurf, screen,
           (pit_x-pitradius)/One, (pit_y+pitradius)/One)

  selectsurface(screen, xsize, ysize)

  // Must draw the robots first in case there are grabbed bottles
  FOR i = 1 TO robotv!0  DO drawrobot(i)

  FOR i = 1 TO bottlev!0 DO drawbottle(i)

  setcolour(maprgb(255,255,255))
  
  IF help DO
  { plotf(30, 150, "Q  -- Quit")
    plotf(30, 135, "P  -- Pause/Continue")
    plotf(30, 120, "H  -- Toggle help information")
    plotf(30, 105, "G  -- Grab")
    plotf(30,  90, "R  -- Release")
    plotf(30,  75, "D  -- Toggle debugging")
    plotf(30,  60, "U  -- Toggle usage")
    plotf(30,  45, "Arrow keys -- Control the blue robot")
  }

  setcolour(maprgb(255,255,255))
  

  IF displayusage DO
    plotf(30, 245, "CPU usage = %i3%% sps = %n", usage, sps)

  IF debugging DO
  { LET r = robotv!1
    LET b = bottlev!1
    plotf(30, 220, "Robot1  x=%10.5d  y=%10.5d xdot=%10.5d  ydot=%10.5d",
          r!r_cgx, r!r_cgy, r!r_cgxdot, r!r_cgydot)
    plotf(30, 205, " costheta=%10.5d       sintheta=%10.5d",
          r!r_costheta, r!r_sintheta)
    plotf(30, 175, "    grabpos=%10.5d       grabposdot=%10.5d",
          r!r_grabpos, r!r_grabposdot)
    plotf(30, 160, "Bottle1 x=%10.5d  y=%10.5d xdot=%10.5d  ydot=%10.5d",
          b!b_cgx, b!b_cgy, b!b_cgxdot, b!b_cgydot)
  }
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
                LOOP

      CASE 'U': displayusage := ~displayusage
                LOOP

      CASE 'G': // Grab
              { LET r = robotv!1
                // Close grabber unless a bottle is already grabbed
                //UNLESS r!r_bottle DO
                  r!r_grabposdot := -1_00000
                LOOP
              }

      CASE 'R': // Release
              { LET r = robotv!1
                r!r_grabposdot := +1_00000
//writef("Releasing grabber of robot 1 bottle node %n*n", r!r_bottle)
//abort(5000)
                IF r!r_bottle DO releasebottle(r)
                LOOP
              }

      CASE 'S': // Start again
                LOOP

      CASE 'P': // Toggle stepping
                stepping := ~stepping
                LOOP

      CASE sdle_arrowup:
              { LET r = robotv!1
                r!r_cgxdot := r!r_cgxdot + 
                              muldiv(9_00000, r!r_costheta, One)
                r!r_cgydot := r!r_cgydot + 
                              muldiv(9_00000, r!r_sintheta, One)
                setdir(r)
//writef("costheta=%10.5d sintheta=%10.5d*n", r!r_costheta, r!r_sintheta)
//abort(5000)
                LOOP
              }

      CASE sdle_arrowdown:
              { LET r = robotv!1
                r!r_cgxdot := r!r_cgxdot - 
                              muldiv(9_00000, r!r_costheta, One)
                r!r_cgydot := r!r_cgydot -
                              muldiv(9_00000, r!r_sintheta, One)
                setdir(r)
//writef("costheta=%10.5d sintheta=%10.5d*n", r!r_costheta, r!r_sintheta)
//abort(5000)
                LOOP
              }

      CASE sdle_arrowright:
              { LET r = robotv!1
                LET xdot = r!r_cgxdot
                LET ydot = r!r_cgydot
                LET dc  = cosine(4_000)
                LET ds  = sine(4_000)
                r!r_cgxdot := inprod(xdot,ydot, dc, ds)
                r!r_cgydot := inprod(xdot,ydot,-ds, dc)
                setdir(r)
                LOOP
              }

      CASE sdle_arrowleft:
              { LET r = robotv!1
                LET xdot = r!r_cgxdot
                LET ydot = r!r_cgydot
                LET dc  = cosine(4_000)
                LET ds  = - sine(4_000)
                r!r_cgxdot := inprod(xdot,ydot, dc, ds)
                r!r_cgydot := inprod(xdot,ydot,-ds, dc)
                setdir(r)
                LOOP
              }
    }

  CASE sdle_quit:
    writef("QUIT*n");
    done := TRUE
    LOOP
}

AND nearedge(x, y, size) = VALOF
{ size := 8*size

//  writef("nearedge: x=%n y=%n size=%n xsize**One=%n ysize**One=%n*n",
//         x, y, size, xsize*One, ysize*One)
//abort(1000)
  UNLESS size < x < xsize*One - size  RESULTIS TRUE
  UNLESS size < y < ysize*One - size  RESULTIS TRUE
//writef("=> TRUE*n")
  RESULTIS FALSE
}

AND nearpit(x, y, size) = VALOF
{ LET cx = pit_x
  LET cy = pit_y //ysize*One/2
  LET dx = ABS(x - cx)
  LET dy = ABS(y - cy)
  size := size + pitradius
  IF dx < size | dy < size RESULTIS TRUE
  RESULTIS FALSE
}

AND nearbottle(x, y, size) = VALOF
{ size := 2*(size + bottleradius)
  FOR i = 1 TO bottlev!0 DO
  { LET b = bottlev!i
    LET bx = b!b_cgx
    LET by = b!b_cgy
    LET dx = ABS(x - bx)
    LET dy = ABS(y - by)
//writef("nearbottle: i=%i2 x=%n y=%n bx=%n by=%n size=%n*n", i, x, y, bx, by, size)
    IF dx+dy < size RESULTIS TRUE
  }
//writef("=>FALSE*n")
//abort(1000)
  RESULTIS FALSE
}

AND nearrobot(x, y, size) = VALOF
{ size := 2*(size + robotradius)
  FOR i = 1 TO robotv!0 DO
  { LET r = robotv!i
    LET rx = r!r_cgx
    LET ry = r!r_cgy
    LET dx = ABS(x - rx)
    LET dy = ABS(y - ry)
//writef("nearrobot: i=%i2 x=%n y=%n bx=%n by=%n size=%n*n", i, x, y, bx, by, size)
    IF dx+dy < size RESULTIS TRUE
  }
//writef("=>FALSE*n")
//abort(1000)
  RESULTIS FALSE
}

LET start() = VALOF
{ LET argv = VEC 50
  LET stepmsecs = ?
  LET comptime  = 0 // Amount of cpu time per frame
  LET day, msecs, filler = 0, 0, 0
  //datstamp(@day)
  seed := msecs     // Set seed based on time of day
  //msecs0 := msecs   // Set the starting time
  //msecsnow := 0

  UNLESS rdargs("-b/n,-r/n,-sx/n,-sy/n,-s/n",
                argv, 50) DO
  { writef("Bad arguments for robots*n")
    RESULTIS 0
  }

  bottles := 40
  robots  := 7
  xsize   := 700
  ysize   := 500

  IF argv!0 DO bottles := !(argv!0) // -b/n
  IF argv!1 DO robots  := !(argv!1) // -r/n
  IF argv!2 DO xsize   := !(argv!2) // -sx/n
  IF argv!3 DO ysize   := !(argv!3) // -sy/n
  IF argv!4 DO seed    := !(argv!4) // -s/n

  IF bottles <   1 DO bottles :=   1
  IF bottles > 100 DO bottles := 100
  IF robots  <   1 DO robots  :=   1
  IF robots  >  30 DO robots  :=  30

  setseed(seed)

  UNLESS sys(Sys_sdl, sdl_avail) DO
  { writef("*nThe SDL features are not available*n")
    RESULTIS 0
  }

  spacev := getvec(spacevupb)

  UNLESS spacev DO
  { writef("Insufficient space available*n")
    RESULTIS 0
  }

  spacep, spacet := spacev, spacev+spacevupb


  IF FALSE DO
  { // Code to test the cosines function
    LET e1, e2, rsq = One, One, One
    LET x, y, xdot, ydot, c, s = 0, 0, One, 0, One, 0
    LET p = @x
    FOR dy = 0 TO One BY One/100 DO
    { ydot := dy
      setdir(p)
      rsq := inprod(c,c, s,s)
      writef("dx=%9.5d  dy=%9.5d cos=%9.5d sin=%9.5d rsq=%9.5d*n",
              One, dy, c, s, rsq)
      IF e1 < rsq DO e1 := rsq
      IF e2 > rsq DO e2 := rsq
    }
    writef("Errors +%7.5d  -%7.5d*n", e1-One, One-e2)
abort(1000)
    RESULTIS 0
  }

  // Initialise the priority queue
  priq := mkvec(200)
  priqn, priqupb := 0, 200

  initsdl()
  mkscreen("Robots", xsize, ysize)

  backcolour      := maprgb(120,120,120)
  col_red         := maprgb(255,  0,  0)
  col_black       := maprgb(  0,  0,  0)
  col_brown       := maprgb(100, 50, 20)
  pitcolour       := maprgb( 20, 20,100)
  robotcolour     := maprgb(  0,255,  0)
  robot1colour    := maprgb(  0,120, 40)
  grabcolour      := maprgb(200,200, 40)

  pit_x, pit_y := xsize*One/2, ysize*One/2
  pit_xdot, pit_ydot := 0, 0
  thepit := @pit_x

  // Initialise robotv
  robotv := mkvec(robots)
  robotv!0 := 0
  FOR i = 1 TO robots DO
  { LET r = mkvec(r_upb)
    LET x = ?
    LET y = ?

    { x := randno(xsize*One)
      y := randno(ysize*One)
      UNLESS nearedge (x, y, robotradius) |
             nearpit  (x, y, robotradius) |
             nearrobot(x, y, robotradius) BREAK
    } REPEAT

    robotv!0 := i
    robotv!i := r
    // Position
    r!r_cgx        := x
    r!r_cgy        := y
    // Motion
    r!r_cgxdot     := randno(40_00000) - 20_00000
    r!r_cgydot     := randno(40_00000) - 20_00000
    r!r_costheta   := cosines(r!r_cgxdot, r!r_cgydot)
    r!r_sintheta   := result2
    // grabber
    r!r_grabpos    := 1_00000   // grabber open
    r!r_grabposdot := 0_00000
    r!r_bottle     := 0         // No grabbed bottle
    r!r_colour     := i=1 -> robot1colour, robotcolour
    r!r_id := i
    robotcoords(r)
  }

  // Initialise bottlev
  bottlev := mkvec(bottles)
  bottlev!0 := 0
  FOR i = 1 TO bottles DO
  { LET b = mkvec(b_upb)
    LET x = ?
    LET y = ?

    { // Choose a random position for the next bottle
      x := randno(xsize*One)
      y := randno(ysize*One)
      UNLESS nearedge  (x, y, bottleradius) |
             nearpit   (x, y, bottleradius) |
             nearrobot (x, y, robotradius)  |
             nearbottle(x, y, bottleradius) BREAK
    } REPEAT

    bottlev!0   := i
    bottlev!i   := b
    b!b_cgx     := x
    b!b_cgy     := y
    b!b_cgxdot  := randno(50_00000) - 25_00000
    b!b_cgydot  := randno(50_00000) - 25_00000
    b!b_grabbed := FALSE
    b!b_robot   := 0         // No grabbing robot
    b!b_dropped := FALSE
    b!b_id      := i
  }

  help := FALSE //TRUE

  stepping := TRUE     // =FALSE if not stepping
  usage := 0
  debugging := FALSE
  displayusage := FALSE
  sps := 40 // Initial setting
  stepmsecs := 1000/sps

  wall_wx := 0
  wall_ex := (screenxsize-1)*One      // East wall

  wall_sy    := 0                     // South wall
  wall_ny := (screenysize-1)*One      // North wall

// Lots of initialisation ####################################
  bottlesurfR := 0
  bottlesurfK := 0
  bottlesurfB := 0
  pitsurf := 0

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
  sdldelay(0_200)

  IF bottlesurfR DO freesurface(bottlesurfR)
  IF bottlesurfK DO freesurface(bottlesurfK)
  IF bottlesurfB DO freesurface(bottlesurfB)
  IF pitsurf     DO freesurface(pitsurf)

  closesdl()

  IF spacev DO freevec(spacev)
  RESULTIS 0
}

// ################### Priority Queue functions ######################

AND prq() BE
{ FOR i = 1 TO priqn DO writef(" %i4", priq!i!0)
  newline()
}

AND insertevent(event) BE
{ priqn := priqn+1        // Increment number of events
  upheap(event, priqn)
}

AND upheap(event, i) BE
{ LET eventtime = event!0

  { LET p = i/2           // Parent of i
    UNLESS p & eventtime < priq!p!0 DO
    { priq!i := event
      RETURN
    }
    priq!i := priq!p      // Demote the parent
    i := p
  } REPEAT
}

AND downheap(event, i) BE
{ LET j, min = 2*i, ? // j is left child, if present

  IF j > priqn DO
  { upheap(event, i)
    RETURN
  }
  min := priq!j!0
  // Look at other child, if it exists
  IF j<priqn & min>priq!(j+1)!0 DO j := j+1
  // promote earlier child
  priq!i := priq!j
  i := j
} REPEAT

AND getevent1() = VALOF
{ LET event = priq!1        // Get the earliest event
  LET last  = priq!priqn    // Get the event at the end of the heap
  UNLESS priqn>0 RESULTIS 0 // No events in the priority queue
  priqn := priqn-1          // Decrement the heap size
  downheap(last, 1)         // Re-insert last event
  RESULTIS event
}

AND waitfor(msecs) BE
{ // Make an event item into the priority queue
  LET eventtime, co = msecsnow+msecs, currco
  insertevent(@eventtime)   // Insert into the priority queue
  cowait()                  // Wait for the specified time
}

// ###################### Queueing functions #########################
/*
AND prwaitq(node) BE
{ LET p = wkqv!node
  IF -1 <= p <= 0 DO { writef("wkq for node %n: %n*n", node, p); RETURN }
  writef("wkq for node %n:", node)
  WHILE p DO
  { writef(" %n", p!1)
    p := !p
  }
  newline()
}

AND qitem(node) BE
{ // Make a queue item
  LET link, co = 0, currco
  LET p = wkqv!node
  UNLESS p DO
  { // The node was not busy
    wkqv!node := -1  // Mark node as busy
    IF tracing DO
      writef("%i8: node %i4: node not busy*n", simtime, node)
    RETURN
  }
  // Append item to the end of this queue
  IF tracing DO
    writef("%i8: node %i4: busy so appending message to end of work queue*n",
            simtime, node)
  TEST p=-1
  THEN wkqv!node := @link     // Form a unit list
  ELSE { WHILE !p DO p := !p  // Find the end of the wkq
         !p := @link          // Append to end of wkq
       }
  cowait() // Wait to be activated (by dqitem)
}

AND dqitem(node) BE
{ LET item = wkqv!node // Current item (~=0)
  UNLESS item DO abort(999)
  TEST item=-1
  THEN wkqv!node := 0                  // The node is no longer busy
  ELSE { LET next = item!0
         AND co   = item!1
         wkqv!node := next -> next, -1 // De-queue the item
         callco(co)                    // Process the next message
       }
}
*/



