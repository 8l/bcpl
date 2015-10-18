/*
This program is designed to find a minimum cost solution to
a sliding blocks puzzle.

Implemented in BCPL by Martin Richards  (c) August 2003

The puzzle is played on a 4x5 board on which 10 blocks can slide.
There are four unit blocks (U), four 1x2 blocks (V) oriented
vertically, one 2x1 block (H) oriented horizontally and one 2x2 block
(S). This initial position of the blocks is as follows:

          -----------------------
         |     | SSSSSSSSS |     |
         |     | SSSSSSSSS |     |
         |-----| SSSSSSSSS |-----|
         | VVV | SSSSSSSSS | VVV |
         | VVV | SSSSSSSSS | VVV |
         | VVV |-----------| VVV |
         | VVV | UUU | UUU | VVV |
         | VVV | UUU | UUU | VVV |
         |-----+-----+-----+-----|
         | VVV | UUU | UUU | VVV |
         | VVV | UUU | UUU | VVV |
         | VVV |-----------| VVV |
         | VVV | HHHHHHHHH | VVV |
         | VVV | HHHHHHHHH | VVV |
          -----------------------

The aim is to slide the blocks until the 2x2 square is positioned
centrally at the bottom. It is believed this takes a minimum of 114
moves, where a move is defined to be moving one block one position up,
down, left or right by one place.

Implementation

The board is represented by a bit pattern with one bit to indicate
the occupancy of each square on the board.

The vector bitsS holds bit patterns representing the 12 possible
placements of the 2x2 block.

The vector bitsH holds bit patterns representing the 15 possible
placements of the horizontally oriented 2x1 block.

The vector bitsV holds bit patterns representing the 16 possible
placements of a vertically oriented 1x2 block.

The vector bitsU holds bit patterns representing the 20 possible
placements of a 1x1 block.

A particular placement of the 2x2 block can be represented by a
placement number p in the range 1 to 12. The bit pattern representing
which board positions it occupies is bitsS!p. Its immediately adjacent
placements are held in the vector succsS!p. If we call this vector v,
v!0=n is the number adjacent placements and v!1 ,.., v!n are the
placements.

The vectors succsH, succsV and succsU contain adjacency information
for the 2x1, 1x2 and 1x1 blocks in a form similar to succsS.

The vector bitsV4 contains composite placements of the four vertical
blocks and succsV4 contains the corresponding adjacency information.
For a particular composite placement of the vertical blocks, p say,
the bit pattern is bitsV4!p and compV4!p is a vector identifying the
four component vertical block composing it. If compV4!p = v, the
elements v!1 ,.., v!4 are the placements of the components.  The upper
bound of bitsV4 is 886.

The vectors bitsU4, succsU4 and compU4 are defined similarly. The
upper bound of bitsU4 is C(20,4) = 4845.

A valid board placements are held in bitsB, the successors are held in
succsB. There are 65880 legal placements of all the pieces. If p is a
board placement, compB!p!1 ,.., compB!p!4 identify the components from
bitsS, bitsH, bitsV4 and bitsU4, respectively.  The element dist!p
will hold the length of the shortest path from the initial board
position to that corresponding to p. For the initial position the
value is zero and all the other are initial set to -1.  (representing
infinity). The algorithm uses a breadth first search to compute all
the elements of dist. Whenever an element of dist changes from -1 the
corresponding element of a second vector prev is set to the number of
the previous placement so that minimun length paths can be generated
if needed. When the search has finished any remaining -1s in dist
correspond to unreachable board positions.

The program currently shows that a solution can be found in 84 moves
and that of the 25955 reachable board positions there are four that
are most distant from the initial position taking 133 moves to reach.
These positions are:

          -----------------------           -----------------------
         | UUU | UUU | VVV | UUU |         |     | VVV | VVV | UUU |
         | UUU | UUU | VVV | UUU |         |     | VVV | VVV | UUU |
         |-----+-----| VVV |-----|         |-----+ VVV | VVV |-----|
         | VVV | VVV | VVV |     |         | UUU | VVV | VVV |     |
         | VVV | VVV | VVV |     |         | UUU | VVV | VVV |     |
         | VVV | VVV |-----------|         |-----+-----+-----------|
         | VVV | VVV | HHHHHHHHH |   and   | UUU | VVV | HHHHHHHHH |
         | VVV | VVV | HHHHHHHHH |         | UUU | VVV | HHHHHHHHH |
         |-----+-----+-----------|         |-----+ VVV |-----------|
         | UUU | VVV | SSSSSSSSS |         | VVV | VVV | SSSSSSSSS |
         | UUU | VVV | SSSSSSSSS |         | VVV | VVV | SSSSSSSSS |
         |-----| VVV | SSSSSSSSS |         | VVV |-----| SSSSSSSSS |
         |     | VVV | SSSSSSSSS |         | VVV | UUU | SSSSSSSSS |
         |     | VVV | SSSSSSSSS |         | VVV | UUU | SSSSSSSSS |
          -----------------------          -----------------------

and their mirror images. No reachable position has the horizontal
block in the top row.

*/

GET "libhdr"

GLOBAL {
  bitsS:ug; succsS
  bitsH;    succsH
  bitsV;    succsV
  bitsU;    succsU
  bitsV4;   succsV4; compV4
  bitsU4;   succsU4; compU4
  bitsB;    succsB;  compB;  dist;  prev; solv; id

  spacev; spacep; spacet

  tracing
  solution
  count
}

MANIFEST {
  Spaceupb  = 1_200_000
  bitsV4upb =       886
  bitsU4upb =      4845
  bitsBupb  =     65880
}

LET start() = VALOF
{ LET argv = VEC 50
  LET stdout = output()
  LET out = stdout

  UNLESS rdargs("-o/k,-t/s,-s/s", argv, 50) DO
  { writef("Bad arguments for blks*n")
    RESULTIS 20
  }

  IF argv!0 DO
  { out := findoutput(argv!0)
    UNLESS out DO
    { writef("Unable to open output file %s*n", argv!0)
      RESULTIS 20
    }
    selectoutput(out)
  }

  tracing := argv!1
  solution := argv!2
  count := 0

  spacev := getvec(Spaceupb)
  spacep, spacet := spacev, spacev+Spaceupb
  UNLESS spacev DO
  { writef("Insufficient space available*n")
    RESULTIS 20
  }

//  writef("blks2 entered*n")

  initvecs()
  writef("initialisation done*n")

  search()

  writef("End of search*n")

fin:
  UNLESS out=stdout DO endwrite()
  freevec(spacev)
  RESULTIS 0
}

AND mkvec(n) = VALOF
{ LET p = spacep
  spacep := spacep+n+1
  IF spacep>spacet DO
  { writef("Insufficient space*n")
    abort(999)
    RESULTIS 0
  }
  RESULTIS p
}

AND mkinitvec(n, a, b, c, d) = VALOF
{ LET p = spacep
  spacep := spacep+n+1
  IF spacep>spacet DO
  { writef("Insufficient space*n")
    abort(999)
    RESULTIS 0
  }
  FOR i = 0 TO n DO p!i := (@n)!i
  RESULTIS p
}

AND initvecs() BE
{ // 2x2 square block
  bitsS := TABLE 12,    // placement bits
           #xCC000,    #x66000,    #x33000,   //  1  2  3
           #x0CC00,    #x06600,    #x03300,   //  4  5  6
           #x00CC0,    #x00660,    #x00330,   //  7  8  9
           #x000CC,    #x00066,    #x00033    // 10 11 12
  succsS := mkvec(12)
  succsS! 0 := 12
  succsS! 1 := mkinitvec(2,          2,  4)
  succsS! 2 := mkinitvec(3,      1,  3,  5)
  succsS! 3 := mkinitvec(2,      2,      6)
  succsS! 4 := mkinitvec(3,  1,      5,  7)
  succsS! 5 := mkinitvec(4,  2,  4,  6,  8)
  succsS! 6 := mkinitvec(3,  3,  5,      9)
  succsS! 7 := mkinitvec(3,  4,      8, 10)
  succsS! 8 := mkinitvec(4,  5,  7,  9, 11)
  succsS! 9 := mkinitvec(3,  6,  8,     12)
  succsS!10 := mkinitvec(2,  7,     11    )
  succsS!11 := mkinitvec(3,  8, 10, 12    )
  succsS!12 := mkinitvec(2,  9, 11        )

  // 2x1 horizontal block
  bitsH := TABLE 15,    // placement bits
           #xC0000,    #x60000,    #x30000,   //  1  2  3
           #x0C000,    #x06000,    #x03000,   //  4  5  6
           #x00C00,    #x00600,    #x00300,   //  7  8  9
           #x000C0,    #x00060,    #x00030,   // 10 11 12
           #x0000C,    #x00006,    #x00003    // 13 14 15

  succsH := mkvec(15)
  succsH! 0 := 15
  succsH! 1 := mkinitvec(2,          2,  4)
  succsH! 2 := mkinitvec(3,      1,  3,  5)
  succsH! 3 := mkinitvec(2,      2,      6)
  succsH! 4 := mkinitvec(3,  1,      5,  7)
  succsH! 5 := mkinitvec(4,  2,  4,  6,  8)
  succsH! 6 := mkinitvec(3,  3,  5,      9)
  succsH! 7 := mkinitvec(3,  4,      8, 10)
  succsH! 8 := mkinitvec(4,  5,  7,  9, 11)
  succsH! 9 := mkinitvec(3,  6,  8,     12)
  succsH!10 := mkinitvec(3,  7,     11, 13)
  succsH!11 := mkinitvec(4,  8, 10, 12, 14)
  succsH!12 := mkinitvec(3,  9, 11,     15)
  succsH!13 := mkinitvec(2, 10, 14        )
  succsH!14 := mkinitvec(3, 11, 13, 15    )
  succsH!15 := mkinitvec(2, 12, 14        )

  // 1x2 vertical block
  bitsV := TABLE 16,    // placement bits
           #x88000,    #x44000,    #x22000,    #x11000,  //  1  2  3  4
           #x08800,    #x04400,    #x02200,    #x01100,  //  5  6  7  8
           #x00880,    #x00440,    #x00220,    #x00110,  //  9 10 11 12
           #x00088,    #x00044,    #x00022,    #x00011   // 13 14 15 16

  succsV := mkvec(16)
  succsV! 0 := 16
  succsV! 1 := mkinitvec(2,          2,  5)
  succsV! 2 := mkinitvec(3,      1,  3,  6)
  succsV! 3 := mkinitvec(3,      2,  4,  7)
  succsV! 4 := mkinitvec(2,      3,      8)
  succsV! 5 := mkinitvec(3,  1,      6,  9)
  succsV! 6 := mkinitvec(4,  2,  5,  7, 10)
  succsV! 7 := mkinitvec(4,  3,  6,  8, 11)
  succsV! 8 := mkinitvec(3,  4,  7,     12)
  succsV! 9 := mkinitvec(3,  5,     10, 13)
  succsV!10 := mkinitvec(4,  6,  9, 11, 14)
  succsV!11 := mkinitvec(4,  7, 10, 12, 15)
  succsV!12 := mkinitvec(3,  8, 11,     16)
  succsV!13 := mkinitvec(2,  9,     14    )
  succsV!14 := mkinitvec(3, 10, 13, 15    )
  succsV!15 := mkinitvec(3, 11, 14, 16    )
  succsV!16 := mkinitvec(2, 12, 15        )

  // 1x1 unit squares
  bitsU := TABLE 20,    // placement bits
           #x80000,    #x40000,    #x20000,    #x10000,  //  1  2  3  4
           #x08000,    #x04000,    #x02000,    #x01000,  //  5  6  7  8
           #x00800,    #x00400,    #x00200,    #x00100,  //  9 10 11 12
           #x00080,    #x00040,    #x00020,    #x00010,  // 13 14 15 16
           #x00008,    #x00004,    #x00002,    #x00001   // 17 18 19 20

  succsU := mkvec(20)
  succsU! 0 := 20
  succsU! 1 := mkinitvec(2,          2,  5)
  succsU! 2 := mkinitvec(3,      1,  3,  6)
  succsU! 3 := mkinitvec(3,      2,  4,  7)
  succsU! 4 := mkinitvec(2,      3,      8)
  succsU! 5 := mkinitvec(3,  1,      6,  9)
  succsU! 6 := mkinitvec(4,  2,  5,  7, 10)
  succsU! 7 := mkinitvec(4,  3,  6,  8, 11)
  succsU! 8 := mkinitvec(3,  4,  7,     12)
  succsU! 9 := mkinitvec(3,  5,     10, 13)
  succsU!10 := mkinitvec(4,  6,  9, 11, 14)
  succsU!11 := mkinitvec(4,  7, 10, 12, 15)
  succsU!12 := mkinitvec(3,  8, 11,     16)
  succsU!13 := mkinitvec(3,  9,     14, 17)
  succsU!14 := mkinitvec(4, 10, 13, 15, 18)
  succsU!15 := mkinitvec(4, 11, 14, 16, 19)
  succsU!16 := mkinitvec(3, 12, 15,     20)
  succsU!17 := mkinitvec(2, 13,     18    )
  succsU!18 := mkinitvec(3, 14, 17, 19    )
  succsU!19 := mkinitvec(3, 15, 18, 20    )
  succsU!20 := mkinitvec(2, 16, 19        )

  bitsV4  := mkvec(bitsV4upb)
  succsV4 := mkvec(bitsV4upb)
  compV4  := mkvec(bitsV4upb)

  // Form the V4 bit patterns
writef("*nFinding V4 bit patterns*n")
  { LET p = 0
    FOR a = 1 TO bitsV!0 DO
    { LET ba = bitsV!a
      FOR b = a+1 TO bitsV!0 IF (ba & bitsV!b)=0 DO
      { LET bb = ba + bitsV!b
        FOR c = b+1 TO bitsV!0 IF (bb & bitsV!c)=0 DO
        { LET bc = bb + bitsV!c
          FOR d = c+1 TO bitsV!0 IF (bc & bitsV!d)=0 DO
          { p := p+1
            bitsV4!p, compV4!p := bc + bitsV!d, mkinitvec(4, a, b, c, d)
//writef("bitsV4!%i3 = %x5  a=%i2 a=%i2 a=%i2 a=%i2*n", p, bitsV4!p, a, b, c, d)
//writef("bitsV!%i2 = %x5*n", a, bitsV!a)
//writef("bitsV!%i2 = %x5*n", b, bitsV!b)
//writef("bitsV!%i2 = %x5*n", c, bitsV!c)
//writef("bitsV!%i2 = %x5*n", d, bitsV!d)
//abort(1000)
          }
        }
      }
    }
    bitsV4!0 := p
    writef("upb of bitsV4 = %i5*n", p)
    sort(bitsV4, compV4, compare)
IF FALSE DO
FOR i = 1 TO p DO
{ LET comp = compV4!i
  LET a, b, c, d = comp!1, comp!2, comp!3, comp!4
  writef("bitsV4!%i3 = %x5  a=%i2 a=%i2 a=%i2 a=%i2*n", i, bitsV4!i, a, b, c, d)
  writef("bitsV!%i2 = %x5*n", a, bitsV!a)
  writef("bitsV!%i2 = %x5*n", b, bitsV!b)
  writef("bitsV!%i2 = %x5*n", c, bitsV!c)
  writef("bitsV!%i2 = %x5*n", d, bitsV!d)
  abort(1000)
}

  }

  // Form the V4 successors
writef("*nFinding V4 successors*n")

//IF FALSE DO
  FOR p = 1 TO bitsV4!0 DO
  { LET bits = bitsV4!p
    AND comp = compV4!p
    AND s, n = spacep, 0
    succsV4!p := s
//writef("p=%i3 %x5  comp=%x8*n", p, bitsV4!p, comp)
//abort(1000)
    FOR i = 1 TO 4 DO
    { LET q = comp!i // find a component placement
      IF q DO
      { LET bits0 = bits - bitsV!q
        LET succs = succsV!q          // Vector of successors
//writef("q=%i2 bits0=%x5  succs!0=%n*n", q, bits0, succs!0)
//abort(1000)
        FOR i = 1 TO succs!0 IF (bits0 & bitsV!(succs!i))=0 DO
        { n := n+1
          s!n := find(bitsV4, bits0 + bitsV!(succs!i))
IF FALSE DO
{ LET comp1 = compV4!(s!n)
LET a, b, c, d = comp!1, comp!2, comp!3, comp!4
newline()
writef("bitsV4!%i3 = %x5  a=%i2 b=%i2 c=%i2 d=%i2*n", p, bitsV4!p, a, b, c, d)
writef("bitsV!%i2 = %x5*n", a, bitsV!a)
writef("bitsV!%i2 = %x5*n", b, bitsV!b)
writef("bitsV!%i2 = %x5*n", c, bitsV!c)
writef("bitsV!%i2 = %x5*n", d, bitsV!d)
a, b, c, d := comp1!1, comp1!2, comp1!3, comp1!4
writef("*nSuccessor:*n")
writef("bitsV4!%i3 = %x5  a=%i2 b=%i2 c=%i2 d=%i2*n", s!n, bitsV4!(s!n), a, b, c, d)
writef("bitsV!%i2 = %x5*n", a, bitsV!a)
writef("bitsV!%i2 = %x5*n", b, bitsV!b)
writef("bitsV!%i2 = %x5*n", c, bitsV!c)
writef("bitsV!%i2 = %x5*n", d, bitsV!d)
abort(1000)
}

        }
      }
    }
    s!0 := n
    spacep := spacep + n + 1
  }


  bitsU4  := mkvec(bitsU4upb)
  succsU4 := mkvec(bitsU4upb)
  compU4  := mkvec(bitsU4upb)

  // Form the U4 bit patterns
writef("*nFinding U4 bit patterns*n")
  { LET p = 0
    FOR a = 1 TO bitsU!0 DO
    { LET ba = bitsU!a
      FOR b = a+1 TO bitsU!0 IF (ba & bitsU!b)=0 DO
      { LET bb = ba + bitsU!b
        FOR c = b+1 TO bitsU!0 IF (bb & bitsU!c)=0 DO
        { LET bc = bb + bitsU!c
          FOR d = c+1 TO bitsU!0 IF (bc & bitsU!d)=0 DO
          { p := p+1
            bitsU4!p, compU4!p := bc + bitsU!d, mkinitvec(4, a, b, c, d)
//writef("bitsU4!%i3 = %x5  a=%i2 a=%i2 a=%i2 a=%i2*n", p, bitsU4!p, a, b, c, d)
//writef("bitsU!%i2 = %x5*n", a, bitsU!a)
//writef("bitsU!%i2 = %x5*n", b, bitsU!b)
//writef("bitsU!%i2 = %x5*n", c, bitsU!c)
//writef("bitsU!%i2 = %x5*n", d, bitsU!d)
//abort(1000)
          }
        }
      }
    }
    bitsU4!0 := p
    writef("upb of bitsU4 = %i5*n", p)
    sort(bitsU4, compU4, compare)
IF FALSE DO
FOR i = 1 TO p DO
{ LET comp = compU4!i
  LET a, b, c, d = comp!1, comp!2, comp!3, comp!4
  writef("bitsU4!%i3 = %x5  a=%i2 a=%i2 a=%i2 a=%i2*n", i, bitsU4!i, a, b, c, d)
  writef("bitsU!%i2 = %x5*n", a, bitsU!a)
  writef("bitsU!%i2 = %x5*n", b, bitsU!b)
  writef("bitsU!%i2 = %x5*n", c, bitsU!c)
  writef("bitsU!%i2 = %x5*n", d, bitsU!d)
  abort(1000)
}
  }

  // Form the U4 successors
writef("*nFinding U4 successors*n")

//IF FALSE DO
  FOR p = 1 TO bitsU4!0 DO
  { LET bits = bitsU4!p
    AND comp = compU4!p
    AND s, n = spacep, 0
    succsU4!p := s
//writef("p=%i3 %x5  comp=%x8*n", p, bitsU4!p, comp)
//abort(1000)
    FOR i = 1 TO 4 DO
    { LET q = comp!i // find a component placement
      IF q DO
      { LET bits0 = bits - bitsU!q
        LET succs = succsU!q          // Vector of successors
//writef("q=%i2 bits0=%x5  succs!0=%n*n", q, bits0, succs!0)
//abort(1000)
        FOR i = 1 TO succs!0 IF (bits0 & bitsU!(succs!i))=0 DO
        { n := n+1
          s!n := find(bitsU4, bits0 + bitsU!(succs!i))
/*
{ LET comp1 = compU4!(s!n)
LET a, b, c, d = comp!1, comp!2, comp!3, comp!4
newline()
writef("bitsU4!%i3 = %x5  a=%i2 b=%i2 c=%i2 d=%i2*n", p, bitsU4!p, a, b, c, d)
writef("bitsU!%i2 = %x5*n", a, bitsU!a)
writef("bitsU!%i2 = %x5*n", b, bitsU!b)
writef("bitsU!%i2 = %x5*n", c, bitsU!c)
writef("bitsU!%i2 = %x5*n", d, bitsU!d)
a, b, c, d := comp1!1, comp1!2, comp1!3, comp1!4
writef("*nSuccessor:*n")
writef("bitsU4!%i3 = %x5  a=%i2 b=%i2 c=%i2 d=%i2*n", s!n, bitsU4!(s!n), a, b, c, d)
writef("bitsU!%i2 = %x5*n", a, bitsU!a)
writef("bitsU!%i2 = %x5*n", b, bitsU!b)
writef("bitsU!%i2 = %x5*n", c, bitsU!c)
writef("bitsU!%i2 = %x5*n", d, bitsU!d)
abort(1000)
}
*/

        }
      }
    }
    s!0 := n
    spacep := spacep + n + 1
  }

  bitsB  := mkvec(bitsBupb)
  succsB := mkvec(bitsBupb)
  compB  := mkvec(bitsBupb)
  dist   := mkvec(bitsBupb)
  id     := mkvec(bitsBupb)
  prev   := mkvec(bitsBupb)
  solv   := mkvec(bitsBupb)

  // Form the board bit patterns
writef("*nFinding board bit patterns*n")
  { LET p = 0
    FOR s = 1 TO bitsS!0 DO
    { LET bs = bitsS!s
      FOR h = 1 TO bitsH!0 IF (bs & bitsH!h)=0 DO
      { LET bh = bs + bitsH!h
        FOR v4 = 1 TO bitsV4!0 IF (bh & bitsV4!v4)=0 DO
        { LET bv4 = bh + bitsV4!v4
          FOR u4 = 1 TO bitsU4!0 IF (bv4 & bitsU4!u4)=0 DO
          { p := p+1
            bitsB!p, compB!p := bv4 + bitsU4!u4, mkinitvec(4, s, h, v4, u4)
//writef("bitsB! %i4 = %x5  s=%i2 h=%i2 v4=%i3 u4=%i4*n", p, bitsB!p, s, h, v4, u4)
//writef("bitsS! %i4 = %x5*n", s, bitsS!s)
//writef("bitsH! %i4 = %x5*n", h, bitsH!h)
//writef("bitsV4!%i4 = %x5*n", v4, bitsV4!v4)
//writef("bitsU4!%i4 = %x5*n", u4, bitsU4!u4)
//abort(1000)
          }
        }
      }
    }
    bitsB!0 := p
    writef("upb of bitsB  = %i5*n", p)
    sort(bitsB, compB, compareB)
IF FALSE DO
FOR i = 1 TO p DO
{ LET comp = compB!i
  LET s, h, v4, u4 = comp!1, comp!2, comp!3, comp!4
  writef("bitsB! %i4 = %x5  s=%i2 h=%i2 v4=%i2 u4=%i2*n", i, bitsB!i, s, h, v4, u4)
  writef("bitsS! %i4 = %x5*n", s,  bitsS!s)
  writef("bitsH! %i4 = %x5*n", h,  bitsH!h)
  writef("bitsV4!%i4 = %x5*n", v4, bitsV4!v4)
  writef("bitsU4!%i4 = %x5*n", u4, bitsU4!u4)
  abort(1000)
}
  }

  // Form the board successors
writef("*nFinding board successors*n")
  count := 0
//IF FALSE DO
  FOR p = 1 TO bitsB!0 DO
  { LET bits, bits0 = bitsB!p, ?
    AND q, succs = ?, ?
    AND comp = compB!p    // comp!1,..,comp!4 identify
                          // the S, H, V4 and U4 placements
    AND spl, hpl, vpl, upl = comp!1, comp!2, comp!3, comp!4
    AND s, n = spacep, 0
    succsB!p := s         // s will contain the successors
//IF p REM 100 = 0 DO writef("p = %i5/%n*n", p, bitsB!0)
//writef("p=%i3 %x5  comp=%x8*n", p, bitsB!p, comp)
//abort(1000)

    // Find successors involving S moves
    q := comp!1 // Get the S placement
    bits0 := bits - bitsS!q
    succs := succsS!q          // Vector of S successors
//writef("q=%i2 bits0=%x5  succs!0=%n*n", q, bits0, succs!0)
//abort(1000)
    FOR i = 1 TO succs!0 DO
    { LET newspl = succs!i
      UNLESS (bits0 & bitsS!(succs!i))=0 LOOP
//writef("successor found, i=%n*n", i)
      n := n+1
      s!n := findB(newspl, hpl, vpl, upl)
      count := count + 1
IF FALSE DO
{ LET q = s!n
  LET comp1 = compB!q
LET a, b, c, d = comp!1, comp!2, comp!3, comp!4
newline()
writef("bitsB! %i5 = %x5  a=%i2 b=%i2 c=%i2 d=%i2*n", p, bitsB!p, a, b, c, d)
writef("bitsS! %i5 = %x5*n", a, bitsS!a)
writef("bitsH! %i5 = %x5*n", b, bitsH!b)
writef("bitsV4!%i5 = %x5*n", c, bitsV4!c)
writef("bitsU4!%i5 = %x5*n", d, bitsU4!d)
a, b, c, d := comp1!1, comp1!2, comp1!3, comp1!4
writef("*S  Successor count=%n:*n", count)
writef("bitsB! %i5 = %x5  a=%i2 b=%i2 c=%i2 d=%i2*n", q, bitsB!q, a, b, c, d)
writef("bitsS! %i5 = %x5*n", a, bitsS!a)
writef("bitsH! %i5 = %x5*n", b, bitsH!b)
writef("bitsV4!%i5 = %x5*n", c, bitsV4!c)
writef("bitsU4!%i5 = %x5*n", d, bitsU4!d)
abort(1000)
}

    }



    // Find successors involving H moves
    q := comp!2 // Get the H placement
    bits0 := bits - bitsH!q
    succs := succsH!q          // Vector of H successors
//writef("q=%i2 bits0=%x5  succs!0=%n*n", q, bits0, succs!0)
//abort(1000)
    FOR i = 1 TO succs!0 DO
    { LET newhpl = succs!i
      UNLESS (bits0 & bitsH!(succs!i))=0 LOOP
//writef("successor found, i=%n*n", i)
      n := n+1
      s!n := findB(spl, newhpl, vpl, upl)
      count := count + 1
IF FALSE DO
{ LET q = s!n
  LET comp1 = compB!q
LET a, b, c, d = comp!1, comp!2, comp!3, comp!4
newline()
writef("bitsB! %i5 = %x5  a=%i2 b=%i2 c=%i2 d=%i2*n", p, bitsB!p, a, b, c, d)
writef("bitsS! %i5 = %x5*n", a, bitsS!a)
writef("bitsH! %i5 = %x5*n", b, bitsH!b)
writef("bitsV4!%i5 = %x5*n", c, bitsV4!c)
writef("bitsU4!%i5 = %x5*n", d, bitsU4!d)
a, b, c, d := comp1!1, comp1!2, comp1!3, comp1!4
writef("*nH  Successor count=%n:*n", count)
writef("bitsB! %i5 = %x5  a=%i2 b=%i2 c=%i2 d=%i2*n", q, bitsB!q, a, b, c, d)
writef("bitsS! %i5 = %x5*n", a, bitsS!a)
writef("bitsH! %i5 = %x5*n", b, bitsH!b)
writef("bitsV4!%i5 = %x5*n", c, bitsV4!c)
writef("bitsU4!%i5 = %x5*n", d, bitsU4!d)
abort(1111)
}

    }



    // Find successors involving V4 moves
    q := comp!3 // Get the V4 placement
    bits0 := bits - bitsV4!q
    succs := succsV4!q          // Vector of V4 successors
//writef("q=%i2 bits0=%x5  succs!0=%n*n", q, bits0, succs!0)
//abort(1000)
    FOR i = 1 TO succs!0 DO
    { LET newvpl = succs!i
      UNLESS (bits0 & bitsV4!(succs!i))=0 LOOP
//writef("V4 successor found, i=%n*n", i)
      n := n+1
      s!n := findB(spl, hpl, newvpl, upl)
      count := count + 1
IF FALSE DO
{ LET q = s!n
  LET comp1 = compB!q
LET a, b, c, d = comp!1, comp!2, comp!3, comp!4
newline()
writef("bitsB! %i5 = %x5  a=%i2 b=%i2 c=%i2 d=%i2*n", p, bitsB!p, a, b, c, d)
writef("bitsS! %i5 = %x5*n", a, bitsS!a)
writef("bitsH! %i5 = %x5*n", b, bitsH!b)
writef("bitsV4!%i5 = %x5*n", c, bitsV4!c)
writef("bitsU4!%i5 = %x5*n", d, bitsU4!d)
a, b, c, d := comp1!1, comp1!2, comp1!3, comp1!4
writef("*nV4 Successor count=%n:*n", count)
writef("bitsB! %i5 = %x5  a=%i2 b=%i2 c=%i2 d=%i2*n", q, bitsB!q, a, b, c, d)
writef("bitsS! %i5 = %x5*n", a, bitsS!a)
writef("bitsH! %i5 = %x5*n", b, bitsH!b)
writef("bitsV4!%i5 = %x5*n", c, bitsV4!c)
writef("bitsU4!%i5 = %x5*n", d, bitsU4!d)
abort(1000)
}

    }



    // Find successors involving U4 moves
    q := comp!4 // Get the U4 placement
    bits0 := bits - bitsU4!q
    succs := succsU4!q          // Vector of U4 successors
//writef("q=%i2 bits0=%x5  succs!0=%n*n", q, bits0, succs!0)
//abort(1000)
    FOR i = 1 TO succs!0 DO
    { LET newupl = succs!i
      UNLESS (bits0 & bitsU4!(succs!i))=0 LOOP
//writef("U4 successor found, i=%n*n", i)
      n := n+1
      s!n := findB(spl, hpl, vpl, newupl)
      count := count + 1
IF FALSE DO
{ LET q = s!n
  LET comp1 = compB!q
LET a, b, c, d = comp!1, comp!2, comp!3, comp!4
newline()
writef("bitsB! %i5 = %x5  a=%i2 b=%i2 c=%i2 d=%i2*n", p, bitsB!p, a, b, c, d)
writef("bitsS! %i5 = %x5*n", a, bitsS!a)
writef("bitsH! %i5 = %x5*n", b, bitsH!b)
writef("bitsV4!%i5 = %x5*n", c, bitsV4!c)
writef("bitsU4!%i5 = %x5*n", d, bitsU4!d)
a, b, c, d := comp1!1, comp1!2, comp1!3, comp1!4
writef("*nU4 Successor count=%n:*n", count)
writef("bitsB! %i5 = %x5  a=%i2 b=%i2 c=%i2 d=%i2*n", q, bitsB!q, a, b, c, d)
writef("bitsS! %i5 = %x5*n", a, bitsS!a)
writef("bitsH! %i5 = %x5*n", b, bitsH!b)
writef("bitsV4!%i5 = %x5*n", c, bitsV4!c)
writef("bitsU4!%i5 = %x5*n", d, bitsU4!d)
abort(1000)
}
    }
    s!0 := n
    spacep := spacep + n + 1
//IF count REM 1000 = 0 DO writef("count = %i6*n", count)
//abort(1000)
  }
writef("Total edge count = %n*n", count)

writef("Total space used = %n*n", spacep-spacev)
}

AND compare(kp, dp, kq, dq) = kp<kq -> -1,
                              kp>kq ->  1,
                              0

AND compareB1(kp, dp, kq, dq) = VALOF
{ LET res = compareB(kp, dp, kq, dq)
  LET s, h, v4, u4 = dp!1, dp!2, dp!3, dp!4

  writef("*ncomparing:*n")
  writef("bitsS! %i4 = %x5*n", s,  bitsS!s)
  writef("bitsH! %i4 = %x5*n", h,  bitsH!h)
  writef("bitsV4!%i4 = %x5*n", v4, bitsV4!v4)
  writef("bitsU4!%i4 = %x5*n", u4, bitsU4!u4)
  s, h, v4, u4 := dq!1, dq!2, dq!3, dq!4
  writef("with:*n")
  writef("bitsS! %i4 = %x5*n", s,  bitsS!s)
  writef("bitsH! %i4 = %x5*n", h,  bitsH!h)
  writef("bitsV4!%i4 = %x5*n", v4, bitsV4!v4)
  writef("bitsU4!%i4 = %x5*n", u4, bitsU4!u4)
  writef("=> %n*n", res)
  abort(1000)
  RESULTIS res
}

AND compareB(kp, dp, kq, dq) = VALOF
{ LET bitsp, bitsq = ?, ?
  bitsp, bitsq := bitsS!(dp!1), bitsS!(dq!1) // S
  IF bitsp<bitsq RESULTIS -1
  IF bitsp>bitsq RESULTIS  1
  bitsp, bitsq := bitsH!(dp!2), bitsH!(dq!2) // H
  IF bitsp<bitsq RESULTIS -1
  IF bitsp>bitsq RESULTIS  1
  bitsp, bitsq := bitsV4!(dp!3), bitsV4!(dq!3) // V4
  IF bitsp<bitsq RESULTIS -1
  IF bitsp>bitsq RESULTIS  1
  bitsp, bitsq := bitsU4!(dp!4), bitsU4!(dq!4) // U4
  IF bitsp<bitsq RESULTIS -1
  IF bitsp>bitsq RESULTIS  1
  RESULTIS 0
}

AND sort(keyv, datav, cmpfn) BE
{ LET upb = keyv!0
  LET m = 1
  UNTIL m>upb DO m := m*3 + 1  // Find first suitable value in the
                               // series:  1, 4, 13, 40, 121, 364, ...
  { m := m/3
//IF keyv=bitsB DO writef("m=%n*n", m)
    FOR i = m+1 TO upb DO
    { LET key, data = keyv!i, datav!i
      LET j = i
      { LET k = j - m
//IF m<=4 & k>0 & keyv=bitsB DO
//        { writef("m=%n k=%i5  i=%i5*n", m, k, i)
//          compareB1(keyv!k, datav!k, key, data)
//        }
        IF k<=0 | cmpfn(keyv!k, datav!k, key, data)>0 BREAK
        keyv!j  := keyv!k
        datav!j := datav!k
        j := k
      } REPEAT
      keyv!j  := key
      datav!j := data
   }
 } REPEATUNTIL m=1
}


AND find(v, x) = VALOF
{ LET p, q = 1, v!0  // v!1 ... v!n sorted in decreasing order
  WHILE p<=q DO
  { LET t = (p+q)/2
//writef("find: %x5 trying %x5 at %n*n", x, v!t, t)
    IF v!t>x DO { p := t+1; LOOP }
    IF v!t<x DO { q := t-1; LOOP }
//writef("find: %x5 found at %n*n", x, t)
//abort(1000)
    RESULTIS t
  }
  writef("find: %x5 failure*n", x)
  abort(999)
  RESULTIS 0
}

AND findB(s, h, v4, u4) = VALOF
{ LET p, q = 1, bitsB!0
  LET sbits, hbits, v4bits, u4bits = bitsS!s, bitsH!h, bitsV4!v4, bitsU4!u4
  WHILE p<=q DO
  { LET t = (p+q)/2
    LET cv = compB!t
    LET bits = ?
//writef("find: %x5 %x5 %x5 %x5 trying at %n*n", sbits, hbits, v4bits, u4bits, t)
    bits := bitsS!(cv!1)
    IF bits>sbits DO { p := t+1; LOOP }
    IF bits<sbits DO { q := t-1; LOOP }
    bits := bitsH!(cv!2)
    IF bits>hbits DO { p := t+1; LOOP }
    IF bits<hbits DO { q := t-1; LOOP }
    bits := bitsV4!(cv!3)
    IF bits>v4bits DO { p := t+1; LOOP }
    IF bits<v4bits DO { q := t-1; LOOP }
    bits := bitsU4!(cv!4)
    IF bits>u4bits DO { p := t+1; LOOP }
    IF bits<u4bits DO { q := t-1; LOOP }
//writef("find: found at %n*n", t)
//abort(1000)
    RESULTIS t
  }
  writef("find: failure*n")
  abort(999)
  RESULTIS 0
}

AND pr(n, s, h, v4, u4) BE
{ FOR sh = 19 TO 0 BY -1 DO
  { LET bit = 1<<sh
    LET ch = '**'
    UNLESS (s &bit) = 0 DO ch := 'S'
    UNLESS (h &bit) = 0 DO ch := 'H'
    UNLESS (v4&bit) = 0 DO ch := 'V'
    UNLESS (u4&bit) = 0 DO ch := 'U'
    writef(" %c", ch)

    IF sh REM 4 = 0 TEST sh=16 THEN writef("   %i3*n", n)
                               ELSE newline()
  }
  newline()
}

AND prsol(pos) BE
{ LET comp = compB!pos
  LET sbits  = bitsS!(comp!1)
  LET hbits  = bitsH!(comp!2)
  LET v4bits = bitsV4!(comp!3)
  LET u4bits = bitsU4!(comp!4)
  writef("%i5: %i3 %i5  ", id!pos, dist!pos, id!(prev!pos))
  FOR sh = 19 TO 0 BY -1 DO
  { LET bit = 1<<sh
    LET ch = '**'
    UNLESS (sbits &bit) = 0 DO ch := 'S'
    UNLESS (hbits &bit) = 0 DO ch := 'H'
    UNLESS (v4bits&bit) = 0 DO ch := 'V'
    UNLESS (u4bits&bit) = 0 DO ch := 'U'
    writef(" %c", ch)

    IF sh REM 4 = 0 DO wrch(' ')
  }
  IF sbits=#x00066 DO writes("  solution")
  newline()
//abort(1000)
}

AND search() BE
{ LET pos = findB(find(bitsS,  #x66000),
                  find(bitsH,  #x00006),
                  find(bitsV4, #x09999),
                  find(bitsU4, #x00660)
                  )
  LET p, q, v, d = 1, 1, ?, 0
  FOR i = 0 TO bitsBupb DO dist!i, id!i := -1, 0

  solv!q := pos     // Initialise the solution stack
  id!pos := q
  prev!pos := 0
  dist!pos := 0

  IF tracing DO prsol(pos)
//  abort(8888)

  WHILE p<=q DO
  { pos := solv!p
    p := p+1
    v := succsB!pos
    d := dist!pos+1
    FOR i = 1 TO v!0 DO
    { LET newpos = v!i
      IF dist!newpos<0 DO
      { prev!newpos := pos
        dist!newpos := d
        q := q+1
        solv!q := newpos
        id!newpos := q
        IF tracing DO prsol(newpos)
        IF solution & bitsS!(compB!newpos!1)=#x00066 DO
        { writef("*nsolution found*n")
          prsolution(newpos)
          RETURN
        }
      }
    }
  }
}

AND prsolution(pos) BE
{ IF prev!pos DO prsolution(prev!pos)
  prsol(pos)
}

/*
The first solution found by this program is:

    1:   0     0   * S S *  V S S V  V U U V  V U U V  V H H V 
    2:   1     1   V S S *  V S S V  * U U V  V U U V  V H H V 
    4:   2     2   V S S V  V S S V  * U U *  V U U V  V H H V 
    9:   3     4   V S S V  V S S V  V U U *  V U U V  * H H V 
   19:   4     9   V S S V  V S S V  V U U *  V U U V  H H * V 
   34:   5    19   V S S V  V S S V  V U * U  V U U V  H H * V 
   53:   6    34   V S S V  V S S V  V * U U  V U U V  H H * V 
   75:   7    53   V S S V  V S S V  V * U U  V U * V  H H U V 
   94:   8    75   V S S V  V S S V  V * U U  V * U V  H H U V 
  111:   9    94   V S S V  V S S V  * V U U  * V U V  H H U V 
  134:  10   111   * S S V  V S S V  V V U U  * V U V  H H U V 
  163:  11   134   * S S V  * S S V  V V U U  V V U V  H H U V 
  199:  12   163   S S * V  S S * V  V V U U  V V U V  H H U V 
  234:  13   199   S S * V  S S U V  V V * U  V V U V  H H U V 
  276:  14   234   S S U V  S S * V  V V * U  V V U V  H H U V 
  343:  15   276   S S U V  S S * V  V V U *  V V U V  H H U V 
  424:  16   343   S S U V  S S * V  V V U V  V V U V  H H U * 
  519:  17   424   S S U V  S S U V  V V * V  V V U V  H H U * 
  646:  18   519   S S U V  S S U V  V V U V  V V * V  H H U * 
  806:  19   646   S S U V  S S U V  V V U V  V V U V  H H * * 
  989:  20   806   S S U V  S S U V  V V U V  V V U V  * H H * 
 1196:  21   989   S S U V  S S U V  V V U V  V V U V  * * H H 
 1448:  22  1196   S S U V  S S U V  * V U V  V V U V  V * H H 
 1746:  23  1448   S S U V  S S U V  * * U V  V V U V  V V H H 
 2078:  24  1746   * * U V  S S U V  S S U V  V V U V  V V H H 
 2430:  25  2078   * U * V  S S U V  S S U V  V V U V  V V H H 
 2816:  26  2430   U * * V  S S U V  S S U V  V V U V  V V H H 
 3251:  27  2816   U * U V  S S * V  S S U V  V V U V  V V H H 
 3722:  28  3251   U U * V  S S * V  S S U V  V V U V  V V H H 
 4256:  29  3722   U U * V  S S U V  S S * V  V V U V  V V H H 
 4859:  30  4256   U U U V  S S * V  S S * V  V V U V  V V H H 
 5494:  31  4859   U U U V  * S S V  * S S V  V V U V  V V H H 
 6128:  32  5494   U U U V  * S S V  V S S V  V V U V  * V H H 
 6737:  33  6128   U U U V  V S S V  V S S V  * V U V  * V H H 
 7322:  34  6737   U U U V  V S S V  V S S V  V * U V  V * H H 
 7865:  35  7322   U U U V  V S S V  V S S V  V U * V  V * H H 
 8362:  36  7865   U U U V  V S S V  V S S V  V * * V  V U H H 
 8824:  37  8362   U U U V  V * * V  V S S V  V S S V  V U H H 
 9292:  38  8824   U * U V  V U * V  V S S V  V S S V  V U H H 
 9761:  39  9292   U U * V  V U * V  V S S V  V S S V  V U H H 
10202:  40  9761   U U V *  V U V *  V S S V  V S S V  V U H H 
10619:  41 10202   U U V *  V U V V  V S S V  V S S *  V U H H 
11025:  42 10619   U U V V  V U V V  V S S *  V S S *  V U H H 
11401:  43 11025   U U V V  V U V V  V * S S  V * S S  V U H H 
11720:  44 11401   U U V V  V * V V  V U S S  V * S S  V U H H 
11999:  45 11720   U * V V  V U V V  V U S S  V * S S  V U H H 
12288:  46 11999   * U V V  V U V V  V U S S  V * S S  V U H H 
12614:  47 12288   V U V V  V U V V  * U S S  V * S S  V U H H 
12942:  48 12614   V U V V  V U V V  V U S S  V * S S  * U H H 
13252:  49 12942   V U V V  V U V V  V * S S  V U S S  * U H H 
13521:  50 13252   V U V V  V U V V  V * S S  V U S S  U * H H 
13763:  51 13521   V U V V  V U V V  V * S S  V * S S  U U H H 
13996:  52 13763   V U V V  V U V V  V S S *  V S S *  U U H H 
14232:  53 13996   V U V *  V U V V  V S S V  V S S *  U U H H 
14478:  54 14232   V U V *  V U V *  V S S V  V S S V  U U H H 
14732:  55 14478   V U * V  V U * V  V S S V  V S S V  U U H H 
14983:  56 14732   V * U V  V U * V  V S S V  V S S V  U U H H 
15236:  57 14983   V * U V  V * U V  V S S V  V S S V  U U H H 
15501:  58 15236   * V U V  * V U V  V S S V  V S S V  U U H H 
15766:  59 15501   * V U V  V V U V  V S S V  * S S V  U U H H 
16057:  60 15766   V V U V  V V U V  * S S V  * S S V  U U H H 
16365:  61 16057   V V U V  V V U V  S S * V  S S * V  U U H H 
16723:  62 16365   V V U V  V V U V  S S V *  S S V *  U U H H 
17104:  63 16723   V V U *  V V U V  S S V V  S S V *  U U H H 
17497:  64 17104   V V * U  V V U V  S S V V  S S V *  U U H H 
17913:  65 17497   V V U U  V V * V  S S V V  S S V *  U U H H 
18343:  66 17913   V V U U  V V V V  S S V V  S S * *  U U H H 
18789:  67 18343   V V U U  V V V V  S S V V  S S H H  U U * * 
19216:  68 18789   V V U U  V V V V  S S V V  S S H H  U * U * 
19601:  69 19216   V V U U  V V V V  S S V V  S S H H  * U U * 
19964:  70 19601   V V U U  V V V V  S S V V  S S H H  * U * U 
20323:  71 19964   V V U U  V V V V  S S V V  S S H H  * * U U 
20683:  72 20323   V V U U  V V V V  * * V V  S S H H  S S U U 
21047:  73 20683   * V U U  V V V V  V * V V  S S H H  S S U U 
21435:  74 21047   * * U U  V V V V  V V V V  S S H H  S S U U 
21824:  75 21435   * U * U  V V V V  V V V V  S S H H  S S U U 
22209:  76 21824   U * * U  V V V V  V V V V  S S H H  S S U U 
22544:  77 22209   U * U *  V V V V  V V V V  S S H H  S S U U 
22816:  78 22544   U * U V  V V V V  V V V *  S S H H  S S U U 
23054:  79 22816   U U * V  V V V V  V V V *  S S H H  S S U U 
23253:  80 23054   U U V V  V V V V  V V * *  S S H H  S S U U 
23450:  81 23253   U U V V  V V V V  V V H H  S S * *  S S U U 
23601:  82 23450   U U V V  V V V V  V V H H  S S U *  S S * U 
23731:  83 23601   U U V V  V V V V  V V H H  S S * U  S S * U 
23853:  84 23731   U U V V  V V V V  V V H H  * S S U  * S S U   solution
*/


