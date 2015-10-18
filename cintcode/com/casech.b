// (C) Copyright 1978 Tripos Research Group
//     University of Cambridge
//     Computer Laboratory

// Modified by MR for Cintcode
// CASECH [FROM] input [TO] output [DICT dictionary] [L] [U] [A]

//17/06/2010 MR
// Reinserted FLOAT and FIX
// Caused '.' to be replaced by '_' in identifiers

// 25/4/04 MR
// Deleted FIX and FLOAT, added MOD OF SLCT and XOR
// Changed default to L

SECTION "CASECH"

GET "libhdr"

GLOBAL {
upper: ug
lower
ch
wordv
wch
wordsize
charv
treevec
treep
linecount
nametree
wordnode
word
echo
settag
mstream
sectv   // Vector of section bracket tags
sectp   // = depth of section brackets
        // sectv!sectp = tag of current section
sectt   // upb of sectv
}


LET readprog() BE
{ SWITCHON ch INTO

  { CASE '*p':
    CASE '*n': linecount := linecount+1
    CASE '*t':
    CASE '*s': rch(echo) REPEATWHILE ch='*s'
               LOOP

    CASE '0':CASE '1':CASE '2':CASE '3':CASE '4':
    CASE '5':CASE '6':CASE '7':CASE '8':CASE '9':
         readfloat()
         LOOP

    CASE 'a':CASE 'b':CASE 'c':CASE 'd':CASE 'e':
    CASE 'f':CASE 'g':CASE 'h':CASE 'i':CASE 'j':
    CASE 'k':CASE 'l':CASE 'm':CASE 'n':CASE 'o':
    CASE 'p':CASE 'q':CASE 'r':CASE 's':CASE 't':
    CASE 'u':CASE 'v':CASE 'w':CASE 'x':CASE 'y':
    CASE 'z':
    CASE 'A':CASE 'B':CASE 'C':CASE 'D':CASE 'E':
    CASE 'F':CASE 'G':CASE 'H':CASE 'I':CASE 'J':
    CASE 'K':CASE 'L':CASE 'M':CASE 'N':CASE 'O':
    CASE 'P':CASE 'Q':CASE 'R':CASE 'S':CASE 'T':
    CASE 'U':CASE 'V':CASE 'W':CASE 'X':CASE 'Y':
    CASE 'Z':
         rdtag()
         writetag()
         LOOP

    CASE '$': rch(echo)
              TEST ch='(' | ch=')' THEN { rdtag()
                                          writetag()
                                        }
                                   ELSE rch(echo)
              LOOP

    CASE '/':
       rch(echo)
       IF ch='\'  DO { rch(echo) ;        LOOP }
       IF ch='**' DO { readcomment('/') ; LOOP }
       UNLESS ch='/' LOOP
    Comment:
       rch(echo) REPEATUNTIL iscc(ch) | ch=endstreamch
       LOOP

    CASE '|':
       rch(echo)
       IF ch='|' GOTO Comment
       UNLESS ch='**' LOOP
       readcomment('|')
       LOOP

    CASE '#':
       { LET radix = 8
          rch(echo)
          IF ch='B' DO { radix := 2  ; rch(echo) }
          IF ch='X' DO { radix := 16 ; rch(echo) }
          readnumber(radix)
          LOOP }

    CASE '"': rch(echo)
              FOR I = 1 TO 255 DO { IF ch='"' BREAK
                                    rdstrch()
                                  }
              rch(echo)
              LOOP

    CASE '*'':rch(echo)
              rdstrch()
              rch(echo)
              LOOP

    DEFAULT:  rch(echo)
              LOOP

    CASE endstreamch: RETURN
  }
} REPEAT

AND iscc(ch)= (ch='*n') | (ch='*p')

AND readcomment(term) BE
{
   rch(echo)
   {
      IF iscc(ch)
      THEN linecount := linecount + 1
      IF ch='**' THEN
      {
         rch(echo)
         UNLESS ch=term LOOP
         rch(echo)
         RETURN
      }
      IF ch=endstreamch DO error("Endstreamch in comment*n")
      rch(echo)
   } REPEAT
}

AND lookupword(makenew) = VALOF
{ LET p = @nametree

  wordnode := !p

  UNTIL wordnode=0 DO
  { LET cmp = compstring(wordv, wordnode+2)
    IF cmp=0 RESULTIS wordnode+2
    p := wordnode + (cmp<0->0,1)
    wordnode := !p
  }

  IF makenew DO
  { wordnode := newvec(wordsize+2)
    wordnode!0, wordnode!1 := 0, 0
    FOR i = 0 TO wordsize DO wordnode!(i+2) := wordv!i
    !p:=wordnode
  }
  RESULTIS 0
}

AND declsyswords() BE
{
    d("ABS/AND/*
      *BE/BREAK/BY/*
      *CASE/*
      *DO/DEFAULT/*
      *EQ/EQV/ELSE/ENDCASE/*
      *FALSE/FLOAT/FOR/FINISH/FIX/*
      *GOTO/GE/GR/GLOBAL/GET/*
      *IF/INTO/*
      *LET/LV/LE/LS/LOGOR/LOGAND/LOOP/LSHIFT//")

    d("MANIFEST/MOD/*
      *NEEDS/NE/NOT/NEQV/*
      *OF/OR/*
      *RESULTIS/RETURN/REM/RSHIFT/RV/*
      *REPEAT/REPEATWHILE/REPEATUNTIL/*
      *SECTION/SLCT/SWITCHON/STATIC/*
      *TO/TEST/TRUE/THEN/TABLE/*
      *UNTIL/UNLESS/*
      *VEC/VALOF/*
      *WHILE/*
      *XOR//")
}

AND d(words) BE
{ LET i, length = 1, 0

  { LET ch = words%i
    TEST ch='/'
    THEN { IF length=0 RETURN
           charv!0 := length
           wordsize := packstring(charv, wordv)
           lookupword(TRUE)
           length := 0
         }
    ELSE { length := length + 1
           charv!length := ch
         }
    i := i + 1
  } REPEAT
}

AND rch(echo) BE
{
  IF echo DO wch(ch)
  ch:=rdch()
}

AND rdtag() BE
{ LET n = 1
  charv!1 := ch

  { rch(FALSE)
    IF ch='.' DO ch := '_'
    UNLESS 'A'<=ch<='Z' |
           'a'<=ch<='z' |
           '0'<=ch<='9' |
            ch='.' | ch='_' BREAK
    n := n+1
    charv!n := ch
  } REPEAT

  charv!0 := n
  wordsize := packstring(charv, wordv)
 }


AND writetag() BE
{ LET mode=lookupword(settag)

  TEST mode=0 THEN
  {
    IF upper DO
    {
      FOR i=1 TO charv!0 DO
      {
         LET ch=charv!i
         IF 'a'<=ch<='z' DO charv!i:=ch-'a'+'A'
      }
      packstring(charv, wordv)
    }
    IF lower FOR i=1 TO charv!0 DO
    {
      LET ch=charv!i
      IF 'A'<=ch<='Z' DO charv!i:=ch-'A'+'a'
    }
    IF echo FOR i=1 TO charv!0 DO wch(charv!i)
  }
  ELSE IF echo FOR i = 1 TO mode%0 DO
       { LET ch = mode%i
         wrch(ch)
       }
}

AND allupperwrch(ch) BE
{
  IF 'a'<=ch<='z' DO ch:=ch-'a'+'A'
  wrch(ch)
}

AND readfloat() BE
{ WHILE '0'<=ch<='9' | ch='_' DO rch(echo)
  IF ch='.' DO
  { // Read the fraction       eq 123.456
    rch(echo)   
    WHILE '0'<=ch<='9' | ch='_' DO rch(echo)
  }
  IF ch='e' | ch='E' DO
  { // Read the exponent       eg 123e-5  1.2e10
    rch(echo)
    IF ch='-' | ch='+' DO rch(echo)
    WHILE '0'<=ch<='9' | ch='_' DO rch(echo)
  }
}

AND readnumber(radix) BE UNTIL value(ch)>=radix & ch~='_' DO rch(echo)

AND value(ch) = '0'<=ch<='9' -> ch-'0',
                'a'<=ch<='f' -> ch-'a'+10,
                'A'<=ch<='F' -> ch-'A'+10,
                100

AND rdstrch() = VALOF
{ LET k = ch

  rch(echo)

  IF k='*n' DO error("Bad string")

  IF k='**' DO
  { IF ch='*n' | ch='*s' | ch='*t' DO
    { { IF ch='*n' DO linecount := linecount+1
        rch(echo)
      } REPEATWHILE ch='*n' | ch='*s' | ch='*t'
      rch(echo)
      RESULTIS rdstrch()
    }

    rch(echo)
  }

  RESULTIS k
}

AND newvec(n) = VALOF
{ treep := treep - n - 1
  IF treep<=treevec DO
  { error("Program too large")
    stop(20)
  }
  RESULTIS treep
}


AND error(Mess) BE
{ LET oldout=output()
  selectoutput(mstream)
  writef("Line %n %s*n", linecount, Mess)
  selectoutput(oldout)
}

AND start() = VALOF
{ LET v1 = VEC 50
  AND v2 = VEC 100
  LET argv = VEC 40
  AND instream, outstream = 0, 0
  AND dictstream = 0
  LET stdout = output()
  LET sv = VEC 100
  sectv, sectp, sectt := sv, 0, 100
  mstream := stdout
  linecount:=0
  wordv := v1
  charv := v2
  treevec := getvec(5000)
  treep   := treevec+5000

  IF treevec = 0
  THEN { writes("No space for tree*n"); RESULTIS 20 }

  wch := wrch
  UNLESS rdargs("FROM/A,TO/K,DICT/K,U/S,L/S,A/S", argv, 40) DO
  { writes("Args no good*n")
    RESULTIS 20
  }

  instream := findinput(argv!0)        // FROM/A
  UNLESS instream DO
  { writef("Can't open %s*n", argv!0)
    RESULTIS 20
  }

  IF argv!1 DO
  { outstream := findoutput(argv!1)    // TO/K
    IF outstream = 0
    THEN { writef("Can't open %s*n",argv!1); RESULTIS 20 }
  }
  UNLESS outstream DO outstream := stdout

  dictstream := argv!2 -> findinput(argv!2), 0  // DICT/K

  lower, upper := TRUE, FALSE          // Default is now L

  TEST argv!3                          // U/S
  THEN lower, upper := FALSE, TRUE
  ELSE IF argv!5                       // A/S
       THEN wch := allupperwrch

  selectoutput(outstream)

  nametree:=0
  declsyswords()
  IF dictstream DO
  { echo:=FALSE; settag:=TRUE
    selectinput(dictstream)
    rch(FALSE)
    readprog()
    endread()
  }

  echo:=TRUE
  settag:=FALSE
  selectinput(instream)
  rch(FALSE)
  readprog()
  endread()
  UNLESS outstream=stdout DO endwrite()
  freevec(treevec)
  RESULTIS 0
}
