// (C) Copyright 1978 Tripos Research Group
//     University of Cambridge
//     Computer Laboratory

// BCPL-TRN

GET ":COM.BCPL.BCPL"

MANIFEST
$(
// selectors
h1=0; h2=1; h3=2; h4=3; h5=4; h6=5

// AE tree operators
s.number=1; s.name=2; s.string=3
s.valof=6; s.lv=7; s.vecap=9
s.byteap=28
s.cond=37; s.comma=38; s.table=39
s.and=40; s.valdef=41; s.vecdef=42
s.commalist=43; s.fndef=44; s.rtdef=45
s.ass=50; s.resultis=53; s.colon=54
s.test=55; s.for=56; s.if=57; s.unless=58
s.while=59; s.until=60; s.repeat=61
s.repeatwhile=62; s.repeatuntil=63
s.loop=65; s.break=66
s.endcase=69; s.case=71; s.default=72
s.semicolonlist=73; s.let=74; s.manifest=75; s.static=79
s.semicolon=97

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
$)


GLOBAL
$(
nextparam:200
transreport:201

trans:202

declnames:203
decldyn:204
declstat:205
decllabels:206
checkdistinct:207
addname:208
cellwithname:209
scanlabels:210
transdef:211
transdyndefs:212
transstatdefs:213
statdefs:214

jumpcond:215
transswitch:216
transfor:217

load:218
loadlv:219
loadzero:220
loadlist:221

evalconst:222
assign:223
transname:224

complab:225
compentry:226
compdatalab:227
compjump:228
out1:229
out2:230
out3:233
outstring:236
wrpn:239
endocode:240
wrc:241

paramnumber:250
comcount:251
ssp:252
vecssp:253
currentbranch:254
dvec:255
dvece:257
dvecp:258
dvect:259
globdecl:260
globdecls:261
globdeclt:262
casek:263
casel:264
casep:265
caset:266
caseb:267
breaklabel:268
resultlabel:269
defaultlabel:270
endcaselabel:271
looplabel:272
ocount:273
$)

.

SECTION "TRN1"

GET ""

LET start(x) BE
   $(1 LET t = declsize/10+30
       LET v = 0
       err.p, err.l := level(), fail
       errcount := 0
       dvec := getvec(declsize)
       v := getvec(3*t)
       IF v=0 | dvec=0 DO
         $( rc := 20
            transreport(1, 0) $)

       dvece, dvecp, dvect := 3, 3, declsize
       dvec!0, dvec!1, dvec!2 := 0, 0, 0

       globdecl, globdecls, globdeclt := v, 0, t

       casek, casel := v+t, v+2*t
       casep, caset, caseb := 0, t, -1

       endcaselabel, defaultlabel := 0, 0
       resultlabel, breaklabel, looplabel := -1, -1, -1

       comcount, currentbranch := 0, x
       ocount, paramnumber := 0, 0

       selectoutput(ocodestream)
       WHILE x~=0 &
             (h1!x=s.section | h1!x=s.needs) DO
       $( out1(h1!x)
          outstring(h2!x+1)
          x:=h3!x
       $)
       ssp := savespacesize
       out2(s.stack, ssp)
       decllabels(x)
       trans(x)
       out2(s.global, globdecls/2)

       FOR i = 0 TO globdecls-2 BY 2 DO
           out2(globdecl!i, globdecl!(i+1))

fail:  UNLESS v=0 DO
         $( endocode()
            selectoutput(verstream)
            freevec(v) $)
       UNLESS dvec=0 DO freevec(dvec)
   $)1

AND nextparam() = VALOF
    $( paramnumber := paramnumber + 1
       RESULTIS paramnumber  $)

AND transreport(n, x) BE
    $( LET p = errcount*3
       errvec!p := n
       errvec!(p+1) := x
       errvec!(p+2) := comcount
       errcount := errcount+1
       reportcount := reportcount+1
       IF reportcount>=reportmax DO rc := 20
       IF rc>=20 DO longjump(err.p,err.l)
       IF rc<10  DO rc := 10
    $)

.

SECTION "TRN2"

GET ""

LET trans(x) BE UNLESS x=0 DO
$(t LET sw = FALSE
    comcount :=comcount+1
    currentbranch := x
    IF testflags(1) DO
    $( rc := 20
       transreport(0) $)

    SWITCHON h1!x INTO

$(  DEFAULT:
        transreport(100, x)
        ENDCASE

    CASE s.let:
     $( LET a, s, s1 = dvece, ssp, 0
        LET v = vecssp
        declnames(h2!x)
        checkdistinct(a, dvece)
        vecssp, s1 := ssp, ssp
        ssp := s
        transdef(h2!x)
        UNLESS ssp=s1 DO transreport(110, x)
        UNLESS ssp=vecssp DO $( ssp := vecssp
                                out2(s.stack, ssp)  $)
        out1(s.store)
        decllabels(h3!x)
        trans(h3!x)
        vecssp := v
        UNLESS ssp=s DO out2(s.stack, s)
        dvece, ssp := a, s
        ENDCASE   $)

    CASE s.static:
    CASE s.global:
    CASE s.manifest:
     $( LET a, s = dvece, ssp
        AND op = h1!x
        LET list = h2!x
        LET p = list + 2

        IF op=s.manifest DO op := s.number

        FOR i = 0 TO h2!list-1 BY 2 DO
        $( LET name = p!i
           LET k = evalconst(p!(i+1))
           TEST op=s.static
            THEN $( LET m = nextparam()
                    addname(name, s.label, m)
                    compdatalab(m)
                    out2(s.itemn, k)  $)

            ELSE addname(name, op, k)

        $)

        decllabels(h3!x)
        trans(h3!x)
        dvece, ssp := a, s
        ENDCASE $)


    CASE s.ass:
        assign(h2!x, h3!x)
        ENDCASE

    CASE s.rtap:
     $( LET s = ssp
        ssp := ssp+savespacesize
        out2(s.stack, ssp)
        loadlist(h3!x)
        load(h2!x)
        out2(s.rtap, s)
        ssp := s
        ENDCASE  $)

    CASE s.goto:
        load(h2!x)
        out1(s.goto)
        ssp := ssp-1
        ENDCASE

    CASE s.colon:
        complab(h4!x)
        comcount := comcount-1
        trans(h3!x)
        ENDCASE

    CASE s.unless:
        sw := TRUE
    CASE s.if:
     $( LET l = nextparam()
        jumpcond(h2!x, sw, l)
        trans(h3!x)
        complab(l)
        ENDCASE   $)

    CASE s.test:
     $( LET l, m = nextparam(), nextparam()
        jumpcond(h2!x, FALSE, l)
        trans(h3!x)
        compjump(m)
        complab(l)
        trans(h4!x)
        complab(m)
        ENDCASE   $)

    CASE s.loop:
        IF looplabel<0 DO transreport(104, x)
        IF looplabel=0 DO looplabel := nextparam()
        compjump(looplabel)
        ENDCASE

    CASE s.break:
        IF breaklabel<0 DO transreport(104, x)
        IF breaklabel=0 DO breaklabel := nextparam()
        compjump(breaklabel)
        ENDCASE

    CASE s.return:
        out1(s.rtrn)
        ENDCASE

    CASE s.finish:
        out1(s.finish)
        ENDCASE

    CASE s.resultis:
        IF resultlabel<0 DO transreport(104, x)
        load(h2!x)
        out2(s.res, resultlabel)
        ssp := ssp - 1
        ENDCASE

    CASE s.while:
        sw := TRUE
    CASE s.until:
     $( LET l, m = nextparam(), nextparam()
        LET bl, ll = breaklabel, looplabel
        breaklabel, looplabel := 0, m

        compjump(m)
        complab(l)
        trans(h3!x)
        complab(m)
        jumpcond(h2!x, sw, l)
        UNLESS breaklabel=0 DO complab(breaklabel)
        breaklabel, looplabel := bl, ll
        ENDCASE   $)

    CASE s.repeatwhile:
        sw := TRUE
    CASE s.repeatuntil:
    CASE s.repeat:
     $( LET l,bl,ll = nextparam(),breaklabel,looplabel
        breaklabel, looplabel := 0, 0
        complab(l)
        TEST h1!x=s.repeat
            THEN $( looplabel := l
                    trans(h2!x)
                    compjump(l)  $)
            ELSE $( trans(h2!x)
                    UNLESS looplabel=0 DO
                          complab(looplabel)
                    jumpcond(h3!x, sw, l)  $)
        UNLESS breaklabel=0 DO complab(breaklabel)
        breaklabel, looplabel := bl, ll
        ENDCASE   $)

    CASE s.case:
     $( LET l, k = nextparam(), evalconst(h2!x)
        IF casep>=caset DO
          $( rc := 20
             transreport(141, x) $)
        IF caseb<0 DO transreport(105, x)
        FOR i = caseb TO casep-1 DO
             IF casek!i=k DO transreport(106, x)
        casek!casep := k
        casel!casep := l
        casep := casep + 1
        complab(l)
        trans(h3!x)
        ENDCASE   $)

    CASE s.default:
        IF caseb<0 DO transreport(105, x)
        UNLESS defaultlabel=0 DO
                 transreport(101, x)
        defaultlabel := nextparam()
        complab(defaultlabel)
        trans(h2!x)
        ENDCASE

    CASE s.endcase:
        IF caseb<0 DO transreport(105, x)
        compjump(endcaselabel)
        ENDCASE

    CASE s.switchon:
        transswitch(x)
        ENDCASE

    CASE s.for:
        transfor(x)
        ENDCASE

    CASE s.semicolon:
        comcount := comcount-1
        trans(h2!x)
        trans(h3!x)
        ENDCASE

    CASE s.semicolonlist:
        comcount := comcount - 1
        FOR h = 2 TO h2!x+1 DO trans(h!x)
        ENDCASE
$)t

.

SECTION "TRN3"

GET ""

LET declnames(x) BE
    UNTIL x=0 SWITCHON h1!x INTO

     $(  DEFAULT:
               transreport(102, currentbranch)
               BREAK

         CASE s.vecdef: CASE s.valdef:
               decldyn(h2!x)
               BREAK

         CASE s.rtdef: CASE s.fndef:
               h5!x := nextparam()
               declstat(h2!x, h5!x)
               BREAK

         CASE s.and:
               declnames(h2!x)
               x := h3!x
               LOOP
     $)


AND decldyn(x) BE UNLESS x=0 DO

    SWITCHON h1!x INTO
    $( CASE s.name:
           addname(x, s.local, ssp)
           ssp := ssp + 1
           ENDCASE

       CASE s.comma:
           addname(h2!x, s.local, ssp)
           ssp := ssp + 1
           decldyn(h3!x)
           ENDCASE

       CASE s.commalist:
           FOR h = 2 TO h2!x+1 DO decldyn(h!x)
           ENDCASE

       DEFAULT:
           transreport(103, x)
    $)

AND declstat(x, l) BE
    $(1 LET t = cellwithname(x)

        IF dvec!(t+1)=s.global DO
           $( LET n = dvec!(t+2)
              addname(x, s.global, n)
              IF globdecls+1>=globdeclt DO
                $( rc := 20
                   transreport(144, x) $)
              globdecl!globdecls := n
              globdecl!(globdecls+1) := l
              globdecls := globdecls + 2
              RETURN  $)


     $( LET m = nextparam()
        addname(x, s.label, m)
        compdatalab(m)
        out2(s.iteml, l)
    $)1


AND decllabels(x) BE
    $( LET b = dvece
       scanlabels(x)
       checkdistinct(b, dvece)
    $)


AND checkdistinct(p, q) BE
    FOR s = q-3 TO p BY -3 DO
    $( LET n = dvec!s
       FOR r = p TO s-3 BY 3 DO
           IF dvec!r=n DO transreport(142, n)
    $)


AND addname(n, p, a) BE
    $( IF dvece+2>=dvect DO
         $( rc := 20
            transreport(143, currentbranch) $)
       dvec!dvece,dvec!(dvece+1),dvec!(dvece+2) := n,p,a
       dvece := dvece + 3  $)


AND cellwithname(n) = VALOF
    $( LET x = dvece

       x := x - 3 REPEATUNTIL x=0 \/ dvec!x=n

       RESULTIS x  $)


AND scanlabels(x) BE UNLESS x=0 DO

    SWITCHON h1!x INTO
    $( CASE s.colon:
           h4!x := nextparam()
           declstat(h2!x, h4!x)

       CASE s.if: CASE s.unless: CASE s.while:
       CASE s.until: CASE s.switchon: CASE s.case:
           scanlabels(h3!x)
           ENDCASE

       CASE s.semicolonlist:
           FOR h = 2 TO h2!x+1 DO scanlabels(h!x)
           ENDCASE

       CASE s.semicolon:
           scanlabels(h3!x)

       CASE s.repeat: CASE s.repeatwhile:
       CASE s.repeatuntil: CASE s.default:
           scanlabels(h2!x)
           ENDCASE

       CASE s.test:
           scanlabels(h3!x)
           scanlabels(h4!x)
           ENDCASE
    $)


AND transdef(x) BE
    $(1 transdyndefs(x)
        IF statdefs(x) DO
           $( LET l, s= nextparam(), ssp
              compjump(l)
              transstatdefs(x)
              ssp := s
              out2(s.stack, ssp)
              complab(l)  $)1


AND transdyndefs(x) BE
    SWITCHON h1!x INTO
    $( CASE s.and:
           transdyndefs(h2!x)
           x := h3!x
           LOOP

       CASE s.vecdef:
           out2(s.llp, vecssp)
           ssp := ssp + 1
           vecssp := vecssp + 1 + evalconst(h3!x)
           BREAK

       CASE s.valdef:
           loadlist(h3!x)
           BREAK

       DEFAULT:
           BREAK

    $) REPEAT

AND transstatdefs(x) BE
$( WHILE h1!x=s.and DO
   $( transstatdefs(h2!x)
      x := h3!x
   $)

   IF h1!x=s.fndef | h1!x=s.rtdef DO
   $(2 LET a, c = dvece, dvecp
       AND bl, ll = breaklabel, looplabel
       AND rl, cb = resultlabel, caseb
       breaklabel, looplabel := -1, -1
       resultlabel, caseb := -1, -1

       compentry(h2!x, h5!x)
       ssp := savespacesize

       dvecp := dvece
       decldyn(h3!x)
       checkdistinct(a, dvece)
       decllabels(h4!x)

       out2(s.save, ssp)

       TEST h1!x=s.fndef
          THEN $( load(h4!x); out1(s.fnrn)  $)
          ELSE $( trans(h4!x); out1(s.rtrn)  $)

       out2(s.endproc, 0)

       breaklabel, looplabel := bl, ll
       resultlabel, caseb := rl, cb
       dvece, dvecp := a, c
    $)2
$)

AND statdefs(x) = h1!x=s.fndef \/ h1!x=s.rtdef -> TRUE,
                  h1!x NE s.and -> FALSE,
                  statdefs(h2!x) -> TRUE,
                  statdefs(h3!x)

.

SECTION "TRN4"

GET ""

LET jumpcond(x, b, l) BE
$(jc LET sw = b
     UNLESS smallnumber(x) SWITCHON h1!x INTO
     $( CASE s.false: b := NOT b
        CASE s.true: IF b DO compjump(l)
                     RETURN

        CASE s.not: jumpcond(h2!x, NOT b, l)
                    RETURN

        CASE s.logand: sw := NOT sw
        CASE s.logor:
         TEST sw THEN $( jumpcond(h2!x, b, l)
                         jumpcond(h3!x, b, l)  $)

                 ELSE $( LET m = nextparam()
                         jumpcond(h2!x, NOT b, m)
                         jumpcond(h3!x, b, l)
                         complab(m)  $)

         RETURN

        DEFAULT:
     $)

     load(x)
     out2(b -> s.jt, s.jf, l)
     ssp := ssp - 1
$)jc

AND transswitch(x) BE
    $(1 LET p, b, dl = casep, caseb, defaultlabel
        AND ecl = endcaselabel
        LET l = nextparam()
        endcaselabel := nextparam()
        caseb := casep

        compjump(l)
        defaultlabel := 0
        trans(h3!x)
        compjump(endcaselabel)

        complab(l)
        load(h2!x)
        IF defaultlabel=0 DO defaultlabel := endcaselabel
        out3(s.switchon, casep-p, defaultlabel)

        FOR i = caseb TO casep-1 DO out2(casek!i, casel!i)

        ssp := ssp - 1
        complab(endcaselabel)
        endcaselabel := ecl
        casep, caseb, defaultlabel := p, b, dl
    $)1

AND transfor(x) BE
     $( LET a = dvece
        LET l, m = nextparam(), nextparam()
        LET bl, ll = breaklabel, looplabel
        LET k, n = 0, 0
        LET step = 1
        LET s = ssp
        breaklabel, looplabel := 0, 0

        addname(h2!x, s.local, s)
        load(h3!x)

        k, n := s.ln, h4!x
        UNLESS smallnumber(n) TEST h1!n=s.number
            THEN n := h2!n
            ELSE $( k, n := s.lp, ssp
                    load(h4!x)  $)

        UNLESS h5!x=0 DO step := evalconst(h5!x)

        out1(s.store)
        compjump(l)
        decllabels(h6!x)
        complab(m)
        trans(h6!x)
        UNLESS looplabel=0 DO complab(looplabel)
        out2(s.lp, s); out2(s.ln, step)
        out1(s.plus); out2(s.sp, s)
        complab(l)
        TEST step > 0 THEN
          $( out2(s.lp,s)
             out2(k,n)
          $)
         ELSE
          $( out2(k,n)
             out2(s.lp,s)
          $)
        out2(s.endfor, m)

        UNLESS breaklabel=0 DO complab(breaklabel)
        breaklabel, looplabel, ssp := bl, ll, s
        out2(s.stack, ssp)
        dvece := a  $)

.

SECTION "TRN5"

GET ""

LET load(x) BE
    $(1 IF x=0 DO $( transreport(148, currentbranch)
                     loadzero()
                     RETURN  $)

        IF smallnumber(x) DO
        $( out2(s.ln, x)
           ssp := ssp + 1
           RETURN
        $)

     $( LET op = h1!x

        SWITCHON op INTO

     $( DEFAULT:
            transreport(147, currentbranch)
            loadzero()
            ENDCASE

        CASE s.byteap: op:=s.getbyte
        CASE s.div: CASE s.rem: CASE s.minus:
        CASE s.ls: CASE s.gr: CASE s.le: CASE s.ge:
        CASE s.lshift: CASE s.rshift:
            load(h2!x)
            load(h3!x)
            out1(op)
            ssp := ssp - 1
            ENDCASE

        CASE s.vecap: CASE s.mult: CASE s.plus:
        CASE s.eq: CASE s.ne: CASE s.logand:
        CASE s.logor: CASE s.eqv: CASE s.neqv:
         $( LET a, b = h2!x, h3!x
            IF smallnumber(a) |
               h1!a=s.name | h1!a=s.number DO
                               a, b := h3!x, h2!x
            load(a)
            load(b)
            IF op=s.vecap DO
              $( out1(s.plus)
                 op := s.rv $)
            out1(op)
            ssp := ssp - 1
            ENDCASE   $)

        CASE s.neg: CASE s.not: CASE s.rv: CASE s.abs:
            load(h2!x)
            out1(op)
            ENDCASE

        CASE s.true: CASE s.false: CASE s.query:
            out1(op)
            ssp := ssp + 1
            ENDCASE

        CASE s.lv:
            loadlv(h2!x)
            ENDCASE

        CASE s.number:
            out2(s.ln, h2!x)
            ssp := ssp + 1
            ENDCASE

        CASE s.string:
         $( out1(s.lstr)
            outstring(@ h2!x)
            ssp := ssp + 1
            ENDCASE   $)

        CASE s.name:
            transname(x, s.lp, s.lg, s.ll, s.ln)
            ssp := ssp + 1
            ENDCASE

        CASE s.valof:
         $( LET rl = resultlabel
            LET a = dvece
            decllabels(h2!x)
            resultlabel := nextparam()
            trans(h2!x)
            complab(resultlabel)
            out2(s.rstack, ssp)
            ssp := ssp + 1
            dvece := a
            resultlabel := rl
            ENDCASE   $)


        CASE s.fnap:
         $( LET s = ssp
            ssp := ssp + savespacesize
            out2(s.stack, ssp)
            loadlist(h3!x)
            load(h2!x)
            out2(s.fnap, s)
            ssp := s + 1
            ENDCASE   $)

        CASE s.cond:
         $( LET l, m = nextparam(), nextparam()
            LET s = ssp
            jumpcond(h2!x, FALSE, m)
            load(h3!x)
            out2(s.res,l)
            ssp := s; out2(s.stack, ssp)
            complab(m)
            load(h4!x)
            out2(s.res,l)
            complab(l)
            out2(s.rstack,s)
            ENDCASE   $)

        CASE s.table:
         $( LET m = nextparam()
            LET a = h2!x
            out2(s.lll, m)
            compdatalab(m)
            ssp := ssp + 1
            UNLESS smallnumber(a) DO
            $( LET p, n = 0, 0
               IF h1!a=s.comma DO p, n := a+1, 2
               IF h1!a=s.commalist DO p, n := a+2, h2!a
               UNLESS p=0 DO
               $( FOR h = 0 TO n-1 DO
                      out2(s.itemn, evalconst(h!p))
                  ENDCASE
               $)
            $)
            out2(s.itemn, evalconst(a))
            ENDCASE  $)
    $)1


AND loadlv(x) BE
    $(1 IF x=0 | smallnumber(x) GOTO err

        SWITCHON h1!x INTO

     $( DEFAULT:
   err:     transreport(113, currentbranch)
            loadzero()
            ENDCASE

        CASE s.name:
            transname(x, s.llp, s.llg, s.lll, 0)
            ssp := ssp + 1
            ENDCASE

        CASE s.rv:
            load(h2!x)
            ENDCASE

        CASE s.vecap:
         $( LET a, b = h2!x, h3!x
            IF smallnumber(a) | h1!a=s.name DO
               a, b := h3!x, h2!x
            load(a)
            load(b)
            out1(s.plus)
            ssp := ssp - 1
            ENDCASE   $)
    $)1

AND loadzero() BE $( out2(s.ln, 0)
                     ssp := ssp + 1  $)

AND loadlist(x) BE UNLESS x=0 DO
$( UNLESS smallnumber(x) DO
   $( LET p, n = 0, 0
      IF h1!x=s.comma DO p, n := x+1, 2
      IF h1!x=s.commalist DO p, n := x+2, h2!x
      UNLESS p=0 DO
      $( FOR h = 0 TO n-1 DO load(h!p)
         RETURN
      $)
   $)
   load(x)
$)

.

SECTION "TRN6"

GET ""

LET evalconst(x) = VALOF
$(1 LET a, b = 0, 0

    IF x=0 DO $( transreport(117, currentbranch)
                 RESULTIS 0  $)

    IF smallnumber(x) RESULTIS x

    SWITCHON h1!x INTO
 $( DEFAULT:
         transreport(118, x)
         RESULTIS 0

    CASE s.name:
      $( LET t = cellwithname(x)
         IF dvec!(t+1)=s.number RESULTIS dvec!(t+2)
         transreport(119, x)
         RESULTIS 0  $)

    CASE s.number: RESULTIS h2!x
    CASE s.true:   RESULTIS TRUE
    CASE s.query:
    CASE s.false:  RESULTIS FALSE

    CASE s.mult:   // dyadic operators
    CASE s.div:
    CASE s.rem:
    CASE s.plus:
    CASE s.minus:
    CASE s.lshift:
    CASE s.rshift:
    CASE s.logor:
    CASE s.logand:
    CASE s.eqv:
    CASE s.neqv:b := evalconst(h3!x)

    CASE s.abs:    // monadic operators
    CASE s.neg:
    CASE s.not: a := evalconst(h2!x)
 $)

    SWITCHON h1!x INTO
 $( CASE s.abs:   RESULTIS ABS a
    CASE s.neg:   RESULTIS -a
    CASE s.not:   RESULTIS ~a

    CASE s.mult:  RESULTIS a * b
    CASE s.div:   RESULTIS a / b
    CASE s.rem:   RESULTIS a REM b
    CASE s.plus:  RESULTIS a + b
    CASE s.minus: RESULTIS a - b
    CASE s.lshift:RESULTIS a << b
    CASE s.rshift:RESULTIS a >> b
    CASE s.logand:RESULTIS a & b
    CASE s.logor: RESULTIS a | b
    CASE s.eqv:   RESULTIS a EQV b
    CASE s.neqv:  RESULTIS a NEQV b
 $)
$)1


AND assign(x, y) BE
    $(1 IF x=0 | smallnumber(x) | y=0 DO
        $( transreport(110, currentbranch)
           RETURN  $)

        SWITCHON h1!x INTO
     $( CASE s.comma:
        CASE s.commalist:
            IF smallnumber(y) | h1!x\=h1!y DO
            $( transreport(112, currentbranch)
               ENDCASE
            $)

            $( LET l, n = h2, 2
               IF h1!x=s.commalist DO
               $( l, n := h3, h2!x
                  UNLESS h2!y=n DO
                  $( transreport(112, currentbranch)
                     ENDCASE
                  $)
               $)
               FOR h = l TO l+n-1 DO
                   assign(h!x, h!y)
           $)
           ENDCASE

       CASE s.name:
           load(y)
           transname(x, s.sp, s.sg, s.sl, 0)
           ssp := ssp - 1
           ENDCASE

       CASE s.byteap:
           load(y)
           load(h2!x)
           load(h3!x)
           out1(s.putbyte)
           ssp:=ssp-3
           ENDCASE

       CASE s.rv: CASE s.vecap:
           load(y)
           loadlv(x)
           out1(s.stind)
           ssp := ssp - 2
           ENDCASE

       DEFAULT:
           transreport(109, currentbranch)
    $)1


AND transname(x, p, g, l, n) BE
$(1 LET t = cellwithname(x)
    LET k, a = dvec!(t+1), dvec!(t+2)
    LET op = g

    SWITCHON k INTO
    $( DEFAULT: transreport(115, x)
                ENDCASE
       CASE s.local:  IF t-dvecp<0 DO
                         transreport(116, x)
                      op := p
       CASE s.global: ENDCASE
       CASE s.label:  op := l
                      ENDCASE
       CASE s.number: TEST n=0
                        THEN transreport(113, x)
                        ELSE op := n
    $)

    out2(op, a)
$)1

.

SECTION "TRN7"

GET ""

LET complab(l) BE out2(s.lab, l)

AND compentry(n, l) BE
    $(  LET s = @n!2
        LET t = s%0
        out3(s.entry, t, l)
        FOR i = 1 TO t DO
          $( LET c = s%i
             out1(transchars -> charcode!c, c) $)
    $)

AND compdatalab(l) BE out2(s.datalab, l)

AND compjump(l) BE out2(s.jump, l)

AND outstring(x) BE
    $( LET l = x%0
       out1(l)
       FOR i=1 TO l DO out1(x%i)
    $)

AND out1(n) BE
    $( IF n<0 DO
         $( wrc('-'); n := - n
            IF n<0 THEN
              $( LET ndiv10 = (n>>1)/5
                 wrpn(ndiv10)
                 n:=n-ndiv10*10
              $)
         $)
       wrpn(n)
       wrc('*s')  $)

AND wrpn(n) BE
    $( IF n>9 DO wrpn(n/10)
       wrc(n REM 10 + '0')  $)

AND out2(x, y) BE $( out1(x); out1(y)  $)

AND out3(x, y, z) BE $( out1(x); out1(y); out1(z)  $)

AND endocode() BE $( wrch('*N'); ocount := 0  $)

AND wrc(ch) BE
    $( ocount := ocount + 1
       IF ocount>62 & ch='*S' DO
             $( wrch('*N'); ocount := 0; RETURN  $)
       wrch(ch)  $)


