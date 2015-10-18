GET "libhdr"

LET start() = VALOF
$( LET v = VEC 31

   FOR i = 0 TO 31 DO v!i := (randno(100000)<<16) + randno(100000)
//   FOR i = 0 TO 31 DO v!i := i | i<<10
   newline()
   prbitmap(v)
   transpose(v)
   prbitmap(v)

/*
   FOR i = 0 TO 31 DO t(i)
   t(#b11011111011111101111111011111111) 
   t(#b11001110011111001111110011111110) 
   t(#b10001100011110001111100011111100) 
   t(#b10001000010000001000000010000000) 
   t(#b01000100001000000100000001000000) 
   t(#b11111111111111111111111111111111) 
   t(#b01111111111111111111111111111110) 
   t(#b01111111111111110111111111111110) 
   t(#b01010101010101010101010101010101) 
   t(#b10101010101010101010101010101010)
*/
   RESULTIS 0
$)

AND regions(w) = w=0 -> 0, VALOF
$( LET bit = w & -w
   LET a = w + bit
   RESULTIS 1 + regions(a - (a & -a)) 
$)

AND t(w) BE writef("%x8  regions = %i2*n", w, regions(w))

AND transpose(v) BE
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
   m1, m2 := #xCCCCCCCC, #x33333333
   FOR p = v TO v+1 FOR q = p TO p+31 BY 4 DO
   $( LET a, b = q!0, q!2
      q!0  := ((a&m2)<<2) + (b & m2)
      q!2  := ((b&m1)>>2) + (a & m1)
   $)
   m1, m2 := #xAAAAAAAA, #x55555555
   FOR q = v TO v+31 BY 2 DO
   $( LET a, b = q!0, q!1
      q!0  := ((a&m2)<<1) + (b & m2)
      q!1  := ((b&m1)>>1) + (a & m1)
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

