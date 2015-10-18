/*
   This program is designed to profile various sort algorithms.
   It needs to be run under the BCPL Cintcode System.

   Written by: Martin Richards  (c) 1 August 1998
*/

SECTION "profsort"

GET "libhdr"
GET "CLIHDR"

GLOBAL { 
sortfun:   200
sortstr:   201
upb:       202
rev:       203
ranseed:   204
argform:   205

ptr:       210
}


MANIFEST { upb = 10000  }

LET w(form, a, b, c) BE { writef(form, a, b, c); newline() }

AND help() BE
{ w("")
  w("Usage: %s", argform)
  w("")
  w("   SORT n  -- selects the sort method")
  w("   SORT 0  -- output list of sort methods")
  w("   N n     -- selects the number of items to sort")
  w("   SEED n  -- selects the random number generator seed")
  w("   SEED 0  -- use 1 to n as the data for sorting")
  w("   RANGE n -- data value range is 0..n-1")
  w("   RLEN n  -- insert the same random value about n times")
  w("   REV     -- reverses the order of the initial data")
  w("   no args -- gives this message")
  w("")
  w("profsort runs the sort method with profiling enabled")
  w("To analyse the profile results, profsort must be preloaded.")
  w("Typical usage is:")
  w("")
  w("    preload profsort")
  w("    profsort 2 n 5000 seed 1234")
  w("    stats profile to **")
  sortmethod(0)
}

AND sortmethod(n) = VALOF
{ LET max = ?

  sortfun := TABLE 0,0,0,0,0,0,0,0,0,0
  sortstr := TABLE 0,0,0,0,0,0,0,0,0,0

  sortfun!1 := nullsort;      sortstr!1 := "nullsort"
  sortfun!2 := insertionsort; sortstr!2 := "insertionsort"
  sortfun!3 := shellsort;     sortstr!3 := "shellsort"
  sortfun!4 := quicksort;     sortstr!4 := "quicksort"
  sortfun!5 := heapsort;      sortstr!5 := "heapsort"
  sortfun!6 := treesort;      sortstr!6 := "treesort"
  sortfun!7 := mergesort;     sortstr!7 := "mergesort"
  max := 7

  IF n=0 DO
  { writef("*nSort methods:*n*n")
    FOR i = 1 TO max DO writef("%i2:  %s*n", i, sortstr!i)
    newline()
    RESULTIS 0
  }
  IF 1<=n<=max RESULTIS sortfun!n
  RESULTIS 0
}

AND start() = VALOF
{ LET argv = VEC 50
  LET method = 0
  LET fun = 0
  LET str = 0
  LET upb = 5000
  LET seed = 1
  LET range = 9_999_999
  LET rlen = 0
  LET reverse = FALSE
  LET data = 0

  argform := "SORT,N/K,SEED/K,RANGE/K,RLEN/K,REV/S"

  IF rdargs(argform, argv, 50)=0 DO
  { writef("Bad arguments for profsort*n")
    help()
    RESULTIS 20
  }

  IF argv!0 DO method := str2numb(argv!0)
  IF argv!1 DO upb    := str2numb(argv!1)
  IF argv!2 DO seed   := str2numb(argv!2)
  IF argv!3 DO range  := str2numb(argv!3)
  IF argv!4 DO rlen   := str2numb(argv!4)

  rev := argv!5

  IF method=0 DO { help(); RESULTIS 0 }

  fun := sortmethod(method)

  UNLESS fun DO { writef("Unknown sort method %n*n", method)
                  help()
                  RESULTIS 20
                }

  data := initdata(upb, seed, range, rev, rlen)

  writef("Calling %s*n", sortstr!method)

  profile(fun, data, upb)

  freevec(data)
  RESULTIS 0
}

AND random(upb) = VALOF  // return a random number in the range 1 to upb
{ ranseed := ranseed*2147001325 + 715136305
  RESULTIS ABS(ranseed/3) REM upb + 1
}

AND initdata(max, seed, range, reverse, runlength) = VALOF
{ LET v = getvec(max)
  IF v=0 RESULTIS 0
  writef("Sorting %n values in range %n seed=%n*n", max, range, seed)
  ranseed := seed
  TEST seed=0
  THEN { LET p, inc = 1, 1
         IF reverse DO p, inc := max, -1
         FOR i = 1 TO max DO { v!p := (i-1) REM range + 1
                               p := p+inc
                             }
         writef("using consective %screasing integers*n",
                 reverse->"de", "in")
       }
  ELSE FOR i = 1 TO max DO v!i := random(range)

  IF 1<=runlength<max DO
  { LET val = random(range)
    writef("putting value %n in %n random places*n", val, runlength)
    FOR i = 1 TO runlength DO v!(random(max)) := val
  }
  prdata(v, max)
  RESULTIS v
} 

AND prdata(v, max) BE
{ FOR i = 1 TO max<100->max, 100 DO
  { writef(" %i7", v!i)
    UNLESS i REM 8 DO newline()
  }
  newline()
  IF max>100 DO writef("...*n")
}

AND ispreloaded() = VALOF
{ LET preloaded = FALSE
  LET p = cli_preloadlist

  WHILE p DO
  { IF compstring(cli_commandname, @p!2)=0 RESULTIS TRUE
    p := !p
  }
  RESULTIS FALSE
}

AND profile(f, v, upb) BE
{  LET preloaded = ispreloaded()
   LET msecs = sys(30)

   IF preloaded DO sys(0, -2)  // Select statistics gathering interpreter

   sys(4)      // Turn on tallying
   f(v, upb)
   sys(5)      // Turn off tallying

   IF preloaded DO sys(0, -1)  // Select fast interpreter

   msecs := sys(30) - msecs
   writef("Sort time %n msecs*n", msecs)
   TEST sorted(v, upb)
   THEN writes("The data is now sorted*n")
   ELSE writef("The data is not sorted*n")
   prdata(v, upb)
   TEST preloaded
   THEN writef("Profile data was collected, now run stats to STATS*n")
   ELSE writef("%s was not preloaded, so no profile data collected*n",
                cli_commandname)
}

AND sorted(v, n) = VALOF
{ FOR i = 1 TO n-1 UNLESS v!i<=v!(i+1) RESULTIS FALSE
  RESULTIS TRUE
}

// *********************** Tree Sort ******************************

AND treesort(v, upb) BE { LET tree, treespace = 0, getvec(upb*3)
                          IF treespace=0 DO
                          { writef("Can't allocate workspace*n")
                            RETURN
                          }
                          ptr := treespace
                          FOR i = 1 TO upb DO putintree(@tree, v!i)
                          ptr := @ v!1
                          flatten(tree)
                          freevec(treespace)
                        }

AND putintree(a, k) BE { LET n = !a
                         IF n=0 DO { !a := ptr
                                     !ptr, ptr!1, ptr!2 := k, 0, 0
                                     ptr := ptr + 3
                                     RETURN
                                   }
                         a := k<!n -> @ n!1, @ n!2
                       } REPEAT

AND flatten(t) BE UNTIL t=0 DO { flatten(t!1)
                                 !ptr := !t
                                 ptr := ptr + 1
                                 t := t!2
                               }

// ********************* Insertion Sort ***************************

AND insertionsort(v, upb) BE FOR i = 2 TO upb DO
{ LET val = v!i
  FOR j = i TO 2 BY -1 TEST v!(j-1) <= val
                       THEN { v!j := val; BREAK }
                       ELSE v!j := v!(j-1)
}

// ********************* Shell Sort *******************************

AND shellsort(v, upb) BE
{ LET m = 1
   UNTIL m>upb DO m := m*3 + 1  // Find first suitable value in the
                                // series:  1, 4, 13, 40, 121, 364, ...
   { m := m/3
      FOR i = m+1 TO upb DO
      { LET vi = v!i
         LET j = i
         { LET k = j - m
            IF k<=0 | v!k <= vi BREAK
            v!j := v!k
            j := k
         } REPEAT
         v!j := vi
      }
   } REPEATUNTIL m=1
}

// ********************* Heap Sort ********************************

AND heapify(v, k, i, last) BE
{ LET j = i+i  // If there is a son (or two), j = subscript of first.
   AND x = k    // x will hold the larger of the sons if any.

   IF j<=last DO x := v!j      // j, x = subscript and key of first son.
   IF j< last DO
   { LET y = v!(j+1)          // y = key of the other son.
      IF x<y DO x,j := y, j+1  // j, x = subscript and key of larger son.
   }

   IF k=x | k>=x DO
   { v!i := k                 // k is not lower than larger son if any.
      RETURN
   }

   v!i := x
   i := j
} REPEAT

AND heapsort(v, upb) BE
{ FOR i = upb/2 TO 1 BY -1 DO heapify(v, v!i, i, upb)

   FOR i = upb TO 2 BY -1 DO
   { LET k = v!i
      v!i := v!1
      heapify(v, k, 1, i-1)
   }
}

// ************************ Quicksort **************************

AND quicksort(v, n) BE qsort(v+1, v+n)

AND qsort(l, r) BE
{ WHILE l+8<r DO
   { LET midpt = (l+r)/2
      // Select a good(ish) median value.
      LET val   = middle(!l, !midpt, !r)
      LET i = partition(val, l, r)
      // Only use recursion on the smaller partition.
      TEST i>midpt THEN { qsort(i, r);   r := i-1 }
                   ELSE { qsort(l, i-1); l := i   }
   }

   FOR p = l+1 TO r DO  // Now perform insertion sort.
     FOR q = p-1 TO l BY -1 TEST q!0<=q!1 THEN BREAK
                                          ELSE { LET t = q!0
                                                  q!0 := q!1
                                                  q!1 := t
                                               }
}

AND middle(a, b, c) = a<b -> b<c -> b,
                                    a<c -> c,
                                           a,
                             b<c -> a<c -> a,
                                           c,
                                    b

AND partition(median, p, q) = VALOF
{ LET t = ?
   WHILE !p < median DO p := p+1
   WHILE !q > median DO q := q-1
   IF p>=q RESULTIS p
   t  := !p
   !p := !q
   !q := t
   p, q := p+1, q-1
} REPEAT

// ************************** Merge Sort ************************

AND mergesort(v, n) BE
{ LET work = getvec(n/2)
  IF work=0 DO
  { writef("Can't allocate workspace*n")
    RETURN
  }
  msort( v, v, n, work)
  freevec(work)   
}

AND msort(f, t, n, w) BE TEST n<8
THEN FOR i = 1 TO n DO
     { LET val = f!i
       LET j = i
       WHILE j>1 & val < t!(j-1) DO { t!j := t!(j-1); j := j-1 }
       t!j := val
     }
ELSE { LET n1 = n/4
       LET n2 = n/2
       LET n3 = n1+n2

//       f                                    w
//       |-------|-------|-------|-------|    |-------|-------|
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

       msort(f+n1,           w+n1, n2-n1, w)
       msort(   f, f+n1, n1,              w)
       merge(      f+n1, n1, w+n1, n2-n1, w)

       msort(f+n2, f, n1,             f+n1)
       msort(f+n3,        f+n3, n-n3, f+n2)
       merge(      f, n1, f+n3, n-n3, f+n2)

       merge( w, n2, f+n2, n-n2, t)
     }

AND merge(a, an, b, bn, t) BE
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

// ************************** Null Sort ************************

AND nullsort(v, n) BE RETURN

