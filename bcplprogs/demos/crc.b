SECTION "CRC"

GET "libhdr"

LET start() BE
$( LET w = 1                   // xn
   LET d = #b1101000000001000  // 1 + x + x3 + x12 + x16

   selectoutput(findoutput("res"))

   FOR i = 1 TO (1<<16)+64 DO
   $( wrch('0'+(w&1))
      IF i REM 64 = 0 DO newline()
      w := (w&1)=0 -> w>>1, w>>1 NEQV d
   $)

   writef("*nend of output*n")
   endwrite()
$)

