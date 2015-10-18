GET "libhdr"

LET start() = VALOF
{ LET argv      = VEC 50
  LET instream  = 0
  LET outstream = 0
  LET filename  = "data" 
  LET sum       = 314159
  LET res       = 0
  LET ignorews  = FALSE // Ignore white space flag

  IF rdargs("FROM/A,TO/K,IGNOREWS/S", argv, 50) = 0 DO
  { writes("Bad arguments for CHECKSUM*n")
    res := 20
    GOTO fin
  }

  filename := argv!0               // FROM/A
  instream := findinput(filename)
  UNLESS instream DO { writef("can't open %s*n", filename)
                       res := 20
                       GOTO fin
                     }
  selectinput(instream)

  IF argv!1 DO                     // TO/K
  { outstream := findoutput(argv!1)
    UNLESS outstream DO { writef("can't open %s*n", argv!1)
                          endread()
                          res := 20
                          GOTO fin
                        }
  }

  ignorews := argv!2               // IGNOREWS/S

  { LET ch = rdch()
    IF ch=endstreamch BREAK
    IF intflag() DO { writes("*n******BREAK*n")
                      GOTO fin
                    }
    IF ignorews SWITCHON ch INTO
    { DEFAULT:  ENDCASE
      CASE '*n':
      CASE '*c':
      CASE '*p':
      CASE '*t':
      CASE '*b':
      CASE '*s': LOOP
    }
       
    sum := (13*sum + ch) MOD 1_000_000
  } REPEAT

  IF outstream DO selectoutput(outstream)
  writef("%i6 %s*n", sum, filename)

fin:
  IF instream  DO endstream(instream)
  IF outstream DO endstream(outstream)

  RESULTIS 0
}
