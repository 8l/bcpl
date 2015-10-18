GET "libhdr"

LET gcd(a, b) = VALOF
{ LET r = a MOD b   // r will be less than b
  IF r=0 RESULTIS b // b exactly divides a so is the gcd
  // r and b have the same gcd as a and b
  a := b
  b := r   // a is greater than b
  //writef("%32b*n", a) // To see the rate of convergence
} REPEAT

LET try(a, b) BE
{ LET res = gcd(a, b)
  writef("gcd(%n, %n) = %n*n", a, b, res)
}

LET start() = VALOF
{ try(18, 30)
  try(1000, 450)
  try(1576280161, 1226540484)
}
