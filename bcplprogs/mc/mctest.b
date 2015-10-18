GET "libhdr"
GET "mc.h"

MANIFEST {
 A=mc_a; B=mc_b; C=mc_c; D=mc_d; E=mc_e; F=mc_f
 a1=1; a2; a3
 v1=1; v2; v3
}

LET start() = VALOF
{ // Load the dynamic code generation package
  LET mcseg = globin(loadseg("mci386"))
  LET mcb = 0
  LET L, M, N = 0, 0, 0 // For local labels
  LET v = VEC 1000
  FOR i = 0 TO 1000 DO v!i := 1000+i

  UNLESS mcseg DO
  { writef("Trouble with MC package: mci386*n")
    GOTO fin
  }

  // Create an MC instance for 10 functions with a data space
  // of 100 words and code space of 4000
  mcb := mcInit(10, 100, 4000)

  UNLESS mcb DO
  { writef("Unable to create an mci386 instance*n")
    GOTO fin
  } 

  mc := 0          // Currently no selected MC instance
  mcSelect(mcb)

  L, M, N := mcNextlab(), mcNextlab(), mcNextlab()

  mcK(mc_debug, #b0011)  

  mcK(mc_debug, #b1111)  
  mcKKK(mc_entry, 1, 3, 5);
//  writef("F1 body %n  m/c address %x8*n",
//          mcCodep()+mc*4, mcCodep()+rootnode!rtn_mc0+mc*4)

        mcRK(mc_mv, D, #xFFFF4567)
        mcRK(mc_mv, A, #x89ABCDEF)
        mcRK(mc_mv, B, #x10000000)
        mcPRF("With  D=%8x  ",  D)
        mcPRF("A=%8x  ", A)
        mcPRF("B=%8x*n", B)
        mcR(mc_div, B)
        mcPRF("the instruction:  DIV B*n")
        mcPRF("gives D=%8x  ", D)
        mcPRF("A=%8x  ", A)
        mcPRF("B=%8x*n", B)
/*
  mcRA(mc_mv,  A, a1)
  mcRA(mc_mv,  B, a2)
  mcRA(mc_mv,  C, a3)
  mcPRF("F1(%d, ", A)
  mcPRF("%d, ", B)
  mcPRF("%d) entered*n", C)
  mcRA(mc_add, A, a2)
  mcRA(mc_sub, A, a3)
  mcPRF("F1 returning A=%d*n", A)
  mcF(mc_rtn)

  mcKKK(mc_entry, 2, 3, 5);
//  writef("F2 body %n  m/c address %x8*n",
//          mcCodep()+mc*4, mcCodep()+rootnode!rtn_mc0+mc*4)
  mcRA(mc_mv,  A, a1)
  //mcPRF("Function 2 entered, a1=%d*n", A)
  mcK(mc_push, 666)
  mcK(mc_push, 555)

  mcK(mc_push, 444)
  mcK(mc_push, 333)
  mcK(mc_push, 123)
  mcK(mc_push, 111)
  mcPRF("Calling F1(123,333,444)*n", A)
  mcKK(mc_call, 1, 3)
  //mcPRF("F1(123,333,444) returned A=%d*n", A)
*/
  //mcR(mc_push, A)
  //mcKK(mc_call, 1, 3)
  //mcPRF("F1(A,555,666) returned A=%d*n", A)
  mcF(mc_rtn)

  mcK(mc_debug, #b0011)  

  mcF(mc_endfn);
  mcF(mc_end);

  //writef("*nmc0=%x8 mc2=%x8*n", rootnode!rtn_mc0, rootnode!rtn_mc2)

  newline()
  //writef("*n*nCalling function F%n*n", 1)
  writef("*n*nF1(10, 20, 30)=> %n*n", mcCall(1, 10, 20, 30))
  writef("*n*nF2(10, 20, 30)=> %n*n", mcCall(2, 10, 20, 30))
//  writef("*n*nCalling function 2 => %n*n", mcCall(2, 40, 50, 60))

fin:
  //writef("fin: reached*n")
  IF mc DO mcClose()
  IF mcseg DO unloadseg(mcseg)  
  writef("*nReturning from mctest*n")
  RESULTIS 0
}

    
