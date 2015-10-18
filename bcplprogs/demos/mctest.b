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

  mcK(mc_debug, #b1011)  

  mcK(mc_alignd, 4)
  mcL(mc_dlab, M)
  mcK(mc_datak, 1234)
  mcL(mc_datal, N)
  mcL(mc_datal, M)
  mcL(mc_dlab,  N)

  mcK(mc_debug, #b0011)  

  mcKKK(mc_entry, 1, 3, 5);

  mcRK(mc_mv, A, 11)
  mcRK(mc_mv, B, 22)
  mcRK(mc_mv, C, 33)
  mcRK(mc_mv, D, 44)
  mcRK(mc_mv, E, 55)
  mcRK(mc_mv, F, 66)

  mcK(mc_debug, #b1111)  

  //mcDXsBK(mc_cmp, 80, B, 4, A, 10)
  //mcGK(mc_mv, 0, 999)

   
//  mcRG(mc_mvzxh, A, 0)

  mcK(mc_debug, #b1111)


  mcStrR(mc_prf, "arg=%d*n", A)
  mcK(mc_debug, #b0011)

  mcRK(mc_cmp, A, 12)
  mcStrR(mc_prf, "A=%d*n", A)
  mcStrR(mc_prf, "B=%d*n", B)
  mcStrR(mc_prf, "C=%d*n", C)
  mcStrR(mc_prf, "D=%d*n", D)
  mcStrR(mc_prf, "E=%d*n", E)
  mcStrR(mc_prf, "F=%d*n", F)

  L := mcNextlab()
  mcJL(mc_jeq, L)
  mcR(mc_push, A)
  mcStr(mc_prf, "A~=11*n")
  mcL(mc_lab, L)
  
  mcF(mc_rtn);
  mcF(mc_endfn);
  mcF(mc_end);

  newline()
  //writef("*n*nCalling function F%n*n", 1)
  writef("*n*nF1(10, 20, 30)=> %n*n", mcCall(1, 10, 20, 30))
//  writef("*n*nCalling function 2 => %n*n", mcCall(2, 40, 50, 60))

fin:
  //writef("fin: reached*n")
  IF mcseg DO unloadseg(mcseg)  
  writef("*nReturning from mctest*n")
  RESULTIS 0
}

    
