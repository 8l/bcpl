/*
This program tests whether a Boolean funtion of five variables
represented by a 32-bit bit pattern having four ones must imply 
the for some i,j  vi=0 or vi=1 or vi=vj or vi~=vj.

This program does it by exhaustively searching the 2**15 cases.

It shows, for instance, that if the min terms are:

abcde=  00000  00011  01100  10101

then there is no simple equality relation between any pair of
the variables a, b, c, d and e.

de = 00  01      11
ce = 00  01  10  11
be = 00  01  10
ae = 00  01      11
cd = 00  01  10
bd = 00  01  10 
ad = 00  01  10
bc = 00  01      11
ac = 00  01      11
ab = 00  01  10

Implemented by Martin Richards (c) June 2003
*/


GET "libhdr"

LET start() = VALOF
{ LET a = 0 // Without loss of generality set a to 0
  FOR b = 0 TO 31 FOR c = 0 TO 31 FOR d = 0 TO 31 DO
  { IF ok(a, b, c, d) DO
    { writef("a=%b5 b=%b5 c=%b5 d=%b5*n", a, b, c, d)
      //abort(1111)
    }
  }

  RESULTIS 0
}

AND ok(a, b, c, d, e) = VALOF
{ UNLESS try(#b00011, a,b,c,d) RESULTIS FALSE
  UNLESS try(#b00101, a,b,c,d) RESULTIS FALSE
  UNLESS try(#b01001, a,b,c,d) RESULTIS FALSE
  UNLESS try(#b10001, a,b,c,d) RESULTIS FALSE
  UNLESS try(#b00110, a,b,c,d) RESULTIS FALSE
  UNLESS try(#b01010, a,b,c,d) RESULTIS FALSE
  UNLESS try(#b10010, a,b,c,d) RESULTIS FALSE
  UNLESS try(#b01100, a,b,c,d) RESULTIS FALSE
  UNLESS try(#b10100, a,b,c,d) RESULTIS FALSE
  UNLESS try(#b11000, a,b,c,d) RESULTIS FALSE
  RESULTIS TRUE
}  

AND try(w,x,y,z,t) = VALOF
{ LET n = 1
  LET a,b,c,d = x&w, y&w, z&w, t&w
  UNLESS b=a DO n := n+1
  UNLESS c=a | c=b DO n := n+1
  UNLESS d=a | d=b | d=c DO n := n+1
  RESULTIS n>=3
}



