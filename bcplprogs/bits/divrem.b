/*
This code is to experiment possible implementations of 32 bit division
and remainder to run in ARM assembly language.

Implemented by Martin Richards (c) May 2013
*/

GET "libhdr"

LET start() = VALOF
{ try(minint, 1)
  FOR i = -2 TO +2 FOR j = -2 TO +2 DO
  { try(i, j)
    try(minint+i, j)
    try(maxint+i, j)
    try(minint+i, minint+j)
    try(maxint+i, minint+j)
    try(2_000_000_000+i, 1_000+j)
    try(minint, -1)
  }

  RESULTIS 0
}

AND try(x, y) BE
{ LET q = divrem(x, y)
  LET r = result2
  LET q1 = divrem2(x, y)
  LET r1= result2
  UNLESS q=q1 & r=r1 DO
  { writef("%8x / %x8 => %x8, remainder %x8 should be %x8, remainder %x8*n",
            x, y, q1, r1, q, r)
    writef("%8i / %i8 => %i8, remainder %i8 should be %i8, remainder %i8*n",
            x, y, q1, r1, q, r)
abort(1000)
  }
}

AND uge(x, y) = VALOF
{ LET res = uge1(x, y)
  //writef("uge(%32b, %32b) => %n*n", x, y, res)
  RESULTIS res
}

AND uge1(x, y) = VALOF
{ IF x<0 & y>0 RESULTIS TRUE
  IF x>0 & y<0 RESULTIS FALSE
  // x and y are both <=0 or both >=0
  RESULTIS x>=y
}

AND ult(x, y) = uge(y, x)

AND ule(x, y) = x=y | uge(y, x) -> TRUE, FALSE

AND divrem(r, d) = VALOF // Inefficient but correct
{ // Treat r and d as unsigned
  // result = r/d
  // result2 = r MOD d
  // If d=0 both results are -1
  LET q, b = 0, 1 // Quotient
  IF d=0 DO { result2 := -1; RESULTIS -1 }
  // d is non zero
  //writef("r=%32b d=%32b*n", r, d)
  WHILE d>0 & uge(r,d) DO d, b := d<<1, b<<1
  //writef("r=%32b d=%32b b=%32b*n", r, d, b)
  
  { IF uge(r, d) DO r, q := r-d, q+b
    //writef("r=%32b d=%32b b=%32b*n", r, d, b)
    d, b := d>>1, b>>1
  } REPEATWHILE b
  
  //writef("q=%32b r=%32b*n*n", q, r)
  result2 := r
  RESULTIS q
}

AND divrem1(r, d) = VALOF
{ // Treat n and d as unsigned
  // result = n/d
  // result2 = n MOD d
  IF d=0 DO { result2 := -1; RESULTIS -1 }
  result2 := r MOD d
  RESULTIS r / d
}

AND divrem2(r, d) = VALOF
{ // Treat r and d as unsigned
  // result = r/d
  // result2 = r MOD d
  LET q = 0
  IF d<=0 DO
  { IF d<0 TEST uge(r,d)
           THEN { result2 := r-d; RESULTIS 1 }
           ELSE { result2 := r;   RESULTIS 0 }
    result2 := -1 // Division by zero
    RESULTIS -1
  }
  // d is > 0, ie d = 0xxxxxx1xxxxxxxxxx
//writef("*ndivrem2: r=%32b d=%32b*n", r, d)
  IF ule(r, d<<00) GOTO b00 // J if r ule (d<<00)
  IF ule(r, d<<01) GOTO b01 // J if r ule (d<<01)
  IF ule(r, d<<02) GOTO b02 // J if r ule (d<<02)
  IF ule(r, d<<03) GOTO b03 // J if r ule (d<<03)
  IF ule(r, d<<04) GOTO b04 // J if r ule (d<<04)
  IF ule(r, d<<05) GOTO b05 // J if r ule (d<<05)
  IF ule(r, d<<06) GOTO b06 // J if r ule (d<<06)
  IF ule(r, d<<07) GOTO b07 // J if r ule (d<<07)
  IF ule(r, d<<08) GOTO b08 // J if r ule (d<<08)
  IF ule(r, d<<09) GOTO b09 // J if r ule (d<<09)
  IF ule(r, d<<10) GOTO b10 // J if r ule (d<<10)
  IF ule(r, d<<11) GOTO b11 // J if r ule (d<<11)
  IF ule(r, d<<12) GOTO b12 // J if r ule (d<<12)
  IF ule(r, d<<13) GOTO b13 // J if r ule (d<<13)
  IF ule(r, d<<14) GOTO b14 // J if r ule (d<<14)
  IF ule(r, d<<15) GOTO b15 // J if r ule (d<<15)
  IF ule(r, d<<16) GOTO b16 // J if r ule (d<<16)
  IF ule(r, d<<17) GOTO b17 // J if r ule (d<<17)
  IF ule(r, d<<18) GOTO b18 // J if r ule (d<<18)
  IF ule(r, d<<19) GOTO b19 // J if r ule (d<<19)
  IF ule(r, d<<20) GOTO b20 // J if r ule (d<<20)
  IF ule(r, d<<21) GOTO b21 // J if r ule (d<<21)
  IF ule(r, d<<22) GOTO b22 // J if r ule (d<<22)
  IF ule(r, d<<23) GOTO b23 // J if r ule (d<<23)
  IF ule(r, d<<24) GOTO b24 // J if r ule (d<<24)
  IF ule(r, d<<25) GOTO b25 // J if r ule (d<<25)
  IF ule(r, d<<26) GOTO b26 // J if r ule (d<<26)
  IF ule(r, d<<27) GOTO b27 // J if r ule (d<<27)
  IF ule(r, d<<28) GOTO b28 // J if r ule (d<<28)
  IF ule(r, d<<29) GOTO b29 // J if r ule (d<<29)
  IF ule(r, d<<30) GOTO b30 // J if r ule (d<<30)
  IF ule(r, d<<31) GOTO b31 // J if r ule (d<<31)

b31: pr(32, r, d, q)
     IF uge(r, d<<31) DO r, q := r-(d<<31), q+(1<<31)
b30: pr(31, r, d, q)
     IF uge(r, d<<30) DO r, q := r-(d<<30), q+(1<<30)
b29: pr(30, r, d, q)
     IF uge(r, d<<29) DO r, q := r-(d<<29), q+(1<<29)
b28: pr(29, r, d, q)
     IF uge(r, d<<28) DO r, q := r-(d<<28), q+(1<<28)
b27: pr(28, r, d, q)
     IF uge(r, d<<27) DO r, q := r-(d<<27), q+(1<<27)
b26: pr(27, r, d, q)
     IF uge(r, d<<26) DO r, q := r-(d<<26), q+(1<<26)
b25: pr(26, r, d, q)
     IF uge(r, d<<25) DO r, q := r-(d<<25), q+(1<<25)
b24: pr(25, r, d, q)
     IF uge(r, d<<24) DO r, q := r-(d<<24), q+(1<<24)
b23: pr(24, r, d, q)
     IF uge(r, d<<23) DO r, q := r-(d<<23), q+(1<<23)
b22: pr(23, r, d, q)
     IF uge(r, d<<22) DO r, q := r-(d<<22), q+(1<<22)
b21: pr(22, r, d, q)
     IF uge(r, d<<21) DO r, q := r-(d<<21), q+(1<<21)
b20: pr(21, r, d, q)
     IF uge(r, d<<20) DO r, q := r-(d<<20), q+(1<<20)
b19: pr(20, r, d, q)
     IF uge(r, d<<19) DO r, q := r-(d<<19), q+(1<<19)
b18: pr(19, r, d, q)
     IF uge(r, d<<18) DO r, q := r-(d<<18), q+(1<<18)
b17: pr(18, r, d, q)
     IF uge(r, d<<17) DO r, q := r-(d<<17), q+(1<<17)
b16: pr(17, r, d, q)
     IF uge(r, d<<16) DO r, q := r-(d<<16), q+(1<<16)
b15: pr(16, r, d, q)
     IF uge(r, d<<15) DO r, q := r-(d<<15), q+(1<<15)
b14: pr(15, r, d, q)
     IF uge(r, d<<14) DO r, q := r-(d<<14), q+(1<<14)
b13: pr(14, r, d, q)
     IF uge(r, d<<13) DO r, q := r-(d<<13), q+(1<<13)
b12: pr(13, r, d, q)
     IF uge(r, d<<12) DO r, q := r-(d<<12), q+(1<<12)
b11: pr(12, r, d, q)
     IF uge(r, d<<11) DO r, q := r-(d<<11), q+(1<<11)
b10: pr(11, r, d, q)
     IF uge(r, d<<10) DO r, q := r-(d<<10), q+(1<<10)
b09: pr(10, r, d, q)
     IF uge(r, d<<09) DO r, q := r-(d<<09), q+(1<<09)
b08: pr(09, r, d, q)
     IF uge(r, d<<08) DO r, q := r-(d<<08), q+(1<<08)
b07: pr(08, r, d, q)
     IF uge(r, d<<07) DO r, q := r-(d<<07), q+(1<<07)
b06: pr(07, r, d, q)
     IF uge(r, d<<06) DO r, q := r-(d<<06), q+(1<<06)
b05: pr(06, r, d, q)
     IF uge(r, d<<05) DO r, q := r-(d<<05), q+(1<<05)
b04: pr(05, r, d, q)
     IF uge(r, d<<04) DO r, q := r-(d<<04), q+(1<<04)
b03: pr(04, r, d, q)
     IF uge(r, d<<03) DO r, q := r-(d<<03), q+(1<<03)
b02: pr(03, r, d, q)
     IF uge(r, d<<02) DO r, q := r-(d<<02), q+(1<<02)
b01: pr(02, r, d, q)
     IF uge(r, d<<01) DO r, q := r-(d<<01), q+(1<<01)
b00: pr(01, r, d, q)
     IF uge(r, d)     DO r, q := r-d,       q+1
  result2 := r
  RESULTIS q
}

AND pr(sh, r, d, q) BE
{ //writef("%i2 r=%32b d=%32b q=%32b*n", sh, r, d, q)
}
