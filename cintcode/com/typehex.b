// (C) Copyright 1979 Tripos Research Group
//     University of Cambridge
//     Computer Laboratory

GET "libhdr"

GLOBAL $( buffer     :  ug
          ptr        :  ug + 1
          lim        :  ug + 2
       $)

MANIFEST $( buffer.size = 150 $)

LET start() = VALOF
  $( LET args      = VEC 50
     LET sysout    = output()
     LET instream  = 0
     LET outstream = 0
     LET word      = ?
     LET wdcount   = 0
     LET buf       = VEC buffer.size - 1

     buffer       := buf
     lim, ptr     := 0, -1

     IF rdargs("FROM/A,TO/K", args, 50) = 0 DO
     $( writes("Bad arguments for TYPEHEX*n")
        RESULTIS 20
     $)

     instream := findinput(args!0)
     IF instream = 0 DO $( writef("can't open %s*n", args!0)
                           RESULTIS 20
                        $)
     selectinput(instream)

     UNLESS args!1 = 0 DO
     $( outstream := findoutput(args!1)
        IF outstream = 0 DO $( writef("can't open %s*n", args!1)
                               endread()
                               RESULTIS 20
                            $)
        selectoutput(outstream)
     $)

     WHILE getword(@ word) DO
     $( writef("%X8",word)
        IF intflag() DO $( selectoutput(sysout)
                           writes("*n******BREAK*n")
                           GOTO out
                        $)
        wdcount:=wdcount+1
        wrch(wdcount REM 8 = 0 ->'*n','*s')
     $)

     UNLESS wdcount REM 16 = 0 DO newline()

  out:
     endread()
     UNLESS outstream = 0 DO $( selectoutput(outstream)
                                endwrite()
                             $)
     RESULTIS 0
  $)

AND getword(addr) = VALOF
  $( LET ch = ?
     ! addr := 0
     ch := rdch()
     IF ch=endstreamch RESULTIS FALSE
     addr%0 := ch
     ch := rdch()
     IF ch=endstreamch RESULTIS TRUE
     addr%1 := ch
     ch := rdch()
     IF ch=endstreamch RESULTIS TRUE
     addr%2 := ch
     ch := rdch()
     IF ch=endstreamch RESULTIS TRUE
     addr%3 := ch
     RESULTIS TRUE
  $)
