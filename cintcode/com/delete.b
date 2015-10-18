// (C) Copyright 1979 Tripos Research Group
//     University of Cambridge
//     Computer Laboratory

SECTION "DELETE"

GET "libhdr"

LET start() = VALOF
{ LET argv = VEC 80

  TEST rdargs(",,,,,,,,,,-f/S", argv, 80)=0
  THEN { writes("Bad args*N")
         RESULTIS 20
       }
  ELSE FOR i = 0 TO 9 DO
       { IF argv!i=0 BREAK
         IF deletefile(argv!i)=0 UNLESS argv!10 DO
         { writef("Can't delete %s*n", argv!i)
           RESULTIS 5
         }
       }
  RESULTIS 0
}
