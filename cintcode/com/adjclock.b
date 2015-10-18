/*  adjclock [[+/-]hh[:mm]]

With no arguments it outputs the current clock adjustment, otherwise
it sets the clock adjustment value (which is held in the rootnode).

Implemented by Martin Richards (c) May 2004
*/



SECTION "ADJCLOCK"

GET "libhdr"

GLOBAL { str:ug; strp; len; ch }

LET start() = VALOF
{ LET argv = VEC 10
  LET adjustment = rootnode!rtn_adjclock

  UNLESS rdargs("OFFSET", argv, 10) DO
  { writef("Bad argument for ADJCLOCK*n")
    RESULTIS 20
  }

  IF argv!0 & str2mins(argv!0) DO adjustment := result2

  rootnode!rtn_adjclock := adjustment

  writef("Clock adjustment is now: ")
  IF adjustment<0 DO
  { wrch('-')
    adjustment := -adjustment
  }
  writef("%n:%z2*n", adjustment / 60, adjustment REM 60)
  RESULTIS 0
}

AND str2mins(s) = VALOF
{ LET neg, hours, mins = FALSE, 0, 0

  str, strp, len := s, 1, s%0

  rch()
  IF ch='-' | ch='+' DO
  { IF ch='-' DO neg := TRUE
    rch()
  }
  WHILE '0'<=ch<='9' DO
  { hours := 10*hours + ch-'0'
    rch()
  }
  IF ch=':' DO
  { rch()
    WHILE '0'<=ch<='9' DO
    { mins := 10*mins + ch-'0'
      rch()
    }
  }
  UNLESS ch=endstreamch RESULTIS FALSE

  mins := 60*hours + mins
  result2 := neg -> -mins, mins
  RESULTIS TRUE
}

AND rch() BE TEST strp<=len THEN { ch := str%strp; strp := strp+1 }
                            ELSE   ch := endstreamch
