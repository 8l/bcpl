/*
********************* UNDER DEVELOPMENT ***************************

This program is designed to find a minimum cost solution to
a sliding blocks puzzle.

Implemented in BCPL by Martin Richards  (c) August 2000

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
         | VVV | HHHHHHHHH | VVV |
         | VVV | HHHHHHHHH | VVV |
         |-----|-----------|-----|
         | VVV | UUU | UUU | VVV |
         | VVV | UUU | UUU | VVV |
         | VVV |-----|-----| VVV |
         | VVV | UUU | UUU | VVV |
         | VVV | UUU | UUU | VVV |
          -----------------------

The aim is to slide the blocks until the 2x2 square is positioned
centrally at the bottom. It is believed this takes a minimum of 79
moves, where a move is defined to be moving a block one position up,
down, left or right by one place.

Implementation

The board is represented by a bit pattern with one bit to indicate
the occupancy of each square on the board.

The vector sv holds bit patterns representing the 12 possible
placements of the 2x2 block.

The vector hv holds bit patterns representing the 15 possible
placements of the horizontally oriented 2x1 block.

The vector vv holds bit patterns representing the 16 possible
placements of a vertically oriented 1x2 block.

The vector uv holds bit patterns representing the 20 possible
placements of a 1x1 block.

A particular placement of the 2x2 block can be represented by a
placement number p in the range 1 to 12. The bit pattern representing
which board positions it occupies is sv!p. It immediately adjacent
placements are packed into the 4 byte integer adjsv!p. This integer
contains the bytes a, b, c and d, giving the placement numbers
corresponding to moves in the directions up, left, right and down,
respectively. If a move that would shift the block over the edge of
the board is given a byte is zero. The initial placement number of the
2x2 block is 2, and sv!2 = #x6600 gives the four board positions that
it occupies. The adjacency bytes are packed in adjsv!2 = #x00010305,
indicating that it cannot be moves up, but can move left, right and
down to placement numbers 1, 3 and 5, respectively.

The vectors adjhv, adjvv and adjuv contain adjacency information
for the 2x1, 1x2 and 1x1 blocks in a form similar to adjsv.

*/

GET "libhdr"

GLOBAL {
  sv:ug; adjsv
  hv;    adjhv
  vv;    adjvv
  uv;    adjuv

  spacev; spacep; spacet

  visv    // visited bit map
  tracing
  prcount
}

MANIFEST {
 Visvupb = 1450000
}

LET start() = VALOF
{ LET argv = VEC 50
  LET stdout = output()
  LET out = stdout

  UNLESS rdargs("-o/k,-t/s", argv, 50) DO
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
  prcount := 0

  spacev := getvec(1500000)
  spacep, spacet := spacev, spacev+1500000
  UNLESS spacev DO
  { writef("Insufficient space available*n")
    RESULTIS 20
  }

  writef("blks entered*n")

  initvecs()
  writef("initialisation done*n")

  search()

fin:
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

AND initvecs() BE
{ // 2x2 square block
  sv :=    TABLE 12,    // placement bits
           #xCC000,    #x66000,    #x33000,
           #x0CC00,    #x06600,    #x03300,
           #x00CC0,    #x00660,    #x00330,
           #x000CC,    #x00066,    #x00033
  adjsv := TABLE 12,  // adjacent positions
           #x00000204, #x00010305, #x00020006,
           #x01000507, #x02040608, #x03050009,
           #x0400080A, #x0507090B, #x0608000C,
           #x07000B00, #x080A0C00, #x090B0000

  // 2x1 horizontal block
  hv :=    TABLE 15,    // placement bits
           #xC0000,    #x60000,    #x30000,
           #x0C000,    #x06000,    #x03000,
           #x00C00,    #x00600,    #x00300,
           #x000C0,    #x00060,    #x00030,
           #x0000C,    #x00006,    #x00003
  adjhv := TABLE 15,  // adjacent positions
           #x00000204, #x00010305, #x00020006,
           #x01000507, #x02040608, #x03050009,
           #x0400080A, #x0507090B, #x0608000C,
           #x07000B0D, #x080A0C0E, #x090B000F,
           #x0A000E00, #x0B0D0F00, #x0C0E0000

  // 1x2 vertical block
  vv :=    TABLE 16,    // placement bits
           #x88000,    #x44000,    #x22000,    #x11000,
           #x08800,    #x04400,    #x02200,    #x01100,
           #x00880,    #x00440,    #x00220,    #x00110,
           #x00088,    #x00044,    #x00022,    #x00011
  adjvv := TABLE 16,  // adjacent positions
           #x00000205, #x00010306, #x00020407, #x00030008,
           #x01000609, #x0205070A, #x0306080B, #x0407000C,
           #x05000A0D, #x06090B0E, #x070A0C0F, #x080B0010,
           #x09000E00, #x0A0D0F00, #x0B0E1000, #x0C0F0000

  // 1x1 unit squares
  uv :=    TABLE 20,    // placement bits
           #x80000,    #x40000,    #x20000,    #x10000,
           #x08000,    #x04000,    #x02000,    #x01000,
           #x00800,    #x00400,    #x00200,    #x00100,
           #x00080,    #x00040,    #x00020,    #x00010,
           #x00008,    #x00004,    #x00002,    #x00001
  adjuv := TABLE 20,  // adjacent positions
           #x00000205, #x00010306, #x00020407, #x00030008,
           #x01000609, #x0205070A, #x0306080B, #x0407000C,
           #x05000A0D, #x06090B0E, #x070A0C0F, #x080B0010,
           #x09000E11, #x0A0D0F12, #x0B0E1013, #x0C0F0014,
           #x0D001200, #x0E111300, #x0F121400, #x10130000

  visv := mkvec(Visvupb)
  FOR i = 0 TO Visvupb DO visv!i := 0
}

AND search() BE
{ try(0, 2, 8, 5,8,13,16, 14,15,18,19) // Search from the initial position
  writef("End of search*n")
}

AND visited(sb, hb, vb, ub) = VALOF
{ LET hsh = (sb*12345 + hb*34567 + vb*56789 + ub) & maxint
  LET i = hsh REM Visvupb
  LET bit = 1 << (hsh REM 32)
  IF (visv!i & bit)~=0 RESULTIS TRUE
  visv!i := visv!i + bit  // Mark as visited
  RESULTIS FALSE
}


AND try(n, s, h, v1, v2, v3, v4, u1, u2, u3, u4) BE
{ LET sb = sv!s
  LET hb = hv!h
  LET vb = vv!v1+vv!v2+vv!v3+vv!v4
  LET ub = uv!u1+uv!u2+uv!u3+uv!u4
  LET used = sb+hb+vb+ub

//  IF n>800 RETURN

  IF tracing DO
  { writef("%i2 %i2 %i2 %i2 %i2 %i2 %i2 %i2 %i2 %i2 *n",
            s,  h,  v1, v2, v3, v4, u1, u2, u3, u4)
    abort(1000)
  }
  IF visited(sb, hb, vb, ub) RETURN
  
//  pr(n, sb, hb, vb,ub)

  IF s=11 DO
  { writef("Solution found!!!*n")
    pr(n, sb, hb, vb,ub)
//    abort(1000)
    RETURN
  }

  { LET adj = adjsv!s // Try moving the 2x2 block
    used := used-sb
    WHILE adj DO
    { LET p = adj&255
      adj := adj>>8
      IF tracing DO writef("considering s=%n*n", p)
      IF p=0 | (used&sv!p)>0 LOOP
      try(n+1, p, h, v1,v2,v3,v4, u1,u2,u3,u4)
    }
    used := used+sb
  }

  { LET adj = adjhv!h // Try moving the 2x1 block
    used := used-hb
    WHILE adj DO
    { LET p = adj&255
      adj := adj>>8
      IF tracing DO writef("considering h=%n*n", p)
      IF p=0 | (used&hv!p)>0 LOOP
      try(n+1, s, p, v1,v2,v3,v4, u1,u2,u3,u4)
    }
    used := used+hb
  }

  { LET adj = adjvv!v1 // Try moving the first 1x2 block
    used := used-vv!v1
    WHILE adj DO
    { LET p = adj&255
      adj := adj>>8
      IF tracing DO writef("considering v1=%n*n", p)
      IF p=0 | (used&vv!p)>0 LOOP
      try(n+1, s, h, p,v2,v3,v4, u1,u2,u3,u4)
    }
    used := used+vv!v1
  }

  { LET adj = adjvv!v2 // Try moving the second 1x2 block
    used := used-vv!v2
    WHILE adj DO
    { LET p = adj&255
      adj := adj>>8
      IF tracing DO writef("considering v2=%n*n", p)
      IF p=0 | (used&vv!p)>0 LOOP
      try(n+1, s, h, v1,p,v3,v4, u1,u2,u3,u4)
    }
    used := used+vv!v2
  }

  { LET adj = adjvv!v3 // Try moving the third 1x2 block
    used := used-vv!v3
    WHILE adj DO
    { LET p = adj&255
      adj := adj>>8
      IF tracing DO writef("considering v3=%n*n", p)
      IF p=0 | (used&vv!p)>0 LOOP
      try(n+1, s, h, v1,v2,p,v4, u1,u2,u3,u4)
    }
    used := used+vv!v3
  }

  { LET adj = adjvv!v4 // Try moving the fourth 1x2 block
    used := used-vv!v4
    WHILE adj DO
    { LET p = adj&255
      adj := adj>>8
      IF tracing DO writef("considering v4=%n*n", p)
      IF p=0 | (used&vv!p)>0 LOOP
      try(n+1, s, h, v1,v2,v3,p, u1,u2,u3,u4)
    }
    used := used+vv!v4
  }

  { LET adj = adjuv!u1 // Try moving the first 1x1 block
    used := used-uv!u1
    WHILE adj DO
    { LET p = adj&255
      adj := adj>>8
      IF tracing DO writef("considering u1=%n*n", p)
      IF p=0 | (used&uv!p)>0 LOOP
      try(n+1, s, h, v1,v2,v3,v4, p,u2,u3,u4)
    }
    used := used+uv!u1
  }

  { LET adj = adjuv!u2 // Try moving the second 1x1 block
    used := used-uv!u2
    WHILE adj DO
    { LET p = adj&255
      adj := adj>>8
      IF tracing DO writef("considering u2=%n*n", p)
      IF p=0 | (used&uv!p)>0 LOOP
      try(n+1, s, h, v1,v2,v3,v4, u1,p,u3,u4)
    }
    used := used+uv!u2
  }

  { LET adj = adjuv!u3 // Try moving the third 1x1 block
    used := used-uv!u3
    WHILE adj DO
    { LET p = adj&255
      adj := adj>>8
      IF tracing DO writef("considering u3=%n*n", p)
      IF p=0 | (used&uv!p)>0 LOOP
      try(n+1, s, h, v1,v2,v3,v4, u1,u2,p,u4)
    }
    used := used+uv!u3
  }

  { LET adj = adjuv!u4 // Try moving the fourth 1x1 block
    used := used-uv!u4
    WHILE adj DO
    { LET p = adj&255
      adj := adj>>8
      IF tracing DO writef("considering u4=%n*n", p)
      IF p=0 | (used&uv!p)>0 LOOP
      try(n+1, s, h, v1,v2,v3,v4, u1,u2,u3,p)
    }
    used := used+uv!u4
  }

}

AND pr(n, sb, hb, vb, ub) BE
{ LET sep = '*s'
  prcount := prcount+1
  writef("Position %i5   depth %i4  %c", prcount, n, sep)
  FOR sh = 19 TO 0 BY -1 DO
  { LET bit = 1<<sh
    LET ch = '**'
    UNLESS (sb&bit) = 0 DO ch := 'S'
    UNLESS (hb&bit) = 0 DO ch := 'H'
    UNLESS (vb&bit) = 0 DO ch := 'V'
    UNLESS (ub&bit) = 0 DO ch := 'U'
    wrch(ch)
    UNLESS sh REM 4 DO wrch(sep)
  }
  newline()
}


