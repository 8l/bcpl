GET "libhdr"

LET start() = VALOF
{ LET stdin = input()
  LET stdout = output()
  LET argv = VEC 50
  LET inname, instream = "data", 0
  LET outname, outstream = "res", 0
  LET length = 0
  LET started = FALSE

  UNLESS rdargs("FROM/A,TO/K", argv, 50) DO
  { writef("Bad arguments for N2BIN*n")
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

  { LET ch = rdch()
    IF '0'<=ch<='9' DO
    { LET val = 0
      WHILE '0'<=ch<='9' DO
      { val := 10*val + ch - '0'
        ch := rdch()
      }

      IF val=23456 BREAK                // End marker

      IF started DO
      { binwrch(val)
        length := length + 1
      }
      IF val=12345 DO started := TRUE   // Begin marker
    }
    IF ch=endstreamch BREAK
  } REPEAT

fin:
  IF instream  UNLESS instream=stdin   DO endstream(instream)
  IF outstream UNLESS outstream=stdout DO endstream(outstream)
  selectinput(stdin)
  selectoutput(stdout)

  writef("%s length %n => %s written*n", inname, length, outname)
  RESULTIS 0
}
