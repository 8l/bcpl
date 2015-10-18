/*
This program was implemented by Martin Richards (c) June 2009

It attempts to solve a computationally difficult jigsaw puzzle with
n**2 pieces that are almost square but have edges that have possible
shapes A, B, C, D, 1, 2, 3 and 4. 

   ####/\####
A  ----  ----

Edge:    0   4      1    5      2    6      3    7

        #   ###     #   ###    #   ####    #    ###
        ##   ##     #   ###    ###    #    ##    ##
        ###   #     ###   #    ###    #    ##    ##
        ##   ##     #   ###    ###    #    ##    ##
        #   ###     #   ###    #   ####    #    ###

The only edges that interlock are 0-4, 1-5, 2-6 and 3-7. Each piece
can be rotated or turned over. The aim is to fit the pieces together
to form an n x n square. When two pieces are adjacent their connecting
edges must interlock. There is no constraint on the outside edges.

Example puzzles

2x2
Pieces:    6305  4017
           5124  6327

Solution:    3       0 
           6   0   4   1
             5       7

             1       3
           5   2   6   2
             4       7


3x3

4x4

5x5
Pieces:    1047  0365  2167  2174  3065
           3376  3166  2375  3054  1147
           0267  2257  3147  0075  3346
           6304  4016  5307  4125  6204
           0056  1267  2376  3157  1067  

Solution:    0        3        1        1        0
           1   4    0   6    2   6    2   6    3   6
             7        5        7        4        5

             3        1        3        0        1
           3   7    3   6    2   7    3   5    1   4
             6        6        5        4        7

             2        2        1        0        3
           0   6    2   5    3   4    0   7    3   4
             7        7        7        5        6

             3        0        3        1        2
           6   0    4   1    5   0    4   2    6   0
             4        6        7        5        4

             0        2        3        1        0
           0   5    1   6    2   7    3   5    1   6
             6        7         6       7        7  


The program performs an exhaustive raster scan search from the top
left to the bottom right using a pre-computed structure holding all
the rotations and reflections of each piece. For the 5x5 puzzle there
are 25 pieces numbered 1 to 25. Suppose piece 1 is 1047, then its
shape is:

                    0
                  #####
              #############
              #############
                 ###########
           1     ############ 4
                 ###########
              ###### ######
              ###### ######
                    7

When attepting to place this piece the left hand and top edges will
have already been determined, so can only be places if the left and
top codes are 5 and 4, respectively.

There is a vector, piecev, that holds information about each piece.
piece!1 points to a vector whose subscripts range from #00 to #77
identifying the rotations and reflections this piece that match each
given left and top edge. piecev!1!#10 will point to a list of elements
repesrenting the rotations and reflections of piece 1 having a left
edge with code 1 and a top edge with code 0. Each element of the set
holds the codes of the form #10xy representing a placement satisfying
the left and top edge constraints with x and y being the codes for the
right hand and bottom edges.

At an intermediate stage in the solution of the 5x5 puzzle, the
state might be as follows:

             0        3        1        1        0
           1   4    0   6    2   6    2   6    3   6
             7        5        7        4        5

             3        1
           3   7    3   x
             6        y

This partial solution is held in a vector called solutionv as follows:

solutionv!0 = #1047
solutionv!1 = #0365
solutionv!2 = #2167
solutionv!3 = #2164
solutionv!4 = #3065

The next element of solutionv to be filled has subscript 5 and this is
held in solutionp. The required form of the next placement is clearly
#31xy. The search try each element of the list piecev!i!#31 where i
identifies a currently unused piece. When solutionp=25 a solution has
been found.


The search takes in turn each unused piece i, say, and tries each
element of the set specified by piece!i!#06. At the beginning of a row
all possible left hand edges 0 to 7 are tried, and while in the
first row all possible top edges are tried. To avoid many rotational
and reflected solutions, one of the pieces is neither rotated nor
reflected.

*/

GET "libhdr"

GLOBAL {
  blklist: ug
  blkp
}

MANIFEST {
  blkupb = 4000
}

LET jigsaw1() = TABLE
  4,
  #3056, #0174,
  #1245, #3276

LET start() = VALOF
{
  writef("Jigsaw entered*n")

  blkp, blklist := 1, 0

  solve(jigsaw1())
  //solve(jigsaw2())
  //solve(jigsaw3())

  RESULTIS 0
}

AND solve(data) BE
{ LET n = data!0
  LET piece = newvec(n)
  FOR p = 1 TO n DO
  { LET w = data!p
    LET a = w>>9 & 7  // top
    AND b = w>>6 & 7  // right
    AND c = w>>3 & 7  // bottom
    AND d = w    & 7  // left
    LET p1 = a<<9 | b<<6 | c<<3 | d
    LET p2 = b<<9 | c<<6 | d<<3 | a
    LET p3 = c<<9 | d<<6 | a<<3 | b
    LET p4 = d<<9 | a<<6 | b<<3 | c
    LET p5 = d<<9 | c<<6 | b<<3 | a
    LET p6 = c<<9 | b<<6 | a<<3 | d
    LET p7 = b<<9 | a<<6 | d<<3 | c
    LET p8 = a<<9 | d<<6 | c<<3 | b
    LET v = newvec(#77)
    piece!p := v
    FOR j = #00 TO #77 DO v!j := 0

    insert(p1, v)
    UNLESS p2=p1 DO insert(p2, v)
    UNLESS p3=p1 | p3=p2 DO insert(p3, v)
    UNLESS p4=p1 | p4=p2 | p4=p3 DO insert(p4, v)
    UNLESS p5=p1 | p5=p2 | p5=p3 | p5=p4 DO insert(p5, v)
    UNLESS p6=p1 | p6=p2 | p6=p3 | p6=p4 | p6=p5 DO insert(p6, v)
    UNLESS p7=p1 | p7=p2 | p7=p3 | p7=p4 | p7=p5 | p7=p6 DO insert(p7, v)
    UNLESS p8=p1 | p8=p2 | p8=p3 | p8=p4 | p8=p5 | p8=p6 | p8=p7 DO insert(p8, v)
  } 
}

AND insert(w, v) BE
{ LET a = w>>9 & 7  // top
  AND b = w>>6 & 7  // right
  AND c = w>>3 & 7  // bottom
  AND d = w    & 7  // left

  LET i = d<<3 | a
  v!i := mk2(v!i, c<<3 | b)
  writef("insert: inserted %o4 in v=%n*n", w, v)
}

AND mk2(x, y) = VALOF
{ LET p = newvec(1)
  p!0, p!1 := x, y
  RESULTIS p
}

AND newvec(upb) = VALOF
{ LET res = ?
  IF blklist=0 | blkp + upb + 1 > blkupb DO
  { LET nb = getvec(blkupb)
    UNLESS nb DO
    { writef("newvec: failed*n")
      abort(999)
    }
    nb!0 := blklist
    blklist := nb
    blkp := 1
  }
  res := @blklist!blkp
  blkp := blkp + upb + 1

  RESULTIS res  
}

AND try(left, top, x, y) BE
{ // Try to place a piece at position (x,y)
  // left and top are the codes for the left and top edges.
  IF left=-1 DO
  { // We are at the start of a row and so must
    // explore all possible left edges.
    FOR edge = 0 TO 7 DO try(edge, top, x, y)
    RETURN
  }
  IF top=-1 DO
  { // We are on the top row and must explore all
    // top edges.
    FOR edge = 0 TO 7 DO try(left, edge, x, y)
    RETURN
  }
  
  { // Try each of the remainig pieces in turn
    LET i = left<<3 | top
    FOR p = 1 TO pieces_left DO
    { LET piece = piece!p
    } 
  }
}  
