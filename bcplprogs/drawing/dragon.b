GET "libhdr"

// This is a program to generate an Encapsulated Postscript 
// representation of the dragon curve

LET start() = VALOF
$( LET argv = VEC 50
   LET n = 1024
   LET oldout = output()
   LET outfile = 0

   IF rdargs("N,TO/K", argv, 50)=0 DO
   $( writes("Bad arguments for DRAGON*n")
      RESULTIS 20
   $)

   UNLESS argv!0=0 DO n := str2numb(argv!0)

   UNLESS argv!1=0 DO outfile := findoutput(argv!1)

   UNLESS outfile=0 DO selectoutput(outfile)

   writes("*n")
   dragon(n)
   writes("*n")

   UNLESS outfile=0 | outfile=oldout DO endwrite()

   selectoutput(oldout)
   RESULTIS 0
$)

AND bits(w) = w=0 -> 0, 1 + bits(w & w-1)

AND gray(n) = n NEQV n>>1

AND dragon(n) BE FOR i = 0 TO n-1 DO
                 $( LET dir = bits(gray(i)) & 3
                    IF i REM 32 = 0 DO newline()
                    writef("%c ", "RULD" % (dir+1))
                 $)