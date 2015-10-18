/*
This program convert a set of Boolean expressions into
a set of relations over no more than eight variables.

Implemented in BCPL by Martin Richards (c) May 2006

Usage:  exp2rel x.exp to x.rel

The expression file contains of a list of expressions separated
by semicolons or newlines.

E ;...; E

where E is a Boolean expression with the following syntax:

      Syntax   Precedence  Tree node

N ::= <name>               [Name, link, id, <string>]

E ::= N
      0                    [False] represents false
      1                    [True]  represents true
      ( E )                E
      ~ E          5       [Not, E]
      E & E        4       [And, E, E]
      E | E        3       [Or, E, E] 
      E = E        2       [Eq, E, E]
      E ~= E       2       [Ne, E, E]
      E -> E       1       [Imp, E, E]
      N: E         0       [Def, N, E]

Semicolons occurring at the ends of lines can be omitted. Comments
go from # to the end of the line.

Examples:

a: (b -> c) | d

b: ~d & (a | c)

~(a|b|c|d) # At least one of a, b, c or d must be false


Expressions containing no more that eight variable tranlate into
single relations, others are broken into smaller expressions using
new system allocated variable names.
*/

SECTION "exp2rel"

GET "libhdr"
 
MANIFEST {  // Lexical tokens, parse tree operators and op-codes

Name=1; True; False
Not; And; Or; Eq; Ne; Imp; Def
Lparen; Rparen; Semicolon; Eof
}
 
GLOBAL { 
rec_p:ug; rec_l; fin_p; fin_l
fatalerr; synerr; trnerr; errcount; errmax
expstream; relstream
mk1; mk2; mk3
newvec; treep; treevec
optTokens; optTree

expv     // vector of expressions expv!1 .. expv!expn
expn     // Number of expressions
expvupb  // The UPB of expv (typically=5000)

// Globals used in LEX
chbuf; charv; ch; rch; lex; token; lexval; wordnode
wrchbuf; chcount; lineno; pos
buf    // The input buffer
bufp   // The position of the next character to return, it is the number of
       // bytes so far returned.
bufn   // The number of bytes in buf.

dsw; declsyswords; nametable; lookupword; varname
rdtag
opstr
truenode; falsenode
varno
sysnameno

// Globals used in SYN
rdexpressions
checkfor; exp2rel; rname
rdstatements; 
translate; plist
rnexp; rexp; rbexp
 
// Globals used in TRN
trexpression
trans; trexp
comline
}

MANIFEST {                         //  Selectors
h1=0; h2=1; h3=2; h4=3
nametablesize = 541
varnameupb = 50000                 // Maximum number of variables allowed
bufnmax = 1000 // The upperbound of buf
}
 
LET start() = VALOF
{ LET treesize = 0
  LET stdin = input()
  LET stdout = output()
  LET expname = "a.exp"
  LET relname = "**"
  LET argform = "EXP,TO=-o/K,TOKENS=-l/S,TREE=-p/S"
  LET argv = VEC 50

  errmax   := 2
  errcount := 0
  fin_p, fin_l := level(), fin

  treevec := 0  expstream, relstream := 0, 0
   
  writef("*nexp2rel (15 June 2006)*n")
 
  IF rdargs(argform, argv, 50)=0 DO
    fatalerr("Bad arguments for: %s*n", argform)

  treesize := 400000

  IF argv!0 DO expname := argv!0       // EXP
  IF argv!1 DO relname := argv!1       // TO
  optTokens := argv!2                  // TOKENS  -l
  optTree   := argv!3                  // TREE    -p

  expstream := findinput(expname)
  relstream := findoutput(relname)

  UNLESS expstream DO fatalerr("Trouble with exp file %s*n", expname)
  UNLESS relstream DO fatalerr("Trouble with rel file %s*n", relname)

  selectinput(expstream)
  selectoutput(relstream)
 

  treevec := getvec(treesize)

  UNLESS treevec DO
     fatalerr("Insufficient memory*n")
   
  treep := treevec + treesize

  expvupb := 5000
  expv := newvec(expvupb)

  expn := 0
  rdexpressions(expv, expvupb) // Read and translate  expressions
  //writef("start: varno=%n*n", varno)
  FOR i = 1 TO varno DO writef("# v%n is %s*n", i, @h4!(varname!i))
   
fin:
  IF treevec    DO freevec(treevec)
  IF expstream  DO { selectinput(expstream); endread()  }
  IF relstream  DO { selectoutput(relstream)
                     UNLESS relstream=stdout DO  endwrite() }

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

    CASE '#':   // Skip over comment
                rch() REPEATUNTIL ch='*n' | ch=endstreamch
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
                token := lookupword(rdtag())
                RETURN

    CASE '0': token := False;     BREAK
    CASE '1': token := True;      BREAK

 
    CASE '(': token := Lparen;    BREAK
    CASE ')': token := Rparen;    BREAK 
    CASE ';': token := Semicolon; BREAK
    CASE '&': token := And;       BREAK
    CASE '|': token := Or;        BREAK
    CASE '=': token := Eq;        BREAK
    CASE ':': token := Def;       BREAK
 
    CASE '-':   rch()
                IF ch='>' DO { token := Imp;  BREAK }
                synerr("'>' should follow '-'")
                token := Imp
                RETURN
 
    CASE '~':   rch()
                IF ch='=' DO { token := Ne;  BREAK }
                token := Not
                RETURN
 
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
  FOR i = 1 TO len DO hashval := 13*hashval + word%i REM 1_000_000
  hashval := hashval REM nametablesize
  wordnode := nametable!hashval
 
  WHILE wordnode & i<=len TEST (@h4!wordnode)%i=word%i
                          THEN i := i+1
                          ELSE wordnode, i := h2!wordnode, 0
  IF wordnode=0 DO
  { wordnode := newvec(len/bytesperword+4)
    h1!wordnode, h2!wordnode := Name, nametable!hashval
    varno := varno+1
    h3!wordnode := varno
    FOR i = 0 TO len DO (@h4!wordnode)%i := word%i
    nametable!hashval := wordnode
    varname!varno := wordnode
  }
  RESULTIS h1!wordnode
}
 
AND dsw(word, tok) BE { lookupword(word); h1!wordnode := tok  }
 
AND declsyswords() BE
{ dsw("false", False); falsenode := wordnode
  dsw("true", True);   truenode := wordnode
} 
 
LET rch() BE
// Put the next character in ch but use an input buffer
// so that lines can be written before the first chacter of a line is returned.
// buf    is the input buffer
// bufupb is the upperbound of buf
// bufp   is the position of the next character to return, it is the number of
//        bytes so far returned.
// bufn   is the number of bytes in buf, bufn=-1 if the stream is exhausted
{ IF bufp>=bufn DO
  { // Read the next line into the buffer
    bufn := 0
    bufp := 0
    UNTIL bufn>=bufnmax DO
    { LET ch = rdch()
      bufn := bufn+1
      buf!bufn := ch
      IF ch='*n' | ch=endstreamch BREAK
    }
    // Output the current line, if any.
    IF bufn DO
    { writef("# ")
      FOR i = 1 TO bufn-1 UNLESS buf!i=endstreamch DO wrch(buf!i)
      newline()
    }
  }
  bufp := bufp+1
  ch := buf!bufp
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
 
AND rdexpressions(v, upb) = VALOF
{ // This reads expressions separated by semicolons and newlines
  // into expv.
  // It returns the number of expressions successfully read.
  // If optToken is true, it just tests the lexical analyser.

  LET tree = 0
  rec_p, rec_l := level(), recover

  charv := newvec(256/bytesperword)     
  chbuf := newvec(64/bytesperword)
  buf   := newvec(bufnmax)
  nametable := newvec(nametablesize)
  varname := newvec(varnameupb)
  chcount, lineno := 0, 1
 
  UNLESS charv & chbuf & buf & nametable & varname DO
    fatalerr("More workspace needed")
  FOR i = 0 TO 63 DO chbuf%i := 0
  FOR i = 0 TO nametablesize DO nametable!i := 0
  FOR i = 0 TO varnameupb DO varname!i := 0
  varno := 0
  declsyswords()

  varno := 0
  sysnameno := 0
  pos := 0
  expn := 0
  newline()
  bufn := 0
  bufp := 0
  rch()
  lex()

  IF optTokens UNTIL token=Eof DO         // For debugging lex.
  { writef("token = %i3 %s", token, opstr(token))
    IF token=Name   DO writef("      %s",   charv)
    newline()
    lex()
  }

recover:
  { WHILE token=Semicolon DO lex()
    IF token=Eof BREAK
    tree := rexp(0) // Parse the next expression

    //IF optTree DO { writef("*nExpression %n:*n", expn+1)
    //                plist(tree, 0, 20)
    //                newline()
    //              }

    IF tree DO
    { IF expn>=upb DO fatalerr("Too many expressions")
      expn := expn+1
      v!expn := tree
      trexpression()
    }
  } REPEAT
  newline()
  RESULTIS expn
}
 
AND fatalerr(mess, a) BE
{ writef("*nFatal error:  ")
  writef(mess, a)
  writes("*nProgram aborted*n")
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
 
LET rdstatements() BE
{ LET ln = lineno

  WHILE token=Name DO
  { // Read in another statement
    LET statement = rexp(0)
    UNLESS statement & h1!statement=Eq DO
      synerr("Trouble with statement")

    trans(statement)
  }

  IF token=Eof RETURN

  synerr("Bad statement")
} REPEAT

AND rname() = VALOF
{ LET a = wordnode
  checkfor(Name, "Name expected")
  RESULTIS a
}
 
LET rbexp() = VALOF
{ LET a, op, ln = 0, token, lineno
 
  SWITCHON op INTO
 
  { DEFAULT: synerr("Error in expression")

    CASE True:   lex()
                 RESULTIS truenode

    CASE False:  lex()
                 RESULTIS falsenode

    CASE Name:   a := wordnode
                 lex()
                 TEST token=Def
                 THEN RESULTIS mk3(Def, a, rnexp(0))
                 ELSE RESULTIS a
 
    CASE Lparen: a := rnexp(0)
                 checkfor(Rparen, "')' missing")
                 RESULTIS a
 
    CASE Not:    RESULTIS mk2(Not, rnexp(5))
   }
}
 
AND rnexp(n) = VALOF { lex(); RESULTIS rexp(n) }
 
AND rexp(n) = VALOF
{ LET a, b, p = rbexp(), 0, 0

  { LET op, ln = token, lineno
    SWITCHON op INTO
 
    { DEFAULT:      BREAK

      CASE And:     p := 4;  ENDCASE
      CASE Or:      p := 3;  ENDCASE
      CASE Eq:
      CASE Ne:      p := 2;  ENDCASE
      CASE Imp:     p := 1;  ENDCASE
    }

    IF n>=p RESULTIS a
    a := mk3(op, a, rnexp(p))
  } REPEAT

  RESULTIS a
}

LET opstr(op) = VALOF SWITCHON op INTO
{ DEFAULT:       RESULTIS "Unknown"


  CASE And:      RESULTIS "And"
  CASE Def:      RESULTIS "Def"
  CASE Eq:       RESULTIS "Eq"
  CASE False:    RESULTIS "False"
  CASE Imp:      RESULTIS "Imp"
  CASE Name:     RESULTIS "Name"
  CASE Ne:       RESULTIS "Ne"
  CASE Not:      RESULTIS "Not"
  CASE Or:       RESULTIS "Or"       
  CASE Rparen:   RESULTIS "Rparen"
  CASE Semicolon:RESULTIS "Semicolon"
  CASE True:     RESULTIS "True"
}

LET plist(x, n, d) BE
{ LET s, size, ln = 0, 0, 0
  LET v = TABLE 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

  IF x=0 DO { writes("Nil"); RETURN  }
 
  SWITCHON h1!x INTO
  { DEFAULT:
         size     := 1;        ENDCASE

    CASE Name:    writef("%s -- v%n", @h4!x, h3!x);          RETURN

    CASE And: CASE Or:
    CASE Eq: CASE Ne: CASE Imp: CASE Def:
         size     := 3;       ENDCASE

    CASE Not:
         size     := 2;       ENDCASE

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
  IF comline DO writef(" near line %n", comline)
  writes(":   ")
  writef(mess, a)
  newline()
  errcount := errcount + 1
  IF errcount >= errmax DO fatalerr("*nCompilation aborted*n")
}

AND trexpression() BE
{ // The expressions are in expv!1 .. expv!expn

  // First ensure that no expression has more than eight variables
  LET i = expn
  WHILE i <= expn DO
  { LET exp = expv!i
    LET fvl = VEC 8
    LET n = ?
//    writef("Ensuring expression %n uses no more than eight variables*n*n", i)
//plist(exp, 0, 20)
//newline()
    n := reduceexp(exp, 8, fvl)
    //writef("Expression %n uses %n variable(s): ", i, n)
    //FOR j = 1 TO n DO writef(" v%n", fvl!j)
    newline()
    IF optTree DO
    { plist(exp, 0, 20)
      newline()
    }
    // Translate and expression that uses n (<=8) variable
    // into a relation.
    trexp(exp, n, fvl)
    i := i+1
  }
}

AND reduceexp(x, n, fvl) = VALOF SWITCHON h1!x INTO
// Ensure that expression x has no more that n variables.

// Arguments:
//   x      The expression
//   n      Maximum number of variables allowed, 7<=n<=8
//   fvl    is a vector with UPB n to hold the variable numbers.

// It splits the expression into smaller pieces if necessary
// and return the number of variables used in the root portion
// placing the variable in fvl in reducing order.
// The result will be between 0 and n.

// If x uses more than n variables, it is replaced by x' by
// replacing a branch in x, y say, by a a newly allocated name
// node N, say, and adding a new expression of the form [Def, N', y]
// to the end of the vector of expressions. The result is obtained
// by evaluating reduceexp(x', n, fvl).



{ DEFAULT:  writef("reduceexp: Unknown op %s*n", h1!x)
            trnerr("")
            RESULTIS 0

  CASE Name: 
         //writef("reduceexp: name %s putting varno=%n in fvl!1*n", @h4!x, h3!x)
         fvl!1 := h3!x
         RESULTIS 1

  CASE And: CASE Or:
  CASE Eq: CASE Ne: CASE Imp: CASE Def:
       { LET n1, n2, res = ?, ?, 0
         LET i1, i2 = 1, 1
         LET fvl1 = VEC 8
         LET fvl2 = VEC 8
         LET str  = VEC 10

         n1 := reduceexp(h2!x, n, fvl1)
         n2 := reduceexp(h3!x, n, fvl2)

         // Form the union of fvl1 and fvl2 in fvl
//writef("reduceexp: op=%s n=%n n1=%n n2=%n*n", opstr(h1!x), n, n1, n2)
//writef("reduceexp: x is:*n")
//plist(x, 0, 20)
//newline()
//writef("reduceexp: fvl1:")
//FOR i = 1 TO n1 DO writef(" v%n", fvl1!i)
//newline()
//writef("reduceexp: fvl2:")
//FOR i = 1 TO n2 DO writef(" v%n", fvl2!i)
//newline()
//abort(2222)

         { LET id1, id2, larger = 0, 0, 0
           IF i1<=n1 DO id1 := fvl1!i1
           IF i2<=n2 DO id2 := fvl2!i2
           larger := id1>id2 -> id1, id2

//writef("reduceexp: n=%n id1=%n id2=%n larger=%n res=%n*n", n, id1, id2, larger, res)

           IF larger=0 DO
           { // No more variable to unite.
             //writef("There %p\was\were\%- %n variable%-%ps: ", res)
             //FOR i = 1 TO res DO writef(" v%n", fvl!i)
             //newline()
             RESULTIS res
           }

           IF res=n DO
           { // There are too many variables so split the expression
             // Create a new name and choose an operand to replace.
             LET y, namenode = 0, ?
             str%1 := '$'
             sysnameno := sysnameno+1
             str%0 := packnum(str, 2, sysnameno)
             lookupword(str)
             namenode := wordnode
//writef("Creating new namenode for %s -- v%n*n", str, h3!wordnode)
             TEST n1>n2 // Replace the more complicated operand 
             THEN { y := h2!x
                    h2!x := namenode // Replace y by the new name.
                  }
             ELSE { y := h3!x
                    h3!x := namenode // Replace y by the new name.
                  }

             // Ensure that y uses no more than n-1 variables. 
//writef("Ensuring the following operand uses no more than 7 variables*n")
//plist(y, 0, 20)
//newline()
//abort(1000)
             reduceexp(y, 7, fvl)
             // Construct a new expresion that uses no more
             // than n variables.
             expn := expn+1
             expv!expn := mk3(Def, namenode, y)
//writef("Creating new simple expression %n:*n", expn)
//plist(expv!expn, 0, 20)
//newline()
//abort(2000)
                  
             RESULTIS reduceexp(x, n, fvl)
           }

           res := res+1
//writef("reduceexp: fvl!%n=%n*n", res, larger)
           fvl!res := larger
           // Step through one or both fvl lists.
           IF id1=larger DO i1 := i1+1
           IF id2=larger DO i2 := i2+1
         } REPEAT
       }


  CASE Not:
         RESULTIS reduceexp(h2!x, n, fvl)

  CASE True:
  CASE False:
         RESULTIS 0
}

AND packnum(s, i, x) = VALOF
{ IF x>9 DO i := packnum(s, i, x/10) + 1
  s%i := x REM 10 + '0'
  RESULTIS i
}

AND trexp(x, n, fvl) BE
// Translate expression x intp relations over no more than
// eight variables
{ //writef("trexp: entered*n")
  LET w = VEC 7  // The relation bit pattern
  LET sig = FALSE
  LET lim = 1<<n
  FOR i = 0 TO 7 DO w!i := 0
  FOR i = 0 TO 7 FOR j = 0 TO 31 DO
  { LET setting = 32*i+j
    IF setting=lim GOTO out
    IF eval(x, fvl, setting) DO w!i := w!i + (1<<j)
  }
out:
  IF n>=8 DO
  { writef("%x8 ", w!7)
    writef("%x8 ", w!6)
    writef("%x8 ", w!5)
    writef("%x8 ", w!4)
  }
  IF n>=7 DO
  { writef("%x8 ", w!3)
    writef("%x8 ", w!2)
  }
  IF n>=6 DO
    writef("%x8 ", w!1)
  writef("%x8 ", w!0)
  IF n>4 DO newline()
  FOR i = 1 TO n DO writef("v%n ", fvl!i)
  newline()
  newline()
}

AND eval(x, fvl, setting) = VALOF SWITCHON h1!x INTO
{ DEFAULT:  writef("eval: Unkbown op=%n*n", h1!x)
            abort(999)

  CASE True:
            RESULTIS TRUE

  CASE False:
            RESULTIS FALSE

  CASE Name:
          { LET id = h3!x
            FOR i = 1 TO 8 DO
            { IF id = fvl!i RESULTIS (setting&1)=0 -> FALSE, TRUE
              setting := setting>>1
            }
            writef("eval: name %s not in fvl*n", @h4!x)
            abort(999)
          }

  CASE Not: RESULTIS ~ eval(h2!x, fvl, setting)

  CASE And: UNLESS eval(h2!x, fvl, setting) RESULTIS FALSE
            RESULTIS eval(h3!x, fvl, setting)
  CASE Or:  IF eval(h2!x, fvl, setting) RESULTIS TRUE
            RESULTIS eval(h3!x, fvl, setting)

  CASE Def:
  CASE Eq:  RESULTIS eval(h2!x, fvl, setting) =
                     eval(h3!x, fvl, setting)

  CASE Ne:  RESULTIS eval(h2!x, fvl, setting) ~=
                     eval(h3!x, fvl, setting)

  CASE Imp: IF eval(h2!x, fvl, setting) DO
              RESULTIS eval(h3!x, fvl, setting)
            RESULTIS TRUE
}
