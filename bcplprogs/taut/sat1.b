GET "libhdr"

MANIFEST $(
Ssize = 800000; Hsize = 50000

Xcells=10; Ycells=10
Dxsize=1; Dysize=1
Xsize=Xcells*Dxsize; Ysize=Ycells*Dysize

T_eof=0; T_numb=1
$)

GLOBAL $(
spacev:200; spacep:201; spacet:202
termv:203; termp:204; termt:205

termcount:206
varmax:207
varv:208

hashtab:210
linenumber:211
ch:212; lexval:213; token:214

xsize: 220; ysize: 221

densityv:230
$)

/* Data format:
   
c ... end of line     Comment
p ... end of line     Comment
i j k 0               A term, complemented variables are negative

endstreamch           Enf of data


The terms are read in and stored in spacev, terminated with two zeros.
During input, the number of terms is calculated in termcount, and the
value of the largest variable is found and placed in varmax.

*/

LET start() = VALOF
$( LET argv = VEC 50

   IF rdargs("DATA", argv, 50)=0 DO
   $( writes("Bad arguments for SAT1*n")
      RESULTIS 20
   $)

   UNLESS initvec() RESULTIS error("Unable to allocate workspace")

   IF argv!0=0 DO argv!0 := "data.cnf"
   UNLESS readterms(argv!0)  RESULTIS error("Unable to read terms")

   setterms()

   UNLESS setvars() RESULTIS error("Unable to set variables")

   FOR i = 1 TO termcount DO
   $( LET p = termv!i
      $( writef("%i5 ", !p)
         IF !p=0 BREAK
         p := p+1
      $) REPEAT
      newline()
   $)

   prdensity()

   writef("*n %i5 terms*n %i5 largest variable*n", termcount, varmax)

   retvecs()
   RESULTIS 0
$)

AND initvec() = VALOF
$( spacev := getvec(Ssize)
   spacet := spacev + Ssize

   termv := 0
   termcount := 0
   varmax := 0

   hashtab := getvec(Hsize)

   UNLESS spacev=0 | hashtab=0 RESULTIS TRUE

   retvecs()

   RESULTIS FALSE
$)

AND retvecs() BE
$( UNLESS spacev=0 DO freevec(spacev)
   UNLESS hashtab=0 DO freevec(hashtab)
$)

AND setvars() = VALOF
$( varv := spacep
   spacep := spacep + varmax
   densityv := spacep+1
   spacep := spacep + denpos(Xsize, Ysize) + 1
   IF spacep>spacet RESULTIS FALSE

   FOR i = 0 TO spacep-1 DO densityv!i := 0

   FOR i = 1 TO varmax DO
   $( LET xpos, ypos = randno(Xsize), randno(Ysize)
      LET dpos = denpos(xpos, ypos)
      varv!i := spacep
      put(i)      // id
      put(xpos)   // xpos
      put(xpos)   // ypos
      put(0)      // xdot
      put(0)      // ydot
      writef("%i3  xpos %i5   ypos %i5*n", i, xpos, ypos)
      densityv!dpos := densityv!dpos + 1
   $)

newline()
writef("varv %i7*ndensityv %i7 *n", varv, densityv)
   RESULTIS TRUE
$)

AND denpos(x, y) = VALOF
$( LET i = (x/Dxsize) + (y/Dysize) * Xcells
   writef("x = %i5    y = %i6      dpos = %i4*n", x, y, i)
   RESULTIS i
$)

AND prdensity() BE
$( FOR i = 0 TO Dysize-1 DO
   $( LET row = densityv + Dxsize*i
      FOR p = row TO row+Dxsize-1 DO
      $( LET k = !p
         IF k>'9' DO k := 10
         wrch("-123456789**"%(k+1))
      $)
      newline()
   $) 
$)

AND setterms() = VALOF
$( LET t = spacev
   termv := spacep-1
   FOR i = 1 TO termcount DO
   $( put(t)
      UNTIL !t = 0 DO t := t+1
      t := t+1
   $)

   RESULTIS TRUE
$)

AND readterms(filename) = VALOF
$( LET oldin = input()
   LET data = findinput(filename)
   IF data=0 DO
   $( writef("Trouble with file %s*n", filename)
      RESULTIS FALSE
   $)
   writef("Reading from file %s*n", filename)
   selectinput(data)

   spacep := spacev
   rch()

   $( lex()
      SWITCHON token INTO
      $( DEFAULT: writes("Bad token %n*n", token)
                  lex()
                  LOOP
         CASE T_numb: $( LET k = ABS lexval
                         IF k=0 DO termcount := termcount+1
                         IF varmax<k DO varmax := k
                         put(lexval)
                         ENDCASE
                      $)
         CASE T_eof: BREAK
      $)
   $) REPEAT

   put(0)
   put(0)

   endread()
   selectinput(oldin)
   RESULTIS TRUE
$)

AND rch() BE ch := rdch()

AND lex() BE
$( SWITCHON ch INTO
   $( DEFAULT: writef("Bad ch: %n '%c'*n", ch, ch)
               rch()
               LOOP

      CASE endstreamch: token := T_eof
                        RETURN

      CASE '*n': linenumber := linenumber + 1
      CASE '*t':
      CASE ' ':  rch()
                 LOOP
      CASE 'p':
      CASE 'c': rch() REPEATUNTIL ch='*n' | ch=endstreamch
                LOOP
      CASE '-':
      CASE '0':CASE '1':CASE '2':CASE '3':CASE '4':
      CASE '5':CASE '6':CASE '7':CASE '8':CASE '9':
                lexval := rdnumb()
                token := T_numb
                RETURN
   $)
$) REPEAT

AND rdnumb() = VALOF
$( LET res = 0
   LET neg = FALSE

   IF ch='-' DO $( neg := TRUE; rch() $)
   WHILE '0'<=ch<='9' DO $( res := 10*res + ch - '0'
                            rch()
                         $)
   IF neg DO res := -res
   RESULTIS res
$)

AND put(n) BE
$( IF spacep<spacet DO !spacep := n
   spacep := spacep+1
//   writef("%i5 ", n)
//   IF n=0 DO newline()
$)

AND error(mess) = VALOF
$( writef("*nError: %s*n", mess)
   retvecs()
   RESULTIS 20
$)




