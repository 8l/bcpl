// (C) Copyright 1978 Tripos Research Group
//     University of Cambridge
//     Computer Laboratory

// BCPL-SYN

GET ":COM.BCPL.BCPL"

MANIFEST
$(
// selectors
h1=0; h2=1; h3=2; h4=3; h5=4; h6=5

// basic symbols
s.be=89; s.end=90; s.lsect=91; s.rsect=92
s.get=93; s.into=98
s.to=99; s.by=100; s.do=101; s.or=102
s.vec=103; s.lparen=105; s.rparen=106

// AE tree operators
s.number=1; s.name=2; s.string=3
s.valof=6; s.lv=7; s.vecap=9
s.byteap=28
s.cond=37; s.comma=38; s.table=39
s.and=40; s.valdef=41; s.vecdef=42
s.commalist=43; s.fndef=44; s.rtdef=45
s.ass=50; s.resultis=53; s.colon=54
s.test=55; s.for=56; s.if=57; s.unless=58
s.while=59; s.until=60; s.repeat=61
s.repeatwhile=62; s.repeatuntil=63
s.loop=65; s.break=66
s.endcase=69; s.case=71; s.default=72
s.semicolonlist=73; s.let=74; s.manifest=75; s.static=79
s.semicolon=97

// AE tree and OCODE operators
s.true=4; s.false=5
s.rv=8; s.fnap=10
s.mult=11; s.div=12; s.rem=13; s.plus=14
s.minus=15; s.query=16; s.neg=17; s.abs=19
s.eq=20; s.ne=21; s.ls=22; s.gr=23; s.le=24; s.ge=25
s.not=30; s.lshift=31; s.rshift=32; s.logand=33
s.logor=34; s.eqv=35; s.neqv=36
s.needs=48; s.section=49
s.rtap=51; s.goto=52
s.return=67; s.finish=68
s.switchon=70; s.global=76

nametablesize=47
getmax=20
wordmax=255/bytesperword+1
$)

GLOBAL
$(
nextsymb:200

lookupword:201
declsyswords:202

rch:203
wrchbuf:204
rdtag:205
performget:206
readnumber:207
rdstrch:208

newvec:209
list1:210
list2:211
list3:212
list4:213
list5:214
list6:215
synreport:216

rdblockbody:217
rdseq:218
rdcdefs:219
rdsect:220
rnamelist:221
rname:222
ignore:223
checkfor:224

rbexp:225
rexp:226
rexplist:227
rdef:228

rbcom:229
rcom:230
makelist:231

symb:250
decval:251
wordnode:252
wordv:253
chbuf:254
chcount:255
nlpending:256
nulltag:257
getv:258
getp:259
nametable:260
rec.p:261
rec.l:262
$)

.

SECTION "SYN1"

GET ""

LET nextsymb() BE
$(1 nlpending := FALSE

$(2 IF testflags(1) DO synreport(0)
    SWITCHON ch INTO

$(s CASE '*N': nlpending := TRUE
    CASE '*T':
    CASE '*S': rch() REPEATWHILE ch='*S'
               LOOP

    CASE '0':CASE '1':CASE '2':CASE '3':CASE '4':
    CASE '5':CASE '6':CASE '7':CASE '8':CASE '9':
         symb := s.number
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
      $( LET c = ch
         rch()
         rdtag(c)
         symb := lookupword()
         IF symb=s.get DO $( performget(); LOOP  $)
         RETURN
      $)

    CASE '$': multichar("()", s.lsect, s.rsect, 0)
              IF symb=0 DO synreport(91)
              rdtag('$')
              lookupword()
              RETURN

    CASE '[':
    CASE '(': symb := s.lparen; BREAK
    CASE ']':
    CASE ')': symb := s.rparen; BREAK

    CASE '#':
       $( LET radix = 8
          rch()
          UNLESS '0'<=ch<='7' DO
          $( SWITCHON capitalch(ch) INTO
             $( DEFAULT: synreport(33)
                CASE 'B': radix := 2; ENDCASE
                CASE 'O': radix := 8; ENDCASE
                CASE 'X': radix := 16
             $)
             rch()
          $)
          readnumber(radix)
          symb := s.number
          RETURN
       $)


    CASE '?': symb := s.query;     BREAK
    CASE '+': symb := s.plus;      BREAK
    CASE ',': symb := s.comma;     BREAK
    CASE ';': symb := s.semicolon; BREAK
    CASE '@': symb := s.lv;        BREAK
    CASE '&': symb := s.logand;    BREAK
    CASE '=': symb := s.eq;        BREAK
    CASE '!': symb := s.vecap;     BREAK
    CASE '%': symb := s.byteap;    BREAK
    CASE '**':symb := s.mult;      BREAK

    CASE '|':
         multichar("|", 0, s.logor)
         UNLESS symb=0 RETURN

cmnt:    UNTIL ch='*N' | ch=endstreamch DO rch()
         LOOP

    CASE '/':
         multichar("\/**", s.logand, 0, -1, s.div)
         IF symb>0 RETURN
         IF symb=0 GOTO cmnt


         $( IF testflags(1) DO synreport(0)
            IF ch='**' DO
              $( rch()
                 IF ch='/' BREAK
                 LOOP $)
            IF ch=endstreamch DO synreport(63)
            rch()
         $) REPEAT

         rch()
         LOOP

    CASE '~': multichar("=", s.ne, s.not)
              RETURN

    CASE '\': multichar("/=", s.logor, s.ne, s.not)
              RETURN

    CASE '<': multichar("=<", s.le, s.lshift, s.ls)
              RETURN

    CASE '>': multichar("=>", s.ge, s.rshift, s.gr)
              RETURN

    CASE '-': multichar(">", s.cond, s.minus)
              RETURN

    CASE ':': multichar("=", s.ass, s.colon)
              RETURN


    CASE '"':
           $( LET i = 0
              rch()

              UNTIL ch='"' DO
                  $( IF i=255 DO synreport(34)
                     i := i + 1
                     wordv%i := rdstrch()  $)

              wordv%0 := i
              symb := s.string
              BREAK
           $)

    CASE '*'':rch()
              decval := rdstrch()
              symb := s.number
              UNLESS ch='*'' DO synreport(34)
              BREAK


    DEFAULT:  UNLESS ch=endstreamch DO
                $( ch := '*S'
                   synreport(94) $)
    CASE '.': IF getp=0 DO $( symb := s.end;    BREAK $)
              endread()
              getp := getp - 3
              sourcestream := getv!getp
              selectinput(sourcestream)
              linecount := getv!(getp+1)
              ch := getv!(getp+2)
              LOOP
$)s

$)2 REPEAT

    rch()
$)1

AND multichar(chars, a, b, c, d) BE
$( LET t = @chars
   LET i, lim = 1, chars%0
   rch()
   UNTIL i>lim DO
   $( IF ch=chars%i DO
      $( rch()
         BREAK
      $)
      i := i+1
   $)
   symb := t!i
$)
.

SECTION "SYN2"

GET ""

LET lookupword() = VALOF

$(1 LET hashval =
       VALOF $( LET res = wordv%0
                FOR i = 1 TO res DO
                     res := (res*13 +
                             capitalch(wordv%i)) & #X7FFF
                RESULTIS res REM nametablesize
             $)

    LET i = 0

    wordnode := nametable!hashval

    UNTIL wordnode=0 |
          compstring(wordnode+2, wordv)=0 DO
               wordnode := h2!wordnode

    IF wordnode=0 DO
      $( LET wordsize = wordv%0/bytesperword
         wordnode := newvec(wordsize+2)
         wordnode!0 := s.name
         wordnode!1 := nametable!hashval
         FOR i = 0 TO wordsize DO
            wordnode!(i+2) := wordv!i
         nametable!hashval := wordnode  $)

    RESULTIS h1!wordnode
$)1


AND declsyswords() BE
$(1 symb := TABLE
      s.and,s.abs,
      s.be,s.break,s.by,
      s.case,
      s.do,s.default,
      s.eq,s.eqv,s.or,s.endcase,
      s.false,s.for,s.finish,
      s.goto,s.ge,s.gr,s.global,s.get,
      s.if,s.into,
      s.let,s.lv,s.le,s.ls,s.logor,
          s.logand,s.loop,s.lshift,
      s.manifest,
      s.ne,s.not,s.neqv,s.needs,
      s.or,
      s.resultis,s.return,s.rem,s.rshift,s.rv,
      s.repeat,s.repeatwhile,s.repeatuntil,
      s.switchon,s.static,s.section,
      s.to,s.test,s.true,s.do,s.table,
      s.until,s.unless,
      s.vec,s.valof,
      s.while,
      0

    d("AND/ABS/*
      *BE/BREAK/BY/*
      *CASE/*
      *DO/DEFAULT/*
      *EQ/EQV/ELSE/ENDCASE/*
      *FALSE/FOR/FINISH/*
      *GOTO/GE/GR/GLOBAL/GET/*
      *IF/INTO/*
      *LET/LV/LE/LS/LOGOR/LOGAND/LOOP/LSHIFT//")

    d("MANIFEST/*
      *NE/NOT/NEQV/NEEDS/*
      *OR/*
      *RESULTIS/RETURN/REM/RSHIFT/RV/*
      *REPEAT/REPEATWHILE/REPEATUNTIL/*
      *SWITCHON/STATIC/SECTION/*
      *TO/TEST/TRUE/THEN/TABLE/*
      *UNTIL/UNLESS/*
      *VEC/VALOF/*
      *WHILE/*
      *$//")

     nulltag := wordnode
$)1


AND d(words) BE
$(1 LET i, length = 1, 0

    $( LET ch = words%i
       TEST ch='/'
           THEN $( IF length=0 RETURN
                   wordv%0 := length
                   lookupword()
                   h1!wordnode := !symb
                   symb := symb + 1
                   length := 0  $)
           ELSE $( length := length + 1
                   wordv%length := ch  $)
       i := i + 1
    $) REPEAT
$)1

.

SECTION "SYN3"

GET ""

LET rch() BE
    $( ch := rdch()
       IF ch='*N' | ch='*E' | ch='*C' | ch='*P' DO
         $( ch := '*N'
            linecount := linecount+1 $)
       chcount := chcount + 1
       chbuf!(chcount&63) := ch  $)

AND wrchbuf() BE
    $( writes("*N...")
       FOR p = chcount-63 TO chcount DO
                $( LET k = chbuf!(p&63)
                   IF k>0 DO wrch(k)  $)
       newline()  $)


AND rdtag(char) BE
    $( LET i = 1
       wordv%i := char

       $( UNLESS 'A'<=capitalch(ch)<='Z' \/
                 '0'<=ch<='9' \/
                  ch='.' BREAK
          i := i+1
          wordv%i := ch
          rch()
       $) REPEAT

       wordv%0 := i
    $)


AND performget() BE
    $( LET s = 0
       AND t = transchars
       transchars := FALSE
       nextsymb()
       transchars := t
       UNLESS symb=s.string & getp+2<=getmax DO
          synreport(97)
       TEST wordv%0=0 THEN
          s := findinput(fromfile)
       ELSE
       $( s := findinput(wordv)
          IF s=0 DO
            $( LET dir = currentdir
               currentdir := locatedir("SYS:G")
               s := findinput(wordv)
               freeobj(currentdir)
               currentdir := dir
            $)
       $)
       IF s=0 DO synreport(96,wordv)
       getv!getp := sourcestream
       getv!(getp+1) := linecount
       getv!(getp+2) := ch
       getp := getp + 3
       linecount := 1
       sourcestream := s
       selectinput(s)
       rch()
     $)


AND readnumber(radix) BE
    $( LET d = value(ch)
       decval := d
       IF d>=radix DO synreport(33)

       $( rch()
          d := value(ch)
          IF d>=radix RETURN
          decval := radix*decval + d  $) REPEAT
    $)


AND value(ch) = VALOF
    $( LET c = capitalch(ch)
       RESULTIS '0'<=c<='9' -> c-'0',
                'A'<=c<='F' -> c-'A'+10,
                100
    $)

AND rdstrch() = VALOF
$( LET k = ch

   rch()

   IF k='*N' DO synreport(34)

   IF k='**' THEN
   $( IF ch='*N' | ch='*S' | ch='*T' DO
      $( rch() REPEATWHILE ch='*N' | ch='*S' | ch='*T'
         UNLESS ch='**' DO synreport(34)
         rch()
         LOOP
      $)

      k := ch
      ch := capitalch(ch)

      IF ch='T' DO k := '*T'
      IF ch='S' DO k := '*S'
      IF ch='N' DO k := '*N'
      IF ch='E' DO k := '*E'
      IF ch='B' DO k := '*B'
      IF ch='C' DO k := '*C'
      IF ch='P' DO k := '*P'
      TEST ch='X' | '0'<=ch<='9'
        THEN $( LET r, n = 8, 3
                IF ch='X' DO
                $( r, n := 16, 2
                   rch()
                $)
                k := readoctalorhex(r, n)
                IF k>255 DO synreport(34)
                RESULTIS k  // don't translate *Xnn or *nnn
             $)
        ELSE rch()
  $)

  RESULTIS transchars -> charcode!k, k
$) REPEAT


AND readoctalorhex(radix,digits) = VALOF
$( LET answer = 0
   FOR j = 1 TO digits DO
      $( LET valch = value(ch)
         IF valch>=radix DO synreport(34)
         answer:=answer*radix + valch
         rch()
      $)
   RESULTIS answer
$)

.

SECTION "SYN4"

GET ""

LET start() =  VALOF
$(1 LET a = 0
    LET v = getvec(nametablesize+64+wordmax+getmax)
    err.p, err.l := level(), fail
    getp := 0
    chcount := 0
    treep := treevec+treesize
    treeq := treevec
    zeronode := list2(s.number, 0)
    IF v=0 | smallnumber(treevec) DO synreport(1)
    err.l := exit
    FOR i = 0 TO nametablesize+63 DO v!i := 0
    nametable := v
    chbuf := v+nametablesize
    wordv := chbuf+64
    getv := wordv+wordmax
    declsyswords()
    rch()
    IF ch=endstreamch GOTO exit
    rec.p, rec.l := err.p, l

l:  nextsymb()

 $( LET rprog() = VALOF
    $( LET op, a = symb, 0
       nextsymb()
       UNLESS symb=s.string DO synreport(95)
       a := rbexp()
       IF op=s.section DO
          writef("Section %S*N", a+1)
       RESULTIS list3(op, a,
          symb = s.needs -> rprog(), rdblockbody())
    $)

    a := symb=s.section | symb=s.needs -> rprog(),
         rdblockbody()

    UNLESS symb=s.end DO synreport(99)
  $)

    unrdch()
exit:
    freevec(v)
fail:
    UNLESS a=0 DO writef("Tree size %N*N",
                     treesize+treevec-treep)
    RESULTIS a
$)1


AND newvec(n) = VALOF
    $( treep := treep - n - 1;
       IF treep-treeq<0 DO synreport(98)
       RESULTIS treep  $)

AND list1(x) = VALOF
    $( LET p = newvec(0)
       p!0 := x
       RESULTIS p  $)

AND list2(x, y) = VALOF
    $( LET p = newvec(1)
       p!0, p!1 := x, y
       RESULTIS p   $)

AND list3(x, y, z) = VALOF
    $( LET p = newvec(2)
       p!0, p!1, p!2 := x, y, z
       RESULTIS p     $)

AND list4(x, y, z, t) = VALOF
    $( LET p = newvec(3)
       p!0, p!1, p!2, p!3 := x, y, z, t
       RESULTIS p   $)

AND list5(x, y, z, t, u) = VALOF
    $( LET p = newvec(4)
       p!0, p!1, p!2, p!3, p!4 := x, y, z, t, u
       RESULTIS p   $)

AND list6(x, y, z, t, u, v) = VALOF
    $( LET p = newvec(5)
       p!0, p!1, p!2, p!3, p!4, p!5 := x, y, z, t, u, v
       RESULTIS p  $)


AND makelist(k, n) = valof
$( let q = treeq + n
   IF treep-treeq<2 do synreport(98)
   UNTIL q=treeq DO
   $( q, treep := q-1, treep-1
      !treep := !q
   $)
   treep := treep - 2
   h1!treep, h2!treep := k, n
   resultis treep
$)

AND synreport(n, a) BE
$( LET s = 0
   s := VALOF SWITCHON n INTO
   $( DEFAULT: a := n
               RESULTIS "Error %N"
      CASE  0: rc := 20
               writes("****BREAK - ")
               GOTO brk
      CASE  1: rc := 20
               RESULTIS "Run out of store - "
      CASE  6: RESULTIS "'$(' expected"
      CASE  7: RESULTIS "'$)' expected"
      CASE  8:CASE 40:CASE 43:
               RESULTIS "Name expected"
      CASE  9: RESULTIS "Untagged '$)' mismatch"
      CASE 15:CASE 19:CASE 41:
               RESULTIS "')' missing"
      CASE 30: RESULTIS "Bad conditional expression"
      CASE 32: RESULTIS "Invalid expression"
      CASE 33: RESULTIS "Bad number"
      CASE 34: RESULTIS "Bad string*
                        * or character constant"
      CASE 42: RESULTIS "Bad procedure heading"
      CASE 44:CASE 45:
               RESULTIS "Bad declaration"
      CASE 50: RESULTIS "Unexpected ':'"
      CASE 51: RESULTIS "Invalid command"
      CASE 54: RESULTIS "'ELSE' expected"
      CASE 57:CASE 58:
               RESULTIS "Bad FOR loop"
      CASE 60: RESULTIS "'INTO' expected"
      CASE 61:CASE 62:
               RESULTIS "':' expected"
      CASE 63: RESULTIS "'**/' missing"
      CASE 91: RESULTIS "'$'  out of context"
      CASE 94: RESULTIS "Illegal character"
      CASE 95: RESULTIS "Illegal section name"
      CASE 96: rc := 20
               RESULTIS "Can't GET %S - "
      CASE 97: RESULTIS "Bad GET directive"
      CASE 98: rc := 20
               RESULTIS "Program too large - "
      CASE 99: RESULTIS "Incorrect termination"
    $)

   IF rc<10 DO rc := 10
   reportcount := reportcount+1
   writef("*NError near line %N:  ", linecount)
   writef(s, a)
   IF reportcount>reportmax DO
   $( writes("*NToo many errors - ")
      rc := 20 $)
brk:IF rc>=20 DO
    $( writes("Compilation aborted*N")
       UNTIL getp=0 DO
       $( endread()
          getp := getp-3
          sourcestream := getv!getp
          selectinput(sourcestream)
       $)
       longjump(err.p,err.l)
    $)

   wrchbuf()
   nlpending := FALSE

   UNTIL symb=s.lsect | symb=s.rsect |
         symb=s.let | symb=s.and |
         symb=s.end | nlpending DO nextsymb()
   longjump(rec.p, rec.l)
$)

.

SECTION "SYN5"

GET ""

LET rdblockbody() = VALOF
$(1 LET p, l = rec.p, rec.l
    LET a = 0
    LET ptr = @a

 $( LET op = 0
    rec.p, rec.l := level(), recover
    ignore(s.semicolon)

    SWITCHON symb INTO
    $(s CASE s.manifest:
        CASE s.static:
        CASE s.global:
                op := symb
                nextsymb()
                !ptr := rdsect(rdcdefs)
                ENDCASE

        CASE s.let:
                nextsymb()
                !ptr := rdef()
       recover:
             $( LET qtr = ptr
                WHILE symb=s.and DO
                  $( nextsymb()
                     !qtr := list3(s.and, !qtr, rdef())
                     qtr := @h3!(!qtr)
                  $)
                op := s.let
                ENDCASE

        DEFAULT:!ptr := rdseq()
                UNLESS symb=s.rsect | symb=s.end DO
                          synreport(51)
        CASE s.rsect: CASE s.end:
                BREAK
    $)s
    !ptr := list3(op, !ptr, 0)
    ptr := @h3!(!ptr)
 $) REPEAT

    rec.p, rec.l := p, l
    RESULTIS a
$)1

AND rdseq() = VALOF
$( LET n = 0
   LET q = treeq

   $( ignore(s.semicolon)
      !treeq := rcom()
      treeq, n := treeq+1, n+1
   $) REPEATUNTIL symb=s.rsect | symb=s.end

   treeq := q
   IF n=1 RESULTIS !q
   IF n=2 RESULTIS list3(s.semicolon, q!0, q!1)
   RESULTIS makelist(s.semicolonlist, n)
$)


AND rdcdefs() = VALOF
$( LET q, n = treeq, 0
   LET p, l = rec.p, rec.l

   rec.p, rec.l := level(), rec

   $( !treeq := rname()
      UNLESS symb=s.eq | symb=s.colon DO
             synreport(45)
      nextsymb()
      treeq!1 := rexp(0)
      treeq, n := treeq+2, n+2
rec:  ignore(s.semicolon)
   $) REPEATWHILE symb=s.name

   rec.p, rec.l := p, l
   treeq := q
   RESULTIS makelist(s.semicolonlist, n)
$)

AND rdsect(r) = VALOF
    $(  LET tag, a = wordnode, 0
        checkfor(s.lsect, 6)
        a := r()
        UNLESS symb=s.rsect DO synreport(7)
        TEST tag=wordnode
             THEN nextsymb()
             ELSE IF wordnode=nulltag DO
                      $( symb := 0
                         synreport(9)  $)
        RESULTIS a   $)


AND rnamelist() = VALOF
$( LET q, n = treeq, 0

   $( !treeq := rname()
      treeq, n := treeq+1, n+1
      UNLESS symb=s.comma BREAK
      nextsymb()
   $) REPEAT

   treeq := q
   IF n=1 RESULTIS !q
   IF n=2 RESULTIS list3(s.comma, q!0, q!1)
   RESULTIS makelist(s.commalist, n)
$)


AND rname() = VALOF
    $( LET a = wordnode
       checkfor(s.name, 8)
       RESULTIS a  $)

AND ignore(item) BE IF symb=item DO nextsymb()

AND checkfor(item, n) BE
      $( UNLESS symb=item DO synreport(n)
         nextsymb()  $)

.

SECTION "SYN6"

GET ""

LET rbexp() = VALOF
$(1 LET a, op = 0, symb

    SWITCHON symb INTO

 $( DEFAULT: synreport(32)

    CASE s.query:
        nextsymb()
        RESULTIS list1(s.query)

    CASE s.true:
    CASE s.false:
    CASE s.name:
        a := wordnode
        nextsymb()
        RESULTIS a

    CASE s.string:
     $( LET wordsize = wordv%0/bytesperword
        a := newvec(wordsize+1)
        a!0 := s.string
        FOR i = 0 TO wordsize DO a!(i+1) := wordv!i
        nextsymb()
        RESULTIS a
     $)

    CASE s.number:
     $( LET k = decval
        nextsymb()
        IF k=0 RESULTIS zeronode
        IF smallnumber(k) RESULTIS k
        RESULTIS list2(s.number, k)
     $)

    CASE s.lparen:
        nextsymb()
        a := rexp(0)
        checkfor(s.rparen, 15)
        RESULTIS a

    CASE s.valof:
        nextsymb()
        RESULTIS list2(s.valof, rcom())

    CASE s.vecap: op := s.rv
    CASE s.lv:
    CASE s.rv:    nextsymb()
                  RESULTIS list2(op, rexp(37))

    CASE s.plus:  nextsymb()
                  RESULTIS rexp(34)

    CASE s.minus: nextsymb()
                  a := rexp(34)
                  IF smallnumber(a) RESULTIS list2(s.number, -a)
                  RESULTIS list2(s.neg, a)

    CASE s.not:   nextsymb()
                  RESULTIS list2(s.not, rexp(24))

    CASE s.abs:   nextsymb()
                  RESULTIS list2(s.abs, rexp(35))

    CASE s.table: nextsymb()
                  RESULTIS list2(s.table, rexplist())
$)1


AND rexp(n) = VALOF
$(1 LET a = rbexp()

    LET b, c, p, q = 0, 0, 0, 0

$(2 LET op = symb

    IF nlpending RESULTIS a

    SWITCHON op INTO

$(s DEFAULT: RESULTIS a

    CASE s.lparen: nextsymb()
                   b := 0
                   UNLESS symb=s.rparen DO b := rexplist()
                   checkfor(s.rparen, 19)
                   a := list3(s.fnap, a, b)
                   LOOP

    CASE s.vecap:  p := 40; GOTO lassoc

    CASE s.byteap: p := 36; GOTO lassoc

    CASE s.rem:CASE s.mult:CASE s.div:
                   p := 35; GOTO lassoc

    CASE s.plus:CASE s.minus:
                   p := 34; GOTO lassoc

    CASE s.eq:CASE s.ne:
    CASE s.le:CASE s.ge:
    CASE s.ls:CASE s.gr:
           IF n>=30 RESULTIS a

           $(r nextsymb()
               b := rexp(30)
               a := list3(op, a, b)
               TEST c=0 THEN c :=  a
                        ELSE c := list3(s.logand, c, a)
               a, op := b, symb
           $)r REPEATWHILE s.eq<=op<=s.ge

           a := c
           LOOP

    CASE s.lshift:CASE s.rshift:
                   p, q := 25, 30; GOTO dyadic

    CASE s.logand: p := 23; GOTO lassoc

    CASE s.logor:  p := 22; GOTO lassoc

    CASE s.eqv:CASE s.neqv:
                   p := 21; GOTO lassoc

    CASE s.cond:
            IF n>=13 RESULTIS a
            nextsymb()
            b := rexp(0)
            checkfor(s.comma, 30)
            a := list4(s.cond, a, b, rexp(0))
            LOOP

    lassoc: q := p

    dyadic: IF n>=p RESULTIS a
            nextsymb()
            a := list3(op, a, rexp(q))
            LOOP
$)s
$)2 REPEAT
$)1

AND rexplist() = VALOF
$( LET a = 0
   LET n = 0
   LET q = treeq

   $( !treeq := rexp(0)
      treeq, n := treeq+1, n+1
      UNLESS symb=s.comma BREAK
      nextsymb()
   $) REPEAT

   treeq := q
   IF N=1 RESULTIS q!0
   IF n=2 RESULTIS list3(s.comma, q!0, q!1)
   RESULTIS makelist(s.commalist, n)
$)


AND rdef() = VALOF
$(1 LET n = rnamelist()

    SWITCHON symb INTO

 $( CASE s.lparen:
      $( LET a = 0
         nextsymb()
         UNLESS h1!n=s.name DO synreport(40)
         IF symb=s.name DO a := rnamelist()
         checkfor(s.rparen, 41)

         IF symb=s.be DO
           $( nextsymb()
              RESULTIS list5(s.rtdef, n, a, rcom(), 0) $)

         IF symb=s.eq DO
           $( nextsymb()
              RESULTIS list5(s.fndef, n, a, rexp(0), 0) $)

         synreport(42)  $)

    DEFAULT:
         synreport(44)

    CASE s.eq:
         nextsymb()
         IF symb=s.vec DO
           $( nextsymb()
              UNLESS h1!n=s.name DO synreport(43)
              RESULTIS list3(s.vecdef, n, rexp(0)) $)

         RESULTIS list3(s.valdef, n, rexplist())
$)1

.

SECTION "SYN7"

GET ""

LET rbcom() = VALOF
$(1 LET a, b, op = 0, 0, symb

    SWITCHON symb INTO
 $( DEFAULT: RESULTIS 0

    CASE s.name:CASE s.number:CASE s.string:
    CASE s.true:CASE s.false:
    CASE s.lv:CASE s.rv:CASE s.vecap:
    CASE s.lparen:
            a := rexplist()

            IF symb=s.ass  THEN
               $( op := symb
                  nextsymb()
                  RESULTIS list3(op, a, rexplist())  $)

            IF smallnumber(a) DO synreport(51)

            IF symb=s.colon DO
               $( UNLESS h1!a=s.name DO synreport(50)
                  nextsymb()
                  RESULTIS list4(s.colon, a, rbcom(),0) $)

            IF h1!a=s.fnap DO
                 $( h1!a := s.rtap
                    RESULTIS a  $)

            synreport(51)
            RESULTIS a

    CASE s.goto:CASE s.resultis:
            nextsymb()
            RESULTIS list2(op, rexp(0))

    CASE s.if:CASE s.unless:
    CASE s.while:CASE s.until:
            nextsymb()
            a := rexp(0)
            ignore(s.do)
            RESULTIS list3(op, a, rcom())

    CASE s.test:
            nextsymb()
            a := rexp(0)
            ignore(s.do)
            b := rcom()
            checkfor(s.or, 54)
            RESULTIS list4(s.test, a, b, rcom())

    CASE s.for:
        $(  LET i, j, k = 0, 0, 0
            nextsymb()
            a := rname()
            checkfor(s.eq,57)
            i := rexp(0)
            checkfor(s.to, 58)
            j := rexp(0)
            IF symb=s.by DO $( nextsymb()
                               k := rexp(0)  $)
            ignore(s.do)
            RESULTIS list6(s.for, a, i, j, k, rcom())  $)

    CASE s.loop:CASE s.break:CASE s.endcase:
    CASE s.return:CASE s.finish:
            a := wordnode
            nextsymb()
            RESULTIS a

    CASE s.switchon:
            nextsymb()
            a := rexp(0)
            checkfor(s.into, 60)
            RESULTIS list3(s.switchon, a, rdsect(rdseq))

    CASE s.case:
            nextsymb()
            a := rexp(0)
            checkfor(s.colon, 61)
            RESULTIS list3(s.case, a, rbcom())

    CASE s.default:
            nextsymb()
            checkfor(s.colon, 62)
            RESULTIS list2(s.default, rbcom())

    CASE s.lsect:
            RESULTIS rdsect(rdblockbody)
$)1


AND rcom() = VALOF
$(1 LET a = rbcom()

    IF a=0 DO synreport(51)

    WHILE symb=s.repeat | symb=s.repeatwhile |
                          symb=s.repeatuntil DO
          $( LET op = symb
             nextsymb()
             TEST op=s.repeat
                 THEN a := list2(op, a)
                 ELSE a := list3(op, a, rexp(0))   $)

    RESULTIS a
$)1


