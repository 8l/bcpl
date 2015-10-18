GET "libhdr"

LET start() = VALOF
{ LET data = findinput("../../Cintpos/cintpos/junk")

  LET res  = findoutput("../../Cintpos/cintpos/junk1")  

  selectinput(data)
  selectoutput(res)

  { LET ch = rdch()
    IF ch=endstreamch BREAK
    IF ch='\' DO
    { LET ch1 = rdch()
      LET ch2 = rdch()
      ch := hexval(ch1)<<4 | hexval(ch2)
      IF ch<0 DO writef("*nBad hex escape \%c%c*n", ch1, ch2)
    }
    wrch(ch)
  } REPEAT

  endread()
  endwrite()
  RESULTIS 0
}

AND hexval(k) = '0'<=k<='9' -> k-'0',
                'A'<=k<='F' -> k-'A' + 10,
                 -1

