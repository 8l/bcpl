GET "libhdr"

GLOBAL $( count:200 $)

MANIFEST $( mbits=#x77777777; lbits=#x11111111 $)

LET start() = VALOF
$( try(#x32110000)
   try(#x11230000)
   try(#x20103010)
   try(#x11111111)
   try(#x22220000)
   try(#x12340000)
   try(#x02340000)
   RESULTIS 0
$)

AND try(freqs)
$( writef("Letter frequencies %x8", freqs)
   count := 0
   anags(freqs)
   writef(" gives %i7 anagrams*n", count)
$)

AND anags(freqs) BE
   TEST freqs=0
   THEN count := count+1
   ELSE $( LET poss = (freqs+mbits)>>3 & lbits
           UNTIL poss=0 DO $( LET bit = poss & -poss
                              poss := poss-bit
                              anags(freqs-bit)
                           $)
        $)


