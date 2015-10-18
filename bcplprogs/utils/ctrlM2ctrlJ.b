// (C) Copyright 1978 Tripos Research Group
//     University of Cambridge
//     Computer Laboratory

SECTION "ctrlM2ctrlJ"

GET "libhdr"

GLOBAL
$(
inputstream:150
outputstream:151
$)

LET start() = VALOF
$( LET argv = VEC 50
   LET rc = 0
   LET ch = 0
   LET oldoutput = output()

   inputstream := 0
   outputstream := 0

   IF rdargs("FROM/A,TO", argv, 50) = 0 DO
   $( writes("Bad args*n")
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

   $( LET tab = 0

      $( ch := rdch()
         IF intflag() DO $( selectoutput(oldoutput)
                            writes("****BREAK*n")
                            rc := 5
                            GOTO exit
                         $)
         IF tab=0 DO $( IF ch=endstreamch GOTO exit
                     $)
         SWITCHON ch INTO
         $( CASE 13:          newline();   LOOP

            DEFAULT:          wrch(ch);    LOOP

            CASE endstreamch: newline()
                              GOTO exit
         $)
      $) REPEAT
   $) REPEAT

exit:
   UNLESS inputstream=0  DO $( selectinput(inputstream);   endread()  $)
   UNLESS outputstream=0 DO $( selectoutput(outputstream); endwrite() $)
   RESULTIS rc
$)
