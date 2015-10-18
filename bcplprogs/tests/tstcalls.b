GET "libhdr"

GLOBAL {
 g11:11
 g300:300
 g400:400
 g600:600
 argv:ug
}

LET start() = VALOF
{ LET a,b,c,d = g400,0,0,0
  argv := TABLE 0,0,0,0,0, 0,0,0,0,0,
                0,0,0,0,0, 0,0,0,0,0, 0
  UNLESS rdargs("K7/S,K7G/S,K7G1/S,K7GH/S,K/S,KH/S,KW/S,G1/S,G2/S,G3/S",
                 argv, 20) DO
  { writef("Bad arguments for tstcalls*n")
    RESULTIS 0
  }

  writef("Testing Cintcode calling instructions*n")

  IF argv!0 DO a()     // K7
  IF argv!1 DO g11()   // K7G
  IF argv!2 DO g300()  // K7G1
  IF argv!3 DO g600()  // K7GH

  IF argv!4 DO
  { LET v = VEC 100
    g11()   // K 109
  }

  IF argv!5 DO
  { LET v = VEC 5000
    g300()   // KH 5009
  }

  IF argv!6 DO
  { LET v = VEC 70000
    g600()   // KW 70009
  }

  IF argv!7 GOTO 0
  IF argv!8 GOTO -1
  IF argv!9 GOTO -1000000000

  RESULTIS 0
}
