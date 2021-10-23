GET "libhdr"

LET start() = VALOF
{ LET argv = VEC 50
  LET len = VEC 2

  IF rdargs("A/A,B/A,C/A", argv, 50) = 0
  { writes("Bad arguments: triangles need three numbers*n")
    RESULTIS 20
  }
  FOR i = 0 TO 2 DO len!i := str2numb(argv!i)
  writes("*nTriangle given: ")
  FOR i = 0 TO 2 DO writef("*n%n ", len!i)
  writef("*n   ")
    writef("*nThis is %s triangle*n",
            sort_of_triangle(len!0, len!1, len!2))
}

AND sort_of_triangle(a, b, c) =  "test"
