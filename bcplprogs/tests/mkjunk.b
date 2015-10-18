SECTION "mkjunk"

GET "libhdr"

LET start() = VALOF
{ LET argv = VEC 30
  LET stdout = output()
  LET scb, size = 0, 4096+20 // in bytes
  LET pv = VEC 1

  UNLESS rdargs("SIZE,NAME", argv, 30) DO
  { writef("Bad arguments for mkjunk*n")
    stop(20)
  }

  IF argv!0 & string.to.number(argv!0) DO size := result2

  UNLESS argv!1 DO argv!1 := "junk"

  writef("mkjunk: %s  size: %n*n", argv!1, size)

  scb := findoutput(argv!1)
  UNLESS scb DO
  { writef("Can't open file '%s'*n", argv!1)
    stop(20)
  }
  selectoutput(scb)

  { LET rowstart = 0
    FOR i = 1 TO size DO 
    { LET col = i REM 50
      LET ch = i-1
      IF col=1 DO ch := rowstart/10000
      IF col=2 DO ch := rowstart/1000
      IF col=3 DO ch := rowstart/100
      IF col=4 DO ch := rowstart/10
      IF col=5 DO ch := rowstart
      ch := ch REM 10 + '0'
      IF col=6 DO ch := ':'
      IF col=0 DO ch, rowstart := '*n', i
      binwrch(ch)
    }
  }
  endwrite()

  selectoutput(stdout)
  RESULTIS 0
}


