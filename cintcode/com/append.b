SECTION "APPEND"

GET "libhdr"

GLOBAL
{
inputstream:ug
outputstream
}

LET start() = VALOF
{ LET argv = VEC 50
  LET rc = 0
  LET ch = 0
  LET oldoutput = output()

  inputstream := 0
  outputstream := 0

  UNLESS rdargs("FROM/A,TO/K", argv, 50) DO
  { writes("Bad args*n")
    rc := 20
    GOTO exit
  }

  inputstream := findinput(argv!0)         // FROM
  UNLESS inputstream DO { writef("Can*'t open %s*n", argv!0)
                          rc := 20
                          GOTO exit
                        }
  selectinput(inputstream)

  IF argv!1 DO                             // TO/K
  { outputstream := findappend(argv!1)
    IF outputstream=0 DO
    { writef("Can*'t open %s*n", argv!1)
      rc := 20
      GOTO exit
    }
    selectoutput(outputstream)
  }

  { LET tab = 0

    { ch := rdch()
      IF intflag() DO { IF tab DO wrch('*n')
                        selectoutput(oldoutput)
                        writes("****BREAK*n")
                        rc := 5
                        GOTO exit
                      }
      UNLESS tab DO { IF ch=endstreamch GOTO exit
                    }
      SWITCHON ch INTO
      { CASE '*c':
        CASE '*n':
        CASE '*p': wrch(ch); BREAK

        CASE '*t': { wrch('*s')
                     tab := tab+1
                   } REPEATUNTIL tab REM 8 = 0
                   LOOP

        DEFAULT:   wrch(ch)
                   tab := tab+1
                   LOOP

        CASE endstreamch:
//                wrch('*n')
                  GOTO exit
      }
    } REPEAT
  } REPEAT

exit:
  IF inputstream  DO endstream(inputstream)
  IF outputstream DO endstream(outputstream)
  RESULTIS rc
}
