GET "libhdr"

LET start() = VALOF
{ LET a = 0   // a and b will hold two consecutive Fibonacci numbers
  LET b = 1
  LET c = a+b // c will hold the Fibonacci number after b, namely a+b
  LET i = 0   // The position of the Fibonacci number held in a

  WHILE i<=2 DO
  { writef("Position %n  Value %n*n", i, a)
    a := b
    b := c
    c := a+b
    i := i+1
  }

  RESULTIS 0
}
