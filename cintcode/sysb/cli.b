// (c) Copyright M. Richards, 23 April 2010

/* Change log

23/04/10
Changed to new datstamp format.

27/06/07
Added setseed(12345) since the random number seed is now a global
variable (not a static).

17/01/06
As suggested by Dave Lewis, ignore commands starting with a #. This
enables executable Unix command scripts using text like:
#!/usr/local/bin/cintsys -s
as the first line of the script file.
21/5/2001
Changed manifest cli_initialstack to 50000 in CLIHDR (previously 5000)
*/

SECTION "CLI"

GET "libhdr"
//GET "clihdr"

MANIFEST
{ namemax   = 25
  promptmax = 15
  filemax   = 10
}

LET start(parm_pkt) BE // parm_pkt only used in Cintpos
{ LET prompt      = VEC promptmax
  LET commandname = VEC namemax
  LET commandfile = VEC filemax  // Command-command file name, if in use
  LET globbase    = @globsize    // globsize is global 0
  LET cpumsecs    = sys(Sys_cputime)
  LET initprompt  = "%5.3d> "
  //LET initprompt = "%5.3d %+%2i:%2z:%2z.%3z> " // Useful for debugging
  LET datavec     = VEC 10       // Used as private data by some CLIs
                                 // tcpcli uses it to hold the TCP
                                 // stream name.
  FOR i = 0 TO 10 DO datavec!i := 0
   
  cli_data        := datavec       // MR 10/7/03
  cli_status      := 0             // MR 10/7/03
  cli_prompt      := prompt
  cli_commandname := commandname
  cli_commandfile := commandfile

  FOR i = 0 TO initprompt%0 DO
    cli_prompt%i := initprompt%i

  cli_standardinput := input()
  cli_currentinput := cli_standardinput
  cli_standardoutput := output()
  cli_commandname%0 := 0
  cli_commandfile%0 := 0
  cli_defaultstack := cli_initialstack
  cli_returncode := 0
  cli_result2 := 0
  cli_module := 0
  cli_preloadlist := 0
  cli_tallyflag := FALSE
  cli_faillevel := cli_initialfaillevel

  setseed(12345) // MR 27/6/07

  IF rootnode!rtn_boottrace DO
    sawritef("cli: now entering the main CLI loop*n")

  { LET ch, item = '*n', ?

    { // Start of main command loop
      //cli_interactive :=  cli_currentinput=cli_standardinput

      // Possibly output the prompt
      IF ch='*n' & cli_currentinput=cli_standardinput DO
      { LET hours, mins, secs = 0, 0, 0
        LET days, msecs, flag = 0, 0, 0 
        datstamp(@days)
        secs  := msecs  /  1000
        msecs := msecs MOD 1000
        mins  := secs   /  60
        hours := mins   /  60
        mins  := mins  MOD 60
        secs  := secs  MOD 60

        // Calculate msecs since issuing last prompt
        cpumsecs := sys(Sys_cputime) - cpumsecs

        writef(cli_prompt,
               cpumsecs, // msecs used by last command
               0,        // The task number, if running under Cintpos
               hours, mins, secs, msecs) // The time of day
        deplete(cos)

        cpumsecs := sys(Sys_cputime)
      }

      item := rditem(cli_commandname, namemax)

      SWITCHON item INTO
      { CASE 0: // The item was: eof
          IF cli_currentinput=cli_standardinput DO sys(Sys_quit, 0)
          BREAK

        CASE 1: // The item was: unquoted name
        CASE 2: // The item was: quoted name
        { LET p, coptr = cli_preloadlist, 0
          // If the command name is # or starts with a #,
          // treat the command as a comment,
          // ie skip to just before EOL or EOF.
          IF cli_commandname%0 > 0 & cli_commandname%1 = '#' DO
          { LET ch = ?
            ch := rdch() REPEATUNTIL ch='*n' | ch=';' | ch=endstreamch
            IF ch='*n' DO unrdch()
            LOOP
          }
 
          WHILE p DO            // Search in preloadlist.
          { IF compstring(cli_commandname, @p!2)=0 DO
            { cli_module := p!1
              BREAK             // Module found.
            }
            p := !p
          }

          UNLESS cli_module DO cli_module := loadseg(cli_commandname)

          start := globword+1 // Unset start
          UNLESS globin(cli_module)=0 DO
            coptr := createco(clihook, cli_defaultstack)
          TEST coptr=0
          THEN { cli_result2 := result2
                 writef("Can't load %s*n", cli_commandname)
               }
          ELSE { IF cli_tallyflag DO
                 { cli_tallyflag := FALSE
                   sys(Sys_tally, TRUE)   // Turn on tallying
                 }

                 // Transfer control to the command,
                 // and save the return code.
                 cli_returncode := callco(coptr, 0)
                 cli_result2 := result2

                 sys(Sys_tally, FALSE)    // Turn off tallying

                 // Unset user globals
                 FOR i = ug TO globsize DO
                   globbase!i := globword + i

                 // Restore the library globals
                 globin(rootnode!rtn_blib)
                 //globin(rootnode!rtn_cli)

                 deleteco(coptr)
                 selectinput (cli_currentinput)
                 selectoutput(cli_standardoutput)

                 IF cli_returncode >= cli_faillevel DO
                 { writef("%s failed returncode %n",
                           cli_commandname, cli_returncode)
                   IF cli_result2 DO
                     writef(" reason %n", cli_result2)
                   newline()
                 }
               }

          IF p=0 & cli_module DO unloadseg(cli_module)
          cli_module := 0
        }

        CASE 3: // The item was: '*n'
        CASE 4: // The item was: ';'
          ENDCASE

        DEFAULT:// Unknown item. 
          writes("Error in command name*n")
      }

      ch := '*n'
      IF unrdch() DO ch := rdch()
      // Skip to end of line unless last command terminated by nl or ;
      UNTIL ch='*n' | ch=';' | ch=endstreamch DO ch := rdch()

      IF intflag() DO { writes("****BREAK - CLI*N")
                        BREAK
                      }
    } REPEAT

    IF (cli_status & clibit_comcom) ~= 0 DO
    { // We were within a command-command, so close the stream
      endstream(cli_currentinput)
      cli_currentinput := cli_standardinput
      selectinput(cli_currentinput)

//sawritef("cli: deleting command file %s*n", cli_commandfile)

      // and delete the command file
      IF cli_commandfile%0 DO { sys(Sys_deletefile, cli_commandfile)
                                cli_commandfile%0 := 0
                              }
      cli_status := cli_status & ~clibit_comcom
    }
  } REPEAT
}
