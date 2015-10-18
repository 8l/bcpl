// This is a test of integer division algorithms

// It is still under development

// Implemented by Martin Richards (c) January 2012

GET "libhdr"

GLOBAL {
  d:ug
  k
  x
}

LET start() = VALOF
{ LET argv = VEC 50

  UNLESS rdargs("D/n,K/n,X/n", argv, 50) DO
  { writef("Bad arguments for idiv*n")
    RESULTIS 0
  }

  d, k := 3_000000, 5
  x := 0_500000        // The initial guess is critical

  IF argv!0 DO d := !(argv!0)  // d/n
  IF argv!1 DO k := !(argv!1)  // k/n
  IF argv!2 DO x := !(argv!2)  // x/n


  writef("%i2: %12.6d*n", 0, x)

  // Calculate the reciprical using Newton-Raphson iteration
  FOR i = 1 TO k DO
  { x := muldiv(x, 2_000000 - muldiv(d, x, 1_000000), 1_000000)
    writef("%i2: %12.6d*n", i, x)
  }

  try(7,5)
  try(70,50)
  try(700,500)
  try(7000,5000)
  try(70000,50000)
  try(700000,500000)
  try(7000000,5000000)
  try(70000000,50000000)
  try(700000000,50000000)
  try(7000000000,5000000000)

  try(#xFFFFFFFF, #x80000000)
  try(#xFFFFFFFF, #x08000000)
  try(#xFFFFFFFF, #x00800000)
  try(#xFFFFFFFF, #x00000001)
  try(#xFFFFFFFF, #x00000000)

  FOR i = 1 TO 5 DO
  { LET n, d = randno(1_000_000_000), randno(1_000_000_000)/100
    try(n, d)
  }  
  RESULTIS 0
}

AND try(n, d) = VALOF
{ LET q, r = ?, ?
  writef("%10u / %10u =>*n", n, d)
  q := longdiv(n,d)
  r := result2
  checkdiv(n, d, q, r)
  writef("  %10u remainder %10u*n", q, r)
  q := fastdiv(n,d)
  r := result2
  checkdiv(n, d, q, r)
  writef("  %10u remainder %10u*n", q, r)
}

AND checkdiv(n, d, q, r) BE
  TEST d*q = n-r & 0-r<=0 & r-d<0 |
       d=0 & q=-1 & r=-1    // Division by zero
  THEN writef("    ")
  ELSE writef("Bad ")

AND longdiv(n, d) = VALOF
{ // n       is the unsigned numberator
  // d       is the unsigned denominator
  // result  is the quotient
  // result2 is the remainder
  LET k = 0
  LET r = n
  LET q = 0

  UNLESS d DO { result2 := -1; RESULTIS -1 } // Div by zero
  WHILE (r>>1)-d > 0 DO d, k := d<<1, k+1
  // Invariant: original denominator = d / 2**k
  { q := q<<1  // make room for another quotient digit
    IF r-d>=0 DO r, q := r-d, q+1 // Unsigned comparison
    IF k=0 DO { result2 := r; RESULTIS q }
    d, k := d>>1, k-1
  } REPEAT 
}

AND fastdiv(n, d) = VALOF
{ // n       is the unsigned numberator
  // d       is the unsigned denominator
  // result  is the quotient
  // result2 is the remainder

  // This is a variation of Goldschmidt's (or IBM's) method.

  // If d=0 return -1 with remainder -1 indicating division by zero

  // Scale n and d so that 1/2<d<=1
  // then write d as 1-x ie x = 1-d
  // Note that 0<=x<1/2

  // After scaling the quotient is n/(1-x)
  // Multiply the top and bottom successively by
  // (1+x), (1+x^2), (1+x^4), (1+x^8), ...
  // giving, typically

  // quotient = n(1+x)(1+x^2)(1+x^4)(1+x^8)(1+x^16)/(1-x^32)

  // since 0<=x<1/2, the term (1-x^32) can be ignored for 32-bit precision

  // Represent number using scaled integers with scale binary digits
  // after the decimal point.
  LET scale = 0
  LET unit  = 1
  LET x, xp = ?, ?
  // Invariant: one = unit / 2^scale
  LET q = n

  UNLESS d DO { result2 := -1; RESULTIS -1 } // Division by zero

  IF d<0 TEST n-d<0
         THEN { result2 := n;   RESULTIS 0 }
         ELSE { result2 := n-d; RESULTIS 1 }

  // Now scale n and d
  UNTIL d-unit<=0 DO // Unsigned d <= unit
  { unit, scale := 2*unit, scale+1
    //writef("unit = %32b scale %n*n", unit, scale)
    //IF scale>=32 BREAK
  }

  x  := unit - d
  //writef("d    = %32b*n", d)
  //writef("unit = %32b scale=%n*n", unit, scale)
  xp := x                         // xp = x^1
  //writef("xp   = %32b*n", xp)
  q  := muldiv(q, unit+xp, unit)
  xp := muldiv(xp, xp, unit)     // xp = x^2
  //writef("xp   = %32b*n", xp)
  q  := muldiv(q, unit+xp, unit)
  xp := muldiv(xp, xp, unit)     // xp = x^4
  //writef("xp   = %32b*n", xp)
  q  := muldiv(q, unit+xp, unit)
  xp := muldiv(xp, xp, unit)     // xp = x^8
  //writef("xp   = %32b*n", xp)
  q  := muldiv(q, unit+xp, unit)
  xp := muldiv(xp, xp, unit)     // xp = x^16
  //writef("xp   = %32b*n", xp)
  q  := muldiv(q, unit+xp, unit)

  q := q>>scale   // Convert to unscaled integer
  result2 := n - q*d
  WHILE result2-d>=0 DO result2, q := result2-d, q+1
  RESULTIS q
}
