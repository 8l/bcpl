SECTION "draw"

GET "libhdr"

GLOBAL $( cur.x : 200
          cur.y : 201
$)

LET wrbyte(ch) BE
$( TEST 32<=ch<96
   THEN wrbch(ch)
   ELSE $( LET n1 = ch>>4 & 15
           AND n2 = ch    & 15
           wrbch(#x70+n1)
           wrbch(#x60+n2)
        $)
$)

LET start() BE
$( LET tty = findoutput("/dev/tty")

   IF tty=0 DO
   $( writef("Trouble with /dev/tty*n")
      RETURN
   $)

   selectoutput(tty)

   wrbch(12)  // clear text area
 
   moveto(0, 0)
   drawby(1024, 0)
   drawby(0, 1023)
   drawby(-1024, 0)
   drawby(0, -1023)
   
   quad(1024, 0, 0)
$)

AND plot(k, x, y) BE
$( wrbch(25)
   wrbyte(k)
   wrbyte(x & 255)
   wrbyte(x>>8 & 255)
   wrbyte(y & 255)
   wrbyte(y>>8 & 255)
$)

AND moveto(x, y) BE
$( cur.x, cur.y := x, y
   plot(4, cur.x, cur.y)
$)

AND drawto(x, y) BE
$( cur.x, cur.y := x, y
   plot(5, cur.x, cur.y)
$)

AND moveby(x, y) BE moveto(cur.x + x, cur.y + y)

AND drawby(x, y) BE drawto(cur.x + x, cur.y + y)

 
AND bits(w) = w=0 -> 0, 1 + bits(w & (w-1))

AND gray(n) = n NEQV n>>1

AND dragon(size) BE FOR i = 0 TO 1023 DO
    SWITCHON bits(gray(i)) & 3 INTO
    $( CASE 0: drawby(size, 0); ENDCASE
       CASE 1: drawby(0, size); ENDCASE
       CASE 2: drawby(-size, 0); ENDCASE
       CASE 3: drawby(0, -size); ENDCASE
    $)       

AND quad(size, x, y) = VALOF
$( LET a, b = x+size, y+size
   LET s = size>>1
   LET mx, my = x+s, y+s
   LET r2 = 160000

   IF s < 4 DO
   $( TEST (mx-512)*(mx-512)+(my-512)*(my-512) > r2
      THEN IF (x-512)*(x-512)+(y-512)*(y-512)  > r2 &
              (x-512)*(x-512)+(b-512)*(b-512)  > r2 &
              (a-512)*(a-512)+(y-512)*(y-512)  > r2 &
              (a-512)*(a-512)+(b-512)*(b-512)  > r2 RESULTIS FALSE
      ELSE IF (x-512)*(x-512)+(y-512)*(y-512) <= r2 &
              (x-512)*(x-512)+(b-512)*(b-512) <= r2 &
              (a-512)*(a-512)+(y-512)*(y-512) <= r2 &
              (a-512)*(a-512)+(b-512)*(b-512) <= r2 RESULTIS FALSE
     RESULTIS TRUE
   $)

   IF (quad(s, x, y) | quad(s, mx, my) | quad(s, mx, y) | quad(s, x, my))=TRUE DO
   $( moveto(mx, y)
      drawby(0, size)
      moveto(x, my)
      drawby(size, 0)
      RESULTIS TRUE
   $)
   RESULTIS FALSE
$)

