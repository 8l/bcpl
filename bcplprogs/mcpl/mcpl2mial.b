/*
MCPL to MIAL (MCPL Internal Assembly Language) compiler
for compilation into native code using, for example, mial386.

Copyright: Martin Richards 16 June 1997


It is based on the MCPL to MINTCODE and the BCPL to SIAL compilers.

It uses a reverse polish form of MCODE.

Development of this compiler started on 2 Nov 1992
This version is designed to run interpretively using MINTCODE,
and is similar in structure to the BCPL Cintcode system.
The GLOBAL declaration has been put back into the MCPL and
the syntax of EXTERNAL declarations has been retained but not
implemented.

9/7/97  Separate mcplsyn.b and mcpltrn.b from mcpl2mial.b
        so that they can be shared with the mcpl->mintcode compiler.
*/

SECTION "SYN"

GLOBAL {
//General Interface
errcount:600; errmax:601; fin_p:602; fin_l:603
sourcestream:604; sysprint:605; mcodeout:606
treep:607; treevec:608; findfilename:609

//Syn interface
chbuf:610; ch:611; chcount:612; lineno:613
rch:614; findfileno:615; filelist:616; freefilelist:617
formtree:618; plist:619
}

GET "../bcplprogs/mcplsyn.b"
.


SECTION "TRN"

GLOBAL {
//General Interface
errcount:600; errmax:601; fin_p:602; fin_l:603
sourcestream:604; sysprint:605; mcodeout:606
treep:607; treevec:608; findfilename:609

// Trn interface
translate:620
}

GET "../bcplprogs/mcpltrn.b"
.


SECTION "MCPL2MIAL"

GET "libhdr"

GLOBAL {
//General Interface
errcount:600; errmax:601; fin_p:602; fin_l:603
sourcestream:604; sysprint:605; mcodeout:606
treep:607; treevec:608; findfilename:609

//Syn interface
chbuf:610; ch:611; chcount:612; lineno:613
rch:614; findfileno:615; filelist:616; freefilelist:617
formtree:618; plist:619

// Trn interface
translate:620

// Cg interface
mcodein:630; tostream: 631
codegenerate: 632
}

LET start() = VALOF
{  LET treesize = 200000
   AND argv = VEC 50
   AND argform =
   "FROM/A,TO/K,VER/K,TREE/S,D1/S,D2/S,OENDER/S,"
   LET debug, prtree, bigender = 0, FALSE, ?
   LET stdout = output()

   sysprint := stdout
   selectoutput(sysprint)

   writef("*nMCPL2MIAL 8 July 1997*n")

   IF rdargs(argform, argv, 50)=0 DO {  writes("Bad arguments*n")
                                        RESULTIS 20
                                     }

   fin_p, fin_l := level(), fin
   errmax       := 30
   errcount     := 0
   treevec      := 0
   sourcestream := 0
   mcodeout     := 0
   mcodein      := 0
   tostream     := 0
   filelist     := 0

   prtree := argv!3

   // Code generator options

   bigender := (!"AAA" & 255) = 'A' // =TRUE if running on a bigender
   IF argv!4 DO debug    := debug+1       // D1
   IF argv!5 DO debug    := debug+2       // D2
   IF argv!6 DO bigender := ~bigender     // OENDER

   sourcestream := findinput(argv!0)      // FROM

   IF sourcestream=0 DO {  writef("Trouble with FROM file %s*n", argv!0)
                           errcount := 1
                           GOTO fin
                        }

   selectinput(sourcestream)

   mcodeout := findoutput("MCODE")

   IF mcodeout=0 DO {  writes("Trouble with file MCODE*n")
                       errcount := 1
                       GOTO fin
                    }

   treevec := getvec(treesize)

   IF treevec=0 DO {  writes("Insufficient memory*n")
                      errcount := 1
                      GOTO fin
                   }

   UNLESS argv!2=0 DO       // VER
   {  sysprint := findoutput(argv!2)
      IF sysprint=0 DO
      {  sysprint := stdout
         writef("Trouble with VER file %s*n", argv!2)
         errcount := 1
         GOTO fin
      }
   }

   selectoutput(sysprint)

   {  LET b = VEC 64/bytesperword
      chbuf := b
      FOR i = 0 TO 63 DO chbuf%i := 0
      chcount, lineno := 0, findfileno(argv!0)<<24 | 1
      rch()

      UNTIL ch=endstreamch DO
      {  LET tree = ?
         treep := treevec + treesize

         tree := formtree()
         IF tree=0 BREAK

         writef("*nTree size %n*n", treesize+treevec-treep)

         IF prtree DO {  writes("Parse Tree*n")
                         plist(tree, 0, 20)
                         newline()
                      }

         UNLESS errcount=0 GOTO fin
         selectoutput(mcodeout)
         translate(tree)
         selectoutput(sysprint)
      }
   }

   selectinput(sourcestream);  endread();   sourcestream := 0
   selectoutput(mcodeout);     endwrite();  mcodeout     := 0

   selectoutput(sysprint)

   UNLESS errcount=0 GOTO fin

   mcodein := findinput("MCODE")
   IF mcodein=0 DO
   {  writef("Trouble reading file MCODE*n")
      errcount := 1
      GOTO fin
   }

   IF argv!1=0 DO argv!1 := "MIAL"

   tostream := findoutput(argv!1)
   IF tostream=0 DO
   {  writef("Trouble with code file %s*n", argv!1)
      errcount := 1
      GOTO fin
   }

   selectinput(mcodein)
   codegenerate(treevec, treesize, debug, bigender)

   selectoutput(sysprint)

fin:
   UNLESS treevec=0       DO freevec(treevec)
   UNLESS sourcestream=0  DO {  selectinput(sourcestream); endread()  }
   UNLESS mcodeout=0      DO {  selectoutput(mcodeout);    endwrite() }
   UNLESS mcodein=0       DO {  selectinput(mcodein);      endread()  }
   UNLESS tostream=0      DO {  selectoutput(tostream)
                                UNLESS tostream=stdout DO  endwrite() }
   UNLESS sysprint=stdout DO {  selectoutput(sysprint);    endwrite() }
   freefilelist(filelist)
   selectoutput(stdout)
   UNLESS errcount=0 RESULTIS 20
   RESULTIS 0
}

// Start of the MCODE->MIAL Codegenerator

GET "libhdr"

MANIFEST {
// Object module item types.
t_hunk  = 2000       // hunk   n  w1 ... wn
t_reloc = 2001       // reloc  n  a1 ... an
t_end   = 2002       // end

modword   = #xFDDF   // MODULE and Entry marker words.
entryword = #xDFDF

               // MCODE operators
s_ln=1
s_true=5
s_false=6
s_query=7

s_lp=10
s_lg=11

s_llp=13
s_llg=14

s_sp=16
s_sg=17
s_lf=18
s_lx=19

s_neg=21
s_abs=22
s_not=23
s_bitnot=24

s_callc=29
s_call=30
s_indw=31
s_indw0=32
s_indb=33
s_indb0=34
s_lsh=35  // same order as op:= operators
s_rsh=36
s_mult=37
s_div=38
s_mod=39
s_bitand=40
s_xor=41
s_plus=42
s_sub=43
s_bitor=44

s_eq=45
s_ne=46
s_le=47
s_ge=48
s_ls=49
s_gr=50
s_rel=51

s_ptr=59
s_ll=60
s_lll=61
s_sl=62
s_lpath=63
s_llpath=64
s_spath=65
s_stw=66
s_stb=67
s_lvindw=68
s_cpr=69

s_jt=70
s_jf=71
s_lab=72
s_stack=73

s_dup=79
s_lr=80
s_str=81
s_jump=82
s_dlab=83
s_dw=84
s_db=85
s_dl=86
s_ds=87

s_inc1b=90
s_inc4b=91
s_dec1b=92
s_dec4b=93
s_inc1a=94
s_inc4a=95
s_dec1a=96
s_dec4a=97

s_goto=103
s_raise=104
s_handle=105

s_match=120
s_return=124

s_module=145
s_endmodule=146

s_global=150
s_fun=151
s_cfun=152
s_endfun=153
s_unhandle=156
s_line=157
s_file=158
s_setargs=159
s_fnargs=160
s_locs=161

s_none=200

             //  Selectors
h1=0; h2=1; h3=2; h4=3

hashtabsize=63
}

GLOBAL {
cgmodules   : 401
rdn         : 402
rdl         : 403
rdgn        : 404
rdstr       : 405
newlab      : 406
checklab    : 407
cgerror     : 408

initstack   : 410
stack       : 411
store       : 412
scan        : 413
cgpendingop : 414

loadba      : 416
setba       : 417

genxch      : 420
genatb      : 421

loada       : 422
push        : 423
loadboth    : 424
inreg_a     : 425
inreg_b     : 426
addinfo_a   : 427
addinfo_b   : 428
pushinfo    : 429
xchinfo     : 430
atbinfo     : 431
btainfo     : 432

forget_a    : 435
forget_b    : 436
forgetall   : 437
forgetvar   : 438
forgetallvars: 439

iszero      : 440
storet      : 441
storeshared : 442

loadt       : 443
lose1       : 444
swapargs    : 445
cgstw       : 446
storein     : 447
cgindw0     : 448

cginc       : 449
cgplus      : 450
cgaddk      : 451
cgglobal    : 452
cgentry     : 453
cgcall      : 455
cgjump      : 457

jmpfn       : 458
jfn0        : 459
revjfn      : 460
compjfn     : 461
prepj       : 462
cgraise     : 463

cgstatics   : 477
getblk      : 478
freeblk     : 479
freeblks    : 480

initdatalists : 481

genfp       : 500
genfkp      : 501
genfkp      : 502
genfg       : 503
genfkg      : 504
genfpg      : 505
genfk       : 506
genfw       : 507
genfl       : 508
genflk      : 509
genfkl      : 510
genfm       : 511
genfmw      : 512

genf        : 520
geng        : 521
genc        : 522
genk        : 523
genw        : 524
genl        : 525

cgrelop     : 530

checkspace  : 531

dboutput    : 540
wrkn        : 541
wrcode      : 542

// Global variables.
procdepth   : 550

ssp         : 551
tempt       : 552
tempv       : 553

arg1        : 554
arg2        : 555
debug       : 556
bigender    : 557

ch          : 560
op          : 561
pendingop   : 562
mlabnumber  : 563
incode      : 565

lineno      : 570
progsize    : 571
maxgn       : 572
maxssp      : 573

info_a      : 575
info_b      : 576

clist       : 580
cliste      : 581

dpbase      : 590
dp          : 591
freelist    : 592

hashtab     : 595
charv       : 596
lookup      : 597
newvec      : 598
}


MANIFEST
{
// Value descriptors.
k_none=0
k_numb=1   // numbers in the range -#xFFFFFF to #xFFFFFF
k_lw=2     // label addressing larger constants
k_fnlab=3
k_lvloc=4; k_lvglob=5; k_lvlab=6;
k_a=8; k_b=9; k_c=10

k_ext=11
k_loc=12; k_glob=13; k_lab=14;

k_loci=15;  k_lvloci=16    //  <27-bits> loci    ie P!<27-bits>!n
k_globi=17; k_lvglobi=18   //  <27-bits> globi   ie G!<27-bits>!n
k_labi=19;  k_lvlabi=20    //  <27-bits> labi    ie L<27-bits>!n

swapped=TRUE; notswapped=FALSE
}

MANIFEST {
// MIAL op codes and directives

f_lp=      1
f_lg=      2
f_ll=      3

f_llp=     4
f_llg=     5
f_lll=     6
f_lf=      7
f_lw=      8

f_l=      10
f_lm=     11

f_sp=     12
f_sg=     13
f_sl=     14

f_ap=     15
f_ag=     16
f_a=      17
f_s=      18

f_lkp=    20
f_lkg=    21
f_rv=     22
f_rvp=    23
f_rvk=    24
f_st=     25
f_stp=    26
f_stk=    27
f_stkp=   28
f_stkg=   29
f_xst=    30

f_stb=    31
f_lvind=  32
f_indb=   33
f_indb0=  34
f_indw=   35

f_k=      36
f_kpg=    37

f_neg=    38
f_not=    39
f_abs=    40

f_xdiv=   41
f_xmod=   42
f_xsub=   43

f_mul=    45
f_div=    46
f_mod=    47
f_add=    48
f_sub=    49

f_eq=     50
f_ne=     51
f_ls=     52
f_gr=     53
f_le=     54
f_ge=     55
f_eq0=    56
f_ne0=    57
f_ls0=    58
f_gr0=    59
f_le0=    60
f_ge0=    61

f_lsh=    65
f_rsh=    66
f_and=    67
f_or=     68
f_xor=    69
f_lshk=   70
f_rshk=   71

f_xch=    80
f_atb=    81
f_atc=    82
f_bta=    83
f_btc=    84
f_cta=    85
f_atblp=  86
f_atblg=  87
f_atbll=  88
f_atbl=   89

f_j=      90
f_rtn=    91

f_ikp=    93
f_ikg=    94
f_ikl=    95
f_ip=     96
f_ig=     97
f_il=     98

f_jeq=    100
f_jne=    101
f_jls=    102
f_jgr=    103
f_jle=    104
f_jge=    105
f_jeq0=   106
f_jne0=   107
f_jls0=   108
f_jgr0=   109
f_jle0=   110
f_jge0=   111

f_brk=    120
f_nop=    121
f_chgco=  122
f_mdiv=   123
f_sys=    124

f_inc1b=  130
f_inc4b=  131
f_dec1b=  132
f_dec4b=  133
f_inc1a=  134
f_inc4a=  135
f_dec1a=  136
f_dec4a=  137

f_hand =  140
f_unh  =  141
f_raise=  142

f_module=   150
f_modstart= 151
f_modend=   152
f_global=   153

f_const=    155

f_lab=      157
f_entry=    158

f_dlab=     160
f_dw=       161
f_db=       162
f_dl=       163
f_ds=       164
}


LET codegenerate(workspace, workspacesize, dbg, bige) BE
{  writes("CG2MIAL 20 May 1997*n")

   IF workspacesize<2000 DO {  cgerror("Too little workspace")
                               errcount := errcount+1
                               longjump(fin_p, fin_l)
                            }

   // Set the codegenerator options
   debug, bigender := dbg, bige

   lineno, progsize := 0, 0

   op := rdn()

   selectoutput(tostream)
   cgmodules(workspace, workspacesize)
   selectoutput(sysprint)
   writef("Program size = %n Fcodes*n", progsize)
}


AND cgmodules(workvec, vecsize) BE UNTIL op=0 DO
{  LET p = workvec
   dpbase := p
   dp := workvec+vecsize

   tempv := newvec(300)
   tempt := tempv+300

   hashtab := newvec(hashtabsize)
   FOR i = 0 TO hashtabsize DO hashtab!i := 0
   charv := newvec(1024)  // For strings, file names etc.

   mlabnumber := 0
   incode := TRUE
   maxssp := 0
   maxgn  := 0
   procdepth := 0
   info_a, info_b := 0, 0
   initstack(3)
   initdatalists()

   WHILE op=s_file DO {  rdn(); rdstr(); op := rdn() }

   genf(f_modstart)
   IF op=s_module DO
   {  LET n = rdn()
      genfk(f_module, n)
      FOR i = 1 TO n DO genc(rdn())
      op := rdn()
   }

   incode := FALSE
   scan()
   op := rdn()
   incode := TRUE
   genf(f_modend)
}


// Read an MCODE operator or argument.
AND rdn() = VALOF
{  LET a, neg = 0, FALSE
   ch := rdch() REPEATWHILE ch='*s' | ch='*n'
   IF ch=endstreamch RESULTIS 0
   IF ch='-' DO {  neg := TRUE; ch := rdch() }
   WHILE '0'<=ch<='9' DO {  a := 10*a + ch - '0'; ch := rdch()  }
   IF neg RESULTIS -a
   RESULTIS a
}

// Read in an MCODE label.
AND rdl() = VALOF
{  LET lab = rdn()
   RESULTIS lab
}

// Read in a global number.
AND rdgn() = VALOF
{  LET gn = rdn()
   IF maxgn<gn DO maxgn := gn
   RESULTIS gn
}


// Read in an MCODE string (known to have length<=255)
AND rdstr() = VALOF
{  LET len = rdn() & 255
   charv%0 := len
   FOR i = 1 TO len DO charv%i := rdn()
   RESULTIS lookup(charv)
}

AND lookup(str) = VALOF
{  LET len, i = str%0, 0
   LET hashval = 19609 // This and 31397 are primes.
   LET node = ?
   FOR i = 0 TO len DO hashval := (hashval NEQV str%i) * 31397
   hashval := (hashval>>1) REM hashtabsize

   node := hashtab!hashval

   UNTIL node=0 | i>len TEST (@h2!node)%i=str%i
                        THEN i := i+1
                        ELSE node, i := h1!node, 0

   IF node=0 DO
   {  node := newvec(len/bytesperword+2)
      h1!node := hashtab!hashval
      FOR i = 0 TO len DO (@h2!node)%i := str%i
      hashtab!hashval := node
   }

   RESULTIS node+1
}

AND newvec(upb) = VALOF
{  dp := dp-upb-1
   RESULTIS dp
}

// Generate next label number.
AND newlab() = VALOF
{  mlabnumber := mlabnumber+1
   RESULTIS mlabnumber
}


AND cgerror(mes, a) BE
{  writes("*nError: ")
   writef(mes, a)
   newline()
   errcount := errcount+1
   IF errcount>errmax DO {  writes("Too many errors*n")
                            longjump(fin_p, fin_l)
                         }
}


// Initialize the simulated stack (SS).
// SS cells are of the form [k, n, i, s]
// where k    is the kind k_loc etc
//       n, i are arguments
//       s    is the position rel to P of this item
LET initstack(n) BE
{  arg2, arg1, ssp := tempv, tempv+3, n
   pendingop := s_none
   h1!arg2, h2!arg2, h3!arg2 := k_loc, ssp-2, ssp-2
   h1!arg1, h2!arg1, h3!arg1 := k_loc, ssp-1, ssp-1
   IF maxssp<ssp DO maxssp := ssp
}


// Move simulated stack pointer to n.
AND stack(n) BE
{  IF maxssp<n DO maxssp := n
   IF n>=ssp+4 DO {  store(0, ssp-1)
                     initstack(n)
                     RETURN
                  }

   WHILE n>ssp DO loadt(k_loc, ssp, 0)

   UNTIL n=ssp DO
   {  IF arg2=tempv DO
      {  TEST n=ssp-1
         THEN {  ssp := n
                 h1!arg1, h2!arg1 := h1!arg2, h2!arg2
                 h4!arg1 := ssp-1
                 h1!arg2, h2!arg2, h3!arg2 := k_loc, ssp-2, ssp-2
              }
         ELSE initstack(n)
         RETURN
      }

      arg1, arg2, ssp := arg1-3, arg2-3, ssp-1
   }
}

// Store all SS items from s1 to s2 in their true
// locations on the stack.
// It may corrupt both registers A and B.
AND store(s1, s2) BE FOR p = tempv TO arg1 BY 3 DO
                     {  LET s = h3!p
                        IF s>s2 RETURN
                        IF s>=s1 DO storet(p)
                     }



// Store any SS items holding values depending on (k,n)
// where k=k_loc,  k_glob or k_lab in their temporary stack locations.
// It may corrupt both registers A and B.
// It is only called from storein.
AND storeshared(k, n, t, a) BE
  FOR p = t TO a BY 3 IF shared(k, n, h1!p, h2!p) DO storet(p)

AND shared(k, n, k1, n1) = VALOF
{ IF k1<k_ext RESULTIS FALSE              // (k1,n1) not variable
  IF k1>=k_loci | k>=k_loci RESULTIS TRUE // one is indirect
  IF k=k1 & n=n1 RESULTIS TRUE            // same simple variable
  RESULTIS FALSE                          // different simple variables
}

AND scan() BE
{  IF debug>1 DO {  dboutput()
                    writef("op=%i3/%i3*n", op, pendingop)
                 }

   SWITCHON op INTO

   {  DEFAULT:         cgerror("Bad MCODE op %n*n", op); ENDCASE

      CASE 0:          RETURN

// lx n c1 ... cn     n<=255
      CASE s_lx:       loadt(k_ext, rdstr());            ENDCASE

// lpath n i          load p!n!i      n~=0
      CASE s_lpath:   {  LET n = rdn()
                         LET i = rdn()
                         loadt(k_loci + (n<<5), i)
                         ENDCASE
                      }

// llpath n i         load @ p!n!i      n~=0
      CASE s_llpath:  {  LET n = rdn()
                         LET i = rdn()
                         loadt(k_lvloci + (n<<5), i)
                         ENDCASE
                      }

// spath n i          store p!n!i      n~=0
      CASE s_spath:   {  LET n = rdn()
                         LET i = rdn()
                         storein(k_loci + (n<<5), i)
                         ENDCASE
                      }

// setargs len argpos
      CASE s_setargs: {  LET n = rdn()
                         LET pos = rdn()
                         cgpendingop()
                         FOR i = n-1 TO 0 BY -1 DO
                         {  loada(arg1)
                            genfp(f_sp, pos+i)
                            stack(ssp-1)
                         }
                         ENDCASE
                      }

      CASE s_stw:      cgstw()
                       ENDCASE

      CASE s_stb:      cgpendingop()
                       loadba(arg2, arg1)
                       genf(f_stb)
                       stack(ssp-2)
                       ENDCASE

      CASE s_lvindw:
      CASE s_indw:
      CASE s_indw0:
      CASE s_indb0:
      CASE s_indb:
      CASE s_mult:CASE s_div:CASE s_mod:
      CASE s_plus:CASE s_sub:
      CASE s_eq: CASE s_ne:
      CASE s_ls:CASE s_gr:CASE s_le:CASE s_ge:
      CASE s_lsh:CASE s_rsh:
      CASE s_bitand:CASE s_bitor:CASE s_xor:
                       cgpendingop()
                       pendingop := op
                       ENDCASE

      CASE s_str:      cgpendingop()
                       loada(arg1)
                       genf(f_atc)
                       stack(ssp-1);            ENDCASE
      CASE s_cpr:      cgpendingop()
                       loada(arg1)
                       genf(f_atc);             ENDCASE
      CASE s_dup:      cgpendingop()
                       loada(arg1)
                       storet(arg1)
                       loadt(k_a, 0);           ENDCASE
      CASE s_lr:       forgetall()
                       genf(f_cta)
                       loadt(k_a, 0);           ENDCASE

      CASE s_ptr:      loadt(k_loc, ssp);       ENDCASE

      CASE s_true:     loadt(k_numb, -1);       ENDCASE
      CASE s_false:    loadt(k_numb, 0);        ENDCASE
      CASE s_query:    loadt(k_loc, ssp);       ENDCASE
      CASE s_stack:cgpendingop(); stack(rdn()); ENDCASE

      CASE s_inc1b:    cginc(f_inc1b);          ENDCASE
      CASE s_inc4b:    cginc(f_inc4b);          ENDCASE
      CASE s_dec1b:    cginc(f_dec1b);          ENDCASE
      CASE s_dec4b:    cginc(f_dec4b);          ENDCASE
      CASE s_inc1a:    cginc(f_inc1a);          ENDCASE
      CASE s_inc4a:    cginc(f_inc4a);          ENDCASE
      CASE s_dec1a:    cginc(f_dec1a);          ENDCASE
      CASE s_dec4a:    cginc(f_dec4a);          ENDCASE

      CASE s_bitnot:CASE s_not:CASE s_neg:CASE s_abs:
                       cgpendingop()
                       pendingop := op
                       ENDCASE

      CASE s_unhandle: genf(f_unh)
                       ENDCASE

      CASE s_return:   cgpendingop()
                       genf(f_rtn)
                       incode := FALSE
                       ENDCASE

      CASE s_fnargs:
                    {  LET a = rdn()
                       IF a>0 DO addinfo_a(k_loc, 3)
                       stack(3+a)
                       ENDCASE
                    }

      CASE s_match:    rdn(); rdn();  // ??????????????????????????
                       store(0, ssp)
                       //cgerror("Unimplemented op in scan %n*n", op)
                       ENDCASE

      CASE s_raise:    cgraise(rdn())
                       incode := FALSE
                       ENDCASE

      CASE s_locs:     stack(ssp+rdn());           ENDCASE

      CASE s_lp:       loadt(k_loc, rdn());        ENDCASE
      CASE s_lg:       loadt(k_glob, rdgn());      ENDCASE
      CASE s_llp:      loadt(k_lvloc, rdn());      ENDCASE
      CASE s_llg:      loadt(k_lvglob, rdgn());    ENDCASE

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

      CASE s_sp:       storein(k_loc,  rdn());     ENDCASE
      CASE s_sg:       storein(k_glob, rdgn());    ENDCASE

// call k             call a procedure incrementing P by k
      CASE s_call:     cgcall(rdn())
                       ENDCASE

      CASE s_jump:     cgpendingop()
                       store(0, ssp-1)
                       forgetall()
                       genfl(f_j, rdl());          ENDCASE

      CASE s_handle:   cgpendingop()
                       store(0, ssp-1)
                       forgetall()
                       genfp(f_llp, ssp)
                       genfl(f_hand, rdl())
                       stack(ssp+3)
                       ENDCASE

      CASE s_jt:       cgjump(TRUE, rdl());        ENDCASE
      CASE s_jf:       cgjump(FALSE, rdl());       ENDCASE

      CASE s_ll:       loadt(k_lab, rdl());        ENDCASE
      CASE s_lll:      loadt(k_lvlab, rdl());      ENDCASE

      CASE s_lf:       loadt(k_fnlab, rdl());      ENDCASE

      CASE s_sl:       storein(k_lab, rdl());      ENDCASE

      CASE s_lab:      cgpendingop()
                       store(0, ssp-1)
                       forgetall()
                       incode := procdepth>0
                       genfl(f_lab, rdl())
                       incode := TRUE
                       ENDCASE

      CASE s_fun:   {  LET lab = rdl()
                       LET name = rdstr()
                       procdepth := procdepth+1
                       cgentry(lab, name)
                       ENDCASE
                    }

      CASE s_cfun:  {  LET lab = rdl()
                       LET name = rdstr()
                       LET type = rdstr()
                       procdepth := procdepth+1
                       cgerror("Unimplemented op in scan %n*n", op)
                       //cgcentry(lab, name, type)
                       ENDCASE
                    }

      CASE s_callc: {  rdn()
                       rdstr()
                       cgerror("Unimplemented op in scan %n*n", op)
                       ENDCASE
                    }

      CASE s_endfun:   procdepth := procdepth-1
                       ENDCASE

      CASE s_global:   cgglobal(rdn());      ENDCASE

      CASE s_endmodule: RETURN

      CASE s_dlab:     incode := TRUE
                       genfl(f_dlab, rdl()); ENDCASE

      CASE s_dw:       genfw(f_dw, rdn());   ENDCASE
      CASE s_db:       genfk(f_db, rdn());   ENDCASE
      CASE s_dl:       genfl(f_dl, rdl());   ENDCASE
      CASE s_ds:       genfk(f_ds, rdn());   ENDCASE


      CASE s_line:  {  LET fno = rdn()
                       LET ln  = rdn()
                       lineno := fno<<24 | ln
                       IF debug>0 DO writef("// line %n*n", ln)
                       ENDCASE
                    }
   }

   op := rdn()
} REPEAT


// Compiles code to deal with any pending op.
LET cgpendingop() BE
{  LET f = 0
   LET sym = TRUE
   LET pndop = pendingop
   pendingop := s_none

   SWITCHON pndop INTO
   {  DEFAULT:      cgerror("Bad pendingop %n", pndop)

      CASE s_none:  RETURN

      CASE s_abs:   loada(arg1)
                    genf(f_abs)
                    forget_a()
                    RETURN

      CASE s_neg:   loada(arg1)
                    genf(f_neg)
                    forget_a()
                    RETURN

      CASE s_bitnot:
      CASE s_not:   loada(arg1)
                    genf(f_not)
                    forget_a()
                    RETURN

      CASE s_lvindw: loadba(arg2, arg1)
                     genf(f_lvind)
                     lose1(k_a, 0)
                     forget_a()
                     RETURN

      CASE s_indw0: cgindw0()
                    //loada(arg1)
                    //genf(f_rv)
                    //forget_a()
                    RETURN

      CASE s_indb0: loada(arg1)
                    genf(f_indb0)
                    forget_a()
                    RETURN

      CASE s_eq:
      CASE s_ne:
      CASE s_ls:
      CASE s_gr:
      CASE s_le:
      CASE s_ge:    cgrelop(pndop)
                    RETURN

      CASE s_sub:   UNLESS k_numb=h1!arg1 DO
                    {  f, sym := f_sub, FALSE
                       ENDCASE
                    }
                    h2!arg1 := -h2!arg1

      CASE s_plus:  cgplus(); RETURN

      CASE s_lsh:   IF h1!arg1=k_numb DO
                    { loada(arg2)
                      genfk(f_lshk, h2!arg1)
                      f := 0
                      ENDCASE
                    }
                    f, sym := f_lsh, FALSE;  ENDCASE

      CASE s_rsh:   IF h1!arg1=k_numb DO
                    { loada(arg2)
                      genfk(f_rshk, h2!arg1)
                      f := 0
                      ENDCASE
                    }
                    f, sym := f_rsh, FALSE;  ENDCASE

      CASE s_indw:  f, sym := f_indw, FALSE; ENDCASE
      CASE s_indb:  f      := f_indb;        ENDCASE
      CASE s_mult:  f      := f_mul;         ENDCASE
      CASE s_div:   f, sym := f_div, FALSE;  ENDCASE
      CASE s_mod:   f, sym := f_mod, FALSE;  ENDCASE
      CASE s_bitand:f      := f_and;         ENDCASE
      CASE s_bitor: f      := f_or;          ENDCASE
      CASE s_xor:   f      := f_xor;         ENDCASE
   }

   UNLESS f=0 DO { TEST sym THEN loadboth(arg2, arg1)
                            ELSE loadba(arg2, arg1)
                   genf(f)
                 }
   forget_a()
   lose1(k_a,0)
}



LET loada(x) BE
// Loada compiles code to evaluate SS item x into A
// The contents of B is left unchanged
{  LET k, n = h1!x, h2!x

   IF k=k_a RETURN

   // Dump A register if currently in use somewhere else.
   FOR t = arg1 TO tempv BY -3 IF h1!t=k_a DO {  storet(t); BREAK }

   TEST inreg_a(k, n)
   THEN { h1!x := k_a; RETURN }
   ELSE IF inreg_b(k, n) DO {  genf(f_bta)
                               h1!x := k_a
                               btainfo()
                               RETURN
                            }

   k, n := h1!x, h2!x // Might have been changed by storet.
   SWITCHON k & 31 INTO
   {  DEFAULT:       cgerror("in loada %n", k)

      CASE k_a:      RETURN

      CASE k_numb:   TEST n>=0 THEN genfk(f_l,  n)
                               ELSE genfk(f_lm,-n)
                     ENDCASE
      CASE k_lw:     genfm(f_lw, n);            ENDCASE
      CASE k_fnlab:  genfl(f_lf, n);            ENDCASE

//    CASE k_ext:    genfx(f_lx, n);            ENDCASE

      CASE k_loc:    genfp(f_lp, n);            ENDCASE
      CASE k_glob:   genfg(f_lg, n);            ENDCASE
      CASE k_lab:    genfl(f_ll, n);            ENDCASE

      CASE k_lvloc:  genfp(f_llp, n);           ENDCASE
      CASE k_lvglob: genfg(f_llg, n);           ENDCASE
      CASE k_lvlab:  genfl(f_lll, n);           ENDCASE

      CASE k_loci:   genfkp(f_lkp, n, k>>5);    ENDCASE
      CASE k_globi:  genfkg(f_lkg, n, k>>5);    ENDCASE
      CASE k_labi:   genfl(f_ll, k>>5)
                     genfk(f_rvk, n);           ENDCASE

      CASE k_lvloci: genfp(f_lp, k>>5)
                     cgaddk(4*n);               ENDCASE
      CASE k_lvglobi:genfg(f_lg, h1!x>>5)
                     cgaddk(4*n);               ENDCASE
      CASE k_lvlabi: genfl(f_ll, h1!x>>5)
                     cgaddk(4*n);               ENDCASE
   }

   // An instruction to load the A register has just been compiled.
   forget_a()
   addinfo_a(h1!x, h2!x)
   h1!x := k_a
}

AND loadba(x, y) BE IF loadboth(x, y)=swapped DO genxch(x, y)

AND setba(x, y) BE
{ UNLESS x=0 DO h1!x := k_a
  UNLESS y=0 DO h1!y := k_a
}

AND genxch(x, y) BE { genf(f_xch); xchinfo(); setba(x, y) }

AND genatb(x, y) BE { genf(f_atb); atbinfo(); setba(x, y) }

AND loadboth(x, y) = VALOF
// Compiles code to cause
//   either    x -> [B]  and  y -> [A]
//             giving result NOTSWAPPED
//   or        x -> [A]  and  y -> [B]
//             giving result SWAPPED.
// LOADBOTH only swaps if this saves code.
{  // First ensure that no other stack item uses reg A.
   FOR t = tempv TO arg1 BY 3 DO
       IF h1!t=k_a UNLESS t=x | t=y DO storet(t)

   {  LET xa, ya = inreg_a(h1!x, h2!x), inreg_a(h1!y, h2!y)
      AND xb, yb = inreg_b(h1!x, h2!x), inreg_b(h1!y, h2!y)

      IF xb & ya DO {  setba(x,y);               RESULTIS notswapped }
      IF xa & yb DO {  setba(y,x);               RESULTIS swapped    }
      IF xa & ya DO {  genatb(x,y);              RESULTIS notswapped }
      IF xb & yb DO {  genxch(0,y); genatb(x,y); RESULTIS notswapped }

      IF xa DO {               push(x,y); RESULTIS notswapped }
      IF ya DO {               push(y,x); RESULTIS swapped    }
      IF xb DO {  genxch(0,x); push(x,y); RESULTIS notswapped }
      IF yb DO {  genxch(0,y); push(y,x); RESULTIS swapped    }

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
{  LET p = info_a
   IF k=k_a RESULTIS TRUE
   UNTIL p=0 DO {  IF k=h2!p & n=h3!p RESULTIS TRUE
                   p := !p
                }
   RESULTIS FALSE
}

AND inreg_b(k, n) = VALOF
{  LET p = info_b
   IF k=k_b RESULTIS TRUE
   UNTIL p=0 DO {  IF k=h2!p & n=h3!p RESULTIS TRUE
                   p := !p
                }
   RESULTIS FALSE
}

AND addinfo_a(k, n) BE info_a := getblk(info_a, k, n)

AND addinfo_b(k, n) BE info_b := getblk(info_b, k, n)

AND pushinfo(k, n) BE
{  forget_b()
   info_b := info_a
   info_a := getblk(0, k, n)
}

AND xchinfo() BE
{  LET t = info_a
   info_a := info_b
   info_b := t
}

AND atbinfo() BE
{  LET p = info_a
   forget_b()
   UNTIL p=0 DO {  addinfo_b(h2!p, h3!p); p := !p }
}

AND btainfo() BE
{  LET p = info_b
   forget_a()
   UNTIL p=0 DO {  addinfo_a(h2!p, h3!p); p := !p }
}

AND forget_a() BE {  freeblks(info_a); info_a := 0 }

AND forget_b() BE {  freeblks(info_b); info_b := 0 }

AND forgetall() BE {  forget_a(); forget_b() }

// Forgetvar is called just after compiling an assigment to a simple
// variable (k, n).  k is k_loc, k_glob, k_ext or k_lab.
// Information about matching simple variables must be thrown away.
// Information about indirect values must be thrown away.
// The treatment of k_lvloci, k_lvglobi and k_lvlabi could be improved.
AND forgetvar(k, n) BE
{  LET p = info_a
   UNTIL p=0 DO {  LET op = h2!p
                   IF k=op & h3!p=n | op>=k_loci DO h2!p := k_none
                   p := !p
                }
   p := info_b
   UNTIL p=0 DO {  LET op = h2!p
                   IF k=op & h3!p=n | op>=k_loci DO h2!p := k_none
                   p := !p
                }
}

AND forgetallvars() BE  // After compiling an indirect assignment.
{  LET p = info_a
   UNTIL p=0 DO {  IF h2!p>=k_ext DO h2!p := k_none
                   p := !p
                }
   p := info_b
   UNTIL p=0 DO {  IF h2!p>=k_ext DO h2!p := k_none
                   p := !p
                }
}

AND iszero(a) = h1!a=k_numb & h2!a=0 -> TRUE, FALSE

// Store the value of a SS item in its true stack location.
AND storet(x) BE
{  LET s = h3!x
   IF h1!x=k_loc & h2!x=s RETURN
   loada(x)
   genfp(f_sp, s)
   forgetvar(k_loc, s)
   addinfo_a(k_loc, s)
   h1!x, h2!x := k_loc, s
}

// Load an item (k,n) onto the SS. It may move SS items.
AND loadt(k, n) BE
{  cgpendingop()
   TEST arg1+3=tempt
   THEN {  storet(tempv)  // SS stack overflow.
           FOR t = tempv TO arg2+2 DO t!0 := t!3
        }
   ELSE arg2, arg1 := arg2+3, arg1+3
   h1!arg1,h2!arg1,h3!arg1 := k,n,ssp
   ssp := ssp + 1
   IF maxssp<ssp DO maxssp := ssp
}


// Replace the top two SS items by (k,n) and set PENDINGOP=S_NONE.
AND lose1(k, n) BE
{  ssp := ssp - 1
   TEST arg2=tempv
   THEN {  h1!arg2, h2!arg2 := k_loc, ssp-2
           h3!arg2 := ssp-2
        }
   ELSE {  arg1 := arg2
           arg2 := arg2-3
        }
   h1!arg1, h2!arg1, h3!arg1 := k, n, ssp-1
   pendingop := s_none
}

AND swapargs() BE
{  LET k, n = h1!arg1, h2!arg1
   h1!arg1, h2!arg1 := h1!arg2, h2!arg2
   h1!arg2, h2!arg2 := k, n
}

AND cgstw() BE
{  cgpendingop()
   loadba(arg1, arg2)
   genf(f_st)
   stack(ssp-2)
   forgetallvars()
}

/*
AND cgstw() BE
{  //      !(             <arg1>) := <arg2>
   //      !(       pndop <arg1>) := <arg2>
   //  or  !(<arg2> pndop <arg1>) := <arg3>
   IF pendingop=s_plus DO
   {  //  !(<arg2>+<arg1>) := <arg3>
      IF k_numb=h1!arg1 DO
      {  LET offset = h2!arg1         // <arg2>!offset := <arg3>
         LET k, n = h1!arg2, h2!arg2
         stack(ssp-1)
         // offset!<arg1> := <arg2>
         pendingop := s_none

         SWITCHON k INTO
         { DEFAULT:     IF loadboth(arg2, arg1)=swapped DO
                        { IF offset=0 DO { genf(f_xst)
                                           stack(ssp-2)
                                           forgetallvars()
                                           RETURN
                                         }
                           genf(f_xch)
                           xchinfo()
                        }
                        // offset!A := B
                        genfk(f_stk, offset)
                        stack(ssp-2)
                        forgetallvars()
                        RETURN

           CASE k_loc:  stack(ssp-1)
                        // offset!Pn := <arg1>
                        storein(k_loci+(n<<5), offset)
                        RETURN
           CASE k_glob: stack(ssp-1)
                        // offset!Gn := <arg1>
                        storein(k_globi+(n<<5), offset)
                        RETURN
           CASE k_lab:  stack(ssp-1)
                        // offset!Ln := <arg1>
                        storein(k_labi+(n<<5), offset)
                        RETURN
         }
      }

      // <arg1>!<arg2> := <arg3>
      IF h1!arg2=k_loc DO swapargs()
      IF h1!arg1=k_loc DO
      {  LET n = h2!arg1              // Pn!<arg2> := <arg3>
         stack(ssp-1)
         pendingop := s_none
         // Pn!<arg1> := <arg2>
         IF loadba(arg2, arg1) = swapped DO
         { genf(f_xch}
           xchinfo()
         }
         // Pn!A := B
         genfp(f_stp, n)
         stack(ssp-2)
         forgetallvars()
         RETURN
      }

      UNLESS arg2=tempv DO
      {  LET arg3 = arg2 - 3
         IF h1!arg3=k_a DO
         {  IF h1!arg2=k_loc |
               h1!arg2=k_glob |
               h1!arg2=k_numb & bits24(h2!arg2) DO swapargs()
            IF h1!arg1=k_loc |
               h1!arg1=k_glob |
               h1!arg1=k_numb & bits24(h2!arg1) DO
            // Optimize the case  <arg2>!<arg1> := <arg3>
            // where <arg3> is already in A
            // and <arg1> is a local, a global or a number.
            {  genf(f_atb)  // Put <arg3> into B
               h1!arg3 := k_b
               cgplus()     // Compiles an A, AP or AG instr.
               genf(f_st)
               stack(ssp-2)
               forgetallvars()
               RETURN
            }
         }
      }
   }

   cgpendingop()

   // !<arg1> := <arg2>

   {  LET k, n = h1!arg1, h2!arg1

      IF k=k_glob & t=0 DO {  loada(arg2)
                              genfkg(f_stkg, 0, n)
                              stack(ssp-2)
                              forgetallvars()
                              RETURN
                           }

      IF k=k_loc & t<=3 DO {  loada(arg2)
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
*/

// Store the top item of the SS in (k,n).
AND storein(k, n) BE
// k is k_loc, k_loci, k_glob, k_globi, k_lab or k_labi.
{  IF pendingop=s_sub & h1!arg1=k_numb DO
   { pendingop := s_plus
     h2!arg1 := - h2!arg1
   }
   IF pendingop=s_plus DO
   { IF h1!arg1=k & h2!arg1=n & (k=k_loc | k=k_glob | k=k_lab) DO swapargs()
     IF h1!arg2=k & h2!arg2=n & (k=k_loc | k=k_glob | k=k_lab) DO
     { // we have <arg2> := <arg2> + <arg1>
       // where <arg2> is local, global or static
       LET val = h2!arg1
       pendingop := s_none
       storeshared(k, n, tempv, arg2-3)
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
   storeshared(k, n, tempv, arg2)
   loada(arg1)

   SWITCHON k&31 INTO
   {  DEFAULT:      cgerror("in storein %n", k&31)
      CASE k_loc:   genfp(f_sp, n);          ENDCASE
      CASE k_glob:  genfg(f_sg, n);          ENDCASE
      CASE k_lab:   genfl(f_sl, n);          ENDCASE
      CASE k_loci:  genfkp(f_stkp, n, k>>5); ENDCASE
      CASE k_globi: genfkg(f_stkg, n, k>>5); ENDCASE
      CASE k_labi:  genf(f_atb)
                    genfl(f_ll, k>>5)
                    genfk(f_stk, n);         ENDCASE
   }
   forgetvar(k, n)
   addinfo_a(k, n)
   stack(ssp-1)
}


AND cginc(f) BE
{  cgpendingop()
   loada(arg1)
   genf(f)
   forget_a()
   forgetallvars()
}

AND cgplus() BE
// Compiles code to compute <arg2> + <arg1>.
// It does not look at PENDINGOP.

{  IF iszero(arg1) DO {  stack(ssp-1); RETURN }

   IF iszero(arg2) DO
   {  IF h2!arg1=ssp-1 & h1!arg1=k_loc |
      (h1!arg1&31)=k_loci & (h1!arg1>>5)=ssp-1 DO loada(arg1)
      lose1(h1!arg1, h2!arg1)
      RETURN
   }

   TEST inreg_a(h1!arg1, h2!arg1)
   THEN loada(arg1)
   ELSE IF inreg_a(h1!arg2, h2!arg2) DO loada(arg2)

   IF h1!arg1=k_a DO swapargs()

   IF h1!arg2=k_loc DO swapargs()
   IF h1!arg1=k_loc DO {  loada(arg2)
                          genfp(f_ap, h2!arg1)
                          forget_a()
                          lose1(k_a, 0)
                          RETURN
                       }

   IF h1!arg2=k_numb DO swapargs()
   IF h1!arg1=k_numb DO {  loada(arg2)
                           cgaddk(h2!arg1)
                           lose1(k_a, 0)
                           RETURN
                        }

   IF h1!arg2=k_glob DO swapargs()
   IF h1!arg1=k_glob DO {  loada(arg2)
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
{  TEST k>=0
   THEN genfk(f_a, k)
   ELSE genfk(f_s, -k)
   forget_a()
}

AND cgglobal(n) BE
{  cgstatics()
   incode := TRUE
   genf(f_global)
   genk(n)
   FOR i = 1 TO n DO {  geng(rdgn()); genl(rdl()) }
   geng(maxgn)
}


AND cgentry(lab, name) BE
{
   IF debug>0 DO writef("*n// FUN   %s*n", name)

   incode := TRUE
   genfk(f_entry, name%0)
   FOR i = 1 TO name%0 DO genc(name%i)

   genfl(f_lab, lab)
   forgetall()
}

// Function or routine call.
AND cgcall(k) BE
{  LET sa = k+3  // Stack address of first arg (if any).
   AND a1 = 0    // SS item for first arg if present.

   cgpendingop()

// Deal with non args.
   FOR t = tempv TO arg2 BY 3 DO {  IF h3!t>=k BREAK
                                    IF h1!t=k_a DO storet(t)
                                 }

// Deal with args 2, 3 ...
   FOR t = tempv TO arg2 BY 3 DO
   {  LET s = h3!t
      IF s=sa DO
      {  a1 := t  // We have found the SS item for the first arg.
         IF h1!t=k_a & t+3=arg2 DO
         // Two argument call with the first arg already in A.
         {  genf(f_atb)
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
               THEN genfp(f_lp, sa)  // First arg exists but not in SS.
               ELSE loada(a1)        // First arg exists in SS

   // First arg (if any) is now in A.

   TEST h1!arg1=k_glob
   THEN genfpg(f_kpg, k, h2!arg1)
   ELSE {  IF sa<ssp-1 DO { genf(f_atb)
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
}

AND cgraise(count) BE  // count is the number of args to RAISE
{  LET s = ssp
   cgpendingop()
   SWITCHON count INTO
   {  DEFAULT: cgerror("Compiler error in cgraise %n*n", count)

      CASE 3: loada(arg1)
              genf(f_atc)
              stack(ssp-1)
      CASE 2: loadba(arg1, arg2)
              ENDCASE
      CASE 1: loada(arg1)
   }
   genf(f_raise)
   incode := FALSE
   stack(s-count)
}

// Used for MCODE operators JT and JF.
AND cgjump(b,l) BE
{  LET f = jmpfn(pendingop)
   IF f=0 DO {  loadt(k_numb,0); f := f_jne }
   pendingop := s_none
   UNLESS b DO f := compjfn(f)
   store(0,ssp-3)
   genfl(prepj(f),l)
   stack(ssp-2)
}

AND jmpfn(op) = VALOF SWITCHON op INTO
{  DEFAULT:  RESULTIS 0
   CASE s_eq: RESULTIS f_jeq
   CASE s_ne: RESULTIS f_jne
   CASE s_ls: RESULTIS f_jls
   CASE s_gr: RESULTIS f_jgr
   CASE s_le: RESULTIS f_jle
   CASE s_ge: RESULTIS f_jge
}

// cgrelop compiles a relop in a boolean context.
// op is one of s_eq, s_ne, s_ls, s_gr, s_le or s_ge.
AND cgrelop(op) BE
{ LET f = 0

  IF iszero(arg1) DO
  { f := VALOF SWITCHON op INTO
         { CASE s_eq: RESULTIS f_eq0
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
         { CASE s_eq: RESULTIS f_eq0
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

AND jfn0(f) = f+6 // Change F_JEQ into F_JEQ0  etc...

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
{  IF iszero(arg2) DO {  swapargs(); f := revjfn(f) }
   IF iszero(arg1) DO {  loada(arg2); RESULTIS jfn0(f) }
   IF loadboth(arg2, arg1)=swapped RESULTIS revjfn(f)
   RESULTIS f
}

AND cgstatics() BE
{  incode := TRUE

   UNTIL clist=0 DO  // List of 24-32 bit constants
   {  LET blk = clist
      clist := !clist
      genfmw(f_const, h2!blk, h3!blk)
      freeblk(blk)
   }
   cliste := @clist
   incode := FALSE
}

AND getblk(a, b, c, d) = VALOF
{  LET p = freelist
   TEST p=0 THEN {  dp := dp-4; checkspace(); p := dp }
            ELSE freelist := !p
   h1!p, h2!p, h3!p, h4!p := a, b, c, d
   RESULTIS p
}

AND freeblk(p) BE {  !p := freelist; freelist := p }

AND freeblks(p) BE UNLESS p=0 DO
{  LET oldfreelist = freelist
   freelist := p
   UNTIL !p=0 DO p := !p
   !p := oldfreelist
}

AND initdatalists() BE
{  clist,   cliste   := 0, @clist
   freelist := 0
}

LET codef(x) BE { progsize := progsize + 1; writef("F%n*n", x) }

LET codep(x) BE writef("P%n*n", x)

LET codeg(x) BE writef("G%n*n", x)

LET codek(x) BE writef("K%n*n", x)

LET codew(x) BE writef("W%n*n", x)

LET codec(x) BE writef("C%n*n", x)

LET codel(x) BE writef("L%n*n", x)

LET codem(x) BE writef("M%n*n", x)


LET genfp(f, a) BE IF incode DO
{  IF debug>0 DO wrcode(f, a)
   codef(f)
   codep(a)
}

LET genfkp(f, k, a) BE IF incode DO
{  IF debug>0 DO wrcode(f, k, a)
   codef(f)
   codek(k)
   codep(a)
}

LET genfkp(f, k, a) BE IF incode DO
{  IF debug>0 DO wrcode(f, k, a)
   codef(f)
   codek(k)
   codep(a)
}

LET genfg(f, n) BE IF incode DO
{   IF debug>0 DO wrcode(f, n)
   codef(f)
   codeg(n)
}

LET genfkg(f, k, n) BE IF incode DO
{   IF debug>0 DO wrcode(f, k, n)
   codef(f)
   codek(k)
   codeg(n)
}

LET genfpg(f, p, n) BE IF incode DO
{  IF debug>0 DO wrcode(f, p, n)
   codef(f)
   codep(p)
   codeg(n)
}

LET genfk(f, a) BE IF incode DO
{  IF debug>0 DO wrcode(f, a)
   codef(f)
   codek(a)
}

LET genfkl(f, a, l) BE IF incode DO
{  IF debug>0 DO wrcode(f, a, l)
   codef(f)
   codek(a)
   codel(l)
}

LET genfw(f, w) BE IF incode DO
{  IF debug>0 DO wrcode(f, w)
   codef(f)
   codew(w)
}

LET genfl(f, n) BE IF incode DO
{  IF debug>0 DO wrcode(f, n)
   codef(f)
   codel(n)
}

LET genflk(f, n, k) BE IF incode DO
{  IF debug>0 DO wrcode(f, n, k)
   codef(f)
   codel(n)
   codek(k)
}

LET genfm(f, n) BE IF incode DO
{  IF debug>0 DO wrcode(f, n)
   codef(f)
   codem(n)
}

LET genfmw(f, n, w) BE IF incode DO
{  IF debug>0 DO wrcode(f, n, w)
   codef(f)
   codem(n)
   codew(w)
}

LET genf(f) BE IF incode DO
{  IF debug>0 DO wrcode(f)
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
{  cgerror("Program too large")
   errcount := errcount+1
   longjump(fin_p, fin_l)
}


AND dboutput() BE
{  LET p = info_a
   writef("ssp=%i2 ", ssp)
   writes("A=(")
   UNTIL p=0 DO {  wrkn(h2!p, h3!p)
                   p := !p
                   UNLESS p=0 DO wrch('*s')
                }

   p := info_b
   writes(") B=(")
   UNTIL p=0 DO {  wrkn(h2!p, h3!p)
                   p := !p
                   UNLESS p=0 DO wrch('*s')
                }
   wrch(')')

   IF debug=2 DO {  writes("  ")
                    FOR p=tempv TO arg1 BY 3  DO
                    {  IF (p-tempv) REM 30 = 10 DO newline()
                       wrkn(h1!p,h2!p)
                       wrch('*s')
                    }
                 }
   newline()
}

AND wrkn(k, n) BE SWITCHON k&31 INTO
   {  DEFAULT:       writef("?");               RETURN
      CASE k_none:   writef("-");               RETURN
      CASE k_numb:   writef("N%n",    n);       RETURN
      CASE k_lw:     writef("W%n",    n);       RETURN
      CASE k_fnlab:  writef("F%n",    n);       RETURN
      CASE k_lvloc:  writef("@P%n",   n);       RETURN
      CASE k_lvglob: writef("@G%n",   n);       RETURN
      CASE k_lvlab:  writef("@L%n",   n);       RETURN
      CASE k_a:      writef("A",      n);       RETURN
      CASE k_b:      writef("B");               RETURN
      CASE k_c:      writef("C");               RETURN
      CASE k_ext:    writef("X%n",    n);       RETURN
      CASE k_loc:    writef("P%n",    n);       RETURN
      CASE k_glob:   writef("G%n",    n);       RETURN
      CASE k_lab:    writef("L%n",    n);       RETURN
      CASE k_loci:   writef("%nP%n",  n, k>>5); RETURN
      CASE k_lvloci: writef("@%nP%n", n, k>>5); RETURN
      CASE k_globi:  writef("%nG%n",  n, k>>5); RETURN
      CASE k_lvglobi:writef("@%nG%n", n, k>>5); RETURN
      CASE k_labi:   writef("%nL%n",  n, k>>5); RETURN
      CASE k_lvlabi: writef("@%nL%n", n, k>>5); RETURN
   }


LET cgindw0() BE
{  IF pendingop=s_sub & h1!arg1=k_numb DO
      pendingop, h2!arg1 := s_plus, -h2!arg1

   IF pendingop=s_plus DO
   {  IF k_numb=h1!arg2 DO swapargs()
      IF k_numb=h1!arg1 & (h2!arg1&3)=0 DO
      {  LET k = h2!arg1/4  // <arg2> ! k
         stack(ssp-1)       // now <arg1> ! k)
         pendingop := s_none

         IF h1!arg1=k_loc DO
         {  LET n = h2!arg1  // Pn ! k
            h1!arg1, h2!arg1 := k_loci + (n<<5), k
            RETURN
         }

         IF h1!arg1=k_glob DO
         {  LET n = h2!arg1  // Gn ! k
            h1!arg1, h2!arg1 := k_globi + (n<<5), k
            RETURN
         }

         loada(arg1)
         TEST k=0 THEN genf(f_rv)
                  ELSE genfk(f_rvk, k)
         forget_a()
         h1!arg1, h2!arg1 := k_a, 0
         RETURN
      }
   }

   cgpendingop()

   // !(<arg1>)
   IF h1!arg1=k_loc DO
   {  LET n = h2!arg1  // ! Pn
      h1!arg1, h2!arg1 := k_loci + (n<<5), 0
      RETURN
   }

   IF h1!arg1=k_glob DO
   {  LET n = h2!arg1  // ! Gn
      h1!arg1, h2!arg1 := k_globi + (n<<5), 0
      RETURN
   }

   IF h1!arg1=k_lab DO
   {  LET n = h2!arg1  // ! Ln
      h1!arg1, h2!arg1 := k_labi + (n<<5), 0
      RETURN
   }

   loada(arg1)
   genf(f_rv)
   forget_a()
   h1!arg1, h2!arg1 := k_a, 0
}


AND wrcode(f, a, b) BE
{  LET form = VALOF SWITCHON f INTO
   {  DEFAULT:         a := f
                       RESULTIS "Unknown f-code %n"

      CASE f_lp:       RESULTIS "LP    P%n"
      CASE f_lg:       RESULTIS "LG    G%n"
      CASE f_ll:       RESULTIS "LL    L%n"

      CASE f_llp:      RESULTIS "LLP   P%n"
      CASE f_llg:      RESULTIS "LLG   G%n"
      CASE f_lll:      RESULTIS "LLL   L%n"
      CASE f_lf:       RESULTIS "LF    L%n"
      CASE f_lw:       RESULTIS "LW    M%n"

      CASE f_l:        RESULTIS "L     K%n"
      CASE f_lm:       RESULTIS "LM    K%n"

      CASE f_sp:       RESULTIS "SP    P%n"
      CASE f_sg:       RESULTIS "SG    G%n"
      CASE f_sl:       RESULTIS "SL    L%n"

      CASE f_ap:       RESULTIS "AP    P%n"
      CASE f_ag:       RESULTIS "AG    G%n"
      CASE f_a:        RESULTIS "A     K%n"
      CASE f_s:        RESULTIS "S     K%n"

      CASE f_lkp:      RESULTIS "LKP   K%n P%n"
      CASE f_lkg:      RESULTIS "LKG   K%n P%n"
      CASE f_rv:       RESULTIS "RV"
      CASE f_rvp:      RESULTIS "RVP   P%n"
      CASE f_rvk:      RESULTIS "RVK   K%n"
      CASE f_st:       RESULTIS "ST"
      CASE f_stp:      RESULTIS "STP   P%n"
      CASE f_stk:      RESULTIS "STK   K%n"
      CASE f_stkp:     RESULTIS "STKP  K%n P%n"
      CASE f_stkg:     RESULTIS "STKG  K%n G%n"
      CASE f_xst:      RESULTIS "XST"

      CASE f_stb:      RESULTIS "STB"
      CASE f_lvind:    RESULTIS "LVIND"
      CASE f_indb:     RESULTIS "INDB"
      CASE f_indb0:    RESULTIS "INDB0"
      CASE f_indw:     RESULTIS "INDW"

      CASE f_k:        RESULTIS "K     P%n"
      CASE f_kpg:      RESULTIS "KPG   P%n G%n"

      CASE f_neg:      RESULTIS "NEG"
      CASE f_not:      RESULTIS "NOT"
      CASE f_abs:      RESULTIS "ABS"

      CASE f_xdiv:     RESULTIS "XDIV"
      CASE f_xmod:     RESULTIS "XMOD"
      CASE f_xsub:     RESULTIS "XSUB"

      CASE f_mul:      RESULTIS "MUL"
      CASE f_div:      RESULTIS "DIV"
      CASE f_mod:      RESULTIS "MOD"
      CASE f_add:      RESULTIS "ADD"
      CASE f_sub:      RESULTIS "SUB"

      CASE f_eq:       RESULTIS "EQ"
      CASE f_ne:       RESULTIS "NE"
      CASE f_ls:       RESULTIS "LS"
      CASE f_gr:       RESULTIS "GR"
      CASE f_le:       RESULTIS "LE"
      CASE f_ge:       RESULTIS "GE"
      CASE f_eq0:      RESULTIS "EQ0"
      CASE f_ne0:      RESULTIS "NE0"
      CASE f_ls0:      RESULTIS "LS0"
      CASE f_gr0:      RESULTIS "GR0"
      CASE f_le0:      RESULTIS "LE0"
      CASE f_ge0:      RESULTIS "GE0"

      CASE f_lsh:      RESULTIS "LSH"
      CASE f_rsh:      RESULTIS "RSH"
      CASE f_and:      RESULTIS "AND"
      CASE f_or:       RESULTIS "OR"
      CASE f_xor:      RESULTIS "XOR"

      CASE f_xch:      RESULTIS "XCH"
      CASE f_atb:      RESULTIS "ATB"
      CASE f_atc:      RESULTIS "ATC"
      CASE f_bta:      RESULTIS "BTA"
      CASE f_btc:      RESULTIS "BTC"
      CASE f_atblp:    RESULTIS "ATBLP P%n"
      CASE f_atblg:    RESULTIS "ATBLG G%n"
      CASE f_atbll:    RESULTIS "ATBLL L%n"
      CASE f_atbl:     RESULTIS "ATBL  K%n"

      CASE f_j:        RESULTIS "J     L%n"
      CASE f_rtn:      RESULTIS "RTN"

      CASE f_ikp:      RESULTIS "IKP   K%n P%n"
      CASE f_ikg:      RESULTIS "IKG   K%n G%n"
      CASE f_ikl:      RESULTIS "IKL   K%n L%n"
      CASE f_ip:       RESULTIS "IP    P%n"
      CASE f_ig:       RESULTIS "IG    G%n"
      CASE f_il:       RESULTIS "IL    L%n"

      CASE f_jeq:      RESULTIS "JEQ   L%n"
      CASE f_jne:      RESULTIS "JNE   L%n"
      CASE f_jls:      RESULTIS "JLS   L%n"
      CASE f_jgr:      RESULTIS "JGR   L%n"
      CASE f_jle:      RESULTIS "JLE   L%n"
      CASE f_jge:      RESULTIS "JGE   L%n"
      CASE f_jeq0:     RESULTIS "JEQ0  L%n"
      CASE f_jne0:     RESULTIS "JNE0  L%n"
      CASE f_jls0:     RESULTIS "JLS0  L%n"
      CASE f_jgr0:     RESULTIS "JGR0  L%n"
      CASE f_jle0:     RESULTIS "JLE0  L%n"
      CASE f_jge0:     RESULTIS "JGE0  L%n"

      CASE f_brk:      RESULTIS "BRK"
      CASE f_nop:      RESULTIS "NOP"
      CASE f_chgco:    RESULTIS "CHGCO"
      CASE f_mdiv:     RESULTIS "MDIV"
      CASE f_sys:      RESULTIS "SYS"

      CASE f_inc1b:    RESULTIS "INC1B"
      CASE f_inc4b:    RESULTIS "INC4B"
      CASE f_dec1b:    RESULTIS "DEC1B"
      CASE f_dec4b:    RESULTIS "DEC4B"
      CASE f_inc1a:    RESULTIS "INC1A"
      CASE f_inc4a:    RESULTIS "INC4A"
      CASE f_dec1a:    RESULTIS "DEC1A"
      CASE f_dec4a:    RESULTIS "DEC4A"

      CASE f_hand:     RESULTIS "HAND"
      CASE f_unh:      RESULTIS "UNH"
      CASE f_raise:    RESULTIS "RAISE"

      CASE f_module:   RESULTIS "MODULE"
      CASE f_modstart: RESULTIS "MODSTART"
      CASE f_modend:   RESULTIS "MODEND"
      CASE f_global:   RESULTIS "GLOBAL"
      CASE f_const:    RESULTIS "CONST"
      CASE f_lab:      RESULTIS "LAB   L%n"
      CASE f_entry:    RESULTIS "ENTRY"

      CASE f_dlab:     RESULTIS "DLAB  L%n"
      CASE f_dw:       RESULTIS "DW"
      CASE f_db:       RESULTIS "DB"
      CASE f_dl:       RESULTIS "DL"
      CASE f_ds:       RESULTIS "DS"
   }

   IF debug=2 DO dboutput()
   writes("        ")
   writef(form, a, b)
   newline()
}




