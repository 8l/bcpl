/*
This program is a simple demonstration of the OpenGL interface.

The BCPL GL library is in g/gl.b with header g/gl.h and is designed to
work unchanged with either OpenGL using SDL or OpenGL ES using EGL.

Implemented by Martin Richards (c) July 2014

History

23/03/15
Simplified this program to only display gltst.mdl with limited control.
The tigermoth is now displayed in the flight simulator gltiger.b.

20/12/14
Modified the cube to be like a square missile with control surfaces.
It will display a rotating tigermoth by default. 

03/12/14
Began conversion to use floating point numbers.

Command argument:

OBJ       Use OpenGL Objects for vertex and index data
-d        Turn on debugging

Controls:

Q  causes quit
P  Output debugging info to the terminal
S  Stop/start the stepping the image

Rotational controls

Right/left arrow Increase/decrease rotation rate about direction of thrust
Up/Down arrow    Increase/decrease rotation rate about direction of right wing
>  <             Increase/decrease rotation rate about direction of lift

0,1,2,3,4,5,6,7  Set eye direction -- The eye is always looking
                                      towards the origin.
+,-              Increase/decrease eye distance

The transformations

The model is represented using three axes t (the direction of thrust),
w the direction of the left wing and l (the direction of lift,
orthogonal to t and w). These use the right hand convention, ie t is
forward, w is left and l is up.

Real world coordinate use axes x (right), y(up) and z(towards the
viewer). These also use the right hand convention.

  ctx; cty; ctz   // Direction cosines of direction t
  cwx; cwy; cwz   // Direction cosines of direction w
  clx; cly; clz   // Direction cosines of direction l

  eyex, eyey, eyez specify a point on the line of sight
                   between the eye and the origin. The line of
                   sight is towards the origin from this point.

  eyedistance holds the distance between the eye and the origin.

Since standard BCPL now supports floating point operations and the
latest Raspberry Pi (Model B-2) has proper support for floating point
this program will phase out scales fixed point arithmetic and use
floating point instead. This is a simple but extensive change.
*/

GET "libhdr"
GET "gl.h"
GET "gl.b"          // Insert the library source code
.
GET "libhdr"
GET "gl.h"

GLOBAL {
  done:ug
  stepping
  debug
  glprog
  Vshader
  Fshader

  VertexLoc  // Attribute variable locations
  ColorLoc
  DataLoc    // data[0]=ctrl  data[1]=value

  MatrixLoc  // Uniform variable locations
  ControlLoc

  CosElevator
  SinElevator
  CosRudder
  SinRudder
  CosAileron
  SinAileron

  modelfile

  // The following variables are floating point number

  ctx; cty; ctz   // Direction cosines of direction t
  cwx; cwy; cwz   // Direction cosines of direction w
  clx; cly; clz   // Direction cosines of direction l

  rtdot; rwdot; rldot // Anti-clockwise rotation rates
                      // about the t, w and l axes
 
  eyex; eyey; eyez // Coordinates of a point on the line of sight
                   // from to eye to the origin (0.0, 0.0, 0.0).
  eyedistance      // The distance between the eye and the origin.

  // The next four variables must be in consecutive locations
  // since @VertexData is passed to loadmodel.
  VertexData       // Vector of 32-bit floating point numbers
  VertexDataSize   // = number of numbers in VertexData
  IndexData        // Vector of 16-bit unsigned integers
  IndexDataSize    // = number of 16-bit integers in IndexData

  useObjects       //= TRUE if using OpenGL Objects
  VertexBuffer
  IndexBuffer

  projectionMatrix // is the matrix used by the vertex shader
                   // to transform the vertex coordinates to
                   // screen coordinates.
  workMatrix       // is used when constructing the projection matrix.
}

LET start() = VALOF
{ LET m1 = VEC 15
  LET m2 = VEC 15
  LET argv = VEC 50
  LET modelfile = "gltst.mdl"

  projectionMatrix, workMatrix := m1, m2

  UNLESS rdargs("obj/s,-d/s", argv, 50) DO
  { writef("Bad arguments for gltst*n")
    RETURN
  }

  useObjects := argv!0            // obj/s
  debug := argv!1                 // -d/s

  UNLESS glInit() DO
  { writef("*nOpenGL not available*n")
    RESULTIS 0
  }

  writef("start: calling glMkScreen*n")
  // Create an OpenGL window
  screenxsize := glMkScreen("OpenGL First Test", 800, 680)
  screenysize := result2
  UNLESS screenxsize DO
  { writef("*nUnable to create an OpenGL window*n")
    RESULTIS 0
  }
  writef("Screen Size is %n x %n*n", screenxsize, screenysize)

  writef("start: calling glMkProg  ")
  glprog := glMkProg()
  writef("=> glprog=%n*n", glprog);

  IF glprog<0 DO
  { writef("*nUnable to create a GL program*n")
    RESULTIS 0
  }

  // Read and Compile the vertex shader
  writef("start: calling CompileV(%n,gltstVshader.sdr) ",glprog)
  Vshader := Compileshader(glprog, TRUE, "gltstVshader.sdr")
  writef("=> Vshader=%n*n", Vshader)

  // Read and Compile the fragment shader
  writef("start: calling CompileF(%n,gltstFshader.sdr) ",glprog)
  Fshader := Compileshader(glprog, FALSE, "gltstFshader.sdr")
  writef("=> Fshader=%n*n", Fshader)

  // Link the program
  writef("start: calling glLinkProg(%n)*n", glprog)
  UNLESS glLinkProg(glprog) DO
  { writef("*nUnable to link a GL program*n")
    RESULTIS 0
  }

  writef("start: calling glUseProgram(%n)*n", glprog)
  glUseProgram(glprog)

  // Get attribute locations after linking
  VertexLoc := glGetAttribLocation(glprog, "g_vVertex")
  ColorLoc  := glGetAttribLocation(glprog, "g_vColor")
  DataLoc   := glGetAttribLocation(glprog, "g_vData")

  writef("VertexLoc=%n*n", VertexLoc)
  writef("ColorLoc=%n*n",  ColorLoc)
  writef("DataLoc=%n*n",   DataLoc)

  // Get uniform locations after linking
  MatrixLoc      := glGetUniformLocation(glprog, "matrix")
  ControlLoc     := glGetUniformLocation(glprog, "control")

  writef("MatrixLoc=%n*n",  MatrixLoc)
  writef("ControlLoc=%n*n", ControlLoc)

  //writef("start: calling glDeleteShader(%n)*n", Vshader)
  //glDeleteShader(Vshader)
  //writef("start: calling glDeleteShader(%n)*n", Fshader)
  //glDeleteShader(Fshader)

  // Load model

  UNLESS loadmodel(modelfile, @VertexData) DO
  { writef("*nUnable to load model: %s*n", modelfile)
    RESULTIS 0
  }

  IF debug DO
  { // Output the vertex and index data
    // as a debugging aid
    FOR i = 0 TO VertexDataSize-1 DO
    { IF i MOD 8 = 0 DO newline()
      writef(" %8.3d", sc3(VertexData!i))
    }
    newline()
    FOR i = 0 TO (IndexDataSize-1)/2 DO
    { LET w = IndexData!i
      IF i MOD 6 = 0 DO writef("*n%i6: ", 2*i)
      writef(" %i5 %i5", w & #xFFFF, w>>16)
    }
    newline()
  }

  sys(Sys_gl, GL_Enable, GL_DEPTH_TEST) // This call is neccessary
  sys(Sys_gl, GL_DepthFunc, GL_LESS)    // This the default

  // A pixel written if incoming depth < buffer depth
  // This assumes positive Z is into the screen, but
  // remember the depth test is performed after all other
  // transformations have been done.

  TEST useObjects
  THEN {
    // Setup the model using OpenGL objects
    writef("start: VertexDataSize=%n*n", VertexDataSize)
    VertexBuffer := sys(Sys_gl, GL_GenVertexBuffer, VertexDataSize, VertexData)

    // Tell GL the positions in VertexData of the xyz fields,
    // ie the first 3 words of each 8 word item in VertexData
    sys(Sys_gl, GL_EnableVertexAttribArray, VertexLoc);
    sys(Sys_gl, GL_VertexData,
                VertexLoc,     // Attribute number for xyz data
                3,             // 3 floats for xyz
                8,             // 8 floats per vertex item in vertexData
                0)             // Offset in words of the xyz data

    writef("start: VertexData xyz data copied to graphics object %n*n", VertexBuffer)

    // Tell GL the positions in VertexData of the rgb fields,
    // ie the second 3 words of each 8 word item in VertexData
    sys(Sys_gl, GL_EnableVertexAttribArray, ColorLoc);
    sys(Sys_gl, GL_VertexData,
                ColorLoc,      // Attribute number rgb data
                3,             // 3 floats for rgb data
                8,             // 8 floats per vertex item in vertexData
                3)             // Offset in words of the rgb data

    writef("start: ColourData rgb data copied to graphics object %n*n", VertexBuffer)

    // Tell GL the positions in VertexData of the kd fields,
    // ie word 6 of each 8 word item in VertexData
    sys(Sys_gl, GL_EnableVertexAttribArray, DataLoc);
    sys(Sys_gl, GL_VertexData,
                DataLoc,       // Attribute number rgb data
                2,             // 2 floats for kd data
                8,             // 8 floats per vertex item in vertexData
                6)             // Offset in words of the kd data

    writef("start: VertexData kd data copied to graphics object %n*n", VertexBuffer)

    // VertexData can now be freed
    //freevec(VertexData)

    writef("start: IndexDataSize=%n*n", IndexDataSize)
    IndexBuffer  := sys(Sys_gl, GL_GenIndexBuffer, IndexData, IndexDataSize)

    writef("start: IndexData copied to graphics memory object %n*n", IndexBuffer)

    // IndexData can now be freed
    //freevec(IndexData)
  } ELSE {
    // Setup the model not using objects
    sys(Sys_gl, GL_EnableVertexAttribArray, VertexLoc);
    sys(Sys_gl, GL_EnableVertexAttribArray, ColorLoc);
    sys(Sys_gl, GL_EnableVertexAttribArray, DataLoc);

    // The next call tells GL where the xyz fields of 
    // attribute VertexLoc appear in VertexData. It says
    // that each vertex is specified by items consisting
    // 8 words. The first 3 words of each item contains
    // the xyz values.
    glVertexData(VertexLoc,
                 3,            // 3 Values x, y, z
                 8,            // Stride of 8 words (=32 bytes)
                               // ie 8 values in VertexData per vertex
                 VertexData)   // Position of xyz value of vertex 0

    // The next call tells GL where the rgb fields of 
    // attribute ColorLoc appear in VertexData. It says
    // they are in 3 words at position 3 of each 8 word item.
    glVertexData(ColorLoc,
                 3,            // 3 Values r, g, b
                 8,            // Stride in words (=32 bytes)
                               // ie 8 values in VertexData per vertex
                 VertexData+3) // Position of rgb values of vertex 0

    // The next call tells GL where the kd fields of 
    // attribute ColorLoc appear in VertexData. It says
    // they are in the last 2 words of each 8 word item.
    glVertexData(DataLoc,
                 2,            // 2 Values k, d
                 8,            // Stride in words (=32 bytes)
                               // ie 8 values in VertexData per vertex
                 VertexData+6) // Position of kd values of vertex 0
  }

  // Initialise the state

  done     := FALSE
  stepping := FALSE

  // Set the initial direction cosines to orient t, w and l in
  // directions -z, -x and y, ie viewing the aircraft from behind.

  ctx, cty, ctz :=    0.0,  0.0, #-1.0
  cwx, cwy, cwz :=  #-1.0,  0.0,   0.0
  clx, cly, clz :=    0.0,  1.0,   0.0

  //rtdot, rwdot, rldot := 0.0,   0.0, 0.0
  rtdot, rwdot, rldot := 0.003, 0.001, 0.002 // Rotate the model slowly

  eyex, eyey, eyez := 0.0, 0.0, 1.0

  eyedistance := 150.000

  IF debug DO
  { glSetvec( workMatrix, 16,
                   2.0,  0.0,  0.0,  0.0,
                   0.0,  1.0,  0.0,  0.0,
                   0.0,  0.0,  1.0,  0.0,
                   0.0,  0.0,  0.0, 10.0
                 )
    glSetvec( projectionMatrix, 16,
                   1.0,  2.0,  3.0,  4.0,
                   5.0,  6.0,  7.0,  8.0,
                   9.0, 10.0, 11.0, 12.0,
                  13.0, 14.0, 15.0, 16.0
                 )
    newline()
    prmat(workMatrix)
    writef("times*n")
    prmat(projectionMatrix)
    glMat4mul(workMatrix, projectionMatrix, projectionMatrix)
    writef("gives*n")
    prmat(projectionMatrix)
    abort(1000)
  }

  UNTIL done DO
  { processevents()

    // Only rotate the object if not stepping
    UNLESS stepping DO
    { // If not stepping adjust the orientation of the model.
      rotate(rtdot, rwdot, rldot)
    }

    // Set the model rotation matrix from model
    // coordinates (t,w,l) to world coordinates (x,y,z)
    glSetvec( projectionMatrix, 16,
                    ctx,  cty, ctz, 0.0,  // column 1
                    cwx,  cwy, cwz, 0.0,  // column 2
                    clx,  cly, clz, 0.0,  // column 3
                    0.0,  0.0, 0.0, 1.0   // column 4
            )

    // Rotate the model and eye until the eye is on the z axis

    { LET ex, ey, ez = eyex, eyey, eyez
      LET oq = glRadius2(ex, ez) 
      LET op = glRadius3(ex, ey, ez)
      LET cos_theta = ez #/ oq 
      LET sin_theta = ex #/ oq 
      LET cos_phi      = oq #/ op 
      LET sin_phi      = ey #/ op 

      // Rotate anti-clockwise about Y axis by angle theta
      glSetvec( workMatrix, 16,
                  cos_theta, 0.0, sin_theta, 0.0,   // column 1
                        0.0, 1.0,       0.0, 0.0,   // column 2
                #-sin_theta, 0.0, cos_theta, 0.0,   // column 3
                        0.0, 0.0,       0.0, 1.0    // column 4
               )

      glMat4mul(workMatrix, projectionMatrix, projectionMatrix)

      // Rotate clockwise about X axis by angle phi
      glSetvec( workMatrix, 16,
                1.0,     0.0,       0.0, 0.0,    // column 1
                0.0, cos_phi, #-sin_phi, 0.0,    // column 2
                0.0, sin_phi,   cos_phi, 0.0,    // column 3
                0.0,     0.0,       0.0, 1.0     // column 4
               )

      glMat4mul(workMatrix, projectionMatrix, projectionMatrix)

      // Change the origin to the eye position on the z axis by
      // moving the model eyedistance in the negative z direction.
      glSetvec( workMatrix, 16,
                1.0, 0.0,           0.0, 0.0, // column 1
                0.0, 1.0,           0.0, 0.0, // column 2
                0.0, 0.0,           1.0, 0.0, // column 3
                0.0, 0.0, #-eyedistance, 1.0  // column 4
              )

      glMat4mul(workMatrix, projectionMatrix, projectionMatrix)
    }

    { // Define the truncated pyramid for the view projection
      // using the frustrum transformation.
      LET n, f = 0.1, 5000.0
      LET fan, fsn = f#+n, f#-n
      LET n2 = 2.0#*n
      LET l, r = #-0.5, 0.5
      LET ral, rsl = r#+l, r#-l
      LET b, t = #-0.5, 0.5 
      LET tab, tsb = t#+b, t#-b

      LET aspect = FLOAT screenxsize #/ FLOAT screenysize
      LET fv = 2.0 #/ 0.5  // Half field of view at unit distance
      glSetvec( workMatrix, 16,
           fv #/ aspect, 0.0,                         0.0,   0.0, // column 1
                    0.0,  fv,                         0.0,   0.0, // column 2
                    0.0, 0.0,        (f #+ n) #/ (n #- f), #-1.0, // column 3
                    0.0, 0.0, (2.0 #* f #* n) #/ (n #- f),   0.0  // column 4
                )

      // The perspective matrix could be set more conveniently using
      // glSetPerspective library function defined in g/gl.b
      //glSetPerspective(workMatrix,
      //                     aspect, // Aspect ratio
      //                        0.5, // Field of view at unit distance
      //                        0.1, // Distance to near limit
      //                     5000.0) // Distance to far limit

      glMat4mul(workMatrix, projectionMatrix, projectionMatrix)
    }

    // Send the matrix to uniform variable "matrix" for use by the
    // vertex shader.
    glUniformMatrix4fv(MatrixLoc, glprog, projectionMatrix)

    // Calculate the cosines and sines of the control surfaces.
    { LET RudderAngle = #- rldot #* 100.0
      CosRudder := sys(Sys_flt, fl_cos, RudderAngle)
      SinRudder := sys(Sys_flt, fl_sin, RudderAngle)
    }

    { LET ElevatorAngle = rwdot  #* 100.0
      CosElevator := sys(Sys_flt, fl_cos, ElevatorAngle)
      SinElevator := sys(Sys_flt, fl_sin, ElevatorAngle)
    }

    { LET AileronAngle = rtdot #* 100.0
      CosAileron := sys(Sys_flt, fl_cos, AileronAngle)
      SinAileron := sys(Sys_flt, fl_sin, AileronAngle)
    }

    // Send them to the graphics hardware as elements of the
    // uniform 4x4 matrix "control" for use by the vertex shader.
    { LET control = VEC 15
      FOR i = 0 TO 15 DO control!i := 0.0

      control!00 :=  CosRudder    // 0 0
      control!01 :=  SinRudder    // 0 1
      control!02 :=  CosElevator  // 0 2
      control!03 :=  SinElevator  // 0 3
      control!04 :=  CosAileron   // 1 0
      control!05 :=  SinAileron   // 1 1

      // Send the control values to the graphics hardware
      glUniformMatrix4fv(ControlLoc, glprog, control)
    }

    // Draw a new image
    glClearColour(130, 130, 250, 255)
    glClearBuffer() // Clear colour and depth buffers

    drawmodel()

    glSwapBuffers()

    delay(0_020) // Delay for 1/50 sec
  }

  sys(Sys_gl, GL_DisableVertexAttribArray, VertexLoc)
  sys(Sys_gl, GL_DisableVertexAttribArray, ColorLoc)
  sys(Sys_gl, GL_DisableVertexAttribArray, DataLoc)

  delay(0_050)
  glClose()

  RESULTIS 0
}

AND Compileshader(prog, isVshader, filename) = VALOF
{ // Create and compile a shader whose source code is
  // in a given file.
  // isVshader=TRUE if compiling a vertex shader
  // isVshader=FALSE if compiling a fragment shader
  LET oldin = input()
  LET oldout = output()
  LET buf = 0
  LET shader = 0
  LET ramstream = findinoutput("RAM:")
  LET instream = findinput(filename)
  UNLESS ramstream & instream DO
  { writef("Compileshader: Trouble with i/o streams*n")
    RESULTIS -1
  }

  //Copy shader program to RAM:
  //writef("Compiling shader %s*n", filename)
  selectoutput(ramstream)
  selectinput(instream)

  { LET ch = rdch()
    IF ch=endstreamch BREAK
    wrch(ch)
  } REPEAT

  wrch(0) // Place the terminating byte

  selectoutput(oldout)
  endstream(instream)
  selectinput(oldin)

  buf := ramstream!scb_buf

  shader := sys(Sys_gl,
                (isVshader -> GL_CompileVshader, GL_CompileFshader),
                prog,
                buf)

//writef("Compileshader: shader=%n*n", shader)
  endstream(ramstream)
  RESULTIS shader
}

AND drawmodel() BE
  TEST useObjects
  THEN { // Draw triangles using vertex and index data
         // held in graphics objects
         glDrawTriangles(IndexDataSize, 0)
       }
  ELSE { // Draw triangles using vertex and index data
         // held in main memory
         glDrawTriangles(IndexDataSize, IndexData)
       }

AND processevents() BE WHILE getevent() SWITCHON eventtype INTO
{ DEFAULT:
    //writef("processevents: Unknown event type = %n*n", eventtype)
    LOOP

  CASE sdle_keydown:
    SWITCHON capitalch(eventa2) INTO
    { DEFAULT:  LOOP

      CASE 'Q': done := TRUE
                LOOP

      CASE 'A': abort(5555)
                LOOP

      CASE 'P': // Print direction cosines and other data
                newline()
                writef("ct     %9.6d %9.6d %9.6d rtdot=%9.6d*n",
                       sc6(ctx),sc6(cty),sc6(ctz), sc6(rtdot))
                writef("cw     %9.6d %9.6d %9.6d rwdot=%9.6d*n",
                       sc6(cwx),sc6(cwy),sc6(cwz), sc6(rwdot))
                writef("cl     %9.6d %9.6d %9.6d rldot=%9.6d*n",
                       sc6(clx),sc6(cly),sc6(clz), sc6(rldot))
                newline()
                writef("eyepos %9.3d %9.3d %9.3d*n",
                        sc3(eyex), sc3(eyey), sc3(eyez))
                writef("eyedistance = %9.3d*n", sc3(eyedistance))
                LOOP

      CASE 'S': stepping := ~stepping
                LOOP

      CASE '0': eyex, eyez :=   0.000,   1.000; LOOP
      CASE '1': eyex, eyez :=   0.707,   0.707; LOOP
      CASE '2': eyex, eyez :=   1.000, #-0.000; LOOP
      CASE '3': eyex, eyez :=   0.707, #-0.707; LOOP
      CASE '4': eyex, eyez :=   0.000, #-1.000; LOOP
      CASE '5': eyex, eyez := #-0.707, #-0.707; LOOP
      CASE '6': eyex, eyez := #-1.000,   0.000; LOOP
      CASE '7': eyex, eyez := #-0.707,   0.707; LOOP

      CASE '=':
      CASE '+': eyedistance := eyedistance #* 1.1; LOOP

      CASE '_':
      CASE '-': IF eyedistance#>=1.0 DO
                   eyedistance := eyedistance #/ 1.1
                LOOP

      CASE '>':CASE '.':    rldot := rldot #+ 0.0005; LOOP
      CASE '<':CASE ',':    rldot := rldot #- 0.0005; LOOP

      CASE sdle_arrowdown:  rwdot := rwdot #+ 0.0005; LOOP
      CASE sdle_arrowup:    rwdot := rwdot #- 0.0005; LOOP

      CASE sdle_arrowleft:  rtdot := rtdot #+ 0.0005; LOOP
      CASE sdle_arrowright: rtdot := rtdot #- 0.0005; LOOP
    }
    LOOP

  CASE sdle_quit:             // 12
    writef("QUIT*n");
    sys(Sys_gl, GL_Quit)
    LOOP
}

// Convertion functions between floating point and scaled values.
AND sc3(x) = glF2N(    1_000, x)
AND sc6(x) = glF2N(1_000_000, x)

AND inprod(a,b,c, x,y,z) =
  // Return the cosine of the angle between two unit vectors.
  a #* x #+ b #* y #+ c #* z

AND rotate(t, w, l) BE
{ // Rotate the orientation of the aircraft
  // t, w and l are assumed to be small and cause
  // rotation about axis t, w, l. Positive values cause
  // anti-clockwise rotations about their axes.

  LET tx = inprod(1.0, #-l,   w,  ctx,cwx,clx)
  LET wx = inprod(  l, 1.0, #-t,  ctx,cwx,clx)
  LET lx = inprod(#-w,   t, 1.0,  ctx,cwx,clx)

  LET ty = inprod(1.0, #-l,   w,  cty,cwy,cly)
  LET wy = inprod(  l, 1.0, #-t,  cty,cwy,cly)
  LET ly = inprod(#-w,   t, 1.0,  cty,cwy,cly)

  LET tz = inprod(1.0, #-l,   w,  ctz,cwz,clz)
  LET wz = inprod(  l, 1.0, #-t,  ctz,cwz,clz)
  LET lz = inprod(#-w,   t, 1.0,  ctz,cwz,clz)

  ctx, cty, ctz := tx, ty, tz
  cwx, cwy, cwz := wx, wy, wz
  clx, cly, clz := lx, ly, lz

  adjustlength(@ctx);      adjustlength(@cwx);      adjustlength(@clx) 
  adjustortho(@ctx, @cwx); adjustortho(@ctx, @clx); adjustortho(@cwx, @clx)
}

AND adjustlength(v) BE
{ // This helps to keep vector v of unit length
  LET r = glRadius3(v!0, v!1, v!2)
  v!0 := v!0 #/ r
  v!1 := v!1 #/ r
  v!2 := v!2 #/ r
}

AND adjustortho(a, b) BE
{ // This helps to keep the unit vector b orthogonal to a
  LET a0, a1, a2 = a!0, a!1, a!2
  LET b0, b1, b2 = b!0, b!1, b!2
  LET corr = inprod(a0,a1,a2, b0,b1,b2)
  b!0 := b0 #- a0 #* corr
  b!1 := b1 #- a1 #* corr
  b!2 := b2 #- a2 #* corr
}

AND prmat(m) BE
{ prf8_3(m! 0)
  prf8_3(m! 4)
  prf8_3(m! 8)
  prf8_3(m!12)
  newline()
  prf8_3(m! 1)
  prf8_3(m! 5)
  prf8_3(m! 9)
  prf8_3(m!13)
  newline()
  prf8_3(m! 2)
  prf8_3(m! 6)
  prf8_3(m!10)
  prf8_3(m!14)
  newline()
  prf8_3(m! 3)
  prf8_3(m! 7)
  prf8_3(m!11)
  prf8_3(m!15)
  newline()
}

AND prv(v) BE
{ prf8_3(v!0)
  prf8_3(v!1)
  prf8_3(v!2)
  prf8_3(v!3)
}

AND prf8_3(x) BE writef(" %8.3d", sc3(x))

AND dbmatrix(m) BE //IF FALSE DO
{ LET x,y,z,w = ?,?,?,?
  LET v = @x
  LET n, p, one = #-0.5, #+0.5, 1.0
  prmat(m); newline()
  x,y,z,w := 1.0,0.0,0.0,1.0
  prv(v); glMat4mulV(m, v, v); writef(" => "); prv(v); newline()
  x,y,z,w := 0.0,1.0,0.0,1.0
  prv(v); glMat4mulV(m, v, v); writef(" => "); prv(v); newline()
  x,y,z,w := 0.0,0.0,1.0,1.0
  prv(v); glMat4mulV(m, v, v); writef(" => "); prv(v); newline()

  x,y,z,w := n,n,p,one
  prv(v); glMat4mulV(m, v, v); writef(" => "); prv(v); newline()
  x,y,z,w := p,n,p,one
  prv(v); glMat4mulV(m, v, v); writef(" => "); prv(v); newline()
  x,y,z,w := p,n,n,one
  prv(v); glMat4mulV(m, v, v); writef(" => "); prv(v); newline()
  x,y,z,w := n,n,n,one
  prv(v); glMat4mulV(m, v, v); writef(" => "); prv(v); newline()

  x,y,z,w := n,p,p,one
  prv(v); glMat4mulV(m, v, v); writef(" => "); prv(v); newline()
  x,y,z,w := p,p,p,one
  prv(v); glMat4mulV(m, v, v); writef(" => "); prv(v); newline()
  x,y,z,w := p,p,n,one
  prv(v); glMat4mulV(m, v, v); writef(" => "); prv(v); newline()
  x,y,z,w := n,p,n,one
  prv(v); glMat4mulV(m, v, v); writef(" => "); prv(v); newline()
  newline()
}

