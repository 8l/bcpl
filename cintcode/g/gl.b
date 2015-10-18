/*
############### UNDER DEVELOPMENT #####################

This library provides some functions that interface with the OpenGL
Graphics library that should work with both OpenGL ES using EGL and
the full version of OpenGL using SDL. The intention is for BCPL
programs to work without change under either version of OpenGL.

This will be compiled with one of the following conditional
compilation options set.

  OpenGL       for the full OpenGL library used with SDL
  OpenGLES     for OpenGL ES in the Raspberry Pi

Implemented by Martin Richards (c) Jan 2014

Change history:

26/08/12
Initial implementation.

15/07/13
Started adding OpenGL functions.


This library provide the BCPL interface to the OpenGL features. Even
if OpenGL is called from EGL and not SDL, the SDL features will be
available providing access to keyboard, mouse and joy stick events,
and possibly sound features.

This library should be included as a separate section for programs
that need it. Such programs typically have the following structure.

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

LET glInit() = VALOF
{ LET mes = VEC 256/bytesperword
  mes%0 := 0

  UNLESS sys(Sys_gl, GL_Init) DO
  { //sys(Sys_gl, GL_getError, mes)
    sawritef("*nglInit unable to initialise OpenGL: %s*n", mes)
    RESULTIS FALSE
  }

  // Successful
  RESULTIS TRUE
}

AND glMkScreen(title, xsize, ysize) = VALOF
{ // Create an OpenGL window with given title and size
  LET mes = VEC 256/bytesperword
  mes%0 := 0

  //writef("glMkScreen: Creating an OpenGL window*n")

  screenxsize, screenysize := xsize, ysize

  //writef("MkScreen: calling sys(Sys_gl, GL_MkScreen, %s, %n %n)*n",
  //        title, xsize, ysize)

  screenxsize := sys(Sys_gl, GL_MkScreen, title, xsize, ysize)
  screenysize := result2

  writef("GL_MkScreen: returned screen size %n x %n*n",
         screenxsize, screenysize)

  UNLESS screenxsize>0 DO
  { //sys(Sys_gl, GL_GetError, mes)
    writef("Unable to create an OpenGL screen: *n", mes)
    RESULTIS 0
  }

  result2 := screenysize
  RESULTIS screenxsize
}

AND glClose() BE
{ sys(Sys_gl, GL_Quit)
}

AND glMkProg() = VALOF
{ //writef("glMkProg: entered*n")
  RESULTIS sys(Sys_gl, GL_MkProg)
}

AND glCompileVshader(prog, cstr)  = VALOF
{ // Create and compile the vertex shader whose source is
  // in the C string cstr
  //writef("glCompileVshader: entered, prog=%n cstr=%n*n", prog, cstr)
  sys(Sys_gl, GL_CompileVshader, prog, cstr)
  RESULTIS -1
}

AND glCompileFshader(prog, cstr)  = VALOF
{ // Create and compile the fragment shader whose source is
  // in the C string cstr
  //writef("glCompileFshader: entered, prog=%n cstr=%n*n", prog, cstr)
  sys(Sys_gl, GL_CompileFshader, prog, cstr)
  RESULTIS -1
}
 
AND glLinkProg(prog) = VALOF
{ //writef("glLinkProg(%n): entered*n", prog)
  RESULTIS sys(Sys_gl, GL_LinkProgram, prog)
}
 
AND glBindAttribLocation(prog, loc, name) = VALOF
{ // Specify attribute location before linking.
  //writef("glBindAttribLocation(%n, %n, %s): entered*n", prog, loc, name)
  RESULTIS sys(Sys_gl, GL_BindAttribLocation, prog, loc, name)
}
 
AND glGetAttribLocation(prog, name) = VALOF
{ // Get attribute location after linking.
  //writef("glGetAttribLocation(%n, %s): entered*n", prog, name)
  RESULTIS sys(Sys_gl, GL_GetAttribLocation, prog, name)
}
 
AND glGetUniformLocation(prog, name) = VALOF
{ // Get uniform location after linking
  //writef("glGetUniformLocation(%n, %s): entered*n", prog, name)
  RESULTIS sys(Sys_gl, GL_GetUniformLocation, prog, name)
}
 
AND glLoadModel(prog, name)  = VALOF
{ //writef("glLoadModel: %n %s entered*n", prog, name)
  RESULTIS -1
}

AND glUseProgram(prog) = VALOF
{ //writef("glUseProgram: %n entered*n", prog)
  RESULTIS  sys(Sys_gl, GL_UseProgram, prog)
}
 
AND sc3(x) = glF2N(    1_000, x)// #*    1000.0)
AND sc6(x) = glF2N(1_000_000, x)// #* 1000000.0)


AND glUniform1f(loc, x) = VALOF
{ //writef("gl.b: glUniform1f: loc=%6i x=%8.3d*n",
  //       loc, sc3(x))
  sys(Sys_gl, GL_Uniform1f, loc, x)
//abort(1000)
  RESULTIS -1
}
 
AND glUniform2f(loc, x, y) = VALOF
{ //writef("gl.b: glUniform2f: loc=%6i x=%8.3d y=%8.3d*n",
  //        loc, sc3(x), sc3(y))
  sys(Sys_gl, GL_Uniform2f, loc, x, y)
//abort(1000)
  RESULTIS -1
}
 
AND glUniform3f(loc, x, y, z) = VALOF
{ //writef("gl.b: glUniform3f: loc=%6i x=%8.3d y=%8.3d z=%8.3d*n",
  //       loc, sc3(x), sc3(y), sc3(z))
  sys(Sys_gl, GL_Uniform3f, loc, x, y, z)
//abort(1000)
  RESULTIS -1
}
 
AND glUniform4f(loc, x, y, z, w) = VALOF
{ //writef("gl.b: glUniform4f: loc=%6i x=%8.3d y=%8.3d z=%8.3d w=%8.3d*n",
  //       loc, sc3(x), sc3(y), sc3(z), sc3(w))
  sys(Sys_gl, GL_Uniform4f, loc, x, y, z, w)
//abort(1000)
  RESULTIS -1
}
 
AND glDeleteShader(shader) = VALOF
{ //writef("glDeleteShader: %n entered*n", shader)
  RESULTIS -1
}
 
AND glSwapBuffers() = VALOF
{ //writef("glSwapBuffers: entered*n")
  RESULTIS sys(Sys_gl, GL_SwapBuffers)
}
 
AND glCos(angle) = VALOF
{ // angle is fixed point in degrees with 6 decimal after
  // the decimal point. The result is a float.
  LET radians = sys(Sys_flt, fl_N2F,
                    muldiv(angle, 3_141593, 1_000000),
                    180_000000)
  RESULTIS sys(Sys_flt, fl_cos, radians)
}

AND glSin(angle) = VALOF
{ // angle is fixed point in degrees with 6 decimal after
  // the decimal point. The result is a float.
  LET radians = sys(Sys_flt, fl_N2F,
                    muldiv(angle, 3_141593, 1_000000),
                    180_000000)
  RESULTIS sys(Sys_flt, fl_sin, radians)
}

AND glSetIdent4(v) BE
{ glSetvecN2F(v, 16, 1,
              1, 0, 0, 0,
              0, 1, 0, 0,
              0, 0, 1, 0,
              0, 0, 0, 1)
}

AND glSetvec(v, n,
             n0,n1,n2,n3,n4,n5,n6,n7,n8,n9,n10,n11,n12,n13,n14,n15) BE
{ LET p = @n0
//writef("glSetvec: entered*n")
  FOR i = 0 TO n-1 DO v!i := p!i
}

// Used to set colours, points, mat3 and mat4, etc
AND glSetvecN2F(v, n, scale,
                n0,n1,n2,n3,n4,n5,n6,n7,n8,n9,n10,n11,n12,n13,n14,n15) BE
{ LET p = @n0
//writef("glSetvecN2F: entered*n")
  FOR i = 0 TO n-1 DO
    v!i := sys(Sys_flt, fl_N2F, scale, p!i)
}

AND glSetvecF2N(v, n, scale,
                f0,f1,f2,f3,f4,f5,f6,f7,f8,f9,f10,f11,f12,f13,f14,f15) BE
{ LET p = @f0
//writef("glSetvecF2N: entered*n")
  FOR i = 0 TO n-1 DO
    v!i := sys(Sys_flt, fl_F2N, scale, p!i)
}

AND glSetPerspective(mat4, aspect, fov, n, f) BE
{ // The field of view is given as a field of view at unit distance
  // ie field of view is 45 degrees if fov=2.0
  // aspect = width/height of screen in pixels
  LET fv = 2.0 #/ fov

  mat4!00 := fv #/ aspect // Column 1
  mat4!01 := 0.0
  mat4!02 := 0.0
  mat4!03 := 0.0

  mat4!04 := 0.0          // Column 2
  mat4!05 := fv
  mat4!06 := 0.0
  mat4!07 := 0.0

  mat4!08 := 0.0         // Column 3
  mat4!09 := 0.0
  mat4!10 := (f #+ n) #/ (n #- f)
  mat4!11 := #-1.0

  mat4!12 := 0.0         // Column 4
  mat4!13 := 0.0
  mat4!14 := (2.0 #* f #* n) #/ (n #- f)
  mat4!15 := 0.0
}

AND glRadius2(x, y) = VALOF
{ LET a = sys(Sys_flt, fl_mul, x, x)
  a := sys(Sys_flt, fl_add, a, sys(Sys_flt, fl_mul, y, y))
  RESULTIS sys(Sys_flt, fl_sqrt, a)
}

AND glRadius3(x, y, z) = VALOF
{ LET a = sys(Sys_flt, fl_mul, x, x)
  a := sys(Sys_flt, fl_add, a, sys(Sys_flt, fl_mul, y, y))
  a := sys(Sys_flt, fl_add, a, sys(Sys_flt, fl_mul, z, z))
  RESULTIS sys(Sys_flt, fl_sqrt, a)
}

// glN2F(1_000, 1_234) => 1.234
AND glN2F(scale, n) = sys(Sys_flt, fl_N2F, scale, n)

// glF2N(1_000, 1.234) => 1_234
AND glF2N(scale, x) = sys(Sys_flt, fl_F2N, scale, x)

// glN2Fv converts n scaled fixed point numbers in v to floating
//AND glN2Fv(v, n, scale) BE
//  FOR i = 0 TO n-1 DO v!i := sys(Sys_flt, fl_N2F, scale, v!i)

// glF2Nv converts n floating point numbers to scaled fixed point.
//AND glF2Nv(v, n, scale) BE
//  FOR i = 0 TO n-1 DO v!i := sys(Sys_flt, fl_F2N, v!i, scale)

AND glMat4mul(a, b, c) BE
{ // Perform c := a*b, where a and b are 4x4 floating point matrices
  // a,b and c need not be distinct.
//writef("glMat4mul: calling GL_M4mulM4 %n %n %n*n", a, b, c)
  sys(Sys_gl, GL_M4mulM4, a, b, c)
}

AND glMat4mulV(a, b, c) BE
{ // Perform c := a*b, where a is a 4x4 floating point matrix
  // and b and c are 4 element vectors. b and c need not be distinct.
//writef("glMat4mulV: calling GL_M4mulV %n %n %n*n", a, b, c)
  sys(Sys_gl, GL_M4mulV, a, b, c)
}

AND glUniformMatrix4fv(loc, prog, matrix) BE
{ //writef("glUniformmatrix4fv: entered*n")
  sys(Sys_gl, GL_UniformMatrix4fv, loc, prog, matrix)
}

AND glClearColour(r, g, b, a) BE
{ sys(Sys_gl, GL_ClearColour, r,g,b,a)
}

AND glClearBuffer() BE
{ sys(Sys_gl, GL_ClearBuffer)
}

AND getevent() = VALOF
{ //writef("gl: Calling sys(Sys_sdl, GL_pollevent...)*n")
  RESULTIS sys(Sys_gl, GL_pollevent, @eventtype)
}

AND loadmodel(filename, modelv) = VALOF
{ // This function reads a .mdl file specifying the vertices and
  // indices of a model. It returns TRUE if successful.
  // It updates
  // modelv!0 to point to the vertex data
  // modelv!1 to the number of values in the vertex data
  // modelv!2 to point to the index data packed as 16-bit values
  // modelv!3 to the number of 16-bit values in the index data.

  LET res = TRUE
  LET stdin = input()
  LET instream = findinput(filename)
  LET scale = 1_000 // The default scale
                    // It is the scaled fixed point value representing 1.000
  LET vdata = TRUE  // Initially reading vertex data by default
  // Declare self expanding vectors for the
  LET vvec, vp, vupb = 0, -1, -1 // vertices and
  LET ivec, ip, iupb = 0, -1, -1 // indices.

  UNLESS instream DO
  { writef("Trouble with file %s*n", filename)
    RESULTIS FALSE
  }

  selectinput(instream)

  ch := rdch()
  lineno := 1 // The first line has lineno=1

nxt:
  lex()

  SWITCHON token INTO
  { DEAFAULT:  writef("line %n: Bad model file*n", lineno)
               res := FALSE
               GOTO ret

    CASE s_scale:         // s scale
      lex()
      UNLESS token = s_num DO
      { writef("Line %n: Bad Scale statement*n", lineno)
        res := FALSE
        GOTO ret
      }
      scale := lexval
      GOTO nxt

    CASE s_vertex:
      vdata := TRUE
      GOTO nxt

    CASE s_index:
      vdata := FALSE
      GOTO nxt

    CASE s_num:
      TEST vdata
      THEN pushf(@vvec, glN2F(scale, lexval))
      ELSE pushi(@ivec, lexval)
      GOTO nxt

    CASE s_eof:
      ENDCASE
  }

  modelv!0, modelv!1 := vvec, vp+1
  modelv!2, modelv!3 := ivec, ip+1

//writef("Model %s*n", filename, vp+1, ip+1)
//writef("VertexData= %i7 VertexDataSize= %i4*n", vvec, vp+1)
//writef("IndexData = %i7 IndexDataSize = %i4*n", ivec, ip+1)

ret:
  IF instream DO endstream(instream)
  selectinput(stdin)
  RESULTIS res
}

AND lex() BE
{ LET neg = FALSE

  SWITCHON ch INTO
  { DEFAULT:
      writef("line %n: Bad character '%c' in model file*n", lineno, ch)
      ch := rdch()
      LOOP

    CASE 'z':            // A debugging aid
    CASE endstreamch:
      token := s_eof
      RETURN

    CASE '/': // Skip over comments
      UNTIL ch='*n' | ch=endstreamch DO ch := rdch()
      LOOP

    CASE '*n':
      lineno := lineno+1

    CASE '*s':
      ch := rdch()
      LOOP

    CASE 's':
      token := s_scale
      ch := rdch()
      RETURN

    CASE 'v':
      token := s_vertex
      ch := rdch()
      RETURN

    CASE 'i':
      token := s_index
      ch := rdch()
      RETURN

    CASE '-':
      neg := TRUE
    CASE '+':
      ch := rdch()

    CASE '0': CASE '1': CASE '2': CASE '3': CASE '4': 
    CASE '5': CASE '6': CASE '7': CASE '8': CASE '9':
      lexval := 0
      WHILE '0'<=ch<='9' DO
      { lexval := 10*lexval + ch - '0'
        ch := rdch()
      }
      IF neg DO lexval := - lexval
      token := s_num
      RETURN
  }
} REPEAT

AND pushf(v, val) BE
{ // v is a self expanding vector of 32-bit values
  // v -> [data, p, upb]
  // Initially data=0, p=-1 and upb=-1
  // If p>=0 data!p holds the latest value pushed into v
  // When necessary, a new larger vector data is allocated
  // initialised with the content of the previous vector.
  LET data, p, upb = v!0, v!1, v!2

  IF p=upb DO
  { // We must expand the vector
    LET newupb = (upb+10)*3/2
    LET newdata = getvec(newupb)
    UNLESS newdata DO
    { writef("More memory needed*n")
      abort(999)
    }
    FOR i = 0 TO upb DO newdata!i := data!i
    FOR i = upb+1 TO newupb DO newdata!i := 0
    IF data DO freevec(data)
    v!0, v!2 := newdata, newupb
    data := newdata
  }
  p := p+1
  data!p, v!1 := val, p
  //writef("pushf: %i3 %x8*n", p, val)
}

AND pushi(v, val) BE
{ // v is a self expanding vector of 16-bit values
  // v -> [data, p, upb]
  // Initially data=0, p=-1 and upb=-1
  // data has room for upb+1 16-bit values
  // If p>=0 get16(data,p) holds the latest 16-bit value pushed into v
  // When necessary, a new larger vector data is allocated
  // initialised with the content of the previous vector.
  LET data, p, upb = v!0, v!1, v!2

  IF p=upb DO
  { // We must expand the vector
    LET newupb = (upb+10)*3/2 | 1 // Ensure that it is odd
    LET wupb = newupb/2
    LET newdata = getvec(wupb)
    UNLESS newdata DO
    { writef("More memory needed*n")
      abort(999)
    }
    FOR i = 0 TO p/2 DO newdata!i := data!i
    FOR i = p/2+1 TO newupb/2 DO newdata!i := 0
    IF data DO freevec(data)
    v!0, v!2 := newdata, newupb
    data := newdata
  }
  p := p+1
  v!1 := p
  put16(data, p, val)
  //writef("pushi: %i3 %i4*n", p, val)
}

AND get16(v, i) = VALOF
{ LET w = 0
  LET p = 2*i
  LET a, b = v%p, v%(p+1)
  (@w)%0 := 1
  TEST (w & 1) = 0
  THEN RESULTIS (a<<8) + b // Big ender m/c 
  ELSE RESULTIS (b<<8) + a // Little ender m/c 
}

AND put16(v, i, val) BE
{ LET w = 0
  LET p = 2*i
  LET a, b = val&255, (val>>8) & 255
  (@w)%0 := 1
  TEST (w & 1) = 0
  THEN v%p, v%(p+1) := b, a // Big ender m/c 
  ELSE v%p, v%(p+1) := a, b // Little ender m/c 
}

AND glVertexData(loc, n, stride, data) BE
  sys(Sys_gl, GL_VertexData, loc, n, stride, data)

AND glDrawTriangles(n, indexv) BE
  // n = number of index values (3 index values per triangle)
  // indexv is a vector of unsigned 16-bit integers
  sys(Sys_gl, GL_DrawTriangles, n, indexv)

/*
AND drawch(ch) BE TEST ch='*n'
THEN { currx, curry := 10, curry-14
     }
ELSE { FOR line = 0 TO 11 DO
         write_ch_slice(currx, curry+11-line, ch, line)
       currx := currx+9
     }

AND write_ch_slice(x, y, ch, line) BE
{ // Writes the horizontal slice of the given character.
  // Character are 8x12
  LET cx, cy = currx, curry
  LET i = (ch&#x7F) - '*s'
  // 3*i = subscript of the character in the following table.
  LET charbase = TABLE // Still under development !!!
         #X00000000, #X00000000, #X00000000, // space
         #X18181818, #X18180018, #X18000000, // !
         #X66666600, #X00000000, #X00000000, // "
         #X6666FFFF, #X66FFFF66, #X66000000, // #
         #X7EFFD8FE, #X7F1B1BFF, #X7E000000, // $
         #X06666C0C, #X18303666, #X60000000, // %
         #X3078C8C8, #X7276DCCC, #X76000000, // &
         #X18181800, #X00000000, #X00000000, // '
         #X18306060, #X60606030, #X18000000, // (
         #X180C0606, #X0606060C, #X18000000, // )
         #X00009254, #X38FE3854, #X92000000, // *
         #X00000018, #X187E7E18, #X18000000, // +
         #X00000000, #X00001818, #X08100000, // ,
         #X00000000, #X007E7E00, #X00000000, // -
         #X00000000, #X00000018, #X18000000, // .
         #X06060C0C, #X18183030, #X60600000, // /
         #X386CC6C6, #XC6C6C66C, #X38000000, // 0
         #X18387818, #X18181818, #X18000000, // 1
         #X3C7E6206, #X0C18307E, #X7E000000, // 2
         #X3C6E4606, #X1C06466E, #X3C000000, // 3
         #X1C3C3C6C, #XCCFFFF0C, #X0C000000, // 4
         #X7E7E6060, #X7C0E466E, #X3C000000, // 5
         #X3C7E6060, #X7C66667E, #X3C000000, // 6
         #X7E7E0606, #X0C183060, #X40000000, // 7
         #X3C666666, #X3C666666, #X3C000000, // 8
         #X3C666666, #X3E060666, #X3C000000, // 9
         #X00001818, #X00001818, #X00000000, // :
         #X00001818, #X00001818, #X08100000, // ;
         #X00060C18, #X30603018, #X0C060000, // <
         #X00000000, #X7C007C00, #X00000000, // =
         #X00603018, #X0C060C18, #X30600000, // >
         #X3C7E0606, #X0C181800, #X18180000, // ?
         #X7E819DA5, #XA5A59F80, #X7F000000, // @
         #X3C7EC3C3, #XFFFFC3C3, #XC3000000, // A
         #XFEFFC3FE, #XFEC3C3FF, #XFE000000, // B
         #X3E7FC3C0, #XC0C0C37F, #X3E000000, // C
         #XFCFEC3C3, #XC3C3C3FE, #XFC000000, // D
         #XFFFFC0FC, #XFCC0C0FF, #XFF000000, // E
         #XFFFFC0FC, #XFCC0C0C0, #XC0000000, // F
         #X3E7FE1C0, #XCFCFE3FF, #X7E000000, // G
         #XC3C3C3FF, #XFFC3C3C3, #XC3000000, // H
         #X18181818, #X18181818, #X18000000, // I
         #X7F7F0C0C, #X0C0CCCFC, #X78000000, // J
         #XC2C6CCD8, #XF0F8CCC6, #XC2000000, // K
         #XC0C0C0C0, #XC0C0C0FE, #XFE000000, // L
         #X81C3E7FF, #XDBC3C3C3, #XC3000000, // M
         #X83C3E3F3, #XDBCFC7C3, #XC1000000, // N
         #X7EFFC3C3, #XC3C3C3FF, #X7E000000, // O
         #XFEFFC3C3, #XFFFEC0C0, #XC0000000, // P
         #X7EFFC3C3, #XDBCFC7FE, #X7D000000, // Q
         #XFEFFC3C3, #XFFFECCC6, #XC3000000, // R
         #X7EC3C0C0, #X7E0303C3, #X7E000000, // S
         #XFFFF1818, #X18181818, #X18000000, // T
         #XC3C3C3C3, #XC3C3C37E, #X3C000000, // U
         #X81C3C366, #X663C3C18, #X18000000, // V
         #XC3C3C3C3, #XDBFFE7C3, #X81000000, // W
         #XC3C3663C, #X183C66C3, #XC3000000, // X
         #XC3C36666, #X3C3C1818, #X18000000, // Y
         #XFFFF060C, #X183060FF, #XFF000000, // Z
         #X78786060, #X60606060, #X78780000, // [
         #X60603030, #X18180C0C, #X06060000, // \
         #X1E1E0606, #X06060606, #X1E1E0000, // ]
         #X10284400, #X00000000, #X00000000, // ^
         #X00000000, #X00000000, #X00FFFF00, // _
         #X30180C00, #X00000000, #X00000000, // `
         #X00007AFE, #XC6C6C6FE, #X7B000000, // a
         #XC0C0DCFE, #XC6C6C6FE, #XDC000000, // b
         #X00007CFE, #XC6C0C6FE, #X7C000000, // c
         #X060676FE, #XC6C6C6FE, #X76000000, // d
         #X00007CFE, #XC6FCC0FE, #X7C000000, // e
         #X000078FC, #XC0F0F0C0, #XC0000000, // f
         #X000076FE, #XC6C6C6FE, #X7606FE7C, // g
         #XC0C0DCFE, #XC6C6C6C6, #XC6000000, // h
         #X18180018, #X18181818, #X18000000, // i
         #X0C0C000C, #X0C0C0C7C, #X38000000, // j
         #X00C0C6CC, #XD8F0F8CC, #XC6000000, // k
         #X00606060, #X6060607C, #X38000000, // l
         #X00006CFE, #XD6D6D6D6, #XD6000000, // m
         #X0000DCFE, #XC6C6C6C6, #XC6000000, // n
         #X00007CFE, #XC6C6C6FE, #X7C000000, // o
         #X00007CFE, #XC6FEFCC0, #XC0000000, // p
         #X00007CFE, #XC6FE7E06, #X06000000, // q
         #X0000DCFE, #XC6C0C0C0, #XC0000000, // r
         #X00007CFE, #XC07C06FE, #X7C000000, // s
         #X0060F8F8, #X6060607C, #X38000000, // t
         #X0000C6C6, #XC6C6C6FE, #X7C000000, // u
         #X0000C6C6, #X6C6C6C38, #X10000000, // v
         #X0000D6D6, #XD6D6D6FE, #X6C000000, // w
         #X0000C6C6, #X6C386CC6, #XC6000000, // x
         #X0000C6C6, #XC6C6C67E, #X7606FE7C, // y
         #X00007EFE, #X0C3860FE, #XFC000000, // z
         #X0C181808, #X18301808, #X18180C00, // {
         #X18181818, #X18181818, #X18181800, // |
         #X30181810, #X180C1810, #X18183000, // }
         #X00000070, #XD1998B0E, #X00000000, // ~
         #XAA55AA55, #XAA55AA55, #XAA55AA55  // rubout

  IF i>=0 DO charbase := charbase + 3*i

  // charbase points to the three words giving the
  // pixels of the character.
  { LET col = colour
    LET w = VALOF SWITCHON line INTO
    { CASE  0: RESULTIS charbase!0>>24
      CASE  1: RESULTIS charbase!0>>16
      CASE  2: RESULTIS charbase!0>> 8
      CASE  3: RESULTIS charbase!0
      CASE  4: RESULTIS charbase!1>>24
      CASE  5: RESULTIS charbase!1>>16
      CASE  6: RESULTIS charbase!1>> 8
      CASE  7: RESULTIS charbase!1
      CASE  8: RESULTIS charbase!2>>24
      CASE  9: RESULTIS charbase!2>>16
      CASE 10: RESULTIS charbase!2>> 8
      CASE 11: RESULTIS charbase!2
    }

    IF ((w >> 7) & 1) = 1 DO drawpoint(x,   y)
    IF ((w >> 6) & 1) = 1 DO drawpoint(x+1, y)
    IF ((w >> 5) & 1) = 1 DO drawpoint(x+2, y)
    IF ((w >> 4) & 1) = 1 DO drawpoint(x+3, y)
    IF ((w >> 3) & 1) = 1 DO drawpoint(x+4, y)
    IF ((w >> 2) & 1) = 1 DO drawpoint(x+5, y)
    IF ((w >> 1) & 1) = 1 DO drawpoint(x+6, y)
    IF (w & 1)        = 1 DO drawpoint(x+7, y)

//writef("writeslice: ch=%c line=%i2 w=%b8 bits=%x8 %x8 %x8*n",
//        ch, line, w, charbase!0, charbase!1, charbase!2)

  }

  currx, curry := cx, cy
}

AND drawstring(x, y, s) BE
{ moveto(x, y)
  FOR i = 1 TO s%0 DO drawch(s%i)
}

AND plotf(x, y, form, a, b, c, d, e, f, g, h) BE
{ LET oldwrch = wrch
  LET s = VEC 256/bytesperword
  plotfstr := s
  plotfstr%0 := 0
  wrch := plotwrch
  writef(form, a, b, c, d, e, f, g, h)
  wrch := oldwrch
  drawstring(x, y, plotfstr)
}

AND plotwrch(ch) BE
{ LET strlen = plotfstr%0 + 1
  plotfstr%strlen := ch
  plotfstr%0 := strlen 
}
*/

