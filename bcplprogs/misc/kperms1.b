GET "libhdr"

GLOBAL $( word:200; maxn:201; count:202; len:203 $)

MANIFEST $( am=#x0000000F; ab=#x00000001
            bm=#x000000F0; bb=#x00000010
            cm=#x00000F00; cb=#x00000100
            dm=#x0000F000; db=#x00001000
            em=#x000F0000; eb=#x00010000
            fm=#x00F00000; fb=#x00100000
            gm=#x0F000000; gb=#x01000000
            hm=#xF0000000; hb=#x10000000
$)

LET start() = VALOF
$( LET frq = TABLE 1, 3, 1, 2, 0, 0, 0, 0
   LET w = 0
   LET v = VEC 20
   word := v

//   writef("*nAnagrams with %n As, %n Bs, %n Cs and %n Ds*n*n",

   maxn := 0
   FOR i = 7 TO 0 DO maxn, w := maxn+frq!i, (w<<4)+frq!i

   word%0 := maxn
   count, len := 0, 0
   perms(0, w)
   writef("*n*nCount = %n*n", count)
   RESULTIS 0
$)


AND perms(w) BE
   TEST n=maxn
   THEN pr(word)
   ELSE $( n := n+1
           UNLESS (w&am)=0 DO $( word%n := 'A'; perms(n, w-ab) $)
           UNLESS (w&bm)=0 DO $( word%n := 'B'; perms(n, w-bb) $)
           UNLESS (w&cm)=0 DO $( word%n := 'C'; perms(n, w-cb) $)
           UNLESS (w&dm)=0 DO $( word%n := 'D'; perms(n, w-db) $)
           UNLESS (w&em)=0 DO $( word%n := 'E'; perms(n, w-eb) $)
           UNLESS (w&fm)=0 DO $( word%n := 'F'; perms(n, w-fb) $)
           UNLESS (w&gm)=0 DO $( word%n := 'G'; perms(n, w-gb) $)
           UNLESS (w&hm)=0 DO $( word%n := 'H'; perms(n, w-hb) $)
        $)

AND pr(str) BE
$( count := count+1
   writef("%s ", str)
   len := len + maxn + 1
   IF len>72 DO $( newline(); len := 0 $)
$)

