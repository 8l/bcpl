// Header file for the M68000 code-generator  December 1980
 
// Author:  M. Richards
 
// The Code Generator is based on the one written for the
// IBM Series/1 by M. Richards, which was based on the one
// for the PDP-11 at Cambridge.
 
// 3 Nov 1981:  Modified by MR to run under MC68000 TRIPOS
 
 
GET "libhdr"
 
 
 
MANIFEST
$(
//  Relocatable Object Hunks
 
    t.hunk                     = 1000
    t.reloc                    = 1001
    t.end                      = 1002
$)
 
 
 
MANIFEST
$(
    secword                    = 12345
$)
 
 
 
MANIFEST
$(
//  OCODE Keywords
 
    s.true                     = 4
    s.false                    = 5
    s.rv                       = 8
    s.fnap                     = 10
    s.mult                     = 11
    s.div                      = 12
    s.rem                      = 13
    s.plus                     = 14
    s.minus                    = 15
    s.query                    = 16
    s.neg                      = 17
    s.abs                      = 19
    s.eq                       = 20
    s.ne                       = 21
    s.ls                       = 22
    s.gr                       = 23
    s.le                       = 24
    s.ge                       = 25
    s.not                      = 30
    s.lshift                   = 31
    s.rshift                   = 32
    s.logand                   = 33
    s.logor                    = 34
    s.eqv                      = 35
    s.neqv                     = 36
    s.lp                       = 40
    s.lg                       = 41
    s.ln                       = 42
    s.lstr                     = 43
    s.ll                       = 44
    s.llp                      = 45
    s.llg                      = 46
    s.lll                      = 47
    s.needs                    = 48
    s.section                  = 49
    s.rtap                     = 51
    s.goto                     = 52
    s.finish                   = 68
    s.switchon                 = 70
    s.global                   = 76
    s.sp                       = 80
    s.sg                       = 81
    s.sl                       = 82
    s.stind                    = 83
    s.jump                     = 85
    s.jt                       = 86
    s.jf                       = 87
    s.endfor                   = 88
    s.blab                     = 89
    s.lab                      = 90
    s.stack                    = 91
    s.store                    = 92
    s.rstack                   = 93
    s.entry                    = 94
    s.save                     = 95
    s.fnrn                     = 96
    s.rtrn                     = 97
    s.res                      = 98
    s.datalab                  = 100
    s.iteml                    = 101
    s.itemn                    = 102
    s.endproc                  = 103
    s.debug                    = 109
    s.none                     = 111
    s.getbyte                  = 120
    s.putbyte                  = 121
$)
 
 
 
 
MANIFEST
$(
//  Selectors
 
    h1                         = 0
    h2                         = 1
    h3                         = 2
$)
 
 
 
 
GLOBAL $( rc            :   150
          verstream     :   152
          ocodestream   :   153
          codestream    :   154
          datvec        :   155
 
          ocodefile     :   158
          keepocode     :   159
 
          cgworksize    :   160
          naming        :   162
          callcounting  :   163
          profcounting  :   164
          stkchking     :   165
          altobj        :   167
          cg.a          :   168
          cg.b          :   169
 
          workspace     :   170
          switchspace   :   171
          tempfile      :   172
          err.p         :   173
          err.l         :   174
          cg.y          :   175
          cg.z          :   176
 
          collapse      :   179
$)
 
GLOBAL
$(
//  Global Routines
 
    addtoword                  : 180
    bswitch                    : 181
    bug                        : 182
    callcounting               : 183
    cgapply                    : 184
    cgbyteap                   : 185
    cgcmp                      : 186
    cgcondjump                 : 187
    cgitemn                    : 188
    cgdyadic                   : 189
    cgentry                    : 190
    cgerror                    : 191
    cgglobal                   : 192
    cgmove                     : 193
    cgname                     : 194
    cgpendingop                : 195
    cgreturn                   : 196
    cgrv                       : 197
    cgsave                     : 198
    cgsects                    : 199
    cgstatics                  : 200
    cgstind                    : 201
    cgstring                   : 202
    cgswitch                   : 203
    checkparam                 : 204
    checkspace                 : 205
    choosereg                  : 206
    class                      : 207
    cnop                       : 208
    code                       : 209
    code2                      : 210
    condbfn                    : 211
    dboutput                   : 212
    exta                       : 213
    extd                       : 214
    forgetall                  : 215
    forgetr                    : 216
    forgetvar                  : 217
    forgetvars                 : 218
    formea                     : 219
 
    freeblk                    : 220
    freereg                    : 221
    gen                        : 222
    genb                       : 223
    genea                      : 224
    geneaea                    : 225
    genqea                     : 226
    genmoveq                   : 227
    genrand                    : 228
    genrea                     : 229
    genr                       : 230
    genrr                      : 231
    genshkr                    : 232
    genwea                     : 233
    genwr                      : 234
    getblk                     : 235
    inforegs                   : 237
    initdatalists              : 238
    initftables                : 239
    initslave                  : 240
    initstack                  : 241
    inregs                     : 242
    insertcount                : 243
    isfree                     : 244
    isinslave                  : 245
    loadt                      : 246
    lose1                      : 247
    lswitch                    : 248
    match                      : 249
    moveinfo                   : 250
    movetoa                    : 251
    movetoanycr                : 252
    movetoanyr                 : 253
    movetoanyrsh               : 254
    movektol                   : 255
    movetor                    : 256
    nextparam                  : 257
    objword                    : 258
    outputsection              : 259
    procbase                   : 260
    rdgn                       : 261
    rdl                        : 262
    rdn                        : 263
    regscontaining             : 264
    regsinuse                  : 265
    regswithinfo               : 266
    regusedby                  : 267
    remem                      : 268
    compbfn                    : 269
    scan                       : 270
    setlab                     : 271
    stack                      : 272
    store                      : 273
    storein                    : 274
    storet                     : 275
    swapargs                   : 276
    try                        : 277
    wrkn                       : 278
 
 
    // GLOBAL Variables
 
    ea.m                       : 280
    ea.d                       : 281
    arg1                       : 282
    arg1cl                     : 283
    arg2                       : 284
    arg2cl                     : 285
    casek                      : 287
    casel                      : 288
    countflag                  : 289
    datalabel                  : 290
    debug                      : 291
    nlist                      : 292
    nliste                     : 293
    dp                         : 294
    fns.add                    : 295
    fns.and                    : 296
    fns.cmp                    : 297
    fns.eor                    : 298
    fns.or                     : 299
    fns.sub                    : 300
    fntab                      : 301
    freelist                   : 302
    incode                     : 303
    labv                       : 304
    listing                    : 305
    llist                      : 306
    maxgn                      : 308
    maxlab                     : 309
 
    maxssp                     : 310
    needslist                  : 312
    needsliste                 : 313
    numbinl                    : 314
    op                         : 316
    paramnumber                : 318
    pendingop                  : 319
    procstk                    : 320
    procstkp                   : 321
    progsize                   : 323
    rlist                      : 324
    slave                      : 325
    ssp                        : 326
    stv                        : 328
    stvp                       : 329
    tempt                      : 332
    tempv                      : 333
    traceloc                   : 334
    debugout                   : 335
$)
 
 
 
MANIFEST
$(
    swapped                    = TRUE
    notswapped                 = FALSE
 
 
    //  DATA Registers
 
    r0                         = 0
    r1                         = 1
    r2                         = 2
    r3                         = 3
    r4                         = 4
    r5                         = 5
    r6                         = 6
    r7                         = 7
 
 
    //  ADDRESS Registers
 
    rz                         = 0
    rp                         = 1
    rg                         = 2
    rl                         = 3
    rb                         = 4
    rs                         = 5
    rr                         = 6
    rsp                        = 7
 
 
    //  CLASS Bits:
    //
    //         z   q   b       w  am  cr   r  r7  r6  r5  r4  r3  r2  r1  r0
    //         0   1   2   3   4   5   6   7   8   9  10  11  12  13  14  15
 
    c.r                        = #X0100    // Item is a register
    c.cr                       = #X0200    // Value is in a register or slaved
    c.m                        = #X0400    // Alterable memory location
    c.w                        = #X0800    // Long constant
    c.b                        = #X2000    // Byte constant
    c.q                        = #X4000    // Quick constant
    c.z                        = #X8000    // Zero constant
 
    c.regs                     = #X00FF
 
 
    //  Items in Simulated Stack or Registers
 
    k.sh                       = #10
    k.lv                       = #20
 
 
    k.loc                      = #01
    k.locsh                    = k.loc + k.sh
    k.lvloc                    = k.loc + k.lv
    k.lvlocsh                  = k.loc + k.sh + k.lv
 
    k.glob                     = #02
    k.globsh                   = k.glob + k.sh
    k.lvglob                   = k.glob + k.lv
    k.lvglobsh                 = k.glob + k.sh + k.lv
 
    k.lab                      = #03
    k.labsh                    = k.lab + k.sh
    k.lvlab                    = k.lab + k.lv
    k.lvlabsh                  = k.lab + k.sh + k.lv
 
    k.notsh                    = #77 - k.sh
 
    k.numb                     = #40
    k.reg                      = #50
 
    k.ir0                      = #60
    k.ir1                      = #61
    k.ir2                      = #62
    k.ir3                      = #63
    k.ir4                      = #64
    k.ir5                      = #65
    k.ir6                      = #66
    k.ir7                      = #67
 
 
    //  GLOBAL routine numbers
 
    gn.stop                    = 2
    gn.mul                     = 3    // Temporary fix
    gn.div                     = 4    // Temporary fix
    gn.rem                     = 5    // Temporary fix
 
 
    //  Machine Code Subroutine Entry Points
 
    sr.mul                     = 32
    sr.div                     = 40
    sr.stkchk                  = 20
    sr.profile                 = 48
 
 
 
    //  M68000 Addressing Modes
 
    m.w                        = #100    //  Abs word extension bit
    m.ww                       = #200    //  Abs long extension bit
    m.l                        = #400    //  Base rel extension bit
 
    m.00                       =  #00    //  R0 register direct
    m.10                       =  #10    //  A0 register direct
    m.1l                       =  #13    //  L  register direct
    m.20                       =  #20    //  (A0)
    m.2p                       =  #21    //  P register indirect
    m.2g                       =  #22    //  G register indirect
    m.2l                       =  #23    //  (L)
    m.2s                       =  #25    //  (S) for save routine
    m.2r                       =  #26    //  (R) for return routine
    m.50                       = #150    //  w(A0)
    m.5p                       = #151    //  w(P)  local variables
    m.5g                       = #152    //  w(G)  global variables
    m.5b                       = #454    //  w(B)  static variables
    m.5s                       = #155    //  w(S)  for system subroutines
    m.6z                       = #160    //  b(Z,Ri)  for BCPL indirection
    m.6p                       = #161    //  b(P,Ri)  out of range locals
    m.6g                       = #162    //  b(G,Ti)  out of range globals
    m.6l                       = #163    //  b(L,Ri)  out of indirect ref
    m.6b                       = #164    //  b(B,Ri)  ????????????
    m.73                       = #173    //  b(PC,Ri) used in label switch
    m.74                       = #374    //  #w  Long immediate data
 
 
    //  Function Table Entries
 
    ft.qr                      = 0       //  #q,Dn
    ft.qm                      = 1       //  #q,ea
    ft.rr                      = 2       //  Dn,Dm
    ft.rm                      = 3       //  Dn,ea
    ft.ir                      = 4       //  #w,Dn
    ft.im                      = 5       //  #w,ea
    ft.mr                      = 6       //  ea,Dn
    ft.zr                      = 7       //  #0,Dn
    ft.zm                      = 8       //  #0,ea
$)
 
 
 
 
MANIFEST
$(
    //  Instructions compiled by  "geneaea( f, ms, ds, md, dd )"
 
    f.moveb                    = #X1000  //  MOVE.B    ea,ea
    f.movew                    = #X3000  //  MOVE      ea,ea
    f.movel                    = #X2000  //  MOVE.L    ea,ea
 
 
    //  Instruction compiled by  "genmoveq( r, b )"
 
    f.moveq                    = #X7000  //  MOVEQ     #q,ea
 
 
    //  Instructions compiled by  "genwea( f, w, m, d )"
 
    f.addq                     = #X5080  //  ADDQ.L    #q,ea
    f.subq                     = #X5180  //  SUBQ.L    #q,ea
 
 
    //  Instruction compiled by  "genqea( f, q, m, d )"
    //  (Doesn't appear to have any entries!)
 
 
    //  Instructions compiled by  "genrea( f, r, m, d )"
 
    f.eor                      = #XB180  //  EOR       Dn,ea
    f.lea                      = #X41C0  //  LEA       ea,An
 
 
    //  Shift Instructions
 
    f.lslkr                    = #XE188  //  LSL.L     #q,Dn
    f.lsrkr                    = #XE088  //  LSR.L     #q,Dn
    f.lslrr                    = #XE1A8  //  LSL.L     Dn,Dm
    f.lsrrr                    = #XE0A8  //  LSR.L     Dn,Dm
 
 
    //  Instructions compiled by  "genea( f, m, d )"
 
    f.clr                      = #X4280  //  CLR.L     ea
    f.jmp                      = #X4EC0  //  JMP       ea
    f.jsr                      = #X4E80  //  JSR       ea
    f.neg                      = #X4480  //  NEG.L     ea
    f.not                      = #X4680  //  NOT.L     ea
 
 
    //  Instruction compiled by  "gen( f )"
 
    f.nop                      = #X4E71  //  NOP
 
 
    //  Instructions compiled by  "genb( f, l )"
 
    f.bra                      = #X6000  //  BRA       Ln
    f.beq                      = #X6700  //  BEQ       Ln
    f.bne                      = #X6600  //  BNE       Ln
    f.blt                      = #X6D00  //  BLT       Ln
    f.bge                      = #X6C00  //  BGE       Ln
    f.ble                      = #X6F00  //  BLE       Ln
    f.bgt                      = #X6E00  //  BGT       Ln
$)
 
//.
 
 
 
 
//SECTION "M68CG1"
 
//GET "LIBHDR"
//GET "CG68HDR"
 
LET start() BE
  $( err.p, err.l := level(), stop.label
 
     workspace, switchspace, tempfile := 0,0,0
 
     writef("M68000 CG (October 1981)*N*
            *Workspace size = %N*N", cgworksize)
 
     ocodestream := findinput(ocodefile)
     IF ocodestream = 0 THEN
       $( cgerror("can't open %S", ocodefile)
          collapse(20)
       $)
 
     selectinput(ocodestream)
 
     progsize := 0
//   maxused := 0
 
     workspace := getvec(cgworksize)
 
     IF workspace = 0 THEN
       $( cgerror("can't get workspace")
          collapse(20)
       $)
 
     debugout := verstream
     traceloc, debug := cg.a, cg.b
 
     op := rdn()
 
     cgsects(workspace, cgworksize)
 
     writef("Program size = %N words*N", progsize)
//   writef("Maximum workspace used = %N words*N", maxused)
 
     collapse(0)
 
stop.label:
     RETURN
 
 
  $)
 
 
 
AND collapse(n) BE
  $( IF ocodestream \= 0 THEN
       $( endread()
          ocodestream := 0
       $)
     IF workspace \= 0 THEN
       freevec(workspace)
     IF switchspace \= 0 THEN
       freevec(switchspace)
     rc := n
     longjump(err.p, err.l)
  $)
 
 
 
AND cgsects(workvec, vecsize) BE UNTIL op=0 DO
$(1 LET p = workvec
    tempv := p
    p := p+3*100 // room for 100 SS items
    tempt := p-3 // highest legal value for ARG1
    procstk, procstkp := p, 0
    p := p+20
    slave := p  // for the slave info about R0 to R7
    p := p + 8
    dp := workvec+vecsize
    labv := p
    paramnumber := (dp-p)/10+10
    p := p+paramnumber
    FOR lp = labv TO p-1 DO !lp := -1
    stv := p
    stvp := 0
    initdatalists()
    initftables()
    initslave()
    freelist := 0
    incode := FALSE
    countflag := FALSE
    maxgn := 0
    maxlab := 0
    maxssp := 0
    procbase := 0
    datalabel := 0
    initstack(3)
    code2(0)
    TEST op=s.section
      THEN $( cgname(s.section,rdn())
              op := rdn()
           $)
      ELSE cgname(s.section,0)
    scan()
    op := rdn()
    stv!0 := stvp/4   //  size of section in words
    outputsection(op=0)
    progsize := progsize + stvp/4
 
$)1
 
 
// read in OCODE operator or argument
// argument may be of form Ln
AND rdn() = VALOF
$( LET a, sign = 0, '+'
   LET ch = 0
 
   ch := rdch() REPEATWHILE
      ch='*S' | ch='*N' | ch='L'
 
   IF ch=endstreamch RESULTIS 0
 
   IF ch='-' DO $( sign := '-'
                   ch := rdch()
                $)
 
   WHILE '0'<=ch<='9' DO $( a := 10*a + ch - '0'
                            ch := rdch()
                         $)
 
   IF sign='-' DO a := -a
   RESULTIS a
$)
 
// read in an OCODE label
AND rdl() = VALOF
$( LET l = rdn()
   IF maxlab<l DO
   $( maxlab := l
      checkparam()
   $)
   RESULTIS l
$)
 
// read in a global number
AND rdgn() = VALOF
$( LET g = rdn()
   IF maxgn<g DO maxgn := g
   RESULTIS g
$)
 
 
// generate next label parameter
AND nextparam() = VALOF
$( paramnumber := paramnumber-1
   checkparam()
   RESULTIS paramnumber
$)
 
 
AND checkparam() BE IF maxlab>=paramnumber DO
$( cgerror("TOO MANY LABELS - INCREASE WORKSPACE")
   collapse(20)
$)
 
 
AND cgerror(mess, a) BE
$( writes("*NERROR: ")
   writef(mess,a)
   newline()
$)
 
AND bug(n) BE
$( writef("COMPILER BUG %N*N", n)
   dboutput(4)
// backtrace()
   writes("Continuing ...*N")
$)
 
 
//.
 
//SECTION "M68CG2"
 
//GET "LIBHDR"
//GET "CG68HDR"
 
// initialise the simulated stack (SS)
LET initstack(n) BE
$( arg2, arg1 := tempv, tempv+3
   ssp := n
   pendingop := s.none
   h1!arg2, h2!arg2, h3!arg2 := k.loc, ssp-2, ssp-2
   h1!arg1, h2!arg1, h3!arg1 := k.loc, ssp-1, ssp-1
   IF maxssp<ssp DO maxssp := ssp
$)
 
 
// move simulated stack (SS) pointer to N
AND stack(n) BE
$(1 IF n>=ssp+4 DO
    $( store(0,ssp-1)
       initstack(n)
       RETURN
    $)
 
    WHILE n>ssp DO loadt(k.loc, ssp)
 
    UNTIL n=ssp DO
    $( IF arg2=tempv DO
       $( TEST n=ssp-1
          THEN $( ssp := n
                  h1!arg1,h2!arg1 := h1!arg2,h2!arg2
                  h3!arg1 := ssp-1
                  h1!arg2,h2!arg2 := k.loc,ssp-2
                  h3!arg2 := ssp-2
               $)
          ELSE initstack(n)
          RETURN
       $)
 
       arg1, arg2 := arg1-3, arg2-3
       ssp := ssp-1
    $)
$)1
 
 
 
// store all SS items from A to B in their true
// locations on the stack
AND store(a,b) BE
$( FOR p = tempv TO arg1 BY 3 DO
   $( LET s = h3!p
      IF s>b BREAK
      IF s>=a & h1!p>=k.reg DO storet(p)
   $)
   FOR p = tempv TO arg1 BY 3 DO
   $( LET s = h3!p
      IF s>b RETURN
      IF s>=a DO storet(p)
   $)
$)
 
 
 
AND scan() BE
 
$(1 LET l, m = ?, ?
 
    IF traceloc>=0 DO
       TEST traceloc<=stvp<=traceloc+20
       THEN debug := 10
       ELSE debug := 0
 
    IF debug>0 DO dboutput(debug)
 
    SWITCHON op INTO
 
 $(sw DEFAULT:     cgerror("BAD OP %N", op)
                   ENDCASE
 
      CASE 0:      RETURN
 
      CASE s.debug:debug := rdn() // set the debug level
                   ENDCASE
 
      CASE s.lp:   loadt(k.loc,  rdn());  ENDCASE
      CASE s.lg:   loadt(k.glob, rdgn()); ENDCASE
      CASE s.ln:   loadt(k.numb, rdn());  ENDCASE
 
      CASE s.lstr: cgstring(rdn());       ENDCASE
 
      CASE s.true: loadt(k.numb, TRUE);   ENDCASE
      CASE s.false:loadt(k.numb, FALSE);  ENDCASE
 
      CASE s.llp:  loadt(k.lvloc, rdn()); ENDCASE
      CASE s.llg:  loadt(k.lvglob,rdgn());ENDCASE
 
      CASE s.sp:   storein(k.loc, rdn()); ENDCASE
      CASE s.sg:   storein(k.glob,rdgn());ENDCASE
 
      CASE s.ll:
      CASE s.lll:
      CASE s.sl: $( LET l = rdl()
                    LET p = llist
                    UNTIL p=0 DO
                    $( IF l=h2!p BREAK
                       p := !p
                    $)
                    IF op=s.sl & p=0 DO
                    $( storein(k.lab, l)
                       ENDCASE
                    $)
                    IF op=s.lll & p=0 DO
                    $( loadt(k.lvlab, l)
                       ENDCASE
                    $)
                    IF op=s.ll TEST p=0
                    THEN $( loadt(k.lab, l)
                            ENDCASE
                         $)
                    ELSE $( loadt(k.lvlabsh, h3!p)
                            ENDCASE
                         $)
                    cgerror("Illegal use of static constant")
                    ENDCASE
                 $)
 
      CASE s.stind:cgstind();             ENDCASE
 
      CASE s.rv:   cgrv();                ENDCASE
 
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
 
      CASE s.endfor:
                   cgpendingop()
                   pendingop := s.le
                   cgcondjump(TRUE, rdl())
                   ENDCASE
 
      CASE s.jt:
      CASE s.jf:   l := rdl()
                   $( LET nextop = rdn()
 
                      IF nextop=s.jump DO
                      $( cgcondjump(op=s.jf, rdl())
                         GOTO jump
                      $)
                      cgcondjump(op=s.jt, l)
                      op := nextop
                      LOOP
                   $)
 
      CASE s.res:  cgpendingop()
                   store(0, ssp-2)
                   movetor(arg1,r1)
                   stack(ssp-1)
 
      CASE s.jump: cgpendingop()
                   store(0, ssp-1)
                   l := rdl()
 
      jump:        $( op := rdn() // deal with STACKs
                      UNLESS op=s.stack BREAK
                      stack(rdn())
                   $) REPEAT
 
                   UNLESS op=s.lab DO
                   $( genb(f.bra, l)
                      incode := FALSE
                      LOOP
                   $)
                   m := rdl()
                   UNLESS l=m DO
                   $( genb(f.bra, l)
                      incode := FALSE
                   $)
                   GOTO lab
 
      CASE s.blab: // BCPL label (for compat. with FE)
      CASE s.lab:  cgpendingop()
                   store(0, ssp-1)
                   m := rdl()
 
      lab:         setlab(m)
                   // only compile code inside
                   // procedure bodies
                   incode := procstkp>0
                   countflag := profcounting
                   forgetall()
                   ENDCASE
 
 
      CASE s.goto: cgpendingop()
                   store(0, ssp-2)
                   TEST h1!arg1=k.lvlabsh
                   THEN genb(f.bra, h2!arg1)
                   ELSE $( movetoa(rl)
                           genea(f.jmp, m.2l, 0)
                        $)
                   incode := FALSE
                   stack(ssp-1)
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
                   ENDCASE
                $)
 
      CASE s.save: IF procstkp>=20 DO
                   $( cgerror("PROC STACK OVF")
                      collapse(20)
                   $)
                   procstk!procstkp     := procbase
                   procstk!(procstkp+1) := maxssp
                   procbase := stvp
                   cgsave(rdn())
                   IF stkchking DO
                   $( genea(f.jsr,m.5s,sr.stkchk)
                      procstk!(procstkp+2) := stvp
                      code2(0)
                      maxssp := ssp
                   $)
                   procstkp := procstkp+3
                   ENDCASE
 
      CASE s.fnap:
      CASE s.rtap: cgapply(op, rdn())
                   ENDCASE
 
      CASE s.rtrn:
      CASE s.fnrn: cgreturn(op)
                   incode := FALSE
                   ENDCASE
 
      CASE s.endproc:
          $( LET n = rdn()
             procstkp := procstkp-3
             IF stkchking  DO
             $( LET p = procstk!(procstkp+2)
                FOR i = 0 TO 3 DO
                    stv%(p+i) := (@maxssp)%i
             $)
             maxssp   := procstk!(procstkp+1)
             procbase := procstk!procstkp
             IF procstkp=0 DO cgstatics()
             ENDCASE
          $)
 
      CASE s.rstack:
                   initstack(rdn())
                   loadt(k.reg, r1)
                   ENDCASE
 
      CASE s.finish:
             $( LET k = ssp
                stack(ssp+3)
                loadt(k.numb, 0)
                loadt(k.glob, gn.stop)
                cgapply(s.rtap, k)
                ENDCASE
             $)
 
      CASE s.switchon:
            $( LET n = 2 * rdn() + 1
               switchspace := getvec(n)
               IF switchspace = 0 THEN
                 $( cgerror("can't get workspace for SWITCHON")
                    collapse(20)
                 $)
               cgswitch(switchspace, n)
               freevec(switchspace)
               switchspace := 0
               ENDCASE
            $)
 
      CASE s.getbyte:
      CASE s.putbyte:
                   cgbyteap(op)
                   ENDCASE
 
      // not fully implemented yet
      CASE s.needs:cgname(s.needs,rdn())
                   ENDCASE
 
      CASE s.global: cgglobal(rdn())
                     RETURN
 
      // DATALAB is always immediately followed
      // by either (1) one or more ITEMNs
      //        or (2) one ITEML
      CASE s.datalab: datalabel := rdl()
                      ENDCASE
 
      // ITEML is always immediately preceeded by
      // a DATALAB
      CASE s.iteml:llist := getblk(llist, datalabel, rdl())
                   ENDCASE
 
      // ITEMN is always immediately preceeded by
      // a DATALAB or an ITEMN
      // CGITEMN sets DATALABEL to zero
      CASE s.itemn:cgitemn(rdn())
                   ENDCASE
 $)sw
 
    op := rdn()
 
$)1 REPEAT
 
 
//.
 
//SECTION "M68CG3"
 
//GET "LIBHDR"
//GET "CG68HDR"
 
// compiles code to deal with any pending op
LET cgpendingop() BE
 
$(1 LET pendop = pendingop
    LET f, r = ?, ?
 
    pendingop := s.none
 
    SWITCHON pendop INTO
    $(sw DEFAULT:cgerror("BAD PNDOP %N",pendop)
                 RETURN
 
         CASE s.abs:
                 r := movetoanyr(arg1)
                 loadt(k.numb, 0)
                 f := cgcmp(f.bge)
                 gen(f+2)       // BGE   *+4
                 genr(f.neg, r) // NEG.L Dr
                 lose1(k.reg, r)
                 forgetr(r)
                 RETURN
 
         CASE s.neg:
         CASE s.not:
                 r := movetoanyr(arg1)
                 genr((pendop=s.neg->f.neg,f.not), r)
                 forgetr(r)
         CASE s.none:
                 RETURN
 
 
         CASE s.eq: CASE s.ne:
         CASE s.ls: CASE s.gr:
         CASE s.le: CASE s.ge:
                 // comparisons are ARG2 <op> ARG1
              $( LET arg3 = arg2
                 loadt(h1!arg1, h2!arg1)
                 h1!arg2, h2!arg2 := h1!arg3, h2!arg3
                 h1!arg3, h2!arg3 := k.numb, FALSE
                 // select and initialise a register
                 // for the result
                 r := movetoanyr(arg3)
                 f := cgcmp(compbfn(condbfn(pendop)))
                 gen(f+2)       // Bcc   *+4
                 genr(f.not, r) // NOT.L Dr
                 forgetr(r)
                 stack(ssp-2)
                 RETURN
              $)
 
         CASE s.eqv:
         CASE s.neqv:
                 cgdyadic(fns.eor, TRUE, FALSE)
                 IF pendop=s.eqv DO
                 $( // just in case its not already in
                    // a register
                    r := movetoanyr(arg2)
                    genr(f.not, r)
                    forgetr(r)
                 $)
                 ENDCASE
 
         CASE s.minus:
                 cgdyadic(fns.sub, FALSE, FALSE)
                 ENDCASE
 
         CASE s.plus:
                 cgdyadic(fns.add, TRUE, FALSE)
                 ENDCASE
 
         CASE s.div:
         CASE s.rem:
         CASE s.mult:
//****************************************************
//start *** temporary fix until MUL DIV S/Rs are ready
         $( LET k = ssp - 2
            LET gn = gn.mul
            IF pendop=s.div DO gn := gn.div
            IF pendop=s.rem DO gn := gn.rem
            store(0, k-1)
            movetor(arg1, r2)     // left operand
            movetor(arg2, r1)     // right operand
            loadt(k.numb, 4*k)    // stack frame size
            movetor(arg1, r0)
            loadt(k.glob, gn)     // MUL DIV or REM function
            movetoa(rb)
            genea(f.jsr, m.2s, 0) // call the function
            stack(k)              // reset the stack
            loadt(k.reg, r1)
            forgetall()
            RETURN
         $)
//end ***** temporary fix until MUL DIV S/Rs are ready
//****************************************************
                 movetor(arg2, r6)
                 movetor(arg1, r7)
                 FOR r = r0 TO r5 DO freereg(r)
                 genea(f.jsr, m.5s,
                       (pendop=s.mult -> sr.mul, sr.div))
                 forgetall()
                 lose1(k.reg,
                       (pendop=s.rem  -> r2, r1))
                 ENDCASE
 
         CASE s.logor:
                 cgdyadic(fns.or, TRUE, FALSE)
                 ENDCASE
 
         CASE s.logand:
                 cgdyadic(fns.and, TRUE, FALSE)
                 ENDCASE
 
         CASE s.lshift:
         CASE s.rshift:
                 r := movetoanyr(arg2)
                 TEST h1!arg1=k.numb & 1<=h2!arg1<=8
                 THEN genshkr((pendop=s.lshift ->
                               f.lslkr,f.lsrkr), h2!arg1, r)
                 ELSE $( LET s = movetoanyr(arg1)
                         genrr((pendop=s.lshift ->
                                f.lslrr, f.lsrrr), s, r)
                      $)
                 forgetr(r)
                 ENDCASE
 
    $)sw
 
    stack(ssp-1)
    IF debug>6 DO dboutput(3)
$)1
 
 
 
//.
 
//SECTION "M68CG4"
 
//GET "LIBHDR"
//GET "CG68HDR"
 
LET cgdyadic(fns, swappable, mem2) = VALOF
 
// MEM2 is TRUE if the function is CMP or if an
// assignment is being compiled (in which case the
// function is ADD, SUB, AND or OR).  The destination
// of the assignment is represented by ARG2.
// If MEM2 is FALSE no memory location may be changed,
// and the result of the operation will be
// represented (on return) by ARG2.
 
// If SWAPPABLE is TRUE the operands may be swapped if
// there is some advantage in doing so.
 
// The result is SWAPPED if the operands were swapped,
// and NOTSWAPPED otherwise.  SSP is not altered.
// FNS is a vector of 9 elements
 
// 0  FT.QR  ADDQ SUBQ                     #q,ea   GENQEA
// 1  FT.QM  ADDQ SUBQ                     #q,ea   GENQEA
// 2  FT.RR  ADD  SUB  CMP  AND  OR  EOR   ea,Dn   GENREA
// 3  FT.RM  ADD  SUB       AND  OR  EOR   Dn,ea   GENREA
// 4  FT.IR  ADDI SUBI CMPI ANDI ORI EORI  #ww,Dn  GENWEA
// 5  FT.IM  ADDI SUBI CMPI ANDI ORI EORI  #ww,ea  GENWEA
// 6  FT.MR  ADD  SUB  CMP  AND  OR        ea,Dn   GENREA
// 7  FT.ZR            TST                         GENEA
// 8  FT.ZM            TST                         GENEA
 
// Empty entries have value -1 indicating that
// that version of the function does not
// exist.
// The register slave is updated appropriately.
$( LET drcl = c.r
   IF fns=fns.cmp DO drcl := c.cr
 
   arg1cl := class(arg1)
   IF arg1cl=0 DO
   $( movetoanycr(arg1)
      LOOP
   $)
   arg2cl := class(arg2)
   IF arg2cl=0 DO
   $( movetoanycr(arg2)
      LOOP
   $)
 
   IF arg1cl=c.m=arg2cl DO
   $( // both unslaved memory operands
      // put the source in a register
      movetoanyr(arg1)
      LOOP
   $)
 
   IF arg1cl=c.b+c.w DO
   $( // if unslaved byte sized but not quick
      // put in register
      movetoanyr(arg1)
      LOOP
   $)
 
   IF arg2cl=c.b+c.w DO
   $( // if unslaved byte sized but not quick
      // put in register
      movetoanyr(arg2)
      LOOP
   $)
 
 
   fntab := fns
 
   IF try(mem2, drcl) RESULTIS notswapped
 
   // If MEM2 is TRUE and the function is
   // ADD SUB AND OR EOR then the above call
   // of TRY will succeed.
 
   IF swappable DO
   $( swapargs()
      IF try(mem2, drcl) RESULTIS swapped
      swapargs()
   $)
 
// we have failed to compile anything this
// time round, so let us try to simplify
// the operands and try again.
 
   IF NOT swappable & NOT mem2 & (arg2cl&c.r)=0 DO
   $( // make SUB ...,Dn possible
      movetoanyr(arg2)
      LOOP
   $)
 
   UNLESS (arg2cl & c.w) = 0 DO
   $( movetoanyr(arg2)  // mem2 = FALSE
      LOOP
   $)
 
   UNLESS (arg1cl & c.w) = 0 DO
   $( movetoanyr(arg1)
      LOOP
   $)
 
   IF (arg2cl & c.r) = 0 DO
   $( movetoanyr(arg2)  // mem2 = FALSE
      LOOP
   $)
 
   IF (arg1cl & c.r) = 0 DO
   $( movetoanyr(arg1)
      LOOP
   $)
 
   bug(1)
   RESULTIS notswapped
$) REPEAT
 
// try to compile an instruction for
// ARG2 op ARG1
// the result is TRUE iff successful
// FNTAB holds the function codes for op
// ARG1CL and ARG2CL are already setup
AND try(mem2, drcl) =
    match(ft.qr,         c.q,   c.r)    |
    match(ft.rr,         c.cr,  drcl)   |
    mem2 & match(ft.qm,  c.q,   c.m)    |
    match(ft.mr,         c.m,   drcl)   |
    mem2 & match(ft.rm,  c.cr,  c.m)    |
    match(ft.zr,         c.z,   drcl)   |
    mem2 & match(ft.zm,  c.z,   c.m)    |
    // only use immediate instructions
    // if the constant is larger than a byte
    match(ft.ir,         c.w,   drcl)   |
    mem2 & match(ft.im,  c.w,   c.m)    -> TRUE, FALSE
 
// Compile an instruction if the operands match
// the required classifications CL1 and CL2 and
// the corresponding function code exists.
// If the destination is a register that is
// updated, FORGETR is called and ARG2 updated
// appropriately.
// FNTAB will contain function code variations
// for one of the following:
//    ADD  SUB  CMP  AND  OR  EOR
// The state of the register slave is updated
// if any instruction is compiled.
AND match(ft.entry, cl1, cl2) = VALOF
$( LET f = fntab!ft.entry
   LET k1, n1, k2, n2 = ?, ?, ?, ?
   LET s, r = ?, ?
 
   IF debug>5 DO
      writef("MATCH(%N,%X4, %X4) ARG1CL=%X4 ARG2CL=%X4*N",
              ft.entry, cl1, cl2, arg1cl, arg2cl)
 
   IF f=-1 |
      (arg1cl & cl1) \= cl1 |
      (arg2cl & cl2) \= cl2 RESULTIS FALSE
 
   IF cl1=c.w DO
      // check that the constant is larger than a byte
      UNLESS (arg1cl & c.b) = 0 RESULTIS FALSE
 
   // The match was successful so compile
   // an instruction.
   k1, n1 := h1!arg1, h2!arg1
   k2, n2 := h1!arg2, h2!arg2
 
   IF cl1=c.cr DO s := choosereg(arg1cl&c.regs)
   IF cl2=c.cr DO r := choosereg(arg2cl&c.regs)
   IF cl2=c.r  DO r := n2 & 7
 
   SWITCHON ft.entry INTO
   $( CASE ft.qr: // the function is ADDQ or SUBQ
           IF n1=0 ENDCASE
           IF n1<0 DO n1, f := -n1, f.addq+f.subq-f
           genqea(f, n1, m.00+r, 0)
           ENDCASE
 
      CASE ft.qm: // the function is ADDQ or SUBQ
           IF n1=0 ENDCASE
           IF n1<0 DO n1, f := -n1, f.addq+f.subq-f
           formea(k2, n2)
           genqea(f, n1, ea.m, ea.d)
           r := -1
           ENDCASE
 
      CASE ft.zr: // the function is CMP (actually TST)
           genea(f, m.00+r, 0)
           ENDCASE
 
      CASE ft.zm: // the function is CMP (actually TST)
           formea(k2, n2)
           genea(f, ea.m, ea.d)
           r := -1
           ENDCASE
 
      CASE ft.rr:
           TEST f=f.eor
           THEN genrea(f, s, m.00+r, 0)
           ELSE genrea(f, r, m.00+s, 0)
           ENDCASE
 
      CASE ft.rm:
           formea(k2, n2)
           genrea(f, s, ea.m, ea.d)
           r := -1
           ENDCASE
 
      CASE ft.ir:
           genwr(f, n1, r)
           ENDCASE
 
      CASE ft.im:
           formea(k2, n2)
           genwea(f, n1, ea.m, ea.d)
           r := -1
           ENDCASE
 
      CASE ft.mr:
           formea(k1, n1)
           genrea(f, r, ea.m, ea.d)
           ENDCASE
 
      DEFAULT: bug(5)
   $)
 
   UNLESS fntab=fns.cmp TEST r>=0
   THEN forgetr(r)
   ELSE forgetvar(k2, n2)
 
   IF debug>5 DO dboutput(3)
 
   RESULTIS TRUE
$)
 
AND swapargs() BE
$( LET k, n, cl = h1!arg1, h2!arg1, arg1cl
   h1!arg1, h2!arg1, arg1cl := h1!arg2, h2!arg2, arg2cl
   h1!arg2, h2!arg2, arg2cl := k, n, cl
$)
 
 
AND initftables() BE
$( fns.add := TABLE
#X5080,#X5080,#XD080,#XD180,#X0680,#X0680,#XD080,    -1,    -1
//  QR     QM     RR     RM     IR     IM     MR     ZR     ZM
 
   fns.sub := TABLE
#X5180,#X5180,#X9080,#X9180,#X0480,#X0480,#X9080,    -1,    -1
//  QR     QM     RR     RM     IR     IM     MR     ZR     ZM
 
   fns.cmp := TABLE
    -1,    -1,#XB080,    -1,#X0C80,#X0C80,#XB080,#X4A80,#X4A80
//  QR     QM     RR     RM     IR     IM     MR     ZR     ZM
 
   fns.and := TABLE
    -1,    -1,#XC080,#XC180,#X0280,#X0280,#XC080,    -1,    -1
//  QR     QM     RR     RM     IR     IM     MR     ZR     ZM
 
   fns.or  := TABLE
    -1,    -1,#X8080,#X8180,#X0080,#X0080,#X8080,    -1,    -1
//  QR     QM     RR     RM     IR     IM     MR     ZR     ZM
 
   fns.eor := TABLE
    -1,    -1,#XB180,#XB180,#X0A80,#X0A80,    -1,    -1,    -1
//  QR     QM     RR     RM     IR     IM     MR     ZR     ZM
 
$)
 
AND movetoanyrsh(a) = VALOF
$( LET r = -1
 
   SWITCHON h1!a INTO
   $( CASE k.loc:
      CASE k.glob:
      CASE k.lab:
      CASE k.lvloc:
      CASE k.lvglob:
      CASE k.lvlab: h1!a := h1!a + k.sh
                    ENDCASE
 
      CASE k.numb:  h2!a := h2!a * 4
                    ENDCASE
 
      DEFAULT:      r := movetoanyr(a)
                    genshkr(f.lslkr, 2, r)
                    forgetr(r)
   $)
 
   IF r<0 DO r := movetoanyr(a)
   RESULTIS r
$)
 
// Get A in a data register for use as a
// source operand.
// No data registers will change before it is used
AND movetoanycr(a) = VALOF
$( LET cl = class(a)
   LET poss = cl & c.regs
   IF poss=0 RESULTIS movetoanyr(a)
   RESULTIS choosereg(poss)
$)
 
// move a SS item into any data register
AND movetoanyr(a) = VALOF
$( LET usedregs = regsinuse()
   LET poss = ?
 
   // is A already in a register?
   IF h1!a=k.reg RESULTIS h2!a
 
   // slaved registers that are free
   poss := class(a) & c.regs & NOT usedregs
   UNLESS poss=0 RESULTIS movetor(a, choosereg(poss))
 
   // suitable regs with no info that are free
   poss := c.regs & NOT (usedregs | regswithinfo())
   UNLESS poss=0 RESULTIS movetor(a, choosereg(poss))
 
   // suitable regs that are free
   poss := c.regs & NOT usedregs
   UNLESS poss=0 RESULTIS movetor(a, choosereg(poss))
 
   // If A is of form K.IRr
   // then move it to Dr.
   IF h1!a>=k.ir0 RESULTIS movetor(a, h1!a & 7)
 
   // all registers are in use
   // so free the oldest
   FOR t = tempv TO arg1 DO
       IF regusedby(t)>=0 DO
       $( storet(t)
          BREAK
       $)
   // The situation is now better so try again
$) REPEAT
 
 
// move a SS item A into data register Dr
 
AND movetor(a,r) = VALOF
$( LET k, n = h1!a, h2!a
   LET cl = ?
 
   // is A already where required?
   IF k=k.reg & n=r RESULTIS r
 
   // free register R if necessary
   UNLESS regusedby(a)=r DO
   $( freereg(r)
      k, n := h1!a, h2!a
   $)
 
   cl := class(a)
 
   IF cl=0 SWITCHON h1!a INTO
   $( CASE k.lvlocsh:
      CASE k.lvloc: n := n-3
      CASE k.lvglobsh:
      CASE k.lvglob:n := 4*n // convert to byte address
                 $( LET oldn = H2!a
                    LET ms = m.10 + (k&7)  // (P) or (G)
                    TEST n=0
                    THEN geneaea(f.movel, ms, 0, m.00+r, 0)
                    ELSE $( h1!a, h2!a := k.numb, n
                            movetor(a, r)
                            // compile   ADD P,Dr  or   ADD G,Dr
                            genrea(fns.add!ft.mr, r, ms, 0)
                         $)
                    n := oldn  // Restore n for remem
                 $)
           shret:   IF (k&k.sh)=0 DO
                       genshkr(f.lsrkr, 2, r)
                    GOTO ret
 
      CASE k.lvlabsh:
      CASE k.lvlab: formea(k.lab, n)
                    genrea(f.lea, rl, ea.m, ea.d)
                    numbinl := 0  // value in L unknown
                    geneaea(f.movel, m.1l, 0, m.00+r, 0)
                    GOTO shret
 
      CASE k.locsh:
      CASE k.globsh:
      CASE k.labsh: h1!a := h1!a - k.sh
                    movetor(a, r)
                    genshkr(f.lslkr, 2, r)
                    GOTO ret
 
      DEFAULT:      bug(9)
 
   $)
 
   UNLESS (cl & c.cr) = 0 DO // value already in a register
   $( LET s = choosereg(cl & c.regs)
      IF (cl>>r & 1) = 0 DO
      $( // move only if necessary
         geneaea(f.movel, m.00+s, 0, m.00+r, 0)
         moveinfo(s, r)
      $)
      GOTO ret
   $)
 
   UNLESS (cl & c.b) = 0 DO  // a byte constant
   $( genmoveq(n&#XFF, r)
      GOTO ret
   $)
 
   formea(k, n)
   geneaea(f.movel, ea.m, ea.d, m.00+r, 0)
 
ret: forgetr(r)
     remem(r, k, n)
     h1!a, h2!a := k.reg, r
     RESULTIS r
$)
 
// move ARG1 to Ar
AND movetoa(r) BE
$( LET k, n, s = h1!arg1, h2!arg1, -1
   LET cl = class(arg1)
 
   UNLESS (cl & c.cr) = 0 DO // value is in a data register
      s := choosereg(cl & c.regs)
 
   IF s=-1 SWITCHON k INTO
   $( CASE k.lvlocsh:
      CASE k.lvglobsh:
                    formea(k&7, n)
                    genrea(f.lea, r, ea.m, ea.d)
                    RETURN
 
      CASE k.lvlabsh:
                    formea(k.lab, n)
                    genrea(f.lea, r, ea.m, ea.d)
                    RETURN
 
 
      CASE k.numb:  // use a D register for a byte constant
                    UNLESS (cl & c.b)=0 ENDCASE
                    formea(k.numb, n)
                    genrea(f.lea, r, ea.m, ea.d)
                    RETURN
 
      CASE k.loc:
      CASE k.glob:
      CASE k.lab:   formea(k, n)
                    geneaea(f.movel, ea.m, ea.d, m.10+r, 0)
                    RETURN
 
      DEFAULT:
 
   $)
 
   IF s=-1 DO s := movetoanycr(arg1)
 
   // compile  MOVEA.L Ds,Ar
   geneaea(f.movel, m.00+s, 0, m.10+r, 0)
$)
 
 
// find which register, if any, is used by
// an SS item
AND regusedby(a) = VALOF
$( LET k=h1!a
   IF k<k.reg RESULTIS -1
   IF k=k.reg RESULTIS h2!a
   RESULTIS k-k.ir0
$)
 
 
AND isfree(r) = VALOF
$( FOR t=tempv TO arg1 BY 3 DO
      IF regusedby(t)=r RESULTIS FALSE
   RESULTIS TRUE
$)
 
 
// Free register R by storing the SS item (if any)
// that depends on it.
AND freereg(r) BE FOR t=tempv TO arg1 BY 3 DO
                    IF regusedby(t)=r DO
                    $( storet(t)
                       BREAK
                    $)
 
 
// store the value of a SS item in its true
// stack location
// it uses CGDYADIC and preserves PENDINGOP
AND storet(a) BE UNLESS h2!a=h3!a & h1!a=k.loc DO
$( LET ak, an, s = h1!a, h2!a, h3!a
   LET pendop = pendingop
   pendingop := s.none
   h1!a, h2!a := k.loc, s
   loadt(k.loc, s)
   loadt(ak, an)
   cgmove()
   stack(ssp-2)
   pendingop := pendop
$)
 
 
// load an item (K,N) onto the SS
AND loadt(k, n) BE
$( cgpendingop()
   TEST arg1=tempt
   THEN cgerror("SIMULATED STACK OVERFLOW")
   ELSE arg1, arg2 := arg1+3, arg2+3
 
   h1!arg1,h2!arg1,h3!arg1 := k,n,ssp
   ssp := ssp + 1
   IF maxssp<ssp DO maxssp := ssp
   IF debug>6 DO dboutput(3)
$)
 
 
// replace the top two SS items by (K,N)
AND lose1(k, n) BE
$( ssp := ssp - 1
   TEST arg2=tempv
   THEN $( h1!arg2,h2!arg2 := k.loc,ssp-2
           h3!arg2 := ssp-2
        $)
   ELSE arg1, arg2 := arg1-3, arg2-3
   h1!arg1, h2!arg1, h3!arg1 := k,n,ssp-1
$)
 
 
AND cgbyteap(op) BE
$(1 cgpendingop()
 $( LET r = movetoanyrsh(arg2)
    LET i = h2!arg1
    UNLESS h1!arg1=k.numb & -128<=i<=127 DO
    $( cgdyadic(fns.add, TRUE, FALSE)
       i := 0
    $)
    stack(ssp-1)
    // just to make certain
    r := movetoanyr(arg1)
    h1!arg1, h2!arg1 := k.ir0+r, i
    // ARG1 now represents the address of the
    // byte in mode 6 addressible form.
 
    TEST op=s.getbyte
    THEN $( loadt(k.numb, 0)
            r := movetoanyr(arg1)
            formea(h1!arg2, h2!arg2)
            // byte assignment to a data register
            // does not extend the sign
            geneaea(f.moveb, ea.m, ea.d, m.00+r, 0)
            forgetr(r)
            lose1(k.reg, r)
         $)
    ELSE $( LET m, d = 0, 0
            TEST h1!arg2=k.loc | h1!arg2=k.glob
            THEN $( formea(h1!arg2, h2!arg2)
                    m, d := ea.m, ea.d + 3
                    IF m=m.2p DO m := m.5p
                    IF m=m.2g DO m := m.5g
                 $)
            ELSE m, d := m.00+movetoanycr(arg2), 0
            formea(h1!arg1, h2!arg1)
            // the address in EA.M and EA.D will not use L
            geneaea(f.moveb, m, d, ea.m, ea.d)
            forgetvars()
            stack(ssp-2)
         $)
 $)
$)1
 
// compile code to move <arg1> to <arg2>
// where <arg2> represents a memory location
AND cgmove() BE
$( LET k, n = h1!arg2, h2!arg2
   LET m, d = -1, 0
   LET cl = class(arg1)
 
   UNLESS (cl&c.cr)=0 DO
      m := m.00+choosereg(cl, c.regs)
 
   IF m=-1 & (cl&c.b)\=0 DO
   $( IF h2!arg1=0 DO
      $( // use CLR instruction
         formea(k, n)
         genea(f.clr, ea.m, ea.d)
         forgetvar(k, n)
         RETURN
      $)
      // otherwise take advantage of MOVEQ
      m := m.00+movetoanycr(arg1)
   $)
 
   IF m=-1 & (cl&c.m+c.w)\=0 THEN
      UNLESS formea(h1!arg1, h2!arg1) DO
          // provided <arg1> address does not use L
          m, d := ea.m, ea.d
 
   IF m=-1 DO m := m.00+movetoanyr(arg1)
 
   formea(k, n)
   geneaea(f.movel, m, d, ea.m, ea.d)
   forgetvar(k, n)
   IF 0<=m<=7 DO remem(m, k, n) // M is D reg direct mode
$)
 
 
AND cgstind() BE
$( cgrv()
   swapargs()
   cgmove()
   stack(ssp-2)
$)
 
 
// store the top item of the SS in (K,N)
// K is K.LOC, K.GLOB or K.LAB
AND storein(k, n) BE
$(1 LET b = (h1!arg1=k & h2!arg1=n) -> 1,
            (h1!arg2=k & h2!arg2=n) -> 2, 0
    LET pendop = pendingop
 
    IF b=0 GOTO gencase
 
    pendingop := s.none
    SWITCHON pendop INTO
 
    $(2 DEFAULT:
        gencase: pendingop := pendop
                 cgpendingop()
 
        CASE s.none:
                 loadt(k, n)
                 swapargs()
                 cgmove()
                 ENDCASE
 
        CASE s.neg:
        CASE s.not:
                 UNLESS b=1 GOTO gencase
                 formea(k, n)
                 genea((pendop=s.neg -> f.neg, f.not),
                       ea.m, ea.d)
                 forgetvar(k, n)
                 stack(ssp-1)
                 RETURN
 
        CASE s.plus:
                 IF b=1 DO swapargs()
                 cgdyadic(fns.add, FALSE, TRUE)
                 ENDCASE
 
        CASE s.minus:
                 UNLESS b=2 GOTO gencase
                 cgdyadic(fns.sub, FALSE, TRUE)
                 ENDCASE
 
        CASE s.logor:
                 IF b=1 DO swapargs()
                 cgdyadic(fns.or,  FALSE, TRUE)
                 ENDCASE
 
        CASE s.logand:
                 IF b=1 DO swapargs()
                 cgdyadic(fns.and, FALSE, TRUE)
                 ENDCASE
 
    $)2
    stack(ssp-2)
$)1
 
 
//.
 
//SECTION "M68CG5"
 
//GET "LIBHDR"
//GET "CG68HDR"
 
LET cgrv() BE
 
$(1 LET r = 0
 
    IF pendingop=s.minus & h1!arg1=k.numb DO
             pendingop, h2!arg1 := s.plus, -h2!arg1
 
    IF pendingop=s.plus &
        (h1!arg1=k.numb | h1!arg2=k.numb)
 
    THEN $( LET arg = arg2
            LET n = h2!arg1
            IF h1!arg2=k.numb DO arg, n := arg1, h2!arg2
            n := 4*n
            IF -128<=n<=127 DO
            $( pendingop := s.none
               r := movetoanyrsh(arg)
               lose1(k.ir0+r, n)
               RETURN
            $)
         $)
 
    cgpendingop()
    r := movetoanyrsh(arg1)
    h1!arg1, h2!arg1 := k.ir0+r, 0
$)1
 
 
AND cgglobal(n) BE
$( cgstatics()
   code2(0)
   FOR i = 1 TO n DO
   $( code2(rdgn())
      code2(labv!rdl())
   $)
   code2(maxgn)
$)
 
 
AND cgentry(n,l) BE
$( cnop()
   cgname(s.entry,n)
   setlab(l)
   forgetall()
   incode := TRUE
   countflag := callcounting
$)
 
 
AND cgsave(n) BE
$( FOR r = r1 TO r4 DO
   $( LET s = 3+r-r1
      IF s>=n BREAK
      remem(r, k.loc, s)
   $)
 
   initstack(n)
$)
 
 
// function or routine call
AND cgapply(op,k) BE
 
$( LET sa1 = k+3
   LET sa4 = k+6
 
   cgpendingop()
 
   // store args 5,6,...
   store(sa4+1, ssp-2)
 
   // now deal with non-args
   FOR t = tempv TO arg2 BY 3 DO
   $( IF h3!t>=k BREAK
      IF h1!t>=k.reg DO storet(t)
   $)
 
   // move args 1-4 to arg registers
   FOR t = arg2 TO tempv BY -3 DO
   $( LET s = h3!t
      LET r = s-k-2
      IF s<sa1 BREAK
      IF s<=sa4 & isfree(r) DO movetor(t,r)
   $)
   FOR t = arg2 TO tempv BY -3 DO
   $( LET s = h3!t
      LET r = s-k-2
      IF s<sa1 BREAK
      IF s<=sa4 DO movetor(t,r)
   $)
 
   // deal with args not in SS
   FOR s = sa1 TO sa4 DO
   $( LET r = s-k-2
      IF s>=h3!tempv BREAK
      IF regusedby(arg1)=r DO movetor(arg1,r7)
      loadt(k.loc,s)
      movetor(arg1,r)
      stack(ssp-1)
   $)
 
   loadt(k.numb, 4*k)
   movetor(arg1, r0) // put the stack inc in R0
   stack(ssp-1)
 
   movetoa(rb)      // MOVE <arg1>,B
   genea(f.jsr, m.2s, 0)  // JSR (S)
   forgetall()
   stack(k)
   IF op=s.fnap DO loadt(k.reg,r1)
$)
 
 
AND cgreturn(op) BE
$( cgpendingop()
   IF op=s.fnrn DO
   $( movetor(arg1,r1)
      stack(ssp-1)
   $)
   genea(f.jmp, m.2r, 0)     // JMP (R)
   initstack(ssp)
$)
 
 
// used for OCODE operators JT and JF
AND cgcondjump(b,l) BE
$(1 LET bfn = condbfn(pendingop)
    IF bfn=0 DO
    $( cgpendingop()
       loadt(k.numb,0)
       bfn := f.bne
    $)
    pendingop := s.none
    store(0,ssp-3)
    UNLESS b DO bfn := compbfn(bfn)
    bfn := cgcmp(bfn)
    genb(bfn,l)
    stack(ssp-2)
    countflag := profcounting
$)1
 
 
// Compile code to set the condition code to reflect
// the result of <arg2> rel <arg1>.
 
AND cgcmp(f) =
    cgdyadic(fns.cmp, TRUE, TRUE) = notswapped -> f,
    f=f.blt -> f.bgt,
    f=f.bgt -> f.blt,
    f=f.ble -> f.bge,
    f=f.bge -> f.ble,
    f
 
//.
 
//SECTION "M68CG6"
 
//GET "LIBHDR"
//GET "CG68HDR"
 
// compiles code for SWITCHON
// N = no. of cases
// D = default label
LET cgswitch(v,m) BE
$(1 LET n = m/2
    LET d = rdl()
    casek, casel := v-1, v+n-1
 
    // read and sort (K,L) pairs
    FOR i = 1 TO n DO
    $( LET a = rdn()
       LET l = rdl()
       LET j = i-1
       UNTIL j=0 DO
       $( IF a > casek!j BREAK
          casek!(j+1) := casek!j
          casel!(j+1) := casel!j
          j := j - 1
       $)
       casek!(j+1), casel!(j+1) := a, l
    $)
 
    cgpendingop()
    store(0, ssp-2)
    movetor(arg1,r1)
 
    // care with overflow !
    TEST 2*n-6 > casek!n/2-casek!1/2
 
    THEN lswitch(1, n, d)
 
    ELSE $( bswitch(1, n, d)
 
            genb(f.bra, d)
         $)
 
    stack(ssp-1)
$)1
 
 
// binary switch
AND bswitch(p, q, d) BE TEST q-p>6
 
      THEN $( LET m = nextparam()
              LET t = (p+q)/2
              loadt(k.numb,casek!t)
              genb(cgcmp(f.bge), m)
              stack(ssp-1)
              bswitch(p, t-1, d)
              genb(f.bra,d)
              setlab(m)
              forgetall()
              incode := TRUE
              genb(f.beq,casel!t)
              bswitch(t+1, q, d)
           $)
 
      ELSE FOR i = p TO q DO
           $( loadt(k.numb,casek!i)
              genb(cgcmp(f.beq),casel!i)
              stack(ssp-1)
           $)
 
 
 
// label vector switch
AND lswitch(p,q,d) BE
$(1 LET l = nextparam()
    LET dl = labv!d
 
    loadt(k.numb,casek!p)
    cgdyadic(fns.sub, FALSE, FALSE)
    genb(f.blt,d)
    stack(ssp-1)
 
    loadt(k.numb,casek!q-casek!p)
    genb(cgcmp(f.bgt),d)
    stack(ssp-1)
 
    genshkr(f.lslkr,1,r1)
    geneaea(f.movew,m.73,extd(r1,6),m.1l,0) // MOVE.W 6(PC,R1),L
    genea(f.jmp, m.6b, exta(rl,0))          // JMP    0(B,L)
    incode := FALSE
    // now compile the label vector table in-line
    IF dl=-1 DO dl := stvp + 2 * (casek!q-casek!p+1)
    FOR k=casek!p TO casek!q TEST casek!p=k
        THEN $( code(labv!(casel!p)-procbase)
                p := p+1
             $)
        ELSE code(dl-procbase)
$)1
 
 
AND condbfn(op) = VALOF SWITCHON op INTO
$( CASE s.eq:  RESULTIS f.beq
   CASE s.ne:  RESULTIS f.bne
   CASE s.gr:  RESULTIS f.bgt
   CASE s.le:  RESULTIS f.ble
   CASE s.ge:  RESULTIS f.bge
   CASE s.ls:  RESULTIS f.blt
   DEFAULT:    RESULTIS 0
$)
 
AND compbfn(bfn) = bfn=f.beq -> f.bne,
                   bfn=f.bne -> f.beq,
                   bfn=f.blt -> f.bge,
                   bfn=f.bge -> f.blt,
                   bfn=f.bgt -> f.ble,
                   bfn=f.ble -> f.bgt,
                   bug(4)
 
AND genb(bfn, l) BE IF incode DO
$( LET a = labv!l
 
   TEST a<0
 
   // label is unset?
   THEN $( gen(bfn)   // compile 2 word branch instruction
           rlist := getblk(rlist, stvp, l) // make ref to L
           code(-stvp)
        $)
 
   // no, the label was set
   ELSE TEST stvp-a > 127
 
        //  back jump too far for J
        THEN $( gen(bfn)   // compile 2 word branch
                code(a-stvp)
             $)
 
        // it can be a short backward jump
        ELSE gen(bfn|(a-stvp-2 & #XFF))
 
   IF bfn=f.bra DO incode := FALSE
$)
 
 
 
 
 
//.
 
//SECTION "M68CG7"
 
//GET "LIBHDR"
//GET "CG68HDR"
 
// Class bits:
//      q  b     w  m  cr r  r7 r6 r5 r4 r3 r2 r1 r0
//   0  1  2  3  4  5  6  7  8  9  10 11 12 13 14 15
 
LET class(a) = VALOF
$( LET k, n = h1!a, h2!a
// LET junk = VALOF IF debug>7 DO backtrace()
 
   LET bits = regscontaining(k, n)
 
   IF debug>5 DO
      writef("REGSCONTAINING(%N,%N) %X4*N", k, n, bits)
 
   SWITCHON k INTO
   $( DEFAULT:
   // CASE K.LVLOC:   CASE K.LOCSH:
   // CASE K.LVGLOB:  CASE K.GLOBSH:
   // CASE K.LVLAB:   CASE K.LABSH:
   // CASE K.LVLAB:
   // CASE K.LVLABSH:
                  ENDCASE
 
      CASE k.glob:
      CASE k.loc:
      CASE k.lab:
      CASE k.ir7:
      CASE k.ir6:
      CASE k.ir5:
      CASE k.ir4:
      CASE k.ir3:
      CASE k.ir2:
      CASE k.ir1:
      CASE k.ir0: bits := bits | c.m
                  ENDCASE
 
 
      CASE k.numb:IF n=0 DO          bits := bits | c.z
                  IF -8<=n<=8 DO     bits := bits | c.q
                  IF -128<=n<=127 DO bits := bits | c.b
                  bits := bits | c.w
                  ENDCASE
 
      CASE k.reg: bits := bits | c.r+c.cr
   $)
 
   IF debug>5 DO
      writef("CLASS(%N,%N) %X4*N", h1!a, h2!a, bits)
   RESULTIS bits
$)
 
AND choosereg(regs) = VALOF
$( IF debug>5 DO
      writef("CHOOSEREG(%X4)*N", regs)
   FOR r = r1 TO r7 DO
       UNLESS (regs>>r&1)=0 RESULTIS r
   IF (regs&1)=0 DO bug(5)
   RESULTIS r0
$)
 
// form effective address in EA.M and EA.D
// If the address requires an offset that will not
// fit in a 16 bit word then code is compiled to
// put a suitable value in L.  The result is TRUE
// if this was done and FORMEA may not be called
// until EA.M AND EA.D have been used.
AND formea(k, n) = VALOF
$( LET x = k & 7  // P G or D0-D7
 
   ea.d := n
 
   SWITCHON k INTO
   $( DEFAULT:     bug(8)
 
      CASE k.reg:  ea.m, ea.d := n, 0 // Dn direct
                   RESULTIS FALSE
 
      CASE k.numb: ea.m := m.74       // #w long immediate
                   RESULTIS FALSE
 
      CASE k.loc:  n    := n - 3
      CASE k.glob: ea.d := n * 4
                   UNLESS -32768<=ea.d<=32767 DO
                   $( ea.d :=  ea.d & #X00FFFFFF
                      n    := (ea.d & #X00FFFF00) + 128
                      UNLESS numbinl=n DO
                         genrea(f.lea, rl, m.74, n)
                      numbinl := n
                      ea.m := m.6l
                      ea.d := exta(x, ea.d-n)
                      RESULTIS TRUE
                   $)
                   TEST ea.d=0
                   THEN ea.m := m.20 + x // (P)  or (G)
                   ELSE ea.m := m.50 + x // w(P) or w(G)
                   RESULTIS FALSE
      CASE k.ir7:
      CASE k.ir6:
      CASE k.ir5:
      CASE k.ir4:
      CASE k.ir3:
      CASE k.ir2:
      CASE k.ir1:
      CASE k.ir0:  // it is known that -128<=N<127
                   ea.m, ea.d := m.6z, extd(x, n)  // b(Z,Ri)
                   RESULTIS FALSE
 
      CASE k.lab:  ea.m := m.5b
                   RESULTIS FALSE
   $)
$)
 
AND initslave() BE FOR r = r0 TO r7 DO slave!r := 0
 
AND forgetr(r) BE UNLESS slave!r=0 DO
$( LET a = @slave!r
   UNTIL !a = 0 DO  a := !a
   !a := freelist
   freelist := slave!r
   slave!r := 0
$)
 
AND forgetall() BE
$(  FOR r = r0 TO r7 DO forgetr(r)
    numbinl := 0  // no known value in L
$)
 
AND remem(r, k, n) BE IF k<k.reg DO
    slave!r := getblk(slave!r, k, n)
 
AND moveinfo(s, r) BE UNLESS s=r DO
$( LET p = slave!s
   forgetr(r)
   UNTIL p=0 DO
   $( remem(r, h2!p, h3!p)
      p := !p
   $)
$)
 
// Forget the slave information about the
// variable (K, N).  If K>=K.IR0 all information
// about variables are lost.
// K is one of: K.LOC, K.GLOB, K.LAB or K.IRr
AND forgetvar(k, n) BE TEST k>=k.ir0
THEN forgetvars()
ELSE FOR r = r0 TO r7 DO
$( LET a = @slave!r
 
    $( LET p = !a
      IF p=0 BREAK
      TEST h3!p=n & (h2!p & k.notsh)=k
      THEN $( !a := !p   // free and unlink the item
              freeblk(p)
           $)
      ELSE a := p
   $) REPEAT
$)
 
AND forgetvars() BE FOR r = r0 TO r7 DO
$( LET a = @slave!r
 
   $( LET p = !a
      IF p=0 BREAK
      TEST h2!p <= k.labsh
      THEN $( !a := !p   // free and unlink the item
              freeblk(p)
           $)
      ELSE a := p
   $) REPEAT
$)
 
AND regscontaining(k, n) = VALOF
$( LET regset = 0
 
   IF k=k.reg RESULTIS 1<<n | c.cr+c.r
 
   FOR r = r0 TO r7 IF isinslave(r, k, n) DO
       regset := regset | (1<<r) | c.cr
 
   RESULTIS regset
$)
 
AND inregs(r, regs) =
    r<0 | (regs>>r & 1)=0 -> FALSE, TRUE
 
AND isinslave(r, k, n) = VALOF
$( LET p = slave!r
 
   UNTIL p=0 DO
   $( IF h2!p=k & h3!p=n RESULTIS TRUE
      p := !p
   $)
 
   RESULTIS FALSE
$)
 
AND regsinuse() = VALOF
$( LET regset = 0
 
   FOR t = tempv TO arg1 BY 3 DO
       IF h1!t>=k.reg DO
       $( LET r = h1!t & 7
          IF h1!t=k.reg DO r := h2!t
          regset := regset | (1<<r)
       $)
   RESULTIS regset
$)
 
AND regswithinfo() = VALOF
$( LET regset = 0
   FOR r = r0 TO r7 DO
       UNLESS slave!r=0 DO regset := regset | (1<<r)
   RESULTIS regset
$)
 
 
AND code(a) BE
$( stv%stvp     := a>>8
   stv%(stvp+1) := a
   stvp := stvp + 2
   IF debug>0 DO
      writef("CODE: %X4*N", a)
   checkspace()
$)
 
AND code2(a) BE
$( code(a>>16)
   code(a)
$)
 
// line up on full word boundary
AND cnop() BE IF (stvp&3)=2 DO code(f.nop)
 
AND addtoword(val, a) BE
$( val := val + (stv%a<<8) + stv%(a+1)
   stv%a     := val>>8
   stv%(a+1) := val
$)
 
// functions to form index extension words
AND extd(r, d) = #X0800 + ((r&7)<<12) + (d&#XFF)
 
AND exta(r, d) = #X8800 + ((r&7)<<12) + (d&#XFF)
 
// make an operand if required
AND genrand(m, d) BE TEST (m & m.l)=0
THEN $( UNLESS (m&m.ww)=0 DO code(d>>16)
        UNLESS (m&m.w) =0 DO code(d)
     $)
ELSE $( LET val = labv!d
        IF val=-1  DO
        $( rlist := getblk(rlist, stvp, d)
           val := 0
        $)
        code(val-procbase)
     $)
 
 
// compile  single word instructions
AND gen(f) BE IF incode DO
$( insertcount()
   code(f)
$)
 
// compile  NEG ea  etc.
AND genea(f, m, d) BE IF incode DO
$( LET instr = f | (m&#77)
   insertcount()
   code(instr)
   genrand(m, d)
$)
 
// compile  MOVE.L  ea,ea  etc.
AND geneaea(f, ms, ds, md, dd) BE IF incode DO
$( LET instr = f | (ms&#77) | (md&7)<<9 | (md&#70)<<3
   insertcount()
   code(instr)
   genrand(ms, ds)
   genrand(md, dd)
$)
 
// compile  ADDQ.L  #q,ea  etc.
AND genqea(f, q, m, d) BE genrea(f, q&7, m, d)
 
// compile MOVEQ #b,Dn
AND genmoveq(b, r) BE gen(f.moveq | (r<<9) | (b&#XFF))
 
// compile  ADD.L Dn,ea   ADD.L ea,Dn  etc.
AND genrea(f, r, m, d) BE IF incode DO
$( LET instr = f | (m&#77) | (r<<9)
   insertcount()
   code(instr)
   genrand(m, d)
$)
 
// compile  SWAP Dn  etc.
AND genr(f, r) BE gen(f+r)
 
// compile  LSL Ds,Dr     etc.
AND genrr(f, s, r) BE gen(f | s<<9 | r)
 
// compile  LSL #q,Dn  etc.
AND genshkr(f, sk, r) BE genrr(f, sk&7, r)
 
// compile  ADDI.L  #w,Dr  etc.
AND genwr(f, w, r) BE genwea(f, w, m.00+r, 0)
 
// compile  ADDI.L  #w,ea  etc.
AND genwea(f, w, m, d) BE IF incode DO
$( LET instr = f | (m&#77)
   insertcount()
   code(instr)
   code2(w)
   genrand(m, d)
$)
 
 
// inserts a profile count
AND insertcount() BE IF countflag DO
$( countflag := FALSE
   cnop()
   genea(f.jsr, m.5s, sr.profile)
   code2(0)
$)
 
 
// set the label L to the current location
AND setlab(l) BE
$( LET a = @rlist
   UNLESS labv!l=-1 DO bug(9)
   labv!l := stvp
 
   // fill in forward jump refs
   // and remove them from RLIST
   UNTIL !a=0 DO
   $( LET p = !a
      TEST l = h3!p
      THEN $( addtoword(stvp, h2!p)
              !a := !p
              freeblk(p)
           $)
      ELSE a := p
   $)
$)
 
 
// compiles names for S.ENTRY, S.SECTION, S.NEEDS
AND cgname(op,n) BE
$( LET v = VEC 4
   FOR i=0 TO 4 DO v!i := 0
   v%0 := op=s.entry->7,17
   FOR i=1 TO n DO
   $( LET c = rdn()
      IF i<=7 DO v%i := c
   $)
   FOR i = n+1 TO 7 DO
       v%i := n=0->#X2A,#X20 // #X20 is ASCII '*S'
                             // #X2A is ASCII asterisk
   FOR i = 1 TO datvec%0 DO v%(i+8) := datvec%i
 
   UNLESS op=s.needs DO IF naming DO
   $( IF op=s.section DO code2(secword)
      FOR i = 0 TO op=s.entry->1,4  DO code2(v!i)
   $)
$)
 
 
AND cgstring(n) BE
$( LET w = n
   datalabel := nextparam()
   loadt(k.lvlab, datalabel)
 
   FOR i = 1 TO n|3 DO
   $( w := w<<8
      IF i<=n DO w := rdn() | w
      IF i REM 4 = 3 DO
      $( cgitemn(w)
         w := 0
      $)
   $)
$)
 
AND getblk(a, b, c) = VALOF
$( LET p = freelist
   TEST p=0
   THEN $( dp := dp-3
           p := dp
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
 
AND cgitemn(n) BE
$(  LET p = getblk(0, datalabel, n)
    datalabel := 0
    !nliste := p
    nliste := p
$)
 
// Compile static data.  It is only
// called at the outermost level
// There are no ITEML items since are regarded
// as constants so as to allow position independent
// code.  ITEML information is held on the LLIST
 
AND cgstatics() BE
$( cnop() // line up on a full word boundary
 
   UNTIL nlist=0 DO
   $( LET p = h1!nlist
      LET l = h2!nlist
      LET n = h3!nlist
      UNLESS l=0 DO setlab(l)
      code2(n)
      freeblk(nlist)
      nlist := p
   $)
 
   nliste := @nlist  // (NLIST=0 when we are finished)
$)
 
 
 
AND initdatalists() BE
$(  rlist   := 0        // for single word rel label refs
    llist   := 0        // for the DATALAB ITEML mappings
    nlist   := 0        // for ITEMNs with their labels
    nliste  := @nlist
    needslist  := 0     // list of NEEDS directives
    needsliste := @needslist
$)
 
 
AND checkspace() BE IF stv+stvp/4>dp DO
$(  cgerror("PROGRAM TOO LARGE %N WORDS COMPILED", stvp)
    writef("STV = %N, DP = %N*N", stv, dp)
    collapse(20)
$)
 
 
//.
 
//SECTION "M68CG8"
 
//GET "LIBHDR"
//GET "CG68HDR"
 
LET outputsection(last) BE
$( selectoutput(codestream)
 
   TEST altobj
   THEN $( objword(t.hunk)
           objword(stvp/4)
           FOR p=0 TO stvp/4-1 DO
           $( IF p REM 8 = 0 DO newline()
              objword(stv!p)
           $)
           IF last THEN objword(t.end)
           newline()
        $)
   ELSE $( LET hu, size, en = t.hunk, stvp/4, t.end
           writewords(@ hu, 1)
           writewords(@ size, 1)
           writewords(stv, size)
           IF last DO writewords(@ en, 1)
        $)
 
   selectoutput(verstream)
$)
 
 
 
AND objword(w) BE writef("%X8 ", w)
 
AND dboutput(lev) BE
$(1
    IF lev>3 DO
    $( LET p = rlist
       writes("*NRLIST:  ")
       UNTIL p=0 DO
       $( writef("%N:L%N ", h2!p, h3!p)
          p := !p
       $)
    $)
 
    IF lev>2 DO
    $( writes("*NSLAVE: ")
       FOR r = r0 TO r7 DO
       $( LET p = slave!r
          IF p=0 LOOP
          writef("   R%N= ", r)
          UNTIL p=0 DO
          $( wrkn(h2!p, h3!p)
             p := !p
          $)
       $)
    $)
 
    IF lev>1 DO
    $( writes("*NSTACK: ")
       FOR p=tempv TO arg1 BY 3 DO wrkn(h1!p,h2!p)
    $)
 
    writef("*NOP=%I3/%I3  SSP=%N LOC=%N*N",
           op,pendingop,ssp,stvp)
$)1
 
 
AND wrkn(k,n) BE
$(1 LET s = VALOF SWITCHON k INTO
    $( DEFAULT:          RESULTIS "?"
       CASE k.numb:      RESULTIS "N%N"
       CASE k.loc:       RESULTIS "P%N"
       CASE k.glob:      RESULTIS "G%N"
       CASE k.lab:       RESULTIS "L%N"
       CASE k.locsh:     RESULTIS "PS%N"
       CASE k.globsh:    RESULTIS "GS%N"
       CASE k.labsh:     RESULTIS "LS%N"
       CASE k.lvloc:     RESULTIS "@P%N"
       CASE k.lvglob:    RESULTIS "@G%N"
       CASE k.lvlab:     RESULTIS "@L%N"
       CASE k.lvlocsh:   RESULTIS "@PS%N"
       CASE k.lvglobsh:  RESULTIS "@GS%N"
       CASE k.lvlabsh:   RESULTIS "@LS%N"
       CASE k.reg:       RESULTIS "R%N"
       CASE k.ir0:       RESULTIS "(R0,%N)"
       CASE k.ir1:       RESULTIS "(R1,%N)"
       CASE k.ir2:       RESULTIS "(R2,%N)"
       CASE k.ir3:       RESULTIS "(R3,%N)"
       CASE k.ir4:       RESULTIS "(R4,%N)"
       CASE k.ir5:       RESULTIS "(R5,%N)"
       CASE k.ir6:       RESULTIS "(R6,%N)"
       CASE k.ir7:       RESULTIS "(R7,%N)"
    $)
    writef(s,n)
    wrch('*S')
$)1
 
 
 
 
 
 

