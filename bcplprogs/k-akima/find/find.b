GET "libhdr"

MANIFEST {
 Char    = 'c'      // identifies a character
 BoL     = '`'      // beginning of line
 EoL     = '*''     // end of line
 Any     = '?'      // any character
 CCl     = '['      // begin character class
 NCCl    = '^'      // negation of chracter class
 CClEnd  = ']'      // end of character class
 Closure = '**'     // zero or more occurences
 Escape  = ':'      // escape character
 NotC    = '^'      // negation character
}
MANIFEST {
 MaxLine = 1024
}
MANIFEST {
 MaxPat = 257
}
MANIFEST {
 Count = 1; PrevCl; StartCl; CloSize
}

STATIC {
 fin_p; fin_l
}
STATIC {
 ignore_case
}
STATIC {
 lcount
}
STATIC {
 pbuf = 0
}
STATIC {
 invert = 0
}
STATIC {
 instream = 0
}
STATIC {
 outstream = 0
}
STATIC {
 lbuf = 0
}

//$$Debug
$<Debug
LET DbgDumpPattBuf() BE {
 FOR i = 1 TO MaxPat DO {
  writef(" %x3", pbuf!i)
  UNLESS i REM 16 DO newline()
 }
 newline()
}
LET DbgDumpLineBuf() BE {
 LET i = 0

 {
  i := i + 1
  writef(" %x3", lbuf!i)
  UNLESS i REM 16 DO newline()
 } REPEATWHILE lbuf!i
 newline()
}
$>Debug

LET start() = VALOF {
 LET error(msg) BE {
  IF outstream DO {
   endwrite()
   outstream := 0
  }
  selectoutput(findoutput("**"))
  writes(msg)
  newline()
  longjump(fin_p, fin_l)
 }
 LET readline() = VALOF {
  LET i, ch = 0, ?

  UNLESS lcount < 0 DO lcount := lcount + 1
  lbuf!2 := 0
  WHILE i < MaxLine DO {
   i, ch, lbuf!i := i + 1, rdch(), ch
   SWITCHON ch INTO {
   CASE endstreamch:   IF 1 = i    RESULTIS -1
   CASE '*n':                      i := i - 1; BREAK
   CASE '*c':                      i := i - 1
   default:                        ENDCASE
   }
  }
  i, lbuf!i := i + 1, 0
  RESULTIS i - 1
 }
 AND writeline() BE {
  IF 0 <= lcount DO writef("%i5: ", lcount)
  FOR i = 1 TO MaxLine DO {
   UNLESS lbuf!i BREAK
   wrch(lbuf!i)
  }
  newline()
 }
 LET case(c) = ignore_case & ('A'<= c <= 'Z') ->
               c + 'a' - 'A',
               c
 LET makpat(arg) = VALOF {
  LET addset(c, j) = VALOF {
   IF MaxPat <= !j RESULTIS FALSE
   pbuf!!j, !j := c, !j + 1
   RESULTIS TRUE
  }
  AND esc(array, i) = VALOF {
   TEST Escape ~= array%!i     RESULTIS array%!i
   ELSE TEST 0 =  array%(!i+1) RESULTIS Escape
   ELSE {
    !i := !i + 1
    SWITCHON array%!i INTO {
    CASE 't':                  RESULTIS '*t'
    CASE 'b':                  RESULTIS '*b'
    CASE 's':                  RESULTIS ' '
    DEFAULT:                   RESULTIS array%!i
    }
   }
  }
  AND getccl(arg, i, j) = VALOF {
   LET dodash(set, arg, i, j) BE {
    LET index(s, c) = VALOF {
	 LET i = 1

	 WHILE s%i DO {
	  IF s%i = c RESULTIS i
	  i := i + 1
	 }
	 RESULTIS -1
	}

    LET lower, upper = ?, ?

    !i, !j := !i + 1, !j - 1
	upper, lower := index(set, esc(arg, i)), index(set, pbuf!!j)
    WHILE lower <= upper DO {
	 addset(case(set%lower), j)
	 lower := lower + 1
	}
   }

   LET jstart = ?
   LET digit  = "0123456789"
   LET loalf  = "abcdefghijklmnopqrstuvwxyz"
   LET upalf  = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

   !i := !i + 1
   TEST NotC = arg%!i THEN {
    addset(NCCl, j)
    !i := !i + 1
   } ELSE addset(CCl, j)
   jstart := !j
   addset(0, j)
   WHILE arg%!i & CClEnd ~= arg%!i DO {
    TEST      Escape = arg%!i           THEN addset(esc(arg, i), j)
    ELSE TEST '-'    ~= arg%!i          THEN addset(arg%!i, j)
    ELSE TEST j <= 1 | 0 = arg%!i       THEN addset('-', j)
    ELSE TEST '0' <= pbuf!(!j-1) <= '9' THEN dodash(digit, arg, i, j)
    ELSE TEST 'a' <= pbuf!(!j-1) <= 'z' THEN dodash(loalf, arg, i, j)
    ELSE TEST 'A' <= pbuf!(!j-1) <= 'Z' THEN dodash(upalf, arg, i, j)
    ELSE                                addset('-', j)
    !i := !i + 1
   }
   pbuf!jstart := !j - jstart - 1
   RESULTIS CClEnd = arg%!i
  }
  AND stclos(j, lastj, lastcl) = VALOF {
   LET jp, jt = ?, ?

   jp := !j - 1
   WHILE !lastj <= jp DO {
    jt := jp + CloSize
    addset(pbuf!jp, @jt)
    jp := jp - 1
   }
   !j, jp := !j + CloSize, !lastj
   addset(Closure, lastj)
   addset(0,       lastj)
   addset(lastcl,  lastj)
   addset(0,       lastj)
   RESULTIS jp
  }

  LET i, j, lastcl, lastj, lj, from = ?, 1, -1, 1, ?, ?

  i, from := 1 - invert, i
  WHILE i <= arg%0 DO {
   lj := j
   TEST      Any     = arg%i                 THEN addset(Any, @j)
   ELSE TEST BoL     = arg%i & i = from      THEN addset(BoL, @j)
   ELSE TEST EoL     = arg%i & 0 = arg%(i+1) THEN addset(EoL, @j)
   ELSE TEST CCl     = arg%i                 THEN
    UNLESS getccl(arg, @i, @j)                    BREAK
   ELSE TEST Closure = arg%i & from < i      THEN {
    lj := lastj
	IF BoL = pbuf!lj | EoL = pbuf!lj | Closure = pbuf!lj BREAK
	lastcl := stclos(@j, @lastj, lastcl)
   } ELSE {
    addset(Char, @j)
	addset(case(esc(arg, @i)), @j)
   }
   lastj, i := lj, i + 1
  }
  IF FALSE = addset(0, @j) | i < arg%0 RESULTIS FALSE
  RESULTIS TRUE
 }
 LET match() = VALOF {
  LET amatch(from) = VALOF {
   LET omatch(i, j) = VALOF {
    LET locate(c, offset) = VALOF {
	 LET i = offset + pbuf!offset

	 WHILE offset < i DO {
	  IF c = pbuf!i RESULTIS TRUE
	  i := i - 1
	 }
	 RESULTIS FALSE
	}

    LET bump, c = -1, case(lbuf!!i)

    TEST      BoL  = pbuf!j  IF     1 = !i     bump := 0
    ELSE TEST EoL  = pbuf!j  UNLESS lbuf!!i    bump := 0
    ELSE TEST 0    = lbuf!!i                   RESULTIS FALSE
    ELSE TEST Char = pbuf!j  IF     case(lbuf!!i) = pbuf!(j+1)
                                               bump := 1
    ELSE TEST Any  = pbuf!j                    bump := 1
    ELSE TEST CCl  = pbuf!j  IF     locate(case(lbuf!!i), j + 1)
                                               bump := 1
    ELSE TEST NCCl = pbuf!j  UNLESS locate(case(lbuf!!i), j + 1)
                                               bump := 1
    ELSE error("In omatch: can't happen")
    IF 0 <= bump THEN {
     !i := !i + bump
     RESULTIS TRUE
    }
    RESULTIS FALSE
   }

   LET i, j, offset, stack = ?, 1, ?, -1

   offset := from
   WHILE pbuf!j DO {
    TEST Closure = pbuf!j THEN {
     stack := j
	 j := j + CloSize
	 i := offset
	 WHILE lbuf!i UNLESS omatch(@i, j) BREAK
	 pbuf!(stack+Count) := i - offset
	 pbuf!(stack+StartCl) := offset
	 offset := i
    } ELSE UNLESS omatch(@offset, j) DO {
     WHILE 0 <= stack DO {
	  IF 0 < pbuf!(stack+Count) BREAK
	  stack := pbuf!(stack+PrevCl)
	 }
	 IF stack < 0 RESULTIS -1
	 pbuf!(stack+Count) := pbuf!(stack+Count) - 1
	 j := stack + CloSize
	 offset := pbuf!(stack+StartCl) + pbuf!(stack+Count)
    }
    TEST      Char    = pbuf!j   THEN j := j + 2
	ELSE TEST BoL     = pbuf!j | EoL = pbuf!j | Any = pbuf!j
	                             THEN j := j + 1
	ELSE TEST CCl     = pbuf!j | NCCl = pbuf!j
	                             THEN j := j + 2 + pbuf!(j+1)
	ELSE TEST Closure = pbuf!j   THEN j := j + CloSize
	ELSE error("In amatch: can't happen")
   }
   RESULTIS offset
  }

  LET i = 1

  WHILE TRUE DO {
   IF 0 <= amatch(i) RESULTIS TRUE
   i := i + 1
   UNLESS lbuf!i RESULTIS FALSE
  }
 }

 LET argv = VEC 10

 fin_p, fin_l := level(), fin
 IF 0 = rdargs("FROM/A,TO/K,PAT/A/K,C/S,N/S", argv, 10)  DO error("Invalid args: FIND FROM/A,TO/K,PAT/A/K,C/S,N/S")
 ignore_case := argv!3
 lcount := -1 - argv!4
 pbuf := getvec(MaxPat)
 UNLESS pbuf DO error("Insufficient memory")
 $<Debug
  FOR c = 0 TO MaxPat DO pbuf!c := 0
 $>Debug
 IF '~' = argv!2%1 DO invert := -1
 UNLESS makpat(argv!2) error("Pattern too long")
 instream := findinput(argv!0)
 UNLESS instream DO error("Can't open input")
 selectinput(instream)
 IF argv!1 DO {
  outstream := findoutput(argv!1)
  UNLESS outstream DO error("Can't open output")
  selectoutput(outstream)
 }
 lbuf := getvec(MaxLine + 1)
 UNLESS lbuf DO error("Insufficient memory")
 WHILE 0 <= readline() DO
  IF match() NEQV invert DO writeline()

fin:
 IF freevec DO freevec(pbuf)
 IF lbuf DO freevec(lbuf)
 IF instream  DO endread()
 IF outstream DO endwrite()

 RESULTIS 0
}
