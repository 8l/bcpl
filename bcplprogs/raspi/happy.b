GET "libhdr"

LET start() = VALOF
{ FOR n = 0 TO 500_000 DO
  { LET ch = happy(n)
    IF n MOD 50 = 0 DO writef("*n%7i: ", n)
    IF n MOD 10 = 0 DO writef(" ")
    wrch(ch)
    deplete(cos)
  }
  newline()
  RESULTIS 0
}

AND happy(n) = VALOF
{ // Return 'S' if n is sad
  //        'H' if n is happy
  //        '-' if loops
  //        '#' if diverges
  LET count = 0
  LET prevn = -1

  WHILE 2 <= n <= 1_000_000 DO
  { LET sum = 0
//writef("*nn=%6i count=%6i digit: ", n, count)
    { LET d = n MOD 10
      //writef(" %n", d)
      n := n / 10
      //sum := sum + d * d
      sum := sum + d * d * d
    } REPEATUNTIL n=0

    //writef(" => sum=%n*n", sum)
//abort(1000)
    n := sum
    count := count + 1
    IF n=prevn DO
    { //writef("*nLoop found when n=%n*n", n)
      RESULTIS '-'  // Loops
    }
    IF (count & (count-1)) = 0 DO
    { //writef("count = %n  saving prevn=%n*n", count, n)
      prevn := n
    }
  }

  RESULTIS n=0 -> 'S', // Sad
           n=1 -> 'H', // Happy
                  '#'  // Diverges
}
