/* Change history

11/6/96
First written

*/

SECTION "SIAL2CIN"


GET "libhdr"

MANIFEST {
t_hunk  = 1000       // Object module item types.
t_end   = 1002

sectword  = #xFDDF   // SECTION and Entry marker words.
entryword = #xDFDF


// Sial op codes and directive

c_lp=     1
c_lg=     2
c_ll=     3

c_llp=    4
c_llg=    5
c_lll=    6
c_lf=     7
c_lw=     8

c_l=      10
c_lm=     11

c_sp=     12
c_sg=     13
c_sl=     14

c_ap=     15
c_ag=     16
c_a=      17
c_s=      18

c_lkp=    20
c_lkg=    21
c_rv=     22
c_rvp=    23
c_rvk=    24
c_st=     25
c_stp=    26
c_stk=    27
c_stkp=   28
c_skg=    29

c_k=      35
c_kpg=    36

c_neg=    37
c_not=    38
c_abs=    39

c_mul=    45
c_div=    46
c_rem=    47
c_add=    48
c_sub=    49

c_eq=     50
c_ne=     51
c_ls=     52
c_gr=     53
c_le=     54
c_ge=     55
c_eq0=    56
c_ne0=    57
c_ls0=    58
c_gr0=    59
c_le0=    60
c_ge0=    61

c_lsh=    65
c_rsh=    66
c_and=    67
c_or=     68
c_xor=    69
c_eqv=    70

c_gbyt=   75
c_pbyt=   76
c_xpbyt=  77

c_swb=    78
c_swl=    79

c_xch=    80
c_atc=    81
c_atb=    82
c_btc=    83

c_j=      90
c_rtn=    91
c_goto=   92
c_jeq=    100
c_jne=    101
c_jls=    102
c_jgr=    103
c_jle=    104
c_jge=    105
c_jeq0=   106
c_jne0=   107
c_jls0=   108
c_jgr0=   109
c_jle0=   110
c_jge0=   111
c_jge0m=  112

c_brk=    120
c_nop=    121
c_chgco=  122
c_mdiv=   123
c_sys=    124

c_section=  130
c_modstart= 131
c_modend=   132
c_global=   133
c_string=   134
c_const=    135
c_static=   136
c_mlab=     137
c_lab=      138
c_lstr=     139
c_entry=    140

h1=0; h2=1; h3=2  // Selectors.
}

GLOBAL {
stdin:200; stdout:201; verout:202
sialin:203; cinout:204
workvec: 205
workvecsize: 206

fin_p:237; fin_l:238
errcount:291; errmax:292

codegenerate: 300

// Global procedures.
rdl      : 302
rdgn     : 303
cgerror  : 304

scan     : 310

gensp    : 320
genlp    : 321
genllp   : 322
genln    : 323
genap    : 324
genlkpn  : 325
genlkgn  : 326
genrvp   : 327
genrvk   : 328
genstpn  : 329
genstk   : 330
genstkpn : 331
genstkgn : 332

genkp    : 333
genkpg   : 334
genrel   : 335



genaddk    : 340
genglobal  : 341
genentry   : 342
genswb     : 343
genswl     : 344
gensection : 345
genmodstart: 346
genmodend  : 347

genstring : 350
genconst  : 351
genstatic : 352
setlab    : 353

getblk    : 365
freeblk   : 366
freeblks  : 367

initdatalists : 368

geng     : 369
gen      : 370
genb     : 371
genr     : 372
genh     : 373
genw     : 374

checkspace : 375
codeb      : 376
code2b     : 377
code4b     : 378
pack4b     : 379
codeh      : 380
codew      : 381
coder      : 382

getw       : 383
puth       : 384
putw       : 385
align      : 386
chkrefs    : 387
dealwithrefs:388
genindword : 389
inrange_d  : 390
inrange_i  : 391
fillref_d  : 392
fillref_i  : 393
relref     : 394

outputsection : 395
wrword   : 396
wrhex2   : 397
wrword_at: 398
dboutput : 399
wrcode   : 401
wrfcode  : 402

// Global variables.

stv      : 408
stvp     : 409

dp       : 411
freelist : 412

incode   : 413
labv     : 414
labnumber: 415
newlab   : 416
mlab0    : 417

progsize : 431

reflist  : 434
refliste : 435
rlist    : 436
rliste   : 437
skiplab  : 440

bigender : 450
naming   : 451
debug    : 452
bining   : 453
}


// CINTCODE function codes.
MANIFEST {
f_k0   =   0
f_brk  =   2
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
f_sys  = 145
f_swb  = 146
f_swl  = 147
f_st   = 148
f_st0  = 148
f_stp0 = 149
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
}

LET start() = VALOF
{ LET argv = VEC 50
  AND argform =
  "FROM/A,TO/K,VER/K,NONAMES/S,D1/S,D2/S,OENDER/S"

  stdin  := input()
  stdout := output()
  verout := stdout

  errmax   := 30
  errcount := 0
  fin_p, fin_l := level(), fin

  workvecsize := 20000
  workvec  := getvec(workvecsize)

  IF workvec=0 DO { writef("Insufficient memory*n")
                    errcount := 1
                    GOTO fin
                 }

  sialin   := 0
  cinout   := 0
  
  writef("*nSIAL2CIN (18 June 1996)*n")
 
  IF rdargs(argform, argv, 50)=0 DO { writes("Bad arguments*n")
                                      errcount := 1
                                      GOTO fin
                                    }

  // Code generator options 

  bining   := TRUE
  naming   := TRUE
  debug    := 0
  bigender := (!"AAA" & 255) = 'A' // =TRUE if running on a bigender

  IF argv!3 DO naming   := FALSE         // NONAMES
  IF argv!4 DO debug    := debug+1       // D1
  IF argv!5 DO debug    := debug+2       // D2
  IF argv!6 DO bigender := ~bigender     // OENDER

  sialin := findinput(argv!0)      // FROM

  IF sialin=0 DO { writef("Trouble with file %s*n", argv!0)
                   errcount := 1
                   GOTO fin
                 }

  selectinput(sialin)
 
  UNLESS argv!2=0 DO       // VER
  { verout := findoutput(argv!2)
    IF verout=0 DO
    { verout := stdout
      writef("Trouble with file %s*n", argv!2)
      errcount := 1
      GOTO fin
    }
  }
   
  cinout := findoutput(argv!1)

  IF cinout=0 DO cinout := verout

  selectinput(sialin)
  selectoutput(verout)
  codegenerate()

fin:
  UNLESS sialin=0      DO { selectinput(sialin);     endread()  }
  UNLESS cinout=0      DO { selectoutput(cinout)
                            UNLESS cinout=stdout DO  endwrite() }
  UNLESS verout=stdout DO { selectoutput(verout);    endwrite() }
  UNLESS workvec=0     DO freevec(workvec)
  selectoutput(stdout)
  RESULTIS errcount=0 -> 0, 20
}
 
AND rdcode(let) = VALOF
$( LET a, ch, neg = 0, ?, FALSE

   ch := rdch() REPEATWHILE ch='*s' | ch='*n'

   IF ch=endstreamch RESULTIS -1

   UNLESS ch=let DO error("Bad item, looking for %c found %c*n", let, ch)

   ch := rdch()

   IF ch='-' DO { neg := TRUE; ch := rdch() }

   WHILE '0'<=ch<='9' DO $( a := 10*a + ch - '0'; ch := rdch()  $)

   RESULTIS neg -> -a, a
$)

AND rdf() = rdcode('F')
AND rdp() = rdcode('P')
AND rdg() = rdcode('G')
AND rdk() = rdcode('K')
AND rdh() = rdcode('H')
AND rdw() = rdcode('W')
AND rdl() = rdcode('L')
AND rdm() = rdcode('M') + mlab0
AND rdc() = rdcode('C')

AND error(mess, a, b, c) BE
$( LET out = output()
   UNLESS out=stdout DO
   $( selectoutput(stdout)
      writef(mess, a, b, c)
      selectoutput(out)
   $)
   writef(mess, a, b, c)
$)

AND newlab() = VALOF
{ labnumber := labnumber-1
  RESULTIS labnumber
}

AND scan() BE
$( LET op = rdf()

   SWITCHON op INTO

   $( DEFAULT:       error("Bad op %n*n", op); LOOP

      CASE -1:       RETURN
      
      CASE c_lp:     genlp(rdp())      // LP3 .. LP16   LP  LPH  LPW
                     ENDCASE
      CASE c_lg:     geng(f_lg, rdg()) // LG  LG1  LGH
                     ENDCASE
      CASE c_ll:     genr(f_ll, rdl()) // LL   LL$
                     ENDCASE

      CASE c_llp:    genllp(rdp()); ENDCASE       // LLP
      CASE c_llg:    geng(f_llg, rdg()); ENDCASE  // LLG  LLG1  LLGH
      CASE c_lll:    genr(f_lll, rdl()); ENDCASE  // LLL   LLL$
      CASE c_lf:     genr(f_lf, rdl());  ENDCASE  // LF  LF$
      CASE c_lw:     genr(f_ll, rdm());  ENDCASE  // LL  LL$ for big consts

      CASE c_l:      genln(rdk());  ENDCASE    // L0 .. L10  L  LH  LW
      CASE c_lm:     genln(-rdk()); ENDCASE    // LM1  LMH

      CASE c_sp:     gensp(rdp()); ENDCASE      // SP3 .. SP16  SPH  SPW
      CASE c_sg:     geng(f_sg, rdg()); ENDCASE // SG  SG1  SGH
      CASE c_sl:     genr(f_sl, rdl()); ENDCASE // SL

      CASE c_ap:     genap(rdp()); ENDCASE       // AP3 .. AP12  AP  APH  APW
      CASE c_ag:     geng(f_ag, rdg()); ENDCASE // AG  AG1  AGH
      CASE c_a:      genaddk(rdk());  ENDCASE    // A1 .. A5  A  AH  AW
      CASE c_s:      genaddk(-rdk());  ENDCASE   // S1 .. S4  S  SH

      CASE c_lkp:  { LET k = rdk()  // L0P3 .. L0P12 L1P3 .. L1P6
                     LET n = rdp()  // L2P3 .. L2P5  L3P3 .. L3P4
                     genlkpn(k, n)  // L4P3 .. L4P4
                     ENDCASE
                   }
      CASE c_lkg:  { LET k = rdk()  // L0G   L0G1   L0GH
                     LET n = rdg()  // L1G   L1G1   L1GH
                     genlkgn(k, n)  // L2G   L2G1   L2GH
                     ENDCASE 
                   }

      CASE c_rv:     gen(f_rv);  ENDCASE    // RV
      CASE c_rvp:    genrvp(rdp());   ENDCASE // RVP3 ... RVP7
      CASE c_rvk:    genrvk(rdk());   ENDCASE // RV1 ... RV6
      CASE c_st:     gen(f_st);  ENDCASE    // ST
      CASE c_stp:    genstpn(rdp());   ENDCASE // STP3 .. STP5
      CASE c_stk:    genstk(rdk());   ENDCASE // ST1  ST2  ST3  ST4
      CASE c_stkp: { LET k = rdk()  // ST0P3  ST0P4  ST1P3  ST1P4
                     LET n = rdp()
                     genstkpn(k, n)
                     ENDCASE
                   }
      CASE c_skg:  { LET k = rdk()  // ST0G  ST0G1  ST0GH
                     LET g = rdg()
                     genstkgn(k, g)
                     ENDCASE
                   }
      CASE c_k:      genkp(rdp());  ENDCASE  // K3 .. K11  K  KH  KW
      CASE c_kpg:    genkpg(rdp()); ENDCASE  // K3G .. K11G  +G1  +GH

      CASE c_neg:    gen(f_neg);  ENDCASE   // NEG
      CASE c_not:    gen(f_not);  ENDCASE   // NOT
      CASE c_abs:    chkrefs(3)
                     genb(f_jgr0, 2)      // Conditionally skip
                     gen(f_neg)           // over this NEG instruction.
                     ENDCASE
      CASE c_mul:    gen(f_mul);  ENDCASE  // MUL
      CASE c_div:    gen(f_div);  ENDCASE  // DIV
      CASE c_rem:    gen(f_rem);  ENDCASE  // REM
      CASE c_add:    gen(f_add);  ENDCASE  // ADD
      CASE c_sub:    gen(f_sub);  ENDCASE  // SUB

      CASE c_eq:     genrel(f_jeq);  ENDCASE
      CASE c_ne:     genrel(f_jne);  ENDCASE
      CASE c_ls:     genrel(f_jls);  ENDCASE
      CASE c_gr:     genrel(f_jgr);  ENDCASE
      CASE c_le:     genrel(f_jle);  ENDCASE
      CASE c_ge:     genrel(f_jge);  ENDCASE
      CASE c_eq0:    genrel(f_jeq0); ENDCASE
      CASE c_ne0:    genrel(f_jne0); ENDCASE
      CASE c_ls0:    genrel(f_jls0); ENDCASE
      CASE c_gr0:    genrel(f_jgr0); ENDCASE
      CASE c_le0:    genrel(f_jle0); ENDCASE
      CASE c_ge0:    genrel(f_jge0); ENDCASE

      CASE c_lsh:    gen(f_lsh);  ENDCASE  // LSH
      CASE c_rsh:    gen(f_rsh);  ENDCASE  // RSH
      CASE c_and:    gen(f_and);  ENDCASE  // AND
      CASE c_or:     gen(f_or);   ENDCASE  // OR
      CASE c_xor:    gen(f_xor);  ENDCASE  // XOR
      CASE c_eqv:    gen(f_xor); gen(f_not); ENDCASE

      CASE c_gbyt:   gen(f_gbyt);  ENDCASE // GBYT
      CASE c_pbyt:   gen(f_pbyt);  ENDCASE // PBYT
      CASE c_xpbyt:  gen(f_xpbyt); ENDCASE // XPBYT

      CASE c_swb:    genswb(); ENDCASE   // SWB
      CASE c_swl:    genswl(); ENDCASE   // SWL

      CASE c_xch:    gen(f_xch); ENDCASE   // XCH
      CASE c_atc:    gen(f_atc); ENDCASE   // ATC
      CASE c_atb:    gen(f_atb); ENDCASE   // ATB
      CASE c_btc:    gen(f_btc); ENDCASE   // BTC

      CASE c_j:      genr(f_j, rdl()); incode := FALSE; ENDCASE // J  J$
      CASE c_rtn:    gen(f_rtn);       incode := FALSE; ENDCASE // RTN
      CASE c_goto:   gen(f_goto);      incode := FALSE; ENDCASE // GOTO
                     chkrefs(50)

      CASE c_jeq:    genr(f_jeq,  rdl()); ENDCASE  // JEQ  JEQ$
      CASE c_jne:    genr(f_jne,  rdl()); ENDCASE  // JNE  JNE$
      CASE c_jls:    genr(f_jls,  rdl()); ENDCASE  // JLS  JLS$
      CASE c_jgr:    genr(f_jgr,  rdl()); ENDCASE  // JGR  JGR$
      CASE c_jle:    genr(f_jle,  rdl()); ENDCASE  // JLE  JLE$
      CASE c_jge:    genr(f_jge,  rdl()); ENDCASE  // JGE  JGE$
      CASE c_jeq0:   genr(f_jeq0, rdl()); ENDCASE  // JEQ0 JEQ0$
      CASE c_jne0:   genr(f_jne0, rdl()); ENDCASE  // JNE0 JNE0$
      CASE c_jls0:   genr(f_jls0, rdl()); ENDCASE  // JLS0 JLS0$
      CASE c_jgr0:   genr(f_jgr0, rdl()); ENDCASE  // JGR0 JGR0$
      CASE c_jle0:   genr(f_jle0, rdl()); ENDCASE  // JLE0 JLE0$
      CASE c_jge0:   genr(f_jge0, rdl()); ENDCASE  // JGE0 JGE0$
      CASE c_jge0m:  genr(f_jge0, rdm()); ENDCASE

      CASE c_brk:    gen(f_brk);   ENDCASE
      CASE c_nop:    gen(f_nop);   ENDCASE
      CASE c_chgco:  gen(f_chgco); ENDCASE
      CASE c_mdiv:   gen(f_mdiv);  ENDCASE
      CASE c_sys:    gen(f_sys);   ENDCASE

      CASE c_section:  gensection(); ENDCASE
      CASE c_modstart: genmodstart(); ENDCASE
      CASE c_modend:   genmodend();   ENDCASE
      CASE c_global:   genglobal();     ENDCASE
      CASE c_string:   genstring();     ENDCASE
      CASE c_const:    genconst();      ENDCASE
      CASE c_mlab:   UNLESS incode DO chkrefs(30)
                     setlab(rdm())
                     ENDCASE

      CASE c_lab:    UNLESS incode DO chkrefs(30)
                     setlab(rdl())
                     incode := TRUE
                     ENDCASE

      CASE c_static: genstatic(); ENDCASE

      CASE c_lstr:   genr(f_lll, rdm()); ENDCASE
      CASE c_entry:  genentry(rdk());    ENDCASE
   $)
$) REPEAT

LET codegenerate() BE
{ 
   IF workvecsize<2000 DO { cgerror("Too little workspace")
                            errcount := errcount+1
                            longjump(fin_p, fin_l)
                          }

   progsize := 0

   scan()
   writef("Program size = %n bytes*n", progsize)
}


AND genmodstart() BE
{ LET p = workvec
  labv := p
  dp := workvec+workvecsize
  labnumber := (dp-p)/10+10
  mlab0 := (3*labnumber)/4
  p := p+labnumber
  FOR lp = labv TO p-1 DO !lp := -1
  stv := p
  stvp := 0
  incode := FALSE
  initdatalists()

  codew(0)  // For size of module.
}

AND gensection() BE
{ LET n = rdk()
  LET v = VEC 3
  v%0 := 7
  FOR i = 1 TO n DO  { LET c = rdc()
                       IF i<=7 DO v%i := c
                     }
  FOR i = n+1 TO 7 DO v%i := 32  //ASCII space.
  IF naming DO
  { codew(sectword)
    codew(pack4b(v%0, v%1, v%2, v%3))
    codew(pack4b(v%4, v%5, v%6, v%7))
  }
}

AND genmodend() BE
{ putw(0, stvp/4)  // Plant size of module.
  outputsection()
  progsize := progsize + stvp
}


AND genrel(f) BE
{ chkrefs(4)
  genb(f, 2)    // Jump to    ---
  gen(f_fhop)   //               |
  gen(f_lm1)    // this point  <-
}

AND genln(n) BE
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

AND genllp(n) BE TEST 0<=n<=255
                 THEN genb(f_llp, n)
                 ELSE TEST 0<=n<=#xFFFF
                      THEN genh(f_llph, n)
                      ELSE genw(f_llpw, n)

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


AND genlkpn(k, n) BE
{ IF n>=3 SWITCHON k INTO
  { DEFAULT: ENDCASE
    CASE 0: IF n<=12 DO { gen(f_l0p0+n); RETURN }
    CASE 1: IF n<=6  DO { gen(f_l1p0+n); RETURN }
    CASE 2: IF n<=5  DO { gen(f_l2p0+n); RETURN }
    CASE 3: IF n<=4  DO { gen(f_l3p0+n); RETURN }
    CASE 4: IF n<=4  DO { gen(f_l4p0+n); RETURN }
  }
  genlp(n)
  genrvk(k)
}

AND genlkgn(k, n) BE
{ SWITCHON k INTO
  { DEFAULT: ENDCASE
    CASE 0: geng(f_l0g, n); RETURN
    CASE 1: geng(f_l1g, n); RETURN
    CASE 2: geng(f_l2g, n); RETURN
  }
  geng(f_lg, n)
  genrvk(k)
}

AND genrvp(n) BE  // RVP3 ... RVP7
{ IF 3<=n<=7 DO { gen(f_rvp0+n); RETURN }
  genap(n)
  gen(f_rv)
}

AND genrvk(k) BE // RV1 ... RV6
{ IF 0<=k<=6 DO { gen(f_rv+k); RETURN }
  genaddk(k)
  gen(f_rv) 
}

AND genstpn(n) BE // STP3 .. STP5
{ IF 3<=n<=5 DO { gen(f_stp0+n); RETURN }
  genlp(n)
  gen(f_st)
}

AND genstk(k) BE // ST  ST1  ST2  ST3  ST4
{ IF 0<=k<=3 DO { gen(f_st+k); RETURN }
  genaddk(k)
  gen(f_st)
}

AND genstkpn(k, n) BE  // ST0P3  ST0P4  ST1P3  ST1P4
{ SWITCHON k INTO
  { DEFAULT: ENDCASE
    CASE 0: IF 3<=n<=4 DO { gen(f_st0p0+n); RETURN }
    CASE 1: IF 3<=n<=4 DO { gen(f_st1p0+n); RETURN }
  }
  genlp(n)
  genstk(k)
}

AND genstkgn(k, n) BE // ST0G  ST0G1  ST0GH
{ SWITCHON k INTO
  { DEFAULT: ENDCASE
    CASE 0: { geng(f_s0g, n); RETURN }
  }
  geng(f_lg, n)
  genstk(k)
}



AND genap(n) BE
      TEST 3<=n<=12 THEN gen(f_ap0 + n)
                    ELSE TEST 0<=n<=255
                         THEN genb(f_ap, n)
                         ELSE TEST 0<=n<=#xFFFF
                              THEN genh(f_aph, n)
                              ELSE genw(f_apw, n)


AND genaddk(k) BE UNLESS k=0 DO  // Compile code to add k to A.
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
}

AND genglobal() BE
{ LET n = rdk()
  incode := FALSE
  chkrefs(512)   // Deal with ALL outstanding refs.
  align(4)
  codew(0)       // Compile Global initialisation data.
  FOR i = 1 TO n DO { codew(rdg()); codew(labv!rdl()) }
  codew(rdg())
}


AND genentry(n) BE
{ LET v = VEC 3
   v%0 := 7
   FOR i = 1 TO n DO { LET c = rdc()
                        IF i<=7 DO v%i := c
                     }
   FOR i = n+1 TO 7 DO v%i := 32  // Ascii SPACE.
   chkrefs(80)  // Deal with some forward refs.
   align(4)
   IF naming DO { codew(entryword)
                   codew(pack4b(v%0, v%1, v%2, v%3))
                   codew(pack4b(v%4, v%5, v%6, v%7))
                }
   IF debug>0 DO writef("// Entry to:   %s*n", v)
}

AND genkp(k) BE
{ TEST 3<=k<=11
  THEN gen(f_k0+k)
  ELSE TEST 0<=k<=255
       THEN genb(f_k, k)
       ELSE TEST 0<=k<=#xFFFF
            THEN genh(f_kh, k)
            ELSE genw(f_kw, k)
}

AND genkpg(k) BE
{ LET n = rdg()

  IF 3<=k<=11 DO { geng(f_k0g+k, n); RETURN }

  geng(f_lg, n)

  genkp(k)
}

AND genswb() BE
{ LET n = rdk()
  LET dlab = rdl()
  chkrefs(6+4*n) // allow for padding to 7 cases
  gen(f_swb)
  align(2)
  codeh(n)
  coder(dlab)
  FOR i = 1   TO n DO { codeh(rdk()); coder(rdl()) }
  FOR i = n+1 TO 7 DO { codeh(0); coder(dlab) }
}

AND genswl() BE
{ LET n = rdk()
  LET dlab = rdl()
  chkrefs(2*n+6)
  gen(f_swl)
  align(2)
  codeh(n)
  coder(dlab)        // Default label.

  FOR i = 1 TO n DO coder(rdl())
}

AND genstring() BE
{ LET lab = rdm()
  LET n = rdk()
  LET a = n
  chkrefs(n + 3) // +3 because align(4) might generate 3 bytes
  align(4)
  setlab(lab)

  { LET b, c, d = 0, 0, 0
    IF n>0 DO b := rdc()
    IF n>1 DO c := rdc()
    IF n>2 DO d := rdc()
    codew(pack4b(a, b, c, d))
    IF n<=3 BREAK
    n, a := n-4, rdc()
  } REPEAT
}

AND genconst() BE
{ LET lab = rdm()
  chkrefs(4 + 3) // +3 because align(4) might generate 3 bytes
  align(4)
  setlab(lab)
  codew(rdw())
}

AND genstatic() BE
{ LET lab = rdl()
  LET n = rdk()
  chkrefs(4*n + 3) // +3 because align(4) might generate 3 bytes
  align(4)
  setlab(lab)
  FOR i = 1 TO n DO codew(rdw())
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
{ reflist, refliste := 0, @reflist
  rlist,   rliste   := 0, @rlist
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
{ chkrefs(5)
  IF debug>0 DO wrcode(f, "%n", w)
  codeb(f)
  code4b(w)
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

AND pack4b(b0, b1, b2, b3) =
  bigender -> b0<<24 | b1<<16 | b2<<8 | b3,
              b3<<24 | b2<<16 | b1<<8 | b0

AND codeh(h) BE
{ IF debug>0 DO writef("%i4:  DATAH %n*n", stvp, h)
  code2b(h)
}

AND codew(w) BE
{ IF debug>0 DO writef("%i4:  DATAW 0x%x8*n", stvp, w)
  code4b(w)
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
{ LET r = rlist       // Assume RLIST ~= 0

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
{ stv%a := stv%a | 1    // Force indirect form.
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
{ UNTIL reflist=0 DO { cgerror("Label L%n unset", h3!reflist)
                       reflist := !reflist
                     }

  IF bining DO { LET outstream = output()
                 selectoutput(cinout)  // Output a HUNK.
                 newline()
                 wrword(t_hunk)
                 wrword(stvp/4)
                 FOR p=0 TO stvp-4 BY 4 DO
                 { IF p REM 20 = 0 DO newline()
                   wrword_at(p)
                 }
                 newline()
                 selectoutput(outstream)
               }
}

AND wrword(a) BE writef("%X8 ", a)

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
                     }
                ELSE { wrhex2(stv%(a+3))
                       wrhex2(stv%(a+2))
                       wrhex2(stv%(a+1))
                       wrhex2(stv%(a))
                     }
  wrch(' ')
}

AND dboutput() BE
{ IF debug=1 DO { LET l = rlist
                  writes("*nREFS ")
                  UNTIL l=0 DO { writef("%n L%n  ", l!1, l!2)
                                 l := !l
                               }
                }
  newline()
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
    CASE 30: RESULTIS "  JEQ0  JNE0  JLS0  JGR0  JLE0  JGE0 ST1P4     -"
    CASE 31: RESULTIS " JEQ0$ JNE0$ JLS0$ JGR0$ JLE0$ JGE0$     -     -"
  }
  LET n = f>>5 & 7
  FOR i = 6*n+1 TO 6*(n+1) DO wrch(s%i)
}


