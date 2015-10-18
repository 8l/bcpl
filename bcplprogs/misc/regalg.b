SECTION "regalg"

GET "libhdr"

MANIFEST {
spaceupb=10000
}


GLOBAL { spacev:200; spacet:201
retcode:202
data:   204
}

LET start() = VALOF
{ LET argv = VEC 50
  LET datafilename = "regdata"
  LET data = 0

  IF rdargs("DATAFILE", argv, 50)=0 DO
  { writef("Bad argument for regalg*n")
    RESULTIS 20
  }

  data, spacev := 0, 0

  UNLESS argv!0=0 DO datafilename := argv!0

  writef("Register allocation algorithm entered, datafile %s*n",
          datafilename)


  spacev := getvec(spaceupb)
  spacet := spacev + spaceupb

  IF spacev=0 DO
  { writef("Unable to allocate work space*n")
    RESULTIS 20
  }

  data := findinput(datafilename)
  IF data=0 DO
  { writef("Unable to open file %s*n", datafilename)
    retcode := 20
    GOTO ret
  }

  rddata()

  solve()

ret:
  UNLESS spacev=0 DO freevec(spacev)
  UNLESS data=0 DO { selectinput(data); endread() }

  RESULTIS 0
} 

AND rddata() BE
{ writes("rddata*n")
}

AND solve() BE
{ writes("solve*n")
}
