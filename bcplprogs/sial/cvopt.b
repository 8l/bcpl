SECTION "cvopt"

GET "libhdr"

GET "sial.h"

GLOBAL {
sialin:   200
sialout:  201
stdin:    202
stdout:   203

rdf:      210
rdp:      211
rdg:      212
rdk:      213
rdn:      214
rdr:      215
rdw:      216
rdl:      217
rdc:      218
rdt:      219

rdcode:   220

scan:     230
cvf:      231
cvfp:     232
cvfg:     233
cvfk:     234
cvfw:     236
cvfl:     237

plab:     240
dlab:     241
}

LET start() = VALOF
{ LET argv = VEC 20

  sialout := 0
  stdout := output()
  IF rdargs("FROM,TO/K", argv, 20)=0 DO
  { writes("Bad args for cvopt*n")
    RESULTIS 20
  }
  IF argv!0=0 DO argv!0 := "bcpl.opt"
  IF argv!1=0 DO argv!1 := "bcpl.sasm"
  sialin := findinput(argv!0)
  IF sialin=0 DO
  { writef("Trouble with file %s*n", argv!0)
    RESULTIS 20
  }
  sialout := findoutput(argv!1)
   
  IF sialout=0 DO
  { writef("Trouble with file %s*n", argv!1)
    RESULTIS 20
  }
   
  writef("Converting %s to %s*n", argv!0, argv!1)
  selectinput(sialin)
  selectoutput(sialout)
  plab, dlab := 0, 0
  scan()
  endread()
  UNLESS sialout=stdout DO endwrite()
  selectoutput(stdout)
  writef("Conversion complete*n")
  RESULTIS 0
}

// argument may be of form Ln
AND rdcode(let) = VALOF
{ LET a, ch, neg = 0, ?, FALSE

  ch := rdch() REPEATWHILE ch='*s' | ch='*n'

  IF ch=endstreamch RESULTIS -1

  UNLESS ch=let DO error("Bad item, looking for %c found %c*n", let, ch)

  ch := rdch()

  IF ch='-' DO { neg := TRUE; ch := rdch() }

  WHILE '0'<=ch<='9' DO { a := 10*a + ch - '0'; ch := rdch()  }

  RESULTIS neg -> -a, a
}

AND rdf() = rdcode('F')
AND rdp() = rdcode('P')
AND rdg() = rdcode('G')
AND rdk() = rdcode('K')
AND rdn() = rdcode('N')
AND rdr() = rdcode('R')
AND rdw() = rdcode('W')
AND rdl() = rdcode('L')
AND rdm() = rdcode('M')
AND rdc() = rdcode('C')
AND rdt() = rdcode('T')

AND error(mess, a, b, c) BE
{ LET out = output()
  UNLESS out=stdout DO
  { selectoutput(stdout)
    writef(mess, a, b, c)
    selectoutput(out)
  }
  writef(mess, a, b, c)
}

AND scan() BE
{ LET op = rdf()

  SWITCHON op INTO

  { DEFAULT:       error("Bad op %n*n", op); LOOP

    CASE -1:       RETURN
      
    CASE f_lp:     cvfp("LP"); ENDCASE
    CASE f_lg:     cvfg("LG"); ENDCASE
    CASE f_ll:     cvfm("LL"); ENDCASE

    CASE f_llp:    cvfp("LLP"); ENDCASE
    CASE f_llg:    cvfg("LLG"); ENDCASE
    CASE f_lll:    cvfm("LLL"); ENDCASE
    CASE f_lf:     cvfl("LF"); ENDCASE
    CASE f_lw:     cvfm("LW"); ENDCASE

    CASE f_l:      cvfk("L"); ENDCASE
    CASE f_lm:     cvfk("LM"); ENDCASE

    CASE f_sp:     cvfp("SP"); ENDCASE
    CASE f_sg:     cvfg("SG"); ENDCASE
    CASE f_sl:     cvfm("SL"); ENDCASE

    CASE f_ap:     cvfp("AP"); ENDCASE
    CASE f_ag:     cvfg("AG"); ENDCASE
    CASE f_a:      cvfk("A"); ENDCASE
    CASE f_s:      cvfk("S"); ENDCASE

    CASE f_lkp:    cvfrp("LKP"); ENDCASE
    CASE f_lkg:    cvfrg("LKG"); ENDCASE
    CASE f_rv:     cvf("RV"); ENDCASE
    CASE f_rvp:    cvfp("RVP"); ENDCASE
    CASE f_rvk:    cvfr("RVK"); ENDCASE
    CASE f_st:     cvf("ST"); ENDCASE
    CASE f_stp:    cvfp("STP"); ENDCASE
    CASE f_stk:    cvfr("STK"); ENDCASE
    CASE f_stkp:   cvfrp("STKP"); ENDCASE
    CASE f_skg:    cvfrg("SKG"); ENDCASE
    CASE f_xst:    cvf("XST"); ENDCASE

    CASE f_k:      cvfp("K"); ENDCASE
    CASE f_kpg:    cvfpg("KPG"); ENDCASE

    CASE f_neg:    cvf("NEG"); ENDCASE
    CASE f_not:    cvf("NOT"); ENDCASE
    CASE f_abs:    cvf("ABS"); ENDCASE

    CASE f_xdiv:   cvf("XDIV"); ENDCASE
    CASE f_xrem:   cvf("XREM"); ENDCASE
    CASE f_xsub:   cvf("XSUB"); ENDCASE

    CASE f_mul:    cvf("MUL"); ENDCASE
    CASE f_div:    cvf("DIV"); ENDCASE
    CASE f_rem:    cvf("REM"); ENDCASE
    CASE f_add:    cvf("ADD"); ENDCASE
    CASE f_sub:    cvf("SUB"); ENDCASE

    CASE f_eq:     cvf("EQ"); ENDCASE
    CASE f_ne:     cvf("NE"); ENDCASE
    CASE f_ls:     cvf("LS"); ENDCASE
    CASE f_gr:     cvf("GR"); ENDCASE
    CASE f_le:     cvf("LE"); ENDCASE
    CASE f_ge:     cvf("GE"); ENDCASE
    CASE f_eq0:    cvf("EQ0"); ENDCASE
    CASE f_ne0:    cvf("NE0"); ENDCASE
    CASE f_ls0:    cvf("LS0"); ENDCASE
    CASE f_gr0:    cvf("GR0"); ENDCASE
    CASE f_le0:    cvf("LE0"); ENDCASE
    CASE f_ge0:    cvf("GE0"); ENDCASE

    CASE f_lsh:    cvf("LSH"); ENDCASE
    CASE f_rsh:    cvf("RSH"); ENDCASE
    CASE f_and:    cvf("AND"); ENDCASE
    CASE f_or:     cvf("OR"); ENDCASE
    CASE f_xor:    cvf("XOR"); ENDCASE
    CASE f_eqv:    cvf("EQV"); ENDCASE

    CASE f_gbyt:   cvf("GBYT");  ENDCASE
    CASE f_xgbyt:  cvf("XGBYT"); ENDCASE
    CASE f_pbyt:   cvf("PBYT");  ENDCASE
    CASE f_xpbyt:  cvf("XPBYT"); ENDCASE

    CASE f_swb:       cvswb(); ENDCASE
    CASE f_swl:       cvswl(); ENDCASE

    CASE f_xch:    cvf("XCH"); ENDCASE
    CASE f_atb:    cvf("ATB"); ENDCASE
    CASE f_atc:    cvf("ATC"); ENDCASE
    CASE f_bta:    cvf("BTA"); ENDCASE
    CASE f_btc:    cvf("BTC"); ENDCASE
    CASE f_atblp:  cvfp("ATBLP"); ENDCASE
    CASE f_atblg:  cvfg("ATBLG"); ENDCASE
    CASE f_atbl:   cvfk("ATBL"); ENDCASE

    CASE f_j:      cvfl("J"); ENDCASE
    CASE f_rtn:    cvf("RTN"); ENDCASE
    CASE f_goto:   cvf("GOTO"); ENDCASE

    CASE f_ikp:    cvfrp("IKP"); ENDCASE
    CASE f_ikg:    cvfrg("IKG"); ENDCASE
    CASE f_ikl:    cvfrm("IKL"); ENDCASE
    CASE f_ip:     cvfp("IP");   ENDCASE
    CASE f_ig:     cvfg("IG");   ENDCASE
    CASE f_il:     cvfm("IL");   ENDCASE

    CASE f_jeq:    cvfl("JEQ"); ENDCASE
    CASE f_jne:    cvfl("JNE"); ENDCASE
    CASE f_jls:    cvfl("JLS"); ENDCASE
    CASE f_jgr:    cvfl("JGR"); ENDCASE
    CASE f_jle:    cvfl("JLE"); ENDCASE
    CASE f_jge:    cvfl("JGE"); ENDCASE
    CASE f_jeq0:   cvfl("JEQ0"); ENDCASE
    CASE f_jne0:   cvfl("JNE0"); ENDCASE
    CASE f_jls0:   cvfl("JLS0"); ENDCASE
    CASE f_jgr0:   cvfl("JGR0"); ENDCASE
    CASE f_jle0:   cvfl("JLE0"); ENDCASE
    CASE f_jge0:   cvfl("JGE0"); ENDCASE

    CASE f_brk:    cvf("BRK"); ENDCASE
    CASE f_nop:    cvf("NOP"); ENDCASE
    CASE f_chgco:  cvf("CHGCO"); ENDCASE
    CASE f_mdiv:   cvf("MDIV"); ENDCASE
    CASE f_sys:    cvf("SYS"); ENDCASE

    CASE f_section:  cvfs("SECTION"); ENDCASE
    CASE f_modstart: cvf("MODSTART")
                     plab, dlab := 0, 0
                     ENDCASE
    CASE f_modend:   cvf("MODEND"); ENDCASE
    CASE f_global:   cvglobal(); ENDCASE
    CASE f_string:   cvstring(); ENDCASE
    CASE f_const:    cvconst(); ENDCASE
    CASE f_static:   cvstatic(); ENDCASE
    CASE f_lab:      cvlab(); ENDCASE
    CASE f_lstr:     cvfm("LSTR"); ENDCASE
    CASE f_entry:    cventry(); ENDCASE
  }

  newline()
} REPEAT

AND cvf(s)   BE writef(s)
AND cvfp(s)  BE writef("%t7 P%n", s, rdp())
AND cvfrp(s) BE writef("%t7 R%n P%n", s, rdr(), rdp())
AND cvfg(s)  BE writef("%t7 G%n", s, rdg())
AND cvfrg(s) BE writef("%t7 R%n G%n", s, rdr(), rdg())
AND cvfrm(s) BE writef("%t7 R%n M%n", s, rdr(), rdm())
AND cvfpg(s) BE writef("%t7 P%n G%n", s, rdp(), rdg())
AND cvfk(s)  BE writef("%t7 K%n", s, rdk())
AND cvfr(s)  BE writef("%t7 R%n", s, rdr())
AND cvfw(s)  BE writef("%t7 W%n", s, rdw())
AND cvfl(s)  BE writef("%t7 L%n", s, rdl())
AND cvfm(s)  BE writef("%t7 M%n", s, rdm())

AND cvswl() BE
{ LET n = rdn()
  LET l = rdl()
  writef("SWL N%n L%n", n, l)
  FOR i = 1 TO n DO writef("*nL%n", rdl())
}

AND cvswb() BE
{ LET n = rdn()
  LET l = rdl()
  writef("SWB N%n L%n", n, l)
  FOR i = 1 TO n DO 
  { LET k = rdk()
    LET l = rdl()
    writef("*nK%n L%n", k, l)
  }
}

AND cvglobal() BE
{ LET n = rdn()
  writef("GLOBAL N%n*n", n)
  FOR i = 1 TO n DO
  { LET g = rdg()
    LET n = rdl()
    writef("G%i3 L%n*n", g, n)
  }
  writef("G%n", rdg())
}

AND cvstring() BE
{ LET lab = nextdlab()
  LET n = rdn()
  writef("STRING  (M%n) N%n", lab, n)
  FOR i = 1 TO n DO writef(" C%n", rdc())
}

AND cvconst() BE
{ LET lab = nextdlab()
  LET w = rdw()
  writef("CONST   (M%n) W%n", lab, w)
}

AND cvstatic() BE
{ LET lab = nextdlab()
  LET n = rdn()
  writef("STATIC  (M%n) N%n", lab, n)
  FOR i = 1 TO n DO writef(" W%n", rdw())
}

AND cvlab() BE
{ LET lab = nextplab()
  writef("*nLAB     (L%n)", lab)
}

AND cvfs(s) BE
{ LET n = rdn()
  writef("%t7 N%n", s, n)
  FOR i = 1 TO n DO writef(" T%n", rdt())
}

AND cventry() BE
{ LET n = rdn()
  LET v = VEC 256
  v%0 := n
  FOR i = 1 TO n DO v%i := rdt()
  writef("*n//Entry to: %s*n", v)
  writef("%t7 N%n", "ENTRY", n)
  FOR i = 1 TO n DO writef(" T%n", v%i)
}

AND nextplab() = VALOF
{ plab := plab+1
  RESULTIS plab
}

AND nextdlab() = VALOF
{ dlab := dlab+1
  RESULTIS dlab
}
