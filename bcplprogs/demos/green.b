GET"libhdr"

LET start() BE
$( LET a,b,c,d,e,f,g,h = 0,0,0,0,0,0,0,1

   FOR day = 1 TO 28 DO
   $( h := h+g
      g := f
      f := e
      e := d
      d := c
      c := b
      b := a
      a := 8 * h
     
      writef("number of greenfly at end of day %N is %I8*N",
              day, a+b+c+d+e+f+g+h)
   $)
$)

