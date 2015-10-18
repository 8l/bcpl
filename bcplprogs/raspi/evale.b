GET "libhdr"
 
GLOBAL {
  sum:ug   // The sum of terms so far
  term     // The next term to add to sum
  tab      // The frequency counts of the digits of e
  digcount
  digits   // The number of decimal digits to calculate
  upb
}
 
LET start() = VALOF
{ LET n  = 1
  digits := 2000         // Calculate e to 2000 decimal places
  upb  := (digits+10)/4  // add ten guard digits
  tab  := getvec(9)      // for digit frequency counts
  sum  := getvec(upb)    // will hold the sum of the series
  term := getvec(upb)    // the next term in the series to add to sum

  UNLESS tab & sum & term DO
  { writef("Unable to allocate vectors*n")
    GOTO fin
  }

  settok(sum,  1)        // Initial value of sum
  settok(term, 1)        // The first term to add
 
  UNTIL iszero(term) DO  // Until the term is zero
  { add(sum, term)       //   Add the term to sum
    n := n + 1
    divbyk(term, n)      //   Calculate the next term
  }
 
  // Write out e
  writes("*ne = *n")
  print(sum)

  // Write out the digit frequency counts
  writes("*nDigit counts*n")
  FOR i = 0 TO 9 DO writef("%n:%i3  ", i, tab!i)
  newline()

fin:
  freevec(tab)
  freevec(sum)
  freevec(term)
  RESULTIS 0
}

AND settok(v, k) BE
{ v!0 := k                     // Set the integer part
  FOR i = 1 TO upb DO v!i := 0 // Clear all fractional digits
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

AND print(v) BE
{ FOR i = 0 TO 9 DO tab!i := 0  // Clear the frequency counts
  digcount := 0
  writef(" %i4.", v!0)
  FOR i = 1 TO upb DO
  { IF i MOD 15 = 0 DO writes("*n ")
    wrpn(v!i, 4)
    wrch('*s')
  }
  newline()
} 
 
AND wrpn(n, d) BE
{ IF d>1 DO wrpn(n/10, d-1)
  IF digcount>=digits RETURN
  n := n MOD 10
  tab!n := tab!n + 1
  wrch(n+'0')
  digcount := digcount+1
}

