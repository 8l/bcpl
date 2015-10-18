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

   search(v!1, v!2, v!3, v!4, v!5, v!6)

   IF count>=1 RESULTIS 0
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
   $( LET ak =      (lb>>a & 1)
      FOR b = a+1 TO 27 DO
      $( LET bk = ak + (lb>>b & 1)
         FOR c = b+1 TO 28 DO
         $( LET ck = bk + (lb>>c & 1)
            FOR d = c+1 TO 29 DO
            $( LET dk = ck + (lb>>d & 1)
               FOR e = d+1 TO 30 DO
               $( LET ek = dk + (lb>>e & 1)
                  FOR f = e+1 TO 31 DO
                  $( LET fk = ek + (lb>>f & 1)
                     hist!fk := hist!fk + 1
                  $)
               $)
            $)
         $)
      $)
   $)

   writef("Case 1 greater than 32*n")
   FOR a = 0   TO 27 DO
   $( LET ak =      (lb>>a & 1)
      FOR b = a+1 TO 28 DO
      $( LET bk = ak + (lb>>b & 1)
         FOR c = b+1 TO 29 DO
         $( LET ck = bk + (lb>>c & 1)
            FOR d = c+1 TO 30 DO
            $( LET dk = ck + (lb>>d & 1)
               FOR e = d+1 TO 31 DO
               $( LET ek = dk + (lb>>e & 1)
                  FOR f = 0   TO 16 DO
                  $( LET fk = ek + (hb>>f & 1)
                     hist!fk := hist!fk + 1
                  $)
               $)
            $)
         $)
      $)
   $)

   writef("Case 2 greater than 32*n")
   FOR a = 0   TO 28 DO
   $( LET ak =      (lb>>a & 1)
      FOR b = a+1 TO 29 DO
      $( LET bk = ak + (lb>>b & 1)
         FOR c = b+1 TO 30 DO
         $( LET ck = bk + (lb>>c & 1)
            FOR d = c+1 TO 31 DO
            $( LET dk = ck + (lb>>d & 1)
               FOR e = 0   TO 15 DO
               $( LET ek = dk + (hb>>e & 1)
                  FOR f = e+1 TO 16 DO
                  $( LET fk = ek + (hb>>f & 1)
                     hist!fk := hist!fk + 1
                  $)
               $)
            $)
         $)
      $)
   $)

   writef("Case 3 greater than 32*n")
   FOR a = 0   TO 29 DO
   $( LET ak =      (lb>>a & 1)
      FOR b = a+1 TO 30 DO
      $( LET bk = ak + (lb>>b & 1)
         FOR c = b+1 TO 31 DO
         $( LET ck = bk + (lb>>c & 1)
            FOR d = 0   TO 14 DO
            $( LET dk = ck + (hb>>d & 1)
               FOR e = d+1 TO 15 DO
               $( LET ek = dk + (hb>>e & 1)
                  FOR f = e+1 TO 16 DO
                  $( LET fk = ek + (hb>>f & 1)
                     hist!fk := hist!fk + 1
                  $)
               $)
            $)
         $)
      $)
   $)

   writef("Case 4 greater than 32*n")
   FOR a = 0   TO 30 DO
   $( LET ak =      (lb>>a & 1)
      FOR b = a+1 TO 31 DO
      $( LET bk = ak + (lb>>b & 1)
         FOR c = 0   TO 13 DO
         $( LET ck = bk + (hb>>c & 1)
            FOR d = c+1 TO 14 DO
            $( LET dk = ck + (hb>>d & 1)
               FOR e = d+1 TO 15 DO
               $( LET ek = dk + (hb>>e & 1)
                  FOR f = e+1 TO 16 DO
                  $( LET fk = ek + (hb>>f & 1)
                     hist!fk := hist!fk + 1
                  $)
               $)
            $)
         $)
      $)
   $)

   writef("Case 5 greater than 32*n")
   FOR a = 0   TO 31 DO
   $( LET ak =      (lb>>a & 1)
      FOR b = 0   TO 12 DO
      $( LET bk = ak + (hb>>b & 1)
         FOR c = b+1 TO 13 DO
         $( LET ck = bk + (hb>>c & 1)
            FOR d = c+1 TO 14 DO
            $( LET dk = ck + (hb>>d & 1)
               FOR e = d+1 TO 15 DO
               $( LET ek = dk + (hb>>e & 1)
                  FOR f = e+1 TO 16 DO
                  $( LET fk = ek + (hb>>f & 1)
                     hist!fk := hist!fk + 1
                  $)
               $)
            $)
         $)
      $)
   $)

   writef("Case 6 greater than 32*n")
   FOR a = 0   TO 11 DO
   $( LET ak =      (hb>>a & 1)
      FOR b = a+1 TO 12 DO
      $( LET bk = ak + (hb>>b & 1)
         FOR c = b+1 TO 13 DO
         $( LET ck = bk + (hb>>c & 1)
            FOR d = c+1 TO 14 DO
            $( LET dk = ck + (hb>>d & 1)
               FOR e = d+1 TO 15 DO
               $( LET ek = dk + (hb>>e & 1)
                  FOR f = e+1 TO 16 DO
                  $( LET fk = ek + (hb>>f & 1)
                     hist!fk := hist!fk + 1
                  $)
               $)
            $)
         $)
      $)
   $)

   writef("Total number of permutations is %n*n*n", count)

   FOR i = 0 TO 6 DO writef("%n numbers correct %i8 times*n", i, hist!i)
   writef("*nTotal             %i8*n*n", 
           hist!0+hist!1+hist!2+hist!3+hist!4+hist!5+hist!6)
$)
/* This should output:

   0 numbers correct  6096454 times
   1 numbers correct  5775588 times
   2 numbers correct  1851150 times
   3 numbers correct   246820 times
   4 numbers correct    13545 times
   5 numbers correct      258 times
   6 numbers correct        1 times

   Total             13983816
*/

