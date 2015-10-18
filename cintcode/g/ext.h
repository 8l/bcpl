/*
######## UNDER DEVELOPMENT ################

This is the header file for the EXT extenions interface. This interface
allows users to specify any extentions to the library they like. It follows
the same structure as the SDL and GL extensions but the user has complete
control of the content. The extensions are invoked by calls such as

sys(Sys_ext, EXT_Avail, ...)

and they are implemented in C by the file sysc/extfn.c. Only a dummy
version of extfn.c is provided in this distribution.

History:
14/04/14
Initial implementation

g_extbase is set in libhdr to be the first global used in the ext library
It can be overridden by re-defining g_extbase after GETting libhdr.

A program wishing to use the EXT library should contain the following lines.

GET "libhdr"
MANIFEST { g_extbase=nnn  } // Only used if the default setting of 950 in
                            // libhdr is not suitable.
GET "ext.h"
GET "ext.b"                 // Insert the library source code
.
GET "libhdr"
MANIFEST { g_extbase=nnn  } // Only used if the default setting of 950 in
                            // libhdr is not suitable.
GET "ext.h"
Rest of the program
*/

GLOBAL {
  extInit:g_extbase
  extTestfn
}

MANIFEST {
// ops used in calls of the form: sys(Sys_ext, op,...)
// These should work when using a properly configured BCPL Cintcode system
// running under Linux, Windows or or OSX provided the OpenGL libraries
// have been installed.
// All manifests start with a capital letter.

EXT_Avail=0          // Returns TRUE if the EXT features are available
EXT_Init=1           // Initialise EXT
EXT_Testfn=2         // A test function
}
