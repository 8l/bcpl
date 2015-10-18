/*

This program attempts to obtain the best wining strategy for the pig
dice game on the assumption that it depends only on the current turn
score, the own score and the opponent score.


Implemented by Martin Richards (c) March 2014

All the scores are positive and less than 100 so there are one million
possible game states corresponding to the grid points in a 100x100x100
cube. The optimum strategy can be represented by setting flags for
every game state indicating whether to play the die or hold. The grid
points of this cube is represented by a million word array called
cube. The game state opponentscore, ownscore and turnscore is held in
cube!i where

       i = opponentscore*100000+ownscore*100+turnscore

The element cube!i holds (prob<<1 | flag), where prob is the
probability of winning and flag=1 if the best strategy is to hold.
The probabilities are represented using scaled numbers with 8 decimal
digits after the decimal point.

Initially all elements of cube hold a probability of 0.5 and a flag of
zero.  The program then repeated recomputes all the elements of the
cube until no further improvement is possible.

At the end the program outputs the file pigcube.txt giving the
pobability and flag of every element of the cube, and the file
pigstrat.txt giving the turn score on which the hold for each opponent
and own score. If the command argument -d is not given, the format of
this file is suitable to be read in by the program pig.b, allowing it
to play the game with the optimum strategy.

*/

GET "libhdr"

GLOBAL {
  stdout:ug
  tracing
  One           // Normally 1_000_000_00
  lim           // Normally = 100 the goal of the game
  limsq
  cubeupb
  cube
  maxchange
  newchange
  prevmaxchange
  playcount
  playchanges
}

LET start() = VALOF
{ LET argv = VEC 50
  LET itercount = 0

  stdout := output()

  UNLESS rdargs("lim/n,-t/s", argv, 50) DO
  { writef("Bad arguments for pigstrategy*n")
    RESULTIS 0
  }

  lim := 100
  IF argv!0 DO lim := !(argv!0)   // lim/n
  tracing := argv!1               // -t/s

  One := 1_000_000_00

  limsq   := lim*lim
  cubeupb := lim*lim*lim - 1
  cube    := getvec(cubeupb)

  UNLESS cube DO
  { writef("More space needed*n")
    RESULTIS 0
  }

  FOR i = 0 TO cubeupb DO cube!i := One // = 0.5<<1 | 0

  maxchange := One+1

  { prevmaxchange := maxchange
    maxchange, playcount, playchanges := 0, 0, 0

    FOR op = lim-1 TO 0 BY -1 DO
      FOR my = lim-1 TO 0 BY -1 DO
        FOR ts = lim-1 TO 0 BY -1 DO p(op, my, ts)

    itercount := itercount+1
    writef("%i3: maxchange = %10.8d  playcount=%n playchanges=%n*n",
             itercount, maxchange, playcount, playchanges)
  } REPEATWHILE tracing | maxchange < prevmaxchange

  prstrategy()
  newline()
  IF cube DO freevec(cube)
  RESULTIS 0
}

AND p(op, my, ts) BE
{ LET i = op*limsq + my*lim + ts
  LET a2, a3, a4, a5, a6 = 0,0,0,0,0
  LET b0 = 0
  LET diff = 0
  LET playprob, holdprob = ?, ?

  //IF op=36 & my=31 & ts=13 DO
  //{ pr(op,my,ts)
  //  newline()
  //}

  IF ts>=lim RETURN // The game has been won

  IF ts+my >= lim DO
  { // The game is won, so hold gives winning probability of 1.0.
    diff := One - (cube!i>>1)
    newchange := ABS diff
    IF (cube!i & 1) = 0 DO playchanges := playchanges+1
    cube!i := One<<1 | 1  // Prob 1.0  flag:Hold
    IF tracing & diff DO prdiff(op, my, ts, diff)
    IF newchange > maxchange DO maxchange := newchange
    RETURN
  }

  IF ts DO
  { // The player has a positive turn score

    // Calculate the probability of winning if holding now.
    b0 := cubeval(my+ts, op, 0)
    holdprob := One - b0

    // Calculate the probability of winning if throwing the die again
    b0 := cubeval(my, op, 0)
    a2 := cubeval(op, my, ts+2)
    a3 := cubeval(op, my, ts+3)
    a4 := cubeval(op, my, ts+4)
    a5 := cubeval(op, my, ts+5)
    a6 := cubeval(op, my, ts+6)
    playprob := ( One - b0 + a2 + a3 + a4 + a5 + a6 + 3 ) / 6
//writef("%i3 %i3 %i3: *n", op, my, ts)
//IF op=25 & my=21 & ts=10 DO abort(1111)
    TEST holdprob >= playprob
    THEN { // It is better to hold
           diff := holdprob - (cube!i>>1)
           newchange := ABS diff
           IF (cube!i & 1) = 0 DO playchanges := playchanges+1
           cube!i := holdprob<<1 | 1  // holdprob  flag:Hold
           IF op=25 & my=21 & ts=10 & prevmaxchange<5 | tracing & diff DO
           { pr(my+ts, op, 0); newline()
             pr(my, op, 0)
             pr(op, my, ts+2)
             pr(op, my, ts+3); newline()
             pr(op, my, ts+4)
             pr(op, my, ts+5)
             pr(op, my, ts+6); newline()
             writef("(%i2 %i2 %i2):%10.8dH %10.8dP => ",
                     op, my, ts, holdprob, playprob)
             prdiff(op, my, op, diff)
 //abort(2222)
           }
           IF newchange > maxchange DO maxchange := newchange
           RETURN
         }
    ELSE { // It is better the play the die
           diff := playprob - (cube!i>>1)
           newchange := ABS diff
           IF (cube!i & 1) = 1 DO playchanges := playchanges+1
           playcount := playcount+1
           cube!i := playprob<<1  // playprob  flag:Play
           IF op=25 & my=21 & ts=10 & prevmaxchange<5 | tracing & diff DO
           { pr(my+ts, op, 0); newline()
             pr(my, op, 0)
             pr(op, my, ts+2)
             pr(op, my, ts+3); newline()
             pr(op, my, ts+4)
             pr(op, my, ts+5)
             pr(op, my, ts+6); newline()
             writef("(%i2 %i2 %i2):%10.8dH %10.8dP => ",
                     op, my, ts, holdprob, playprob)
             prdiff(op, my, ts, diff)
// abort(3333)
           }
           IF newchange > maxchange DO maxchange := newchange
           RETURN
         }
  }

  // The current turn score is zero, so throw the die

  b0 := cubeval(my, op, 0)
  a2 := cubeval(op, my, 2)
  a3 := cubeval(op, my, 3)
  a4 := cubeval(op, my, 4)
  a5 := cubeval(op, my, 5)
  a6 := cubeval(op, my, 6)

  playprob := ( One - b0 + a2 + a3 + a4 + a5 + a6 + 3 ) / 6

  diff := playprob - (cube!i>>1)
  newchange := ABS diff

  IF tracing & diff DO
  { pr(my, op, 0)  // Output value before cube!i is updated.
                   // Done now because my and op may be equal.
    newline()
  }

  IF (cube!i & 1) = 1 DO playchanges := playchanges+1
  playcount := playcount+1
  cube!i := playprob<<1  // playprob  flag:Play
  IF op=25 & my=21 & ts=10 & prevmaxchange<5 | tracing & diff DO
  { pr(op, my, 2)
    pr(op, my, 3); newline()
    pr(op, my, 4)
    pr(op, my, 5)
    pr(op, my, 6); newline()
    prdiff(op, my, 0, diff) // Output the updated value
//abort(4444)
  }
  IF newchange > maxchange DO maxchange := newchange
  RETURN
}

AND cubeval(op, my, ts) = VALOF
{ IF ts+my >= lim RESULTIS One
  RESULTIS cube!(op*limsq+my*lim+ts) >> 1
}

AND prset(i) BE
{ LET w = cube!i
  LET prob = w>>1
  LET act = (w&1)=0 -> "play", "hold"
  LET op = (i / limsq) MOD lim
  LET my = (i / lim  ) MOD lim
  LET ts =  i          MOD lim
  writef("(%i2 %i2 %i2): set %s %10.8d  maxchange = %10.8d*n",
          op, my, ts,
          act, prob, maxchange)
}

AND prstrategy() BE
{ LET outstream = findoutput("pigcube.txt")
  UNLESS outstream DO
  { writef("Trouble with file: pigcube.txt*n")
    RETURN
  }

  selectoutput(outstream)

  // Output the strategy
  FOR op = 0 TO lim-1 DO
    FOR my = 0 TO lim-1 DO
    { FOR ts = 0 TO lim-1 DO
      { LET i = op*limsq + my*lim + ts
        LET w = cube!i
        LET prob = w>>1
        LET letter = (w & 1) = 0 -> 'P', 'H'
        IF ts MOD 5 = 0 DO
          writef("*n(%i2 %i2 %i2): ", op, my, ts)
        writef(" %10.8d%c", prob, letter)
      }
      newline()
    }
  endstream(outstream)

  outstream := findoutput("pigstrat.txt")
  UNLESS outstream DO
  { writef("Trouble with file: pigstrat.txt*n")
    RETURN
  }

  selectoutput(outstream)

//abort(6666)
  FOR op = 0 TO lim-1 DO
  { sawritef("*nOpponent score %i2", op)
    FOR my = 0 TO lim-1 DO
    { LET holdval = lim
      FOR ts = 0 TO lim-1 DO
      { LET i = op*limsq + my*lim + ts
          IF (cube!i & 1) > 0 & holdval=lim DO holdval := ts
      }
      IF my MOD 10 = 0 DO
      { newline()
        writef("(%i2 %i2):  ", op, my)
      }
      writef(" %i3", holdval)
    }
    newline()
  }
  newline()
  endstream(outstream)
  selectoutput(stdout)
}

AND pr(op, my, ts) BE
{ LET i = op*limsq + my*lim + ts
  LET w = ts>=lim -> One<<1 | 1, cube!i
  LET prob = w>>1
  LET letter = (w&1)=0 -> 'P', 'H'
  TEST ts>=lim
  THEN writef("(%i2 %i2 XX):%10.8d%c ",  op, my,     prob, letter)
  ELSE writef("(%i2 %i2 %i2):%10.8d%c ", op, my, ts, prob, letter)
}

AND prdiff(op, my, ts, diff) BE //IF diff DO
{ pr(op, my, ts)
  writef("diff=%10.8d*n", diff)
}
