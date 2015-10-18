GET "libhdr"

GLOBAL $( w1:200; w2:201
          w3:202; w4:203
          w5:204; w6:205
          n1:206; n2:207
          n3:208; n4:209
          n5:210; n6:211
$)


LET start() = VALOF
$( LET error = 0
   w1, w2 := randno(1000), randno(1000)
   w3, w4 := randno(1000), randno(1000)
   w5, w6 := randno(1000), randno(1000)

   error := train()

   FOR i = 1 TO 1000 DO
   $( LET e = 0
      AND d1, d2 = randno(100)-50, randno(100)-50
      AND d3, d4 = randno(100)-50, randno(100)-50
      AND d5, d6 = randno(100)-50, randno(100)-50

      n1,n2,n3,n4,n5,n6 := 
        f(w1+d1),f(w2+d2),f(w3+d3),f(w4+d4),f(w5+d5),f(w6+d6)

      e := train()
      IF e<=error DO
      $( error, w1,w2,w3,w4,w5,w6 := e, n1,n2,n3,n4,n5,n6
         writef("%i4: err = %i4, weights %i4 %i4 %i4 %i4 %i4 %i4*n",
                 i, error, w1, w2, w3, w4, w5, w6)
      $)
   $)

   RESULTIS 0
$)

AND train() = ABS terr(   0,    0,    0) +
              ABS terr(   0, 1000, 1000) +
              ABS terr(1000,    0, 1000) +
              ABS terr(1000, 1000,    0)

AND terr(x, y, z) = eval(x, y) - z

AND eval(x, y) = VALOF
$( LET h1, h2 = f((x*w1+y*w2)/1000), f((x*w3+y*w4)/1000)
   RESULTIS f((h1*w5+h1*w6)/1000)
$)

AND f(x) = x<   0 ->    0,
           x>1000 -> 1000,
           x