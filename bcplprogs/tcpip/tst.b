GET "libhdr"
GET "tcp.h"

LET start() = VALOF
{ 
  writef("Testing callc*n")

  FOR fno = 0 TO 5 DO
  { writef("sys(Sys_callc, %n, %n, %n)",
                fno, 100+fno, 100-fno)
    deplete(cos)
    sys(Sys_delay, tickspersecond)
    writef(" => %n*n",
            sys(Sys_callc, fno, 100+fno, 100-fno))
  }
  writef("*nEnd of test*n")
  RESULTIS 0
}
