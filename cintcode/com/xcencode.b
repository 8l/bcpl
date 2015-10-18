SECTION "XCENCODE"

GET "libhdr"

/*
This program encodes a collection of one or more character
or binary files into a file of printable characters with lines
of about 50 characters suitable for transmission by email. It uses
run length encoding to make the encoded file more compact. If the
same byte occurs twice consecutively the next byte is a count
between 0 and 255 of how many more repetitions there are.

Usage: xcencode "FILE,LIST/K,TO/K/A,BIN/S"

where FILE is the name of a single file to encode
      LIST is a list of file names of files to encode.
      TO   is the encoded file
 and  BIN  is set the file is to be read using binrdch so that
           carriage return ('*c') characters are not ignored.

One or other of FILE and LIST must be supplied.
If both are given FILE will give the first filename to be encoded
followed by those given by LIST.

Each encoded file is preceeded by a separator of the form:

#####filename#

followed by the encoded file in which all characters with ASCII codes
in the range 33 to 126 except for '#', '=' and '.' are copied, spaces are
replaced by dots ('.') and all other characters (including '#' '=' and
'.') are encoded by #hh where hh is the ASCII code in hex. The encoded
file is broken into lines of about 50 characters.

The last file to be encoded is terminated by ######+#.

Such xencode'd files can be decoded by the xdecode command.

Written by Martin Richards (c) September 2008
*/

GLOBAL
{
tostream: ug
stdin
stdout
liststream
count
binflag
}

LET start() = VALOF
{ LET file1name = 0
  LET listname = 0
  LET rc = 0
  LET filename = VEC 256/bytesperword
  LET argv = VEC 50

  stdin, stdout := input(), output()

  tostream := 0
  liststream := 0
  newline()

  IF rdargs("FILE,LIST/K,TO/K/A,BIN/S", argv, 50) = 0 DO
  { writes("Bad args for XENCODE*n")
    rc := 20
    GOTO exit
  }

  file1name := argv!0              // FILE
  listname  := argv!1              // LIST/K

  IF argv!2 DO { tostream := findoutput(argv!2)    // TO/K/A
                 UNLESS tostream DO
                 { writef("Can*'t open %s*n", argv!2)
                   rc := 20
                   GOTO exit
                 }
               }
  binflag := argv!3                // BIN/S


  UNLESS file1name | listname DO
  { writes("Error: At least one of FILE and LIST must be given*n")
    rc := 20
    GOTO exit
  }

  IF file1name DO xencode(file1name)

  IF listname  DO xencodelist(listname)

  selectoutput(tostream)

  writef("*n######+#*n") // The termination marker

exit:
   UNLESS tostream=0 DO { selectoutput(tostream); endwrite() }
   RESULTIS rc
}

AND xencode(name) BE
{ LET oldin = input()
  LET inputstream = findinput(name)
  LET prevch = -1
  LET rch = binflag -> binrdch, rdch
  count := 0

  UNLESS inputstream DO { writef("Can*'t open %s*n", name)
                          RETURN
                        }
  writef("Encoding file: %s*n", name)

  selectinput(inputstream)
  selectoutput(tostream)

  writef("*n######%s#*n", name)

  { LET ch = rch()
    LET d1, d2, d3 = 0, 0, 0
    IF ch=endstreamch BREAK

    WHILE ch=prevch DO
    { // Perform run-length encoding
      LET repcount = 0
      putch(ch)        // Put the same character again

      { ch := rch()
        IF repcount=999 | ch~=prevch BREAK
        repcount := repcount+1
      } REPEAT
      // ch is the first character after the repetition count 
      d1 := '0' + repcount / 100
      d2 := '0' + repcount /  10 MOD 10
      d3 := '0' + repcount       MOD 10
      TEST '0'<=ch<='9'
      THEN { // If the run-length item is followed by a digit
             // put all three digits
             putch(d1)
             putch(d2)
             putch(d3)
           }
      ELSE { // The run-length item was not followed by a digit
             // output the count will all leading zeros supressed.
             IF repcount >= 100 DO putch(d1)
             IF repcount >=  10 DO putch(d2)
             IF repcount >    0 DO putch(d3)
           }
      IF ch=endstreamch BREAK
      // ch is now the first character after the run-length item
    }

    IF ch=endstreamch BREAK
    prevch := ch
    putch(ch)
  } REPEAT

  newline()
  endstream(inputstream)
  selectinput(oldin)
  selectoutput(stdout)
}

AND putch(ch) BE
{ TEST 32<=ch<127 & ch~='#' & ch~='.' &ch~='='
  THEN { IF ch=' ' DO ch := '.'
         wrch(ch)
         count := count+1
       }
  ELSE { writef("#%x2", ch); count := count+3 }

  IF count>50 DO { newline(); count := 0 }
}

AND xencodelist(name) BE
{ LET liststream = findinput(name)

  UNLESS liststream DO { writef("Can*'t open %s*n", name)
                         RETURN
                       }
  selectinput(liststream)

  { LET ch = rdch()
    LET len = 0
    LET filename = VEC 255/bytesperword

    IF ch=endstreamch BREAK
    IF ch='*n' | ch='*s' LOOP
    len := 0
    filename%0 := 0
    
    UNTIL ch='*n' | ch='*s' | ch=endstreamch | len>=255 DO
    { len := len+1
      filename%0, filename%len := len, ch
      ch := rdch()
    }

    IF len DO xencode(filename)
    IF ch=endstreamch BREAK
  } REPEAT  

  endstream(liststream)
}

