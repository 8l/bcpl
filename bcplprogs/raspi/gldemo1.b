/*
################ UNDER DEVELOPMENT ########################
This program is a demonstration of the OpenGL interface.

It uses the BCPL library g/gl.b with header g/gl.h and should work
unchanged with either OpenGL using SDL or OpenGL ES using EGL.

Implemented by Martin Richards (c) 11 Feb 2014

Q  causes quit
D  toggles debugging output

*/

GET "libhdr"
GET "gl.h"
GET "gl.b"          // Insert the library source code
.
GET "libhdr"
GET "gl.h"

GLOBAL {
  stdin: ug
  stdout
  tracing
  program
  vshader
  fshader
}


LET start() = VALOF
{ LET argv = VEC 50

  UNLESS rdargs("-t/s", argv, 50) DO
  { writef("Bad arguments for gldemo1*n")
    RESULTIS 0
  }

  tracing := argv!0                 // -t/s

  UNLESS glinitgl() DO
  { writef("OpenGL is not available*n")
    RESULTIS 0
  }

  stdout := output()

  program := glMkProgram()
  addVshader(program)
  addFshader(program)

  // Create an OpenGL window
  UNLESS glMkScreen("OpenGL Demo 1", 800, 620) DO
  { //writef("*nUnable to create an OpenGL window*n")
    RESULTIS 0
  }

  RESULTIS 0
}

AND addVshader(prog) = VALOF
{ LET res = TRUE
  LET ramstr = findinoutput("RAM:")

  UNLESS ramstr DO
  { writef("Trouble with RAM stream*n")
    RESULTIS FALSE
  }

  selectoutput(ramstr)

  writes(
    "attribute vec4 g_vVertex;*n*
    *attribute vec4 g_vColour;*n*
    *varying   vec4 g_vVSColour;*n*

    *void main()*n*
    *{ gl_Position = vec4(g_Vertex.x, g_Vertex.y,*n*
    *                     g_Vertex.z, g_Vertex.w)*n*
    *}*n"
  )

  res := glCompileVshader(prog, ramstr)
  endstream(ramstr)
  RESULTIS res
}

AND addFshader(prog) = VALOF
{ LET res = TRUE
  LET ramstr = findinoutput("RAM:")

  UNLESS ramstr DO
  { writef("Trouble with RAM stream*n")
    RESULTIS FALSE
  }

  selectoutput(ramstr)

  writes(
    "precision mediump;*n*
    *varying   vec4 g_vVSColour;*n*

    *void main()*n*
    *{ gl_FragColor = g_vVSColor;*n*
    *}*n"
  )

  res := glCompileFshader(prog, ramstr)
  endstream(ramstr)
  RESULTIS res
}





