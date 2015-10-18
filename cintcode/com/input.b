// (C) Copyright 1979 Tripos Research Group
//     University of Cambridge
//     Computer Laboratory

SECTION "INPUT"

GET "libhdr"

LET start() = VALOF
$( LET argv = VEC 50
   LET save = VEC 50
   LET oldout = output()
   LET tlen = ?
   LET term, stream = "/**", ?
   IF rdargs("TO/A,TERM/K",argv,50)=0 DO $( writes("Bad args*n")
                                            RESULTIS 20
                                         $)
   stream := findoutput(argv!0)
   IF stream=0 DO $( writef("Can't open %s*n", argv!0)
                     RESULTIS 20
                  $)
   selectoutput(stream)

   UNLESS argv!1 = 0 DO term := argv!1
   tlen := term%0

   $( LET t, ch = 1, ?
      ch := rdch()
      WHILE t<=tlen & compch(ch,term%t)=0 & ch\='*n' DO
      $( save%t := ch
         t := t+1
         ch := rdch()
      $)
      IF t>tlen & ch='*N' BREAK
      FOR j = 1 TO t-1 DO wrch(save%j)
      IF ch=endstreamch GOTO ended
      wrch(ch)
      $( IF intflag() DO $( writes("****BREAK*n")
                            UNLESS oldout=output() DO endwrite()
                            RESULTIS 10
                         $)
         IF ch='*n' BREAK
         ch := rdch()
         IF ch=endstreamch GOTO ended
         wrch(ch)
      $) REPEAT
   $) REPEAT

ended:
   UNLESS oldout=output() DO endwrite()
   RESULTIS 0
$)
