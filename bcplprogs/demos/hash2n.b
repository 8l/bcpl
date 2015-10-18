// This program tries out hash functions for powers of 2

GET "libhdr"

LET start() = VALOF
{ LET used = VEC 100

  FOR d = 2 TO 67 DO
  { LET r = 1
    FOR i = 0 TO 100 DO used!i := FALSE

    writef("*n*n2****n mod %n   for n in 0..%n*n*n",
                   d,                d-1)
    FOR i = 1 TO d DO
    { writef("%i2%c ", r, used!r->'#', ' ')
      IF i REM 16 = 0 DO newline()
      used!r := TRUE
      r := (2*r) REM d
    }
  }

  writef("*n*nEnd of test*n")
  RESULTIS 0
}