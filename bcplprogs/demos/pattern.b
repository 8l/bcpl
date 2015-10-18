GET "libhdr"

STATIC {
work=0;   wp=0;   succflag=FALSE
pat=0;    aux=0
ch=0;     patp=0; patlen=0
errflag=FALSE
}

// The Interpreter

LET match(pat, aux, str) = VALOF
{ LET w = VEC 128
  LET s = 0
  work, wp, succflag := w, 0, FALSE
  put(1)
  UNLESS aux%0=0 DO put(aux%0)

  { // FIRST COMPLETE THE CLOSURE
    LET n = 1
    UNTIL n>wp DO
    { LET p = work!n
      LET k, q = pat%p, aux%p
      SWITCHON k INTO
      { CASE '#': put(p+1)
        CASE '%': put(q)
        DEFAULT:  ENDCASE
        CASE '(':
        CASE '/': put(p+1)
                  UNLESS q=0 DO put(q)
      }
      n := n+1
    }

    IF s>=str%0 RESULTIS succflag
    IF wp=0 RESULTIS FALSE
    s := s+1
    ch := str%s

    // NOW DEAL WITH MATCH ITEMS
    n := wp
    wp, succflag := 0, FALSE

    FOR i = 1 TO n DO
    { LET p = work!i
      LET k = pat%p
      SWITCHON k INTO
      { CASE '#':
        CASE '/':
        CASE '%':
        CASE '(': LOOP

        CASE '*'':IF ch=pat%[p+1] DO put(aux%p)
                  LOOP
        DEFAULT:  // A MATCH ITEM
                  UNLESS ch=k LOOP
        CASE '?': // SUCCESSFUL MATCH
                  put(aux%p)
                  LOOP
      }
    }
  } REPEAT
}

AND put(n) BE TEST n=0
    THEN succflag := TRUE
    ELSE { FOR i = 1 TO wp IF work!i=n RETURN
           wp := wp+1
           work!wp := n
         }

// The Compiler

LET rch() BE TEST patp>=patlen
    THEN ch := endstreamch
    ELSE { patp := patp+1
           ch := pat%patp
         }

AND nextitem() BE
    { IF ch='*'' DO rch()
      rch()
    }

AND prim() = VALOF
{ LET a, op = patp, ch
  nextitem()
  SWITCHON op INTO
  { CASE endstreamch:
    CASE ')':
    CASE '/': errflag := TRUE
    DEFAULT:  RESULTIS a

    CASE '#': setexits(prim(), a)
              RESULTIS a

    CASE '(': a := exp(a)
              UNLESS ch=')' DO errflag := TRUE
              nextitem()
              RESULTIS a
  }
}

AND exp(altp) = VALOF
{ LET exits = 0

  { LET a = prim()
    TEST ch='/' | ch=')' | ch=endstreamch
    THEN { exits := join(exits,a)
           UNLESS ch='/' RESULTIS exits
           aux%altp := patp
           altp := patp
           nextitem()
         }
    ELSE setexits(a,patp)
  } REPEAT
}


AND setexits(list,val) BE UNTIL list=0 DO
{ LET a = aux%list
  aux%list := val
  list := a
}

AND join(a,b) = VALOF
{ LET t = a
  IF a=0 RESULTIS b
  UNTIL aux%a=0 DO a := aux%a
  aux%a := b
  RESULTIS t
}

AND cmplpat(pattern, cmplpattern) = VALOF
{ pat, aux := pattern, cmplpattern
  patp, patlen := 0, pat%0
  errflag := FALSE
  FOR i = 0 TO patlen DO aux%i := 0
  rch()
  setexits(exp(0),0)
  RESULTIS NOT errflag
}

// Test program for cmplpat and match

LET start() = VALOF
{ try("A/B",           "A",  "B",          0)
  try("A#BC",          "AC", "ABBC",   "ABB", 0)
  try("A(/B)",         0)
  try("(A/%)#(B/C)D", "AD", "ACCBCD", "BBCD", 0)
  try("#?'#'?",       "#?", "A#?##?", "#??", 0)
  RESULTIS 0
}

AND try(pattern, s1, s2, s3, s4, s5) BE
{ LET aux = VEC 50
  AND t = @ s1
  TEST cmplpat(pattern, aux)
  THEN writef("*n*"%s*" compiled successfully*n", pattern)
  ELSE { writef("*n*"%s*" failed to compile*n", pattern)
         RETURN
       }
  UNTIL !t=0 DO
  { writes(match(pattern, aux, !t) -> "matches", "does not match")
    writef(" *"%s*"*n", !t)
    t := t + 1
  }
}

