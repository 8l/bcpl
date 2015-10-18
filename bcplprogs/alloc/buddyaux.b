GET "libhdr"

LET start() = VALOF
{ LET layout = 0

  FOR i = 0 TO 255 DO
  { writef("#x%x8", f(i))
    //writef(" %b8: %bW*n", i, f(i))
    IF i<255 DO wrch(',')
    layout := layout+1
    IF layout REM 7 = 0 DO newline()
  }
  newline()
}

AND f(x) = VALOF
{ LET m1 = try(x, #b0001, 1)
  LET sh1 = result2
  LET m2 = try(x, #b0011, 2)
  LET sh2 = result2
  LET m3 = try(x, #b1111, 4)
  LET sz1 = 0
  IF m1  DO sz1 := 1
  IF m2  DO sz1 := 2
  IF m3  DO sz1 := 3
  IF x=0 DO sz1 := 4
  RESULTIS m3<<24 | m2<<16 | m1<<8 | sh1<<3 | sh2<<5 | sz1
}

AND try(x, m, size) = VALOF
{ result2 := 0
  { IF (x & m)=0 RESULTIS m
    m, result2 := m<<size, result2+size
  } REPEATWHILE result2<8
  result2 := 0
  RESULTIS 0
}

