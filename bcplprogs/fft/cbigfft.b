/*

This is a version of bigfft.b that uses scaled fixed point complex
arithmetic rather than modulo arithmetic.  It is perhaps useful for
applications involving digital sound.

Implemented by Martin Richards (c) January 2008

*/

GET "libhdr"

MANIFEST {
Scale = 1000     // All scaled values are of the form: dddd.ddd
//Round = Scale/2  // Used for rounding

//K = 16
//K = 12
//K = 10
K = 8
//K = 3
//K = 2

N       = 1<<K    // N = 2^K
upb     = N-1     // UPB of data vectors
}

STATIC {
 rdata=0      // real components
 idata=0      // imaginary components
 prupb = upb  // Upper bound for printing
 rw           // Table of re(w^k)
 iw           // Table of im(w^k)
 romega
 iomega
}

LET rwki(k,i) = VALOF
// Returns the real part of the (2^i)th power (i = 0..k)
// of the (2^k)th root of unity using scaled arithmetic
// with 9 digits after the decimal point.
{ LET t = TABLE
  1_000000000,                                  
  0_999999995, // cos(2Pi/65536) = re(w^1)      (2**16)th root of unity
  0_999999982, // cos(2Pi/32768) = re(w^2)      (2**15)th root of unity
  0_999999926, // cos(2Pi/16384) = re(w^4)      (2**14)th root of unity
  0_999999706, // cos(2Pi/ 8192) = re(w^8)      (2**13)th root of unity
  0_999998823, // cos(2Pi/ 4096) = re(w^16)     (2**12)th root of unity
  0_999995294, // cos(2Pi/ 2048) = re(w^32)     (2**11)th root of unity
  0_999981175, // cos(2Pi/ 1024) = re(w^64)     (2**10)th root of unity
  0_999924702, // cos(2Pi/  512) = re(w^128)    (2** 9)th root of unity
  0_999698819, // cos(2Pi/  256) = re(w^256)    (2** 8)th root of unity
  0_998795456, // cos(2Pi/  128) = re(w^512)    (2** 7)th root of unity
  0_995184727, // cos(2Pi/   64) = re(w^1024)   (2** 6)th root of unity
  0_980785280, // cos(2Pi/   32) = re(w^2048)   (2** 5)th root of unity
  0_923879533, // cos(2Pi/   16) = re(w^4096)   (2** 4)th root of unity
  0_707106782, // cos(2Pi/    8) = re(w^8192)   (2** 3)th root of unity
  0_000000000, // cos(2Pi/    4) = re(w^16384)  (2** 2)th root of unity
 -1_000000000, // cos(2Pi/    2) = re(w^32768)  (2** 1)th root of unity
  1_000000000  // cos(2Pi/    1) = re(w^65536)  (2** 0)th root of unity
  LET base = 17-k // k=16 => 0, k=15=>1, k=14=>2, etc 
  RESULTIS t!(base+i)
}

LET iwki(k, i) = VALOF
// Returns the imaginary part of the (2^i)th power
// of the (2^k)th root of unity using scaled arithmetic
// with 9 digits after the decimal point.
{ LET t = TABLE
  0_000000000,
  0_000095874, // sin(2Pi/65536) = im(w^1)      (2**16)th root of unity
  0_000191748, // sin(2Pi/32768) = im(w^2)      (2**15)th root of unity
  0_000383495, // sin(2Pi/16384) = im(w^4)      (2**14)th root of unity
  0_000766990, // sin(2Pi/ 8192) = im(w^8)      (2**13)th root of unity
  0_001533980, // sin(2Pi/ 4096) = im(w^16)     (2**12)th root of unity
  0_003067957, // sin(2Pi/ 2048) = im(w^32)     (2**11)th root of unity
  0_006135885, // sin(2Pi/ 1024) = im(w^64)     (2**10)th root of unity
  0_012271538, // sin(2Pi/  512) = im(w^128)    (2** 9)th root of unity
  0_024541228, // sin(2Pi/  256) = im(w^256)    (2** 8)th root of unity
  0_049067674, // sin(2Pi/  128) = im(w^512)    (2** 7)th root of unity
  0_098017140, // sin(2Pi/   64) = im(w^1024)   (2** 6)th root of unity
  0_195090322, // sin(2Pi/   32) = im(w^2048)   (2** 5)th root of unity
  0_382683432, // sin(2Pi/   16) = im(w^4096)   (2** 4)th root of unity
  0_707106782, // sin(2Pi/    8) = im(w^8192)   (2** 3)th root of unity
  1_000000000, // sin(2Pi/    4) = im(w^16384)  (2** 2)th root of unity
  0_000000000, // sin(2Pi/    2) = im(w^32768)  (2** 1)th root of unity
  0_000000000  // sin(2Pi/    1) = im(w^65536)  (2** 0)th root of unity
  LET base = 17-k // k=16 => 0, k=15=>1, k=14=>2, etc 
  RESULTIS t!(base+i)
}

AND wpower(k, n) = VALOF
// Returns re(w**n), result2=im(w**n) where w is the (2**k)th root of unity
// using scaled arithmetic with 9 digits after the decimal point.
{ LET res, res2 = 1_000000000, 0
  LET i = 0
  LET nn = n

  WHILE n DO
  { UNLESS (n&1)=0 DO
    { // Multiply by w^(2**i) where w = (2^k)th root of unity
      LET rwk, iwk = rwki(k,i), iwki(k,i) 
      LET rt, it = res, res2
      res  := muldiv(rt, rwk, 1_000000000) - muldiv(it, iwk, 1_000000000)
      res2 := muldiv(rt, iwk, 1_000000000) + muldiv(it, rwk, 1_000000000)
    }
    i, n := i+1, n>>1
  }

  result2 := res2
  RESULTIS res
}

LET start() = VALOF
{
   prupb := upb
   rdata := getvec(upb)
   idata := getvec(upb)

   rw := getvec(N)  // For a table of w^i, i=0..N
   iw := getvec(N)

   // Build a table of powers of the Nth root of unity where N=2^K.
   FOR i = 0 TO N DO
   { LET r2 = 0
     LET i2 = 0
     rw!i := wpower(K, i)
     iw!i := result2
     r2 := muldiv(rw!i, rw!i, 1_000000000)
     i2 := muldiv(iw!i, iw!i, 1_000000000)
     //writef("%i5 %16b: %12.9d*n", i, i, r2+i2)
     //IF ABS (r2+i2-1_000000000) >= 10 DO abort(1000)
   }

//   writef("*n The %nth root of unity is (%12.9d,%12.9d)*n*n", N, rw!1, iw!1)

//   FOR i = 0 TO N DO
//   { writef("%i5: (%12.9d, %12.9d) power %i3 => (%12.9d, %12.9d)*n",
//             i, rw!1, iw!1, i, rw!i, iw!i)
//   }
//abort(1000)

   FOR i = 0 TO upb DO rdata!i, idata!i := i, 0
   //rdata!1 := 1*Scale

   pr(rdata, idata, prupb)
// prints  -- Original data

//(  0.0000,  0.0000) (  1.0000,  0.0000) (  2.0000,  0.0000) (  3.0000,  0.0000) 
//(  4.0000,  0.0000) (  5.0000,  0.0000) (  6.0000,  0.0000) (  7.0000,  0.0000) 
//(  8.0000,  0.0000) (  9.0000,  0.0000) ( 10.0000,  0.0000) ( 11.0000,  0.0000) 
//( 12.0000,  0.0000) ( 13.0000,  0.0000) ( 14.0000,  0.0000) ( 15.0000,  0.0000) 

   fft(rdata, idata, FALSE)
   pr(rdata, idata, prupb)
// prints   -- Transformed data

//(120.0000,  0.0000) ( -8.0001,-40.2184) ( -8.0000,-19.3136) ( -8.0001,-11.9726) 
//( -8.0000, -8.0000) ( -7.9999, -5.3454) ( -8.0000, -3.3136) ( -7.9999, -1.5912) 
//( -8.0000,  0.0000) ( -7.9999,  1.5912) ( -8.0000,  3.3136) ( -7.9999,  5.3454) 
//( -8.0000,  8.0000) ( -8.0001, 11.9726) ( -8.0000, 19.3136) ( -8.0001, 40.2184) 

   fft(rdata, idata, TRUE)
   FOR i = 0 TO upb DO rdata!i, idata!i := rdata!i/N, idata!i/N
   pr(rdata, idata, prupb)
// prints  -- Restored data

//(  0.0000,  0.0000) (  1.0000,  0.0000) (  2.0000,  0.0000) (  3.0000,  0.0000) 
//(  4.0000,  0.0000) (  5.0000,  0.0000) (  6.0000,  0.0000) (  7.0000,  0.0000) 
//(  8.0000,  0.0000) (  8.9999,  0.0000) (  9.9999,  0.0000) ( 10.9999,  0.0000) 
//( 12.0000,  0.0000) ( 12.9999,  0.0000) ( 13.9999,  0.0000) ( 14.9998,  0.0000) 

   RESULTIS 0
}

AND fft(rv, iv, inverse) BE
{ LET rvn = rv+N
  LET ivn = iv+N
  LET n2  = N>>1

  // First do the perfect shuffle
  reorder(rv, iv, N)

  // Then do all the butterfly operations
  FOR s = 1 TO K DO
  { LET m  = 1<<s
    LET m2 = m>>1
    LET k = 0
    FOR j = 0 TO m2-1 DO
    { LET rp = rv+j
      LET ip = iv+j
      WHILE rp<rvn DO
      { LET rwk = rw!k
        LET iwk = inverse -> -iw!k, iw!k
        butterfly(rp, ip, rp+m2, ip+m2, rwk, iwk, k)
        rp, ip := rp+m, ip+m
      }
      k := k + (1<<(K-s))
    }
  }
}

AND butterfly(rp, ip, rq, iq, rwk, iwk, k) BE
{ LET ra, ia = !rp, !ip
  LET rb = mul(!rq, !iq, rwk, iwk)
  LET ib = result2
//writef("bfly: %i4 %i4 w^%n*n", rp-rdata, rq-rdata, k) 
  !rp, !ip := ra+rb, ia+ib
  !rq, !iq := ra-rb, ia-ib
}

AND reorder(rv, iv, n) BE
{ LET j = 0
  FOR i = 0 TO n-2 DO
  { LET k = n>>1
    // j is i with its bits is reverse order
    IF i<j DO
    { LET rt, it  = rv!j, iv!j
      rv!j, iv!j := rv!i, iv!i
      rv!i, iv!i :=  rt,   it
    }
    // k  =  100..00       10..0000..00
    // j  =  0xx..xx       11..10xx..xx
    // j' =  1xx..xx       00..01xx..xx
    // k' =  100..00       00..0100..00
    WHILE k<=j DO { j := j-k; k := k>>1 } //) "increment" j
    j := j+k                              //)
  }
}

AND pr(rv, iv, max) BE
{ FOR i = 0 TO max DO { writef("(%12.3d,%12.3d) ", rv!i, iv!i)
                        IF i REM 4 = 3 DO newline()
                      }
  newline()
}

AND mul(rx, ix, ry, iy) = VALOF
{ LET res =  muldiv(rx, ry, 1_000000000) - muldiv(ix, iy, 1_000000000)
  result2 := muldiv(rx, iy, 1_000000000) + muldiv(ix, ry, 1_000000000)
  RESULTIS res
}

