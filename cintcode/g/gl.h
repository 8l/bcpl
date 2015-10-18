/*
######## UNDER DEVELOPMENT ################

This is the header file for the BCPL graphics interface that should
work with both OpenGL ES and the full version of OpenGL. The intention
is for BCPL programs to work without change under either version of
OpenGL.

This will be compiled with one of the following conditional
compilation options set.

  OpenGL       for the full OpenGL library used with SDL
  OpenGLES     for OpenGL ES for the Raspberry Pi

Implemented by Martin Richards (c) Jan 2014

History:
12/01/14
Initial implementation

g_glbase is set in libhdr to be the first global used in the gl library
It can be overridden by re-defining g_glbase after GETting libhdr.

A program wishing to use the SDL library should contain the following lines.

GET "libhdr"
MANIFEST { g_glbase=nnn  }  // Only used if the default setting of 450 in
                            // libhdr is not suitable.
GET "gl.h"
GET "gl.b"                  // Insert the library source code
.
GET "libhdr"
MANIFEST { g_glbase=nnn  }  // Only used if the default setting of 450 in
                            // libhdr is not suitable.
GET "gl.h"
Rest of the program
*/

GLOBAL {
// More functions will be included in due course
// All these functions capitalise the first letter of each
// word except the first, eg glMkScreen.
glInit: g_glbase

screen             // Handle to the screen surface
format             // Handle to the screen format, used by eg setcolour

screenxsize
screenysize

getevent           // sets event state
eventtype          // Event type set by getevent()
eventa1
eventa2
eventa3
eventa4
eventa5

glMkScreen         // (title, xsize, ysize)
glClose            // ()
glMkProg
glLoadShaderV      // (filename) load and compile
glLoadShaderF      // (filename) load and compile
glLinkProg
glBindAttribLocation
glBindUniformLocation
glGetAttribLocation
glGetUniformLocation
glLoadModel
glUseProgram
glUniform1f
glUniform2f
glUniform3f
glUniform4f
glDeleteShader
glUseProgram
glSwapBuffers
glClearColour
glClearBuffer

glCos       // (degrees)  Return cos of the angle as a float
glSin       // (degrees)  Return sin of the angle as a float
glF2N       // (scale, f) Convert to fixed
glN2F       // (scale, n) Convert to float
//glF2Nv      // (v, n, scale) Convert up to 16 values from float to fixed
//glN2Fv      // (v, n, scale) Convert up to 16 values from fixed to float
glMat4mul   // (a, b, c) Multiply 4x4 matrices a and b to give c
            // a,b and c need not be distinct. 
glMat4mulV  // (a, b, c) Multiply the 4x4 matrix a by vector b
            // to give vector c
            // b and c need not be distinct. 
glSetvec    // (v ,n, n0, n1,...) copy up to 16 values into v
glSetvecN2F // (v, n, scale, n0, n1,...)

            // Convert up to 16 scaled fixed point number to floats storing
            // them in v
glSetvecF2N // (v, n, scale, f0, f1,...)
            // Convert up to 16 floats to scaled fixed point storing them
            // in v
glSetPerspective // (mat4, fov, aspect, n, f)      -- Set the perspective matrix
glRadius2   // (x,y)   Return sqrt(x**2+y**2)      -- x, y and the result are floats
glRadius3   // (x,y,z) Return sqrt(x**2+y**2+z**2) -- x, y, z and the result are floats
glUniformMatrix4fv
glVertexData        // (loc, n, stride, datav)
glDrawTriangles     // (n, indexv)  -- n = number of triangles to draw

  loadmodel        // (filename, modelv) -- modelv = @VertexData

  lex
  ch
  lineno
  token
  lexval

  plotf              // (x, y, format, args...)
  plotfstr           // Used by plotf
}

MANIFEST {
// ops used in calls of the form: sys(Sys_gl, op,...)
// These should work when using a properly configured BCPL Cintcode system
// running under Linux, Windows or or OSX provided the OpenGL libraries
// have been installed.
// All manifests start with a capital letter.

GL_Init=1         // initialise SDL with everything
GL_SetFltScale=2    // Specify the integer that represents floating 1.0
GL_Quit=3           // Shut down SDL
GL_GetError=4       // str -- fill str with BCPL string for the latest GL error
GL_MkScreen=5       // width height
GL_SwapBuffers=6
GL_MkProg=7         // ()
GL_CompileVshader=8
GL_CompileFshader=9
GL_GetAttribLocation=10
GL_GetUniformLocation=11
GL_DeleteShader=12
GL_UseProgram=13
GL_LinkProgram=14
GL_Uniform1f=15
GL_Uniform2f=16
GL_Uniform3f=17
GL_Uniform4f=18
GL_LoadModel=19
GL_BindAttribLocation=20
GL_UniformMatrix4fv=21
GL_ClearColour=22
GL_ClearBuffer=23
GL_M4mulM4=24

GL_pollevent=25    // pointer to [type, args, ... ] to hold details of the next event
                   // return 0 if no events available
GL_Enable=26
GL_Disable=27
GL_DepthFunc=28
GL_VertexData=29
GL_DrawTriangles=30
GL_EnableVertexAttribArray=31
GL_DisableVertexAttribArray=32
GL_GenVertexBuffer=33
GL_GenIndexBuffer=34
GL_VertexAttribPointer=35
GL_M4mulV=36

sdle_active          = 1  // window gaining or losing focus
sdle_keydown         = 2  // => mod ch
sdle_keyup           = 3  // => mod ch
sdle_mousemotion     = 4  // => x y
sdle_mousebuttondown = 5  // => buttonbits
sdle_mousebuttonup   = 6  // => buttonbits
sdle_joyaxismotion   = 7
sdle_joyballmotion   = 8
sdle_joyhatmotion    = 9
sdle_joybuttondown   = 10
sdle_joybuttonup     = 11
sdle_quit            = 12
sdle_syswmevent      = 13
sdle_videoresize     = 14
sdle_userevent       = 15

sdle_arrowup         = 273
sdle_arrowdown       = 274
sdle_arrowright      = 275
sdle_arrowleft       = 276

  s_scale=1  // Used by loadmodel
  s_vertex
  s_index
  s_num
  s_eof

GL_DEPTH_TEST = 2929
GL_LESS = 513
}
