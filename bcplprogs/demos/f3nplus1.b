/*
   A problem suggested by B.Thwaites in 1952.

   Investigate the integer function f(n)

   where    f(n) = n/2    if n even
   else     f(n) = 3*n+1

   Implemented in BCPL by Martin Richards (c) September 2000
*/

GET "libhdr"

LET f(n) = (n&1)=0 -> n/2, 3*n+1

LET start() = VALOF
{ LET argv = VEC 50
  LET n = 0

  UNLESS rdargs("n", argv, 50) DO
  { writes("Bad argument*n")
    RESULTIS 20
  }

  IF argv!0 DO n := str2numb(argv!0)

  IF n DO
  { try(n)
    RESULTIS 0
  }

  { writef("n = ")
    n := readn()
    newline()
    IF n=0 RESULTIS 0
    try(n)
  } REPEAT
}

AND try(n) BE
{ LET layout = 0

  { writef(" %i6", n)
    layout := layout+1
    IF layout REM 10 = 0 DO newline()
    IF n=1 BREAK
    n := f(n)
  } REPEAT

  newline()
}
