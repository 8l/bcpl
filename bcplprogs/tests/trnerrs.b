// This is a BCPL program designed to test the
// translation phase error messages of the BCPL compiler.

GLOBAL $( g200:200; g201:201  $)

STATIC $( S1=0; s2=0  $)

MANIFEST $( m1=1; m2=2  $)

LET start() BE
$( LET a, b, c, d = 1, 2, 3, 4

   trans()
$)

AND trans() BE
$( LET x, y, z = 1, 2, 3
   LET p, q = 5, 6, 7
   UNTIL x=0 DO
   $( IF x=0 BREAK
      IF y=0 LOOP
      IF z=0 FINISH
      IF g200=0 ENDCASE
      IF g201=0 RESULTIS 1234
      
      CASE 12345:
       
      x := 1
       
      DEFAULT:
      x:=2
      SWITCHON x INTO
      $( CASE 1:
         CASE 2:
         DEFAULT:
         CASE 3:
         CASE 1+1:
         DEFAULT: ENDCASE
      $)
       
      x:= x-1
   $)
    
   $( LET aaa,bbb,ccc,aaa = 1,2,3,4
      AND bbb = 5
      LET f(p,q) = x*p + g201+y
      x := @(x+1)
      x := @ m1
      FOR i = 1 TO 10 BY 3/(m1-1) DO x := x+1
      x,y := 1
      x,y := 1,2,3
   $)
$)

