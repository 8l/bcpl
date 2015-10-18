// (c) M. Richards  Copyright 16 August 2000

/*
1/12/2005
Changed to use 11 character section and function names.
Changed argument format to: "TO/K,STATS/S,PROFILE/S,ANALYSIS/S,HELP/S"
The default TO stream for the options STATS, PROFILE and ANALYSIS are
the file names STATS, PROFILE and ANALYSIS, respectively.

16/8/2000
Updated to use sys(Sys_setcount, maxint) to select the slow interpreter
*/

/*
** This program supercedes the old tally command.
**
** The argument format is: "TO/K,ON/S,STATS/S,PROFILE/S,ANALYSIS/S,HELP/S"

** Usage:
**
** preload bcpl                Preload the program to study.
** stats on                    Enable statisticss gathering for just
**                             the next command.
**
** bcpl com/bcpl.b to junk     Execute the command to study.
** 
** interpreter                 Select the fast interpreter (cintasm)
**                             since stats automatically selects
**                             the slow one.
**
** stats stats                 Send instruction frequencies
**                             to file STATS (by default),
**                             or
** stats profile               Send detailed profile info to file
**                             to file PROFILE (by default),
**                             or
** stats analysis              Generate statistical analysis
**                             to file ANALYSIS (by default).
**
** Only one of the STATS, PROFILE or ANALYSIS may be used at a time,
** and TO may only be used with STATS, PROFILE and ANALYSIS.
*/

SECTION "STATS"

GET "libhdr"

MANIFEST { disupb=26; typeupb=8  }

GLOBAL {
s_lpdis:200;   d_lpdis:230
s_spdis:201;   d_spdis:231
s_grds:202;    d_grds:232
s_gwrs:203;    d_gwrs:233
s_kdis:204;    d_kdis:234
s_rfdis:205;   d_rfdis:235
s_rbdis:206;   d_rbdis:236
s_idis:207;    d_idis:237
s_lndis:208;   d_lndis:238
s_lmdis:209;   d_lmdis:239

s_gvecap:210;  d_gvecap:240
s_pvecap:211;  d_pvecap:241
s_gbyt:212;    d_gbyt:242
s_pbyt:213;    d_pbyt:243
s_adds:214;    d_adds:244
s_subs:215;    d_subs:245
s_eops:216;    d_eops:246
s_fv:217;      d_fv:247
s_fcount:218;  d_fcount:248
s_cj:219;      d_cj:249
s_cj0:220;     d_cj0:250
s_swb:221;     d_swb:251
s_swl:222;     d_swl:252
s_ftype:223;   d_ftype:253
s_rtn:224;     d_rtn:254

tostream:260
fcode:270
freq:271
pc:272

stats: 280
profile:281
analysis:282
}

LET start() = VALOF
{ LET argv = VEC 20
  AND tofile = 0
  AND outstream = 0
  AND tallyv = rootnode!rtn_tallyv
  AND oldout = output()

  IF tallyv=0 DO
  { writes("Statistic gathering not available*n")
    RESULTIS 20
  }
   
  UNLESS rdargs("TO/K,ON/S,STATS/S,PROFILE/S,ANALYSIS/S,HELP/S",
                argv, 20) DO
  { writes("Bad arguments for STATS*n")
    RESULTIS 20
  }

  UNLESS argv!1 |                    // ON
         argv!2 |                    // STATS
         argv!3 |                    // PROFILE
         argv!4 DO                   // ANALYSIS
     argv!5 := TRUE

  IF argv!5 DO                       // HELP
  { LET w = writes

    w("*nTypical usage:*n*n")

    w("preload bcpl             Preload the program to study.*n")
    w("stats on                 Enable statistics gathering for*n")
    w("                           just the next command.*n*n")

    w("bcpl com/bcpl.b to junk  Execute the command to study.*n*n")

    w("interpreter              Select the fast interpreter,*n")
    w("                           since stats automatically selects*n")
    w("                           the slow one.*n*n")

    w("stats stats              Send instruction frequencies*n")
    w("                           to file: STATS.*n")
    w("                         or*n")
    w("stats profile            Send detailed profile information*n")
    w("                           to file: PROFILE.*n")
    w("                         or*n")
    w("stats analysis           Generate statistical analysis*n")
    w("                           to file: ANALYSIS.*n*n")

    w("Only one of ON, STATS, PROFILE or ANALYSIS may be specified.*n*n")

    w("The TO option can be used to override the default*n")
    w("destination for the STATS, PROFILE and ANALYSIS options.*n")

    RESULTIS 0
  }

  { LET k = 0
    IF argv!1 DO k := k+1
    IF argv!2 DO k := k+1
    IF argv!3 DO k := k+1
    IF argv!4 DO k := k+1
    IF k>1 DO
    { writef("Only one of ON, STATS, PROFILE or ANALYSIS may be specified*n")
      RESULTIS 0
    }
  }

  IF argv!1 DO                     // ON
  { cli_tallyflag := TRUE
    // Select slow statistics gathering interpreter
    sys(Sys_setcount, maxint)
    writes("Statistics gathering enabled*n")
    RESULTIS 0
  }

  stats    := argv!2               // STATS
  profile  := argv!3               // PROFILE
  analysis := argv!4               // ANALYSIS

  IF stats    DO tofile := "STATS"
  IF profile  DO tofile := "PROFILE"
  IF analysis DO tofile := "ANALYSIS"

  IF argv!0   DO tofile := argv!0  // TO
   
  outstream := findoutput(tofile)
  IF outstream=0 DO { writes("Trouble with file %s*n", tofile)
                      RESULTIS 20
                    }
  selectoutput(outstream)
   
  init_analysis()
  statsout(rootnode!rtn_blklist, tallyv, tallyv!0)
  free_storage()

  UNLESS outstream=oldout DO endwrite()
  selectoutput(oldout)
  RESULTIS 0
}

AND statsout(base, tallyv, upb) BE
{ LET cursect = 0

  // Scan memory
  FOR i = 1 TO upb DO
  { 
    //writef("Scanning location %i6*n", i)
//abort(1000)
    IF profile & (i&3)=0 DO
    { LET name = base + (i>>2)-3
      LET word = name<100 -> 0, name!-1

      IF word=sectword & name%0=11 DO
      { cursect := i - 16
        writef("*n%i6: Section:   %s   Size: %n*n",
                  cursect,        name,      name!-2)
      }
      IF word=entryword & name%0=11 DO
         writef("*n%i6: Function:  %s*n", i-cursect, name)
    }

    IF tallyv!i DO
    { LET f = base%i
      LET basebyte = base<<2
      pc := basebyte + i
      fcode := 0%pc
      freq  := tallyv!i

      IF profile DO
      { writef("+%i5:%i6 ", i-cursect, tallyv!i)
        prinstr(pc, basebyte+cursect)
        newline()
      }

      analyse_instr()
    }

    IF intflag() DO { writef("*n++++ BREAK*n")
                      BREAK
                    }
  }
   
  IF analysis DO { pr_analysis(); RETURN  }

  // Otherwise print a simple frequency table
  IF stats DO
  { writef("*nInstruction frequencies (total executed %n)*n", d_fcount)
   
    FOR i = 0 TO 128 BY 128 FOR j = 0 TO 31 DO
    { newline()
      IF intflag() DO { writef("*n++++ BREAK*n")
                        RETURN
                      }
      FOR k = 0 TO 96 BY 32 DO
      { LET f = i + j + k
        IF f=128 DO newline()
        wrfcode(f)
        writef(" %i7   ", d_fv!f)
      }
    }
  }

  newline()
}

AND wrfcode(f) BE
{ LET s = VALOF SWITCHON f&31 INTO
  { DEFAULT:
    CASE  0: RESULTIS "     -     K   LLP     L    LP    SP    AP     A"
    CASE  1: RESULTIS "     -    KH  LLPH    LH   LPH   SPH   APH    AH"
    CASE  2: RESULTIS "   BRK    KW  LLPW    LW   LPW   SPW   APW    AW"
    CASE  3: RESULTIS "    K3   K3G  K3G1  K3GH   LP3   SP3   AP3  L0P3"
    CASE  4: RESULTIS "    K4   K4G  K4G1  K4GH   LP4   SP4   AP4  L0P4"
    CASE  5: RESULTIS "    K5   K5G  K5G1  K5GH   LP5   SP5   AP5  L0P5"
    CASE  6: RESULTIS "    K6   K6G  K6G1  K6GH   LP6   SP6   AP6  L0P6"
    CASE  7: RESULTIS "    K7   K7G  K7G1  K7GH   LP7   SP7   AP7  L0P7"
    CASE  8: RESULTIS "    K8   K8G  K8G1  K8GH   LP8   SP8   AP8  L0P8"
    CASE  9: RESULTIS "    K9   K9G  K9G1  K9GH   LP9   SP9   AP9  L0P9"
    CASE 10: RESULTIS "   K10  K10G K10G1 K10GH  LP10  SP10  AP10 L0P10"
    CASE 11: RESULTIS "   K11  K11G K11G1 K11GH  LP11  SP11  AP11 L0P11"
    CASE 12: RESULTIS "    LF   S0G  S0G1  S0GH  LP12  SP12  AP12 L0P12"
    CASE 13: RESULTIS "   LF$   L0G  L0G1  L0GH  LP13  SP13 XPBYT     S"
    CASE 14: RESULTIS "    LM   L1G  L1G1  L1GH  LP14  SP14   LMH    SH"
    CASE 15: RESULTIS "   LM1   L2G  L2G1  L2GH  LP15  SP15   BTC  MDIV"
    CASE 16: RESULTIS "    L0    LG   LG1   LGH  LP16  SP16   NOP CHGCO"
    CASE 17: RESULTIS "    L1    SG   SG1   SGH   SYS    S1    A1   NEG"
    CASE 18: RESULTIS "    L2   LLG  LLG1  LLGH   SWB    S2    A2   NOT"
    CASE 19: RESULTIS "    L3    AG   AG1   AGH   SWL    S3    A3  L1P3"
    CASE 20: RESULTIS "    L4   MUL   ADD    RV    ST    S4    A4  L1P4"
    CASE 21: RESULTIS "    L5   DIV   SUB   RV1   ST1   XCH    A5  L1P5"
    CASE 22: RESULTIS "    L6   REM   LSH   RV2   ST2  GBYT  RVP3  L1P6"
    CASE 23: RESULTIS "    L7   XOR   RSH   RV3   ST3  PBYT  RVP4  L2P3"
    CASE 24: RESULTIS "    L8    SL   AND   RV4  STP3   ATC  RVP5  L2P4"
    CASE 25: RESULTIS "    L9   SL$    OR   RV5  STP4   ATB  RVP6  L2P5"
    CASE 26: RESULTIS "   L10    LL   LLL   RV6  STP5     J  RVP7  L3P3"
    CASE 27: RESULTIS "  FHOP   LL$  LLL$   RTN  GOTO    J$ ST0P3  L3P4"
    CASE 28: RESULTIS "   JEQ   JNE   JLS   JGR   JLE   JGE ST0P4  L4P3"
    CASE 29: RESULTIS "  JEQ$  JNE$  JLS$  JGR$  JLE$  JGE$ ST1P3  L4P4"
    CASE 30: RESULTIS "  JEQ0  JNE0  JLS0  JGR0  JLE0  JGE0 ST1P4     -"
    CASE 31: RESULTIS " JEQ0$ JNE0$ JLS0$ JGR0$ JLE0$ JGE0$     -     -"
  }
  LET n = f>>5 & 7
  FOR i = 6*n+1 TO 6*(n+1) DO wrch(s%i)
}

AND prinstr(pc, cursect) BE
{ LET a = 0
  wrfcode(0%pc)
  SWITCHON instrtype(0%pc) INTO
  { DEFAULT:
    CASE '0':                                      RETURN
    CASE '1': a  := gb(pc+1);                      ENDCASE
    CASE '2': a  := gh(pc+1);                      ENDCASE
    CASE '4': a  := gw(pc+1);                      ENDCASE
    CASE 'R': a  := pc+1 + gsb(pc+1) - cursect;    ENDCASE
    CASE 'I': pc := pc+1 + 2*gb(pc+1) & #xFFFFFFFE
              a  := pc + gsh(pc) - cursect;        ENDCASE
  }
  writef(" %n", a)
}

AND gb(pc) = 0%pc

AND gsb(pc) = 0%pc<=127 -> 0%pc, 0%pc-256

AND gsh(pc) = VALOF
{ LET h = gh(pc)
  RESULTIS h<=#x7FFF -> h, h - #x10000
}

AND gh(pc) = VALOF
{ LET w = ?
  LET p = @w  // Designed to work on both Big and Little Ender M/Cs.
  p%0, p%1, p%2, p%3 := 0%pc, 0%(pc+1), 0%pc, 0%(pc+1)
  RESULTIS w & #xFFFF
}

AND gw(pc) = VALOF
{ LET w = ?
  LET p = @w  // Designed to work on both Big and Little Ender M/Cs.
  p%0, p%1, p%2, p%3 := 0%pc, 0%(pc+1), 0%(pc+2), 0%(pc+3)
  RESULTIS w
}

AND instrtype(f) = "?0000000000RI10000000000000RIRI*
                  *124111111111111111110000RIRIRIRI*
                  *12411111111111111111000000RIRIRI*
                  *1242222222222222222200000000RIRI*
                  *124000000000000000BL00000000RIRI*
                  *12400000000000000000000000RIRIRI*
                  *1240000000000020000000000000000?*
                  *124000000000012000000000000000??"%f




AND init_analysis() BE
{ s_lpdis, d_lpdis := getvec(disupb), getvec(disupb)
  s_spdis, d_spdis := getvec(disupb), getvec(disupb)
  s_grds, d_grds := 0, 0
  s_gwrs, d_gwrs := 0, 0
  s_kdis,  d_kdis  := getvec(disupb), getvec(disupb)
  s_rfdis, d_rfdis := getvec(disupb), getvec(disupb)
  s_rbdis, d_rbdis := getvec(disupb), getvec(disupb)
  s_idis,  d_idis  := getvec(disupb), getvec(disupb)
  s_lndis, d_lndis := getvec(disupb), getvec(disupb)
  s_lmdis, d_lmdis := getvec(disupb), getvec(disupb)

  FOR i = 0 TO disupb DO
  { s_lpdis!i, d_lpdis!i := 0, 0
    s_spdis!i, d_spdis!i := 0, 0
    s_kdis!i,  d_kdis!i  := 0, 0
    s_rfdis!i, d_rfdis!i := 0, 0
    s_rbdis!i, d_rbdis!i := 0, 0
    s_idis!i,  d_idis!i  := 0, 0
    s_lndis!i, d_lndis!i := 0, 0
    s_lmdis!i, d_lmdis!i := 0, 0
  }

  s_gvecap, d_gvecap := 0, 0
  s_pvecap, d_pvecap := 0, 0
  s_gbyt,   d_gbyt   := 0, 0
  s_pbyt,   d_pbyt   := 0, 0
  s_adds,   d_adds   := 0, 0
  s_subs,   d_subs   := 0, 0
  s_eops,   d_eops   := 0, 0
   
  s_fv, d_fv := getvec(255), getvec(255)
  FOR i = 0 TO 255 DO s_fv!i, d_fv!i := 0, 0

  s_fcount, d_fcount := 0, 0
  s_cj,  d_cj  := 0, 0
  s_cj0, d_cj0 := 0, 0
  s_swb, d_swb := 0, 0
  s_swl, d_swl := 0, 0

  s_ftype, d_ftype := getvec(typeupb), getvec(typeupb)
  FOR i = 0 TO typeupb DO s_ftype!i, d_ftype!i := 0, 0
   
  s_rtn, d_rtn := 0, 0
}

AND free_storage() BE
{ freevec(s_lpdis);   freevec(d_lpdis)
  freevec(s_spdis);   freevec(d_spdis)
  freevec(s_kdis);    freevec(d_kdis)
  freevec(s_rfdis);   freevec(d_rfdis)
  freevec(s_rbdis);   freevec(d_rbdis)
  freevec(s_idis);    freevec(d_idis)
  freevec(s_lndis);   freevec(d_lndis)
  freevec(s_lmdis);   freevec(d_lmdis)

  freevec(s_fv);      freevec(d_fv)
  freevec(s_ftype);   freevec(d_ftype)
}

AND pr_analysis() BE
{ writef("*n*nInstructions  %i7(%i5)*n", d_fcount, s_fcount)
   
  FOR i = 0 TO 128 BY 128 FOR j = 0 TO 31 DO
  { newline()
    FOR k = 0 TO 96 BY 32 DO
    { LET f = i + j + k
      IF f=128 DO newline()
      writef("    ")
      wrfcode(f)
      writef("    ")
    }
    newline()
    FOR k = 0 TO 96 BY 32 DO
    { LET f = i + j + k
      writef(" %i7(%i4)", d_fv!f, s_fv!f)
    }
  }
  writes("*n*n     GVECAP        PVECAP         GBYT          PBYT*n")
     writef("%i7(%i4) ", d_gvecap, s_gvecap)
     writef("%i7(%i4) ", d_pvecap, s_pvecap)
     writef("%i7(%i4) ", d_gbyt,  s_gbyt)
     writef("%i7(%i4) ", d_pbyt,  s_pbyt)
   
  writes("*n*n     ADDS          SUBS           EOPS*n")
     writef("%i7(%i4) ", d_adds, s_adds)
     writef("%i7(%i4) ", d_subs, s_subs)
     writef("%i7(%i4) ", d_eops, s_eops)

  writes("*n*n      SWB           SWL*n")
     writef("%i7(%i4) ", d_swb, s_swb)
     writef("%i7(%i4) ", d_swl, s_swl)
   
  writes("*n*n      CJ            CJ0*n")
     writef("%i7(%i4) ", d_cj,  s_cj)
     writef("%i7(%i4) ", d_cj0, s_cj0)
   
  writes("*n*nOperand distributions")
   
  writes("*n*n       LP            SP            K*n")
  FOR i = 0 TO disupb DO
  { writef("%i7(%i4) ", d_lpdis!i, s_lpdis!i)
    writef("%i7(%i4) ", d_spdis!i, s_spdis!i)
    writef("%i7(%i4) ", d_kdis!i,  s_kdis!i)
    wrdisrange(i)
    newline()
  }

  writes("*n*n       LG            SG            RTN*n")
     writef("%i7(%i4) ", d_grds, s_grds)
     writef("%i7(%i4) ", d_gwrs, s_gwrs)
     writef("%i7(%i4) ", d_rtn,  s_rtn)

  writes(
 "*n*n       LN            LM            RF            RB            I*n")
  FOR i = 0 TO disupb
  { writef("%i7(%i4) ", d_lndis!i, s_lndis!i)
    writef("%i7(%i4) ", d_lmdis!i, s_lmdis!i)
    writef("%i7(%i4) ", d_rfdis!i, s_rfdis!i)
    writef("%i7(%i4) ", d_rbdis!i, s_rbdis!i)
    writef("%i7(%i4) ", d_idis!i,  s_idis!i)
    wrdisrange(i)
    newline()
  }
  writes ("*nInstruction types*n*n")
  FOR i = 0 TO 8 DO
    writef(" %c  %i8(%i4)  %i4*n",
            "?0124RIBL"%(i+1), d_ftype!i, s_ftype!i,
            ("012352200"%(i+1)-'0')*s_ftype!i)
}


AND analyse_instr() BE
{ LET a = 0
  s_fv!fcode, d_fv!fcode := s_fv!fcode+1, d_fv!fcode+freq
  s_fcount, d_fcount := s_fcount+1, d_fcount+freq

  SWITCHON instrtype(fcode) INTO
  { DEFAULT:
    CASE '?': s_ftype!0, d_ftype!0 := s_ftype!0+1, d_ftype!0+freq
              ENDCASE
    CASE '0': s_ftype!1, d_ftype!1 := s_ftype!1+1, d_ftype!1+freq
              ENDCASE
    CASE '1': s_ftype!2, d_ftype!2 := s_ftype!2+1, d_ftype!2+freq
              ENDCASE
    CASE '2': s_ftype!3, d_ftype!3 := s_ftype!3+1, d_ftype!3+freq
              ENDCASE
    CASE '4': s_ftype!4, d_ftype!4 := s_ftype!4+1, d_ftype!4+freq
              ENDCASE
    CASE 'R': s_ftype!5, d_ftype!5 := s_ftype!5+1, d_ftype!5+freq
              a  := pc+1 + gsb(pc+1);
              TEST a>=pc THEN updis(s_rfdis, d_rfdis, a-pc)
                         ELSE updis(s_rbdis, d_rbdis, pc-a)
              ENDCASE
    CASE 'I': s_ftype!6, d_ftype!6 := s_ftype!6+1, d_ftype!6+freq
              a := gb(pc+1)
              updis(s_idis, d_idis, 255-a)
              a := pc+1 + 2*a & #xFFFFFFFE
              a  := a + gsh(a); 
              TEST a>=pc THEN updis(s_rfdis, d_rfdis, a-pc)
                         ELSE updis(s_rbdis, d_rbdis, pc-a)
              ENDCASE
    CASE 'B': s_ftype!7, d_ftype!7 := s_ftype!7+1, d_ftype!7+freq
              ENDCASE
    CASE 'L': s_ftype!8, d_ftype!8 := s_ftype!8+1, d_ftype!8+freq
              ENDCASE
  }

  SWITCHON fcode INTO
  { DEFAULT:
    CASE   0:
    CASE   1:
    CASE   2: //   BRK
              RETURN
    CASE   3: //    K3
    CASE   4: //    K4
    CASE   5: //    K5
    CASE   6: //    K6
    CASE   7: //    K7
    CASE   8: //    K8
    CASE   9: //    K9
    CASE  10: //   K10
    CASE  11: //   K11
              call(fcode); RETURN
    CASE  12: //    LF
    CASE  13: //   LF$
              RETURN
    CASE  14: //    LM
              numb(-gb(pc+1)); RETURN
    CASE  15: //   LM1
    CASE  16: //    L0
    CASE  17: //    L1
    CASE  18: //    L2
    CASE  19: //    L3
    CASE  20: //    L4
    CASE  21: //    L5
    CASE  22: //    L6
    CASE  23: //    L7
    CASE  24: //    L8
    CASE  25: //    L9
    CASE  26: //   L10
              numb(fcode-16); RETURN
    CASE  27: //  FHOP
              RETURN
    CASE  28: //   JEQ
    CASE  29: //  JEQ$
              cjump(); RETURN
    CASE  30: //  JEQ0
    CASE  31: // JEQ0$
              cjump0(); RETURN
              RETURN
    CASE  32: //     K
              call(gb(pc+1)); RETURN
    CASE  33: //    KH
              call(gh(pc+1)); RETURN
    CASE  34: //    KW
              call(gw(pc+1)); RETURN
    CASE  35: //   K3G
    CASE  36: //   K4G
    CASE  37: //   K5G
    CASE  38: //   K6G
    CASE  39: //   K7G
    CASE  40: //   K8G
    CASE  41: //   K9G
    CASE  42: //  K10G
    CASE  43: //  K11G
              grd(); call(fcode-32); RETURN
    CASE  44: //   S0G
              grd(); vecwr(); RETURN
    CASE  45: //   L0G
              grd(); vecrd(); RETURN
    CASE  46: //   L1G
    CASE  47: //   L2G
              grd(); add(); numb(fcode-45); vecrd(); RETURN
    CASE  48: //    LG
              grd(); RETURN
    CASE  49: //    SG
              gwr(); RETURN
    CASE  50: //   LLG
              RETURN
    CASE  51: //    AG
              grd(); add(); RETURN
    CASE  52: //   MUL
    CASE  53: //   DIV
    CASE  54: //   REM
    CASE  55: //   XOR
             eop(); RETURN
    CASE  56: //    SL
    CASE  57: //   SL$
    CASE  58: //    LL
    CASE  59: //   LL$
              RETURN
    CASE  60: //   JNE
    CASE  61: //  JNE$
              cjump(); RETURN
    CASE  62: //  JNE0
    CASE  63: // JNE0$
              cjump0(); RETURN
    CASE  64: //   LLP
    CASE  65: //  LLPH
    CASE  66: //  LLPW
              RETURN
    CASE  67: //  K3G1
    CASE  68: //  K4G1
    CASE  69: //  K5G1
    CASE  70: //  K6G1
    CASE  71: //  K7G1
    CASE  72: //  K8G1
    CASE  73: //  K9G1
    CASE  74: // K10G1
    CASE  75: // K11G1
              grd(); call(fcode-64); RETURN
    CASE  76: //  S0G1
              grd(); vecwr(); RETURN
    CASE  77: //  L0G1
              grd(); vecrd(); RETURN
    CASE  78: //  L1G1
    CASE  79: //  L2G1
              grd(); vecrd(); add(); numb(fcode-77); RETURN
    CASE  80: //   LG1
              grd(); RETURN
    CASE  81: //   SG1
              gwr(); RETURN
    CASE  82: //  LLG1
              RETURN
    CASE  83: //   AG1
              grd(); add(); RETURN
    CASE  84: //   ADD
              add(); RETURN
    CASE  85: //   SUB
              sub(); RETURN
    CASE  86: //   LSH
    CASE  87: //   RSH
    CASE  88: //   AND
    CASE  89: //    OR
              eop(); RETURN
    CASE  90: //   LLL
    CASE  91: //  LLL$
              RETURN
    CASE  92: //   JLS
    CASE  93: //  JLS$
              cjump(); RETURN
    CASE  94: //  JLS0
    CASE  95: // JLS0$
              cjump0(); RETURN
    CASE  96: //     L
              numb(gb(pc+1)); RETURN
    CASE  97: //    LH
              numb(gh(pc+1)); RETURN
    CASE  98: //    LW
              numb(gw(pc+1)); RETURN
    CASE  99: //  K3GH
    CASE 100: //  K4GH
    CASE 101: //  K5GH
    CASE 102: //  K6GH
    CASE 103: //  K7GH
    CASE 104: //  K8GH
    CASE 105: //  K9GH
    CASE 106: // K10GH
    CASE 107: // K11GH
              grd(); call(fcode-96); RETURN
    CASE 108: //  S0GH
              grd(); vecwr(); RETURN
    CASE 109: //  L0GH
              grd(); vecrd(); RETURN
    CASE 110: //  L1GH
    CASE 111: //  L2GH
              grd(); numb(fcode-109); add(); vecrd(); RETURN
    CASE 112: //   LGH
              grd(); RETURN
    CASE 113: //   SGH
              gwr(); RETURN
    CASE 114: //  LLGH
              RETURN
    CASE 115: //   AGH
              grd(); add(); RETURN
    CASE 116: //    RV
              vecrd(); RETURN
    CASE 117: //   RV1
    CASE 118: //   RV2
    CASE 119: //   RV3
    CASE 120: //   RV4
    CASE 121: //   RV5
    CASE 122: //   RV6
              numb(fcode-116); add(); vecrd(); RETURN
    CASE 123: //   RTN
              s_rtn, d_rtn := s_rtn+1, d_rtn+freq
              RETURN
    CASE 124: //   JGR
    CASE 125: //  JGR$
              cjump(); RETURN
    CASE 126: //  JGR0
    CASE 127: // JGR0$
              cjump0(); RETURN
    CASE 128: //    LP
              locrd(gb(pc+1)); RETURN
    CASE 129: //   LPH
              locrd(gh(pc+1)); RETURN
    CASE 130: //   LPW
              locrd(gw(pc+1)); RETURN
    CASE 131: //   LP3
    CASE 132: //   LP4
    CASE 133: //   LP5
    CASE 134: //   LP6
    CASE 135: //   LP7
    CASE 136: //   LP8
    CASE 137: //   LP9
    CASE 138: //  LP10
    CASE 139: //  LP11
    CASE 140: //  LP12
    CASE 141: //  LP13
    CASE 142: //  LP14
    CASE 143: //  LP15
    CASE 144: //  LP16
              locrd(fcode-128); RETURN
    CASE 145: //   SYS
              RETURN
    CASE 146: //   SWB
              s_swb, d_swb := s_swb+1, d_swb+freq
              RETURN
    CASE 147: //   SWL
              s_swl, d_swl := s_swl+1, d_swl+freq
              RETURN
    CASE 148: //    ST
              vecwr(); RETURN
    CASE 149: //   ST1
    CASE 150: //   ST2
    CASE 151: //   ST3
              numb(fcode-148); add(); vecwr(); RETURN
    CASE 152: //  STP3
    CASE 153: //  STP4
    CASE 154: //  STP5
              locrd(fcode-149); add(); vecwr(); RETURN
    CASE 155: //  GOTO
              RETURN
    CASE 156: //   JLE
    CASE 157: //  JLE$
              cjump(); RETURN
    CASE 158: //  JLE0
    CASE 159: // JLE0$
              cjump0(); RETURN
    CASE 160: //    SP
              locwr(gb(pc+1)); RETURN
    CASE 161: //   SPH
              locwr(gh(pc+1)); RETURN
    CASE 162: //   SPW
              locwr(gw(pc+1)); RETURN
    CASE 163: //   SP3
    CASE 164: //   SP4
    CASE 165: //   SP5
    CASE 166: //   SP6
    CASE 167: //   SP7
    CASE 168: //   SP8
    CASE 169: //   SP9
    CASE 170: //  SP10
    CASE 171: //  SP11
    CASE 172: //  SP12
    CASE 173: //  SP13
    CASE 174: //  SP14
    CASE 175: //  SP15
    CASE 176: //  SP16
              locwr(fcode-160); RETURN
    CASE 177: //    S1
    CASE 178: //    S2
    CASE 179: //    S3
    CASE 180: //    S4
              numb(fcode-176); sub(); RETURN
    CASE 181: //   XCH
              RETURN
    CASE 182: //  GBYT
              s_gbyt, d_gbyt := s_gbyt+1, d_gbyt+freq
              RETURN
    CASE 183: //  PBYT
              s_pbyt, d_pbyt := s_pbyt+1, d_pbyt+freq
              RETURN
    CASE 184: //   ATC
    CASE 185: //   ATB
              RETURN
    CASE 186: //     J
    CASE 187: //    J$
              RETURN
    CASE 188: //   JGE
    CASE 189: //  JGE$
              cjump(); RETURN
    CASE 190: //  JGE0
    CASE 191: // JGE0$
              cjump0(); RETURN
    CASE 192: //    AP
              locrd(gb(pc+1)); add(); RETURN
    CASE 193: //   APH
              locrd(gh(pc+1)); add(); RETURN
    CASE 194: //   APW
              locrd(gw(pc+1)); add(); RETURN
    CASE 195: //   AP3
    CASE 196: //   AP4
    CASE 197: //   AP5
    CASE 198: //   AP6
    CASE 199: //   AP7
    CASE 200: //   AP8
    CASE 201: //   AP9
    CASE 202: //   AP10
    CASE 203: //   AP11
    CASE 204: //   AP12
              locrd(fcode-192); add(); RETURN
    CASE 205: // XPBYT
              s_pbyt, d_pbyt := s_pbyt+1, d_pbyt+freq
              RETURN
    CASE 206: //   LMH
              numb(-gh(pc+1)); RETURN
    CASE 207: //   BTC
              RETURN
    CASE 208: //   NOP
              RETURN
    CASE 209: //    A1
    CASE 210: //    A2
    CASE 211: //    A3
    CASE 212: //    A4
    CASE 213: //    A5
              numb(fcode-208); add(); RETURN
    CASE 214: //  RVP3
    CASE 215: //  RVP4
    CASE 216: //  RVP5
    CASE 217: //  RVP6
    CASE 218: //  RVP7
              locrd(fcode-211); add(); vecrd(); RETURN
    CASE 219: // ST0P3
    CASE 220: // ST0P4
              locrd(fcode-216); vecwr(); RETURN
    CASE 221: // ST1P3
    CASE 222: // ST1P4
              locrd(fcode-218); numb(1); add(); vecwr(); RETURN
    CASE 223: //     -
              RETURN
    CASE 224: //     A
              numb(gb(pc+1)); add(); RETURN
    CASE 225: //    AH
              numb(gh(pc+1)); add(); RETURN
    CASE 226: //    AW
              numb(gw(pc+1)); add(); RETURN
    CASE 227: //  L0P3
    CASE 228: //  L0P4
    CASE 229: //  L0P5
    CASE 230: //  L0P6
    CASE 231: //  L0P7
    CASE 232: //  L0P8
    CASE 233: //  L0P9
    CASE 234: // L0P10
    CASE 235: // L0P11
    CASE 236: // L0P12
              locrd(fcode-224); vecrd(); RETURN
    CASE 237: //     S
              numb(gb(pc+1)); sub(); RETURN
    CASE 238: //    SH
              numb(gh(pc+1)); sub(); RETURN
    CASE 239: //  MDIV
    CASE 240: // CHGCO
              RETURN
    CASE 241: //   NEG
    CASE 242: //   NOT
              eop(); RETURN
    CASE 243: //  L1P3
    CASE 244: //  L1P4
    CASE 245: //  L1P5
    CASE 246: //  L1P6
              numb(1); locrd(fcode-240); add(); vecrd(); RETURN
    CASE 247: //  L2P3
    CASE 248: //  L2P4
    CASE 249: //  L2P5
              numb(2); locrd(fcode-244); add(); vecrd(); RETURN
    CASE 250: //  L3P3
    CASE 251: //  L3P4
              numb(3); locrd(fcode-247); add(); vecrd(); RETURN
    CASE 252: //  L4P3
    CASE 253: //  L4P4
              numb(4); locrd(fcode-249); add(); vecrd(); RETURN
    CASE 254: //     -
              RETURN
    CASE 255: //     -
  }
}

// Number
AND numb(n) BE TEST n<0 THEN updis(s_lmdis, d_lmdis, -n)
                        ELSE updis(s_lndis, d_lndis, n)
// Local read
AND locrd(n) BE updis(s_lpdis, d_lpdis, n)

// Local write
AND locwr(n) BE updis(s_spdis, d_spdis, n)

// Global read
AND grd() BE s_grds, d_grds := s_grds+1, d_grds+freq

//Global write
AND gwr() BE s_gwrs, d_gwrs := s_gwrs+1, d_gwrs+freq

// Indirect read
AND vecrd() BE s_gvecap, d_gvecap := s_gvecap+1, d_gvecap+freq

// Indirect write
AND vecwr() BE s_pvecap, d_pvecap := s_pvecap+1, d_pvecap+freq

// Add
AND add() BE s_adds, d_adds := s_adds+1, d_adds+freq

// Subtract
AND sub() BE s_subs, d_subs := s_subs+1, d_subs+freq

// Other expression operators
AND eop() BE s_eops, d_eops := s_eops+1, d_eops+freq

// Conditional jump (not on zero)
AND cjump() BE s_cj, d_cj := s_cj+1, d_cj+freq

// Conditional jump on zero
AND cjump0() BE s_cj0, d_cj0 := s_cj0+1, d_cj0+freq

// Function call
AND call(k) BE updis(s_kdis, d_kdis, k)

// Accumulate offset (or value) size statistics
AND updis(s_v, d_v, val) BE
{ s_v!disupb, d_v!disupb := s_v!disupb+1, d_v!disupb+freq
  IF val<0 RETURN
  IF val<=16 DO  { s_v!val, d_v!val := s_v!val+1, d_v!val+freq
                   RETURN
                 }
  IF val<32 DO   { s_v!17, d_v!17 := s_v!17+1, d_v!17+freq
                   RETURN
                 }
  IF val<64 DO   { s_v!18, d_v!18 := s_v!18+1, d_v!18+freq
                   RETURN
                 }
  IF val<128 DO  { s_v!19, d_v!19 := s_v!19+1, d_v!19+freq
                   RETURN
                 }
  IF val<256 DO  { s_v!20, d_v!20 := s_v!20+1, d_v!20+freq
                   RETURN
                 }
  IF val<512 DO  { s_v!21, d_v!21 := s_v!21+1, d_v!21+freq
                   RETURN
                 }
  IF val<1024 DO { s_v!22, d_v!22 := s_v!22+1, d_v!22+freq
                   RETURN
                 }
  IF val<2048 DO { s_v!23, d_v!23 := s_v!23+1, d_v!23+freq
                   RETURN
                 }
  IF val<4096 DO { s_v!24, d_v!24 := s_v!24+1, d_v!24+freq
                   RETURN
                 }
  s_v!25, d_v!25 := s_v!25+1, d_v!25+freq
}

AND wrdisrange(i) BE
{ IF i<=16 DO { writef("%n", i);     RETURN }
  IF i=17  DO { writes("17-31");     RETURN }
  IF i=18  DO { writes("32-63");     RETURN }
  IF i=19  DO { writes("64-127");    RETURN }
  IF i=20  DO { writes("128-255");   RETURN }
  IF i=21  DO { writes("256-511");   RETURN }
  IF i=22  DO { writes("512-1023");  RETURN }
  IF i=23  DO { writes("1024-2047"); RETURN }
  IF i=24  DO { writes("2048-4095"); RETURN }
  IF i=25  DO { writes("4096-");     RETURN }
  writes("Total")
}

