GET "libhdr"

LET start() = VALOF
{ LET n = 100   // The number of the prime we want
  LET p = 2     // The current number we are looking at
  LET count = 0 // The count of how many primes we have found

  { // Start of the main loop
    // Test whether p is prime
    // Let us assume it is prime unless proved otherwise
    LET p_is_prime = TRUE
    // Try dividing it by all numbers between 2 and p-1

    FOR d = 2 TO p-1 DO
    { // d is the next divisor to try
      // We test to see if d divides p exactly
      LET r = p  // Take a copy of p
      // Keep subtracting d until r is less than d
      UNTIL r < d DO r := r - d
      // If r is now zero, d exactly divides p
      // and so p is not prime
      IF r=0 DO
      { p_is_prime := FALSE
        BREAK  // Break out of the FOR loop
      }
    }

    IF p_is_prime DO
    { // We have found a prime so increment the count
      count := count + 1
      IF count = n DO
      { // We have found the prime we were looking for,
        // so print it out.
        writef("The %nth prime is %n*n", n, p)
        // and stop
        RESULTIS 0
      }
    }
    // Test the next number
    p := p+1
  } REPEAT
}
