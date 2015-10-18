/*
This is an implementation of the pig dice game.


Implemented in BCPL by Martin Richards (c) March 2014

This is a two player game that uses a six sided die. Each player has a
bank that accumulates the score. The players take turns with the die
alternately. The first player repeatedly throws the die until either a
one is thown or the player decides to terminate his turn by saying
"hold". If a one is thrown the player's score in left unchanged, but
if the player holds the sum of the numbers thrown during the term is
added to his score. In either case the die is given to the other
player. The first player to reach a score of 100 wins.

The optimum choice of whether to roll the die or hold depends on the
current scores of each player and the score accumulated in the current
turn. It turns out to be counter intuitive and complicated.

This program takes several numeric arguments: a1, b1, c1, a2, b2 and
c2. If the a1 is zero, player 1 is a user controlled by input from the
keyboard. When it is player 1's turn, pressing P causes the die to be
thown and pressing H terminates the turn. If either a one is thrown or
H is pressed the die is passes to the other player.  If a1 is non
zero, player 1 is played by the computer using a strategy specified by
a1, b1 and c1.  If a1 is negative, player 1 is played by the computer
using the optimum strategy using data in the file pigstrat.txt, but if
a1 is greater than zero the computer uses a playing strategy defined
by a1, b1 and c1. You can think of the game state as a point
(my,op,ts) in a 3D cube where my and op are player 1 and player 2's
scores and ts is player 1's current turn score. If we assume that the
ts axis is vertical, the coordinates (my,op) identify a point on a
horizontal square. We can think of this square as the floor of a
shed. The strategy is based on a sloping plane that can be thought of
as the shed's roof. If ts is less than the height of the roof at floor
position (my,op) the strategy is to throw, otherwise player 1 should
hold. The orientation of the roof is defined by its height a1 at the
origin (0,0), b1 at position (99,0) and c1 at position (0,99). So if
ts<a+(b-a)*my/99+(c-a)*op/99, the strategy is to throw the die.  The
default settings for b1 and c1 are both set to a1. This, of course,
represents a horizontal roof of height a1.

Player 2's strategy is specified similarly using arguments a2,
b2 and c2. It is thus possible to cause the computer to
play itself with possibly different strategies.  A new game can be
started by pressing S, and the program can be terminated by pressing
Q. After each game, the tally of wins by each player is output. This
is useful when comparing the effectiveness of different playing
strategies.

*/

GET "libhdr"

GLOBAL {
  stdin:ug
  stdout
  ch
  a1; b1; c1 // Player1's strategy parameters
  a2; b2; c2 // Player2's strategy parameters
  score1     // Player 1's score
  score2     // Player 2's score
  player     // =0 if game ended,
             // =1 if it is player 1's turn,
             // =2 if it is player 2's turn.
  wins1      // Count of how often player1 has won
  wins2      // Count of how often player2 has won
  quitting   // =TRUE when Q is pressed
  newgameP   // The longjump arguments to
  newgameL   // start a new game
  strategybytes
  strategybytesupb
  strategystream
}

LET strategyrdch() = VALOF
{ LET ch = rdch()
  UNLESS ch='(' RESULTIS ch
  // Ignore text enclosed within parentheses
  { ch := rdch()
    IF ch=endstreamch RESULTIS endstreamch
  } REPEATUNTIL ch=')'
} REPEAT

LET start() = VALOF
{ LET days, msecs, filler = 0, 0, 0
  LET argv = VEC 50

  UNLESS rdargs("a1/n,b1/n,c1/n,a2/n,b2/n,c2/n",
                argv, 50) DO
  { writef("Bad argument(s) for pig*n")
    RESULTIS 0
  }

  a1, b1, c1 :=  0,  0,  0 // Player1's strategy
  a2, b2, c2 := 21, 11, 31 // Player2's strategy
  //a2, b2, c2 := -1,  0,  0 // Player2's strategy (optimum)
  wins1, wins2 := 0, 0
  quitting := FALSE

  IF argv!0 DO
  { a1   := !(argv!0)
    b1, c1 := a1, a1
  }
  IF argv!1 DO b1   := !(argv!1)
  IF argv!2 DO c1   := !(argv!2)
  IF argv!3 DO
  { a2   := !(argv!3)
    b2, c2 := a2, a2
  }
  IF argv!4 DO b2   := !(argv!4)
  IF argv!5 DO c2   := !(argv!5)

  newgameP, newgameL := level(), newgame
  datstamp(@days)
  setseed(msecs)
  strategybytes := 0
  strategybytesupb := 100*100-1
  strategystream := 0

  IF a1<0 | a2<0 DO
  { // Load the optimum strategy data from file pigstrat.txt
    strategybytes := getvec(strategybytesupb/bytesperword)
    UNLESS strategybytes DO
    { writef("Unable to allocated strategybytes*n")
      GOTO fin
    }
    strategystream := findinput("pigstrat.txt")
    UNLESS strategystream DO
    { writef("Unable to open pigstrat.txt*n")
      GOTO fin
    }

    selectinput(strategystream)

sawritef("pig reading pigstrat.txt*n")

    { LET i, ch = 0, 0

      { LET x = 0

        { ch := strategyrdch()
        } REPEATUNTIL '0'<=ch<='9' | ch=endstreamch
        IF ch=endstreamch BREAK

        WHILE '0'<=ch<='9' DO
        { x :=10*x + ch - '0'
          ch := strategyrdch()
        }
        IF i <= strategybytesupb DO strategybytes%i := x
        i := i+1
      } REPEAT	

      UNLESS i = 100*100 DO
      { writef("pigstrat.txt contains %n numbers, should be 10000*n", i)
        GOTO fin
      }
    }

    endstream(strategystream)
    strategystream := 0

    IF FALSE DO
    FOR op = 0 TO 99 DO
    { FOR my = 0 TO 99 DO
      { IF my MOD 10 = 0 DO writef("*n(%i2,%i2): ", op, my)
        writef(" %i3", strategybytes%(op*100 + my))
      }
      newline()
      abort(1000)
    }
  }


newgame:
  score1, score2 := 0, 0

  writef("*nNew Game*n")

  UNTIL quitting DO
  { play(1, a1, b1, c1)
    IF quitting BREAK
    play(2, a2, b2, c2)

    IF score1>=100 DO
    { wins1 := wins1 + 1
      writef("*nPlayer 1 wins*n")
    }
    IF score2>=100 DO
    { wins2 := wins2 + 1
      writef("*nPlayer 2 wins*n")
    }
    IF score1>=100 | score2>=100 DO
    { writef("Player1 scored %i3 games won %i3*n", score1, wins1)
      writef("Player2 scored %i3 games won %i3*n", score2, wins2)

      { writef("*nPress S or Q ")
        deplete(cos)
        ch := rch()
        IF ch='Q' | ch=endstreamch DO
        { newline()
          RESULTIS 0
        }
        IF ch='S' GOTO newgame  
      } REPEAT
    }
  }

fin:
  IF strategybytes DO freevec(strategybytes)
  IF strategystream DO endstream(strategystream)
  RESULTIS 0
}

AND rch() = VALOF
{ LET c = capitalch(sardch())
  writes("*b *b")
  deplete(cos)
  RESULTIS c
}

AND play(player, a, b, c) BE UNLESS score1>=100 | score2>=100 DO
{ LET turnscore = 0
  LET done   = FALSE
  LET throws = 0
  LET turnv  = VEC 100

  //UNLESS a DO writef("Press P, H or S*n")

  { LET score    = score1
    LET opponent = score2

    IF player=2 DO score, opponent := score2, score1

    writef("*cPlayer%n: %i3 opponent %i3 turn %i3=",
            player, score, opponent, turnscore)
    IF throws>0 DO writef("%n", turnv!0)
    FOR i = 1 TO throws-1 DO writef("+%n", turnv!i)
    deplete(cos)

    IF done DO
    { newline()
      TEST player=1
      THEN score1 := score1 + turnscore
      ELSE score2 := score2 + turnscore
      RETURN
    }

    IF strategy(turnscore, score, opponent, a, b, c) DO 
    { // Throw
      LET n = randno(6)
      turnv!throws := n
      throws := throws+1
      turnscore := turnscore+n
      IF n=1 DO
      { turnscore := 0
        done := TRUE
      }
      UNLESS score+turnscore >= 100 LOOP
    }
    // Hold
    done := TRUE
  } REPEAT
}

AND strategy(turnscore, myscore, opscore, a, b, c) = VALOF
{ // Return TRUE to throw die
  // Return FALSE to hold

  UNLESS a RESULTIS userplay()

  UNLESS turnscore RESULTIS TRUE // m/c always throws first time

  // If a<0 use the optimum strategy
  IF a<0 RESULTIS turnscore < strategybytes%(opscore*100+myscore)

  // If a>0 use strategy based on a, b and c
  //writef("strategy: turnscore=%n myscore=%n opscore=%n a=%n b=%n c=%n*n)",
  //        turnscore, myscore, opscore, a, b, c)
  //writef("strategy: a + (myscore**(b-a) + opscore**(c-a))/99 = %n*n",
  //        a + (myscore*(b-a) + opscore*(c-a))/99)
//abort(1000)
  RESULTIS turnscore < a + (myscore*(b-a) + opscore*(c-a))/99
}

AND userplay() = VALOF
{ ch := rch()
  SWITCHON ch INTO
  { DEFAULT: LOOP
    CASE 'P': RESULTIS TRUE
    CASE endstreamch:
    CASE 'Q': quitting := TRUE
    CASE 'H': RESULTIS FALSE
    CASE 'S': longjump(newgameP, newgameL)
  }
} REPEAT

