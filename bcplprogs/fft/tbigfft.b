/*
This is a tracing version of bigfft.b
*/

GET "libhdr"

MANIFEST {
modulus = #x10001  // 2**16 + 1

$$ln4  // Set condition compilation flag to select data size
//$$walsh

$<ln16 omega = #x00003; ln = 16 $>ln16  // omega**(2**16) = 1
$<ln12 omega = #x0ADF3; ln = 12 $>ln12  // omega**(2**12) = 1
$<ln10 omega = #x096ED; ln = 10 $>ln10  // omega**(2**10) = 1
$<ln4  omega = #x08000; ln = 4  $>ln4   // omega**(2**4)  = 1
$<ln3  omega = #x0FFF1; ln = 3  $>ln3   // omega**(2**3)  = 1

$<walsh    omega=1           $>walsh    // The Walsh transform (permuted)

N       = 1<<ln                  // N is a power of 2
upb     = N-1
prupb   = upb&31                 // Upper bound for printing
}

STATIC   { data=0  }

LET start() = VALOF
{  writef("fft with N = %n and omega = %n modulus = %n*n*n",
                    N,         omega,     modulus)

   data := getvec(upb)

   UNLESS omega=1 DO   // Unless doing Walsh tranform
     check(omega, N)   //   check that omega and N are consistent

   FOR i = 0 TO upb DO data!i := i// MOD 256
   //pr(data, prupb)
// prints  -- Original data
//     0     1     2     3     4     5     6     7

   fft(data, ln, omega)
//RESULTIS 0
   pr(data, prupb)
// prints   -- Transformed data
// 65017 26645 38448 37467 30114 19936 15550 42679

   fft(data, ln, ovr(1,omega))
   FOR i = 0 TO upb DO data!i := ovr(data!i, N)
   pr(data, prupb)
// prints  -- Restored data
//     0     1     2     3     4     5     6     7
   RESULTIS 0
}

AND fft(v, ln, w) BE  // ln = log2 n    w = nth root of unity
{ LET n  = 1<<ln
  LET vn = v+n
  LET n2 = n>>1

  // First do the perfect shuffle
  reorder(v, n)

  // Then do all the butterfly operations
  FOR s = 1 TO ln DO
  { LET m  = 1<<s
    LET m2 = m>>1
    LET k = 0
    FOR j = 0 TO m2-1 DO
    { LET p = v+j
      WHILE p<vn DO { butterfly(p, p+m2, w, k); p := p+m }
      k := k + (1<<(ln-s))
    }
  }
}

AND power(w, n) = n=0 -> 1,
                  (n&1)=0 -> power(mul(w, w), n>>1),
                             mul(power(mul(w, w), n>>1), w)

AND butterfly(p, q, w, k) BE { LET wk = power(w, k)
                               LET a, b = !p, mul(!q, wk)
                               !p, !q := add(a, b), sub(a, b)
writef("bfly: %i4 %i4 w^%n=%x8 w=%x8*n",
 p-data, q-data, k, wk, w)
                           }

AND reorder(v, n) BE
{ LET j = 0
  FOR i = 0 TO n-2 DO
  { LET k = n>>1
    // j is i with its bits is reverse order
    IF i<j DO
    { LET t = v!j; v!j := v!i; v!i := t
      writef("swap: %i4 %i4*n", i, j)
    }
    // k  =  100..00       10..0000..00
    // j  =  0xx..xx       11..10xx..xx
    // j' =  1xx..xx       00..01xx..xx
    // k' =  100..00       00..0100..00
    WHILE k<=j DO { j := j-k; k := k>>1 } //) "increment" j
    j := j+k                              //)
  }
}

AND check(w, n) BE
{ // Check that w is a principal nth root of unity
  LET x = 1
  FOR i = 1 TO n-1 DO { x := mul(x, w)
                        IF x=1 DO writef("omega****%n = 1*n", i)
                      }
  UNLESS mul(x, w)=1 DO
  { writef("Bad omega**%n should be  1*n", n)
    writef("Bad omega = %x8*n", omega)
  }
}

AND pr(v, max) BE
{ FOR i = 0 TO max DO { writef("%I5 ", v!i)
                        IF i REM 8 = 7 DO newline()
                      }
  newline()
}

AND dv(a, m, b, n) = a=1 -> m,
                     a=0 -> m-n,
                     a<b -> dv(a, m, b REM a, m*(b/a)+n),
                     dv(a REM b, m+n*(a/b), b, n)


AND inv(x) = dv(x, 1, modulus-x, 1)

AND add(x, y) = VALOF
{ LET a = x+y
  IF a<modulus RESULTIS a
  RESULTIS a-modulus
}

AND sub(x, y) = add(x, neg(y))

AND neg(x)    = modulus-x

AND mul(x, y) = x=0 -> 0,
                (x&1)=0 -> mul(x>>1, add(y,y)),
                add(y, mul(x>>1, add(y,y)))

AND ovr(x, y) = mul(x, inv(y))
