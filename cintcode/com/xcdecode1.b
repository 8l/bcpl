SECTION "XCDECODE"

GET "libhdr"

/*
This program decodes a file encoded by the xcencode command.
See xcencode.b for details.

Written by Martin Richards (c) September 2008
*/

GLOBAL
{
inputstream:ug
outstream
stdout
hashcount
listing
prevch
repcount
digits
wr
wrcount
wrc
rdc
}

LET rdc() = VALOF
{ LET ch = rdch()
  // Ignore all control characters other than *n
  IF 0<=ch<=31 UNLESS ch='*n' LOOP
sawritef("rdc: %i3 '%c'*n", ch, ch)
  RESULTIS ch
} REPEAT

LET wrc(ch) BE
{ wrcount := wrcount+1
sawritef("wrc: %n '%c'*n", wrcount, ch)
//abort(1000)
  IF wrcount MOD  10000 = 0 DO
  { LET out = output()
    selectoutput(stdout)
    IF wrcount MOD 500000 = 0 DO newline()
    wrch('.')
    selectoutput(out)
  }
  //wr(ch)
}

LET start() = VALOF
{ LET count = 0
  LET argv = VEC 50
  LET fromname = "data"
  LET toname = VEC 256/bytesperword
  LET rc = 0
  LET ch = 0
  stdout := output()

//writef("xcdecode entered*n")
//abort(1000)
  inputstream := 0
  outstream := 0
  listing := FALSE
  newline()

  IF rdargs("FROM/A,LIST/S,BIN/S", argv, 50) = 0 DO
  { writes("Bad args for XCDECODE*n")
     rc := 20
     GOTO exit
  }

  fromname := argv!0           // FROM/A
  listing  := argv!1           // LIST/S
  wr := wrch
  IF argv!2 DO wr := binwrch   // BIN/S

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
    ch := rdc()

    IF ch=endstreamch GOTO exit

    IF ch='#' DO
    { hashcount := hashcount+1

      { ch := rdc()
        IF ch='*n' LOOP
        IF ch=endstreamch GOTO exit
        UNLESS ch='#' BREAK
        hashcount := hashcount+1
      } REPEAT

      // Hashcount = number of consecutive '#'s
      // If >= 6 then we have a separator. It should be of the form
      // ######filename#, ignoring newlines in the filename.
      IF hashcount>=6 DO
      { // Read the filename into toname
        LET len = 0
        toname%0 := 0
        UNTIL ch='#' DO
        { IF ch=endstreamch GOTO exit
          UNLESS ch='*n' DO
          { len := len+1
            IF len>255 BREAK
            toname%0, toname%len := len, ch
          }
          ch := rdc()
        }

        //writef("Item separator found*n")
        //FOR i = 1 TO hashcount DO wrch('#')
        //writef("%s%c*n", toname, ch)
//abort(1001)
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
//abort(1002)
  IF ch=endstreamch GOTO exit

  writef("Decoding to file: %s ", toname)
  deplete(stdout)
abort(1003)
  wrcount := 0

  IF listing DO toname := "NIL:"

  outstream := 0

  //UNLESS listing DO
  { sawritef("*nCalling findoutput(%s) toname=%n*n", toname, toname)
    outstream := findoutput(toname)
sawritef("*nfindoutput(%s) => %n*n", toname, outstream)
sawritef("*nReturned from findoutput(%s) toname=%n*n", toname, toname)
    UNLESS outstream DO
    { writef("Can*'t open %s*n", toname)
      rc := 20
      GOTO exit
    }

    selectoutput(outstream)
  }

  prevch := -1
  repcount := 0
  digits := -1

  { ch := rdc()

    SWITCHON ch INTO
    { CASE '.':  ch := ' '
      DEFAULT:   IF outstream DO putch(ch)
                 LOOP

      CASE endstreamch:
                 GOTO exit

      CASE '=':          // '=' must be escaped!
      CASE '*n': LOOP

      CASE '#':  // Either an escaped character or the start of a separator
               { LET a, b = ?, ?

                 a := rdc() REPEATWHILE a='*n'
                 b := rdc() REPEATWHILE b='*n'

                 IF a='#' & b='#' DO
                 { // It must be a separator
                   hashcount := 3
                   IF outstream DO endstream(outstream)
                   outstream := 0
                   selectoutput(stdout)
                   writef(" %n*n", wrcount)
                   GOTO next
                 }
                 IF a=endstreamch | b=endstreamch GOTO exit
                 // Otherwise write escaped character
                 IF outstream DO putch((value(a)<<4) + value(b))
                 LOOP
               }
    }
  } REPEAT

exit:
  IF inputstream  DO { endstream(inputstream); inputstream := 0 }
  IF outstream    DO { endstream(outstream);   outstream := 0
                       selectoutput(stdout)
                       writef(" %n*n", wrcount)
                     }
  RESULTIS rc
}

AND putch(ch) BE
{ IF 0<=digits<3 & '0'<=ch<='9' DO
  { // We are reading a repetition count and have another digit
    repcount := repcount*10 + ch - '0'
    digits := digits+1
    IF digits<3 RETURN  // There might be another run-length digit
  }

  // Output prevch repcount (usually zero) times
  WHILE repcount DO {  wrc(prevch); repcount := repcount-1 }

  IF digits=3 DO
  { // ch holds the third digit of the latest repetition count
    digits := -1
    RETURN
  }

  // We are no longer in a repetition count and ch is the
  // next character to output
  digits := -1

  IF ch=prevch DO
  { // Deal with a new run-length item
    wrc(ch)
    // Start a new run-length count
    repcount, digits := 0, 0
    RETURN
  }
  // ch was different from prevch and so did not trigger
  // a run-length item
  wrc(ch)
  prevch := ch
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
