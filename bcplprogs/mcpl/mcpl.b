/*
MCPL to MINTCODE compiler

Copyright: Martin Richards 16 June 1997

It uses a reverse polish form of MCODE.

Development of this compiler started on 2 Nov 1992
This version is designed to run interpretively using MINTCODE,
and is similar in structure to the BCPL Cintcode system.
The GLOBAL declaration has been put back into the MCPL and
the syntax of EXTERNAL declarations has been retained but not
implemented.

30/7/93 Implemented GLOBAL declarations in SYN and TRN.
28/1/97 Removed bug in storein
12/2/97 Allow nested comments
16/6/97 Restrict syntax of function arguments
        Correct bug in rdseq
        Change syntax of LET to make it similar to STATIC
        old:  LET a, b, c = f(), ?, v!i
        new:  LET a=f(), b, c=v!i
        LET a,b,c ALL= 0  is no longer available
16/6/97
Implement the method application operator for object oriented
programming in MCPL. E # (E1, E2,..., En) is equivalent to
((!E1)!E)(E1, E2,..., En)
8/7/97
Separated into files mcpl.b, mcplsyn.b and mcpltrn.b, so that
they can be shared with the native code version of the compiler.
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


SECTION "MCPL"

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
   "FROM/A,TO/K,VER/K,TREE/S,NONAMES/S,D1/S,D2/S,OENDER/S,"
   LET bining, debug, prtree = TRUE, 0, FALSE
   LET bigender, naming = ?, TRUE
   LET stdout = output()

   sysprint := stdout
   selectoutput(sysprint)
 
   writef("*nMCPL 9 July 1997*n")
 
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
   IF argv!4 DO naming   := FALSE         // NONAMES
   IF argv!5 DO debug    := debug+1       // D1
   IF argv!6 DO debug    := debug+2       // D2
   IF argv!7 DO bigender := ~bigender     // OENDER

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
   selectoutput(mcodeout);     endwrite();  mcodeout := 0

   selectoutput(sysprint)

   UNLESS errcount=0 GOTO fin

   mcodein := findinput("MCODE")
   IF mcodein=0 DO
   {  writef("Trouble reading file MCODE*n")
      errcount := 1
      GOTO fin
   }

   IF argv!1=0 DO argv!1 := "MINTCODE"

   tostream := findoutput(argv!1)
   IF tostream=0 DO
   {  writef("Trouble with code file %s*n", argv!1)
      errcount := 1
      GOTO fin
   }

   selectinput(mcodein)
   codegenerate(treevec, treesize, bining, debug, bigender, naming)

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

// Start of the MCODE->Mintcode Codegenerator

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

s_callc=29;
s_call=30;
s_indw=31;
s_indw0=32;
s_indb=33; 
s_indb0=34;
s_lsh=35;  // in same order as op:= operators 
s_rsh=36;  
s_mult=37; 
s_div=38; 
s_mod=39; 
s_bitand=40; 
s_xor=41;
s_plus=42;
s_sub=43;
s_bitor=44; 

s_eq=45; 
s_ne=46; 
s_le=47; 
s_ge=48; 
s_ls=49; 
s_gr=50; 
s_rel=51;

s_ptr=59;
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

s_inc1b=90; 
s_inc4b=91; 
s_dec1b=92; 
s_dec4b=93
s_inc1a=94; 
s_inc4a=95; 
s_dec1a=96; 
s_dec4a=97

s_goto=103; 
s_raise=104; 
s_handle=105

s_match=120; 
s_return=124

s_module=145
s_endmodule=146;

s_global=150
s_fun=151
s_cfun=152
s_endfun=153
s_unhandle=156
s_line=157
s_file=158
s_setargs=159
s_fnargs=160; 
s_locs=161; 

s_none=200

             //  Selectors
h1=0; h2=1; h3=2; h4=3

hashtabsize=63
}

GLOBAL { 
cgmodules: 401
rdn      : 402
rdl      : 403
rdgn     : 404
rdstr    : 405
newlab   : 406
checklab : 407
cgerror  : 408

initstack: 410
stack    : 411
store    : 412
scan     : 413
cgpendingop:414
loadval  : 415
loadba   : 416
setba    : 417

genxch   : 420
genatb   : 421
loada    : 422
push     : 423
loadboth : 424
inreg_a  : 425
inreg_b  : 426
addinfo_a: 427
pushinfo : 428
xchinfo  : 429
atbinfo  : 430

forget_a : 431
forget_b : 432
forgetall: 433
forgetvar: 434
forgetallvars: 435

iszero   : 437
storet   : 438
gensp    : 439
genlp    : 440
genllp   : 441
genln    : 442
loadt    : 443
lose1    : 444
swapargs : 445
cgstw    : 446
storein  : 447

cginc    : 449
cgplus   : 450
cgaddk   : 451
cgglobal : 452
cgentry  : 453
cgcall   : 455
cgjump   : 457
jmpfn    : 458
jfn0     : 459
revjfn   : 460
compjfn  : 461
prepj    : 462
cgraise  : 463

cgstring : 475
setlab   : 476
cgstatics: 477
getblk   : 478
freeblk  : 479
freeblks : 480

initdatalists : 481

geng     : 490
gen      : 491
genb     : 492
genr     : 493
genh     : 494
genw     : 495
checkspace : 496
codeb    : 497
code2b   : 498
code4b   : 499
pack4b   : 500
codec    : 501
codeh    : 502
codew    : 503
codewl   : 504
coder    : 505

getw     : 508
puth     : 509
putw     : 510
align    : 511
chkrefs  : 512
dealwithrefs:513
genindword:514
inrange_d: 515
inrange_i: 516
fillref_d: 517
fillref_i: 518
relref:    519

outputmodule : 520
objword  : 521
dboutput : 522
wrkni    : 523
wrcode   : 524
wrfcode  : 525

// Global variables.
arg1     : 531
arg2     : 532
bining   : 533

ch       : 536
debug    : 537
lineno   : 538

nlist    : 540
nliste   : 541
dp       : 542
freelist : 543

incode   : 545
labv     : 546

bigender : 548

maxgn    : 550
maxlab   : 551
maxssp   : 552
naming   : 553

op       : 555
labnumber : 556
pendingop: 557

progsize : 560
info_a   : 561
info_b   : 562
reflist  : 565
refliste : 566
rlist    : 568
rliste   : 569
skiplab  : 570
ssp      : 571
reloclist : 572
relocliste: 573

stv      : 580
stvp     : 581
tempt    : 583
tempv    : 584

hashtab  : 590
charv    : 591
lookup   : 592
newvec   : 593
}


MANIFEST
{ 
// Value descriptors.
k_none=0; k_numb=1; k_fnlab=2
k_lvloc=3; k_lvloci=4; k_lvglob=5; k_lvlab=6
k_a=7; k_b=8
k_loc=9; k_glob=10; k_ext=11; k_lab=12;
k_glob0=24; k_glob1=25; k_glob2=26
k_loci=30

swapped=TRUE; notswapped=FALSE

}

// MINTCODE function codes.
MANIFEST { 
f_k0   =   0

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
f_mod  =  54
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

f_lvind= 146
f_stb  = 147
f_st   = 148

f_jle  = 156
f_jle0 = 158

f_sp   = 160
f_sph  = 161
f_spw  = 162
f_sp0  = 160
f_s0   = 176
f_xch  = 181
f_indb = 182
f_indb0= 183
f_atc  = 184
f_atb  = 185
f_j    = 186
f_jge  = 188
f_jge0 = 190

f_ap   = 192
f_aph  = 193
f_apw  = 194
f_ap0  = 192
f_indw = 205
f_lmh  = 206
f_btc  = 207
f_nop  = 208
f_a0   = 208
f_rvp0 = 211
f_st0p0= 216
f_st1p0= 218
f_cta  = 223

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
f_inc1b= 243
f_inc4b= 244
f_dec1b= 245
f_dec4b= 246
f_inc1a= 247
f_inc4a= 248
f_dec1a= 249
f_dec4a= 250

f_hand = 252
f_unh  = 254
f_raise= 255
}


LET codegenerate(workspace, workspacesize, bin, dbg, bige, names) BE
{  writes("MintCG 9 July 1997*n")

   IF workspacesize<2000 DO {  cgerror("Too little workspace")
                               errcount := errcount+1
                               longjump(fin_p, fin_l)
                            }

   // Set the codegenerator options
   bining, debug, bigender, names := bin, dbg, bige, names

   progsize := 0

   op := rdn()

   cgmodules(workspace, workspacesize)   

   writef("Program size = %n*n", progsize)
}

AND cgmodules(workvec, vecsize) BE UNTIL op=0 DO
{  LET p = workvec
   dp := workvec+vecsize
   stv := p
   stvp := 0

   tempv := newvec(400)
   tempt := tempv+400
   labv := p
   labnumber := (dp-p)/10+10
   labv := newvec(labnumber)
   FOR i = 0 TO labnumber DO labv!i := -1
   hashtab := newvec(hashtabsize)
   FOR i = 0 TO hashtabsize DO hashtab!i := 0
   charv := newvec(1024)

   incode := FALSE
   maxlab := 0
   maxssp := 0
   maxgn  := 0
   info_a, info_b := 0, 0
   initstack(3)
   initdatalists()

   WHILE op=s_file DO {  rdn(); rdstr(); op := rdn() }

   codew(0)  // For size of module.
   IF op=s_module DO
   {  LET n = rdn()
      LET v = VEC 3
      v%0 := 7
      FOR i = 1 TO n DO  {  LET c = rdn()
                            IF i<=7 DO v%i := c
                         }
      FOR i = n+1 TO 7 DO v%i := 32  //ASCII space.
      IF naming DO
      {  codew(modword)
         codew(pack4b(v%1, v%2, v%3, v%4))
         codew(pack4b(v%5, v%6, v%7, 0))
      }
      op := rdn()
   }

   scan()
   op := rdn()
   putw(0, stvp/4)  // Plant size of module.
   outputmodule()
   progsize := progsize + stvp
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
   IF maxlab<lab DO {  maxlab := lab; checklab() }
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
   checkspace()
   RESULTIS dp
}

// Generate next label number.
AND newlab() = VALOF
{  labnumber := labnumber-1
   checklab()
   RESULTIS labnumber
}


AND checklab() BE IF maxlab>=labnumber DO
{  cgerror("Too many labels - increase workspace")
   errcount := errcount+1
   longjump(fin_p, fin_l)
}

AND cgerror(mes, a) BE
{  LET oldout = output()
   selectoutput(sysprint)
   writes("*nError: ")
   writef(mes, a)
   newline()
   errcount := errcount+1
   IF errcount>errmax DO {  writes("Too many errors*n")
                            longjump(fin_p, fin_l)
                         }
   selectoutput(oldout)
}


// Initialize the simulated stack (SS).
// SS cells are of the form [k, n, i, s]
// where k    is the kind k_loc etc
//       n, i are arguments
//       s    is the position rel to P of this item
LET initstack(n) BE
{  arg2, arg1, ssp := tempv, tempv+4, n
   pendingop := s_none
   h1!arg2, h2!arg2, h4!arg2 := k_loc, ssp-2, ssp-2
   h1!arg1, h2!arg1, h4!arg1 := k_loc, ssp-1, ssp-1
   IF maxssp<ssp DO maxssp := ssp
}


// Move simulated stack pointer to n.
AND stack(n) BE
{  IF maxssp<n DO maxssp := n
   IF n>=ssp+4 DO {  store(0, ssp-1)
                     initstack(n)
                     RETURN
                  }

   WHILE n>ssp DO loadt(k_loc, ssp)

   UNTIL n=ssp DO
   {  IF arg2=tempv DO
      {  TEST n=ssp-1
         THEN {  ssp := n
                 h1!arg1, h2!arg1, h3!arg1 := h1!arg2, h2!arg2, h3!arg2
                 h4!arg1 := ssp-1
                 h1!arg2, h2!arg2, h4!arg2 := k_loc, ssp-2, ssp-2
              }
         ELSE initstack(n)
         RETURN
      }

      arg1, arg2, ssp := arg1-4, arg2-4, ssp-1
   }
}

// Store all SS items from s1 to s2 in their true
// locations on the stack.
// It may corrupt both registers A and B.
AND store(s1, s2) BE FOR p = tempv TO arg1 BY 4 DO
                     {  LET s = h4!p
                        IF s>s2 RETURN
                        IF s>=s1 DO storet(p)
                     }



// Store any SS items holding value (k,n) in their temporary
// stack locations. It may corrupt both registers A and B.
// It is called from storein
AND storetemp(k, n, s1, s2) BE
  FOR p = tempv TO arg2 BY 4 IF h1!p=k & h2!p=n DO storet(p)



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
                         loadt(k_loci, n, i)
                         ENDCASE    
                      }

// llpath n i         load @ p!n!i      n~=0
      CASE s_llpath:  {  LET n = rdn()
                         LET i = rdn()
                         loadt(k_lvloci, n, i)
                         ENDCASE    
                      }

// spath n i          store p!n!i      n~=0
      CASE s_spath:   {  LET n = rdn()
                         LET i = rdn()
                         storein(k_loci, n, i)
                         ENDCASE    
                      }
   
// setargs len argpos
      CASE s_setargs: {  LET n = rdn()
                         LET pos = rdn()
                         cgpendingop()
                         FOR i = n-1 TO 0 BY -1 DO
                         {  loada(arg1)
                            gensp(pos+i)
                            stack(ssp-1)
                         } 
                         ENDCASE
                      }

      CASE s_stw:      cgstw()
                       ENDCASE

      CASE s_stb:      cgpendingop()
                       loadba(arg1, arg2)
                       gen(f_stb)
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
                       gen(f_atc)
                       stack(ssp-1);            ENDCASE
      CASE s_cpr:      cgpendingop()
                       loada(arg1)
                       gen(f_atc);              ENDCASE
      CASE s_dup:      cgpendingop()
                       loada(arg1)
                       storet(arg1)
                       loadt(k_a, 0);           ENDCASE
      CASE s_lr:       forgetall()
                       gen(f_cta)
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

      CASE s_unhandle: gen(f_unh)
                       ENDCASE

      CASE s_return:   cgpendingop()
                       gen(f_rtn)
                       incode := FALSE
                       ENDCASE

      CASE s_fnargs:  
                    {  LET a = rdn()
                       IF a>0 DO addinfo_a(k_loc, 3)
                       stack(3+a)
                       ENDCASE
                    }

      CASE s_match:    rdn()   // ss position of first match arg
                       rdn();  // Number of match args
                       store(0, ssp) // Ensure everything is in memory
                       //cgerror("Unimplemented op in scan %n*n", op)
                       ENDCASE

      CASE s_raise:    cgraise(rdn())
                       incode := FALSE
                       ENDCASE

      CASE s_locs:     stack(ssp+rdn());           ENDCASE

      CASE s_lp:       loadt(k_loc, rdn(), 0);     ENDCASE
      CASE s_lg:       loadt(k_glob, rdgn(), 0);   ENDCASE
      CASE s_llp:      loadt(k_lvloc, rdn(), 0);   ENDCASE
      CASE s_llg:      loadt(k_lvglob, rdgn(), 0); ENDCASE

      CASE s_ln:       loadt(k_numb,  rdn(), 0);   ENDCASE

      CASE s_sp:       storein(k_loc,  rdn(), 0);  ENDCASE
      CASE s_sg:       storein(k_glob, rdgn(), 0); ENDCASE

// call k             call a procedure incrementing P by k
      CASE s_call:     cgcall(rdn())
                       ENDCASE

      CASE s_jump:     cgpendingop()
                       store(0, ssp-1)
                       forgetall()
                       genr(f_j, rdl());           ENDCASE

      CASE s_handle:   cgpendingop()
                       store(0, ssp-1)
                       forgetall()
                       genllp(ssp)
                       genr(f_hand, rdl())
                       stack(ssp+3)
                       ENDCASE

      CASE s_jt:       cgjump(TRUE, rdl());        ENDCASE
      CASE s_jf:       cgjump(FALSE, rdl());       ENDCASE

      CASE s_ll:       loadt(k_lab, rdl(), 0);     ENDCASE
      CASE s_lll:      loadt(k_lvlab, rdl(), 0);   ENDCASE

      CASE s_lf:       loadt(k_fnlab, rdl(), 0);   ENDCASE

      CASE s_sl:       storein(k_lab, rdl(), 0);   ENDCASE

      CASE s_lab:      cgpendingop()
                       UNLESS incode DO chkrefs(30)
                       store(0, ssp-1)
                       setlab(rdl())
                       incode := TRUE
                       forgetall()
                       ENDCASE

      CASE s_fun:
      CASE s_cfun:  {  LET lab = rdl()
                       LET name = rdstr()
                       LET type = op=s_fun -> 0, rdstr()
                       cgentry(lab, name, type) 
                       ENDCASE
                    }

      CASE s_callc: {  rdn()
                       rdstr()
                       cgerror("Unimplemented op in scan %n*n", op)
                       ENDCASE
                    }
                   
      CASE s_endfun:   ENDCASE

      CASE s_global:   cgglobal(rdn()); ENDCASE

      CASE s_endmodule: RETURN

      CASE s_dlab:     chkrefs(512)
                       align(4)
                       setlab(rdl())
                       ENDCASE

      CASE s_dw:       codew(rdn());  ENDCASE
      CASE s_db:       codec(rdn());  ENDCASE
      CASE s_dl:       codewl(rdl()); ENDCASE
      CASE s_ds:    {  LET n = rdn()
                       FOR i = 1 TO n DO codew(0)
                       ENDCASE
                    }

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
                    chkrefs(3)
                    genb(jfn0(f_jgr), 2) // Conditionally skip
                    gen(f_neg)           // over this NEG instruction.
                    forget_a()
                    RETURN

      CASE s_neg:   loada(arg1)
                    gen(f_neg)
                    forget_a()
                    RETURN

      CASE s_bitnot:
      CASE s_not:   loada(arg1)
                    gen(f_not)
                    forget_a()
                    RETURN

      CASE s_lvindw: loadba(arg2, arg1)
                     gen(f_lvind)
                     lose1(k_a, 0, 0)
                     forget_a()
                     RETURN

      CASE s_indw0: loada(arg1)
                    gen(f_rv)
                    forget_a()
                    RETURN

      CASE s_indb0: loada(arg1)
                    gen(f_indb0)
                    forget_a()
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
                    RETURN

      CASE s_sub:   UNLESS k_numb=h1!arg1 DO
                    {  f, sym := f_sub, FALSE
                       ENDCASE
                    }
                    h2!arg1 := -h2!arg1

      CASE s_plus:  cgplus(); RETURN

      CASE s_indw:  f, sym := f_indw, FALSE; ENDCASE
      CASE s_indb:  f      := f_indb;        ENDCASE
      CASE s_mult:  f      := f_mul;         ENDCASE
      CASE s_div:   f, sym := f_div, FALSE;  ENDCASE
      CASE s_mod:   f, sym := f_mod, FALSE;  ENDCASE
      CASE s_lsh:   f, sym := f_lsh, FALSE;  ENDCASE
      CASE s_rsh:   f, sym := f_rsh, FALSE;  ENDCASE
      CASE s_bitand:f      := f_and;         ENDCASE
      CASE s_bitor: f      := f_or;          ENDCASE
      CASE s_xor:   f      := f_xor;         ENDCASE
   }

   TEST sym THEN loadboth(arg2, arg1)
            ELSE loadba(arg2, arg1)

   gen(f)
   forget_a()

   lose1(k_a,0,0)
}

LET loada(x)   BE {  loadval(x, FALSE); setba(0, x) }

AND push(x, y) BE {  loadval(y, TRUE);  setba(x, y) }

AND loadval(x, pushing) BE  // ONLY called from loada and push.
// Load compiles code to have the following effect:
// If pushing=TRUE    B := A; A := <x>.
// If pushing=FALSE   B := ?; A := <x>.
{  LET k, n, i = h1!x, h2!x, h3!x

   UNLESS pushing | k=k_a DO  // Dump A register if necessary.
     FOR t = arg1 TO tempv BY -4 IF h1!t=k_a DO {  storet(t); BREAK }

   TEST inreg_a(k, n, i) THEN setba(0, x)
                         ELSE IF inreg_b(k, n, i) DO {  genxch(0, 0)
                                                        RETURN
                                                     }
   SWITCHON h1!x INTO
   {  DEFAULT:  cgerror("in loadval %n", k)

      CASE k_a: IF pushing UNLESS inreg_b(k, n, i) DO genatb(0, 0)
                RETURN

      CASE k_numb:
        TEST -1<=n<=10
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
        ENDCASE

      CASE k_loci:    genlp(n)    // needs improving ??????
                      TEST 0<=i<=6 THEN gen(f_rv+i)
                                   ELSE {  cgaddk(4*i)
                                           gen(f_rv)
                                        }
                      ENDCASE

      CASE k_lvloci:  genlp(n)
                      cgaddk(4*h3!x)
                      ENDCASE

      CASE k_loc:  genlp(n);        ENDCASE
      CASE k_glob: geng(f_lg, n);   ENDCASE
      CASE k_lab:  genr(f_ll, n);   ENDCASE
      CASE k_fnlab:genr(f_lf, n);   ENDCASE

      CASE k_lvloc:genllp(n);       ENDCASE

      CASE k_lvglob:geng(f_llg, n); ENDCASE
      CASE k_lvlab: genr(f_lll, n); ENDCASE
      CASE k_glob0: geng(f_l0g, n); ENDCASE
      CASE k_glob1: geng(f_l1g, n); ENDCASE
      CASE k_glob2: geng(f_l2g, n); ENDCASE
   }

   // A loading instruction has just been compiled.
   pushinfo(h1!x, h2!x, h3!x)
}

AND loadba(x, y) BE IF loadboth(x, y)=swapped DO genxch(x, y)

AND setba(x, y) BE
{  UNLESS x=0 DO h1!x := k_b
   UNLESS y=0 DO h1!y := k_a
}

AND genxch(x, y) BE {  gen(f_xch); xchinfo(); setba(x, y) }

AND genatb(x, y) BE {  gen(f_atb); atbinfo(); setba(x, y) }

AND loadboth(x, y) = VALOF
// Compiles code to cause
//   either    x -> [B]  and  y -> [A]
//             giving result NOTSWAPPED
//   or        x -> [A]  and  y -> [B]
//             giving result SWAPPED.
// LOADBOTH only swaps if this saves code.
{  // First ensure that no other stack item uses reg A.
   FOR t = tempv TO arg1 BY 4 DO
       IF h1!t=k_a UNLESS t=x | t=y DO storet(t)

   {  LET xa, ya = inreg_a(h1!x, h2!x, h3!x), inreg_a(h1!y, h2!y, h3!y)
      AND xb, yb = inreg_b(h1!x, h2!x, h3!x), inreg_b(h1!y, h2!y, h3!y)

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

LET inreg_a(k, n, i) = VALOF
{  LET p = info_a
   IF k=k_a RESULTIS TRUE
   UNTIL p=0 DO {  IF k=h2!p & n=h3!p & i=h4!p RESULTIS TRUE
                   p := !p
                }
   RESULTIS FALSE
}

AND inreg_b(k, n, i) = VALOF
{  LET p = info_b
   IF k=k_b RESULTIS TRUE
   UNTIL p=0 DO {  IF k=h2!p & n=h3!p & i=h4!p RESULTIS TRUE
                   p := !p
                }
   RESULTIS FALSE
}

AND addinfo_a(k, n, i) BE info_a := getblk(info_a, k, n, i)

AND pushinfo(k, n, i) BE
{  forget_b()
   info_b := info_a
   info_a := getblk(0, k, n, i)
}

AND xchinfo() BE

{  LET t = info_a
   info_a := info_b
   info_b := t
}

AND atbinfo() BE
{  LET p = info_b
   forget_a()
   UNTIL p=0 DO {  addinfo_a(h2!p, h3!p, h4!p); p := !p }
}

AND forget_a() BE {  freeblks(info_a); info_a := 0 }

AND forget_b() BE {  freeblks(info_b); info_b := 0 }

AND forgetall() BE {  forget_a(); forget_b() }

// Forgetvar is called just after compiling an assigment to a simple
// variable (k, n, i).  k is k_loc, k_loci, k_glob, k_ext or k_lab.
// Register information about indirect local values must also be
// thrown away.
AND forgetvar(k, n, i) BE
{  LET p = info_a
   UNTIL p=0 DO {  IF h3!p=n &
                      ( k=h2!p  & h4!p=i      |
                        k=k_loc & h2!p=k_loci
                      ) DO h2!p := k_none
                   p := !p
                }
   p := info_b
   UNTIL p=0 DO {  IF h3!p=n &
                      ( k=h2!p  & h4!p=i      |
                        k=k_loc & h2!p=k_loci
                      ) DO h2!p := k_none
                   p := !p
                }
}

AND forgetallvars() BE  // After compiling an indirect assignment.
{  LET p = info_a
   UNTIL p=0 DO {  IF h2!p>=k_loc DO h2!p := k_none
                   p := !p
                }
   p := info_b
   UNTIL p=0 DO {  IF h2!p>=k_loc DO h2!p := k_none
                   p := !p
                }
}

AND iszero(a) = h1!a=k_numb & h2!a=0 -> TRUE, FALSE

// Store the value of a SS item in its true stack location.
AND storet(x) BE
{  LET s = h4!x
   IF h1!x=k_loc & h2!x=s RETURN
   loada(x)
   gensp(s)
   forgetvar(k_loc, s, 0)
   addinfo_a(k_loc, s, 0)
   h1!x, h2!x, h3!x := k_loc, s, 0
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

AND genllp(n) BE TEST 0<=n<=255
                 THEN genb(f_llp, n)
                 ELSE TEST 0<=n<=#xFFFF
                      THEN genh(f_llph, n)
                      ELSE genw(f_llpw, n)

AND genln(n) BE TEST -1<=n<=10
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

// Load an item (K,N) onto the SS. It may move SS items.
AND loadt(k, n, i) BE
{  cgpendingop()
   TEST arg1+4=tempt
   THEN {  storet(tempv)  // SS stack overflow.
           FOR t = tempv TO arg2+3 DO t!0 := t!4
        }
   ELSE arg2, arg1 := arg2+4, arg1+4
   h1!arg1,h2!arg1,h3!arg1,h4!arg1 := k,n,i,ssp
   ssp := ssp + 1
   IF maxssp<ssp DO maxssp := ssp
}


// Replace the top two SS items by (K,N) and set PENDINGOP=S_NONE.
AND lose1(k, n, i) BE
{  ssp := ssp - 1
   TEST arg2=tempv
   THEN {  h1!arg2, h2!arg2, h3!arg2 := k_loc, ssp-2, 0
           h4!arg2 := ssp-2
        }
   ELSE {  arg1 := arg2
           arg2 := arg2-4
        }
   h1!arg1, h2!arg1, h3!arg1, h4!arg1 := k, n, i, ssp-1
   pendingop := s_none
}

AND swapargs() BE
{  LET k, n, i = h1!arg1, h2!arg1, h3!arg1
   h1!arg1, h2!arg1, h3!arg1 := h1!arg2, h2!arg2, h3!arg2
   h1!arg2, h2!arg2, h3!arg2 := k, n, i
}

AND cgstw() BE
{  cgpendingop()
   loadba(arg1, arg2)
   gen(f_st)
   stack(ssp-2)
   forgetallvars()
}

// Store the top item of the SS in (k,n,i).
// k is k_loc, k_loci, k_glob  or k_lab.
AND storein(k, n, i) BE
{  cgpendingop()

   SWITCHON k INTO
   {  DEFAULT:     cgerror("in storein %n", k)

      CASE k_loc:  storetemp(k, n, 0, ssp-2)
                   loada(arg1); gensp(n);       ENDCASE
      CASE k_glob: storetemp(k, n, 0, ssp-2)
                   loada(arg1); geng(f_sg, n);  ENDCASE
      CASE k_lab:  storetemp(k, n, 0, ssp-2)
                   loada(arg1); genr(f_sl, n);  ENDCASE

      CASE k_loci: store(0, ssp-2)
                   loada(arg1)
                   genlp(n)
                   cgaddk(4*i)
                   gen(f_st)
                   forgetall()
                   stack(ssp-1)
                   RETURN
   }
   forgetvar(k, n, i)
   addinfo_a(k, n, i)
   stack(ssp-1)
}

AND cginc(f) BE
{  cgpendingop()
   loada(arg1)
   gen(f)
   forget_a()
   forgetallvars()
}

AND cgplus() BE
// Compiles code to compute <arg2> + <arg1>.
// It does not look at PENDINGOP.

{  IF iszero(arg1) DO {  stack(ssp-1); RETURN }

   IF iszero(arg2) DO
   {  IF h2!arg1=ssp-1 & h1!arg1=k_loc DO loada(arg1)
      lose1(h1!arg1, h2!arg1, h3!arg1)
      RETURN
   }

   TEST inreg_a(h1!arg1, h2!arg1, h3!arg1)
   THEN loada(arg1)
   ELSE IF inreg_a(h1!arg2, h2!arg2, h3!arg2) DO loada(arg2)

   IF h1!arg1=k_a DO swapargs()

   IF h1!arg2=k_loc & 3<=h2!arg2<=12 DO swapargs()
   IF h1!arg1=k_loc & 3<=h2!arg1<=12 DO {  loada(arg2)
                                           gen(f_ap0 + h2!arg1)
                                           forget_a()
                                           lose1(k_a, 0, 0)
                                           RETURN
                                        }

   IF h1!arg2=k_numb & -4<=h2!arg2<=5 DO swapargs()
   IF h1!arg1=k_numb & -4<=h2!arg1<=5 DO {  loada(arg2)
                                            cgaddk(h2!arg1)
                                            lose1(k_a, 0, 0)
                                            RETURN
                                         }

   IF h1!arg2=k_loc DO swapargs()
   IF h1!arg1=k_loc DO
   {  LET n = h2!arg1
      loada(arg2)
      TEST 3<=n<=12 THEN gen(f_ap0 + n)
                    ELSE TEST 0<=n<=255
                         THEN genb(f_ap, n)
                         ELSE TEST 0<=n<=#xFFFF
                              THEN genh(f_aph, n)
                              ELSE genw(f_apw, n)
      forget_a()
      lose1(k_a, 0, 0)
      RETURN
   }

   IF h1!arg2=k_glob DO swapargs()
   IF h1!arg1=k_glob DO {  loada(arg2)
                           geng(f_ag, h2!arg1)
                           forget_a()
                           lose1(k_a, 0, 0)
                           RETURN
                        }

   IF h1!arg2=k_numb DO swapargs()
   IF h1!arg1=k_numb DO {  LET n = h2!arg1
                           loada(arg2)
                           cgaddk(n)
                           lose1(k_a, 0, 0)
                           RETURN
                        }
   loadboth(arg2, arg1)
   gen(f_add)
   forget_a()
   lose1(k_a, 0, 0)
}

AND cgaddk(k) BE UNLESS k=0 DO  // Compile code to add k to A.
{  TEST -4<=k<=5
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
{  incode := FALSE
   cgstatics()
   chkrefs(512)   // Deal with ALL outstanding refs.
   align(4)
   codew(0)       // Compile Global initialisation data.
   FOR i = 1 TO n DO {  codew(rdgn()); codew(labv!rdl()) }
   codew(maxgn)
}

AND cgraise(count) BE  // count is the number of args to RAISE
{  LET s = ssp
   cgpendingop()
   SWITCHON count INTO
   {  DEFAULT: cgerror("Compiler error in cgraise %n*n", count)

      CASE 3: loada(arg1)
              gen(f_atc)
              stack(ssp-1)
      CASE 2: loadba(arg1, arg2)
              ENDCASE
      CASE 1: loada(arg1)
   }
   gen(f_raise)
   incode := FALSE
   stack(s-count)
}
   

AND cgentry(lab, name, type) BE
{  LET v = VEC 3
   LET n = name%0
   v%0 := 7
   FOR i = 1 TO n IF i<=7 DO v%i := name%i
   FOR i = n+1 TO 7 DO v%i := 32  // Ascii SPACE.
   chkrefs(80)  // Deal with some forward refs.
   align(4)
   IF naming DO {  codew(entryword)
                   codew(pack4b(v%1, v%2, v%3, v%4))
                   codew(pack4b(v%5, v%6, v%7, 0))
                }
   IF debug>0 DO writef("*n// FUN %s*n", name)
   setlab(lab)
   incode := TRUE
   initstack(3)
   forgetall()
}

// Function or routine call.
AND cgcall(k) BE
{  LET sa = k+3  // Stack address of first arg (if any).
   AND a1 = 0    // SS item for first arg if found.

   cgpendingop()

// Deal with non args.
   FOR t = tempv TO arg2 BY 4 DO {  IF h4!t>=k BREAK
                                    IF h1!t=k_a DO storet(t)
                                 }

// Deal with args 2, 3 ...
   FOR t = tempv TO arg2 BY 4 DO
   {  LET s = h4!t
      IF s=sa DO
      {  a1 := t  // We have found the SS item for the first arg.
         IF h1!t=k_a & t+4=arg2 DO
         // Two argument call with the first arg already in A.
         {  push(t, arg2)
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
   ELSE {  push(a1, arg1)
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
}

// Used for MCODE operators JT and JF.
AND cgjump(b,l) BE
{  LET f = jmpfn(pendingop)
   IF f=0 DO {  loadt(k_numb,0,0); f := f_jne }
   pendingop := s_none
   UNLESS b DO f := compjfn(f)
   store(0,ssp-3)
   genr(prepj(f),l)
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
{  IF iszero(arg2) DO {  swapargs(); f := revjfn(f) }
   IF iszero(arg1) DO {  loada(arg2); RESULTIS jfn0(f) }
   IF loadboth(arg2, arg1)=swapped RESULTIS revjfn(f)
   RESULTIS f
}

AND cgstring(n) BE
{  LET l, a = newlab(), n
   loadt(k_lvlab,l,0)
   {  LET b, c, d = 0, 0, 0
      IF n>0 DO b := rdn()
      IF n>1 DO c := rdn()
      IF n>2 DO d := rdn()
      !nliste := getblk(0,l,pack4b(a, b, c, d))
      nliste := !nliste
      l := 0
      IF n<=3 BREAK
      n, a := n-4, rdn()
   } REPEAT
}

AND setlab(l) BE
{  LET p = @rlist

   IF debug>0 DO writef("%i4: L%n:*n", stvp, l)

   labv!l := stvp  // Set the label.

   // Fill in all refs that are in range.
   {  LET r = !p
      IF r=0 BREAK
      TEST h3!r=l & inrange_d(h2!r, stvp)
      THEN {  fillref_d(h2!r, stvp)
              !p := !r   // Remove item from RLIST.
              freeblk(r)
           }
      ELSE p := r  // Keep the item.
   } REPEAT
   rliste := p     // Ensure that RLISTE is sensible.

   p := @reflist

   {  LET r = !p
      IF r=0 BREAK
      TEST h3!r=l
      THEN {  LET a = h2!r
              puth(a,stvp-a) // Plant rel address.
              !p := !r       // Remove item from REFLIST.
              freeblk(r)
           }
      ELSE p := r  // Keep item.
   } REPEAT

   refliste := p   // Ensure REFLISTE is sensible.
}

AND cgstatics() BE UNTIL nlist=0 DO
{  LET len, nl = 0, nlist

   nliste := @nlist  // All NLIST items will be freed.

   len, nl := len+4, !nl REPEATUNTIL nl=0 | h2!nl ~= 0

   chkrefs(len+3)  // +3 because align(4) may generate 3 bytes.
   align(4)

   setlab(h2!nlist)  // NLIST always starts labelled.

   {  LET blk = nlist
      nlist := !nlist
      freeblk(blk)
      codew(h3!blk)
   } REPEATUNTIL nlist=0 | h2!nlist ~= 0
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
{  reflist,   refliste   := 0, @reflist
   reloclist, relocliste := 0, @reloclist
   rlist,     rliste     := 0, @rlist
   nlist,     nliste     := 0, @nlist
   freelist := 0
}

LET geng(f, n) BE TEST n<256
                  THEN genb(f, n)
                  ELSE TEST n<512
                       THEN genb(f+32, n-256)
                       ELSE genh(f+64, n)

LET gen(f) BE IF incode DO
{  chkrefs(1)
   IF debug>0 DO wrcode(f, "")
   codeb(f)
}

LET genb(f, a) BE IF incode DO
{  chkrefs(2)
   IF debug>0 DO wrcode(f, "%i3", a)
   codeb(f)
   codeb(a)
}

LET genr(f, n) BE IF incode DO
{  chkrefs(2)
   IF debug>0 DO wrcode(f, "L%n", n)
   codeb(f)
   codeb(0)
   relref(stvp-2, n)
}

LET genh(f, h) BE IF incode DO  // Assume 0 <= h <= #xFFFF
{  chkrefs(3)
   IF debug>0 DO wrcode(f, "%n", h)
   codeb(f)
   code2b(h)
}

LET genw(f, w) BE IF incode DO
{  chkrefs(5)
   IF debug>0 DO wrcode(f, "%n", w)
   codeb(f)
   code4b(w)
}

AND checkspace() BE IF stvp/4>dp-stv DO
{  cgerror("Program too large, %n bytes compiled", stvp)
   errcount := errcount+1
   longjump(fin_p, fin_l)
}

AND codeb(byte) BE
{  stv%stvp := byte
   stvp := stvp + 1
   checkspace()
}

AND code2b(h) BE TEST bigender
THEN {  codeb(h>>8 ); codeb(h    )  }
ELSE {  codeb(h    ); codeb(h>>8 )  }

AND code4b(w) BE TEST bigender
THEN {  codeb(w>>24); codeb(w>>16); codeb(w>>8 ); codeb(w    )  }
ELSE {  codeb(w    ); codeb(w>>8 ); codeb(w>>16); codeb(w>>24)  }

AND pack4b(b0, b1, b2, b3) =
  bigender -> b0<<24 | b1<<16 | b2<<8 | b3,
              b3<<24 | b2<<16 | b1<<8 | b0

AND codec(c) BE
{  IF debug>0 DO writef("%i4:  DATAC %n*n", stvp, c)
   codeb(c)
}

AND codeh(h) BE
{  IF debug>0 DO writef("%i4:  DATAH %n*n", stvp, h)
   code2b(h)
}

AND codew(w) BE
{  IF debug>0 DO writef("%i4:  DATAW 0x%x8*n", stvp, w)
   code4b(w)
}

AND codewl(lab) BE
{  IF debug>0 DO writef("%i4:  DATAW L%n*n", stvp, lab)
   !relocliste := getblk(0, stvp, lab)
   relocliste := !relocliste
   code4b(0)
}

AND coder(n) BE
{  LET labval = labv!n
   IF debug>0 DO writef("%i4:  DATAH L%n-$*n", stvp, n)
   code2b(0)
   TEST labval=-1 THEN {  !refliste := getblk(0, stvp-2, n)
                          refliste := !refliste
                       }
                  ELSE puth(stvp-2, labval-stvp+2)
}

AND getw(a) = 
   bigender -> stv%a<<24 | stv%(a+1)<<16 | stv%(a+2)<<8  | stv%(a+3),
               stv%a     | stv%(a+1)<<8  | stv%(a+2)<<16 | stv%(a+3)<<24

AND puth(a, w) BE
   TEST bigender
   THEN stv%a,     stv%(a+1) := w>>8, w
   ELSE stv%(a+1), stv%a     := w>>8, w

AND putw(a, w) BE
   TEST bigender
   THEN stv%a, stv%(a+1), stv%(a+2), stv%(a+3) := w>>24,w>>16, w>>8, w
   ELSE stv%(a+3), stv%(a+2), stv%(a+1), stv%a := w>>24,w>>16, w>>8, w

AND align(n) BE UNTIL stvp REM n = 0 DO codeb(0)

AND chkrefs(n) BE  // Resolve references until it is possible
                   // to compile n bytes without a reference
                   // going out of range.
{  LET p = @rlist

   skiplab := 0

   UNTIL !p=0 DO
   {  LET r = !p
      LET a = h2!r // RLIST is ordered in increasing A.

      IF (stv%a & 1) = 0 DO
      // An unresolved reference at address A
      {  IF inrange_i(a, stvp+n+3) BREAK
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
      ELSE {  !p := !r   // Free item if already resolved
              freeblk(r) // and no longer in direct range.
              IF !p=0 DO rliste := p  // Correct RLISTE.
           }
   }

   // At this point all necessary indirect data words have
   // been compiled.

   UNLESS skiplab=0 DO {  setlab(skiplab)
                          skiplab, incode := 0, TRUE
                       }
}

AND genindword(l) BE  // Called only from CHKREFS.
{  LET r = rlist      // Assume RLIST ~= 0

   IF incode DO
   {  skiplab := newlab()
      // genr(f_j, skiplab) without the call of chkrefs(2).
      IF debug>0 DO wrcode(f_j, "L%n", skiplab)
      codeb(f_j)
      codeb(0)
      relref(stvp-2, skiplab)
      incode := FALSE
   }

   align(2)

   UNTIL r=0 DO
   {  IF h3!r=l & (stv%(h2!r) & 1)=0 DO fillref_i(h2!r, stvp)
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
{  LET rel = (p-a)/2
   RESULTIS 0 <= rel <= 255
}

AND fillref_d(a, p) BE
{  stv%a := stv%a & 254  // Back to direct form if neccessary.
   stv%(a+1) := p-a-1
}

AND fillref_i(a, p) BE  // P is even.
{  stv%a := stv%a | 1   // Force indirect form.
   stv%(a+1) := (p-a)/2
}

AND relref(a, l) BE
// RELREF is only called just after compiling
// a relative reference instruction at
// address A (=stvp-2).
{  LET labval = labv!l

   IF labval>=0 & inrange_d(a, labval) DO {  fillref_d(a, labval)
                                             RETURN
                                          }

   // All other references in RLIST have
   // addresses smaller than A and so RLIST will
   // remain properly ordered if this item
   // is added to the end.
   !rliste := getblk(0, a, l)
   rliste := !rliste
}

LET outputmodule() BE
{  LET p, relocs = reloclist, 0

   UNTIL p=0 DO {  LET a, lab = h2!p, h3!p
                   LET labval = labv!lab
                   relocs, p := relocs+1, h1!p
                   TEST labval=-1
                   THEN cgerror("Label L%n unset", h3!reflist)
                   ELSE putw(a, getw(a)+labval)
                }

   UNTIL reflist=0 DO {  cgerror("Label L%n unset", h3!reflist)
                         reflist := !reflist
                      }

   IF bining DO {  LET outstream = output()
                   selectoutput(tostream)  // Output a HUNK.
                   newline()
                   objword(t_hunk)
                   objword(stvp/4)
                   FOR p=0 TO stvp-4 BY 4 DO
                   {  IF p REM 20 = 0 DO newline()
                      objword(getw(p))
                   }
                   newline()
                   UNLESS relocs=0 DO
                   {  LET n = 0
                      p := reloclist
                      objword(t_reloc)
                      objword(relocs)
                      UNTIL p=0 DO {  IF n REM 5 = 0 DO newline()
                                      objword(h2!p)
                                      n, p := n+1, h1!p
                                   }
                      newline()
                   }
                   selectoutput(outstream)
                }
}

AND objword(a) BE writef("%X8 ", a)

AND dboutput() BE
{  LET p = info_a
   writef("ssp=%i2 ", ssp)
   writes("A=(")
   UNTIL p=0 DO {  wrkni(h2!p, h3!p, h4!p)
                   p := !p
                   UNLESS p=0 DO wrch('*s')
                }
    
   p := info_b
   writes(") B=(")
   UNTIL p=0 DO {  wrkni(h2!p, h3!p, h4!p)
                   p := !p
                   UNLESS p=0 DO wrch('*s')
                }
   wrch(')')
   
   IF debug=2 DO {  writes("  ")
                    FOR p=tempv TO arg1 BY 4  DO
                    {  IF (p-tempv) REM 30 = 10 DO newline()
                       wrkni(h1!p,h2!p,h3!p)
                       wrch('*s')
                    }
                 }
   
   IF debug=3 DO {   LET l = rlist
                     writes("*nREFS ")
                     UNTIL l=0 DO {  writef("%n L%n  ", l!1, l!2)
                                     l := !l
                                  }
                 }
   newline()
}

AND wrkni(k, n, i) BE SWITCHON k INTO
   {  DEFAULT:       writef("?");            RETURN
      CASE k_none:   writef("-");            RETURN
      CASE k_numb:   writef("N%n", n);       RETURN
      CASE k_fnlab:  writef("F%n", n);       RETURN
      CASE k_lvloc:  writef("@P%n", n);      RETURN
      CASE k_lvglob: writef("@G%n", n);      RETURN
      CASE k_lvlab:  writef("@L%n", n);      RETURN
      CASE k_a:      writef("A", n);         RETURN
      CASE k_b:      writef("B");            RETURN
      CASE k_loc:    writef("P%n", n);       RETURN
      CASE k_glob:   writef("G%n", n);       RETURN
      CASE k_lab:    writef("L%n", n);       RETURN
      CASE k_loci:   writef("%nP%n", i, n);  RETURN
      CASE k_lvloci: writef("@%nP%n", i, n); RETURN
      CASE k_glob0:  writef("0G%n", n);      RETURN
      CASE k_glob1:  writef("1G%n", n);      RETURN
      CASE k_glob2:  writef("2G%n", n);      RETURN
   }

AND wrcode(f, form, a, b) BE
{  //IF debug=2 DO dboutput()
   writef("%i4: ", stvp)
   wrfcode(f)
   writes("  ")
   writef(form, a, b)
   newline()
}

AND wrfcode(f) BE
{  LET s = VALOF SWITCHON f&31 INTO
   {  DEFAULT:
      CASE  0: RESULTIS "     -     K   LLP     L    LP    SP    AP     A"
      CASE  1: RESULTIS "     -    KH  LLPH    LH   LPH   SPH   APH    AH"
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
      CASE 13: RESULTIS "   LF$   L0G  L0G1  L0GH  LP13  SP13  INDW     S"
      CASE 14: RESULTIS "    LM   L1G  L1G1  L1GH  LP14  SP14   LMH    SH"
      CASE 15: RESULTIS "   LM1   L2G  L2G1  L2GH  LP15  SP15   BTC  MDIV"
      CASE 16: RESULTIS "    L0    LG   LG1   LGH  LP16  SP16   NOP CHGCO"
      CASE 17: RESULTIS "    L1    SG   SG1   SGH   SYS    S1    A1   NEG"
      CASE 18: RESULTIS "    L2   LLG  LLG1  LLGH LVIND    S2    A2   NOT"
      CASE 19: RESULTIS "    L3    AG   AG1   AGH   STB    S3    A3 INC1B"
      CASE 20: RESULTIS "    L4   MUL   ADD    RV    ST    S4    A4 INC4B"
      CASE 21: RESULTIS "    L5   DIV   SUB   RV1   ST1   XCH    A5 DEC1B"
      CASE 22: RESULTIS "    L6   MOD   LSH   RV2   ST2  INDB  RVP3 DEC4B"
      CASE 23: RESULTIS "    L7   XOR   RSH   RV3   ST3 INDB0  RVP4 INC1A"
      CASE 24: RESULTIS "    L8    SL   AND   RV4  STP3   ATC  RVP5 INC4A"
      CASE 25: RESULTIS "    L9   SL$    OR   RV5  STP4   ATB  RVP6 DEC1A"
      CASE 26: RESULTIS "   L10    LL   LLL   RV6  STP5     J  RVP7 DEC4A"
      CASE 27: RESULTIS "  FHOP   LL$  LLL$   RTN     -    J$ ST0P3     -"
      CASE 28: RESULTIS "   JEQ   JNE   JLS   JGR   JLE   JGE ST0P4  HAND"
      CASE 29: RESULTIS "  JEQ$  JNE$  JLS$  JGR$  JLE$  JGE$ ST1P3 HAND$"
      CASE 30: RESULTIS "  JEQ0  JNE0  JLS0  JGR0  JLE0  JGE0 ST1P4   UNH"
      CASE 31: RESULTIS " JEQ0$ JNE0$ JLS0$ JGR0$ JLE0$ JGE0$   CTA RAISE"
   }
   LET n = f>>5 & 7
   FOR i = 6*n+1 TO 6*(n+1) DO wrch(s%i)
}

