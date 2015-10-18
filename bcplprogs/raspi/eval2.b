GET "libhdr"
 
GLOBAL {
  sum:ug
  term
  upb
}
 
LET start() = VALOF
{ upb  := 2004/4       // Each element hold 4 decimal digits plus 4 guard digits
  sum  := getvec(upb)
  term := getvec(upb)

  settok(sum,  0)
  sum!upb := 5000      // Add 1/2 at digit position 2000 for rounding
  settok(term, 1)
 
  UNTIL iszero(term) DO
  { add(sum, term)
    divbyk(term, 2)
  }
 
  // Write out the sum to 40 decimal places
   writef("*nsum = %n.", sum!0)
   FOR i = 1 TO 10 DO writef(" %4z", sum!i)
   newline()

fin:
   freevec(sum)
   freevec(term)
   RESULTIS 0
}
 
AND settok(v, k) BE
{ v!0 := k
  FOR i = 1 TO upb DO v!i := 0
}
 
AND add(a, b) BE
{ LET c = 0
  FOR i = upb TO 0 BY -1 DO
  { LET d = c + a!i + b!i
    a!i := d MOD 10000
    c   := d  /  10000
  }
}
 
AND divbyk(v, k) BE
{ LET c = 0
  FOR i = 0 TO upb DO
  { LET d = c*10000 + v!i
    v!i := d  /  k
    c   := d MOD k
  }
}
 
AND iszero(v) = VALOF
{ FOR i = upb TO 0 BY -1 IF v!i RESULTIS FALSE
  RESULTIS TRUE
}



