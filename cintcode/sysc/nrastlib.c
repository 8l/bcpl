/* cinterp.h contains machine/system dependent #defines  */

#include "cintsys.h"

BCPLWORD setraster(BCPLWORD n, BCPLWORD val)
{ 
  return -1;   /* To indicate rastering not available */
}

void rasterpoint(BCPLWORD p)
{ 
  return;
}


