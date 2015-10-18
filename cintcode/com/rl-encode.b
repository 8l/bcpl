// This is a program will (hopefully) copy a file compacting it
// using run length encoding.

// Implemented by Martin Richards (c) June 2009

// Usage:

// rl-encode filename [[TO] tofile]

/*

The given file will be read as binay 8-bit bytes. If two identical
bytes are encountered they will be copied and followed by up to 3
decimal digits giving the count of how many more occurences of this
character should follow. Ordinary text files will convert into hopefully
more compact text files.

The inverse command is

rl-decode filename [[TO] tofile]

*/

GET "libhdr"

GLOBAL {
 eof: ug
 sysin
 sysout
 fromname
 toname
 fromstream
 tostream
 count
}

LET start() = VALOF
{ LET argv = VEC 50
  sysin      := input()
  sysout     := output()
  fromname   := 0
  toname     := "**"
  fromstream := 0
  tostream   := 0
  count      := 0

  UNLESS rdargs("FROM/A,TO/K", argv, 50) DO
  { writes("bad arguments for rl-encode*n")
    stop(20)
  }

  fromname := argv!0                      // FROM
  IF argv!1 DO toname   := argv!1         // TO
 
  fromstream := findinput(fromname)
  UNLESS fromstream DO
  { writef("can't open %s*n", fromname)
    stop(20)
  }

  tostream := findoutput(toname)
  UNLESS tostream DO
  { writef("can't open %s*n", toname)
    endread()
    stop(20)
  }
  selectoutput(tostream)
  selectinput(fromstream)

  { LET ch = binrdch()

    UNTIL ch=endstreamch DO
    { LET ch1 = binrdch()
      TEST ch=ch1
      THEN { // Two identical bytes
             LET repcount = 0
             { ch1 := binrdch()
               IF ch~=ch1 | repcount=999 BREAK
               repcount := repcount+1
             } REPEAT
             binwrch(ch)
             binwrch(ch)
             IF '0'<=ch1<='9' DO repcount := repcount + 1000
             IF repcount>99 DO wrch(repcount/100 MOD 10 + '0')
             IF repcount>9  DO wrch(repcount/10  MOD 10 + '0')
             IF repcount>0  DO wrch(repcount     MOD 10 + '0')
           }
      ELSE { binwrch(ch)
           }
      ch := ch1
    }
  }

  UNLESS sysout=tostream DO endwrite()
  endread()

  selectoutput(sysout)
  RESULTIS 0
}







