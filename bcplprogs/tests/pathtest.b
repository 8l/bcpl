// This a test for the pathfindinput function. It is based on
// the type program. It type a file searched for on the
// path given by the BCPLCMDS shell variable.

SECTION "PATHTEST"

GET "libhdr"

GLOBAL
$(
inputstream:150
outputstream:151
numbers:152
linenumber:153
$)

LET start() = VALOF
$( LET argv = VEC 50
   LET rc = 0
   LET ch = 0
   LET oldoutput = output()

   inputstream := 0
   outputstream := 0

   IF rdargs("FROM/A,TO,N/S", argv, 50) = 0 DO
   $( writes("Bad args*n")
      rc := 20
      GOTO exit
   $)

   inputstream := pathfindinput(argv!0, "BCPLPATH")
   IF inputstream = 0 DO $( writef("Can*'t open %s*n", argv!0)
                            rc := 20
                            GOTO exit
                         $)
   selectinput(inputstream)

   UNLESS argv!1=0 DO $( outputstream := findoutput(argv!1)
                         IF outputstream=0 DO
                         $( writef("Can*'t open %s*n", argv!1)
                            rc := 20
                            GOTO exit
                         $)
                         selectoutput(outputstream)
                      $)

   numbers := argv!2

   linenumber := 1

   $( LET tab = 0

      $( ch := rdch()
         IF intflag() DO $( UNLESS tab=0 DO wrch('*n')
                            selectoutput(oldoutput)
                            writes("****BREAK*n")
                            rc := 5
                            GOTO exit
                         $)
         IF tab=0 DO $( IF ch=endstreamch GOTO exit
                        IF numbers DO writef("%I5  ", linenumber)
                     $)
         SWITCHON ch INTO
         $( CASE '*c': CASE '*n': CASE '*p':
                       linenumber := linenumber+1; wrch(ch); BREAK

            CASE '*e': linenumber := linenumber+1; tab := 8; LOOP

            CASE '*t':
                    $( wrch('*s')
                       tab := tab+1
                    $) REPEATUNTIL tab REM 8 = 0
                       LOOP

            DEFAULT:   wrch(ch);              tab := tab+1;  LOOP

            CASE endstreamch:
                       wrch('*n');                           GOTO exit
         $)
      $) REPEAT
   $) REPEAT

exit:
   UNLESS inputstream=0  DO $( selectinput(inputstream);   endread()  $)
   UNLESS outputstream=0 DO $( selectoutput(outputstream); endwrite() $)
   RESULTIS rc
$)
