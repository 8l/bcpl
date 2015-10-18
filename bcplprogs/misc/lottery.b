GET "libhdr"

STATIC $( count = 0  $)

LET start() = VALOF
$( LET v = VEC 49

   FOR i = 1 TO 49 DO v!i := i

   FOR i = 1 TO 6 DO
   $( LET r = i + randno(49-i)
      LET t = v!i
      v!i := v!r
      v!r := t
   $)

   FOR p = 2 TO 6 DO  // Now perform insertion sort.
     FOR q = v+p-1 TO v+1 BY -1 TEST q!0<=q!1 
                                THEN BREAK
                                ELSE $( LET t = q!0
                                        q!0 := q!1
                                        q!1 := t
                                     $)

   FOR i = 1 TO 6 DO writef(" %i2", v!i)
   newline()

   count := count + 1

//   search(v!1, v!2, v!3, v!4, v!5, v!6)

   IF count>=50 RESULTIS 0
$) REPEAT

AND bits(w) = w=0 -> 0, 1 + bits(w & (w-1))
   
AND search(n1, n2, n3, n4, n5, n6) BE
$( LET lb, hb = 0, 0
   LET count = 0
   LET hist = VEC 6
   FOR i = 0 TO 6 DO hist!i := 0

   TEST n1>32 DO hb := hb + (1<<(n1-32)) ELSE lb := lb + (1<<(n1-1)) 
   TEST n2>32 DO hb := hb + (1<<(n2-32)) ELSE lb := lb + (1<<(n2-1)) 
   TEST n3>32 DO hb := hb + (1<<(n3-32)) ELSE lb := lb + (1<<(n3-1)) 
   TEST n4>32 DO hb := hb + (1<<(n4-32)) ELSE lb := lb + (1<<(n4-1)) 
   TEST n5>32 DO hb := hb + (1<<(n5-32)) ELSE lb := lb + (1<<(n5-1)) 
   TEST n6>32 DO hb := hb + (1<<(n6-32)) ELSE lb := lb + (1<<(n6-1)) 

   writef("hb = %x8  lb = %x8*n", hb, lb)
 
   writef("Case 0 greater than 32*n")
   FOR a = 0   TO 26 DO
   FOR b = a+1 TO 27 DO
   FOR c = b+1 TO 28 DO
   FOR d = c+1 TO 29 DO
   FOR e = d+1 TO 30 DO
   FOR f = e+1 TO 31 DO
   $( LET lbits = (1<<a)|(1<<b)|(1<<c)|(1<<d)|(1<<e)|(1<<f)
      LET i = bits(lbits & lb)
      hist!i := hist!i + 1
   $)

   writef("Case 1 greater than 32*n")
   FOR a = 0   TO 27 DO
   FOR b = a+1 TO 28 DO
   FOR c = b+1 TO 29 DO
   FOR d = c+1 TO 30 DO
   FOR e = d+1 TO 31 DO
   $( LET lbits = (1<<a)|(1<<b)|(1<<c)|(1<<d)|(1<<e)
      LET lk = bits(lbits & lb)
      FOR f = 0 TO 16 DO
      $( LET hbits = (1<<f)
         LET i = lk + bits(hbits & hb)
         hist!i := hist!i + 1
      $)
   $)

   writef("Case 2 greater than 32*n")
   FOR a = 0   TO 28 DO
   FOR b = a+1 TO 29 DO
   FOR c = b+1 TO 30 DO
   FOR d = c+1 TO 31 DO
   $( LET lbits = (1<<a)|(1<<b)|(1<<c)|(1<<d)
      LET lk = bits(lbits & lb)
      FOR e = 0   TO 15 DO
      FOR f = e+1 TO 16 DO
      $( LET hbits = (1<<e)|(1<<f)
         LET i = lk + bits(hbits & hb)
         hist!i := hist!i + 1
      $)
   $)

   writef("Case 3 greater than 32*n")
   FOR a = 0   TO 29 DO
   FOR b = a+1 TO 30 DO
   FOR c = b+1 TO 31 DO
   $( LET lbits = (1<<a)|(1<<b)|(1<<c)
      LET lk = bits(lbits & lb)
      FOR d = 0   TO 14 DO
      FOR e = d+1 TO 15 DO
      FOR f = e+1 TO 16 DO
      $( LET hbits = (1<<d)|(1<<e)|(1<<f)
         LET i = lk + bits(hbits & hb)
         hist!i := hist!i + 1
      $)
   $)

   writef("Case 4 greater than 32*n")
   FOR a = 0   TO 30 DO
   FOR b = a+1 TO 31 DO
   $( LET lbits = (1<<a)|(1<<b)
      LET lk = bits(lbits & lb)
      FOR c = 0   TO 13 DO
      FOR d = c+1 TO 14 DO
      FOR e = d+1 TO 15 DO
      FOR f = e+1 TO 16 DO
      $( LET hbits = (1<<c)|(1<<d)|(1<<e)|(1<<f)
         LET i = lk + bits(hbits & hb)
         hist!i := hist!i + 1
      $)
   $)

   writef("Case 5 greater than 32*n")
   FOR a = 0   TO 31 DO
   $( LET lbits = (1<<a)
      LET lk = bits(lbits & lb)
      FOR b = 0   TO 12 DO
      FOR c = b+1 TO 13 DO
      FOR d = c+1 TO 14 DO
      FOR e = d+1 TO 15 DO
      FOR f = e+1 TO 16 DO
      $( LET hbits = (1<<b)|(1<<c)|(1<<d)|(1<<e)|(1<<f)
         LET i = lk + bits(hbits & hb)
         hist!i := hist!i + 1
      $)
   $)

   writef("Case 6 greater than 32*n")
   $( LET lbits = 0
      LET lk = bits(lbits & lb)
      FOR a = 0   TO 11 DO
      FOR b = a+1 TO 12 DO
      FOR c = b+1 TO 13 DO
      FOR d = c+1 TO 14 DO
      FOR e = d+1 TO 15 DO
      FOR f = e+1 TO 16 DO
      $( LET hbits = (1<<a)|(1<<b)|(1<<c)|(1<<d)|(1<<e)|(1<<f)
         LET i = lk + bits(hbits & hb)
         hist!i := hist!i + 1
      $)
   $)

   writef("Total number of permutations is %n*n*n", count)
   writef("It should be                    %n*n*n", 
           44/1*45/2*46/3*47/4*48/5*49/6)

   FOR i = 0 TO 6 DO writef("%n numbers correct %i7 times*n", i, hist!i)

$)

