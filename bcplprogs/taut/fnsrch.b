/*
This program find the cheapest boolean expression
to compute each bollean function over three boolean argument.
*/

GET "libhdr"

MANIFEST {
  X = #b11110000
  Y = #b11001100
  Z = #b10101010

  Not=1
  And
  Or
  Eqv
  Xor
  Imp
}

GLOBAL {
  costv: ug
  opv        // The operator
  a1v; a2v   // The operands
  change
}

LET start() = VALOF
{ LET v1 = VEC 255
  AND v2 = VEC 255
  AND v3 = VEC 255
  AND v4 = VEC 255
  costv, opv, a1v, a2v := v1, v2, v3, v4  
  FOR i = 0 TO 255 DO opv!i, costv!i, a1v!i, a2v!i := 0, 1000, -1, -1
  change := FALSE
  put(X, X, 1, -1, -1)
  put(Y, Y, 1, -1, -1)
  put(Z, Z, 1, -1, -1)

  WHILE change DO
  { change := FALSE
    FOR a = 0 TO 255 IF opv!a DO
    { put(~a, Not, 1, a, -1)
      FOR b = 0 TO 255 IF opv!b DO
      { put(a  &  b, And, 4, a, b)
        put(a  |  b, Or,  4, a, b)
        put(a EQV b, Eqv, 4, a, b)
        put(a XOR b, Xor, 4, a, b)
        put(~a |  b, Imp, 5, a, b)
      }
    }
  }
  selectoutput(findoutput("BOOLFNS"))
  prexprs()
  endwrite()
  RESULTIS 0
}

AND put(x, op, cost, a, b) BE
{ x := x & #xFF
  IF a>=0 DO cost := cost + costv!a
  IF b>=0 DO cost := cost + costv!b
  IF cost < costv!x DO
  { opv!x, costv!x, a1v!x, a2v!x := op, cost, a, b 
    change := TRUE
  }
}

AND prexprs() BE FOR a = 0 TO 255 IF opv!a DO
{ writef("  CASE #b%b8: RESULTIS *"", a)
  pr(a, 0)
  writes("*"*n")
}

AND pr(a, n) BE 
{ LET op = opv!a
  LET str = opstr(op)
  LET p = prec(op)
  IF p<=n DO wrch('(')

  SWITCHON op INTO
  { DEFAULT:
    CASE X:
    CASE Y:
    CASE Z:     writef("%s", str); ENDCASE

    CASE Not:   writef("%s", str); pr(a1v!a, p); ENDCASE

    CASE And:
    CASE Or:
    CASE Eqv:
    CASE Xor:
    CASE Imp:   pr(a1v!a, p); writef("%s", str); pr(a2v!a, p); ENDCASE
  }
  
  IF p<=n DO wrch(')')
}

AND opstr(op) = VALOF SWITCHON op INTO
{ DEFAULT:    RESULTIS "???"
  CASE X:     RESULTIS "x"
  CASE Y:     RESULTIS "y"
  CASE Z:     RESULTIS "z"
  CASE Not:   RESULTIS "~"
  CASE And:   RESULTIS "&"
  CASE Or:    RESULTIS "|"
  CASE Eqv:   RESULTIS "="
  CASE Xor:   RESULTIS "#"
  CASE Imp:   RESULTIS "->"
}

AND prec(op) = VALOF SWITCHON op INTO
{ DEFAULT:
  CASE X:
  CASE Y:
  CASE Z:     RESULTIS 6
  CASE Not:   RESULTIS 5
  CASE And:   RESULTIS 4
  CASE Or:    RESULTIS 3
  CASE Eqv:   RESULTIS 2
  CASE Xor:   RESULTIS 2
  CASE Imp:   RESULTIS 1
}

