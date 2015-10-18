SECTION "XENCODE"

GET "libhdr"

/*
This program encodes a collection of one or more character
or binary files into a file of printable characters with lines
of about 50 characters suitable for transmission by email.

Usage: xencode "FILE,LIST/K,TO/K/A"

where FILE is the name of a single file to encode
      LIST is a list of file names of files to encode.
 and  TO   is the encoded file

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

  IF rdargs("FILE,LIST/K,TO/K/A", argv, 50) = 0 DO
  { writes("Bad args for XENCODE*n")
    rc := 20
    GOTO exit
  }

  file1name := argv!0              // FILE
  listname  := argv!1              // LIST

  IF argv!2 DO { tostream := findoutput(argv!2)
                 UNLESS tostream DO
                 { writef("Can*'t open %s*n", argv!2)
                   rc := 20
                   GOTO exit
                 }
               }


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
  LET count = 0

  UNLESS inputstream DO { writef("Can*'t open %s*n", name)
                          RETURN
                        }
  writef("Encoding file: %s*n", name)

  selectinput(inputstream)
  selectoutput(tostream)

  writef("*n######%s#*n", name)

  { LET ch = rdch()
    IF ch=endstreamch BREAK

    TEST 32<=ch<127 & ch~='#' & ch~='.' &ch~='='
    THEN { IF ch=' ' DO ch := '.'
           wrch(ch)
           count := count+1
         }
    ELSE { writef("#%x2", ch); count := count+3 }

    IF count>50 DO { newline(); count := 0 }
  } REPEAT

  newline()
  endstream(inputstream)
  selectinput(oldin)
  selectoutput(stdout)
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

