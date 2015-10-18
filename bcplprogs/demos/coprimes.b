SECTION "coprimes"

GET "libhdr"

MANIFEST $( upb = 4000 $)

LET prime2() = VALOF
$( LET n = 2   
   $( LET a, b =1, 3 REM n      
      FOR i = 2 TO n DO 
      $( LET c = (a+b) REM n                           
         a := b                           
         b := c                        
      $)      
      IF a=1 DO cowait(n)      
      n := n+1   
   $) REPEAT
$)

AND prime1() = VALOF
$( LET isprime = getvec(upb)   
   FOR i = 2 TO upb DO isprime!i := TRUE  // Until proved otherwise.    
   FOR p = 2 TO upb IF isprime!p DO   
   $( LET i = p*p      
      UNTIL i>upb DO $( isprime!i := FALSE; i := i + p $)      
      cowait(p)   
   $)   
   freevec(isprime)   
   RESULTIS 0
$)

LET start() BE
$( LET P1 = createco(prime1, 100)   
   LET P2 = createco(prime2, 100)   
   LET x1, x2, val, count = 0, 0, 0, 0   
   $( IF x1=val DO x1 := callco(P1)      
      IF x2=val DO x2 := callco(P2)      
      val := x1<x2 -> x1, x2      
      IF val=0 | intflag() BREAK      
      IF count REM 10 = 0 DO newline()      
      writef(" %i4%c", val, val<x1 -> 'F', val<x2 -> 'P', ' ')      
      UNLESS x1=x2 DO wrch(7)      
      count := count+1   
   $) REPEAT   
   newline()   
   deleteco(P1)   
   deleteco(P2)
$)

