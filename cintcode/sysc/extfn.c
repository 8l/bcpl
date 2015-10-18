/*
This contains the implemetation of the sys(Sys_ext, fno, ...) facility.

###### Still under development ############

Implemented by Martin Richards (c) April 2014

This file can be modified by users to provide any extension to the
BCPL library that the user would like.

BCPL calls to this library are of the form

res := sys(Sys_ext, fno, a1, a2, a3, a4,...)

This calls extfn(args, g)
where args[0] = fno, args[1]=a1,... etc
and   g points to the base of the global vector.

fno=0  Test that a version of the EXT extension is available
       res is TRUE if it is.

fno=1 ...

The function numbers such as EXT_avail, EXT_init and EXT_testfn are declared
as mainfests in g/ext.h
*/

#include "cintsys.h"
#include <stdio.h>
#include <stdlib.h>


#ifndef EXTavail
BCPLWORD extfn(BCPLWORD *args, BCPLWORD *g, BCPLWORD *W) {
  printf("extfn: EXTavail was not defined\n");
    return 0;   // EXT is not available
}
#endif

#ifdef EXTavail
// These must agree with the declarations in g/ext.h
#define EXT_Avail               0
#define EXT_Init                1
#define EXT_Testfn              2

BCPLWORD extfn(BCPLWORD *a, BCPLWORD *g, BCPLWORD *W) {
  //char tmpstr[256];
  //int argc = 0;

  //printf("extfn: EXTavail was defined\n");

  //printf("extfn: fno=%d a1=%d a2=%d a3=%d a4=%d\n",
  //        a[0], a[1], a[2], a[3], a[4]);

  switch(a[0]) {
    default:
      printf("extfn: Unknown op: fno=%d a1=%d a2=%d a3=%d a4=%d\n",
              a[0], a[1], a[2], a[3], a[4]);
      return 0;

    case EXT_Avail: // Return TRUE since the EXT features are available.
        return -1;

    case EXT_Init:  // Initialise all EXT features
      { return -1;
      }

    case EXT_Testfn:  // Set result2 and return a result.
        printf("extfn: fno=%d a1=%d a2=%d a3=%d\n",
              a[0], a[1], a[2], a[3]);
        g[Gn_result2] = a[1]*a[2] - a[3];
        return a[1]*a[2] + a[3];
  }
}
#endif
