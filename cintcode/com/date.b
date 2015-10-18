// (C) Copyright 1979 Tripos Research Group
//     University of Cambridge
//     Computer Laboratory

// Modified 27/1/2011

SECTION "DATE"

GET "libhdr"

LET start() = VALOF
{ LET tostream = 0
  LET days, msecs = 0, 0
  LET argv = VEC 50
  LET v = VEC 14

  UNLESS rdargs("TO/K", argv, 50) DO
  { writef("Bad arguments for DATE*n")
    RESULTIS 20
  }

  IF argv!0 DO                        // TO/K
  { tostream := findoutput(argv!0)
    UNLESS tostream DO
    { writef("******Can*'t open %s*n", argv!0)
      RESULTIS 20
    }
    selectoutput(tostream)
  }

  datstamp(@days)
  dat_to_strings(@days, v)
  writef(" %s %s*n", v+10, v)
  IF tostream DO endstream(tostream)
  RESULTIS 0
}
