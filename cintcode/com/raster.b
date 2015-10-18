// (c) M. Richards  Copyright 20 Jun 2006

// Typical usage when run under rastsys:

// > raster count 1000 scale 12 to rastdata
// > bcpl com/bcpl.b to junk
// ...
// > raster
// > rast2ps

/* This will generate a relatively compact file using run length encoding
**
** K1000 S12          1000 instruction per raster line, 12 bytes per pixel
** W10B3W1345B1N      10 white 3 black 1345 white 1 black newline
** W13B3W12B2N        etc
** ...
*/


SECTION "RASTER"

GET "libhdr"

LET start() = VALOF
{ LET argv = VEC 40
  AND outstream = 0
  AND tallyv = rootnode!rtn_tallyv
  AND oldout = output()
  AND count, scale = 1000, 12

  IF tallyv=0 DO
  { writes("Rastering not available*n")
    RESULTIS 20
  }
   
  IF rdargs("COUNT,SCALE,TO/K,HELP/S",argv, 40)=0 DO
  { writes("Bad arguments for RASTER*n")
    RESULTIS 20
  }

  IF argv!3 DO
  { writes("*nTypical usage:*n*n")
    writes("    raster count 1000 scale 12 to rastdata*n")
    writes("    bcpl com/bcpl.b to junk*n")
    writes("    ...*n")
    writes("    raster*n")
    writes("    rast2ps*n")
    writes("*n    Remember to use rastsys (NOT cintsys)*n")
    RESULTIS 0
  }

  UNLESS sys(Sys_setraster, 3)=0 DO
  { writes("Rastering is not available*n")
    RESULTIS 20
  }

  UNLESS argv!0 | argv!1 | argv!2 DO
  { LET res = sys(Sys_setraster, 0, 0) // Attempt to close raster file
    TEST res=0 THEN writes("Raster file closed*n")
               ELSE writes("Unable to close raster file*n")
    RESULTIS 0
  }
   
  IF argv!0 DO count := str2numb(argv!0)
  IF argv!1 DO scale := str2numb(argv!1)

  writef("*nRastering to file %s with count = %n and scale = %n*n",
          argv!2, count, scale)
  sys(Sys_setraster, 1, count)
  sys(Sys_setraster, 2, scale)
   
  IF sys(Sys_setraster, 0, argv!2) DO // Attempt to open raster file
  { writes("Trouble opening raster file: %s*n", argv!2)
    RESULTIS 20
  }

  cli_tallyflag := TRUE  // Tell the CLI to start rastering
  RESULTIS 0
}
