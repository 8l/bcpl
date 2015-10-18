SECTION "DETAB"

GET "libhdr"

GLOBAL
{
inputstream:200
outputstream:201
tabsep:202
}

LET start() = VALOF
{ LET argv = VEC 50
  LET rc = 0
  LET ch = 0
  LET oldoutput = output()

  inputstream := 0
  outputstream := 0

  IF rdargs("FROM/A,TO/K,SEP/K", argv, 50) = 0 DO
  { writes("Bad args for DETAB*n")
    rc := 20
    GOTO exit
  }

  inputstream := findinput(argv!0)
  IF inputstream = 0 DO { writef("Can*'t open %s*n", argv!0)
                          rc := 20
                          GOTO exit
                        }
  selectinput(inputstream)

  UNLESS argv!1=0 DO { outputstream := findoutput(argv!1)
                       IF outputstream=0 DO
                       { writef("Can*'t open %s*n", argv!1)
                         rc := 20
                         GOTO exit
                       }
                       selectoutput(outputstream)
                     }
  tabsep := 4
  IF argv!2 DO tabsep := str2numb(argv!2)

  { LET tab = 0

    { ch := rdch()
      IF intflag() DO { UNLESS tab=0 DO wrch('*n')
                        selectoutput(oldoutput)
                        writes("****BREAK*n")
                        rc := 5
                        GOTO exit
                      }
      IF tab=0 DO { IF ch=endstreamch GOTO exit
                  }
      SWITCHON ch INTO
      { CASE '*n': CASE '*p':
                   wrch(ch)
                   BREAK

        CASE '*c': BREAK

        CASE '*t':
                 { wrch('*s')
                   tab := tab+1
                 } REPEATUNTIL tab REM tabsep = 0
                 LOOP

        DEFAULT:   wrch(ch)
                   tab := tab+1
                   LOOP

        CASE endstreamch:
                   wrch('*n')
                   GOTO exit
      }
    } REPEAT
  } REPEAT

exit:
  UNLESS inputstream=0 DO
  { selectinput(inputstream)
    endread()
  }
  UNLESS outputstream=0 | outputstream=oldoutput DO
  { selectoutput(outputstream)
    endwrite()
  }
  RESULTIS rc
}
