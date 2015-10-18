GET "libhdr"

LET start() = VALOF
{ LET argv = VEC 50
  LET stdout = output()
  LET outstream = 0
  LET stdin = input()
  LET instream = 0
  LET dict1 = "bcpl/bcplprogs/words/words" // For windows CE
  LET dict2 = "/usr/dict/words"            // For Linux
  LET dict = "words"
  LET n, matched = 0, TRUE
  LET word = VEC 50
  LET str = ?
  LET strcounts  = VEC 3
  LET wordcounts = VEC 3

  UNLESS rdargs("/A,DICT,TO/K,-d/S", argv, 50) DO
  { writef("Bad arguments for anagrams*n")
    RESULTIS 20
  }

  str := argv!0                     // given string
  compcounts(str, strcounts)

  IF argv!3 DO                      // -d
  { writef("ZYXWVUTSRQPONMLKJIHGFEDCBA*n")
    writef("%bQ*n", strcounts!0)
    writef("%bQ*n", strcounts!1)
    writef("%bQ*n", strcounts!2)
    writef("%bQ*n", strcounts!3)
    RESULTIS 0
  }

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


  { LET ch = rdch()
    IF ch=endstreamch BREAK
    
    TEST ch='*n'
    THEN { word%0 := n
           n := 0
           compcounts(word, wordcounts)
           IF strcounts!0=wordcounts!0 &
              strcounts!1=wordcounts!1 &
              strcounts!2=wordcounts!2 &
              strcounts!3=wordcounts!3 DO writef("%s*n", word)
         }
    ELSE { n := n + 1
           word%n := ch
         }
  } REPEAT

  UNLESS instream=stdin DO endread()
  IF outstream DO endwrite()
  RESULTIS 0
}

AND compcounts(s, v) BE
{ LET len, i = s%0, 1
  LET bits = 0

  v!0, v!1, v!2, v!3 := 0, 0, 0, 0
 
  UNTIL i>len DO
  { LET ch = capitalch(s%i)
    i := i+1
    IF 'A'<=ch<='Z' DO
    { LET bit = 1<<(ch-'A')
      TEST (bits&bit)=0
      THEN bits := bits+bit
      ELSE { addbits(bits, v); bits := bit }
    }
  }
  addbits(bits, v)
}

AND addbits(bits, p) BE IF bits DO
{ addbits(!p & bits, p+1)
  !p := !p NEQV bits
}
