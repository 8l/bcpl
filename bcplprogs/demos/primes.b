GET "libhdr"
 
GLOBAL {  count: ug  }
 
MANIFEST {  upb = 9999  }
//MANIFEST {  upb = 1000000  }
 
LET start() = VALOF
{  LET isprime = getvec(upb)
   LET bigp = 0
   count := 0

   FOR i = 2 TO upb DO isprime!i := TRUE  // Until proved otherwise.
 
   FOR p = 2 TO upb IF isprime!p DO
   {  LET i = p*p
      UNTIL i>upb DO {  isprime!i := FALSE; i := i + p }
      out(p)
      bigp := p
   }

//writef("*n*nLargest prime %n*n", bigp)
   writes("*nend of output*n")
   freevec(isprime)
   RESULTIS 0
}
 
AND out(n) BE
{  IF count MOD 10 = 0 DO writef("*n%i5: ", count+1)
   writef(" %i5", n)
   count := count + 1
}
