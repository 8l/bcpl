GET "libhdr"

LET start() = VALOF
{ LET instr = findinput("sintab")
  LET outstr = findoutput("res")
  selectinput(instr)
  selectoutput(outstr)

  { LET ch=rdch()
    LET layout = 0

    { LET val = 0
      LET d = 0
      IF ch=endstreamch BREAK

      WHILE ch='*n' | ch=' ' DO ch := rdch()
      IF ch='.' DO ch := rdch()
      WHILE '0'<=ch<='9' | 'A'<=ch<='F' DO
      { LET dig = 100
        d := d+1
        IF '0'<=ch<='9' DO dig := ch-'0'
        IF 'A'<=ch<='F' DO dig := ch-'F'
        IF dig>15 BREAK
        IF d<=8 DO val := (val<<4) + dig
        IF d=9 & dig>=8 DO val := val+1
        ch := rdch()
      }
      IF layout MOD 7 = 0 DO newline()
      layout := layout+1
      writef("#x%x8,", val)
    } REPEAT
  }
  newline()
  endwrite()
  endread()
  RESULTIS 0
}
