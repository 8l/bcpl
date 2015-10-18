// This is to test the Unicode feature of the system.

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
  { writef("Writing Unicode characters in UTF-8 format to stream %s*n",
            argv!0)
    selectoutput(outstream)
  }

  //binwrch(27); writes("%@") // Return to ISO-2022 mode
  //binwrch(27); writes("%G") // Enter RTF-8 mode

  writef("char constant %x4*n", '*#12FE')
  writef("Using string escapes: **#00a9: *#00a9*n")
  writef("Using string escapes: **#2260: *#2260*n")
  writef("Using string escapes: **#8140: *#8140*n")
  writef("Using string escapes: **#8141: *#8141*n")
  writef("Using string escapes: **#8142: *#8142*n")
  writef("Using string escapes: **#3120: *#3120*n")
  writef("Using string escapes: **#3121: *#3121*n")
  writef("Using string escapes: **#3122: *#3122*n")
  writef("Using string escapes: **#3123: *#3123*n")
  writef("Using string escapes: **#3124: *#3124*n")
  writef("Using string escapes: **#3125: *#3125*n")

  newline()
  tst("copyright sign ", #xa9)
  tst("not equals sign", #x2260)
  tst("a chinese char ", #x8140)
  tst("a chinese char ", #x8141)
  tst("a chinese char ", #x8142)
  FOR i = 0 TO 12 DO
    tst("a chinese char ", #x3120+i)

  //binwrch(27); writes("%@") // Return to ISO-2022 mode
  newline()

  IF outstream DO endstream(outstream)
  selectoutput(stdout)
  RESULTIS 0
}

AND tst(mess, ch) BE
{ writef("%s: Unicode %x4 %# ", mess, ch, ch)
  wr_utf8(wrb8, ch) // Write the UTF-8 code in binary
  newline()
}

AND wr_utf8(f, ch) BE
{ // Convert a Unicode character to RTF-8 format
  IF ch<=#x7F DO
  { f(ch)                   // 0xxxxxxx
    RETURN
  }
  IF ch<=#x7FF DO
  { f(#b1100_0000+(ch>>6))  // 110xxxxx
    f(#x80+( ch    &#x3F))  // 10xxxxxx
    RETURN
  }
  IF ch<=#xFFFF DO
  { f(#b1110_0000+(ch>>12)) // 1110xxxx
    f(#x80+((ch>>6)&#x3F))  // 10xxxxxx
    f(#x80+( ch    &#x3F))  // 10xxxxxx
    RETURN
  }
  IF ch<=#x1F_FFFF DO
  { f(#b1111_0000+(ch>>18)) // 11110xxx
    f(#x80+((ch>>12)&#x3F)) // 10xxxxxx
    f(#x80+((ch>>6)&#x3F))  // 10xxxxxx
    f(#x80+( ch    &#x3F))  // 10xxxxxx
    RETURN
  }
  IF ch<=#x3FF_FFFF DO
  { f(#b1111_1000+(ch>>24)) // 111110xx
    f(#x80+((ch>>18)&#x3F)) // 10xxxxxx
    f(#x80+((ch>>12)&#x3F)) // 10xxxxxx
    f(#x80+((ch>>6)&#x3F))  // 10xxxxxx
    f(#x80+( ch    &#x3F))  // 10xxxxxx
    RETURN
  }
  IF ch<=#x7FFF_FFFF DO
  { f(#b1111_1100+(ch>>30)) // 1111110x
    f(#x80+((ch>>24)&#x3F)) // 10xxxxxx
    f(#x80+((ch>>18)&#x3F)) // 10xxxxxx
    f(#x80+((ch>>12)&#x3F)) // 10xxxxxx
    f(#x80+((ch>> 6)&#x3F)) // 10xxxxxx
    f(#x80+( ch     &#x3F)) // 10xxxxxx
    RETURN
  }
}

AND wrb8(byte) BE
{ writef("%b8 ", byte)
}
