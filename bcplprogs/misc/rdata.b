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
Mdna   : 205
Fdna   : 206

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
Mdna := 0
Fdna := 0

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

  d( 83, F,  35,  18, 0,  MNC)
  d(112, F,  49,   6, 0,    S)
  d(  0, F,  31,   0, 1,   MC)
  d( 86, F,  40,   6, 1,   SD)
  d(  0, M,  34,   6, 0,  MNC)
  d( 22, F,  50,  12, 1,    S)
  d(114, M,  47,   6, 0,   MC)
  d( 93, M,  55,   6, 0,   SD)
  d( 54, F,  71,   1, 0,  MNC)
  d(116, M,  49,   1, 0,  MNC)
  d(115, F,  26,   1, 2,    S)
  d(117, F,  43,   2, 0,    S)
  d(105, F,  31,   5, 1,    S)
  d(113, M,  35,   4, 1,   SD)
  d(110, M,  28,   5, 0,   SD)
  d(118, F,  25,   0, 1,    0)
  d( 67, F,  48,  15, 1,   MC)
  d( 84, F,  28,  12, 0,    S)
  d(100, F,  31,   4, 0,   MC)
  d(119, F,  22,   4, 0,    S)
  d(109, F,  50,   6, 1,  MNC)
  d(123, F,  18,   2, 1,    S)
  d(120, F,  36,   4, 0,   MC)
  d(122, F,  33,  11, 0,  MNC)
  d(128, F,  25,   3, 0,  MNC)
  d(124, M,  55,   6, 2,    S)
  d( 85, F,  26,   3, 0,   MC)
  d(127, F,  30,  12, 0,  MNC)
  d(125, M,  54,   1, 0,   MC)
  d(126, F,  64,   1, 0,  MNC)
  d(103, F,  48,   8, 0,   MC)
  d( 90, F,  45,   5, 0,   SD)
  d( 87, F,  55,   2, 0,   MC)
  d(132, F,  28,   2, 2,  MNC)
  d(142, F,  47,   4, 2,   MC)
  d(131, F,  25,   1, 0,   SP)
  d(133, F,  62,   2, 0,    W)
  d( 96, F,  41,   3, 0,   MC)
  d(134, F,  31,   8, 0,    S)
  d( 34, F,  54,   1, 1,  MNC)
  d(135, M,  25,   2, 0,    S)
  d(134, M,  36,   2, 2,   MC)
  d(138, F,  16,   2, 0,   SP)
  d(136, F,  51,   5, 2,   SP)
  d(140, F,  63,   3, 0,  MNC)
  d(144, F,  52,   1, 0,   MC)
  d(143, F,  41,   4, 0,   MC)
  d( 80, F,  50,   1, 0,   MC)
  d(146, F,  50,   1, 0,    S)
  d(147, F,  28,   5, 0,    S)
  d(148, M,  22,   4, 0,    S)
  d(149, F,  55,   3, 0,   SD)
  d(150, M,  32,   1, 0,    S)
  d(151, M,  25,   0, 1,    S)
  d( 99, F,  45,   2, 1,   SD)
  d(152, F,  37,  18, 0,  MNC)
  d(153, F,  43,   3, 0,   MC)
  d(121, F,  34,   2, 0,   SP)
  d(154, M,  69,   6, 0,    W)
  d(155, F,  26,   4, 0,    S)
  d(129, F,  34,   5, 0,   SP)
  d(130, F,  45,   4, 0,   MC)
  d(  0, M,  28,   5, 0,   SD)

  pr()
  RESULTIS 0
}

AND d(ser, s, a, sess, dna, ms) BE
{ statv!ms := statv!ms + 1

  TEST s=M
  THEN { Mcount := Mcount + 1
         Mdna := Mdna + dna

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
         Fdna := Fdna + dna

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
  writef("Mdna   = %i4   Fdna   = %i4    Total = %i4*n",
          Mdna,          Fdna,           Mdna+Fdna)

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

