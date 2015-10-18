SECTION "PAGIN"

GET "libhdr"

GLOBAL
$(
inputstream:150
outputstream:151
len:152
linenumber:153
$)

LET start() = VALOF
$( LET argv = VEC 50
   LET rc = 0
   LET ch = 0
   LET oldoutput = output()

   len := 75

   inputstream := 0
   outputstream := 0

   IF rdargs("FROM/A,TO,LEN/K", argv, 50) = 0 DO
   $( writes("Bad args for PAGIN*n")
      rc := 20
      GOTO exit
   $)

   inputstream := findinput(argv!0)
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

   UNLESS argv!2=0 DO len := str2numb(argv!2)


   $( LET pos, poslastsp = 0, len
      LET line = VEC 100

      $( ch := rdch()

         IF intflag() DO $( selectoutput(oldoutput)
                            writes("****BREAK*n")
                            rc := 5
                            GOTO exit
                         $)

   sw:   SWITCHON ch INTO
         $( CASE '*c': CASE '*n': CASE '*p':
                       wrline(line, pos)
                       pos, poslastsp := 0, len
                       LOOP

            CASE '*s': poslastsp := pos
                       line!pos := ch;   
                       pos := pos + 1
                       ch := rdch() REPEATWHILE ch='*s'
                       IF pos>=len DO { wrline(line, poslastsp)
                                        pos, poslastsp := 0, len
                                      }
                       GOTO sw

            DEFAULT:   line!pos := ch;   
                       pos := pos + 1
                       IF pos>=len DO
                       { wrline(line, poslastsp)
                         FOR i = 0 TO pos-poslastsp-1 DO 
                            line!i := line!(poslastsp+i+1)
                         pos := pos-poslastsp-1
                         poslastsp := len
                       }
                       LOOP

            CASE endstreamch:
                       wrline(line, pos);  GOTO exit
         $)
      $) REPEAT
   $)

exit:
   UNLESS inputstream=0  DO $( selectinput(inputstream);   endread()  $)
   UNLESS outputstream=0 DO $( selectoutput(outputstream); endwrite() $)
   RESULTIS rc
$)


AND wrline(line, n) BE
{ FOR i = 0 TO n-1 DO wrch(line!i)
  newline()
}