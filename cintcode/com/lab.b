SECTION "LAB"

GET "libhdr"

LET start() = VALOF
{ LET argv = VEC 50

  UNLESS rdargs("LABEL/A", argv, 50) DO
  { writef("LAB expects an argument*n")
    RESULTIS 20
  }
  RESULTIS 0
}

