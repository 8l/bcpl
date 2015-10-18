GET "libhdr"

LET start() = VALOF
{ LET x, xs, y, ys, z, zs = 1, 16, 1, 8, 1, 20
  LET a, r = 0, 0
  LET m64 = (1<<x) > 0 // =TRUE if running on a 64-bit system
  LET argv = VEC 50

  UNLESS rdargs("x/n,xs/n,y/n,ys/n,z/n,zs/n", argv, 50) DO
  { writef("Bad arguments for tstmuldivbits*n")
    RESULTIS 0
  }

  IF argv!0 DO x  := !(argv!0)
  IF argv!1 DO xs := !(argv!1)
  IF argv!2 DO y  := !(argv!2)
  IF argv!3 DO ys := !(argv!3)
  IF argv!4 DO z  := !(argv!4)
  IF argv!5 DO zs := !(argv!5)

  a := muldiv(x<<xs, y<<ys, z<<zs)
  r := result2

  TEST m64
  THEN { writef("%16x x %16x / %16x =>*n", x<<xs, y<<ys, z<<zs) 
         writef("%16x            remainder %16x*n", a, r)
       }
  ELSE { writef("%8x x %8x / %8x =>*n", x<<xs, y<<ys, z<<zs) 
         writef("%8x    remainder %8x*n", a, r)
       }

  RESULTIS 0
}
