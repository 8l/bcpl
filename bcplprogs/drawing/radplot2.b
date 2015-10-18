SECTION "randplot2"

GET "libhdr"

GLOBAL $( sysin:      300
          sysout:     301

          imagevec:   302

          cur.x:      303
          cur.y:      304

          baseaddr:   305
          refcount:   306
          seed1:      307
          seed2:      308

          ptr:        309
       $)

MANIFEST $( rowbit_len   = 1000
            colbit_len   = 1000

            chrows       = colbit_len / 24 + 1
            chcols       = rowbit_len / 24 + 1

            colbytes     = 3 * chrows
            
            rowbit_upb   = rowbit_len - 1
            colbit_upb   = colbit_len - 1
            colbyte_upb  = colbytes - 1

            imagevec_upb = ((colbytes)*(rowbit_len) - 1)/bytesperword

            ESC = 27

            vecupb = 8004
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
$( moveto(0, 0)
   drawby(0, colbit_upb)
   drawby(rowbit_upb, 0)
   drawby(0, -colbit_upb)
   drawby(-rowbit_upb, 0)

   seed1 := 12345
   seed2 := 23456
   FOR x = 0 TO 999 DO
   $( writef("x = %I3*n", x)
      FOR y = 0 TO 999 TEST 500<=x<=500+31 & 500<=y<=500+31
                       THEN IF randno1(10000)>9000 DO point(x,y)
                       ELSE IF randno2(10000)>9500 DO point(x,y)
   $)

   outimage()

   wrpstr("*n*n")
$)

AND randno1(upb) = VALOF
$( seed1 := 2147001325 * seed1 + 715136305
   RESULTIS (seed1/3 >> 1) REM upb + 1
$)

AND randno2(upb) = VALOF
$( seed2 := 2147001325 * seed2 + 715136305
   RESULTIS (seed2/3 >> 1) REM upb + 1
$)






