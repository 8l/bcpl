// This program test random access to files
// for both binary character i/o and record i/o.

// Implemented by Martin Richards 12/7/04

SECTION "ranio"

GET "libhdr"

GLOBAL {
  reclen: ug
  recno           // current record number, unless reclen=1
  rec             // The record buffer, unless reclen=1
  mode            // = 'C' or 'X'
  stdin
  stdout
}

LET start() = VALOF
{ LET posv = VEC 1
  LET file, ramv = 0, 0
  LET res = 0
  LET filename = "junk"
  LET stdin, stdout = input(), output()
  LET argv = VEC 30

  stdin := input()
  stdout := output()

  UNLESS rdargs("FILE", argv, 30) DO
  { writef("Bad arguments for seek*n")
    stop(20)
  }

  IF argv!0 DO filename := argv!0

  writef("*nFile: %s*n", filename)

  file := findinoutput(filename)

  UNLESS file DO
  { writef("Can't open file '%s'*n", filename)
    stop(20)
  }

  IF compstring(filename, "ram:")=0
  { LET end = 100
    LET bufend = file!scb_bufend
    selectoutput(file)
    FOR i = 0 TO bufend-1 DO wrch(i<end -> 'A' + i REM 26, 0)
    selectoutput(stdout)
    writef("RAM stream %n bufen=%n  end=%n bytes created*n", file, bufend, end)
  } 

  reclen, recno, rec, mode := 1, 0, 0, 'C'
  posv!0, posv!1 := 0, 0

  writef("Current position is 0 in character mode*n*n")

help:
  writef("*nPossible commands:*n*n")
  writef("H     Output help information*n")
  writef("Q     Quit*n")
  writef("D     Enter the debugger*n")
  writef("P n   Point to position n in the file*n")
  writef("L n   Set the record length to n (n>0)*n")
  writef("N     Output the current file position*n")
  writef("R     Read and display on record from this position*n")
  writef("C     Set character mode*n")
  writef("X     Set hex mode*n")
  writef("Wc    Write a record filled with c's at this position*n*n")

  { LET ch = ?
    writef("*c# ")
    deplete(cos)
    ch := rdch()
    SWITCHON capitalch(ch) INTO
    { DEFAULT:  writef("*nUnexpected ch=%n '%c'*n", ch, ch); LOOP
      CASE 'H': GOTO help

      CASE '*s':
      CASE '*n': LOOP

      CASE endstreamch:
      CASE 'Q': BREAK

      CASE 'D': abort(1000); LOOP
    
      CASE 'P': TEST reclen=1                    // Set file position
                THEN { posv!1 := rdn()
                       posv!0 := posv!1  /  4096
                       posv!1 := posv!1 REM 4096
                       point(file, posv)
                     }
                ELSE { recno := rdn()
                       IF recno<0 DO recno := 0
                     }
                // Intentional fall through

      CASE 'N': TEST reclen=1                    // Display file position
                THEN { note(file, posv)
                       writef("*nBlock = %i4 Pos = %i4*n", posv!0, posv!1)
                       LOOP
                     }
                ELSE { UNLESS recordpoint(file, recno) DO
                       { writef("Unable to point to record %n*n", recno)
                         LOOP
                       }
                       recno := recordnote(file)
                       writef("Record length: %i6*n", reclen)
                       writef("Record number: %i6*n", recno)
                     }
                LOOP

      CASE 'L': reclen := rdn()
                UNLESS reclen>0 DO reclen := 1
                IF rec DO
                { freevec(rec)  // Free the record buffer, if any
                  rec := 0
                }
                IF reclen=1 LOOP        // Loop if single character mode
                // Allocate the record buffer
                rec := getvec((reclen-1)/bytesperword)
                UNLESS rec DO
                { writef("*nCannot allocate a buffer for %n bytes*n", reclen)
                  reclen := 1
                  LOOP
                }
                setrecordlength(file, reclen)
                writef("Record length set to %n*n", reclen)
                LOOP

      CASE 'R': TEST reclen=1
                THEN { selectinput(file)
                       note(file, posv)
                       writef("*nBlock = %i4 Pos = %i4  Read:  ",
                               posv!0, posv!1)
                       ch := binrdch()
                       selectinput(stdin)
                       TEST ch=endstreamch
                       THEN writef(" EOF*n")
                       ELSE writef(" ch = %i3 '%c'*n", ch, ch)
                     }
                ELSE { writef("Record %i3 (len=%n) is:*n", recno, reclen)
                       TEST get_record(rec, recno, file)
                       THEN { wrrec(rec)
                              recno := recno+1
                            }
                       ELSE { writef(" EOF*n")
                            }
                     }
                LOOP

      CASE 'W': TEST reclen=1
                THEN { note(file, posv)
                       ch := rdch()
                       IF ch='*n' LOOP
                       IF ch=endstreamch BREAK
                       writef("*nBlock = %i4 Pos = %i4  Write:  ch = %i3 '%c'*n",
                               posv!0, posv!1, ch, ch)
                       selectoutput(file)
                       UNLESS binwrch(ch) DO
                       { selectoutput(stdout)
                         writef("Unable to write '%c'*n", ch)
                       }
                       selectoutput(stdout)
                     }
                ELSE { ch := rdch()
                       FOR i = 0 TO reclen-1 DO rec%i := ch
                       UNLESS put_record(rec, recno, file) DO
                       { writef("unable to write record number %n*n",
                                 recno)
                         LOOP
                       }
                       writef("record of '%c's written at record number %n*n",
                               ch, recno)
                       recno := recno+1
                     }
                LOOP

      CASE 'C': mode := 'C'
                writef("Now in character mode*n")
                LOOP
      CASE 'X': mode := 'X'
                writef("Now in hex mode*n")
                LOOP
    }
  } REPEAT

  newline()

  IF file DO endstream(file)
  IF ramv DO freevec(ramv)
  RESULTIS 0
}

AND rdn() = VALOF
{ LET res = 0
  LET ch = rdch()
  WHILE ch='*s' DO ch := rdch()
  WHILE '0'<=ch<='9' DO
  { res := 10*res + ch -'0'
    ch := rdch()
  }
  unrdch()
  RESULTIS res
}

AND wrrec(rec) BE TEST mode='C'
THEN { FOR i = 0 TO reclen-1 DO
       { wrch(rec%i)
         IF i REM 50 = 49 DO newline()
       }
       UNLESS reclen REM 50 = 0 DO newline()
       newline()
     }
ELSE { FOR i = 0 TO reclen-1 DO
       { writef(" %x2", rec%i)
         IF i REM 20 = 19 DO newline()
       }
       UNLESS reclen REM 20 = 0 DO newline()
     }
