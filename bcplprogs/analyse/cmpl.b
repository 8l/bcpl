/* Change history

15/1/01
Complain if global number is larger than 65535.

10/8/00
Change the maximum number of error message from 30 to 10.

14/12/99
Made / * ... * /  comments nest.
Allow the constants in MANIFEST, STATIC and GLOBAL declarations 
to be optional. If absent the value is one greater than the
previous value. Unless specified the first value is zero, so
MANIFEST { a; b=10; c } declares a, b and c to be 0, 10 and 11,
respectively.

9/6/99
Made changes to buffer OCODE in memory. When bcpl is called
without the TO argument it writes numeric ocode to the file OCODE.
Lex treats CR (13) correctly to improve convenience when running
under Windows and WindowsCE.

26/2/99
Added BIN option to the compiler to generate a binary (rather than
hex) hunk format for the compiled code. This is primarily for the
Windows CE version of the cintcode system where compactness is
particularly important. There is a related change to loadseg in
cintmain.c

17/11/98
Changed the workspacesize to 40000 and added the SIZE keyword
to allow the user to specify this size.

9/11/98
Made GET directives search the current working directory
then directories given by the shell variable BCPLPATH, if set.
It uses the BLIB function pathfindinput.

15/12/96
Correct a bug in cellwithname

16/8/96
Added one line to readnumber to allow underscores in numbers after 
the first digit.

7/6/96
Implement the method application operator for object oriented
programming in BCPL. E # (E1, E2,..., En) is equivalent to
((!E1)!E)(E1, E2,..., En)

24/12/95
Improved the efficiency of cellwithname in TRN (using the hash chain
link in name node).
Improved the efficiency of outputsection in CG by introducing
wrhex2 and wrword_at.

24/7/95
Removed bug in atbinfo, define addinfo_b change some global numbers.
Implement constant folding in TRN.

13/7/95
Allowed { and } to represent untagged section brackets.

22/6/93
Reverse order in SWB and have a minimum of 7 cases
to allow faster interpreter.

2/6/93
Changed code for SWB to use heap-like binary tree.

19/5/93
Put in code to compile BTC and XPBYT instructions.

23/4/93
Allowed the codegenerator to compiler the S instruction.

21/12/92
Cured bug in compilation of (b -> f, g)(1,2,3)

24/11/92 
Cured bug in compilation of a, b := s%0 > 0, s%1 = '!'

23/7/92:
Renamed nextlab as newlab, load as loadval in the CG.
Put back simpler hashing function in lookupword.
Removed rdargs fudge.
Removed S2 compiler option.
Cured bug concerning the closing of gostream when equal to stdout.
*/

SECTION "SYN"

//   SYNHDR
 
GET "libhdr"
 
MANIFEST $(                          // Parse Tree operators

s_number=1; s_name=2; s_string=3; s_true=4; s_false=5
s_valof=6; s_lv=7; s_rv=8; s_vecap=9; s_fnap=10
s_mult=11; s_div=12; s_rem=13
s_plus=14; s_minus=15; s_query=16; s_neg=17; s_abs=19
s_eq=20; s_ne=21; s_ls=22; s_gr=23; s_le=24; s_ge=25
s_byteap = 28; s_mthap=29
s_not=30; s_lshift=31; s_rshift=32; s_logand=33; s_logor=34
s_eqv=35; s_neqv=36; s_cond=37; s_comma=38; s_table=39
s_and=40; s_valdef=41; s_vecdef=42; s_constdef=43
s_fndef=44; s_rtdef=45; s_needs=48; s_section=49
s_ass=50; s_rtap=51; s_goto=52; s_resultis=53; s_colon=54
s_test=55; s_for=56; s_if=57; s_unless=58
s_while=59; s_until=60; s_repeat=61; s_repeatwhile=62
s_repeatuntil=63
s_loop=65; s_break=66; s_return=67; s_finish=68
s_endcase=69; s_switchon=70; s_case=71; s_default=72
s_seq=73; s_let=74; s_manifest=75; s_global=76; s_static=79
 
// OTHER BASIC SYMBOL CODES
s_be=89; s_end=90; s_lsect=91; s_rsect=92; s_get=93
s_semicolon=97; s_into=98
s_to=99; s_by=100; s_do=101; s_else=102
s_vec=103; s_lparen=105; s_rparen=106
$)
 
GLOBAL $(                    // Globals used in LEX
chbuf:200; decval:201; getstreams:202; charv:203
// OCODE buffer variables
obuf:205; obufp:206; obufq:207; obuft:208; obufsize:209
workvec:210; rdn:211; wrn:212  
readnumber:213; rdstrch:214
symb:215; wordnode:216; ch:217
rdtag:218; performget:219
lex:220; dsw:221; declsyswords:222; nlpending:223
lookupword:225; rch:226;
skiptag:230; wrchbuf:231; chcount:232; lineno:233
nulltag:234; rec_p:235; rec_l:236; fin_p:237; fin_l:238
 
// GLOBALS USED IN SYN
rdblockbody:240;  rdsect:241
rnamelist:242; rname:243
rdef:245; rcom:246
rdcdefs:247; nametable:248; nametablesize:249
formtree:250; synerr:251; plist:252
rexplist:255; rdseq:256
list1:261; list2:262; list3:263
list4:264; list5:265; list6:266; list7:267
newvec:268; treep:269; treevec:270
rnexp:271; rexp:272; rbexp:274
errcount:291; errmax:292
sourcestream:293; sysprint:294; ocodeout:295
gostream: 297; eqcases: 298; prtree: 299
trnerr:312; translate:345
savespacesize:382
$)
 
 
MANIFEST $(                         //  Selectors
h1=0; h2=1; h3=2; h4=3; h5=4; h6=5; h7=6

c_backspace =  8
c_tab       =  9
c_newline   = 10
c_newpage   = 12
c_return    = 13
c_escape    = 27
c_space     = 32
$)
 
GLOBAL $(
codegenerate:399

bigender : 550
naming   : 551
debug    : 552
bining   : 553

$)

LET start() = VALOF
$( LET treesize = 0
   AND argv = VEC 50
   AND argform =
"FROM/A,TO/K,VER/K,SIZE/K,TREE/S,NONAMES/S,D1/S,D2/S,OENDER/S,EQCASES/S,BIN/S"
   LET stdout = output()

   errmax   := 10
   errcount := 0
   fin_p, fin_l := level(), fin

   treevec      := 0
   obuf         := 0
   sourcestream := 0
   ocodeout     := 0
   gostream     := 0
   
   sysprint := stdout
   selectoutput(sysprint)
 
   writef("*nBCPL (10 Aug 2000)*n")
 
   IF rdargs(argform, argv, 50)=0 DO $( writes("Bad arguments*n")
                                        errcount := 1
                                        GOTO fin
                                     $)
   treesize := 40000
   IF argv!3 DO treesize := str2numb(argv!3)
   IF treesize<10000 DO treesize := 10000
   obufsize := treesize/4

   prtree        := argv!4
   savespacesize := 3

   // Code generator options 

   naming := TRUE
   debug := 0
   bigender := (!"AAA" & 255) = 'A' // =TRUE if running on a bigender
   IF argv!5 DO naming   := FALSE         // NONAMES
   IF argv!6 DO debug    := debug+1       // D1
   IF argv!7 DO debug    := debug+2       // D2
   IF argv!8 DO bigender := ~bigender     // OENDER
   eqcases := argv!9                      // EQCASES
   bining  := argv!10                     // BIN (binary hunk)

   sourcestream := findinput(argv!0)      // FROM

   IF sourcestream=0 DO $( writef("Trouble with file %s*n", argv!0)
                           errcount := 1
                           GOTO fin
                        $)

   selectinput(sourcestream)
 
   TEST argv!1          // TO
   THEN $( gostream := findoutput(argv!1)
           IF gostream=0 DO
           $( writef("Trouble with code file %s*n", argv!1)
              errcount := 1
              GOTO fin
           $)
        $)
   ELSE { ocodeout := findoutput("OCODE")
          IF ocodeout=0 DO
          $( writes("Trouble with file OCODE*n")
             errcount := 1
             GOTO fin
          $)
        }

   treevec := getvec(treesize)
   obuf    := getvec(obufsize)

   IF treevec=0 | obuf=0 DO
   $( writes("Insufficient memory*n")
      errcount := 1
      GOTO fin
   $)
   
   UNLESS argv!2=0 DO       // VER
   $( sysprint := findoutput(argv!2)
      IF sysprint=0 DO
      $( sysprint := stdout
         writef("Trouble with file %s*n", argv!2)
         errcount := 1
         GOTO fin
      $)
   $)

   selectoutput(sysprint)

   // Now syntax analyse, translate and code-generate each section
   $( LET b = VEC 64/bytesperword
      chbuf := b
      FOR i = 0 TO 63 DO chbuf%i := 0
      chcount, lineno := 0, 1
      rch()
 
      UNTIL ch=endstreamch DO
      $( LET tree = ?
         treep := treevec + treesize
         obufp := 0
         obuft := obufsize * bytesperword

         tree := formtree()
         IF tree=0 BREAK
 
         //writef("Tree size %n*n", treesize+treevec-treep)
 
         IF prtree DO $( writes("Parse Tree*n")
                         plist(tree, 0, 20)
                         newline()
                      $)
  
         UNLESS errcount=0 GOTO fin

//writef("calling translate (=%n)*n", translate); sys(2) 
         translate(tree)

         obufq := obufp     // Prepare to read from OCODE buffer
         obufp := 0

         TEST argv!1=0
         THEN writeocode()  // Write OCODE file if no TO argument
         ELSE codegenerate(treevec, treesize)
      $)
   $)
   
fin:
   UNLESS treevec=0       DO freevec(treevec)
   UNLESS obuf=0          DO freevec(obuf)
   UNLESS sourcestream=0  DO $( selectinput(sourcestream); endread()  $)
   UNLESS ocodeout=0      DO $( selectoutput(ocodeout)
                                UNLESS ocodeout=stdout DO endwrite()
                             $)
   UNLESS gostream=0      DO $( selectoutput(gostream)
                                UNLESS gostream=stdout DO  endwrite() $)
   UNLESS sysprint=stdout DO $( selectoutput(sysprint);    endwrite() $)

   selectoutput(stdout)
   RESULTIS errcount=0 -> 0, 20
$)

// ************* OCODE I/O Routines **************************

/*
The OCODE buffer variables are:

obuf         is the OCODE buffer -- (obuf=workvec)
obufp        position of next byte in the OCODE buffer
obufq        another pointer into the OCODE buffer
obuft        end of the OCODE buffer.
obufsize     size of obuf (in words)
*/

AND writeocode() BE
{ LET layout = 0
  selectoutput(ocodeout)

  UNTIL obufp>=obufq DO
  { writef(" %n", rdn())
    layout := layout+1
    UNLESS layout REM 16 DO newline()
  }
  newline()
  selectoutput(sysprint)
  writef("OCODE size: %i5/%n*n", obufq, obuft)
}

AND rdn() = VALOF
{ LET byte = obuf%obufp
  IF obufp>=obufq RESULTIS 0
  obufp := obufp+1
  IF byte<223 RESULTIS byte
  IF byte=223 RESULTIS -1
  RESULTIS (byte&31) + (rdn()<<5)
}

AND wrn(n) BE
{ IF obufp>=obuft DO
  { errmax := 0 // make it fatal
    trnerr("More workspace needed for OCODE buffer*n")
  }
  IF -1<=n<223 DO    // This is the normal case
  { IF n=-1 DO n := 223
    obuf%obufp := n
    obufp := obufp + 1
    RETURN
  }
  obuf%obufp := 224 + (n&31)
  obufp := obufp + 1
  n := n>>5
} REPEAT

// ************* End of  OCODE I/O Routines *******************
  
LET lex() BE
$( nlpending := FALSE
 
   $( SWITCHON ch INTO
 
      $( CASE '*p':
         CASE '*n':
               lineno := lineno + 1
               nlpending := TRUE  // IGNORABLE CHARACTERS
         CASE '*c':
         CASE '*t':
         CASE '*s':
               rch() REPEATWHILE ch='*s'
               LOOP

         CASE '0':CASE '1':CASE '2':CASE '3':CASE '4':
         CASE '5':CASE '6':CASE '7':CASE '8':CASE '9':
              symb := s_number
              readnumber(10)
              RETURN
 
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
              symb := lookupword(rdtag(ch))
              IF symb=s_get DO $( performget(); LOOP  $)
              RETURN
 
         CASE '$':
              rch()
              IF ch='$' | ch='<' | ch='>' DO
              $( LET k = ch
                 symb := lookupword(rdtag('<'))
                 // symb = s_true             if the tag is set
                 //      = s_false or s_name  otherwise
 
                 // $>tag   marks the end of a conditional
                 //         skipping section
                 IF k='>' DO
                 $( IF skiptag=wordnode DO
                       skiptag := 0   // Matching $>tag found
                    LOOP
                 $)
 
                 UNLESS skiptag=0 LOOP

                 // Only process $<tag and $$tag if not skipping
 
                 // $$tag  complements the value of a tag
                 IF k='$' DO
                 $( h1!wordnode := symb=s_true -> s_false, s_true
                    LOOP
                 $)
 
                 // $<tag
                 IF symb=s_true LOOP      // Don't skip if set

                 // tag is false so skip until matching $>tag or EOF
                 skiptag := wordnode
                 UNTIL skiptag=0 | symb=s_end DO lex()
                 skiptag := 0
                 RETURN
              $)
 
              UNLESS ch='(' | ch=')' DO synerr("'$' out of context")
              symb := ch='(' -> s_lsect, s_rsect
              lookupword(rdtag('$'))
              RETURN
 
         CASE '{': symb, wordnode := s_lsect, nulltag; BREAK
         CASE '}': symb, wordnode := s_rsect, nulltag; BREAK

         CASE '#':
              symb := s_number
              rch()
              IF '0'<=ch<='7'    DO $(        readnumber(8);  RETURN  $)
              IF ch='b' | ch='B' DO $( rch(); readnumber(2);  RETURN  $)
              IF ch='o' | ch='O' DO $( rch(); readnumber(8);  RETURN  $)
              IF ch='x' | ch='X' DO $( rch(); readnumber(16); RETURN  $)
              symb := s_mthap
              RETURN
 
         CASE '[':
         CASE '(': symb := s_lparen;    BREAK
         CASE ']':
         CASE ')': symb := s_rparen;    BREAK 
         CASE '?': symb := s_query;     BREAK
         CASE '+': symb := s_plus;      BREAK
         CASE ',': symb := s_comma;     BREAK
         CASE ';': symb := s_semicolon; BREAK
         CASE '@': symb := s_lv;        BREAK
         CASE '&': symb := s_logand;    BREAK
         CASE '|': symb := s_logor;     BREAK
         CASE '=': symb := s_eq;        BREAK
         CASE '!': symb := s_vecap;     BREAK
         CASE '%': symb := s_byteap;    BREAK
         CASE '**':symb := s_mult;      BREAK
 
         CASE '/':
              rch()
              IF ch='\' DO $( symb := s_logand; BREAK $)
              IF ch='/' DO
              $( rch() REPEATUNTIL ch='*n' | ch=endstreamch
                 LOOP
              $)
 
              IF ch='**' DO
              {  LET depth = 1

                 {  rch()
                    IF ch='**' DO
                    {  rch() REPEATWHILE ch='**'
                       IF ch='/' DO {  depth := depth-1; LOOP }
                    }
                    IF ch='/' DO
                    {  rch()
                       IF ch='**' DO {  depth := depth+1; LOOP }
                    }
                    IF ch='*n' DO lineno := lineno+1
                    IF ch=endstreamch DO synerr("Missing '**/'")
                 } REPEATUNTIL depth=0

                 rch()
                 LOOP
              }

              symb := s_div
              RETURN
 
         CASE '~':
              rch()
              IF ch='=' DO $( symb := s_ne;     BREAK $)
              symb := s_not
              RETURN
 
         CASE '\':
              rch()
              IF ch='/' DO $( symb := s_logor;  BREAK $)
              IF ch='=' DO $( symb := s_ne;     BREAK $)
              symb := s_not
              RETURN
 
         CASE '<': rch()
              IF ch='=' DO $( symb := s_le;     BREAK $)
              IF ch='<' DO $( symb := s_lshift; BREAK $)
              symb := s_ls
              RETURN
 
         CASE '>': rch()
              IF ch='=' DO $( symb := s_ge;     BREAK $)
              IF ch='>' DO $( symb := s_rshift; BREAK $)
              symb := s_gr
              RETURN
 
         CASE '-': rch()
              IF ch='>' DO $( symb := s_cond; BREAK  $)
              symb := s_minus
              RETURN
 
         CASE ':': rch()
              IF ch='=' DO $( symb := s_ass; BREAK  $)
              symb := s_colon
              RETURN
 
         CASE '"':
           $( LET len = 0
              rch()
 
              UNTIL ch='"' DO
              $( IF len=255 DO synerr("Bad string constant")
                 len := len + 1
                 charv%len := rdstrch()
              $)
 
              charv%0 := len
              wordnode := newvec(len/bytesperword+2)
              h1!wordnode := s_string
              FOR i = 0 TO len DO (@h2!wordnode)%i := charv%i
              symb := s_string
              BREAK
           $)
 
         CASE '*'':
              rch()
              decval := rdstrch()
              symb := s_number
              UNLESS ch='*'' DO synerr("Bad character constant")
              BREAK
 
 
         DEFAULT:
              UNLESS ch=endstreamch DO
              $( LET badch = ch
                 ch := '*s'
                 synerr("Illegal character %x2", badch)
              $)

         CASE '.':
              IF getstreams=0 DO $( symb := s_end
                                    IF ch='.' DO rch()
                                    RETURN
                                 $)
              endread()
              ch           := h4!getstreams
              lineno       := h3!getstreams
              sourcestream := h2!getstreams
              getstreams   := h1!getstreams
              selectinput(sourcestream)
              LOOP
      $)
   $) REPEAT
 
   rch()
$)
 
LET lookupword(word) = VALOF
$( LET len, i = word%0, 0
   LET hashval = 19609 // This and 31397 are primes.
   FOR i = 0 TO len DO hashval := (hashval NEQV word%i) * 31397
   hashval := (hashval>>1) REM nametablesize

   wordnode := nametable!hashval
 
   UNTIL wordnode=0 | i>len TEST (@h3!wordnode)%i=word%i
                            THEN i := i+1
                            ELSE wordnode, i := h2!wordnode, 0
 
   IF wordnode=0 DO
   $( wordnode := newvec(len/bytesperword+3)
      h1!wordnode, h2!wordnode := s_name, nametable!hashval
      FOR i = 0 TO len DO (@h3!wordnode)%i := word%i
      nametable!hashval := wordnode
   $)
 
   RESULTIS h1!wordnode
$)
 
AND dsw(word, sym) BE $( lookupword(word); h1!wordnode := sym  $)
 
AND declsyswords() BE
$( dsw("AND", s_and)
   dsw("ABS", s_abs)
   dsw("BE", s_be)
   dsw("BREAK", s_break)
   dsw("BY", s_by)
   dsw("CASE", s_case)
   dsw("DO", s_do)
   dsw("DEFAULT", s_default)
   dsw("EQ", s_eq)
   dsw("EQV", s_eqv)
   dsw("ELSE", s_else)
   dsw("ENDCASE", s_endcase)
   dsw("FALSE", s_false)
   dsw("FOR", s_for)
   dsw("FINISH", s_finish)
   dsw("GOTO", s_goto)
   dsw("GE", s_ge)
   dsw("GR", s_gr)
   dsw("GLOBAL", s_global)
   dsw("GET", s_get)
   dsw("IF", s_if)
   dsw("INTO", s_into)
   dsw("LET", s_let)
   dsw("LV", s_lv)
   dsw("LE", s_le)
   dsw("LS", s_ls)
   dsw("LOGOR", s_logor)
   dsw("LOGAND", s_logand)
   dsw("LOOP", s_loop)
   dsw("LSHIFT", s_lshift)
   dsw("MANIFEST", s_manifest)
   dsw("NE", s_ne)
   dsw("NOT", s_not)
   dsw("NEQV", s_neqv)
   dsw("NEEDS", s_needs)
   dsw("OR", s_else)
   dsw("RESULTIS", s_resultis)
   dsw("RETURN", s_return)
   dsw("REM", s_rem)
   dsw("RSHIFT", s_rshift)
   dsw("RV", s_rv)
   dsw("REPEAT", s_repeat)
   dsw("REPEATWHILE", s_repeatwhile)
   dsw("REPEATUNTIL", s_repeatuntil)
   dsw("SWITCHON", s_switchon)
   dsw("STATIC", s_static)
   dsw("SECTION", s_section)
   dsw("TO", s_to)
   dsw("TEST", s_test)
   dsw("TRUE", s_true)
   dsw("THEN", s_do)
   dsw("TABLE", s_table)
   dsw("UNTIL", s_until)
   dsw("UNLESS", s_unless)
   dsw("VEC", s_vec)
   dsw("VALOF", s_valof)
   dsw("WHILE", s_while)
   dsw("$", 0)
 
   nulltag := wordnode
$) 
 
LET rch() BE
$( ch := rdch()
   chcount := chcount + 1
   chbuf%(chcount&63) := ch
$)
 
AND wrchbuf() BE
$( writes("*n...")
   FOR p = chcount-63 TO chcount DO
   $( LET k = chbuf%(p&63)
      IF 0<k<255 DO wrch(k)
   $)
   newline()
$)
 
 
AND rdtag(ch1) = VALOF
$( LET len = 1
   IF eqcases & 'a'<=ch1<='z' DO ch1 := ch1 + 'A' - 'a'
   charv%1 := ch1
 
   $( rch()
      UNLESS 'a'<=ch<='z' | 'A'<=ch<='Z' |
             '0'<=ch<='9' | ch='.' | ch='_' BREAK
      IF eqcases & 'a'<=ch<='z' DO ch := ch + 'A' - 'a'
      len := len+1
      charv%len := ch
   $) REPEAT
 
   charv%0 := len
   RESULTIS charv
$)
 
 
AND performget() BE
$( LET stream = ?
   lex()
   UNLESS symb=s_string DO synerr("Bad GET directive")
   stream := pathfindinput(charv, "BCPLPATH")
   TEST stream=0
   THEN synerr("Unable to find GET file %s", charv)
   ELSE $( getstreams := list4(getstreams, sourcestream, lineno, ch)
           sourcestream := stream
           selectinput(sourcestream)
           lineno := 1
           rch()
        $)
$)
 
AND readnumber(radix) BE
$( LET d = value(ch)
   decval := d
   IF d>=radix DO synerr("Bad number")
 
   $( rch()
      IF ch='_' LOOP
      d := value(ch)
      IF d>=radix RETURN
      decval := radix*decval + d
   $) REPEAT
$)
 
 
AND value(ch) = '0'<=ch<='9' -> ch-'0',
                'A'<=ch<='F' -> ch-'A'+10,
                'a'<=ch<='f' -> ch-'a'+10,
                100
 
AND rdstrch() = VALOF
$( LET k = ch

   IF k='*n' | k='*p' DO
   $( lineno := lineno+1
      synerr("Unescaped newline character")
   $)
 
   IF k='**' DO
   $( rch()
      k := ch
      IF 'a'<=k<='z' DO k := k + 'A' - 'a'
      SWITCHON k INTO
      $( CASE '*n':
         CASE '*p':
         CASE '*s':
         CASE '*t': WHILE ch='*n' | ch='*p' | ch='*s' | ch='*t' DO
                    $( IF ch='*n' | ch='*p' DO lineno := lineno+1
                       rch()
                    $)
                    IF ch='**' DO $( rch(); LOOP  $)

         DEFAULT:   synerr("Bad string or character constant")
         
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
         
         CASE 'X':  RESULTIS readoctalorhex(16,2)
         
         CASE '0':CASE '1':CASE '2':CASE '3':CASE '4':
         CASE '5':CASE '6':CASE '7':CASE '8':CASE '9':
                    k:=value(ch)*64+readoctalorhex(8,2)
                    IF k>255 DO 
                       synerr("Bad string or character constant")
                    RESULTIS k
      $)
   $)
   
   rch()
   RESULTIS k
$) REPEAT
 
 
AND readoctalorhex(radix, digits) = VALOF
$( LET answer, dig = 0, ?
   FOR j = 1 TO digits DO
   $( rch()
      dig := value(ch)
      IF dig > radix DO synerr("Bad string or character constant")
      answer:=answer*radix + dig
   $)
   rch()
   RESULTIS answer
$)

LET newvec(n) = VALOF
$( treep := treep - n - 1;
   IF treep<=treevec DO
   $( errmax := 0  // Make it fatal
      synerr("More workspace needed")
   $)
   RESULTIS treep
$)
 
AND list1(x) = VALOF
$( LET p = newvec(0)
   p!0 := x
   RESULTIS p
$)
 
AND list2(x, y) = VALOF
$( LET p = newvec(1)
   p!0, p!1 := x, y
   RESULTIS p
$)
 
AND list3(x, y, z) = VALOF
$( LET p = newvec(2)
   p!0, p!1, p!2 := x, y, z
   RESULTIS p
$)
 
AND list4(x, y, z, t) = VALOF
$( LET p = newvec(3)
   p!0, p!1, p!2, p!3 := x, y, z, t
   RESULTIS p
$)
 
AND list5(x, y, z, t, u) = VALOF
$( LET p = newvec(4)
   p!0, p!1, p!2, p!3, p!4 := x, y, z, t, u
   RESULTIS p
$)
 
AND list6(x, y, z, t, u, v) = VALOF
$( LET p = newvec(5)
   p!0, p!1, p!2, p!3, p!4, p!5 := x, y, z, t, u, v
   RESULTIS p
$)
 
AND list7(x, y, z, t, u, v, w) = VALOF
$( LET p = newvec(6)
   p!0, p!1, p!2, p!3, p!4, p!5, p!6 := x, y, z, t, u, v, w
   RESULTIS p
$)
 
AND formtree() =  VALOF
$( LET res = 0

   nametablesize := 541

   getstreams := 0
   charv      := newvec(256/bytesperword)     
   nametable  := newvec(nametablesize) 
   FOR i = 0 TO nametablesize DO nametable!i := 0
   skiptag := 0
   declsyswords()
 
   rec_p, rec_l := level(), rec
 
   lex()

   IF symb=s_query DO            // For debugging lex.
   $( lex()
      IF symb=s_end RESULTIS 0
      writef("symb =%i3  decval = %i8   charv = %s*n",
              symb,      decval,        charv)
   $) REPEAT

rec:res := symb=s_section -> rprog(s_section),
           symb=s_needs   -> rprog(s_needs), rdblockbody(TRUE)
   UNLESS symb=s_end DO synerr("Incorrect termination")
 
   RESULTIS res
$)
 
AND rprog(thing) = VALOF
$( LET a = 0
   lex()
   a := rbexp()
   UNLESS h1!a=s_string THEN synerr("Bad SECTION or NEEDS name")
   RESULTIS list3(thing, a,
                  symb=s_needs -> rprog(s_needs),rdblockbody(TRUE))
$)
 
 
AND synerr(mess, a) BE
$( errcount := errcount + 1
   writef("*nError near line %n:  ", lineno)
   writef(mess, a)
   wrchbuf()
   IF errcount > errmax DO
   $( writes("*nCompilation aborted*n")
      longjump(fin_p, fin_l)
   $)
   nlpending := FALSE
 
   UNTIL symb=s_lsect | symb=s_rsect |
         symb=s_let | symb=s_and |
         symb=s_end | nlpending DO lex()

   IF symb=s_and DO symb := s_let
   longjump(rec_p, rec_l)
$)
 
LET rdblockbody(outerlevel) = VALOF
$( LET p, l = rec_p, rec_l
   LET a, ln = 0, ?
 
   rec_p, rec_l := level(), recover

recover:  
   IF symb=s_semicolon DO lex()
 
   ln := lineno
   
   SWITCHON symb INTO
   $( CASE s_manifest:
      CASE s_static:
      CASE s_global:
              $(  LET op = symb
                  lex()
                  a := rdsect(rdcdefs, op=s_global->s_colon,s_eq)
                  a := list4(op, a, rdblockbody(outerlevel), ln)
                  ENDCASE
              $)
 
 
      CASE s_let: lex()
                  a := rdef(outerlevel)
                  WHILE symb=s_and DO
                  $( LET ln1 = lineno
                     lex()
                     a := list4(s_and, a, rdef(outerlevel), ln1)
                  $)
                  a := list4(s_let, a, rdblockbody(outerlevel), ln)
                  ENDCASE
 
      DEFAULT:    IF outerlevel DO
                  $( errmax := 0 // Make it fatal.
                     synerr("Bad outer level declaration")
                  $)
                  a := rdseq()
                  UNLESS symb=s_rsect DO synerr("Error in command")
 
      CASE s_rsect:IF outerlevel DO lex()
      CASE s_end:
   $)
 
   rec_p, rec_l := p, l
   RESULTIS a
$)
 
AND rdseq() = VALOF
$( LET a = 0
   IF symb=s_semicolon DO lex()
   a := rcom()
   IF symb=s_rsect | symb=s_end RESULTIS a
   RESULTIS list3(s_seq, a, rdseq())
$)

AND rdcdefs(sep) = VALOF
$( LET res, id = 0, 0
   LET ptr = @res
   LET p, l = rec_p, rec_l
   LET kexp = 0
   rec_p, rec_l := level(), recov
 
   $( kexp := 0
      id := rname()
      IF symb=sep DO kexp := rnexp(0)
      !ptr := list4(s_constdef, 0, id, kexp)
      ptr := @h2!(!ptr)

recov:IF symb=s_semicolon DO lex()
   $) REPEATWHILE symb=s_name
 
   rec_p, rec_l := p, l
   RESULTIS res
$)
 
AND rdsect(r, arg) = VALOF
$( LET tag, res = wordnode, 0
   UNLESS symb=s_lsect DO synerr("'$(' or '{' expected")
   lex()
   res := r(arg)
   UNLESS symb=s_rsect DO synerr("'$)' or '}' expected")
   TEST tag=wordnode THEN lex()
                     ELSE IF wordnode=nulltag DO
                          $( symb := 0
                             synerr("Untagged '$)' mismatch")
                          $)
   RESULTIS res
$)

AND rnamelist() = VALOF
$( LET a = rname()
   UNLESS symb=s_comma RESULTIS a
   lex()
   RESULTIS list3(s_comma, a, rnamelist())
$)

AND rname() = VALOF
$( LET a = wordnode
   UNLESS symb=s_name DO synerr("Name expected")
   lex()
   RESULTIS a
$)
 
LET rbexp() = VALOF
$( LET a, op = 0, symb
 
   SWITCHON symb INTO
 
   $( DEFAULT: synerr("Error in expression")

      CASE s_query:  lex()
                     RESULTIS list1(s_query)
 
      CASE s_true:
      CASE s_false:
      CASE s_name:
      CASE s_string: a := wordnode
                     lex()
                     RESULTIS a
 
      CASE s_number: a := list2(s_number, decval)
                     lex()
                     RESULTIS a
 
      CASE s_lparen: a := rnexp(0)
                     UNLESS symb=s_rparen DO synerr("')' missing")
                     lex()
                     RESULTIS a
 
      CASE s_valof:  lex()
                     RESULTIS list2(s_valof, rcom())
 
      CASE s_vecap:  op := s_rv
      CASE s_lv:
      CASE s_rv:     RESULTIS list2(op, rnexp(7))
 
      CASE s_plus:   RESULTIS rnexp(5)
 
      CASE s_minus:  a := rnexp(5)
                     TEST h1!a=s_number THEN h2!a := - h2!a
                                        ELSE a := list2(s_neg, a)
                     RESULTIS a
 
      CASE s_abs:    RESULTIS list2(s_abs, rnexp(5))
 
      CASE s_not:    RESULTIS list2(s_not, rnexp(3))
 
      CASE s_table:  lex()
                     RESULTIS list2(s_table, rexplist())
  $)
$)
 
AND rnexp(n) = VALOF $( lex(); RESULTIS rexp(n) $)
 
AND rexp(n) = VALOF
$( LET a, b, p = rbexp(), 0, 0

   UNTIL nlpending DO 
   $( LET op = symb
 
      SWITCHON op INTO
 
      $( DEFAULT:       RESULTIS a
 
         CASE s_lparen: lex()
                        b := 0
                        UNLESS symb=s_rparen DO b := rexplist()
                        UNLESS symb=s_rparen DO synerr("')' missing")
                        lex()
                        a := list4(s_fnap, a, b, 0)
                        LOOP
 
         CASE s_mthap:$( LET e1 = 0
                         lex()
                         UNLESS symb=s_lparen DO synerr("'(' missing")
                         lex()
                         b := 0
                         UNLESS symb=s_rparen DO b := rexplist()
                         IF b=0 DO synerr("argument expression missing")
                         UNLESS symb=s_rparen DO synerr("')' missing")
                         lex()
                         TEST h1!b=s_comma
                         THEN e1 := h2!b
                         ELSE e1 := b
                         a := list3(s_vecap, list2(s_rv, e1), a)
                         a := list4(s_fnap, a, b, 0)
                         LOOP
                      $)
 
         CASE s_vecap:  p := 8; ENDCASE
         CASE s_byteap: p := 8; ENDCASE // Changed from 7 on 16 Dec 1999
         CASE s_mult:
         CASE s_div:
         CASE s_rem:    p := 6; ENDCASE
         CASE s_plus:
         CASE s_minus:  p := 5; ENDCASE
 
         CASE s_eq:CASE s_le:CASE s_ls:
         CASE s_ne:CASE s_ge:CASE s_gr:
                        IF n>=4 RESULTIS a
                        b := rnexp(4)
                        a := list3(op, a, b)
                        WHILE  s_eq<=symb<=s_ge DO
                        $( LET c = b
                           op := symb
                           b := rnexp(4)
                           a := list3(s_logand, a, list3(op, c, b))
                        $)
                        LOOP
 
         CASE s_lshift:
         CASE s_rshift: IF n>=4 RESULTIS a
                        a := list3(op, a, rnexp(4))
                        LOOP

         CASE s_logand: p := 3; ENDCASE
         CASE s_logor:  p := 2; ENDCASE
         CASE s_eqv:
         CASE s_neqv:   p := 1; ENDCASE
 
         CASE s_cond:   IF n>=1 RESULTIS a
                        b := rnexp(0)
                        UNLESS symb=s_comma DO
                               synerr("Bad conditional expression")
                        a := list4(s_cond, a, b, rnexp(0))
                        LOOP
      $)
      
      IF n>=p RESULTIS a
      a := list3(op, a, rnexp(p))
   $)
   
   RESULTIS a
$)
 
LET rexplist() = VALOF
$( LET res, a = 0, rexp(0)
   LET ptr = @res
 
   WHILE symb=s_comma DO $( !ptr := list3(s_comma, a, 0)
                            ptr := @h3!(!ptr)
                            a := rnexp(0)
                         $)
   !ptr := a
   RESULTIS res
$)
 
LET rdef(outerlevel) = VALOF
$( LET n = rnamelist()
 
   SWITCHON symb INTO
 
   $( CASE s_lparen:
        $( LET a = 0
           lex()
           UNLESS h1!n=s_name DO synerr("Bad formal parameter")
           IF symb=s_name DO a := rnamelist()
           UNLESS symb=s_rparen DO synerr("')' missing")
           lex()
 
           IF symb=s_be DO
           $( lex()
              RESULTIS list5(s_rtdef, n, a, rcom(), 0)
           $)
 
           IF symb=s_eq RESULTIS list5(s_fndef, n, a, rnexp(0), 0)
 
           synerr("Bad procedure heading")
        $)
 
      DEFAULT: synerr("Bad declaration")
 
      CASE s_eq:
           IF outerlevel DO synerr("Bad outer level declaration")
           lex()
           IF symb=s_vec DO
           $( UNLESS h1!n=s_name DO synerr("Name required before = VEC")
              RESULTIS list3(s_vecdef, n, rnexp(0))
           $)
           RESULTIS list3(s_valdef, n, rexplist())
   $)
$)
 
LET rbcom() = VALOF
$( LET a, b, op, ln = 0, 0, symb, lineno
 
   SWITCHON symb INTO
   $( DEFAULT: RESULTIS 0
 
      CASE s_name:CASE s_number:CASE s_string:CASE s_lparen:
      CASE s_true:CASE s_false:CASE s_lv:CASE s_rv:CASE s_vecap:
      CASE s_plus:CASE s_minus:CASE s_abs:CASE s_not:
      CASE s_table:CASE s_valof:CASE s_query:
      // All tokens that can start an expression.
            a := rexplist()
 
            IF symb=s_ass DO
            $( op := symb
               lex()
               RESULTIS list4(op, a, rexplist(), ln)
            $)
 
            IF symb=s_colon DO
            $( UNLESS h1!a=s_name DO synerr("Unexpected ':'")
               lex()
               RESULTIS list5(s_colon, a, rbcom(), 0, ln)
            $)
 
            IF h1!a=s_fnap DO
            $( h1!a, h4!a := s_rtap, ln
               RESULTIS a
            $)
 
            synerr("Error in command")
            RESULTIS a
 
      CASE s_goto:
      CASE s_resultis:
            RESULTIS list3(op, rnexp(0), ln)
 
      CASE s_if:
      CASE s_unless:
      CASE s_while:
      CASE s_until:
            a := rnexp(0)
            IF symb=s_do DO lex()
            RESULTIS list4(op, a, rcom(), ln)
 
      CASE s_test:
            a := rnexp(0)
            IF symb=s_do DO lex()
            b := rcom()
            UNLESS symb=s_else DO synerr("ELSE missing")
            lex()
            RESULTIS list5(s_test, a, b, rcom(), ln)
 
      CASE s_for:
         $( LET i, j, k = 0, 0, 0
            lex()
            a := rname()
            UNLESS symb=s_eq DO synerr("'=' missing")
            i := rnexp(0)
            UNLESS symb=s_to DO synerr("TO missing")
            j := rnexp(0)
            IF symb=s_by DO k := rnexp(0)
            IF symb=s_do DO lex()
            RESULTIS list7(s_for, a, i, j, k, rcom(), ln)
         $)
 
      CASE s_loop:
      CASE s_break:
      CASE s_return:
      CASE s_finish:
      CASE s_endcase:
            lex()
            RESULTIS list2(op, ln)
 
      CASE s_switchon:
            a := rnexp(0)
            UNLESS symb=s_into DO synerr("INTO missing")
            lex()
            RESULTIS list4(s_switchon, a, rdsect(rdseq), ln)
 
      CASE s_case:
            a := rnexp(0)
            UNLESS symb=s_colon DO synerr("Bad CASE label")
            lex()
            RESULTIS list4(s_case, a, rbcom(), ln)
 
      CASE s_default:
            lex()
            UNLESS symb=s_colon DO synerr("Bad DEFAULT label")
            lex()
            RESULTIS list3(s_default, rbcom(), ln)
 
      CASE s_lsect:
            RESULTIS rdsect(rdblockbody, FALSE)
   $)
$)

AND rcom() = VALOF
$( LET a = rbcom()
 
   IF a=0 DO synerr("Error in command")
 
   WHILE symb=s_repeat | symb=s_repeatwhile | symb=s_repeatuntil DO
   $( LET op, ln = symb, lineno
      UNLESS op=s_repeat $( a := list4(op, a, rnexp(0), ln); LOOP $)
      a := list3(op, a, ln)
      lex()
   $)
 
   RESULTIS a
$)
/*
LET plist(x) BE
$( writef("*nName table contents, size = %n*n", nametablesize)
   FOR i = 0 TO nametablesize-1 DO
   $( LET p, n = nametable!i, 0
      UNTIL p=0 DO p, n := p!1, n+1
      writef("%i3:%n", i, n)
      p := nametable!i
      UNTIL p=0 DO $( writef(" %s", p+2); p := p!1  $)
      newline()
   $)
$)
*/
LET plist(x, n, d) BE
$( LET size, ln = 0, 0
   LET v = TABLE 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

   IF x=0 DO $( writes("Nil"); RETURN  $)
 
   SWITCHON h1!x INTO
   $( CASE s_number: writen(h2!x);         RETURN
 
      CASE s_name:   writes(x+2);          RETURN
 
      CASE s_string: writef("*"%s*"",x+1); RETURN
 
      CASE s_for:    size, ln := 6, h7!x;  ENDCASE
 
      CASE s_cond:CASE s_fndef:CASE s_rtdef:CASE s_constdef:
                     size := 4;            ENDCASE
 
      CASE s_test:
                     size, ln := 4, h5!x;  ENDCASE
 
      CASE s_needs:CASE s_section:CASE s_vecap:CASE s_byteap:CASE s_fnap:
      CASE s_mult:CASE s_div:CASE s_rem:CASE s_plus:CASE s_minus:
      CASE s_eq:CASE s_ne:CASE s_ls:CASE s_gr:CASE s_le:CASE s_ge:
      CASE s_lshift:CASE s_rshift:CASE s_logand:CASE s_logor:
      CASE s_eqv:CASE s_neqv:CASE s_comma:
      CASE s_valdef:CASE s_vecdef:
      CASE s_seq:
                     size := 3;            ENDCASE
                     
      CASE s_colon:
                     size, ln := 3, h5!x;  ENDCASE
 
      CASE s_and:
      CASE s_ass:CASE s_rtap:CASE s_if:CASE s_unless:
      CASE s_while:CASE s_until:CASE s_repeatwhile:
      CASE s_repeatuntil:
      CASE s_switchon:CASE s_case:CASE s_let:
      CASE s_manifest:CASE s_static:CASE s_global:
                     size, ln := 3, h4!x;  ENDCASE
 
      CASE s_valof:CASE s_lv:CASE s_rv:CASE s_neg:CASE s_not:
      CASE s_table:CASE s_abs:
                     size := 2;            ENDCASE
 
      CASE s_goto:CASE s_resultis:CASE s_repeat:CASE s_default:
                     size, ln := 2, h3!x;  ENDCASE
 
      CASE s_true:CASE s_false:CASE s_query:
                     size := 1;            ENDCASE
      
      CASE s_loop:CASE s_break:CASE s_return:
      CASE s_finish:CASE s_endcase:
                     size, ln := 1, h2!x;  ENDCASE

      DEFAULT:       size := 1
   $)
 
   IF n=d DO $( writes("Etc"); RETURN $)
 
   writef("Op %n", h1!x)
   IF ln>0 DO writef("  line %n", ln)
   FOR i = 2 TO size DO $( newline()
                           FOR j=0 TO n-1 DO writes( v!j )
                           writes("**-")
                           v!n := i=size->"  ","! "
                           plist(h1!(x+i-1), n+1, d)
                        $)
$)
 
.
SECTION "TRN"

//    TRNHDR
 
GET "libhdr"
 
MANIFEST $(   // Parse tree operators
s_number=1; s_name=2; s_string=3; s_true=4; s_false=5
s_valof=6; s_lv=7; s_rv=8; s_vecap=9; s_fnap=10
s_mult=11; s_div=12; s_rem=13; s_plus=14; s_minus=15
s_query=16; s_neg=17; s_abs=19
s_eq=20; s_ne=21; s_ls=22; s_gr=23; s_le=24; s_ge=25
s_byteap = 28
s_not=30; s_lshift=31; s_rshift=32; s_logand=33; s_logor=34
s_eqv=35; s_neqv=36; s_cond=37; s_comma=38; s_table=39
s_and=40; s_valdef=41; s_vecdef=42; s_constdef=43
s_fndef=44; s_rtdef=45; s_needs=48; s_section=49
s_ass=50; s_rtap=51; s_goto=52; s_resultis=53; s_colon=54
s_test=55; s_for=56; s_if=57; s_unless=58
s_while=59; s_until=60; s_repeat=61; s_repeatwhile=62
s_repeatuntil=63
s_loop=65; s_break=66; s_return=67; s_finish=68; s_endcase=69
s_switchon=70; s_case=71; s_default=72
s_seq=73; s_let=74; s_manifest=75; s_global=76
s_local=77; s_label=78; s_static=79
$)

MANIFEST $(    //  Selectors
h1=0; h2=1; h3=2; h4=3; h5=4; h6=5; h7=6
$)

MANIFEST $(
s_lf=39; s_lp=40; s_lg=41; s_ln=42; s_lstr=43
s_ll=44; s_llp=45; s_llg=46; s_lll=47 
s_sp=80; s_sg=81; s_sl=82; s_stind=83
s_jump=85; s_jt=86; s_jf=87; s_endfor=88
s_lab=90; s_stack=91; s_store=92; s_rstack=93; s_entry=94
s_save=95; s_fnrn=96; s_rtrn=97; s_res=98
s_datalab=100; s_itemn=102
s_endproc=103; s_getbyte=120; s_putbyte=121
$)

GLOBAL  $(
wrn:212  
nametable:248; nametablesize:249
fin_p:237; fin_l:238; plist:252; treep:269; treevec:270
 
errcount:291; errmax:292; sysprint:294
 
trnext:300; trans:301; declnames:302; decldyn:303
declstat:304; checkdistinct:305; addname:306; cellwithname:307
transdef:308; scanlabel:309
decllabels:310; undeclare:311; trnerr:312
jumpcond:320; transswitch:321; transfor:322
assign:330; load:331; fnbody:332; loadlv:333; loadlist:334
isconst:335; evalconst:336; transname:337
nextlab:343; labnumber:344; translate:345; newblk:346
dvec:360; dvece:361; dvecp:362; dvect:363
caselist:365; casecount:366; comline:370; procname:371
resultlab:372; defaultlab:373; endcaselab:374
looplab:375; breaklab:376; ssp:380; vecssp:381; savespacesize:382
gdeflist:385; gdefcount:386
outstring:389; out1:390; out2:391
$)

LET nextlab() = VALOF
$( labnumber := labnumber + 1
   RESULTIS labnumber
$)
 
AND trnerr(mess, a) BE
$( writes("Error ")
   UNLESS procname=0 DO writef("in %s ", @h3!procname)
   writef("near line %n:    ", comline)
   writef(mess, a)
   newline()
   errcount := errcount + 1
   IF errcount >= errmax DO $( writes("*nCompilation aborted*n")
                               longjump(fin_p, fin_l)
                            $)
$)

AND newblk(x, y, z) = VALOF
$( LET p = dvect - 3
   IF dvece>p DO $( errmax := 0        // Make it fatal.
                    trnerr("More workspace needed")
                 $)
   p!0, p!1, p!2 := x, y, z
   dvect := p
   RESULTIS p
$)

AND translate(x) BE
$( dvec,  dvect := treevec, treep
   h1!dvec, h2!dvec, h3!dvec := 0, 0, 0
   dvece := dvec+3
   dvecp := dvece

   FOR i = 0 TO nametablesize-1 DO
   $( LET name = nametable!i
      UNTIL name=0 DO
      $( LET next = h2!name
         h2!name := 0 // Mark undeclared
//   writef("Undeclare %s*n", name+2)
         name := next
      $)
   $)

   gdeflist, gdefcount := 0, 0
   caselist, casecount, defaultlab := 0, -1, 0
   resultlab, breaklab, looplab, endcaselab := -2, -2, -2, -2
   comline, procname, labnumber := 1, 0, 0
   ssp, vecssp := savespacesize, savespacesize

   WHILE x~=0 & (h1!x=s_section | h1!x=s_needs) DO
   $( LET op, a = h1!x, h2!x
      out1(op)
      outstring(@h2!a)
      x:=h3!x
   $)

   trans(x, 0)
   out2(s_global, gdefcount)
   UNTIL gdeflist=0 DO $( out2(h2!gdeflist, h3!gdeflist)
                          gdeflist := h1!gdeflist
                       $)  
$)

LET trnext(next) BE $( IF next<0 DO out1(s_rtrn)
                       IF next>0 DO out2(s_jump, next)
                    $)
 
LET trans(x, next) BE
// x       is the command to translate
// next<0  compile x followed by RTRN
// next>0  compile x followed by JUMP next
// next=0  compile x only
$( LET sw = FALSE
   IF x=0 DO $( trnext(next); RETURN $)
 
   SWITCHON h1!x INTO
   $( DEFAULT: trnerr("Compiler error in Trans"); RETURN
 
      CASE s_let:
      $( LET cc = casecount
         LET e, s, s1 = dvece, ssp, 0
         LET v = vecssp
         casecount := -1 // Disallow CASE and DEFAULT labels
         comline := h4!x
         declnames(h2!x)
         checkdistinct(e)
         vecssp, s1 := ssp, ssp
         ssp := s
         comline := h4!x
         transdef(h2!x)
         UNLESS ssp=s1 DO trnerr("Lhs and rhs do not match")
         UNLESS ssp=vecssp DO $( ssp := vecssp; out2(s_stack, ssp) $)
         out1(s_store)
         decllabels(h3!x)
         trans(h3!x, next)
         vecssp := v
         UNLESS ssp=s DO out2(s_stack, s)
         ssp := s
         casecount := cc
         undeclare(e)
         RETURN
      $)
 
      CASE s_static:
      CASE s_global:
      CASE s_manifest:
      $( LET cc = casecount
         LET e, s = dvece, ssp
         AND op = h1!x
         AND y = h2!x
         LET prevk = -1
         
         casecount := -1 // Disallow CASE and DEFAULT labels
         comline := h4!x
 
         UNTIL y=0 DO
         $( LET n = h4!y -> evalconst(h4!y), prevk+1
            prevk := n
            IF op=s_static DO $( LET k = n
                                 n := nextlab()
                                 out2(s_datalab, n)
                                 out2(s_itemn, k)
                              $)
            IF op=s_global UNLESS 0<=n<=65535 DO
               trnerr("Global number too large for: %s*n", @h3!(h3!y))
            addname(h3!y, op, n)
            y := h2!y
         $)
 
         decllabels(h3!x)
         trans(h3!x, next)
         ssp := s
         casecount := cc
         undeclare(e)
         RETURN
      $)
 
 
      CASE s_ass:
         comline := h4!x
         assign(h2!x, h3!x)
         trnext(next)
         RETURN
 
      CASE s_rtap:
      $( LET s = ssp
         comline := h4!x
         ssp := ssp+savespacesize
         out2(s_stack, ssp)
         loadlist(h3!x)
         load(h2!x)
         out2(s_rtap, s)
         ssp := s
         trnext(next)
         RETURN
      $)
 
      CASE s_goto:
         comline := h3!x
         load(h2!x)
         out1(s_goto)
         ssp := ssp-1
         RETURN
 
      CASE s_colon:
         comline := h5!x
         out2(s_lab, h4!x)
         trans(h3!x, next)
         RETURN
 
      CASE s_unless: sw := TRUE
      CASE s_if:
         comline := h4!x
         TEST next>0 THEN $( jumpcond(h2!x, sw, next)
                             trans(h3!x, next)
                          $)
                     ELSE $( LET l = nextlab()
                             jumpcond(h2!x, sw, l)
                             trans(h3!x, next)
                             out2(s_lab, l)
                             trnext(next)
                          $)
         RETURN
 
      CASE s_test:
      $( LET l, m = nextlab(), 0
         comline := h5!x
         jumpcond(h2!x, FALSE, l)
         
         TEST next=0 THEN $( m := nextlab(); trans(h3!x, m) $)
                     ELSE trans(h3!x, next)
                     
         out2(s_lab, l)
         trans(h4!x, next)
         UNLESS m=0 DO out2(s_lab, m)
         RETURN
      $)
 
      CASE s_loop:
         comline := h2!x
         IF looplab<0 DO trnerr("Illegal use of LOOP")
         IF looplab=0 DO looplab := nextlab()
         out2(s_jump, looplab)
         RETURN
 
      CASE s_break:
         comline := h2!x
         IF breaklab=-2 DO trnerr("Illegal use of BREAK")
         IF breaklab=-1 DO $( out1(s_rtrn); RETURN $)
         IF breaklab= 0 DO breaklab := nextlab()
         out2(s_jump, breaklab)
         RETURN
 
      CASE s_return:
         comline := h2!x
         out1(s_rtrn)
         RETURN
 
      CASE s_finish:
         comline := h2!x
         out1(s_finish)
         RETURN
 
      CASE s_resultis:
         comline := h3!x
         IF resultlab=-1 DO $( fnbody(h2!x); RETURN $)
         UNLESS resultlab>0 DO trnerr("RESULTIS out of context")
         load(h2!x)
         out2(s_res, resultlab)
         ssp := ssp - 1
         RETURN
 
      CASE s_while: sw := TRUE
      CASE s_until:
      $( LET l, m = nextlab(), next
         LET bl, ll = breaklab, looplab
         comline := h4!x
         breaklab, looplab := next, 0
         IF next<=0 DO m := nextlab()
         IF next =0 DO breaklab := m
         jumpcond(h2!x, ~sw, m)
         out2(s_lab, l)
         trans(h3!x, 0)
         UNLESS looplab=0 DO out2(s_lab, looplab)
         comline := h4!x
         jumpcond(h2!x, sw, l)
         IF next<=0 DO out2(s_lab, m)
         trnext(next)
         breaklab, looplab := bl, ll
         RETURN
      $)
 
      CASE s_repeatwhile: sw := TRUE
      CASE s_repeatuntil:
      $( LET l, bl, ll = nextlab(), breaklab, looplab
         comline := h4!x
         breaklab, looplab := next, 0
         out2(s_lab, l)
         trans(h2!x, 0)
         UNLESS looplab=0 DO out2(s_lab, looplab)
         comline := h4!x
         jumpcond(h3!x, sw, l)

//       UNLESS breaklab=0 DO out2(s_lab, breaklab)
         IF next=0 & breaklab>0 DO out2(s_lab, breaklab)

         trnext(next)
         breaklab, looplab := bl, ll
         RETURN
      $)
 
      CASE s_repeat:
      $( LET bl, ll = breaklab, looplab
         comline := h4!x
         breaklab, looplab := next, nextlab()
         out2(s_lab, looplab)

         trans(h2!x, looplab)

         IF next=0 & breaklab>0 DO out2(s_lab, breaklab)

         breaklab, looplab := bl, ll
         RETURN
      $)
 
      CASE s_case:
      $( LET l, k, cl = nextlab(), ?, caselist
         comline := h4!x
         k := evalconst(h2!x)
         IF casecount<0 DO trnerr("CASE label out of context")
         UNTIL cl=0 DO
         $( IF h2!cl=k DO trnerr("'CASE %n:' occurs twice", k)
            cl := h1!cl
         $)
         caselist := newblk(caselist, k, l)
         casecount := casecount + 1
         out2(s_lab, l)
         trans(h3!x, next)
         RETURN
      $)
 
      CASE s_default:
         comline := h3!x
         IF casecount<0 | defaultlab~=0 DO trnerr("Bad DEFAULT label")
         defaultlab := nextlab()
         out2(s_lab, defaultlab)
         trans(h2!x, next)
         RETURN
 
      CASE s_endcase:
         comline := h2!x
         IF endcaselab=-2 DO trnerr("Illegal use of ENDCASE")
         IF endcaselab=-1 DO out1(s_rtrn)
         // endcaselab is never equal to 0
         IF endcaselab>0  DO out2(s_jump, endcaselab)
         RETURN
 
      CASE s_switchon:
         transswitch(x, next)
         RETURN
 
      CASE s_for:
         transfor(x, next)
         RETURN
 
      CASE s_seq:
         trans(h2!x, 0)
         x := h3!x
   $)
$) REPEAT

LET declnames(x) BE UNLESS x=0 SWITCHON h1!x INTO
 
$(  DEFAULT:       trnerr("Compiler error in Declnames")
                   RETURN
 
    CASE s_vecdef:
    CASE s_valdef: decldyn(h2!x)
                   RETURN
 
    CASE s_rtdef:
    CASE s_fndef:  h5!x := nextlab()
                   declstat(h2!x, h5!x)
                   RETURN
 
    CASE s_and:    declnames(h2!x)
                   comline := h4!x
                   declnames(h3!x)
$)
 
AND decldyn(x) BE UNLESS x=0 DO
 
$( IF h1!x=s_name  DO $( addname(x, s_local, ssp)
                         ssp := ssp + 1
                         RETURN
                      $)
 
   IF h1!x=s_comma DO $( addname(h2!x, s_local, ssp)
                         ssp := ssp + 1
                         decldyn(h3!x)
                         RETURN
                      $)
 
   trnerr("Compiler error in Decldyn")
$)
 
AND declstat(x, lab) BE
$( LET c = cellwithname(x)
 
   TEST h2!c=s_global THEN $( LET gn = h3!c
                              gdeflist := newblk(gdeflist, gn, lab)
                              gdefcount := gdefcount + 1
                              addname(x, s_global, gn)
                           $)
                      ELSE    addname(x, s_label, lab)
$)
 
AND decllabels(x) BE
$( LET e = dvece
   scanlabels(x)
   checkdistinct(e)
$)
 
AND checkdistinct(p) BE
$( LET lim = dvece - 3
   FOR q = p TO lim-3 BY 3 DO
   $( LET n = h1!q
      FOR c = q+3 TO lim BY 3 DO
          IF h1!c=n DO trnerr("Name %s defined twice", @h3!n)
   $)
$)
 
AND addname(name, k, a) BE
$( LET p = dvece + 3
   IF p>dvect DO trnerr("More workspace needed")
   h1!dvece, h2!dvece, h3!dvece := name, k, a
   h2!name := dvece // Remember the declaration
   dvece := p
$)
 
AND undeclare(e) BE 
$( FOR t = e TO dvece-3 BY 3 DO
   $( LET name = h1!t
      h2!name := 0   // Forget its declaration
   $)
   dvece := e
$)

AND cellwithname(n) = VALOF
$( LET t = h2!n
   UNLESS t=0 RESULTIS t  // It has been looked up before
   t := dvece
   t := t - 3 REPEATUNTIL h1!t=n | h1!t=0
   h2!n := t  // Associate the name with declaration item
   RESULTIS t
$)
 
AND scanlabels(x) BE UNLESS x=0 SWITCHON h1!x INTO
 
$( CASE s_colon:   comline := h5!x
                   h4!x := nextlab()
                   declstat(h2!x, h4!x)
 
   CASE s_if: CASE s_unless: CASE s_while: CASE s_until:
   CASE s_switchon: CASE s_case:
                   scanlabels(h3!x)
                   RETURN
 
   CASE s_seq:     scanlabels(h3!x)
 
   CASE s_repeat: CASE s_repeatwhile: CASE s_repeatuntil:
   CASE s_default: scanlabels(h2!x)
                   RETURN
 
   CASE s_test:    scanlabels(h3!x)
                   scanlabels(h4!x)
   DEFAULT:        RETURN
$)
 
AND transdef(x) BE
$( LET ln = comline
   transdyndefs(x)
   comline := ln
   IF statdefs(x) DO $( LET l, s= nextlab(), ssp
                        out2(s_jump, l)
                        transstatdefs(x)
                        ssp := s
                        out2(s_stack, ssp)
                        out2(s_lab, l)
                     $)
   comline := ln
$)
 
 
AND transdyndefs(x) BE SWITCHON h1!x INTO
$( CASE s_and:    transdyndefs(h2!x)
                  comline := h4!x
                  transdyndefs(h3!x)
                  RETURN
 
   CASE s_vecdef: out2(s_llp, vecssp)
                  ssp := ssp + 1
                  vecssp := vecssp + 1 + evalconst(h3!x)
                  RETURN
 
   CASE s_valdef: loadlist(h3!x)
 
   DEFAULT:       RETURN
$)
 
AND transstatdefs(x) BE SWITCHON h1!x INTO
$( CASE s_and:  transstatdefs(h2!x)
                comline := h4!x
                transstatdefs(h3!x)
                RETURN
 
   CASE s_fndef:
   CASE s_rtdef:
             $( LET e, p = dvece, dvecp
                AND oldpn = procname
                AND bl, ll = breaklab,  looplab
                AND rl, el = resultlab, endcaselab
                AND cl, cc = caselist,  casecount
                breaklab,  looplab    := -2, -2
                resultlab, endcaselab := -2, -2
                caselist,  casecount  :=  0, -1
                procname := h2!x

                out2(s_entry, h5!x)
                outstring(@h3!procname)
                ssp := savespacesize
                dvecp := dvece
                decldyn(h3!x)
                checkdistinct(e)
                decllabels(h4!x)
                out2(s_save, ssp)
                TEST h1!x=s_rtdef THEN trans(h4!x, -1)
                                  ELSE fnbody(h4!x)
                out1(s_endproc)
 
                breaklab,  looplab    := bl, ll
                resultlab, endcaselab := rl, el
                caselist,  casecount  := cl, cc
                procname := oldpn
                dvecp := p
                undeclare(e)
             $)
 
   DEFAULT:     RETURN
$)
 
AND statdefs(x) = h1!x=s_fndef | h1!x=s_rtdef -> TRUE,
                  h1!x ~= s_and               -> FALSE,
                  statdefs(h2!x)              -> TRUE,
                  statdefs(h3!x)
 
 
LET jumpcond(x, b, l) BE
$( LET sw = b

   SWITCHON h1!x INTO
   $( CASE s_false:  b := NOT b
      CASE s_true:   IF b DO out2(s_jump, l)
                     RETURN
 
      CASE s_not:    jumpcond(h2!x, NOT b, l)
                     RETURN
 
      CASE s_logand: sw := NOT sw
      CASE s_logor:  TEST sw THEN $( jumpcond(h2!x, b, l)
                                     jumpcond(h3!x, b, l)
                                     RETURN
                                  $)
 
                             ELSE $( LET m = nextlab()
                                     jumpcond(h2!x, NOT b, m)
                                     jumpcond(h3!x, b, l)
                                     out2(s_lab, m)
                                     RETURN
                                  $)
 
        DEFAULT:     load(x)
                     out2(b -> s_jt, s_jf, l)
                     ssp := ssp - 1
                     RETURN
   $)
$)
 
AND transswitch(x, next) BE
$( LET cl, cc = caselist, casecount 
   LET dl, el = defaultlab, endcaselab
   LET l, dlab = nextlab(), ?
   caselist, casecount, defaultlab := 0, 0, 0
   endcaselab := next=0 -> nextlab(), next
 
   comline := h4!x
   out2(s_jump, l)
   trans(h3!x, endcaselab)
 
   comline := h4!x
   out2(s_lab, l)
   load(h2!x)

   dlab := defaultlab>0 -> defaultlab,
           endcaselab>0 -> endcaselab,
           nextlab()

   out2(s_switchon, casecount); out1(dlab) 
   UNTIL caselist=0 DO $( out2(h2!caselist, h3!caselist)
                          caselist := h1!caselist
                       $)
   ssp := ssp - 1

   IF next=0                DO    out2(s_lab, endcaselab)
   IF next<0 & defaultlab=0 DO $( out2(s_lab, dlab)
                                  out1(s_rtrn)
                               $)

   defaultlab, endcaselab := dl, el
   caselist,   casecount  := cl, cc
$)
 
AND transfor(x, next) BE
$( LET e, m, blab = dvece, nextlab(), 0
   LET bl, ll = breaklab, looplab
   LET cc = casecount
   LET k, n, step = 0, 0, 1
   LET s = ssp

   casecount := -1  // Disallow CASE and DEFAULT labels.   
   breaklab, looplab := next, 0
   
   comline := h7!x
 
   addname(h2!x, s_local, s)
   load(h3!x)
 
   TEST h1!(h4!x)=s_number THEN    k, n := s_ln, h2!(h4!x)
                           ELSE $( k, n := s_lp, ssp
                                   load(h4!x)
                                $)
 
   UNLESS h5!x=0 DO step := evalconst(h5!x)
 
   out1(s_store)
   
   TEST k=s_ln & h1!(h3!x)=s_number  // check for constant limits 
   THEN $( LET initval = h2!(h3!x)
           IF step>=0 & initval>n | step<0 & initval<n DO
           $( TEST next<0
              THEN out1(s_rtrn)
              ELSE TEST next>0
                   THEN out2(s_jump, next)
                   ELSE $( blab := breaklab>0 -> breaklab, nextlab()
                           out2(s_jump, blab)
                        $)
           $)
        $)
   ELSE $( IF next<=0 DO blab := nextlab()
           out2(s_lp, s)
           out2(k, n)
           out1(step>=0 -> s_gr, s_ls)
           out2(s_jt, next>0 -> next, blab)
        $)

   IF breaklab=0 & blab>0 DO breaklab := blab
   
   comline := h7!x
   decllabels(h6!x)
   comline := h7!x
   out2(s_lab, m)
   trans(h6!x, 0)
   UNLESS looplab=0 DO out2(s_lab, looplab)
   out2(s_lp, s); out2(s_ln, step); out1(s_plus); out2(s_sp, s)
   out2(s_lp,s); out2(k,n); out1(step>=0 -> s_le, s_ge)
   out2(s_jt, m)
 
   IF next<=0 TEST blab>0 
              THEN                  out2(s_lab, blab)
              ELSE IF breaklab>0 DO out2(s_lab, breaklab)
   trnext(next)
   casecount := cc
   breaklab, looplab, ssp := bl, ll, s
   out2(s_stack, ssp)
   undeclare(e)
$)
 
LET load(x) BE
$( LET op = h1!x

   IF isconst(x) DO
   $( out2(s_ln, evalconst(x))
      ssp := ssp + 1
      RETURN
   $)
 
   SWITCHON op INTO
   $( DEFAULT:          trnerr("Compiler error in Load")
                        out2(s_ln, 0)
                        ssp := ssp + 1
                        RETURN
 
      CASE s_byteap:    op:=s_getbyte

      CASE s_div: CASE s_rem: CASE s_minus:
      CASE s_ls: CASE s_gr: CASE s_le: CASE s_ge:
      CASE s_lshift: CASE s_rshift:
                        load(h2!x); load(h3!x); out1(op)
                        ssp := ssp - 1
                        RETURN
 
      CASE s_vecap: CASE s_mult: CASE s_plus: CASE s_eq: CASE s_ne:
      CASE s_logand: CASE s_logor: CASE s_eqv: CASE s_neqv:
         $( LET a, b = h2!x, h3!x
            TEST h1!a=s_name |
                 h1!a=s_number THEN $( load(b); load(a) $)
                               ELSE $( load(a); load(b) $)
            TEST op=s_vecap THEN out2(s_plus, s_rv)
                            ELSE out1(op)
            ssp := ssp - 1
            RETURN
         $)
 
      CASE s_neg: CASE s_not: CASE s_rv: CASE s_abs:
                       load(h2!x)
                       out1(op)
                       RETURN
 
      CASE s_true: CASE s_false: CASE s_query:
                       out1(op)
                       ssp := ssp + 1
                       RETURN
 
      CASE s_lv:       loadlv(h2!x); RETURN
 
      CASE s_number:   out2(s_ln, h2!x); ssp := ssp + 1; RETURN
 
      CASE s_string:   out1(s_lstr)
                       outstring(@ h2!x)
                       ssp := ssp + 1
                       RETURN
 
      CASE s_name:     transname(x, s_lp, s_lg, s_ll, s_lf, s_ln)
                       ssp := ssp + 1
                       RETURN
 
      CASE s_valof: $( LET e, rl, cc = dvece, resultlab, casecount
                       casecount := -1 // Disallow CASE & DEFAULT labels
                       resultlab := nextlab()
                       decllabels(h2!x)
                       trans(h2!x, 0)
                       out2(s_lab, resultlab)
                       out2(s_rstack, ssp)
                       ssp := ssp + 1
                       resultlab, casecount := rl, cc
                       undeclare(e)
                       RETURN
                    $)
 
      CASE s_fnap:  $( LET s = ssp
                       ssp := ssp + savespacesize
                       out2(s_stack, ssp)
                       loadlist(h3!x)
                       load(h2!x)
                       out2(s_fnap, s)
                       ssp := s + 1
                       RETURN
                    $)
 
      CASE s_cond:  $( LET l, m = nextlab(), nextlab()
                       LET s = ssp
                       jumpcond(h2!x, FALSE, m)
                       load(h3!x)
                       out2(s_res,l)
                       ssp := s; out2(s_stack, ssp)
                       out2(s_lab, m)
                       load(h4!x)
                       out2(s_res,l)
                       out2(s_lab, l)
                       out2(s_rstack,s)
                       RETURN
                    $)
 
      CASE s_table: $( LET m = nextlab()
                       out2(s_datalab, m)
                       x := h2!x
                       WHILE h1!x=s_comma DO
                       $( out2(s_itemn, evalconst(h2!x))
                          x := h3!x
                       $)
                       out2(s_itemn, evalconst(x))
                       out2(s_lll, m)
                       ssp := ssp + 1
                       RETURN
                    $)
   $)
$)

AND fnbody(x) BE SWITCHON h1!x INTO
$( DEFAULT:         load(x)
                    out1(s_fnrn)
                    ssp := ssp - 1
                    RETURN
                   
   CASE s_valof: $( LET e, rl, cc = dvece, resultlab, casecount
                    casecount := -1 // Disallow CASE & DEFAULT labels
                    resultlab := -1
                    decllabels(h2!x)
                    trans(h2!x, -1)
                    resultlab, casecount := rl, cc
                    undeclare(e)
                    RETURN
                 $)

   CASE s_cond:  $( LET l = nextlab()
                    jumpcond(h2!x, FALSE, l)
                    fnbody(h3!x)
                    out2(s_lab, l)
                    fnbody(h4!x)
                 $)
$)
 
 
AND loadlv(x) BE
$( UNLESS x=0 SWITCHON h1!x INTO
   $( DEFAULT:         ENDCASE
 
      CASE s_name:     transname(x, s_llp, s_llg, s_lll, 0, 0)
                       ssp := ssp + 1
                       RETURN
 
      CASE s_rv:       load(h2!x)
                       RETURN
 
      CASE s_vecap: $( LET a, b = h2!x, h3!x
                       IF h1!a=s_name DO a, b := h3!x, h2!x
                       load(a)
                       load(b)
                       out1(s_plus)
                       ssp := ssp - 1
                       RETURN
                    $)
   $)

  trnerr("Ltype expression needed")
  out2(s_ln, 0)
  ssp := ssp + 1
$)
 
AND loadlist(x) BE UNLESS x=0 TEST h1!x=s_comma
                              THEN $( loadlist(h2!x); loadlist(h3!x) $)
                              ELSE load(x)

LET isconst(x) = VALOF
$( IF x=0 RESULTIS FALSE
 
   SWITCHON h1!x INTO
   $( CASE s_name:
        $( LET c = cellwithname(x)
           RESULTIS h2!c=s_manifest
        $)
 
      CASE s_number:
      CASE s_true:
      CASE s_false:  RESULTIS TRUE
 
      CASE s_neg:
      CASE s_abs:
      CASE s_not:    RESULTIS isconst(h2!x)
       
      CASE s_mult:
      CASE s_div:
      CASE s_rem:
      CASE s_plus:
      CASE s_minus:
      CASE s_lshift:
      CASE s_rshift:
      CASE s_logor:
      CASE s_logand:
      CASE s_eqv:
      CASE s_neqv:   IF isconst(h2!x) & isconst(h3!x) RESULTIS TRUE

      DEFAULT:       RESULTIS FALSE

   $)
$)

LET evalconst(x) = VALOF
$( LET a, b = 0, 0

   IF x=0 DO $( trnerr("Compiler error in Evalconst")
                RESULTIS 0
             $)
 
   SWITCHON h1!x INTO
   $( CASE s_name:
        $( LET c = cellwithname(x)
           IF h2!c=s_manifest RESULTIS h3!c
           trnerr("Variable %s in manifest expression", @h3!x)
           RESULTIS 0
        $)
 
      CASE s_number: RESULTIS h2!x
      CASE s_true:   RESULTIS TRUE
      CASE s_false:  RESULTIS FALSE
      CASE s_query:  RESULTIS 0
 
      CASE s_neg:
      CASE s_abs:
      CASE s_not:    a := evalconst(h2!x)
                     ENDCASE
       
      CASE s_mult:
      CASE s_div:
      CASE s_rem:
      CASE s_plus:
      CASE s_minus:
      CASE s_lshift:
      CASE s_rshift:
      CASE s_logor:
      CASE s_logand:
      CASE s_eqv:
      CASE s_neqv:   a, b := evalconst(h2!x), evalconst(h3!x)
                     ENDCASE

      DEFAULT:
   $)
    
   SWITCHON h1!x INTO
   $( CASE s_neg:    RESULTIS  -  a
      CASE s_abs:    RESULTIS ABS a
      CASE s_not:    RESULTIS NOT a
       
      CASE s_mult:   RESULTIS a   *    b
      CASE s_plus:   RESULTIS a   +    b
      CASE s_minus:  RESULTIS a   -    b
      CASE s_lshift: RESULTIS a   <<   b
      CASE s_rshift: RESULTIS a   >>   b
      CASE s_logor:  RESULTIS a   |    b
      CASE s_logand: RESULTIS a   &    b
      CASE s_eqv:    RESULTIS a  EQV   b
      CASE s_neqv:   RESULTIS a  NEQV  b
      CASE s_div:    UNLESS b=0 RESULTIS a   /    b
      CASE s_rem:    UNLESS b=0 RESULTIS a  REM   b
       
      DEFAULT:
   $)

   trnerr("Error in manifest expression")
   RESULTIS 0
$)

AND assign(x, y) BE
$( IF x=0 | y=0 DO $( trnerr("Compiler error in assign")
                      RETURN
                   $)
   
   UNLESS (h1!x=s_comma)=(h1!y=s_comma) DO
   $( trnerr("Bad simultaneous assignment")
      RETURN
   $)
 
   SWITCHON h1!x INTO
   $( CASE s_comma:  assign(h2!x, h2!y)
                     assign(h3!x, h3!y)
                     RETURN
 
      CASE s_name:   load(y)
                     transname(x, s_sp, s_sg, s_sl, 0, 0)
                     ssp := ssp - 1
                     RETURN
 
      CASE s_byteap: load(y)
                     load(h2!x)
                     load(h3!x)
                     out1(s_putbyte)
                     ssp:=ssp-3
                     RETURN
 
      CASE s_rv:
      CASE s_vecap:  load(y)
                     loadlv(x)
                     out1(s_stind)
                     ssp := ssp - 2
                     RETURN
 
      DEFAULT:       trnerr("Ltype expression needed")
   $)
$)
 
 
AND transname(x, p, g, l, f, n) BE
$( LET c = cellwithname(x)
   LET k, a = h2!c, h3!c
   LET name = @h3!x
 
   SWITCHON k INTO
   $( DEFAULT:        trnerr("Name '%s' not declared", name)
   
      CASE s_global:  out2(g, a); RETURN
 
      CASE s_local:   IF c<dvecp DO
                         trnerr("Dynamic free variable '%s' used", name)
                      out2(p, a); RETURN
 
      CASE s_static:  out2(l, a); RETURN
 
      CASE s_label:   IF f=0 DO
                      $( trnerr("Misuse of entry name '%s'", name)
                         f := p
                      $)
                      out2(f, a); RETURN

      CASE s_manifest:IF n=0 DO
                      $( trnerr("Misuse of MANIFEST name '%s'", name)
                         n := p
                      $)
                      out2(n, a)
  $)
$)
 
AND out1(x) BE wrn(x)
 
AND out2(x, y) BE $( out1(x); out1(y) $)
 
AND outstring(s) BE FOR i = 0 TO s%0 DO out1(s%i)

.
SECTION "CINCG"

// Header file for the CINTCODE32 code-generator
// based on the CINTCODE code-generator (1980).
// Copyright  M.Richards  6 June 1991.

GET "libhdr"

MANIFEST $(
t_hunk  = 1000       // Object module item types.
t_bhunk = 3000       // binary hunk (not hex)
t_end   = 1002

sectword  = #xFDDF   // SECTION and Entry marker words.
entryword = #xDFDF

// OCODE keywords.
s_true=4; s_false=5; s_rv=8; s_fnap=10
s_mult=11; s_div=12; s_rem=13
s_plus=14; s_minus=15; s_query=16; s_neg=17; s_abs=19
s_eq=20; s_ne=21; s_ls=22; s_gr=23; s_le=24; s_ge=25
s_not=30; s_lshift=31; s_rshift=32; s_logand=33
s_logor=34; s_eqv=35; s_neqv=36
s_lf=39; s_lp=40; s_lg=41; s_ln=42; s_lstr=43
s_ll=44; s_llp=45; s_llg=46; s_lll=47
s_needs=48; s_section=49; s_rtap=51; s_goto=52; s_finish=68
s_switchon=70; s_global=76; s_sp=80; s_sg=81; s_sl=82; s_stind=83
s_jump=85; s_jt=86; s_jf=87; s_endfor=88
s_lab=90; s_stack=91; s_store=92; s_rstack=93; s_entry=94
s_save=95; s_fnrn=96; s_rtrn=97; s_res=98
s_datalab=100; s_itemn=102; s_endproc=103; s_none=111
s_getbyte=120; s_putbyte=121

h1=0; h2=1; h3=2  // Selectors.
$)

GLOBAL $(
fin_p:237; fin_l:238
errcount:291; errmax:292; gostream: 297

codegenerate: 399

// Global procedures.
rdn:211     // reads numbers from the OCODE buffer

cgsects    : 400
rdl        : 402
rdgn       : 403
newlab     : 404
checklab   : 405
cgerror    : 406

initstack  : 407
stack      : 408
store      : 409
scan       : 410
cgpendingop:411
loadval    : 412
loadba     : 413
setba      : 414

genxch     : 415
genatb     : 416
loada      : 417
push       : 418
loadboth   : 419
inreg_a    : 420
inreg_b    : 421
addinfo_a  : 422
addinfo_b  : 423
pushinfo   : 424
xchinfo    : 425
atbinfo    : 426

forget_a   : 427
forget_b   : 428
forgetall  : 429
forgetvar  : 430
forgetallvars: 431

iszero     : 432
storet     : 433
gensp      : 434
genlp      : 435
loadt      : 436
lose1      : 437
swapargs   : 438
cgstind    : 439
storein    : 440

cgrv       : 441
cgplus     : 442
cgaddk     : 443
cgglobal   : 444
cgentry    : 445
cgapply    : 446
cgjump     : 447
jmpfn      : 448
jfn0       : 449
revjfn     : 450
compjfn    : 451
prepj      : 452

swlpos     : 453
swrpos     : 454
findpos    : 455
rootpos    : 456

cgswitch   : 457
switcht    : 458
switchseg  : 459
switchb    : 460
switchl    : 461
cgstring   : 462
setlab     : 463
cgstatics  : 464
getblk     : 465
freeblk    : 466
freeblks   : 467

initdatalists : 468

geng       : 469
gen        : 470
genb       : 471
genr       : 472
genh       : 473
genw       : 474
checkspace : 475
codeb      : 476
code2b     : 477
code4b     : 478
pack4b     : 479
codeh      : 480
codew      : 481
coder      : 482

getw       : 483
puth       : 484
putw       : 485
align      : 486
chkrefs    : 487
dealwithrefs:488
genindword :489
inrange_d  : 490
inrange_i  : 491
fillref_d  : 492
fillref_i  : 493
relref     : 494

outputsection : 495
wrword     : 496
wrhex2     : 497
wrword_at  : 498
dboutput   : 499
wrkn       : 500
wrcode     : 501
wrfcode    : 502

// Global variables.
arg1       : 503
arg2       : 504

ssp        : 505

tempt      : 506
tempv      : 507
stv        : 508
stvp       : 509

ch         : 510

dp         : 511
freelist   : 512

incode     : 513
labv       : 514

casek      : 515
casel      : 516

maxgn      : 520
maxlab     : 521
maxssp     : 522

op         : 527
labnumber  : 528
pendingop  : 529
procdepth  : 530

progsize   : 531

info_a     : 532
info_b     : 533
reflist    : 534
refliste   : 535
rlist      : 536
rliste     : 537
nlist      : 538
nliste     : 539
skiplab    : 540

bigender   : 550
naming     : 551
debug      : 552
bining     : 553

$)


MANIFEST
$(
// Value descriptors.
k_none=0; k_numb=1; k_fnlab=2
k_lvloc=3; k_lvglob=4; k_lvlab=5
k_a=6; k_b=7; k_c=8
k_loc=9; k_glob=10; k_lab=11; 
k_loc0=12; k_loc1=13; k_loc2=14; k_loc3=15; k_loc4=16
k_glob0=17; k_glob1=18; k_glob2=19

swapped=TRUE; notswapped=FALSE

// Global routine numbers.
gn_stop=2
$)

// CINTCODE function codes.
MANIFEST $(
f_k0   =   0
f_lf   =  12
f_lm   =  14
f_lm1  =  15
f_l0   =  16
f_fhop =  27
f_jeq  =  28
f_jeq0 =  30

f_k    =  32
f_kh   =  33
f_kw   =  34
f_k0g  =  32
f_s0g  =  44
f_l0g  =  45
f_l1g  =  46
f_l2g  =  47
f_lg   =  48
f_sg   =  49
f_llg  =  50
f_ag   =  51
f_mul  =  52
f_div  =  53
f_rem  =  54
f_xor  =  55
f_sl   =  56
f_ll   =  58
f_jne  =  60
f_jne0 =  62

f_llp  =  64
f_llph =  65
f_llpw =  66
f_add  =  84
f_sub  =  85
f_lsh  =  86
f_rsh  =  87
f_and  =  88
f_or   =  89
f_lll  =  90
f_jls  =  92
f_jls0 =  94

f_l    =  96
f_lh   =  97
f_lw   =  98
f_rv   = 116
f_rtn  = 123
f_jgr  = 124
f_jgr0 = 126

f_lp   = 128
f_lph  = 129
f_lpw  = 130
f_lp0  = 128
f_swb  = 146
f_swl  = 147
f_st   = 148
f_st0  = 148
f_goto = 155
f_jle  = 156
f_jle0 = 158

f_sp   = 160
f_sph  = 161
f_spw  = 162
f_sp0  = 160
f_s0   = 176
f_xch  = 181
f_gbyt = 182
f_pbyt = 183
f_atc  = 184
f_atb  = 185
f_j    = 186
f_jge  = 188
f_jge0 = 190

f_ap   = 192
f_aph  = 193
f_apw  = 194
f_ap0  = 192
f_xpbyt= 205
f_lmh  = 206
f_btc  = 207
f_nop  = 208
f_a0   = 208
f_rvp0 = 211
f_st0p0= 216
f_st1p0= 218

f_a    = 224
f_ah   = 225
f_aw   = 226
f_l0p0 = 224
f_s    = 237
f_sh   = 238
f_mdiv = 239
f_chgco= 240
f_neg  = 241
f_not  = 242
f_l1p0 = 240
f_l2p0 = 244
f_l3p0 = 247
f_l4p0 = 249
$)

LET codegenerate(workspace, workspacesize) BE
$( //writes("CIN32CG 9 June 1999*n")

   IF workspacesize<2000 DO $( cgerror("Too little workspace")
                               errcount := errcount+1
                               longjump(fin_p, fin_l)
                            $)

   progsize := 0

   op := rdn()

   cgsects(workspace, workspacesize)
   writef("Code size = %n bytes*n", progsize)
$)


AND cgsects(workvec, vecsize) BE UNTIL op=0 DO
$( LET p = workvec
   tempv := p
   p := p+90
   tempt := p
   casek := p
   p := p+400
   casel := p
   p := p+400
   labv := p
   dp := workvec+vecsize
   labnumber := (dp-p)/10+10
   p := p+labnumber
   FOR lp = labv TO p-1 DO !lp := -1
   stv := p
   stvp := 0
   incode := FALSE
   maxgn := 0
   maxlab := 0
   maxssp := 0
   procdepth := 0
   info_a, info_b := 0, 0
   initstack(3)
   initdatalists()

   codew(0)  // For size of module.
   IF op=s_section DO
   $( LET n = rdn()
      LET v = VEC 3
      v%0 := 7
      FOR i = 1 TO n DO  $( LET c = rdn()
                            IF i<=7 DO v%i := c
                         $)
      FOR i = n+1 TO 7 DO v%i := 32  //ASCII space.
      IF naming DO
      $( codew(sectword)
         codew(pack4b(v%0, v%1, v%2, v%3))
         codew(pack4b(v%4, v%5, v%6, v%7))
      $)
      op := rdn()
   $)

   scan()
   op := rdn()
   putw(0, stvp/4)  // Plant size of module.
   outputsection()
   progsize := progsize + stvp
$)


// Read an OCODE operator or argument.
/*
AND rdn() = VALOF
$( LET a, sign = 0, '+'
   ch := rdch() REPEATWHILE ch='*s' | ch='*n'
   IF ch=endstreamch RESULTIS 0
   IF ch='-' DO $( sign := '-'; ch := rdch() $)
   WHILE '0'<=ch<='9' DO $( a := 10*a + ch - '0'; ch := rdch()  $)
   IF sign='-' RESULTIS -a
   RESULTIS a
$)
*/
// Read in an OCODE label.
AND rdl() = VALOF
$( LET l = rdn()
   IF maxlab<l DO $( maxlab := l; checklab() $)
   RESULTIS l
$)

// Read in a global number.
AND rdgn() = VALOF
$( LET g = rdn()
   IF maxgn<g DO maxgn := g
   RESULTIS g
$)


// Generate next label number.
AND newlab() = VALOF
$( labnumber := labnumber-1
   checklab()
   RESULTIS labnumber
$)


AND checklab() BE IF maxlab>=labnumber DO
$( cgerror("Too many labels - increase workspace")
   errcount := errcount+1
   longjump(fin_p, fin_l)
$)


AND cgerror(mes, a) BE
$( writes("*nError: ")
   writef(mes, a)
   newline()
   errcount := errcount+1
   IF errcount>errmax DO $( writes("Too many errors*n")
                            longjump(fin_p, fin_l)
                         $)
$)


// Initialize the simulated stack (SS).
LET initstack(n) BE
$( arg2, arg1, ssp := tempv, tempv+3, n
   pendingop := s_none
   h1!arg2, h2!arg2, h3!arg2 := k_loc, ssp-2, ssp-2
   h1!arg1, h2!arg1, h3!arg1 := k_loc, ssp-1, ssp-1
   IF maxssp<ssp DO maxssp := ssp
$)


// Move simulated stack (SS) pointer to N.
AND stack(n) BE
$( IF maxssp<n DO maxssp := n
   IF n>=ssp+4 DO $( store(0,ssp-1)
                     initstack(n)
                     RETURN
                  $)

   WHILE n>ssp DO loadt(k_loc, ssp)

   UNTIL n=ssp DO
   $( IF arg2=tempv DO
      $( TEST n=ssp-1
         THEN $( ssp := n
                 h1!arg1, h2!arg1, h3!arg1 := h1!arg2, h2!arg2, ssp-1
                 h1!arg2, h2!arg2, h3!arg2 := k_loc, ssp-2, ssp-2
              $)
         ELSE initstack(n)
         RETURN
      $)

      arg1, arg2, ssp := arg1-3, arg2-3, ssp-1
   $)
$)



// Store all SS items from S1 to S2 in their true
// locations on the stack.
// It may corrupt both registers A and B.
AND store(s1, s2) BE FOR p = tempv TO arg1 BY 3 DO
                     $( LET s = h3!p
                        IF s>s2 RETURN
                        IF s>=s1 DO storet(p)
                     $)


AND scan() BE
$( IF debug>1 DO $( writef("OP=%i3 PND=%i3 ", op, pendingop)
                    dboutput()
                 $)

   SWITCHON op INTO

   $( DEFAULT:     cgerror("Bad OCODE op %n", op)
                   ENDCASE

      CASE 0:      RETURN
      
      CASE s_needs:
                $( LET n = rdn()  // Ignore NEEDS directives.
                   FOR i = 1 TO n DO rdn()
                   ENDCASE
                $)

      CASE s_lp:   loadt(k_loc,   rdn());   ENDCASE
      CASE s_lg:   loadt(k_glob,  rdgn());  ENDCASE
      CASE s_ll:   loadt(k_lab,   rdl());   ENDCASE
      CASE s_lf:   loadt(k_fnlab, rdl());   ENDCASE
      CASE s_ln:   loadt(k_numb,  rdn());   ENDCASE

      CASE s_lstr: cgstring(rdn());         ENDCASE

      CASE s_true: loadt(k_numb, -1);       ENDCASE
      CASE s_false:loadt(k_numb,  0);       ENDCASE

      CASE s_llp:  loadt(k_lvloc,  rdn());  ENDCASE
      CASE s_llg:  loadt(k_lvglob, rdgn()); ENDCASE
      CASE s_lll:  loadt(k_lvlab,  rdl());  ENDCASE

      CASE s_sp:   storein(k_loc,  rdn());  ENDCASE
      CASE s_sg:   storein(k_glob, rdgn()); ENDCASE
      CASE s_sl:   storein(k_lab,  rdl());  ENDCASE

      CASE s_stind:cgstind(); ENDCASE

      CASE s_rv:   cgrv(); ENDCASE

      CASE s_mult:CASE s_div:CASE s_rem:
      CASE s_plus:CASE s_minus:
      CASE s_eq: CASE s_ne:
      CASE s_ls:CASE s_gr:CASE s_le:CASE s_ge:
      CASE s_lshift:CASE s_rshift:
      CASE s_logand:CASE s_logor:CASE s_eqv:CASE s_neqv:
      CASE s_not:CASE s_neg:CASE s_abs:
                   cgpendingop()
                   pendingop := op
                   ENDCASE

      CASE s_jt:   cgjump(TRUE, rdl());  ENDCASE

      CASE s_jf:   cgjump(FALSE, rdl()); ENDCASE

      CASE s_goto: cgpendingop()
                   store(0, ssp-2)
                   TEST h1!arg1=k_fnlab
                   THEN genr(f_j, h2!arg1)
                   ELSE $( loada(arg1); gen(f_goto) $)
                   stack(ssp-1)
                   incode := FALSE
                   // This is a good place to deal with
                   // some outstanding forward refs.
                   chkrefs(50)
                   ENDCASE

      CASE s_lab:  cgpendingop()
                   UNLESS incode DO chkrefs(30)
                   store(0, ssp-1)
                   setlab(rdl())
                   forgetall()
                   incode := procdepth>0
                   ENDCASE

      CASE s_query:loadt(k_loc, ssp);              ENDCASE

      CASE s_stack:cgpendingop(); stack(rdn());    ENDCASE

      CASE s_store:cgpendingop(); store(0, ssp-1); ENDCASE

      CASE s_entry:
                $( LET l = rdl()
                   LET n = rdn()
                   cgentry(l, n)
                   procdepth := procdepth + 1
                   ENDCASE
                $)

      CASE s_save:
                $( LET n = rdn()
                   initstack(n)
                   IF n>3 DO addinfo_a(k_loc, 3)
                   ENDCASE
                $)

      CASE s_fnap:
      CASE s_rtap: cgapply(op, rdn()); ENDCASE

      CASE s_rtrn: cgpendingop()
                   gen(f_rtn)
                   incode := FALSE
                   ENDCASE
                   
      CASE s_fnrn: cgpendingop()
                   loada(arg1)
                   gen(f_rtn)
                   stack(ssp-1)
                   incode := FALSE
                   ENDCASE

      CASE s_endproc:
                   cgstatics()
                   procdepth := procdepth - 1
                   ENDCASE

      CASE s_res:
      CASE s_jump:
                $( LET l = rdl()

                   cgpendingop()
                   store(0, ssp-2)
                   TEST op=s_jump
                   THEN storet(arg1)
                   ELSE $( loada(arg1); stack(ssp-1) $)

                   $( op := rdn()
                      UNLESS op=s_stack BREAK
                      stack(rdn())
                   $) REPEAT

                   TEST op=s_lab
                   THEN $( LET m = rdl()
                           UNLESS l=m DO genr(f_j, l)
                           setlab(m)
                           forgetall()
                           incode := procdepth>0
                           op := rdn()
                        $)
                   ELSE $( genr(f_j, l)
                           incode := FALSE
                           // Deal with some refs.
                           chkrefs(50)
                        $)

                   LOOP
                $)

      // rstack always occurs immediately after a lab statement
      // at a time when cgpendingop() and store(0, ssp-2) have
      // been called.
      CASE s_rstack: stack(rdn()); loadt(k_a, 0); ENDCASE

      CASE s_finish:  // Compile code for:  stop(0).
         $( LET k = ssp
            stack(ssp+3)
            loadt(k_numb, 0)
            loadt(k_numb, 0)
            loadt(k_glob, gn_stop)
            cgapply(s_rtap, k)    // Simulate the call: stop(0, 0)
            ENDCASE
         $)

      CASE s_switchon: cgswitch(); ENDCASE

      CASE s_getbyte:  cgpendingop()
                       loadba(arg2, arg1)
                       gen(f_gbyt)
                       forget_a()
                       lose1(k_a, 0)
                       ENDCASE


      CASE s_putbyte:  cgpendingop()

                       // First move arg3 to C.
                    $( LET arg3 = arg2 - 3
                       TEST arg3-tempv < 0 
                       THEN $( loadt(k_loc, ssp-3)
                               loada(arg1)
                               gen(f_atc)
                               stack(ssp-1)
                            $)
                       ELSE $( TEST inreg_b(h1!arg3, h2!arg3)
                               THEN    gen(f_btc)
                               ELSE $( loada(arg3)
                                       gen(f_atc)
                                    $)
                               h1!arg3 := k_c
                            $)
                       TEST loadboth(arg2, arg1)=swapped
                       THEN gen(f_xpbyt)
                       ELSE gen(f_pbyt)
                       forgetallvars()
                       stack(ssp-3)
                       ENDCASE
                    $)

      CASE s_global:   cgglobal(rdn()); RETURN

      CASE s_datalab:
                $( LET lab = rdl() 
                   op := rdn()

                   WHILE op=s_itemn DO
                   $( !nliste := getblk(0,lab,rdn())
                      nliste, lab, op := !nliste, 0, rdn()
                   $)
                   LOOP
                $)
   $)

   op := rdn()
$) REPEAT


// Compiles code to deal with any pending op.
LET cgpendingop() BE
$( LET f = 0
   LET sym = TRUE
   LET pndop = pendingop
   pendingop := s_none

   SWITCHON pndop INTO
   $( DEFAULT:      cgerror("Bad pendingop %n", pndop)

      CASE s_none:  RETURN

      CASE s_abs:   loada(arg1)
                    chkrefs(3)
                    genb(jfn0(f_jgr), 2) // Conditionally skip
                    gen(f_neg)           // over this NEG instruction.
                    forget_a()
                    RETURN

      CASE s_neg:   loada(arg1)
                    gen(f_neg)
                    forget_a()
                    RETURN

      CASE s_not:   loada(arg1)
                    gen(f_not)
                    forget_a()
                    RETURN

      CASE s_eq: CASE s_ne:
      CASE s_ls: CASE s_gr:
      CASE s_le: CASE s_ge:
                    f := prepj(jmpfn(pndop))
                    chkrefs(4)
                    genb(f, 2)    // Jump to    ---
                    gen(f_fhop)   //               |
                    gen(f_lm1)    // this point  <-
                    lose1(k_a, 0)
                    forget_a()
                    forget_b()
                    RETURN

      CASE s_minus: UNLESS k_numb=h1!arg1 DO
                    $( f, sym := f_sub, FALSE
                       ENDCASE
                    $)
                    h2!arg1 := -h2!arg1

      CASE s_plus:  cgplus(); RETURN

      CASE s_mult:  f      := f_mul;        ENDCASE
      CASE s_div:   f, sym := f_div, FALSE; ENDCASE
      CASE s_rem:   f, sym := f_rem, FALSE; ENDCASE
      CASE s_lshift:f, sym := f_lsh, FALSE; ENDCASE
      CASE s_rshift:f, sym := f_rsh, FALSE; ENDCASE
      CASE s_logand:f      := f_and;        ENDCASE
      CASE s_logor: f      := f_or;         ENDCASE
      CASE s_eqv:
      CASE s_neqv:  f      := f_xor;        ENDCASE
   $)

   TEST sym THEN loadboth(arg2, arg1)
            ELSE loadba(arg2, arg1)

   gen(f)
   forget_a()
   IF pndop=s_eqv THEN gen(f_not)

   lose1(k_a, 0)
$)

LET loada(x)   BE $( loadval(x, FALSE); setba(0, x) $)

AND push(x, y) BE $( loadval(y, TRUE);  setba(x, y) $)

AND loadval(x, pushing) BE  // ONLY called from loada and push.
// Load compiles code to have the following effect:
// If pushing=TRUE    B := A; A := <x>.
// If pushing=FALSE   B := ?; A := <x>.
$( LET k, n = h1!x, h2!x

   UNLESS pushing | k=k_a DO  // Dump A register if necessary.
     FOR t = arg1 TO tempv BY -3 IF h1!t=k_a DO $( storet(t); BREAK $)

   TEST inreg_a(k, n) THEN setba(0, x)
                      ELSE IF inreg_b(k, n) DO $( genxch(0, 0)
                                                  RETURN
                                               $)
   SWITCHON h1!x INTO
   $( DEFAULT:  cgerror("in loada %n", k)

      CASE k_a: IF pushing UNLESS inreg_b(k, n) DO genatb(0, 0)
                RETURN

      CASE k_numb:
        TEST -1<=n<=10
        THEN gen(f_l0+n)
        ELSE TEST 0<=n<=255
             THEN genb(f_l, n)
             ELSE TEST -255<=n<=0
                  THEN genb(f_lm, -n)
                  ELSE TEST 0<=n<=#xFFFF
                       THEN genh(f_lh, n)
                       ELSE TEST -#xFFFF<=n<=0
                            THEN genh(f_lmh, -n)
                            ELSE genw(f_lw, n)
        ENDCASE

      CASE k_loc:  genlp(n);        ENDCASE
      CASE k_glob: geng(f_lg, n);   ENDCASE
      CASE k_lab:  genr(f_ll, n);   ENDCASE
      CASE k_fnlab:genr(f_lf, n);   ENDCASE

      CASE k_lvloc:TEST 0<=n<=255
                   THEN genb(f_llp, n)
                   ELSE TEST 0<=n<=#xFFFF
                        THEN genh(f_llph, n)
                        ELSE genw(f_llpw, n)
                   ENDCASE

      CASE k_lvglob:geng(f_llg, n); ENDCASE
      CASE k_lvlab: genr(f_lll, n); ENDCASE
      CASE k_loc0:  gen(f_l0p0+n);  ENDCASE
      CASE k_loc1:  gen(f_l1p0+n);  ENDCASE
      CASE k_loc2:  gen(f_l2p0+n);  ENDCASE
      CASE k_loc3:  gen(f_l3p0+n);  ENDCASE
      CASE k_loc4:  gen(f_l4p0+n);  ENDCASE
      CASE k_glob0: geng(f_l0g, n); ENDCASE
      CASE k_glob1: geng(f_l1g, n); ENDCASE
      CASE k_glob2: geng(f_l2g, n); ENDCASE
   $)

   // A loading instruction has just been compiled.
   pushinfo(h1!x, h2!x)
$)

AND loadba(x, y) BE IF loadboth(x, y)=swapped DO genxch(x, y)

AND setba(x, y) BE
$( UNLESS x=0 DO h1!x := k_b
   UNLESS y=0 DO h1!y := k_a
$)

AND genxch(x, y) BE $( gen(f_xch); xchinfo(); setba(x, y) $)

AND genatb(x, y) BE $( gen(f_atb); atbinfo(); setba(x, y) $)

AND loadboth(x, y) = VALOF
// Compiles code to cause
//   either    x -> [B]  and  y -> [A]
//             giving result NOTSWAPPED
//   or        x -> [A]  and  y -> [B]
//             giving result SWAPPED.
// LOADBOTH only swaps if this saves code.
$( // First ensure that no other stack item uses reg A.
   FOR t = tempv TO arg1 BY 3 DO
       IF h1!t=k_a UNLESS t=x | t=y DO storet(t)

   $( LET xa, ya = inreg_a(h1!x, h2!x), inreg_a(h1!y, h2!y)
      AND xb, yb = inreg_b(h1!x, h2!x), inreg_b(h1!y, h2!y)

      IF xb & ya DO $( setba(x,y);               RESULTIS notswapped $)
      IF xa & yb DO $( setba(y,x);               RESULTIS swapped    $)
      IF xa & ya DO $( genatb(x,y);              RESULTIS notswapped $)
      IF xb & yb DO $( genxch(0,y); genatb(x,y); RESULTIS notswapped $)
      
      IF xa DO $(              push(x,y); RESULTIS notswapped $)
      IF ya DO $(              push(y,x); RESULTIS swapped    $)
      IF xb DO $( genxch(0,x); push(x,y); RESULTIS notswapped $)
      IF yb DO $( genxch(0,y); push(y,x); RESULTIS swapped    $)
      
      loada(x)
      push(x, y)
      RESULTIS notswapped
   $)
$)

LET inreg_a(k, n) = VALOF
$( LET p = info_a
   IF k=k_a RESULTIS TRUE
   UNTIL p=0 DO $( IF k=h2!p & n=h3!p RESULTIS TRUE
                   p := !p
                $)
   RESULTIS FALSE
$)

AND inreg_b(k, n) = VALOF
$( LET p = info_b
   IF k=k_b RESULTIS TRUE
   UNTIL p=0 DO $( IF k=h2!p & n=h3!p RESULTIS TRUE
                   p := !p
                $)
   RESULTIS FALSE
$)

AND addinfo_a(k, n) BE info_a := getblk(info_a, k, n)

AND addinfo_b(k, n) BE info_b := getblk(info_b, k, n)

AND pushinfo(k, n) BE
$( forget_b()
   info_b := info_a
   info_a := getblk(0, k, n)
$)

AND xchinfo() BE
$( LET t = info_a
   info_a := info_b
   info_b := t
$)

AND atbinfo() BE
$( LET p = info_a
   forget_b()
   UNTIL p=0 DO $( addinfo_b(h2!p, h3!p); p := !p $)
$)

AND forget_a() BE $( freeblks(info_a); info_a := 0 $)

AND forget_b() BE $( freeblks(info_b); info_b := 0 $)

AND forgetall() BE $( forget_a(); forget_b() $)

// Forgetvar is called just after a simple variable (k, n) has been
// updated.  k is k_loc, k_glob or k_lab.  Note that register
// infomation about indirect local and global values
// must also be thrown away.
AND forgetvar(k, n) BE
$( LET p = info_a
   UNTIL p=0 DO $( IF h2!p>=k_loc0 | h2!p=k & h3!p=n DO h2!p := k_none
                   p := !p
                $)
   p := info_b
   UNTIL p=0 DO $( IF h2!p>=k_loc0 | h2!p=k & h3!p=n DO h2!p := k_none
                   p := !p
                $)
$)

AND forgetallvars() BE  // Called after STIND or PUTBYTE.
$( LET p = info_a
   UNTIL p=0 DO $( IF h2!p>=k_loc DO h2!p := k_none
                   p := !p
                $)
   p := info_b
   UNTIL p=0 DO $( IF h2!p>=k_loc DO h2!p := k_none
                   p := !p
                $)
$)

AND iszero(a) = h1!a=k_numb & h2!a=0 -> TRUE, FALSE

// Store the value of a SS item in its true stack location.
AND storet(x) BE
$( LET s = h3!x
   IF h1!x=k_loc & h2!x=s RETURN
   loada(x)
   gensp(s)
   forgetvar(k_loc, s)
   addinfo_a(k_loc, s)
   h1!x, h2!x := k_loc, s
$)

AND gensp(s) BE TEST 3<=s<=16
                THEN gen(f_sp0+s)
                ELSE TEST 0<=s<=255
                     THEN genb(f_sp, s)
                     ELSE TEST 0<=s<=#xFFFF
                          THEN genh(f_sph, s)
                          ELSE genw(f_spw, s)

AND genlp(n) BE TEST 3<=n<=16
                THEN gen(f_lp0+n)
                ELSE TEST 0<=n<=255
                     THEN genb(f_lp, n)
                     ELSE TEST 0<=n<=#xFFFF
                          THEN genh(f_lph, n)
                          ELSE genw(f_lpw, n)

// Load an item (K,N) onto the SS. It may move SS items.
AND loadt(k, n) BE
$( cgpendingop()
   TEST arg1+3=tempt
   THEN $( storet(tempv)  // SS stack overflow.
           FOR t = tempv TO arg2+2 DO t!0 := t!3
        $)
   ELSE arg2, arg1 := arg2+3, arg1+3
   h1!arg1,h2!arg1,h3!arg1 := k,n,ssp
   ssp := ssp + 1
   IF maxssp<ssp DO maxssp := ssp
$)


// Replace the top two SS items by (K,N) and set PENDINGOP=S_NONE.
AND lose1(k, n) BE
$( ssp := ssp - 1
   TEST arg2=tempv
   THEN $( h1!arg2,h2!arg2 := k_loc,ssp-2
           h3!arg2 := ssp-2
        $)
   ELSE $( arg1 := arg2
           arg2 := arg2-3
        $)
   h1!arg1, h2!arg1, h3!arg1 := k,n,ssp-1
   pendingop := s_none
$)

AND swapargs() BE
$( LET k, n = h1!arg1, h2!arg1
   h1!arg1, h2!arg1 := h1!arg2, h2!arg2
   h1!arg2, h2!arg2 := k, n
$)

AND cgstind() BE
$( LET t = VALOF
   $( IF pendingop=s_plus DO
      $( IF k_numb=h1!arg2 DO swapargs()
         IF k_numb=h1!arg1 DO
         $( LET n = h2!arg1
            IF 0<=n<=3 DO $( stack(ssp-1)
                             pendingop := s_none
                             RESULTIS n
                          $)
         $)

         IF h1!arg2=k_loc & 3<=h2!arg2<=5 DO swapargs()
         IF h1!arg1=k_loc & 3<=h2!arg1<=5 DO
         $( LET n = h2!arg1
            stack(ssp-1)
            pendingop := s_none
            RESULTIS n+1  // The codes for P3, P4 and P5.
         $)

         UNLESS arg2=tempv DO
         $( LET arg3 = arg2 - 3
            IF h1!arg3=k_a DO
            $( IF h1!arg2=k_loc |
                  h1!arg2=k_glob |
                  h1!arg2=k_numb DO swapargs()
               IF h1!arg1=k_loc |
                  h1!arg1=k_glob |
                  h1!arg1=k_numb DO
               // Optimize the case  <arg2>!<arg1> := <arg3>
               // where <arg3> is already in A
               // and <arg1> is a local, a global or a number.
               $( push(arg3, arg2)
                  cgplus()  // Compiles an A, AP or AG instr.
                  gen(f_st)
                  stack(ssp-2)
                  forgetallvars()
                  RETURN
               $)
            $)
         $)
      $)

      cgpendingop()
      RESULTIS 0
   $)

   // Now compile code for S!<arg1> := <arg2>
   // where           S is 0, 1, 2, 3, P3, P4 or P5
   // depending on    T =  0, 1, 2, 3,  4,  5 or  6

   $( LET k, n = h1!arg1, h2!arg1
   
      IF k=k_glob & t=0 DO $( loada(arg2)
                              geng(f_s0g, n)
                              stack(ssp-2)
                              forgetallvars()
                              RETURN
                           $)

      IF k=k_loc & 3<=n<=4 & t<=1 DO $( loada(arg2)
                                        gen(t=0 -> f_st0p0+n,
                                                   f_st1p0+n)
                                        stack(ssp-2)
                                        forgetallvars()
                                        RETURN
                                     $)

      loadba(arg2, arg1)
      gen(f_st+t)
      stack(ssp-2)
      forgetallvars()
   $)
$)


// Store the top item of the SS in (K,N).
AND storein(k, n) BE
// K is K_LOC, K_GLOB or K_LAB.
$( cgpendingop()
   loada(arg1)

   SWITCHON k INTO
   $( DEFAULT:     cgerror("in storein %n", k)
      CASE k_loc:  gensp(n);       ENDCASE
      CASE k_glob: geng(f_sg, n);  ENDCASE
      CASE k_lab:  genr(f_sl, n);  ENDCASE
   $)
   forgetvar(k, n)
   addinfo_a(k, n)
   stack(ssp-1)
$)

LET cgrv() BE
$( LET t = VALOF
   $( IF pendingop=s_plus DO
      $( IF k_numb=h1!arg2 DO swapargs()
         IF k_numb=h1!arg1 DO
         $( LET n = h2!arg1
            IF 0<=n<=6 DO $( stack(ssp-1)
                             pendingop := s_none
                             RESULTIS n
                          $)
         $)

         IF h1!arg2=k_loc & 3<=h2!arg2<=7 DO swapargs()
         IF h1!arg1=k_loc & 3<=h2!arg1<=7 DO $( LET n = h2!arg1
                                                stack(ssp-1)
                                                pendingop := s_none
                                                RESULTIS 10 + n
                                             $)
      $)
      cgpendingop()
      RESULTIS 0
   $)

   // Now compile code for S!<arg1>
   // where          S is 0,..., 6, P3,..., P7
   // depending on   T =  0,..., 6, 13,..., 17

   LET k, n = h1!arg1, h2!arg1
   
   IF k=k_glob & 0<=t<=2 DO $( h1!arg1 := k_glob0 + t; RETURN $)

   IF k=k_loc & n>=3 DO
      IF t=0 & n<=12 |
         t=1 & n<=6  |
         t=2 & n<=5  |
         t=3 & n<=4  |
         t=4 & n<=4  DO $( h1!arg1 := k_loc0 + t; RETURN $)

   loada(arg1)
   TEST t<=6 THEN gen(f_rv+t)
             ELSE gen(f_rvp0 + t - 10)
   forget_a()
   h1!arg1, h2!arg1 := k_a, 0
$)

AND cgplus() BE
// Compiles code to compute <arg2> + <arg1>.
// It does not look at PENDINGOP.

$( IF iszero(arg1) DO $( stack(ssp-1); RETURN $)

   IF iszero(arg2) DO
   $( IF h2!arg1=ssp-1 &
         (h1!arg1=k_loc | k_loc0<=h1!arg1<=k_loc4) DO loada(arg1)
      lose1(h1!arg1, h2!arg1)
      RETURN
   $)

   TEST inreg_a(h1!arg1, h2!arg1)
   THEN loada(arg1)
   ELSE IF inreg_a(h1!arg2, h2!arg2) DO loada(arg2)

   IF h1!arg1=k_a DO swapargs()

   IF h1!arg2=k_loc & 3<=h2!arg2<=12 DO swapargs()
   IF h1!arg1=k_loc & 3<=h2!arg1<=12 DO $( loada(arg2)
                                           gen(f_ap0 + h2!arg1)
                                           forget_a()
                                           lose1(k_a, 0)
                                           RETURN
                                        $)

   IF h1!arg2=k_numb & -4<=h2!arg2<=5 DO swapargs()
   IF h1!arg1=k_numb & -4<=h2!arg1<=5 DO $( loada(arg2)
                                            cgaddk(h2!arg1)
                                            lose1(k_a, 0)
                                            RETURN
                                         $)

   IF h1!arg2=k_loc DO swapargs()
   IF h1!arg1=k_loc DO
   $( LET n = h2!arg1
      loada(arg2)
      TEST 3<=n<=12 THEN gen(f_ap0 + n)
                    ELSE TEST 0<=n<=255
                         THEN genb(f_ap, n)
                         ELSE TEST 0<=n<=#xFFFF
                              THEN genh(f_aph, n)
                              ELSE genw(f_apw, n)
      forget_a()
      lose1(k_a, 0)
      RETURN
   $)

   IF h1!arg2=k_glob DO swapargs()
   IF h1!arg1=k_glob DO $( loada(arg2)
                           geng(f_ag, h2!arg1)
                           forget_a()
                           lose1(k_a, 0)
                           RETURN
                        $)

   IF h1!arg2=k_numb DO swapargs()
   IF h1!arg1=k_numb DO $( LET n = h2!arg1
                           loada(arg2)
                           cgaddk(n)
                           lose1(k_a, 0)
                           RETURN
                        $)
   loadboth(arg2, arg1)
   gen(f_add)
   forget_a()
   lose1(k_a, 0)
$)

AND cgaddk(k) BE UNLESS k=0 DO  // Compile code to add k to A.
$( TEST -4<=k<=5
   THEN TEST k<0 THEN gen(f_s0 - k)
                 ELSE gen(f_a0 + k)
   ELSE TEST -255<=k<=255
        THEN TEST k>0 THEN genb(f_a, k)
                      ELSE genb(f_s, -k)
        ELSE TEST 0<=k<=#xFFFF
             THEN genh(f_ah, k)
             ELSE TEST -#xFFFF<=k<=0
                  THEN genh(f_sh, -k)
                  ELSE genw(f_aw, k)
   forget_a()
$)

AND cgglobal(n) BE
$( incode := FALSE
   cgstatics()
   chkrefs(512)   // Deal with ALL outstanding refs.
   align(4)
   codew(0)       // Compile Global initialisation data.
   FOR i = 1 TO n DO $( codew(rdgn()); codew(labv!rdl()) $)
   codew(maxgn)
$)


AND cgentry(l, n) BE
$( LET v = VEC 3
   v%0 := 7
   FOR i = 1 TO n DO $( LET c = rdn()
                        IF i<=7 DO v%i := c
                     $)
   FOR i = n+1 TO 7 DO v%i := 32  // Ascii SPACE.
   chkrefs(80)  // Deal with some forward refs.
   align(4)
   IF naming DO $( codew(entryword)
                   codew(pack4b(v%0, v%1, v%2, v%3))
                   codew(pack4b(v%4, v%5, v%6, v%7))
                $)
   IF debug>0 DO writef("// Entry to:   %s*n", v)
   setlab(l)
   incode := TRUE
   forgetall()
$)

// Function or routine call.
AND cgapply(op, k) BE
$( LET sa = k+3  // Stack address of first arg (if any).
   AND a1 = 0    // SS item for first arg if found.

   cgpendingop()

// Deal with non args.
   FOR t = tempv TO arg2 BY 3 DO $( IF h3!t>=k BREAK
                                    IF h1!t=k_a DO storet(t)
                                 $)

// Deal with args 2, 3 ...
   FOR t = tempv TO arg2 BY 3 DO
   $( LET s = h3!t
      IF s=sa DO
      $( a1 := t  // We have found the SS item for the first arg.
         IF h1!t=k_a & t+3=arg2 DO
         // Two argument call with the first arg already in A.
         $( push(t, arg2)
            storet(arg2)    // Store second arg.
            genxch(0, t)    // Restore first arg back to A.
            BREAK
         $)
      $)
      IF s>sa DO storet(t)
   $)

   // Move first arg (if any) into A.
   IF sa<ssp-1 TEST a1=0
               THEN genlp(sa)  // First arg exists but not in SS.
               ELSE loada(a1)  // First arg exists in SS

   // First arg (if any) is now in A.

   TEST h1!arg1=k_glob & 3<=k<=11
   THEN geng(f_k0g+k, h2!arg1)
   ELSE $( push(a1, arg1)
           // First arg (if any) is now in B
           // and the procedure address is in A.
           TEST 3<=k<=11
           THEN gen(f_k0+k)
           ELSE TEST 0<=k<=255
                THEN genb(f_k, k)
                ELSE TEST 0<=k<=#xFFFF
                     THEN genh(f_kh, k)
                     ELSE genw(f_kw, k)
        $)

   forgetall()
   stack(k)
   IF op=s_fnap DO loadt(k_a, 0)
$)

// Used for OCODE operators JT and JF.
AND cgjump(b,l) BE
$( LET f = jmpfn(pendingop)
   IF f=0 DO $( loadt(k_numb,0); f := f_jne $)
   pendingop := s_none
   UNLESS b DO f := compjfn(f)
   store(0,ssp-3)
   genr(prepj(f),l)
   stack(ssp-2)
$)

AND jmpfn(op) = VALOF SWITCHON op INTO
$( DEFAULT:  RESULTIS 0
   CASE s_eq: RESULTIS f_jeq
   CASE s_ne: RESULTIS f_jne
   CASE s_ls: RESULTIS f_jls
   CASE s_gr: RESULTIS f_jgr
   CASE s_le: RESULTIS f_jle
   CASE s_ge: RESULTIS f_jge
$)

AND jfn0(f) = f+2 // Change F_JEQ into F_JEQ0  etc...

AND revjfn(f) = f=f_jls -> f_jgr,
                f=f_jgr -> f_jls,
                f=f_jle -> f_jge,
                f=f_jge -> f_jle,
                f

AND compjfn(f) = f=f_jeq -> f_jne,
                 f=f_jne -> f_jeq,
                 f=f_jls -> f_jge,
                 f=f_jge -> f_jls,
                 f=f_jgr -> f_jle,
                 f=f_jle -> f_jgr,
                 f

AND prepj(f) = VALOF  // Returns the appropriate m/c fn.
$( IF iszero(arg2) DO $( swapargs(); f := revjfn(f) $)
   IF iszero(arg1) DO $( loada(arg2); RESULTIS jfn0(f) $)
   IF loadboth(arg2, arg1)=swapped RESULTIS revjfn(f)
   RESULTIS f
$)

// Compiles code for SWITCHON.
LET cgswitch() BE
$( LET n = rdn()     // Number of cases.
   LET dlab = rdl()  // Default label.

   // Read and sort (K,L) pairs.
   FOR i = 1 TO n DO
   $( LET k = rdn()
      LET l = rdl()
      LET j = i-1
      UNTIL j=0 DO  $( IF k > casek!j BREAK
                       casek!(j+1), casel!(j+1) := casek!j, casel!j
                       j := j - 1
                    $)
      casek!(j+1), casel!(j+1) := k, l
   $)

   cgpendingop()
   store(0, ssp-2)
   loada(arg1)
   stack(ssp-1)
   switcht(1, n, dlab)
$)

// Code has already been compiled to set A to the 
// value of the switch expression.
AND switcht(p, q, dlab) BE
$( UNLESS p<=q DO $( genr(f_j, dlab); RETURN $)
   
   IF 0 <= casek!q - casek!p <= #xFFFF DO   // Care with overflow!
   $( switchseg(p, q, dlab)
      RETURN
   $)
   
   $( LET r = (p+q)/2  // p<q  and so  r~=q
      LET s = r

      WHILE p<r & 0 <= casek!s-casek!(r-1) <= #xFFFF DO r := r-1
      WHILE s<q & 0 <= casek!r-casek!(s+1) <= #xFFFF DO s := s+1
	
      // Note that: if r=p then s~=q
      IF r-p <= q-s DO r := s+1
      // r is now set to the pivot position. Note: r~=p

      cgaddk(-casek!r)
	
      // Now subtract casek!r from all case constants
      // and re-sort if necessary.
      r := offsetcases(p, q, r)
      // r is chosen so that casek!r=0

      TEST r=p
      THEN genr(f_jls0, dlab)
      ELSE $( LET lab = newlab()
              genr(f_jge0, lab)
              switcht(p, r-1, dlab)  // All cases < 0
              setlab(lab)
           $)
      switcht(r, q, dlab)            // All cases >= 0
   $)
$)

AND offsetcases(p, q, r) = VALOF
$( LET offset = casek!r
   IF offset=0 RESULTIS r  // Nothing to do.
   
   FOR i = p TO q  DO casek!i := casek!i - offset
   IF casek!p < casek!q RESULTIS r  // No overflow occurred.
   
   // Re-sort the cases.
   FOR i = p+1 TO q DO
   $( LET j = i
      LET k, l = casek!i, casel!i
      UNTIL j>p & casek!(j-1) > k DO
      $( casek!j, casel!j := casek!(j-1), casel!(j-1)
         j := j-1
      $)
      casek!j, casel!j := k, l
   $)
   
   // Find the new pivot point.
   FOR i = p TO q IF casek!i=0 RESULTIS i
   cgerror("in offsetcases")
   RESULTIS p
$)

AND switchseg(p, q, dlab) BE
$( // Only called when  0 <= casek!q - casek!p <= #xFFFF
   //              and  p <= q
   LET n = q-p+1  // The number of cases (>=1).

   IF n=1 DO $( cgaddk(-casek!p)
                genr(f_jeq0, casel!p)
                genr(f_j, dlab)
                RETURN
             $)

   TEST 2*n < casek!q - casek!p  // Which is smaller?
   THEN switchb(p, q, dlab)      // Binary chop switch.
   ELSE switchl(p, q, dlab)      // Label vector switch.
$)

AND switchb(p, q, dlab) BE  // Binary chop switch.
$( // Only called when  0 <= casek!q - casek!p <= #xFFFF
   //              and  p < q
   LET n = q-p+1   // Number of cases (>1).
   LET n1 = n>7 ->n, 7
   
   // Ensure that all case constants can be represented by
   // unsigned 16 bit integers.
   IF casek!p<0 | casek!q>#xFFFF DO
   $( cgaddk(-casek!p)
      offsetcases(p, q, p)
   $)
   
   chkrefs(6+4*n1) // allow for padding to 7 cases
   gen(f_swb)
   align(2)
   codeh(n)
   coder(dlab)
   FOR i = p TO q DO $( LET pos = q + 1 - findpos(i-p+1, q-p+1)
                        codeh(casek!pos)
                        coder(casel!pos)
                     $)
   FOR i = q+1 TO p+6 DO $( codeh(0) // pad out to 7 cases
                            coder(dlab)
                         $)
$)

// If the integers 1..n were stored in a balanced binary
// tree using the tree structure of heap sort, then
// integer i would be at position findpos(i, n).
AND findpos(i, n) = VALOF
$( LET r = ?
   IF i = 1 DO $( swlpos, swrpos := 0, n
                  RESULTIS rootpos(0, n)
               $)
   r := findpos(i/2, n)
   TEST (i&1) = 0 THEN swrpos := r-1
                  ELSE swlpos := r
   RESULTIS rootpos(swlpos, swrpos)
$)

AND rootpos(p, q) = VALOF
$( LET n = q-p
   LET s, r = 2, ?
   UNTIL s>n DO s := s+s
   s := s/2
   r := n-s+1
   IF s <= r+r RESULTIS p + s
   RESULTIS p + s/2 + r
$)

AND switchl(p, q, dlab) BE  // Label vector switch.
$( // Only called when  0 <= casek!q - casek!p <= #xFFFF
   //              and  p < q

   LET n, t = ?, p

   // Adjust case constants to suit SWL instruction.
   IF casek!p<0 | casek!p>1 | casek!q>#xFFFF DO
   $( cgaddk(-casek!p)
      offsetcases(p, q, p)
   $)
   
   n := casek!q + 1   // Number of entries in the label vector.
   chkrefs(2*n+6)
   gen(f_swl)
   align(2)
   codeh(n)
   coder(dlab)        // Default label.

   FOR k= 0 TO casek!q TEST casek!t=k
                       THEN $( coder(casel!t)
                               t := t+1
                            $)
                       ELSE coder(dlab)
$)

AND cgstring(n) BE
$( LET l, a = newlab(), n
   loadt(k_lvlab,l)
   $( LET b, c, d = 0, 0, 0
      IF n>0 DO b := rdn()
      IF n>1 DO c := rdn()
      IF n>2 DO d := rdn()
      !nliste := getblk(0,l,pack4b(a, b, c, d))
      nliste := !nliste
      l := 0
      IF n<=3 BREAK
      n, a := n-4, rdn()
   $) REPEAT
$)

AND setlab(l) BE
$( LET p = @rlist

   IF debug>0 DO writef("%i4: L%n:*n", stvp, l)

   labv!l := stvp  // Set the label.

   // Fill in all refs that are in range.
   $( LET r = !p
      IF r=0 BREAK
      TEST h3!r=l & inrange_d(h2!r, stvp)
      THEN $( fillref_d(h2!r, stvp)
              !p := !r   // Remove item from RLIST.
              freeblk(r)
           $)
      ELSE p := r  // Keep the item.
   $) REPEAT
   rliste := p     // Ensure that RLISTE is sensible.

   p := @reflist

   $( LET r = !p
      IF r=0 BREAK
      TEST h3!r=l
      THEN $( LET a = h2!r
              puth(a,stvp-a) // Plant rel address.
              !p := !r       // Remove item from REFLIST.
              freeblk(r)
           $)
      ELSE p := r  // Keep item.
   $) REPEAT

   refliste := p   // Ensure REFLISTE is sensible.
$)



AND cgstatics() BE UNTIL nlist=0 DO
$( LET len, nl = 0, nlist

   nliste := @nlist  // All NLIST items will be freed.

   len, nl := len+4, !nl REPEATUNTIL nl=0 | h2!nl ~= 0

   chkrefs(len+3)  // +3 because align(4) may generate 3 bytes.
   align(4)

   setlab(h2!nlist)  // NLIST always starts labelled.

   $( LET blk = nlist
      nlist := !nlist
      freeblk(blk)
      codew(h3!blk)
   $) REPEATUNTIL nlist=0 | h2!nlist ~= 0
$)



AND getblk(a, b, c) = VALOF
$( LET p = freelist
   TEST p=0 THEN $( dp := dp-3; checkspace(); p := dp $)
            ELSE freelist := !p
   h1!p, h2!p, h3!p := a, b, c
   RESULTIS p
$)


AND freeblk(p) BE $( !p := freelist; freelist := p $)

AND freeblks(p) BE UNLESS p=0 DO
$( LET oldfreelist = freelist
   freelist := p
   UNTIL !p=0 DO p := !p
   !p := oldfreelist
$)


AND initdatalists() BE
$( reflist, refliste := 0, @reflist
   rlist,   rliste   := 0, @rlist
   nlist,   nliste   := 0, @nlist
   freelist := 0
$)

LET geng(f, n) BE TEST n<256
                  THEN genb(f, n)
                  ELSE TEST n<512
                       THEN genb(f+32, n-256)
                       ELSE genh(f+64, n)

LET gen(f) BE IF incode DO
$( chkrefs(1)
   IF debug DO wrcode(f, "")
   codeb(f)
$)

LET genb(f, a) BE IF incode DO
$( chkrefs(2)
   IF debug>0 DO wrcode(f, "%i3", a)
   codeb(f)
   codeb(a)
$)

LET genr(f, n) BE IF incode DO
$( chkrefs(2)
   IF debug>0 DO wrcode(f, "L%n", n)
   codeb(f)
   codeb(0)
   relref(stvp-2, n)
$)

LET genh(f, h) BE IF incode DO  // Assume 0 <= h <= #xFFFF
$( chkrefs(3)
   IF debug>0 DO wrcode(f, "%n", h)
   codeb(f)
   code2b(h)
$)

LET genw(f, w) BE IF incode DO
$( chkrefs(5)
   IF debug>0 DO wrcode(f, "%n", w)
   codeb(f)
   code4b(w)
$)

AND checkspace() BE IF stvp/4>dp-stv DO
$( cgerror("Program too large, %n bytes compiled", stvp)
   errcount := errcount+1
   longjump(fin_p, fin_l)
$)


AND codeb(byte) BE
$( stv%stvp := byte
   stvp := stvp + 1
   checkspace()
$)

AND code2b(h) BE TEST bigender
THEN $( codeb(h>>8 ); codeb(h    )  $)
ELSE $( codeb(h    ); codeb(h>>8 )  $)

AND code4b(w) BE TEST bigender
THEN $( codeb(w>>24); codeb(w>>16); codeb(w>>8 ); codeb(w    )  $)
ELSE $( codeb(w    ); codeb(w>>8 ); codeb(w>>16); codeb(w>>24)  $)

AND pack4b(b0, b1, b2, b3) =
  bigender -> b0<<24 | b1<<16 | b2<<8 | b3,
              b3<<24 | b2<<16 | b1<<8 | b0

AND codeh(h) BE
$( IF debug>0 DO writef("%i4:  DATAH %n*n", stvp, h)
   code2b(h)
$)

AND codew(w) BE
$( IF debug>0 DO writef("%i4:  DATAW 0x%x8*n", stvp, w)
   code4b(w)
$)

AND coder(n) BE
$( LET labval = labv!n
   IF debug>0 DO writef("%i4:  DATAH L%n-$*n", stvp, n)
   code2b(0)
   TEST labval=-1 THEN $( !refliste := getblk(0, stvp-2, n)
                          refliste := !refliste
                       $)
                  ELSE puth(stvp-2, labval-stvp+2)
$)

AND getw(a) = 
   bigender -> stv%a<<24 | stv%(a+1)<<16 | stv%(a+2)<<8  | stv%(a+3),
               stv%a     | stv%(a+1)<<8  | stv%(a+2)<<16 | stv%(a+3)<<24

AND puth(a, w) BE
   TEST bigender
   THEN stv%a,     stv%(a+1) := w>>8, w
   ELSE stv%(a+1), stv%a     := w>>8, w

AND putw(a, w) BE
   TEST bigender
   THEN stv%a, stv%(a+1), stv%(a+2), stv%(a+3) := w>>24,w>>16, w>>8, w
   ELSE stv%(a+3), stv%(a+2), stv%(a+1), stv%a := w>>24,w>>16, w>>8, w

AND align(n) BE UNTIL stvp REM n = 0 DO codeb(0)

AND chkrefs(n) BE  // Resolve references until it is possible
                   // to compile n bytes without a reference
                   // going out of range.
$( LET p = @rlist

   skiplab := 0

   UNTIL !p=0 DO
   $( LET r = !p
      LET a = h2!r // RLIST is ordered in increasing A.

      IF (stv%a & 1) = 0 DO
      // An unresolved reference at address A
      $( IF inrange_i(a, stvp+n+3) BREAK
         // This point is reached if there is
         // an unresolved ref at A which cannot
         // directly relative address STVP+N+3
         // and so an indirect data word must
         // be compiled.
         // The +3 is to allow for a possible
         // skip jump instruction and possibly
         // one filler byte.
         genindword(h3!r)
      $)

      // At this point the reference at A
      // is in range of a resolving indirect
      // data word and should be removed from
      // RLIST if there is no chance that it
      // can be resolved by a direct relative
      // address.
      TEST inrange_d(a, stvp)
      THEN p := r        // Keep the item.
      ELSE $( !p := !r   // Free item if already resolved
              freeblk(r) // and no longer in direct range.
              IF !p=0 DO rliste := p  // Correct RLISTE.
           $)
   $)

   // At this point all necessary indirect data words have
   // been compiled.

   UNLESS skiplab=0 DO $( setlab(skiplab)
                          skiplab, incode := 0, TRUE
                       $)
$)

AND genindword(l) BE  // Called only from CHKREFS.
$( LET r = rlist      // Assume RLIST ~= 0

   IF incode DO
   $( skiplab := newlab()
      // genr(f_j, skiplab) without the call of chkrefs(2).
      IF debug>0 DO wrcode(f_j, "L%n", skiplab)
      codeb(f_j)
      codeb(0)
      relref(stvp-2, skiplab)
      incode := FALSE
   $)

   align(2)

   UNTIL r=0 DO
   $( IF h3!r=l & (stv%(h2!r) & 1)=0 DO fillref_i(h2!r, stvp)
      r := !r
   $)

   coder(l)
$)

AND inrange_d(a, p) = a-127 <= p <= a+128
// The result is TRUE if direct relative instr (eg J) at
// A can address location P directly.

AND inrange_i(a, p) = VALOF
// The result is TRUE if indirect relative instr (eg J$)
// at A can address a resolving word at P.
$( LET rel = (p-a)/2
   RESULTIS 0 <= rel <= 255
$)

AND fillref_d(a, p) BE
$( stv%a := stv%a & 254  // Back to direct form if neccessary.
   stv%(a+1) := p-a-1
$)

AND fillref_i(a, p) BE  // P is even.
$( stv%a := stv%a | 1   // Force indirect form.
   stv%(a+1) := (p-a)/2
$)

AND relref(a, l) BE
// RELREF is only called just after compiling
// a relative reference instruction at
// address A (=stvp-2).
$( LET labval = labv!l

   IF labval>=0 & inrange_d(a, labval) DO $( fillref_d(a, labval)
                                             RETURN
                                          $)

   // All other references in RLIST have
   // addresses smaller than A and so RLIST will
   // remain properly ordered if this item
   // is added to the end.
   !rliste := getblk(0, a, l)
   rliste := !rliste
$)

LET outputsection() BE
$( LET outstream = output()
   UNTIL reflist=0 DO $( cgerror("Label L%n unset", h3!reflist)
                         reflist := !reflist
                      $)

   selectoutput(gostream)  // Output a HUNK or BHUNK.

   TEST bining
   THEN { writef("%X3 ", t_bhunk)          // writes 4 chars "BB8 "
          FOR p=0 TO 3      DO wrch(stv%p) // write bhunk size
          FOR p=0 TO stvp-1 DO wrch(stv%p) // write the bhunk
        }
   ELSE { newline()
          wrword(t_hunk)
          wrword(stvp/4)
          FOR p=0 TO stvp-4 BY 4 DO
          $( IF p REM 20 = 0 DO newline()
             wrword_at(p)
          $)
          newline()
        }
   selectoutput(outstream)
$)

AND wrword(a) BE writef("%X8 ", a)

AND wrhex2(byte) BE
$( LET t = TABLE '0','1','2','3','4','5','6','7',
                 '8','9','A','B','C','D','E','F'
   wrch(t!(byte>>4))
   wrch(t!(byte&15))
$)

AND wrword_at(a) BE
$( TEST bigender THEN $( wrhex2(stv%a)
                         wrhex2(stv%(a+1))
                         wrhex2(stv%(a+2))
                         wrhex2(stv%(a+3))
                      $)
                 ELSE $( wrhex2(stv%(a+3))
                         wrhex2(stv%(a+2))
                         wrhex2(stv%(a+1))
                         wrhex2(stv%(a))
                      $)
   wrch(' ')
$)

AND dboutput() BE
$( LET p = info_a
   writes("A=(")
   UNTIL p=0 DO $( wrkn(h2!p, h3!p)
                   p := !p
                   UNLESS p=0 DO wrch('*s')
                $)
    
   p := info_b
   writes(") B=(")
   UNTIL p=0 DO $( wrkn(h2!p, h3!p)
                   p := !p
                   UNLESS p=0 DO wrch('*s')
                $)
   wrch(')')
   
   IF debug=2 DO $( writes("  STK: ")
                    FOR p=tempv TO arg1 BY 3  DO
                    $( IF (p-tempv) REM 30 = 10 DO newline()
                       wrkn(h1!p,h2!p)
                       wrch('*s')
                    $)
                 $)
   
   IF debug=3 DO $(  LET l = rlist
                     writes("*nREFS ")
                     UNTIL l=0 DO $( writef("%n L%n  ", l!1, l!2)
                                     l := !l
                                  $)
                 $)
   newline()
$)


AND wrkn(k,n) BE
$( LET s = VALOF SWITCHON k INTO
   $( DEFAULT:       k := n
                     RESULTIS "?"
      CASE k_none:   RESULTIS "-"
      CASE k_numb:   RESULTIS "N"
      CASE k_fnlab:  RESULTIS "F"
      CASE k_lvloc:  RESULTIS "@P"
      CASE k_lvglob: RESULTIS "@G"
      CASE k_lvlab:  RESULTIS "@L"
      CASE k_a:      RESULTIS "A"
      CASE k_b:      RESULTIS "B"
      CASE k_c:      RESULTIS "C"
      CASE k_loc:    RESULTIS "P"
      CASE k_glob:   RESULTIS "G"
      CASE k_lab:    RESULTIS "L"
      CASE k_loc0:   RESULTIS "0P"
      CASE k_loc1:   RESULTIS "1P"
      CASE k_loc2:   RESULTIS "2P"
      CASE k_loc3:   RESULTIS "3P"
      CASE k_loc4:   RESULTIS "4P"
      CASE k_glob0:  RESULTIS "0G"
      CASE k_glob1:  RESULTIS "1G"
      CASE k_glob2:  RESULTIS "2G"
   $)
   writes(s)
   UNLESS k=k_none | k=k_a | k=k_b | k=k_c DO writen(n)
$)

AND wrcode(f, form, a, b) BE
$( IF debug=2 DO dboutput()
   writef("%i4: ", stvp)
   wrfcode(f)
   writes("  ")
   writef(form, a, b)
   newline()
$)

AND wrfcode(f) BE
$( LET s = VALOF SWITCHON f&31 INTO
   $( DEFAULT:
      CASE  0: RESULTIS "     -     K   LLP     L    LP    SP    AP     A"
      CASE  1: RESULTIS "     -    KH  LLPH    LH   LPH   SPH   APH    AH"
      CASE  2: RESULTIS "   BRK    KW  LLPW    LW   LPW   SPW   APW    AW"
      CASE  3: RESULTIS "    K3   K3G  K3G1  K3GH   LP3   SP3   AP3  L0P3"
      CASE  4: RESULTIS "    K4   K4G  K4G1  K4GH   LP4   SP4   AP4  L0P4"
      CASE  5: RESULTIS "    K5   K5G  K5G1  K5GH   LP5   SP5   AP5  L0P5"
      CASE  6: RESULTIS "    K6   K6G  K6G1  K6GH   LP6   SP6   AP6  L0P6"
      CASE  7: RESULTIS "    K7   K7G  K7G1  K7GH   LP7   SP7   AP7  L0P7"
      CASE  8: RESULTIS "    K8   K8G  K8G1  K8GH   LP8   SP8   AP8  L0P8"
      CASE  9: RESULTIS "    K9   K9G  K9G1  K9GH   LP9   SP9   AP9  L0P9"
      CASE 10: RESULTIS "   K10  K10G K10G1 K10GH  LP10  SP10  AP10 L0P10"
      CASE 11: RESULTIS "   K11  K11G K11G1 K11GH  LP11  SP11  AP11 L0P11"
      CASE 12: RESULTIS "    LF   S0G  S0G1  S0GH  LP12  SP12  AP12 L0P12"
      CASE 13: RESULTIS "   LF$   L0G  L0G1  L0GH  LP13  SP13 XPBYT     S"
      CASE 14: RESULTIS "    LM   L1G  L1G1  L1GH  LP14  SP14   LMH    SH"
      CASE 15: RESULTIS "   LM1   L2G  L2G1  L2GH  LP15  SP15   BTC  MDIV"
      CASE 16: RESULTIS "    L0    LG   LG1   LGH  LP16  SP16   NOP CHGCO"
      CASE 17: RESULTIS "    L1    SG   SG1   SGH   SYS    S1    A1   NEG"
      CASE 18: RESULTIS "    L2   LLG  LLG1  LLGH   SWB    S2    A2   NOT"
      CASE 19: RESULTIS "    L3    AG   AG1   AGH   SWL    S3    A3  L1P3"
      CASE 20: RESULTIS "    L4   MUL   ADD    RV    ST    S4    A4  L1P4"
      CASE 21: RESULTIS "    L5   DIV   SUB   RV1   ST1   XCH    A5  L1P5"
      CASE 22: RESULTIS "    L6   REM   LSH   RV2   ST2  GBYT  RVP3  L1P6"
      CASE 23: RESULTIS "    L7   XOR   RSH   RV3   ST3  PBYT  RVP4  L2P3"
      CASE 24: RESULTIS "    L8    SL   AND   RV4  STP3   ATC  RVP5  L2P4"
      CASE 25: RESULTIS "    L9   SL$    OR   RV5  STP4   ATB  RVP6  L2P5"
      CASE 26: RESULTIS "   L10    LL   LLL   RV6  STP5     J  RVP7  L3P3"
      CASE 27: RESULTIS "  FHOP   LL$  LLL$   RTN  GOTO    J$ ST0P3  L3P4"
      CASE 28: RESULTIS "   JEQ   JNE   JLS   JGR   JLE   JGE ST0P4  L4P3"
      CASE 29: RESULTIS "  JEQ$  JNE$  JLS$  JGR$  JLE$  JGE$ ST1P3  L4P4"
      CASE 30: RESULTIS "  JEQ0  JNE0  JLS0  JGR0  JLE0  JGE0 ST1P4     -"
      CASE 31: RESULTIS " JEQ0$ JNE0$ JLS0$ JGR0$ JLE0$ JGE0$     -     -"
   $)
   LET n = f>>5 & 7
   FOR i = 6*n+1 TO 6*(n+1) DO wrch(s%i)
$)



