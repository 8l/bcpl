// This is the BCPL 32/64 bit OCODE to Cintcode codegenerator.

// Implemented by Martin Richards (c) 12 May 2013

/* Change history

06/08/14
Modified to include floating point constants and the operators
#* #/ ~+ #- #= #~= #< #> #<= and #>=.

15/05/13
Modified to use c64 and t64 that specify the BCPL word length of
the compiler and target machines, respectively.

10/05/13
Major change to the compilation of SWITCHON to stop the compiler
crashing when given CASE minint:. See function switcht.

10/07/09
Separated the compiler into bcplfe.b and codegenerators
bcplcgcin.b and bcplcgsial.b and added the interface
header g/bcplfecg.h

07/09/06
This is a version of the BCPL compiler that generates 64-cintcode.  It
is designed to run on both 32- and 64-bit systems. The options t32 and
t64 specify the bit length of the BCPL word in the target system. The
default is the same as the current system.  On 64-bit systems
numerical constants are compiles to full precision, but on 32-bit
systems they are truncated to 32 bits then sign extended to 64
bits. 64-bit Cintcode has one new instruction (MW) that modifies the
operand of the next W type instruction (KW, LLPW, LW, LPW, SPW, APW
and AW). It does this by setting the senior 32-bits of the new 64-bit
MW register. This is added to the operand of any W type instruction
and is cleared after use.

18/01/06
Based on Dave Lewis's suggestion,
in outputsection(), add:
   IF objline1%0 DO writef("%s*n", objline1)
where objline1 is the first line of file objline1 if it can be found
in the current directory or in the HDRS directory. This will typically
put a line such as:
#!/usr/local/bin/cintsys -c
as the first line of the compiled object module. This line is ignored
by the CLI but may be useful under Linux. If objline1 cannot be found
no such line is inserted at the start of the object module.

07/01/06
Initial version of the 64-bit codegenerator

26/2/99
Added BIN option to the compiler to generate a binary (rather than
hex) hunk format for the compiled code. This is primarily for the
Windows CE version of the cintcode system where compactness is
particularly important. There is a related change to loadseg in
cintmain.c

24/12/95
Improved the efficiency of outputsection in CG by introducing
wrhex2 and wrword_at.

24/7/95
Removed bug in atbinfo, define addinfo_b change some global numbers.
Implement constant folding in TRN.

22/6/93
Reverse order in SWB and have a minimum of 7 cases
to allow faster interpreter.

2/6/93
Changed code for SWB to use heap-like binary tree.

19/5/93
Put in code to compile BTC and XPBYT instructions.

23/4/93
Allowed the codegenerator to compiler the S instruction.

21/12/92
Cured bug in compilation of (b -> f, g)(1,2,3)

24/11/92 
Cured bug in compilation of a, b := s%0 > 0, s%1 = '!'

23/7/92:
Renamed nextlab as newlab, load as loadval in the CG.
Put back simpler hashing function in lookupword.
Removed rdargs fudge.
Removed S2 compiler option.
Cured bug concerning the closing of gostream when equal to stdout.
*/

SECTION "BCPLCGCIN"

// If c64 is FALSE, we are running an a 32-bit system
// If c64 is TRUE,  we are running an a 64-bit system

// If t64 is FALSE, it generates 32-bit Cintcode.
// If t64 is TRUE,  it generates 64-bit Cintcode.
// If neither are set is generates code compatible with the currently
// running system.

GET "libhdr"
GET "bcplfecg"

GLOBAL {
// Global procedures.
cgsects: cgg
rdname
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
loadval
loadba
setba

genxch
genatb
loada
push
loadboth
inreg_a
inreg_b
addinfo_a
addinfo_b
pushinfo
xchinfo
atbinfo

forget_a
forget_b
forgetall
forgetvar
forgetallvars

iszero
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
setlab
cgstatics
getblk
freeblk
freeblks

initdatalists

geng
gen
genb
genbb
genflt
genfb
genfbb
genr
genh
genw
checkspace
codeb
code2b
code4b
pack4b
codeh
codew
coder

getw
puth
putw
align
chkrefs
dealwithrefs
genindword
inrange_d
inrange_i
fillref_d
fillref_i
relref

outputsection
wrword
wrhex2
wrword_at
dboutput
wrkn
wrcode
wrfcode
sopname

// Global variables.
arg1
arg2

ssp

tempt
tempv
stv
stvp

ch

dp
freelist

incode
labv

casek
casel

maxgn
maxlab
maxssp

op
labnumber
pendingop
procdepth

progsize

info_a
info_b
reflist
refliste
rlist
rliste
nlist
nliste
skiplab

codestr
blkupb            // =3 if bytesperword=4 and t64=TRUE
                  // =2 otherwise.
}

MANIFEST
{
// Value descriptors.
k_none=0; k_numb=1; k_fnlab=2
k_lvloc=3; k_lvglob=4; k_lvlab=5
k_a=6; k_b=7; k_c=8
k_loc=9; k_glob=10; k_lab=11; 
k_loc0=12; k_loc1=13; k_loc2=14; k_loc3=15; k_loc4=16
k_glob0=17; k_glob1=18; k_glob2=19

swapped=TRUE; notswapped=FALSE

// Global routine numbers.
gn_stop=2
}

// CINTCODE op codes.
MANIFEST {
f_k0   =   0
f_fltop=   1  // Added 20/07/10
f_lf   =  12
f_lm   =  14
f_lm1  =  15
f_l0   =  16
f_fhop =  27
f_jeq  =  28
f_jeq0 =  30

f_k    =  32
f_kh   =  33
f_kw   =  34
f_k0g  =  32
f_s0g  =  44
f_l0g  =  45
f_l1g  =  46
f_l2g  =  47
f_lg   =  48
f_sg   =  49
f_llg  =  50
f_ag   =  51
f_mul  =  52
f_div  =  53
f_rem  =  54
f_xor  =  55
f_sl   =  56
f_ll   =  58
f_jne  =  60
f_jne0 =  62

f_llp  =  64
f_llph =  65
f_llpw =  66
f_add  =  84
f_sub  =  85
f_lsh  =  86
f_rsh  =  87
f_and  =  88
f_or   =  89
f_lll  =  90
f_jls  =  92
f_jls0 =  94

f_l    =  96
f_lh   =  97
f_lw   =  98
f_rv   = 116
f_rtn  = 123
f_jgr  = 124
f_jgr0 = 126

f_lp   = 128
f_lph  = 129
f_lpw  = 130
f_lp0  = 128
f_swb  = 146
f_swl  = 147
f_st   = 148
f_st0  = 148
f_goto = 155
f_jle  = 156
f_jle0 = 158

f_sp   = 160
f_sph  = 161
f_spw  = 162
f_sp0  = 160
f_s0   = 176
f_xch  = 181
f_gbyt = 182
f_pbyt = 183
f_atc  = 184
f_atb  = 185
f_j    = 186
f_jge  = 188
f_jge0 = 190

f_ap   = 192
f_aph  = 193
f_apw  = 194
f_ap0  = 192
f_xpbyt= 205
f_lmh  = 206
f_btc  = 207
f_nop  = 208
f_a0   = 208
f_rvp0 = 211
f_st0p0= 216
f_st1p0= 218
f_mw   = 223

f_a    = 224
f_ah   = 225
f_aw   = 226
f_l0p0 = 224
f_s    = 237
f_sh   = 238
f_mdiv = 239
f_chgco= 240
f_neg  = 241
f_not  = 242
f_l1p0 = 240
f_l2p0 = 244
f_l3p0 = 247
f_l4p0 = 249
f_selld= 254  // Added 20/07/10
f_selst= 255  // Added 20/07/10
}

LET codegenerate(workspace, workspacesize) BE
{ //writef("%n-bit system generating %n-bit code*n", (c64->64,32), (t64->64,32))

  IF workspacesize<2000 DO { cgerror("Too little workspace")
                             errcount := errcount+1
                             longjump(fin_p, fin_l)
                           }

  progsize := 0

  op := rdn()

  cgsects(workspace, workspacesize)
  writef("Code size = %i5 bytes of %n-bit %s ender Cintcode*n",
         progsize, (t64->64,32), (bigender->"big","little"))
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
  labv := p
  dp := workvec+vecsize
  labnumber := (dp-p)/10+10
  p := p+labnumber
  FOR lp = labv TO p-1 DO !lp := -1
  stv := p
  stvp := 0
  incode := FALSE
  maxgn := 0
  maxlab := 0
  maxssp := 0
  procdepth := 0
  info_a, info_b := 0, 0

  TEST t64 & ~c64
  THEN blkupb := 3 // t64 set but running on a 32-bit implementation
  ELSE blkupb := 2 // otherwise.

  initstack(3)
  initdatalists()

  codew(0, 0)  // For size of module.
  IF op=s_section DO
  { MANIFEST { upb=11 } // Max length of entry name
    LET n = rdn()
    LET v = VEC upb/bytesperword
    v%0 := upb
    rdname(n, v) // Pack up to 11 character of the name into v

    IF naming DO
    { TEST c64
      THEN codew(  sectword>>32,  sectword)
      ELSE codew(-(sectword>>31), sectword) // Sign extend
      codestr(v)
    }

    op := rdn()
  }

  scan()
  op := rdn()
  putw(0, stvp/wordbytelen)  // Plant the word size of the module.
  outputsection()
  progsize := progsize + stvp
}

AND rdname(n, v) BE
{ // Pack up to 11 character of the name into v including
  // the first and last five.
  TEST n<=11
  THEN { FOR i = 1 TO n DO v%i := rdn()
         FOR i = n+1 TO 11 DO v%i := '*s'
       }
  ELSE { FOR i = 1 TO 5   DO v%i := rdn()
         FOR i = 6 TO n-6 DO rdn() // Ignore the middle characters
         FOR i = 6 TO 11  DO v%i := rdn()
         IF n>11 DO v%6 := '*''
       }
}

// Read in an OCODE label.
AND rdl() = VALOF
{ LET l = rdn()
  IF maxlab<l DO { maxlab := l; checklab() }
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
{ labnumber := labnumber-1
  checklab()
  RESULTIS labnumber
}

AND checklab() BE IF maxlab>=labnumber DO
{ cgerror("Too many labels - increase workspace")
  errcount := errcount+1
  longjump(fin_p, fin_l)
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
  IF maxssp<ssp DO maxssp := ssp
}

// Move simulated stack (SS) pointer to N.
AND stack(n) BE
{ IF maxssp<n DO maxssp := n
  IF n>=ssp+4 DO { store(0,ssp-1)
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
{ IF debug>1 DO { writef("OP=%t5 PND=%t5 ", opname(op), opname(pendingop))
                  dboutput()
                }
  SWITCHON op INTO

  { DEFAULT:     cgerror("Bad OCODE op %n %s", op, opname(op))
                 ENDCASE

    CASE s_fnum:
               { LET mantissa = rdn()
                 LET exponent = rdn()
                 cgpendingop()
                 loadt(k_numb, mantissa)
                 loada(arg1)
                 genfb(f_fltop, fl_mk, exponent)
                 forget_a()
                 ENDCASE
               }

    CASE s_selld:
               { LET len = rdn()
                 LET sh  = rdn()
//writef("selld: calling cgpendingop*n")
                 cgpendingop()
//writef("selld: calling loada*n")
                 loada(arg1)
//writef("selld: calling genbb*n")
                 genbb(f_selld, len, sh)
                 forget_a()
                 ENDCASE
               }

    CASE s_selst:
               { LET sfop = rdn()
                 LET len  = rdn()
                 LET sh   = rdn()
                 cgpendingop()
                 loadba(arg2, arg1)
                 genfbb(f_selst, sfop, len, sh)
                 forgetallvars()
                 stack(ssp-2)
                 ENDCASE
               }

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
    CASE s_ln:   loadt(k_numb,  rdn());   ENDCASE

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

    CASE s_float: CASE s_fix: CASE s_fneg: CASE s_fabs:
    CASE s_not:CASE s_neg:CASE s_abs:
    CASE s_fmul: CASE s_fdiv:
    CASE s_fadd:CASE s_fsub:
    CASE s_feq: CASE s_fne:
    CASE s_fls:CASE s_fgr:CASE s_fle:CASE s_fge:

    CASE s_mul:CASE s_div:CASE s_rem:
    CASE s_add:CASE s_sub:
    CASE s_eq: CASE s_ne:
    CASE s_ls:CASE s_gr:CASE s_le:CASE s_ge:
    CASE s_lshift:CASE s_rshift:
    CASE s_logand:CASE s_logor:CASE s_eqv:CASE s_neqv:
                 cgpendingop()
                 pendingop := op
                 ENDCASE

    CASE s_jt:   cgjump(TRUE, rdl());  ENDCASE

    CASE s_jf:   cgjump(FALSE, rdl()); ENDCASE

    CASE s_goto: cgpendingop()
                 store(0, ssp-2)
                 TEST h1!arg1=k_fnlab
                 THEN genr(f_j, h2!arg1)
                 ELSE { loada(arg1); gen(f_goto) }
                 stack(ssp-1)
                 incode := FALSE
                 // This is a good place to deal with
                 // some outstanding forward refs.
                 chkrefs(50)
                 ENDCASE

    CASE s_lab:  cgpendingop()
                 UNLESS incode DO chkrefs(30)
                 store(0, ssp-1)
                 setlab(rdl())
                 forgetall()
                 incode := procdepth>0
                 ENDCASE

    CASE s_query:loadt(k_loc, ssp);              ENDCASE

    CASE s_stack:cgpendingop(); stack(rdn());    ENDCASE

    CASE s_store:cgpendingop(); store(0, ssp-1); ENDCASE

    CASE s_entry:
               { LET l = rdl()
                 LET n = rdn()
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
    CASE s_rtap: cgapply(op, rdn())
                 ENDCASE

    CASE s_rtrn: cgpendingop()
                 gen(f_rtn)
                 incode := FALSE
                 ENDCASE
                   
    CASE s_fnrn: cgpendingop()
                 loada(arg1)
                 gen(f_rtn)
                 stack(ssp-1)
                 incode := FALSE
                 ENDCASE

    CASE s_endproc:
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
                 ELSE { loada(arg1); stack(ssp-1) }

                 { op := rdn()
                   UNLESS op=s_stack BREAK
                   stack(rdn())
                 } REPEAT

                 TEST op=s_lab
                 THEN { LET m = rdl()
                        UNLESS l=m DO genr(f_j, l)
                        setlab(m)
                        forgetall()
                        incode := procdepth>0
                        op := rdn()
                      }
                 ELSE { genr(f_j, l)
                        incode := FALSE
                        // Deal with some refs.
                        chkrefs(50)
                      }

                 LOOP
               }

    // rstack always occurs immediately after a lab statement
    // at a time when cgpendingop() and store(0, ssp-2) have
    // been called.
    CASE s_rstack:
                 stack(rdn()); loadt(k_a, 0); ENDCASE

    CASE s_finish:  // Compile code for:  stop(0).
               { LET k = ssp
                 stack(ssp+3)
                 loadt(k_numb, 0)
                 loadt(k_numb, 0)
                 loadt(k_glob, gn_stop)
                 cgapply(s_rtap, k)    // Simulate the call: stop(0, 0)
                 ENDCASE
               }

    CASE s_switchon:
                 cgswitch(); ENDCASE

    CASE s_getbyte:
                 cgpendingop()
                 loadba(arg2, arg1)
                 gen(f_gbyt)
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
                        gen(f_atc)
                        stack(ssp-1)
                      }
                 ELSE { TEST inreg_b(h1!arg3, h2!arg3)
                        THEN    gen(f_btc)
                        ELSE { loada(arg3)
                               gen(f_atc)
                             }
                        h1!arg3 := k_c
                      }
                 TEST loadboth(arg2, arg1)=swapped
                 THEN gen(f_xpbyt)
                 ELSE gen(f_pbyt)
                 forgetallvars()
                 stack(ssp-3)
                 ENDCASE
               }

    CASE s_global:
                 cgglobal(rdn()); RETURN

    CASE s_datalab:
               { LET lab = rdl() 
                 op := rdn()

                 WHILE op=s_itemn DO
                 { LET t = getblk(0,lab,0)
                   LET bv = @t!2
                   LET val = rdn()
                   LET w = val
                   // Copy the bytes of val into bv in
                   // little-ender order
                   FOR i = 0 TO 3 DO // Deal with ls 4 bytes
                   { bv%i := w
                     w := w>>8
                   }

                   // For 64-bit target deal with the senior 4 bytes
                   IF t64 DO
                   { TEST c64
                     THEN w := val>>32
                     ELSE w := val<0 -> -1, 0 // Sign extend
                     FOR i = 4 TO 7 DO
                     { bv%i := w
                       w := w>>8
                     }
                   }

                   !nliste := t
                   nliste, lab, op := !nliste, 0, rdn()
                 }
                 LOOP
               }
  }

  op := rdn()
} REPEAT


// Compiles code to deal with any pending op.
LET cgpendingop() BE
{ LET f, flop = 0, 0
  LET sym = TRUE
  LET pndop = pendingop
  pendingop := s_none

  SWITCHON pndop INTO
  { DEFAULT:      cgerror("Bad pendingop %s", opname(pndop))

    CASE s_none:  RETURN

    CASE s_float: loada(arg1)
                  genflt(fl_float)
                  forget_a()
                  RETURN

    CASE s_fix:   loada(arg1)
                  genflt(fl_fix)
                  forget_a()
                  RETURN

    CASE s_fabs:  loada(arg1)
                  genflt(fl_abs)
                  forget_a()
                  RETURN

    CASE s_abs:   loada(arg1)
                  chkrefs(3)
                  genb(jfn0(f_jgr), 2) // Conditionally skip
                  gen(f_neg)           // over this NEG instruction.
                  forget_a()
                  RETURN

    CASE s_fneg:  loada(arg1)
                  genflt(fl_neg)
                  forget_a()
                  RETURN

    CASE s_neg:   loada(arg1)
                  gen(f_neg)
                  forget_a()
                  RETURN

    CASE s_not:   loada(arg1)
                  gen(f_not)
                  forget_a()
                  RETURN

    CASE s_feq:   flop := fl_eq; GOTO case_feq
    CASE s_fne:   flop := fl_ne; GOTO case_feq
    CASE s_fls:   flop := fl_ls; GOTO case_feq
    CASE s_fgr:   flop := fl_gr; GOTO case_feq
    CASE s_fle:   flop := fl_le; GOTO case_feq
    CASE s_fge:   flop := fl_ge; GOTO case_feq
case_feq:         loadba(arg2, arg1)
                  genflt(flop)
                  lose1(k_a, 0)
                  forget_a()
                  forget_b()
                  RETURN

    CASE s_eq: CASE s_ne:
    CASE s_ls: CASE s_gr:
    CASE s_le: CASE s_ge:
                  f := prepj(jmpfn(pndop))
                  chkrefs(4)
                  genb(f, 2)    // Jump to    ---
                  gen(f_fhop)   //               |
                  gen(f_lm1)    // this point  <-
                  lose1(k_a, 0)
                  forget_a()
                  forget_b()
                  RETURN

    CASE s_sub:   UNLESS k_numb=h1!arg1 DO
                  { f, sym := f_sub, FALSE
                    ENDCASE
                  }
                  h2!arg1 := -h2!arg1

    CASE s_add:   cgadd(); RETURN

    CASE s_fmul:  f := fl_mul;  GOTO case_fmul
    CASE s_fadd:  f := fl_add;  GOTO case_fmul

case_fmul:        loadboth(arg2, arg1)
                  genflt(f)
                  forget_a()
                  lose1(k_a, 0)
                  RETURN

    CASE s_fdiv:  f := fl_div;   GOTO case_fdiv
    CASE s_fsub:  f := fl_sub; GOTO case_fdiv

case_fdiv:        loadba(arg2, arg1)
                  genflt(f)
                  forget_a()
                  lose1(k_a, 0)
                  RETURN

    CASE s_mul:   f      := f_mul;        ENDCASE
    CASE s_div:   f, sym := f_div, FALSE; ENDCASE
    CASE s_rem:   f, sym := f_rem, FALSE; ENDCASE
    CASE s_lshift:f, sym := f_lsh, FALSE; ENDCASE
    CASE s_rshift:f, sym := f_rsh, FALSE; ENDCASE
    CASE s_logand:f      := f_and;        ENDCASE
    CASE s_logor: f      := f_or;         ENDCASE
    CASE s_eqv:
    CASE s_neqv:  f      := f_xor;        ENDCASE
  }

  TEST sym THEN loadboth(arg2, arg1)
           ELSE loadba(arg2, arg1)

  gen(f)
  forget_a()
  IF pndop=s_eqv THEN gen(f_not)

  lose1(k_a, 0)
}

LET loada(x)   BE { loadval(x, FALSE); setba(0, x) }

AND push(x, y) BE { loadval(y, TRUE);  setba(x, y) }

AND loadval(x, pushing) BE  // ONLY called from loada and push.
// Load compiles code to have the following effect:
// If pushing=TRUE    B := A; A := <x>.
// If pushing=FALSE   B := ?; A := <x>.
{ LET k, n = h1!x, h2!x

  UNLESS pushing | k=k_a DO  // Dump A register if necessary.
    FOR t = arg1 TO tempv BY -3 IF h1!t=k_a DO { storet(t); BREAK }

  TEST inreg_a(k, n) THEN setba(0, x)
                     ELSE IF inreg_b(k, n) DO { genxch(0, 0)
                                                RETURN
                                              }
  SWITCHON h1!x INTO
  { DEFAULT:  cgerror("in loada %n", k)

    CASE k_a: IF pushing UNLESS inreg_b(k, n) DO genatb(0, 0)
              RETURN

    CASE k_numb:
              cgloadk(n)
              RETURN

    CASE k_loc:  genlp(n);        ENDCASE
    CASE k_glob: geng(f_lg, n);   ENDCASE
    CASE k_lab:  genr(f_ll, n);   ENDCASE
    CASE k_fnlab:genr(f_lf, n);   ENDCASE

    CASE k_lvloc:TEST 0<=n<=255
                 THEN genb(f_llp, n)
                 ELSE TEST 0<=n<=#xFFFF
                      THEN genh(f_llph, n)
                      ELSE genw(f_llpw, n)
                 ENDCASE

    CASE k_lvglob:geng(f_llg, n); ENDCASE
    CASE k_lvlab: genr(f_lll, n); ENDCASE
    CASE k_loc0:  gen(f_l0p0+n);  ENDCASE
    CASE k_loc1:  gen(f_l1p0+n);  ENDCASE
    CASE k_loc2:  gen(f_l2p0+n);  ENDCASE
    CASE k_loc3:  gen(f_l3p0+n);  ENDCASE
    CASE k_loc4:  gen(f_l4p0+n);  ENDCASE
    CASE k_glob0: geng(f_l0g, n); ENDCASE
    CASE k_glob1: geng(f_l1g, n); ENDCASE
    CASE k_glob2: geng(f_l2g, n); ENDCASE
  }

  // A loading instruction has just been compiled.
  pushinfo(h1!x, h2!x)
}

AND loadba(x, y) BE IF loadboth(x, y)=swapped DO genxch(x, y)

AND setba(x, y) BE
{ UNLESS x=0 DO h1!x := k_b
  UNLESS y=0 DO h1!y := k_a
}

AND genxch(x, y) BE { gen(f_xch); xchinfo(); setba(x, y) }

AND genatb(x, y) BE { gen(f_atb); atbinfo(); setba(x, y) }

AND loadboth(x, y) = VALOF
// Compiles code to cause
//   either    x -> [B]  and  y -> [A]
//             giving result NOTSWAPPED
//   or        x -> [A]  and  y -> [B]
//             giving result SWAPPED.
// loadboth only swaps if this saves code.
{ // First ensure that no other stack item uses reg A.
  FOR t = tempv TO arg1 BY 3 DO
    IF h1!t=k_a UNLESS t=x | t=y DO storet(t)

  { LET xa, ya = inreg_a(h1!x, h2!x), inreg_a(h1!y, h2!y)
    AND xb, yb = inreg_b(h1!x, h2!x), inreg_b(h1!y, h2!y)

    IF xb & ya DO { setba(x,y);               RESULTIS notswapped }
    IF xa & yb DO { setba(y,x);               RESULTIS swapped    }
    IF xa & ya DO { genatb(x,y);              RESULTIS notswapped }
    IF xb & yb DO { genxch(0,y); genatb(x,y); RESULTIS notswapped }
      
    IF xa DO {              push(x,y); RESULTIS notswapped }
    IF ya DO {              push(y,x); RESULTIS swapped    }
    IF xb DO { genxch(0,x); push(x,y); RESULTIS notswapped }
    IF yb DO { genxch(0,y); push(y,x); RESULTIS swapped    }
      
    loada(x)
    push(x, y)
    RESULTIS notswapped
  }
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

AND pushinfo(k, n) BE
{ forget_b()
  info_b := info_a
  info_a := getblk(0, k, n)
}

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

AND forget_a() BE { freeblks(info_a); info_a := 0 }

AND forget_b() BE { freeblks(info_b); info_b := 0 }

AND forgetall() BE { forget_a(); forget_b() }

// Forgetvar is called just after a simple variable (k, n) has been
// updated.  k is k_loc, k_glob or k_lab.  Note that register
// infomation about indirect local and global values
// must also be thrown away.
AND forgetvar(k, n) BE
{ LET p = info_a
  UNTIL p=0 DO { IF h2!p>=k_loc0 | h2!p=k & h3!p=n DO h2!p := k_none
                 p := !p
               }
  p := info_b
  UNTIL p=0 DO { IF h2!p>=k_loc0 | h2!p=k & h3!p=n DO h2!p := k_none
                 p := !p
               }
}

AND forgetallvars() BE  // Called after STIND, SELST or PUTBYTE.
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

AND gensp(s) BE TEST 3<=s<=16
                THEN gen(f_sp0+s)
                ELSE TEST 0<=s<=255
                     THEN genb(f_sp, s)
                     ELSE TEST 0<=s<=#xFFFF
                          THEN genh(f_sph, s)
                          ELSE genw(f_spw, s)

AND genlp(n) BE TEST 3<=n<=16
                THEN gen(f_lp0+n)
                ELSE TEST 0<=n<=255
                     THEN genb(f_lp, n)
                     ELSE TEST 0<=n<=#xFFFF
                          THEN genh(f_lph, n)
                          ELSE genw(f_lpw, n)

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
  IF maxssp<ssp DO maxssp := ssp
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
             h1!arg2=k_numb DO swapargs()
          IF h1!arg1=k_loc |
             h1!arg1=k_glob |
             h1!arg1=k_numb DO
          // Optimize the case  <arg2>!<arg1> := <arg3>
          // where <arg3> is already in A
          // and <arg1> is a local, a global or a number.
          { push(arg3, arg2)
            cgadd()  // Compiles an A, AP or AG instr.
            gen(f_st)
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
                           geng(f_s0g, n)
                           stack(ssp-2)
                           forgetallvars()
                           RETURN
                         }

    IF k=k_loc & 3<=n<=4 & t<=1 DO { loada(arg2)
                                     gen(t=0 -> f_st0p0+n,
                                                f_st1p0+n)
                                     stack(ssp-2)
                                     forgetallvars()
                                     RETURN
                                   }

    loadba(arg2, arg1)
    gen(f_st+t)
    stack(ssp-2)
    forgetallvars()
  }
}

// Store the top item of the SS in (K,N).
AND storein(k, n) BE
// K is K_LOC, K_GLOB or K_LAB.
{ cgpendingop()
  loada(arg1)

  SWITCHON k INTO
  { DEFAULT:     cgerror("in storein %n", k)
    CASE k_loc:  gensp(n);       ENDCASE
    CASE k_glob: geng(f_sg, n);  ENDCASE
    CASE k_lab:  genr(f_sl, n);  ENDCASE
  }
  forgetvar(k, n)
  addinfo_a(k, n)
  stack(ssp-1)
}

LET cgrv() BE
{ LET t = VALOF
  { IF pendingop=s_add DO
    { IF k_numb=h1!arg2 DO swapargs()
      IF k_numb=h1!arg1 DO
      { LET n = h2!arg1
        IF 0<=n<=6 DO { stack(ssp-1)
                        pendingop := s_none
                        RESULTIS n
                      }
      }

      IF h1!arg2=k_loc & 3<=h2!arg2<=7 DO swapargs()
      IF h1!arg1=k_loc & 3<=h2!arg1<=7 DO { LET n = h2!arg1
                                            stack(ssp-1)
                                            pendingop := s_none
                                            RESULTIS 10 + n
                                          }
    }
    cgpendingop()
    RESULTIS 0
  }

  // Now compile code for S!<arg1>
  // where          S is 0,..., 6, P3,..., P7
  // depending on   T =  0,..., 6, 13,..., 17

  LET k, n = h1!arg1, h2!arg1
   
  IF k=k_glob & 0<=t<=2 DO { h1!arg1 := k_glob0 + t; RETURN }

  IF k=k_loc & n>=3 DO
    IF t=0 & n<=12 |
       t=1 & n<=6  |
       t=2 & n<=5  |
       t=3 & n<=4  |
       t=4 & n<=4  DO { h1!arg1 := k_loc0 + t; RETURN }

  loada(arg1)
  TEST t<=6 THEN gen(f_rv+t)
            ELSE gen(f_rvp0 + t - 10)
  forget_a()
  h1!arg1, h2!arg1 := k_a, 0
}

AND cgadd() BE
// Compiles code to compute <arg2> + <arg1>.
// It does not look at PENDINGOP.

{ IF iszero(arg1) DO { stack(ssp-1); RETURN }

  IF iszero(arg2) DO
  { IF h2!arg1=ssp-1 &
       (h1!arg1=k_loc | k_loc0<=h1!arg1<=k_loc4) DO loada(arg1)
    lose1(h1!arg1, h2!arg1)
    RETURN
  }

  TEST inreg_a(h1!arg1, h2!arg1)
  THEN loada(arg1)
  ELSE IF inreg_a(h1!arg2, h2!arg2) DO loada(arg2)

  IF h1!arg1=k_a DO swapargs()

  IF h1!arg2=k_loc & 3<=h2!arg2<=12 DO swapargs()
  IF h1!arg1=k_loc & 3<=h2!arg1<=12 DO { loada(arg2)
                                         gen(f_ap0 + h2!arg1)
                                         forget_a()
                                         lose1(k_a, 0)
                                         RETURN
                                       }

  IF h1!arg2=k_numb & -4<=h2!arg2<=5 DO swapargs()
  IF h1!arg1=k_numb & -4<=h2!arg1<=5 DO { loada(arg2)
                                          cgaddk(h2!arg1)
                                          lose1(k_a, 0)
                                          RETURN
                                        }

  IF h1!arg2=k_loc DO swapargs()
  IF h1!arg1=k_loc DO
  { LET n = h2!arg1
    loada(arg2)
    TEST 3<=n<=12 THEN gen(f_ap0 + n)
                  ELSE TEST 0<=n<=255
                       THEN genb(f_ap, n)
                       ELSE TEST 0<=n<=#xFFFF
                            THEN genh(f_aph, n)
                            ELSE genw(f_apw, n)
    forget_a()
    lose1(k_a, 0)
    RETURN
  }

  IF h1!arg2=k_glob DO swapargs()
  IF h1!arg1=k_glob DO { loada(arg2)
                         geng(f_ag, h2!arg1)
                         forget_a()
                         lose1(k_a, 0)
                         RETURN
                       }

  IF h1!arg2=k_numb DO swapargs()
  IF h1!arg1=k_numb DO { LET n = h2!arg1
                         loada(arg2)
                         cgaddk(n)
                         lose1(k_a, 0)
                         RETURN
                       }
  loadboth(arg2, arg1)
  gen(f_add)
  forget_a()
  lose1(k_a, 0)
}

AND cgloadk(n) BE
{ TEST -1<=n<=10
  THEN gen(f_l0+n)
  ELSE TEST 0<=n<=255
       THEN genb(f_l, n)
       ELSE TEST -255<=n<=0
            THEN genb(f_lm, -n)
            ELSE TEST 0<=n<=#xFFFF
                 THEN genh(f_lh, n)
                 ELSE TEST -#xFFFF<=n<=0
                      THEN genh(f_lmh, -n)
                      ELSE genw(f_lw, n)
  pushinfo(k_numb, n)
}

AND cgaddk(k) BE UNLESS k=0 DO  // Compile code to add k to A.
{ TEST -4<=k<=5
  THEN TEST k<0 THEN gen(f_s0 - k)
                ELSE gen(f_a0 + k)
  ELSE TEST -255<=k<=255
       THEN TEST k>0 THEN genb(f_a, k)
                     ELSE genb(f_s, -k)
       ELSE TEST 0<=k<=#xFFFF
            THEN genh(f_ah, k)
            ELSE TEST -#xFFFF<=k<=0
                 THEN genh(f_sh, -k)
                 ELSE genw(f_aw, k)
  forget_a()
}

AND cgglobal(n) BE
{ incode := FALSE
  cgstatics()
  chkrefs(512)   // Deal with ALL outstanding refs.
  align(wordbytelen)
  codew(0, 0)       // Compile Global initialisation data.
  FOR i = 1 TO n DO
  { codew(0, rdgn())
    codew(0, labv!rdl())
  }
  codew(0, maxgn)
}


AND cgentry(l, n) BE
{ MANIFEST { upb=11 } // Max length of entry name
  LET v = VEC upb/bytesperword
  v%0 := upb
  rdname(n, v) // Pack up to 11 character of the name into v

  chkrefs(80)  // Deal with some forward refs.
  align(wordbytelen)
  IF naming DO
  { TEST c64
    THEN codew(  entryword>>32,  entryword)
    ELSE codew(-(entryword>>31), entryword) // Sign extend
    codestr(v)   // Compile the words containing the packed
                 // string characters
  }

  IF debug>0 DO writef("// Entry to:   %s*n", v)
  setlab(l)
  incode := TRUE
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
      { push(t, arg2)
        storet(arg2)    // Store second arg.
        genxch(0, t)    // Restore first arg back to A.
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

  TEST h1!arg1=k_glob & 3<=k<=11
  THEN geng(f_k0g+k, h2!arg1)
  ELSE { push(a1, arg1)
         // First arg (if any) is now in B
         // and the procedure address is in A.
         TEST 3<=k<=11
         THEN gen(f_k0+k)
         ELSE TEST 0<=k<=255
              THEN genb(f_k, k)
              ELSE TEST 0<=k<=#xFFFF
                   THEN genh(f_kh, k)
                   ELSE genw(f_kw, k)
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
  genr(prepj(f),l)
  stack(ssp-2)
}

AND jmpfn(op) = VALOF SWITCHON op INTO
{ DEFAULT:  RESULTIS 0
  CASE s_eq: RESULTIS f_jeq
  CASE s_ne: RESULTIS f_jne
  CASE s_ls: RESULTIS f_jls
  CASE s_gr: RESULTIS f_jgr
  CASE s_le: RESULTIS f_jle
  CASE s_ge: RESULTIS f_jge
}

AND jfn0(f) = f+2 // Change F_JEQ into F_JEQ0  etc...

AND revjfn(f) = f=f_jls -> f_jgr,
                f=f_jgr -> f_jls,
                f=f_jle -> f_jge,
                f=f_jge -> f_jle,
                f

AND compjfn(f) = f=f_jeq -> f_jne,
                 f=f_jne -> f_jeq,
                 f=f_jls -> f_jge,
                 f=f_jge -> f_jls,
                 f=f_jgr -> f_jle,
                 f=f_jle -> f_jgr,
                 f

AND prepj(f) = VALOF  // Returns the appropriate m/c fn.
{ IF iszero(arg2) DO { swapargs(); f := revjfn(f) }
  IF iszero(arg1) DO { loada(arg2); RESULTIS jfn0(f) }
  IF loadboth(arg2, arg1)=swapped RESULTIS revjfn(f)
  RESULTIS f
}

// Compiles code for SWITCHON.
LET cgswitch() BE
{ LET n = rdn()     // Number of cases.
  LET dlab = rdl()  // Default label.

  // Read and sort (K,L) pairs.
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
  loada(arg1)
  stack(ssp-1)
  switcht(1, n, dlab, FALSE, 0)
}

AND prcases(p, q) BE
{ writef("*nprcases: p=%n q=%n*n", p, q)
  FOR i = p TO q DO
  { IF (i-p) MOD 8 = 0 DO newline()
    writef(" %11i", casek!i)
  }
  newline()
}

// Code has already been compiled to set either A or B to the 
// value of the switch expression.
// Compile code to switch on cases in region p..q with default
// label dlab.
AND switcht(p, q, dlab, inba, aval) BE
{ // If inba=TRUE,  the switch value is in B and A=aval.
  // If inba=FALSE, the switch value is in A.
  // Compile code for cases in the region region p to q
  // and default label dlab.
  LET n = q-p+1    // Number of cases in region p..q
  LET r = (p+q)/2
  LET s = r

  // If no cases goto default label
  IF n=0 DO { genr(f_j, dlab); RETURN }

  IF n=1 DO
  { // There is just one case so use an equality test.
    // Set B = switch value and A = casek!p
    TEST inba
    THEN { cgaddk(casek!p-aval)
           aval := casek!p
         } 
    ELSE { inba, aval := TRUE, casek!p
           cgloadk(aval)
         }
    genr(f_jeq, casel!p)
    genr(f_j, dlab)
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

  IF n<=3 IF p<r | s<q  DO
  { // Use a sequence of equality tests.
    FOR i = p TO q DO
    { TEST inba
      THEN { cgaddk(casek!i-aval)
             aval := casek!i
           } 
      ELSE { inba, aval := TRUE, casek!i
             cgloadk(aval)
           }
      genr(f_jeq, casel!i)
    }
    genr(f_j, dlab)
    forgetall()
    RETURN
  }

  UNLESS r=p DO
  { // At least one case in LH region p .. r-1
    // Set B = switch value and A = casek!r
    LET lab = newlab()
    TEST inba
    THEN { cgaddk(casek!r-aval)
           aval := casek!r
         } 
    ELSE { inba, aval := TRUE, casek!r
           cgloadk(aval)
         }
    genr(f_jge, lab)
    switcht(p, r-1, dlab, TRUE, aval)
    setlab(lab)
    switcht(r, q,   dlab, TRUE, aval)
    RETURN
  }

  UNLESS s=q DO
  { // At least one case in RH region s+1 .. q
    // Set B = switch value and A = casek!s
    LET lab = newlab()
    TEST inba
    THEN { cgaddk(casek!s-aval)
           aval := casek!s
         } 
    ELSE { inba, aval := TRUE, casek!s
           cgloadk(aval)
         }
    genr(f_jgr, lab)
    switcht(p,   s, dlab, TRUE, aval)
    setlab(lab)
    switcht(s+1, q, dlab, TRUE, aval)
    RETURN
  }

  IF inba DO gen(f_xch) // Put B back in A, if necessary.
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
   
  chkrefs(6+4*n1) // allow for padding to 7 cases
  gen(f_swb)
  align(2)
  codeh(n)
  coder(dlab)
  FOR i = p TO q DO { LET pos = q + 1 - findpos(i-p+1, q-p+1)
                      codeh(casek!pos)
                      coder(casel!pos)
                    }
  FOR i = q+1 TO p+6 DO { codeh(0) // pad out to 7 cases
                          coder(dlab)
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

  LET n, t = ?, p

  // Adjust case constants to suit SWL instruction.
  IF casek!p<0 | casek!p>1 | casek!q>#xFFFF DO
  { cgaddk(-casek!p)
    offsetcases(p, q, casek!p)
  }
   
  n := casek!q + 1   // Number of entries in the label vector.
  chkrefs(2*n+6)
  gen(f_swl)
  align(2)
  codeh(n)
  coder(dlab)        // Default label.

  FOR k = 0 TO casek!q TEST casek!t=k
                       THEN { coder(casel!t)
                              t := t+1
                            }
                       ELSE coder(dlab)
}

AND cgstring(n) BE
{ LET lab, a = newlab(), n
  loadt(k_lvlab, lab)

  { // Start of packing loop
    LET t  = getblk(0, lab, 0) // The first item hold the label
    LET b, c, d, e, f, g, h = 0, 0, 0, 0, 0, 0, 0
    !nliste := t
    nliste := !nliste
    lab := 0                  // Clear the label for further items

    IF n>=1 DO b := rdn()
    IF n>=2 DO c := rdn()
    IF n>=3 DO d := rdn()
    n := n-4      // 1 to 4 bytes have been packed
    TEST t64
    THEN { IF n>=0 DO e := rdn()
           IF n>=1 DO f := rdn()
           IF n>=2 DO g := rdn()
           IF n>=3 DO h := rdn()
           n := n-4    // 1 to 8 bytes have been packed
           TEST bigender
           THEN TEST c64
                THEN h3!t := pack4b(a,b,c,d)<<32 | pack4b(e,f,g,h)
                ELSE h4!t, h3!t := pack4b(a,b,c,d), pack4b(e,f,g,h)
           ELSE TEST c64
                THEN h3!t := pack4b(h,g,f,e)<<32 | pack4b(d,c,b,a)
                ELSE h4!t, h3!t := pack4b(h,g,f,e), pack4b(d,c,b,a)
         }
    ELSE TEST bigender
         THEN h3!t := pack4b(a,b,c,d)
         ELSE h3!t := pack4b(d,c,b,a)

    IF n<0 BREAK  // There are no more characters to pack

    a := rdn()
  } REPEAT
}

AND setlab(l) BE
{ LET p = @rlist

  IF debug>0 DO writef("%i4: L%n:*n", stvp, l)

  labv!l := stvp  // Set the label.

  // Fill in all refs that are in range.
  { LET r = !p
    IF r=0 BREAK
    TEST h3!r=l & inrange_d(h2!r, stvp)
    THEN { fillref_d(h2!r, stvp)
           !p := !r   // Remove item from RLIST.
           freeblk(r)
         }
    ELSE p := r  // Keep the item.
  } REPEAT
  rliste := p     // Ensure that RLISTE is sensible.

  p := @reflist

  { LET r = !p
    IF r=0 BREAK
    TEST h3!r=l
    THEN { LET a = h2!r
           puth(a,stvp-a) // Plant rel address.
           !p := !r       // Remove item from REFLIST.
           freeblk(r)
         }
    ELSE p := r  // Keep item.
  } REPEAT

  refliste := p   // Ensure REFLISTE is sensible.
}

AND cgstatics() BE WHILE nlist DO
{ LET len, nl = 0, nlist

  nliste := @nlist  // All NLIST items will be freed.

  // Calculate the length in bytes of the next static value.
  len, nl := len+wordbytelen, !nl REPEATUNTIL nl=0 | h2!nl

  chkrefs(len+wordbytelen-1) // +wordbytelen since align(wordbytelen)
                             // may generate this number of bytes.
  align(wordbytelen)

  setlab(h2!nlist)  // The first NLIST item always has a label.

  { LET blk = nlist
    LET w   = h3!blk
    nlist := !nlist
//writef("cgstatics: blk=%n -> [%n, %n, %x8]*n", blk, blk!0, blk!1, blk!2)
    TEST c64
    THEN TEST t64
         THEN codew( (w>>32), w)  // c64 -> T64
         ELSE codew(-(w>>31), w)  // c64 -> t32   sign extend
    ELSE TEST t64
         THEN codew(  h4!blk, w)  // c32 -> t64
         ELSE codew(       0, w)  // c32 -> t32
    freeblk(blk)
  } REPEATUNTIL nlist=0 | h2!nlist
}

AND getblk(a, b, c) = VALOF
{ LET p = freelist
  TEST p=0 THEN { dp := dp-blkupb-1; checkspace(); p := dp }
           ELSE freelist := !p
  IF blkupb=3 DO p!3 := 0 // Clear the 4th word if it exists
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
{ reflist, refliste := 0, @reflist
  rlist,   rliste   := 0, @rlist
  nlist,   nliste   := 0, @nlist
  freelist := 0
}

LET geng(f, n) BE TEST n<256
                  THEN genb(f, n)
                  ELSE TEST n<512
                       THEN genb(f+32, n-256)
                       ELSE genh(f+64, n)

LET gen(f) BE IF incode DO
{ chkrefs(1)
  IF debug DO wrcode(f, "")
  codeb(f)
}

LET genb(f, a) BE IF incode DO
{ chkrefs(2)
  IF debug>0 DO wrcode(f, "%i3", a)
  codeb(f)
  codeb(a)
}

LET genbb(f, a, b) BE IF incode DO
{ chkrefs(3)
  IF debug>0 DO wrcode(f, "%i3 %i3", a, b)
  codeb(f)
  codeb(a)
  codeb(b)
}

LET genflt(flop) BE IF incode DO
{ chkrefs(2)
  IF debug>0 DO wrcode(f_fltop, "%s", flopname(flop))
  codeb(f_fltop)
  codeb(flop)
}

LET genr(f, n) BE IF incode DO
{ chkrefs(2)
  IF debug>0 DO wrcode(f, "L%n", n)
  codeb(f)
  codeb(0)
  relref(stvp-2, n)
}

LET genh(f, h) BE IF incode DO  // Assume 0 <= h <= #xFFFF
{ chkrefs(3)
  IF debug>0 DO wrcode(f, "%n", h)
  codeb(f)
  code2b(h)
}

LET genw(f, w) BE IF incode DO
{ UNLESS -#x80000000 <= w <= #x7FFFFFFF DO
  { // This code is only executed if running on a 64-bit system
    // and an MW instruction is needed.
    LET mw = w>>32
    IF (w & #x80000000)~=0 DO mw := mw+1
    chkrefs(5)
    // Output code to set the senior 32 bits of the mw register
    // so that w = mw + sign_extend32(w & #xFFFFFFFF)
    // The MW register is always cleared after use.

    IF debug>0 DO wrcode(f_mw, "#x%x8", mw)
    codeb(f_mw)
    code4b(mw)
  }

  chkrefs(5)
  IF debug>0 DO wrcode(f, "#x%x8", w)
  codeb(f)
  code4b(w)
}

LET genfb(f, flop, a) BE IF incode DO
{ // Only called by: genfb(f_fltop, fl_mk, exponent)
  chkrefs(3)
  IF debug>0 DO wrcode(f, "%s %n", flopname(flop), a)
  codeb(f)
  codeb(flop)
  codeb(a)
}

LET genfbb(f, sfop, a, b) BE IF incode DO
{ chkrefs(4)
  IF debug>0 DO wrcode(f, "%s %n %n", sfname(sfop), a, b)
  codeb(f)
  codeb(sfop)
  codeb(a)
  codeb(b)
}

AND checkspace() BE IF stvp/4>dp-stv DO
{ cgerror("Program too large, %n bytes compiled", stvp)
  errcount := errcount+1
  longjump(fin_p, fin_l)
}

AND codeb(byte) BE
{ stv%stvp := byte
  stvp := stvp + 1
  checkspace()
}

AND code2b(h) BE TEST bigender
THEN { codeb(h>>8 ); codeb(h    )  }
ELSE { codeb(h    ); codeb(h>>8 )  }

AND code4b(w) BE TEST bigender
THEN { codeb(w>>24); codeb(w>>16); codeb(w>>8 ); codeb(w    )  }
ELSE { codeb(w    ); codeb(w>>8 ); codeb(w>>16); codeb(w>>24)  }

AND pack4b(a, b, c, d) = (((a<<8) | b)<<8 | c)<<8 | d

AND codeh(h) BE
{ IF debug>0 DO writef("%i4:  DATAH %n*n", stvp, h)
  code2b(h)
}

AND codew(wh, wl) BE TEST t64
THEN { IF debug>0 DO writef("%i4:  DATAW #x%x8%x8*n", stvp, wh, wl)
       TEST bigender
       THEN { codeb(wh>>24)
              codeb(wh>>16)
              codeb(wh>>8)
              codeb(wh)
              codeb(wl>>24)
              codeb(wl>>16)
              codeb(wl>>8)
              codeb(wl)
            }
       ELSE { codeb(wl)
              codeb(wl>>8)
              codeb(wl>>16)
              codeb(wl>>24)
              codeb(wh)
              codeb(wh>>8)
              codeb(wh>>16)
              codeb(wh>>24)
            }
     }
ELSE { IF debug>0 DO writef("%i4:  DATAW #x%x8*n", stvp, wl)
       TEST bigender
       THEN { codeb(wl>>24)
              codeb(wl>>16)
              codeb(wl>>8)
              codeb(wl)
            }
       ELSE { codeb(wl)
              codeb(wl>>8)
              codeb(wl>>16)
              codeb(wl>>24)
            }
     }

AND codestr(s) BE
{ LET i, len = 0, s%0

  TEST t64
  THEN UNTIL i>len DO // Target is 64-bit Cintcode
       { LET p = stvp
         LET a,b,c,d,e,f,g,h = 0,0,0,0,0,0,0,0
         IF i<=len DO a := s%i
         i := i+1
         IF i<=len DO b := s%i
         i := i+1
         IF i<=len DO c := s%i
         i := i+1
         IF i<=len DO d := s%i
         i := i+1
         IF i<=len DO e := s%i
         i := i+1
         IF i<=len DO f := s%i
         i := i+1
         IF i<=len DO g := s%i
         i := i+1
         IF i<=len DO h := s%i
         i := i+1

         TEST bigender
         THEN { codeb(a); codeb(b); codeb(c); codeb(d)
                codeb(e); codeb(f); codeb(g); codeb(h)
                IF debug>0 DO
                  writef("%i4:  DATAW #x%x2%x2%x2%x2%x2%x2%x2%x2*n", 
                          p,            a, b, c, d, e, f, g, h)
              }
         ELSE { codeb(a); codeb(b); codeb(c); codeb(d)
                codeb(e); codeb(f); codeb(g); codeb(h)
                IF debug>0 DO
                  writef("%i4:  DATAW #x%x2%x2%x2%x2%x2%x2%x2%x2*n", 
                          p,            h, g, f, e, d, c, b, a)
              }
       }
  ELSE UNTIL i>len DO // Target is 32-bit Cintcode
       { LET p = stvp
         LET a,b,c,d = 0,0,0,0
         IF i<=len DO a := s%i
         i := i+1
         IF i<=len DO b := s%i
         i := i+1
         IF i<=len DO c := s%i
         i := i+1
         IF i<=len DO d := s%i
         i := i+1

         TEST bigender
         THEN { codeb(a); codeb(b); codeb(c); codeb(d)
                IF debug>0 DO
                  writef("%i4:  DATAW #x%x2%x2%x2%x2*n", p, a,b,c,d)
              }
         ELSE { codeb(a); codeb(b); codeb(c); codeb(d)
                IF debug>0 DO
                  writef("%i4:  DATAW #x%x2%x2%x2%x2*n", p, d,c,b,a)
              }
       }
}

AND coder(n) BE
{ LET labval = labv!n
  IF debug>0 DO writef("%i4:  DATAH L%n-$*n", stvp, n)
  code2b(0)
  TEST labval=-1 THEN { !refliste := getblk(0, stvp-2, n)
                        refliste := !refliste
                      }
                 ELSE puth(stvp-2, labval-stvp+2)
}

AND getw(a) = VALOF TEST bigender
THEN TEST t64
     THEN RESULTIS 
                   stv%(a+0)<<56 |
                   stv%(a+1)<<48 |
                   stv%(a+2)<<40 |
                   stv%(a+3)<<32 |
                   stv%(a+4)<<24 |
                   stv%(a+5)<<16 |
                   stv%(a+6)<<8  |
                   stv%(a+7)
     ELSE RESULTIS stv%(a+0)<<24 |
                   stv%(a+1)<<16 |
                   stv%(a+2)<<8  |
                   stv%(a+3)
ELSE TEST t64
     THEN RESULTIS stv%(a+0)     |
                   stv%(a+1)<<8  |
                   stv%(a+2)<<16 |
                   stv%(a+3)<<24 |
                   stv%(a+4)<<32 |
                   stv%(a+5)<<40 |
                   stv%(a+6)<<48 |
                   stv%(a+7)<<56
     ELSE RESULTIS stv%(a+0)     |
                   stv%(a+1)<<8  |
                   stv%(a+2)<<16 |
                   stv%(a+3)<<24

AND puth(a, w) BE
  TEST bigender
  THEN stv%a,     stv%(a+1) := w>>8, w
  ELSE stv%(a+1), stv%a     := w>>8, w

AND putw(a, w) BE
  TEST bigender
  THEN TEST t64
       THEN { stv%(a+0) := w>>56
              stv%(a+1) := w>>48
              stv%(a+2) := w>>40
              stv%(a+3) := w>>32
              stv%(a+4) := w>>24
              stv%(a+5) := w>>16
              stv%(a+6) := w>>8
              stv%(a+7) := w
            }
       ELSE { stv%(a+0) := w>>24
              stv%(a+1) := w>>16
              stv%(a+2) := w>>8
              stv%(a+3) := w
            }
  ELSE TEST t64
       THEN { stv%(a+7) := w>>56
              stv%(a+6) := w>>48
              stv%(a+5) := w>>40
              stv%(a+4) := w>>32
              stv%(a+3) := w>>24
              stv%(a+2) := w>>16
              stv%(a+1) := w>>8
              stv%(a+0) := w
            }
       ELSE { stv%(a+3) := w>>24
              stv%(a+2) := w>>16
              stv%(a+1) := w>>8
              stv%(a+0) := w
            }

AND align(n) BE UNTIL stvp REM n = 0 DO codeb(0)

AND chkrefs(n) BE  // Resolve references until it is possible
                   // to compile n bytes without a reference
                   // going out of range.
{ LET p = @rlist

  skiplab := 0

  UNTIL !p=0 DO
  { LET r = !p
    LET a = h2!r // RLIST is ordered in increasing A.

    IF (stv%a & 1) = 0 DO
    // An unresolved reference at address A
    { IF inrange_i(a, stvp+n+3) BREAK
      // This point is reached if there is
      // an unresolved ref at A which cannot
      // directly relative address STVP+N+3
      // and so an indirect data word must
      // be compiled.
      // The +3 is to allow for a possible
      // skip jump instruction and possibly
      // one filler byte.
      genindword(h3!r)
    }

    // At this point the reference at A
    // is in range of a resolving indirect
    // data word and should be removed from
    // RLIST if there is no chance that it
    // can be resolved by a direct relative
    // address.
    TEST inrange_d(a, stvp)
    THEN p := r        // Keep the item.
    ELSE { !p := !r   // Free item if already resolved
           freeblk(r) // and no longer in direct range.
           IF !p=0 DO rliste := p  // Correct RLISTE.
         }
  }

  // At this point all necessary indirect data words have
  // been compiled.

  UNLESS skiplab=0 DO { setlab(skiplab)
                        skiplab, incode := 0, TRUE
                      }
}

AND genindword(l) BE  // Called only from CHKREFS.
{ LET r = rlist      // Assume RLIST ~= 0

  IF incode DO
  { skiplab := newlab()
    // genr(f_j, skiplab) without the call of chkrefs(2).
    IF debug>0 DO wrcode(f_j, "L%n", skiplab)
    codeb(f_j)
    codeb(0)
    relref(stvp-2, skiplab)
    incode := FALSE
  }

  align(2)

  UNTIL r=0 DO
  { IF h3!r=l & (stv%(h2!r) & 1)=0 DO fillref_i(h2!r, stvp)
    r := !r
  }

  coder(l)
}

AND inrange_d(a, p) = a-127 <= p <= a+128
// The result is TRUE if direct relative instr (eg J) at
// A can address location P directly.

AND inrange_i(a, p) = VALOF
// The result is TRUE if indirect relative instr (eg J}
// at A can address a resolving word at P.
{ LET rel = (p-a)/2
  RESULTIS 0 <= rel <= 255
}

AND fillref_d(a, p) BE
{ stv%a := stv%a & 254  // Back to direct form if neccessary.
  stv%(a+1) := p-a-1
}

AND fillref_i(a, p) BE  // P is even.
{ stv%a := stv%a | 1   // Force indirect form.
  stv%(a+1) := (p-a)/2
}

AND relref(a, l) BE
// RELREF is only called just after compiling
// a relative reference instruction at
// address A (=stvp-2).
{ LET labval = labv!l

  IF labval>=0 & inrange_d(a, labval) DO { fillref_d(a, labval)
                                           RETURN
                                         }

  // All other references in RLIST have
  // addresses smaller than A and so RLIST will
  // remain properly ordered if this item
  // is added to the end.
  !rliste := getblk(0, a, l)
  rliste := !rliste
}

LET outputsection() BE
{ LET outstream = output()
  UNTIL reflist=0 DO { cgerror("Label L%n unset", h3!reflist)
                       reflist := !reflist
                     }

  selectoutput(gostream)  // Output a HUNK or BHUNK.

  UNLESS objline1written IF objline1%0 DO
  { writef("%s*n", objline1)
    objline1written := TRUE
  }

  TEST bining
  THEN { writef("%X3 ", t_bhunk)          // writes 4 chars "BB8 "
         FOR p=0 TO 3      DO wrch(stv%p) // write bhunk size
         FOR p=0 TO stvp-1 DO wrch(stv%p) // write the bhunk
       }
  ELSE { newline()
         TEST t64
         THEN { LET p = 0
                writef("%16x ",t_hunk64)
                writef("%16x ", stvp/wordbytelen)
                WHILE p < stvp DO
                { IF p REM 32 = 0 DO newline()
                  wrword_at(p)
                  p := p+wordbytelen
                }
              }
         ELSE { LET p = 0
                writef("%8x ", t_hunk)
                writef("%8x ", stvp/wordbytelen)
                WHILE p < stvp DO
                { IF p REM 32 = 0 DO newline()
                  wrword_at(p)
                  p := p+wordbytelen
                }
              }
         newline()
       }
  selectoutput(outstream)
}

AND wrhex2(byte) BE
{ LET t = TABLE '0','1','2','3','4','5','6','7',
                '8','9','A','B','C','D','E','F'
  wrch(t!(byte>>4))
  wrch(t!(byte&15))
}

AND wrword_at(a) BE
{ TEST bigender THEN { wrhex2(stv%a)
                       wrhex2(stv%(a+1))
                       wrhex2(stv%(a+2))
                       wrhex2(stv%(a+3))
                       IF t64 DO
                       { wrhex2(stv%(a+4))
                         wrhex2(stv%(a+5))
                         wrhex2(stv%(a+6))
                         wrhex2(stv%(a+7))
                       }
                     }
                ELSE { IF t64 DO
                       { wrhex2(stv%(a+7))
                         wrhex2(stv%(a+6))
                         wrhex2(stv%(a+5))
                         wrhex2(stv%(a+4))
                       }
                       wrhex2(stv%(a+3))
                       wrhex2(stv%(a+2))
                       wrhex2(stv%(a+1))
                       wrhex2(stv%(a))
                     }
  wrch(' ')
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
   
  IF debug=3 DO { LET l = rlist
                  writes("*nREFS ")
                  UNTIL l=0 DO { writef("%n L%n  ", l!1, l!2)
                                 l := !l
                               }
                }
  newline()
}


AND wrkn(k,n) BE
{ LET s = VALOF SWITCHON k INTO
  { DEFAULT:       k := n
                   RESULTIS "?"
    CASE k_none:   RESULTIS "-"
    CASE k_numb:   RESULTIS "N"
    CASE k_fnlab:  RESULTIS "F"
    CASE k_lvloc:  RESULTIS "@P"
    CASE k_lvglob: RESULTIS "@G"
    CASE k_lvlab:  RESULTIS "@L"
    CASE k_a:      RESULTIS "A"
    CASE k_b:      RESULTIS "B"
    CASE k_c:      RESULTIS "C"
    CASE k_loc:    RESULTIS "P"
    CASE k_glob:   RESULTIS "G"
    CASE k_lab:    RESULTIS "L"
    CASE k_loc0:   RESULTIS "0P"
    CASE k_loc1:   RESULTIS "1P"
    CASE k_loc2:   RESULTIS "2P"
    CASE k_loc3:   RESULTIS "3P"
    CASE k_loc4:   RESULTIS "4P"
    CASE k_glob0:  RESULTIS "0G"
    CASE k_glob1:  RESULTIS "1G"
    CASE k_glob2:  RESULTIS "2G"
  }
  writes(s)
  UNLESS k=k_none | k=k_a | k=k_b | k=k_c DO writen(n)
}

AND wrcode(f, form, a, b) BE
{ IF debug=2 DO dboutput()
  writef("%i4: ", stvp)
  wrfcode(f)
  writes("  ")
  writef(form, a, b)
  newline()
}

AND wrfcode(f) BE
{ LET s = VALOF SWITCHON f&31 INTO
  { DEFAULT:
    CASE  0: RESULTIS "     -     K   LLP     L    LP    SP    AP     A"
    CASE  1: RESULTIS " FLTOP    KH  LLPH    LH   LPH   SPH   APH    AH"
    CASE  2: RESULTIS "   BRK    KW  LLPW    LW   LPW   SPW   APW    AW"
    CASE  3: RESULTIS "    K3   K3G  K3G1  K3GH   LP3   SP3   AP3  L0P3"
    CASE  4: RESULTIS "    K4   K4G  K4G1  K4GH   LP4   SP4   AP4  L0P4"
    CASE  5: RESULTIS "    K5   K5G  K5G1  K5GH   LP5   SP5   AP5  L0P5"
    CASE  6: RESULTIS "    K6   K6G  K6G1  K6GH   LP6   SP6   AP6  L0P6"
    CASE  7: RESULTIS "    K7   K7G  K7G1  K7GH   LP7   SP7   AP7  L0P7"
    CASE  8: RESULTIS "    K8   K8G  K8G1  K8GH   LP8   SP8   AP8  L0P8"
    CASE  9: RESULTIS "    K9   K9G  K9G1  K9GH   LP9   SP9   AP9  L0P9"
    CASE 10: RESULTIS "   K10  K10G K10G1 K10GH  LP10  SP10  AP10 L0P10"
    CASE 11: RESULTIS "   K11  K11G K11G1 K11GH  LP11  SP11  AP11 L0P11"
    CASE 12: RESULTIS "    LF   S0G  S0G1  S0GH  LP12  SP12  AP12 L0P12"
    CASE 13: RESULTIS "   LF$   L0G  L0G1  L0GH  LP13  SP13 XPBYT     S"
    CASE 14: RESULTIS "    LM   L1G  L1G1  L1GH  LP14  SP14   LMH    SH"
    CASE 15: RESULTIS "   LM1   L2G  L2G1  L2GH  LP15  SP15   BTC  MDIV"
    CASE 16: RESULTIS "    L0    LG   LG1   LGH  LP16  SP16   NOP CHGCO"
    CASE 17: RESULTIS "    L1    SG   SG1   SGH   SYS    S1    A1   NEG"
    CASE 18: RESULTIS "    L2   LLG  LLG1  LLGH   SWB    S2    A2   NOT"
    CASE 19: RESULTIS "    L3    AG   AG1   AGH   SWL    S3    A3  L1P3"
    CASE 20: RESULTIS "    L4   MUL   ADD    RV    ST    S4    A4  L1P4"
    CASE 21: RESULTIS "    L5   DIV   SUB   RV1   ST1   XCH    A5  L1P5"
    CASE 22: RESULTIS "    L6   REM   LSH   RV2   ST2  GBYT  RVP3  L1P6"
    CASE 23: RESULTIS "    L7   XOR   RSH   RV3   ST3  PBYT  RVP4  L2P3"
    CASE 24: RESULTIS "    L8    SL   AND   RV4  STP3   ATC  RVP5  L2P4"
    CASE 25: RESULTIS "    L9   SL$    OR   RV5  STP4   ATB  RVP6  L2P5"
    CASE 26: RESULTIS "   L10    LL   LLL   RV6  STP5     J  RVP7  L3P3"
    CASE 27: RESULTIS "  FHOP   LL$  LLL$   RTN  GOTO    J$ ST0P3  L3P4"
    CASE 28: RESULTIS "   JEQ   JNE   JLS   JGR   JLE   JGE ST0P4  L4P3"
    CASE 29: RESULTIS "  JEQ$  JNE$  JLS$  JGR$  JLE$  JGE$ ST1P3  L4P4"
    CASE 30: RESULTIS "  JEQ0  JNE0  JLS0  JGR0  JLE0  JGE0 ST1P4 SELLD"
    CASE 31: RESULTIS " JEQ0$ JNE0$ JLS0$ JGR0$ JLE0$ JGE0$    MW SELST"
  }
  LET n = f>>5 & 7
  FOR i = 6*n+1 TO 6*(n+1) DO wrch(s%i)
}



