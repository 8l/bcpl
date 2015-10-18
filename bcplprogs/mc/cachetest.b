GET "libhdr"
GET "mc.h"

MANIFEST {
 A=mc_a; B=mc_b; C=mc_c; D=mc_d; E=mc_e; F=mc_f
}

GLOBAL {
  lo:ug; hi; step; repcount
  time0
}

LET start() = VALOF
{ // Load the dynamic code generation package
  LET argv = VEC 50
  LET mcseg = globin(loadseg("mci386"))
  LET mcb = 0
  LET L = 0 // For the loop label

  UNLESS mcseg DO
  { writef("Trouble with MC package: mci386*n")
    GOTO fin
  }

  UNLESS rdargs("lo/n,hi/n", argv, 50) DO
  { writef("Bad arguments for cachetest*n")
    GOTO fin
  }

  lo, hi := 1_000, 8_000_000

  IF argv!0 DO lo       := !(argv!0)
  IF argv!1 DO hi       := !(argv!1)

  writef("*nRunning CACHETEST with lo=%n, hi=%n*n*n", lo, hi)

  repcount := 1000

  WHILE lo<=hi DO
  { // Create an MC instance for 10 functions with a data space
    // of 100 words and code space of 500_000
    mcb := mcInit(10, 10, 3_000_000)

    UNLESS mcb DO
    { writef("Unable to create an mci386 instance*n")
      GOTO fin
    } 

    mc := 0          // Currently no selected MC instance
    mcSelect(mcb)


    //mcK(mc_debug, #b0000)  

    mcKKK(mc_entry, 1, 3, 5);
    mcRA(mc_mv, A, 1)           // Get the repetition count
    L := mcNextlab()

    mcL(mc_lab, L)

    FOR i = 1 TO lo DO mcF(mc_nop)

    mcRK(mc_sub, A, 1)
    mcRK(mc_cmp, A, 0)
    mcJL(mc_jgt, L)
  
    mcF(mc_rtn);
    mcF(mc_endfn);
    mcF(mc_end);

    //newline()

//IF FALSE DO
    { LET t, avg = 0, 0

      { LET t0 = sys(Sys_cputime)
        mcCall(1, repcount, 20, 30)
        t := sys(Sys_cputime) - t0 // CPU time in msecs
        //writef("%n x %i7 NOPs: CPU time is %6.3d secs*n",
        //        repcount, lo, t)
        IF 400<=t<=600 BREAK
        IF t<450 DO repcount := repcount*11/10
        IF t>550 DO repcount := repcount*9/10
      } REPEAT

      avg := muldiv(t, 1_000_000, muldiv(repcount, lo, 1000)+1)   
      writef("%i7 x %i7 NOPs: Average per million NOPs is %i5 usecs*n",
              repcount, lo, avg)
//abort(1000)
    }

    IF lo < 100_000_000 DO step := 10_000_000
    IF lo <  10_000_000 DO step :=  1_000_000
    IF lo <   1_000_000 DO step :=    100_000
    IF lo <     100_000 DO step :=     10_000
    IF lo <      10_000 DO step :=      1_000

    lo := lo + step
//abort(1000)
    mcClose()
  }

fin:
  IF mcseg DO unloadseg(mcseg)  
  //writef("returning from cachetest*n")
  RESULTIS 0
}

/*
Typical result:
    
Running CACHETEST with lo=1000, hi=8000000

1395411 x    1000 NOPs: Average per million NOPs is   308 usecs
 915527 x    2000 NOPs: Average per million NOPs is   300 usecs
 600676 x    3000 NOPs: Average per million NOPs is   305 usecs
 486547 x    4000 NOPs: Average per million NOPs is   303 usecs
 394102 x    5000 NOPs: Average per million NOPs is   304 usecs
 319221 x    6000 NOPs: Average per million NOPs is   302 usecs
 258568 x    7000 NOPs: Average per million NOPs is   303 usecs
 232711 x    8000 NOPs: Average per million NOPs is   300 usecs
 209439 x    9000 NOPs: Average per million NOPs is   302 usecs
 188495 x   10000 NOPs: Average per million NOPs is   302 usecs
  90154 x   20000 NOPs: Average per million NOPs is   299 usecs
  65721 x   30000 NOPs: Average per million NOPs is   299 usecs
  47909 x   40000 NOPs: Average per million NOPs is   313 usecs
  38806 x   50000 NOPs: Average per million NOPs is   309 usecs
  31432 x   60000 NOPs: Average per million NOPs is   312 usecs
  25459 x   70000 NOPs: Average per million NOPs is   314 usecs
  22913 x   80000 NOPs: Average per million NOPs is   310 usecs
  20621 x   90000 NOPs: Average per million NOPs is   312 usecs
  18558 x  100000 NOPs: Average per million NOPs is   312 usecs
   8874 x  200000 NOPs: Average per million NOPs is   309 usecs
   5821 x  300000 NOPs: Average per million NOPs is   314 usecs
   4714 x  400000 NOPs: Average per million NOPs is   312 usecs
   3817 x  500000 NOPs: Average per million NOPs is   309 usecs
   3091 x  600000 NOPs: Average per million NOPs is   318 usecs
   2502 x  700000 NOPs: Average per million NOPs is   325 usecs
   2251 x  800000 NOPs: Average per million NOPs is   327 usecs
   2025 x  900000 NOPs: Average per million NOPs is   323 usecs
   1639 x 1000000 NOPs: Average per million NOPs is   347 usecs
    459 x 2000000 NOPs: Average per million NOPs is   620 usecs
    217 x 3000000 NOPs: Average per million NOPs is   844 usecs
    157 x 4000000 NOPs: Average per million NOPs is   875 usecs
    126 x 5000000 NOPs: Average per million NOPs is   888 usecs
    113 x 6000000 NOPs: Average per million NOPs is   884 usecs
     90 x 7000000 NOPs: Average per million NOPs is   888 usecs
     81 x 8000000 NOPs: Average per million NOPs is   895 usecs
*/
