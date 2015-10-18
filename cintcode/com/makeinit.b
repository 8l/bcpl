/* MakeInit -- Construct an initialisation file for a
*  multi-file NATBCPL application.
*  Written by Colin Liebenrood  (cjlieben@waitrose.com)
*
*  Slightly modified by Martin Richards (mr@cl.cam.ac.uk)
*  to give it the following usage:
*
* makeinit aaa.b bbb.b ... kkk.b to init.c stacksize 20000 gsize 2000
*
* $Log: makeinit.b,v $
*
* Revision 2.0  2010/09/23 11:42:34  martin
* Changed the default stack size to 50000
*
* Revision 1.9  2009/09/07 12:50:13  martin
* Used BCPLWORD instead of WORD plus other minor changes
* Changed performget to be compatible with the latest bcplfe
*
* Revision 1.8  2004/04/25 07:38:23  martin
* Made GET directives use BCPLHDRS environment variable
*
* Revision 1.7  2004/04/21 16:35:00  martin
* Changed rdargs format to ",,,,,,,,,,TO/k/a,STKSIZE/k,GLOBSIZE/k"
*
* Revision 1.6  2004/04/03 14:53:05  colin
* Revised order of arguments, to allow input from stdin with named output only
* Use rdargs()-style command line.  Protect against no files in input-list.
* Tidy version-number display.
*
* Revision 1.5  2004/04/01 16:12:22  colin
* Made target stack-size and global vector size into parameters.
* Altered emitted code to conform to revised function prototypes in bcpl.h
*
* Revision 1.4  2004/03/21 17:45:13  colin
* Fix coding error
*
* Revision 1.3  2004/03/21 17:42:03  colin
* Fully working? with comments updated
*
* Revision 1.2  2004/03/19 20:17:00  colin
* Handling multiple files and storing section-names. Wrong status returns
*
* Revision 1.1  2004/03/18 15:54:10  colin
* Initial revision
*
*
*/

SECTION "MakeInit"

GET "libhdr"
 
MANIFEST { 
// Used in scanforsection(), lex() and friends
s_number=1; s_name; s_string; s_true; s_false
s_div; s_logand; s_needs; s_section
s_end; s_lsect; s_rsect; s_get
s_dot; s_eof

h1=0; h2; h3; h4            //  Selectors
bt_name=0; bt_left; bt_right; bt_file

c_backspace =  8        // Character constants
c_tab       =  9
c_newline   = 10
c_newpage   = 12
c_return    = 13
c_escape    = 27
c_space     = 32

nametablesize = 541
worksize      = 40000
storesize     = 5000

RTF8=1
GB2312
}
 
GLOBAL {
// Variables for scanforsection() etc
getstreams:ug; charv; token; wordnode; ch
decval; hdrs
bigender
skiptag; lineno; nametable
treep; treevec; sourcestream
scanerror; sectionseen

// Global variables
currentfile; storevec; storevp
sections; stacksize; gvecsize
defaultencoding
encoding
}
 

LET start() = VALOF
{ LET inputstream, outputstream = ?, ?
  AND work = ?
  AND fileseen, runok = 0,1
  LET argv = VEC 100
  LET version = VEC 5

  UNLESS rdargs(",,,,,,,,,,,TO/A/K,STKSIZE/K,GLOBSIZE/K", argv, 100) DO {
    writes("Bad arguments*n")
    RESULTIS 20
  }

  outputstream := findoutput(argv ! 11)
  IF outputstream = 0 DO {
    writef("Cannot open file %s*n", argv ! 11)
    RESULTIS 20
  }

// default allocations for user program   
  stacksize := 50000
  IF argv!12 DO {
    stacksize := str2numb(argv!12)
    IF stacksize < 10000 DO stacksize := 10000
  }

  gvecsize := 1000
  IF argv!13 DO {
    gvecsize := str2numb(argv!13)
    IF gvecsize < 500 DO gvecsize := 500
  }

  hdrs := "BCPLHDRS"
  bigender := (!"AAA" & 255) = 'A' // =TRUE if running on a bigender

  writef("MakeInit version %s*n", getversion(version))

// Allocate working memory for scanning the files
  work := getvec(worksize)
  UNLESS work DO
  { writes("Insufficient memory*n")
    RESULTIS 20
  }

// Allocate storage for information found
  storevec := getvec(storesize)
  UNLESS storevec DO {
    writes("Insufficient memory(store)*n")
    RESULTIS 20
  }

  storevp := storevec+storesize

// Initialise the storage and add a universal entry
  sections := 0
  recordsection("BLIB", "(run-time library)")
  recordsection("DLIB", "(system dependent library)")

  FOR i = 0 TO 10 DO
  {
    // Scan the input-file for filenames. Pass each name found to
    // scanforsection() to extract any SECTION "..." entries found, 
    // which are stored in storevec, anchored at global sections.
    LET file = argv!i
    UNLESS file LOOP
    fileseen := fileseen + 1
    scanforsection(file, work)
    IF scanerror > 0 DO runok := 0
  }

// output the new file
  IF fileseen & runok DO {
    LET op = output()
    selectoutput(outputstream)
    writeinitfile()
    UNLESS outputstream=op DO endwrite()
    selectoutput(op)
  }

  UNLESS fileseen DO writes("Error - no file(s) seen*n")

  freevec(work)
  freevec(storevec)

  RESULTIS fileseen & runok -> 0, 10 
}

// Extract version-number from Revision string
AND getversion(v) = VALOF {
  LET version = "$Revision: 2.0 $" // updated by RCS
  AND len, s, d = 0, 1, 1

  len := version%0
  UNTIL ('0' <= version%s <= '9') | s = len DO s := s + 1
  UNTIL version%s = ' ' | s = len DO {
    v%d := version%s
    s := s + 1; d := d + 1
  }
  v%0 := d-1
  RESULTIS v
}

// Scan file for SECTION "...." entries, using workspace for
// working memory.
AND scanforsection(file, workspace) BE {
  treevec := workspace
  treep := treevec + worksize

  sourcestream := findinput(file)
  IF sourcestream=0 DO { 
    writef("Trouble with file %s*n", file)
    scanerror := 1
    RETURN
  }

  currentfile := newstring(file)
  selectinput(sourcestream)
  scanerror := 0
  sectionseen := 0
  lineno := 1
  rch()
  getstreams := 0
  charv      := newvec(256/bytesperword)     
  nametable  := newvec(nametablesize) 
  FOR i = 0 TO nametablesize DO nametable!i := 0
  skiptag := 0
  declsyswords()

  UNTIL (ch=endstreamch & getstreams=0) | scanerror DO { 
    lex()
    IF token = s_section {
      lex()
      IF token = s_string DO {
        recordsection(charv, currentfile)
        sectionseen := 1
      }
    }
  }

  endread()
  UNLESS sectionseen DO {
    writef("No Section seen in file %s*n", currentfile)
    scanerror := 1
  }
  RETURN
}

// Record a section-entry in store, using a binary-tree structure, so that
// eventual output is in ascending alphabetic order of section name.
// Duplicate section-names are errors and are reported as such.
AND recordsection(s, f) BE {
  LET p = @sections
  LET node = !p

  UNTIL node=0 DO {
    LET cmp = cmpstr(s, node!bt_name)
    IF cmp = 0 DO {
      writef("Duplicate section %s in %s and %s*n", s, f, node!bt_file)
      scanerror := scanerror+1
      RETURN
    }
    
    p := node + (cmp < 0 -> bt_left, bt_right)
    node := !p
  }

  node := newstorevec(bt_file)
  node!bt_name := newstring(s)
  node!bt_left, node!bt_right := 0, 0
  node!bt_file := f
  !p := node
}

// Compare two strings, ignoring case
AND cmpstr(s1, s2) = VALOF
{ LET len1, len2 = s1%0, s2%0
  FOR i = 1 TO len1 DO
  { LET ch1, ch2 = s1%i, s2%i
    IF i>len2  RESULTIS 1
    IF 'a'<=ch1<='z' DO ch1:=ch1-'a'+'A'
    IF 'a'<=ch2<='z' DO ch2:=ch2-'a'+'A'
    IF ch1>ch2 RESULTIS 1
    IF ch1<ch2 RESULTIS -1
  }
  IF len1<len2 RESULTIS -1
  RESULTIS 0
}

// Allocate storage for section and file names
AND newstorevec(n) = VALOF {
  storevp := storevp - n - 1
  IF storevp <= storevec DO {
    writes("Out of store space*n")
    stop(20)
  }

  RESULTIS storevp
}

// Allocate space for a copy of string s in the store
AND newstring(s) = VALOF {
  LET size = 1 + s%0 / bytesperword
  LET str = newstorevec(size)
  FOR i = 0 TO s%0
   str%i := s%i

  RESULTIS str
}

// Write the initialisation file, using the section-names found.
AND writeinitfile() BE {
  LET version = VEC 5
  writef("/** Initialisation file written by MakeInit version %s  **/*n",
        getversion(version))
  writes("#include *"bcpl.h*"*n")
  writef("*nint stackupb=%n;*n", stacksize)
  writef("*nint gvecupb=%n;*n",  gvecsize)
  writes("*n/** BCPL sections  **/*n")
  // List references to other modules
  listsects(sections, "extern %s(BCPLWORD **g); *t/** file %s  **/*n")
  newline()
  // List initsections() functions
  writes("void initsections(BCPLWORD **g) {*n")
  listsects(sections, "       %s(g); *t/** file %s  **/*n")
  writes("*n       return;*n}*n")
}

// List store entries in order (binary tree in-order traverse), using
// the passed writef format for section-name and file-name
AND listsects(p, fmt) BE {
   UNLESS p = 0 DO {
     listsects(p!bt_left, fmt)
     writef(fmt, p!bt_name, p!bt_file)
     listsects(p!bt_right, fmt)
   }
}

// lex() returns the next relevant symbol from the current input-stream, in
// globals token and charv. This routine and those it uses have been extracted
// from the compiler (bcpl.b) and simplified for this purpose.
AND lex() BE
{
  { SWITCHON ch INTO

    { DEFAULT:
            { LET badch = ch
              ch := '*s'
              synerr("Illegal character %x2", badch)
            }

      CASE '*p':
      CASE '*n': lineno := lineno + 1

      CASE '*c':
      CASE '*t':
      CASE '*s':
                rch() REPEATWHILE ch='*s'
                LOOP

      CASE '0':CASE '1':CASE '2':CASE '3':CASE '4':
      CASE '5':CASE '6':CASE '7':CASE '8':CASE '9':
      CASE '_':
                rch(); LOOP
 
      CASE 'a':CASE 'b':CASE 'c':CASE 'd':CASE 'e':
      CASE 'f':CASE 'g':CASE 'h':CASE 'i':CASE 'j':
      CASE 'k':CASE 'l':CASE 'm':CASE 'n':CASE 'o':
      CASE 'p':CASE 'q':CASE 'r':CASE 's':CASE 't':
      CASE 'u':CASE 'v':CASE 'w':CASE 'x':CASE 'y':
      CASE 'z':
      CASE 'A':CASE 'B':CASE 'C':CASE 'D':CASE 'E':
      CASE 'F':CASE 'G':CASE 'H':CASE 'I':CASE 'J':
      CASE 'K':CASE 'L':CASE 'M':CASE 'N':CASE 'O':
      CASE 'P':CASE 'Q':CASE 'R':CASE 'S':CASE 'T':
      CASE 'U':CASE 'V':CASE 'W':CASE 'X':CASE 'Y':
      CASE 'Z':
               token := lookupword(rdtag(ch))
               IF token=s_get DO { performget(); LOOP  }
               RETURN
 
      CASE '$':
               rch()
               IF ch='$' | ch='<' | ch='>' DO
               { LET k = ch
                 token := lookupword(rdtag('<'))
                 // token = s_true             if the tag is set
                 //      = s_false or s_name  otherwise
 
                 // $>tag   marks the end of a conditional
                 //         skipping section
                 IF k='>' DO
                 { IF skiptag=wordnode DO
                      skiptag := 0   // Matching $>tag found
                   LOOP
                 }
 
                 UNLESS skiptag=0 LOOP

                 // Only process $<tag and $$tag if not skipping
 
                 // $$tag  complements the value of a tag
                 IF k='$' DO
                 { h1!wordnode := token=s_true -> s_false, s_true
                   LOOP
                 }
 
                 // $<tag
                 IF token=s_true LOOP      // Don't skip if set

                 // tag is false so skip until matching $>tag or EOF
                 skiptag := wordnode
                 UNTIL skiptag=0 | token=s_end DO lex()
                 skiptag := 0
                 LOOP
              }
 
              UNLESS ch='(' | ch=')' DO synerr("'$' out of context")
              token := ch='(' -> s_lsect, s_rsect
              lookupword(rdtag('$'))
              LOOP //RETURN
 
      CASE '/':
               rch()
               IF ch='\' DO { token := s_logand; BREAK }
               IF ch='/' DO
               { rch() REPEATUNTIL ch='*n' | ch=endstreamch
                 LOOP
               }
 
               IF ch='**' DO
               { LET depth = 1

                 { rch()
                   IF ch='**' DO
                   { rch() REPEATWHILE ch='**'
                     IF ch='/' DO {  depth := depth-1; LOOP }
                   }
                   IF ch='/' DO
                   { rch()
                     IF ch='**' DO {  depth := depth+1; LOOP }
                   }
                   IF ch='*n' DO lineno := lineno+1
                   IF ch=endstreamch DO synerr("Missing '**/'")
                 } REPEATUNTIL depth=0

                 rch()
                 LOOP
               }

               token := s_div
               LOOP

      CASE '#':
               token := s_number
               rch()
               IF '0'<=ch<='7'    DO {        readnumber(8,  100); LOOP  }
               IF ch='b' | ch='B' DO { rch(); readnumber(2,  100); LOOP  }
               IF ch='o' | ch='O' DO { rch(); readnumber(8,  100); LOOP  }
               IF ch='x' | ch='X' DO { rch(); readnumber(16, 100); LOOP  }
               LOOP
 
      CASE '.': token := s_dot;       BREAK

      CASE '{': CASE '}': 
      CASE '[': CASE '(': CASE ']': CASE ')': CASE '?': 
      CASE '+': CASE ',': CASE ';': CASE '@': CASE '&': 
      CASE '|': CASE '=': CASE '!': CASE '%': CASE '**':
      CASE '~': CASE '\': CASE '<': CASE '>':  CASE '-':
      CASE ':': 
                rch()
                LOOP

      CASE '"':
           { LET len = 0
             rch()
             encoding := defaultencoding // encoding for *# escapes

             UNTIL ch='"' DO
             { LET code = rdstrch()
               TEST result2
               THEN { // A  *# code found.
                      // Convert it to UTF8 or GB2312 format.
                      TEST encoding=GB2312
                      THEN { // Convert to GB2312 sequence
                             IF code>#x7F DO
                             { LET hi = code  /  100 + 160
                               LET lo = code MOD 100 + 160
                               IF len>=254 DO synerr("Bad string constant")
                               TEST bigender
                               THEN { charv%(len+1) := hi 
                                      charv%(len+2) := lo
                                    }
                               ELSE { charv%(len+1) := lo 
                                      charv%(len+2) := hi
                                    }
                               len := len + 2
                               LOOP
                             }
                             IF len>=255 DO synerr("Bad string constant")
                             charv%(len+1) := code // Ordinary ASCII char
                             len := len + 1
                             LOOP
                           }
                      ELSE { // Convert to UTF8 sequence
                             IF code<=#x7F DO
                             { IF len>=255 DO synerr("Bad string constant")
                               charv%(len+1) := code   // 0xxxxxxx
                               len := len + 1
                               LOOP
                             }
                             IF code<=#x7FF DO
                             { IF len>=254 DO synerr("Bad string constant")
                               charv%(len+1) := #b1100_0000+(code>>6)  // 110xxxxx
                               charv%(len+2) := #x80+( code    &#x3F)  // 10xxxxxx
                               len := len + 2
                               LOOP
                             }
                             IF code<=#xFFFF DO
                             { IF len>=253 DO synerr("Bad string constant")
                               charv%(len+1) := #b1110_0000+(code>>12) // 1110xxxx
                               charv%(len+2) := #x80+((code>>6)&#x3F)  // 10xxxxxx
                               charv%(len+3) := #x80+( code    &#x3F)  // 10xxxxxx
                               len := len + 3
                               LOOP
                             }
                             IF code<=#x1F_FFFF DO
                             { IF len>=252 DO synerr("Bad string constant")
                               charv%(len+1) := #b1111_0000+(code>>18) // 11110xxx
                               charv%(len+2) := #x80+((code>>12)&#x3F) // 10xxxxxx
                               charv%(len+3) := #x80+((code>> 6)&#x3F) // 10xxxxxx
                               charv%(len+4) := #x80+( code     &#x3F) // 10xxxxxx
                               len := len + 4
                               LOOP
                             }
                             IF code<=#x3FF_FFFF DO
                             { IF len>=251 DO synerr("Bad string constant")
                               charv%(len+1) := #b1111_1000+(code>>24) // 111110xx
                               charv%(len+2) := #x80+((code>>18)&#x3F) // 10xxxxxx
                               charv%(len+3) := #x80+((code>>12)&#x3F) // 10xxxxxx
                               charv%(len+4) := #x80+((code>> 6)&#x3F) // 10xxxxxx
                               charv%(len+5) := #x80+( code     &#x3F) // 10xxxxxx
                               len := len + 5
                               LOOP
                             }
                             IF code<=#x7FFF_FFFF DO
                             { IF len>=250 DO synerr("Bad string constant")
                               charv%(len+1) := #b1111_1100+(code>>30) // 1111110x
                               charv%(len+2) := #x80+((code>>24)&#x3F) // 10xxxxxx
                               charv%(len+3) := #x80+((code>>18)&#x3F) // 10xxxxxx
                               charv%(len+4) := #x80+((code>>12)&#x3F) // 10xxxxxx
                               charv%(len+5) := #x80+((code>> 6)&#x3F) // 10xxxxxx
                               charv%(len+6) := #x80+( code     &#x3F) // 10xxxxxx
                               len := len + 6
                               LOOP
                             }
                             synerr("Bad Unicode character")
                           }
                    }
               ELSE { // Not a Unicode character
                      IF len=255 DO synerr("Bad string constant")
                      len := len + 1
                      charv%len := code
                    }
             }
 
             charv%0 := len
             token := s_string
             BREAK
          }
  
      CASE '*'':
              rch()
              encoding := defaultencoding
              decval := rdstrch()
              token := s_number
              UNLESS ch='*'' DO synerr("Bad character constant")
              BREAK

       CASE endstreamch:
              IF getstreams DO
              { // Return from a 'GET' stream
                LET p = getstreams
                endread()
                ch           := h4!getstreams
                lineno       := h3!getstreams
                sourcestream := h2!getstreams
                getstreams   := h1!getstreams
                freevec(p) // Free the GET node
                selectinput(sourcestream)
                LOOP
              }
              // endstreamch => EOF only at outermost GET level 
              token := s_eof
              RETURN
    }
  } REPEAT
 
  rch()
}

// Access and maintain a symbol-table for lex()
AND lookupword(word) = VALOF
{ LET len, i = word%0, 0
  LET hashval = 19609 // This and 31397 are primes.
  FOR i = 0 TO len DO hashval := (hashval NEQV word%i) * 31397
  hashval := (hashval>>1) REM nametablesize

  wordnode := nametable!hashval
 
  UNTIL wordnode=0 | i>len TEST (@h3!wordnode)%i=word%i
                           THEN i := i+1
                           ELSE wordnode, i := h2!wordnode, 0
 
  IF wordnode=0 DO
  { wordnode := newvec(len/bytesperword+3)
    h1!wordnode, h2!wordnode := s_name, nametable!hashval
    FOR i = 0 TO len DO (@h3!wordnode)%i := word%i
    nametable!hashval := wordnode
  }
 
  RESULTIS h1!wordnode
}
 
// Symbol-table initialisation
AND dsw(word, sym) BE { lookupword(word); h1!wordnode := sym  }
 
AND declsyswords() BE
{ dsw("GET", s_get)
  dsw("NEEDS", s_needs)
  dsw("SECTION", s_section)
  dsw("$", 0)
} 
 
// lex() support-routines
AND rch() BE {
    ch:= rdch()
}
 
AND rdtag(ch1) = VALOF
{ LET len = 1
  charv%1 := ch1
 
  { rch()
    UNLESS 'a'<=ch<='z' | 'A'<=ch<='Z' |
           '0'<=ch<='9' | ch='.' | ch='_' BREAK
    len := len+1
    charv%len := ch
  } REPEAT
 
  charv%0 := len
  RESULTIS charv
}
 
AND catstr(s1, s2) = VALOF
// Concatenate strings s1 and s2 leaving the result in s1.
// s1 is assumed to be able to hold a string of length 255.
// The resulting string is truncated to length 255, if necessary. 
{ LET len = s1%0
  LET n = len
  FOR i = 1 TO s2%0 DO
  { n := n+1
    IF n>255 BREAK
    s1%n := s2%i
  }
  s1%0 := n
} 
 
AND performget() BE
{ LET stream = ?
  LET len = 0
  lex()
  UNLESS token=s_string DO synerr("Bad GET directive")
  len := charv%0

  // Append .h to the GET filename does not end in .h or .b
  UNLESS len>=2 & charv%(len-1)='.' & 
         (charv%len='h' | charv%len='b') DO
  { len := len+2
    charv%0, charv%(len-1), charv%len := len, '.', 'h'
  }

  FOR i = 1 TO charv%0 IF charv%i=':' DO charv%i := '/'

  // First look in the current directory
  //writef("Searching for *"%s*" in the current directory*n", charv)
  stream := findinput(charv)

  // Then try the headers directories
  //UNLESS stream DO writef("Searching for *"%s*" in %s*n", charv, hdrs)
  UNLESS stream DO stream := pathfindinput(charv, hdrs)

  // Finally prepend g/ and lookup in the system root directory
  UNLESS stream DO
  { LET filename = VEC 256/bytesperword
    filename%0 := 0
    catstr(filename, "g/")
    catstr(filename, charv)
    //writef("Searching for *"%s*" in %s*n", filename, rootnode!rtn_rootvar)
    stream := pathfindinput(filename, rootnode!rtn_rootvar)
  }

  UNLESS stream DO
  { synerr("Unable to find GET file %s", charv)
    RETURN
  }

  { LET len = charv%0
    LET node = getvec(4 + len/bytesperword)
    LET str = @node!4

    UNLESS node DO synerr("getvec failure in performget")

    FOR i = 0 TO len DO str%i := charv%i
//    sourcefileno := sourcefileno+1
//    sourcenamev!sourcefileno := str
    node!0, node!1, node!2, node!3 := getstreams, sourcestream, lineno, ch
    getstreams := node
  }

  sourcestream := stream
  selectinput(sourcestream)
  lineno := 1
  rch()
}
 
AND readnumber(radix, digs) = VALOF
// Read a binary, octal, decimal or hexadecimal unsigned number
// with between 1 and digs digits. Underlines are allowed.
// This function is used for numerical constants and numerical
// escapes in string and character constants.
{ LET i, res = 0, 0
 
  { UNLESS ch='_' DO // ignore underlines
    { LET d = value(ch)
      IF d>=radix BREAK
      i := i+1       // Increment count of digits
      res := radix*res + d
    }
    rch()
  } REPEATWHILE i<digs

  UNLESS i DO synerr("Bad number")
  RESULTIS res
}
 
AND value(ch) = '0'<=ch<='9' -> ch-'0',
                'A'<=ch<='F' -> ch-'A'+10,
                'a'<=ch<='f' -> ch-'a'+10,
                100
 
AND rdstrch() = VALOF
{ // Return the integer code for the next string character
  // Set result2=TRUE if *# character code was found, otherwise FALSE
  LET k = ch

  IF k='*n' | k='*p' DO
  { lineno := lineno+1
    synerr("Unescaped newline character")
  }
 
  IF k='**' DO
  { rch()
    k := ch
    IF 'a'<=k<='z' DO k := k + 'A' - 'a'
    SWITCHON k INTO
    { CASE '*n':
      CASE '*c':
      CASE '*p':
      CASE '*s':
      CASE '*t': WHILE ch='*n' | ch='*c' | ch='*p' | ch='*s' | ch='*t' DO
                 { IF ch='*n' DO lineno := lineno+1
                   rch()
                 }
                 IF ch='**' DO { rch(); LOOP  }

      DEFAULT:   synerr("Bad string or character constant, ch=%n", ch)
         
      CASE '**':
      CASE '*'':
      CASE '"':                    ENDCASE
         
      CASE 'T':  k := c_tab;       ENDCASE
      CASE 'S':  k := c_space;     ENDCASE
      CASE 'N':  k := c_newline;   ENDCASE
      CASE 'E':  k := c_escape;    ENDCASE
      CASE 'B':  k := c_backspace; ENDCASE
      CASE 'P':  k := c_newpage;   ENDCASE
      CASE 'C':  k := c_return;    ENDCASE
         
      CASE 'X':  // *xhh  -- A character escape in hexadecimal
                 rch()
                 k := readnumber(16,2)
                 result2 := FALSE
                 RESULTIS k

      CASE '#':  // *#u   set UTF8 mode
                 // *#g   set GB2312 mode
                 // In UTF8 mode
                 //     *#hhhh or *##hhhhhhhh  -- a Unicode character
                 // In GB2312
                 //     *#dddd                 -- A GB2312 code
               { LET digs = 4
                 rch()
                 IF ch='u' | ch='U' DO { encoding := UTF8;   rch(); LOOP }
                 IF ch='g' | ch='G' DO { encoding := GB2312; rch(); LOOP }
                 TEST encoding=GB2312
                 THEN { 
                        k := readnumber(10, digs)
//sawritef("rdstrch: GB2312: %i4*n", k)
                      }
                 ELSE { IF ch='#' DO { rch(); digs := 8 }
                        k := readnumber(16, digs)
//sawritef("rdstrch: Unicode: %x4*n", k)
                      }
                 result2 := TRUE
                 RESULTIS k
               }

      CASE '0':CASE '1':CASE '2':CASE '3':CASE '4':
      CASE '5':CASE '6':CASE '7':
                 // *ooo -- A character escape in octal 
                 k := readnumber(8,3)
                 IF k>255 DO 
                       synerr("Bad string or character constant")
                 result2 := FALSE
                 RESULTIS k
    }
  }
   
  rch()
  result2 := FALSE
  RESULTIS k
} REPEAT

AND newvec(n) = VALOF
{ treep := treep - n - 1;
  IF treep<=treevec DO
     synerr("More workspace needed")

  RESULTIS treep
}

AND list4(x, y, z, t) = VALOF
{ LET p = newvec(3)
  p!0, p!1, p!2, p!3 := x, y, z, t
  RESULTIS p
}
 
AND synerr(mess, a, b) BE {
  writef("*nError near line %n:  ", lineno)
  writef(mess, a, b)
  //writef(" in file %s*n", currentfile)
  newline()
  scanerror := 1
}
