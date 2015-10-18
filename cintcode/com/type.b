// (C) Copyright 1978 Tripos Research Group
//     University of Cambridge
//     Computer Laboratory

SECTION "TYPE"

GET "libhdr"

GLOBAL
{
inputstream:ug
outputstream
numbers
linenumber
}

LET start() = VALOF
{ LET argv = VEC 50
  LET rc = 0
  LET ch = 0
  LET oldoutput = output()

  inputstream := 0
  outputstream := 0

  UNLESS rdargs("FROM/A,TO,OPT/K", argv, 50) DO
  { writes("Bad args*n")
    rc := 20
    GOTO exit
  }

  inputstream := findinput(argv!0)
  UNLESS inputstream DO { writef("Can*'t open %s*n", argv!0)
                          rc := 20
                          GOTO exit
                        }
  selectinput(inputstream)

  UNLESS argv!1=0 DO
  { outputstream := findoutput(argv!1)
    IF outputstream=0 DO
    { writef("Can*'t open %s*n", argv!1)
      rc := 20
      GOTO exit
    }
    selectoutput(outputstream)
  }

  numbers := FALSE

  IF argv!2 DO
  { LET opts = argv!2
    FOR i = 1 TO opts%0 SWITCHON capitalch(opts%i) INTO
    { CASE 'N': numbers := TRUE
                ENDCASE
    }
  }

  linenumber := 1

  { LET tab = 0

    { ch := rdch()
      IF intflag() DO { IF tab DO wrch('*n')
                        selectoutput(oldoutput)
                        writes("****BREAK*n")
                        rc := 5
                        GOTO exit
                      }
      UNLESS tab DO { IF ch=endstreamch GOTO exit
                      IF numbers DO writef("%I5  ", linenumber)
                    }
      SWITCHON ch INTO
      { CASE '*c':
        CASE '*n':
        CASE '*p': linenumber := linenumber+1; wrch(ch); BREAK

        CASE '*e': linenumber := linenumber+1; tab := 8; LOOP

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
