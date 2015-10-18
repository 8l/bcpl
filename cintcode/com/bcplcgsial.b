// This is the Ocode to Sial codegenerator

// Implemented by Martin Richards (c) July 2007


/* Change history

10/08/14
Added floating point instructions: fix, float, fabs, fmul,
fdiv, fadd, fsub, fneg, feq, fne, fls, fgr fle and fge.

10/05/13
Major change to the compilation of SWITCHON to stop the compiler
crashing when given CASE minint:. See function switcht.

08/07/09
Made into a separate file to be combined with the standard BCPL
frontend (bcplsystrm.b).

*/

SECTION "bcplcgsial"

// BCPL code-generator for Sial
// Copyright  M.Richards  9 July 1998.

GET "libhdr"
GET "bcplfecg"

GET "sial.h" // This header is used by sial code conversion programs
             // such as sial-386.b

GLOBAL {
// Global procedures.
cgsects: cgg
rdl
rdgn
newlab
checklab
cgerror

initstack
stack
store
scan
cgpendingop


iszero
bits24

loada
loadboth
inreg_a
inreg_b
addinfo_a
addinfo_b

xchinfo
atbinfo
btainfo

forget_a
forget_b
forgetall
forgetvar
forgetallvars


storet
gensp
genlp
loadt
lose1
swapargs
cgstind
storein

cgrv
cgadd
cgloadk
cgaddk
cgglobal
cgentry
cgapply
cgjump
jmpfn
jfn0
revjfn
compjfn
prepj

swlpos
swrpos
findpos
rootpos

cgswitch
switcht
switchta
switchseg
switchb
switchl
cgstring

cgstatics
getblk
freeblk
freeblks

initdatalists

genfp
genfkp
genfkp
genfg
genfkg
genfpg
genfk
genfw
genfl
genflk
genfkl
genfm
genfmw

genf
geng
genc
genk
genw
genl
wrarg

cgrelop
cgfrelop

checkspace

dboutput
wrkn
wrcode
wrfcode

// Global variables.
arg1
arg2

ssp

tempt
tempv
stv
stvp

ch
dpbase
dp
freelist

incode
casek
casel

maxgn

op
labnumber
pendingop
procdepth

progsize
codelayout

info_a
info_b

clist
cliste
tlist
tliste
slist
sliste

}


MANIFEST
{
// Value descriptors.
k_none=0
k_numb=1   // numbers in the range -#xFFFFFF to #xFFFFFF
k_fnlab=2
k_lvloc=3; k_lvglob=4; k_lvlab=5; k_lstr=6; k_lw=7
k_a=8; k_b=9; k_c=10
k_loc=11; k_glob=12; k_lab=13; 
k_lock=14           //  <28-bits> lock    ie P!<28-bits>!n
k_globk=15          //  <28-bits> globk   ie G!<28-bits>!n

swapped=TRUE; notswapped=FALSE

// Global routine numbers.
gn_stop=2
}

LET codegenerate(workspace, workspacesize) BE
{ //writes("SIALCG  1 Sept 2014*n")

  IF workspacesize<2000 DO { cgerror("Too little workspace")
                             errcount := errcount+1
                             longjump(fin_p, fin_l)
                           }

  progsize := 0
  codelayout := 0

  op := rdn()

  selectoutput(gostream)
  cgsects(workspace, workspacesize)
  selectoutput(sysprint)
  writef("Program size = %n Fcodes*n", progsize)
}


AND cgsects(workvec, vecsize) BE UNTIL op=0 DO
{ LET p = workvec
  tempv := p
  p := p+90
  tempt := p
  casek := p
  p := p+400
  casel := p
  p := p+400
  dpbase := p
  dp := workvec+vecsize
  labnumber := 9000
  incode := TRUE
  maxgn := 0
  procdepth := 0
  info_a, info_b := 0, 0
  initstack(3)
  initdatalists()

  genf(f_modstart)
  IF op=s_section DO
  { LET n = rdn()

    IF naming DO genfk(f_section, n)

    FOR i = 1 TO n DO  { LET c = rdn()
                         IF naming DO genc(c)
                       }

    op := rdn()
  }

  incode := FALSE
  scan()
  op := rdn()
  incode := TRUE
  genf(f_modend)
  newline()
}

// Read in an OCODE label.
AND rdl() = VALOF
{ LET l = rdn()
  RESULTIS l
}

// Read in a global number.
AND rdgn() = VALOF
{ LET g = rdn()
  IF maxgn<g DO maxgn := g
  RESULTIS g
}


// Generate next label number.
AND newlab() = VALOF
{ labnumber := labnumber+1
  RESULTIS labnumber
}

AND cgerror(mes, a) BE
{ writes("*nError: ")
  writef(mes, a)
  newline()
  errcount := errcount+1
  IF errcount>errmax DO { writes("Too many errors*n")
                          longjump(fin_p, fin_l)
                        }
}


// Initialize the simulated stack (SS).
LET initstack(n) BE
{ arg2, arg1, ssp := tempv, tempv+3, n
  pendingop := s_none
  h1!arg2, h2!arg2, h3!arg2 := k_loc, ssp-2, ssp-2
  h1!arg1, h2!arg1, h3!arg1 := k_loc, ssp-1, ssp-1
}


// Move simulated stack (SS) pointer to N.
AND stack(n) BE
{ IF n>=ssp+4 DO { store(0,ssp-1)
                   initstack(n)
                   RETURN
                 }

  WHILE n>ssp DO loadt(k_loc, ssp)

  UNTIL n=ssp DO
  { IF arg2=tempv DO
    { TEST n=ssp-1
      THEN { ssp := n
             h1!arg1, h2!arg1, h3!arg1 := h1!arg2, h2!arg2, ssp-1
             h1!arg2, h2!arg2, h3!arg2 := k_loc, ssp-2, ssp-2
           }
      ELSE initstack(n)
      RETURN
    }

    arg1, arg2, ssp := arg1-3, arg2-3, ssp-1
  }
}



// Store all SS items from S1 to S2 in their true
// locations on the stack.
// It may corrupt both registers A and B.
AND store(s1, s2) BE FOR p = tempv TO arg1 BY 3 DO
                     { LET s = h3!p
                       IF s>s2 RETURN
                       IF s>=s1 DO storet(p)
                     }


AND scan() BE
{ IF debug>1 DO { writef("OP=%i3 PND=%i3 ", op, pendingop)
                  dboutput()
                }

  SWITCHON op INTO

  { DEFAULT:     cgerror("Bad OCODE op %n", op)
                 ENDCASE

    CASE 0:      RETURN
      
    CASE s_needs:
               { LET n = rdn()  // Ignore NEEDS directives.
                 FOR i = 1 TO n DO rdn()
                 ENDCASE
               }

    CASE s_lp:   loadt(k_loc,   rdn());   ENDCASE
    CASE s_lg:   loadt(k_glob,  rdgn());  ENDCASE
    CASE s_ll:   loadt(k_lab,   rdl());   ENDCASE
    CASE s_lf:   loadt(k_fnlab, rdl());   ENDCASE

    CASE s_ln: { LET k = rdn()
                 UNLESS -#xFFFFFF<=k<=#xFFFFFF DO
                 { LET lab = newlab()
                   loadt(k_lw, lab)
                   !cliste := getblk(0,lab,k)
                   cliste := !cliste
                   ENDCASE
                 }
                   
                 loadt(k_numb, k)
                 ENDCASE
               }

    CASE s_fnum:
               { LET x = rdn()
                 LET exponent = rdn()

                 x := sys(Sys_flt, fl_mk, x, exponent)
                 
                 UNLESS -#xFFFFFF<=x<=#xFFFFFF DO
                 { LET lab = newlab()
                   loadt(k_lw, lab)
                   !cliste := getblk(0,lab,x)
                   cliste := !cliste
                   ENDCASE
                 }
                   
                 loadt(k_numb, x)
                 ENDCASE
               }

    CASE s_lstr: cgstring(rdn());         ENDCASE

    CASE s_true: loadt(k_numb, -1);       ENDCASE
    CASE s_false:loadt(k_numb,  0);       ENDCASE

    CASE s_llp:  loadt(k_lvloc,  rdn());  ENDCASE
    CASE s_llg:  loadt(k_lvglob, rdgn()); ENDCASE
    CASE s_lll:  loadt(k_lvlab,  rdl());  ENDCASE

    CASE s_sp:   storein(k_loc,  rdn());  ENDCASE
    CASE s_sg:   storein(k_glob, rdgn()); ENDCASE
    CASE s_sl:   storein(k_lab,  rdl());  ENDCASE

    CASE s_stind:cgstind(); ENDCASE

    CASE s_rv:   cgrv(); ENDCASE

    CASE s_mul:CASE s_div:CASE s_rem:
    CASE s_add:CASE s_sub:
    CASE s_eq: CASE s_ne:
    CASE s_ls:CASE s_gr:CASE s_le:CASE s_ge:
    CASE s_lshift:CASE s_rshift:
    CASE s_logand:CASE s_logor:CASE s_eqv:CASE s_neqv:
    CASE s_not:CASE s_neg:CASE s_abs:
    CASE s_float:CASE s_fix:CASE s_fabs:
    CASE s_fmul:CASE s_fdiv:
    CASE s_fadd:CASE s_fsub:CASE s_fneg:
    CASE s_feq: CASE s_fne:
    CASE s_fls:CASE s_fgr:CASE s_fle:CASE s_fge:
                 cgpendingop()
                 pendingop := op
                 ENDCASE

    CASE s_jt:   cgjump(TRUE, rdl());  ENDCASE

    CASE s_jf:   cgjump(FALSE, rdl()); ENDCASE

    CASE s_goto: cgpendingop()
                 store(0, ssp-2)
                 TEST h1!arg1=k_fnlab
                 THEN genfl(f_j, h2!arg1)
                 ELSE { loada(arg1); genf(f_goto) }
                 stack(ssp-1)
                 incode := FALSE
                 ENDCASE

    CASE s_lab:  cgpendingop()
                 store(0, ssp-1)
                 forgetall()
                 incode := procdepth>0
                 genfl(f_lab, rdl())
                 ENDCASE

    CASE s_query:loadt(k_loc, ssp);              ENDCASE

    CASE s_stack:cgpendingop(); stack(rdn());    ENDCASE

    CASE s_store:cgpendingop(); store(0, ssp-1); ENDCASE

    CASE s_entry:
               { LET l = rdl()
                 LET n = rdn()
                 incode := TRUE
                 cgentry(l, n)
                 procdepth := procdepth + 1
                 ENDCASE
               }

    CASE s_save:
               { LET n = rdn()
                 initstack(n)
                 IF n>3 DO addinfo_a(k_loc, 3)
                 ENDCASE
               }

    CASE s_fnap:
    CASE s_rtap: cgapply(op, rdn()); ENDCASE

    CASE s_rtrn: cgpendingop()
                 genf(f_rtn)
                 incode := FALSE
                 ENDCASE
                   
    CASE s_fnrn: cgpendingop()
                 loada(arg1)
                 genf(f_rtn)
                 stack(ssp-1)
                 incode := FALSE
                 ENDCASE

    CASE s_endproc:
                 incode := FALSE
                 cgstatics()
                 procdepth := procdepth - 1
                 ENDCASE

    CASE s_res:
    CASE s_jump:
               { LET l = rdl()

                 cgpendingop()
                 store(0, ssp-2)
                 TEST op=s_jump
                 THEN storet(arg1)
                 ELSE { loada(arg1)
                        genf(f_res)   // Put result in <res>
                                      // ready for the jump to
                                      // the result label
                        stack(ssp-1)
                      }

                 { op := rdn()
                   UNLESS op=s_stack BREAK
                   stack(rdn())
                 } REPEAT

                 TEST op=s_lab
                 THEN { LET m = rdl()
                        UNLESS l=m DO genfl(f_j, l)
                        forgetall()
                        incode := procdepth>0
                        genfl(f_lab, m)
                        op := rdn()
                      }
                 ELSE { genfl(f_j, l)
                        incode := FALSE
                      }

                 LOOP
               }

    // rstack always occurs immediately after a lab statement
    // at a time when cgpendingop() and store(0, ssp-2) have
    // been called.
    CASE s_rstack:
                 stack(rdn())
                 genf(f_ldres)  // A := <res>
                 loadt(k_a, 0)
                 ENDCASE

    CASE s_finish:  // Compile code for:  stop(0).
               { LET k = ssp
                 stack(ssp+3)
                 loadt(k_numb, 0)
                 loadt(k_glob, gn_stop)
                 cgapply(s_rtap, k)
                 ENDCASE
               }

    CASE s_switchon:
                 cgswitch(); ENDCASE

    CASE s_getbyte:
                 cgpendingop()
                 TEST loadboth(arg2, arg1)=swapped
                 THEN genf(f_xgbyt)
                 ELSE genf(f_gbyt)
                 forget_a()
                 lose1(k_a, 0)
                 ENDCASE

    CASE s_putbyte:
                 cgpendingop()

                 // First move arg3 to C.
                 { LET arg3 = arg2 - 3
                   TEST arg3-tempv < 0 
                   THEN { loadt(k_loc, ssp-3)
                          loada(arg1)
                          genf(f_atc)
                          stack(ssp-1)
                        }
                   ELSE { TEST inreg_b(h1!arg3, h2!arg3)
                          THEN    genf(f_btc)
                          ELSE { loada(arg3)
                                 genf(f_atc)
                               }
                          h1!arg3 := k_c
                        }
                   TEST loadboth(arg2, arg1)=swapped
                   THEN genf(f_xpbyt)
                   ELSE genf(f_pbyt)
                   forgetallvars()
                   stack(ssp-3)
                   ENDCASE
                 }

    CASE s_global: cgglobal(rdn()); RETURN

    CASE s_datalab:
                 { LET lab = rdl() 
                   op := rdn()

                   WHILE op=s_itemn DO
                   { !tliste := getblk(0,lab,rdn())
                      tliste, lab, op := !tliste, 0, rdn()
                   }
                   LOOP
                }
  }

  op := rdn()
} REPEAT


// Compiles code to deal with any pending op.
LET cgpendingop() BE
{ LET f = 0
  LET sym = TRUE // Symmetric operator like mul or add
                 // unless otherwise specified
  LET pndop = pendingop
  pendingop := s_none
  SWITCHON pndop INTO
  { DEFAULT:      cgerror("Bad pendingop %n", pndop)

    CASE s_none:  RETURN

    CASE s_abs:   loada(arg1)
                  genf(f_abs)
                  forget_a()
                  RETURN

    CASE s_neg:   loada(arg1)
                  genf(f_neg)
                  forget_a()
                  RETURN

    CASE s_fneg:  loada(arg1)
                  genf(f_fneg)
                  forget_a()
                  RETURN

    CASE s_float: loada(arg1)
                  genf(f_float)
                  forget_a()
                  RETURN

    CASE s_fix:   loada(arg1)
                  genf(f_fix)
                  forget_a()
                  RETURN

    CASE s_fabs:  loada(arg1)
                  genf(f_fabs)
                  forget_a()
                  RETURN

    CASE s_not:   loada(arg1)
                  genf(f_not)
                  forget_a()
                  RETURN

    CASE s_eq: CASE s_ne:
    CASE s_ls: CASE s_gr:
    CASE s_le: CASE s_ge:
                  cgrelop(pndop)
                  RETURN

    CASE s_feq: CASE s_fne:
    CASE s_fls: CASE s_fgr:
    CASE s_fle: CASE s_fge:
                  cgfrelop(pndop)
                  RETURN

    CASE s_sub:   UNLESS k_numb=h1!arg1 DO
                  { f, sym := f_sub, FALSE
                    ENDCASE
                  }
                  h2!arg1 := -h2!arg1

    CASE s_add:   cgadd(); RETURN

    CASE s_mul:   f      := f_mul;         ENDCASE
    CASE s_fmul:  f      := f_fmul;        ENDCASE
    CASE s_fadd:  f      := f_fadd;        ENDCASE
    CASE s_logand:f      := f_and;         ENDCASE
    CASE s_logor: f      := f_or;          ENDCASE
    CASE s_eqv:   f      := f_eqv;         ENDCASE
    CASE s_neqv:  f      := f_xor;         ENDCASE

    CASE s_div:   f, sym := f_div,  FALSE; ENDCASE
    CASE s_rem:   f, sym := f_rem,  FALSE; ENDCASE
    CASE s_fdiv:  f, sym := f_fdiv, FALSE; ENDCASE
    CASE s_fsub:  f, sym := f_fsub, FALSE; ENDCASE

    CASE s_lshift:f, sym := f_lsh, FALSE;  ENDCASE
    CASE s_rshift:f, sym := f_rsh, FALSE;  ENDCASE
  }

  IF loadboth(arg2, arg1)=swapped & ~sym SWITCHON f INTO
  { DEFAULT:  ENDCASE
    CASE f_div: f := f_xdiv;            ENDCASE
    CASE f_rem: f := f_xrem;            ENDCASE
    CASE f_sub: f := f_xsub;            ENDCASE
    CASE f_fls: f := f_fgr;             ENDCASE
    CASE f_fle: f := f_fge;             ENDCASE
    CASE f_fgr: f := f_fls;             ENDCASE
    CASE f_fdiv:f := f_fxdiv;           ENDCASE 
    CASE f_fsub:f := f_fxsub;           ENDCASE

    CASE f_lsh:
    CASE f_rsh: genf(f_xch); xchinfo(); ENDCASE
  }

  genf(f)
  forget_a()
  IF f=f_lsh | f=f_rsh |
     f=f_fmul | f=f_div | f=f_xdiv |
     f=f_fadd | f=f_fsub | f=f_fxsub |
     f=f_feq | f=f_fne |
     f=f_fls | f=f_fgr |
     f=f_fle | f=f_fge DO forget_b()

  lose1(k_a, 0)
}

LET loada(x) BE
// Loada compiles code to evaluate SS item x into A
// The contents of B is left unchanged
{ LET k, n = h1!x, h2!x

  IF k=k_a RETURN

  // Dump A register if currently in use somewhere else.
  FOR t = arg1 TO tempv BY -3 IF h1!t=k_a DO { storet(t); BREAK }

  TEST inreg_a(k, n)
  THEN h1!x := k_a
  ELSE IF inreg_b(k, n) DO { genf(f_bta)
                             h1!x := k_a
                             btainfo()
                             RETURN
                           }

  SWITCHON h1!x & 15 INTO
  { DEFAULT:      cgerror("in loada %n", k)

    CASE k_a:     RETURN

    CASE k_numb:  TEST n>=0 THEN genfk(f_l,n)
                            ELSE genfk(f_lm,-n)
                  ENDCASE

    CASE k_loc:   genlp(n);                  ENDCASE
    CASE k_glob:  genfg(f_lg, n);            ENDCASE
    CASE k_lab:   genfl(f_ll, n);            ENDCASE
    CASE k_fnlab: genfl(f_lf, n);            ENDCASE

    CASE k_lvloc: genfp(f_llp, n);           ENDCASE

    CASE k_lvglob:genfg(f_llg, n);           ENDCASE
    CASE k_lvlab: genfl(f_lll, n);           ENDCASE
    CASE k_lstr:  genfm(f_lstr, n);          ENDCASE
    CASE k_lw:    genfm(f_lw, n);            ENDCASE
    CASE k_lock:  genfkp(f_lkp, n, h1!x>>4); ENDCASE
    CASE k_globk: genfkg(f_lkg, n, h1!x>>4); ENDCASE
  }

  // An instruction to load the A register has just been compiled.
  forget_a()
  addinfo_a(h1!x, h2!x)
  h1!x := k_a
}

AND loadboth(x, y) = VALOF
// Compiles code to cause
//   either    B := <x>  and  A := <y>
//             giving result NOTSWAPPED
//   or        B := <y>  and  A := <x>
//             giving result SWAPPED.
// loadboth only swaps if this generates less code.
{ // First ensure that no other stack item uses reg A.
  FOR t = tempv TO arg1 BY 3 DO
    IF h1!t=k_a UNLESS t=x | t=y DO storet(t)

  { LET xa, ya = inreg_a(h1!x, h2!x), inreg_a(h1!y, h2!y)
    AND xb, yb = inreg_b(h1!x, h2!x), inreg_b(h1!y, h2!y)

    IF xb & ya DO { h1!x, h1!y := k_b, k_a
                    RESULTIS notswapped
                  }
    IF xa & yb DO { h1!x, h1!y := k_a, k_b
                    RESULTIS swapped
                  }
    IF xa & ya DO { genf(f_atb);
                    atbinfo()
                    h1!x, h1!y := k_b, k_a
                    RESULTIS notswapped
                  }
    IF xb & yb DO { genf(f_bta)
                    btainfo()
                    h1!x, h1!y := k_b, k_a
                    RESULTIS notswapped
                  }
      
    IF xa DO { push(x, y)
               RESULTIS notswapped
             }
    IF ya DO { push(y, x)
               RESULTIS swapped
             }
    IF xb DO { h1!x := k_b; loada(y);  RESULTIS notswapped }
    IF yb DO { h1!y := k_b; loada(x);  RESULTIS swapped    }
      
    loada(x)
    push(x, y)
    RESULTIS notswapped
  }
}

AND push(a, x) BE // compile code for B := <a>; A := <x>
                  // assuming <a> is already in A
{ LET k, n = h1!x, h2!x

  SWITCHON h1!x INTO
  { DEFAULT:     genf(f_atb)
                 h1!a := k_b
                 atbinfo()
                 loada(x)
                 RETURN

    CASE k_loc:  genfp(f_atblp, n); ENDCASE
    CASE k_glob: genfg(f_atblg, n); ENDCASE
    CASE k_numb: genfk(f_atbl,  n); ENDCASE
  }

  atbinfo()
  forget_a()
  addinfo_a(k, n)
  h1!a, h1!x := k_b, k_a
} 

LET inreg_a(k, n) = VALOF
{ LET p = info_a
  IF k=k_a RESULTIS TRUE
  UNTIL p=0 DO { IF k=h2!p & n=h3!p RESULTIS TRUE
                 p := !p
               }
  RESULTIS FALSE
}

AND inreg_b(k, n) = VALOF
{ LET p = info_b
  IF k=k_b RESULTIS TRUE
  UNTIL p=0 DO { IF k=h2!p & n=h3!p RESULTIS TRUE
                 p := !p
               }
  RESULTIS FALSE
}

AND addinfo_a(k, n) BE info_a := getblk(info_a, k, n)

AND addinfo_b(k, n) BE info_b := getblk(info_b, k, n)

AND xchinfo() BE
{ LET t = info_a
  info_a := info_b
  info_b := t
}

AND atbinfo() BE
{ LET p = info_a
  forget_b()
  UNTIL p=0 DO { addinfo_b(h2!p, h3!p); p := !p }
}

AND btainfo() BE
{ LET p = info_b
  forget_a()
  UNTIL p=0 DO { addinfo_a(h2!p, h3!p); p := !p }
}

AND forget_a() BE { freeblks(info_a); info_a := 0 }

AND forget_b() BE { freeblks(info_b); info_b := 0 }

AND forgetall() BE { forget_a(); forget_b() }

// Forgetvar is called just after a simple variable (k, n) has been
// updated.  k is k_loc, k_glob or k_lab.  Note that register
// infomation about indirect local and global values
// must also be thrown away.
AND forgetvar(k, n) BE
{ LET p = info_a
  UNTIL p=0 DO { IF h2!p>=k_lock | h2!p=k & h3!p=n DO h2!p := k_none
                 p := !p
               }
  p := info_b
  UNTIL p=0 DO { IF h2!p>=k_lock | h2!p=k & h3!p=n DO h2!p := k_none
                 p := !p
               }
}

AND forgetallvars() BE  // Called after STIND or PUTBYTE.
{ LET p = info_a
  UNTIL p=0 DO { IF h2!p>=k_loc DO h2!p := k_none
                 p := !p
               }
  p := info_b
  UNTIL p=0 DO { IF h2!p>=k_loc DO h2!p := k_none
                 p := !p
               }
}

AND iszero(a) = h1!a=k_numb & h2!a=0 -> TRUE, FALSE

AND bits24(n) = -#xFFFFFF<=n<=#xFFFFFF -> TRUE, FALSE

// Store the value of a SS item in its true stack location.
AND storet(x) BE
{ LET s = h3!x
  IF h1!x=k_loc & h2!x=s RETURN
  loada(x)
  gensp(s)
  forgetvar(k_loc, s)
  addinfo_a(k_loc, s)
  h1!x, h2!x := k_loc, s
}

AND gensp(s) BE genfp(f_sp, s)

AND genlp(n) BE genfp(f_lp, n)

// Load an item (K,N) onto the SS. It may move SS items.
AND loadt(k, n) BE
{ cgpendingop()
  TEST arg1+3=tempt
  THEN { storet(tempv)  // SS stack overflow.
         FOR t = tempv TO arg2+2 DO t!0 := t!3
       }
  ELSE arg2, arg1 := arg2+3, arg1+3
  h1!arg1,h2!arg1,h3!arg1 := k,n,ssp
  ssp := ssp + 1
}

// Replace the top two SS items by (K,N) and set PENDINGOP=S_NONE.
AND lose1(k, n) BE
{ ssp := ssp - 1
  TEST arg2=tempv
  THEN { h1!arg2,h2!arg2 := k_loc,ssp-2
         h3!arg2 := ssp-2
       }
  ELSE { arg1 := arg2
         arg2 := arg2-3
       }
  h1!arg1, h2!arg1, h3!arg1 := k,n,ssp-1
  pendingop := s_none
}

AND swapargs() BE
{ LET k, n = h1!arg1, h2!arg1
  h1!arg1, h2!arg1 := h1!arg2, h2!arg2
  h1!arg2, h2!arg2 := k, n
}

AND cgstind() BE
{ LET t = VALOF
  { IF pendingop=s_add DO
    { IF k_numb=h1!arg2 DO swapargs()
      IF k_numb=h1!arg1 DO
      { LET n = h2!arg1
        IF 0<=n<=3 DO { stack(ssp-1)
                        pendingop := s_none
                        RESULTIS n
                      }
      }

      IF h1!arg2=k_loc & 3<=h2!arg2<=5 DO swapargs()
      IF h1!arg1=k_loc & 3<=h2!arg1<=5 DO
      { LET n = h2!arg1
        stack(ssp-1)
        pendingop := s_none
        RESULTIS n+1  // The codes for P3, P4 and P5.
      }

      UNLESS arg2=tempv DO
      { LET arg3 = arg2 - 3
        IF h1!arg3=k_a DO
        { IF h1!arg2=k_loc |
             h1!arg2=k_glob |
             h1!arg2=k_numb & bits24(h2!arg2) DO swapargs()
          IF h1!arg1=k_loc |
             h1!arg1=k_glob |
             h1!arg1=k_numb & bits24(h2!arg1) DO
          // Optimize the case  <arg2>!<arg1> := <arg3>
          // where <arg3> is already in A
          // and <arg1> is a local, a global or a number.
          { genf(f_atb)  // Put <arg3> into B
            h1!arg3 := k_b
            cgadd()     // Compiles an A, AP or AG instr.
            genf(f_st)
            stack(ssp-2)
            forgetallvars()
            RETURN
          }
        }
      }
    }

    cgpendingop()
    RESULTIS 0
  }

  // Now compile code for S!<arg1> := <arg2>
  // where           S is 0, 1, 2, 3, P3, P4 or P5
  // depending on    T =  0, 1, 2, 3,  4,  5 or  6

  { LET k, n = h1!arg1, h2!arg1
   
    IF k=k_glob & t=0 DO { loada(arg2)
                           genfkg(f_skg, 0, n)
                           stack(ssp-2)
                           forgetallvars()
                           RETURN
                         }

    IF k=k_loc & t<=3 DO { loada(arg2)
                           genfkp(f_stkp, t, n)
                           stack(ssp-2)
                           forgetallvars()
                           RETURN
                         }

    IF loadboth(arg2, arg1)=swapped DO
    { IF t=0 DO { genf(f_xst)
                  stack(ssp-2)
                  forgetallvars()
                  RETURN
                }
      genf(f_xch)
      xchinfo()
    }

    SWITCHON t INTO
    { DEFAULT:
      CASE 0: genf(f_st);        ENDCASE
      CASE 1:
      CASE 2:
      CASE 3: genfk(f_stk, t);   ENDCASE
      CASE 4:
      CASE 5:
      CASE 6: genfp(f_stp, t-1); ENDCASE
    }

    stack(ssp-2)
    forgetallvars()
  }
}


// Store the top item of the SS in (K,N).
AND storein(k, n) BE
// K is K_LOC, K_GLOB or K_LAB.
{ IF pendingop=s_sub & h1!arg1=k_numb DO
  { pendingop := s_add
    h2!arg1 := - h2!arg1
  }
  IF pendingop=s_add DO
  { IF h1!arg1=k & h2!arg1=n DO swapargs()
    IF h1!arg2=k & h2!arg2=n DO
    { // we have <arg2> := <arg2> + <arg1>
      // where <arg2> is local, global or static
      LET val = h2!arg1
      pendingop := s_none
      TEST h1!arg1=k_numb
      THEN SWITCHON k INTO
           { CASE k_loc:  genfkp(f_ikp, val, n); ENDCASE
             CASE k_glob: genfkg(f_ikg, val, n); ENDCASE
             CASE k_lab:  genfkl(f_ikl, val, n); ENDCASE
           }
       
      ELSE { loada(arg1)
             SWITCHON k INTO
             { CASE k_loc:  genfp(f_ip, n); ENDCASE
               CASE k_glob: genfg(f_ig, n); ENDCASE
               CASE k_lab:  genfl(f_il, n); ENDCASE
             }
           }
      forgetvar(k, n)
      forget_a()
      addinfo_a(k, n)
      stack(ssp-2)
      RETURN
    }
  }

  cgpendingop()
  loada(arg1)

  SWITCHON k INTO
  { DEFAULT:     cgerror("in storein %n", k)
    CASE k_loc:  gensp(n);        ENDCASE
    CASE k_glob: genfg(f_sg, n);  ENDCASE
    CASE k_lab:  genfl(f_sl, n);  ENDCASE
  }
  forgetvar(k, n)
  addinfo_a(k, n)
  stack(ssp-1)
}

LET cgrv() BE
{ IF pendingop=s_add DO
  { IF k_numb=h1!arg2 DO swapargs()
    IF k_numb=h1!arg1 DO
    { LET k = h2!arg1  // arg2 ! k
      stack(ssp-1)     // now arg1 ! k
      pendingop := s_none 

      IF h1!arg1=k_loc DO
      { LET n = h2!arg1  // Pn ! k
        h1!arg1, h2!arg1 := k_lock + (n<<4), k
        RETURN
      }

      IF h1!arg1=k_glob DO
      { LET n = h2!arg1  // Gn ! k
        h1!arg1, h2!arg1 := k_globk + (n<<4), k
        RETURN
      }

      loada(arg1)
      TEST k=0 THEN genf(f_rv)
               ELSE genfk(f_rvk, k)
      forget_a()
      h1!arg1, h2!arg1 := k_a, 0
      RETURN
    }

    IF k_loc=h1!arg2 DO swapargs()
    IF k_loc=h1!arg1 DO
    { LET n = h2!arg1
      loada(arg2)
      genfp(f_rvp, n)
      forget_a()
      lose1(k_a, 0)
      RETURN
    }

  }

  cgpendingop()

  IF h1!arg1=k_loc DO
  { LET n = h2!arg1  // ! Pn
    h1!arg1, h2!arg1 := k_lock + (n<<4), 0
    RETURN
  }

  IF h1!arg1=k_glob DO
  { LET n = h2!arg1  // ! Gn
    h1!arg1, h2!arg1 := k_globk + (n<<4), 0
    RETURN
  }

  loada(arg1)
  genf(f_rv)
  forget_a()
  h1!arg1, h2!arg1 := k_a, 0
}

AND cgadd() BE
// Compiles code to compute <arg2> + <arg1>.
// It does not look at PENDINGOP.

{ IF iszero(arg1) DO { stack(ssp-1); RETURN }

  IF iszero(arg2) DO
  { IF h2!arg1=ssp-1 &
       (h1!arg1=k_loc | (h1!arg1&15)=k_lock) DO loada(arg1)
    lose1(h1!arg1, h2!arg1)
    RETURN
  }

  TEST inreg_a(h1!arg1, h2!arg1)
  THEN loada(arg1)
  ELSE IF inreg_a(h1!arg2, h2!arg2) DO loada(arg2)

  IF h1!arg1=k_a DO swapargs()

  IF h1!arg2=k_loc DO swapargs()
  IF h1!arg1=k_loc DO { loada(arg2)
                        genfp(f_ap, h2!arg1)
                        forget_a()
                        lose1(k_a, 0)
                        RETURN
                      }

  IF h1!arg2=k_numb DO swapargs()
  IF h1!arg1=k_numb DO { loada(arg2)
                         cgaddk(h2!arg1)
                         lose1(k_a, 0)
                         RETURN
                       }

  IF h1!arg2=k_glob DO swapargs()
  IF h1!arg1=k_glob DO { loada(arg2)
                         genfg(f_ag, h2!arg1)
                         forget_a()
                         lose1(k_a, 0)
                         RETURN
                       }
  loadboth(arg2, arg1)
  genf(f_add)
  forget_a()
  lose1(k_a, 0)
}

AND cgaddk(k) BE UNLESS k=0 DO  // Compile code to add k to A.
{ TEST k>=0
  THEN genfk(f_a, k)
  ELSE genfk(f_s, -k)
  forget_a()
}

AND cgk2a(k) BE // Compile code to set k in A.
{ TEST k>=0
  THEN genfk(f_l, k)
  ELSE genfk(f_lm, -k)
  forget_a()
}

AND cgglobal(n) BE
{ cgstatics()
  incode := TRUE
  genf(f_global)
  genk(n)
  FOR i = 1 TO n DO { geng(rdgn()); genl(rdl()) }
  geng(maxgn)
}


AND cgentry(l, n) BE
{ LET v = VEC 255

  v%0 := n
  FOR i = 1 TO n DO v%i := rdn()

  IF debug>0 DO writef("// Entry to:   %s*n", v)

  incode := TRUE
  IF naming DO { genfk(f_entry,n)
                 FOR i = 1 TO n DO genc(v%i)
               }

  genfl(f_lab, l)
  forgetall()
}

// Function or routine call.
AND cgapply(op, k) BE
{ LET sa = k+3  // Stack address of first arg (if any).
  AND a1 = 0    // SS item for first arg if found.

  cgpendingop()

// Deal with non args.
  FOR t = tempv TO arg2 BY 3 DO { IF h3!t>=k BREAK
                                  IF h1!t=k_a DO storet(t)
                                }

// Deal with args 2, 3 ...
  FOR t = tempv TO arg2 BY 3 DO
  { LET s = h3!t
    IF s=sa DO
    { a1 := t  // We have found the SS item for the first arg.
      IF h1!t=k_a & t+3=arg2 DO
      // Two argument call with the first arg already in A.
      { genf(f_atb)
        atbinfo()
        h1!t := k_b
        storet(arg2)   // Store second arg (without detroying B).
        genf(f_xch)    // Restore first arg back to A.
        xchinfo()
        h1!t := k_a
        BREAK
      }
    }
    IF s>sa DO storet(t)
  }

  // Move first arg (if any) into A.
  IF sa<ssp-1 TEST a1=0
              THEN genlp(sa)  // First arg exists but not in SS.
              ELSE loada(a1)  // First arg exists in SS

  // First arg (if any) is now in A.

  TEST h1!arg1=k_glob
  THEN genfpg(f_kpg, k, h2!arg1)
  ELSE { IF sa<ssp-1 DO { genf(f_atb)
                          UNLESS a1=0 DO h1!a1 := k_b
                          atbinfo()
                        }
         // First arg (if any) is now in B
         loada(arg1)
         // The procedure entry address is now in A.
         genfp(f_k, k)
       }

  forgetall()
  stack(k)
  IF op=s_fnap DO loadt(k_a, 0)
}

// Used for OCODE operators JT and JF.
AND cgjump(b,l) BE
{ LET f = jmpfn(pendingop)
  IF f=0 DO { loadt(k_numb,0); f := f_jne }
  pendingop := s_none
  UNLESS b DO f := compjfn(f)
  store(0,ssp-3)
  genfl(prepj(f),l)
  stack(ssp-2)
}

AND jmpfn(op) = VALOF SWITCHON op INTO
{ DEFAULT:    RESULTIS 0
  CASE s_eq:  RESULTIS f_jeq
  CASE s_ne:  RESULTIS f_jne
  CASE s_ls:  RESULTIS f_jls
  CASE s_gr:  RESULTIS f_jgr
  CASE s_le:  RESULTIS f_jle
  CASE s_ge:  RESULTIS f_jge

  CASE s_feq: RESULTIS f_jfeq
  CASE s_fne: RESULTIS f_jfne
  CASE s_fls: RESULTIS f_jfls
  CASE s_fgr: RESULTIS f_jfgr
  CASE s_fle: RESULTIS f_jfle
  CASE s_fge: RESULTIS f_jfge
}

AND cgrelop(op) BE // For integer relational operators
{ LET f = ?

  IF iszero(arg1) DO
  { f := VALOF SWITCHON op INTO
         { DEFAULT:   RESULTIS 0
           CASE s_eq: RESULTIS f_eq0
           CASE s_ne: RESULTIS f_ne0
           CASE s_ls: RESULTIS f_ls0
           CASE s_gr: RESULTIS f_gr0
           CASE s_le: RESULTIS f_le0
           CASE s_ge: RESULTIS f_ge0
         }
    loada(arg2)
    lose1(k_a, 0)
    genf(f)
    forget_a()
    RETURN
  }

  IF iszero(arg2) DO
  { f := VALOF SWITCHON op INTO
         { DEFAULT:   RESULTIS 0
           CASE s_eq: RESULTIS f_eq0
           CASE s_ne: RESULTIS f_ne0
           CASE s_ls: RESULTIS f_gr0
           CASE s_gr: RESULTIS f_ls0
           CASE s_le: RESULTIS f_ge0
           CASE s_ge: RESULTIS f_le0
         }
    loada(arg1)
    lose1(k_a, 0)
    genf(f)
    forget_a()
    RETURN
  }
  
  TEST loadboth(arg2, arg1)=swapped
  THEN f := VALOF SWITCHON op INTO
            { DEFAULT:   RESULTIS 0
              CASE s_eq: RESULTIS f_eq
              CASE s_ne: RESULTIS f_ne
              CASE s_ls: RESULTIS f_gr
              CASE s_gr: RESULTIS f_ls
              CASE s_le: RESULTIS f_ge
              CASE s_ge: RESULTIS f_le
            }
  ELSE f := VALOF SWITCHON op INTO
            { DEFAULT:   RESULTIS 0
              CASE s_eq: RESULTIS f_eq
              CASE s_ne: RESULTIS f_ne
              CASE s_ls: RESULTIS f_ls
              CASE s_gr: RESULTIS f_gr
              CASE s_le: RESULTIS f_le
              CASE s_ge: RESULTIS f_ge
            }

  genf(f)
  lose1(k_a, 0)
  forget_a()
  RETURN
}

AND cgfrelop(op) BE // For floating point relational operators
{ LET f = ?

  IF iszero(arg1) DO // Note that 0.0 = #x00000000
                     // so iszero(arg1)=TRUE if arg1 represents 0.0
  { f := VALOF SWITCHON op INTO
         { DEFAULT:   RESULTIS 0
           CASE s_feq: RESULTIS f_feq0
           CASE s_fne: RESULTIS f_fne0
           CASE s_fls: RESULTIS f_fls0
           CASE s_fgr: RESULTIS f_fgr0
           CASE s_fle: RESULTIS f_fle0
           CASE s_fge: RESULTIS f_fge0
         }
    loada(arg2)
    lose1(k_a, 0)
    genf(f)
    forget_a()
    RETURN
  }

  IF iszero(arg2) DO // Note that 0.0 = #x00000000
                     // so iszero(arg1)=TRUE if arg1 represents 0.0
  { f := VALOF SWITCHON op INTO
         { DEFAULT:   RESULTIS 0
           CASE s_feq: RESULTIS f_feq0
           CASE s_fne: RESULTIS f_fne0
           CASE s_fls: RESULTIS f_fgr0
           CASE s_fgr: RESULTIS f_fls0
           CASE s_fle: RESULTIS f_fge0
           CASE s_fge: RESULTIS f_fle0
         }
    loada(arg1)
    lose1(k_a, 0)
    genf(f)
    forget_a()
    RETURN
  }
  
  TEST loadboth(arg2, arg1)=swapped
  THEN f := VALOF SWITCHON op INTO
            { DEFAULT:   RESULTIS 0
              CASE s_feq: RESULTIS f_feq
              CASE s_fne: RESULTIS f_fne
              CASE s_fls: RESULTIS f_fgr
              CASE s_fgr: RESULTIS f_fls
              CASE s_fle: RESULTIS f_fge
              CASE s_fge: RESULTIS f_fle
            }
  ELSE f := VALOF SWITCHON op INTO
            { DEFAULT:   RESULTIS 0
              CASE s_feq: RESULTIS f_feq
              CASE s_fne: RESULTIS f_fne
              CASE s_fls: RESULTIS f_fls
              CASE s_fgr: RESULTIS f_fgr
              CASE s_fle: RESULTIS f_fle
              CASE s_fge: RESULTIS f_fge
            }

  genf(f)
  lose1(k_a, 0)
  forget_a()
  RETURN
}

AND jfn0(f) = f+6 // Change F_JEQ  into F_JEQ0  etc...
                  // and    F_JFEQ into F_JFEQ0  etc...

AND revjfn(f) = f=f_jls -> f_jgr,
                f=f_jgr -> f_jls,
                f=f_jle -> f_jge,
                f=f_jge -> f_jle,
                f

AND compjfn(f) = f=f_jeq  -> f_jne,
                 f=f_jne  -> f_jeq,
                 f=f_jls  -> f_jge,
                 f=f_jge  -> f_jls,
                 f=f_jgr  -> f_jle,
                 f=f_jle  -> f_jgr,

                 f=f_jfeq -> f_jfne,
                 f=f_jfne -> f_jfeq,
                 f=f_jfls -> f_jfge,
                 f=f_jfge -> f_jfls,
                 f=f_jfgr -> f_jfle,
                 f=f_jfle -> f_jfgr,
                 f

AND prepj(f) = VALOF  // Returns the appropriate m/c fn.
                      // It works for both integer and
                      // floating point relations.
{ IF iszero(arg2) DO { swapargs(); f := revjfn(f) }
  IF iszero(arg1) DO { loada(arg2); RESULTIS jfn0(f) }
  IF loadboth(arg2, arg1)=swapped RESULTIS revjfn(f)
  RESULTIS f
}

// Compiles code for SWITCHON.
LET cgswitch() BE
{ // The switch expression value is on top of the stack
  LET n = rdn()     // Number of cases.
  LET dlab = rdl()  // Default label.

  // Read and sort (K,L) pairs sorting them into increasing k order.
  FOR i = 1 TO n DO
  { LET k = rdn()
    LET l = rdl()
    LET j = i-1
    UNTIL j=0 DO  { IF k > casek!j BREAK
                    casek!(j+1), casel!(j+1) := casek!j, casel!j
                    j := j - 1
                  }
    casek!(j+1), casel!(j+1) := k, l
  }

  cgpendingop()
  store(0, ssp-2)
  loada(arg1)      // A := switch value
  stack(ssp-1)

  // If there are no cases, so jump the default label
  IF n=0 DO { genfl(f_j, dlab); RETURN }

  //genf(f_res) // Ensure the switch value is in A
  switcht(1, n, dlab, FALSE)
}

AND prcases(p, q) BE
{ writef("*nprcases: p=%n q=%n*n", p, q)
  FOR i = p TO q DO
  { IF (i-p) MOD 8 = 0 DO newline()
    writef(" %11i", casek!i)
  }
  newline()
}

AND switcht(p, q, dlab, inb) BE
{ // If inb=TRUE,  the switch value is in B
  // If inb=FALSE, the switch value is in A.
  // Compile code for cases in the region region p to q
  // and default label dlab.
  LET n = q-p+1    // Number of cases in region p..q
  LET r = (p+q)/2 + 1 // Only used if n>=4
  LET s = r

  IF n<4 DO
  { // There are less than 4 cases so use equality tests.
    // Set B = switch value
    UNLESS n=0 UNLESS inb DO genf(f_atb)
    FOR i = p TO q DO
    { cgk2a(casek!i)
      genfl(f_jeq, casel!i)
    }
    genfl(f_j, dlab)
    forgetall()
    RETURN
  }

  // There are at least four cases in region p .. q

//writef("switcht: p=%n q=%n casek!p=%n, casek!q=%n, diff=%n*n",
//                 p,   q,   casek!p,    casek!q,    casek!q-casek!p)
//prcases(p, q)
//abort(1002)

  // Find the middle segment
  WHILE p<r & 0 <= casek!s-casek!(r-1) <= #xFFFF DO r := r-1
  WHILE s<q & 0 <= casek!(s+1)-casek!r <= #xFFFF DO s := s+1

  // r..s is a region of case constants including the mid point
  // of region p..q, and for which
  // 0 <= casek!i - casek!r <= #xFFFF for all i in r..s

//writef("switcht: r=%n s=%n*n",r,s)
//abort(1000)
/*
  IF n<=3 IF p<r | s<q  DO
  { // Use a sequence of equality tests.
    UNLESS inb DO genf(f_atb)
    FOR i = p TO q DO
    { cgk2a(casek!i)
      genfl(f_jeq, casel!i) // Leaves values in A and B unchanged
    }
    genfl(f_j, dlab)
    forgetall()
    RETURN
  }
*/
  IF p<r DO
  { // At least one case in LH region p .. r-1
    // Set B = switch value and A = the case constant
    LET lab = newlab()
    UNLESS inb DO genf(f_atb)
    cgk2a(casek!r)
    genf(f_res)
    genfl(f_jge, lab) // J if switch value not in LH region
    switcht(p, r-1, dlab, TRUE)
    genfl(f_lab, lab)
    genf(f_ldres)  // B = switch value, A = casek!r but not used
    switcht(r, q,   dlab, TRUE)
    RETURN
  }

  IF s<q DO
  { // At least one case in RH region s+1 .. q
    // Set B = switch value and A = casek!s
    LET lab = newlab()
    UNLESS inb DO genf(f_atb)
    cgk2a(casek!s)
    genf(f_res)
    genfl(f_jgr, lab)
    switcht(p,   s, dlab, TRUE)
    genfl(f_lab, lab)
    genf(f_ldres)  // B = switch value, A = casek!r but not used
    switcht(s+1, q, dlab, TRUE)
    RETURN
  }

  IF inb DO genf(f_xch) // Put B back in A, if necessary.
  switchseg(r, s, dlab)
  forgetall()
}

AND offsetcases(p, q, offset) BE IF offset DO
{ // Subtract offset from all case constants in the region p to q

//writef("offsetcases p=%n q=%n offset=%n*n", p, q, offset)
//prcases(p, q)
   
  FOR i = p TO q  DO casek!i := casek!i - offset
}

AND switchseg(p, q, dlab) BE
{ // Only called
  // when  0 <= casek!i - casek!p <= #xFFFF for all i in p..q
  // and   p <= q
  // and A holds the switch value
  LET n = q-p+1  // The number of cases (>=1).

//writef("switchseg: n=%n casek!p=%n casek!q=%n*n", n, casek!p, casek!q)
//prcases(p, q)
//abort(1001)

  TEST 2*n < casek!q - casek!p  // Which is generates less code?
  THEN switchb(p, q, dlab)      // Binary chop switch.
  ELSE switchl(p, q, dlab)      // Label vector switch.
}

AND switchb(p, q, dlab) BE  // Binary chop switch.
{ // Only called when  0 <= casek!q - casek!p <= #xFFFF
  //              and  p < q
  // and A holds the switch value
  LET n = q-p+1   // Number of cases (>1).
  LET n1 = n>7 ->n, 7
   
//writef("switchb: n=%n casek!p=%n casek!p=%n*n", n, casek!p, casek!q)
//prcases(p, q)
//abort(1000)
  // Ensure that all case constants can be represented by
  // unsigned 16 bit integers.
  IF casek!p<0 | casek!q>#xFFFF DO
  { cgaddk(-casek!p)
    offsetcases(p, q, casek!p)
  }
   
  genf(f_swb)
  genk(n)
  genl(dlab)
  FOR i = p TO q DO { LET pos = q + 1 - findpos(i-p+1, q-p+1)
                      genk(casek!pos)
                      genl(casel!pos)
                    }
}

// If the integers 1..n were stored in a balanced binary
// tree using the tree structure of heap sort, then
// integer i would be at position findpos(i, n).
AND findpos(i, n) = VALOF
{ LET r = ?
  IF i = 1 DO { swlpos, swrpos := 0, n
                RESULTIS rootpos(0, n)
              }
  r := findpos(i/2, n)
  TEST (i&1) = 0 THEN swrpos := r-1
                 ELSE swlpos := r
  RESULTIS rootpos(swlpos, swrpos)
}

AND rootpos(p, q) = VALOF
{ LET n = q-p
  LET s, r = 2, ?
  UNTIL s>n DO s := s+s
  s := s/2
  r := n-s+1
  IF s <= r+r RESULTIS p + s
  RESULTIS p + s/2 + r
}

AND switchl(p, q, dlab) BE  // Label vector switch.
{ // Only called when  0 <= casek!q - casek!p <= #xFFFF
  //              and  p < q
  // and A holds the switch value

  LET n, t = ?, p

  // Adjust case constants to suit SWL instruction.
  IF casek!p<0 | casek!p>1 | casek!q>#xFFFF DO
  { cgaddk(-casek!p)
    offsetcases(p, q, casek!p)
  }
   
  n := casek!q + 1   // Number of entries in the label vector.
  genf(f_swl)
  genk(n)
  genl(dlab)        // Default label.

  FOR k = 0 TO casek!q TEST casek!t=k
                       THEN { genl(casel!t)
                              t := t+1
                            }
                       ELSE genl(dlab)
}

AND cgstring(n) BE
{ LET l, a = newlab(), n
  loadt(k_lstr, l)
  { LET b, c, d = 0, 0, 0
    IF n>0 DO b := rdn()
    IF n>1 DO c := rdn()
    IF n>2 DO d := rdn()
    !sliste := getblk(0,l,((d<<8|c)<<8|b)<<8|a)
    sliste := !sliste
    l := 0
    IF n<=3 BREAK
    n, a := n-4, rdn()
  } REPEAT
}

AND cgstatics() BE
{ incode := TRUE

  UNTIL clist=0 DO  // List of 24-32 bit constants
  { LET blk = clist
    clist := !clist
    genfmw(f_const, h2!blk, h3!blk)
    freeblk(blk)
  }
  cliste := @clist

  UNTIL tlist=0 DO  // Static variables and tables
  { LET len, nl = 0, tlist
    len, nl := len+1, !nl REPEATUNTIL nl=0 | h2!nl ~= 0

    genflk(f_static, h2!tlist, len)  // tlist always starts labelled.

    FOR i = 1 TO len DO
    { LET blk = tlist
      tlist := !tlist
      freeblk(blk)
      genw(h3!blk)
    }
  }
  tliste := @tlist

  UNTIL slist=0 DO  // String constants
  { LET n = h3!slist & 255
    LET lenbyte = TRUE
    genfm(f_string, h2!slist)  // SLIST always starts labelled.

    { LET blk = slist
      LET w = h3!blk
      slist := !slist
      TEST lenbyte THEN { genk(w & 255); lenbyte := FALSE }
                   ELSE    genc(w & 255)
      IF n>=1 DO genc(w>>8  & 255)
      IF n>=2 DO genc(w>>16 & 255)
      IF n>=3 DO genc(w>>24 & 255)
      n := n-4
      freeblk(blk)
    } REPEATUNTIL slist=0 | h2!slist ~= 0
  }
  sliste := @slist
  incode := FALSE
}



AND getblk(a, b, c) = VALOF
{ LET p = freelist
  TEST p=0 THEN { dp := dp-3; checkspace(); p := dp }
           ELSE freelist := !p
  h1!p, h2!p, h3!p := a, b, c
  RESULTIS p
}


AND freeblk(p) BE { !p := freelist; freelist := p }

AND freeblks(p) BE UNLESS p=0 DO
{ LET oldfreelist = freelist
  freelist := p
  UNTIL !p=0 DO p := !p
  !p := oldfreelist
}


AND initdatalists() BE
{ tlist,   tliste   := 0, @tlist
  slist,   sliste   := 0, @slist
  clist,   cliste   := 0, @clist
  freelist := 0
}

LET codef(x) BE
{ progsize := progsize + 1
  codelayout := 0
  writef("*nF%n", x)
}

LET wrarg(form, x) BE
{ codelayout := codelayout+1
  IF codelayout MOD 10 = 0 DO newline()
  writef(form, x)
}

LET codep(x) BE wrarg(" P%n", x)

LET codeg(x) BE wrarg(" G%n", x)

LET codek(x) BE wrarg(" K%n", x)

LET codew(x) BE wrarg(" W%n", x)

LET codec(x) BE wrarg(" C%n", x)

LET codel(x) BE wrarg(" L%n", x)

LET codem(x) BE wrarg(" M%n", x)


LET genfp(f, a) BE IF incode DO
{ IF debug>0 DO wrcode(f, a)
  codef(f)
  codep(a)
}

LET genfkp(f, k, a) BE IF incode DO
{ IF debug>0 DO wrcode(f, k, a)
  codef(f)
  codek(k)
  codep(a)
}

LET genfkp(f, k, a) BE IF incode DO
{ IF debug>0 DO wrcode(f, k, a)
  codef(f)
  codek(k)
  codep(a)
}

LET genfg(f, n) BE IF incode DO 
{  IF debug>0 DO wrcode(f, n)
   codef(f)
   codeg(n)
}

LET genfkg(f, k, n) BE IF incode DO 
{  IF debug>0 DO wrcode(f, k, n)
   codef(f)
   codek(k)
   codeg(n)
}

LET genfpg(f, p, n) BE IF incode DO 
{ IF debug>0 DO wrcode(f, p, n)
   codef(f)
   codep(p)
   codeg(n)
}

LET genfk(f, a) BE IF incode DO
{ IF debug>0 DO wrcode(f, a)
  codef(f)
  codek(a)
}

LET genfkl(f, a, l) BE IF incode DO
{ IF debug>0 DO wrcode(f, a, l)
  codef(f)
  codek(a)
  codel(l)
}

LET genfw(f, w) BE IF incode DO
{ IF debug>0 DO wrcode(f, w)
  codef(f)
  codew(w)
}

LET genfl(f, n) BE IF incode DO
{ IF debug>0 DO wrcode(f, n)
  codef(f)
  codel(n)
}

LET genflk(f, n, k) BE IF incode DO
{ IF debug>0 DO wrcode(f, n, k)
  codef(f)
  codel(n)
  codek(k)
}

LET genfm(f, n) BE IF incode DO
{ IF debug>0 DO wrcode(f, n)
  codef(f)
  codem(n)
}

LET genfmw(f, n, w) BE IF incode DO
{ IF debug>0 DO wrcode(f, n, w)
  codef(f)
  codem(n)
  codew(w)
}

LET genf(f) BE IF incode DO
{ IF debug>0 DO wrcode(f)
  codef(f)
}

LET geng(n) BE IF incode DO
{ 
  codeg(n)
}

LET genc(c) BE IF incode DO
{ 
  codec(c)
}

LET genk(k) BE IF incode DO
{ 
  codek(k)
}

LET genw(w) BE IF incode DO
{ 
  codew(w)
}

LET genl(lab) BE IF incode DO
{ 
  codel(lab)
}

AND checkspace() BE IF dp<dpbase DO
{ cgerror("Program too large")
  errcount := errcount+1
  longjump(fin_p, fin_l)
}

AND dboutput() BE
{ LET p = info_a
  writes("A=(")
  UNTIL p=0 DO { wrkn(h2!p, h3!p)
                 p := !p
                 UNLESS p=0 DO wrch('*s')
               }
    
  p := info_b
  writes(") B=(")
  UNTIL p=0 DO { wrkn(h2!p, h3!p)
                 p := !p
                 UNLESS p=0 DO wrch('*s')
               }
  wrch(')')
   
  IF debug=2 DO { writes("  STK: ")
                  FOR p=tempv TO arg1 BY 3  DO
                  { IF (p-tempv) REM 30 = 10 DO newline()
                    wrkn(h1!p,h2!p)
                    wrch('*s')
                  }
                }
   
  newline()
}


AND wrkn(k,n) BE
{ LET s = VALOF SWITCHON k INTO
  { DEFAULT:       k := n
                   RESULTIS "?"
    CASE k_none:   RESULTIS "-"
    CASE k_numb:   RESULTIS "N%n"
    CASE k_fnlab:  RESULTIS "F%n"
    CASE k_lvloc:  RESULTIS "@P%n"
    CASE k_lvglob: RESULTIS "@G%n"
    CASE k_lvlab:  RESULTIS "@L%n"
    CASE k_lstr:   RESULTIS "S%n"
    CASE k_lw:     RESULTIS "W%n"
    CASE k_a:      RESULTIS "A"
    CASE k_b:      RESULTIS "B"
    CASE k_c:      RESULTIS "C"
    CASE k_loc:    RESULTIS "P%n"
    CASE k_glob:   RESULTIS "G%n"
    CASE k_lab:    RESULTIS "L%n"
    CASE k_lock:   RESULTIS "%nP%n"
    CASE k_globk:  RESULTIS "%nG%n"
  }
  writef(s, n, k>>4)
}

AND wrcode(f, a, b) BE
{ LET form = VALOF SWITCHON f INTO
  { DEFAULT:       RESULTIS "-"

    CASE f_lp:     RESULTIS "LP    P%n"
    CASE f_lg:     RESULTIS "LG    G%n"
    CASE f_ll:     RESULTIS "LL    L%n"

    CASE f_llp:    RESULTIS "LLP   P%n"
    CASE f_llg:    RESULTIS "LLG   G%n"
    CASE f_lll:    RESULTIS "LLL   L%n"
    CASE f_lf:     RESULTIS "LF    L%n"
    CASE f_lw:     RESULTIS "LW    M%n"

    CASE f_l:      RESULTIS "L     K%n"
    CASE f_lm:     RESULTIS "LM    K%n"

    CASE f_sp:     RESULTIS "SP    P%n"
    CASE f_sg:     RESULTIS "SG    G%n"
    CASE f_sl:     RESULTIS "SL    L%n"

    CASE f_ap:     RESULTIS "AP    P%n"
    CASE f_ag:     RESULTIS "AG    G%n"
    CASE f_a:      RESULTIS "A     K%n"
    CASE f_s:      RESULTIS "S     K%n"

    CASE f_lkp:    RESULTIS "LKP   K%n P%n"
    CASE f_lkg:    RESULTIS "LKG   K%n P%n"
    CASE f_rv:     RESULTIS "RV"
    CASE f_rvp:    RESULTIS "RVP   P%n"
    CASE f_rvk:    RESULTIS "RVK   K%n"
    CASE f_st:     RESULTIS "ST"
    CASE f_stp:    RESULTIS "STP   P%n"
    CASE f_stk:    RESULTIS "STK   K%n"
    CASE f_stkp:   RESULTIS "STKP  K%n P%n"
    CASE f_skg:    RESULTIS "SKG   K%n G%n"
    CASE f_xst:    RESULTIS "XST"

    CASE f_k:      RESULTIS "K     P%n"
    CASE f_kpg:    RESULTIS "KPG   P%n G%n"

    CASE f_neg:    RESULTIS "NEG"
    CASE f_not:    RESULTIS "NOT"
    CASE f_abs:    RESULTIS "ABS"

    CASE f_xdiv:   RESULTIS "XDIV"
    CASE f_xrem:   RESULTIS "XREM"
    CASE f_xsub:   RESULTIS "XSUB"

    CASE f_mul:    RESULTIS "MUL"
    CASE f_div:    RESULTIS "DIV"
    CASE f_rem:    RESULTIS "REM"
    CASE f_res:    RESULTIS "RES"
    CASE f_add:    RESULTIS "ADD"
    CASE f_sub:    RESULTIS "SUB"

    CASE f_eq:     RESULTIS "EQ"
    CASE f_ne:     RESULTIS "NE"
    CASE f_ls:     RESULTIS "LS"
    CASE f_gr:     RESULTIS "GR"
    CASE f_le:     RESULTIS "LE"
    CASE f_ge:     RESULTIS "GE"
    CASE f_eq0:    RESULTIS "EQ0"
    CASE f_ne0:    RESULTIS "NE0"
    CASE f_ls0:    RESULTIS "LS0"
    CASE f_gr0:    RESULTIS "GR0"
    CASE f_le0:    RESULTIS "LE0"
    CASE f_ge0:    RESULTIS "GE0"

    CASE f_lsh:    RESULTIS "LSH"
    CASE f_rsh:    RESULTIS "RSH"
    CASE f_and:    RESULTIS "AND"
    CASE f_or:     RESULTIS "OR"
    CASE f_xor:    RESULTIS "XOR"
    CASE f_eqv:    RESULTIS "EQV"

    CASE f_gbyt:   RESULTIS "GBYT"
    CASE f_xgbyt:  RESULTIS "XGBYT"
    CASE f_pbyt:   RESULTIS "PBYT"
    CASE f_xpbyt:  RESULTIS "XPBYT"

    CASE f_swb:    RESULTIS "SWB"
    CASE f_swl:    RESULTIS "SWL"

    CASE f_xch:    RESULTIS "XCH"
    CASE f_atb:    RESULTIS "ATB"
    CASE f_atc:    RESULTIS "ATC"
    CASE f_bta:    RESULTIS "BTA"
    CASE f_btc:    RESULTIS "BTC"
    CASE f_atblp:  RESULTIS "ATBLP P%n"
    CASE f_atblg:  RESULTIS "ATBLG G%n"
    CASE f_atbl:   RESULTIS "ATBL  K%n"

    CASE f_j:      RESULTIS "J     L%n"
    CASE f_rtn:    RESULTIS "RTN"
    CASE f_goto:   RESULTIS "GOTO"

    CASE f_ikp:    RESULTIS "IKP   K%n P%n"
    CASE f_ikg:    RESULTIS "IKG   K%n G%n"
    CASE f_ikl:    RESULTIS "IKL   K%n L%n"
    CASE f_ip:     RESULTIS "IP    P%n"
    CASE f_ig:     RESULTIS "IG    G%n"
    CASE f_il:     RESULTIS "IL    L%n"

    CASE f_jeq:    RESULTIS "JEQ   L%n"
    CASE f_jne:    RESULTIS "JNE   L%n"
    CASE f_jls:    RESULTIS "JLS   L%n"
    CASE f_jgr:    RESULTIS "JGR   L%n"
    CASE f_jle:    RESULTIS "JLE   L%n"
    CASE f_jge:    RESULTIS "JGE   L%n"
    CASE f_jeq0:   RESULTIS "JEQ0  L%n"
    CASE f_jne0:   RESULTIS "JNE0  L%n"
    CASE f_jls0:   RESULTIS "JLS0  L%n"
    CASE f_jgr0:   RESULTIS "JGR0  L%n"
    CASE f_jle0:   RESULTIS "JLE0  L%n"
    CASE f_jge0:   RESULTIS "JGE0  L%n"
    CASE f_jge0m:  RESULTIS "JGE0M M%n"

    CASE f_brk:    RESULTIS "BRK"
    CASE f_nop:    RESULTIS "NOP"
    CASE f_chgco:  RESULTIS "CHGCO"
    CASE f_mdiv:   RESULTIS "MDIV"
    CASE f_sys:    RESULTIS "SYS"

    CASE f_section:  RESULTIS "SECTION"
    CASE f_modstart: RESULTIS "MODSTART"
    CASE f_modend:   RESULTIS "MODEND"
    CASE f_global:   RESULTIS "GLOBAL"
    CASE f_string:   RESULTIS "STRING"
    CASE f_const:    RESULTIS "CONST"
    CASE f_static:   RESULTIS "STATIC"
    CASE f_mlab:     RESULTIS "MLAB  M%n"
    CASE f_lab:      RESULTIS "LAB   L%n"
    CASE f_lstr:     RESULTIS "LSTR"
    CASE f_entry:    RESULTIS "ENTRY"

    CASE f_float:    RESULTIS "FLOAT"
    CASE f_fix:      RESULTIS "FIX"
    CASE f_fabs:     RESULTIS "FABS"
    CASE f_fmul:     RESULTIS "FMUL"
    CASE f_fdiv:     RESULTIS "FDIV"
    CASE f_fadd:     RESULTIS "FADD"
    CASE f_fsub:     RESULTIS "FSUB"
    CASE f_fneg:     RESULTIS "FNEG"

    CASE f_feq:      RESULTIS "FEQ"
    CASE f_fne:      RESULTIS "FNE"
    CASE f_fls:      RESULTIS "FLS"
    CASE f_fgr:      RESULTIS "FGR"
    CASE f_fle:      RESULTIS "FLE"
    CASE f_fge:      RESULTIS "FGE"
  }

  IF debug=2 DO dboutput()
  writes("*n        ")
  writef(form, a, b)
//  newline()
}







