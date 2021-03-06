/* A program to compute Pi to many decimal places.
   Written by Kiyoshi Akima
   Slightly edited by M. Richards

   Typical usage:

   0> c b pi
   bcpl pi.b to pi hdrs BCPLHDRS 

   BCPL (17 Jan 2006)
   Code size =   872 bytes
   0> 
   0> pi 200
   pi = 3.+
   1415926535 8979323846 2643383279 5028841971 6939937510
   5820974944 5923078164 0628620899 8628034825 3421170679
   8214808651 3282306647 0938446095 5058223172 5359408128
   4811174502 8410270193 8521105559 6446229489 5493038196
   30> 
*/

GET "libhdr"

LET allocate(w) = 1 + getvec(w + 1)

LET arctangent(sum, term, temp, factor, y, len) BE {
  LET j, y2 = 1, y * y
  LET acc, carry = ?, ?

  term%0 := factor
  FOR i = 1 TO len DO term%i := 0
  divide(term, term, y, len)
  FOR i = 0 TO len DO temp%i := term%i
  carry := 0
  FOR i = len TO 0 BY -1 DO
    acc, sum%i, carry := sum%i + temp%i + carry, acc MOD 100, acc / 100

  { divide(term, term, y2, len)
    j := j + 2
    divide(term, temp, j, len)
    carry := 0
    FOR i = len TO 0 BY -1 DO
    { acc := 100 + sum%i - temp%i - carry
      sum%i := acc MOD 100
      carry := 1 - acc / 100
    }
    divide(term, term, y2, len)
    j := j + 2
    divide(term, temp, j, len)
    carry := 0
    FOR i = len TO 0 BY -1 DO
    { acc := sum%i + temp%i + carry
      sum%i := acc MOD 100
      carry := acc / 100
    }
  } REPEATUNTIL iszero(temp, len)
}

AND iszero(v, l) = VALOF {
  FOR i = 0 TO l IF v%i RESULTIS FALSE
  RESULTIS TRUE
}

AND divide(src, dst, d, l) BE {
  LET rem, n = 0, ?

  FOR i = 0 TO l DO
  { n := src%i + 100 * rem
    rem := n MOD d
    dst%i := n / d
  }
}

LET start() = VALOF {
  LET argv = VEC 10
  LET digits = ?
  LET bytes, words = ?, ?
  LET pi, temp1, temp2 = ?, ?, ?
  LET p = 0

  UNLESS rdargs("DIGITS/A", argv, 10) DO {
    writes("usage: pi #digits*n")
    RESULTIS 1
  }
  digits := str2numb(argv!0)
  UNLESS 0 < digits DO {
    writes("usage: pi #digits*n")
    RESULTIS 1
  }
  bytes, words := 1 + digits / 2, 1 + digits / 8
  pi, temp1, temp2 := allocate(words), allocate(words), allocate(words)
  UNLESS pi & temp1 & temp2 DO {
    writes("pi: insufficent memory*n")
    RESULTIS 2
  }
  FOR i = 0 TO bytes DO pi%i := 0
  arctangent(pi, temp1, temp2, 24,   8, bytes)
  arctangent(pi, temp1, temp2,  8,  57, bytes)
  arctangent(pi, temp1, temp2,  4, 239, bytes)
  writef("pi = %i1.+*n", pi%0)
  FOR i = 1 TO digits DO {
    TEST i MOD 2 THEN {
      p := p + 1
      writef("%i1", pi%p / 10)
    } ELSE
      writef("%i1", pi%p MOD 10)
    UNLESS i MOD 10 DO {
      wrch(i MOD 50 -> ' ', '*n')
      UNLESS i MOD 1000 DO
      wrch('*n')
    }
  }
  IF digits MOD 50 DO wrch('*n')
  freevec(pi - 1)
  freevec(temp1 - 1)
  freevec(temp2 - 1)

  RESULTIS 0
}
