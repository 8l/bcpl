/*

This will be an implementataion of the buddy system for space
allocation. It is loosely based on the buddy program written by
W.A.Wulf in BLISS submitted to the IFIP/TC-2 Working Conference on
Machine-Oriented Higher Level Languages, August 10, 1973.

Implemented in BCPL by Martin Richards (c) March 2004

*/

GET "testbuddy.b"

// This module defines:

// init(upb)     Initialise the package
// uninit()      Close down the package
// alloc(upb)    Allocate a block
// free(p)       Free a block

GLOBAL {
  list:300   // list!i is a list of free blocks of size 1<<i
             // list!0 .. list!30
  mask       // mask!0=0, mask!1=#b0001, mask!2=#b0011, etc
  mem        // memory from which space is allocated


}

// Find smallest n for which 2**n >= w
LET lg2(w) = VALOF
{ LET t = TABLE
      0,0,1,1,2,2,2,2,3,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,
      5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,
      6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,
      6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,
      7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,
      7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,
      7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,
      7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7
  LET c = (w = (w & -w)) + 1 // =0 if w is a power of 2, =1 otherwise
  UNLESS w>>8  RESULTIS t!w            + c
  UNLESS w>>16 RESULTIS t!(w>> 8) +  8 + c
  UNLESS w>>24 RESULTIS t!(w>>16) + 16 + c
  RESULTIS              t!(w>>24) + 24 + c
}


//LET start() = VALOF
//{
//  FOR i = 0 TO 512 DO writef("%bG: %i2*n", i, lg2(i))
//  RESULTIS 0
//}

LET init(v, size) = VALOF
{ LET k, p = lg2(size), 0

  writef("Memory size = %n  k = %n*n", size, k)

  mask, list := getvec(30), getvec(30)
  mem := v
  
  UNLESS mask & list DO
  { writef("Insufficient memory*n")
    abort(9999)
    uninit()
    RESULTIS FALSE
  }

  FOR k = 30 TO 0 BY -1 DO // Never allocate a block smaller than 2 words
  { // Make initial free lists
    LET sz = 1<<k
    mask!k := sz-1
    TEST p+sz <= size
    THEN { list!k := p       // Put a block of sz words onto list k
           //writef("%i7: k=%i2  free block size=%i7*n", p, k, sz)
           mem!p := -1       // It is the only block in this list
           mem!(p+1) := k    // Its size index
           p := p+sz         // Position of next block
         }
    ELSE list!k := -1        // This list is empty
  }

//prinfo()
  RESULTIS TRUE
}

AND uninit() BE
{ IF mask DO freevec(mask)
  IF list DO freevec(list)
  mask, list := 0, 0
}

AND collapse(a, k) BE
{ LET b = list!k
//  writef("collapse: block %x5 size %n*n", a, n)
  WHILE b>=0 TEST (a XOR b) = 1<<k  // Test if buddies
             THEN { list!k := mem!b  // Delink b
//                    writef("collapse: combine with buddy %x5*n", b)
                    collapse(b & ~(1<<k), k+1) // 
                    RETURN
                  }
             ELSE b := mem!b

  // Block a cannot be combined with its buddy
  // so insert into list of blocks of size n
  mem!a, mem!(a+1) := list!k, k
  list!k := a
//  writef("collapse: insert block %x5 into list!%n*n", a, k)
}

// alloc returns subscript of block of size 1<<lgsize
//               or -1 if no suitable block available

AND alloc(upb) = VALOF
{ LET k = lg2(upb+2)
  UNLESS 1 <= k <= 30 RESULTIS -1
//  writef("alloc: k=%n*n", k)
  TEST list!k >= 0
  THEN { LET p = list!k  // Delink the first
         list!k := mem!p
//         writef("alloc: block %x5 found in L!%n*n", p, n)
         RESULTIS p
       }
  ELSE { LET t0 = alloc(2*upb+1)  // Allocate a block of next larger size
         LET t1 = t0 + (1<<k)
         IF t0<0 RESULTIS -1
         mem!t1, mem!(t1+1) := list!k, k   // free the second half
         list!k := t1
//         writef("alloc: Split block %x5 freeing second half %x5*n", t0, t1)
//         writef("alloc: block %x5 size %n allocated*n", t0, n)
         RESULTIS t0          // allocate the first half
       }
}

AND free(p) = VALOF
{ // free the block at position p
  // Return 0 if successful, -1 otherwise.
  LET k = mem!(p+1)

//  writef("free: p=%x5 n=%n*n", p, n)
  UNLESS 0<=k<=30 RESULTIS -1
//  writef("k is OK*n")
  UNLESS (p & mask!k) = 0 RESULTIS -1 // Safety check
//  writef("p is OK*n")

  // Safety check -- make sure we are not freeing a block
  // that contains free blocks
  FOR i = 0 TO k-1 DO
  { LET q = list!i
    WHILE q>=0 TEST (p NEQV q) < 1<<k
                THEN RESULTIS -1
                ELSE q := mem!q
  }
//  writef("safety check 1 is OK*n")

  // Safety check -- make sure we are not freeing a block
  // that is already free
  { LET q = list!k
    WHILE q>=0 TEST p=q
               THEN RESULTIS -1
               ELSE q := mem!q
  }
//  writef("safety check 2 is OK*n")

  // Safety check -- make sure we are not freeing a block
  // that is contained in another free block
  FOR i = k+1 TO 30 DO
  { LET q = list!i
    WHILE q>=0 TEST (p NEQV q) < 1<<i
                THEN RESULTIS -1
                ELSE q := mem!q
  }
//  writef("safety check 3 is OK*n")

  collapse(p, k)
}

AND prinfo() BE
{ FOR i = 0 TO 30 DO
  { LET p = list!i
    IF p<0 LOOP
    writef("%i2 %x7:", i, 1<<i)
    WHILE p>=0 DO { writef(" %x7", p); p := mem!p }
    newline()
  }
}


