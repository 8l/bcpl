SECTION "fridays"

GET "libhdr"

MANIFEST $( mon=0; sun=6; jan=0; feb=1; dec=11 $)

LET start() = VALOF
$( LET count       = TABLE 0, 0, 0, 0, 0, 0, 0
   LET daysinmonth = TABLE 31,  ?, 31, 30, 31, 30,
                           31, 31, 30, 31, 30, 31
   LET days = 0
      
   FOR year = 1973 TO 1973+399 DO
   $( daysinmonth!feb := febdays(year)
      FOR month = jan TO dec DO
      $( LET day13 = (days+12) REM 7
         count!day13 := count!day13 + 1
         days := days + daysinmonth!month
      $)
   $)
   FOR day = mon TO sun DO
     writef("%i3 %sdays*n",
            count!day,
            select(day,
                  "Mon","Tues","Wednes","Thurs","Fri","Sat","Sun")
           )
   RESULTIS 0
$)

AND febdays(year) = year REM 400 = 0 -> 29,
                    year REM 100 = 0 -> 28,
                    year REM 4   = 0 -> 29,
                    28

AND select(n, a0, a1, a2, a3, a4, a5, a6) = n!@a0


