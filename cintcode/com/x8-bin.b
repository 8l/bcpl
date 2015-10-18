// This is a program convert a file of 32-bit hex word into a binary.
// Implemented by Martin Richards (c) Aug 2002

// Usage:

// x8-bin filename [[TO] tofile]

/*
It will convert the file:

44434241 48474645 4C4B4A49 504F4E4D 54535251 58575655 310A5A59 35343332 
39383736 00000A30 

to:

ABCDEFGHIJKLMNOPQRSTUVWXYZ
1234567890

(padded with two null characters)
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
{ LET argv    = VEC 50
  sysin      := input()
  sysout     := output()
  fromname   := 0
  toname     := "JUNK"
  fromstream := 0
  tostream   := 0
  count      := 0

  UNLESS rdargs("FROM/A,TO/K", argv, 50) DO
  { writes("bad arguments for x8-bin*n")
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

  { LET word = rdhexword()
    IF result2=-1 BREAK
    wrword(word)
    count := count+4 // count in bytes
    IF count REM 1000000 = 0 DO sawritef("size %i8*n", count)
  } REPEAT

  endread()

  UNLESS sysout=tostream DO endwrite()

  selectoutput(sysout)
  writef("%n bytes written to file *"%s*"*n", count, toname)
  RESULTIS 0
}

AND rdhexword() = VALOF
{ LET word, byte = 0, 0
  // Skip initial white space
  byte := rdch() REPEATWHILE byte=' ' | byte='*n' | byte='*c'
  result2 := -1

  { LET val = value(byte)
    UNLESS 0<=val<=15 RESULTIS word
    word := (word<<4) + val
    result2 := 0
    byte := rdch()
    result2 := 0
  } REPEAT
}

AND value(ch) = '0'<=ch<='9' -> ch - '0',
                'A'<=ch<='F' -> ch - 'A' + 10,
                'a'<=ch<='f' -> ch - 'a' + 10,
                100

AND wrword(word) BE
{ LET s = @word
  binwrch(s%0)
  binwrch(s%1)
  binwrch(s%2)
  binwrch(s%3)
}






