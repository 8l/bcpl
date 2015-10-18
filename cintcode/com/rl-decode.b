// This is a program will (hopefully) copy a file expanding its
// run length encoding. It is the inverse command for rl-encode.

// Implemented by Martin Richards (c) June 2009

// Usage:

// rl-decode filename [[TO] tofile]

/*

The given file is read as binary 8-bit bytes. If two identical
bytes are encountered, it will read up to three decimal digits
giving the number of repetition of the latest byte.

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
  { writes("bad arguments for rl-decode*n")
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
             LET i, n = 0, 0
             // Read up to three digits
             { ch1 := binrdch()
               i := i+1
               IF i>3 BREAK
               UNLESS '0'<=ch1<='9' BREAK
               n := 10*n + ch1 - '0'
             } REPEAT
             // Write the ch twice folloed by n repetitions
             FOR i = 1 TO n+2 DO binwrch(ch)
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







