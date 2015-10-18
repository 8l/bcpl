GET "libhdr"

LET start() = VALOF
{ LET n = 7
  LET count = 0

  { count := count+1
    IF n=1 RESULTIS count
    TEST n MOD 2 = 0
    THEN n := n/2
    ELSE n := 3*n+1
  } REPEAT
}
