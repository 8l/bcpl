/*
Development of this program has only just started.

This program is a variant of the well known make command modified
to run under cintsys and cintpos.

Designed and implemented by Martin Richards (c) December 2010

Log

18/01/11
It looks as if bmake now works. The BCPL compiler has been modified
to append xref data when both VER and XREF are specified.

10/01/11
Added -s option to output the rules after the application of the
patterns. Started to implement apply_patterns and generate_commands.

01/12/10
Started the implementation of bmake.

Usage:

bmake "TARGET,FROM=-f/K,TO/K,-m/S,-l/S,-p/S,-r/S,-s/S,-c/S,-d/S"

TARGET is the target name (normally a file name). The default is
       the target of the first rule.
FROM   is the name of the makefile (default: bmakefile)
TO     specifies where the output is to be sent (default: standard output)
-m     output the makefile after macrogeneration
-l     output the lexical token.
-p     output the rule patterns.
-r     output the rules before the application of the rule patterns.
-s     output the rules after the application of the rule patterns.
       This output includes the modify times of all targets and items.
-c     output command sequence to bring the specified target up to date.
-d     output debugging trace.

The makefile is first processed by the BGPM macrogenerator with
the following special characters:

%      Comment - skip all characters until a non white space character
       on a later input line.
[      Start of a new macro call.
!      Argument separator in macro calls.
#      Argument item prefix.
]      End of macro argument list.
{      Open quote character
}      Close quote character.

A typical macro definition and call is as follows:

[def!xxx!{This output results from the call {[xxx!}#1{]}}]
[xxx!yyy]

This would generate:

This output results from the call [xxx!yyy]


The syntax of bmakefile rules

target-item <= item ... item << command-sequence >>

Every rule must have a target item and a body consisting of a possibly
empty command sequence enclosed in << and >> brackets.  The
command-sequence is an arbitrary sequence of characters not containing
>>.  The item list may be empty and, if so, the symbol <= may be
omitted.  White space including newlines are allowed anywhere between
items.

A target item may contain a parameter of the form <tag> normally as a
component of a file name where the tag is any sequence of zero or more
letters and digits. The tag has no significance other than all
parameters occurring within a rule must have the same tag. Rules
containing parameters are called rule patterns, as in:

cin/<f> <= com/<f>.b g/hdr.h << c bc <f> >>

Such rules are only used when there is no explicit rule for a given
target. When a rule pattern is applied all occurrences of its
parameter are replaced by the text that allowed the target item to be
matched. So if cin/echo must be brought up to date and has no explicit
rule, the above pattern will automatically add the following rule to
the set:

cin/echo <= com/echo.b g/hdr.h << c bc echo >>

A target is out of date if it does not exist or if any of the items it
depends on are out of date or have a modify dates later than that of
the target. A target is brought up to date by, first, bringing the
items it depends on up to date and then executing the CLI command
sequence given by the body.

Items may consist of any sequence of characters not including %, [ !,
] {, }, =, or white space, and < and > may only appear in parameters.

In normal use, bmake generates a command-command file to bring the
target up to date and then returns to the CLI to cause it to be
executed.  The -c option allows the command-command file to be
inspected without it being executed, and the -m, -l, -p, -r, -s and -d
options provide other debugging aids.

*/

SECTION "bmake"

GET "libhdr"

GLOBAL {
// BGPM globals
bg_s:ug
bg_t
bg_h
bg_p
bg_f
bg_c
bg_e
bg_ch

bggetch; bgputch;  bgwrn
error

bgpmco
bgpmfn

sysin; sysout; sourcestream; tostream
sourcenamev; sourcefileno; sourcefileupb
getstreams; lineno

optMacros; optTokens; optPats; optRules; optSets; optComs

newvec; mk1; mk2; mk3; mk4; mk5; mk6; mk7; mk8

blklist  // List of blocks of work space
blkb
blkp
blkt
blkitem
//treevec; treep; treet
base; upb; rec_p; rec_l; fin_p; fin_l

rulelist; ruleliste
patnlist; patnliste

debug              // =TRUE causes output of the debugging trace
errcount; errmax
fatalerr; synerr; fatalsynerr
trerr
strv    // Short term sting buffer

rch; ch; chbuf; chcount; parse; tree
prrule; prpatn; opstr; prlineno
token
bgexp; bgbexp; argp; argt
wrc; wrs; chpos; charv; len; tagv; tlen
wordnode
rdtag; param; parampos
opstr
lookupword
nametable
parse
targetstr
targetitem
apply_patterns
match
generate_commands
newfile
}

MANIFEST {
nametablesize = 541
blkupb = 4000
charvupb = 10000  // Maximum body length

// BGPM markers
s_eof     =  -2
s_eom     =  -3

// BGPM builtin macros
s_def     =  -4
s_set     =  -5
s_get     =  -6
s_eval    =  -7
s_lquote  =  -8
s_rquote  =  -9
s_comment = -10
s_rep     = -19

// BGPM special characters
c_call    = '['
c_apply   = ']'
c_sep     = '!'
c_comment = '%' 
c_lquote  = '{'
c_rquote  = '}'
c_arg     = '#'

// General selectors
h1=0; h2; h3; h4; h5; h6; h7

// Selectors
n_next=0
n_ln            // Line number of the target item of the rule or pattern.
n_subj          // Subject item of the rule or pattern.
n_dpns          // List of items this rule depends on
n_com           // The command string. Only zero for default rules.
n_param         // Param string if pattern, zero if rule.
n_state=n_param // =0 if not touched,
                // =1 if looking through the depends-on list,
                // =2 if all items in the depends-on list have been processed.
n_days          // >0  modification time of the subject if known.
                // =0  subject iten does not exist.
                // =-1 subject item not yet inspected.
n_msecs         // zero or msecs since midnight.

// Data structures

// [next, rule, <packed string>]                            -- item
// [next,  pos, <packed string>]                            -- pattern item
//                                                          -- next is the hash chain
// [next, item]                                             -- dpns-list
// [len, <packed chars>]                                    -- com
// [next, ln, item, depends-list, com, state, days, msecs]  -- rule
// [next, ln, item, depends-list, com, param]               -- pattern

// Lexical token
s_item=1
s_dependson
s_com
s_end

workfileupb=255
taskposlwb=8
taskposupb     =       9
switchpos      =       6

}

LET start() = VALOF
{ LET argv = VEC 50
  LET s = VEC 10
  LET fromname = "bmakefile"
  LET toname = 0
  LET b = VEC 64/bytesperword
  LET dbv = VEC 9
  strv := s         // Short term sting buffer

  errcount, errmax := 0, 5
  fin_p, fin_l := level(), fin
  rec_p, rec_l := fin_p, fin_l

  chbuf := b
  FOR i = 0 TO 63 DO chbuf%i := 0
  chcount := 0

  upb := 100_000

  sysin := input()
  sysout := output()

  base := 0              // Base of BGPM workspace
  sourcestream := 0
  getstreams := 0
  tostream := sysout
  bgpmco := 0

  // Space for parse tree, etc.
  blklist, blkb, blkp, blkt, blkitem := 0, 0, 0, 0, 0

  sourcefileupb := 1000
  sourcenamev := newvec(sourcefileupb)
  UNLESS sourcenamev DO
  { writef("Insufficient space available*n")
    GOTO fin
  }
  sourcefileno := 0
  FOR i = 0 TO sourcefileupb DO sourcenamev!i := "unknown"   

  // Sourcefile 1 is "builti-n" and is used during initialisation.
  // Sourcefile 2 is always the FROM argument filename
  // Higher numbers are GET files
  lineno := (1<<20) + 1
  targetstr, targetitem := 0, 0
 
  UNLESS rdargs("TARGET,FILE/K,TO/K,-m/S,-l/S,-p/S,-r/S,-s/S,-c/S,-d/S", argv, 50) DO
  { fatalerr("Bad arguments for BMAKE*n")
    RESULTIS 0
  }
  IF argv!0 DO targetstr := argv!0// TARGET
  IF argv!1 DO fromname := argv!1 // FROM  -- name of the makefile
  IF argv!2 DO toname := argv!2   // TO/K  -- name of the output file
  optMacros := argv!3             // -m/S  -- Output macrogenerated text 
  optTokens := argv!4             // -l/S  -- Trace lexical tokens
  optPats   := argv!5             // -r/S  -- Output the patterns
  optRules  := argv!6             // -r/S  -- Output rules before pattern application
  optSets   := argv!7             // -r/S  -- Output rules after pattern application
  optComs   := argv!8             // -c/S  -- Output the command sequence
  debug     := argv!9             // -d/S  -- Output debugging trace

  sourcefileno := 1
  sourcenamev!1 := fromname

  IF upb<500 DO upb := 500
  base := getvec(upb)    // BGPM workspace
  UNLESS base DO
    fatalerr("Unable to allocate work space (upb = %n)*n", upb)

  bgpmco := createco(bgpmfn, 2000)

  UNLESS bgpmco DO fatalerr("Unable to create bgpmco*n")

  sourcestream := findinput(fromname)
  UNLESS sourcestream DO
  { synerr("Unable to find file: %s*n", fromname)
    GOTO fin
  }

  IF toname DO
  { tostream := findoutput(toname)
    UNLESS tostream DO
    { synerr("Unable to find file: %s*n", toname)
      GOTO fin
    }
  }

  IF sourcestream DO selectinput(sourcestream)
  IF tostream DO selectoutput(tostream)
  

  IF optMacros DO
  { // Test the output of BGPM
    LET prevlineno = 0

    newline()

    { rch()
      IF ch=endstreamch BREAK
//writef("rch() => lineno ="); prlineno(lineno)
//writef("  ch = %i3: ", ch)
      //UNLESS lineno=prevlineno DO
      //{ newline()
      //  prlineno(lineno)
      //  writef(": ")
      //  prevlineno := lineno
      //}
      wrch(ch)
//newline()
//abort(1007)
    } REPEAT
    GOTO fin
  }

  rch()

  parse()              // Perform Syntax Analysis

  IF optTokens GOTO fin

  IF optPats DO
  { LET p = patnlist
    writef("*nPatterns*n*n")
    WHILE p DO
    { prpatn(p)
      p := !p
    }
    newline()
  }

  IF optRules DO
  { LET p = rulelist
    writes("*nRules*n*n")
    WHILE p DO
    { prrule(p)
      p := !p
    }
    newline()
  }

  // Apply the patterns

  apply_patterns()

  UNLESS targetitem DO
  { UNLESS rulelist DO fatalsynerr("No target specified")
    targetitem := n_subj!rulelist
  }

  IF optSets DO
  { LET p = rulelist

    IF targetitem DO writef("*nTarget: %s*n", @h3!targetitem)

    writef("*nRules after the application of the patterns*n*n")
    WHILE p DO
    { prrule(p)
      p := !p
    }
    newline()
  }

  IF errcount GOTO fin

  IF optComs DO
  { IF debug DO writef("Calling generate_commands(...)*n")
    UNLESS generate_commands(targetitem)=maxint DO
      writef("%s is already up to date*n", @h3!targetitem)
    GOTO fin
  }


  { LET newf   = VEC workfileupb
    LET workfile = "T-CMD0Tnn"
    LET newstream = 0
    LET outstream = 0

    newfile := newf

    // Construct work-file name
    //    T-CMD0Tnn
    //           nn     two digits of the taskid (=00 under cintsys)
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

//sawritef("bmake: using command file %s*n", newfile)

    IF debug DO writef("Calling generate_commands(...) to file %s*n", newfile)

    outstream := findoutput(newfile)

    UNLESS outstream DO
    { writef("Can't open file *"%s*" for output", newfile)
      GOTO fin
    }

    selectoutput(outstream)

//sawritef("bmake: calling generate_commands*n")
    UNLESS generate_commands(targetitem)=maxint DO
    { selectoutput(sysout)
      writef("%s is already up to date*n", @h3!targetitem)
      selectoutput(outstream)
    }
//sawritef("bmake: returned from generate_commands*n")

    // Copy rest of current input.

    selectinput(cli_currentinput)

//sawritef("bmake: cli_status=%x8 clibit_comcom=%x8*n", cli_status, clibit_comcom)

    IF (cli_status & clibit_comcom)~=0 DO
    { // If we were already processing a command-command, copy the
      // rest of the previous file into the new file
//sawritef("bmake: in a command-command copying from %s*n", cli_commandfile)
      { ch := rdch()
        IF ch = endstreamch BREAK
        wrch(ch)
      } REPEAT

      // Then close and delete the old file
      endstream(cli_currentinput)
      deletefile(cli_commandfile)
    }

    endstream(outstream)           // Close the new file

    newstream :=findinput(newfile) // and open it for input

    // Set up the new command file for the CLI to process,
    // remembering its name so that it can be deleted later.
    cli_currentinput := newstream
    FOR j = 0 TO newfile%0 DO cli_commandfile%j := newfile%j

    // Set the CLI comcom bit
    cli_status := cli_status | clibit_comcom

    selectoutput(sysout)
    IF debug DO writef("bmake returning to the CLI to execute script %s*n",
                        cli_commandfile)
  }

fin:
  IF bgpmco DO deleteco(bgpmco)
  UNLESS sourcestream=sysin DO endstream(sourcestream)
  UNLESS tostream=sysout    DO endstream(tostream)
  selectinput(sysin)
  selectoutput(sysout)
  IF base DO freevec(base)
  WHILE blklist DO
  { LET blk = blklist
    blklist := !blk
    freevec(blk)
  }
  RESULTIS 0
}

// This section implements a macrogenerator based on GPM
// designed by Strachey (in 1964)

LET prlineno(ln) BE
{ LET fileno = ln>>20
  LET lno = ln & #xFFFFF
  TEST ln
  THEN writef(" %s[%n]", sourcenamev!fileno, lno)
  ELSE writef(" <no line>")
//abort(1005)
}

LET bgputch(ch) BE
{ TEST bg_h=0
  THEN TEST ch >= (1<<20)
       THEN lineno := ch
       ELSE cowait(ch)
  ELSE push(ch)

  IF ch = '*n' DO lineno := lineno+1
}

AND push(ch) = VALOF { IF bg_t=bg_s DO bg_error("Insufficient work space")
                       bg_s := bg_s + 1
                       !bg_s := ch
                       RESULTIS bg_s
                     }

AND bggetch() = VALOF
{ LET ch = ?
//writef("bggetch: called with bg_c=%n lineno=%x8*n", bg_c, lineno)
  TEST bg_c
  THEN { // Reading from a macro body
         bg_c := bg_c+1
         ch := !bg_c
         // Check for file/line number
         IF ch>=(1<<20) DO { lineno := ch; LOOP }
         // Check for newline
  //IF ch='*n' DO lineno := lineno + 1
         RESULTIS ch
       } REPEAT
  ELSE { // Reading from file
         ch := rdch()

         { // Check for comment
           UNLESS ch=c_comment RESULTIS ch

           // Skip a bgpm comment. Ie skip characters
           // up to and including the newline and then skip
           // to the next non white space character. 
           { // Skip over the current line
             ch := rdch()
             IF ch=endstreamch RESULTIS ch
             IF ch='*n' DO
             { lineno := lineno + 1
               BREAK
             }
           } REPEAT

           { // Skip over white space
             ch := rdch()
             IF ch='*s' | ch='*t' LOOP
             IF ch='*n' DO
             { lineno := lineno+1
               LOOP
             }
             BREAK
           } REPEAT 
           // ch is a non white space character
         } REPEAT
       }
}

AND arg(a, n) = VALOF { IF !a<0 DO bg_error("Too few arguments")
                        IF n=0 RESULTIS a
                        a, n := a+!a+1, n-1
                      } REPEAT

AND lookup(name) = VALOF
{ LET a, i, len = bg_e, 0, !name
  LET buf = VEC 256/bytesperword
//writef("lookup: "); prlineno(lineno)
//writef(" Looking up *"%s*"*n", arg2str(name, buf))

  WHILE a DO
  { LET p = name
    LET q = @a!2
    LET pe, qe = p+!p, q+!q

    { LET ch1 = s_eom
      LET ch2 = s_eom
      // Skip over file/line items
      WHILE p<pe DO
      { p := p+1
        ch1 := !p
        IF ch1<=255 BREAK
      }
      // Skip over file/line items
      WHILE q<qe DO
      { q := q+1
        ch2 := !q
        IF ch2<=255 BREAK
      }
      UNLESS ch1=ch2 BREAK
      IF ch1=s_eom RESULTIS a    // Macro definition found
      // Compare more characters
    } REPEAT
    // try the next macro definition
    a := !a      
  }

  bg_error("Macro *"%s*" not defined", arg2str(name, buf))
  RESULTIS 0
}

AND arg2str(a, str) = VALOF
{ LET len = !a
  LET i, j = 0, 1
  IF len>20 DO len := 20
  FOR j = 1 TO len DO
  { LET ch = a!j
    IF ch>255 LOOP  // Ignore line number words
    i := i+1
    str%i := ch
  }
  str%0 := i
  IF !a>20 DO str%19, str%20 := '.', '.'
  RESULTIS str
}

AND define(name, code) BE
{ LET s1 = bg_s
//sawritef("define: Defining %s S=%n T=%n E=%n*n", name, bg_s, bg_t, bg_e)
  push(bg_e)  // Save the old environment pointer
  push(bg_t)  // and t
  // Push the macro name onto the stack
  push(name%0+1)
  push((1<<20) + 1)
  FOR i = 1 TO name%0 DO push(name%i)
  push(2)          // Every macro body starts with a line number
  push((1<<20)+1)  // Special line number for built-in macros
  push(code)       // The built-in macro code
  push(s_eom)      // This marks the end of the argument list.
  UNTIL bg_s=s1 DO { !bg_t := !bg_s; bg_t, bg_s := bg_t-1, bg_s-1 }
  bg_e := bg_t+1   // Set the new environment pointer 
//sawritef("define: Defined  %s S=%n T=%n E=%n*n", name, bg_s, bg_t, bg_e)
//abort(1001)
}

AND bgpmfn() BE
{ // This is the main function of bgpmco which generates the sequence
  // of characters of the macro expansion of its source file.
  // It passes the expanded text to the lexical analyser by call
  // of cowait(ch), and maintains lineno to always hold the file/line
  // number of the latest character passed.

  rec_p, rec_l := level(), ret

  bg_s, bg_t, bg_h, bg_p, bg_f, bg_e, bg_c := base-1, base+upb, 0, 0, 0, 0, 0

  //lineno := (2<<20) + 1       // Special file/line number for built-in macros

  define("def",     s_def)
  define("set",     s_set)
  define("get",     s_get)
  define("eval",    s_eval)
  define("lquote",  s_lquote)
  define("rquote",  s_rquote)
  define("eof",     s_eof)
  define("rep",     s_rep)

  { // Start of main scanning loop.

//writef("bgpmfn: calling bggetch()*n")
    bg_ch := bggetch()

    // bg_ch is the next character to scan.
    // It might be a special operator such as s_def or s_eom
    // or a file/line nummber: (fno<<20) + line
    // or an ordinary ASCII character.

//writef("bgpmfn: bg_ch=%x8*n", bg_ch)
sw:

//writef("bgpmfn: ch=%x8 ", bg_ch)
//IF 32<=bg_ch<=127 DO writef("'%c' ", bg_ch)
//IF bg_ch<0        DO writef(" %i3 ", bg_ch)
//prlineno(lineno); newline()
//abort(1009)

    SWITCHON bg_ch INTO
    { DEFAULT:
//writef("bgpmfn: DEFAULT: bg_ch=%x8*n", bg_ch)
           IF bg_ch>=(1<<20) DO
           { // Update the file/line number variable
             lineno := bg_ch
             bgputch(bg_ch)
             LOOP
           }
//writef("bgpmfn: DEFAULT: ch now set to %x8*n", bg_ch)
           bgputch(bg_ch)
           LOOP

      CASE endstreamch:
           IF getstreams=0 DO
           { // End of file at the outermost level
             // So send end-of-stream characters from now on.
             cowait(endstreamch) REPEAT
           }
           // Close the get stream and resume the previous input.
           endread()
           lineno       := h3!getstreams
           sourcestream := h2!getstreams
           getstreams   := h1!getstreams
           selectinput(sourcestream)
//writef("bgpm: eof sourcestream=%n", sourcestream); prlineno(lineno)
//newline()
           LOOP

      CASE c_lquote:
         { LET d = 1
           { bg_ch := bggetch()
             IF bg_ch<0 DO bg_error("Non character in quoted string")
             IF bg_ch=c_lquote DO   d := d+1
             IF bg_ch=c_rquote DO { d := d-1; IF d=0 BREAK }
             bgputch(bg_ch)
           } REPEAT
           LOOP
         }

      CASE c_call:               // '['
           bg_f := push(bg_f)    // Position of start of new macro call
           push(bg_h)            // Save start of previous arg start
           push(?)               // Space for lno
           push(?)               // Space for e
           push(?)               //       and t
           bg_h := push(?)       // Start of zeroth arg of new call
           push(lineno)          // File/line number of zeroth arg
           LOOP

      CASE c_sep:                // '!'
           IF bg_h=0 DO          // ignore if not reading macro arguments
           { bgputch(bg_ch)
             LOOP
           }
           !bg_h := bg_s-bg_h    // Fill in the length of latest arg
           bg_h := push(?)       // Start a new arg
           push(lineno)          // File/line number of next arg
           LOOP

      CASE c_arg:                // '#'
           IF bg_p=0 DO          // Ignore if not expanding a macro
           { bgputch(bg_ch)
             LOOP
           }
           bg_ch := bggetch()
           { // Read and integer and use it to find the start
             // of the corresponding macro argument
             LET a = arg(bg_p+5, rdint())
             LET lno = lineno    // Save current file/line number
             // Copy the specified argument
             FOR q = a+1 TO a+!a DO
             { LET ch = !q
               IF ch >= (1<<20) DO
               { lineno := ch
                 LOOP
               }
               IF ch = '*n' DO lineno := lineno + 1
               bgputch(ch)
             }
             lineno := lno    // Restore the file/line number
             GOTO sw
           }

      CASE c_apply:               // Apply (])
         { LET a = bg_f

           IF bg_h=0 DO           // Ignore if not reading arguments
           { bgputch(ch)
             LOOP
           }

           !bg_h := bg_s-bg_h     // Fill in the length of the latest arg
           push(s_eom)            // Append EOM marking end of args
           bg_f := a!0            // Restore previous start of call pointer
           bg_h := a!1            // Restore previous start of arg pointer
           a!0 := bg_p            // Save current state
           a!1 := bg_c
           a!2 := lineno          // Save current  file/line number.
           a!3 := bg_e
           a!4 := bg_t
           // Copy the call to the top end.
           { !bg_t := !bg_s; bg_t, bg_s := bg_t-1, bg_s-1 } REPEATUNTIL bg_s<a
           bg_p := bg_t+1
           bg_c := arg(lookup(bg_p+5)+2, 1)
           LOOP
         }

      CASE s_lquote:                 // Left quote ('{')
           bgputch(c_lquote)
           LOOP

      CASE s_rquote:                 // Right quote ('}')
           bgputch(c_rquote)
           LOOP
         
      CASE s_comment:                // Comment character ('%')
           bgputch(c_comment)
           LOOP
         
      CASE s_eof:                    // End of file
//writef("s_eof: reached*n")
           cowait(s_eof)
           RETURN

      CASE s_eom:                    // End of macro body
ret:       IF bg_p=0 LOOP
           bg_t   := bg_p!4
           bg_e   := bg_p!3
           lineno := bg_p!2
           bg_c   := bg_p!1
           bg_p   := bg_p!0
           LOOP

      CASE s_def:                    // [def!name!body...]
          //            *----------------------------------------------*
          //   F H ln E T | n ln d e f | n ln name | n ln body ...     eom
          // ^ ^
          // T P
          //                         *---------------------------------*
          //                       E T | n ln name | n ln body eom ... eom
          //                       ^
          //                       E
         { LET a1 = arg(bg_p+5, 1)   // The name
           LET a2 = arg(bg_p+5, 2)   // The body
           a2!(!a2+1) := s_eom       // Mark the end of the body
           bg_e   := a1 - 2
           bg_t   := bg_e-1
           bg_e!1 := bg_p!4          // previous T
           bg_e!0 := bg_p!3          // previous E
           lineno := bg_p!2          // previous file/line
           bg_c   := bg_p!1          // previous C
           bg_p   := bg_p!0          // previous P
           LOOP
         }

      CASE s_set:                    // [set!name!new value]
         { LET name = arg(bg_p+5, 1)
           LET val  = arg(bg_p+5, 2)
           LET len = !val
           LET a = lookup(name)
           LET b = arg(a+2, 1)
           LET max = a!1 - b - 1  // Max length of the value.
           IF len>max DO len := max
           FOR i = 0 TO len DO b!i := val!i
           b!(len+1) := s_eom
           GOTO ret
         }

      CASE s_get:                    // [get!filename]
         { LET name = arg(bg_p+5, 1)
           LET len = !name
           LET n = 0
           LET filename = VEC 256/bytesperword
           //lineno := bg_p!2 // Use the file/line of the get call.
           // Remove file/line items from the file name
           FOR i = 1 TO len DO
           { LET ch = name!i
             IF ch >= (1<<20) LOOP
             n := n+1
             IF n>255 DO bg_error("File name too long")
             filename%n := name!i
             filename%0 := n
           }
           // Return from [get!....]
           bg_t   := bg_p!4
           bg_e   := bg_p!3
           lineno := bg_p!2
           bg_c   := bg_p!1
           bg_p   := bg_p!0
           performget(filename)
           LOOP
         }

      CASE s_eval:                    // [eval!expression]
           bgwrnum(evalarg(1))
           GOTO ret

      CASE s_rep:                     // [rep!count!text]
         { LET a = arg(bg_p+5, 2)
           FOR k = 1 TO evalarg(1) DO
             FOR q = a+1 TO a+!a DO bgputch(!q)
           GOTO ret
         }
    }
  } REPEAT
}

AND rdint() = VALOF
{ // Only used for #ddd
  LET val = 0
  GOTO M

L:bg_ch := bggetch()

M:IF bg_ch >= (1<<20) GOTO L
  IF '0'<=bg_ch<='9' DO { val := 10*val + bg_ch - '0'; GOTO L }

  RESULTIS val
}

AND performget(filename) BE
{ // First look in the current directory
  LET stream = findinput(filename)
//  writef("Searching for *"%s*" in the current directory*n", filename)

  // Then try the headers directories
//  UNLESS stream DO writef("Searching for *"%s*" in MUSHDRS*n", filename)
  UNLESS stream DO stream := pathfindinput(filename, "MUSHDRS")

  UNLESS stream DO
  { bg_error("Unable to $get!%s;", filename)
    RETURN
  }

  IF sourcefileno>=sourcefileupb DO
  { bg_error("Too many GET files")
    RETURN
  }

  { LET len = filename%0
    LET str = newvec(len/bytesperword)
    IF str FOR i = 0 TO len DO str%i := filename%i
    sourcefileno := sourcefileno+1
    sourcenamev!sourcefileno := str
  }

  getstreams := mk3(getstreams, sourcestream, lineno)
  sourcestream := stream
  selectinput(sourcestream)
//writef("performget: old lno = "); prlineno(lineno)
//newline()
  lineno := (sourcefileno<<20) + 1
//writef("performget: new lno = "); prlineno(lineno)
//newline()
}

AND evalarg(n) = VALOF
{ argp := arg(bg_p+5, n)
  argt := argp + !argp + 1
  RESULTIS bgexp(0)
}

AND bgbexp() = VALOF
{ bg_ch := getargch()

//sawritef("bgbexp: bg_ch=%n*n", bg_ch)
  SWITCHON bg_ch INTO
  { DEFAULT:  bg_error("Bad expression, ch=%c", ch)

    CASE '*s': LOOP // Ignore spaces within expressions

    CASE '.':
    CASE '0': CASE '1': CASE '2': CASE '3': CASE '4':
    CASE '5': CASE '6': CASE '7': CASE '8': CASE '9':
              RESULTIS  bgrdnum()

    CASE '+': RESULTIS  bgexp(2)
    CASE '-': RESULTIS -bgexp(2)

    CASE '(': { LET res = bgexp(1)
                bg_ch := getargch()
                RESULTIS res
              }
  }
} REPEAT

AND bgexp(n) = VALOF
{ LET a = bgbexp()

  { SWITCHON bg_ch INTO
    { DEFAULT:   IF n>1 | n=1 & bg_ch=')' | n=0 & bg_ch=s_eof RESULTIS a
      err:       bg_error("Bad expression")
      CASE '*s': bg_ch := getargch() // Ignore spaces within expressions
                 LOOP

      CASE 'R':                                // R   (right shift)
      CASE 'r':  IF n<6 DO { LET b = bgexp(6)
                             a := a>>b
                             LOOP
                           }
                 RESULTIS a

      CASE 'L':                                // L   (left shift)
      CASE 'l':  IF n<6 DO { LET b = bgexp(6)
                             a := a<<b
                             LOOP
                           }
                 RESULTIS a
      CASE '**': IF n<5 DO { a := muldiv(a, bgexp(5),  1_000); LOOP }
                 RESULTIS a
      CASE '/':  IF n<5 DO { a := muldiv(a,  1_000, bgexp(5)); LOOP }
                 RESULTIS a
      CASE '+':  IF n<4 DO { a := a  +  bgexp(4); LOOP }
                 RESULTIS a
      CASE '-':  IF n<4 DO { a := a  -  bgexp(4); LOOP }
                 RESULTIS a
      CASE '&':  IF n<3 DO { LET b = bgexp(3)
                             a := a & b
                             LOOP
                           }
                 RESULTIS a
      CASE '|':  IF n<2 DO { LET b = bgexp(2)
                             a := a | b
                             LOOP
                           }
                 RESULTIS a
    }
  } REPEAT
}

AND getargch() = VALOF
{ LET p = argp+1
  IF p>=argt RESULTIS s_eof
  argp := p
  ch := !p
  UNLESS ch >= (1<<20) RESULTIS ch
  lineno := ch
  // Skip over file/line items
} REPEAT

AND bgrdnum() = VALOF
{ // Only used in bexp
  LET val = 0
  WHILE '0'<=bg_ch<='9' DO { val := 10*val + bg_ch - '0'
                             bg_ch := getargch()
                           }
  RESULTIS val
}

AND bgwrnum(n) BE
{ LET frac = ?
  IF n<0 DO { bgputch('-'); n := -n }
  wrpn(n)
}

AND wrpn(n) BE
{ IF n>9 DO wrpn(n/10)
  bgputch(n MOD 10 + '0')
}

AND wrc(ch) BE IF -127<=ch<=127 DO
{ IF ch='*n' DO { newline(); chpos := 0; RETURN }
  IF chpos>70 DO wrs("*n  ")
  TEST ch<0
  THEN { writef("'%n'", ch)
         chpos := chpos+4
       }
  ELSE { UNLESS '*s'<=ch<127 DO ch := '?'  // Assume 7 bit ASCII.
         wrch(ch)
         IF ch='*n' DO wrs("  ")
         chpos := chpos+1
       }
}

AND wrs(s) BE FOR i = 1 TO s%0 DO wrc(s%i)

AND wrn(n) BE
{ IF n>9 DO wrn(n/10)
  wrc(n MOD 10 + '0')
}

AND bg_error(mess, a, b, c) BE
{ LET out = output()
  selectoutput(sysout)
  wrs("*n*n######### Error near"); prlineno(lineno); wrs(": ")
  writef(mess, a, b, c)
  //error()
  selectoutput(out)
}

AND error() BE
{ wrs("*nIncomplete calls:*n")
  IF bg_f DO prcall(3, bg_f, bg_h, bg_s)
  wrs("Active macro calls:*n"); btrace(bg_p, 3)
  //wrs("*nEnvironment:*n");  wrenv(bg_e, 20)
  //wrs("######### End of error message*n")
  wrc('*n')

  errcount := errcount+1
  IF errcount >= errmax DO fatalerr("*nToo many errors")
  
  selectoutput(tostream)
  longjump(rec_p, rec_l)
}

AND prcall(n, f, h, s) BE UNLESS f=0 TEST n=0
                                     THEN wrs(" ...")
                                     ELSE { prcall(n-1, !f, f!1, f-1)
                                            !h := s-h
                                            wrcall(f+5, s)
                                          }

AND btrace(p, n) BE
{ IF n=0 DO wrs(" ...*n")
  IF p=0 | n=0 RETURN
  wrcall(p+5, p!4); wrc(c_apply); wrc('*n')
  p, n := !p, n-1
} REPEAT

AND wrcall(a, b) BE
{ LET sep = c_call
  LET lno = a!1
  LET filename = sourcenamev!(lno>>20)
  LET ln = lno & #xFFFFF
  wrc('*s')
  FOR i = 1 TO filename%0 DO wrc(filename%i)
  wrc('[')
  wrn(ln)
  wrs("]: ")
 
  UNTIL a>=b DO { wrc(sep); wrarg(a)
                  a := a + !a + 1
                  sep := c_sep
                }
}

AND wrarg(a) BE
{ LET len = !a
  IF len > 60 DO len := 60
  FOR ptr = a+2 TO a + len DO wrc(!ptr)
  IF !a > 60 DO wrs(" ...")
}

AND wrenv(e, n) BE UNTIL e=0 DO
{ LET name  = arg(e+2, 0)
  LET value = arg(e+2, 1)
  IF n=0 DO { wrs(" ...*n"); RETURN }
  wrs(" Name: ");   wrarg(name); FOR i = !name TO 12 DO wrc('*s')
  wrs("  Value: "); wrarg(value)
  wrc('*n')
  e, n := !e, n-1
}

LET newvec(n) = VALOF
{ LET p = blkp
  LET blkupb = 10_000
  blkp := p+n+1
  IF blkp>=blkt DO
  { LET v = getvec(blkupb) // Get some more space
//writef("newvec: allocation block %n upb %n*n", v, blkupb)
    UNLESS v & n<blkupb DO
    { bg_error("System error: newvec failure*n")
      abort(999)
    }
    
    v!0 := blklist
    blklist := v
    blkt := v+blkupb
    p    := v+1
    blkp := p+n+1
  }
//writef("newvec: allocated p=%n n=%i4 blklist=%n*n",
//         p, n, blklist)
  RESULTIS p
}
 
AND mk1(x) = VALOF
{ LET p = newvec(0)
  p!0 := x
  RESULTIS p
}
 
AND mk2(x, y) = VALOF
{ LET p = newvec(1)
  p!0, p!1 := x, y
  RESULTIS p
}
 
AND mk3(x, y, z) = VALOF
{ LET p = newvec(2) // Allocate a new node
  p!0, p!1, p!2 := x, y, z
  RESULTIS p
}
 
AND mk4(x, y, z, t) = VALOF
{ LET p = newvec(3)
  p!0, p!1, p!2, p!3 := x, y, z, t
  RESULTIS p
}
 
AND mk5(x, y, z, t, u) = VALOF
{ LET p = newvec(4)
  p!0, p!1, p!2, p!3, p!4 := x, y, z, t, u
  RESULTIS p
}
 
AND mk6(x, y, z, t, u, v) = VALOF
{ LET p = newvec(5)
  p!0, p!1, p!2, p!3, p!4, p!5 := x, y, z, t, u, v
  RESULTIS p
}
 
AND mk7(x, y, z, t, u, v, w) = VALOF
{ LET p = newvec(6)
  p!0, p!1, p!2, p!3, p!4, p!5, p!6 := x, y, z, t, u, v, w
  RESULTIS p
}

AND mk8(a, b, c, d, e, f, g, h) = VALOF
{ LET p = newvec(7)
  p!0, p!1, p!2, p!3, p!4, p!5, p!6, p!7 := a, b, c, d, e, f, g, h
  RESULTIS p
}

AND mk9(a, b, c, d, e, f, g, h, i) = VALOF
{ LET p = newvec(8)
  p!0, p!1, p!2, p!3, p!4, p!5, p!6, p!7, p!8 := a, b, c, d, e, f, g, h, i
  RESULTIS p
}

LET rch() BE
{ ch := callco(bgpmco)
//writef("*nrch: ch=%x8*n", ch)
  UNLESS ch=endstreamch DO
  { chcount := chcount+1
    chbuf%(chcount&63) := ch
  }
}

AND lex() BE
{ //   <=           -> dependson
  //   << ... >>    -> com
  //   ...          -> item
  //   endofstream  -> eof

  // Within a command string or item, parameters <...> may occur

  // Items are terminated by <=, << or white space

  param, parampos, len := 0, 0, 0
  token := s_item // Until proved otherwise

//sawritef("lex: lineno=%n/%n ch=%n '%c'*n",
//  lineno>>20, lineno&#xFFFFF, ch, ch)

sw:
  SWITCHON ch INTO
  { DEFAULT:
      IF ch='>' & token=s_com DO
      { // Check if >>
        rch()
        IF ch='>' DO
        { // End of command string reached
          rch()
          // token=s_com  and len is the length of the string
          // held in charv%1 ... charv%len
          RETURN   // A command string
        }
        len := len + 1
        charv%len := '>'
//writef("charv%%%n=%n*n", len, charv%len)
      }
      len := len + 1
      charv%len := ch
//writef("charv%%%n=%n*n", len, charv%len)
      rch()
      GOTO sw

    CASE endstreamch:
      IF len RETURN // An item or command sequence
                    // len is the length of the string
                    // held in charv%1 ... charv%len
      token := s_eof
      RETURN        // eof

    CASE '*p': CASE '*n':
    CASE '*c': CASE '*t': CASE '*s':
      IF token=s_com DO
      { // Copy command string characters into charv
        len := len+1
        charv%len := ch
        rch()
        GOTO sw
      }
      IF len RETURN // Return an item
      rch()         // Ignore white space
      GOTO sw

    CASE '<':
      // It might be
      //    <=
      //    <<
      // or the start a parameter <tag>
      rch()

      IF ch='=' DO
      { // <=
        IF len & token=s_item DO
        { ch := '<'
          unrdch() // Put '=' back
          RETURN   // An item
        }
        token := s_dependson
        rch()
        RETURN
      }

      IF ch='<' DO
      { // <<
        IF len & token=s_item DO
        { ch := '<'
          unrdch() // Put '<' back
          RETURN   // An item
        }
        // Start reading a command sequence
        token := s_com
        // Skip over '<' and ignore white space
        rch() REPEATWHILE ch='*s' | ch='*t' | ch='*n'
        GOTO sw
      }

      // It must be a parameter of form <...>
      rdtag()
      len := len+1
      charv%len := 0  // Indicating a parameter
      parampos := len // position of the parameter
//writef("charv%%%n=%n*n", len, charv%len)
      GOTO sw
  }
}

AND rdtag() BE
{ // Read a tag   < ch ... >
  LET i = 1
  LET tag = 0

  tagv%1 := '<'

  { // Read tag characters
    UNLESS 'A'<=ch<='Z' |
           'a'<=ch<='z' |
           '0'<=ch<='9' BREAK
    i := i+1
    IF i>254 DO synerr("Parameter tag too long")
    tagv%i := ch
    rch()
  } REPEAT

  UNLESS ch='>' DO synerr("Bad parameter tag, ch=%c", ch)
  i := i+1
  tagv%i := '>'
  tagv%0 := i

  rch()
  tag := lookupword(tagv)
  TEST param
  THEN UNLESS param=tag DO
         synerr("All parameters in a pattern must be the same")
  ELSE param := tag
}
 
LET lookupword(word) = VALOF
{ // Return a pointer to [next, rule, <packed string] for an item
  // or param string.
  // The next field is used for hash chains.
  // The rule field will point to the rule, if any, whose subject
  // is this item.
  LET len, i = word%0, 0
  LET hashval = len
  FOR i = 1 TO len DO hashval := (13*hashval + word%i) & #xFF_FFFF
  hashval := hashval MOD nametablesize
  wordnode := nametable!hashval
 
  WHILE wordnode & i<=len TEST (@h3!wordnode)%i=word%i
                          THEN i := i+1
                          ELSE wordnode, i := !wordnode, 0
  UNLESS wordnode DO
  { // len = 0, 1, 2, 3  => upb 2
    // len = 4, 5, 6, 7  => upb 3,  etc
    wordnode := newvec(len/bytesperword+2)
    // Insert at head of hash chain
    h1!wordnode := nametable!hashval
    nametable!hashval := wordnode
    h2!wordnode := 0  // The rule pointer is not yet known
    FOR i = 0 TO len DO (@h3!wordnode)%i := word%i
  }
//writef("lookupword: wordnode=%n %s*n", wordnode, @h3!wordnode)
  RESULTIS wordnode
}
 
AND wrchbuf() BE
{ writes("*n...")
  FOR p = chcount-63 TO chcount DO
  { LET k = chbuf%(p&63)
    IF 0<k<255 DO wrch(k)
  }
  newline()
}
 
AND parse() = VALOF
{ LET res = 0
  rec_p, rec_l := level(), recover

  rulelist, ruleliste := 0, @rulelist
  patnlist, patnliste := 0, @patnlist

  charv := newvec(charvupb/bytesperword)     
  tagv := newvec(256/bytesperword)     
  nametable := newvec(nametablesize)
  UNLESS tagv & charv & nametable DO
    fatalerr("More workspace needed")
  FOR i = 0 TO nametablesize DO nametable!i := 0

  IF optTokens DO newline()

  // Create the target item if the target is explicitly given.

  IF targetstr DO targetitem := lookupword(targetstr)

  // Now process the bmakefile

  lex()

  WHILE optTokens DO
  { // Loop to test the lexical analyser
    writef("%t9", opstr(token))

    SWITCHON token INTO
    { DEFAULT:
         writef("Bad token %t9*n", opstr(token))
         ENDCASE

      CASE s_item:
         FOR i = 1 TO len DO
         { LET c = charv%i
           TEST c
           THEN wrch(c)
           ELSE writef("%s", @h3!param)
         }
         newline()
         ENDCASE

      CASE s_dependson:
         newline()
         ENDCASE

      CASE s_eof:
         newline()
         RESULTIS 0

      CASE s_com:
         writef("*n<<*n")
         FOR i = 1 TO len DO
         { LET c = charv%i
           TEST c
           THEN wrch(c)
           ELSE writef("%s", @h3!param)
         }
         writef(">>*n")
         param := 0
         ENDCASE
    }

    lex()
  }


recover:
  IF optTokens RESULTIS 0

  // Read in the rules and patterns

  UNTIL token=s_eof DO
  { LET ln, subject, dpns, com, par = lineno, 0, 0, 0, 0

//writef("Expecting item: token=%n %s*n", token, opstr(token))

    UNLESS token=s_item DO synerr("Target-item expected")

    IF param DO
    { par := param
      //writef("Pattern with parameter %s*n", @h3!par)
    }

    charv%0 := len
    subject := lookupword(charv)
    IF param DO h2!subject := parampos
    // subject -> [chain,   0, <packed chars>] // If non pattern item
    // subject -> [chain, pos, <packed chars>] // If pattern item

    lex()
//writef("Expecting dependson or com: token=%n %s*n", token, opstr(token))

    IF token=s_dependson DO
    { // Read the depends on list
      LET dpnse = @dpns
      lex()   // Skip over <=

      // read zero or more items
      WHILE token=s_item DO
      { LET node = 0
        charv%0 := len
        lookupword(charv)
        IF param DO h2!wordnode := parampos
        node := mk2(0, wordnode)
//writef("dpns node=%n wordnode=%n %s*n", node, wordnode, @h3!wordnode)
        UNLESS node DO fatalsynerr("Out of space")
        // Append this item to the end of the list
        !dpnse := node
        dpnse := node
        // If the item contains a parameter it must have been declared
        // in the subject item
        TEST par
        THEN UNLESS param=0 | par=param DO
               synerr("Parameter %s should be %s*n", @h3!param, @h3!par)
        ELSE IF param DO
               synerr("Parameter %s not allowed in a rule", @h3!param)
        lex()
      }
    }

    // Now read the command sequence (enclosed in << and >>)
//writef("Expecting com: token=%n %s*n", token, opstr(token))
    UNLESS token=s_com DO synerr("<< ... >> expected")

    { // token = s_com  and
      // len (may be zero) holds the number of characters, ie
      // charv%1 ... charv%len  are the characters of the command sequence

      // Make a command node of the form:
      //   com -> [len, <packed chars>]
      // Since the length may be greater than 255 it is held in com!0
      // not in (com+1)%0.
      // The packed characters are in (com+1)%1 ... (com+1)%len
      LET upb = 2 + len/bytesperword
      // len = 0, 1, 2, 3  =>  upb = 2
      // len = 4, 5, 6, 7  =>  upb = 3, etc
      com := newvec(upb)
      UNLESS com DO synerr("More space needed")
      com!0 := len
      FOR i = 1 TO len DO (com+1)%i := charv%i
//      writef("*ncom=%n allocated*n", com)
    }

    TEST par
    THEN UNLESS par=param DO
           synerr("Parameter %s should be %s*n", @h3!param, @h3!par)
    ELSE IF param DO
           synerr("Parameter %s not allowed in a rule", @h3!param)

    // Append the rule or pattern onto the end of the appropriate list.
    TEST par
    THEN { !patnliste := mk6(0, ln, subject, dpns, com, par)
           patnliste := !patnliste
//writef("Added pattern %n*n", patnliste)
         }
    ELSE { // subject -> [chain, rule, <packed chars>]
           !ruleliste := mk9(0, ln, subject, dpns, com,
                            -1, // state
                             0, // days  )  modification time of the subject
                             0, // msecs )
                             0) // ticks for compatibility with old dat format
           ruleliste := !ruleliste
           IF h2!subject DO synerr("Second rule for subject %s", @h3!subject)
           h2!subject := ruleliste
         }

    lex()     // Skip over the body
  }

  RESULTIS res
}

AND fatalerr(mess, a, b, c) BE
{ selectoutput(sysout)
  writes("*nError: ")
  writef(mess, a, b, c)
  writes("*nBMAKE aborted*n")
  longjump(fin_p, fin_l)
}
 
AND fatalsynerr(mess, a, b) BE
{ selectoutput(sysout)
  writef("*nError near line:  "); prlineno(lineno); newline()
  writef(mess, a, b)
  writef("*nRecent text:*n")
  wrchbuf()
  errcount := errcount+1
  writes("*nBMAKE aborted*n")
  longjump(fin_p, fin_l)
}

AND synerr(mess, a, b, c) BE
{ LET out = output()
  selectoutput(sysout)
  writef("*nError near line:  "); prlineno(lineno); newline()
  writef(mess, a, b, c)
  wrchbuf()
  // Skip the rest of the input line 
  UNTIL ch='*n' | ch=endstreamch DO rch()
  lex()
  error("")
  errcount := errcount+1
  IF errcount >= errmax DO fatalerr("Too many errors")

//abort(1000)
  selectoutput(out)
  longjump(rec_p, rec_l)
}

AND prrule(p) BE
{ // p -> [next, ln, subject, dpns, com, state, days, msecs, -]
  LET s = @h3!(n_subj!p)
  LET q = n_dpns!p
  LET com = n_com!p
  LET dstrings = VEC 14
  dat_to_strings(@n_days!p, dstrings)

  //writef("%i6  ", p)
  writef("%s <=  Date: %s %s   ", s, dstrings, dstrings+5)
  IF n_ln!p DO prlineno(n_ln!p)
  newline()

  WHILE q DO
  { // q -> [next, item]
    LET s = @h3!(h2!q)
    writef("     %s*n", s)
    q := !q
  }

  writef("<<*n")
  TEST com
  THEN FOR i = 1 TO h1!com DO wrch((com+1)%i)
  ELSE writef("default-rule")
  writef("*n>>*n*n")
}

AND prpatn(p) BE
{ // p -> [next, ln, subject, dpns, com, param]
  LET s   = @h3!(n_subj!p)
  LET q   = n_dpns!p
  LET com = n_com!p
  LET parstr = @h3!(n_param!p)

  FOR i = 1 TO s%0 DO
  { LET c = s%i
    TEST c
    THEN wrch(c)
    ELSE writef("%s", parstr)
  }

  writef(" <=   ")
  prlineno(n_ln!p)
  newline()

  WHILE q DO
  { LET s = @h3!(h2!q)
    writef("     ")
    FOR i = 1 TO s%0 DO
    { LET c = s%i
      TEST c
      THEN wrch(c)
      ELSE writef("%s", parstr)
    }
    newline()
    q := !q
  }

  writef("<<*n")
//writef("parstr = %s com=%n*n", parstr, com)
  IF com FOR i = 1 TO h1!com DO
  { LET c = (com+1)%i
    TEST c
    THEN wrch(c)
    ELSE writef("%s", parstr)
  }
  writef("*n>>*n*n")
}

AND pritemstr(str, parstr) BE
{ FOR i = 1 TO str%0 DO
  { LET c = str%i
//writef("pritemstr: c=%n*n", c)
    TEST c
    THEN wrch(c)
    ELSE writef("%s", parstr)
  }
}

AND opstr(tok) = VALOF SWITCHON tok INTO
{ DEFAULT:          RESULTIS "Unknown op"

  CASE s_com:       RESULTIS "Com"
  CASE s_dependson: RESULTIS "Dependson"
  CASE s_eof:       RESULTIS "Eof"
  CASE s_item:      RESULTIS "Item"
}

AND apply_patterns() BE
{ // Ensure that items in the rule list have a defining rule
  // using patterns to create them if necessary.
  LET r = rulelist

  IF targetitem DO findrulefor(targetitem)

  WHILE r DO
  { // Iterate through all the rules in the rule list
    // including new rules added during the proccess.
    LET dpns = n_dpns!r
    LET subjstr = @h3!(n_subj!r)
    LET rc = sys(Sys_filemodtime, subjstr, @n_days!r) 
    LET dstrings = VEC 14

//    writef("*napply_patterns: processing rule %n with subject %s*n",
//            r, subjstr)

    dat_to_strings(@n_days!r, dstrings)
 //writef("apply_pattern: file %s mod time %s %s*n", subjstr, dstrings, dstrings+5)

    WHILE dpns DO
    { // Iterate through the items in the depends on list
      LET item = h2!dpns
      findrulefor(item)
      dpns := !dpns
    }

    r := !r
  }
}

AND findrulefor(item) BE
{ LET itemstr = @h3!item
  LET rule = h2!item
  LET p = patnlist
  IF rule RETURN

  //writef("findrulefor: looking for pattern for %s*n", @h3!item)

  WHILE p DO
  { LET subj = n_subj!p
    LET parstr = @h3!(n_param!p)
    LET subjstr = @h3!subj
    LET pos = h2!subj

    IF match(itemstr, subjstr, pos, tagv) DO
    { // Matching pattern found
      LET ln = n_ln!p      // Line number of the pattern
      LET dpns = n_dpns!p
      LET com = n_com!p
      LET newdpns = 0      // For the new depends on list
      LET dpe = @newdpns
      LET newcom = 0       // For the new command sequence

IF debug DO
  writef("Making rule from pattern for %s tagv=%s*n", itemstr, tagv)

      WHILE dpns DO
      { // Append a new depends on item
        LET dpnsitem = h2!dpns
        LET str = @h3!dpnsitem 
        LET len = 0
        LET dpnode = 0
        FOR i = 1 TO str%0 DO
        { LET c = str%i
          TEST c
          THEN { len := len+1
                 charv%len := c
               }
          ELSE FOR i = 1 TO tagv%0 DO
               { len := len+1
                 charv%len := tagv%i
               }
        }
        charv%0 := len
        lookupword(charv)
//writef("findrulefor: appending dpns item %s*n", charv)
        // Append depends on item
        dpnode := mk2(0, wordnode)
        !dpe := dpnode
        dpe := dpnode

        dpns := !dpns
      }

//writef("findrulefor: building new command sequence, com=%n*n", com)

      IF com DO
      { // Now build a new command sequence
        LET len = 0
        LET comstrlen = h1!com
        LET comstr    = @h2!com
        LET upb       = 0

//comstr%0 := comstrlen
//writef("findrulefor: comstrlen = %n %s tagv=%s*n", comstrlen, comstr, tagv)
//abort(1000)

        FOR i = 1 TO comstrlen DO
        { LET c = comstr%i
          TEST c
          THEN { len := len+1
                 charv%len := c
               }
          ELSE FOR i = 1 TO tagv%0 DO
               { len := len+1
                 charv%len := tagv%i
               }
        }

        // Make a command node of the form:
        //   newcom -> [len, <packed chars>]
        // Since the length may be greater than 255 it is held in newcom!0
        // not in (newcom+1)%0.
        // The packed characters are in (newcom+1)%1 ... (newcom+1)%len
        upb := 2 + len/bytesperword
        // len = 0, 1, 2, 3  =>  upb = 2
        // len = 4, 5, 6, 7  =>  upb = 3, etc
        newcom := newvec(upb)
        UNLESS com DO synerr("More space needed")
        newcom!0 := len
        (newcom+1)%0 := len
        FOR i = 1 TO len DO (newcom+1)%i := charv%i
//      writef("*nnewcom=%n allocated*n", newcom)
//abort(1001)
      }      

      // Append the corresponding rule
      //writef("Building new rule from pattern*n")


      !ruleliste := mk9(0, ln, item, newdpns, newcom,
                       -1, // state
                        0, // days  )  modification time of the subject
                        0, // msecs )
                        0) // ticks for compatibility with old dat format
      ruleliste := !ruleliste
      h2!item   := ruleliste
      RETURN
    }
    p := !p
  }

  // No pattern found
IF debug DO
  writef("Making default rule for %s*n", @h3!item)

  !ruleliste := mk9(0, 0, item, 0, 0,
                   -1, // state
                    0, // days  )  modification time of the subject
                    0, // msecs )
                    0) // ticks for compatibility with old dat format
  ruleliste := !ruleliste
  h2!item   := ruleliste
}

AND match(itemstr, subjstr, pos, chv) = VALOF
{ LET itemlen = itemstr%0
  LET subjlen = subjstr%0
  LET len = itemlen - subjlen + 1
//writef("match: itemstr=%s subjstr=%s pos=%n*n", itemstr, subjstr, pos) 
  // Is the item string long enough?
  IF len < 0 RESULTIS FALSE
//writef("match: length ok*n")
  // Check the prefix
  FOR i = 1 TO pos-1 UNLESS itemstr%i = subjstr%i RESULTIS FALSE
//writef("match: prefix ok*n")
  // Check the postfix
  FOR i = pos+1 TO subjlen UNLESS itemstr%(len+i-1) = subjstr%i RESULTIS FALSE
//writef("match: postfix ok*n")
  // The match is successful
  FOR i = 1 TO len DO chv%i := itemstr%(pos+i-1)
  chv%0 := len
//writef("match: itemstr=%s subjstr=%s pos=%n => chv=%s*n",
//        itemstr, subjstr, pos, chv) 
  RESULTIS TRUE
}

AND generate_commands(item) = VALOF
{ // Bring item up to date generating any commands that are needed
  // The result and result2 is a date stamp (days, msecs).
  // It is (0,0) if the item does not exist and has only a default rule.
  // It is (maxint, 0) if commands have been generated to create it.
  // Otherwise it is the date stamp of the file corresponding to the item.
  LET rule = h2!item
  LET state = n_state!rule
  LET com = n_com!rule
  LET p = 0
  LET days, msecs = 1, 0
  // days=1 to force an absent file to be built even when it
  // depends on no other file, as in: bmake clean

  UNLESS com | n_days!rule DO
  { fatalerr("Item %s does not exist and has no rule to build it*n", @h3!item)
    RESULTIS 0
  }

//writef("generate_commands: Item %s rule=%n com=%n*n", @h3!item, rule, com)
//abort(1000)

  IF state=1 DO
  { // item depends directly or indirectly on itself
    fatalerr("%s depends directly or indirectly on itself*n", @h3!item)
    n_state!rule := 2
    RETURN
  }
  IF state=2 DO
  { // Item is up to date
    result2 := n_msecs!rule
    RESULTIS n_days!rule
  }

  n_state!rule := 1  // Start processing this rule

  // First bring all its depends on items up to date

  p := n_dpns!rule
  WHILE p DO
  { // make a depends on item
    LET ds = generate_commands(h2!p)
    LET ms = result2
    IF ds>days | (ds=days & ms>msecs) DO days, msecs := ds, ms
    p := !p
  }

  n_state!rule := 2 

  // days,msecs is the date stamp of the most recent depends on item 

IF debug DO
{ LET out = output()
  selectoutput(sysout)
  writef("Item %s com=%n*n", @h3!item, com)
  writef("  days=%n n_days!rule=%n*n", days, n_days!rule)
  writef("  msecs=%n n_msecs!rule=%n*n", msecs, n_msecs!rule)
  TEST days>n_days!rule | (days=n_days!rule & msecs>n_msecs!rule)
  THEN writef("  and so is out of date*n")
  ELSE writef("  and so is up to date*n")
  selectoutput(out)
}
//abort(1001)

  IF days>n_days!rule | (days=n_days!rule & msecs>n_msecs!rule) DO
  { // The target is out of date so we must generate the command sequence
    LET len = h1!com
    LET comstr = @h2!com
IF debug DO
{ LET out = output()
  selectoutput(sysout)
  writef("Generating commands to build %s*n", @h3!item)
  selectoutput(out)
}
//abort(1001)
    FOR i = 1 TO len DO wrch(comstr%i)
    newline()
    // Mark the current rule as up to date
    n_days!rule, n_msecs!rule := maxint, 0
    result2 := 0
    RESULTIS maxint
  }

  // The target is already up to date

IF debug DO
{ LET out = output()
  selectoutput(sysout)
  writef("Item %s is up to date*n", @h3!item)
  selectoutput(out)
}

  result2 := n_msecs!rule
  RESULTIS n_days!rule
}

