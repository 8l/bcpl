SECTION "sial2bred"

GET "libhdr"

MANIFEST
{
// sial opcodes and directives
f_lp=     1
f_lg=     2
f_ll=     3

f_llp=    4
f_llg=    5
f_lll=    6
f_lf=     7
f_lw=     8

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
f_skg=    29
f_xst=    30

f_k=      35
f_kpg=    36

f_neg=    37
f_not=    38
f_abs=    39

f_xdiv=   40
f_xrem=   41
f_xsub=   42

f_mul=    45
f_div=    46
f_rem=    47
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
f_eqv=    70

f_gbyt=   74
f_xgbyt=  75
f_pbyt=   76
f_xpbyt=  77

f_swb=    78
f_swl=    79

f_xch=    80
f_atb=    81
f_atc=    82
f_bta=    83
f_btc=    84
f_atblp=  85
f_atblg=  86
f_atbl=   87

f_j=      90
f_rtn=    91
f_goto=   92

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
f_jge0m=  112

f_brk=    120
f_nop=    121
f_chgco=  122
f_mdiv=   123
f_sys=    124

f_section=  130
f_modstart= 131
f_modend=   132
f_global=   133
f_string=   134
f_const=    135
f_static=   136
f_mlab=     137
f_lab=      138
f_lstr=     139
f_entry=    140
}

GLOBAL {
sialin:   200
sialout:  201
stdin:    202
stdout:   203

rdf:      210
rdp:      211
rdg:      212
rdk:      213
rdh:      214
rdw:      215
rdl:      216
rdd:      217
rdc:      218
rdcode:   219
op:       220

scan:     230
cvf:      231
cvfp:     232
cvfg:     233
cvfk:     234

cvfw:     236
cvfl:     237
cvfd:     238

prevL:    240
}

LET start() = VALOF
{ LET argv = VEC 20

  sialout := 0
  stdout := output()
  IF rdargs("FROM,TO/K", argv, 20)=0 DO
  { writes("Bad args for cvsial*n")
    RESULTIS 20
  }
  IF argv!0=0 DO argv!0 := "bcpl.sial"
  IF argv!1=0 DO argv!1 := "bcpl.bred"
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
{ op := rdf()

  SWITCHON op INTO

  { DEFAULT:       error("Bad op %n*n", op); LOOP

    CASE -1:       RETURN
      
    CASE f_lp:     cvfp(); ENDCASE
    CASE f_lg:     cvfg(); ENDCASE
    CASE f_ll:     cvfl(); ENDCASE

    CASE f_llp:    cvfp(); ENDCASE
    CASE f_llg:    cvfg(); ENDCASE
    CASE f_lll:    cvfl(); ENDCASE
    CASE f_lf:     cvfl(); ENDCASE
    CASE f_lw:     cvfm(); ENDCASE

    CASE f_l:      cvfk(); ENDCASE
    CASE f_lm:     cvfk(); ENDCASE

    CASE f_sp:     cvfp(); ENDCASE
    CASE f_sg:     cvfg(); ENDCASE
    CASE f_sl:     cvfl(); ENDCASE

    CASE f_ap:     cvfp(); ENDCASE
    CASE f_ag:     cvfg(); ENDCASE
    CASE f_a:      cvfk(); ENDCASE
    CASE f_s:      cvfk(); ENDCASE

    CASE f_lkp:    cvfkp(); ENDCASE
    CASE f_lkg:    cvfkg(); ENDCASE
    CASE f_rv:     cvf(); ENDCASE
    CASE f_rvp:    cvfp(); ENDCASE
    CASE f_rvk:    cvfk(); ENDCASE
    CASE f_st:     cvf(); ENDCASE
    CASE f_stp:    cvfp(); ENDCASE
    CASE f_stk:    cvfk(); ENDCASE
    CASE f_stkp:   cvfkp(); ENDCASE
    CASE f_skg:    cvfkg(); ENDCASE
    CASE f_xst:    cvf(); ENDCASE

    CASE f_k:      cvfp(); ENDCASE
    CASE f_kpg:    cvfpg(); ENDCASE

    CASE f_neg:    cvf(); ENDCASE
    CASE f_not:    cvf(); ENDCASE
    CASE f_abs:    cvf(); ENDCASE

    CASE f_xdiv:   cvf(); ENDCASE
    CASE f_xrem:   cvf(); ENDCASE
    CASE f_xsub:   cvf(); ENDCASE

    CASE f_mul:    cvf(); ENDCASE
    CASE f_div:    cvf(); ENDCASE
    CASE f_rem:    cvf(); ENDCASE
    CASE f_add:    cvf(); ENDCASE
    CASE f_sub:    cvf(); ENDCASE

    CASE f_eq:     cvf(); ENDCASE
    CASE f_ne:     cvf(); ENDCASE
    CASE f_ls:     cvf(); ENDCASE
    CASE f_gr:     cvf(); ENDCASE
    CASE f_le:     cvf(); ENDCASE
    CASE f_ge:     cvf(); ENDCASE
    CASE f_eq0:    cvf(); ENDCASE
    CASE f_ne0:    cvf(); ENDCASE
    CASE f_ls0:    cvf(); ENDCASE
    CASE f_gr0:    cvf(); ENDCASE
    CASE f_le0:    cvf(); ENDCASE
    CASE f_ge0:    cvf(); ENDCASE

    CASE f_lsh:    cvf(); ENDCASE
    CASE f_rsh:    cvf(); ENDCASE
    CASE f_and:    cvf(); ENDCASE
    CASE f_or:     cvf(); ENDCASE
    CASE f_xor:    cvf(); ENDCASE
    CASE f_eqv:    cvf(); ENDCASE

    CASE f_gbyt:   cvf();  ENDCASE
    CASE f_xgbyt:  cvf(); ENDCASE
    CASE f_pbyt:   cvf();  ENDCASE
    CASE f_xpbyt:  cvf(); ENDCASE

    CASE f_swb:       cvswb(); ENDCASE
    CASE f_swl:       cvswl(); ENDCASE

    CASE f_xch:    cvf(); ENDCASE
    CASE f_atb:    cvf(); ENDCASE
    CASE f_atc:    cvf(); ENDCASE
    CASE f_bta:    cvf(); ENDCASE
    CASE f_btc:    cvf(); ENDCASE
    CASE f_atblp:  cvfp(); ENDCASE
    CASE f_atblg:  cvfg(); ENDCASE
    CASE f_atbl:   cvfk(); ENDCASE

    CASE f_j:      cvfl(); ENDCASE
    CASE f_rtn:    cvf(); ENDCASE
    CASE f_goto:   cvf(); ENDCASE

    CASE f_ikp:    cvfkp(); ENDCASE
    CASE f_ikg:    cvfkg(); ENDCASE
    CASE f_ikl:    cvfkl(); ENDCASE
    CASE f_ip:     cvfp();   ENDCASE
    CASE f_ig:     cvfg();   ENDCASE
    CASE f_il:     cvfl();   ENDCASE

    CASE f_jeq:    cvfl(); ENDCASE
    CASE f_jne:    cvfl(); ENDCASE
    CASE f_jls:    cvfl(); ENDCASE
    CASE f_jgr:    cvfl(); ENDCASE
    CASE f_jle:    cvfl(); ENDCASE
    CASE f_jge:    cvfl(); ENDCASE
    CASE f_jeq0:   cvfl(); ENDCASE
    CASE f_jne0:   cvfl(); ENDCASE
    CASE f_jls0:   cvfl(); ENDCASE
    CASE f_jgr0:   cvfl(); ENDCASE
    CASE f_jle0:   cvfl(); ENDCASE
    CASE f_jge0:   cvfl(); ENDCASE
    CASE f_jge0m:  cvfm(); ENDCASE

    CASE f_brk:    cvf(); ENDCASE
    CASE f_nop:    cvf(); ENDCASE
    CASE f_chgco:  cvf(); ENDCASE
    CASE f_mdiv:   cvf(); ENDCASE
    CASE f_sys:    cvf(); ENDCASE

    CASE f_section:  cvfs(); ENDCASE
    CASE f_modstart: prevL:=0; cvf(); ENDCASE
    CASE f_modend:   cvf(); ENDCASE
    CASE f_global:   cvglobal(); ENDCASE
    CASE f_string:   cvstring(); ENDCASE
    CASE f_const:    cvconst(); ENDCASE
    CASE f_static:   cvstatic(); ENDCASE
    CASE f_mlab:     cvfm(); ENDCASE
    CASE f_lab:      cvfl(); ENDCASE
    CASE f_lstr:     cvfm(); ENDCASE
    CASE f_entry:    cventry(); ENDCASE
  }
} REPEAT

AND cvf()   BE   wrF(op)
AND cvfp()  BE { wrF(op); wrP(rdp()) }
AND cvfkp() BE { wrF(op); wrK(rdk()); wrP(rdp()) }
AND cvfg()  BE { wrF(op); wrG(rdg()) }
AND cvfkg() BE { wrF(op); wrK(rdk()); wrG(rdg()) }
AND cvfkl() BE { wrF(op); wrK(rdk()); wrL(rdl()) }
AND cvfpg() BE { wrF(op); wrP(rdp()); wrG(rdg()) }
AND cvfk()  BE { wrF(op); wrK(rdk()) }
AND cvfw()  BE { wrF(op); wrW(rdw()) }
AND cvfl()  BE { wrF(op); wrL(rdl()) }
AND cvfm()  BE { wrF(op); wrM(rdm()) }

AND cvswl() BE
{ LET n = rdk()
  LET l = rdl()
  wrF(op); wrK(n); wrL(l)
  FOR i = 1 TO n DO wrL(rdl())
}

AND cvswb() BE
{ LET n = rdk()
  LET l = rdl()
  wrF(op); wrK(n); wrL(l)
  FOR i = 1 TO n DO 
  { LET k = rdk()
    LET l = rdl()
    wrK(k); wrL(l)
  }
}

AND cvglobal() BE
{ LET n = rdk()
  wrF(op); wrK(n)
  FOR i = 1 TO n DO
  { LET g = rdg()
    LET n = rdl()
    wrG(g); wrL(n)
  }
  wrG(rdg())
}

AND cvstring() BE
{ LET lab = rdm()
  LET n = rdk()
  wrF(op); wrM(lab); wrK(n)
  FOR i = 1 TO n DO wrC(rdc())
}

AND cvconst() BE
{ LET lab = rdm()
  LET w = rdw()
  wrF(op); wrM(lab); wrW(w)
}

AND cvstatic() BE
{ LET lab = rdl()
  LET n = rdk()
  wrF(op); wrL(lab); wrK(n)
  FOR i = 1 TO n DO wrW(rdw())
}

AND cvfs(s) BE
{ LET n = rdk()
  wrF(op); wrK(n)
  FOR i = 1 TO n DO wrC(rdc())
}

AND cventry() BE
{ LET n = rdk()
  wrF(op); wrK(n)
  FOR i = 1 TO n DO wrC(rdc())
}

AND wrF(n) BE wrOp(n, 'F')
AND wrP(n) BE wrI(n, 'P')
AND wrG(n) BE wrI(n, 'G')
AND wrL(n) BE wrI(n, 'L')
AND wrM(n) BE wrI(n, 'M')
AND wrC(n) BE wrI(n, 'C')
AND wrK(n) BE wrI(n, 'K')
AND wrW(n) BE wrI(n, 'W')

AND wrV(n) BE TEST 0<=n<=127 THEN wrch(n)
                             ELSE { wrch(128+(n&127)); wrW(n>>7) }

AND wrI(n, letter) BE RETURN // Ingnore   writef("%c%n*n", letter, n)

AND wrLab(n) BE { wrV(64+n-prevL); prevL := n }

AND wrOp(n) BE wrch(n)


