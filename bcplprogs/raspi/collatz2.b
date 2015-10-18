GET "libhdr"

MANIFEST {
  upb = (1<<20)-1 // ie about 1 million digits max
  mask = upb
  countt=10000  // count at start of test loop
  looplen=541   // Length of test loop
}

GLOBAL {
 digv:ug // digv is a circular buffer holding up to upb binary
 digp    // Position of the least significant binary digit of
         // the number.
 digq    // Position of the most significant digit of the number.
 digvc   // Copy of the digits at last checkpoint
 digcs   // Count of digits in digvc.
 countchk // Count at last checkpoint

 digvt   // Digits of the number at the start of the test loop
 digts   // Count of digits in digvt

 eq1     // Returns TRUE if the number if 1,
         // ie digp=digq and digv!digp=1
 divby2  // Function to divide by 2
 mulby3plus1 // Function to perform n := 3*n+1
 tracing // =TRUE causes the numbers to be output
 looptest// If TRUE a loop of values is created
         // to test that loops can be detected
}

LET start() = VALOF
{ LET len = 5
  LET seed = 12345
  LET count = 0
  LET argv = VEC 50

  UNLESS rdargs("len/n,seed/n,t/s,loop/s", argv, 50) DO
  { writef("Bad args for collatz2*n")
    RESULTIS 0
  }

  IF argv!0 DO len := !(argv!0)      // LEN/N
  IF argv!1 DO seed := !(argv!1)     // SEED/N
  tracing := argv!2                  // T/S
  looptest := argv!3                 // LOOP/S

  setseed(seed)

  UNLESS 0<len<upb DO
  { writef("len must be in range 1 to %n*n", upb)
    RESULTIS 0
  }
  
  digv  := getvec(upb)
  digvc := getvec(upb)
  UNLESS digv & digvc DO
  { writef("upb too large -- more space needed*n")
    RESULTIS 0
  }

  digvt := 0

  IF looptest DO
  { digvt := getvec(upb)
    UNLESS digvt DO
    { writef("upb too large -- more space needed*n")
      RESULTIS 0
    }
  }

  // Initialise digv with a random number of length len
  digp := 0
  FOR i = 0 TO len-2 DO digv!i := randno(2000)/1000
  digv!(len-1) := 1     // Plant a most signigicant 1
  digq := len-1         // Set position of the most significant digit
  digcs := -1

  { LET digs = ((digq+mask+1-digp) & mask) + 1

    count := count+1
    writef("%9i %6i: ", count, digs)
    IF tracing DO prnum()
    newline()

    // Check whether the current number has been seen before
    IF digs = digcs DO
    { // Numbers are the same length so check the digits
      writef("Checking the digits*n", digs)
      FOR i = 0 TO digs-1 UNLESS digvc!i=digv!((digp+i)&mask) GOTO notsame
      writef("*nLoop of length %n found at count = %n*n",
              count-countchk, count)
      GOTO fin
    }

notsame:
    IF (count&(count-1))=0 DO
    { // Set new check value in digvc
      FOR i = 0 TO digs-1 DO digvc!i := digv!((digp+i)&mask)
      digcs := digs
      countchk := count // Remember the position of the check value
      writef("%9i %6i: Set new check value*n", count, digs)
//abort(1002)
    }

    IF looptest DO
    { IF count=countt DO
      { // Create a loop starting here
        FOR i = 0 TO digs-1 DO digvt!i := digv!((digp+i)&mask)
        digts := digs
        writef("%9i: Save start of loop number*n", count)
//abort(1001)
      }

      IF count>countt & (count-countt) MOD looplen = 0 DO
      { // Return to start of test loop
        FOR i = 0 TO digts-1 DO digv!i := digvt!i
        digp, digq := 0, digts-1
        writef("%9i: Restore start of loop number*n", count)
//abort(1000)
      }
    }

    IF eq1() BREAK
    TEST digv!digp=0 // Test for even
    THEN divby2()
    ELSE mulby3plus1()
  } REPEAT

fin:
  IF digv  DO freevec(digv)
  IF digvc DO freevec(digvc)
  IF digvt DO freevec(digvt)
  RESULTIS 0
}

AND eq1() = digp=digq & digv!digp=1 -> TRUE, FALSE

AND divby2() BE
{ TEST digp=digq
  THEN digv!digp := 0
  ELSE digp := (digp+1)&mask
}

AND mulby3plus1() BE
{ // Calculate 3*n+1 eg
  //        1 +
  //     1011 +
  //    10110 =
  //   ------
  //   100010
  LET carry = 1
  LET prev  = 0
  LET i = digp

  { LET dig = digv!i
    LET val = carry+dig+prev
    digv!i := val&1
    carry  := val>>1
    prev := dig
    IF i=digq DO
    { IF prev=0=carry RETURN // No need to lengthen the number
      i := (i+1)&mask
      digv!i := 0
      digq := i
      LOOP
    }
    i := (i+1)&mask
  } REPEAT
}

AND prnum() BE
{ LET i = digp
  { LET dig = digv!i
    wrch('0'+dig)
    IF i=digq RETURN
    i := (i+1)&mask
  } REPEAT
}
