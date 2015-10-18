GET "libhdr"

LET start() = VALOF
{ LET argv = VEC 50
  LET res = 0
  LET stdout = output()
  LET outstream = 0
  LET stdin = input()
  LET instream = 0
  LET dict1 = "bcpl/bcplprogs/words/words" // For windows CE
  LET dict2 = "/usr/dict/words"            // For Linux
  LET dict = "words"                       // words in the current directory
  LET countv = VEC 255
  LET pairv = getvec(27*27)

  FOR ch = 0 TO 255 DO countv!ch := 0
  FOR i  = 0 TO 27*27 DO pairv!i := 0

  UNLESS rdargs("DICT,TO/K,-d/S", argv, 50) DO
  { writef("Bad arguments for anagrams*n")
    res := 20
    GOTO fin
  }

  IF argv!0 DO dict := argv!0       // DICT

  IF argv!1 DO 
  { outstream := findoutput(argv!1) // TO
    IF outstream=0 DO
    { writef("Trouble with file %s*n", argv!2)
      res := 20
      GOTO fin
    }
    selectoutput(outstream)
  }

  IF dict DO instream := findinput(dict)
  IF instream=0 DO instream := findinput(dict1)
  IF instream=0 DO instream := findinput(dict2)
  IF instream=0 DO
  { writef("Cannot open the dictionary*n")
    res := 20
    GOTO fin
  }
  selectinput(instream)

  { LET prevch = '.'
    { LET ch = capitalch(rdch())
      LET p = 'A'<=prevch<='Z' -> 27*(prevch-'A'+1), 0

    
      TEST 'A'<=ch<='Z'
      THEN { p := p + ch - 'A' + 1         // letter letter or
                                           // non-letter letter
             pairv!p   := pairv!p   + 1
             countv!ch := countv!ch + 1
           }
      ELSE IF p DO pairv!p := pairv!p + 1  // letter non-letter 

      IF ch=endstreamch BREAK
      prevch := ch
    } REPEAT
  }

  UNLESS instream=stdin DO endread()

  writef("*n*n*n")
  writef("   ")
  FOR i = 1 TO 27 DO writef("    %c", ".ABCDEFGHIJKLMNOPQRSTUVWXYZ"%i)
  newline()
  writef(".:      ")
  FOR i = 1 TO 26 DO writef("%i5", pairv!i)
  newline()
  FOR i = 1 TO 26 DO
  { LET p = 
    writef("%c: ", i+'A'-1)
    FOR p = 27*i TO 27*i+26 DO writef("%i5", pairv!p)
    writef(" %i5*n", countv!('A'+i-1))
  }


fin:
  IF pairv DO freevec(pairv)
  IF outstream DO endwrite()
  RESULTIS 0
}

