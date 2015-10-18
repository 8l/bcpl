/*  ******* UNDER DEVELOPMENT **********

This is an experimental mergesort that requires
no extra workspace except for a recusion stack.

Implemented in BCPL by Martin Richards (c) May 2001
*/

GET "libhdr"

GLOBAL
{ data:ug
  size
}

LET merge(p, q, r) BE UNTIL p>=q DO
{ // p!0 <= p!1 <= ... q!-1
  // q!0 <= q!1 <= ... r!-1
  // Returns with elements from p to r-1 sorted
  LET x = q!0
  LET t = q

  IF q>=r RETURN

  WHILE p!0 <= x DO
  { p := p+1
    IF p=q RETURN   // Because q!-1 < q!0
  }

  // p!0 > q!0  and p<q
  // We must swap at least one element

  x := p!0  // x is >= q!0

  // Now swap elements starting at t with elements starting at p
  // while !p > !t and p<q and t<r
  { LET y = t!0
    IF x<=y BREAK
//writef("swap*n")
//pr(p,t,0)
    t!0 := p!0
    p!0 := y
    p, t := p+1, t+1
  } REPEATWHILE p<q & t<r

  IF p>=q DO { merge(p, t, r); RETURN }

  merge(q, t, r) // re-sort the righthand region
  // Repeat to do merge(p, q, r)
}

AND mergesort(v, n) BE
{ LET p = @v!1
  LET q = @v!n
  msort(p, q)
}

AND msort(p, q) BE IF p+5<q DO
{ LET m = (p+q)*3/4
  msort(p, m-1)
  msort(m, q)
//pr(p, m, q+1)
  merge(p, m, q+1)
//pr(p, m, q+1)
}

AND start() = VALOF
{ //LET res = findoutput("res")
  //selectoutput(res)
/*
  try(10)
  try(20)
  try(30)
  try(40)
  try(50)
  try(60)
  try(70)
  try(80)
  try(90)
  try(100)
  try(200)
  try(300)
  try(400)
  try(500)
  try(600)
  try(700)
  try(800)
  try(900)
  try(1000)
  try(2000)
  try(3000)
  try(4000)
  try(5000)
  try(6000)
  try(7000)
  try(8000)
  try(9000)
*/
  try(10000)
/*
//  try(100000)
//  try(1000000)
*/
  //endwrite()
  RESULTIS 0
}

AND sorted(v, n) = VALOF
{ FOR i = 1 TO n-1 IF v!i>v!(i+1) RESULTIS FALSE
  RESULTIS TRUE
}

AND try(upb) BE
{ writef("Sorting %i6 ints ", upb)

  try1("ms: ", mergesort, upb)
  try1("ms1:", mergesort1, upb)
//  try1("sh: ", shellsort, upb)
//  try1("hp: ", heapsort,  upb)
  try1("qs: ", quicksort, upb)
 
  newline()
}

AND testsort(v, n) BE
{ writef("Test sort  v=%n n=%n*n", v, n)
  FOR i = 1 TO 10 DO writef("%i9*n", v!i)
  newline()
  heapsort(v, n)
  newline()
  FOR i = 1 TO 10 DO writef("%i9*n", v!i)
  newline()
}

AND try1(str, sortfn, upb) BE
{ size := upb
  data := getvec(size)
  setseed(upb)
  FOR i = 1 TO size DO data!i := randno(9999999)

//  writef(" %s%iB", str, instrcount(sortfn, data, size))
  sortfn(data, size)

  UNLESS sorted(data, size) DO writef("*nData not sorted*n")
  freevec(data)
}

AND pr(p, q, r) BE
{ LET end = data+size
  FOR i = 1 TO size DO
  { LET a = data+i
    LET mark = ' '
    IF a=p | a=q | a=r DO mark := '#'
    writef(" %i3%c", a!0, mark)
  }
  IF p>end | q>end | r>end DO writes("  #")
  newline()
}

AND shellsort(v, upb) BE
$( LET m = 1
   UNTIL m>upb DO m := m*3 + 1  // Find first suitable value in the
                                // series:  1, 4, 13, 40, 121, 364, ...
   $( m := m/3
      FOR i = m+1 TO upb DO
      $( LET vi = v!i
         LET j = i
         $( LET k = j - m
            IF k<=0 | v!k < vi BREAK
            v!j := v!k
            j := k
         $) REPEAT
         v!j := vi
      $)
   $) REPEATUNTIL m=1
$)

AND heapify(v, k, i, last) BE
$( LET j = i+i  // If there is a son (or two), j = subscript of first.
   AND x = k    // x will hold the larger of the sons if any.

   IF j<=last DO x := v!j      // j, x = subscript and key of first son.
   IF j< last DO
   $( LET y = v!(j+1)          // y = key of the other son.
      IF x<y DO x,j := y, j+1  // j, x = subscript and key of larger son.
   $)

   IF k=x | k>=x DO
   $( v!i := k                 // k is not lower than larger son if any.
      RETURN
   $)

   v!i := x
   i := j
$) REPEAT

AND heapsort(v, upb) BE
$( FOR i = upb/2 TO 1 BY -1 DO heapify(v, v!i, i, upb)

   FOR i = upb TO 2 BY -1 DO
   $( LET k = v!i
      v!i := v!1
      heapify(v, k, 1, i-1)
   $)
$)

AND quicksort(v, n) BE qsort(v+1, v+n)

AND qsort(l, r) BE
$( WHILE l+8<r DO
   $( LET midpt = (l+r)/2
      // Select a good(ish) median value.
      LET val   = middle(!l, !midpt, !r)
      LET i = partition(val, l, r)
      // Only use recursion on the smaller partition.
      TEST i>midpt THEN $( qsort(i, r);   r := i-1 $)
                   ELSE $( qsort(l, i-1); l := i   $)
   $)

   FOR p = l+1 TO r DO  // Now perform insertion sort.
     FOR q = p-1 TO l BY -1 TEST q!0<=q!1 THEN BREAK
                                          ELSE $( LET t = q!0
                                                  q!0 := q!1
                                                  q!1 := t
                                               $)
$)

AND middle(a, b, c) = a<b -> b<c -> b,
                                    a<c -> c,
                                           a,
                             b<c -> a<c -> a,
                                           c,
                                    b

AND partition(median, p, q) = VALOF
$( LET t = ?
   WHILE !p < median DO p := p+1
   WHILE !q > median DO q := q-1
   IF p>=q RESULTIS p
   t  := !p
   !p := !q
   !q := t
   p, q := p+1, q-1
$) REPEAT

// ************************** Merge Sort ************************

AND mergesort1(v, n) BE
{ LET work = getvec(n/2)
  IF work=0 DO
  { writef("Can't allocate workspace*n")
    RETURN
  }
  msort1( v, v, n, work)
  freevec(work)   
}

AND msort1(f, t, n, w) BE TEST n<8
THEN FOR i = 1 TO n DO
     { LET val = f!i
       LET j = i
       WHILE j>1 & val < t!(j-1) DO { t!j := t!(j-1); j := j-1 }
       t!j := val
     }
ELSE { LET n1 = n/4
       LET n2 = n/2
       LET n3 = n1+n2

//        f                                    w
//        |-------|-------|-------|-------|    |-------|-------|
//        |     |       |       |       |      |     |       |
//        1     n1      n2      n3      n      1     n1      n2
//
// msort          fffffff                      wwwwwww        
//                                                     ttttttt
// msort  fffffff                              wwwwwww
//                ttttttt
// merge          aaaaaaa                              bbbbbbb
//                                             ttttttttttttttt
// msort          wwwwwww fffffff        
//        ttttttt
// msort                  wwwwwww fffffff
// msort                          ttttttt
// merge  aaaaaaa                 bbbbbbb
//                        ttttttttttttttt
// merge                  bbbbbbbbbbbbbbb      aaaaaaaaaaaaaaa
//        ttttttttttttttttttttttttttttttt

       msort1(f+n1,           w+n1, n2-n1, w)
       msort1(   f, f+n1, n1,              w)
       merge1(      f+n1, n1, w+n1, n2-n1, w)

       msort1(f+n2, f, n1,             f+n1)
       msort1(f+n3,        f+n3, n-n3, f+n2)
       merge1(      f, n1, f+n3, n-n3, f+n2)

       merge1( w, n2, f+n2, n-n2, t)
     }

AND merge1(a, an, b, bn, t) BE
{ LET va, vb = ?, ?
  t := t+1
  IF an DO { a := a+1; va := !a }
  IF bn DO { b := b+1; vb := !b }
  UNLESS an=0 | bn=0 DO
  { TEST va<=vb
    THEN { !t := va
           t := t+1
           an := an-1
           IF an=0 BREAK
           a := a+1
           va := !a
         }
    ELSE { !t := vb
           t := t+1
           bn := bn-1
           IF bn=0 BREAK
           b := b+1
           vb := !b
         }
  } REPEAT

  UNTIL an=0 DO { !t := !a; t := t+1; a := a+1; an := an-1 }
  IF b=t RETURN
  UNTIL bn=0 DO { !t := !b; t := t+1; b := b+1; bn := bn-1 }
}

