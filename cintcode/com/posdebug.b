// The program allows the user to inspect a memory dump of
// the Cintpos system.

// Implemented by Martin Richards (c) August 2005

// Usage:

// dumpdebug [FROM <image>]

// The FROM argument specifies the dump image file,
// the default DUMP.mem



SECTION " dumpdebug"

GET "libhdr"
GET "manhdr"

GLOBAL
{ eof: ug
  pptr
  gptr
  cptr
  ctcb
  fsize

  regs
  tasktab
  devtab
  membase
  memlim
  memupb
  context
  trapregs       // =bootregs if context=3, =klibregs otherwise
                 // but not valid if context is 1 or 2
  ch
  lch
  rch
  val
  vars
  style
  bpt_addr
  bpt_instr

  cohandid
  imagefilename  // 0 or name of the image file

  // Variables used by getimage, nextword, and mem.
  datastream       // scb of the image file
  blkcount         // repetition count if neg, otherwise size of block
  currword         // current word from image file
  pagetab          // The page table
  pagenoupb        // The page table upb

  rec_p; rec_l   // Recovery label for longjump
}

MANIFEST {
  maxpri    = maxint

  sectnamesize = (11 + bytesperword)/bytesperword
  routnamesize = (11 + bytesperword)/bytesperword
  nameoffset   = -routnamesize
  vecupb       = 5000

  r_a=0
  r_b
  r_c
  r_p
  r_g
  r_st
  r_pc
  r_count
  r_mw
  r_upb = r_mw

  // Contants used by getimage and mem.
  pageshift = 12   // 12 is 15 seconds faster than 10
  pageupb = (1<<pageshift)-1
  pagemask = pageupb
}

LET start() BE
{ LET argv       = VEC 50
  AND datv       = VEC 1
  AND datstrings = VEC 12
  AND sysin      = input()
  AND sysout     = output()
  AND imagefilename = "DUMP.mem"
  AND taskcount  = 0

  UNLESS rdargs("FROM", argv, 50) DO
  { writes("bad arguments for DUMPDEBUG*n")
    stop(20)
  }

  pagetab := 0
  cohandid := sysin!scb_task

  IF argv!0 DO imagefilename := argv!0
  IF imagefilename UNLESS getimage(imagefilename) DO
  { writef("Unable to load image file %s*n", imagefilename)
    RETURN
  }

  rec_p, rec_l := level(), fin

  tasktab := mem(rootnode+rtn_tasktab)
  devtab  := mem(rootnode+rtn_devtab)
  membase := mem(rootnode+rtn_membase)
  memlim  := mem(rootnode+rtn_memsize)
  context := mem(rootnode+rtn_context)
  // context = 1   SIGINT received
  // context = 2   SIGSEGV received
  // context = 3   dump caused by fault in BOOT of standalone debug
  // context = 4   dump requested by user calling sys(Sys_quit, -2)
  // context = 5   non zero user fault code
  // context = 6   dump requested in standalone debug

  SWITCHON context INTO
  { DEFAULT: sawritef("*nUnknown context = %n*n", context)

    CASE 1:
    CASE 2: FOR r = 0 TO 7 DO bootregs!r := 0
            bootregs!r_p := mem(rootnode+rtn_lastp)
            bootregs!r_g := mem(rootnode+rtn_lastg)

    CASE 3: // In BOOT
    CASE 6: // In sadebug in BOOT
            trapregs := bootregs; ENDCASE

    CASE 4: // sys(Sys_quit, -2) called
    CASE 5: // Non zero user code 
            trapregs := klibregs; ENDCASE
  }

  writef("*nImage File: %s", imagefilename)
  IF memdatstamp(datv) DO
  { dat_to_strings(datv, datstrings)

    writef("           Dated:  %s %s*n", @datstrings!0, @datstrings!5)
  }
  newline()

  SWITCHON context INTO
  { DEFAULT:  writef("Unknown reason (%n) for dumping memory", context)
              ENDCASE
    CASE 1:   writef("Dump caused by signal SIGINT")
              ENDCASE
    CASE 2:   writef("Dump caused by signal SIGSEGV")
              ENDCASE
    CASE 3:   writef("Dump caused by fault in BOOT or standalone debug")
              ENDCASE
    CASE 4:   writef("Dump by user probably calling: dumpmem")
              ENDCASE
    CASE 5:   writef("Dump caused by non zero user fault code")
              ENDCASE
    CASE 6:   writef("Dump requested in standalone debug")
              ENDCASE
  }
  newline()

  { LET st = mem(rootnode+rtn_lastst)
    SWITCHON st INTO
    { DEFAULT: sawritef("Unexpected ST value: %n*n", st); ENDCASE
      CASE 0:  sawritef("while in user code -- interrupts enabled*n"); ENDCASE
      CASE 1:  sawritef("while in KLIB -- interrupts disabled*n");     ENDCASE
      CASE 2:  sawritef("while in BOOT -- interrupts disabled*n");     ENDCASE
      CASE 3:  sawritef("while in the ISR -- interrupts disabled*n");  ENDCASE
    }
  }

  
//  wrregs("BOOT Registers", bootregs)
//  wrregs("KLIB Registers", klibregs)
//  wrregs("SAVE Registers", saveregs)
//  wrregs("ISR  Registers", isrregs)

  //dumprootnode()

  IF mem(klibregs+r_st)=3 DO
  { writef("*nThe Interrupt Service Routine is currently running*n*n")
  }

  // Use exclusive input mode while in dumpdebug
  sendpkt(notinuse, cohandid, Action_exclusiveinput, 0, 0, TRUE)
  dumpdebug()
  sendpkt(notinuse, cohandid, Action_exclusiveinput, 0, 0, FALSE)

fin:
  deleteimage()
}

AND rch() BE
{ lch := sendpkt(notinuse, cohandid, Action_exclusiverdch, 0, 0)
  sawrch(lch)
  ch := capitalch(lch)
}

AND memdatstamp(v) = VALOF
{ LET tv = rootnode+rtn_days
 
  v!0 := mem(tv+0)
  v!1 := mem(tv+1)

  RESULTIS TRUE
}

AND dumpdebug() = VALOF
{ 
  rec_p, rec_l := level(), recover // recovery point for error()

  // Initialise the standalone debugger
  membase := mem(rootnode+rtn_membase)
  memlim  := membase + mem(rootnode+rtn_memsize)
  style   := 'F'                   // Default printing style
  val     := 0

  // Get the breakpoint vectors from the rootnode

  bpt_addr  := mem(rootnode+rtn_bptaddr)
  bpt_instr := mem(rootnode+rtn_bptinstr)
  vars      := mem(rootnode+rtn_dbgvars)

  FOR i = 0 TO 9 DO            // Remove all BRK instructions (if any)
  { LET ba = mem(bpt_addr+i)
    //writef("bpt %n: addr: %i6    instr: %n*n", i, ba, mem(bpt_instr+i))
    IF ba DO stmemb(0, ba, mem(bpt_instr+i))
  }

  ctcb, cptr, regs := 0, 0, 0
  selectask(-1)  // Select the current task

  { LET gn = mem(regs+r_pc) - globword
    LET code = mem(rootnode + rtn_abortcode)
    LET mess =  VALOF SWITCHON code INTO
                { CASE   1: RESULTIS "Illegal instruction"
                  CASE   2: RESULTIS "BRK instruction"
                  CASE   3: RESULTIS "Zero count"
                  CASE   4: TEST 0<=gn<=mem(gptr+0)
                            THEN RESULTIS "G%n unassigned"
                            ELSE RESULTIS "Negative pc"
                  CASE   5: RESULTIS "Division by zero"
                  CASE  10: RESULTIS "Cintasm single step"
                  CASE  11: RESULTIS "Watch addr: %$%i7 value: %i8"
                  CASE  12: RESULTIS "Indirect address out of range: %$%$%$%n"
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

    writef("*nLast abort code: %n  ", mem(rootnode+rtn_abortcode))
    writef(mess, gn, mem(1), mem(2), mem(3))
    newline()
    GOTO recover
  }

recover:
  ch := '*n'
nxt:                          // Main loop for debug commands
  IF ch='*n' DO prprompt()

  rch() REPEATWHILE ch='*s'
sw:
  SWITCHON ch INTO

  { DEFAULT: error()

    CASE endstreamch: newline(); GOTO ret 

    CASE '*s':
    CASE '*n':GOTO nxt
      
    CASE '?':
       writes("*n?          Print list of dumpdebug commands*n")
       writes("Gn Pn Rn Vn Wn An          Variables*n")
       writes("G  P  R  V  W  A           Pointers*n")
       writes("123 #o377 #FF03 'c         Constants*n")
       writes("**e /e %e +e -e |e &e       Dyadic operators*n")
       writes("!e                         Subscription*n")
       writes("< >                        Left/Right shift one place*n")
       writes("$c $d $f $b $o $s $u $x    Set the print style*n")
       writes("SGn SPn SRn SVn SAn        Store current value*n")
       writes("Sn         Select task n*n")
       writes("S.         Select current task*n")
       writes("=          Print current value*n")
       writes("Tn         Print n consecutive locations*n")
       writes("I          Print current instruction*n")
       writes("N          Print next instruction*n")
       writes("B          List the current breakpoints*n")
       writes("Q          Quit -- exit from dumpdebug*n")
       writes(".          Move to current coroutine*n")
       writes(",          Move down one stack frame*n")
       writes(";          Move to parent coroutine*n")
       writes("[          Move to first coroutine*n")
       writes("]          Move to next coroutine*n")
       GOTO recover

    CASE '0': CASE '1': CASE '2':
    CASE '3': CASE '4': CASE '5':
    CASE '6': CASE '7': CASE '8':
    CASE '9': CASE '#': CASE '*'':
    CASE 'G': CASE 'P': CASE 'R':
    CASE 'V': CASE 'W': CASE 'A':
              val := rdval();                 GOTO sw

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
    CASE '|': rch(); val := val  |  rdval();        GOTO sw
    CASE '&': rch(); val := val  &  rdval();        GOTO sw

    CASE '<': val := val << 1;                GOTO nxt
    CASE '>': val := val >> 1;                GOTO nxt

    CASE '=': print(val); newline();          GOTO recover

    CASE 'S': { LET type = ?
                rch()
                // Is it a task selection?
                IF ch='.' DO
                { newline()      // Select regs, p and g at time of
                  selectask(-1)  // last leaving cinterp.
                  rch()
                  GOTO sw
                }
                IF '0'<=ch<='9' DO
                { // Select a specified task
                  selectask(rdval())
                  GOTO sw
                }
                // No -- it must be a store instruction
                type := ch
                rch()
                stmem(rdvaraddr(type), val) // Only SVi
                GOTO sw
              }


    CASE 'T': rch()
            { LET n = rdn()
              IF n<=0 DO n := 1
              FOR i=0 TO n-1 DO
              { IF i REM 5 = 0 DO praddr(val+i)
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

    CASE 'Q': newline()
              RETURN
         
    CASE 'N': val := nextpc(val)
    CASE 'I': prinstr(val); newline(); GOTO recover

    CASE 'B':  // List the current breakpoints.
       newline()
       FOR i = 0 TO 9 DO
       { LET ba=mem(bpt_addr+i)
         IF ba DO
         { writef("%n:  ", i)
           writearg(ba)
           newline()
         }
       }
       GOTO recover

    CASE ',':  // Move down one stack frame and output it.
             { LET a = cont(pptr+0)>>2
               IF a=cptr | a=0 DO { writef(" Base of stack*n")
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
                { writef(" There is no parent coroutine*n")
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
              THEN pptr := cont(regs+r_p)>>2
              ELSE pptr := cont(cptr+co_pptr)>>2
              fsize := cptr + 6 + cont(cptr+co_size) - pptr
              wrcortn()
              GOTO recover
  }

ret:
retstep:
}

AND prprompt() BE
{ LET id = -1
  LET st = regs!r_st
  LET letter = '?'
//sys(Sys_tracing, FALSE)
//sawritef("ctcb=%n*n", ctcb)
  IF ctcb DO
  { id     := mem(ctcb+tcb_taskid)
    letter := mem(ctcb+tcb_active) -> 'a', 'd'

  }
  IF st=1 DO letter := 'k'
  IF st=2 DO letter := 'b'
  IF st=3 DO letter := 'i'
  sawritef("%c%n# ", letter, id)  // Standalone prompt
}

AND prpkt(pkt) BE
{ writef("%i6:   PKT:", pkt)
  FOR i = pkt_link TO pkt_arg1 DO writearg(mem(pkt+i))
  newline()
}

AND dumprootnode() BE
{ writef("*nRootnode at %n*n*n", rootnode)

  writef("  tasktab    %iA*n", mem(rtn_tasktab+rootnode))
  writef("  devtab     %iA*n", mem(rtn_devtab+rootnode))
  writef("  tcblist    %iA*n", mem(rtn_tcblist+rootnode))
  writef("  crntask    %iA  ", mem(rtn_crntask+rootnode))
  writef(" task %n*n", mem(tcb_taskid+mem(rtn_crntask+rootnode)))
  writef("  blklist    %iA*n", mem(rtn_blklist+rootnode))
  writef("  clkintson  %iA*n", mem(rtn_clkintson+rootnode))
  writef("  clwkq      %iA*n", mem(rtn_clwkq+rootnode))
  writef("  memsize    %iA*n", mem(rtn_memsize+rootnode))
  writef("  info       %iA*n", mem(rtn_info+rootnode))
  writef("  sys        %iA*n", mem(rtn_sys+rootnode))
  writef("  blib       %iA*n", mem(rtn_blib+rootnode))
  writef("  boot       %iA*n", mem(rtn_boot+rootnode))
  writef("  klib       %iA*n", mem(rtn_klib+rootnode))
  writef("  abortcode  %iA*n", mem(rtn_abortcode+rootnode))
  writef("  context    %iA*n", mem(rtn_context+rootnode))
  writef("  lastp      %iA*n", mem(rtn_lastp+rootnode))
  writef("  lastg      %iA*n", mem(rtn_lastg+rootnode))
  writef("  days       %iA*n", mem(rtn_days+rootnode))
  writef("  msecs      %iA*n", mem(rtn_msecs+rootnode))
  writef("  idletcb    %iA*n", mem(rtn_idletcb+rootnode))

  writef("*nTasktab at %n upb=%n*n", tasktab, mem(tasktab))
  FOR i = 1 TO mem(tasktab) IF mem(tasktab+i) DO
  { LET tcb = mem(tasktab+i)
    LET id, pri, wkq = mem(tcb+tcb_taskid), mem(tcb+tcb_pri), mem(tcb+tcb_wkq)
    LET taskname = tcb+tcb_namebase // MR 17/01/05
    writef("%i6: TCB for task %i3,    pri %i5  ", tcb, id, pri)
    FOR i = 1 TO memb(taskname, 0) DO wrch(memb(taskname, i))
    newline()
    WHILE wkq DO
    { LET pkt = wkq
      prpkt(pkt)
      wkq := mem(wkq)
    }
  }
  writef("*nDevtab at %n upb=%n*n", devtab, mem(devtab))
  FOR i = 1 TO mem(devtab) IF mem(devtab+i) DO
  { LET dcb = mem(devtab+i)
    LET id, type, wkq = mem(dcb+Dcb_devid), mem(dcb+Dcb_type), mem(dcb+Dcb_wkq)
    writef("%i6: DCB for device %i3 type %n ", dcb, id, type)
    SWITCHON type INTO
    { DEFAULT:          writef("(unknown)"); ENDCASE

      CASE Devt_clk:    writef("(clock)");  ENDCASE
      CASE Devt_ttyin:  writef("(ttyin)");  ENDCASE
      CASE Devt_ttyout: writef("(ttyout)"); ENDCASE
      CASE Devt_fileop: writef("(fileop)"); ENDCASE
      CASE Devt_tcpdev: writef("(tcpdev)"); ENDCASE
    }
    newline()
    IF id=-1 DO wkq := mem(rtn_clwkq+rootnode)
    WHILE wkq DO
    { LET pkt = wkq
      prpkt(pkt)
      wkq := mem(wkq)
    }
  }  
}

AND dumpmemory() BE
{ LET blocklist  = mem(rootnode+rtn_membase)
  LET topofstore = mem(rootnode+rtn_memsize)
  LET a = blocklist
  LET free, used, n = 0, 0, 0
  LET largest_free = 0
  LET joinfree = 0
  LET sectnames, routnames, globinit = 0, 0, 0
  LET constr = output()
  LET outstr = 0

  writef("*nMap of free and allocated blocks in %n..%n*n*n", membase, memlim)

  WHILE mem(a) DO
  { LET size = mem(a)
    LET freeblk = (size&1)=1

    IF testflags(flag_b) GOTO exit

    TEST freeblk
    THEN { // Free block
           size := size-1
           free := free + size
           joinfree := joinfree + size
           IF joinfree > largest_free DO largest_free := joinfree
         }
    ELSE { // Used block
           used := used + size
           joinfree := 0
         }

    UNLESS size>=0 & a+size<=topofstore DO
    { writef("******Store chain corrupt!!*n*
              *Noticed at %n*n", a)
      BREAK
    }

    writef("%i8:%i7 ", a, size)
    IF freeblk DO { writes("free "); GOTO nxt }

    { LET creator = a+size-5
      LET len = memb(creator, 0)
      writef(" allocated by: ")
      FOR i = 1 TO len DO wrch(memb(creator, i))
      FOR i = len+1 TO 16 DO wrch(' ')
    }

    IF a = (rootnode-1) DO { writes("Rootnode"); GOTO nxt }
    IF mem(a+3) = sectword & memb(a+4, 0) = 11 DO
    { LET name = a+4
      writef("Section ")
      FOR i = 1 TO memb(name, 0) DO wrch(memb(name, i))
      GOTO nxt
    }

    FOR id = 1 TO mem(tasktab) DO
    { LET t = mem(tasktab+id)
      IF t DO
      { LET p, g = mem(t+tcb_sbase), mem(t+tcb_gbase)
        IF a+1=p DO { writef("Task %n stack", id); GOTO nxt }
        IF a+1=g DO { writef("Task %n global vector", id); GOTO nxt }
        IF a+1=t DO { writef("Task %n TCB", id); GOTO nxt }
        IF g & a>500 FOR gn = 1 TO mem(g) IF a+1=mem(g+gn) DO
                     { writef("Task %n G%n => ", id, gn)
                       GOTO dump
                     }
      }
    }
dump:
    writes("*n         ")
    FOR i = 1 TO 5 DO { LET n = mem(a+i)
                        TEST -10_000_000<=n<=10_000_000
                        THEN writef("%iA ", n)
                        ELSE writef("#x%x8 ", n)
                      }
nxt: 
    newline()
    a := a + size
  }

  writef("End of block list = %n*n", a)
  topofstore := a

  writef("*nLargest contiguous free area: %n words*n", largest_free)
  writef("Totals: %n words available, %n used, %n free*n*n",
          used+free, used, free)

exit:
}

AND dumptask(tcb) BE
{ LET id = mem(tcb+tcb_taskid)
  LET seglist, pkt = 0, 0
  LET state, flags, cliseg = 0, 0, 0
  LET dead = FALSE             // Assume activated unless proved otherwise
  LET pkt = mem(tcb_wkq+tcb)
  regs, pptr, gptr := 0, 0, 0
  UNLESS tcb RETURN

  seglist := mem(tcb_seglist+tcb)
  pkt   := mem(tcb + tcb_wkq)
  state := mem(tcb + tcb_state)
  flags := mem(tcb + tcb_flags)
  dead  := (state & State_dead) = State_dead
  cliseg := mem(seglist+4)    // The CLI segment

  writef("*n################### Task %i2:", id)
  wrch(' ')
  FOR i = 1 TO memb(tcb+tcb_namebase, 0) DO wrch(memb(tcb+tcb_namebase, i))
  wrch(' ')
  FOR i = memb(tcb+tcb_namebase, 0)+1 TO 15+16 DO wrch('#')
  writef("*n*n")
  writef("tcb=%n:", tcb)
  writef(" pri %n,", mem(tcb + tcb_pri))
  writef(" stksz %n,", mem(tcb+tcb_stsiz))
  writef(" state=#b%b4, flags=#b%b6*n", mem(tcb+tcb_state), mem(tcb+tcb_flags))

  { LET state = mem(tcb+tcb_state)
    writes("*nState: ")
    SWITCHON state & #b1100 INTO
    { CASE #b0000: writef(" running");     ENDCASE
      CASE #b0100: writef(" waiting");     ENDCASE
      CASE #b1000: writef(" interrupted"); ENDCASE
      CASE #b1100: dead := TRUE
                   writef(" dead");        ENDCASE
    }
    UNLESS (state & #b0010)=0 DO writef(" held")
    UNLESS (state & #b0001)=0 DO writef(" with packet")
    newline()
  }

  writef("*nPackets: wkq=%n*n", pkt)
  UNTIL pkt<=0 DO
  { prpkt(pkt)
    pkt := mem(pkt_link+pkt)
  }

  IF dead DO
  { writef("*nNo stack or global vector since the task is dead*n")
    RETURN
  }

  regs, ctcb, cptr := 0, tcb, 0

  TEST mem(rootnode+rtn_crntask)=ctcb
  THEN { // klibregs is the register set passed to the interpreter by BOOT
         // these are normally the registers to use.
         regs := klibregs // The default register set
         // If st=3 we are in the interrupt service routine
         // so we will use the registers that were saved when the
         // interrupt occurred.
         IF mem(regs+r_st)=3 DO regs := saveregs
       }
  ELSE regs := @ctcb!tcb_a

  gptr  := mem(regs+r_g) >> 2
  pptr  := mem(regs+r_p) >> 2

  // Set current coroutine if in user or kernel mode and the task
  // is active
  IF mem(tcb+tcb_active) DO cptr := mem(gptr+g_currco)

  UNLESS cptr <= pptr <= cptr + mem(cptr+co_size + 6) DO cptr := 0

  fsize := 100
//sawritef("cptr=%n*n", cptr)
  IF cptr DO fsize := cptr + 6 + mem(cptr+co_size) - pptr

  wrregs("Registers", regs)

  writef("*nSeglist %n:  length %n", mem(tcb_seglist+tcb), mem(seglist))
  //FOR i = 1 TO mem(seglist) DO writef("  %n", mem(seglist+i))

  { LET segl = mem(tcb + tcb_seglist)

    FOR j = 1 TO mem(segl) DO
    { LET seg = mem(segl+j)
      LET layout = 0
      writef("*nSeg%n %i6: ", j, seg)
      WHILE seg DO
      { IF layout & (layout MOD 5)=0 DO writef("*n             ")
        wrch(' ')
        layout := layout + 1
        write_sectname(seg)
        seg := mem(seg)
      }
    }
    newline()

    IF gptr DO
    { LET gupb = mem(gptr)
      writef("*nGlobal variables at G = %n:*n", gptr)
      FOR gn = 0 TO gupb DO
      { LET w = mem(gptr+gn)
        IF gn REM 5 = 0 DO
        { LET v, gw = gptr+gn, globword+gn
          IF              mem(v+0)=gw+0 &
             (gn+1>gupb | mem(v+1)=gw+1) &
             (gn+2>gupb | mem(v+2)=gw+2) &
             (gn+3>gupb | mem(v+3)=gw+3) &
             (gn+4>gupb | mem(v+4)=gw+4) DO { gn := gn+4; LOOP }
          writef("*nG%i3:", gn)
        }
        writearg(w)
      }
      newline()
    }

    writef("*nCoroutine stacks for task %n:*n", id)  
    wrcortns(tcb)
  }
}

AND wrregs(str, regs) BE
{ writef("*n%s:*n", str)
  writef("a=%n b=%n c=%n ", mem(regs+r_a), mem(regs+r_b), mem(regs+r_c))
  writef("p=%n(%n) g=%n(%n) ", mem(regs+r_p), mem(regs+r_p)>>2,
                               mem(regs+r_g), mem(regs+r_g)>>2)
  writef("st=%n pc=%n count=%n*n", mem(regs+r_st), mem(regs+r_pc),
                                   mem(regs+r_count))
}

AND write_sectname(s) BE
{ LET name = s+3
  TEST (mem(s+2) = sectword) & (memb(s+3, 0) = 11)
  THEN FOR i = 1 TO 11 DO wrch(memb(name, i))
  ELSE writes("???????????")
}

AND checkaddr(a) = VALOF
{ UNLESS membase<=a<=memlim DO
  { writef("*n bad address %d not in %n--%n*n", a, membase, memlim)
    RESULTIS 0
  }
  RESULTIS a
}

AND cont(a) = mem(checkaddr(a))

AND wrcortns(tcb) BE
{ cptr := cont(gptr+g_colist)

//sawritef("cptr=%n pptr=%n gptr=%n regs=%n*n", cptr, pptr, gptr, regs)

  WHILE 0<cptr<=memlim DO
  { TEST cptr=cont(gptr+g_currco)
    THEN TEST 1<=mem(rootnode+rtn_context)<=2 & // SIGINT or SIGSEGV
              mem(rootnode+rtn_crntask)=tcb
         THEN pptr := mem(rootnode+rtn_lastp)
         ELSE pptr := mem(regs+r_p)>>2
    ELSE pptr := cont(cptr+co_pptr)>>2

    fsize := cptr + 6 + mem(cptr+co_size) - pptr
//sawritef("cptr=%n pptr=%n gptr=%n fsize=%n*n", cptr, pptr, gptr, fsize)

    { LET size = cont(cptr+co_size)
      LET hwm = size+6
      writef("*n%i7: ", cptr)
      IF cptr=mem(gptr+g_currco) DO writes("Current ")
      writes("Coroutine ")
      writearg(cont(cptr+co_fn))
      writef("  Parent %n", mem(cptr+co_parent))
      WHILE cont(cptr+hwm)=stackword DO hwm:=hwm-1
      writef("  Stack %n/%n*n", hwm-6, size)
      wrframe()

      // Move down one stack frame and output it.
      { LET a = mem(pptr)>>2
        IF a<cptr | a>pptr DO { writes(" Corrupt stack chain*n")
                                BREAK
                              }
        IF a=cptr | a=0    DO { writef(" Base of stack*n")
                                BREAK
                              }
        fsize := pptr-a
        pptr := a
        wrframe()
      } REPEAT
    }

    // Find next coroutine in the list
    cptr := cont(cptr+co_list)
  }
  TEST cptr THEN writef("*nCorrupt coroutine list*n")
            ELSE writef("*nEnd of coroutine list*n")
}

AND wrcortn() BE
{ LET size = cont(cptr+co_size)
  LET hwm = size+6
  writef(" %i7: ", cptr)
  writes("Coroutine ")
  writearg(cont(cptr+co_fn))
  writef("  Parent %n", mem(cptr+co_parent))
  WHILE cont(cptr+hwm)=stackword DO hwm:=hwm-1
  writef("  Stack %n/%n*n", hwm-6, size)
  prprompt()
  wrch(' ')
  wrframe()
}

AND wrframe() BE
{ writef("%i7:", pptr)
  IF pptr=cptr DO { writes("   Base of stack*n"); RETURN }
  writearg(mem(pptr+2))
  FOR i=3 TO 6 UNLESS i>=fsize DO writearg(cont(pptr+i))
  newline()
  IF fsize>7 DO
  { writef("        ")
    FOR i = 7 TO 11 UNLESS i>=fsize DO writearg(cont(pptr+i))
    newline()
  }
  IF fsize>12 DO
  { writef("        ")
    FOR i = 12 TO 16 UNLESS i>=fsize DO writearg(cont(pptr+i))
    newline()
  }
}

AND writearg(n) BE TEST isfun(n)
                   THEN { LET s = (n>>2)-3  // MR 1/11/03
//FOR i = 1 TO 11 DO writef("i=%i2  ch=%n*n", 
                          wrch(' ')
                          FOR i = 1 TO memb(s, 0) DO wrch(memb(s, i))
                          wrch(' ')
                        }
                   ELSE TEST globword<=n<=globword+1000  // MR 1/11/03
                        THEN writef("   #G%z3#    ", n-globword)
                        ELSE TEST -10_000_000<=n<=10_000_000
                             THEN writef(" %iB ", n)
                             ELSE writef("  #x%x8 ", n)

AND isfun(f) = VALOF
{ LET a = f>>2
  UNLESS (f&3)=0 & membase+4<a<=memlim RESULTIS FALSE // MR 25/9/03
  IF mem(a-4)=entryword & memb(a-3, 0)=11 RESULTIS TRUE 
  RESULTIS FALSE
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
    CASE 'P': base, lim := pptr, fsize;           ENDCASE
    CASE 'G': base, lim := gptr, gptr!g_globsize; ENDCASE
    CASE 'R': base, lim := regs, r_upb;           ENDCASE
    CASE 'V': base, lim := vars, 9;               ENDCASE
    CASE 'W': base, lim := ctcb, tcb_upb;         ENDCASE
    CASE 'A': base, lim :=    0, memlim;          ENDCASE
  }
  UNLESS 0<=n<=lim DO error()
  RESULTIS base + n
}

AND rdval() = VALOF
{ LET res, radix = 0, 10

  SWITCHON ch INTO
  { DEFAULT:   error()

    CASE 'G':  rch()
               IF '0'<=ch<='9' RESULTIS mem(rdvaraddr('G'))
               RESULTIS gptr

    CASE 'P':  rch()
               IF '0'<=ch<='9' RESULTIS mem(rdvaraddr('P'))
               RESULTIS pptr

    CASE 'R':  rch()
               IF '0'<=ch<='9' RESULTIS mem(rdvaraddr('R'))
               RESULTIS regs

    CASE 'V':  rch()
               IF '0'<=ch<='9' RESULTIS mem(rdvaraddr('V'))
               RESULTIS vars

    CASE 'W':  rch()
               IF '0'<=ch<='9' RESULTIS mem(rdvaraddr('W'))
               RESULTIS ctcb

    CASE 'A':  rch()
               IF '0'<=ch<='9' RESULTIS mem(rdvaraddr('A'))
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
  IF pptr <= a <= pptr+fsize                DO type, base := 'P', pptr
  IF gptr <= a <= gptr+mem(gptr+g_globsize) DO type, base := 'G', gptr
  IF vars <= a <= vars+9                    DO type, base := 'V', vars
  IF ctcb <= a <= ctcb+tcb_upb              DO type, base := 'W', ctcb
  IF regs <= a <= regs+r_upb                DO type, base := 'R', regs
  writef("*n%c%i5:", type, a-base)
}

AND print(n) BE SWITCHON style INTO
{ DEFAULT:   error();                 RETURN
  CASE 'C':  { LET p = @n
               writes(" ")
               FOR i = 0 TO 3 DO
               { LET ch = p%i
                 wrch(32<=ch<=127 -> ch, '.')
               }
               RETURN
             }
  CASE 'B':  writef( " %bW ", n);     RETURN
  CASE 'D':  writef( " %IA ", n);     RETURN
  CASE 'F':  writearg(n);             RETURN
  CASE 'O':  writef( " %OC ", n);     RETURN
  CASE 'S':  checkaddr(n)
             writef( " %S ",  n);     RETURN
  CASE 'U':  writef( " %UA ", n);     RETURN
  CASE 'X':  writef( " %X8 ", n);     RETURN
}

AND selectask(id) BE
{ // If id<0, select the regs, p and g at the time of last
  // leaving cinterp, otherwise select the tcb for task id
  // and the registers corresponding to that task.
  LET tasktab = mem(rtn_tasktab+rootnode)
  AND st      = mem(rootnode+rtn_lastst)  // The latest ST value
  AND ctxt    = mem(rootnode+rtn_context) // The context
  LET t = 0                               // To hold the TCB address

  IF tasktab & 0<id<=mem(tasktab+0) DO t := mem(tasktab+id)
  IF id<0 DO t := mem(rtn_crntask+rootnode)

  UNLESS t DO
  { sawritef("Task %n does not exist*n", id)
    RETURN
  }

  ctcb, cptr := t, 0

  TEST t=mem(rtn_crntask+rootnode)
  THEN TEST id>0 & st=3
       THEN regs := saveregs     // regs of crntask at time of fault
       ELSE regs := klibregs     // regs at time of fault
  ELSE regs := @tcb_regs!t       // regs belonging to non current task


//sawritef("regs=%n*n", regs)
  gptr  := mem(r_g + regs) >> 2
  pptr  := mem(r_p + regs) >> 2

  // Set current coroutine if in user or kernel mode and the task
  // is active
  IF st<2 & mem(t+tcb_active) DO cptr := mem(gptr+g_currco)

  UNLESS cptr <= pptr <= cptr + mem(cptr+co_size) + 6 DO cptr := 0

  fsize := 100
//sawritef("cptr=%n*n", cptr)
  IF cptr DO fsize := cptr + 6 + mem(cptr+co_size) - pptr
//sawritef("fsize=%n*n", fsize)

  { LET name = t+tcb_namebase
    sawritef("Task %n: ", mem(t+tcb_taskid))
    FOR i = 1 TO memb(name, 0) DO sawrch(memb(name, i))
    sawritef(" selected*n")
  }
  
}

AND error() BE { writes("  ??*n"); longjump(rec_p, rec_l) }

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
  writef(" %i7: ", pc)
  checkaddr(pc>>2)
  wrfcode(gb(pc))
  SWITCHON instrtype(gb(pc)) INTO
  { DEFAULT:
    CASE '0':                                      RETURN
    CASE '1': a  := gb(pc+1);                      ENDCASE
    CASE '2': a  := gh(pc+1);                      ENDCASE
    CASE '4': a  := gw(pc+1);                      ENDCASE
    CASE 'R': a  := pc+1 + gsb(pc+1);              ENDCASE
    CASE 'I': pc := pc+1 + 2*gb(pc+1) & #xFFFFFFFE
              a  := pc + gsh(pc);                  ENDCASE
  }
  writef("  %n", a)
  vars!9 := a
}

AND gb(pc) = memb(0, pc)

AND gsb(pc) = gb(pc)<=127 -> gb(pc), gb(pc)-256

AND gsh(pc) = VALOF
{ LET h = gh(pc)
  RESULTIS h<=#x7FFF -> h, h - #x10000
}

AND gh(pc) = VALOF
{ LET w = 0
  LET p = @w  // Designed to work on both Big and Little Ender M/Cs.
  p%0, p%1, p%2, p%3 := gb(pc), gb(pc+1), gb(pc), gb(pc+1)
  RESULTIS w & #xFFFF
}

AND gw(pc) = VALOF
{ LET w = 0
  LET p = @w  // Designed to work on both Big and Little Ender M/Cs.
  p%0, p%1, p%2, p%3 := gb(pc), gb(pc+1), gb(pc+2), gb(pc+3)
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

AND nextpc(pc) = VALOF SWITCHON instrtype(gb(pc)) INTO
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

AND nextword() = VALOF
{ UNTIL blkcount DO
  { UNLESS readwords(@blkcount, 1) DO
    { //sawritef("Bad count in dump file data*n")
      //abort(1000)
      blkcount, currword := 0, #xBAD00BAD
      RESULTIS currword
    }
    IF blkcount<0 DO
    { UNLESS readwords(@currword, 1) DO
      { sawritef("Bad block dump file*n")
        currword := #xBAD00BAD
      }
    }
    //TEST blkcount<0
    //THEN sawritef("%i7 x %x8*n", -blkcount, currword)
    //ELSE sawritef("%i7 BLOCK*n", blkcount)
//abort(1000)
  }

  TEST blkcount>0
  THEN { UNLESS readwords(@currword, 1) DO
         { sawritef("Bad block dump file*n")
           currword := #xBAD00BAD
         }
         blkcount := blkcount - 1
         RESULTIS currword
       }
  ELSE { blkcount := blkcount+1
         RESULTIS currword
       }

}

AND eqpages(p1, p2) = VALOF
{ FOR i = 0 TO pageupb UNLESS p1!i=p2!i RESULTIS FALSE
  RESULTIS TRUE
}

AND getimage(filename) = VALOF
{ // Return TRUE is successful, FALSE otherwise.
  LET res = FALSE                 // Assume the worst

  datastream := findinput(filename)

  UNLESS datastream RESULTIS FALSE
  selectinput(datastream)

  writef("*nReading image file ...")
  deplete(cos)

  blkcount, currword := 0, #xBAD00BAD
  pagetab := 0
  pagenoupb := 0

  // Get the memory upb
  UNLESS readwords(@memupb, 1) DO
  { writef("*nBad memupb in dump file*n")
    GOTO ret
  }

  IF memupb<0 GOTO ret

  pagenoupb := memupb>>pageshift
  pagetab := getvec(pagenoupb)
  UNLESS pagetab DO
  { writef("*nUnable to to allocate space for the page table*n")
    RESULTIS FALSE
  }
  // Initialise the page table
  FOR pageno = 0 TO pagenoupb DO pagetab!pageno := 0

  FOR pageno = 0 TO pagenoupb DO
  { LET page = VEC pageupb
    AND newpage = 0
    // Read the next page
    FOR i = 0 TO pageupb DO page!i := nextword()

    // Is it the same as a previous page
    FOR p = 0 TO pageno-1 IF eqpages(page, pagetab!p) DO
    { // A matching page has been found
      newpage := pagetab!p
//sawritef("page %i5 same as page %i5*n", pageno, p)
      BREAK
    }
    UNLESS newpage DO
    { // A matching page was not found so make a new one
      newpage := getvec(pageupb)
      FOR i = 0 TO pageupb DO newpage!i := page!i
//sawritef("page %i5 is new*n", pageno)
    }
    // Put the page in the page table
    pagetab!pageno := newpage
    IF pageno MOD 100 = 0 DO { wrch('.'); deplete(cos) }
//abort(1234)
  }

  newline()

  res := TRUE   // Image successful read

ret:
  IF datastream DO endstream(datastream)
//abort(2222)
  RESULTIS res
}

AND deleteimage() BE IF pagetab DO
{ FOR pageno = 0 TO pagenoupb DO
  { LET page = pagetab!pageno
    UNLESS page LOOP
    freevec(page)
    // Delete all page table entries pointing to this page.
    FOR p = pageno+1 TO pagenoupb IF page=pagetab!p DO pagetab!p := 0
  }
  freevec(pagetab)
}

AND mem(p) = VALOF
{ LET pageno = p>>pageshift  // Typically 10
  AND offset = p & pagemask  // Typically 1023
  
  IF pageno > pagenoupb DO
  { writef("*nBad Cintpos memory address %x8  %n*n", p, p)
    longjump(rec_p, rec_l)
    // Should not reach this point
    RESULTIS #xBAD00BAD
  }

  RESULTIS pagetab!pageno!offset
}

AND stmem(p, w) BE
{ LET pageno = p>>pageshift  // Typically 12
  AND offset = p & pagemask  // Typically 4095
  AND page, count = 0, 0

  IF pageno > pagenoupb DO
  { writef("*nBad Cintpos memory address %x8  %n*n", p, p)
    longjump(rec_p, rec_l)
    // Should not reach this point
    RETURN
  }

  page := pagetab!pageno

  FOR i = 0 TO pagenoupb IF pagetab!i=page DO count := count + 1
  IF count>1 DO
  { // There are more pages sharing this page, so make a copy
    LET newpage = getvec(pageupb)
    UNLESS newpage DO
    { writef("*nMore space needed*n")
      longjump(rec_p, rec_l)
      // Should not reach this point
      RETURN
    }

sawritef("*nCopying page %n*n", pageno)
    FOR i = 0 TO pageupb DO newpage!i := page!i
    pagetab!pageno := newpage
  }

  pagetab!pageno!offset := w
}

AND memb(p, n) = VALOF
{ LET word = mem(p+(n>>2))
  RESULTIS (@word)%(n&3)
}

AND stmemb(p, n, byte) = VALOF
{ LET word = mem(p+(n>>2))
  (@word)%(n&3) := byte
  stmem(p+(n>>2))
}
