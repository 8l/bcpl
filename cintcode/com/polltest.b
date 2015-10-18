GET "libhdr"

LET start() = VALOF
{ LET timev = VEC 2
  writef("Poll Readch test entered*n")
  FOR i = 1 TO 100 DO
  { LET ch = sys(Sys_pollsardch)
    datstamp(timev)
    writef("%6.3d ", timev!1 MOD 60_000)
    SWITCHON ch INTO
    { DEFAULT:  writef("%i3 '%c'*n", ch, ch); ENDCASE
      CASE -1:  writef("EOF*n"); ENDCASE
      CASE -3:  writef("POLLCH*n"); ENDCASE
    }
    delay(20)
  }
  writef("End of test*n")
}
