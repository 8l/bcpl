/*
############### UNDER DEVELOPMENT #####################

This library provides the BCPL interface to the EXT user extensions.

Implemented by Martin Richards (c) April 2014

Change history:

14/04/14
Initial implementation.

It should typically be included as a separate section for programs that
need it. Such programs typically have the following structure.

GET "libhdr"
MANIFEST { g_extbase=nnn  } // Only used if the default setting of 950 in
                            // libhdr is not suitable.
GET "ext.h"
GET "ext.b"                  // Insert the library source code
.
GET "libhdr"
MANIFEST { g_extbase=nnn  } // Only used if the default setting of 950 in
                            // libhdr is not suitable.
GET "ext.h"
*/

LET extInit() = VALOF
{ 
  UNLESS sys(Sys_ext, EXT_Init) DO
  { writef("*nextInit unable to initialise the EXT extension library*n")
    RESULTIS FALSE
  }

  // Successful
  RESULTIS TRUE
}

AND extTestfn(a, b, c) = sys(Sys_ext, EXT_Testfn, a, b, c)


