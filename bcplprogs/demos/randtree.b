SECTION "randtree"

GET "libhdr"

MANIFEST $( op=0; left=1; right=2  $)

GLOBAL $( spacep:200 $)

LET node(n, x, y) = VALOF
$( spacep := spacep - 3
   op!spacep, left!spacep, right!spacep := n, x, y
   RESULTIS spacep
$)

AND randtree(size) = size=0 -> 0, VALOF
$( LET lsize = randno(size) - 1
   LET rsize = size - lsize - 1
   RESULTIS node(randno(5), randtree(lsize), randtree(rsize))
$)

LET prtree(tree) BE
$( STATIC $( line = ?  $)

   LET prt(t, n) BE UNLESS t=0 DO
   $( line!(n+1) := FALSE
      prt(left!t, n+1)
      FOR i = 0 TO n-1 DO writes(line!i -> "! ", "  ")
      writef("**-+ %n*n", op!t)
      line!n := NOT line!n
      line!(n+1) := right!t~=0
      FOR i = 0 TO n+1 DO writes(line!i -> "! ", "  ")
      newline()
      prt(right!t, n+1)
   $)
   
   LET v = VEC 100
   line := v
   line!0 := TRUE
   prt(tree, 0)
   newline()
$)

LET start() = VALOF
$( LET v = VEC 1000
   spacep := v+1000
   prtree(randtree(7))
   RESULTIS 0
$)
