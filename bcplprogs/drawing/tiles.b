GET"libhdr"

GLOBAL $(
sqr  : 200
used : 201
soln : 202
$)

LET start() BE
$( LET v1 = VEC 1000
   LET v2 = VEC 1000
   LET v3 = VEC 500

   sqr  := v1
   used := v2
   soln := v3

   FOR i = 0 TO 1000 DO sqr!i, used!i := i*i, FALSE

   FOR i = 608 TO 608 DO
   $( soln!0 := i
      try(1, 1, sqr!i)
   $)
$)

AND try(p, size, area) BE
TEST area=0
THEN $( FOR i = 0 TO p-1 DO writef("%I3 ", soln!i)
        newline()
     $)
ELSE UNTIL sqr!size>area | p>3 DO
     $( soln!p := size
        try(p+1, size+1, area-sqr!size)
        size   := size + 1
     $)
        
