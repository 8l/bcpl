/* This is a BCPL implementation of the Fast Walsh transform
using arithmetic modulo 2**16+1

(c) Martin Richards -- Jan 2000

For N=8 the transformation is:

v' = W x v, where

W  = [1  1  1  1  1  1  1  1]
     [1  1  1  1 -1 -1 -1 -1]
     [1  1 -1 -1  1  1 -1 -1]
     [1  1 -1 -1 -1 -1  1  1]
     [1 -1  1 -1  1 -1  1 -1]
     [1 -1  1 -1 -1  1 -1  1]
     [1 -1 -1  1  1 -1 -1  1]
     [1 -1 -1  1 -1  1  1 -1]

Note that

W x W = [8  0  0  0  0  0  0  0]
        [0  8  0  0  0  0  0  0]
        [0  0  8  0  0  0  0  0]
        [0  0  0  8  0  0  0  0]
        [0  0  0  0  8  0  0  0]
        [0  0  0  0  0  8  0  0]
        [0  0  0  0  0  0  8  0]
        [0  0  0  0  0  0  0  8]

So

v = (W x W x v) / 8

The program does the transformation with N=1024
*/

GET "libhdr"

MANIFEST {
modulus = #x10001  // 2**16 + 1

ln = 10            // Select data size

N       = 1<<ln    // N is the data size = 2**ln
upb     = N-1
}

STATIC   { data=0  }

LET start() = VALOF
{  writef("fwt with N = %n and modulus = %n*n*n",
                    N,         modulus)

   data := getvec(upb)

   FOR i = 0 TO upb DO data!i := i
   pr(data, 7)
// prints  -- Original data
//     0     1     2     3     4     5     6     7

   fwt(data, ln)
   pr(data, 7)
// prints   -- Transformed data
// 65017     4     2     0     1     0     0     0

   fwt(data, ln)
   FOR i = 0 TO upb DO data!i := ovr(data!i, N)
   pr(data, 7)
// prints  -- Restored data
//     0     1     2     3     4     5     6     7
   RESULTIS 0
}

AND fwt(v, ln) BE  // ln = log2(n)
{ LET n = 1<<ln
  LET vn = v+n
  LET n2 = n>>1

  // First do the perfect shuffle
  reorder(v, n)

  // Then do all the butterfly operations
  FOR s = 1 TO ln DO
  { LET m = 1<<s
    LET m2 = m>>1
    FOR j = 0 TO m2-1 DO
    { LET p = v+j
      WHILE p<vn DO { butterfly(p, p+m2); p := p+m }
    }
  }
}

AND butterfly(p, q) BE { LET a, b = !p, !q
                         !p, !q := add(a, b), sub(a, b)
                       }

AND reorder(v, n) BE
{ LET j = 0
  FOR i = 0 TO n-2 DO
  { LET k = n>>1
    // j is i with its bits is reverse order
    IF i<j DO { LET t = v!j; v!j := v!i; v!i := t }
    // k  =  100..00       10..0000..00
    // j  =  0xx..xx       11..10xx..xx
    // j' =  1xx..xx       00..01xx..xx
    // k' =  100..00       00..0100..00
    WHILE k<=j DO { j := j-k; k := k>>1 } //) "increment" j
    j := j+k                              //)
  }
}

AND pr(v, max) BE
{ FOR i = 0 TO max DO { writef("%i5 ", v!i)
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


