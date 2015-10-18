// This is an OCODE to Intcode codegenerator dated 1982 approx

//    CGHDR


GET "LIBHDR"

// OCODE OPERATORS

MANIFEST
$(    s.true          =    4
      s.false         =    5
      s.rv            =    8
      s.fnap          =   10
      s.mult          =   11
      s.div           =   12
      s.rem           =   13
      s.plus          =   14
      s.minus         =   15
      s.query         =   16
      s.neg           =   17
      s.abs           =   19
      s.eq            =   20
      s.ne            =   21
      s.ls            =   22
      s.gr            =   23
      s.le            =   24
      s.ge            =   25
      s.not           =   30
      s.lshift        =   31
      s.rshift        =   32
      s.logand        =   33
      s.logor         =   34
      s.eqv           =   35
      s.neqv          =   36
      s.cond          =   37
      s.lp            =   40
      s.lg            =   41
      s.ln            =   42
      s.lstr          =   43
      s.ll            =   44
      s.llp           =   45
      s.llg           =   46
      s.lll           =   47
      s.needs         =   48
      s.section       =   49
      s.rtap          =   51
      s.goto          =   52
      s.for           =   56
      s.return        =   67
      s.finish        =   68
      s.switchon      =   70
      s.global        =   76
      s.sp            =   80
      s.sg            =   81
      s.sl            =   82
      s.stind         =   83
      s.jump          =   85
      s.jt            =   86
      s.jf            =   87
      s.endfor        =   88
      s.lab           =   90
      s.stack         =   91
      s.store         =   92
      s.rstack        =   93
      s.entry         =   94
      s.save          =   95
      s.fnrn          =   96
      s.rtrn          =   97
      s.res           =   98
      s.reslab        =   99
      s.datalab       =  100
      s.iteml         =  101
      s.itemn         =  102
      s.endproc       =  103
      s.end           =  104
      s.char          =  105
      error           =  108
      s.debug         =  109
      s.startblock    =  110
      s.none          =  111
      s.mod           =  116
      s.getbyte       =  120
      s.putbyte       =  121
$)




// Code Generator Globals:

GLOBAL
$(  rc:                  150
    fromfile:            151
    verstream:           152
    ocodestream:         153
    codestream:          154
    datvec:              155
    err.p:               156
    err.l:               157
    ocodefile:           158
    keepocode:           159

    // CG options

    cgworksize:          160
    cglisting:           161
    naming:              162
    callcounting:        163
    profcounting:        164
    stkchking:           165
    restricted:          166
    altobj:              167
    cg.a:                168
    cg.b:                169
    cg.y:                175
    cg.z:                176
$)



MANIFEST
$(  free.global = 177
$)




GLOBAL
$(  ch:         free.global+0
    wordv:      free.global+1
    sysprint:   free.global+3
    sysin:      free.global+4
    ssp:        free.global+5
    state:      free.global+6
    ad.a:       free.global+7
    ad.k:       free.global+8
    option:     free.global+9
    datav:      free.global+10
    datap:      free.global+11
    datat:      free.global+12
    proglength: free.global+13
    linep:      free.global+14
    param:      free.global+15
    op:         free.global+16
    readop:     free.global+17
    rdn:        free.global+18
    rdl:        free.global+19
    gencode:    free.global+20
    force.nil:  free.global+21
    force.ad:   free.global+22
    force.ac:   free.global+23
    force.acad: free.global+24
    swap:       free.global+25
    load:       free.global+26
    storein:    free.global+27
    cgstring:   free.global+28
    data:       free.global+29
    nextparam:  free.global+30
    code:       free.global+31
    complab:    free.global+32
    opcode:     free.global+33
    wr:         free.global+34
    wrn:        free.global+35
    wrdata:     free.global+36
$)

MANIFEST $(
    m.n           = 0
    m.i           = 1
    m.p           = 2
    m.ip          = 3
    m.l           = 4
    m.il          = 5
    m.g           = 6
    m.ig          = 7
    f.l           = 'L'
    f.s           = 'S'
    f.a           = 'A'
    f.j           = 'J'
    f.t           = 'T'
    f.f           = 'F'
    f.k           = 'K'
    f.x           = 'X'
    f.d           = 'D'
    f.c           = 'C'
    nil           = 0
    ad            = 1
    ac            = 2
    acad          = 3
$)





.

SECTION "IC-CG1"



//    CG1


GET ""



STATIC
$(  wp = 0
    strsize = 0
$)




/*< This code reads from character format OCODE files
LET T(S) = VALOF
      $( FOR I = 0 TO STRSIZE DO UNLESS S!I=WORDV!I RESULTIS FALSE
         RESULTIS TRUE  $)

LET old.READOP() = VALOF
    $(1 LET S = VEC 20

        CH := RDCH() REPEATWHILE CH='*N' \/ CH='*S'
        WP := 0

        WHILE 'A'<=CH<='Z' DO
           $( WP := WP + 1
              S!WP := CH
              CH := RDCH()  $)

        S!0 := WP
        STRSIZE := PACKSTRING(S, WORDV)

        SWITCHON S!1 INTO
     $( DEFAULT: IF CH=ENDSTREAMCH RESULTIS S.END
                 RESULTIS ERROR

        CASE 'D':
        RESULTIS T("DATALAB") -> S.DATALAB,
                 T("DIV") -> S.DIV,
                 T("DEBUG") -> S.DEBUG, ERROR

        CASE 'E':
        RESULTIS T("EQ") -> S.EQ,
                 T("ENTRY") -> S.ENTRY,
                 T("EQV") -> S.EQV,
                 T("ENDPROC") -> S.ENDPROC,
                 T("END") -> S.END, ERROR

        CASE 'F':
        RESULTIS T("FNAP") -> S.FNAP,
                 T("FNRN") -> S.FNRN,
                 T("FALSE") -> S.FALSE,
                 T("FINISH") -> S.FINISH, ERROR


        CASE 'G':
        RESULTIS T("GOTO") -> S.GOTO,
                 T("GE") -> S.GE,
                 T("GR") -> S.GR,
                 T("GLOBAL") -> S.GLOBAL, ERROR

        CASE 'I':
        RESULTIS T("ITEMN") -> S.ITEMN,
                 T("ITEML") -> S.ITEML,  ERROR

        CASE 'J':
        RESULTIS T("JUMP") -> S.JUMP,
                 T("JF") -> S.JF,
                 T("JT") -> S.JT,  ERROR

        CASE 'L':
        IF WP=2 DO
             SWITCHON S!2 INTO
             $( DEFAULT: RESULTIS ERROR
                CASE 'E': RESULTIS S.LE
                CASE 'N': RESULTIS S.LN
                CASE 'G': RESULTIS S.LG
                CASE 'P': RESULTIS S.LP
                CASE 'L': RESULTIS S.LL
                CASE 'S': RESULTIS S.LS  $)

        RESULTIS T("LAB") -> S.LAB,
                 T("LLG") -> S.LLG,
                 T("LLL") -> S.LLL,
                 T("LLP") -> S.LLP,
                 T("LOGAND") -> S.LOGAND,
                 T("LOGOR") -> S.LOGOR,
                 T("LSHIFT") -> S.LSHIFT,
                 T("LSTR") -> S.LSTR, ERROR

        CASE 'M':
        RESULTIS T("MINUS") -> S.MINUS,
                 T("MULT") -> S.MULT, ERROR

        CASE 'N':
        RESULTIS  T("NE") -> S.NE,
                  T("NEG") -> S.NEG,
                  T("NEQV") -> S.NEQV,
                  T("NOT") -> S.NOT,  ERROR

        CASE 'P':
        RESULTIS T("PLUS") -> S.PLUS, ERROR

        CASE 'Q':
        RESULTIS T("QUERY") -> S.QUERY, ERROR

        CASE 'R':
        RESULTIS T("RES") -> S.RES,
                 T("REM") -> S.REM,
                 T("RTAP") -> S.RTAP,
                 T("RTRN") -> S.RTRN,
                 T("RSHIFT") -> S.RSHIFT,
                 T("RSTACK") -> S.RSTACK,
                 T("RV") -> S.RV, ERROR

        CASE 'S':
        RESULTIS T("SG") -> S.SG,
                 T("SP") -> S.SP,
                 T("SL") -> S.SL,
                 T("STIND") -> S.STIND,
                 T("STACK") -> S.STACK,
                 T("SAVE") -> S.SAVE,
                 T("SWITCHON") -> S.SWITCHON,
                 T("STORE") -> S.STORE, ERROR

        CASE 'T':
        RESULTIS T("TRUE") -> S.TRUE, ERROR
    $)
$)1
/*>*/




LET readop() = VALOF
// this version of READOP deals with INTEGER type OCODE
$(  LET a, neg = 0, FALSE
    ch := rdch() REPEATWHILE ch='*N' \/ ch='*S'
    TEST ch=endstreamch THEN a := s.end ELSE
    $(  IF ch='-' THEN
        $(  neg := TRUE
            ch := rdch()
        $)
        WHILE '0' LE ch LE '9' DO
        $(  a := a*10 +ch - '0'
            ch := rdch()
        $)

    $)
    RESULTIS (neg -> -a, a)
$)




AND rdn() = VALOF
$(  // reads a number from the OCODE file
    LET a, neg = 0, FALSE
    ch := rdch() REPEATWHILE ch='*N' \/ ch='*S'
    IF ch='-' THEN
    $(  neg := TRUE
        ch := rdch()
    $)
    WHILE '0' LE ch LE '9' DO
    $(  a := a*10 +ch - '0'
        ch := rdch()
    $)
    RESULTIS (neg -> -a, a)
$)




AND rdl() = VALOF
// reads an OCODE label
    $(1 LET a = 0

        ch := rdch() REPEATWHILE ch='*N' \/ ch='*S'

        IF ch='L' DO ch := rdch()

        WHILE '0' LE ch LE '9' DO
                  $( a := a*10 + ch - '0'
                     ch := rdch()  $)

        RESULTIS a   $)1






.


SECTION "IC-CG2"


//    CG2


GET ""

LET gencode() BE
$(rpt
    SWITCHON op INTO
    $(  DEFAULT:
            selectoutput(sysprint)
            writef("IC-CG: unknown OCODE number:  %N*N", op)
            selectoutput(codestream)
            ENDCASE

        CASE s.none:    CASE s.end:     CASE 0:
            RETURN

        CASE s.debug:
            selectoutput(sysprint)
            writef("IC-CG: STATE=%N, SSP=%N, AD.A=%N, AD.K=%N*N",
                            state,    ssp,    ad.a,    ad.k)
            selectoutput(codestream)
            ENDCASE

        CASE s.needs:
            wr('*N')
            writes("/ NEEDS ")
            FOR i=1 TO rdn() DO wrch(rdn())
            wr('*N')
            ENDCASE

        CASE s.lp:
            load(rdn(), m.ip)
            ENDCASE

        CASE s.lg:
            load(rdn(), m.ig)
            ENDCASE

        CASE s.ll:
            load(rdl(), m.il)
            ENDCASE

        CASE s.ln:
            load(rdn(), m.n)
            ENDCASE

        CASE s.lstr:
            cgstring(rdn())
            ENDCASE

        CASE s.true:
            load(-1, m.n)
            ENDCASE

        CASE s.false:
            load(0, m.n)
            ENDCASE

        CASE s.llp:
            load(rdn(), m.p)
            ENDCASE

        CASE s.llg:
            load(rdn(), m.g)
            ENDCASE

        CASE s.lll:
            load(rdl(), m.l)
            ENDCASE

        CASE s.sp:
            storein(rdn(), m.p)
            ENDCASE

        CASE s.sg:
            storein(rdn(), m.g)
            ENDCASE

        CASE s.sl:
            storein(rdl(), m.l)
            ENDCASE

        CASE s.stind:
            force.acad()
            code(f.s, ad.a, ad.k)
            ssp, state := ssp-2, nil
            ENDCASE

        CASE s.putbyte:
            // args on the stack are as follows:
            //         top of stack  ->  arg1
            //                           arg2
            //                           arg3
            // where the operation is  ARG2%ARG1 := ARG3
            force.nil()
            code(f.l, ssp-3, m.p)    // load address of vector on stack!
            code(f.x, opcode(s.putbyte), m.n)
            ssp := ssp-3
            state := nil
            ENDCASE

        CASE s.mult:    CASE s.div:     CASE s.rem:
        CASE s.minus:   CASE s.eq:      CASE s.ne:
        CASE s.ls:      CASE s.gr:      CASE s.le:
        CASE s.ge:      CASE s.lshift:  CASE s.rshift:
        CASE s.logand:  CASE s.logor:   CASE s.neqv:
        CASE s.eqv:     CASE s.getbyte:
            force.acad()
            code(f.l, ad.a, ad.k)
            code(f.x, opcode(op), m.n)
            state, ssp := ac, ssp-1
            ENDCASE

        CASE s.rv:      CASE s.neg:     CASE s.not:
        CASE s.abs:
            force.ac()
            code(f.x, opcode(op), m.n)
            ENDCASE

        CASE s.plus:
            force.acad()
            code(f.a, ad.a, ad.k)
            state, ssp := ac, ssp-1
            ENDCASE

        CASE s.jump:
            force.nil()
            code(f.j, rdl(), m.l)
            ENDCASE

        CASE s.jt:      CASE s.jf:
            force.ac()
            code(op=s.jt->f.t,f.f, rdl(), m.l)
            ssp, state := ssp-1, nil
            ENDCASE

        CASE s.endfor:
            // Simulate the effect of the OCODE
            //       MINUS LN 0 LE JT
            // the label follows the ENDFOR code
            force.acad()
            code(f.l, ad.a, ad.k)
            code(f.x, opcode(s.minus), m.n)
            state := ac
            ssp := ssp - 1
            load(0, m.n)
            code(f.l, ad.a, ad.k)
            code(f.x, opcode(s.le), m.n)
            code(f.t, rdl(), m.l)
            ssp := ssp - 2
            state := nil
            ENDCASE

        CASE s.goto:
            force.ad()
            code(f.j, ad.a, ad.k)
            ssp, state := ssp-1, nil
            ENDCASE

        CASE s.lab:
            force.nil()
            complab(rdl())
            ENDCASE

        CASE s.query:
            force.nil()
            ssp := ssp + 1
            ENDCASE

        CASE s.stack:
            force.nil()
            ssp := rdn()
            ENDCASE

        CASE s.store:
            force.nil()
            ENDCASE

        CASE s.entry:
            $(  LET n = rdn()
                LET l = rdl()
                wr('*N')
                wr('$')
                FOR i = 1 TO n DO rdn()
                wr(' ')
                complab(l)
                ENDCASE
            $)

        CASE s.save:
            ssp := rdn()
            ENDCASE

        CASE s.endproc:
            rdn()
            ENDCASE

        CASE s.rtap:    CASE s.fnap:
            $(  LET k = rdn()
                force.ac()
                code(f.k, k, m.n)
                TEST op=s.fnap THEN
                $(  ssp := k+1
                    state := ac
                $) ELSE
                $(  ssp := k
                    state := nil
                $)
                ENDCASE
            $)

        CASE s.fnrn:
            force.ac()
            ssp := ssp - 1
        CASE s.rtrn:
            code(f.x, opcode(s.rtrn), m.n)
            state := nil
            ENDCASE

        CASE s.res:
            force.ac()
            code(f.j, rdl(), m.l)
            ssp, state := ssp-1, nil
            ENDCASE

        CASE s.rstack:
            force.nil()
            ssp, state := rdn()+1, ac
            ENDCASE

        CASE s.finish:
            code(f.x, opcode(op), m.n)
            ENDCASE

        CASE s.switchon:
            $(  LET n = rdn()
                LET d = rdl()
                force.ac()
                code(f.x, opcode(op), m.n)
                code(f.d, n, m.n)
                code(f.d, d, m.l)
                ssp, state := ssp-1, nil
                FOR i = 1 TO n DO
                $(  code(f.d, rdn(), m.n)
                    code(f.d, rdl(), m.l)
                $)
                ENDCASE
            $)

        CASE s.global:
            wr('*N')
            FOR i = 0 TO datap-2 BY 2 DO wrdata(datav!i, datav!(i+1))
            wr('*N')
            FOR i = 1 TO rdn() DO
            $(  wr('G')
                wrn(rdn())
                wr('L')
                wrn(rdl())
                wr('*S')
            $)
            wr('*N')
            wr('Z')
            wr('*N')
            RETURN

        CASE s.datalab:
        CASE s.iteml:
            data(op, rdl())
            ENDCASE

        CASE s.itemn:
            data(op, rdn())
            ENDCASE
    $)

    op := readop()

$)rpt REPEAT







.

SECTION "IC-CG3"



//    CG3


GET ""




//
//  This code deals with the generation of INTCODE for loads and stores.
//


//  The INTCODE stack may be in one of four states (kept in STATE):
//
//     STATE = NIL
//          top of stack - (offset SSP-1) - in stack frame
//          second of stack - (offset SSP-2) - in stack frame
//          INTCODE accumulator A is empty
//          No pending load
//
//     STATE = AC
//          top of stack - (offset SSP-1) - in INTCODE register A
//          second of stack - (offset SSP-2) - in stack frame
//          No pending load
//
//     STATE = AD
//          top of stack - (offset SSP-1) - in pending load variables
//          second of stack - (offset SSP-2) - in stack frame
//          INTCODE accumulator A is empty
//
//     STATE = ACAD
//          top of stack - (offset SSP-1) - in pending load variables
//          second of stack - (offset SSP-2) - in INTCODE register A
//
//  The two variables AD.A and AD.K hold the address and address modifier
//  of a pending load.  This load will be performed when next necessary.

// LOADS are made into variables on the stack - and hence use M.IP
// STORES are made from addresses on the stack - and hence use M.P







LET force.nil() BE
// Forces NIL state - so that INTCODE register A is empty and there are
// no pending loads.
    SWITCHON state INTO
    $(  CASE acad:
            code(f.s, ssp-2, m.p)
        CASE ad:
            code(f.l, ad.a, ad.k)
        CASE ac:
            code(f.s, ssp-1, m.p)
            state := nil
        CASE nil:
    $)




AND force.ad() BE
// Forces AD state in which the variables AD.A and AD.K hold details of a
// pending load and INTCODE register A is empty.
    SWITCHON state INTO
    $(  CASE acad:
            code(f.s, ssp-2, m.p)
            GOTO l

        CASE ac:
            code(f.s, ssp-1, m.p)
        CASE nil:
            ad.a := ssp-1
            ad.k := m.ip
l:          state := ad
        CASE ad:
    $)




AND force.ac() BE
// Forces AC state in which the INTCODE register A holds the top of stack
// and there are no pending loads.
    SWITCHON state INTO
    $(  CASE nil:
            code(f.l, ssp-1, m.ip)
            GOTO l

        CASE acad:
            code(f.s, ssp-2, m.p)
        CASE ad:
            code(f.l, ad.a, ad.k)
l:          state := ac
        CASE ac:
    $)





AND force.acad() BE
// Forces state ACAD in which AD.A and AD.K hold details of the pending
// load of the top of stack and INTCODE register A holds the next of stack.
    SWITCHON state INTO
    $(  CASE ad:
            code(f.l, ssp-2, m.ip)
            GOTO l

        CASE ac:
            code(f.s, ssp-1, m.p)
        CASE nil:
            code(f.l, ssp-2, m.ip)
            ad.a := ssp-1
            ad.k := m.ip
l:          state := acad
        CASE acad:
    $)




AND swap() BE
// This procedure swaps the top two elements on the stack represented
// in state STATE and leaves the stack in state ACAD.  (with the top
// two registers pending and in the A register respectively).
$(  state := acad   // for most of them:
    SWITCHON state INTO
    $(  CASE nil:
            // load A register with the top of stack:
            code(f.l, ssp-1, m.ip)
            ENDCASE

        CASE ad:
            // Do pending load
            code(f.l, ad.a, ad.k)

        CASE ac:
            // Store A into top of stack (instead of second of stack)
            code(f.s, ssp-1, m.p)
            ENDCASE

        CASE acad:
            // We want to load the stack in the order
            //       <pending load>
            //       <intcode register A>
            // this would mean saving register A whilst it is used for
            // stacking the pending load.  However, we can save the
            // intcode register A first if we are sure that it does not
            // affect the pending load which will have to be done subsequently
            // - i.e. so long as the pending load is not from the top
            // of stack to which we will write register A.
            TEST ad.a=ssp-1 & (ad.k=m.p | ad.k=m.ip) THEN
            $(  // too bad - we'll have to save A first
                code(f.s, ssp, m.p)
                code(f.l, ad.a, ad.k)   // do pending load
                code(f.s, ssp-2, m.p)   // put in swapped position
                code(f.l, ssp, m.p)     // get A back
                state := ac
            $) ELSE
            $(  code(f.s, ssp-1, m.p)
                code(f.l, ad.a, ad.k)
                code(f.s, ssp-2, m.p)   // put back into second of stack
                state := nil
            $)
    $)
    ad.a := ssp-2      // for when STATE = AD or ACAD
    ad.k := m.ip
$)





AND load(a, k) BE
// A - the new contents of the accumulator A
// K - the kind (mode) in which the operand is to be fetched
//     (an M.<flags> constant typically)
// This procedure frees the pending load given in AD.A and AD.K (if there
// is one) and then loads A and K into them.
    SWITCHON state INTO
    $( CASE nil: state := ad
                 GOTO m

       CASE acad:
       CASE ad:  force.ac()
       CASE ac:  state := acad
       m:        ad.a, ad.k := a, k
                 ssp := ssp + 1
    $)





AND storein(a, k) BE
$(  force.ac()
    code(f.s, a, k)
    ssp, state := ssp-1, nil
$)




AND cgstring(n) BE
$(1 LET l = nextparam()
    data(s.datalab, l)
    data(s.char, n)
    FOR i = 1 TO n DO data(s.char, rdn())
    load(l, m.l)
$)1




AND data(k, v) BE
$(  LET p = datap
    datav!p, datav!(p+1) := k, v
    datap := datap + 2
    IF datap>datat THEN
    $(  selectoutput(sysprint)
        writes("IC-CG: too many constants*N")
        selectoutput(codestream)
        datap := 0
    $)
$)




AND nextparam() = VALOF
$(  param := param - 1

    IF  param < 0  THEN
    $(
        selectoutput( sysprint )
        writes( "IC-CG:  too many labels (!)*N" )
        selectoutput( codestream )

        param  :=  100  // ????
    $)

    RESULTIS param
$)





.

SECTION "IC-CG4"



//    CG4


GET ""




LET code(f, a, k) BE
// F - function = F.L  F.S  F.A  F.J  F.T  F.F  F.K  or  F.X
// A - data (D field in INTCODE)
// K - mode in which data is to be fetched, one of:
//        M.N    -  normal
//        M.I    -  indirect
//        M.IG   -  indirect global
//        M.P    -  local variable (relative to stack frame)
//        M.IP   -  indirect local
//        M.L    -  label
//        M.IL   -  indirect label
$(  wr(f)
    SWITCHON k INTO
    $( CASE m.i: wr('I')
       CASE m.n: ENDCASE

       CASE m.ig: wr('I')
       CASE m.g:  wr('G')
                  ENDCASE

       CASE m.ip: wr('I')
       CASE m.p:  wr('P'); ENDCASE

       CASE m.il: wr('I')
       CASE m.l:  wr('L'); ENDCASE  $)

    wrn(a)
    wr(' ')
    proglength := proglength + 1
$)





AND complab(n) BE
$(  // writes out an INTCODE label
    wrn(n)
    wr(' ')
$)



AND wrdata(k, n) BE
// writes out an OCODE data item in INTCODE
    SWITCHON k INTO
    $(  CASE s.datalab: complab(n); RETURN

        CASE s.itemn: code(f.d, n, m.n); RETURN

        CASE s.iteml: code(f.d, n, m.l); RETURN

        CASE s.char:  code(f.c, n, m.n); RETURN
    $)




AND opcode(op) = VALOF
// returns INTCODE number <n> in X<n> for OCODE opcode OP
    SWITCHON op INTO
    $(  CASE s.rv:    RESULTIS 1
        CASE s.neg:   RESULTIS 2
        CASE s.not:   RESULTIS 3
        CASE s.rtrn:  RESULTIS 4
        CASE s.mult:  RESULTIS 5
        CASE s.div:   RESULTIS 6
        CASE s.rem:   RESULTIS 7
        CASE s.plus:  RESULTIS 8
        CASE s.minus: RESULTIS 9
        CASE s.eq:    RESULTIS 10
        CASE s.ne:    RESULTIS 11
        CASE s.ls:    RESULTIS 12
        CASE s.ge:    RESULTIS 13
        CASE s.gr:    RESULTIS 14
        CASE s.le:    RESULTIS 15
        CASE s.lshift:RESULTIS 16
        CASE s.rshift:RESULTIS 17
        CASE s.logand:RESULTIS 18
        CASE s.logor: RESULTIS 19
        CASE s.neqv:  RESULTIS 20
        CASE s.eqv:   RESULTIS 21
        CASE s.finish:RESULTIS 22
        CASE s.switchon:RESULTIS 23
        CASE s.getbyte:RESULTIS 36
        CASE s.putbyte:RESULTIS 37
        CASE s.abs:    RESULTIS 38

        DEFAULT: selectoutput(sysprint)
                 writef("IC-CG: unknown op %N*N", op)
                 selectoutput(codestream)
                 RESULTIS 0
    $)


AND wr(ch) BE
$(  IF ch='*N' THEN
    $(  wrch('*N')
        linep := 0
        RETURN
    $)

    IF linep=71 THEN
    $(  wrch('/')
        wrch('*N')
        linep := 0
    $)
    linep := linep + 1
    wrch(ch)
$)




//AND wrn(n) BE
//$(  IF n<0 THEN
//    $(  wr('-')
//        n := -n
//    $)
//    IF n>9 DO wrn(n/10)
//    wr(n REM 10 + '0')
//$)

AND wrn (n) BE
$( LET t    = VEC 10
   LET i, k = 0, -n

   IF n<0 DO k := n
   t!i, k, i := -(k REM 10), k/10, i+1 REPEATUNTIL k=0
   IF n<0 THEN wr('-')
   FOR j = i-1 TO 0 BY -1 DO wr(t!j+'0')
$)




.


SECTION "IC-CG5"



//    CG5


GET ""





LET start() BE
$(  LET workspace = ?
    LET v = VEC 50
    writes("Intcode CG (December 1982)*N")
    err.p , err.l := level() , exit.label
    wordv := v
    sysin := input()
    sysprint := output()

    ocodestream := findinput(ocodefile)
    IF ocodestream = 0 THEN
    $(  writef("IC-CG: Can't open *"%S*"*N", ocodefile)
        exit(20)
    $)

    workspace := getvec(cgworksize)
    TEST workspace=0 THEN
    $(  writef("IC-CG: Can't get %N words for CG workspace*N", cgworksize)
        exit(20)
    $) ELSE
    $(  datav := workspace
        datat := cgworksize
    $)

    proglength := 0

    selectinput(ocodestream)
    selectoutput(codestream)

    $(rpt
        op := readop()
        IF op=s.section THEN
        $(  wr('*N')
            writes("/ SECTION ")
            FOR i=1 TO rdn() DO wrch(rdn())
            wr('*N')
            op := readop()
        $)
        ssp, state := 2, nil
        datap, linep,  param := 0, 0, 1000
        gencode()
    $)rpt REPEATUNTIL op=s.end

    selectoutput(sysprint)
    writef("Program size = %N words*N", proglength)
    exit(0)

exit.label:
    RETURN
$)



AND exit(n) BE
$(  UNLESS ocodestream=0 THEN
    $(  selectinput(ocodestream)
        endread()
        ocodestream := 0
    $)
    selectinput(sysin)
    selectoutput(sysprint)

    UNLESS datav=0 THEN freevec(datav)

    rc := n

    longjump(err.p, err.l)
$)

