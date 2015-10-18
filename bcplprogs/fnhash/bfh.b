GET "libhdr"

GLOBAL
{ spacev:200; spacep; spacet
  var
  hval
  T; F
  str; strp; ch; token; lexval
}

MANIFEST
{ False; True; Id; Not; And; Or; Imp; Eqv
  Lparen; Rparen; Eol; Eof
  MaxVar=5000
  Upb=50000
  Modulus = 257
}

// Modulo Arithmetic Package

LET add(x, y) = VALOF
{ LET a = x+y
  IF 0<=a<Modulus RESULTIS a
  RESULTIS a-Modulus
}

AND sub(x, y) = add(x, neg(y))

AND neg(x)    = Modulus-x

AND mul(x, y) = x=0 -> 0,
                (x&1)=0 -> mul(x>>1, add(y,y)),
                add(y, mul(x>>1, add(y,y)))

// Space Allocation

LET mk1(x) = VALOF
{ LET p = spacep-1
  IF p<spacev DO
  { writef("Out of space*n")
    abort(999)
    RESULTIS 0
  }
  p!0 := x
  spacep := p
  RESULTIS p
}

LET mk2(x, y) = VALOF
{ mk1(y)
  RESULTIS mk1(x)
}

LET mk3(x, y, z) = VALOF
{ mk2(y, z)
  RESULTIS mk1(x)
}

// Main Program

LET start() = VALOF
{ LET str = "(a & b) & c = a & (b & c)"
  LET argv = VEC 50
  UNLESS rdargs("EXP,SEED,TREE/S", argv, 50) DO
  { writef("Bad arguments for mfhash*n")
    RESULTIS 20
  }
  writef("mfhash entered*n")
  spacev := getvec(Upb)
  spacet := spacev+Upb
  spacep := spacet
  var := getvec(MaxVar)
  hval := getvec(MaxVar)
  FOR i = 0 TO MaxVar DO var!i, hval!i := Id, randno(Modulus)

  T := mk1(True)
  F := mk1(False)

  IF argv!0 THEN str := argv!0
  IF argv!1 THEN setseed(str2numb(argv!1))

  try(str)
 
  freevec(spacev)
  freevec(var)
  freevec(hval)
  RESULTIS 0
}

AND try(s) BE
{ LET e = 0
  writef("Trying: %s*n", s)
  e := parse(s)
  writef("Tree: "); pr(e, 0); newline()
  writef("mfhash  = %n*n", mfHash (e, 1, 1))  
  writef("mfhash1 = %n*n", mfHash1(e, 1, 1))  
}

AND mfHash1(e, seed, n) = n=16 -> (eval(e)->seed,0), VALOF
{ LET res = ?
  LET h = add(mul(seed, 2), hval!n)
  STATIC { layout=0 }
  IF n=0 DO layout := 0
  IF n=2 DO
  { writef(" %i3", seed)
    layout := layout + 1
    IF layout REM 16 = 0 DO newline()
  }
  var!n := False; res := mfHash1(e,               h,  n+1)
  var!n := True;  res := add(mfHash1(e, sub(seed, h), n+1), res)
  var!n := Id
  RESULTIS res
}

AND mfHash(e, seed, n) = VALOF
{ LET res = ?
  LET se = simplify(e)
  LET h = add(mul(seed, 2), hval!n)
/*
  writef("mfHash:     "); pr(e, 0);  newline()
  writef("environment:"); prenv();   newline()
  writef("simplified: "); pr(se, 0); newline()
  newline()
*/
  IF se=T | se=F DO { writef("   => %c when ", se=T -> 'T', 'F')
                      prenv()
                      newline()
                    }

  IF se=T RESULTIS seed
  IF se=F RESULTIS 0

  TEST contains(e, @var!n)
  THEN { var!n := False; res := mfHash(se,               h,  n+1)
         var!n := True;  res := add(mfHash(se, sub(seed, h), n+1), res)
         var!n := Id
       }
  ELSE res := mfHash(se, seed, n+1)
  RESULTIS res
}

AND eval(e) = VALOF SWITCHON e!0 INTO
{ DEFAULT:    writef("Bad boolean expression*n")
              RESULTIS 0
  CASE True:  RESULTIS TRUE
  CASE False: RESULTIS FALSE
  CASE Not:   RESULTIS ~eval(e!1)
  CASE And:   IF eval(e!1) RESULTIS eval(e!2)
              RESULTIS FALSE
  CASE Or:    IF eval(e!1) RESULTIS TRUE
              RESULTIS eval(e!2)
  CASE Imp:   IF eval(e!1) RESULTIS eval(e!2)
              RESULTIS TRUE
  CASE Eqv:   RESULTIS eval(e!1)=eval(e!2)
}

AND contains(e, var) = VALOF SWITCHON e!0 INTO
{ DEFAULT:    writef("Bad boolean expression*n")
              RESULTIS FALSE
  CASE True:
  CASE False: RESULTIS FALSE
  CASE Id:    RESULTIS e=var
  CASE Not:   RESULTIS contains(e!1, var)
  CASE And:   
  CASE Or:    
  CASE Imp:   
  CASE Eqv:   RESULTIS contains(e!1, var) -> TRUE,
                       contains(e!2, var) 
}

AND simplify(e) = VALOF SWITCHON e!0 INTO
{ DEFAULT:    writef("Bad boolean expression*n")
              RESULTIS 0
  CASE Id:    RESULTIS e
  CASE True:  RESULTIS T
  CASE False: RESULTIS F
  CASE Not:   { LET x = simplify(e!1)
                IF x=T RESULTIS F
                IF x=F RESULTIS T
                RESULTIS x=e!1 -> e, mk2(Not, x)
              }
  CASE And:   { LET x, y = simplify(e!1), ?
                IF x=F RESULTIS F
                y := simplify(e!2)
                IF x=T RESULTIS y
                IF y=F RESULTIS F
                IF y=T RESULTIS x
                RESULTIS x=e!1 & y=e!2 -> e, mk3(And, x, y)
              }
  CASE Or:    { LET x, y = simplify(e!1), ?
                IF x=T RESULTIS T
                y := simplify(e!2)
                IF x=F RESULTIS y
                IF y=T RESULTIS T
                IF y=F RESULTIS x
                RESULTIS x=e!1 & y=e!2 -> e, mk3(Or, x, y)
              }
  CASE Imp:   { LET x, y = simplify(e!1), ?
                IF x=F RESULTIS T
                y := simplify(e!2)
                IF x=y RESULTIS T
                IF x=T RESULTIS y
                IF y=T RESULTIS T
                IF y=F RESULTIS x!0=Not -> x!1, mk2(Not, x)
                RESULTIS x=e!1 & y=e!2 -> e, mk3(Imp, x, y)
              }
  CASE Eqv:   { LET x, y = simplify(e!1), simplify(e!2)
                IF x=y RESULTIS T
                IF x=T RESULTIS y
                IF y=T RESULTIS x
                IF x=F RESULTIS y!0=Not -> y!1, mk2(Not, y)
                IF y=F RESULTIS x!0=Not -> x!1, mk2(Not, x)
                RESULTIS x=e!1 & y=e!2 -> e, mk3(Imp, x, y)
              }
} 

AND pr(e, n) BE SWITCHON e!0 INTO
{ DEFAULT:    writef("Bad boolean expression*n")
              RETURN
  CASE True:  writef("T")
              RETURN
  CASE False: writef("F")
              RETURN
  CASE Id:    writef("%c", 'a'+e-var-1)
              RETURN
  CASE Not:   writef(" ~")
              pr(e!1, 4)
              RETURN
  CASE And:   IF n>3 DO writef("(")
              pr(e!1, 3)
              writef(" & ")
              pr(e!2, 3)
              IF n>4 DO writef(")")
              RETURN
  CASE Or:    IF n>2 DO writef("(")
              pr(e!1, 2)
              writef(" | ")
              pr(e!2, 2)
              IF n>3 DO writef(")")
              RETURN
  CASE Imp:   IF n>0 DO writef("(")
              pr(e!1, 1)
              writef(" -> ")
              pr(e!2, 1)
              IF n>0 DO writef(")")
              RETURN
  CASE Eqv:   IF n>0 DO writef("(")
              pr(e!1, 0)
              writef(" = ")
              pr(e!2, 0)
              IF n>0 DO writef(")")
              RETURN
}

AND prenv() BE FOR i = 1 TO MaxVar UNLESS var!i=Id DO
                   writef(" %c=%c", 'a'+i-1, var!i=True->'T','F')

AND randexp(d, n) = VALOF
{ // Returns a random boolean expression of depth d
  // with no more than n variables
  LET op, x, y = ?, ?, ?
  IF d=0 RESULTIS @var!randno(n)
  x := randexp(d-1, n)
  IF randno(1000)<100 RESULTIS mk2(Not, x)
  y := randexp(d-1, n)
  op := randno(1000)<200 -> And,
        randno(1000)<300 -> Or,
        randno(1000)<950 -> Imp,
        Eqv

  RESULTIS mk3(op, x, y)
}

// Parser

AND lexInit(s) BE
{ str, strp := s, 1
  rch()
}

AND rch() BE
{ TEST strp>str%0
  THEN ch := Eof
  ELSE { ch := str%strp; strp := strp+1 }
}

AND lex() BE SWITCHON ch INTO
{ DEFAULT:  writef("Bad syntax*n")
            token := Eof;              RETURN

  CASE '*s': rch() REPEATWHILE ch='*s'
             lex()
             RETURN
  CASE '*n': token := Eol
             rch();                    RETURN

  CASE 'a':CASE 'b':CASE 'c':CASE 'd':CASE 'e':
  CASE 'f':CASE 'g':CASE 'h':CASE 'i':CASE 'j':
  CASE 'k':CASE 'l':CASE 'm':CASE 'n':CASE 'o':
  CASE 'p':CASE 'q':CASE 'r':CASE 's':CASE 't':
  CASE 'u':CASE 'v':CASE 'w':CASE 'x':CASE 'y':
  CASE 'z':
             token := Id; lexval := ch; rch(); RETURN


  CASE 'T':  token := True;             rch(); RETURN
  CASE 'F':  token := False;            rch(); RETURN
  CASE '(':  token := Lparen;           rch(); RETURN
  CASE ')':  token := Rparen;           rch(); RETURN
  CASE '~':  token := Not;              rch(); RETURN
  CASE '&':  token := And;              rch(); RETURN
  CASE '|':  token := Or;               rch(); RETURN
  CASE '=':  token := Eqv;              rch(); RETURN
  CASE '-':  rch()
             UNLESS ch='>' DO writef("Bad syntax: '>' expected*n")
             token := Imp;              rch(); RETURN
}

AND parse(s) = VALOF
{ LET tree = ?
  lexInit(s)
  RESULTIS nexp(0)
}

AND prim() = VALOF SWITCHON token INTO
{ DEFAULT:     writef("Bad expression*n")
abort(999)
               RESULTIS 0

  CASE Id:     { LET a = var + lexval - 'a' + 1
                 lex()
                 RESULTIS a
               }
  CASE True:   lex(); RESULTIS T
  CASE False:  lex(); RESULTIS F

  CASE Lparen: { LET a = nexp(0)
                 UNLESS token=Rparen DO
                   writef("Bad syntax: ')' expected*n")
                 lex()
                 RESULTIS a
               }

  CASE Not:    RESULTIS mk2(Not, nexp(3))
}
  
AND nexp(n) = VALOF { lex(); RESULTIS exp(n) }

AND exp(n) = VALOF
{ LET a = prim()

  { LET op = token
    LET prec = VALOF SWITCHON op INTO
    { DEFAULT:  BREAK
      CASE And: RESULTIS 3
      CASE Or:  RESULTIS 2
      CASE Imp:
      CASE Eqv: RESULTIS 1
    }
    IF n>=prec BREAK
    a := mk3(op, a, nexp(prec))
  } REPEAT

  RESULTIS a
}
