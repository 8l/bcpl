/*
This is a framework for experimenting with solutions
to the firing squad problem.
*/

GET "libhdr"

MANIFEST { upb = 1000 }
 
GLOBAL { rulev: ug; codetab }

LET start() = VALOF
{ LET v = VEC upb
  AND n = 50
  LET argv = VEC 20

  UNLESS rdargs("N", argv, 20) DO
  { writes("Bad arguments for SQUAD*n")
    RESULTIS 20
  }
  UNLESS argv!0=0 DO n := str2numb(argv!0)

  UNLESS 1<=n<=upb DO
  { writef("The number of soldiers must be between 1 and %n*n", upb)
    RESULTIS 0
  }

  writef("*nFiring squad solution for %i2 soldier%-%ps*n*n", n)
  squad(v, n+2)
  RESULTIS 0
}
 
AND squad(v, n) BE
{ LET count = 0
  codetab := TABLE ' ', '|', '>', ')', ']', '<', '(', '[',
                   '1', '2', '3', '4', '5', '6', '#', '?'
  initrules()
  FOR i = 0 TO n+1 DO v!i := 0
  v!1, v!2, v!n := 1, 2, 1

  { LET p, a, b, c = 0, ?, v!0, v!1
    LET error = FALSE
    writef("%i3: ", count)
    count := count+1
    FOR i = 1 TO n DO
    { LET val = v!i
      writef("%c", codetab!val)
      IF val=#xF DO error := TRUE
    }
    newline()
    IF v!2=6 | error BREAK
    UNTIL p=n DO
    { p := p+1
      a := b
      b := c
      c := v!(p+1)
      v!p := func(a, b, c)
    }
  } REPEAT
 
  newline()
  closerules()
}

AND setrule(abc, val) BE
{ UNLESS rulev!abc = #xF DO
  { LET a = codech(abc>>8)
    LET b = codech(abc>>4)
    LET c = codech(abc   )
    writef("Error: rule '%c%c%c' => %c and %c*n",
                         a,b,c, codech(rulev!abc), codech(val))
  }
  rulev!abc := val
}

AND codech(x) = codetab!(x&15)

AND code(ch) = VALOF
{ FOR i = 0 TO 15 IF ch=codetab!i RESULTIS i 
  RESULTIS -1
}

AND rule(s) BE
{ LET a   = code(s%1)
  LET b   = code(s%2)
  LET c   = code(s%3)
  LET val = code(s%5)
  UNLESS s%0=5 & (a|b|c|val)>=0 DO
  { writef("Bad rule: %s*n", s)
    RETURN
  }
  setrule(a<<8 | b<<4 | c, val)
}

AND initrules() BE
{ rulev := getvec(#xFFF)
  FOR i = 0 TO #xFFF DO rulev!i := #xF

  rule(" |>=|")
  rule("|> = ")
  rule(">  =>")
  rule("   = ")
  rule("  |= ")
  rule(" | =|")
  rule("| >= ")
  rule(" > = ")
  rule("|  = ")
  rule("  >=<")
  rule("> |=<")
  rule(" <|=<")
  rule("  <=<")
  rule(" <<=<")
  rule("<<|=<")
  rule("<<<=<")
  rule("<| =|")
  rule(" < = ")
  rule("< |= ")
  rule("<  = ")
  rule("< >= ")
  rule("| <=>")
  rule("> <=1")
  rule("  1=<")
  rule(" 1 = ")
  rule("1  =>")
  rule("< <=<")
  rule("1 <=<")
}

AND closerules() BE IF rulev DO freevec(rulev)

AND func(a, b, c) = VALOF
{ LET i = a<<8 | b<<4 | c
  RESULTIS rulev!i
}

/*
0> squadf 50

Firing squad solution for 50 soldiers

  0: |1                                                 |
*/
 
