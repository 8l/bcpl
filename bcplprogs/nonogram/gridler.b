// This is another demonstration program to solve a backtracking
// problem using recursion. It is a very naive implementation
// and can be made to run much faster in several ways, such as
// not recomputing the possible placements in a row or column
// if nothing has changed in that row or column. When recursion
// is necessary the pivot cell could be better chosen.

// Copyright: Martin Richards,  September 2005

GET "libhdr"


LET filename() = "nonograms/n783"
//LET filename() = "nonograms/n778"
//LET filename() = "nonograms/gtst"


MANIFEST {

// Bit patterns used in elements of boardv, possv and placementv

Wbit = 1      // If (cell&Wbit)~=0 that cell can still be coloured white 
Bbit = 2      // If (cell&Wbit)~=0 that cell can still be coloured black
}

GLOBAL {

rows: ug      // The number of rows
cols          // The number of columns

xupb          // = cols-1
yupb          // = rows-1

spacev        // To hold board vectors etc
spacet        // Points to just beyond the end of spacev
spacep        // Points to next free position in spacev

boardv        // The current board vector
boardvupb     // upperbound of boardv (= rows*cols-1)

linev         // Points to the first cell in boardv of the
              // current row or column
sep           // =1    if current line is a row,
              // =cols if current line is a column.

possv         // possv!p holds a bit pattern showing the possible
              // settings of the cell at position p
placementv    // Used to hold the next valid placement of blocks
              // in the current row or column. Each element of
              // placementv will be either Wbit or Bbit.
placementvupb // The upperbound of placementv (=rows-1 or =cols-1).

xdatav      // This holds vectors of block sizes for each row
ydatav      // This holds vectors of block sizes for each column

// The freedom value of a row is the number of cells between the last cell
// of the last block and the end of the row when all the blocks are packed
// to the left as closely as possible, ie with just one white cell
// separating each block. If there are k blocks in the row and the sum of
// their sizes is s, the freedom is: cols-s-(k-1).
// The freedom of each column is defined similarly.

xfreedomv   // Freedom values for each row
yfreedomv   // Freedom values for each column

change      // =TRUE if something changed in boardv

count       // The count of solutions found so far.

tracing     // Controls tracing output
debug       // Controls debugging info
}

LET start() = VALOF
{ LET argv = VEC 50
  LET retcode = 0
  LET datafile = filename()

  IF rdargs("DATA,TO/K,D/N,TRACE/S", argv, 50)=0 DO
  {  writef("Bad arguments for GRIDLER*n")
     RESULTIS 20
  }

  IF argv!0 DO datafile := argv!0
  IF argv!1 DO
  { LET out = findoutput(argv!1)
    IF out=0 DO
    { writef("Cannot open file %s*n", argv!1)
      RESULTIS 20
    }
    selectoutput(out)
  }

  debug := 0
  IF argv!2 DO debug := !(argv!2)
  tracing := argv!3

  UNLESS initdata() DO 
  { writes("Cannot allocate workspace*n")
    retcode := 20
    GOTO ret
  }

  UNLESS readdata(datafile) DO
  { writes("Cannot read the data*n")
    retcode := 20
    GOTO ret
  }

  writef("Search for solutions file=%s on %nx%n board*n", datafile, cols, rows)

  boardvupb := rows*cols - 1
  boardv := newvec(boardvupb)
//abort(1004)

  // Initially all cell can be set White or Black
  FOR i = 0 TO boardvupb DO boardv!i := Wbit | Bbit

  count := 0
  findallsolutions()

  writef("%n solution%s found*n", count, count=1 -> "", "s")

ret:
  IF argv!1 DO endwrite()
  retspace()
  RESULTIS retcode
}

AND initdata() = VALOF
{ 
  rows, cols := 0, 0
  xupb, yupb := 0, 0
  spacev   := getvec(100000)
  spacet   := spacev+100000
  spacep   := spacev

  boardv     := 0
  possv      := 0
  placementv := 0

  UNLESS spacev & xdatav & ydatav & xfreedomv & yfreedomv RESULTIS FALSE

  xdatav   := newvec(100)  // Allow up to 100 rows and columns
  ydatav   := newvec(100)
  xfreedomv:= newvec(100)
  yfreedomv:= newvec(100)

  possv      := newvec(100) // To hold possible cell settings in a
                            // row or column.
  placementv := newvec(100) // To hold valid block placements is a
                            // row or column

  FOR i = 0 TO 50 DO
  { xdatav!i     := 0
    ydatav!i     := 0
    xfreedomv!i  := 0
    yfreedomv!i  := 0
    possv!i      := 0
    placementv!i := 0
  }

  RESULTIS TRUE
}

AND newvec(upb) = VALOF
{ LET res = spacep
  spacep := spacep+upb+1
  IF spacep<=spacet RESULTIS res
  RESULTIS 0
}

AND retspace() BE
{ IF spacev     DO freevec(spacev)
}

AND readdata(filename) = VALOF
{ LET stdin = input()
  LET data = findinput(filename)
  LET argv = VEC 200

  UNLESS data DO
  { writef("Unable to open file %s*n", filename)
    RESULTIS FALSE
  }

  selectinput(data)

  xupb, yupb := -1, -1

  { LET ch = rdch()
    WHILE ch='*s' | ch='*n' DO ch := rdch()
    IF ch=endstreamch BREAK
    unrdch()

    IF rdargs("ROW/S,COL/S,,,,,,,,,,,,,,,,,,,", argv, 200)=0 DO
    { writes("Bad data file, rdargs=>0*n")
      endread()
      selectinput(stdin)
      RESULTIS FALSE
    }

    UNLESS argv!0 | argv!1 LOOP

    IF argv!0 & argv!1 DO
    { writes("Bad data file*n")
      endread()
      selectinput(stdin)
      RESULTIS FALSE
    }

    IF argv!0 DO
    { yupb := yupb+1
      ydatav!yupb := spacep
    }

    IF argv!1 DO
    { xupb := xupb+1
      xdatav!xupb := spacep
    }

    FOR i = 2 TO 20 DO
    { UNLESS argv!i BREAK
      !spacep := str2numb(argv!i)    // Fill in the block size
      spacep := spacep + 1
    }
    !spacep := 0                     // Fill in the end marker
    spacep := spacep + 1
  } REPEAT

  rows, cols := yupb+1, xupb+1

  // Calculate the freedom values
  FOR x = 0 TO xupb DO xfreedomv!x := freedom(xdatav!x, yupb)
  FOR y = 0 TO yupb DO yfreedomv!y := freedom(ydatav!y, xupb)

  IF debug=3 DO
  { FOR x = 0 TO xupb DO writef("xfreedom!%i2 = %i2*n", x, xfreedomv!x)
    FOR y = 0 TO yupb DO writef("yfreedom!%i2 = %i2*n", y, yfreedomv!y)
  }

  endread()

  selectinput(stdin)

  // Safety check
  // The number of black cells in the rows must equal the number
  // in the columns
  UNLESS blackcells(xdatav, xupb)=blackcells(ydatav, yupb) DO
  { writes("Data sumcheck failure*n")
    writef("X black cells = %n*n", blackcells(xdatav,xupb))
    writef("Y black cells = %n*n", blackcells(ydatav,yupb))
    RESULTIS FALSE
  }

  RESULTIS TRUE
}

AND blackcells(v, upb) = VALOF
{ LET res = 0
  FOR i = 0 TO upb DO
  { LET p = v!i  // A vector os block sizes
    WHILE !p DO { res := res+!p; p := p+1 }
  }
  RESULTIS res
}

AND freedom(p, upb) = VALOF
{ // The freedom value of a row is the number of cells between the last cell
  // of the last block and the end of the row when the blocks are packed
  // to the left as closely as they can, ie with just one white cell
  // separating each block. If there are k blocks is a row and the sum of
  // their sizes is s, the freedom of that row is cols-s-(k-1).
  // The freedom of each column is defined similarly.

  UNLESS !p RESULTIS upb+1
  upb := upb - !p            // Subtract the size of the first block

  { p := p+1                 // Look for the next block
    UNLESS !p RESULTIS upb+1 // End of list reached
    upb := upb - !p - 1      // Subtract the block size and 1 for the separator
  } REPEAT
}

AND findallsolutions() BE
{ LET pivot = -1 // For first cell that can be Black or White

  UNLESS solve() RETURN // no solutions can be found from here

  FOR i = 0 TO boardvupb IF boardv!i = (Wbit|Bbit) DO
  { pivot := i
    BREAK
  }

  IF pivot<0 DO
  { count := count+1
    writef("*nSolution: %n*n", count)
    prboard()
    newline()
    RETURN
  }
 
  { LET v = getvec(boardvupb)
    UNLESS v DO
    { writef("No space left*n")
      RETURN
    }
    FOR i = 0 TO boardvupb DO v!i := boardv!i
    boardv!pivot := Wbit
    IF tracing DO
    { writef("Recurse with pivot cell %n set to White*n", pivot)
      prboard()
      abort(1000)
    }
    findallsolutions()

    // Restore saved board
    FOR i = 0 TO boardvupb DO boardv!i := v!i
    boardv!pivot := Bbit
    IF tracing DO
    { writef("Recurse with pivot cell %n set to Black*n", pivot)
      prboard()
      abort(1000)
    }
    freevec(v)
  }
} REPEAT   // Tail recursive call

// solve returns FALSE is no solution are possible from the current state.
AND solve() = VALOF
{
  { // Repeatedly process every row and column so long as progress is
    // being made.
    change := FALSE
    //writef("calling dorows*n")
    UNLESS dorows() RESULTIS FALSE
    //IF tracing DO prboard()
    //writef("calling docols*n")
    UNLESS docols() RESULTIS FALSE
    IF tracing DO
    { prboard()
      abort(1000)
    }
//writef("solve: change=%n*n", change)
  } REPEATWHILE change

  // No more progress can be made
  RESULTIS TRUE
}

// dorows returns FALSE if no solution possible from current state
AND dorows() = VALOF
{ sep := 1                  // set=1 for all rows

  FOR y = 0 TO yupb DO
  { LET p    = ydatav!y     // The vector of block sizes
    LET free = yfreedomv!y  // The freedom value for this row

    //writef("dorows: y=%n blocks: ", y)
    //FOR i = 0 TO 50 DO
    //{ LET size = p!i
    //  UNLESS size BREAK
    //  writef(" %n", size)
    //}
    //newline()

    // Initialise possv and placementv
    FOR i = 0 TO xupb DO possv!i, placementv!i := 0, 0
  
    linev := boardv + y*cols // First cell of row
    findallplacements(linev, 0, free, p)

    //FOR i = 0 TO xupb DO writef("%n", possv!i)
    //newline()

    // AND together values in possv with values in boardv
//writef("*nrow %i2: possible settings: ", y)
    FOR i = 0 TO xupb DO
    { LET prev = !linev
      LET bits = possv!i & prev
//writef(" %n->%n", prev, bits)
//UNLESS bits DO newline()
      !linev := bits
      change := change | (prev~=bits)
      UNLESS bits RESULTIS FALSE // No solution possible from here
      linev := linev+1
    }
//writef(" change=%n*n", change)

//abort(1002)
//prboard()
//abort(1002)
  }


  RESULTIS TRUE
}

// docols returns FALSE if no solution possible from current state
AND docols() = VALOF
{ sep := cols                  // sep=cols for all columns

  FOR x = 0 TO xupb DO
  { LET p    = xdatav!x     // The vector of block sizes
    LET free = xfreedomv!x  // The freedom value for this column

//    writef("docols: x=%n blocks: ", x)
//    FOR i = 0 TO 50 DO
//    { LET size = p!i
//      UNLESS size BREAK
//      writef(" %n", size)
//    }
//    newline()

    // Initialise possv and placementv
    FOR i = 0 TO yupb DO possv!i, placementv!i := 0, 0
  
    linev := boardv + x   // First cell of column
    findallplacements(linev, 0, free, p)

//    FOR i = 0 TO yupb DO writef("%n", possv!i)
//    newline()

    // AND together values in possv with values in boardv
//writef("*ncol %i2: ", x)
    FOR i = 0 TO yupb DO
    { LET prev = !linev
      LET bits = possv!i & prev
//writef("%n", bits)
//UNLESS bits DO newline()
      !linev := bits
      change := change | (prev~=bits)
      UNLESS bits RESULTIS FALSE // No solution possible from here
      linev := linev+cols
    }
//newline()
//prboard()
//abort(1002)
  }

  RESULTIS TRUE
}

AND findallplacements(pos, i, freedom, p) BE
{ // pos     points to a cell in boardv corresponding to the
  //         current position in the current line.
  // i       is the subscript of placementsv corresponding to the
  //         current cell.
  // freedom is the remaining freedom value
  // p       points to the remaining block sizes

  // The globals
  // linev   points to the first cell in the current row or column
  // sep     =1,    if processing a row
  //         =cols, if processing a column

  // When a valid placement is found, every element of placementsv
  // will be either Bbit or Wbit and this vector will be ORed into
  // possv

  LET size = !p // Get next block size
//writef("findallplacements: pos=%n, sep=%n i=%n, freedom=%n,  next size=%n*n",
//        pos, sep, i, freedom, size)
//abort(1001)
  TEST size
  THEN { // We have at least one block to place
         IF i DO
         { // It is not the first block of a row or column
           // so we must fill in a white separator cell.
           // Return if the next cell cannot be white.
//writef("findallplacements: trying to place a white separator at %n*n", i)
           IF (!pos & Wbit)=0 DO
           { //writef("Failed*n")
             RETURN
           }
           placementv!i := Wbit
//writef("findallplacements: placed a white separator at %n*n", i)
           pos, i := pos+sep, i+1
         }

         FOR f = 0 TO freedom DO
         { LET j = i
           LET p0 = pos // Current position
//writef("findallplacements: f=%n i=%n pos=%n*n", f, i, pos)
           // Try to insert n freedom white cells here.
//writef("findallplacements: trying to place %n white freedom cell%-%ps at %n*n",
//              f, j)
           FOR k = 1 TO f DO
           {
//writef("findallplacements: trying to a place white freedom cell at %n*n", j)
             // Return if next cell cannot be white
             IF (!p0 & Wbit)=0 DO
             { //writef("Failed*n")
               RETURN
             }
             placementv!j := Wbit
//writef("findallplacements: placed a white freedom cell at %n*n", j)
             p0, j := p0+sep, j+1
           }
//writef("findallplacements: trying to place a block size=%n at %n*n", size, j)
           // Try to place the block
           FOR s = 1 TO size DO
           { // Return if next cell cannot be black
//writef("findallplacements: trying to a place black cell at %n*n", j)
             IF (!p0 & Bbit)=0 DO
             { //writef("Failed*n")
               GOTO again
             }
             placementv!j := Bbit
//writef("findallplacements: placed a black cell at %n*n", j)
             p0, j := p0+sep, j+1
           }

           // The block has be placed successfully
           // so go on searching from here with reduced freedom
           // and one fewer block sizes.
//writef("findallplacements: calling  findallplacements(%n,%n,%n,%n)*n",
//                             p0, j, freedom-f, p+1)
           findallplacements(p0, j, freedom-f, p+1)
//writef("findallplacements: returned findallplacements(%n,%n,%n,%n)*n",
//                             p0, j, freedom-f, p+1)
again:
         }
       }
  ELSE { // No more blocks, so fill in remaining white cell if possible
//writef("findallplacements: trying to place %n white freedom cell%-%ps at %n*n",
//              freedom, i)
         WHILE freedom DO
         { // Return if next cell cannot be white
//writef("findallplacements: trying to place a white freedom cell at %n*n", i)
           IF (!pos & Wbit)=0 DO
           { //writef("Failed*n")
             RETURN
           }
           placementv!i := Wbit
//writef("findallplacements: placed a white freedom cell at %n*n", i)
           pos, i := pos+sep, i+1
           freedom := freedom-1
         }

         // The remaining white cells were successfully placed,
         // so a valid placement has been found.
         // OR the placement bits into possv.
//writef("findallplacements: found a valid placement*n", i)
         FOR j = i-1 TO 0 BY -1 DO possv!j := possv!j | placementv!j 

         IF tracing DO
         { LET upb = sep=1 -> xupb, yupb
           FOR i = 0 TO upb TEST placementv!i=Wbit
                            THEN writef(".")
                            ELSE writef("X")
           newline()
//           FOR i = 0 TO upb DO writef("%n", possv!i)
//           newline()
         }
//abort(1000)
       }

}

AND prboard() BE
{ FOR i = 0 TO boardvupb DO
  { LET bits = boardv!i
    IF i REM cols = 0 DO sawritef("*n%i2: ", i/cols)
    SWITCHON bits INTO
    { DEFAULT:        sawritef(" ?"); ENDCASE
      CASE 0:         sawritef(" #"); ENDCASE
      CASE Wbit:      sawritef(" ."); ENDCASE
      CASE Bbit:      sawritef(" X"); ENDCASE
      CASE Wbit|Bbit: sawritef(" _"); ENDCASE
    }
  }
}

