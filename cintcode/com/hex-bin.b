// This is a program convert a hex file to back to a binary file.
// It is the inverse of bin2hex.b

// Implemented by Martin Richards (c) July 2002

// Usage:

// hex2bin filename [[TO] tofile]

/*
It will convert the file:

41 42 43 44 45 46 47 48 49 4A 4B 4C 4D 4E 4F 50
51 52 53 54 55 56 57 58 59 5A 0A 31 32 33 34 35
36 37 38 39 30 0A

to:

ABCDEFGHIJKLMNOPQRSTUVWXYZ
1234567890
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
  { writes("bad arguments for hex2b*n")
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

  { LET byte = rdhexbyte()
    IF byte<0 BREAK
    wrch(byte)
    count := count+1
  } REPEAT

  endread()

  UNLESS sysout=tostream DO endwrite()

  selectoutput(sysout)
  writef("%n bytes written to file *"%s*"*n", count, toname)
  RESULTIS 0
}

AND rdhexbyte() = VALOF
{ LET a, b = 0, 0
  a := rdch() REPEATWHILE a=' ' | a='*n'
  IF a=endstreamch RESULTIS -1
  a := value(a)
  UNLESS 0<=a<=15 DO abort(999)
  b := rdch()
  IF b=endstreamch RESULTIS -1
  b := value(b)
  UNLESS 0<=b<=15 abort(999)

  RESULTIS (a<<4) | b
}

AND value(ch) = '0'<=ch<='9' -> ch - '0',
                'A'<=ch<='F' -> ch - 'A' + 10,
                'a'<=ch<='f' -> ch - 'a' + 10,
                100
