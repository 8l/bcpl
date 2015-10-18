SECTION "XDECODE"

GET "libhdr"

/*
This program decodes a file encoded by the xencode command.
See xencode.b for details.

Written by Martin Richards (c) September 2008
*/

GLOBAL
{
inputstream:ug
outstream
hashcount
listing
}

LET start() = VALOF
{ LET count = 0
  LET argv = VEC 50
  LET fromname = "data"
  LET toname = VEC 256/bytesperword
  LET rc = 0
  LET ch = 0
  LET stdout = output()

  inputstream := 0
  outstream := 0
  listing := FALSE
  newline()

  IF rdargs("FROM/A,LIST/S", argv, 50) = 0 DO
  { writes("Bad args for XDECODE*n")
     rc := 20
     GOTO exit
  }

  fromname := argv!0
  listing  := argv!1

  inputstream := findinput(fromname)
  UNLESS inputstream DO { writef("Can*'t open %s*n", fromname)
                          rc := 20
                          GOTO exit
                        }
  selectinput(inputstream)

  hashcount := 0

next:
  // Start of main extraction loop
  selectoutput(stdout)
  
  { // Find the next separator
    ch := rdch()

    IF ch=endstreamch GOTO exit

    IF ch='#' DO
    { hashcount := hashcount+1

      { ch := rdch()
        IF ch=endstreamch GOTO exit
        UNLESS ch='#' BREAK
        hashcount := hashcount+1
      } REPEAT

      // Hashcount = number of consecutive '#'s
      // If >= 6 then we have a separator. It should be of the form
      // ######filename#
      IF hashcount>=6 DO
      { // Read the filename into toname
        LET len = 0
        toname%0 := 0
        UNTIL ch='#' | ch='*n' DO
        { IF ch=endstreamch GOTO exit
          len := len+1
          IF len>255 BREAK
          toname%0, toname%len := len, ch
          ch := rdch()
        }

        //writef("Item separator found*n")
        //FOR i = 1 TO hashcount DO wrch('#')
        //writef("%s%c*n", toname, ch)

        IF toname%0=1 & toname%1='+' DO
        { // Final terminator found
          GOTO exit
        }

        UNLESS ch='#' & 0<len<256 & hashcount>=6 DO
        { writef("Bad item separator*n")
          FOR i = 1 TO hashcount DO wrch('#')
          writef("%s%c*n", toname, ch)
          GOTO exit
        }
        BREAK
      }
    }
  } REPEATUNTIL ch=endstreamch

  IF ch=endstreamch GOTO exit

  writef("Decoding to file: %s*n", toname)

  IF listing DO toname := "NIL:"

  outstream := 0

  UNLESS listing DO
  { outstream := findoutput(toname)
    UNLESS outstream DO
    { writef("Can*'t open %s*n", toname)
      rc := 20
      GOTO exit
    }

    selectoutput(outstream)
  }

  { ch := rdch()

    SWITCHON ch INTO
    { DEFAULT:   IF outstream DO wrch(ch)
                 LOOP

      CASE endstreamch:
                 GOTO exit

      CASE '.':  IF outstream DO wrch(' ')
                 LOOP

      CASE '=':          // '=' must be escaped!
      CASE '*n': LOOP

      CASE '#':  // Either an escaped character or the start of a separator
               { LET a = rdch()
                 LET b = rdch()
                 IF a='#' & b='#' DO
                 { // It must be a separator
                   hashcount := 3
                   IF outstream DO endstream(outstream)
                   outstream := 0
                   selectoutput(stdout)
                   GOTO next
                 }
                 IF a=endstreamch | b=endstreamch GOTO exit
                 // Otherwise write escaped character
                 IF outstream DO wrch((value(a)<<4) + value(b))
                 LOOP
               }
    }
  } REPEAT

exit:
  IF inputstream  DO { endstream(inputstream); inputstream := 0 }
  IF outstream    DO { endstream(outstream);   outstream := 0 }
  RESULTIS rc
}

AND value(ch) = VALOF SWITCHON ch INTO
{ DEFAULT:
    writef("##%x2##", ch)
    RESULTIS 0

  CASE '0':CASE '1':CASE '2':CASE '3':CASE '4':
  CASE '5':CASE '6':CASE '7':CASE '8':CASE '9':
    RESULTIS ch-'0'
    
  CASE 'A':CASE 'B':CASE 'C':CASE 'D':CASE 'E':
  CASE 'F':
    RESULTIS ch - 'A' + 10

  CASE 'a':CASE 'b':CASE 'c':CASE 'd':CASE 'e':
  CASE 'f':
    RESULTIS ch - 'a' + 10
}
