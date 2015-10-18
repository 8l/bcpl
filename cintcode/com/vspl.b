/*
This is a compiler and interpreter for the language VSPL
implemented in BCPL

(c) Martin Richards 20 March 2003
*/


GET "libhdr"
 
MANIFEST {  // Lexical tokens, parse tree operators and op-codes

Num=1; Name; String; True; False
Valof; Fnap; Lv; Ind; Vecap
Neg; Not; Mul; Div; Mod; Add; Sub
Eq; Ne; Le; Ge; Lt; Gt; Lsh; Rsh; And; Or; Xor
Comma; Fndef; Rtdef; Assign; Rtap; Resultis
Test; If; Unless; While; Until; For; Return; Seq
Let; Vec; Static; Statvec; Decl; Var
Lparen; Rparen; Lsquare; Rsquare; Lcurly; Rcurly
To; Do; Then; Else; Be; Eof; Semicolon
Rtrn; Fnrn; Addr; Local; Lab; Data; Jt; Jf; Jump;
Ln; Lp; Llp; Ll; Laddr; Sp; Sl; Stind; Lres
Entry; Stack; Printf; Sys; Halt
}
 
GLOBAL { 
rec_p:ug; rec_l; fin_p; fin_l
fatalerr; synerr; trnerr; errcount; errmax
progstream; tostream
mk1; mk2; mk3; mk4; mk5; mk6
newvec; treep; treevec
optTokens; optTree; optCode; optTrace

// Globals used in LEX
chbuf; charv; ch; rch; lex; token; lexval; wordnode
wrchbuf; chcount; lineno
dsw; declsyswords; namestart; nametable; lookupword
rdstrch; rdtag

// Globals used in SYN
checkfor; rdprog; rdblockbody
rnamelist; rstatlist; rname
rdef; rncom; rcom
formtree; plist
rexplist; rdseq
rnexp; rexp; rbexp
 
// Globals used in TRN and the interpreter
 
trnext:300; trprog; trcom; decldyn
declstatnames; checkdistinct; addname; cellwithname
trdecl; undeclare; jumpcond
assign; load; fnbody; loadlist; transname
dvec; dvece; dvecp; dvect
comline; procname; resultlab; ssp
outf; outfn; outfl; outfs; outentry
outlab; outvar; outstatvec; outstring; opstr; hasOperand
mem; memt; regs
codev; codep; codet; datav; datap; datat; stack; stackt
labv; refv; labmax; putc; putd; putref
setlab; nextlab; labnumber; resolvelabels
interpret; printf
}

MANIFEST {                         //  Selectors
h1=0; h2=1; h3=2; h4=3; h5=4; h6=5
nametablesize = 541
c_tab         =   9
c_newline     =  10
}
 
LET start() = VALOF
{ LET treesize = 0
  AND memsize = 0
  AND argv = VEC 50
  AND argform =
        "PROG/A,TO=-o/K,TOKENS=-l/S,TREE=-p/S,CODE=-c/S,TRACE=-t/S"
  LET stdout = output()

  errmax   := 2
  errcount := 0
  fin_p, fin_l := level(), fin

  treevec, labv, refv, mem := 0, 0, 0, 0
  progstream, tostream := 0, 0
   
  writef("*nVSPL (26 Apl 2012) BCPL Version*n")
 
  IF rdargs(argform, argv, 50)=0 DO fatalerr("Bad arguments*n")

  treesize := 10000
  memsize  := 50000

  progstream := findinput(argv!0)      // PROG

  IF progstream=0 DO fatalerr("Trouble with file %s*n", argv!0)

  selectinput(progstream)
 
  IF argv!1                            // TO      -o
  DO { tostream := findoutput(argv!1)
       IF tostream=0 DO fatalerr("Trouble with code file %s*n", argv!1)
     }

  optTokens := argv!2                  // TOKENS  -l
  optTree   := argv!3                  // TREE    -p
  optCode   := argv!4                  // CODE    -c
  optTrace  := argv!5                  // TRACE   -t

  treevec := getvec(treesize)
  mem     := getvec(memsize)
  memt    := memsize
  labv := getvec(1000)
  refv := getvec(1000)
  labmax := 1000

  UNLESS treevec & mem & labv & refv DO
     fatalerr("Insufficient memory*n")
   
  UNLESS tostream DO tostream := stdout
  selectoutput(tostream)

  { LET tree = 0
    LET b = VEC 64/bytesperword
    chbuf := b
    FOR i = 0 TO 63 DO chbuf%i := 0
    chcount, lineno := 0, 1
    rch()
 
    treep := treevec + treesize

    tree := formtree()              // Perform Syntax Analysis
    IF optTokens GOTO fin

    IF optTree DO { writes("Parse Tree*n")
                    plist(tree, 0, 20)
                    newline()
                  }
  
    IF errcount GOTO fin

    regs  := 10
    codev := 100
    codep := codev
    codet := 10000
    datav := codet
    datap := datav
    datat := memt

    FOR i = 0 TO memt DO mem!i := 0

    trprog(tree)                    // Translate the tree

    stack := datap
    stackt := memt

    IF errcount GOTO fin
    { LET rv = mem+regs
      AND sv = mem+stack
      rv!0 := 0        // result register
      rv!1 := stack    // p pointer
      rv!2 := stack+2  // sp
      rv!3 := codev    // pc
      rv!4 := maxint   // count

      sv!0, sv!1, sv!2 := 0, 0, 0
 
      { LET ret = interpret(regs, mem)   // Execute the interpreter
        IF ret DO writef("Return code %n*n", ret)
        writef("*nInstructions executed: %n*n", maxint-rv!4)
      }
    }
  }
   
fin:
  IF treevec       DO freevec(treevec)
  IF mem           DO freevec(mem)
  IF labv          DO freevec(labv)
  IF refv          DO freevec(refv)
  IF progstream    DO { selectinput(progstream); endread()  }
  IF tostream      DO { selectoutput(tostream)
                        UNLESS tostream=stdout DO  endwrite() }

  selectoutput(stdout)
  result2 := 0 // No reason given
  RESULTIS errcount=0 -> 0, 20
}

LET lex() BE
{ SWITCHON ch INTO
  { CASE '*p': CASE '*n':
                 lineno := lineno + 1
    CASE '*c': CASE '*t': CASE '*s':
                 rch()
                 LOOP

    CASE '0':CASE '1':CASE '2':CASE '3':CASE '4':
    CASE '5':CASE '6':CASE '7':CASE '8':CASE '9':
                lexval := 0
                WHILE '0'<=ch<='9' DO
                { lexval := 10*lexval + ch - '0'
                  rch()
                }
                token := Num
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
                token := lookupword(rdtag())
                RETURN
 
    CASE '{': token := Lcurly;    BREAK
    CASE '}': token := Rcurly;    BREAK
    CASE '[': token := Lsquare;   BREAK
    CASE ']': token := Rsquare;   BREAK
    CASE '(': token := Lparen;    BREAK
    CASE ')': token := Rparen;    BREAK 
    CASE '!': token := Ind;       BREAK
    CASE '@': token := Lv;        BREAK
    CASE '+': token := Add;       BREAK
    CASE '-': token := Sub;       BREAK
    CASE ',': token := Comma;     BREAK
    CASE ';': token := Semicolon; BREAK
    CASE '&': token := And;       BREAK
    CASE '|': token := Or;        BREAK
    CASE '=': token := Eq;        BREAK
    CASE '**':token := Mul;       BREAK
    CASE '^': token := Xor;       BREAK
 
    CASE '/':   rch()
                IF ch='/' DO
                { rch() REPEATUNTIL ch='*n' | ch=endstreamch
                  LOOP
                }
                token := Div
                RETURN
 
    CASE '~':   rch()
                IF ch='=' DO { token := Ne;  BREAK }
                token := Not
                RETURN
 
    CASE '<':   rch()
                IF ch='=' DO { token := Le;  BREAK }
                IF ch='<' DO { token := Lsh; BREAK }
                token := Lt
                RETURN
 
    CASE '>':   rch()
                IF ch='=' DO { token := Ge;  BREAK }
                IF ch='>' DO { token := Rsh; BREAK }
                token := Gt
                RETURN
 
    CASE ':':   rch()
                IF ch='=' DO { token := Assign;  BREAK }
                synerr("'=' expected after ':'")
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
                h1!wordnode := String
                FOR i = 0 TO len DO (@h2!wordnode)%i := charv%i
                token := String
                BREAK
              }
 
    CASE '*'':  rch()
                lexval := rdstrch()
                token := Num
                UNLESS ch='*'' DO synerr("Bad character constant")
                BREAK

    DEFAULT:    UNLESS ch=endstreamch DO
                { LET badch = ch
                  ch := '*s'
                  synerr("Illegal character %x2", badch)
                }
                token := Eof
                RETURN
  } REPEAT
 
  rch()
}
 
LET lookupword(word) = VALOF
{ LET len, i = word%0, 0
  LET hashval = len
  FOR i = 1 TO len DO hashval := (13*hashval + word%i) & #xFF_FFFF
  hashval := hashval REM nametablesize
  wordnode := nametable!hashval
 
  WHILE wordnode & i<=len TEST (@h3!wordnode)%i=word%i
                          THEN i := i+1
                          ELSE wordnode, i := h2!wordnode, 0
  IF wordnode=0 DO
  { wordnode := newvec(len/bytesperword+3)
    h1!wordnode, h2!wordnode := Name, nametable!hashval
    FOR i = 0 TO len DO (@h3!wordnode)%i := word%i
    nametable!hashval := wordnode
  }
  RESULTIS h1!wordnode
}
 
AND dsw(word, tok) BE { lookupword(word); h1!wordnode := tok  }
 
AND declsyswords() BE
{ dsw("be", Be);             dsw("do", Do);         dsw("else", Else)
  dsw("false", False);       dsw("if", If);         dsw("for", For)
  dsw("let", Let);           dsw("mod", Mod);       dsw("printf", Printf)
  dsw("resultis", Resultis); dsw("return", Return); dsw("static", Static)
  dsw("sys", Sys);           dsw("test", Test);     dsw("to", To)
  dsw("true", True);         dsw("then", Then);     dsw("valof", Valof)
  dsw("vec", Vec);           dsw("unless", Unless); dsw("until", Until)
  dsw("while", While)  
  lookupword("start")
  namestart := wordnode
} 
 
LET rch() BE
{ ch := rdch()
  chcount := chcount+1
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
 
AND rdtag() = VALOF
{ LET len = 0
  WHILE 'a'<=ch<='z' | 'A'<=ch<='Z' | '0'<=ch<='9' |  ch='_' DO
  { len := len+1
    IF len>255 DO synerr("Name too long")
    charv%len := ch
    rch()
  }
  charv%0 := len
  RESULTIS charv
}
 
AND rdstrch() = VALOF
{ LET res = ch
  IF ch='*n' | ch='*p' DO
  { lineno := lineno+1
    synerr("Unescaped newline character")
  }
  IF ch='\' DO
  { rch()
    SWITCHON ch INTO
    { DEFAULT:   synerr("Bad string or character constant")
      CASE '\': CASE '*'': CASE '"':  res := ch;        ENDCASE
      CASE 't': CASE 'T':             res := c_tab;     ENDCASE
      CASE 'n': CASE 'N':             res := c_newline; ENDCASE
    }
  }
  rch()
  RESULTIS res
}

LET newvec(n) = VALOF
{ treep := treep - n - 1;
  IF treep<=treevec DO fatalerr("More workspace needed")
  RESULTIS treep
}
 
AND mk1(a) = VALOF
{ LET p = newvec(0)
  p!0 := a
  RESULTIS p
}
 
AND mk2(a, b) = VALOF
{ LET p = newvec(1)
  p!0, p!1 := a, b
  RESULTIS p
}
 
AND mk3(a, b, c) = VALOF
{ LET p = newvec(2)
  p!0, p!1, p!2 := a, b, c
  RESULTIS p
}
 
AND mk4(a, b, c, d) = VALOF
{ LET p = newvec(3)
  p!0, p!1, p!2, p!3 := a, b, c, d
  RESULTIS p
}
 
AND mk5(a, b, c, d, e) = VALOF
{ LET p = newvec(4)
  p!0, p!1, p!2, p!3, p!4 := a, b, c, d, e
  RESULTIS p
}
 
AND mk6(a, b, c, d, e, f) = VALOF
{ LET p = newvec(5)
  p!0, p!1, p!2, p!3, p!4, p!5 := a, b, c, d, e, f
  RESULTIS p
}
 
AND formtree() = VALOF
{ LET res = 0
  rec_p, rec_l := level(), recover

  charv := newvec(256/bytesperword)     
  nametable := newvec(nametablesize)
  UNLESS charv & nametable DO fatalerr("More workspace needed")
  FOR i = 0 TO nametablesize DO nametable!i := 0
  declsyswords()
  lex()

  IF optTokens DO            // For debugging lex.
  { IF token=Eof RESULTIS 0
    writef("token = %i3 %s", token, opstr(token))
    IF token=Num    DO writef("       %n",  lexval)
    IF token=Name   DO writef("      %s",   charv)
    IF token=String DO writef("    *"%s*"", charv)
    newline()
    lex()
  } REPEAT

recover:
  res := rdprog()
  UNLESS token=Eof DO fatalerr("Incorrect termination")
  RESULTIS res
}
 
AND fatalerr(mess, a) BE
{ writef("*nFatal error:  ")
  writef(mess, a)
  writes("*nCompilation aborted*n")
  errcount := errcount+1
  longjump(fin_p, fin_l)
}

AND synerr(mess, a) BE
{ writef("*nError near line %n:  ", lineno)
  writef(mess, a)
  wrchbuf()
  errcount := errcount+1
  IF errcount >= errmax DO fatalerr("Too many errors")

  // Skip the rest of the input line 
  UNTIL ch='*n' | ch=endstreamch DO rch()
  lex()

  longjump(rec_p, rec_l)
}

LET checkfor(tok, mess) BE
{ UNLESS token=tok DO synerr(mess)
  lex()
}
 
LET rdprog() = VALOF
{ LET ln = lineno
  SWITCHON token INTO
  { DEFAULT:  synerr("Bad outer level declaration*n")

    CASE Eof: RESULTIS 0

    CASE Static:
               { LET d = ?
                 lex()
                 d := mk3(Static, rstatlist(), ln)
                 RESULTIS  mk3(Decl, d, rdprog())
               }

    CASE Let:
         { LET n, args = 0, 0
           lex()
           n := rname()
           checkfor(Lparen, "'(' missing")
           IF token=Name DO args := rnamelist()
           checkfor(Rparen, "')' missing")
 
           IF token=Be DO
           { LET d = mk5(Rtdef, n, args, rncom(), ln)
             RESULTIS mk3(Decl, d, rdprog())
           }
 
           IF token=Eq DO
           { LET d = mk5(Fndef, n, args, rnexp(0), ln)
             RESULTIS mk3(Decl, d, rdprog())
           }
 
           synerr("Bad procedure heading")
        }
  }
} REPEAT

LET rdblockbody() = VALOF
{ LET res, orec_p, orec_l = 0, rec_p, rec_l
  LET op = token
  rec_p, rec_l := level(), recover

recover:
  SWITCHON op INTO
  { DEFAULT:    res := rdseq()
                ENDCASE

    CASE Let:
    CASE Vec: { LET n, e, ln = 0, 0, lineno
                lex()
                n := rname()
                TEST op=Let
                THEN { checkfor(Eq, "Missing '='")
                       e := rexp(0)
                     }
                ELSE { checkfor(Lsquare, "Missing '['")
                       e := rexp(0)
                       UNLESS h1!e=Num DO synerr("Bad 'vec' declaration")
                       checkfor(Rsquare, "Missing ']'")
                     }
                checkfor(Semicolon, "';' expected")
                res := mk5(op, n, e, rdblockbody(), ln)
                ENDCASE
              }
  }
 
  rec_p, rec_l := orec_p, orec_l
  RESULTIS res
}
 
AND rdseq() = VALOF
{ LET a = 0
  a := rcom()
  IF token=Rcurly | token=Eof RESULTIS a
  checkfor(Semicolon, "';' expected")
  RESULTIS mk3(Seq, a, rdseq())
}

AND rnamelist() = VALOF
{ LET a = rname()
  UNLESS token=Comma RESULTIS a
  lex()
  RESULTIS mk3(Comma, a, rnamelist())
}

AND rexplist() = VALOF
{ LET a = rexp(0)
  UNLESS token=Comma RESULTIS a
  lex()
  RESULTIS mk3(Comma, a, rexplist())
}
 
AND rstatlist() = VALOF
{ LET a = rname()
  IF token=Lsquare DO
  { LET b = rnexp(0)
    UNLESS h1!b=Num DO synerr("Number expected")
    checkfor(Rsquare, "']' expected")
    a := mk3(Statvec, a, b)
  }
  UNLESS token=Comma RESULTIS a
  lex()
  RESULTIS mk3(Comma, a, rstatlist())
}

AND rname() = VALOF
{ LET a = wordnode
  checkfor(Name, "Name expected")
  RESULTIS a
}
 
LET rbexp() = VALOF
{ LET a, op, ln = 0, token, lineno
 
  SWITCHON op INTO
 
  { DEFAULT: synerr("Error in expression")

    CASE True:
    CASE False:
    CASE Name:
    CASE String: a := wordnode
                 lex()
                 RESULTIS a
 
    CASE Num:    a := mk2(Num, lexval)
                 lex()
                 RESULTIS a
 
    CASE Printf:
    CASE Sys: lex()
              checkfor(Lparen, "'(' missing")
              a := 0
              UNLESS token=Rparen DO a := rexplist()
              checkfor(Rparen, "')' missing")
              RESULTIS mk3(op, a, ln)


    CASE Lparen: a := rnexp(0)
                 checkfor(Rparen, "')' missing")
                 RESULTIS a
 
    CASE Valof:  RESULTIS mk2(Valof, rncom())
 
    CASE Ind:
    CASE Lv:     RESULTIS mk2(op, rnexp(7))
 
    CASE Add:    RESULTIS rnexp(5)
 
    CASE Sub:    a := rnexp(5)
                 TEST h1!a=Num THEN h2!a := - h2!a
                               ELSE a := mk2(Neg, a)
                 RESULTIS a
 
    CASE Not:    RESULTIS mk2(Not, rnexp(3))
   }
}
 
AND rnexp(n) = VALOF { lex(); RESULTIS rexp(n) }
 
AND rexp(n) = VALOF
{ LET a, b, p = rbexp(), 0, 0

  { LET op, ln = token, lineno
    SWITCHON op INTO
 
    { DEFAULT:      BREAK
 
      CASE Lparen:  lex()
                    b := 0
                    UNLESS token=Rparen DO b := rexplist()
                    checkfor(Rparen, "')' missing")
                    a := mk4(Fnap, a, b, ln)
                    LOOP
 
      CASE Lsquare: b := rnexp(0)
                    checkfor(Rsquare, "']' missing")
                    a := mk3(Vecap, a, b)
                    LOOP
 
      CASE Mul:CASE Div:CASE Mod:
                    p := 7;              ENDCASE
      CASE Add:CASE Sub:
                    p := 6;              ENDCASE
      CASE Lsh:CASE Rsh:
                    p := 5;              ENDCASE
      CASE Eq:CASE Le:CASE Lt:CASE Ne:CASE Ge:CASE Gt:
                    p := 4;              ENDCASE
      CASE And:     p := 3;              ENDCASE
      CASE Or:      p := 2;              ENDCASE
      CASE Xor:     p := 1;              ENDCASE
    }
      
    IF n>=p RESULTIS a
    a := mk3(op, a, rnexp(p))
  } REPEAT

  RESULTIS a
}
  
LET rcom() = VALOF
{ LET n, a, b, op, ln = 0, 0, 0, token, lineno
 
  SWITCHON token INTO
  { DEFAULT:     synerr("Command expected")
 
    CASE Name:CASE Num:CASE Lparen:CASE Ind:
    CASE Sys:CASE Printf:
    // All tokens that can start an expression.
                 a := rexp(0)
 
                 IF token=Assign DO
                 { UNLESS h1!a=Name | h1!a=Vecap | h1!a=Ind DO
                     synerr("Bad assigment statement")
                   RESULTIS mk4(Assign, a, rnexp(0), ln)
                 }
 
                 IF h1!a=Fnap DO
                 { h1!a := Rtap
                   RESULTIS a
                 }
 
                 UNLESS h1!a=Sys | h1!a=Printf DO
                   synerr("Error in command")
                 RESULTIS a
 
    CASE Resultis:
                 RESULTIS mk3(op, rnexp(0), ln)
 
    CASE If:    CASE Unless:
    CASE While: CASE Until:
                 a := rnexp(0)
                 checkfor(Do, "'do' missing")
                 RESULTIS mk4(op, a, rcom(), ln)
 
    CASE Test:   a := rnexp(0)
                 checkfor(Then, "'then' missing")
                 b := rcom()
                 checkfor(Else, "'else' missing")
                 RESULTIS mk5(Test, a, b, rcom(), ln)
 
    CASE For:    lex()
                 n := rname()
                 checkfor(Eq, "'=' expected")
                 a := rexp(0)
                 checkfor(To, "'to' expected")
                 b := rexp(0)
                 checkfor(Do, "'do' missing")
                 RESULTIS mk6(For, n, a, b, rcom(), ln)

    CASE Return: lex()
                 RESULTIS mk2(op, ln)
 
    CASE Lcurly: lex()
                 a := rdblockbody()
                 checkfor(Rcurly, "'}' expected")
                 RESULTIS a
   }
}

AND rncom() = VALOF { lex(); RESULTIS rcom() }

LET opstr(op) = VALOF SWITCHON op INTO
{ DEFAULT:       RESULTIS "Unknown"

  CASE Assign:   RESULTIS "Assign";    CASE Add:     RESULTIS "Add"
  CASE And:      RESULTIS "And";       CASE Be:      RESULTIS "Be"
  CASE Comma:    RESULTIS "Comma";     CASE Data:    RESULTIS "Data"
  CASE Decl:     RESULTIS "Decl";      CASE Div:     RESULTIS "Div"
  CASE Do:       RESULTIS "Do";        CASE Else:    RESULTIS "Else"
  CASE Entry:    RESULTIS "Entry";     CASE Eq:      RESULTIS "Eq"
  CASE False:    RESULTIS "False";     CASE Fnap:    RESULTIS "Fnap"
  CASE For:      RESULTIS "For";       CASE Fndef:   RESULTIS "Fndef"
  CASE Fnrn:     RESULTIS "Fnrn";      CASE Ge:      RESULTIS "Ge"
  CASE Gt:       RESULTIS "Gt";        CASE Halt:    RESULTIS "Halt"
  CASE If:       RESULTIS "If";        CASE Ind:     RESULTIS "Ind"
  CASE Jf:       RESULTIS "Jf";        CASE Jt:      RESULTIS "Jt"
  CASE Jump:     RESULTIS "Jump";      CASE Lab:     RESULTIS "Lab"
  CASE Laddr:    RESULTIS "Laddr";     CASE Lcurly:  RESULTIS "Lcurly"
  CASE Le:       RESULTIS "Le";        CASE Let:     RESULTIS "Let"
  CASE Ll:       RESULTIS "Ll";        CASE Llp:     RESULTIS "Llp"
  CASE Ln:       RESULTIS "Ln";        CASE Lp:      RESULTIS "Lp"
  CASE Lparen:   RESULTIS "Lparen";    CASE Lres:    RESULTIS "Lres"
  CASE Lsh:      RESULTIS "Lsh";       CASE Lsquare: RESULTIS "Lsquare"
  CASE Lt:       RESULTIS "Lt";        CASE Lv:      RESULTIS "Lv"
  CASE Mod:      RESULTIS "Mod";       CASE Mul:     RESULTIS "Mul"
  CASE Name:     RESULTIS "Name";      CASE Ne:      RESULTIS "Ne"
  CASE Neg:      RESULTIS "Neg";       CASE Not:     RESULTIS "Not"
  CASE Num:      RESULTIS "Num";       CASE Or:      RESULTIS "Or"       
  CASE Printf:   RESULTIS "Printf";    CASE Rcurly:  RESULTIS "Rcurly"
  CASE Resultis: RESULTIS "Resultis";  CASE Return:  RESULTIS "Return"
  CASE Rparen:   RESULTIS "Rparen";    CASE Rsh:     RESULTIS "Rsh"
  CASE Rsquare:  RESULTIS "Rquare";    CASE Rtap:    RESULTIS "Rtap"
  CASE Rtdef:    RESULTIS "Rtdef";     CASE Rtrn:    RESULTIS "Rtrn"
  CASE Semicolon:RESULTIS "Semicolon"; CASE Seq:     RESULTIS "Seq"
  CASE Sl:       RESULTIS "Sl";        CASE Sp:      RESULTIS "Sp"
  CASE Stack:    RESULTIS "Stack";     CASE Static:  RESULTIS "Static"
  CASE Statvec:  RESULTIS "Statvec";   CASE String:  RESULTIS "String"
  CASE Stind:    RESULTIS "Stind";     CASE Sub:     RESULTIS "Sub"
  CASE Sys:      RESULTIS "Sys";       CASE Test:    RESULTIS "Test"
  CASE Then:     RESULTIS "Then";      CASE To:      RESULTIS "To"
  CASE True:     RESULTIS "True";      CASE Valof:   RESULTIS "Valof"
  CASE Vecap:    RESULTIS "Vecap";     CASE Vec:     RESULTIS "Vec"
  CASE Unless:   RESULTIS "Unless";    CASE Until:   RESULTIS "Until"
  CASE While:    RESULTIS "While";     CASE Xor:     RESULTIS "Xor"
}

LET plist(x, n, d) BE
{ LET s, size, ln = 0, 0, 0
  LET v = TABLE 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

  IF x=0 DO { writes("Nil"); RETURN  }
 
  SWITCHON h1!x INTO
  { DEFAULT:
         size     := 1;        ENDCASE

    CASE Num:     writen(h2!x);         RETURN
    CASE Name:    writes(x+2);          RETURN
    CASE String:  writef("*"%s*"",x+1); RETURN

    CASE For:
         size, ln := 5, h6!x; ENDCASE

    CASE Fndef: CASE Rtdef:
         size, ln := 4, h5!x; ENDCASE

    CASE Let: CASE Vec: CASE Test:
         size, ln := 4, h5!x; ENDCASE

    CASE Vecap: CASE Mul: CASE Div: CASE Mod: CASE Add: CASE Sub:
    CASE Eq: CASE Ne: CASE Lt: CASE Gt: CASE Le: CASE Ge:
    CASE Lsh: CASE Rsh: CASE And: CASE Or: CASE Xor:
    CASE Comma: CASE Seq: CASE Decl: CASE Statvec:
         size     := 3;       ENDCASE

    CASE Assign: CASE Rtap: CASE Fnap:
    CASE If: CASE Unless: CASE While: CASE Until:
         size, ln := 3, h4!x; ENDCASE

    CASE Valof: CASE Lv: CASE Ind: CASE Neg: CASE Not:
         size     := 2;       ENDCASE

    CASE Printf: CASE Sys: CASE Static: CASE Resultis:
         size, ln := 2, h3!x; ENDCASE

    CASE True: CASE False:
         size     := 1;       ENDCASE
  }
 
  IF n=d DO { writes("Etc"); RETURN }
  writef("%s", opstr(h1!x))
  IF ln DO writef("  -- line %n", ln)
  FOR i = 2 TO size DO { newline()
                         FOR j=0 TO n-1 DO writes( v!j )
                         writes("**-")
                         v!n := i=size->"  ","! "
                         plist(h1!(x+i-1), n+1, d)
                       }
}


AND trnerr(mess, a) BE
{ writes("Error")
  IF procname DO writef(" in %s", @h3!procname)
  IF comline DO writef(" near line %n", comline)
  writes(":   ")
  writef(mess, a)
  newline()
  errcount := errcount + 1
  IF errcount >= errmax DO fatalerr("*nCompilation aborted*n")
}

AND trprog(x) BE
{ dvec, dvect := treevec, treep
  h1!dvec, h2!dvec, h3!dvec := 0, 0, 0
  dvece := dvec+3
  FOR i = 0 TO nametablesize-1 DO
  { LET name = nametable!i
    UNTIL name=0 DO
    { LET next = h2!name
      h2!name := 0 // Mark undeclared
      name := next
    }
  }

  FOR i = 0 TO labmax DO labv!i, refv!i := -1, 0

  resultlab := -2
  comline, procname, labnumber := 1, 0, 1
  ssp := 2

  outfl(Laddr, 1); ssp := ssp+1  // 1 = lab number of start
  outfn(Fnap, 3);  ssp := ssp-1
  outf(Halt)

  declstatnames(x)
  checkdistinct(dvec+3)
  WHILE x DO { trdecl(h2!x); x:=h3!x }
  resolvelabels()
  writef("Program size: %n   Data size: %n*n", codep-codev, datap-datav)
}

LET trnext(next) BE { IF next<0 DO outf(Rtrn)
                      IF next>0 DO outfl(Jump, next)
                    }
 
LET trcom(x, next) BE
// x       is the command to translate
// next<0  compile x followed by Rtrn
// next>0  compile x followed by Jump next
// next=0  compile x only
{ LET op = h1!x

  SWITCHON op INTO
  { DEFAULT: trnerr("Compiler error in Trans")
             RETURN
 
    CASE Let:
           { LET e, s = dvece, ssp
             comline := h5!x
             addname(h2!x, Local, ssp+1)
             load(h3!x)
             trcom(h4!x, next)
             undeclare(e)
             outfn(Stack, s)
             ssp := s
             RETURN
           }
  
    CASE Vec:
           { LET e, s = dvece, ssp
             comline := h5!x
             addname(h2!x, Vec, ssp+1)
             ssp := ssp + h2!(h3!x)
             outfn(Stack, ssp)
             trcom(h4!x, next)
             undeclare(e)
             outfn(Stack, s)
             ssp := s
             RETURN
           }
  
    CASE Assign:
             comline := h4!x
             assign(h2!x, h3!x)
             trnext(next)
             RETURN
 
    CASE Rtap:
           { LET s = ssp
             comline := h4!x
             ssp := ssp+3
             outfn(Stack, ssp)
             loadlist(h3!x)
             load(h2!x)
             outfn(Rtap, s+1)
             ssp := s
             trnext(next)
             RETURN
           }
 
    CASE Printf:
    CASE Sys:
           { LET s = ssp
             LET op = h1!x
             comline := h3!x
             loadlist(h2!x)
             outfn(op, s+1)
             ssp := s
             trnext(next)
             RETURN
           }
 
    CASE Unless:
    CASE If: comline := h4!x
             TEST next>0
             THEN { jumpcond(h2!x, op=Unless, next)
                    trcom(h3!x, next)
                  }
             ELSE { LET l = nextlab()
                    jumpcond(h2!x, op=Unless, l)
                    trcom(h3!x, next)
                    outlab(l)
                    trnext(next)
                  }
             RETURN
 
    CASE Test:
           { LET l, m = nextlab(), 0
             comline := h5!x
             jumpcond(h2!x, FALSE, l)
         
             TEST next=0
             THEN { m := nextlab(); trcom(h3!x, m) }
             ELSE trcom(h3!x, next)
                     
             outlab(l)
             trcom(h4!x, next)
             UNLESS m=0 DO outlab(m)
             RETURN
           }
 
    CASE Return:
             comline := h2!x
             outf(Rtrn)
             RETURN
 
    CASE Resultis:
             comline := h3!x
             IF resultlab=-1 DO { fnbody(h2!x); RETURN }
             UNLESS resultlab>0 DO
             { trnerr("RESULTIS out of context")
               RETURN
             }
             load(h2!x)
             outfl(Resultis, resultlab)
             ssp := ssp - 1
             RETURN
 
    CASE Until:
    CASE While:
           { LET l, m = nextlab(), next
             comline := h4!x
             IF next<=0 DO m := nextlab()
             jumpcond(h2!x, op=Until, m)
             outlab(l)
             trcom(h3!x, 0)
             comline := h4!x
             jumpcond(h2!x, op=While, l)
             IF next<=0 DO outlab(m)
             trnext(next)
             RETURN
           }
 
    CASE For:
           { LET e, s = dvece, ssp
             LET l, m = nextlab(), nextlab()
             comline := h5!x
             addname(h2!x, Local, ssp+1)
             load(h3!x)  // The control variable at s+1
             load(h4!x)  // The end limit        at s+2

             outfl(Jump, m)               // Jump to test

             outlab(l)                    // Start of body
             trcom(h5!x, 0)

             outfn(Lp, s+1); ssp := ssp+1 // Inc control variable
             outfn(Ln, 1);   ssp := ssp+1
             outf(Add);      ssp := ssp-1
             outfn(Sp, s+1); ssp := ssp-1

             outlab(m)
             outfn(Lp, s+1); ssp := ssp+1 // Compare with limit
             outfn(Lp, s+2); ssp := ssp+1
             outf(Le);       ssp := ssp-1
             outfl(Jt, l);   ssp := ssp-1

             undeclare(e)
             outfn(Stack, s)
             ssp := s
             trnext(next)
             RETURN
           }
  
    CASE Seq:
            trcom(h2!x, 0)
            x := h3!x
  }
} REPEAT

AND declstatnames(x) BE WHILE x DO
{ LET d = h2!x
  
  SWITCHON h1!d INTO
  { DEFAULT:  trnerr("Compiler error in declstatnames")
              RETURN

    CASE Static: { LET p, np = h2!d, 0
                   WHILE p SWITCHON h1!p INTO
                   { DEFAULT:  trnerr("Bad STATIC declaration")
                               RETURN

                     CASE Comma:  np := h3!p
                                  p  := h2!p
                                  LOOP

                     CASE Name: { LET lab = nextlab()
                                  outvar(lab)
                                  addname(p, Var, lab)
                                  p := np
                                  np := 0
                                  LOOP
                                }
                     CASE Statvec:
                                { LET lab = nextlab()
                                  LET upb = h2!(h3!p)
                                  outstatvec(lab, upb)
                                  addname(h2!p, Addr, lab)
                                  p := np
                                  np := 0
                                  LOOP
                                }
                   }
                   ENDCASE      
                 }

    CASE Fndef:
    CASE Rtdef: 
              { LET name = h2!d
                LET lab = name=namestart -> 1, nextlab()
                addname(name, Addr, lab)
                ENDCASE
              }
  }
  x := h3!x
}

AND decldyn(x) BE UNLESS x=0 DO
 
{ IF h1!x=Name  DO { ssp := ssp+1
                     addname(x, Local, ssp)
                     RETURN
                   }
 
  IF h1!x=Comma DO { ssp := ssp+1
                     addname(h2!x, Local, ssp)
                     decldyn(h3!x)
                     RETURN
                   }
 
   trnerr("Compiler error in Decldyn")
}
 
AND checkdistinct(p) BE
{ LET lim = dvece - 3
  FOR q = p TO lim-3 BY 3 DO
  { LET n = h1!q
    FOR c = q+3 TO lim BY 3 DO
        IF h1!c=n DO trnerr("Name %s defined twice", @h3!n)
  }
}
 
AND addname(name, k, a) BE
{ LET p = dvece + 3
  IF p>dvect DO { trnerr("More workspace needed"); RETURN }
  h1!dvece, h2!dvece, h3!dvece := name, k, a
  h2!name := dvece // Remember the declaration
  dvece := p
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
  UNLESS t=0 RESULTIS t  // It has been looked up before
  t := dvece
  t := t - 3 REPEATUNTIL h1!t=n | h1!t=0
  h2!n := t  // Associate the name with declaration item
  RESULTIS t
}
 
AND trdecl(x) BE SWITCHON h1!x INTO
{  CASE Static:  // Static declarations are compiled in declstatnames
               RETURN

   CASE Fndef:
   CASE Rtdef:
             { LET e = dvece
               LET name = h2!x
               LET t = cellwithname(name)
               LET strlab = nextlab()

               resultlab := -2
               procname := name

               outstring(strlab, @h3!procname)
               outentry(h3!t, strlab)
               ssp := 2
               decldyn(h3!x)  // Declare the formal paramenters
               checkdistinct(e)
               outfn(Stack, ssp)
               TEST h1!x=Rtdef THEN trcom(h4!x, -1)
                               ELSE fnbody(h4!x)
 
               undeclare(e)
               procname := 0
             }
 
  DEFAULT:   RETURN
}
 
LET jumpcond(x, b, l) BE
{ LET sw = b

  SWITCHON h1!x INTO
  { CASE False:  b := NOT b
    CASE True:   IF b DO outfl(Jump, l)
                 RETURN
 
    CASE Not:    jumpcond(h2!x, NOT b, l)
                 RETURN
 
    CASE And: sw := NOT sw
    CASE Or:  TEST sw THEN { jumpcond(h2!x, b, l)
                             jumpcond(h3!x, b, l)
                             RETURN
                           }
 
                       ELSE { LET m = nextlab()
                              jumpcond(h2!x, NOT b, m)
                              jumpcond(h3!x, b, l)
                              outlab(m)
                              RETURN
                            }
 
    DEFAULT:     load(x)
                 outfl(b -> Jt, Jf, l)
                 ssp := ssp-1
                 RETURN
  }
}

LET load(x) BE
{ LET op = h1!x

  SWITCHON op INTO
  { DEFAULT:      trnerr("Compiler error in Load, op=%n", op)
                  outfl(Ln, 0)
                  ssp := ssp+1
                  RETURN
 
    CASE Vecap:
    CASE Mul: CASE Div: CASE Mod: CASE Add: CASE Sub:
    CASE Eq: CASE Ne: CASE Lt: CASE Gt: CASE Le: CASE Ge:
    CASE Lsh: CASE Rsh: CASE And: CASE Or: CASE Xor:
                  load(h2!x); load(h3!x); outf(op)
                  ssp := ssp-1
                  RETURN
 
    CASE Ind: CASE Neg: CASE Not:
                  load(h2!x)
                  outf(op)
                  RETURN

    CASE Lv:      loadlv(h2!x)
                  RETURN
 
    CASE Num:     outfn(Ln, h2!x); ssp := ssp+1; RETURN
    CASE True:    outfn(Ln, -1);   ssp := ssp+1; RETURN
    CASE False:   outfn(Ln, 0);    ssp := ssp+1; RETURN
 
    CASE String:  
                { LET strlab = nextlab()
                  outstring(strlab, @h2!x)
                  outfl(Laddr, strlab)
                  ssp := ssp+1
                  RETURN
                }
 
    CASE Name:    transname(x, Lp, Ll, Llp, Laddr)
                  ssp := ssp+1
                  RETURN
 
    CASE Valof: { LET rl = resultlab
                  resultlab := nextlab()
                  trcom(h2!x, 0)
                  outlab(resultlab)
                  outfn(Stack, ssp)
                  outf(Lres); ssp := ssp+1
                  resultlab := rl
                  RETURN
                }
 
    CASE Fnap:  { LET s = ssp
                  ssp := ssp+3
                  outfn(Stack, ssp)
                  loadlist(h3!x)
                  load(h2!x)
                  outfn(Fnap, s+1)
                  outf(Lres); ssp := s+1
                  RETURN
                }
    CASE Printf:
    CASE Sys:
           { LET s = ssp
             LET op = h1!x
             comline := h3!x
             loadlist(h2!x)
             outfn(op, s+1)
             ssp := s
             outf(Lres)
             ssp := ssp+1
             RETURN
           }
  }
}

AND loadlv(x) BE SWITCHON h1!x INTO
{ DEFAULT:    trnerr("Bad operand to @")
              outf(Lres); ssp := ssp+1
              RETURN

  CASE Name:  transname(x, Llp, Laddr, 0, 0); ssp := ssp+1
              RETURN

  CASE Ind:   load(h2!x)
              RETURN

  CASE Vecap: load(h2!x); load(h3!x); outf(Add); ssp := ssp-1
              RETURN
}

AND fnbody(x) BE SWITCHON h1!x INTO
{ DEFAULT:      load(x)
                outf(Fnrn)
                ssp := ssp-1
                RETURN
                   
  CASE Valof: { LET e, rl = dvece, resultlab
                resultlab := -1
                trcom(h2!x, -1)
                resultlab := rl
                undeclare(e)
                RETURN
              }
}
 
AND loadlist(x) BE UNLESS x=0 TEST h1!x=Comma
                              THEN { loadlist(h2!x); loadlist(h3!x) }
                              ELSE load(x)

AND assign(x, y) BE SWITCHON h1!x INTO
{ DEFAULT:    trnerr("Bad assignment")
              RETURN
  CASE Name:  load(y)
              transname(x, Sp, Sl, 0, 0)
              ssp := ssp-1
              RETURN
  CASE Vecap: load(y)
              load(h2!x); load(h3!x); outf(Add); ssp := ssp-1
              outf(Stind); ssp := ssp-2
              RETURN
  CASE Ind:   load(y)
              load(h2!x)
              outf(Stind); ssp := ssp-2
              RETURN
}
 
AND transname(x, p, l, v, a) BE
{ LET c = cellwithname(x)
  LET k, n = h2!c, h3!c
  LET name = @h3!x
 
  SWITCHON k INTO
  { DEFAULT:      trnerr("Name '%s' not declared", name)
   
    CASE Local:   outfn(p, n); RETURN
 
    CASE Var:     outfl(l, n); RETURN
 
    CASE Vec:     IF v=0 DO
                  { trnerr("Misuse of local vector '%s'", name)
                    v := p
                  }
                  outfn(v, n)
                  RETURN

    CASE Addr:    IF a=0 DO
                  { trnerr("Misuse of entry name '%s'", name)
                    a := l
                  }
                  outfl(a, n)
                  RETURN
  }
}
 
AND wrf(form, a, b, c) BE IF optCode DO writef(form, a, b, c)

AND outf(op) BE
{ wrf("%s*n", opstr(op))
  putc(op)
}

AND outfn(op, a) BE
{ wrf("%s %n*n", opstr(op), a)
  putc(op); putc(a)
}

AND outfl(op, lab) BE
{ wrf("%s L%n*n", opstr(op), lab)
  putc(op); putref(lab)
}

AND outlab(lab) BE
{ wrf("Lab L%n*n", lab)
  setlab(lab, codep)
}

AND outentry(l1, l2) BE
{ wrf("Entry L%n L%n*n", l1, l2)
  putref(l2)
  setlab(l1, codep)
}

AND outstring(lab, s) BE
{ LET sv = mem+datap
  LET p = datap
  LET len = s%0
  wrf("String L%n %s*n", lab, s)
  setlab(lab, datap)
  FOR i = 0 TO len DO
  { IF i REM 4 = 0 DO putd(0)
    sv%i := i<len -> s%(i+1), 0 // assemble a zero terminated string
  }
}

AND outstatvec(lab, a) BE
{ wrf("Statvec L%n %n*n", lab, a)
  setlab(lab, datap)
  FOR i = 0 TO a-1 DO putd(0)
}

AND outvar(lab) BE
{ wrf("Var L%n*n", lab)
  setlab(lab, datap)
  putd(0)
}
 
AND putc(w) BE TEST codep>codet
               THEN trnerr("More code space needed")
               ELSE { mem!codep := w
                      codep := codep+1
                    }

AND putd(w) BE TEST datap>datat
               THEN trnerr("More data space needed")
               ELSE { mem!datap := w
                      datap := datap+1
                    }

AND putref(lab) BE TEST codep>codet
                   THEN trnerr("More code space needed")
                   ELSE { mem!codep := refv!lab
                          refv!lab := codep
                          codep := codep+1
                        }

AND setlab(lab, addr) BE labv!lab := addr

AND nextlab() = VALOF
{ TEST labnumber>=labmax
  THEN fatalerr("More label space needed")
  ELSE labnumber := labnumber + 1
  RESULTIS labnumber
}
 

AND resolvelabels() BE FOR lab = 1 TO labnumber DO
{ LET p = refv!lab
  LET labval = labv!lab
  IF p & labval<0 TEST lab=1 THEN trnerr("start not defined")
                             ELSE trnerr("Label %n unset", lab)
  WHILE p DO { LET np = mem!p
               mem!p, p := labval, np
             }
}

AND interpret(regs, mem) = VALOF
{ LET retcode = 0
  LET rv = mem+regs
  LET res, pp, sp, pc = rv!0, mem+rv!1, mem+rv!2, mem+rv!3
  LET count = rv!4

  { LET op = !pc                // Fetch next instruction
    IF optTrace DO
    { writef("p:%i5  sp:%i5 %iA %iA  %i5: %t8",
              pp-mem,    sp-mem, sp!-1, sp!0, pc-mem, opstr(op))
      IF hasOperand(op) DO writef(" %n", pc!1)
      newline()
    }
    IF count<=0 DO { retcode := 3; BREAK } // Zero count
    count := count-1
    pc := pc+1
//IF sp-stack>stackt DO abort(9999)
    SWITCHON op INTO
    { DEFAULT:      retcode := 1;    BREAK    // Unknown op code

      CASE Halt:    retcode := sp!0; BREAK

      CASE Laddr:   sp := sp+1; sp!0 := !pc;       pc := pc+1; LOOP
      CASE Ln:      sp := sp+1; sp!0 := !pc;       pc := pc+1; LOOP
      CASE Lp:      sp := sp+1; sp!0 := pp!(!pc);  pc := pc+1; LOOP
      CASE Llp:     sp := sp+1; sp!0 := pp+!pc-mem;pc := pc+1; LOOP
      CASE Ll:      sp := sp+1; sp!0 := mem!(!pc); pc := pc+1; LOOP
      CASE Sp:      pp!(!pc) := sp!0; sp := sp-1;  pc := pc+1; LOOP
      CASE Sl:      mem!(!pc):= sp!0; sp := sp-1;  pc := pc+1; LOOP

      CASE Rtap:
      CASE Fnap:  { LET opp, retaddr = pp, pc+1
                    pp, pc := pp+!pc, sp!0+mem
                    pp!0, pp!1, pp!2 := opp-mem, retaddr-mem, pc-mem
                    sp := pp+2
                    LOOP
                  }

      CASE Lres:    sp := sp+1; sp!0 := res;                LOOP

      CASE Fnrn:    res := sp!0
      CASE Rtrn:  { LET npp, npc = pp!0+mem, pp!1+mem
                    sp := pp-1
                    pp, pc := npp, npc
                    LOOP
                  }
      CASE Ind:     sp!0 :=  mem!(sp!0);                   LOOP
      CASE Neg:     sp!0 :=  -  sp!0;                      LOOP
      CASE Not:     sp!0 := NOT sp!0;                      LOOP
      CASE Stind:   sp := sp-2; mem!(sp!2) := sp!1;        LOOP
      CASE Vecap:   sp := sp-1; sp!0 := mem!(sp!0 + sp!1); LOOP
      CASE Mul:     sp := sp-1; sp!0 := sp!0  *  sp!1;     LOOP
      CASE Div:     sp := sp-1; sp!0 := sp!0  /  sp!1;     LOOP
      CASE Mod:     sp := sp-1; sp!0 := sp!0 REM sp!1;     LOOP
      CASE Add:     sp := sp-1; sp!0 := sp!0  +  sp!1;     LOOP
      CASE Sub:     sp := sp-1; sp!0 := sp!0  -  sp!1;     LOOP
      CASE Eq:      sp := sp-1; sp!0 := sp!0  =  sp!1;     LOOP
      CASE Ne:      sp := sp-1; sp!0 := sp!0 ~=  sp!1;     LOOP
      CASE Le:      sp := sp-1; sp!0 := sp!0 <=  sp!1;     LOOP
      CASE Ge:      sp := sp-1; sp!0 := sp!0 >=  sp!1;     LOOP
      CASE Lt:      sp := sp-1; sp!0 := sp!0  <  sp!1;     LOOP
      CASE Gt:      sp := sp-1; sp!0 := sp!0  >  sp!1;     LOOP
      CASE Lsh:     sp := sp-1; sp!0 := sp!0 <<  sp!1;     LOOP
      CASE Rsh:     sp := sp-1; sp!0 := sp!0 >>  sp!1;     LOOP
      CASE And:     sp := sp-1; sp!0 := sp!0  &  sp!1;     LOOP
      CASE Or:      sp := sp-1; sp!0 := sp!0  |  sp!1;     LOOP
      CASE Xor:     sp := sp-1; sp!0 := sp!0 XOR sp!1;     LOOP
      CASE Jt:      sp := sp-1; pc := sp!1->!pc+mem,pc+1;  LOOP
      CASE Jf:      sp := sp-1; pc := sp!1->pc+1,!pc+mem;  LOOP
      CASE Resultis:sp := sp-1; res := sp!1
      CASE Jump:    pc := !pc+mem;                         LOOP
      CASE Stack:   sp := pp + !pc; pc := pc+1;            LOOP
      CASE Printf:  sp := pp + !pc - 1
                    pc := pc+1
                    printf(mem, sp!1, sp+2)
                    LOOP
      CASE Sys:     sp := pp + !pc - 1
                    pc := pc+1
                    SWITCHON sp!1 INTO
                    { DEFAULT: writef("*nBad sys(%n,...) call*n", sp!1)
                               retcode  := 2;               BREAK   
                      CASE 0:  retcode  := sp!2;            BREAK
                      CASE 1:  res := interpret(sp!2, mem); LOOP
                      CASE 2:  optTrace := sp!2;            LOOP
                      CASE 3:  res := count; count := sp!2; LOOP
                    }
    }
  } REPEAT

  rv!0, rv!1, rv!2, rv!3, rv!4 := res, pp-mem, sp-mem, pc-mem, count
  RESULTIS retcode
}

AND printf(mem, form, p) BE
{ LET fmt = form+mem
  LET i = 0

  { LET k = fmt%i
    i := i+1
    IF k=0 RETURN
    IF k='%' DO
    { LET n = 0;
      { k := fmt%i
        i := i+1
        UNLESS '0'<=k<='9' BREAK
        n := 10*n + k - '0'
      } REPEAT
      SWITCHON k INTO
      { DEFAULT:  wrch(k); LOOP
        CASE 'd': writed  (!p,     n); p := p+1; LOOP
        CASE 's': wrs     (mem+!p, n); p := p+1; LOOP
        CASE 'x': writehex(!p,     n); p := p+1; LOOP
      }
    }
    wrch(k)
  } REPEAT
}

AND wrs(s, n) BE
{ LET len = 0
  WHILE s%len DO len := len+1
  FOR i = len+1 TO n DO wrch(' ')
  FOR i = 0 TO len-1 DO wrch(s%i)
}

AND hasOperand(op) = VALOF SWITCHON op INTO
{ CASE Fnrn:CASE Rtrn:CASE Lres:CASE Halt:
  CASE Vecap:CASE Ind:CASE Stind:CASE Neg:CASE Not:
  CASE Mul:CASE Div:CASE Mod:CASE Add:CASE Sub:
  CASE Eq:CASE Ne:CASE Le:CASE Ge:CASE Lt:CASE Gt:
  CASE Lsh:CASE Rsh:CASE And:CASE Or:CASE Xor:
            RESULTIS FALSE
  DEFAULT:  RESULTIS TRUE
}

