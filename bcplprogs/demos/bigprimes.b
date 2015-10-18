SECTION "BIGPRIMES"
 
GET "libhdr"
 
GLOBAL $( count: ug  $)
 
LET start() = VALOF
$( LET n, k = 1000000000, 20
   LET argv = VEC 50

   IF rdargs("FROM,COUNT", argv, 50)=0 DO
   $( writes("Bad arguments for BIGPRIMES*n")
      RESULTIS 20
   $)

   UNLESS argv!0=0 DO n := str2numb(argv!0)
   UNLESS argv!1=0 DO k := str2numb(argv!1)

   writef("*n%n primes from %n are:*n", k, n)

   count := 0

   UNTIL count>=k DO
   $( IF isprime(n) DO out(n)
      n := n+1
   $)
 
   writes("*nend of output*n")

   RESULTIS 0
$)

AND isprime(n) = VALOF
$( LET d = 2
   $( IF d*d>n RESULTIS TRUE
      IF n REM d = 0 RESULTIS FALSE
      d := d+1
   $) REPEAT
$)
 
AND out(n) BE
$( IF count REM 5 = 0 DO newline()
   writef(" %i9", n)
   count := count + 1
$)
