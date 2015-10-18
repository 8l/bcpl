GET "libhdr"

GLOBAL {
  datav:   200
  datap:   201
  refsv:   202
  fromstr: 203
  ch:      204
  wrdist:  205
  bitlen:  206
}

LET start() = VALOF
{ LET argv = VEC 50

  IF rdargs("FROM,TO/K", argv, 50)=0 DO
  { writef("Bad arguments for labopt*n")
    RESULTIS 20
  }

  fromstr := findinput("LABS")

  datav := getvec(50000)
  refsv := getvec(10000)

  FOR i = 0 TO 10000 DO refsv!i := 0

  selectinput(fromstr)
  selectoutput(findoutput("RES"))

  datap := 0
  bitlen := 0
  ch := rdch()

  { SWITCHON ch INTO
    { DEFAULT: ch := rdch(); LOOP

      CASE endstreamch: BREAK

      CASE '#': ch := rdch()
                wrlabs()
                datap := 0
                FOR i = 0 TO 10000 DO refsv!i := 0
                LOOP

      CASE 'L': { LET lab = 0
                  ch := rdch()
                  WHILE '0'<=ch<='9' DO
                  { lab := 10*lab + ch - '0'
                    ch := rdch()
                  }
                  IF ch=':' DO { lab := -lab; ch := rdch() }
                  datap := datap+1
                  datav!datap := lab
                  IF lab>0 DO refsv!lab := refsv!lab + 1
                  LOOP
                }
    }
  } REPEAT

  endwrite()
  endread()

  freevec(refsv)
  freevec(datav)
  RESULTIS 0
}

AND wrlabs() BE
{ LET curlab = 0
  LET count = 0
  LET sign, scount = +1, 0

  writef("wrlabs called*n")
  FOR i = 1 TO 10000 DO
  { LET refs = refsv!i
    IF refs=0 BREAK
    IF refs=1 DO { count := count+1
                   writef("%i3: %i2*n", i, refs)
                   LOOP
                 }
    writef("%i3: %i2  ", i, refs)
    IF count DO
    { LET mod = (count-1)>>2
      WHILE mod DO { mod := mod-1
                     writef(" %n", mod&7)
                     mod := mod>>3
                     bitlen := bitlen+4
                   }
      writef(" S%n", (count-1)&3)
      bitlen := bitlen+4
      count := 0
    } 
    { LET mod = (refs-1)>>2
      WHILE mod DO { mod := mod-1
                     writef(" %n", mod&7)
                     mod := mod>>3
                     bitlen := bitlen+4
                   }
      writef(" V%n", (refs-1)&3)
      bitlen := bitlen+4
    } 
    newline()
  }
  newline()
  FOR i = 1 TO datap DO
  { LET lab = datav!i
    IF lab<0 DO { curlab := -lab; LOOP }
    TEST lab<=curlab
    THEN { LET dist = 0
           FOR i = lab TO curlab DO IF refsv!i>0 DO dist := dist+1
           IF sign>0 DO
           { writef("sign count: %n  ", scount)
             wrsigncount(scount)
             newline()
             sign, scount := -1, 0
           }
           scount := scount+1
           wrdist(sign, dist)
           newline()
           refsv!lab := refsv!lab-1
         }
    ELSE { LET dist = 0
           FOR i = curlab TO lab DO IF refsv!i>0 DO dist := dist+1
           IF sign<0 DO
           { writef("sign count: %n  ", scount)
             wrsigncount(scount)
             newline()
             sign, scount := +1, 0
           }
           scount := scount+1
           wrdist(sign, dist)
           newline()
           refsv!lab := refsv!lab-1
         }
    writef("bitlen: %n*n", bitlen)
  }
  IF scount DO 
  { writef("sign count: %n  ", scount)
    wrsigncount(scount)
    newline()
    sign, scount := +1, 0
  }

  wrdist(+1, 0)
  newline() 
  writef("bitlen: %n bits (%n bytes)*n", bitlen, (bitlen+7)/8)
}

AND wrsigncount(k) BE
{ k := k-1
  WHILE k DO { k := k-1
               writef(" %b2", k REM 3 + 1)
               k := k/3
               bitlen := bitlen+2
             }
  writef(" 00")
  bitlen := bitlen+2
}

STATIC {
 sval=0
 srep=0
 bval=0
 binc=0
 brep=0
 lastbig=FALSE
 szcount=0
}

LET wrdist(s, d) BE
{ LET signch = s>0 -> '+', '-'

  IF d=0 DO
  { IF szcount DO
    { writef("size count: %n  ", szcount)
      wrszcount(szcount)
      newline()
      lastbig := TRUE
      szcount := 0
    }
    writef("%c%n ", signch, d)

    IF srep DO { writef(" %n", sval)
                 wrsrep(srep)
               }
    sval, srep := d, 0

    IF brep DO wrbrep(brep)
    bval, binc, brep := d, 0, 0

    RETURN
  }
  TEST d<=4
  THEN { IF lastbig DO
         { writef("size count: %n  ", szcount)
           wrszcount(szcount)
           newline()
           lastbig := FALSE
           szcount := 0
         }
         writef("%c%n ", signch, d)
         szcount := szcount+1
         IF d=sval DO { srep := srep+1; RETURN }
         IF srep DO { writef(" %n", sval)
                      wrsrep(srep)
                    }
         writef(" V%n", d)
         bitlen := bitlen+2
         sval, srep := d, 0
       }
  ELSE { UNLESS lastbig DO
         { writef("size count: %n  ", szcount)
           wrszcount(szcount)
           newline()
           lastbig := TRUE
           szcount := 0
         }
         writef("%c%n ", signch, d)
         szcount := szcount+1
         IF d=bval+binc*(brep+1) DO { brep := brep+1; RETURN }
         IF brep DO wrbrep(brep)
         IF d=bval-1 DO { binc, brep := -1, 1; RETURN }
         wrbval(d-4)
         bval, binc, brep := d, 0, 0
       }
} 

AND wrsrep(k) BE
{ k := k-1
  WHILE k DO { k := k-1
               writef(" %b2", k REM 3 + 1)
               k := k/3
               bitlen := bitlen+2
             }
  writef(" 00")
  bitlen := bitlen+2
}

AND wrszcount(k) BE
{ k := k-1
  WHILE k DO { k := k-1
               writef(" %b2", k REM 3 + 1)
               k := k/3
               bitlen := bitlen+2
             }
  writef(" 00")
               bitlen := bitlen+2
}

AND wrbrep(k) BE
{ LET mod = (k-1)>>1
  WHILE mod DO { mod := mod-1
                 writef(" M%n", mod&7)
                 mod := mod>>3
                 bitlen := bitlen+4
               }
  TEST binc=0 THEN writef(" R%n",  k&1)
              ELSE writef(" R%nD", k&1)
  bitlen := bitlen+4
}

AND wrbval(k) BE
{ LET mod = (k-1)>>2
  WHILE mod DO { mod := mod-1
                 writef(" M%n", mod&7)
                 mod := mod>>3
                 bitlen := bitlen+4
               }
  writef(" B%n",  k&3)
  bitlen := bitlen+4
}



