GET "libhdr"

LET start() = VALOF
{ LET k = sys(Sys_settrcount, 0)
  LET p = 0

  writef("initial trcount=%n*n", k)

  FOR i = 0 TO 4100 DO sys(Sys_trpush, #xDD000000+i)

  // Stop trpushing
  k := sys(Sys_settrcount, -1)
  writef("Number of trpush values = %n*n", k)
  p := k - 4096
  IF p<0 DO p := 0
  FOR i = p TO k-1 DO
  { LET val = sys(Sys_gettrval, i)
    LET flag = val>>24
    val := val & #xFFFFFF
    IF (i-p) MOD 8 = 0 DO writef("*n%i4:", i-p)
    TEST flag=#x66
    THEN writef("  %6.3d:", val) // Time item inserted by trpush
    ELSE writef("%6i/%x2", val, flag) 
  }
  newline()
  
  RESULTIS 0
}
