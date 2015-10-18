// This is an old and out of date OCODE to MIPS assembler codegenerator
// written by a student

SECTION "CINCG"

// Header file for the CINTCODE32 code-generator
// based on the CINTCODE code-generator (1980).
// Copyright  M.Richards  6 June 1991.

GET "libhdr"

MANIFEST $(
t_hunk  = 1000       // Object module item types.
t_end   = 1002

sectword  = #xFDDF   // SECTION and Entry marker words.
entryword = #xDFDF

// OCODE keywords.
s_true=4; s_false=5; s_rv=8; s_fnap=10
s_mult=11; s_div=12; s_rem=13
s_plus=14; s_minus=15; s_query=16; s_neg=17; s_abs=19
s_eq=20; s_ne=21; s_ls=22; s_gr=23; s_le=24; s_ge=25
s_not=30; s_lshift=31; s_rshift=32; s_logand=33
s_logor=34; s_eqv=35; s_neqv=36
s_lf=39; s_lp=40; s_lg=41; s_ln=42; s_lstr=43
s_ll=44; s_llp=45; s_llg=46; s_lll=47
s_needs=48; s_section=49; s_rtap=51; s_goto=52; s_finish=68
s_switchon=70; s_global=76; s_sp=80; s_sg=81; s_sl=82; s_stind=83
s_jump=85; s_jt=86; s_jf=87; s_endfor=88
s_lab=90; s_stack=91; s_store=92; s_rstack=93; s_entry=94
s_save=95; s_fnrn=96; s_rtrn=97; s_res=98
s_datalab=100; s_itemn=102; s_endproc=103; s_none=111
s_getbyte=120; s_putbyte=121

h1=0; h2=1; h3=2  // Selectors.
$)

GLOBAL $(
fin_p:237; fin_l:238
errcount:291; errmax:292; sysprint:294; gostream: 297

codegenerate: 399

// Global procedures.
cgsects  : 400
rdn      : 401
rdl      : 402
rdgn     : 403
nextlabel  : 404
checklab : 405
cgerror  : 406

initstack: 410
stack    : 411
store    : 412
scan     : 413
cgpendingop:414
load     : 415
loadba   : 416
setba    : 417

genxch   : 420
genatb   : 421
loada    : 422     // not used
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
loadt    : 441
lose1    : 442
swapargs : 443
cgstind  : 444
storein  : 445

cgrv     : 449
cgplus   : 450
cgaddk   : 451
cgglobal : 452
cgentry  : 453
cgapply  : 455
cgjump   : 457
jmpfn    : 458
jfn0     : 459
revjfn   : 460
compjfn  : 461
prepj    : 462

cgswitch : 470
switcht  : 471
switchseg: 472
switchb  : 473
switchl  : 474
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
codeh    : 501
codew    : 502
coder    : 503

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

dboutput : 522
wrkn     : 523
wrcode   : 524
wrfcode  : 525

// Global variables.
arg1     : 531
arg2     : 532
bining   : 533
casek    : 534
casel    : 535
ch       : 536
debug    : 537

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
procdepth: 558

progsize : 560
info_a   : 561
info_b   : 562
reflist  : 565
refliste : 566
rlist    : 568
rliste   : 569
skiplab  : 570
ssp      : 571

stv      : 580
stvp     : 581
tempt    : 583
tempv    : 584

// MY GLOBAL VARIABLES
genrrr	 : 586
genrnr   : 587
genr    : 588
genf	 : 590
remem	 : 591
initreglist : 592
forget	 : 593
movelist : 594
genpseudo : 597
gennum	 : 598
genpslab : 599
genstring : 600
reglist  : 601
inuse	 : 602
movetor  : 604
movetoanyr : 605
cgreturn : 606
datalabel :608
cgsave   : 609
genrrn   : 610
genrl    : 611
genl    : 612
codewl   : 613
endlab   : 614
regcontaining : 615
reginuse : 616
cgarith  : 618
cgrelation:619
switchspace:620
casek    :621
casel    :622
lswitch  :623
bswitch  :624
fnend    :625
cggetbyte:626
cgputbyte:627
fnlabel  :628
sdcount  :629
sectno   :630
$)


MANIFEST
$(
// Value descriptors.
k_none=0; k_numb=1; k_fnlab=2
k_lvloc=3; k_lvglob=4; k_lvlab=5
k_a=6; k_b=7; k_c=8
k_loc=9; k_glob=10; k_lab=11; 
k_loc0=12; k_loc1=13; k_loc2=14; k_loc3=15; k_loc4=16
k_glob0=17; k_glob1=18; k_glob2=19

// I added this one
k_reg=6

swapped=TRUE; notswapped=FALSE

// Global routine numbers.
gn_stop=2

// MY MANIFEST CONSTANTS
mf_la   =1
mf_lw   =2
mf_add  =3
mf_sw   =4
mf_j    =5
mf_li   =6
mf_move =7
mf_addi =8
mf_jal  =9
mf_sub  =10
mf_bgez =11
mf_nor  =12
mf_mult =13
mf_mflo =14
mf_div  =15
mf_rem  =16
mf_mfhi =17
mf_sll  =18
mf_srl  =19
mf_or   =20
mf_and  =21
mf_beq  =22
mf_bne  =23
mf_bltz =24
mf_bgtz =25
mf_blez =26
mf_xor  =27
mf_sb   =28
mf_lbu  =29

p_text  =100
p_word  =101
p_globl =102
p_ent   =103
p_end   =104
p_sdata =105
p_data  =106

r_p     =16
r_np    =17
r_g     =18
r_j     =20

regnotavail = 2031619
allregsused = 67108863
$)

////.
////SECTION "CINCG1"
////GET "CGHDR"

LET codegenerate(workspace, workspacesize) BE
$( writes("MIPSCG 1 April 1992*n")

   IF workspacesize<2000 DO $( cgerror("Too little workspace")
                               errcount := errcount+1
                               longjump(fin_p, fin_l)
                            $)

   progsize := 0

   op := rdn()

   selectoutput(gostream)
   cgsects(workspace, workspacesize)   
   selectoutput(sysprint)
   writef("Program size = %n*n",progsize)
   writef("Finished*n")
  
$)

///////////////// Functions to generate code /////////////

AND genrrr(f,r1,r2,r3) BE IF incode DO
$( genf(f)
   writef(" $%n,$%n,$%n*n",r1,r2,r3)
$)

AND genrnr(f,r1,num,r2) BE IF incode DO
$( genf(f)
   writef(" $%n,%n($%n)*n",r1,num,r2)
$)

AND genr(f,r) BE IF incode DO
$( genf(f)
   writef(" $%n*n",r)
$)

AND genrn(f,r,num) BE IF incode DO
$( genf(f)
   writef(" $%n,%n*n",r,num)
$)

AND genrr(f,r1,r2) BE IF incode DO
$( genf(f)
   writef(" $%n,$%n*n",r1,r2)
$)

AND genrrn(f,r1,r2,num) BE IF incode DO
$( genf(f)
   writef(" $%n,$%n,%n*n",r1,r2,num)
$)

AND genrl(f,r1,lab) BE IF incode DO
$( LET lablet = 'L' + sectno
   genf(f)
   writef(" $%n,%c%n*n",r1,lablet,lab)
$)

AND genrrl(f,r1,r2,lab) BE IF incode DO
$( LET lablet = 'L' + sectno
   genf(f)
   writef(" $%n,$%n,%c%n*n",r1,r2,lablet,lab)
$)

AND genl(f,l) BE IF incode DO
$( LET lablet = 'L' + sectno
   genf(f)
   writef(" %c%n*n",lablet,l)
$)

AND genf(f) BE
$( stvp := stvp+4
   SWITCHON f INTO

   $( DEFAULT : writef(" f not recognised %n*n",f) ; ENDCASE
  
      CASE mf_la   : writef(" la   ") ; ENDCASE
      CASE mf_lw   : writef(" lw   ") ; ENDCASE
      CASE mf_add  : writef(" add  ") ; ENDCASE
      CASE mf_sw   : writef(" sw   ") ; ENDCASE
      CASE mf_j    : writef(" j    ") ; ENDCASE
      CASE mf_li   : writef(" li   ") ; ENDCASE
      CASE mf_move : writef(" move ") ; ENDCASE
      CASE mf_jal  : writef(" jal  ") ; ENDCASE
      CASE mf_addi : writef(" addi ") ; ENDCASE
      CASE mf_sub  : writef(" sub  ") ; ENDCASE
      CASE mf_bgez : writef(" bgez ") ; ENDCASE
      CASE mf_nor  : writef(" nor  ") ; ENDCASE
      CASE mf_mult : writef(" mult ") ; ENDCASE
      CASE mf_mflo : writef(" mflo ") ; ENDCASE
      CASE mf_div  : writef(" div  ") ; ENDCASE
      CASE mf_rem  : writef(" rem  ") ; ENDCASE
      CASE mf_mfhi : writef(" mfhi ") ; ENDCASE
      CASE mf_sll  : writef(" sll  ") ; ENDCASE
      CASE mf_srl  : writef(" srl  ") ; ENDCASE
      CASE mf_or   : writef(" or   ") ; ENDCASE
      CASE mf_and  : writef(" and  ") ; ENDCASE
      CASE mf_beq  : writef(" beq  ") ; ENDCASE
      CASE mf_bne  : writef(" bne  ") ; ENDCASE
      CASE mf_bltz : writef(" bltz ") ; ENDCASE
      CASE mf_bgtz : writef(" bgtz ") ; ENDCASE
      CASE mf_blez : writef(" blez ") ; ENDCASE
      CASE mf_xor  : writef(" xor  ") ; ENDCASE
      CASE mf_lbu  : writef(" lbu  ") ; ENDCASE
      CASE mf_sb   : writef(" sb   ") ; ENDCASE
   $)
$)

AND genpseudo(p) BE
$( SWITCHON p INTO
   $( DEFAULT : writef("pseudo op not recognised")

      CASE p_text  : writef(" .text *n") ; ENDCASE
      CASE p_word  : writef(" .word")
		     stvp := stvp+4      ; ENDCASE
      CASE p_globl : writef(" .globl")   ; ENDCASE
      CASE p_ent   : writef(" .ent")     ; ENDCASE
      CASE p_end   : writef(" .end")     ; ENDCASE
      CASE p_sdata : writef(" .sdata*n") ; ENDCASE
      CASE p_data  : writef(" .data*n")  ; ENDCASE
   $)
$)

/////////////////// End of functions to generate code /////////

//////////////// Basic register functions /////////////////

AND inuse(r) = VALOF
$( FOR t = tempv TO arg1 BY 3 DO
	$( IF (t!0 = k_reg) & (t!1 = r) 
           THEN RESULTIS TRUE
	$)
   RESULTIS FALSE
$)


AND movetor(arg, r) = VALOF
$( LET k , n = h1!arg , h2!arg

   // If arg is already there then return
   IF (h1!arg = k_reg) & (h2!arg = r) RESULTIS h2!arg

   // If  r is being used store it away
   IF inuse(r) DO
   $( FOR t = tempv TO arg1 BY 3 DO
      $( IF k = k_reg & n = r DO genrnr(mf_sw,n,4*h3!t,r_p)
      $)
      forget(r)
   $)
  
   // If already in a reg just move it
   IF k = k_reg DO
   $( genrr(mf_move,r,n)
      movelist(n,r)
      RESULTIS r
   $)

   // Deal with othercases
   SWITCHON k INTO
     $(
	  CASE k_loc   :genrnr(mf_lw,r,4*n,r_p)
		        GOTO ret

	  CASE k_glob  :genrnr(mf_lw,r,4*n,r_g)
		        GOTO ret

	  CASE k_numb  :genrn(mf_li,r,n)
                        GOTO ret

	  CASE k_fnlab :genrl(mf_la,r,n)
		        GOTO ret

	  CASE k_lab   :genrl(mf_la,r,n)
			genrnr(mf_lw,r,0,r)
			GOTO ret

	  CASE k_lvloc :genrrn(mf_srl,r,r_p,2)
		        genrrn(mf_addi,r,r,n)
		        GOTO ret

	  CASE k_lvglob:genrrn(mf_srl,r,r_g,2)
		        genrrn(mf_addi,r,r,n)
		        GOTO ret

	  CASE k_lvlab :genrl(mf_la,r,n)
		        genrrn(mf_srl,r,r,2)
			GOTO ret

	  DEFAULT     :writef("  #case not declared in move to r%n*n",k)

      $)

ret: forget(r)
     remem(r,k,n)
     h1!arg, h2!arg := k_reg, r
     RESULTIS r
$)

AND movetoanyr(arg) = VALOF
$( LET k, n = h1!arg, h2!arg
   UNLESS k = k_reg DO
   $( LET rc = regcontaining(k,n)
      LET ru = reginuse()
      LET pr = rc & ~ru
      IF pr ~= 0 DO
         $( LET q = choosereg(pr)
            h1!arg, h2!arg := k_reg, q
            RESULTIS q
         $)  
      IF rc ~= 0 DO
      $( LET r = choosereg(~ru)
         LET s = choosereg(rc)
         genrr(mf_move,r,s)
         movelist(s,r)
         RESULTIS r
      $)
      n := movetor(arg,choosereg(~ru))
   $)
   RESULTIS n
$)


AND codewl(n) BE
$( LET lablet = 'L' + sectno
   genpseudo(p_sdata)
   genpseudo(p_word)
   writef(" %c%n*n",lablet,n)
   sdcount := sdcount + 1
   genpseudo(p_text)
$)

///////////// Functions to manipulate list of reg contents ///


AND getblk(a,b,c) = VALOF
$( LET p = freelist
   TEST p = 0
   THEN $( dp:=dp-3
           p:=dp
           checkspace()
        $)
   ELSE freelist := !p
   h1!p, h2!p, h3!p := a, b, c
   RESULTIS p
$)

AND freeblk(p) BE
$( !p := freelist
   freelist := p
$)

AND remem (a,b,c) BE
$( reglist!a := getblk(reglist!a,b,c)
$)

AND initreglist() BE
$( FOR r = 0 TO 31 DO reglist!r := 0
$)

AND forget(r) BE UNLESS reglist!r = 0 DO
$( LET a = @reglist!r
   UNTIL !a = 0 DO a := !a
   !a := freelist
   freelist := reglist!r
   reglist!r := 0
$)

AND forgetall() BE
$( FOR i = 0 TO 25 DO forget(i)
$)

AND movelist(s,d) BE UNLESS s = d DO
$( LET p = reglist!s
   forget(d)
   UNTIL p = 0 DO
   $( remem(d,h2!p,h3!p)
      p := !p
   $)
$)

AND forgetvar(k,n) BE
$( FOR r = 0 TO 25 DO
  $( LET a = @reglist!r
    $(  LET p = !a
	IF p = 0 BREAK
	TEST h3!p = n & h2!p = k
	THEN $( !a := !p
		freeblk(p)
	     $)
	ELSE a :=p
    $) REPEAT
  $)
$)

AND forgetallvars() BE
$( FOR r = 0 TO 25 DO
   $( LET a = @reglist!r
      $( LET p = !a
         IF p = 0 BREAK
         TEST h2!p > 8 
         THEN $( !a:=!p
                 freeblk(p)
              $)
         ELSE a:=p
      $) REPEAT
   $)
$)

AND regcontaining(k,n) = VALOF
$( LET v = 0
   FOR r = 0 TO 25 DO
   $( LET p = reglist!r
      UNTIL p = 0 DO
      $( IF h2!p = k & h3!p = n v:=v|1<<r  
         p:=!p
      $)
   $)
   RESULTIS v
$)

AND reginuse() = VALOF
$( LET v = 0

   FOR i = tempv TO arg1 BY 3 DO
   $( IF h1!i = k_reg v:=v|1<<(h2!i)
   $)
   v:=v | regnotavail

   // Are all the registers being used?
   IF v = allregsused DO
   $( freeareg()
      RESULTIS reginuse()
   $)

   RESULTIS v
$)

AND freeareg() BE
$( LET a = oldestreg()
   FOR i = tempv TO arg1 BY 3 DO
   $( IF h1!i = k_reg & h2!i = a DO storet(i)
   $)
$)

AND oldestreg() = VALOF
$( FOR i = tempv TO arg1 BY 3 DO
   $( IF h1!i = k_reg RESULTIS h2!i
   $)
$)

AND choosereg(a) = VALOF
$( IF a = 0 writef("  # error in choosereg*n")
   FOR r = 0 TO 25 DO
   $( UNLESS (a>>r & 1) = 0 RESULTIS r 
   $)
$)

// End of manipulations 


// Set Up           

AND cgsects(workvec, vecsize) BE UNTIL op=0 DO
$( LET p = workvec
   tempv := p
   p := p+90
   tempt := p - 3
   reglist := p
   p := p +32
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
   sdcount :=0
   incode := FALSE
   maxgn := 0
   maxlab := 0
   maxssp := 0
   procdepth := 1
   initstack(3)
   initdatalists()
   initreglist()

   $( endlab := nextlabel()
      codewl(endlab)  // Ptr to next module.
      IF op=s_section DO
      $( LET n = rdn()
	 FOR i = 1 TO n DO
          $( LET c = rdn()
	  $)
         op := rdn()
      $)

      scan()
      op := rdn()
      writef("%c%n:*n",('L' + sectno - 1),endlab)      
      progsize := progsize + stvp
   $)
$)


// Read an OCODE operator or argument.
AND rdn() = VALOF
$( LET a, sign = 0, '+'
   ch := rdch() REPEATWHILE ch='*s' | ch='*n'
   IF ch=endstreamch RESULTIS 0
   IF ch='-' DO $( sign := '-'; ch := rdch() $)
   WHILE '0'<=ch<='9' DO $( a := 10*a + ch - '0'; ch := rdch()  $)
   IF sign='-' RESULTIS -a
   RESULTIS a
$)

// Read in an OCODE label.
AND rdl() = VALOF
$( LET l = rdn()
   IF maxlab<l DO $( maxlab := l; checklab() $)
   RESULTIS l
$)

// Read in a global number.
AND rdgn() = VALOF
$( LET g = rdn()
   IF maxgn<g DO maxgn := g
   RESULTIS g
$)


// Generate next label number.
AND nextlabel() = VALOF
$( labnumber := labnumber-1
   checklab()
   RESULTIS labnumber
$)


AND checklab() BE IF maxlab>=labnumber DO
$( cgerror("Too many labels - increase workspace")
   errcount := errcount+1
   longjump(fin_p, fin_l)
$)


AND cgerror(mes, a) BE
$( LET oldout = output()
   selectoutput(sysprint)
   writes("*nError: ")
   writef(mes, a)
   newline()
   errcount := errcount+1
   IF errcount>errmax DO $( writes("Too many errors*n")
                            longjump(fin_p, fin_l)
                         $)
   selectoutput(oldout)
$)


////.
////SECTION "CINCG2"
////GET "CGHDR"

// Initialize the simulated stack (SS).
LET initstack(n) BE
$( arg2, arg1, ssp := tempv, tempv+3, n
   pendingop := s_none
   h1!arg2, h2!arg2, h3!arg2 := k_loc, ssp-2, ssp-2
   h1!arg1, h2!arg1, h3!arg1 := k_loc, ssp-1, ssp-1
   IF maxssp<ssp DO maxssp := ssp
$)


// Move simulated stack (SS) pointer to N.
AND stack(n) BE
$( IF maxssp<n DO maxssp := n
   IF n>=ssp+4 DO $( store(0,ssp-1)
                     initstack(n)
                     RETURN
                  $)

   WHILE n>ssp DO loadt(k_loc, ssp)

   UNTIL n=ssp DO
   $( IF arg2=tempv DO
      $( TEST n=ssp-1
         THEN $( ssp := n
                 h1!arg1, h2!arg1, h3!arg1 := h1!arg2, h2!arg2, ssp-1
                 h1!arg2, h2!arg2, h3!arg2 := k_loc, ssp-2, ssp-2
              $)
         ELSE initstack(n)
//writef(" ssp %n*n",ssp)
         RETURN
      $)

      arg1, arg2, ssp := arg1-3, arg2-3, ssp-1

   $)
$)



// Store all SS items from S1 to S2 in their true
// locations on the stack.
// It may corrupt both registers A and B.
AND store(s1, s2) BE FOR p = tempv TO arg1 BY 3 DO
                     $( LET s = h3!p
                        IF s>s2 RETURN
                        IF s>=s1 DO storet(p)
                     $)


AND scan() BE
$( //IF debug>1 DO $( writef("OP=%i3 PND=%i3 ", op, pendingop)
//                    dboutput()
//                 $)
LET r = 0

   SWITCHON op INTO

   $( DEFAULT:     cgerror("Bad OCODE op %n", op)
                   ENDCASE

      CASE 0:      RETURN
      
      CASE s_needs:
                $( LET n = rdn()  // Ignore NEEDS directives.
                   FOR i = 1 TO n DO rdn()
                   ENDCASE
                $)

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

      CASE s_sp:   storein(k_loc,  rdn()) ; ENDCASE
      CASE s_sg:   storein(k_glob, rdgn()); ENDCASE
      CASE s_sl:   storein(k_lab,  rdl());  ENDCASE

      CASE s_stind:cgstind(); ENDCASE

      CASE s_rv:   cgrv(); ENDCASE

      CASE s_mult:CASE s_div:CASE s_rem:
      CASE s_plus:CASE s_minus:
      CASE s_eq: CASE s_ne:
      CASE s_ls:CASE s_gr:CASE s_le:CASE s_ge:
      CASE s_lshift:CASE s_rshift:
      CASE s_logand:CASE s_logor:CASE s_eqv:CASE s_neqv:
      CASE s_not:CASE s_neg:CASE s_abs:
                   cgpendingop()
                   pendingop := op
                   ENDCASE

      CASE s_jt:   cgjump(TRUE, rdl());  ENDCASE

      CASE s_jf:   cgjump(FALSE, rdl()); ENDCASE

      CASE s_goto: cgpendingop()
                   store(0, ssp-2)
                   r:=movetoanyr(arg1)
		   genr(mf_j,r)
                   stack(ssp-1)
                   incode := FALSE
                   ENDCASE

      CASE s_lab:  cgpendingop()
                   store(0, ssp-1)
                   setlab(rdl())
                   forgetall() 
                   incode := TRUE //procdepth>0
                   ENDCASE

      CASE s_query:loadt(k_loc, ssp);              ENDCASE

      CASE s_stack:cgpendingop(); stack(rdn());    ENDCASE

      CASE s_store:cgpendingop(); store(0, ssp-1); ENDCASE

      CASE s_entry:
                $( LET l = rdl()
                   LET n = rdn()
                   cgentry(l, n)
                   procdepth := procdepth + 1
                   ENDCASE
                $)

      CASE s_save:
                $( LET n = rdn()
                   cgsave(n)
                   ENDCASE
                $)

      CASE s_fnap:
      CASE s_rtap: cgapply(op, rdn()); ENDCASE

      CASE s_rtrn: cgpendingop()
		   cgreturn(op)
                   incode := FALSE
                   ENDCASE
                   
      CASE s_fnrn: cgpendingop()
                   cgreturn(op)
                   incode := FALSE
                   ENDCASE

      CASE s_endproc:
		   genpseudo(p_end)
		   writef(" %s*n",fnlabel)
		   freevec(fnlabel)
                   genpseudo(p_sdata)   // data
                   cgstatics()
		   genpseudo(p_text)
                   procdepth := procdepth - 1
                   ENDCASE

      CASE s_res :
      CASE s_jump:
                  $( LET l=rdl()
		     cgpendingop()
		     store(0,ssp-2)
		     TEST op=s_jump
                       THEN storet(arg1)
		       ELSE $( movetor(arg1,4)
			       forget(4)
			       stack(ssp-1)
			    $)
		     $( op := rdn()
			UNLESS op=s_stack BREAK
			stack(rdn())
  		     $) REPEAT

		     TEST op=s_lab
		     THEN $( LET m=rdl()
			     UNLESS l=m DO genl(mf_j,l)
			     setlab(m)
			     forgetall()
		 	     incode:= TRUE //procdepth>0
			     op:=rdn()
			  $)
		     ELSE $( genl(mf_j,l)
			     incode:=FALSE
			  $)
		     LOOP
		  $)

      CASE s_rstack: initstack(rdn()); loadt(k_reg, 4); ENDCASE

      CASE s_finish:  // Compile code for:  stop(0).
         $( LET k = ssp
            stack(ssp+3)
            loadt(k_numb, 0)
            loadt(k_glob, gn_stop)
            cgapply(s_rtap, k)
            ENDCASE
         $)

      CASE s_switchon:$( LET n = 2*rdn() + 1
			 switchspace := getvec(n)
			 IF switchspace = 0 DO
			 $( cgerror(" can't get space for switchon*n")
			   
			 $)
			 cgswitch(switchspace,n)
			 freevec(switchspace)
			 switchspace:=0 
		         ENDCASE
		      $)	 

      CASE s_getbyte:  cgpendingop()
		       cggetbyte()
                       ENDCASE


      CASE s_putbyte:  cgpendingop()
		       cgputbyte()
                       ENDCASE
                    
      CASE s_global:   cgglobal(rdn()); RETURN

      CASE s_datalab:
                $( LET lab = rdl()
                   op := rdn()

                   WHILE op=s_itemn DO
                   $( !nliste := getblk(0,lab,rdn())
                      nliste, lab, op := !nliste, 0, rdn()
                   $)
                   LOOP		  
                $)
   $)

   op := rdn()
$) REPEAT


////.
////SECTION "CINCG3"
////GET "CGHDR"

// Compiles code to deal with any pending op.
LET cgpendingop() BE
$( LET f = 0
   LET l, r, s = 0, 0, 0
   LET pndop = pendingop
   pendingop := s_none

   SWITCHON pndop INTO
   $( 
      DEFAULT:      cgerror("Bad pendingop %n", pndop)

      CASE s_none:  RETURN
      CASE s_plus:  cgplus(); RETURN

      CASE s_abs: l:= nextlabel
		  r:=movetoanyr(arg1)
                  genrl(mf_bgez,r,l)
		  genrrr(mf_sub,r,0,r)
		  setlab(l)
		  incode := TRUE
		  forget(r)
		  h1!arg1, h2!arg1:=k_reg, r
                  RETURN
   
      CASE s_neg: r:=movetoanyr(arg1)
		  genrrr(mf_sub,r,0,r)
		  forget(r)
   		  h1!arg1, h2!arg1:=k_reg, r
		  RETURN		

      CASE s_not: r:=movetoanyr(arg1)
		  genrrr(mf_nor,r,r,r)
		  forget(r)
   		  h1!arg1, h2!arg1:=k_reg, r
		  RETURN
   
      CASE s_eq:
      CASE s_ne:
      CASE s_ls:
      CASE s_gr:
      CASE s_le:
      CASE s_ge:  cgrelation(pndop)
                  RETURN
      CASE s_eqv   :
      CASE s_neqv  :                   
      CASE s_minus :
      CASE s_mult  :
      CASE s_div   :
      CASE s_rem   :
      CASE s_lshift:
      CASE s_rshift:
      CASE s_logand:
      CASE s_logor : cgarith(pndop)
                     RETURN 
 		   
   $)


$)

AND cgarith(f) BE
$( LET r = movetoanyr(arg1)
   LET s = movetoanyr(arg2)
   LET t = choosereg(~reginuse())
   forget(t)
   SWITCHON f INTO
   $( CASE s_minus  :  genrrr(mf_sub,t,s,r) ; ENDCASE
      CASE s_mult   :  genrr(mf_mult,s,r)
		       genr(mf_mflo,t)      ; ENDCASE
      CASE s_div    :  genrr(mf_div,s,r)
	  	       genr(mf_mflo,t)      ; ENDCASE
      CASE s_rem    :  genrr(mf_rem,s,r)
	  	       genr(mf_mfhi,t)      ; ENDCASE
      CASE s_lshift :  genrrr(mf_sll,t,s,r) ; ENDCASE
      CASE s_rshift :  genrrr(mf_srl,t,s,r) ; ENDCASE
      CASE s_logand :  genrrr(mf_and,t,s,r) ; ENDCASE
      CASE s_logor  :  genrrr(mf_or,t,s,r)  ; ENDCASE
      CASE s_neqv   :  genrrr(mf_xor,t,s,r) ; ENDCASE
      CASE s_eqv    :  genrrr(mf_xor,t,s,r)
                       genrrr(mf_nor,t,t,t) ; ENDCASE
    $)
    lose1(k_reg,t)
$)

AND cgrelation(op) BE
$( LET f = jmpfn(op)
   LET r = movetoanyr(arg2)
   LET s = movetoanyr(arg1)
   LET l = nextlabel()
   LET m = nextlabel()
   TEST f = mf_beq | f = mf_bne
     THEN genrrl(f,r,s,l)
     ELSE $( genrrr(mf_sub,r,r,s)
             genrl(f,r,l)
          $)
   forget(r)
   genrn(mf_li,r,FALSE)
   genl(mf_j,m)
   setlab(l)
   incode := TRUE
   genrn(mf_li,r,TRUE)
   setlab(m)
   lose1(k_reg,r)
$)



AND cgplus() BE
$( LET r,s,t = 0,0,0
//writef(" ssp = %n*n",ssp)
   // see if one of args is a number
    IF h1!arg2 = k_numb DO swapargs()
    TEST h1!arg1 = k_numb & h2!arg1 > -32768 & h2!arg1 < 32767
     THEN TEST h2!arg1=0 
           THEN  $( lose1(h1!arg2,h2!arg2)
	        pendingop:=s_none
	        RETURN
             $)
	   ELSE $( r:=movetoanyr(arg2)
	           s:=choosereg(~reginuse())
		   forget(s)
		   genrrn(mf_addi,s,r,h2!arg1)
		   lose1(k_reg,s)
		   pendingop:=s_none
//writef(" ssp = %n*n",ssp)
		   RETURN
	        $)
   // neither a number so move args to regs
    ELSE $( r:=movetoanyr(arg1)
            s:=movetoanyr(arg2)
            t:=choosereg(~reginuse())
            genrrr(mf_add,t,r,s)
            forget(t)
            lose1(k_reg,t)
            pendingop:=s_none
         $)
$)

////.
////SECTION "CINCG4"
////GET "CGHDR"

AND iszero(a) = h1!a=k_numb & h2!a=0 -> TRUE, FALSE



// Store the value of a SS item in its true stack location.
AND storet(x) BE
$( LET s = h3!x
   UNLESS (h1!x=k_loc) & (h2!x=s) DO
   $( LET r = movetoanyr(x)
      genrnr(mf_sw,r,4*h3!x,r_p)
      h1!x, h2!x := k_loc, h3!x
      remem(r,k_loc,h2!x)  // this was commented out
   $)
   RETURN
$)



// Load an item (K,N) onto the SS. It may move SS items.
AND loadt(k, n) BE
$( cgpendingop()
   TEST arg1+3=tempt
   THEN $( storet(tempv)  // SS stack overflow.
           FOR t = tempv TO arg2+2 DO t!0 := t!3
        $)
   ELSE arg2, arg1 := arg2+3, arg1+3
   h1!arg1,h2!arg1,h3!arg1 := k,n,ssp
   ssp := ssp + 1
   IF maxssp<ssp DO maxssp := ssp
$)


// Replace the top two SS items by (K,N) and set PENDINGOP=S_NONE.
AND lose1(k, n) BE
$( ssp := ssp - 1
   TEST arg2=tempv
   THEN $( h1!arg2,h2!arg2 := k_loc,ssp-2
           h3!arg2 := ssp-2
        $)
   ELSE $( arg1 := arg2
           arg2 := arg2-3
        $)
   h1!arg1, h2!arg1, h3!arg1 := k,n,ssp-1
   pendingop := s_none
$)

AND swapargs() BE
$( LET k, n = h1!arg1, h2!arg1
   h1!arg1, h2!arg1 := h1!arg2, h2!arg2
   h1!arg2, h2!arg2 := k, n
$)

AND cgstind() BE
$( LET t,u = 0,0
   IF pendingop = s_plus DO
   $(
      // see if one of the args is a number
      // and if so put it in arg1
      IF h1!arg2 = k_numb DO swapargs()
      IF h1!arg1 = k_numb DO
      $( // see if number small enough for indirectio
         LET n = h2!arg1
	 IF n > -16384 & n < 16384 DO
	 $( t:=movetoanyr(arg2)
	    genrrn(mf_sll,t,t,2)
	    forget(t)
	    lose1(k_reg,t)
	    u:=movetoanyr(arg2)
	    genrnr(mf_sw,u,4*n,t)
	    stack(ssp-2)
	    forgetallvars()
	    RETURN
         $)
      $)
   $)

   // use brute force
   cgpendingop()
   u:=movetoanyr(arg1)
   TEST arg2 >= tempv
     THEN t:=movetoanyr(arg2)
     ELSE $( t:=choosereg(~reginuse())
             genrnr(mf_lw,t,4*(ssp-2),r_p)
          $)
   genrrn(mf_sll,u,u,2)
   forget(u)
   genrnr(mf_sw,t,0,u)
   stack(ssp-2)
   forgetallvars()
   RETURN
$)


// Store the top item of the SS in (K,N).
AND storein(k, n) BE
// K is K_LOC, K_GLOB or K_LAB.
$( LET r,s = 0,0
   cgpendingop()
   // pendingop set to s_none
   r:= movetoanyr(arg1)
   SWITCHON k INTO
   $( DEFAULT       : cgerror("in storein %n",k)
      CASE k_loc    : genrnr(mf_sw,r,4*n,r_p) ; ENDCASE
      CASE k_glob   : genrnr(mf_sw,r,4*n,r_g) ; ENDCASE
      CASE k_lab    : s:=choosereg(~reginuse())
		      genrl(mf_la,s,n)
		      genrnr(mf_sw,r,0,s)     ; ENDCASE
   $)
   forgetvar(k,n)
   remem(r,k,n)
   stack(ssp-1)
$)

////.
////SECTION "CINCG5"
////GET "CGHDR"

AND cgrv() BE
$( LET r,s =0,0
   IF pendingop = s_plus DO
   $( // see if one of args is a number
      IF h1!arg2 = k_numb DO swapargs()
      IF h1!arg1 = k_numb DO
      $( LET k = h2!arg1
         IF k >-16384 & k < 16384 DO
         $( s:=movetoanyr(arg2)
	    r:=choosereg(~reginuse())
	    forget(r)
	    forget(s)
	    genrrn(mf_sll,s,s,2)
	    genrnr(mf_lw,r,4*k,s)
	    lose1(k_reg,r)
	    pendingop:=s_none
	    RETURN
	 $)
      $)
   $)
   cgpendingop()
   r:=movetoanyr(arg1)
   s:=choosereg(~reginuse())
   forget(s)
   genrrn(mf_sll,s,r,2)
   genrnr(mf_lw,s,0,s)
   forget(r)
   h1!arg1, h2!arg1:= k_reg, s
$)


AND cgglobal(n) BE
$( LET lablet = 'L' + sectno
   genpseudo(p_sdata)
   genpseudo(p_word)
   writef(" %c%n*n",lablet,endlab)
   genpseudo(p_word)
   writef(" 0*n")
   genpseudo(p_word)  
   writef(" 0*n")
   sdcount := sdcount + 3 + 2*n + 1

// Must have a multiple of 4 words in sdata

   UNTIL (sdcount REM 4) = 0 DO
   $( genpseudo(p_word)
      writef(" 0*n")
      sdcount := sdcount + 1
   $)

   FOR i = 1 TO n DO
   $( genpseudo(p_word)
      writef(" %n*n",rdgn())
      genpseudo(p_word)
      writef(" %c%n*n",lablet,rdl())
   $)
   genpseudo(p_word)
   writef(" %n*n",maxgn)

// Increment section number

   sectno := sectno + 1
$)


AND cgentry(l, n) BE
$( LET w = n << 24
   fnlabel:=getvec(n+1)
   fnlabel%0:=n
   FOR i = 1 TO n DO fnlabel%i:=rdn()
  
// Now generate entryword and packed name

   genpseudo(p_word)
   writef(" 0x%x8*n",entryword)
   FOR i = 1 TO n DO
   $( w:=w >> 8
      w:=fnlabel%i << 24 | w
      IF i REM 4 = 3 & i <= 8 DO
      $( genpseudo(p_word)
	 writef(" 0x%x8*n",w)
      $)
   $)
   FOR i = n + 1 TO 7 DO
   $( w:=w >> 8
      w:=32 << 24 | w     // ASCII space
      IF i REM 4 = 3 DO
      $( genpseudo(p_word)
	 writef(" 0x%x8*n",w)
      $)
   $)

// Now generate info for the debugger

   genpseudo(p_ent)
   writef(" %s*n",fnlabel)
   writef("%s:*n",fnlabel)

   setlab(l)
   incode := TRUE
   forgetall()    
$)



// Function or routine call.
AND cgapply(op, k) BE
$( LET sa1 = k+3
   LET sa4 = k+6
   LET t = 0
 
   cgpendingop()
 
   t:=movetor(arg1,r_j)  // move jump address to jump reg.   

   // store args 5,6,...
   store(sa4+1, ssp-2)
 
   // now deal with non-args
   FOR t = tempv TO arg2 BY 3 DO
   $( IF h3!t>=k BREAK
      storet(t)
   $)
 
   // move args 1-4 to arg registers
   // and store them away
   FOR t = arg2 TO tempv BY -3 DO
   $( LET s = h3!t
      LET r = s-k+1
      IF s < sa1 BREAK
      IF s <= sa4 DO movetor(t,r)
   $) 

   // deal with args not in SS
   FOR s = sa1 TO sa4 DO
   $( LET r = s-k+1
      IF s >= h3! tempv BREAK
      IF h1!arg1=k_reg & h2!arg1 = r DO
      $( forget(21)
         genrr(mf_move,21,r)
         h2!arg1 := 21
      $)
      genrnr(mf_lw,r,4*s,r_p)
    $)
 

   genrrn(mf_addi,r_np,r_p,4*k)

   genrnr(mf_sw,t,8,r_p)   // pointer to function in p2
   genr(mf_jal,t)

   forgetall()     // forgetallvars ?
   stack(k)
   IF op=s_fnap DO loadt(k_reg,4)

$)





AND cgreturn(op) BE
$( cgpendingop()
   IF op = s_fnrn DO
   $( movetor(arg1,4)
      stack(ssp-1)
   $)
   genrnr(mf_lw,31,4,r_p)
   genrnr(mf_lw,r_p,0,r_p)
   genr(mf_j,31)
   initstack(ssp)
$)

AND cgsave(m) BE
$( initstack(m)
   genrnr(mf_sw,r_p,0,r_np)
   genrnr(mf_sw,31,4,r_np)
   genrr(mf_move,r_p,r_np)
   FOR r = 4 TO 7 DO
      $( IF r > m BREAK
         remem(r,k_loc,r-1)
         genrnr(mf_sw,r,4*(r-1),r_p)
      $)

$)

// Used for OCODE operators JT and JF.
AND cgjump(b,l) BE
$( LET f = jmpfn(pendingop)
   LET r,s = 0,0
   IF f = 0 DO $( loadt(k_numb,0)
		  f := mf_bne
               $)
   pendingop:=s_none
   UNLESS b DO f:=compjfn(f)
   store(0,ssp-3)
   r:=movetoanyr(arg1)
   s:=movetoanyr(arg2)

   TEST f = mf_beq | f = mf_bne
     THEN genrrl(f,r,s,l)
     ELSE $( genrrr(mf_sub,s,s,r)
             genrl(f,s,l)
             forget(s)
	  $)
   stack(ssp-2)
//   writef(" ssp is %n*n",ssp)    // remove this
$)

AND jmpfn(op) = VALOF SWITCHON op INTO
$( DEFAULT   : RESULTIS 0
   CASE s_eq : RESULTIS mf_beq
   CASE s_ne : RESULTIS mf_bne
   CASE s_ls : RESULTIS mf_bltz
   CASE s_gr : RESULTIS mf_bgtz
   CASE s_le : RESULTIS mf_blez
   CASE s_ge : RESULTIS mf_bgez
$)

AND compjfn(f) = f = mf_blez -> mf_bgtz,
	        f = mf_beq -> mf_bne,
	        f = mf_bltz -> mf_bgez,
	        f = mf_bgez -> mf_bltz,
	        f = mf_bgtz -> mf_blez,
	        f = mf_bne -> mf_beq,
                f

////.
////SECTION "CINCG6"
////GET "CGHDR"

AND cggetbyte() BE
$( LET s,t = 0,0
   LET k,n = h1!arg1, h2!arg1
   LET r = movetoanyr(arg2)
   genrrn(mf_sll,r,r,2)
   forget(r)
   TEST k = k_numb & n < 16384 & n > -16384
     THEN $( s:=choosereg(~reginuse())
             forget(s)
	     genrnr(mf_lbu,s,n,r)
	     lose1(k_reg,s)
	     RETURN
          $)
     ELSE $( s:=movetoanyr(arg1)
	     t:=choosereg(~reginuse())
	     forget(t)
	     genrrr(mf_add,t,r,s)
	     genrnr(mf_lbu,t,0,t) 
	     lose1(k_reg,t)
          $)
$)

AND cgputbyte() BE
$( LET s,t,u = 0,0,0
   LET k,n = h1!arg1, h2!arg1
   LET r = movetoanyr(arg2)
   genrrn(mf_sll,r,r,2)
   forget(r)
   TEST k = k_numb & n < 16384 & n > -16384
     THEN $( lose1(k_reg,r)
	     t:=movetoanyr(arg2)
	     genrnr(mf_sb,t,n,r)
	     stack(ssp-2)
	     RETURN
	  $)
     ELSE $( s:=movetoanyr(arg1)
	     t:=choosereg(~reginuse())
	     forget(t)
	     genrrr(mf_add,t,r,s)
	     lose1(k_reg,t)
	     u:=movetoanyr(arg2)
	     genrnr(mf_sb,u,0,t)
	     stack(ssp-2)
	  $)
$)


// Compiles code for SWITCHON.
LET cgswitch(v,m) BE
$( LET n = m/2
   LET er = 0 // expression register
   LET d = rdl()
   casek, casel := v-1, v+n-1
   // read and sort k,l pairs
   FOR i = 1 TO n DO 
   $( LET a = rdn()
      LET l = rdl()
      LET j = i-1
      UNTIL j = 0 DO
      $( IF a > casek!j BREAK
	 casek!(j+1):= casek!j
	 casel!(j+1):= casel!j
	 j:=j-1
      $)
      casek!(j+1), casel!(j+1) := a, l
   $)
   cgpendingop()
   store(0,ssp-2)
   er:=movetoanyr(arg1)

   // see which switch to implement
   TEST 2*n-6 > casek!n/2 - casek!1/2
     THEN lswitch(1,n,d,er)
     ELSE $( bswitch(1,n,d,er)
	     genl(mf_j,d)
	  $)
   stack(ssp-1)

$)

AND lswitch(p,q,d,e) BE
$( LET s,t = 0,0
   LET m = nextlabel()
   LET lablet = 'L' + sectno
   loadt(k_numb,casek!p)
   s:=movetoanyr(arg1)
   t:=choosereg(~reginuse())
   forget(t)
   stack(ssp-1)
   genrrr(mf_sub,t,e,s)
   genrl(mf_bltz,t,d)        // jump to default if less than case min.
   loadt(k_numb,casek!q)
   t:=movetor(arg1,t)
   stack(ssp-1)
   genrrr(mf_sub,t,t,e)
   genrl(mf_bltz,t,d)        // jump to default if bigger than case max.

   // now pick up case using indirection

   genrl(mf_la,t,m)
   genrrr(mf_sub,e,e,s)
   genrrn(mf_sll,e,e,2)
   genrrr(mf_add,t,t,e)
   genrnr(mf_lw,s,0,t)
   genr(mf_j,s)
   forget(s)
   forget(t)
   forget(e)

   // now generate table

   genpseudo(p_sdata)
   setlab(m)
   FOR k = casek!p TO casek!q TEST casek!p = k
     THEN $( genpseudo(p_word)
             writef(" %c%n*n",lablet,casel!p)
	     sdcount := sdcount + 1
	     m:=0
             p:=p+1
          $)
     ELSE $( genpseudo(p_word)
             writef(" %c%n*n",lablet,d)
	     sdcount := sdcount + 1
	     m:=0
          $)

   genpseudo(p_text)
$)

AND bswitch(p,q,d,e) BE TEST q-p > 6
  THEN $( LET t = (p+q)/2
          LET r = 0
          LET m = nextlabel()
          loadt(k_numb,casek!t)
	  r:= movetoanyr(arg1)
	  stack(ssp-1)
	  genrrr(mf_sub,r,r,e)
	  genrl(mf_blez,r,m)
	  bswitch(p,t-1,d,e)
	  genl(mf_j,d)
	  setlab(m)
	  incode := TRUE
	  forgetall()
	  incode:=TRUE
          genrrl(mf_beq,0,r,casel!t)
 	  bswitch(t+1,q,d,e)
       $)
  ELSE FOR i = p TO q DO
       $( LET r = 0
          loadt(k_numb,casek!i)
	  r:=movetoanyr(arg1)
	  stack(ssp-1)
          genrrl(mf_beq,r,e,casel!i)
       $)



AND cgstring(n) BE
$( LET l,a = nextlabel(), n
   loadt(k_lvlab,l)
   $( LET b,c,d = 0,0,0
      IF n > 0 DO b:=rdn()
      IF n > 1 DO c:=rdn()
      IF n > 2 DO d:=rdn()
      !nliste:=getblk(0,l,pack4b(a,b,c,d))
      nliste:=!nliste
      l:=0
      IF n <= 3 BREAK
      n,a := n-4,rdn()
   $) REPEAT
$)

AND pack4b(a,b,c,d) = VALOF
$( LET w = d
   w:=w<<8 | c
   w:=w<<8 | b
   w:=w<<8 | a
   RESULTIS w
$)




AND setlab(l) BE
$( LET m = 'L' + sectno
   writef("%c%n:*n",m,l)
$)


AND cgstatics() BE UNTIL nlist=0 DO
$( LET nl = nlist
   nliste := @nlist
   nl := !nl REPEATUNTIL nl=0 | h2!nl ~=0

   setlab(h2!nlist)

   $( LET blk = nlist
      nlist := !nlist
      freeblk(blk)
      genpseudo(p_word) 
      writef(" 0x%x8*n",h3!blk)
      sdcount := sdcount + 1
   $) REPEATUNTIL nlist =0 | h2!nlist ~=0
$)



AND initdatalists() BE
$( nlist := 0
   nliste:= @nlist
   freelist:=0
$)



////.
////SECTION "CINCG7"
////GET "CGHDR"

AND checkspace() BE IF stvp/4>dp-stv DO
$( cgerror("Program too large, %n bytes compiled", stvp)
   errcount := errcount+1
   longjump(fin_p, fin_l)
$)

////.
////SECTION "CINCG8"
////GET "CGHDR"

AND dboutput() BE
$(   
   IF debug=2 DO $( writes("  STK: ")
                    FOR p=tempv TO arg1 BY 3  DO
                    $( IF (p-tempv) REM 30 = 10 DO newline()
                       wrkn(h1!p,h2!p)
                       wrch('*s')
                    $)
                 $)

   IF debug=3 DO $( writes("*nREGISTER LIST: ")
		    FOR r = 0 TO 25 DO
		    $( LET p = reglist!r
		       IF p = 0 LOOP
		       writef("  $%n = ",r)
		       UNTIL p = 0 DO
		       $( wrkn(h2!p,h3!p)
			  p:=!p
		       $)
		    $)
		 $)
   
   newline()
$)


AND wrkn(k,n) BE
$( LET s = VALOF SWITCHON k INTO
   $( DEFAULT:       k := n
                     RESULTIS "?"
      CASE k_none:   RESULTIS "-"
      CASE k_numb:   RESULTIS "N"
      CASE k_fnlab:  RESULTIS "F"
      CASE k_lvloc:  RESULTIS "@P"
      CASE k_lvglob: RESULTIS "@G"
      CASE k_lvlab:  RESULTIS "@L"
      CASE k_reg:    RESULTIS "R"
      CASE k_loc:    RESULTIS "P"
      CASE k_glob:   RESULTIS "G"
      CASE k_lab:    RESULTIS "L"
   $)
   writes(s)
   UNLESS k=k_none DO writen(n)
$)



 
 

