// (C) Copyright 1978 Tripos Research Group
//     University of Cambridge
//     Computer Laboratory

// Modified 27/1/2011

SECTION "TIME"

GET "libhdr"

LET start() = VALOF
{ LET tostream, precise = 0, FALSE
  LET days, msecs = 0, 0
  LET argv = VEC 50
  LET v = VEC 14

  UNLESS rdargs("TO/K,MSECS/S", argv, 50) DO
  { writef("Bad arguments for TIME*n")
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

  precise := argv!1                // MSECS/S

  datstamp(@days)
  dat_to_strings(@days, v)
  writef(" %s", v+5)
  IF precise DO writef(".%3z", msecs MOD 1000)
  newline()
  IF tostream DO endstream(tostream)
  RESULTIS 0
}

