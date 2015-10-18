/*
########## UNDER EARLY STAGE OF DEVELOPMENT #############

This is a compiler and interpreter for the language PAL
implemented in BCPL.

(c) Martin Richards 21 Oct 2010

Usage:

pal  "PROG/A,TO=-o/K,TOKENS=-l/S,TREE=-p/S,CODE=-c/S,TRACE=-t/S"

   PROG   gives the filename of the PAL program to run, eg test.pal
-o TO     gives the filename of the output
-l TOKENS is a switch to test the lexical analyser
-p TREE   causes the parse tree to be output
-c CODE   outputs the compiled blackboard evaluator code
-t TRACE  Traces the execution of the blackboard evaluator.

21/10/2010
Started modifying this compiler to make it follow the syntax and
POCODE of the Pal70 compiler whose original compiler listing is in
doc/pal70-mabee-17jun70.pdf

08/07/2010
Started to modify lex and syn to agree with the PAL syntax specified
in Appendix 2.1 (dated 02/17/68) with the following minor extensions.

The operators ~=, <= and >= are included.
( and [ are synonyms as are ) and ].
-> and -* are synonyms.
~ and not are synonyms.

14/06/2010
Lex more or less complete, now working on the syntax analyser.

09/06/2010
Started re-implementation of PAL based on VSPL.

*/


GET "libhdr"
 
MANIFEST {
// Selectors
h1=0; h2=1; h3=2; h4=3; h5=4; h6=5

// Syntactic operators
Bar=1; Eof; Where; Dot
Lparen; Rparen; In; Percent
Ifso; Ifnot; Do

// AE Tree nodes
Def; Let; Lambda; Valof; Test
If; While; Ass
Seq; Colon
Noshare; Cond
Comma; Valdef
Rec; And; Within
Mpt; Paren

// AE nodes and POCODE symbols
Goto; Res
Not; Nil; Stringconst; Name
Plus; Minus
Aug; Logor; Logand
Eq; Ne; Lt; Le; Gt; Ge
Mult; Div; Power
Pos; Neg; Apply

// POCODE symbols
LoadL; LoadR; LoadE; LoadS; LoadN; LoadF; LoadJ
RestoreE1; LoadGuess
FormClosure; FormLvalue; FormRvalue
Members
Jump; JumpF; Save; Return
TestEmpty; Lose1; Update
Declname; Declnames; Initname; Initnames
Decllabel; SetlabEs; Blocklink; Reslink
Setup; Halt
Integer; Lab; Param; Equ

// AE nodes, POCODE symbols and run-time node types
Dummy; Jj; True; False; Int; Real; Sys
Number; Tuple

// Translation symbols
Val=0; Ref

// Library functions
Sys_isboolean=1
Sys_isstring
Sys_isfunction
Sys_isprogramclosure
Sys_islabel
Sys_istuple
Sys_isreal
Sys_isinteger
Sys_stem
Sys_stern
Sys_conc
Sys_itor
Sys_rtoi
Sys_stoi
Sys_lookupinj
Sys_order
Sys_print
Sys_readch
Sys_atom
Sys_null
Sys_share
}
 
GLOBAL { 
rec_p:ug; rec_l; fin_p; fin_l
fatalerr; synerr; trnerr; errcount; errmax
progstream; tostream
mk1; mk2; mk3; mk4; mk5; mk6
newvec; treep; treevec
optTokens; optTree; optCode; optTrace

// Globals used in LEX
chbuf; charv; ch; rch; lex
token; lexval; exponent; wordnode
nilnode; truenode; falsenode; dummynode; mptnode
wrchbuf; chcount; lineno
dsw; declsyswords; namestart; nametable; lookupword
rdnumber; rdstrch; rdtag

// Globals used in SYN
checkfor; rdprog
rdnamelist; rname
rdnbdef; rbdef; rndef; rdef
formtree; plist
rnexp; rexp; rnbexp; rbexp
rncom; rcom; rbcom

// Globals used in TRN and the interpreter
 
trnext:300; trprog; trdef; trans
findlabels; translabels; transrhs
loaddefinee; declguesses; initnames; transscope
mapb; mapf; length; upssp
trcom; decldyn
declstatnames; checkdistinct; addname; cellwithname
trdecl; jumpcond
assign; load; fnbody; loadlist; transname
dvec; dvece; dvecp; dvect
comline; procname; resultlab; ssp; msp
outf; outname; outstring; outfv; outfn; outfsl
outfnn; outfl; outfs; outentry
outlab; outlabset; outvar; outstatvec; outstring
opstr; hasOperand
pc; sp; env; dump; count
mem; memt; regs
codev; codep; codet
datav; datap; datat
//stack; stackt
labv; refv; labmax; putc; putd; putref
setlab; setlabval; nextlab; labnumber; resolvelabels
interpret; printf
}

MANIFEST {                         //  Selectors
nametablesize = 541
c_tab         =   9
c_newline     =  10
}
 
LET start() = VALOF
{ LET treesize = 0
  AND codesize = 0
  AND datasize = 0
  AND argv = VEC 50
  AND argform =
        "PROG/A,TO=-o/K,TOKENS=-l/S,TREE=-p/S,CODE=-c/S,TRACE=-t/S"
  LET stdout = output()

  errmax   := 2
  errcount := 0
  fin_p, fin_l := level(), fin

  treevec, labv, refv, mem := 0, 0, 0, 0
  progstream, tostream := 0, 0
   
  writef("*nPAL (27 Oct 2010)*n")
 
  IF rdargs(argform, argv, 50)=0 DO fatalerr("Bad arguments*n")

  treesize := 10000
  codesize := 50000
  datasize :=  5000

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
  codev   := getvec(codesize)
  codep   := 0
  codet   := codesize

  datav   := getvec(datasize)
  datap   := 0
  datat   := datasize

  labv := getvec(1000)
  refv := getvec(1000)
  labmax := 1000

  UNLESS treevec & codev & datav & labv & refv DO
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

    IF optTree DO { writes("*nParse Tree*n*n")
                    plist(tree, 0, 20)
                    newline()
                  }
  
    IF errcount GOTO fin

    regs  := 10

    FOR i = 0 TO codet DO codev!i := 0
    FOR i = 0 TO datat DO datav!i := 0

    trprog(tree)                    // Translate the tree

    //stack := datap
    //stackt := memt

    IF errcount GOTO fin

    // Set the initial CSED machine state
    sp := 0           // sp
    pc := 0           // pc
    env := 0          // env
    dump := 0         // dump
    count := maxint   // count

 
    writef("*nStarting the interpreter*n*n")

    { LET ret = interpret()   // Execute the interpreter
      IF ret DO writef("Return code %n*n", ret)
      writef("*nInstructions executed: %n*n", maxint-count)
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
                token := rdnumber()
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
 
    CASE '[':
    CASE '(': token := Lparen;    BREAK
    CASE ']':
    CASE ')': token := Rparen;    BREAK 
    CASE '%': token := Percent;   BREAK 
    CASE '+': token := Plus;      BREAK
    CASE ',': token := Comma;     BREAK
    CASE '&': token := Logand;    BREAK
    CASE '|': token := Bar;       BREAK
    CASE '=': token := Valdef;    BREAK
    CASE '^': token := Power;     BREAK
    CASE ';': token := Seq;       BREAK
    CASE '$': token := Noshare;   BREAK
    CASE '.': token := Dot;       BREAK
 
    CASE '**':  rch()
                IF ch='**' DO { token := Power;  BREAK }
                token := Mult
                RETURN

    CASE '/':   rch()
                IF ch='/' DO
                { rch() REPEATUNTIL ch='*n' | ch=endstreamch
                  LOOP
                }
                token := Div
                RETURN
 
    CASE '<':   rch()
                IF ch='=' DO { token := Le;  BREAK }
                token := Lt
                RETURN

    CASE '>':   rch()
                IF ch='=' DO { token := Ge;  BREAK }
                token := Gt
                RETURN

    CASE '~':   rch()
                IF ch='=' DO { token := Ne;  BREAK }
                token := Not
                RETURN

    CASE '-':   rch()
                IF ch='>' | ch='**' DO { token := Cond; BREAK }
                token := Minus
                RETURN

    CASE ':':   rch()
                IF ch='=' DO { token := Ass;  BREAK }
                token := Colon
                RETURN
 
    CASE '*'': // A string constant
              { LET len = 0
                rch()
 
                UNTIL ch='*'' DO
                { IF len=255 DO synerr("Bad string constant")
                  len := len + 1
                  charv%len := rdstrch()
                }
 
                charv%0 := len
                wordnode := newvec(len/bytesperword+2)
                h1!wordnode := Stringconst
                FOR i = 0 TO len DO (@h2!wordnode)%i := charv%i
                token := Stringconst
                BREAK
              }
 
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
{ 
  dsw("and", And)
  dsw("aug", Aug)
  dsw("def", Def)
  dsw("do", Do)
  dsw("dummy", Dummy)
  dummynode := wordnode
  dsw("else", Ifnot)
  dsw("eq", Eq)
  dsw("false", False)
  falsenode := wordnode
  dsw("fn", Lambda)
  dsw("ge", Ge)
  dsw("goto", Goto)
  dsw("gt", Gt)
  dsw("if", If)
  dsw("ifnot", Ifnot)
  dsw("ifso", Ifso)
  dsw("in", In)
  ///dsw("jj", Jj)
  dsw("le", Le)
  dsw("let", Let)
  ///dsw("ll", Lambda)
  dsw("logand", Logand)
  dsw("lt", Lt)
  dsw("ne", Ne)
  dsw("nil", Nil)
  nilnode := wordnode
  dsw("not", Not)
  dsw("or", Logor)
  dsw("rec", Rec)
  dsw("res", Res)
  ///dsw("resultis", Res)
  dsw("sys", Sys)
  dsw("test", Test)
  ///dsw("then", Ifso)
  dsw("true", True)
  truenode := wordnode
  ///dsw("val", Val)
  dsw("valof", Valof)
  dsw("where", Where)
  dsw("within", Within)
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

AND rdnumber() = VALOF
{ LET tok, zeroes, ok = Int, 0, FALSE
  lexval, exponent := 0, 0

  WHILE '0'<=ch<='9' DO
  { ok := TRUE               // At least one digit
    TEST ch='0'
    THEN { zeroes := zeroes+1
         }
    ELSE { WHILE zeroes DO
           { IF lexval > maxint/10 TEST tok=Int
             THEN synerr("Integer too large")
             ELSE synerr("Too many significant digits")
             lexval := 10*lexval
             zeroes := zeroes-1
             exponent := exponent-1
           }
           IF lexval > maxint/10 TEST tok=Int
           THEN synerr("Integer too large")
           ELSE synerr("Too many significant digits")
           lexval := 10*lexval + ch - '0'
           exponent := exponent - 1
         }
    rch()
    WHILE ch='.' DO
    { IF tok=Real DO synerr("Bad real number")
      tok, ok := Real, FALSE  // No digits after dot yet
      exponent := zeroes
      rch()
    }
  }
  TEST tok=Real
  THEN { UNLESS ok DO
           synerr("No digits after decimal point")
         IF lexval>99999999 DO
           synerr("More than 8 significant digits in real number")
         IF exponent=0 DO
           synerr("No digits after decimal point in real number")
       }
  ELSE { WHILE zeroes DO
         { IF lexval > maxint/10 DO synerr("Number too large")
           lexval := 10*lexval
           zeroes := zeroes-1
         }
       }
  RESULTIS tok
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
  IF ch='**' DO
  { rch()
    SWITCHON ch INTO
    { DEFAULT:   synerr("Bad string or character constant")
      CASE '*'': CASE '"':  res := ch;     ENDCASE
      CASE 't':  CASE 'T':  res := '*t';   ENDCASE
      CASE 's':  CASE 'S':  res := '*s';   ENDCASE
      CASE 'n':  CASE 'N':  res := '*n';   ENDCASE
      CASE 'b':  CASE 'B':  res := '*b';   ENDCASE
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
  mptnode := mk1(Mpt)

  lex()

  IF optTokens DO            // For debugging lex.
  { writef("token = %i3 %s", token, opstr(token))
    IF token=Int    DO writef("       %n",  lexval)
    IF token=Real   DO writef("      %ne%n",  lexval, exponent)
    IF token=Name   DO writef("      %s",   charv)
    IF token=Stringconst DO
    { writef("    *'")
      FOR i = 1 TO charv%0 SWITCHON charv%i INTO
      { DEFAULT:   wrch(charv%i); ENDCASE
        CASE '*n': writes("**n"); ENDCASE
        CASE '*p': writes("**p"); ENDCASE
        CASE '*t': writes("**t"); ENDCASE
      }
      writef("*'")
    }
    newline()
    IF token=Eof RESULTIS 0
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
{ // P -> def D0 .. def D0 in C0 eof |
  //      C0 eof

  LET a, ln = 0, lineno

  SWITCHON token INTO
  { DEFAULT:
      a := rcom(0)
      ENDCASE

    CASE Eof:
      ENDCASE  // No program!

    CASE Def:
    { LET d = rndef()
      a := mk4(Def, d, rdprog(), ln)
      ENDCASE
    }

    CASE In:
      a := rncom(0)
      ENDCASE
  }
  UNLESS token=Eof DO synerr("Incorrect termination")

  RESULTIS a
}

AND rnbdef(n) = VALOF
{ lex()
  RESULTIS rbdef(n)
}

AND rbdef(n) = VALOF
{ // BD -> N,...,N = E
  //       N BV...BV = E
  //       ( D )
  //       rec D
  LET op, ln = token, lineno

  SWITCHON op INTO
  { DEFAULT:
      synerr("Bad definition, name, rec or '(' expected")

    CASE Name:
      { LET names = rname()
        ln := lineno

        IF token=Comma DO
        { // Must be a simultaneous definition
          // N ,..., N = C0
          names := rdnamelist(names)
          checkfor(Valdef, "Bad definition")
          RESULTIS mk4(Valdef, names, rcom(0), ln)
        }

        IF token=Valdef RESULTIS mk4(Valdef, names, rncom(0), ln)

        { // Must be a function definition
          // N BV ... BV = C0
          LET v = VEC 50
          AND i, b = 0, ?
          WHILE i<=50 DO
          { UNLESS token=Lparen | token=Name BREAK
            v!i := rbv()
            i := i+1
          }
          UNLESS i~=0 & token=Valdef DO synerr("Bad definition")
          b := rncom(0)
          WHILE i>0 DO
          { i := i-1
            b := mk4(Lambda, v!i, b, ln)
          }
          RESULTIS mk4(Valdef, names, b, ln)
        }
      }

    CASE Lparen:
    { LET a = rndef(0)
      checkfor(Rparen, "Bad definition")
      RESULTIS a
    }

    CASE Rec:
      lex()
      UNLESS n=0 DO synerr("Redundant 'rec'")
      RESULTIS mk3(Rec, rnbdef(2), ln)
  }
}

AND rndef(n) = VALOF { lex(); RESULTIS rdef(n) }

AND rdef(n) = VALOF
{ // D -> D and D
  //      D within D
  //      BD
  LET a = rbdef(0)
  LET b = 0

  { LET op, ln = token, lineno

//sawritef("rdef: op=%s ln=%n*n", opstr(op), ln)
    SWITCHON op INTO
    { DEFAULT:
        RESULTIS a

      CASE And:
        IF a=0 DO synerr("Definition missing before 'and'")
        IF n>=6 RESULTIS a
        { LET i = 1
          LET v = VEC 100
          WHILE token=And DO
          { v!i := rnbdef(0)
            i := i+1
          }
          b := a
          a := newvec(i+1)
          a!0, a!1, a!2 := And, i+1, b
          FOR j = 1 TO i-1 DO a!(j+2) := v!j
          LOOP
        }

      CASE Within:
        IF a=0 DO synerr("Definition missing before 'within'")
        IF n>=3 RESULTIS a
        a := mk4(Within, a, rndef(0), ln)
        LOOP
    }
  } REPEAT
}

AND rbv() = VALOF
{ // Only called when token is Name or Lparen
  LET a = ?
  IF token=Name RESULTIS rname()
  checkfor(Lparen, "'(' expected")
  IF token=Rparen DO
  { lex()
    RESULTIS mptnode
  }
  a := rdnamelist(0)
  checkfor(Rparen, "Bad bound variable list")
  RESULTIS a
}

AND rdnamelist(n) = VALOF
{ LET a, b, i, ln = 0, n, 1, lineno
  LET v = VEC 100
  IF n=0 DO
  { UNLESS token=Name DO
      synerr("Bad name list")
    b := rname()
  }
  UNLESS token=Comma RESULTIS b
  WHILE token=Comma DO
  { lex()
    UNLESS token=Name DO synerr("A name is missing")
    v!i := rname()
    i := i+1
  }
  a := newvec(i+1)
  h1!a, h2!a, h3!a := Comma, i, b
  FOR j = 1 TO i-1 DO a!(j+2) := v!j
  RESULTIS a
}

AND rname() = VALOF
{ LET a = wordnode
  checkfor(Name, "Name expected")
  RESULTIS a
}

AND rarg() = VALOF
{ LET a, ln = 0, lineno
sawritef("rarg: token=%s*n", opstr(token))
  SWITCHON token INTO
  { DEFAULT:
      RESULTIS 0  // Not suitable as an unparenthesised argument

  }
}
 
LET rbexp(n) = VALOF
{ LET a, op, ln = 0, token, lineno
 
  SWITCHON op INTO
 
  { DEFAULT:
      synerr("Error in expression")

    CASE True:
    CASE False:
    CASE Name:
    CASE Nil:
    CASE Stringconst:
    CASE Sys:
      a := wordnode
      lex()
      RESULTIS a
   
    CASE Lparen:
      lex()
      TEST token=Rparen
      THEN a := nilnode
      ELSE a := rcom(0)
      checkfor(Rparen, "')' missing")
      IF n<=8 DO a := mk3(Paren, a, ln)
      RESULTIS a
 
    CASE Int:
      a := mk2(Int, lexval)
      lex()
      RESULTIS a
 
    CASE Real:
      a := mk3(Real, lexval, exponent)
      lex()
      RESULTIS a
 
    CASE Noshare:
      UNLESS n<=36 DO synerr("'$' or 'sys' out of context")
      RESULTIS mk3(op, rnexp(38), ln)
 
    CASE Plus:
      UNLESS n<=30 DO synerr("'+' out of context")
      RESULTIS rnexp(32)
 
    CASE Minus:
      UNLESS n<=30 DO synerr("'-' out of context")
      a := rnexp(32)
      TEST h1!a=Int | h1!a=Real
      THEN h2!a := - h2!a
      ELSE a := mk2(Neg, a)
      RESULTIS a
 
    CASE Not:
      UNLESS n<=24 DO synerr("'not' out of context")
      RESULTIS mk2(Not, rnexp(26))
  }
}
 
AND rnexp(n) = VALOF { lex(); RESULTIS rexp(n) }
 
AND rexp(n) = VALOF
{ LET a, b, p = rbexp(n), 0, 0

  { LET op, ln = token, lineno

    SWITCHON op INTO
    { DEFAULT:
        RESULTIS a
 
      // Tokens that start a function argument
      
      CASE Nil:
      CASE True:
      CASE False:
      CASE Int:
      CASE Real:
      CASE Stringconst:
      CASE Name:
        a := mk4(Apply, a, rbexp(0), ln)
        LOOP

      CASE Lparen:
        lex()
        IF token=Rparen DO
        { // Empty argument list
          lex()
          RESULTIS nilnode
        }
        b := rcom(0)
        checkfor(Rparen, "')' expected")
        a := mk4(Apply, a, b, ln)
        LOOP

      CASE Comma:
        IF n>14 RESULTIS a
        { LET i = 1
          LET v = VEC 500
          WHILE token=Comma DO
          { v!i := rnexp(16)
            i := i+1
          }
          b := a
          a := newvec(i+1)
          a!0, a!1, a!2 := Comma, i, b
          FOR j = 1 TO i-1 DO a!(j+2) := v!j
//sawritef("rexp: Comma i=%n*n", i)
          LOOP
        }

      CASE Aug:
        IF n>16 RESULTIS a
        a := mk4(Aug, a, rnexp(18), ln)
        LOOP

      CASE Cond:
        IF n>18 RESULTIS a
        b := rnexp(18)
        checkfor(Bar, "Bad conditional expression")
        a := mk5(Cond, a, b, rexp(18), ln)
        LOOP

      CASE Logor:
        IF n>20 RESULTIS a
        a := mk4(op, a, rnexp(22), ln)
        LOOP

      CASE Logand:
        IF n>22 RESULTIS a
        a := mk4(op, a, rnexp(24), ln)
        LOOP

      CASE Eq:CASE Le:CASE Lt:CASE Ne:CASE Ge:CASE Gt:
        IF n>26 RESULTIS a
        a := mk4(op, a, rnexp(30), ln)
        LOOP

      CASE Plus:CASE Minus:
        IF n>30 RESULTIS a
        a := mk4(op, a, rnexp(32), ln)
        LOOP

      CASE Mult:CASE Div:
        IF n>32 RESULTIS a
        a := mk4(op, a, rnexp(34), ln)
        LOOP

      CASE Power:
        IF n>36 RESULTIS a
        a := mk4(op, a, rnexp(34), ln)
        LOOP

      CASE Percent:
        IF n>36 RESULTIS a
        lex()
        UNLESS token=Name DO synerr("Name expected in '%' construct")
        b := rname()
        a := mk4(Comma, 2, a, rexp(38))
        a := mk4(Apply, b, a, ln)
        LOOP
    }
  } REPEAT
}

AND rncom(n) = VALOF
{ lex()
  RESULTIS rcom(n)
}

AND rcom(n) = VALOF
{ LET a = rbcom(n)

  { LET op, ln = token, lineno
    SWITCHON op INTO
 
    { DEFAULT:
        BREAK
 
      CASE Seq:
        IF n>6 RESULTIS a
        a := mk4(Seq, a, rncom(6), ln)
        LOOP

      CASE Where:
        IF n>2 RESULTIS a
        a := mk4(Where, a, rnbdef(0), ln)
        LOOP

      CASE Colon:
        UNLESS h1!a=Name & n<=8 DO
          synerr("Syntax error in label")
        a := mk5(Colon, a, rncom(8), 0, ln)
        LOOP
    }
  } REPEAT

  RESULTIS a
}

AND rbcom(n) = VALOF
{ LET op, ln, a, b = token, lineno, 0, 0

  SWITCHON op INTO
  { DEFAULT: // Must be an expression
    { a := rexp(n)
      ln := lineno
      IF token=Ass RESULTIS mk4(Ass, a, rnexp(14), ln)
      RESULTIS a
    }

    CASE Let:
    { UNLESS n=0 DO synerr("'let' out of context")
      a := rndef(0)
      checkfor(In, "'in' expected in 'let' construct")
      RESULTIS mk4(Let, a, rcom(0), ln)
    }

    CASE Lambda:
    { LET v = VEC 50
      AND i = 0
      UNLESS n=0 DO synerr("'fn' out of context")
      lex()
      WHILE i<=50 DO
      { UNLESS token=Lparen | token=Name BREAK
        v!i := rbv()
        i := i+1
      }
      IF i=0 DO synerr("No bound variable list after 'fn'")
      checkfor(Dot, "'.' missing in 'fn' construct")
      a := rcom(0)
      WHILE i>0 DO
      { i := i-1
        a := mk4(Lambda, v!i, a, ln)
      }
      RESULTIS a
    }

    CASE Valof:
      UNLESS n<=4 DO synerr("'valof' out of context")
      RESULTIS mk3(op, rncom(6), ln)
 
    CASE Test:
      UNLESS n<=10 DO synerr("'test' out of context")
      a := rnexp(20)
      SWITCHON token INTO
      { DEFAULT:
          synerr("Bad 'test' command")

        CASE Ifso:
          b := rncom(8)
          checkfor(Ifnot, "'ifnot' expected")
          RESULTIS mk5(Cond, a, b, rncom(8), ln)

        CASE Ifnot:
          b := rncom(8)
          checkfor(Ifso, "'ifnot' expected")
          RESULTIS mk5(Cond, a, rncom(8), b, ln)
      }


    CASE While:
    CASE If:
    { LET op = token
      UNLESS n<=10 DO synerr("'if' or 'while' out of context")     
      a := rnexp(20)
      checkfor(Do, "'do' expected")
      TEST op=If
      THEN RESULTIS mk5(Cond, a, rcom(8), dummynode, ln)
      ELSE RESULTIS mk5(While, a, rcom(8), ln)
    }

    CASE Goto:
      RESULTIS mk3(Goto, rnexp(38), ln)

    CASE Res:
      RESULTIS mk3(Res, rnexp(14), ln)

  }
}

LET opstr(op) = VALOF SWITCHON op INTO
{ DEFAULT:          sawritef("opstr: unknown op: %n*n", op)
                    RESULTIS "###Unknown op ###"

  CASE Ass:         RESULTIS "Ass"
  CASE And:         RESULTIS "And"
  CASE Apply:       RESULTIS "Apply"
  CASE Aug:         RESULTIS "Aug"
  CASE Bar:         RESULTIS "Bar"
  CASE Blocklink:   RESULTIS "Blocklink"
  CASE Colon:       RESULTIS "Colon"
  CASE Comma:       RESULTIS "Comma"
  CASE Cond:        RESULTIS "Cond"
  CASE Decllabel:   RESULTIS "Decllabel"
  CASE Declname:    RESULTIS "Declname"
  CASE Declnames:   RESULTIS "Declnames"
  CASE Def:         RESULTIS "Def"
  CASE Div:         RESULTIS "Div"
  CASE Do:          RESULTIS "Do"
  CASE Dot:         RESULTIS "Dot"
  CASE Dummy:       RESULTIS "Dummy"
  CASE Eof:         RESULTIS "Eof"
  CASE Eq:          RESULTIS "Eq"
  CASE Ifnot:       RESULTIS "Ifnot"
  CASE Power:       RESULTIS "Power"
  CASE False:       RESULTIS "False"
  CASE FormClosure: RESULTIS "FormClosure"
  CASE FormLvalue:  RESULTIS "FormLvalue"
  CASE FormRvalue:  RESULTIS "FormRvalue"
  CASE Ge:          RESULTIS "Ge"
  CASE Goto:        RESULTIS "Goto"
  CASE Gt:          RESULTIS "Gt"
  CASE Halt:        RESULTIS "Halt"
  CASE If:          RESULTIS "If"
  CASE In:          RESULTIS "In"
  CASE Initname:    RESULTIS "Initname"
  CASE Initnames:   RESULTIS "Initnames"
  CASE Int:         RESULTIS "Int"
  CASE Jj:          RESULTIS "Jj"
  CASE Jump:        RESULTIS "Jump"
  CASE JumpF:       RESULTIS "JumpF"
  CASE Lab:         RESULTIS "Lab"
  CASE Lambda:      RESULTIS "Lambda"
  CASE Le:          RESULTIS "Le"
  CASE Let:         RESULTIS "Let"
  CASE LoadE:       RESULTIS "LoadE"
  CASE LoadF:       RESULTIS "LoadF"
  CASE LoadGuess:   RESULTIS "LoadGuess"
  CASE LoadJ:       RESULTIS "LoadJ"
  CASE LoadL:       RESULTIS "LoadL"
  CASE LoadN:       RESULTIS "LoadN"
  CASE LoadR:       RESULTIS "LoadR"
  CASE LoadS:       RESULTIS "LoadS"
  CASE Logand:      RESULTIS "Logand"
  CASE Logor:       RESULTIS "Logor"
  CASE Lose1:       RESULTIS "Lose1"
  CASE Lparen:      RESULTIS "Lparen"
  CASE Lt:          RESULTIS "Lt"
  CASE Members:     RESULTIS "Members"
  CASE Minus:       RESULTIS "Minus"
  CASE Mpt:         RESULTIS "Mpt"
  CASE Mult:        RESULTIS "Mult"
  CASE Name:        RESULTIS "Name"
  CASE Ne:          RESULTIS "Ne"
  CASE Neg:         RESULTIS "Neg"
  CASE Nil:         RESULTIS "Nil"
  CASE Not:         RESULTIS "Not"
  CASE Paren:       RESULTIS "Paren"       
  CASE Percent:     RESULTIS "Percent"       
  CASE Plus:        RESULTIS "Plus"
  CASE Real:        RESULTIS "Real"       
  CASE Rec:         RESULTIS "Rec"       
  CASE Res:         RESULTIS "Res"
  CASE Reslink:     RESULTIS "Reslink"
  CASE RestoreE1:   RESULTIS "RestoreE1"
  CASE Return:      RESULTIS "Return"
  CASE Rparen:      RESULTIS "Rparen"
  CASE Save:        RESULTIS "Save"
  CASE Seq:         RESULTIS "Seq"
  CASE SetlabEs:    RESULTIS "SetlabEs"
  CASE Setup:       RESULTIS "Setup"
  CASE Stringconst: RESULTIS "Stringconst"
  CASE Sys:         RESULTIS "Sys"
  CASE Test:        RESULTIS "Test"
  CASE TestEmpty:   RESULTIS "TestEmpty"
  CASE Ifso:        RESULTIS "Ifso"
  CASE True:        RESULTIS "True"
  CASE Tuple:       RESULTIS "Tuple"
  CASE Noshare:     RESULTIS "Noshare"
  CASE Update:      RESULTIS "Update"
  CASE Valdef:      RESULTIS "Valdef"
  CASE Valof:       RESULTIS "Valof"
  CASE Where:       RESULTIS "Where"
  CASE Within:      RESULTIS "Within"
}

LET plist(x, n, d) BE
{ LET op, size, ln = ?, 0, 0
  LET v = TABLE 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

  IF x=0 DO { writes("Null"); RETURN  }
 
  op := h1!x

  SWITCHON op INTO
  { DEFAULT:
writef("Default op=%s*n", opstr(op)); RETURN

    CASE Int:     writef("Int %n", h2!x);           RETURN
    CASE Real:    writef("Real %ne%n", h2!x, h3!x); RETURN
    CASE Name:    writef("Name %s", x+2);           RETURN
    CASE Stringconst:  
                { LET s = x+1
                  writef("Stringconst *'")
                  FOR i = 1 TO s%0 SWITCHON s%i INTO
                  { DEFAULT:   wrch(s%i); ENDCASE
                    CASE '*n': writes("**n"); ENDCASE
                    CASE '*p': writes("**p"); ENDCASE
                    CASE '*t': writes("**t"); ENDCASE
                  }
                  writef("*'")
                  RETURN
                }

    CASE Colon:
         size, ln := 3, h5!x; ENDCASE

    CASE Cond: CASE Test: CASE Percent:
         size, ln := 4, h5!x; ENDCASE

    CASE Power: CASE Mult: CASE Div: CASE Plus: CASE Minus:
    CASE Eq: CASE Ne: CASE Lt: CASE Gt: CASE Le: CASE Ge:
    CASE Logand: CASE Logor: CASE Aug:
    CASE Let: CASE Where: CASE Within:
    CASE Lab:
    CASE Ass: CASE Apply: CASE Lambda:
    CASE Def: CASE Valdef: CASE Tuple: CASE Seq:
    CASE If:
         size, ln := 3, h4!x; ENDCASE

    CASE Comma: CASE And:
         // x -> [op, n, a1 ,..., an]
         size := h2!x+1
//sawritef("plist: Comma size=%n*n", size)
         x := x+1
         ENDCASE

    CASE Noshare:
    CASE Rec:
    CASE Valof: 
    CASE Goto: 
    CASE Res:
    CASE Sys:
    CASE Paren:
         size, ln := 2, h3!x; ENDCASE

    CASE True: CASE False:
    CASE Nil: CASE Mpt:
    CASE Dummy:
         size := 1;       ENDCASE
  }
 
  IF n=d DO { writes("Etc"); RETURN }
  writef("%s", opstr(op))
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
{ LET n = ?
  FOR i = 0 TO labmax DO labv!i, refv!i := -1, 0

  comline, procname, labnumber := 1, 0, 0
  ssp, msp := 0, 1

  IF optCode DO writef("*nCompiled code:*n*n")

  n := nextlab()
  outfl(Setup, n)

  translabels(x)

  trans(x, Val)
  UNLESS ssp=1 DO writef("*nSSP error*n")
  outf(Halt)
  outlabset(n, msp)

  //resolvelabels()

  writef("*nProgram size: %n data size: %n*n*n",
          codep, datap)
}

LET trans(x, mode) BE
// x       is the program
// mode is Val or Ref
{ LET op = h1!x

  IF x=0 DO
  { writes("*nExpression missing*n")
    outf(Nil)
    upssp(1)
    IF mode=Ref DO outf(FormLvalue)
    RETURN
  }

//writef("trans: op=%s*n", opstr(op))
  SWITCHON op INTO
  { DEFAULT:
      // It must be an expression
      load(x)
      RETURN

    CASE Let:
    { LET lab1 = nextlab()
      LET lab2 = nextlab()
      comline := h5!x
      transrhs(h2!x)
      outfl(Blocklink, lab1)
      IF ssp=msp DO msp := ssp+1
      transscope(x, lab2, mode)
      outlab(lab1)             
      RETURN
    }
  
    CASE Def:
      transrhs(h2!x)
      declnames(h2!x)
      translabels(h3!x)
      trans(h3!x, Val)
      RETURN

    CASE Mult: CASE Div: CASE Power: CASE Plus: CASE Minus:
    CASE Eq: CASE Ne: CASE Lt: CASE Le: CASE Gt: CASE Ge:
    CASE Logand: CASE Logor:
      trans(h3!x, Val)
      trans(h2!x, Val)
      outf(op)
      ssp := ssp-1
      IF mode=Ref DO outf(FormLvalue)
      RETURN

    CASE Aug:
      trans(h3!x, Ref)
      trans(h2!x, Val)
      outf(Aug)
      ssp := ssp-1
      IF mode=Ref DO outf(FormLvalue)
      RETURN

    CASE Apply:
      trans(h3!x, Ref)
      trans(h2!x, Ref)
      outf(Apply)
      ssp := ssp-1
      IF mode=Val DO outf(FormRvalue)
      RETURN

    CASE Pos:
    CASE Neg:
    CASE Not:
      trans(h2!x, Val)
      outf(op)
      IF mode=Ref DO outf(FormLvalue)
      RETURN

    CASE Noshare:
      trans(h2!x, Val)
      IF mode=Ref DO outf(FormLvalue)
      RETURN

    CASE Comma:
    { LET len = length(x)
      LET r(x) BE trans(x, Ref)
      mapb(r, x)
      outfn(Tuple, len)
      ssp := ssp - len + 1
      IF mode=Ref DO outf(FormLvalue)
      RETURN
    }

    CASE Lambda:
    { LET lab1 = nextlab()
      LET lab2 = nextlab()
      LET lab3 = nextlab()
      outfl(FormClosure, lab1)
      upssp(1)
      outfl(Jump, lab2)
      outlab(lab1)
      transscope(x, lab3, Ref)
      outlab(lab2)
      IF mode=Ref DO outf(FormLvalue)
      RETURN
    }

    CASE Colon:
      IF h4!x=0 DO
      { trnerr("Label %s improperly used", h3!(h2!x))
      }
      outlab(h4!x)
      trans(h3!x, mode)
      RETURN

    CASE Seq:
      trans(h2!x, Val)
      outf(Lose1)
      trans(h3!x, mode)
      RETURN

    CASE Valof:
    { LET lab1 = nextlab()
      LET lab2 = nextlab()
      outfl(Reslink, lab1)
      ssp := ssp+1
      IF ssp>=msp DO msp := ssp+1
      { LET a, b = ssp, msp
        ssp, msp := 0, 1
        outfl(Save, lab2)
        outf(Jj)
        outf(FormLvalue)
        outf(Declname)
        outname(Name, 0, "**RES**")
        translabels(h2!x)
        trans(h2!x, Ref)
        outf(Return)
        UNLESS ssp=1 DO trnerr("SSP Error")
        outlabset(lab2, msp)
        ssp, msp := a, b
      }
      outlab(lab1)
      IF mode=Val DO outf(FormRvalue)
      RETURN
    }

    CASE Res:
      trans(h2!x, Ref)
      outf(Res)
      ssp := ssp-1
      RETURN

    CASE Goto:
      trans(h2!x, Val)
      outf(Goto)
      ssp := ssp-1
      RETURN

    CASE Cond:
    { LET lab1 = nextlab()
      LET lab2 = nextlab()
      trans(h2!x, Val)
      outfl(JumpF, lab1)
      ssp := ssp-1
      trans(h3!x, mode)
      outfl(Jump, lab2)
      outlab(lab1)
      ssp := ssp-1
      trans(h4!x, mode)
      outlab(lab2)
      RETURN
    }

    CASE While:
    { LET lab1 = nextlab()
      LET lab2 = nextlab()
      outlab(lab2)
      trans(h2!x, Val)
      outfl(JumpF, lab1)
      ssp := ssp-1
      trans(h3!x, Val)
      outf(Lose1)
      outfl(Jump, lab2)
      outlab(lab1)
      outf(Dummy)
      IF mode=Ref DO outf(FormLvalue)
      RETURN
    }

    CASE Ass:
    { LET len = length(h2!x)
      comline := h4!x
      trans(h2!x, Ref)
      trans(h3!x, Val)
      outfn(Update, len)
      ssp := ssp-1
      IF mode=Ref DO outf(FormLvalue)
      RETURN
    }

    CASE Paren:
      translabels(h2!x)
      trans(h2!x, mode)
      RETURN

    CASE Nil:
    CASE Dummy:
    CASE True:
    CASE False:
    CASE Sys:
      outf(op)
      upssp(1)
      IF mode=Ref DO outf(FormLvalue)
      RETURN

    CASE Name:
      outf(mode=Val -> LoadR, LoadL)
      outname(x)
      upssp(1)
      RETURN

    CASE Int:
      outfn(LoadN, h2!x)
      upssp(1)
      RETURN

    CASE Real: 
      outfn(LoadF, h2!x, h3!x)
      upssp(1)
      RETURN

    CASE Stringconst:
      outf(LoadS)
      outstring(x)
      upssp(1)
      IF mode=Ref DO outf(FormLvalue)
      RETURN
  }
}

AND findlabels(x) = VALOF
{ IF x=0 RESULTIS 0
  SWITCHON h1!x INTO
  { DEFAULT:
      RESULTIS 0

    CASE Colon:
    { LET lab = nextlab()
      h4!x := lab
      outfsl(Decllabel, h2!x, lab)
      RESULTIS 1 + findlabels(h3!x)
    }

    CASE Paren:
      RESULTIS findlabels(h2!x)

    CASE Cond:
      RESULTIS findlabels(h3!x) +
               findlabels(h4!x)

    CASE While:
      RESULTIS findlabels(h3!x)

    CASE Seq:
      RESULTIS findlabels(h2!x) +
               findlabels(h3!x)
  }
}

AND translabels(x) BE
{ LET n = findlabels(x)
  IF n DO outf(SetlabEs, n)
}

AND transrhs(x) BE
{ IF x=0 RETURN

  SWITCHON h1!x INTO
  { DEFAULT:
      RETURN

    CASE And:
    { LET len = length(x)
      mapb(transrhs, x)
      outfn(Tuple, len)
      ssp := ssp - len + 1
      outf(FormLvalue)
      RETURN
    }

    CASE Valdef:
      trans(h3!x, Ref)
      RETURN

    CASE Rec:
      outf(LoadE)
      upssp(1)
      declguesses(h2!x)
      transrhs(h2!x)
      initnames(h2!x)
      loaddefinee(h2!x)
      outf(RestoreE1)
      ssp := ssp-1
      RETURN

    CASE Within:
    { LET lab1 = nextlab()
      LET lab2 = nextlab()
      transrhs(h2!x)
      outfl(Blocklink, lab1)
      IF ssp=msp DO msp := ssp+1
      { LET a, b = ssp, msp
        ssp, msp := 0, 1
        outfl(Save, lab2)
        declnames(h2!x)
        transrhs(h3!x)
        outf(Return)
        UNLESS ssp=1 DO trnerr("SSP error")
        outlabset(lab2, msp)
        ssp, msp := a, b
      }
      outlab(lab1)
      RETURN
    }
  }
}

AND declnames(x) BE
{ IF x=0 RETURN
  SWITCHON h1!x INTO
  { DEFAULT:
      trnerr("Bad bound variable list")
      RETURN

    CASE Name:
      outf(Declname)
      outname(x)
      ssp := ssp-1
      RETURN

    CASE Comma:
      outfn(Declnames, length(x))
      ssp := ssp-1
      mapf(outname, x)
      RETURN

    CASE And:
    { LET len = length(x)
      outfn(Members, len)
      upssp(len-1)
      mapf(declnames, x)
      RETURN
    }

    CASE Rec:
    CASE Valdef:
      declnames(h2!x)
      RETURN

    CASE Within:
      declnames(h3!x)
      RETURN

    CASE Mpt:
      outf(TestEmpty)
      ssp := ssp-1
      RETURN
  }
}

AND loaddefinee(x) BE
{ IF x=0 RETURN
  SWITCHON h1!x INTO
  { DEFAULT:
      trnerr("Bad definition")
      RETURN

    CASE Name:
      outf(LoadR); outname(x)
      upssp(1)
      outf(FormLvalue)
      RETURN

    CASE And:
    CASE Comma:
    { LET len = length(x)
      mapb(loaddefinee, x)
      outfn(Tuple, len)
      ssp := ssp - len + 1
      outf(FormLvalue)
      RETURN
    }

    CASE Rec:
    CASE Valdef:
      loaddefinee(h2!x)
      RETURN

    CASE Within:
      loaddefinee(h3!x)
      RETURN

  }
}

AND declguesses(x) BE
{ IF x=0 RETURN
  SWITCHON h1!x INTO
  { DEFAULT:
      trnerr("Bad definition")
      RETURN

    CASE Name:
      outf(LoadGuess)
      IF ssp=msp DO msp := ssp+1
      outf(Declname); outname(x)
      RETURN

    CASE And:
    CASE Comma:
      mapf(declguesses, x)
      RETURN

    CASE Rec:
    CASE Valdef:
      declguesses(h2!x)
      RETURN

    CASE Within:
      declguesses(h3!x)
      RETURN
  }
}

AND initnames(x) BE
{ IF x=0 RETURN
  SWITCHON h1!x INTO
  { DEFAULT:
      trnerr("Bad definition")
      RETURN

    CASE Name:
      outf(Initname); outname(x)
      ssp := ssp-1
      RETURN

    CASE And:
    { LET len = length(x)
      outfn(Members, len)
      upssp(len-1)
      outfn(Initnames, len)
      mapf(initnames, x)
      RETURN
    }

    CASE Comma:
    { LET len = length(x)
      outfn(Initnames, len)
      ssp := ssp-1
      mapf(outname, x)
      RETURN
    }

    CASE Rec:
    CASE Valdef:
      initnames(h2!x)
      RETURN

    CASE Within:
      initnames(h3!x)
      RETURN
  }
}

AND transscope(x, n, mode) BE
{ LET a, b = ssp, msp
  ssp, msp := 1, 1
  outfn(Save, n)
  declnames(h2!x)
  translabels(h3!x)
  trans(h3!x, mode)
  outf(Return)
  UNLESS ssp=1 DO trnerr("SSP error")
  outlabset(n, msp)
  ssp, msp := a, b
}

AND mapf(r, x) BE
{ LET len = h2!x
  FOR i = 1 TO len DO r(x!(i+1))
}

AND mapb(r, x) BE
{ LET len = h2!x
  FOR i = len TO 1 BY -1 DO r(x!(i+1))
}

AND length(x) = h1!x=And | h1!x=Comma -> h2!x, 1

AND upssp(x) BE
{ ssp := ssp+x
  IF ssp>msp DO msp := ssp
}

AND wrf(form, a, b, c) BE IF optCode DO writef(form, a, b, c)

AND outf(op) BE
{ wrf("%s*n", opstr(op))
  putc(op)
}

AND outname(x) BE
{ LET name = @h3!x
  LET len = name%0
  //outfn(Name, len)
  FOR i = 1 TO len DO putc(name%i)
  IF optCode DO writef(" %s*n", name)
}

AND outstring(x) BE
{ LET name = @h3!x
  LET len = name%0
  outfn(Stringconst, len)
  FOR i = 1 TO len DO putc(name%i)
  IF optCode DO writef(" %s", name)
}

AND outfv(op, var) BE
{ wrf("%s %s*n", opstr(op), var)
  putc(op); putc(var)
}

AND outn(a) BE
{ wrf("%n*n", a)
  putc(a)
}

AND outfn(op, a) BE
{ wrf("%s %n*n", opstr(op), a)
  putc(op); putc(a)
}

AND outfnn(op,a, b) BE
{ wrf("%s %n %n*n", opstr(op), a, b)
  putc(op); putc(a); putc(b)
}

AND outfsl(op,a, b) BE
{ wrf("%s %s L%n*n", opstr(op), a, b)
  putc(op); putc(a); putc(b)
}

AND outfl(op, lab) BE
{ wrf("%s L%n*n", opstr(op), lab)
  putc(op); putref(lab)
}

AND outlab(lab) BE
{ wrf("Lab L%n*n", lab)
  setlab(lab, codep)
}

AND outlabset(lab, val) BE
{ wrf("L%n=%n*n", lab, val)
  setlab(lab, val)
}

AND outentry(l1, l2) BE
{ wrf("Entry L%n L%n*n", l1, l2)
  putref(l2)
  setlab(l1, codep)
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
               ELSE { codev!codep := w
                      codep := codep+1
                    }

AND putd(w) BE TEST datap>datat
               THEN trnerr("More data space needed")
               ELSE { datav!datap := w
                      datap := datap+1
                    }

AND putref(lab) BE TEST codep>codet
                   THEN trnerr("More code space needed")
                   ELSE { codev!codep := refv!lab
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
  WHILE p DO { LET np = codev!p
               codev!p, p := labval, np
             }
}

AND interpret(regs, mem) = VALOF
{ // Execute one or more SCED instructions
  // sp holds S
  // pc holds C
  // env holds E
  // dump holds D -> previous [S, E, C, D]
  // count is the count of instruction executed
  LET retcode = 0

  { // Start of main loop
    LET op = codev!pc                // Fetch next instruction
    IF optTrace DO
    { writef("%i5: %t8", pc, opstr(op))
      //IF hasOperand(op) DO writef(" %n", pc!1)
      newline()
    }
    IF count<=0 DO { retcode := 3; BREAK } // Zero count
    count := count-1
    pc := pc+1

    SWITCHON op INTO
    { DEFAULT:      retcode := 1;    BREAK    // Unknown op code

      CASE Halt:    BREAK
/*
      CASE Laddr:   sp := sp+1; sp!0 := !pc;       pc := pc+1; LOOP
      CASE Ln:      sp := sp+1; sp!0 := !pc;       pc := pc+1; LOOP
      CASE Lp:      sp := sp+1; sp!0 := pp!(!pc);  pc := pc+1; LOOP
      CASE Llp:     sp := sp+1; sp!0 := pp+!pc-mem;pc := pc+1; LOOP
      CASE Ll:      sp := sp+1; sp!0 := mem!(!pc); pc := pc+1; LOOP
      CASE Sp:      pp!(!pc) := sp!0; sp := sp-1;  pc := pc+1; LOOP
      CASE Sl:      mem!(!pc):= sp!0; sp := sp-1;  pc := pc+1; LOOP

      CASE Apply: { LET opp, retaddr = pp, pc+1
                    pp, pc := pp+!pc, sp!0+mem
                    pp!0, pp!1, pp!2 := opp-mem, retaddr-mem, pc-mem
                    sp := pp+2
                    LOOP
                  }

      CASE Ret:     res := sp!0
                  { LET npp, npc = pp!0+mem, pp!1+mem
                    sp := pp-1
                    pp, pc := npp, npc
                    LOOP
                  }
      CASE Neg:     sp!0 :=  -  sp!0;                      LOOP
      CASE Not:     sp!0 := NOT sp!0;                      LOOP
      CASE Mult:     sp := sp-1; sp!0 := sp!0  *  sp!1;     LOOP
      CASE Div:     sp := sp-1; sp!0 := sp!0  /  sp!1;     LOOP
      CASE Mod:     sp := sp-1; sp!0 := sp!0 REM sp!1;     LOOP
      CASE Add:     sp := sp-1; sp!0 := sp!0  +  sp!1;     LOOP
      CASE Minus:     sp := sp-1; sp!0 := sp!0  -  sp!1;     LOOP
      CASE Eq:      sp := sp-1; sp!0 := sp!0  =  sp!1;     LOOP
      CASE Ne:      sp := sp-1; sp!0 := sp!0 ~=  sp!1;     LOOP
      CASE Le:      sp := sp-1; sp!0 := sp!0 <=  sp!1;     LOOP
      CASE Ge:      sp := sp-1; sp!0 := sp!0 >=  sp!1;     LOOP
      CASE Lt:      sp := sp-1; sp!0 := sp!0  <  sp!1;     LOOP
      CASE Gt:      sp := sp-1; sp!0 := sp!0  >  sp!1;     LOOP
      CASE Logand:  sp := sp-1; sp!0 := sp!0  &  sp!1;     LOOP
      CASE Logor:   sp := sp-1; sp!0 := sp!0  |  sp!1;     LOOP
      CASE Jt:      sp := sp-1; pc := sp!1->!pc+mem,pc+1;  LOOP
      CASE Jf:      sp := sp-1; pc := sp!1->pc+1,!pc+mem;  LOOP
      CASE Jump:    pc := !pc+mem;                         LOOP
      CASE Res:     sp := sp-1; res := sp!1
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
*/
    }
  } REPEAT

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
{ //CASE Fnrn:CASE Rtrn:CASE Lres:CASE Halt:
  //CASE Vecap:CASE Ind:CASE Stind:CASE Neg:CASE Not:
  //CASE Mult:CASE Div:CASE Mod:CASE Plus:CASE Minus:
  //CASE Eq:CASE Ne:CASE Le:CASE Ge:CASE Lt:CASE Gt:
  //CASE Lsh:CASE Rsh:CASE And:CASE Or:CASE Xor:
            RESULTIS FALSE

  DEFAULT:  RESULTIS TRUE
}


