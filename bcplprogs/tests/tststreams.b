GET "libhdr"

GLOBAL {
  stdin: ug
  stdout
}

LET start() = VALOF
{ stdin  := input()
  stdout := output()

  testnilstream()
  testramstream()


  RESULTIS 0
}

AND testnilstream() BE
{ LET nilstream = findoutput("NIL:")
  writef("Writing hello 500_000 times to NIL:*n")
  selectoutput(nilstream)
  FOR i = 1 TO 500_000 DO writes("hello*n")
  selectoutput(stdout)
  writef("*ncalling endstream(nilstream)*n")
  endstream(nilstream)

  nilstream := findinput("NIL:")
  writef("Reading 500_000 characters from NIL:*n")
  selectinput(nilstream)
  FOR i = 1 TO 500_000 DO
  { LET ch = rdch()
    UNLESS ch=endstreamch DO
    { writef("reading from NIL: gave %n*n", ch)
      abort(999)
    }
  }
  selectinput(stdin)
  writef("*ncalling endstream(nilstream)*n")
  endstream(nilstream)
}

AND testramstream() BE
{ LET ramstream = findinoutput("RAM:")
  LET buf = 0
  writef("Testing RAM: streams*n")
  selectoutput(ramstream)
  FOR i = 0 TO 5000 DO
  { wrch(i & 255)
    UNLESS buf = ramstream!scb_buf DO
    { buf := ramstream!scb_buf
      sawritef("*n%i5: New RAM buffer %n size %n*n", i, buf, ramstream!scb_bufend)
    }
  }

  selectoutput(stdout)
  writef("Calling rewindstream{ramstream)*n")
  rewindstream(ramstream)
  selectinput(ramstream)

  FOR i = 0 TO 20000 DO
  { LET ch = rdch()
    IF ch=endstreamch BREAK
    IF i MOD 16 = 0 DO writef("*n%i5: ", i)
    writef(" %i3", ch)
  }
  newline()

  writef("Calling endstream(ramstream)*n")
  endstream(ramstream)

  RETURN
}

