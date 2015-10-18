/*
This is a test program for the BCPL compiler and Cintcode interpreter

Last updated by Martin Richards (c) January 2011

This version is similar to cmpltest but includes tests for
the extended version BCPL compiled using xbcpl.

It tests all floating point operations including all the
sys(Sys_flt, op, ...) operations, the SLCT-OF operations
and all op:= assignments including those with OF on the
left hand side.

The ONLY free variable of this program is: sys  (or wrch)
*/

SECTION "xcmpltest"

GET "libhdr"

GLOBAL { f:200; g:401; h:602
         testno:203; failcount:204
         v:205; testcount:206; quiet:207; t:208
         bitsperword:210; msb:211; allones:212  }

STATIC { a=10; b=11; c=12; w=0  }

MANIFEST { k0=0; k1=1; k2=2  }

LET wrc(ch) BE sys(11,ch)   //wrch(ch)

AND wrs(s) BE
  FOR i = 1 TO s%0 DO wrc(s%i)

AND nl() BE wrc('*n')

AND wrd(n, d) BE //wrx(n,8)
///*
{ LET t = VEC 30
  AND i, k = 0, -n
  IF n<0 DO d, k := d-1, n
  t!i, i, k := -(k REM 10), i+1, k/10 REPEATUNTIL k=0
  FOR j = i+1 TO d DO wrc('*s')
  IF n<0 DO wrc('-')
  FOR j = i-1 TO 0 BY -1 DO wrc(t!j+'0')
}
//*/
AND wrn(n) BE wrd(n, 0)

AND wrx(n, d) BE
{ IF d>1 DO wrx(n>>4, d-1)
  wrc((n&15)!TABLE '0','1','2','3','4','5','6','7',
                   '8','9','A','B','C','D','E','F' )
}

LET t(x, y) = VALOF
{ testcount := testcount + 1
  wrd(testno, 4)
  wrc(' ')
  wrd(x, 21)
  wrc(' ')
  TEST x=y
  THEN wrs("OK")
  ELSE { wrx(x, 8); wrs(" FAILED*nIt should be ")
         wrd(y, 13)
         wrc(' ')
         wrx(y, 8)
         failcount := failcount + 1
       }
  nl()
  testno := testno + 1
  RESULTIS y
}

LET t1(a,b,c,d,e,f,g) = t(a+b+c+d+e+f, g)

LET start(parm) = VALOF
{ LET ww = 65
  LET v1 = VEC 200
  AND v2 = VEC 200
  wrs("*nCmpltest running on a ")
  bitsperword, msb, allones := 1, 1, 1
  UNTIL (msb<<1)=0 DO
    bitsperword, msb, allones := bitsperword+1, msb<<1, allones<<1 | 1
  TEST (@ww)%0=65
  THEN wrs("little")
  ELSE wrs("big")
  wrs(" ender machine*n")
  wrs("The BCPL word is ")
  wrd(bitsperword, 0)
  wrs(" bits long*n*n*n")
//abort(1000)    
  tester(0, 1, 2, v1, v2)

//{ LET n = 1   // special test for the << and >> operators
//  FOR i = -5 TO 80 DO writef("%i4 %xP*n", i, 1<<i)
//  FOR i = -5 TO 80 DO writef("%i4 %xP*n", i, msb>>i)
//}
    
  RESULTIS 0
}

AND tester(x, y, z, v1, v2) BE
{ LET n0, n1, n2, n3, n4 = 0, 1, 2, 3, 4
  LET n5, n6, n7, n8, n9 = 5, 6, 7, 8, 9
  LET oct1775 = #1775

//  wrs("*NCgtester entered*N")

//  FIRST INITIALIZE CERTAIN VARIABLES

  f, g, h := 100, 101, 102
  testno, testcount, failcount := 0, 0, 0
  v, w := v1, v2

  FOR i = 0 TO 200 DO v!i, w!i := 1000+i, 10000+i


  quiet := FALSE

//  TEST SIMPLE VARIABLES AND EXPRESSIONS

  testno := 1

  t(a+b+c, 33)        // 1
  t(f+g+h, 303)
  t(x+y+z, 3)

  t(123+321-400, 44)  // 4
  t(x=0, TRUE)
  t(y=0, FALSE)
  t(!(@y+x), 1)
  t(!(@b+x), 11)
  t(!(@g+x), 101)

  x, a, f := 5, 15, 105
  t(x, 5)            // 10
  t(a, 15)
  t(f, 105)

  v!1, v!2 := 1234, 5678
  t(v!1, 1234)       // 13
  t(v!z, 5678)

  t(x*a, 75)         //  15
  t(1*x+2*y+3*z+f*4,433)
  t(x*a+a*x, 150)

  t(100/(a-a+2), 50) //  18
  t(a/x, 3)
  t(a/-x, -3)
  t((-a)/x, -3)
  t((-a)/(-x), 3)
  t((a+a)/a, 2)
  t((a*x)/(x*a), 1)
  t((a+b)*(x+y)*123/(6*123), 26)

  t(n7 REM 2, 1)      //  26
  t(f REM 100, 5)
  t(a REM x, 0)

  t(-f, -105)       //  29

  f := 105
  t(f = 105, TRUE)   // 30
  t(f~= 105, FALSE)
  t(f < 105, FALSE)
  t(f>= 105, TRUE)
  t(f > 105, FALSE)
  t(f<= 105, TRUE)

  f := 104
  t(f = 105, FALSE)  // 36
  t(f~= 105, TRUE)
  t(f < 105, TRUE)
  t(f>= 105, FALSE)
  t(f > 105, FALSE)
  t(f<= 105, TRUE)

  f := 0
  t(f = 0, TRUE)    // 42
  t(f~= 0, FALSE)
  t(f < 0, FALSE)
  t(f>= 0, TRUE)
  t(f > 0, FALSE)
  t(f<= 0, TRUE)

  f := 1
  t(f = 0, FALSE)   // 48
  t(f~= 0, TRUE)
  t(f < 0, FALSE)
  t(f>= 0, TRUE)
  t(f > 0, TRUE)
  t(f<= 0, FALSE)

  testno := 60

  t(oct1775<<3, #17750)  // 60
  t(oct1775>>3, #177)
  t(oct1775<<z+1, #17750)
  t(oct1775>>z+1, #177)

  { LET b1100 = #b1100
    LET b1010 = #b1010
    LET yes, no = TRUE, FALSE

    testno := 70

    t(b1100&#B1010, #B1000)    //  70
    t(b1100 | #B1010, #B1110)
    t((b1100 EQV   #B1010) & #B11111, #B11001)
    t(b1100 NEQV  #B1010, #B0110)

    t(NOT yes, no)         // 74
    t(NOT no, yes)
    t(NOT(b1100 EQV -b1010), b1100 NEQV -b1010)
  }

  testno := 80
  f := 105
  t(-f, -105)               // 80

  t(!v, 1000)               // 81
  t(v!0, 1000)
  t(v!1, 1234)
  t(v!(!v-998), 5678)

  testno := 90

  t(!w, 10000)              // 90
  t(w!0, 10000)
  t(0!w, 10000)
  t(1!w, 10001)
  t(w!1, 10001)
  t(!(w+200), 10200)

  a := TRUE
  b := FALSE

  IF a DO x := 16
  t(x, 16)                  // 96
  x := 16

  IF b DO x := 15
  t(x, 16)                  // 97
  x := 15

  { LET w = VEC 20
    a := l1
    GOTO a
l2: wrs("GOTO ERROR*N")
    failcount := failcount+1
  }

l1:
  a := VALOF RESULTIS 11
  t(a, 11)                  // 98

  testno := 100  // TEST SIMULATED STACK ROUTINES

  { LET v1 = VEC 1
    v1!0, v1!1 := -1, -2
    { LET v2 = VEC 10
      FOR i = 0 TO 10 DO v2!i := -i
      t(v2!5, -5)           //  101
    }
    t(v1!1, -2)             //  102
  }

  x := x + t(x,15, t(f, 105), t(a, 11)) - 15   // 103-105
  t(x, 15)                                     // 106

  x := x+1
  t(x, 16)   // 107
  x := x-1
  t(x, 15)   // 108
  x := x+7
  t(x,22)    // 109
  x := x-22
  t(x, 0)    // 110
  x := x+15
  t(x, 15)   // 111
  x := x + f
  t(x, 120)  // 112
  x := 1

  testno := 130
  f := 105
  t(f = 105 -> 1, 2, 1)   // 130
  t(f~= 105 -> 1, 2, 2)
  t(f < 105 -> 1, 2, 2)
  t(f>= 105 -> 1, 2, 1)
  t(f > 105 -> 1, 2, 2)
  t(f<= 105 -> 1, 2, 1)

  f := 104
  t(f = 105 -> 1, 2, 2)  // 136
  t(f~= 105 -> 1, 2, 1)
  t(f < 105 -> 1, 2, 1)
  t(f>= 105 -> 1, 2, 2)
  t(f > 105 -> 1, 2, 2)
  t(f<= 105 -> 1, 2, 1)

  f := 0
  t(f = 0 -> 1, 2, 1)    // 142
  t(f~= 0 -> 1, 2, 2)
  t(f < 0 -> 1, 2, 2)
  t(f>= 0 -> 1, 2, 1)
  t(f > 0 -> 1, 2, 2)
  t(f<= 0 -> 1, 2, 1)
  f := 1
  t(f = 0 -> 1, 2, 2)   // 148
  t(f~= 0 -> 1, 2, 1)
  t(f < 0 -> 1, 2, 2)
  t(f>= 0 -> 1, 2, 1)
  t(f > 0 -> 1, 2, 1)
  t(f<= 0 -> 1, 2, 2)

  testno := 200  // TEST SWITCHON COMMANDS

  { LET s1, s1f = 0, 0
    AND s2, s2f = 0, 0
    AND s3, s3f = 0, 0
    FOR i = -200 TO 200 DO
    { LET x = 7
      SWITCHON i INTO
      { DEFAULT: s1 := s1+1000; ENDCASE
        CASE -1000: s1f := s1f + i; ENDCASE
        CASE -200: s1 := s1 + 1
        CASE -190: s1 := s1 + 1
        CASE -180: s1 := s1 + 1
        CASE   -5: s1 := s1 + 1
        CASE    0: s1 := s1 + 1
        CASE -145: s1 := s1 + 1
        CASE    7: s1 := s1 + 1
        CASE    8: s1 := s1 + 1
        CASE  200: s1 := s1 + 1
        CASE  190: s1 := s1 + 1
        CASE  100: s1 := s1 + 1
        CASE   90: s1 := s1 + 1
        CASE  199: s1 := s1 + 1
        CASE   95: s1 := s1 + 1
        CASE   76: s1 := s1 + 1
        CASE   88: s1 := s1 + 1
        CASE   99: s1 := s1 + 1
        CASE  -98: s1 := s1 + 1
        CASE   11: s1 := s1 + 1
        CASE   12: s1 := s1 + 1
        CASE   13: s1 := s1 + 1
        CASE   41: s1 := s1 + 1
        CASE   91: s1 := s1 + 1
        CASE   92: s1 := s1 + 1
        CASE   71: s1 := s1 + 1
        CASE   73: s1 := s1 + 1
        CASE   74: s1 := s1 + 1
        CASE   81: s1 := s1 + 1
        CASE   82: s1 := s1 + 1
        CASE   61: s1 := s1 + 1
        CASE -171: s1 := s1 + 1
        CASE -162: s1 := s1 + 1
      }

      SWITCHON i+10000 INTO
      { DEFAULT: s2 := s2+1000; ENDCASE
        CASE 10020: s2 := s2 + 1
        CASE 10021: s2 := s2 + 1
        CASE 10022: s2 := s2 + 1
        CASE 10023: s2 := s2 + 1
        CASE 10024: s2 := s2 + 1
        CASE 10025: s2 := s2 + 1
        CASE 10026: s2 := s2 + 1
        CASE 10027: s2 := s2 + 1
        CASE 10028: s2 := s2 + 1
        CASE 10029: s2 := s2 + 1
        CASE 10010: s2 := s2 + 1
        CASE 10011: s2 := s2 + 1
        CASE 10012: s2 := s2 + 1
        CASE 10013: s2 := s2 + 1
        CASE 10014: s2 := s2 + 1
        CASE 10015: s2 := s2 + 1
      }

      SWITCHON i*100 INTO
      { DEFAULT: s3 := s3+1000; ENDCASE
        CASE -100000: s3f := s3f + i; ENDCASE
        CASE -20000: s3 := s3 + 1
        CASE -19000: s3 := s3 + 1
        CASE -18000: s3 := s3 + 1
        CASE   -500: s3 := s3 + 1
        CASE    000: s3 := s3 + 1
        CASE -14500: s3 := s3 + 1
        CASE    700: s3 := s3 + 1
        CASE    800: s3 := s3 + 1
        CASE  20000: s3 := s3 + 1
        CASE  19000: s3 := s3 + 1
        CASE  10000: s3 := s3 + 1
        CASE   9000: s3 := s3 + 1
        CASE  19900: s3 := s3 + 1
        CASE   9500: s3 := s3 + 1
        CASE   7600: s3 := s3 + 1
        CASE   8800: s3 := s3 + 1
        CASE   9900: s3 := s3 + 1
        CASE  -9800: s3 := s3 + 1
        CASE   1100: s3 := s3 + 1
        CASE   1200: s3 := s3 + 1
        CASE   1300: s3 := s3 + 1
        CASE   4100: s3 := s3 + 1
        CASE   9100: s3 := s3 + 1
        CASE   9200: s3 := s3 + 1
        CASE   7100: s3 := s3 + 1
        CASE   7300: s3 := s3 + 1
        CASE   7400: s3 := s3 + 1
        CASE   8100: s3 := s3 + 1
        CASE   8200: s3 := s3 + 1
        CASE   6100: s3 := s3 + 1
        CASE -17100: s3 := s3 + 1
        CASE -16200: s3 := s3 + 1
      }
    }
    t(s1f, 0)                                        // 200
    t(s2f, 0)                                        // 201
    t(s3f, 0)                                        // 202
    t(s1, (401-32)*1000 + 32* (32+1)/2)  //369528     // 203
    t(s2, (401-16)*1000 + 16* (16+1)/2)  //385136     // 204
    t(s3, (401-32)*1000 + 32* (32+1)/2)  //369528     // 205
  }

  testno := 250  // TEST FUNCTION CALLING

  t1(1,2,3,4,5,6, 21)
  t1(t(1,1), t(2,2), t(3,3), t(4,4), t(5,5), t(6,6),
     t(21,21))
  t1(VALOF RESULTIS 1,
     VALOF RESULTIS 2,
     VALOF RESULTIS 3,
     VALOF RESULTIS 4,
     VALOF RESULTIS 5,
     VALOF RESULTIS 6,
     21)
  t1(VALOF RESULTIS 1,
     t(2,2),
     VALOF RESULTIS 3,
     t(4,4),
     VALOF RESULTIS 5,
     t(6,6),
     21)
  t1( 1, t(2,2), VALOF RESULTIS 3,
      4, t(5,5), VALOF RESULTIS 6,
      21)
  t1(!v,v!0,v!200,!w,w!0,w!200, 2*1000+1200+2*10000+10200)
  (t1+(x+x)/x-2)(1,1,1,1,1,1,6)

  testno := 300  // TEST EXPRESSION OPERATORS

  f := 105
  t((2+3)+f+6,116)
  t(f+2+3+6,116)
  t(6+3+2+f, 116)
  t(f-104, 1)
  t((x+2)=(x+2)->99,98, 99)
  t(f<f+1->21,22, 21)
  t(f>f+1->31,32, 32)
  t(f<=105->41,42, 41)
  t(f>=105->51,52, 51)

  testno := 400  // TEST REGISTER ALLOCATION ETC.

  x := 0
  y := 1
  z := 2
  t(x, 0)
  t(y, 1)
  t(z, 2)
  f,g,h := 101,102,103
  a,b,c := 11,12,13
  t(x+1,1)
  t(f+1, 102)
  t(a+1, 12)
  t(!(@a*2/2+f-101),11)
  a := @f
  t(!a, 101)
  b := @g
  a := @b
  t(!!a, 102)
  w!0 := @w!1
  w!1 := @h
  t(z*y+(w!0)!0!0-2, 103)
  t(z*y+w!1!0-2, 103)
  t(t(123,123),t(123,123))

  testno := 500 // test 16 and 32  bit cintcode operands

  x := 100
  t(x*x, 10000)               // LH
  t(x*x*x*x, 100000000)       // LW
  t(x*x+10000, 20000)         // AH
  t(x*x+100000000, 100010000) // AW
  t(x*x-10000, 0)             // SH
  t(x*x-100000000, -99990000) // AW

  testno := 600

  locals(103,104,105,106,107,108,109,110,111,112,113,114,115,116,117)

  testno := 700

  a := 1
  b := msb
  c :=  allones
  t(a<<0, 1)
  t(a<<1, 2)
  t(a<<2, 4)
  t(a<<bitsperword-1, msb)
  t(a<<bitsperword,     0)
  t(a<<bitsperword+1,   0)

  t(a>>0, 1)
  t(b>>bitsperword-1, 1)
  t(c>>bitsperword-1, 1)
  t(b>>bitsperword,   0)
  t(c>>bitsperword,   0)

  testno := 800
  a, b, c := 20, -30, 0
  t(ABS a, 20)
  t(ABS b, 30)
  t(ABS c, 0)

  v!0 := 1001
  t(v!0, 1001)
  v!1 := 1002
  t(v!1, 1002)
  v!2 := 1003
  t(v!2, 1003)
  v!3 := 1004
  t(v!3, 1004)
  v!4 := 1005
  t(v!4, 1005)

  w!0 := 2001
  t(w!0, 2001)
  w!1 := 2002
  t(w!1, 2002)
  w!2 := 2003
  t(w!2, 2003)
  w!3 := 2004
  t(w!3, 2004)
  w!4 := 2005
  t(w!4, 2005)

  w%0 := 21
  t(w%0, 21)
  w%1 := 22
  t(w%1, 22)
  w%2 := 23
  t(w%2, 23)
  w%3 := 3
  t(w%3, 3) // compiles xpbyt instruction

  a := 10
  b := a<<5
  w%4 := a  // compiles a btc instruction
  t(w%4, 10)

  a, b, g := 100,101,300
  a := a+1
  t(a, 101)
  a := a+b
  t(a, 202)
  g := g+b
  t(g, 401)

  g := 8
  b := 3
  a := g REM b
  t(a, 2)

  g := 20
  b := 12
  a := g - b
  t(a, 8)

  testno := 850

  // Test Unicode character and string escapes
  // assuming the compiler has UTF8 as the default encoding.
  t('*#1234', #x1234)
  t("*#1234"%0, 3)                // 0001 0010 0011 0100
  t("*#1234"%1, #b1110_0001)      // 0001
  t("*#1234"%2, #b10_001000)      //      0010 00
  t("*#1234"%3, #b10_110100)      //             11 0100

  t('*##1234_5678', #x1234_5678)
  t("*##1234_5678"%0, 6)          // 0001 0010 0011 0100 0101 0110 0111 1000
  t("*##1234_5678"%1, #b1111110_0)//  0
  t("*##1234_5678"%2, #b10_010010)//   01 0010
  t("*##1234_5678"%3, #b10_001101)//           0011 01
  t("*##1234_5678"%4, #b10_000101)//                  00 0101
  t("*##1234_5678"%5, #b10_011001)//                          0110 01
  t("*##1234_5678"%6, #b10_111000)//                                 11 1000

  // Test GB2312 character and string escapes
  // assuming the compiler has UTF8 as the default encoding.
  t('*#g*#4566', 4566)
  t("*#g*#4566"%0, 2)     // row 45  col 66  = character 'foreign'
  t("*#g*#4566"%1, #xE2)  // #xE2 = 66 + 160
  t("*#g*#4566"%2, #xCD)  // #xCD = 45 + 160

  testno := 1000
  testslct()
  testno := 2000
  testopassign()
  testno := 3000
  testflt()

  nl()
  wrn(testcount)
  wrs(" TESTS COMPLETED, ")
  wrn(failcount)
  wrs(" FAILURE(S)*N")
}

AND testslct() BE
{ MANIFEST {
    S0_0_0 = SLCT 0      // Full word offset 0
    S0_0_1 = SLCT 1      // Full word offset 1
    S0_4_0 = SLCT 4:0    // 28-bit field, shift of 4, offset 0 
    S8_4_1 = SLCT 8:4:1  //  8-bit field, shift of 4, offset 1 
    S8_0_0 = SLCT 8:0:0  // ls 8 bits, offset 0
  }

  LET a, b = #x12345678, #xFEDCBA98  // Two bit patterns
  LET x, y = a, b  // A two word test record
  LET r = @x       // Pointer to the record
  
  t(S0_0_0::r, #x12345678)
  t(S0_0_1::r, #xFEDCBA98)
  t(S0_4_0::r, #x01234567)
  t(S8_4_1::r, #x000000A9)
  t(S8_0_0::r, #x00000078)

  x, y := a, b
  S0_0_0::r := #x21436587;   t(x, #x21436587)
  x, y := a, b
  S0_0_1::r := #xEFCDAB89;   t(y, #xEFCDAB89)
  x, y := a, b
  S0_4_0::r := #xEFCDAB89;   t(x, #xFCDAB898)
  x, y := a, b
  S8_4_1::r := #xA9876543;   t(y, #xFEDCB438)
  x, y := a, b
  S8_0_0::r := #xCBA98765;   t(x, #x12345665)

  x := r
  S0_0_0::r !:= 1;   t(x, b)
  x, y := a, r
  S0_0_1::r !:= 0;   t(y, a)

  b := #x12345BCA;
  y := b; S8_4_1::r   *:= 2;    t(y, #x1234578A)
  y := b; S8_4_1::r   /:= 2;    t(y, #x123455EA)
  y := b; S8_4_1::r MOD:= 64;   t(y, #x123453CA)
  y := b; S8_4_1::r   +:= #x15; t(y, #x12345D1A)
  y := b; S8_4_1::r   -:= #x0D; t(y, #x12345AFA)
  y := b; S8_4_1::r  <<:= 1;    t(y, #x1234578A)
  y := b; S8_4_1::r  >>:= 1;    t(y, #x123455EA)
  y := b; S8_4_1::r   &:= #xC7; t(y, #x1234584A)
  y := b; S8_4_1::r   |:= #x61; t(y, #x12345FDA)
  y := b; S8_4_1::r EQV:= #xC6; t(y, #x1234585A)
  y := b; S8_4_1::r XOR:= #xC6; t(y, #x123457AA)
}

AND testopassign() BE
{ LET v = VEC 10

  v!1 := v; v!5 := 1000; v!1 !:= 5; t(v!1, 1000)
   
  FOR a = -5 TO 5 FOR b = -5 TO 5 DO
  { LET x, y = ?, ?
    LET fa, fb = FLOAT (a*1000), FLOAT (b*1000)
    v%6 := a

    x := fa; x #*:= fb; t(x, fa #* fb)
    IF b DO
    { x := fa; x #/:= fb; t(x, fa #/ fb)
    }
    x := fa; x #+:= fb; t(x, fa #+ fb)
    x := fa; x #-:= fb; t(x, fa #- fb)

    x := a; x   *:= b; t(x, a   * b)
    IF b DO
    { x := a; x   /:= b; t(x, a   / b)
      x := a; x MOD:= b; t(x, a MOD b)
    }

    x := a; x   +:= b; t(x, a   + b)
    x := a; x   -:= b; t(x, a   - b)
    x := a; x  <<:= b; t(x, a  << b)
    x := a; x  >>:= b; t(x, a  >> b)
    x := a; x   &:= b; t(x, a   & b)
    x := a; x   |:= b; t(x, a   | b)
    x := a; x EQV:= b; t(x, a EQV b)
    x := a; x XOR:= b; t(x, a XOR b)

    // Test s%x op:= a
    v%5 := a; v%6 := v%5   * b;  v%5   *:= b; t(v%5, v%6)
    IF b DO
    { v%5 := a; v%6 := v%5   / b; v%5   /:= b; t(v%5, v%6)
      v%5 := a; v%6 := v%5 MOD b; v%5 MOD:= b; t(v%5, v%6)
    }
    v%5 := a; v%6 := v%5   + b; v%5   +:= b; t(v%5, v%6)
    v%5 := a; v%6 := v%5   - b; v%5   -:= b; t(v%5, v%6)
    v%5 := a; v%6 := v%5  << b; v%5  <<:= b; t(v%5, v%6)
    v%5 := a; v%6 := v%5  >> b; v%5  >>:= b; t(v%5, v%6)
    v%5 := a; v%6 := v%5   & b; v%5   &:= b; t(v%5, v%6)
    v%5 := a; v%6 := v%5   | b; v%5   |:= b; t(v%5, v%6)
    v%5 := a; v%6 := v%5 EQV b; v%5 EQV:= b; t(v%5, v%6)
    v%5 := a; v%6 := v%5 XOR b; v%5 XOR:= b; t(v%5, v%6)
  }
}

AND testflt() BE
{ LET x, y = 0,0

  t(FIX #-(FLOAT 123456), FIX FLOAT -123456) 
  t(#- (FLOAT 123456), FLOAT -123456) 
  t(FIX(#ABS (FLOAT -123456)), FIX(FLOAT 123456)) 
  t(#ABS (FLOAT -1), FLOAT 1) 
  t(FLOAT 123456 #* FLOAT 2, FLOAT 246912) 
  t(FLOAT 246912 #/ FLOAT 2, FLOAT 123456) 
  t(FLOAT 12345 #+ FLOAT 54321, FLOAT 66666) 
  t(FLOAT 12345 #- FLOAT 1234, FLOAT 11111) 

  UNLESS sys(Sys_flt, fl_avail)=-1 DO
  { wrs("sys(Sys_flt, ...) not available*n")
  }

  t(sys(Sys_flt, fl_mk, 12345, -1), 1234.5)

  x := sys(Sys_flt, fl_unmk, 1234.5)
  y := result2
  t(x, 123450000)
  t(y, -5)

  x := sys(Sys_flt, fl_unmk, #-1234.5)
  y := result2
  t(x, -123450000)
  t(y, -5)

  x := sys(Sys_flt, fl_float, 123456); t(x, FLOAT 123456)
  x := sys(Sys_flt, fl_fix, 12345.6); t(x, FIX 12345.6)
  x := sys(Sys_flt, fl_abs, 12345.6); t(x, #ABS 12345.6)
  x := sys(Sys_flt, fl_abs, #-12345.6); t(x, #ABS #-12345.6)
  x := sys(Sys_flt, fl_mul, 12.5, 43.5); t(x, 12.5 #* 43.5)
  x := sys(Sys_flt, fl_div, 12.5, #-43.5); t(x, 12.5 #/ #-43.5)
  x := sys(Sys_flt, fl_add, 12.5, 43.5); t(x, 12.5 #+ 43.5)
  x := sys(Sys_flt, fl_sub, 12.5, 43.5); t(x, 12.5 #- 43.5)
  x := sys(Sys_flt, fl_pos, #-12345.6); t(x, #+ #-12345.6)
  x := sys(Sys_flt, fl_neg, #-12345.6); t(x, #- #-12345.6)

  FOR a = -2 TO 2 FOR b = -2 TO 2 DO
  { x, y := FLOAT a, FLOAT b
    t(sys(Sys_flt, fl_eq, x, y), x #=  y)
    t(sys(Sys_flt, fl_ne, x, y), x #~= y)
    t(sys(Sys_flt, fl_ls, x, y), x #<  y)
    t(sys(Sys_flt, fl_gr, x, y), x #>  y)
    t(sys(Sys_flt, fl_le, x, y), x #<= y)
    t(sys(Sys_flt, fl_ge, x, y), x #>= y)
  }

  t(FIX(sys(Sys_flt, fl_acos, 0.5)#*1000000.0), 1047198)
  t(FIX(sys(Sys_flt, fl_asin, 0.5)#*1000000.0),  523599)
  t(FIX(sys(Sys_flt, fl_atan, 0.5)#*1000000.0),  463648)
  t(FIX(sys(Sys_flt, fl_atan2, 0.5, 0.4)#*1000000.0),    896055)
  t(FIX(sys(Sys_flt, fl_cos, 0.5)#*1000000.0),   877583)
  t(FIX(sys(Sys_flt, fl_sin, 0.5)#*1000000.0),   479426)
  t(FIX(sys(Sys_flt, fl_tan, 0.5)#*1000000.0),   546303)
  t(FIX(sys(Sys_flt, fl_cosh, 0.5)#*1000000.0), 1127626)
  t(FIX(sys(Sys_flt, fl_sinh, 0.5)#*1000000.0),  521095)
  t(FIX(sys(Sys_flt, fl_tanh, 0.5)#*1000000.0),  462117)
  t(FIX(sys(Sys_flt, fl_exp, 1.0)#*1000000.0),  2718282)

  x := sys(Sys_flt, fl_frexp, 1023.0)
  y := result2
  t(x, 1023.0#/1024.0)
  t(y, 10)

  x := sys(Sys_flt, fl_ldexp, 1023.0#/1024.0, 10)
  t(x, 1023.0)

  t(FIX(sys(Sys_flt, fl_log, 0.5)#*1000000.0),    -693147)
  t(FIX(sys(Sys_flt, fl_log10, 0.5)#*1000000.0),  -301030)

  x := sys(Sys_flt, fl_modf, 123.25)
  y := result2
  t(x, 0.25)
  t(y, 123)

  t(FIX(sys(Sys_flt, fl_pow, 2.0, 0.5)#*1000000.0),  1414214)
  t(FIX(sys(Sys_flt, fl_sqrt, 2.0)#*1000000.0),  1414214)
  t(FIX(sys(Sys_flt, fl_ceil, 2.5)#*1000000.0),  3000000)
  t(FIX(sys(Sys_flt, fl_ceil, #-2.5)#*1000000.0),  -2000000)
  t(FIX(sys(Sys_flt, fl_floor, 2.5)#*1000000.0), 2000000)
  t(FIX(sys(Sys_flt, fl_floor, #-2.5)#*1000000.0), -3000000)

  t(FIX(sys(Sys_flt, fl_fmod, 100.25, 25.0)#*1000000.0),  250000)
}


AND locals(p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17) BE
{ t(p3, 103)
  t(p4, 104)
  t(p5, 105)
  t(p6, 106)
  t(p7, 107)
  t(p8, 108)
  t(p9, 109)
  t(p10,110)
  t(p11,111)
  t(p12,112)
  t(p13,113)
  t(p14,114)
  t(p15,115)
  t(p16,116)
  t(p17,117)
}
