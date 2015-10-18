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
placements of the ten pieces on the board of which only 25955 are
reachable from the initial position.  The puzzle has a graph with each
board position represented by a node each node having a list of other
nodes reachable by a single move. These connections between nodes are
called edges. The graph is said to be undirected since every move is
reversible.  The cluster of nodes reachable from a given node is
called, by mathematicians, a simply connected component. The sliding
block puzzle turns out to have 898 such components, the largest and
smallest having 25955 and 2 nodes. As we have seen, one of the
components of size 25955 node includes the starting position.

Implementation

The board is represented by a bit pattern with each bit indicating the
occupancy of each of the 20 squares on the board.

The vector bitsS holds bit patterns representing the 12 possible
placements of the 2x2 block in bitsS!1 to bitsS!12. The upper bound,
12, is held in bitsS!0.

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
 s_link=0      // link=0 or link -> another node at the dist value.
 s_dist        // dist=-1 or the distance from the starting position.
               // If dist=-1, this node has not yet been visited.
 s_prev        // prev=0 or prev -> predecessor node in the path
               // from the starting position to this node.
 s_chain       // chain=0 or chain -> another node with the same hash value.
 s_succs       // List of adjacent placement nodes.

               // succs=0 or succs -> [next, node]
 // Piece placement numbers
 s_S
 s_Va; s_Vb; s_Vc; s_Vd
 s_H
 s_Ua; s_Ub; s_Uc; s_Ud

 // Board placement bit patterns
 s_S1  // Positions occupied by the 2x2 piece
 s_V4  // Positions occupied by the 1x2 virtical pieces
 s_H1  // Positions occupied by the 2x1 horizontal piece
 s_U4  // Positions occupied by the 1x1 pieces

 s_upb=s_U4  // The upb of a placement node
}

/*

The program creates nodes all 65880 valid board placements and puts
pointers to them in elements nodev!1 to nodev!65880. nodev!0 is set to
the upper bound 65880. The fields S1, V4, H1 and U4 are distinct for
all placements. A hash table, hashtab, allows efficient looking up of
placement nodes given their S1, V4, H1 and U4 settings. The call
hashfn(S1,V4,H1,U4) computes the hash value. The pointer to the next
node in a hash chain is held in the chain field. All the placement
nodes are created by the call createnodes().

The program then creates, for each placement node, the list of
immediately adjacent placements. This is done by the call
createsuccs() which makes calls of the form mksuccs(node) for every
node in nodev.

The program next creates lists of nodes at different distances from
the starting position. These lists are placed in the vector listv with
listv!i holding the list of all nodes at distance i from the starting
position. These lists are created by the call createlists(). The call
find(#x66000,#x09999,#x00006,#00660) finds the starting node, which is
given a dist value of zero and becomes the only node in listv!0. All
other nodes initially have dist values of -1, indicating that their
distances are not yet known. The dist field is set to i for all nodes
in the list listv!i. The list of nodes at distance i from the starting
position is constructed by the call createlist(i) which inspects every
node in listv!(i-1). Each successor to these nodes, that have not be
visited previously, is inserted into listv!i, with its dist field set
to i and its prev field set to the immediate predecessor. The variable
solution points to the first node visited that has the 2x2 placed
centrally at the bottom. This combined with the prev field values
allows the solution to be output. If listv!i turns out to be empty, all
reachable nodes have been visited and createlists returns.

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

While there are still unvisited nodes, the program goes on to find
another component using any unvisited node as the starting node and
calling createlists again.

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
  componentsizemax
  componentsizemin
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
  Spaceupb  = 2_000_000
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

  solution         := 0
  nodecount        := 0
  edgecount        := 0
  componentcount   := 0
  componentsize    := 0
  componentsizemax := 0
  componentsizemin := maxint
  componentp := 0

  spacev := getvec(Spaceupb)

  UNLESS spacev DO
  { writef("Insufficient space available*n")
    RESULTIS 20
  }

  spacep, spacet := spacev, spacev+Spaceupb

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

IF FALSE DO
  FOR i = 1 TO nodev!0 DO
  { LET node = nodev!i
    LET succs = s_succs!node
    writef("node %i7: ", i)
    prboard(s_S1!node, s_V4!node, s_H1!node, s_U4!node)
    //writef("*nsuccs: ")
    //WHILE succs DO
    //{ writef(" %i5", succs!1)
    //  succs := succs!0
    //}
    newline()
    succs := s_succs!node
    WHILE succs DO
    { LET succ = succs!1
      writef("succ %i7: ", succ)
      prboard(s_S1!succ, s_V4!succ, s_H1!succ, s_U4!succ)
      newline()
      succs := succs!0
    }
    //abort(1000)
  }

  explore()

  // Lists of nodes at all distances have now been created
  // so output the solution

  IF solution DO prsol(solution)

  writef("nodecount=       %n*n",   nodecount)
  writef("edgecount=       %n*n",   edgecount)
  writef("componentcount=  %n*n",   componentcount)
  writef("componentsizemax=%n*n",   componentsizemax)
  writef("componentsizemin=%n*n",   componentsizemin)
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
    FOR va = 1 TO bitsV!0 - 3 IF (bits & bitsV!va)=0 DO
    { bits := bits + bitsV!va
      FOR vb = va+1 TO bitsV!0 - 2 IF (bits & bitsV!vb)=0 DO
      { bits := bits + bitsV!vb
        FOR vc = vb+1 TO bitsV!0 - 1 IF (bits & bitsV!vc)=0 DO
        { bits := bits + bitsV!vc
          FOR vd = vc+1 TO bitsV!0 IF (bits & bitsV!vd)=0 DO
          { bits := bits + bitsV!vd
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
  componentcount := 0
  componentsizemax := 0
  componentsizemin := maxint

  root := find(#x66000, #x09999, #x00006, #x00660)

  WHILE root DO
  { LET dist = ?

    // Insert the root of the next simply connected component
    s_link!root, s_dist!root := 0, 0
    listv!0 := root
    dist := 0
    componentcount := componentcount + 1
    componentsize := 1

    WHILE listv!dist DO
    { dist := dist+1
      createlist(dist)
    }

    // The component is now complete
    IF componentsize > componentsizemax DO componentsizemax := componentsize
    IF componentsize < componentsizemin DO componentsizemin := componentsize

    IF tracing DO
    { writef("Component %i3 size %i5 root ", componentcount, componentsize)
      prboard(s_S1!root, s_V4!root, s_H1!root, s_U4!root)
      newline()
      //abort(1007)
    }

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

AND createlist(dist) BE
{ LET prevnode = listv!(dist-1) // List of nodes at distance dist
  //writef("Making list of nodes at distance %n*n", dist)
  //writef("prevnode=%n*n", prevnode)
//abort(1006)

  // Create list of nodes at the new distance
  listv!dist := 0

  WHILE prevnode DO
  { // prevnode is a node at the previous distance.
    // Any successors of prevnode that have not yet been
    // visited are to be inserted into listv!dist.
    LET succs = s_succs!prevnode // List of nodes adjacent to prevnode

//writef("exploring successors of  ")
//prboard(s_S1!prevnode, s_V4!prevnode, s_H!prevnode, s_U4!prevnode)
//newline()
 
    WHILE succs DO
    { LET succ = succs!1 // succ is a successor to prevnode
      IF s_dist!succ < 0 DO
      { // succ has not yet been visited
        s_dist!succ := dist
        s_prev!succ := prevnode
        s_link!succ := listv!dist
        listv!dist := succ
        componentsize := componentsize + 1
        //writef("dist=%i4  ", dist)
        //prboard(s_S1!succ, s_V4!succ, s_H1!succ, s_U4!succ)
        //newline()
        UNLESS solution IF s_S1!succ=#x00066 DO
        { solution := succ
          //writef("Solution*n")
          //abort(1111)
        }
        //abort(3000)
      }
      succs := succs!0
    }
    prevnode := s_link!prevnode
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
}


/*
When this program runs it outputs the following

  0:  * S S *   V S S V   V U U V   V U U V   V H H V
  1:  V S S *   V S S V   * U U V   V U U V   V H H V
  2:  V S S *   V S S V   V U U V   V U U V   * H H V
  3:  V S S *   V S S V   V U U V   V U U V   H H * V
  4:  V S S V   V S S V   V U U *   V U U V   H H * V
  5:  V S S V   V S S V   V U U *   V U * V   H H U V
  6:  V S S V   V S S V   V U * U   V U * V   H H U V
  7:  V S S V   V S S V   V U * U   V * U V   H H U V
  8:  V S S V   V S S V   V * U U   V * U V   H H U V
  9:  V S S V   V S S V   * V U U   * V U V   H H U V
 10:  * S S V   V S S V   V V U U   * V U V   H H U V
 11:  * S S V   * S S V   V V U U   V V U V   H H U V
 12:  S S * V   S S * V   V V U U   V V U V   H H U V
 13:  S S * V   S S U V   V V * U   V V U V   H H U V
 14:  S S U V   S S * V   V V * U   V V U V   H H U V
 15:  S S U V   S S * V   V V U U   V V * V   H H U V
 16:  S S U V   S S U V   V V * U   V V * V   H H U V
 17:  S S U V   S S U V   V V U *   V V * V   H H U V
 18:  S S U V   S S U V   V V U *   V V U V   H H * V
 19:  S S U V   S S U V   V V U V   V V U V   H H * *
 20:  S S U V   S S U V   V V U V   V V U V   * H H *
 21:  S S U V   S S U V   V V U V   V V U V   * * H H
 22:  S S U V   S S U V   V * U V   V V U V   * V H H
 23:  S S U V   S S U V   * * U V   V V U V   V V H H
 24:  * * U V   S S U V   S S U V   V V U V   V V H H
 25:  * U * V   S S U V   S S U V   V V U V   V V H H
 26:  U * * V   S S U V   S S U V   V V U V   V V H H
 27:  U * U V   S S * V   S S U V   V V U V   V V H H
 28:  U U * V   S S * V   S S U V   V V U V   V V H H
 29:  U U * V   S S U V   S S * V   V V U V   V V H H
 30:  U U U V   S S * V   S S * V   V V U V   V V H H
 31:  U U U V   * S S V   * S S V   V V U V   V V H H
 32:  U U U V   * S S V   V S S V   V V U V   * V H H
 33:  U U U V   V S S V   V S S V   * V U V   * V H H
 34:  U U U V   V S S V   V S S V   V * U V   V * H H
 35:  U U U V   V S S V   V S S V   V U * V   V * H H
 36:  U U U V   V S S V   V S S V   V * * V   V U H H
 37:  U U U V   V * * V   V S S V   V S S V   V U H H
 38:  U * U V   V U * V   V S S V   V S S V   V U H H
 39:  U U * V   V U * V   V S S V   V S S V   V U H H
 40:  U U V *   V U V *   V S S V   V S S V   V U H H
 41:  U U V *   V U V V   V S S V   V S S *   V U H H
 42:  U U V V   V U V V   V S S *   V S S *   V U H H
 43:  U U V V   V U V V   V * S S   V * S S   V U H H
 44:  U U V V   V * V V   V U S S   V * S S   V U H H
 45:  U * V V   V U V V   V U S S   V * S S   V U H H
 46:  * U V V   V U V V   V U S S   V * S S   V U H H
 47:  V U V V   V U V V   * U S S   V * S S   V U H H
 48:  V U V V   V U V V   V U S S   V * S S   * U H H
 49:  V U V V   V U V V   V * S S   V U S S   * U H H
 50:  V U V V   V U V V   V * S S   V U S S   U * H H
 51:  V U V V   V U V V   V * S S   V * S S   U U H H
 52:  V U V V   V U V V   V S S *   V S S *   U U H H
 53:  V U V *   V U V V   V S S V   V S S *   U U H H
 54:  V U V *   V U V *   V S S V   V S S V   U U H H
 55:  V U * V   V U * V   V S S V   V S S V   U U H H
 56:  V * U V   V U * V   V S S V   V S S V   U U H H
 57:  V * U V   V * U V   V S S V   V S S V   U U H H
 58:  * V U V   * V U V   V S S V   V S S V   U U H H
 59:  * V U V   V V U V   V S S V   * S S V   U U H H
 60:  V V U V   V V U V   * S S V   * S S V   U U H H
 61:  V V U V   V V U V   S S * V   S S * V   U U H H
 62:  V V U V   V V * V   S S U V   S S * V   U U H H
 63:  V V * V   V V U V   S S U V   S S * V   U U H H
 64:  V V * V   V V U V   S S * V   S S U V   U U H H
 65:  V V * V   V V * V   S S U V   S S U V   U U H H
 66:  V V V *   V V V *   S S U V   S S U V   U U H H
 67:  V V V *   V V V V   S S U V   S S U *   U U H H
 68:  V V V V   V V V V   S S U *   S S U *   U U H H
 69:  V V V V   V V V V   S S * U   S S U *   U U H H
 70:  V V V V   V V V V   S S U U   S S * *   U U H H
 71:  V V V V   V V V V   S S U U   S S H H   U U * *
 72:  V V V V   V V V V   S S U U   S S H H   U * U *
 73:  V V V V   V V V V   S S U U   S S H H   * U U *
 74:  V V V V   V V V V   S S U U   S S H H   * U * U
 75:  V V V V   V V V V   S S U U   S S H H   * * U U
 76:  V V V V   V V V V   * * U U   S S H H   S S U U
 77:  V V V V   V V V V   * U * U   S S H H   S S U U
 78:  V V V V   V V V V   U * * U   S S H H   S S U U
 79:  V V V V   V V V V   U * U *   S S H H   S S U U
 80:  V V V V   V V V V   U U * *   S S H H   S S U U
 81:  V V V V   V V V V   U U H H   S S * *   S S U U
 82:  V V V V   V V V V   U U H H   S S U *   S S * U
 83:  V V V V   V V V V   U U H H   S S * U   S S * U
 84:  V V V V   V V V V   U U H H   * S S U   * S S U  solution
nodecount=       65880
edgecount=       206780
componentcount=  898
componentsizemax=25955
componentsizemin=2
space used = 1736680 words
*/


