/*
This program uses dynamic programming to solve the
matrix-chain multiplication problem discussed in
Cormen, Leiserson and Rivest "Introduction to Algorithms"
page 302-309.
*/

GET "libhdr"

MANIFEST
{ imax = 10
  jmax = 10
}

GLOBAL {
  m:ug
}

LET start() = VALOF
{ LET v = VEC imax
  LET w = VEC imax*jmax
  m := v
  FOR i = 1 TO imax DO m!i := @w!((i-1)*jmax)

  writef("Matrix-chain problem*n")
  try( 1,  TABLE 5, 3)
  try( 2,  TABLE 5, 3, 6)
  try( 3,  TABLE 5, 3, 6, 2)
  try( 4,  TABLE 5, 3, 6, 2, 8)
  try( 6,  TABLE 30, 35, 15, 5, 10, 20, 25)
  try( 9,  TABLE 30, 35, 15, 5, 10, 20, 25, 12, 3, 8)
  try(10,  TABLE 30, 35, 15, 5, 10, 20, 25, 12, 3, 8, 20)
  RESULTIS 0
}

AND try(n, p) BE
// n = the number of matrices to multiply
{ LET res = 0
  newline()
  FOR i = 0 TO n DO writef(" %i2", p!i)
  newline()
  res := instrcount(muls, p, 1, n)
  writef("Number of scalar multiplications: %n  instruction count: %n*n",
          result2, res)
  FOR i = 1 TO n FOR j = 1 TO n DO m!i!j := maxint
  res := instrcount(dynmuls, p, 1, n)
  writef("Number of scalar multiplications: %n  instruction count: %n*n",
          result2, res)
}

AND muls(p, i, j) = i=j -> 0, VALOF
{ LET res = maxint
  FOR k = i TO j-1 DO
  { LET r = muls(p, i,   k) +
            muls(p, k+1, j) +
            p!(i-1) * p!k * p!j
    IF res > r DO res := r
  }
  RESULTIS res
}

AND dynmuls(p, i, j) = i=j -> 0, VALOF
{ LET res = m!i!j
  IF res = maxint DO
  { // We must compute the value of m!i!j
    FOR k = i TO j-1 DO
    { LET r = dynmuls(p, i,   k) +
              dynmuls(p, k+1, j) +
              p!(i-1) * p!k * p!j
      IF res > r DO res:= r
    }
    m!i!j := res // Remember the value for future use
  }
  RESULTIS res
}

