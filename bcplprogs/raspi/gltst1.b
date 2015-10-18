/*
################ UNDER DEVELOPMENT ########################
This program is a demonstration of the SDL OpenGL interface.

Implemented by Martin Richards (c) Dec 2013

Q  causes quit
D  toggles debugging output

*/

GET "libhdr"
GET "sdl.h"
GET "sdl.b"          // Insert the library source code
.
GET "libhdr"
GET "sdl.h"

MANIFEST {
  One = 1_000000
}

GLOBAL {
  done:ug

  debugging
  plotusage
  usage         // 0 to 100 percentage cpu usage
  sps           // Steps per second
  stepmsecs     // msecs per step

  step
  
  c_aileron;  c_trimaileron  // -32768 .. 32767
  c_elevator; c_trimelevator // -32768 .. 32767
  c_rudder;   c_trimrudder   // -32768 .. 32767

  ctx; cty; ctz   // Direction cosines of direction t
  cwx; cwy; cwz   // Direction cosines of direction w
  clx; cly; clz   // Direction cosines of direction l

  cetx; cety; cetz // Eye direction cosines of direction t
  cewx; cewy; cewz // Eye direction cosines of direction w
  celx; cely; celz // Eye direction cosines of direction l

  eyex; eyey; eyez // Relative position of the eye
  eyedist          // Eye x or y distance from aircraft

  rtdot; rwdot; rldot // Rotation rates about t, w and l axes
}


LET start() = VALOF
{ LET t0, t1 = 0, 0
  LET stepmsecs = 1
  LET framecount = 0

  IF sys(Sys_sdl, sdl_avail) DO writef("*nSDL is available*n")
  IF sys(Sys_sdl, gl_avail)  DO writef("*nOpenGL is available*n")

  initsdl()

  // Create an OpenGL window
  mkglscreen("OpenGL Test", 800, 500)

  ctx, cty, ctz := One,   0,   0
  cwx, cwy, cwz :=   0, One,   0
  clx, cly, clz :=   0,   0, One

  cetx, cety, cetz := One,   0,   0
  cewx, cewy, cewz :=   0, One,   0
  celx, cely, celz :=   0,   0, One

  eyex, eyey, eyez := -eyedist, 0, 0 // Relative position of the eye
  eyedist := 100_000                 // Eye distance initially 100 ft

  c_aileron,  c_trimaileron  := 0, 0
  c_elevator, c_trimelevator := 0, 0
  c_rudder,   c_trimrudder   := 0, 0

  done := FALSE

writef("start: width=%n height=%n*n", screenxsize, screenysize)

  setup_opengl(screenxsize, screenysize)

  t0 := sdlmsecs()
  framecount := 0

  UNTIL done DO
  { processevents()
    step()            // Update the orientation of the aircraft
    drawscreen()
    framecount := framecount+1
    t1 := sdlmsecs()
    IF t1-t0>1000 DO
    { LET framerate = framecount * 1000 / (t1-t0)
      writef("framrate = %n frames/sec*n", framerate)
      framecount := 0
      t0 := t1
    }
    //sdldelay(stepmsecs)
  }

  writef("*nQuitting*n")
  //sdldelay(5000)
  closesdl()
  RESULTIS 0
}

AND drawscreen() BE
{ STATIC { angle = 0_000000 } // Should be a global

  LET v0 = TABLE -1_000, -1_000,  1_000
  LET v1 = TABLE  1_000, -1_000,  1_000
  LET v2 = TABLE  1_000,  1_000,  1_000
  LET v3 = TABLE -1_000,  1_000,  1_000
  LET v4 = TABLE -1_000, -1_000, -1_000
  LET v5 = TABLE  1_000, -1_000, -1_000
  LET v6 = TABLE  1_000,  1_000, -1_000
  LET v7 = TABLE -1_000,  1_000, -1_000

  LET c0 = TABLE 255,   0,   0, 255  // Red
  LET c1 = TABLE   0, 255,   0, 255  // Green
  LET c2 = TABLE   0,   0, 255, 255  // Blue
  LET c3 = TABLE 255, 255, 255, 255  // White
  LET c7 = TABLE   0, 255, 255, 255  // Yellow
  LET c4 = TABLE   0,   0,   0, 255  // Black
  LET c5 = TABLE 255, 255,   0, 255  // Orange
  LET c6 = TABLE 255,   0, 255,   0  // Purple

  // Clear the colour and depth buffers
  sys(Sys_sdl, gl_Clear, GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)

  // We don't want to modify the projection matrix
  sys(Sys_sdl, gl_MatrixMode, GL_MODELVIEW)
  sys(Sys_sdl, gl_LoadIdentity)

  // Move down the z-axis
  sys(Sys_sdl, gl_Translate, 0_000, 0_000, -5_000)

  sys(Sys_sdl, gl_Rotate, angle, 0_000, 1_000, 1_000)

  angle := (angle + 1_000000) MOD 360_000000

  // Send our triangle data to the pipeline
  sys(Sys_sdl, gl_Begin, GL_TRIANGLES)

  sys(Sys_sdl, gl_Color4v, c0); sys(Sys_sdl, gl_Vertex3v, v0)
  sys(Sys_sdl, gl_Color4v, c1); sys(Sys_sdl, gl_Vertex3v, v1)
  sys(Sys_sdl, gl_Color4v, c2); sys(Sys_sdl, gl_Vertex3v, v2)

  sys(Sys_sdl, gl_Color4v, c0); sys(Sys_sdl, gl_Vertex3v, v0)
  sys(Sys_sdl, gl_Color4v, c2); sys(Sys_sdl, gl_Vertex3v, v2)
  sys(Sys_sdl, gl_Color4v, c3); sys(Sys_sdl, gl_Vertex3v, v3)

  sys(Sys_sdl, gl_Color4v, c1); sys(Sys_sdl, gl_Vertex3v, v1)
  sys(Sys_sdl, gl_Color4v, c5); sys(Sys_sdl, gl_Vertex3v, v5)
  sys(Sys_sdl, gl_Color4v, c6); sys(Sys_sdl, gl_Vertex3v, v6)

  sys(Sys_sdl, gl_Color4v, c1); sys(Sys_sdl, gl_Vertex3v, v1)
  sys(Sys_sdl, gl_Color4v, c6); sys(Sys_sdl, gl_Vertex3v, v6)
  sys(Sys_sdl, gl_Color4v, c2); sys(Sys_sdl, gl_Vertex3v, v2)

  sys(Sys_sdl, gl_Color4v, c5); sys(Sys_sdl, gl_Vertex3v, v5)
  sys(Sys_sdl, gl_Color4v, c4); sys(Sys_sdl, gl_Vertex3v, v4)
  sys(Sys_sdl, gl_Color4v, c7); sys(Sys_sdl, gl_Vertex3v, v7)

  sys(Sys_sdl, gl_Color4v, c5); sys(Sys_sdl, gl_Vertex3v, v5)
  sys(Sys_sdl, gl_Color4v, c7); sys(Sys_sdl, gl_Vertex3v, v7)
  sys(Sys_sdl, gl_Color4v, c6); sys(Sys_sdl, gl_Vertex3v, v6)

  sys(Sys_sdl, gl_Color4v, c4); sys(Sys_sdl, gl_Vertex3v, v4)
  sys(Sys_sdl, gl_Color4v, c0); sys(Sys_sdl, gl_Vertex3v, v0)
  sys(Sys_sdl, gl_Color4v, c3); sys(Sys_sdl, gl_Vertex3v, v3)

  sys(Sys_sdl, gl_Color4v, c4); sys(Sys_sdl, gl_Vertex3v, v4)
  sys(Sys_sdl, gl_Color4v, c3); sys(Sys_sdl, gl_Vertex3v, v3)
  sys(Sys_sdl, gl_Color4v, c7); sys(Sys_sdl, gl_Vertex3v, v7)

  sys(Sys_sdl, gl_Color4v, c3); sys(Sys_sdl, gl_Vertex3v, v3)
  sys(Sys_sdl, gl_Color4v, c2); sys(Sys_sdl, gl_Vertex3v, v2)
  sys(Sys_sdl, gl_Color4v, c6); sys(Sys_sdl, gl_Vertex3v, v6)

  sys(Sys_sdl, gl_Color4v, c3); sys(Sys_sdl, gl_Vertex3v, v3)
  sys(Sys_sdl, gl_Color4v, c6); sys(Sys_sdl, gl_Vertex3v, v6)
  sys(Sys_sdl, gl_Color4v, c7); sys(Sys_sdl, gl_Vertex3v, v7)

  sys(Sys_sdl, gl_Color4v, c1); sys(Sys_sdl, gl_Vertex3v, v1)
  sys(Sys_sdl, gl_Color4v, c0); sys(Sys_sdl, gl_Vertex3v, v0)
  sys(Sys_sdl, gl_Color4v, c4); sys(Sys_sdl, gl_Vertex3v, v4)

  sys(Sys_sdl, gl_Color4v, c1); sys(Sys_sdl, gl_Vertex3v, v1)
  sys(Sys_sdl, gl_Color4v, c4); sys(Sys_sdl, gl_Vertex3v, v4)
  sys(Sys_sdl, gl_Color4v, c5); sys(Sys_sdl, gl_Vertex3v, v5)

  sys(Sys_sdl, gl_End)

  sys(Sys_sdl, gl_SwapBuffers)
}

AND setup_opengl(width, height) BE
{ LET ratio = width*1_000000 / height
  // Set out shading model
  sys(Sys_sdl, gl_ShadeModel, GL_SMOOTH)
  // Culling
  sys(Sys_sdl, gl_CullFace, GL_BACK)
  sys(Sys_sdl, gl_FrontFace, GL_CCW)
  sys(Sys_sdl, gl_Enable, GL_CULL_FACE)
  // Set the clear colour
  sys(Sys_sdl, gl_ClearColor, 50, 50, 50, 0)
  // Setup our viewpoint
  sys(Sys_sdl, gl_ViewPort, 0, 0, width, height)
  // Change to the projection matrix and set
  // our viewing volume
  sys(Sys_sdl, gl_MatrixMode, GL_PROJECTION)
  sys(Sys_sdl, gl_LoadIdentity)
  sys(Sys_sdl, glu_Perspective, 60_000000, ratio, 1_000, 1024_000)
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

      CASE 'N': // Reduce eye distance
                eyedist := eyedist*5/6
                IF eyedist<10_000 DO eyedist := 10_000
                LOOP

      CASE 'F': // Increase eye distance
                eyedist := eyedist*6/5
                LOOP

      CASE ',':
      CASE '<': c_trimrudder := c_trimrudder - 500
                c_rudder := c_rudder - 500;       LOOP

      CASE '.':
      CASE '>': c_trimrudder := c_trimrudder + 500
                c_rudder := c_rudder + 500;       LOOP

      CASE sdle_arrowup:    c_trimelevator := c_trimelevator+2000
                            c_elevator := c_elevator+500;         LOOP
      CASE sdle_arrowdown:  c_trimelevator := c_trimelevator-2000
                            c_elevator := c_elevator-500;         LOOP
      CASE sdle_arrowright: c_trimaileron  := c_trimaileron +2000
                            c_aileron := c_aileron+500;           LOOP
      CASE sdle_arrowleft:  c_trimaileron  := c_trimaileron -2000
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
      CASE 3:   c_rudder   := c_trimrudder+value;        LOOP // Rudder
    }
  }

  CASE sdle_quit:             // 12
    done := TRUE
    writef("QUIT*n");
    LOOP
}

AND step() BE
{
}

