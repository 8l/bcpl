GET "libhdr"

GLOBAL $(  // variables
hashtab     : 200
hashtabsize : 201
seed        : 202
spacep      : 203
spacesize   : 204
spacet      : 205
spacev      : 206

hashfn      : 210
node        : 211
nodesused   : 212
printtree   : 213
randomtree  : 214
simpinit    : 215
$)

MANIFEST $(  // node operators
s.int   = 1
s.id    = 2
s.plus  = 10
$)

MANIFEST $(  // selectors
n.link  = 0
n.count = 1
n.op    = 2
n.a1    = 3
n.a2    = 4

n.upb   = 4
$)

LET hashfn(op, x, y) = (op*12345 + x*54321 + y*654321 >> 1) REM hashtabsize

AND node(op, x, y) = VALOF
$( LET hashval = hashfn(op, x, y)
   LET ptr = @ hashtab!hashval

   $( LET p = !ptr

      IF p = 0 DO
      $( p := spacep - n.upb - 1
         IF p<spacev RESULTIS 0
         spacep := p

         n.count!p := 1
         n.op!p    := op
         n.a1!p    := x
         n.a2!p    := y

         n.link!p := hashtab!hashval
         hashtab!hashval := p

         RESULTIS p
      $)

      IF n.op!p=op & 
         n.a1!p=x  &
         n.a2!p=y  RESULTIS p

      ptr := p
   $) REPEAT
$)  

AND nodesused() = VALOF
$( LET k = 0
   FOR i = 0 TO hashtabsize DO
   $( LET p = hashtab!i
      UNTIL p=0 | k>50000 DO p, k := n.link!p, k+1
   $)
   RESULTIS k
$)

AND printtree(x) BE
$( IF x=0 DO $( writes("nil")
                RETURN
             $)

   SWITCHON n.op!x INTO
   $( DEFAULT:     writes("unknown")
                   RETURN

      CASE s.int:  writef("%N", n.a1!x)
                   RETURN

      CASE s.id:   writef("v%N", n.a1!x)
                   RETURN

      CASE s.plus: writes("(")
                   printtree(n.a1!x)
                   wrch(' ')
                   printtree(n.a2!x)
                   wrch(')')
                   RETURN
   $)
$)

AND randno(upb) = VALOF
$( seed := seed * 2147001325 + 715136305
   RESULTIS (seed/3 >> 1) REM upb + 1 
$)

AND randomtree(size) = 
    size=0 -> 0,
    size=1 -> ( randno(50)>35 -> node(s.id,  randno(5), 0),
                                 node(s.int, randno(3), 0)
              ), VALOF $( LET p = randno(size) - 1
                          LET q = size - p - 1
                          RESULTIS node(s.plus, randomtree(p), randomtree(q))
                       $)
   
   
AND simpinit() = VALOF
$( hashtabsize := 251
   seed        := 12345
   spacesize   := 50000
 
   hashtab := getvec(hashtabsize)
   IF hashtab = 0 RESULTIS 0

   spacev := getvec(spacesize)
   IF spacev = 0 RESULTIS 0
   spacet := spacev + spacesize
   spacep := spacet

   RESULTIS -1  // successful return
$)



LET start() = VALOF
$( LET tree = 0

   IF simpinit()=0 DO
   $( writes("Insufficient memory*n")
      RESULTIS 20
   $)

   FOR i = 100 TO 2000 BY 100 DO
   $( FOR i = 0 TO hashtabsize DO hashtab!i := 0
      tree := randomtree(i)
//    printtree(tree)
      writef("Tree size %i4,  Nodes used = %i4*n", i, nodesused())
   $)

   writes("End of test*n")
   RESULTIS 0
$)
