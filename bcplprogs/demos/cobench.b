// This is a benchmark program for the coroutine mechanism

// Implemented in BCPL by Martin Richards (c) March 2004

SECTION "cobench"

GET "libhdr"

GLOBAL {
  kill_co: ug        // The killer coroutine
  source_co
  tracing
}

LET start() = VALOF
{ LET argv = VEC 50
  LET k, n = 10_000, 500
  LET cptr = 0

  UNLESS rdargs("-k,-n,-t/S", argv, 50) DO
  { writef("Bad arguments for cobench*n")
    RESULTIS 0
  }

  IF argv!0 & string_to_number(argv!0) DO k := result2 // -k
  IF argv!1 & string_to_number(argv!1) DO n := result2 // -n
  tracing := argv!2                                    // -t

  writef("*nCobench sending %n numbers via %n copy coroutines*n*n", k, n)

  kill_co := createco(deleteco, 150)

  cptr := createco(sinkfn, 150)

  FOR i = 1 TO n DO
  { LET co = createco(copyfn, 150)
    callco(co, cptr)
    cptr := co
  }

  source_co := createco(sourcefn, 150)
  callco(source_co, cptr)

  IF tracing DO writef("All coroutines created*n*n")

  callco(source_co, k) // Tell sourceco to send k numbers 

  deleteco(kill_co)

  writef("*nCobench done*n")
  RESULTIS 0
}

AND sourcefn(nextco) BE
{ LET k = cowait()
  LET channel = 0
  LET out_chan_ptr = @channel

  callco(nextco, out_chan_ptr)
 
  //IF tracing DO
  //  writef("srcefn: co=%n out_chan_ptr=%n k=%n*n*n",
  //          currco, out_chan_ptr, k)

  FOR val = 1 TO k DO
  { IF tracing DO writef("srcefn: sending number %n*n", val)
    cowrite(out_chan_ptr, val)
  }
  IF tracing DO writef("srcefn: sending number 0*n")
  cowrite(out_chan_ptr, 0)
  //IF tracing DO writef("srcefn: dying*n")
  die()
}

AND copyfn(nextco) BE
{ LET channel = 0
  LET in_chan_ptr, out_chan_ptr = cowait(), @channel

  callco(nextco, out_chan_ptr)

  { LET val = coread(in_chan_ptr)
    IF tracing DO writef("copyfn: copying number %n*n", val)
    cowrite(out_chan_ptr, val)
    UNLESS val BREAK
  } REPEAT

  //IF tracing DO writef("copyfn: dying*n")
  die()
}

AND sinkfn(in_chan_ptr) BE
{ //IF tracing DO writef("sinkfn:   co=%n in_chan_ptr=%n*n",
  //                      currco, in_chan_ptr)

  { LET val = coread(in_chan_ptr)
    IF tracing DO writef("sinkfn: recving number %n*n", val)
    UNLESS val BREAK
  } REPEAT

  //IF tracing DO writef("sinkfn: dying*n")

  die()
}

AND coread(ptr) = VALOF
{ LET cptr = !ptr
  TEST cptr
  THEN { !ptr := 0         // Clear the channel word
         RESULTIS resumeco(cptr, currco)
       }
  ELSE { !ptr := currco    // Set channel word to this coroutine
         RESULTIS cowait() // Wait for value from cowrite
       }
}

AND cowrite(ptr, val) BE
{ LET cptr = !ptr
  TEST cptr
  THEN { !ptr := 0
         callco(cptr, val) // Send val to coread
       }
  ELSE { !ptr := currco
          callco(cowait(), val)
       }
}

AND die() BE resumeco(kill_co, currco)


