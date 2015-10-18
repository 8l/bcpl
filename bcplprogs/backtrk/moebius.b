/*
************ UNDER DEVELOPMENT *********************

This program is designed to explore games like Moebius and Mogul
mentioned on pages 479-480 in the chapter by R.K. Guy "Unsolved
problems in Cominatorial Games" which in the book "Games of No Chance"
ed. Nowakowski, CUP, 1996.

This program is implemented in BCPL by
Martin Richards (c) August 2000

The game Moebius starts is played on a row of 18 coins. A move turns 1
to 5 adjacent coins of which the right most must go from heads to
tails. The winner is the player who makes all coins tails.

This program computes which initial settings are forced wins for the
first player.

This game generalises to one with n coins in which up to c adjacent
coins can be turned. If we name such games (n,c), the game Moebius
is (18,5) and Mogul is (24,7). Both these apparently exhibit remarkable
patterns.

Implementation of Moebius

A setting of the row of coins is represented by a bit pattern (w)
of length 18 with ones representing heads. If w&bit is non zero
then successor state include w NEQV bit, w NEQV (bit*3),
w NEQV (bit*7), ..., w NEQV (bit*31).

The byte vector val (with 2**18 elements) describe the value of a
setting. val%w holds a 2-bit pattern xy.

x=1 if setting w is known to be a forced win for the first player.
y=1 if setting w is known that the second player can force a win
    whatever move the first player makes.

Initially, val%0=#b01 and val%w=#b00 for all w>0.

If w is a setting that has a move leading to a setting with value #b01
then val%w is set to #b10. I.e. setting w is a forced win for the
first player.

If w is a setting for which all moves leads to settings with value
#b10 then val%w is set to #b01. I.e. w is a losing setting for the
first player.

The moebius command

The argument format of mobius is "-c,-m,-n,-o/K,-t/S".

-c n       The number of coins in the row, default 18
-m n       The maximum number of coins turns in a move, default 5
-n n       The length of each output line
-o file    The name of the output file, the default is to the screen
-t         Turn on tracing

The output is a text file in the form of a raster image with one
character describing the value of each coin pattern. Winning and
losing patterns are represented by minus signs (-) and an asterisks
(*), respectively. The number of patterns per raster line is given by
the -n parameter, but no more the the first 136 are output on any
line.  Coin patterns are represented by bit patterns with 1
representing heads. The rightmost coin is represented by the least
significant bit. The values are output in increasing pattern order.
*/

GET "libhdr"

GLOBAL {
  val:ug
  coins
  maxturns
  len
  upb
  tracing
}

LET start() = VALOF
{ LET argv = VEC 50
  LET stdout = output()
  LET out = stdout

  UNLESS rdargs("-c,-m,-n,-o/K,-t/s", argv, 50) DO
  { writef("Bad arguments for moebius*n")
    RESULTIS 20
  }
  coins, maxturns, len := 5, 3, 64

  IF argv!0 DO coins    := str2numb(argv!0)
  IF argv!1 DO maxturns := str2numb(argv!1)
  IF argv!2 DO len      := str2numb(argv!2)
  upb := (1<<coins) - 1

  IF argv!3 DO
  { out := findoutput(argv!3)
    IF out=0 DO
    { writef("Trouble with file: %s*n", argv!3)
      GOTO fin
    }
    selectoutput(out)
  }
  tracing := argv!4

  val := getvec(upb/bytesperword)
  writef("coins: %n  maxturns: %n len: %n*n", coins, maxturns, len)

  val%0 := #b01
  FOR w = 1 TO upb DO val%w := #b00

  FOR w = 0 TO upb DO try(w)

  pr()

fin:
  freevec(val)
  UNLESS out=stdout DO endwrite()
  selectoutput(stdout)
  RESULTIS 0
}

AND try(w) = VALOF
{ LET res = val%w
  IF res RESULTIS res
  // Try all moves from here
  // If any has value 01 thes the result is 10 (win)
  // If all have value 10 then then the result is 01 (lose)
  FOR sh = 0 TO coins-1 DO
  { LET bit = 1<<sh
    UNLESS (w & bit)=0 DO
    { LET fac = 1
      FOR t = 1 TO maxturns DO // Try all forward moves
      { LET bits = bit*fac
        IF bits>upb BREAK
        IF try(w NEQV bits)=#b01 DO
        { val%w := #b10
          IF tracing DO writef("%x8: %b2*n", w, val%w)
          RESULTIS #b10
        }
        fac := fac*2+1
      }
    }
  }

  val%w := #b01
  IF tracing DO writef("%x8: %b2*n", w, val%w)
  RESULTIS #b01
}
   
AND pr() BE
{ FOR w = 0 TO upb DO
  { LET r = val%w
    UNLESS w REM len DO newline()
    IF w REM len < 136 DO
       wrch(r=#b00 -> '0',
            r=#b01 -> '**',
            r=#b10 -> '-',
            r=#b11 -> 'X', '?')
  }
  newline()
}
