// (C) Copyright 1979 Tripos Research Group
//     University of Cambridge
//     Computer Laboratory

// This is the version of the C command for the Cintsys system.

SECTION "C"

GET "libhdr"


GLOBAL { subch         :  ug
         busch         :  ug +  1
         defch         :  ug +  2
         dirch         :  ug +  3
         ch            :  ug +  4

         instream      :  ug +  5
         outstream     :  ug +  6
         sys_stream    :  ug +  7

         rdargskey     :  ug +  8
         parameters    :  ug +  9
         keyword       :  ug + 10
         defstart      :  ug + 11
         keygiven      :  ug + 12
         temp1         :  ug + 13

         par_stream    :  ug + 14

         err_p         :  ug + 15
         err_l         :  ug + 16

         c_rcode       :  ug + 17
         c_result2     :  ug + 18
       }



MANIFEST { fileupb        =      20
           taskposlwb     =      14
           taskposupb     =      15
           switchpos      =      11

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

  LET temp1     = "comfile1"
  LET comfile   = "comfile"
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

  rdargskey  := rkvec
  parameters := parvec
  keyword    := keyvec

  item := rditem(cfile, fileupb)   // Get the command-command filename
  UNLESS item=1 DO
  { reportcerr("Bad command file name")
    RESULTIS 20
  }

  // First look in the current directory
  instream := pathfindinput(cfile, 0)

  UNLESS instream DO // Try the scripts directories next
    instream := pathfindinput(cfile, rootnode!rtn_scriptsvar)

  UNLESS instream DO // Failing that, try the root directory
    instream := pathfindinput(cfile, rootnode!rtn_rootvar)

  UNLESS instream DO reportcerr("Can't open %s", cfile)

  selectinput(instream)

  outstream := findoutput(temp1)

  IF outstream = 0 DO
    reportcerr("Can't open work file *"%s*"",temp1)

  selectoutput(outstream)

  //IF cli_interactive DO intflag()

  ch := rdch()

  UNTIL ch=endstreamch TEST ch=dirch
                       THEN handledirective()
                       ELSE substitute()
  endread()

  // First read rest of parameter line.

  consume_rest_of_line()

  // Copy rest of current input.

  selectinput(cli_currentinput)

  UNLESS cli_currentinput=cli_standardinput DO
  { { ch := rdch()
      IF ch=endstreamch BREAK
      wrch(ch)
    } REPEAT
  }

  endwrite()

  UNLESS cli_currentinput=cli_standardinput DO
  { endread()
    deletefile(cli_commandfile)
  }

  renamefile(temp1, comfile)

  FOR j = 0 TO comfile%0 DO cli_commandfile%j := comfile%j

  cli_currentinput :=findinput(comfile)
  RESULTIS 0

err_l:
  selectoutput(sys_stream)

  result2 := c_result2
  stop(c_rcode)

  RESULTIS c_rcode
}


AND handledirective() BE // Called after reading 'dirch'
{ ch := rdch()
   UNLESS ch = '*n' | ch = ' ' | ch = endstreamch THEN
   { LET item,c = ?,?
      unrdch()

      item := rditem(keyword,keywordupb)
      c := (item \= 1 -> -1,
               findarg("KEY,K,DEFAULT,DEF,*
                       *BRA,KET,DOLLAR,DOT",keyword))
      IF c < 0 DO reportcerr("Invalid directive")

      SWITCHON c INTO

      { CASE 0: CASE 1:
             // KEY for RDARGS.
             IF keygiven DO reportcerr("More than one K directive")

             { LET item = rditem(rdargskey,rdargskeyupb)
                IF item <= 0 DO
                   reportcerr("Illegal K directive")

                selectinput(par_stream)
                selectoutput(sys_stream)
                defstart := rdargs(rdargskey,
                                   parameters,parsupb)
                unrdch()
                selectoutput(outstream)
                selectinput(instream)
                IF defstart = 0 DO reportcerr("Parameters unsuitable for*
                                              * key *"%s*"", rdargskey)

                keygiven := TRUE
             }
             ENDCASE

         CASE 2:
         CASE 3:
             // DEFAULT keyword [=] value
             { LET item = rditem(keyword,keywordupb)
                LET keyn = ?

                IF item < 0 DO reportcerr("Illegal keyword")

                IF item = 0 ENDCASE

                UNLESS keygiven DO reportcerr("No K directive")

                keyn := findarg(rdargskey,keyword)

                IF keyn >= 0 & parameters ! keyn = 0 DO
                { LET dupb = parsupb+parameters-defstart
                   item := rditem(defstart,dupb)

                   IF item = -2 DO item := rditem(defstart,dupb)

                   IF item <= 0 DO { IF item ~= 0 THEN
                                         reportcerr("Illegal D item")
                                      ENDCASE
                                   }

                   parameters ! keyn := defstart
                   defstart := defstart +
                   (defstart % 0)/bytesperword + 1
                }
                ENDCASE

             }


          DEFAULT: // Set new character.
             (@ subch) ! (c - 4) := getch()
             ENDCASE

        }

     ch := rdch()

  }

  UNTIL ch = '*n' | ch = endstreamch DO ch := rdch()

  ch := rdch()
}



AND substitute() BE
{ LET writing, substituting = TRUE, FALSE
   UNTIL ch='*n' | ch=endstreamch DO

   TEST ch = subch & writing  // <key$default>
   THEN { LET keyn, len = ?, 0
           writing, substituting := FALSE, TRUE

           UNLESS keygiven DO reportcerr("No K directive")

           ch := rdch()

           UNTIL ch=busch | ch=defch |
                 ch='*n'  | ch=endstreamch DO
           { IF len >= keycharsmax DO reportcerr("Keyword too long*n")
              len := len + 1
              keyword%len := ch
              ch := rdch()
           }


           keyword%0 := len

           keyn := findarg(rdargskey,keyword)

           TEST keyn < 0 | parameters ! keyn = 0
           THEN writing := TRUE
           ELSE TEST parameters ! keyn = -1
                THEN writes(keyword)
                ELSE writes(parameters ! keyn)

           IF ch = defch DO ch := rdch()

        }
   ELSE { TEST ch = busch & substituting
           THEN writing, substituting := TRUE, FALSE
           ELSE IF writing DO wrch(ch)
           ch := rdch()
        }
   wrch('*n')
   ch := rdch()
}


AND getch() = VALOF // Get single character item.
{ LET item = rditem(keyword, keywordupb)

   IF item=0 DO { ch := rdch()
                   unrdch()
                   IF ch='*n' | ch=endstreamch RESULTIS -2
                }

   UNLESS item>0 & keyword%0=1 DO
          reportcerr("Invalid directive argument")

   RESULTIS keyword%1
}


AND consume_rest_of_line() BE
{ LET ch = ?
  selectinput(par_stream)
  ch := rdch() REPEATUNTIL ch = '*n' |
                           ch = ';'  |
                           ch = endstreamch
}



AND reportcerr(format, x, y) BE
{ c_result2 := result2

   UNLESS outstream = 0 DO { endwrite()
                              deletefile(temp1)
                              selectoutput(sys_stream)
                           }
   UNLESS instream = 0 DO endread()
   consume_rest_of_line()
   writes("C: "); writef(format, x, y)
   wrch('*n')
   c_rcode := 20
   longjump(err_p, err_l)
}
