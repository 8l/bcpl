SECTION "hamming"

GET "libhdr"

MANIFEST { upb=100 }

LET new(args) BE
{ LET p, nx2, nx3, nx5 = args!0, args!1, args!2, args!3
  LET x2, x3, x5 = 1, 1, 1
  cowait()        // End of initialisation.

  { LET val = x2<x3 -> (x2<x5 -> x2, x5),
                       (x3<x5 -> x3, x5)
    IF intflag() DO abort(98)
    cowait(val)  // Return next value.
    !p := val
    p := p+1
    IF val=x2 DO x2 := callco(nx2)
    IF val=x3 DO x3 := callco(nx3)
    IF val=x5 DO x5 := callco(nx5)
  } REPEAT
}

AND mul(args) BE
{ LET p, k = args!0, args!1
  cowait()      // End of initialisation.
   
  { cowait(k * !p)  // Return next value
    p := p+1
  } REPEAT
}

LET start() = VALOF
{ LET v    = getvec(upb)
  LET nx2  = initco(mul, 100, v, 2)
  LET nx3  = initco(mul, 100, v, 3)
  LET nx5  = initco(mul, 100, v, 5)
  LET next = initco(new, 100, v, nx2, nx3, nx5)
   
  FOR i = 1 TO upb DO { writef(" %i6", callco(next))
                        IF i REM 10 = 0 DO newline()
                      }

  deleteco(nx2); deleteco(nx3); deleteco(nx5); deleteco(next)
  freevec(v)
  RESULTIS 0
}

