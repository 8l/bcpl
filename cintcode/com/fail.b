/***********************************************************************
**             (C) Copyright 1982  TRIPOS Research Group              **
**            University of Cambridge Computer Laboratory             **
************************************************************************
*                                                                      *
*                                                                      *
*                 ########    ####    ########  ##                     *
*                 ########   ######   ########  ##                     *
*                 ##        ##    ##     ##     ##                     *
*                 ######    ########     ##     ##                     *
*                 ##        ##    ##     ##     ##                     *
*                 ##        ##    ##     ##     ##                     *
*                 ##        ##    ##  ########  ########               *
*                 ##        ##    ##  ########  ########               *
*                                                                      *
************************************************************************
**    Author:  Martin Richards                                2004    **
**                                                                    **
** Modifications:                                                     **
**                                                                    **
***********************************************************************/

SECTION "FAIL"

GET "libhdr"

LET start() = VALOF
{ LET rc = 0
  LET argv = VEC 10

  UNLESS rdargs("RC/N,REASON/N", argv, 10) DO
  { writef("Bad args for FAIL*n")
    stop(20,0)
  }

  result2 := 0
  IF argv!0 DO rc      := !(argv!0)
  IF argv!1 DO result2 := !(argv!1)
  RESULTIS rc
}
