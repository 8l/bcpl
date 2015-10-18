/*
Test simple floating point operations.
*/


GET "libhdr"

GLOBAL {
 testno:ug
 errors
}

LET start() = VALOF
{ LET a = 1.234
  AND b = #-1.234
  AND c = 0.0
  AND d = #-c
  AND e = FIX a
  AND f = FIX b
  AND g = FLOAT 1234
  AND h = #ABS a
  AND i = #ABS b
  AND j = a #* b #/ g
  AND k = a #+ b #- g
  AND l = #+ b

  testno := 0
  errors := 0

  IF a #<= a DO writef("a<=a*n")
  IF a #>= a DO writef("a>=a*n")
  IF a #>= a DO writef("a>=a*n")
  IF a #>= b DO writef("a>=b*n")
  IF c #= d  DO writef("c>=d*n")
  writef("e=%n f=%n*n", e, f)
  IF g #~= 1234.1 DO writef("g #~= 1234.1*n")
  IF g #< 1234.1 DO writef("g #< 1234.1*n")
  IF g #> 1233.9 DO writef("g #> 1233.9*n")

  t(1.234, #- b)                              // 1
  t(#- 0.0, #+ 0.0)                           // 2
  t(#ABS (#- 1.234), 1.234)                   // 3
  tb(FIX 12.34, 12)                           // 4
  tb(FIX (#- 12.34), -12)                     // 5
  t(FLOAT 123 #+ FLOAT 456, FLOAT 579)        // 6
  t(1.234 #* 2.0, 2.468)                      // 7
  t(1.5 #/ 2.0, 0.75)                         // 8
  t(1.234 #+ 2.0, 3.234)                      // 9 
  t(1.5 #- 2.0, #- 0.5)                       //10

  tb(1.234 #= 1.234, TRUE)                    //11
  tb(1.234 #= 1.235, FALSE)                   //12

  tb(1.234 #~= 1.234, FALSE)                  //13
  tb(1.234 #~= 1.235, TRUE)                   //14

  tb(1.234 #<= 1.233, FALSE)                  //15
  tb(1.234 #<= 1.234, TRUE)                   //16
  tb(1.234 #<= 1.235, TRUE)                   //17

  tb(1.234 #>= 1.233, TRUE)                   //18
  tb(1.234 #>= 1.234, TRUE)                   //19
  tb(1.234 #>= 1.235, FALSE)                  //20

  tb(1.234 #< 1.233, FALSE)                   //21
  tb(1.234 #< 1.234, FALSE)                   //22
  tb(1.234 #< 1.235, TRUE)                    //23

  tb(1.234 #> 1.233, TRUE)                    //24
  tb(1.234 #> 1.234, FALSE)                   //25
  tb(1.234 #> 1.234, FALSE)                   //26

  t(1.0, 1.0)                                 //27
  t(2.0, 2.0)                                 //28
  t(3.0, 3.0)                                 //29

  t(#- 1.0, #- 1.0)                           //30
  t(#- 2.0, #- 2.0)                           //31
  t(#- 3.0, #- 3.0)                           //32

  writef("*nEnd of floating point test, %n error%-%ps*n", errors)
  RESULTIS 0
}

AND t(x, y) BE
{ testno := testno+1

  writef("%i3: ", testno)
  prfloat(x)
  prfloat(y)
  TEST x #= y
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
