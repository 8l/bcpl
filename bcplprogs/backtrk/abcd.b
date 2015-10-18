/*
   Find a long string of letters A, B, C and D for which no
   adjacent substrings are permutations of each other. Run for
   about one second.

   (c) Martin Richards 1980
*/

GET "libhdr"

GLOBAL { base:200; time0:201 }

LET try(p, k) BE
{ !p := k
  UNLESS ok(p, p, p) RETURN
  IF sys(30)-time0>1000 DO // Has it run for one second?
  { writef("Execution time is %n msecs*n", sys(30)-time0)
    out(base, p)
    newline()
    stop(0)
  }
  p := p+1
  try(p, k+'A')
  try(p, k+'B'+#x100)
  try(p, k+'C'+#x10000)
  try(p, k+'D'+#x1000000)
}

AND ok(p, q, r) = VALOF
{ q, r := q-1, r-2
  IF r < base RESULTIS TRUE
  IF !p+!r = 2*!q RESULTIS FALSE
} REPEAT

AND out(b, p) BE UNTIL b=p DO
{ IF (b-base) REM 50 = 0 DO newline()
  wrch(b!1 - b!0)
  b := b+1
}

AND start() = VALOF
{ LET v = VEC 5000
  base := v
  time0 := sys(30)
  try(base, 0)
}