GET "libhdr"

LET start() = VALOF
{ LET f = VEC 50
  f!0 := 0   // Fill in the first two Fibonacci number
  f!1 := 1
  // Now fill the others in
  FOR i = 2 TO 50 DO f!i := f!(i-1) + f!(i-2)

  // Now write out the result
  FOR i = 0 TO 50 DO
    writef("Position %2i  Value %12u  %32b*n", i, f!i, f!i)

  RESULTIS 0
}
