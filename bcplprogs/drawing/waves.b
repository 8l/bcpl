GET"libhdr"

LET start() BE
$( LET t = TABLE 16,
                 128+0,
                 128+0,
                 128+0,
                 128+16,
                 128+32,
                 128+32,
                 128+32,
                 128+16,
                 128+0,
                 128-16,
                 128-32,
                 128-32,
                 128-32,
                 128-16,
                 128+0,
                 128+0


   LET y, yd, ydd = 0,0,0

   LET best, score = 0, 1000000000

   FOR bits = 0 TO (1<<t!0) - 1 DO
   $( LET sc, y, yd, ydd = 0, 128, 0, 0
      LET w = bits

      FOR i = 1 TO t!0 DO
      $( TEST (w & 1) = 0 THEN ydd := ydd-1
                          ELSE ydd := ydd+1
         w := w>>1
         yd := yd + ydd
         y := y + yd
         sc := max(sc, scfn(t!i, y))
         IF sc>=score BREAK
      $)

      IF sc<score DO score, best := sc, bits
   $)

   $( LET sc, y, yd, ydd = 0, 128, 0, 0
      LET w = best

      FOR i = 1 TO t!0 DO
      $( TEST (w & 1) = 0 THEN ydd := ydd-1
                          ELSE ydd := ydd+1
         w := w>>1
         yd := yd + ydd
         y := y + yd
         writef("%N  %I3  %I3  %I3  %I3  %I3*N",
                best>>(i-1) & 1, ydd, yd, y, t!i, scfn(t!i, y))
      $)

      writef("Score = %I5*N", score)
   $)


   writes("*NEnd of output*N*N")
$)

AND scfn(x, y) = ABS(x-y)

AND max(a, b) = a>=b -> a, b


