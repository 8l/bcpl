GET "libhdr"

MANIFEST { vecstatsupb=20000 }

LET start() = VALOF
{ LET v = rtn_vecstatsv!rootnode
  LET layout = 0
  writef("getvec-ed blocks (requested size : number allocated):*n*n")

  //sys(Sys_putsysval, v+3, 1000)
  //sys(Sys_putsysval, v+10, 2000)
  //sys(Sys_putsysval, v+300, 3000)

  FOR i = 0 TO vecstatsupb DO
  { LET val = sys(Sys_getsysval, v+i)
    IF val DO
    { writef(" %i5:%i4", i, val)
      layout := layout+1
      IF layout REM 6 = 0 DO newline()
    }
  }
  newline()
}
