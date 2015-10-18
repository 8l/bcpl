// This is a simulator of 1949 version of the Edsac computer
// implemented in BCPL by Martin Richards (c) May 2005

// Usage:  edsac  or natedsac     (there are no arguments)

// The simulator executes the 1949 version of the Edsac istruction set,
// and used the preload initial orders version 1 implemented by
// David Wheeler. The Squares program (squares.txt) was written by
// Maurice Wilkes and first ran in June 1949.

SECTION "edsac" 
GET "libhdr"


//Memory:

// 512 35-bit words with even addresses, split into two 17-bit halves
// with one seperator bit.

//         | 17 bits | 1 bit gap | 17 bits |
//            2n+1                   2n          S access, 17 bits
//                      2n                       L access, 35 bits

// Implemented here by the vector mem!0 .. mem!1023. The even elements
// holding 18 bits and the odd ones 17 bits.

// The sequence control register (scr) holds the 10-bit address of
// the next instruction to be obeyed.

// The next instruction is loaded into the instruction regiger (instr)
// and is 17 bits long, consisting of a 5-bit operation code, an unused
// bit, 10 bits of address and one bit indicating the size of the
// operand, if any.

//         | 5 bits | 1 bit | 10 bits | 1 bit |
//          op code  unused   address   size

// There is a 71-bit accumulator, held, in this implementatation, in
// five variables a0, a1, a2, a3 and a4, each holding 15 bits except
// a4 that holds 11 bits. he least significant 4 bits of a4 are zero.

// There is a 35 bit multiplier register, held in this implementation,
// in the variables h0, h1 and h2. They have the same alignment as the
// accumulator variables, h0 and h1 both hold 15 bits and h2 holds 6 bits.
// The least significant 9 bits of h2 are zero.

// There is 35 bit working register held in the variable w0, w1 and w2,
// with the same alignment as h0, h1 and h2.

// The accumulator, multiplier and operand registers are normally
// thought of as signed twos complement binary fractions.

GLOBAL {
 mem:ug     // 1024 18-bit locations of memory
            // Odd locations have 17 bits and even have 18 bits.
 h0; h1; h2 // 15-, 15- and 5-bits of the multiplier register
 r0; r1; r2 // 15-, 15- and 5-bits of the operand register
 rsize      // Size of r -- ='S' or 'L'
 a0; a1; a2 // 71-bit accumulator left justified in five 15-bit
 a3; a4     // fields (the last hold 11 bits).

 scr        // The 10-bit address of the current instruction

 tape       // Edsac paper tape input stream

 figshift   // Current character shift for Edsac output
            // TRUE = figure shift, False = letter shift

 // Debugger variables
 ch
 name       // Name of paper tape reader file
 mflags      // 1024 words of debugging flag bits 

 rflags     // Register flags
 code       // Interpreter return code
            // = 0     Normal termination (executing ZS instruction)
 singlestep

 style      // Default printing style, b, d, f or i.
 size       // Default printing size,  S, L or F

 vsize      // Size of current value
            // S = 17 bits, L = 35 bits and F = 71 bits

 wsize      // Size of work value
            // S = 17 bits, L = 35 bits and F = 71 bits

 v0; v1; v2 // 71-bit current value left justified in five 15-bit
 v3; v4     // fields (the last hold 11 bits).
            // Short (S) values occupy the senior 17 bits
            // Long  (L) values occupy the senior 35 bits
            // Full length (F) values occupy 71 bits.
 w0; w1; w2 // 71-bit work value left justified in five 15-bit
 w3; w4     // fields (the last hold 11 bits).
 x0; x1; x2 // 71-bit extra value left justified in five 15-bit
 x3; x4     // fields (the last hold 11 bits).

 recp; recl // Recovery label
}

MANIFEST {
  // rflag bits
  rf_scr   = 1<< 0

  rf_rb    = 1<< 1
  rf_rd    = 1<< 2
  rf_rf    = 1<< 3

  rf_hsb   = 1<< 5
  rf_hsd   = 1<< 6
  rf_hsf   = 1<< 7
  rf_hsi   = 1<< 8

  rf_hlb   = 1<< 9
  rf_hld   = 1<<10
  rf_hlf   = 1<<11

  rf_asb   = 1<<12
  rf_asd   = 1<<13
  rf_asf   = 1<<14
  rf_asi   = 1<<15

  rf_alb   = 1<<16
  rf_ald   = 1<<17
  rf_alf   = 1<<18

  rf_afb   = 1<<19
  rf_afd   = 1<<20
  rf_aff   = 1<<21

  // mflag bits
  mf_break = 1<< 0

  mf_sb    = 1<< 1
  mf_sd    = 1<< 2
  mf_sf    = 1<< 3
  mf_si    = 1<< 4

  mf_lb    = 1<< 5
  mf_ld    = 1<< 6
  mf_lf    = 1<< 7
}

LET start() = VALOF
{ LET argv = VEC 30
  LET namev = VEC 64/bytesperword
  LET squares = "squares.txt"

  figshift := TRUE

  name := namev

  UNLESS rdargs("prog", argv, 30) DO
  { writef("Bad arguments for EDSAC*n")
    RESULTIS 0
  }

  // Set the default program name to squares.txt
  FOR i = 0 TO squares%0 DO name%i := squares%i
  IF argv!0 FOR i = 0 TO (argv!0)%0 DO name%i := (argv!0)%i

  writef("Paper tape: %s*n", name)
  tape := findinput(name)
  UNLESS tape DO writef("Paper tape %s not found*n", name)
  IF tape DO selectinput(tape)

  mem    := getvec(1023)
  mflags := getvec(1023)
  rflags := rf_scr | rf_rb | rf_hlb | rf_afb
  singlestep := FALSE

  sawritef("*nEDSAC Simulator -- Type ? for help*n*n")

  shell()

  newline()

  freevec(mem)
  freevec(mflags)

  IF tape DO endstream(tape)
  RESULTIS 0
}

AND shell() BE
{ v0, v1, v2, v3, v4, vsize := 0, 0, 0, 0, 0, 'S'
  w0, w1, w2, w3, w4, wsize := 0, 0, 0, 0, 0, 'S'

  // Initialise machine registers and memory
  a0, a1, a2, a3, a4 := 0, 0, 0, 0, 0
  h0, h1, h2 := 0, 0, 0
  r0, r1, r2 := 0, 0, 0
  scr := 0

  style := 'B'
  size  := 'S'

  FOR i = 0 TO 1023 DO mem!i, mflags!i := 0, 0

  recp, recl := level(), rec

rec:
  ch := '*n' // To cause an initial prompt

  { // Main debug loop
    LET op = ?

    IF ch='*n' DO sawritef("# ")  // The prompt

nxt:
    ch := sardch()
sw: op := capitalch(ch)
sawritef("Command letter: %c*n", ch)
    SWITCHON op INTO
    { DEFAULT:    error("Unknown command")

      CASE '*n': LOOP

      CASE ' ': GOTO nxt

      CASE '?':
        sawritef("*n*n")
        sawritef("?             Print list of debug commands*n")

        sawritef("123  .125  #1011  #.1011  'c  17-bit constants*n")
        sawritef("123S .125S #1011S #.1011S     17-bit constants*n")
        sawritef("123L .125L #1011L #.1011L     35-bit constants*n")
        sawritef("123F .125F #1011F #.1011F     71-bit constants*n")

        sawritef("**k +k -k      Multipy/Add/Subtract constant k*n")
        sawritef("/ ^           Divide/multiply the current value by 10*n")
        sawritef("~             Negate the current value*n")
        sawritef("< >           Shift the current value left/right one place*n")

        sawritef("$<s>          Set the default printing style to <s>*n")
        sawritef("                <s> = b   binary integer*n")
        sawritef("                <s> = d   decimal integer*n")
        sawritef("                <s> = f   decimal fraction*n")
        sawritef("                <s> = i   instruction*n")
        sawritef("=             Print the current value in current style*n")

        sawritef("LS LL LF      Change the length of the current value*n")

        sawritef("A H P         Get value from Acc, H or SCR*n")
        sawritef("Ma MSa MLa    Get a 17 or 35 bit value from memory*n")
        sawritef("SA SH         Store the current value in Acc or H*n")
        sawritef("Ja            Jump to a, ie set SCR to a*n")
        sawritef("Sa            Store the current value in memory address a*n")
        sawritef("Ia            Assemble instructions in location a, a+1,..*n")

        sawritef("Tn<s> TSn<s>  Print n consecutive 17-bit locations, *
                 *style <s>*n")
        sawritef("TLn<s>        Print n consecutive 35-bit words, style <s>*n")

        sawritef("F<name>       Set the paper tape filename*n")
        sawritef("Q             Quit*n")
        sawritef("R             Load initial orders *
                 *and clear registers SCR, H and Acc*n")
        sawritef("Z             Set all 1024 memory locations to zero*n")

        sawritef("DP            Toggle dump of SCR and the next order*n")
        sawritef("DR<s>         Toggle dump of the operand, style <s>*n")
        sawritef("DSH<s> DLH<s> Toggle dump of H, style <s>*n")
        sawritef("DSA<s> DLA<s> DFA<s> Toggle dump of Acc, style <s>*n")
        sawritef("DSa<s>        Toggle dump of 17-bit memory location, *
                 *style <s>*n")
        sawritef("DLa<s>        Toggle dump of 35-bit memory word, style <s>*n")
        sawritef(";             Print requested values*n")

        sawritef("B  Ba  Ua     List, set or unset breakpoints*n")
        sawritef("C             Continue normal execution*n")
        sawritef("\             Execute one instruction*n")
        ch := '*n'
        LOOP

      CASE '#': // Binary integer or fraction
      CASE '.': // Decimal fraction
      CASE '0':CASE '1':CASE '2':CASE '3':CASE '4':
      CASE '5':CASE '6':CASE '7':CASE '8':CASE '9':
        getnum()
        w2v()
        GOTO sw

      CASE '$':
        style := capitalch(sardch())
        UNLESS style='B' | style='D' | style='F' | style='I' DO
          error("B, D, F or I expected")
        LOOP

      CASE 'L': // LS  LL  LF
        ch := capitalch(sardch())
        UNLESS ch='S' | ch='L' | ch='F' DO error("S, L or F expected")
        vsize := ch
        LOOP

      CASE 'I': // Assemble instructions
        ch := sardch()
        FOR a = getint() TO 1023 DO
        { LET instr, addr, len = 0, 0, 0
          sawritef("%i4> ", a)

          ch := capitalch(sardch()) REPEATWHILE ch=' '
          IF ch='*n' | ch=endstreamch BREAK
          op := asc2ed(ch)
          IF op<0 BREAK

          instr := op<<12
          // Read address field
          { ch := capitalch(sardch())
            UNLESS '0'<=ch<='9' BREAK
            addr := 10*addr + ch - '0'
          } REPEAT

          instr := instr | (addr&2047)<<1

          IF ch='L' DO instr := instr+1
          UNLESS ch='S' | ch='L' BREAK
          mem!a := instr
          sawritef("*n%i4: ", a)
          printinstr(instr)
          sawrch('*n')          
        }
        ch := '*n'
        LOOP

      CASE ';': // Print requested values
        sawrch('*n')          
        dump()
        ch := '*n'
        LOOP

      CASE 'T': // Tn  TnB  TnD  TnF  TnI
                // TSn TSnB TSnD TSnF TSnI
                // TLn TLnB TLnD TSnF
      { LET size, st = 'S', style
        LET st = style     // The current style
        LET addr = v2n()
        LET n = 0
        ch := capitalch(sardch())
        IF ch='S' | ch='L' DO
        { size := ch
          ch := capitalch(sardch())
        }

        n := getint()
        ch := capitalch(ch)
        IF ch='B' | ch='D' | ch='F' | ch='I' DO
          st := ch // Override the current style

        IF n<=0 DO n := 1
        UNLESS ch='*n' DO sawritef("*n")

        TEST size='L'
        THEN { addr := addr & -2 // Round down to even address
               FOR i = 0 TO n-1 DO
               { sawritef("%i4: ", addr+2*i)
                 ldwl(addr+2*i)
                 printw(st)
                 sawritef("*n")
               }
             }
        ELSE { FOR i = 0 TO n-1 DO
               { sawritef("%i4: ", addr+i)
                 ldws(addr+i)
//sawritef("*nw0=%bF w1=%bF*n", w0, w1); abort(1000)
                 printw(st)
                 sawritef("*n")
               }
             }
        }
        ch := '*n'
        LOOP


      CASE 'A': // A
        a2v()
        ch := ' '
        LOOP

      CASE 'H': // H
        v0, v1, v2, v3, v4, vsize := h0, h1, h2, 0, 0, 'L'
        ch := ' '
        LOOP

      CASE 'P': // P
        v0, v1, v2, v3, v4, vsize := scr>>2, scr<<13 & #x6000, 0, 0, 0, 'S'
        ch := ' '
        LOOP

      CASE 'S': // SA  SH
                // Sa
      
      { LET addr = 0
        ch := capitalch(sardch())
        SWITCHON ch INTO
        { DEFAULT:   ENDCASE
          CASE 'A': v2a()
                    sawrch('*n')
                    ch := '*n'
                    LOOP

          CASE 'H': v2h()
                    sawrch('*n')
                    ch := '*n'
                    LOOP
        }

        addr := getint()
        SWITCHON vsize INTO
        { DEFAULT:  error("Cannot store a 71 bit value in memory")
          CASE 'S': stvs(addr); ENDCASE
          CASE 'L': stvl(addr); ENDCASE
        }
        sawrch('*n')
        ch := '*n'
        LOOP
      }

      CASE 'J': // Ja
        ch := capitalch(sardch())
        scr := getint() & 1023
        GOTO sw

      CASE 'M': // Ma  MSa  MLa
      ch := capitalch(sardch())

      { LET size = ch

        SWITCHON size INTO
        { DEFAULT:  ldvs(getint() & 1023); GOTO sw
          CASE 'S': ch := capitalch(sardch())
                    ldvs(getint() & 1023); GOTO sw
          CASE 'L': ch := capitalch(sardch())
                    ldvl(getint() & 1023); GOTO sw
        }
      }

      CASE '**':   // v := v * w  as 71-bit fractions
                   // The length of v remains unchanged
      { LET neg = FALSE
        ch := capitalch(sardch())
        getnum()
        //IF (v0 & #x4000) ~= 0 DO { neg := ~neg; negv() }
        //IF (w0 & #x4000) ~= 0 DO { neg := ~neg; negw() }
        v2x()
        v0, v1, v2, v3, v4 := 0, 0, 0, 0, 0
        FOR i = 1 TO 71 DO
        { shrv(1)
          IF (w4&#x10)>0 DO addx2v()
          shrw(1)
        }
        //IF neg DO negv()
        GOTO sw
      }

      CASE '/':  // Divide by 10
        v2w()
        divwby10()
        w2v()
        LOOP

      CASE '^':  // Multiply by 10
        v2w()
        mulwby10()
        w2v()
        LOOP

      CASE '-':
      CASE '+':
        ch := sardch()
        getnum()
        IF op='-' DO negw()
        addw2v()
        GOTO sw

      CASE '~':
        v2w()
        negw()
        w2v()
        LOOP

      CASE '<':
        v2w()
        shlw(1)
        w2v()
        LOOP

      CASE '>':
        v2w()
        shrw(1)
        w2v()
        v4 := v4 & #x7FF0 // Truncate to 71 bits
        LOOP

      CASE '=':
        //sawritef("*n%bF %bF %bF %bF %bB %c*n", v0, v1, v2, v3, v4>>4, vsize)
        sawritef("*n")
        v2w()
        printw(style)
        sawritef("*n")
        ch := '*n'
        LOOP

      CASE 'Q':
        sawritef("*n"); RETURN

      CASE 'R':
        reset()
        sawritef("*nInitial orders loaded and registers cleared*n")
        ch := '*n'
        LOOP

      CASE 'Z':
        FOR i = 0 TO 1023 DO mem!i := 0
        sawritef("*nMemory cleared*n")
        ch := '*n'
        LOOP

      CASE 'B':
      { LET addr = ?
        ch := capitalch(sardch())
        UNLESS '0'<=ch<='9' DO
        { // List the breakpoints
          UNLESS ch='*n' DO sawrch('*n')

          sawritef("Breakpoints:*n")
          FOR a = 0 TO 1023 IF (mflags!a & mf_break) ~= 0 DO
          { sawritef("%i4: ", a)
            printinstr(mem!a)
            sawrch('*n')
          }
          sawritef("# %c", ch)
          GOTO sw
        }
        addr := getint()
        mflags!addr := mflags!addr | mf_break
        GOTO sw
      }

      CASE 'U':
      { LET addr = ?
        ch := capitalch(sardch())
        UNLESS '0'<=ch<='9' DO error("Number expected")
        addr := getint()
        mflags!addr := mflags!addr & ~mf_break
        LOOP
      }

      CASE 'F':
      { LET len = 0
        sawritef("*nFile name for Edsac paper tape reader: ")
        ch := sardch() REPEATWHILE ch=' '
        IF ch='*n' DO
        { sawritef("%s*n", name)
          LOOP
        }
        name%0 := len
        UNTIL ch='*n' | ch=endstreamch | len>64 DO
        { len := len+1
          name%len := ch
          ch := sardch()
        }
        name%0 := len
        IF len DO
        { IF tape DO endstream(tape)
          tape := findinput(name)
          UNLESS tape DO error("Trouble with file: %s*n", name)
          writef("*nPaper tape: %s*n", name)
          selectinput(tape)
        }
        ch := '*n'
        LOOP
      }

      CASE 'D': // Toggle dump requests
                // DP                      The sequence control register
                // DR<s>                   The operand of the current instuction
                // DSH<s> DLH<s>           The multiplier reister
                // DSA<s> DLA<s> DFA<s>    The accumulator
                // DSa<s> DLa<s>.          A memory 17 or 35 bit value
      { LET addr = -1 // >= 0 if Da<s> DSa<s> DLa<s>
        LET bit, zbits = 0, 0
        LET ch1 = 0         // value  P R H A or M
        LET ch2 = 0         // size   S or L
        LET ch3 = 0         // style  B D F or I

        ch := capitalch(sardch())

        SWITCHON ch INTO
        { DEFAULT:  ENDCASE

          CASE 'P': ch1 := ch
                    ch := capitalch(sardch())
                    GOTO lookup

          CASE 'R': ch1 := ch
                    ch := capitalch(sardch())
                    GOTO st


          CASE '0':CASE '1':CASE '2':CASE '3':CASE '4':
          CASE '5':CASE '6':CASE '7':CASE '8':CASE '9':
                    addr := getint() & 1023
                    ch1 := 'M'
                    ENDCASE
        }

        SWITCHON ch INTO   // The size
        { CASE 'S':
          CASE 'L':
          CASE 'F': ch2 := ch
                    ch := capitalch(sardch())
                    ENDCASE

          DEFAULT:  error("Size S, L or possibly F expected")
        }

        SWITCHON ch INTO
        { DEFAULT:  error("A, H or a digit expected")

          CASE '0':CASE '1':CASE '2':CASE '3':CASE '4':
          CASE '5':CASE '6':CASE '7':CASE '8':CASE '9':
                    // A request to dump a memory value
                    addr := getint() & 1023
                    ch1 := 'M'
                    ENDCASE

         CASE 'H':
         CASE 'A':  ch1 := ch
                    ch := capitalch(sardch())
                    ENDCASE
        }

st:
        SWITCHON ch INTO   // The style
        { CASE 'I':
          CASE 'F':
          CASE 'D':
          CASE 'B': ch3 := ch
                    ch := capitalch(sardch())
                    ENDCASE

          DEFAULT:  error("Style B, D, F or I expected")
        }


lookup:
        bit := VALOF SWITCHON ch1 | ch2<<8 | ch3<<16 INTO
               { DEFAULT:   error("Bad dump request")


                 CASE 'P':                     RESULTIS rf_scr // DP

                 CASE 'R' | 'B'<<16:           RESULTIS rf_rb  // DRB
                 CASE 'R' | 'D'<<16:           RESULTIS rf_rd  // DRD
                 CASE 'R' | 'F'<<16:           RESULTIS rf_rf  // DRF

                 CASE 'H' | 'S'<<8 | 'B'<<16:  RESULTIS rf_hsb // DSB
                 CASE 'H' | 'S'<<8 | 'D'<<16:  RESULTIS rf_hsd // DSD
                 CASE 'H' | 'S'<<8 | 'F'<<16:  RESULTIS rf_hsf // DSF
                 CASE 'H' | 'S'<<8 | 'I'<<16:  RESULTIS rf_hsi // DSI

                 CASE 'H' | 'L'<<8 | 'B'<<16:  RESULTIS rf_hlb // DLB
                 CASE 'H' | 'L'<<8 | 'D'<<16:  RESULTIS rf_hld // DLD
                 CASE 'H' | 'L'<<8 | 'F'<<16:  RESULTIS rf_hlf // DLF

                 CASE 'A' | 'S'<<8 | 'B'<<16:  RESULTIS rf_asb // DSAB
                 CASE 'A' | 'S'<<8 | 'D'<<16:  RESULTIS rf_asd // DSAD
                 CASE 'A' | 'S'<<8 | 'F'<<16:  RESULTIS rf_asf // DSAF
                 CASE 'A' | 'S'<<8 | 'I'<<16:  RESULTIS rf_asi // DSAI

                 CASE 'A' | 'L'<<8 | 'B'<<16:  RESULTIS rf_alb // DLAB
                 CASE 'A' | 'L'<<8 | 'D'<<16:  RESULTIS rf_ald // DLAD
                 CASE 'A' | 'L'<<8 | 'F'<<16:  RESULTIS rf_alf // DLAF

                 CASE 'A' | 'F'<<8 | 'B'<<16:  RESULTIS rf_afb // DFAB
                 CASE 'A' | 'F'<<8 | 'D'<<16:  RESULTIS rf_afd // DFAD
                 CASE 'A' | 'F'<<8 | 'F'<<16:  RESULTIS rf_aff // DFAF

                 CASE 'M' | 'S'<<8 | 'B'<<16:  RESULTIS mf_sb  // DSaB
                 CASE 'M' | 'S'<<8 | 'D'<<16:  RESULTIS mf_sd  // DSaD
                 CASE 'M' | 'S'<<8 | 'F'<<16:  RESULTIS mf_sf  // DSaF
                 CASE 'M' | 'S'<<8 | 'I'<<16:  RESULTIS mf_si  // DSaI

                 CASE 'M' | 'L'<<8 | 'B'<<16:  RESULTIS mf_lb  // DLaB
                 CASE 'M' | 'L'<<8 | 'D'<<16:  RESULTIS mf_ld  // DLaD
                 CASE 'M' | 'L'<<8 | 'F'<<16:  RESULTIS mf_lf  // DLaF
               }

        TEST addr>=0 THEN mflags!addr := mflags!addr XOR bit
                     ELSE rflags      := rflags      XOR bit

        sawrch('*n')
        //ch := '*n'
        GOTO sw
      }

      CASE '\':
        singlestep := TRUE

      CASE 'C':
        sawritef("*n")
        code := interpret()
        //sawritef("*ncode = %n*n", code)
        SWITCHON code INTO
        { DEFAULT:

          CASE 0:
            sawritef("*nSuccessful termination of the program*n")
            ch := '*n'
            LOOP

          CASE 1: // Single step return
            singlestep := FALSE
            ENDCASE

          CASE 2: // Breakpoint return
            sawritef("*nBreakpoint at %n*n", scr)
            ENDCASE

          CASE 3: // Unknown instruction
            sawritef("*nUnknown instruction:*n")
            printinstr(mem!scr)
            ENDCASE

        }

        dump()

        ch := '*n'
        LOOP
    }
  } REPEAT
}

AND dump() BE
{ LET instr = mem!scr
  LET addr  = instr>>1 & #x3FF

  TEST (instr&1)=0 THEN ldrs(addr)
                   ELSE ldrl(addr&#x3FE)

  IF (rflags & rf_scr) ~= 0 DO                          // DP
  { sawritef("*nSCR: %i3: ", scr)
    printinstr(instr)
    sawrch('*n')
  }

  IF (rflags & rf_rb) ~= 0 DO                           // DRB
  { w0, w1, w2, wsize := r0, r1, r2, rsize
    sawritef("  R: ")
    printw('B')
    sawritef("*n")
  }

  IF (rflags & rf_rd) ~= 0 DO                           // DRD
  { w0, w1, w2, wsize := r0, r1, r2, rsize
    sawritef("  R: ")
    printw('D')
    sawritef("*n")
  }

  IF (rflags & rf_rf) ~= 0 DO                           // DRF
  { w0, w1, w2, wsize := r0, r1, r2, rsize
    sawritef("  R: ")
    printw('F')
    sawritef("*n")
  }

  IF (rflags & rf_hsb) ~= 0 DO                          // HSB
  { w0, w1, w2, wsize := h0, h1, h2, 'S'
    sawritef("  H: ")
    printw('B')
    sawritef("*n")
  }

  IF (rflags & rf_hsd) ~= 0 DO                          // HSD
  { w0, w1, w2, wsize := h0, h1, h2, 'S'
    sawritef("  H: ")
    printw('D')
    sawritef("*n")
  }

  IF (rflags & rf_hsf) ~= 0 DO                          // HSF
  { w0, w1, w2, wsize := h0, h1, h2, 'S'
    sawritef("  H: ")
    printw('F')
    sawritef("*n")
  }

  IF (rflags & rf_hsi) ~= 0 DO                          // HSI
  { w0, w1, w2, wsize := h0, h1, h2, 'S'
    sawritef("  H: ")
    printw('I')
    sawritef("*n")
  }

  IF (rflags & rf_hlb) ~= 0 DO                          // HLB
  { w0, w1, w2, wsize := h0, h1, h2, 'L'
    sawritef("  H: ")
    printw('B')
    sawritef("*n")
  }

  IF (rflags & rf_hld) ~= 0 DO                          // HLD
  { w0, w1, w2, wsize := h0, h1, h2, 'L'
    sawritef("  H: ")
    printw('D')
    sawritef("*n")
  }

  IF (rflags & rf_hlf) ~= 0 DO                          // HLF
  { w0, w1, w2, wsize := h0, h1, h2, 'L'
    sawritef("  H: ")
    printw('F')
    sawritef("*n")
  }

  IF (rflags & rf_asb) ~= 0 DO                          // ASB
  { w0, w1, w2, w3, w4, wsize := a0, a1, a2, 0, 0, 'S'
    sawritef("  A: ")
    printw('B')
    sawritef("*n")
  }

  IF (rflags & rf_asd) ~= 0 DO                          // ASD
  { w0, w1, w2, w3, w4, wsize := a0, a1, a2, 0, 0, 'S'
    sawritef("  A: ")
    printw('D')
    sawritef("*n")
  }

  IF (rflags & rf_asf) ~= 0 DO                          // ASF
  { w0, w1, w2, w3, w4, wsize := a0, a1, a2, 0, 0, 'S'
    sawritef("  A: ")
    printw('F')
    sawritef("*n")
  }

  IF (rflags & rf_asi) ~= 0 DO                          // ASI
  { w0, w1, w2, w3, w4, wsize := a0, a1, a2, 0, 0, 'S'
    sawritef("  A: ")
    printw('I')
    sawritef("*n")
  }

  IF (rflags & rf_alb) ~= 0 DO                          // ALB
  { w0, w1, w2, w3, w4, wsize := a0, a1, a2, 0, 0, 'L'
    sawritef("  A: ")
    printw('B')
    sawritef("*n")
  }

  IF (rflags & rf_ald) ~= 0 DO                          // ALD
  { w0, w1, w2, w3, w4, wsize := a0, a1, a2, 0, 0, 'L'
    sawritef("  A: ")
    printw('D')
    sawritef("*n")
  }

  IF (rflags & rf_alf) ~= 0 DO                          // ALF
  { w0, w1, w2, w3, w4, wsize := a0, a1, a2, 0, 0, 'L'
    sawritef("  A: ")
    printw('F')
    sawritef("*n")
  }

  IF (rflags & rf_afb) ~= 0 DO                           // AFB
  { w0, w1, w2, w3, w4, wsize := a0, a1, a2, a3, a4, 'F'
    sawritef("  A: ")
    printw('B')
    sawritef("*n")
  }

  IF (rflags & rf_afd) ~= 0 DO                           // AFD
  { w0, w1, w2, w3, w4, wsize := a0, a1, a2, a3, a4, 'F'
    sawritef("  A: ")
    printw('D')
    sawritef("*n")
  }

  IF (rflags & rf_aff) ~= 0 DO                           // AFF
  { w0, w1, w2, w3, w4, wsize := a0, a1, a2, a3, a4, 'F'
    sawritef("  A: ")
    printw('F')
    sawritef("*n")
  }

  FOR addr = 0 TO 1023 DO
  { LET flags = mflags!addr
    IF (flags & -2) = 0 LOOP
    sawritef("%i4: ", addr)
    IF (flags & mf_sb) ~= 0 DO { sawritef(" "); ldws(addr); printw('B') } // SaB
    IF (flags & mf_sd) ~= 0 DO { sawritef(" "); ldws(addr); printw('D') } // SaD
    IF (flags & mf_sf) ~= 0 DO { sawritef(" "); ldws(addr); printw('F') } // SaF
    IF (flags & mf_si) ~= 0 DO { sawritef(" "); ldws(addr); printw('I') } // SaI

    IF (flags & mf_lb) ~= 0 DO { sawritef(" "); ldwl(addr); printw('B') } // LaB
    IF (flags & mf_ld) ~= 0 DO { sawritef(" "); ldwl(addr); printw('D') } // LaD
    IF (flags & mf_lf) ~= 0 DO { sawritef(" "); ldwl(addr); printw('F') } // LaF
    sawrch('*n')
  } 
}

AND v2n() = VALOF
{ v2w()
  IF wsize='S' DO shrw(54)
  IF wsize='L' DO shrw(36)
  RESULTIS w2<<26 | w3<<11 | w4>>4
}

AND a2v() BE v0,v1,v2,v3,v4, vsize := a0,a1,a2,a3,a4, 'F' 
AND v2a() BE a0,a1,a2,a3,a4 := v0,v1,v2,v3,v4
AND v2x() BE x0,x1,x2,x3,x4 := v0,v1,v2,v3,v4
AND v2h() BE TEST vsize='F'
             THEN error("Bad operand size")
             ELSE h0,h1,h2 := v0,v1,v2
AND v2w() BE w0,w1,w2,w3,w4,wsize := v0,v1,v2,v3,v4,vsize
AND w2v() BE v0,v1,v2,v3,v4,vsize := w0,w1,w2,w3,w4,wsize
AND w2x() BE x0,x1,x2,x3,x4       := w0,w1,w2,w3,w4
AND x2w() BE w0,w1,w2,w3,w4 := x0,x1,x2,x3,x4

AND ldws(a) BE
{ LET x = mem!a
  w0 := x>>2            // 15-bits
  w1 := x<<13 & #x6000  //  2-bits
  w2, w3, w4 := 0, 0, 0
  wsize := 'S'
}

AND ldwl(a) BE
{ LET x0 = mem!(a+1)                 // 17-bits
  LET x1 = mem!a                     // 18-bits

  w0 :=  x0>>2                       // 15-bits
  w1 := (x0<<13 | x1>>5) & #x7FFF    // 15-bits
  w2 :=  x1<<10 & #x7C00             //  5-bits
  w3, w4 := 0, 0
  wsize := 'L'
}

AND error(mess, a, b, c) BE
{ sawritef("*nError: %f*n", mess, a, b, c)
  longjump(recp, recl)
}

AND getint() = VALOF
{ LET res = 0

  UNLESS '0'<=ch<='9' DO error("Number expected")
  
  WHILE '0'<=ch<='9' DO
  { res := res*10 + ch - '0'
    ch := capitalch(sardch())
  }
  RESULTIS res
}

AND getnum() BE  // 123 12S 12L 12F
                 // .123 .123S .123L .123F
                 // #1011  #1011S #1011L #1011F
                 // #.110  #.110S #.110L #.110F
                 // Leave the value in w
{ LET frac = FALSE
  w0, w1, w2, w3, w4 := 0, 0, 0, 0, 0

  SWITCHON ch INTO
  { DEFAULT:  error("Bad number")

    CASE '0': CASE '1': CASE '2': CASE '3': CASE '4': 
    CASE '5': CASE '6': CASE '7': CASE '8': CASE '9': 
  
      WHILE '0'<=ch<='9' DO
      { mulwby10()
        adddig(ch-'0')
        //sawritef("*n%bF %bF %bF %bF %bB*n", w0, w1, w2, w3, w4>>4)
        ch := capitalch(sardch())
      }
      ENDCASE

    CASE '.': // Decimal fraction
    { x0, x1, x2, x3, x4 :=      0, 0, 0, 0, 0
      w0, w1, w2, w3, w4 := #x4000, 0, 0, 0, 0 // Unsigned 1.000000
      divwby10f() // Unsigned divide by 10

      ch := capitalch(sardch())


      WHILE '0'<=ch<='9' DO
      {
//sawrch('*n')
  //sawritef("x: %bF %bF %bF %bF %bF*n", x0, x1, x2, x3, x4)
  //sawritef("w: %bF %bF %bF %bF %bF*n", w0, w1, w2, w3, w4)
         FOR i = '0' TO ch-1 DO addw2x()
  //sawritef("*nch = %c*n", ch)
  //sawritef("x: %bF %bF %bF %bF %bF*n", x0, x1, x2, x3, x4)
        divwby10f()
  //sawritef("w: %bF %bF %bF %bF %bF*n", w0, w1, w2, w3, w4)
        ch := capitalch(sardch())
      }
      // Round up to 71 bits
      x2w()
      roundw()
  //sawritef("w: %bF %bF %bF %bF %bF result rounded*n", w0, w1, w2, w3, w4)
      frac := TRUE
      ENDCASE
    }

    CASE '#': // Binary integer or fraction
      x0, x1, x2, x3, x4 := 0, 0, 0, 0, 0
      w0, w1, w2, w3, w4 := 0, 0, 0, 0, 0
      ch := capitalch(sardch())
      TEST ch='.'
      THEN { // Binary fraction
             ch := capitalch(sardch())
             UNLESS '0'<=ch<='1' DO error("Bad binary fraction")
             w0 := #x2000

             WHILE '0'<=ch<='1' DO
             { IF ch='1' DO addw2x()
               shrw(1)
               ch := capitalch(sardch())
             }
             x2w()
             frac := TRUE
             ENDCASE
           }
      ELSE { // Binary integer
             UNLESS '0'<=ch<='1' DO error("Bad binary integer")
             w0, w1, w2, w3, w4 := 0, 0, 0, 0, 0

             WHILE '0'<=ch<='1' DO
             { shlw(1)
               IF ch='1' DO addtow(0, 0, 0, 0, #x10) // Add 1
               ch := capitalch(sardch())
             }
             ENDCASE
           }
  }

//sawritef("*nch=%c*n", ch)

  IF ch='F' DO
  { wsize := 'F'
    ch:=' '
    RETURN
  }
  IF ch='L' DO
  { UNLESS frac DO shlw(36)
    wsize := 'L'
    ch:=' '
    RETURN
  }

  IF ch='S' DO
  { UNLESS frac DO shlw(54)
    wsize := 'S'
    ch:=' '
    RETURN
  }

  UNLESS frac DO shlw(54)
  wsize := 'S'
}

AND addw2v() BE
{ v4 := v4 + w4
  v3 := v3 + w3 + (v4>>15)
  v2 := v2 + w2 + (v3>>15)
  v1 := v1 + w1 + (v2>>15)
  v0 := v0 + w0 + (v1>>15)
  v4 := v4 & #x7FFF
  v3 := v3 & #x7FFF
  v2 := v2 & #x7FFF
  v1 := v1 & #x7FFF
  v0 := v0 & #x7FFF
}

AND addw2x() BE
{ x4 := x4 + w4
  x3 := x3 + w3 + (x4>>15)
  x2 := x2 + w2 + (x3>>15)
  x1 := x1 + w1 + (x2>>15)
  x0 := x0 + w0 + (x1>>15)
  x4 := x4 & #x7FFF
  x3 := x3 & #x7FFF
  x2 := x2 & #x7FFF
  x1 := x1 & #x7FFF
  x0 := x0 & #x7FFF
}

AND addx2v() BE
{ v4 := v4 + x4
  v3 := v3 + x3 + (v4>>15)
  v2 := v2 + x2 + (v3>>15)
  v1 := v1 + x1 + (v2>>15)
  v0 := v0 + x0 + (v1>>15)
  v4 := v4 & #x7FFF
  v3 := v3 & #x7FFF
  v2 := v2 & #x7FFF
  v1 := v1 & #x7FFF
  v0 := v0 & #x7FFF
}

AND addx2w() BE
{ w4 := w4 + x4
  w3 := w3 + x3 + (w4>>15)
  w2 := w2 + x2 + (w3>>15)
  w1 := w1 + x1 + (w2>>15)
  w0 := w0 + x0 + (w1>>15)
  w4 := w4 & #x7FFF
  w3 := w3 & #x7FFF
  w2 := w2 & #x7FFF
  w1 := w1 & #x7FFF
  w0 := w0 & #x7FFF
}

AND addtow(b0, b1, b2, b3, b4) BE
{ w4 := w4 + b4
  w3 := w3 + b3 + (w4>>15)
  w2 := w2 + b2 + (w3>>15)
  w1 := w1 + b1 + (w2>>15)
  w0 := w0 + b0 + (w1>>15)
  w4 := w4 & #x7FFF
  w3 := w3 & #x7FFF
  w2 := w2 & #x7FFF
  w1 := w1 & #x7FFF
  w0 := w0 & #x7FFF
}

AND mulwby10() = VALOF
{ // Multiply by 10 and extract the integer part
  LET dig = ?
  w4 := w4*10
  w3 := w3*10 + (w4>>15)
  w2 := w2*10 + (w3>>15)
  w1 := w1*10 + (w2>>15)
  w0 := w0*10 + (w1>>15)
  w4 := w4 & #x7FFF
  w3 := w3 & #x7FFF
  w2 := w2 & #x7FFF
  w1 := w1 & #x7FFF
  dig := w0>>14      // Extract the integer part
  w0 := w0 & #x3FFF
  RESULTIS dig
}

AND divwby10f() BE
// Divide unsigned 75 bit fraction w by ten
{ LET dig = 0
  // Multiply by 0.000110011001100....... ie 1/10
  LET s0, s1, s2, s3, s4 = w0, w1, w2, w3, w4 // Save original w
  LET t0, t1, t2, t3, t4 = x0, x1, x2, x3, x4 // Save x
  x0, x1, x2, x3, x4 := 0, 0, 0, 0, 0 // To hold w/10
  //sawrch('*n')
  //sawritef("x: %bF %bF %bF %bF %bF*n", x0, x1, x2, x3, x4)
  //sawritef("w: %bF %bF %bF %bF %bF*n", w0, w1, w2, w3, w4)
  shrw(2)
  w0 := w0 & #x1FFF // Make it an unsigned right shift

  FOR i = 1 TO 18 DO
  { shrw(2)
    addw2x()
    shrw(1)
    addw2x()
    shrw(1)
    //sawrch('*n')
    //sawritef("x: %bF %bF %bF %bF %bF*n", x0, x1, x2, x3, x4)
    //sawritef("w: %bF %bF %bF %bF %bF*n", w0, w1, w2, w3, w4)
  }

  x2w()
//sawritef("w: %bF %bF %bF %bF %bF*n", w0, w1, w2, w3, w4)

  x0, x1, x2, x3, x4 := t0, t1, t2, t3, t4 // Restore x
}

AND divwby10() = VALOF
// Divide unsigned 71 bit integer w by ten and return the remainder, ie the
// least significant decimal digit.
{ LET dig = 0
  // Unsigned divide by 10 by multiplying by 0.000110011001100....... ie 1/10
  LET s0, s1, s2, s3, s4 = w0, w1, w2, w3, w4 // Save original w
  LET t0, t1, t2, t3, t4 = x0, x1, x2, x3, x4 // Save x
  x0, x1, x2, x3, x4 := 0, 0, 0, 0, 0 // To hold w/10
  //sawrch('*n')
  //sawritef("x: %bF %bF %bF %bF %bF*n", x0, x1, x2, x3, x4)
  //sawritef("w: %bF %bF %bF %bF %bF*n", w0, w1, w2, w3, w4)
  shrw(2)
  w0 := w0 & #x1FFF // Make it an unsigned right shift

  WHILE w0+w1+w2+w3+w4 DO // ie until w=0
  { shrw(2)
    addw2x()
    shrw(1)
    addw2x()
    shrw(1)
    //sawrch('*n')
    //sawritef("x: %bF %bF %bF %bF %bF*n", x0, x1, x2, x3, x4)
    //sawritef("w: %bF %bF %bF %bF %bF*n", w0, w1, w2, w3, w4)
  }

  x2w()
//sawritef("w: %bF %bF %bF %bF %bF*n", w0, w1, w2, w3, w4)
  w4 := w4 & #x7FF0 // Round down to 71 bits
//sawritef("w: %bF %bF %bF %bF %bF rounded*n", w0, w1, w2, w3, w4)
  w2x()

  // Calculate the remainder
  mulwby10()
//sawritef("s: %bF %bF %bF %bF %bF*n", s0, s1, s2, s3, s4)
//sawritef("-: %bF %bF %bF %bF %bF*n", w0, w1, w2, w3, w4)
  negw()
  addtow(s0, s1, s2, s3, s4)
//sawritef("=: %bF %bF %bF %bF %bF*n", w0, w1, w2, w3, w4)
  dig := w4>>4
//sawritef("dig = %n*n", dig)
//abort(1111)

  x2w()        // Recover w/10 from x

  WHILE dig>9 DO // Apply minor correction
  { addtow(0, 0, 0, 0, #x00010)
    dig := dig-10
//sawritef("correcting dig = %n*n", dig)
//sawritef("w: %bF %bF %bF %bF %bF*n", w0, w1, w2, w3, w4)
//abort(2222)
  }
  x0, x1, x2, x3, x4 := t0, t1, t2, t3, t4 // Restore x
  RESULTIS dig
}

AND roundw() BE
{ // Round to 71 bits
  //sawrch('*n')
  //sawritef("w: %bF %bF %bF %bF %bF*n", w0, w1, w2, w3, w4)
  addtow(0, 0, 0, 0, #x8)
  w4 := w4 & #x7FF0 // Truncate to 71 bits
  //sawritef("w: %bF %bF %bF %bF %bF rounded*n", w0, w1, w2, w3, w4)
}

AND shlw(n) BE WHILE n & 127 DO
{ w0 := #x7FFF & (w0<<1 | w1>>14)
  w1 := #x7FFF & (w1<<1 | w2>>14)
  w2 := #x7FFF & (w2<<1 | w3>>14)
  w3 := #x7FFF & (w3<<1 | w4>>14)
  w4 := #x7FFF & (w4<<1)
  n := n-1
}

AND shrv(n) BE WHILE n & 127 DO
{ v4 := v4>>1 | v3<<14
  v3 := v3>>1 | v2<<14
  v2 := v2>>1 | v1<<14
  v1 := v1>>1 | v0<<14
  v0 := v0>>1 | v0 & #x4000  // Duplicate the sign bit
  v4 := v4 & #x7FF0
  v3 := v3 & #x7FFF
  v2 := v2 & #x7FFF
  v1 := v1 & #x7FFF
  n := n-1
}

AND shrw(n) BE WHILE n & 127 DO
{ w4 := w4>>1 | w3<<14
  w3 := w3>>1 | w2<<14
  w2 := w2>>1 | w1<<14
  w1 := w1>>1 | w0<<14
  w0 := w0>>1 | w0 & #x4000  // Duplicate the sign bit
  w4 := w4 & #x7FFF
  w3 := w3 & #x7FFF
  w2 := w2 & #x7FFF
  w1 := w1 & #x7FFF
  n := n-1
}

AND negw() BE
  { // negate a
    TEST w4
    THEN w4, w3, w2, w1, w0 := -w4, ~w3, ~w2, ~w1, ~w0
    ELSE TEST w3
         THEN w3, w2, w1, w0 := -w3, ~w2, ~w1, ~w0
         ELSE TEST w2
              THEN w2, w1, w0 := -w2, ~w1, ~w0
              ELSE TEST w1
                   THEN w1, w0 := -w1, ~w0
                   ELSE w0 := -w0
   
    w4 := w4 & #x7FFF
    w3 := w3 & #x7FFF
    w2 := w2 & #x7FFF
    w1 := w1 & #x7FFF
    w0 := w0 & #x7FFF
  }

AND adddig(dig) BE
{ w4 := w4 + (dig<<4)
  w3 := w3 + (w4>>15)
  w2 := w2 + (w3>>15)
  w1 := w1 + (w2>>15)
  w0 := w0 + (w1>>15)
  w4 := w4 & #x7FFF
  w3 := w3 & #x7FFF
  w2 := w2 & #x7FFF
  w1 := w1 & #x7FFF
  w0 := w0 & #x7FFF
}

AND printw(style) BE
// Print w in given style
// If wsize = S  the senior 17 bits are printed
// If wsize = L  the senior 35 bits are printed
// If wsize = F  all 71 bits are printed
{ LET digv = VEC 30
//sawritef("printw: wsize=%c style=%c*n", wsize, style)
//sawritef("%bF %bF %bF %bF %bB %c*n", w0, w1, w2, w3, w4>>4, wsize)
//abort(1000)
  SWITCHON wsize<<8 | style INTO
  { DEFAULT: error("Bad size/style combination: %c/%c", wsize, style)

    CASE 'S'<<8 | 'I':
    CASE 'L'<<8 | 'I':
    CASE 'F'<<8 | 'I':
      printinstr(w0<<2 | w1>>13)
      RETURN
  
    CASE 'S'<<8 | 'B':
      sawritef("%bF%b2",w0, w1>>13)
      RETURN   

    CASE 'L'<<8 | 'B': 
      sawritef("%bF%b2 %b1 %bC%b5", w0, w1>>13, w1>>12 & 1, w1&#xFFF, w2>>10)
      RETURN   

    CASE 'F'<<8 | 'B':  
      sawritef("%bF%b2 %b1 %bC%b5", w0, w1>>13, w1>>12 & 1, w1&#xFFF, w2>>10)
      sawritef(" %bA%bF%bB*n", w2&#x3FF, w3, w4>>4)
      RETURN   

    CASE 'S'<<8 | 'D': shrw(54); printwd( 6); RETURN  

    CASE 'L'<<8 | 'D': shrw(36); printwd(11); RETURN  
    CASE 'F'<<8 | 'D':           printwd(22); RETURN  

    CASE 'S'<<8 | 'F': printwf( 5); RETURN  
    CASE 'L'<<8 | 'F': printwf(11); RETURN  
    CASE 'F'<<8 | 'F': printwf(20); RETURN  
  }
}

AND printwd(n) BE
{ LET b = FALSE // TRUE after first non-zero digit
  LET neg = FALSE
  LET firstsig = 25
  LET str = VEC 25/bytesperword
  IF (w0 & #x4000) ~= 0 DO { neg := TRUE; negw() }
  str%0 := 25
//sawritef("*nprintwd(%n) entered*n", n)
//sawritef("w: %bF %bF %bF %bF %bF*n", w0, w1, w2, w3, w4)

  FOR i = 25 TO 1 BY -1 DO
  { LET dig = divwby10() // Digits from the least sig end
//sawritef("dig=%n*n", dig)
//sawritef("w: %bF %bF %bF %bF %bF*n", w0, w1, w2, w3, w4)
    str%i := dig + '0'
    IF dig DO firstsig := i
  }

  FOR i = 1 TO firstsig-1 DO str%i := ' '
  IF neg DO str%(firstsig-1) := '-'

  // Write the decimal fraction
  FOR i = 26-n TO 25 DO sawrch(str%i)
}

AND printwf(n) BE
{ // Write the decimal fraction
  // Round w appropriately
  LET t0, t1, t2, t3, t4 = w0, w1, w2, w3, w4

  w0, w1, w2, w3, w4 := #x2000, 0, 0, 0, 0 // 1/2

  FOR i = 1 TO n DO divwby10f()
  //sawritef("w: %bF %bF %bF %bF %bF*n", w0, w1, w2, w3, w4)
  //sawritef("+: %bF %bF %bF %bF %bF*n", t0, t1, t2, t3, t4)
  UNLESS (t0&#x4000)=0 DO negw() // Negate if necessary
  addtow(t0, t1, t2, t3, t4) // Round by adding or subtracting 0.5*10**-n
  //sawritef("=: %bF %bF %bF %bF %bF*n", w0, w1, w2, w3, w4)

  TEST (w0&#x4000)=0
  THEN sawritef(" 0.")
  ELSE { negw()
         TEST (w0&#x4000)=0
         THEN sawritef("-0.")
         ELSE { sawritef("-1."); w0 := w0&#x3FFF }
       }

  FOR i = 1 TO n DO
  { LET dig = mulwby10() // mul by 10 and extract integer part
    sawrch(dig+'0')
  }
}

AND printinstr(instr) BE
{ LET addr = instr>>1 & 2047 // Include the unused bit
  LET op = instr>>12 & 31
  sawritef("%b5_%b1_%bA_%b1   ",
     op, instr>>11 & 1, instr>>1 & 1023, instr&1)
  sawritef("%c%i4%c  // ", prf2asc(op), addr, (instr&1)=0 -> 'S', 'L')
  SWITCHON op INTO
  { DEFAULT: RETURN

    CASE  3: // E
      sawritef("if acc>=0 goto %n", addr); RETURN
    CASE  4: // R
      sawritef("acc >>= %n", lbpos(instr)); RETURN
    CASE  5: // T
      sawritef("mem[%n] = acc; acc = 0", addr); ENDCASE
    CASE  6: // Y
      sawritef("acc += 2****-36"); RETURN
    CASE  7: // U
      sawritef("mem[%n] = acc", addr); ENDCASE
    CASE  8: // I
      sawritef("mem[%n] = rd()", addr); RETURN
    CASE  9: // O
      sawritef("wr(mem[%n])", addr); RETURN
    CASE 12: // S
      sawritef("acc -= mem[%n]", addr); ENDCASE
    CASE 13: // Z
      sawritef("stop"); RETURN
    CASE 17: // F
      sawritef("verify last output"); RETURN
    CASE 21: // H
      sawritef("H = mem[%n]", addr); ENDCASE
    CASE 22: // N
      sawritef("acc -= H ** mem[%n]", addr); ENDCASE
    CASE 25: // L
      sawritef("acc <<= %n", lbpos(instr)); RETURN
    CASE 26: // X
      sawritef("no operation", addr); RETURN
    CASE 27: // G
      sawritef("if acc<0 goto %n", addr); RETURN
    CASE 28: // A
      sawritef("acc += mem[%n]", addr); ENDCASE
    CASE 30: // C
      sawritef("acc += H & mem[%n]", addr); ENDCASE
    CASE 31: // V
      sawritef("acc += H ** mem[%n]", addr); ENDCASE
  }
  sawritef(", %s", (instr&1)=0 -> "short", "long")
}

AND lbpos(instr) = VALOF
{ LET res = 1 // instr is a left or right shift instruction
  WHILE (instr&1)=0 DO res, instr := res+1, instr>>1
  RESULTIS res
}

AND prl(a) BE
    writef("%i4: %bH %b1 %bH", a, mem!(a+1), mem!a>>17, mem!a)

AND interpret() = VALOF
// Returns:
//  0     Executed ZnS
//  1     Single step return -- (if singlestep=TRUE)
//  2     Breakpoint reached -- ie (flags!scr&f_break)~=0
//  3     Unknown instruction

{ // Instruction execution loop
  LET instr = mem!scr
  LET addr  = instr>>1 & #x3FF

  TEST (instr&1)=0 THEN ldrs(addr)
                   ELSE ldrl(addr&#x3FE)

  scr := scr+1
  SWITCHON instr & #b11111_0_0000000000_1 INTO
  { DEFAULT:                     RESULTIS 3

    CASE #b00011_0_0000000000_0: IF (a0 & #x4000) = 0 DO      // E n S
                                     scr := addr;     ENDCASE

    CASE #b00100_0_0000000000_0:                              // R n S
    CASE #b00100_0_0000000000_1: shr(instr);          ENDCASE // R n L

    CASE #b00101_0_0000000000_0: stas(addr);                  // T n S
                                 a0, a1, a2 := 0, 0, 0
                                 a3, a4 := 0, 0       ENDCASE

    CASE #b00101_0_0000000000_1: stal(addr);                  // T n L
                                 a0, a1, a2 := 0, 0, 0
                                 a3, a4 := 0, 0       ENDCASE

    CASE #b00110_0_0000000000_0: round();             ENDCASE // Y n S

    CASE #b00111_0_0000000000_0: stas(addr);          ENDCASE // U n S
    CASE #b00111_0_0000000000_1: stal(addr&#x3FC);    ENDCASE // U n L

    CASE #b01000_0_0000000000_0: sts(addr, rd());     ENDCASE // I n S

    CASE #b01001_0_0000000000_0: ldrs(addr)                   // O n S
                                 wr(r0>>10);          ENDCASE

    CASE #b01100_0_0000000000_0:                              // S n S
    CASE #b01100_0_0000000000_1: negr()                       // S n L
                                 add();               ENDCASE

    CASE #b01101_0_0000000000_0: RESULTIS 0                   // Z n S

    CASE #b10101_0_0000000000_0: ldhs(addr);          ENDCASE // H n S
    CASE #b10101_0_0000000000_1: ldhl(addr&#x3FC);    ENDCASE // H n L

    CASE #b10110_0_0000000000_0:                              // N n S
    CASE #b10110_0_0000000000_1: negr()                       // N n L
                                 mul();               ENDCASE

    CASE #b11001_0_0000000000_0:                              // L n S
    CASE #b11001_0_0000000000_1: shl(instr);          ENDCASE // L n L

    CASE #b11010_0_0000000000_0:                              // X n S
    CASE #b11010_0_0000000000_1:                      ENDCASE // X n L

    CASE #b11011_0_0000000000_0: UNLESS (a0 & #x4000) = 0 DO  // G n S
                                     scr := addr;     ENDCASE

    CASE #b11100_0_0000000000_0:                              // A n S
    CASE #b11100_0_0000000000_1: add();               ENDCASE // A n L

    CASE #b11110_0_0000000000_0:                              // C n S
    CASE #b11110_0_0000000000_1: and();               ENDCASE // C n L

    CASE #b11111_0_0000000000_0:                              // V n S
    CASE #b11111_0_0000000000_1: mul();               ENDCASE // V n L

  }

  IF singlestep RESULTIS 1

  IF (mflags!scr & mf_break) ~= 0 RESULTIS 2

} REPEAT

AND reset() BE
{ // Load the initial orders, clear the registers and
  // re-position the input paper tape.
  loadinitorders()
  a0, a1, a2, a3, a4 := 0, 0, 0, 0, 0
  h0, h1, h2 := 0, 0, 0
  r0, r1, r2, rsize := 0, 0, 0, 'L'
  scr := 0
  IF tape DO
  { endstream(tape)
    tape := findinput(name)
    UNLESS tape DO
      error("*nUnable to open file %s*n", name)
    selectinput(tape)
  }
}

AND loadinitorders() BE
{ // Load initial orders version 1
  sts( 0, #b00101_0_0000000000_0)  // T0S
  sts( 1, #b10101_0_0000000010_0)  // H2S
  sts( 2, #b00101_0_0000000000_0)  // T0S
  sts( 3, #b00011_0_0000000110_0)  // E6S
  sts( 4, #b00000_0_0000000001_0)  // P1S
  sts( 5, #b00000_0_0000000101_0)  // P5S
  sts( 6, #b00101_0_0000000000_0)  // T0S
  sts( 7, #b01000_0_0000000000_0)  // I0S
  sts( 8, #b11100_0_0000000000_0)  // A0S
  sts( 9, #b00100_0_0000010000_0)  // R16S
  sts(10, #b00101_0_0000000000_1)  // T0L
  sts(11, #b01000_0_0000000010_0)  // I2S
  sts(12, #b11100_0_0000000010_0)  // A2S
  sts(13, #b01100_0_0000000101_0)  // S5S
  sts(14, #b00011_0_0000010101_0)  // E21S
  sts(15, #b00101_0_0000000011_0)  // T3S
  sts(16, #b11111_0_0000000001_0)  // V1S
  sts(17, #b11001_0_0000001000_0)  // L8S
  sts(18, #b11100_0_0000000010_0)  // A2S
  sts(19, #b00101_0_0000000001_0)  // T1S
  sts(20, #b00011_0_0000001011_0)  // E11S
  sts(21, #b00100_0_0000000100_0)  // R4S
  sts(22, #b11100_0_0000000001_0)  // A1S
  sts(23, #b11001_0_0000000000_1)  // L0L
  sts(24, #b11100_0_0000000000_0)  // A0S
  sts(25, #b00101_0_0000011111_0)  // T31S
  sts(26, #b11100_0_0000011001_0)  // A25S
  sts(27, #b11100_0_0000000100_0)  // A4S
  sts(28, #b00111_0_0000011001_0)  // U25S
  sts(29, #b01100_0_0000011111_0)  // S31S
  sts(30, #b11011_0_0000000110_0)  // G6S
}

// Auxiliary functions

AND sts(a, x) BE mem!a := x & #x1FFFF

AND stl(a, x1, x0) BE
{ mem!(a+1) := x1 & #x1FFFF // Senior half
  mem!a     := x0 & #x3FFFF // Junior half
}

AND ldas(a) BE
{ LET x = mem!a
  a0 := x>>2            // 15-bits
  a1 := x<<15 & #x6000  //  2-bits
  a2, a3, a4 := 0, 0, 0
}


AND ldhs(a) BE
{ LET x = mem!a
  h0 := x>>2            // 15-bits
  h1 := x<<13 & #x6000  //  2-bits
  h2 := 0
}

AND ldrs(a) BE
{ LET x = mem!a
  r0 := x>>2            // 15-bits
  r1 := x<<13 & #x6000  //  2-bits
  r2 := 0
  rsize := 'S'
}

AND ldvs(a) BE
{ LET x = mem!a
  v0 := x>>2            // 15-bits
  v1 := x<<13 & #x6000  //  2-bits
  v2 := 0
  vsize := 'S'
}

AND ldal(a) BE
{ LET x0 = mem!(a|1)                 // 17-bits
  LET x1 = mem!(a&-2)                // 18-bits

  a0 :=  x0>>2                       // 15-bits
  a1 := (x0<<13 | x1>>5) & #x7FFF    // 15-bits
  a2 :=  x1<<10 & #x7C00             //  5-bits
  a3, a4 := 0, 0
}

AND ldhl(a) BE
{ LET x0 = mem!(a|1)                 // 17-bits
  LET x1 = mem!(a&-2)                // 18-bits

  h0 := x0>>2                        // 15-bits
  h1 := (x0<<13 | x1>>5) & #x7FFF    // 15-bits
  h2 := x1<<10 & #x7C00              //  5-bits
}

AND ldrl(a) BE
{ LET x0 = mem!(a|1)                 // 17-bits
  LET x1 = mem!(a&-2)                // 18-bits

  r0 := x0>>2                        // 15-bits
  r1 := (x0<<13 | x1>>5) & #x7FFF    // 15-bits
  r2 := x1<<10 & #x7C00              //  5-bits
  rsize := 'L'
}

AND ldvl(a) BE
{ LET x0 = mem!(a|1)                 // 17-bits
  LET x1 = mem!(a&-2)                // 18-bits

  v0 := x0>>2                        // 15-bits
  v1 := (x0<<13 | x1>>5) & #x7FFF    // 15-bits
  v2 := x1<<10 & #x7C00              //  5-bits
  vsize := 'L'
}

AND stas(a) BE mem!a := a0<<2 | a1>>13
AND sths(a) BE mem!a := h0<<2 | h1>>13
AND strs(a) BE mem!a := r0<<2 | r1>>13
AND stvs(a) BE mem!a := v0<<2 | v1>>13

AND stal(a) BE
{ mem!(a|1)  := a0<<2 | a1>>13             // 17 bits
  mem!(a&-2) := (a1<<5 | a2>>10) & #x3FFFF // 18 bits
}

AND stvl(a) BE
{ mem!(a|1)  := v0<<2 | v1>>13             // 17 bits
  mem!(a&-2) := (v1<<5 | v2>>10) & #x3FFFF // 18 bits
}

AND add() BE
{ a2 := a2 + r2
  a1 := a1 + r1 + (a2>>15)
  a0 := a0 + r0 + (a1>>15)
  a2 := a2 & #x7FFF
  a1 := a1 & #x7FFF
  a0 := a0 & #x7FFF
}

AND round() BE
{ // Round to 35 bits by adding one in bit 36 of the accumulator
  a2 := a2 + #x0200           // The 36th bit
  a1 := a1 + (a2>>15)
  a0 := a0 + (a1>>15)
  a2 := a2 & #x7FFF
  a1 := a1 & #x7FFF
  a0 := a0 & #x7FFF
}

AND and() BE
{ // a := a + (h&r)
  a2 := a2 + (h2 & r2)
  a1 := a1 + (h1 & r1) + (a2>>15)
  a0 := a0 + (h0 & r0) + (a1>>15)
  a2 := a2 & #x7FFF
  a1 := a1 & #x7FFF
  a0 := a0 & #x7FFF
}

AND mul() BE
{ LET x, neg = ?, FALSE
  LET b0, b1, b2 = ?, ?, ?
  LET c0, c1, c2, c3, c4 = a0, a1, a2, a3, a4

//writef(" r : %bF %bF %bF*n", r0, r1, r2)
//writef(" h : %bF %bF %bF*n", h0, h1, h2)

  UNLESS (r0 & #x4000)=0 DO { negr(); neg := TRUE }
  b0, b1, b2 := r0, r1, r2

  r0, r1, r2 := h0, h1, h2
  UNLESS (r0 & #x4000)=0 DO { negr(); neg := ~neg }

//writef("|r|: %bF %bF %bF*n", b0, b1, b2)
//writef("|h|: %bF %bF %bF*n", r0, r1, r2)

  // a := |r| * |h|   (ie all positive)
  
  x := b2*r2                    // ls bit 88
  a4 := (x>>14)           

  x := b1*r2 + b2*r1            // ls bit 73
  a4 := a4 + (x<<1 & #x7FFC)
  a3 := (x>>14) + (a4>>15)

  x := b0*r2 + b1*r1 + b2*r0    // ls bit 58
  a3 := a3 + (x<<1 & #x7FFE)
  a2 := (x>>14) + (a3>>15)

  x := b0*r1 + b1*r0            // ls bit 43
  a2 := a2 + (x<<1 & #x7FFE)
  a1 := (x>>14) + (a2>>15)

  x := b0*r0                    // ls bit 28
  a1 := a1 + (x<<1 & #x7FFF)  
  a0 := (x>>14) + (a1>>15)

  a4 := a4 & #x7FFF
  a3 := a3 & #x7FFF
  a2 := a2 & #x7FFF
  a1 := a1 & #x7FFF
  a0 := a0 & #x7FFF

//writef("*na := |r| ** |h|*n")
//writef(" a : %bF %bF %bF %bF %bF*n", a0, a1, a2, a3, a4)

  IF neg DO
  { // negate a
    TEST a4
    THEN a4, a3, a2, a1, a0 := -a4, ~a3, ~a2, ~a1, ~a0
    ELSE TEST a3
         THEN a3, a2, a1, a0 := -a3, ~a2, ~a1, ~a0
         ELSE TEST a2
              THEN a2, a1, a0 := -a2, ~a1, ~a0
              ELSE TEST a1
                   THEN a1, a0 := -a1, ~a0
                   ELSE a0 := -a0
   
    a4 := a4 & #x7FFF
    a3 := a3 & #x7FFF
    a2 := a2 & #x7FFF
    a1 := a1 & #x7FFF
    a0 := a0 & #x7FFF
  }

  // a := a + c
  a4 := a4 + c4
  a3 := a3 + c3 + (a4>>15)
  a2 := a2 + c2 + (a3>>15)
  a1 := a1 + c1 + (a2>>15)
  a0 := a0 + c0 + (a1>>15)

  a4 := a4 & #x7FFF
  a3 := a3 & #x7FFF
  a2 := a2 & #x7FFF
  a1 := a1 & #x7FFF
  a0 := a0 & #x7FFF
//newline()
//writef(" c : %bF %bF %bF %bF %bF*n", c0, c1, c2, c3, c4)
//writef(" a : %bF %bF %bF %bF %bF*n", a0, a1, a2, a3, a4)
//abort(1111)
}

AND negr() BE
{ // Negate the 35-bit operand register
  TEST r2
  THEN r2, r1, r0 := -r2, ~r1, ~r0
  ELSE TEST r1
       THEN r1, r0 := -r1, ~r0
       ELSE r0 := -r0
  r2 := r2 & #x7FFF
  r1 := r1 & #x7FFF
  r0 := r0 & #x7FFF
}

AND shr(bits) BE     // Arithmetic right shift
{ a1 := a1 | a0<<15
  a2 := a2 | a1<<15
  a3 := a3 | a2<<15
  a4 := a4 | a3<<15

  // Arithmetic right shift
  { a0, a1, a2, a3, a4 := a0>>1 | a0&#x4000, a1>>1, a2>>1, a3>>1, a4>>1
    UNLESS (bits&1)=0 BREAK
    bits := bits>>1
  } REPEAT

  a1 := a1 & #x7FFF
  a2 := a2 & #x7FFF
  a3 := a3 & #x7FFF
  a4 := a4 & #x7FF0
}

AND shl(bits) BE
{ { a0, a1, a2, a3, a4 := a0<<1, a1<<1, a2<<1, a3<<1, a4<<1
    UNLESS (bits&1)=0 BREAK
    bits := bits>>1
  } REPEAT

  a0 := a0 + (a1>>15) & #x7FFF
  a1 := a1 + (a2>>15) & #x7FFF
  a2 := a2 + (a3>>15) & #x7FFF
  a3 := a3 + (a4>>15) & #x7FFF
  a4 := a4            & #x7FF0
}

// rd reads the next 5 bit row from the Edsac paper tape reader.
// This version ignores spaces, tabs and newlines.

AND rd() = VALOF
{ LET ch = ?

  UNLESS tape DO
  { writef("*nNo input tape selected*n")
    abort(999)
  }

  ch := rdch()

  SWITCHON ch INTO
  { DEFAULT:  code := asc2ed(ch)
              IF code>=0 RESULTIS code
              writef("Bad ch %n '%c'*n", ch, ch)
              abort(999)
              RESULTIS 0
             
    CASE '*t':
    CASE '*s': 
    CASE '*n': LOOP
  }
} REPEAT

AND asc2ed(ch) = VALOF SWITCHON ch INTO
{ DEFAULT:  RESULTIS -1

  CASE 'P':  CASE '0':  RESULTIS  0
  CASE 'Q':  CASE '1':  RESULTIS  1
  CASE 'W':  CASE '2':  RESULTIS  2
  CASE 'E':  CASE '3':  RESULTIS  3
  CASE 'R':  CASE '4':  RESULTIS  4
  CASE 'T':  CASE '5':  RESULTIS  5
  CASE 'Y':  CASE '6':  RESULTIS  6
  CASE 'U':  CASE '7':  RESULTIS  7
  CASE 'I':  CASE '8':  RESULTIS  8
  CASE 'O':  CASE '9':  RESULTIS  9
  CASE 'J':             RESULTIS 10
  CASE '#':             RESULTIS 11
  CASE 'S':             RESULTIS 12
  CASE 'Z':             RESULTIS 13
  CASE 'K':             RESULTIS 14
  CASE '**':            RESULTIS 15
  CASE '.':             RESULTIS 16
  CASE 'F':             RESULTIS 17
  CASE '@':             RESULTIS 18
  CASE 'D':             RESULTIS 19
  CASE '!':             RESULTIS 20
  CASE 'H':             RESULTIS 21
  CASE 'N':             RESULTIS 22
  CASE 'M':             RESULTIS 23
  CASE '&':             RESULTIS 24
  CASE 'L':             RESULTIS 25
  CASE 'X':             RESULTIS 26
  CASE 'G':             RESULTIS 27
  CASE 'A':             RESULTIS 28
  CASE 'B':             RESULTIS 29
  CASE 'C':             RESULTIS 30
  CASE 'V':             RESULTIS 31
}

// wr outputs teleprinter code as ASCII characters

AND wr(ch) BE
{ IF ch=11 DO { figshift := TRUE;  RETURN }
  IF ch=15 DO { figshift := FALSE; RETURN }
  IF ch=16 RETURN  // Null character
  TEST figshift THEN sawrch(fig2asc(ch))
                ELSE sawrch(let2asc(ch))
}

AND fig2asc(ch) = "0123456789? *"+(  $*c; #,.*n)/#-?:="% ((ch&31)+1)

AND let2asc(ch) = "PQWERTYUIOJ SZK  F*cD HNM*nLXGABCV" % ((ch&31)+1)

AND prf2asc(ch) = "PQWERTYUIOJ#SZK**.F@D!HNM&LXGABCV"  % ((ch&31)+1)

