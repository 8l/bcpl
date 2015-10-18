GET "libhdr"
GET "mc.h"

MANIFEST {
  A=mc_a; B=mc_b; C=mc_c; D=mc_d; E=mc_e; F=mc_f
  a1=1; a2; a3
}

LET start() = VALOF
{ // Load the dynamic code generation package
  LET mcseg = globin(loadseg("mci386"))
  LET mcb = 0
  LET n = 0

  UNLESS mcseg DO
  { writef("Trouble with MC package: mci386*n")
    GOTO fin
  }

  // Create an MC instance for 10 functions with a data space
  // of 100 words and code space of 4000 words.
  mcb := mcInit(10, 100, 4000)

  UNLESS mcb DO
  { writef("Unable to create an mci386 instance*n")
    GOTO fin
  } 

  mc := 0                  // Currently no selected MC instance
  mcSelect(mcb)            // Select the new MC instance

  mcK(mc_debug, #b0011)    // Trace comments and MC instructions

  mcKKK(mc_entry, 1, 3, 5) // Entry point for function 1
                           // having 3 arguments and 5 local variables

  mcK(mc_debug, #b1111)    // Trace comments, MC instructions,
                           // target instructions and compiled binary.


{ LET x, y = 17, 5
  mcRK( mc_mv,  A, x)
mcRK( mc_mv,  B, y)
mcPRF("signed   %8x ** ", A)
mcPRF("%8x => ", B)
  mcK(  mc_mul, y)           // MUL K
mcPRF("D=%8x ",  D)
mcPRF("A=%8x*n", A)

    mcRK(mc_add, A, 1)     // Add one to product to give remainder
mcPRF("signed   <%8x ", D)
mcPRF("%8x> / ", A)
mcRK( mc_mv,  B, y)
mcPRF("%8x => ", B)
      mcK(  mc_div, y)      // DIV  K
mcPRF("remainder:%8x ", D)
mcPRF("quotient:%8x*n", A)
}

{ LET x, y = -17, 5
  mcRK( mc_mv,  A, x)
mcRK( mc_mv,  B, y)
mcPRF("signed   %8x ** ", A)
mcPRF("%8x => ", B)
  mcK(  mc_mul, y)           // MUL K
mcPRF("D=%8x ",  D)
mcPRF("A=%8x*n", A)

    mcRK(mc_add, A, -1)     // Add one to product to give remainder
mcPRF("signed   <%8x ", D)
mcPRF("%8x> / ", A)
mcRK( mc_mv,  B, y)
mcPRF("%8x => ", B)
      mcK(  mc_div, y)      // DIV  K
mcPRF("remainder:%8x ", D)
mcPRF("quotient:%8x*n", A)
}

{ LET x, y = 17, -5
  mcRK( mc_mv,  A, x)
mcRK( mc_mv,  B, y)
mcPRF("signed   %8x ** ", A)
mcPRF("%8x => ", B)
  mcK(  mc_mul, y)           // MUL K
mcPRF("D=%8x ",  D)
mcPRF("A=%8x*n", A)

    mcRK(mc_add, A, -1)     // Add one to product to give remainder
mcPRF("signed   <%8x ", D)
mcPRF("%8x> / ", A)
mcRK( mc_mv,  B, y)
mcPRF("%8x => ", B)
      mcK(  mc_div, y)      // DIV  K
mcPRF("remainder:%8x ", D)
mcPRF("quotient:%8x*n", A)
}

{ LET x, y = -17, -5
  mcRK( mc_mv,  A, x)
mcRK( mc_mv,  B, y)
mcPRF("signed   %8x ** ", A)
mcPRF("%8x => ", B)
  mcK(  mc_mul, y)           // MUL K
mcPRF("D=%8x ",  D)
mcPRF("A=%8x*n", A)

    mcRK(mc_add, A, 1)     // Add one to product to give remainder
mcPRF("signed   <%8x ", D)
mcPRF("%8x> / ", A)
mcRK( mc_mv,  B, y)
mcPRF("%8x => ", B)
      mcK(  mc_div, y)      // DIV  K
mcPRF("remainder:%8x ", D)
mcPRF("quotient:%8x*n", A)
}



  mcK(mc_debug, #b0011)    // Trace only comments and MC instructions
  mcF(mc_rtn)              // Return from function 1
  mcF(mc_endfn)            // End of function 1 code
  mcF(mc_end)              // End of dynamic code generation

  writef("*nF1(10, 20, 30) => %n*n", mcCall(1, 10, 20, 30))

fin:
  IF mcseg DO unloadseg(mcseg)  
  RESULTIS 0
}

