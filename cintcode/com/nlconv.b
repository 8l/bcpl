GET "libhdr"

LET start() = VALOF
{ LET argv = VEC 50
  LET infile = 0
  LET outfile = 0
  LET nl = nlunix
  LET ch = 0

  UNLESS rdargs("FILE,TOUNIX/S,TODOS/S,Q/S", argv, 50) DO
  { writes("Bad arguments for NLCONV*n")
    RESULTIS 20
  }

  UNLESS argv!0 DO
  { LET w(s) = writef("%s*n", s)
    w("nlconv FILE,TOUNIX/S,TODOS/S,Q/S")
    newline()
    w("This replaces each end-of-line mark in the given file (FILE) by")
    w("    LF        if TOUNIX specified (the default)")
    w("    CR LF     if TODOS  specified")
    newline()
    w("On input, CR LF, CR, LF CR and LF are all end-of-line marks")
    newline()
    w("Q quietens nlconv")
    RESULTIS 0
  }
 
  infile := findinput(argv!0)  
  UNLESS infile DO
  { writef("Trouble with file %s*n", argv!0)
    RESULTIS 20
  }
  selectinput(infile)
  outfile := findoutput("TEMPFILE")
  UNLESS outfile DO
  { writef("Cannot open TEMPFILE")
    endread()
    RESULTIS 20
  }

  IF argv!2 DO nl := nldos

  UNLESS argv!3 TEST nl=nlunix
                THEN writef("Converting EOLs to LFs*n")
                ELSE writef("Converting EOLs to CR LFs*n")

  selectoutput(outfile)

  ch := rdch()

  { SWITCHON ch INTO
    { DEFAULT: wrch(ch)
               ch := rdch()
               LOOP
      CASE endstreamch:
               BREAK
      CASE 13: ch := rdch() 
               IF ch=10 DO ch := rdch()
               nl()
               LOOP
      CASE 10: ch := rdch() 
               IF ch=13 DO ch := rdch()
               nl()
               LOOP
    }
  } REPEAT

  endread()
  endwrite()
  renamefile("TEMPFILE", argv!0)
  RESULTIS 0
}

AND nlunix() BE wrch(10)                // LF

AND nldos() BE { wrch(13); wrch(10) }   // CR LF
