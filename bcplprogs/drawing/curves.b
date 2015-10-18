SECTION "curves"

GET "libhdr"

GLOBAL $( sysin:      300
          sysout:     301

          imagevec:   302

          cur.x:      303
          cur.y:      304

          baseaddr:   305
          refcount:   306
          seed:       307

          ptr:        308
       $)

MANIFEST $( rowbit_len   = 1400
            colbit_len   = 1100

            chrows       = colbit_len / 24 + 1
            chcols       = rowbit_len / 24 + 1

            colbytes     = 3 * chrows
            
            rowbit_upb   = rowbit_len - 1
            colbit_upb   = colbit_len - 1
            colbyte_upb  = colbytes - 1

            imagevec_upb = ((colbytes)*(rowbit_len) - 1)/bytesperword

            ESC = 27

            vecupb = 3000
            items  = 2000
            refsperline = 100
         $)


LET start() BE
$( LET v0 = VEC imagevec_upb

   imagevec := v0

   FOR i = 0 TO imagevec_upb DO imagevec!i := 0

   sysin  := input()
   sysout := output()

   initlq1500()

   pic()

   selectoutput(sysout)
   writes("*nEnd of output*n")
$)

AND outimage() BE FOR row = 0 TO chrows - 1 DO
$( LET len = 1
   LET p   = row * 3


   FOR i = 1 TO rowbit_len DO
   $( UNLESS imagevec%p=0 & imagevec%(p+1)=0 & imagevec%(p+2)=0 DO
             len := i
      p := p + colbytes
   $)

   p := row * 3

   wrpch(ESC); wrpch('**'); wrpch(39)
   wrpch(len REM 256)
   wrpch(len / 256)
   FOR i = 1 TO len DO
   $( wrpch(imagevec%p)
      wrpch(imagevec%(p+1))
      wrpch(imagevec%(p+2))
      p := p + colbytes
   $)
   wrpstr("*n")
$)


AND point(x, y) BE 
$( LET p   = x * colbytes + y / 8
   AND bit = 1 << 7 - (y & 7)
   IF 0<=x<=rowbit_upb & 0<=y<=colbit_upb DO
   $( imagevec%p := imagevec%p | bit
//      IF x REM 50 = 0 DO writef("x%N y%N*n", x, y)
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

AND wrpn(n) BE
$( IF n>9 DO wrpn(n/10)
   wrpch(n REM 10 + '0')
$)


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
$( LET v = VEC vecupb

   baseaddr := v
   refcount := 0
   seed := 12345

   moveto(300, 500)

   dragon(2)

   outimage()

   wrpstr("*n*n")
$)


AND dragon(size) BE FOR i = 0 TO #XFFFF DO
    SWITCHON bits(gray(i)) & 3 INTO
    $( CASE 0: drawby(size, 0);  ENDCASE  // right
       CASE 1: drawby(0,  size); ENDCASE  // up
       CASE 2: drawby(-size, 0); ENDCASE  // left
       CASE 3: drawby(0, -size); ENDCASE  // down
    $)

AND gray(n) = n NEQV n>>1

AND bits(w) = w=0 -> 0, 1 + bits(w & (w-1))






