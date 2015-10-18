SECTION "prmcode"

GET "libhdr"

MANIFEST
$(
// MCODE keywords

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
s_vec=25

s_callc=29;
s_call=30;
s_indw=31;
s_indw0=32;
s_indb=33; 
s_indb0=34;
s_lsh=35;  // same order as op:= operators 
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
s_args=74
s_torf=75
s_dump=76
s_locs=77

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
s_every=121; 
s_return=124

s_module=145
s_endmodule=146;

s_global=150;
s_fun=151
s_cfun=152
s_endfun=153

s_handler=155
s_unhandle=156
s_line=157
s_file=158
s_setargs=159
s_fnargs=160
s_locs=161
$)


LET start() = VALOF
$( LET argv = VEC 20
   LET mcodein = ?
   AND mcodeprn = 0
   LET sysprint = output()
   IF rdargs("FROM,TO/K", argv, 20)=0 DO
   $( writes("Bad args for prmcode*n")
      RESULTIS 20
   $)
   IF argv!0=0 DO argv!0 := "MCODE"
   IF argv!1=0 DO argv!1 := "**"
   mcodein := findinput(argv!0)
   IF mcodein=0 DO
   $( writef("Trouble with file %s*n", argv!0)
      RESULTIS 20
   $)
   mcodeprn := findoutput(argv!1)
   
   IF mcodeprn=0 DO
   $( writef("Trouble with file %s*n", argv!1)
      RESULTIS 20
   $)
   
   writef("Converting %s to %s*n", argv!0, argv!1)
   selectinput(mcodein)
   selectoutput(mcodeprn)
   scan()
   endread()
   UNLESS mcodeprn=sysprint DO endwrite()
   selectoutput(sysprint)
   writef("Conversion Complete*n")
   RESULTIS 0   
$)

// argument may be of form Ln
AND rdn() = VALOF
$( LET a, ch, sign = 0, ?, '+'

   ch := rdch() REPEATWHILE ch='*S' | ch='*n'

   IF ch=endstreamch RESULTIS 0

   IF ch='-' DO $( sign := '-'; ch := rdch() $)

   WHILE '0'<=ch<='9' DO $( a := 10*a + ch - '0'; ch := rdch()  $)

   IF sign='-' RESULTIS -a
   RESULTIS a
$)


AND scan() BE
$( LET mcodeop = rdn()
   LET op, opn, opnn = 0, 0, 0
   LET opl = 0
   LET ops, opns, opls, oplss = 0, 0, 0, 0

   SWITCHON mcodeop INTO

   $( DEFAULT:          writef("Bad MCODE op %n*n", mcodeop); LOOP

      CASE 0:           RETURN
      
      CASE s_module:    ops    := "MODULE";    ENDCASE
      CASE s_endmodule: op     := "ENDMODULE"; ENDCASE

      CASE s_global:   $( LET n = rdn()
                          writef("GLOBAL %n*n", n)
                          FOR i = 1 TO n DO
                          $( writef("%i8   ", rdn())
                             writef("L%n*n", rdn())
                          $)
                          newline()
                          LOOP
                       $)

      CASE s_lp:        opn    := "LP";        ENDCASE
      CASE s_lg:        opn    := "LG";        ENDCASE

      CASE s_ln:        opn    := "LN";        ENDCASE

      CASE s_true:      op     := "TRUE";      ENDCASE
      CASE s_false:     op     := "FALSE";     ENDCASE
      CASE s_query:     op     := "QUERY";     ENDCASE

      CASE s_llp:       opn    := "LLP";       ENDCASE
      CASE s_llg:       opn    := "LLG";       ENDCASE

      CASE s_sp:        opn    := "SP";        ENDCASE
      CASE s_sg:        opn    := "SG";        ENDCASE

      CASE s_lf:        opl    := "LF";        ENDCASE
      CASE s_lx:        ops    := "LX";        ENDCASE

      CASE s_ll:        opl    := "LL";        ENDCASE
      CASE s_lll:       opl    := "LLL";       ENDCASE
      CASE s_sl:        opl    := "SL";        ENDCASE

      CASE s_lpath:     opnn   := "LPATH";     ENDCASE
      CASE s_llpath:    opnn   := "LLPATH";    ENDCASE
      CASE s_spath:     opnn   := "SPATH";     ENDCASE

      CASE s_cpr:       op     := "CPR";     ENDCASE
      CASE s_dup:       op     := "DUP";     ENDCASE
      CASE s_lr:        op     := "LR";      ENDCASE
      CASE s_str:       op     := "STR";     ENDCASE
      
      CASE s_stw:       op     := "STW";       ENDCASE
      CASE s_stb:       op     := "STB";       ENDCASE
      CASE s_lvindw:    op     := "LVINDW";    ENDCASE

      CASE s_indw0:     op     := "INDW0";     ENDCASE
      CASE s_indw:      op     := "INDW";      ENDCASE
      CASE s_indb0:     op     := "INDB0";     ENDCASE
      CASE s_indb:      op     := "INDB";      ENDCASE

      CASE s_mult:      op     := "MULT";      ENDCASE
      CASE s_div:       op     := "DIV";       ENDCASE
      CASE s_mod:       op     := "MOD";       ENDCASE
      CASE s_plus:      op     := "PLUS";      ENDCASE
      CASE s_sub:       op     := "SUB";       ENDCASE
      CASE s_eq:        op     := "EQ";        ENDCASE
      CASE s_ne:        op     := "NE";        ENDCASE
      CASE s_ls:        op     := "LS";        ENDCASE
      CASE s_gr:        op     := "GR";        ENDCASE
      CASE s_le:        op     := "LE";        ENDCASE
      CASE s_ge:        op     := "GE";        ENDCASE
      CASE s_lsh:       op     := "LSH";       ENDCASE
      CASE s_rsh:       op     := "RSH";       ENDCASE
      CASE s_bitand:    op     := "BITAND";    ENDCASE
      CASE s_bitor:     op     := "BITOR";     ENDCASE
      CASE s_xor:       op     := "XOR";       ENDCASE

      CASE s_bitnot:    op     := "BITNOT";    ENDCASE
      CASE s_not:       op     := "NOT";       ENDCASE
      CASE s_neg:       op     := "NEG";       ENDCASE
      CASE s_abs:       op     := "ABS";       ENDCASE

      CASE s_vec:       op     := "VEC";       ENDCASE

      CASE s_jt:        opl    := "JT";        ENDCASE
      CASE s_jf:        opl    := "JF";        ENDCASE

      CASE s_lab:       opl    := "LAB";       ENDCASE


      CASE s_ptr:       op     := "PTR";       ENDCASE
      CASE s_locs:      opn    := "LOCS";      ENDCASE
      CASE s_stack:     opn    := "STACK";     ENDCASE
      CASE s_fnargs:    opn    := "FNARGS";    ENDCASE

      CASE s_fun:       opls   := "FUN";       ENDCASE

      CASE s_cfun:      oplss  := "CFUN";      ENDCASE

      CASE s_call:      opn    := "CALL";      ENDCASE
      CASE s_callc:     opns   := "CALLC";     ENDCASE

      CASE s_return:    op     := "RETURN";    ENDCASE

      CASE s_endfun:    op     := "ENDFUN" ;   ENDCASE

      CASE s_jump:      opl    := "JUMP";      ENDCASE

      CASE s_dlab:      opl    := "DLAB";      ENDCASE
      CASE s_dw:        opn    := "DW";        ENDCASE
      CASE s_db:        opn    := "DB";        ENDCASE
      CASE s_dl:        opl    := "DL";        ENDCASE
      CASE s_ds:        opn    := "DS";        ENDCASE

      CASE s_inc1b:     op     := "INC1B";     ENDCASE
      CASE s_inc4b:     op     := "INC4B";     ENDCASE
      CASE s_dec1b:     op     := "DEC1B";     ENDCASE
      CASE s_dec4b:     op     := "DEC4B";     ENDCASE
      CASE s_inc1a:     op     := "INC1A";     ENDCASE
      CASE s_inc4a:     op     := "INC4A";     ENDCASE
      CASE s_dec1a:     op     := "DEC1A";     ENDCASE
      CASE s_dec4a:     op     := "DEC4A";     ENDCASE

      CASE s_handle:    opl    := "HANDLE";    ENDCASE
      CASE s_unhandle:  op     := "UNHANDLE";  ENDCASE
      CASE s_match:     opnn   := "MATCH";     ENDCASE

      CASE s_raise:     opn    := "RAISE";     ENDCASE
      CASE s_line:      opnn   := "LINE";      ENDCASE

      CASE s_file:      opns   := "FILE";      ENDCASE

      CASE s_setargs:   opnn   := "SETARGS";   ENDCASE

   $)

   UNLESS op=0    DO writef("%S",     op)
   UNLESS opn=0   DO writef("%S %n",  opn,  rdn())
   UNLESS opnn=0  DO writef("%S %n %n",  opnn,  rdn(), rdn())
   UNLESS opl=0   DO writef("%S L%n", opl, rdn())

   UNLESS ops=0   DO $( writef("%S", ops)
                        wrstr()
                     $)
   UNLESS opns=0  DO $( writef("%S %n", opns, rdn())
                        wrstr()
                     $)
   UNLESS opls=0  DO $( writef("%S L%n", opls, rdn())
                        wrstr()
                     $)
   UNLESS oplss=0 DO $( writef("%S L%n", oplss, rdn())
                        wrstr()
                        wrstr()
                     $)
   newline()
$) REPEAT

AND wrstr() BE
$( LET len = rdn()
   writef(" %n ", len)
   FOR i = 1 TO len DO $( LET ch = rdn()
                          IF i REM 15 = 0 DO newline()
                          TEST 32<=ch<=127 THEN writef(" '%c'", ch)
                                           ELSE writef(" %i3 ", ch)
                       $)
$)

