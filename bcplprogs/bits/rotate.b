GET "libhdr"

LET start() = VALOF
$( LET v = VEC 31

   FOR i = 0 TO 31 DO v!i := (randno(100000)<<16) + randno(100000)

   newline()

   prbitmap(v)
   FOR i = 1 TO 10001 DO rotate(v)
   prbitmap(v)

   RESULTIS 0
$)

AND rotate(v) BE
$( LET m1, m2 = #xFFFF0000, #x0000FFFF

   FOR p = v TO v+15 DO
   $( LET a, b = p!0, p!16
      p!0  := ((a&m2)<<16) + (b & m2)
      p!16 := ((b&m1)>>16) + (a & m1)
   $)
   m1, m2 := #xFF00FF00, #x00FF00FF
   FOR p = v TO v+7 FOR q = p TO p+31 BY 16 DO
   $( LET a, b = q!0, q!8
      q!0  := ((a&m2)<<8) + (b & m2)
      q!8  := ((b&m1)>>8) + (a & m1)
   $)

   m1, m2 := #xF0F0F0F0, #x0F0F0F0F
   FOR p = v TO v+3 FOR q = p TO p+31 BY 8 DO
   $( LET a, b = q!0, q!4
      q!0  := ((a&m2)<<4) + (b & m2)
      q!4  := ((b&m1)>>4) + (a & m1)
   $)

   FOR p = v TO v+28 BY 4 DO
   $( LET a = ((p!0 & #x33333333)<<2) + (p!2 & #x33333333)
      LET b = ((p!1 & #x33333333)<<2) + (p!3 & #x33333333)
      LET c =  (p!0 & #xCCCCCCCC) +    ((p!2 & #xCCCCCCCC)>>2)
      LET d =  (p!1 & #xCCCCCCCC) +    ((p!3 & #xCCCCCCCC)>>2)

      p!0 := ((a & #x55555555)<<1) + (b & #x55555555)
      p!1 :=  (a & #xAAAAAAAA) +    ((b & #xAAAAAAAA)>>1)
      p!2 := ((c & #x55555555)<<1) + (d & #x55555555)
      p!3 :=  (c & #xAAAAAAAA) +    ((d & #xAAAAAAAA)>>1)
   $)
$)

AND prbitmap(v) BE
$( FOR i = 0 TO 31 DO 
   $( LET w = v!i
      FOR j = 31 TO 0 BY -1 DO writef(" %c", (w>>j & 1) = 0 -> '-', '**')
      newline()
   $)
   newline()
$)

