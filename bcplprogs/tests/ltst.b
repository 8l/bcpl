GET "libhdr"

GLOBAL $( count:200; byte:201; outstr:202
pxlsize: 203
dotxsize: 204
dotysize: 205
xupb: 206; xlo: 207; xhi: 208
yupb: 209; ylo: 210; yhi: 211
mag: 212
datalen: 213
$)
 
// For datalen=2, pxlsize=3, dotxsize=2, dotysize=1,
// the frame is as follows:
//
//     * * * * * * * * * * * * * * * * *  1
//     * * * * * * * * * * * * * * * * *
//     * * * * * * * * * * * * * * * * *
//     * * *                       * * *
//     * * *                       * * *
//     * * *       -----------     * * *  ylo
//     * * *      |a a   b b  |    * * *
//     * * *      |           |    * * *
//     * * *      |           |    * * *
//     * * *      |c c   d d  |    * * *
//     * * *      |           |    * * *
//     * * *      |           |    * * *  yhi
//     * * *       -----------     * * *
//     * * * * * * * * * * * * * * * * *
//     * * * * * * * * * * * * * * * * *
//     * * * * * * * * * * * * * * * * *  yupb
//     1           x         x         x
//                 l         h         u
//                 o         i         p
//                                     b

LET ranbit() = VALOF
$( STATIC $( seed = 12345 $)
   seed := seed*2147001325 + 715136305
   RESULTIS (seed>>24) & 1
$)

LET start() BE
$( LET argv = VEC 50
   LET v = 0
   LET sysout = output()

   IF rdargs("X,Y,PXLSIZE,DATATLEN,MAG,TO/K", argv, 50)=0 DO
   $( writes("Bad argument*n")
      RETURN
   $)

   datalen := 256
   mag := 1
   pxlsize := 3
   dotxsize := 2
   dotysize := 1

   UNLESS argv!0=0 DO dotxsize := str2numb(argv!0)
   UNLESS argv!1=0 DO dotysize := str2numb(argv!1)
   UNLESS argv!2=0 DO pxlsize  := str2numb(argv!2)
   UNLESS argv!3=0 DO datalen  := str2numb(argv!3)
   UNLESS argv!4=0 DO mag      := str2numb(argv!4)

   xupb := (2+datalen+1)*pxlsize + dotxsize
   xlo := 1    + 2*pxlsize
   xhi := xupb - pxlsize - dotxsize
   yupb := xupb
   ylo  := xlo
   yhi  := xhi

   v := getvec(yupb)

   IF argv!5=0 DO argv!5 := "test.ps"

   outstr := findoutput(argv!5)
   IF outstr=0 DO
   $( writef("Trouble with file %s*n", argv!5)
      RETURN
   $)

   selectoutput(outstr)

   wrl("%%!PS-Adobe-0.0")

   wrl("/Courier findfont")
   wrl("50 scalefont setfont")

   wrl("/pl { dup")
   wrl("      length 8 mul 1 true [ 1 0 0 1 0 0 ]")
   wrl("      4 index")
   wrl("      imagemask")
   wrl("      pop")
   wrl("      0 -1 translate")
   wrl("    } bind def")


   wrl("72 300 div dup scale")
   wrl("100 3000 translate")
   wrl("0 50 moveto")

   writef("(dot size %nx%n in %nx%n square,  mag = %n) show*n",
            dotxsize, dotysize, pxlsize, pxlsize, mag)

   writef("%n %n scale*n", mag, mag)

   FOR x = 1 TO xupb DO v%x := 1
   FOR i = 1 TO pxlsize DO outrow(v, xupb)

   FOR x = 1+pxlsize TO xupb-pxlsize DO v%x := 0
   FOR i = 1 TO pxlsize DO outrow(v, xupb)

   FOR y = 1 TO datalen DO 
   $( FOR x = 0 TO datalen-1 DO
      $( LET bit = ranbit()
         LET i = xlo + x*pxlsize
         FOR j = i          TO i+dotxsize-1 DO v%j := bit
         FOR j = i+dotxsize TO i+pxlsize    DO v%j := 0
      $)

      FOR i = 1 TO dotysize DO outrow(v, xupb)
      FOR x = xlo TO xhi DO v%x := 0
      FOR i= dotysize+1 TO pxlsize DO outrow(v, xupb)
   $)

   FOR i = 1 TO dotysize DO outrow(v, yupb)

   FOR x = 1+pxlsize TO xupb-pxlsize DO v%x := 1
   FOR i = 1 TO pxlsize DO outrow(v, xupb)

   wrl("*nshowpage")

   UNLESS sysout=output() DO endwrite()
$)

AND wrl(s) BE writef("%s*n", s)

AND outrow(v, upb) BE
$( writes("<*n")
   count, byte := 0, 0
   FOR i = 1 TO upb DO wrbit(v%i)
   UNTIL count REM 8 = 0 DO wrbit(0)
   writes(">pl")
$)

AND wrbit(b) BE
$( count, byte := count+1, byte<<1 | b
   UNLESS count REM 8 = 0 RETURN
   writef("%x2", byte) 
   IF count REM 256 = 0 DO newline()
   byte := 0
$)
   





