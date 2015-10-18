SECTION "JOIN"

GET "libhdr"

LET start() = VALOF
{ LET argv = VEC 130
  LET temp = "TEMPFILE"
  LET tofilename = 0
  LET oldoutput = output()
  LET oldinput = input()
  LET inputstream = 0
  LET outputstream = 0
  LET rc = 0
  IF rdargs(",,,,,,,,,,,,,,,TO/A/K", argv, 100)=0 DO
  { writef("Bad args for JOIN*N")
    RESULTIS 20
  }
  tofilename := argv!15

  IF compstring(tofilename, "**")=0 DO temp := tofilename

  outputstream := findoutput(temp)
  IF outputstream=0 DO { writef("Can't open %s*n", temp)
                         rc := 20
                         GOTO ret
                       }
  selectoutput(outputstream)
  FOR i = 0 TO 14 DO
  { LET filename = argv!i
    IF filename=0 BREAK
    inputstream := findinput(filename)
    IF inputstream=0 DO  { selectoutput(oldoutput)
                           writef("Can't open %s*n", filename)
                           rc := 20
                           GOTO ret
                         }
    selectinput(inputstream)

    { LET ch = rdch()
      IF ch=endstreamch BREAK
      IF intflag() DO { selectoutput(oldoutput)
                        writes("****BREAK*n")
                        rc := 10
                        GOTO ret
                      }
      wrch(ch)
    } REPEAT

    endread()
    inputstream := 0
  }
  UNLESS outputstream=oldoutput DO { endwrite(); outputstream := 0 }

  UNLESS compstring(tofilename, "**")=0 IF renamefile(temp, tofilename)=0 DO
  { rc := 20
    selectoutput(oldoutput)
    writef("Can't rename %s as %s*N", temp, tofilename)
  }

ret:
  IF outputstream UNLESS outputstream=oldoutput DO
                  { selectoutput(outputstream)
                    endwrite()
                  }
  IF inputstream  UNLESS inputstream=oldinput DO
                  { selectinput(inputstream)
                    endread()
                  }
  selectoutput(oldoutput)
  UNLESS compstring(tofilename, "**")=0 DO deletefile(temp)
  RESULTIS rc
}
