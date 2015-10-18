/*
b2flow is a BCPL to FCODE translator
implemented in BCPL by Martin Richards (c) April 2001
*/

/* Change history

1/2/00
Started converting this compiler to generate FCODE, a simple
flow graph intermediate form for experiments on dataflow
analysis optimisations of a typeless language. The idea is
let the optimiser see all the program being compiled including
the source of all libraries. The only interface between the compiled
program and the operating system will be via the library functions
sys, muldiv and chngco defined in SYSLIB.

This program is based on bcpl.b as it was on 1/2/2000
*/

SECTION "SYN"

GET "b2flow.h"
 
GLOBAL {                    // Globals used in LEX
chbuf:220; decval; getstreams; charv
workvec
readnumber; rdstrch
symb; wordnode; ch
rdtag; performget
lex; dsw; declsyswords; nlpending
lookupword; rch;
skiptag; wrchbuf; chcount; lineno
nulltag; rec_p; rec_l
 
// GLOBALS USED IN SYN
rdblockbody; rdsect
rnamelist; rname
rdef; rcom
rdcdefs
formtree; synerr; plist
rexplist; rdseq
list1; list2; list3
list4; list5; list6; list7
newvec
rnexp; rexp; rbexp
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
   AND argform =
"FROM/A,TO/K,VER/K,SIZE/K,TREE/S,NONAMES/S,D1/S,D2/S,OENDER/S,EQCASES/S,BIN/S"
   LET stdout = output()

   errmax   := 30
   errcount := 0
   fin_p, fin_l := level(), fin

   treevec      := 0
   sourcestream := 0
   flowout     := 0
   
   sysprint := stdout
   selectoutput(sysprint)
 
   writef("*nB2FLOW (1 Feb 2000)*n")
 
   IF rdargs(argform, argv, 50)=0 DO { writes("Bad arguments*n")
                                        errcount := 1
                                        GOTO fin
                                     }
   treesize := 40000
   IF argv!3 DO treesize := str2numb(argv!3)
   IF treesize<10000 DO treesize := 10000

   prtree        := argv!4

   // Code generator options 

   naming := TRUE
   debug := 0
   bigender := (!"AAA" & 255) = 'A' // =TRUE if running on a bigender
   IF argv!5 DO naming   := FALSE         // NONAMES
   IF argv!6 DO debug    := debug+1       // D1
   IF argv!7 DO debug    := debug+2       // D2
   IF argv!8 DO bigender := ~bigender     // OENDER
   eqcases := argv!9                      // EQCASES

   sourcestream := findinput(argv!0)      // FROM

   IF sourcestream=0 DO { writef("Trouble with file %s*n", argv!0)
                          errcount := 1
                          GOTO fin
                        }

   selectinput(sourcestream)
 
   UNLESS argv!1 DO argv!1 := "FLOW"
   flowout := findoutput(argv!1)
   IF flowout=0 DO
   { writef("Trouble with code file %s*n", argv!1)
     errcount := 1
     GOTO fin
   }

   treevec := getvec(treesize)

   IF treevec=0 DO
   { writes("Insufficient memory*n")
     errcount := 1
     GOTO fin
   }
   
   UNLESS argv!2=0 DO       // VER
   { sysprint := findoutput(argv!2)
     IF sysprint=0 DO
     { sysprint := stdout
       writef("Trouble with file %s*n", argv!2)
       errcount := 1
       GOTO fin
     }
   }

   selectoutput(sysprint)

   // Now syntax analyse, translate each section
   { LET b = VEC 64/bytesperword
     chbuf := b
     FOR i = 0 TO 63 DO chbuf%i := 0
     chcount, lineno := 0, 1
     rch()
 
     UNTIL ch=endstreamch DO
     { LET tree = ?
       treep := treevec + treesize

       tree := formtree()
       IF tree=0 BREAK
 
       //writef("Tree size %n*n", treesize+treevec-treep)
 
       IF prtree DO { writes("Parse Tree*n")
                      plist(tree, 0, 20)
                      newline()
                    }
  
       UNLESS errcount=0 GOTO fin
       translate(tree)
     }
   }
   
fin:
   UNLESS treevec=0       DO freevec(treevec)
   UNLESS sourcestream=0  DO { selectinput(sourcestream); endread()  }
   UNLESS flowout=0       DO { selectoutput(flowout)
                               UNLESS flowout=stdout DO   endwrite() }
   UNLESS sysprint=stdout DO { selectoutput(sysprint);    endwrite() }

   selectoutput(stdout)
   RESULTIS errcount=0 -> 0, 20
}

  
LET lex() BE
{ nlpending := FALSE
 
   { SWITCHON ch INTO
 
      { CASE '*p':
         CASE '*n':
               lineno := lineno + 1
               nlpending := TRUE  // IGNORABLE CHARACTERS
         CASE '*c':
         CASE '*t':
         CASE '*s':
               rch() REPEATWHILE ch='*s'
               LOOP

         CASE '0':CASE '1':CASE '2':CASE '3':CASE '4':
         CASE '5':CASE '6':CASE '7':CASE '8':CASE '9':
              symb := s_number
              readnumber(10)
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
              symb := lookupword(rdtag(ch))
              IF symb=s_get DO { performget(); LOOP  }
              RETURN
 
         CASE '$':
              rch()
              IF ch='$' | ch='<' | ch='>' DO
              { LET k = ch
                 symb := lookupword(rdtag('<'))
                 // symb = s_true             if the tag is set
                 //      = s_false or s_name  otherwise
 
                 // $>tag   marks the end of a conditional
                 //         skipping section
                 IF k='>' DO
                 { IF skiptag=wordnode DO
                       skiptag := 0   // Matching $>tag found
                    LOOP
                 }
 
                 UNLESS skiptag=0 LOOP

                 // Only process $<tag and $$tag if not skipping
 
                 // $$tag  complements the value of a tag
                 IF k='$' DO
                 { h1!wordnode := symb=s_true -> s_false, s_true
                    LOOP
                 }
 
                 // $<tag
                 IF symb=s_true LOOP      // Don't skip if set

                 // tag is false so skip until matching $>tag or EOF
                 skiptag := wordnode
                 UNTIL skiptag=0 | symb=s_end DO lex()
                 skiptag := 0
                 RETURN
              }
 
              UNLESS ch='(' | ch=')' DO synerr("'$' out of context")
              symb := ch='(' -> s_lsect, s_rsect
              lookupword(rdtag('$'))
              RETURN
 
         CASE '{': symb, wordnode := s_lsect, nulltag; BREAK
         CASE '}': symb, wordnode := s_rsect, nulltag; BREAK

         CASE '#':
              symb := s_number
              rch()
              IF '0'<=ch<='7'    DO {        readnumber(8);  RETURN  }
              IF ch='b' | ch='B' DO { rch(); readnumber(2);  RETURN  }
              IF ch='o' | ch='O' DO { rch(); readnumber(8);  RETURN  }
              IF ch='x' | ch='X' DO { rch(); readnumber(16); RETURN  }
              symb := s_mthap
              RETURN
 
         CASE '[':
         CASE '(': symb := s_lparen;    BREAK
         CASE ']':
         CASE ')': symb := s_rparen;    BREAK 
         CASE '?': symb := s_query;     BREAK
         CASE '+': symb := s_plus;      BREAK
         CASE ',': symb := s_comma;     BREAK
         CASE ';': symb := s_semicolon; BREAK
         CASE '@': symb := s_lv;        BREAK
         CASE '&': symb := s_logand;    BREAK
         CASE '|': symb := s_logor;     BREAK
         CASE '=': symb := s_eq;        BREAK
         CASE '!': symb := s_vecap;     BREAK
         CASE '%': symb := s_byteap;    BREAK
         CASE '**':symb := s_mult;      BREAK
 
         CASE '/':
              rch()
              IF ch='\' DO { symb := s_logand; BREAK }
              IF ch='/' DO
              { rch() REPEATUNTIL ch='*n' | ch=endstreamch
                 LOOP
              }
 
              IF ch='**' DO
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
                    IF ch='*n' DO lineno := lineno+1
                    IF ch=endstreamch DO synerr("Missing '**/'")
                 } REPEATUNTIL depth=0

                 rch()
                 LOOP
              }

              symb := s_div
              RETURN
 
         CASE '~':
              rch()
              IF ch='=' DO { symb := s_ne;     BREAK }
              symb := s_not
              RETURN
 
         CASE '\':
              rch()
              IF ch='/' DO { symb := s_logor;  BREAK }
              IF ch='=' DO { symb := s_ne;     BREAK }
              symb := s_not
              RETURN
 
         CASE '<': rch()
              IF ch='=' DO { symb := s_le;     BREAK }
              IF ch='<' DO { symb := s_lshift; BREAK }
              symb := s_ls
              RETURN
 
         CASE '>': rch()
              IF ch='=' DO { symb := s_ge;     BREAK }
              IF ch='>' DO { symb := s_rshift; BREAK }
              symb := s_gr
              RETURN
 
         CASE '-': rch()
              IF ch='>' DO { symb := s_cond; BREAK  }
              symb := s_minus
              RETURN
 
         CASE ':': rch()
              IF ch='=' DO { symb := s_ass; BREAK  }
              symb := s_colon
              RETURN
 
         CASE '"':
           { LET len = 0
              rch()
 
              UNTIL ch='"' DO
              { IF len=255 DO synerr("Bad string constant")
                 len := len + 1
                 charv%len := rdstrch()
              }
 
              charv%0 := len
              wordnode := newvec(len/bytesperword+2)
              h1!wordnode := s_string
              FOR i = 0 TO len DO (@h2!wordnode)%i := charv%i
              symb := s_string
              BREAK
           }
 
         CASE '*'':
              rch()
              decval := rdstrch()
              symb := s_number
              UNLESS ch='*'' DO synerr("Bad character constant")
              BREAK
 
 
         DEFAULT:
              UNLESS ch=endstreamch DO
              { LET badch = ch
                 ch := '*s'
                 synerr("Illegal character %x2", badch)
              }

         CASE '.':
              IF getstreams=0 DO { symb := s_end
                                    IF ch='.' DO rch()
                                    RETURN
                                 }
              endread()
              ch           := h4!getstreams
              lineno       := h3!getstreams
              sourcestream := h2!getstreams
              getstreams   := h1!getstreams
              selectinput(sourcestream)
              LOOP
      }
   } REPEAT
 
   rch()
}
 
LET lookupword(word) = VALOF
{ LET len, i = word%0, 0
   LET hashval = 19609 // This and 31397 are primes.
   FOR i = 0 TO len DO hashval := (hashval NEQV word%i) * 31397
   hashval := (hashval>>1) REM nametablesize

   wordnode := nametable!hashval
 
   UNTIL wordnode=0 | i>len TEST (@h3!wordnode)%i=word%i
                            THEN i := i+1
                            ELSE wordnode, i := h2!wordnode, 0
 
   IF wordnode=0 DO
   { wordnode := newvec(len/bytesperword+3)
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
  dsw("NE", s_ne)
  dsw("NOT", s_not)
  dsw("NEQV", s_neqv)
  dsw("NEEDS", s_needs)
  dsw("OR", s_else)
  dsw("RESULTIS", s_resultis)
  dsw("RETURN", s_return)
  dsw("REM", s_rem)
  dsw("RSHIFT", s_rshift)
  dsw("RV", s_rv)
  dsw("REPEAT", s_repeat)
  dsw("REPEATWHILE", s_repeatwhile)
  dsw("REPEATUNTIL", s_repeatuntil)
  dsw("SWITCHON", s_switchon)
  dsw("STATIC", s_static)
  dsw("SECTION", s_section)
  dsw("TO", s_to)
  dsw("TEST", s_test)
  dsw("TRUE", s_true)
  dsw("THEN", s_do)
  dsw("TABLE", s_table)
  dsw("UNTIL", s_until)
  dsw("UNLESS", s_unless)
  dsw("VEC", s_vec)
  dsw("VALOF", s_valof)
  dsw("WHILE", s_while)
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
  IF eqcases & 'a'<=ch1<='z' DO ch1 := ch1 + 'A' - 'a'
  charv%1 := ch1
 
  { rch()
    UNLESS 'a'<=ch<='z' | 'A'<=ch<='Z' |
           '0'<=ch<='9' | ch='.' | ch='_' BREAK
    IF eqcases & 'a'<=ch<='z' DO ch := ch + 'A' - 'a'
    len := len+1
    charv%len := ch
  } REPEAT
 
  charv%0 := len
  RESULTIS charv
}
 
AND performget() BE
{ LET stream = ?
  lex()
  UNLESS symb=s_string DO synerr("Bad GET directive")
  stream := pathfindinput(charv, "BCPLPATH")
  TEST stream=0
  THEN synerr("Unable to find GET file %s", charv)
  ELSE { getstreams := list4(getstreams, sourcestream, lineno, ch)
         sourcestream := stream
         selectinput(sourcestream)
         lineno := 1
         rch()
       }
}
 
AND readnumber(radix) BE
{ LET d = value(ch)
  decval := d
  IF d>=radix DO synerr("Bad number")
 
  { rch()
    IF ch='_' LOOP
    d := value(ch)
    IF d>=radix RETURN
    decval := radix*decval + d
  } REPEAT
}
 
 
AND value(ch) = '0'<=ch<='9' -> ch-'0',
                'A'<=ch<='F' -> ch-'A'+10,
                'a'<=ch<='f' -> ch-'a'+10,
                100
 
AND rdstrch() = VALOF
{ LET k = ch

   IF k='*n' | k='*p' DO
   { lineno := lineno+1
      synerr("Unescaped newline character")
   }
 
   IF k='**' DO
   { rch()
      k := ch
      IF 'a'<=k<='z' DO k := k + 'A' - 'a'
      SWITCHON k INTO
      { CASE '*n':
         CASE '*p':
         CASE '*s':
         CASE '*t': WHILE ch='*n' | ch='*p' | ch='*s' | ch='*t' DO
                    { IF ch='*n' | ch='*p' DO lineno := lineno+1
                       rch()
                    }
                    IF ch='**' DO { rch(); LOOP  }

         DEFAULT:   synerr("Bad string or character constant")
         
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
         
         CASE 'X':  RESULTIS readoctalorhex(16,2)
         
         CASE '0':CASE '1':CASE '2':CASE '3':CASE '4':
         CASE '5':CASE '6':CASE '7':CASE '8':CASE '9':
                    k:=value(ch)*64+readoctalorhex(8,2)
                    IF k>255 DO 
                       synerr("Bad string or character constant")
                    RESULTIS k
      }
   }
   
   rch()
   RESULTIS k
} REPEAT
 
 
AND readoctalorhex(radix, digits) = VALOF
{ LET answer, dig = 0, ?
   FOR j = 1 TO digits DO
   { rch()
      dig := value(ch)
      IF dig > radix DO synerr("Bad string or character constant")
      answer:=answer*radix + dig
   }
   rch()
   RESULTIS answer
}

LET newvec(n) = VALOF
{ treep := treep - n - 1;
   IF treep<=treevec DO
   { errmax := 0  // Make it fatal
      synerr("More workspace needed")
   }
   RESULTIS treep
}
 
AND list1(x) = VALOF
{ LET p = newvec(0)
   p!0 := x
   RESULTIS p
}
 
AND list2(x, y) = VALOF
{ LET p = newvec(1)
   p!0, p!1 := x, y
   RESULTIS p
}
 
AND list3(x, y, z) = VALOF
{ LET p = newvec(2)
   p!0, p!1, p!2 := x, y, z
   RESULTIS p
}
 
AND list4(x, y, z, t) = VALOF
{ LET p = newvec(3)
   p!0, p!1, p!2, p!3 := x, y, z, t
   RESULTIS p
}
 
AND list5(x, y, z, t, u) = VALOF
{ LET p = newvec(4)
   p!0, p!1, p!2, p!3, p!4 := x, y, z, t, u
   RESULTIS p
}
 
AND list6(x, y, z, t, u, v) = VALOF
{ LET p = newvec(5)
   p!0, p!1, p!2, p!3, p!4, p!5 := x, y, z, t, u, v
   RESULTIS p
}
 
AND list7(x, y, z, t, u, v, w) = VALOF
{ LET p = newvec(6)
   p!0, p!1, p!2, p!3, p!4, p!5, p!6 := x, y, z, t, u, v, w
   RESULTIS p
}
 
AND formtree() =  VALOF
{ LET res = 0

   nametablesize := 541

   getstreams := 0
   charv      := newvec(256/bytesperword)     
   nametable  := newvec(nametablesize) 
   FOR i = 0 TO nametablesize DO nametable!i := 0
   skiptag := 0
   declsyswords()
 
   rec_p, rec_l := level(), rec
 
   lex()

   IF symb=s_query DO            // For debugging lex.
   { lex()
      IF symb=s_end RESULTIS 0
      writef("symb =%i3  decval = %i8   charv = %s*n",
              symb,      decval,        charv)
   } REPEAT

rec:res := symb=s_section -> rprog(s_section),
           symb=s_needs   -> rprog(s_needs), rdblockbody(TRUE)
   UNLESS symb=s_end DO synerr("Incorrect termination")
 
   RESULTIS res
}
 
AND rprog(thing) = VALOF
{ LET a = 0
   lex()
   a := rbexp()
   UNLESS h1!a=s_string THEN synerr("Bad SECTION or NEEDS name")
   RESULTIS list3(thing, a,
                  symb=s_needs -> rprog(s_needs),rdblockbody(TRUE))
}
 
 
AND synerr(mess, a) BE
{ errcount := errcount + 1
   writef("*nError near line %n:  ", lineno)
   writef(mess, a)
   wrchbuf()
   IF errcount > errmax DO
   { writes("*nCompilation aborted*n")
      longjump(fin_p, fin_l)
   }
   nlpending := FALSE
 
   UNTIL symb=s_lsect | symb=s_rsect |
         symb=s_let | symb=s_and |
         symb=s_end | nlpending DO lex()

   IF symb=s_and DO symb := s_let
   longjump(rec_p, rec_l)
}
 
LET rdblockbody(outerlevel) = VALOF
{ LET p, l = rec_p, rec_l
   LET a, ln = 0, ?
 
   rec_p, rec_l := level(), recover

recover:  
   IF symb=s_semicolon DO lex()
 
   ln := lineno
   
   SWITCHON symb INTO
   { CASE s_manifest:
      CASE s_static:
      CASE s_global:
              {  LET op = symb
                  lex()
                  a := rdsect(rdcdefs, op=s_global->s_colon,s_eq)
                  a := list4(op, a, rdblockbody(outerlevel), ln)
                  ENDCASE
              }
 
 
      CASE s_let: lex()
                  a := rdef(outerlevel)
                  WHILE symb=s_and DO
                  { LET ln1 = lineno
                     lex()
                     a := list4(s_and, a, rdef(outerlevel), ln1)
                  }
                  a := list4(s_let, a, rdblockbody(outerlevel), ln)
                  ENDCASE
 
      DEFAULT:    IF outerlevel DO
                  { errmax := 0 // Make it fatal.
                     synerr("Bad outer level declaration")
                  }
                  a := rdseq()
                  UNLESS symb=s_rsect DO synerr("Error in command")
 
      CASE s_rsect:IF outerlevel DO lex()
      CASE s_end:
   }
 
   rec_p, rec_l := p, l
   RESULTIS a
}
 
AND rdseq() = VALOF
{ LET a = 0
   IF symb=s_semicolon DO lex()
   a := rcom()
   IF symb=s_rsect | symb=s_end RESULTIS a
   RESULTIS list3(s_seq, a, rdseq())
}

AND rdcdefs(sep) = VALOF
{ LET res, id = 0, 0
   LET ptr = @res
   LET p, l = rec_p, rec_l
   LET kexp = 0
   rec_p, rec_l := level(), recov
 
   { kexp := 0
      id := rname()
      IF symb=sep DO kexp := rnexp(0)
      !ptr := list4(s_constdef, 0, id, kexp)
      ptr := @h2!(!ptr)

recov:IF symb=s_semicolon DO lex()
   } REPEATWHILE symb=s_name
 
   rec_p, rec_l := p, l
   RESULTIS res
}
 
AND rdsect(r, arg) = VALOF
{ LET tag, res = wordnode, 0
   UNLESS symb=s_lsect DO synerr("'{' or '{' expected")
   lex()
   res := r(arg)
   UNLESS symb=s_rsect DO synerr("'}' or '}' expected")
   TEST tag=wordnode THEN lex()
                     ELSE IF wordnode=nulltag DO
                          { symb := 0
                             synerr("Untagged '}' mismatch")
                          }
   RESULTIS res
}

AND rnamelist() = VALOF
{ LET a = rname()
   UNLESS symb=s_comma RESULTIS a
   lex()
   RESULTIS list3(s_comma, a, rnamelist())
}

AND rname() = VALOF
{ LET a = wordnode
   UNLESS symb=s_name DO synerr("Name expected")
   lex()
   RESULTIS a
}
 
LET rbexp() = VALOF
{ LET a, op = 0, symb
 
   SWITCHON symb INTO
 
   { DEFAULT: synerr("Error in expression")

      CASE s_query:  lex()
                     RESULTIS list1(s_query)
 
      CASE s_true:
      CASE s_false:
      CASE s_name:
      CASE s_string: a := wordnode
                     lex()
                     RESULTIS a
 
      CASE s_number: a := list2(s_number, decval)
                     lex()
                     RESULTIS a
 
      CASE s_lparen: a := rnexp(0)
                     UNLESS symb=s_rparen DO synerr("')' missing")
                     lex()
                     RESULTIS a
 
      CASE s_valof:  lex()
                     RESULTIS list2(s_valof, rcom())
 
      CASE s_vecap:  op := s_rv
      CASE s_lv:
      CASE s_rv:     RESULTIS list2(op, rnexp(7))
 
      CASE s_plus:   RESULTIS rnexp(5)
 
      CASE s_minus:  a := rnexp(5)
                     TEST h1!a=s_number THEN h2!a := - h2!a
                                        ELSE a := list2(s_neg, a)
                     RESULTIS a
 
      CASE s_abs:    RESULTIS list2(s_abs, rnexp(5))
 
      CASE s_not:    RESULTIS list2(s_not, rnexp(3))
 
      CASE s_table:  lex()
                     RESULTIS list2(s_table, rexplist())
  }
}
 
AND rnexp(n) = VALOF { lex(); RESULTIS rexp(n) }
 
AND rexp(n) = VALOF
{ LET a, b, p = rbexp(), 0, 0

   UNTIL nlpending DO 
   { LET op = symb
 
      SWITCHON op INTO
 
      { DEFAULT:       RESULTIS a
 
         CASE s_lparen: lex()
                        b := 0
                        UNLESS symb=s_rparen DO b := rexplist()
                        UNLESS symb=s_rparen DO synerr("')' missing")
                        lex()
                        a := list4(s_fnap, a, b, 0)
                        LOOP
 
         CASE s_mthap:{ LET e1 = 0
                         lex()
                         UNLESS symb=s_lparen DO synerr("'(' missing")
                         lex()
                         b := 0
                         UNLESS symb=s_rparen DO b := rexplist()
                         IF b=0 DO synerr("argument expression missing")
                         UNLESS symb=s_rparen DO synerr("')' missing")
                         lex()
                         TEST h1!b=s_comma
                         THEN e1 := h2!b
                         ELSE e1 := b
                         a := list3(s_vecap, list2(s_rv, e1), a)
                         a := list4(s_fnap, a, b, 0)
                         LOOP
                      }
 
         CASE s_vecap:  p := 8; ENDCASE
         CASE s_byteap: p := 8; ENDCASE // Changed from 7 on 16 Dec 1999
         CASE s_mult:
         CASE s_div:
         CASE s_rem:    p := 6; ENDCASE
         CASE s_plus:
         CASE s_minus:  p := 5; ENDCASE
 
         CASE s_eq:CASE s_le:CASE s_ls:
         CASE s_ne:CASE s_ge:CASE s_gr:
                        IF n>=4 RESULTIS a
                        b := rnexp(4)
                        a := list3(op, a, b)
                        WHILE  s_eq<=symb<=s_ge DO
                        { LET c = b
                           op := symb
                           b := rnexp(4)
                           a := list3(s_logand, a, list3(op, c, b))
                        }
                        LOOP
 
         CASE s_lshift:
         CASE s_rshift: IF n>=4 RESULTIS a
                        a := list3(op, a, rnexp(4))
                        LOOP

         CASE s_logand: p := 3; ENDCASE
         CASE s_logor:  p := 2; ENDCASE
         CASE s_eqv:
         CASE s_neqv:   p := 1; ENDCASE
 
         CASE s_cond:   IF n>=1 RESULTIS a
                        b := rnexp(0)
                        UNLESS symb=s_comma DO
                               synerr("Bad conditional expression")
                        a := list4(s_cond, a, b, rnexp(0))
                        LOOP
      }
      
      IF n>=p RESULTIS a
      a := list3(op, a, rnexp(p))
   }
   
   RESULTIS a
}
 
LET rexplist() = VALOF
{ LET res, a = 0, rexp(0)
   LET ptr = @res
 
   WHILE symb=s_comma DO { !ptr := list3(s_comma, a, 0)
                            ptr := @h3!(!ptr)
                            a := rnexp(0)
                         }
   !ptr := a
   RESULTIS res
}
 
LET rdef(outerlevel) = VALOF
{ LET n = rnamelist()
 
   SWITCHON symb INTO
 
   { CASE s_lparen:
        { LET a = 0
           lex()
           UNLESS h1!n=s_name DO synerr("Bad formal parameter")
           IF symb=s_name DO a := rnamelist()
           UNLESS symb=s_rparen DO synerr("')' missing")
           lex()
 
           IF symb=s_be DO
           { lex()
              RESULTIS list5(s_rtdef, n, a, rcom(), 0)
           }
 
           IF symb=s_eq RESULTIS list5(s_fndef, n, a, rnexp(0), 0)
 
           synerr("Bad procedure heading")
        }
 
      DEFAULT: synerr("Bad declaration")
 
      CASE s_eq:
           IF outerlevel DO synerr("Bad outer level declaration")
           lex()
           IF symb=s_vec DO
           { UNLESS h1!n=s_name DO synerr("Name required before = VEC")
              RESULTIS list3(s_vecdef, n, rnexp(0))
           }
           RESULTIS list3(s_valdef, n, rexplist())
   }
}
 
LET rbcom() = VALOF
{ LET a, b, op, ln = 0, 0, symb, lineno
 
   SWITCHON symb INTO
   { DEFAULT: RESULTIS 0
 
      CASE s_name:CASE s_number:CASE s_string:CASE s_lparen:
      CASE s_true:CASE s_false:CASE s_lv:CASE s_rv:CASE s_vecap:
      CASE s_plus:CASE s_minus:CASE s_abs:CASE s_not:
      CASE s_table:CASE s_valof:CASE s_query:
      // All tokens that can start an expression.
            a := rexplist()
 
            IF symb=s_ass DO
            { op := symb
               lex()
               RESULTIS list4(op, a, rexplist(), ln)
            }
 
            IF symb=s_colon DO
            { UNLESS h1!a=s_name DO synerr("Unexpected ':'")
               lex()
               RESULTIS list5(s_colon, a, rbcom(), 0, ln)
            }
 
            IF h1!a=s_fnap DO
            { h1!a, h4!a := s_rtap, ln
               RESULTIS a
            }
 
            synerr("Error in command")
            RESULTIS a
 
      CASE s_goto:
      CASE s_resultis:
            RESULTIS list3(op, rnexp(0), ln)
 
      CASE s_if:
      CASE s_unless:
      CASE s_while:
      CASE s_until:
            a := rnexp(0)
            IF symb=s_do DO lex()
            RESULTIS list4(op, a, rcom(), ln)
 
      CASE s_test:
            a := rnexp(0)
            IF symb=s_do DO lex()
            b := rcom()
            UNLESS symb=s_else DO synerr("ELSE missing")
            lex()
            RESULTIS list5(s_test, a, b, rcom(), ln)
 
      CASE s_for:
         { LET i, j, k = 0, 0, 0
            lex()
            a := rname()
            UNLESS symb=s_eq DO synerr("'=' missing")
            i := rnexp(0)
            UNLESS symb=s_to DO synerr("TO missing")
            j := rnexp(0)
            IF symb=s_by DO k := rnexp(0)
            IF symb=s_do DO lex()
            RESULTIS list7(s_for, a, i, j, k, rcom(), ln)
         }
 
      CASE s_loop:
      CASE s_break:
      CASE s_return:
      CASE s_finish:
      CASE s_endcase:
            lex()
            RESULTIS list2(op, ln)
 
      CASE s_switchon:
            a := rnexp(0)
            UNLESS symb=s_into DO synerr("INTO missing")
            lex()
            RESULTIS list4(s_switchon, a, rdsect(rdseq), ln)
 
      CASE s_case:
            a := rnexp(0)
            UNLESS symb=s_colon DO synerr("Bad CASE label")
            lex()
            RESULTIS list4(s_case, a, rbcom(), ln)
 
      CASE s_default:
            lex()
            UNLESS symb=s_colon DO synerr("Bad DEFAULT label")
            lex()
            RESULTIS list3(s_default, rbcom(), ln)
 
      CASE s_lsect:
            RESULTIS rdsect(rdblockbody, FALSE)
   }
}

AND rcom() = VALOF
{ LET a = rbcom()
 
   IF a=0 DO synerr("Error in command")
 
   WHILE symb=s_repeat | symb=s_repeatwhile | symb=s_repeatuntil DO
   { LET op, ln = symb, lineno
      UNLESS op=s_repeat { a := list4(op, a, rnexp(0), ln); LOOP }
      a := list3(op, a, ln)
      lex()
   }
 
   RESULTIS a
}
/*
LET plist(x) BE
{ writef("*nName table contents, size = %n*n", nametablesize)
   FOR i = 0 TO nametablesize-1 DO
   { LET p, n = nametable!i, 0
      UNTIL p=0 DO p, n := p!1, n+1
      writef("%i3:%n", i, n)
      p := nametable!i
      UNTIL p=0 DO { writef(" %s", p+2); p := p!1  }
      newline()
   }
}
*/
LET plist(x, n, d) BE
{ LET size, ln = 0, 0
   LET v = TABLE 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

   IF x=0 DO { writes("Nil"); RETURN  }
 
   SWITCHON h1!x INTO
   { CASE s_number: writen(h2!x);         RETURN
 
      CASE s_name:   writes(x+2);          RETURN
 
      CASE s_string: writef("*"%s*"",x+1); RETURN
 
      CASE s_for:    size, ln := 6, h7!x;  ENDCASE
 
      CASE s_cond:CASE s_fndef:CASE s_rtdef:CASE s_constdef:
                     size := 4;            ENDCASE
 
      CASE s_test:
                     size, ln := 4, h5!x;  ENDCASE
 
      CASE s_needs:CASE s_section:CASE s_vecap:CASE s_byteap:CASE s_fnap:
      CASE s_mult:CASE s_div:CASE s_rem:CASE s_plus:CASE s_minus:
      CASE s_eq:CASE s_ne:CASE s_ls:CASE s_gr:CASE s_le:CASE s_ge:
      CASE s_lshift:CASE s_rshift:CASE s_logand:CASE s_logor:
      CASE s_eqv:CASE s_neqv:CASE s_comma:
      CASE s_valdef:CASE s_vecdef:
      CASE s_seq:
                     size := 3;            ENDCASE
                     
      CASE s_colon:
                     size, ln := 3, h5!x;  ENDCASE
 
      CASE s_and:
      CASE s_ass:CASE s_rtap:CASE s_if:CASE s_unless:
      CASE s_while:CASE s_until:CASE s_repeatwhile:
      CASE s_repeatuntil:
      CASE s_switchon:CASE s_case:CASE s_let:
      CASE s_manifest:CASE s_static:CASE s_global:
                     size, ln := 3, h4!x;  ENDCASE
 
      CASE s_valof:CASE s_lv:CASE s_rv:CASE s_neg:CASE s_not:
      CASE s_table:CASE s_abs:
                     size := 2;            ENDCASE
 
      CASE s_goto:CASE s_resultis:CASE s_repeat:CASE s_default:
                     size, ln := 2, h3!x;  ENDCASE
 
      CASE s_true:CASE s_false:CASE s_query:
                     size := 1;            ENDCASE
      
      CASE s_loop:CASE s_break:CASE s_return:
      CASE s_finish:CASE s_endcase:
                     size, ln := 1, h2!x;  ENDCASE

      DEFAULT:       size := 1
   }
 
   IF n=d DO { writes("Etc"); RETURN }
 
   writef("Op %n", h1!x)
   IF ln>0 DO writef("  line %n", ln)
   FOR i = 2 TO size DO { newline()
                           FOR j=0 TO n-1 DO writes( v!j )
                           writes("**-")
                           v!n := i=size->"  ","! "
                           plist(h1!(x+i-1), n+1, d)
                        }
}
 
.
SECTION "TRN"

//    TRNHDR
 
GET "b2flow.h"

GLOBAL  {
trnext:300; trans; declnames; decldyn
declstat; checkdistinct; addname; cellwithname
transdef; scanlabel
decllabels; undeclare; trnerr
jumpcond; transswitch; transfor
assign; load; fnbody; loadlv; loadlist
isconst; evalconst; nameld; namelv
nextlab; labnumber; newblk
dvec; dvece; dvecp; dvect; varid
caselist; casecount; comline; procname; inproc; argno
resultvar; resultlab; defaultlab; endcaselab
looplab; breaklab
outstring; out1; out2; out3; out4; wrn
wrname; argvar; argp; argt
}

LET nextlab() = VALOF
{ labnumber := labnumber + 1
  RESULTIS labnumber
}
 
AND trnerr(mess, a) BE
{ writes("Error ")
  UNLESS procname=0 DO writef("in %s ", @h3!procname)
  writef("near line %n:    ", comline)
  writef(mess, a)
  newline()
  errcount := errcount + 1
  IF errcount >= errmax DO { writes("*nCompilation aborted*n")
                             longjump(fin_p, fin_l)
                           }
}

AND newblk(x, y, z) = VALOF
{ LET p = dvect - 3
  IF dvece>p DO { errmax := 0        // Make it fatal.
                  trnerr("More workspace needed")
                }
  p!0, p!1, p!2 := x, y, z
  dvect := p
  RESULTIS p
}

AND translate(x) BE
{ LET v = VEC 500
  argvar, argp, argt := v, v, v+500
  dvec,  dvect := treevec, treep
  h1!dvec, h2!dvec, h3!dvec := 0, 0, 0
  dvece := dvec+3
  dvecp := dvece
  varid := 0
  FOR i = 0 TO nametablesize-1 DO
  { LET name = nametable!i
    UNTIL name=0 DO
    { LET next = h2!name
      h2!name := 0 // Mark undeclared
      name := next
    }
  }

  caselist, casecount, defaultlab := 0, -1, 0
  resultlab, breaklab, looplab, endcaselab := -2, -2, -2, -2
  comline, procname, inproc, argno, labnumber := 1, 0, FALSE, 0, 0

  WHILE x~=0 & (h1!x=s_section | h1!x=s_needs) DO
  { LET op, a = h1!x, h2!x
    out1(op)
    outstring(@h2!a)
    x:=h3!x
  }

  trans(x, 0)
}

LET trnext(next) BE { IF next<0 DO out1(s_rtrn)
                      IF next>0 DO out2(s_jump, next)
                    }
 
LET trans(x, next) BE
// x       is the command to translate
// next<0  compile x followed by RTRN or FNRN
// next>0  compile x followed by JUMP next
// next=0  compile x only
{ LET sw = FALSE
  IF x=0 DO { trnext(next); RETURN }
 
  SWITCHON h1!x INTO
  { DEFAULT: trnerr("Compiler error in Trans"); RETURN
 
    CASE s_let:
      { LET cc = casecount
        LET e = dvece
        casecount := -1 // Disallow CASE and DEFAULT labels
        comline := h4!x
        declnames(h2!x)
        checkdistinct(e)
        comline := h4!x
        transdef(h2!x)
        decllabels(h3!x)
        trans(h3!x, next)
        casecount := cc
        undeclare(e)
        RETURN
     }
 
      CASE s_static:
      CASE s_global:
      CASE s_manifest:
      { LET cc = casecount
        LET e = dvece
        AND op = h1!x
        AND y = h2!x
        LET prevk = -1
         
        casecount := -1 // Disallow CASE and DEFAULT labels
        comline := h4!x
 
        UNTIL y=0 DO
        { LET n = h4!y -> evalconst(h4!y), prevk+1
          prevk := n
          varid := varid + 1 // Allocate next variable id
          // Compile:  STATIC Vi Kn
          //           GLOBAL Vi Gn
          // or        MANIFEST Vi Kn
          out3(op, varid, n)
          addname(h3!y, op, varid, n)
          y := h2!y
        }
 
        decllabels(h3!x)
        trans(h3!x, next)
        casecount := cc
        undeclare(e)
        RETURN
      }
 
 
      CASE s_ass:
         comline := h4!x
         assign(h2!x, h3!x)
         trnext(next)
         RETURN
 
      CASE s_rtap:
       { LET ap = argp
         comline := h4!x
         loadlist(h3!x)
         out3(s_rtap, load(h2!x), argp-ap)
         FOR p = ap TO argp-1 DO out1(!p)
         argp := ap
         trnext(next)
         RETURN
      }
 
      CASE s_goto:
         comline := h3!x
         out2(s_goto, load(h2!x))
         RETURN
 
      CASE s_colon:
         comline := h5!x
         out2(s_lab, h4!x)
         trans(h3!x, next)
         RETURN
 
      CASE s_unless: sw := TRUE
      CASE s_if:
         comline := h4!x
         TEST next>0 THEN { jumpcond(h2!x, sw, next)
                             trans(h3!x, next)
                          }
                     ELSE { LET l = nextlab()
                             jumpcond(h2!x, sw, l)
                             trans(h3!x, next)
                             out2(s_lab, l)
                             trnext(next)
                          }
         RETURN
 
      CASE s_test:
      { LET l, m = nextlab(), 0
         comline := h5!x
         jumpcond(h2!x, FALSE, l)
         
         TEST next=0 THEN { m := nextlab(); trans(h3!x, m) }
                     ELSE trans(h3!x, next)
                     
         out2(s_lab, l)
         trans(h4!x, next)
         UNLESS m=0 DO out2(s_lab, m)
         RETURN
      }
 
      CASE s_loop:
         comline := h2!x
         IF looplab<0 DO trnerr("Illegal use of LOOP")
         IF looplab=0 DO looplab := nextlab()
         out2(s_jump, looplab)
         RETURN
 
      CASE s_break:
         comline := h2!x
         IF breaklab=-2 DO trnerr("Illegal use of BREAK")
         IF breaklab=-1 DO { out1(s_rtrn); RETURN }
         IF breaklab= 0 DO breaklab := nextlab()
         out2(s_jump, breaklab)
         RETURN
 
      CASE s_return:
         comline := h2!x
         out1(s_rtrn)
         RETURN
 
      CASE s_finish:
         comline := h2!x
         out1(s_finish)
         RETURN
 
      CASE s_resultis:
         comline := h3!x
         IF resultlab=-1 DO { fnbody(h2!x); RETURN }
         UNLESS resultlab>0 DO trnerr("RESULTIS out of context")
         out3(s_ld, resultvar, load(h2!x))
         out2(s_jump, resultlab)
         RETURN
 
      CASE s_while: sw := TRUE
      CASE s_until:
      { LET l, m = nextlab(), next
         LET bl, ll = breaklab, looplab
         comline := h4!x
         breaklab, looplab := next, 0
         IF next<=0 DO m := nextlab()
         IF next =0 DO breaklab := m
         jumpcond(h2!x, ~sw, m)
         out2(s_lab, l)
         trans(h3!x, 0)
         UNLESS looplab=0 DO out2(s_lab, looplab)
         comline := h4!x
         jumpcond(h2!x, sw, l)
         IF next<=0 DO out2(s_lab, m)
         trnext(next)
         breaklab, looplab := bl, ll
         RETURN
      }
 
      CASE s_repeatwhile: sw := TRUE
      CASE s_repeatuntil:
      { LET l, bl, ll = nextlab(), breaklab, looplab
         comline := h4!x
         breaklab, looplab := next, 0
         out2(s_lab, l)
         trans(h2!x, 0)
         UNLESS looplab=0 DO out2(s_lab, looplab)
         comline := h4!x
         jumpcond(h3!x, sw, l)

//       UNLESS breaklab=0 DO out2(s_lab, breaklab)
         IF next=0 & breaklab>0 DO out2(s_lab, breaklab)

         trnext(next)
         breaklab, looplab := bl, ll
         RETURN
      }
 
      CASE s_repeat:
      { LET bl, ll = breaklab, looplab
         comline := h4!x
         breaklab, looplab := next, nextlab()
         out2(s_lab, looplab)

         trans(h2!x, looplab)

         IF next=0 & breaklab>0 DO out2(s_lab, breaklab)

         breaklab, looplab := bl, ll
         RETURN
      }
 
      CASE s_case:
      { LET l, k, cl = nextlab(), ?, caselist
         comline := h4!x
         k := evalconst(h2!x)
         IF casecount<0 DO trnerr("CASE label out of context")
         UNTIL cl=0 DO
         { IF h2!cl=k DO trnerr("'CASE %n:' occurs twice", k)
            cl := h1!cl
         }
         caselist := newblk(caselist, k, l)
         casecount := casecount + 1
         out2(s_lab, l)
         trans(h3!x, next)
         RETURN
      }
 
      CASE s_default:
         comline := h3!x
         IF casecount<0 | defaultlab~=0 DO trnerr("Bad DEFAULT label")
         defaultlab := nextlab()
         out2(s_lab, defaultlab)
         trans(h2!x, next)
         RETURN
 
      CASE s_endcase:
         comline := h2!x
         IF endcaselab=-2 DO trnerr("Illegal use of ENDCASE")
         IF endcaselab=-1 DO out1(s_rtrn)
         // endcaselab is never equal to 0
         IF endcaselab>0  DO out2(s_jump, endcaselab)
         RETURN
 
      CASE s_switchon:
         transswitch(x, next)
         RETURN
 
      CASE s_for:
         transfor(x, next)
         RETURN
 
      CASE s_seq:
         trans(h2!x, 0)
         x := h3!x
   }
} REPEAT

LET declnames(x) BE UNLESS x=0 SWITCHON h1!x INTO
 
{ DEFAULT:       trnerr("Compiler error in Declnames")
                 RETURN
 
  CASE s_vecdef:
  CASE s_valdef: decldyn(h2!x, s_local)
                 RETURN
 
  CASE s_rtdef:
  CASE s_fndef:  h5!x := nextlab()
                 declstat(h2!x, h5!x)
                 RETURN
 
  CASE s_and:    declnames(h2!x)
                 comline := h4!x
                 declnames(h3!x)
}
 
AND decldyn(x, kind) BE UNLESS x=0 DO
{ IF h1!x=s_name  DO { varid := varid + 1
                       TEST kind=s_arg
                       THEN { out3(s_arg, varid, argno); argno := argno+1 }
                       ELSE out2(s_local, varid)
                       addname(x, kind, varid, 0)
                       RETURN
                     }
 
  IF h1!x=s_comma DO { varid := varid + 1
                       TEST kind=s_arg
                       THEN { out3(s_arg, varid, argno); argno := argno+1 }
                       ELSE out2(s_local, varid)
                       addname(h2!x, kind, varid, 0)
                       decldyn(h3!x, kind)
                       RETURN
                     }
 
  trnerr("Compiler error in Decldyn")
}
 
AND declstat(x, lab) BE
{ LET c = cellwithname(x)
  LET k = h2!c&255
 
  TEST k=s_global THEN { LET gn = h3!c
                         LET vid = h2!c>>8
                         out3(s_globinit, gn, lab)
                         //addname(x, s_global, vid, gn)
                       }
                  ELSE { varid := varid + 1
                         addname(x, s_label, varid, lab)
                       }
}
 
AND decllabels(x) BE
{ LET e = dvece
   scanlabels(x)
   checkdistinct(e)
}
 
AND checkdistinct(p) BE
{ LET lim = dvece - 3
   FOR q = p TO lim-3 BY 3 DO
   { LET n = h1!q
      FOR c = q+3 TO lim BY 3 DO
          IF h1!c=n DO trnerr("Name %s defined twice", @h3!n)
   }
}
 
AND addname(name, k, vid, a) BE
{ LET p = dvece + 3
  IF p>dvect DO trnerr("More workspace needed")
  h1!dvece, h2!dvece, h3!dvece := name, k+(vid<<8), a
  h2!name := dvece        // Remember the declaration
  dvece := p
  wrname(name, vid)
}
 
AND undeclare(e) BE 
{ FOR t = e TO dvece-3 BY 3 DO
  { LET name = h1!t
    h2!name := 0   // Forget its declaration
  }
  dvece := e
}

AND cellwithname(n) = VALOF
{ LET t = h2!n
  UNLESS t DO  // Has it been looked up before
  { t := dvece
    t := t - 3 REPEATUNTIL h1!t=n | h1!t=0
    h2!n := t  // Associate the name with declaration item
  }
  RESULTIS t
}
 
AND scanlabels(x) BE UNLESS x=0 SWITCHON h1!x INTO
 
{ CASE s_colon:   comline := h5!x
                   h4!x := nextlab()
                   declstat(h2!x, h4!x)
 
   CASE s_if: CASE s_unless: CASE s_while: CASE s_until:
   CASE s_switchon: CASE s_case:
                   scanlabels(h3!x)
                   RETURN
 
   CASE s_seq:     scanlabels(h3!x)
 
   CASE s_repeat: CASE s_repeatwhile: CASE s_repeatuntil:
   CASE s_default: scanlabels(h2!x)
                   RETURN
 
   CASE s_test:    scanlabels(h3!x)
                   scanlabels(h4!x)
   DEFAULT:        RETURN
}
 
AND transdef(x) BE
{ LET ln = comline
  transdyndefs(x)
  comline := ln
  IF statdefs(x) TEST inproc
                 THEN { LET l= nextlab()
                        out2(s_jump, l)
                        transstatdefs(x)
                        out2(s_lab, l)
                      }
                 ELSE transstatdefs(x)
  comline := ln
}
 
 
AND transdyndefs(x) BE SWITCHON h1!x INTO
{ CASE s_and:      transdyndefs(h2!x)
                   comline := h4!x
                   transdyndefs(h3!x)
                   RETURN
 
  CASE s_vecdef: { LET upb = evalconst(h3!x)
                   LET c = cellwithname(h2!x)
                   LET vid = h2!c>>8
                   varid := varid + 1
                   out3(s_vec, varid, upb)
                   out3(s_ld, vid, varid)
                   RETURN
                 }
 
  CASE s_valdef: assign(h2!x, h3!x)
 
  DEFAULT:       RETURN
}
 
AND transstatdefs(x) BE SWITCHON h1!x INTO
{ CASE s_and:  transstatdefs(h2!x)
               comline := h4!x
               transstatdefs(h3!x)
               RETURN
 
  CASE s_fndef:
  CASE s_rtdef:
            { LET e, p = dvece, dvecp
              AND oldpn, oldinproc, oldan = procname, inproc, argno
              AND bl, ll = breaklab,  looplab
              AND rl, el = resultlab, endcaselab
              AND cl, cc = caselist,  casecount
              breaklab,  looplab    := -2, -2
              resultlab, endcaselab := -2, -2
              caselist,  casecount  :=  0, -1
              procname, inproc, argno := h2!x, TRUE, 0

              out2(s_entry, h5!x)
              outstring(@h3!procname)
              dvecp := dvece
              decldyn(h3!x, s_arg)
              checkdistinct(e)
              decllabels(h4!x)
              TEST h1!x=s_rtdef THEN trans(h4!x, -1)
                                ELSE fnbody(h4!x)
              out1(s_endproc)
 
              breaklab,  looplab    := bl, ll
              resultlab, endcaselab := rl, el
              caselist,  casecount  := cl, cc
              procname, inproc, argno := oldpn, oldinproc, oldan
              dvecp := p
              undeclare(e)
            }
 
  DEFAULT:    RETURN
}
 
AND statdefs(x) = h1!x=s_fndef | h1!x=s_rtdef -> TRUE,
                  h1!x ~= s_and               -> FALSE,
                  statdefs(h2!x)              -> TRUE,
                  statdefs(h3!x)
 
 
LET jumpcond(x, b, l) BE
{ LET sw = b

  SWITCHON h1!x INTO
  { CASE s_false:  b := NOT b
    CASE s_true:   IF b DO out2(s_jump, l)
                   RETURN
 
    CASE s_not:    jumpcond(h2!x, NOT b, l)
                   RETURN
 
    CASE s_logand: sw := NOT sw
    CASE s_logor:  TEST sw THEN { jumpcond(h2!x, b, l)
                                  jumpcond(h3!x, b, l)
                                  RETURN
                                }
 
                           ELSE { LET m = nextlab()
                                  jumpcond(h2!x, NOT b, m)
                                  jumpcond(h3!x, b, l)
                                  out2(s_lab, m)
                                  RETURN
                                }
 
    DEFAULT:       out3(b -> s_jt, s_jf, load(x), l)
                   RETURN
  }
}
 
AND transswitch(x, next) BE
{ LET cl, cc = caselist, casecount 
   LET dl, el = defaultlab, endcaselab
   LET l, dlab = nextlab(), ?
   caselist, casecount, defaultlab := 0, 0, 0
   endcaselab := next=0 -> nextlab(), next
 
   comline := h4!x
   out2(s_jump, l)
   trans(h3!x, endcaselab)
 
   comline := h4!x

   dlab := defaultlab>0 -> defaultlab,
           endcaselab>0 -> endcaselab,
           nextlab()

   out2(s_lab, l)
   out4(s_switchon, load(h2!x), casecount, dlab) 
   UNTIL caselist=0 DO { out2(h2!caselist, h3!caselist)
                         caselist := h1!caselist
                       }

   IF next=0                DO    out2(s_lab, endcaselab)
   IF next<0 & defaultlab=0 DO { out2(s_lab, dlab)
                                 out1(s_rtrn)
                               }

   defaultlab, endcaselab := dl, el
   caselist,   casecount  := cl, cc
}
 
AND transfor(x, next) BE
{ LET e, m, blab = dvece, nextlab(), 0
  LET bl, ll = breaklab, looplab
  LET cc = casecount
  LET k, n, step = 0, 0, 1
  LET cntlvar, limvar, stepvar = varid+1, ?, ?
  varid := cntlvar

  casecount := -1  // Disallow CASE and DEFAULT labels.   
  breaklab, looplab := next, 0
   
  comline := h7!x
 
  addname(h2!x, s_local, cntlvar, 0)
  out3(s_ld, cntlvar, load(h3!x))  // Initialize the control variable
  limvar := load(h4!x)

  UNLESS h5!x DO h5!x := TABLE s_number, 1
  stepvar := load(h5!x)
 
  TEST isconst(h3!x) & isconst(h4!x) // check for constant limits 
  THEN { LET initval = evalconst(h3!x)
         LET limval  = evalconst(h4!x)
         LET stepval = evalconst(h5!x)

         IF stepval>=0 & initval>limval | stepval<0 & initval<limval DO
         { TEST next<0
           THEN out1(s_rtrn)
           ELSE TEST next>0
                THEN out2(s_jump, next)
                ELSE { blab := breaklab>0 -> breaklab, nextlab()
                       out2(s_jump, blab)
                     }
         }
       }
  ELSE { IF next<=0 DO blab := nextlab()
         varid := varid+1
         out4((step>=0 -> s_gr, s_ls), varid, cntlvar, limvar)
         out3(s_jt, varid, (next>0 -> next, blab))
       }

  IF breaklab=0 & blab>0 DO breaklab := blab
   
  comline := h7!x
  decllabels(h6!x)
  comline := h7!x
  out2(s_lab, m)
  trans(h6!x, 0)
  UNLESS looplab=0 DO out2(s_lab, looplab)
  out4(s_plus, cntlvar, cntlvar, stepvar)
  varid := varid + 1
  out4((step>=0 -> s_le, s_ge), varid, cntlvar, limvar)
  out3(s_jt, varid, m)
 
  IF next<=0 TEST blab>0 
             THEN                  out2(s_lab, blab)
             ELSE IF breaklab>0 DO out2(s_lab, breaklab)
  trnext(next)
  casecount := cc
  breaklab, looplab := bl, ll
  undeclare(e)
}
 
LET load(x) = VALOF
{ LET op = h1!x

  IF isconst(x) DO
  { varid := varid + 1
    out3(s_manifest, varid, evalconst(x))
    RESULTIS varid
  }
 
  SWITCHON op INTO
  { DEFAULT:          trnerr("Compiler error in Load")
                      RESULTIS 0
 
    CASE s_byteap:    op:=s_getbyte

    CASE s_div: CASE s_rem: CASE s_minus:
    CASE s_ls: CASE s_gr: CASE s_le: CASE s_ge:
    CASE s_lshift: CASE s_rshift:
    CASE s_vecap: CASE s_mult: CASE s_plus: CASE s_eq: CASE s_ne:
    CASE s_logand: CASE s_logor: CASE s_eqv: CASE s_neqv:
                    { LET a = load(h2!x)
                      LET b = load(h3!x)
                      varid := varid + 1
                      out4(op, varid, a, b)
                      RESULTIS varid
                    }
 
    CASE s_neg: CASE s_not: CASE s_rv: CASE s_abs:
                   { LET a = load(h2!x)
                     varid := varid + 1
                     out3(op, varid, a)
                     RESULTIS varid
                   }
 
    CASE s_true: CASE s_false: CASE s_query:
                     varid := varid + 1
                     out2(op, varid)
                     RESULTIS varid
 
    CASE s_lv:       RESULTIS loadlv(h2!x)
 
    CASE s_number:   varid := varid + 1
                     out3(s_manifest, varid, h2!x)
                     RESULTIS varid
 
    CASE s_string:   varid := varid + 1
                     out2(s_string, varid)
                     outstring(@ h2!x)
                     RESULTIS varid
 
    CASE s_name:     RESULTIS nameld(x)
 
    CASE s_valof: { LET e, rl, cc = dvece, resultlab, casecount
                    LET rvar = resultvar
                    LET res = varid + 1
                    varid := res
                    resultvar := varid
                    casecount := -1 // Disallow CASE & DEFAULT labels
                    resultlab := nextlab()
                    decllabels(h2!x)
                    trans(h2!x, 0)
                    out2(s_lab, resultlab)
                    resultvar := rvar
                    resultlab, casecount := rl, cc
                    undeclare(e)
                    RESULTIS res
                  }

    CASE s_fnap:  { LET ap = argp
                    loadlist(h3!x)
                    varid := varid + 1
                    out4(s_fnap, varid, load(h2!x), argp-ap)
                    FOR p = ap TO argp-1 DO out1(!p)
                    argp := ap
                    RESULTIS varid
                  }
 
    CASE s_cond:  { LET l, m = nextlab(), nextlab()
                    LET res = varid + 1
                    varid := varid
                    jumpcond(h2!x, FALSE, m)
                    out3(s_ld, res, load(h3!x))
                    out2(s_jump,l)
                    out2(s_lab, m)
                    out3(s_ld, res, load(h4!x))
                    out2(s_lab, l)
                    RETURN
                  }
 
    CASE s_table: { LET res = varid + 1
                    LET n, p = 1, h2!x
                    varid := res
                    WHILE h1!p=s_comma DO n, p := n+1, h3!p
                    
                    out3(s_table, res, n)
                    x := h2!x
                    WHILE h1!x=s_comma DO
                    { out1(evalconst(h2!x))
                      x := h3!x
                    }
                    out1(evalconst(x))
                    RESULTIS res
                  }
  }
}

AND fnbody(x) BE SWITCHON h1!x INTO
{ DEFAULT:        out2(s_fnrn, load(x))
                  RETURN
                   
  CASE s_valof: { LET e, rl, cc = dvece, resultlab, casecount
                  casecount := -1 // Disallow CASE & DEFAULT labels
                  resultlab := -1
                  decllabels(h2!x)
                  trans(h2!x, -1)
                  resultlab, casecount := rl, cc
                  undeclare(e)
                  RETURN
                }

  CASE s_cond:  { LET l = nextlab()
                  jumpcond(h2!x, FALSE, l)
                  fnbody(h3!x)
                  out2(s_lab, l)
                  fnbody(h4!x)
                }
}
 
 
AND loadlv(x) = VALOF
{ UNLESS x=0 SWITCHON h1!x INTO
  { DEFAULT:         ENDCASE
 
    CASE s_name:  { LET res = varid + 1
                    varid := res
                    out3(s_llv, res, namelv(x))
                    RESULTIS res
                  }
 
    CASE s_rv:      RESULTIS load(h2!x)
 
    CASE s_vecap: { LET res = varid + 1
                    varid := res
                    out4(s_plus, varid, load(h2!x), load(h3!x))
                    RESULTIS res
                  }
  }

  trnerr("Ltype expression needed")
  RESULTIS 0
}
 
AND loadlist(x) BE UNLESS x=0 TEST h1!x=s_comma
                   THEN { loadlist(h2!x); loadlist(h3!x) }
                   ELSE TEST argp>=argt
                        THEN trnerr("Too many function arguments*n")
                        ELSE { !argp := load(x)
                               argp := argp+1
                             }

LET isconst(x) = VALOF
{ IF x=0 RESULTIS FALSE
 
  SWITCHON h1!x INTO
  { CASE s_name:
        { LET c = cellwithname(x)
          RESULTIS (h2!c&255)=s_manifest
        }
 
    CASE s_number:
    CASE s_true:
    CASE s_false:  RESULTIS TRUE
 
    CASE s_neg:
    CASE s_abs:
    CASE s_not:    RESULTIS isconst(h2!x)
       
    CASE s_mult:
    CASE s_div:
    CASE s_rem:
    CASE s_plus:
    CASE s_minus:
    CASE s_lshift:
    CASE s_rshift:
    CASE s_logor:
    CASE s_logand:
    CASE s_eqv:
    CASE s_neqv:   IF isconst(h2!x) & isconst(h3!x) RESULTIS TRUE

    DEFAULT:       RESULTIS FALSE
  }
}

LET evalconst(x) = VALOF
{ LET a, b = 0, 0

  IF x=0 DO { trnerr("Compiler error in Evalconst")
              RESULTIS 0
            }
 
  SWITCHON h1!x INTO
  { CASE s_name:
        { LET c = cellwithname(x)
          IF (h2!c&255)=s_manifest RESULTIS h3!c
          trnerr("Variable %s in manifest expression", @h3!x)
          RESULTIS 0
        }
 
    CASE s_number: RESULTIS h2!x
    CASE s_true:   RESULTIS TRUE
    CASE s_false:  RESULTIS FALSE
    CASE s_query:  RESULTIS 0
 
    CASE s_neg:
    CASE s_abs:
    CASE s_not:    a := evalconst(h2!x)
                   ENDCASE
       
    CASE s_mult:
    CASE s_div:
    CASE s_rem:
    CASE s_plus:
    CASE s_minus:
    CASE s_lshift:
    CASE s_rshift:
    CASE s_logor:
    CASE s_logand:
    CASE s_eqv:
    CASE s_neqv:   a, b := evalconst(h2!x), evalconst(h3!x)
                   ENDCASE

    DEFAULT:
  }
    
  SWITCHON h1!x INTO
  { CASE s_neg:    RESULTIS  -  a
    CASE s_abs:    RESULTIS ABS a
    CASE s_not:    RESULTIS NOT a
       
    CASE s_mult:   RESULTIS a   *    b
    CASE s_plus:   RESULTIS a   +    b
    CASE s_minus:  RESULTIS a   -    b
    CASE s_lshift: RESULTIS a   <<   b
    CASE s_rshift: RESULTIS a   >>   b
    CASE s_logor:  RESULTIS a   |    b
    CASE s_logand: RESULTIS a   &    b
    CASE s_eqv:    RESULTIS a  EQV   b
    CASE s_neqv:   RESULTIS a  NEQV  b
    CASE s_div:    UNLESS b=0 RESULTIS a   /    b
    CASE s_rem:    UNLESS b=0 RESULTIS a  REM   b
       
    DEFAULT:
  }

  trnerr("Error in manifest expression")
  RESULTIS 0
}

AND assign(x, y) BE
{ IF x=0 | y=0 DO { trnerr("Compiler error in assign")
                    RETURN
                  }
   
  UNLESS (h1!x=s_comma)=(h1!y=s_comma) DO
  { trnerr("Bad simultaneous assignment")
    RETURN
  }
 
  SWITCHON h1!x INTO
  { CASE s_comma:  assign(h2!x, h2!y)
                   assign(h3!x, h3!y)
                   RETURN
 
    CASE s_name:   out3(s_ld, namelv(x), load(y))
                   RETURN
 
    CASE s_byteap: { LET a = load(y)
                     LET b = load(h2!x)
                     LET c = load(h3!x)
                     out4(s_putbyte, a, b, c)
                     RETURN
                   }
 
    CASE s_rv:
    CASE s_vecap:  { LET a = loadlv(x)
                     out3(s_stind, a, load(y))
                     RETURN
                   }
 
    DEFAULT:       trnerr("Ltype expression needed")
  }
}
 
 
AND nameld(x) = VALOF
{ LET c = cellwithname(x)
  LET k, vid = h2!c&255, h2!c>>8
  LET name = @h3!x
 
  SWITCHON k INTO
  { DEFAULT:        trnerr("Name '%s' not declared", name)
   
    CASE s_arg:
    CASE s_local:   IF c<dvecp DO
                       trnerr("Dynamic free variable '%s' used", name)
 
    CASE s_global:
    CASE s_label:
    CASE s_manifest:
    CASE s_static:  RESULTIS vid
  }
}

AND namelv(x) = VALOF
{ LET c = cellwithname(x)
  LET k, vid = h2!c&255, h2!c>>8
  LET name = @h3!x
 
  SWITCHON k INTO
  { DEFAULT:         trnerr("Name '%s' not declared", name)

    CASE s_arg:
    CASE s_local:    IF c<dvecp DO
                       trnerr("Dynamic free variable '%s' used", name)
 
    CASE s_global:
    CASE s_static:   RESULTIS vid
 
    CASE s_label:    trnerr("Misuse of entry name '%s'", name)
                     RESULTIS 0

    CASE s_manifest: trnerr("Misuse of MANIFEST name '%s'", name)
                     RESULTIS 0
  }
}

 
AND out1(x) BE wrn(x)
AND out2(x, y) BE { wrn(x); wrn(y) }
AND out3(x, y, z) BE { wrn(x); wrn(y); wrn(z) }
AND out4(x, y, z, t) BE { wrn(x); wrn(y); wrn(z); wrn(t) }
 
AND outstring(s) BE FOR i = 0 TO s%0 DO wrn(s%i)

AND wrname(x, vid) BE
{ out2(s_name, vid)
  outstring(x+2)
}

AND wrn(n) BE 
{ selectoutput(flowout)
  writef("%n*n", n)
  selectoutput(sysprint)
}


