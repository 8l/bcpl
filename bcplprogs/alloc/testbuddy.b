/*
This is the test harness for various space allocators.

Implemented in BCPL by Martin Richards (c) October 2001
*/

GET "libhdr"

MANIFEST {
  blkupb = 1000 // Max number of allocated blocks
  Msize = 50000 // Specifies the number of words of available memory
}

GLOBAL {
  M:ug       // Memory of size Msize from which allocation is performed
             // M!0 .. M!(Msize-1)


  blkv       // blkv!1  .. blkv!blkp  are the blocks currently allocated
  blkvn      // blkvn!1 .. blkvn!blkp are their sizes
  blkp       // normally in range 1 .. blkupb
  allocated  // space currently allocated
  threshhold // space is freed before allocation
             // if allocated>threshhold

  // Functions defined in the allocator
  init       // init(v, upb)   initialise the allocator
  uninit     // uninit()       free any space used by the allocator
  alloc      // p := alloc(n)  allocate a block of size n
  free       // p := free(p)   free the block at position p
  prinfo     // prinfo()       output debugging info
}

LET start() = VALOF
{ LET sv = VEC 100

  M     := getvec(Msize-1)
  blkv  := getvec(blkupb)
  blkvn := getvec(blkupb)
  blkp  := 0

writef("M=%n blkv=%n blkvn=%n*n", M, blkv, blkvn)

  UNLESS M & blkv & blkvn DO
  { writef("Insufficient memory*n")
    IF M     DO freevec(M)
    IF blkv  DO freevec(blkv)
    IF blkvn DO freevec(blkvn)

    RESULTIS 20
  }

  setseed(123456)

  // Set the block size random distribution
  FOR i = 0 TO 100 DO
  { LET n = 0
    IF i>10 DO n := 1 
    IF i>20 DO n := 2 
    IF i>25 DO n := 3 
    IF i>30 DO n := 4 
    IF i>35 DO n := 5 
    IF i>40 DO n := 6 
    IF i>45 DO n := 7 
    IF i>50 DO n := 8 
    IF i>55 DO n := 9 
    IF i>60 DO n := 10 
    IF i>65 DO n := 11
    IF i>70 DO n := 12 
    IF i>75 DO n := 13
    IF i>80 DO n := 14
    IF i>84 DO n := 15
    IF i>88 DO n := 16
    IF i>92 DO n := 17
    IF i>96 DO n := 18
    IF i>98 DO n := 19
    IF i>99 DO n := 20

    IF n>18 DO n := 4
//n := n & 3
    sv!i := n 
  }
    
//writef("calling init*n")
  UNLESS init(M, Msize) DO   // Initialise the space allocation system
  { writef("Unable to initialise*n")
    IF M     DO freevec(M)
    IF blkv  DO freevec(blkv)
    IF blkvn DO freevec(blkvn)
    RESULTIS 0
  }

//writef("returned from init*n")

  allocated := 0
  threshhold := Msize/2

  // Exercise the space allocator
  FOR i = 1 TO 20 DO
  { IF i REM 10 = 0 DO writef("i=%n*n", i)

    // First free random blocks until the allocated space
    // if less than the threshhold
    WHILE allocated>threshhold DO
    { LET r = randno(blkp)         // Choose a random block to free

      writef("Freeing block: %i3 blkp=%n blkv!r=%x7 blkv!blkp=%x7*n",
                             r,  blkp,   blkv!r,    blkv!blkp)
      IF blkv!r>=0 DO
      { tryfree(blkv!r, blkvn!r)
        blkv!r, blkvn!r := blkv!blkp, blkvn!blkp
        blkp := blkp-1
      }
    }

    { LET n = sv!(randno(101)-1)   // Choose a random block size
      LET b = tryalloc(n)
      writef("Allocate block size %x7 at %x7*n", n, b)

      IF b>=0 DO
      { IF blkp>=blkupb DO 
        { writef("too many allocated blocks*n")
          abort(9999)
          blkp := 0
        }
        blkp := blkp+1
        blkv!blkp, blkvn!blkp := b, n
      }

      // Shade allocated blocks
      FOR i = 1 TO blkp DO
      { LET b, n = blkv!i, blkvn!i
        LET upb = (1<<n) - 1
        M!b, M!(b+upb) := 0, 0
        FOR i = 1 TO 4 + upb/5000 DO 
        { LET p = randno(upb+1) - 1
          LET x = M!(b+p)
          LOOP
        }
      }
    }
//    prinfo()
    prblks()
//    abort(1000)
  }

  uninit()
  IF M DO freevec(M)
  IF blkv DO freevec(blkv)
  IF blkvn DO freevec(blkvn)
  RESULTIS 0
}

AND tryalloc(n) = VALOF
{ LET p = alloc(n)
//  writef("trying to allocate block with n = %n*n", n)
//  TEST p<0 THEN writef("Allocation failed*n")
//           ELSE writef("Block at %x5 allocated*n", p)
  IF p>=0 DO
  { allocated := allocated + (1<<n)
//    writef("alloc: %x5 %i7  total allocated=%i9*n", p, 1<<n, allocated)
    // Mark start of allocation
    FOR i = 0 TO (1<<n) - 1 BY 200 DO { LET x = M!(p+i); LOOP }
  }
  RESULTIS p
}

AND tryfree(a, n) = VALOF
{ LET p = free(a, n)
//  writef("trying to free block %x5 of size %n*n", a, n)
//  IF p<0 DO writef("Freeing failed*n")
  IF p>=0 DO
  { allocated := allocated - (1<<n)
//    writef("free:  %x5 %i7  total allocated=%i9*n", a, 1<<n, allocated)
    // Mark end of allocation
    FOR i = 0 TO (1<<n) - 1 BY 200 DO { LET x = M!(a+i); LOOP }
  }
  RESULTIS p
}

AND prblks() BE
{ LET layout = 0
  writef("Allocated blocks:*n")
  FOR i = 1 TO blkp IF blkv!i>=0 DO
  { writef(" %x5/%i2", blkv!i, blkvn!i)
    layout := layout+1
    IF layout REM 7 = 0 DO newline()
  }
  newline()
}



