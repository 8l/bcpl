/*
This program was implemented in BCPL
by Martin Richards (c) October 2005

It converts .exp terms into .rel terms where the relations are over no
more than 3 variables.

For instance, the command:

exp2rel3 x.exp to x.rel

will convert the file x.exp:

v1 = (v2 & v3) -> (v4 -> v5)
v2 = ~v3
v3 = (v4 | ~v5) -> v1
v1 = 1

to the file x.rel:

# v1 = (v2 & v3) -> (v4 -> v5)
00001011 v1 v2 

# v2 = ~v3
00001011 v1 v2 

# v3 = (v4 | ~v5) -> v1
00001011 v1 v2 

# v1 = 1
0100000 v1


This is suitable input for the chk3 satisfiability tester.

The first extra variable that exp2rel3 can use is by default numbered
1000 but can be specified using the argument xvar, as in:

exp2rel3 data/tst4.exp xvar 10

Unless all variable numbers in the exp file are less than the xvar value,
the program complains.

The syntax of expressions, E, is as follows:

E -> 0         representing false
  |  1         representing true
  |  Vn        n >= 1
  |  ( E )
  |  ~ E
  |  E  & E    And
  |  E  | E    Or
  |  E  = E    Equal
  |  E ~= E    Not equal
  |  E -> E    Implies

Each line of the exp file is either a comment starting with #, a blank
line or a term of the form:

Vn = E

The program converts these terms into equivalent sets of relations
over up to three variables. Each relation is output as an 8-bit
pattern followed by upto three variables, for example:

00101101 v23 v65 v3

The 8-bit pattern specifies what settings of the variable are allowed, as
shown in the following:

  relation bits  0 0 1 0 1 1 0 1
pattern allowed      Y   Y Y   Y
            v23  0 1 0 1 0 1 0 1
            v65  0 0 1 1 0 0 1 1
            v3   0 0 0 0 1 1 1 1

ie the bit pattern 00101101 indicates that the three values
   (v23,v65,v3) must be one of: 010, 100, 101 or 111
   so the relation is equivalent to: v23=(v65->v3)

If an term contains more than three variables it is split into
multiple relations using extra variables allocated by exp2rel3.
*/

GET "libhdr"

GLOBAL {
  nextvar : ug
  maxinputvar    // The largest variable number allowed in the input file.
  maxvar
  spacev
  spacep
  spacet

  buf            // Line buffer
  bufp

  ch             // Next character of input
  lineno         // Input line number
  buf            // Circular buffer of input characters
  bufp           // Position of latest character
  token          // The current lexical token
  varno          // The latest variable number

  rec_p; rec_l   // Recovery label

  rch            // Read next input character
  lex            // Read next lexical token
  rterm          // read a term: Vn = E
  rprim          // Read a primary expression: 0, 1, Vn (E) or ~E
  rexp           // Read and expression: E E&E E|E E=E E~=E or E->E
  rnexp          // Call lex then rexp

  ptree          // Output the parse tree
  printtree      // Print the tree option
}

MANIFEST {
  spacevupb = 2000 // The upperbound of spacev
  bufupb = 4095

  // Lexical tokens
  s_false=1    // 0
  s_true       // 1
  s_var        // Vn
  s_lparen     // (
  s_rparen     // )
  s_not        // ~
  s_and        // &
  s_or         // |
  s_eq         // =
  s_ne         // ~=
  s_imp        // ->
  s_def        // =  (in a term)
  s_eol        // end-of-line
  s_eof        // end-of-file

  h1=0  // Selectors
  h2
  h3

}

LET start() = VALOF
{ LET retcode = 0
  LET expname = "data/e1.exp"   // The default exp filename
  LET len = 0
  LET relname = VEC 50
  LET oldin = input()
  LET oldout = output()
  LET expstream = 0
  LET relstream = 0

  LET argv = VEC 50

  spacev, buf := 0, 0

  UNLESS rdargs("from,xvar,to/k,tree/S,help/S",argv, 50) DO
  { writef("Bad arguments for exp2rel3*n")
    RESULTIS 0
  }

  printtree := argv!3

  IF argv!4 DO
  { writef("*nArgument format: from,xvar,to/k,tree/S,help/S*n*n")
    writef("from:  the name of the exp file*n")
    writef("xvar:  the number of the first variable for exp2rel3 to use*n")
    writef("to:    the name of the rel file*n")
    writef("tree:  output the parse tree of every term*n")
    writef("help:  output this help information*n*n")

    writef("If the 'to' argument is not given, the output filename is the*n")
    writef("same as the exp filename with its extension changed to .rel*n*n")

    RESULTIS 0
  }

  IF argv!0 DO expname := argv!0
  len := expname%0
  FOR i = 1 TO 4 UNLESS expname%(len-4+i)=".exp"%i DO
  { writef("expname %s does not end in .exp*n", expname)
    RESULTIS 0
  }
  FOR i = 0 TO len DO relname%i := expname%i
  FOR i = 1 TO 4 DO relname%(len-4+i) := ".rel"%i
  
  nextvar := 1000
  IF argv!1 & string.to.number(argv!1) DO nextvar := result2
  maxinputvar := nextvar-1

  IF argv!2 DO relname := argv!2

  writef("Converting %s to %s with xvar=%n*n", expname, relname, nextvar)

  spacev := getvec(spacevupb)
  spacet := spacev+spacevupb+1
  spacep := spacet

  buf    := getvec(bufupb)
  bufp   := 0

  UNLESS spacev & buf DO
  { writef("Need more space*n")
    GOTO fin
  }

  expstream := findinput(expname)
  relstream := findoutput(relname)

  UNLESS expstream DO
  { writef("Unable to open %s*n", expname)
    RESULTIS FALSE
  }

  UNLESS relstream DO
  { writef("Unable to open %s*n", relname)
    RESULTIS FALSE
  }

  selectinput(expstream)
  selectoutput(relstream)

  maxvar := 0

  bufp := 0
  ch := '*n'  // To get rch started
  lineno := 1
  rch()

  { LET term = ?
    rec_p, rec_l := level(), recover
    spacep := spacet // Reset tree space
    lex()
//writef("calling rterm*n")
    term := rterm()
//writef("returned from rterm, term=%n*n", term)

    IF term & printtree DO
    { ptree(term, 0, 20) // Debugging aid
      newline()
    }
    IF term DO term2rel3(term)

recover:                    // error(..) jumps to here
  } REPEATUNTIL token=s_eof

fin:
  IF spacev DO freevec(spacev)
  IF buf    DO freevec(buf)
  IF expstream DO { selectinput(expstream); endread() }
  IF relstream DO { selectoutput(relstream); endwrite() }

  selectinput(oldin)
  selectoutput(oldout)

  writef("*nAll done*n")
  RESULTIS retcode
}

// The lexical analyser

AND error(mess, a,b,c) BE
{
  writef("Error near line %n: ", lineno)
  writef(mess, a, b, c)
  wrch('*n')

  writef("Error near line %n: ", lineno)
  writef(mess, a, b, c)
  newline()
  wrline()
  FOR i = 1 TO bufp-1 DO wrch('#')
  writef("^*n")
abort(1000)
  UNTIL ch='*n' | ch=endstreamch DO ch := rch()
  longjump(rec_p, rec_l)
}

AND wrline() BE
{ FOR i = 1 TO bufupb DO
  { LET c = buf!i
    IF c='*n' | c=endstreamch BREAK
wrch(c)
    //wrch(c)
  }
wrch('*n')
//  newline()
}

AND rch() BE
{ IF ch='*n' DO
  { // Get the next line of input
    //writef("*nInput line: ")
    FOR i = 1 TO bufupb DO
    { LET c = rdch()
      IF ch='*p' DO ch := '*n'
      buf!i := c
//UNLESS '*s'<=c<=126 DO abort(1111)
      IF c='*n' | c=endstreamch BREAK
      //wrch(c)
    }
    //wrch('*n')
    bufp := 0
  }

  IF ch=endstreamch RETURN

  bufp := bufp+1
  ch := buf!bufp

//writef("rch: returning with ch='%c'*n", ch)
//abort(1001)
}

AND lex1() BE
{ lex1()
  writef("lex: found token = ")
  writef(opname(token), token)
  writef("*n")
}

AND lex() BE
{ // The lexical tokens are:
  // 0, 1, vn, ( ) ~ & | = ~= -> EOL and EOF

//TEST ch=endstreamch
//THEN writef("lex: entered with ch = EOF'*n")
//ELSE writef("lex: entered with ch = '%c'*n", ch)
  SWITCHON ch INTO
  { DEFAULT:   error("Bad ch=%n*n", ch)
               token := s_eof
               RETURN

    CASE endstreamch:
               token := s_eof
               RETURN

    CASE '*p':
    CASE '*n':
               lineno := lineno+1
               rch()
               token := s_eol
               RETURN
    CASE '*s':
    CASE '*t':
               rch()
               LOOP

    CASE '#':  rch() REPEATUNTIL ch='*n' | ch='*p' | ch=endstreamch
               LOOP

    CASE 'v':
    CASE 'V':  varno := 0
               rch()
               UNLESS '0'<=ch<='9' DO error("Bad variable number")
               WHILE '0'<=ch<='9' DO
               { varno := 10*varno + ch - '0'
                 rch()
               }
               token := s_var
               RETURN

    CASE '0':  token := s_false;  ENDCASE
    CASE '1':  token := s_true;   ENDCASE
    CASE '(':  token := s_lparen; ENDCASE
    CASE ')':  token := s_rparen; ENDCASE
    CASE '&':  token := s_and;    ENDCASE
    CASE '|':  token := s_or;     ENDCASE
    CASE '=':  token := s_eq;     ENDCASE

    CASE '-':  rch()
               IF ch='>' DO { token := s_imp; ENDCASE }
               error("'>' expected")
               RETURN

    CASE '~':  rch()
               IF ch='=' DO { token := s_ne;  ENDCASE }
               token := s_not
               RETURN
  } // End of switch

  rch()
  RETURN

} REPEAT // to skip over spaces and tabs

// The syntax analyser

AND checkfor(symb, mess) BE
{ UNLESS symb=token DO error(mess)
  lex()
}

AND rterm() = VALOF
{ // Read a term of the form: Vn = E
  LET term = 0
  LET var = 0

  // Debugging aid to test lex
  //lex() REPEATUNTIL token=s_eof

  // Ignore blank lines
  WHILE token=s_eol DO lex()

  // Test for EOF
  IF token=s_eof RESULTIS 0

  // It must be a term of the form: Vn = E EOL
  UNLESS token=s_var DO error("A term must be of the form: Vn = E <eol>")
  writef("*n# ")
  wrline()
  var := rprim()

  checkfor(s_eq, "'=' expected")

  term := mk3(s_def, var, rexp(0))
  UNLESS token=s_eol DO error("Bad term")

  RESULTIS term
}

AND rprim() = VALOF SWITCHON token INTO
{ DEFAULT:  error("Bad expression")

  CASE s_false: lex(); RESULTIS mk1(s_false)
  CASE s_true:  lex(); RESULTIS mk1(s_true)

  CASE s_var: { LET vno = varno
                lex()
                RESULTIS mk2(s_var, vno)
              }

  CASE s_lparen:
               { LET a = rnexp(0)
                 checkfor(s_rparen, "')' expected")
                 RESULTIS a
               }

  CASE s_not:   RESULTIS mk2(s_not, rnexp(5))  
}

AND rnexp(n) = VALOF
{ lex()
  RESULTIS rexp(n)
}

AND rexp(n) = VALOF
{ LET a = rprim()

  { LET op = token
    SWITCHON op INTO
    { DEFAULT:  RESULTIS a

      CASE s_and:  // 4,   left assoc
                IF n>=4 RESULTIS a
                a := mk3(op, a, rnexp(4))
                LOOP

      CASE s_or:   // 3,   left assoc
                IF n>=3 RESULTIS a
                a := mk3(op, a, rnexp(3))
                LOOP


      CASE s_eq:   // 2,   left assoc
      CASE s_ne:
                IF n>=2 RESULTIS a
                a := mk3(op, a, rnexp(2))
                LOOP


      CASE s_imp:  // 1,   right assoc
                IF n>=1 RESULTIS a
                a := mk3(op, a, rnexp(0))
                LOOP
    }
  } REPEAT
}

AND push(x) = VALOF
{ LET a = spacep-1
  IF a<spacev DO error("More tree space needed")
  spacep := a
  !a := x
  RESULTIS a
}

AND mk1(x) = VALOF
{ LET a = push(x)
  //writef("%i6: mk1(%s)*n", a, opname(x))
  RESULTIS a
}

AND mk2(x, y) = VALOF
{ LET a = ?
  push(y)
  a := push(x)
  //writef("%i6: mk2(%s, %n)*n", a, opname(x), y)
  RESULTIS a
}

AND mk3(x, y, z) = VALOF
{ LET a = ?
  push(z)
  push(y)
  a := push(x)
  //writef("%i6: mk3(%s, %n, %n)*n", a, opname(x), y, z)
  RESULTIS a
}

AND ptree(x, n, d) BE
{ LET size, ln = 0, 0
  LET v = TABLE 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

  IF x=0 DO { writes("Nil"); RETURN  }
 
  SWITCHON h1!x INTO
  { CASE s_false: writes("false");      RETURN
    CASE s_true:  writes("true");       RETURN
 
    CASE s_var:   writef("V%n", h2!x);  RETURN
 
    
    CASE s_and:CASE s_or:CASE s_eq:
    CASE s_ne:CASE s_imp:CASE s_def:
                  size := 3;            ENDCASE

    CASE s_not:   size := 2;            ENDCASE

    DEFAULT:      size := 1
  }
 
  IF n=d DO { writes("Etc"); RETURN }
 
  writef(opname(h1!x), h1!x)
  FOR i = 2 TO size DO { newline()
                         FOR j=0 TO n-1 DO writes( v!j )
                         writes("**-")
                         v!n := i=size->"  ","! "
                         ptree(h1!(x+i-1), n+1, d)
                      }
}
 
AND opname(op) = VALOF SWITCHON op INTO
{ DEFAULT:       RESULTIS "Op %n"

  CASE s_false:  RESULTIS "False"
  CASE s_true:   RESULTIS "True"
  CASE s_var:    RESULTIS "Var"
  CASE s_lparen: RESULTIS "Lparen"
  CASE s_rparen: RESULTIS "Rparen"
  CASE s_not:    RESULTIS "Not"
  CASE s_and:    RESULTIS "And"
  CASE s_or:     RESULTIS "Or"
  CASE s_eq:     RESULTIS "Eq"
  CASE s_ne:     RESULTIS "Ne"
  CASE s_imp:    RESULTIS "Imp"
  CASE s_def:    RESULTIS "Def"
  CASE s_eol:    RESULTIS "Eol"
  CASE s_eof:    RESULTIS "Eof"
}



// The translator

AND term2rel3(x) BE TEST h1!x=s_def
THEN { LET vno = h2!(h2!x)
       exp2rel3(vno, h3!x)
     }
ELSE error("Bad op=%n in term2rel3")

AND nextvno() = VALOF
{ LET vno = nextvar
  nextvar := nextvar+1
  RESULTIS vno
}

AND exp2rel3(vno, x) = VALOF SWITCHON h1!x INTO
{ DEFAULT:  error("Unknown tree operator")
            RESULTIS 0

  CASE s_false:
  CASE s_true: { LET bits = opbits(h1!x)
                 IF vno<0 DO vno := nextvno()
                 RESULTIS genrel1(bits, vno)
               }

  CASE s_var:  RESULTIS h2!x

  CASE s_not:  { LET bits = opbits(h1!x)
                 LET b = exp2rel3(-1, h2!x)
                 IF vno<0 DO vno := nextvno()
                 RESULTIS genrel2(bits, vno, b)
               }

  CASE s_and:
  CASE s_or:
  CASE s_eq:
  CASE s_ne:
  CASE s_imp:  { LET bits = opbits(h1!x)
                 LET b = exp2rel3(-1, h2!x)
                 LET c = exp2rel3(-1, h3!x)
                 IF vno<0 DO vno := nextvno()
                 RESULTIS genrel3(bits, vno, b, c)
               }

}



AND opbits(op) = VALOF SWITCHON op INTO
{ DEFAULT:  error("Unknown tree op: %n*n", op)

  // [abcdefgh, x, y, z]
  //  h=1  iff  0  0  0
  //  g=1  iff  1  0  0
  //  f=1  iff  0  1  0
  //  e=1  iff  1  1  0
  //  d=1  iff  0  0  1
  //  c=1  iff  1  0  1
  //  b=1  iff  0  1  1
  //  a=1  iff  1  1  1

  CASE s_false: RESULTIS #b00000001   // x = 0
  CASE s_true:  RESULTIS #b00000010   // x = 1
  CASE s_not:   RESULTIS #b00000110   // x = ~ y
  CASE s_and:   RESULTIS #b10010101   // x = y &  z
  CASE s_or:    RESULTIS #b10101001   // x = y |  z
  CASE s_eq:    RESULTIS #b10101001   // x = y  = z
  CASE s_ne:    RESULTIS #b01010110   // x = y ~= z
  CASE s_imp:   RESULTIS #b10100110   // x = y -> z
  CASE s_def:   RESULTIS #b00001001   // x=y
}

AND genrel1(bits, a) = VALOF
{ writef("%b8 v%n*n", bits, a)
  RESULTIS a
}

AND genrel2(bits, a, b) = VALOF
{ writef("%b8 v%n v%n*n", bits, a, b)
  RESULTIS a
}

AND genrel3(bits, a, b, c) = VALOF
{ writef("%b8 v%n v%n v%n*n", bits, a, b, c)
  RESULTIS a
}




