GET "libhdr"

LET start() = VALOF
{ LET stdin = input()
  LET stdout = output()
  LET argv = VEC 50
  LET inname, instream = "data", 0
  LET outname, outstream = "res", 0
  LET length = 0

  UNLESS rdargs("FROM/A,TO/K", argv, 50) DO
  { writef("Bad arguments for BIN2N*n")
    RESULTIS 0
  }

  IF argv!0 DO inname  := argv!0
  IF argv!1 DO outname := argv!1

  instream := findinput(inname)
  outstream := findoutput(outname)

  UNLESS instream DO
  { writef("Cannot open file %s*n", inname)
    GOTO fin
  }

  UNLESS outstream DO
  { writef("Cannot open file %s*n", outname)
    GOTO fin
  }

  selectinput(instream)
  selectoutput(outstream)

  writef("*n12345*n")    // Begin marker

  { LET ch = binrdch()
    IF ch=endstreamch BREAK
    length := length+1
    IF length MOD 20 = 0 DO newline()
    writef(" %n", ch)
  } REPEAT

  writef("*n23456*n")    // End marker

fin:
  IF instream  UNLESS instream=stdin   DO endstream(instream)
  IF outstream UNLESS outstream=stdout DO endstream(outstream)
  selectinput(stdin)
  selectoutput(stdout)

  writef("%s length %n => %s written*n", inname, length, outname)
  RESULTIS 0
}
