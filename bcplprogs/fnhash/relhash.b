/*
A boolean relation over 6 boolean variables can be thought of
a boolean function of 6 variables and can be represented
by a 64 bit pattern.
This program experiments with the hashing of boolean functions
represented this way.

Implemented in BCPL by Martin Richards (c) April 2001
*/

GET "libhdr"

MANIFEST
{ MaxVar=5000
  Upb=50000
  Modulus = 100000 //257
}

// Modulo Arithmetic Package

LET add(x, y) = VALOF
{ LET a = x+y
  IF 0<=a<Modulus RESULTIS a
  RESULTIS a-Modulus
}

AND sub(x, y) = add(x, neg(y))

AND neg(x)    = Modulus-x

AND mul(x, y) = x=0 -> 0,
                (x&1)=0 -> mul(x>>1, add(y,y)),
                add(y, mul(x>>1, add(y,y)))


// Main Program

LET start() = VALOF
{ LET argv = VEC 50
  LET a, b, c, d, e, f = 2, 3, 4, 5, 6, 7
  UNLESS rdargs("", argv, 50) DO
  { writef("Bad arguments for relhash*n")
    RESULTIS 20
  }
  writef("relhash entered*n")

  try(0, #b10110111, 0, 0, 0, 0, 0, 0)
  try(0, #b10110111, 0, 0, 0, 0, 0, 1)
  try(0, #b10110111, 0, 0, 0, 0, 1, 0)
  try(0, #b10110111, 0, 0, 0, 0, 1, 1)
  try(0, #b10110111, 0, 0, 0, 1, 0, 0)
  try(0, #b10110111, 0, 0, 0, 1, 0, 1)
  try(0, #b10110111, 0, 0, 0, 1, 1, 0)
  try(0, #b10110111, 0, 0, 0, 1, 1, 1)
  try(0, #b00000000, a, b, c, d, e, f)
  try(0, #b10000000, a, b, c, d, e, f)
  try(0, #b11000000, a, b, c, d, e, f)
  try(0, #b11110000, a, b, c, d, e, f)
  try(0, #b10000001, a, b, c, d, e, f)
  try(0, #b00000001, a, b, c, d, e, f)
  try(0, #b11001100, a, b, c, d, e, f)
  try(0, #b11111111, a, b, c, d, e, f)
  try(-1,        -1, a, b, c, d, e, f)
 
  RESULTIS 0
}

AND try(r1, r2, a, b, c, d, e, f) BE
{ 
  writef("%bG %bG %bG %bG %n %n %n %n %n %n => %n*n",
          r1>>16,r1, r2>>16, r2, a, b, c, d, e, f,
          relHash6(r1, r2, a, b, c, d, e, f))
}

AND comb(a, x, y) = add(mul(a,x), mul(sub(1,a),y))

AND relHash6(r1, r2, a, b, c, d, e, f) =
  comb(a, relHash5(r1, b, c, d, e, f), relHash5(r2, b, c, d, e, f))

AND relHash5(rel, a, b, c, d, e) =
  comb(a, relHash4(rel>>16, b, c, d, e), relHash4(rel, b, c, d, e))

AND relHash4(rel, a, b, c, d) =
  comb(a, relHash3(rel>>8, b, c, d), relHash3(rel, b, c, d))

AND relHash3(rel, a, b, c) =
  comb(a, relHash2(rel>>4, b, c), relHash2(rel, b, c))

AND relHash2(rel, a, b) =
  comb(a, relHash1(rel>>2, b), relHash1(rel, b))

AND relHash1(rel, a) =
  comb(a, relHash0(rel>>1), relHash0(rel))

AND relHash0(rel) = rel & 1

