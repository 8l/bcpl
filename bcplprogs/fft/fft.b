GET "libhdr"

MANIFEST $(
modulus = #x10001  // 2**16 + 1

//omega   = #x00003  // omega**(2**16) = 1
//upb     = #x0FFFF

//omega   = #x0ADF3  // omega**(2**12) = 1
//upb     = #x00FFF

omega   = #x096ED  // omega**(2**10) = 1
upb     = #x003FF

//omega   = #x08000  // omega**(2**4) = 1
//upb     = #x0000F

//omega   = #x0FFF1  // omega**(2**3) = 1
//upb     = #x00007

N       = upb + 1    // N is a power of 2
MSB     = N>>1
LSB     = 1
$)

STATIC   $( v=0; w=0  $)

LET start() = VALOF
$( v := getvec(upb)
   w := getvec(upb)

   FOR i = 0 TO upb DO v!i := i
   pr(v, 15)
// prints  -- Original data
//     0     1     2     3     4     5     6     7
//     8     9    10    11    12    13    14    15

   w!0 := 1
   FOR i = 1 TO upb DO w!i := mul(w!(i-1), omega)  // roots of unity
   FOR i = 1 TO upb IF w!i=1 DO writef("omega****%n = 1*n", i)
   UNLESS mul(w!upb, omega)=1 DO writef("Bad omega*n")
   fftn(v)
   pr(v, 15)
// prints   -- Transformed data
// 65017 26645 38448 37467 30114 19936 15550 42679
// 39624 42461 43051 65322 18552 37123 60445 26804

   w!0 := 1
   FOR i = 1 TO upb DO w!i := ovr(w!(i-1), omega) // inverse roots of unity
   FOR i = 1 TO upb IF w!i=1 DO writef("omega****-%n = 1*n", i)
   UNLESS ovr(w!upb, omega)=1 DO writef("Bad omega*n")
   fftn(v)
   FOR i = 0 TO upb DO v!i := ovr(v!i, N)
   pr(v, 15)
// prints  -- 
//     0     1     2     3     4     5     6     7
//     8     9    10    11    12    13    14    15
   RESULTIS 0
$)

AND fftn(v) BE $( fft(N, v, 0, MSB)
                  reorder(v, v, MSB, LSB)
                $)

AND reorder(p, q, bp, bq) BE TEST bp=0
                             THEN IF p<q DO $( LET t = !p
                                               !p := !q
                                               !q := t
                                            $)
                             ELSE $( LET bp1, bq1 = bp>>1, bq<<1
                                     reorder(p+bp, q+bq, bp1, bq1)
                                     reorder(p,    q,    bp1, bq1)
                                  $)

AND fft(nn, i, pp, bit) BE $( LET n, p = nn>>1, pp>>1
//                            IF nn>256 DO writef("%x5  %x4*n", nn, i-v)
                              FOR j = i TO i+n-1 DO butterfly(j, j+n, w!p)
                              IF n=1 RETURN
                              fft(n,   i,     p, bit)
                              fft(n, i+n, p+bit, bit)
                           $)

AND butterfly(i, j, x) BE $( LET a, b = !i, mul(!j, x)
                             !i, !j := add(a, b), sub(a, b)
                          $)


AND pr(v, upb) BE
$( FOR i = 0 TO upb DO
   $( writef("%I5 ", v!i)
      IF i REM 8 = 7 DO newline()
   $)
   newline()
$)




AND dv(a, m, b, n) = a=1 -> m,
                     a=0 -> m-n,
                     a<b -> dv(a, m, b REM a, m*(b/a)+n),
                     dv(a REM b, m+n*(a/b), b, n)


AND inv(x) = dv(x, 1, modulus-x, 1)

AND add(x, y) = VALOF
$( LET a = x+y
   IF 0<=a<modulus RESULTIS a
   RESULTIS a-modulus
$)

AND sub(x, y) = add(x, neg(y))

AND neg(x)    = modulus-x

AND mul(x, y) = x=0 -> 0,
                (x&1)=0 -> mul(x>>1, add(y,y)),
                add(y, mul(x>>1, add(y,y)))

AND ovr(x, y) = mul(x, inv(y))








