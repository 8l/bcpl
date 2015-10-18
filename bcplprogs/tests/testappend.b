GET "libhdr"

LET start() = VALOF
{ LET stdout = output()
  LET filename = "junk"
  LET stream = findoutput(filename)
  selectoutput(stream)
  writef("First line*n")
  endstream(stream)
  stream := findappend(filename)
  selectoutput(stream)
  writef("Second line*n")
  endstream(stream)
  selectoutput(stdout)
  stream := findinput(filename)
  selectinput(stream)

  writef("*nThe file %s is now:*n*n", filename)

  { LET ch = rdch()
    IF ch=endstreamch BREAK
    wrch(ch)
  } REPEAT

  RESULTIS 0
}
