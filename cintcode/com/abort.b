SECTION "ABORT"

GET "libhdr"

LET start() = VALOF 
{ LET argv = VEC 10
  AND n = 99
   
  UNLESS rdargs("NUMBER", argv, 10) DO
  { writef("Bad argument for ABORT*n")
    RESULTIS 20
  }
   
  IF argv!0 & string_to_number(argv!0) DO n := result2
   
  abort(n)
  RESULTIS 0
}
