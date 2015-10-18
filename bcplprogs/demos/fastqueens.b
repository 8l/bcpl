GET "libhdr"
 
GLOBAL { count:ug; all  }
 
LET try(n) BE
{ LET poss = all

  SWITCHON n INTO
  {
    DEFAULT: writef("n=%n out of range*n", n)
             RETURN

    CASE 14:
    CASE 13:
    CASE 12:
    CASE 11:
    CASE 10:
    CASE  9:
    CASE  8:
         poss8 := all
         ld8, row8, rd8 := 0,0,0
         GOTO L8
    CASE  7:
    CASE  6:
    CASE  5:
    CASE  4:
    CASE  3:
    CASE  2:
    CASE  1:

    L14:
    L13:
    L12:
    L11:
    L10:
    L9:
        RETURN
    L8: 
        p8 := poss8 & -poss8
        UNLESS p8 GOTO L9
        ld7   := (ld8+p8)<<1
        rd7   := (rd8+p8)>>1
        row7  := row8+p8
        poss7 := all & ~(ld8 | row8 | rd8)
    L7:
        p7 := poss7 & -poss7
        UNLESS p7 GOTO L8
        ld6   := (ld7+p7)<<1
        rd6   := (rd7+p7)>>1
        row6  := row7+p7
        poss6 := all & ~(ld6 | row6 | rd6)
    L6:
    L5:
    L4:
    L3:
    L2:
    L1:
        IF poss1 DO count := count+1
        GOTO L2
}

LET start() = VALOF
{ all := 1
  
  FOR n = 1 TO 14 DO
  { count := 0
    try(n)
    writef("Number of solutions to %i2-queens is %i7*n", n, count)
    all := 2*all + 1
  }

  RESULTIS 0
}
