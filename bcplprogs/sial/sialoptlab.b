
/* This is a modification of sialopt
   It just outputs the lab streams L and M after renumbering in ascending
   order of setting. The setting occurences have a colon appended.
   End of module is marked by '#'.
   This stream is designed for statistical analysis.
*/ 

SECTION "sialoptlab"

GET "libhdr"

GET "sial.h"

GLOBAL {
sialin:   200
sialout:  201
stdin:    202
stdout:   203
debug:    204

rdf:      210
rdp:      211
rdg:      212
rdk:      213
rdw:      215
rdl:      216
rdc:      218
rdcode:   219

readmodule:   220
optimize:     221
outputmodule: 222

rdf:      231
rdfp:     232
rdfg:     233
rdfk:     234
rdfw:     236
rdfl:     237
rdfd:     238

codev:    240
codep:    241
labv:     242
propv:    243
newlab:   244  // newlab!lab is the equated label if not zero.
currlab:  245

nextplab: 250  // next program label
nextdlab: 251  // next data label
}

MANIFEST {
codevupb= 150000
labvupb=   10000

// property bits
p_plab=    1      // used in J, JEQ, JEQ0 etc
p_dlab=    2      // used in LL LLL SL IL IKL
p_equate=  4      // the label has been equated with another label 
}

LET start() = VALOF
{ LET argv = VEC 20

  sialout := 0
  stdout := output()
  IF rdargs("FROM,TO/K,D/K", argv, 20)=0 DO
  { writes("Bad args for sialoptlab*n")
    RESULTIS 20
  }
  IF argv!0=0 DO argv!0 := "bcpl.sial"
  IF argv!1=0 DO argv!1 := "bcpl.opt"
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

  debug := 0
  IF argv!2 DO debug := str2numb(argv!2)
   
  codev := getvec(codevupb)
  labv := getvec(labvupb)
  propv := getvec(labvupb)
  newlab := getvec(labvupb)

  TEST codev=0 | labv=0 | propv=0 | newlab=0 
  THEN writef("Insufficient memory*n")
  ELSE { writef("Converting %s to %s*n", argv!0, argv!1)
         selectinput(sialin)
         selectoutput(sialout)
         
         { codep := 0
           nextplab, nextdlab := 0, 0
           UNLESS readmodule() BREAK
           codep := 0
           nextplab, nextdlab := 0, 0
           optimize()
           codep := 0
           nextplab, nextdlab := 0, 0
           outputmodule()
         } REPEAT

         endread()
         UNLESS sialout=stdout DO endwrite()
       }
  selectoutput(stdout)
  writef("Conversion complete*n")
  IF codev DO freevec(codev)
  IF labv DO freevec(labv)
  IF propv DO freevec(propv)
  IF newlab DO freevec(newlab)
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

AND rdop() = rdcode('F')
AND rdp()  = rdcode('P')
AND rdg()  = rdcode('G')
AND rdk()  = rdcode('K')
AND rdw()  = rdcode('W')
AND rdl()  = rdcode('L')
AND rdm()  = rdcode('M')
AND rdc()  = rdcode('C')

AND error(mess, a, b, c) BE
{ LET out = output()
   UNLESS out=stdout DO
   { selectoutput(stdout)
      writef(mess, a, b, c)
      selectoutput(out)
   }
   writef(mess, a, b, c)
}

AND readmodule() = VALOF
// This reads in the unoptimized SIAL and store the statements in codev.
// It equates equal program labels and sets p_plab and p_dlab bits in
// the property word for each label used. Labels that are not used
// need not be assigned a new label number and do not need to be set.
{ LET op = rdop()

  SWITCHON op INTO

  { DEFAULT:       error("Bad op %n*n", op)
                   RESULTIS FALSE

    CASE -1:       RESULTIS FALSE

    CASE f_lp:     rdfp(op);          ENDCASE
    CASE f_lg:     rdfg(op);          ENDCASE
    CASE f_ll:     rdfl(op, p_dlab);  ENDCASE

    CASE f_llp:    rdfp(op);          ENDCASE
    CASE f_llg:    rdfg(op);          ENDCASE
    CASE f_lll:    rdfl(op, p_dlab);  ENDCASE
    CASE f_lf:     rdfl(op, p_plab);  ENDCASE
    CASE f_lw:     rdfm(op, p_dlab);  ENDCASE

    CASE f_l:      rdfk(op);          ENDCASE
    CASE f_lm:     rdfk(op);          ENDCASE

    CASE f_sp:     rdfp(op);          ENDCASE
    CASE f_sg:     rdfg(op);          ENDCASE
    CASE f_sl:     rdfl(op, p_dlab);  ENDCASE

    CASE f_ap:     rdfp(op);          ENDCASE
    CASE f_ag:     rdfg(op);          ENDCASE
    CASE f_a:      rdfk(op);          ENDCASE
    CASE f_s:      rdfk(op);          ENDCASE

    CASE f_lkp:    rdfkp(op); ENDCASE
    CASE f_lkg:    rdfkg(op); ENDCASE
    CASE f_rv:     rdf(op);   ENDCASE
    CASE f_rvp:    rdfp(op);  ENDCASE
    CASE f_rvk:    rdfk(op);  ENDCASE
    CASE f_st:     rdf(op);   ENDCASE
    CASE f_stp:    rdfp(op);  ENDCASE
    CASE f_stk:    rdfk(op);  ENDCASE
    CASE f_stkp:   rdfkp(op); ENDCASE
    CASE f_skg:    rdfkg(op); ENDCASE
    CASE f_xst:    rdf(op);   ENDCASE

    CASE f_k:      rdfp(op);  ENDCASE
    CASE f_kpg:    rdfpg(op); ENDCASE

    CASE f_neg:    rdf(op);   ENDCASE
    CASE f_not:    rdf(op);   ENDCASE
    CASE f_abs:    rdf(op);   ENDCASE

    CASE f_xdiv:   rdf(op);   ENDCASE
    CASE f_xrem:   rdf(op);   ENDCASE
    CASE f_xsub:   rdf(op);   ENDCASE

    CASE f_mul:    rdf(op);   ENDCASE
    CASE f_div:    rdf(op);   ENDCASE
    CASE f_rem:    rdf(op);   ENDCASE
    CASE f_add:    rdf(op);   ENDCASE
    CASE f_sub:    rdf(op);   ENDCASE

    CASE f_eq:     rdf(op);   ENDCASE
    CASE f_ne:     rdf(op);   ENDCASE
    CASE f_ls:     rdf(op);   ENDCASE
    CASE f_gr:     rdf(op);   ENDCASE
    CASE f_le:     rdf(op);   ENDCASE
    CASE f_ge:     rdf(op);   ENDCASE
    CASE f_eq0:    rdf(op);   ENDCASE
    CASE f_ne0:    rdf(op);   ENDCASE
    CASE f_ls0:    rdf(op);   ENDCASE
    CASE f_gr0:    rdf(op);   ENDCASE
    CASE f_le0:    rdf(op);   ENDCASE
    CASE f_ge0:    rdf(op);   ENDCASE

    CASE f_lsh:    rdf(op);   ENDCASE
    CASE f_rsh:    rdf(op);   ENDCASE
    CASE f_and:    rdf(op);   ENDCASE
    CASE f_or:     rdf(op);   ENDCASE
    CASE f_xor:    rdf(op);   ENDCASE
    CASE f_eqv:    rdf(op);   ENDCASE

    CASE f_gbyt:   rdf(op);   ENDCASE
    CASE f_xgbyt:  rdf(op);   ENDCASE
    CASE f_pbyt:   rdf(op);   ENDCASE
    CASE f_xpbyt:  rdf(op);   ENDCASE

    CASE f_swb:    rdswb(op); ENDCASE
    CASE f_swl:    rdswl(op); ENDCASE

    CASE f_xch:    rdf(op);   ENDCASE
    CASE f_atb:    rdf(op);   ENDCASE
    CASE f_atc:    rdf(op);   ENDCASE
    CASE f_bta:    rdf(op);   ENDCASE
    CASE f_btc:    rdf(op);   ENDCASE
    CASE f_atblp:  rdfp(op);  ENDCASE
    CASE f_atblg:  rdfg(op);  ENDCASE
    CASE f_atbl:   rdfk(op);  ENDCASE

    CASE f_j:      rdfl(op, p_plab);  ENDCASE
    CASE f_rtn:    rdf(op);   ENDCASE
    CASE f_goto:   rdf(op);   ENDCASE

    CASE f_ikp:    rdfkp(op); ENDCASE
    CASE f_ikg:    rdfkg(op); ENDCASE
    CASE f_ikl:    rdfkl(op, p_dlab); ENDCASE
    CASE f_ip:     rdfp(op);  ENDCASE
    CASE f_ig:     rdfg(op);  ENDCASE
    CASE f_il:     rdfl(op, p_dlab);  ENDCASE

    CASE f_jeq:    rdfl(op, p_plab);  ENDCASE
    CASE f_jne:    rdfl(op, p_plab);  ENDCASE
    CASE f_jls:    rdfl(op, p_plab);  ENDCASE
    CASE f_jgr:    rdfl(op, p_plab);  ENDCASE
    CASE f_jle:    rdfl(op, p_plab);  ENDCASE
    CASE f_jge:    rdfl(op, p_plab);  ENDCASE
    CASE f_jeq0:   rdfl(op, p_plab);  ENDCASE
    CASE f_jne0:   rdfl(op, p_plab);  ENDCASE
    CASE f_jls0:   rdfl(op, p_plab);  ENDCASE
    CASE f_jgr0:   rdfl(op, p_plab);  ENDCASE
    CASE f_jle0:   rdfl(op, p_plab);  ENDCASE
    CASE f_jge0:   rdfl(op, p_plab);  ENDCASE
    CASE f_jge0m:  rdfm(f_jge0, p_plab);  ENDCASE

    CASE f_brk:    rdf(op);   ENDCASE
    CASE f_nop:    rdf(op);   ENDCASE
    CASE f_chgco:  rdf(op);   ENDCASE
    CASE f_mdiv:   rdf(op);   ENDCASE
    CASE f_sys:    rdf(op);   ENDCASE

    CASE f_section:  rdfs(op);      ENDCASE
    CASE f_modstart: codep := 0
                     FOR i = 0 TO labvupb DO
                       labv!i, propv!i, newlab!i := 0, 0, 0
                     rdf(op);       ENDCASE
    CASE f_modend:   rdf(op)
                     push(0)        // End marker
                     RESULTIS TRUE
    CASE f_global:   rdglobal(op);  ENDCASE
    CASE f_string:   rdstring(op);  ENDCASE
    CASE f_const:    rdconst(op);   ENDCASE
    CASE f_static:   rdstatic(op);  ENDCASE
    CASE f_mlab:     setplab(labvupb-rdm()); LOOP
    CASE f_lab:      setplab(rdl());         LOOP

    CASE f_lstr:     rdfm(op, p_dlab);      ENDCASE
    CASE f_entry:    rdentry(op);   ENDCASE
  }
  currlab := 0
} REPEAT

AND rdf(op)   BE { push(op) }
AND rdfp(op)  BE { push(op); push(rdp()) }
AND rdfkp(op) BE { push(op); push(rdk()); push(rdp()) }
AND rdfg(op)  BE { push(op); push(rdg()) }
AND rdfkg(op) BE { push(op); push(rdk()); push(rdg()) }
AND rdfpg(op) BE { push(op); push(rdp()); push(rdg()) }
AND rdfk(op)  BE { push(op); push(rdk()) }
AND rdfw(op)  BE { push(op); push(rdw()) }

// only used by IKL
AND rdfkl(op) BE { push(op); push(rdk()); push(rdl()) }

AND rdfl(op, props) BE
{ LET lab = rdl()
  IF (propv!lab & p_equate)>0 DO lab := newlab!lab
  push(op)
  push(lab)
  propv!lab := propv!lab | props
}

AND rdfm(op, props) BE
{ LET lab = labvupb - rdm()
  IF (propv!lab & p_equate)>0 DO lab := newlab!lab
  push(op)
  push(lab)
  propv!lab := propv!lab | props
}

AND setplab(lab) BE
{ TEST currlab
  THEN { propv!currlab := propv!currlab | propv!lab
         newlab!lab := currlab
         propv!lab := p_equate
       }
  ELSE { currlab := lab
         push(f_lab)
         push(lab)
         propv!lab := propv!lab | p_plab
       }
}

AND push(x) BE
{ codev!codep := x
  codep := codep+1
  IF codep>codevupb DO abort(9998)
}

AND pop() = VALOF
{ LET val = codev!codep
  codep := codep+1
  RESULTIS val
}

AND rdswl(op) BE
{ LET n = rdk()
  push(op)
  push(n)
  FOR i = 0 TO n DO
  { LET lab = rdl()
    push(lab)
    propv!lab := propv!lab | p_plab
  }
}

AND rdswb(op) BE
{ LET n = rdk()
  LET lab = rdl()
  push(op)
  push(n)
  push(lab)
  propv!lab := propv!lab | p_plab
  FOR i = 1 TO n DO 
  { LET k = rdk()
    LET lab = rdl()
    push(k)
    push(lab)
    propv!lab := propv!lab | p_plab
  }
}

AND rdglobal(op) BE
{ LET n = rdk()
  push(op)
  push(n)
  FOR i = 1 TO n DO
  { LET g = rdg()
    LET lab = rdl()
    push(g)
    push(lab)
    propv!lab := propv!lab | p_plab
  }
  push(rdg())
}

AND rdstring(op) BE
{ LET lab = labvupb - rdm()
  LET n = rdk()
  push(op)
  push(lab)
  push(n)
  FOR i = 1 TO n DO push(rdc())
}

AND rdconst(op) BE
{ LET lab = labvupb - rdm()
  LET w = rdw()
  push(op)
  push(lab)
  push(w)
}

AND rdstatic(op) BE
{ LET lab = rdl()
  LET n = rdk()
  push(op)
  push(lab)
  push(n)
  FOR i = 1 TO n DO push(rdw())
}

AND rdfs(op) BE
{ LET n = rdk()
  push(op)
  push(n)
  FOR i = 1 TO n DO push(rdc())
}

AND rdentry(op) BE
{ LET n = rdk()
  push(op)
  push(n)
  FOR i = 1 TO n DO push(rdc())
}

AND optimize() BE
// This reads through the code in codev allocating program and data
// labels in the order in which they are set, provided they have been
// used.
{ LET op = pop()
//writef("codep=%n F%n*n", codep-1, op)

  SWITCHON op INTO

  { DEFAULT:       error("Bad op %n*n", op); abort(888)

    CASE 0:        RETURN
    CASE -1:       abort(887); LOOP

    CASE f_lp:
    CASE f_lg:
    CASE f_ll:
    CASE f_llp:
    CASE f_llg:
    CASE f_lll:
    CASE f_lf:
    CASE f_lw:
    CASE f_l:
    CASE f_lm:
    CASE f_sp:
    CASE f_sg:
    CASE f_sl:
    CASE f_ap:
    CASE f_ag:
    CASE f_a:
    CASE f_s:
    CASE f_rvp:
    CASE f_rvk:
    CASE f_stp:
    CASE f_stk:
    CASE f_k:
    CASE f_atblp:
    CASE f_atblg:
    CASE f_atbl:
    CASE f_j:
    CASE f_ip:
    CASE f_ig:
    CASE f_il:
    CASE f_jeq:
    CASE f_jne:
    CASE f_jls:
    CASE f_jgr:
    CASE f_jle:
    CASE f_jge:
    CASE f_jeq0:
    CASE f_jne0:
    CASE f_jls0:
    CASE f_jgr0:
    CASE f_jle0:
    CASE f_jge0:
    CASE f_lstr:
                   codep := codep+1; ENDCASE

    CASE f_lkp:
    CASE f_lkg:
    CASE f_stkp:
    CASE f_skg:
    CASE f_kpg:
    CASE f_ikp:
    CASE f_ikg:
    CASE f_ikl:    codep := codep+2; ENDCASE

    CASE f_rv:
    CASE f_st:
    CASE f_xst:
    CASE f_neg:
    CASE f_not:
    CASE f_abs:
    CASE f_xdiv:
    CASE f_xrem:
    CASE f_xsub:
    CASE f_mul:
    CASE f_div:
    CASE f_rem:
    CASE f_add:
    CASE f_sub:
    CASE f_eq:
    CASE f_ne:
    CASE f_ls:
    CASE f_gr:
    CASE f_le:
    CASE f_ge:
    CASE f_eq0:
    CASE f_ne0:
    CASE f_ls0:
    CASE f_gr0:
    CASE f_le0:
    CASE f_ge0:
    CASE f_lsh:
    CASE f_rsh:
    CASE f_and:
    CASE f_or:
    CASE f_xor:
    CASE f_eqv:
    CASE f_gbyt:
    CASE f_xgbyt:
    CASE f_pbyt:
    CASE f_xpbyt:
    CASE f_xch:
    CASE f_atb:
    CASE f_atc:
    CASE f_bta:
    CASE f_btc:
    CASE f_rtn:
    CASE f_goto:
    CASE f_brk:
    CASE f_nop:
    CASE f_chgco:
    CASE f_mdiv:
    CASE f_sys:
    CASE f_modstart:
                   ENDCASE

    CASE f_swb:  { LET n = pop()
                   codep := codep + 2*n + 1
                   ENDCASE
                 }
    CASE f_swl:  { LET n = pop()
                   codep := codep + n + 1
                   ENDCASE
                 }

    CASE f_section:
    CASE f_entry:
                 { LET n = pop()
                   codep := codep + n
                   ENDCASE
                 }

    CASE f_global:
                 { LET n = pop()
                   codep := codep + 2*n + 1
                   ENDCASE
                 }

    CASE f_string: { LET lab = pop()
                     LET n = pop()
                     codep := codep + n
                     IF (propv!lab & p_dlab) > 0 DO
                     { nextdlab := nextdlab + 1
                       newlab!lab := nextdlab
                     }
                     ENDCASE
                   }
    CASE f_const:  { LET lab = pop()
                     codep := codep + 1
                     IF (propv!lab & p_dlab) > 0 DO
                     { nextdlab := nextdlab + 1
                       newlab!lab := nextdlab
                     }
                     ENDCASE
                   }
    CASE f_static: { LET lab = pop()
                     LET n = pop()
                     codep := codep + n
                     IF (propv!lab & p_dlab) > 0 DO
                     { nextdlab := nextdlab + 1
                       newlab!lab := nextdlab
                     }
                     ENDCASE
                   }
    CASE f_lab:    { LET lab = pop()
                     IF newlab!lab=0 & (propv!lab & p_plab) > 0 DO
                     { nextplab := nextplab + 1
                       newlab!lab := nextplab
                     }
                     ENDCASE
                   }

    CASE f_modend: RETURN
  }
} REPEAT


AND outputmodule() BE
{ LET op = pop()

  SWITCHON op INTO

  { DEFAULT:       error("Bad op %n*n", op);
                   abort(1000)
                   LOOP

    CASE f_lp:
    CASE f_llp:
    CASE f_sp:
    CASE f_ap:
    CASE f_rvp:
    CASE f_stp:
    CASE f_k:
    CASE f_atblp:  cvfp(op);   ENDCASE


    CASE f_lg:
    CASE f_llg:
    CASE f_sg:
    CASE f_ag:
    CASE f_atblg:  cvfg(op);   ENDCASE

    CASE f_ll:
    CASE f_lll:
    CASE f_lf:
    CASE f_sl:
    CASE f_j:
    CASE f_lw:     cvfl(op);   ENDCASE

    CASE f_l:
    CASE f_lm:
    CASE f_a:
    CASE f_s:
    CASE f_atbl:   cvfk(op);   ENDCASE

    CASE f_rvk:
    CASE f_stk:    cvfr(op);   ENDCASE

    CASE f_lkp:
    CASE f_stkp:   cvfrp(op);  ENDCASE

    CASE f_lkg:
    CASE f_skg:    cvfrg(op);  ENDCASE

    CASE f_kpg:    cvfpg(op);  ENDCASE

    CASE f_rv:
    CASE f_st:
    CASE f_xst:
    CASE f_neg:
    CASE f_not:
    CASE f_abs:
    CASE f_xdiv:
    CASE f_xrem:
    CASE f_xsub:
    CASE f_mul:
    CASE f_div:
    CASE f_rem:
    CASE f_add:
    CASE f_sub:
    CASE f_eq:
    CASE f_ne:
    CASE f_ls:
    CASE f_gr:
    CASE f_le:
    CASE f_ge:
    CASE f_eq0:
    CASE f_ne0:
    CASE f_ls0:
    CASE f_gr0:
    CASE f_le0:
    CASE f_ge0:
    CASE f_lsh:
    CASE f_rsh:
    CASE f_and:
    CASE f_or:
    CASE f_xor:
    CASE f_eqv:
    CASE f_gbyt:
    CASE f_xgbyt:
    CASE f_pbyt:
    CASE f_xpbyt:
    CASE f_xch:
    CASE f_atb:
    CASE f_atc:
    CASE f_bta:
    CASE f_btc:
    CASE f_rtn:
    CASE f_goto:
    CASE f_brk:
    CASE f_nop:
    CASE f_chgco:
    CASE f_mdiv:
    CASE f_sys:
    CASE f_modstart: cvf(op);  ENDCASE


    CASE f_swb:    cvswb(op);  ENDCASE
    CASE f_swl:    cvswl(op);  ENDCASE


    CASE f_ikp:    cvfrp(op);  ENDCASE
    CASE f_ikg:    cvfrg(op);  ENDCASE
    CASE f_ikl:    cvfrl(op);  ENDCASE
    CASE f_ip:     cvfp(op);   ENDCASE
    CASE f_ig:     cvfg(op);   ENDCASE
    CASE f_il:     cvfl(op);   ENDCASE

    CASE f_jeq:
    CASE f_jne:
    CASE f_jls:
    CASE f_jgr:
    CASE f_jle:
    CASE f_jge:
    CASE f_jeq0:
    CASE f_jne0:
    CASE f_jls0:
    CASE f_jgr0:
    CASE f_jle0:
    CASE f_jge0:     cvfl(op);      ENDCASE

    CASE f_section:  cvsection(op); ENDCASE

    CASE f_modend:   cvf(op); writef("#*n")
                     RETURN

    CASE f_global:   cvglobal(op); ENDCASE

    CASE f_string:   cvstring(op); ENDCASE
    CASE f_const:    cvconst(op);  ENDCASE
    CASE f_static:   cvstatic(op); ENDCASE
    CASE f_lab:      cvlab(op);    ENDCASE

    CASE f_lstr:     cvfl(op);     ENDCASE
    CASE f_entry:    cventry(op);  ENDCASE
  }
} REPEAT

AND cvf(op)   BE wrF(op)

AND cvfp(op)  BE { wrF(op); wrP(pop()) }

AND cvfrp(op) BE { wrF(op); wrR(pop()); wrP(pop()) }

AND cvfg(op)  BE { wrF(op); wrG(pop()) }

AND cvfrg(op) BE { wrF(op); wrR(pop()); wrG(pop()) }

AND cvfrl(op) BE { wrF(op); wrR(pop()); wrL(pop()) }

AND cvfpg(op) BE { wrF(op); wrP(pop()); wrG(pop()) }

AND cvfk(op)  BE { wrF(op); wrK(pop()) }

AND cvfr(op)  BE { wrF(op); wrR(pop()) }

AND cvfw(op)  BE { wrF(op); wrW(pop()) }

AND cvfl(op)  BE { wrF(op); wrL(pop()) }

AND cvswl(op) BE
{ LET n = pop()
  wrF(op)
  wrN(n)
  wrL(pop())
  FOR i = 1 TO n DO wrL(pop())
}

AND cvswb(op) BE
{ LET n = pop()
  wrF(op)
  wrN(n)
  wrL(pop())
  FOR i = 1 TO n DO 
  { wrK(pop())
    wrL(pop())
  }
}

AND cvglobal(op) BE
{ LET n = pop()
  wrF(op)
  wrN(n)
  FOR i = 1 TO n DO
  { wrG(pop())
    wrL(pop())
  }
  wrG(pop())
}

AND cvstring(op) BE
{ LET lab = pop()
  LET n = pop()
  wrF(op)
  wrdL(lab) // just for checking
  wrN(n)
  FOR i = 1 TO n DO wrC(pop())
}

AND cvconst(op) BE
{ LET lab = pop()
  wrF(op)
  wrdL(lab) // just for checking
  wrW(pop())
}

AND cvstatic(op) BE
{ LET lab = pop()
  LET n = pop()
  wrF(op)
  wrdL(lab) // just for checking
  wrN(n)
  FOR i = 1 TO n DO wrW(pop())
}

AND cvlab(op)  BE
{ LET lab = pop()
  wrF(op)
  wrpL(lab) // just for checking
}


AND cvsection(op) BE
{ LET n = pop()
  wrF(op)
  wrN(n)
  FOR i = 1 TO n DO wrT(pop())
}

AND cventry(op) BE
{ LET n = pop()
  wrF(op)
  wrN(n)
  FOR i = 1 TO n DO wrT(pop())
}

AND wrF(x) BE RETURN //writef("F%n*n", x)
AND wrP(x) BE RETURN //writef("P%n*n", x)
AND wrG(x) BE RETURN //writef("G%n*n", x)
AND wrK(x) BE RETURN //writef("K%n*n", x)
AND wrN(x) BE RETURN //writef("N%n*n", x)
AND wrR(x) BE RETURN //writef("R%n*n", x)
AND wrW(x) BE RETURN //writef("W%n*n", x)
AND wrC(x) BE RETURN //writef("C%n*n", x)
AND wrT(x) BE RETURN //writef("T%n*n", x)

AND wrL(lab) BE 
{ LET letter = 'X'
  IF (propv!lab & p_equate) > 0 DO lab := newlab!lab
  IF (propv!lab & p_plab) > 0 DO letter := 'L'
  IF (propv!lab & p_dlab) > 0 DO letter := 'M'
  IF letter='X' DO abort(1111)
  writef("%c%n*n", letter, newlab!lab)
}

AND wrdL(lab) BE // used by STRING CONST STATIC 
{ LET letter = 'X'
  IF (propv!lab & p_equate) > 0 DO lab := newlab!lab
  IF (propv!lab & p_plab) > 0 DO letter := 'L'
  IF (propv!lab & p_dlab) > 0 DO letter := 'M'
  nextdlab := nextdlab+1
  UNLESS letter='M'  & newlab!lab=nextdlab DO
  { writef("wrdL: %c%n  -- should be: M%n*n", letter, newlab!lab, nextdlab)  
    abort(1111)
  }
  writef("%c%n:*n", letter, newlab!lab)
}

AND wrpL(lab) BE // used by LAB
{ LET letter = 'X'
  IF (propv!lab & p_equate) > 0 DO lab := newlab!lab
  IF (propv!lab & p_plab) > 0 DO letter := 'L'
  IF (propv!lab & p_dlab) > 0 DO letter := 'M'
  nextplab := nextplab+1
  UNLESS letter='L'  & newlab!lab=nextplab DO
  { writef("wrdL: %c%n  -- should be: L%n*n", letter, newlab!lab, nextplab)  
    abort(1111)
  }
  writef("%c%n:*n", letter, newlab!lab)
}
