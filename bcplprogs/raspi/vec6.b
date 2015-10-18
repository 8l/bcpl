GET "libhdr"
 
LET start() = VALOF
{ LET upb = 1_000_000
  LET isprime = getvec(upb)

  FOR i = 2 TO upb DO isprime!i := TRUE  // Until proved otherwise.
 
  FOR p = 2 TO upb IF isprime!p DO
  { LET i = p*p // First non prime to be crossed out
    // Cross out all multiple of p
    IF i>upb BREAK
    { isprime!i := FALSE; i := i + p } REPEATUNTIL i>upb
  }

  // Output some primes near the end
  FOR p = upb-100 TO upb IF isprime!p DO writef("%6i*n", p)

  freevec(isprime)
  RESULTIS 0
}

