GET "libhdr"

LET start() BE
$( LET k = 0
   LET pch = VEC 255
   LET v = VEC 255

   FOR i = 0 TO 255 DO pch!i := ' '
   printable(pch, "ABCDEFGHIJKLMNOPQRSTUVWXYZ")
   printable(pch, "abcdefghijklmnopqrstuvwxyz")
   printable(pch, "0123456789")
   printable(pch, "!*"#$%&'()=-~^|\`@{[_+;**:}]<,>.?/")

   FOR i = 0 TO 255 DO v!i := 0

// selectinput(findinput("FROM"))

   writef("CHARHIST OUTPUT*N")

   $( LET ch = rdch()
      IF ch=endstreamch BREAK
      v!ch := v!ch + 1
   $) REPEAT

   FOR i = 0 TO 255 DO
   $( IF i REM 8 = 0 DO newline()
      IF i REM 64 = 0 DO newline()
      writef(" %I5/%C", v!i, pch!i)
   $)

   newline()
   writef("*N*NEND OF OUTPUT*N")
$)

AND printable(v, s) BE FOR i = 1 TO s%0 DO v!(s%i) := s%i

