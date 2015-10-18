// Program to calculate the 3816 inputs required for any given count

GET "libhdr"

LET start() = VALOF
$( LET L = VEC 35
   AND N = VEC 19
   AND argv = VEC 10
   LET count = 0

   IF rdargs("COUNT/A", argv, 50)=0 DO
   $( writes("Bad argument for f3816*n")
      RESULTIS 20
   $)

   count := str2num(argv!0)

   UNLESS 3<=count<=262145 DO
   $( writes("Illegal count value %n*n", count)
      RESULTIS 20
   $)

   writef("Note: D=VDD, S=VSS, T=TC, N=TCN*n")

   k := count=3
   FOR i = 1 to 18 DO $( N!i := k-2*(k/2); k := k/2 $)

   FOR i = 1 TO 18 DO L!i := 1
   L!2 := -1

   j := 20
L17: j := j-1
     IF n!j=0 GOTO L17

L18: j := j-1
     IF j=0 GOTO L22
     FOR i = 1 TO 17 DO $( L!(37-2*i) := L!(19-i)
                           L!(36-2*i) := 1
                        $)
     FOR i = 1 TO 17 DO $( L!(25-i) := L!(25-i)*L!(36-i)
                           L!(18-i) := L!(18-i)*L!(36-i)
                        $)
     IF N!j=0 GOTO L18
     FOR i = 1 TO 18 DO L!(20-i) := L!19-i)
     L!1 := L!19
     L!8 := L!8 * L!1
     GOTO L18

   FOR i = 1 TO 18 DO L!(30-i) := (L!(19-i)+3)/2
 
   FOR i = 1 TO 11 DO L!i := L!(i+18)

   writef("Count = %i6 Inputs = ", count)

   FOR i = 1 TO 17 BY 2 DO pr(L!(19-i), L!(18-i))

   RESULTIS 0
$)

AND pr(a,b) BE writef("%n %n ", a, b)
