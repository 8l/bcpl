SECTION "sial-sasm"

GET "libhdr"

GET "sial.h"

GLOBAL {
sialin: ug
sialout; stdin; stdout

rdf; rdp; rdg; rdk; rdh; rdw; rdl; rdd; rdc
rdcode

scan
cvf; cvfp; cvfg; cvfk; cvfh; cvfw; cvfl; cvfd
}

LET start() = VALOF
{ LET argv = VEC 20

   sialout := 0
   stdout := output()
   IF rdargs("FROM,TO/K", argv, 20)=0 DO
   { writes("Bad args for sial-sasm*n")
      RESULTIS 20
   }
   IF argv!0=0 DO argv!0 := "prog.sial"
   IF argv!1=0 DO argv!1 := "prog.sasm"
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
AND rdh() = rdcode('H')
AND rdw() = rdcode('W')
AND rdl() = rdcode('L')
AND rdm() = rdcode('M')
AND rdc() = rdcode('C')

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
      CASE f_ll:     cvfl("LL"); ENDCASE

      CASE f_llp:    cvfp("LLP"); ENDCASE
      CASE f_llg:    cvfg("LLG"); ENDCASE
      CASE f_lll:    cvfl("LLL"); ENDCASE
      CASE f_lf:     cvfl("LF"); ENDCASE
      CASE f_lw:     cvfm("LW"); ENDCASE

      CASE f_l:      cvfk("L"); ENDCASE
      CASE f_lm:     cvfk("LM"); ENDCASE

      CASE f_sp:     cvfp("SP"); ENDCASE
      CASE f_sg:     cvfg("SG"); ENDCASE
      CASE f_sl:     cvfl("SL"); ENDCASE

      CASE f_ap:     cvfp("AP"); ENDCASE
      CASE f_ag:     cvfg("AG"); ENDCASE
      CASE f_a:      cvfk("A"); ENDCASE
      CASE f_s:      cvfk("S"); ENDCASE

      CASE f_lkp:    cvfkp("LKP"); ENDCASE
      CASE f_lkg:    cvfkg("LKG"); ENDCASE
      CASE f_rv:     cvf("RV"); ENDCASE
      CASE f_rvp:    cvfp("RVP"); ENDCASE
      CASE f_rvk:    cvfk("RVK"); ENDCASE
      CASE f_st:     cvf("ST"); ENDCASE
      CASE f_stp:    cvfp("STP"); ENDCASE
      CASE f_stk:    cvfk("STK"); ENDCASE
      CASE f_stkp:   cvfkp("STKP"); ENDCASE
      CASE f_skg:    cvfkg("SKG"); ENDCASE
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

      CASE f_res:    cvf("RES"); ENDCASE   // res> := A
      CASE f_ldres:  cvf("LDRES"); ENDCASE // A := <res>

      CASE f_ikp:    cvfkp("IKP"); ENDCASE
      CASE f_ikg:    cvfkg("IKG"); ENDCASE
      CASE f_ikl:    cvfkl("IKL"); ENDCASE
      CASE f_ip:     cvfp("IP");   ENDCASE
      CASE f_ig:     cvfg("IG");   ENDCASE
      CASE f_il:     cvfl("IL");   ENDCASE

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
      CASE f_jge0m:  cvfm("JGE0"); ENDCASE

      CASE f_brk:    cvf("BRK"); ENDCASE
      CASE f_nop:    cvf("NOP"); ENDCASE
      CASE f_chgco:  cvf("CHGCO"); ENDCASE
      CASE f_mdiv:   cvf("MDIV"); ENDCASE
      CASE f_sys:    cvf("SYS"); ENDCASE

      CASE f_section:  cvfs("SECTION"); ENDCASE
      CASE f_modstart: cvf("MODSTART"); ENDCASE
      CASE f_modend:   cvf("MODEND"); ENDCASE
      CASE f_global:   cvglobal(); ENDCASE
      CASE f_string:   cvstring(); ENDCASE
      CASE f_const:    cvconst(); ENDCASE
      CASE f_static:   cvstatic(); ENDCASE
      CASE f_mlab:     cvfm("MLAB"); ENDCASE
      CASE f_lab:      cvfl("LAB"); ENDCASE
      CASE f_lstr:     cvfm("LSTR"); ENDCASE
      CASE f_entry:    cventry(); ENDCASE

      CASE f_float:    cvf("FLOAT"); ENDCASE
      CASE f_fix:      cvf("FIX"); ENDCASE
      CASE f_fabs:     cvf("FABS"); ENDCASE

      CASE f_fmul:     cvf("FMUL"); ENDCASE
      CASE f_fdiv:     cvf("FDIV"); ENDCASE
      CASE f_fxdiv:    cvf("FXDIV"); ENDCASE
      CASE f_fadd:     cvf("FADD"); ENDCASE
      CASE f_fsub:     cvf("FSUB"); ENDCASE
      CASE f_fxsub:    cvf("FXSUB"); ENDCASE
      CASE f_fneg:     cvf("FNEG"); ENDCASE

      CASE f_feq:      cvf("FEQ"); ENDCASE
      CASE f_fne:      cvf("FNE"); ENDCASE
      CASE f_fls:      cvf("FLS"); ENDCASE
      CASE f_fgr:      cvf("FGR"); ENDCASE
      CASE f_fle:      cvf("FLE"); ENDCASE
      CASE f_fge:      cvf("FGE"); ENDCASE

      CASE f_feq0:    cvf("FEQ0"); ENDCASE
      CASE f_fne0:    cvf("FNE0"); ENDCASE
      CASE f_fls0:    cvf("FLS0"); ENDCASE
      CASE f_fgr0:    cvf("FGR0"); ENDCASE
      CASE f_fle0:    cvf("FLE0"); ENDCASE
      CASE f_fge0:    cvf("FGE0"); ENDCASE

      CASE f_jfeq:    cvfl("JFEQ"); ENDCASE
      CASE f_jfne:    cvfl("JFNE"); ENDCASE
      CASE f_jfls:    cvfl("JFLS"); ENDCASE
      CASE f_jfgr:    cvfl("JFGR"); ENDCASE
      CASE f_jfle:    cvfl("JFLE"); ENDCASE
      CASE f_jfge:    cvfl("JFGE"); ENDCASE

      CASE f_jfeq0:   cvfl("JFEQ0"); ENDCASE
      CASE f_jfne0:   cvfl("JFNE0"); ENDCASE
      CASE f_jfls0:   cvfl("JFLS0"); ENDCASE
      CASE f_jfgr0:   cvfl("JFGR0"); ENDCASE
      CASE f_jfle0:   cvfl("JFLE0"); ENDCASE
      CASE f_jfge0:   cvfl("JFGE0"); ENDCASE
   }

   newline()
} REPEAT

AND cvf(s)  BE writef(s)
AND cvfp(s) BE writef("%t7 P%n", s, rdp())
AND cvfkp(s) BE writef("%t7 K%n P%n", s, rdk(), rdp())
AND cvfg(s) BE writef("%t7 G%n", s, rdg())
AND cvfkg(s) BE writef("%t7 K%n G%n", s, rdk(), rdg())
AND cvfkl(s) BE writef("%t7 K%n L%n", s, rdk(), rdl())
AND cvfpg(s) BE writef("%t7 P%n G%n", s, rdp(), rdg())
AND cvfk(s) BE writef("%t7 K%n", s, rdk())
AND cvfh(s) BE writef("%t7 H%n", s, rdh())
AND cvfw(s) BE writef("%t7 W%n", s, rdw())
AND cvfl(s) BE writef("%t7 L%n", s, rdl())
AND cvfm(s) BE writef("%t7 M%n", s, rdm())

AND cvswl() BE
{ LET n = rdk()
   LET l = rdl()
   writef("SWL K%n L%n", n, l)
   FOR i = 1 TO n DO writef("*nL%n", rdl())
}

AND cvswb() BE
{ LET n = rdk()
   LET l = rdl()
   writef("SWB K%n L%n", n, l)
   FOR i = 1 TO n DO 
   { LET k = rdk()
      LET l = rdl()
      writef("*nK%n L%n", k, l)
   }
}

AND cvglobal() BE
{ LET n = rdk()
   writef("GLOBAL K%n*n", n)
   FOR i = 1 TO n DO
   { LET g = rdg()
      LET n = rdl()
      writef("G%n L%n*n", g, n)
   }
   writef("G%n", rdg())
}

AND cvstring() BE
{ LET lab = rdm()
   LET n = rdk()
   writef("STRING  M%n K%n", lab, n)
   FOR i = 1 TO n DO writef(" C%n", rdc())
}

AND cvconst() BE
{ LET lab = rdm()
   LET w = rdw()
   writef("CONST   M%n W%n", lab, w)
}

AND cvstatic() BE
{ LET lab = rdl()
   LET n = rdk()
   writef("STATIC  L%n K%n", lab, n)
   FOR i = 1 TO n DO writef(" W%n", rdw())
}

AND cvfs(s) BE
{ LET n = rdk()
   writef("%t7 K%n", s, n)
   FOR i = 1 TO n DO writef(" C%n", rdc())
}

AND cventry() BE
{ LET n = rdk()
   LET v = VEC 256
   v%0 := n
   FOR i = 1 TO n DO v%i := rdc()
   writef("*n//Entry to: %s*n", v)
   writef("%t7 K%n", "ENTRY", n)
   FOR i = 1 TO n DO writef(" C%n", v%i)
}
