// (C) Copyright 1979 Tripos Research Group
//     University of Cambridge
//     Computer Laboratory

// This is the Cintsys/Cintpos C command.

/*
01/10/2010
Made Cintsys and Cintpos versions of c.b identical.

07/09/2010
Changed the lookup sequence for the command-command filename
to:
1) the current directory.
2) the directories specified by the scripts environment variable
   whose name in the rtn_scriptsvar field of the rootnode.
3) The root directory specified by the environment variable in
   the rtn_rootvar field of the rootnode.

Under Linux I might have the scriptsvar variable set to

NPVSSCRIPTS

and

echo $NPVSSCRIPTS

gives

/home/mr10/NPVS/s:/home/mr10/distribution/Cintpos/cintpos/s

You can see what the rootnode environment variables are set to
using the CLI command: setroot

*/

SECTION "C"

GET "libhdr"


GLOBAL {
  subch: ug
  busch
  defch
  dirch
  ch

  instream
  outstream
  sys_stream

  rdargskey
  parameters
  keyword
  defstart
  keygiven

  newfile

  par_stream

  err_p
  err_l

  c_rcode
  c_result2
}



MANIFEST {
  fileupb        =      20
  workfileupb    =       8
  taskposlwb     =       8
  taskposupb     =       9
  switchpos      =       6

  parsupb        =     100
  rdargskeyupb   =      50
  keywordupb     =      10
  keycharsmax    =      21
}

LET start() = VALOF
{ // The first item on the command line is used as
  // the command-command filename. I.e. C filename args .....
  // The file name and the parameters are read from the currently
  // selected stream, and this stream is also used as the rest of
  // the current command-command file.
  LET cfile = VEC fileupb  // To hold the command-command filename
  LET item  = ?

  LET rkvec  = VEC rdargskeyupb
  LET parvec = VEC parsupb
  LET keyvec = VEC keywordupb
  LET newf   = VEC workfileupb
  LET workfile = "T-CMD0TNN"
  LET newstream = ?

  err_p      := level()
  c_rcode    := 0
  c_result2  := 0

  instream   := input()
  sys_stream := output()
  par_stream := cli_currentinput
  outstream  := 0

  keygiven   := FALSE

  // Set the default versions of the special characters
  subch := '<'  // Start of substitution item
  busch := '>'  // End of substitution item
  defch := '$'  // For default values, eg:  <from$mydata>
  dirch := '.'  // For directives, eg: .key

  newfile    := newf
  rdargskey  := rkvec
  parameters := parvec
  keyword    := keyvec

  item := rditem(cfile, fileupb) // Get the command-command filename
  UNLESS item=1 | item=2 DO      // Unquoted or quoted string
  { reportcerr("Bad command file name")
    RESULTIS 20
  }

//sawritef("c: command-command filename=%s*n", cfile)
  // First look in the current directory
  instream := findinput(cfile)

  UNLESS instream DO // Try the scripts directories next
    instream := pathfindinput(cfile, rootnode!rtn_scriptsvar)

  UNLESS instream DO // Failing that, try the root directory
    instream := pathfindinput(cfile, rootnode!rtn_rootvar)

  UNLESS instream DO reportcerr("Can't open %s", cfile)

  selectinput(instream)

  // Construct work-file name
  //    T-CMD0Tnn
  //           nn     two digits of the taskid
  //         *        0 or 1 to make it different from current file name 
  FOR j = 0 TO workfile%0 DO newfile%j := workfile%j

  { LET t = taskid
    FOR j = taskposupb TO taskposlwb BY -1 DO // ie: 9 then 8
    { newfile%j := t REM 10 + '0'
      t := t/10
    }
  }

  IF (cli_status & clibit_comcom)~=0 DO
  { // We are currently running a command-command from file
    // so we must choose a different filename.
    IF cli_commandfile%0 >= switchpos DO  // switchpos = 6
    { // T-CMD0Tnn <==> T-CMD1Tnn
      newfile%switchpos := cli_commandfile%switchpos XOR 1
    }
  }

//sawritef("c: using command file %s*n", newfile)
  outstream := findoutput(newfile)

  UNLESS outstream DO reportcerr("Can't open file *"%s*" for output",newfile)

  selectoutput(outstream)

  //IF cli_interactive DO testflags(flag_commbreak) // Clear ctrl-C flag

  ch := rdch()

  UNTIL ch=endstreamch TEST ch=dirch
                       THEN handledirective()
                       ELSE substitute()
  endread()

  // First read rest of parameter line.

//sawritef("c: calling consume_rest_of_line*n")
  consume_rest_of_line()

  // Copy rest of current input.

  selectinput(cli_currentinput)

//sawritef("c: cli_status=%x8 clibit_comcom=%x8*n", cli_status, clibit_comcom)

//  IF cli_currentinput ~= cli_standardinput DO
  IF (cli_status & clibit_comcom)~=0 DO
  { // If we were already processing a command-command, copy the
    // rest of the previous file into the new file
//sawritef("c: we were in a command-command reading from %s*n", cli_commandfile)
    { ch := rdch()
      IF ch = endstreamch BREAK
      wrch(ch)
    } REPEAT
    // Then close and delete the old file
    endread()
    deletefile(cli_commandfile)
  }

  endwrite()                     // Close the new file

  newstream :=findinput(newfile) // and open it for input

  // Set up the new command file for the CLI to process,
  // remembering its name so that it can be deleted later.
  cli_currentinput := newstream
  FOR j = 0 TO newfile%0 DO cli_commandfile%j := newfile%j

  // Set the CLI comcom bit
  cli_status := cli_status | clibit_comcom


err_l:
  selectoutput(sys_stream)

  result2 := c_result2
//  UNLESS command_stream DO stop(c_rcode)

//sawritef("c: returning from c with c_rcode=%n cli_commandfile=%s*n",
//          c_rcode, cli_commandfile)
  RESULTIS c_rcode
}


AND handledirective() BE // Called after reading 'dirch'
{ ch := rdch()
  UNLESS ch = '*n' | ch = ' ' | ch = endstreamch DO
  { LET item, c = ?, ?
    unrdch()

    item := rditem(keyword, keywordupb)
    c := (item=1 ->
            findarg("K=KEY,DEF=DEFAULT,*
                     *BRA,KET,DOLLAR,DOT",keyword),
            -1
         )
//sawritef("handledirective: c=%n*n", c)

    IF c < 0 DO reportcerr("Invalid directive")

    SWITCHON c INTO
    { DEFAULT: 
           reportcerr("Illegal directive")
           RETURN

      CASE 0:                         // K=KEY
           // KEY for RDARGS.
           IF keygiven DO reportcerr("More than one K directive")

           { LET item = rditem(rdargskey, rdargskeyupb)
             IF item <= 0 DO reportcerr("Illegal K directive")
//sawritef("c: rdargskey=%s*n", rdargskey)
             selectinput(par_stream)
             selectoutput(sys_stream) // For error messages
             defstart := rdargs(rdargskey, parameters, parsupb)
             unrdch() // ?????????????????????
             selectoutput(outstream)
             selectinput(instream)
             UNLESS defstart DO
               reportcerr("Parameters unsuitable for key *"%s*"", rdargskey)
             keygiven := TRUE
             ENDCASE
           }

      CASE 1:                      // DEF=DEFAULT
           // DEFAULT keyword [=] value
           { LET item = rditem(keyword,keywordupb)
             LET keyn = ?

             IF item < 0 DO reportcerr("Illegal keyword")

             IF item = 0 ENDCASE

             UNLESS keygiven DO reportcerr("No K directive")

             keyn := findarg(rdargskey,keyword)

             IF keyn >= 0 & parameters ! keyn = 0 DO
             { LET dupb = parsupb+parameters-defstart
               item := rditem(defstart, dupb)

                IF item = 5 DO      // Skip over '='
                  item := rditem(defstart,dupb)

                IF item = 0 ENDCASE // EOF

                IF item < 0 DO      // Error
                { reportcerr("Illegal .DEF item")
                  ENDCASE
                }

               parameters ! keyn := defstart
               defstart := defstart +
                           (defstart % 0)/bytesperword + 1
              }
              ENDCASE
            }

      CASE 2:                 // BRA
      CASE 3:                 // KET
      CASE 4:                 // DOLLAR
      CASE 5:                 // DOT
            (@ subch) ! (c - 2) := getch()
            ENDCASE

    }

    ch := rdch()
  }

  UNTIL ch = '*n' | ch = endstreamch DO ch := rdch()

  ch := rdch()
}



AND substitute() BE
{ LET writing, substituting = TRUE, FALSE

  UNTIL ch='*n' | ch=endstreamch TEST ch=subch & writing
  THEN { LET keyn, len = ?, 0 // <key$default>
         writing := FALSE
         substituting := TRUE

         UNLESS keygiven DO reportcerr("No K directive")

         ch := rdch()

         UNTIL ch=busch | ch=defch |            //  >        $
               ch='*n'  | ch=endstreamch DO     //  newline  EOF
         { IF len >= keycharsmax DO reportcerr("Keyword too long*n")
           len := len + 1
           keyword%len := ch
//sawritef("c: keyword!%n=%c*n", len, ch)
           ch := rdch()
         }
         keyword%0 := len
//sawritef("c: keyword=%s*n", keyword)

         keyn := findarg(rdargskey, keyword)

         TEST keyn < 0 | parameters!keyn = 0
         THEN writing := TRUE
         ELSE TEST parameters ! keyn = -1
              THEN writes(keyword)
              ELSE { writes(parameters!keyn)
//sawritef("c: substituting %s for key %s*n", parameters!keyn, keyword)
                   }

         IF ch = defch DO ch := rdch()

       }
  ELSE { TEST ch=busch & substituting
         THEN { writing := TRUE
                substituting := FALSE
              }
         ELSE IF writing DO wrch(ch)
         ch := rdch()
       }

  wrch('*n')
  ch := rdch()
}


AND getch() = VALOF // Get single character item.
{ LET item = rditem(keyword, keywordupb)

  UNLESS item DO
  { ch := rdch(); unrdch()
    IF ch = '*n' | ch = endstreamch RESULTIS -2
  }

   UNLESS item>0 & keyword%0=1 DO
          reportcerr("Invalid directive argument")

   RESULTIS keyword%1
}

AND consume_rest_of_line() BE
{ LET ch = ?
  selectinput(par_stream)
//sawritef("c: consume_rest_of_line entered*n")
  ch := rdch() REPEATUNTIL ch = '*n' |
                           ch = ';'  |
                           ch = endstreamch
//sawritef("c: returning from consume_rest_of_line*n")
}

AND reportcerr(format,x,y) BE
{ c_result2 := result2

  IF outstream DO
  { endstream(outstream)
    deletefile(newfile)
    selectoutput(sys_stream)
  }
  IF instream DO endread()
  consume_rest_of_line()
  writes("C: ")
  writef(format, x, y)
  newline()
  c_rcode := 20
  longjump(err_p, err_l)
}
