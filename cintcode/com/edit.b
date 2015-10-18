// (C) Copyright 1978 Tripos Research Group
//     University of Cambridge
//     Computer Laboratory

SECTION "EDIT"

GET "libhdr"

MANIFEST
$(
smax=80;  amax=80
gmax=10;  cfmax=10
fmin=5;   fmax=30
lmax=120; pmax=20

s_in=0; s_out=1

// file offsets
f_lk=0;   f_sp=1
f_lc=2;   f_ex=3
f_io=4;   f_fn=5

// command file offsets
cf_el=0;  cf_sp=1
cf_cp=2;  cf_cl=3
cf_cb=4

// line offsets
l_next=0; l_prev=1
l_numb=2; l_cch=3
l_len=4;  l_buf=4

// error codes
err_uc=0;   err_udc=1
err_bra=2;  err_cntx=3
err_pm=4;   err_num=5
err_line=6; err_fnx=7
err_str=8;  err_nom=9
err_rep=10; err_noin=11
err_nopr=12;err_cr=13
err_glob=14;err_ff=15
err_cf=16;  err_ffa=17
err_arg=18; err_opt=19
err_rn=20;  err_gv=21
err_cfv=22; err_qw=23
err_brk=24

// repeatable double letter commands
c_sa = ('S'<<8) | 'A'
c_sb = ('S'<<8) | 'B'
c_dl = ('D'<<8) | 'L'
c_df = ('D'<<8) | 'F'
c_dt = ('D'<<8) | 'T'
c_pa = ('P'<<8) | 'A'
c_pb = ('P'<<8) | 'B'
c_nc = ('N'<<8) | 'C'

$)

GLOBAL
$(
isinteractive:151
openstreams:152
closestreams:153
rewind:154
windup:155
closeout:156
closein:157
newvec:158
discardvec:159

edit:160

checkvalidchar:161
checkspaceornl:162
readcommline:163
commrdch:164
uncommrdch:165
nextcomm:166
readplusminus:167
commreadn:168
numarg:169
readcontext:170
abe_args:171
dps_arg:172
lf_arg:173
readfiletitle:174
addfilespec:175
findfilespec:176
losefilespec:177
closefile:178
changecom:179
revertcom:180
changeout:181
changein:182

renumber:183
split:184
concatenate:185
insert:186
readline:187
writeline:188
getline:189
putline:190
nextline:191
prevline:192
move:193
ver:194
verline:195

error:196
truncate:197
expand:198
compress:199
condense:200
incrementp:201
subst:202
index:203
readglobal:204
deleteglobal:205
findglobal:206
changeglobal:207


e_to:220
e_from:221
e_work:222
e_ver:223
e_with:224
e_workout:225
e_workin:226
e_backup:227
currentoutput:228
currentinput:229
primaryoutput:230
primaryinput:231
textin:232
textout:233
edits:234
verout:235
cfstack:236
cfsp:237
maxlinel:238
maxplines:239
freelines:240
oldestline:241
currentline:242
current:243
pointer:244
expanded:245
condensed:246
exhausted:247
quiet:248
deleting:249
repeating:250
unchanged:251
nosubs:252
ceiling:253
linev:254
linel:255
commbuf:256
commpoint:257
commlinel:258
comm:259
delim:260
cch:261
sw_comm:262
str_comm:263
lf_comm:264
str_match:265
str_repl:266
lf_match:267
z_match:268
globcount:269
g_match:270
g_repl:271
verifying:272
uppercase:273
trailing:274
filelist:275
veclist:276
opened:277
zerolevel:278
editlevel:279
quitlevel:280
editlab:281
quitlab:282
rc:283
$)


LET start() BE
 $( LET argv = VEC amax
    LET cvec = VEC cfmax
    LET gvec = VEC 2*gmax
    LET iovec = VEC 2*fmin
    LET oldoutput = output()
    LET oldinput = input()

    rc := 0
    opened := FALSE
    quitlevel := level()
    zerolevel := 0
    verout := oldoutput
    edits := oldinput
    commlinel := 0
    veclist := 0
    filelist := 0
    cfsp := 0

    IF rdargs("FROM/A,TO,WITH/K,VER/K,OPT/K",argv,amax)=0
       DO error(err_arg)

    e_from := argv!0
    e_to := argv!1
    e_work := e_to
    e_with := argv!2
    e_ver := argv!3
    e_workin := "TEMP1"
    e_workout := "TEMP2"
    e_backup := "EDITBACKUP"
    IF e_to=0 DO $( e_to := e_from
                    e_work := e_workin
                    e_workin := e_workout
                    e_workout := e_work
                 $)
    UNLESS e_ver=0 DO $( LET s = findoutput(e_ver)
                         IF s=0 DO error(err_ffa,e_ver)
                         verout := s
                      $)
    UNLESS e_with=0 DO $( LET s = findinput(e_with)
                          IF s=0 DO error(err_ffa,e_with)
                          edits := s
                       $)

    maxlinel := lmax
    maxplines := pmax
    UNLESS argv!4=0 DO
    $( LET opts = argv!4
       LET i = 1
       LET rdn(opts, lvi) = VALOF
       $( LET n = 0
          LET i = !lvi+1
          LET c = opts%i
          WHILE i<=opts%0 & '0'<=c<='9' DO $( n := n*10+c-'0'
                                              i := i+1
                                              c := opts%i
                                           $)
          !lvi := i-1
          RESULTIS n
       $)

       WHILE i<=opts%0 DO
       $( SWITCHON capitalch(opts%i) INTO
          $( CASE 'W': maxlinel := rdn(opts, @i)
                       ENDCASE

             CASE 'P': maxplines := rdn(opts, @i)
                       ENDCASE

          $)
          i := i+1
       $)

       UNLESS maxlinel>0 & maxplines>0 DO
          error(err_opt)
    $)

    freelines := newvec((1+l_buf+maxlinel)*(maxplines+2))
    freelines!l_next := 0
    FOR i = 1 TO maxplines+1 DO
    $( LET l = freelines+(1+l_buf+maxlinel)*i
       LET n = freelines!l_next
       freelines!l_next := l
       l!l_next := n
    $)

    commbuf := newvec(maxlinel/bytesperword)
    str_match := newvec(smax)
    str_repl := newvec(smax)
    lf_match := newvec(smax)
    z_match := newvec(smax)

    g_match := gvec
    g_repl := gvec+gmax
    cfstack := cvec
    primaryoutput := iovec
    primaryinput := iovec+fmin

    cfstack!0 := edits
    verifying := isinteractive(edits)
    selectoutput(verout)
    trailing, uppercase := FALSE, TRUE
    str_comm, lf_comm := c_nc, c_nc
    z_match!0, z_match!1 := 1, 'Z'

    openstreams()
    IF verifying DO writes("EDIT ready*N")
    edit(0)

quitlab:
    UNLESS verout=oldoutput DO closeout(verout)
    UNLESS edits=oldinput DO closein(edits)
    UNTIL filelist=0 DO losefilespec(filelist)
    UNTIL veclist=0 DO discardvec(veclist+1)
    stop(rc)
 $)


AND isinteractive(s) = s!scb_type<=0


AND openstreams() BE
 $( textin := findinput(e_from)
    IF textin=0 DO error(err_ffa,e_from)
    textout := findoutput(e_work)
    IF textout=0 DO $( closein(textin)
                       error(err_ffa,e_work)
                    $)
    primaryoutput!f_sp := textout
    primaryinput!f_sp := textin
    primaryinput!f_lc := 0
    primaryinput!f_ex := FALSE
    currentoutput := primaryoutput
    currentinput := primaryinput
    currentline := freelines
    freelines := currentline!l_next
    oldestline := currentline
    currentline!l_next := 0
    currentline!l_prev := 0
    linev := currentline+l_buf
    expanded :=  FALSE
    linel, pointer := 0, 0
    cch := endstreamch
    current, exhausted := 0, FALSE
    unchanged, nosubs := TRUE, TRUE
    globcount := 0
    ceiling := maxint
    opened := TRUE
 $)


AND closestreams() BE
 $( opened := FALSE
    UNTIL oldestline=0 DO writeline()
    UNLESS currentoutput=primaryoutput DO
       losefilespec(currentoutput)
    UNLESS currentinput=primaryinput DO
       losefilespec(currentinput)
    closeout(primaryoutput!f_sp)
    closein(primaryinput!f_sp)
 $)


AND rewind() BE
 $( e_from := e_work
    e_work := e_workin
    e_workin := e_workout
    e_workout := e_work
 $)


AND windup() BE
    UNLESS e_work=e_to DO
    $( renamefile(e_to,e_backup)
       IF renamefile(e_work,e_to)=0 DO
          error(err_rn,e_work,e_to)
       deletefile(e_workin)
    $)


AND closeout(s) BE UNLESS s=0 DO
 $( LET o = output()
    selectoutput(s)
    endwrite()
    UNLESS o=s DO selectoutput(o)
 $)


AND closein(s) BE UNLESS s=0 DO
 $( LET i = input()
    selectinput(s)
    endread()
    UNLESS i=s DO selectinput(i)
 $)


AND newvec(n) = VALOF
 $( LET v = getvec(n+1)
    IF v=0 DO error(err_gv)
    !v := veclist
    veclist := v
    RESULTIS v+1
 $)


AND discardvec(v) BE
 $( LET p = @veclist
    UNTIL !p=0 DO
    $( LET t = !p
       IF t=v-1 DO
       $( !p := !t
          freevec(t)
          BREAK
       $)
       p := t
    $)
 $)


LET edit(n) BE
 $( LET counting = FALSE
    LET count, countp = 0, 0

editlab:
    IF n=0 DO
    $( editlevel := level()
       readcommline()
    $)
    counting := FALSE

    // repeat loop to get commands
    $( LET e, s, c, p, q = 0, 0, 0, 0, 0

       IF intflag() DO error(err_brk)
       nextcomm()
       quiet := NOT verifying
       deleting, repeating := FALSE, FALSE

 sw:   sw_comm := comm
       SWITCHON comm INTO

       $( DEFAULT:
             error(err_uc, comm)

          CASE '0':CASE '1':CASE '2':CASE '3':CASE '4':
          CASE '5':CASE '6':CASE '7':CASE '8':CASE '9':
             count := commreadn()
             IF count=0 & zerolevel=0 DO
                zerolevel := editlevel
             countp := commpoint
             counting := TRUE
          CASE '*S':
             LOOP

          CASE '[':CASE '(':
             edit(n+1)
             ENDCASE

          CASE ']':CASE ')':
             UNLESS n>0 DO error(err_bra)
             RETURN

          CASE endstreamch:
             UNLESS cfsp=0 DO
             $( revertcom()
                RETURN
             $)
          CASE 'W': CASE 'Q':
             nextcomm()
             UNLESS comm='*N' | comm=endstreamch DO
                error(err_qw,sw_comm)
             UNLESS sw_comm='Q' DO move(maxint)
             closestreams()
             UNLESS sw_comm='Q' DO windup()
             UNTIL cfsp=0 DO revertcom()
             longjump(quitlevel, quitlab)

          CASE '**':
             move(maxint)
             closestreams()
             rewind()
             openstreams()
             ENDCASE

          CASE '|':CASE '\':
             UNTIL comm='*N' DO commrdch()
          CASE '*N':
    nl:      UNLESS n=0 DO error(err_bra)
             IF isinteractive(edits) DO
                TEST quiet | unchanged THEN
                   newline()
                ELSE
                   ver(sw_comm, '*E')
             GOTO editlab

          CASE '?':CASE '!':
             nextcomm()
             IF comm='*N' & isinteractive(edits) DO
             $( quiet, unchanged := FALSE, FALSE
                GOTO nl
             $)
             uncommrdch()
             ver(sw_comm, '*N')
             ENDCASE

          CASE '>':
             incrementp()
             ENDCASE

          CASE '<':
             condense()
             UNLESS pointer=0 DO unchanged := FALSE
             pointer := 0
             ENDCASE

          CASE ':':
             UNLESS pointer=linel DO unchanged := FALSE
             pointer := linel
             ENDCASE

          CASE '#':
             IF incrementp() DO
             $( linev!pointer := -1
                condensed := FALSE
                nosubs := FALSE
             $)
             ENDCASE

          CASE '_':
             IF incrementp() DO
             $( linev!pointer := '*S'
                nosubs := FALSE
             $)
             ENDCASE

          CASE '%':
             IF incrementp() DO
             $( LET a = linev+pointer
                LET value = !a
                IF 'a'<=value<='z' DO
                $( !a := value+'A'-'a'
                   nosubs := FALSE $)
             $)
             ENDCASE

          CASE '$':
             IF incrementp() DO
             $( LET a = linev+pointer
                LET value = !a
                IF 'A'<=value<='Z' DO
                $( !a := value-'A'+'a'
                   nosubs := FALSE $)
             $)
             ENDCASE

          CASE 'U':
             uppercase := readplusminus()
             ENDCASE

          CASE 'V':
             verifying := readplusminus()
             ENDCASE

          CASE 'Z':
          $( LET n = z_match!0
             delim :=commrdch()
             readcontext(z_match)
             IF z_match!0=0 DO
             $( z_match!0 := n
                error(err_cntx, 'Z')
             $)
             ENDCASE $)

          CASE '=':
             renumber(numarg(FALSE,FALSE))
             ENDCASE

          CASE '-':
             deleting := TRUE
          CASE '+':
             e := numarg(TRUE,FALSE)
             FOR i = 1 TO e DO nextline()
             ENDCASE

          CASE 'N':
             nextline()
             ENDCASE

          CASE 'M':
             move(numarg(FALSE,FALSE))
             ENDCASE

          CASE 'I':
             quiet := TRUE
             move(numarg(FALSE,FALSE))
             insert()
             ENDCASE

          CASE 'T':
             commrdch()
             c := comm
             SWITCHON comm INTO
             $( CASE 'R':
                   trailing := readplusminus()
                   ENDCASE

                CASE 'P':
                   UNTIL currentline!l_prev=0 DO
                      prevline()
                CASE 'N':
                   e := maxplines
                   GOTO tlab

                DEFAULT:
                   checkvalidchar()
                CASE 'L':
                   e :=  numarg(TRUE,FALSE)
    tlab:          quiet := TRUE
                   FOR i = 1 TO e DO
                   $( UNLESS linel=0 &
                         (current=0 | exhausted) DO
                      $( IF c='L' DO
                            TEST current=-1 THEN
                               writes("  +++  ")
                            ELSE
                               writef("%I5  ", current)
                         verline('?')
                      $)
                      IF exhausted BREAK
                      nextline()
                   $)
                   unchanged := FALSE
                   ENDCASE
             $)
             ENDCASE

          CASE 'H':
             ceiling := numarg(FALSE,FALSE)
             ENDCASE

          CASE 'O':
             changeout()
             ENDCASE

          CASE 'C':
             commrdch()
             SWITCHON comm INTO
             $( DEFAULT:
                   checkspaceornl()
                   changecom()
                   edit(0)
                   ENDCASE

                CASE 'C':
                   delim := commrdch()
                   commrdch()
                   TEST comm='?' THEN
                   $( s := cch='*C' -> "**C",
                           cch='*E' -> "**E",
                           cch='*N' -> "**N",
                           cch='*P' -> "**P", "?"
                      writes(s)
                      newline()
                   $)
                   ELSE
                      cch := comm='C' -> '*C',
                             comm='E' -> '*E',
                             comm='N' -> '*N',
                             comm='P' -> '*P', endstreamch
                   UNTIL comm=delim | comm='*N' DO
                      commrdch()
                   ENDCASE

                CASE 'L':
                   compress()
                   concatenate()
                   ENDCASE

                CASE 'F':
                   closefile()
                   ENDCASE
             $)
             ENDCASE

          CASE 'S':
             commrdch()
    ssw:     SWITCHON comm INTO
             $( DEFAULT:
                   checkspaceornl()
                   changein()
                   ENDCASE

                CASE 'A': CASE 'B':
                   c := comm='A' -> c_sa, c_sb
                   dps_arg(c)
                   compress()
                   e := index(linev, pointer,
                              linel, str_match)
                   IF e<0 DO error(err_nom)
                   IF c=c_sa DO e := e+str_match!0
                   split(e)
                   ENDCASE
             $)
             ENDCASE

          CASE 'P':
             commrdch()
    psw:     SWITCHON comm INTO
             $( DEFAULT:
                   uncommrdch()
                   prevline()
                   ENDCASE

                CASE 'A': CASE 'B':
                   c := comm='A' -> c_pa, c_pb
                   dps_arg(c)
                   compress()
                   e := index(linev, pointer,
                              linel, str_match)
                   IF e<0 DO error(err_nom)
                   pointer := c=c_pa -> e+str_match!0, e
                   nosubs := FALSE
                   ENDCASE
             $)
             ENDCASE

          CASE 'A': CASE 'B': CASE 'E':
             abe_args(comm)
             compress()
             p := index(linev, pointer,
                        linel, str_match)
             IF p<0 DO error(err_nom)
             q := p+str_match!0
             IF str_comm='B' DO q := p
             IF str_comm='A' DO p := q
             subst(p, q, str_repl)
             ENDCASE

          CASE 'L': CASE 'F':
             lf_arg(comm)
             compress()
             p := lf_match!0

             $( IF sw_comm='L' DO p := linel
                UNLESS p>linel DO
                   IF index(linev, pointer, p, lf_match) >=0 BREAK
                nextline()
             $) REPEAT

             ENDCASE

          CASE 'G':
             readglobal()
             ENDCASE

          CASE 'D':
             commrdch()
    dsw:     SWITCHON comm INTO
             $( CASE 'F':CASE 'L':
                   c := comm='F' -> c_df, c_dl
                   UNLESS repeating DO
                      str_comm, lf_comm := c, c
                   deleting, quiet := TRUE, TRUE
                   GOTO sw

                CASE 'T':
                   dps_arg(c_dt)
                   compress()
                   e := index(linev, pointer,
                              linel, str_match)
                   IF e<0 DO error(err_nom)
                   UNLESS e=pointer DO
                   $( FOR i = 1 TO linel-e DO
                         linev!(pointer+i) := linev!(e+i)
                      linel := pointer+linel-e
                      nosubs := FALSE
                   $)
                   ENDCASE

                CASE 'G':
                   deleteglobal()
                   ENDCASE

                DEFAULT:
                   checkvalidchar()
                   GOTO drlab
             $)
             ENDCASE

    drlab:
          CASE 'R':
          $( LET a1 = numarg(FALSE,FALSE)
             LET a2 = numarg(FALSE,TRUE,a1)
             IF sw_comm='R' DO quiet := TRUE
             move(a1)
             deleting, quiet := TRUE, TRUE
             move(a2)
             TEST exhausted THEN $( linel, pointer := 0, 0
                                    unchanged := FALSE
                                    cch := endstreamch
                                 $)
                            ELSE nextline()
             IF sw_comm='R' DO insert()
             ENDCASE
          $)

          CASE '"':
             nextline()
          CASE '*'':
             repeating := TRUE
             comm := str_comm
             GOTO sw

          CASE '&':
             repeating := TRUE
             comm := lf_comm
             GOTO sw

          // repeated double letter commands
          CASE c_df: CASE c_dl: CASE c_dt:
             comm := comm&255
             GOTO dsw

          CASE c_pa: CASE c_pb:
             comm := comm&255
             GOTO psw

          CASE c_sa: CASE c_sb:
             comm := comm&255
             GOTO ssw

          CASE c_nc:
             error(err_rep)
       $)

       UNLESS nosubs DO unchanged := FALSE

       IF counting DO
       $( UNLESS count=0 DO
          $( count := count-1
             IF count=0 DO $( counting := FALSE; LOOP $)
          $)
          commpoint := countp
       $)

    $) REPEAT
 $)

LET checkvalidchar() BE
    TEST comm='*S' | comm='*N' |
         comm='**' | comm='.'  | '0'<=comm<='9'
    THEN uncommrdch()
    ELSE error(err_udc, sw_comm, comm)


AND checkspaceornl() BE
    TEST comm='*S' | comm='*N'
    THEN uncommrdch()
    ELSE error(err_udc, sw_comm, comm)


AND readcommline() BE
 $( commlinel := 0
    selectinput(edits)

    $( LET ch = rdch()
       IF ch='*E' | ch='*N' | ch='*C' | ch='*P' BREAK
       IF ch=endstreamch DO $( IF commlinel=0 DO commlinel := -1
                               BREAK
                            $)
       commlinel := commlinel+1
       UNLESS commlinel>maxlinel DO commbuf%commlinel := ch
    $) REPEAT

    IF commlinel>maxlinel DO
    $( commlinel := maxlinel
       writes("****** Command line truncated*N")
       rc := 10
    $)
    commpoint := 0
 $)


AND commrdch() = VALOF
 $( commpoint := commpoint+1
    comm := commlinel=-1        -> endstreamch,
            commpoint>commlinel ->        '*N',
            capitalch(commbuf%commpoint)
    RESULTIS comm
 $)


AND uncommrdch() BE commpoint := commpoint-1


AND nextcomm() BE commrdch() REPEATWHILE comm='*S'


AND readplusminus() = VALOF
 $( commrdch()
    IF comm='+' RESULTIS TRUE
    IF comm='-' RESULTIS FALSE
    error(err_pm, sw_comm)
 $)


AND commreadn() = VALOF
 $( LET a = 0
    $( a := a*10+comm-'0'
       commrdch()
    $) REPEATWHILE '0'<=comm<='9'
    uncommrdch()
    RESULTIS a
 $)


// read a number argument
// '*' => end of document
// '.' =>  -> 1, CURRENT
AND numarg(add, opt, def) = VALOF
 $( nextcomm()
    IF comm = '.' RESULTIS add -> 1, current
    IF comm = '**' RESULTIS maxint
    IF '0'<=comm<='9' RESULTIS commreadn()
    IF opt DO $( uncommrdch(); RESULTIS def $)
    error(err_num, sw_comm)
 $)


// read a context string argument
AND readcontext(v) BE
 $( LET i = 0
    $( commrdch()
       IF comm=delim | comm='*N' BREAK
       IF i>=smax DO error(err_str)
       i := i+1
       v!i := commbuf%commpoint
    $) REPEAT
    v!0 := i
 $)


AND abe_args(c) BE  UNLESS repeating DO
 $( dps_arg(c)
    readcontext(str_repl)
 $)


AND dps_arg(c) BE UNLESS repeating DO
 $( str_comm := c
    delim := commrdch()
    readcontext(str_match)
 $)


AND lf_arg(c) BE  UNLESS repeating DO
 $( UNLESS deleting DO
       str_comm, lf_comm := c, c
    delim := commrdch()
    readcontext(lf_match)
 $)


// read a file title argument
AND readfiletitle(v) = VALOF
 $( LET i = 0
    nextcomm()
    UNTIL comm='*S' | comm='*N' DO
    $( IF i>=fmax*bytesperword DO error(err_str)
       i := i+1
       v%i := commbuf%commpoint
       commrdch()
    $)
    v%0 := i
    RESULTIS i
 $)


// add a file spec to the file list
AND addfilespec(v, type) = VALOF
 $( LET p = newvec(fmin+fmax)
    LET s = type=s_in -> findinput(v), findoutput(v)
    IF s=0 DO error(err_ff, v)
    !p := filelist
    filelist := p
    FOR i = 0 TO v%0 DO (p+f_fn)%i := v%i
    p!f_lc := 0
    p!f_ex := FALSE
    p!f_io := type
    p!f_sp := s
    RESULTIS p
 $)


// find a file spec in the file list
AND findfilespec(v, type) = VALOF
 $( LET p = @filelist
    UNTIL !p=0 DO
    $( LET t = !p
       TEST compstring(t+f_fn, v)=0 & type=t!f_io THEN
          RESULTIS t
       ELSE
          p := t
    $)
    RESULTIS 0
 $)


// close a file and remove it from the list
AND losefilespec(pf) BE
 $( LET p = @filelist
    UNTIL !p=0 DO
    $( LET t = !p
       TEST t = pf THEN
       $( LET close = t!f_io=s_in ->
                  closein, closeout
          close(t!f_sp)
          !p := !t
          discardvec(t)
          BREAK
       $)
       ELSE p := t
    $)
 $)


AND closefile() BE
 $( LET v = VEC fmax
    LET e = readfiletitle(v)
    IF e=0 DO error(err_fnx)
    e := findfilespec(v, s_out)
    UNLESS e=0 DO
    $( IF e=currentoutput DO
       $( UNTIL oldestline=currentline DO writeline()
          currentoutput := primaryoutput
          textout := currentoutput!f_sp
       $)
       losefilespec(e)
       RETURN
    $)
    e := findfilespec(v, s_in)
    UNLESS e=0 DO
    $( IF e=currentinput DO
       $( renumber(-1)
          currentinput := primaryinput
          current := currentinput!f_lc
          exhausted := currentinput!f_ex
          textin := currentinput!f_sp
       $)
       losefilespec(e)
       RETURN
    $)
    error(err_cf, v)
 $)


// change the command input stream
// stack the current command line and its pointers
AND changecom() BE
 $( LET v = VEC fmax
    LET e = readfiletitle(v)
    LET f = 0
    LET s = 0
    IF e=0 DO error(err_fnx)
    IF cfsp>cfmax DO error(err_cfv)
    e := findinput(v)
    IF e=0 DO error(err_ff, v)
    s := commlinel/bytesperword
    f := newvec(cf_cb+s)
    f!cf_cp := commpoint
    f!cf_cl := commlinel
    f!cf_sp := edits
    f!cf_el := editlevel
    FOR i = 0 TO s DO
       (f+cf_cb)!i := commbuf!i
    cfstack!cfsp := f
    cfsp := cfsp+1
    edits := e
 $)


// revert to the previous command stream
AND revertcom() BE
 $( LET f = 0
    closein(edits)
    cfsp := cfsp-1
    f := cfstack!cfsp
    commpoint := f!cf_cp
    commlinel := f!cf_cl
    edits := f!cf_sp
    editlevel := f!cf_el
    FOR i = 0 TO commlinel/bytesperword DO
       commbuf!i := (f+cf_cb)!i
    discardvec(f)
 $)


// change the current output stream
// read file name and look it up
// if not found then open it
AND changeout() BE
 $( LET v = VEC fmax
    LET e = readfiletitle(v)
    TEST e=0 | compstring(v, "#")=0
    THEN e := primaryoutput
    ELSE $( e := findfilespec(v, s_out)
            IF e=0 DO e := addfilespec(v, s_out)
         $)
    UNTIL oldestline=currentline DO writeline()
    currentoutput := e
    textout := currentoutput!f_sp
 $)


// change the current input stream
AND changein() BE
 $( LET v = VEC fmax
    LET e = readfiletitle(v)
    TEST e=0 | compstring(v, "#")=0
    THEN e := primaryinput
    ELSE $( e := findfilespec(v, s_in)
            IF e=0 DO e := addfilespec(v, s_in)
         $)
    renumber(-1)
    currentinput := e
    textin := e!f_sp
    IF currentline!l_next=0 DO exhausted := e!f_ex
 $)


// renumber all lines in store
LET renumber(n) BE
 $( LET l = currentline
    current := n
    UNTIL l=0 DO
    $( l!l_numb := n
       UNLESS n=-1 DO n := n+1
       l := l!l_next
    $)
    UNLESS n=-1 DO currentinput!f_lc := n-1
    l := currentline!l_prev
    UNTIL l=0 DO $( l!l_numb := -1; l := l!l_prev $)
 $)


// split the current line
AND split(p) BE
 $( LET l = freelines
    freelines := l!l_next
    l!l_prev := currentline
    l!l_next := currentline!l_next
    UNLESS currentline!l_next=0 DO currentline!l_next!l_prev := l
    currentline!l_next := l
    nosubs := FALSE
    l!l_len := linel-p
    l!l_numb := current
    l!l_cch := cch
    FOR i = p+1 TO linel DO (l+l_buf)!(i-p) := linev!i
    cch := '*N'
    linel := p
    exhausted := FALSE
    putline()
    currentline := l
    getline()
    IF currentline!l_next=0 DO exhausted := currentinput!f_ex
    current := -1
    nosubs := FALSE
    IF freelines=0 DO writeline()
 $)


// concatenate the next line
AND concatenate() BE
 $( LET l = 0
    LET s = linel
    LET p = pointer
    nosubs := TRUE
    nextline()
    putline()
    l := currentline
    currentline := currentline!l_prev
    getline()
    FOR i = linel+1 TO s DO linev!i := '*S'
    linel := s
    subst(linel, linel, l+l_buf)
    pointer := p
    currentline!l_next := l!l_next
    UNLESS l!l_next=0 DO
       l!l_next!l_prev := currentline
    l!l_next := freelines
    freelines := l
 $)


// insert material before the current line
AND insert() BE
 $( LET v = VEC fmax
    LET e = readfiletitle(v)
    LET i = 0
    LET l = currentline
    LET p = pointer
    LET s = nosubs
    TEST e=0 THEN $( UNTIL comm='*N' DO commrdch()
                     selectinput(edits)
                  $)
             ELSE $( i := findinput(v)
                     IF i=0 DO error(err_ff, v)
                     selectinput(i)
                  $)
    nosubs := TRUE
    putline()
    current := -1

    $( currentline := freelines
       readline()
       IF i=0 & linel=z_match!0 &
          index(linev, 0, linel, z_match)=0 BREAK
       IF linel=0 & cch=endstreamch BREAK
       freelines := currentline!l_next
       currentline!l_next := l
       currentline!l_prev := l!l_prev
       UNLESS l!l_prev=0 DO l!l_prev!l_next := currentline
       l!l_prev := currentline
       IF oldestline=l DO oldestline := currentline
       putline()
       IF freelines=0 DO writeline()
       IF intflag() DO $( UNLESS i=0 DO endread()
                          currentline := l
                          getline()
                          error(err_brk)
                       $)
    $) REPEAT

    UNLESS i=0 DO endread()
    currentline := l
    getline()
    nosubs := s
    pointer := p
 $)


// read an input line
AND readline() BE
 $( linev := currentline+l_buf
    linel := 0

    $( cch := rdch()
       IF cch<'*S' DO
          IF cch='*E' | cch='*N' |
             cch='*C' | cch='*P' BREAK
       IF cch=endstreamch BREAK
       linel := linel+1
       UNLESS linel>maxlinel DO linev!linel := cch
    $) REPEAT

    IF truncate(linel) DO linel := maxlinel
    UNLESS trailing DO
       WHILE linel>pointer & linev!linel='*S' DO
          linel := linel-1
    nosubs := TRUE
    expanded := FALSE
 $)


// write an output line
AND writeline() BE
 $( LET l = oldestline
    LET v = oldestline+l_buf
    IF l=currentline DO putline()
    selectoutput(textout)
    FOR p = 1 TO v!0 DO wrch(v!p)
    UNLESS l!l_cch=endstreamch DO wrch(l!l_cch)
    selectoutput(verout)
    oldestline := l!l_next
    UNLESS oldestline=0 DO oldestline!l_prev := 0
    l!l_next := freelines
    freelines := l
 $)


// set up a new current line
AND getline() BE
 $( linev := currentline+l_buf
    linel := currentline!l_len
    cch := currentline!l_cch
    current := currentline!l_numb
    nosubs := TRUE
    expanded := FALSE
 $)


// store the current line
AND putline() BE
 $( pointer := 0
    UNLESS quiet | nosubs DO ver('?', '*N')
    compress()
    UNLESS trailing DO
       WHILE linel>0 & linev!linel='*S' DO
          linel := linel-1
    currentline!l_cch := cch
    currentline!l_len := linel
    currentline!l_numb := current
 $)


// move on to the next line
AND nextline() BE
 $( IF intflag() DO error(err_brk)
    IF current>0 & current>=ceiling DO error(err_cr)
    IF exhausted DO error(err_noin)
    pointer := 0
    UNLESS deleting DO putline()
    TEST currentline!l_next=0
    THEN $( UNLESS deleting DO
            $( freelines!l_prev := currentline
               currentline!l_next := freelines
               currentline := freelines
               freelines := freelines!l_next
               currentline!l_next := 0
               IF freelines=0 DO writeline()
            $)
            current := currentinput!f_lc+1
            selectinput(textin)
            readline()
            FOR i = 1 TO globcount DO changeglobal(i)
            exhausted := cch=endstreamch
            currentinput!f_lc := current
            currentinput!f_ex := exhausted
         $)
    ELSE $( currentline := currentline!l_next
            getline()
            IF currentline!l_next=0 DO
               exhausted := currentinput!f_ex
            IF deleting DO
            $( LET p = currentline!l_prev
               currentline!l_prev := p!l_prev
               UNLESS p!l_prev=0 DO
                  p!l_prev!l_next := currentline
               p!l_next := freelines
               freelines := p
               IF oldestline=p DO oldestline := currentline
            $)
         $)
    IF exhausted & zerolevel\=0 DO error(err_noin)
    unchanged := FALSE
 $)


//  move back to the previous line
AND prevline() BE
 $( IF currentline!l_prev=0 DO error(err_nopr)
    putline()
    currentline := currentline!l_prev
    getline()
    exhausted := FALSE
    unchanged := FALSE
 $)


// move on to line N
AND move(n) BE
    UNLESS n=current DO
    $( UNLESS deleting DO
       $( LET l = currentline!l_prev
          UNTIL l=0 DO
          $( LET m = l!l_numb
             UNLESS m=-1 DO
             $( IF m=n DO
                $( putline()
                   currentline := l
                   getline()
                   exhausted := FALSE
                   unchanged := FALSE
                   RETURN
                $)
                IF m<n BREAK
             $)
             l := l!l_prev
          $)
       $)
       UNTIL n=current DO
       $( IF current>0 & current>=n DO
             error(err_line, n)
          IF exhausted & n=maxint DO
          $( IF deleting DO linel := 0
             BREAK
          $)
          nextline()
       $)
    $)


// verify the current line
AND ver(c, n) BE
 $( TEST current=-1
    THEN writes("+++")
    ELSE writen(current)
    wrch(exhausted -> '**', '.')
    newline()
    UNLESS linel=0 & (current=0 | exhausted) DO
    $( verline(c)
       UNLESS pointer=0 DO
       $( FOR i = 1 TO pointer-1 DO wrch('*S')
          wrch('>')
          wrch(n)
       $)
    $)
    unchanged, nosubs := TRUE, TRUE
 $)


// write out a verification line
AND verline(c) BE
 $( LET vch1(ch) =
         #40<=ch< #177 -> ch,
              ch ='*T' -> '*S',
              ch<    0 -> '*S', '?'

    AND vch2(ch) =
         #40<=ch< #177 -> ch,
              ch ='*T' -> '*S',
              ch<    0 -> '*S', hex(ch>>4)

    AND vch3(ch) =
         #40<=ch< #100 -> '*S',
        #100<=ch< #140 -> '-',
        #140<=ch< #177 -> '*S',
              ch ='*T' -> 'T',
              ch<    0 -> '.', hex(ch&15)

    AND hex(ch) =
        ch>9 -> 'A'+ch-10, '0'+ch

    AND wrl(vch) BE
     $( LET l = linel
        WHILE l>0 & vch(linev!l)='*S' DO l := l-1
        FOR p = 1 TO l DO wrch(vch(linev!p))
        newline()
     $)

    expand()
    condense()
    TEST c='!' THEN
    $( wrl(vch2)
       wrl(vch3)
    $)
    ELSE
       wrl(vch1)
 $)


LET error(n, a, b) BE
 $( LET r = 10
    LET z = zerolevel
    LET s = VALOF SWITCHON n INTO

  $( CASE err_uc:   RESULTIS "Unknown command - %C"
     CASE err_udc:  RESULTIS "Unknown command - %C%C"
     CASE err_bra:  RESULTIS "Unmatched parenthesis"
     CASE err_cntx: RESULTIS "Null context after %C"
     CASE err_pm:   RESULTIS "+ or - expected after %C"
     CASE err_num:  RESULTIS "Number expected after %C"
     CASE err_line: RESULTIS "Line number %N too small"
     CASE err_fnx:  RESULTIS "Filename expected"
     CASE err_str:  RESULTIS "String too long"
     CASE err_nom:  RESULTIS "No match"
     CASE err_rep:  RESULTIS "Nothing to repeat"
     CASE err_noin: RESULTIS "Input exhausted"
     CASE err_nopr: RESULTIS "No more previous lines"
     CASE err_cr:   RESULTIS "Ceiling reached"
     CASE err_glob: RESULTIS "Too many globals"
     CASE err_ffa:  r := 20
     CASE err_ff:   RESULTIS "Can't open %S"
     CASE err_cf:   RESULTIS "Can't close %S"
     CASE err_arg:  r := 20
                    RESULTIS "Bad args"
     CASE err_opt:  r := 20
                    RESULTIS "Invalid option values"
     CASE err_rn:   r := 20
                    RESULTIS "Can't rename %S as %S"
     CASE err_gv:   r := 20
                    RESULTIS "Run out of store"
     CASE err_cfv:  r := 20
                    RESULTIS "Command file stack ovf"
     CASE err_qw:   RESULTIS "Invalid %C command"
     CASE err_brk:  RESULTIS "****BREAK"
  $)

    zerolevel := 0

    $( IF editlevel=z & n=err_noin DO
       $( IF isinteractive(edits) DO
             UNLESS verifying DO newline()
          GOTO l
       $)
       IF cfsp=0 BREAK
       revertcom()
    $) REPEAT

    UNLESS commlinel<=0 | isinteractive(edits) DO
    $( FOR i = 1 TO commlinel DO wrch(commbuf%i)
       UNLESS commbuf%commlinel='*N' DO newline()
       FOR i = 1 TO commpoint-1 DO wrch('*S')
       writes("!*N")
    $)
    writef(s, a, b)
    newline()
    rc := r
    IF rc=20 | NOT isinteractive(edits) DO
    $( UNLESS rc=20 DO ver('?', '*N')
       IF opened DO closestreams()
       longjump(quitlevel, quitlab)
    $)
 l: IF verifying DO ver('?', '*E')
    longjump(editlevel, editlab)
 $)


AND truncate(p) = VALOF
 $( UNLESS p>maxlinel RESULTIS FALSE
    TEST current=-1 THEN
       writes("****** Line +++ truncated*N")
    ELSE
       writef("****** Line %I3 truncated*N", current)
    rc := 10
    RESULTIS TRUE
 $)


// expand tabs in the current line with dummy characters
AND expand() BE UNLESS expanded DO
 $( LET j = 0
    LET t = maxlinel-linel
    LET p = t+pointer
    LET c, f = 0, FALSE
    FOR i = linel TO 1 BY -1 DO linev!(t+i) := linev!i
    UNTIL t>=maxlinel DO
    $( IF j+(c='*T' -> 1,0) > t DO
       $( t := t+1
          FOR i = linel TO t BY -1 DO linev!i := linev!(i-1)
          f := TRUE
          LOOP
       $)
       j := j+1
       TEST c='*T' THEN linev!j := -1
                   ELSE $( t := t+1
                           c := linev!t
                           linev!j := c
                        $)
       IF j REM 8 = 0 DO c := 0
       IF t=p DO pointer := j
    $)
    IF f DO truncate(maxint)
    linel := j
    expanded, condensed := TRUE, TRUE
 $)


// remove all dummy characters from the current line
AND compress() BE IF expanded DO
 $( LET i, j = 0, 0
    UNTIL i>=linel DO
    $( i := i+1
       UNLESS linev!i<0 DO $( j := j+1
                              linev!j := linev!i
                           $)
       IF pointer=i DO pointer := j
    $)
    linel := j
    expanded := FALSE
 $)


// remove all dummy characters from the current line
// leaving tabs expanded
AND condense() BE IF expanded DO UNLESS condensed DO
 $( LET i, j = 0, 0
    UNTIL i>=linel DO
    $( i := i+1
       IF pointer=i DO pointer := j+(linev!i<0 -> 0,1)
       UNLESS linev!i<0 DO
       $( j := j+1
          linev!j := linev!i
          IF linev!i='*T' DO
             UNTIL j REM 8 = 0 DO $( j := j+1
                                     linev!j := -1
                                  $)
       $)
    $)
    linel := j
    condensed := TRUE
 $)


// step the character pointer
AND incrementp() = VALOF
 $( expand()
    IF pointer=lmax RESULTIS FALSE
    pointer := pointer+1
    unchanged := FALSE
    IF pointer>linel DO $( linev!pointer := '*S'
                           linel := pointer
                        $)
    RESULTIS TRUE
 $)


// substitute a string for line positions P+1 to Q
AND subst(p, q, v) BE
 $( LET s = v!0
    LET t = linel-q
    LET r = 0
    truncate(p+s+t)
    IF p+s>maxlinel DO s := maxlinel-p
    r := p+s
    IF r+t>maxlinel DO t := maxlinel-r
    linel := r+t
    UNLESS r=q TEST r>q THEN FOR i = t TO 1 BY -1 DO
                                 linev!(r+i) := linev!(q+i)
                        ELSE FOR i = 1 TO t DO
                                 linev!(r+i) := linev!(q+i)
    FOR i = 1 TO s DO linev!(p+i) := v!i
    nosubs := FALSE
 $)


// search line positions P+1 to Q for a string
AND index(l, p, q, v) = VALOF
 $( LET s = v!0
    q := q-s
    UNTIL p>q DO
    $( LET r = l+p
       FOR i = 1 TO s DO
          TEST uppercase | v=z_match
          THEN UNLESS compch(r!i, v!i)=0 GOTO l
          ELSE UNLESS r!i=v!i GOTO l
       RESULTIS p
 l:    p := p+1
    $)
    RESULTIS -1
 $)


AND readglobal() BE
 $( LET v = VEC smax
    LET s = 0
    LET p = 0
    LET n = 0
    LET l = currentline
    delim := commrdch()
    readcontext(v)
    s := v!0
    IF s=0 DO error(err_cntx, 'G')
    n := findglobal(v)
    TEST n<0 THEN $( IF globcount>=gmax DO error(err_glob)
                     globcount := globcount+1
                     n := globcount
                     p := newvec(s)
                     FOR i = 0 TO s DO p!i := v!i
                     g_match!n := p
                  $)
             ELSE discardvec(g_repl!n)
    readcontext(v)
    s := v!0
    p := newvec(s)
    FOR i = 0 TO s DO p!i := v!i
    g_repl!n := p
    p := pointer
    s := nosubs
    nosubs := TRUE
    $( putline()
       currentline := currentline!l_next
       IF currentline=0 DO currentline := l
       getline()
       changeglobal(n)
    $) REPEATUNTIL currentline=l
    IF nosubs DO nosubs := s
    pointer := p
 $)


AND deleteglobal() BE
 $( LET v = VEC smax
    delim := commrdch()
    readcontext(v)
    TEST v!0=0 THEN $( FOR i = 1 TO globcount DO
                       $( discardvec(g_match!i)
                          discardvec(g_repl!i)
                       $)
                       globcount := 0
                    $)
               ELSE $( LET n = findglobal(v)
                       IF n<0 DO error(err_nom)
                       discardvec(g_match!n)
                       discardvec(g_repl!n)
                       FOR i = n TO globcount-1 DO
                         g_match!i,g_repl!i := g_match!(i+1),g_repl!(i+1)
                       globcount := globcount-1
                    $)
 $)


AND findglobal(v) = VALOF
 $( FOR i = 1 TO globcount DO
    $( LET w = g_match!i
       IF v!0=w!0 & index(v, 0, v!0, w)=0 RESULTIS i
    $)
    RESULTIS -1
 $)


AND changeglobal(i) BE
 $( LET p = 0
    LET v = g_match!i
    LET w = g_repl!i

    $( LET n = index(linev, p, linel, v)
       IF n<0 BREAK
       subst(n, n+v!0, w)
       p := n+w!0
    $) REPEAT
 $)
