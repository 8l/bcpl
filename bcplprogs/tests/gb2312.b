// This is to test the output of extended characters in GB2312 format.

GET "libhdr"

LET start() = VALOF
{ LET stdout, outstream = output(), 0
  LET argv = VEC 20

  UNLESS rdargs("TO", argv, 20) DO
  { writef("Bad args for chars*n")
    RESULTIS 0
  }

  IF argv!0 DO outstream := findoutput(argv!0)

  IF outstream DO
  { writef("Writing characters in GB2312 format to stream %s*n",
            argv!0)
    selectoutput(outstream)
  }

//  FOR k = #x2000 TO #x2200 DO
  { writef("*#gExtended GB2312 character 2154 prints as: '*#2154'*n")
    writef("%%# in writef can also be used: '%#'*n", 2154)
  }
//GOTO fin

  codewrch(GB2312) // Select GB2312 encoding for this stream
  tst("Foreign sign ", 4566)   // Write 'foreign' => CD E2
  newline()

  FOR row = 1 TO 87 FOR col = 1 TO 94 DO
    tst("code", row*100 + col)

fin:
  newline()

  IF outstream DO endstream(outstream)
  selectoutput(stdout)
  RESULTIS 0
}

AND tst(mess, ch) BE
{ writef("%s: %i4, hex: %x4 %# ", mess, ch, ch, ch)
  wr_gb2312(wrx, ch) // Write the gb2312 code in hex
  newline()
}

AND wr_gb2312(f, ch) BE
{ // Convert a Unicode character to GB2312 format
  IF ch<=#x7F DO
  { f(ch)
    RETURN
  }

  f(ch/100 + 160)      // High byte
  f(ch MOD 100 + 160)  // Low byte
}

AND wrx(byte) BE
{ writef("%x2 ", byte)
}
