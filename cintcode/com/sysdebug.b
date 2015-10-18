// The program allows the user to inspect the compacted memory
// dump of the Cintpos system.

// Martin Richards (c) November 2006

// Usage:

// dumpsys [FROM <image>]

// The FROM argument specifies the dump image file,
// the default DUMP.mem

// The program is a combination of the sadebug function in sysb/boot.b
// and com/dumpsys.b



SECTION " dumpdebug"

GET "libhdr"


GLOBAL
{ eof: ug
  pptr
  gptr
  cptr
  fsize

  regs
  membase
  memlim
  memupb
  context
  ch
  lch
  rch
  val
  vars
  style
  bpt_addr
  bpt_instr

  imagefilename  // 0 or name of the image file
  imagedata      // Raw DUMP.mem file (=0 if no image given)
  addrv          // memory addresses
  datav          // corresponding pointers into imagedata
  datavupb
  imagep  

  rec_p; rec_l   // Recovery label for longjump
}

MANIFEST {
  maxpri    = maxint

  sectnamesize = (11 + bytesperword)/bytesperword
  routnamesize = (11 + bytesperword)/bytesperword
  nameoffset   = -routnamesize
  vecupb       = 5000

  g_globsize=0; g_sys=3; g_currco=7; g_colist=8 

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
}

LET rch() BE
{ lch := sys(Sys_sardch) // This is for BCPL Cintcode, not Cintpos.
  ch := capitalch(lch)
}

LET start() BE
{ LET argv       = VEC 50
  AND datv       = VEC 1
  AND datstrings = VEC 12
  AND sysin      = input()
  AND sysout     = output()
  AND imagefilename = "DUMP.mem"

  UNLESS rdargs("FROM", argv, 50) DO
  { writes("bad arguments for DUMPDEBUG*n")
    stop(20)
  }

  IF argv!0 DO imagefilename := argv!0
  IF imagefilename UNLESS getimage(imagefilename) DO
  { writef("Unable to load image file %s*n", imagefilename)
    RETURN
  }

  rec_p, rec_l := level(), fin

  membase := mem(rootnode+rtn_membase)
  memlim  := mem(rootnode+rtn_memsize)
  context := mem(rootnode+rtn_context)
  // context = 1   SIGINT received
  // context = 2   SIGSEGV received
  // context = 3   dump caused by fault in BOOT of standalone debug
  // context = 4   dump requested by user calling sys(Sys_quit, -2)
  // context = 5   non zero user fault code
  // context = 6   dump requested in standalone debug

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
  
  dumprootnode()

  debug()

fin:
  IF imagedata DO freevec(imagedata)
  IF addrv     DO freevec(addrv)
  IF datav     DO freevec(datav)
}

AND memdatstamp(v) = VALOF
{ LET tv = rootnode+rtn_days
 
  UNLESS 0<=tv<=memupb RESULTIS FALSE

  v!0 := mem(tv+0)
  v!1 := mem(tv+1)

  RESULTIS TRUE
}

AND debug() = VALOF
{ 
  rec_p, rec_l := level(), recover // recovery point for error()

  // Initialise the standalone debugger
  membase := mem(rootnode+rtn_membase)
  memlim  := membase + mem(rootnode+rtn_memsize)

  // Get the breakpoint vectors from the rootnode
  bpt_addr  := mem(rootnode+rtn_bptaddr)
  bpt_instr := mem(rootnode+rtn_bptinstr)

  // Get the variable vector from the rootnode
  // so that vt10 will work, but note that our image
  // of the dumped Cintcode memory must be writable so
  // that 1234SV3  will work (and the removal of breakpoints).
  vars  := mem(rootnode+rtn_dbgvars)

  style := 'F'                 // Default printing style
  val   := 0
/*
  FOR i = 0 TO 9 DO            // Remove all BRK instructions (if any)
  { LET ba = mem(bpt_addr+i)
    //writef("bpt %n: addr: %i6    instr: %n*n", i, ba, mem(bpt_instr+i))
    IF ba DO setmemb(0, ba, mem(bpt_instr+i))
  }
*/
  selectprog(1) // Select the CLI program

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
                  CASE  11: RESULTIS "Watch addr: %+%i7 value: %i8"
                  CASE  12: RESULTIS "Indirect address out of range: %+%+%+%n"
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

    writef("*nAbort code: %n  ", mem(rootnode+rtn_abortcode))
    writef(mess, gn, mem(1), mem(2), mem(3))
    newline()
  }

recover:
  ch := '*n'
nxt:                          // Main loop for debug commands
  IF ch='*n' DO prprompt()

  rch() REPEATWHILE ch='*s'
sw:
  SWITCHON ch INTO

  { DEFAULT: error()

    CASE endstreamch:
       newline()
       RETURN

    CASE '*s':
    CASE '*n':GOTO nxt
      
    CASE '?':
       writes("*n?          Print list of debug commands*n")
       writes("Gn Pn Rn Vn Wn An          Variables*n")
       writes("G  P  R  V  W  A           Pointers*n")
       writes("123 #o377 #FF03 'c         Constants*n")
       writes("**e /e %e +e -e |e &e       Dyadic operators*n")
       writes("!e                         Subscription*n")
       writes("< >                        Left/Right shift one place*n")
       writes("$c $d $f $b $o $s $u $x    Set the print style*n")
       writes("SGn SPn SRn SVn SAn        Store current value*n")
       writes("S0 S1   Select the Boot/CLI program*n")
       writes("=       Print current value*n")
       writes("Tn      Print n consecutive locations*n")
       writes("Bn      Print n blocks from current position*n")
       writes("I       Print current instruction*n")
       writes("N       Print next instruction*n")
       writes("Q       Quit -- exit from dumpdebug*n")
       writes(".       Move to current coroutine*n")
       writes(",       Move down one stack frame*n")
       writes(";       Move to parent coroutine*n")
       writes("[       Move to first coroutine*n")
       writes("]       Move to next coroutine*n")
       GOTO recover

    CASE '0': CASE '1': CASE '2':
    CASE '3': CASE '4': CASE '5':
    CASE '6': CASE '7': CASE '8':
    CASE '9': CASE '#': CASE '*'':
    CASE 'G': CASE 'P': CASE 'R':
    CASE 'V': CASE 'A':
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
                // Is it a program selection?
                IF ch='0' DO { selectprog(0);   GOTO recover }
                IF ch='1' DO { selectprog(1);   GOTO recover }
                // No -- it must be a store instruction
                type := ch
                rch()
                setmem(rdvaraddr(type), val)
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

    CASE 'B': rch()
            { LET n = rdn()
              IF n<=0 DO n := 1

              { LET size = 0
                LET blk = findblock(val)
                IF blk<0 BREAK  // No suitable block found
                val := blk
                size := mem(val) & -2
                prblock(val)
                n := n-1
                UNLESS n & size BREAK
                val := val+size
              } REPEAT

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

    CASE ',':  // Move down one stack frame and output it.
             { LET a = cont(pptr)>>2
               IF a=0 DO { writef(" Base of stack*n")
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
              THEN pptr := cont(regs+r_p)>>2
              ELSE pptr := cont(cptr+co_pptr)>>2
              fsize := cptr + 6 + cont(cptr+co_size) - pptr
              wrcortn()
              GOTO recover
  }
}

AND prprompt() BE
{ TEST regs=bootregs
  THEN writef("# ")
  ELSE writef("** ")
  deplete(cos)
}

AND dumprootnode() BE
{ writef("*nRootnode at %n*n*n", rootnode)

  writef("  blklist    %i8*n", cont(rtn_blklist+rootnode))
  writef("  memsize    %i8*n", cont(rtn_memsize+rootnode))
  writef("  info       %i8*n", cont(rtn_info+rootnode))
  writef("  sys        %i8*n", cont(rtn_sys+rootnode))
  writef("  blib       %i8*n", cont(rtn_blib+rootnode))
  writef("  boot       %i8*n", cont(rtn_boot+rootnode))
  writef("  abortcode  %i8*n", cont(rtn_abortcode+rootnode))
  writef("  context    %i8*n", cont(rtn_context+rootnode))
  writef("  lastp      %i8*n", cont(rtn_lastp+rootnode))
  writef("  lastg      %i8*n", cont(rtn_lastg+rootnode))

}

AND findblock(addr) = VALOF
{ // Find the base of the block contain addr
  // return -1 if no such block
  LET blocklist  = cont(rootnode+rtn_blklist)
  LET topofstore = cont(rootnode+rtn_memsize)
  LET a = blocklist
  LET free, used, n = 0, 0, 0

  { LET size = cont(a) & -2          // Mask off the size
    UNLESS size BREAK                // End of block chain reached

    UNLESS a <= a+size <= topofstore DO
    { writef("******Store chain corrupt!!*n*
              *Noticed at %n*n", a)
      RESULTIS a
    }
    IF a <= addr < a+size RESULTIS a // Found the base of the block
    a := a+size
  } REPEAT

  RESULTIS -1  // End of block chain reached
}

AND prblock(a) BE
{ LET size = cont(a)
  LET freeblk = (size&1)=1
  size := size & -2

  writef("%i8:%i7 ", a, size)
  IF freeblk DO { writes("free "); GOTO nxt }

  IF a = (rootnode-1) DO { writes("Rootnode"); GOTO nxt }
  IF cont(a+3) = sectword & memb(a+4, 0) = 11 DO
  { LET name = a+4
    writef("Section ")
    FOR i = 1 TO memb(name, 0) DO wrch(memb(name, i))
    GOTO nxt
  }

  IF a+1=(cont(cliregs+r_g)>>2) DO { writef("CLI Global vector"); GOTO nxt }
  IF a+1=(cont(bootregs+r_g)>>2) DO { writef("Boot Global vector"); GOTO nxt }
  { LET p = cont(cliregs+r_p)>>2
    IF a <= p <= a + size DO { writef("a CLI coroutine stack"); GOTO nxt }
    p := cont(bootregs+r_p)>>2
    IF a <= p <= a + size DO { writef("a Boot coroutine stack"); GOTO nxt }
  }
dump:
  FOR i = 1 TO 5 DO { LET n = cont(a+i)
                      TEST -10_000_000<=n<=10_000_000
                      THEN writef("%iA ", n)
                      ELSE writef("#x%x8 ", n)
                    }
nxt:
  newline()
}


AND dumpmemory() BE
{ LET blocklist  = cont(rootnode+rtn_membase)
  LET topofstore = cont(rootnode+rtn_memsize)
  LET a = blocklist
  LET free, used, n = 0, 0, 0
  LET largest_free = 0
  LET joinfree = 0
  LET sectnames, routnames, globinit = 0, 0, 0
  LET constr = output()
  LET outstr = 0

  writef("*nMap of free and allocated blocks in %n..%n*n*n", membase, memlim)

  WHILE cont(a) DO
  { LET size = cont(a)
    LET freeblk = (size&1)=1

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

    IF a = (rootnode-1) DO { writes("Rootnode"); GOTO nxt }
    IF cont(a+3) = sectword & memb(a+4, 0) = 11 DO
    { LET name = a+4
      writef("Section ")
      FOR i = 1 TO memb(name, 0) DO wrch(memb(name, i))
      GOTO nxt
    }
/*
    FOR id = 1 TO cont(tasktab) DO
    { LET t = cont(tasktab+id)
      IF t DO
      { LET p, g = cont(t+tcb_sbase), cont(t+tcb_gbase)
        IF a+1=p DO { writef("Task %n stack", id); GOTO nxt }
        IF a+1=g DO { writef("Task %n global vector", id); GOTO nxt }
        IF a+1=t DO { writef("Task %n TCB", id); GOTO nxt }
        IF g & a>500 FOR gn = 1 TO cont(g) IF a+1=cont(g+gn) DO
                     { writef("Task %n G%n => ", id, gn)
                       GOTO dump
                     }
      }
    }
*/
dump:
    FOR i = 1 TO 5 DO { LET n = cont(a+i)
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

AND wrregs(str, regs) BE
{ writef("*n%s:*n", str)
  writef("a=%n b=%n c=%n ", mem(regs+r_a), mem(regs+r_b), mem(regs+r_c))
  writef("p=%n(%n) g=%n(%n) ", mem(regs+r_p), mem(regs+r_p)>>2,
                               mem(regs+r_g), mem(regs+r_g)>>2)
  writef("st=%n pc=%n count=%n mw=%n*n", mem(regs+r_st), mem(regs+r_pc),
                                   mem(regs+r_count),mem(regs+r_mw))
}

AND write_sectname(s) BE
{ LET name = s+3
  TEST (cont(s+2) = sectword) & (memb(s+3, 0) = 11)
  THEN FOR i = 1 TO 11 DO wrch(memb(name, i))
  ELSE writes("???????????")
}

AND checkaddr(a) = VALOF
{ UNLESS membase<=a<=memlim DO
  { writef("*nBad address %n not in range %n--%n*n", a, membase, memlim)
    RESULTIS 0
  }
  RESULTIS a
}

AND cont(a) = mem(checkaddr(a))

AND wrcortn() BE
{ LET size = cont(cptr+co_size)
  LET hwm = size+6
  writef(" %i7: ", cptr)
  writes("  Coroutine:")
  writearg(cont(cptr+co_fn))
  writef("  Parent %n", mem(cptr+co_parent))
  WHILE cont(cptr+hwm)=stackword DO hwm:=hwm-1
  writef("  Stack %n/%n*n", size, hwm-6)
  prprompt()
  wrch(' ')
  wrframe()
}

AND wrframe() BE
{ writef("%i8:", pptr)
  TEST pptr=cptr
  THEN writef("  #StackBase#")
  ELSE writearg(mem(pptr+2))
  FOR i=3 TO 6 UNLESS i>=fsize DO writearg(cont(pptr+i))
  newline()
  IF fsize>7 DO
  { writef("            ")
    FOR i = 7 TO 11 UNLESS i>=fsize DO writearg(cont(pptr+i))
    newline()
  }
  IF fsize>12 DO
  { writef("            ")
    FOR i = 12 TO 16 UNLESS i>=fsize DO writearg(cont(pptr+i))
    newline()
  }
}

AND writearg(n) BE
// Write an argument in a field width of 13 characters
  TEST isfun(n)
  THEN { LET s = (n>>2)-3  // MR 1/11/03
         LET len = memb(s, 0)
         WHILE len>0 & memb(s, len)=' ' DO len := len-1
         FOR i = len+1 TO 13 DO wrch(' ')
         FOR i = 1 TO len DO wrch(memb(s, i))
       }
  ELSE TEST globword<=n<=globword+1000  // MR 1/11/03
       THEN writef("       #G%z3#", n-globword)
       ELSE TEST -10_000_000<=n<=10_000_000
            THEN writef("  %iB", n)
            ELSE writef("   #x%x8", n)

AND isfun(f) = VALOF
{ LET a = f>>2
//sawritef("isfun(%n)*n", f)
  UNLESS (f&3)=0 & membase+4<a<=memlim RESULTIS FALSE // MR 25/9/03
//sawritef("isfun: a=%n*n", a)
  IF mem(a-4)=entryword & memb(a-3, 0)=11 RESULTIS TRUE 
//sawritef("isfun: returning FALSE*n")
  RESULTIS FALSE
}

AND getimage(filename) = VALOF
{ LET res = FALSE
  LET oldin = input()
  LET scb = findinput(filename)
  LET size, upb, wordsread = 0, 0, 0

  imagedata, addrv, datav := 0, 0, 0

  UNLESS scb RESULTIS FALSE
  size := sys(Sys_filesize, scb!scb_fd)    // Size in bytes
  IF size DO upb  := (size-1)/bytesperword // UPB in words      

  imagedata := getvec(upb)
  UNLESS imagedata DO
  { writef("Unable to allocate a vector with upb=%n*n", upb)
    GOTO ret
  }
  selectinput(scb)
  wordsread := readwords(imagedata, upb+1)
  UNLESS upb+1=wordsread DO
  { writef("Read %n words from %s, it should have been %n*n",
            wordsread, filename, upb+1)
    GOTO ret
  }
  //writef("Read %n words from %s*n", wordsread, filename)
  //FOR i = 0 TO upb>31->31, upb DO writef("%i5: %x8*n", i, imagedata!i)

  memupb := imagedata!0
  imagep := 1

  datavupb := 0
  { LET addr, imagep = 0, 1
    UNTIL addr > memupb DO
    { LET n = imagedata!imagep

//TEST n>=0 THEN writef("%i9: %i9 BLOCK*n", addr, n)
//          ELSE writef("%i9: %i9 x %x8*n", addr, -n, imagedata!(imagep+1))
      UNLESS n BREAK

      TEST n>0 THEN imagep := imagep + n + 1
               ELSE imagep := imagep + 2
      datavupb := datavupb + 1
      //addrv!datavupb := addr
      //datav!datavupb := p
      addr := addr + ABS n
    }
    UNLESS addr = memupb+1 DO
    { writef("Image file is corrupt, addr=%n memupb=%n*n", addr, memupb)
      GOTO ret
    }
  }
//  writef("Image file ok, datavupb=%n*n", datavupb)

  addrv := getvec(datavupb)
  datav := getvec(datavupb)
  UNLESS addrv & datav DO
  { writef("More space needed*n")
    GOTO ret
  }

  datavupb := 0

  { LET addr, imagep = 0, 1
    UNTIL addr > memupb DO
    { LET n = imagedata!imagep

      UNLESS n BREAK

      datavupb := datavupb + 1
      addrv!datavupb := addr
      datav!datavupb := imagep

      TEST n>0 THEN imagep := imagep + n + 1
               ELSE imagep := imagep + 2
      addr := addr + ABS n
    }

    UNLESS addr = memupb+1 DO
    { writef("Image file is corrupt, addr=%n memupb=%n*n", addr, memupb)
      GOTO ret
    }
  }

  res := TRUE
ret:
  IF scb DO endstream(scb)
  selectinput(oldin)
  RESULTIS res
}

AND mem(p) = VALOF // Get a word of dumped memory
{ LET i, j, len, res = 1, datavupb+1, 0, 0
  UNLESS 0<=p<=memupb DO
  { writef("*nBad Cintpos memory address %x8  %n*n", p, p)
    longjump(rec_p, rec_l)
    RESULTIS #xBAD00BAD
  }

  { LET m = (i+j)/2
//    writef("addrv!m=%i9 p=%n  i=%i2 m=%i2 j=%i2*n", addrv!m, p, i, m, j)
//abort(1000)
    IF i=m BREAK
    TEST addrv!m <= p THEN i := m
                      ELSE j := m
  } REPEAT

  len := imagedata!(datav!i)
  //writef("len = %n  datav!i=%n*n*n", len, datav!i)
  TEST len>0 THEN res := imagedata!(datav!i + p-addrv!i+1)
             ELSE res := imagedata!(datav!i + 1)
  //writef("mem(%n) => %x8  %i9*n", p, res, res)
  RESULTIS res
}

AND setmem(p, val) BE // Set a word of dumped memory
{ LET i, j, len, res = 1, datavupb+1, 0, 0
  UNLESS 0<=p<=memupb DO
  { writef("*nBad Cintpos memory address %x8  %n*n", p, p)
    longjump(rec_p, rec_l)
  }

  { LET m = (i+j)/2
//    writef("addrv!m=%i9 p=%n  i=%i2 m=%i2 j=%i2*n", addrv!m, p, i, m, j)
//abort(1000)
    IF i=m BREAK
    TEST addrv!m <= p THEN i := m
                      ELSE j := m
  } REPEAT

  len := imagedata!(datav!i)
  //writef("len = %n  datav!i=%n*n*n", len, datav!i)
  IF len<=0 DO
  { writef("Unable to write %x8 to location %n*n", val, p)
    RETURN
  }
  imagedata!(datav!i + p-addrv!i+1) := val
}

AND memb(p, n) = VALOF // Read a byte of dumped memory
{ LET word = mem(p+(n>>2))
  RESULTIS (@word)%(n&3)
}

AND setmemb(p, n, byte) = VALOF // Set a byte of dumped memory
{ LET word = mem(p+(n>>2))
  (@word)%(n&3) := byte
  setmem(p+(n>>2), word)
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
  IF regs <= a <= regs+r_upb                DO type, base := 'R', regs
  writef("*n%c%i5:", type, a-base)
}

AND print1(n) BE
{ sawritef("*nprint: n=%n*n", n)
  print1(n)
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

AND selectprog(id) BE
{ // id=0 selects the boot program, and
  // id=1 selects the CLI program
  // It selects the appropriate register set, etc
  // ie it sets: regs, gptr, pptr, cptr and fsize

  TEST id=0 
  THEN regs := bootregs     // regs of crntask at time of fault
  ELSE regs := cliregs      // regs at time of fault

  gptr  := mem(r_g + regs) >> 2
  pptr  := mem(r_p + regs) >> 2

  // Set current coroutine if in user or kernel mode and the task
  // is active
  cptr := mem(gptr+g_currco)

  // Unset cptr if there is a problem
  UNLESS cptr <= pptr <= cptr + mem(cptr+co_size) + 6 DO cptr := 0

  fsize := 100
//sawritef("cptr=%n*n", cptr)
  IF cptr DO fsize := cptr + 6 + mem(cptr+co_size) - pptr
//sawritef("fsize=%n*n", fsize)

  TEST id=0
  THEN writef("*nBoot program selected*n")
  ELSE writef("*nCLI program selected*n")
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
    CASE 31: RESULTIS " JEQ0$ JNE0$ JLS0$ JGR0$ JLE0$ JGE0$    MW     -"
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
                  *1240000000000?2?0000000000000004*
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

