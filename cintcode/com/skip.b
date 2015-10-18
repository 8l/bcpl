SECTION "SKIP"

GET "libhdr"

GLOBAL { ch: ug }

LET start() = VALOF
{ LET arg= VEC 50
  LET label= ""
  LET found = FALSE
  LET s = VEC 127

  UNLESS rdargs("LABEL",arg,50) DO
  { writes("Bad argument spec for Skip*n")
    RESULTIS return_hard
  }

  IF cli_currentinput = cli_standardinput DO
  { writes("Skip must be in a command file*n")
    RESULTIS return_hard
  }

  IF arg!0 DO label := arg!0

  ch:='*n'
  UNTIL found | ch=endstreamch DO
  { ch := rdch() REPEATWHILE ch=' ' | ch='*c'
    rdstr(s)
    IF compstring(s, "lab")=0 THEN
    { WHILE ch=' ' DO ch:=rdch()
      rdstr(s)
      found := compstring(s, label)=0
    }
    UNTIL ch='*n' | ch=endstreamch DO ch:=rdch()
  }

  UNLESS found DO
  { writef("Label *"%s*" not found by Skip*n", label)
    RESULTIS return_hard
  }
}



AND rdstr(s) BE
{ LET i=0
  UNTIL ch='*N' | ch=endstreamch | ch=' ' DO
  { UNLESS ch='*c' DO
    { i := i+1
      s%i:=ch
    }
    ch:=rdch()
  }
  s%0 := i
}

