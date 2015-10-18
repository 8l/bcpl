/*
This is a demonstration of BCPL using floating point numbers.

It simulates the trajectory of a shell fired at a velocity
of 1000 ft/sec at an angle 45 degrees to the horizontal.
It steps the position every dt seconds which is typically
between 0.01 and 0.1. Air resistance is ignored. It returns
to earth in about 44 seconds after travelling a horizontal
distance of about 31 thousand feet.

Implemented by Martin Richards (c) Sept 2014
*/

GET "libhdr"

LET start() = VALOF
{ LET pi = 3.14159265
  LET theta_degrees = 45.0
  LET theta_radians = theta_degrees #* pi #/ 180.0
  LET costheta = sys(Sys_flt, fl_cos, theta_radians)
  LET sintheta = sys(Sys_flt, fl_sin, theta_radians)
  LET xdot = 1000.0 #* costheta
  LET ydot = 1000.0 #* sintheta
  LET prevydot = ydot
  LET x, y, t = 0.0, 0.0, 0.0
  LET dt = 0.01   // Time in seconds per step
  LET g = 32.174  // Gravity acceleration in ft per sec per sec
  { LET prevydot = ydot // So we can use the average ydot in each step.
    ydot := ydot #- g #* dt
    x := x #+ dt #* xdot
    y := y #+ dt #* (prevydot #+ ydot) #/ 2.0
    t := t #+ dt
    writef("%9.3d:  ",    FIX (t #* 1000.0))
    writef("x = %9.3d ",  FIX (x #* 1000.0))
    writef("y = %9.3d*n", FIX (y #* 1000.0))
  } REPEATUNTIL y #< 0.0

  RESULTIS 0
}
