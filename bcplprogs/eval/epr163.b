GET "libhdr"

MANIFEST $( upb = 12; upb1 = upb+1  $)

LET start() = VALOF
$( LET pi = VEC upb
   AND root163 = VEC upb
   AND x = VEC upb
   AND ex = VEC upb
   LET exponent = 0
   numfromstr(pi, upb,
     "3.14159265358979323846264338327950288419716939937510582097494459230")
   writef("Pi is :-*n")
   print(pi, 0)
   sqrt163(root163)
   writef("Root 163 is :-*n")
   print(root163, 0)
   mult(x, pi, root163)
   writef("Pi x Root 163 is :-*n")
   print(x, 0)
   divbyk(x, 1024)
   exp(ex, x)
   FOR i = 1 TO 10 DO $( exponent := 2*exponent
                         mult(ex, ex, ex)
                         IF ex!0>10000 DO $( divbyk(ex, 10000)
                                             exponent := exponent + 1
                                          $)
                      $)
   writef("*ne to the Pi root 163 is :-*n")
   print(ex, exponent)
   RESULTIS 0
$)

AND numfromstr(v, upb, s) BE
$( LET p, k, val = 0, 0, k
   FOR i = 1 TO s%0 DO
   $( LET ch = s%i
      IF '0'<=ch<='9' DO val, k := 10*val + ch - '0', k+1
      IF ch='.' | k=4 DO $( IF p<=upb DO v!p := val
                            p, k, val := p+1, 0, 0
                         $)
   $)
   UNTIL k=4 DO val, k := 10*val, k+1
   IF p<=upb DO v!p := val
   UNTIL p>=upb DO $( p := p+1; v!p := 0  $)
$)

AND sqrt163(x) BE
$( LET w    = VEC upb
   AND eps  = VEC upb
   AND n163 = VEC upb
   numfromstr(x,    upb,  "13.")
   numfromstr(n163, upb, "163.")
   $( mult(w, x, x)
      TEST w!0>=163 THEN $( sub(eps, w, n163)
                            divbyk(eps, 24)
                            sub(x, x, eps)
                         $)
                    ELSE $( sub(eps, n163, w)
                            divbyk(eps, 24)
                            add(x, x, eps)
                         $)
   $) REPEATUNTIL iszero(eps)
$)

AND mult(x, y, z) BE
$( LET res = VEC upb1
   numfromstr(res, upb1, "0.")
   res!upb1 := 5000  // for rounding
   FOR i = 0 TO upb UNLESS y!i=0 DO
     FOR j = 0 TO upb1-i DO $( LET p = i + j
                               LET carry = y!i*z!j 
                               UNTIL carry=0 DO
                               $( LET w = res!p + carry
                                  IF p=0 DO $( res!0 := w; BREAK $)
                                  res!p, carry := w REM 10000, w/10000
                                  p := p-1
                               $)
                            $)
   FOR i = 0 TO upb DO x!i := res!i
$)

AND exp(ex, x) BE
$( LET n = 0
   LET term = VEC upb
   numfromstr(term, upb, "1.")
   numfromstr(ex,   upb, "0.")
   UNTIL iszero(term) DO $( add(ex, ex, term)
                            mult(term, term, x)
                            n := n+1
                            divbyk(term, n)
                         $)
$)

AND add(x, y, z) BE $( LET c = 0
                       FOR i = upb TO 0 BY -1 DO $( LET d = c + y!i + z!i
                                                    x!i := d REM 10000
                                                    c   := d  /  10000
                                                 $)
                    $)
 
AND sub(x, y, z) BE $( LET borrow = 0
                       FOR i = upb TO 1 BY -1 DO
                       $( LET d = y!i - borrow - z!i
                          borrow := 0
                          UNTIL d>=0 DO borrow, d := borrow+1, d+10000
                          x!i := d
                       $)
                       x!0 := y!0 - borrow - z!0
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
 
AND print(v, exponent) BE
$( writef("%I4", v!0)
   FOR i = 1 TO upb DO $( wrch(exponent=0 -> '.', '*s')
                          exponent := exponent - 1
                          IF i REM 15 = 0 DO newline()
                          wrpn(v!i, 4)
                       $)
   newline()
$)
 
AND wrpn(n, d) BE $( IF d>1 DO wrpn(n/10, d-1)
                     wrch(n REM 10 +'0')
                  $)


