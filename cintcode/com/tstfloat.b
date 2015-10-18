/*
Test simple floating point operations including
manifest floating point constants.
*/

SECTION "tstfloat"

GET "libhdr"

GLOBAL {
 testno:ug
 errors
 f1_234
 f1_234neg
 f12_34
 f12_64
 i123
 i456
 i579
 f1_5
 f0_0
 f1_0
}

LET f(x, y) = VALOF
{ 
  pr(x)
  pr(y)
  x := x #> y
  writef("x #> y => %n*n", x)
  RESULTIS x
}

AND start1() = VALOF
{ LET x = f(1.234, 1.235)
  result2 := 0
  RESULTIS 0
}

AND pr(x) BE
{ 
  writef("%c %8b %23b*n",
          x<0->'-','+',
          x>>23 & #xFF,
          x & #x7FFFFF)
}



LET initconsts() BE
{
  f1_234 := 1.234;  //prfloat(f1_234); newline()
  f1_234neg := sys(Sys_flt, fl_neg, 1.234);  //prfloat(f1_234neg); newline()
  f12_34 := 12.34
  f12_64 := 12.64
  i123, i456, i579 := 123, 456, 579
  f1_5 := 1.5
  f0_0 := 0.0
  f1_0 := 1.0
}

AND start() = VALOF
{ LET c1234 = 1234
  LET a = 1.234
  AND b = #-1.234
  AND c = 0.0
  LET d = #-c
  AND e = FIX a
  AND f = FIX b
  AND g = FLOAT 1234
  AND h = #ABS a
  AND i = #ABS b
  LET j = a #* b #/ g
  AND k = 0//a #+ b #- g
  AND l = #+ b
  LET m = TABLE
        1.0,
        2.0,
        1.0 #+ 2.0,
        1.0 #- 2.0,
        #- 1.0,
        2.0 #* 3.0,
        2.0 #/ 3.0,
        #ABS (#- 1.5),
        #ABS (#+ 1.5),
        FLOAT 5

  //writef("1.0:          ");  prfloat(m!0); newline()
  //writef("2.0:          ");  prfloat(m!1); newline()
  //writef("1.0 #+ 2.0:   ");  prfloat(m!2); newline()
  //writef("1.0 #- 2.0:   ");  prfloat(m!3); newline()
  //writef("#- 1.0:       ");  prfloat(m!4); newline()
  //writef("2.0 #** 3.0:   "); prfloat(m!5); newline()
  //writef("2.0 #/ 3.0:   ");  prfloat(m!6); newline()
  //writef("#ABS (#- 1.5) ");  prfloat(m!7); newline()
  //writef("#ABS (#+ 1.5) ");  prfloat(m!8); newline()
  //writef("FLOAT 5:      ");  prfloat(m!9); newline()
        
  initconsts()

  testno := 0
  errors := 0

  //IF a #<= a DO writef("a<=a*n")
  //IF a #>= a DO writef("a>=a*n")
  //IF a #>= a DO writef("a>=a*n")
  //IF a #>= b DO writef("a>=b*n")
  //IF c #= d  DO writef("c>=d*n")
  //writef("e=%n f=%n*n", e, f)
  //IF g #~= 1234.1 DO writef("g #~= 1234.1*n")
  //IF g #< 1234.1  DO writef("g #< 1234.1*n")
  //IF g #> 1233.9  DO writef("g #> 1233.9*n")

//newline()
  //writef("Testing monadic #-  %8x %8x*n", f1_234,  #- f1_234neg)
  t(f1_234, #- f1_234neg)                     // 1

  //writef("Testing monadic #- and #+*n")
  t(#- 0.0, #+ 0.0)                           // 2

  //writef("Testing #ABS*n")
  t(#ABS f1_234neg, 1.234)                    // 3
  //writef("Testing FIX*n")
  tb(FIX f12_64, 13)                          // 4
  //writef("Testing FIX*n")
  tb(FIX (#- f12_64), -13)                    // 5
  //writef("Testing FLOAT*n")
  t(FLOAT i123 #+ FLOAT i456, FLOAT i579)     // 6
  //writef("Testing #***n")
  t(f1_234 #* 2.0, 2.468)                     // 7
  //writef("Testing #/*n")
  t(f1_5 #/ 2.0, 0.75)                        // 8
  //writef("Testing #+*n")
  t(f1_234 #+ 2.0, 3.234)                     // 9 
  //writef("Testing #-*n")
  t(f1_5 #- 2.0, #- 0.5)                      //10

  //writef("Testing manifest #=*n")
  tb(1.234 #= 1.233, FALSE)                   //11
  tb(1.234 #= 1.234, TRUE)                    //12
  tb(1.234 #= 1.235, FALSE)                   //13

  //writef("Testing manifest #~=*n")
  tb(1.234 #~= 1.233, TRUE)                   //14
  tb(1.234 #~= 1.234, FALSE)                  //15
  tb(1.234 #~= 1.235, TRUE)                   //16

  //writef("Testing manifest #<=*n")
  tb(1.234 #<= 1.233, FALSE)                  //17
  tb(1.234 #<= 1.234, TRUE)                   //18
  tb(1.234 #<= 1.235, TRUE)                   //19

  //writef("Testing manifest #>=*n")
  tb(1.234 #>= 1.233, TRUE)                   //20
  tb(1.234 #>= 1.234, TRUE)                   //21
  tb(1.234 #>= 1.235, FALSE)                  //22

  //writef("Testing manifest #<*n")
  tb(1.234 #< 1.233, FALSE)                   //23
  tb(1.234 #< 1.234, FALSE)                   //24
  tb(1.234 #< 1.235, TRUE)                    //25

  //writef("Testing manifest #>*n")
  tb(1.234 #> 1.233, TRUE)                    //26
  tb(1.234 #> 1.234, FALSE)                   //27
  tb(1.234 #> 1.235, FALSE)                   //28

  testno := 30

  //writef("Testing #=*n")
  tb(f1_234 #= 1.233, FALSE)                  //31
  tb(f1_234 #= 1.234, TRUE)                   //32
  tb(f1_234 #= 1.235, FALSE)                  //33

  //writef("Testing #~=*n")
  tb(f1_234 #~= 1.233, TRUE)                  //34
  tb(f1_234 #~= 1.234, FALSE)                 //35
  tb(f1_234 #~= 1.235, TRUE)                  //36

  //writef("Testing #<=*n")
  tb(f1_234 #<= 1.233, FALSE)                 //37
  tb(f1_234 #<= 1.234, TRUE)                  //38
  tb(f1_234 #<= 1.235, TRUE)                  //39 x

  //writef("Testing #>=*n")
  tb(f1_234 #>= 1.233, TRUE)                  //40
  tb(f1_234 #>= 1.234, TRUE)                  //41
  tb(f1_234 #>= 1.235, FALSE)                 //42 x

  //writef("Testing #<*n")
  tb(f1_234 #< 1.233, FALSE)                  //43
  tb(f1_234 #< 1.234, FALSE)                  //44
  tb(f1_234 #< 1.235, TRUE)                   //45 x

  //writef("Testing #>*n")
  tb(f1_234 #> 1.233, TRUE)                   //46
  tb(f1_234 #> 1.234, FALSE)                  //47
  tb(f1_234 #> 1.235, FALSE)                  //48 x

  testno := 100

  //writef("Testing manifest constants*n")
  //t(1.0, 1.0)                                 //101
  //t(2.0, 2.0)                                 //102
  //t(3.0, 3.0)                                 //103

  //writef("Testing manifest negative constants*n")
  //t(#- 1.0, #- 1.0)                           //104
  //t(#- 2.0, #- 2.0)                           //105
  //t(#- 3.0, #- 3.0)                           //106

  //writef("Testing manifest FLOAT*n")
  //t(FLOAT 1234, 1234.0)                       //107
  //writef("Testing FLOAT*n")
  //t(FLOAT c1234, 1234.0)                      //108

  newline()
  writef("sys(Sys_flt, fl_radius2, 3.0, 4.0)      = %10.3d*n",
          sys(Sys_flt, fl_F2N,
                       1_000,
                       sys(Sys_flt, fl_radius2, 3.0, 4.0)))

  writef("sys(Sys_flt, fl_radius3, 1.0, 2.0, 2.0) = %10.3d*n",
          sys(Sys_flt, fl_F2N,
                       1_000,
                       sys(Sys_flt, fl_radius3, 1.0, 2.0, 2.0)))

  writef("*nEnd of floating point test, %n error%-%ps*n", errors)
  RESULTIS 0
}



AND t(x, y) BE
{ 
  testno := testno+1
  writef("%i3: ", testno)
  prfloat(x)
  prfloat(y)

  // Change -0.0 to +0.0 leaving everything else unchanged
  x := sys(Sys_flt, fl_add, x, 0.0)
  y := sys(Sys_flt, fl_add, y, 0.0)

  TEST x = y // Test that the bit patterns are identical
  THEN { writef(" OK*n")
       }
  ELSE { writef(" BAD*n")
         errors := errors+1
       }
}

AND tb(x, y) BE
{ testno := testno+1

  writef("%i3: x=%i2 y=%i2", testno, x, y)
  TEST x = y
  THEN { writef(" OK*n")
       }
  ELSE { writef(" BAD*n")
         errors := errors+1
       }
}

AND prfloat(x) BE
{ writef("  %c", x>=0 -> '+', '-')
  writef(" %8b", (x>>23) & #xFF)
  writef(" %23b", x & #x7FFFFF)
}




