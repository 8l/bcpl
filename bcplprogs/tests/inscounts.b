GET "libhdr"

GLOBAL { nullfn:200; fact }

LET nullfn() BE RETURN

LET fact(n) = n=0 -> 1, n*fact(n-1)

LET start() = VALOF
{ writef("*nnullfn takes %n Cintcode instructions*n*n", instrcount(nullfn, 23))
  FOR i = 1 TO 8 DO writef("fact(%n) takes %i3 Cintcode instructions*n",
                           i,  instrcount(fact, i))
  RESULTIS 0
}
