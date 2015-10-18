/*
This program tests whether a Boolean function of five variables
represented by a 32-bit bit pattern having five ones implies 
there is a simple relation over some pair of variables vi and vj.

This program does it by exhaustively searching the 2**20 cases.

It shows, for instance, that if the min terms are:

abcde=  00000  00001  01110  10110  11011  11101

then there is no relation between any pair of
the variables a, b, c, d and e.

de = 00  01  10  11
ce = 00  01  10  11
be = 00  01  10  11
ae = 00  01  10  11
cd = 00  01  10  11
bd = 00  01  10  11
ad = 00  01  10  11
bc = 00  01  10  11
ac = 00  01  10  11
ab = 00  01  10  11

Let R be a relation over 5 variables (abcde) which is

(a) dependent on every variable,
(b) for each variable x, say, there are valid setting in which x=1 and x=0,
(c) there is no pair of variable xy, say, for which x=y for all valid setting,
(d) there is no pair of variable xy, say, for which x=~y for all valid setting.

If R can be factorized into the conjunction of a relation S over 2
variables and T over 3 variables then

(a) R must imply S
(b) S must be of the form x->y x->~y ~x->y ~x->~y, and so its
    bit pattern must be 0111, 1011, 1101 or 1110 
(c) The number of ones in bit pattern for R must be divisible by 3
(d) and be between 6 and 31-6=25, ie 6,9,12,15,18,21 or 24

Implemented by Martin Richards (c) June 2003
*/


GET "libhdr"

LET start() = VALOF
{ LET a = 0 // Without loss of generality set a to 0
  FOR b = a+1 TO 31 FOR c = b+1 TO 31 FOR d = c+1 TO 31 FOR e = d+1 TO 31 DO
    FOR f = e+1 TO 31 DO
  { IF ok(a, b, c, d, e, f) DO
    { writef("a=%b5 b=%b5 c=%b5 d=%b5 e=%b5 f=%b5*n", a, b, c, d, e, f)
      abort(1111)
    }
  }

  RESULTIS 0
}

AND ok(a, b, c, d, e, f) = VALOF
{ LET k = 4      // solution: a=00000 b=00001 c=01110 d=10110 e=11011 f=11101
  k,f   := 4,0   // solution: none
  k,e,f := 4,0,0 // solution: none
  k,e,f := 3,0,0 // solution: a=00000 b=00011 c=01100 d=10101
  IF distinct(#b00011, a,b,c,d,e,f) < k RESULTIS FALSE
  IF distinct(#b00101, a,b,c,d,e,f) < k RESULTIS FALSE
  IF distinct(#b01001, a,b,c,d,e,f) < k RESULTIS FALSE
  IF distinct(#b10001, a,b,c,d,e,f) < k RESULTIS FALSE
  IF distinct(#b00110, a,b,c,d,e,f) < k RESULTIS FALSE
  IF distinct(#b01010, a,b,c,d,e,f) < k RESULTIS FALSE
  IF distinct(#b10010, a,b,c,d,e,f) < k RESULTIS FALSE
  IF distinct(#b01100, a,b,c,d,e,f) < k RESULTIS FALSE
  IF distinct(#b10100, a,b,c,d,e,f) < k RESULTIS FALSE
  IF distinct(#b11000, a,b,c,d,e,f) < k RESULTIS FALSE
  RESULTIS TRUE
}  

AND distinct(w,a,b,c,d,e,f) = VALOF
{ LET n = 1
  a,b,c,d,e,f:= a&w, b&w, c&w, d&w, e&w, f&w
  UNLESS b=a DO n := n+1
  UNLESS c=a | c=b DO n := n+1
  UNLESS d=a | d=b | d=c DO n := n+1
  UNLESS e=a | e=b | e=c | e=d DO n := n+1
  UNLESS f=a | f=b | f=c | f=d | f=e DO n := n+1
  RESULTIS n
}




