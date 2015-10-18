// This is a program to convert a compacted dump of the entire
// Cintcode memory (normally written to DUMP.mem) into a readable form.
// It is based on the dumpsys.b program of the Cintpos system.

// Martin Richards (c) November 2006

// Usage:

// dumpsys [FROM <image>] [TO <file>]

// The FROM argument specifies the dump image file,
// the default DUMP.mem
// The TO argument specifies where to send the output.

// The program dumps the rootnode, the CLI's global vector and its
// coroutine stacks,folled by a dump of all all memory blocks.

SECTION " dumpsys"

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

  imagefilename  // 0 or name of the image file
  imagedata      // Raw DUMP.mem file (=0 if no image given)
  addrv          // memory addresses
  datav          // corresponding pointers into imagedata
  datavupb
  imagep  

  rec_p; rec_l   // Recovery label for longjump
}

MANIFEST {
  maxpri = maxint

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

LET start() BE
{ LET argv       = VEC 50
  AND datv       = VEC 1
  AND datstrings = VEC 12
  AND sysin      = input()
  AND sysout     = output()
  AND toname     = 0
  AND tostream   = 0
  AND imagefilename = "DUMP.mem"
  AND taskcount  = 0

  UNLESS rdargs("FROM,TO/K", argv, 50) DO
  { writes("bad arguments for DUMPSYS*n")
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

  toname := argv!1
 
  IF toname DO
  { tostream := findoutput(toname)
    UNLESS tostream DO
    { writef("can't open %s*n", toname)
      GOTO fin
    }
    selectoutput(tostream)
  }

  writef("*nImage File: %s", imagefilename)
  IF memdatstamp(datv) DO
  { dat_to_strings(datv, datstrings)
//sawritef("dumpsys: datv = [%n %n]*n", datv!0, datv!1)
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
  
  writef("*nLast abort code: %n*n", mem(rootnode+rtn_abortcode))

  dumprootnode()

  dumptask("Boot", bootregs) 
  dumptask("CLI", cliregs)
 
  dumpmemory()

fin:
  IF tostream UNLESS sysout=tostream DO endstream(tostream)
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

AND dumprootnode() BE
{ writef("*nRootnode at %n*n*n", rootnode)

  writef("  blklist    %iA*n", mem(rtn_blklist+rootnode))
  writef("  memsize    %iA*n", mem(rtn_memsize+rootnode))
  writef("  info       %iA*n", mem(rtn_info+rootnode))
  writef("  sys        %iA*n", mem(rtn_sys+rootnode))
  writef("  blib       %iA*n", mem(rtn_blib+rootnode))
  writef("  boot       %iA*n", mem(rtn_boot+rootnode))
  writef("  abortcode  %iA*n", mem(rtn_abortcode+rootnode))
  writef("  context    %iA*n", mem(rtn_context+rootnode))
  writef("  lastp      %iA*n", mem(rtn_lastp+rootnode))
  writef("  lastg      %iA*n", mem(rtn_lastg+rootnode))
  writef("  days       %iA*n", mem(rtn_days+rootnode))
  writef("  msecs      %iA*n", mem(rtn_msecs+rootnode))
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
    IF mem(a+3) = sectword & memb(a+4, 0) = 11 DO
    { LET name = a+4
      writef("Section ")
      FOR i = 1 TO memb(name, 0) DO wrch(memb(name, i))
      GOTO nxt
    }
/*
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
*/
dump:
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

AND dumptask(name, regs) BE
{ writef("*n*n######################### Program %s ", name)
  FOR i = name%0+1 TO 15+16 DO wrch('#')
  writef("*n")

  gptr := mem(regs+r_g) >> 2
  pptr := mem(regs+r_p) >> 2
  cptr := mem(gptr+g_currco)

  UNLESS cptr <= pptr <= cptr + mem(cptr+co_size + 6) DO cptr := 0

  fsize := 100
//sawritef("cptr=%n*n", cptr)
  IF cptr DO fsize := cptr + 6 + mem(cptr+co_size) - pptr

  wrregs("Registers", regs)

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

  writef("*nCoroutine stacks for program %s:*n", name)  
  wrcortns(regs)
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
  TEST (mem(s+2) = sectword) & (memb(s+3, 0) = 11)
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

AND wrcortns(regs) BE
{ 
//sawritef("cptr=%n pptr=%n gptr=%n*n", cptr, pptr, gptr)
  cptr := cont(gptr+g_colist)

  WHILE 0<cptr<=memlim DO
  { // Output a coroutine stack
    TEST cptr=cont(gptr+g_currco)
    THEN pptr := cont(regs+r_p)>>2
    ELSE pptr := cont(cptr+co_pptr)>>2
    fsize := cptr + 6 + cont(cptr+co_size) - pptr
    wrcortn()

    // Find next coroutine in the list
    cptr := cont(cptr+co_list)
  }
  TEST cptr THEN writef("*nCorrupt coroutine list*n")
            ELSE writef("*nEnd of coroutine list*n")
}

AND wrcortn() BE
{ LET size = cont(cptr+co_size)
  LET hwm = size+6
  writef("*n%i8: ", cptr)
  IF cptr=mem(gptr+g_currco) DO writes("Current ")
  writes("Coroutine ")
  writearg(cont(cptr+co_fn))
  writef("  Parent %n", mem(cptr+co_parent))
  WHILE cont(cptr+hwm)=stackword DO hwm:=hwm-1
  writef("  Stack %n/%n*n", size, hwm-6)
  wrframe()

  WHILE pptr> cptr DO
  { LET a = cont(pptr)>>2
    fsize := pptr-a
    pptr := a
    wrframe()
  }

  writef(" Base of stack*n")
}

AND wrframe() BE
{ writef("%i8:", pptr)
  TEST pptr=cptr
  THEN writef("  #StackBase#")
  ELSE writearg(mem(pptr+2))
  FOR i=3 TO 6 UNLESS i>=fsize DO writearg(cont(pptr+i))
  newline()
  IF fsize>7 DO
  { writef("         ")
    FOR i = 7 TO 11 UNLESS i>=fsize DO writearg(cont(pptr+i))
    newline()
  }
  IF fsize>12 DO
  { writef("         ")
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

AND memb(p, n) = VALOF
{ LET word = mem(p+(n>>2))
  RESULTIS (@word)%(n&3)
}
