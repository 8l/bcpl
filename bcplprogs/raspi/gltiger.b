/*
This program is a demonstration of the OpenGL interface.

################ STILL UNDER DEVELOPMENT ########################

It is soon going to be modified to make extensive use of the floating
point facilities now available in BCPL. This modification involves
changing the BCPL GL library to use floating point.

The BCPL GL library is in g/gl.b with header g/gl.h and is designed to
work unchanged with either OpenGL using SDL or OpenGL ES using EGL and
some SDL features.

Implemented by Martin Richards (c) July 2014

History

20/12/14
Modified the cube to be like a square missile with control surfaces.
It will display a rotating tigermoth by default. 

03/12/14
Began conversion to use floating point numbers.



Command argument:

-a/n      Aircraft number, default = 0 for the tigermoth
          = 1 for the cube-like missile used in gltst.b 
OBJ       Use OpenGL Objects for vertex and index data
-d        Turn on debugging

Controls:

Q  causes quit
P  Output debugging info to the terminal
S  Stop/start the stepping the image

Rotational controls

Right/left arrow Increase/decrease rotation rate about direction of thrust
Up/Down arrow    Increase/decrease rotation rate about direction of left wing
>  <             Increase/decrease rotation rate about direction of lift

R   L            Increase/decrease cgndot
U   D            Increase/decrease cgwdot
F   B            Increase/decrease cghdot

0,1,2,3,4,5,6,7  Set eye direction -- the eye is always looking at
                                      the CG of the aircraft.

8,9              Increase/decrease eye height
+,-              Increase/decrease eye distance

The transformations

Three coordinate systems are used in this program.

The first specifies point (t,w,l) on the aircraft where t is the
distance fron the centre of gravity (CG) forward in the direction of
thrust. w is the distance from the CG in the direction of the left
wing, and l is the distance in the direction of lift. these three
directions are at right angles to each other. Mathematicians describe
them as orthogonal.

The second coordinate system (n,w,h) describes points using real world
coordinates. n is the distance north of the origin, w is the distance
west of the origin and h is the distance (height) above the
origin. The origin is chosen to be in the centre line of the runway at
its southern most end. The runway is aligned from south to north.

The third coordinate system (x,y,z) describes points as displayed on
the screen. In this system the origin is the centre of the screen. x
is the distance to the right of the origin and y is the distance above
the origin, and z is the distance from the origin towards the
viewer. Thus the further a point is from the viewer the more negative
will be its z component. These z components are used by the graphics
hardware to remove surfaces that are hidden behind other surfaces.

The orientation of the aircraft is specified by the followin nine
direction cosines.

  ctn; ctw; cth   // Direction cosines of direction t
  cwn; cww; cwh   // Direction cosines of direction w
  cln; clw; clh   // Direction cosines of direction l

  cgn; cgw; cgh   // Coordinates of the CG

  eyedirection    // =0 means the eye is looking horizontally
                  //    in the direction of thrust.
  eyerelh         // Relative to cgh
  eyedistance         holds the distance between the eye and
                      the CG of the aircraft.


  eyepn, eyepw, eyeph specify the real world coordinates of the
                      point (P) the eye is focussing on. P is
                      often the CG of the aircraft.

  eyen, eyew, eyeh    specify real world coordinates of a point
                      on the line of sight of the eye.

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
  aircraft          // =0 or 1
  stepping
  debug
  glprog
  Vshader
  Fshader

  VertexLoc       // Attribute variable locations
  ColorLoc
  DataLoc         // data[0]=ctrl  data[1]=value

  ModelMatrixLoc  // Uniform variable locations
  LandMatrixLoc
  ControlLoc

  CosElevator
  SinElevator
  CosRudder
  SinRudder
  CosAileron
  SinAileron

  modelfile

  // The following variables are floating point number

  ctn; ctw; cth   // Direction cosines of direction t
  cwn; cww; cwh   // Direction cosines of direction w
  cln; clw; clh   // Direction cosines of direction l

  rtdot; rwdot; rldot // Anti-clockwise rotation rates
                      // about the t, w and l axes
 
  cgn; cgw; cgh          // Coordinates of the CG of the aircraft
                         // in feet as a floating point number
  cgndot; cgwdot; cghdot // CG velocity

  eyedirection     // =0 to =7
  eyerelh          // height of the eye relative to cgh

  eyen; eyew; eyeh // Coordinates of a point on the line of sight
                   // from to eye to the origin (0.0,0.0,0.0).
  eyedistance      // The distance between the eye and the CG of
                   // the aircraft.

  // The next four variables must be in consecutive locations
  // since @VertexData is passed to loadmodel.
  VertexData       // Vector of 32-bit floating point numbers
  VertexDataSize   // = number of numbers in VertexData
  IndexData        // Vector of 16-bit unsigned integers
  IndexDataSize    // = number of 16-bit integers in IndexData

  useObjects       //= TRUE if using OpenGL Objects
  VertexBuffer
  IndexBuffer

  LandMatrix       // The matrix used by the vertex shader
                   // to transform the vertex coordinates of points
                   // on the land to screen coordinates.
  ModelMatrix      // The matrix used by the vertex shader
                   // to transform the vertex coordinates of points
                   // on the model to screen coordinates.
  WorkMatrix       // is used when constructing the projection matrix.
}

LET start() = VALOF
{ LET m1 = VEC 15
  LET m2 = VEC 15
  LET m3 = VEC 15
  LET argv = VEC 50
  LET modelfile = "tigermothmodel.mdl"
  LET aircraft = 0

  ModelMatrix, LandMatrix, WorkMatrix := m1, m2, m3

  UNLESS rdargs("-a/n,obj/s,-d/s", argv, 50) DO
  { writef("Bad arguments for gltst*n")
    RETURN
  }

  IF argv!0 DO aircraft := !argv!0 // -a/n
  useObjects := argv!1             // obj/s
  debug := argv!2                  // -d/s

  IF aircraft=1 DO modelfile := "gltst.mdl"

  writef("start: calling glInit*n")
  UNLESS glInit() DO
  { writef("*nOpenGL not available*n")
    RESULTIS 0
  }

  writef("start: calling glMkScreen*n")
  // Create an OpenGL window
  screenxsize := glMkScreen("Tigermoth flight simulator", 800, 680)
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
  writef("start: calling CompileV(%n,gltigerVshader.sdr) ",glprog)
  Vshader := Compileshader(glprog, TRUE, "gltigerVshader.sdr")
  writef("=> Vshader=%n*n", Vshader)

  // Read and Compile the fragment shader
  writef("start: calling CompileF(%n,gltigerFshader.sdr) ",glprog)
  Fshader := Compileshader(glprog, FALSE, "gltigerFshader.sdr")
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
  LandMatrixLoc  := glGetUniformLocation(glprog, "landmatrix")
  ModelMatrixLoc := glGetUniformLocation(glprog, "modelmatrix")
  ControlLoc     := glGetUniformLocation(glprog, "control")

  writef("LandMatrixLoc=%n*n",  LandMatrixLoc)
  writef("ModelMatrixLoc=%n*n", ModelMatrixLoc)
  writef("ControlLoc=%n*n",     ControlLoc)

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

  // Pixel written if incoming depth < buffer depth
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

  cgn,    cgw,    cgh    :=  0.0, 0.0, 20.0
  cgndot, cgwdot, cghdot :=  0.0, 0.0,  0.0


  // Set the initial direction cosines to orient t, w and l in
  // directions -z, -x and y, ie viewing the aircraft from behind.

  ctn, ctw, cth :=   1.0,  0.0,   0.0
  cwn, cww, cwh :=   0.0,  1.0,   0.0
  cln, clw, clh :=   0.0,  0.0,   1.0

  rtdot, rwdot, rldot := 0.0,   0.0, 0.0
  //rtdot, rwdot, rldot := 0.002, 0.003, 0.001 // Rotate the model slowly

  eyedirection :=  0         // Direction of thrust
  eyerelh      :=  0.0       // Relative to cgh
  eyedistance  := 50.000

  eyen, eyew, eyeh := 1.0, 0.0, 0.0


  IF debug DO
  { glSetvec( WorkMatrix, 16,
                   2.0,  0.0,  0.0,  0.0,
                   0.0,  1.0,  0.0,  0.0,
                   0.0,  0.0,  1.0,  0.0,
                   0.0,  0.0,  0.0, 10.0
                 )
    glSetvec( LandMatrix, 16,
                   1.0,  2.0,  3.0,  4.0,
                   5.0,  6.0,  7.0,  8.0,
                   9.0, 10.0, 11.0, 12.0,
                  13.0, 14.0, 15.0, 16.0
                 )
    newline()
    prmat(WorkMatrix)
    writef("times*n")
    prmat(LandMatrix)
    glMat4mul(WorkMatrix, LandMatrix, LandMatrix)
    writef("gives*n")
    prmat(LandMatrix)
    abort(1000)
  }

//sawritef("Entering main loop*n")

  UNTIL done DO
  { processevents()

    // Only rotate the object if not stepping
    UNLESS stepping DO
    { // If not stepping adjust the orientation of the model.
      rotate(rtdot, rwdot, rldot)

      // Move the centre of the model
      cgn := cgn #+ cgndot
      cgw := cgw #+ cgwdot
      cgh := cgh #+ cghdot
    }

    // We now construct the matrix LandMatrix to transform
    // points in real world coordinated to screen coordinates

    // We assume the eye is looking directly towards the centre
    // of gravity of the model.

    // First rotate world coordinate (n,w,u) to
    // screen coodinates (x,y,z)
    // ie  n -> -z
    //     w -> -x
    //     u ->  y
    // and translate the aircraft and land to place the aircraft CG
    // to the origin

    SWITCHON eyedirection INTO
    { DEFAULT:
      CASE 0: eyen, eyew := #-1.000,   0.000; ENDCASE
      CASE 1: eyen, eyew := #-0.707, #-0.707; ENDCASE
      CASE 2: eyen, eyew :=   0.0,   #-1.000; ENDCASE
      CASE 3: eyen, eyew :=   0.707, #-0.707; ENDCASE
      CASE 4: eyen, eyew :=   1.0,     0.000; ENDCASE
      CASE 5: eyen, eyew :=   0.707,   0.707; ENDCASE
      CASE 6: eyen, eyew :=   0.0,     1.000; ENDCASE
      CASE 7: eyen, eyew := #-0.707,   0.707; ENDCASE
    }

    eyeh := eyerelh

    // Matrix to move aircraft and land so that the CG of
    // the aircraft is at the origin

    glSetvec( LandMatrix, 16,
                      1.0,  0.0,   0.0, 0.0,   // column 1
                      0.0,  1.0,   0.0, 0.0,   // column 2
                      0.0,  0.0,   1.0, 0.0,   // column 3
                    #-cgn,#-cgw, #-cgh, 1.0    // column 4
             )

    // Rotate the model and eye until the eye is on the z axis
    
    { LET en, ew, eh = eyen, eyew, eyeh
      LET oq = glRadius2(en, ew) 
      LET op = glRadius3(en, ew, eh)
      LET cos_theta = #- en #/ oq 
      LET sin_theta = #- ew #/ oq 
      LET cos_phi   =    oq #/ op 
      LET sin_phi   =    eh #/ op 

      // Rotate anti-clockwise about h axis by angle theta
      // to move the eye onto the nh plane.
      glSetvec( WorkMatrix, 16,
                  cos_theta, #-sin_theta, 0.0, 0.0,   // column 1
                  sin_theta,   cos_theta, 0.0, 0.0,   // column 2
                        0.0,         0.0, 1.0, 0.0,   // column 3
                        0.0,         0.0, 0.0, 1.0    // column 4
               )
//sawritef("Rotation matrix R1*n")
//prmat(LandMatrix)
//abort(1000)
      glMat4mul(WorkMatrix, LandMatrix, LandMatrix)

      //newline()
      //writef("eyen=%6.3d eyew=%6.3d eyeh=%6.3d*n", eyen, eyew, eyeh)
      //writef("cgn= %6.3d cgw= %6.3d cgh= %6.3d*n", cgn,   cgw,  cgh)
      //writef("cos and sin of theta and phi: "); prv(@cos_theta); newline()
      //writef("Matrix to rotate and translate the model*n")
      //writef("and move the eye into the yz plane*n")
      //dbmatrix(LandMatrix)

      
      // Rotate clockwise about w axis by angle phi
      // to move the eye onto the n axis. 
      glSetvec( WorkMatrix, 16,
            cos_phi, 0.0, #-sin_phi, 0.0,    // column 1
                0.0, 1.0,       0.0, 0.0,    // column 2
            sin_phi, 0.0,   cos_phi, 0.0,    // column 3
                0.0, 0.0,       0.0, 1.0     // column 4
               )
//sawritef("Rotation matrix R2*n")
//prmat(WorkMatrix)
//abort(1000)
      glMat4mul(WorkMatrix, LandMatrix, LandMatrix)

      //newline()
      //writef("Matrix to rotate and translate the model*n")
      //writef("and move the eye onto the z axis*n")
      //dbmatrix(LandMatrix)
    }

// Matrix to transform world coordinates (n,w,h) to
// to screen coordinated ((x,y,z)
// ie x = -w
//    y =  h
//    z = -n

    glSetvec(WorkMatrix, 16,
                    0.0,  0.0, #-1.0, 0.0,   // column 1
                  #-1.0,  0.0,   0.0, 0.0,   // column 2
                    0.0,  1.0,   0.0, 0.0,   // column 3
                    0.0,  0.0,   0.0, 1.0    // column 4
            )

    glMat4mul(WorkMatrix, LandMatrix, LandMatrix)


//IF FALSE DO
    { // Change the origin to the eye position on the z axis by
      // moving the model eyedistance in the negative z direction.
      glSetvec( WorkMatrix, 16,
                1.0, 0.0,           0.0, 0.0, // column 1
                0.0, 1.0,           0.0, 0.0, // column 2
                0.0, 0.0,           1.0, 0.0, // column 3
                0.0, 0.0, #-eyedistance, 1.0  // column 4
              )

//sawritef("Change to eye origin matrix*n")
//prmat(WorkMatrix)
//abort(1000)
      glMat4mul(WorkMatrix, LandMatrix, LandMatrix)

      //newline()
      //writef("Matrix to rotate and translate the model*n")
      //writef("and move the eye onto the z axis*n")
      //writef("and move the eye a distance in the z direction*n")
      //dbmatrix(LandMatrix)
    }

//IF FALSE DO
    { // Define the truncated pyramid for the view projection
      // using the frustrum transformation.
      LET n, f = 0.1, 5000.0
      LET fan, fsn = f#+n, f#-n
      LET n2 = 2.0#*n
      LET l, r = #-0.5, 0.5
      LET ral, rsl = r#+l, r#-l
      LET b, t = #-0.5, 0.5 
      LET tab, tsb = t#+b, t#-b

      //glSetvec( WorkMatrix, 16,
      //          n2#/rsl,      0.0,            0.0,   0.0, // column 1
      //              0.0,  n2#/tsb,            0.0,   0.0, // column 2
      //         ral#/rsl, tab#/tsb,     #-fan#/fsn, #-1.0, // column 3
      //              0.0,      0.0, #-(n2#*f)#/fsn,   0.0  // column 4
      //        )

      // Alternatively use the perspective transformation explicitly.
      { LET aspect =  FLOAT screenxsize #/ FLOAT screenysize
        LET fv = 2.0              // Half field of view at unit distance
        glSetvec( WorkMatrix, 16,
           fv #/ aspect, 0.0,                         0.0,   0.0, // column 1
                    0.0,  fv,                         0.0,   0.0, // column 2
                    0.0, 0.0,        (f #+ n) #/ (n #- f), #-1.0, // column 3
                    0.0, 0.0, (2.0 #* f #* n) #/ (n #- f),   0.0  // column 4
                )

        // The perspective matrix could be set more conveniently using
        // glSetPerspective library function defined in g/gl.b
        //glSetPerspective(WorkMatrix,
        //                     aspect, // Aspect ratio
        //                        1.0, // Field of view at unit distance
        //                        0.1, // Distance to near limit
        //                     5000.0) // Distance to far limit
      }


//sawritef("work matrix*n")
//prmat(WorkMatrix)
//sawritef("Projection matrix*n")
//prmat(LandMatrix)
      glMat4mul(WorkMatrix, LandMatrix, LandMatrix)
//sawritef("final Projection matrix*n")
//dbmatrix(LandMatrix)

/*
      newline()
      writef(" n="); prf8_3(n)
      writef(" f=%8.3d", sc3(f))
      writef(" l=%8.3d", sc3(l))
      writef(" r=%8.3d", sc3(r))
      writef(" b=%8.3d", sc3(b))
      writef(" t=%8.3d", sc3(t))
      newline()
*/

//abort(1000)
    }

    // Send the LandMatrix to uniform variable "landmatrix" for
    // use by the vertex shader transform land points.
    glUniformMatrix4fv(LandMatrixLoc, glprog, LandMatrix)

    // Set the model rotation matrix from model
    // coordinates (t,w,l) to world coordinates (x,y,z)
    glSetvec( ModelMatrix, 16,
                    ctn,  ctw, cth, 0.0,  // column 1
                    cwn,  cww, cwh, 0.0,  // column 2
                    cln,  clw, clh, 0.0,  // column 3
                    0.0,  0.0, 0.0, 1.0   // column 4
            )
    ///newline()
    ///writef("Matrix to rotate the model*n")
    ///dbmatrix(LandMatrix)

    // Set the model's centre of gravity to (cgn,cgw,cgh)
    glSetvec( WorkMatrix, 16,
                  1.0, 0.0, 0.0, 0.0,    // column 1
                  0.0, 1.0, 0.0, 0.0,    // column 2
                  0.0, 0.0, 1.0, 0.0,    // column 3
                  cgn, cgw, cgh, 1.0     // column 4
               )

//sawritef("Translation matrix*n")
//prmat(WorkMatrix)
//abort(1000)

    glMat4mul(WorkMatrix, ModelMatrix, ModelMatrix)

    //newline()
    //writef("Matrix to rotate and translate the model*n")
    //dbmatrix(ModelMatrix)
    //abort(1000)

    // Now apply the projection transformation to the model matrix
    glMat4mul(LandMatrix, ModelMatrix, ModelMatrix)

    // Send the ModelMatrix to uniform variable "modelmatrix" for
    // use by the vertex shader transform points on the model.
    glUniformMatrix4fv(ModelMatrixLoc, glprog, ModelMatrix)

    // Calculate the cosines and sines of the control surfaces.
    { LET RudderAngle = #- rldot #* 100.0
      CosRudder := sys(Sys_flt, fl_cos, RudderAngle)
      SinRudder := sys(Sys_flt, fl_sin, RudderAngle)
//writef("RudderAngle = %9.3d  cos=%5.3d   sin=%5.3d*n",
//        sc3(RudderAngle), sc3(CosRudder), sc3(SinRudder))
    }

    { LET ElevatorAngle = rwdot  #* 100.0
      CosElevator := sys(Sys_flt, fl_cos, ElevatorAngle)
      SinElevator := sys(Sys_flt, fl_sin, ElevatorAngle)
//writef("ElevatorAngle = %9.3d  cos=%5.3d   sin=%5.3d*n",
//        sc3(ElevatorAngle), sc3(CosElevator), sc3(SinElevator))
    }

    { LET AileronAngle = rtdot #* 100.0
      CosAileron := sys(Sys_flt, fl_cos, AileronAngle)
      SinAileron := sys(Sys_flt, fl_sin, AileronAngle)
    }

    // Send them to the graphics hardware as elements of the
    // uniform matrix "control" for use by the vertex shader.
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

//writef(" %5.3d %5.3d %5.3d %5.3d %5.3d %5.3d*n",
//        sc3(CosRudder), sc3(CosElevator), sc3(CosAileron),
//        sc3(SinRudder), sc3(SinElevator), sc3(SinAileron))

    // Draw a new image
    glClearColour(130, 130, 250, 255)
    glClearBuffer() // Clear colour and depth buffers

    drawmodel()

IF FALSE DO
    FOR i = -1 TO 1 BY 2 DO
    { // Draw half size images either side
      glSetvec( LandMatrix, 16,
                   ctn#/100.0,  ctw#/100.0, cth#/100.0, 0.0, // column 1
                   cwn#/100.0,  cww#/100.0, cwh#/100.0, 0.0, // column 2
                   cln#/100.0,  clw#/100.0, clh#/100.0, 0.0, // column 3
      cgn#+0.450#*(FLOAT i),       cgw,        cgh,     1.0  // column 4
              )

      glSetPerspective(WorkMatrix, 1.0, 0.5, 0.1, 5000.0)
      glMat4mul(WorkMatrix, LandMatrix, LandMatrix)

      // Send the matrix to uniform variable "matrix" for use
      // by the vertex shader.
      glUniformMatrix4fv(ModelMatrixLoc, glprog, LandMatrix)

      drawmodel()
    }

  //  plotf(250, 30, "First Demo")

    glSwapBuffers()

    delay(0_020) // Delay for 1/50 sec
//abort(1000)
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
                writef("xyz=   %9.3d %9.3d %9.3d*n",
                       sc3(cgn),sc3(cgw),sc3(cgh))
                writef("ct     %9.6d %9.6d %9.6d rtdot=%9.6d*n",
                       sc6(ctn),sc6(ctw),sc6(cth), sc6(rtdot))
                writef("cw     %9.6d %9.6d %9.6d rwdot=%9.6d*n",
                       sc6(cwn),sc6(cww),sc6(cwh), sc6(rwdot))
                writef("cl     %9.6d %9.6d %9.6d rldot=%9.6d*n",
                       sc6(cln),sc6(clw),sc6(clh), sc6(rldot))
                newline()
                writef("eyedirection %n*n", eyedirection)
                writef("eyepos %9.3d %9.3d %9.3d*n",
                        sc3(eyen), sc3(eyew), sc3(eyeh))
                writef("eyedistance = %9.3d*n", sc3(eyedistance))
                LOOP

      CASE 'S': stepping := ~stepping
                LOOP

      CASE 'L': // Increase cgwdot
                cgwdot := cgwdot #+ 0.05
                LOOP

      CASE 'R': // Decrease cgwdot
                cgwdot := cgwdot #- 0.05
                LOOP

      CASE 'U': // Increase cghdot
                cghdot := cghdot #+ 0.05
                LOOP

      CASE 'D': // Decrease cghdot
                cghdot := cghdot #- 0.05
                LOOP

      CASE 'F': // Increase cgndot
                cgndot := cgndot #+ 0.05
                LOOP

      CASE 'B': // Decrease cgndot
                cgndot := cgndot #- 0.05
                LOOP

      CASE '0':
      CASE '1':
      CASE '2':
      CASE '3':
      CASE '4':
      CASE '5':
      CASE '6':
      CASE '7': eyedirection := eventa2 - '0'
                LOOP

      CASE '8': eyerelh := eyerelh #+ 0.1; LOOP
      CASE '9': eyerelh := eyerelh #+ #- 0.1; LOOP

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

  CASE sdle_videoresize:      // 14
    //writef("videoresize*n", eventa1, eventa2, eventa3)
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

  LET tx = inprod(1.0, #-l,   w,  ctn,cwn,cln)
  LET wx = inprod(  l, 1.0, #-t,  ctn,cwn,cln)
  LET lx = inprod(#-w,   t, 1.0,  ctn,cwn,cln)

  LET ty = inprod(1.0, #-l,   w,  ctw,cww,clw)
  LET wy = inprod(  l, 1.0, #-t,  ctw,cww,clw)
  LET ly = inprod(#-w,   t, 1.0,  ctw,cww,clw)

  LET tz = inprod(1.0, #-l,   w,  cth,cwh,clh)
  LET wz = inprod(  l, 1.0, #-t,  cth,cwh,clh)
  LET lz = inprod(#-w,   t, 1.0,  cth,cwh,clh)

  ctn, ctw, cth := tx, ty, tz
  cwn, cww, cwh := wx, wy, wz
  cln, clw, clh := lx, ly, lz

  adjustlength(@ctn);      adjustlength(@cwn);      adjustlength(@cln) 
  adjustortho(@ctn, @cwn); adjustortho(@ctn, @cln); adjustortho(@cwn, @cln)
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
