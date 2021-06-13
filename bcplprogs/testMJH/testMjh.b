/*
This program finds the set of numbers that can be computed from a
given set of up to 6 numbers using only the operations plus, minus,
times and divide. Each number can only be used once and all numbers
and intermediate results must be integral and in the range 0 to 999.

Written in BCPL by Mike Hewitt (c) June 2021
*/

GET "libhdr"

GLOBAL   { v:200; resv; opstr; vala; valb; change; outstream }

MANIFEST { Upb=999 }

LET start() = VALOF
{ LET argv = VEC 50
  LET len = VEC 2
  LET oldout = output()
    writef("*nThis is %s triangle*n"
            )
}

