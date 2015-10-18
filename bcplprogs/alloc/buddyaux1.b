GET "libhdr"

LET start() = VALOF
{ LET layout = 0

  FOR i = 0 TO 255 DO
  { LET w = f(i)
    //writef("#x%x8", f(i))
    writef(" #b%b8_%b8_%b8_%b2_%b3_%b3, // %b8*n",
             w>>24, w>>16, w>>8, w>>6, w>>3, w, i)
    //IF i<255 DO wrch(',')
    layout := layout+1
    //IF layout REM 7 = 0 DO newline()
  }
  newline()
}

AND f(x) = VALOF
{ LET m1 = try1(x)
  LET sh1 = result2
  LET m2 = try2(x)
  LET sh2 = result2
  LET m3 = try4(x)
  LET sz1 = 0
  IF m1  DO sz1 := 1
  IF m2  DO sz1 := 2
  IF m3  DO sz1 := 3
  IF x=0 DO sz1 := 4
  RESULTIS m3<<24 | m2<<16 | m1<<8 | sh2<<5 | sh1<<3 | sz1
}

AND try1(x) = VALOF
{
  IF (x&#b00000001)=0 & (x&#b00000010)~=0 DO { result2 := 0; RESULTIS #b00000001 }
  IF (x&#b00000010)=0 & (x&#b00000001)~=0 DO { result2 := 1; RESULTIS #b00000010 }
  IF (x&#b00000100)=0 & (x&#b00001000)~=0 DO { result2 := 2; RESULTIS #b00000100 }
  IF (x&#b00001000)=0 & (x&#b00000100)~=0 DO { result2 := 3; RESULTIS #b00001000 }
  IF (x&#b00010000)=0 & (x&#b00100000)~=0 DO { result2 := 4; RESULTIS #b00010000 }
  IF (x&#b00100000)=0 & (x&#b00010000)~=0 DO { result2 := 5; RESULTIS #b00100000 }
  IF (x&#b01000000)=0 & (x&#b10000000)~=0 DO { result2 := 6; RESULTIS #b01000000 }
  IF (x&#b10000000)=0 & (x&#b01000000)~=0 DO { result2 := 7; RESULTIS #b10000000 }

  IF (x&#b00000001)=0 & (x&#b00001100)~=0 DO { result2 := 0; RESULTIS #b00000001 }
  IF (x&#b00000100)=0 & (x&#b00000011)~=0 DO { result2 := 2; RESULTIS #b00000100 }
  IF (x&#b00010000)=0 & (x&#b11000000)~=0 DO { result2 := 4; RESULTIS #b00010000 }
  IF (x&#b01000000)=0 & (x&#b00110000)~=0 DO { result2 := 6; RESULTIS #b01000000 }

  IF (x&#b00000001)=0 DO { result2 := 0; RESULTIS #b00000001 }
  IF (x&#b00010000)=0 DO { result2 := 4; RESULTIS #b00010000 }

  result2 := 0
  RESULTIS 0
}

AND try2(x) = VALOF
{
  IF (x&#b00000011)=0 & (x&#b00001100)~=0 DO { result2 := 0; RESULTIS #b00000011 }
  IF (x&#b00001100)=0 & (x&#b00000011)~=0 DO { result2 := 2; RESULTIS #b00001100 }
  IF (x&#b00110000)=0 & (x&#b11000000)~=0 DO { result2 := 4; RESULTIS #b00110000 }
  IF (x&#b11000000)=0 & (x&#b00110000)~=0 DO { result2 := 6; RESULTIS #b11000000 }

  IF (x&#b00000011)=0 DO { result2 := 0; RESULTIS #b00000011 }
  IF (x&#b00110000)=0 DO { result2 := 4; RESULTIS #b00110000 }

  result2 := 0
  RESULTIS 0
}

AND try4(x) = VALOF
{
  IF (x&#b00001111)=0 DO { result2 := 0; RESULTIS #b00001111 }
  IF (x&#b11110000)=0 DO { result2 := 4; RESULTIS #b11110000 }

  result2 := 0
  RESULTIS 0
}

