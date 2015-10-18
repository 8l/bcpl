// (c) Copyright: Martin Richards   8 Dec 2010

/*
Change log

8/11/06
Made several changes for the -v and -d options, and for dumpsys.

27/07/06
Stored the default environment variable names for the system root,
the headers and the cli path directories in the rootnode. 

05/07/06
Changed to use mainly lowercase file names.

12/01/06
As suggested by Dave Lewis, saved cli_returncode from the CLI global
vector in the BOOT global vector, so that this value can be returned
to the (Unix) shell.
*/

SECTION "BOOT"

GET "libhdr"
//GET "clihdr"  // MR 17/1/2006

GLOBAL {
sadebug:ug
checkaddr
cont
debug
error
gb
gh
gsb
gsh
gw
instrtype
fname
nextpc
praddr
prinstr
print
rdval
rdvaraddr
rch
wrcortn
wrframe
writearg

bpt        // The current breakpoint number or -1
bpt_addr   // Vector of breakpoint PC values
bpt_instr  // Vector of breakpoint first bytes (op codes)
brkstep    // =TRUE when resuming from a breakpoint
snglstep   // =TRUE when single stepping (\ command)

gptr       // Currently selected G pointer
cptr       // Currently selected coroutine
pptr       // Currently selected P pointer
fsize      // Size of currently selected stack frame

membase
memlim
oldcount
recp
recl
regs       // The register set of the selected task
trapregs   // regs on entry to sadebug, ie the set that caused
           // cinterp to return with a non zero result.
style
val        // Current value
vars       // Vector of variables (V1 .. V9)

crntcb     // Currently selected TCB, if in Cintpos
ch
lch
}

STATIC { debugstarted = FALSE } // For Cintpos only

MANIFEST
{
g_globsize=0; g_sys=3; g_currco=7; g_colist=8; g_rootnode=9

f_brk   = 2

r_a     = 0
r_b     = 1
r_c     = 2
r_p     = 3
r_g     = 4
r_st    = 5
r_pc    = 6
r_count = 7
r_mw    = 8
r_upb   = 8

root_stackupb =  500  // MR 25/1/07
root_gvecupb  = 1000  // MR 25/1/07
gn_cli_returncode = 137  // dtl 25-09-06, matches declaration of cli_returncode

fl_mk = 2 // Floating point operation

// Cintpos only
tasktabupb = 200  // MR 18/10/04
devtabupb  = 1000
}

LET start(fn, size, c) BE
// This is the very first BCPL code to be entered (from cintsys/cintpos)
// Its stack and globals are already setup
// globsize (G0) is already set -- MR 25/1/07
// rootnode (G9) is already set -- MR 25/1/07
// p!0 holds the stack size
// sys is in rootnode!rtn_sys

{ // First make the boot stack into a coroutine stack
  // for debugging purposes.
  LET cosz = ?
  currco := @fn-3               // currco = base of the boot stack
  cosz := currco!0              // The size as supplied by cintsys/cintpos

  colist := currco
  currco!co_pptr     :=  0
  currco!co_parent   := -1      // Mark as root coroutine
  currco!co_list     :=  0
  currco!co_fn       :=  start  // These are the same locations as fn
  currco!co_size     :=  cosz   //                                 size
  currco!co_c        :=  0      //                             and c

  boot()
}

AND boot() BE
// This is the very first BCPL code to be entered (from cintsys/cintpos).
// Its stack is allocated and initialised with #xABCD1234 but
// must be made into a root coroutine stack. The global vector
// is allocated and fully initilalise with all the entry points
// in: boot, blib, syslib and dlib.

// Most rootnode fields have been initialised by cintsys/cintpos,
// including

// rtn_boot   The module boot ie this module
// rtn_blib   The module blib, syslib and dlib
// rtn_sys    The function sys

{ LET g, p = 0, 0
   
  IF rootnode!rtn_boottrace DO
  { sawritef("BOOT stack is at %n*n", currco)
    sawritef("BOOT global vector is at %n*n", @globsize)
  }

  // Allocate the root stack and global vector (for klib or cli)
  // Note that boot's stack and global vector were allocated by
  // cintsys(64) or cintpos.
  p := getvec(root_stackupb+6)  // The root coroutine stack
  g := getvec(root_gvecupb)     // The root global vector

  // boot only uses standalone i/o
  rdch, wrch := sardch, sawrch
  tcb, taskid := 0, 1          // For compatibility with cintpos
                               // Pretend to be in the CLI task

  IF rootnode!rtn_boottrace>1 DO
  { sys(Sys_tracing, FALSE)
    sawritef("boot: instruction tracing turned off*n")
  }

  UNLESS p & g DO
  { sawritef("System error in boot: getvec failed*n")
    sys(Sys_quit, 0)
  }

  IF rootnode!rtn_boottrace DO
  { sawritef("CLI stack allocated at %n*n", p)
    sawritef("CLI global vector allocated at %n*n", g)
  }

  // Clear the root global vector and stack (for klib to cli)
  g!0 := root_gvecupb
  p!0 := root_stackupb
  FOR i = 1 TO g!0 DO g!i := globword + i;
  FOR i = 1 TO p!0+6 DO p!i := stackword
 
  writef("*nBCPL %n-bit Cintcode System (30 May 2013)*n", BITSPERBCPLWORD)

  IF rootnode!rtn_boottrace>1 DO
  { sawritef("boot: turning on instruction tracing*n")
    sys(Sys_tracing, TRUE)
  }

  // Set the environment variable names for this system in the rootnode
  // BCPL Cintcode uses BCPLROOT,   BCPLPATH   and BCPLHDRS
  // BCPL64        uses BCPL64ROOT, BCPL64PATH and BCPL64HDRS
  // Cintpos       uses POSROOT,    POSPATH    and POSHDRS
  //{ LET rootvar, pathvar, hdrsvar, scriptsvar = 
  //      "BCPLROOT",   "BCPLPATH",   "BCPLHDRS",   "BCPLSCRIPTS"
  //    //"BCPL64ROOT", "BCPL64PATH", "BCPL64HDRS", "BCPL64SCRIPTS"
  //    //"POSROOT",    "POSPATH",    "POSHDRS",    "POSSCRIPTS"
  //  FOR i = 0 TO rootvar%0    DO (rootnode!rtn_rootvar)%i    := rootvar%i
  //  FOR i = 0 TO pathvar%0    DO (rootnode!rtn_pathvar)%i    := pathvar%i
  //  FOR i = 0 TO hdrsvar%0    DO (rootnode!rtn_hdrsvar)%i    := hdrsvar%i
  //  FOR i = 0 TO scriptsvar%0 DO (rootnode!rtn_scriptsvar)%i := scriptsvar%i
  //}

//writef("Type 5 characters to test standalone rdch*n")
//FOR i = 1 TO 5 DO
//{ LET ch = sardch()
//  sawritef("ch = %n '%c'*n", ch, ch)
//  IF ch='.' BREAK
//}


  g!g_globsize := root_gvecupb
  g!g_sys      := sys
  g!g_rootnode := rootnode
  g!g_currco   := 0          // These are initialised to simplify
  g!g_colist   := 0          // the initial debugging of cintasm.
   
  // Initialise the standalone debugger variables
  membase   := rootnode!rtn_membase
  memlim    := membase + rootnode!rtn_memsize
  vars      := TABLE 0,0,0,0,0,0,0,0,0,0
  bpt_addr  := TABLE 0,0,0,0,0,0,0,0,0,0
  bpt_instr := TABLE 0,0,0,0,0,0,0,0,0,0
  style     := 'F'                   // Default printing style
  val       := 0
  brkstep   := FALSE
  snglstep  := FALSE

  crntcb    := 0       // For Cintpos only

  // Breakpoints may be set and cleared by the debug task so
  // bpt_addr and bpt_instr must be accessible to it. These fields
  // are also used by the dumpdebug command.
  rootnode!rtn_bptaddr  := bpt_addr
  rootnode!rtn_bptinstr := bpt_instr
  rootnode!rtn_dbgvars  := vars        // MR 25/08/05

  regs         := cliregs
  regs!r_a     := 0          // A
  regs!r_b     := 0          // B
  regs!r_c     := 0          // C
  regs!r_p     := p<<B2Wsh   // P
  regs!r_g     := g<<B2Wsh   // G
  regs!r_st    := 1          // Cintpos only -- In klib, interrupts disabled
  regs!r_pc    := startroot  // PC
  regs!r_count := -1         // Count  (-1 = infinity)
  regs!r_mw    := 0          // MW (used by 64-bit Cintcode)

  { LET sw = 1  // 1=cintasm  2=interpret
    IF rootnode!rtn_boottrace>1 DO sw := 2
    regs!r_count := sw=1 -> -1, 1_000_000_000
  }

  IF rootnode!rtn_boottrace>1 DO
  { sys(Sys_tracing, FALSE)
    sawritef("boot: instruction tracing turned off*n")
  }

  IF rootnode!rtn_boottrace DO
  { sawritef("boot about to call the interpreter recursively*n")
    sawritef("It should start executing the boot function: startroot*n")
  }

  { // In this loop a private copy of the sys function is made
    // so that breakpoints can be set in the normal sys fuction
    // without interferring with the sys calls used here.
    LET res = 0
    LET sysf = (rootnode!rtn_sys>>B2Wsh)-4
    LET sysv = VEC 4       // The vector to hold the private copy sys.
                           // This copy will work on big and little
                           // ender machines running using either 32-
                           // or 64-bit Cintcode.
    // Copy the standard version of sys including its name
    // into private work space.
    FOR i = 0 TO 4 DO sysv!i := sysf!i
    sys := (sysv+4)<<B2Wsh // Update the sys function in boot's global
                           // vector to point to this private version.

    //sysv%0 := #x91      // SYS
    //sysv%1 := #x7B      // RTN
    //sys := sysv<<B2Wsh  // Update the sys function in boot's global
                        // vector to point to this private version.

    IF rootnode!rtn_boottrace DO
    { sawritef("boot: about to call sys(Sys_interpret,...)*n")
    }

    IF rootnode!rtn_boottrace>1 DO
    { sawritef("boot: after turning instruction tracing on*n")
      sys(Sys_tracing, TRUE)
    }

    res := sys(Sys_interpret, regs)  // Call the interpreter

    // Save cli_returncode from CLI global vector in BOOT global vector
    cli_returncode := g!gn_cli_returncode // MR 17/1/06

    UNLESS res DO sys(Sys_quit, 0)  // Exit from cintsys or cintpos

    IF res=-1 LOOP        // Re-enter the interpreter immediately
                          // to allow a different interpreter to
                          // be entered.

    IF res=-2 DO          // Used by the dumpmem command to
    { sys(Sys_dumpmem, 4) // dump the memory (context=4) and
      LOOP                // re-enter the interpreter.
    }
    rootnode!rtn_abortcode := res

    IF rootnode!rtn_dumpflag DO
    { rootnode!rtn_dumpflag := FALSE // To stop memory being dumped twice.
      sys(Sys_dumpmem, 5) // Dump the memory (context=5) and quit
      // Memory has been dumped so just leave Cintpos
      sys(Sys_quit, 0)
    }

    val := regs!r_pc      // Debug's current value

    IF rootnode!rtn_boottrace>1 DO
    { sys(Sys_tracing, FALSE)
      sawritef("boot: instruction tracing turned off*n")
    }

    UNLESS sadebug(res) DO
    { sawritef("Standalone debug could not cope*n")
      sys(Sys_quit, res)
    }

  } REPEAT // to re-enter the interpreter.
}

AND startroot(fn, size, c) BE
{ // On entry the base of the stack is at @fn-3,
  // and the P pointer is set to this value.
  // All the stack elements are set to #xABCD1234, except
  // for the zeroth word which holds the stacksize.

  // The base of the global vector is at @globsize (=Global 0),
  // all its elements are filled with words of the form
  // globword+n (=#8F8F0000+n), except for the follow few critical
  // global variables:

  // globsize  -- set to the upper bound
  // sys       -- set to the entry point of the function sys
  // rootnode  -- set to point to the root node (typically = 100)
  // currco    -- set to zero
  // colist    -- set to zero

  LET stacksize = 0

  // Make the stack into a root coroutine stack.
  currco := @fn-3
  colist := currco

  stacksize        := currco!0

  currco!co_pptr   :=  0
  currco!co_parent := -1          // Mark as root coroutine
  currco!co_list   :=  0
  currco!co_fn     :=  startroot  // These are the same locations as fn
  currco!co_size   :=  stacksize  //                                 size
  currco!co_c      :=  0          //                             and c

  rootcode()
}

AND rootcode() BE
{
  tcb, taskid := 0, 1 // Compatibility with Cintpos
  crntcb := 0         // Cintpos only -- no current task yet

  // Set the globals defined in blib, syslib and dlib
  sys(Sys_globin, rootnode!rtn_blib)
   
  rootnode!rtn_keyboard := 0
  rootnode!rtn_screen   := 0
  currentdir            := 0

  IF rootnode!rtn_boottrace>1 DO
  { sys(Sys_tracing, FALSE)
    sawritef("rootcode: instruction tracing turned off*n")
  }

  selectinput(findinput("**"))
  selectoutput(findoutput("**"))

  // We can now do normal stream IO (using rdch and wrch),
  // for example:
  //writes("Hello*n")

  IF rootnode!rtn_boottrace DO
  { sawritef("startroot: can now use normal stream i/o*n")
    sawritef("startroot: trying to load syscin/cli*n")
  }


  UNLESS globin(loadseg("syscin/cli")) DO
  { sawritef("Unable to start the CLI.*n")
    sys(Sys_quit, 0)
  }

  IF rootnode!rtn_boottrace DO
  { sawritef("startroot: loaded syscin/cli successfully*n")
    sawritef("startroot: now entering the cli*n")
  }
   
  start()          // Enter the newly loaded CLI
  sys(Sys_quit, 0)
}

AND sadebug(code) = VALOF
// Enter standalone debug
// Only entered as a result of the interpreter encountering
// a fault. The Cintcode registers in regs represent the state at
// that moment.

{ IF sawrch<0 DO     // Test if the system is sufficiently initialised
                     // to run standalone debug.
  { LET mess = "Fault occurred before the system was initialised*n"
    FOR i = 1 TO mess%0 DO sys(Sys_sawrch, mess%i)
    sys(Sys_quit, code)
    RESULTIS FALSE
  }

  trapregs := regs // Save the register set at time of entering sadebug
                   // (In Cintpos, regs changes when selecting different
                   // tasks)
                   // On exit from sadebug regs must equal trapregs.

  recp  := @code-3 << B2Wsh // level() without using BLIB.
  recl  := recover
  bpt   := -1

  gptr  := regs!r_g >> B2Wsh
  cptr  := gptr!g_currco
  pptr  := regs!r_p >> B2Wsh
  fsize := cptr + 6 + cptr!co_size
  val   := regs!r_pc

  IF code=3 DO          // Zero count.
  { IF brkstep DO
    { brkstep := FALSE  // Breakpoint continuation.
      IF oldcount>0 DO oldcount := oldcount-1
      trapregs!r_count := oldcount
      GOTO ret          // Restore BRK instructions and continue.
    }
    IF snglstep DO
    { snglstep := FALSE // Single step.
      IF oldcount>0 DO oldcount := oldcount-1
      trapregs!r_count := oldcount
      writes(" A="); print(regs!r_a)
      writes(" B="); print(regs!r_b)
      prinstr(val)
      newline()
      GOTO recover
    }
  }

  FOR i = 0 TO 9 DO            // Remove all BRK instructions
  { LET ba = bpt_addr!i
    IF ba~=0 & 0%ba=f_brk DO 0%ba := bpt_instr!i
  }

  IF code=2 DO  // BRK instruction
    FOR i = 0 TO 9 IF bpt_addr!i=val DO
    { bpt := i
      writef("*n!! BPT %n:  ", bpt)
      writearg(val)
      writes("*n   ")
      writes(" A="); print(regs!r_a)
      writes(" B="); print(regs!r_b)
      prinstr(val)
      newline()
      GOTO recover
    }

  IF code=10 DO // Cintasm single step
  { writes(" A="); print(regs!r_a)
    writes(" B="); print(regs!r_b)
    prinstr(val)
    newline()
    GOTO recover
  }

  { LET gn = regs!r_pc - globword
    LET mess =  VALOF SWITCHON code INTO
                { CASE   1: RESULTIS "Illegal instruction"
                  CASE   2: RESULTIS "BRK instruction"
                  CASE   3: RESULTIS "Zero count"
                  CASE   4: TEST 0<=gn<=gptr!0
                            THEN RESULTIS "G%n unassigned"
                            ELSE RESULTIS "Negative pc"
                  CASE   5: RESULTIS "Division by zero"
                  CASE  10: RESULTIS "Cintasm single step"
                  CASE  11: RESULTIS "Watch addr: %+%i7 value: %i8"
                  CASE  12: RESULTIS "Indirect address out of range: %+%+%+%n"
                  CASE  13: RESULTIS "SIGINT received"
                  CASE  99: RESULTIS "User requested"
                  CASE 110: RESULTIS "Callco fault"
                  CASE 111: RESULTIS "Resumeco fault"
                  CASE 112: RESULTIS "Deleteco fault"
                  CASE 180: RESULTIS "Unable to delete a task"
                  CASE 181: RESULTIS "Unable to send a packet"
                  CASE 182: RESULTIS "Unexpected pkt received"
                  CASE 186: RESULTIS "Bad input stream"
                  CASE 187: RESULTIS "Bad output stream"
                  CASE 188: RESULTIS "Unable to replenish input"
                  CASE 189: RESULTIS "Wrch fault"
                  CASE 190: RESULTIS "Endread fault"
                  CASE 191: RESULTIS "Endwrite fault"
                  CASE 197: RESULTIS "Store chain fault"
                  DEFAULT:  RESULTIS "Unknown fault"
                }
    sawritef("*n!! ABORT %n: ", code)
    sawritef(mess, gn, !1, !2, !3)
    sawrch('*n')
  }

recover:
  ch := '*n'
nxt:                       // Main loop for debug commands
  IF ch='*n' DO writes("** ")
  rch()
sw:
  SWITCHON ch INTO

  { DEFAULT: error()

    CASE endstreamch:
    CASE 'Q': sawritef("*n"); sys(Sys_quit, 0)   // Quit
         
      
    CASE '*s':
    CASE '*t':
    CASE '*n': GOTO nxt

    CASE '?':
       writes("*n?            Print list of debug commands*n")
       writes("Gn Pn Rn Vn                Variables*n")
       writes("G  P  R  V                 Pointers*n")
       writes("123 #o377 #FF03 'c         Constants*n")
       writes("**e /e %e +e -e |e &e ^e   Dyadic operators*n")
       writes("!e                         Subscription*n")
       writes("< >                        Shift left/right one place*n")
       writes("$b $c $d $f $o $s $u $x    Set the print style*n")
       writes("SGn SPn SRn SVn SAn        Store in variable*n")
       writes("=          Print current value*n")
       writes("Tn         Print n consecutive locations*n")
       writes("I          Print current instruction*n")
       writes("N          Print next instruction*n")
       writes("D          Dump Cintcode memory to DUMP.mem*n")
       writes("Q          Quit -- leave the cintpos system*n")
       writes("M          Set/Reset memory watch address*n")
       writes("B 0Bn eBn  List, Unset or Set breakpoints*n")
       writes("X  (G4B9C) Set breakpoint 9 at start of clihook*n")
       writes("Z  (P1B9C) Set breakpoint 9 at return of current function*n")
       writes("C          Continue normal execution*n")
       writes("\          Single step execute one Cintcode instruction*n")
       writes(". ; [ ]    Move to current/parent/first/next coroutine*n")
       writes(",          Move down one stack frame*n")
       GOTO recover

    CASE '0': CASE '1': CASE '2':
    CASE '3': CASE '4': CASE '5':
    CASE '6': CASE '7': CASE '8':
    CASE '9': CASE '#': CASE '*'':
    CASE 'G': CASE 'P': CASE 'R':
    CASE 'V': CASE 'A':
              val := rdval();                       GOTO sw

    CASE '!': rch(); val := cont(val  +  rdval());  GOTO sw
    CASE '+': rch(); val := val  +  rdval();        GOTO sw
    CASE '-': rch(); val := val  -  rdval();        GOTO sw
    CASE '**':rch(); val := val  *  rdval();        GOTO sw
    CASE '/': rch(); { LET a = rdval()
                       UNLESS a DO error()
                       val := val / a
                       GOTO sw
                     }
    CASE '%': rch(); { LET a = rdval()
                       UNLESS a DO error()
                       val := val REM a
                       GOTO sw
                     }
    CASE '|': rch(); val := val  |  rdval();  GOTO sw
    CASE '&': rch(); val := val  &  rdval();  GOTO sw
    CASE '^': rch(); val := val XOR rdval();  GOTO sw

    CASE '<': val := val << 1;                GOTO nxt
    CASE '>': val := val >> 1;                GOTO nxt

    CASE '=': print(val); newline();          GOTO recover

    CASE 'S': { LET type = rch()
                rch()
                !rdvaraddr(type) := val
                GOTO sw
              }

    CASE 'T': rch()
            { LET n = rdn()
              LET k = bitsperword=32 -> 5, 4
              IF n<=0 DO n := 1
              FOR i=0 TO n-1 DO
              { IF i REM k = 0 DO praddr(val+i)
                print(cont(val+i))
              }
              newline()
              GOTO sw
            }

    CASE '$': rch()
              UNLESS ch='B' | ch='C' | ch='D' | ch='F' |
                     ch='O' | ch='S' | ch='U' | ch='X' DO
              { writef("Valid style letters are: BCDFOSUX*n")
                GOTO nxt
              }
              style := ch
              GOTO nxt

    CASE 'D': writef("*nCintcode memory dumped to DUMP.mem*n")
              sys(Sys_dumpmem, 6) // Dump the memory (context=6)
              GOTO recover

    CASE 'N': val := nextpc(val)
    CASE 'I': prinstr(val); newline(); GOTO recover

    CASE 'X':  // Equivalent to G4B9C
         val := gptr!4  // set breakpoint 9 at clihook and resume
         GOTO caseb

    CASE 'Z':  // Equivalent to P1B9C
         val := pptr!1  // set breakpoint 9 to current return address and resume

    caseb:
    CASE 'B':  // Set, clear or display breakpoints.
     { LET comch = ch
       TEST comch='B' THEN rch()       // For B
                      ELSE ch := '9'   // For X or Z
       IF '0'<=ch<='9' DO
       { LET n = ch - '0'  // Set or Clear a break point.
         bpt_addr!n := 0
         IF val=0 GOTO nxt
         checkaddr(val>>B2Wsh)
         FOR i = 0 TO 9 IF bpt_addr!i=val DO bpt_addr!i := 0
         bpt_addr!n, bpt_instr!n := val, 0%val
         GOTO comch='B' -> nxt, resume
       }
       UNLESS ch='*n' DO newline()
       FOR i = 0 TO 9 DO  // List all breakpoints.
       { LET ba=bpt_addr!i
         UNLESS ba=0 DO
         { writef("%n:  ", i)
           writearg(ba)
           newline()
         }
       }
       GOTO recover
     }

    CASE 'M':  // Set or clear memory watch address
               checkaddr(val)
               TEST val THEN writef("*nWatch address: %n*n", val)
                        ELSE writef("*nWatch unset*n")
               sys(Sys_watch, val)
               GOTO recover

resume:
    CASE 'C': // Continue Cintcode execution.
             { LET pc = trapregs!r_pc
               newline()
               FOR i = 0 TO 9 IF pc=bpt_addr!i DO
               { // We are resuming at a break point
                 oldcount := trapregs!r_count
                 trapregs!r_count := 1 // Set it up to execute just
                 brkstep := TRUE   // one instruction
                 GOTO retstep
               }
               GOTO ret  // Resume execution.
             }

    CASE '\': oldcount := trapregs!r_count // Single step execution.
              trapregs!r_count := 1
              snglstep := TRUE
              GOTO retstep

    CASE ',':  // Move down one stack frame and output it.
             { LET a = pptr!0>>B2Wsh
               IF pptr=cptr DO { writef(" Base of stack*n")
                                 GOTO recover
                               }
               fsize := pptr-a
               pptr := a
               wrframe()
               GOTO recover
             }

    CASE ';': IF cptr DO
              { LET c = cont(cptr+co_parent)
                IF c<=0 DO
                { writef(" A root coroutine has no parent*n")
                  GOTO recover
                }
                cptr := c
              }
              GOTO newc

    CASE '.': cptr := cont(gptr+g_currco)
              GOTO newc

    CASE ']': cptr := cont(cptr+co_list)
              IF cptr=0 DO { writef(" End of coroutine list*n")
                             GOTO recover
                           }
              GOTO newc

    CASE '[': cptr := cont(gptr+g_colist)

newc:         UNLESS cptr DO
              { writef("No such coroutine*n")
                GOTO recover
              }
              TEST cptr=cont(gptr+g_currco)
              THEN pptr := regs!r_p>>B2Wsh
              ELSE pptr := cont(cptr+co_pptr)>>B2Wsh
              fsize := cptr + 6 + cptr!co_size - pptr
              wrcortn()
              GOTO recover

  }

ret:
  // Set BRK instructions at the breakpoint and resume.
  FOR i = 0 TO 9 DO { LET ba=bpt_addr!i // Set all breakpoints.
                      IF ba DO 0%ba := f_brk
                    }
retstep:
  // Resume execution without setting BRK instructions at the breakpoints.
  // This is used by the '\' command and when resuming from a breakpoint.

  // Must ensure that regs is restored to its original value.
  regs := trapregs

//sawritef("sadebug: retstep reached*n")
//  rtn_insadebug!rootnode := FALSE
  RESULTIS TRUE  // Successful return from sadebug
}

AND prprompt() BE
{ 
  writef("** ")  // Standalone prompt
}

AND wrcortn() BE
{ LET size = cont(cptr+co_size)
  LET hwm = size+6
  writef(" %i7: ", cptr)
  writes("  Coroutine:")
  writearg(cont(cptr+co_fn))
  writef("  Parent %n", cptr!co_parent)
  WHILE cont(cptr+hwm)=stackword DO hwm:=hwm-1
  writef("  Stack %n/%n*n", hwm-6, size)
  prprompt()
  wrch(' ')
  wrframe()
}

AND wrframe() BE
{ writef("%i8:", pptr)
  TEST pptr=cptr
  THEN writef("  #StackBase#")
  ELSE writearg(pptr!2)
  FOR i=3 TO 6 IF i<fsize DO print(cont(pptr+i))
  newline()
  IF fsize>7 DO
  { prprompt()
    writef("          ")
    FOR i = 7 TO 11 IF i<fsize DO print(cont(pptr+i))
    newline()
  }
  IF fsize>12 DO
  { prprompt()
    writef("          ")
    FOR i = 12 TO 16 IF i<fsize DO print(cont(pptr+i))
    newline()
  }
  IF fsize>17 DO
  { prprompt()
    writef("          ")
    FOR i = 17 TO 21 IF i<fsize DO print(cont(pptr+i))
    newline()
  }
}

AND writearg(n) BE
{ LET name = fname(n)
  TEST bitsperword=32
  THEN // Write value in a field width of 21
       TEST name
       THEN { LET len = name%0
              WHILE len>0 & name%len=' ' DO len := len-1
              FOR i = len+1 TO 13 DO wrch(' ')
              FOR i = 1 TO len DO wrch(name%i)  // MR 17/11/06
            }
       ELSE TEST globword<=n<=globword+gptr!0
            THEN writef("       #G%z3#", n-globword)
            ELSE TEST -10000000<=n<=10000000
                 THEN writef("  %iB", n)
                 ELSE writef("   #x%x8", n)
  ELSE // Write value in a field width of 21
       TEST name
       THEN { LET len = name%0
              WHILE len>0 & name%len=' ' DO len := len-1
              FOR i = len+1 TO 21 DO wrch(' ')
              FOR i = 1 TO len DO wrch(name%i)  // MR 17/11/06
            }
       ELSE TEST globword<=n<=globword+gptr!0
            THEN writef("               #G%z3#", n-globword)
            ELSE TEST -10000000<=n<=10000000
                 THEN writef("  %iJ", n)
                 ELSE writef("   #x%xG", n)
}

AND fname(f) = VALOF
{ LET nameoffset = bitsperword=32 -> 3, 2
  LET n = (f>>B2Wsh) - nameoffset
  UNLESS (f&(bytesperword-1))=0 &
         membase+2<n<=memlim RESULTIS 0 // MR 25/9/03
  IF n!-1=entryword & n%0=11 RESULTIS n 
  RESULTIS 0
}

AND rdn() = VALOF
{ LET res = 0
  WHILE '0'<=ch<='9' DO { res := res*10 + ch - '0'; rch() }
  RESULTIS res
}

AND rdvaraddr(type) = VALOF
{ LET base, lim, n = ?, ?, ?
  UNLESS '0'<=ch<='9' DO error()
  n := rdn()
  SWITCHON type INTO
  { DEFAULT:   error()
    CASE 'P': base, lim := pptr,   fsize;           ENDCASE
    CASE 'G': base, lim := gptr,   gptr!g_globsize; ENDCASE
    CASE 'R': base, lim := regs,   r_upb;           ENDCASE
    CASE 'V': base, lim := vars,   9;               ENDCASE
  //CASE 'W': base, lim := crntcb, tcb_upb;         ENDCASE
    CASE 'A': base, lim := 0,      memlim;          ENDCASE
  }
  UNLESS 0<=n<=lim DO error()
  RESULTIS base + n
}

AND rdval() = VALOF
{ LET res, radix = 0, 10

  SWITCHON ch INTO
  { DEFAULT:   error()

    CASE 'G':  rch()
               IF '0'<=ch<='9' RESULTIS !rdvaraddr('G')
               RESULTIS gptr

    CASE 'P':  rch()
               IF '0'<=ch<='9' RESULTIS !rdvaraddr('P')
               RESULTIS pptr

    CASE 'R':  rch()
               IF '0'<=ch<='9' RESULTIS !rdvaraddr('R')
               RESULTIS regs

    CASE 'V':  rch()
               IF '0'<=ch<='9' RESULTIS !rdvaraddr('V')
               RESULTIS vars

    CASE 'A':  rch()
               IF '0'<=ch<='9' RESULTIS !rdvaraddr('A')
               RESULTIS 0

    CASE '*'': rch(); res := lch; rch();  RESULTIS res

    CASE '#':  radix := 16
               rch()
               IF ch='O' DO { radix := 8; rch() }

    CASE '0': CASE '1': CASE '2': CASE '3': CASE '4': 
    CASE '5': CASE '6': CASE '7': CASE '8': CASE '9': 
               { LET d = 100
                 IF '0'<=ch<='9' DO d := ch-'0'
                 IF 'A'<=ch<='F' DO d := ch-'A'+10
                 IF d>=radix RESULTIS res
                 res := res*radix+d
                 rch()
               } REPEAT
  }
}

AND praddr(a) BE
{ LET type, base = 'A', 0
  IF pptr <= a <= pptr+fsize           DO type, base := 'P', pptr
  IF gptr <= a <= gptr+gptr!g_globsize DO type, base := 'G', gptr
  IF vars <= a <= vars+9               DO type, base := 'V', vars
  IF regs <= a <= regs+r_upb           DO type, base := 'R', regs
  writef("*n%c%i5:", type, a-base)
}

AND print(n) BE
TEST bitsperword=32
THEN // Write 32-bit value in given style in a field width of 13
     SWITCHON style INTO
     { DEFAULT:   error();                 RETURN
       CASE 'C':  { LET p = @n
                    writes("         ")
                    FOR i = 0 TO 3 DO
                    { LET ch = p%i
                      wrch(32<=ch<=127 -> ch, '.')
                    }
                    RETURN
                  }
       CASE 'B':  writef( "  %bW", n);     RETURN
       CASE 'D':  writef( "  %IB", n);     RETURN
       CASE 'F':  writearg(n);             RETURN
       CASE 'O':  writef( "  %OB", n);     RETURN
       CASE 'S':  checkaddr(n)
                  writef( "  %S",  n);     RETURN
       CASE 'U':  writef( "  %UB", n);     RETURN
       CASE 'X':  writef( "     %X8", n);  RETURN
     }
ELSE // Write 64-bit value in given style in a field width of 21
     SWITCHON style INTO
     { DEFAULT:   error();                 RETURN
       CASE 'C':  { LET p = @n
                    writes(" ")
                    FOR i = 0 TO 7 DO
                    { LET ch = p%i
                      wrch(32<=ch<=127 -> ch, '.')
                    }
                    RETURN
                  }
       CASE 'B':  TEST bitsperword=32
                  THEN writef( " %32b ", n)
                  ELSE writef( " %64b ", n)
                  RETURN

       CASE 'D':  TEST bitsperword=32
                  THEN writef( " %10i ", n)
                  ELSE writef( " %20i ", n)
                  RETURN

       CASE 'F':  writearg(n);             RETURN

       CASE 'O':  TEST bitsperword=32
                  THEN writef( " %11o ", n)
                  ELSE writef( " %22o ", n)
                  RETURN

       CASE 'S':  checkaddr(n)
                  writef( " %S ",  n);     RETURN

       CASE 'U':  TEST bitsperword=32
                  THEN writef( " %10U ", n)
                  ELSE writef( " %20U ", n)
                  RETURN

       CASE 'X':  TEST bitsperword=32
                  THEN writef( " %8x ", n)
                  ELSE writef( " %16x ", n)
                  RETURN
     }

AND checkaddr(a) = VALOF
{ UNLESS membase<=a<=memlim DO error()
  RESULTIS a
}

AND cont(a) = !checkaddr(a)

AND error() BE { writes("  ??*n"); longjump(recp, recl) }

AND wrfcode(f) BE
{ LET s = VALOF SWITCHON f&31 INTO
  { DEFAULT:
    CASE  0: RESULTIS "     -     K   LLP     L    LP    SP    AP     A"
    CASE  1: RESULTIS " FLTOP    KH  LLPH    LH   LPH   SPH   APH    AH"
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
    CASE 30: RESULTIS "  JEQ0  JNE0  JLS0  JGR0  JLE0  JGE0 ST1P4 SELLD"
    CASE 31: RESULTIS " JEQ0$ JNE0$ JLS0$ JGR0$ JLE0$ JGE0$    MW SELST"
  }
  LET n = f>>5 & 7
  FOR i = 6*n+1 TO 6*(n+1) DO wrch(s%i)
}

AND prinstr(pc) BE
{ LET a, b, c = 0, 0, 0
  writef(" %i7: ", pc)
  checkaddr(pc>>B2Wsh)
  wrfcode(0%pc)
  SWITCHON instrtype(0%pc) INTO
  { DEFAULT:
    CASE '0':                                      RETURN
    CASE '1': a := gb(pc+1);                       ENDCASE
    CASE '2': a := gh(pc+1);                       ENDCASE
    CASE 'F': a := gb(pc+1)
              writef("  %n", a)
              IF a=fl_mk DO
              { LET m = gw(pc+2)
                LET e = gw(pc+6)
                writef("  %n %n", m, e)
              }
              RETURN
    CASE 'X': a  := gb(pc+1)
              b  := gb(pc+2)
              writef("  %n %n", a, b)
              RETURN
    CASE 'Y': a  := gb(pc+1)
              b  := gb(pc+2)
              c  := gb(pc+3)
              writef("  %n %n %n", a, b, c)
              RETURN

    CASE '4': a  := gw(pc+1);                      ENDCASE
    CASE 'R': a  := pc+1 + gsb(pc+1);              ENDCASE
    CASE 'I': pc := pc+1 + 2*gb(pc+1) & #xFFFFFFFE
              a  := pc + gsh(pc);                  ENDCASE
  }
  TEST -10_000_000 < a < 10_000_000
  THEN writef("  %n", a)
  ELSE writef("  #%x8", a)
  vars!9 := a
}

AND gb(pc) = 0%pc

AND gsb(pc) = 0%pc<=127 -> 0%pc, 0%pc-256

AND gsh(pc) = VALOF
{ LET h = gh(pc)
  RESULTIS h<=#x7FFF -> h, h - #x10000
}

AND gh(pc) = VALOF
{ LET w = ?
  LET p = @w  // Designed to work on both Big and Little Ender M/Cs.
  p%0, p%1, p%2, p%3 := 0%pc, 0%(pc+1), 0%pc, 0%(pc+1)
  RESULTIS w & #xFFFF
}

AND gw(pc) = VALOF
{ LET w = ?
  LET p = @w  // Designed to work on both Big and Little Ender M/Cs.
  p%0, p%1, p%2, p%3 := 0%pc, 0%(pc+1), 0%(pc+2), 0%(pc+3)
  RESULTIS w
}

AND instrtype(f) = "F0000000000RI10000000000000RIRI*
                  *124111111111111111110000RIRIRIRI*
                  *12411111111111111111000000RIRIRI*
                  *1242222222222222222200000000RIRI*
                  *124000000000000000BL00000000RIRI*
                  *12400000000000000000000000RIRIRI*
                  *1240000000000?2?0000000000000004*
                  *124000000000012?00000000000000XY"%f

AND nextpc(pc) = VALOF SWITCHON instrtype(0%pc) INTO
                       { DEFAULT:
                         CASE '0': RESULTIS pc+1
                         CASE '1':
                         CASE 'F': // FLTOP MK exponent
                                   // FLTOP op
                                   IF 0%(pc+1)=fl_mk RESULTIS pc+3
                                   RESULTIS pc+2
                         CASE 'R':
                         CASE 'I': RESULTIS pc+2
                         CASE 'X':               // SELLD len sh
                         CASE '2': RESULTIS pc+3
                         CASE 'Y': RESULTIS pc+4 // SELST op len sh
                         CASE '4': RESULTIS pc+5
                         CASE 'B': pc := pc+2 & #xFFFFFFFE
                                   RESULTIS pc + 4*gh(pc) + 6
                         CASE 'L': pc := pc+2 & #xFFFFFFFE
                                   RESULTIS pc + 2*gh(pc) + 6
                       }

AND rch() BE { lch := rdch(); ch := capitalch(lch) }

