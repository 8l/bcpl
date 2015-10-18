// This is a program convert a binary file to hex for editing
// Implemented by Martin Richards (c) July 2002

// Usage:

// bin2hex filename [[TO] tofile]

/*
It will convert the file:

ABCDEFGHIJKLMNOPQRSTUVWXYZ
1234567890

to:

41 42 43 44 45 46 47 48 49 4A 4B 4C 4D 4E 4F 50
51 52 53 54 55 56 57 58 59 5A 0A 31 32 33 34 35
36 37 38 39 30 0A
*/

GET "libhdr"

GLOBAL { eof: ug }

LET start() BE
{ LET argv       = VEC 50
  LET sysin      = input()
  LET sysout     = output()
  LET fromname   = 0
  LET toname     = 0
  LET fromstream = 0
  LET tostream   = 0
  LET count = 0

  UNLESS rdargs("FROM/A,TO/K", argv, 50) DO
  { writes("bad arguments for bin2hex*n")
    stop(20)
  }

  fromname := argv!0                      // FROM
  toname   := argv!1                      // TO
 
  fromstream := findinput(fromname)
  UNLESS fromstream DO
  { writef("can't open %s*n", fromname)
    stop(20)
  }

  IF toname DO
  { tostream := findoutput(toname)
    UNLESS tostream DO
    { writef("can't open %s*n", toname)
      endread()
      stop(20)
    }
    selectoutput(tostream)
  }


  selectinput(fromstream)

  { LET ch = 0
//    ch := binrdch()
    ch := rdch()              // rdch is fine under Cintpos
    IF ch=endstreamch BREAK
    IF count REM 16 = 0 DO newline()
    writef(" %x2", ch)
    count := count+1
  } REPEAT

  newline()

  endread()

  IF tostream UNLESS sysout=tostream DO endwrite()
}
