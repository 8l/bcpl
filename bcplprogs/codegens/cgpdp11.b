// (C) Copyright 1978 Tripos Research Group
//     University of Cambridge
//     Computer Laboratory

GET ":COM.BCPL.BCPL"

MANIFEST
$(
// selectors
h1=0; h2=1; h3=2; h4=3; h5=4; h6=5

// AE tree and OCODE operators
s.true=4; s.false=5
s.rv=8; s.fnap=10
s.mult=11; s.div=12; s.rem=13; s.plus=14
s.minus=15; s.query=16; s.neg=17; s.abs=19
s.eq=20; s.ne=21; s.ls=22; s.gr=23; s.le=24; s.ge=25
s.not=30; s.lshift=31; s.rshift=32; s.logand=33
s.logor=34; s.eqv=35; s.neqv=36
s.needs=48; s.section=49
s.rtap=51; s.goto=52
s.return=67; s.finish=68
s.switchon=70; s.global=76

// OCODE operators
s.lp=40; s.lg=41; s.ln=42; s.lstr=43; s.ll=44
s.llp=45; s.llg=46; s.lll=47
s.local=77; s.label=78
s.sp=80; s.sg=81; s.sl=82; s.stind=83
s.jump=85; s.jt=86; s.jf=87; s.endfor=88
s.lab=90; s.stack=91; s.store=92; s.rstack=93
s.entry=94; s.save=95; s.fnrn=96; s.rtrn=97
s.res=98; s.datalab=100; s.iteml=101; s.itemn=102
s.endproc=103; s.getbyte=120; s.putbyte=121

s.debug=109; s.none=111
$)

MANIFEST
$(
//relocatable object blocks
t.hunk=1000
t.reloc=1001
t.end=1002
$)

MANIFEST $( secword=12345 $)

MANIFEST
$(
// registers
r0=0; r1=1; r2=2; r3=3; r.g=4; r.p=5; r.sp=6; r.pc=7

// items in simulated stack, in registers, or
// arguments to GEN routines
k.none=1
k.numb=2
k.loc=3; k.glob=4; k.lab=5
k.mloc=6; k.mglob=7; k.mlab=8
k.lvloc=9; k.lvglob=10; k.lvlab=11
k.reg=12
k.x0=13; k.x1=14; k.x2=15; k.x3=16
k.a=17

// global routine numbers
gn.stop=2
gn.checkstk=3
gn.mult=4
gn.div =5
gn.rem =6
gn.lshift=7
gn.rshift=8

// PDP addressing modes
m.v=#100; m.l=#200 // operand and label flags

m.10=#10           // indirect bit

m.20=#20; m.v27=#127; m.l27=#227; m.2p=#25; m.2s=#26

m.v37=#137

m.4p=#45

m.v60=#160; m.v6g=#164; m.v6p=#165; m.v67=#167; m.l67=#267
m.v70=#170; m.v7s=#176; m.l77=#277
$)

MANIFEST
$(
// single operand instructions
// compiled by GEND(F,K,N)
f.clr = #05000
f.clrb=#105000
f.dec = #05300
f.inc = #05200
f.neg = #05400
f.adc = #05500
f.tst = #05700
f.com = #05100
f.asr = #06200
f.asl = #06300
f.sxt = #06700
f.ror = #06000
f.swab= #00300

// register source instructions
// compiled by GENRS(F,K,N)
f.ash = #72000
f.ashc= #73000
f.mul = #70000
f.div = #71000

// register destination instructions
// compiled by GENRD(F,K,N)
f.xor = #74000

// jump instructions
// compiled by GENJ(F,R,K,N)
f.jmp = #00100
f.jsr = #04000

// double operand instructions
// compiled by GENSD(F,K1,N1,K2,N2)
f.mov = #10000
f.movb=#110000
f.add = #60000
f.sub =#160000
f.cmp = #20000
f.bis = #50000
f.bisb=#150000
f.bit = #30000
f.bic = #40000

// branch and condition code instructions
// compiled by GENBRANCH(F,L), GEN(F)
f.br  = #00400   // this bit reverses a cond branch
f.beq = #01400
f.bne = #01000
f.blt = #02400
f.bge = #02000
f.ble = #03400
f.bgt = #03000

f.clc = #00241
$)

GLOBAL
$(
rdn:181
rdl:182
rdgn:183
nextparam:184
checkparam:185
cgerror:186

initstack:187
stack:188
store:189
scan:190

cgpendingop:191
cgglobcall:192
numberis:193

getvalue:194
movetoanyrsh:195
movetoanyr:196
movetor:197
lookinregs:198
lookinfreeregs:199
nextr:200
regusedby:201
isfree:202
freereg:203
storet:204
loadt:205
lose1:206
cgbyteap:207
cgstind:208
storein:209

cgrv:210
cgshiftk:211
cgaddk:212
cgplus:213
cgminus:214
cglogand:215
cgglobal:216
cgentry:217
cgsave:218
cgapply:219
cgreturn:220
cgjump:221
cgcmp:222

cgswitch:223
checkbrefs:224
genbrefjumps:225
brlabref:226
condbrfn:227
genbranch:228
genmov:229
gensd:230
genrs:231
genrd:232
gend:233
gen:234
genj:235

formsaddr:236
formdaddr:237
formaddr:238
remem:239
setinfo:240
forget:241
forgetvars:242
forgetall:243
code:244
coderand:245
coded:246
coders:247
codesd:248
insertcount:249
setlab:250
cglab:251
cgname:252
cgstring:253
labref:254
cgdata:255
cgstatics:256
initdatalists:257
checkspace:258

outputsection:259
objword:260
dosword:261
endrecord:262
dboutput:263
wrkn:264

arg1:270
arg2:271
pendingop:272
op:273
tempv:274
tempt:275
ssp:276
dlist:277
dliste:278
reflist:279
refliste:280
needslist:282
needsliste:282
stvp:283
stv:284
dp:285
progsize:286
reg.k:287
reg.n:288
moved:289
addr.m:290
addr.v:291
casek:292
casel:293
paramnumber:294
brefv:295
brefp:296
labv:297
incode:298
maxgn:299
maxlab:300
maxssp:301
procstk:302
procstkp:303
countflag:304
debugging:305
binv:306
binp:307
$)

.

SECTION "CG1"

GET ""

LET start() BE
 $( LET v = 0
    err.p, err.l := level(), fail
    writes("PDP11 CG*N")
    ocodestream := findinput(ocodefile)
    IF ocodestream=0 DO
       cgerror("Can't open %S", TRUE, ocodefile)
    selectinput(ocodestream)
    v := getvec(cgworksize)
    IF v=0 DO
       cgerror("Can't get workspace", TRUE)
    IF cgworksize<500 DO
       cgerror("Insufficient workspace", TRUE)
    progsize := 0
 l: op := rdn()
    IF op=0 GOTO x
    tempv, tempt := v, v+150
    brefv, brefp := tempt, tempt
    procstk, procstkp := brefv+128, 0
    reg.k := procstk+20
    reg.n := reg.k+4
    labv := reg.n+4
    dp := v+cgworksize
    paramnumber := (dp-labv)/10+10
    stv := labv+paramnumber
    FOR p = labv TO stv-1 DO !p := -1
    stvp := 0
    initdatalists()
    incode := FALSE
    countflag := FALSE
    maxgn := 0
    maxlab := 0
    maxssp := 0
    initstack(2)
    code(0, 0)
    TEST op=s.section
    $( cgname(s.section, rdn())
       op := rdn() $)
    ELSE
       cgname(s.section, 0)
    scan()
    stv!0 := stvp
    UNLESS maxgn=0 DO outputsection()
    progsize := progsize+stvp
    GOTO l

 x: writef("Program size %N*N", progsize)
fail:
    UNLESS v=0 DO freevec(v)
    UNLESS ocodestream=0 DO endread()
    ocodestream := 0
 $)


// read in OCODE operator or argument
// argument may be of form Ln
AND rdn() = VALOF
    $( LET a, sign = 0, '+'
       LET ch = 0

       ch := rdch() REPEATWHILE
          ch='*S' \/ ch='*N' \/ ch='L'

       IF ch=endstreamch RESULTIS 0

       IF ch='-' DO $( sign := '-'
                       ch := rdch()  $)

       WHILE '0'<=ch<='9' DO $( a := 10*a + ch - '0'
                                ch := rdch()  $)

       IF sign='-' DO a := -a
       RESULTIS a
    $)

// read in an OCODE label
AND rdl() = VALOF
    $( LET l = rdn()
       IF maxlab<l DO
       $( maxlab := l
          checkparam() $)
       RESULTIS l  $)

// read in a global number
AND rdgn() = VALOF
    $( LET g = rdn()
       IF maxgn<g DO maxgn := g
       RESULTIS g  $)


// generate next label parameter
AND nextparam() = VALOF
    $( paramnumber := paramnumber-1
       checkparam()
       RESULTIS paramnumber  $)


AND checkparam() BE
       IF maxlab>=paramnumber DO
       $( cgerror("Too many labels -*
                  * increase workspace", TRUE) $)


AND cgerror(n,f,a) BE
    $( writes("*NError. ")
       writef(n,a)
       newline()
       rc := 10
       IF f DO
       $( rc := 20
          longjump(err.p, err.l) $)
    $)

.

SECTION "CG2"

GET ""

// initialise the simulated stack (SS)
LET initstack(n) BE
    $( arg2, arg1 := tempv, tempv+3
       ssp := n
       pendingop := s.none
       h1!arg2, h2!arg2, h3!arg2 := k.loc, ssp-2, ssp-2
       h1!arg1, h2!arg1, h3!arg1 := k.loc, ssp-1, ssp-1
       IF maxssp<ssp DO maxssp := ssp  $)


// move simulated stack (SS) pointer to N
AND stack(n) BE
$(1 IF maxssp<n DO maxssp := n
    IF n>=ssp+4 DO
        $( store(0,ssp-1)
           initstack(n)
           RETURN   $)

    WHILE n>ssp DO loadt(k.loc, ssp)

    UNTIL n=ssp DO
    $( IF arg2=tempv DO
       $( TEST n=ssp-1
            THEN $( ssp := n
                    h1!arg1,h2!arg1 := h1!arg2,h2!arg2
                    h3!arg1 := ssp-1
                    h1!arg2,h2!arg2 := k.loc,ssp-2
                    h3!arg2 := ssp-2  $)
            ELSE initstack(n)
          RETURN  $)

       arg1, arg2 := arg1-3, arg2-3
       ssp := ssp-1  $)
$)1



// store all SS items from A to B in their true
// locations on the stack
AND store(a,b) BE FOR p = tempv TO arg1 BY 3 DO
    $( LET s = h3!p
       IF s>b RETURN
       IF s>=a DO storet(p)  $)



AND scan() BE

$(1 IF testflags(1) DO cgerror("BREAK", TRUE)
    SWITCHON op INTO

 $(sw DEFAULT:     cgerror("Bad op %N", FALSE, op)
                   ENDCASE

      CASE 0:      RETURN

//    CASE s.debug:debugging := NOT debugging
//                 ENDCASE

      CASE s.lp:   loadt(k.loc, rdn()); ENDCASE
      CASE s.lg:   loadt(k.glob, rdgn()); ENDCASE
      CASE s.ll:   loadt(k.lab, rdl()); ENDCASE
      CASE s.ln:   loadt(k.numb, rdn()); ENDCASE

      CASE s.lstr: cgstring(rdn()); ENDCASE

      CASE s.true: loadt(k.numb, #177777); ENDCASE
      CASE s.false:loadt(k.numb, 0); ENDCASE

      CASE s.llp:  loadt(k.lvloc, rdn()); ENDCASE
      CASE s.llg:  loadt(k.lvglob, rdgn()); ENDCASE
      CASE s.lll:  loadt(k.lvlab, rdl()); ENDCASE

      CASE s.sp:   storein(k.loc, rdn()); ENDCASE
      CASE s.sg:   storein(k.glob, rdgn()); ENDCASE
      CASE s.sl:   storein(k.lab, rdl()); ENDCASE

      CASE s.stind:cgstind(); ENDCASE

      CASE s.rv:   cgrv(); ENDCASE

      CASE s.mult:CASE s.div:CASE s.rem:
      CASE s.plus:CASE s.minus:
      CASE s.eq: CASE s.ne:
      CASE s.ls:CASE s.gr:CASE s.le:CASE s.ge:
      CASE s.lshift:CASE s.rshift:
      CASE s.logand:CASE s.logor:CASE s.eqv:CASE s.neqv:
      CASE s.not:CASE s.neg:CASE s.abs:
                   cgpendingop()
                   pendingop := op
                   ENDCASE

      CASE s.jump: cgpendingop()
                   store(0, ssp-1)
                   genbranch(f.br, rdl())
                   ENDCASE

      CASE s.endfor:
                   cgpendingop()
                   pendingop := s.le
      CASE s.jt:   cgjump(TRUE, rdl())
                   ENDCASE

      CASE s.jf:   cgjump(FALSE, rdl())
                   ENDCASE

      CASE s.goto: cgpendingop()
                   store(0, ssp-2)
                   getvalue(arg1)
                   genj(f.jmp,0,h1!arg1,h2!arg1)
                   stack(ssp-1)
                   ENDCASE

      CASE s.lab:  cgpendingop()
                   store(0, ssp-1)
                   cglab(rdl())
                   ENDCASE

      CASE s.query:cgpendingop()
                   stack(ssp+1)
                   ENDCASE

      CASE s.stack:cgpendingop()
                   stack(rdn())
                   ENDCASE

      CASE s.store:cgpendingop()
                   store(0, ssp-1)
                   ENDCASE

      CASE s.entry:
                $( LET n = rdn()
                   LET l = rdl()
                   cgentry(n, l)
                   ENDCASE  $)

      CASE s.save: cgsave(rdn())
                   IF stkchking DO
                   $( IF procstkp>=20 DO
                         cgerror("Proc stack ovf", TRUE)
                      procstk!procstkp := maxssp
                      genj(f.jsr,r.pc,k.glob,gn.checkstk)
                      procstk!(procstkp+1) := stvp
                      code(0,0)
                      maxssp := ssp $)
                   procstkp := procstkp+2
                   ENDCASE

      CASE s.fnap:
      CASE s.rtap: cgapply(op, rdn())
                   ENDCASE

      CASE s.rtrn:
      CASE s.fnrn: cgreturn(op)
                   ENDCASE

      CASE s.endproc:
                $( LET n = rdn()
                   procstkp := procstkp-2
                   IF stkchking  DO
                   $( stv!(procstk!(procstkp+1)) :=
                         2*maxssp-2
                      maxssp := procstk!procstkp $)
                   ENDCASE  $)

      CASE s.res:  cgpendingop()
                   store(0, ssp-2)
                   movetor(arg1,r0)
                   genbranch(f.br, rdl())
                   stack(ssp-1)
                   ENDCASE

      CASE s.rstack:
                   initstack(rdn())
                   loadt(k.reg, r0)
                   ENDCASE

      CASE s.finish:
                   loadt(k.numb, 0)
                   loadt(k.numb, 0)
                   cgglobcall(gn.stop)
                   ENDCASE

      CASE s.switchon:
                   cgswitch(rdn())
                   ENDCASE

      CASE s.getbyte:
      CASE s.putbyte:
                   cgbyteap(op)
                   ENDCASE

      CASE s.needs:cgname(s.needs,rdn())
                   ENDCASE

      CASE s.global:
                   cgglobal(rdn())
                   RETURN

      CASE s.datalab:
      CASE s.iteml:cgdata(op, rdl()); ENDCASE
      CASE s.itemn:cgdata(op, rdn()); ENDCASE
 $)sw

//  IF debugging DO dboutput()
    op := rdn()

$)1 REPEAT

.

SECTION "CG3"

GET ""

// compiles code to deal with any pending op
LET cgpendingop() BE

$(1 LET r = 0
    LET sw = FALSE
    LET pendop = pendingop
    LET num1 = h1!arg1=k.numb
    LET kk = h2!arg1
    LET rand1,rand2 = arg1,arg2

    pendingop := s.none

    SWITCHON pendop INTO
    $(sw CASE s.abs:
                 r := movetoanyr(arg1)
                 UNLESS moved DO gend(f.tst,k.reg,r)
                 checkbrefs(3)
                 code(f.bge+1,0)
         CASE s.neg:
                 sw := TRUE
         CASE s.not:
                 r := movetoanyr(arg1)
                 gend(sw->f.neg,f.com, k.reg, r)
         CASE s.none:
                 RETURN
    $)sw

    getvalue(arg1)
    getvalue(arg2)

    IF h1!arg2=k.numb \/ h1!arg1=k.reg \/
          lookinfreeregs(arg1)>=0 DO
       // swop operands for symetric ops
       rand1,rand2 := arg2,arg1

    SWITCHON pendop INTO

    $(sw DEFAULT:cgerror("Bad pndop %N",FALSE,pendop)
                 RETURN

         CASE s.eq: CASE s.ne:
         CASE s.ls: CASE s.gr:
         CASE s.le: CASE s.ge:
                 // comparisons are ARG2 <op> ARG1
              $( LET f = condbrfn(pendop)
                 r := nextr(-1)
                 gend(f.clr,k.reg,r)
                 f := cgcmp(FALSE,f)
                 checkbrefs(3)
                 code(f+1,0)
                 gend(f.com,k.reg,r)
                 ENDCASE $)

         CASE s.eqv:
                 sw := TRUE
         CASE s.neqv:
              $( LET rs = movetoanyr(arg1)
                 r := movetoanyr(arg2)

                 TEST restricted
                 THEN $( LET w = nextr(-1)
                         gensd(f.mov,k.reg,rs,k.reg,w)
                         gensd(f.bic,k.reg,r,k.reg,w)
                         gensd(f.bic,k.reg,rs,k.reg,r)
                         gensd(f.bis,k.reg,w,k.reg,r) $)
                 ELSE genrd(f.xor, rs, k.reg, r)

                 IF sw DO gend(f.com, k.reg, r)
                 ENDCASE  $)

         CASE s.plus:
                 IF num1 & h1!arg2=k.numb DO
                 $( lose1(k.numb, kk+h2!arg2)
                    RETURN  $)

                 r := movetoanyr(rand2)
                 cgplus(rand1,k.reg,r)
                 ENDCASE

         CASE s.minus:
                 r := movetoanyr(arg2)
                 cgminus(arg1,k.reg,r)
                 ENDCASE

         CASE s.mult:
                 IF numberis(2,rand1) DO
                 $( r := movetoanyr(rand2)
                    gend(f.asl, k.reg, r)
                    ENDCASE  $)

                 IF restricted DO
                 $( cgglobcall(gn.mult)
                    loadt(k.reg, r0)
                    RETURN  $)

                 r := h1!rand2=k.reg -> h2!rand2,
                           isfree(1) -> 1,3
                 movetor(rand2,r)
                 IF (r&1)=0 DO freereg(r\/1,rand1)
                 genrs(f.mul,r,h1!rand1,h2!rand1)
                 r := r\/1
                 ENDCASE

         CASE s.div:
                 sw := TRUE
         CASE s.rem:
                 TEST restricted

                 THEN $( cgglobcall(sw->gn.div,gn.rem)
                         loadt(k.reg,r0)
                         RETURN  $)

                 ELSE $( LET n = regusedby(arg2)
                         r := isfree(0) & isfree(1) -> 0,
                              isfree(2) & isfree(3) -> 2,
                              n>=0 -> n&2, nextr(-1)&2
                         freereg(r,arg2)
                         movetor(arg2, r+1)
                         UNLESS moved DO
                            gend(f.tst,k.reg,r+1)
                         gend(f.sxt, k.reg, r)
                         genrs(f.div,r,h1!arg1,h2!arg1)
                         UNLESS sw DO r := r+1  $)

                 ENDCASE

          CASE s.logor:
                 r := movetoanyr(rand2)
                 gensd(f.bis,h1!rand1,h2!rand1,k.reg,r)
                 ENDCASE

          CASE s.logand:
                 r := movetoanyr(rand2)
                 cglogand(rand1,k.reg,r)
                 ENDCASE

          CASE s.lshift:
                 sw := TRUE
          CASE s.rshift:
                 IF num1 DO
                 $( IF kk=1 \/ kk=2 \/ kk=8 DO
                    $( r := movetoanyr(arg2)
                       cgshiftk(sw,kk,k.reg,r)
                       ENDCASE
                    $)

                    UNLESS restricted DO
                    $( r := movetoanyr(arg2)
                       TEST sw
                       THEN genrs(f.ash,r,k.numb,kk)
                       ELSE $( gen(f.clc)
                               gend(f.ror,k.reg,r)
                               genrs(f.ash,r,k.numb,1-kk)
                            $)
                       ENDCASE
                    $)
                 $)

             IF restricted DO
             $( cgglobcall(sw->gn.lshift,gn.rshift)
                loadt(k.reg,r0)
                RETURN  $)

             TEST sw

             THEN $( r := movetoanyr(arg2)
                     genrs(f.ash,r,h1!arg1,h2!arg1)  $)

             ELSE $( LET n = regusedby(arg2)
                     LET s = nextr(-1)
                     r := s=0 \/ s=1 ->  2,0
                     genmov(k.numb,16,k.reg,s)
                     gensd(f.sub,h1!arg1,h2!arg1,k.reg,s)
                     h1!arg1, h2!arg1 := k.reg, s
                     movetor(arg2, r+1)
                     freereg(r,0)
                     gend(f.clr, k.reg, r)
                     genrs(f.ashc, r, k.reg, s)  $)

             ENDCASE

    $)sw

    lose1(k.reg, r)
$)1



// compiles a global call for out of
// line functions
AND cgglobcall(gn) BE
    $( cgpendingop()
       store(0,ssp-3)
       movetor(arg2, r0)
       movetor(arg1, r1)
       stack(ssp-2)
       genj(f.jsr,r.pc,k.glob,gn)
       code(2*ssp,0)
       forgetall()
    $)


AND numberis(n,a) =
       h1!a=k.numb & h2!a=n -> TRUE, FALSE

.

SECTION "CG4"

GET ""

// make any Lvalues addressable - ie get them
// into a register
LET getvalue(a) BE
       IF h1!a=k.lvloc \/ h1!a=k.lvglob \/ h1!a=k.lvlab DO
          movetoanyr(a)


// move a SS item into any register and shift
// it left for use with CGRV
AND movetoanyrsh(a) = VALOF
    $( LET k,n,r = h1!a,h2!a,-1
       LET km = k=k.loc -> k.mloc,
                k=k.lab -> k.mlab,
                k=k.glob -> k.mglob, k.none
       UNLESS km=k.none DO
       $( r := lookinregs(km,n)
          IF r>=0 RESULTIS r $)
       r := movetoanyr(a)
       gend(f.asl,k.reg,r)
       setinfo(r,km,n)
       RESULTIS r
    $)


// move a SS item into any register
AND movetoanyr(a) = VALOF
    $( LET k,n,r = h1!a,h2!a,0
       moved := FALSE
       IF k=k.reg RESULTIS n
       r := lookinfreeregs(k,n)
       IF r>=0 DO
       $( h1!a,h2!a := k.reg,r
          RESULTIS r $)
       RESULTIS movetor(a,nextr(-1))
    $)


// move a SS item into a given  register
AND movetor(a,r) = VALOF
    $( freereg(r,a)
       moved := FALSE
       genmov(h1!a,h2!a,k.reg,r)
       h1!a,h2!a := k.reg,r
       RESULTIS r
    $)


// look for the value of an item (K,N) in the
// registers; the register will not be modified
AND lookinregs(k,n) = VALOF
    $( FOR r=r0 TO r3 DO
          IF reg.k!r=k & reg.n!r=n RESULTIS r
       RESULTIS -1
    $)


// look for the value of an item (K,N) in the
// free registers; the register may be modified
AND lookinfreeregs(k,n) = VALOF
    $( FOR r=r0 TO r3 DO
          IF reg.k!r=k & reg.n!r=n & isfree(r) RESULTIS r
       RESULTIS -1
    $)


// allocate the next register (except x);
// free it if required
AND nextr(x) = VALOF
    $( FOR r=r0 TO r3 DO
          UNLESS r=x DO
             IF reg.k!r=k.none & isfree(r) RESULTIS r
       FOR r=r0 TO r3 DO
          UNLESS r=x DO
             IF isfree(r) RESULTIS r
       FOR t=tempv TO arg1 BY 3 DO
       $( LET r=regusedby(t)
          UNLESS r=x IF r>=0 DO
          $( freereg(r,0)
             RESULTIS r $)
       $)
    $)


// find which register, if any, is used by
// a SS item
AND regusedby(a) = VALOF
    $( LET k=h1!a
       IF k=k.reg RESULTIS h2!a
       IF k.x0<=k<=k.x3 RESULTIS k-k.x0
       RESULTIS -1  $)


AND isfree(r) = VALOF
    $( FOR t=tempv TO arg1 BY 3 DO
          IF regusedby(t)=r RESULTIS FALSE
       RESULTIS TRUE
    $)


// free register R by storing the values of
// all SS items (except X) that depend upon it
AND freereg(r,x) BE
       FOR t=tempv TO arg1 BY 3 DO
          UNLESS t=x DO IF regusedby(t)=r DO
             storet(t)


// store the value of a SS item in its true
// stack location
AND storet(a) BE
    $( getvalue(a)
       genmov(h1!a,h2!a,k.loc,h3!a)
       h1!a := k.loc
       h2!a := h3!a  $)


// load an item (K,N) onto the SS
AND loadt(k, n) BE
    $( cgpendingop()
       arg2 := arg1
       arg1 := arg1 + 3
       IF h3+arg1-tempt>=0 DO
          cgerror("Sim stack ovf", TRUE)
       h1!arg1,h2!arg1,h3!arg1 := k,n,ssp
       ssp := ssp + 1
       IF maxssp<ssp DO maxssp := ssp
    $)


// replace the top two SS items by (K,N)
AND lose1(k, n) BE
    $( ssp := ssp - 1
       TEST arg2=tempv
       THEN $( h1!arg2,h2!arg2 := k.loc,ssp-2
               h3!arg2 := ssp-2 $)
       ELSE $( arg1 := arg2
               arg2 := arg2-3 $)
       h1!arg1, h2!arg1, h3!arg1 := k,n,ssp-1
    $)


AND cgbyteap(op) BE
$(1 cgpendingop()
 $( LET s = movetoanyrsh(arg2)
    LET i = h2!arg1
    UNLESS h1!arg1=k.numb DO
    $( freereg(s,arg2)
       getvalue(arg1)
       cgplus(arg1,k.reg,s)
       i := 0 $)
    TEST op=s.getbyte
    THEN $( LET r = nextr(s)
            gend(f.clr,k.reg,r)
            codesd(f.bisb,m.v60+s,i,r,0)
            lose1(k.reg,r)
         $)
    ELSE $( TEST arg2=tempv
            THEN formsaddr(k.loc,ssp-3)
            ELSE $( LET arg3 = arg2-3
                    getvalue(arg3)
                    formsaddr(h1!arg3,h2!arg3)
                 $)
            codesd(f.movb,addr.m,addr.v,m.v60+s,i)
            forgetvars()
            stack(ssp-3)
         $)
 $)
$)1


AND cgstind() BE
    $( cgrv()
       genmov(h1!arg2,h2!arg2,h1!arg1,h2!arg1)
       forgetvars()
       stack(ssp-2)
    $)


// store the top item of the SS in (K,N)
AND storein(k, n) BE

$(1 LET b = (h1!arg1=k & h2!arg1=n) -> 1,
            (h1!arg2=k & h2!arg2=n) -> 2, 0
    LET arg = b=2 -> arg1,arg2
    LET num = b=2 & h1!arg=k.numb
    LET kk = h2!arg
    LET sw = FALSE
    LET pendop = pendingop

    IF b=0 GOTO gencase

    pendingop := s.none
    SWITCHON pendop INTO

    $(2 DEFAULT:
        gencase: pendingop := pendop
                 cgpendingop()

        CASE s.none:
                 getvalue(arg1)
                 genmov(h1!arg1,h2!arg1,k,n)
                 stack(ssp-1)
                 RETURN

        CASE s.neg:
                 sw := TRUE
        CASE s.not:
                 UNLESS b=1 GOTO gencase
                 gend(sw->f.neg,f.com, k, n)
                 stack(ssp-1)
                 RETURN

        CASE s.plus:
                 getvalue(arg)
                 cgplus(arg, k, n)
                 ENDCASE

        CASE s.minus:
                 getvalue(arg)
                 cgminus(arg, k, n)
                 IF b=1 DO gend(f.neg,k, n)
                 ENDCASE

        CASE s.logor:
                 getvalue(arg)
                 gensd(f.bis,h1!arg,h2!arg,k,n)
                 ENDCASE

        CASE s.logand:
                 getvalue(arg)
                 cglogand(arg, k, n)
                 ENDCASE

        CASE s.neqv:
                 IF restricted GOTO gencase
                 genrd(f.xor,movetoanyr(arg),k,n)
                 ENDCASE

        CASE s.mult:
                 IF h1!arg=k.numb DO
                    IF kk=2 \/ kk=4 DO
                    $( cgshiftk(TRUE,kk/2,k,n)
                       ENDCASE
                    $)
                 GOTO gencase

        CASE s.lshift:
                 sw := TRUE
        CASE s.rshift:
                 IF num DO
                    IF kk=1 \/ kk=2 \/ kk=8 DO
                    $( cgshiftk(sw,kk,k,n)
                       ENDCASE
                    $)

                 GOTO gencase
    $)2
    stack(ssp-2)
$)1

.

SECTION "CG5"

GET ""

LET cgrv() BE

$(1 LET r = 0

    IF pendingop=s.minus & h1!arg1=k.numb DO
             pendingop, h2!arg1 := s.plus, -h2!arg1

    TEST pendingop=s.plus &
          (h1!arg1=k.numb \/ h1!arg2=k.numb)

    THEN $( LET arg = arg2
            LET n = h2!arg1
            IF h1!arg2=k.numb DO arg,n := arg1,h2!arg2
            pendingop := s.none
            r := movetoanyrsh(arg)
            lose1(k.x0+r,n) $)

    ELSE $( cgpendingop()
            r := movetoanyrsh(arg1)
            h1!arg1, h2!arg1 := k.x0+r, 0 $)
$)1


AND cgshiftk(sw,kk,k,n) BE
$(1 IF kk=8 DO
    $( gend(sw->f.swab,f.clrb, k, n)
       gend(sw->f.clrb,f.swab, k, n)
       RETURN
    $)
    UNLESS sw DO gen(f.clc)
    gend(sw->f.asl,f.ror, k, n)
    IF kk=2 DO gend(sw->f.asl,f.asr, k, n)
$)1


AND cgaddk(kk, k, n) BE UNLESS kk=0 DO
$(1 IF kk=1  DO $( gend(f.inc, k, n); RETURN  $)
    IF kk=-1 DO $( gend(f.dec, k, n); RETURN  $)
    gensd(f.add, k.numb, kk, k, n)
$)1


AND cgplus(a,k,n) BE TEST h1!a=k.numb
    THEN cgaddk(h2!a, k, n)
    ELSE gensd(f.add, h1!a, h2!a, k, n)


AND cgminus(a,k,n) BE TEST h1!a=k.numb
    THEN cgaddk(-h2!a, k, n)
    ELSE gensd(f.sub, h1!a, h2!a, k, n)


AND cglogand(a,k,n) BE TEST h1!a=k.numb
    THEN gensd(f.bic,k.numb,NOT h2!a,k,n)
    ELSE $( LET ra=movetoanyr(a)
            gend(f.com,k.reg,ra)
            gensd(f.bic,k.reg,ra,k,n)  $)


AND cgglobal(n) BE
$(1 cgstatics()
    code(0, 0)
    FOR i = 1 TO n DO
    $( code(rdgn(), 0)
       code(labv!rdl(), 0)  $)
    code(maxgn, 0)
$)1


AND cgentry(n,l) BE
$(1 genbrefjumps(25,0)
    cgname(s.entry,n)
    setlab(l)
    incode := TRUE
    codesd(f.add,m.v7s,0,r.p,0)      // ADD @0(SP),P
    codesd(f.mov,m.2s,0,m.2p,0)      // MOV (SP)+,(P)+
    IF naming DO
       codesd(f.mov,r.pc,0,m.v6p,-4) // MOV PC,-4(P)
    countflag := callcounting
    forgetall()
$)1


AND cgsave(n) BE
$(1 TEST n>=5
    THEN $( IF n>=6 DO codesd(f.mov,r3,0,m.v6p,6)
            codesd(f.mov,r.p,0,r3,0)
            FOR r=r0 TO r2 DO
            $( codesd(f.mov,r,0,m.20+r3,0)
               setinfo(r,k.loc,r+2)
            $)
         $)
    ELSE $( IF n>=3 DO genmov(k.reg,r0,k.loc,2)
            IF n>=4 DO genmov(k.reg,r1,k.loc,3)
         $)
    initstack(n)
$)1


// function or routine call
AND cgapply(op,k) BE

$(1 LET sr0 = k+2
    LET sr3 = k+5

    cgpendingop()

    // store args 5,6,...
    store(sr3+1, ssp-2)

    // now deal with non-args
    FOR t = tempv TO arg2 BY 3 DO
        $( IF h3!t>=k BREAK
           IF regusedby(t)>=0 DO storet(t)  $)

    getvalue(arg1)

    // move args 1-4 to arg registers
    FOR t = arg2 TO tempv BY -3 DO
        $( LET s = h3!t
           LET r = s-sr0
           IF s<sr0 BREAK
           IF s<=sr3 & isfree(r) DO movetor(t,r)  $)
    FOR t = arg2 TO tempv BY -3 DO
        $( LET s = h3!t
           LET r = s-sr0
           IF s<sr0 BREAK
           IF s<=sr3 DO movetor(t,r)  $)

    // deal with args not in SS
    FOR s = sr0 TO sr3 DO
    $( LET r = s-sr0
       IF s>=h3!tempv BREAK
       freereg(r,0)
       genmov(k.loc, s, k.reg, r)  $)

    genj(f.jsr,r.pc,h1!arg1,h2!arg1)
    code(2*k-2,0)
    forgetall()
    stack(k)
    IF op=s.fnap DO loadt(k.reg,r0)
$)1


AND cgreturn(op) BE

$(1 cgpendingop()
    IF op=s.fnrn DO
    $( movetor(arg1,r0)
       stack(ssp-1)  $)
    codesd(f.mov,m.4p, 0, r3, 0)      // MOV -(P),R3
    codesd(f.sub, m.20+r3, 0, r.p, 0) // SUB (R3)+,P
    genj(f.jmp,0,k.reg,r3)            // JMP (R3)
    initstack(ssp)
$)1


// used for OCODE operators JT and JF
AND cgjump(b,l) BE
$(1 LET f = condbrfn(pendingop)
    IF f=0 DO
    $( cgpendingop()
       loadt(k.numb,0)
       f := f.bne $)
    pendingop := s.none
    store(0,ssp-3)
    getvalue(arg1)
    getvalue(arg2)
    f := cgcmp(b,f)
    genbranch(f,l)
    stack(ssp-2)
    countflag := profcounting
$)1


AND cgcmp(b,f) = VALOF
$(1 TEST numberis(0,arg1)
    THEN gend(f.tst,h1!arg2,h2!arg2)
    ELSE TEST numberis(0,arg2)
         THEN $( gend(f.tst,h1!arg1,h2!arg1)
                 f := VALOF SWITCHON f INTO
                    $( CASE f.blt: RESULTIS f.bgt
                       CASE f.bge: RESULTIS f.ble
                       CASE f.ble: RESULTIS f.bge
                       CASE f.bgt: RESULTIS f.blt
                       DEFAULT:    RESULTIS f
                    $)
              $)
         ELSE gensd(f.cmp,h1!arg2,h2!arg2,h1!arg1,h2!arg1)
    RESULTIS b -> f, f NEQV f.br
$)1

.

SECTION "CG6"

GET ""

// compiles code for SWITCHON
// N = no. of cases
// D = default label
LET cgswitch(n) BE
    $(1 LET d = rdl()
        LET v = getvec(2*n+1)
        IF v=0 DO cgerror("Run out of store",TRUE)
        casek, casel := v, v+n

        // read and sort (K,L) pairs
        FOR i = 1 TO n DO
          $( LET a = rdn()
             LET l = rdl()
             LET j = i-1
             UNTIL j=0 DO
               $( IF a > casek!j BREAK
                  casek!(j+1) := casek!j
                  casel!(j+1) := casel!j
                  j := j - 1  $)
             casek!(j+1), casel!(j+1) := a, l  $)

        cgpendingop()
        store(0, ssp-2)
        movetor(arg1,r0)
        stack(ssp-1)

        UNLESS n=0 DO
           // care with overflow !
           TEST 2*n-6 > casek!n/2-casek!1/2

                   THEN lswitch(1, n, d)

                   OR $( bswitch(1, n, d)

                         genbranch(f.br, d)  $)

           freevec(v)
    $)1


// binary switch
AND bswitch(p, q, d) BE TEST q-p>6

      THEN $( LET m = nextparam()
              LET t = (p+q)/2
              gensd(f.cmp,k.reg,r0,k.numb,casek!t)
              genbranch(f.bge,m)
              bswitch(p, t-1, d)
              genbranch(f.br,d)
              genbrefjumps(25,0)
              setlab(m)
              incode := TRUE
              genbranch(f.beq,casel!t)
              bswitch(t+1, q, d)  $)

      ELSE FOR i = p TO q DO
              $( gensd(f.cmp,k.reg,r0,k.numb,casek!i)
                 genbranch(f.beq,casel!i) $)



// label vector switch
AND lswitch(p,q,d) BE
    $(1 LET l = nextparam()
        gensd(f.cmp,k.reg,r0,k.numb,casek!p)
        genbranch(f.blt,d)
        gensd(f.cmp,k.reg,r0,k.numb,casek!q)
        genbranch(f.bgt,d)
        gend(f.asl,k.reg,r0)
        checkbrefs(2)
        gen(f.jmp+#70+r0)
        code(-2*casek!p, l)
        incode := FALSE
        genbrefjumps(casek!q-casek!p+25,0)
        setlab(l)
        FOR k=casek!p TO casek!q TEST casek!p=k
            THEN $( code(0, casel!p);
                    p := p+1 $)
            ELSE code(0, d)
    $)1


// checks that at least N consecutive words
// may be compiled without any branch refs
// going out of range
AND checkbrefs(n) BE
  $( IF countflag DO insertcount()
     UNLESS brefv=brefp \/
      brefv!1+127-n-(brefp-brefv)/2>stvp DO
        TEST incode
        THEN $( LET l = nextparam()
                brlabref(l, stvp)
                code(f.br, 0)
                genbrefjumps(n+25,0)
                setlab(l)  $)
        ELSE genbrefjumps(n+25,0)
  $)


// generates jumps to fill in enough branch
// refs to ensure that at least N words may
// be compiled, given that label X is to be
// defined as the next location; is only
// called when INCODE is (should be) false
AND genbrefjumps(n,x) BE
  $( LET p = brefv
     UNTIL p=brefp \/
      p!1+127-n-(brefp-brefv)/2>stvp DO
        $( IF p!0=x DO     // leave refs to X
           $( p := p+2
              LOOP $)
           IF brefv!0=x DO // check X still in range
           $( UNLESS brefv!1+127>stvp DO
              $( genbrefjumps(n,0)
                 RETURN $)
           $)
        $( LET l=p!0
           setlab(l)       // to fill in branch refs
           labv!l := -1    // then unset L again
           code(f.jmp+#67, 0)
           coderand(m.l67,l)
        $)
        $)
  $)


// generate a label ref for a branch instr
AND brlabref(l, a) BE
     $( brefp!0, brefp!1 := l, a
        brefp := brefp + 2  $)


AND condbrfn(op) = VALOF SWITCHON op INTO
     $( CASE s.eq:  RESULTIS f.beq
        CASE s.ne:  RESULTIS f.bne
        CASE s.gr:  RESULTIS f.bgt
        CASE s.le:  RESULTIS f.ble
        CASE s.ge:  RESULTIS f.bge
        CASE s.ls:  RESULTIS f.blt
        DEFAULT:    RESULTIS 0
     $)


AND genbranch(f, l) BE IF incode DO
    $(1 LET a = labv!l

        checkbrefs(1)

        IF a=-1 DO         // label is unset
           $( brlabref(l, stvp)
              code(f,0)
              IF f=f.br DO incode := FALSE
              RETURN  $)

        IF stvp-a > 127 DO // back jump too far for BR
           $( LET m = 0
              IF f=f.br DO
              $( coded(f.jmp,m.l67,l)
                 incode := FALSE
                 RETURN $)
              f := f NEQV f.br
              m := nextparam()
              genbranch(f, m)
              coded(f.jmp, m.l67, l)
              genbrefjumps(25,m)
              setlab(m)
              RETURN  $)

        // it must be a short backward jump
        code(f+(a-stvp-1 & #377), 0)
        IF f=f.br DO incode := FALSE
    $)1


// generate a MOV instr; will calculate Lvalues
AND genmov(k1,n1,k2,n2) BE UNLESS k1=k2 & n1=n2 DO
   $(1 LET mv,m1,v1 = 0,0,0
       LET r=lookinregs(k1,n1)
       IF r>=0 DO k1,n1 := k.reg,r
       UNLESS k1=k2 & n1=n2 DO
       $( SWITCHON k1 INTO
          $( CASE k.lvloc:
                m1,mv := r.p,2*(n1-2)
                GOTO l

             CASE k.lvglob:
                m1,mv := r.g,2*n1
                GOTO l

             CASE k.lvlab:
                m1,v1 := m.l27,n1
           l:   formdaddr(k2,n2)
                codesd(f.mov,m1,v1,addr.m,addr.v)
                UNLESS mv=0 DO
                   codesd(f.add,m.v27,mv,addr.m,addr.v)
                IF mv<=0 DO gen(f.clc)
                coded(f.ror,addr.m,addr.v)
                ENDCASE

             CASE k.numb:
                IF n1=0 DO
                $( formdaddr(k2,n2)
                   coded(f.clr,addr.m,addr.v)
                   ENDCASE $)

             DEFAULT:
                gensd(f.mov,k1,n1,k2,n2)
          $)
          moved := TRUE
       $)
       remem(k1,n1,k2,n2)
   $)1


AND gensd(f,k1,n1,k2,n2) BE
    $( formsaddr(k1,n1)
    $( LET m1,v1 = addr.m,addr.v
       TEST f=f.cmp
         THEN formsaddr(k2,n2)
         ELSE formdaddr(k2,n2)
       codesd(f,m1,v1,addr.m,addr.v)
    $) $)


AND genrs(f,r,k,n) BE
    $( formsaddr(k,n)
       forget(k.reg,r)
       IF f=f.mul \/ f=f.div \/ f=f.ashc DO
          // these instrs use a register pair
          forget(k.reg,r\/1)
       coders(f,r,addr.m,addr.v)
    $)


AND genrd(f,r,k,n) BE
    $( formdaddr(k,n)
       coders(f,r,addr.m,addr.v)
    $)


AND gend(f,k,n) BE
    $( TEST f=f.tst
         THEN formsaddr(k,n)
         ELSE formdaddr(k,n)
       coded(f,addr.m,addr.v)
    $)


AND gen(f) BE IF incode DO
    $( checkbrefs(1)
       code(f,0)
    $)


// generate a JMP or JSR instr;
// one extra level of indirection
AND genj(f,r,k,n) BE
    $( formsaddr(k,n)
       addr.m := (addr.m & m.10)=0 ->
          addr.m+m.10, (addr.m & 7)+m.v70
       IF f=f.jsr DO checkbrefs(3)
       coders(f,r,addr.m,addr.v)
       IF f=f.jmp DO incode := FALSE
    $)

.

SECTION "CG7"

GET ""

// forms a source address (M,V) pair;
// looks in the registers
LET formsaddr(k,n) BE
    $( LET r=lookinregs(k,n)
       IF r>=0 DO
       $( addr.m,addr.v := r,0
          RETURN $)
       formaddr(k,n)
    $)


// forms a destination address (M,V) pair;
// forgets the value of the destination
AND formdaddr(k,n) BE
    $( forget(k,n)
       formaddr(k,n)
    $)


// forms a machine address pair (M,V)
// for use by a CODE- routine
AND formaddr(k,n) BE
   $(1 SWITCHON k INTO
       $( CASE k.loc:
             addr.m,addr.v := m.v6p,2*(n-2)
             ENDCASE

          CASE k.glob:
             addr.m,addr.v := m.v6g,2*n
             ENDCASE

          CASE k.lab:
             addr.m,addr.v := m.l67,n
             ENDCASE

          CASE k.numb:
             addr.m,addr.v := m.v27,n
             ENDCASE

          CASE k.reg:
             addr.m,addr.v := n,0
             ENDCASE

          CASE k.x0: CASE k.x1: CASE k.x2: CASE k.x3:
             addr.m,addr.v := m.v60+k-k.x0,2*n
       $)
       IF m.v60<=addr.m<=m.v67 & addr.v=0 DO
          addr.m := (addr.m & 7)+m.10
   $)1



// called by GENMOV to update the contents
// of the registers
AND remem(k1,n1,k2,n2) BE
       TEST k2=k.reg
         THEN setinfo(n2,k1,n1)
         ELSE IF k1=k.reg & reg.k!n1=k.none DO
                 setinfo(n1,k2,n2)


// sets the info for register R to (K,N)
AND setinfo(r,k,n) BE
    $( SWITCHON k INTO
       $( CASE k.reg:
             k := reg.k!n
             n := reg.n!n
             ENDCASE

          DEFAULT:
             k := k.none
          CASE k.loc: CASE k.glob:
          CASE k.lab:
          CASE k.mloc: CASE k.mglob:
          CASE k.mlab:
          CASE k.lvloc: CASE k.lvglob:
          CASE k.lvlab:
          CASE k.numb:
       $)
       reg.k!r := k
       reg.n!r := n
    $)


// forgets the value of a register or variable
AND forget(k,n) BE
    $( SWITCHON k INTO
       $( CASE k.reg:
             reg.k!n := k.none
          DEFAULT:
             RETURN

          CASE k.loc:
             forget(k.mloc,n)
             ENDCASE

          CASE k.glob:
             forget(k.mglob,n)
             ENDCASE

          CASE k.lab:
             forget(k.mlab,n)

          CASE k.mloc: CASE k.mglob: CASE k.mlab:
       $)
       FOR r=r0 TO r3 DO IF reg.k!r=k & reg.n!r=n DO
             reg.k!r := k.none
    $)


// forgets the values of all variables; called
// after an indirect assignment
AND forgetvars() BE
    FOR r=r0 TO r3 SWITCHON reg.k!r INTO
       $( CASE k.loc: CASE k.glob:
          CASE k.lab:
          CASE k.mloc: CASE k.mglob:
          CASE k.mlab:
             reg.k!r := k.none
          DEFAULT:
       $)


// forgets the contents of all registers; called
// after labels, procedure calls
AND forgetall() BE
    FOR r=r0 TO r3 DO reg.k!r := k.none


// makes one word of code; L indicates a label ref
AND code(a, l) BE
$(1 UNLESS l=0 DO labref(l, stvp)
    stv!stvp := a
    stvp := stvp + 1
    checkspace()
$)1

// make an operand if required
AND coderand(m, v) BE
$(1 UNLESS (m&m.v)=0 DO code(v, 0)
    UNLESS (m&m.l)=0 DO TEST m=m.l27
       THEN code(0,v)
       ELSE code(-2*stvp-2, -v)
$)1

AND coded(f, m, v) BE IF incode DO
$(1 checkbrefs(2)
    code(f+(m&#77),0)
    coderand(m, v)  $)1

AND coders(f, r, m, v) BE IF incode DO
$(1 checkbrefs(2)
    code(f+(r<<6)+(m&#77),0)
    coderand(m, v)  $)1

AND codesd(f, m1, v1, m2, v2) BE IF incode DO
$(1 checkbrefs(3)
    code(f+((m1&#77)<<6)+(m2&#77),0)
    coderand(m1,v1)
    coderand(m2,v2)  $)1


// inserts a profile count
AND insertcount() BE
$(1 countflag := FALSE
    codesd(f.add,m.v27,1,m.v27,0)
    coded(f.adc,m.v27,0) $)1


// set the label L to the current location
AND setlab(l) BE
$(1 LET p = brefv
    UNLESS labv!l=-1 DO
      cgerror("Label L%N set twice", FALSE, l)
    labv!l := stvp
    // fill in forward branch refs
    UNTIL p-brefp>=0 DO TEST !p=l
      THEN $( LET loc = p!1
              LET a = stvp - loc - 1
              IF a>127 DO
                 cgerror("Bad BR lab L%N", FALSE, l)
              stv!loc := stv!loc + a
              brefp := brefp - 2
              FOR q = p TO brefp-1 DO q!0 := q!2  $)
      ELSE p := p+2
$)1


// compile OCODE label L
AND cglab(l) BE
$(1 UNLESS incode DO genbrefjumps(25,l)
    IF incode DO UNLESS brefp=brefv DO
       // eliminate redundant branches  (BR .+2)
       IF (brefp-2)!0=l & (brefp-2)!1=stvp-1 DO
          stvp, brefp := stvp-1, brefp-2
    setlab(l)
    incode := TRUE
    countflag := profcounting
    forgetall()
$)1


// compiles names for S.ENTRY, S.SECTION, S.NEEDS
AND cgname(op,n) BE
$(1 LET v = VEC 17/bytesperword+1
    v%0 := op=s.entry-> 7, 17
    FOR i = 1 TO 9 DO v%(i+8) := datvec%i
    FOR i=1 TO n DO
    $( LET c = rdn()
       IF i<=7 DO v%i := c $)
    FOR i = n+1 TO 7 DO v%i :=  n=0 -> '**', '*S'
    v%8 := '*S'
//  UNLESS op=s.entry \/ n=0 DO
//  $( dp := dp-4
//     checkspace()
//     h1!dp, h2!dp := 0, op
//     h3!dp := rad50(v,1)
//     h4!dp := rad50(v,4)
//     !needsliste := dp
//     needsliste := dp
//  $)
    UNLESS op=s.needs DO IF naming DO
    $( IF op=s.section DO code(secword,0)
       FOR i = 0 TO op=s.entry->6,16 BY 2 DO
          code((v%(i+1)<<8)+v%i, 0)
    $)
$)1


 /*
AND rad50(s,i) = VALOF
$(1 LET r(c) =
       'a' <= c <= 'z' -> c-#100,
              c  = '$' -> #33,
              c  = '.' -> #34,
       '0' <= c <= '9' -> c-#22, 0
    LET val = 0
    FOR j = i TO i+2 DO val := val*#50+r(s%j)
    RESULTIS val
$)1
 */

AND cgstring(n) BE
    $(1 LET l,w = nextparam(),n
        loadt(k.lvlab,l)
        cgdata(s.datalab, l)
        $( UNLESS n=0 DO w := rdn()<<8 \/ w
           cgdata(s.itemn, w)
           IF n<=1 BREAK
           n, w := n-2, rdn()  $) REPEAT
    $)1


// generate a label reference
// L>0 => relocation
AND labref(l, p) BE
$(1 dp := dp-3
    checkspace()
    h1!dp, h2!dp, h3!dp := 0, l, p
    !refliste := dp
    refliste := dp  $)1


AND cgdata(a, l) BE
$(1 dp := dp-3
    checkspace()
    h1!dp, h2!dp, h3!dp := 0, a, l
    !dliste := dp
    dliste := dp  $)1


AND cgstatics() BE
$(1 LET d = dlist
    UNTIL d=0 DO
    $( SWITCHON h2!d INTO
       $( CASE s.datalab: setlab(h3!d);    ENDCASE
          CASE s.iteml:   code(0, h3!d);   ENDCASE
          CASE s.itemn:   code(h3!d, 0);   ENDCASE  $)
       d := !d  $)
$)1



AND initdatalists() BE
$(1 reflist := 0
    refliste := @reflist
    dlist := 0
    dliste := @dlist
    needslist := 0
    needsliste := @needslist
$)1


AND checkspace() BE IF stv+stvp-dp>0 DO
    cgerror("Program too large*
            * %N words compiled",TRUE, stvp)

.

SECTION "CG8"

GET ""

LET outputsection() BE
$(1 LET rl = reflist
    LET r = 0

    UNTIL rl=0 DO      // fill in label refs
    $( LET l = h2!rl
       AND a = h3!rl
       LET labval = 0
       TEST l>0
         THEN r := r+1
         ELSE l := -l
       labval := labv!l
       IF labval=-1 DO
          cgerror("Label L%N unset", FALSE, l)
       stv!a := stv!a + 2*labval
       rl := !rl  $)
 /*
    IF cglisting DO
    $( writes("*N; .CSECT*NB:*N")
       rl := reflist
       FOR p = 0 TO stvp-1 DO
       $( LET s = "  "
          writef(" %O6",stv!p&#177777)
          UNLESS rl=0 DO IF h3!rl=p DO
          $( IF h2!rl>0 DO s := "+B"
             rl := !rl  $)
          writef("%S; %O4*N", s, 2*p)  $)
       writes(" .END*N")
    $)
 */
    selectoutput(codestream)

 /* TEST altobj THEN           // DOS object module
    $( LET gsdrec = TABLE
               #X0001,  // GSD
               #006410, // RAD50  "BCPL  "
               #045400,
               0,
               0,
               #63337,  // RAD50  "PROG  "
               #25700,
               #02450,  // PSECT name
               #0       // fill in length here
       LET v = VEC 50
       binv,binp := v,0
       gsdrec!8 := stvp*2      // fill in length
       FOR i = 0 TO 8 DO       // output GSD record
          dosword(gsdrec!i)
       endrecord()
       rl := needslist         // output externals
       UNTIL rl=0 DO
       $( LET t = #02100       // .GLOBAL reference
          dosword(#X0001)      // GSD
          IF h2!rl=s.section DO
          $( dosword(h3!rl)    // name
             dosword(h4!rl)
             dosword(#02150)   // .GLOBAL definition
             dosword(0)
             t := #03000 $)    // .IDENT
          dosword(h3!rl)       // name
          dosword(h4!rl)
          DOSWORD(T)
          DOSWORD(0)
          ENDRECORD()
          rl := !rl
       $)
       dosword(#X0002)         // end of GSD
       endrecord()
       dosword(#X0004)         // RLD to set loc counter
       dosword(#X0007)
       dosword(#63337)         // RAD50 "PROG  "
       dosword(#25700)
       dosword(0)
       endrecord()
       rl := reflist
       FOR T = 0 TO stvp-1 BY 20 DO
       $( LET rldsw = FALSE    // set TRUE if RLD req
          dosword(#X0003)      // TXT record
          dosword(2*t)         // load address
          FOR p = t TO t+19 DO
             IF p<stvp DO dosword(stv!p)
          endrecord()
          UNTIL rl=0 DO
          $( LET a = h3!rl     // addr of word to reloc
             IF h2!rl>0 DO
             $( IF a>t+19 BREAK
                UNLESS rldsw DO   // start RLD record
                   dosword(#X0004)
                rldsw := TRUE
                dosword(#X0001+(2*(a-t+2)<<8))
                dosword(stv!a)  $)
             rl := !rl  $)
          IF rldsw DO             // end record if req
             endrecord()
       $)
       dosword(#X0006)         // end of module record
       endrecord()
    $)

    ELSE                       // TRIPOS object module
 */ $( objword(t.hunk)
       objword(stvp)
       writewords(stv, stvp)
       IF r>0 DO               // output RELOC block
       $( objword(t.reloc)
          objword(r)
          rl := reflist
          UNTIL rl=0 DO
          $( IF h2!rl>0 DO objword(h3!rl)
             rl := !rl $)
       $)
       objword(t.end)
    $)
    selectoutput(verstream)
$)1


AND objword(w) BE writewords(@w, 1)

 /*
AND dosword(w) BE
$(1 binv!binp := w
    binp := binp+1 $)1


AND endrecord() BE
$(1 LET bytes = 2*binp+4
    LET cksum = -1-bytes
    objword(1)
    objword(bytes)
    FOR i=0 to binp-1 DO
    $( LET w = binv!i
       objword(w)
       cksum := cksum-w-(w>>8)
    $)
    objword(cksum&255)
    binp := 0
$)1
 */
 /*
AND dboutput() BE
$(1 LET nl = "*N      "
    writef("op=%N pndop=%N ssp=%N loc=%O4*Nstack ",
           op,pendingop,ssp,stvp*2)
    FOR p=arg1 TO tempv BY -3 DO
    $( IF (arg1-p) REM 30 = 27 DO writes(nl)
       wrkn(h1!p,h2!p) $)
    writes("*Nbrefs ")
    FOR p=brefv TO brefp-2 BY 2 DO
    $( IF p-brefv REM 10 = 8 DO writes(nl)
       writef("L%N %O4 ",p!0,2*p!1) $)
    writes("*Nregs  ")
    FOR r=r0 TO r3 DO UNLESS reg.k!r=k.none DO
    $( writef("r%N=",r)
       wrkn(reg.k!r,reg.n!r) $)
    newline()
$)1


AND wrkn(k,n) BE
$(1 LET s = VALOF
       SWITCHON k INTO
       $( DEFAULT: RESULTIS "?"
          CASE k.numb:   RESULTIS "N"
          CASE k.loc:    RESULTIS "P"
          CASE k.glob:   RESULTIS "G"
          CASE k.lab:    RESULTIS "L"
          CASE k.mloc:   RESULTIS "ML"
          CASE k.mglob:  RESULTIS "MG"
          CASE k.mlab:   RESULTIS "ML"
          CASE k.lvloc:  RESULTIS "@P"
          CASE k.lvglob: RESULTIS "@G"
          CASE k.lvlab:  RESULTIS "@L"
          CASE k.reg:    RESULTIS "R"
          CASE k.x0:     RESULTIS "X0 "
          CASE k.x1:     RESULTIS "X1 "
          CASE k.x2:     RESULTIS "X2 "
          CASE k.x3:     RESULTIS "X3 "
       $)
    writef("%S%N  ",s,n)
$)1
 */


