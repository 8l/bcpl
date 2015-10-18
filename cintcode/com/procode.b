/*
This program converts the numeric representation of OCODE
into a more readable form.

26/07/10
Updated to include the OF, floating point and op:=
extensions
*/

SECTION "procode"

GET "libhdr"
GET "bcplfecg"

LET start() = VALOF
{ LET argv = VEC 20
  LET ocodein = ?
  AND ocodeprn = 0
  LET sysprint = output()
  IF rdargs("FROM,TO/K", argv, 20)=0 DO
  { writes("Bad args for procode*n")
    RESULTIS 20
  }
  IF argv!0=0 DO argv!0 := "ocode"
  IF argv!1=0 DO argv!1 := "**"
  ocodein := findinput(argv!0)
  IF ocodein=0 DO
  { writef("Trouble with file %s*n", argv!0)
    RESULTIS 20
  }
  ocodeprn := findoutput(argv!1)
   
  IF ocodeprn=0 DO
  { writef("Trouble with file %s*n", argv!1)
    RESULTIS 20
  }
   
  writef("Converting %s to %s*n", argv!0, argv!1)
  selectinput(ocodein)
  selectoutput(ocodeprn)
  scan()
  endread()
  UNLESS ocodeprn=sysprint DO endwrite()
  selectoutput(sysprint)
  writef("Conversion complete*n")
  RESULTIS 0
}

// argument may be of form Ln
AND rdn() = VALOF
{ LET a, ch, sign = 0, ?, '+'

  ch := rdch() REPEATWHILE ch='*S' | ch='*n'

  IF ch=endstreamch RESULTIS 0

  IF ch='-' DO { sign := '-'; ch := rdch() }

  WHILE '0'<=ch<='9' DO { a := 10*a + ch - '0'; ch := rdch()  }

  IF sign='-' RESULTIS -a
  RESULTIS a
}


AND scan() BE
{ LET ocodeop = rdn()
  LET op0, op1, op2, op1l, len = 0, 0, 0, 0, -1
  //LET opf2, ops2 = 0, 0
  LET ops2 = 0

  SWITCHON ocodeop INTO

  { DEFAULT:         writef("Bad OCODE op %n*n", ocodeop)
                     abort(1000)
                     LOOP

    CASE 0:          RETURN
      
    CASE s_section:  op0, len := "SECTION", rdn(); ENDCASE
    CASE s_needs:    op0, len := "NEEDS",   rdn(); ENDCASE

    CASE s_lp:       op1 := "LP";            ENDCASE
    CASE s_lg:       op1 := "LG";            ENDCASE
    CASE s_ln:       op1 := "LN";            ENDCASE

//    CASE s_fnum:     opf2 := "FNUM";         ENDCASE

    CASE s_lstr:     op0, len := "LSTR", rdn(); ENDCASE

    CASE s_true:     op0 := "TRUE";          ENDCASE
    CASE s_false:    op0 := "FALSE";         ENDCASE

    CASE s_llp:      op1 := "LLP";           ENDCASE
    CASE s_llg:      op1 := "LLG";           ENDCASE

    CASE s_sp:       op1 := "SP";            ENDCASE
    CASE s_sg:       op1 := "SG";            ENDCASE

    CASE s_lf:       op1l := "LF";           ENDCASE
    CASE s_ll:       op1l := "LL";           ENDCASE
    CASE s_lll:      op1l := "LLL";          ENDCASE
    CASE s_sl:       op1l := "SL";           ENDCASE
      
    CASE s_selld:    op2 := "SELLD";         ENDCASE
    CASE s_selst:    ops2 := "SELST";        ENDCASE

    CASE s_stind:    op0 := "STIND";         ENDCASE

    CASE s_rv:       op0 := "RV";            ENDCASE

    CASE s_float:    op0 := "FLOAT";         ENDCASE
    CASE s_fix:      op0 := "FIX";           ENDCASE
    CASE s_fabs:     op0 := "FABS";          ENDCASE
    CASE s_fmul:     op0 := "FMUL";          ENDCASE
    CASE s_fdiv:     op0 := "FDIV";          ENDCASE
    CASE s_fadd:     op0 := "FADD";          ENDCASE
    CASE s_fsub:     op0 := "FSUB";          ENDCASE
    CASE s_fneg:     op0 := "FNEG";          ENDCASE
    CASE s_feq:      op0 := "FEQ";           ENDCASE
    CASE s_fne:      op0 := "FNE";           ENDCASE
    CASE s_fls:      op0 := "FLS";           ENDCASE
    CASE s_fgr:      op0 := "FGR";           ENDCASE
    CASE s_fle:      op0 := "FLE";           ENDCASE
    CASE s_fge:      op0 := "FGE";           ENDCASE

    CASE s_mul:      op0 := "MUL";           ENDCASE
    CASE s_div:      op0 := "DIV";           ENDCASE
    CASE s_rem:      op0 := "REM";           ENDCASE
    CASE s_add:      op0 := "ADD";           ENDCASE
    CASE s_sub:      op0 := "SUB";           ENDCASE
    CASE s_eq:       op0 := "EQ";            ENDCASE
    CASE s_ne:       op0 := "NE";            ENDCASE
    CASE s_ls:       op0 := "LS";            ENDCASE
    CASE s_gr:       op0 := "GR";            ENDCASE
    CASE s_le:       op0 := "LE";            ENDCASE
    CASE s_ge:       op0 := "GE";            ENDCASE
    CASE s_lshift:   op0 := "LSHIFT";        ENDCASE
    CASE s_rshift:   op0 := "RSHIFT";        ENDCASE
    CASE s_logand:   op0 := "LOGAND";        ENDCASE
    CASE s_logor:    op0 := "LOGOR";         ENDCASE
    CASE s_eqv:      op0 := "EQV";           ENDCASE
    CASE s_neqv:     op0 := "NEQV";          ENDCASE
    CASE s_not:      op0 := "NOT";           ENDCASE
    CASE s_neg:      op0 := "NEG";           ENDCASE
    CASE s_abs:      op0 := "ABS";           ENDCASE

    CASE s_jt:       op1l := "JT";           ENDCASE
    CASE s_jf:       op1l := "JF";           ENDCASE

    CASE s_goto:     op0 := "GOTO";          ENDCASE

    CASE s_lab:      op1l := "LAB";          ENDCASE

    CASE s_query:    op0 := "QUERY";         ENDCASE

    CASE s_stack:    op1 := "STACK";         ENDCASE

    CASE s_store:    op0 := "STORE";         ENDCASE

    CASE s_entry:    { LET l = rdn()
                       len := rdn()
                       writef("ENTRY L%n", l)
                       ENDCASE
                     }

    CASE s_save:     op1 := "SAVE";          ENDCASE

    CASE s_fnap:     op1 := "FNAP";          ENDCASE
    CASE s_rtap:     op1 := "RTAP";          ENDCASE

    CASE s_fnrn:     op0 := "FNRN";          ENDCASE
    CASE s_rtrn:     op0 := "RTRN";          ENDCASE

    CASE s_endproc:  op0 := "ENDPROC";       ENDCASE // no args now

    CASE s_res:      op1l := "RES";          ENDCASE
    CASE s_jump:     op1l := "JUMP";         ENDCASE

    CASE s_rstack:   op1 := "RSTACK";        ENDCASE

    CASE s_finish:   op0 := "FINISH";        ENDCASE

    CASE s_switchon: { LET n = rdn()
                       writef("SWITCHON %n L%n*n", n, rdn())
                       FOR i = 1 TO n DO
                       { writef("%i8   ", rdn())
                         writef("L%n*n", rdn())
                       }
                       newline()
                       LOOP
                     }

    CASE s_getbyte:  op0 := "GETBYTE";       ENDCASE
    CASE s_putbyte:  op0 := "PUTBYTE";       ENDCASE

    CASE s_global:   { LET n = rdn()
                       writef("GLOBAL %n*n", n)
                       FOR i = 1 TO n DO
                       { writef("%i8   ", rdn())
                         writef("L%n*n", rdn())
                       }
                       newline()
                       LOOP
                     }


    CASE s_datalab:  op1l := "DATALAB";      ENDCASE
    CASE s_itemn:    op1  := "ITEMN";        ENDCASE
  }

  UNLESS op0=0   DO writef("%S",     op0)
  UNLESS op1=0   DO writef("%S %n",  op1,  rdn())
  UNLESS op2=0   DO writef("%S %n %n",  op2,  rdn(), rdn())
  UNLESS op1l=0  DO writef("%S L%n", op1l, rdn())
  ///UNLESS opf2=0  DO writef("%S %n %n", opf2, rdn(), rdn())
  UNLESS ops2=0  DO
  { LET s = sfname(rdn())
    writef("%s %s %n %n", ops2, s, rdn(), rdn())
  }
  IF len>=0 DO { // Write a string of len characters
                 writef(" %n ", len)
                 FOR i = 1 TO len DO
                 { LET ch = rdn()
                   IF i REM 15 = 0 DO newline()
                   TEST 32<=ch<=127 THEN writef(" '%c'", ch)
                                    ELSE writef(" %i3 ", ch)
                 }
               }

  newline()
//abort(1000)
} REPEAT

AND sfname(sfop) = VALOF SWITCHON sfop INTO
{ DEFAULT:        RESULTIS "UNKNOWN"

  CASE 0:         RESULTIS "NULL"
  CASE sf_vecap:  RESULTIS "VECAP"
  CASE sf_fmul:   RESULTIS "FMUL"
  CASE sf_fdiv:   RESULTIS "FDIV"
  CASE sf_fadd:   RESULTIS "FADD"
  CASE sf_fsub:   RESULTIS "FSUB"
  CASE sf_mul:    RESULTIS "MUL"
  CASE sf_div:    RESULTIS "DIV"
  CASE sf_rem:    RESULTIS "REM"
  CASE sf_add:    RESULTIS "ADD"
  CASE sf_sub:    RESULTIS "SUB"
  CASE sf_lshift: RESULTIS "LSHIFT"
  CASE sf_rshift: RESULTIS "RSHIFT"
  CASE sf_logand: RESULTIS "LOGAND"
  CASE sf_logor:  RESULTIS "LOGOR"
  CASE sf_eqv:    RESULTIS "EQV"
  CASE sf_neqv:   RESULTIS "NEQV"
}


