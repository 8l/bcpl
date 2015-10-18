GET "libhdr"

MANIFEST $( all=#777  $)
 
STATIC $( bestmove=0  $)
 
LET evalpos(side, pos, oppos) = VALOF
 
// SIDE  = 1 for X
//       =-1 for O
//       and is the side who has just moved
// POS   = bit map of postions occupied by side
// OPPOS = bit map for the other side
// the result = 2 if SIDE has already won
//            = 1 if SIDE can force a win
//            = 0 if SIDE can force draw
//            =-1 if SIDE can be beaten
//            =-2 if SIDE is already beaten
 
$( LET otherside = -side
   LET poss = all-pos-oppos
   LET bestsc, bestp = -2, 0
 
   bestmove := 0
 
   IF won(pos)   RESULTIS  2  // the game is already won
   IF won(oppos) RESULTIS -2  // the game is already lost
   IF poss=0     RESULTIS  0  // the game is a draw
 
   UNTIL poss=0 DO
   $( LET p = poss & -poss    // find a place to go
      LET sc = evalpos(otherside, oppos+p, pos)
      IF sc>1  DO sc := 1
      IF sc<-1 DO sc := -1
      IF sc>bestsc DO bestsc, bestp := sc, p
      poss := poss-p
   $)
 
   bestmove := bestp
   RESULTIS -bestsc
$)
 
AND won(pos) = (pos & #700) = #700 |
               (pos & #070) = #070 |
               (pos & #007) = #007 |
               (pos & #111) = #111 |
               (pos & #222) = #222 |
               (pos & #444) = #444 |
               (pos & #124) = #124 |
               (pos & #421) = #421 -> TRUE, FALSE
 
 
LET start() = VALOF
$( LET side, pos, oppos = 1, 0, 0
 
   $( LET ch = rdch()
      SWITCHON capitalch(ch) INTO
      $( DEFAULT: writef("*nBad command character '%c'*n", ch)
                  LOOP
         CASE 'Q':BREAK
 
         CASE '*s':CASE '*n': LOOP
 
         CASE 'N': side, pos, oppos := 1, 0, 0
                   LOOP
 
         CASE '-': pos, oppos := pos<<1, oppos<<1
                   LOOP
 
         CASE 'X': pos, oppos := (pos<<1)+1, oppos<<1
                   LOOP
 
         CASE 'O': pos, oppos := pos<<1, (oppos<<1)+1
                   LOOP
 
         CASE 'P': print(side, pos, oppos)
                   LOOP

         CASE 'S': writef("score = %n*n", evalpos(side, pos, oppos))
                   LOOP

         CASE 'M': $( LET sc = evalpos(side, pos, oppos)
                      LET t = pos
                      UNLESS -1<=sc<=1 DO
                      $( writef("Game already won by %c*n",
                                 side>0 -> 'X', 'O')
                         LOOP
                      $)
                      IF pos+oppos=all DO
                      $( writes("Game finished*n")
                         LOOP
                      $)
                      side, pos, oppos := -side, oppos+bestmove, t
                      print(side, pos, oppos)
                      LOOP
                    $)
      $)
   $) REPEAT
 
   RESULTIS 0
$)
 
 
AND print(side, b1, b2) BE 
$( LET xpos, opos = b1, b2
   IF side<0 DO xpos, opos := b2, b1
   newline()
   FOR i = 0 TO 8 DO
   $( TEST i REM 3 = 0 THEN UNLESS i=0 DO writes("*n---+---+---*n")
                       ELSE writes("|")
      TEST (xpos&256) ~= 0
      THEN writef(" X ")
      ELSE TEST (opos&256) ~= 0
           THEN writes(" O ")
           ELSE writes("   ")
      xpos, opos := xpos<<1, opos<<1
$)
   newline()
$)
 
/* typical console data
XXX OO- ---  P
XXO X-O -XO  P
--- -X- ---  P
O-X -X- ---  P
O-X -XX O--  P
O-X XX- O--  P
-OX -XX O--  P
Q
*/
