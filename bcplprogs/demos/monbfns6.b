// This program calculates the number of monadic boolean 
// functions of n boolean variables, for n<=6

GET "libhdr"

GLOBAL {
  succs0: 200  // <succs0!i, succs1!1> = set of successors to vertex i
  succs1: 201
}

LET start() = VALOF
{ LET v0 = VEC 63
  LET v1 = VEC 63
  FOR i = 0 TO 63 DO
  { v0!i, v1!i := 0, 0
    FOR j = i TO 63 IF (i&j)=i TEST j<32
    THEN v0!i := v0!i | 1<<j
    ELSE v1!i := v1!i | 1<<(j-32)
  }
  succs0, succs1 := v0, v1  

//FOR n = 0 TO 63 DO writef("%b6 %bW %bW*n", n, succs1!n, succs0!n)

  FOR n = 0 TO 6 DO
    writef("There are %i7 monotonic boolean functions of %n variables*n",
                      mbfns(0, 1<<n, 0), n)
  RESULTIS 0
}

AND mbfns(i, bit, bits1, bits0) = VALOF
{ LET count = 0
  //writef("i=%n bits %b6*n", i, bits)
  IF i>=bit RESULTIS 1
  IF ((i<32 -> bits0>>i, bits1>>(i-32)) & 1) = 0 DO
          count := mbfns(i+1, bit, bits1 | succs1!i,
                                   bits0 | succs0!i) // Vi assigned T
  RESULTIS count + mbfns(i+1, bit, bits1, bits0)     // Vi assigned F
}


