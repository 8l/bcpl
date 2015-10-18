/*
Still under development.

This is a program intended to read a .mus representation of a score
and write a corresponding MIDI file and/or play it on a MIDI device
possibly synchronising the accompanement with the solist, if any.


Implemented by Martin Richards (c) July 2011

Change history

01/09/11
Play lines now have an origin such as (oer, oem) giving a point in the
real-time midi-time graph through which the play line passes and a
rate such as erate giving the slope in midi msecs per real second.
The estimated play line based on recent microphone and keyboard events
is represented by oer, oem and erate. The current play line is
represented by ocr, ocm and crate. Both are updated about 20 times per
second and the values of ocr, ocm and crate are chosen to cause the
current play line to approach the estimated play line reasonably
quickly.

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

LET appendmus(str, name) = VALOF
{ // Append .mus if no extension
  LET strlen = str%0
  LET namelen = 0
  LET dots = FALSE

  FOR i = 1 TO str%0 DO
  { LET ch = str%i
    IF ch='.' DO dots := TRUE
    namelen := namelen+1
    name%namelen := ch
  }

  UNLESS dots DO
  { // Append .mus
    LET ext = ".mus"
    FOR i = 1 TO ext%0 DO
    { LET ch = ext%i
      namelen := namelen+1
      name%namelen := ch
    }
  }

  name%0 := namelen
  //writef("appendmus: %s => %s*n", str, name)
  RESULTIS name
}

LET start() = VALOF
{ LET argv = VEC 50
  LET fromname = VEC 50
  LET toname = 0
  LET midifilename = 0
  LET play = FALSE
  LET bartabcbupb,  bartabcbv  = 0, 0  // Self expanding bar table
  LET beattabcbupb, beattabcbv = 0, 0  // Self expanding beat table
  LET b   = VEC 64
  LET bln = VEC 64
  AND s1  = VEC 10
  AND s2  = VEC 10
  AND dbv = VEC 9

  playmus_version := "Playmus v2.1" // Used here and in writemidi.

  writef("*n%s 25/07/2011 14:22*n", playmus_version)

  appendmus("mus/tst", fromname)

  chbuf   := b
  chbufln := bln
  FOR i = 0 TO 63 DO chbuf!i, chbufln!i := 0, 0
  chcount := 0

  strv, fnolnstrv := s1, s2         // Short term string buffer
  debugv := dbv
  FOR i = 0 TO 9 DO debugv!i := FALSE

debugv!1 := TRUE

  bartabcb,  barmsecs  := @bartabcbupb,  0
  beattabcb, beatmsecs := @beattabcbupb, 0
  bartab, beattab := 0, 0

  soundv, soundp := 0, 0
  veclist := 0

  baseday := -1 // This will be initialised by first call of getrealmsecs
  chanvol := -1
  variablevol := FALSE

  killco := createco(deleteco, 500)

  errcount, errmax := 0, 5
  fin_p, fin_l := level(), fin
  rec_p, rec_l := fin_p, fin_l

  bg_baseupb := 100_000    //Default work space size for bgpm.
  startbarno, endbarno := 1, maxint/2
  start_msecs, end_msecs := 0, maxint
  solochannels := 0  // No soloists yet
  quitting := FALSE

  sysin := input()
  sysout := output()

  bg_base := 0              // Base of BGPM workspace
  sourcestream := 0
  getstreams := 0
  tostream := 0
  bgpmco := 0
  conductorblk := 0

  // Space for parse tree, shape data, note data, etc.
  blklist, blkb, blkp, blkt, blkitem := 0, 0, 0, 0, 0
  // Initialise the freelists
  mk1list, mk2list, mk3list, mk4list, mk5list := 0, 0, 0, 0, 0
  mk6list, mk7list, mk8list, mk9list          := 0, 0, 0, 0

  sourcefileupb := 1000
  sourcenamev := newvec(sourcefileupb)
  UNLESS sourcenamev DO
  { writef("Insufficient space available*n")
    GOTO fin
  }
  sourcefileno := 1
  FOR i = 0 TO sourcefileupb DO sourcenamev!i := "unknown"   

  // Sourcefile 1 is "built-in" used during initialisation.
  // Sourcefile 2 is always the FROM filename
  // Higher numbers are GET files
  lineno := (1<<20) + 1
  nextlineno := lineno
  plineno := 0

  msecsbase := -1
  oer, oem, erate := getrealmsecs(), 0, 1000
  ocr, ocm, crate := oer, oem, erate
  bg_baseupb := 100_000
 
  UNLESS rdargs("FROM,START/N,END/N,TADJ/N,TO/K,UPB/K/N,*
                *PP/S,LEX/S,TREE/S,PTREE/S,STRACE/S,NTRACE/S,MTRACE/S,*
                *MIDI/K,PLAY/S,ACC/S,PITCH/N,GD/S,WAIT/S,Calib/S", argv, 50) DO
     fatalerr("Bad arguments for PLAYMUS*n")

  pitch := 0

  IF argv!0 DO appendmus(argv!0, fromname) // FROM
  IF argv!1 DO startbarno := !(argv!1)  // START  -- First bar to play
  IF argv!2 DO endbarno   := !(argv!2)  // END    -- Last bar to play
  IF argv!3 DO erate      := !(argv!3)  // TADJ   -- Tempo adjustment
  IF argv!4 DO toname     := argv!4     // TO
  IF argv!5 DO bg_baseupb := !(argv!5)  // UPB    -- BGPM space
  optPp     := argv!6                   // PP     -- Print macrogenerated text 
  optLex    := argv!7                   // LEX    -- Trace lexical tokens
  optTree   := argv!8                   // TREE   -- Print init parse tree
  optPtree  := argv!9                   // PTREE  -- Print part trees
  optStrace := argv!10                  // STRACE -- Syn trace
  optNtrace := argv!11                  // NTRACE -- Note tracing
  optMtrace := argv!12                  // MTRACE -- Midi tracing playing
  IF argv!13 DO midifilename := argv!13 // MIDI   -- Midi output filename
  play := argv!14                       // PLAY   -- Play the midi data
  accompany := argv!15                  // ACC    -- Accompany listen to the
                                        //        -- microphone and keyboard
  IF argv!16 DO pitch := !(argv!16)     // PITCH  -- Change pitch
  graphdata := argv!17                  // GD     -- Generate graph data
  waiting := argv!18                    // WAIT   -- Wait before playing
  calibrating := argv!19                // CALIB  -- Calibrate Midi-Mic delay

  IF accompany DO play := TRUE

  IF bg_baseupb<5000 DO bg_baseupb := 5000
  bg_base := getvec(bg_baseupb)    // BGPM workspace
  UNLESS bg_base DO
    fatalerr("Unable to allocate work space (upb = %n)*n", bg_baseupb)

  sourcenamev!1 := "built-in"
  sourcefileno  := 1

  { LET len = fromname%0
    LET str = newvec(len/bytesperword)
    IF str FOR i = 0 TO len DO str%i := fromname%i
    sourcefileno := sourcefileno+1
    sourcenamev!sourcefileno := str
  }

  sourcestream := findinput(fromname)
  lineno := (sourcefileno<<20) + 1
  nextlineno := lineno

  UNLESS sourcestream DO fatalerr("Unable to read file %s*n", fromname)

  tostream := sysout
  IF toname DO
  { tostream := findoutput(toname)
    UNLESS tostream DO fatalerr("Unable to write to file %s*n", argv!1)
  }

  bgpmco := createco(bgpmfn, 2000)

  UNLESS bgpmco DO fatalerr("Unable to create bgpmco*n")

  IF midifilename DO
  { LET len = midifilename%0
    UNLESS len>4 &
           midifilename%(len-3)='.' &
           midifilename%(len-2)='m' &
           midifilename%(len-1)='i' &
           midifilename%(len-0)='d' DO
    { writef("*nMidi file name *"%s*" must have .mid extension*n",
             midifilename)
      GOTO fin
    }
  }

  selectinput(sourcestream)
  selectoutput(tostream)

  IF optPp DO
  { // Test the output of BGPM
    LET prevlineno = 0

    { rch()
      IF ch=endstreamch BREAK

      UNLESS lineno=prevlineno DO
      { writef("<%n/%n>", lineno>>20, lineno & #xFFFFF)
        prevlineno := lineno
      }
      wrch(ch)
    } REPEAT
    newline()
    GOTO fin
  }

  rch()
 
  // Set the defaults so that the next note will be a
  // crotchet in octave 4 (middle C up to B).
  prevlengthnum := 4
  prevoctave, prevnoteletter := 4, 'f'

  tree := formtree()              // Perform Syntax Analysis

  IF optLex GOTO fin

  IF optTree DO { writes("*nTree before processing*n*n")
                  prtree(tree, 0, 20)
                  newline()
                }

  IF errcount GOTO fin

  //writef("*nCalling trscores*n*n")
  timesiga, timesigb := 4, 4
  qbeatsperbeat := 4096/timesigb // ie 1024 for crotchet beats
  beatcount := 1
  prevbeatqbeat := 0             // No beats yet
  currpartname := 0

  midilist := 0           // Initialist the list of midi items
  midiliste := @midilist  // Pointer to final link in the list
                          // used when appending midi items.

  currbarno := 1

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

  // Initialise the events list
  eventv := newvec(eventvupb)
  eventp := 0
  prevrt := 0
  FOR i = 0 TO eventvupb DO eventv!i := 0

  IF midifilename DO writemidi(midifilename, midilist)

  IF play DO playmidi(midilist)

fin:
  writef("*nFiles:")
  FOR i = 1 TO sourcefileno DO
    writef(" <%n>=%s", i, sourcenamev!i)
  newline()

  WHILE veclist DO
  { //writef("fin: freeing veclist vector %n*n", veclist!1)
    freevec(veclist!1)
    veclist := !veclist
  }

//writef("start: freeing killco %n*n", killco)
  IF killco DO { deleteco(killco); killco := 0 }
//writef("start: freeing soundv %n*n", soundv)
  IF soundv DO { freevec(soundv);  soundv := 0 }
//writef("start: freeing bgpmco %n*n", bgpmco)
  IF bgpmco DO { deleteco(bgpmco); bgpmco := 0 }
  UNLESS sourcestream=sysin DO endread()
  UNLESS tostream=sysout    DO endwrite()
  selectinput(sysin)
  selectoutput(sysout)
  IF bg_base DO { freevec(bg_base); bg_base := 0 }
  WHILE blklist DO
  { LET blk = blklist
    blklist := !blk
//writef("start: freeing blklist blk %n*n", blk)
    freevec(blk)
  }
//writef("Quitting playmus*n")
//abort(1000)
  RESULTIS 0
}

.

/*
This section implements the macrogenerator used by playmus.
It is a modification of GPM designed by Strachey (in 1964)
*/

SECTION "bgpm"

GET "libhdr"
GET "playmus.h"

LET prlineno(ln) BE
{ LET fno = ln>>20
  ln := ln & #xFFFFF
  writef("%s[%n]", sourcenamev!fno, ln)
//abort(1005)
}

LET bgputch(ch) BE
{ // ch may be a <fno/ln> item
  TEST bg_h=0
  THEN { IF ch >= (1<<20) DO
         { lineno := ch
           RETURN
         }
         cowait(ch)
       }
  ELSE { UNLESS plineno=lineno DO
         { plineno := lineno
           bgpush(lineno)
         }
         bgpush(ch)
       }
  RETURN
}

AND bgpush(ch) = VALOF
{ IF bg_t=bg_s DO bg_error("Insufficient work space")
  bg_s := bg_s + 1
  !bg_s := ch
  RESULTIS bg_s
}

AND bggetch() = VALOF
{ // This returns the next character from memory or an input file,
  // lineno is set to the <fno/ln> of the original source character.
  // <fno/ln> items occur whenever the line number changes and at the
  // start of every argument held in memory, except art the start of
  // the body of built in macros. lineno holds the <fno/ln> value of
  // the latest character from memory or file. For the newline character
  // it corresponds to the beginning of the next line.
  LET ch = ?
//writef("bggetch: called with bg_c=%n lineno=%x8*n", bg_c, lineno)
  TEST bg_c
  THEN { // Reading from memory
         bg_c := bg_c+1
         ch := !bg_c
         // Check for fno/ln number
         IF ch>=(1<<20) DO
         { lineno := ch
           nextlineno := lineno
           LOOP
         }
         RESULTIS ch
       } REPEAT
  ELSE { // Reading from file
         lineno := nextlineno
         ch := rdch()
         IF ch='*n' DO nextlineno := lineno+1

         { // Check for comment
           UNLESS ch=c_comment DO
           { //writef("[%n/%n]%c*n", lineno>>20, lineno & #xFFFFF, ch)
             RESULTIS ch
           }

           // Skip a bgpm comment. Ie skip characters
           // up to and including the newline and then skip
           // to the next non white space character. 
           { // Skip over the current line
             lineno := nextlineno
             ch := rdch()
             IF ch=endstreamch RESULTIS ch
             IF ch='*n' DO
             { nextlineno := lineno + 1
               BREAK
             }
           } REPEAT

           { // Skip over white space
             lineno := nextlineno
             ch := rdch()
             IF ch='*s' | ch='*t' LOOP
             IF ch='*n' DO
             { nextlineno := lineno+1
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
//writef("lookup: <%n/%n> looking up *"%s*"*n",
//        lineno>>20, lineno&#xFFFFF, arg2str(name, buf))

  WHILE a DO
  { LET p = name
    LET q = @a!2
    LET pe, qe = p+!p, q+!q

    { LET ch1 = s_eom
      LET ch2 = s_eom
      // Skip over fno/ln items
      WHILE p<pe DO
      { p := p+1
        ch1 := !p
        IF ch1<=255 BREAK
      }
      // Skip over fno/ln items
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
{ // Convert and argument to s string removing <fno/ln> items.
  LET len = !a
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
{ // Define a built in macro.
  LET s1 = bg_s
//sawritef("define: Defining %s S=%n T=%n E=%n*n", name, bg_s, bg_t, bg_e)
  bgpush(bg_e)  // Save the old environment pointer
  bgpush(bg_t)  // and t
  // Push the macro name onto the stack
  bgpush(name%0+1)
  bgpush((1<<20) + 1) // Special <fno/ln> number for built-in macros
  FOR i = 1 TO name%0 DO bgpush(name%i)
  bgpush(1)           // The bodies of built in macros have no <fno/ln> item.
  bgpush(code)        // The built-in macro code -- a negative number.
  bgpush(s_eom)       // This marks the end of the argument list.
  UNTIL bg_s=s1 DO { !bg_t := !bg_s; bg_t, bg_s := bg_t-1, bg_s-1 }
  bg_e := bg_t+1    // Set the new environment pointer 
//sawritef("define: Defined  %s S=%n T=%n E=%n*n", name, bg_s, bg_t, bg_e)
//abort(1001)
}

AND bgpmfn() BE
{ // This is the main function of bgpmco which generates the sequence
  // of characters of the macro expansion of its source file.
  // It passes the expanded text to the lexical analyser by call
  // of cowait(ch), and maintains lineno to always hold the <fno/ln>
  // number of the latest character passed.

  rec_p, rec_l := level(), ret

  bg_s, bg_t, bg_h, bg_p := bg_base-1, bg_base+bg_baseupb, 0, 0
  bg_f, bg_e, bg_c       := 0, 0, 0

  define("def",     s_def)
  define("set",     s_set)
  define("get",     s_get)
  define("eval",    s_eval)
  define("lquote",  s_lquote)
  define("rquote",  s_rquote)
  define("comment", s_comment)
  define("eof",     s_eof)
  define("char",    s_char)
  define("rep",     s_rep)
  define("rnd",     s_rnd)
  define("urnd",    s_urnd)

  // lineno is initially set to the <fno/ln> value corresponding to
  // the first line of the FROM file.

  { // Start of main scanning loop.

//writef("bgpmfn: calling bggetch()*n")
    bg_ch := bggetch()

    // bg_ch is the next character to scan.
    // lineno is its <fno/ln> value.

//writef("bgpmfn: bg_ch=%x8*n", bg_ch)
sw:

//writef("bgpmfn: ch=%x8 ", bg_ch)
//IF 32<=bg_ch<=127 DO writef("'%c' ", bg_ch)
//IF bg_ch<0        DO writef(" %i3 ", bg_ch)
//writef(" <%n/%n>*n", lineno>>20, lineno & #xFFFFF)
//abort(1009)

    SWITCHON bg_ch INTO
    { DEFAULT:
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
           lineno       := h3!getstreams // <fn0/ln> of ';' of $get!...;
           nextlineno   := lineno
           sourcestream := h2!getstreams
           getstreams   := h1!getstreams
           selectinput(sourcestream)
//writef("bgpm: eof sourcestream=%n <%n/%n>*n",
//        sourcestream, lineno>>20, lineno & #xFFFFF)
           LOOP

      CASE c_lquote:
         { LET d = 1
           { bg_ch := bggetch()
             IF bg_ch<0 DO bg_error("Non character in quoted text")
             IF bg_ch=c_lquote DO   d := d+1
             IF bg_ch=c_rquote DO { d := d-1; IF d=0 BREAK }
             bgputch(bg_ch)
           } REPEAT
           LOOP
         }

      CASE c_call:               // '$'
           bg_f := bgpush(bg_f)    // Position of start of new macro call
           bgpush(bg_h)            // Save start of previous arg start
           bgpush(?)               // Space for <fno/ln> of ';'
           bgpush(?)               // Space for e
           bgpush(?)               //       and t
           bg_h := bgpush(?)       // Start of zeroth arg of new call
           plineno := lineno
           bgpush(lineno)          // <fno/ln> value for this '$'
           LOOP

      CASE c_sep:                // '!'
           IF bg_h=0 DO          // ignore if not reading macro arguments
           { bgputch(bg_ch)
             LOOP
           }
           !bg_h := bg_s-bg_h    // Fill in the length of latest arg
           bg_h := bgpush(?)       // Length field for the new arg
           plineno := lineno
           bgpush(lineno)          // <fno/ln> number of the '!'
           LOOP

      CASE c_arg:                // '#'
         { LET lno = lineno      // Save the <fno/ln> of #dd
           IF bg_p=0 DO          // Ignore if not expanding a macro
           { bgputch(bg_ch)
             LOOP
           }
           bg_ch := bggetch()
           { // Read and integer and use it to find the start
             // of the corresponding macro argument
             LET a = arg(bg_p+5, rdint())

             // Copy the specified argument
             FOR q = a+1 TO a+!a DO
             { LET ch = !q
               IF ch >= (1<<20) DO { lineno := ch; LOOP }
               bgputch(ch)
             }
             lineno := lno    // Restore the <fno/ln> value of the #dd.
             GOTO sw
           }
         }

      CASE c_apply:               // Apply (;)
         { LET a = bg_f

           IF bg_h=0 DO           // Ignore if not reading arguments
           { bgputch(ch)
             LOOP
           }

           !bg_h := bg_s-bg_h     // Fill in the length of the latest arg
           bgpush(s_eom)            // Append EOM marking end of args
           bg_f := a!0            // Restore previous start of call pointer
           bg_h := a!1            // Restore previous start of arg pointer
           a!0 := bg_p            // Save current state
           a!1 := bg_c
           a!2 := lineno          // Save <fno/ln> of ';'.
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
           lineno := bg_p!2          // Set <fno/ln> to that of ';'
           nextlineno := lineno
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
           lineno := bg_p!2          // previous <fno/ln>
           nextlineno := lineno
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
           //lineno := bg_p!2 // Use the fno/ln of the get call.
           // Remove fno/ln items from the file name
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
           nextlineno := lineno
           bg_c   := bg_p!1
           bg_p   := bg_p!0
           performget(filename)
           LOOP
         }

      CASE s_char:                    // $char!expression;
           bgputch(evalarg(1)/1000)
           GOTO ret

      CASE s_eval:                    // $eval!expression;
           bgwrnum(evalarg(1))
           GOTO ret

      CASE s_rep:                     // $rep!count!text;
         { LET a = arg(bg_p+5, 2)
           FOR k = 1 TO evalarg(1)/1000 DO
           { //writef("s_rep: k=%n*n", k)
//abort(1022)
             FOR q = a+1 TO a+!a DO
             { //writef("s_rep: q=%n lim=%n !q=%x8*n", q, a+!a, !q)
               bgputch(!q)
             }
           }
           GOTO ret
         }

      CASE s_rnd:                     // $rnd!expression;
                                      // Return a signed random number is
                                      //        in specified range
           bgwrnum(muldiv(randno(2_000_000)-1_000_000, evalarg(1), 1_000_000))
           GOTO ret

      CASE s_urnd:                    // $urnd!expression;
                                      // Return an unsigned random number is
                                      //        in specified range
           bgwrnum(muldiv(randno(1_000_000), evalarg(1), 1_000_000))
           GOTO ret
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
  LET musfilename = VEC 50
  LET stream = findinput(appendmus(filename, musfilename))
//  writef("Searching for *"%s*" in the current directory*n", musfilename)

  // Then try the headers directories
//  UNLESS stream DO writef("Searching for *"%s*" in MUSHDRS*n", musfilename)
  UNLESS stream DO stream := pathfindinput(musfilename, "MUSHDRS")

  UNLESS stream DO
  { bg_error("Unable to $get!%s;", musfilename)
    RETURN
  }

  IF sourcefileno>=sourcefileupb DO
  { bg_error("Too many GET files")
    RETURN
  }

  { LET len = musfilename%0
    LET str = newvec(len+4/bytesperword)
    IF str FOR i = 0 TO musfilename%0 DO str%i := musfilename%i
    sourcefileno := sourcefileno+1
    sourcenamev!sourcefileno := str
  }

  getstreams := mk3(getstreams, sourcestream, lineno)
  sourcestream := stream
  selectinput(sourcestream)
//writef("performget: old lno = <%n/%n>*n", lineno>>20, lineno&#xFFFFF)
  lineno := (sourcefileno<<20) + 1
  nextlineno := lineno
//writef("performget: new lno = <%n/%n>*n", lineno>>20, lineno&#xFFFFF)
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

    CASE '*'':
            { LET ch = getargch()
              bg_ch := getargch()
              RESULTIS ch*1000
            }

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
  nextlineno := lineno
  // Skip over fno/ln items
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
         chpos := chpos+3
       }
  ELSE { UNLESS '*s'<=ch<127 DO ch := '?'  // Assume 7 bit ASCII.
         wrch(ch)
         IF ch='*n' DO wrs(" ")
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
  writef("*n*n######### Error near <%n/%n>: ", lineno>>20, lineno & #xFFFFF)
  writef(mess, a, b, c)
  error()
  selectoutput(out)
}

AND error(mess, a, b, c) BE
{ LET out = output()
  selectoutput(sysout)
  wrs("*nIncomplete calls:*n")
  IF bg_f DO prcall(3, bg_f, bg_h, bg_s)
  wrs("Active macro calls:*n"); btrace(bg_p, 3)
  //wrs("*nEnvironment:*n");  wrenv(bg_e, 20)
  //wrs("######### End of error message*n")
  wrc('*n')

  errcount := errcount+1
  IF errcount >= errmax DO fatalerr("*nToo many errors")
  
  selectoutput(out)
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
  writef("<%n/%n>", lno>>20, lno & #xFFFFF)
 
  UNTIL a>=b DO { wrc(sep); wrarg(a)
                  a := a + !a + 1
                  sep := c_sep
                }
}

AND wrarg(a) BE
{ LET len = !a
  LET p = a+1
  LET q = p + len - 1
  TEST len>20
  THEN { FOR i = p TO p+9 IF !i<256 DO wrc(!i)
         wrs("...")
         FOR i = q-9 TO q IF !i<256 DO wrc(!i)
       }
  ELSE { FOR i = p TO q IF !i<256 DO wrc(!i)
       }
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
  blkp := p+n+1
  IF blkp>=blkt DO
  { LET v = getvec(blkupb) // Get some more space
//writef("newvec: allocation block %n upb %n*n", v, blkupb)
    UNLESS v & n<blkupb DO
    { LET out = output()
      selectoutput(sysout)
      writef("*nSystem error: newvec failure*n")
      selectoutput(out)
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
  //IF optStrace DO writef("%i6 -> newvec upb %n*n", p, n)
  RESULTIS p
}
 
AND mk1(a) = VALOF
{ LET p = newvec(0)
  p!0 := a
  RESULTIS p
}
 
AND mk2(a, b) = VALOF
{ LET p = newvec(1)
  p!0, p!1 := a, b
  RESULTIS p
}
 
AND mk3(a, b, c) = VALOF
{ LET p = mk3list
  TEST p
  THEN mk3list := !p  // Use a node from the mk3 free list
  ELSE p := newvec(2) // Allocate a new node
  p!0, p!1, p!2 := a, b, c
  RESULTIS p
}
 
AND mk4(a, b, c, d) = VALOF
{ LET p = newvec(3)
  p!0, p!1, p!2, p!3 := a, b, c, d
  RESULTIS p
}
 
AND mk5(a, b, c, d, e) = VALOF
{ LET p = newvec(4)
  p!0, p!1, p!2, p!3, p!4 := a, b, c, d, e
  RESULTIS p
}
 
AND mk6(a, b, c, d, e, f) = VALOF
{ LET p = newvec(5)
  p!0, p!1, p!2, p!3, p!4, p!5 := a, b, c, d, e, f
  RESULTIS p
}
 
AND mk7(a, b, c, d, e, f, g) = VALOF
{ LET p = newvec(6)
  p!0, p!1, p!2, p!3, p!4, p!5, p!6 := a, b, c, d, e, f, g
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

AND unmk1(p) BE { !p := mk1list; mk1list := p }
AND unmk2(p) BE { !p := mk2list; mk2list := p }
AND unmk3(p) BE { !p := mk3list; mk3list := p }
AND unmk4(p) BE { !p := mk4list; mk4list := p }
AND unmk5(p) BE { !p := mk5list; mk5list := p }
AND unmk6(p) BE { !p := mk6list; mk6list := p }
AND unmk7(p) BE { !p := mk7list; mk7list := p }
AND unmk8(p) BE { !p := mk8list; mk8list := p }
AND unmk9(p) BE { !p := mk9list; mk9list := p }
.

SECTION "lex"

GET "libhdr"
GET "playmus.h"

LET rch() BE
{ ch := callco(bgpmco)
//writef("*nrch: ch=%i3 <%n/%n>*n", ch, lineno>>20, lineno & #xFFFFF)
  UNLESS ch=endstreamch DO
  { chcount := chcount+1
    chbuf  !(chcount&63) := ch
    chbufln!(chcount&63) := lineno
  }
}

AND lex() BE
{ LET neg = FALSE

  tokln := lineno
//sawritef("lex: lineno=<%n/%n> ch=%n '%c'*n",
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
                IF neg DO numval := -numval
                token := s_num
                IF ch='~' DO
                { token := s_numtied
                  rch()
                }
                RETURN

    CASE 'a':CASE 'b':CASE 'c':CASE 'd':CASE 'e':CASE 'f':CASE 'g':
//sawritef("lex: case 'a'-'g': reached*n")
                token := s_note // May change to s_notetied
                noteletter := ch
                notesharps :=  0  // = 0, 1, 2, -1 or -2
                reloctave  :=  0  // Octaves up
                notelengthnum := -1  // If not specified
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
                WHILE ch='*'' | ch=',' DO
                { // octaves up or down
                  TEST ch='*''
                  THEN reloctave := reloctave+1
                  ELSE reloctave := reloctave-1
                  rch()
                }
rdlength:
                notelengthnum := -1      // No explicit length yet
                WHILE '0'<=ch<='9' DO
                { IF notelengthnum<0 DO notelengthnum := 0
                  notelengthnum := notelengthnum*10 + ch - '0'
                  rch()
                }
//writef("notelengthnum=%n*n", notelengthnum)

                dotcount := 0
                WHILE ch='.' DO
                { dotcount := dotcount+1
                  rch()
                }
//writef("dotcount=%n*n", dotcount)

                IF ch='~' & token=s_note DO
                { token := s_notetied
                  rch()
                }
                // token = s_note or s_notetied
                // noteletter = 'a' .. 'g'
                // notesharps = -2, -1, 0, 1, 2
                // reloctave = -9,..., 0,..., 9
                // notelengthnum = -1, 0, 1, 2, 4, 8, 16,...
                // dotcount = 0, 1, 2,...
                RETURN

    CASE 'r':  token := s_rest
               rch()
               GOTO rdlength

    CASE 's':  token := s_space
               rch()
               GOTO rdlength

    CASE 'z':  token := s_null         // A zero length space
               rch()
               BREAK

    CASE '\':
//sawritef("case '\': tokln=<%n/%n>*n", tokln>>20, tokln & #xFFFFF)
//abort(1000)
              rch()    // Reserved words, eg \vol
              token := lookupword(rdtag())
//sawritef("case '\': token=%s*n", opstr(token))
              IF token=s_word DO synerr("Unknown keyword \%s", charv)
              RETURN
 
    CASE '[': token := s_lsquare;   rch(); BREAK
    CASE ']': token := s_rsquare;   rch(); BREAK
    CASE '(': token := s_lparen;    rch(); BREAK
    CASE ')': token := s_rparen;    rch(); BREAK 
    CASE '{': token := s_lcurly;    rch(); BREAK
    CASE '}': token := s_rcurly;    rch(); BREAK 
    CASE ':': token := s_colon;     rch(); BREAK

    CASE '**':token := s_star
              rch()
              IF ch='~' DO
              { token := s_startied
                rch()
              }
              RETURN

    CASE '|': rch()
              IF ch='|' DO { token := s_doublebar; rch(); BREAK }
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
//writef("string node %n for '%s' created*n", stringval, stringval)
                rch()
                RETURN
              }
 
  } // End of switch
} REPEAT
 
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
{ // Return the token for a keyword
  // or s_word, if not found.
  LET len, i = word%0, 0
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
    h2!wordnode := s_word
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
  dsw("control", s_control)               dsw("ctrl", s_control)
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
  dsw("nonvarvol", s_nonvarvol)
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
  dsw("transposition", s_transposition)
  dsw("trebleclef", s_trebleclef)
  dsw("tuplet", s_tuplet);                dsw("tup", s_tuplet)
  dsw("varvol", s_varvol)
  dsw("vibrate", s_vibrate);              dsw("vr", s_vibrate)
  dsw("vibrateadj", s_vibrateadj);        dsw("vra", s_vibrateadj)
  dsw("vibamp", s_vibamp);                dsw("vm", s_vibamp)
  dsw("vibampadj", s_vibampadj);          dsw("vma", s_vibampadj)
  dsw("vol", s_vol);                      dsw("v", s_vol)
  dsw("voladj", s_voladj);                dsw("va", s_voladj)
  dsw("volmap", s_volmap)
} 
 
AND wrchbuf() BE
{ LET prevln = 0
  writes("*n...")
  FOR p = chcount-63 TO chcount IF p>=0 DO
  { LET k  = chbuf!(p&63)
    LET ln = chbufln!(p&63)
    IF 0<k<=255 DO
    { UNLESS ln=prevln DO
      { UNLESS k='*n' DO newline()
        writef("<%n/%n>", ln>>20, ln&#xFFFFF)
        prevln := ln
      }
      UNLESS k='*n' DO wrch(k)
    }
  }
  writef("*n*nFiles:")
  FOR i = 1 TO sourcefileno DO
    writef(" <%n>=%s", i, sourcenamev!i)
  newline()
}

AND rdtag() = VALOF
{ LET len = 0
  WHILE 'a'<=ch<='z' | 'A'<=ch<='Z' |  ch='_' DO
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

  IF optLex DO newline()

  declsyswords()
  lex()

  WHILE optLex DO
  { writef("<%n/%n> %t9", tokln>>20, tokln&#xFFFFF, opstr(token))

    SWITCHON token INTO
    { DEFAULT:
//writef("default case")
         ENDCASE

      CASE s_string:
         writef(" *"%s*"", stringval)
         ENDCASE

      CASE s_num:
      CASE s_numtied:
         writef(" %8.3d", numval)
//abort(1001)
         ENDCASE

      CASE s_note:
      CASE s_notetied:
         writef("%c", capitalch(noteletter))
         IF notelengthnum>=0 DO writef("%n", notelengthnum)
         FOR i =  1 TO notesharps       DO wrch('#')
         FOR i = -1 TO notesharps BY -1 DO wrch('b')
         FOR i =  1 TO reloctave        DO wrch('*'')
         FOR i = -1 TO reloctave  BY -1 DO wrch(',')
         FOR i =  1 TO dotcount         DO wrch('.')
//abort(1000)
         ENDCASE

      CASE s_rest:
         writef("R")
         IF notelengthnum>=0 DO writef("%n", notelengthnum)
         FOR i = 1 TO dotcount DO wrch('.')
         ENDCASE

      CASE s_space:
         writef("S")
         IF notelengthnum>=0 DO writef("%n", notelengthnum)
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
  IF optLex RESULTIS 0

  res := rdscores()
  UNLESS token=s_eof DO fatalsynerr("Incorrect termination")
  RESULTIS res
}

AND fatalerr(mess, a, b, c) BE
{ writes("*nFatal near "); prlineno(lineno); writes(": ")
  writef(mess, a, b, c)
  writes("*nCompilation aborted*n")
  longjump(fin_p, fin_l)
}
 
AND fatalsynerr(mess, a) BE
{ writef("*nError near "); prlineno(lineno); writes(": ")
  writef(mess, a)
  writef("*nRecent text:*n")
  wrchbuf()
  errcount := errcount+1
  writes("*nCompilation aborted*n")
  longjump(fin_p, fin_l)
}

AND synerr(mess, a, b, c) BE
{ 
  writef("*nError near "); prlineno(lineno); writes(": ")
  writef(mess, a, b, c)
  wrchbuf()
  // Skip the rest of the input line 
  UNTIL ch='*n' | ch=endstreamch DO rch()
  lex()
  //error("")
  errcount := errcount+1
  IF errcount >= errmax DO fatalerr("Too many errors")

//abort(1000)
  longjump(rec_p, rec_l)
}

AND trerr(absq, mess, a, b, c, d, e, f) BE
{ // If absq >= 0 the error message will include bar and beat numbers.
  // tokln will hold the file/line number of the current tree node.
  writef("*nTranslation error near "); prlineno(tokln)
  IF absq<0 & qbeats>=0 DO absq := qscale(qbeats)
  IF absq>=0 DO
  { LET bno = qbeats2barno(absq)
    writef(" at qbeat %n of bar %n", absq-barno2qbeats(bno), bno)
  } 
  IF currpartname DO writef(" in %s", currpartname)
  writes(":*n   ")
  writef(mess, a, b, c, d, e, f)
  newline()
  errcount := errcount+1
  IF errcount >= errmax DO fatalerr("Too many errors")
}

LET checkfor(tok, mess) BE
{ UNLESS token=tok DO synerr(mess)
  lex()
}
 
LET rdscores() = VALOF
{ // Return  -> [-, Score,    ln, conductor, parts]
  // or         [-, Interval, ln, msecs]
  // or         [-, List,     ln, scorelist]
  LET res = 0
  LET prev = @res
  LET ln = tokln

  WHILE token=s_score | token=s_interval DO
  { LET sc = rdscore()
    // Append the score or interval to the list of scores
    IF optStrace UNLESS prev=@res DO
      writef("%i6:   [%n, %s, %s,...]*n",
              prev, sc, opstr(h2!sc), fnoln2str(h3!sc, fnolnstrv))
    !prev := sc
    prev := sc
//writef("rdscores: res=%n prev=%n*n", res, prev)
  }

  // res is a list of scores
  UNLESS res & !res RESULTIS res
  // If more than one score form a List node.
  res := mk4(0, s_list, ln, res)
  IF optStrace DO
    writef("%i6 -> [0, List, %s, %n]*n",
           fnoln2str(ln, fnolnstrv)) 
  RESULTIS res
}

AND rdscore() = VALOF
{ // Return -> [-, Score, ln, name, conductor, parts]
  // where
  // conductor -> [-, Conductor, ln, note-item]
  // parts     -> [-, Part,      ln, note-item, qlen]
  // or        -> [-, Solo,      ln, note-item, qlen]
  // A score contains one conductor, one or more parts
  // (some of which may be solos).
  LET res = 0
  LET scoreln = tokln
  LET parln = tokln
  LET a = 0
  LET name = "Unnamed"
  LET conductor = 0  // The conductor
  LET parts = 0      // A list of parts and solos
  LET lastpart = @parts
  LET oldp, oldl = rec_p, rec_l
  rec_p, rec_l := level(), scorerec

  IF token = s_interval DO // \interval or \interval 1.5 \interval(1.5)
  { LET val = 2_000        // 2 secs default interval between scores.
    lex()
//sawritef("rdscore: token = \interval*n")
    IF token=s_lparen DO
    { lex()
      rdnumber()
      val := numval
      checkfor(s_rparen, "Bad parameter for \interval")
      GOTO mkinterval
    }

    IF token=s_num DO
    { val := numval
      lex()
      GOTO mkinterval
    }

    // \interval without argument

mkinterval:
    res := mk4(0, s_interval, scoreln, val)
    IF optStrace DO
      writef("%i6 -> [%n, %s, %s, %n]*n",
              h1!res,
              opstr(h2!res),
              fnoln2str(h3!res, fnolnstrv),
              h4!res)
    RESULTIS res
  }

  checkfor(s_score, "\score or \interval expected")
  name := rdstring()                     // Name of this score
  parln := tokln

  // The conductor and other parts of a score are performed simultaneously
  // and so are enclosed in square brackets.
  checkfor(s_lsquare, "'[' expected")
  
scorerec:
  UNTIL token=s_rsquare DO
  { // Start of loop to find score items
    LET ln = tokln
    
    SWITCHON token INTO
    { DEFAULT:
        synerr("\conductor, \solo or \part expected, token=%s", opstr(token))

      CASE s_conductor:
        lex()
        IF conductor DO synerr("Only one conductor is allowed*n")
        // The body of the conductor part must be a block even if
        // no shape data occurs within the part
        conductorblk :=  mk8(0, s_block, ln,
                             rdnoteitem(), // Body
                             -1,           // No parent environment block
                             0,            // No shape items yet
                             -1,           // qstart
                             -1)           // qend
        IF optStrace DO
          writef("%i6 -> [%n, %s, %s, %n, %n, %n, %n, %n]*n",
                  conductorblk,
                  h1!conductorblk,
                  opstr(h2!conductorblk),
                  fnoln2str(h3!conductorblk, fnolnstrv),
                  h4!conductorblk,
                  h5!conductorblk,
                  h6!conductorblk,
                  h7!conductorblk,
                  h8!conductorblk)
        conductor := mk4(0, s_conductor, ln, conductorblk)
        IF optStrace DO
          writef("%i6 -> [%n, %s, %s, %n]*n",
                  conductor,
                  h1!conductor,
                  opstr(h2!conductor),
                  fnoln2str(h3!conductor, fnolnstrv),
                  h4!conductor)
        LOOP

      CASE s_part: // [-, Part, ln, notes, channel]
      CASE s_solo: // [-, Solo, ln, notes, channel]
      { LET op = token
        lex()
        a := mk5(0, op, ln, rdnoteitem(), -1)
        IF optStrace DO
        { writef("%i6 -> [%n, %s, %s, %n, -1]*n",
                  a,
                  h1!a,
                  opstr(h2!a),
                  fnoln2str(h3!a, fnolnstrv),
                  h4!a)
          UNLESS lastpart=@parts DO
            writef("%i6:   [%n,...]*n", lastpart, a)
        }
        !lastpart := a
        lastpart := a
        LOOP
      }

      CASE s_eof:
        fatalsynerr("Unexpected end of file")
    }
  }

  lex() // Skip over the right square bracket

  rec_p, rec_l := oldp, oldl

  UNLESS conductor DO fatalsynerr("A conductor is required") 
  UNLESS parts     DO fatalsynerr("At least one part or solo is needed") 

  res := mk5(0, s_par, parln, parts, -1) // qbeat length of the longest part

  IF optStrace DO
    writef("%i6 -> [%n, %s, %s, %n, -1]*n",
            res,
            h1!res,
            opstr(h2!res),
            fnoln2str(h3!res, fnolnstrv),
            h4!res)

  res := mk6(0, s_score, scoreln, name, conductor, res)

  IF optStrace DO
    writef("%i6 -> [%n, %s, %s, *"%s*", %n, %n]*n",
            res,
            h1!res,
            opstr(h2!res),
            fnoln2str(h3!res, fnolnstrv),
            h4!res,
            h5!res,
            h6!res)

  RESULTIS res
}

AND rdstring() = VALOF
{ LET a = stringval
  checkfor(s_string, "String expected")
  RESULTIS a
}

AND rdnumber() = VALOF
{ // Used only by the syntax analyser
  LET a = numval
  checkfor(s_num, "Number expected")
  RESULTIS a
}

AND rdinteger() = VALOF
{ LET a = numval
  checkfor(s_num, "Integer expected")
  UNLESS a>=0 & a MOD 1000 = 0 DO synerr("%5.3d not an integer", a)
  RESULTIS a/1000
}

AND noteqbeats(lengthnum, prevlengthnum, dotcount) = VALOF
{ // Calculate the note or rest's qbeats
  LET qlen = 0

  IF lengthnum<0 DO lengthnum := prevlengthnum

  SWITCHON lengthnum INTO
  { DEFAULT:  synerr("Bad note length %n", lengthnum)

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
{ LET op, ln = token, tokln
  LET a, b = 0, 0

//writef("rdnoteitem: op=%s  <%n/%n>*n", opstr(op), ln>>20, ln&#xFFFFF)
  SWITCHON op INTO
  { DEFAULT:
      RESULTIS 0

    CASE s_num: // An octave number
      //writef("rdnoteprim: numval= %9.3d*n", numval)
      UNLESS 0<=prevoctave<=9_000 & numval MOD 1000 = 0 DO
        synerr("Bad octave number %4.3d", numval)
      prevoctave := numval / 1000
      prevnoteletter := 'f' // So C to B are all in the same octave 
      lex()
      RESULTIS rdnoteprim()

    CASE s_lparen: // [-, Seq, ln, note-list, qlen]
      lex()
      a := rdnoteitems()
      checkfor(s_rparen, "Syntax error in ( ... ) construct")
      a := mk5(0, s_seq, ln, a, -1)

      IF optStrace DO
        writef("%i6 -> [%n, %s, %s, %n, %n]*n",
                a,
                h1!a,
                opstr(h2!a),
                fnoln2str(h3!a, fnolnstrv),
                h4!a,
                h5!a)

      RESULTIS a

    CASE s_lcurly: // [-, Block, ln, noteitem,
                   //  envblk, shapeitems, absqstart, absqend]
      lex()
      a := mk5(0, s_seq, ln, rdnoteitems(), -1)
      checkfor(s_rcurly, "Syntax error in { ... } construct")
      IF optStrace DO
        writef("%i6 -> [%n, %s, %s, %n, %n]*n",
                a,
                h1!a,
                opstr(h2!a),
                fnoln2str(h3!a, fnolnstrv),
                h4!a,
                h5!a)

      a := mk8( 0, s_block, ln,
                a,  // List of notes
                -1, // Parent environment block.
                0,  // No shape items yet.
                -1, // Absolute qbeat position of start -- not set yet.
                -1) // Absolute qbeat position of end -- not set yet.
      IF optStrace DO
        writef("%i6 -> [%n, %s, %s, %n, %n, %n, %n, %n]*n",
                a,
                h1!a,
                opstr(h2!a),
                fnoln2str(h3!a, fnolnstrv),
                h4!a,
                h5!a,
                h6!a,
                h7!a,
                h8!a)

      RESULTIS a

    CASE s_lsquare: // [-, Par, ln, note-list, qlen]
      lex()
      a := rdnoteitems()
      checkfor(s_rsquare, "Syntax error in [ ... ] construct")
      a := mk5(0, s_par, ln, a, -1)
      IF optStrace DO
        writef("%i6 -> [%n, %s, %s, %n, %n]*n",
                a,
                h1!a,
                opstr(h2!a),
                fnoln2str(h3!a, fnolnstrv),
                h4!a,
                h5!a)

      RESULTIS a

    CASE s_note:     // [-, Note,     ln, <letter,sharps,n>, qlen]
    CASE s_notetied: // [-, Notetied, ln, <letter,sharps,n>, qlen]
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

      prevoctave := prevoctave +    // octave of previous note
                    reloctave  +    // count of 's and ,s
                    tab1!(7*i + j)  // letter change correction

      // Calculate the midi note number (untransposed)
      notenumber := (prevoctave+1)*12 + tab2!i + notesharps
//writef("notenumber=%n*n", notenumber)

      UNLESS 0<=notenumber<=127 DO
        synerr("Note %n out of range", notenumber)

      a := mk5(0, op, ln,
               noteletter<<16 | (notesharps&255)<<8 | notenumber,
               noteqbeats(notelengthnum, prevlengthnum, dotcount))
      IF optStrace DO
        writef("%i6 -> [%n, %s, %s, <%c:%n:%n>, %n]*n",
                a,
                h1!a,
                opstr(h2!a),
                fnoln2str(h3!a, fnolnstrv),
                noteletter, notesharps, notenumber,
                h5!a)

      IF notelengthnum>=0 DO prevlengthnum := notelengthnum
      lex()
      RESULTIS a
    }

    CASE s_rest:  // [-, Rest,  ln, qlen]
    CASE s_space: // [-, Space, ln, qlen]
      a := mk4(0, op, ln, noteqbeats(notelengthnum, prevlengthnum, dotcount))
      IF optStrace DO
        writef("%i6 -> [%n, %s, %s, %n]*n",
                a,
                h1!a,
                opstr(h2!a),
                fnoln2str(h3!a, fnolnstrv),
                h4!a)
      IF notelengthnum>=0 DO prevlengthnum := notelengthnum
      lex()
      RESULTIS a

    CASE s_null: // [-, Null, ln, qlen=0]
      a := mk4(0, op, ln, 0)
      IF optStrace DO
        writef("%i6 -> [%n, %s, %s, %n]*n",
                a,
                h1!a,
                opstr(h2!a),
                fnoln2str(h3!a, fnolnstrv),
                h4!a)

      lex()
      RESULTIS a

    CASE s_barline:            // All yield [-, op, ln]
    CASE s_doublebar:
    CASE s_repeatback:
    CASE s_repeatforward:
    CASE s_repeatbackforward:
    CASE s_trebleclef:
    CASE s_altoclef:
    CASE s_tenorclef:
    CASE s_bassclef:
    CASE s_varvol:
    CASE s_nonvarvol:
      a := mk3(0, op, ln)
      IF optStrace DO
        writef("%i6 -> [%n, %s, %s]*n",
                a,
                h1!a,
                opstr(h2!a),
                fnoln2str(h3!a, fnolnstrv))
      lex()
      RESULTIS a

    CASE s_control: // [-, Control, ln, controller-no, val]
                    // Corresponds to Midi: Bn <controller no> <val>
    CASE s_timesig: // [-, Timesig, ln, <int>, <int>]
    CASE s_bank:    // [-, Bank, ln, int, int]
      lex()
      checkfor(s_lparen, "'(' expected")
      a := rdinteger()
      b := rdinteger()
      checkfor(s_rparen, "')' expected")
      a := mk5(0, op, ln, a, b)
      IF optStrace DO
        writef("%i6 -> [%n, %s, %s, %n, %n]*n",
                a,
                h1!a,
                opstr(h2!a),
                fnoln2str(h3!a, fnolnstrv),
                h4!a,
                h5!a)
      RESULTIS a

    CASE s_patch:   // [-, Patch, ln, int]
      lex()
      a := rdinteger()
      a := mk4(0, op, ln, a)
      IF optStrace DO
        writef("%i6 -> [%n, %s, %s, %n]*n",
                a,
                h1!a,
                opstr(h2!a),
                fnoln2str(h3!a, fnolnstrv),
                h4!a)
      RESULTIS a

    CASE s_keysig:  // [-, keysig, ln, note, maj-min]
    { LET plet, poct, plen = prevnoteletter, prevoctave, prevlengthnum
      lex()
      checkfor(s_lparen, "'(' expected")
      a := rdnoteprim()
      UNLESS a & h2!a=s_note DO synerr("Note expected")
      UNLESS token=s_major | token=s_minor DO
        synerr("\major or \minor expected")
      a := mk5(0, op, ln, a, token)
      IF optStrace DO
        writef("%i6 -> [%n, %s, %s, %n, %s]*n",
                a,
                h1!a,
                opstr(h2!a),
                fnoln2str(h3!a, fnolnstrv),
                h4!a,
                opstr(h5!a))
      lex()
      prevnoteletter, prevoctave, prevlengthnum := plet, poct, plen
      checkfor(s_rparen, "')' expected")
      RESULTIS a
    }

    CASE s_transposition: // [-, Transposition, ln, semitones-up]
    { LET plet, poct, plen = prevnoteletter, prevoctave, prevlengthnum
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
      IF optStrace DO
        writef("%i6 -> [%n, %s, %s, %n]*n",
                a,
                h1!a,
                opstr(h2!a),
                fnoln2str(h3!a, fnolnstrv),
                h4!a)
      lex()
      checkfor(s_rparen, "')' expected, token=%s", opstr(token))
      prevnoteletter, prevoctave, prevlengthnum := plet, poct, plen
      RESULTIS a
    }

    CASE s_pedoff:   // All [-, op, ln]
    CASE s_pedoffon:
    CASE s_pedon:
    CASE s_portaoff:
    CASE s_portaon:
    CASE s_softoff:
    CASE s_softon:
      lex()
      a := mk3(0, op, ln)
      IF optStrace DO
        writef("%i6 -> [%n, %s, %s]*n",
                a,
                h1!a,
                opstr(h2!a),
                fnoln2str(h3!a, fnolnstrv))
      RESULTIS a

    CASE s_volmap: // [-, op, ln, shape_list]
      lex()
      a := mk4(0, op, ln, rdshapelist())
      IF optStrace DO
        writef("%i6 -> [%n, %s, %s, %n]*n",
                a,
                h1!a,
                opstr(h2!a),
                fnoln2str(h3!a, fnolnstrv),
                h4!a)
      RESULTIS a

    CASE s_name:               // All [-, op, ln, string]
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
      a := mk4(0, op, ln, rdstring())
      IF optStrace DO
        writef("%i6 -> [%n, %s, %s, *"%s*"]*n",
                a,
                h1!a,
                opstr(h2!a),
                fnoln2str(h3!a, fnolnstrv),
                h4!a)
      RESULTIS a

  }
}

AND rdnoteitem() = VALOF
{ // Return the parse tree of a note item or zero if none found.
  LET op, ln = ?, ?
  LET a = rdnoteprim()

sw:
  UNLESS a RESULTIS 0
  op, ln := token, tokln
  SWITCHON token INTO
  { DEFAULT:
      RESULTIS a

    // Infixed operators with a shape as second operand.
    CASE s_vibrate:
    CASE s_vibrateadj:
    CASE s_vibamp:
    CASE s_vibampadj:
    CASE s_vol:
    CASE s_voladj:
    CASE s_tempo:
    CASE s_tempoadj:
    CASE s_legato:
    CASE s_legatoadj:
    CASE s_delay:
    CASE s_delayadj: // [-, op, ln, noteitem, shapelist]
      lex()
      a := mk5(0, op, ln, a, rdshapelist())
      IF optStrace DO
        writef("%i6 -> [%n, %s, %s, %n, %n]*n",
                a,
                h1!a,
                opstr(h2!a),
                fnoln2str(h3!a, fnolnstrv),
                h4!a,
                h5!a)
      GOTO sw

    // Infixed operators with a note(s) as second operand.
    CASE s_tuplet:
      lex()
      a := mk5(0, op, ln, a, rdnoteitem())
      IF optStrace DO
        writef("%i6 -> [%n, %s, %s, %n, %n]*n",
                a,
                h1!a,
                opstr(h2!a),
                fnoln2str(h3!a, fnolnstrv),
                h4!a,
                h5!a)
      GOTO sw
  }

  RESULTIS 0
}

AND rdnoteitems(n) = VALOF
// This returns a list of note items linked though the
// next (=h1) field. Such a list will always be an operand
// of seq, block or par construct.
{ LET res = 0
  LET prev = @res
  // Setup new recovery point
  LET oldp, oldl = rec_p, rec_l
  rec_p, rec_l := level(), sw

sw:
  { LET a = rdnoteitem()
    UNLESS a BREAK
    IF optStrace DO
      writef("%i6 -> [%n,...]*n", prev, a)
    !prev := a
    prev := a
  } REPEAT

  rec_p, rec_l := oldp, oldl
  RESULTIS res
}

AND rdshapelist() = VALOF
// This returns a list node of shape items linked though the next (=h1) field.
// The list is either a single shape item (a number, a tied number, * or *~)
// or a sequence of shape items enclosed in parentheses.
// Shape values are scaled by sfac/1024. So, for instance,
// if sfac=512 (corresponding to a quaver), a tempo value of
// 120 would be halved giving a rate of 60 crotchets per minute.
// sfac can be changed within a shape sequence by items such as
// :256 or :s8
// The main purpose of scaling is to allow, for instance, dotted
// quaver = 138 to be specified by \tempo(:s8. 138). It is typically
// not used with any of the other shape operators.
{ LET list = 0
  LET lastitem = @list
  LET item = 0
  LET ln = tokln
  LET sfac = 1024
  LET prevlen = prevlengthnum
  prevlengthnum := 4  // Assume the prev length number was 4 (a crotchet)

  IF token=s_num | token=s_numtied DO
  { numval := muldiv(numval, sfac, 1024)
    item := mk4(0, token, tokln, numval)
    IF optStrace DO
    { writef("%i6 -> [%n, %s, %s, %5.3d]*n",
              item,
              h1!item,
              opstr(h2!item),
              fnoln2str(h3!item, fnolnstrv),
              h4!item)
      UNLESS lastitem=@list DO
        writef("%i6 -> [%n,...]*n", lastitem, item)
    }
    !lastitem := item
    lastitem := item
    GOTO ret
  }

  IF token=s_star | token=s_startied DO
  { item := mk3(0, token, tokln)
    // Star items are not scaled by sfac.
    IF optStrace DO
    { writef("%i6 -> [%n, %s, %s]*n",
              item,
              h1!item,
              opstr(h2!item),
              fnoln2str(h3!item, fnolnstrv))
      UNLESS lastitem=@list DO
        writef("%i6 -> [%n,...]*n", lastitem, item)
    }
    !lastitem := item
    lastitem := item
    GOTO ret
  }

  checkfor(s_lparen, "A shape must start with '(', '**', '**~' or a number")

  UNTIL token=s_rparen SWITCHON token INTO
  { DEFAULT:
      synerr("Bad item in shape list: %s", opstr(token))
      BREAK

    CASE s_space:
    { LET len = noteqbeats(notelengthnum, prevlengthnum, dotcount)
      item := mk4(0, s_space, tokln, len)
      IF optStrace DO
        writef("%i6 -> [%n, %s, %s, %n]*n",
              item,
              h1!item,
              opstr(h2!item),
              fnoln2str(h3!item, fnolnstrv),
              h4!item)
      IF notelengthnum>=0 DO prevlengthnum := notelengthnum
      lex()
      GOTO append
    }

    CASE s_colon:
      lex()
      IF token=s_space DO
      { sfac := noteqbeats(notelengthnum, 4, dotcount)
        lex()
        LOOP
      }

      IF token=s_num DO  // eg :1536
      { sfac := numval/1000
//writef("rdshapelist: sfac=%n*n", sfac) 
        lex()
        LOOP
      }

      synerr("'s' or an integer expected after ':' in shape list")
      LOOP


    CASE s_num:
    CASE s_numtied:
      numval := muldiv(sfac, numval, 1024)
      item := mk4(0, token, tokln, numval)
      IF optStrace DO
        writef("%i6 -> [%n, %s, %s, %5.3d]*n",
              item,
              h1!item,
              opstr(h2!item),
              fnoln2str(h3!item, fnolnstrv),
              h4!item)
      lex()
      GOTO append

    CASE s_star:
    CASE s_startied:
      item := mk3(0, token, tokln)
      IF optStrace DO
        writef("%i6 -> [%n, %s, %s]*n",
              item,
              h1!item,
              opstr(h2!item),
              fnoln2str(h3!item, fnolnstrv))
      lex()

append:
      IF optStrace UNLESS lastitem=@list DO
        writef("%i6:  [%n,...]*n",lastitem, item)
      !lastitem := item
      lastitem := item
      LOOP
  }

ret:
  lex()
  prevlengthnum := prevlen
  list := mk4(0, s_list, ln, list)
  IF optStrace DO
    writef("%i6 -> [%n, %s, %s, %n]*n",
            list,
            h1!list,
            opstr(h2!list),
            fnoln2str(h3!list, fnolnstrv),
            h4!list)
  RESULTIS list
}

/*
Automatic insertion of blocks

The tree representing the list of scores and the bodies of blocks
are searches by insertblocks to find inner blocks or places where
inner blocks must be inserted. For either kind of block it a list
of shape data items for each kind of shape. This is done by calls
of initblock which calls shapescanblock for each kind of shape.

When initblock has create all shape data items it calls insertblocks
on the body of the block to find and deal with inner blocks.

shapescanblock searches for shape data belonging to its block. It
searches everywhere except the elements of a par construct, the body
of an inner block or the lefthand operand of a tuplet construct.

It does this by calling shapescan to do most of the work. Before
returning shapescanblock insert a final shape data item is previous
item was not positioned at the end of the block.
*/

AND insertblocks(noteitem, envblk) BE IF noteitem DO
{ // noteitem is any note item.
  // envblk is the current environment block or zero.

  // When called

  // qbeats is the local qbeat position of the note item.
  // scbase, scfaca and scfacb are the scaling parameters used
  //   by qscale to convert local qbeat values to absolute values.

  // It searches the entire tree rooted at noteitem in depth first
  // order inserting block nodes where necessary and filling in the
  // qlen fields of all Par and Seq nodes.
  // It ensures that the body of the conductor node is a block, and
  // that the bodies of Part and Solo nodes are blocks if they contain
  // unprotected shape operators. Similarly, the elements of Par
  // constructs and the left hand operands of Tuplet nodes are blocks,
  // if needed.
  // For each block it finds or inserts it fills in the parent, qstart
  // and qend fields, and initialised the shape item list to null.
  // It does not explore the h1 field of the given note item.

//writef("insertblocks: op = %s*n", opstr(h2!noteitem))
  SWITCHON h2!noteitem INTO
  { DEFAULT:
      RETURN

    CASE s_name:
      currpartname := h4!noteitem
      RETURN

    CASE s_rest:
    CASE s_space:
      qbeats := qbeats + h4!noteitem
      RETURN

    CASE s_note:
    CASE s_notetied:
      qbeats := qbeats + h5!noteitem
      RETURN

    CASE s_block:      // User inserted block
                       // [-, Block, ln, noteitem,
                       //     envblk, shapeitems, qstart, qend]
    { LET body = h4!noteitem
      LET qlen = qbeatlength(body)
      h5!noteitem := envblk // Fill in the node's parent field.
      h6!noteitem := 0 // No shape list yet
      h7!noteitem := qscale(qbeats)
      h8!noteitem := qscale(qbeats + qlen - 1)
      insertblocks(body, noteitem)
      RETURN
    }

    CASE s_conductor:  // [-, Conductor, ln, noteitem]
    CASE s_part:       // [-, Part,      ln, noteitem, channel]
    CASE s_solo:       // [-, Solo,      ln, noteitem, channel]
    { // h1!noteitem should be zero
      LET body = h4!noteitem

      IF blockneeded(body) DO
      { // Insert a new block because it was needed.
        LET qlen = qbeatlength(body)
        LET ln   = h3!noteitem
        LET newblk = mk8(0, s_block, ln,
                         body,                  // The block body
                         envblk,                // Parent block
                         0,                     // No shape items yet
                         qscale(qbeats),        // Abs qbeat position of start.
                         qscale(qbeats+qlen-1)) // Abs qbeat position of end.
        h4!noteitem := newblk // Replace the notelist by the new block.
        // Now explore the body giving it the new environment block.
        insertblocks(body, newblk)
        RETURN
      }

      // No new block needed so just explore the body.
      insertblocks(body, envblk)
      RETURN
    }

    CASE s_par:        // [-, Par, ln, parlist, qlen]
                       // qlen is the local qbeat length of the
                       //      longest item in the list.
    { // Blocks are inserted at each elements of a par construct where needed.
      LET q0 = qbeats
      LET qlen = 0
      LET ptr = @h4!noteitem

      // ptr points to a cell containing a list of par items.
      WHILE !ptr DO
      { LET paritem = !ptr // Next element of the Par construct
        qbeats := q0
        TEST blockneeded(paritem)
        THEN { LET newblk = mk8(!paritem, s_block, h3!paritem,
                                paritem,
                                envblk,  // Parent block
                                0,       // No shape items
                                -1,      // Abs qbeat position of start
                                -1)      // Abs qbeat end of block
               !paritem := 0 // The link has been put in the new block node.
               !ptr := newblk
               insertblocks(paritem, newblk)
               h7!newblk := qscale(q0)
               h8!newblk := qscale(qbeats-1)
             }
        ELSE { insertblocks(paritem, envblk)
             }

        IF qlen < qbeats - q0 DO qlen := qbeats - q0
        ptr := !ptr
      }

      h5!noteitem := qlen // Remember the qbeat length of the Par construct
      qbeats := q0 + qlen // Local end qbeat of the Par construct.
      RETURN
    }

    CASE s_tuplet: // [-, Tuplet, ln, notes, notes]
    { // The left hand operand of a tuplet is a block if necessary.
      LET q0  = qbeats
      LET lhs = h4!noteitem
      LET rhs = h5!noteitem
      LET qlen1 = qbeatlength(lhs)
      LET qlen2 = qbeatlength(rhs)

      TEST blockneeded(lhs)
      THEN { LET newblk = mk8(!lhs, s_block, h3!lhs,
                              lhs,
                              envblk,             // Parent environment block
                              0,                  // No shape items yet
                              qscale(q0),         // Abs qbeat position of start
                              qscale(q0+qlen1-1)) // Abs qbeat position of end
             IF optStrace DO
               writef("%i6 -> [%n, %s, %s, %n, %n, %n, %n, %n]*n",
                newblk,
                h1!newblk,
                opstr(h2!newblk),
                fnoln2str(h3!newblk, fnolnstrv),
                h4!newblk,
                h5!newblk,
                h6!newblk,
                h7!newblk,
                h8!newblk)

             !lhs := 0 // The link has been put in the block node.
             h4!noteitem := newblk
             IF optStrace DO
               writef("%i6:  [%n, %s, %s, %n, %n]*n",
                noteitem,
                h1!noteitem,
                opstr(h2!noteitem),
                fnoln2str(h3!noteitem, fnolnstrv),
                h4!noteitem,
                h5!noteitem)
             insertblocks(lhs, newblk)
           }
      ELSE { insertblocks(lhs, envblk)
           }

      { // Now explore the right hand operand.
        LET qlen = qbeats - q0 // Local qbeat length of left operand
        LET oscbase, oscfaca, oscfacb = scbase, scfaca, scfacb
        LET newbase = qscale(q0)
        LET newfaca = qscale(q0+qlen-1) - newbase
        LET newfacb = qlen2
        qbeats := 0 // New local position
        insertblocks(rhs, envblk)
        scbase, scfaca, scfacb := oscbase, oscfaca, oscfacb
        qbeats := q0 + qlen1
      }
      RETURN
    }

    CASE s_seq: // [-, Seq, ln, list, qlen]
    { // All elements of a sequence must be inspected
      LET list = @h4!noteitem
      LET q0 = qbeats

      WHILE !list DO
      { LET seqitem = !list // Next element of the sequence.
//writef("insertblocks: Seq qbeats=%n*n", qbeats)
        insertblocks(seqitem, envblk)
        list := !list
      }
      h5!noteitem := qbeats - q0 // Fill in local qbeat length
//writef("insertblocks: Seq qlen=%n*n", h5!noteitem)
      RETURN
    }

    CASE s_vibrate:
    CASE s_vibrateadj:
    CASE s_vibamp:
    CASE s_vibampadj:
    CASE s_vol:
    CASE s_voladj:
    CASE s_tempo:
    CASE s_tempoadj:
    CASE s_legato:
    CASE s_legatoadj:
    CASE s_delay:
    CASE s_delayadj: // [-, op, ln, noteitem, shapelist]
      // Inspect the left hand operand.
      insertblocks(h4!noteitem, envblk)
      RETURN
  }
}

AND blockneeded(noteitem) = VALOF
{ // noteitem of note item, possibly a sequence .
  // This returns TRUE if there is an unprotected shape operator
  // somewhere in the list, ie not in an inner block.

  UNLESS noteitem RESULTIS FALSE

  SWITCHON h2!noteitem INTO
  { DEFAULT:
      RESULTIS FALSE

    CASE s_tuplet: // [-, Tuplet, ln, noteitem, noteitem]
    { // Only look in the right hand operand of the tuplet.
      LET rhs = h5!noteitem
      RESULTIS blockneeded(rhs)
    }

    CASE s_seq:
    { // Look in all elements of the sequence.
      LET p = h4!noteitem

      WHILE p DO
      { IF blockneeded(p) RESULTIS TRUE
        p := !p
      }

      RESULTIS FALSE
    }

    // Dyadic shape operators
    // Inspect the left hand operand.
    CASE s_vibrate:
    CASE s_vibrateadj:
    CASE s_vibamp:
    CASE s_vibampadj:
    CASE s_vol:
    CASE s_voladj:
    CASE s_tempo:
    CASE s_tempoadj:
    CASE s_legato:
    CASE s_legatoadj:
    CASE s_delay:
    CASE s_delayadj: // [-, op, ln, noteitem, shapelist]
      RESULTIS TRUE
  }
}

AND initshapeitems(t, envblk) BE WHILE t DO
{ // t      is a node inside envblk
  // envblk is the current environment block which has already
  //        had the parent, qstart and qend fields initialised.

  // The following globals are set

  // qbeats   is the local qbeat position
  // scbase, scfaca and scfacb are the scaling parameters

  // This function performs a depth first search on the tree rooted at t.
  // When it finds a Block node it calls shapescanblock for each kind of
  // shape to populate the block's list of shape items. It then continues
  // searching the body of the block.
  // By processing the blocks in this order, the values of star items in
  // shape lists can be looked up correctly.

  LET op = h2!t

  SWITCHON op INTO
  { DEFAULT: // Ignore most node types
      RETURN

    CASE s_name:
      currpartname := h4!t
      RETURN

    CASE s_block:  // [-, Block, ln, body, parent, shapeitems, qstart, qend]
    { LET body = h4!t
      LET msecsmapneeded = FALSE
      LET q0 = qbeats

      h6!t := 0           // No shape items yet

//writef("initshapeitems: block=%n absqstart=%n absqend=%n*n", t, h7!t, h8!t)

      // Find all shape data that belongs to this block
      shapescanblock(t, s_vibrate,     envblk)
      shapescanblock(t, s_vibrateadj,  envblk)
      shapescanblock(t, s_vibamp,      envblk)
      shapescanblock(t, s_vibampadj,   envblk)
      shapescanblock(t, s_vol,         envblk)
      shapescanblock(t, s_voladj,      envblk)
      IF shapescanblock(t, s_tempo,    envblk) DO msecsmapneeded := TRUE
      IF shapescanblock(t, s_tempoadj, envblk) DO msecsmapneeded := TRUE
      shapescanblock(t, s_legato,      envblk)
      shapescanblock(t, s_legatoadj,   envblk)
      shapescanblock(t, s_delay,       envblk)
      shapescanblock(t, s_delayadj,    envblk)

      IF msecsmapneeded | t=conductorblk DO
      { // Add an Msecsmap item to the shape list
        //writef("Adding Msecsmap item to the shape list*n")
        mkmsecsmap(t)
      }

      //prblockenv(t)

      // Now initialise the inner blocks
      qbeats := q0
      initshapeitems(body, t) // blk is the new environment block
      RETURN
    }

    CASE s_conductor:  // [-, Conductor, ln, body]
    CASE s_part:       // [-, Part,      ln, body, channel]
    CASE s_solo:       // [-, Solo,      ln, body, channel]
    { LET body = h4!t
      initshapeitems(body, envblk)
      RETURN
    }

    CASE s_par: // [-, Par, ln, list, qlen]
                // list is the list of par items.
                // qlen is already set to the local qbeat length of
                //      the longest element.
    { // Deal with a list of elements.
      LET list = h4!t

      WHILE list DO
      { LET len = ?
        initshapeitems(list, envblk)
        list := !list
      }
      RETURN
    }

    CASE s_seq:        // [-, Seq, ln, list, qlen]
    { // Deal with a list of elements.
      LET list = h4!t

      WHILE list DO
      { initshapeitems(list, envblk)
        list := !list
      }

      RETURN
    }

    CASE s_tuplet:
    { // The left hand operand of a tuplet is a block
      LET lhs = h4!t
      LET rhs = h5!t

      initshapeitems(lhs, envblk)

      { LET lhsqlen = qbeatlength(lhs)
        LET rhsqlen = qbeatlength(rhs)
        LET obase, ofaca, ofacb = scbase, scfaca, scfacb

        // Set up new scaling parameters
        LET nbase = qscale(qbeats)
        LET nfaca = qscale(qbeats+lhsqlen-1) - nbase
        LET nfacb = rhsqlen

        scbase, scfaca, scfacb := nbase, nfaca, nfacb
        qbeats := 0

        initshapeitems(rhs, envblk)

        // Restore previous scaling parameters
        scbase, scfaca, scfacb := obase, ofaca, ofacb
      }
      RETURN
    }

    // Dyadic shape operators, typically
    // [-, op, ln, notes, qlen, shape]
    // Inspect the left hand operand.
    CASE s_vibrate:
    CASE s_vibrateadj:
    CASE s_vibamp:
    CASE s_vibampadj:
    CASE s_vol:
    CASE s_voladj:
    CASE s_tempo:
    CASE s_tempoadj:
    CASE s_legato:
    CASE s_legatoadj:
    CASE s_delay:
    CASE s_delayadj: // [-, op, ln, noteitem, shapelist]
      initshapeitems(h4!t, envblk)
      RETURN
  }
}

AND mkmsecsmap(envblk) BE
{ // Add a msecsmap item to the shape items list of envblk giving the mapping
  // to msecs for any semiquaver position within that block.

  LET parent = h5!envblk
  LET qstart = h7!envblk
  LET qend   = h8!envblk
  LET q0     = qstart     & #x7FFFFF00
  LET q1     = (qend+256) & #x7FFFFF00
  LET upb    = (q1-q0) / 256
  LET v      = getvec(upb)
  LET msecs  = 0           // Start time of qbeat q0

  // q0 is qstart rounded down to a multiple of 256
  // q1 is qend   rounded  up  to a multiple of 256

  // v!0 will hold the msecs value corresponding to absolute qbeat
  // position q0 and v!upb corresponds to the msecs value at position q1

  // If q is any qbeat position such that qstart<=q<=qend, then
  // corresponding msecs value is computed as follows:

  //    LET i = (q-q0)  /  256
  //    LET r = (q-q0) MOD 256
  //    LET a, b = v!i, v!(i+1)
  //    RESULTIS a + muldiv(b-a, r, 256)

  // If envblk has a parent the values in v are scaled so that the first
  // element of v (v!0) is the msecs value of qstart looked up in the
  // parent environment, and the last element of v is the msecs value
  // corresponding to qend in the parent ernvironment.

//writef("mkmsecsmap: qstart=%n qend=%n q0=%n q2=%n upb=%n*n",
//        qstart, qend, q0, q1, upb)
  FOR i = 0 TO upb DO
  { // A semiquaver has 1024/4 = 256 qbeats
    // At tempo  60.000 256 qbeats take  250 msecs
    // At tempo 120.000 256 qbeats take 125.5 msecs
    // At tempo   t     256 qbeats take 60*250/t = 15000/t msecs
    LET q = i*256
    LET tempo = getshapeval(q0+q, envblk, s_tempo, s_tempoadj)
    // tempo is in crotchets(=1024 qbeats) per minute.
    LET rate = muldiv(15000, 1000, tempo)
//  writef("%i4: qpos=%i4 msecs=%i7   tempo=%9.3d %i4 msecs per semiquaver*n",
//          i, q0+q, msecs, tempo, rate) 
    v!i := msecs
    msecs := msecs + rate
  }

  veclist := mk2(veclist, v)
  h6!envblk := mk3(h6!envblk, s_msecsmap, v)

  IF parent DO
  { // The parent environment exists, so scale the elements of v
    // appropriately.
    LET oms1 = qbeats2msecs(qstart, parent)
    LET oms2 = qbeats2msecs(qend,   parent)
    LET ms1  = qbeats2msecs(qstart, envblk)
    LET ms2  = qbeats2msecs(qend,   envblk)
    LET faca = oms2 - oms1
    LET facb =  ms2 -  ms1
//writef("qstart=%n qend=%n faca=%n facb=%n*n", qstart, qend, faca, facb)
//writef("oms1=%n oms2=%n ms1=%n ms2=%n*n", oms1, oms2, ms1, ms2)
    FOR i = 0 TO upb DO
      v!i := oms1 + muldiv(v!i-ms1, faca, facb)
  }
}

AND prblockenv(blk) BE
{ // blk -> [-, Block, ln, body, envblk, shapeitems, qstart, qend]
  // Output the data for every kind of shape belonging
  // to the given block.
  LET shapelist = h6!blk
  LET qstart, qend = h7!blk, h8!blk
  LET qlen = qend - qstart
  LET ln = h3!blk
  LET fno = ln>>20
  ln := ln & #xFFFFF

//  writef("*nBlock absqstart=%n absqend=%n qlen=%n on line <%n/%n>*n",
//          qstart, qend, qlen, fno, ln)

  UNLESS shapelist DO writef("No shape data*n")

  WHILE shapelist DO
  { LET op = h2!shapelist
    LET v  = h3!shapelist
    writef("%s qstart=%n qend=%n", opstr(op), qstart, qend)
    TEST op=s_msecsmap
    THEN { FOR i = 0 TO qlen/256 DO
           { IF i MOD 8 = 0 DO newline()
             writef(" %9.3d", v!i)
           }
         }
    ELSE { FOR i = 1 TO v!0 BY 2 DO
           { IF i MOD 10 = 1 DO newline()
             writef(" %i6:%9.3d", v!i, v!(i+1))
           }
         }
    newline()
    shapelist := !shapelist
  }
//abort(1000)
}

AND shapescanblock(blk, kind) = blk=0 -> 0, VALOF
{ // blk -> [-, Block, ln, body, parent, shapeitems, qstart, qend]
  // The parent, qstart and qend fields are already set.
  // This function inserts a shape item at the start of shapeitems if
  // any shape data of the right kind in found in the body of the block.
  LET upb, v = 0, 0 // Initially empty self expanding vector.
  LET cb     = @upb
  LET body   = h4!blk
  LET parent = h5!blk // The next environment level out
  LET qstart = h7!blk
  LET qend   = h8!blk
  LET q0     = qbeats
  LET qlen    = qbeatlength(body)

  LET obase, ofaca, ofacb = scbase, scfaca, scfacb

  // Calculate the new scaling parameters
  LET nbase = qstart       // Absolute qbeat position
  LET nfaca = qend - nbase // Absolute qbeat length
  LET nfacb = qlen         // Local qbeat length of the body

//  writef("shapescanblock: qlen=%n*n", qlen)
//  writef("shapescanblock: scbase=%n scfaca=%n scfacb=%n*n",
//            nbase, nfaca, nfacb)

  // Set the new scaling parameters
  qbeats := 0
  scbase, scfaca, scfacb := nbase, nfaca, nfacb

  // Deal with the shape data of given kind that belongs to this block.
//writef("shapescanblock: %s calling shapescan*n", opstr(kind))

  // TRUE means shapes of this kind are allowed.
  shapescan(body, kind, blk, cb, TRUE)

  // Restore previous scaling parameters
  scbase, scfaca, scfacb := obase, ofaca, ofacb
  qbeats := q0 + qlen

  IF v DO
  { // Some shape data was found
    LET p = v!0
    LET prevtied = v!p // The tied flag
    LET prevq    = v!(p-2)
    LET prevval  = v!(p-1)

    p := p-1
    v!0 := p
//writef("shapescanblock:qend=%n prevq=%n prevval= %9.3d*n",
//        qend, prevq, prevval)

    UNLESS prevq=qend DO
    { //The last shape item was not at the end of the block, so
      // add another item.
      pushval(cb, qend)
      TEST prevtied
      THEN { LET starval = lookupshapeval(qend, kind, parent)
             pushval(cb, starval)
//writef("shapescanblock:Plant at p=%i3: %i6 %9.3d*n", p+1, qend, starval)
           }
      ELSE { pushval(cb, prevval) // Duplicate previous val
//writef("shapescanblock:Plant at p=%i3: %i6 %9.3d*n", p+1, qend, prevval)
           }
    }

//    writef("shapescanblock: some %s data was found*n", opstr(kind))

    veclist := mk2(veclist, v)
    // Insert a new shape item into the shapeitems list
//writef("shapescanblock: Inserting shape data of kind %s*n", opstr(kind))
    h6!blk := mk3(h6!blk, kind, v)
  }

  RESULTIS v // Non zero if shape data found
}

AND shapescan(t, kind, blk, cb, ok) BE IF t DO
{ // t      is a node inside blk but not inside and inner block.
  // kind   is a shape kind, eq s_volume.
  // blk    is the environment block corresponding to the current scope.
  //        Its parent is used to lookup star values.
  // cb     is the control block for the shape data of the given kind
  //        that is being built.
  // ok     is TRUE if shape data of this kind is valid, and FALSE otherwise.
  //        Shape data is not valid if it is found in the left operand of
  //        a shape operator of the same kind.

  // The following globals are set:

  // qbeats   is the local qbeat position
  // scbase, scfaca and scfacb are the scaling parameters

  // It performs a left to right depth first search looking for nodes
  // with operator kind.

  LET op = h2!t

//sawritef("shapescan: op=%s qpos=%n ok=%n*n", opstr(op), qpos, ok)

  SWITCHON op INTO
  { DEFAULT:    // Ignore most node types
      RETURN

    CASE s_seq:        // [-, Seq, ln, list, qlen]
                       // qlen is already set.
    { // Deal with a list of elements.
      LET list = h4!t

      WHILE list DO
      { shapescan(list, kind, blk, cb, ok)
        qbeats := qbeats + qbeatlength(list)
        list := !list
      }

      RETURN
    }

    CASE s_tuplet:
    { // Only scan the right hand operand of a tuplet since the left
      // operand will be a block.
      LET q0  = qbeats
      LET lhs = h4!t
      LET rhs = h5!t
      LET lhsqlen = qbeatlength(lhs)
      LET rhsqlen = qbeatlength(rhs)

      LET obase, ofaca, ofacb = scbase, scfaca, scfacb

      // Calculate the new scaling parameters
      LET nbase = qscale(q0)                   // Absolute position
      LET nfaca = qscale(q0+lhsqlen-1) - nbase // Absolute length of lhs
      LET nfacb = rhsqlen                      // Local length of rhs

      //writef("shapescan: Tuplet lhsqlen=%n rhsqlen=%n*n", lhsqlen, rhsqlen)
      //writef("shapescan: scbase=%n scfaca=%n scfacb=%n*n",
      //          nbase, nfaca, nfacb)

      // Set the new scaling parameters
      qbeats := 0
      scbase, scfaca, scfacb := nbase, nfaca, nfacb

      shapescan(rhs, kind, blk, cb, ok)

      // Restore previous scaling parameters
      scbase, scfaca, scfacb := obase, ofaca, ofacb
      qbeats := q0 + lhsqlen
      RETURN
    }

    // Dyadic shape operators
    CASE s_vibrate:
    CASE s_vibrateadj:
    CASE s_vibamp:
    CASE s_vibampadj:
    CASE s_vol:
    CASE s_voladj:
    CASE s_tempo:
    CASE s_tempoadj:
    CASE s_legato:
    CASE s_legatoadj:
    CASE s_delay:
    CASE s_delayadj: // [-, op, ln, noteitem, shape-list]
      IF op=kind DO
      { // Add items of shape data qbeat length of notes or <0
        LET q0 = qbeats
        LET qlen = ?    // Local qbeat length of notes.
        LET slen = ?    // Local qbeat length of shape-list. 
        LET body = h4!t // The body note item
        LET list = h5!t // shape list
        // list is a list of spaces of possibly tied numbers and stars, ie
        //       -> 0
        //       or [-, Space,    ln, qlen]        
        //       or [-, Num,      ln, val]        
        //       or [-, Numtied,  ln, val]        
        //       or [-, Star,     ln]        
        //       or [-, Startied, ln]
        LET obase, ofaca, ofacb = scbase, scfaca, scfacb
        LET nbase, nfaca, nfacb = ?, ?, ?

        UNLESS ok DO
        { LET opname = opstr(op)
          tokln := h3!t
          trerr(-1, "Inner use of %s not protected by a block", opname)
          RETURN
        }

        qlen := qbeatlength(body)
        slen := shapelistlength(list)

        //writef("shapescan: qlen=%n slen=%n*n", qlen, slen)
        // Calculate the new scaling parameters
        nbase := qscale(q0)                // Absolute qbeat position
        nfaca := qscale(q0+qlen-1) - nbase // Absolute qbeat length
        nfacb := slen                      // Local shape list length

        // Set the new scaling parameters
        scbase, scfaca, scfacb := nbase, nfaca, nfacb

        // Add the data from this shape list
        //writef("shapescan: data of kind %s found*n", opstr(op))
        scanshapelist(list, kind, blk, cb)

        // Restore previous scaling parameters
        scbase, scfaca, scfacb := obase, ofaca, ofacb
        qbeats := q0
      }
//sawritef("shapescan: op=%s qpos=%n ok=%n*n", opstr(op), qpos, ok)
      IF op=kind DO ok := FALSE
      // Scan the left hand operand of a shape operator.
//sawritef("shapescan: op=%s kind=%s scanning lhs ok=%n*n",
//          opstr(op), opstr(kind), ok)
      shapescan(h4!t, kind, blk, cb, ok)
      RETURN
  }
}

AND scanshapelist(list, kind, envblk, cb) BE
{ // list is a List node giving a list of one or more shape items of
  //      the required kind to be appended to the shape data being
  //      formed in cb.
  // kind is the kind of shape data being processed
  // envblk  is the block corresponding to the scope of this shape data
  //      h7!envblk = absolute qbeat position of the start of the block.
  // cb   is the self expanding shape structure with
  //   cb!0 = current upb of the shape vector, and
  //   cb!1 = zero or the shape vector whose zeroth element
  //          is the position of the latest entry.

  // qbeat scaling from local to absolute qbeats is done using the
  // scbase, scfaca and scfacb (which have already been set) by the formula:

  //          scbase + muldiv(q, scfaca, scfacb)

  // If cb!1 (=v, say) is non zero, and v!0 (=p, say) is the
  // position of the latest entry. The entries v!1 .. v!(p-1)
  // contain (qbeat, value) pairs, and v!p is TRUE if there is
  // an outstanding tie and FALSE otherwise.

  // A shape item is a number or star, tied or otherwise, or a space.
  // If a space has no length number its number is the
  // same and the length number of the previous space. Initially
  // set to 4 (=1024 qbeats).

  // If the very first item of shape data is not at start position of
  // the block, the item *~ is inserted.
  // The value of star (*) is looked up in the parent of the current block.

  LET qstart    = h7!envblk // Abs qbeat position of the start of the block.
  LET qend      = h8!envblk
  LET q         = 0         // Holds the local qbeat position in this shape.
  LET spaceqlen = 1024      // Initial qbeat length of a space

  // The following variables are used to implement the rule that
  // S is inserted between consecutive values.

  LET firstval  = TRUE      // No previous value in this shape list.
  LET prevspace = FALSE     // No space given since last value in this list.

//  writef("shapescanlist: envblk=%n qstart=%n qend=%n*n",
//          envblk, qstart, qend)

  IF h2!list=s_list DO list := h4!list

  WHILE list DO
  { LET op, ln = h2!list, h3!list
    LET opname = opstr(op)
    LET v    = cb!1
    LET p    = v -> v!0, 0
    LET val  = h4!list // For value of a number or star or space length.
    LET tied     = FALSE
    LET prevtied = FALSE
    LET fno = ln>>20
    ln := ln&#xFFFFF

    SWITCHON op INTO
    { DEFAULT:
        //writef("shapescanlist: %s -- <%n/%n>*n", opname, fno, ln)
        ENDCASE

      CASE s_numtied:
      CASE s_startied:
        tied := TRUE

      CASE s_num:
      CASE s_star:
      { // We have a shape value to plant.
        // If it is a number it has already been scaled by
        // the current :s or :dd value.
        LET absq = ?
        //writef("shapescanlist: %s -- <%n/%n>*n", opname, fno, ln)

        UNLESS prevspace | firstval DO
        { // Insert as space of the same size as the previous one, if any.
          q := q + spaceqlen
          //writef("shapescanlist: inserting a suitable space, q=%n*n", q)
        }

        absq := qscale(q) // Abs qbeat position of this value

        IF p=0 & absq~=qstart DO
        { // We are inserting the first shape value of this kind in the
          // current block.
          // If it is not at the start of the current block insert the
          // item *~.
          // Lookup star in the parent environment block.
          LET starval = lookupshapeval(qstart, kind, h5!envblk)
          //writef("shapescanlist: inserting **~ at start of shape*n")
//writef("shapescanlist: Plant at p=%i3: %i6 %9.3d*n", 1, qstart, starval)
          pushval(cb, qstart)
          pushval(cb, starval)
                  
          pushval(cb, TRUE)   // Mark as tied
          v := cb!1
          p := v!0
        }

        prevtied := FALSE

        IF p DO
        { prevtied := v!p
          p := p-1                 // Remove the tie flag
          v!0 := p
        }

        IF op=s_star | op=s_startied DO
        { // Lookup the value of star
          val := lookupshapeval(absq, kind, envblk)
        }

        //writef("shapescanlist: %s %9.3d  <%n/%n>*n", opname, val, fno, ln)

        IF p UNLESS prevtied DO
        { // The previous exists and is untied
          // so duplicate the previous value if different from val.
          LET prevq, prevval = v!(p-1), v!p // Prev qbeat and value
          IF prevq<absq-1 & prevval~=val DO
          { // but only if there is room.
//writef("shapescanlist: Plant at p=%i3: %i6 %9.3d*n",
//        p+1, absq-1, prevval)
            pushval(cb, absq-1)
            pushval(cb, prevval)  // Duplicate value.
            v := cb!1
            p := v!0
          }
        }
//writef("shapescanlist: Plant at p=%i3: %i6 %9.3d*n", p+1, absq, val)
        pushval(cb, absq) // Plant the current shape pair
        pushval(cb, val)
 
        pushval(cb, tied)  // Indicate whether the previous
                           // value had a tie.
        v := cb!1
        p := v!0
        firstval  := FALSE
        prevspace := FALSE
//abort(1015)
        ENDCASE
      }

      CASE s_space:
      { //writef("shapescanlist: %t7 %n*n", opname, val)
        spaceqlen := val // Remember the qbeat length of this space. 
        q := q + val
        prevspace := TRUE
        ENDCASE
      }
    }
//abort(1012)
    //writef("shapescanlist: %s -- q = %n*n", opname, q)
    list := !list  // Get the next item in the shape list.
  }

}

LET fnoln2str(ln, s) = VALOF
{ LET fno = ln>>20
  LET v = VEC 10
  LET len = 1
  ln := ln & #xFFFFF
  v!len := '>'
  { len := len+1
    v!len := ln MOD 10 + '0'
    ln := ln/10
  } REPEATWHILE ln
  len := len+1 
  v!len := '/'
  { len := len+1
    v!len := fno MOD 10 + '0'
    fno := fno/10
  } REPEATWHILE fno
  len := len+1 
  v!len := '<'
  s%0 := len
  FOR i = 1 TO len DO s%i := v!(len-i+1)
  RESULTIS s
}

LET opstr(op) = VALOF SWITCHON op INTO
{ DEFAULT:        sawritef("opstr: System error, op %n*n", op)
//abort(1000)
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
  CASE s_delayadj:            RESULTIS "Delayadj"
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
  CASE s_list:                RESULTIS "List"
  CASE s_lparen:              RESULTIS "Lparen"
  CASE s_lsquare:             RESULTIS "Lsquare"
  CASE s_major:               RESULTIS "Major"
  CASE s_minor:               RESULTIS "Minor"
  CASE s_msecsmap:            RESULTIS "Msecsmap"
  CASE s_name:                RESULTIS "Name"
  CASE s_neg:                 RESULTIS "Neg"
  CASE s_nonvarvol:           RESULTIS "Nonvarvol"
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
  CASE s_star:                RESULTIS "Star"
  CASE s_startied:            RESULTIS "Startied"
  CASE s_string:              RESULTIS "String"
  CASE s_softon:              RESULTIS "Softon"
  CASE s_softoff:             RESULTIS "Softoff"
  CASE s_tempo:               RESULTIS "Tempo"
  CASE s_tempoadj:            RESULTIS "Tempoadj"
  CASE s_tenorclef:           RESULTIS "Tenorclef"
  CASE s_timesig:             RESULTIS "Timesig"
  CASE s_title:               RESULTIS "Title"
  CASE s_transposition:       RESULTIS "Transposition"
  CASE s_trebleclef:          RESULTIS "Trebleclef"
  CASE s_tuplet:              RESULTIS "Tuplet"
  CASE s_varvol:              RESULTIS "Varvol"
  CASE s_vibrate:             RESULTIS "Vibrate"
  CASE s_vibrateadj:          RESULTIS "Vibrateadj"
  CASE s_vibamp:              RESULTIS "Vibamp"
  CASE s_vibampadj:           RESULTIS "Vibampadj"
  CASE s_vol:                 RESULTIS "Vol"
  CASE s_voladj:              RESULTIS "Voladj"
  CASE s_volmap:              RESULTIS "Volmap"
}

AND prnote(letter, sharps, note, qbeats) BE
{ // If qbeats<0 just output the note letter possibly followed by # or b
  // otherwise output the octave number, note letter, sharps and flats, and
  // the length in qbeats.
  LET n = sharps&255
  LET count = 0
  // Sign extend n
  IF n>128 DO n := n-256

  // Cause 4Ces (note 59) to print as 4Cb not 3Cb
  // Cause 3Bis (note 60) to print as 3B# not 4B#

  IF qbeats>=0 TEST note>=12
  THEN writef("%n", (note-n)/12-1)
  ELSE writef("-")
  wrch(letter+'A'-'a')
//writef(" sharps=%n ", sharps)
  FOR i = 1 TO n  DO { wrch('#'); count := count+1 }
  FOR i = n TO -1 DO { wrch('b'); count := count+1 }
  IF qbeats>=0 FOR i = count TO 3 DO wrch(' ')
  UNLESS qbeats<0 DO
  { IF note DO writef("%n:", note)
    writef("%i4", qbeats)
  }
}

LET prtree(t, n, d) BE
{ // This prints the abstract syntax tree of a MUS score
  // x is either zero or points to a node [next, op, ln, ...]
  // op is the node operator, eg s_seq, s_note etc.
  // next is a link to the next node in a list. It is not "owned"
  //      by the node but by the head node of the list, typically
  //      having operator s_seq, s_block or s_par.
  // ln is the line/file number for the node.
  // The other fields are node dependent.
  LET v = TABLE 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
  LET op, ln, fno, a1, a2 = ?, ?, ?, ?, ?
  LET opname = ?

//writef("%n: ", t)
  IF n>=d DO { writes("Etc"); RETURN  }
  IF t=0  DO { writes("Nil"); RETURN  }

  op, ln, a1, a2 := h2!t, h3!t, h4!t, h5!t
  fno := ln>>20
  ln  := ln & #xFFFFF
  opname := opstr(op)

  SWITCHON op INTO
  { DEFAULT:
         writef("%s <%n/%n>", opname, fno, ln)
         ENDCASE

    CASE s_interval:
    CASE s_num:      writef("%t8 %9.3d <%n/%n>",  opname, a1, fno, ln); RETURN
    CASE s_numtied:  writef("%t8 %9.3d~ <%n/%n>", opname, a1, fno, ln); RETURN

    CASE s_star:
    CASE s_startied: writef("%t8 <%n/%n>", opname, fno, ln); RETURN

    CASE s_note:     // [-, Note,     ln, <letter,sharps,note>, qlen]
    CASE s_notetied: // [-, Notetied, ln, <letter,sharps,note>, qlen]
    { LET letter =   a1>>16
      LET sharps =  (a1>>8) & 255
      LET note   =   a1 & 255      // MIDI number
      LET qbeats =   a2            // Note qbeats (crochet = 1024)
      writef("%t8 ", opname)
      prnote(letter, sharps, note, qbeats)
      writef(" <%n/%n>", fno, ln)
      RETURN
    }

    CASE s_rest:    // [-, Rest,  ln, qlen]
    CASE s_space:   // [-, Space, ln, qlen]
    { LET qbeats = a1
      writef("%t7 %n <%n/%n>", opname, qbeats, fno, ln)
      RETURN
    }

    CASE s_null:   // [-, null, ln]
      writef("%s <%n/%n>", opname, fno, ln)
      RETURN

    CASE s_control:       writef("Control (%n %n)", a1, a2);  RETURN
    CASE s_timesig:       writef("Timesig (%n %n)", a1, a2);  RETURN

    CASE s_bank:          writef("Bank    (%n %n)", a1, a2);  RETURN

    CASE s_patch:         writef("Patch   %n", a1);           RETURN

    CASE s_transposition: writef("Transposition (%n)", a1);   RETURN

    CASE s_keysig:
      // [-, keysig, ln, [-, note, ln, <letter, sharps, noteno>, mode]
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
    CASE s_name:                 // eg Piano LH
    CASE s_instrumentname:       // eg Flute
    CASE s_instrumentshortname:
    CASE s_barlabel:
    CASE s_partlabel:
      writef("%t7 *"%s*"  <%n/%n>", opname, a1, fno, ln)
      RETURN

    CASE s_list:      // [-, List, ln, list]
      writef("%s", opname)
      GOTO prlist

    CASE s_seq:       // [-, seq,   ln, list, qlen]
    CASE s_par:       // [-, par,   ln, list, qlen]
      writef("%s qlen=%n <%n/%n>", opname, h5!t, fno, ln)

      // Print each item in the list
prlist:
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
    CASE s_block:     // [-, block, ln, body, envblk, shapeitems, qstart, qend]
      writef("%s parent=%n shapeitems=%n qstart=%n qend=%n <%n/%n>*n",
              opname, h5!t, h6!t, h7!t, h8!t, fno, ln)
      IF h6!t DO
      { prblockenv(t)
      } 
      FOR j=0 TO n-1 DO writes( v!j )
      writes("**-")
      v!n := "  "
      prtree(a1, n+1, d)      
      RETURN

    CASE s_conductor: // [-, Conductor, ln, noteitem]
    CASE s_part:      // [-, Part,      ln, noteitem, channel]
    CASE s_solo:      // [-, Solo,      ln, noteitem, channel]
      writef("%s <%n/%n>*n", opname, fno, ln)
      FOR j=0 TO n-1 DO writes( v!j )
      writes("**-")
      v!n := "  "
      prtree(a1, n+1, d)      
      RETURN

    CASE s_score:     // [-, Score, ln, name, conductor, parts]
      writef("%s *"%s*" <%n/%n>*n", opname, a1, fno, ln)
      FOR j = 0 TO n-1 DO writes( v!j )
      writes("**-")
      v!n := "! "
      prtree(a2, n+1, d)
      newline()
      FOR j = 0 TO n-1 DO writes( v!j )
      writes("**-")
      v!n := "  "
      prtree(h6!t, n+1, d)
      RETURN       

    // Dyadic shape operators, typically
    // [-, op, ln, notes, qlen, shape]
    CASE s_vibrate:
    CASE s_vibrateadj:
    CASE s_vibamp:
    CASE s_vibampadj:
    CASE s_vol:
    CASE s_voladj:
    CASE s_tempo:
    CASE s_tempoadj:
    CASE s_legato:
    CASE s_legatoadj:
    CASE s_delay:
    CASE s_delayadj: // [-, op, ln, notes, shape_list]
      writef("%s <%n/%n>*n", opname, fno, ln)
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

    CASE s_volmap: // [-, op, ln, shape_list]
      writef("%s <%n/%n>*n", opname, fno, ln)
      FOR j = 0 TO n-1 DO writes( v!j )
      writes("**-")
      v!n := "  "
      prtree(a1, n+1, d)
      RETURN       

    CASE s_tuplet: // [-, op, ln, notes, notes]
      writef("%s <%n/%n>", opname, fno, ln)
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

LET trscores(x) = VALOF IF x SWITCHON h2!x INTO
{ // Return TRUE if successful
  DEFAULT:
    tokln := h3!x
    qbeats := -1 // Stop the error message having a bar number
    trerr(-1, "Bad Mus tree")
    RESULTIS FALSE

  CASE s_seq:       // Sequence of scores
  { LET a = h4!x
    WHILE a DO
    { UNLESS trscore(a) RESULTIS FALSE
      a := !a
    }
    RESULTIS TRUE
  }

  CASE s_score:     // A score
    RESULTIS trscore(x)
}

AND trscore(t) = t=0 -> FALSE, VALOF
{ // Append the midi items corresponding to score t onto the
  // end of midilist. midiliste points to its last link field.
  // t -> [-, Score, ln, name, conductor, parts]
  LET op        = h2!t
  LET name      = h4!t
  LET conductor = h5!t
  LET parts     = h6!t
  LET qlen      = 0

  tokln := h3!t   // For error messages
  barqerr := 0

  midichannel := -1 // No Midi channel used yet
  currpartname := 0 // No part name yet

  IF op=s_interval RESULTIS FALSE

  qbeats := 0
  scbase, scfaca, scfacb := 0,   0,  0   // No scaling yet

  plist, tlist, clist    := 0,   0,  0   // No ties yet
  pqpos, tqpos, cqpos    := -1, -1, -1

  UNLESS op=s_score & conductor & parts DO
  { trerr(-1, "Bad score")
    RESULTIS FALSE
  }

  // t -> [-, Score, ln, name, conductor, parts]

  conductorblk := h4!conductor
  UNLESS conductorblk & h2!conductorblk=s_block DO
  { tokln := h3!conductor
    trerr(-1, "The conductor part must be a block")
    RESULTIS FALSE
  }

  writef("*nTranslating score: *"%s*"*n", name)

  // First create the bar and beat tables from the conductor's part.
  // These are both self expanding tables.

  // bartabcb  -> [upb, v] where upb is zero or the upperbound of v
  // beattabcb -> [upb, v] where upb is zero or the upperbound of v

  pushval(bartabcb,  0) // Bar  1 starts at qbeat 0
  pushval(beattabcb, 0) // Beat 1 starts at qbeat 0

//writef("Calling barscan of the conductor part*n")

  qbeats, barno := 0, 1

  // Update maxbarno and bartab every time barno changes.
  maxbarno, bartab := barno, bartabcb!1

  // Set initial scaline parameters (no scaling).
  scbase, scfaca, scfacb := 0, 0, 0

//  barscan(h4!conductorblk)
  barscan(conductor)
  //writef("Returned from barscan, qbeats=%n*n", qbeats)

  bartab := bartabcb!1   // bartab -> [n, q1,...,qn]
                         // where n-1 is the maximum bar number
                         // and qi is the qbeat value at the start of bar i

  beattab := beattabcb!1 // beattab -> [n, q1,...,qn]
                         // where n-1 is the maximum beat number
                         // and qi is the qbeat value at the start of beat i

  maxbarno  := bartab!0 - 1
  maxbeatno := beattab!0 - 1

  // bartab has entries for bar 1 up to bar maxbarno.
  // The qbeat value at the start of bar n is bartab!n
  // but if n is greater than maxbarno, it is calculated assuming
  // the extra bars have the same qbeat length as the last conductor
  // bar. The fuction barno2qbeats performs this calculation.

//FOR bno = 1 TO maxbarno DO
//{ LET q  = barno2qbeats(bno)
//  LET q1 = barno2qbeats(bno+1)
//  writef("%i6: Bar %i2: qlen = %i5*n", q, bno, q1-q)
//}

  // Insert bartab at the head of veclist
  veclist := mk2(veclist, bartab)

  // Insert beattab at the head of veclist
  veclist := mk2(veclist, beattab)

  // The bar and beat tables are now populated, so optionally
  // write them out.

  IF FALSE DO
  { TEST bartab
    THEN { writef("*nBar table upb=%n*n*n", maxbarno)
           FOR i = 1 TO maxbarno+1 DO
           { writef(" %i5:%i8", i, bartab!i)
             IF i MOD 5 = 0 DO newline()
           }
           newline()
         }
    ELSE writef("No bar table*n")
//abort(1001)
  }

  IF FALSE DO
  { TEST beattab
    THEN { writef("*nBeat table upb=%n*n*n", maxbeatno)
           FOR i = 1 TO maxbeatno DO
           { writef(" %i5:%i8", i, beattab!i)
             IF i MOD 5 = 0 DO newline()
           }
           newline()
         }
    ELSE writef("No beat table*n")
//abort(1001)
  }

  // Insert block nodes where necessary.

  //writef("Inserting conductor blocks=%n*n*n")

  qbeats := 0
  insertblocks(conductor, 0)

  //writef("Inserting parts blocks*n")
  qbeats := 0
  insertblocks(parts, conductorblk)

  //writef("*nInitialising conductor shapeitems*n*n")
  initshapeitems(conductorblk, 0, 0) // No environment and qpos=0

  //writef("*nInitialising parts shapeitems*n*n")
  qbeats := 0
  initshapeitems(parts, conductorblk)

  //writef("*ntrscore: All blocks have been inserted and initialised*n")

//abort(1009)
  // Insert shape data in all blocks

  // Calculate the midi msecs of the start and end of the playback.    
  writef("*nSelecting bars %n to ", startbarno)
  TEST endbarno<#x3FFFFFFF
  THEN writef("%n", endbarno)
  ELSE writef("the end")
  newline()

  IF endbarno>maxbarno DO endbarno := maxbarno

  start_msecs := barno2msecs(startbarno, conductorblk) - 0_100
  end_msecs   := barno2msecs(endbarno+1, conductorblk)

  newline()
  writef("Start time: %9.3d midi secs*n",   start_msecs)
  writef("End   time: %9.3d midi secs*n", end_msecs)

  // Set elements of barmsecs
  //writef("Allocating barmsecs maxbarno is %n*n", maxbarno)
  barmsecs := getvec(maxbarno + 1) 
  UNLESS barmsecs DO
  { writef("Unable to allocate space for barmsecs*n")
    RESULTIS FALSE
  }

  // Remember to free the barmsecs vector.
  veclist := mk2(veclist, barmsecs)

  FOR bno = 1 TO maxbarno DO
  { LET ms = qbeats2msecs(bartab!bno, conductorblk)
    barmsecs!bno := ms
    //writef("Setting barmsecs!%i3 qbeat=%i7 = %8.3d*n",
    //        bno, bartab!bno, ms)
  }

    // Change the elements of beatmsecs fromqbeats to msecs
  beatmsecs := getvec(maxbeatno)
  UNLESS beatmsecs DO
  { trerr("More space needed")
    RESULTIS FALSE
  }

  // Remember to free the beatmsecs vector.
  veclist := mk2(veclist, beatmsecs)

  //writef("Setting beatmsecs, beatmsecs!0=%n*n", maxbeatno)
  FOR beat = 1 TO maxbeatno DO
  { LET ms = qbeats2msecs(beattab!beat, conductorblk)
    //writef("Setting beatmsecs!%i4 qbeat=%i7 = %8.3d*n",
    //        beat, beattab!beat, ms)
    beatmsecs!beat := ms
  }
  //abort(1112)

  midichannel := -1  // No midi channel yet
  transposition := 0 // No transposition specified yet
  qbeats := 0
  genmidi(parts, conductorblk)
//writef("*ntrscore: Returned from genmidi(parts,...)*n")
//prties()

  IF optPtree DO { writes("*nThe Tree after midi generation*n*n")
                   prtree(t, 0, 20)
                   newline()
                 }

  RESULTIS TRUE
}

AND qbeatlength(t) = t=0 -> 0, VALOF
{ // Return the qbeat length of construct x
  // assuming that x has already been bar scanned so
  // nodes such as seq and par already have their qlen fields
  // filled in.
//sawritef("qbeatlength called*n")
  LET op = h2!t  // The tree node operator
  LET ln = h3!t  // The fno/ln number of the tree node
  LET a1 = h4!t  // The first operand, if any, of the tree node
  LET a2 = h5!t  // The second operand, if any, of the tree node
  LET opname  = opstr(op)
  LET fno = ln>>20
  ln := ln & #xFFFFF

//writef("qbeatlength: op=%14t a1=%i7 <%n/%n>", opname, a1, fno, ln)
//newline()
//writef("%n %10t:*n", t, opname)
//abort(1003)

  SWITCHON op INTO
  { DEFAULT:
      RESULTIS 0

    CASE s_note:      // t -> [-, Note,     ln, <letter,sharps,n>, qlen]
    CASE s_notetied:  // t -> [-, Notetied, ln, <letter,sharps,n>, qlen]
      // Return the qbeats value of the next note item. 
      RESULTIS a2

    CASE s_rest:
    CASE s_space:
      RESULTIS a1

    CASE s_block:      // [-, Block, ln, noteitem,  env, shapeitems, q1, q2]
    CASE s_conductor:  // [-, Conductor, ln, noteitem,  envblk]
    CASE s_part:       // [-, Part,      ln, noteitem,  envblk]
    CASE s_solo:       // [-, Solo,      ln, noteitem,  envblk]
    CASE s_tuplet:     // [-, Tuplet,    ln, noteitem,  noteitem]

    CASE s_delay:      // [-, delay,     ln, noteitem, shape]
    CASE s_delayadj:   // [-, delayadj,  ln, noteitem, shape]
    CASE s_legato:     // [-, legato,    ln, noteitem, shape]
    CASE s_legatoadj:  // [-, legatoadj, ln, noteitem, shape]
    CASE s_tempo:      // [-, tempo,     ln, noteitem, shape]
    CASE s_tempoadj:   // [-, tempoadj,  ln, noteitem, shape]
    CASE s_vibrate:    // [-, vibrate,   ln, noteitem, shape]
    CASE s_vibrateadj: // [-, vibrateadj,ln, noteitem, shape]
    CASE s_vibamp:     // [-, vibamp,    ln, noteitem, shape]
    CASE s_vibampadj:  // [-, vibampadj, ln, noteitem, shape]
    CASE s_vol:        // [-, vol,       ln, noteitem, shape]
    CASE s_voladj:     // [-, voladj,    ln, noteitem, shape]
      RESULTIS qbeatlength(a1)


    CASE s_seq:       // [-, Seq, ln, list, qlen]
    { LET res = 0

      IF h5!t>=0 RESULTIS h5!t
         
      WHILE a1 DO
      { res := res + qbeatlength(a1)
        a1 := !a1
      }
      h5!t := res
      RESULTIS res
    }

    CASE s_par:       // [-, Seq, ln, list, qlen]
    { LET res = 0

      IF h5!t>=0 RESULTIS h5!t
         
      WHILE a1 DO
      { LET len = qbeatlength(a1)
        IF len>res DO res := len
        a1 := !a1
      }
      h5!t := res
      RESULTIS res
    }
  }
}

AND shapelistlength(list) = list=0 -> 0, VALOF
{ // list -> [-, List, ln, itemlist]

  // list is a list of possibly tied numbers or stars, or spaces.

  // It returns the length of the shape list in qbeats.
  // qbeats is incremented by spaces, eg s4, s8.., etc
  // If no spaces occur between values a separation of s4 is assumed.

  LET res = 0
  LET prevnum = FALSE
  LET prevlen = 1024

//writef("shapelistlength: %n %s:*n", list, opname)
//abort(1000)
  UNLESS h2!list=s_list DO trerr(-1, "Bad shape list")

  list := h4!list
  // list is now the list of shape items.

  WHILE list DO
  { LET op, ln = h2!list, h3!list
    LET opname = opstr(op)
    LET fno = ln>>20
    ln := ln & #xFFFFF

    tokln := h3!list

    SWITCHON op INTO
    { DEFAULT:
        trerr(-1, "Bad op %s in shape list", opname)
        ENDCASE

      //CASE s_list:             // [-, List,     ln, shapeitems]
      //  res := res + shapelistlength(h4!list)
      //  ENDCASE

      CASE s_star:             // [-, Star,     ln]
      CASE s_startied:         // [-, Startied, ln]
      CASE s_num:              // [-, Num,      ln, value]
      CASE s_numtied:          // [-, Numtied,  ln, value]
      { LET val = numval
        //writef("%s -- <%n/%n>*n", opname, fno, ln)
        IF prevnum DO
        { // Assume s4 between numbers
          res := res + prevlen
        }
        prevnum := TRUE
        ENDCASE
      }

      CASE s_space:            // [-, Num, ln, qlen]
      { LET qlen = h4!list
        //writef("%t7 qlen=%n*n", opname, qlen)
        res := res + qlen
        prevlen := qlen
        prevnum := FALSE
        ENDCASE
      }
    }

    list := !list
  }

  RESULTIS res
}

AND updatebeattable(op, qbeats, barno) BE
{ // This function updates the beat table checking that the current qbeat
  // value is compatible with the current time signature.
  // It is only called when a time signature or bar line is
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
  { LET str = op=s_timesig -> "Time signature", "Bar line"
     writef("Error: %s misplaced in bar=%n*n", str, barno)
  }
}

AND barscan(x) BE WHILE x DO
{ // This is only called to scan the conductor's part.
  // It adds entries to the bar and beat self expanding tables whose
  // control blocks are bartabcb and beattabcb. These tables are used
  // by the error message functions and playmidi. As it walks over the
  // tree it increments the globals qbeats and barno which
  // should be intialised to 0, 1 and 1 respectively.
  LET op = h2!x
  tokln := h3!x

  //writef("barscan: op=%s ln=%n/%n*n", opstr(op), ln>>20, ln&#xFFFFF)

  SWITCHON op INTO
  { DEFAULT: // Ignore all the other tree nodes
      ENDCASE

    CASE s_conductor: // [-, Conductor, ln, body]
      x := h4!x
      LOOP

    CASE s_name: // [-, Name, ln, str]
      currpartname := h4!x
      ENDCASE

    CASE s_tuplet:
      trerr(-1, "\tuple is not permitted in the conductor's part")
      ENDCASE

    CASE s_par:
      trerr(-1, "\par is not permitted in the conductor's part")
      ENDCASE

    CASE s_block:
      x := h4!x
      LOOP

    CASE s_note:
    CASE s_notetied:
      trerr(-1, "Notes are not permitted in the conductor's part")
      qbeats := qbeats + h5!x
      ENDCASE

    CASE s_space:
    CASE s_rest:
      qbeats := qbeats + h4!x
      ENDCASE

    CASE s_tempo:
    CASE s_tempoadj:
    CASE s_vol:
    CASE s_voladj:
    CASE s_legato:
    CASE s_legatoadj:
    CASE s_delay:
    CASE s_delayadj:
    CASE s_vibrate:
    CASE s_vibrateadj:
    CASE s_vibamp:
    CASE s_vibampadj:  // [-, op, ln, list, shape]

    CASE s_seq:        // [-, Seq, ln, list, qlen]
      barscan(h4!x)
      ENDCASE

    CASE s_barline:
    CASE s_doublebar:
      // Fill in entries in the bar and beat tables.
      updatebeattable(op, qbeats, barno)
      // Fill in the qbeat value of the new bar
      pushval(bartabcb, qbeats)
      barno := barno + 1
      maxbarno, bartab := barno, bartabcb!1
      ENDCASE

    CASE s_timesig:   // [-, Timesig, ln, a1, a2]
    { // This is used in the conductor part to construct the mapping
      // vector from beat number to qbeat value. The qbeat values are
      // later replaced by msecs values.
      // A warning is given if a timesig statement or bar line does
      // not occur at the time of a beat. Timesig statements can occur
      // in the middle of bars as in:
      // | \timesig(3 8) r4. r4. \timesig(2 8) r4 |
      updatebeattable(op, qbeats, barno)
      timesiga, timesigb, prevbeatqbeat := h4!x, h5!x, qbeats
      qbeatsperbeat := 4096/timesigb
      beatcount := 1
//writef("timesig: %n %n qbeat=%n*n", timesiga, timesigb, qbeats)
      ENDCASE
    }

    //CASE s_conductor: // [-, Conductor, ln, noteitem,  env]
      x := h4!x
      LOOP
  }
  x := !x  // Look at the next item in the list
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
    { trerr(-1, "More memory needed")
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
//IF debugv!1 DO
//{  writef("pushval: replacing v=%i6 upb=%i5 with newv=%i7 upb=%i5*n",
//           v, upb, newv, newupb)
//   //abort(6666)
//}
    v := newv
  }
  p := p+1
  v!0, v!p := p, x
//IF debugv!1 DO
//  writef("pushval: updating v[%i3] with %i9*n", p, x)
}

// Implementation of note ties.

// The ties information is held in the globals plist, tlist, clist
// pqpos, tqpos and cqpos. tlist holds a list of unresolved tied notes
// that started in the current note thread. Normally tlist is empty or
// just contains one item, but just after a Par or Tuplet construct the
// list may contain more than one unresolved tie. Multiple ties in tlist
// can only be resolved by multiple note threads arising from a Par or
// Tuplet construct. Each item in tlist is of the form [link, note, absq],
// where note is the midi note number (after transposition and pitch change)
// and absq is the absolute qbeat position of the start of the note
// ignoring legato and delay effects. The nominal end position of every
// note in tlist is held in tqpos.
// This list plist hold unresolved ties at the start of a Par or Tuplet
// construct. These can be resolved by notes at the start of any of the
// resulting note threads.
// clist holds the collection of outstanding ties at the end of each thread
// of a Par or Tuplet construct. When such a construct is completed, clist
// becomes the new tlist since the multiple thread have now joined to become
// one.

AND istied(note, absq) = VALOF
{ // note is a midi notenumber (after transposition and pitch change).
  // absq is the current scaled qbeat position.

  // The result is TRUE if this note resolves a tie, in which case
  // the tie item is removed from its list (tlist or plist).

  // This function is only called when a Note or Notetied
  // is encountered while generating midi data (in genmidi).

  LET a   = 0

//LET str = VEC 5
//writef("istied: called note=%s qbeats=%n*n",
//        note2str(note, str), qbeats)
//prties()

  // Choose the list to search through.
  IF plist & absq=pqpos DO a := @plist
  IF tlist & absq=tqpos DO a := @tlist

  // Attempt to find and remove a resolvable tie.

  WHILE a & !a DO
  { // Check if this note resolves a tie in this list.
    LET t = !a   // -> [link, midi_note, absqstart]
    LET midi_note = h2!t
    LET absqstart = h3!t
    IF note=midi_note DO
    { // Item t can be resolved so remove it from its list
      //writef("*nistied: note %n at %n has been resolved at %n*n",
      //        note, absqstart, absq)
      !a := !t
      unmk3(t)
      RESULTIS TRUE
    }
    a := !a
  }

  RESULTIS FALSE
}

AND checktlist(envblk) BE
{ // When called any tie in tlist is unresolvable so generate
  // error messages for any items in the list and issue appropriate
  // note_off commands.
  // envblk is used in the calculation of midimsecs value of any
  // note_off commands generated.
  // On return tlist will be zero and tqpos will be negative.

  WHILE tlist DO
  { // This tie is unresolvable so remove it and generate a warning
    // message and issue a note_off command.
    LET next      = h1!tlist
    LET midi_note = h2!tlist
    LET absqstart = h3!tlist
    LET midimsecs = qbeats2msecs(tqpos, envblk)
    LET str = VEC 5
    note2str(midi_note, str)

    
trerr(absqstart, "Unresolvable tied note %s", str)
    apmidi(midimsecs,
           midi_note_off+midichannel+(midi_note<<8))
    IF optNtrace DO
      writef("%9.3d Note Off: chan=%n note=%t4*n",
              midimsecs, midichannel, str)
//abort(1000)
    unmk3(tlist)  // Return the current tie item to free store.
    tlist := next
  }

  tlist, tqpos := 0, -1
}

AND prties() BE
{ LET t, c, p = tlist, clist, plist
  LET str = VEC 5

  UNLESS t | c | p DO { writef("No outstanding ties*n*n"); RETURN }
  IF t DO
  { writef("*ntlist tqpos =%i5:", tqpos)
    WHILE t DO
    { writef(" (%s,%n)", note2str(t!1&127, str), t!2)
      t := !t
    }
  }
  IF c DO
  { writef("*nclist cqpos =%i5:", cqpos)
    WHILE c DO
    { writef(" (%s,%n)", note2str(c!1&127, str), c!2)
      c := !c
    }
  }
  IF p DO
  { writef("*nplist pqpos =%i5:", pqpos)
    WHILE p DO
    { writef(" (%s,%n)", note2str(p!1&127, str), p!2)
      p := !p
    }
  }
  newline()
  newline()
}

AND barno2qbeats(bno) = VALOF
{ // Bar 1 starts at qbeat=0 (=bartab!1)
  LET blen = 4096 // Default bar length
  IF bno<1 RESULTIS 0
  IF bno<=maxbarno RESULTIS bartab!bno
  // Calculate the final bar length
  IF maxbarno>1 DO blen := bartab!(maxbarno+1) - bartab!maxbarno
  IF blen=0 DO blen := 4096 // Just in case last bar has length zero
  // pad with bars of the last bar length
  RESULTIS bartab!maxbarno + blen*(bno-maxbarno)
}

AND qbeats2barno(qb) = VALOF
{ IF maxbarno=0 RESULTIS -1

//writef("qbeats2barno: qb=%n currbarno=%n*n", qb, currbarno)

  WHILE currbarno > 1 DO
  { IF qb >= barno2qbeats(currbarno) BREAK
    currbarno := currbarno-1
//writef("qbeats2barno: qb=%n currbarno=%n*n", qb, currbarno)
  }

  WHILE qb >= barno2qbeats(currbarno+1) DO
  { currbarno := currbarno+1
//writef("qbeats2barno: qb=%n currbarno=%n*n", qb, currbarno)
  }
//writef("qbeats2barno: returning %n*n", currbarno)
  RESULTIS currbarno
}

// Scale a local qbeat position to an absolute position
AND qscale(q) = VALOF
{ LET res = ?
  TEST scfaca~=scfacb & scfacb
  THEN res := scbase + muldiv(q, scfaca, scfacb)
  ELSE res := scbase + q
  //writef("qscale: q=%n scbase=%n scfaca=%n scfacb=%n => %n*n",
  //        q, scbase, scfaca, scfacb, res)
  RESULTIS res
}

AND genmidi(t, envblk) BE
{ // t is the leading tree node of a segment of notes.
  // envblk is the current shape environment block.

  // The globals
  // qbeats hold the absolute qbeat position of the start of the segement.
  // tlist and clist hold the current outstanding ties.
  // scbase, scfaca and scfacb hold the current scaling parameters.

  // envblk -> [link, s_block, ln, prevenv, shapelist, qstart, qend]
  //           ln is a line/file number
  //           prevenv points to the enclosing environment
  //           shapelist is 0
  //                     or -> [link, kind, shapedata]
  //                        kind = s_tempo, s_tempoadj,
  //                               s_vibrate, s_vibrateadj,
  //                               s_vibamp, s_vibampadj,
  //                               s_vol, s_voladj,
  //                               s_legato, s_legatoadj,
  //                               s_delay or s_delayadj.
  //                        shapedata -> [2n, q1, x1,... qn,xn]
  //                            qi is a qbeat value and
  //                            xi is the corresponding shape data value.
  //                            q1 = qstart
  //                            qn = qend
  //                            For * and *~ the xi value is maxint.
  //           qstart is the qbeat position at the start of the block
  //           qend   is the qbeat position at the end of the block

  // The scaling parameters are held in the globals
  // scbase, scfaca and scfacb. These are required for the implementation
  // of (x)\tuplet(y).
  // scbase is the qbeat of the start of note segment x after scaling,
  // scfaca is the number of qbeats in x after scaling,
  // scfacb is the number of qbeats in note segment y before scaling.
  // Assuming the translation of y started with qbeats=qbase, the scaled
  // version of qbeats is:

  //        scbase + muldiv(qbeats, scfaca, scfacb).

  // Clearly if scfaca=scfacb no scaling is required.

  // Midi data is appended to a list of midi events (midilist) whose
  // last node is pointed to by midiliste.
  // Each node in the list is of the form [link, msecs, midi_triple]
  // where link points to the next item, msecs is the time of this event
  // in milli-seconds from the start of the score, and midi_triple is a packed
  // triplet of bytes representing a midi event. The least significant byte
  // is the Midi operator (eg note_on or note_off + the Midi
  // channel number(0..15)). The senior 24 bits provide up to 3 bytes of
  // operand, such as a midi note number and pressure. Although not
  // currently used, a non midi operation can be represented using a least
  // significant byte less that 128.

  LET op = h2!t  // The tree node operator
  LET ln = h3!t  // The fno/ln number of the tree node
  LET a1 = h4!t  // The first operand, if any, of the tree node
  LET a2 = h5!t  // The second operand, if any, of the tree node

  LET opname  = opstr(op)
  LET fno = ln>>20
  tokln := ln
  ln := ln & #xFFFFF

//writef("genmidi: qbeats=%n ", qbeats)
//writef("op=%14t a1=%i7 <%n/%n>*n", opname, a1, fno, ln)
//writef("%n %10t:*n", t, opname)
//newline()
//abort(1003)

  IF optNtrace DO
  { LET aq = qscale(qbeats)
    LET t = qbeats2msecs(aq, envblk)
    //writef("%9.3d ", t)
    //writef("%10t aq=%n q=%n bar=%n <%n/%i3>",
    //       opname, aq, qbeats, qbeats2barno(aq), fno, ln)
    //writef("tmp=%i3 ", getshapeval(aq, envblk, s_tempo, s_tempoadj)/1000)
    //writef("dly=%i3 ", getshapeval(aq, envblk, s_delay, s_delayadj)/1000)
    //writef("vol=%i3 ", getshapeval(aq, envblk, s_vol, s_voladj)/1000)
    //writef("leg=%i3 ", getshapeval(aq, envblk, s_legato, s_legatoadj)/1000)
//    newline()
//    writef(" t=%7.3d**%7.3d%%",
//            lookupshapeval(aq, s_tempo, envblk),
//            lookupshapeval(aq, s_tempoadj, envblk))
//    writef(" d=%7.3d**%7.3d%%",
//            lookupshapeval(aq, s_delay, envblk),
//            lookupshapeval(aq, s_delayadj, envblk))
//    writef(" v=%7.3d**%7.3d%%",
//            lookupshapeval(aq, s_vol, envblk),
//            lookupshapeval(aq, s_voladj, envblk))
//    writef(" l=%7.3d**%7.3d%%",
//            lookupshapeval(aq, s_legato, envblk),
//            lookupshapeval(aq, s_legatoadj, envblk))
    //newline()
  }

  SWITCHON op INTO
  { DEFAULT:
      // Ignore most node types
      RETURN

    CASE s_name:
      currpartname := h4!t
      IF optNtrace DO
      { LET aq = qscale(qbeats)
        LET t = qbeats2msecs(aq, envblk)
        writef("*n%9.3d %s*n*n", t, currpartname)
      }
      RETURN

    CASE s_varvol:     // t -> [-, varvol,   ln]
       // Volume may change while a note is being played
       // as is typical of wind instruments
       variablevol := TRUE
       RETURN

    CASE s_nonvarvol:  // t -> [-, nonvarvol,ln]
       // Volume may not change while a note is being played
       // as is typical of keyboard instruments
       variablevol := FALSE
       RETURN

    CASE s_pedon:      // t -> [-, pedon,    ln]
    CASE s_pedoff:     // t -> [-, pedoff,   ln]
    CASE s_pedoffon:   // t -> [-, pedoffon, ln]
    CASE s_portaon:    // t -> [-, portaon,  ln]
    CASE s_portaoff:   // t -> [-, portaoff, ln]
    CASE s_softon:     // t -> [-, softon,   ln]
    CASE s_softoff:    // t -> [-, softoff,  ln]

    CASE s_control:    // t -> [-, control, ln, controller, value]
    { LET dly = getshapeval(qbeats, envblk, s_delay, s_delayadj)/1000
      // qbeats and dly are both unscaled qbeat values
      LET absq = qscale(qbeats+dly)
      // Use the timemap data in the environment to calculate the
      // midi msecs value.
      LET midimsecs = qbeats2msecs(absq, envblk)
      LET chan      = midichannel // chan in range 0 to 15 

      SWITCHON op INTO
      { DEFAULT:
          writef("genmidi: Bad op %s (%n) qbeats=%n*n",
                 opname, op, qbeats)
          abort(999)
          RETURN

        CASE s_pedon:     a1, a2 := 64, 127; ENDCASE
        CASE s_pedoff:    a1, a2 := 64,   0; ENDCASE
        CASE s_pedoffon:  a1, a2 := 64,   0; ENDCASE
        CASE s_portaon:   a1, a2 := 65, 127; ENDCASE
        CASE s_portaoff:  a1, a2 := 65,   0; ENDCASE
        CASE s_softon:    a1, a2 := 66, 127; ENDCASE
        CASE s_softoff:   a1, a2 := 66,   0; ENDCASE
        CASE s_control:                      ENDCASE
      }

      apmidi(midimsecs,                                // Msecs
             midi_control+chan+(a1<<8)+(a2<<16)) // Control
      IF optNtrace DO
        writef("%9.3d Control:   chan=%n ctrl=%i3  val=%n*n",
                midimsecs, chan, a1, a2)
      IF op=s_pedoffon DO
      { a2 := 127   // pedoff to pedon
        // Delay pedon by 10 msecs
        apmidi(midimsecs+10,                             // Msecs
               midi_control+chan+(a1<<8)+(a2<<16)) // Control
        IF optNtrace DO
          writef("%9.3d Control:   chan=%n ctrl=%i3  val=%n*n",
                  midimsecs, chan, a1, a2)
      }
      RETURN
    }

    CASE s_rest:
    CASE s_space:
//writef("genmidi: rest: qbeats=%n qlen=%n*n", qbeats, a1)
      qbeats := qbeats + a1
      // Check for unresolved ties is tlist.
      checktlist(envblk)
      RETURN

    CASE s_note:      // t -> [-, Note,     ln, <letter,sharps,n>, qlen]
    CASE s_notetied:  // t -> [-, Notetied, ln, <letter,sharps,n>, qlen]
//writef("CASE s_note or s_notetied:*n")
    { 
      LET n      =  a1      & 255
      LET sharps = (a1>> 8) & 255
      LET letter = (a1>>16) & 255
      // Find the requires Midi note number
      LET midi_note  = n + transposition + pitch  // The transposed note
      LET qlen   = h5!t // Length of the note in qbeats

      LET nomqs  = qscale(qbeats)
      LET nomqe  = qscale(qbeats+qlen)

//writef("genmidi: Note/Notetied %n*n", midi_note)

      UNLESS istied(midi_note, nomqs) DO
      { // This note does not resolve a previous ties, so play it.
        LET dly       = getshapeval(nomqs, envblk, s_delay,  s_delayadj)/1000
        LET legato    = getshapeval(nomqs, envblk, s_legato, s_legatoadj)
        LET absqs     = qscale(qbeats+dly)
        LET midimsecs = qbeats2msecs(absqs, envblk)
        LET chan = midichannel // chan in range 0 to 15
        // The +1 is a fudge at the moment to avoid a problem
        // when two different shape values are at the same
        // qbeat position. May be this should not be allowed
        // to happen.
        LET vol = getshapeval(nomqs+1, envblk, s_vol, s_voladj)

        // Scale volume 0 to 100_000 to midi range 0 to 127
        vol := (127 * vol + 50_000)/100_000
        IF vol>127 DO vol := 127
        IF vol<0   DO vol := 0

        //writef("*ngenmidi: %9.3d %t8  ", midimsecs, opname)
        //prnote(letter, sharps, n, qlen)
        //writef(" vol=%9.3d legato=%9.3d*n", vol, legato)
//abort(1010)
//writef("qbeats=%n to %n delay=%n*n", qbeats, qbeats+qlen, dly)
        //IF transposition DO
        //  writef("getmidi: note %i3 transposed to %i3*n  ", n, midi_note)

        // Schedule a note_on command.
        TEST variablevol
        THEN { // This note should modify its volume as it is played
               UNLESS vol=chanvol DO
               { apmidi(midimsecs,               // Channel volume
                       midi_control+midichannel+(7<<8)+(vol<<16))
                 IF optNtrace DO
                   writef("%9.3d Chan vol:  midichannel=%n vol=%n*n",
                     midimsecs, midichannel, vol)
                 chanvol := vol
               }
               apmidi(midimsecs,                                // Note on
                      midi_note_on+midichannel+(midi_note<<8)+(127<<16))
               IF optNtrace DO
                 writef("%9.3d Note On:   midichannel=%n note=%t4  vol=%n*n",
                   midimsecs, midichannel, note2str(midi_note, strv), 127)
               FOR q = qbeats+64 TO qbeats+qlen-32 BY 128 DO
               { LET dly = getshapeval(q, envblk, s_delay,  s_delayadj)/1000
                 LET legato = getshapeval(q, envblk, s_legato, s_legatoadj)
                 LET absqs = qscale(q+dly)
                 LET midimsecs = qbeats2msecs(absqs, envblk)
                 LET vol = getshapeval(q+1, envblk, s_vol, s_voladj)

                 // Scale volume 0 to 100_000 to midi range 0 to 127
                 vol := (127 * vol + 50_000)/100_000
                 IF vol>127 DO vol := 127
                 IF vol<0   DO vol := 0

//writef("genmidi: Note chanvol=%n vol=%n*n", chanvol, vol)

                 UNLESS chanvol=vol DO
                 { apmidi(midimsecs,               // Channel volume
                         midi_control+midichannel+(7<<8)+(vol<<16))
                   IF optNtrace DO
                     writef("%9.3d Chan vol:  midichannel=%n vol=%n*n",
                       midimsecs, midichannel, vol)
                   chanvol := vol
                 }
               }
             }
        ELSE { apmidi(midimsecs,                                // Note on
                      midi_note_on+midichannel+(midi_note<<8)+(vol<<16))
               IF optNtrace DO
                 writef("%9.3d Note On:   midichannel=%n note=%t4  vol=%n*n",
                   midimsecs, midichannel, note2str(midi_note, strv), vol)

//              apmidi(midimsecs,                 // test GS percussion
//              midi_note_on+9+(71<<8)+(vol<<16))
             }
     }

     // Check that there are no unresolved ties in tlist
     checktlist(envblk)

     // tlist is now zero

     TEST op=s_notetied
     THEN { // This note is tied with a later one so don't
            // schedule its note off command, but insert an item
            // in the current list of unresolved tied notes.
            LET absqs = qscale(qbeats)   // Nominal start of note

            tqpos := qscale(qbeats+qlen) // Nominal end of note
            tlist := mk3(0, midi_note, absqs)
//writef("genmidi: note=%n qbeats=%n absqs=%n tqpos=%n in tlist*n",
//          midi_note, qbeats, absqs, tqpos)
//            prties()
          }
     ELSE { // This note is not tied to a later one,
            // so schedule a note off command.
            // The legatoness of a note is determined at its start.
            LET leg       = getshapeval(qbeats, envblk, s_legato, s_legatoadj)
            LET qe        = qbeats + muldiv(qlen, leg, 100_000)
            LET dly       = getshapeval(qe, envblk, s_delay, s_delayadj)/1000
            LET absqe     = qscale(qe+dly)
            LET midimsecs = qbeats2msecs(absqe, envblk)

//writef("%i7: Note off: midichannel=%n note=%i3  legato=%9.3d*n",
//       midimsecs, midichannel, n, leg)
            apmidi(midimsecs,                    // Note off
                   midi_note_off+midichannel+(midi_note<<8))
            IF optNtrace DO
              writef("%9.3d Note Off:  midichannel=%n note=%t4*n",
                      midimsecs, midichannel, note2str(midi_note, strv))
          }

      // Return the qbeats value of the next note item. 
      qbeats := qbeats + qlen
//writef("genmidi: note %n done qbeats=%n*n", midi_note, qbeats)
      RETURN
    }

    CASE s_transposition:
      transposition := a1
//writef("genmidi: transposition set to %n*n", transposition)
      RETURN


    CASE s_bank:
//writef("CASE s_bank:*n")
    { LET dly = getshapeval(qbeats, envblk, s_delay, s_delayadj)/1000
      // qbeats and dly are both unscaled qbeat values
      LET absq = qscale(qbeats+dly)
      // Use the timemap data in the environment to calculate the
      // midi msecs value.
      LET midimsecs = qbeats2msecs(absq, envblk)

      apmidi(midimsecs,                                       // Msecs
             midi_control+midichannel+(0<<8)+(a1<<16))  // Bank MSB
      apmidi(midimsecs,                                       // Msecs
             midi_control+midichannel+(32<<8)+(a2<<16)) // Bank LSB
      IF optNtrace DO
      { writef("%9.3d Bank:      midichannel=%n MSB=%n*n",
               midimsecs, midichannel, a1)
        writef("%9.3d Bank:      midichannel=%n LSB=%n*n",
               midimsecs, midichannel, a2)
      }
      RETURN
    }

    CASE s_patch:
//writef("CASE s_patch:*n")
    { LET dly = getshapeval(qbeats, envblk, s_delay, s_delayadj)/1000
      // qbeats and dly are both unscaled qbeat values
      LET absq = qscale(qbeats+dly)
      // Use the timemap data in the environment to calculate the
      // midi msecs value.
      LET midimsecs = qbeats2msecs(absq, envblk)

      apmidi(midimsecs,                            // Msecs
             midi_progchange+midichannel+(a1<<8))  // Patch command
      IF optNtrace DO
      { writef("%9.3d Patch:     midichannel=%n prog=%n*n",
               midimsecs, midichannel, a1)
      }
      RETURN
    }

    CASE s_part:      // [-, Part,      ln, noteitem,  env]
    CASE s_solo:      // [-, Solo,      ln, noteitem,  env]
      //writef("genmidi: %s*n", opname)

      barqerr := 0

      IF midichannel>=15 DO
        writef("Error: No more than 16 parts are allowed*n")

      // Choose next midi channel (avoiding 9 -- GM percussion)
      // midichannel will be in range 0 to 15
      midichannel := midichannel + 1 REPEATWHILE midichannel=9
      h5!t := midichannel
      chanvol := -1

      // Allow more than one solo part
      IF h2!t=s_solo & midichannel>=0 DO solochannels := 1<<midichannel

      transposition := 0 // No transposition specified yet
      qbeats := 0

      genmidi(a1, envblk)
      // Check that there are no outstanding ties.
//writef("genmidi: just finished generating a part or solo*n")
//prties()
//writef("genmidi: checking that there are no outstanding ties*n")
      checktlist(envblk)
//prties()
      RETURN

    CASE s_delay:      // [-, delay,     ln, noteitem, shape]
    CASE s_delayadj:   // [-, delayadj,  ln, noteitem, shape]
    CASE s_legato:     // [-, legato,    ln, noteitem, shape]
    CASE s_legatoadj:  // [-, legatoadj, ln, noteitem, shape]
    CASE s_tempo:      // [-, tempo,     ln, noteitem, shape]
    CASE s_tempoadj:   // [-, tempoadj,  ln, noteitem, shape]
    CASE s_vibrate:    // [-, vibrate,   ln, noteitem, shape]
    CASE s_vibrateadj: // [-, vibrateadj,ln, noteitem, shape]
    CASE s_vibamp:     // [-, vibamp,    ln, noteitem, shape]
    CASE s_vibampadj:  // [-, vibampadj, ln, noteitem, shape]
    CASE s_vol:        // [-, vol,       ln, noteitem, shape]
    CASE s_voladj:     // [-, voladj,    ln, noteitem, shape]

      genmidi(a1, envblk)
      RETURN

    CASE s_block:  // [-, Block, ln, body, parent, shapeitems, qstart, qend)
      //writef("genmidi: %s -- %n*n", opname, ln)
      chanvol := -1
      genmidi(a1, t)
      RETURN

    CASE s_seq:       // [-, Seq, ln, list, qlen]
      //writef("genmidi: %s -- %n*n", opname, ln)
      WHILE a1 DO
      { genmidi(a1, envblk)
        a1 := !a1
      }
      RETURN

    CASE s_barline:
    CASE s_doublebar:
    { LET aq = qscale(qbeats)
      LET t = qbeats2msecs(aq, envblk)
      LET absq = qscale(qbeats)
      LET bno  = qbeats2barno(absq)
      LET q1   = barno2qbeats(bno)
      LET q2   = barno2qbeats(bno+1)
      LET qerr = ?
      IF ABS(absq-q1) > ABS(q2-absq) DO bno, q1 := bno+1, q2
      qerr := absq - q1

      // Check tlist for unresolvable ties.
      IF tlist & tqpos~=absq DO
        checktlist(envblk)

      IF optNtrace DO
        writef("*n%9.3d Bar: %n*n", t, bno)

      UNLESS qerr=barqerr DO
      { barqerr := qerr
        trerr(absq, "Misplaced barline %n qbeats*
                    * (about %n semiquaver%-%ps) %s start of bar %n*n",
              ABS qerr, ABS qerr/256, (qerr<0 -> "before", "after"), bno)
      }
      RETURN
    }

    CASE s_par:       // t -> [-, Par, ln, list, qlen]
      // list is the list of items in the par construct
      // qlen is the qbeat length of the longest par item.
//writef("genmidi: %s qlen=%n -- <%n/%n> qbeats=%n*n",
//        opname, h5!t, fno, ln, qbeats)
//prties()

    { LET qlen  = a2     // qbeat length of longest element of the par.
      LET q0 = qbeats    // qbeat position of the start
                         // of the par construct.
      LET q1 = q0 + qlen // qbeat position of the end.
      LET absq0 = qscale(q0)
      LET absq1 = qscale(q1)
      LET count = 0      // Element number

      // Save old tie lists
      LET oclist, ocqpos = clist, cqpos
      LET oplist, opqpos = -1, -1
 //writef("genmidi: %s <%n/%n> saved clist*n",
 //        opname, fno, ln)

      TEST pqpos=absq0
      THEN { // This Par construct can resolve ties in plist, so do
             // not change it and do note restore it at the end.
 //writef("genmidi: this Par construct can resolve ties in plist*n")
           }
      ELSE { // This par construct cannot resolve ties in plist, so
             // set plist to the current tlist
 //writef("genmidi: this Par construct cannot resolve plist ties*n")
 //writef("genmidi: so save plist and set it to tlist*n")
             oplist, opqpos := plist, pqpos
             plist, pqpos := tlist, tqpos
           }

      // Set up the new clist.
      clist, cqpos := 0, absq1

      //writef("genmidi: setting tlist and clist to null*n")

      WHILE a1 DO
      { // Translate each member of the par construct
        count := count+1       // Count of members
        chanvol := -1

        // Start each member of the par construct at the same
        // local qbeat position
        qbeats := q0
        tlist, tqpos := 0, -1  // No outstanding ties in the current thread.
        
        //writef("genmidi: op=%s <%n/%n> starting par element %n*n",
        //        opname, fno, ln, count)
        //prties()
        genmidi(a1, envblk)
        //writef("genmidi: op=%s <%n/%n> finished par element %n*n",
        //        opname, fno, ln, count)
        //prties()

        tokln := h3!a1

        UNLESS qbeats-q0 = qlen DO
        { TEST h2!a1=s_part | h2!a1=s_solo
          THEN { LET bn1 = qbeats2barno(qbeats)
                 LET bn2 = qbeats2barno(q0+qlen)
                 LET qerr = q0 + qlen - qbeats
                 trerr(-1,
                   "Part ends %n qbeats early in bar %n, final bar is %n*n",
                   qerr, bn1, bn2)
               }
          ELSE { trerr(-1,
                  "Member %n of the par construct has qlen=%n, should be %n*n",
                  count, qbeats-q0, qlen)
               }
        }

        // Check for unresolvable ties in tlist
        IF tlist & tqpos~=absq1 DO
          checktlist(envblk)

        // Insert tlist onto the front of clist
        IF tlist DO
        { LET p = tlist
          WHILE !p DO p := !p
          !p := clist
          clist := tlist
          // cqpos is still absq1
        }

        // Inspect the next member of the par construct
//writef("tlist items have been added to clist*n")
//        writef("genmidi: tlist set to null*n")
//prties()
        a1 := !a1
      }

      // All members of the par construct have been processed, so
      // set tlist = clist, restore old clist, and conditionally
      // restore plist.

      IF oplist>=0 DO
      { // This par construct started later than an enclosing one,
        // so all ties in plist must have been resolved by now. 
        // Check for unresolved ties in plist.
        IF plist DO
        { tlist, tqpos := plist, pqpos
          checktlist(envblk)
        }
        // Restore previous plist
        plist, pqpos := oplist, opqpos
      }

      // Set tlist and clist appropriately.
      tlist, tqpos :=  clist,  cqpos
      clist, cqpos := oclist, ocqpos

      qbeats := q0 + qlen

//writef("Leaving par construct with qbeats=%n*n", qbeats)
//prties()
      RETURN
    }

    CASE s_tuplet:
    { // t -> [-, Tuplet, ln, noteitem, noteitem]

      LET lhs     = h4!t
      LET rhs     = h5!t
      LET lhsqlen = qbeatlength(lhs)
      LET rhsqlen = qbeatlength(rhs)

      LET q0      = qbeats       // qbeat position of the start
                                 // of the par construct.
      LET q1      = q0 + lhsqlen // qbeat position of the end.
      LET absq0   = qscale(q0)
      LET absq1   = qscale(q1)

      // Save old tie lists
      LET oclist, ocqpos = clist, cqpos
      LET oplist, opqpos = -1, -1
 //writef("genmidi: %s <%n/%n> saved clist*n",
 //        opname, fno, ln)

      TEST pqpos=absq0
      THEN { // This Tuplet construct can resolve ties in plist, so
             // do not change it and do not restore it at the end.
 //writef("genmidi: this Tuplet construct can resolve ties in plist*n")
           }
      ELSE { // This Tuplet construct cannot resolve ties in plist,
             // so set plist to the current tlist.
 //writef("genmidi: this Par construct cannot resolve plist ties*n")
 //writef("genmidi: so save plist and set it to tlist*n")
             oplist, opqpos := plist, pqpos
              plist,  pqpos := tlist, tqpos
           }

      // Set up the new clist.
      clist := 0
      cqpos := absq1    // Scale qbeat of end of the tuplet

      // Translate the left operand
      tlist, tqpos := 0, -1   // Reset the current ties list
      qbeats := q0
      chanvol := -1

//writef("*ngenmidi: Tuplet Generating left operand qbeats=%n*n", qbeats)
//prties()
      genmidi(a1, envblk)

      tokln := h3!a1

      // Check that there are no unresolvable ties in tlist
      IF tlist & tqpos~=absq1 DO
      { checktlist(envblk)
      }

      clist, cqpos := tlist, tqpos

      // Translate the right hand operand of the tuplet.

      { LET obase, ofaca, ofacb = scbase, scfaca, scfacb

        // Set up new scaling parameters

        scbase := absq0          // Scaled qbeat start of tuplet start
        scfaca := absq1 - absq0  // Scaled qbeat length of tuplet
        scfacb := rhsqlen        // Unscaled qbeat length of RHS

        tlist, tqpos := 0, -1
        qbeats := 0
        chanvol := -1

//writef("*ngenmidi: Tuplet generating right operand qbeats=%n*n", qbeats)
//prties()
        genmidi(rhs, envblk)
//writef("*ngenmidi: Tuplet done right operand qbeats=%n*n", qbeats)
//prties()

        scbase, scfaca, scfacb := obase, ofaca, ofacb

      // Check that there are no unresolvable ties in tlist.
        IF tlist & tqpos~=absq1 DO
          checktlist(envblk)

        // Insert tlist onto the front of clist
        IF tlist DO
        { LET p = tlist
          WHILE !p DO p := !p
          !p := clist
          clist, cqpos := tlist, tqpos
          tlist, tqpos := 0, -1
        }
      }

      // Both members of the Tuplet have been processed, so
      // set tlist = clist, restore old clist, and conditionally
      // retore plist.

      IF oplist>=0 DO
      { // This Tuplet construct started later that the enclosing one, if any
        // so all ties in plist must have now been resolved. 
        // Check there are no unresolved ties in plist.
        IF plist DO
        { tlist, tqpos := plist, pqpos
          checktlist(envblk)
        }
        // Restore previous plist
        plist, pqpos := oplist, opqpos
      }

      // Set tlist and restore previous clist
      tlist, tqpos :=  clist,  cqpos
      clist, cqpos := oclist, ocqpos

      qbeats := q0 + lhsqlen

//writef("Leaving Tuplet construct with qbeats=%n*n", qbeats)
//prties()
      RETURN
    }
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

AND qbeats2msecs(absq, currblk) = VALOF
{ // absq is the absolute qbeat position to look up.
  // It returns the midi msecs corresponding to absq.
IF absq<0 DO
{ writef("qbeats2msecs: absq=%n*n", absq)
  abort(1111)
}
  WHILE currblk DO
  { // env -> [link, Block, ln, body, envblk, shapeitems, qstart, qend]

    LET list   = h6!currblk   // The shape items list
    LET qstart = h7!currblk
    LET qend   = h8!currblk

//writef("*nqbeats2msecs: entered with absq=%n*n", absq)
//writef("qbeats2msecs: currblk=%n qstart=%n qend=%n*n", currblk, qstart, qend)

    WHILE list DO
    { // list -> [link, kind, shapedata]
      IF h2!list=s_msecsmap & qstart<=absq<=qend DO
      { LET v   = h3!list // -> [ms0, ms1,..., msn]

        LET q0 = qstart     & #x7FFFFF00
        LET q1 = (qend+256) & #x7FFFFF00
        LET n  = (q1-q0) / 256

        // v!0 holds the midi msecs value corresponding to
        //     absolute qbeat position q0 and
        // v!n corresponds to the msecs value at position q1.

        LET i    = (absq-q0)  /  256
        LET r    = (absq-q0) MOD 256
        LET a, b = v!i, v!(i+1)
        LET res  = a + muldiv(b-a, r, 256) 
        //writef("qbeats2msecs: qstart=%n absq=%n qend=%n q0=%n q1=%n*n",
        //        qstart, absq, qend, q0, q1)
        //writef("qbeats2msecs: i=%n r=%n a=%n b=%n => %n*n",
        //        i, r, a, b, res)
        RESULTIS res
      }
      list := !list
    }

    IF currblk=conductorblk DO
    { LET ms = qbeats2msecs(qend, currblk)
      // Assume 1 qbeat = 1 msecs for qbeats after the end of conductor part.
      RESULTIS ms + absq - qend
    }
//writef("qbeats2msecs: trying next level out*n")
    // Try the next level out
    currblk := h5!currblk
  }


  // No msecs map found so assume 1 qbeat = 1 msecs
//writef("qbeats2msecs: returning default value %n*n", absq)
  RESULTIS absq
}

AND barno2msecs(bn, envblk) = VALOF
{   
  LET q  = barno2qbeats(bn)
  LET ms = qbeats2msecs(q, envblk)
//writef("*nbarno2msecs: bn=%n maxbarno=%n q=%n*n", bn, maxbarno, q)
//writef("barno2msecs: returns msecs=%n*n", ms)
//abort(1003)
  RESULTIS ms
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
  // pushbyte is only used to add bytes to the midi data held in cb.

  LET upb  = cb!0                  // Current upb (in words) of v
  LET bupb = upb*bytesperword      // The upb in bytes
  LET v    = cb!1                  // is zero or a getvec'd vector holding 
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
    { trerr(-1, "More memory needed")
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
  LET prevr = 0
  LET stop_msecs = end_msecs + 1_000 // Stop 1 second after end_msecs
  LET stdout = output()
  LET midiout =  0
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
  pushstr(cb, playmus_version)
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
    LET dr = 0

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
      LET r = m2r_msecs(midimsecs, ocr, ocm, crate) // real msecs of item
      dr := r - prevr
      prevr := r
    }

//writef("%i7: midi op: %x2 %x2 %x2*n", t, op, a1, a2)

    SWITCHON fn INTO
    { DEFAULT:  writef("Unexpected midi op: %x2 %x2 %x2*n", op, a1, a2)
                ENDCASE

      CASE midi_note_on: UNLESS midimsecs>=start_msecs LOOP
      CASE midi_note_off:
      CASE midi_keypressure:
      CASE midi_control:
      CASE midi_chanpressure:
      CASE midi_pitchbend:
        pushnum (cb, dr)
        pushbyte(cb, op)
        pushbyte(cb, a1)
        pushbyte(cb, a2)
        LOOP

      CASE midi_progchange:
        pushnum(cb, dr)
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

  //writef("midi byte upb=%n*n", v!0)
  selectoutput(midiout)

  FOR i = bytesperword TO v!0 DO binwrch(v%i)

  endstream(midiout)
  selectoutput(stdout)
  freevec(v)        // Free the vector holding the Midi data
}

.

SECTION "shapefns"

GET "libhdr"
GET "playmus.h"

LET getshapeval(q, envblk, kind, kindadj) = VALOF
{ // Return the shape value corresponding to qbeat position qb 
  // deduced from the shape data in the given environment chain.
  // The result includes the corresponding shape adjustment.
  // The qbeat values in the shape data lists are already scaled.
  LET val = lookupshapeval(q, kind,    envblk)
  LET adj = lookupshapeval(q, kindadj, envblk)
  LET res = muldiv(val, adj, 100_000)
  //writef("getshapeval: kind=%s q=%i4 val=%8.3d adj=%8.3d => res=%8.3d*n",
  //        opstr(kind), q, val, adj, res)
  RESULTIS res
}

AND lookupshapeval(q, kind, envblk) = VALOF
{ // q  is an absolute qbeat position
  // kind is a shape kind eg s_tempo,, s_tempoadj, etc
  // env -> [-, s_block, ln, body, envblk, shapelist, qstart, qend]
//writef("lookupshapeval: q=%n kind=%s envblk=%n*n", q, opstr(kind), envblk)
  WHILE envblk DO
  { // envblk -> [link, Block, ln, body, prevenv, shapelist, qstart, qend]
    LET t = h6!envblk // The shape item list
    WHILE t DO
    { // t -> [link, kind, shapedata]
      // Get the scaled qbeat positions of the start and end of the block
      LET qstart, qend = h7!envblk, h8!envblk
//writef("lookupshapeval: q=%n t=%n kind=%s*n", q, t, opstr(h2!t))

      IF t!1=kind DO
      { LET shapedata = t!2
        LET res = shapeval(q, kind, shapedata, envblk)
        result2 := !envblk
        RESULTIS res
      }
      t := !t
    }
    // Try the next environment block one level out
    envblk := h5!envblk
  }

  // Shape value was not found so return the default value
  SWITCHON kind INTO
  { DEFAULT:       // All adjustment shapes
                    RESULTIS 100_000

    CASE s_tempo:   RESULTIS 120_000
    CASE s_vol:     RESULTIS  70_000
    CASE s_legato:  RESULTIS  90_000
    CASE s_delay:   RESULTIS   0_000 // No delay
    CASE s_vibrate: RESULTIS   4_000 // 4 cycles per second
    CASE s_vibamp:  RESULTIS  25_000 // About a quarter of a semitone
  }
}

AND shapeval1(q, kind, shapedata, envblk) = VALOF
{ LET res = shapeval1(q, kind, shapedata, envblk)
  writef("Shapeval: q=%n %s => %9.3d*n", q, opstr(kind), res)
  RESULTIS res
}

AND shapeval(q, kind, shapedata, envblk) = VALOF
{ // q    is an scaled qbeat position
  // kind is a shape kind
  // shapedata -> [2n, q1, x1, q2, x2,..., qn, xn]
  // envblk -> the current environment block
  //           [link, Block, ln, body, parent, shapeitems, qstart, qend]
  // if n = 1 the result is x1
  // if q<=q1 the result is x1
  // if q>=qn the result is xn
  // otherwise use linear interpolation between the closest values.
  LET n2 = shapedata!0
  LET q1 = shapedata!1
  LET qn = shapedata!(n2-1)
//writef("shapeval: n2=%n q1=%n qn=%n*n", n2, q1, qn)

  IF n2=2 DO trerr(q, "shapeval: n=1")
  IF q<=q1 | n2=2 RESULTIS shapedata!2
  IF q>=qn RESULTIS shapedata!n2

  // At this point we know q1 <= q <= qn
  { LET a,  b  = 1, 3
    LET qa, qb = ?, ?
    LET xa, xb = ?, ?
    // Binary chop might be faster
    WHILE q > shapedata!b DO { a := b; b := b+2 }
    qa, qb := shapedata! a,    shapedata! b
    xa, xb := shapedata!(a+1), shapedata!(b+1)
//writef("*nshapeval: a=%n b=%n qa=%n xa=%8.3d qb=%n xb=%8.3d => %8.3d*n",
//        a, b, qa, xa, qb, xb, xa + muldiv(xb-xa, q-qa, qb-qa))
    RESULTIS xa + muldiv(xb-xa, q-qa, qb-qa)
  }
}
.

SECTION "playmidi"

/*
Playmidi reads microphone input and commands from the keyboard while
it plays the midi events.

If option ACC is given, input from the microphone will be compared
with solo part(s) in an attempt to synchronise midi output with the
soloist.

The keyboard commands are read using pollsardch and will be as follows:

B       The nearest bar line is now
space   The nearest beat is now
+       Play faster
-       Play slower
S       Stop/Start
G       Go to start of bar n. All commands reset n to zero
P       Go to start of the previous bar
N       Go to the start of the next bar
0..9    n := 10n + digit
*/

GET "libhdr"
GET "playmus.h"
GET "sound.h"
GET "mc.h"

LET genrecogfn(note) = VALOF
{ // This function is under development

  // Generate an MC function to return the amplitude of a given note.
  // The result is the function number or zero on error.
  // The resulting MC function takes one argument which is a BCPL pointer
  // to the latest the latest cumulative sample. Sufficient samples are
  // assumed to be available.
  // The result is the average amplitude of the given note.
  LET a, m, b = 0, 0, 0
  LET freq = freqtab!note
  LET samples_per_cycle = muldiv(44100, 1000, freq) // Scaled ddd.ddd
  LET qcycle = samples_per_cycle/4 // 90 degree offset
  LET v1 = soundv + soundvupb
  LET v2 = v1 - qcycle             // For sample 90 degrees out of phase
  LET p1, p2, total_by_2, amplitude = 0, 0, 0, 0
  LET cycles = (freq * 32) / 440_000  // 32 cycles for note 4A
  IF cycles<4  DO cycles := 4         // Ensure 4<=cycle<=32
  IF cycles>32 DO cycles := 32

  // Ensure that cycles is not too large for the sound buffer.
  WHILE cycles*samples_per_cycle/1000 <= soundvupb-qcycle DO
    cycles := cycles-1

  // Need to generate native code for the following:

  total_by_2 := (!v1 - !(v1-cycles*samples_per_cycle/1000)) / 2

  p1, p2 := total_by_2, total_by_2

  FOR i = 1 TO cycles DO
  { b := i * samples_per_cycle / 1000
    b := (b+1) & -2 // Round to nearest even number
    m := (a+b) / 2  // Midpoint of this cycle
    p1 := p1 - !(v1-a) + !(v1-m)
    p2 := p2 - !(v2-a) + !(v2-m)
    a := b          // Position of first sample of next cycle
  }
  // Calculate the average amplitude
  amplitude := (ABS p1 + ABS p2) / cycles
  RESULTIS amplitude
}


AND getrealmsecs() = VALOF
{ // Return a msecs value that increases even over midnight.
  MANIFEST { msecsperday = 24*60*60*1000 } // msecs in 24 hours
  LET day, msecs, filler = 0, 0, 0
  sys(Sys_datstamp, @day)

  // Initialise baseday on first call of getrealmsecs
  IF msecsbase < 0 DO msecsbase := msecs

  // Return msecs since msecsbase.
  msecs := msecs - msecsbase
  IF msecs<0 DO msecs := msecs+msecsperday
  RESULTIS msecs
}

LET notecofn(argv) = VALOF
{ // soundmsecs is the real time of the latest sample insoundv
  LET note = argv!0
  LET notetimes = argv!1    // This must be freed before the coroutine dies.
  LET noteupb = notetimes!0
  LET notep = 0             // Will hold the position in notetimes of the
                            // nearest matching note
  LET dmsecs = 0            // Difference between midi time of matching
                            // note and real_msecs  
  LET rmsecs = 0            // Real time now
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
  // If a note is detected, assume it started at soundmsecs-offset
  note2str(note, notename)

  writef("*nnote=%s samples_per_cycle = %9.3d freq=%9.3d k=%n*n",
           notename, samples_per_cycle, freq, k)
  FOR i = 1 TO notetimes!0 DO
  { IF (i-1) MOD 8 = 0 DO newline()
    writef(" %9.3d", notetimes!i)
  }
  newline()

  rmsecs := cowait(0) // real time of latest sample, or -1 to finish

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
    //IF amp>3500 UNLESS noteon DO
    IF amp>2500 UNLESS noteon DO
    { // A note start has just been detected
      LET startrmsecs = soundmsecs-offset // Real time of note start
      LET mmsecs = r2m_msecs(startrmsecs, oer, oem, erate)
      //writef("%9.3d: %9.3d %9.3d %s*n", rmsecs,startrmsecs,mmsecs,notename)
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
      // If the note is within 500 msecs of now add it to the set of events.
      // Its weight is its amplitude (0..127).
      IF -0_500 <= dmsecs <= 0_500 DO
      { addevent(mmsecs, startrmsecs, amp, note)
        totalerr, notecount := totalerr+dmsecs, notecount+1
        writef("%9.3d: mmsecs=%9.3d err %9.3d avg=%9.3d amp=%i5 %s*n",
                rmsecs, mmsecs, dmsecs, totalerr/notecount, amp, notename)
      }
    }

    IF amp<1000 IF noteon DO
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
{ // Find the start times of this note played by any of the soloists.
  LET upb, v = 0, 0 // A self expanding vector
  LET p = midilist  // List of midi triples
  LET stop_msecs = end_msecs + 1_000 // Stop 1 second after end_msecs
  LET notename = VEC 1
  note2str(note, notename)

  UNLESS solochannels RESULTIS 0

  WHILE p DO
  { LET op, a1, a2 = ?, ?, ?
    LET msecs = p!1 // Time of next midi event
    LET triple = p!2
    LET midiop = triple & #xF0
    LET chan   = triple & #x0F
    LET a1 = (triple>> 8) & 255
    LET a2 = (triple>>16) & 255

    p := !p

    UNLESS a1 = note LOOP

    UNLESS midiop=midi_note_on LOOP
    IF ((1<<chan) & solochannels)=0 LOOP

    IF msecs>stop_msecs BREAK
    IF msecs<start_msecs LOOP

    pushval(@upb, msecs)
    //writef("%9.3d %s*n", msecs, notename)
  }
  RESULTIS v
}

AND addevent(rt, mt, weight, note) BE
{ // note = -1 for bar line events
  // note = -2 for beat events
  // note>=0 for note events

  LET p = eventv+eventp

//  writef("addevent: %5.3d %5.3d weight=%i5  note=%n*n",
//          rt, mt, weight, note)

  IF rt<prevrt+10 RETURN
  prevrt := rt
  p!0, p!1, p!2, p!3 :=  rt, mt, weight, note
  eventp := eventp + 4
  IF eventp >= eventvupb DO eventp := 0
  IF graphdata DO
  { LET ch = note=-1 -> 'B',
             note=-2 -> 'S',
             'M'
    writef("#%c %n %n %n*n", ch, rt, mt, weight)
  }
}

AND clearevents() BE   FOR i = 0 TO eventvupb BY 4 DO eventv!i := 0

AND calcrates() BE IF real_msecs >= calc_msecs DO
{ LET cgr, cgm, w = 0, 0, 0 // CG of recent events.
  LET count = 0             // Count of recent events.
  LET corr  = 0             // midi msecs distance from current play line.
  LET em    = 0             // Estimated midi msecs at now.
  //LET em1   = 0             // Estimated midi msecs 1 sec from now.
  LET cm    = 0             // Midi msecs now.
  LET ratediff = 0

  // Calculate new rates about 20 times per second
  calc_msecs := real_msecs + 50

  // Calculate weighted average of (rt, mt) pairs in eventv
  FOR i = 0 TO eventvupb BY 4 DO
  { LET e = @eventv!i // => [ rt, mt, weight, op]
    LET dt     = e!0 - real_msecs // Relative to now (to avoid overflow)
    LET mt     = e!1
    LET weight = e!2

    // Only consider events that occurred within the last 2 seconds
    IF eventv!0=0 | dt < -2_000 LOOP
    //writef("calcrates: rt=%5.3d mt=%5.3d weight=%n*n", rt, mt, weight)
    cgr := cgr + dt*weight
    cgm := cgm + mt*weight
    w := w + weight
    count := count+1
    //writef("calcrates: cgr=%5.3d cgm=%5.3d weight=%n*n", cgr, cgm, w)
  }

  //writef("calrates: count=%n*n", count)
  UNLESS w RETURN // No events so do not change the rates

  // Calculate the centre of gravity
  cgr, cgm := real_msecs+cgr/w, cgm/w

  // Calculate the estimated midi msecs error of CG relative to
  // the current estimated play line.
  corr := cgm - r2m_msecs(cgr, oer, oem, erate)
  // corr >0 if the soloist is ahead of estimated play line

  IF graphdata DO
    writef("#G %n %n*n", cgr, cgm)

//  writef("calrates: cgr=%5.3d cgm=%5.3d corr=%5.3d*n", cgr, cgm, corr)
//  writef("calrates: old oer=%5.3d oem=%5.3d erate=%5.3d*n",
//         oer, oem, erate)
//  writef("calrates: corr=%5.3d*n", corr)

  IF corr> 40 DO corr :=  40
  IF corr<-40 DO corr := -40
  erate := erate + corr

  // Limit the play rate but keep within 0.5 and 2.0
  IF erate>2_000 DO erate := 2_000
  IF erate<0_500 DO erate := 0_500

  // Make the new estimated play line pass through the CG
  oer, oem := cgr, cgm

//  writef("calrates: new oer=%5.3d oem=%5.3d erate=%5.3d*n",
//         oer, oem, erate)

  // oer, oem, erate now represent the new estimated play line,
  // passing through CG.

  // Choose a more recent origin for the new estimated play line
  oem := r2m_msecs(real_msecs, oer, oem, erate)
  oer := real_msecs

  // Choose the origin of the new correction play line
  ocm := r2m_msecs(real_msecs, ocr, ocm, crate)
  ocr := real_msecs

  // Choose the new rate for the correction play line
  crate := erate
  IF oem > ocm + 0_050 DO crate := erate + 0_200
  IF oem < ocm - 0_050 DO crate := erate - 0_200

  IF graphdata DO
  { writef("#E %n %n %n*n", oer, oem, erate)
    writef("#C %n %n %n*n", ocr, ocm, crate)
  }
//  writef("real_msecs=%9.3d oem=%5.3d erate=%5.3d ocm=%5.3d crate=%5.3d*n",
//          real_msecs, oem, erate, ocm, crate)
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

  // Shift the data in soundv
  FOR i = 0 TO soundvupb - 1024 DO soundv!i := soundv1024!i

  // Accummulate the new samples into the end of soundv
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

  // The playmidi coroutine returns TRUE when the end of performance
  // is reached.
  LET str = VEC 5
  LET midip = midilist

//  writef("playmidico: called arg=%n*n", arg)

  { // Main loop

    WHILE midip & ~quitting DO
    { // Output all midi triples that are now due
      LET mt = midip!1 // Midi time of next midi triple
      LET rt = m2r_msecs(mt, ocr, ocm, crate)

      //IF mt > stop_msecs BREAK

//writef("%9.3d playmidico: mt=%9.3d  rt=%9.3d*n", real_msecs, mt, rt)
      IF rt <= real_msecs DO
      { // This midi triple is now due so output it.
        LET triple = midip!2
        LET op     = triple & 255
        LET chan   = op & #x0F
        LET a1     = (triple>> 8) & 255
        LET a2     = (triple>>16) & 255
        LET is_note_on = (op&#xF0)=midi_note_on
        midip := !midip
//writef("%9.3d playmidico: triple %2x %2x %2x*n", real_msecs, op, a1, a2)

        // Unless calibrating, do not play the solo channels
        UNLESS calibrating IF ((1<<chan) & solochannels)~=0 LOOP
//writef("%9.3d playmidico: triple %2x %2x %2x*n", real_msecs, op, a1, a2)
//writef("%9.3d playmidico: mt=%9.3d [%5.3d %5.3d]*n",
//        real_msecs, mt, start_msecs, end_msecs)

        // Output the midi triple, but only note_on commands if mt is
        // between start_msecs and end_msecs.
        TEST is_note_on
        THEN IF start_msecs < mt <= end_msecs DO
             { wrmid3(mt, op, a1, a2)
               IF graphdata DO
                 writef("#N %n %n %s*n", real_msecs, mt, note2str(a1, str)) 
             }
        ELSE wrmid3(mt, op, a1, a2)

        LOOP
      }

//writef("%9.3d playmidico: end of performance*n", real_msecs)
      cowait(FALSE)      // Wait to be given control
    }

    // End of performance #################
    cowait(TRUE) REPEAT
  }
}

AND keycofn(arg) BE
{ // Coroutine to read the keyboard
  LET ch = sys(Sys_pollsardch)

  SWITCHON ch INTO
  { DEFAULT:
      writef("key %i3 '%c'*n", ch, ch)

    CASE '?':
    CASE 'h': CASE 'H':  // Help
      newline()
      writef("? H       Output help info*n")
      writef("Q         Quit*n")
      writef("B         A bar line is now*n")
      writef("<space>   A beat is now*n")
      writef("+         Play faster*n")
      writef("-         Play slower*n")
      writef("P         Pause/Play*n")
      writef("n G       Goto start of bar n*n")
      newline()
      LOOP

    CASE 'q':CASE 'Q':  // Quit
      writef("*nQuitting*n")
      quitting := TRUE
      LOOP

    CASE 'b':CASE 'B':
    { LET mt   = r2m_msecs(real_msecs-0_000, oer, oem, erate)
      LET bno  = msecs2barno(mt)
      LET bms  = 0
      LET err  = ?
      LET bms1 = barmsecs!(bno)
      LET bms2 = barmsecs!(bno+1)
      TEST mt < (bms1+bms2)/2
      THEN bms := bms1
      ELSE bno, bms := bno+1, bms2
      writef("%9.3d: bar  %i3      crate=%9.3d err = %6.3d*n",
                mt, bno, crate, mt-bms)
      addevent(real_msecs, bms, 127, -1) // -1 means Bar
      LOOP
    }

    CASE '*s': // Nearest beat
    { LET mt     = r2m_msecs(real_msecs-0_000, oer, oem, erate)
      LET beatno = msecs2beatno(mt) // beat number of most recent beat

      LET bms = -1   // Will be the midi time of the nearest beat
      LET weight = 0 // Will be the weight of this event
                     // =127 if exactly on a beat, =0 half way between beats
      LET b, bno, err = 1, ?, ?
      LET bms1  = beatmsecs!beatno     // Time of previous beat
      LET bms2  = beatmsecs!(beatno+1) // Time of next beat
      LET mid   = (bms1+bms2)/2
      LET range = (bms2-bms1)/2

      writef("*n %9.3d %8.3d beatno %i3 bms1=%6.3d bms2=%6.3d*n",
              real_msecs, mt, beatno, bms1, bms2)

      TEST mt < mid
      THEN { bms := bms1
             weight := (127 * (mid-mt))/range
           }
      ELSE { bms := bms2
             weight := (127 * (mt-mid))/range
             beatno := beatno+1
           }
      bno := msecs2barno(beatmsecs!beatno)
      FOR i = 0 TO 32 IF beatmsecs!(beatno-i)<=barmsecs!bno DO
      { b := i+1
        BREAK
      }
      writef(" %9.3d %8.3d beat %i3/%i3  erate=%9.3d w=%i3 err = %6.3d*n",
              real_msecs, mt, bno, b, erate, weight, mt-bms)
      addevent(real_msecs,    // Real time now
               bms,           // Midi time of nearest beat
               weight,           //
               -2) // -2 means Beat
      LOOP
    }

    CASE '+':
    CASE '=':
      clearevents()
      IF erate+50 <= 2_000 DO
      { // Calculate a new origin for the new estimated play line
        // and increase its rate a little
        oem := r2m_msecs(real_msecs, oer, oem, erate)
        oer := real_msecs
        erate := erate + 50

        // Choose a new origin for the new correction play line
        ocm := r2m_msecs(real_msecs, ocr, ocm, crate)
        ocr := real_msecs

        // Choose the new rate for the correction play line
        crate := erate
        IF oem > ocm + 0_050 DO crate := erate + 0_200
        IF oem < ocm - 0_050 DO crate := erate - 0_200

        IF graphdata DO
        { writef("#+ %n %n %n*n", oer, oem, erate)
          writef("#C %n %n %n*n", ocr, ocm, crate)
        }
      }
      sawritef(" erate = %9.3d*n", erate)
      LOOP

    CASE '-':
    CASE '_':
      clearevents()
      IF erate-50 >= 0_500 DO
      { // Calculate a new origin for the new estimated play line
        // and increase its rate a little
        oem := r2m_msecs(real_msecs, oer, oem, erate)
        oer := real_msecs
        erate := erate - 50

        // Choose a new origin for the new correction play line
        ocm := r2m_msecs(real_msecs, ocr, ocm, crate)
        ocr := real_msecs

        // Choose the new rate for the correction play line
        crate := erate
        IF oem > ocm + 0_050 DO crate := erate + 0_200
        IF oem < ocm - 0_050 DO crate := erate - 0_200

        IF graphdata DO
        { writef("#+ %n %n %n*n", oer, oem, erate)
          writef("#C %n %n %n*n", ocr, ocm, crate)
        }
      }
      sawritef(" erate = %9.3d*n", erate)
      LOOP

    CASE -3: // No keyboard character available
      ENDCASE
  }
  cowait(0)
} REPEAT



AND playmidi(midilist) BE
{ LET midiname = "/dev/midi"
  LET micname = "/dev/dsp1"
  LET micformat = 16  // S16_LE
  LET micchannels = 1 // Mono
  LET micrate = 44100 // Mic samples per second
  LET stop_msecs = end_msecs + 1_000 // Stop 1 midi second after end_msecs
  LET stdout = output()
  LET midi_msecs = 0
  LET nval = 0
  LET mb = VEC micbufupb

  totalerr, notecount := 0, 0

  // Set initial origins and rates
  ocr, ocm, crate := getrealmsecs(), 0, erate
  oer, oem := ocr, ocm

  soundco    := createco(soundcofn,    1000)
  playmidico := createco(playmidicofn, 1000)
  keyco      := createco(keycofn,      1000)

IF FALSE DO
{ writef("Testing r2m_msecs and m2r_msecs*n")
  FOR i = 1 TO 3 DO
  { LET rt = getrealmsecs()
    LET mt = r2m_msecs(rt, ocr, ocm, crate)
    writef("*nr2m_msecs(%9.3d, %9.3d, %9.3d, %9.3d) => %9.3d*n",
            rt, ocr, ocm, crate, mt)
    rt := m2r_msecs(mt, ocr, ocm, crate)
    writef("m2r_msecs(%9.3d, %9.3d, %9.3d, %9.3d) => %9.3d*n",
            mt, ocr, ocm, crate, rt)
    msdelay(500)
    crate := muldiv(crate, 1_100, 1_000)
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
    // Only create note coroutines for notes played by the solists
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
  { wrmid3(midi_msecs, midi_control+chan, #x7B, 0)// Allnotes off
    wrmid3(midi_msecs, midi_control+chan, #x79, 0)// All controllers off
  }

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

  // Set initial origins and rates again.
  ocr, ocm, crate := getrealmsecs(), start_msecs, erate
  oer, oem := ocr, ocm

  { // Start of main timer loop

    IF quitting BREAK

    // Try to read some sound data into soundv
    callco(soundco, 1234)
    // If new sound data has been read mic_msecs will have been
    // set to the approximately real time of the latest sample.
    // mic_msecs is used by the note recognition coroutines.

    real_msecs := getrealmsecs()
    midi_msecs := r2m_msecs(real_msecs, ocr, ocm, crate)

    // Test for end of performance
    IF midi_msecs>=stop_msecs BREAK

    // Output any outstanding midi triples if any are due
    IF callco(playmidico, 2345) DO
    { // playmidico has reached the end of the performance
      BREAK
    }

    // Process any keyboard input
    callco(keyco, 3456)

    // Process up to 5 note recognisers
    FOR i = 1 TO notecoupb DO
    { callco(notecov!notecop, real_msecs)
      notecop := notecop + 1
      IF notecop>notecoupb DO notecop := 1
      IF i>=5 BREAK
    }

    // Calculate new parameters for the estimated and current play lines
    // based on their previous values and recent events in the
    // eventv circular buffer.
    calcrates(real_msecs)

    msdelay(5) // Delay 5 msecs (=1/200 sec)
  } REPEAT

  // Delay to let all sounds die down
  msdelay(1000)

  // All notes off all channels
  FOR chan = 0 TO 15 DO
    wrmid3(midi_msecs, midi_control+chan, 123, 0) // All notes off
  msdelay(500)

  IF notecount DO
    writef("*nAverage Midi-mic error %5.3d = %5.3d/%n*n",
            totalerr/notecount, totalerr, notecount)

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

AND r2m_msecs(real_msecs, or, om, rate) = VALOF
{ // Convert real time msecs to midi msecs
  // rate is the number of midi msecs per real second
  // offset is the real time in msecs at midi time zero
  LET mt = om + muldiv(real_msecs-or, rate, 1000)
  RESULTIS mt
}

AND m2r_msecs(midi_msecs, or, om, rate) = VALOF
{ // Convert midi msecs to real time
  // rate is the number of midi msecs per real second
  // offset is the real time in msecs at midi time zero
  LET rt = or + muldiv(midi_msecs-om, 1000, rate)
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
    IF op = #x80 DO
      writef("  chan %i2 Off %t4", chan, note2str(b, strv))
    IF op = #x90 DO
      writef("  chan %i2 On  %t4 vol %n", chan, note2str(b, strv), c)
    IF op = #xC0 DO
      writef("  chan %i2 Program change %n", chan, b)
    IF op = midi_control DO
    { writef("  chan %i2 Control %i3 %i3", chan, b, c)
      IF b=  0 DO writef(" Set Bank MSB=%n", c)
      IF b=  7 DO writef(" Set Volume MSB=%n", c)
      IF b= 32 DO writef(" Set Bank LSB=%n", c)
      IF b= 39 DO writef(" Set Volume LSB=%n", c)
      IF b=120 DO writef(" All sound off")
      IF b=121 DO writef(" All controllers off")
      IF b=123 DO writef(" All notes off")
    }
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
    CASE  8: RESULTIS "G#"
    CASE  9: RESULTIS "A "
    CASE 10: RESULTIS "Bb"
    CASE 11: RESULTIS "B "
  }
  str%0 := 3
  str%1 := oct>=0 -> oct + '0', '-'
  str%2 := s%1
  str%3 := s%2
  //writef("*nnote2str: n=%n oct=%n => *"%s*"*n", n, oct, str)
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
  { LET str = VEC 5
    writef("System error: note off event missing chan=%n note=%s*n",
            chan, note2str(n, str))
  }
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

