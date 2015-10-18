// This is another demonstration program to solve a backtracking
// problem using recursion and bit patterns. 
// See queens.b and penta3.b

// Copyright: Martin Richards,  January 1997

GET "libhdr"

GLOBAL {
xupb     : 200
yupb     : 201
spacev   : 202
spacet   : 203
spacep   : 204
boardv   : 205
knownv   : 206
xdatav   : 207
ydatav   : 208
xfreedomv: 209
yfreedomv: 210
change   : 211
tracing  : 212
rowbits  : 213
known    : 214
orsets   : 215
andsets  : 216
count    : 217
debug    : 218
}

LET start() = VALOF
{ LET argv = VEC 50
  LET retcode = 0
  LET datafile = "nonograms/n220"

  IF rdargs("DATA,TO/K,TRACE/S,D1/S,D2/S", argv, 50)=0 DO
  {  writef("Bad arguments for NONOGRAM*n")
     RESULTIS 20
  }

  UNLESS argv!0=0 DO datafile := argv!0
  UNLESS argv!1=0 DO
  { LET out = findoutput(argv!1)
    IF out=0 DO
    { writef("Cannot open file %s*n", argv!1)
      RESULTIS 20
    }
    selectoutput(out)
  }

  tracing := argv!2
  debug := 0
  IF argv!3 DO debug := debug+1
  IF argv!4 DO debug := debug+2

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

  count := 0
  allsolutions()

  writef("%n solution%s found*n", count, count=1 -> "", "s")

ret:
  UNLESS argv!1=0 DO endwrite()
  retspace()
  RESULTIS retcode
}

AND initdata() = VALOF
{ 
  xupb     := 0
  yupb     := 0
  spacev   := getvec(100000)
  spacet   := spacev+100000
  spacep   := spacev
  boardv   := getvec(31)
  knownv   := getvec(31)
  xdatav   := getvec(31)
  ydatav   := getvec(31)
  xfreedomv:= getvec(31)
  yfreedomv:= getvec(31)

  IF spacev=0 | boardv=0 | knownv=0 | xdatav=0 | ydatav=0 |
     xfreedomv=0 | yfreedomv=0 RESULTIS FALSE

  FOR i = 0 TO 31 DO
  { boardv!i    := 0
    knownv!i    := 0
    xdatav!i    := 0
    ydatav!i    := 0
    xfreedomv!i := 0
    yfreedomv!i := 0
  }

  RESULTIS TRUE
}

AND retspace() BE
{ UNLESS spacev=0    DO freevec(spacev)
  UNLESS boardv=0    DO freevec(boardv)
  UNLESS knownv=0    DO freevec(knownv)
  UNLESS xdatav=0    DO freevec(xdatav)
  UNLESS ydatav=0    DO freevec(ydatav)
  UNLESS xfreedomv=0 DO freevec(xfreedomv)
  UNLESS yfreedomv=0 DO freevec(yfreedomv)
}

AND readdata(filename) = VALOF
{ LET stdin = input()
  LET data = findinput(filename)
  LET argv = VEC 200

  IF data=0 DO
  { writef("Unable to open file %s*b", filename)
    RESULTIS FALSE
  }

  selectinput(data)

  xupb, yupb := -1, -1

  { LET ch = rdch()
    WHILE ch='*s' | ch='*n' DO ch := rdch()
    IF ch=endstreamch BREAK
    unrdch()

    IF rdargs("ROW/S,COL/S,,,,,,,,,,,,,,,,,,,", argv, 200)=0 DO
    { writes("Bad data file*n")
      endread()
      selectinput(stdin)
      RESULTIS FALSE
    }

    IF argv!0 EQV argv!1 DO
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
    { IF argv!i = 0 BREAK
      !spacep := str2numb(argv!i)
      spacep := spacep + 1
    }
    !spacep := 0
    spacep := spacep + 1


  } REPEAT

  FOR x = 0 TO xupb DO xfreedomv!x := freedom(xdatav!x, yupb)
  FOR y = 0 TO yupb DO yfreedomv!y := freedom(ydatav!y, xupb)

  IF debug=3 DO
  { FOR x = 0 TO xupb DO writef("xfreedom!%i2 = %i2*n", x, xfreedomv!x)
    FOR y = 0 TO yupb DO writef("yfreedom!%i2 = %i2*n", y, yfreedomv!y)
  }

  endread()

  selectinput(stdin)

  UNLESS blobs(xdatav, xupb)=blobs(ydatav, yupb) DO
  { writes("Data sumcheck failure*n")
    writef("X blobs = %n*n", blobs(xdatav,xupb))
    writef("Y blobs = %n*n", blobs(ydatav,yupb))
    RESULTIS FALSE
  }

  RESULTIS TRUE
}

AND blobs(v, upb) = VALOF
{ LET res = 0
  FOR i = 0 TO upb DO
  { LET p = v!i
    UNTIL !p=0 DO { res := res+!p; p := p+1 }
  }
  RESULTIS res
}

AND freedom(p, upb) = VALOF
{ IF !p=0 RESULTIS 0
  upb := upb - !p
  { p := p+1
    IF !p=0 RESULTIS upb+1
    upb := upb - !p - 1
  } REPEAT
}

AND allsolutions() BE
{ UNLESS solve() RETURN // no solutions can be found from here

  { LET b = VEC 31
    LET k = VEC 31
    LET pos, bit = 0, 0

    // save current state
    FOR i = 0 TO 31 DO b!i, k!i := boardv!i, knownv!i
    FOR i = 0 TO yupb DO
    { LET bits = NOT knownv!i
      UNLESS bits=0 DO
      { pos, bit := i, bits & -bits
        BREAK
      }  
    }

    // test to see if a solution has been found
    IF bit=0 DO
    { count := count + 1
      writef("*nSolution %n*n*n", count)
      prboard()
      RETURN
    }

    // there may be a solution from here
    // try both setting of the unresolved square 
    // given by pos and bit
    knownv!pos := knownv!pos | bit

    IF debug=1 DO
    { writes("Try setting a square to blank*n")
      prboard()
    }

    allsolutions()
    FOR i = 0 TO 31 DO boardv!i, knownv!i := b!i, k!i
    knownv!pos := knownv!pos | bit
    boardv!pos := boardv!pos | bit

    IF debug=1 DO
    { writes("Try setting a square to unblank*n")
      prboard()
    }
  }
} REPEAT

// solve returns FALSE is no solution possible from here
AND solve() = VALOF
{ change := TRUE

  WHILE change DO
  { change := FALSE
    UNLESS dorows() RESULTIS FALSE
    IF tracing DO prboard()
    flip()
    UNLESS dorows() DO { flip(); RESULTIS FALSE }
    flip()
    IF tracing DO prboard()
  }

  RESULTIS TRUE
}

// dorows returns FALSE if no solution possible from current state
AND dorows() = VALOF
{ FOR y = 0 TO yupb DO
  { LET p = ydatav!y
    LET q = p
    LET free = yfreedomv!y
    //writef("y = %i2 freedom = %i2 ", y, free)
    //UNTIL !q=0 DO { writef("%i2 ", !q); q := q+1 }
    //newline()
    orsets  := 0
    andsets := #xFFFFFFFF
    rowbits, known := boardv!y, knownv!y
    try(p, 0, 0, free)

    UNLESS (andsets & orsets) = andsets RESULTIS FALSE

    rowbits := rowbits | andsets
    known := known | NOT orsets | andsets
    UNLESS known=knownv!y DO
    { boardv!y, knownv!y := rowbits, known
      change := TRUE
      IF debug=2 DO { writes("Board changed*n"); prboard() }
    }
  }
  RESULTIS TRUE
}

AND try(p, set, pos, free) BE
{ LET size = !p
  LET piece = (1<<size) - 1

  IF size=0 DO // end of piece list
  { IF ok(set, xupb+1) DO
    { orsets  := orsets  | set
      andsets := andsets & set
      IF debug=2 DO
      { FOR x = 0 TO xupb DO
        { LET ch = (set>>x & 1)=0 -> '.', '**'
          writef(" %c", ch)
        }
        writes("  possible line*n")
      }
    }
    RETURN
  }

  FOR i = 0 TO free DO
  { LET nset = set | piece<<pos+i
    LET npos = pos+i+size+1
    IF ok(nset, npos) DO try(p+1, nset, npos, free-i)
  }
}

// ok returns TRUE if the given blob placement is
// compatible with the current known board settings
AND ok(set, npos) = VALOF
{ LET mask = known & ((1<<npos) - 1)
  RESULTIS ((set NEQV rowbits) & mask) = 0
} 

AND flip() BE
{ LET xd, yd = xdatav, ydatav
  LET xf, yf = xfreedomv, yfreedomv
  LET xu, yu = xupb, yupb
  xdatav, ydatav       := yd, xd
  xfreedomv, yfreedomv := yf, xf
  xupb, yupb           := yu, xu
  
  flipbits(boardv)
  flipbits(knownv)
}

// flipbits swaps bit (i,j) with bit (j,i) for
// all bits in a 32x32 bitmap. It does it in 5 stages
// by swapping square areas of sizes 16, 8, 4, 2 and
// finally 1.
AND flipbits(v) BE
{ FOR p = v TO v+0  BY 32 FOR q = p TO p+15 DO
  { LET a, b = q!0, q!16
    q!0  := a&#x0000FFFF | (b&#x0000FFFF)<<16
    q!16 := b&#xFFFF0000 | (a&#xFFFF0000)>>16
  }
  FOR p = v TO v+16 BY 16 FOR q = p TO p+7 DO
  { LET a, b = q!0, q!8
    q!0  := a&#x00FF00FF | (b&#x00FF00FF)<<8
    q!8  := b&#xFF00FF00 | (a&#xFF00FF00)>>8
  }
  FOR p = v TO v+24 BY 8 FOR q = p TO p+3 DO
  { LET a, b = q!0, q!4
    q!0  := a&#x0F0F0F0F | (b&#x0F0F0F0F)<<4
    q!4  := b&#xF0F0F0F0 | (a&#xF0F0F0F0)>>4
  }
  FOR p = v TO v+28 BY 4 FOR q = p TO p+1 DO
  { LET a, b = q!0, q!2
    q!0  := a&#x33333333 | (b&#x33333333)<<2
    q!2  := b&#xCCCCCCCC | (a&#xCCCCCCCC)>>2
  }
  FOR p = v TO v+30 BY 2 FOR q = p TO p+0 DO
  { LET a, b = q!0, q!1
    q!0 := a&#x55555555 | (b&#x55555555)<<1
    q!1 := b&#xAAAAAAAA | (a&#xAAAAAAAA)>>1
  }
}


AND prboard() BE
{ FOR y = 0 TO yupb DO
  { LET row, known = boardv!y, knownv!y
    FOR x = 0 TO xupb DO
      TEST (known>>x & 1)=0
      THEN writes(" ?")
      ELSE TEST (row>>x & 1)=0
           THEN writes(" .")
           ELSE writes(" M")
    newline()
  }
  newline()
}

