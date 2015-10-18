GET "libhdr"
 
GLOBAL $( sum:200; term:201; tab:202; digcount:203 $)
 
MANIFEST $( digits=2000; upb=(digits+5)/4 $)

LET start() = VALOF
$( LET n  = 1
   LET v1 = VEC 9
   AND v2 = VEC upb
   AND v3 = VEC upb
 
   tab, sum, term := v1, v2, v3
 
   settok(sum,  1)
   settok(term, 1)
 
   UNTIL iszero(term) DO $( add(sum, term)
                            n := n + 1
                            divbyk(term, n)
                         $)
 
   writes("*ne = *n")
   print(sum)
    
   writes("*nDigit counts*n")
   FOR i = 0 TO 9 DO writef("%n:%i3  ", i, tab!i)
   newline()
   RESULTIS 0
$)
 
AND settok(v, k) BE $( v!0 := k
                       FOR i = 1 TO upb DO v!i := 0
                    $)
 
AND add(a, b) BE $( LET c = 0
                    FOR i = upb TO 0 BY -1 DO $( LET d = c + a!i + b!i
                                                 a!i := d REM 10000
                                                 c   := d  /  10000
                                              $)
                 $)
 
AND divbyk(v, k) BE $( LET c = 0
                       FOR i = 0 TO upb DO $( LET d = c*10000 + v!i
                                              v!i := d  /  k
                                              c   := d REM k
                                           $)
                    $)
 
AND iszero(v) = VALOF
$( FOR i = upb TO 0 BY -1 UNLESS v!i=0 RESULTIS FALSE
   RESULTIS TRUE
$)
 
AND print(v) BE
$( FOR i = 0 TO 9 DO tab!i := 0
   digcount := 0
   writef(" %I4.", v!0)
   FOR i = 1 TO upb DO $( IF i REM 15 = 0 DO writes("*n ")
                          wrpn(v!i, 4)
                          wrch('*s')
                       $)
   newline()
$)
 
AND wrpn(n, d) BE $( IF d>1 DO wrpn(n/10, d-1)
                     IF digcount>=digits RETURN
                     n := n REM 10
                     tab!n := tab!n + 1
                     wrch(n+'0')
                     digcount := digcount+1
                  $)


