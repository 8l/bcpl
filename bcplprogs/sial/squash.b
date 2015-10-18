GET "libhdr"

MANIFEST $( chsize = 200000 $)

GLOBAL
$(
inputstream:150
outputstream:151
chv:152
ptr:153
chupb:154
treevec:155
treep:156
treet:157
$)

LET start() = VALOF
$( LET argv = VEC 50
   LET oldin = input()
   LET oldoutput = output()
   LET rc = 0

   inputstream := 0
   outputstream := 0

   IF rdargs("FROM/A,TO", argv, 50) = 0 DO
   $( writes("Bad args*n")
      rc := 20
      GOTO exit
   $)

   chv := getvec((chsize+1)/bytesperword)
   ptr := getvec(chsize+1)
   treevec := getvec(3*chsize)
   treep, treet := 0, 3*chsize

   IF chv=0 | ptr=0 | treevec=0 DO
   $( writef("Insufficient memory*n")
      rc := 20
      GOTO exit
   $)
 
   inputstream := findinput(argv!0)
   IF inputstream = 0 DO $( writef("Can*'t open %s*n", argv!0)
                            rc := 20
                            GOTO exit
                         $)
   selectinput(inputstream)

   UNLESS argv!1=0 DO $( outputstream := findoutput(argv!1)
                         IF outputstream=0 DO
                         $( writef("Can*'t open %s*n", argv!1)
                            rc := 20
                            GOTO exit
                         $)
                      $)

    chupb := 0

    $( LET ch = rdch()  // Read the file into chv
       IF ch=0 DO ch:= 255
       IF intflag() DO $( selectoutput(oldoutput)
                          writes("****BREAK*n")
                          rc := 5
                          GOTO exit
                       $)
       IF chupb>chsize DO $( selectoutput(oldoutput)
                             writes("Input file too large*n")
                             rc := 5
                             GOTO exit
                          $)

       IF ch=endstreamch BREAK
//writef("chv!%i2 = %i3*n", chupb, ch)
       chv%chupb := ch
       chupb := chupb+1
    $) REPEAT
    chv%chupb := 0  // EOF marker

    selectinput(oldin)

    FOR i = 0 TO chupb DO ptr!i := i

    writef("Sort cyclic rotations  chupb = %i2*n", chupb)
    // Sort cyclic rotations
    qsort(0, chupb) 
    // Sorting done
    writef("Sorting done*n")

//    pr()

    treep, treet := 0, 6*chsize

    UNLESS outputstream=0 DO selectoutput(outputstream)
    writef("%n*n*n", chupb+1)
  
    mktree()
    selectoutput(oldoutput)

    writef("%n nodes used*n", treep/5)
    writes("*nEnd of run*n")

exit:
   UNLESS inputstream=0  DO $( selectinput(inputstream);   endread()  $)
   UNLESS outputstream=0 DO $( selectoutput(outputstream); endwrite() $)
   UNLESS chv=0 DO freevec(chv)
   UNLESS ptr=0 DO freevec(ptr)
   UNLESS treevec=0 DO freevec(treevec)
   RESULTIS rc
$)

AND pr() BE
$( FOR i = 0 TO chupb DO
   $( writef("%i4: ", i)
      FOR j = 0 TO 11 DO writef(" %i3", findch(i, j))
      newline()
   $)
$)

AND qsort(l, r) BE
$( 
   WHILE l+8<r DO
   $( LET midpt = (l+r)/2
      // Select a good(ish) median value.
      LET meds   = middle(ptr!l, ptr!midpt, ptr!r)
      LET i = partition(meds, l, r)
//writef("QS  i = %n l = %i2 r = %i2*n", i, l, r)
      // Only use recursion on the smaller partition.
      TEST i>midpt THEN $( qsort(i, r);   r := i-1 $)
                   ELSE $( qsort(l, i-1); l := i   $)
   $)

//writef("Insertion sort %i2 %i2*n", l, r)
   FOR p = l+1 TO r DO  // Now perform insertion sort.
     FOR q = p-1 TO l BY -1 TEST gt(ptr!q,ptr!(q+1))
                            THEN $( LET t = ptr!q
                                    ptr!q := ptr!(q+1)
                                    ptr!(q+1) := t
                                 $)
                            ELSE BREAK
//pr()
$)

AND middle(a, b, c) = 
    gt(b,a) -> gt(c,b) -> b,
                          gt(c,a) -> c,
                                     a,
               gt(c,b) -> gt(c,a) -> a,
                                     c,
                          b

AND partition(medp, p, q) = VALOF
$( LET t = ?
//   writef("partition %i2 %i2 %i2*n", medp, p, q)
   WHILE gt(medp, ptr!p) DO p := p+1
   WHILE gt(ptr!q, medp) DO q := q-1
//   writef("partition1 p=%i2 q=%i2*n", p, q)
   IF p>=q RESULTIS p
//   writef("swapping p=%i2 q=%i2*n", p, q)
   t  := ptr!p
   ptr!p := ptr!q
   ptr!q := t
   p, q := p+1, q-1
$) REPEAT

AND gt(a, b) = VALOF
$( IF a=b RESULTIS FALSE
   WHILE chv%a=chv%b DO a, b := a+1, b+1
   IF chv%a>chv%b RESULTIS TRUE
   RESULTIS FALSE
$)

AND mktree() BE
$( LET r = initstructure()

newline()
   UNTIL r = treep DO
   $( LET w = treep
newline()
      UNTIL r = w DO $( augment(r); r := r+5 $)
   $)
$)

AND mk5(a,b,c,d,e) = VALOF
$( LET p = treevec+treep
   p!0, p!1, p!2, p!3, p!4 := a, b, c, d, e
//writef("mk5   %i3: %i3 %i3 %i3 %i3 %i3*n", treep, a, b, c, d, e)
   treep := treep+5
//writes("*nType RET to continue*n")
//   UNTIL rdch()='*n' DO p := p
//IF treep>200 DO abort(1000)
   RESULTIS treep-5
$)

AND initstructure() = VALOF
$( LET env = mk5(0, -1, chupb+1, 0, -1)
   LET row = 0
   LET res = treep
   treevec!(env+4) := res
   WHILE row<=chupb DO
   $( LET ch = findch(row, 0)
      LET rep = 1
//      put(row, 0, ch)
      WHILE row+rep<=chupb & ch=findch(row+rep, 0) DO rep := rep+1
      mk5(row, 0, rep, env, -1)
      put(row, 0, ch, rep)
      row := row+rep
   $)
   RESULTIS res
$)

// r   -> [row,  col, rep,  env,  succ]
// env -> [row1, col1, rep1, env1, succ1]
AND augment(r) BE
$( LET row, col, rep, env  = 
             treevec!r, treevec!(r+1), treevec!(r+2), treevec!(r+3)
   LET ncol = col + 1

   LET rep1, e  = treevec!(env+2), env
   LET col2, rep2 = ?, ?

//writef("augment: r = %n  col = %n succ = %n*n", r, col, treevec!(r+4))
//writef("augment: row = %n  rep = %n env = %n*n", row, rep, env)
//writef("augment: rep1 = %n e = %n  succ1*n", rep1, e, treevec!(e+4))
   IF rep1=rep DO $( treevec!(r+4) := 0
//                     writef("succ of %n is %n*n", r, 0)
                     RETURN
                  $)
   // rep<rep1
   WHILE treevec!(e+4)=0 DO e := treevec!(e+3)

   e := treevec!(e+4)
   col2, rep2 := treevec!(e+1), treevec!(e+2)

// e is the environment list for r, giving the possible characters that
// can occur in findch(row, ncol) ... findch(row+rep-1, ncol)

   $( LET ch = findch(row, ncol)
      LET chrep = 1
      LET skip = 0
      LET node = ?
      $( LET row2 = treevec!e
//        writef("e %i3 ch %i3 row %i3 ncol %i3   ch2 %i3 row2 %i3 col2 %i3*n",
//                e,    ch,    row,    ncol,    findch(row2, col2), row2, col2)
         IF ch = findch(row2, col2) BREAK
         skip, e := skip+1, e+5
      $) REPEAT
      // e points to matching node
//      UNLESS rep1=rep2 DO put(row, ncol, skip)
      WHILE chrep<rep DO
      $( UNLESS ch = findch(row+chrep, ncol) BREAK
//         UNLESS rep1=rep2 DO put(row+chrep, ncol, 0)
         chrep := chrep+1
      $)
      UNLESS rep1=rep2 DO put(row, ncol, skip, chrep)
      node := mk5(row, ncol, chrep, e, -1)
      IF treevec!(r+4)<0 DO treevec!(r+4) := node

      row, rep := row+chrep, rep-chrep
//writef("remaining rep = %n*n", rep)
   $) REPEATUNTIL rep=0
$)

AND put(row,col,n, rep) BE 
$( /*writef("%i5: ", row)
   UNLESS col=0 DO FOR i = 0 TO col DO 
                   $( LET ch = findch(row, i)
                      UNLESS 32<=ch<=127 DO ch := '?'
                      wrch(ch)
                   $)
*/
   writef(" %n/%n*n", n, rep)
$)

AND findch(row, col) = VALOF
$( LET p = ptr!row + col
   IF p>chupb DO p := p-chupb-1
//writef("ch at row = %i3  col = %i3  is %i3*n",row, col, chv%p)
   RESULTIS chv%p
$)