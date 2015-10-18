GET "libhdr"

GLOBAL {
 x:ug
 y
 z
 v
}

LET h() BE
{ IF x>y DO { x := 1 <> y := 2 REPEATUNTIL x<y }
         <> z:=3
  RETURN
}

LET start() = VALOF
{ //x, y, z := 1.2, 1234.5678e-5, 1000e-3
  x, y, z := 111, 222, 333
/*
  x := x #* y #/ z
  x := x #+ y #- z
  x := #- 1.2
  x := y #= z
  x := y #~= z
  x := y #< z
  x := y #> z
  x := y #<= z
  x := y #>= z
*/
  x := FLOAT 12345
  //x := FIX 1234.5678
  newline()
  RESULTIS 0
}

AND f() = VALOF
{ 
  x, y !:= 1, 2
  x #*:= 2.3
  x #/:= 2.3
  x *:= 2
  x /:= 2
  x MOD:= 2
  x #+:= 2.3
  x #-:= 2.3
  x +:= 2
  x -:= 3

  RESULTIS "*n*p*s*t"
}

AND g() = VALOF
{ 
  x <<:= 2
  x >>:= 3
  x &:= 7
  x |:= 5
  x EQV:= 5
  x XOR:= 5

  RESULTIS "hello there*n"
}
