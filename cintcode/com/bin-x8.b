// This is a program convert a binary file into a file of 32-bit hex words.

// Implemented by Martin Richards (c) Aug 2002

// Usage:

// bin-x8 filename [[TO] tofile]

/*
It will convert the file:

ABCDEFGHIJKLMNOPQRSTUVWXYZ
1234567890

to:

44434241 48474645 4C4B4A49 504F4E4D 54535251 58575655 310A5A59 35343332 
39383736 00000A30 

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
  { writes("Bad arguments for bin-x8, format: FROM/A,TO/K*n")
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

  { LET word = 0
    LET s = @word
    LET ch = binrdch()
    IF ch=endstreamch BREAK
    s%0 := ch
    ch := binrdch()
    IF ch=endstreamch GOTO wr
    s%1 := ch
    ch := binrdch()
    IF ch=endstreamch GOTO wr
    s%2 := ch
    ch := binrdch()
    IF ch=endstreamch GOTO wr
    s%3 := ch
wr:
    writef("%x8 ", word)
    count := count+1
    IF count REM 8 = 0 DO newline()
  } REPEAT

  UNLESS count REM 8 = 0 DO newline()

  UNLESS sysout=tostream DO endwrite()
  endread()

  selectoutput(sysout)
  writef("%n words written to file *"%s*"*n", count, toname)
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






