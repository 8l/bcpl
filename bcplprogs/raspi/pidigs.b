/*
This is a BCPL implementation of the program that appears in section
10.7 of the book "Number Theory, A Programmer's Guide" by Mark
Herkommer. He uses a miraculous formula for pi discovered by David
Bailey, Peter Borwein and Simon Plouffe. The formula is

pi = the sum from n = 0 to infinity of

  (4/(8n+1) - 2/(8n+4) - 1/(8n+5) - 1/(8n+6))/(16**n)

Using modulo arithmetic, it is possible to find the nth hexadecimal
digit of pi without having to compute the others.

Herkommer's program uses double length floating point values, but mine
uses 32-bit scaled fixed point arithmetic, as a result my version
suffer rounding errors for smaller values of n. Using scaled numbers
with 28 bits after the decimal point allows this program to compute
the hex digits of pi from position 0 to 5000 correctly. It also
calculates the digits from position 100000 to 100050 correctly as well
as the digit at position one million. There is no guarantee that all
the other positions will be computed correctly since errors can arise
when long sequences of ones occur in the binary representation of pi,
and this is unpredictable.

I have just modified this program to output the digits of pi in both
hexadecimal and decimal. With 28 fraction bits the first decimal digit
to be wrong is at position 7007.

Implemented in BCPL by Martin Richards (c) october 2014

*/

GET "libhdr"

MANIFEST {
// Define the scaled arithmetic parameters
fraclen = 28        // Number of binary digits after the decimal point
                    // 28 allows numbers in the range -8.0 <= x < 8.0
One  = 1<<fraclen   // eg #x10000000
Two  = 2*One        // eg #x20000000
Four = 4*One        // eg #x40000000
fracmask = One - 1  // eg #x0FFFFFFF 

upb = 1000
}

LET start() = VALOF
{ LET hexdig = getvec(upb)

  writef("*nPi in hex*n")
  writef("*n       3.")
  hexdig!0 := 3
  FOR n = 1 TO upb DO {
    LET dig = pihexdig(n-1)
    hexdig!n := dig  // Save the hex digits in hexdig
    IF n MOD 50 = 1 DO writef("*n%5i: ", n)
    writef("%x1", dig); deplete(cos)
  }
  newline()

  writef("*nPi in decimal*n")
  writef("*n       3.")

  FOR i = 1 TO upb DO
  { IF i MOD 50 = 1 DO writef("*n%5i: ", i)
    hexdig!0 := 0          // Remove the integer part then
    mulby10(hexdig, upb)   // multiply the fraction by 10 to obtain
    writef("%n", hexdig!0) // the next decimal digit in hexdig!0
    deplete(cos)
  }
  newline()
  freevec(hexdig)
  RESULTIS 0
}

AND mulby10(v, upb) BE
{ // v contains one hex digit per element with the
  // decimal point between v!0 and v!1
  LET carry = 0
  FOR i = upb TO 0 BY -1 DO
  { LET d = v!i*10 + carry
    v!i, carry := d MOD 16, d/16
  }
}

AND pihexdig(n) = VALOF
{ // By convention, the first hex digit after the decimal point
  // is at position n=0
  LET s = 0 // A scaled number with fraclen binary digits
            // after the decimal point
  LET t = One

  //writef("*nn = %n*n", n)

  FOR i = 0 TO n-1 DO
  { LET a = muldiv(Four, powmod(16, n-i, 8*i+1), 8*i+1)
    LET b = muldiv( Two, powmod(16, n-i, 8*i+4), 8*i+4)
    LET c = muldiv( One, powmod(16, n-i, 8*i+5), 8*i+5)
    LET d = muldiv( One, powmod(16, n-i, 8*i+6), 8*i+6)

    s := s + a - b - c - d & fracmask

    //tr("a", a); tr("b", b); tr("c", c); tr("d", d); tr("s", s)
    //newline()
  }

  // Now add more terms until they are too small to matter
  { LET i = n
    WHILE t DO
    { LET a = 4 * t / (8*i+1)
      LET b = 2 * t / (8*i+4)
      LET c =     t / (8*i+5)
      LET d =     t / (8*i+6)

      s := s + a - b - c - d & fracmask

      //tr("a", a); tr("b", b); tr("c", c); tr("d", d); tr("s", s)
      //newline()

      i, t := i+1, t/16
    }
  }

  RESULTIS (s>>(fraclen-4)) & #xF
}

AND powmod(x, n, m) = VALOF
{ LET res = 1
  LET p = x MOD m
  WHILE n DO
  { UNLESS (n & 1)=0 DO res := (res * p) MOD m
    n := n>>1
    p := (p*p) MOD m
  }
  RESULTIS res
}

AND tr(str, x) BE
{ // Output scaled number x in decimal and hex
  LET d = muldiv( 1_000_000, x, One)
  LET h = muldiv(#x10000000, x, One) // Just in case fraclen is not 28
  writef("%s = %9.6d  %8x*n", str, d, h)
}
