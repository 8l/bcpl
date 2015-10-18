SECTION "maze"

GET "libhdr"

MANIFEST $( Good=0; Bad=1 
Left =256; Right =258; Up =260; Down =262
Left1=257; Right1=259; Up1=261; Down1=263
$)

GLOBAL $( maze:200; xupb:201; yupb:202; fringe:203
sysin:204; sysout:205
change:206; found:207
$)

LET start() = VALOF
$( LET argv = VEC 50
   LET rtncode = 0
   LET oldin, oldout = input(), output()

   xupb,yupb := 0,0

   IF rdargs("FROM,TO/K,X,Y", argv, 50)=0 DO
   $( writes("Bad arguments for MAZE*n")
      RESULTIS 20
   $)

   IF argv!0=0 DO argv!0 := "maze.data"

   sysin := findinput(argv!0)
   IF sysin = 0 DO
   $( writef("Can't open file %s*n", argv!0)
      RESULTIS 20
   $)

   sysout := oldout
   UNLESS argv!1=0 DO
   $( sysout := findoutput(argv!1)
      IF sysout=0 DO
      $( writef("Unable to open file %s*n", argv!1)
         endread()
         RESULTIS 20
      $)
   $)
   
   UNLESS argv!2=0 DO xupb := str2numb(argv!2)
   UNLESS argv!3=0 DO yupb := str2numb(argv!3)
   UNLESS 10<=xupb<1000 DO xupb := 60
   UNLESS 10<=yupb<1000 DO yupb := 30

   maze := getvec(yupb)

   FOR y = 0 TO yupb DO
   $( LET line = getvec(xupb)
      FOR x = 0 TO xupb DO line!x := '*s'
      maze!y := line
   $)
   FOR x = 0 TO xupb DO maze!0!x, maze!yupb!x := '-', '-'
   FOR y = 0 TO yupb DO maze!y!0, maze!y!xupb := '|', '|'
   maze!0!0,    maze!yupb!0    := '+', '+'
   maze!0!xupb, maze!yupb!xupb := '+', '+'

   UNLESS read_maze()=Good DO
      writes("Work area too small*n")

   search()

   pr_solution()

   UNLESS sysout=oldout DO
   $( endwrite()
      selectoutput(oldout)
   $)

ret:
   FOR y = 0 TO yupb DO freevec(maze!y)
   freevec(maze)

   RESULTIS rtncode

$)

AND read_maze() = VALOF
$(  LET ch = 0
    LET x, y = 2, 2
    LET res = Good
    LET oldin = input()
    selectinput(sysin)

    $( ch := rdch()
       IF ch='*n' DO $( x, y := 2, y+1; LOOP $)
       IF ch='*s' DO $( x := x+1; LOOP $)
       IF ch=endstreamch BREAK
       IF ch='**' DO ch := '#'
       TEST x>xupb-1 | y>yupb-1 THEN res := Bad
                                ELSE maze!y!x := ch
       x := x+1
    $) REPEAT

    endread()
    selectinput(oldin)
    RESULTIS res
$)

AND search() BE
$( LET pass = 0
   change := TRUE

   $( WHILE change DO
      $( LET nextpass = 1-pass
         change := FALSE
         FOR y = 1 TO yupb-1 FOR x = 1 TO xupb-1 DO
         $( LET ch = maze!y!x
            IF ch='A' | 
               ch=Left+pass | ch=Right+pass | ch=Up+pass | ch=Down+pass DO
            $( try(x+1, y, Left+nextpass)
               try(x-1, y, Right+nextpass)
               try(x, y+1, Up+nextpass)
               try(x, y-1, Down+nextpass)
            $)
         $)
         pass := nextpass
         pr_solution()
      $)
   $)
   RETURN
$)

AND try(x, y, dir) = VALOF
$( LET ch = maze!y!x
   IF ch='*s' DO $( maze!y!x := dir
                    change := TRUE
                 $)
   UNLESS ch='B' RETURN

   $( SWITCHON dir INTO
      $( CASE Left: CASE Left1:  x := x-1; ENDCASE
         CASE Right:CASE Right1: x := x+1; ENDCASE
         CASE Up:   CASE Up1:    y := y-1; ENDCASE
         CASE Down: CASE Down1:  y := y+1; ENDCASE
      $)
      dir := maze!y!x
      IF dir='A' BREAK
      maze!y!x := '**'
   $) REPEAT

   FOR y = 1 TO yupb-1 FOR x = 1 TO xupb-1 DO
      IF maze!y!x>=256 DO maze!y!x := '*s'

   found := TRUE   
$)

AND pr_solution() BE
$( FOR y = 0 TO yupb DO
   $( LET line = maze!y
      LET len = xupb
      UNTIL line!len ~= '*s' DO len := len-1
      FOR x = 0 TO len
      $( LET ch = line!x
         IF ch=Left   DO ch := '<'
         IF ch=Right  DO ch := '>'
         IF ch=Up     DO ch := '^'
         IF ch=Down   DO ch := 'v'
         IF ch=Left1  DO ch := '<'
         IF ch=Right1 DO ch := '>'
         IF ch=Up1    DO ch := '^'
         IF ch=Down1  DO ch := 'v'
         wrch(ch)
      $)
      newline()
   $) 
   newline()
$)


