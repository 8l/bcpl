/*
This program implements performs an exhaustive search of the
game tree for the two person pentominoes game played on
an 8x8 board. The first person who is unable to place a
piece loses. This program demonstrates the first player
can force a win.

Implemented in BCPL by Martin Richards (c) August 2000

ref: 
Orman, H.K. "Pentominoes: A First Player Win", In "Games of No
Chance" ed. Nowakowski R.J., MSRI Publications, Vol 29, 1996.
*/

GET "libhdr"

GLOBAL {
  count:ug 
  stackv; stackp; stackt; p0; q0; p1; q1
  hashtab

  path       // Given initial path
  w1v; w0v   // Vectors representing the move placements
  mvn        // Vector of move numbers
  mvt        // Vector of number of moves at each level

  chs        // Vector of chars used by pr
  w1bits64   // Active w1 bits at this 64 bit level
  w0bits64   // Active w0 bits at this 64 bit level
  pbits64    // Active piece bits at this level
  prn64      // The first level to use the 64 bit representation
  w1bits32   // Active w1 bits at this 32 bit level
  w0bits32   // Active w0 bits at this 32 bit level
  prn32      // The first level to use the 32 bit representation

  prw1; prw0 // Global variables used by exp32, exp64 and pr

  // Global functions
  setups; mappieces; freestack; addminrot; addallrots
  init; addpos; reflect; rotate; bits
  try76; cmp64; try64; cmp32; try32
  pr; cmpput64; exp64; cmpput32; exp32
}

MANIFEST {
  P1=1;    P2=1<<1; P3=1<<2; P4 =1<<3; P5 =1<<4;  P6 =1<<5
  P7=1<<6; P8=1<<7; P9=1<<8; P10=1<<9; P11=1<<10; P12=1<<11

  Hashtabsize =4001  // Large enough for 2308 entries
}

LET setup() = VALOF
{  // Initialise the set of possible piece placements on
   // the 8x8 board allowing for all rotations, reflections
   // and translations. The generate the set of truly
   // distinct first moves.

   stackv := getvec(500000)
   stackt := @ stackv!500000
   stackp := stackv

   p1 := stackp
   mappieces(addallrots)
   q1 := stackp
   writef("*nThere are %i4 possible first moves", (q1-p1)/3)

   p0 := stackp
   mappieces(addminrot)
   q0 := stackp
   writef("*nof which  %i4 are truly distinct*n", (q0-p0)/3)
}

AND mappieces(f) BE
{  hashtab := getvec(Hashtabsize)
   FOR i = 0 TO Hashtabsize DO hashtab!i := 0

   init(f,     #x1F, P1)  //  * * * * *     *
   init(f, #x020702, P2)  //              * * *
                          //                *

   init(f,   #x010F, P3)  //  * * * *         *
   init(f, #x010701, P4)  //        *     * * *
                          //                  *

   init(f,   #x0703, P5)  //    * *       * * *
   init(f,   #x030E, P6)  //  * * *           * *

   init(f, #x070101, P7)  //      *       *
   init(f, #x030604, P8)  //      *       * *
                          //  * * *         * *

   init(f,   #x0507, P9)  //  * * *       *
   init(f, #x010704, P10) //  *   *       * * *
                          //                  *

   init(f,   #x0F02, P11) //      *          *
   init(f, #x010702, P12) //  * * * *      * * *
                          //                   *

   freevec(hashtab)
}

AND freestack() BE freevec(stackv)

AND addminrot(w1, w0, piece) BE
{ LET mw1=w1
  AND mw0=w0

  rotate(@w1)
  IF w1<mw1 | w1=mw1 & w0<mw0 DO mw1, mw0 := w1, w0
  rotate(@w1)
  IF w1<mw1 | w1=mw1 & w0<mw0 DO mw1, mw0 := w1, w0
  rotate(@w1)
  IF w1<mw1 | w1=mw1 & w0<mw0 DO mw1, mw0 := w1, w0

  reflect(@w1)

  IF w1<mw1 | w1=mw1 & w0<mw0 DO mw1, mw0 := w1, w0
  rotate(@w1)
  IF w1<mw1 | w1=mw1 & w0<mw0 DO mw1, mw0 := w1, w0
  rotate(@w1)
  IF w1<mw1 | w1=mw1 & w0<mw0 DO mw1, mw0 := w1, w0
  rotate(@w1)
  IF w1<mw1 | w1=mw1 & w0<mw0 DO mw1, mw0 := w1, w0

  addpos(mw1, mw0, piece) 
}

AND addallrots(w1, w0, piece) BE
{ addpos(w1, w0, piece)
  rotate(@w1)
  addpos(w1, w0, piece)
  rotate(@w1)
  addpos(w1, w0, piece)
  rotate(@w1)
  addpos(w1, w0, piece)

  reflect(@w1)

  addpos(w1, w0, piece)
  rotate(@w1)
  addpos(w1, w0, piece)
  rotate(@w1)
  addpos(w1, w0, piece)
  rotate(@w1)
  addpos(w1, w0, piece)
}

AND init(f, word0, piece) BE
{ LET word1 = 0

  { LET w1=word1
    AND w0=word0 

    { f(w1, w0, piece)
      IF ((w0|w1) & #x80808080)~=0 BREAK // can't move left any more
      w1 := w1<<1                        // move piece left one place
      w0 := w0<<1
    } REPEAT
    
    IF (word1 & #xFF000000)~=0 RETURN

    word1 := word1<<8 | word0>>24       // shift (word1,word0) left 8
    word0 := word0<<8
  } REPEAT
}

AND addpos(w1, w0, piece) BE
{ LET hashval = ABS((w1+1)*(w0+3)) REM Hashtabsize

  { LET p = hashtab!hashval

    UNLESS p DO { hashtab!hashval := stackp // Make new entry
                  stackp!0 := w1
                  stackp!1 := w0
                  stackp!2 := piece
                  stackp := stackp+3
                  RETURN
                }

    IF p!0=w1 & p!1=w0 RETURN             // Match found

    hashval := hashval+1
    IF hashval>Hashtabsize DO hashval := 0
  } REPEAT
}

AND reflect(p) BE // Repflect p!0,p!1 about the vertical centre line
{ LET w1 = p!0
  AND w0 = p!1
  p!1 := (w0&#x01010101)<<7 | (w0&#x80808080)>>7 |
         (w0&#x02020202)<<5 | (w0&#x40404040)>>5 |
         (w0&#x04040404)<<3 | (w0&#x20202020)>>3 |
         (w0&#x08080808)<<1 | (w0&#x10101010)>>1

  p!0 := (w1&#x01010101)<<7 | (w1&#x80808080)>>7 |
         (w1&#x02020202)<<5 | (w1&#x40404040)>>5 |
         (w1&#x04040404)<<3 | (w1&#x20202020)>>3 |
         (w1&#x08080808)<<1 | (w1&#x10101010)>>1
}

AND rotate(p) BE // Rotate right about the mid point
{ LET w1 = p!0
  AND w0 = p!1

  LET a = (w0&#x0F0F0F0F)<<4 | w1&#x0F0F0F0F
  LET b = (w1&#xF0F0F0F0)>>4 | w0&#xF0F0F0F0

  a  := (a & #X00003333)<<2 | (a & #X0000CCCC)<<16 |
        (a & #XCCCC0000)>>2 | (a & #X33330000)>>16

  b  := (b & #X00003333)<<2 | (b & #X0000CCCC)<<16 |
        (b & #XCCCC0000)>>2 | (b & #X33330000)>>16

  p!1 := (a & #X00550055)<<1 | (a & #X00AA00AA)<<8  |
         (a & #XAA00AA00)>>1 | (a & #X55005500)>>8

  p!0 := (b & #X00550055)<<1 | (b & #X00AA00AA)<<8  |
         (b & #XAA00AA00)>>1 | (b & #X55005500)>>8
}

AND bits(w) = w=0 -> 0, 1 + bits(w&(w-1))


AND start() = VALOF
{ LET argv = VEC 50
  LET stdout = output()

  UNLESS rdargs(",,,,,,,,,,,,TO/K", argv, 50) DO
  { writef("Bad arguments*n")
    RESULTIS 0
  }

  path := getvec(12)
  w1v  := getvec(12)
  w0v  := getvec(12)
  mvn  := getvec(12)
  mvt  := getvec(12)

  chs := getvec(64)
  prn64 := 20
  prn32 := 20

  FOR i = 0 TO 11 DO path!(i+1) := argv!i -> str2numb(argv!i), -1

  IF argv!12 DO selectoutput(findoutput(argv!12))

  setup()

  // (p1,q1) holds the set of all 2308 distinct moves
  // (p0,q0) holds the set of the 296 symmetrically distinct moves

  TEST try76(1, p0, q0, p1, q1)
  THEN writes("*nFirst player can force a win*n")
  ELSE writes("*nFirst player cannot force a win*n")

  freestack()

  IF argv!12 DO endwrite()

  RESULTIS 0
}

AND try76(n, p, q, np, nq) = VALOF
{ LET s = stackp   // Base of new possible move set
  AND t = p        // Position of next move to try
  AND lim = q      // End of current move set

  UNLESS path!n<0 DO        // Use the path is given
  { t := @p!(3*(path!n-1))
    IF t<lim DO lim := t+1
  }

  WHILE t < lim DO
  { LET w1, w0, piece = t!0, t!1, t!2 // Choose a move
    LET r = np
    LET w1bits, w0bits, pbits = 0, 0, 0
    t := t+3

    w1v!n, w0v!n := w1, w0            // Save the move for printing
    mvn!n, mvt!n := (t-p)/3, (q-p)/3

    IF path!n>=0 & path!(n+1)<0 DO
    { writef("*nConsidering board position:")
      FOR i = 1 TO n DO writef(" %n/%n", mvn!i, mvt!i)
      newline()
      newline()
      pr(n)
    }

    stackp := s

    UNTIL r>=nq DO      // Form the set of of possible replies
    { LET a, b, c = r!0, r!1, r!2
      r := r+3
      IF (a&w1)=0 & (b&w0)=0 & (c&piece)=0 DO
      { stackp!0, stackp!1, stackp!2 := a, b, c
        stackp := stackp+3
        w1bits := w1bits | a
        w0bits := w0bits | b
        pbits  := pbits  | c
      }
    }

    // The possible replies are stored between s and stackp

    IF s=stackp      // There are no replies 
      RESULTIS TRUE  // so the chosen move is a winner

    // Explore the possible replies
    TEST n>=2 & path!(n+1)<0
    THEN UNLESS cmp64(n+1, s, stackp, w1bits, w0bits, pbits) RESULTIS TRUE
    ELSE UNLESS try76(n+1, s, stackp, s, stackp  )           RESULTIS TRUE
  } 

  // We cannot find a winning move from the available moves
  stackp := s
  RESULTIS FALSE
}

AND cmp64(n, p, q, w1bits, w0bits, pbits) = VALOF
{ LET s = stackp
  AND res = 0

  // w1bits, w0bits and pbits describe how the bits are packed
  // into two 32 bit words
  w1bits64, w0bits64, pbits64, prn64 := w1bits, w0bits, pbits, n

  // Compress the representation of the moves from 76 to 64 bits.
  FOR t = p TO q-1 BY 3 DO cmpput64(t!0, t!1, t!2)

  res := try64(n, s, stackp)

  prn64 := 20
  stackp := s
  RESULTIS res
}

AND try64(n, p, q) = VALOF
{ LET s=stackp
  AND t=p

  WHILE t < q DO
  { LET w1, w0 = t!0, t!1     // Choose a move
    LET r = p
    AND w1bits, w0bits = 0, 0
    t := t+2
    stackp := s

    w1v!n, w0v!n := w1, w0
    mvn!n, mvt!n := (t-p)/2, (q-p)/2

    IF n=4 DO
    { writef("*n*nTrying Move %n: %i3/%n:*n", n, mvn!n, mvt!n)
      pr(n)
    }
    IF n=5 DO newline()
    IF n=6 DO
    { FOR i = 1 TO n DO writef("%i3/%n ", mvn!i, mvt!i)
      writes("      *c")
    }

    UNTIL r>=q DO      // Form the set of of possible replies
    { LET a, b = r!0, r!1
      r := r+2
      IF (a&w1)=0 & (b&w0)=0 DO
      { stackp!0, stackp!1 := a, b
        stackp := stackp+2
        w1bits := w1bits | a
        w0bits := w0bits | b
      }
    }

    // The possible replies are stored between s and stackp

    IF s=stackp       // There are no replies 
      RESULTIS TRUE   // so move n is a winner

    // See if this move n is a winner
    TEST bits(w1bits) + bits(w0bits) <= 32
    THEN UNLESS cmp32(n+1, s, stackp, w1bits, w0bits) RESULTIS TRUE
    ELSE UNLESS try64(n+1, s, stackp)                 RESULTIS TRUE
  } 

  // We cannot find a winning move from the available moves
  stackp := s
  RESULTIS FALSE
}

AND cmp32(n, p, q, w1bits, w0bits) = VALOF 
{ LET s = stackp
  LET res = 0

  // w1bits and w0bits describe how the bits were packed in a 32 bit word
  w1bits32, w0bits32, prn32 := w1bits, w0bits, n
  

  // Compact the representation of the moves from 64 to 32 bits.
  FOR t = p TO q-1 BY 2 DO cmpput32(t!0, t!1)

  res := try32(n, s, stackp)

  prn32 := 20
  stackp := s
  RESULTIS res
}


AND try32(n, p, q) = VALOF
{ LET s=stackp
  LET t=p

  WHILE t < q DO
  { LET w0 = t!0     // Choose a move
    LET r = p
    t := t+1

    w1v!n, w0v!n := 0, w0
    mvn!n, mvt!n := t-p, q-p

//    FOR i = 1 TO n DO writef(" %n/%n", mvn!i, mvt!i)
//    newline()
//    pr(n)
//abort(1000)

    stackp := s

    FOR r = p TO q-1 IF (r!0&w0)=0 DO
    { stackp!0 := r!0
      stackp := stackp+1
    }
//    UNTIL r>=q DO      // Form the set of possible replies
//    { LET a = r!0
//      r := r+1
//      IF (a&w0)=0 DO { stackp!0 := a; stackp := stackp+1 }
//    }

    IF s=stackp RESULTIS TRUE      // Move n is a winner
    IF n=11 LOOP                   // Move n is a loser
    UNLESS try32(n+1, s, stackp) RESULTIS TRUE
  } 

  // We cannot find a winning move from the available moves
  stackp := s
  RESULTIS FALSE
}

AND pr(n) BE
{ FOR i = 1 TO 64 DO chs%i := '.'

  FOR p = 1 TO n DO
  { LET ch = 'A'+p-1
    IF p=n DO ch := '**'
    prw1, prw0 := w1v!p, w0v!p

    IF p>=prn32 DO exp32()  // expand from 32 to 64 bits
    IF p>=prn64 DO exp64()  // expand from 64 to 76 bits
    // prw1 and prw0 now contain the board bits

    FOR i = 1 TO 64 DO  // Convert to and 8x8 array of chars
    { IF (prw0&1)~=0 DO chs%i := ch
      prw0 := prw0>>1
      UNLESS i REM 32 DO prw0 := prw1
    }
  }

  FOR i = 1 TO 64 DO    // Output the 8x8 array
  { writef(" %c", chs%i)
    IF i REM 8 = 0  DO newline()
  }
  newline()
}

AND cmpput64(w1, w0, piece) BE
{ LET w1bits = ~w1bits64  // Pos of unused bits in w1
  AND w0bits = ~w0bits64  // Pos of unused bits in w0
  AND pbits  =   pbits64  // Pos of piece bits to pack into w1 and w0

  WHILE pbits & w0bits DO // While there are still piece bits to pack
                          // and space in w0
  { LET w0bit = w0bits & -w0bits // A free w0 bit
    LET pbit  = pbits  & -pbits  // A piece bit to pack
    IF (piece&pbit)~=0 DO
                w0 := w0 | w0bit // Move a piece bit into w0
    pbits  :=  pbits -  pbit
    w0bits := w0bits - w0bit
  }

  WHILE pbits & w1bits DO // While there are still piece bits to pack
                          // and space in w1
  { LET w1bit = w1bits & -w1bits // A free w1 bit
    LET pbit  = pbits  & -pbits  // A piece bit to pack
    IF (piece&pbit)~=0 DO
                w1 := w1 | w1bit // Move a piece bit into w1
    pbits  := pbits - pbit
    w1bits := w1bits - w1bit
  }

  stackp!0, stackp!1 := w1, w0
  stackp := stackp+2
}

AND exp64() = VALOF
{ prw1 := prw1 & w1bits64  // Remove the piece bits from
  prw0 := prw0 & w0bits64  // the w1 and w0 bit patterns
}

AND cmpput32(w1, w0) BE
{ LET w1bits =  w1bits32
  AND w0bits = ~w0bits32

  WHILE w1bits & w0bits DO // While there are still w1 bits to pack
                           // and space in w0
  { LET w1bit = w1bits & -w1bits    // A bit in w1 to pack in a
    LET w0bit = w0bits & -w0bits    // free bit of w0
    IF (w1&w1bit)~=0 DO w0 := w0 | w0bit // Move a w1 bit into w0
    w1bits := w1bits - w1bit
    w0bits := w0bits - w0bit
  }
  stackp!0 := w0
  stackp := stackp+1
}

AND exp32() = VALOF // Move various bits from prw0 into prw1
{ LET w1bits =  w1bits32
  AND w0bits = ~w0bits32
  prw1 := 0
  WHILE w1bits & w0bits DO
  { LET w1bit = w1bits & -w1bits
    LET w0bit = w0bits & -w0bits
    IF (prw0&w0bit)~=0 DO { prw0 := prw0 - w0bit
                            prw1 := prw1 | w1bit
                          }
    w1bits := w1bits - w1bit
    w0bits := w0bits - w0bit
  }
}
