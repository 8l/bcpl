/*
############### UNDER DEVELOPMENT #########################

This is a systematic test for the MC Package

Implemented by Martin Richards (c) January 2008
*/

GET "libhdr"
GET "mc.h"

MANIFEST {
// Register mnemonics
a = mc_a
b = mc_b
c = mc_c
d = mc_d
e = mc_e
f = mc_f
}

GLOBAL {
  testno: ug
}

LET start() = VALOF
{ // Load the dynamic code generation package
  LET argv = VEC 50
  LET mcseg = 0
  LET mcb = 0
  LET tests, errors = 0, 0

  UNLESS rdargs("TEST/n", argv, 50) DO
  { writef("Bad arguments for mccheck*n")
    RESULTIS 0
  }

  testno := 0
  IF argv!0 DO testno := !(argv!0)

  mcseg := globin(loadseg("mci386"))
  UNLESS mcseg DO
  { writef("Trouble with MC package: mci386*n")
    GOTO fin
  }

  // Create an MC instance for 20 functions with a data space
  // of 20 words and code space of 40000
  mcb := mcInit(20, 30, 40000)

  UNLESS mcb DO
  { writef("Unable to create an mci386 instance*n")
    GOTO fin
  } 

  mc := 0          // Currently no selected MC instance
  mcSelect(mcb)


  IF testno=0 DO mcK(mc_debug, 3)  

  mcKKK(mc_entry, 1, 3, 0);

  gentests()

  mcF(mc_rtn);
  mcF(mc_endfn);

  newline()

  FOR i = 1 TO 10 DO
  { LET code = 0
    tests := tests+1
    writef("Test %i3: ", i)
    deplete(cos)
    code := mcCall(1, i, 222, 333)
    TEST code=0
    THEN writef(" OK*n")
    ELSE { writef(" Failed, code=%n*n", code)
           errors := errors+1
         }
  }

  writef("*n%n test%-%ps completed, there %p\was\were\ were %-%n error%-%ps*n",
          tests, errors)

fin:
  IF mcseg DO unloadseg(mcseg)  
  RESULTIS 0
}

AND gentests() BE
{ LET retlab = mcNextlab()
  LET lab = 0
  LET tno = 0

  tno := tno+1
  lab := mcNextlab()
  //mcRA(mc_ld,  a, 100)
  mcRA(mc_cmp, a, 1)
  //mcKA(mc_cmp, tno, 1)
  mcJS(mc_jne, lab)

  IF tno=testno DO mcK(mc_debug, 3)
  mcComment("*nTest %n: ADD*n", tno)
  mcRK(mc_ld,  f, 0)            // To hold OR of any errors
  tstadd(3,     7)
  tstadd(30000, 70000)
  IF tno=testno DO mcK(mc_debug, 0)
  mcJL(mc_jmp, retlab)

  mcL(mc_lab, lab)
  tno := tno+1
  lab := mcNextlab()
  mcRA(mc_ld,  a, 1)
  mcRK(mc_cmp, a, tno)
  mcJS(mc_jne, lab)
  mcComment("*nTest %n*n", tno)
  mcRK(mc_ld,  a, #b0011)
  mcRK(mc_ld,  b, #b1010)
  mcRR(mc_and, a, b)        // and RR
  mcRK(mc_sub, a, #b0010)
  mcJL(mc_jmp, retlab)
  mcL(mc_lab, lab)

  tno := tno+1
  lab := mcNextlab()
  mcRA(mc_ld,  a, 1)
  mcRK(mc_cmp, a, tno)
  mcJS(mc_jne, lab)
  mcComment("*nTest %n*n", tno)
  mcRK(mc_ld,  a, #b0011)
  mcRK(mc_ld,  b, #b1010)
  mcRR(mc_and, a, b)              // cmp RR
  mcRK(mc_sub, a, #b0011)
  mcJL(mc_jmp, retlab)
  mcL(mc_lab, lab)

  tno := tno+1
  lab := mcNextlab()
  mcRA(mc_ld,  a, 1)
  mcRK(mc_cmp, a, tno)
  mcJS(mc_jne, lab)
  mcComment("*nTest %n*n", tno)
  mcRK(mc_ld,  a, 2)
  mcRK(mc_ld,  b, 5)
  mcRR(mc_ld, a, b)       // ld RR
  mcRK(mc_sub, a, 2)
  mcJL(mc_jmp, retlab)
  mcL(mc_lab, lab)

  tno := tno+1
  lab := mcNextlab()
  mcRA(mc_ld,  a, 1)
  mcRK(mc_cmp, a, tno)
  mcJS(mc_jne, lab)
  mcComment("*nTest %n*n", tno)
  mcRK(mc_ld,  a, 5)
  mcRK(mc_ld,  b, 2)
  mcRR(mc_lsh, a, b)       // lsh RR
  mcRK(mc_sub, a, 20)
  mcJL(mc_jmp, retlab)
  mcL(mc_lab, lab)

  tno := tno+1
  lab := mcNextlab()
  mcRA(mc_ld,  a, 1)
  mcRK(mc_cmp, a, tno)
  mcJS(mc_jne, lab)
  mcComment("*nTest %n*n", tno)
  mcRK(mc_ld,  a, #b0011)
  mcRK(mc_ld,  b, #b1010)
  mcRR(mc_or,  a, b)       // or RR
  mcRK(mc_sub, a, #b1011)
  mcJL(mc_jmp, retlab)
  mcL(mc_lab, lab)

  tno := tno+1
  lab := mcNextlab()
  mcRA(mc_ld,  a, 1)
  mcRK(mc_cmp, a, tno)
  mcJS(mc_jne, lab)
  mcComment("*nTest %n*n", tno)
  mcRK(mc_ld,  a, #b101000)
  mcRK(mc_ld,  b, 2)
  mcRR(mc_sub, a, #b001010)       // rsh RR
  mcRK(mc_sub, a, -3)
  mcJL(mc_jmp, retlab)
  mcL(mc_lab, lab)

  tno := tno+1
  lab := mcNextlab()
  mcRA(mc_ld,  a, 1)
  mcRK(mc_cmp, a, tno)
  mcJS(mc_jne, lab)
  mcComment("*nTest %n*n", tno)
  mcRK(mc_ld,  a, 2)
  mcRK(mc_ld,  b, 5)
  mcRR(mc_sub, a, b)       // sub RR
  mcRK(mc_sub, a, -3)
  mcJL(mc_jmp, retlab)
  mcL(mc_lab, lab)

  tno := tno+1
  lab := mcNextlab()
  mcRA(mc_ld,  a, 1)
  mcRK(mc_cmp, a, tno)
  mcJS(mc_jne, lab)
  mcComment("*nTest %n*n", tno)
  mcRK(mc_ld,  a, #x0011)
  mcRK(mc_ld,  b, #x1010)
  mcRR(mc_xor, a, b)       // xor RR
  mcRK(mc_sub, a, #x1001)
  mcJL(mc_jmp, retlab)
  mcL(mc_lab, lab)


  mcRK(mc_ld, f, 1111)
 

  mcL(mc_lab, retlab)
  mcRR(mc_ld, a, f)

}

AND tstadd(x, y) BE
{ mcRK(mc_ld,  a, x)
  mcRK(mc_add, a, y)            // ADD A,y
  mcRK(mc_sub, a, x+y)
  mcRR(mc_or,  f, a)

  mcRK(mc_ld,  b, x)
  mcRK(mc_add, b, y)            // ADD B,y
  mcRK(mc_sub, b, x+y)
  mcRR(mc_or,  f, b)

  mcRK(mc_ld,  a, x)
  mcRK(mc_ld,  b, y)
  mcRR(mc_add, a, b)            // ADD A,B
  mcRK(mc_sub, a, x+y)
  mcRR(mc_or,  f, a)
}    
