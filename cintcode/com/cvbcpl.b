// This is a program to replace $( and $) section brackets
// by { and } section brackets. It assumes that the source
// program is syntactically correct.

// It is based on bcplfe.b

// Implemented by Martin Richards (c) 7 July 2010


/* Change history

07/07/10
First implementation

*/

SECTION "CVBCPL"

GET "libhdr"
GET "bcplfecg"
 
GLOBAL {
// Globals used in LEX
chbuf:feg
decval//; getstreams; 
charv
//hdrs  // MR 10/7/04

workvec
readnumber; rdstrch
token; wordnode; ch
rdtag//; performget
lex; dsw; declsyswords; nlpending
lookupword; rch
sourcenamev; sourcefileno; sourcefileupb
skiptag; wrchbuf; chcount; lineno
nulltag; rec_p; rec_l
 
// Globals used in SYN
rdblockbody;  rdsect
rnamelist; rname
rdef; rcom
rdcdefs
formtree; synerr; opname
rexplist; rdseq
mk1; mk2; mk3
mk4; mk5; mk6; mk7
newvec
rnexp; rexp; rbexp
tostream
}
 
 
MANIFEST {
c_backspace =  8
c_tab       =  9
c_newline   = 10
c_newpage   = 12
c_return    = 13
c_escape    = 27
c_space     = 32
}

LET start() = VALOF
{ LET treesize = 0
  AND argv = VEC 50
  AND argform = "FROM/A,TO/K,SIZE/K/N"
  LET stdout = output()
  errmax   := 10
  errcount := 0
  fin_p, fin_l := level(), fin

  treevec      := 0
  sourcestream := 0
  tostream     := 0

  sysprint := stdout
  selectoutput(sysprint)
 
  writef("*nCVBCPL (7 Jul 2010)*n")

  IF rdargs(argform, argv, 50)=0 DO { writes("Bad arguments*n")
                                      errcount := 1
                                      GOTO fin
                                    }
  treesize := 200_000
  IF argv!2 DO treesize := !argv!2                   // SIZE/K/N
  IF treesize<10_000 DO treesize := 10_000

  sourcestream := findinput(argv!0)                  // FROM/A

  IF sourcestream=0 DO { writef("Trouble with file %s*n", argv!0)
                         errcount := 1
                         GOTO fin
                       }

  selectinput(sourcestream)
 
  IF argv!1 DO                                       // TO/K
  { tostream := findoutput(argv!1)
    UNLESS tostream DO
    { writef("Trouble with code file %s*n", argv!1)
      errcount := 1
      GOTO fin
    }
  }

  treevec := getvec(treesize)

  IF treevec=0 DO
  { writes("Insufficient memory*n")
    errcount := 1
    GOTO fin
  }
   
  IF tostream DO selectoutput(tostream)


  { LET b = VEC 64/bytesperword
    chbuf := b
    FOR i = 0 TO 63 DO chbuf%i := 0
    chcount, lineno := 0, (sourcefileno<<20) + 1
    token, decval := 0, 0
    rch()
 
    { // Start of loop to process each section
      LET tree = ?
      treep := treevec + treesize

      tree := formtree()
      UNLESS tree BREAK

    } REPEATWHILE token=s_dot
  }
   
fin:
  IF treevec       DO freevec(treevec)
  IF sourcestream  DO { selectinput(sourcestream); endread() }
  IF tostream      DO { selectoutput(tostream)
                        UNLESS tostream=stdout DO endwrite()
                      }
  UNLESS sysprint=stdout DO { selectoutput(sysprint); endwrite() }

  selectoutput(stdout)
//abort(7777)
  RESULTIS errcount=0 -> 0, 20
}

  
LET lex() BE
{ nlpending := FALSE
 
  { SWITCHON ch INTO
 
    { DEFAULT:
            { LET badch = ch
              ch := '*s'
              synerr("Illegal character %x2", badch)
            }

      CASE '*n':
               lineno := lineno + 1
      CASE '*p':
               nlpending := TRUE  // IGNORABLE CHARACTERS
      CASE '*c':
      CASE '*t':
      CASE '*s':
               { wrch(ch); rch() } REPEATWHILE ch='*s'
               LOOP

      CASE '0':CASE '1':CASE '2':CASE '3':CASE '4':
      CASE '5':CASE '6':CASE '7':CASE '8':CASE '9':
              //wrch(ch)
              token := s_number
              decval := readnumber(10, 100)
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
              token := lookupword(rdtag(ch))
              writes(charv)
              IF token=s_get DO
              { lex() // read the string argument of GET
                LOOP
              }
              RETURN
 
      CASE '$':
              rch()
              IF ch='$' | ch='<' | ch='>' DO
              { LET k = ch
                token := lookupword(rdtag('<'))
                writef("$%c", k)
                FOR i = 2 TO charv%0 DO wrch(charv%i)
                // token = s_true             if the tag is set
                //      = s_false or s_name  otherwise
 
                // $>tag   marks the end of a conditional
                //         skipping section

                // $$tag  complements the value of a tag

                lex()
                RETURN
              }
 
              UNLESS ch='(' | ch=')' DO synerr("'$' out of context")
              token := ch='(' -> s_lsect, s_rsect
              lookupword(rdtag('$'))
              wrch(token=s_lsect -> '{', '}')
              RETURN
 
      CASE '{': token, wordnode := s_lsect, nulltag; BREAK
      CASE '}': token, wordnode := s_rsect, nulltag; BREAK

      CASE '#':
              token := s_number
              wrch(ch)
              rch()
              IF '0'<=ch<='7' DO
              { decval := readnumber( 8, 100)
                RETURN
              }
              IF ch='b' | ch='B' DO
              { wrch(ch)
                rch()
                decval := readnumber( 2, 100)
                RETURN
              }
              IF ch='o' | ch='O' DO
              { wrch(ch)
                rch()
                decval := readnumber( 8, 100)
                RETURN
              }
              IF ch='x' | ch='X' DO
              { wrch(ch)
                rch()
                decval := readnumber(16, 100)
                RETURN
              }
              lex(); LOOP // deal with #+ etc
              //token := s_mthap
              RETURN
 
      CASE '[': token := s_sbra;      BREAK
      CASE ']': token := s_sket;      BREAK
      CASE '(': token := s_lparen;    BREAK
      CASE ')': token := s_rparen;    BREAK 
      CASE '?': token := s_query;     BREAK
      CASE '+': token := s_plus;      BREAK
      CASE ',': token := s_comma;     BREAK
      CASE ';': token := s_semicolon; BREAK
      CASE '@': token := s_lv;        BREAK
      CASE '&': token := s_logand;    BREAK
      CASE '=': token := s_eq;        BREAK
      CASE '!': token := s_vecap;     BREAK
      CASE '%': token := s_byteap;    BREAK
      CASE '**':token := s_mult;      BREAK
      CASE '|': token := s_logor;     BREAK
      CASE '.': token := s_dot;       BREAK

 
      CASE '/':
              wrch(ch); rch()
              IF ch='\' DO { token := s_logand; BREAK }
              IF ch='/' DO
              { { wrch(ch); rch() } REPEATUNTIL ch='*n' | ch=endstreamch
                LOOP
              }
 
              IF ch='**' DO
              { LET depth = 1

                { wrch(ch); rch()
                  IF ch='**' DO
                  { { wrch(ch); rch() } REPEATWHILE ch='**'
                    IF ch='/' DO { depth := depth-1; LOOP }
                  }
                  IF ch='/' DO
                  { wrch(ch); rch()
                    IF ch='**' DO { depth := depth+1; LOOP }
                  }
                  IF ch='*n' DO lineno := lineno+1
                  IF ch=endstreamch DO synerr("Missing '**/'")
                } REPEATUNTIL depth=0

                wrch(ch); rch()
                LOOP
              }

              token := s_div
              RETURN
 
      CASE '~':
              wrch(ch); rch()
              IF ch='=' DO { token := s_ne;     BREAK }
              token := s_not
              RETURN
 
      CASE '\':
              wrch(ch); rch()
              IF ch='/' DO { token := s_logor;  BREAK }
              IF ch='=' DO { token := s_ne;     BREAK }
              token := s_not
              RETURN
 
      CASE '<': wrch(ch); rch()
              IF ch='=' DO { token := s_le;     BREAK }
              IF ch='<' DO { token := s_lshift; BREAK }
              token := s_ls
              RETURN
 
      CASE '>': wrch(ch); rch()
              IF ch='=' DO { token := s_ge;     BREAK }
              IF ch='>' DO { token := s_rshift; BREAK }
              token := s_gr
              RETURN
 
      CASE '-': wrch(ch); rch()
              IF ch='>' DO { token := s_cond; BREAK  }
              token := s_minus
              RETURN
 
      CASE ':': wrch(ch); rch()
              IF ch='=' DO { token := s_ass; BREAK  }
              IF ch=':' DO { token := s_of;  BREAK  }  // Inserted 11/7/01
              token := s_colon
              RETURN
 
      CASE '"':
           { LET len = 0
             wrch(ch); rch()
             encoding := defaultencoding // encoding for *# escapes

             UNTIL ch='"' DO
             { LET code = rdstrch()
               TEST result2
               THEN { // A  *# code found.
                      // Convert it to UTF8 or GB2312 format.
                      TEST encoding=GB2312
                      THEN { // Convert to GB2312 sequence
                             IF code>#x7F DO
                             { LET hi = code  /  100 + 160
                               LET lo = code MOD 100 + 160
                               IF len>=254 DO synerr("Bad string constant")
                               TEST bigender
                               THEN { charv%(len+1) := hi 
                                      charv%(len+2) := lo
                                    }
                               ELSE { charv%(len+1) := lo 
                                      charv%(len+2) := hi
                                    }
                               len := len + 2
                               LOOP
                             }
                             IF len>=255 DO synerr("Bad string constant")
                             charv%(len+1) := code // Ordinary ASCII char
                             len := len + 1
                             LOOP
                           }
                      ELSE { // Convert to UTF8 sequence
                             IF code<=#x7F DO
                             { IF len>=255 DO synerr("Bad string constant")
                               charv%(len+1) := code   // 0xxxxxxx
                               len := len + 1
                               LOOP
                             }
                             IF code<=#x7FF DO
                             { IF len>=254 DO synerr("Bad string constant")
                               charv%(len+1) := #b1100_0000+(code>>6)  // 110xxxxx
                               charv%(len+2) := #x80+( code    &#x3F)  // 10xxxxxx
                               len := len + 2
                               LOOP
                             }
                             IF code<=#xFFFF DO
                             { IF len>=253 DO synerr("Bad string constant")
                               charv%(len+1) := #b1110_0000+(code>>12) // 1110xxxx
                               charv%(len+2) := #x80+((code>>6)&#x3F)  // 10xxxxxx
                               charv%(len+3) := #x80+( code    &#x3F)  // 10xxxxxx
                               len := len + 3
                               LOOP
                             }
                             IF code<=#x1F_FFFF DO
                             { IF len>=252 DO synerr("Bad string constant")
                               charv%(len+1) := #b1111_0000+(code>>18) // 11110xxx
                               charv%(len+2) := #x80+((code>>12)&#x3F) // 10xxxxxx
                               charv%(len+3) := #x80+((code>> 6)&#x3F) // 10xxxxxx
                               charv%(len+4) := #x80+( code     &#x3F) // 10xxxxxx
                               len := len + 4
                               LOOP
                             }
                             IF code<=#x3FF_FFFF DO
                             { IF len>=251 DO synerr("Bad string constant")
                               charv%(len+1) := #b1111_1000+(code>>24) // 111110xx
                               charv%(len+2) := #x80+((code>>18)&#x3F) // 10xxxxxx
                               charv%(len+3) := #x80+((code>>12)&#x3F) // 10xxxxxx
                               charv%(len+4) := #x80+((code>> 6)&#x3F) // 10xxxxxx
                               charv%(len+5) := #x80+( code     &#x3F) // 10xxxxxx
                               len := len + 5
                               LOOP
                             }
                             IF code<=#x7FFF_FFFF DO
                             { IF len>=250 DO synerr("Bad string constant")
                               charv%(len+1) := #b1111_1100+(code>>30) // 1111110x
                               charv%(len+2) := #x80+((code>>24)&#x3F) // 10xxxxxx
                               charv%(len+3) := #x80+((code>>18)&#x3F) // 10xxxxxx
                               charv%(len+4) := #x80+((code>>12)&#x3F) // 10xxxxxx
                               charv%(len+5) := #x80+((code>> 6)&#x3F) // 10xxxxxx
                               charv%(len+6) := #x80+( code     &#x3F) // 10xxxxxx
                               len := len + 6
                               LOOP
                             }
                             synerr("Bad Unicode character")
                           }
                    }
               ELSE { // Not a Unicode character
                      IF len=255 DO synerr("Bad string constant")
                      len := len + 1
                      charv%len := code
                    }
             }
             charv%0 := len
             wordnode := newvec(len/bytesperword+2)
             h1!wordnode := s_string
             FOR i = 0 TO len DO (@h2!wordnode)%i := charv%i
             token := s_string
             BREAK
          }
 
      CASE '*'':
              wrch(ch); rch()
              encoding := defaultencoding
              decval := rdstrch()
              token := s_number
              UNLESS ch='*'' DO synerr("Bad character constant")
              BREAK
 
 
      CASE endstreamch:
              token := s_eof
              RETURN
    }
  } REPEAT
 
  wrch(ch); rch()
}
 
LET lookupword(word) = VALOF
{ LET len, i = word%0, 0
  LET hashval = 19609 // This and 31397 are primes.
  FOR j = 0 TO len DO hashval := (hashval NEQV word%j) * 31397
  hashval := (hashval>>1) REM nametablesize

  wordnode := nametable!hashval
 
  UNTIL wordnode=0 | i>len TEST (@h3!wordnode)%i=word%i
                           THEN i := i+1
                           ELSE wordnode, i := h2!wordnode, 0
 
  UNLESS wordnode DO
  { wordnode := newvec(len/bytesperword+2)
    h1!wordnode, h2!wordnode := s_name, nametable!hashval
    FOR i = 0 TO len DO (@h3!wordnode)%i := word%i
    nametable!hashval := wordnode
  }
 
  RESULTIS h1!wordnode
}
 
AND dsw(word, sym) BE { lookupword(word); h1!wordnode := sym  }
 
AND declsyswords() BE
{ dsw("AND", s_and)
  dsw("ABS", s_abs)
  dsw("BE", s_be)
  dsw("BREAK", s_break)
  dsw("BY", s_by)
  dsw("CASE", s_case)
  dsw("DO", s_do)
  dsw("DEFAULT", s_default)
  dsw("EQ", s_eq)
  dsw("EQV", s_eqv)
  dsw("ELSE", s_else)
  dsw("ENDCASE", s_endcase)
  dsw("FALSE", s_false)
  dsw("FOR", s_for)
  dsw("FINISH", s_finish)
  dsw("GOTO", s_goto)
  dsw("GE", s_ge)
  dsw("GR", s_gr)
  dsw("GLOBAL", s_global)
  dsw("GET", s_get)
  dsw("IF", s_if)
  dsw("INTO", s_into)
  dsw("LET", s_let)
  dsw("LV", s_lv)
  dsw("LE", s_le)
  dsw("LS", s_ls)
  dsw("LOGOR", s_logor)
  dsw("LOGAND", s_logand)
  dsw("LOOP", s_loop)
  dsw("LSHIFT", s_lshift)
  dsw("MANIFEST", s_manifest)
  dsw("MOD", s_rem)
  dsw("NE", s_ne)
  dsw("NEEDS", s_needs)
  dsw("NEQV", s_neqv)
  dsw("NOT", s_not)
  dsw("OF", s_of)                   // Inserted 11/7/01
  dsw("OR", s_else)
  dsw("RESULTIS", s_resultis)
  dsw("RETURN", s_return)
  dsw("REM", s_rem)
  dsw("RSHIFT", s_rshift)
  dsw("RV", s_rv)
  dsw("REPEAT", s_repeat)
  dsw("REPEATWHILE", s_repeatwhile)
  dsw("REPEATUNTIL", s_repeatuntil)
  dsw("SECTION", s_section)
  dsw("SKIP", s_skip)               // Added 22/6/05
  dsw("SLCT", s_slct)               // Inserted 11/7/01
  dsw("STATIC", s_static)
  dsw("SWITCHON", s_switchon)
  dsw("TO", s_to)
  dsw("TEST", s_test)
  dsw("TRUE", s_true)
  dsw("THEN", s_do)
  dsw("TABLE", s_table)
  dsw("UNLESS", s_unless)
  dsw("UNTIL", s_until)
  dsw("VEC", s_vec)
  dsw("VALOF", s_valof)
  dsw("WHILE", s_while)
  dsw("XOR", s_neqv)
  dsw("$", 0)
 
  nulltag := wordnode
} 
 
LET rch() BE
{ ch := rdch()
  chcount := chcount + 1
  chbuf%(chcount&63) := ch
}
 
AND wrchbuf() BE
{ writes("*n...")
  FOR p = chcount-63 TO chcount DO
  { LET k = chbuf%(p&63)
    IF 0<k<255 DO wrch(k)
  }
  newline()
}
 
 
AND rdtag(ch1) = VALOF
{ LET len = 1
  //IF eqcases & 'a'<=ch1<='z' DO ch1 := ch1 + 'A' - 'a'
  charv%1 := ch1
 
  { rch()
    UNLESS 'a'<=ch<='z' | 'A'<=ch<='Z' |
           '0'<=ch<='9' | ch='.' | ch='_' BREAK
    //IF eqcases & 'a'<=ch<='z' DO ch := ch + 'A' - 'a'
    len := len+1
    charv%len := ch
  } REPEAT
 
  charv%0 := len
  RESULTIS charv
}

AND catstr(s1, s2) = VALOF
// Concatenate strings s1 and s2 leaving the result in s1.
// s1 is assumed to be able to hold a string of length 255.
// The resulting string is truncated to length 255, if necessary. 
{ LET len = s1%0
  LET n = len
  FOR i = 1 TO s2%0 DO
  { n := n+1
    IF n>255 BREAK
    s1%n := s2%i
  }
  s1%0 := n
} 
 
AND readnumber(radix, digs) = VALOF
// Read a binary, octal, decimal or hexadecimal unsigned number
// with between 1 and digs digits. Underlines are allowed.
// This function is used for numerical constants and numerical
// escapes in string and character constants.
{ LET i, res = 0, 0
 
  { UNLESS ch='_' DO // ignore underlines
    { LET d = value(ch)
      IF d>=radix BREAK
      i := i+1       // Increment count of digits
      res := radix*res + d
    }
    wrch(ch)
    rch()
  } REPEATWHILE i<digs

  UNLESS i DO synerr("Bad number")
  RESULTIS res
}
 
 
AND value(ch) = '0'<=ch<='9' -> ch-'0',
                'A'<=ch<='F' -> ch-'A'+10,
                'a'<=ch<='f' -> ch-'a'+10,
                100
 
AND rdstrch() = VALOF
{ // Return the integer code for the next string character
  // Set result2=TRUE if *# character code was found, otherwise FALSE
  LET k = ch

  IF k='*n' | k='*p' DO
  { lineno := lineno+1
    synerr("Unescaped newline character")
  }
 
  IF k='**' DO
  { wrch(ch)
    rch()
    k := ch
    IF 'a'<=k<='z' DO k := k + 'A' - 'a'
    SWITCHON k INTO
    { CASE '*n':
      CASE '*c':
      CASE '*p':
      CASE '*s':
      CASE '*t': WHILE ch='*n' | ch='*c' | ch='*p' | ch='*s' | ch='*t' DO
                 { IF ch='*n' DO lineno := lineno+1
                   wrch(ch); rch()
                 }
                 IF ch='**' DO { wrch(ch); rch(); LOOP  }

      DEFAULT:   synerr("Bad string or character constant, ch=%n", ch)
         
      CASE '**':
      CASE '*'':
      CASE '"':                    ENDCASE
         
      CASE 'T':  k := c_tab;       ENDCASE
      CASE 'S':  k := c_space;     ENDCASE
      CASE 'N':  k := c_newline;   ENDCASE
      CASE 'E':  k := c_escape;    ENDCASE
      CASE 'B':  k := c_backspace; ENDCASE
      CASE 'P':  k := c_newpage;   ENDCASE
      CASE 'C':  k := c_return;    ENDCASE
         
      CASE 'X':  // *xhh  -- A character escape in hexadecimal
                 wrch(); rch()
                 k := readnumber(16,2)
                 result2 := FALSE
                 RESULTIS k

      CASE '#':  // *#u   set UTF8 mode
                 // *#g   set GB2312 mode
                 // In UTF8 mode
                 //     *#hhhh or *##hhhhhhhh  -- a Unicode character
                 // In GB2312
                 //     *#dddd                 -- A GB2312 code
               { LET digs = 4
                 wrch(ch); rch()
                 IF ch='u' | ch='U' DO { encoding := UTF8;   wrch(ch); rch(); LOOP }
                 IF ch='g' | ch='G' DO { encoding := GB2312; wrch(ch); rch(); LOOP }
                 TEST encoding=GB2312
                 THEN { 
                        k := readnumber(10, digs)
//sawritef("rdstrch: GB2312: %i4*n", k)
                      }
                 ELSE { IF ch='#' DO { wrch(ch); rch(); digs := 8 }
                        k := readnumber(16, digs)
//sawritef("rdstrch: Unicode: %x4*n", k)
                      }
                 result2 := TRUE
                 RESULTIS k
               }

      CASE '0':CASE '1':CASE '2':CASE '3':CASE '4':
      CASE '5':CASE '6':CASE '7':
                 // *ooo -- A character escape in octal 
                 k := readnumber(8,3)
                 IF k>255 DO 
                       synerr("Bad string or character constant")
                 result2 := FALSE
                 RESULTIS k
    }
  }
   
  wrch(ch); rch()
  result2 := FALSE
  RESULTIS k
} REPEAT

LET newvec(n) = VALOF
{ treep := treep - n - 1;
  IF treep<=treevec DO
  { errmax := 0  // Make it fatal
    synerr("More workspace needed")
  }
  RESULTIS treep
}
 
AND mk1(x) = VALOF
{ LET p = newvec(0)
  p!0 := x
  RESULTIS p
}
 
AND mk2(x, y) = VALOF
{ LET p = newvec(1)
  p!0, p!1 := x, y
  RESULTIS p
}
 
AND mk3(x, y, z) = VALOF
{ LET p = newvec(2)
  p!0, p!1, p!2 := x, y, z
  RESULTIS p
}
 
AND mk4(x, y, z, t) = VALOF
{ LET p = newvec(3)
  p!0, p!1, p!2, p!3 := x, y, z, t
  RESULTIS p
}
 
AND mk5(x, y, z, t, u) = VALOF
{ LET p = newvec(4)
  p!0, p!1, p!2, p!3, p!4 := x, y, z, t, u
  RESULTIS p
}
 
AND mk6(x, y, z, t, u, v) = VALOF
{ LET p = newvec(5)
  p!0, p!1, p!2, p!3, p!4, p!5 := x, y, z, t, u, v
  RESULTIS p
}
 
AND mk7(x, y, z, t, u, v, w) = VALOF
{ LET p = newvec(6)
  p!0, p!1, p!2, p!3, p!4, p!5, p!6 := x, y, z, t, u, v, w
  RESULTIS p
}
 
AND formtree() =  VALOF
{ LET res = 0

  nametablesize := 541

  charv      := newvec(256/bytesperword)     
  nametable  := newvec(nametablesize) 
  FOR i = 0 TO nametablesize DO nametable!i := 0
  declsyswords()
 
  rec_p, rec_l := level(), rec
 
  token, decval := 0, 0

  { lex()
rec:
    IF token=s_eof BREAK

    IF token=s_lsect DO rdsect()
  } REPEAT

  RESULTIS res
}
 
AND synerr(mess, a) BE
{ LET fno = lineno>>20
  LET ln = lineno & #xFFFFF

  errcount := errcount + 1
  writef("*nError near ")
  writef("[%n]:  ", ln)
  writef(mess, a)
  wrchbuf()
  IF errcount > errmax DO
  { writes("*nConversion aborted*n")
    longjump(fin_p, fin_l)
  }
  nlpending := FALSE
 
  UNTIL token=s_lsect | token=s_rsect |
        token=s_let | token=s_and |
        token=s_dot | token=s_eof | nlpending DO lex()

  longjump(rec_p, rec_l)
}
 
 
AND rdsect() BE
// Called when token=s_lsect
{ LET tag, res = wordnode, 0

  { lex()

    WHILE token=s_lsect DO rdsect()

    IF token=s_rsect DO
    { TEST tag=wordnode
      THEN { // Close section tag matches openning tag
             lex()
             RETURN
           }
      ELSE { wrch('}') // Insert a closing section bracket
             LOOP
           }
    }
    IF token=s_eof DO
    { wrch('}')
      RETURN
    }
  } REPEAT
}

