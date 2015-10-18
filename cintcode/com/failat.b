/***********************************************************************
**             (C) Copyright 1982  TRIPOS Research Group              **
**            University of Cambridge Computer Laboratory             **
************************************************************************
*                                                                      *
*                                                                      *
*       ########    ####    ########  ##          ####    ########     *
*       ########   ######   ########  ##         ######   ########     *
*       ##        ##    ##     ##     ##        ##    ##     ##        *
*       ######    ########     ##     ##        ########     ##        *
*       ##        ##    ##     ##     ##        ##    ##     ##        *
*       ##        ##    ##     ##     ##        ##    ##     ##        *
*       ##        ##    ##  ########  ########  ##    ##     ##        *
*       ##        ##    ##  ########  ########  ##    ##     ##        *
*                                                                      *
************************************************************************
**    Author:  Adrian Aylward                                 1978    **
**                                                                    **
** Modifications:                                                     **
** 18 Feb 02   Martin Richards     Modified for Cintpos               **
**                                                                    **
***********************************************************************/

SECTION "FAILAT"

GET "libhdr"

LET start() = VALOF
{ LET argv = VEC 10

  UNLESS rdargs("FAILLEVEL/N", argv, 10) DO
  { writef("Bad args for FAILAT*n")
    RESULTIS 20
  }

  TEST argv!0
  THEN cli_faillevel := !(argv!0)
  ELSE writef("Current fail level is %n*n", cli_faillevel)

  RESULTIS 0
}
