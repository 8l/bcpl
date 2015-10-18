// (C) Copyright 1979 Tripos Research Group
//     University of Cambridge
//     Computer Laboratory

// 14/2/03     MR     Modified to run under Cintpos

// Program which tries to identify a vector
// given its address

SECTION "idvec"
GET "libhdr"

STATIC { // So as not to zap globals when CALLSEGed
  addr = 0
  ptr.found = FALSE
  tasktab   = 0
  devtab    = 0
}



LET start(addr.or.zero) BE
{ LET argv = VEC 30
  tasktab   := rtn_tasktab ! rootnode
  devtab    := rtn_devtab  ! rootnode
  ptr.found := FALSE // So repeated execution works

  TEST addr.or.zero = 0
  THEN { // Running as command
         IF rdargs("address/a", argv, 30) = 0 DO
         {
           writes("Bad arguments to IDVEC*N")
           stop(20)
         }

         addr := stringval(argv!0)
       }
  ELSE addr := addr.or.zero // Called by CALLSEG

  addr := addr | 1 // All GETVEC vectors have odd addresses
  IF (addr!-1 & 1) = 1 DO
  { writes("Vector is not allocated!*N")
    RETURN // in case in CALLSEG
  }

  IF addr = tasktab DO { mywritef("Task table*N"); RETURN }
  IF addr = devtab  DO { mywritef("Device table*N"); RETURN }

    // Search tasks
    FOR t=1 TO tasktab!0 DO searchtask(t)

    // Search devices
    FOR d=1 TO devtab!0 DO searchdev(d)

    UNLESS ptr.found DO
    { writes("Cannot identify this vector")

      TEST addr.or.zero = 0
      THEN { writes(" - first 10 words are:*N")
             FOR a=addr-1 TO addr+8 DO // addr is address + 1
             { LET word = !a
               writef("%i9: %iB  %x8  *'%c%c%c%c*'*n",
                       a, word, word,
                       safech((@word)%0),
                       safech((@word)%1),
                       safech((@word)%2),
                       safech((@word)%3))
             }
           }
      ELSE newline()
      }
    }

AND safech(ch) = 32<=(ch&127)<127 -> ch&127, '.'


AND searchtask(t) BE
{ LET tcb, sbase, gbase, segl = tasktab!t, ?, ?, ?
  UNLESS tcb RETURN // No such task
  IF addr=tcb DO { mywritef("TCB of task %N*N", t); RETURN }

  // Look down segment list
  segl := tcb_seglist ! tcb
  IF addr = segl DO mywritef("Segment list of task %N*N", t)

  FOR x=1 TO segl!0 DO
  { LET sec= segl!x
    WHILE sec DO
    { IF addr = sec DO mywritef("Code section of task %n: %s*n", t,
                                 addr!2 = sectword -> addr+3,
                                       "<no name>")
      sec := !sec
    }
  }

  // Don't carry on if task is dead
  IF (tcb_state ! tcb & State_dead) = State_dead RETURN

  sbase := tcb_sbase ! tcb
  gbase := tcb_gbase ! tcb

  // Inspect stack
  IF addr = sbase DO { mywritef("Stack of task %N*N", t); RETURN }

  // Is it a coroutine stack?
  { LET cstack = gbase!8  // The colist!!!!!!!!!!!!!!!!
    WHILE cstack DO
    { IF cstack=addr DO
      { mywritef("Coroutine stack of task %n*n",t)
        RETURN
      }
      cstack := cstack!co_list
    }
  }

  // Inspect global vector

  IF addr=gbase DO
  { mywritef("Global vector of task %N*N", t)
    RETURN
  }

  FOR gn = 1 TO gbase!0 IF addr = gbase!gn DO
    mywritef("Pointed to by global %n of task %n*n", gn, t)

  FOR s = 0 TO tcb_stsiz ! tcb - 1 IF sbase!s = addr DO
    mywritef("Pointed to by stack location %N of task %N*N", sbase+s, t)
}


AND searchdev(d) BE
{ LET dcb = devtab!d
  UNLESS dcb RETURN // No such device

  IF addr=dcb DO
  { mywritef("DCB of device -%n  type %s*n", d, devtype(dcb!0))
    RETURN
  }
}

AND devtype(t) = VALOF SWITCHON t INTO
{ DEFAULT:          RESULTIS "Unknown"

  CASE Devt_clk:    RESULTIS "Clk"
  CASE Devt_ttyin:  RESULTIS "Ttyin"
  CASE Devt_ttyout: RESULTIS "Ttyout"
  CASE Devt_fileop: RESULTIS "Fileop"
  CASE Devt_tcpdev: RESULTIS "Tcpdev"
}

AND stringval(s) = VALOF
{ // converts a string to a number
  LET val = 0
  LET neg = ?
  LET char1 = ?

  TEST s%1 = '-' THEN neg, char1 := TRUE, 2
                 ELSE neg, char1 := FALSE, 1

  FOR j = char1 TO s%0 DO
  { UNLESS '0' <= s%j <= '9' DO
    { writef("Invalid char *'%C*' in number*N", s%j)
      stop(20)
    }
    val := val*10 + s%j - '0'
  }

  RESULTIS val
}

AND mywritef(f,a,b,c,d) BE
{ ptr.found := TRUE
  writef(f,a,b,c,d)
}
