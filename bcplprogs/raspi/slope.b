GET "libhdr"

// This program outputs the approximate slope of y = x^n for
// various values of x and n, using scaled numbers with 8 digits
// after the decimal point.


LET start() = VALOF
{ writef("     x      n     dx         slope     n**pow(x,n-1)*n*n")

  try( 1_12345678, 0); try( 1_12345678, 1); try( 1_12345678, 2)
  try( 1_12345678, 3); try( 1_12345678, 4)
  newline()
  try( 0_87654321, 0); try( 0_87654321, 1); try( 0_87654321, 2)
  try( 0_87654321, 3); try( 0_87654321, 4)
  newline()
  try(-0_12345678, 0); try(-0_12345678, 1); try(-0_12345678, 2)
  try(-0_12345678, 3); try(-0_12345678, 4)

  RESULTIS 0
}

AND try(x, n) BE
{ LET dx = 0_00010000
  LET slope = muldiv(pow(x+dx,n) - pow(x,n), 1_00000000, dx)
  writef("%11.8d %n %11.8d %11.8d  %11.8d*n",
         x, n, dx, slope, n * pow(x, n-1)) 
}

AND pow(x, n) = VALOF
{ LET xn = 1_00000000
  FOR i = 1 TO n DO xn := muldiv(xn, x, 1_00000000)
  RESULTIS xn
}
