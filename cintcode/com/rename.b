// (C) Copyright 1978 Tripos Research Group
//     University of Cambridge
//     Computer Laboratory

SECTION "RENAME"

GET "libhdr"

LET start() = VALOF
{ LET argv = VEC 50

  UNLESS rdargs("FROM/A,TO=AS/A/K", argv, 50) DO
  { writes("Bad args*n")
    RESULTIS 20
  }

  UNLESS renamefile(argv!0, argv!1) DO
  { LET res2 = result2
    writef("Can't rename %s as %s*n", argv!0, argv!1)
    result2 := res2
    RESULTIS 20
  }
  RESULTIS 0
}
