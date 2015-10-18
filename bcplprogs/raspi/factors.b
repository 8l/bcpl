GET "libhdr"

LET start() = VALOF
{ LET n = readn()
  LET factor = 2

  IF n<=0 RESULTIS 0

  WHILE n>1 DO
  { IF n MOD factor = 0 DO
    { writef("%n*n", factor)
      n := n / factor
      LOOP
    }
    factor := factor + 1 
  }
} REPEAT
