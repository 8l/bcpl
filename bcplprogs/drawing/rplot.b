SECTION "rplot"

GET "libhdr"

GLOBAL $( sysin:      300
          sysout:     301

          imagevec:   302

          cur.x:      303
          cur.y:      304
       $)

MANIFEST $( rowbit_len   = 1100
            colbit_len   = 1100
            chrows       = rowbit_len / 24 + 1
            chcols       = colbit_len / 24 + 1
            colbytes     = 3 * chcols
            
            rowbit_upb   = rowbit_len - 1
            colbit_upb   = colbit_len - 1
            colbyte_upb  = colbytes - 1

            imagevec_upb = (colbytes)*(rowbit_len) - 1

            ESC = 27
         $)


LET start() BE
$( LET v0 = VEC imagevec_upb/bytesperword

   imagevec := v0

   FOR i = 0 TO colbytes * rowbit_len - 1 DO imagevec%i := 0

   sysin  := input()
   sysout := output()

   initlq1500()

   pic()

   outimage()

   wrpstr("*nEnd of output*n")

   selectoutput(sysout)
   writes("*nEnd of output*n")
$)

AND outimage() BE FOR col = 0 TO chcols - 1 DO
$( LET p = col * 3
   wrpch(ESC); wrpch('**'); wrpch(39)
   wrpch(rowbit_len REM 256)
   wrpch(rowbit_len / 256)
   FOR i = 0 TO rowbit_upb DO
   $( wrpch(imagevec%p & 255)
      wrpch(imagevec%(p+1) & 255)
      wrpch(imagevec%(p+2) & 255)
      p := p + colbytes
   $)
   wrpstr("*n")
$)


AND point(x, y) BE 
$( LET p   = x * colbytes + y / 8
   AND bit = 1 << 7 - (y & 7)
   IF 0<=x<=rowbit_upb & 0<=y<=colbit_upb DO
   $( imagevec%p := imagevec%p | bit
      writef("x%N y%N*n", x, y)
   $)
   cur.x, cur.y := x, y
$)  

AND moveto(x, y) BE cur.x, cur.y := x, y

AND moveby(x, y) BE cur.x, cur.y := cur.x + x, cur.y + y

AND drawto(x, y) BE
$( LET mx, my = (x+cur.x)/2, (y+cur.y)/2
   TEST (mx=x | mx=cur.x) & (my=y | my=cur.y)
   THEN point(x, y)
   ELSE $( drawto(mx, my)
           drawto(x, y)
        $)
   cur.x, cur.y := x, y
$)

AND drawby(x, y) BE drawto(cur.x+x, cur.y+y)

AND initlq1500() BE
$( wrpch(27); wrpch('@')  // initialise printer

   wrpch(27); wrpch('x'); wrpch(1)  // select NLQ mode

   wrpch(27); wrpch('3'); wrpch(24) // set line spacing to 24
$)

AND wrpstr(s) BE FOR i = 1 TO s%0 TEST s%i='*n'
   THEN $( wrpch(13)
           wrpch(10)
        $)
   ELSE wrpch(s%i)


AND wrpch(ch) BE
$( wrbch(27)                   // ESC
   TEST 32<=ch<96
   THEN wrbch(ch)
   ELSE $( LET n1 = ch>>4 & 15
           AND n2 = ch    & 15
           wrbch(#x70+n1)
           wrbch(#x60+n2)
        $)
$)

AND pic() BE
$( moveto(0, 0)
   drawby(1024, 0)
   drawby(0, 1023)
   drawby(-1024, 0)
   drawby(0, -1023)
   
   quad(1024, 0, 0)
$)

 
AND bits(w) = w=0 -> 0, 1 + bits(w & (w-1))

AND gray(n) = n NEQV n>>1

AND dragon(size) BE FOR i = 0 TO 1023 DO
    SWITCHON bits(gray(i)) & 3 INTO
    $( CASE 0: drawby(size, 0); ENDCASE
       CASE 1: drawby(0, size); ENDCASE
       CASE 2: drawby(-size, 0); ENDCASE
       CASE 3: drawby(0, -size); ENDCASE
    $)       

AND quad(size, x, y) BE
$( LET a, b = x+size, y+size
   LET s = size>>1
   LET mx, my = x+s, y+s
   LET r2 = 160000


   IF s < 1 RETURN

   TEST (mx-512)*(mx-512)+(my-512)*(my-512) > r2
   THEN IF (x-512)*(x-512)+(y-512)*(y-512)  > r2 &
           (x-512)*(x-512)+(b-512)*(b-512)  > r2 &
           (a-512)*(a-512)+(y-512)*(y-512)  > r2 &
           (a-512)*(a-512)+(b-512)*(b-512)  > r2 RETURN
   ELSE IF (x-512)*(x-512)+(y-512)*(y-512) <= r2 &
           (x-512)*(x-512)+(b-512)*(b-512) <= r2 &
           (a-512)*(a-512)+(y-512)*(y-512) <= r2 &
           (a-512)*(a-512)+(b-512)*(b-512) <= r2 RETURN

   moveto(mx, y)
   drawby(0, size)
   moveto(x, my)
   drawby(size, 0)

   quad(s, x, my)
   quad(s, mx, my)
   quad(s, mx, y)
   quad(s, x, y)
$)







