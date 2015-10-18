//
//
// MiniLisp
// ========
//
//
//        A. C. Norman.     November 1981
//
//  Modified by M. Richards  November 1983
//
// 26/11/95
//   Modified by MR to run under the Cintcode BCPL System

// Usage: e.g.     mlisp demo.lisp size 20000
 
 
 
// Numbers are in range #xE0000000 to #x1FFFFFFF
// Codepointers are #x40000000 to #x4FFFFFFF
// Identifiers are in range #x50000000 to #x50FFFFFF
// Lists are #x80000000 to #x80FFFFFF
 
 
 
MANIFEST $(
   p_maxnum=#x20000000
   p_minnum=#xE0000000
   p_code0=#x40000000   //Entrypoint of hard code, 0 args
   p_code1=#x41000000
   p_code2=#x42000000
   p_code3=#x43000000
   p_code4=#x44000000
   p_fcode=#x4f000000   //Entrypoint of special case hard code
   p_id   =#x50000000
   p_list =#x80000000
   gcbit  =#x20000000
   abits  =#x00FFFFFF
$)
 
GET "libhdr"
 
GLOBAL $(
   heapbase:150 // Start of free area
   heapend:151 // End ditto
   freechain:152

   // The following globals upto lastglobal must be consecutive for
   // the garbage collector to work.
   nil:153
   eofmarker:154 // Token handed back by READ to mark end of file
   lisptrue:155 // Lisp atom 'T'
   pname:156  // Lisp atom 'PNAME'
   leftparen:157
   rightparen:158
   dot:159
   unset:160  // 'INDEFINITE VALUE' marker
   posn:161 // Position along line being printed
   curchar:162
   oblist:163 //List of Lisp identifiers that must be recognized
   boffo:164  //Character assembly buffer
   boffp:165
   quotesymbol:166
   quote:167
   lambda:168
   startstackbase:169 // Used in error recovery
   restartlabel:170 //     for longjump
   arg1:171
   arg2:172
   arg3:173
   arg4:174
   function:175
   funarg:176
   lastglobal:177

   quitlabel:178
   progin:179
   stdin:180
   stdout:181
   tofile:182
   retcode:183

   main:200
   read:201
   mkquote:202
   readlist:203
   readsymbol:204
   symchar:205
   mknumber:206
   print:207
   terpri:208
   prin:209
   prinatom:210
   prinnumber:211
   prinhex:212
   princhar:213
   princhar1:214

   car:220
   cdr:221
   atom:222
   lispatom:223
   numberp:224
   lispnumberp:225
   symb:226
   cons:227
   lispeq:228
   equal:229
   lispequal:230

   mkatom:240
   stringtolist:241
   put:242
   lispget:243
   assoc:244
   reversewoc:245

   lisptimes:250
   checknumber:251
   lispquotient:252
   lispremainder:253
   lispplus:254
   lispdifference:255
   lispminus:256
   lispadd1:257
   lispsub1:258
   lispnull:259
   lispzerop:260
   lispsetq:261

   lisprdch:270
   lispwrch:271
   lispquit:272
   lispgreaterp:273
   lisplessp:274
   lisplist:275

   notimplemented:280
   lispquote:281
   de:282
   cond:283
   eval:284
   apply:285
   makequoted:286
   evlis:287
   spread:288
   pair:289
   error:290
   mixerror:291
   lispbacktrace:292
   userpostmortem:293
   reclaim:294
   mark:295
   marked:296
$)
 
 
// This Lisp is very crude, but demonstrates many of the essentials of
// the language. It is implemented assuming a 32-bit machine.
 
LET start() = VALOF
$( LET size, retcode = 20000, 0
   LET argv = VEC 50
   LET v = VEC 24

   IF rdargs("PROG,TO/K,SIZE/K", argv, 50)=0 DO
   $( writes("Bad arguments for MLISP*n")
      retcode := 20
      GOTO ret
   $)

   UNLESS argv!2=0 DO size := str2numb(argv!2)
   size := size & #x00FFFFF8

   heapbase := getvec(size)
   heapend := heapbase + size

   IF heapbase=0 DO
   $( writef("Unable to allocate %n words of heap*n", size)
      retcode := 20
      GOTO ret
   $)

   progin := 0
   tofile := 0
   stdin  := input()
   stdout := output()

   UNLESS argv!0=0 DO
   $( progin := findinput(argv!0)
      IF progin=0 DO
      $( writef("Unable to open file %s*n", argv!0)
         retcode := 20
         GOTO ret
      $)
   $)

   UNLESS argv!1=0 DO
   $( tofile := findoutput(argv!1)
      IF tofile=0 DO
      $( writef("Unable to open file %s*n", argv!1)
         retcode := 20
         GOTO ret
      $)
   $)

   boffo, boffp := v, 0
   arg1, arg2, arg3, arg4 := 0, 0, 0, 0
   posn, curchar := 0, 0

   UNLESS progin=0 DO selectinput(progin)
   UNLESS tofile=0 DO selectoutput(tofile)

   writef("*nDemo Lisp store size %n*n",size)

   main() // and call MAIN with a big vector as argument

ret:
   UNLESS progin=0 DO
   $( selectinput(progin)
      endread()
   $)
   UNLESS tofile=0 DO
   $( selectoutput(tofile)
      endwrite()
   $)
   UNLESS heapbase=0 DO freevec(heapbase)
   selectinput(stdin)
   RESULTIS retcode
$)
 
// MAIN sets up major Lisp datastructures, then runs a READ/EVAL/PRINT loop
 
AND main() BE
$( startstackbase := level()
   restartlabel := readevalprint
   quitlabel := quitlab
   freechain := 0
 
   // Build an initial freelist
   FOR i=heapbase|1 TO heapend-1 BY 2 DO
   $( !i, 1!i := 8888, freechain
      freechain := i+p_list
   $)
   oblist := 0
 
   // Since NIL is self-referential setting it up is a slightly
   // delicate procedure....
   nil := cons(0, 0) + p_id - p_list
   !(nil&abits) := nil; 1!(nil&abits) := nil
   oblist := cons(nil, nil)
   pname := 0
   pname := mkatom("pname", nil)
   1!(nil&abits) := cons(cons(pname,stringtolist("nil")),nil)
   1!(pname&abits):=cons(cons(pname,stringtolist("pname")),nil)
   // ... the rest of the predefined atoms are fairly easy.
   lisptrue := mkatom("T",nil); !(lisptrue&abits) := lisptrue
   unset := mkatom("INDEFINITE VALUE",nil); !(unset&abits):=unset
   !(pname&abits) := unset
   leftparen := mkatom("**LPAR**",unset)
   rightparen := mkatom("**RPAR**",unset)
   dot := mkatom("**DOT**",unset)
   quotesymbol := mkatom("**QUOTE**",unset)
   eofmarker := mkatom("**EOF**",unset)
   mkatom("car",p_code1+car)
   mkatom("cdr",p_code1+cdr)
   mkatom("cons",p_code2+cons)
   mkatom("atom",p_code1+lispatom)
   mkatom("eq",p_code2+lispeq)
   quote := mkatom("quote",p_fcode+lispquote)
   mkatom("cond",p_fcode+cond)
   mkatom("de",p_fcode+de)
   mkatom("equal",p_code2+lispequal)
   mkatom("numberp",p_code1+lispnumberp)
   mkatom("put",p_code3+put)
   mkatom("get",p_code2+lispget)
   mkatom("print",p_code1+print)
   mkatom("prin",p_code1+prin)
   mkatom("terpri",p_code0+terpri)
   mkatom("eval",p_code2+eval)
   lambda := mkatom("lambda",unset)
   mkatom("function",p_fcode+function)
   funarg := mkatom("funarg",unset)
   mkatom("read",p_code0+read)
   mkatom("assoc",p_code2+assoc)
   mkatom("reversewoc",p_code1+reversewoc)
 
   // the following were added by MR
   mkatom("times",p_fcode+lisptimes)
   mkatom("**",p_fcode+lisptimes)
   mkatom("quotient",p_code2+lispquotient)
   mkatom("/",p_code2+lispquotient)
   mkatom("remainder",p_code2+lispremainder)
   mkatom("%",p_code2+lispremainder)
   mkatom("plus",p_fcode+lispplus)
   mkatom("+",p_fcode+lispplus)
   mkatom("difference",p_code2+lispdifference)
   mkatom("minus",p_code1+lispminus)
   mkatom("-",p_code1+lispminus)
   mkatom("add1",p_code1+lispadd1)
   mkatom("1+",p_code1+lispadd1)
   mkatom("sub1",p_code1+lispsub1)
   mkatom("1-",p_code1+lispsub1)
   mkatom("null",p_code1+lispnull)
   mkatom("zerop",p_code1+lispzerop)
   mkatom("setq",p_fcode+lispsetq)
   mkatom("rdch",p_code0+lisprdch)
   mkatom("wrch",p_code1+lispwrch)
   mkatom("quit",p_code0+lispquit)
   mkatom("greaterp",p_code2+lispgreaterp)
   mkatom(">",p_code2+lispgreaterp)
   mkatom("lessp",p_code2+lisplessp)
   mkatom("<",p_code2+lisplessp)
   mkatom("list",p_fcode+lisplist)
 
 
 
readevalprint:
    curchar:='*n'
    posn:=0
    $( LET u=read()
       IF u=eofmarker BREAK
       print(eval(u,nil))
    $) REPEAT
quitlab:
$)
 
// READ can cope with parenthesized Lisp expressions, and with
// the shorthand 'X that stands for (QUOTE X)
// The hardest case is when it finds a '(', and then it calls READLIST.
 
AND read() = VALOF
$( LET k = readsymbol()
   IF k=leftparen RESULTIS readlist()
   IF k=rightparen | k=dot LOOP // Ignore excess ')' or dots
   IF k=quotesymbol RESULTIS mkquote(read())
   RESULTIS k
$) REPEAT
 
AND mkquote(x) = cons(quote,cons(x,nil))
 
// READLIST is coded here for conciseness and clarity, not for ultimate
// efficiency (the same is true of many functions in this Lisp!). It
// parses lists using a rather trivial recursive descent algorithm.
 
AND readlist() = VALOF
$( LET k = readsymbol()
   IF k=rightparen RESULTIS nil
   IF k=dot THEN
   $( k := read()
      UNLESS readsymbol()=rightparen DO error("Illegal syntax in dot notation")
      RESULTIS k
   $)
   TEST k=leftparen THEN k := readlist()
                    ELSE IF k=quotesymbol THEN k := mkquote(read())
   RESULTIS cons(k,readlist())
$)
 
// READSYMBOL is responsible for lexical analysis. It detects the special
// syntactic markers '(', ')', '.' and '''. It also does some processing
// on blanks, newlines and end of file. It reads decimal numbers and
// assembles identifiers into the buffer BOFFO.
 
AND readsymbol() = VALOF
$( LET isnum = TRUE

   SWITCHON curchar INTO
   $( CASE endstreamch: RESULTIS eofmarker

      CASE ';': curchar := rdch() REPEATUNTIL curchar='*n' |
                                              curchar=endstreamch
      CASE '*n':
      CASE ' ': curchar:=rdch(); LOOP
      CASE '(': curchar:=rdch(); RESULTIS leftparen
      CASE '.': curchar:=rdch(); RESULTIS dot
      CASE ')': curchar:=rdch(); RESULTIS rightparen
      CASE '*'':curchar:=rdch(); RESULTIS quotesymbol
      DEFAULT:  ENDCASE
   $)

   boffp:=0
 
   WHILE curchar='!' | symchar(curchar) DO
   $( UNLESS '0'<=curchar<='9' DO isnum := FALSE
      // ! escapes in non symbol characters
      IF curchar='!' DO curchar:=rdch()
      boffp := boffp+1
      boffo%boffp:=curchar
      curchar:=rdch()
   $)

   boffo%0:=boffp
   IF isnum DO RESULTIS mknumber(boffo)
   RESULTIS mkatom(boffo,unset)
$) REPEAT
 
 
// Test if a character is a letter or digit. Note that the code given here
// is adequate on an ASCII machine but is not proper on an EBCDIC one because
// the letters do not lie in a neat consecutive block of character codes.
// For present purposes I don't intend to worry about that!
 
AND symchar(c) = VALOF SWITCHON c INTO
$( DEFAULT:    RESULTIS TRUE

   CASE endstreamch:
   CASE '(':
   CASE ')':
   CASE '.':
   CASE ';':
   CASE '*n':
   CASE '*s':
   CASE '*p':
   CASE '*t': RESULTIS FALSE
$)
 
AND mknumber(chv) = VALOF
$( LET res = 0

   // Start of loop here
   FOR i = 1 TO chv%0 DO
   $( LET ch = chv%i
      UNLESS '0'<=ch<='9' DO error("bad number")
      // I am rather careful about overflow here, because an overlarge number
      // could look, in this Lisp's environment, like a symbol or pair or
      // something.
      IF res>=p_maxnum/10 DO error("numeric overflow on input")
      res := 10*res+ch-'0'
      IF res>=p_maxnum DO error("numeric overflow on input")
   $)

   RESULTIS res
$)
 
 
 
// PRINT is the Lisp PRINT function, and it is supposed to be able to
// display any structure that Lisp has, except possibly in the case of
// looped up lists.
 
AND print(a) = VALOF
$( prin(a)
   terpri()
   RESULTIS a
$)
 
// TERPRI is Lisp's name for what BCPL calls NEWLINE()
 
AND terpri() = VALOF
$( newline()
   posn:=0
   RESULTIS nil
$)
 
// PRIN is PRINT without the final TERPRI
 
AND prin(a) = VALOF
$( LET sep='('
   IF atom(a) THEN $( prinatom(a); RESULTIS a $)
   UNTIL atom(a) DO
   $( princhar1(sep)
      sep:=' '
      prin(car(a))
      a := cdr(a)
   $)
   UNLESS a=nil DO $( writes(" . "); prinatom(a) $)
   princhar1(')')
   RESULTIS a
$)
 
// The more interesting case in PRIN is when it has to deal with an atom
 
AND prinatom(x) BE
$( LET v=nil
   IF numberp(x) THEN
   $( IF x<0 THEN $( princhar('-'); x:=-x $)
      prinnumber(x)
      RETURN
   $)
   // Not being a symbol probably means X is a pointer to some binary code.
   UNLESS symp(x) DO
   $( princhar('<')
      prinhex(x>>24)
      princhar(':')
      prinnumber(x&abits)
      princhar('>')
      // That was not VERY informative, but at least it was something
      RETURN
   $)
   // Identifiers have their name stored under the tag PNAME on their
   // property list.
   v := lispget(x,pname)
   UNTIL v=nil DO
   $( LET w=car(v)
      princhar((w>>16)&#xFF) // Unpack 3 characters per word
      princhar((w>>8)&#xFF)
      princhar(w&#xFF)
      v:=cdr(v)
   $)
   RETURN
$)
 
// PRINTNUMBER prints in decimal, counting how many characters get printed on
// the line.
 
AND prinnumber(x) BE
$( IF x>=10 THEN prinnumber(x/10)
   princhar('0' + x REM 10)
$)
 
AND prinhex(x) BE
$( UNLESS 0<=x<16 DO $( prinhex(x>>4); x := x & 15 $)
   TEST x<=9 THEN princhar('0' + x)
             ELSE princhar('A' + x - 10)
$)
 
AND princhar(c) BE
$( IF c=0 RETURN // degenerate case of a null character
   IF c='*n' THEN $( newline(); posn:=0; RETURN $)
   TEST posn>=80 THEN $( newline(); posn:=1 $)
                 ELSE posn:=posn+1
   wrch(c)
$)
// PRINCHAR1 is called when I am not in the middle of printing a symbol,
// and it forces a line break if we are getting close to the end of the
// line (PRINCHAR only forces a newline when we hit the 80th column).
 
AND princhar1(c) BE
$( IF posn>=70 THEN $( newline(); posn:=0 $)
   princhar(c)
$)
 
 
 
// Some basic Lisp functions...
 
AND car(a) = VALOF
$( IF atom(a) THEN mixerror("Attempt to take CAR of the atom",a)
   RESULTIS !(a&abits)
$)
 
AND cdr(a) = VALOF
$( IF atom(a) THEN mixerror("Attempt to take CDR of the atom",a)
   RESULTIS 1!(a&abits)
$)
 
// Note that the atom test depends on conventions I am using in this
// Lisp about the storage of objects
 
AND atom(x) = x>=p_minnum
 
// ATOM is for calling from this BCPL program, and returns TRUE or FALSE
// LISPATOM is what the Lisp programmer sees, and it returns T or NIL
 
AND lispatom(x) = x>=p_minnum -> lisptrue , nil
 
AND numberp(x) = p_minnum <= x < p_maxnum
 
AND lispnumberp(x) = p_minnum <= x < p_maxnum -> lisptrue , nil
 
AND symp(x) = (x&#xF0000000)=p_id
 
 
 
AND cons(a,b) = VALOF
$( LET res=freechain
   LET k=res&abits
   freechain:=1!k
   !k,1!k:=a,b
   IF freechain=0 DO reclaim()
   RESULTIS res
$)
 
AND lispeq(a,b) = a=b -> lisptrue, nil // See what a cheap test EQ is!
 
AND equal(a,b) = VALOF
$( // And compare the complexity of EQUAL
   IF atom(a) RESULTIS a=b
   IF atom(b) RESULTIS FALSE
   IF equal(car(a),car(b)) RESULTIS equal(cdr(a),cdr(b))
   RESULTIS FALSE
$)
 
AND lispequal(a,b) = equal(a,b) -> lisptrue, nil
 
// MKATOM builds an identifier with name as specified by the BCPL
// string NAME. If the atom did not already exist it is created with
// default value VALUE.
 
AND mkatom(name,value) = VALOF
$( LET ah=stringtolist(name)
   AND w=oblist
   UNTIL atom(w) DO
   $( IF equal(lispget(car(w),pname),ah) RESULTIS car(w)
      w:=cdr(w)
   $)
   // Here the identifier is really a new one
   ah := cons(pname,ah)
   ah := cons(ah,nil)
   ah := cons(value,ah) + p_id - p_list
   oblist:=cons(ah,oblist)
   RESULTIS ah
$)
 
AND stringtolist(name) = VALOF
$( LET k=nil
   AND l=name%0
   AND w=0
   // Pack characters 3 to a Lisp pair
   FOR i=1 TO l DO
   $( w := (w<<8)\/name%i
      IF i REM 3 = 0 DO $( k := cons(w,k); w:=0 $)
   $)
   UNLESS l REM 3 = 0 DO
   $( UNTIL l REM 3 = 0 DO $( w := w<<8; l:=l+1 $)
      k := cons(w,k)
   $)
   // I have to call REVERSEWOC because the list of characters got built
   // up in the wrong order.
   RESULTIS reversewoc(k)
$)
 
 
// This Lisp function PUT
 
AND put(name,tag,value) = VALOF
$( LET pl=nil
   UNLESS symp(name) THEN mixerror("PUT called on a nonatomic argument",name)
   pl := 1!(name&abits)
   UNTIL atom(pl) DO
   $( UNLESS atom(car(pl)) IF tag=car(car(pl)) DO
      $( 1!(!(pl&abits)&abits) := value
         RESULTIS value
      $)
      pl := cdr(pl)
   $)
   1!(name&abits) := cons(cons(tag,value),1!(name&abits))
   RESULTIS value
$)
 
 
// The Lisp function GET
 
AND lispget(name,tag) = VALOF
$( LET pl=nil
   UNLESS symp(name) THEN mixerror("GET called on a nonatomic argument",name)
   pl := 1!(name&abits)
   UNTIL atom(pl) DO
   $( UNLESS atom(car(pl)) IF tag=car(car(pl)) RESULTIS cdr(car(pl))
      pl := cdr(pl)
   $)
   RESULTIS nil // Not found
$)
 
 
// The Lisp function ASSOC
 
AND assoc(tag,alist) = VALOF
$( UNTIL atom(alist) DO
   $( UNLESS atom(car(alist)) IF equal(tag,car(car(alist))) RESULTIS car(alist)
      alist := cdr(alist)
   $)
   RESULTIS nil // Not found
$)
 
 
// This REVERSE function overwrites the cells that made up its
// argument. This saves some store at the cost of some worry!
 
AND reversewoc(l) = VALOF
$( LET p=nil
   AND w=nil
   UNTIL atom(l) DO
   $( w:=cdr(l)
      1!(l&abits):=p
      p:=l
      l:=w
   $)
   RESULTIS p
$)
 
 
// functions added by MR
 
AND lisptimes(x, alist) = VALOF
$( LET a = 1
   UNTIL atom(x) DO
   $( LET v = eval(car(x), alist)
      checknumber(v)
      a := checknumber(a*v)
      x := cdr(x)
   $)
   RESULTIS a
$)
 
AND checknumber(x) = numberp(x) -> x, error("Bad number")
 
AND lispquotient(x, y) = VALOF
$( checknumber(x)
   checknumber(y)
   IF y=0 DO checknumber(nil)
   RESULTIS checknumber(x/y)
$)
 
AND lispremainder(x, y) = VALOF
$( checknumber(x)
   checknumber(y)
   IF y=0 DO checknumber(nil)
   RESULTIS checknumber(x REM y)
$)
 
AND lispplus(x, alist) = VALOF
$( LET a = 0
   UNTIL atom(x) DO
   $( LET v = checknumber(eval(car(x), alist))
      a := checknumber(a+v)
      x := cdr(x)
   $)
   RESULTIS a
$)
 
AND lispdifference(x, y) = checknumber(checknumber(x) - checknumber(y))
 
AND lispminus(x) = checknumber(-checknumber(x))
 
AND lispadd1(x) = checknumber(checknumber(x)+1)
 
AND lispsub1(x) = checknumber(checknumber(x)-1)
 
AND lispnull(x) = x=nil -> lisptrue, nil
 
AND lispzerop(x) = x=0 -> lisptrue, nil
 
AND lispsetq(x, alist) = VALOF
$( LET v = eval(car(cdr(x)), alist)
   LET a = car(x)
   IF a=lisptrue | a=nil | NOT atom(a) DO error("SETQ error")
   !(a&abits) := v
   RESULTIS v
$)
 
 
AND lisprdch() = rdch()
 
AND lispwrch(x) = VALOF $( wrch(x); RESULTIS x  $)
 
AND lispquit() = longjump(startstackbase, quitlabel)
 
AND lispgreaterp(x, y) = checknumber(x) > checknumber(y) -> lisptrue, nil
 
AND lisplessp(x, y) = checknumber(x) < checknumber(y) -> lisptrue, nil
 
AND lisplist(x, alist) = atom(x) -> nil,
                         cons(eval(car(x),alist), lisplist(cdr(x),alist))
 
AND notimplemented() BE error("Function not yet implemented")
 
// QUOTE is special in that it does not evaluate its argument
 
AND lispquote(x,alist) = car(x)
 
AND function(x,alist) = cons(funarg,
                             cons(car(x),
                                  cons(alist,nil)))
 
 
// DE is for defining functions
 
AND de(l,alist) = VALOF
$( LET name=car(l)
   UNLESS symp(name) DO mixerror("Illegal name in DE",name)
   !(name&abits):=cons(lambda,cdr(l))
   RESULTIS name
$)
 
// COND is Lisp's version of IF ... THEN ... ELSE.
 
AND cond(l,alist) = VALOF
$( UNTIL atom(l) DO
   $( LET w=car(l)
      UNLESS eval(car(w),alist)=nil RESULTIS eval(car(cdr(w)),alist)
      l:=cdr(l)
   $)
   RESULTIS nil
$)
 
 
// The function EVAL does almost all the work of evaluating Lisp expressions.
// the second argument is an association list holding an environment of
// name-value pairs.
 
AND eval(x,alist) = VALOF
$( LET fn=x // This variable in stackframe for use by BACKTRACE
   AND args=0

   IF atom(x) THEN
   $( IF symp(x) THEN
      $( LET v=assoc(x,alist) // Look name up in environment
         TEST v=nil THEN v:=!(x&abits) // Look in value cell
         ELSE v:=cdr(v)
         IF v=unset THEN mixerror("Unbound variable",x)
         RESULTIS v
      $)
      RESULTIS x
   $)
   fn:=car(x)

   $( IF atom(fn) DO
      $( IF symp(fn) THEN $( fn:=eval(fn,alist); LOOP $)
         IF (fn&#xF0000000)=#x40000000 GOTO binarycode
         mixerror("Illegal object used as function",fn)
      $)
      IF car(fn)=lambda GOTO applylambda
      IF car(fn)=funarg GOTO applyfunarg
      fn:=eval(fn,alist)
   $) REPEAT
 
binarycode:
   IF (fn&#x0f000000)=#x0f000000 RESULTIS (fn&abits)(cdr(x),alist)
   args := evlis(cdr(x),alist)
   $( LET nargs=(fn>>24)&#x0F
      fn := fn&abits
      spread(args,nargs)
      SWITCHON nargs INTO
      $( CASE 0: RESULTIS fn()
         CASE 1: RESULTIS fn(arg1)
         CASE 2: RESULTIS fn(arg1,arg2)
         CASE 3: RESULTIS fn(arg1,arg2,arg3)
         CASE 4: RESULTIS fn(arg1,arg2,arg3,arg4)
         DEFAULT: error("Improper function type")
      $)
   $)
 
 
applylambda:
   args := evlis(cdr(x),alist)
   alist:=pair(car(cdr(fn)),args,alist)
   RESULTIS eval(car(cdr(cdr(fn))),alist)
 
applyfunarg:
   RESULTIS apply(car(cdr(fn)),evlis(cdr(x),alist),car(cdr(cdr(fn))))
 
$)
 
// APPLY is used when the arguments of a function have already been
// evaluated: this means that the function (its first argument) must
// not be a special form (QUOTE, COND etc)
 
AND apply(fn,args,alist) = VALOF
$( // The version coded here is cheap and nasty - in a real system EVAL and
   // APPLY would share their work rather more evenly than is suggested here
   args := makequoted(args)
   RESULTIS eval(cons(fn,args),alist)
$)
 
AND makequoted(l) = VALOF
$( IF l=nil RESULTIS nil
   RESULTIS cons(mkquote(car(l)),makequoted(cdr(l)))
$)
 
// EVLIS is used for evaluating the arguments for a function.
 
AND evlis(l,alist) = VALOF
$( LET a, b = 0, 0
   IF atom(l) RESULTIS nil
   a := eval(car(l), alist)
   b := evlis(cdr(l), alist)
   RESULTIS cons(a, b)
$)
 
// SPREAD is a subfunction of EVAL used when calling a machine-code (in this
// Lisp a BCPL) function
 
AND spread(l,nargs) BE
$( LET p=@arg1
   arg1,arg2,arg3,arg4:=nil,nil,nil,nil
   FOR i=1 TO nargs DO
   $( IF l=nil THEN error("Not enough arguments for a function")
      !p:=car(l) // update global arg1, arg2, ...
      l:=cdr(l)
      p:=p+1
   $)
   UNLESS l=nil DO error("Too many arguments for a function")
   RETURN
$)
 
 
// PAIR adds some new bindings to the front of an association list L
 
AND pair(a,b,l) = VALOF
$( IF atom(a) & atom(b) RESULTIS l
   IF atom(a) DO error("Function called with too many arguments")
   IF atom(b) DO error("Function called with insufficient arguments")
   RESULTIS cons(cons(car(a),car(b)),pair(cdr(a),cdr(b),l))
$)
 
 
// Error recovery is, at present, rather coarse!
 
AND error(a) BE
$( writef("*n****** Error: %s*n",a)
   lispbacktrace()
   longjump(startstackbase,restartlabel)
$)
 
AND mixerror(a,l) BE
$( writef("*n****** Error: %s ",a)
   print(l)
   lispbacktrace()
   longjump(startstackbase,restartlabel)
$)
 
AND lispbacktrace() BE
$( LET p = level()>>2
   LET base = startstackbase>>2
   AND q, b = 0, 0

   $( // Do this until p=base
      q := p
      p := p!0>>2
      IF p=base BREAK
      b := p!2  // Function being executed
      IF b=error | b=mixerror LOOP
      TEST b=eval THEN
      $( LET x=p!3
         AND alist=p!4 // I could possibly print these as well as just X
         AND fn=p!5
         writes("Evaluating: ");
         print(x)
      $)
      ELSE $( LET n = q-p-3 // Number of args/local variables
              IF n<0 DO n:=0
              writef("in %s*n", (b>>2)-2)
              FOR j=1 TO n DO
             $( LET arg=p!(j+2)
                writef("Var %n: ",j)
                print(arg)
             $)
         $)
   $) REPEAT
   writes("End of backtrace*n")
$)
 
AND userpostmortem() BE
$( writes("*n**********Serious error detected*n")
   retcode := 30
   longjump(startstackbase,quitlabel)
$)
 
 
 
// The garbage collector used here is a classical mark-and-sweep one.
 
AND reclaim() BE
$( // First mark all cells reachable via the stack. Note that this code
   // necessarily depends on stack organization, so it will need adjustment
   // when this code gets moved from one machine to another
 
   LET p = level()>>2
   LET base = startstackbase>>2

   UNTIL p<=base DO
   $( LET q=p
      p:=p!0>>2
//writef("Marking stack from %i7 to %i7*n", p+3, q-1)
      FOR a=p+3 TO q-1 DO mark(!a)
   $)
 
   // Also mark all things refered to by (relevant) global variables
 
//writef("Marking globals from %i7 to %i7*n", @nil, @lastglobal-1)
   FOR a=@nil TO @lastglobal-1 DO mark(!a)
 
   // Now sweep over store looking for things that have not been marked.
 
   freechain:=0
   p:=0
   FOR i=heapbase|1 TO heapend-1 BY 2 DO
   $( LET v=!i
//writef("%x8: %x8 %x8   mark %i2*n", i, v, 1!i, marked(v))
      TEST marked(v)
      THEN !i:=v NEQV gcbit
      ELSE $( p:=p+1  // Count cells reclaimed
             !i,1!i:=9999,freechain
             freechain:=i+p_list
           $)
   $)
 
   writef("*n****** GC collected %n cells*n",p)
//longjump(startstackbase,quitlabel)
   IF p<100 DO
   $( writes("*n******Error: More store needed*n")
      retcode := 25
      longjump(startstackbase,quitlabel)
   $)
   RETURN
$)

 
AND mark(p) BE
$( //writef("mark: %x8*n", p)
   IF atom(p) & NOT symp(p) RETURN
   p := p&abits
   UNLESS heapbase<=p<=heapend  RETURN // Junk pointer?
   IF (p&1)=0 RETURN // Valid pointers are odd!
   $( LET carp=!p
      IF marked(carp) RETURN
      !p:=carp NEQV gcbit  // Mark this cell
      mark(carp)
      mark(1!p)
   $)
$)
 
//                             pos  pos   op   op    lst  lst  neg   neg
//                             000x 001x  010x 011x  100x 101x 110x  111x
AND marked(p) = (p>>29)!TABLE FALSE,TRUE,FALSE,TRUE,FALSE,TRUE,TRUE,FALSE
 
