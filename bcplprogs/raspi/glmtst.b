/*
This is designed to test matrix multiplication
in gl.

Implemented by Martin Richards (c) May 2014
*/

GET "libhdr"
GET "gl.h"
GET "gl.b"
.

GET "libhdr"
GET "gl.h"

LET start() = VALOF
{ LET A = VEC 15
  LET B = VEC 15
  LET C = VEC 15
  LET P = VEC 15
  LET Q = VEC 15

  LET days, msecs, dummy = 0, 0, 0
  datstamp(@days)
  setseed(msecs) // Use msecs of the current time as random number seed

  randmat(A)
  randmat(B)
  randmat(C)

  writef("*n*n                   A*
         *                               B*
         *                               C*n*n")

  prrow(A,0);  prrow(B,0);  prrow(C,0); newline()
  prrow(A,1);  prrow(B,1);  prrow(C,1); newline()
  prrow(A,2);  prrow(B,2);  prrow(C,2); newline()
  prrow(A,3);  prrow(B,3);  prrow(C,3); newline()

  copymat(B, Q)
  glMat4mul(A, Q)
  copymat(C, P)
  glMat4mul(Q, P)  // P = (AB)C

  copymat(C, Q)
  glMat4mul(B, Q)
  glMat4mul(A, Q)  // Q = A(BC)

  writef("*n*n                 (AB)C             =*
         *              A(BC)*n*n")

  prrow(P,0);  prrow(Q,0);  newline()
  prrow(P,1);  prrow(Q,1);  newline()
  prrow(P,2);  prrow(Q,2);  newline()
  prrow(P,3);  prrow(Q,3);  newline()

  copymat(B, P)
  glMat4mul(A, P)   // P = AB
  copymat(A, Q)
  glMat4mul(B, Q)   // Q = BA

  writef("*n*n                  AB              ~=*
         *               BA*n*n")

  prrow(P,0);  prrow(Q,0);  newline()
  prrow(P,1);  prrow(Q,1);  newline()
  prrow(P,2);  prrow(Q,2);  newline()
  prrow(P,3);  prrow(Q,3);  newline()

  RESULTIS 0
}

AND randmat(M) BE
{ // Fill M with random floating point numbers in range -4.9 to +4.9
  FOR i = 0 TO 15 DO M!i := sys(Sys_flt, fl_N2F, randno(99)-50, 10)
}

AND prrow(M, i) BE
{ writef("    ")
  FOR j = 0 TO 3 DO
  { LET x = M!(4*j + i)
    writef(" %6.1d", sys(Sys_flt, fl_F2N, x, 10))
  }
}

AND copymat(P, Q) BE FOR i = 0 TO 15 DO Q!i := P!i

