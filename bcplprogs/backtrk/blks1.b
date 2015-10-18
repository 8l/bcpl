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
centrally at the bottom. It is believed this takes a minimum of 114
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
  treev   // treev!d  is the list of positions at depth d

  tracing
  count
  maxd
  found
}

MANIFEST {
  N_p=0            // Parent
  N_left; N_right  // Tree link
  N_hash           // Hash of the position
  N_sb; N_hb; N_vb; N_ub
  N_s              // Block placement numbers
  N_h
  N_v1
  N_v2
  N_v3
  N_v4
  N_u1
  N_u2
  N_u3
  N_u4
  N_upb=N_u4       // The upper bound

  Spaceupb=4000000
}

LET start() = VALOF
{ LET argv = VEC 50
  LET stdout = output()
  LET out = stdout

  UNLESS rdargs("-d,-o/k,-t/s", argv, 50) DO
  { writef("Bad arguments for blks*n")
    RESULTIS 20
  }

  maxd := argv!0 -> str2numb(argv!0), 114

  IF argv!1 DO
  { out := findoutput(argv!1)
    UNLESS out DO
    { writef("Unable to open output file %s*n", argv!1)
      RESULTIS 20
    }
    selectoutput(out)
  }

  tracing := argv!2
  count := 0
  found := FALSE

  spacev := getvec(Spaceupb)
  spacep, spacet := spacev, spacev+Spaceupb
  UNLESS spacev DO
  { writef("Insufficient space available*n")
    RESULTIS 20
  }

//  writef("blks1 entered*n")

  initvecs()
//  writef("initialisation done*n")

  put(0, 0, 2, 8, 5,8,13,16, 14,15,18,19) // Put in the initial position
  FOR d = 0 TO maxd-1 DO
  { count := 0
    putsuccs(d, treev!d)
    //prtree(0, treev!(d+1))
//    writef("There are %i5 positions at depth %i2*n", count, d+1)
  }
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

AND mknode(p, hash,
           sb, hb, vb, ub,
           s, h, v1,v2,v3,v4, u1,u2,u3,u4) = VALOF
{ LET t = spacep
  spacep := spacep+N_upb+1
  IF spacep>spacet DO
  { writef("Insufficient space*n")
    abort(999)
    RESULTIS 0
  }
  N_p!t     := p
  N_left!t  := 0
  N_right!t := 0
  N_hash!t  := hash
  N_sb!t    := sb
  N_hb!t    := hb
  N_vb!t    := vb
  N_ub!t    := ub
  N_s!t     := s
  N_h!t     := h
  N_v1!t    := v1
  N_v2!t    := v2
  N_v3!t    := v3
  N_v4!t    := v4
  N_u1!t    := u1
  N_u2!t    := u2
  N_u3!t    := u3
  N_u4!t    := u4
  RESULTIS t
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

  treev := mkvec(200)
  FOR i = 0 TO 200 DO treev!i := 0
}

AND put(d, p, s, h, v1, v2, v3, v4, u1, u2, u3, u4) BE
{ LET sb   = sv!s
  LET hb   = hv!h
  LET vb   = vv!v1+vv!v2+vv!v3+vv!v4
  LET ub   = uv!u1+uv!u2+uv!u3+uv!u4
  LET used = sb+hb+vb+ub
  LET hash = hashfn(d, sb, hb, vb, ub)
  LET a    = @treev!d

  IF d>=200 RETURN

  IF tracing DO
    writef("%i2 %i2 %i2 %i2 %i2 %i2 %i2 %i2 %i2 %i2 *n",
            s,  h,  v1, v2, v3, v4, u1, u2, u3, u4)
  // Test for backward move
  IF d>1 & member(d-2, sb, hb, vb, ub) RETURN
  
//writef("INSERTING*n")
//pr(d, sb, hb, vb,ub)

  { LET t = !a
    IF t=0 BREAK
//    writef("VISITING TREE NODE %n(%n, %n)*n", t, N_left!t, N_right!t)
//pr(d, N_sb!t, N_hb!t, N_vb!t, N_ub!t)
    IF hash=N_hash!t DO
    { //writef("NODE ALREADY IN TREE*n")
      RETURN
    }
    a := hash < N_hash!t -> @N_left!t, @N_right!t
  } REPEAT

  count := count+1


  !a := mknode(p, hash,
               sb, hb, vb, ub,
               s, h, v1,v2,v3,v4, u1,u2,u3,u4)
//writef("NODE %n ADDED TO TREE*n", !a)
//  pr(d, sb, hb, vb,ub)
//prtree(0, treev!d)

  IF s=11 DO
  { LET t = !a
    LET n = d
    IF found RETURN
    found := TRUE
    writef("Solution found*n")
    WHILE t DO
    { pr(n, N_sb!t, N_hb!t, N_vb!t, N_ub!t)
      t := N_p!t
      n := n-1
    }
//    abort(1000)
    RETURN
  }

}

AND hashfn(d, sb,hb,vb,ub) = VALOF
//{ LET h = sb*12345 NEQV hb*34567 NEQV vb*56789 NEQV ub
{ LET h = sb*hb NEQV vb*ub
  FOR i = 1 TO 5 DO sb := 2147001325*sb + 715136305
  FOR i = 1 TO 5 DO hb := 2147001325*hb + 715136305
  FOR i = 1 TO 5 DO vb := 2147001325*vb + 715136305
  FOR i = 1 TO 5 DO ub := 2147001325*ub + 715136305
  h := h + (sb NEQV hb NEQV vb NEQV ub)
  FOR i = 1 TO 3 + (d & 3) DO h := 2147001325*h + 715136305
  h := (h & maxint) REM 10000000
  RESULTIS h
}

AND member(d, sb, hb, vb, ub) = VALOF
{ LET hash = hashfn(d, sb, hb, vb, ub)
  LET t = treev!d
//writef("member: %n *n", hash)
//prtree(0, t)
  WHILE t DO
  { //writef("Comparing %n with %n*n", hash, N_hash!t)
    IF hash=N_hash!t RESULTIS TRUE //&
//       sb=N_sb!t & hb=N_hb!t & vb=N_vb!t & ub=N_ub!t RESULTIS TRUE
    t := hash < N_hash!t -> N_left!t, N_right!t
  }
//writef("NOT a member*n")
  RESULTIS FALSE
}

AND prtree(n, t) BE IF t DO
{ prtree(n+1, N_left!t)
  FOR i = 1 TO n DO wrch(' ')
  writef("%n*n", N_hash!t)
  prtree(n+1, N_right!t)
}

AND putsuccs(d, t) BE
{ UNLESS t RETURN
  putsuccs(d, N_left!t)
  dosuccs(d, t)
  putsuccs(d, N_right!t)
}

AND dosuccs(d, t) BE
{ LET p  = N_p!t
  LET s  = N_s!t
  LET h  = N_h!t
  LET v1 = N_v1!t
  LET v2 = N_v2!t
  LET v3 = N_v3!t
  LET v4 = N_v4!t
  LET u1 = N_u1!t
  LET u2 = N_u2!t
  LET u3 = N_u3!t
  LET u4 = N_u4!t
  LET sb = sv!s
  LET hb = hv!h
  LET vb = vv!v1+vv!v2+vv!v3+vv!v4
  LET ub = uv!u1+uv!u2+uv!u3+uv!u4
  LET used = sb+hb+vb+ub

  { LET adj = adjsv!s // Try moving the 2x2 block
    used := used-sb
    WHILE adj DO
    { LET x = adj&255
      adj := adj>>8
      IF tracing DO writef("considering s=%n*n", x)
      IF x=0 | (used&sv!x)>0 LOOP
      put(d+1, t, x, h, v1,v2,v3,v4, u1,u2,u3,u4)
    }
    used := used+sb
  }

  { LET adj = adjhv!h // Try moving the 2x1 block
    used := used-hb
    WHILE adj DO
    { LET x = adj&255
      adj := adj>>8
      IF tracing DO writef("considering h=%n*n", x)
      IF x=0 | (used&hv!x)>0 LOOP
      put(d+1, t, s, x, v1,v2,v3,v4, u1,u2,u3,u4)
    }
    used := used+hb
  }

  { LET adj = adjvv!v1 // Try moving the first 1x2 block
    used := used-vv!v1
    WHILE adj DO
    { LET x = adj&255
      adj := adj>>8
      IF tracing DO writef("considering v1=%n*n", x)
      IF x=0 | (used&vv!x)>0 LOOP
      put(d+1, t, s, h, x,v2,v3,v4, u1,u2,u3,u4)
    }
    used := used+vv!v1
  }

  { LET adj = adjvv!v2 // Try moving the second 1x2 block
    used := used-vv!v2
    WHILE adj DO
    { LET x = adj&255
      adj := adj>>8
      IF tracing DO writef("considering v2=%n*n", x)
      IF x=0 | (used&vv!x)>0 LOOP
      put(d+1, t, s, h, v1,x,v3,v4, u1,u2,u3,u4)
    }
    used := used+vv!v2
  }

  { LET adj = adjvv!v3 // Try moving the third 1x2 block
    used := used-vv!v3
    WHILE adj DO
    { LET x = adj&255
      adj := adj>>8
      IF tracing DO writef("considering v3=%n*n", x)
      IF x=0 | (used&vv!x)>0 LOOP
      put(d+1, t, s, h, v1,v2,x,v4, u1,u2,u3,u4)
    }
    used := used+vv!v3
  }

  { LET adj = adjvv!v4 // Try moving the fourth 1x2 block
    used := used-vv!v4
    WHILE adj DO
    { LET x = adj&255
      adj := adj>>8
      IF tracing DO writef("considering v4=%n*n", x)
      IF x=0 | (used&vv!x)>0 LOOP
      put(d+1, t, s, h, v1,v2,v3,x, u1,u2,u3,u4)
    }
    used := used+vv!v4
  }

  { LET adj = adjuv!u1 // Try moving the first 1x1 block
    used := used-uv!u1
    WHILE adj DO
    { LET x = adj&255
      adj := adj>>8
      IF tracing DO writef("considering u1=%n*n", x)
      IF x=0 | (used&uv!x)>0 LOOP
      put(d+1, t, s, h, v1,v2,v3,v4, x,u2,u3,u4)
    }
    used := used+uv!u1
  }

  { LET adj = adjuv!u2 // Try moving the second 1x1 block
    used := used-uv!u2
    WHILE adj DO
    { LET x = adj&255
      adj := adj>>8
      IF tracing DO writef("considering u2=%n*n", x)
      IF x=0 | (used&uv!x)>0 LOOP
      put(d+1, t, s, h, v1,v2,v3,v4, u1,x,u3,u4)
    }
    used := used+uv!u2
  }

  { LET adj = adjuv!u3 // Try moving the third 1x1 block
    used := used-uv!u3
    WHILE adj DO
    { LET x = adj&255
      adj := adj>>8
      IF tracing DO writef("considering u3=%n*n", x)
      IF x=0 | (used&uv!x)>0 LOOP
      put(d+1, t, s, h, v1,v2,v3,v4, u1,u2,x,u4)
    }
    used := used+uv!u3
  }

  { LET adj = adjuv!u4 // Try moving the fourth 1x1 block
    used := used-uv!u4
    WHILE adj DO
    { LET x = adj&255
      adj := adj>>8
      IF tracing DO writef("considering u4=%n*n", x)
      IF x=0 | (used&uv!x)>0 LOOP
      put(d+1, t, s, h, v1,v2,v3,v4, u1,u2,u3,x)
    }
    used := used+uv!u4
  }

}

AND pr(n, sb, hb, vb, ub) BE
{ FOR sh = 19 TO 0 BY -1 DO
  { LET bit = 1<<sh
    LET ch = '**'
    UNLESS (sb&bit) = 0 DO ch := 'S'
    UNLESS (hb&bit) = 0 DO ch := 'H'
    UNLESS (vb&bit) = 0 DO ch := 'V'
    UNLESS (ub&bit) = 0 DO ch := 'U'
    writef(" %c", ch)

    IF sh REM 4 = 0 TEST sh=16 THEN writef("   %i3*n", n)
                               ELSE newline()
  }
  newline()
}



