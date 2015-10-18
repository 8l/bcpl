/***********************************************************************
**             (C) Copyright 1982  TRIPOS Research Group              **
**            University of Cambridge Computer Laboratory             **
************************************************************************

                               ########  ########
                               ########  ########
                                  ##     ##
                                  ##     ######
                                  ##     ##
                                  ##     ##
                               ########  ##
                               ########  ##

********************************************************************************
** Version Date       Name            Remarks                                 **
**                                                                            **
**         14-Feb-02 M.Richards       Modified for Cintpos                    **
**         29-Jul-04 M.Richards       Made if exists work under Cintpos       **
**                                                                            **
*******************************************************************************/

SECTION "IF"

GET "libhdr"


LET start() BE
{ LET v = VEC 80
  LET sw = FALSE

  UNLESS rdargs(",NOT/S,WARN/S,ERROR/S,FAIL/S,EQ/K,VAREQ/K,EXISTS/K", v, 80)
    GOTO badargs

//sawritef("if: returncode=%n reason=%n*n", cli_returncode, cli_result2)

  sw := VALOF
  { IF v!2 & cli_returncode>= 5 RESULTIS TRUE
    IF v!3 & cli_returncode>=10 RESULTIS TRUE
    IF v!4 & cli_returncode>=20 RESULTIS TRUE

    IF v!5 DO
    { UNLESS v!0 GOTO badargs
      IF compstring(v!5, v!0)=0 RESULTIS TRUE
    }

    IF v!6 DO
    { LET val = getlogname(v!6)
      UNLESS v!0 GOTO badargs
      IF val & compstring(val, v!0)=0 RESULTIS TRUE
    }

    IF v!7 DO
    { LET s = sys(Sys_filemodtime, v!7)
      RESULTIS s -> TRUE, FALSE
    }

    RESULTIS FALSE
  }

  IF v!1 DO sw := NOT sw

  UNLESS sw DO
  { LET ch = unrdch() -> rdch(), '*n'
    UNTIL ch='*n' | ch=endstreamch DO ch := rdch()
  }

  stop(0)

badargs:
  writes("Bad args*n")
  stop(20)
}
