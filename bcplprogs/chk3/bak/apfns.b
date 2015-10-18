// The apply functions on a single relation

// apnot(rel, i)         apply the NOT operator to argument i
// ignore(rel, i)        remove arg i assuming it is unconstrained

// apset1(rel, i)        apply  ai  =   1,   eliminate ai
// apset0(rel, i)        apply  ai  =   0,   eliminate ai
// apeq(rel, i, j)       apply  ai  =  aj,   eliminate aj
// apne(rel, i, j)       apply  ai  = ~aj,   eliminate aj

// apimppp(rel, i, j)    apply  ai ->  aj
// apimppn(rel, i, j)    apply  ai -> ~aj
// apimpnp(rel, i, j)    apply ~ai ->  aj
// apimpnn(rel, i, j)    apply ~ai -> ~aj

SECTION "applyfns"

GET "libhdr"
GET "chk3.h"



// Update rel bits corresponding to argument i being complemented
// eg: R11010110(x,y,z) => R01101101(x,y,~z)

// x 10101010
// y 11001100
// z 11110000

//   11010110 means xyz = 111 or 011 or 001 or 010 or 100
//   01101101 means xyz = 110 or 010 or 000 or 011 or 101
LET apnot(rel, i) BE
{ LET a = rel!r_w0
  LET sh, m1, m2 = ?, ?, ?

  //wrrel(rel, TRUE)
  writef("apnot: arg %n*n", i)

  SWITCHON i INTO
  { DEFAULT: writef("apnot error*n"); abort(999)
             RETURN

    CASE 2:  rel!r_w0 := a<<4 & #xF0 | a>>4 & #x0F; ENDCASE
    CASE 1:  rel!r_w0 := a<<2 & #xCC | a>>2 & #x33; ENDCASE
    CASE 0:  rel!r_w0 := a<<1 & #xAA | a>>1 & #x55; ENDCASE
  }
  wrrel(rel, TRUE)
}

AND testapnot() BE
  FOR rel = 0 TO #b11111111 DO
  { LET r1, r2 = 0, 0
    inittests()
    r1 := mkrel(rel, 1, 2, 3)
    r2 := mkrel(rel, 1, 2, 3)
    FOR v1 = 0 TO 1 FOR v2 = 0 TO 1 FOR v3 = 0 TO 1 DO
    { LET i = 0
      apnot(r2, 0)
      UNLESS evalrel(r1, 0, a, b, c)=evalrel(r2, 0, 1-a, b, c) GOTO bad
      r2!r_w0 := rel
      apnot(r2, 1)
      UNLESS evalrel(r1, 0, a, b, c)=evalrel(r2, 0, a, 1-b, c) GOTO bad
      r2!r_w0 := rel
      apnot(r2, 2)
      UNLESS evalrel(r1, 0, a, b, c)=evalrel(r2, 0, a, b, 1-c) GOTO bad
      LOOP
bad:  writef("ERROR: apnot(r2, %n)*n", i)
      wrrel(r1)
      wrrel(r2)
    }
}

// Apply:  Argument i is known to have value 1
// eg: R11010110(x,y,z) => R00001101(x,y,0)

// x 10101010
// y 11001100
// z 11110000

//   11010110 means xyz = 111 or 011 or 001 or 010 or 100
//   00001101 means xy  = 11  or 01  or 00
AND apset1(rel, i) BE
{ LET v = @rel!r_v0

  //wrrel(rel, TRUE)
  writef("apset1: arg %n*n", i)
  SWITCHON i INTO
  { DEFAULT: bug("Error in apset1: i=%n*n", i)
             RETURN
    CASE 2:  rel!r_w0 := rel!r_w0 & #xF0; ENDCASE
    CASE 1:  rel!r_w0 := rel!r_w0 & #xCC; ENDCASE
    CASE 0:  rel!r_w0 := rel!r_w0 & #xAA; ENDCASE
  }
  apnot(rel, i)
  rmref(rel, v!i)
  v!i := 1
  wrrel(rel, TRUE)
}

// Apply:  Argument i is known to have value 0
// eg: R11010110(x,y,z) => R00001101(x,y,0)

// x 10101010
// y 11001100
// z 11110000

//   11010110 means xyz = 111 or 011 or 001 or 010 or 100
//   00000110 means xy  =                      01  or 10
AND apset0(rel, i) BE
{ LET v = @rel!r_v0

  //wrrel(rel, TRUE)
  writef("apset0: arg %n*n", i)

  SWITCHON i INTO
  { DEFAULT: bug("Error in apset0: i=%n*n", i)
             RETURN
    CASE 2:  rel!r_w0 := rel!r_w0 & #x0F; ENDCASE
    CASE 1:  rel!r_w0 := rel!r_w0 & #x33; ENDCASE
    CASE 0:  rel!r_w0 := rel!r_w0 & #x55; ENDCASE
  }
  rmref(rel, v!i)
  v!i := 0
  wrrel(rel, TRUE)
}

// Apply:  ai = aj
// eg: R11010110(x,y,z) with y=z gives R00001110(x,y,0)

// x 10101010
// y 11001100
// z 11110000

//   11010110 means xyz = 111 or 011 or 001 or 010 or 100
//   00001110 means xy  = 11  or 01                or 10
AND apeq(rel, i, j) BE
{ LET v = @rel!r_v0

  //newline()
  //wrrel(rel, TRUE)
  writef("apeq: args %n %n*n", i, j)

  SWITCHON i*8+j INTO
  { DEFAULT:            ENDCASE  // Either i=j or an error

    CASE #21: CASE #12: rel!r_w0 := rel!r_w0 & #xC3; ENDCASE
    CASE #20: CASE #02: rel!r_w0 := rel!r_w0 & #xA5; ENDCASE
    CASE #10: CASE #01: rel!r_w0 := rel!r_w0 & #x99; ENDCASE
  }
  wrrel(rel, TRUE)
  ignorearg(rel, j)
}

// Apply:  ai ~= aj
// eg: R11010110(x,y,z) with y=~z gives R00000101(x,y,0)

// x 10101010
// y 11001100
// z 11110000

//   11010110 means xyz = 111 or 011 or 001 or 010 or 100
//   00000101 means xy  =               00  or 01
AND apne(rel, i, j) BE
{ LET v = @rel!r_v0

  //newline()
  //wrrel(rel, TRUE)
  writef("apne: args %n %n*n", i, j)

  SWITCHON i*8+j INTO
  { DEFAULT:            ENDCASE  // an error

    CASE #21: CASE #12: rel!r_w0 := rel!r_w0 & #x3C; ENDCASE
    CASE #20: CASE #02: rel!r_w0 := rel!r_w0 & #x5A; ENDCASE
    CASE #10: CASE #01: rel!r_w0 := rel!r_w0 & #x66; ENDCASE
  }
  wrrel(rel, TRUE)
  ignorearg(rel, j)
}

// Apply:  ai -> aj
// eg: R11010110(x,y,z) with y->z gives R11010010(x,y,z)

// x 10101010
// y 11001100
// z 11110000

//   11010110 means xyz = 111 or 011 or 001 or 010 or 100
//   11010010 means xyz = 111 or 011 or 001        or 100
AND apimppp(rel, i, j)  BE
{ LET v = @rel!r_v0

  //newline()
  //wrrel(rel, TRUE)
  writef("apimppp: args %n %n*n", i, j)

  SWITCHON i*8+j INTO
  { DEFAULT:  ENDCASE  // an error

    CASE #22:                              ENDCASE
    CASE #21: rel!r_w0 := rel!r_w0 & #xCF; ENDCASE
    CASE #20: rel!r_w0 := rel!r_w0 & #xAF; ENDCASE

    CASE #12: rel!r_w0 := rel!r_w0 & #xF3; ENDCASE
    CASE #11:                              ENDCASE
    CASE #10: rel!r_w0 := rel!r_w0 & #xBB; ENDCASE

    CASE #01: rel!r_w0 := rel!r_w0 & #xDD; ENDCASE
    CASE #00:                              ENDCASE
  }
  wrrel(rel, TRUE)
}

// Apply  ai -> ~aj
// eg: R11010110(x,y,z) with y->~z gives R00010110(x,y,z)

// x 10101010
// y 11001100
// z 11110000

//   11010110 means xyz = 111 or 011 or 001 or 010 or 100
//   00010110 means xyz =               001 or 010 or 100
AND apimppn(rel, i, j) BE
{ LET v = @rel!r_v0

  //newline()
  //wrrel(rel, TRUE)
  writef("apimppn: args %n %n*n", i, j)

  SWITCHON i*8+j INTO
  { DEFAULT:  ENDCASE  // an error

    CASE #22: rel!r_w0 := rel!r_w0 & #xF0; ENDCASE
    CASE #21: rel!r_w0 := rel!r_w0 & #x3F; ENDCASE
    CASE #20: rel!r_w0 := rel!r_w0 & #x5F; ENDCASE

    CASE #12: rel!r_w0 := rel!r_w0 & #x3F; ENDCASE
    CASE #11: rel!r_w0 := rel!r_w0 & #xCC; ENDCASE
    CASE #10: rel!r_w0 := rel!r_w0 & #x77; ENDCASE

    CASE #02: rel!r_w0 := rel!r_w0 & #x5F; ENDCASE
    CASE #01: rel!r_w0 := rel!r_w0 & #x77; ENDCASE
    CASE #00: rel!r_w0 := rel!r_w0 & #xAA; ENDCASE
  }
  wrrel(rel, TRUE)
}


// Apply ~ai -> aj
// eg: R11010110(x,y,z) with ~y->z gives R11010010(x,y,z)

// x 10101010
// y 11001100
// z 11110000

//   11010110 means xyz = 111 or 011 or 001 or 010 or 100
//   11010010 means xyz = 111 or 011 or 001        or 100
AND apimpnp(rel, i, j) BE
{ LET v = @rel!r_v0

  //newline()
  //wrrel(rel, TRUE)
  writef("apimpnp: args %n %n*n", i, j)

  SWITCHON i*8+j INTO
  { DEFAULT:  ENDCASE  // an error

    CASE #22: rel!r_w0 := rel!r_w0 & #x0F; ENDCASE
    CASE #21: rel!r_w0 := rel!r_w0 & #xFC; ENDCASE
    CASE #20: rel!r_w0 := rel!r_w0 & #xFA; ENDCASE

    CASE #12: rel!r_w0 := rel!r_w0 & #xFC; ENDCASE
    CASE #11: rel!r_w0 := rel!r_w0 & #x33; ENDCASE
    CASE #10: rel!r_w0 := rel!r_w0 & #xEE; ENDCASE

    CASE #02: rel!r_w0 := rel!r_w0 & #xFA; ENDCASE
    CASE #01: rel!r_w0 := rel!r_w0 & #xEE; ENDCASE
    CASE #00: rel!r_w0 := rel!r_w0 & #x55; ENDCASE
  }
  wrrel(rel, TRUE)
}


// Apply: ~ai -> ~aj
// eg: R11010110(x,y,z) with ~y->~z gives R11010010(x,y,z)

// x 10101010
// y 11001100
// z 11110000

//   11010110 means xyz = 111 or 011 or 001 or 010 or 100
//   11000110 means xyz = 111 or 011        or 010 or 100
AND apimpnn(rel, i, j) BE apimppp(rel, j, i)




