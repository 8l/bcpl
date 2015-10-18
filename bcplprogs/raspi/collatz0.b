GET "libhdr"

LET start() = VALOF
{ LET n = 173_519_878  //123456789
  LET count = 0

  { count := count+1
    writef("%5i: %10i*n", count, n)
    IF n=1 BREAK
    TEST n MOD 2 = 0
    THEN n := n/2
    ELSE n := 3*n+1
  } REPEAT

  RESULTIS 0
}
