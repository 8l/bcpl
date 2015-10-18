SECTION "warshall"
 
GET "libhdr"
 
MANIFEST $( upb          =  100
            bitsperword  =  16
            wordsperrow  = upb / bitsperword + 1
            vecupb       = (upb+1)*wordsperrow - 1
$)
 
LET warshall(v) BE FOR i = 0 TO upb DO
$( LET wordi = i / bitsperword
   AND biti  = 1 << i REM bitsperword
   AND rowi  = v + i*wordsperrow
 
   FOR rowj = v TO v+upb*wordsperrow BY wordsperrow DO
     UNLESS (rowj!wordi & biti) = 0 DO
       FOR k = 0 TO wordsperrow-1 DO rowj!k := rowj!k | rowi!k
$)
 
AND clear(v) BE FOR p = v TO v+vecupb DO !p := 0
 
AND set(v, x, y) BE
$( LET wordx = x / bitsperword
   AND bitx  = 1 << x REM bitsperword
   AND rowy = v + y*wordsperrow
   rowy!wordx := rowy!wordx | bitx
$)
 
AND iszero(row) = VALOF
$( FOR i = 0 TO wordsperrow-1 UNLESS row!i=0 RESULTIS FALSE
   RESULTIS TRUE
$)
 
AND pr(v) BE FOR y = 0 TO upb DO
$( LET rowy = v + y * wordsperrow
   AND k = 0
   IF iszero(rowy) LOOP
   writef("%i3: ", y)
   FOR x = 0 TO upb DO
   $( LET wordx = x / bitsperword
      AND bitx  = 1 << x REM bitsperword
      UNLESS (rowy!wordx & bitx) = 0 DO
      $( k := k+1
         IF k REM 10 = 0 DO writes("*n     ")
         writef("%i3", x)
      $)
   $)
   newline()
$)
 
 
 
 
 
 
LET start() BE
$( LET matrix = getvec(vecupb)
   AND current.y = 0
 
   writes("*nTest program for Warshall's algorithm*n")
 
   $( LET ch = rdch()
      SWITCHON capitalch(ch) INTO
      $( DEFAULT:   writef("*nBad character '%c'*n", ch)
         CASE '*n': newline()
         CASE '*s': LOOP
 
         CASE 'X':  $( LET x = readn()
                       TEST 0<=x<=upb
                       THEN set(matrix, x, current.y)
                       ELSE writef("*nX (= %n) out of range*n", x)
                       LOOP
                     $)
 
         CASE 'Y':  $( LET y = readn()
                       TEST 0<=y<=upb
                       THEN current.y := y
                       ELSE writef("*nY (= %n) out of range*n", y)
                       LOOP
                     $)
 
         CASE 'Z':  clear(matrix)
                    LOOP
 
         CASE 'W':  warshall(matrix)
                    LOOP
 
         CASE 'P':  pr(matrix)
                    newline()
                    LOOP
 
         CASE 'Q':  BREAK
      $)
   $) REPEAT
 
   freevec(matrix)
   writes("*nEnd of test*n")
$)
 
 
