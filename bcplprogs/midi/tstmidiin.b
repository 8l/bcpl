GET "libhdr"

GLOBAL {
  toname:ug
  tostream
  stdin
  stdout
  midiname
  midifd
}

LET start() = VALOF
{ LET argv = VEC 50
  LET buf = VEC 1024/bytesperword

  toname := 0
  tostream := 0
  stdout := output()
  stdin  := input()

  midiname := "/dev/dmmidi1"
  //midiname := "junk.midi"

  midifd := 0

  UNLESS rdargs("TO/K,DEV/K", argv, 50) DO
  { writef("Bad arguments for tstmidiin*n")
    RESULTIS 0
  }

  IF argv!0 DO toname := argv!0      // TO
  IF argv!1 DO midiname := argv!1      // DEV

  midifd := sys(Sys_sound, 8, midiname) // Open the MIDI device for reading

  writef("midifd=%n*n*n", midifd)

  IF midifd<=0 DO
  { writef("Trouble with %s fd=%n*n", midiname, midifd)
    RESULTIS 0
  }

  IF toname DO
  { tostream := findoutput(toname)
    UNLESS tostream DO
    { writef("Trouble with stream: %s*n", toname)
      GOTO fin
    }
  }
  writef("*nreceiving MIDI data from %s*n*n*n",
          midiname)

  IF tostream DO selectoutput(tostream)

  { LET buf = VEC 1024/bytesperword

    LET len = sys(Sys_sound, 9, midifd, buf, 1024)

    //IF len<0 BREAK
    writef("len=%n*n", len)
    FOR i = 0 TO len-1 DO
    { IF buf%i = #x80 & buf%(i+1)=#x6C GOTO fin
      writef("MIDI: %x2*n", buf%i)
      delay(1)
    }
  } REPEAT

fin:
  IF tostream DO endstream(tostream)

  sys(Sys_sound, 3, midifd) // Close the sound device
  selectoutput(stdout)
  writef("End of test*n")

  RESULTIS 0
}

AND delay(msecs) BE
{ LET ticks = tickspersecond * msecs / 1000
  deplete(cos)
  sys(Sys_delay, ticks)
}

AND wrmid1(a) BE
{ LET v = VEC 1
  v%0 := a
  sawritef(" %x2*n", a)
  sys(Sys_sound, 7, midifd, v, 1)
}

AND wrmid2(a, b) BE
{ LET v = VEC 1
  v%0, v%1 := a, b
  sawritef(" %x2 %x2*n", a, b)
  sys(Sys_sound, 7, midifd, v, 2)
}

AND wrmid3(a, b, c) BE
{ LET v = VEC 1
  v%0, v%1, v%2 := a, b, c
  sawritef(" %x2 %x2 %x2*n", a, b, c)
  sys(Sys_sound, 7, midifd, v, 3)
}

AND copyfile(name) BE
{ LET stdin = input()
  LET instr = findinput(name)

  UNLESS instr DO
  { sawritef("Trouble with file: %s*n", name)
    RETURN
  }

  sawritef("*nCopying file %s*n", name)

  selectinput(instr)

  { LET byte = binrdch()
    IF byte<0 BREAK
    sawritef("*nWriting MIDI byte: %x2*n", byte)
    wrmid1(byte)
    delay(50)
  } REPEAT

  endstream(instr)
  selectinput(stdin)
}
