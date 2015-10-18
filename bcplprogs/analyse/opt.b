/*
This is a first attempt to analyse complete Cintcode programs.
It take a list of cintcode object modules that constitutes
a complete program including all library files and analyses the
flowgraph of the resulting code.

It is intended to perform dead code elimination, variable range
analysis, analysis of the use of pointers and indirection, etc.

Written in BCPL by Martin Richards (c) May 2001

Development log

22/5/2001
Runs cmpltest and the BCPL self compilation test.

22/11/2000
Implementation started 
*/

GET "libhdr"

GLOBAL {
  segv:ug     // Vector of program segments
  segp        // Next position in segv
  gvec        // The program's global vector
  stackv      // The program's stack
  spacev      // Base of free space vector
  spacep      // Pointer to next word of free space
  spacet      // Pointer to last word of free space
  globiv       // Global vector info
  progv       // Vector holding the program modules
  progiv      // Program info vector (one element in progiv per byte in progv)
  progivt     // Top of program info vector
  progp       // Next word in progv
  progupb     // Upb of progv
  proglink    // Pointer to code for each cintcode instruction
  codev       // Vector for the simple translated code
  codep       // Pointer to next word of codev
  codet       // Pointer to last word of codev
  stdout
  tofile
  tracing

  r_a; r_b; r_c; r_p; r_g; r_pc  // Interpreter registers
}

MANIFEST {
/* relocatable object blocks  */
  T_hunk  = 1000
  T_bhunk = 3000
  T_end   = 1002

  Entryword = #x0000DFDF  // Funtion entrypoint marker

  SpaceUpb =  1500000
  GvecUpb  =     1000
  StackUpb =    50000
  CodevUpb =   800000

// Marks for 
  M_null   = #x00000000  // No information
  M_nyet   = #x00000001  // Not yet implemented
  M_f      = #x00000002  // Cintcode function byte
  M_i      = #x00000004  // Cintcode immediate data incl switch data
                         // resolving words and global initialisation data 
  M_d      = #x00000008  // Static data
  M_rd     = #x00000010  // Data read
  M_wr     = #x00000020  // Data written
  M_lab    = #x00000040  // Destination of a jump
  M_flab   = #x00000080  // Function entry point
  M_pto    = #x00000100  // Address taken
  M_rf     = #x00000200  // Reachable function byte
  M_ginit  = #x00000400  // Initialised global function
  M_lf     = #x00000800  // Non global function
  M_ln     = #x00001000  // Loaded as a constant
  M_lp     = #x00002000  // Loaded from a local
  M_llp    = #x00004000  // Loaded as the address of a local
  M_sp     = #x00008000  // Stored in a local
  M_lg     = #x00010000  // Loaded from a global
  M_llg    = #x00020000  // Loaded as the address of a global
  M_sg     = #x00040000  // Stored in a global
  M_ll     = #x00080000  // Loaded from a static variable
  M_lll    = #x00100000  // Loaded as the address of a static
  M_sl     = #x00200000  // Stored in a static
  M_k      = #x00400000  // Used in a function call
  M_lb     = #x00800000  // Loaded by gbyt
  M_sb     = #x01000000  // Stored by pbyt
  M_ldind  = #x02000000  // Loaded by an indirect load
  M_stind  = #x04000000  // Stored indirectly
  M_spare  = #x08000000  // Spare
  M_spare  = #x10000000  // 
  M_spare  = #x20000000  // 
  M_spare  = #x40000000  // 
  M_spare  = #x80000000  // 


}

// CINTCODE function codes.
MANIFEST {
F_k0   =   0
F_brk  =   2
F_lf   =  12
F_lm   =  14
F_lm1  =  15
F_l0   =  16
F_fhop =  27
F_jeq  =  28
F_jeq0 =  30

F_k    =  32
F_kh   =  33
F_kw   =  34
F_k0g  =  32
F_s0g  =  44
F_l0g  =  45
F_l1g  =  46
F_l2g  =  47
F_lg   =  48
F_sg   =  49
F_llg  =  50
F_ag   =  51
F_mul  =  52
F_div  =  53
F_rem  =  54
F_xor  =  55
F_sl   =  56
F_ll   =  58
F_jne  =  60
F_jne0 =  62

F_llp  =  64
F_llph =  65
F_llpw =  66

F_k0g1  =  32+32
F_s0g1  =  44+32
F_l0g1  =  45+32
F_l1g1  =  46+32
F_l2g1  =  47+32
F_lg1   =  48+32
F_sg1   =  49+32
F_llg1  =  50+32
F_ag1   =  51+32

F_add  =  84
F_sub  =  85
F_lsh  =  86
F_rsh  =  87
F_and  =  88
F_or   =  89
F_lll  =  90
F_jls  =  92
F_jls0 =  94

F_l    =  96
F_lh   =  97
F_lw   =  98

F_k0gh  =  32+64
F_s0gh  =  44+64
F_l0gh  =  45+64
F_l1gh  =  46+64
F_l2gh  =  47+64
F_lgh   =  48+64
F_sgh   =  49+64
F_llgh  =  50+64
F_agh   =  51+64

F_rv   = 116
F_rtn  = 123
F_jgr  = 124
F_jgr0 = 126

F_lp   = 128
F_lph  = 129
F_lpw  = 130
F_lp0  = 128
F_sys  = 145
F_swb  = 146
F_swl  = 147
F_st   = 148
F_st0  = 148
F_stp0 = 149
F_goto = 155
F_jle  = 156
F_jle0 = 158

F_sp   = 160
F_sph  = 161
F_spw  = 162
F_sp0  = 160
F_s0   = 176
F_xch  = 181
F_gbyt = 182
F_pbyt = 183
F_atc  = 184
F_atb  = 185
F_j    = 186
F_jge  = 188
F_jge0 = 190

F_ap   = 192
F_aph  = 193
F_apw  = 194
F_ap0  = 192
F_xpbyt= 205
F_lmh  = 206
F_btc  = 207
F_nop  = 208
F_a0   = 208
F_rvp0 = 211
F_st0p0= 216
F_st1p0= 218

F_a    = 224
F_ah   = 225
F_aw   = 226
F_l0p0 = 224
F_s    = 237
F_sh   = 238
F_mdiv = 239
F_chgco= 240
F_neg  = 241
F_not  = 242
F_l1p0 = 240
F_l2p0 = 244
F_l3p0 = 247
F_l4p0 = 249

// Simple target code for analysis and interpretation

I_end  = 0  // Marks the end of a fragment of code

I_k         // call function in a, first arg  
I_rtn       // return from a function

I_ln        // a := n
I_lp        // a := p!n
I_lg        // a := g!n
I_ll        // a := value of static variable at n
I_llp       // a := @ p!n
I_llg       // a := @ g!n
I_lll       // a := @ value of static variable at n
I_lf        // a := entry address n

I_sp        // p!n
I_sg        // g!n
I_sl        // assign a to static variable at n
I_st        // !a := b

I_mul       // a := b * a
I_div       // a := b / a
I_rem       // a := b REM a
I_add       // a := b + a
I_a         // a := a + n
I_ap        // a := a + p!n
I_ag        // a := a + g!n
I_sub       // a := b - a
I_lsh       // a := b<<a
I_rsh       // a := b>>a
I_and       // a := b & a
I_or        // a := b | a
I_xor       // a := b NEQV a
I_neg       // a := -a
I_not       // a := ~a

I_rv        // a := a!n

I_lap       // a := p!n!a
I_lkp       // a := p!n!k
I_stap      // p!n!a := b
I_stkp      // p!n!k := a

I_lkg       // a := g!n!k
I_stkg      // g!n!k := a

I_swb       // binary chop switch on a
I_swl       // label vector switch on a

I_xch       // swap a and b
I_gbyt      // a := b%a
I_pbyt      // b%a := c
I_xpbyt     // a%b := c
I_atc       // c := a
I_atb       // b := a

I_btc       // c := b

I_sys       // a := sys(P!3, p!4, p!5, p!6)
I_mdiv      // a := muldiv(p!3, p!4, p!5); RETURN
I_chgco     // a := changeco(p!3, p!4); RETURN

I_goto      // pc := a
I_j         // j

I_jeq
I_jeq0
I_jne
I_jne0
I_jls
I_jls0
I_jgr
I_jgr0
I_jle
I_jle0
I_jge
I_jge0
}

LET start() = VALOF
{ LET argv = VEC 100
  LET retcode = 0

  UNLESS rdargs(",,,,,,,,,,-o/k,-t/s", argv, 100) DO
  { writes("Bad arguments for *"opt*"*n")
    RESULTIS 20
  }

  stdout := output()
  tofile := stdout
  IF argv!10 DO
  { tofile := findoutput(argv!10)         // -o filename
    UNLESS tofile DO
    { writef("Trouble with output file: %s*n", argv!10)
      RESULTIS 20
    }
  }
  tracing := argv!11                      // -t

  selectoutput(tofile)

  segv := getvec(9+3)            // Extra two for SYSLIB and BLIB
  spacev := getvec(SpaceUpb)
  spacep, spacet := spacev, spacev+SpaceUpb
  UNLESS segv & gvec & spacev DO
  { writef("Insufficient space*n")
    retcode := 20
    GOTO fin
  }
  FOR i = 0 TO 9+3 DO segv!i := 0 // Include space for SYSLIB BLIB and clihook
  segp := 0
  progv, progp := spacep, spacep

  FOR i = 0 TO 9 IF argv!i DO
  { LET seg = ?
    IF tracing DO writef("Loading: %s*n", argv!i)
    seg := loadseglist(argv!i)

    TEST seg
    THEN { segv!segp := seg
           segp := segp+1
         }
    ELSE writef("Bad Cintcode segment: %s*n", argv!i)
  }

  IF tracing DO writef("Loading: %s*n", "BLIB")
  segv!segp := loadseglist("BLIB")
  TEST segv!segp THEN segp := segp+1
                 ELSE writef("Unable to load BLIB*n")


  IF tracing DO writef("Loading: %s*n", "SYSLIB")
  segv!segp := loadseglist("SYSLIB")
  TEST segv!segp THEN segp := segp+1
                 ELSE writef("Unable to load SYSLIB*n")


IF tracing DO writef("Loading: %s*n", "clihook")
  segv!segp := loadseglist("clihook")
  TEST segv!segp THEN segp := segp+1
                 ELSE writef("Unable to load clihook*n")

  progupb := progp - spacev  // upb in words
  spacep := progp

  stackv   := spacep; spacep := spacep + StackUpb + 1
  gvec     := spacep; spacep := spacep + GvecUpb + 1
  globiv   := spacep; spacep := spacep + GvecUpb + 1
  progiv   := spacep; spacep := spacep + 4*progupb + 1
  progivt  := spacep
  proglink := spacep; spacep := spacep + 4*progupb + 1
  codev    := spacep; spacep := spacep + CodevUpb + 1
  codep    := codev
  codet    := spacep

  IF spacep>spacet DO
  { writef("Insufficient space*n")
    retcode := 20
    GOTO fin
  }
  FOR i = 0 TO GvecUpb DO gvec!i, globiv!i := 0, 0
  FOR i = 0 TO StackUpb DO stackv!i := 0
  gvec!0 := GvecUpb                 // The size of the global vector
  FOR i = 0 TO 4*progupb DO progiv!i, proglink!i := 0, 0

  FOR i = 0 TO 9+3 IF segv!i DO initseglist(segv!i, gvec)
  
  IF tracing DO
  { FOR i = 1 TO gvec!0 IF gvec!i DO
    { writef("G!%i3: %i6  ", i, gvec!i)
      IF globiv!i DO prmarks(globiv!i)
      newline()
    }
    newline()
    writef("progv    = %i6*n",  progv    -spacev)
    writef("progp    = %i6*n",  progp    -spacev)
    writef("stackv   = %i6*n",  stackv   -spacev)
    writef("gvec     = %i6*n",  gvec     -spacev)
    writef("globiv   = %i6*n",  globiv   -spacev)
    writef("progiv   = %i6*n",  progiv   -spacev)
    writef("progivt  = %i6*n",  progivt  -spacev)
    writef("proglink = %i6*n",  proglink -spacev)
    writef("codev    = %i6*n",  codev    -spacev)
    writef("spacep   = %i6*n",  spacep   -spacev)
    writef("spacet   = %i6*n",  spacet   -spacev)
  }

//  FOR p = 0 TO progp-progv-1 DO
//    writef("%i6: %x8*n", 4*p, progv!p)
//  newline()

  // Scan all code reachable via global functions
  // and generate simple code
  FOR gn = 0 TO gvec!0 UNLESS (globiv!gn & M_ginit)=0 DO
  { IF tracing & isfun(gvec!gn) DO prentry(gvec!gn)
    scan(gvec!gn)
    markprog(gvec!gn, M_ginit)
  }
/*
writef("prog-prov = %n*n", progp-progv)
  FOR pc = 0 TO (progp-progv)*4 - 1 DO
  { writef("%i6: %x2 ", pc, progv%pc)
    prmarks(progiv!pc)
    newline()
    UNLESS (progiv!pc & M_f)=0 DO prinstr(pc)
  }

  FOR n = 0 TO gvec!0 IF globiv!n DO
  { writef("G!%i4: %i6  ", n, gvec!n)
    prmarks(globiv!n)
    newline()
  }
*/
  r_a     := 0
  r_b     := 0
  r_c     := 0
  r_p     := stackv
  r_g     := gvec
  r_pc    := gvec!4    // Start by calling clihook (to init i/o)

  writef("*nEntering interpreter*n")

  WHILE r_pc DO r_pc := interpret(r_pc)

  IF r_a DO writef("*nstart returned %n*n", r_a)

fin:
  FOR i = 0 TO 9+3 IF segv!i DO unloadseglist(segv!i)
  UNLESS tofile=stdout DO endwrite()
  selectoutput(stdout)
  freevec(spacev)
  freevec(segv)
  RESULTIS retcode
}
 
AND loadseglist(filename) = VALOF
{ LET list  = 0;
  LET liste = 0;
  LET oldin = input()

  LET fp = pathfindinput(filename, "BCPLPATH");
  UNLESS fp RESULTIS 0
  selectinput(fp)

  { LET type = rdhex()

    SWITCHON type INTO
    { DEFAULT:
          err:    unloadseglist(list)
                  list := 0
      CASE -1:    endread()
                  RESULTIS list

      CASE T_hunk:
               {  LET i, n = ?, rdhex()
                  LET np = progp+n+1
                  IF np>spacet GOTO err
                  progp!0 := 0
                  FOR i = 1 TO n DO progp!i := rdhex()
                  TEST list=0 THEN list := progp
                              ELSE !liste := progp
                  liste := progp
                  progp := np
                  LOOP
                }

      CASE T_end:
    }
  } REPEAT
} 

// unloadseglist has nothing to do since segments are
// loaded into spacev
AND unloadseglist(segl) BE RETURN

/* rdhex reads in one hex number including the terminating character
   and returns its value. EOF returns -1.
*/
AND rdhex() = VALOF
{ LET w = 0
  LET ch = rdch()

   WHILE ch=' ' | ch='*n' DO ch := rdch()

   IF ch='#' DO { /* remove comments from object modules */
                   UNTIL ch='*n' | ch = endstreamch DO ch := rdch()
                   RESULTIS rdhex()
                }

   {  LET d = 100
      IF '0'<=ch<='9' DO d := ch-'0'
      IF 'A'<=ch<='F' DO d := ch-'A'+10
      IF 'a'<=ch<='f' DO d := ch-'a'+10

      IF d=100 RESULTIS ch=endstreamch -> -1, w
      w := (w<<4) | d
      ch := rdch()
   } REPEAT
}

AND initseglist(segl, g) = VALOF
{ LET a = segl
  LET gsize = g!0
 
  WHILE a DO
  { LET base = (a-progv+1)<<2 // start of a section
    LET p = a + a!1           // last word of a section
    IF !p>gsize RESULTIS 0
    { p := p-2                // next (gn, entry) pair
      UNLESS p!1 BREAK
      g!(!p) := base + p!1    // initialise the global
      markglob(!p, M_ginit)
    } REPEAT
    a := !a    // Deal with the next section in the list
  }
  RESULTIS segl
}

AND markprog(a, m) BE progiv!a := progiv!a | m

AND markglob(n, m) BE globiv!n := globiv!n | m

AND prmarks(marks) BE WHILE marks DO
{ LET bit = marks & -marks
  marks := marks-bit
  SWITCHON bit INTO
  { DEFAULT:        writef("Bad:%x8 ", bit); ENDCASE

    CASE M_null:                             ENDCASE

    CASE M_f:       // Cintcode function byte
                    writef("f ");            ENDCASE
    CASE M_i:       // Cintcode immediate data
                    writef("i ");            ENDCASE
    CASE M_d:       // Static data
                    writef("d ");            ENDCASE
    CASE M_rd:      // Data read
                    writef("rd ");           ENDCASE
    CASE M_wr:      // Data written
                    writef("wr ");           ENDCASE
    CASE M_lab:     // Destination of a jump
                    writef("lab ");          ENDCASE
    CASE M_flab:    // Function entry point
                    writef("flab ");         ENDCASE
    CASE M_pto:     // Address taken
                    writef("pto ");          ENDCASE
    CASE M_rf:      // Reachable function byte
                    writef("rf ");           ENDCASE
    CASE M_ginit:   // Initialised global function
                    writef("ginit ");        ENDCASE
    CASE M_lf:      // Non global function
                    writef("lf ");           ENDCASE
    CASE M_nyet:    // Not yet implemented
                    writef("nyet ");         ENDCASE
  }
}

AND wrfcode(f) BE
{ LET s = VALOF SWITCHON f&31 INTO
   { DEFAULT:
      CASE  0: RESULTIS "     -     K   LLP     L    LP    SP    AP     A"
      CASE  1: RESULTIS "     -    KH  LLPH    LH   LPH   SPH   APH    AH"
      CASE  2: RESULTIS "   BRK    KW  LLPW    LW   LPW   SPW   APW    AW"
      CASE  3: RESULTIS "    K3   K3G  K3G1  K3GH   LP3   SP3   AP3  L0P3"
      CASE  4: RESULTIS "    K4   K4G  K4G1  K4GH   LP4   SP4   AP4  L0P4"
      CASE  5: RESULTIS "    K5   K5G  K5G1  K5GH   LP5   SP5   AP5  L0P5"
      CASE  6: RESULTIS "    K6   K6G  K6G1  K6GH   LP6   SP6   AP6  L0P6"
      CASE  7: RESULTIS "    K7   K7G  K7G1  K7GH   LP7   SP7   AP7  L0P7"
      CASE  8: RESULTIS "    K8   K8G  K8G1  K8GH   LP8   SP8   AP8  L0P8"
      CASE  9: RESULTIS "    K9   K9G  K9G1  K9GH   LP9   SP9   AP9  L0P9"
      CASE 10: RESULTIS "   K10  K10G K10G1 K10GH  LP10  SP10  AP10 L0P10"
      CASE 11: RESULTIS "   K11  K11G K11G1 K11GH  LP11  SP11  AP11 L0P11"
      CASE 12: RESULTIS "    LF   S0G  S0G1  S0GH  LP12  SP12  AP12 L0P12"
      CASE 13: RESULTIS "   LF$   L0G  L0G1  L0GH  LP13  SP13 XPBYT     S"
      CASE 14: RESULTIS "    LM   L1G  L1G1  L1GH  LP14  SP14   LMH    SH"
      CASE 15: RESULTIS "   LM1   L2G  L2G1  L2GH  LP15  SP15   BTC  MDIV"
      CASE 16: RESULTIS "    L0    LG   LG1   LGH  LP16  SP16   NOP CHGCO"
      CASE 17: RESULTIS "    L1    SG   SG1   SGH   SYS    S1    A1   NEG"
      CASE 18: RESULTIS "    L2   LLG  LLG1  LLGH   SWB    S2    A2   NOT"
      CASE 19: RESULTIS "    L3    AG   AG1   AGH   SWL    S3    A3  L1P3"
      CASE 20: RESULTIS "    L4   MUL   ADD    RV    ST    S4    A4  L1P4"
      CASE 21: RESULTIS "    L5   DIV   SUB   RV1   ST1   XCH    A5  L1P5"
      CASE 22: RESULTIS "    L6   REM   LSH   RV2   ST2  GBYT  RVP3  L1P6"
      CASE 23: RESULTIS "    L7   XOR   RSH   RV3   ST3  PBYT  RVP4  L2P3"
      CASE 24: RESULTIS "    L8    SL   AND   RV4  STP3   ATC  RVP5  L2P4"
      CASE 25: RESULTIS "    L9   SL$    OR   RV5  STP4   ATB  RVP6  L2P5"
      CASE 26: RESULTIS "   L10    LL   LLL   RV6  STP5     J  RVP7  L3P3"
      CASE 27: RESULTIS "  FHOP   LL$  LLL$   RTN  GOTO    J$ ST0P3  L3P4"
      CASE 28: RESULTIS "   JEQ   JNE   JLS   JGR   JLE   JGE ST0P4  L4P3"
      CASE 29: RESULTIS "  JEQ$  JNE$  JLS$  JGR$  JLE$  JGE$ ST1P3  L4P4"
      CASE 30: RESULTIS "  JEQ0  JNE0  JLS0  JGR0  JLE0  JGE0 ST1P4     -"
      CASE 31: RESULTIS " JEQ0$ JNE0$ JLS0$ JGR0$ JLE0$ JGE0$     -     -"
   }
   LET n = f>>5 & 7
   FOR i = 6*n+1 TO 6*(n+1) DO wrch(s%i)
}

AND prinstr(pc) BE
{ LET a = 0
   writef("%i6: ", pc)
   wrfcode(progv%pc)
   SWITCHON instrtype(progv%pc) INTO
   { DEFAULT:
      CASE '0': newline();                           RETURN
      CASE '1': a  := gb(pc+1);                      ENDCASE
      CASE '2': a  := gh(pc+1);                      ENDCASE
      CASE '4': a  := gw(pc+1);                      ENDCASE
      CASE 'R': a  := pc+1 + gsb(pc+1);              ENDCASE
      CASE 'I': pc := pc+1 + 2*gb(pc+1) & #xFFFFFFFE
                a  := pc + gsh(pc);                  ENDCASE
   }
   writef("  %n*n", a)
}

AND prentry(f) BE writef("*n%s:*n", progv+(f>>2)-2)

AND isfun(f) = VALOF
{ LET a = progv + (f>>2)
   UNLESS (f&3)=0 RESULTIS FALSE
   IF a!-3=Entryword & (a-2)%0=7 RESULTIS TRUE 
   RESULTIS FALSE
}


AND gb(pc) = progv%pc

AND gsb(pc) = progv%pc<=127 -> progv%pc, progv%pc-256

AND gsh(pc) = VALOF
{ LET h = gh(pc)
   RESULTIS h<=#x7FFF -> h, h - #x10000
}

AND gh(pc) = VALOF
{ LET w = ?
   LET p = @w  // Designed to work on both Big and Little Ender M/Cs.
   p%0, p%1, p%2, p%3 := progv%pc, progv%(pc+1), progv%pc, progv%(pc+1)
   RESULTIS w & #xFFFF
}

AND gw(pc) = VALOF
{ LET w = ?
   LET p = @w  // Designed to work on both Big and Little Ender M/Cs.
   p%0, p%1, p%2, p%3 := progv%pc, progv%(pc+1), progv%(pc+2), progv%(pc+3)
   RESULTIS w
}

AND instrtype(f) = "?0000000000RI10000000000000RIRI*
                  *124111111111111111110000RIRIRIRI*
                  *12411111111111111111000000RIRIRI*
                  *1242222222222222222200000000RIRI*
                  *124000000000000000BL00000000RIRI*
                  *12400000000000000000000000RIRIRI*
                  *1240000000000?2?000000000000000?*
                  *124000000000012?00000000000000??"%f

AND nextpc(pc) = VALOF SWITCHON instrtype(progv%pc) INTO
                       { DEFAULT:
                          CASE '0': RESULTIS pc+1
                          CASE '1':
                          CASE 'R':
                          CASE 'I': RESULTIS pc+2
                          CASE '2': RESULTIS pc+3
                          CASE '4': RESULTIS pc+5
                          CASE 'B': pc := pc+2 & #xFFFFFFFE
                                    RESULTIS pc + 4*gh(pc) + 6
                          CASE 'L': pc := pc+2 & #xFFFFFFFE
                                    RESULTIS pc + 2*gh(pc) + 6
                       }

  
AND scan(pc) BE
{ LET f = progv%pc
  IF progiv!pc RETURN        // Already scanned
  IF tracing DO prinstr(pc)
  markprog(pc, M_f)
  proglink!pc := codep // Link to code fragment for this instrction
  pc := pc+1
  SWITCHON f INTO
  { DEFAULT:  writef("Unexpected Cintcode function code %n*n", f)
              RETURN

    CASE F_mul:   //a = b * a;        goto fetch;
                  gen1(I_mul)
                  gen2(I_j, pc)
                  LOOP

    CASE F_div:   //if(a==0) {res = 5; pc--; goto ret; } /* Division by zero */
                  //a = b / a;        goto fetch;
                  gen1(I_div)
                  gen2(I_j, pc)
                  LOOP
    CASE F_rem:   //if(a==0) {res = 5; pc--; goto ret; } /* Division by zero */
                  //a = b % a;        goto fetch;
                  gen1(I_rem)
                  gen2(I_j, pc)
                  LOOP
    CASE F_add:   //a = b + a;        goto fetch;
                  gen1(I_add)
                  gen2(I_j, pc)
                  LOOP
    CASE F_sub:   //a = b - a;        goto fetch;
                  gen1(I_sub)
                  gen2(I_j, pc)
                  LOOP
    CASE F_neg:   //a = - a;          goto fetch;
                  gen1(I_neg)
                  gen2(I_j, pc)
                  LOOP

    CASE F_fhop:  //a = 0; pc++;      goto fetch;
                  gen2(I_ln, 0)
                  gen2(I_j, pc+1)
                  LOOP

    CASE F_lsh:   //if (a>31) b=0; /* bug */
                  //a = b << a;       goto fetch;
                  gen1(I_lsh)
                  gen2(I_j, pc)
                  LOOP
    CASE F_rsh:   //if (a>31) b=0; /* bug */
                  //a = WD((UWD b)>>a); goto fetch;
                  gen1(I_rsh)
                  gen2(I_j, pc)
                  LOOP
    CASE F_not:   //a = ~ a;          goto fetch;
                  gen1(I_not)
                  gen2(I_j, pc)
                  LOOP
    CASE F_and:   //a = b & a;        goto fetch;
                  gen1(I_and)
                  gen2(I_j, pc)
                  LOOP
    CASE F_or:    //a = b | a;        goto fetch;
                  gen1(I_or)
                  gen2(I_j, pc)
                  LOOP
    CASE F_xor:   //a = b ^ a;        goto fetch;
                  gen1(I_xor)
                  gen2(I_j, pc)
                  LOOP

    CASE F_goto:  //pc = a;           goto fetch;
                  gen1(I_goto)    // may fail to scan target
                  RETURN

    CASE F_brk:   //res = 2; pc--; goto ret;  /* BREAKPOINT  */
                  RETURN
                 
    CASE F_rv+6:  //a = W[a+6]; goto fetch;
    CASE F_rv+5:  //a = W[a+5]; goto fetch;
    CASE F_rv+4:  //a = W[a+4]; goto fetch;
    CASE F_rv+3:  //a = W[a+3]; goto fetch;
    CASE F_rv+2:  //a = W[a+2]; goto fetch;
    CASE F_rv+1:  //a = W[a+1]; goto fetch;
    CASE F_rv:    //a = W[a+0]; goto fetch;
                  gen2(I_rv, f-F_rv)
                  gen2(I_j, pc)
                  LOOP

    CASE F_st+3:  //W[a+3] = b; goto fetch;
    CASE F_st+2:  //W[a+2] = b; goto fetch;
    CASE F_st+1:  //W[a+1] = b; goto fetch;
    CASE F_st:    //W[a+0] = b; goto fetch;
                  gen2(I_st, f-F_st)
                  gen2(I_j, pc)
                  LOOP

    CASE F_chgco: //W[Wg[Gn_currco]] = Wp[0];     /* !currco := !p    */
                  //pc = Wp[1];                   /* pc      := p!1   */
                  //Wg[Gn_currco] = Wp[4];        /* currco  := cptr  */
                  //p = W[Wp[4]]>>2;              /* p       := !cptr */
                  //Wp = W+p;
                  //goto fetch;
                  gen1(I_chgco)
                  RETURN

    CASE F_mdiv:  //a = muldiv(Wp[3], Wp[4], Wp[5]);
                  //Wg[Gn_result2] = result2;
                  ///* fall through to return  */
                  gen1(I_mdiv)      // may need looking at
                  RETURN

    CASE F_rtn:   //pc = Wp[1]; p  = W[p]>>2;  Wp = W+p; goto fetch;
                  gen1(I_rtn)
                  RETURN

    CASE F_gbyt: //a = B[a+(b<<2)];            goto fetch;
                  gen1(I_gbyt)
                  gen2(I_j, pc)
                  LOOP
    CASE F_pbyt: //B[a+(b<<2)] = (char)c;      goto fetch;
                  gen1(I_pbyt)
                  gen2(I_j, pc)
                  LOOP
    CASE F_xpbyt://B[b+(a<<2)] = (char)c;      goto fetch;
                  gen1(I_xpbyt)
                  gen2(I_j, pc)
                  LOOP
    CASE F_atc:  //c = a;                      goto fetch;
                  gen1(I_atc)
                  gen2(I_j, pc)
                  LOOP
    CASE F_btc:  //c = b;                      goto fetch;
                  gen1(I_btc)
                  gen2(I_j, pc)
                  LOOP
    CASE F_atb:  //b = a;                      goto fetch;
                  gen1(I_atb)
                  gen2(I_j, pc)
                  LOOP
    CASE F_xch:  //a = a^b; b = a^b; a = a^b;  goto fetch;
                  gen1(I_xch)
                  gen2(I_j, pc)
                  LOOP

    CASE F_swb: //{ INT32 n,k,val,i=1;
                //  k = (pc+1)>>1;
                //  n = H[k];
                //  while(i<=n)
                //  { i = i+i;
                //    val = H[k+i];
                //    if (a==val) { k += i; break; }
                //    if (a<val) i++;
                //  }
                //  k++;
                //  pc = (k<<1) + SH[k];
                //  goto fetch;
                //}
                { LET q = pc+1 & -2
                  LET n = gh(q)
                  gen1(I_swb)
                  FOR i = 0 TO n DO
                  { LET p = q + 4*i
                    gen1(gh(p))
                    gen1(p+2 + gsh(p+2))
                  }

                  // Scan default and case labels
                  FOR i = 0 TO n DO scan(q+4*i+2 + gsh(q+4*i+2))
                  RETURN
                }

    CASE F_swl: //{ INT32 n,q;
                //  q = (pc+1)>>1;
                //  n = H[q++];
                //  if(0<=a && a<n) q = q + a + 1;
                //  pc = (q<<1) + SH[q];
                //  goto fetch;
                //}
                { LET q = pc+1 & -2
                  LET n = gh(q)
                  q := q+2
                  
                  gen2(I_swl, n)
                  FOR i = 0 TO n DO gen1(q+2*i + gsh(q+2*i))
                  // Scan default and case labels
                  FOR i = 0 TO n DO scan(q+2*i + gsh(q+2*i))
                  RETURN
                }


    CASE F_sys: //if(a<=0) {
                //  if(a==0)  { res = Wp[4]; goto ret; }  /* finish      */
                //  if(a==-1) {       /* oldcount := sys(-1, newcount)   */
                //    a = count;
                //    count = Wp[4];
                //    res = -1;
                //    goto ret;
                //  }
                //}
                //a = dosys(p, g); 
                //goto fetch;                          /* system call */
                  gen1(I_sys)
                  gen2(I_j, pc)
                  LOOP

    CASE F_lp0+16:  //b = a; a = Wp[16]; goto fetch;
    CASE F_lp0+15:  //b = a; a = Wp[15]; goto fetch;
    CASE F_lp0+14:  //b = a; a = Wp[14]; goto fetch;
    CASE F_lp0+13:  //b = a; a = Wp[13]; goto fetch;
    CASE F_lp0+12:  //b = a; a = Wp[12]; goto fetch;
    CASE F_lp0+11:  //b = a; a = Wp[11]; goto fetch;
    CASE F_lp0+10:  //b = a; a = Wp[10]; goto fetch;
    CASE F_lp0+9:   //b = a; a = Wp[9];  goto fetch;
    CASE F_lp0+8:   //b = a; a = Wp[8];  goto fetch;
    CASE F_lp0+7:   //b = a; a = Wp[7];  goto fetch;
    CASE F_lp0+6:   //b = a; a = Wp[6];  goto fetch;
    CASE F_lp0+5:   //b = a; a = Wp[5];  goto fetch;
    CASE F_lp0+4:   //b = a; a = Wp[4];  goto fetch;
    CASE F_lp0+3:   //b = a; a = Wp[3];  goto fetch;
                  gen1(I_atb)
                  gen2(I_lp, f-F_lp0)
                  gen2(I_j, pc)
                  LOOP

    CASE F_lp:   //b = a; a = Wp[B[pc++]];          goto fetch;
                  gen1(I_atb)
                  gen2(I_lp, gb(pc)) 
                  pc := pc+1
                  gen2(I_j, pc)
                  LOOP
    CASE F_lph:  //b = a; a = Wp[GH(pc)];  pc += 2; goto fetch;
                  gen1(I_atb)
                  gen2(I_lp, gh(pc))
                  pc := pc+2
                  gen2(I_j, pc)
                  LOOP
    CASE F_lpw:  //b = a; a = Wp[GW(pc)];  pc += 4; goto fetch;
                  gen1(I_atb)
                  gen2(I_lp, gw(pc))
                  pc := pc+4
                  gen2(I_j, pc)
                  LOOP

    CASE F_llp:  //b = a; a = p+B[pc++];             goto fetch;
                  gen1(I_atb)
                  gen2(I_llp, gb(pc))
                  pc := pc+1
                  gen2(I_j, pc)
                  LOOP
    CASE F_llph: //b = a; a = p+GH(pc);     pc += 2; goto fetch;
                  gen1(I_atb)
                  gen2(I_llp, gh(pc))
                  pc := pc+2
                  gen2(I_j, pc)
                  LOOP
    CASE F_llpw: //b = a; a = p+GW(pc);     pc += 4; goto fetch;
                  gen1(I_atb)
                  gen2(I_llp, gw(pc))
                  pc := pc+4
                  gen2(I_j, pc)
                  LOOP
    CASE F_sp0+16: //Wp[16] = a; goto fetch;
    CASE F_sp0+15: //Wp[15] = a; goto fetch;
    CASE F_sp0+14: //Wp[14] = a; goto fetch;
    CASE F_sp0+13: //Wp[13] = a; goto fetch;
    CASE F_sp0+12: //Wp[12] = a; goto fetch;
    CASE F_sp0+11: //Wp[11] = a; goto fetch;
    CASE F_sp0+10: //Wp[10] = a; goto fetch;
    CASE F_sp0+9:  //Wp[9]  = a; goto fetch;
    CASE F_sp0+8:  //Wp[8]  = a; goto fetch;
    CASE F_sp0+7:  //Wp[7]  = a; goto fetch;
    CASE F_sp0+6:  //Wp[6]  = a; goto fetch;
    CASE F_sp0+5:  //Wp[5]  = a; goto fetch;
    CASE F_sp0+4:  //Wp[4]  = a; goto fetch;
    CASE F_sp0+3:  //Wp[3]  = a; goto fetch;
                  gen2(I_sp, f-F_sp0)
                  gen2(I_j, pc)
                  LOOP

    CASE F_sp:    //Wp[B[pc++]] = a;                  goto fetch;
                  gen2(I_sp, gb(pc))
                  pc := pc+1
                  gen2(I_j, pc)
                  LOOP
    CASE F_sph:   //Wp[GH(pc)]  = a;         pc += 2; goto fetch;
                  gen2(I_sp, gh(pc))
                  pc := pc+2
                  gen2(I_j, pc)
                  LOOP
    CASE F_spw:   //Wp[GW(pc)]  = a;         pc += 4; goto fetch;
                  gen2(I_sp, gw(pc))
                  pc := pc+4
                  gen2(I_j, pc)
                  LOOP

    CASE F_lgh:   //b = a; a = Wg[GH(pc)];   pc += 2; goto fetch;
                  gen1(I_atb)
                  gen2(I_lg, gh(pc))
                  pc := pc+2
                  gen2(I_j, pc)
                  LOOP
    CASE F_lg1:   //b = a; a = Wg1[B[pc++]];          goto fetch;
                  gen1(I_atb)
                  gen2(I_lg, gb(pc)+256)
                  pc := pc+1
                  gen2(I_j, pc)
                  LOOP
    CASE F_lg:    //b = a; a = Wg[B[pc++]];           goto fetch; 
                  gen1(I_atb)
                  gen2(I_lg, gb(pc))
                  pc := pc+1
                  gen2(I_j, pc)
                  LOOP

    CASE F_sgh:   //Wg[GH(pc)]   = a;        pc += 2; goto fetch;
                  gen2(I_sg, gh(pc))
                  pc := pc+2
                  gen2(I_j, pc)
                  LOOP
    CASE F_sg1:   //Wg1[B[pc++]] = a;                 goto fetch;
                  gen2(I_sg, gb(pc)+256)
                  pc := pc+1
                  gen2(I_j, pc)
                  LOOP
    CASE F_sg:    //Wg[B[pc++]]  = a;                 goto fetch;
                  gen2(I_sg, gb(pc))
                  pc := pc+1
                  gen2(I_j, pc)
                  markglob((progv%pc), M_wr)
                  LOOP

    CASE F_llgh: //b = a; a = g+GH(pc);      pc += 2; goto fetch;
                  gen1(I_atb)
                  gen2(I_llg, gh(pc))
                  pc := pc+2
                  gen2(I_j, pc)
                  LOOP

    CASE F_llg1: //b = a; a = g+256+B[pc++];          goto fetch;
                  gen1(I_atb)
                  gen2(I_llg, gb(pc)+256)
                  pc := pc+1
                  gen2(I_j, pc)
                  LOOP
    CASE F_llg:  //b = a; a = g+B[pc++];              goto fetch;
                  gen1(I_atb)
                  gen2(I_llg, gb(pc))
                  pc := pc+1
                  gen2(I_j, pc)
                  LOOP

    CASE F_ll+1: //i = (pc>>1) + B[pc];
                 //i = (i<<1) + SH[i];
                 //b = a; a = W[i>>2];          pc++; goto fetch;
                  gen1(I_atb)
                  gen2(I_ll, indaddr(pc))
                  pc := pc+1
                  gen2(I_j, pc)
                  LOOP

    CASE F_ll:   //b = a; a = W[(pc+SB[pc])>>2];pc++; goto fetch;
                  gen1(I_atb)
                  gen2(I_ll, reladdr(pc))
                  pc := pc+1
                  gen2(I_j, pc)
                  LOOP

    CASE F_sl+1: //i = (pc>>1) + B[pc];
                 //i = (i<<1) + SH[i];
                 //W[i>>2] = a;                 pc++; goto fetch;
                  gen2(I_sl, indaddr(pc))
                  pc := pc+1
                  gen2(I_j, pc)
                  LOOP

    CASE F_sl:   //W[(pc+SB[pc])>>2] = a;       pc++; goto fetch;
                  gen2(I_sl, reladdr(pc))
                  pc := pc+1
                  gen2(I_j, pc)
                  LOOP
   
    CASE F_lll+1://i = (pc>>1) + B[pc];
                 //i = (i<<1) + SH[i];
                 //b = a; a = i>>2;             pc++; goto fetch;
                  gen1(I_atb)
                  gen2(I_lll, indaddr(pc))
                  pc := pc+1
                  gen2(I_j, pc)
                  LOOP

    CASE F_lll:  //b = a; a = (pc+SB[pc])>>2;   pc++; goto fetch;
                  gen1(I_atb)
                  gen2(I_lll, reladdr(pc))
                  pc := pc+1
                  gen2(I_j, pc)
                  LOOP

    CASE F_l0+10: //b = a; a = 10; goto fetch;
    CASE F_l0+9:  //b = a; a =  9; goto fetch;
    CASE F_l0+8:  //b = a; a =  8; goto fetch;
    CASE F_l0+7:  //b = a; a =  7; goto fetch;
    CASE F_l0+6:  //b = a; a =  6; goto fetch;
    CASE F_l0+5:  //b = a; a =  5; goto fetch;
    CASE F_l0+4:  //b = a; a =  4; goto fetch;
    CASE F_l0+3:  //b = a; a =  3; goto fetch;
    CASE F_l0+2:  //b = a; a =  2; goto fetch;
    CASE F_l0+1:  //b = a; a =  1; goto fetch;
    CASE F_l0:    //b = a; a =  0; goto fetch;
    CASE F_l0-1:  //b = a; a = -1; goto fetch; 
                  gen1(I_atb)
                  gen2(I_ln, f-F_l0)
                  gen2(I_j, pc)
                  LOOP

    CASE F_l:     //b = a; a = B[pc++];               goto fetch;
                  gen1(I_atb)
                  gen2(I_ln, gb(pc))
                  pc := pc+1
                  gen2(I_j, pc)
                  LOOP

    CASE F_lh:    //b = a; a = GH(pc);       pc += 2; goto fetch;
                  gen1(I_atb)
                  gen2(I_ln, gh(pc))
                  pc := pc+2
                  gen2(I_j, pc)
                  LOOP
    CASE F_lw:    //b = a; a = GW(pc);       pc += 4; goto fetch;
                  gen1(I_atb)
                  gen2(I_ln, gw(pc))
                  pc := pc+4
                  gen2(I_j, pc)
                  LOOP

    CASE F_lm:    //b = a; a = - WD(B[pc++]);         goto fetch;
                  gen1(I_atb)
                  gen2(I_ln, -gb(pc))
                  pc := pc+1
                  gen2(I_j, pc)
                  LOOP

    CASE F_lmh:   //b = a; a = - WD(GH(pc)); pc += 2; goto fetch;
                  gen1(I_atb)
                  gen2(I_ln, -gh(pc))
                  pc := pc+2
                  gen2(I_j, pc)
                  LOOP
                
    CASE F_lf+1:  //b = a;
                  //a = (pc>>1) + B[pc];
                  //a = (a<<1) + SH[a];         pc++; goto fetch;
                { LET dest = indaddr(pc)
                  gen1(I_atb)
                  gen2(I_lf, dest)
                  pc := pc+1
                  gen2(I_j, pc)
                  scan(dest)
                  LOOP
                }

    CASE F_lf:    //b = a; a = pc + SB[pc];     pc++; goto fetch;
                { LET dest = reladdr(pc)
                  gen1(I_atb)
                  gen2(I_lf, dest)
                  pc := pc+1
                  gen2(I_j, pc)
                  scan(dest)
                  LOOP
                }

    CASE F_k0gh+11: //Wp[11] = p<<2; p += 11; goto applygh;
    CASE F_k0gh+10: //Wp[10] = p<<2; p += 10; goto applygh;
    CASE F_k0gh+9:  //Wp[ 9] = p<<2; p +=  9; goto applygh;
    CASE F_k0gh+8:  //Wp[ 8] = p<<2; p +=  8; goto applygh;
    CASE F_k0gh+7:  //Wp[ 7] = p<<2; p +=  7; goto applygh;
    CASE F_k0gh+6:  //Wp[ 6] = p<<2; p +=  6; goto applygh;
    CASE F_k0gh+5:  //Wp[ 5] = p<<2; p +=  5; goto applygh;
    CASE F_k0gh+4:  //Wp[ 4] = p<<2; p +=  4; goto applygh;
    CASE F_k0gh+3:  //Wp[ 3] = p<<2; p +=  3;
    applygh:        //Wp    = W+p;
                    //Wp[1] = pc + 2;
                    //pc    = Wg[GH(pc)];
                    //Wp[2] = pc;
                    //Wp[3] =  a;
                    //if (pc>=0) goto fetch;
                    //goto negpc;
                  gen1(I_atb)
                  gen2(I_lg, gh(pc))
                  pc := pc+2
                  gen3(I_k, f-F_k0gh, pc)
                  LOOP

    CASE F_k0g1+11: //Wp[11] = p<<2; p += 11; goto applyg1;
    CASE F_k0g1+10: //Wp[10] = p<<2; p += 10; goto applyg1;
    CASE F_k0g1+9:  //Wp[ 9] = p<<2; p +=  9; goto applyg1;
    CASE F_k0g1+8:  //Wp[ 8] = p<<2; p +=  8; goto applyg1;
    CASE F_k0g1+7:  //Wp[ 7] = p<<2; p +=  7; goto applyg1;
    CASE F_k0g1+6:  //Wp[ 6] = p<<2; p +=  6; goto applyg1;
    CASE F_k0g1+5:  //Wp[ 5] = p<<2; p +=  5; goto applyg1;
    CASE F_k0g1+4:  //Wp[ 4] = p<<2; p +=  4; goto applyg1;
    CASE F_k0g1+3:  //Wp[ 3] = p<<2; p +=  3;
    applyg1:        //Wp    = W+p;
                    //Wp[1] = pc + 1;
                    //pc    = Wg1[B[pc]];
                    //Wp[2] = pc;
                    //Wp[3] = a;
                    //if (pc>=0) goto fetch;
                    //goto negpc;
                  gen1(I_atb)
                  gen2(I_lg, gb(pc)+256)
                  pc := pc+1
                  gen3(I_k, f-F_k0g1, pc)
                  LOOP
 
    CASE F_k0g+11: //Wp[11] = p<<2; p += 11; goto applyg;
    CASE F_k0g+10: //Wp[10] = p<<2; p += 10; goto applyg;
    CASE F_k0g+9:  //Wp[ 9] = p<<2; p +=  9; goto applyg;
    CASE F_k0g+8:  //Wp[ 8] = p<<2; p +=  8; goto applyg;
    CASE F_k0g+7:  //Wp[ 7] = p<<2; p +=  7; goto applyg;
    CASE F_k0g+6:  //Wp[ 6] = p<<2; p +=  6; goto applyg;
    CASE F_k0g+5:  //Wp[ 5] = p<<2; p +=  5; goto applyg;
    CASE F_k0g+4:  //Wp[ 4] = p<<2; p +=  4; goto applyg;
    CASE F_k0g+3:  //Wp[ 3] = p<<2; p +=  3;
    applyg:        //Wp    = W+p;
                   //Wp[1] = pc + 1;
                   //pc    = Wg[B[pc]];
                   //Wp[2] = pc;
                   //Wp[3] = a;
                   //if (pc>=0) goto fetch;
                   //goto negpc;
                  gen1(I_atb)
                  gen2(I_lg, gb(pc))
                  pc := pc+1
                  gen3(I_k, f-F_k0g, pc)
                  LOOP

    CASE F_k0+11:  //Wp[11] = p<<2; p += 11; goto applyk;
    CASE F_k0+10:  //Wp[10] = p<<2; p += 10; goto applyk;
    CASE F_k0+9:   //Wp[ 9] = p<<2; p +=  9; goto applyk;
    CASE F_k0+8:   //Wp[ 8] = p<<2; p +=  8; goto applyk;
    CASE F_k0+7:   //Wp[ 7] = p<<2; p +=  7; goto applyk;
    CASE F_k0+6:   //Wp[ 6] = p<<2; p +=  6; goto applyk;
    CASE F_k0+5:   //Wp[ 5] = p<<2; p +=  5; goto applyk;
    CASE F_k0+4:   //Wp[ 4] = p<<2; p +=  4; goto applyk;
    CASE F_k0+3:   //Wp[ 3] = p<<2; p +=  3;
    applyk:        //Wp    = W+p;
                   //Wp[1] = WD pc;
                   //pc    = a;
                   //Wp[2] = pc;
                   //Wp[3] = a = b;
                   //if (pc>=0) goto fetch;
                   //goto negpc;
                  gen3(I_k, f-F_k0, pc)
                  LOOP

    CASE F_k:      //k = B[pc]; Wp[k] = p<<2; p +=  k;
                   //Wp    = W+p;
                   //Wp[1] = pc + 1;
                   //pc    = a;
                   //Wp[2] = pc;
                   //Wp[3] = a = b;
                   //if (pc>=0) goto fetch;
                   //goto negpc;
                  gen3(I_k, gb(pc), pc+1)
                  pc := pc+1
                  LOOP

    CASE F_kh:     //k = GH(pc); Wp[k] = p<<2; p +=  k;
                   //Wp    = W+p;
                   //Wp[1] = pc + 2;
                   //pc    = a;
                   //Wp[2] = pc;
                   //Wp[3] = a = b;
                   //if (pc>=0) goto fetch;
                   //goto negpc;
                  gen3(I_k, gh(pc), pc+2)
                  pc := pc+2
                  LOOP

    CASE F_kw:     //k = GW(pc); Wp[k] = p<<2; p +=  k;
                   //Wp    = W+p;
                   //Wp[1] = pc + 4;
                   //pc    = a;
                   //Wp[2] = pc;
                   //Wp[3] = a = b;
                   //if (pc>=0) goto fetch;
                   //goto negpc;
                  gen3(I_k, gw(pc), pc+4)
                  pc := pc+4
                  LOOP

    CASE F_jeq:   //if(b==a) { pc += SB[pc];   goto fetch; }
                  //pc++; goto fetch;
                  pc := relcondjump(I_jeq, pc)
                  LOOP
    CASE F_jeq+1: //if(b==a) goto indjump;
                  //pc++; goto fetch;
                  pc := indcondjump(I_jeq, pc)
                  LOOP
    CASE F_jeq+2: //if(a==0) { pc += SB[pc];   goto fetch; }
                  //pc++; goto fetch;
                  pc := relcondjump(I_jeq0, pc)
                  LOOP
    CASE F_jeq+3: //if(a==0) goto indjump;
                  //pc++; goto fetch;
                  pc := indcondjump(I_jeq0, pc)
                  LOOP

    CASE F_jne:   //if(b!=a) { pc += SB[pc];   goto fetch; }
                  //pc++; goto fetch;
                  pc := relcondjump(I_jne, pc)
                  LOOP
    CASE F_jne+1: //if(b!=a) goto indjump;
                  //pc++; goto fetch;
                  pc := indcondjump(I_jne, pc)
                  LOOP

    CASE F_jne+2: //if(a!=0) { pc += SB[pc];   goto fetch; }
                  //pc++; goto fetch;
                  pc := relcondjump(I_jne0, pc)
                  LOOP

    CASE F_jne+3: //if(a!=0) goto indjump;
                  //pc++; goto fetch;
                  pc := indcondjump(I_jne0, pc)
                  LOOP

    CASE F_jls:   //if(b<a) { pc += SB[pc];   goto fetch; }
                  //pc++; goto fetch;
                  pc := relcondjump(I_jls, pc)
                  LOOP

    CASE F_jls+1: //if(b<a) goto indjump;
                  //pc++; goto fetch;
                  pc := indcondjump(I_jls, pc)
                  LOOP

    CASE F_jls+2: //if(a<0) { pc += SB[pc];   goto fetch; }
                  //pc++; goto fetch;
                  pc := relcondjump(I_jls0, pc)
                  LOOP

    CASE F_jls+3: //if(a<0) goto indjump;
                  //pc++; goto fetch;
                  pc := indcondjump(I_jls0, pc)
                  LOOP

    CASE F_jgr:   //if(b>a) { pc += SB[pc];   goto fetch; }
                  //pc++; goto fetch;
                  pc := relcondjump(I_jgr, pc)
                  LOOP

    CASE F_jgr+1: //if(b>a) goto indjump;
                  //pc++; goto fetch;
                  pc := indcondjump(I_jgr, pc)
                  LOOP

    CASE F_jgr+2: //if(a>0) { pc += SB[pc];   goto fetch; }
                  //pc++; goto fetch;
                  pc := relcondjump(I_jgr0, pc)
                  LOOP

    CASE F_jgr+3: //if(a>0) goto indjump;
                  //pc++; goto fetch;
                  pc := indcondjump(I_jgr0, pc)
                  LOOP

    CASE F_jle:   //if(b<=a) { pc += SB[pc];   goto fetch; }
                  //pc++; goto fetch;
                  pc := relcondjump(I_jle, pc)
                  LOOP

    CASE F_jle+1: //if(b<=a) goto indjump;
                  //pc++; goto fetch;
                  pc := indcondjump(I_jle, pc)
                  LOOP

    CASE F_jle+2: //if(a<=0) { pc += SB[pc];   goto fetch; }
                  //pc++; goto fetch;
                  pc := relcondjump(I_jle0, pc)
                  LOOP

    CASE F_jle+3: //if(a<=0) goto indjump;
                  //pc++; goto fetch;
                  pc := indcondjump(I_jle0, pc)
                  LOOP

    CASE F_jge:   //if(b>=a) { pc += SB[pc];   goto fetch; }
                  //pc++; goto fetch;
                  pc := relcondjump(I_jge, pc)
                  LOOP

    CASE F_jge+1: //if(b>=a) goto indjump;
                  //pc++; goto fetch;
                  pc := indcondjump(I_jge, pc)
                  LOOP

    CASE F_jge+2: //if(a>=0) { pc += SB[pc];   goto fetch; }
                  //pc++; goto fetch;
                  pc := relcondjump(I_jge0, pc)
                  LOOP

    CASE F_jge+3: //if(a>=0) goto indjump;
                  //pc++; goto fetch;
                  pc := indcondjump(I_jge0, pc)
                  LOOP

    CASE F_j:     //pc += SB[pc];        goto fetch;
                  pc := reladdr(pc)
                  gen2(I_j, pc) 
                  LOOP

    CASE F_j+1:   //pc = (pc>>1) + B[pc];
                  //pc = (pc<<1) + SH[pc];
                  //goto fetch;
                  pc := indaddr(pc)
                  gen2(I_j, pc)
                  LOOP 

    CASE F_ap0+12: //a = a + Wp[12]; goto fetch;
    CASE F_ap0+11: //a = a + Wp[11]; goto fetch;
    CASE F_ap0+10: //a = a + Wp[10]; goto fetch;
    CASE F_ap0+9:  //a = a + Wp[ 9]; goto fetch;
    CASE F_ap0+8:  //a = a + Wp[ 8]; goto fetch;
    CASE F_ap0+7:  //a = a + Wp[ 7]; goto fetch;
    CASE F_ap0+6:  //a = a + Wp[ 6]; goto fetch;
    CASE F_ap0+5:  //a = a + Wp[ 5]; goto fetch;
    CASE F_ap0+4:  //a = a + Wp[ 4]; goto fetch;
    CASE F_ap0+3:  //a = a + Wp[ 3]; goto fetch;
                  gen2(I_ap, f-F_ap0)
                  gen2(I_j, pc)
                  LOOP

    CASE F_ap:    //a += Wp[B[pc++]];         goto fetch;
                  gen2(I_ap, gb(pc))
                  pc := pc+1
                  gen2(I_j, pc)
                  LOOP

    CASE F_aph:   //a += Wp[GH(pc)]; pc += 2; goto fetch;
                  gen2(I_ap, gh(pc))
                  pc := pc+2
                  gen2(I_j, pc)
                  LOOP

    CASE F_apw:   //a += Wp[GW(pc)]; pc += 4; goto fetch;
                  gen2(I_ap, gw(pc))
                  pc := pc+4
                  gen2(I_j, pc)
                  LOOP

    CASE F_agh:   //a += Wg[GH(pc)]; pc += 2; goto fetch;
                  gen2(I_ag, gh(pc))
                  pc := pc+2
                  gen2(I_j, pc)
                  LOOP

    CASE F_ag1:   //a += Wg1[B[pc++]];        goto fetch;
                  gen2(I_ag, gb(pc)+256)
                  pc := pc+1
                  gen2(I_j, pc)
                  LOOP

    CASE F_ag:    //a += Wg[B[pc++]];         goto fetch;
                  gen2(I_ag, gb(pc))
                  pc := pc+1
                  gen2(I_j, pc)
                  LOOP

    CASE F_a0+5: //a += 5; goto fetch;
    CASE F_a0+4: //a += 4; goto fetch;
    CASE F_a0+3: //a += 3; goto fetch;
    CASE F_a0+2: //a += 2; goto fetch;
    CASE F_a0+1: //a += 1; goto fetch;
                  gen2(I_a, f-F_a0)
                  gen2(I_j, pc)
                  LOOP

    CASE F_nop:  //        goto fetch;
                  gen2(I_j, pc)
                  LOOP

    CASE F_a:    //a += B[pc++];           goto fetch;
                  gen2(I_a, gb(pc))
                  pc := pc+1
                  gen2(I_j, pc)
                  LOOP

    CASE F_ah:   //a += GH(pc);   pc += 2; goto fetch;
                  gen2(I_a, gh(pc))
                  pc := pc+2
                  gen2(I_j, pc)
                  LOOP

    CASE F_aw:   //a += GW(pc);   pc += 4; goto fetch;
                  gen2(I_a, gw(pc))
                  pc := pc+4
                  gen2(I_j, pc)
                  LOOP

    CASE F_s:    //a -= B[pc++];           goto fetch;
                  gen2(I_a, -gb(pc))
                  pc := pc+1
                  gen2(I_j, pc)
                  LOOP

    CASE F_sh:   //a -= GH(pc);   pc += 2; goto fetch;
                  gen2(I_a, -gh(pc))
                  pc := pc+2
                  gen2(I_j, pc)
                  LOOP

    CASE F_s0+4: //a -= 4; goto fetch;
    CASE F_s0+3: //a -= 3; goto fetch;
    CASE F_s0+2: //a -= 2; goto fetch;
    CASE F_s0+1: //a -= 1; goto fetch;
                  gen2(I_a, -(f-F_s0))
                  gen2(I_j, pc)
                  LOOP

    CASE F_l0p0+12: //b = a; a = W[Wp[12]+0]; goto fetch;
    CASE F_l0p0+11: //b = a; a = W[Wp[11]+0]; goto fetch;
    CASE F_l0p0+10: //b = a; a = W[Wp[10]+0]; goto fetch;
    CASE F_l0p0+9:  //b = a; a = W[Wp[ 9]+0]; goto fetch;
    CASE F_l0p0+8:  //b = a; a = W[Wp[ 8]+0]; goto fetch;
    CASE F_l0p0+7:  //b = a; a = W[Wp[ 7]+0]; goto fetch;
    CASE F_l0p0+6:  //b = a; a = W[Wp[ 6]+0]; goto fetch;
    CASE F_l0p0+5:  //b = a; a = W[Wp[ 5]+0]; goto fetch;
    CASE F_l0p0+4:  //b = a; a = W[Wp[ 4]+0]; goto fetch;
    CASE F_l0p0+3:  //b = a; a = W[Wp[ 3]+0]; goto fetch;
                  gen1(I_atb)
                  gen3(I_lkp, 0, f-F_l0p0)
                  gen2(I_j, pc)
                  LOOP

    CASE F_l1p0+6:  //b = a; a = W[Wp[ 6]+1]; goto fetch;
    CASE F_l1p0+5:  //b = a; a = W[Wp[ 5]+1]; goto fetch;
    CASE F_l1p0+4:  //b = a; a = W[Wp[ 4]+1]; goto fetch;
    CASE F_l1p0+3:  //b = a; a = W[Wp[ 3]+1]; goto fetch;
                  gen1(I_atb)
                  gen3(I_lkp, 1, f-F_l1p0)
                  gen2(I_j, pc)
                  LOOP

    CASE F_l2p0+5:  //b = a; a = W[Wp[ 5]+2]; goto fetch;
    CASE F_l2p0+4:  //b = a; a = W[Wp[ 4]+2]; goto fetch;
    CASE F_l2p0+3:  //b = a; a = W[Wp[ 3]+2]; goto fetch;
                  gen1(I_atb)
                  gen3(I_lkp, 2, f-F_l2p0)
                  gen2(I_j, pc)
                  LOOP

    CASE F_l3p0+4:  //b = a; a = W[Wp[ 4]+3]; goto fetch;
    CASE F_l3p0+3:  //b = a; a = W[Wp[ 3]+3]; goto fetch;
                  gen1(I_atb)
                  gen3(I_lkp, 3, f-F_l3p0)
                  gen2(I_j, pc)
                  LOOP

    CASE F_l4p0+4:  //b = a; a = W[Wp[ 4]+4]; goto fetch;
    CASE F_l4p0+3:  //b = a; a = W[Wp[ 3]+4]; goto fetch;
                  gen1(I_atb)
                  gen3(I_lkp, 4, f-F_l4p0)
                  gen2(I_j, pc)
                  LOOP

    CASE F_l0gh:  //b = a; a = W[Wg[GH(pc)]+0]; pc += 2; goto fetch;
    CASE F_l1gh:  //b = a; a = W[Wg[GH(pc)]+1]; pc += 2; goto fetch;
    CASE F_l2gh:  //b = a; a = W[Wg[GH(pc)]+2]; pc += 2; goto fetch;
                  gen1(I_atb)
                  gen3(I_lkg, f-F_l0gh, gh(pc))
                  pc := pc+2
                  gen2(I_j, pc)
                  LOOP

    CASE F_l0g1:  //b = a; a = W[Wg1[B[pc++]]+0];        goto fetch;
    CASE F_l1g1:  //b = a; a = W[Wg1[B[pc++]]+1];        goto fetch;
    CASE F_l2g1:  //b = a; a = W[Wg1[B[pc++]]+2];        goto fetch;
                  gen1(I_atb)
                  gen3(I_lkg, f-F_l0g1, gb(pc)+256)
                  pc := pc+1
                  gen2(I_j, pc)
                  LOOP

    CASE F_l0g:   //b = a; a = W[Wg[B[pc++]]+0];         goto fetch;
    CASE F_l1g:   //b = a; a = W[Wg[B[pc++]]+1];         goto fetch;
    CASE F_l2g:   //b = a; a = W[Wg[B[pc++]]+2];         goto fetch;
                  gen1(I_atb)
                  gen3(I_lkg, f-F_l0g, gb(pc))
                  pc := pc+1
                  gen2(I_j, pc)
                  LOOP

    CASE F_s0gh:  //W[Wg[GH(pc)]+0] = a;        pc += 2; goto fetch;
                  gen3(I_stkg, 0, gh(pc))
                  pc := pc+2
                  gen2(I_j, pc)
                  LOOP

    CASE F_s0g1:  //W[Wg1[B[pc++]]+0] = a;               goto fetch;
                  gen3(I_stkg, 0, gb(pc)+256)
                  pc := pc+1
                  gen2(I_j, pc)
                  LOOP

    CASE F_s0g:   //W[Wg[B[pc++]]+0] = a;                goto fetch;
                  gen3(I_stkg, 0, gb(pc))
                  pc := pc+1
                  gen2(I_j, pc)
                  LOOP

    CASE F_stp0+5: //W[a+Wp[5]] = b; goto fetch;
    CASE F_stp0+4: //W[a+Wp[4]] = b; goto fetch;
    CASE F_stp0+3: //W[a+Wp[3]] = b; goto fetch;
                  gen2(I_stap, f-F_stp0)
                  gen2(I_j, pc)
                  LOOP

    CASE F_st0p0+4: //W[Wp[4]+0] = a; goto fetch;
    CASE F_st0p0+3: //W[Wp[3]+0] = a; goto fetch;
                  gen3(I_stkp, 0, f-F_st0p0)
                  gen2(I_j, pc)
                  LOOP

    CASE F_st1p0+4: //W[Wp[4]+1] = a; goto fetch;
    CASE F_st1p0+3: //W[Wp[3]+1] = a; goto fetch;
                  gen3(I_stkp, 1, f-F_st1p0)
                  gen2(I_j, pc)
                  LOOP
   
    CASE F_rvp0+7: //a = W[a+Wp[7]]; goto fetch;
    CASE F_rvp0+6: //a = W[a+Wp[6]]; goto fetch;
    CASE F_rvp0+5: //a = W[a+Wp[5]]; goto fetch;
    CASE F_rvp0+4: //a = W[a+Wp[4]]; goto fetch;
    CASE F_rvp0+3: //a = W[a+Wp[3]]; goto fetch;
                  gen2(I_lap, f-F_rvp0)
                  gen2(I_j, pc)
                  LOOP
  }
} REPEAT

AND gen1(x) BE
{ !codep := x
  codep := codep+1
  IF codep>codet DO
  { writef("codev not large enough*n")
    abort(999)
  }
}

AND gen2(x, y) BE { gen1(x); gen1(y) }

AND gen3(x, y, z) BE { gen1(x); gen1(y); gen1(z) }

AND relcondjump(f, pc) = VALOF
{ LET dest = reladdr(pc)
  gen2(f, dest)
  pc := pc+1
  gen2(I_j, pc)
  scan(dest)
  RESULTIS pc
}

AND indcondjump(f, pc) = VALOF
{ LET dest = indaddr(pc)
  gen2(f, dest)
  pc := pc+1
  gen2(I_j, pc)
  scan(dest)
  RESULTIS pc
}

AND reladdr(pc) = pc + gsb(pc)

AND indaddr(pc) = VALOF
{ LET a = ((pc>>1) + gb(pc)) << 1
//  writef("pc:%n gb(pc):%n a:%n  gsh(a):%n*n",
//          pc,   gb(pc),   a,    gsh(a))
  RESULTIS a + gsh(a)
} 

AND interpret(pc) = VALOF
{ LET a, b, c, n = r_a, r_b, r_c, ?
  LET p, g = r_p, r_g
  LET ipc = proglink!pc
  LET op = ?
  IF tracing DO prinstr(pc)
  UNLESS ipc DO
  { writef("Error: ipc=0*n")
    pc := 0
    GOTO ret
  }
//abort(1000)

fetch:
  op := !ipc
  IF tracing DO
  { writef("a:%i6  b:%i6  c:%i6  p:%i6", a, b, c, p)
    writef("  ipc=%i6: %t5 %n*n", ipc, ifstr(op), ipc!1)
  }
  ipc := ipc+1
  SWITCHON op INTO
  { DEFAULT:   writef("Bad code: %n*n", op)
               abort(999)
               GOTO fetch

    CASE I_end: // Marks the end of a fragment of code
                writef("I_end:*n")
                abort(9999)
                GOTO ret

    CASE I_k:   // call function in a, first arg in b
//writef("I_k: n:%n  p:%n l:%n f:%n*n", !ipc, p, ipc!1, a)
                n := !ipc
                p!n, p!(n+1), p!(n+2) := p, ipc!1, a
                pc, p := a, p+n
                a, p!3 := b, b
//abort(1000)
                GOTO ret
                
    CASE I_rtn: // return from a function
                pc := p!1
                p  := !p
                GOTO ret

    CASE I_ln:  // a := n
                a := !ipc; ipc := ipc+1;           GOTO fetch
    CASE I_lp:  // a := p!n
                n := !ipc; a := p!n; ipc := ipc+1; GOTO fetch
    CASE I_lg:  // a := g!n
                n := !ipc; a := g!n; ipc := ipc+1; GOTO fetch
    CASE I_ll:  // a := value of static variable at n
                n := !ipc; a :=  progv!(n>>2); ipc := ipc+1; GOTO fetch
    CASE I_llp: // a := @ p!n
                n := !ipc; a := @p!n; ipc := ipc+1; GOTO fetch
    CASE I_llg: // a := @ g!n
                n := !ipc; a := @g!n; ipc := ipc+1; GOTO fetch
    CASE I_lll: // a := @ value of static variable at n
                n := !ipc; a := progv+(n>>2); ipc := ipc+1; GOTO fetch
    CASE I_lf:  // a := entry address n
                n := !ipc; a := n; ipc := ipc+1;   GOTO fetch

    CASE I_sp:  // p!n := a
                n := !ipc; p!n := a; ipc := ipc+1; GOTO fetch
    CASE I_sg:  // g!n := a
                n := !ipc; g!n := a; ipc := ipc+1; GOTO fetch
    CASE I_sl:  // assign a to static variable at n
                n := !ipc; progv!(n>>2) := a; ipc := ipc+1; GOTO fetch

    CASE I_st:  a!(ipc!0) := b; ipc := ipc+1;     GOTO fetch

    CASE I_mul: a := b * a;                       GOTO fetch
    CASE I_div: a := b / a;                       GOTO fetch
    CASE I_rem: a := b REM a;                     GOTO fetch
    CASE I_add: a := b + a;                       GOTO fetch
    CASE I_a:   // a := a + n
                n := !ipc; a := a+n; ipc := ipc+1; GOTO fetch

    CASE I_ap:  // a := a + p!n
                n := !ipc; a := a+p!n; ipc := ipc+1; GOTO fetch
    CASE I_ag:  // a := a + g!n
                n := !ipc; a := a+g!n; ipc := ipc+1; GOTO fetch

    CASE I_sub: a := b - a;                       GOTO fetch
    CASE I_lsh: a := b << a;                      GOTO fetch
    CASE I_rsh: a := b >> a;                      GOTO fetch
    CASE I_and: a := b & a;                       GOTO fetch
    CASE I_or:  a := b | a;                       GOTO fetch
    CASE I_xor: a := b NEQV a;                    GOTO fetch
    CASE I_neg: a := -a;                          GOTO fetch
    CASE I_not: a := ~a;                          GOTO fetch

    CASE I_rv:  a := a!(ipc!0); ipc := ipc+1;     GOTO fetch

    CASE I_lap:       // a := p!n!a
                a := p!(ipc!0)!a; ipc := ipc+1;       GOTO fetch
    CASE I_lkp:       // a := p!n!k
                a := p!(ipc!1)!(ipc!0); ipc := ipc+2; GOTO fetch
    CASE I_stap:      // p!n!a := b
                p!(ipc!0)!a := b; ipc := ipc+1;       GOTO fetch
    CASE I_stkp:      // p!n!k := a
                p!(ipc!1)!(ipc!0) := a; ipc := ipc+2; GOTO fetch

    CASE I_lkg:       // a := g!n!k
                a := g!(ipc!1)!(ipc!0); ipc := ipc+2; GOTO fetch
    CASE I_stkg:      // g!n!k := a
                g!(ipc!1)!(ipc!0) := a; ipc := ipc+2; GOTO fetch

    CASE I_swb:       // binary chop switch on a
             { LET n = !ipc
               LET i, val = 1, ?
               WHILE i <= n DO
               { i := i<<1
                 val := ipc!i
                 IF a=val DO { pc := ipc!(i+1); GOTO ret }
                 IF a<val DO i := i+1
               }
               pc := ipc!1
               GOTO ret
             }
    CASE I_swl:       // label vector switch on a
               IF 0 <= a < !ipc DO { pc := ipc!(a+2); GOTO ret }
               pc := ipc!1
               GOTO ret

    CASE I_xch: // exchange a and b
                n := a; a := b; b := n;            GOTO fetch
    CASE I_gbyt: a := b%a;                         GOTO fetch
    CASE I_pbyt: b%a := c;                         GOTO fetch
    CASE I_xpbyt:a%b := c;                         GOTO fetch
    CASE I_atc:  c := a;                           GOTO fetch
    CASE I_atb:  b := a;                           GOTO fetch
    CASE I_btc:  c := b;                           GOTO fetch

    CASE I_sys: // a := sys(p!3, p!4, p!5, p!6)
                IF a=2 DO { tracing := TRUE;      GOTO fetch }
                IF a=3 DO { tracing := FALSE;     GOTO fetch }
                a := sys(p!3, p!4, p!5, p!6);     GOTO fetch

    CASE I_mdiv:// a := muldiv(p!3, p!4, p!5); RETURN
                a := muldiv(p!3, p!4, p!5)
                pc := p!1
                p := !p
                GOTO ret

    CASE I_chgco:// a := changeco(p!3, p!4); RETURN
                GOTO bad

    CASE I_goto:// pc := a
                pc := a
                GOTO ret

    CASE I_j:   // j
                pc := !ipc
                GOTO ret

    CASE I_jeq:  pc := b = a -> !ipc, pc+2; GOTO ret 
    CASE I_jeq0: pc := a = 0 -> !ipc, pc+2; GOTO ret 
    CASE I_jne:  pc := b ~=a -> !ipc, pc+2; GOTO ret 
    CASE I_jne0: pc := a ~=0 -> !ipc, pc+2; GOTO ret 
    CASE I_jls:  pc := b < a -> !ipc, pc+2; GOTO ret 
    CASE I_jls0: pc := a < 0 -> !ipc, pc+2; GOTO ret 
    CASE I_jgr:  pc := b > a -> !ipc, pc+2; GOTO ret 
    CASE I_jgr0: pc := a > 0 -> !ipc, pc+2; GOTO ret 
    CASE I_jle:  pc := b <=a -> !ipc, pc+2; GOTO ret 
    CASE I_jle0: pc := a <=0 -> !ipc, pc+2; GOTO ret 
    CASE I_jge:  pc := b >=a -> !ipc, pc+2; GOTO ret 
    CASE I_jge0: pc := a >=0 -> !ipc, pc+2; GOTO ret 
bad:
                 writef("code not implemented*n")
                 abort(999)
                 RESULTIS 0
  }
  
ret:
  r_a, r_b, r_c := a, b, c
  r_p, r_g := p, g
  r_pc := pc
  RESULTIS pc
}

AND ifstr(f) = VALOF SWITCHON f INTO
  { DEFAULT:   RESULTIS "Unknown"

    CASE I_end:  RESULTIS "end"
    CASE I_k:    RESULTIS "k"
    CASE I_rtn:  RESULTIS "rtn"
    CASE I_ln:   RESULTIS "ln"
    CASE I_lp:   RESULTIS "lp"
    CASE I_lg:   RESULTIS "lg"
    CASE I_ll:   RESULTIS "ll"
    CASE I_llp:  RESULTIS "llp"
    CASE I_llg:  RESULTIS "llg"
    CASE I_lll:  RESULTIS "lll"
    CASE I_lf:   RESULTIS "lf"
    CASE I_sp:   RESULTIS "sp"
    CASE I_sg:   RESULTIS "sg"
    CASE I_sl:   RESULTIS "sl"
    CASE I_st:   RESULTIS "st"
    CASE I_mul:  RESULTIS "mul"
    CASE I_div:  RESULTIS "div"
    CASE I_rem:  RESULTIS "rem"
    CASE I_add:  RESULTIS "add"
    CASE I_a:    RESULTIS "a"
    CASE I_ap:   RESULTIS "ap"
    CASE I_ag:   RESULTIS "ag"
    CASE I_sub:  RESULTIS "sub"
    CASE I_lsh:  RESULTIS "lsh"
    CASE I_rsh:  RESULTIS "rsh"
    CASE I_and:  RESULTIS "and"
    CASE I_or:   RESULTIS "or"
    CASE I_xor:  RESULTIS "xor"
    CASE I_neg:  RESULTIS "neg"
    CASE I_not:  RESULTIS "not"
    CASE I_rv:   RESULTIS "rv"
    CASE I_lap:  RESULTIS "lap"
    CASE I_lkp:  RESULTIS "lkp"
    CASE I_stap: RESULTIS "stap"
    CASE I_stkp: RESULTIS "stkp"
    CASE I_lkg:  RESULTIS "lkg"
    CASE I_stkg: RESULTIS "stkg"
    CASE I_swb:  RESULTIS "swb"
    CASE I_swl:  RESULTIS "swl"
    CASE I_xch:  RESULTIS "xch"
    CASE I_gbyt: RESULTIS "gbyt"
    CASE I_pbyt: RESULTIS "pbyt"
    CASE I_xpbyt:RESULTIS "xpbyt"
    CASE I_atc:  RESULTIS "atc"
    CASE I_atb:  RESULTIS "atb"
    CASE I_btc:  RESULTIS "btc"
    CASE I_sys:  RESULTIS "sys"
    CASE I_mdiv: RESULTIS "mdiv"
    CASE I_chgco:RESULTIS "chgco"
    CASE I_goto: RESULTIS "goto"
    CASE I_j:    RESULTIS "j"
    CASE I_jeq:  RESULTIS "jeq"
    CASE I_jeq0: RESULTIS "jeq0"
    CASE I_jne:  RESULTIS "jne"
    CASE I_jne0: RESULTIS "jne0"
    CASE I_jls:  RESULTIS "jls"
    CASE I_jls0: RESULTIS "jls0"
    CASE I_jgr:  RESULTIS "jgr"
    CASE I_jgr0: RESULTIS "jgr0"
    CASE I_jle:  RESULTIS "jle"
    CASE I_jle0: RESULTIS "jle0"
    CASE I_jge:  RESULTIS "jge"
    CASE I_jge0: RESULTIS "jge0"
  }



