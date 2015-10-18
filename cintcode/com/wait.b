// (C) Copyright 1978 Tripos Research Group
//     University of Cambridge
//     Computer Laboratory

SECTION "WAIT"

GET "libhdr"

MANIFEST {
  msecspermin = 60000
  msecsperhour = msecspermin*60
  msecsperday = msecsperhour*24
}

LET start() = VALOF
{ LET argv = VEC 50
  LET days, msecs = 0, 0
  LET daysnow, msecsnow = 0, 0
  LET n = 0

  // Get the date and time now
  datstamp(@daysnow)

  UNLESS rdargs("N/N,SEC=SECS/S,MIN=MINS/S,UNTIL/K", argv, 50) DO
  { error(1)
    RESULTIS 20
  }

  UNLESS argv!3 DO                   // UNTIL/K
  { n := 1
    IF argv!0 DO n := !(argv!0)      // N/N

    TEST argv!2                      // MINS/S
    THEN msecs := n * 60000
    ELSE msecs := n * 1000
    msecs := msecs + msecsnow
    days := daysnow
    IF msecs > msecsperday DO days, msecs := days+1, msecs-msecsperday
  }
  IF argv!3 DO                       // UNTIL/K
  { LET s = argv!3
    LET hour = 0
    LET min = 0
    UNLESS s%0=5 DO { error(3); RESULTIS 20 }
    FOR i=1 TO 5 UNLESS i=3 -> s%i=':', '0'<=s%i<='9' DO
    { error(3)
      RESULTIS 20
    }
    hour := (s%1-'0')*10+s%2-'0'
    IF hour>=24 DO error(3)
    min := (s%4-'0')*10+s%5-'0'
    IF min>=60 DO
    { error(3)
      RESULTIS 20
    }
    msecs := hour*msecsperhour + min*60000
    days := daysnow
    IF msecs<msecsnow DO days := days+1
  }

  { LET str = VEC 14
    dat_to_strings(@days, str)
    //sawritef("Delaying until %s %s*n", str, str+5)
  }


  //sawritef("Delaying until %n days %n msecs*n", days, msecs)

  { LET ds, ms = ?, ?
    datstamp(@ds)
  //sawritef("Delaying until %n days %n msecs*n", days, msecs)
  //sawritef("Time now       %n days %n msecs*n", ds, ms)
    IF (ds>days) |
       (ds=days & ms>=msecs) BREAK
    sys(Sys_delay, 500) // Sleep for 1/2 second
    //IF testflags(flag_b) DO
    //{ writes("****BREAK*N")
    //  RESULTIS 10
    //}
  } REPEAT

  RESULTIS 0
}


AND error(n) BE
{ writes(n=1 -> "Bad args*N",
         n=2 -> "Error in number*N",
                "Time should be HH:MM*N")
}
