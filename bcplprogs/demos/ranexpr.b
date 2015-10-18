GET "libhdr"

MANIFEST $(
Op=0; Val=1; L=1; R=2 // The selectors
Numb=0; Mult=1; Div=2 // The operators
Plus=3; Minus=4
$)

GLOBAL $( ptr:200 $)

LET list(n, a, b, c) = VALOF
$( LET v = @a
   ptr := ptr - n
   FOR i = 0 TO n-1 DO ptr!i := v!i
   RESULTIS ptr
$)

AND randtree(n) =
   n=0 -> list(2, Numb, randno(1000)),
   VALOF $( LET lno = randno(n) - 1
            LET rno = n - lno - 1
            RESULTIS list(3, randno(4),
                             randtree(lno),
                             randtree(rno))
         $)

AND eval(x) =
   Op!x = Numb  -> Val!x,
   Op!x = Mult  -> eval(L!x) * eval(R!x),
   Op!x = Div   -> eval(L!x) / eval(R!x),
   Op!x = Plus  -> eval(L!x) + eval(R!x),
   Op!x = Minus -> eval(L!x) - eval(R!x),
   abort(999)

LET start() = VALOF
$( LET v = VEC 1000
   ptr := v+1000
   writef("Value = %n*n", eval(randtree(7)))
   RESULTIS 0
$)
