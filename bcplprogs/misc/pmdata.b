GET "libhdr"

MANIFEST {
M=0; F=1

MNC = 1
MC  = 2
SD  = 3
S   = 4
W   = 5
SP  = 6
}

GLOBAL {
Mcount : 200
Fcount : 201
statv  : 202
Msessions : 203
Fsessions : 204


Mmnc  : 210
Mmc   : 211
Msd   : 212
Ms    : 213
Mw    : 214
Msp   : 215

Magev : 216
Msesv : 217

Fmnc  : 220
Fmc   : 221
Fsd   : 222
Fs    : 223
Fw    : 224
Fsp   : 225

Fagev : 226
Fsesv : 227
}

LET start() = VALOF
{ LET u  = VEC 10
  LET v1 = VEC 10
  AND v2 = VEC 10
  LET w1 = VEC 10
  AND w2 = VEC 10

  statv := u
  Magev, Fagev := v1, v2
  Msesv, Fsesv := w1, w2

  FOR i = 0 TO 10 DO statv!i := 0 
  FOR i = 0 TO 10 DO Magev!i, Fagev!i, Msesv!i, Fsesv!i := 0, 0, 0, 0

Mcount := 0
Fcount := 0
Msessions := 0
Fsessions := 0

Mmnc  := 0
Mmc   := 0
Msd   := 0
Ms    := 0
Mw    := 0
Msp   := 0

Fmnc  := 0
Fmc   := 0
Fsd   := 0
Fs    := 0
Fw    := 0
Fsp   := 0

  writef("rdata entered*n")

  d(  1, M,  64,   2,    S)
  d(  2, F,  25,   3,    0)
  d(  3, F,  26,   7,    S)
  d(  4, M,  57,   2,  MNC)
  d(  5, F,  27,  12,   SP)
  d(  6, F,  69,   6,    S)
  d(  7, M,  67,   7,  MNC)
  d(  8, F,  37,   5,    0)
  d(  9, F,  26,   4,   MC)
  d( 10, F,  82,   1,  MNC)
  d( 11, M,  76,   1,  MNC)
  d( 12, F,  39,   0,  MNC)
  d( 13, M,  64,   0,    0)
  d( 14, F,  46,   0,  MNC)
  d( 15, F,  32,   0,    0)


  pr()
  RESULTIS 0
}

AND d(ser, s, a, sess, ms) BE
{ statv!ms := statv!ms + 1

  TEST s=M
  THEN { Mcount := Mcount + 1

         IF  0<=a<20    DO Magev!0 := Magev!0 + 1
         IF 20<=a<30    DO Magev!1 := Magev!1 + 1
         IF 30<=a<40    DO Magev!2 := Magev!2 + 1
         IF 40<=a<50    DO Magev!3 := Magev!3 + 1
         IF 50<=a<60    DO Magev!4 := Magev!4 + 1
         IF 60<=a<70    DO Magev!5 := Magev!5 + 1
         IF 70<=a<80    DO Magev!6 := Magev!6 + 1
         IF 80<=a       DO Magev!7 := Magev!7 + 1

         Msessions := Msessions + sess

         IF sess=0  DO Msesv!0 := Msesv!0 + 1
         IF sess=1  DO Msesv!1 := Msesv!1 + 1
         IF sess=2  DO Msesv!2 := Msesv!2 + 1
         IF sess=3  DO Msesv!3 := Msesv!3 + 1
         IF sess=4  DO Msesv!4 := Msesv!4 + 1
         IF sess=5  DO Msesv!5 := Msesv!5 + 1
         IF sess=6  DO Msesv!6 := Msesv!6 + 1
         IF sess=7  DO Msesv!7 := Msesv!7 + 1
         IF sess=8  DO Msesv!7 := Msesv!7 + 1
         IF sess=9  DO Msesv!7 := Msesv!7 + 1
         IF sess=10 DO Msesv!8 := Msesv!8 + 1
         IF sess=11 DO Msesv!8 := Msesv!8 + 1
         IF sess=12 DO Msesv!8 := Msesv!8 + 1
         IF sess>12 DO Msesv!9 := Msesv!9 + 1
       }
  ELSE { Fcount := Fcount + 1

         IF  0<=a<20    DO Fagev!0 := Fagev!0 + 1
         IF 20<=a<30    DO Fagev!1 := Fagev!1 + 1
         IF 30<=a<40    DO Fagev!2 := Fagev!2 + 1
         IF 40<=a<50    DO Fagev!3 := Fagev!3 + 1
         IF 50<=a<60    DO Fagev!4 := Fagev!4 + 1
         IF 60<=a<70    DO Fagev!5 := Fagev!5 + 1
         IF 70<=a<80    DO Fagev!6 := Fagev!6 + 1
         IF 80<=a       DO Fagev!7 := Fagev!7 + 1

         Fsessions := Fsessions + sess

         IF sess=0  DO Fsesv!0 := Fsesv!0 + 1
         IF sess=1  DO Fsesv!1 := Fsesv!1 + 1
         IF sess=2  DO Fsesv!2 := Fsesv!2 + 1
         IF sess=3  DO Fsesv!3 := Fsesv!3 + 1
         IF sess=4  DO Fsesv!4 := Fsesv!4 + 1
         IF sess=5  DO Fsesv!5 := Fsesv!5 + 1
         IF sess=6  DO Fsesv!6 := Fsesv!6 + 1
         IF sess=7  DO Fsesv!7 := Fsesv!7 + 1
         IF sess=8  DO Fsesv!7 := Fsesv!7 + 1
         IF sess=9  DO Fsesv!7 := Fsesv!7 + 1
         IF sess=10 DO Fsesv!8 := Fsesv!8 + 1
         IF sess=11 DO Fsesv!8 := Fsesv!8 + 1
         IF sess=12 DO Fsesv!8 := Fsesv!8 + 1
         IF sess>12 DO Fsesv!9 := Fsesv!9 + 1
       }

}

AND pr() BE
{ 
  writef("Mcount = %i4   Fcount = %i4    Total = %i4*n",
          Mcount,        Fcount,         Mcount+Fcount)

  newline()

  FOR i = 0 TO 7 DO
  { LET s = agegrp(i)
    writef("M%s %i2   F%s %i2*n", s, Magev!i, s, Fagev!i)
  }

  newline()

  FOR i = 0 TO 9 DO
  { LET s = sesgrp(i)
    writef("M%s %i2   F%s %i2*n", s, Msesv!i, s, Fsesv!i)
  }

  writef("*nMsessions %n   Fsessions %n*n", 
            Msessions,     Fsessions)

  newline()

  FOR i = 1 TO 6 DO
  { LET s = msgrp(i)
    writef("%s %i2*n", s, statv!i)
  }
}

AND agegrp(i) = VALOF SWITCHON i INTO
{ DEFAULT: RESULTIS "     "
  CASE 0:  RESULTIS "  -19"
  CASE 1:  RESULTIS "20-29"
  CASE 2:  RESULTIS "30-39"
  CASE 3:  RESULTIS "40-49"
  CASE 4:  RESULTIS "50-59"
  CASE 5:  RESULTIS "60-69"
  CASE 6:  RESULTIS "70-79"
  CASE 7:  RESULTIS "80+  "
}

AND sesgrp(i) = VALOF SWITCHON i INTO
{ DEFAULT: RESULTIS "     "
  CASE 0:  RESULTIS "    0"
  CASE 1:  RESULTIS "    1"
  CASE 2:  RESULTIS "    2"
  CASE 3:  RESULTIS "    3"
  CASE 4:  RESULTIS "    4"
  CASE 5:  RESULTIS "    5"
  CASE 6:  RESULTIS "    6"
  CASE 7:  RESULTIS "  7-9"
  CASE 8:  RESULTIS "10-12"
  CASE 9:  RESULTIS "  12+"
}

AND msgrp(i) = VALOF SWITCHON i INTO
{ DEFAULT: RESULTIS "     "

  CASE MNC:  RESULTIS "  MNC"
  CASE  MC:  RESULTIS "   MC"
  CASE  SD:  RESULTIS "   SD"
  CASE   S:  RESULTIS "    S"
  CASE   W:  RESULTIS "    W"
  CASE  SP:  RESULTIS "   SP"
}

