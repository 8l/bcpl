GET "libhdr"

LET start() = VALOF
{ LET argv = VEC 50
  LET stdout = output()
  LET outstream = 0
  LET stdin = input()
  LET instream = 0
  LET dict = "words"
  LET dict1 = "bcpl/bcplprogs/words/words" // For windows CE
  LET dict2 = "/usr/dict/words"            // For Linux
  LET n, matched = 0, TRUE
  LET v = VEC 50
  LET pattern = ?

  UNLESS rdargs("PATTERN/A,DICT,TO/K", argv, 50) DO
  { writef("Bad arguments for filter*n")
    RESULTIS 20
  }

  pattern := argv!0
  IF argv!1 DO dict := argv!1       // DICT

  IF argv!2 DO 
  { outstream := findoutput(argv!2) // TO
    IF outstream=0 DO
    { writef("Trouble with file %s*n", argv!2)
      RESULTIS 20
    }
    selectoutput(outstream)
  }

  IF dict DO instream := findinput(dict)
  IF instream=0 DO instream := findinput(dict1)
  IF instream=0 DO instream := findinput(dict2)
  IF instream=0 DO
  { writef("Cannot open the dictionary*n")
    RESULTIS 20
  }
  selectinput(instream)

  FOR i = 1 TO pattern%0 DO
  { pattern%i := capitalch(pattern%i)
    IF pattern%i='@' DO pattern%i := '.'
  }

  { LET ch = capitalch(rdch())
    IF ch=endstreamch BREAK
    
    IF ch='*n' DO
    { IF matched & pattern%0=n DO
      { FOR i = 1 TO n DO wrch(v!i)
        newline()
      }
      n, matched := 0, TRUE
      LOOP
    }

    n := n + 1
    TEST pattern%n='.' | ch = pattern%n
    THEN v!n := ch
    ELSE matched := FALSE
  } REPEAT

  UNLESS instream=stdin DO endread()
  IF outstream DO endwrite()
  RESULTIS 0
}
