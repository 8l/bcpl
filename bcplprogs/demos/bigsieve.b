GET "libhdr"
 
GLOBAL {  count: ug; sieve; n; k  }
 
MANIFEST {
  upb = 32_000_000
  //upb = 10_000_000
  sieveupb = upb/32
  All = #xFFFFFFFF
}
 
LET start() = VALOF
{ LET argv = VEC 50

   n, k := 30_000_000, 20
  
  IF rdargs("FROM/N,COUNT/N", argv, 50)=0 DO
  { writes("Bad arguments for BIGPRIMES*n")
    RESULTIS 20
  }

   IF argv!0 DO n := !(argv!0)
   IF argv!1 DO k := !(argv!1)

   writef("*n%n primes from %n are:*n", k, n)

   sieve := getvec(sieveupb)

   FOR i = 0 TO sieveupb DO
     sieve!i := All  // Until proved otherwise.

   // Fill in the sieve 
   FOR p = 2 TO upb IF isprime(p) DO
   {  LET i = p*p
      IF i>upb BREAK
      UNTIL i>upb DO {  notprime(i); i := i + p }
   }

   // The sieve is now complete

   count := 0

   UNTIL count>=k | n>upb DO
   { IF isprime(n) DO out(n)
     n := n+1
   }
 
   writes("*nend of output*n")
   freevec(sieve)
   RESULTIS 0
}

AND isprime(p) = VALOF
{ LET i = p / 32
  AND bit = 1 << (p MOD 32)
  RESULTIS sieve!i & bit
}
 
AND notprime(p) BE
{ LET i = p / 32
  AND bit = 1 << (p MOD 32)
  sieve!i := sieve!i & ~bit
}

AND out(n) BE
{  IF count MOD 5 = 0 DO newline()
   writef(" %i9", n)
   count := count + 1
}
