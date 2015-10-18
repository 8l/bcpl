SECTION "NQUEENS"
 
GET "libhdr"
 
STATIC $( count = 0; all=1  $)
 
LET try(ld,row,  rd) BE TEST row=all
THEN count := count + 1
ELSE $( LET poss = all & NOT (ld | row | rd)
        UNTIL poss=0 DO $( LET p = poss & -poss
                           poss := poss - p
                           try(ld+p << 1, row+p, rd+p >> 1)
                        $)
     $)
 
LET start() = VALOF
$( FOR i = 1 TO 12 DO
   $( count := 0
      try(0, 0, 0)
      writef("%i2 queens solutions is %n*n", i, count)
      all := 2*all+1
   $)
   RESULTIS 0
$)
