// This is a program convert a file numbers in ASCII to back to a binary file.
// It is the inverse of bin-n.b.b

// Implemented by Martin Richards (c) Sept 2006

// Usage:

// hex2bin filename [[TO] tofile]

/*
It will convert the file:

   65   66   67   68   69   70   71   72
   73   74   75   76   77   78   79   80
   81   82   83   84   85   86   87   88
   89   90   10   49   50   51   52   53
   54   55   56   57   48   10

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
  { writes("bad arguments for n-bin*n")
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

  { LET byte = readn()
    IF byte=0 & result2<0 BREAK
    wrch(byte)
    count := count+1
  } REPEAT

  endread()

  UNLESS sysout=tostream DO endwrite()

  selectoutput(sysout)
  writef("%n bytes written to file *"%s*"*n", count, toname)
  RESULTIS 0
}


