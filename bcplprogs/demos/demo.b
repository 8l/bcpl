GET "libhdr"

LET start() = VALOF
$( LET n = 0

   writef("Please give me a number: ")

   n := readn()

   IF n=0 RESULTIS 0

   writef("Your number was %n and its square is %n*n", n, n*n)
$) REPEAT