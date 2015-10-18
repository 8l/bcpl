/*
****** UNDER DEVELOPMENT ***************

This defines the function negexp() that returns
random deviates from the exponential distribution with
a mean of 1.0. The result is in fixed point scaled
arithmetic with 1.0 represented by 1000000.

Based on the algorithm given on page 128 of Knuth, Art of 
Programming, Vol 2.

Implemented in BCPL by Martin Richards, (c) June 2000
*/

GET "libhdr"

GLOBAL {
  seed:ug; q; ln2; h1
}

MANIFEST { One = 1000000 }

LET  rndno() = VALOF {
  seed := 2147001325 * seed + 715136305
  RESULTIS seed & #x7fffffff
}

AND negexp() = VALOF // Exponential distribution mean 1.0
{ LET u = rndno()
  LET v, w = ?, ?
  LET j = 0

  { u := u<<1
// writef("j=%i2 u=%x8*n", j, u)
    IF u>=0 BREAK
    j := j+1
  } REPEAT

  IF u<q!1 RESULTIS j*ln2 + muldiv(One, u, maxint)

//writef("u >= ln2*n")

  v := rndno()
  FOR i = 2 TO 10 DO
  { LET w = rndno()
    IF v>=w DO v := w
// writef("i=%i2 u=%x8 v=%x8*n", i, u, v)
    IF u<q!i BREAK
  }
//abort(1111)
  RESULTIS muldiv(ln2, (j*One+muldiv(One, v, maxint)), One)  
}

AND start() = VALOF
{ seed := 12345
  q := TABLE 0,
             #x58b90bfb, // 0.693147181
             #x7778c9fa, // 0.933373688
             #x7e938c30, // 0.988877796
             #x7fceb6e7, // 0.998495925
             #x7ffa67e6, // 0.999829281
             #x7fff740b, // 0.999983316
             #x7ffff3fe, // 0.999998569
             #x7fffff14, // 0.999999891
             #x7fffffee, // 0.999999992
             #x7ffffffd  // 1.000000000

  ln2 := muldiv(One, #x58b90bfb, maxint) // ln 2.0
 
  h1 := getvec(1000)
  FOR i = 0 TO 1000 DO h1!i := 0

  FOR i = 1 TO 1000000 DO
  { LET p = negexp()/10000
    IF p<0 DO p := 0
    IF p>999 DO p := 999
// writef("p=%i5*n", p)
    h1!p := h1!p + 1
  }

  FOR i = 0 TO 999 DO
  { IF i REM 10 = 0 DO writef("*n%i4: ", i)
    writef(" %i5", h1!i)
  }
  newline()

  FOR i = 1 TO 200 DO
  { prnum(negexp(), 15, 6)
    IF i REM 5 = 0 DO newline()
  }

  freevec(h1)
  RESULTIS 0
}

// Print in width w, f digits after decimal point
// x is scales so that 1.0 is 1000000 (One)
AND prnum(x, w, f) BE
{ LET px = ABS x
  IF f<0 DO f := 0
  IF f>6 DO f := 6
  IF f<6 DO
  { LET r = 5
    FOR i = f TO 4 DO r := r*10
    px := px + r  // Round up, if necessary
  }
  wripart(px/One, w-f-1, x<0) // output the integer part

  FOR i = f TO 5 DO px := px/10

  wrch('.')                   // output the fractional part
  wrfpart(px, f)
}

AND wripart(x, w, neg) BE
{ //writef("wripart: %i9 %n  %n*n", x, w, neg)
  IF x < 10 DO
  { IF neg DO w := w-1
    FOR i = 2 TO w DO wrch(' ')
    IF neg DO wrch('-')
    wrch(x+'0')
    RETURN
  }
  wripart(x/10, w-1, neg)
  wrch(x REM 10 + '0')
}

AND wrfpart(x,n) BE
{ IF n>1 DO wrfpart(x/10, n-1)
  IF n>0 DO wrch(x REM 10 + '0')
}

