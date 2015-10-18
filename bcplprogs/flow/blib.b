// (c)  Copyright:  Martin Richards  30 November 1998

/*
30/4/1996
  Added function flush()
  with corresponding change in cintmain.c

7/6/1996
  Defined mkobj(upb, fns, a, b) for use in object oriented programming.
  See bcplprogs/objdemo.b  (args a and b added 30 March 1999).
*/

SECTION "BLIB"

GET "libhdr"
GET "IOHDR"

LET stop(n) BE cowait(n) // Typically returning from a CLI command
                         // with error code n

AND clihook(a1) = start(a1)

AND intflag()          =  sys(28)  // returns TRUE if user interrupt

AND abort(code)        BE sys(0, code)

AND level(p3)          =  (@p3)!-3

AND longjump(lev, lab) BE $( LET p = @lev - 3; p!0, p!1 := lev, lab $)

AND sardch()           =  sys(10)

AND sawrch(ch)         BE sys(11,ch)

LET rdch() = VALOF
$( LET pos = cis!scb_pos
   LET ch = ?
   IF pos < cis!scb_end DO $( cis!scb_pos := pos+1
                              ch := cis%pos
                              IF ch='*c' RESULTIS rdch()
                              RESULTIS ch
                           $)
   ch := (cis!scb_rdfn)(cis)
   IF ch='*c' RESULTIS rdch()
   RESULTIS ch
$)

AND unrdch() = VALOF
$( LET pos = cis!scb_pos
   IF pos<=scb_bufstart RESULTIS FALSE // Cannot UNRDCH past origin.
   cis!scb_pos := pos-1
   RESULTIS TRUE
$)

AND wrch(ch) BE
$( LET pos = cos!scb_pos
   cos%pos := ch
   cos!scb_pos := pos+1
   IF pos>=cos!scb_end UNLESS (cos!scb_wrfn)(cos) DO abort(189)
$)

AND findinput(string)            = findstream(string, id_inscb,    0)
AND pathfindinput(string, path)  = findstream(string, id_inscb, path)

AND findoutput(string) = findstream(string, id_outscb, 0)

AND findstream(name, id, path) = VALOF
$( LET console = compstring("**", name)=0
   LET scb = ?
   IF console DO
   $( IF id=id_inscb & rootnode!rtn_keyboard~=0
         RESULTIS rootnode!rtn_keyboard
      IF id=id_outscb & rootnode!rtn_screen~=0
         RESULTIS rootnode!rtn_screen
   $) 

   scb := getvec(scb_upb)
   IF scb=0 RESULTIS 0

   scb!scb_pos   := 0
   scb!scb_end   := 0
   scb!scb_file  := 0
   scb!scb_id    := id
   scb!scb_work  := 0
   scb!scb_rdfn  := falsefn
   scb!scb_wrfn  := falsefn
   scb!scb_endfn := falsefn

   IF console DO
   $( scb!scb_file := -1               // Console stream
      scb!scb_work  := FALSE
      IF id=id_inscb  DO $( scb!scb_rdfn := cnslrdfn
                            rootnode!rtn_keyboard := scb
                         $)
      IF id=id_outscb DO $( scb!scb_wrfn := cnslwrfn
                            scb!scb_pos := scb_bufstart
                            scb!scb_end := scb_bufstart
                            rootnode!rtn_screen := scb
                         $)
      RESULTIS scb
   $)

   IF id=id_inscb  DO $( scb!scb_file := sys(14, name, path)
                         scb!scb_rdfn := filerdfn
                      $)
   IF id=id_outscb DO $( scb!scb_file := sys(15, name)
                         scb!scb_pos  := scb_bufstart
                         scb!scb_end  := scb_bufend
                         scb!scb_wrfn := filewrfn
                      $)
   IF scb!scb_file=0 DO $( freevec(scb); RESULTIS 0 $)
   scb!scb_endfn := fileendfn
   RESULTIS scb
$)

AND falsefn(scb) = FALSE

AND cnslrdfn(scb) = VALOF
$( LET p = scb_bufstart
   IF scb!scb_work RESULTIS endstreamch

   $( LET ch = sys(10)
      SWITCHON ch INTO
      $( DEFAULT:          scb%p := ch
                           p := p+1
                           IF p<scb_bufend LOOP
                           BREAK
         CASE endstreamch: scb!scb_work := TRUE
                           IF p=scb_bufstart RESULTIS endstreamch
                           BREAK 
         CASE '*n':        scb%p := ch
                           p := p+1
                           BREAK
         CASE char_bs:     IF p>scb_bufstart DO p := p-1
                           sys(11, ' ')
                           sys(11, char_bs)
                           LOOP
      $)
   $) REPEAT

   scb!scb_pos, scb!scb_end := scb_bufstart+1, p
   RESULTIS scb%scb_bufstart
$)

AND cnslwrfn(scb) = VALOF
$( sys(11, scb%scb_bufstart)
   scb!scb_pos := scb_bufstart
   RESULTIS TRUE
$)

AND filerdfn(scb)  = VALOF
$( LET buf = scb + scb_buf
   LET len = sys(12, scb!scb_file, buf, scb_buflen)
   IF len=0 RESULTIS endstreamch
   scb!scb_pos := scb_bufstart+1
   scb!scb_end := scb_bufstart+len
   RESULTIS scb%scb_bufstart
$)  
   
AND filewrfn(scb) = VALOF
$( LET buf = scb + scb_buf
   LET len = scb!scb_pos - scb_bufstart
   scb!scb_pos := scb_bufstart
   RESULTIS sys(13, scb!scb_file, buf, len)=len -> TRUE, FALSE
$)  
   
AND flush() = VALOF
$( IF cos=0 | cos!scb_id~=id_outscb DO abort(187)
   RESULTIS filewrfn(cos)
$)  
   
AND fileendfn(scb) = sys(16, scb!scb_file)

AND selectinput(scb) BE
$( IF scb=0 | scb!scb_id~=id_inscb DO abort(186)
   cis := scb
$)

AND selectoutput(scb) BE
$( IF scb=0 | scb!scb_id~=id_outscb DO abort(187)
   cos := scb
$)

AND endread()  BE
$( UNLESS (cis!scb_endfn)(cis) DO abort(190)
   freevec(cis)
$)

AND endwrite() BE
$( UNLESS (cos!scb_wrfn)(cos) DO abort(189)
   UNLESS (cos!scb_endfn)(cos) DO abort(191)
   freevec(cos)
$)

AND input()  = cis

AND output() = cos

AND readn() = VALOF
$( LET sum, neg, ch = 0, ?, ?
   ch := rdch() REPEATWHILE ch='*s' | ch='*t' | ch='*n' 
   neg := ch='-'
   IF ch='-' | ch='+' DO ch := rdch()
   UNLESS '0'<=ch<='9' DO $( unrdch(); result2 := -1; RESULTIS 0 $)
   WHILE '0'<=ch<='9' DO $( sum := 10*sum + ch - '0'; ch := rdch() $)
   unrdch()
   result2 := 0
   RESULTIS neg -> -sum, sum
$)

AND newline() BE wrch('*n')

AND newpage() BE wrch('*p')

AND writed(n, d) BE
$( LET t = VEC 10
   AND i, k = 0, -n
   IF n<0 DO d, k := d-1, n
   t!i, i, k := -(k REM 10), i+1, k/10 REPEATUNTIL k=0
   FOR j = i+1 TO d DO wrch('*s')
   IF n<0 DO wrch('-')
   FOR j = i-1 TO 0 BY -1 DO wrch(t!j+'0')
$)

AND writeu(n, d) BE
 $( LET m = (n>>1)/5
    UNLESS m=0 DO $( writed(m, d-1); d := 1 $)
    writed(n-m*10, d)
 $)

AND writen(n) BE writed(n, 0)

AND writebin(n, d) BE
$( IF d>1 DO writebin(n>>1, d-1)
   wrch((n&1)+'0')
$)

AND writeoct(n, d) BE
$( IF d>1 DO writeoct(n>>3, d-1)
   wrch((n&7)+'0')
$)

AND writehex(n, d) BE
$( IF d>1 DO writehex(n>>4, d-1)
   wrch((n&15)!TABLE '0','1','2','3','4','5','6','7',
                     '8','9','A','B','C','D','E','F' )
$)

AND writes(s) BE FOR i = 1 TO s%0 DO wrch(s%i)

AND writet(s, d) BE
 $( writes(s)
    FOR i = 1 TO d-s%0 DO wrch('*s')
 $)

AND writef(format, a, b, c, d, e, f, g, h, i, j, k) BE
$( LET t = @ a

   FOR p = 1 TO format%0 DO
   $( LET k = format%p

      TEST k='%'

      THEN $( LET f, n = ?, ?
              p := p+1
              SWITCHON capitalch(format%p) INTO
              $( DEFAULT:  wrch(format%p); ENDCASE
                 CASE 'S': f := writes;    GOTO l
                 CASE 'T': f := writet;    GOTO m
                 CASE 'C': f := wrch;      GOTO l
                 CASE 'B': f := writebin;  GOTO m
                 CASE 'O': f := writeoct;  GOTO m
                 CASE 'X': f := writehex;  GOTO m
                 CASE 'I': f := writed;    GOTO m
                 CASE 'N': f := writen;    GOTO l
                 CASE 'U': f := writeu
              m:           p := p+1
                           n := format%p
                           n := '0'<=n<='9' -> n-'0', 10+n-'A'
              l:           f(!t, n)
                 CASE '$': t := t+1
              $)
           $)

      ELSE wrch(k)
   $)
$)

STATIC $( seed = 12345 $)

LET randno(upb) = VALOF  // return a random number in the range 1 to upb
$( seed := seed*2147001325 + 715136305
   RESULTIS (ABS(seed/3)) REM upb + 1
$)

AND setseed(newseed) = VALOF // Added  20 Jan 2000
{ LET oldseed = seed
  seed := newseed
  RESULTIS oldseed
}

// muldiv is now implemented in SYSLIB using the MDIV instruction
//AND muldiv(a, b, c) = sys(26, a, b, c)

AND unpackstring(s, v) BE FOR i = s%0 TO 0 BY -1 DO v!i := s%i

AND packstring(v, s) = VALOF
$( LET n = v!0 & 255
   LET size = n/bytesperword
   FOR i = 0 TO n DO s%i := v!i
   FOR i = n+1 TO (size+1)*bytesperword-1 DO s%i := 0
   RESULTIS size
$)

AND capitalch(ch) = 'a' <= ch <= 'z' -> ch + 'A' - 'a', ch

AND compch(ch1, ch2) = capitalch(ch1) - capitalch(ch2)

AND compstring(s1, s2) = VALOF
$( LET len1, len2 = s1%0, s2%0
   LET len = len1<len2 -> len1, len2

   FOR i = 1 TO len DO $( LET res = compch(s1%i, s2%i)
                          UNLESS res=0 RESULTIS res
                       $)

   RESULTIS len1=len2 -> 0, len=len1 -> -1, 1
$)

AND str2numb(s) = VALOF
$( LET a = 0
   FOR i = 1 TO s%0 DO $( LET dig = s%i - '0'
                          IF 0<=dig<=9 DO a := 10*a + dig
                       $)
   RESULTIS s%1='-' -> -a, a
$)

AND rdargs(keys, argv, upb) = VALOF
// rdargs reads the arguments of a command upto and including
// the newline or semicolon that terminates the argument list.
$( LET w, numbargs = argv, ?

   !w := 0
   FOR p = 1 TO keys%0 DO
   $( LET kch = keys%p
      IF kch='/' DO $( LET c = capitalch(keys%(p+1))
                       IF c = 'A' DO !w := !w | 1
                       IF c = 'K' DO !w := !w | 2
                       IF c = 'S' DO !w := !w | 4
                    $)
      IF kch=',' DO $( w := w+1
                       IF w>argv+upb GOTO err
                       !w := 0
                    $)
   $)
   w := w+1
   numbargs := w-argv

// At this stage, the argument elements of argv have been
// initialised to  0    -
//                 1   /A
//                 2   /K
//                 3   /A/K
//                 4   /S
//                 5   /S/A
//                 6   /S/K
//                 7   /S/A/K

   $( LET argno = -1
      LET wupb = upb + argv - w

      SWITCHON rditem(w, wupb) INTO
      $( DEFAULT: GOTO err

         CASE 3:  // *n
         CASE 4:  // ;
         CASE 0:  // endstreamch
             FOR i = 0 TO numbargs - 1 DO
             $( LET a = argv!i
                IF 0<=a<=7 TEST (a&1)=0 THEN argv!i := 0 
                                        ELSE GOTO err
             $)
             RESULTIS w

         CASE 1:  // ordinary item
             argno := findarg(keys, w)
             TEST argno>=0
             THEN TEST 4 <= argv!argno <= 7
                  THEN $( argv!argno := -1  // a switch arg
                          LOOP
                       $)
                  ELSE IF rditem(w,wupb)<=0 GOTO err
             ELSE TEST rdch()='*n' & compstring("?", w)=0
                  THEN $( writef("%s:*n", keys) // help facility
                          ENDCASE
                       $)
                  ELSE unrdch()

         CASE 2:  // quoted item (i.e. arg value)
             IF argno<0 FOR i = 0 TO numbargs-1 SWITCHON argv!i INTO
                        $( CASE 0: CASE 1: argno := i; BREAK
                           CASE 2: CASE 3: GOTO err
                           DEFAULT:
                        $)
             UNLESS argno>=0 GOTO err

             argv!argno := w
             w := w + w%0/bytesperword + 1
      $)
   $) REPEAT
err:
   $( LET ch = ?
      ch := rdch() REPEATUNTIL ch='*n' | ch=';' | ch=endstreamch
      RESULTIS 0
   $)
$)

// Read an item from command line
// returns -1    error
//          0    endstreamch            *** MR change 11/12/92
//          1    unquoted item
//          2    quoted item
//          3    *n                     *** MR change 11/12/92
//          4    ;                      *** MR change 11/12/92
AND rditem(v, upb) = VALOF
$( LET p, pmax = 0, (upb+1)*bytesperword-1
   LET ch, quoted = ?, FALSE

   FOR i = 0 TO upb DO v!i := 0

   // Skip over blank space.
   ch := rdch() REPEATWHILE ch='*s' | ch='*t' | ch='*c'

   IF ch=endstreamch RESULTIS 0
   IF ch='*n'        RESULTIS 3
   IF ch=';'         RESULTIS 4

   IF ch='"' DO $( ch :=  rdch()
                   IF ch='*c' LOOP
                   IF ch='*n' | ch=endstreamch RESULTIS -1
                   IF ch='"' RESULTIS 2 // Found a quoted string.
                   IF ch='**' DO $( ch := rdch()
                                    IF capitalch(ch)='N' DO ch := '*n'
                                 $)
                   p := p+1
                   IF p>pmax RESULTIS -1
                   v%0, v%p := p, ch
                $) REPEAT

   UNTIL ch='*n' | ch='*s' | ch=';' | ch=endstreamch DO
   $( p := p+1
      IF p>pmax RESULTIS -1
      v%0, v%p := p, ch
      ch := rdch()
   $)

   UNLESS ch=endstreamch DO unrdch()
   RESULTIS 1
$)

AND findarg(keys, w) = VALOF  // =argno  if found
                              // =-1     otherwise
$( LET matching, argno, p, len = TRUE, 0, 0, w%0

   FOR i = 1 TO keys%0 DO
   $( LET k = keys%i
      TEST k='=' | k='/' | k=','
      THEN $( IF matching & p=len RESULTIS argno
              matching, p := TRUE, 0
              IF k='/' DO matching := FALSE
              IF k=',' DO argno := argno+1
           $)
      ELSE IF matching DO
           $( p := p+1
              UNLESS compch(k, w%p)=0 DO matching := FALSE
           $)
   $)
   RESULTIS matching & p=len -> argno, -1
$)

LET createco(fn, size) = VALOF
$( LET c = getvec(size+6)

   IF c=0 RESULTIS 0

   FOR i = 6 TO size+6 DO c!i := 0

  // Using P to denote the current stack frame
  // pointer, the following assumptions are made:
  //  P!0, P!1, P!2 contain the return link information
  //  P!3   is the variable fn
  //  P!4   is the variable size
  //  P!5   is the variable c

  // Now make the vector c into a valid BCPL
  // stack frame containg copies of fn, size
  // and c in the same relative positions.
  // Other locations in the new stack frame 
  // are used for other purposes.
  c!0 := c<<B2Wsh // resumption point
  c!1 := currco   // parent link
  c!2 := colist   // colist chain
  c!3 := fn       // the main function
  c!4 := size     // the coroutine size
  c!5 := c        // the new coroutine pointer

  colist := c  // insert into the list of coroutines

  changeco(0, c)

  // Execution now continues with the P pointer set to c<<B2Wsh,
  // and so  the vector c becomes the current stack frame.
  // The compiler will have generated code on
  // the assumption that fn and c are the third and fifth
  // words of the stack frame, and, since c!3 and c!5
  // were initialised to fn and c, the following repeated
  // statement will have the effect (naively) expected.
  // Note that the first call of cowait causes a return
  // from createco with result c.

  c := fn(cowait(c)) REPEAT
$)

AND deleteco(cptr) = VALOF
$( LET a = @colist
   $( LET co = !a
      IF co=cptr | co=0 BREAK
      a := @ co!co_list
   $) REPEAT
   IF !a=0 RESULTIS FALSE  // Coroutine not found.
   UNLESS cptr!1=0 DO abort(112)
   !a := cptr!co_list      // Remove the coroutine from colist.
   freevec(cptr)           // Free the coroutine stack.
   RESULTIS TRUE
$)

AND callco(cptr, a) = VALOF
$( UNLESS cptr!co_parent=0 DO abort(110)
   cptr!co_parent := currco
   RESULTIS changeco(a, cptr)
$)

AND cowait(a) = VALOF
$( LET parent = currco!co_parent
   currco!co_parent := 0
   RESULTIS changeco(a, parent)
$)

AND resumeco(cptr, a) = VALOF
$( LET parent = currco!co_parent
   currco!co_parent := 0
   UNLESS cptr!co_parent=0 DO abort(111)
   cptr!co_parent := parent
   RESULTIS changeco(a, cptr)
$)

AND initco(fn, size, a, b, c, d, e, f, g, h, i, j, k) = VALOF
$( LET cptr = createco(fn, size)
   UNLESS cptr=0 DO callco(cptr, @a)
   RESULTIS cptr
$)

AND getvec(upb) = sys(21, upb)

AND freevec(ptr) BE sys(22, ptr)

AND loadseg(name) = sys(23, name)

AND globin(segl) = sys(24, segl)

AND unloadseg(segl) BE sys(25, segl)

AND callseg(file, a1, a2, a3, a4) = VALOF
$( LET res = 0
   LET segl = loadseg(file)
   LET s = start
   UNLESS segl=0 | globin(segl)=0 DO res := start(a1, a2, a3, a4)
   unloadseg(segl)
   start := s
   RESULTIS res
$)

AND deletefile(name) = sys(17, name)

AND renamefile(fromname, toname) = sys(18, fromname, toname)

AND mkobj(upb, fns, a, b) = VALOF // object making function
{ LET obj = getvec(upb)
  UNLESS obj=0 DO
  { !obj := fns
    InitObj#(obj, a, b)    // Send the InitObj message to the object
  }
  RESULTIS obj
}

