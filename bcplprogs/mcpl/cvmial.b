SECTION "cvmial"

GET "libhdr"

MANIFEST $(
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

$)

GLOBAL $(
mialin:   200
asmout:   201
stdin:    202
stdout:   203

rdf:      210
rdp:      211
rdg:      212
rdk:      213
rdw:      215
rdl:      216
rdc:      218
rdcode:   219

pval:     220
gval:     221
kval:     222
wval:     224
lval:     225
mval:     226

scan:     230
cvf:      231
cvfp:     232
cvfg:     233
cvfk:     234
cvfw:     236
cvfl:     237

modname:  250
modletter:251
charv:    252
labnumber:253
$)

LET start() = VALOF
$( LET argv = VEC 20
   LET v    = VEC 20
   LET cv   = VEC 256/bytesperword

   modname := v
   modname%0 := 0
   modletter := 'A'
   charv := cv
   labnumber := 0

   asmout := 0
   stdout := output()
   IF rdargs("FROM,TO/K", argv, 20)=0 DO
   $( writes("Bad args for cvmial*n")
      RESULTIS 20
   $)
   IF argv!0=0 DO argv!0 := "MIAL"
   IF argv!1=0 DO argv!1 := "**"
   mialin := findinput(argv!0)
   IF mialin=0 DO
   $( writef("Trouble with file %s*n", argv!0)
      RESULTIS 20
   $)
   asmout := findoutput(argv!1)
   
   IF asmout=0 DO
   $( writef("Trouble with file %s*n", argv!1)
      RESULTIS 20
   $)
   
   selectinput(mialin)
   selectoutput(asmout)

   scan()
   endread()
   UNLESS asmout=stdout DO endwrite()
   selectoutput(stdout)

   RESULTIS 0
$)

AND nextlab() = VALOF
{ labnumber := labnumber+1
  RESULTIS labnumber
}

// argument may be of form Ln
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
AND rdp() = VALOF { pval := rdcode('P'); RESULTIS pval }
AND rdg() = VALOF { gval := rdcode('G'); RESULTIS gval }
AND rdk() = VALOF { kval := rdcode('K'); RESULTIS kval }
AND rdw() = VALOF { wval := rdcode('W'); RESULTIS wval }
AND rdl() = VALOF { lval := rdcode('L'); RESULTIS lval }
AND rdm() = VALOF { mval := rdcode('M'); RESULTIS mval }
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

AND scan() BE
$( LET op = rdf()

   SWITCHON op INTO

   $( DEFAULT:       error("# Bad op %n*n", op); LOOP

      CASE -1:       RETURN
      
      CASE f_lp:     cvfp("LP") // a := P!n
                     ENDCASE
      CASE f_lg:     cvfg("LG") // a := G!n
                     ENDCASE
      CASE f_ll:     cvfl("LL") // a := !Ln
                     ENDCASE

      CASE f_llp:    cvfp("LLP") // a := @ P!n
                     ENDCASE
      CASE f_llg:    cvfg("LLG") // a := @ G!n
                     ENDCASE
      CASE f_lll:    cvfl("LLL") // a := @ !Ln
                     ENDCASE
      CASE f_lf:     cvfl("LF") // a := byte address of Ln
                     ENDCASE
      CASE f_l:      cvfk("L") // a := n
                     ENDCASE
      CASE f_lm:     cvfk("LM") // a := -n
                     ENDCASE
      CASE f_lw:     cvfm("LW")
                     ENDCASE

      CASE f_sp:     cvfp("SP") // P!n := a
                     ENDCASE
      CASE f_sg:     cvfg("SG") // G!n := a
                     ENDCASE
      CASE f_sl:     cvfl("SL") // !Ln := a
                     ENDCASE

      CASE f_ap:     cvfp("AP") // a := a + P!n
                     ENDCASE
      CASE f_ag:     cvfg("AG") // a := a + G!n
                     ENDCASE
      CASE f_a:      cvfk("A") // a := a + n
                     ENDCASE
      CASE f_s:      cvfk("S")  // a := a - n
                     ENDCASE

      CASE f_lkp:    cvfkp("LKP") // a := P!n!k
                     ENDCASE
      CASE f_lkg:    cvfkg("LKG") // a := G!n!k
                     ENDCASE
      CASE f_rv:     cvf("RV")  // a := ! a
                     ENDCASE
      CASE f_rvp:    cvfp("RVP") // a := P!n!a
                     ENDCASE
      CASE f_rvk:    cvfk("RVK") // a := a!k
                     ENDCASE
      CASE f_st:     cvf("ST") // !a := b
                     ENDCASE
      CASE f_stp:    cvfp("STP") // P!n!a := b
                     ENDCASE
      CASE f_stk:    cvfk("STK") // a!n := b
                     ENDCASE
      CASE f_stkp:   cvfkp("STKP")  // P!n!k := a
                     ENDCASE
      CASE f_stkg:   cvfkg("STKG") // G!n!k := a
                     ENDCASE
      CASE f_xst:    cvf("XST") // !b := a
                     ENDCASE

      CASE f_stb:    cvf("STB") // %b := a
                     ENDCASE

      CASE f_lvind:  cvf("LVIND") // a := @ b!a
                     ENDCASE

      CASE f_indb:   cvf("INDB") // a := b % a
                     ENDCASE

      CASE f_indb0:  cvf("INDB") // a := % a
                     ENDCASE

      CASE f_indw:   cvf("INDW") // a := b!a
                     ENDCASE

      CASE f_k:      cvfp("K") // Call  a(b,...) incrementing P by n
                     ENDCASE
      CASE f_kpg:    cvfpg("KPG") // Call Gg(a,...) incrementing P by n
                     ENDCASE

      CASE f_neg:    cvf("NEG") // a := - a
                     ENDCASE
      CASE f_not:    cvf("NOT") // a := ~ a
                     ENDCASE
      CASE f_abs:    cvf("ABS") // a := ABS a
                     ENDCASE

      CASE f_xdiv:   cvf("XDIV") // a := a / b
                     ENDCASE
      CASE f_xmod:   cvf("XMOD") // a := a MOD b
                     ENDCASE
      CASE f_xsub:   cvf("XSUB") // a := a - b
                     ENDCASE

      CASE f_mul:    cvf("MUL") // a := b * a; c := ?
                     ENDCASE
      CASE f_div:    cvf("DIV")  // a := b / a; c := ?
                     ENDCASE
      CASE f_mod:    cvf("MOD") // a := b MOD a; c := ?
                     ENDCASE
      CASE f_add:    cvf("ADD") // a := b + a
                     ENDCASE
      CASE f_sub:    cvf("SUB") // a := b - a
                     ENDCASE

      CASE f_eq:     cvf("EQ") // a := b = a
                     ENDCASE
      CASE f_ne:     cvf("NE") // a := b ~= a
                     ENDCASE
      CASE f_ls:     cvf("LS") // a := b < a
                     ENDCASE
      CASE f_gr:     cvf("GR") // a := b > a
                     ENDCASE
      CASE f_le:     cvf("LE") // a := b <= a
                     ENDCASE
      CASE f_ge:     cvf("GE") // a := b >= a
                     ENDCASE

      CASE f_eq0:    cvf("EQ0") // a := a = 0
                     ENDCASE
      CASE f_ne0:    cvf("NE0") // a := a ~= 0
                     ENDCASE
      CASE f_ls0:    cvf("LS0") // a := a < 0
                     ENDCASE
      CASE f_gr0:    cvf("GR0") // a := a > 0
                     ENDCASE
      CASE f_le0:    cvf("LE0") // a := a <= 0
                     ENDCASE
      CASE f_ge0:    cvf("GE0") // a := a >= 0
                     ENDCASE

      CASE f_lsh:    cvf("LSH") // a := b << a
                     ENDCASE
      CASE f_lshk:   cvfk("LSHK") // a := a << k 
                     ENDCASE
      CASE f_rsh:    cvf("RSH") // a := b >> a 
                     ENDCASE
      CASE f_rshk:   cvfk("RSHK") // a := a >> k 
                     ENDCASE
      CASE f_and:    cvf("AND") // a := b & a 
                     ENDCASE
      CASE f_or:     cvf("OR") // a := b | a 
                     ENDCASE
      CASE f_xor:    cvf("XOR") // a := b XOR a
                     ENDCASE

      CASE f_xch:    cvf("XCH") // swap a and b
                     ENDCASE
      CASE f_atb:    cvf("ATB") // b := a
                     ENDCASE
      CASE f_atc:    cvf("ATC") // c := a
                     ENDCASE
      CASE f_cta:    cvf("CTA") // a := c
                     ENDCASE
      CASE f_bta:    cvf("BTA") // a := b
                     ENDCASE
      CASE f_btc:    cvf("BTC") // c := b
                     ENDCASE
      CASE f_atblp:  cvfp("ATBLP") // b := a; a := P!n
                     ENDCASE
      CASE f_atblg:  cvfg("ATBLG") // b := a; a := G!n
                     ENDCASE
      CASE f_atbl:   cvfk("ATBL") // b := a; a := k
                     ENDCASE

      CASE f_j:      cvfl("J") // jump to Ln
                     ENDCASE
      CASE f_rtn:    cvf("RTN") // procedure return
                     ENDCASE

      CASE f_ikp:    cvfkp("IKP") // a := P!n + k; P!n := a
                     ENDCASE
      CASE f_ikg:    cvfkg("IKG") // a := G!n + k; G!n := a
                     ENDCASE
      CASE f_ikl:    cvfkl("IKL") // a := !Ln + k; !Ln := a
                     ENDCASE
      CASE f_ip:     cvfp("IP") // a := P!n + a; P!n := a
                     ENDCASE
      CASE f_ig:     cvfg("IG") // a := G!n + a; G!n := a
                     ENDCASE
      CASE f_il:     cvfl("IL") // a := !Ln + a; !Ln := a
                     ENDCASE

      CASE f_jeq:    cvfl("JEQ") // Jump to Ln if b = a
                     ENDCASE
      CASE f_jne:    cvfl("JNE") // Jump to Ln if b ~= a
                     ENDCASE
      CASE f_jls:    cvfl("JLS") // Jump to Ln if b < a
                     ENDCASE
      CASE f_jgr:    cvfl("JGR") // Jump to Ln if b > a
                     ENDCASE
      CASE f_jle:    cvfl("JLE") // Jump to Ln if b <= a
                     ENDCASE
      CASE f_jge:    cvfl("JGE") // Jump to Ln if b >= a
                     ENDCASE

      CASE f_jeq0:   cvfl("JEQ0") // Jump to Ln if a = 0
                     ENDCASE
      CASE f_jne0:   cvfl("JNE0") // Jump to Ln if a ~= 0
                     ENDCASE
      CASE f_jls0:   cvfl("JLS0") // Jump to Ln if a < 0
                     ENDCASE
      CASE f_jgr0:   cvfl("JGR0") // Jump to Ln if a > 0
                     ENDCASE
      CASE f_jle0:   cvfl("JLE0") // Jump to Ln if a <= 0
                     ENDCASE
      CASE f_jge0:   cvfl("JGE0") // Jump to Ln if a >= 0
                     ENDCASE

      // The following five opcodes are never generated by
      // the BCPL compiler
      CASE f_brk:    cvf("BRK") // Breakpoint instruction
                     ENDCASE
      CASE f_nop:    cvf("NOP") // No operation
                     ENDCASE
      CASE f_chgco:  cvf("CHGCO") // Change coroutine
                     ENDCASE
      CASE f_mdiv:   cvf("MDIV") // a := Muldiv(P!3, P!4, P!5) 
                     ENDCASE
      CASE f_sys:    cvf("SYS") // System function
                     ENDCASE

      CASE f_module:   cvfs("MODULE") // Name of section
                       FOR i = 0 TO charv%0 DO modname%i := charv%i
                       ENDCASE
      CASE f_modstart: cvf("MODSTART") // Start of module  
                       modname%0 := 0
                       ENDCASE
      CASE f_modend:   cvf("MODEND") // End of module 
                       modletter := modletter+1
                       ENDCASE
      CASE f_global:   cvglobal() // Global initialisation data
                       ENDCASE
      CASE f_const:    cvconst() // Large integer constant
                       ENDCASE
      CASE f_lab:      cvfl("LAB") // Program label
                       ENDCASE
      CASE f_entry:    cventry() // Start of a function
                       ENDCASE

      CASE f_dlab:     cvfl("DLAB") // Static data label
                       ENDCASE
      CASE f_dw:       cvfw("DW") // Static data word
                       ENDCASE
      CASE f_db:       cvfk("DB") // Static data byte
                       ENDCASE
      CASE f_dl:       cvfl("DL") // Static data word pointer
                       ENDCASE
      CASE f_ds:       cvfk("DS") // Static data space
                       ENDCASE

      CASE f_inc1b:    cvf("INC1B")   // a := ++(!a)
                       ENDCASE
      CASE f_inc4b:    cvf("INC4B")   // a := +++(!a)
                       ENDCASE
      CASE f_dec1b:    cvf("DEC1B")   // a := --(!a)
                       ENDCASE
      CASE f_dec4b:    cvf("DEC4B")   // a := ---(!a)
                       ENDCASE
      CASE f_inc1a:    cvf("INC1A")   // a := (!a)++
                       ENDCASE
      CASE f_inc4a:    cvf("INC4A")   // a := (!a)+++
                       ENDCASE
      CASE f_dec1a:    cvf("DEC1A")   // a := (!a)--
                       ENDCASE
      CASE f_dec4a:    cvf("DEC4A")   // a := (!a)---
                       ENDCASE

      CASE f_unh:      cvf("UNH")   // h := h!1
                       ENDCASE

      CASE f_hand:     cvfl("HAND") // a!0, a!1, a!2 := P, H, Ln
                                    // H := a
                       ENDCASE

      CASE f_raise:    cvf("RAISE") // LET p,h,l := H!0, H!1, H!2
                                    // H!0, H!1, H!2 := a, b, c
                                    // P, H := p, h
                                    // GOTO l
                       ENDCASE

   $)

   newline()
$) REPEAT

AND cvf(s)   BE writef("%s", s)
AND cvfp(s)  BE writef("%t7 P%n", s, rdp())
AND cvfkp(s) BE writef("%t7 K%n P%n", s, rdk(), rdp())
AND cvfg(s)  BE writef("%t7 G%n", s, rdg())
AND cvfkg(s) BE writef("%t7 K%n G%n", s, rdk(), rdg())
AND cvfkl(s) BE writef("%t7 K%n L%n", s, rdk(), rdl())
AND cvfpg(s) BE writef("%t7 P%n G%n", s, rdp(), rdg())
AND cvfk(s)  BE writef("%t7 K%n", s, rdk())
AND cvfw(s)  BE writef("%t7 W%n", s, rdw())
AND cvfl(s)  BE writef("%t7 L%n", s, rdl())
AND cvfm(s)  BE writef("%t7 M%n", s, rdm())

AND cvglobal() BE
$( LET n = rdk()
   writef("GLOBAL K%n*n", n)
   IF modname%0=0 FOR i = 0 TO 4 DO modname%i := "prog"%i
   FOR i = 1 TO n DO
   $( LET g = rdg()
      LET n = rdl()
      writef("G%n L%n*n", g, n)
   $)
   writef("G%n", rdg())
$)

AND rdchars() = VALOF
{ LET n = rdk()
  charv%0 := n
  FOR i = 1 TO n DO charv%i := rdc()
  RESULTIS n
}

AND cvconst() BE
$( LET lab = rdm()
   LET w = rdw()
   writef("CONST   M%n W%n", lab, w)
$)

AND cvfs(s) BE
$( LET n = rdchars()
   writef("%t7 K%n", s, n)
   FOR i = 1 TO n DO writef(" C%n", charv%i)
$)

AND cventry() BE
$( LET n = rdchars()
   LET op = rdf()
   LET lab = rdl()
   writef("*nEntry to: %s*n", charv)
   writef("%t7 K%n", "ENTRY", n)
   FOR i = 1 TO n DO writef(" C%n", charv%i)
   newline()
   TEST op=f_lab THEN writef("LAB     L%n*n", lab)
                 ELSE writef("Bad op F%n L%n*n", op, lab)
$)




