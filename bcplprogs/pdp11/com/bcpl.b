// (C) Copyright 1979 Tripos Research Group
//     University of Cambridge
//     Computer Laboratory

GET "LIBHDR"

GLOBAL
$(
rc:150
fromfile:151
verstream:152
ocodestream:153
codestream:154
datvec:155
err.p:156
err.l:157
ocodefile:158
keepocode:159

// CG options
cgworksize:160
cglisting:161
naming:162
callcounting:163
profcounting:164
stkchking:165
restricted:166
altobj:167
cg.a:168
cg.b:169
cg.y:175
cg.z:176

// SYN - TRN globals
treesize:180
declsize:181
printtree:182
charcode:183
transchars:184
savespacesize:185
sourcestream:186
ch:187
linecount:188
reportcount:189
errcount:190
errvec:191
treep:192
treeq:193
treevec:194
zeronode:195
smallnumber:196

printplist:200
$)

MANIFEST
$(
reportmax=10
$)

.

SECTION "BCPL"

GET ""

LET start() BE
 $( LET args = "SYS:L.BCPL-ARGS"
    LET syn  = "SYS:L.BCPL-SYN"
    LET trn  = "SYS:L.BCPL-TRN"
    LET err  = "SYS:L.BCPL-ERR"
    LET cg = 0
    LET oldoutput = output()
    LET v1 = VEC 3*reportmax
    LET v2 = VEC 14

    errvec := v1
    datvec := v2
    fromfile := 0
    ocodefile := 0

    cg := callbcplseg(args)
    UNLESS rc=0 GOTO fail

    UNLESS sourcestream=0 DO
    $( $( LET a = callbcplseg(syn)
          IF a=0 BREAK
          IF printtree DO callbcplseg(err, a)
          callbcplseg(trn, a)
          IF errcount>0 DO callbcplseg(err, 0)
       $) REPEATUNTIL ch=endstreamch | rc>=20

       endread()
       selectoutput(ocodestream)
       endwrite()
       ocodestream := 0
       selectoutput(verstream)
       freevec(treevec)
       UNLESS charcode=0 DO freevec(charcode)
    $)


    UNLESS codestream=0 DO
    $( IF rc=0 DO callbcplseg(cg)
       selectoutput(codestream)
       endwrite()
       selectoutput(verstream)
    $)

    UNLESS verstream=oldoutput DO endwrite()
fail:
    UNLESS fromfile=0 DO freevec(fromfile)
    UNLESS ocodefile=0 DO
    $( UNLESS keepocode DO deleteobj(ocodefile)
       freevec(ocodefile)
    $)
    UNLESS cg=0 DO freevec(cg)
    stop(rc)
 $)


AND callbcplseg(s, a) = VALOF
$( let overseg = loadseg(s)
   IF overseg=0 | globin(overseg)=0 DO
   $( writef("Can't load %S*N",s)
      rc := 20
      RESULTIS 0 $)
   a := start(a)
   unloadseg(overseg)
   RESULTIS a
$)

AND smallnumber(x) =  0<x<256 -> TRUE, FALSE


