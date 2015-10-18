// UNDER DEVELOPMENT

GET "libhdr"

LET start() = VALOF
{ LET v = VEC 100
  FOR i = 0 TO 100 DO v!i := -1

  writes("Testing an integer square routine function*n")

  FOR n = 0 TO maxint DO
  { LET count = instrcount(sqrt, n)
//    IF 0<=count<=1000 & v!count<0 DO
    { writef("sqrt(%iB) = %i6   taking %i3 instructions*n", n, result2, count)
      v!count := n
abort(1000)
    }
IF n REM 10_000_000 = 0 DO writef("%iB*n", n)
  }
  RESULTIS 0

  
  FOR n = maxint TO 0 BY -1 DO
//  FOR n = maxint TO maxint DO
  { LET r = sqrt(n)
    LET t = r*r - n
    LET ch = ' '
    IF t>0                DO ch := '>'  // r too large
    IF t + r + r + 1 <= 0 DO ch := '<'  // r too small
    //IF n REM 8 = 0 DO newline()
IF n REM 10_000_000 = 0 DO writef("%iB*n", n)
//    writef("%i5:%i3%c ", n, r, ch)
    writef("  => %i3%c ", r, ch)
UNLESS ch=' ' DO
 { writef("%i5:%i3%c*n", n, r, ch); abort(1111) }
  }
  newline()
  abort(1000)
  RESULTIS 0
}

/*
AND sqrt(x) = VALOF
{ LET xn = x>>30 -> x>>15,
           x>>16 -> x>>6,
           x>>8  -> x>>4,
           x | 4
  IF x <=0 RESULTIS 0

writef("*nx=%iB  xn = %i7", x, xn) 
  xn := (xn + 1 + x/xn)>>1
writef(" %n", xn) 
  xn := (xn + 1 + x/xn)>>1
writef(" %n", xn) 
  xn := (xn + 1 + x/xn)>>1
//writef(" %n", xn) 
//  xn := (xn + 1 + x/xn)>>1
//writef(" %n", xn) 
//  xn := (xn + 1 + x/xn)>>1
//writef(" %n", xn) 
//  xn := (xn + 1 + x/xn)>>1
//writef(" %n", xn) 
//  xn := (xn + 1 + x/xn)>>1
//writef(" %n", xn) 
//  xn := (xn + 1 + x/xn)>>1
writef(" %n", xn) 

  RESULTIS (xn+1)*(xn+1) - x > 0 -> xn-1, xn
}
*/

AND sqrt(x) = VALOF
{ LET res = 0
  LET r =    #x8000


IF res+bit squared < x  s := (res+bit) ** 2 = s + 2*res*bit + bit**2

  IF r*r-x<=0 DO res := r
  r := res + #x4000
  IF r*r-x<=0 DO res := r
  r := res + #x2000
  IF r*r-x<=0 DO res := r
  r := res + #x1000
  IF r*r-x<=0 DO res := r
  r := res + #x0800
  IF r*r-x<=0 DO res := r
  r := res + #x0400
  IF r*r-x<=0 DO res := r
  r := res + #x0200
  IF r*r-x<=0 DO res := r
  r := res + #x0100
  IF r*r-x<=0 DO res := r
  r := res + #x0080
  IF r*r-x<=0 DO res := r
  r := res + #x0040
  IF r*r-x<=0 DO res := r
  r := res + #x0020
  IF r*r-x<=0 DO res := r
  r := res + #x0010
  IF r*r-x<=0 DO res := r
  r := res + #x0008
  IF r*r-x<=0 DO res := r
  r := res + #x0004
  IF r*r-x<=0 DO res := r
  r := res + #x0002
  IF r*r-x<=0 DO res := r
  r := res + #x0001
  IF r*r-x<=0 DO res := r

writef("*nx=%iB  res = %i7", x, res) 
  res := (res + 1 + x/res)>>1
writef(" %n", res) 
  res := (res + 1 + x/res)>>1
writef(" %n", res) 
  res := (res + 1 + x/res)>>1
//writef(" %n", res) 
//  res := (res + 1 + x/res)>>1
//writef(" %n", res) 
//  res := (res + 1 + x/res)>>1
//writef(" %n", res) 
//  res := (res + 1 + x/res)>>1
//writef(" %n", res) 
//  res := (res + 1 + x/res)>>1
//writef(" %n", res) 
//  res := (res + 1 + x/res)>>1
writef(" %n", res) 

  RESULTIS (res+1)*(res+1) - x > 0 -> res-1, res
}




