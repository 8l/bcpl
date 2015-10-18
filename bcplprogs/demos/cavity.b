SECTION "cavity"
 
GET "libhdr"
 
MANIFEST $( upb      = 10
            len      = upb+1
            datavupb = len*len-1
$)
 
GLOBAL $( datav:200;  datat:201
$)
 
LET cav2() = VALOF
$( LET count = 0
   FOR p = datav+len TO datat-len UNTIL !p=0 DO
   $( LET w = !p
      LET bit = w & -w
      fillin(p, bit)
      count := count + 1
   $)
   RESULTIS count
$)
 
AND fillin(p, bit) BE UNLESS (!p & bit) = 0 DO
$( !p := !p - bit
   fillin(p-1,   bit)
   fillin(p+1,   bit)
   fillin(p-len, bit)
   fillin(p+len, bit)
   fillin(p,     bit<<1)
   fillin(p,     bit>>1)
$)
 
GLOBAL $( point: 250;  north: 251;  west: 252;  pos: 253  $)
 
MANIFEST $( solid = TRUE;  cavity = FALSE  $)
 
LET nextpt() = VALOF
$( LET bitpos  = pos REM len
   AND word    = pos / len
   pos := pos + 1
   RESULTIS (datav!word & 1<<bitpos) = 0
$)
 
LET cav1() = VALOF
$( LET cavcount, nextid = 0, 1
   LET v = VEC len*len

   point := v  //   point := getvec(len*len)
   west  := point - 1
   north := point - len
   pos   := 0
 
   FOR p = 0 TO len*len DO point!p := 0
 
   FOR plane = 0 TO upb DO FOR p = 0 TO len*len-1 TEST nextpt()=solid
      THEN point!p := 0
      ELSE $( LET pointid = nextid
              AND a = point!p
              AND b = north!p
              AND c = west!p
 
              IF 0<a         DO pointid := a
              IF 0<b<pointid DO pointid := b
              IF 0<c<pointid DO pointid := c
 
              TEST pointid=nextid
              THEN $( nextid := nextid + 1
                      cavcount := cavcount + 1
                   $)
              ELSE $( IF a>pointid       DO $( rename(a, pointid)
                                               cavcount := cavcount-1
                                            $)
                      IF north!p>pointid DO $( rename(b, pointid)
                                               cavcount := cavcount-1
                                            $)
                      IF west!p >pointid DO $( rename(c, pointid)
                                               cavcount := cavcount-1
                                            $)
                   $)
               point!p := pointid
            $)
 
   RESULTIS cavcount
$)
 
AND rename(oldid, newid) BE
   FOR p = point TO point+len*len DO
       IF !p=oldid DO !p := newid
 
 
LET start() = VALOF
$( LET v = VEC datavupb
   
   writes("Cavity problem*n")
 
   datav := v  // getvec(datavupb)
   datat := datav + datavupb
 
   setdata(10); pr()
   setdata(20); pr()
   setdata(30); pr()
   setdata(40); pr()
   setdata(50); pr()
   RESULTIS 0
$)
 
AND setdata(proportion) BE
$( FOR p = datav TO datat DO !p := 0
   FOR i = 1 TO upb-1 DO
       FOR j = 1 TO upb-1 DO
       $( LET p = datav + i*len + j
          FOR bit = 1 TO upb-1 DO
             IF randno(100)<proportion DO !p := !p | 1<<bit
       $)
$)
 
AND random(n) =  2147001325*n + 715136305

AND randno(upb) = VALOF
$( STATIC $( seed=32415  $)
   seed := random(seed)
   RESULTIS (seed/3 >> 1) REM upb + 1
$)
 
AND pr() BE
$( FOR i = 0 TO upb DO
   $( FOR j = 0 TO upb DO
      $( LET p = datav + i*len + j
         FOR bit = 0 TO upb DO writes((!p & 1<<bit)=0 -> ". ", "** ")
         newline()
      $)
      newline()
   $)
   newline()
   writef("Number of cavities (by cav1) is %n*n*n", cav1())
   writef("Number of cavities (by cav2) is %n*n*n", cav2())
$)
 
