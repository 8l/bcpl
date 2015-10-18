GET "libhdr"

MANIFEST { upb = 40000 }

LET prime1() = VALOF
{ LET isprime = getvec(upb)
  FOR i = 2 TO upb DO isprime!i := TRUE // Until disproved
 
  FOR p = 2 TO upb IF isprime!p DO
  { LET i = p*p
    UNTIL i>upb DO { isprime!i := FALSE; i := i + p }
    cowait(p)
  }
  freevec(isprime)
  RESULTIS 0
}

AND prime2() = VALOF
{ FOR n = 2 TO upb DO
  { LET a, b = 2, 1 
    FOR i = 1 TO n DO { LET c = (a+b) REM n
                        a := b
                        b := c
                      }
    IF a=1 DO cowait(n)
  }
  RESULTIS 0
}

LET start() = VALOF
{ LET P1 = createco(prime1, 100)
  LET P2 = createco(prime2, 100)
  LET n1, n2, min = 0, 0, 0
  { IF n1=min DO n1 := callco(P1)
    IF n2=min DO n2 := callco(P2)
    min := n1<n2 -> n1, n2
    UNLESS n1=n2 DO
       writef(" %i4 from P%c*n", min, n1<n2 -> '1', '2')
  } REPEATUNTIL min=0
  deleteco(P1)
  deleteco(P2)
  RESULTIS 0
}
