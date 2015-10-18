/*
This is the header file for mcsystest.b

written by Martin Richards (c) February 2008
*/

GET "libhdr"
GET "mc.h"

MANIFEST {
 A=mc_a
 B=mc_b
 C=mc_c
 D=mc_d
 E=mc_e
 F=mc_f

 a1=1; a2; a3
 // Initial setting of arguments
 arg1=10; arg2=20; arg3=30
 v1=1; v2; v3; v4; v5
 // Initial setting of first five local variables
 var1=10001;var2=10002;var3=10003;var4=10004;var5=10005

 G1=999  // Global numbers
 G2=998
 M1=99   // Locations in Cintcode memory
 M2=98
}

GLOBAL {
  testno : ug
  currtestno
  testcount
  failcount

  tabv     // tabv is a table assembled in the static area
           // with label tablab. It will be pointed to by
           // register B and will have a m/c address which is
           // multiple of 8. The ith location of the table
           // (ie tabv!i) will hold 1000+i
  tablab
  tabaddr  // The m/c address of tabv
  default_mcdebug
  fnstart
  fnend
  mcrname

  // The main test functions

  testADD_AND_OR_SUB_XOR
  testADDC_SUBC_R_Mem
  testADDC_SUBC_RorMem_R
  testADDC_SUBC_RorMem_K
  testCALL_RET
  testCDQ
  testMUL_UMUL
  testDIV_UDIV
  testJMP_CMP_Jcc_SETcc
  testLEA
  testMV
  testMVB_MVH
  testMVSXB_MVSXH_MVZXB_MVZXH
  testNEG_NOT_INC_DEC
  testPOP_PUSH
  testLSH_RSH
  testXCHG

  ag999    // This will hold the m/c address of g999

  g999: 999
}

