// (C) Copyright 1978 Tripos Research Group
//     University of Cambridge
//     Computer Laboratory

/* Change log

16/8/01
Added SLCT, OF and :: and made /* */ comments nest.
Allowed constants in GLOBAL, MANIFEST and STATIC declarations
to be optional.

*/

SECTION "BCPLXREF"

GET "libhdr"

MANIFEST {
s_null=0
s_let
s_proc
s_lab
s_global
s_manifest
s_static
s_for
s_eq
s_be
s_and
s_name
s_number
s_get
s_string
s_colon
s_lparen
s_rparen
s_case
s_end
s_semicol
s_lsect
s_rsect
wspacesize = 30000
}

GLOBAL {
nextsymb:ug
lookupword
cmpstr
declsyswords
d
rch
rdtag
performget
readnumber
value
rdstrch
newvec
list2
addref
xref
prtree
wrnameinfo
error
match

symb
prevsymb
ch
wordv
wordsize
charv
ptr
treevec
treep
getv
getp
gett
sourcestream
linecount
nametree
wordnode
word
pattern
fileno
nextfile
matchall
oldtype
nlpending
tostream
workspace
}


LET nextsymb() BE
{ prevsymb := symb
  symb := s_null

  IF nlpending DO
  {  linecount := linecount + 1
     nlpending:=FALSE
  }

  SWITCHON ch INTO

  { CASE '*p':
    CASE '*n': nlpending := TRUE
               rch()
               symb:=s_semicol
               RETURN

    CASE '*t':
    CASE '*s': rch() REPEATWHILE ch='*s'
               LOOP

    CASE '0':CASE '1':CASE '2':CASE '3':CASE '4':
    CASE '5':CASE '6':CASE '7':CASE '8':CASE '9':
               readnumber(10)
               symb := s_number
               RETURN

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
               rdtag(ch)
               symb := lookupword()
               UNLESS symb=s_get RETURN
               performget()
               LOOP

    CASE '$':  rch()
               symb := 0
               IF ch='(' DO symb := s_lsect
               IF ch=')' DO symb := s_rsect
               TEST ch='(' | ch=')'
               THEN rdtag('$')
               ELSE rch()
               RETURN

    CASE '{':  symb := s_lsect
               rch()
               RETURN
    CASE '}':  symb := s_rsect
               rch()
               RETURN
    CASE '[':
    CASE '(':  symb := s_lparen
               rch()
               RETURN
    CASE ']':
    CASE ')':  symb := s_rparen
               rch()
               RETURN

    CASE '=':  symb := s_eq
               rch()
               RETURN

    CASE '#':
       { LET radix = 8
         rch()
         IF ch='B' DO radix := 2
         IF ch='X' DO radix := 16
         UNLESS 'O'<=ch<='7' DO rch()
         readnumber(radix)
         symb := s_number
         RETURN
       }

    CASE '/':
         rch()
         IF ch='\' DO { rch(); LOOP  }
         IF ch='/' DO
         { rch() REPEATUNTIL ch='*n' | ch=endstreamch
           LOOP
         }

         UNLESS ch='**' RETURN

         // skip (nested) /* */ comments
         {  LET depth = 1

            {  rch()
               IF ch='**' DO
               {  rch() REPEATWHILE ch='**'
                  IF ch='/' DO {  depth := depth-1; LOOP }
               }
               IF ch='/' DO
               {  rch()
                  IF ch='**' DO {  depth := depth+1; LOOP }
               }
               IF ch='*n' DO linecount := linecount+1
               IF ch=endstreamch BREAK
            } REPEATUNTIL depth=0

            rch()
            LOOP
          }

    CASE '|':
         rch()
         IF ch='|' DO
         { rch() REPEATUNTIL ch='*n' | ch=endstreamch
           LOOP
         }

         UNLESS ch='**' RETURN

         { rch()
           IF ch='**' DO
           { rch() REPEATWHILE ch='**'
             IF ch='|' BREAK
           }
           IF ch='*n' DO linecount:=linecount+1
         } REPEATUNTIL ch=endstreamch

         rch()
         LOOP

    CASE '<':
    CASE '>':
    CASE '\': rch()
              IF ch='=' DO rch()
              RETURN

    CASE '-': rch()
              IF ch='>' DO rch()
              RETURN

    CASE ';': symb:=s_semicol
              rch()
              RETURN

    CASE ':': rch()
              IF ch='=' DO { rch(); RETURN  }
              IF ch=':' DO { rch(); RETURN  }
              symb := s_colon
              RETURN


    CASE '"': rch()
              charv!0 := 0
              FOR i = 1 TO 255 DO
              { IF ch='"' BREAK
                charv!0 := i
                charv!i := rdstrch()
              }
              wordsize := packstring(charv, wordv)
              symb := s_string
              rch()
              RETURN

    CASE '*'':rch()
              rdstrch()
              rch()
              symb := s_number
              RETURN


    CASE '.': UNLESS getp=0 DO ch := endstreamch
    DEFAULT:  UNLESS ch=endstreamch DO
              { rch()
                RETURN
              }
              IF getp=0 DO { symb := s_end
                             RETURN
                           }
              endread()
              getp := getp - 3
              sourcestream := getv!getp
              selectinput(sourcestream)
              linecount := getv!(getp+1)>>3
              fileno := getv!(getp+1)&7
              ch := getv!(getp+2)
              LOOP
  }
} REPEAT

LET lookupword() = VALOF
{ LET p = @nametree

  wordnode := !p

  UNTIL wordnode=0 DO
  { LET cmp = cmpstr(wordv, wordnode+4)
    IF cmp=0 RESULTIS !wordnode
    p := wordnode + (cmp<0->1,2)
    wordnode := !p
  }

  wordnode := newvec(wordsize+4)
  wordnode!0, wordnode!1 := s_name, 0
  wordnode!2, wordnode!3 := 0, 0
  FOR i = 0 TO wordsize DO wordnode!(i+4) := wordv!i

  !p := wordnode
  RESULTIS s_name
}

AND cmpstr(s1, s2) = VALOF
{ LET len1, len2 = s1%0, s2%0
  FOR i = 1 TO len1 DO
  { LET ch1, ch2 = s1%i, s2%i
    IF i>len2  RESULTIS 1
    IF 'a'<=ch1<='z' DO ch1:=ch1-'a'+'A'
    IF 'a'<=ch2<='z' DO ch2:=ch2-'a'+'A'
    IF ch1>ch2 RESULTIS 1
    IF ch1<ch2 RESULTIS -1
  }
  IF len1<len2 RESULTIS -1
  RESULTIS 0
}

AND declsyswords() BE
{ ptr := TABLE
      0,s_and,
      s_be,0,0,
      s_case,
      0,0,
      s_eq,0,0,0,
      0,0,s_for,0,
      0,0,0,s_global,s_get,
      0,0,
      s_let,0,0,0,0,0,0,0,
      s_manifest,
      0,0,0,0,
      0,0,
      0,0,0,0,0,
      0,0,0,
      0,0,0,s_static,
      0,0,0,0,0,
      0,0,
      0,0,
      0

  d("ABS/AND/*
    *BE/BREAK/BY/*
    *CASE/*
    *DO/DEFAULT/*
    *EQ/EQV/ELSE/ENDCASE/*
    *FALSE/FLOAT/FOR/FINISH/*
    *GOTO/GE/GR/GLOBAL/GET/*
    *IF/INTO/*
    *LET/LV/LE/LS/LOGOR/LOGAND/LOOP/LSHIFT//")

  d("MANIFEST/*
    *NEEDS/NE/NOT/NEQV/*
    *OR/OF/*
    *RESULTIS/RETURN/REM/RSHIFT/RV/*
    *REPEAT/REPEATWHILE/REPEATUNTIL/*
    *SECTION/SLCT/SWITCHON/STATIC/*
    *TO/TEST/TRUE/THEN/TABLE/*
    *UNTIL/UNLESS/*
    *VEC/VALOF/*
    *WHILE//")
}


AND d(words) BE
{ LET i, length = 1, 0

  { LET ch = words%i
    TEST ch='/'
    THEN { IF length=0 RETURN
           charv!0 := length
           wordsize := packstring(charv, wordv)
           lookupword()
           !wordnode := !ptr
            ptr := ptr + 1
            length := 0
         }
    ELSE { length := length + 1
           charv!length := ch
         }
    i := i + 1
  } REPEAT
}

LET rch() BE ch := rdch()

AND rdtag(char1) BE
{ LET n = 1
  charv!1 := char1

  { rch()
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


AND performget() BE
{ LET stream = ?
  LET filename = VEC 50
  nextsymb()
  UNLESS symb=s_string DO error("Bad GET directive")
  FOR i = 1 TO wordv%0 IF wordv%i=':' DO wordv%i := '/'
//writef("trying: GET *"%s*" in BCPLHDRS*n", wordv)
  // First look in the current directory
  stream := pathfindinput(wordv, "BCPLHDRS")

  UNLESS stream DO
  { LET dirname = "" // not "g/"
    LET ext     = ".h"
    LET n = 0                  // Form:  <name>.h
    FOR i = 1 TO dirname%0 DO
    { n := n+1
      filename%n := dirname%i
    }
    FOR i = 1 TO wordv%0 DO
    { n := n+1
      filename%n := wordv%i
    }
    FOR i = 1 TO ext%0 DO
    { n := n+1
      filename%n := ext%i
    }
    filename%0 := n
//sawritef("trying: GET *"%s*" in BCPLHDRS*n", filename)
    stream := pathfindinput(filename, "BCPLHDRS")  // MR 18/2/04
  }

  UNLESS stream DO
  { error("Unable to find GET file %s", wordv)
    RETURN
  }
//sawritef("File *"%s*" opened successfully*n", wordv)

  writef("File %N is *"%S*"*n", nextfile+1, wordv)
  getv!getp := sourcestream
  getv!(getp+1) := (linecount<<3)+fileno
  getv!(getp+2) := ch
  getp := getp + 3
  linecount := 1
  sourcestream := stream
  selectinput(sourcestream)
  nextfile := nextfile + 1
  fileno:=nextfile
  rch()
}



AND readnumber(radix) BE
  UNTIL value(ch)>=radix & ch~='_' DO rch()

AND value(ch) = '0'<=ch<='9' -> ch-'0',
                'a'<=ch<='f' -> ch-'a'+10,
                'A'<=ch<='F' -> ch-'A'+10,
                100

AND rdstrch() = VALOF
{ LET k = ch

  rch()

  IF k='*n' DO error("Bad string")

  IF k='**' DO
  { IF ch='*n' | ch='*s' | ch='*t' DO
    { { IF ch='*n' DO linecount := linecount+1
         rch()
       } REPEATWHILE ch='*n' | ch='*s' | ch='*t'
       rch()
       RESULTIS rdstrch()
    }

    rch()
  }

  RESULTIS k
}

LET newvec(n) = VALOF
{ treep := treep - n - 1
  UNLESS treep>=treevec DO
  { error("Program too large")
    quit(20)
  }
  RESULTIS treep
}



AND list2(x, y) = VALOF
{ LET p = newvec(1)
  p!0, p!1 := x, y
  RESULTIS p   }


AND addref(type, name) BE
{ LET p = name+3
  UNTIL !p=0 DO p := !p
  !p := list2(0, (((linecount<<3)+fileno)<<3)+type)
}

AND xref(v,size) BE
{ LET type = s_null

  treevec, treep := v, v+size

  nametree := 0
  nlpending:=FALSE
  matchall:= FALSE
  fileno:=0
  nextfile:=0
  linecount := 1
  declsyswords()
  rch()
  nextsymb()

  UNTIL symb=s_end SWITCHON symb INTO
  { CASE s_global:
    CASE s_static:
    CASE s_manifest: type := symb
                     oldtype := symb
    DEFAULT:         nextsymb()
                     LOOP

    CASE s_and: symb := s_let
    CASE s_case:
    CASE s_for:
    CASE s_let: type := symb
                nextsymb()
                LOOP

    CASE s_rsect:
                type, oldtype := s_null, s_null
                nextsymb()
                LOOP

    CASE s_semicol: type:=oldtype
                    nextsymb()
                    LOOP

    CASE s_colon:
    CASE s_be:
    CASE s_eq: type := s_null
               nextsymb()
               LOOP

    CASE s_name:
    { LET t = type
      LET name = wordnode
      nextsymb()
      IF symb=s_colon DO t:= type=s_null -> s_lab,
                             type=s_case -> s_null, type
      IF type=s_let DO t:= symb=s_lparen -> s_proc, s_let
      IF type =s_global | type=s_manifest | type=s_static DO
        SWITCHON prevsymb INTO
        { DEFAULT:  t := s_null

          CASE s_lsect:
          CASE s_name: CASE s_number: CASE s_rparen:
                    t := type
                    ENDCASE
        }
      word := name+4
      IF matchall | match(1,1) DO addref(t, name)
      LOOP
    }
  }

  newline()
  prtree(nametree)

  writes("*n** - never used*n")
  writes("*nKey to references in <lineno><type><fileno>*n")
  writes(" V - variable*n P - procedure*n L - label*n G - global*n")
  writes(" M - manifest*n S - static*n F - FOR loop variable*n")
  writef("*nSpace used %N*n", v+size-treep)
}

AND prtree(t) BE UNLESS t=0 DO
{ prtree(t!1)
  wrnameinfo(t)
  prtree(t!2)
}

AND wrnameinfo(t) BE IF !t=s_name DO
{ LET n = t+4
  LET l = t!3
  LET chp = n%0 + 3
  LET declared, used = FALSE, FALSE

  IF intflag() RETURN

  UNTIL l=0 DO
  {
    IF ((l!1)&#7)=0 THEN declared := TRUE
    IF ((l!1)&#70)=0 THEN used:=TRUE
    l := !l
  }
  UNLESS used /*in main file*/ RETURN
  writef("%C %S ", (declared->'*s','**'), n)
  UNTIL chp REM 7 = 5 & chp>=12 DO { wrch('*s')
                                     chp := chp+1
                                   }
  l := t!3
  UNTIL l=0 DO
  { LET a = l!1
    LET ln, f, t = a>>6, (a>>3)&7, a&7
    IF chp>=70 DO { writes("*n            ")
                    chp := 12  }
    writed(ln, 5)
    TEST t=0 THEN wrch( f=0 -> '*s', ':' )
             ELSE wrch( "VPLGMSF"%t )
    TEST f=0 THEN wrch('*s')
             ELSE writed(f,1)
    chp:=chp+7
    l := !l
  }

  newline()
}

AND error(mess) BE writef("Line %N %S*n", linecount, mess)

AND match(p,s) =
    s>word%0 -> (p>pattern%0 -> TRUE,
                 pattern%p='**' -> match(p+1,s),
                          FALSE),
    p>pattern%0 -> FALSE,
    pattern%p='**' ->
       (match(p+1,s) -> TRUE,
        match(p,s+1)),
    ( pattern%p=word%s |
      'a'<=word%s<='z' & pattern%p=word%s-'a'+'A' |
      'A'<=word%s<='Z' & pattern%p=word%s-'A'+'a' ) -> match(p+1,s+1),
    FALSE

AND start() = VALOF
{ LET v3 = VEC 20
  LET argv = VEC 40
  LET parm = ?

  IF rdargs("FROM/A,TO/K,PAT/K",argv,40) = 0 DO
  { writes("Invalid args to BCPLXREF*n")
    quit(20)
  }

  parm := (argv!2 = 0 -> "", argv!2)

  getv, getp, gett := v3, 0, 20

  pattern := "**"
  IF parm%0>0 DO pattern := parm
  IF parm%(parm%0)='*n' DO parm%0:=parm%0-1
  writes("BCPL cross referencer")
  TEST pattern%0=1 & pattern%1='**'
  THEN matchall:=TRUE
  ELSE writef(". Pattern=%S", pattern)
  writes("*n*n")

  sourcestream := findinput(argv!0)
  IF sourcestream=0 DO
  { writef("Can't open %S*n", argv!0)
    quit(20)
  }
  selectinput(sourcestream)

  tostream := 0
  UNLESS argv!1 = 0 DO
  { tostream := findoutput(argv!1)
    IF tostream = 0 DO
    { writef("Can't open %S*n", argv!1)
      quit(20)
    }
    selectoutput(tostream)
  }

  charv := getvec(256)     // used to hold strings 1 char/word
  wordv := getvec(256/bytesperword)   // used for strings
  workspace := getvec(wspacesize - 1)
  IF workspace = 0 | charv=0 | wordv=0 DO
  { writes("Insufficient store*n")
    quit(20)
  }

  xref(workspace, wspacesize)
  quit(0) // Close down stream and free work space.
  RESULTIS 0
}


AND quit(code) BE
{ // Tidies up and stops
  UNLESS workspace = 0 DO freevec(workspace)
  UNLESS sourcestream = 0 DO endread()
  UNLESS tostream = 0 DO endwrite()
  stop(code)
}
