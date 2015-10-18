GET "libhdr"

LET start() = VALOF
{ LET v = VEC 5
  LET days = 0
  LET hours = 0
  LET mins = 0
  LET secs = 0
  LET msecs = 0
 
  MANIFEST { secspermin=60; secsperhour=60*60; secsperday = 60*60*24 }

  sys(Sys_datstamp, v)
  // v!0 = days since 1 Jan 1970
  // v!1 = msecs since midnight
  // v!2 = ticks or -1
  //FOR i = 0 TO 2 DO writef(" %i9", v!i)
  //newline()

  days := v!0
  msecs := v!1
  // Assume new dat format
  secs := msecs/1000
  mins := secs/60
  hours := mins/60
  mins := mins MOD 60
  secs := secs MOD 60
  msecs := msecs MOD 1000

  writef("days=%n hours=%n mins=%n secs=%n msecs=%n*n",
          days, hours, mins, secs, msecs)


  RESULTIS 0
}

