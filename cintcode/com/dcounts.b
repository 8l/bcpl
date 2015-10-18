/*
This program outputs the non zero entries of the debugging count table.
The table normally has an upperbound of 511 and is allocated and cleared
when the system starts up. Counts can be incremented by incdcount(i) defined
in cintsys.c or cintpos.c, or by the BCPL call sys(Sys_incdcount).

Implemented by Martin Richards (c) March 2012
*/

SECTION "dcounts"

GET "libhdr"

LET start() = VALOF
{ LET v = rtn_dcountv!rootnode
  LET layout = 0
  writef("*nDump of non-zero Debug Counts*n")

  FOR i = 0 TO v!0 DO
  { LET val = v!i
    IF val DO
    { IF layout MOD 5 = 0 DO newline()
      TEST -10000000<val<10000000
      THEN writef(" %i5:%10i", i, val)
      ELSE writef(" %i5:  %8x", i, val)
      layout := layout+1
    }
  }
  newline()
}
