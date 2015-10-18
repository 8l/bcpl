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

LET flush() BE RETURN

LET start() = VALOF
{ LET argv = VEC 50
  LET rc = 0
  LET ch = 0
  LET oldoutput = output()

  inputstream := 0
  outputstream := 0

  UNLESS rdargs("FROM/A,TO,N/S", argv, 50) DO
  { writes("Bad args*n")
    rc := 20
    GOTO exit
  }

  inputstream := findinput(argv!0)
  IF inputstream = 0 DO { writef("Can*'t open %s*n", argv!0)
                          rc := 20
                          GOTO exit
                        }
  selectinput(inputstream)

  IF argv!1 DO { outputstream := findoutput(argv!1)
                 UNLESS outputstream DO
                 { writef("Can*'t open %s*n", argv!1)
                   rc := 20
                   GOTO exit
                 }
                 selectoutput(outputstream)
               }

  numbers := argv!2

  linenumber := 1

  { LET tab = 0

    { ch := rdch()
      IF intflag() DO { UNLESS tab=0 DO wrch('*n')
                        selectoutput(oldoutput)
                        writes("****BREAK*n")
                        rc := 5
                        GOTO exit
                      }
      IF tab=0 DO { IF ch=endstreamch GOTO exit
                    IF numbers DO writef("%i5  ", linenumber)
                  }
      SWITCHON ch INTO
      { CASE '*c':
        CASE '*n':
        CASE '*p': linenumber := linenumber+1; wrch(ch); 
                   flush(); BREAK

        CASE '*e': linenumber := linenumber+1; tab := 8; LOOP

        CASE '*t':
                   { wrch('*s')
                     tab := tab+1
                   } REPEATUNTIL tab REM 8 = 0
                   LOOP

        DEFAULT:   wrch(ch);         tab := tab+1;  LOOP

        CASE endstreamch:
                   wrch('*n'); flush();               GOTO exit
      }
    } REPEAT
  } REPEAT

exit:
  IF inputstream  DO endstream(inputstream)
  IF outputstream DO endstream(outputstream)
  RESULTIS rc
}
