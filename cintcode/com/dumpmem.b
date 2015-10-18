/*******************************************************************************
**                  (C) Copyright Ford Motor Company Ltd.                     **
**                       Process Control Systems Dept.                        **
********************************************************************************

      ######    ##    ##  ##    ##  #######   ##    ##  ########  ##    ## 
      #######   ##    ##  ###  ###  ########  ###  ###  ########  ###  ### 
      ##    ##  ##    ##  ########  ##    ##  ########  ##        ######## 
      ##    ##  ##    ##  ## ## ##  #######   ## ## ##  ######    ## ## ## 
      ##    ##  ##    ##  ##    ##  ##        ##    ##  ##        ##    ## 
      ##    ##  ##    ##  ##    ##  ##        ##    ##  ##        ##    ## 
      #######   ########  ##    ##  ##        ##    ##  ########  ##    ## 
      ######     ######   ##    ##  ##        ##    ##  ########  ##    ## 

********************************************************************************
** Version Date       Name            Remarks                                 **
**                                                                            **
**   1.0   29-Oct-03  Martin Richards Initial Release                         **
**                                                                            **
*******************************************************************************/

SECTION "DUMPMEM"

GET "libhdr"

LET start() BE
{ LET argv = VEC 8

  UNLESS rdargs("ON/S,OFF/S", argv, 8) DO
  { writef("Bad argument for DUMPMEM*n")
    stop(20)
  }

  IF argv!0 DO
  { rootnode!rtn_dumpflag := TRUE
    writef("Cintpos Memory dumping enabled*n")
    RETURN
  } 

  IF argv!1 DO
  { rootnode!rtn_dumpflag := FALSE
    writef("Cintpos Memory dumping disabled*n")
    RETURN
  } 

  UNLESS argv!0 | argv!1 DO
  { LET datv = VEC 2
    rtn_abortcode!rootnode := 0
    sys(0, -2) // Cause memory to be dumped into DUMP.mem
    //writef("Cintpos memory dumped to DUMP.mem*n")
    RETURN
  }
}
