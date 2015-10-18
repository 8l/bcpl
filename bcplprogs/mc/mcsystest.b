/*
This is a systematic test program for MC packages.

Written by Martin Richards (c) April 2008
*/

SECTION "mcsystest"

GET "mcsystest.h"

LET start() = VALOF
{ LET argv = VEC 50
  // Load the dynamic code generation package
  LET mcseg = 0
  LET mcb = 0

  UNLESS rdargs("TESTNO/n,D/n", argv, 50)

  testno := 0
  IF argv!0 DO testno := !(argv!0)

  default_mcdebug := 0
  IF argv!1 DO default_mcdebug := !(argv!1)

  mcseg := globin(loadseg("mci386"))

  UNLESS mcseg DO
  { writef("Trouble with MC package: mci386*n")
    GOTO fin
  }

  // Create an MC instance for 1000 functions with a data space
  // of 100,000 words and code space of 1,000,000 words.
  mcb := mcInit(1000, 100_000, 1_000_000)

  UNLESS mcb DO
  { writef("Unable to create an mci386 instance*n")
    GOTO fin
  } 

  mc := 0          // Currently no selected MC instance
  mcSelect(mcb)

  currtestno := 100
  testcount := 0
  failcount := 0

  mcK(mc_debug, default_mcdebug)

  mcK(mc_alignd, 8)
  tablab := mcNextlab()
  mcL(mc_dlab, tablab)
  //mcComment("Start of tabv*n")
  tabv := mc+mcDatap()/4
  tabaddr := rootnode!rtn_mc0 + 4*tabv
//writef("tabv = %n %x8 tabaddr=%x8*n", tabv, tabv, tabaddr)
  mcK(mc_debug, #b0000)
  FOR i = 0 TO 1000 DO mcK(mc_datak, 1000+i)

  mcK(mc_debug, default_mcdebug)

  // Compile the tests

  testADD_AND_OR_SUB_XOR()

  testADDC_SUBC_R_Mem(0, -1)

  testADDC_SUBC_R_Mem(-1, -1)
  testADDC_SUBC_R_Mem( 0, -1)
  testADDC_SUBC_R_Mem( 0, 0)
  testADDC_SUBC_R_Mem( 0, 1)
  testADDC_SUBC_R_Mem( 3, #x80000000)

  testADDC_SUBC_RorMem_R(-1, -1)
  testADDC_SUBC_RorMem_R( 0, -1)
  testADDC_SUBC_RorMem_R( 0, 0)
  testADDC_SUBC_RorMem_R( 0, 1)
  testADDC_SUBC_RorMem_R( 3, #x80000000)

  testADDC_SUBC_RorMem_K(-1, -1)
  testADDC_SUBC_RorMem_K( 0, -1)
  testADDC_SUBC_RorMem_K( 0, 0)
  testADDC_SUBC_RorMem_K( 0, 1)
  testADDC_SUBC_RorMem_K( 3, #x80000000)

  testCALL_RET(A, F, 111, 222, 123, 111+222-123)

  testCDQ(   0,  0)
  testCDQ( 123,  0)
  testCDQ(  -1, -1)
  testCDQ(-123, -1)

  testMUL_UMUL(mc_mul,  #x0000007B, #x00000002, #x00000000, #x000000F6)
  testMUL_UMUL(mc_umul, #x0000007B, #x00000002, #x00000000, #x000000F6)
  testMUL_UMUL(mc_mul,  #x0000007B, #xFFFFFFFE, #xFFFFFFFF, #xFFFFFF0A)
  testMUL_UMUL(mc_umul, #x0000007B, #xFFFFFFFE, #x0000007A, #xFFFFFF0A)

  testDIV_UDIV(mc_udiv, #x000000A9, #x87654321, #x00000100, #x00000021, #xA9876543)
  testDIV_UDIV(mc_udiv, #xFFFFABCD, #x12345678, #xFFFFF000, #x0DF12678, #xFFFFBBCD)
  testDIV_UDIV(mc_div,  #xFFFFFFA9, #x87654321, #xFFFFFF00, #xFFFFFF21, #x56789ABC)
  testDIV_UDIV(mc_div,  #xFFFFFFA9, #x87654321, #x00000100, #xFFFFFF21, #xa9876544)

  testJMP_CMP_Jcc_SETcc()

  testLEA()

  testMV()

  testMVB_MVH()
  testMVSXB_MVSXH_MVZXB_MVZXH()
  testNEG_NOT_INC_DEC()
  testPOP_PUSH()
  testLSH_RSH(mc_lsh, #x12345678, 0, #x12345678)
  testLSH_RSH(mc_lsh, #x12345678, 1, #x2468ACF0)
  testLSH_RSH(mc_lsh, #x12345678, 4, #x23456780)
  testLSH_RSH(mc_rsh, #x12345678, 0, #x12345678)
  testLSH_RSH(mc_rsh, #x12345678, 1, #x091A2B3C)
  testLSH_RSH(mc_rsh, #x12345678, 4, #x01234567)

  testXCHG()

  writef("*n%n test%-%ps compiled*n", currtestno-100)


  // Now run the compiled tests

  FOR fno = 101 TO currtestno DO
  { LET res = 0
    IF fno=testno DO writef("Calling F%n(10, 20, 30)*n", fno)
    res := mcCall(fno, arg1, arg2, arg3)
    IF fno=testno DO writef("   => %n*n", fno)
    IF res DO
    { writef("Test %n failed, res = %n %10b*n", fno, res, res)
      failcount := failcount+1
    }
    testcount := testcount+1
    IF fno=testno BREAK
  }

  writef("*n%n test%-%ps completed, %n failed*n*n", testcount, failcount)

fin:
  IF mcseg DO unloadseg(mcseg)  
  RESULTIS 0
}

AND fnstart(mess, a, b, c, d, e, f, g, h, i, j, k) BE
{ currtestno := currtestno+1

  mcComment("*nTest %i2: ", currtestno) 
  mcComment(mess, a, b, c, d, e, f, g, h, i, j, k) 

  mcKKK(mc_entry, currtestno, 3, 1000)

  // Initialise the registers
  mcRK(mc_mv, A, 0)          // A = 0
  mcRL(mc_mv, B, 1)          // B = 1 
  mcRK(mc_mv, C, 2)          // C = 2
  mcRK(mc_mv, D, 3)          // D = 3
  mcRK(mc_mv, E, 4)          // E = 4
  mcRK(mc_mv, F, 5)          // F = 5

  FOR i = 1 TO 5 DO mcVK(mc_mv, i, 10000+i)

  IF testno = currtestno DO
  { mcK(mc_debug, #b1111)
    mcComment("Test %i2: ", currtestno)
    mcComment(mess, a, b, c, d, e, f, g, h, i, j, k)
  }
}

AND fnend() BE
{ IF testno = currtestno DO mcK(mc_debug, default_mcdebug)
  mcF(mc_rtn)
}

AND mcrname(r) = VALOF SWITCHON r INTO
{ 
  DEFAULT:   writef("mcname(%n): Bad MC register*n", r)
             RESULTIS "?"
  CASE mc_a: RESULTIS "A"
  CASE mc_b: RESULTIS "B"
  CASE mc_c: RESULTIS "C"
  CASE mc_d: RESULTIS "D"
  CASE mc_e: RESULTIS "E"
  CASE mc_f: RESULTIS "F"
}

.

SECTION "mcsystest1"


GET "mcsystest.h"

LET testADD_AND_OR_SUB_XOR() BE
{ testOp_R_Mem("mc_add", mc_add, A, F, 111,        0, 111+0)
  testOp_R_Mem("mc_add", mc_add, A, F, 222,        1, 222+1)
  testOp_R_Mem("mc_add", mc_add, A, F, 333,       -1, 333-1)
  testOp_R_Mem("mc_add", mc_add, A, F, 444,       10, 444+10)
  testOp_R_Mem("mc_add", mc_add, A, F, 555,      400, 555+400)
  testOp_R_Mem("mc_add", mc_add, A, F, 666,     -400, 666-400)
  testOp_R_Mem("mc_add", mc_add, A, F, 777, -1000000, 777-1000000)
  testOp_R_Mem("mc_add", mc_add, A, F, 888,  1000000, 888+1000000)

  testOp_R_Mem("mc_add", mc_add, F, A, 111,        0, 111+0)
  testOp_R_Mem("mc_add", mc_add, F, A, 222,        1, 222+1)
  testOp_R_Mem("mc_add", mc_add, F, A, 333,       -1, 333-1)
  testOp_R_Mem("mc_add", mc_add, F, A, 444,       10, 444+10)
  testOp_R_Mem("mc_add", mc_add, F, A, 555,      400, 555+400)
  testOp_R_Mem("mc_add", mc_add, F, A, 666,     -400, 666-400)
  testOp_R_Mem("mc_add", mc_add, F, A, 777, -1000000, 777-1000000)
  testOp_R_Mem("mc_add", mc_add, F, A, 888,  1000000, 888+1000000)

  testOp_R_Mem("mc_sub", mc_sub, A, F, 111,        0, 111-0)
  testOp_R_Mem("mc_sub", mc_sub, A, F, 222,        1, 222-1)
  testOp_R_Mem("mc_sub", mc_sub, A, F, 333,       -1, 333+1)
  testOp_R_Mem("mc_sub", mc_sub, A, F, 444,       10, 444-10)
  testOp_R_Mem("mc_sub", mc_sub, A, F, 555,      400, 555-400)
  testOp_R_Mem("mc_sub", mc_sub, A, F, 666,     -400, 666+400)
  testOp_R_Mem("mc_sub", mc_sub, A, F, 777, -1000000, 777+1000000)
  testOp_R_Mem("mc_sub", mc_sub, A, F, 888,  1000000, 888-1000000)

  testOp_R_Mem("mc_sub", mc_sub, F, A, 111,        0, 111-0)
  testOp_R_Mem("mc_sub", mc_sub, F, A, 222,        1, 222-1)
  testOp_R_Mem("mc_sub", mc_sub, F, A, 333,       -1, 333+1)
  testOp_R_Mem("mc_sub", mc_sub, F, A, 444,       10, 444-10)
  testOp_R_Mem("mc_sub", mc_sub, F, A, 555,      400, 555-400)
  testOp_R_Mem("mc_sub", mc_sub, F, A, 666,     -400, 666+400)
  testOp_R_Mem("mc_sub", mc_sub, F, A, 777, -1000000, 777+1000000)
  testOp_R_Mem("mc_sub", mc_sub, F, A, 888,  1000000, 888-1000000)


  testOp_R_Mem("mc_and", mc_and, A, F, #b1010, #b0011, #b1010 & #b0011)
  testOp_R_Mem("mc_and", mc_and, A, F,
               #xAAAAAAAA, #x33333333, #xAAAAAAAA & #x33333333)

  testOp_R_Mem("mc_and", mc_and, F, A, #b1010, #b0011, #b1010 & #b0011)
  testOp_R_Mem("mc_and", mc_and, F, A,
               #xAAAAAAAA, #x33333333, #xAAAAAAAA & #x33333333)


  testOp_R_Mem("mc_or",  mc_or,  A, F, #b1010, #b0011, #b1010 | #b0011)
  testOp_R_Mem("mc_or",  mc_or,  A, F,
               #xAAAAAAAA, #x33333333, #xAAAAAAAA | #x33333333)

  testOp_R_Mem("mc_or",  mc_or,  F, A, #b1010, #b0011, #b1010 | #b0011)
  testOp_R_Mem("mc_or",  mc_or,  F, A,
               #xAAAAAAAA, #x33333333, #xAAAAAAAA | #x33333333)


  testOp_R_Mem("mc_xor", mc_xor, A, F, #b1010, #b0011, #b1010 XOR #b0011)
  testOp_R_Mem("mc_xor", mc_xor, A, F,
               #xAAAAAAAA, #x33333333, #xAAAAAAAA XOR #x33333333)

  testOp_R_Mem("mc_xor", mc_xor, F, A, #b1010, #b0011, #b1010 XOR #b0011)
  testOp_R_Mem("mc_xor", mc_xor, F, A,
               #xAAAAAAAA, #x33333333, #xAAAAAAAA XOR #x33333333)


  testOp_RorMem_R("mc_add", mc_add, A, F, 111,        0, 111+0)
  testOp_RorMem_R("mc_add", mc_add, A, F, 222,        1, 222+1)
  testOp_RorMem_R("mc_add", mc_add, A, F, 333,       -1, 333-1)
  testOp_RorMem_R("mc_add", mc_add, A, F, 444,       10, 444+10)
  testOp_RorMem_R("mc_add", mc_add, A, F, 555,      400, 555+400)
  testOp_RorMem_R("mc_add", mc_add, A, F, 666,     -400, 666-400)
  testOp_RorMem_R("mc_add", mc_add, A, F, 777, -1000000, 777-1000000)
  testOp_RorMem_R("mc_add", mc_add, A, F, 888,  1000000, 888+1000000)

  testOp_RorMem_R("mc_add", mc_add, F, A, 111,        0, 111+0)
  testOp_RorMem_R("mc_add", mc_add, F, A, 222,        1, 222+1)
  testOp_RorMem_R("mc_add", mc_add, F, A, 333,       -1, 333-1)
  testOp_RorMem_R("mc_add", mc_add, F, A, 444,       10, 444+10)
  testOp_RorMem_R("mc_add", mc_add, F, A, 555,      400, 555+400)
  testOp_RorMem_R("mc_add", mc_add, F, A, 666,     -400, 666-400)
  testOp_RorMem_R("mc_add", mc_add, F, A, 777, -1000000, 777-1000000)
  testOp_RorMem_R("mc_add", mc_add, F, A, 888,  1000000, 888+1000000)

  testOp_RorMem_R("mc_sub", mc_sub, A, F, 111,        0, 111-0)
  testOp_RorMem_R("mc_sub", mc_sub, A, F, 222,        1, 222-1)
  testOp_RorMem_R("mc_sub", mc_sub, A, F, 333,       -1, 333+1)
  testOp_RorMem_R("mc_sub", mc_sub, A, F, 444,       10, 444-10)
  testOp_RorMem_R("mc_sub", mc_sub, A, F, 555,      400, 555-400)
  testOp_RorMem_R("mc_sub", mc_sub, A, F, 666,     -400, 666+400)
  testOp_RorMem_R("mc_sub", mc_sub, A, F, 777, -1000000, 777+1000000)
  testOp_RorMem_R("mc_sub", mc_sub, A, F, 888,  1000000, 888-1000000)

  testOp_RorMem_R("mc_sub", mc_sub, F, A, 111,        0, 111-0)
  testOp_RorMem_R("mc_sub", mc_sub, F, A, 222,        1, 222-1)
  testOp_RorMem_R("mc_sub", mc_sub, F, A, 333,       -1, 333+1)
  testOp_RorMem_R("mc_sub", mc_sub, F, A, 444,       10, 444-10)
  testOp_RorMem_R("mc_sub", mc_sub, F, A, 555,      400, 555-400)
  testOp_RorMem_R("mc_sub", mc_sub, F, A, 666,     -400, 666+400)
  testOp_RorMem_R("mc_sub", mc_sub, F, A, 777, -1000000, 777+1000000)
  testOp_RorMem_R("mc_sub", mc_sub, F, A, 888,  1000000, 888-1000000)


  testOp_RorMem_R("mc_and", mc_and, A, F, #b1010, #b0011, #b1010 & #b0011)
  testOp_RorMem_R("mc_and", mc_and, A, F,
               #xAAAAAAAA, #x33333333, #xAAAAAAAA & #x33333333)

  testOp_RorMem_R("mc_and", mc_and, F, A, #b1010, #b0011, #b1010 & #b0011)
  testOp_RorMem_R("mc_and", mc_and, F, A,
               #xAAAAAAAA, #x33333333, #xAAAAAAAA & #x33333333)


  testOp_RorMem_R("mc_or",  mc_or,  A, F, #b1010, #b0011, #b1010 | #b0011)
  testOp_RorMem_R("mc_or",  mc_or,  A, F,
               #xAAAAAAAA, #x33333333, #xAAAAAAAA | #x33333333)

  testOp_RorMem_R("mc_or",  mc_or,  F, A, #b1010, #b0011, #b1010 | #b0011)
  testOp_RorMem_R("mc_or",  mc_or,  F, A,
               #xAAAAAAAA, #x33333333, #xAAAAAAAA | #x33333333)


  testOp_RorMem_R("mc_xor", mc_xor, A, F, #b1010, #b0011, #b1010 XOR #b0011)
  testOp_RorMem_R("mc_xor", mc_xor, A, F,
               #xAAAAAAAA, #x33333333, #xAAAAAAAA XOR #x33333333)

  testOp_RorMem_R("mc_xor", mc_xor, F, A, #b1010, #b0011, #b1010 XOR #b0011)
  testOp_RorMem_R("mc_xor", mc_xor, F, A,
               #xAAAAAAAA, #x33333333, #xAAAAAAAA XOR #x33333333)

  testOp_RorMem_K("mc_add", mc_add, A, F, 111,        0, 111+0)
  testOp_RorMem_K("mc_add", mc_add, A, F, 222,        1, 222+1)
  testOp_RorMem_K("mc_add", mc_add, A, F, 333,       -1, 333-1)
  testOp_RorMem_K("mc_add", mc_add, A, F, 444,       10, 444+10)
  testOp_RorMem_K("mc_add", mc_add, A, F, 555,      400, 555+400)
  testOp_RorMem_K("mc_add", mc_add, A, F, 666,     -400, 666-400)
  testOp_RorMem_K("mc_add", mc_add, A, F, 777, -1000000, 777-1000000)
  testOp_RorMem_K("mc_add", mc_add, A, F, 888,  1000000, 888+1000000)

  testOp_RorMem_K("mc_add", mc_add, F, A, 111,        0, 111+0)
  testOp_RorMem_K("mc_add", mc_add, F, A, 222,        1, 222+1)
  testOp_RorMem_K("mc_add", mc_add, F, A, 333,       -1, 333-1)
  testOp_RorMem_K("mc_add", mc_add, F, A, 444,       10, 444+10)
  testOp_RorMem_K("mc_add", mc_add, F, A, 555,      400, 555+400)
  testOp_RorMem_K("mc_add", mc_add, F, A, 666,     -400, 666-400)
  testOp_RorMem_K("mc_add", mc_add, F, A, 777, -1000000, 777-1000000)
  testOp_RorMem_K("mc_add", mc_add, F, A, 888,  1000000, 888+1000000)

  testOp_RorMem_K("mc_sub", mc_sub, A, F, 111,        0, 111-0)
  testOp_RorMem_K("mc_sub", mc_sub, A, F, 222,        1, 222-1)
  testOp_RorMem_K("mc_sub", mc_sub, A, F, 333,       -1, 333+1)
  testOp_RorMem_K("mc_sub", mc_sub, A, F, 444,       10, 444-10)
  testOp_RorMem_K("mc_sub", mc_sub, A, F, 555,      400, 555-400)
  testOp_RorMem_K("mc_sub", mc_sub, A, F, 666,     -400, 666+400)
  testOp_RorMem_K("mc_sub", mc_sub, A, F, 777, -1000000, 777+1000000)
  testOp_RorMem_K("mc_sub", mc_sub, A, F, 888,  1000000, 888-1000000)

  testOp_RorMem_K("mc_sub", mc_sub, F, A, 111,        0, 111-0)
  testOp_RorMem_K("mc_sub", mc_sub, F, A, 222,        1, 222-1)
  testOp_RorMem_K("mc_sub", mc_sub, F, A, 333,       -1, 333+1)
  testOp_RorMem_K("mc_sub", mc_sub, F, A, 444,       10, 444-10)
  testOp_RorMem_K("mc_sub", mc_sub, F, A, 555,      400, 555-400)
  testOp_RorMem_K("mc_sub", mc_sub, F, A, 666,     -400, 666+400)
  testOp_RorMem_K("mc_sub", mc_sub, F, A, 777, -1000000, 777+1000000)
  testOp_RorMem_K("mc_sub", mc_sub, F, A, 888,  1000000, 888-1000000)


  testOp_RorMem_K("mc_and", mc_and, A, F, #b1010, #b0011, #b1010 & #b0011)
  testOp_RorMem_K("mc_and", mc_and, A, F,
               #xAAAAAAAA, #x33333333, #xAAAAAAAA & #x33333333)

  testOp_RorMem_K("mc_and", mc_and, F, A, #b1010, #b0011, #b1010 & #b0011)
  testOp_RorMem_K("mc_and", mc_and, F, A,
               #xAAAAAAAA, #x33333333, #xAAAAAAAA & #x33333333)


  testOp_RorMem_K("mc_or",  mc_or,  A, F, #b1010, #b0011, #b1010 | #b0011)
  testOp_RorMem_K("mc_or",  mc_or,  A, F,
               #xAAAAAAAA, #x33333333, #xAAAAAAAA | #x33333333)

  testOp_RorMem_K("mc_or",  mc_or,  F, A, #b1010, #b0011, #b1010 | #b0011)
  testOp_RorMem_K("mc_or",  mc_or,  F, A,
               #xAAAAAAAA, #x33333333, #xAAAAAAAA | #x33333333)


  testOp_RorMem_K("mc_xor", mc_xor, A, F, #b1010, #b0011, #b1010 XOR #b0011)
  testOp_RorMem_K("mc_xor", mc_xor, A, F,
               #xAAAAAAAA, #x33333333, #xAAAAAAAA XOR #x33333333)

  testOp_RorMem_K("mc_xor", mc_xor, F, A, #b1010, #b0011, #b1010 XOR #b0011)
  testOp_RorMem_K("mc_xor", mc_xor, F, A,
               #xAAAAAAAA, #x33333333, #xAAAAAAAA XOR #x33333333)
}



AND testOp_R_Mem(mess, mcop, r1, r2, x, y, res) BE
// Test mc_add, mc_and, mc_or, mc_sub and mc_xor
{ //    RA RV RG RM RL RD RDX RDXs RDXsB
  LET reslab = mcNextlab()
  LET d0 = tabaddr
  LET d1 = tabaddr+4
  LET d2 = tabaddr+8

  mcK(mc_alignd, 4)
  mcL(mc_dlab, reslab)
  mcK(mc_datak, 0)

  fnstart("Test for: %s R,Mem  with r1=%s r2=%s x=%n y=%n res=%n*n",
           mess, mcrname(r1), mcrname(r2), x, y, res)

  mcRK(   mc_mv,  r1,     x)
  mcAK(   mc_mv,  a1,     y)
  mcRA(   mcop,   r1,     a1)        // RA
  mcRK(   mc_sub, r1,     res)
  mcLR(   mc_or,  reslab, r1)

  mcRK(   mc_mv,  r1,     x)
  mcAK(   mc_mv,  v1,     y)
  mcRA(   mcop,   r1,     v1)        // RV
  mcRK(   mc_sub, r1,     res)
  mcLR(   mc_or,  reslab, r1)

  mcRK(   mc_mv,  r1,     x)
  mcGK(   mc_mv,  G1,    y)
  mcRG(   mcop,   r1,    G1)         // RG
  mcRK(   mc_sub, r1,     res)
  mcLR(   mc_or,  reslab, r1)

  mcRK(   mc_mv,  r1,     x)
  mcMK(   mc_mv,  99,     y)
  mcRM(   mcop,   r1,    99)         // RM
  mcRK(   mc_sub, r1,     res)
  mcLR(   mc_or,  reslab, r1)

  mcRK(   mc_mv,  r1,     x)
  mcLK(   mc_mv,  tablab, y)
  mcRL(   mcop,   r1, tablab)        // RL
  mcRK(   mc_sub, r1,     res)
  mcLR(   mc_or,  reslab, r1)

  mcRK(   mc_mv,  r1,     x)
  mcDK(   mc_mv,  d1, y)
  mcRD(   mcop,   r1, d1)     // RD
  mcRK(   mc_sub, r1,     res)
  mcLR(   mc_or,  reslab, r1)

  mcRL(   mc_lea, B, tablab)

  mcRK(   mc_mv,  r1,     x)
  mcDK(   mc_mv,  d0, y)
  mcRDX(  mcop,   r1, 0, B)          // RDX
  mcRK(   mc_sub, r1,     res)
  mcLR(   mc_or,  reslab, r1)

  mcRK(   mc_mv,  r1,     x)
  mcDK(   mc_mv,  d1, y)
  mcRDX(  mcop,   r1, 4, B)          // RDX
  mcRK(   mc_sub, r1,     res)
  mcLR(   mc_or,  reslab, r1)

  mcRK(   mc_mv,  r1,     x)
  mcDK(   mc_mv,  d0+400, y)
  mcRDX(  mcop,   r1, 400, B)        // RDX
  mcRK(   mc_sub, r1,     res)
  mcLR(   mc_or,  reslab, r1)

  FOR sh = 0 TO 3 DO
  { LET s = 1<<sh

    mcRL(mc_lea, D, tablab); mcRK(  mc_rsh, D, sh) // D = tabaddr>>sh

    mcRK(   mc_mv,  r1,     x)
    mcDK(   mc_mv,  d0, y)
    mcRDXs( mcop,   r1, 0, D, s)     // RDXs
    mcRK(   mc_sub, r1,     res)
    mcLR(   mc_or,  reslab, r1)

    mcRK(   mc_mv,  r1,     x)
    mcDK(   mc_mv,  d1, y)
    mcRDXs( mcop,   r1, 4, D, s)     // RDXs
    mcRK(   mc_sub, r1,     res)
    mcLR(   mc_or,  reslab, r1)

    mcRK(   mc_mv,  r1,     x)
    mcDK(   mc_mv,  d0+400, y)
    mcRDXs( mcop,   r1, 400, D, s)   // RDXs
    mcRK(   mc_sub, r1,     res)
    mcLR(   mc_or,  reslab, r1)
  }

  mcRK(   mc_mv, E, 4)

  FOR sh = 0 TO 3 DO
  { LET s = 1<<sh

    mcRL(mc_lea, D, tablab); mcRK(  mc_rsh, D, sh) // D = tabaddr>>sh

    mcRK(   mc_mv,  r1,     x)
    mcDK(   mc_mv,  d1, y)
    mcRDXsB(mcop,   r1, 0, D, s, E)  // RDXsB
    mcRK(   mc_sub, r1,     res)
    mcLR(   mc_or,  reslab, r1)

    mcRK(   mc_mv,  r1,     x)
    mcDK(   mc_mv,  d2, y)
    mcRDXsB(mcop,   r1, 4, D, s, E)  // RDXsB
    mcRK(   mc_sub, r1,     res)
    mcLR(   mc_or,  reslab, r1)

    mcRK(   mc_mv,  r1,     x)
    mcDK(   mc_mv,  d0+404, y)
    mcRDXsB(mcop,   r1, 400, D, s, E) // RDXsB
    mcRK(   mc_sub, r1,     res)
    mcLR(   mc_or,  reslab, r1)
  }

  mcRL(mc_mv, A, reslab)      // Should set A to zero
  fnend()
}

AND testOp_RorMem_R(mess, mcop, r1, r2, x, y, res) BE
{ // Test mc_add, mc_and, mc_or, mc_sub and mc_xor
  // RR AR VR GR MR LR DR DXR DXsR DXsBR
  LET reslab = mcNextlab()
  LET d0 = tabaddr
  LET d1 = tabaddr+4
  LET d2 = tabaddr+8

  mcK(mc_alignd, 4)
  mcL(mc_dlab, reslab)
  mcK(mc_datak, 0)

  fnstart("Test for: %s RorMem,R  with r1=%s r2=%s x=%n y=%n res=%n*n",
           mess, mcrname(r1), mcrname(r2), x, y, res)

  mcRK(   mc_mv,  r1, x)
  mcRK(   mc_mv,  r2, y)
  mcRR(   mcop,   r1, r2)          // RR
  mcRR(   mc_mv,  A,  r1)
  mcRK(   mc_sub, A, res)
  mcLR(   mc_or,  reslab, A)

//mcRK( mc_mv, B, x);  mcStrR(mc_prf, "*nx  =%d*n", B)

  mcAK(   mc_mv,  a1, x)
  mcRK(   mc_mv,  r2, y)
  mcAR(   mcop,   a1, r2)          // AR
  mcRA(   mc_mv,  A, a1)
  mcRK(   mc_sub, A, res)
  mcLR(   mc_or,  reslab, A)

  mcVK(   mc_mv,  v1, x)
  mcRK(   mc_mv,  r2, y)
  mcVR(   mcop,   v1, r2)          // VR
  mcRV(   mc_mv,  A, v1)
  mcRK(   mc_sub, A, res)
  mcLR(   mc_or,  reslab, A)

  mcGK(   mc_mv,  G1, x)
  mcRK(   mc_mv,  r2, y)
  mcGR(   mcop,   G1, r2)          // GR
  mcRG(   mc_mv,  A, G1)
  mcRK(   mc_sub, A, res)
  mcLR(   mc_or,  reslab, A)

  mcMK(   mc_mv,  99, x)
  mcRK(   mc_mv,  r2, y)
  mcMR(   mcop,   99, r2)          // MR
  mcRM(   mc_mv,  A, 99)
  mcRK(   mc_sub, A, res)
  mcLR(   mc_or,  reslab, A)

  mcDK(   mc_mv,  d1, x)
  mcRK(   mc_mv,  r2, y)
  mcDR(   mcop,   d1, r2)          // DR
  mcRD(   mc_mv,  A, d1)
  mcRK(   mc_sub, A, res)
  mcLR(   mc_or,  reslab, A)

  mcRL(   mc_lea, r1, tablab)
  mcDK(   mc_mv,  d0, x)
  mcRK(   mc_mv,  r2, y)
  mcDXR(  mcop,   0, r1, r2)       // DXR
  mcRD(   mc_mv,  A, d0)
  mcRK(   mc_sub, A, res)
  mcLR(   mc_or,  reslab, A)

  mcRL(   mc_lea, r1, tablab)
  mcDK(   mc_mv,  d1, x)
  mcRK(   mc_mv,  r2, y)
  mcDXR(  mcop,   4, r1, r2)       // DXR
  mcRD(   mc_mv,  A, d1)
  mcRK(   mc_sub, A, res)
  mcLR(   mc_or,  reslab, A)

  mcRL(   mc_lea, r1, tablab)
  mcDK(   mc_mv,  d0+400, x)
  mcRK(   mc_mv,  r2, y)
  mcDXR(  mcop,   400, r1, r2)     // DXR
  mcRD(   mc_mv,  A, d0+400)
  mcRK(   mc_sub, A, res)
  mcLR(   mc_or,  reslab, A)

  FOR sh = 0 TO 3 DO
  { LET s = 1<<sh

    mcRL(mc_lea, r1, tablab); mcRK(  mc_rsh, r1, sh) // r1 = tabaddr>>sh

    mcDK(   mc_mv,  d0, x)
    mcRK(   mc_mv,  r2, y)
    mcDXsR( mcop,   0, r1, s, r2)  // DXsR
    mcRD(   mc_mv,  A, d0)
    mcRK(   mc_sub, A, res)
    mcLR(   mc_or,  reslab, A)

    mcRL(mc_lea, r1, tablab); mcRK(  mc_rsh, r1, sh) // r1 = tabaddr>>sh

    mcDK(   mc_mv,  d1, x)
    mcRK(   mc_mv,  r2, y)
    mcDXsR( mcop,   4, r1, s, r2)  // DXsR
    mcRD(   mc_mv,  A, d1)
    mcRK(   mc_sub, A, res)
    mcLR(   mc_or,  reslab, A)

    mcRL(mc_lea, r1, tablab); mcRK(  mc_rsh, r1, sh) // r1 = tabaddr>>sh

    mcDK(   mc_mv,  d0+400, x)
    mcRK(   mc_mv,  r2, y)
    mcDXsR( mcop,   400, r1, s, r2) // DXsR
    mcRD(   mc_mv,  A, d0+400)
    mcRK(   mc_sub, A, res)
    mcLR(   mc_or,  reslab, A)
  }


  FOR sh = 0 TO 3 DO
  { LET s = 1<<sh

    mcRL(mc_lea, r1, tablab); mcRK(  mc_rsh, r1, sh) // r1 = tabaddr>>sh
    mcRK(   mc_mv,  E,      4)

    mcDK(   mc_mv,  d1, x)
    mcRK(   mc_mv,  r2, y)
    mcDXsBR(mcop,   0, r1, s, E, r2) // DXsBR
    mcRD(   mc_mv,  A, d1)
    mcRK(   mc_sub, A,     res)
    mcLR(   mc_or,  reslab, A)

    mcRL(mc_lea, r1, tablab); mcRK(  mc_rsh, r1, sh) // r1 = tabaddr>>sh
    mcRK(   mc_mv,  E,      4)

    mcDK(   mc_mv,  d2, x)
    mcRK(   mc_mv,  r2, y)
    mcDXsBR(mcop,   4, r1, s, E, r2) // DXsBR
    mcRD(   mc_mv,  A, d2)
    mcRK(   mc_sub, A,     res)
    mcLR(   mc_or,  reslab, A)

    mcRL(mc_lea, r1, tablab); mcRK(  mc_rsh, r1, sh) // r1 = tabaddr>>sh
    mcRK(   mc_mv,  E,      4)

    mcDK(   mc_mv,  d0+404, x)
    mcRK(   mc_mv,  r2, y)
    mcDXsBR(mcop,   400, r1, s, E, r2) // DXsBR
    mcRD(   mc_mv,  A, d0+404)
    mcRK(   mc_sub, A,     res)
    mcLR(   mc_or,  reslab, A)
  }

  mcRL(mc_mv, A, reslab)      // Should set A to zero
  fnend()
}

AND testOp_RorMem_K(mess, mcop, r1, r2, x, y, res) BE
{ // Test mc_add, mc_and, mc_or, mc_sub and mc_xor
  // RK AK VK GK MK LK DK DXK DXsK DXsBK
  LET reslab = mcNextlab()
  LET d0 = tabaddr
  LET d1 = tabaddr+4
  LET d2 = tabaddr+8

  mcK(mc_alignd, 4)
  mcL(mc_dlab, reslab)
  mcK(mc_datak, 0)

  fnstart("Test for: %s RorMem,K  with r1=%s r2=%s x=%n y=%n res=%n*n",
           mess, mcrname(r1), mcrname(r2), x, y, res)

  mcRK(   mc_mv,  r1, x)
  mcRK(   mcop,   r1, y)          // RK
  mcRR(   mc_mv,  A,  r1)
  mcRK(   mc_sub, A, res)
  mcLR(   mc_or,  reslab, A)

//mcRK( mc_mv, B, x);  mcStrR(mc_prf, "*nx  =%d*n", B)

  mcAK(   mc_mv,  a1, x)
  mcAK(   mcop,   a1, y)          // AK
  mcRA(   mc_mv,  A, a1)
  mcRK(   mc_sub, A, res)
  mcLR(   mc_or,  reslab, A)

  mcVK(   mc_mv,  v1, x)
  mcVK(   mcop,   v1, y)          // VK
  mcRV(   mc_mv,  A, v1)
  mcRK(   mc_sub, A, res)
  mcLR(   mc_or,  reslab, A)

  mcGK(   mc_mv,  G1, x)
  mcGK(   mcop,   G1, y)          // GK
  mcRG(   mc_mv,  A, G1)
  mcRK(   mc_sub, A, res)
  mcLR(   mc_or,  reslab, A)

  mcMK(   mc_mv,  99, x)
  mcMK(   mcop,   99, y)          // MK
  mcRM(   mc_mv,  A, 99)
  mcRK(   mc_sub, A, res)
  mcLR(   mc_or,  reslab, A)

  mcDK(   mc_mv,  d1, x)
  mcDK(   mcop,   d1, y)          // DK
  mcRD(   mc_mv,  A, d1)
  mcRK(   mc_sub, A, res)
  mcLR(   mc_or,  reslab, A)

  mcRL(   mc_lea, r1, tablab)
  mcDK(   mc_mv,  d0, x)
  mcDXK(  mcop,   0, r1, y)       // DXK
  mcRD(   mc_mv,  A, d0)
  mcRK(   mc_sub, A, res)
  mcLR(   mc_or,  reslab, A)

  mcRL(   mc_lea, r1, tablab)
  mcDK(   mc_mv,  d1, x)
  mcDXK(  mcop,   4, r1, y)       // DXK
  mcRD(   mc_mv,  A, d1)
  mcRK(   mc_sub, A, res)
  mcLR(   mc_or,  reslab, A)

  mcRL(   mc_lea, r1, tablab)
  mcDK(   mc_mv,  d0+400, x)
  mcDXK(  mcop,   400, r1, y)     // DXK
  mcRD(   mc_mv,  A, d0+400)
  mcRK(   mc_sub, A, res)
  mcLR(   mc_or,  reslab, A)

  FOR sh = 0 TO 3 DO
  { LET s = 1<<sh

    mcRL(mc_lea, r1, tablab); mcRK(  mc_rsh, r1, sh) // r1 = tabaddr>>sh

    mcDK(   mc_mv,  d0, x)
    mcDXsK( mcop,   0, r1, s, y)   // DXsK
    mcRD(   mc_mv,  A, d0)
    mcRK(   mc_sub, A, res)
    mcLR(   mc_or,  reslab, A)

    mcRL(mc_lea, r1, tablab); mcRK(  mc_rsh, r1, sh) // r1 = tabaddr>>sh

    mcDK(   mc_mv,  d1, x)
    mcDXsK( mcop,   4, r1, s, y)   // DXsK
    mcRD(   mc_mv,  A, d1)
    mcRK(   mc_sub, A, res)
    mcLR(   mc_or,  reslab, A)

    mcRL(mc_lea, r1, tablab); mcRK(  mc_rsh, r1, sh) // r1 = tabaddr>>sh

    mcDK(   mc_mv,  d0+400, x)
    mcDXsK( mcop,   400, r1, s, y)  // DXsK
    mcRD(   mc_mv,  A, d0+400)
    mcRK(   mc_sub, A, res)
    mcLR(   mc_or,  reslab, A)
  }

  FOR sh = 0 TO 3 DO
  { LET s = 1<<sh

    mcRL(mc_lea, r1, tablab); mcRK(  mc_rsh, r1, sh) // r1 = tabaddr>>sh
    mcRK(   mc_mv,  E,      4)

    mcDK(   mc_mv,  d1, x)
    mcDXsBK(mcop,   0, r1, s, E, y)  // DXsBK
    mcRD(   mc_mv,  A, d1)
    mcRK(   mc_sub, A,     res)
    mcLR(   mc_or,  reslab, A)

    mcRL(mc_lea, r1, tablab); mcRK(  mc_rsh, r1, sh) // r1 = tabaddr>>sh
    mcRK(   mc_mv,  E,      4)

    mcDK(   mc_mv,  d2, x)
    mcDXsBK(mcop,   4, r1, s, E, y)  // DXsBK
    mcRD(   mc_mv,  A, d2)
    mcRK(   mc_sub, A,     res)
    mcLR(   mc_or,  reslab, A)

    mcRL(mc_lea, r1, tablab); mcRK(  mc_rsh, r1, sh) // r1 = tabaddr>>sh
    mcRK(   mc_mv,  E,      4)

    mcDK(   mc_mv,  d0+404, x)
    mcDXsBK(mcop,   400, r1, s, E, y) // DXsBK
    mcRD(   mc_mv,  A, d0+404)
    mcRK(   mc_sub, A,     res)
    mcLR(   mc_or,  reslab, A)
  }

  mcRL(mc_mv, A, reslab)      // Should set A to zero
  fnend()
}

LET testADDC_SUBC_R_Mem(x, y) BE
{ // Test addc and subc
  // RA RV RG RM RL RD RDX RDXs RDXsB
  LET reslab = mcNextlab()
  LET L1 = mcNextlab()
  LET L2 = mcNextlab()
  LET d1 = tabaddr+4
  LET d2 = tabaddr+8

  mcK(mc_alignd, 4)
  mcL(mc_dlab, reslab)
  mcK(mc_datak, 0)
  mcL(mc_dlab, L1)
  mcK(mc_datak, 0)
  mcL(mc_dlab, L2)
  mcK(mc_datak, 0)

  fnstart("Testing ADDC and SUBC (R_Mem) on %x8 and %x8*n", x, y)

  // RA
  mcRK( mc_mv,   A,  y)
  mcRK( mc_mv,   B,  x)
  mcAK( mc_mv,   a1, 12)
  mcAK( mc_mv,   a2, 19)
  mcRA( mc_add,  A, a1)
  mcRA( mc_addc, B, a2)
  mcAK( mc_mv,   a1,  y)
  mcAK( mc_mv,   a2,  x)
  mcRA( mc_sub,  A,  a1)
  mcRA( mc_subc, B,  a2)
  mcRK( mc_sub,  A,  12)
  mcLR( mc_or,   reslab, A)
  mcRK( mc_sub,  B,  19)
  mcLR( mc_or,   reslab, B)

  // RV
  mcRK( mc_mv,   A,  y)
  mcRK( mc_mv,   B,  x)
//mcPRF("%8x ",   B)
//mcPRF("%8x +*n", A)
//mcRK(mc_mv, C, 12)
//mcRK(mc_mv, D, 19)
//mcPRF("%8x ",   D)
//mcPRF("%8x =*n", C)
  mcVK( mc_mv,   v1, 12)
  mcVK( mc_mv,   v2, 19)
  mcRV( mc_add,  A,  v1)
  mcRV( mc_addc, B,  v2)
//mcPRF("%8x ",   B)
//mcPRF("%8x - <x,y> =*n", A)
  mcVK( mc_mv,   v1,  y)
  mcVK( mc_mv,   v2,  x)
  mcRV( mc_sub,  A,  v1)
  mcRV( mc_subc, B,  v2)
//mcPRF("%8x ",   B)
//mcPRF("%8x +*n*n", A)
  mcRK( mc_sub,  A,  12)
  mcLR( mc_or,   reslab, A)
  mcRK( mc_sub,  B,  19)
  mcLR( mc_or,   reslab, B)
//mcPRF("error: %8x ",   B)
//mcPRF("%8x*n*n", A)

  // RG
  mcRK( mc_mv,   A,  y)
  mcRK( mc_mv,   B,  x)
  mcGK( mc_mv,  G1, 12)
  mcGK( mc_mv,  G2, 19)
  mcRG( mc_add,  A, G1)
  mcRG( mc_addc, B, G2)
  mcGK( mc_mv,  G1,  y)
  mcGK( mc_mv,  G2,  x)
  mcRG( mc_sub,  A, G1)
  mcRG( mc_subc, B, G2)
  mcRK( mc_sub,  A,  12)
  mcLR( mc_or,   reslab, A)
  mcRK( mc_sub,  B,  19)
  mcLR( mc_or,   reslab, B)

  // RM
  mcRK( mc_mv,   A,  y)
  mcRK( mc_mv,   B,  x)
  mcMK( mc_mv,   99, 12)
  mcMK( mc_mv,   98, 19)
  mcRM( mc_add,  A,  99)
  mcRM( mc_addc, B,  98)
  mcMK( mc_mv,   99,  y)
  mcMK( mc_mv,   98,  x)
  mcRM( mc_sub,  A,  99)
  mcRM( mc_subc, B,  98)
  mcRK( mc_sub,  A,  12)
  mcLR( mc_or,   reslab, A)
  mcRK( mc_sub,  B,  19)
  mcLR( mc_or,   reslab, B)

  // RL
  mcRK( mc_mv,   A,  y)
  mcRK( mc_mv,   B,  x)
  mcLK( mc_mv,   L1, 12)
  mcLK( mc_mv,   L2, 19)
  mcRL( mc_add,  A,  L1)
  mcRL( mc_addc, B,  L2)
  mcLK( mc_mv,   L1,  y)
  mcLK( mc_mv,   L2,  x)
  mcRL( mc_sub,  A,  L1)
  mcRL( mc_subc, B,  L2)
  mcRK( mc_sub,  A,  12)
  mcLR( mc_or,   reslab, A)
  mcRK( mc_sub,  B,  19)
  mcLR( mc_or,   reslab, B)

  // RD
  mcRK( mc_mv,   A,  y)
  mcRK( mc_mv,   B,  x)
  mcDK( mc_mv,   d1, 12)
  mcDK( mc_mv,   d2, 19)
  mcRD( mc_add,  A,  d1)
  mcRD( mc_addc, B,  d2)
  mcDK( mc_mv,   d1,  y)
  mcDK( mc_mv,   d2,  x)
  mcRD( mc_sub,  A,  d1)
  mcRD( mc_subc, B,  d2)
  mcRK( mc_sub,  A,  12)
  mcLR( mc_or,   reslab, A)
  mcRK( mc_sub,  B,  19)
  mcLR( mc_or,   reslab, B)

  // RDX
  mcRL(   mc_lea,  E, tablab)

  mcRK( mc_mv,   A,  y)
  mcRK( mc_mv,   B,  x)
  mcDXK(mc_mv,   0, E, 12)
  mcDXK(mc_mv,   4, E, 19)
  mcRDX(mc_add,  A,  0, E)
  mcRDX(mc_addc, B,  4, E)
  mcDXK(mc_mv,   0, E,  y)
  mcDXK(mc_mv,   4, E,  x)
  mcRDX(mc_sub,  A,  0, E)
  mcRDX(mc_subc, B,  4, E)
  mcRK( mc_sub,  A,  12)
  mcLR( mc_or,   reslab, A)
  mcRK( mc_sub,  B,  19)
  mcLR( mc_or,   reslab, B)

  FOR sh = 0 TO 3 DO
  { LET s = 1<<sh

    mcRL(mc_lea, E, tablab); mcRK(  mc_rsh, E, sh) // E = tabaddr>>sh

    // RDXs
    mcRK(  mc_mv,   A,  y)
    mcRK(  mc_mv,   B,  x)
    mcDXsK(mc_mv,   0, E, s, 12)
    mcDXsK(mc_mv,   4, E, s, 19)
    mcRDXs(mc_add,  A,  0, E, s)
    mcRDXs(mc_addc, B,  4, E, s)
    mcDXsK(mc_mv,   0, E, s,  y)
    mcDXsK(mc_mv,   4, E, s,  x)
    mcRDXs(mc_sub,  A,  0, E, s)
    mcRDXs(mc_subc, B,  4, E, s)
    mcRK(  mc_sub,  A,  12)
    mcLR(  mc_or,   reslab, A)
    mcRK(  mc_sub,  B,  19)
    mcLR(  mc_or,   reslab, B)
  }

  FOR sh = 0 TO 3 DO
  { LET s = 1<<sh

    mcRL(mc_lea, E, tablab); mcRK(  mc_rsh, E, sh) // E = tabaddr>>sh
    mcRK(   mc_mv,  F, 4)

    // RDXsB
    mcRK(   mc_mv,   A,  y)
    mcRK(   mc_mv,   B,  x)
    mcDXsBK(mc_mv,   0, E, s, F, 12)
    mcDXsBK(mc_mv,   4, E, s, F, 19)
    mcRDXsB(mc_add,  A,  0, E, s, F)
    mcRDXsB(mc_addc, B,  4, E, s, F)
    mcDXsBK(mc_mv,   0, E, s, F,  y)
    mcDXsBK(mc_mv,   4, E, s, F,  x)
    mcRDXsB(mc_sub,  A,  0, E, s, F)
    mcRDXsB(mc_subc, B,  4, E, s, F)
    mcRK(   mc_sub,  A,  12)
    mcLR(   mc_or,   reslab, A)
    mcRK(   mc_sub,  B,  19)
    mcLR(   mc_or,   reslab, B)
  }

  mcRL( mc_mv,   A, reslab)
  mcF(  mc_rtn)

  fnend()
}

LET testADDC_SUBC_RorMem_R(x, y) BE
{ // Test addc and subc
  // RR AR VR GR MR LR DR DXR DXsR DXsBR
  LET reslab = mcNextlab()
  LET L1 = mcNextlab()
  LET L2 = mcNextlab()
  LET d1 = tabaddr+4
  LET d2 = tabaddr+8

  mcK(mc_alignd, 4)
  mcL(mc_dlab, reslab)
  mcK(mc_datak, 0)
  mcL(mc_dlab, L1)
  mcK(mc_datak, 0)
  mcL(mc_dlab, L2)
  mcK(mc_datak, 0)

  fnstart("Testing ADDC and SUBC (RorMem_R) on %x8 and %x8*n", x, y)

  // RR
  mcRK( mc_mv,   A,  y)  // set <B, A> = < x, y>
  mcRK( mc_mv,   B,  x)
  mcRK( mc_mv,   C, 12)
  mcRK( mc_mv,   D, 19)
  mcRR( mc_add,  A,  C)
  mcRR( mc_addc, B,  D)
  mcRK( mc_mv,   C,  y)
  mcRK( mc_mv,   D,  x)
  mcRR( mc_sub,  A,  C)
  mcRR( mc_subc, B,  D)
  mcRK( mc_sub,  A,  12)
  mcLR( mc_or,   reslab, A)
  mcRK( mc_sub,  B,  19)
  mcLR( mc_or,   reslab, B)

  // AR
  mcAK( mc_mv,   a1,  y)
  mcAK( mc_mv,   a2,  x)
  mcRK( mc_mv,   C, 12)
  mcRK( mc_mv,   D, 19)
  mcAR( mc_add,  a1, C)
  mcAR( mc_addc, a2, D)
  mcRK( mc_mv,   C,  y)
  mcRK( mc_mv,   D,  x)
  mcAR( mc_sub,  a1,  C)
  mcAR( mc_subc, a2,  D)
  mcRA( mc_mv,   A,  a1)
  mcRK( mc_sub,  A,  12)
  mcLR( mc_or,   reslab, A)
  mcRA( mc_mv,   B,  a2)
  mcRK( mc_sub,  B,  19)
  mcLR( mc_or,   reslab, B)

  // VR
  mcVK( mc_mv,   v1,  y)
  mcVK( mc_mv,   v2,  x)
  mcRK( mc_mv,   C, 12)
  mcRK( mc_mv,   D, 19)
  mcVR( mc_add,  v1, C)
  mcVR( mc_addc, v2, D)
  mcRK( mc_mv,   C,  y)
  mcRK( mc_mv,   D,  x)
  mcVR( mc_sub,  v1,  C)
  mcVR( mc_subc, v2,  D)
  mcRV( mc_mv,   A,  v1)
  mcRK( mc_sub,  A,  12)
  mcLR( mc_or,   reslab, A)
  mcRV( mc_mv,   B,  v2)
  mcRK( mc_sub,  B,  19)
  mcLR( mc_or,   reslab, B)

  // GR
  mcGK( mc_mv,  G1,  y)
  mcGK( mc_mv,  G2,  x)
  mcRK( mc_mv,   C, 12)
  mcRK( mc_mv,   D, 19)
  mcGR( mc_add, G1, C)
  mcGR( mc_addc,G2, D)
  mcRK( mc_mv,   C,  y)
  mcRK( mc_mv,   D,  x)
  mcGR( mc_sub, G1,  C)
  mcGR( mc_subc,G2,  D)
  mcRG( mc_mv,   A, G1)
  mcRK( mc_sub,  A,  12)
  mcLR( mc_or,   reslab, A)
  mcRG( mc_mv,   B, G2)
  mcRK( mc_sub,  B,  19)
  mcLR( mc_or,   reslab, B)

  // MR
  mcMK( mc_mv,   99,  y)
  mcMK( mc_mv,   98,  x)
  mcRK( mc_mv,   C, 12)
  mcRK( mc_mv,   D, 19)
  mcMR( mc_add,  99, C)
  mcMR( mc_addc, 98, D)
  mcRK( mc_mv,   C,  y)
  mcRK( mc_mv,   D,  x)
  mcMR( mc_sub,  99,  C)
  mcMR( mc_subc, 98,  D)
  mcRM( mc_mv,   A,  99)
  mcRK( mc_sub,  A,  12)
  mcLR( mc_or,   reslab, A)
  mcRM( mc_mv,   B,  98)
  mcRK( mc_sub,  B,  19)
  mcLR( mc_or,   reslab, B)

  // DR
  mcDK( mc_mv,   d1,  y)
  mcDK( mc_mv,   d2,  x)
  mcRK( mc_mv,   C, 12)
  mcRK( mc_mv,   D, 19)
  mcDR( mc_add,  d1, C)
  mcDR( mc_addc, d2, D)
  mcRK( mc_mv,   C,  y)
  mcRK( mc_mv,   D,  x)
  mcDR( mc_sub,  d1,  C)
  mcDR( mc_subc, d2,  D)
  mcRD( mc_mv,   A,  d1)
  mcRK( mc_sub,  A,  12)
  mcLR( mc_or,   reslab, A)
  mcRD( mc_mv,   B,  d2)
  mcRK( mc_sub,  B,  19)
  mcLR( mc_or,   reslab, B)

  // DXR
  mcRL(   mc_lea,  E, tablab)

  mcDXK(mc_mv,   0, E,  y)
  mcDXK(mc_mv,   4, E,  x)
  mcRK( mc_mv,   C, 12)
  mcRK( mc_mv,   D, 19)
  mcDXR(mc_add,  0, E, C)
  mcDXR(mc_addc, 4, E, D)
  mcRK( mc_mv,   C,  y)
  mcRK( mc_mv,   D,  x)
  mcDXR(mc_sub,  0, E,  C)
  mcDXR(mc_subc, 4, E,  D)
  mcRDX(mc_mv,   A,  0, E)
  mcRK( mc_sub,  A,  12)
  mcLR( mc_or,   reslab, A)
  mcRDX(mc_mv,   B,  4, E)
  mcRK( mc_sub,  B,  19)
  mcLR( mc_or,   reslab, B)


  FOR sh = 0 TO 3 DO
  { LET s = 1<<sh

    mcRL(mc_lea, E, tablab); mcRK(  mc_rsh, E, sh) // E = tabaddr>>sh

    // DXsR
    mcDXsK(mc_mv,   0, E, s,  y)
    mcDXsK(mc_mv,   4, E, s,  x)
    mcRK(  mc_mv,   C, 12)
    mcRK(  mc_mv,   D, 19)
    mcDXsR(mc_add,  0, E, s, C)
    mcDXsR(mc_addc, 4, E, s, D)
    mcRK(  mc_mv,   C,  y)
    mcRK(  mc_mv,   D,  x)
    mcDXsR(mc_sub,  0, E, s,  C)
    mcDXsR(mc_subc, 4, E, s,  D)
    mcRDXs(mc_mv,   A,  0, E, s)
    mcRK(  mc_sub,  A,  12)
    mcLR(  mc_or,   reslab, A)
    mcRDXs(mc_mv,   B,  4, E, s)
    mcRK(  mc_sub,  B,  19)
    mcLR(  mc_or,   reslab, B)
  }

  FOR sh = 0 TO 3 DO
  { LET s = 1<<sh

    mcRL(mc_lea, E, tablab); mcRK(  mc_rsh, E, sh) // E = tabaddr>>sh
    mcRK(   mc_mv,  F, 4)

    // DXsBR
    mcDXsBK(mc_mv,   0, E, s, F,  y)
    mcDXsBK(mc_mv,   4, E, s, F,  x)
    mcRK(   mc_mv,   C, 12)
    mcRK(   mc_mv,   D, 19)
    mcDXsBR(mc_add,  0, E, s, F, C)
    mcDXsBR(mc_addc, 4, E, s, F, D)
    mcRK(   mc_mv,   C,  y)
    mcRK(   mc_mv,   D,  x)
    mcDXsBR(mc_sub,  0, E, s, F,  C)
    mcDXsBR(mc_subc, 4, E, s, F,  D)
    mcRDXsB(mc_mv,   A,  0, E, s, F)
    mcRK(   mc_sub,  A,  12)
    mcLR(   mc_or,   reslab, A)
    mcRDXsB(mc_mv,   B,  4, E, s, F)
    mcRK(   mc_sub,  B,  19)
    mcLR(   mc_or,   reslab, B)
  }

  mcRL( mc_mv,   A, reslab)
  mcF(  mc_rtn)

  fnend()
}


LET testADDC_SUBC_RorMem_K(x, y) BE
{ // Test addc and subc
  // RK AK VK GK MK LK DK DXK DXsK DXsBK
  LET reslab = mcNextlab()
  LET L1 = mcNextlab()
  LET L2 = mcNextlab()
  LET d1 = tabaddr+4
  LET d2 = tabaddr+8

  mcK(mc_alignd, 4)
  mcL(mc_dlab, reslab)
  mcK(mc_datak, 0)
  mcL(mc_dlab, L1)
  mcK(mc_datak, 0)
  mcL(mc_dlab, L2)
  mcK(mc_datak, 0)

  fnstart("Testing ADDC and SUBC (RorMem_K) on %x8 and %x8*n", x, y)

  // RK
  mcRK( mc_mv,   A,  y)  // set <B, A> = < x, y>
  mcRK( mc_mv,   B,  x)
  mcRK( mc_add,  A, 12)  // add <19,12>
  mcRK( mc_addc, B, 19)
  mcRK( mc_sub,  A,  y)  // sub < x, y>
  mcRK( mc_subc, B,  x)
  mcRK( mc_sub,  A,  12)
  mcLR( mc_or,   reslab, A)
  mcRK( mc_sub,  B,  19)
  mcLR( mc_or,   reslab, B)

  // AK
  mcAK( mc_mv,   a1,  y)
  mcAK( mc_mv,   a2,  x)
  mcAK( mc_add,  a1, 12)
  mcAK( mc_addc, a2, 19)
  mcAK( mc_sub,  a1,  y)
  mcAK( mc_subc, a2,  x)
  mcRA( mc_mv,   A,  a1)
  mcRK( mc_sub,  A,  12)
  mcLR( mc_or,   reslab, A)
  mcRA( mc_mv,   B,  a2)
  mcRK( mc_sub,  B,  19)
  mcLR( mc_or,   reslab, B)

  // VK
  mcVK( mc_mv,   v1,  y)
  mcVK( mc_mv,   v2,  x)
  mcVK( mc_add,  v1, 12)
  mcVK( mc_addc, v2, 19)
  mcVK( mc_sub,  v1,  y)
  mcVK( mc_subc, v2,  x)
  mcRV( mc_mv,   A,  v1)
  mcRK( mc_sub,  A,  12)
  mcLR( mc_or,   reslab, A)
  mcRV( mc_mv,   B,  v2)
  mcRK( mc_sub,  B,  19)
  mcLR( mc_or,   reslab, B)

  // GK
  mcGK( mc_mv,  G1,  y)
  mcGK( mc_mv,  G2,  x)
  mcGK( mc_add, G1, 12)
  mcGK( mc_addc,G2, 19)
  mcGK( mc_sub, G1,  y)
  mcGK( mc_subc,G2,  x)
  mcRG( mc_mv,   A, G1)
  mcRK( mc_sub,  A,  12)
  mcLR( mc_or,   reslab, A)
  mcRG( mc_mv,   B, G2)
  mcRK( mc_sub,  B,  19)
  mcLR( mc_or,   reslab, B)

  // MK
  mcMK( mc_mv,   99,  y)
  mcMK( mc_mv,   98,  x)
  mcMK( mc_add,  99, 12)
  mcMK( mc_addc, 98, 19)
  mcMK( mc_sub,  99,  y)
  mcMK( mc_subc, 98,  x)
  mcRM( mc_mv,   A,  99)
  mcRK( mc_sub,  A,  12)
  mcLR( mc_or,   reslab, A)
  mcRM( mc_mv,   B,  98)
  mcRK( mc_sub,  B,  19)
  mcLR( mc_or,   reslab, B)

  // LK
  mcLK( mc_mv,   L1,  y)
  mcLK( mc_mv,   L2,  x)
  mcLK( mc_add,  L1, 12)
  mcLK( mc_addc, L2, 19)
  mcLK( mc_sub,  L1,  y)
  mcLK( mc_subc, L2,  x)
  mcRL( mc_mv,   A,  L1)
  mcRK( mc_sub,  A,  12)
  mcLR( mc_or,   reslab, A)
  mcRL( mc_mv,   B,  L2)
  mcRK( mc_sub,  B,  19)
  mcLR( mc_or,   reslab, B)

  // DK
  mcDK( mc_mv,   d1,  y)
  mcDK( mc_mv,   d2,  x)
  mcDK( mc_add,  d1, 12)
  mcDK( mc_addc, d2, 19)
  mcDK( mc_sub,  d1,  y)
  mcDK( mc_subc, d2,  x)
  mcRD( mc_mv,   A,  d1)
  mcRK( mc_sub,  A,  12)
  mcLR( mc_or,   reslab, A)
  mcRD( mc_mv,   B,  d2)
  mcRK( mc_sub,  B,  19)
  mcLR( mc_or,   reslab, B)

  // DXK
  mcRL(   mc_lea,  C, tablab)
  mcDXK(  mc_mv,   0, C,  y)
  mcDXK(  mc_mv,   4, C,  x)
  mcDXK(  mc_add,  0, C, 12)
  mcDXK(  mc_addc, 4, C, 19)
  mcDXK(  mc_sub,  0, C,  y)
  mcDXK(  mc_subc, 4, C,  x)
  mcRDX(  mc_mv,   A,  0, C)
  mcRK(   mc_sub,  A,  12)
  mcLR(   mc_or,   reslab, A)
  mcRDX(  mc_mv,   B,  4, C)
  mcRK(   mc_sub,  B,  19)
  mcLR(   mc_or,   reslab, B)


  FOR sh = 0 TO 3 DO
  { LET s = 1<<sh

    mcRL(mc_lea, C, tablab); mcRK(  mc_rsh, C, sh) // r1 = tabaddr>>sh

    // DXsK
    mcDXsK( mc_mv,   0, C, s,  y)
    mcDXsK( mc_mv,   4, C, s,  x)
    mcDXsK( mc_add,  0, C, s, 12)
    mcDXsK( mc_addc, 4, C, s, 19)
    mcDXsK( mc_sub,  0, C, s,  y)
    mcDXsK( mc_subc, 4, C, s,  x)
    mcRDXs( mc_mv,   A,  0, C, s)
    mcRK(   mc_sub,  A,  12)
    mcLR(   mc_or,   reslab, A)
    mcRDXs( mc_mv,   B,  4, C, s)
    mcRK(   mc_sub,  B,  19)
    mcLR(   mc_or,   reslab, B)
  }

  FOR sh = 0 TO 3 DO
  { LET s = 1<<sh

    mcRL(mc_lea, C, tablab); mcRK(  mc_rsh, C, sh) // r1 = tabaddr>>sh
    mcRK(   mc_mv,  E,      4)

    // DXsBK
    mcDXsBK(mc_mv,   0, C, s, E,  y)
    mcDXsBK(mc_mv,   4, C, s, E,  x)
    mcDXsBK(mc_add,  0, C, s, E, 12)
    mcDXsBK(mc_addc, 4, C, s, E, 19)
    mcDXsBK(mc_sub,  0, C, s, E,  y)
    mcDXsBK(mc_subc, 4, C, s, E,  x)
    mcRDXsB(mc_mv,   A, 0, C, s, E)
    mcRK(   mc_sub,  A, 12)
    mcLR(   mc_or,   reslab, A)
    mcRDXsB(mc_mv,   B, 4, C, s, E)
    mcRK(   mc_sub,  B, 19)
    mcLR(   mc_or,   reslab, B)
  }

  mcRL( mc_mv,   A, reslab)
  mcF(  mc_rtn)

  fnend()
}


.

SECTION "mcsystest2"

GET "mcsystest.h"



LET testCALL_RET(r1, r2, x, y, z, res) BE
{ // Test mc_call  KK
  // and  mc_rtn   F
  LET reslab = mcNextlab()

  mcK(mc_alignd, 4)
  mcL(mc_dlab, reslab)
  mcK(mc_datak, 0)

  // Compile some functions to call

  mcKKK(mc_entry, 1, 3, 5) // F1(x, y, z) = x+y-z
  mcRA(mc_mv,  A, a1)
  mcRA(mc_add, A, a2)
  mcRA(mc_sub, A, a3)
  mcF(mc_rtn)
  mcF(mc_endfn)

  mcKKK(mc_entry, 2, 3, 5) // F2(x, y, z) = F1(x, y, z) + F3(x+1, y+1, z+1)

  mcRA(mc_mv,   B, a1)
  mcRA(mc_mv,   C, a2)
  mcRA(mc_mv,   D, a3)

  mcR( mc_push, D)
  mcR( mc_push, C)
  mcR( mc_push, B)
  mcKK(mc_call, 1, 3)      // Call F1(x, y, z)
  mcRR(mc_mv,   E, A)

  mcRK(mc_add,  B, 1)
  mcRK(mc_add,  C, 1)
  mcRK(mc_add,  D, 1)

  mcR( mc_push, D)
  mcR( mc_push, C)
  mcR( mc_push, B)
  mcKK(mc_call, 3, 3)      // Call F3(x+1, y+1, z+1) -- forward ref
  mcRR(mc_add,  A, E)

  mcF(mc_rtn)
  mcF(mc_endfn)

  mcKKK(mc_entry, 3, 3, 5) // F3(x, y, z) = F1(z, y, x)

  mcA(mc_push,  a1)
  mcA(mc_push,  a2)
  mcA(mc_push,  a3)
  mcKK(mc_call, 1, 3)      // Call F1(z, y, x)

  mcF(mc_rtn)
  mcF(mc_endfn)


  fnstart("Test for: CALL and RET  with r1=%s r2=%s x=%n y=%n z=%n res=%n*n",
           mcrname(r1), mcrname(r2), x, y, z, res)

  mcK(mc_push, z)
  mcK(mc_push, y)
  mcK(mc_push, x)
  mcKK(mc_call, 1, 3)    // Call function F1 with 3 pushed arguments
  mcRK(mc_sub, A, x+y-z) // A should be zero
  mcLR(mc_or, reslab, A)

  mcK(mc_push, z)
  mcK(mc_push, y)
  mcK(mc_push, x)
  mcKK(mc_call, 2, 3)    // Call function F1 with 3 pushed arguments
  mcRK(mc_sub, A, x+y-z + (z+1)+(y+1)-(x+1)) // A should be zero
  mcLR(mc_or, reslab, A)

  mcK(mc_push, G1)
  mcK(mc_push, 888)
  mcK(mc_push, z)
  mcK(mc_push, y)
  mcK(mc_push, x)
  mcKK(mc_call, 1, 3)    // Call function F1(x, y, z)
  mcR( mc_push, A)
  mcKK(mc_call, 1, 3)    // Call function F1(F1(x,y,z),888,999)
  mcRK(mc_sub, A, (x+y-z) + 888 - 999) // A should be zero
  mcLR(mc_or, reslab, A)

  fnend()
}

LET testCDQ(x, y) BE
{ // Set A = x, execute CDQ and test D set to y. 
  LET reslab = mcNextlab()

  mcK(mc_alignd, 4)
  mcL(mc_dlab, reslab)
  mcK(mc_datak, 0)

  fnstart("Test for: CDQ with x=%n y=%n*n", x, y)

  // tests for CDQ  F
  mcRK( mc_mv, A, x)
  mcF(  mc_cdq)
  mcRK( mc_sub, D, y) // Should set D to to y
  mcLR( mc_or, reslab, D)

  mcRL( mc_mv, A, reslab)
  fnend()
}

LET testMUL_UMUL(mcop, x, y, ms, ls) BE
{ // Test MUL and UMUL with operands:  K R A V G M L D DX DXs DXsB
  LET reslab = mcNextlab()
  LET d0 = tabaddr
  LET d1 = tabaddr+4
  LET d2 = tabaddr+8

  mcK(mc_alignd, 4)
  mcL(mc_dlab, reslab)
  mcK(mc_datak, 0)

  fnstart("Test for: %s with x=%n and y=%n*n",
           (mcop=mc_mul -> "MUL", "UMUL"), x, y)

  // tests for MUL UMUL

  mcRK( mc_mv,  A, x)
//mcPRF("%8x ** ", A)
//mcRK( mc_mv,  B, y)
//mcPRF("%8x => ", B)
  mcK(  mcop, y)         //  K
//mcPRF("%8x ",  D)
//mcPRF("%8x*n", A)
  mcRK( mc_sub, D, ms)      // test ms 32 bits
  mcLR( mc_or,  reslab, D)
  mcRK( mc_sub, A, ls)      // test ls 32 bits
  mcLR( mc_or,  reslab, A)

  mcRK( mc_mv,  A, x)
//mcPRF("%8x ** ", A)
  mcRK( mc_mv,  B, y)
//mcPRF("%8x => ", B)
  mcR(  mcop, B)         // R
//mcPRF("%8x ",  D)
//mcPRF("%8x*n", A)
  mcRK( mc_sub, D, ms)      // test ms 32 bits
  mcLR( mc_or,  reslab, D)
  mcRK( mc_sub, A, ls)      // test ls 32 bits
  mcLR( mc_or,  reslab, A)


  mcRK(   mc_mv,  A, x)
  mcAK(   mc_mv,  a1, y)
  mcA(    mcop,   a1)             // A
  mcRK(   mc_sub, D, ms)
  mcLR(   mc_or,  reslab, D)
  mcRK(   mc_sub, A, ls)
  mcLR(   mc_or,  reslab, A)

  mcRK(   mc_mv,  A, x)
  mcVK(   mc_mv,  v1, y)
  mcV(    mcop,   v1)             // V
  mcRK(   mc_sub, D, ms)
  mcLR(   mc_or,  reslab, D)
  mcRK(   mc_sub, A, ls)
  mcLR(   mc_or,  reslab, A)

  mcRK(   mc_mv,  A, x)
  mcGK(   mc_mv,  G1, y)
  mcG(    mcop,   G1)             // G
  mcRK(   mc_sub, D, ms)
  mcLR(   mc_or,  reslab, D)
  mcRK(   mc_sub, A, ls)
  mcLR(   mc_or,  reslab, A)

  mcRK(   mc_mv,  A, x)
  mcMK(   mc_mv,  99, y)
  mcM(    mcop,   99)             // M
  mcRK(   mc_sub, D, ms)
  mcLR(   mc_or,  reslab, D)
  mcRK(   mc_sub, A, ls)
  mcLR(   mc_or,  reslab, A)

  mcRK(   mc_mv,  A, x)
  mcDK(   mc_mv,  d1, y)
  mcD(    mcop,   d1)             // D
  mcRK(   mc_sub, D, ms)
  mcLR(   mc_or,  reslab, D)
  mcRK(   mc_sub, A, ls)
  mcLR(   mc_or,  reslab, A)

  mcRL(   mc_lea, C, tablab)
  mcRK(   mc_mv,  A, x)
  mcDXK(  mc_mv,  0, C, y)
  mcDX(   mcop,   0, C)             // DX
  mcRK(   mc_sub, D, ms)
  mcLR(   mc_or,  reslab, D)
  mcRK(   mc_sub, A, ls)
  mcLR(   mc_or,  reslab, A)

  mcRL(   mc_lea, C, tablab)
  mcRK(   mc_mv,  A, x)
  mcDXK(  mc_mv,  4, C, y)
  mcDX(   mcop,   4, C)             // DX
  mcRK(   mc_sub, D, ms)
  mcLR(   mc_or,  reslab, D)
  mcRK(   mc_sub, A, ls)
  mcLR(   mc_or,  reslab, A)

  mcRL(   mc_lea, C, tablab)
  mcRK(   mc_mv,  A, x)
  mcDXK(  mc_mv,  400, C, y)
  mcDX(   mcop,   400, C)             // DX
  mcRK(   mc_sub, D, ms)
  mcLR(   mc_or,  reslab, D)
  mcRK(   mc_sub, A, ls)
  mcLR(   mc_or,  reslab, A)

  FOR sh = 0 TO 3 DO
  { LET s = 1<<sh

    mcRL(mc_lea, C, tablab); mcRK(  mc_rsh, C, sh) // C = tabaddr>>sh

    mcRK(   mc_mv,  A, x)
    mcDXsK( mc_mv,  0, C, s, y)
    mcDXs(  mcop,   0, C, s)             // DXs
    mcRK(   mc_sub, D, ms)
    mcLR(   mc_or,  reslab, D)
    mcRK(   mc_sub, A, ls)
    mcLR(   mc_or,  reslab, A)

    mcRL(mc_lea, C, tablab); mcRK(  mc_rsh, C, sh) // C = tabaddr>>sh

    mcRK(   mc_mv,  A, x)
    mcDXsK( mc_mv,  4, C, s, y)
    mcDXs(  mcop,   4, C, s)             // DXs
    mcRK(   mc_sub, D, ms)
    mcLR(   mc_or,  reslab, D)
    mcRK(   mc_sub, A, ls)
    mcLR(   mc_or,  reslab, A)

    mcRL(mc_lea, C, tablab); mcRK(  mc_rsh, C, sh) // C = tabaddr>>sh

    mcRK(   mc_mv,  A, x)
    mcDXsK( mc_mv,  400, C, s, y)
    mcDXs(  mcop,   400, C, s)             // DXs
    mcRK(   mc_sub, D, ms)
    mcLR(   mc_or,  reslab, D)
    mcRK(   mc_sub, A, ls)
    mcLR(   mc_or,  reslab, A)
  }

  FOR sh = 0 TO 3 DO
  { LET s = 1<<sh

    mcRL(mc_lea, C, tablab); mcRK(  mc_rsh, C, sh) // C = tabaddr>>sh
    mcRK(   mc_mv,  E,      4)

    mcRK(   mc_mv,  A, x)
    mcDXsBK(mc_mv,  0, C, s, B, y)
    mcDXsB( mcop,   0, C, s, B)             // DXsB
    mcRK(   mc_sub, D, ms)
    mcLR(   mc_or,  reslab, D)
    mcRK(   mc_sub, A, ls)
    mcLR(   mc_or,  reslab, A)

    mcRL(mc_lea, C, tablab); mcRK(  mc_rsh, C, sh) // C = tabaddr>>sh
    mcRK(   mc_mv,  E,      4)

    mcRK(   mc_mv,  A, x)
    mcDXsBK(mc_mv,  4, C, s, B, y)
    mcDXsB( mcop,   4, C, s, B)             // DXsB
    mcRK(   mc_sub, D, ms)
    mcLR(   mc_or,  reslab, D)
    mcRK(   mc_sub, A, ls)
    mcLR(   mc_or,  reslab, A)

    mcRL(mc_lea, C, tablab); mcRK(  mc_rsh, C, sh) // C = tabaddr>>sh
    mcRK(   mc_mv,  E,      4)

    mcRK(   mc_mv,  A, x)
    mcDXsBK(mc_mv,  400, C, s, B, y)
    mcDXsB( mcop,   400, C, s, B)             // DXsB
    mcRK(   mc_sub, D, ms)
    mcLR(   mc_or,  reslab, D)
    mcRK(   mc_sub, A, ls)
    mcLR(   mc_or,  reslab, A)
  }

  mcRL( mc_mv, A, reslab)
  fnend()
}

LET testDIV_UDIV(mcop, d, a, x, ms, ls) BE
{ // Test DIV UDIV with operands:  K R A V G M L D DX DXs DXsB

  LET reslab = mcNextlab()
  LET d0 = tabaddr
  LET d1 = tabaddr+4
  LET d2 = tabaddr+8

  mcK(mc_alignd, 4)
  mcL(mc_dlab, reslab)
  mcK(mc_datak, 0)

  fnstart("Test for: %s  with <%x8 %x8> op %x8*n",
           (mcop=mc_div -> "DIV", "UDIV"), ms, ls, x)

  mcRK(   mc_mv,  D, d)
  mcRK(   mc_mv,  A, a)
  mcRK(   mc_mv,  B, x)
//mcPRF("<%8x ", D)
//mcPRF("%8x> op ", A)
//mcPRF("%8x ", B)
  mcR(    mcop,   B)              // R
//mcPRF("=> %8x ", D)
//mcPRF("%8x*n", A)
  mcRK(   mc_sub, D, ms)
  mcLR(   mc_or,  reslab, D)
  mcRK(   mc_sub, A, ls)
  mcLR(   mc_or,  reslab, A)

  mcRK(   mc_mv,  D, d)
  mcRK(   mc_mv,  A, a)
  mcRK(   mc_mv,  B, x)
  mcK(    mcop,   x)              // K
  mcRK(   mc_sub, D, ms)
  mcLR(   mc_or,  reslab, D)
  mcRK(   mc_sub, A, ls)
  mcLR(   mc_or,  reslab, A)


  mcRK(   mc_mv,  D, d)
  mcRK(   mc_mv,  A, a)
  mcAK(   mc_mv,  a1, x)
  mcA(    mcop,   a1)             // A
  mcRK(   mc_sub, D, ms)
  mcLR(   mc_or,  reslab, D)
  mcRK(   mc_sub, A, ls)
  mcLR(   mc_or,  reslab, A)

  mcRK(   mc_mv,  D, d)
  mcRK(   mc_mv,  A, a)
  mcVK(   mc_mv,  v1, x)
  mcV(    mcop,   v1)             // V
  mcRK(   mc_sub, D, ms)
  mcLR(   mc_or,  reslab, D)
  mcRK(   mc_sub, A, ls)
  mcLR(   mc_or,  reslab, A)

  mcRK(   mc_mv,  D, d)
  mcRK(   mc_mv,  A, a)
  mcGK(   mc_mv, G1, x)
  mcG(    mcop,   G1)            // G
  mcRK(   mc_sub, D, ms)
  mcLR(   mc_or,  reslab, D)
  mcRK(   mc_sub, A, ls)
  mcLR(   mc_or,  reslab, A)

  mcRK(   mc_mv,  D, d)
  mcRK(   mc_mv,  A, a)
  mcMK(   mc_mv, 99, x)
  mcM(    mcop,   99)             // M
  mcRK(   mc_sub, D, ms)
  mcLR(   mc_or,  reslab, D)
  mcRK(   mc_sub, A, ls)
  mcLR(   mc_or,  reslab, A)

  mcRK(   mc_mv,  D, d)
  mcRK(   mc_mv,  A, a)
  mcDK(   mc_mv, d1, x)
  mcD(    mcop,   d1)      // D
  mcRK(   mc_sub, D, ms)
  mcLR(   mc_or,  reslab, D)
  mcRK(   mc_sub, A, ls)
  mcLR(   mc_or,  reslab, A)

  mcRL(   mc_lea, C, tablab)
  mcRK(   mc_mv,  D, d)
  mcRK(   mc_mv,  A, a)
  mcDXK(   mc_mv, 0, C, x)
  mcDX(   mcop,   0, C)   // DX
  mcRK(   mc_sub, D, ms)
  mcLR(   mc_or,  reslab, D)
  mcRK(   mc_sub, A, ls)
  mcLR(   mc_or,  reslab, A)

  mcRL(   mc_lea, C, tablab)
  mcRK(   mc_mv,  D, d)
  mcRK(   mc_mv,  A, a)
  mcDXK(   mc_mv, 4, C, x)
  mcDX(   mcop,   4, C)   // DX
  mcRK(   mc_sub, D, ms)
  mcLR(   mc_or,  reslab, D)
  mcRK(   mc_sub, A, ls)
  mcLR(   mc_or,  reslab, A)

  mcRL(   mc_lea, C, tablab)
  mcRK(   mc_mv,  D, d)
  mcRK(   mc_mv,  A, a)
  mcDXK(   mc_mv, 400, C, x)
  mcDX(   mcop,   400, C)   // DX
  mcRK(   mc_sub, D, ms)
  mcLR(   mc_or,  reslab, D)
  mcRK(   mc_sub, A, ls)
  mcLR(   mc_or,  reslab, A)

  FOR sh = 0 TO 3 DO
  { LET s = 1<<sh

    mcRL(mc_lea, C, tablab); mcRK(  mc_rsh, C, sh) // C = tabaddr>>sh

    mcRK(   mc_mv,  D, d)
    mcRK(   mc_mv,  A, a)
    mcDK(   mc_mv, d0, x)
    mcDXs(   mcop,   0, C, s)          // DXs
    mcRK(   mc_sub, D, ms)
    mcLR(   mc_or,  reslab, D)
    mcRK(   mc_sub, A, ls)
    mcLR(   mc_or,  reslab, A)

    mcRL(mc_lea, C, tablab); mcRK(  mc_rsh, C, sh) // C = tabaddr>>sh

    mcRK(   mc_mv,  D, d)
    mcRK(   mc_mv,  A, a)
    mcDK(   mc_mv, d1, x)
    mcDXs(   mcop,   4, C, s)          // DXs
    mcRK(   mc_sub, D, ms)
    mcLR(   mc_or,  reslab, D)
    mcRK(   mc_sub, A, ls)
    mcLR(   mc_or,  reslab, A)

    mcRL(mc_lea, C, tablab); mcRK(  mc_rsh, C, sh) // C = tabaddr>>sh

    mcRK(   mc_mv,  D, d)
    mcRK(   mc_mv,  A, a)
    mcDK(   mc_mv, d0+400, x)
    mcDXs(   mcop,   400, C, s)          // DXs
    mcRK(   mc_sub, D, ms)
    mcLR(   mc_or,  reslab, D)
    mcRK(   mc_sub, A, ls)
    mcLR(   mc_or,  reslab, A)
  }

  FOR sh = 0 TO 3 DO
  { LET s = 1<<sh

    mcRL(mc_lea, C, tablab); mcRK(  mc_rsh, C, sh) // C = tabaddr>>sh
    mcRK(   mc_mv,  E,      4)

    mcRK(   mc_mv,  D, d)
    mcRK(   mc_mv,  A, a)
    mcDK(   mc_mv, d1, x)
    mcDXsB(   mcop,   0, C, s, E)       // DXsB
    mcRK(   mc_sub, D, ms)
    mcLR(   mc_or,  reslab, D)
    mcRK(   mc_sub, A, ls)
    mcLR(   mc_or,  reslab, A)

    mcRL(mc_lea, C, tablab); mcRK(  mc_rsh, C, sh) // C = tabaddr>>sh
    mcRK(   mc_mv,  E,      4)

    mcRK(   mc_mv,  D, d)
    mcRK(   mc_mv,  A, a)
    mcDK(   mc_mv, d2, x)
    mcDXsB(   mcop,   4, C, s, E)       // DXsB
    mcRK(   mc_sub, D, ms)
    mcLR(   mc_or,  reslab, D)
    mcRK(   mc_sub, A, ls)
    mcLR(   mc_or,  reslab, A)

    mcRL(mc_lea, C, tablab); mcRK(  mc_rsh, C, sh) // C = tabaddr>>sh
    mcRK(   mc_mv,  E,      4)

    mcRK(   mc_mv,  D, d)
    mcRK(   mc_mv,  A, a)
    mcDK(   mc_mv, d0+404, x)
    mcDXsB(  mcop,   400, C, s, E)       // DXsB
    mcRK(   mc_sub, D, ms)
    mcLR(   mc_or,  reslab, D)
    mcRK(   mc_sub, A, ls)
    mcLR(   mc_or,  reslab, A)
  }

  mcRL( mc_mv, A, reslab)
  fnend()
}

LET testJMP_CMP_Jcc_SETcc() BE
{ testJMP()                                  // jmp

  testJcc("jeq", mc_jeq,   1,   2, FALSE)    // jeq
  testJcc("jeq", mc_jeq, -11, -11, TRUE)

  testJcc("jne", mc_jne,   1,   2, TRUE)     // jne
  testJcc("jne", mc_jne, -11, -11, FALSE)

  testJcc("jlt", mc_jlt,   1,   2, TRUE)     // jlt
  testJcc("jlt", mc_jlt, -11, -11, FALSE)
  testJcc("jlt", mc_jlt, #x80000000, #x7FFFFFFF, TRUE)
  testJcc("jlt", mc_jlt, #x7FFFFFFF, #x80000000, FALSE)

  testJcc("jle", mc_jle,   1,   2, TRUE)     // jle
  testJcc("jle", mc_jle, -11, -11, TRUE)
  testJcc("jle", mc_jle, #x80000000, #x7FFFFFFF, TRUE)
  testJcc("jle", mc_jle, #x7FFFFFFF, #x80000000, FALSE)

  testJcc("jgt", mc_jgt,   1,   2, FALSE)    // jgt
  testJcc("jgt", mc_jgt, -11, -11, FALSE)
  testJcc("jgt", mc_jgt, #x80000000, #x7FFFFFFF, FALSE)
  testJcc("jgt", mc_jgt, #x7FFFFFFF, #x80000000, TRUE)

  testJcc("jge", mc_jge,   1,   2, FALSE)    // jge
  testJcc("jge", mc_jge, -11, -11, TRUE)
  testJcc("jge", mc_jge, #x80000000, #x7FFFFFFF, FALSE)
  testJcc("jge", mc_jge, #x7FFFFFFF, #x80000000, TRUE)

  testJcc("ujlt", mc_ujlt,   1,   2, TRUE)     // jlt
  testJcc("ujlt", mc_ujlt, -11, -11, FALSE)
  testJcc("ujlt", mc_ujlt, #x80000000, #x7FFFFFFF, FALSE)
  testJcc("ujlt", mc_ujlt, #x7FFFFFFF, #x80000000, TRUE)

  testJcc("ujle", mc_ujle,   1,   2, TRUE)    // ujle
  testJcc("ujle", mc_ujle, -11, -11, TRUE)
  testJcc("ujle", mc_ujle, #x80000000, #x7FFFFFFF, FALSE)
  testJcc("ujle", mc_ujle, #x7FFFFFFF, #x80000000, TRUE)

  testJcc("ujgt", mc_ujgt,   1,   2, FALSE)   // ujgt
  testJcc("ujgt", mc_ujgt, -11, -11, FALSE)
  testJcc("ujgt", mc_ujgt, #x80000000, #x7FFFFFFF, TRUE)
  testJcc("ujgt", mc_ujgt, #x7FFFFFFF, #x80000000, FALSE)

  testJcc("ujge", mc_ujge,   1,   2, FALSE)   // ujge
  testJcc("ujge", mc_ujge, -11, -11, TRUE)
  testJcc("ujge", mc_ujge, #x80000000, #x7FFFFFFF, TRUE)
  testJcc("ujge", mc_ujge, #x7FFFFFFF, #x80000000, FALSE)


  testSETcc("seq", mc_seq,   1,   2, 0)     // seq
  testSETcc("seq", mc_seq, -11, -11, 1)
  testSETcc("seq", mc_seq, #x80000000, #x7FFFFFFF, 0)
  testSETcc("seq", mc_seq, #x7FFFFFFF, #x80000000, 0)

  testSETcc("sne", mc_sne,   1,   2, 1)     // sne
  testSETcc("sne", mc_sne, -11, -11, 0)
  testSETcc("sne", mc_sne, #x80000000, #x7FFFFFFF, 1)
  testSETcc("sne", mc_sne, #x7FFFFFFF, #x80000000, 1)

  testSETcc("slt", mc_slt,   1,   2, 1)     // slt
  testSETcc("slt", mc_slt, -11, -11, 0)
  testSETcc("slt", mc_slt, #x80000000, #x7FFFFFFF, 1)
  testSETcc("slt", mc_slt, #x7FFFFFFF, #x80000000, 0)

  testSETcc("sle", mc_sle,   1,   2, 1)     // sle
  testSETcc("sle", mc_sle, -11, -11, 1)
  testSETcc("sle", mc_sle, #x80000000, #x7FFFFFFF, 1)
  testSETcc("sle", mc_sle, #x7FFFFFFF, #x80000000, 0)

  testSETcc("sgt", mc_sgt,   1,   2, 0)    // sgt
  testSETcc("sgt", mc_sgt, -11, -11, 0)
  testSETcc("sgt", mc_sgt, #x80000000, #x7FFFFFFF, 0)
  testSETcc("sgt", mc_sgt, #x7FFFFFFF, #x80000000, 1)

  testSETcc("sge", mc_sge,   1,   2, 0)    // sge
  testSETcc("sge", mc_sge, -11, -11, 1)
  testSETcc("sge", mc_sge, #x80000000, #x7FFFFFFF, 0)
  testSETcc("sge", mc_sge, #x7FFFFFFF, #x80000000, 1)

  testSETcc("uslt", mc_uslt,   1,   2, 1)     // slt
  testSETcc("uslt", mc_uslt, -11, -11, 0)
  testSETcc("uslt", mc_uslt, #x80000000, #x7FFFFFFF, 0)
  testSETcc("uslt", mc_uslt, #x7FFFFFFF, #x80000000, 1)

  testSETcc("usle", mc_usle,   1,   2, 1)    // usle
  testSETcc("usle", mc_usle, -11, -11, 1)
  testSETcc("usle", mc_usle, #x80000000, #x7FFFFFFF, 0)
  testSETcc("usle", mc_usle, #x7FFFFFFF, #x80000000, 1)

  testSETcc("usgt", mc_usgt,   1,   2, 0)   // usgt
  testSETcc("usgt", mc_usgt, -11, -11, 0)
  testSETcc("usgt", mc_usgt, #x80000000, #x7FFFFFFF, 1)
  testSETcc("usgt", mc_usgt, #x7FFFFFFF, #x80000000, 0)

  testSETcc("usge", mc_usge,   1,   2, 0)   // usge
  testSETcc("usge", mc_usge, -11, -11, 1)
  testSETcc("usge", mc_usge, #x80000000, #x7FFFFFFF, 1)
  testSETcc("usge", mc_usge, #x7FFFFFFF, #x80000000, 0)
/**/
}

AND testJMP() BE
{ LET L1 = mcNextlab()
  LET L2 = mcNextlab()
  LET L3 = mcNextlab()
  LET L4 = mcNextlab()
  LET L5 = mcNextlab()
  LET L6 = mcNextlab()

  fnstart("Testing JMP instructions*n")
  mcRK(mc_mv, A, 0)
  mcJL(mc_jmp, L6)           // A long jump forward

  mcRK(mc_mv, A, #x12345678) // Not executed

  mcL( mc_lab, L1)
  mcRK(mc_add, A, 1)
  mcJS(mc_jmp, L2)           // A short jump forward

  mcRK(mc_mv, A, #x12345678) // Not executed

  mcL( mc_lab, L2)
  mcRK(mc_add, A, 1)
  mcJS(mc_jmp, L4)           // A short jump forward

  mcRK(mc_mv, A, #x12345678) // Not executed

  mcL( mc_lab, L3)
  mcRK(mc_add, A, 1)
  mcJS(mc_jmp, L5)           // A short jump forward

  mcRK(mc_mv, A, #x12345678) // Not executed

  mcL( mc_lab, L4)
  mcRK(mc_add, A, 1)
  mcJL(mc_jmp, L3)           // A short jump backward

  mcRK(mc_mv, A, #x12345678) // Not executed

  mcL( mc_lab, L5)
  mcRK(mc_add, A, 1)
  FOR i = 1 TO 128 DO mcRK(mc_add, A, 1)
  mcRK(mc_sub, A, 1+1+1+1++1+1+128)
  mcF(mc_rtn)

  mcRK(mc_mv, A, #x12345678) // Not executed

  mcL( mc_lab, L6)
  mcRK(mc_add, A, 1)
  mcJL(mc_jmp, L1)           // A long jump backwards

  fnend()
}

AND testJcc(opname, op, x, y, flag) BE
{ // Test jeq jne jlt jle jgt jge ujlt ujle ujgt ujge
  // flag = TRUE if the jump should be taken
  LET lab = mcNextlab()

  fnstart("Testing %s %n on %x8 and %x8*n", opname, op, x, y)
  TEST flag THEN mcRK(mc_mv, A, 0)
            ELSE mcRK(mc_mv, A, 1)
  mcRK(mc_mv,  B, x)
  mcRK(mc_cmp, B, y)
  mcJS(op, lab)
  TEST flag THEN mcRK(mc_mv, A, 1)
            ELSE mcRK(mc_mv, A, 0)
  mcL(mc_lab, lab)
  mcF(mc_rtn)
  mcF(mc_endfn)
}

AND testSETcc(opname, op, x, y, res) BE
{ // Test seq sne slt sle sgt sge uslt usle usgt usge
  // res = the required result

  fnstart("Testing %s on %x8 and %x8*n", opname, x, y)
  mcRK(mc_mv,  B, x)
  mcRK(mc_cmp, B, y)
  mcRK(mc_mv, A, #x12345678)
  mcR(op, A)
  mcRK(mc_sub, A, res)
  mcF(mc_rtn)
  mcF(mc_endfn)
}

LET testLEA() BE
{ // Test LEA
  //   RA RV RG RM RL RD RDX RDXs RDXsB

  LET reslab = mcNextlab()
  LET lab = mcNextlab()
  LET d0 = tabaddr
  LET d1 = tabaddr+4
  LET d2 = tabaddr+8
  LET val = 123

  mcK(mc_alignd, 4)
  mcL(mc_dlab, reslab)
  mcK(mc_datak, 0)
  mcL(mc_dlab, lab)
  mcK(mc_datak, 0)

  fnstart("Test for: LEA*n")

  mcRA(   mc_lea,   A, a1)         // RA
  mcAK(   mc_mv,    a1, val)    
  mcRDX(  mc_mv,    A, 0, A) 
  mcRK(   mc_sub,   A, val)
  mcLR(   mc_or,  reslab, A)

  mcRV(   mc_lea,   A, v1)         // RV
  mcVK(   mc_mv,    v1, val)    
  mcRDX(  mc_mv,    A, 0, A) 
  mcRK(   mc_sub,   A, val)
  mcLR(   mc_or,  reslab, A)

  mcRG(   mc_lea,   A, G1)         // RG
  mcGK(   mc_mv,   G1, val)    
  mcRDX(  mc_mv,    A, 0, A) 
  mcRK(   mc_sub,   A, val)
  mcLR(   mc_or,  reslab, A)

  mcRM(   mc_lea,   A, 99)         // RM
  mcMK(   mc_mv,    99, val)    
  mcRDX(  mc_mv,    A, 0, A) 
  mcRK(   mc_sub,   A, val)
  mcLR(   mc_or,  reslab, A)

  mcRL(   mc_lea,   A, lab)         // RL
  mcLK(   mc_mv,    lab, val)    
  mcRDX(  mc_mv,    A, 0, A) 
  mcRK(   mc_sub,   A, val)
  mcLR(   mc_or,  reslab, A)

  mcRD(   mc_lea,   A, d1)         // RD
  mcDK(   mc_mv,    d1, val)    
  mcRDX(  mc_mv,    A, 0, A) 
  mcRK(   mc_sub,   A, val)
  mcLR(   mc_or,  reslab, A)

  mcRL(   mc_lea,   C, tablab)
  mcRDX(  mc_lea,   A, 0, C)         // RDX
  mcDK(   mc_mv,    d0, val)    
  mcRDX(  mc_mv,    A, 0, A) 
  mcRK(   mc_sub,   A, val)
  mcLR(   mc_or,  reslab, A)

  mcRL(mc_lea, C, tablab); mcRK(  mc_rsh, C, 2) // C = tabaddr>>2

  mcRDXs( mc_lea,   A, 4, C, 4)         // RDXs
  mcDK(   mc_mv,    d1, val)    
  mcRDX(  mc_mv,    A, 0, A) 
  mcRK(   mc_sub,   A, val)
  mcLR(   mc_or,  reslab, A)

  mcRL(mc_lea, C, tablab); mcRK(  mc_rsh, C, 3) // C = tabaddr>>3

  mcRK(   mc_sub,   E, 4)
  mcRDXsB( mc_lea,  A, 4, C, 8, E)         // RDXsB
  mcDK(   mc_mv,    d2, val)    
  mcRDX(  mc_mv,    A, 0, A) 
  mcRK(   mc_sub,   A, val)
  mcLR(   mc_or,  reslab, A)

  mcRL( mc_mv, A, reslab)
  fnend()
}



LET testMV() BE
{ // Test the following:
  // All 32-bit moves.

  // mv              RA RV RG RM RL RD RDX RDXs RDXsB
  //              RR AR VR GR MR LR DR DXR DXsR DXsBR
  //              RK AK VK GK MK LK DK DXK DXsK DXsBK

  LET reslab = mcNextlab()
  LET L1  = mcNextlab()
  LET L2  = mcNextlab()
  LET d1 = tabaddr+4
  LET d2 = tabaddr+8
  LET w1 = #xA1B2C3D4
  LET w2 = #x12345678

  mcK(mc_alignd, 4)
  mcL(mc_dlab, reslab)
  mcK(mc_datak, 0)
  mcL(mc_dlab, L1)
  mcK(mc_datak, 0)
  mcL(mc_dlab, L2)
  mcK(mc_datak, 0)

  fnstart("Test for: MV instructions*n")

  // RR  RK
  mcRK(   mc_mv,   A,  w1)       // mv    RK
  mcRK(   mc_mv,   B,  w2)
  mcRR(   mc_mv,   C,  A)        // mv    RR
  mcRR(   mc_mv,   D,  B)
  mcRR(   mc_add,  C,  D)
  mcRK(   mc_sub,  C,  w1+w2)
  mcLR(   mc_or,  reslab, C)

  // RA  AR  AK
  mcAK(   mc_mv,   a1, w1)       // mv    AK
  mcRK(   mc_mv,   B,  w2)
  mcAR(   mc_mv,   a2,  B)       // mv    AR
  mcRA(   mc_mv,   A,  a1)       // mv    RA
  mcRA(   mc_add,  A,  a2)
  mcRK(   mc_sub,  A,  w1+w2)
  mcLR(   mc_or,  reslab, A)

  // RV  VR  VK
  mcVK(   mc_mv,   v1, w1)       // mv    VK
  mcRK(   mc_mv,   B,  w2)
  mcVR(   mc_mv,   v2,  B)       // mv    VR
  mcRV(   mc_mv,   A,  v1)       // mv    RV
  mcRV(   mc_add,  A,  v2)
  mcRK(   mc_sub,  A,  w1+w2)
  mcLR(   mc_or,  reslab, A)

  // RG  GR  GK
  mcGK(   mc_mv,  G1, w1)       // mv    GK
  mcRK(   mc_mv,   B,  w2)
  mcGR(   mc_mv,  G2,  B)       // mv    GR
  mcRG(   mc_mv,   A, G1)       // mv    RG
  mcRG(   mc_add,  A, G2)
  mcRK(   mc_sub,  A,  w1+w2)
  mcLR(   mc_or,  reslab, A)

  // RM  MR  MK
  mcMK(   mc_mv,   99, w1)       // mv    MK
  mcRK(   mc_mv,   B,  w2)
  mcMR(   mc_mv,   98,  B)       // mv    MR
  mcRM(   mc_mv,   A,  99)       // mv    RM
  mcRM(   mc_add,  A,  98)
  mcRK(   mc_sub,  A,  w1+w2)
  mcLR(   mc_or,  reslab, A)

  // RL  LR  LK
  mcLK(   mc_mv,   L1, w1)     // mv    LK
  mcRK(   mc_mv,   B,  w2)
  mcLR(   mc_mv,   L2,  B)     // mv    LR
  mcRL(   mc_mv,   A,  L1)     // mv    RL
  mcRL(   mc_add,  A,  L2)
  mcRK(   mc_sub,  A,  w1+w2)
  mcLR(   mc_or,  reslab, A)

  // RD  DR  DK
  mcDK(   mc_mv,   d1, w1)  // mv    DK
  mcRK(   mc_mv,   B,  w2)
  mcDR(   mc_mv,   d2,  B)  // mv    DR
  mcRD(   mc_mv,   A,  d1)  // mv    RD
  mcRD(   mc_add,  A,  d2)
  mcRK(   mc_sub,  A,  w1+w2)
  mcLR(   mc_or,  reslab, A)

  mcRL(   mc_lea,  C, tablab)

  // RDX  DXR  DXK
  mcDXK(  mc_mv,   0, C, w1)  // mv    DXK
  mcRK(   mc_mv,   B, w2)
  mcDXR(  mc_mv,   4, C,  B)  // mv    DXR
  mcRDX(  mc_mv,   A, 0, C)   // mv    RDX
  mcRDX(  mc_add,  A, 4, C)
  mcRK(   mc_sub,  A, w1+w2)
  mcLR(   mc_or,  reslab, A)


  mcRL(mc_lea, C, tablab); mcRK(  mc_rsh, C, 2) // C = tabaddr>>2

  // RDXs  DXsR  DXsK
  mcDXsK( mc_mv,   0, C, 4, w1)  // mv    DXsK
  mcRK(   mc_mv,   B, w2)
  mcDXsR( mc_mv,   4, C, 4, B)   // mv    DXsR
  mcRDXs( mc_mv,   A, 0, C, 4)   // mv    RDXs
  mcRDXs( mc_mv,   D, 0, C, 4)   // mv    RDXs
  mcRR(   mc_add,  A, D)
  mcRDXs( mc_add,  A, 4, C, 4)
  mcRK(   mc_sub,  A, w1+w1+w2)
  mcLR(   mc_or,  reslab, A)

  mcRL(mc_lea, C, tablab); mcRK(  mc_rsh, C, 3) // C = tabaddr>>3

  // RDXsB  DXsBR  DXsBK
  mcRK(   mc_mv,   E, 4)
  mcDXsBK(mc_mv,   0, C, 8, E, w1)  // mv    DXsBK
  mcRK(   mc_mv,   B, w2)
  mcDXsBR(mc_mv,   4, C, 8, E, B)   // mv    DXsBR
  mcRDXsB(mc_mv,   A, 0, C, 8, E)   // mv    RDXsB
  mcRDXsB(mc_mv,   D, 0, C, 8, E)   // mv    RDXsB
  mcRR(   mc_add,  A, D)
  mcRDXsB(mc_add,  A, 4, C, 8, E)
  mcRK(   mc_sub,  A, w1+w1+w2)
  mcLR(   mc_or,  reslab, A)

  mcRL( mc_mv, A, reslab)
  fnend()
}

LET testMVB_MVH() BE
{ // Test all moves to memory byte or memory halfword.

  // mvb mvh         AR VR GR MR LR DR DXR DXsR DXsBR
  //                 AK VK GK MK LK DK DXK DXsK DXsBK

  LET reslab = mcNextlab()
  LET L1  = mcNextlab()
  LET L2  = mcNextlab()
  LET d1 = tabaddr+4
  LET d2 = tabaddr+8
  LET w1 = #xA1B2C3D4
  LET k1 = #x11223344
  LET litender = (@w1)%0 = #xD4 // =TRUE, if running on a little ender m/c
  LET wb, wh = 0, 0 // After mvb or mvh instruction
  TEST litender
  THEN { wb, wh := #xA1B2C344, #xA1B23344 }
  ELSE { wb, wh := #x44B2C3D4, #x4433C3D4 }

  mcK(mc_alignd, 4)
  mcL(mc_dlab, reslab)
  mcK(mc_datak, 0)
  mcL(mc_dlab, L1)
  mcK(mc_datak, 0)
  mcL(mc_dlab, L2)
  mcK(mc_datak, 0)

  fnstart("Test for: MVB and MVH instructions*n")

  // AR  AK
  mcAK(   mc_mv,  a1, w1)
  mcAK(   mc_mv,  a2, w1)
  mcAK(   mc_mvb, a1, k1)       // mvb   AK
  mcRK(   mc_mv,  B,  k1)
  mcAR(   mc_mvb, a2, B)        // mvb   AR
  mcRA(   mc_mv,  C,  a1)
  mcRK(   mc_sub, C,  wb)
  mcLR(   mc_or,  reslab, C)
  mcRA(   mc_mv,  C,  a2)
  mcRK(   mc_sub, C,  wb)
  mcLR(   mc_or,  reslab, C)

  mcAK(   mc_mv,  a1, w1)
  mcAK(   mc_mv,  a2, w1)
//mcRA(   mc_mv,  D,  a1)
//mcPRF("a1=%8x*n", D)
//mcRA(   mc_mv,  D,  a2)
//mcPRF("a2=%8x*n", D)
//mcRK(   mc_mv, D, k1)
//mcPRF("mvh a1 with k1=%8x*n", D)
  mcAK(   mc_mvh, a1, k1)       // mvh   AK
  mcRK(   mc_mv,  B,  k1)
//mcPRF("mvh a2 with B=%8x*n", B)
  mcAR(   mc_mvh, a2, B)        // mvh   AR
  mcRA(   mc_mv,  C,  a1)
//mcPRF("a1=%8x*n", C)
  mcRK(   mc_sub, C,  wh)
  mcLR(   mc_or,  reslab, C)
  mcRA(   mc_mv,  C,  a2)
//mcPRF("a2=%8x*n", C)
  mcRK(   mc_sub, C,  wh)
  mcLR(   mc_or,  reslab, C)

  // VR  VK
  mcVK(   mc_mv,  v1, w1)
  mcVK(   mc_mv,  v2, w1)
  mcVK(   mc_mvb, v1, k1)       // mvb   AK
  mcRK(   mc_mv,  B,  k1)
  mcVR(   mc_mvb, v2, B)        // mvb   AR
  mcRV(   mc_mv,  C,  v1)
  mcRK(   mc_sub, C,  wb)
  mcLR(   mc_or,  reslab, C)
  mcRV(   mc_mv,  C,  v2)
  mcRK(   mc_sub, C,  wb)
  mcLR(   mc_or,  reslab, C)

  mcVK(   mc_mv,  v1, w1)
  mcVK(   mc_mv,  v2, w1)
  mcVK(   mc_mvh, v1, k1)       // mvh   VK
  mcRK(   mc_mv,  B,  k1)
  mcVR(   mc_mvh, v2, B)        // mvh   VR
  mcRV(   mc_mv,  C,  v1)
  mcRK(   mc_sub, C,  wh)
  mcLR(   mc_or,  reslab, C)
  mcRV(   mc_mv,  C,  v2)
  mcRK(   mc_sub, C,  wh)
  mcLR(   mc_or,  reslab, C)

  // GR  GK
  mcGK(   mc_mv, G1, w1)
  mcGK(   mc_mv, G2, w1)
  mcGK(   mc_mvb,G1, k1)       // mvb   GK
  mcRK(   mc_mv,  B,  k1)
  mcGR(   mc_mvb,G2, B)        // mvb   GR
  mcRG(   mc_mv,  C, G1)
  mcRK(   mc_sub, C,  wb)
  mcLR(   mc_or,  reslab, C)
  mcRG(   mc_mv,  C, G2)
  mcRK(   mc_sub, C,  wb)
  mcLR(   mc_or,  reslab, C)

  mcGK(   mc_mv, G1, w1)
  mcGK(   mc_mv, G2, w1)
  mcGK(   mc_mvh,G1, k1)       // mvh   GK
  mcRK(   mc_mv,  B,  k1)
  mcGR(   mc_mvh,G2, B)        // mvh   GR
  mcRG(   mc_mv,  C, G1)
  mcRK(   mc_sub, C,  wh)
  mcLR(   mc_or,  reslab, C)
  mcRG(   mc_mv,  C, G2)
  mcRK(   mc_sub, C,  wh)
  mcLR(   mc_or,  reslab, C)

  // MR  MK
  mcMK(   mc_mv,  99, w1)
  mcMK(   mc_mv,  98, w1)
  mcMK(   mc_mvb, 99, k1)       // mvb   MK
  mcRK(   mc_mv,  B,  k1)
  mcMR(   mc_mvb, 98, B)        // mvb   MR
  mcRM(   mc_mv,  C,  99)
  mcRK(   mc_sub, C,  wb)
  mcLR(   mc_or,  reslab, C)
  mcRM(   mc_mv,  C,  98)
  mcRK(   mc_sub, C,  wb)
  mcLR(   mc_or,  reslab, C)

  mcMK(   mc_mv,  99, w1)
  mcMK(   mc_mv,  98, w1)
  mcMK(   mc_mvh, 99, k1)       // mvh   MK
  mcRK(   mc_mv,  B,  k1)
  mcMR(   mc_mvh, 98, B)        // mvh   MR
  mcRM(   mc_mv,  C,  99)
  mcRK(   mc_sub, C,  wh)
  mcLR(   mc_or,  reslab, C)
  mcRM(   mc_mv,  C,  98)
  mcRK(   mc_sub, C,  wh)
  mcLR(   mc_or,  reslab, C)

  // LR  LK
  mcLK(   mc_mv, L1, w1)
  mcLK(   mc_mv, L2, w1)
  mcLK(   mc_mvb,L1, k1)       // mvb   LK
  mcRK(   mc_mv,  B,  k1)
  mcLR(   mc_mvb,L2, B)        // mvb   LR
  mcRL(   mc_mv,  C, L1)
  mcRK(   mc_sub, C,  wb)
  mcLR(   mc_or,  reslab, C)
  mcRL(   mc_mv,  C, L2)
  mcRK(   mc_sub, C,  wb)
  mcLR(   mc_or,  reslab, C)

  mcLK(   mc_mv, L1, w1)
  mcLK(   mc_mv, L2, w1)
  mcLK(   mc_mvh,L1, k1)       // mvh   LK
  mcRK(   mc_mv,  B,  k1)
  mcLR(   mc_mvh,L2, B)        // mvh   LR
  mcRL(   mc_mv,  C, L1)
  mcRK(   mc_sub, C,  wh)
  mcLR(   mc_or,  reslab, C)
  mcRL(   mc_mv,  C, L2)
  mcRK(   mc_sub, C,  wh)
  mcLR(   mc_or,  reslab, C)

  // DR  DK
  mcDK(   mc_mv, d1, w1)
  mcDK(   mc_mv, d2, w1)
  mcDK(   mc_mvb,d1, k1)       // mvb   DK
  mcRK(   mc_mv,  B,  k1)
  mcDR(   mc_mvb,d2, B)        // mvb   DR
  mcRD(   mc_mv,  C, d1)
  mcRK(   mc_sub, C,  wb)
  mcLR(   mc_or,  reslab, C)
  mcRD(   mc_mv,  C, d2)
  mcRK(   mc_sub, C,  wb)
  mcLR(   mc_or,  reslab, C)

  mcDK(   mc_mv, d1, w1)
  mcDK(   mc_mv, d2, w1)
  mcDK(   mc_mvh,d1, k1)       // mvh   DK
  mcRK(   mc_mv,  B,  k1)
  mcDR(   mc_mvh,d2, B)        // mvh   DR
  mcRD(   mc_mv,  C, d1)
  mcRK(   mc_sub, C,  wh)
  mcLR(   mc_or,  reslab, C)
  mcRD(   mc_mv,  C, d2)
  mcRK(   mc_sub, C,  wh)
  mcLR(   mc_or,  reslab, C)

  mcRL(   mc_lea,  C, tablab)

  // DXR  DXK
  mcDXK(  mc_mv, 0, C, w1)
  mcDXK(  mc_mv, 4, C, w1)
  mcDXK(  mc_mvb,0, C, k1)       // mvb   DK
  mcRK(   mc_mv,  B,  k1)
  mcDXR(  mc_mvb,4, C, B)        // mvb   DR
  mcRDX(  mc_mv,  D, 0, C)
  mcRK(   mc_sub, D,  wb)
  mcLR(   mc_or,  reslab, D)
  mcRDX(  mc_mv,  D, 4, C)
  mcRK(   mc_sub, D,  wb)
  mcLR(   mc_or,  reslab, D)

  mcDXK(  mc_mv,  0, C, w1)
  mcDXK(  mc_mv,  4, C, w1)
  mcDXK(  mc_mvh, 0, C, k1)      // mvh   DXK
  mcRK(   mc_mv,  B, k1)
  mcDXR(  mc_mvh, 4, C, B)       // mvh   DXR
  mcRDX(  mc_mv,  D, 0, C)
  mcRK(   mc_sub, D, wh)
  mcLR(   mc_or,  reslab, D)
  mcRDX(  mc_mv,  D, 4, C)
  mcRK(   mc_sub, D, wh)
  mcLR(   mc_or,  reslab, D)

  mcRL(mc_lea, C, tablab); mcRK(  mc_rsh, C, 2) // C = tabaddr>>2

  // DXsR  DXsK
  mcDXsK( mc_mv,  0, C, 4, w1+1)
  mcDXsK( mc_mv,  4, C, 4, w1)
//mcRDXs(   mc_mv,  D,  0, C, 4)
//mcPRF("0(,C,4)=%8x*n", D)
//mcRDXs(   mc_mv,  D,  4, C, 4)
//mcPRF("4(,C,4)=%8x*n", D)
//mcRK( mc_mv, D, k1)
//mcPRF("mvh 0(,C,4) with k1=%8x*n", D)
  mcDXsK( mc_mvb, 0, C, 4, k1)      // mvb   DXsK
//mcRDXs(   mc_mv,  D,  0, C, 4)
//mcPRF("0(,C,4)=%8x*n", D)
  mcRK(   mc_mv,  B, k1)
//mcPRF("mvh 4(,C,4) with B=%8x*n", B)
  mcDXsR( mc_mvb, 4, C, 4, B)       // mvb   DXsR
  mcRDXs( mc_mv,  D, 0, C, 4)
  mcRK(   mc_sub, D, wb)
  mcLR(   mc_or,  reslab, D)
  mcRDXs( mc_mv,  D, 4, C, 4)
  mcRK(   mc_sub, D, wb)
  mcLR(   mc_or,  reslab, D)

  mcDXsK( mc_mv, 0, C, 4, w1)
  mcDXsK( mc_mv, 4, C, 4, w1)
  mcDXsK( mc_mvh,0, C, 4, k1)       // mvh   DXsK
  mcRK(   mc_mv,  B,  k1)
  mcDXsR( mc_mvh, 4, C, 4, B)       // mvh   DXsR
  mcRDXs( mc_mv,  D, 0, C, 4)
  mcRK(   mc_sub, D,  wh)
  mcLR(   mc_or,  reslab, D)
  mcRDXs( mc_mv,  D, 4, C, 4)
  mcRK(   mc_sub, D,  wh)
  mcLR(   mc_or,  reslab, D)

  mcRL(mc_lea, C, tablab); mcRK(  mc_rsh, C, 3) // C = tabaddr>>3

  // DXsBR  DXsBK
  mcRK(   mc_mv,   E, 4)

  mcDXsBK(mc_mv, 0, C, 8, E, w1)
  mcDXsBK(mc_mv, 4, C, 8, E, w1)
  mcDXsBK(mc_mvb,0, C, 8, E, k1)       // mvb   DXsBK
  mcRK(   mc_mv,  B,   k1)
  mcDXsBR(mc_mvb, 4, C, 8, E, B)       // mvb   DXsBR
  mcRDXsB(mc_mv,  D,   0, C, 8, E)
  mcRK(   mc_sub, D,   wb)
  mcLR(   mc_or,  reslab, D)
  mcRDXsB(mc_mv,  D,   4, C, 8, E)
  mcRK(   mc_sub, D,   wb)
  mcLR(   mc_or,  reslab, D)


  mcRL( mc_mv, A, reslab)
  fnend()
}

LET testMVSXB_MVSXH_MVZXB_MVZXH() BE
{ // Test all sign or zero extended moves.

  // mvsxb mvsxh mvzxb mvzxh
  //              RR RA RV RG RM RL RD RDX RDXs RDXsB

  LET reslab = mcNextlab()
  LET L1  = mcNextlab()
  LET d0 = tabaddr
  LET d1 = tabaddr+4
  LET d2 = tabaddr+8
  LET w1 = #xA1B2C3D4
  LET w2 = #x12345678
  LET litender = (@w1)%0 = #xD4 // =TRUE, if running on a little ender m/c
  LET sxb, sxh, zxb, zxh = 0, 0, 0, 0
  TEST litender
  THEN { sxb, sxh, zxb, zxh := #xFFFFFFD4, #xFFFFC3D4, #x000000D4, #x0000C3D4 }
  ELSE { sxb, sxh, zxb, zxh := #xFFFFFFA1, #xFFFFA1B2, #x000000A1, #x0000A1B2 }

  mcK(mc_alignd, 4)
  mcL(mc_dlab, reslab)
  mcK(mc_datak, 0)
  mcL(mc_dlab, L1)
  mcK(mc_datak, 0)

  fnstart("Test for: MVSXB, MVSXH, MVZXB and MVZXH instructions*n")

  // RR
  mcRK(   mc_mv,    A,  w1)
  mcRR(   mc_mvsxb, B,  A)        // mvsxb RR
  mcRK(   mc_sub,  B, sxb)
  mcLR(   mc_or,  reslab, B)

  mcRK(   mc_mv,    A,  w1)
  mcRR(   mc_mvsxh, B,  A)        // mvsxb RR
  mcRK(   mc_sub,  B, sxh)
  mcLR(   mc_or,  reslab, B)

  mcRK(   mc_mv,    A,  w1)
  mcRR(   mc_mvzxb, B,  A)        // mvzxb RR
  mcRK(   mc_sub,  B, zxb)
  mcLR(   mc_or,  reslab, B)

  mcRK(   mc_mv,    A,  w1)
  mcRR(   mc_mvzxh, B,  A)        // mvzxb RR
  mcRK(   mc_sub,  B, zxh)
  mcLR(   mc_or,  reslab, B)

  
  // RA
  mcAK(   mc_mv,    a1,  w1)

  mcRA(   mc_mvsxb, B,  a1)       // mvsxb RA
  mcRK(   mc_sub,  B, sxb)
  mcLR(   mc_or,  reslab, B)
  mcRA(   mc_mvsxh, B,  a1)       // mvsxh RA
  mcRK(   mc_sub,  B, sxh)
  mcLR(   mc_or,  reslab, B)
  mcRA(   mc_mvzxb, B,  a1)       // mvzxb RA
  mcRK(   mc_sub,  B, zxb)
  mcLR(   mc_or,  reslab, B)
  mcRA(   mc_mvzxh, B,  a1)       // mvzxh RA
  mcRK(   mc_sub,  B, zxh)
  mcLR(   mc_or,  reslab, B)

  // RV
  mcVK(   mc_mv,    v1,  w1)

  mcRV(   mc_mvsxb, A,  v1)        // mvsxb RV
  mcRK(   mc_sub,  A, sxb)
  mcLR(   mc_or,  reslab, A)
  mcRV(   mc_mvsxh, A,  v1)        // mvsxh RV
  mcRK(   mc_sub,  A,  sxh)
  mcLR(   mc_or,  reslab, A)
  mcRV(   mc_mvzxb, A,  v1)        // mvzxb RV
  mcRK(   mc_sub,  A,  zxb)
  mcLR(   mc_or,  reslab, A)
  mcRV(   mc_mvzxh, A,  v1)        // mvzxh RV
  mcRK(   mc_sub,  A,  zxh)
  mcLR(   mc_or,  reslab, A)

  // RG
  mcGK(   mc_mv,   G1,  w1)

  mcRG(   mc_mvsxb, A, G1)        // mvsxb RG
  mcRK(   mc_sub,  A, sxb)
  mcLR(   mc_or,  reslab, A)
  mcRG(   mc_mvsxh, A, G1)        // mvsxh RG
  mcRK(   mc_sub,  A,  sxh)
  mcLR(   mc_or,  reslab, A)
  mcRG(   mc_mvzxb, A, G1)        // mvzxb RG
  mcRK(   mc_sub,  A,  zxb)
  mcLR(   mc_or,  reslab, A)
  mcRG(   mc_mvzxh, A, G1)        // mvzxh RG
  mcRK(   mc_sub,  A,  zxh)
  mcLR(   mc_or,  reslab, A)

  // RM
  mcMK(   mc_mv,    99,  w1)

  mcRM(   mc_mvsxb, A,  99)        // mvsxb RM
  mcRK(   mc_sub,  A, sxb)
  mcLR(   mc_or,  reslab, A)
  mcRM(   mc_mvsxh, A,  99)        // mvsxh RM
  mcRK(   mc_sub,  A,  sxh)
  mcLR(   mc_or,  reslab, A)
  mcRM(   mc_mvzxb, A,  99)        // mvzxb RM
  mcRK(   mc_sub,  A,  zxb)
  mcLR(   mc_or,  reslab, A)
  mcRM(   mc_mvzxh, A,  99)        // mvzxh RM
  mcRK(   mc_sub,  A,  zxh)
  mcLR(   mc_or,  reslab, A)

  // RL
  mcLK(   mc_mv,   L1,  w1)

  mcRL(   mc_mvsxb, A, L1)        // mvsxb RL
  mcRK(   mc_sub,  A, sxb)
  mcLR(   mc_or,  reslab, A)
  mcRL(   mc_mvsxh, A, L1)        // mvsxh RL
  mcRK(   mc_sub,  A,  sxh)
  mcLR(   mc_or,  reslab, A)
  mcRL(   mc_mvzxb, A, L1)        // mvzxb RL
  mcRK(   mc_sub,  A,  zxb)
  mcLR(   mc_or,  reslab, A)
  mcRL(   mc_mvzxh, A, L1)        // mvzxh RL
  mcRK(   mc_sub,  A,  zxh)
  mcLR(   mc_or,  reslab, A)

  // RD
  mcDK(   mc_mv,   d0,  w1)

  mcRD(   mc_mvsxb, A, d0)        // mvsxb RD
  mcRK(   mc_sub,  A, sxb)
  mcLR(   mc_or,  reslab, A)
  mcRD(   mc_mvsxh, A, d0)        // mvsxh RD
  mcRK(   mc_sub,  A,  sxh)
  mcLR(   mc_or,  reslab, A)
  mcRD(   mc_mvzxb, A, d0)        // mvzxb RD
  mcRK(   mc_sub,  A,  zxb)
  mcLR(   mc_or,  reslab, A)
  mcRD(   mc_mvzxh, A, d0)        // mvzxh RD
  mcRK(   mc_sub,  A,  zxh)
  mcLR(   mc_or,  reslab, A)

  // RDX
  mcRK(   mc_mv, C, d0)
  mcDXK(  mc_mv, 0,   C,  w1)
  mcDXK(  mc_mv, 4,   C,  w1)
  mcDXK(  mc_mv, 400, C,  w1)

  mcRDX(  mc_mvsxb, A, 0, C)        // mvsxb RDX
  mcRK(   mc_sub,  A, sxb)
  mcLR(   mc_or,  reslab, A)
  mcRDX(  mc_mvsxh, A, 4, C)        // mvsxh RDX
  mcRK(   mc_sub,  A,  sxh)
  mcLR(   mc_or,  reslab, A)
  mcRDX(  mc_mvzxb, A, 400, C)      // mvzxb RDX
  mcRK(   mc_sub,  A,  zxb)
  mcLR(   mc_or,  reslab, A)
  mcRDX(  mc_mvzxh, A, 0, C)        // mvzxh RDX
  mcRK(   mc_sub,  A,  zxh)
  mcLR(   mc_or,  reslab, A)

  // RDXs
  mcRL(mc_lea, C, tablab); mcRK(  mc_rsh, C, 2) // C = tabaddr>>2
  mcDXsK(  mc_mv, 0,   C, 4, w1)
  mcDXsK(  mc_mv, 4,   C, 4, w1)
  mcDXsK(  mc_mv, 400, C, 4, w1)

  mcRDXs( mc_mvsxb, A, 0, C, 4)        // mvsxb RDXs
  mcRK(   mc_sub,  A, sxb)
  mcLR(   mc_or,  reslab, A)
  mcRDXs( mc_mvsxh, A, 4, C, 4)        // mvsxh RDXs
  mcRK(   mc_sub,  A,  sxh)
  mcLR(   mc_or,  reslab, A)
  mcRDXs( mc_mvzxb, A, 400, C, 4)      // mvzxb RDXs
  mcRK(   mc_sub,  A,  zxb)
  mcLR(   mc_or,  reslab, A)
  mcRDXs( mc_mvzxh, A, 0, C, 4)        // mvzxh RDXs
  mcRK(   mc_sub,  A,  zxh)
  mcLR(   mc_or,  reslab, A)

  // RDXsB
  mcRL(mc_lea, C, tablab); mcRK(  mc_rsh, C, 3) // C = tabaddr>>3
  mcRK(    mc_mv, E, 4)
  mcDXsBK(  mc_mv, 0,   C, 8, E, w1)
  mcDXsBK(  mc_mv, 4,   C, 8, E, w1)
  mcDXsBK(  mc_mv, 400, C, 8, E, w1)

  mcRDXsB( mc_mvsxb, A, 0, C, 8, E)        // mvsxb RDXsB
  mcRK(   mc_sub,  A, sxb)
  mcLR(   mc_or,  reslab, A)
  mcRDXsB( mc_mvsxh, A, 4, C, 8, E)        // mvsxh RDXsB
  mcRK(   mc_sub,  A,  sxh)
  mcLR(   mc_or,  reslab, A)
  mcRDXsB( mc_mvzxb, A, 400, C, 8, E)      // mvzxb RDXsB
  mcRK(   mc_sub,  A,  zxb)
  mcLR(   mc_or,  reslab, A)
  mcRDXsB( mc_mvzxh, A, 0, C, 8, E)        // mvzxh RDXsB
  mcRK(   mc_sub,  A,  zxh)
  mcLR(   mc_or,  reslab, A)

  mcRL( mc_mv, A, reslab)
  fnend()
}

LET testNEG_NOT_INC_DEC() BE
{ // Test NEG, NOT, INC and DEC
  //   R  A  V  G  M  L  D  DX  DXs  DXsB

  LET reslab = mcNextlab()
  LET lab = mcNextlab()
  LET d1 = tabaddr+4
  LET d2 = tabaddr+8
  LET val = 123

  mcK(mc_alignd, 4)
  mcL(mc_dlab, reslab)
  mcK(mc_datak, 0)
  mcL(mc_dlab, lab)
  mcK(mc_datak, 0)

  fnstart("Test for: NEG, NOT, INC and DEC*n")

  mcRK(   mc_mv,   A, 123)          // R
  mcR(    mc_dec,  A)
  mcR(    mc_not,  A)
  mcR(    mc_inc,  A)
  mcR(    mc_neg,  A)
  mcRK(   mc_sub,  A, 122)
  mcLR(   mc_or,  reslab, A)

  mcAK(   mc_mv,   a1, 123)         // A
  mcA(    mc_not,  a1)
  mcAK(   mc_add,  a1, 1)
  mcA(    mc_neg,  a1)
  mcRA(   mc_mv,   A, a1)
  mcRK(   mc_sub,  A, 123)
  mcLR(   mc_or,  reslab, A)

  mcVK(   mc_mv,   v1, 123)         // V
  mcV(    mc_not,  v1)
  mcVK(   mc_add,  v1, 1)
  mcV(    mc_neg,  v1)
  mcRV(   mc_mv,   A, v1)
  mcRK(   mc_sub,  A, 123)
  mcLR(   mc_or,  reslab, A)

  mcGK(   mc_mv,  G1, 123)         // G
  mcG(    mc_not, G1)
  mcGK(   mc_add, G1, 1)
  mcG(    mc_neg, G1)
  mcRG(   mc_mv,   A,G1)
  mcRK(   mc_sub,  A, 123)
  mcLR(   mc_or,  reslab, A)

  mcMK(   mc_mv,   99, 123)         // M
  mcM(    mc_not,  99)
  mcMK(   mc_add,  99, 1)
  mcM(    mc_neg,  99)
  mcRM(   mc_mv,   A, 99)
  mcRK(   mc_sub,  A, 123)
  mcLR(   mc_or,  reslab, A)

  mcLK(   mc_mv,   lab, 123)         // L
  mcL(    mc_not,  lab)
  mcLK(   mc_add,  lab, 1)
  mcL(    mc_neg,  lab)
  mcRL(   mc_mv,   A, lab)
  mcRK(   mc_sub,  A, 123)
  mcLR(   mc_or,  reslab, A)

  mcDK(   mc_mv,   d1, 123)   // D
  mcD(    mc_not,  d1)
  mcDK(   mc_add,  d1, 1)
  mcD(    mc_neg,  d1)
  mcRD(   mc_mv,   A, d1)
  mcRK(   mc_sub,  A, 123)
  mcLR(   mc_or,  reslab, A)

  mcRL(   mc_lea,  C, tablab)

  mcDK(   mc_mv,   d1, 123)   // DX
  mcDX(   mc_not,  4, C)
  mcDK(   mc_add,  d1, 1)
  mcDX(   mc_neg,  4, C)
  mcRD(   mc_mv,   A, d1)
  mcRK(   mc_sub,  A, 123)
  mcLR(   mc_or,  reslab, A)

  mcRL(mc_lea, C, tablab); mcRK(  mc_rsh, C, 2) // C = tabaddr>>2

  mcDK(   mc_mv,   d1, 123)   // DXs
  mcDXs(  mc_not,  4, C, 4)
  mcDK(   mc_add,  d1, 1)
  mcDXs(  mc_neg,  4, C, 4)
  mcRD(   mc_mv,   A, d1)
  mcRK(   mc_sub,  A, 123)
  mcLR(   mc_or,  reslab, A)

  mcRL(mc_lea, C, tablab); mcRK(  mc_rsh, C, 3) // C = tabaddr>>3

  mcRK(   mc_mv,   E, 4)
  mcDK(   mc_mv,   d2, 123)   // DXsB
  mcDXsB( mc_not,  4, C, 8, E)
  mcDK(   mc_add,  d2, 1)
  mcDXsB( mc_neg,  4, C, 8, E)
  mcRD(   mc_mv,   A, d2)
  mcRK(   mc_sub,  A, 123)
  mcLR(   mc_or,  reslab, A)

  mcRL( mc_mv, A, reslab)
  fnend()
}

LET testPOP_PUSH() BE
{ // Test POP and PUSH
  //   K  R  A  V  G  M  L  D  DX  DXs  DXsB

  LET reslab = mcNextlab()
  LET lab = mcNextlab()
  LET d0 = tabaddr
  LET d1 = tabaddr+4
  LET d2 = tabaddr+8
  LET val = 123

  mcK(mc_alignd, 4)
  mcL(mc_dlab, reslab)
  mcK(mc_datak, 0)
  mcL(mc_dlab, lab)
  mcK(mc_datak, 0)

  fnstart("Test for: PUSH and POP*n")

  mcK(   mc_push,   123)         // K
  mcK(   mc_push,   456)
  mcR(   mc_pop,    C)
  mcR(   mc_pop,    D)
  mcRK(   mc_sub,   C, 456)    
  mcLR(   mc_or,  reslab, C)
  mcRK(   mc_sub,   D, 123)    
  mcLR(   mc_or,  reslab, D)

  mcRK(  mc_mv,   A, 234)    
  mcRK(  mc_mv,   B, 567)    
  mcR(   mc_push,   A)         // R
  mcR(   mc_push,   B)
  mcR(   mc_pop,    C)
  mcR(   mc_pop,    D)
  mcRK(   mc_sub,   C, 567)    
  mcLR(   mc_or,  reslab, C)
  mcRK(   mc_sub,   D, 234)    
  mcLR(   mc_or,  reslab, D)

  mcAK(  mc_mv,   a1, 345)    
  mcA(   mc_push,   a1)         // A
  mcA(   mc_pop,    a2)
  mcRA(  mc_mv,    A, a2)
  mcRK(  mc_sub,   A, 345)    
  mcLR(  mc_or,  reslab, A)

  mcVK(  mc_mv,   v1, 345)    
  mcV(   mc_push,   v1)         // V
  mcV(   mc_pop,    v2)
  mcRV(  mc_mv,    A, v2)
  mcRK(  mc_sub,   A, 345)    
  mcLR(  mc_or,  reslab, A)

  mcGK(  mc_mv,  G1, 345)    
  mcG(   mc_push,  G1)         // G
  mcG(   mc_pop,   G2)
  mcRG(  mc_mv,    A, G2)
  mcRK(  mc_sub,   A, 345)    
  mcLR(  mc_or,  reslab, A)

  mcMK(  mc_mv,   99, 345)    
  mcM(   mc_push,   99)         // M
  mcM(   mc_pop,    98)
  mcRM(  mc_mv,    A, 98)
  mcRK(  mc_sub,   A, 345)    
  mcLR(  mc_or,  reslab, A)

  mcLK(  mc_mv,   lab, 345)    
  mcL(   mc_push,   lab)         // L
  mcL(   mc_pop,    tablab)
  mcRL(  mc_mv,    A, tablab)
  mcRK(  mc_sub,   A, 345)    
  mcLR(  mc_or,  reslab, A)

  mcDK(  mc_mv,   d1, 345)    
  mcD(   mc_push,   d1)         // D
  mcD(   mc_pop,    d2)
  mcRD(  mc_mv,    A, d2)
  mcRK(  mc_sub,   A, 345)    
  mcLR(  mc_or,  reslab, A)

  mcRL(  mc_lea,   C, tablab)
  mcDK(  mc_mv,   d1, 3456)    
  mcDX(  mc_push,   4, C)         // DX
  mcDX(  mc_pop,    8, C)
  mcRD(  mc_mv,    A, d2)
  mcRK(  mc_sub,   A, 3456)    
  mcLR(  mc_or,  reslab, A)

  mcRL(mc_lea, C, tablab); mcRK(  mc_rsh, C, 2) // C = tabaddr>>2

  mcDK(  mc_mv,   d1, 34567)    
  mcDXs( mc_push,   4, C, 4)         // DXs
  mcDXs( mc_pop,    8, C, 4)
  mcRD(  mc_mv,    A, d2)
  mcRK(  mc_sub,   A, 34567)    
  mcLR(  mc_or,  reslab, A)

  mcRL(mc_lea, C, tablab); mcRK(  mc_rsh, C, 3) // C = tabaddr>>3

  mcRK(   mc_mv,    E, 4)
  mcDK(  mc_mv,   d2, 345678)    
  mcDXsB(mc_push,   4, C, 8, E)         // DXsB
  mcDXsB(mc_pop,    8, C, 8, E)
  mcRD(  mc_mv,    A, d0+12)
  mcRK(  mc_sub,   A, 345678)    
  mcLR(  mc_or,  reslab, A)

  mcRL( mc_mv, A, reslab)
  fnend()
}

LET testLSH_RSH(mcop, w, n, r) BE
{ // Test LSH and RSH
  //   RR  RK

  LET reslab = mcNextlab()

  mcK(mc_alignd, 4)
  mcL(mc_dlab, reslab)
  mcK(mc_datak, 0)

  fnstart("Test for: LSH and RSH  %x8 op %n => %x8*n", w, n, r)

  mcRK(   mc_mv,    A, w)
  mcRK(   mc_mv,    C, n)
  mcRR(   mcop,     A, C)         // RR
  mcRK(   mc_sub,   A, r)
  mcLR(   mc_or,  reslab, A)

  mcRK(   mc_mv,    A, w)
  mcRK(   mcop,     A, n)         // RK
  mcRK(   mc_sub,   A, r)
  mcLR(   mc_or,  reslab, A)

  mcRL( mc_mv, A, reslab)
  fnend()
}

LET testXCHG() BE
{ // Test XCHG
  //   RR RA RV RG RM RL RD RDX RDXs RDXsB

  LET reslab = mcNextlab()
  LET lab = mcNextlab()
  LET d1 = tabaddr+4
  LET d2 = tabaddr+8
  LET val = 123

  mcK(mc_alignd, 4)
  mcL(mc_dlab, reslab)
  mcK(mc_datak, 0)
  mcL(mc_dlab, lab)
  mcK(mc_datak, 0)

  fnstart("Test for: XCHG*n")

  mcRK(   mc_mv,    A, 123)         // RR
  mcRK(   mc_mv,    B, 456)
  mcRK(   mc_mv,    C, 789)
  mcRR(   mc_xchg,  A, B)
  mcRR(   mc_xchg,  B, C)
  mcRR(   mc_xchg,  C, A)
  mcRK(   mc_sub,   A, 123)
  mcLR(   mc_or,  reslab, A)
  mcRK(   mc_sub,   B, 789)
  mcLR(   mc_or,  reslab, B)
  mcRK(   mc_sub,   C, 456)
  mcLR(   mc_or,  reslab, C)

  mcRK(   mc_mv,    A, 123)         // RA
  mcAK(   mc_mv,    a1,456)
  mcRA(   mc_xchg,  A, a1)
  mcRK(   mc_sub,   A, 456)
  mcLR(   mc_or,  reslab, A)
  mcRA(   mc_mv,    A, a1)
  mcRK(   mc_sub,   A, 123)
  mcLR(   mc_or,  reslab, A)

  mcRK(   mc_mv,    A, 123)         // RV
  mcVK(   mc_mv,    v1,456)
  mcRV(   mc_xchg,  A, v1)
  mcRK(   mc_sub,   A, 456)
  mcLR(   mc_or,  reslab, A)
  mcRV(   mc_mv,    A, v1)
  mcRK(   mc_sub,   A, 123)
  mcLR(   mc_or,  reslab, A)

  mcRK(   mc_mv,    A, 123)         // RG
  mcGK(   mc_mv,   G1,456)
  mcRG(   mc_xchg,  A, G1)
  mcRK(   mc_sub,   A, 456)
  mcLR(   mc_or,  reslab, A)
  mcRG(   mc_mv,    A, G1)
  mcRK(   mc_sub,   A, 123)
  mcLR(   mc_or,  reslab, A)

  mcRK(   mc_mv,    A, 123)         // RM
  mcMK(   mc_mv,    99,456)
  mcRM(   mc_xchg,  A, 99)
  mcRK(   mc_sub,   A, 456)
  mcLR(   mc_or,  reslab, A)
  mcRM(   mc_mv,    A, 99)
  mcRK(   mc_sub,   A, 123)
  mcLR(   mc_or,  reslab, A)

  mcRK(   mc_mv,    A, 123)         // RL
  mcLK(   mc_mv,    lab, 456)
  mcRL(   mc_xchg,  A, lab)
  mcRK(   mc_sub,   A, 456)
  mcLR(   mc_or,  reslab, A)
  mcRL(   mc_mv,    A, lab)
  mcRK(   mc_sub,   A, 123)
  mcLR(   mc_or,  reslab, A)

  mcRK(   mc_mv,    A, 123)         // RD
  mcDK(   mc_mv,    d1, 456)
  mcRD(   mc_xchg,  A, d1)
  mcRK(   mc_sub,   A, 456)
  mcLR(   mc_or,  reslab, A)
  mcRD(   mc_mv,    A, d1)
  mcRK(   mc_sub,   A, 123)
  mcLR(   mc_or,  reslab, A)

  mcRL(   mc_lea,   C, tablab)
  mcRK(   mc_mv,    A, 123)         // RDX
  mcDK(   mc_mv,    d1, 456)
  mcRDX(  mc_xchg,  A, 4, C)
  mcRK(   mc_sub,   A, 456)
  mcLR(   mc_or,  reslab, A)
  mcRD(   mc_mv,    A, d1)
  mcRK(   mc_sub,   A, 123)
  mcLR(   mc_or,  reslab, A)

  mcRL(mc_lea, C, tablab); mcRK(  mc_rsh, C, 2) // C = tabaddr>>2

  mcRK(   mc_mv,    A, 123)         // RDXs
  mcDK(   mc_mv,    d1, 456)
  mcRDXs(  mc_xchg,  A, 4, C, 4)
  mcRK(   mc_sub,   A, 456)
  mcLR(   mc_or,  reslab, A)
  mcRD(   mc_mv,    A, d1)
  mcRK(   mc_sub,   A, 123)
  mcLR(   mc_or,  reslab, A)

  mcRL(mc_lea, C, tablab); mcRK(  mc_rsh, C, 3) // C = tabaddr>>3

  mcRK(   mc_mv,    E, 4)
  mcRK(   mc_mv,    A, 123)         // RDXsB
  mcDK(   mc_mv,    d2, 456)
  mcRDXsB(mc_xchg,  A, 4, C, 8, E)
  mcRK(   mc_sub,   A, 456)
  mcLR(   mc_or,  reslab, A)
  mcRD(   mc_mv,    A, d2)
  mcRK(   mc_sub,   A, 123)
  mcLR(   mc_or,  reslab, A)

  mcRL( mc_mv, A, reslab)
  fnend()
}


