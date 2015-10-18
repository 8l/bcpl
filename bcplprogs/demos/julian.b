GET "libhdr"

// This program calulates the modified Julian date
// for 00:00 on the given date.

// On 17 November 1858 it is 0
// 12 hours before the astronomers fundamental epoch
// (noon on 1 January 4713 BC (year=-4712)), it is -2400000
 
LET start() = VALOF
$( LET argv = VEC 50
   LET year, month, day = -4712, 1, 1

   IF rdargs("YEAR,MONTH,DAY", argv, 50) = 0
   $( writes("Bad arguments for julian*n")
      RESULTIS 20
   $)
   UNLESS argv!0=0 DO year  := str2numb(argv!0)
   UNLESS argv!1=0 DO month := str2numb(argv!1)
   UNLESS argv!2=0 DO day   := str2numb(argv!2)

   IF later(year, month, day, 58795, 2, 28) DO
   { writef("Unable to deal with such a large date*n")
     RESULTIS 0
   }

   writef("The Modified Julian date for %n/%n/%n is: %n*n",
           day, month, year, modifiedjulian(year, month, day))

   writef("It is a %s*n", dayname(year, month, day))
   RESULTIS 0
$)

AND modifiedjulian(year, month, day) = VALOF
{ LET b, c, d = 0, 0, 0
  IF 1<=month<=2 DO year, month := year-1, month+12
  IF later(year, month, day, 1582, 10+2, 14) DO
  { LET a = year / 100    // a = INT(year/100)
    IF year<0 DO a := a+1 // INT meant to round towards 0
    b := 2 - a + a/4
  }
  TEST year<=0
  THEN c := (36525*year - 75)/100  // INT(365.25*year - 0.75)
  ELSE c := (36525*year)/100       // INT(365.25*year)
  IF year<0 DO c := c+1            // INT meant to round towards 0
  d := 306*(month+1)/10            // d = INT(30.6*(month+1))
  RESULTIS b + c + d + day + (1720994 - 2400000)
}

AND later(y1, m1, d1, y2, m2, d2) =
  y1>y2 -> TRUE,

  y1<y2 -> FALSE,
  m1>m2 -> TRUE,
  m1<m2 -> FALSE,
  d1>d2 -> TRUE,
  FALSE

// dayname does not always yield the right value between
// 11 October 1582 and 14 September 1752, because of the change
// to the Gregorian calenda
AND dayname(year, month, day) = VALOF
{ LET d = (700000002 + modifiedjulian(year, month, day)) REM 7
  RESULTIS select(d, "Monday", "Tuesday", "Wednesday", "Thursday",
                     "Friday", "Saturday", "Sunday")
}

AND select(s, a, b, c, d, e, f, g) = s!(@a)

