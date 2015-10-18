/*

This program explores the structure of a sliding blocks puzzle,
finding a minimum cost solution as a bye product.

Re-implemented in BCPL by Martin Richards  (c) December 2014

The puzzle is played on a 4x5 board on which 10 blocks can slide.
There are four unit 1x1 blocks (U), four 1x2 blocks (V) oriented
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
centrally at the bottom. This takes a minimum of 84 moves, where a
move is defined to be moving one block one position up, down, left or
right by one place. The program also tell us there are 65880 different
placements of the tem pieces on the board of which only 25955 are
reachable from the initial position.  The puzzle has a graph with each
board position represented by a node each node having a list of other
nodes reachable by a single move. These connections between nodes are
called edges. The graph is said to be undirected since every move is
reversible.  The cluster of nodes reachable from a given node is
called, by mathematicians, a simply connected component. The sliding
block puzzle has 12 such cluster the largest and smallest having 0000
and 0000 nodes. As we have seen, the cluster including the starting
position has 25955 nodes.

Implementation

The board is represented by a bit pattern with each bit indicating the
occupancy of each of the 20 squares on the board.

The vector bitsS holds bit patterns representing the 12 possible
placements of the 2x2 block.

The vector bitsV holds bit patterns representing the 16 possible
placements of a vertically oriented 1x2 block.

The vector bitsH holds bit patterns representing the 15 possible
placements of the horizontally oriented 2x1 block.

The vector bitsU holds bit patterns representing the 20 possible
placements of a 1x1 block.

A particular placement of the 2x2 block can be represented by a
placement number p in the range 1 to 12. The bit pattern representing
which board positions it occupies is bitsS!p. Its immediately adjacent
placements are held in the vector succsS!p. If we call this vector v,
then v!0=n is the number adjacent placements and v!1 ,.., v!n are their
placement numbers.

The vectors succsV, succsH and succsU contain adjacency information
for the 1x2, 2x1 and 1x1 blocks in a form similar to succsS.

*/

GET "libhdr"

MANIFEST {
 // Selectors for a placement node
 s_link=0      // link=0 or link -> another node at the dist value
 s_dist        // dist=-1 or the distance from the starting position
 s_prev        // prev=0 or prev -> predecessor node in the path
               // from the starting position to this node.
 s_chain       // chain=0 or chain -> another node with the same hash value
 s_succs       // List of adjacent placement nodes
               // succs=0 or succs -> [next, node]
 // Piece placement numbers
 s_S
 s_Va; s_Vb; s_Vc; s_Vd
 s_H
 s_Ua; s_Ub; s_Uc; s_Ud

 // Board placement bit patterns
 s_S1
 s_V4
 s_H1
 s_U4
 s_B

 s_upb=s_B  // The upb of a placement node
}

/*

The program creates nodes all 65880 valid board placements and puts
pointers to them in the vector nodev.  The fields S1, V4, H1 and U4
are distinct for all placements. A hash table, hashtab, is used for
efficient looking up of placement nodes given their S1, V4, H1 and U4
settings. The call hashfn(S1,V4,H1,U4) computes the hash value. The
pointer to the next node in a hash chain is held in the chain
field. All the placement nodes are created by the call createnodes().

The program then creates, for each placement node, the list of
immediately adjacent placements. This is done by calls of the form
createsuccs(node).

The program next creates lists of nodes at different distances from
the starting position. This is done by the call createlists(). The
call find(#x66000,#x09999,#x00006,#00660) finds the starting node,
which is given a dist value of zero and becomes the only node in
listv!0. All other nodes initially have dist values of -1, indicating
that their distances are not yet known. listv!i holds the list of
nodes at diatance i from the starting node. For all these nodes the
dist field is set to i. This list is constructed by by the call
createlist(i) which inspects every node in listv!(i-1). If the call
returns zero, there are no nodes at distance i from the starting
position.

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
  mkvec
  mk2

  tracing
  nodev
  nodecount
  edgecount
  listv
  hashtab
  root
  componentcount
  componentsize
  componentp
  visitedcount
  solution

  hashfn
  find
  initpieces
  createnodes
  createsuccs
  mksuccs
  explore
  prboard
  prsol
  
}

MANIFEST {
  Spaceupb  = 2_500_000
  bitsV4upb =       886
  bitsU4upb =      4845
  nodevupb  =     65880
  listvupb  =       200

  hashtabsize =    5000
}

LET start() = VALOF
{ LET argv   = VEC 50
  LET stdout = output()
  LET out    = stdout

  UNLESS rdargs("-o/k,-t/s", argv, 50) DO
  { writef("Bad arguments for blocks*n")
    RESULTIS 20
  }

  IF argv!0 DO                   // -o/k
  { out := findoutput(argv!0)
    UNLESS out DO
    { writef("Unable to open output file %s*n", argv!0)
      RESULTIS 20
    }
    selectoutput(out)
  }

  tracing := argv!1              // -t/s
  solution := 0
  nodecount := 0
  edgecount := 0
  componentcount := 0
  componentsize := 0
  componentp := 0

  spacev := getvec(Spaceupb)
  spacep, spacet := spacev, spacev+Spaceupb

  UNLESS spacev DO
  { writef("Insufficient space available*n")
    RESULTIS 20
  }

  hashtab := mkvec(hashtabsize-1)
  FOR i = 0 TO hashtabsize-1 DO hashtab!i := 0
  nodev   := mkvec(nodevupb)
  listv   := mkvec(listvupb)
  nodecount := 0
  solution := 0
  root := 0
  componentcount := 0
  componentsize := 0
  componentp := 0
  visitedcount := 0

  initpieces()
  createnodes()
  createsuccs()
  explore()

  // Lists of nodes at all distances have now been created
  // so output the solution

  IF solution DO prsol(solution)

  writef("nodecount=%n*n", nodecount)
  writef("edgecount=%n*n", edgecount)
  writef("componentcount=%n*n", componentcount)
  writef("componentsize=%n*n", componentsize)
  writef("space used = %n words*n", spacep-spacev)

fin:
  UNLESS out=stdout DO endwrite()
  freevec(spacev)
  RESULTIS 0
}

AND mkvec(upb) = VALOF
{ LET p = spacep
  spacep := spacep+upb+1
  IF spacep>spacet DO
  { writef("Insufficient space*n")
    abort(999)
    RESULTIS 0
  }
  //writef("mkvec(%n) => %n*n", upb, p)
  RESULTIS p
}

AND mk2(a, b) = VALOF
{ LET p = mkvec(1)
  p!0, p!1 := a, b
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

AND initpieces() BE
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
}


AND addnode(s, va,vb,vc,vd, h, ua,ub,uc,ud) BE
{ // Insert a new placement node in nodev
  LET node = mkvec(s_upb)
  LET S1   = bitsS!s
  LET V4   = bitsV!va + bitsV!vb + bitsV!vc + bitsV!vd
  LET H1   = bitsH!h
  LET U4   = bitsU!ua + bitsU!ub + bitsU!uc + bitsU!ud
  LET hashval = hashfn(S1, V4, H1, U4)
  s_link!node := 0
  s_dist!node := -1
  s_prev!node := 0
  s_chain!node := hashtab!hashval
  hashtab!hashval := node
  s_succs!node := 0

  s_S !node := s
  s_Va!node := va
  s_Vb!node := vb
  s_Vc!node := vc
  s_Vd!node := vd
  s_H !node := h
  s_Ua!node := ua
  s_Ub!node := ub
  s_Uc!node := uc
  s_Ud!node := ud

  s_S1!node := S1
  s_H1!node := H1
  s_V4!node := V4
  s_U4!node := U4

  nodecount := nodecount+1

//writef("addnode: s=%i2 v=%i2 %i2 %i2 %i2 h=%i2 u=%i2 %i2 %i2 %i2*n",
//        s, va,vb,vc,vd, h, ua,ub,uc,ud)
//writef("*n%i6: ", nodecount)
//prboard(S1, V4, H1, U4)
//newline()
//abort(1000)

  IF nodecount > nodevupb DO
  { writef("nodevupb=%n is too small for nodecount=%n*n", nodevupb)
    RETURN
  }

  nodev!nodecount := node
  nodev!0 := nodecount
}

AND hashfn(S1, V4, H, U4) = (S1 XOR V4*5 XOR H*7 XOR U4*11) MOD hashtabsize

AND find(S1, V4, H1, U4) = VALOF
{ LET hashval = hashfn(S1, V4, H1, U4)
  LET node = hashtab!hashval
//writef("find: entered, hashval=%n*n", hashval)
  WHILE node DO
  { IF S1=s_S1!node &
       V4=s_V4!node &
       H1=s_H1!node &
       U4=s_U4!node RESULTIS node
    node := s_chain!node
  }
  writef("find: Failed to find "); prboard(S1,V4,H1,U4)
  newline()
  abort(999)
  RESULTIS 0
}

AND createnodes() BE
{ FOR s = 1 TO bitsS!0 DO
  { LET bits = bitsS!s
//writef("createnodes: s=%n*n", s)
//abort(1111)
    FOR va = 1 TO bitsV!0 - 3 IF (bits & bitsV!va)=0 DO
    { bits := bits + bitsV!va
//writef("createnodes: s=%n va=%n*n", s, va)
//abort(1111)
      FOR vb = va+1 TO bitsV!0 - 2 IF (bits & bitsV!vb)=0 DO
      { bits := bits + bitsV!vb
//writef("createnodes: s=%n va=%n vb=%n*n", s, va, vb)
//abort(1111)
        FOR vc = vb+1 TO bitsV!0 - 1 IF (bits & bitsV!vc)=0 DO
        { bits := bits + bitsV!vc
//writef("createnodes: s=%n va=%n vb=%n vc=%n*n", s, va, vb, vc)
//abort(1111)
          FOR vd = vc+1 TO bitsV!0 IF (bits & bitsV!vd)=0 DO
          { bits := bits + bitsV!vd
//writef("createnodes: s=%n va=%n vb=%n vc=%n*n", s, va, vb, vc, vd)
//abort(1111)
            FOR h = 1 TO bitsH!0 IF (bits & bitsH!h)=0 DO
            { bits := bits + bitsH!h
              FOR ua = 1 TO bitsU!0 - 3 IF (bits & bitsU!ua)=0 DO
              { bits := bits + bitsU!ua
                FOR ub = ua+1 TO bitsU!0 - 2 IF (bits & bitsU!ub)=0 DO
                { bits := bits + bitsU!ub
                  FOR uc = ub+1 TO bitsU!0 - 1 IF (bits & bitsU!uc)=0 DO
                  { bits := bits + bitsU!uc
                    FOR ud = uc+1 TO bitsU!0 IF (bits & bitsU!ud)=0 DO
                    { bits := bits + bitsU!ud
                      addnode(s,va,vb,vc,vd,h,ua,ub,uc,ud)
                      bits := bits - bitsU!ud
                    }
                    bits := bits - bitsU!uc
                  }
                  bits := bits - bitsU!ub
                }
                bits := bits - bitsU!ua
              }
              bits := bits - bitsH!h
            }
            bits := bits - bitsV!vd
          }
          bits := bits - bitsV!vc
        }
        bits := bits - bitsV!vb
      }
      bits := bits - bitsV!va
    }
  }
}

AND createsuccs() BE
{ // Create successor lists
  //writef("createsuccs: entered nodev!0=%n*n", nodev!0)
  FOR i = 1 TO nodev!0 DO mksuccs(nodev!i)
}

AND mksuccs(node) BE
{ LET all = s_S1!node + s_V4!node + s_H1!node + s_U4!node
  //writef("mksuccs: node is  ")
  //prboard(s_S1!node, s_V4!node, s_H1!node, s_U4!node)
  //newline()
  //abort(2000)
  mksuccsS(node, all, s_S !node)
  mksuccsV(node, all, s_Va!node)
  mksuccsV(node, all, s_Vb!node)
  mksuccsV(node, all, s_Vc!node)
  mksuccsV(node, all, s_Vd!node)
  mksuccsH(node, all, s_H !node)
  mksuccsU(node, all, s_Ua!node)
  mksuccsU(node, all, s_Ub!node)
  mksuccsU(node, all, s_Uc!node)
  mksuccsU(node, all, s_Ud!node)
//abort(2003)
}

AND mksuccsS(p, all, q) BE
{ // all is a bit pattern giving all occupied squares
  // q is the current placement number of the 2x2 S piece
  LET succsv = succsS!q  // Vector of successors of placement q
  LET bitsq = bitsS!q    // The bit pattern for placement q
  LET bits = all - bitsq // bits with placement q removed
  FOR i = 1 TO succsv!0 DO
  { LET j = succsv!i     // The placement number of an adjacent placement of the 2x2 S piece
    LET bitsj = bitsS!j  // The bit pattern for placement j
    //writef("mksuccsS: q=%n i=%n j=%n bits=%x5 bitsq=%x5 bitsj=%x5*n",
    //        q, i, j, bits, bitsq, bitsj)
    //abort(2001)
    IF (bits & bitsj) = 0 DO
    { // Found a successor
      LET S1, V4, H1, U4 = bitsj, s_V4!p, s_H1!p, s_U4!p
      LET succ = find(S1,V4,H1,U4)
      s_succs!p := mk2(s_succs!p, succ)
      edgecount := edgecount+1
      //writef("S successor ")
      //prboard(S1,V4,H1,U4)
      //newline()
      //abort(1000)
    }
  }
}

AND mksuccsV(p, all, q) BE
{ // all is a bit pattern giving all occupied squares
  // q is the current placement number of a 1x2 V piece
  LET succsv = succsV!q  // Vector of successors of placement q
  LET bitsq = bitsV!q    // The bit pattern for placement q
  LET bits = all - bitsq // bits with placement q removed
  FOR i = 1 TO succsv!0 DO
  { LET j = succsv!i     // The placement number of an adjacent placement of the 1x2 V piece
    LET bitsj = bitsV!j  // The bit pattern for placement j
    //writef("mksuccsV: q=%n i=%n j=%n bits=%x5 bitsq=%x5 bitsj=%x5*n",
    //        q, i, j, bits, bitsq, bitsj)
    //abort(2001)
    IF (bits & bitsj) = 0 DO
    { // Found a successor
      LET S1, V4, H1, U4 = s_S1!p, s_V4!p-bitsq+bitsj, s_H1!p, s_U4!p
      LET succ = find(S1,V4,H1,U4)
      s_succs!p := mk2(s_succs!p, succ)
      edgecount := edgecount+1
      //writef("V successor ")
      //prboard(S1,V4,H1,U4)
      //newline()
      //abort(1000)
    }
  }
}

AND mksuccsH(p, all, q) BE
{ // all is a bit pattern giving all occupied squares
  // q is the current placement number of the 2x1 H piece
  LET succsv = succsH!q  // Vector of successors of placement q
  LET bitsq = bitsH!q    // The bit pattern for placement q
  LET bits = all - bitsq // bits with placement q removed
  FOR i = 1 TO succsv!0 DO
  { LET j = succsv!i     // The placement number of an adjacent placement of the 2x1 H piece
    LET bitsj = bitsH!j  // The bit pattern for placement j
    //writef("mksuccsH: q=%n i=%n j=%n bits=%x5 bitsq=%x5 bitsj=%x5*n",
    //        q, i, j, bits, bitsq, bitsj)
    //abort(2001)
    IF (bits & bitsj) = 0 DO
    { // Found a successor
      LET S1, V4, H1, U4 = s_S1!p, s_V4!p, bitsj, s_U4!p
      LET succ = find(S1,V4,H1,U4)
      s_succs!p := mk2(s_succs!p, succ)
      edgecount := edgecount+1
      //writef("H successor ")
      //prboard(S1,V4,H1,U4)
      //newline()
      //abort(1000)
    }
  }
}

AND mksuccsU(p, all, q) BE
{ // all is a bit pattern giving all occupied squares
  // q is the current placement number of a 1x1 U piece
  LET succsv = succsU!q  // Vector of successors of placement q
  LET bitsq = bitsU!q    // The bit pattern for placement q
  LET bits = all - bitsq // bits with placement q removed
  FOR i = 1 TO succsv!0 DO
  { LET j = succsv!i     // The placement number of an adjacent placement of a 1x1 U piece
    LET bitsj = bitsU!j  // The bit pattern for placement j
    //writef("mksuccsU: q=%n i=%n j=%n bits=%x5 bitsq=%x5 bitsj=%x5*n",
    //        q, i, j, bits, bitsq, bitsj)
    //abort(2001)
    IF (bits & bitsj) = 0 DO
    { // Found a successor
      LET S1, V4, H1, U4 = s_S1!p, s_V4!p, s_H1!p, s_U4!p-bitsq+bitsj
      LET succ = find(S1,V4,H1,U4)
      s_succs!p := mk2(s_succs!p, succ)
      edgecount := edgecount+1
      //writef("U successor ")
      //prboard(S1,V4,H1,U4)
      //newline()
      //abort(1000)
    }
  }
}

AND explore() BE
{ componentp := 1

  root := find(#x66000, #x09999, #x00006, #x00660)

  WHILE root DO
  { // Insert the root of the next component
    LET dist = 0
    s_link!root, s_dist!root := 0, dist
    listv!dist := root
    componentcount := componentcount + 1
    componentsize := 1

writef("explore: root  ")
prboard(s_S1!root, s_V4!root, s_H!root, s_U4!root)
newline()
 
    { LET p = listv!dist
      UNLESS p BREAK
      dist := dist + 1
      writef("explore: making list of nodes at distance %n*n", dist)
//abort(1006)

      // Create list of nodes at the new distance
      listv!dist := 0
      WHILE p DO
      { LET q = s_succs!p // List of nodes adjacent to p
writef("exploring successors of  ")
prboard(s_S1!p, s_V4!p, s_H!p, s_U4!p)
newline()
 
        WHILE q DO
        { LET r = q!1
writef("considering successor  ")
prboard(s_S1!r, s_V4!r, s_H!r, s_U4!r)
newline()
          IF s_dist!r<0 DO
          { // Node r has not yet been reached
writef("Adding it to list*n")
abort(3001)
            s_dist!r := dist
            s_prev!r := p
            listv!dist := mk2(listv!dist, r)
            componentsize := componentsize + 1
            UNLESS solution IF s_S1!r=#x00066 DO solution := r
            writef("dist=%i4  ", dist)
            prboard(s_S1!r, s_V4!r, s_H1!r, s_U4!r)
            newline()
            abort(3000)
          }
          q := !q
        }
        p := !p
      }
    } REPEAT

    // The component is now complete
    writef("Component %i3 size %i5 root ", componentcount, componentsize)
    prboard(s_S1!root, s_V4!root, s_H1!root, s_U4!root)
    newline()
    abort(1007)

    // Find the root of the next component
    root := 0
    WHILE componentp <= nodevupb DO
    { LET node = nodev!componentp
      //writef("componentp = %i5*n", componentp)
      IF s_dist!node < 0 DO
      { root := node
        //writef("new component root = %i5*n", root)
//abort(1008)
        BREAK
      }
      componentp := componentp + 1
    }
  }
}

AND prboard(S1, V4, H1, U4) BE
{ LET bit = #x80000

  WHILE bit DO
  { LET ch = '**'
    UNLESS (S1 & bit) = 0 DO ch := 'S'
    UNLESS (H1 & bit) = 0 DO ch := 'H'
    UNLESS (V4 & bit) = 0 DO ch := 'V'
    UNLESS (U4 & bit) = 0 DO ch := 'U'
    writef(" %c", ch)
    IF (bit & #x11110) > 0 DO writef("  ")
    bit := bit>>1
  }
}

AND prsol(node) BE
{ LET S1  = s_S1!node
  LET V4  = s_V4!node
  LET H1  = s_H1!node
  LET U4  = s_U4!node

  IF s_prev!node DO prsol(s_prev!node)

  writef("%i3: ", s_dist!node)
  prboard(S1, V4, H1, U4)

  IF S1=#x00066 DO writes("  solution")
  newline()
//abort(1000)
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


