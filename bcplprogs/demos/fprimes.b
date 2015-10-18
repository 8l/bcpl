SECTION "FPRIMES"
 
GET "libhdr"
 
GLOBAL $( count: ug  $)
 
LET f(n) = n=0->2, n=1->1, f(n-1)+f(n-2)
LET isprime(n) = f(n) REM n = 1
 
LET start() = VALOF
$( FOR p = 2 TO 50 IF isprime(p) DO out(p)
 
   writes("*nend of output*n")
   RESULTIS 0
$)
 
AND out(n) BE
$( IF count REM 10 = 0 DO newline()
   writef(" %i3", n)
   count := count + 1
$)
