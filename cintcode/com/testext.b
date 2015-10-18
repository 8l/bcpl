/*
This tests the EXT user extension library

Implemented by Martin Richards (c) April 2014

See g/ext.h, g/ext.b, sysc/extfn.c for details.
*/

GET "libhdr"
//MANIFEST { g_extbase=nnn  } // Only used if the default setting of 950 in
                            // libhdr is not suitable.
GET "ext.h"
GET "ext.b"                 // Insert the library source code
.
GET "libhdr"
//MANIFEST { g_extbase=nnn  } // Only used if the default setting of 950 in
                            // libhdr is not suitable.
GET "ext.h"

LET start() = VALOF
{ LET a, b, c = 2, 3, 1
  LET res, res2 = 0, 0

  UNLESS sys(Sys_ext, EXT_Avail) DO
  { writef("The EXT extension library is not available*n")
    RESULTIS 0
  }
  
  UNLESS extInit() DO
  { writef("Cannot initialise the EXT extension library*n")
    RESULTIS 0
  }

  res := extTestfn(a, b, c)
  res2 := result2


  writef("*nThis should set*n*n")
  writef("res  = a**b + c*n")
  writef("res2 = a**b - c*n*n")

  writef("a=%n b=%n c=%n => res = %n*n", a,b,c, res)
  writef("a=%n b=%n c=%n => res2= %n*n", a,b,c, res2)
  
//abort(1000)
  RESULTIS 0
}
