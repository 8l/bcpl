GET "libhdr"

LET start() = VALOF
{ LET args = VEC 50

  IF rdargs("YEAR", args, 50)=0 DO
  { writef("Bad arguments for EASTER*n")
    RESULTIS 20
  }

  TEST args!0=0

  THEN { writef("Calculating the Easter cycle*n")
         writef("The Easter cycle is %n*n", cycle())
       }

  ELSE { LET year = str2numb(args!0)
         IF 0<=year<=99 DO year := year+2000
         FOR y = year TO year+9 DO
           writef("The date of Easter in %n is %n/%n*n", 
                   y, easter(y)/10, easter(y) REM 10)
       }

  RESULTIS 0
}

AND easter(year) = VALOF
{ LET a    = year REM 19
  LET b, c = year/100, year REM 100
  LET d, e = b/4, b REM 4
  LET f    = (b+8)/25
  LET g    = (b-f+1)/3
  LET h    = (19*a+b-d-g+15) REM 30
  LET i, k = c/4, c REM 4
  LET l    = (32+2*e+2*i-h-k) REM 7
  LET m    = (a+11*h+22*l)/451
  LET x    = h+l-7*m+114
  LET n, p = x/31, x REM 31
  RESULTIS 10*(p+1)+n
}

// The following is a debugging version of easter with an obvious cycle
AND easter1(year) = year REM 2_718_281

AND cycle() = VALOF
{ MANIFEST { year=1996; K=7654321 }

  LET hashdiff = K*easter(year+1) NEQV K*easter(year)
  
  FOR cycle = 1 TO 6_000_000 DO
  { LET y = year + cycle + cycle

    hashdiff := hashdiff NEQV K*easter(y) NEQV K*easter(y+1)

    IF cycle REM 1_000_000 = 0 DO writef("trying cycle = %i9*n", cycle)
    IF hashdiff=0 DO
    { writef("hashdiff=0 when cycle is %n*n", cycle+1)
      IF iscycle(cycle+1) RESULTIS cycle+1
    }
    
  }

  RESULTIS 0
}

AND iscycle(cycle) = VALOF
{ writef("testing cycle = %n*n", cycle)
  FOR i = 0 TO cycle DO
  { UNLESS easter(1996+i)=easter(1996+cycle+i) RESULTIS FALSE
    IF i REM 1000000 = 0 DO writef("%n matched so far*n", i+1)
  }
  RESULTIS TRUE
}
