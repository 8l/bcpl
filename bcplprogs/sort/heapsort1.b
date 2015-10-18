/*
A heapsort experiment implemented by Martin Richards February 1999

Modified May 2007 to include the strategy of push a newly inserted
root element all the way down to a leaf then applying the upheap
operation. This hopefully reduces the number of comparisons.
*/
 
GET "libhdr"

LET heapify(v, k, i, last) BE
{ LET p = i+i  // If there is a son (or two), j = subscript of first.
  LET s, x = ?, ?

  IF p>last DO { v!i := k; RETURN }
  // There is at least one son

  s := v+p
  x := s!0

  IF p<last & x<s!1 DO x, p := s!1, p+1

  IF k>=x DO { v!i := k; RETURN }

  v!i := x
  i := p
} REPEAT

AND heapsort(v, upb) BE
{ FOR i = upb/2 TO 1 BY -1 DO heapify(v, v!i, i, upb)

  FOR i = upb TO 2 BY -1 DO
  { LET k = v!i
    v!i := v!1
    heapify(v, k, 1, i-1)
  }
}

LET heapifynew(v, k, i, last) BE
{ // First push k down the heap via the larger child
  // until a leaf is found.
  { LET p = i+i  // If there is a son (or two), j = subscript of first.
    LET s, x = ?, ?

    IF p>last BREAK  // No children
    // There is at least one son

    s := v+p
    x := s!0

    IF p<last & x<s!1 DO x, p := s!1, p+1

    v!i := x    // Promote x
    i := p
  } REPEAT

  // Now perform the upheap operation
  // possible moving k up a small number of levels.
  WHILE i>1 DO
  { LET p = i/2 // Find the parent element.
    LET x = v!p
    IF k<=x BREAK
    v!i := x    // Demote x
    i := p
  }

  v!i := k // Store k in its proper position    
} 

AND heapsortnew(v, upb) BE
{ FOR i = upb/2 TO 1 BY -1 DO
    // Using heapifynew here slows it down a little. 
    heapify(v, v!i, i, upb)

  FOR i = upb TO 2 BY -1 DO
  { LET k = v!i
    v!i := v!1
    heapifynew(v, k, 1, i-1)
  }
}




MANIFEST { upb = 1_000_000  }

LET start() = VALOF
{ LET v = getvec(upb)

  try("heap",     heapsort,   v, upb)
  try("heapnew",  heapsortnew,  v, upb)

  writes("*nEnd of test*n")
  freevec(v)
  RESULTIS 0
}

AND try(name, sortroutine, v, upb) BE
{ // delay, referencing the first and last elements of v
  FOR i = 1 TO 50000 DO v!upb := v!1 
  writef("*nSetting %n words of data for %s sort*n", upb, name)
  FOR i = 1 TO upb DO v!i := randno(10000)
  writef("Entering %s sort routine*n", name)
  { LET t = sys(30)
    sortroutine(v, upb)
    writef("Sorting complete in %9.3d secs*n", sys(30)-t)
  }
  TEST sorted(v, upb)
  THEN writes("The data is now sorted*n")
  ELSE writef("### ERROR: %s sort does not work*n", name)
}

AND sorted(v, n) = VALOF
{ //FOR i = 1 TO n-1 UNLESS v!i<=v!(i+1) RESULTIS FALSE
  RESULTIS TRUE
}

/*
Typical run is as follows (on a 1.8GHz Centrino Duo):

0> c b heapsort1
bcpl heapsort1.b to heapsort1 hdrs BCPLHDRS 

BCPL (27 Jul 2006)
Code size =   704 bytes
0> heapsort1

Setting 1000000 words of data for heap sort
Entering heap sort routine
Sorting complete in     2.540 secs
The data is now sorted

Setting 1000000 words of data for heapnew sort
Entering heapnew sort routine
Sorting complete in     1.710 secs
The data is now sorted

End of test
4510> 

*/
