// This is a version of PALSYS as it was for the IBM 360 in
// June 1970. It is being reformatted and modified by M. Richards
// to run under the BCPL Cintsys. November 2010.

// This version is still in the early stages of development.

// XPALHD LAST MODIFIED ON FRIDAY, 12 JUNE 1970
// AT 5:29:07.24 BY R MABEE
// LISTING OF PAL RUN TIME SYSTEM (XPAL) HEADFILE AND BCPL/360 BASIC
// HEADFILE GOTTEN WITHIN SUPPRESSED BY NOLIST DIRECTIVE. TO OVERRIDE
// DIRECTIVE, SPECIFY ALLSOURCE OPTION TO BCPL COMPILER.
//>>> NOLIST
//>>> EJECT
//
//	 ******************************
//	 *                            *
//	 *           XPALHD           *
//	 *                            *
//	 *  (COMPATIBLE WITH PALSYS)  *
//	 *                            *
//	 ******************************
//
// GET BASIC BCPL/360 HEAD FILE
//>>> GET "BASIC"

GET "libhdr"

GLOBAL 	// FLOTLIB GLOBALS
{ fadd:    71 // FADD(REAL1,REAL2) = REAL1 + REAL2
  fsub:    72 // FSUB(REAL1,REAL2) = REAL1 - REAL2
  fmult:   73 // FMULT(REAL1,REAL2) = REAL1 * REAL2
  fdiv:    74 // FDIV(REAL1,REAL2) = REAL1 / REAL2
  fpower:  75 // FPOWER(REAL,INTEGER) = REAL ** INTEGER
  fumin:   76 // FUMIN(REAL) = - REAL
  fabs:    77 // FABS(REAL) = ABS REAL
  fgr:     78 // FGR(REAL1,REAL2) = BOOLEAN
  fge:     79 // FGE(REAL1,REAL2) = BOOLEAN
  feq:     80 // FEQ(REAL1,REAL2) = BOOLEAN
  fne:     81 // FNE(REAL1,REAL2) = BOOLEAN
  fle:     83 // FLE(REAL1,
  fls:     82 // FLS(REAL1,REAL2) = BOOLEAN
  itor:    84 // ITOR(INTEGER) = REAL
  rtoi:    85 // RTOI(REAL) = INTEGER
  stof:    86 // STOF(STRING) = REAL
  ftos:    87 // FTOS(REAL,STRING) = STRING
  stoi:    88 // STOI(STRING) = INTEGER
  writef:  89 // WRITEF(REAL) WRITES REAL NUMBER
  floterr: 90 // TRUE IF FL PT ERROR OCCURS
}


MANIFEST {
// VECTOR APPLICATION
  h1=0; h2=1; h3=2; h4=3; h5=4; h6=5; h7=6

// AE NODES AND POCODE SYMBOLS
  m_goto=148; m_res=149
  m_not=151; m_nil=152; stringconst=153; name=154
  m_plus=157; m_minus=158
  m_aug=160; m_logor=161; m_logand=162
  m_ge=163; m_ne=164; m_le=165; m_gr=166; m_ls=167; m_eq=168
  m_mult=169; m_div=170; m_power=171
  m_pos=173; m_neg=174; m_apply=175

// POCODE SYMBOLS
  m_loadl=181; m_loadr=182; m_loade=183; m_loads=184; m_loadn=185
  m_restoree1=187; m_loadguess=188
  m_formclosure=189; m_formlvalue=190; m_formrvalue=191
  m_members=192
  m_jump=195; m_jumpf=196; m_save=197; m_return=198
  m_testempty=199; m_lose1=200; m_update=201
  m_declname=203; m_declnames=204; m_initname=205; m_initnames=206
  m_decllabel=207; m_setlabes=208; m_blocklink=209; m_reslink=210
  m_setup=211
  integer=213; lab=214; param=215; equ=216

// RUN-TIME NODE TYPES
  m_dummy=220; jj=221; m_true=222; m_false=223; number=224
  m_tuple=225; closure=226; basicfn=227
  lvalue=228; string=229; nils=230; real=231
  label=232; guess=233; env=234; stack=235
}


GLOBAL {
// PLACEMENT SET BY PALSYS
  xpal:202; timeovfl:199; time_exceeded:93

// RUN TIME SYSTEM GLOBAL FUNCTIONS
  load:375; setparams:376; mapliblist:377; libname:378; decllib:379;
  loadl:380; loadr:381; loadj:382; loade:383; loads:384; loadn:385;
  restoree1:386; r_true:387; r_false:388; loadguess:389; nil:390;
  dummy:391; formclosure:392; formlvalue:393; nextlv11:394; next11:395;
  formrvalue:396; tuple:397; members:398; r_not:399; r_logand:400;
  r_logor:401; aug:402; result:403; mult:404; div:405; plus:406;
  minus:407; power:408; pos:409; neg:410; r_eq:411; r_ne:412; r_ls:413;
  r_le:414; r_gr:415; r_ge:416; jump:417; jumpf:418; edbg:419;
  errdbg:420; errlvdbg:421; errokdbg:422; comdbg:423; okrestart:424;
  rvrestart:425; norestart:426; apply:427; save:428; r_return:429;
  testempty:430; lose1:431; r_goto:432; update:433; error:434;
  error1:435; printb:436; printa:437; equal:438; testnumbs2:439;
  testbools2:440; lvofname:441; nameoflv:442; restart:443;
  terminate:444; terminate1:445; lastfn1:446; writenode:447; node:448;
  nextarea:449; marklist:450; mark:451; list:452; split1:453;
  split2:454; declname:455; declnames:456; initname:457; initnames:458;
  r_name:459; nameerror:460; decllabel:461; setlabes:462;
  blocklink:463; reslink:464; setup:465; r_finish:466; print:467;
  userpage:468; stem:469; stern:470; conc:471; atom:472; null:473;
  length:474; istruthvalue:475; isnumber:476; isstring:477;
  isfunction:478; isenviroment:479; islabel:480; istuple:481;
  isreal:482; isdummy:483; share:484; ston:485; cton:486; ntoc:487;
  ntor:488; rton:489; rdchar:490; r_table:491; diagnose:492;
  lastfn:493; lookupine:494; saveenv:495

// RUN TIME SYSTEM GLOBAL VARIABLES
  a:501; b:502; c:503; codep:504; count:505; dummyrv:506; errct:507;
  errflag:508; errorlv:509; e:510; f:511; falserv:512; gcmark:513;
  guessrv:514; linep:515; linet:516; linev:517; listl:518; listp:519;
  listt:520; listv:521; lookupno:522; namechain:523; nameres:524;
  nilrv:525; nilsrv:526; nset:527; oldc:528; parv:529; q:530;
  refp:531; reft:532; refv:533; restartc:534; s:535; stackp:536;
  strb:537; strp:538; tlength:539; top:540; truerv:541

// VARIABLES COMMON WITH PALSYS
  ch		: 218 // LAST CHARACTER READ
  codefile	: 219 // POINTER TO POCODE STORAGE AREA
  codefilep	: 220 // POINTER TO NEXT WORD POCODE STORAGE
  dataflag	: 221 // INDICATES IF DATA FOLLOWS RUN CARD
  gcdbg		: 232 // INDICATES IF COLLECTER DEBUGGING ON
  input		: 234 // PRESENT INPUT STREAM
  lvch		: 251 // LVALUE OF CH
  maxct		: 252 // XPAL MAXIMUM CYCLE COUNT
  maxerr	: 253 // XPAL MAXIMUM ERROR COUNT
  stackwarning	: 269 // APPROXIMATE END BCPL RUN TIME STACK
  storage	: 272 // POINTER TO USABLE FREE STORAGE
  storaget	: 273 // POINTER TO END OF USABLE FREE STORAGE
  tupledepth	: 287 // XPAL MAXIMUM TUPLE PRINT DEPTH
  xpend		: 289 // GLOBAL LABEL
  xpendlevel	: 290 // LEVEL OF GLOBAL LABEL XPEND
}


//>>> LIST

// XPAL1 LAST MODIFIED ON FRIDAY, 12 JUNE 1970
// AT 5:37:27.45 BY R MABEE
//>>> FILENAME "XPAL1"
//
//	***********
//	*         *
//	*  XPAL1  *
//	*         *
//	***********
//
//>>> GET "XPALHD"
//>>> EJECT
// XPAL1A
LET load() BE
{ LET ch, a, p = 0, 0, codefile
  LET v = VEC 255
  refp := 0
  GOTO l
m:
  codep!0, codep := a, codep+1
l:
  ch, p := p!0, p+1
  SWITCHON ch INTO
  { DEFAULT:
      UNLESS ch=endstreamch DO
      { writes("ILLEGAL SYMBOL IN LOADER ")
        writen(ch)
        newline()
        GOTO l
      }
      setparams()
      RETURN

    CASE name:
    CASE stringconst:
    { LET l, n, s = namechain, 0,0
      ch, p := p!0, p+1
      v!0 := ch
      FOR i = 1 TO ch DO v!i, p := p!0, p+1
      n := ch/bytesperword + 1
      s := strp - n
      packstring(v, s)
      UNTIL l=0 DO
      { LET v = l!1
        IF s!0=v!0 DO
        { IF n=1 BREAK
          IF s!1=v!1 DO
          { IF n=2 BREAK
            IF s!2=v!2 DO
            { IF n=3 BREAK
              IF s!3=v!3 DO
              { IF n=4 BREAK
                IF s!4=v!4 IF n=5 BREAK
              }
            }
          }
        }
        l := l!0
      }
      UNLESS l=0 DO
      { a := l!1
        GOTO m
      }
      strp := s - 2
      IF strp<strb DO
      { writes("*n*n*n*tSYMBOL TABLE OVERFLOW IN *
                *XPAL LOADER. NO EXECUTION.*n")
        longjump(xpend, xpendlevel)
      }
      strp!0 := namechain
      strp!1 := s
      namechain := strp
      a := s
      GOTO m
    }

    CASE number:
    { LET dot = FALSE
      ch, p := p!0, p+1
      v!0 := ch
      FOR i = 1 TO ch DO
      { v!i, p := p!0, p+1
	IF v!i='.' DO dot := TRUE
      }
      TEST dot
      THEN { codep!0 := real
             codep := codep + 1
             packstring(v, codep)
             a := stof(codep)
           }
      ELSE { codep!0 := number
             codep := codep + 1
             a := v!1 - 'O'
             FOR i = 2 TO ch DO a := a*10 + v!i - 'O'
           }
      GOTO m
    }

    CASE integer:
      a, p := p!0, p+1
      GOTO m


    CASE lab:
      ch, p := p!0, p+1
      parv!ch := codep
      GOTO l

    CASE param:
      ch, p := p!0, p+1
      refv!refp, refv!(refp+1) := ch, codep
      refp := refp + 2
      IF refp>reft DO
      { writes("*n*n*n*tTABLE OVERFLOW IN XPAL *
               *LOADER. NO EXECUTION.*n")
        longjump(xpend, xpendlevel)
      }
      a := 0
      GOTO m

    CASE equ:
      a, ch, p := p!0, p!1, p+2
      parv!a := ch
      GOTO l

    CASE m_setlabes:   a := setlabes; GOTO m
    CASE m_restoree1:  a := restoree1; GOTO m
    CASE m_formrvalue: a := formrvalue; GOTO m
    CASE m_formlvalue: a := formlvalue; GOTO m
    CASE m_tuple:      a := tuple; GOTO m
    CASE m_members:    a := members; GOTO m
    CASE m_loadguess:  a := loadguess; GOTO m
    CASE m_true:       a := r_true; GOTO m
    CASE m_false:      a := r_false; GOTO m
    CASE m_lose1:      a := lose1; GOTO m
    CASE m_mult:       a := mult; GOTO m
    CASE m_div:        a := div; GOTO m
    CASE m_plus:       a := plus; GOTO m
    CASE m_minus:      a := minus; GOTO m
    CASE m_pos:        a := pos; GOTO m
    CASE m_neg:        a := neg; GOTO m
    CASE m_eq:         a := r_eq; GOTO m
    CASE m_ls:         a := r_ls; GOTO m
    CASE m_gr:         a := r_gr; GOTO m
    CASE m_le:         a := r_le; GOTO m
    CASE m_ne:         a := r_ne; GOTO m
    CASE m_ge:         a := r_ge; GOTO m
    CASE m_logand:     a := r_logand; GOTO m
    CASE m_logor:      a := r_logor; GOTO m
    CASE m_save:       a := save; GOTO m
    CASE m_apply:      a := apply; GOTO m
    CASE m_not:	       a := r_not; GOTO m
    CASE jj:           a := loadj; GOTO m
    CASE m_update:     a := update; GOTO m
    CASE m_res:        a := result; GOTO m
    CASE m_goto:       a := r_goto; GOTO m
    CASE m_loadr:      a := loadr; GOTO m
    CASE m_loadl:      a := loadl; GOTO m
    CASE m_loads:      a := loads; GOTO m
    CASE m_loadn:      a := loadn; GOTO m
    CASE m_loade:      a := loade; GOTO m
    CASE m_testempty:  a := testempty; GOTO m
    CASE m_declname:   a := declname; GOTO m
    CASE m_declnames:  a := declnames; GOTO m
    CASE m_initname:   a := initname; GOTO m
    CASE m_initnames:  a := initnames; GOTO m
    CASE m_formclosure:a := formclosure; GOTO m
    CASE m_jumpf:      a := jumpf; GOTO m
    CASE m_jump:       a := jump; GOTO m
    CASE m_decllabel:  a := decllabel; GOTO m
    CASE m_return:     a := r_return; GOTO m
    CASE m_blocklink:  a := blocklink; GOTO m
    CASE m_reslink:    a := reslink; GOTO m
    CASE m_power:      a := power; GOTO m
    CASE m_nil:        a := nil; GOTO m
    CASE m_dummy:      a := dummy; GOTO m
    CASE m_aug:        a := aug; GOTO m
    CASE m_setup:      setparams()
                       a := setup; GOTO m
  }
}

AND setparams() BE
{ LET i = 0
  UNTIL i=refp DO
  { ! (refv!(i+1)) := parv!(refv!i)
    i := i + 2
  }
  refp := 0
}

//>>> EJECT
// XPAL1B
LET mapliblist(f) BE
{ f("PRINT", print)
  f("PAGE", userpage)
  f("STEM", stem)
  f("STERN", stern)
  f("CONC", conc)
  f("ATOM", atom)
  f("NULL", null)
  f("ORDER", length)
  f("ISTRUTHVALUE", istruthvalue)
  f("ISINTEGER", isnumber)
  f("ISREAL", isreal)
  f("ISSTRING", isstring)
  f("ISFUNCTION", isfunction)
  f("ISLABEL", islabel)
  f("ISTUPLE", istuple)
  f("ISDUMMY", isdummy)
  f("ISENVIROMENT", isenviroment)
  f("FINISH", r_finish)
  f("SHARE", share)
  f("STOI", ston)
  f("CTOI", cton)
  f("ITOC", ntoc)
  f("RTOI", rton)
  f("ITOR", ntor)
  f("READCH", rdchar)
  f("DIAGNOSE", diagnose)
  f("LASTFN", lastfn)
  f("TABLE", r_table)
  f("LOOKUPINE", lookupine)
  f("SAVEENV", saveenv)
}

AND libname(x, y) BE
{ strp := strp - 2
  IF strp<strb DO
  { writes("*n*n*n*tSYMBOL TABLE OVERFLOW IN XPAL LOADER.*
           * NO EXECUTION.*n")
    longjump(xpend, xpendlevel)
  }
  strp!0 := namechain
  strp!1 := x
  namechain := strp
}

AND decllib(x, y) BE
{ a := list(3, basicfn, y)
  a := list(3, lvalue, a)
  e := list(5, env, e, x, a)
}

// XPAL2 LAST MODIFIED ON FRIDAY, 12 JUNE 1970
// AT 5:37:29.37 BY R MABEE
//>>> FILENAME "XPAL2"
//
//	***********
//	*         *
//	*  XPAL2  *
//	*         *
//	***********
//
//>>> GET "XPALHD"
//>>> EJECT
// XPAL2A
LET loadl() BE
{ c := c+1
  a := lvofname(c!0, e)
  TEST a=nilrv
  THEN { a := list(3, lvalue, a)
         errokdbg()
       }
  ELSE next11()
}

AND loadr() BE
{ c := c+1
  a := lvofname(c!0, e)
  TEST a=nilrv
  THEN errdbg()
  ELSE { a := h3!a
         next11()
       }
}

AND loadj() BE
{ a := list(5, jj, h4!s, h5!s, h6!s )
  next11()
}

AND loade() BE
{ a := e
  next11()
}

AND loads() BE
{ LET v = VEC 200
  LET i = 0
  unpackstring(c!1, v)
  i := v!0
  a := nilsrv
  WHILE i > 0 DO
  { a := list(4, string, a, v!i)
    i:=i-1
  }
  c := c+1
  next11()
}

AND loadn() BE
{ a := list(3, c!1, c!2 )
  c := c+2
  next11()
}

AND restoree1() BE
{ e := s!(stackp-2)
  stackp := stackp-1
  s!(stackp-1) := s!stackp
  c := c + 1
}

AND r_true() BE
{ a := truerv
  next11()
}

AND r_false() BE
{ a := falserv
  next11()
}

AND loadguess() BE
{ a := guessrv
  nextlv11()
}

AND nil() BE
{ a := nilrv
  next11()
}

AND dummy() BE
{ a := dummyrv
  next11()
}

AND formclosure() BE
{ a := list(4, closure, e, c!1 )
  c := c+1
  next11()
}

AND formlvalue() BE
{ a := list(3, lvalue, s!(stackp-1))
  s!(stackp-1) := a
  c := c+1
}

AND nextlv11() BE
{ a := list(3, lvalue, a)
  next11()
}

AND next11() BE
{ s!stackp := a
  stackp := stackp+1
  c := c + 1
}

AND formrvalue() BE
{ s!(stackp-1) := h3!(s!(stackp-1))
  c := c+1
}

AND tuple() BE
{ LET n = c!1
  a := node(n+3)
  a!0, a!1, a!2 := n+3, m_tuple, n
  FOR i = 3 TO n+2 DO
    stackp, a!i := stackp-1, s!stackp
  c := c+1
  next11()
}

AND members() BE
{ LET n = c!1
  split1()
  b := h3!a
  FOR i = -2 TO n-3 DO
  { s!stackp := b!(n-i)
    stackp := stackp+1
  }
  c := c+2
}

AND r_not() BE
{ split1()
  IF h2!a=m_false DO
  { a := truerv
    next11()
    RETURN
  }
  TEST h2!a=m_true
  THEN { a := falserv
         next11()
        }
  ELSE { error1("NOT", a, 0)
         errdbg()
       }
}

AND r_logand() BE
{ split2()
  TEST testbools2()
  THEN { a := h2!a=m_true -> b, falserv
         next11()
       }
  ELSE { error1("&", a, b)
         a := falserv
         errdbg()
       }
}

AND r_logor() BE
{ split2()
  TEST testbools2()
  THEN { a := h2!a=m_false -> b, truerv
         next11()
       }
  ELSE { error1("OR", a, b)
         a := falserv
         errdbg()
       }
}

AND aug() BE
{ split2()
  UNLESS h2!a=m_tuple DO
  { error1("AUG", a, b)
    a := nilrv
    errdbg()
    RETURN
  }
  { LET n = h3!a
    LET t = node(n+4)
    t!0, t!1, t!2, t!(n+3) := n+4, m_tuple, n+1, b
    FOR i = 3 TO n+2 DO t!i := a!i
    a := t
    next11()
  }
}

AND result() BE
{ a := lvofname(nameres, e)
  IF a=nilrv DO
  { a := list(3, lvalue, a)
    GOTO reserr
  }
  a := h3!a
  UNLESS h2!a=jj DO
reserr:	{ error("INCORRECT USE OF RES", 0, 0, 0)
          errokdbg()
          RETURN
        }
  h4!s, h5!s, h6!s := h3!a, h4!a, h5!a
  r_return()
}

//>>> EJECT
// XPAL2B
LET mult() BE
{ LET t = a
  split2()
  IF testnumbs2()=number DO
  { a := list(3, number, h3!a*h3!b )
    next11()
    RETURN
  }
  IF testnumbs2()=real DO
  { a := list(3, real, fmult(h3!a, h3!b) )
    IF floterr DO
    { writes("*nOVERFLOW:")
      floterr := FALSE
      GOTO fmuerr
    }
    next11()
    RETURN
  }
  a := list(3, number, 0)
fmuerr:
  error1("**", t, b)
  errdbg()
}

AND div() BE
{ LET t = a
  split2()
  IF testnumbs2()=number DO
  { IF h3!b=0 GOTO derr
    a := list(3, number, h3!a/h3!b )
    next11()
    RETURN
  }
  IF testnumbs2()=real DO
  { a := list(3, real, fdiv(h3!a, h3!b) )
    IF floterr DO
    { UNLESS feq(h3!b, 0) DO writes("*nOVERFLOW:")
      floterr := FALSE
      GOTO derr
    }
    next11()
    RETURN
  }
derr:
  a := list(3, number, 0)
  error1("/", t, b)
  errdbg()
}

AND plus() BE
{ LET t = a
  split2()
  IF testnumbs2()=number DO
  { a := list(3, number, h3!a+h3!b )
    next11()
    RETURN
  }
  IF testnumbs2()=real DO
  { a := list(3, real, fadd(h3!a, h3!b) )
    IF floterr DO
    { writes("*nOVERFLOW:")
      floterr := FALSE
      GOTO fperr
    }
    next11()
    RETURN
  }
  a := list(3, number, 0)
fperr:
  error1("+", t, b)
  errdbg()
}

AND minus() BE
{ LET t = a
  split2()
  IF testnumbs2()=number DO
  { a := list(3, number, h3!a-h3!b )
    next11()
    RETURN
  }
  IF testnumbs2()=real DO
  { a := list(3, real, fsub(h3!a, h3!b) )
    IF floterr DO
    { writes("*nOVERFLOW:")
      floterr := FALSE
      GOTO fmerr
    }
    next11()
    RETURN
  }
  a := list(3, number, 0)
fmerr:
  error1("-", t, b)
  errdbg()
}

AND power() BE
{ LET t = a
  split2()
  UNLESS h2!b=number GOTO pwerr
  IF h2!a=number DO
  { LET base, exp, r = h3!a, h3!b, 1
    TEST exp <= 0
    THEN { IF base=0 GOTO pwerr
           r := ABS base = 1 -> ((-exp & 1)=0 -> 1, base), 0
         }
    ELSE UNTIL exp=0 DO
         { UNLESS (exp & 1)=0 DO r := r * base
           base := base * base
           exp := exp >> 1
         }
    a := list(3, number, r)
    next11()
    RETURN
  }
  IF h2!a=real DO
  { a := list(3, real, fpower(h3!a, h3!b) )
    IF floterr DO
    { writes("*nOVERFLOW:")
      floterr := FALSE
      GOTO pwerr
    }
    next11()
    RETURN
  }
pwerr:
  a := list(3, number, 0)
  error1("****", t, b)
  errdbg()
}

AND pos() BE
{ split1()
  TEST h2!a=number | h2!a=real
  THEN { a := list(3, h2!a, h3!a )
         next11()
       }
  ELSE { error1("+", a, 0)
         a := list(3, number, 0)
         errdbg()
       }
}

AND neg() BE
{ LET t=a
  split1()
  IF h2!a=number DO
  { a := list(3, number, -h3!a )
    next11()
    RETURN
  }
  IF h2!a=real DO
  { a := list(3, real, fumin(h3!a))
    next11()
    RETURN
  }
  a := list(3, number, 0)
  error1("-", t, 0)
  errdbg()
}

AND r_eq() BE
{ LET t=a
  split2()
  a := equal(a, b) -> truerv, falserv
  TEST errflag
  THEN { error1("EQ", t, b)
         errflag := FALSE
         errdbg()
       }
  ELSE next11()
}

AND r_ne() BE
{ LET t=a
  split2()
  a := equal(a, b) -> falserv, truerv
  TEST errflag
  THEN { error1("NE", t, b)
         a := falserv
         errflag := FALSE
         errdbg()
       }
  ELSE next11()
}

AND r_ls() BE
{ split2()
  IF testnumbs2()=number DO
	{	a := h3!a < h3!b -> truerv, falserv
		next11()
		RETURN }
	IF testnumbs2()=real DO
	{	a := fls(h3!a, h3!b) -> truerv, falserv
		next11()
		RETURN }
	error1("LS", a, b)
	a := falserv
	errdbg()
}

AND r_le() BE
{	split2()
	IF testnumbs2()=number DO
	{	a := h3!a <= h3!b -> truerv, falserv
		next11()
		RETURN }
	IF testnumbs2()=real DO
	{	a := fle(h3!a, h3!b) -> truerv, falserv
		next11()
		RETURN }
	error1("LE", a, b)
	a := falserv
	errdbg() }

AND r_ge() BE
{	split2()
	IF testnumbs2()=number DO
	{	a := h3!a >= h3!b -> truerv, falserv
		next11()
		RETURN }
	IF testnumbs2()=real DO
	{	a := fge(h3!a, h3!b) -> truerv, falserv
		next11()
		RETURN }
	error1("GE", a, b)
	a := falserv
	errdbg() }

AND r_gr() BE
{	split2()
	IF testnumbs2()=number DO
	{	a := h3!a > h3!b -> truerv, falserv
		next11()
		RETURN }
	IF testnumbs2()=real DO
	{	a := fgr(h3!a, h3!b) -> truerv, falserv
		next11()
		RETURN }
	error1("GR", a, b)
	a := falserv
	errdbg() }

//>>> EJECT
// XPAL2C
LET jump() BE {	c := c!1 }

AND jumpf() BE
{ split1()
  IF h2!a = m_false DO
  { c := c!1
    RETURN
  }
  IF h2!a = m_true DO
  { c := c+2
    RETURN
  }
  error("NOT A TRUTHVALUE: ", a, 0, 0)
  c := c!1 - 1
  edbg()
}

AND edbg() BE
{ restartc := c+1
  c := @ restart
  a := list(3, lvalue, nilrv)
  comdbg()
}

AND errdbg() BE
{ restartc := c+1
  c := @ rvrestart
  a := list(3, lvalue, a)
  comdbg()
}

AND errlvdbg() BE
{ a := list(3, lvalue, a)
  errokdbg()
}

AND errokdbg() BE
{ restartc := c+1
  c := @ okrestart
  comdbg()
}

AND comdbg() BE
{ h3!s := stackp
  b := node(8)
  h1!b, h2!b := 8, stack
  h4!b, h5!b := restartc, s
  h6!b, h7!b := e, a
  s := b
  b := h3!errorlv
  stackp := 7
  errct := errct + 1
  IF errct >= maxerr DO c := @ norestart
  UNLESS h2!b = closure | h2!b=basicfn DO
  { UNLESS errct >= maxerr DO
      writes("EXECUTION RESUMED*n*n")
    RETURN
  }
  TEST h2!b=closure
  THEN { s!stackp := errorlv
         stackp := stackp+1
         a := b
         oldc, c := c, h4!b
       }
  ELSE { c := c-3
         nil()
         formlvalue()
         (h3!b)()
       }
  restartc := 0
}

AND okrestart() BE
{	a := s!(stackp-1)
	restart()
	s!stackp := a
	stackp := stackp+1 }

AND rvrestart() BE
{ a := s!(stackp-1)
  restart()
  s!stackp := h3!a
  stackp := stackp+1
}

AND norestart() BE
{ writes("*nMAXIMUM NUMBER OF RUN-TIME ERRORS REACHED*n")
  terminate1()
}

AND apply() BE
{ split1()
  a := h3!a
  SWITCHON h2!a INTO
  { CASE closure:
      stackp := stackp+1
      oldc, c := c+1, h4!a
      RETURN

    CASE m_tuple:
      stackp, b := stackp-1, s!stackp
      b := h3!b
      UNLESS h2!b=number DO
      { error(0, a, " APPLIED TO ", b)
        UNLESS h3!a=0 DO a := h4!a
        errlvdbg()
        RETURN
      }
      { LET n = h3!b
        TEST 1 <= n <= h3!a
        THEN { a := a!(n+2)
               next11()
             }
        ELSE { error(0, a, " APPLIED TO ", b)
        UNLESS h3!a=0 TEST n >= 1
        THEN a := a!(h3!a+2)
        ELSE a := h4!a
        errlvdbg() }
        RETURN
      }

    CASE basicfn:
      (h3!a)()
      RETURN

    DEFAULT:
      error("ATTEMPT TO APPLY ",a," TO ",s!(stackp-1))
      edbg()
  }
}

AND save() BE
{ b := node(c!1+6)
  h1!b, h2!b := c!1+6, stack
  h3!s := stackp
  h4!b, h5!b := oldc, s
  h6!b, h7!b := e, s!(stackp-2)
  e := h3!a
  stackp, s := 7, b
  c := c+2
}

AND r_return() BE
{ a := s!(stackp-1)
  restart()
  stackp := stackp-1
  s!(stackp-1) := a
}

AND testempty() BE
{ split1()
  TEST h3!a=nilrv
  THEN c := c+1
  ELSE { error1("FUNCTION OF NO ARGUMENTS", a, 0)
         edbg()
       }
}

AND lose1() BE
{ split1()
  c := c+1
}

AND r_goto() BE
{ split1()
  UNLESS h2!a=label DO
  { error("CANNOT GO TO ", a, 0, 0)
    a := dummyrv
    errdbg()
    RETURN
  }
  c, e := h4!a, h6!a
  s := node(h3!a)
  stackp := 6
  h1!s, h2!s := h3!a, stack
  a := h5!a
  h4!s, h5!s, h6!s := h4!a, h5!a, h6!a
}

AND update() BE
{ LET n = c!1
  split2()
  TEST n = 1 THEN h3!b := a
  ELSE { UNLESS h2!a = m_tuple & h3!a = n DO
         { error("CONFORMALITY ERROR IN ASSIGNMENT",0,0,0)
           writes("THE VALUE OF THE RHS IS: ")
           printa(a, tupledepth)
           newline()
           writes("THE NUMBER OF VARIABLES ON THE LHS IS: ")
           writen(n)
           wrch('*n')
           c := c + 1
           a := dummyrv
           errdbg()
           RETURN
         }
         b := h3!b
         { LET v = VEC 100
           FOR i=3 TO n+2 DO v!i := h3!(a!i)
           FOR i=3 TO n+2 DO h3!(b!i) := v!i
         }
       }
  a := dummyrv
  c := c+1
  next11()
}

//>>> EJECT
// XPAL2D
MANIFEST {	lfield=#o177777; ndist=24 }

LET error(ms1, db1, ms2, db2) BE
{ writes("*n*nRUN TIME ERROR: ")
  UNLESS ms1 = 0 DO writes(ms1)
  UNLESS db1 = 0 DO printa(db1, tupledepth)
  UNLESS ms2 = 0 DO writes(ms2)
  UNLESS db2 = 0 DO printa(db2, tupledepth)
  wrch('*n')
}

AND error1(op, arg1, arg2) BE
{ writes("*n*nRUN TIME ERROR: ")
  writes(op)
  writes(" APPLIED TO ")
  printa(arg1, tupledepth)
  UNLESS arg2=0 DO
  { writes(" AND ")
    printa(arg2, tupledepth)
  }
  wrch('*n')
}

AND printb(x) BE
{ IF x=0 RETURN
  SWITCHON h2!x INTO
  { CASE number:   writen(h3!x)
                   RETURN

    CASE real:   { LET v = VEC 3
                   ftos(h3!x, v)
                   writes(v)
                   RETURN
                 }

    CASE string:   wrch(h4!x)
                   printb(h3!x)
    CASE nils:     RETURN

    CASE m_tuple:{ LET n = h3!x
                   IF n = 0 DO
                   { writes("NIL")
                     RETURN
                   }
                   IF @ x > stackwarning DO
                   { writes("( ETC )")
                     RETURN
                   }
                   wrch('(')
                   FOR i = 3 TO n+1 DO
                   { printb(x!i)
                     writes(", ")
                   }
                   printb(x!(n+2))
                   wrch(')')
                   RETURN
                 }

    CASE m_true:   writes("TRUE"); RETURN
    CASE m_false:  writes("FALSE"); RETURN
    CASE lvalue:   printb(h3!x); RETURN
    CASE closure:
    CASE basicfn:  writes("$FUNCTION$"); RETURN
    CASE label:    writes("$LABEL$"); RETURN
    CASE jj:       writes("$ENVIRONMENT$"); RETURN
    CASE m_dummy:  writes("$DUMMY$"); RETURN
    DEFAULT:       writes("$$$")
  }
}

AND printa(x, n) BE
{ IF x=0 RETURN
  IF n <= 0 DO { writes(" ETC "); RETURN }
  SWITCHON h2!x INTO
  { CASE string:
    CASE nils:
      wrch('*'')
      printb(x)
      wrch('*'')
      RETURN

    CASE m_tuple:
    { LET m = h3!x
      IF m=0 DO { writes(" NIL "); RETURN }
      wrch('(')
      FOR i = 3 TO m+1 DO
      { printa(x!i, n-1)
        wrch(',')
      }
      printa(x!(m+2), n-1)
      wrch(')')
      RETURN
    }

    CASE lvalue:
      printa(h3!x, n)
      RETURN

    DEFAULT:
      wrch(' ')
      printb(x)
      wrch(' ')
      RETURN
  }
}

AND equal(a,b) = VALOF
{ LET btag = h2!b
  SWITCHON btag INTO
  { CASE m_true:
    CASE m_false:
    CASE number:
    CASE real:
    CASE string:
    CASE nils:
      SWITCHON h2!a INTO
      { CASE m_true:   IF btag=m_true RESULTIS TRUE
                       RESULTIS FALSE
        CASE m_false:  IF btag=m_false RESULTIS TRUE
                       RESULTIS FALSE
        CASE number:   IF btag=number & h3!a=h3!b RESULTIS TRUE
                       RESULTIS FALSE
        CASE real:     IF btag=real & h3!a=h3!b RESULTIS TRUE
                       RESULTIS FALSE
        CASE string:   IF btag=string & h4!a=h4!b RESULTIS equal(h3!a,h3!b)
                       RESULTIS FALSE
        CASE nils:     IF btag=nils RESULTIS TRUE
                       RESULTIS FALSE
      }
  }
  errflag := TRUE
  RESULTIS FALSE
}

AND testnumbs2() = h2!a=number & h2!b=number -> number,
		   h2!a=real & h2!b=real -> real,
		   m_false

AND testbools2() = ( h2!a=m_true | h2!a=m_false ) &
		   ( h2!b=m_true | h2!b=m_false )
AND lvofname(n, p) = VALOF
{ h3!lookupno := h3!lookupno + 1
  UNTIL p = 0 DO
  { IF h4!p = n RESULTIS h5!(p)
    p := h3!p
  }
  UNLESS n=nameres DO
    error("UNDECLARED NAME ", 0, n, 0)
  RESULTIS nilrv
}

AND nameoflv(l, p) = VALOF
{ UNTIL p=0 DO
  { IF h5!p=l RESULTIS h4!p
    p := h3!p
  }
  RESULTIS 0
}

AND restart() BE
{ c, b, e := h4!s, h5!s, h6!s
  s := node(h1!b & lfield)
  stackp := h3!b
  FOR i = 0 TO stackp-1 DO s!i := b!i
}

AND terminate() BE
{ listt := listt + 6 // CREATE EXTRA SPACE FOR FINAL DIAGNOSE
  diagnose()
  terminate1()
}

AND terminate1() BE
{ //control(output, 2)
  writen(h3!lookupno)
  writes(" LOOKUPS *t")
  writen(count)
  writes(" CYCLES*n")
  gcmark := gcmark >> 16
  writen(gcmark)
  writes(" GARBAGE COLLECTIONS*n")
  longjump(xpend, xpendlevel)
}

AND lastfn1(p) = VALOF
{ LET name, arg = 0, 0
  LET y, n = 0, 0
  IF h6!q=0 RESULTIS FALSE
  { y := h5!q
    n := h3!y
    TEST n>6
    THEN { name := y!(n-1)
           UNLESS name=nilrv DO
           { name := nameoflv(name, h6!q)
             IF name=0 DO name := "ANONYMOUS"
             arg := y!(n-2)
           }
         }
    ELSE name := nilrv
    q := y
    IF p=0 RESULTIS TRUE
    IF h6!q=0 RESULTIS FALSE
  } REPEATWHILE name=nilrv
  writes("AT THIS TIME, THE FUNCTION BEING EXECUTED IS: ")
  writes(name)
  writes("*nTHE ARGUMENT TO WHICH IT IS BEING APPLIED IS: ")
  printa(arg, tupledepth)
  wrch('*n')
  RESULTIS TRUE
}

AND writenode(n) BE
{ writen(n >> ndist)
  wrch('*t')
  writes(h4!a)
  wrch('*t')
  printa(h5!a, tupledepth)
  wrch('*n')
}

//>>> EJECT
// XPAL2E
MANIFEST {
 lfield=#o177777; mfield=#o77600000; gc1=#o200000
}

LET node(n) = VALOF
{ IF listp+n >= listl DO nextarea(n)
  listp := listp+n
  RESULTIS listp-n
}

AND nextarea(n) BE
{ LET b = FALSE
  IF gcdbg DO writes("*n*nNEXTAREA RECLAIMATION PHASE*n")
  { UNLESS listp=listl DO h1!listp := listl - listp
    IF listl=listt DO
    { IF b DO
      { writes("*n*nRUN TIME SPACE EXHAUSTED*n")
        terminate()
      }
      mark()
      IF gcdbg DO writes("*nMARKLIST PREFORMED*n")
      listl, b := listv, TRUE
    }
    h1!listt := 0
    WHILE ( h1!listl & mfield ) = gcmark DO
      listl := listl + ( h1!listl & lfield )
    listp := listl
    h1!listt := gcmark
    UNTIL ( h1!listl & mfield ) = gcmark DO
      listl := listl + ( h1!listl & lfield )
    IF gcdbg DO { writes("*s*s"); writen(listl-listp) }
  } REPEATWHILE listp+n >= listl
  IF gcdbg DO writes("*s*n")
  RETURN
}

AND marklist(x) BE
{ l:
  IF @ x > stackwarning DO
  { writes("*n*nMAXIMUM NODE DEPTH EXCEEDED*n")
    terminate()
  }
  IF x=0 RETURN
  IF ( h1!x & mfield ) = gcmark RETURN
  h1!x := h1!x & lfield | gcmark
  SWITCHON h2!x INTO
  { DEFAULT:
      writes("*n*nMARKLIST ERROR*n")
      writehex(x); writes(" H1!x="); writehex(h1!x)
      writes(" NODE TYPE IS "); writen(h2!x)
      writes("*s*n")
      RETURN

    CASE m_tuple:
      FOR i = 1 TO h3!x DO marklist(x!(i+2))
      RETURN

    CASE env:
      marklist(h5!x)
      x := (h3!x)
      GOTO l

    CASE stack:
      FOR i = 4 TO h3!x-1 DO marklist(x!i)
      RETURN

    CASE jj:
      marklist(h5!x)
      x := (h4!x)
      GOTO l

    CASE label:
      marklist(h6!x)
      x := (h5!x)
      GOTO l

    CASE lvalue:CASE closure:CASE string:
      x := (h3!x)
      GOTO l
    CASE number:CASE m_true:CASE m_false:CASE m_nil:
    CASE nils:CASE basicfn:CASE guess:
    CASE m_dummy:CASE real:
    RETURN
  }
}

AND mark() BE
{ gcmark := gcmark + gc1
  nset := FALSE
  IF ( gcmark & mfield ) = 0 DO
  { writes("*n*nMAXIMUM NUMBER OF ")
    writes("GARBAGE COLLECTIONS PERFORMED*n")
    terminate()
  }
  marklist(e)
  h3!s := stackp
  marklist(s)
  marklist(a)
  marklist(b)
  RETURN
}

AND list(n, a, b, c, d, e, f) = VALOF
{ f := @ n
  { LET p = node(n)
    SWITCHON n INTO
    { CASE 7: p!6 := f
      CASE 6: p!5 := e
      CASE 5: p!4 := d
      CASE 4: p!3 := c
      CASE 3: p!2 := b
      CASE 2: p!1 := a
      CASE 1: p!0 := n
    }
    f := 0
    RESULTIS p
  }
}

//>>> EJECT
// XPAL2F
MANIFEST { lfield=#o177777 }

LET split1() BE
{ stackp, a := stackp-1, s!stackp
}

AND split2() BE
{ stackp, a, b := stackp-2, s!(stackp+1), s!(stackp)
}

AND declname() BE
{ e := list(5, env, e, c!1, s!(stackp-1))
  stackp := stackp-1
  c := c + 2
}

AND declnames() BE
{ LET n = c!1
  split1(); a := h3!a
  UNLESS h2!a=m_tuple & h3!a=n DO
  { error("CONFORMALITY ERROR IN DEFINITION", 0, 0, 0)
    nameerror(n,1)
    RETURN
  }
  FOR i = 2 TO n+1 DO r_name(i,1)
  c := c+2+n
}

AND initname() BE
{ stackp := stackp-1
  r_name(1,7)
  c := c+2
}

AND initnames() BE
{ LET n = c!1
  split1(); a := h3!a
  UNLESS h2!a=m_tuple & h3!a=n DO
  { error("CONFORMALITY ERROR IN RECURSIVE DEFINITION",0,0,0)
    nameerror(n,4)
    RETURN
  }
  FOR i = 2 TO n+1 DO r_name(i,4)
  c := c+2+n
}

AND r_name(i,p) BE
{ TEST p <= 3
  THEN e := list(5, env, e, c!i,
                 p=1 -> a!(i+1), list(3, lvalue, (p=2 -> a, nilrv)) )
  ELSE { b := lvofname(c!i, e)
         IF b=nilrv DO b := list(3, lvalue, b)
         SWITCHON p INTO
         { CASE 4: h3!b := h3!(a!(i+1)); RETURN
           CASE 5: h3!b := a; RETURN
           CASE 6: h3!b := nilrv; RETURN
           CASE 7: h3!b := h3!(s!stackp); RETURN
         }
       }
}

AND nameerror(n,p) BE
{ writes("THE NAMES BEING DECLARED ARE:*n")
  FOR i = 2 TO n+1 DO
  { writes(c!i)
    wrch('*n')
  }
  writes("THE VALUE(S) PROVIDED ARE: ")
  printa(a, tupledepth)
  newline()
  TEST h2!a=m_tuple
  THEN { LET m=n
         IF m>h3!a DO m := h3!a
         FOR i = 2 TO m+1 DO r_name(i,p)
         FOR i = m+2 TO n+1 DO r_name(i,p+2)
       }
  ELSE { r_name(2,p+1)
         FOR i = 3 TO n+1 DO r_name(i,p+2)
       }
  c := c+n+1
  edbg()
}

AND decllabel() BE
{ a := list(6, stack, 6, h4!s, h5!s, h6!s)
  a := list(6, label* h1!s&lfield, c!2, a, e)
  a := list(3, lvalue, a)
  e := list(5, env, e, c!1, a)
  c := c + 3
}

AND setlabes() BE
{ a := e
  FOR i = 1 TO c!1 DO
  { h6!(h3!(h5!a)) := e
    a := h3!a
  }
  c := c + 2
}

AND blocklink() BE
{ s!stackp := nilrv
  stackp := stackp+1
  oldc := c!1
  a := list(3, lvalue, e)
  c := c+2
}

AND reslink() BE
{ s!stackp := list(3, lvalue, nilrv)
  stackp := stackp+1
  blocklink()
}

AND setup() BE
{ oldc := @ r_finish
  s := list(5, stack, 4, dummyrv, 0)
  a := list(3, lvalue, e)
  e := 0
  stackp := 5
  save()
  split1()
}


// XPAL3 LAST MODIFIED ON FRIDAY, 12 JUNE 1970
// AT 5:37:38.68 BY R MABEE
//>>> FILENAME "XPAL3"
//
//	***********
//	*         *
//	*  XPAL3  *
//	*         *
//	***********
//
//>>> GET "XPALHD"
//>>> EJECT
// XPAL3A
LET r_finish() BE
{ writes("*n*nEXECUTION FINISHED*n")
  terminate1()
}

AND print() BE
{ split1()
  printb(a)
  a := dummyrv
  nextlv11()
}

AND userpage() BE
{ split1()
  //control(output, -1)
  a := dummyrv
  nextlv11()
}

AND stem() BE
{ split1(); b := h3!a
  a := nilsrv
  UNLESS h2!b=string DO
  { error1("STEM", b, 0)
    errlvdbg()
    RETURN
  }
  a := list(4, string, a, h4!b )
  nextlv11()
}

AND stern() BE
{ split1(); a := h3!a
  UNLESS h2!a=string DO
  { error1("STERN", a, 0)
    a := nilsrv
    errlvdbg()
    RETURN
  }
  a := h3!a
  nextlv11()
}

AND conc() BE
{ a := h3!(s!(stackp-1))
  UNLESS h2!a=m_tuple & h3!a=2 DO
concerr:{ error1("CONC", a, 0)
          split1()
          a := nilsrv
          errlvdbg()
          RETURN
        }
  { LET x, y = h2!(h3!(h4!a)), h2!(h3!(h5!a))
    UNLESS ( x=string | x=nils ) &
           ( y=string | y=nils ) GOTO concerr
    { LET v = VEC 512
      b, x := h3!(h4!a), 1
      UNTIL h2!b = nils DO
      { v!x := h4!b
        b := h3!b
        x := x+1
      }
      IF x=1 DO
      { b := h3!(h5!a)
        split1()
        a := b
        nextlv11()
        RETURN
      }
      b := list(4, string, 0, v!q) //???
      a := b
      FOR i = 2 TO x-1 DO
      { h3!a := list(4, string, 0, v!i)
        a := h3!a
      }
      h3!a := h3!(h5!(h3!(s!(stackp-1))))
      split1()
      a := b
      nextlv11()
    }
  }
}

AND atom() BE
{ split1()
  SWITCHON h2!(h3!a) INTO
  { CASE m_true:
    CASE m_false:
    CASE number:
    CASE real:
    CASE string:
    CASE nils:
      a := truerv
      nextlv11()
      RETURN
  }
  a := falserv
  nextlv11()
}

AND null() BE
{ split1()
  a := h2!(h3!a)=m_tuple & h3!(h3!a)=0 -> truerv, falserv
  nextlv11()
}

AND length() BE
{ split1()
  UNLESS h2!(h3!a)=m_tuple DO
  { error1("ORDER", a, 0)
    a := list(3, number, 0)
    errlvdbg()
    RETURN
  }
  a := list(3, number, h3!(h3!a) )
  nextlv11()
}

AND istruthvalue() BE
{ split1()
  SWITCHON h2!(h3!a) INTO
  { CASE m_true:
    CASE m_false:
      a := truerv
      nextlv11()
      RETURN
  }
  a := falserv
  nextlv11()
}

AND isnumber() BE
{ split1()
  a := h2!(h3!a)=number -> truerv, falserv
  nextlv11()
}

AND isstring() BE
{ split1()
  SWITCHON h2!(h3!a) INTO
  { CASE string:
    CASE nils:
      a := truerv
      nextlv11()
      RETURN
  }
  a := falserv
  nextlv11()
}

AND isfunction() BE
{ split1()
  SWITCHON h2!(h3!a) INTO
  { CASE closure:
    CASE basicfn:
      a := truerv
      nextlv11()				
      RETURN
  }
  a := falserv
  nextlv11()
}

AND isenvironment() BE
{ split1()
  a := h2!(h3!a)=jj -> truerv, falserv
  nextlv11()
}

AND islabel() BE
{ split1()
  a := h2!(h3!a)=label -> truerv, falserv
  nextlv11()
}

AND istuple() BE
{ split1()
  a := h2!(h3!a)=m_tuple -> truerv, falserv
  nextlv11()
}

AND isreal() BE
{ split1()
  a := h2!(h3!a)=real -> truerv, falserv
  nextlv11()
}

AND isdummy() BE
{ split1()
  a := h2!(h3!a)=m_dummy -> truerv, falserv
  nextlv11()
}

AND share() BE
{ split1()
  a := h3!a
  UNLESS h2!a=m_tuple & h3!a=2 DO
  { error1("SHARE", a, 0)
    a := falserv
    errlvdbg()
    RETURN
  }
  a := h4!a=h5!a -> truerv, falserv
  nextlv11()
}

//>>> EJECT
// XPAL3B
MANIFEST {
  nfield=#o67700000000; n1=#o100000000
}

LET ston() BE
{ split1(); a := h3!a
  UNLESS h2!a=string DO
  { error1("STOI", a, 0)
    a := list(3, number, 0)
    errlvdbg()
    RETURN
  }
  { LET b = 0
    WHILE h2!a=string DO
    { b := b*10 + h4!a - '0'
      a := h3!a
    }
    a := list(3, number, b)
    nextlv11()
  }
}

AND cton() BE
{ split1()
  a := h3!a
  UNLESS h2!a=string & h2!(h3!a)=nils DO
  { error1("CTOI", a, 0)
    a := list(3, number, 0)
    errlvdbg()
    RETURN
  }
  a := list(3, number, h4!a )
  nextlv11()
}

AND ntoc() BE
{ split1()
  a := h3!a
  UNLESS h2!a=number & h3!a < 256 & h3!a >= 0 DO
  { error1("ITOC", a, 0)
    a := nilsrv
    errlvdbg()
    RETURN
  }
  a := list(4, string, nilsrv, h3!a )
  nextlv11()
}

AND ntor() BE
{ split1(); a := h3!a
  UNLESS h2!a=number DO
  { error1("ITOR", a, 0)
    a := list(3, real, 0)
    errlvdbg()
    RETURN
  }
  a := list(3, real, itor(h3!a) )
  nextlv11()
}

AND rton() BE
{ split1(); a := h3!a
  UNLESS h2!a=real DO
  { error1("RTOI", a, 0)
    a := list(3, number, 0)
    errlvdbg()
    RETURN
  }
  a := list(3, number, rtoi(h3!a) )
  nextlv11()
}

AND rdchar() BE
{ split1()
  a := list(2, nils)
  IF linep>linet DO
  { UNLESS dataflag GOTO enddata
    IF ch='#' TEST dataflag
    THEN { dataflag := FALSE
           nextlv11() // VALUE OF NILS INDICATES EOD
           RETURN
         }
    ELSE
enddata: { writes("*nEND OF DATA FILE ENCOUNTERED*n*n")
           terminate1() }
           linet := linev
           linet!0 := ch
           UNTIL ch='*n' DO
           { ch := rdch()
             linet := linet + 1
             linet!0 := ch
           }
    ch := rdch()
    linep := linev 
  }
  a := list(4, string, a, linep!0 )
  linep := linep + 1
  nextlv11()
}

AND r_table() BE
{ split1(); a := h3!a
  UNLESS h2!a = m_tuple & h3!a = 2 DO
tablerr:{ error1("TABLE", a, 0)
          a := nilrv
          errlvdbg()
          RETURN
        }
  { LET n = h3!(h4!a)
    UNLESS h2!n = number GOTO tablerr
    n := h3!n
    b := h3!(h5!a)
    a := node(n+3)
    a!0, a!1, a!2 := n+3, m_tuple, n
    FOR i = 3 TO n+2 DO a!i := list(3, lvalue, b)
    nextlv11()
  }
}

AND diagnose() BE
{ LET n, i = 0, 1000
  a := s!(stackp-1)
  s!(stackp-1) := list(3, lvalue, dummyrv) // RETURN VALUE
					//REPLACES ARGUMENT ON STACK
  c := c+1
  IF h2!(h3!a)=number DO i := h3!(h3!a)
  errorlv := list(3, lvalue, list(3, basicfn, lastfn) )
  IF nset DO	// 2 SUCCESSIVE EXECUTIONS OF DIAGNOSE REQUIRE
			// AN INTERVENING MARKING PHASE
  { mark()
    listl := listv
  } // TAKE ADVANTAGE OF THE EXTRA
    // MARKING PHASE
  nset := TRUE
  //control(output, -1)
  writes("THE CURRENT ENVIRONMENT IS:*n*n")
  a := e
  q := s
  IF h4!s=restartc DO // TRUE IFF CALL IS FROM COMDBG
    lastfn1(0) // PEEL OFF TOP STACK NODE
l:writes("*tVARIABLE*tRVALUE*n*n")
  WHILE h4!a ~= 0 DO
  { LET m = h1!a & nfield
    TEST m ~= 0
    THEN { writenode(m)
           writes("ETC*n")
           BREAK
         }
    ELSE { n := n+n1
           h1!a := h1!a | n
           writenode(n)
           a := h3!a
         }
  }
  i := i-1
  a := h6!q
  //control(output, 3)
  UNLESS lastfn1(1) DO
fini:{ //control(output, -1)
       RETURN
     }
  IF i <= 0 GOTO fini
  writes("*n*nTHE ENVIRONMENT IN WHICH ")
  writes("THE ABOVE APPLICATION TAKES PLACE IS:*n*n")
  GOTO l
}

AND lastfn() BE
{ s!(stackp-1) := list(3, lvalue, dummyrv) // RETURN VALUE
  // REPLACES ARGUMENT ON STACK
  c := c+1
  //control(output, 2)
  q := s
  IF h4!s=restartc DO // TRUE IFF CALL IS FROM COMDBG
    lastfn1(0) // PEEL OFF TOP STACK NODE
  UNLESS lastfn1(1) DO
    writes("ERROR OCCURRED IN OUTER LEVEL OF PROGRAM*n")
  //control(output, 3)
}

AND lookupine() BE
{ split1(); a := h3!a
  UNLESS h2!a = m_tuple & h3!a = 2 DO
lerr:{ error1("LOOKUPINE", a, 0)
       a := nilrv
       errlvdbg()
       RETURN
     }
  { LET x, i, l = h3!(h5!a), 1, namechain
    LET vp = VEC 10
    LET v = VEC 40
    b := h3!(h4!a)
    UNLESS h2!b=string & h2!x=jj GOTO lerr
    WHILE h2!b=string DO
    { v!i := h4!b
      b := h3!b
      i := i+1
    }
    v!0 := i-1
    packstring(v, vp)
    i := ( i-1 )/bytesperword + 1
    UNTIL l=0 DO
    { LET v = l!1
      IF vp!0=v!0 DO
      { IF i=1 BREAK
        IF vp!1=v!1 DO
        { IF i=2 BREAK
          IF vp!2=v!2 DO
          { IF i=3 BREAK
            IF vp!3=v!3 DO
            { IF i=4 BREAK
              IF vp!4=v!4 IF i=5 BREAK
            }
          }
        }
      }
      l := l!0
    }
    TEST l=0
    THEN i := vp
    ELSE i := l!1
    a := lvofname(i, h5!x)
    TEST a=nilrv
    THEN errlvdbg()
    ELSE next11()
  }
}

AND saveenv() BE
{ split1()
  a := list(5, jj, h4!s, h5!s, h6!s)
  nextlv11()
}

