GET "libhdr"

LET start() = VALOF
{ LET n = 123_456_789
  LET count = 0
  LET lim = (maxint-1)/3

  { count := count+1
    writef("%5i: %10i*n", count, n)
    IF n=1 BREAK
    TEST n MOD 2 = 0
    THEN { n :=n/2
         }
    ELSE { IF n > lim DO
           { writef("Number too big*n")
             BREAK
           }
           n := 3*n+1
         }
  } REPEAT

  RESULTIS 0
}
