GET "libhdr"

LET start() = VALOF
{ LET argv = VEC 50
  LET len = VEC 2

  IF rdargs("A/A,B/A,C/A", argv, 50) = 0
  { writes("Bad arguments: triangle need three numbers*n")
    RESULTIS 20
  }
  FOR i = 0 TO 2 DO len!i := str2numb(argv!i)
  writes("*nTriangle given: ")
  FOR i = 0 TO 2 DO writef("%n ", len!i)
  writef("*nThis is %s triangle*n",
            sort_of_triangle(len!0, len!1, len!2))
  RESULTIS 0
}

AND sort_of_triangle(a, b, c) =
    b<a         -> sort_of_triangle(b, a, c),
    c<b         -> sort_of_triangle(a, c, b),
    // At this point we know that a <= b <= c
    c>a+b       -> "not a",
    a=c         -> "an equilateral",
    a=b | b=c   -> "an isoscelese",
    c*c=a*a+b*b -> "a right angled",
                   "a scalene"
