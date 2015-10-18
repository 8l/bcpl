// COMPARE

// This is a text file comparison program based on one originally
// written by Nick Maclaren

// 24/3/03 Modified to run under Cintpos by Martin Richards

// This program is designed to check two sequential character
// files for altered, inserted or deleted lines.

// Return codes are as follows:
//         0 - the files are identical.
//         5 - the files are not identical.
//        10 - no match could be found.
//        15 - the parameters are invalid or insufficient stack.
//        20 - a file cannot be opened.

// The argument format is: file1/a,file2/a,to/k,opt/k

// file1    The first file to compare
// file2    The file to compare with file1
// to       where to send the output
// opt      Options to control the comparison as follows:

//     1) Spaces are permitted anywhere except within an integer,
// and commas may be used to separate parameters.
//     2) Wn.  Truncate all lines after n (> 0) data characters.
//     3) Mn.  Search for up to n mismatching lines.
//     4) Rn.  Require n (> 0) matching lines to restore synchronisation
//             after a mismatch.
//     Defaults:  W132 R2; M is set to the
// largest value that will fit in the available store.

// The algorithm will allow m1 lines of file1 to
// differ from m2 lines of file2 if there are at least
// min(R,max(m1,m2)+1) identical lines immediately after.
//

SECTION "COMPARE"

GET "libhdr"

MANIFEST { dataposn = 1 }

GLOBAL {
  mismatch:ug; restore; window
  bot1; bot2; top1; top2; base1; base2
  limit1; limit2; line1; line2
  eof1; eof2; stream1; stream2
  words; linesper
  current; equal; file1; file2
  parm; buffer; tostream
}

LET equal(s1, s2, l1, l2) = VALOF
{ LET i,     j = 0, 0
  LET ch1, ch2 = 0, 0        // current characters
  LET pc1, pc2 = '*s', '*s'  // previous characters

//writef("equal: ")
//FOR i = 0 TO l1-1 DO wrch(s1%i)
//writes("  :  ")
//FOR i = 0 TO l2-1 DO wrch(s2%i)
//newline()

  // Remove trailing white space
  WHILE l1>0 DO
  { ch1 := s1%(l1-1)
    UNLESS ch1='*s' | ch1='*t' BREAK
    l1 := l1-1
  }
  WHILE l2>0 DO
  { ch2 := s2%(l2-1)
    UNLESS ch2='*s' | ch2='*t' BREAK
    l2 := l2-1
  }

  { 
    IF i>=l1 & j>=l2 RESULTIS TRUE  // All characters have matched
    IF i>=l1 | j>=l2 RESULTIS FALSE // One line exhausted

    // Both lines have at least one more character to check
    ch1, ch2 := s1%i, s2%j
    i, j := i+1, j+1

    // Coalesce consecutive spaces
    IF pc1='*s' WHILE ch1='*s' | ch1='*t' DO { ch1 := s1%i; i := i+1 }
    IF pc2='*s' WHILE ch2='*s' | ch2='*t' DO { ch2 := s2%j; j := j+1 }
    pc1, pc2 := ch1, ch2
  } REPEATWHILE ch1=ch2

  RESULTIS FALSE
}

LET start() BE {
  LET l, m, n, temp = ?, ?, 0, ?
  LET parmf = VEC 50
  LET argv = VEC 40
  stream1 := 0
  stream2 := 0
  tostream := 0
  buffer := 0

  UNLESS rdargs("file1/a,file2/a,to/k,opt/k", argv, 40) DO
  { writes("Invalid args for COMPARE*n")
    stop(15)
  }
  parm := argv!3 = 0 -> "", argv!3
  file1, file2 := argv!0, argv!1

  IF argv!2 DO
  { tostream := findoutput(argv!2)
    UNLESS tostream DO
    { writef("Can't open %S*n", argv!2)
      stop(20)
    }

    selectoutput(tostream)
  }

  unpackstring(parm,parmf); parmf!(parmf!0+1) := '.'

  // Initialise everything to unset.
  mismatch := -1
  window := -1
  restore := -1

  // The parm field loop.
  WHILE n < parmf!0 DO
  { n := n+1
    SWITCHON capitalch(parmf!n) INTO
    { DEFAULT:    GOTO parmerr

      // Various characters and parameters.
      CASE ' ':
      CASE ',':   LOOP

      // Integer parameters.
      CASE 'M':   temp := @mismatch; GOTO beta
      CASE 'R':   temp := @restore;  GOTO beta
      CASE 'W':   temp := @window
beta:             IF !temp >= 0 GOTO parmerr
                  n := n+1 REPEATWHILE parmf!n = ' '
                  m := 0
                  UNLESS '0' <= parmf!n <= '9' GOTO parmerr

                  { m := 10*m+parmf!n-'0'
                    n := n+1
                  } REPEATWHILE '0' <= parmf!n <= '9'

                  !temp := m;
                  n := n-1
                  LOOP
      }
    }

    // Check values and insert defaults.
    UNLESS restore GOTO parmerr
    IF mismatch < 0 DO mismatch := 25
    IF restore  < 0 DO restore  := 2
    UNLESS window GOTO parmerr
    IF window   < 0 DO window   := 132
    words := window/bytesperword+dataposn

    buffer := getvec((mismatch+restore)*2*(words+1))
    UNLESS buffer DO
    { writes("Insufficient store for COMPARE*n")
      stop(20)
    }

    // Set up constants and start work.
    linesper := 0

    main(buffer)

parmerr:
    writef("Invalid parameters:  %S*n", parm);
    quit(15)
}



AND main(buff) BE
{
  // This controls the comparison.  Its argument is a vector for
  // workspace.  The algorithm is to scan until a mismatch is found.
  // Then to search for identical lines between the files in such a
  // way as to minimise firstly the maximum of the two numbers of
  // differing lines (before the identical ones) and secondly the
  // difference between the numbers.  In case of a tie, file2 will
  // have more lines differing than file1.  End of file is treated as a
  // block of RESTORE identical lines which match no actual lines.
  // The number of identical lines required to restore the matched
  // state is min(RESTORE,max(number of differing lines in file1,
  // number of differing lines in file2)+1).  If no match is found by
  // the time the numbers of differing lines reaches MISMATCH, an
  // error exit is taken.
  //
  LET s1,s2 = " of file1 and line "," of file2"
  LET t1,t2 = ?,?
  LET errflag = FALSE
  t1 := mismatch+restore
  // Allocate space and assign pointers.
  bot1 := buff; top1 := bot1; line1 := 0
  bot2 := bot1+t1; top2 := bot2; line2 := 0
  base1 := bot2+t1; limit1 := base1+t1*words
  base2 := limit1; limit2 := base2+t1*words
  eof1 := FALSE; eof2 := FALSE
  stream1 := 0; stream2 := 0
  current := 0
  pushup(1,mismatch+restore); pushup(2,mismatch+restore)

  // The comparison loop.
alpha:
  //IF testflags(1) DO quit(0)
  t1 := check()
  IF t1 DO { pushup(1,t1); pushup(2,t1); GOTO alpha }
  IF top1 <= bot1 & top2 <= bot2 GOTO beta
  // A mismatch is found.
  errflag := TRUE
  FOR n = 1 TO mismatch DO
  { t1 := n<restore -> n+1, restore
    IF compare(bot1+n,bot2+n,t1) DO
    { printer(n,n)
      pushup(1,n+t1)
      pushup(2,n+t1)
      GOTO alpha
    }

    // Try shifting up and down.
    FOR m = n-1 TO 0 BY -1 DO
    { IF compare(bot1+m,bot2+n,t1) DO
      { printer(m,n)
        pushup(1,m+t1)
        pushup(2,n+t1)
        GOTO alpha
      }
      IF compare(bot1+n,bot2+m,t1) DO
      { printer(n,m)
        pushup(1,n+t1)
        pushup(2,m+t1)
        GOTO alpha
      }
    }
  }

  // No match can be found.
  writef("*nAfter line %N%S%N%S no match could be found.*n",
          line1,s1,line2,s2)
  quit(10)

  // More or less successful end.
beta:
  quit(errflag->5,0)
}

AND pushup(index,num) BE
{
  // This maintains the buffers.  Its arguments are an index to which
  // file and the number of lines to be added.  For each file there is
  // a circular buffer of records, each of which contains the length
  // and the contents of a line.  A vector of pointers indexes the
  // next records.  BOT points to the base of this vector, TOP points
  // to the current end of file in this vector (note that after the
  // first call to PUSHUP it has value BOT+MISMATCH+RESTORE until end
  // of file is reached; the only global indication of no more lines
  // is TOP <= BOT), BASE points to the base of the record buffer and
  // LIMIT points to just after the end of the record buffer.
  //
  LET t1,t2,t3,bot,top,base,limit,eof = ?,num,?,?,?,?,?,?
  // Select the file to manipulate.
  TEST index = 1
  THEN { bot := bot1
         top := top1
         base := base1
         limit := limit1
         eof := eof1
       }
  ELSE { bot := bot2
         top := top2
         base := base2
         limit := limit2
         eof := eof2
       }

  // Push up the circular buffer.
  t1 := bot+num
  TEST t1 < top
  THEN { FOR n = 0 TO top-t1-1 DO bot!n := t1!n; top := top-num }
  ELSE { t2 := top-bot; top := bot }
  t3 := top>bot -> !(top-1), limit

  // Read in more records at end.
  FOR n = 1 TO num DO
  { IF eof THEN BREAK
    t3 := (t3+words<limit->t3+words,base); !top := t3
    t1 := read(index,t3+dataposn)

    // Deal with length etc.
    TEST t1 >= 0 THEN { t3!0 := t1; top := top+1 }
                 ELSE eof := TRUE }

    // Reset file variables.
    TEST index = 1
    THEN { top1 := top; eof1 := eof; line1 := line1+t2 }
    ELSE { top2 := top; eof2 := eof; line2 := line2+t2 }
}

AND compare(chk1,chk2,num) = VALOF
{
  // This compares blocks of lines.  Its arguments are pointers to the
  // buffer index vector.  End of file matches end of file only.

  LET t1, t2, t3 = top1-chk1, top2-chk2, num
  IF t1 < num | t2 < num DO
  { t3 := t1
    UNLESS t1 = t2 RESULTIS FALSE
  }
  FOR n = 0 TO t3-1 DO
  { t1 := chk1!n
    t2 := chk2!n
    UNLESS equal(t1+dataposn,t2+dataposn,t1!0,t2!0) RESULTIS FALSE
  }
  RESULTIS TRUE
}

AND check1() = VALOF
{ LET n = check1()
  writef("check: => %n*n", n)
  IF n=0 DO abort(1000)
  RESULTIS n
}

AND check() = VALOF
{
  // This checks the circular buffers to find the number of identical
  // lines.  End of file always gives inequality.
  LET t1, t2, t3 = top1-bot1, top2-bot2, ?
  t3 := t1<t2 -> t1, t2
  FOR n = 0 TO t3-1 DO
  { t1 := bot1!n
    t2 := bot2!n
    UNLESS equal(t1+dataposn,t2+dataposn,t1!0,t2!0) RESULTIS n
  }
  RESULTIS t3
}

AND read(index,addr) = VALOF
{
  // This reads a record from one or other file.  Its arguments are
  // an index to which file and the address to which to transfer data.
  // It truncates it to the window size.  It returns the length or
  // -1 if end of file.  It gives a diagnostic if the files do not
  // exist.
  LET t1 = index=1 -> @stream1, @stream2
  // Set up the correct stream, opening if necessary.
  UNLESS current = index DO
  { UNLESS !t1 DO
    { !t1 := findinput(index=1->file1,file2)
      UNLESS !t1 DO
      { writef("*nFile %S cannot be opened*n*n", index=1->file1,file2)
        quit(20)
      }
    }
    selectinput(!t1)
    current := index
  }
  // Read a line and sort out the length.
  t1 := readrec(addr)
  IF t1 > window+1 DO t1 := window+1
  RESULTIS t1
}



AND printer(n1,n2) BE
{ // This outputs the differences. Its arguments are the number
  // of differing lines in each file.

  IF n1 > 0 & n2 > 0 DO
  { // Replacement of lines.
    writef("%n", line1+1)
    UNLESS n1=1 DO writef(",%n", line1+n1)
    writef("c%n", line2+1)
    UNLESS n2=1 DO writef(",%n", line2+n2)
    newline()
    prnt1('<', bot1,n1)
    writes("---*n")
    prnt1('>', bot2,n2)
    RETURN
  }

  // Insertions or deletions.
  TEST n1
  THEN { writef("%n", line1+1)
         IF n1>1 DO writef(",%n", line1+n1)
         writef("d%n", line2)
         newline()
         prnt1('<', bot1, n1)
       }
  ELSE { writef("%n", line1)
         writef("a%n", line2+1)
         IF n2>1 DO writef(",%n", line2+n2)
         newline()
         prnt1('>', bot2, n2)
       }
}

AND prnt1(ch, bot, n) BE
{ // Output a line starting with '<' or '>'
  // ch  is '<' or '>'
  // bot is a pointer to the buffer index vector and
  // n   is the number of lines to be output.

  FOR m = 0 TO n-1 DO
  { LET t = bot!m
    writef("%c ", ch)
    writerec(t+dataposn, t!0)
  }
}

AND quit(code) BE
{
  // This is the exit routine.  Its argument is the return code.
  // It returns all the free store got for the program.

  freevec(buffer)
  IF stream1  DO { selectinput(stream1); endread() }
  IF stream2  DO { selectinput(stream2); endread() }
  IF tostream DO { selectoutput(tostream); endwrite() }
  stop(code)
}

AND writerec(buff, len) BE
{ // Writes len characters from buff
  FOR j = 0 TO len - 1 DO wrch(buff%j)
  newline()
}

AND readrec(buff) = VALOF
{ // Reads one record into buff.
  // Result is number of characters read, or -1 if file
  // is exhausted.
  LET n = 0
  LET ch = rdch()
  WHILE ch='*c' DO ch := rdch() // Ignore CR characters

  IF ch=endstreamch RESULTIS -1  // EOF found as fisrt character

  UNTIL ch = '*n' | ch = endstreamch DO
  { buff%n := ch
    n := n+1
    ch := rdch() REPEATWHILE ch='*c' // Ignore CR characters
  }

  RESULTIS n  // Number of characters read before *n or EOF
}
