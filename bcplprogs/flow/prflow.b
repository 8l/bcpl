SECTION "prflow"

GET "b2flow.h"

LET start() = VALOF
{ LET argv = VEC 20
   LET flowin = ?
   AND flowprn = 0
   LET sysprint = output()
   IF rdargs("FROM,TO/K", argv, 20)=0 DO
   { writes("Bad args for prflow*n")
      RESULTIS 20
   }
   IF argv!0=0 DO argv!0 := "FLOW"
   IF argv!1=0 DO argv!1 := "**"
   flowin := findinput(argv!0)
   IF flowin=0 DO
   { writef("Trouble with file %s*n", argv!0)
      RESULTIS 20
   }
   flowprn := findoutput(argv!1)
   
   IF flowprn=0 DO
   { writef("Trouble with file %s*n", argv!1)
      RESULTIS 20
   }
   
   writef("Converting %s to %s*n", argv!0, argv!1)
   selectinput(flowin)
   selectoutput(flowprn)
   scan()
   endread()
   UNLESS flowprn=sysprint DO endwrite()
   selectoutput(sysprint)
   writef("Conversion complete*n")
   RESULTIS 0
}

AND rdn() = VALOF
{ LET a, ch, sign = 0, ?, '+'

   ch := rdch() REPEATWHILE ch='*n' | ch='*n'

   IF ch='#' DO
   { // skip comment
     UNTIL ch='*n' | ch=endstreamch DO ch := rdch()
     RESULTIS rdn()
   }

   IF ch=endstreamch RESULTIS 0

   IF ch='-' DO { sign := '-'; ch := rdch() }

   WHILE '0'<=ch<='9' DO { a := 10*a + ch - '0'; ch := rdch()  }

   IF sign='-' RESULTIS -a
   RESULTIS a
}


AND scan() BE
{ LET flowop = rdn()
  LET op, opk, opl, opvk, opvg, opvl, opgl, len = 0, 0, 0, 0, 0, 0, 0, -1
  LET opvn = 0
  LET opv, opvv, opvvv, opvvvv, opvvvvv = 0, 0, 0, 0, 0

  SWITCHON flowop INTO

  { DEFAULT:         writef("Bad FLOW op %n*n", flowop); LOOP

    CASE 0:          RETURN
      
    CASE s_section:  op , len := "SECTION", rdn(); ENDCASE
    CASE s_needs:    op , len := "NEEDS",   rdn(); ENDCASE

    CASE s_ld:       opvv := "LD";            ENDCASE

    CASE s_string:   writef("STRING V%n ", rdn())
                     len := rdn()
                     ENDCASE

    CASE s_table:    writef("TABLE V%n ", rdn())
                   { LET n = rdn()
                     writef(" %n", n)
                     FOR i = 1 TO n DO writef(" K%n", rdn())
                     ENDCASE
                   }

    CASE s_true:     opv  := "TRUE";          ENDCASE
    CASE s_false:    opv  := "FALSE";         ENDCASE
    CASE s_query:    opv  := "FALSE";         ENDCASE

    CASE s_llv:      opvv := "LLV";           ENDCASE

    CASE s_stind:    opvv := "STIND";         ENDCASE

    CASE s_rv:       opvv:= "RV";            ENDCASE

    CASE s_vecap:    opvvv  := "VECAP";         ENDCASE
    CASE s_mult:     opvvv  := "MUL";           ENDCASE
    CASE s_div:      opvvv  := "DIV";           ENDCASE
    CASE s_rem:      opvvv  := "REM";           ENDCASE
    CASE s_plus:     opvvv  := "ADD";           ENDCASE
    CASE s_minus:    opvvv  := "SUB";           ENDCASE
    CASE s_eq:       opvvv  := "EQ";            ENDCASE
    CASE s_ne:       opvvv  := "NE";            ENDCASE
    CASE s_ls:       opvvv  := "LS";            ENDCASE
    CASE s_gr:       opvvv  := "GR";            ENDCASE
    CASE s_le:       opvvv  := "LE";            ENDCASE
    CASE s_ge:       opvvv  := "GE";            ENDCASE
    CASE s_lshift:   opvvv  := "LSH";           ENDCASE
    CASE s_rshift:   opvvv  := "RSH";           ENDCASE
    CASE s_logand:   opvvv  := "LOGAND";        ENDCASE
    CASE s_logor:    opvvv  := "LOGOR";         ENDCASE
    CASE s_eqv:      opvvv  := "EQV";           ENDCASE
    CASE s_neqv:     opvvv  := "NEQV";          ENDCASE
    CASE s_not:      opvv  := "NOT";            ENDCASE
    CASE s_neg:      opvv  := "NEG";            ENDCASE
    CASE s_abs:      opvv  := "ABS";            ENDCASE

    CASE s_jt:       opvl := "JT";              ENDCASE
    CASE s_jf:       opvl := "JF";              ENDCASE

    CASE s_goto:     opv := "GOTO";             ENDCASE

    CASE s_lab:      opl := "LAB";              ENDCASE

    CASE s_fnap:     writef("FNAP V%n", rdn())
                     writef(" V%n", rdn())
                     { LET n = rdn()
                       writef(" %n", n)
                       FOR i = 1 TO n DO writef(" V%n", rdn())
                     }
                     ENDCASE

    CASE s_rtap:     writef("RTAP V%n", rdn())
                     { LET n = rdn()
                       writef(" %n", n)
                       FOR i = 1 TO n DO writef(" V%n", rdn())
                     }
                     ENDCASE

    CASE s_fnrn:     opv := "FNRN";          ENDCASE
    CASE s_rtrn:     op  := "RTRN";          ENDCASE

    CASE s_endproc:  op  := "ENDPROC";       ENDCASE // no args now

    CASE s_jump:     opl := "JUMP";         ENDCASE

    CASE s_finish:   op  := "FINISH";        ENDCASE

    CASE s_switchon: { LET var = rdn()
                       LET n = rdn()
                       LET defvar = rdn()
                       writef("SWITCHON V%n %n L%n*n", var, n, defvar)
                       FOR i = 1 TO n DO
                       { LET k = rdn()
                         LET lab = rdn()
                         writef("K%n L%n*n", k, lab)
                       }
                       LOOP
                     }

    CASE s_getbyte:  opvvv  := "GETBYTE";       ENDCASE
    CASE s_putbyte:  opvvv  := "PUTBYTE";       ENDCASE

    CASE s_entry:    writef("*nENTRY L%n", rdn())
                     len := rdn()
                     ENDCASE

    CASE s_name:     writef("NAME V%n", rdn())
                     len := rdn()
                     ENDCASE


    CASE s_manifest: opvk := "MANIFEST";      ENDCASE
    CASE s_static:   opvk := "STATIC";        ENDCASE
    CASE s_local:    opv  := "LOCAL";         ENDCASE
    CASE s_arg:      opvn := "ARG";           ENDCASE
    CASE s_vec:      opvk := "VEC";           ENDCASE

    CASE s_global:   opvg := "GLOBAL";        ENDCASE
    CASE s_globinit: opgl := "GLOBINIT";      ENDCASE

    CASE s_sys:      opvvvvv := "SYS";        ENDCASE
    CASE s_chgco:    opvv    := "CHGCO";      ENDCASE
    CASE s_mdiv:     opvvvv  := "MDIV";       ENDCASE
  }

  IF op      DO writef("%S",                     op)
  IF opk     DO writef("%S K%n",                 opk,    rdn())
  IF opl     DO writef("%S L%n",                 opl,    rdn())
  IF opvk    DO writef("%S V%n K%n",             opvk,   rdn(), rdn())
  IF opvg    DO writef("%S V%n G%n",             opvg,   rdn(), rdn())
  IF opvl    DO writef("%S V%n L%n",             opvl,   rdn(), rdn())
  IF opgl    DO writef("%S G%n L%n",             opgl,   rdn(), rdn())
  IF opvn    DO writef("%S V%n %n",              opvn,   rdn(), rdn())
  IF opv     DO writef("%S V%n",                 opv,    rdn())
  IF opvv    DO writef("%S V%n V%n",             opvv,   rdn(), rdn())
  IF opvvv   DO writef("%S V%n V%n V%n",         opvvv,  rdn(), rdn(), rdn())
  IF opvvvv  DO writef("%S V%n V%n V%n V%n",     opvvvv, 
                                           rdn(), rdn(), rdn(), rdn())
  IF opvvvvv DO writef("%S V%n V%n V%n V%n V%n", opvvvvv,
                                           rdn(), rdn(), rdn(), rdn(), rdn())

  IF len>=0 DO { writef(" *"", len)
                 FOR i = 1 TO len DO
                 { LET ch = rdn()
                   IF i REM 15 = 0 DO newline()
                   TEST 32<=ch<=127 THEN writef("%c", ch)
                                    ELSE writef("?")
                 }
                 wrch('*"')
               }

  newline()
} REPEAT

