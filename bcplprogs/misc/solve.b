GET "libhdr"

MANIFEST $(
modulus = #x7FFFFFFF
fail = FALSE
ok   = TRUE
$)

LET tr(a,m,b,n) = VALOF
$( writef("a=%IA  m=%IA  b=%IA  n=%IA*N", a,m,b,n)
   RESULTIS TRUE
$)

LET dv(a, m, b, n) = a=1 -> m,
                     a=0 -> m-n,
                     a<b -> dv(a, m, b REM a, m*(b/a)+n),
                     dv(a REM b, m+n*(a/b), b, n)


LET inv(x) = dv(x, 1, modulus-x, 1)

LET add(x, y) = VALOF
$( LET a = x+y
   IF 0<=a<modulus RESULTIS a
   RESULTIS a-modulus
$)

AND sub(x, y) = add(x, neg(y))

AND neg(x)    = modulus-x

AND mul(x, y) = x=0 -> 0,
                (x&1)=0 -> mul(x>>1, add(y,y)),
                add(y, mul(x>>1, add(y,y)))

AND ovr(x, y) = mul(x, inv(y))

LET prow(x1, x2, x3, x4, xr) BE
   writef("%IA %IA %IA %IA    %IA*N", x1, x2, x3, x4, xr)

LET solve(m, r, a) = VALOF
$( LET a1, a2, a3, a4 = m!0,  m!1,  m!2,  m!3
   AND b1, b2, b3, b4 = m!4,  m!5,  m!6,  m!7
   AND c1, c2, c3, c4 = m!8,  m!9,  m!10, m!11
   AND d1, d2, d3, d4 = m!12, m!13, m!14, m!15

   AND ar, br, cr, dr = r!0,  r!1,  r!2,  r!3
   AND x1, x2, x3, x4, xr, k = ?, ?, ?, ?, ?, ?

   IF a1=0 DO
   $( TEST b1=0
      THEN TEST c1=0
           THEN TEST d1=0
                THEN RESULTIS fail
                ELSE x1, x2, x3, x4, xr := d1, d2, d3, d4, dr
           ELSE x1, x2, x3, x4, xr := c1, c2, c3, c4, cr
      ELSE x1, x2, x3, x4, xr := b1, b2, b3, b4, br
      a1 := x1
      a2 := add(a2, x2)
      a3 := add(a3, x3)
      a4 := add(a4, x4)
      ar := add(ar, xr)
   $)


   newline()
   prow(a1, a2, a3, a4, ar)
   prow(b1, b2, b3, b4, br)
   prow(c1, c2, c3, c4, cr)
   prow(d1, d2, d3, d4, dr)
   newline()

   k := inv(a1)
   a1 := 1
   a2 := mul(a2, k)
   a3 := mul(a3, k)
   a4 := mul(a4, k)
   ar := mul(ar, k)

   k := b1
   b1 := 0
   b2 := sub(b2, mul(a2, k))
   b3 := sub(b3, mul(a3, k))
   b4 := sub(b4, mul(a4, k))
   br := sub(br, mul(ar, k))

   k := c1
   c1 := 0
   c2 := sub(c2, mul(a2, k))
   c3 := sub(c3, mul(a3, k))
   c4 := sub(c4, mul(a4, k))
   cr := sub(cr, mul(ar, k))

   k := d1
   d1 := 0
   d2 := sub(d2, mul(a2, k))
   d3 := sub(d3, mul(a3, k))
   d4 := sub(d4, mul(a4, k))
   dr := sub(dr, mul(ar, k))
   prow(a1, a2, a3, a4, ar)
   prow(b1, b2, b3, b4, br)
   prow(c1, c2, c3, c4, cr)
   prow(d1, d2, d3, d4, dr)
   newline()


   IF b2=0 DO
   $( TEST c2=0
      THEN TEST d2=0
           THEN RESULTIS fail
           ELSE x2, x3, x4, xr := d2, d3, d4, dr
      ELSE x2, x3, x4, xr := c2, c3, c4, cr
      b2 := x2
      b3 := add(b3, x3)
      b4 := add(b4, x4)
      br := add(br, xr)
   $)

   k := inv(b2)
   b2 := 1
   b3 := mul(b3, k)
   b4 := mul(b4, k)
   br := mul(br, k)

   k := a2
   a2 := 0
   a3 := sub(a3, mul(b3, k))
   a4 := sub(a4, mul(b4, k))
   ar := sub(ar, mul(br, k))

   k := c2
   c2 := 0
   c3 := sub(c3, mul(b3, k))
   c4 := sub(c4, mul(b4, k))
   cr := sub(cr, mul(br, k))

   k := d2
   d2 := 0
   d3 := sub(d3, mul(b3, k))
   d4 := sub(d4, mul(b4, k))
   dr := sub(dr, mul(br, k))
   prow(a1, a2, a3, a4, ar)
   prow(b1, b2, b3, b4, br)
   prow(c1, c2, c3, c4, cr)
   prow(d1, d2, d3, d4, dr)
   newline()


   IF c3=0 DO
   $( IF d3=0 RESULTIS fail
      c3 := d3
      c4 := add(c4, d4)
      cr := add(cr, dr)
   $)

   k := inv(c3)
   c3 := 1
   c4 := mul(c4, k)
   cr := mul(cr, k)

   k := a3
   a3 := 0
   a4 := sub(a4, mul(c4, k))
   ar := sub(ar, mul(cr, k))

   k := b3
   b3 := 0
   b4 := sub(b4, mul(c4, k))
   br := sub(br, mul(cr, k))

   k := d3
   d3 := 0
   d4 := sub(d4, mul(c4, k))
   dr := sub(dr, mul(cr, k))

   prow(a1, a2, a3, a4, ar)
   prow(b1, b2, b3, b4, br)
   prow(c1, c2, c3, c4, cr)
   prow(d1, d2, d3, d4, dr)
   newline()

   IF d4=0 RESULTIS fail

   k := inv(d4)
   d4 := 1
   dr := mul(dr, k)

   k := a4
   a4 := 0
   ar := sub(ar, mul(dr, k))

   k := b4
   b4 := 0
   br := sub(br, mul(dr, k))

   k := c4
   c4 := 0
   cr := sub(cr, mul(dr, k))

   prow(a1, a2, a3, a4, ar)
   prow(b1, b2, b3, b4, br)
   prow(c1, c2, c3, c4, cr)
   prow(d1, d2, d3, d4, dr)
   newline()

   a!0, a!1, a!2, a!3 := ar, br, cr, dr
   RESULTIS ok
$)

AND matmul(m, a, b) BE
$( b!0 := inprod(m, a)
   b!1 := inprod(m+4, a)
   b!2 := inprod(m+8, a)
   b!3 := inprod(m+12, a)
$)

AND inprod(a, b) = VALOF
$( LET r = 0
   FOR i = 0 TO 3 DO r := add(r, mul(a!i, b!i))
   RESULTIS r
$)

LET trysolve(a1, a2, a3, a4,    ar,
             b1, b2, b3, b4,    br,
             c1, c2, c3, c4,    cr,
             d1, d2, d3, d4,    dr) BE
$( LET ans = VEC 3
   LET m = VEC 15
   LET r = VEC 3

   m!0,  m!1,  m!2,  m!3 := a1, a2, a3, a4
   m!4,  m!5,  m!6,  m!7 := b1, b2, b3, b4
   m!8,  m!9, m!10, m!11 := c1, c2, c3, c4
   m!12, m!13, m!14, m!15 := d1, d2, d3, d4

   r!0,  r!1,  r!2,  r!3 := ar, br, cr, dr

   writes("*NEquation:*N*N")
   writef("%IA %IA %IA %IA    %IA*N", a1, a2, a3, a4, ar)
   writef("%IA %IA %IA %IA    %IA*N", b1, b2, b3, b4, br)
   writef("%IA %IA %IA %IA    %IA*N", c1, c2, c3, c4, cr)
   writef("%IA %IA %IA %IA    %IA*N", d1, d2, d3, d4, dr)

   TEST solve(m, r, ans)=ok
   THEN $( writef("gives solution: %IA %IA %IA %IA*N",
                   ans!0, ans!1, ans!2, ans!3)
           TEST inprod(@a1, ans)=ar &
                inprod(@b1, ans)=br &
                inprod(@c1, ans)=cr &
                inprod(@d1, ans) = dr
           THEN writes("which is OK*N*N")
           ELSE writes("which is INCORRECT*N*N")
        $)
   ELSE writes("is SINGULAR*N*N")
$)

LET start() BE
$( writes("Testing *N")
   trysolve( 0, 0, 0, 1,     1,
             0, 0, 1, 0,     2,
             0, 1, 0, 0,     3,
             1, 0, 0, 0,     4)

   trysolve( 1, 1, 1, 1,    10,
             0, 1, 1, 1,     9,
             0, 0, 1, 1,     7,
             0, 0, 0, 1,     4)

   trysolve( 1, 1, 1, 1,    10,
             1, 1, 0, 0,     3,
             2, 0, 1, 0,     5,
             1, 1, 0, 1,     7)

   trysolve( 1, 2, 3, 4,     0,
             4, 3, 2, 1,     0,
             1, 1, 1, 0,     0,
             6, 6, 6, 5,     0)

   FOR i = 1 TO 4 DO
   $( LET r() = randno()
      trysolve( r(), r(), r(), r(),    r(),
                r(), r(), r(), r(),    r(),
                r(), r(), r(), r(),    r(),
                r(), r(), r(), r(),    r())
   $)

   FOR i = 1 TO 10000*0 DO
   $( LET x = randno()
      LET y = randno()
      writef("i=%I5 x= %IA  y=%IA*N", i, x, y)
      UNLESS add(x, add(y, 1)) = add(1, add(x, y)) DO err("add", x, y)
      UNLESS mul(x, mul(2, y)) = add(mul(x,y), mul(x,y)) DO err("mul", x, y)
      UNLESS x=0 | inv(inv(x))=x DO err("inv", x, y)
      UNLESS add(x, mul(x, y))=mul(add(y,1), x) DO err("mul1",x,y)
      UNLESS x=0 | mul(x, ovr(y,x)) = y DO
      $( writef("Trouble with ovr*N")
         writef("ovr(%IA, %IA) = %IA*N", y, x, ovr(y,x))
         writef("mul(%IA, %IA) = %IA*N", x, ovr(y,x), mul(x,ovr(y,x)))
      $)
   $)
   writes("*NEnd of test*N")
$)

AND err(mess, x, y) BE writef("Error: %s x=%IA  y=%IA*N", mess, x, y)

AND randno() = VALOF
$( STATIC $( seed = 123456  $)
   seed := 2147001325*seed + 715136305
   RESULTIS ABS(seed/3) REM modulus
$)

AND randno1() = VALOF
$( STATIC $( a=0; b=1; c=1  $)
   a := b
   b := c
   c := add(a, b)
   RESULTIS a
$)

