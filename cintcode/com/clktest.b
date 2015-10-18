GET "libhdr"

LET start() = VALOF
{ LET k = sys(Sys_settrcount, 0)
  LET p = 0
  LET count = 0
  LET msecs = rootnode!rtn_msecs

  writef("initial trcount=%n*n", k)

  // Busy loop for a while
  FOR i = 0 TO 1000 DO
  { WHILE msecs = rootnode!rtn_msecs DO count := count+1
    sys(Sys_trpush, #xFF000000 + count)
    msecs := rootnode!rtn_msecs
    count := 0
  }


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
