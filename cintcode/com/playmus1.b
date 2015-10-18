/*
Still under slow (but slightly quicker) development.

This is a program intended to read a .mus representation of a score
and write a corresponding MIDI file and/or play it on a MIDI device
synchronising the accompanement with the solist, if any.


Implemented by Martin Richards (c) April 2011

Change history

25/04/11
Started implementation of new mechanism for shapes.

07/04/11
Started to implement note recognition from the microphone.

26/03/11
Started to implement keyboard commands in playmidi.

16/10/09
Changed the macrogenerator comment (%) to skip to the end of the line
and then ignore all white space characters until the next non white
space character (which may of course be a %).

08/04/09
Changed the midi data structure to be a linked list and used
mergesort to sort it.

30/03/09
Changed the macrogenerator quotes from { and } to < and > to allow
curly brackets { and } to enclose blocks in .mus files. These will
save and restore certain setting such as volume and tempo during
translation.

20/02/09
Added \pedon, \pedoff, \pedoffon, \softon, \softoff, \portaon and
\portaoff.

18/02/09
Added the :s construct into shapes. \tempo(:s4. 120) means 120 dotted
crotchets per minute which corresponds to 180 crochets per minute.

15/10/08
Began replacing calls of scan functions by suitable calls of walktree.

25/09/08
Put in the MIDI/K option to write midi files, and the PLAY/S option to
play .mus files directly.

03/06/08
Started the implementation of playmus.b
*/

SECTION "playmus"

GET "libhdr"
GET "playmus.h"

LET die() BE 
{ writef("die: calling resumeco(killco, %n)*n", currco)
  resumeco(killco, currco)
}

LET start() = VALOF
{ LET argv = VEC 50
  LET fromname = "mus/tst.mus"
  LET toname = 0
  LET midifilename = 0
  LET play = FALSE
  LET bartabcbupb,  bartabcbv  = 0, 0  // Self expanding bar table
  LET beattabcbupb, beattabcbv = 0, 0  // Self expanding beat table
  LET b   = VEC 64/bytesperword
  AND s   = VEC 10
  AND dbv = VEC 9

  writef("*nPlaymus 25/04/2011 14:50*n")

  chbuf := b
  FOR i = 0 TO 63 DO chbuf%i := 0
  chcount := 0

  strv := s         // Short term sting buffer
  debugv := dbv
  FOR i = 0 TO 9 DO debugv!i := FALSE

debugv!1 := TRUE

  bartabcb,  barmsecs  := @bartabcbupb,  0
  beattabcb, beatmsecs := @beattabcbupb, 0
  bartab, beattab := 0, 0

  soundv, soundp := 0, 0
  xvlist := 0

  killco := createco(deleteco, 500)

  errcount, errmax := 0, 5
  fin_p, fin_l := level(), fin
  rec_p, rec_l := fin_p, fin_l

  upb := 100_000    //Default work space size for bgpm.
  startbarno, endbarno := 1, maxint/2
  start_msecs, end_msecs := 0, maxint
  solochannel := 0  // No soloist yet

  sysin := input()
  sysout := output()

  base := 0              // Base of BGPM workspace
  sourcestream := 0
  getstreams := 0
  tostream := 0
  bgpmco := 0
  conductorenv := 0

  // Space for parse tree, shape data, note data, etc.
  blklist, blkb, blkp, blkt, blkitem := 0, 0, 0, 0, 0
  // Initialise the freelists
  mk1list, mk2list, mk3list, mk4list, mk5list, mk6list, mk7list :=
        0,       0,       0,       0,       0,       0,       0

  sourcefileupb := 1000
  sourcenamev := newvec(sourcefileupb)
  UNLESS sourcenamev DO
  { writef("Insufficient space available*n")
    GOTO fin
  }
  sourcefileno := 1
  FOR i = 0 TO sourcefileupb DO sourcenamev!i := "unknown"   

  // Sourcefile 1 is "built-in" and is used during initialisation.
  // Sourcefile 2 is always the FROM argument filename
  // Higher numbers are GET files
  lineno := (1<<20) + 1
  tempoadj := 1000
 
  UNLESS rdargs("FROM,START/N,END/N,TADJ/N,TO/K,UPB/K/N,*
                *PP/S,LEX/S,TREE/S,PTREE/S,NTRACE/S,MTRACE/S,*
                *MIDI/K,PLAY/S,ACC/S", argv, 50) DO
     fatalerr("Bad arguments for PLAYMUS*n")

  IF argv!0 DO fromname := argv!0       // FROM
  IF argv!1 DO startbarno := !(argv!1)  // START  -- First bar to play
  IF argv!2 DO endbarno   := !(argv!2)  // END    -- Last bar to play
  IF argv!3 DO tempoadj := !(argv!3)    // TADJ   -- Tempo adjustment
  IF argv!4 DO toname   := argv!4       // TO
  IF argv!5 DO upb := !(argv!5)         // UPB    -- BGPM space
  pptrace   := argv!6                   // PP     -- Print macrogenerated text 
  optTokens := argv!7                   // LEX    -- Trace lexical tokens
  optTree   := argv!8                   // TREE   -- Print init parse tree
  optPtree  := argv!9                   // PTREE  -- Print part trees
  optNtrace := argv!10                  // NTRACE -- Note tracing
  optMtrace := argv!11                  // MTRACE -- Midi tracing playing
  IF argv!12 DO midifilename := argv!12 // MIDI   -- Midi output filename
  play := argv!13                       // PLAY   -- Play the midi data
  accompany := argv!14                  // ACC    -- Accompany listen to the
                                        //        -- microphone and keyboard
  IF accompany DO play := TRUE

  IF upb<5000 DO upb := 5000
  base := getvec(upb)    // BGPM workspace
  UNLESS base DO
    fatalerr("Unable to allocate work space (upb = %n)*n", upb)

  sourcestream := findinput(fromname)
  sourcenamev!1 := "built-in"
  sourcenamev!2 := argv!0
  sourcefileno  := 2
  lineno := (sourcefileno<<20) + 1

  UNLESS sourcestream DO fatalerr("Unable to read file %s*n", fromname)

  tostream := sysout
  IF toname DO
  { tostream := findoutput(toname)
    UNLESS tostream DO fatalerr("Unable to write to file %s*n", argv!1)
  }

  bgpmco := createco(bgpmfn, 2000)

  UNLESS bgpmco DO fatalerr("Unable to create bgpmco*n")

  selectinput(sourcestream)
  selectoutput(tostream)

  IF pptrace DO
  { // Test the output of BGPM
    LET prevlineno = 0

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
 
  // Set the defaults so that the next note will be a
  // crotchet in octave 4 (middle C up to B).
  prevnotelength := 4
  prevoctave, prevnoteletter := 4, 'f'

  tree := formtree()              // Perform Syntax Analysis

  IF optTokens GOTO fin

  IF optTree DO { writes("*nComplete Tree*n*n")
                  prtree(tree, 0, 20)
                  newline()
                }
  
  IF errcount GOTO fin

  //writef("*nCalling trscores*n*n")
  timesiga, timesigb := 4, 4
  qbeatsperbeat := 4096/timesigb // ie 1024 for crotchet beats
  beatcount := 1
  prevbeatqbeat := 0             // No beats yet

  midilist := 0           // Initialist the list of midi items
  midiliste := @midilist  // Pointer to final link in the list
                          // used when appending midi items.

  UNLESS trscores(tree) GOTO fin

  //writef("*nUnsorted midi data*n*n")
  //prmidilist(midilist)

  midilist := mergesort(midilist)
  //writef("*nSorted midi data*n*n")
  //prmidilist(midilist)

  midilist := editnoteoffs(midilist) // Remove some note off events
  //writef("*nEdited midi data*n*n")
  //prmidilist(midilist)

  //abort(1000)

  IF midifilename DO writemidi(midifilename, midilist)

  IF play DO playmidi(midilist)

fin:
  // First free all the allocated self expanding vectors
  WHILE xvlist DO
  { writef("fin: freeing self expanding vector %n*n", xvlist!1)
    freevec(xvlist!1)
    xvlist := !xvlist
  }

writef("start: freeing killco %n*n", killco)
  IF killco DO { deleteco(killco); killco := 0 }
writef("start: freeing soundv %n*n", soundv)
  IF soundv DO { freevec(soundv);  soundv := 0 }
writef("start: freeing bgpmco %n*n", bgpmco)
  IF bgpmco DO { deleteco(bgpmco); bgpmco := 0 }
  UNLESS sourcestream=sysin DO endread()
  UNLESS tostream=sysout    DO endwrite()
  selectinput(sysin)
  selectoutput(sysout)
  IF base DO { freevec(base); base := 0 }
  WHILE blklist DO
  { LET blk = blklist
    blklist := !blk
writef("start: freeing blklist blk %n*n", blk)
    freevec(blk)
  }
writef("Quitting playmus*n")
//abort(1000)
  RESULTIS 0
}

.

/*
This section implements the macrogenerator used by playmus.
It is a modification of BGPM designed by Strachey (in 1964)

Implemented by Martin Richards (c) May 2008
*/

SECTION "bgpm"

GET "libhdr"
GET "playmus.h"

LET prlineno(ln) BE
{ LET fileno = ln>>20
  LET lno = ln & #xFFFFF
  writef(" %s[%n]", sourcenamev!fileno, lno)
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

      CASE c_call:               // '$'
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

      CASE c_apply:               // Apply (;)
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

      CASE s_lquote:                 // Left quote ('<')
           bgputch(c_lquote)
           LOOP

      CASE s_rquote:                 // Right quote ('>')
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

      CASE s_def:                    // $def!name!body...;
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

      CASE s_set:                    // $set!name!new value;
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

      CASE s_get:                    // $get!filename;
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
           // Return from $get!....;
           bg_t   := bg_p!4
           bg_e   := bg_p!3
           lineno := bg_p!2
           bg_c   := bg_p!1
           bg_p   := bg_p!0
           performget(filename)
           LOOP
         }

      CASE s_eval:                    // $eval!expression;
           bgwrnum(evalarg(1))
           GOTO ret

      CASE s_rep:                     // $rep!count!text;
         { LET a = arg(bg_p+5, 2)
           FOR k = 1 TO evalarg(1)/1000 DO
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
                             a := ((a/1000)>>(b/1000)) * 1000
                             LOOP
                           }
                 RESULTIS a

      CASE 'L':                                // L   (left shift)
      CASE 'l':  IF n<6 DO { LET b = bgexp(6)
                             a := ((a/1000)<<(b/1000)) * 1000
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
                             a := ((a/1000) & (b/1000)) * 1000
                             LOOP
                           }
                 RESULTIS a
      CASE '|':  IF n<2 DO { LET b = bgexp(2)
                             a := ((a/1000) | (b/1000)) * 1000
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
  UNLESS bg_ch='.'       RESULTIS val*1000
  bg_ch := getargch()
  UNLESS '0'<=bg_ch<='9' RESULTIS val*1000
  val := 10*val + bg_ch - '0'
  bg_ch := getargch()
  UNLESS '0'<=bg_ch<='9' RESULTIS val*100
  val := 10*val + bg_ch - '0'
  bg_ch := getargch()
  UNLESS '0'<=bg_ch<='9' RESULTIS val*10
  val := 10*val + bg_ch - '0'
  bg_ch := getargch()
  RESULTIS val
}

AND bgwrnum(n) BE
{ LET frac = ?
  IF n<0 DO { bgputch('-'); n := -n }
  frac := n MOD 1000
  wrpn(n/1000)
  IF frac = 0 RETURN
  bgputch('.')
  bgputch(frac / 100 + '0')
  frac := frac MOD 100
  IF frac = 0 RETURN
  bgputch(frac / 10 + '0')
  frac := frac MOD 10
  IF frac = 0 RETURN
  bgputch(frac + '0')
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
{ selectoutput(sysout)
  wrs("*n*n######### Error near"); prlineno(lineno); wrs(": ")
  writef(mess, a, b, c)
  selectoutput(tostream)
  error()
  selectoutput(tostream)
}

AND error(mess, a, b, c) BE
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
writef("newvec: allocation block %n upb %n*n", v, blkupb)
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
{ LET p = mk3list
  TEST p
  THEN mk3list := !p  // Use a node from the mk3 free list
  ELSE p := newvec(2) // Allocate a new node
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

AND unmk1(p) BE { !p := mk1list; mk1list := p }
AND unmk2(p) BE { !p := mk2list; mk2list := p }
AND unmk3(p) BE { !p := mk3list; mk3list := p }
AND unmk4(p) BE { !p := mk4list; mk4list := p }
AND unmk5(p) BE { !p := mk5list; mk5list := p }
AND unmk6(p) BE { !p := mk6list; mk6list := p }
AND unmk7(p) BE { !p := mk7list; mk7list := p }
.

SECTION "lex"

GET "libhdr"
GET "playmus.h"

LET rch() BE
{ ch := callco(bgpmco)
//writef("*nrch: ch=%x8*n", ch)
  UNLESS ch=endstreamch DO
  { chcount := chcount+1
    chbuf%(chcount&63) := ch
  }
}

//LET lex() BE
//{ lex1()
//  writef("lex: %s*n", opstr(token))
//}

AND lex() BE
{ LET neg = FALSE

//sawritef("lex: lineno=%n/%n ch=%n '%c'*n",
//  lineno>>20, lineno&#xFFFFF, ch, ch)

  SWITCHON ch INTO
  { DEFAULT:
      UNLESS ch=endstreamch DO
      { LET badch = ch
        ch := '*s'
        synerr("Illegal character %x2 '%c'", badch, badch)
      }
      token := s_eof
      RETURN

    CASE '*p': CASE '*n':
    CASE '*c': CASE '*t': CASE '*s':
                 rch()
                 LOOP

    CASE '-':   neg := TRUE
    CASE '+':   rch()
                UNLESS '0'<=ch<='9' DO
                  synerr("Bad number")

    CASE '0':CASE '1':CASE '2':CASE '3':CASE '4':
    CASE '5':CASE '6':CASE '7':CASE '8':CASE '9':
//sawritef("lex: case '0'-'9': reached*n")
                numval := rdnum()
                token := s_num
                IF ch='~' DO
                { token := s_numtied
                  rch()
                }
                RETURN

    CASE 'a':CASE 'b':CASE 'c':CASE 'd':CASE 'e':CASE 'f':CASE 'g':
//sawritef("lex: case 'a'-'g': reached*n")
                noteletter := ch
                notesharps :=  0  // = 0, 1, 2, -1 or -2
                reloctave  :=  0  // Octaves up
                notelength := -1  // If not specified
                dotcount   :=  0

                rch()
                IF ch='i' DO     // sharp or double sharp
                { rch()
                  UNLESS ch='s' DO synerr("Bad note")
                  rch()
                  UNLESS ch='i' DO
                  { notesharps := 1
                    GOTO rdoctave
                  }
                  rch()
                  UNLESS ch='s' DO synerr("Bad note")
                  rch()
                  notesharps := 2
                  GOTO rdoctave
                }
                IF ch='e' DO     // flat or double double
                { rch()
                  UNLESS ch='s' DO synerr("Bad note")
                  rch()
                  UNLESS ch='e' DO
                  { notesharps := -1
                    GOTO rdoctave
                  }
                  rch()
                  UNLESS ch='s' DO synerr("Bad note")
                  rch()
                  notesharps := -2
                  GOTO rdoctave
                }
rdoctave:
                IF ch='*'' | ch=',' DO
                { // octaves up or down
                  TEST ch='*''
                  THEN { reloctave := reloctave+1
                         rch()
                         UNLESS ch='*'' BREAK
                       }
                  ELSE { reloctave := reloctave-1
                         rch()
                         UNLESS ch=',' BREAK
                       }
                } REPEAT

                notelength := -1      // No explicit length yet
                WHILE '0'<=ch<='9' DO
                { IF notelength<0 DO notelength := 0
                  notelength := notelength*10 + ch - '0'
                  rch()
                }
//writef("notelength=%n*n", notelength)
                dotcount := 0
                WHILE ch='.' DO
                { dotcount := dotcount+1
                  rch()
                }
//writef("dotcount=%n*n", dotcount)

                token := s_note
                IF ch='~' DO
                { token := s_notetied
                  rch()
                }
                RETURN

    CASE 'r':  token := s_rest
               GOTO rdlength

    CASE 's':  token := s_space
rdlength:
               rch()
               notelength, dotcount := -1, 0

               WHILE '0'<=ch<='9' DO
               { IF notelength<0 DO notelength := 0
                 notelength := notelength*10 + ch - '0'
                 rch()
               }
//writef("notelength=%n*n", notelength)
               dotcount := 0
               WHILE ch='.' DO
               { dotcount := dotcount+1
                 rch()
               }
//writef("dotcount=%n*n", dotcount)
               RETURN

    CASE 'z':  token := s_null         // A zero length space
               BREAK

    CASE '\': rch()
              token := lookupword(rdtag())
//sawritef("case '\': token=%s*n", opstr(token))
              RETURN
 
    CASE '[': token := s_lsquare;   BREAK
    CASE ']': token := s_rsquare;   BREAK
    CASE '(': token := s_lparen;    BREAK
    CASE ')': token := s_rparen;    BREAK 
    CASE '{': token := s_lcurly;    BREAK
    CASE '}': token := s_rcurly;    BREAK 
    CASE ':': token := s_colon;     BREAK

    CASE '|': rch()
              IF ch='|' DO { token := s_doublebar; BREAK }
              token := s_barline
              RETURN
 
    CASE '/':   rch()
                IF ch='/' DO
                { rch() REPEATUNTIL ch='*n' | ch=endstreamch
                  LOOP
                }

                IF ch='**' DO
                { LET depth = 1

                  { rch()
                    IF ch='**' DO
                    { rch() REPEATWHILE ch='**'
                      IF ch='/' DO { depth := depth-1; LOOP }
                    }
                    IF ch='/' DO
                    { rch()
                      IF ch='**' DO { depth := depth+1; LOOP }
                    }
                    IF ch=endstreamch DO synerr("Missing '**/'")
                  } REPEATUNTIL depth=0

                  rch()
                  LOOP
                }

                synerr("Bad comment")
                RETURN
 
 
    CASE '"':
              { LET len = 0
                LET ln = lineno
                rch()
 
                UNTIL ch='"' DO
                { IF len=255 DO synerr("Bad string constant")
                  len := len + 1
                  charv%len := rdstrch()
                }
 
                charv%0 := len
                stringval := newvec(len/bytesperword)
                FOR i = 0 TO len DO stringval%i := charv%i
                token := s_string
//writef("string node %n for '%s' created*n", wordnode, @n_a1!wordnode) 
                BREAK
              }
 
  } REPEAT
 
  rch()
}
 
AND rdnum() = VALOF
{ // Only used in lex
  LET val = 0

  WHILE '0'<=ch<='9' DO { val := 10*val + ch - '0'
                          rch()
                        }
  UNLESS ch='.'       RESULTIS val*1000
  rch()
  UNLESS '0'<=ch<='9' RESULTIS val*1000
  val := 10*val + ch - '0'
  rch()
  UNLESS '0'<=ch<='9' RESULTIS val*100
  val := 10*val + ch - '0'
  rch()
  UNLESS '0'<=ch<='9' RESULTIS val*10
  val := 10*val + ch - '0'
  rch()
  RESULTIS val
}


LET lookupword(word) = VALOF
{ LET len, i = word%0, 0
  LET hashval = len
  FOR i = 1 TO len DO hashval := (13*hashval + word%i) & #xFF_FFFF
  hashval := hashval REM nametablesize
  wordnode := nametable!hashval
 
  WHILE wordnode & i<=len TEST (@h3!wordnode)%i=word%i
                          THEN i := i+1
                          ELSE wordnode, i := !wordnode, 0
  UNLESS wordnode DO
  { wordnode := newvec(len/bytesperword+3)
    !wordnode := nametable!hashval
    h2!wordnode := s_name
    FOR i = 0 TO len DO (@h3!wordnode)%i := word%i
    nametable!hashval := wordnode
  }
  RESULTIS h2!wordnode
}
 
AND dsw(word, tok) BE { lookupword(word); h2!wordnode := tok  }
 
AND declsyswords() BE
{ dsw("altoclef", s_altoclef)
  dsw("arranger", s_arranger)
  dsw("bank", s_bank)
  dsw("barlabel", s_barlabel)
  dsw("bassclef", s_bassclef)
  dsw("conductor", s_conductor)
  dsw("control", s_control)
  dsw("composer", s_composer)
  dsw("delay", s_delay);                  dsw("d", s_delay)
  dsw("delayadj", s_delayadj);            dsw("da", s_delayadj)
  dsw("instrument", s_instrument)
  dsw("instrumentname", s_instrumentname)
  dsw("instrumentshortname", s_instrumentshortname)
  dsw("interval", s_interval)
  dsw("keysig", s_keysig)
  dsw("legato", s_legato);                dsw("l", s_legato)
  dsw("legatoadj", s_legatoadj);          dsw("la", s_legatoadj)
  dsw("major", s_major)
  dsw("minor", s_minor)
  dsw("name", s_name)
  dsw("opus", s_opus)
  dsw("part", s_part)
  dsw("partlabel", s_partlabel)
  dsw("patch", s_patch)
  dsw("pedoff", s_pedoff)
  dsw("pedoffon", s_pedoffon)
  dsw("pedon", s_pedon)
  dsw("portaoff", s_portaoff)
  dsw("portaon", s_portaon)
  dsw("repeatback", s_repeatback)
  dsw("repeatbackforward", s_repeatbackforward)
  dsw("repeatforward", s_repeatforward)
  dsw("score", s_score)
  dsw("softoff", s_softoff)
  dsw("softon", s_softon)
  dsw("solo", s_solo)
  dsw("tempo", s_tempo);                  dsw("t", s_tempo)
  dsw("tempoadj", s_tempoadj);            dsw("ta", s_tempoadj)
  dsw("tenorclef", s_tenorclef)
  dsw("timesig", s_timesig)
  dsw("title", s_title)
  dsw("transpose", s_transpose)
  dsw("transposition", s_transposition)
  dsw("trebleclef", s_trebleclef)
  dsw("tuplet", s_tuplet);                dsw("tup", s_tuplet)
  dsw("vol", s_vol);                      dsw("v", s_vol)
  dsw("voladj", s_voladj);                dsw("va", s_voladj)
} 
 
AND wrchbuf() BE
{ writes("*n...")
  FOR p = chcount-63 TO chcount DO
  { LET k = chbuf%(p&63)
    IF 0<k<255 DO wrch(k)
  }
  newline()
}

AND rdtag() = VALOF
{ LET len = 0
  WHILE 'a'<=ch<='z' | 'A'<=ch<='Z' | '0'<=ch<='9' |  ch='_' DO
  { len := len+1
    IF len>255 DO synerr("Name too long")
    charv%len := ch
    rch()
  }
  charv%0 := len
  RESULTIS charv
}
 
AND rdstrch() = VALOF
{ LET res = ch
  IF ch='*n' | ch='*p' DO
  { 
    synerr("Unescaped newline character")
  }
  IF ch='\' DO
  { rch()
    SWITCHON ch INTO
    { DEFAULT:   synerr("Bad string or character constant")
      CASE '\': CASE '*'': CASE '"':  res := ch;   ENDCASE
      CASE 't': CASE 'T':             res := '*t'; ENDCASE
      CASE 'n': CASE 'N':             res := '*n'; ENDCASE
    }
  }
  rch()
  RESULTIS res
}

AND formtree() = VALOF
{ LET res = 0
  rec_p, rec_l := level(), recover

  charv := newvec(256/bytesperword)     
  nametable := newvec(nametablesize)
  UNLESS charv & nametable DO fatalerr("More workspace needed")
  FOR i = 0 TO nametablesize DO nametable!i := 0

  IF optTokens DO newline()

  declsyswords()
  lex()

  WHILE optTokens DO
  { writef("%t9", opstr(token))
    SWITCHON token INTO
    { DEFAULT:
         ENDCASE

      CASE s_string:
         writef(" *"%s*"", stringval)
         ENDCASE

      CASE s_num:
      CASE s_numtied:
         writef(" %8.3d", numval)
         ENDCASE

      CASE s_note:
      CASE s_notetied:
         writef("%c", capitalch(noteletter))
         IF notelength>=0 DO writef("%n", notelength)
         FOR i =  1 TO  notesharps       DO wrch('#')
         FOR i = -1 TO -notesharps BY -1 DO wrch('b')
         FOR i =  1 TO dotcount          DO wrch('.')
         ENDCASE

      CASE s_rest:
         writef("R")
         IF notelength>=0 DO writef("%n", notelength)
         FOR i = 1 TO dotcount DO wrch('.')
         ENDCASE

      CASE s_space:
         writef("S")
         IF notelength>=0 DO writef("%n", notelength)
         FOR i = 1 TO dotcount DO wrch('.')
         ENDCASE
    }

    IF token=s_eof DO
    { newline()
      BREAK
    }
    newline()
    lex()
  }


recover:
  IF optTokens RESULTIS 0

  res := rdscores()
  UNLESS token=s_eof DO fatalsynerr("Incorrect termination")
  RESULTIS res
}

AND fatalerr(mess, a, b, c) BE
{ writes("*nFatal error: ")
  writef(mess, a, b, c)
  writes("*nCompilation aborted*n")
  longjump(fin_p, fin_l)
}
 
AND fatalsynerr(mess, a) BE
{ writef("*nError near line:  "); prlineno(lineno); newline()
  writef(mess, a)
  writef("*nRecent text:*n")
  wrchbuf()
  errcount := errcount+1
  writes("*nCompilation aborted*n")
  longjump(fin_p, fin_l)
}

AND synerr(mess, a, b, c) BE
{ 
  writef("*nError near line:  "); prlineno(lineno); newline()
  writef(mess, a, b, c)
  wrchbuf()
  // Skip the rest of the input line 
  UNTIL ch='*n' | ch=endstreamch DO rch()
  lex()
  error("")
  errcount := errcount+1
  IF errcount >= errmax DO fatalerr("Too many errors")

abort(1000)
  longjump(rec_p, rec_l)
}

AND trerr(mess, a) BE
{ writef("*nError near line:  "); prlineno(lineno); newline()
  writef(mess, a)
  newline()
  errcount := errcount+1
  IF errcount >= errmax DO fatalerr("Too many errors")
}

LET checkfor(tok, mess) BE
{ UNLESS token=tok DO synerr(mess)
  lex()
}
 
LET rdscores() = VALOF
{ LET res = 0
  LET prev = 0
  LET ln = lineno

  WHILE token=s_score DO
  { LET sc = rdscore()
    TEST res THEN !prev := sc
             ELSE res := sc
    prev := sc
//writef("rdscores: res=%n prev=%n*n", res, prev)
  }

  // res is a list of scores
  UNLESS res & !res RESULTIS res
  RESULTIS mk5(0, s_seq, ln, res, -1)
}

AND rdscore() = VALOF
{ // A score contains one conductor, one or more parts
  // (some of which may be solo parts)
  // and possibly some commands.
  LET ln = lineno
  LET parln = lineno
  LET a = 0
  LET name = "Unnamed"
  LET conductor = 0  // The conductor
  LET parts = 0      // A list of parts and solos
  LET lastpart = 0
  LET oldp, oldl = rec_p, rec_l
  rec_p, rec_l := level(), scorerec

  checkfor(s_score, "\score expected")
  name := rdstring()                     // Name of this score
  parln := lineno

  // The conductor and parts of a score are performed simultaneously
  // and so are enclosed in square brackets.
  checkfor(s_lsquare, "'[' expected")
  
scorerec:
  UNTIL token=s_rsquare DO
  { // Start of loop to find score items
    LET ln = lineno
    
    SWITCHON token INTO
    { DEFAULT:
        synerr("\conductor, \solo or \part expected, token=%s", opstr(token))

      CASE s_conductor:
        lex()
        IF conductor DO synerr("Only one conductor is allowed*n")
        conductor := mk5(0, s_conductor, ln, rdnote(), 0)
        LOOP

      CASE s_part:
      CASE s_solo:
      { LET op = token
        lex()
        a := mk5(0, op, ln, rdnote(), 0)
//writef("part node %n created*n", a)
        TEST parts
        THEN !lastpart := a
        ELSE parts := a
        lastpart := a
        LOOP
      }

      CASE s_eof:
        fatalsynerr("Unexpected end of file")
    }
  }

  lex() // Skip over the righr square bracket

  rec_p, rec_l := oldp, oldl

  UNLESS conductor DO fatalsynerr("A conductor is required") 
  UNLESS parts     DO fatalsynerr("At least one part or solo is needed") 

  !conductor := parts
  RESULTIS mk6(0, s_score, ln, name,
                        mk5(0, s_par, parln, conductor, -1), 0)
}

AND rdstring() = VALOF
{ LET a = stringval
  checkfor(s_string, "String expected")
  RESULTIS a
}

AND rdnumber() = VALOF
{ LET a = numval
  checkfor(s_num, "Number expected")
  RESULTIS a
}

AND rdinteger() = VALOF
{ LET a = numval
  checkfor(s_num, "Integer expected")
  UNLESS a MOD 1000 = 0 DO synerr("%5.3d not an integer", a)
  RESULTIS a/1000
}

AND noteqbeats(len, prevlen, dotcount) = VALOF
{ // Calculate the note or rest's qbeats
  LET qlen = 0

  IF len<0 DO len := prevlen

  SWITCHON len INTO
  { DEFAULT:  synerr("Bad note length %n", len)

    CASE   0: qlen := 8192; ENDCASE
    CASE   1: qlen := 4096; ENDCASE
    CASE   2: qlen := 2048; ENDCASE
    CASE   4: qlen := 1024; ENDCASE
    CASE   8: qlen :=  512; ENDCASE
    CASE  16: qlen :=  256; ENDCASE
    CASE  32: qlen :=  128; ENDCASE
    CASE  64: qlen :=   64; ENDCASE
    CASE 128: qlen :=   32; ENDCASE
  }

  { LET q = qlen
    FOR i = 1 TO dotcount DO
    { q := q/2
      qlen := qlen + q
    }
  }
//writef("qlen=%n*n", qlen)
  RESULTIS qlen
}

AND rdnoteprim() = VALOF
{ LET op, ln = token, lineno
  LET a, b = 0, 0

  SWITCHON op INTO
  { DEFAULT:
      synerr("Bad item in note list: token=%s", opstr(op))
      RESULTIS 0

    CASE s_num:
      // A octave number
      //writef("rdnoteprim: numval= %9.3d*n", numval)
      prevoctave := numval / 1000
      prevnoteletter := 'f'
      UNLESS 0<=prevoctave<=9 & numval MOD 1000 = 0 DO
        synerr("Bad octave number %4.3d", numval)
      lex()
      LOOP

    CASE s_lparen:
      lex()
      a := rdnotes()
      checkfor(s_rparen, "Syntax error in ( ... ) construct")
      a := mk5(0, s_seq, ln, a, -1)
//      writef("seq node created %n*n", a)
      RESULTIS a

    CASE s_lcurly:
      lex()
      a := rdnotes()
      checkfor(s_rcurly, "Syntax error in { ... } construct")
      a := mk5(0, s_block, ln, a, -1)
      writef("block node created %n*n", a)
      RESULTIS a

    CASE s_lsquare:
      lex()
      a := rdnotes()
      checkfor(s_rsquare, "Syntax error in [ ... ] construct")
      a := mk5(0, s_par, ln, a, -1)
//      writef("par node created %n*n", a)
      RESULTIS a

    CASE s_note:
    CASE s_notetied:
    { // Calculate the note number
      LET tab1 = TABLE // Octave number change table
                 //  A  B  C  D  E  F  G        -- previous note
                     0, 0,-1,-1, 0, 0, 0,  // A -- new notes
                     0, 0,-1,-1,-1, 0, 0,  // B
                     1, 1, 0, 0, 0, 0, 1,  // C
                     1, 1, 0, 0, 0, 0, 0,  // D
                     0, 1, 0, 0, 0, 0, 0,  // E
                     0, 0, 0, 0, 0, 0, 0,  // F
                     0, 0,-1, 0, 0, 0, 0   // G
      LET tab2 = TABLE // Semitones away from C in same C-B octave
                 //  A  B  C  D  E  F  G
                     9,11, 0, 2, 4, 5, 7
      LET i = noteletter-'a'
      LET j = prevnoteletter-'a'
      prevnoteletter := noteletter

      // Deal with the octave correction

      prevoctave := prevoctave + reloctave
      prevoctave := prevoctave + tab1!(7*i + j)

      // Calculate the midi note number
      notenumber := (prevoctave+1)*12 + tab2!i + notesharps
//writef("notenumber=%n*n", notenumber)

      UNLESS 0<=notenumber<=127 DO
        synerr("Note %n out of range", notenumber)

      a := mk5(0, op, ln,
               noteletter<<16 | (notesharps&255)<<8 | notenumber,
               noteqbeats(notelength, prevnotelength, dotcount))
      IF notelength>=0 DO prevnotelength := notelength
      lex()
      RESULTIS a
    }

    CASE s_rest:
    CASE s_space:
      a := mk4(0, op, ln, noteqbeats(notelength, prevnotelength, dotcount))
//writef("rest/space qlen=%n*n", h4!a) 
      IF notelength>=0 DO prevnotelength := notelength
      lex()
      RESULTIS a

    CASE s_null: // z -- a zero length rest
      a := mk4(0, op, ln, 0)
//writef("rest/space/null qlen=%n*n", h4!a) 
      lex()
      RESULTIS a

    CASE s_barline:
    CASE s_doublebar:
    CASE s_repeatback:
    CASE s_repeatforward:
    CASE s_repeatbackforward:
    CASE s_trebleclef:
    CASE s_altoclef:
    CASE s_tenorclef:
    CASE s_bassclef:
      a := mk3(0, op, ln)
      lex()
      RESULTIS a

    CASE s_control: // \control(<int> <int>)
                    // Corresponds to Midi: Bn <controller no> <val>
    CASE s_timesig: // \timesig(<int> <int>) eg \timesig(6 8)
      lex()
      checkfor(s_lparen, "'(' expected")
      a := rdinteger()
      b := rdinteger()
      checkfor(s_rparen, "')' expected")
      RESULTIS mk5(0, op, ln, a, b)

    CASE s_bank:
      lex()
      checkfor(s_lparen, "'(' expected")
      a := rdnumber()
      b := rdnumber()
      checkfor(s_rparen, "')' expected")
      UNLESS a MOD 1000 = 0 & b MOD 1000 = 0 DO
        synerr("Bad bank numbers")
      RESULTIS mk5(0, op, ln, a/1000, b/1000)

    CASE s_patch:
      lex()
      checkfor(s_lparen, "'(' expected")
      a := rdnumber()
      checkfor(s_rparen, "')' expected")
      UNLESS a MOD 1000 = 0 DO
        synerr("Bad patch number")
      RESULTIS mk4(0, op, ln, a/1000)

    CASE s_keysig:
    { LET plet, poct, plen = prevnoteletter, prevoctave, prevnotelength
      lex()
      checkfor(s_lparen, "'(' expected")
      a := rdnoteprim()
      UNLESS n_op!a=s_note DO synerr("Note expected")
      UNLESS token=s_major | token=s_minor DO
        synerr("\major or \minor expected")
      a := mk5(0, op, ln, a, token)
      lex()
      prevnoteletter, prevoctave, prevnotelength := plet, poct, plen
      checkfor(s_rparen, "')' expected")
      RESULTIS a
    }

    CASE s_transpose:
      lex()
      checkfor(s_lparen, "'(' expected")
      a := rdnoteprim()
      UNLESS n_op!a=s_note DO synerr("Note expected")
      b := rdnoteprim()
      UNLESS n_op!b=s_note DO synerr("Note expected")
      checkfor(s_rparen, "')' expected")
      RESULTIS mk5(0, op, ln, a, b)

    CASE s_transposition:
    { // Written C should sound as
      LET plet, poct, plen = prevnoteletter, prevoctave, prevnotelength
      LET semitones = 0
      lex()
      checkfor(s_lparen, "'(' expected")
      UNLESS token=s_note DO synerr("Note expected")
      //    note => semitones up

      // c'      12        c       0
      // b'      11        b      -1
      // bes'    10        bes    -2
      // a'       9        a      -3
      // aes'     8        aes    -4
      // g'       7        g      -5
      // ges'     6        ges    -6
      // f        5        f,     -7
      // e        4        e,     -8
      // ees      3        ees,   -9
      // d        2        d,    -10
      // des      1        des,  -11
      // c        0        c,    -12

      //                                   A  B  C  D  E  F  G
      semitones := (noteletter-'a')!TABLE -3,-1, 0, 2, 4, 5,-5

      // Deal with the accidentals, if any
      UNLESS -1<=notesharps<=1 DO synerr("Too many accidentals")
      semitones := semitones + notesharps 

      // Correct the octave
      semitones := semitones + 12*reloctave 

      //writef("transposition: %c sharps=%n reloctave=%n => semitones=%n*n",
      //        noteletter, notesharps, reloctave, semitones)
      a := mk4(0, op, ln, semitones)
      lex()
      checkfor(s_rparen, "')' expected, token=%s", opstr(token))
      prevnoteletter, prevoctave, prevnotelength := plet, poct, plen
      RESULTIS a
    }

    CASE s_pedoff:
    CASE s_pedoffon:
    CASE s_pedon:
    CASE s_portaoff:
    CASE s_portaon:
    CASE s_softoff:
    CASE s_softon:
      lex()
      RESULTIS mk3(0, op, ln)

    CASE s_name:
    CASE s_instrumentname:
    CASE s_instrumentshortname:
    CASE s_instrument:
    CASE s_partlabel:
    CASE s_barlabel:
    CASE s_title:
    CASE s_composer:
    CASE s_arranger:
    CASE s_opus:
//writef("rdnoteprim: token=%s*n", opstr(op))
      lex()
      RESULTIS mk4(0, op, ln, rdstring())
  }
} REPEAT

AND rdnote() = VALOF
{ LET op, ln = ?, ?
  LET opname = ?
  LET a, b = rdnoteprim(), 0

sw:
  op, ln := token, lineno
  opname := opstr(op)
  SWITCHON token INTO
  { DEFAULT:
      RESULTIS a

    // Infixed operators with a shape as second operand.
    CASE s_vol:
    CASE s_voladj:
    CASE s_tempo:
    CASE s_tempoadj:
    CASE s_legato:
    CASE s_legatoadj:
    CASE s_delay:
    CASE s_delayadj:
      lex()
      a := mk6(0, op, ln, a, rdshape(1024), FALSE)
      GOTO sw

    // Infixed operators with a note(s) as second operand.
    CASE s_tuplet:
      lex()
      a := mk5(0, op, ln, a, rdnote())
      GOTO sw
  }

  RESULTIS 0
}

AND rdnotes(n) = VALOF
// This returns a list of note items linked though the
// next (=h1) field. Such a list will always be an operand
// of seq, block or par construct.
{ LET res = 0
  LET lastitem = 0
  LET op, ln = token, lineno
  // Setup new recovery point
  LET oldp, oldl = rec_p, rec_l
  rec_p, rec_l := level(), sw

sw:
//writef("*nrdnotes: token=%s*n", opstr(token))
  SWITCHON token INTO
  { DEFAULT:
      rec_p, rec_l := oldp, oldl
      RESULTIS res

    // All the tokens that can start a note item
    CASE s_altoclef:
    CASE s_arranger:
    CASE s_bank:
    CASE s_barlabel:
    CASE s_barline:
    CASE s_bassclef:
    CASE s_composer:
    CASE s_control:
    CASE s_doublebar:
    CASE s_instrument:
    CASE s_instrumentname:
    CASE s_instrumentshortname:
    CASE s_keysig:
    CASE s_lparen:
    CASE s_lcurly:
    CASE s_lsquare:
    CASE s_name:
    CASE s_note:
    CASE s_notetied:
    CASE s_null:
    CASE s_num:
    CASE s_opus:
    CASE s_partlabel:
    CASE s_patch:
    CASE s_pedoff:
    CASE s_pedoffon:
    CASE s_pedon:
    CASE s_portaoff:
    CASE s_portaon:
    CASE s_repeatback:
    CASE s_repeatbackforward:
    CASE s_repeatforward:
    CASE s_rest:
    CASE s_softoff:
    CASE s_softon:
    CASE s_space:
    CASE s_tenorclef:
    CASE s_timesig:
    CASE s_title:
    CASE s_transpose:
    CASE s_transposition:
    CASE s_trebleclef:
    { LET a = rdnote()
      TEST res
      THEN !lastitem := a
      ELSE res := a
      lastitem := a
      GOTO sw
    }
  }
}

AND rdshape(qlen) = VALOF
// This returns a seq node whose operand is a list of shape items
// linked though the next (=h1) field.
// Shape values are scaled by qlen/1024. So, for instance,
// if qlen=512 (corresponding to a quaver), a tempo value of
// 120 would be halved giving a rate of 60 crotchets per minute.
// qlen can be changed within a shape sequence by items such as
// :512 or :s8
// The main purpose of scaling is to allow for instance dotted
// quaver = 138 to be specified by \tempo(:s8. 128). It is typically
// not used with any of the other shape operators.
// Syntactically a shape is either a possibly tied number or a sequence
// of shape items enclosed in parentheses. A shape item is either
// a possibly tied number, a space item (such as s4.) or
// a colon item (such as :512 or s8.).
{ LET list = 0
  LET lastitem = 0
  LET item = 0
  LET ln = lineno
  LET plen = prevnotelength
  prevnotelength := 4  // Assume the prev note length was 4 (a crotchet)

  IF token=s_num | token=s_numtied DO
  { numval := muldiv(qlen, numval, 1024)
    item := mk4(0, token, lineno, numval)
//writef("rdshape: %s=%9.3d*n", opstr(token), numval)
    TEST list
    THEN !lastitem := item
    ELSE list := item
    lastitem := item
    GOTO ret
  }

  checkfor(s_lparen, "A shape must start with '(' or a number")

  UNTIL token=s_rparen SWITCHON token INTO
  { DEFAULT:
      synerr("Bad item in shape list: %s", opstr(token))
      BREAK

    CASE s_space:
    { LET len = noteqbeats(notelength, prevnotelength, dotcount)
      item := mk4(0, s_space, lineno, len)
//writef("rdshape: space qlen=%n*n", h4!item)
      IF notelength>=0 DO prevnotelength := notelength
      lex()
      GOTO append
    }

    CASE s_colon:
      lex()
      IF token=s_space DO
      { qlen := noteqbeats(notelength, 4, dotcount)
//writef("rdshape: rest/space qlen=%n*n", qlen) 
        lex()
        LOOP
      }

      IF token=s_num DO
      { qlen := numval/1000
//writef("rdshape: qlen=%n*n", qlen) 
        lex()
        LOOP
      }

      synerr("'s' or number expected after ':' in shape list")
      LOOP


    CASE s_num:
    CASE s_numtied:
      numval := muldiv(qlen, numval, 1024)
      item := mk4(0, token, lineno, numval)
//writef("rdshape: %s=%9.3d*n", opstr(token), numval)
      lex()

append:
      TEST list
      THEN !lastitem := item
      ELSE list := item
      lastitem := item
      LOOP
  }

ret:
  lex()
  prevnotelength := plen
  RESULTIS mk5(0, s_seq, ln, list, -1)
}



LET opstr(op) = VALOF SWITCHON op INTO
{ DEFAULT:        sawritef("opstr: System error, op %n*n", op)
abort(1000)
                  RESULTIS "Unknown"

  CASE s_altoclef:            RESULTIS "Altoclef"
  CASE s_arranger:            RESULTIS "Arranger"
  CASE s_bank:                RESULTIS "Bank"
  CASE s_barlabel:            RESULTIS "Barlabel"
  CASE s_barline:             RESULTIS "Barline"
  CASE s_bassclef:            RESULTIS "Bassclef"
  CASE s_block:               RESULTIS "Block"
  CASE s_colon:               RESULTIS "Colon"
  CASE s_composer:            RESULTIS "Composer"
  CASE s_conductor:           RESULTIS "Conductor"
  CASE s_control:             RESULTIS "Control"
  CASE s_delay:               RESULTIS "Delay"
  CASE s_doublebar:           RESULTIS "Doublebar"
  CASE s_eof:                 RESULTIS "Eof"
  CASE s_instrument:          RESULTIS "Instrument"
  CASE s_instrumentname:      RESULTIS "Instrumentname"
  CASE s_instrumentshortname: RESULTIS "Instrumentshortname"
  CASE s_interval:            RESULTIS "Interval"
  CASE s_keysig:              RESULTIS "Keysig"
  CASE s_lcurly:              RESULTIS "Lcurly"
  CASE s_legato:              RESULTIS "Legato"
  CASE s_legatoadj:           RESULTIS "Legatoadj"
  CASE s_lparen:              RESULTIS "Lparen"
  CASE s_lsquare:             RESULTIS "Lsquare"
  CASE s_major:               RESULTIS "Major"
  CASE s_minor:               RESULTIS "Minor"
  CASE s_name:                RESULTIS "Name"
  CASE s_neg:                 RESULTIS "Neg"
  CASE s_note:                RESULTIS "Note"
  CASE s_notetied:            RESULTIS "Notetied"
  CASE s_null:                RESULTIS "Null"
  CASE s_num:                 RESULTIS "Num"
  CASE s_numtied:             RESULTIS "Numtied"
  CASE s_opus:                RESULTIS "Opus"
  CASE s_par:                 RESULTIS "Par"
  CASE s_part:                RESULTIS "Part"
  CASE s_partlabel:           RESULTIS "Partlabel"
  CASE s_patch:               RESULTIS "Patch"
  CASE s_pedoff:              RESULTIS "Pedoff"
  CASE s_pedoffon:            RESULTIS "Pedoffon"
  CASE s_pedon:               RESULTIS "Pedon"
  CASE s_portaon:             RESULTIS "Portaon"
  CASE s_portaoff:            RESULTIS "Portaoff"
  CASE s_rcurly:              RESULTIS "Rcurly"
  CASE s_repeatback:          RESULTIS "Repeatback"
  CASE s_repeatbackforward:   RESULTIS "Repeatbackforward"
  CASE s_repeatforward:       RESULTIS "Repeatforward"
  CASE s_rest:                RESULTIS "Rest"
  CASE s_rparen:              RESULTIS "Rparen"
  CASE s_rsquare:             RESULTIS "Rquare"
  CASE s_score:               RESULTIS "Score"
  CASE s_seq:                 RESULTIS "Seq"
  CASE s_solo:                RESULTIS "Solo"
  CASE s_space:               RESULTIS "Space" 
  CASE s_string:              RESULTIS "String"
  CASE s_softon:              RESULTIS "Softon"
  CASE s_softoff:             RESULTIS "Softoff"
  CASE s_tempo:               RESULTIS "Tempo"
  CASE s_tempoadj:            RESULTIS "Tempoadj"
  CASE s_tenorclef:           RESULTIS "Tenorclef"
  CASE s_timesig:             RESULTIS "Timesig"
  CASE s_title:               RESULTIS "Title"
  CASE s_transpose:           RESULTIS "Transpose"
  CASE s_transposition:       RESULTIS "Transposition"
  CASE s_trebleclef:          RESULTIS "Trebleclef"
  CASE s_tuplet:              RESULTIS "Tuplet"
  CASE s_vol:                 RESULTIS "Vol"
  CASE s_voladj:              RESULTIS "Voladj"

  CASE w_barscan:             RESULTIS "Barscan"
  CASE w_length:              RESULTIS "Length"
  CASE w_genmidi:             RESULTIS "Genmidi"
}

AND prnote(letter, sharps, note, qbeats) BE
{ LET n = sharps&255
  LET ch = '#'
  IF n>128 DO n, ch := 256-n, 'b'

  IF note>=12 DO writef("%n", note/12-1)
  wrch(letter+'A'-'a')
//writef(" sharps=%n ", sharps)
  FOR i = 1 TO n DO wrch(ch)
  FOR i = n TO 1 DO wrch(' ')
  wrch(' ')
  UNLESS qbeats<0 DO
  { IF note DO writef("%n:", note)
    writef("%i4", qbeats)
  }
}

LET prtree(x, n, d) BE
{ // This prints the abstract syntax tree of a MUS score
  // x is either zero or points to a node [next, op, ln, ...]
  // op is the node operator, eg s_seq, s_note etc.
  // next is a link to the next node in a list. It is not "owned"
  //      by the node but by the head node of the list, typically
  //      having operator s_seq, s_block or s_par.
  // ln is the line/file number for the node.
  // The other fields are node dependent.
  LET v = TABLE 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
  LET op, ln, a1, a2 = ?, ?, ?, ?
  LET opname = ?

writef("%n: ", x)
  IF n>=d DO { writes("Etc"); RETURN  }
  IF x=0  DO { writes("Nil"); RETURN  }

  op, ln, a1, a2 := n_op!x, n_ln!x, n_a1!x, n_a2!x
  opname := opstr(op)

  SWITCHON op INTO
  { DEFAULT:
         writef("%s --", opname); prlineno(ln)
         ENDCASE

    CASE s_num:     writef("%t8 %0.3d", opname, a1);  RETURN
    CASE s_numtied: writef("%t8 %0.3d~", opname, a1); RETURN

    CASE s_note:     // x -> [-, note,     ln, <letter,sharps,noteno>, qlen]
    CASE s_notetied: // x -> [-, notetied, ln, <letter,sharps,noteno>, qlen]
    { LET letter =   a1>>16
      LET sharps =  (a1>>8) & 255
      LET n      =   a1 & 255      // MIDI number
      LET qbeats =   a2            // Note qbeats (crochet = 1024)
      writef("%t8 ", opname)
      prnote(letter, sharps, n, qbeats)
      RETURN
    }

    CASE s_rest:    // x -> [-, rest,  ln, qlen]
    CASE s_space:   // x -> [-, space, ln, qlen]
    { LET qbeats = a1
      writef("%t7  ", opname)
      prnote((op=s_rest -> 'r', 's'), 0, 0, qbeats)
      RETURN
    }

    CASE s_null:   // x -> [-, null, ln]
      writef("%s --", opname); prlineno(ln)
      RETURN

    CASE s_control:       writef("Control (%n %n)", a1, a2);  RETURN
    CASE s_timesig:       writef("Timesig (%n %n)", a1, a2);  RETURN

    CASE s_bank:          writef("Bank (%n %n)", a1, a2);  RETURN

    CASE s_patch:         writef("Patch (%n)", a1);  RETURN

    CASE s_transposition: writef("Transposition (%n)", a1); RETURN

    CASE s_keysig:
      // x -> [-, keysig, ln, [-, note, ln, <letter, sharps, noteno], mode]
      writef("Keysig (")
      prnote(h4!a1>>16, (h4!a1>>8) & 255, 0, -1)
      TEST a2=s_major THEN writes(" Major)")
                      ELSE writes(" Minor)")
      RETURN

    // Operator with a string argument
    CASE s_title:
    CASE s_composer:
    CASE s_arranger:
    CASE s_opus:
    CASE s_instrument:
    CASE s_name:
    CASE s_instrumentname:
    CASE s_instrumentshortname:
    CASE s_barlabel:
    CASE s_partlabel:
      writef("%t7 *"%s*"  --", opname, a1); prlineno(ln)
      RETURN

    CASE s_seq:       // x -> [-, seq,   ln, list, qlen]
    CASE s_par:       // x -> [-, par,   ln, list, qlen]
    CASE s_block:     // x -> [-, block, ln, list, qlen]
      writef("%s qlen=%n --", opname, h5!x); prlineno(ln)

      WHILE a1 DO
      { newline()
        FOR j=0 TO n-1 DO writes( v!j )
        writes("**-")
        v!n := !a1 ->"! ","  "
        prtree(a1, n+1, d)
        a1 := !a1
      }
      RETURN

    // Monadic operators
    CASE s_conductor: // x -> [-, Conductor, ln, part,  env]
    CASE s_part:      // x -> [-, Part,      ln, part,  env]
    CASE s_solo:      // x -> [-, Solo,      ln, part,  env]
      writef("%s --", opname); prlineno(ln)
      // Print each item in the list
      newline()
      FOR j=0 TO n-1 DO writes( v!j )
      writes("**-")
      v!n := "  "
      prtree(a1, n+1, d)      
      RETURN

    // Treat score as a dyadic operator
    CASE s_score:     // x -> [-, Score, ln, name, parts, env]
      writef("%s *"%s*" --", opname, a1); prlineno(ln)
      newline()
      FOR j = 0 TO n-1 DO writes( v!j )
      writes("**-")
      v!n := "  "
      prtree(a2, n+1, d)
      RETURN       

    // Dyadic shape operators, typically
    // x -> [-, op, ln, notes, shape, flag]
    // flag=TRUE is the shape sequence has already been processed
    // flag is initially FALSE.
    CASE s_vol:
    CASE s_voladj:
    CASE s_tempo:
    CASE s_tempoadj:
    CASE s_legato:
    CASE s_legatoadj:
    CASE s_delay:
    CASE s_delayadj:
      writef("%s flag=%n --", opname, h6!x); prlineno(ln)
      newline()
      FOR j = 0 TO n-1 DO writes( v!j )
      writes("**-")
      v!n := "! "
      prtree(a1, n+1, d)
      newline()
      FOR j = 0 TO n-1 DO writes( v!j )
      writes("**-")
      v!n := "  "
      prtree(a2, n+1, d)
      RETURN       

    CASE s_tuplet:
    // Dyadic tuplet operator, x -> [-, op, ln, notes, notes]
      writef("%s --", opname); prlineno(ln)
      newline()
      FOR j = 0 TO n-1 DO writes( v!j )
      writes("**-")
      v!n := "! "
      prtree(a1, n+1, d)
      newline()
      FOR j = 0 TO n-1 DO writes( v!j )
      writes("**-")
      v!n := "  "
      prtree(a2, n+1, d)
      RETURN       
  }
}

.

GET "libhdr"
GET "playmus.h"

LET trscores(x) = VALOF IF x SWITCHON n_op!x INTO
{ // Return TRUE if successful
  DEFAULT:
    trerr("Bad Mus tree")
    RESULTIS FALSE

  CASE s_seq:       // Sequence of scores
  { LET a = n_a1!x
    WHILE a DO
    { UNLESS trscore(a) RESULTIS FALSE
      a := !a
    }
    RESULTIS TRUE
  }

  CASE s_score:     // A score
    RESULTIS trscore(x)
}

AND trscore(x) = VALOF
{ // Append the midi items corresponding to score x onto the
  // end of midilist. (midiliste is zero or points to its last link).
  // x -> [-, Score, ln, name, body]
  LET name = ?
  LET body = ?
  LET conductor = 0
  LET part = 0
  LET qlen = 0
  LET midichannel = 0 // No Midi channel used yet

  UNLESS x RESULTIS FALSE

  name := n_a1!x
  body := n_a2!x

  conductorenv := 0

  UNLESS n_op!x=s_score & n_op!body=s_par DO
  { trerr("Bad score")
    RESULTIS FALSE
  }

  writef("*nTranslating score: *"%s*"*n", name)

  conductor := n_a1!body
  UNLESS conductor DO
  { trerr("No conductor")
    RESULTIS FALSE
  }

  part := !conductor
  UNLESS part DO
  { trerr("No parts")
    RESULTIS FALSE
  }

sawritef("Calling prescan of conductor*n")
walktree(conductor, 0, w_prescan, 0, 0, 0)

sawritef("Calling performbarscan of conductor*n")
//abort(1001)
  ////performbarscan(conductor, conductorenv, TRUE) // TRUE = conductor part
  pushval(bartabcb, 0) // Bar 1 starts at qbeat 0
writef("Calling walktree*n")
  maxqbeat := walktree(conductor, 0, w_barscan, bartabcb, 0, 0)

  bartab := bartabcb!1 // bartab -> [n, q1,...,qn]
                       // where n is the maximum bar number
                       // and qi is the qbeat value at the start of bar i
  maxbarno := bartab!0
  // Insert the self expanding vector at the head of xvlist
  xvlist := mk2(xvlist, bartab)

  //IF FALSE DO
  { TEST bartab
    THEN { writef("*nBar table upb=%n*n*n", maxbarno)
abort(1000)
           FOR i = 1 TO maxbarno DO
           { writef(" %i5:%i8", i, bartab!i)
             IF i MOD 5 = 0 DO newline()
           }
           newline()
         }
    ELSE writef("No bar table*n")
abort(1001)
  }

  IF FALSE DO
  { TEST beattabcb!0
    THEN { writef("*nBeat table upb=%n*n*n", beattabcb!1!0)
//abort(1000)
           FOR i = 1 TO beattabcb!1!0 DO
           { writef(" %i5:%i8", i, beattabcb!1!i)
             IF i MOD 5 = 0 DO newline()
           }
           newline()
         }
    ELSE writef("No beat table*n")
//abort(1001)
  }

RESULTIS TRUE

  IF optPtree DO { writes("*nConductor Tree*n*n")
                   prtree(conductor, 0, 20)
                   newline()
                 }

sawritef("Performing tempo scan of conductor*n")
  performshapescan(conductor, conductorenv, s_tempo, e_tempo, 120_000)

  tempodata := e_tempo!conductorenv

  IF FALSE DO
  { writef("*nTempo data*n")
    FOR i = 1 TO tempodata!0-1 BY 2 DO
    { IF i MOD 10 = 1 DO newline()
      writef(" %i5:%8.3d", tempodata!i, tempodata!(i+1))
    }
    newline()
    newline()
  }

  writef("Conductor bars   = %i7*n", e_maxbarno!conductorenv)
  writef("Conductor qbeats = %i7*n", e_qbeats!conductorenv)

  { // Calculate the qbeat to msecs mapping
    
    LET qtimevupb = e_qbeats!conductorenv/256
    LET qtimev = getvec(qtimevupb)
    // qtimev is a mapping vector giving the start time in msecs
    // of each semiquaver in the score based on tempodata.
    LET msecs = 0  // Start time of semiquaver 0

    FOR i = 0 TO qtimevupb DO
    { // A semiquaver has 1024/4 = 256 qbeats
      // At tempo  60.000 256 qbeats take  250 msecs
      // At tempo 120.000 256 qbeats take 125.5 msecs
      // At tempo   t     256 qbeats take 60*250/t = 15000/t msecs
      LET qbeat = i*256
      LET tempo = interpolate(tempodata, qbeat)
      LET rate = muldiv(15000, 1000, tempo)
//      writef("%i4: msecs=%i7   tempo=%9.3d %i4 msecs per semiquaver*n",
//              i, msecs, tempo, rate) 
      qtimev!i := msecs
      msecs := msecs + rate
    }
    e_qtimev   !conductorenv := qtimev
    e_qtimevupb!conductorenv := qtimevupb
    
    start_msecs := barno2msecs(startbarno, conductorenv) - 0_100
    end_msecs   := barno2msecs(endbarno+1, conductorenv)

    writef("Playing from %1.3d to %1.3d secs*n", start_msecs, end_msecs)

    // Test qbeats2msecs
    IF FALSE DO
    { writef("qbeats to msecs, qtimevupb=%n",qtimevupb)
      FOR q = 0 TO qtimevupb*256 DO
      { IF q MOD 256 = 0 DO newline()
        IF q MOD 8 = 0 DO writef("*n%i6:", q)
        writef(" %8.3d", qbeats2msecs(q, conductorenv))
      }
      newline()
    }

    // Set elements of barmsecs
    //writef("Allocating barmsecs maxbar number is %n*n", conductor_bartab!0)
    barmsecs := getvec(conductor_bartab!0 + 1) 
    UNLESS barmsecs DO
    { writef("Unable to allocate space for barmsecs*n")
      RESULTIS FALSE
    }

    barmsecs!0 := conductor_bartab!0
    FOR bno = 1 TO conductor_bartab!0 DO
    { LET ms = qbeats2msecs(conductor_bartab!bno, conductorenv)
      barmsecs!bno := ms
      //writef("Setting barmsecs!%i3 qbeat=%i7 = %8.3d*n",
      //        bno, conductor_bartab!bno, ms)
    }

    // Change the elements of beatmsecs fromqbeats to msecs
    beatmsecs := beattabcb!1
    maxbeatno := beatmsecs!0
    //writef("Setting beatmsecs, beatmsecs!0=%n*n", maxbeatno)
    FOR beat = 1 TO maxbeatno DO
    { LET ms = qbeats2msecs(beatmsecs!beat, conductorenv)
      //writef("Setting beatmsecs!%i4 qbeat=%i7 = %8.3d*n",
      //        beat, beatmsecs!beat, ms)
      beatmsecs!beat := ms
    }
    //abort(1111)
  }

  WHILE part DO
  { LET qbeats = 0
    LET bars   = result2
    LET partenv = 0

    partenv := newvec(e_upb)
    UNLESS partenv DO
    { trerr("More space needed")
      RESULTIS FALSE
    }
    FOR i = 0 TO e_upb DO partenv!i := 0

    h5!part := partenv

    e_qbeats   !partenv := e_qbeats   !conductorenv
    e_maxbarno !partenv := e_maxbarno !conductorenv 
    e_bartab   !partenv := e_bartab   !conductorenv 
    e_tempo    !partenv := e_tempo    !conductorenv
    e_qtimev   !partenv := e_qtimev   !conductorenv
    e_qtimevupb!partenv := e_qtimevupb!conductorenv
    e_tempo    !partenv := e_tempo    !conductorenv

    IF midichannel>=16 DO
      writef("Error: No more than 16 parts are allowed*n")

    // Choose next midi channel (avoiding 10 -- GM percussion)
    // midichannel will be in range 1 to 16
    midichannel := midichannel + 1 REPEATWHILE midichannel=10
    e_midichannel!partenv := midichannel

    IF n_op!part=s_solo DO solochannel := midichannel

    transposition := 0 // No transposition specified yet

//sawritef("trscore: calling performbarscan on a part (channel=%n)*n",
//          midichannel)
    //performbarscan(part, partenv, FALSE) // FALSE = not conductor part
                                         // so don't create the bar table
//abort(1005)
    IF optPtree DO { writes("*nPart Tree*n*n")
                     prtree(part, 0, 20)
                     newline()
                   }
  
    performshapescan(part, partenv, s_vol,    e_vol,    100_000)
    performshapescan(part, partenv, s_legato, e_legato,  90_000)
    performshapescan(part, partenv, s_delay,  e_delay,    0_000)

/*
    { // Print out the shape tables
      LET tab = e_vol!partenv
      TEST tab
      THEN { writef("*nVolume table*n*n")
//abort(1001)
             FOR i = 1 TO tab!0 BY 2 DO
             { writef(" %i5:%9i %9.3d*n", i, tab!i, tab!(i+1))
             }
             newline()
           }
      ELSE writef("No volume table*n")
      newline()

      tab := e_legato!partenv
      TEST tab
      THEN { writef("*nLegato table*n*n")
//abort(1001)
             FOR i = 1 TO tab!0 BY 2 DO
             { writef(" %i5:%9i %9.3d*n", i, tab!i, tab!(i+1))
             }
             newline()
           }
      ELSE writef("No legato table*n")
      newline()

      tab := e_delay!partenv
      TEST tab
      THEN { writef("*nDelay table*n*n")
//abort(1001)
             FOR i = 1 TO tab!0 BY 2 DO
             { writef(" %i5:%9i %9.3d*n", i, tab!i, tab!(i+1))
             }
             newline()
           }
      ELSE writef("No delay table*n")
      newline()
    }
    //abort(1011)
*/

    // Compile into midilist (the list of unsorted midi items)
    //performnotescan(part,      // The tree for this part
    //                partenv)   // Its environment node


    // Deal with the ties table
//    IF tiesv DO
//    { //writef("ties table upb = %n  current size=%n*n", tiesupb, tiesv!0)
//      FOR i = 1 TO tiesv!0 BY 2 UNLESS tiesv!i=0 DO
//        writef("Outstanding tied note: channel=%n note=%n qbeat=%n*n",
//                tiesv!i & 15, tiesv!i>>8, tiesv!(i+1))
//    }
    part := !part // Deal with next part, if any.
  }
  RESULTIS TRUE
}

AND qbeatlength(x) = VALOF
{ // Return the qbeat length of construct x
  // assuming that x has already been bar scanned so
  // nodes such as seq and par already have their qlen fields
  // filled in.
//sawritef("qbeatlength called*n")
  RESULTIS walktree(x, 0, w_length, 0, 0, 0)
}

AND shapelength(x) = VALOF
{ // x is a sequence of shape values.
  // It returns the length of the shape in qbeats.
  // qbeats is incremented by spaces, eg s4, s8.., etc
  // If no spaces occur between values a separation of s4 is assumed.

  // x is either a number, a tied number, a space or a sequence (s_seq) node
  // containing a list of numbers, tied numbers and spaces.

  LET op, ln, a, b = ?, ?, ?, ?
  LET opname = ?
  LET numcount = 0

  IF x=0 RESULTIS 1024  // ie an implied s4

  op, ln, a, b := n_op!x, n_ln!x, n_a1!x, n_a2!x
  opname := opstr(op)
//writef("shapelength: %n %s:*n", x, opname)
//abort(1000)

  SWITCHON op INTO
  { DEFAULT:
      trerr("%s -- %n", opname, ln)
      RESULTIS 0

    // Operators with a list argument
    CASE s_seq:       // [-, Seq, ln, list, qlen]
    { LET qbeats  = 0
      LET prevnum = FALSE // TRUE if the previous item was a number

      //writef("%s -- %n*n", opname, ln)

      IF a=0 | !a=0 RESULTIS 1024

      WHILE a DO
      { LET op = n_op!a
        SWITCHON op INTO
        { DEFAULT:
            //writef("%s -- %n*n", opname, ln)
            prevnum := FALSE
            ENDCASE

          CASE s_num:
          CASE s_numtied:
          { LET val = numval
            //writef("%s -- %n*n", opname, ln)
            IF prevnum DO
            { // Assume s4 between numbers
              qbeats := qbeats + 1024
            }
            prevnum := TRUE
            ENDCASE
          }

          CASE s_space:
          { LET qlen = n_a1!a
            //writef("%t7  ", opname)
            //prnote((op=s_rest -> 'r', 's'), 0, 0, qlen)
            //newline()
            qbeats := qbeats + qlen
            prevnum := FALSE
            ENDCASE
          }
        }

        //writef("%s -- qbeats = %n*n", opname, qbeats)
        a := !a
      }

      IF qbeats=0 & prevnum DO qbeats := 1024

      RESULTIS qbeats
    }
  }
}

AND shapescan(x, cb, qbase, qlen, slen) BE IF x DO
{ // x is a sequence (with op s_seq) of shape values.
  // cb is the self expanding shape structure with
  //   cb!0 = current upb of the shape vector, and
  //   cb!1 = zero or the shape vector whose zeroth element
  //          is the position of the latest entry.
  // qbase is the value of qbeats at the start of the shape.
  // qlen is the required length of the segment in qbeats.
  // slen is the length of the shape in qbeats.
  // If cb!1 (=v, say) is non zero, and v!0 (=p, say) is the
  // position of the latest entry. The entries v!1 .. v!(p-1)
  // contain (qbeat, value) pairs, and v!p is TRUE if there is
  // an outstanding tie and FALSE otherwise.

  // x is either a number, a tie, a space or a sequence (s_seq) node
  // containing a list of numbers, spaces and ties.  

  LET op, ln = n_op!x, n_ln!x
  LET opname = opstr(op)
  LET qbeats = 0        // To hold qbeats from the start of the shape.

  // The following variables are used to implement the rule that
  // s4 is inserted between consecutive values.

  LET firstval  = TRUE  // No previous value
  LET prevspace = FALSE // No space given since last value

  UNLESS op=s_seq DO trerr("System error: Bad shape op=%s", opname)

  x := n_a1!x  // Get the item list

  WHILE x DO
  { LET v = cb!1
    LET p = v!0
    LET qpos = ?

    op := n_op!x
    opname := opstr(op)

//writef("*nshapelength: op=%s: qbase=%n qlen=%n slen=%n*n",
//        opname, qbase, qlen, slen)
//abort(1017)
    SWITCHON op INTO
    { DEFAULT:
        //writef("%s -- %n*n", opname, ln)
        ENDCASE

      CASE s_num:
      CASE s_numtied:
      { LET val = n_a1!x
        LET prevtied = v!p
        p := p-1                 // Remove the pushed tie flag
        v!0 := p

        //writef("%s %9.3d  -- ", opname, val); prlineno(ln); newline()
      
        UNLESS prevspace | firstval DO
        { // Assume s4 between consecutive values
          qbeats := qbeats + 1024
          //writef("shapescan: inserting s4, qbeats=%n*n", qbeats)
        }

        // Calculate the qbeat position of this value
        qpos := qbase + muldiv(qbeats, qlen, slen)

        IF qpos >= qbase+qlen DO qpos := qbase+qlen-1

//writef("shapescan: op=%s val=%4.3d qbeats=%n qlen=%n slen=%n qpos=%n*n",
//          opname, val, qbeats, qlen, slen, qpos)
//abort(1014)

        UNLESS prevtied DO
        { // Not tied, so duplicate the previous value, if room
          LET prevq, prevval = v!(p-1), v!p // Prev qbeat and value
          IF prevq<qpos-1 DO
          { // Only if the tie length is greater than 1 qbeat.
//writef("Not tied Plant at p=%i3: %i6 %9.3d*n", v!0+1, qpos-1, prevval)
            pushval(cb, qpos-1)   // Duplicate value.
            pushval(cb, prevval)  // Duplicate value.
          }
        }
//writef("Plant at p=%i3: %i6 %9.3d*n", v!0+1, qpos, val)
        pushval(cb, qpos)
        pushval(cb, val)
 
        pushval(cb, op=s_numtied)  // Indicate whether the previous
                                   // value had a tie.
        firstval  := FALSE
        prevspace := FALSE
//abort(1015)
        ENDCASE
      }

      CASE s_space:
      { LET len = n_a1!x
        //writef("%t7  ", opname)
        //prnote((op=s_rest -> 'r', 's'), 0, 0, len)
        //newline()
        qbeats := qbeats + len
        prevspace := TRUE
        ENDCASE
      }
    }
//abort(1012)
    //writef("%s -- qbeats = %n*n", opname, qbeats)
    x := !x  // Get the next item in the shape list.
  }
}

AND performbarscan(x, env, isconductor) BE
{ LET upb, v = 0, 0 // For the bar table which holds the qbeat value at
                    // the start of each bar (in the conductor's part).
  LET bartab = isconductor -> @upb, 0

  e_qbeats  !env := walktree(x, 0, w_barscan, bartab, 0, 0)
  e_maxbarno!env := result2

  // Insert v at head of xvlist
  v!0 := xvlist
  xvlist := v

  e_bartab!env := v+1
//writef("performbarscan: qbeats=%n maxbarno=%n*n",
//    e_qbeats!env, e_maxbarno!env)
//abort(1004)
}

LET pushval(cb, x) BE
{ // This pushes value x into the table whose control block
  // is tab which has 2 elements as can be seen below.
  LET upb = cb!0      // Current upb of v
  LET v   = cb!1      // is zero or a getvec'd vector holding 
                      // the elements.
  // v!0   is the position in v of its latest element
  // v!1 ... v!(v!0) are the elements
  LET p = v -> v!0, 0 // Position of the previous element, if any.

  // The size of v grows as needed.

  // Initially upb, p, and v are all zero, causing them to be
  // properly initialised on the first call of pushval.

  IF p+1>upb DO
  { // v is not large enough, so we must allocate a larger vector
    LET newupb = 3*upb/2 + 100
    LET newv = getvec(newupb)
//writef("pushval: allocating vec %i6 upb %n*n", newv, newupb)
//abort(2222)
    UNLESS newv DO
    { trerr("More memory needed")
      RETURN
    }
    cb!0 := newupb
    cb!1 := newv
    // Copy the existing table
    FOR i = 0 TO upb DO newv!i := v!i
    // Pad with zeros
    FOR i = upb+1 TO newupb DO newv!i := 0
    // Free the old vector
    IF v DO freevec(v)
IF debugv!1 DO
{  writef("pushval: replacing v=%i6 upb=%i5 with newv=%i7 upb=%i5*n",
           v, upb, newv, newupb)
   abort(6666)
}
    v := newv
  }
  p := p+1
  v!0, v!p := p, x
IF debugv!1 DO
  writef("pushval: updating v[%i3] with %i9*n", p, x)
}

AND performshapescan(x, act) = VALOF
{ // x   is the tree node for a new shape scope to process.
  // act is the shape operator, eg s_tempo, s_vol, ...

  // If any items for the specified shape are found, this function
  // returns a pointer to [link, act, qlen, [2n, q1, x1,..., qn, xn]]
  // If no appropriate shape items are found it returns zero.

  // If the result is non zero, a node referring to the self expanding
  // vector holding the shape data is inserted at the head of xvlist.

  LET upb, v = 0, 0 // The control block
  LET cb = @upb

  LET shapeqlen = walktree(x,
                           0,    // Initial qbeats value
                           act,  // The action eg s_tempo, s_vol, ...
                           cb)   // The control block of the self extending
                                 // vector to hold the shape data pairs.

  IF FALSE DO
  { writef("Shape vector %n for op=%s*n*n", v, opstr(act))
    //abort(1014)
    IF v FOR i = 1 TO v!0 BY 2 DO writef("%i6: %9.3d*n", v!i, v!(i+1))
    newline()
    //abort(1023)
  }

  // Insert this self expanding vector at the head of xvlist, is necessary.
  IF v DO
  { xvlist := mk2(xvlist, v)
    RESULTIS mk4(0, act, shapeqlen, v) // ??????????
  }

  RESULTIS 0 // No shape items found.
}

AND istied(tiescb, n, q) = VALOF
{ // tiescb is the ties control block, tiescb -> [prevtiescb, tlist, ...]
  // cn is the note and channel number
  // q is the qbeat value for the end of the tied note being looked for.
  LET prev = tiescb!0
  LET a    = @tiescb!1

//writef("istied: searching tiescb=%n tiescb!1=%n for n=%n q=%n*n",
//        tiescb, tiescb!1, n, q)
//prties(tiescb)

  WHILE !a DO
  { LET p = !a
//writef("istied: comparing (%n,%n) with (%n,%n), n, q, p!1, p!2)
    IF p!1=n & p!2=q DO
    { // A suitable tied note has been found
      // Remove it from tlist
      !a := !p
      // free its node
      unmk3(p)
      // and return TRUE
//writef("istied: n=%n q=%n resolved*n", n, q)
//prties(tiescb)
      RESULTIS TRUE
    }
    a := p
  }

  // Look in the previous tiescb, is any.
  IF prev RESULTIS istied(prev, n, q)
  RESULTIS FALSE
}

AND performnotescan(x, env) BE
{ // Translate part x into midi items appending them to midilist
  LET prev, tlist, clist = 0, 0, 0 // The initial ties control block
                                   // prev=0  -- no previous ties control block
                                   // tlist=0 -- no current ties yet
                                   // clist   -- empty clist
  LET tiescb = @prev   // tiescb -> [prev, tlist, clist]

  LET a0, a1, a2 = 0, 1000, 1000 // The scaling parameters
 
  walktree(x,
           0,              // Initial qbeat value
           w_genmidi,      // Action
           tiescb,         // the ties control block
           env,            // the current environment
           @a0)            // the scaling parameters
}

AND prties(tiescb) BE FOR i = 1 TO 9 TEST tiescb
THEN { LET tlist, clist = tiescb!1, tiescb!2
       writef("%n: tiescb=%n(%n, %n, %n)",
               i, tiescb, tiescb!0, tlist, clist)
       writef("*ntlist =")
       WHILE tlist DO
       { writef(" (%n,%n)", tlist!1, tlist!2)
         tlist := !tlist
       }
       writef("*nclist =")
       WHILE clist DO
       { writef(" (%n,%n)", clist!1, clist!2)
         clist := !clist
       }
       newline()
       tiescb := !tiescb
     }
ELSE RETURN

AND updatebeattable(qbeats, barno) BE
{ // This function is only called during a barscan of the conductor's part.
  // It update the beat table checking that the current qbeat value
  // is compatible with the current time signature.
  // This is only called when a time signature or bar line is
  // encountered while performing a barscan on the conductor part,
  // and a warning is given if the beats of the previous time signature
  // is not complete. Thus
  //     \timesig(3 8) r4. r4 |
  // would generate a warning but  
  //     \timesig(3 8) r4. r4. |
  // would not.
  WHILE prevbeatqbeat + qbeatsperbeat <= qbeats DO
  { prevbeatqbeat := prevbeatqbeat + qbeatsperbeat
    beatcount := beatcount + 1
    IF beatcount > timesiga DO beatcount := 1
    pushval(beattabcb, prevbeatqbeat)
  }
  UNLESS prevbeatqbeat=qbeats & beatcount=1 DO
     writef("Error: Time signature or bar line misplaced in bar=%n*n",
            barno)

}

AND qbeats2barno(qb) = VALOF TEST bartab=0
THEN RESULTIS 0
ELSE { LET maxbarno = bartab!0
       STATIC { bn=1 $)
       IF maxbarno=0 RESULTIS 0

       WHILE bn > 0 DO
       { IF qb >= bartab!bn BREAK
         bn := bn-1
       }

       WHILE bn < maxbarno DO
       { IF qb < bartab!(bn+1) BREAK
         bn := bn+1
       }

       RESULTIS bn
     }

AND walktree(t, qbeats, act, cb, env, y) = VALOF
//AND walktree(t, qbeats, act, x, y, z) = VALOF
{ // t is the leading tree node of a segment of notes.

  // act specifies what action to perform during the walk as
  //     described below.

  // qbeats is the qbeat position at the start of the segment t.

  // cb  is normally a control block depending on act.
  // env is normally the current environment structure depending on act.
  // y   is an additional argument depending on act.

  // The result is the qbeat value at the end of processing tree t.

  // The possible values of act are as follows:

  // w_prescan   Fill in qlen fields in the s_seq, s_par and shape nodes
  //             of tree t, and insert s_block nodes where necessary.

  // w_length    Inspect the tree and return its length in qbeats. This
  //             is only called after the tree has been processed by
  //             w_prescan.

  // w_barscan   This is only used when scanning the conductor's part.
  //             It adds entries to the self expanding vectors that map
  //             bar and beat numbers to qbeat values.
  //             After this scan bartab!i is the qbeat value at the start
  //             of bar i, and beattab!i is the qbeat value at the start
  //             of beat i. These vectors are used in the function playmidi
  //             and when generating error messages. 

  // s_tempo     Fill the tempo     control block (cb) with tempo data
  // s_tempoadj  Fill the tempoadj  control block (cb) with tempoadj data
  // s_vol       Fill the vol       control block (cb) with vol data
  // s_voladj    Fill the voladj    control block (cb) with voladj data
  // s_legato    Fill the legato    control block (cb) with legato data
  // s_legatoadj Fill the legatoadj control block (cb) with legatoadj data
  // s_delay     Fill the delay     control block (cb) with delay data
  // s_delayadj  Fill the delayadj  control block (cb) with delayadj data

  // For the eight actions above cb is the control block for the appropriate
  // self extending vector. Its structure is the same for each shape type.

  // The argument cb points to [upb, v] where upb is the current upperbound
  // of v. If v is either zero or is a self expanding vector allocated by
  // getvec. Its zeroth element v!0 holds p the latest element of v to be set.
  // The elements  v!1 ... v!(p-1) contain <qbeat,value> pairs, and
  // v!p = TRUE if the latest shape pair is tied causing the shape value to
  // to change linearly until the next pair. If v!p = FALSE the shape value
  // remains unchanged until the next <qbeat,value> pair. 
  // qbeat is an integer corresponding to the number of quantum beats measured
  // from the start of the score and value it a scaled number with three
  // decimal digits after the decimal point. The shape value at any moment is
  // calculated by linear interpolation between the appropriate two
  // shape pairs.

  // w_genmidi     Generate midi events
  //    cb is the ties control block -> [prev_cb, tlist, clist]
  //       where tlist -> [link, note, qbeat] where
  //                   note is the midi note number and
  //                   qbeat being the last qbeat of this unresolved tie.
  //       and   clist is a similar list of unresolved ties from other
  //                   elements of the current par construct

  //    env is the enclosing environment. It is either zero or points to
  //       block node, ie
  //        env -> [link, s_block, ln, prev_env, shape_list, qbeat, qlen]
  //        where ln is a line/file number
  //              prev_env points to the enclosing environment
  //              shape_list =0 or -> [link, kind, shapedata]
  //              where kind = s_tempo, s_tempoadj, s_vol, s_voladj,
  //                           s_legato, s_legatoadj,
  //                           s_delay or s_delayadj.
  //                    shapedata -> [2n, q1, x1,... qn,xn]
  //                    where qi is a qbeat value and
  //                          xi is the corresponding shape data value.
  //        While the shape data is being built its latest element is TRUS
  //          if the lastest (qi,xi) pair has a tie. 
  //    y -> [qbase, q1, q2] the scaling parameters
  //        where qbase is the starting qbeat value and q1/q2 is the scaling
  //        factor.

  // qbase, q1 and q2 are required for the implementation of (t)\tuplet(y)
  // q1 and q2 give the scale adjustment. q2 is the qbeat length of y
  // and q1 is the length of t, ie the required qbeat length. qbase is
  // the qbeat value at the start of t, so qbeat values of scheduled
  // commands (eg note on) must be scaled by the following formula:

  //        qbase + muldiv(qbeats-qbase, q1, q2).

  // Clearly if q1=q2 no scaling is required.

  // Midi data is appended to a list of midi events (midilist) whose
  // last node is pointed to by midiliste.
  // Each node in the list is of the form [link, msecs, midi-triple]
  // where link points to the next item, msecs is the time of this event
  // in milli-seconds from the start of the score, and midi-triple is a packed
  // triplet of bytes representing a midi event. The least significant byte
  // is the note operator (eg note_on or note off + the MIDI
  // channel number(0..15)). The senior 24 bits provide up to 3 bytes of
  // operand, such as a midi note number and pressure. Although not
  // currently used, non midi operations can be represented using least
  // significant bytes less that 128.

  LET op, actname, opname, ln, a1, a2 = ?, ?, ?, ?, ?, ?

  IF t=0 RESULTIS qbeats

  op := n_op!t  // The tree node operator
  ln := n_ln!t  // The file/line number of the tree node
  a1 := n_a1!t  // The first operand, if any, of the tree node
  a2 := n_a2!t  // The second operand, if any, of the tree node

  actname := opstr(act)
  opname  := opstr(op)

writef("walktree: qbeat:%i8 ", qbeats)
writef("act=%9t op=%14t a1=%i7 -- ", actname, opname, a1)
prlineno(ln)
newline()
writef("%n %10t#:*n", t, opname)
//abort(1003)

  SWITCHON op INTO
  { DEFAULT:
      writef("walktree %s: Bad op %s (%n) qbeats=%n*n",
              actname, opname, op, qbeats)
//abort(1000)
      RESULTIS qbeats

    CASE s_name:                // These cases generate no midi data
    CASE s_instrumentname:
    CASE s_instrumentshortname:
    CASE s_instrument:
    CASE s_partlabel:
    CASE s_barlabel:
    CASE s_title:
    CASE s_composer:
    CASE s_arranger:
    CASE s_opus:       // t -> [-, op, ln, string]
    CASE s_keysig:
    CASE s_trebleclef:
    CASE s_altoclef:
    CASE s_tenorclef:
    CASE s_bassclef:
      RESULTIS qbeats

    CASE s_timesig:   // t -> [-, Timesig, ln, a1, a2]
    { // This is used in the conductor part to construct the mapping
      // vector from beat number to qbeat value. The qbeat values are
      // later replaced by msecs values.
      // A warning is given if a timesig statement or bar line does
      // not occur at the time of a beat. Timesig statements can occur
      // in the middle of bars as in:
      // | \timesig(3 8) r4. r4. \timesig(2 8) r4 |
      IF act=w_barscan DO
      { updatebeattable(qbeats, barno)
        timesiga, timesigb, prevbeatqbeat := n_a1!t, n_a2!t, qbeats
        qbeatsperbeat := 4096/timesigb
        beatcount := 1
//writef("timesig: %n %n qbeat=%n*n", timesiga, timesigb, qbeats)
      }
      RESULTIS qbeats
    }

    CASE s_pedon:      // t -> [-, pedon,    ln]
    CASE s_pedoff:     // t -> [-, pedoff,   ln]
    CASE s_pedoffon:   // t -> [-, pedoffon, ln]
    CASE s_portaon:    // t -> [-, portaon,  ln]
    CASE s_portaoff:   // t -> [-, portaoff, ln]
    CASE s_softon:     // t -> [-, softon,   ln]
    CASE s_softoff:    // t -> [-, softoff,  ln]

    CASE s_control:    // t -> [-, control, ln, controller, value]
      IF act=w_genmidi DO
      { LET qbase  = y!0
        LET q1     = y!1
        LET q2     = y!2
        LET chan   = e_midichannel!env - 1 // chan in range 0 to 15 
        LET dly    = interpolate(e_delay!env,  qbeats)
        LET t1 = qbeats        // Start of note
        // Add the delay amount
        t1 := t1 + muldiv(dly, 1024, 1000) // Time in qbeats
//sawritef("walktree %s: scaling t1=%n qbase=%n q1=%n q2=%n",
//        actname, t1, qbase, q1, q2)
        UNLESS q1=q2 DO // Scale if necessary.
        { t1 := qbase + muldiv(t1-qbase, q1, q2)
        }

        SWITCHON op INTO
        { DEFAULT: 
            writef("walktree %s: Bad op %s (%n) qbeats=%n*n",
                   actname, opname, op, qbeats)
            abort(999)
            RESULTIS qbeats

          CASE s_pedon:      // t -> [-, pedon,    ln]
            a1, a2 := 64, 127
            ENDCASE
          CASE s_pedoff:     // t -> [-, pedoff,   ln]
            a1, a2 := 64, 0
            ENDCASE
          CASE s_pedoffon:   // t -> [-, pedoffon, ln]
            a1, a2 := 64, 0
            ENDCASE
          CASE s_portaon:    // t -> [-, portaon,  ln]
            a1, a2 := 65, 127
            ENDCASE
          CASE s_portaoff:   // t -> [-, portaoff, ln]
            a1, a2 := 65, 0
            ENDCASE
          CASE s_softon:     // t -> [-, softon,   ln]
            a1, a2 := 66, 127
            ENDCASE
          CASE s_softoff:    // t -> [-, softoff,  ln]
            a1, a2 := 66, 0
            ENDCASE

          CASE s_control: // t -> [-, control, ln, a1=controller, a2=value]
            ENDCASE
        }
//sawritef(" => t1=%n*n", t1)
        apmidi(qbeats2msecs(t1, env),                    // Msecs
               midi_controlchange+chan+(a1<<8)+(a2<<16)) // Control
        IF optNtrace DO
          writef("%i7: Control:  chan=%n ctrl=%i3  val=%n*n",
                  t1, chan, a1, a2)
        IF op=s_pedoffon DO
        { a2 := 127
          // Delay pedon by 10 msecs
          apmidi(qbeats2msecs(t1, env)+10,                 // Msecs
                 midi_controlchange+chan+(a1<<8)+(a2<<16)) // Control
          IF optNtrace DO
            writef("%i7: Control:  chan=%n ctrl=%i3  val=%n*n",
                    t1, chan, a1, a2)
        }
      }
      RESULTIS qbeats

    CASE s_note:      // t -> [-, Note,     ln, <letter,sharps,n>, qlen]
    CASE s_notetied:  // t -> [-, Notetied, ln, <letter,sharps,n>, qlen]
      IF act=w_genmidi DO
      { // Generate appropriate Midi events
        LET tiescb = cb
        LET qbase  = y!0
        LET q1     = y!1
        LET q2     = y!2
        LET chan = e_midichannel!env - 1 // chan in range 0 to 15 
        LET n      =  a1      & 255
        LET sharps = (a1>> 8) & 255
        LET letter = (a1>>16) & 255
        // Find the requires Midi note number
        LET trn    = n + transposition  // The transposed note
        LET qlen   = a2
        LET vol    = interpolate(e_vol!env,    qbeats)
        LET legato = interpolate(e_legato!env, qbeats)
        LET dly    = interpolate(e_delay!env,  qbeats)
        // A delay of 1.000 = 1 crotchet ie 1024 qbeats
        dly := muldiv(dly, 1024, 1000) // Delay in qbeats

        //writef("walktree %s: %t8  ", actname, opname)
        //prnote(letter, sharps, n, qlen)
        //writef(" vol=%9.3d legato=%9.3d delay=%9.3d*n",
        //        vol, legato, dly)
//abort(1010)
//writef("qbeats=%n*n", qbeats+qlen)
        //IF transposition DO
        //  writef("walktree %s: note %i3 transposed to %i3*n  ",
        //          actname, n, trn)

        // Scale volume 0 to 100_000 to midi range 0 to 127
//writef("note: trn=%n vol=%8.3d scaled to ", trn, vol)
        vol := (127 * vol + 50_000)/100_000
        IF vol>127 DO vol := 127
        IF vol<0   DO vol := 0
//writef("%n*n", vol)
//abort(1000)
        { // Deal with \delay.
          LET t1 = qbeats + dly        // Start of note
          LET t2 = qbeats + qlen + dly // Nominal end of note
          // Add the delay amount
//writef("walktree %s: scaling t1=%n t2=%n qbase=%n q1=%n q2=%n",
//        actname, t1, t2, qbase, q1, q2)
          UNLESS q1=q2 DO // Scale if necessary.
          { t1 := qbase + muldiv(t1-qbase, q1, q2)
            t2 := qbase + muldiv(t2-qbase, q1, q2)
          }
//writef(" => t1=%n t2=%n*n", t1, t2)

//writef("calling istied(tiescb=%n n=%n qbeats=%n*n", tiescb, n, qbeats)
          UNLESS istied(tiescb, trn, qbeats) DO
          { // This note is not tied to a previous note
            // so schedule a note_on command.
            apmidi(qbeats2msecs(t1, env),                  // Msecs
                   midi_note_on+chan+(trn<<8)+(vol<<16))   // Note on
            IF optNtrace DO
              writef("%i7: Note On:  chan=%n note=%t4  vol=%n*n",
                      t1, chan, note2str(trn, strv), vol)
          }

          TEST op=s_notetied
          THEN { // This note is tied with a later one so don't
                 // schedule its note off command, but insert an item
                 // in the current list of unresolved tied notes.
                 LET tiescb = cb
                 LET t = qbeats+qlen // Nominal end qbeat of this note
                 // Scale the end qbeat value, if necessary.
                 UNLESS q1=q2 DO
                   t := qbase + muldiv(t-qbase, q1, q2)
                 // t is the scaled qbeat of the end of this note
//sawritef("notetied: pushing chan %n:%n endt=%n*n", chan, trn, t)

                 tiescb!1 := mk3(tiescb!1, trn, t) // End time and note numb
//writef("walktree: tied note n=%n t=%n*n", trn, t)
//                   prties(tiescb)
               }
          ELSE { // This note is not tied to a later one so
                 // schedule a note off command
                 LET t = qbeats + dly   // The start time in qbeats
                 // Add legato modified note length
                 t := t + muldiv(qlen, legato, 100_000) // The end time
                 // Scale if necessary
                 UNLESS q1=q2 DO
                   t := qbase + muldiv(t-qbase, q1, q2)
//writef("%i7: Note off: chan=%n note=%i3  legato=%9.3d*n", t, chan, n, legato)
                 apmidi(qbeats2msecs(t, env),        // Msecs
                        midi_note_off+chan+(trn<<8)) // Note off
                 IF optNtrace DO
                   writef("%i7: Note Off: chan=%n note=%t4*n",
                           t, chan, note2str(trn, strv))
               }
        }
      }
      // Return the qbeats value of the next note item. 
      RESULTIS qbeats + a2

    CASE s_transposition:
      transposition := a1
//writef("walktree %s: transposition set to %n*n", actname, transposition)
      RESULTIS qbeats


    CASE s_rest:
    CASE s_space:
//writef("walktree: rest: qbeats=%n*n", qbeats+a)
      RESULTIS qbeats + a1

    CASE s_null:  // A zero length space (rest).
//writef("walktree: %s: %s*n", actname, opname)
      RESULTIS qbeats

    CASE s_bank:
      IF act=w_genmidi DO
      { LET qbase = y!0
        LET q1    = y!1
        LET q2    = y!2
        LET chan  = e_midichannel!env - 1 // chan is in range 0 to 15 
        LET t, msecs = ?, ?
        LET dly   = interpolate(e_delay!env, qbeats)
        // A delay of 1.000 = 1 crotchet ie 1024 qbeats
        dly := muldiv(dly, 1024, 1000) // Delay in qbeats

//writef("walktree: bank %n %n*n", a1, a2)
        // Add the delay amount
        t := qbeats + dly              // Time in qbeats
        // Scale t, if necessary
        UNLESS q1=q2 DO
          t  := qbase + muldiv( t-qbase, q1, q2)
        msecs := qbeats2msecs(t, env) // Event time is msecs
//writef("%i7: Bank:     chan=%n MM=%n LL=%n*n", t, chan, a1, a2)
        apmidi(msecs,                                     // Msecs
               midi_controlchange+chan+(0<<8)+(a1<<16))   // Bank MM
        apmidi(msecs,                                     // Msecs
               midi_controlchange+chan+(32<<8)+(a2<<16))  // Bank LL
      }

      RESULTIS qbeats

    CASE s_patch:
//sawritef("CASE s_patch:*n")
      IF act=w_genmidi DO
      { LET qbase = y!0
        LET q1    = y!1
        LET q2    = y!2
        LET chan  = e_midichannel!env - 1 
        LET t, msecs = ?, ?
        LET dly   = interpolate(e_delay!env, qbeats)
        // A delay of 1.000 = 1 crotchet ie 1024 qbeats
        dly := muldiv(dly, 1024, 1000) // Delay in qbeats

        //sawritef("walktree: patch %n env=%n*n", a1, env)
        // Add the delay amount
        t := qbeats + dly
        // Scale t, if necessary
        UNLESS q1=q2 DO
          t  := qbase + muldiv( t-qbase, q1, q2)
        msecs := qbeats2msecs(t, env)  // Event time is msecs
//sawritef("%i7: Patch:    chan=%n prog=%n*n", t, chan, a1)
//abort(1006)
        apmidi(msecs,                            // Msecs
               midi_progchange+chan+(a1<<8))     // Patch command
      }
      RESULTIS qbeats

    CASE s_par:       // [-, Par, ln, list, qlen]
      // list is the list of items in the par construct
      //writef("walktree: %s qlen=%n -- %n qbeats=%n*n",
      //        opname, h5!t, ln, qbeats)
      IF act=w_prescan DO
      { LET qbeatsstart = qbeats
        LET qbeatsend = -1
        LET qbeatmax  = 0
        LET ptr = @p!n_a1
        LET oldshapes = shapes

        // Then prescan the items of the par construct.
        { LET qe = 0
          LET a := !ptr
          UNLESS a BREAK
          shapes := FALSE
          qe := walktree(a, qbeatsstart, s_prescan, cb, env, y)
          IF shapes DO
          { // Insert a Block node
            LET b = mk7{!a, s_block, ln, a,
                        currblk, // The parent link
                        0,       // Initially empty list of shape items
                        qe-qbeatstart) // The qlen of this item
            !ptr := b
            ptr := !a  
          }
        } REPEAT

        RESULTIS qbeatsend
      }

      IF act=w_genmidi DO
      { LET qbeatsstart = qbeats
        // Create a new ties control block
        LET prevtiescb, tlist, clist = cb, 0, 0
        // tlist will hold a list of unresolved ties during
        // the processing of each member of the par construct.
        // clist will hold the combined list of unresolved ties
        // of all members of the par construct.
        // When all members have been processed, these are combined
        // with the tlist of the previous tiescb.
        LET tiescb = @prevtiescb

        // Walk the first item of the par construct
        LET qbeatsend = walktree(a1, qbeats, act, tiescb, env, y)

        clist := tlist

        // Then walk the other items of the par construct.
        { a1 := !a1
          tlist := 0       // Reset the current ties list
          UNLESS a1 BREAK
          walktree(a1, qbeatsstart, act, tiescb, env, y)

          // Insert tlist onto the front of clist
          IF tlist DO
          { LET p = tlist
            WHILE !p DO p := !p
            !p := clist
            clist := tlist
          }
        } REPEAT

        // All members of the par construct have been processed, so
        // put clist on the front of the tlist of the previous tcb
        IF clist DO
        { LET p = clist
          WHILE !p DO p := !p
          !p := prevtiescb!1 // Append previous tlist
          prevtiescb!1 := clist  //
        }
//writef("Leaving par construct*n")
//prties(prevtiescb)
        RESULTIS qbeatsend
      }

      // The action is neither w_barscan nor w_genmidi, so
      // just walk the first item of the par construct
      RESULTIS walktree(a1, qbeats, act, cb, env, y)

    CASE s_conductor: // [-, Conductor, ln, notes,  env]
    CASE s_part:      // [-, Part,      ln, notes,  env]
    CASE s_solo:      // [-, Solo,      ln, notes,  env]
      //writef("walktree %s: %s qbeats=%n*n",
      //        actname, opname, qbeats)
      qbeats := walktree(a1, qbeats, act, cb, env, y)
      RESULTIS qbeats

    CASE s_delay:      // [-, delay,     ln, notes, shape, flag]
    CASE s_delayadj:   // [-, delayadj,  ln, notes, shape, flag]
    CASE s_legato:     // [-, legato,    ln, notes, shape, flag]
    CASE s_legatoadj:  // [-, legatoadj, ln, notes, shape, flag]
    CASE s_tempo:      // [-, tempo,     ln, notes, shape, flag]
    CASE s_tempoadj:   // [-, tempoadj,  ln, notes, shape, flag]
    CASE s_vol:        // [-, vol,       ln, notes, shape, flag]
    CASE s_voladj:     // [-, voladj,    ln, notes, shape, flag]
    { LET q0 = qbeats

      IF op=act DO
      { LET qlen = qbeatlength(a1)        // =qbeats in left operand
        LET slen = shapelength(a2)        // =qbeats in the shape
        shapescan(a2, cb, q0, qlen, slen) // Append shape data to cb
        h6!a1 := TRUE  // This shape has been processed
        RESULTIS q0 + qlen
      }

      //sawritef("walktree: act=%s q0=%n qlen=%n slen=%n*n",
      //              actname, q0, qlen, slen)
//abort(1008)

      qbeats := walktree(a1, qbeats, act, cb, env, y)

      IF act=w_barscan DO //???????????????????????????????
      { LET qlen = qbeatlength(a1)
        LET slen = shapelength(a2) // in qbeats
//sawritef("walktree: op=%s act=%s qlen=%n slen=%n*n",
//          opname, actname, qlen, slen)

        // Fill the shape data in control block given by cb
        shapescan(a2, cb, q0, qlen, slen)
      }

      RESULTIS qbeats
    }

    // The following operators have list operands.

    CASE s_seq:       // [-, Seq, ln, list, qlen]
    { LET q0 = qbeats
         
      IF act=w_length DO
      { //writef("walktree: op=%s ln=%n act=%s qlen=%n*n",
        //        opname, ln, actname, h5!t)
        RESULTIS qbeats + h5!t
      }

      //writef("walktree %s: %s -- %n*n", actname, opname, ln)
      WHILE a1 DO
      { qbeats := walktree(a1, qbeats, act, cb, env, y)
        a1 := !a1
      }

      IF act=w_barscan DO
      {
        h5!y := qbeats - q0 // Fill in the qbeat length of this seq node
        //writef("walktree: op=%s ln=%n act=%s setting qlen=%n*n",
        //        opname, ln, actname, h5!t)
      }

      RESULTIS qbeats
    }

    CASE s_tuplet:
    { // t -> [-, Tuplet, ln, notes, notes]

      // Should treat a1 and a2 as elements of a par construct
      // IMPLEMENT LATER ??????????????????
      LET q0 = qbeats
      LET qlen1 = walktree(a1, q0, act, cb, env, y) - q0
      LET qlen2 = qbeatlength(a2)
      // Now translate the tuplet scaling its length (qlen2)
      // to fit in length qlen1.
//writef("Walktree %s: %s Scaling qlen1=%n qlen2=%n*n",
//        actname, opname, qlen2, qlen1)
      TEST y
      THEN { LET oldqb, oldq1, oldq2 = y!0, y!1, y!2

             y!0, y!1, y!2 := q0, qlen1, qlen2
             walktree(a2, q0, act, cb, env, y)
             y!0, y!1, y!2 := oldqb, oldq1, oldq2
           }
      ELSE   walktree(a2, q0, act, cb, env, y)
      RESULTIS q0+qlen1
    }

    CASE s_doublebar:
    CASE s_barline:
//sawritef("walktree: act=%s qbeats=%i6*n",
//          opstr(act), qbeats)
      IF act=w_barscan DO
      { // We are doing a bar scan in the conductor part so
        // fill in entries in the bar and beat tables.
        updatebeattable(qbeats, barno)
        // Fill in the qbeat value of the new bar
        pushval(bartabcb, qbeats)
        RESULTIS qbeats
      }
      IF bartab DO
      { // Check that the non-conductor barline is in the right place
        LET bn = qbeats2barno(qbeats)
        UNLESS qbeats = bartab!bn DO
        { writef("Misplaced barline -*
                 * bar %n qbeats=%n should be %n*n",
                 bn, qbeats, bartab!bn)
        }
      }

      IF act=w_genmidi DO
      { LET tiescb = cb
        //writef("Barline: qbeats=%n*n", qbeats)
        //prties(tiescb)
//writef("Check for unresolvable ties*n")
        { LET p = @tiescb!1
          WHILE !p DO
          { LET tie = !p
            LET n, q = tie!1, tie!2
            IF q<qbeats DO
            { LET qbase = y!0
              LET q1    = y!1
              LET q2    = y!2
              LET chan  = e_midichannel!env - 1 
              LET t, msecs = ?, ?
              LET dly   = interpolate(e_delay!env, qbeats)
              // A delay of 1.000 = 1 crotchet ie 1024 qbeats
              dly := muldiv(dly, 1024, 1000) // Delay in qbeats

              t := q + dly                 // End time in qbeats
              // Scale t, if necessary
              UNLESS q1=q2 DO
                t := qbase + muldiv(t-qbase, q1, q2)

              msecs := qbeats2msecs(t, env)
              writef("Error: Unresolvable tie n=%s q=%n qbeats=%n*n",
                      note2str(n, strv), q, qbeats)
              // Generate a note off event
              apmidi(msecs, midi_note_off+chan+(n<<8)) // Note off
              IF optNtrace DO
                writef("%i7: Note Off: chan=%n note=%t4*n",
                           t, chan, note2str(n, strv))
abort(999)
              // Remove the tie item
              !p := !tie
              unmk3(tie)
              LOOP
            }
            p := tie
          }
        } 
//abort(1000)
      }
      RESULTIS qbeats
  }
}

AND apmidi(t, code) BE
{ // Append a node onto the end of the midi list
  // t is the time in msecs and
  // code is a midi duplet (op, a) or triplet (op, a, b) of bytes
  //      code = op + (a<<8) + (b<<16)
  LET node = mk3(0, t, code)
  !midiliste := node
  midiliste := node
  //sawritef("apmidi: t=%9.3d %x8*n", t, code)
}

AND qbeats2msecs(q, env) = VALOF
{ LET qtimev    = e_qtimev   !env
  LET qtimevupb = e_qtimevupb!env
  LET i = q/256
  LET x = q MOD 256
  IF i<0 DO i, x := 0, 0
  IF i>=qtimevupb DO i, x := qtimevupb, 0
  IF x=0 RESULTIS qtimev!i
  RESULTIS qtimev!i + muldiv(qtimev!(i+1)-qtimev!i, x, 256)
}

AND barno2msecs(bn, env) = VALOF
{ LET maxbarno = e_maxbarno!env
  LET bartab   = e_bartab  !env
  
//writef("barno2msecs: bn=%n maxbarno=%n*n", bn, maxbarno)
  IF bn<=1        RESULTIS 0
  IF bn>=maxbarno DO bn := maxbarno
//writef("barno2msecs: bn=%n bartab!bn=%n msecs=%n*n",
//    bn, bartab!(bn-1), qbeats2msecs(bartab!(bn-1), env))
//abort(1003)
  RESULTIS qbeats2msecs(bartab!(bn-1), env)
}

AND interpolate(v, x) = VALOF
{ LET res = interpolate1(v, x)
  //writef("interpolate: v=%i6 x=%i6 => res=%6.3d*n", v, x, res)
  RESULTIS res
}

AND interpolate1(v, x) = VALOF
{ LET p = v!0
  // Interpolation data consists of (x,y) pairs stored consectively
  // in v. The upb (p) of v is in v!0
  // (x0,y0) is in v!1     and v!2
  // (x1,y1) is in v!3     and v!4
  // ...
  // (xn,yn) is in v!(p-1) and v!p, the last pair.

  //writef("interpolate: v=%n p=%n x=%n*n", v, p, x)
IF v=0 DO abort(999)
  //FOR i = 1 TO p-1 BY 2 DO writef("%i2: %i9 %9.3d*n", i, v!i, v!(i+1))

  IF x < v!1     RESULTIS v!2
  IF x > v!(p-1 )RESULTIS v!p

  FOR i = 1 TO p-3 BY 2 DO
  { LET x1, y1 = v!i,     v!(i+1)
    LET x2, y2 = v!(i+2), v!(i+3)

//writef("interpolate: i=%i2 %n:%n %n %n:%n*n",
//        i, x1, y1, x, x2, y2)

    IF x>x2  LOOP
    IF x<=x1 RESULTIS y1
    IF x=x2  RESULTIS y2
    // x1 < x < x2

//writef("*ninterpolate: %n:%6.3d %n %n:%6.3d => %9.3d*n",
//        x1, y1, x, x2, y2, y1 + muldiv(y2-y1, x-x1, x2-x1))
//abort(1000)
    RESULTIS y1 + muldiv(y2-y1, x-x1, x2-x1)
  }

  RESULTIS v!p
}
.

SECTION "writemidi"

GET "libhdr"
GET "playmus.h"
GET "sound.h"

MANIFEST {
Meta = #xff

// Meta event defines
Meta_sequence   = 0

// The text type meta events
Meta_text       = 1
Meta_copyright  = 2
Meta_trackname  = 3
Meta_instrument = 4
Meta_lyric      = 5
Meta_marker     = 6
Meta_cue        = 7

// More meta events
Meta_channel      = #x20
Meta_port         = #x21
Meta_eot          = #x2f
Meta_tempo        = #x51
Meta_smpte_offset = #x54
Meta_time         = #x58
Meta_key          = #x59
Meta_prop         = #x7f

// The maximum of the midi defined text types
Max_text_type     = 7

Head_magic        = #x4D546864  // MHdr
Track_magic       = #x4D54726B  // MTrk
}


LET pushbyte(cb, b) BE
{ // This pushes byte x into the self expanding byte table whose
  // control block is cb which has 2 elements as can be seen below.
  LET upb = cb!0     // Current upb (in words) of v
  LET bupb = upb*bytesperword // The upb in bytes
  LET v   = cb!1     // is zero or a getvec'd vector holding 
                     // the elements.
  LET p = v -> v!0, bytesperword-1 // Byte pos of prev element, if any.

//writef("cb=%n p=%n upb=%n v=%n*n", cb, p, upb, v)

  // The size of v grows as needed.

  // Initially upb, p, and v are all zero, causing them to be
  // properly initialised on the first call of pushval.

  IF p+1>bupb DO
  { // Expand the byte vector
    LET newupb = 3*upb/2 + 100
    LET newv = getvec(newupb)
    UNLESS newv DO
    { trerr("More memory needed")
      RETURN
    }
    cb!0 := newupb
    cb!1 := newv
    // Copy the existing table into the new one
    FOR i = 0 TO upb DO newv!i := v!i
    // Pad with zeros
    FOR i = upb+1 TO newupb DO newv!i := 0
    // Free the old table
    IF v DO freevec(v)
    v := newv
  }
  p := p+1
//writef("pushbyte: %x2(%n) at p=%n*n", b&255, b&255, p)
  v!0, v%p := p, b
}

AND pushh(cb, x) BE
{ // Push 16 bits in bigender order
  pushbyte(cb, x>>8)
  pushbyte(cb, x)
}

AND pushw(cb, x) BE
{ // Push 32 bits in bigender order
  pushbyte(cb, x>>24)
  pushbyte(cb, x>>16)
  pushbyte(cb, x>>8)
  pushbyte(cb, x)
}

AND pushw24(cb, x) BE
{ // Push 25 bits in bigender order
  pushbyte(cb, x>>16)
  pushbyte(cb, x>>8)
  pushbyte(cb, x)
}

AND pushstr(cb, s) BE
{ //writef("pushstr: cb=%n %s*n", cb, s)
  pushnum(cb, s%0)
  FOR i = 1 TO s%0 DO pushbyte(cb, s%i)
}

AND pushpfx(cb, n) BE IF n DO
{ pushpfx(cb, n>>7)
  pushbyte(cb, #x80+(n & 127))
}

AND pushnum(cb, n) BE
{ pushpfx(cb, n>>7)
  pushbyte(cb, n & 127)
}

AND packw(cb, p, x) BE
{ LET upb = cb!0
  LET v   = cb!1
  LET pos = v!0
  IF p+3 > pos RETURN
  v%p     := x>>24
  v%(p+1) := x>>16
  v%(p+2) := x>>8
  v%(p+3) := x
}

LET writemidi(filename, midilist) BE
{ // Write MIDI file filename from MIDI items in midilist that have already
  // been sorted.
  LET prevt = 0
  LET stop_msecs = end_msecs + 1_000 // Stop 1 second after end_msecs
  LET stdout = output()
  LET midiout =  0
///  LET tab = midiv  // The sorted MIDI data table
  LET upb, v = 0, 0
  LET cb = @upb // Self expanding byte vector
  LET lpos = 0  // Byte position of track length field

  // Pack Midi header
  
  // Write the MIDI Header
  pushw(cb, Head_magic)
  pushw(cb, 6)               // The header byte length
  pushh(cb, 1)               // Format 1= one or more tracks
  pushh(cb, 2)               // Number of track = 2
  pushh(cb, 1000)            // 1000 ticks per quarter note

  // Write the first (control) track
  pushw(cb, Track_magic)
  lpos := v!0 + 1            // Position of next byte

  pushw(cb, 0)               // For the track byte length

  pushnum(cb, 0)             // Delta time = 0
  pushbyte(cb, #xFF)         // Track name
  pushbyte(cb, #x03)
  pushstr(cb, "control track")

  pushnum(cb, 0)             // Delta time = 0
  pushbyte(cb, #xFF)         // Meta text
  pushbyte(cb, #x01)
  pushstr(cb, "creator: ")

  pushnum(cb, 0)             // Delta time = 0
  pushbyte(cb, #xFF)         // Meta text
  pushbyte(cb, #x01)
  pushstr(cb, "playmus v1.0")
  //pushstr(cb, "GNU Lilypond 2.10.29          ")

  pushnum(cb, 0)             // Delta time = 0
  pushbyte(cb, #xFF)         // Meta time
  pushbyte(cb, #x58)
  pushbyte(cb, 4)            // length
  pushbyte(cb, 4)            // 4 beats per bar
  pushbyte(cb, 2)            // 1 beat = a crochet, ie 4/4 time
  pushbyte(cb, #x12)         // 18 midi clocks per metronome click
  pushbyte(cb, #x08)         // 8 semidemi quavers per 24 midi clocks

  pushnum(cb, 0)             // Delta time = 0
  pushbyte(cb, #xFF)         // Tempo
  pushbyte(cb, #x51)         //
  pushbyte(cb, #x03)         // 
  pushw24(cb, 1_000_000)     // 1000000 usecs per quarter note

  pushnum(cb, 0)             // Delta time = 0
  pushbyte(cb, #xFF)         // End of track
  pushbyte(cb, #x2F)         //
  pushbyte(cb, #x00)         //
  
  packw(cb, lpos, v!0-lpos-3)// Fill in byte length of the track

  // Write the (second) track
  pushw(cb, Track_magic)
  lpos := v!0 + 1            // Position of next byte

  pushw(cb, 0)               // For the track byte length

  pushnum(cb, 0)             // Delta time = 0
  pushbyte(cb, #xFF)         // Track name
  pushbyte(cb, #x03)
  pushstr(cb, "The notes")   // The notes


  WHILE midilist DO
  { LET midimsecs = midilist!1
    LET triple    = midilist!2
    LET op, a1, a2, is_note_on = ?, ?, ?, ?
    LET fn, chan = ?, ?
    LET playing = ?
    LET dt = 0

    IF midimsecs>stop_msecs BREAK
    midilist := !midilist

    op :=  triple      & 255
    a1 := (triple>>8)  & 255
    a2 := (triple>>16) & 255
    fn := op & #xF0   // Midi op without the channel number
    is_note_on := fn = midi_note_on
    chan := op & #x0F   // The midi channel number
    //playing := start_msecs<=midimsecs<=end_msecs

    IF midimsecs>start_msecs DO
    { // Work out the real time delay in msecs
      LET t = midimsecs - start_msecs // msecs since start_msecs 
        
      // Scale the playing speed by tempoadj
      UNLESS tempoadj=1000 | tempoadj<100 DO
        t := muldiv(t, 1000, tempoadj)

      dt := t - prevt
      prevt := t
    }

//writef("%i7: midi op: %x2 %x2 %x2*n", t, op, a1, a2)

    SWITCHON fn INTO
    { DEFAULT:  writef("Unexpected midi op: %x2 %x2 %x2*n", op, a1, a2)
                ENDCASE

      CASE midi_note_on: UNLESS midimsecs>=start_msecs LOOP
      CASE midi_note_off:
      CASE midi_keypressure:
      CASE midi_controlchange:
      CASE midi_chanpressure:
      CASE midi_pitchbend:
        pushnum (cb, dt)
        pushbyte(cb, op)
        pushbyte(cb, a1)
        pushbyte(cb, a2)
        LOOP

      CASE midi_progchange:
        pushnum(cb, dt)
        pushbyte(cb, op)
        pushbyte(cb, a1)
        LOOP

      //CASE midi_sysex:
      //CASE Meta:
    }
  }

  pushnum(cb, 0)             // Delta time = 0
  pushbyte(cb, #xFF)         // End of track
  pushbyte(cb, #x2F)         //
  pushbyte(cb, #x00)         //
  
  packw(cb, lpos, v!0-lpos-3)// Fill in byte length of the track
/*
  IF v DO
  { FOR i = bytesperword TO v!0 DO
    { IF (i-4) MOD 16 = 0 DO newline()
      writef(" %x2", v%i)
    }
    newline()
  }
*/


  midiout := findoutput(filename)
  writef("Writing Midi file: %s*n", filename)

  UNLESS midiout DO
  { writef("Can't open MIDI output file: %s*n", filename)
    RETURN
  }

  writef("midi byte upb=%n*n", v!0)
  selectoutput(midiout)

  FOR i = bytesperword TO v!0 DO binwrch(v%i)

  endstream(midiout)
  selectoutput(stdout)
}

.

SECTION "shapefns"

GET "libhdr"
GET "playmus.h"

LET getshapeval(qv, env, act) = VALOF
{ // Return the shape value corresponding to qbeat position qb 
  // deduced from the shape data in the given environment chain.
  // The result includes the corresponding shape adjustment.
  LET res = lookupshapeval(qv, act,   env, 0)
  LET adj = lookupshapeval(qv, act+1, env, result2)
  RESULTIS muldiv(res, adj, 100_000)
}

AND lookupshapeval(qv, act, p, q) = VALOF
{ // qv  is a qbeat position
  // act is a shape kind
  // p and q are pointers into the environment chain
  UNTIL p=q DO
  { // p -> [link, Block, ln, itemlist, q1, q2]
    LET t = p!3 // The shape item list
    UNTIL t=0 DO
    { // t -> [link, kind, shapedata]
      LET q1, q2 = p!4, p!5
      IF t!1=act DO
      { LET shapedata = t!2
        LET res = shapeval(qv, shapedata, act, p)
        result2 := !p
        RESULTIS res
      }
      t := !t
    }
    p := !p
  }
  // Shape value was not found so return the default value
  SWITCHON act INTO
  { DEFAULT:       // All adjustment shapes
                   RESULTIS 100_000
    CASE s_tempo:  RESULTIS 120_000
    CASE s_vol:    RESULTIS  70_000
    CASE s_legato: RESULTIS  90_000
    CASE s_delay:  RESULTIS   0_000
  }
}

AND shapeval(qv, act, shapedata, p) = VALOF
{ // qv is a qbeat value
  // act is a shape kind
  // shapedata -> [2n, q1, x1, q2, x2,..., qn, xn]
  // p -> the current environment block
  //      [link, Block, ln, itemlist, qbeat1, qbeat2]
  LET n2 = shapedata!0
  LET q1 = shapedata!1
  LET qn = shapedata!(n2-1)

  IF qv<q1 DO
  { LET qb1 = p!4
    LET x = lookupshapeval(qb1, act, !p)
    IF qv<=qb1 RESULTIS x
    RESULTIS x + muldiv(shapedata!2-x, qv-qb1, q1-qb1)
  }

  IF qv>qn DO
  { LET qb2 = p!5
    LET x = lookupshapeval(qb2, act, !p)
    IF qv>=qb2 RESULTIS x
    RESULTIS x - muldiv(x-shapedata!n2, qb2-qv, qb2-qn)
  }

  // At this point q1 <= qv <= qn
  { LET a,  b  = 1, 3
    LET qa, qb = ?, ?
    LET xa, xb = ?, ?
    // Binary chop might be better
    WHILE qv > shapedata!b DO { a := b; b := b+2 }
    qa, qb := shapedata!a, shapedata!b
    xa, xb := shapedata!(a+1), shapedata!(b+1)
    RESULTIS xa + muldiv(xb-xa, qb-qv, qb-qa)
  }
}
.

SECTION "playmidi"

/*
Playmidi is being modified to read microphone input and commands
from the keyboard while it plays the midi events.

Input from the microphone will be compared with the solo part in
an attempt to synchronise midi output with the soloist.

The keyboard commands are read using pollsardch and will be as follows:

B       The nearest bar line is now
space   The nearest beat is now
>       Play faster
<       Play slower
S       Stop/Start
nG      Goto bar n. All commands reset n to zero
P       Goto start of the previous bar
N       Goto the start of the next bar
*/

GET "libhdr"
GET "playmus.h"
GET "sound.h"

LET getrealmsecs1() = VALOF
{ LET msecs = getrealmsecs1()
  LET secs = msecs/1000
  LET mins = secs /60
  LET hours = mins / 60
  
  writef("real time = %9.3d  %2z:%2z%7.3d*n",
          msecs, hours, mins MOD 60, msecs MOD 60000)
  RESULTIS msecs
}

AND getrealmsecs() = VALOF
{ MANIFEST { msecsperday = 24*60*60*1000 } // msecs in 24 hours
  LET day, msecs = 0, 0
  sys(Sys_datstamp, @day)
  // Cause msecs to be monotonic even over midnight
  IF day=baseday RESULTIS msecs
  RESULTIS msecs + msecsperday
}

LET notecofn(argv) = VALOF
{ LET note = argv!0
  LET notetimes = argv!1    // This must be freed before the coroutine dies.
  LET noteupb = notetimes!0
  LET notep = 0             // Will hold the position in notetimes of the
                            // nearest matching note
  LET dmsecs = 0            // Difference between midi time of matching
                            // note and rmsecs  
  LET rmsecs = 0            // Real time of latest sample
  LET offset = 0 // Offset to first sample of k cycles
  LET freq = freqtab!note
  LET notename = VEC 1
  LET samples_per_cycle = muldiv(1000, 44100_000, freq) // Scaled integer
  LET mask = #xFFFF
  LET prevamp, noteon = 0, FALSE
  LET k =  note/2               // Number of cycles to use
  IF k<4 DO k := 4
  IF k>32 DO k := 32
  offset := samples_per_cycle / 44100 // offset in msecs
  // If a note is detected, assume it started at rmsecs-offset
  note2str(note, notename)

  writef("note=%s samples_per_cycle = %9.3d freq=%9.3d k=%n*n",
            notename, samples_per_cycle, freq, k)
  FOR i = 1 TO notetimes!0 DO
  { IF (i-1) MOD 8 = 0 DO newline()
    writef("", notetimes!i)
  }

  rmsecs := cowait(0) // real time now, or -1 to finish

  WHILE rmsecs>=0 DO
  { LET p0amp, p1amp = 0, 0
    LET p = soundp + mask
    LET q = p + samples_per_cycle/4000 // 90 degree out of phase
    LET c = 0
    LET amp, total = ?, ?

    FOR i = 1 TO k DO
    { LET a = ((samples_per_cycle*i)/1000) & -2 // Round down to even
      LET b = (a+c)/2
      //writef("a=%i4 b=%i6 c=%i6*n", a, b, c)
      c := a
      p0amp := p0amp - soundv!((p-a)&mask) +
                       soundv!((p-b)&mask)
      p1amp := p1amp - soundv!((q-a)&mask) +
                       soundv!((q-b)&mask)
      //writef("p0amp=%i8   p1amp=%i8*n", p0amp, p1amp)
    }
    total := soundv!((p-c)&mask) - soundv!(p&mask)
    // Calculate the average amplitude of c samples
    amp := (ABS(total+2*p0amp) + ABS(total+2*p1amp)) / c
    //writef("%9.3d %i5*n", freq, amp)
    //writef("%s %i7*n", notename, amp)
    IF amp>4000 UNLESS noteon DO
    { LET mmsecs = r2m_msecs(rmsecs, curr_rate, curr_offset) // Midi time of now
      writef("%9.3d: mmsecs=%9.3d %s*n", rmsecs, mmsecs, notename)
      //writef("  prevamp=%i5  amp=%i5*n", prevamp, amp)
      noteon := TRUE
      // A note has just started so add an event if it was expected
      { // Loop to find earliest expected note with midi time > mmsecs
        notep := notep+1
        IF notep>noteupb BREAK
        IF notetimes!notep > mmsecs DO
        { dmsecs := notetimes!notep - mmsecs
          BREAK
        }
      } REPEAT

      IF notep>1 & mmsecs - notetimes!(notep-1) < dmsecs DO
      { notep := notep-1
        dmsecs := notetimes!notep - mmsecs
      }
      writef("%9.3d: mmsecs=%9.3d err %9.3d  notep=%i2 %s*n",
              rmsecs, mmsecs, dmsecs, notep, notename)
      // If the expected note is within a second of now add it
      // to the set of events. Its weight is its amplitude.
      IF -1_000 <= dmsecs <= 1_00 DO addevent(mmsecs, rmsecs, amp, note)
    }

    IF amp<1200 IF noteon DO
    { //writef("%9.3d: %s off", rmsecs, notename)
      //writef("  prevamp=%i5  amp=%i5*n", prevamp, amp)
      noteon := FALSE
    }
    //newline()
//abort(1000)
    prevamp := amp
    rmsecs := cowait(amp)
  }

  // We have been told to die
  IF notetimes DO freevec(notetimes)
  die()
}

AND setfreqtab() BE
{ // Set freqtab so that freqtab!n = 1000 * the note frequency
  // where n is the MIDI note number. n=60 for middle C (C4).

  freqtab := TABLE
     8_176,   8_662,   9_178,   9_723,  10_301,  10_914, //   0 -c.. -b
    11_563,  12_250,  12_979,  13_750,  14_568,  15_434,

    16_352,  17_324,  18_355,  19_446,  20_602,  21_827, //  12 0c .. 0b
    23_125,  24_500,  25_957,  27_500,  29_136,  30_868,

    32_703,  34_648,  36_709,  38_891,  41_204,  43_654, //  24 1c .. 1b
    46_250,  49_000,  51_914,  55_000,  58_271,  61_736,
  
    65_406,  69_296,  73_417,  77_782,  82_407,  87_308, //  36 2c .. b2
    92_499,  97_999, 103_827, 110_000, 116_541, 123_471,

   130_812, 138_592, 146_833, 155_564, 164_814, 174_615, //  48 3c .. 3b
   184_998, 195_998, 207_653, 220_000, 233_082, 246_942,

   261_623, 277_183, 293_665, 311_127, 329_628, 349_229, //  60 4c .. 4b
   369_995, 391_996, 415_305, 440_000, 466_164, 493_884,

   523_245, 554_366, 587_330, 622_254, 659_255, 698_457, //  72 5c .. 5b
   739_989, 783_991, 830_610, 880_000, 932_328, 987_767,

  1046_489,1108_731,1174_659,1244_508,1318_510,1396_913, //  84 6c .. 6b
  1479_978,1567_982,1661_219,1760_000,1864_655,1975_533,

  2092_978,2217_461,2349_318,2489_016,2637_020,2793_826, //  96 7c .. 7b
  2959_955,3135_963,3322_438,3520_000,3729_310,3951_066,

  4185_955,4434_922,       0,       0,       0,       0, // 108 8c .. 8b
         0,       0,       0,       0,       0,       0,

         0,       0,       0,       0,       0,       0, // 120 9c .. 9g
         0,       0

//writef("freqtab=%n*n", freqtab)
  // Check the table
  checktab( 98, 2349_318)
  checktab( 99, 2489_016)
  checktab(100, 2637_020)
  checktab(101, 2793_826)
  checktab(102, 2959_955)
  checktab(103, 3135_963)
  checktab(104, 3322_438)
  checktab(105, 3520_000)
  checktab(106, 3729_310)
  checktab(107, 3951_066)
  checktab(108, 4185_955)
  checktab(109, 4434_922)
}

AND checktab(n, f) BE WHILE n>=0 DO
  { UNLESS freqtab!n = f DO
    { writef("note=%i3 change %8.3d to %8.3d*n", n, freqtab!n, f)
      abort(1000)
    }
    n, f := n-12, (f+1)/2
  }

AND findtimes(note) = VALOF
{ LET upb, v = 0, 0 // A self expanding vector
  LET p = midilist  // List of midi triples
  LET solo_note_on = midi_note_on + solochannel - 1
  LET stop_msecs = end_msecs + 1_000 // Stop 1 second after end_msecs
  LET notename = VEC 1
  note2str(note, notename)

  UNLESS solochannel RESULTIS 0

  WHILE p DO
  { LET op, a1, a2 = ?, ?, ?
    LET triple = p!2
    LET msecs = p!1 // Time of next midi event
    p := !p

    UNLESS (triple & 255) = solo_note_on LOOP

    IF msecs>stop_msecs BREAK
    IF msecs<start_msecs LOOP

    a1 := (triple>> 8) & 255  // The solo note number
    a2 := (triple>>16) & 255  // The solo note pressure

    UNLESS a1 = note LOOP

    pushval(@upb, msecs)
    writef("%9.3d %s*n", msecs, notename)
  }
  RESULTIS v
}

AND addevent(mt, rt, weight, note) BE
{ LET str = VEC 2
  writef("addevent: %9.3d %9.3d weight=%i5  note=%s*n",
          mt, rt, weight, note2str(note, str))
}

AND calcrates() BE IF real_msecs >= calc_msecs DO
{ LET m, r, w, corr = 0, 0, 0, 0
  // Calculate new rates no more than 10 times per second
  calc_msecs := real_msecs + 100
  newevents := FALSE
  // Calculate weighted average of (mmsecs, rmsecs) pairs in eventv
  FOR i = 0 TO eventvupb BY 4 DO
  { LET event = @eventv!i // => [ mt, rt, weight, op]
    LET mt, rt, weight = event!0, event!1, event!2
    // Only consider events that occurred within the last 2 seconds
    IF rt < real_msecs - 2_000 LOOP
    writef("event: midi+%9.3d real=%9.3s weight=%n*n", mt, rt, weight)
    m := m + mt*weight
    r := r + rt*weight
    w := w + weight
  }
  // Calculate the centre of gravity
  IF w DO m, r := m/w, r/w

  writef("CG midi=%9.3d real=%9.3d*n", m, r)

  // Choose a good line through the centre of gravity point (r, m)
  FOR i = 0 TO eventvupb BY 4 IF eventv!i DO
  { LET event = @eventv!i
    LET mt, rt, weight = event!0, event!1, event!2
    // Only consider events that occurred within the last 2 seconds
    IF rt < real_msecs - 2_000 LOOP
    corr := corr + muldiv(rt-r, play_rate, 1000)*weight
  }
  IF w DO corr := corr / w
  play_rate := play_rate + corr // Add the average correction
  // Limit the play rate to no more than a factor of 2 from 1.000 
  IF play_rate>2_000 DO play_rate := 2_000
  IF play_rate<0_500 DO play_rate := 0_500
  play_offset := r - muldiv(m, 1000, play_rate)
  // Set a current rate to correct the error in 1 real second
  curr_rate := play_rate - r2m_msecs(r, curr_rate, curr_offset)
  // Limit the correction rate to no more than a factor of 3 from 1.000 
  IF curr_rate>3_000 DO curr_rate := 3_000
  IF curr_rate<0_333 DO curr_rate := 0_333
  curr_offset := r - muldiv(midi_msecs, 1000, curr_rate)
  revert_msecs := real_msecs + 1_000
  writef("play_rate=%9.3d play_offset=%9.3d*n", play_rate, play_offset)
  writef("curr_rate=%9.3d curr_offset=%9.3d*n", curr_rate, curr_offset)
  writef("revert_msecs=%9.3d*n", revert_msecs)
  abort(1000)
}

AND soundcofn(arg) BE
{ // Coroutine to read some microphone data
  LET soundv1024 = soundv + 1024
  LET soundvtop = soundv + soundvupb - 1024

  LET len = sys(Sys_sound, snd_waveInRead, micfd, micbuf, micbufupb+1)
    // micbuf contains signed 32-bit signed mono samples

  soundp := soundvupb

  UNLESS len DO
  { // if no sound data wait for more
    cowait(0)
    LOOP
  }

  UNLESS len=1024 DO
  { writef("Error: waveInRead returned %n samples*n", len)
  }

  // Some sound data is available
  // Get the current real time
  soundmsecs := getrealmsecs()

  FOR i = 0 TO soundvupb - 1024 DO soundv!i := soundv1024!i

  // Accummulate the samples in soundv
  FOR i = 0 TO len-1 DO
  { soundval := soundval + micbuf!i
    //IF i MOD 8 = 0 DO writef("*n%i4: ", i)
    //writef(" %i6", micbuf!i)
    soundvtop!i := soundval
  }
  //  newline()
  //writef("soundco: new data %9.3d*n", soundmsecs)
} REPEAT


AND playmidicofn(arg) BE
{ // This is the body of playmidico which is called by the clock loop
  // every time midi_msecs >= nextmidi_msecs

  LET midip = midilist

//  writef("playmidico: called arg=%n*n", arg)

  { // Main loop

    WHILE midip DO
    { // Output all midi triples that are now due
      LET mt = midip!1 // Midi time of next midi triple
      LET rt = m2r_msecs(mt, curr_rate, curr_offset)

      //IF mt > stop_msecs BREAK

//writef("%9.3d playmidico: mt=%9.3d  rt=%9.3d*n", real_msecs, mt, rt)
      IF rt <= real_msecs DO
      { // This midi triple is now due so output it.
        LET triple = midip!2
        LET op =  triple      & 255
        LET chan = (op & #x0F) + 1
        LET a1 = (triple>> 8) & 255
        LET a2 = (triple>>16) & 255
        LET is_note_on = (op&#xF0)=midi_note_on
        midip := !midip
//writef("%9.3d playmidico: triple %2x %2x %2x*n", real_msecs, op, a1, a2)

        IF chan=solochannel LOOP

        // Output the midi triple except note_on commands are only output
        // if mt is between start_msecs and end_msecs.
        TEST is_note_on
        THEN wrmid3(mt, op, a1, a2)
        ELSE IF start_msecs < mt <= end_msecs DO wrmid3(mt, op, a1, a2)

        LOOP
      }

//writef("%9.3d playmidico: end of performance*n", real_msecs)
      cowait(0)      // Wait to be given control
    }

    // End of performance #################
    cowait(0) REPEAT
  }
}

AND keycofn(arg) BE
{ // Coroutine to read the keyboard
  LET ch = sys(Sys_pollsardch)

  SWITCHON ch INTO
  { DEFAULT:
      writef("key %i3 '%c'*n", ch, ch)
      LOOP

    CASE 'b':CASE 'B':
    { LET mt = r2m_msecs(real_msecs - 180, curr_rate, curr_offset)
      LET bno = msecs2barno(mt)
      LET bms = 0
      LET err = ?
      LET bms1 = barmsecs!(bno)
      LET bms2 = barmsecs!(bno+1)
      TEST mt < (bms1+bms2)/2
      THEN bms := bms1
      ELSE bno, bms := bno+1, bms2
      sawritef("%9.3d: bar %i3  midi_msecs=%9.3d err = %6.3d msecs*n",
                mt, bno, bms, mt-bms)
      LOOP
    }

    CASE '*s': // Nearest beat
    { LET rt = getrealmsecs() - rmsecs0 - 180
      LET bms = 0
      LET beatno = msecs2beatno(rt)
      LET b, bno, err = 1, ?, ?
      LET bms1 = beatmsecs!beatno
      LET bms2 = beatmsecs!(beatno+1)
      TEST rt < (bms1+bms2)/2
      THEN bms := bms1
      ELSE beatno, bms := beatno+1, bms2
      bno := msecs2barno(beatmsecs!beatno)
      FOR i = 0 TO 32 IF beatmsecs!(beatno-i)<=barmsecs!bno DO
      { b := i+1
        BREAK
      }
      sawritef("%9.3d: beat %i3/%i3  midi_msecs=%9.3d err=%6.3d msecs*n",
                rt, bno, b, bms, rt-bms)
      LOOP
    }

    CASE '+':
    CASE '=':
      IF curr_rate+50 <= 3_000 & play_rate+50 <= 2_000 DO
      { LET mt = r2m_msecs(real_msecs, curr_rate, curr_offset)
        curr_rate := curr_rate + 50
        curr_offset := real_msecs - muldiv(mt, 1000, curr_rate)
        mt := r2m_msecs(real_msecs, play_rate, play_offset)
        play_rate := play_rate + 50
        play_offset := real_msecs - muldiv(mt, 1000, play_rate)
      }
      writef("curr_rate=%9.3d  play_rate=%9.3d*n", curr_rate, play_rate)
      LOOP

    CASE '-':
    CASE '_':
      IF curr_rate-50 >= 0_333 & play_rate-50 >= 0_500 DO
      { LET mt = r2m_msecs(real_msecs, curr_rate, curr_offset)
        curr_rate := curr_rate - 50
        curr_offset := real_msecs - muldiv(mt, 1000, curr_rate)
        mt := r2m_msecs(real_msecs, play_rate, play_offset)
        play_rate := play_rate - 50
        play_offset := real_msecs - muldiv(mt, 1000, play_rate)
      }
      writef("curr_rate=%9.3d  play_rate=%9.3d*n", curr_rate, play_rate)
      LOOP

    CASE -3: // No keyboard character available
      ENDCASE
  }
  cowait(0)
} REPEAT



AND playmidi(midilist) BE
{ LET midiname = "/dev/midi"
  LET micname = "/dev/dsp1"
  LET micformat = 16 // S16_LE
  LET micchannels = 1 // Mono
  LET micrate = 44100 // Mic samples per second
  LET stop_msecs = end_msecs + 1_000 // Stop 1 midi second after end_msecs
  LET stdout = output()
  LET midi_msecs = 0
  LET nval = 0
  LET mb = VEC micbufupb

  // Initialise baseday for getrealmsecs
  LET days, msecs = 0, 0
  sys(Sys_datstamp, @days)
  baseday := days

  play_rate := tempoadj
  play_offset := getrealmsecs()
  curr_rate := play_rate
  curr_rate := play_rate

  soundco := createco(soundcofn, 1000)
  playmidico := createco(playmidicofn, 1000)
  keyco :=  createco(keycofn, 1000)

IF FALSE DO
{ writef("Testing r2m_msecs and m2r_msecs*n")
  FOR i = 1 TO 3 DO
  { LET rt = getrealmsecs()
    LET mt = r2m_msecs(rt, curr_rate, curr_offset)
    writef("curr_offset=%9.3d rate=%9.3d rt=%9.3d mt=%i5*n",
            curr_offset, curr_rate, rt, mt)
    writef("calling m2r_msecs*n")
    rt := m2r_msecs(mt, curr_rate, curr_offset)
    writef("curr_offset=%9.3d rate=%9.3d rt=%9.3d mt=%i5*n",
            curr_offset, curr_rate, rt, mt)
    msdelay(500)
    curr_rate := muldiv(curr_rate, 1_100, 1_000)
  }
  abort(1000)
}

  micbuf := mb
  setfreqtab()

  notecov := getvec(127)
  notecoupb := 0 // No note coroutines yet

  FOR note = 0 TO 127 DO notecov!note := 0
  FOR note = 0 TO 127 IF 24<=note<=96 DO // 1C to 7C
  { LET notetimes = findtimes(note)
    // Only create note coroutines for notes played by the solist
    IF notetimes DO
    { notecoupb := notecoupb+1
      notecov!notecoupb := initco(notecofn, 1000, note, notetimes)
    }
  }
  notecop := 1 // Position in notecov of first coroutine, if any.

  midifd, micfd := 0, 0

  // Allocate the vector to hold the cummulative sound samples
  soundv := getvec(soundvupb)

  UNLESS soundv DO
  { writef("*nUnable to allocate soundv*n")
    abort(999)
  }

  FOR i = 0 TO soundvupb DO soundv!i := 0
  soundp, soundval := 0, 0

  //writef("*nsolo channel is %n*n", solochannel)

  UNLESS sys(Sys_sound, snd_test) DO
  { writef("The sound functions are not available*n")
    RETURN
  }

  // Open the Midi output device
  midifd := sys(Sys_sound, snd_midiOutOpen, midiname)

  UNLESS midifd>0 DO
  { writef("Unable to open the Midi device*n")
    GOTO fin
  }

  // Open the Microphone input device
  micfd := sys(Sys_sound, snd_waveInOpen, micname,
               micformat, micchannels, micrate)

  UNLESS micfd>0 DO
  { writef("Unable to open the Microphone device, rc=%n*n", micfd)
    GOTO fin
  }

  real_msecs := getrealmsecs()

  FOR chan = 0 TO 15 DO
    wrmid3(midi_msecs, midi_controlchange+chan, #x7B, 0)// Allnotes off
  FOR chan = 0 TO 15 DO
    wrmid3(midi_msecs, midi_controlchange+chan, #x79, 0)// Allnotes off

//sawritef("Delaying for 500 msecs*n")
//  msdelay(500)
//sawritef("Delay done*n*n")

  // test microphone input
  IF FALSE DO
  { LET v = getvec(44100) // Buffer for 1 second of samples
    LET count = 0
    UNTIL count>=8195 DO
    { LET days, msecs = 0, 0
      LET hours, mins = 0, 0
      LET len = sys(Sys_sound, snd_waveInRead, micfd, micbuf, micbufupb+1)
      LET rt = getrealmsecs()
      hours := rt/(60*60*1000)
      mins  := rt/(60*1000) MOD 60
      msecs := rt MOD (60*1000)

      writef("len=%i5 %i2:%z2:%6.3d*n", len, hours, mins, msecs)
      //abort(1000)
      FOR i = 0 TO len-1 DO
      { LET w = micbuf!i // One signed 32-bit sample per element
        // Copy sample into v
        v!count := w
        count := count+1
        //IF i MOD 8 = 0 DO newline()
        //writef(" %i6", w)
      }
      //newline()
      msdelay(1)
      //abort(1000)
    }
    IF FALSE DO
    FOR i = 0 TO count-1 DO
    { IF i MOD 10 = 0 DO writef("*n%i5: ", i)
      writef(" %i6", v!i)
    }
    newline()
  }

  newevents := FALSE

  { // Start of main timer loop

    // Try to read some sound data into soundv
    callco(soundco, 1234)
    // If new sound data has been read mic_msecs will have been
    // set to the approximately real time of the latest sample.
    // mic_msecs is used by the note recognition coroutines.

    real_msecs := getrealmsecs()
    midi_msecs := r2m_msecs(real_msecs, curr_rate, curr_offset)

    IF real_msecs >= revert_msecs DO
    { curr_rate, curr_offset, revert_msecs := play_rate, play_offset, maxint
      // Re-calculate the current midi time
      midi_msecs := r2m_msecs(real_msecs, curr_rate, curr_offset)
    }

    // Test for end of performance
    IF midi_msecs>=stop_msecs BREAK

    // Output any outstanding midi triples if any are due
    callco(playmidico, 2345)

    // Process any keyboard input
    callco(keyco, 3456)

    // Process up to 5 note recognisers
    FOR i = 1 TO notecoupb DO
    { callco(notecov!notecop, 4567)
      notecop := notecop + 1
      IF notecop>notecoupb DO notecop := 1
      IF i>=5 BREAK
    }

    IF newevents DO
    { // New events are present so calculate new values for
      // play_offset, play_rate, curr_offset and curr_rate
      // based on the events in the eventv circular buffer
      calcrates(real_msecs)
    }

    msdelay(5) // Delay 5 msecs (=1/200 sec)
  } REPEAT

  // Delay to let all sound die down
  msdelay(1000)

  // Allnotes off all channels
  FOR chan = 0 TO 15 DO wrmid3(midi_msecs, midi_controlchange+chan, 123, 0)
  msdelay(500)

fin:
  IF soundco DO { deleteco(soundco); soundco := 0 }
  IF keyco   DO { deleteco(keyco);   keyco   := 0 }
  FOR i = 1 TO notecoupb DO { deleteco(notecov!i);   notecov!i   := 0 }

  IF midifd>0 DO
    sys(Sys_sound, snd_midiOutClose, midifd) // Close the midi output device
  IF micfd>0 DO
    sys(Sys_sound, snd_waveInClose, micfd)   // Close the microphone device
  selectoutput(stdout)
  writef("*nEnd of performance*n")
}

AND r2m_msecs(realmsecs, rate, offset) = VALOF
{ // Convert real time msecs to midi msecs
  // rate is the number of midi msecs per real second
  // offset is the real time in msecs at midi time zero
  LET mt = muldiv(realmsecs-offset, rate, 1000)
  //writef("r2m_msecs: offset=%9.3d diff=%9.3d rate=%9.3d*n",
  //        offset, realmsecs-offset, rate)
  RESULTIS mt
}

AND m2r_msecs(midi_msecs, rate, offset) = VALOF
{ // Convert midi msecs to real time
  // rate is the number of midi msecs per real second
  // offset is the real time in msecs at midi time zero
  LET rt = offset + muldiv(midi_msecs, 1000, rate)
  RESULTIS rt
}

AND msecs2barno(m_msecs) = VALOF
{ IF currbarno<1 DO currbarno := 1
  IF currbarno>maxbarno DO currbarno := maxbarno
  WHILE m_msecs > barmsecs!currbarno DO currbarno := currbarno+1
  WHILE m_msecs < barmsecs!currbarno DO currbarno := currbarno-1
  RESULTIS currbarno
}

AND msecs2beatno(m_msecs) = VALOF
{ IF currbeatno<1 DO currbeatno := 1
  IF currbeatno>maxbeatno DO currbeatno := maxbeatno
  WHILE m_msecs > beatmsecs!currbeatno DO currbeatno := currbeatno+1
  WHILE m_msecs < beatmsecs!currbeatno DO currbeatno := currbeatno-1
  RESULTIS currbeatno
}

AND msdelay(msecs) BE IF msecs>0 DO
{ deplete(cos)
  sys(Sys_delay, msecs)
}

AND wrmid1(t, a) BE
{ IF optMtrace DO writef(" %7.3d: %x2*n", t, a)
  sys(Sys_sound, snd_midiOutWrite1, midifd, a)
}

AND wrmid2(t, a, b) BE
{ IF optMtrace DO writef(" %7.3d: %x2 %x2*n", t, a, b)
  sys(Sys_sound, snd_midiOutWrite2, midifd, a, b)
}

AND wrmid3(t, a, b, c) BE
{ IF optMtrace DO
  { LET op = a & #xF0
    LET chan = (a & #x0F) + 1
    writef(" %9.3d  %7.3d: %x2 %x2 %x2", real_msecs, t, a, b, c)
    IF op = #x90 DO
      writef("  chan %i2 On  %t4 vol %n", chan, note2str(b, strv), c)
    IF op = #x80 DO
      writef("  chan %i2 Off %t4", chan, note2str(b, strv))
    newline()
  } 
  sys(Sys_sound, snd_midiOutWrite3, midifd, a, b, c)
}

AND prmidilist(list) BE WHILE list DO
{ writef("%9.3d: %x8*n", list!1, list!2)
  list := !list
}

AND note2str(n, str) = VALOF
{ // Convert a midi note number to a string (in str)
  // returning str as result.
  // eg note2str(61, str) => "4C#"
  LET oct = n/12 - 1 // 60 to 71 are in octave 4
  LET s = VALOF SWITCHON n MOD 12 INTO
  { DEFAULT: RESULTIS "??"
    CASE  0: RESULTIS "C "
    CASE  1: RESULTIS "C#"
    CASE  2: RESULTIS "D "
    CASE  3: RESULTIS "Eb"
    CASE  4: RESULTIS "E "
    CASE  5: RESULTIS "F "
    CASE  6: RESULTIS "F#"
    CASE  7: RESULTIS "G "
    CASE  8: RESULTIS "Ab"
    CASE  9: RESULTIS "A "
    CASE 10: RESULTIS "Bb"
    CASE 11: RESULTIS "B "
  }
  str%0 := 3
  str%1 := oct>=0 -> oct + '0', '-'
  str%2 := s%1
  str%3 := s%2
  
  RESULTIS str
}

AND editnoteoffs(list) = VALOF
{ // list is a list of sorted midi triples
  // This function removes note off events from the list
  // that would stop a note that should not yet be stopped
  // because of multiple note on events for that note

  LET p = @list
  // Allocate 16 vectors each of size 128 to hold counts for each
  // channel of how many times notes have be started but not yet
  // stopped.
  LET notecountv = VEC 16*128 // Notes currently playing
  FOR i = 0 TO 16*128 DO notecountv!i := 0

  WHILE !p DO
  { LET node = !p  // node is the next midi triple
    LET w = node!2
    LET op   = w & #xF0

    SWITCHON op INTO
    { DEFAULT: ENDCASE

      CASE midi_note_on:
      CASE midi_note_off:
      { LET chan = w & #x0F
        LET n = (w>>8) & #x7F
        LET i = chan<<7 | n
        LET count = notecountv!i
//writef("editnoteoffs: %x2 %x2 %x2 count=%n*n",
//        w&#xFF, w>>8 & #xFF, w>>16 & #xFF, count)

        TEST op=midi_note_on
        THEN notecountv!i := count+1
        ELSE { // Decrement the count
               notecountv!i := count-1
               IF count>1 DO
               { // Remove the triple from the list
//writef("removed*n")
                 !p := !node
                 unmk3(node)
                 LOOP
               }
             }
      }
    }
    p := node
  }

  FOR chan = 0 TO 15 FOR n = 0 TO 127 IF notecountv!(chan<<7 | n) DO
    writef("System error: unmatched note off events chan=%n note=%n*n",
            chan, n)
  RESULTIS list
}

AND mergesort(list1) = VALOF
{ LET p, a, list2 = list1, list1, list1
//writef("*nmergesort:*n"); prmidilist(list1)
  UNLESS list1 & !list1  RESULTIS list1 // No sorting to do

  // list1 has at leat 2 elements

  // Split list1 into two halves list1 and list2
  { a := list2
    list2 := !list2
    p := !p
    IF p=0 BREAK
    p := !p
  } REPEATWHILE p

  !a := 0  // Terminate the left hand list
//writef("*nmergesort: list1*n"); prmidilist(list1)
//writef("*nmergesort: list2*n"); prmidilist(list2)
  RESULTIS mergelist(mergesort(list1), mergesort(list2))
}

AND mergelist(p, q) = VALOF
{ LET res = 0
  LET rese = @res

  UNLESS p RESULTIS q
  UNLESS q RESULTIS p

//writef("*nmergelist: p*n"); prmidilist(p)
//writef("mergelist: q*n"); prmidilist(q)

  { TEST p!1 <= q!1
    THEN { !rese := p
           rese := p
           p := !p
           IF p=0 DO { !rese := q; BREAK }
         }
    ELSE { !rese := q
           rese := q
           q := !q
           IF q=0 DO { !rese := p; BREAK }
         }
  } REPEAT

//writef("mergelist: res*n"); prmidilist(res)
  RESULTIS res
}

