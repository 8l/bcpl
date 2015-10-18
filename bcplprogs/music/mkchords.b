/*
This program creates a .mus file to test a listener's ability
to recognise triads in root and first and second inversions in
random major and minor keys.

Implemented by Martin Richards (c) March 2009.

Usage:

mkchords "n/N,seed/N,to/K,set/N,*
         *major/S,minor/S,*
         *root/S,first/S,second/S,seq/S"

n          The number of test chords
seed       The random number seed
to         The name of the .mus file to be created
           default chords.mus
set        A decimal number whose digits indicate which chords
           a allowed, eg 145 for tonic subdominant and dominant
           default 1234567
major      Major keys allowed
minor      Minor keys allowed
           If neither is specified both major and minor ar allowed
root       Triads in root position are allowed
first      First inversion triads are allowed
second     Second inversion triads are allowed
           If none is specified all three inversions are allowed
seq        Generate all selected triads in sequence
*/

GET "libhdr"

GLOBAL {
  barcount:ug
  stdin
  stdout
  barcount
  majorscale
  minorscale
}

LET start() = VALOF
{ LET format = "n/N,seed/N,to/K,set/N,*
               *major/S,minor/S,*
               *root/S,first/S,second/S,seq/S"
  LET argv = VEC 50
  LET n = 7
  LET tofilename = "chords.mus"
  LET tostream = 0
  LET set = 1234567
  LET seed = 0
  LET root, first, second = TRUE, TRUE, TRUE
  LET major, minor = TRUE, TRUE
  LET sequence = FALSE

  stdin, stdout := input(), output()
  barcount := 0
  majorscale := TABLE  0,  2,  4,  5,  7,  9, 11,      // Major scale
                      12, 14, 16, 17, 19, 21, 23
  minorscale := TABLE  0,  2,  3,  5,  7,  8, 10,      // Minor scale
                      12, 14, 15, 17, 19, 20, 22

  UNLESS rdargs(format, argv, 50) DO
  { writef("Bad args for: %s*n", format)
    RESULTIS 0
  }

  IF argv!0 DO n := !(argv!0)        // n/N   Number of tests
  IF argv!1 DO seed := !(argv!1)     // seed/N   Random number seed
  IF argv!2 DO tofilename := argv!2  // to/K  TO filename
  IF argv!3 DO set := !(argv!3)      // set/N   Allowable chords

  IF argv!4 | argv!5 DO major, minor := FALSE, FALSE
  IF argv!4 DO major := TRUE          // major/S  Allow major scales
  IF argv!5 DO minor := TRUE          // minor/S  Allow minor scales

  IF argv!6 | argv!7 | argv!8 DO root, first, second := FALSE, FALSE, FALSE
  IF argv!6 DO root   := TRUE        // root/S    Allow root position
  IF argv!7 DO first  := TRUE        // first/S   Allow first inversion
  IF argv!8 DO second := TRUE        // second/S  Allow second inversion
  IF argv!9 DO sequence := TRUE      // seq/S     Generate all selected chords

  newline()
  writef("Generating file: %s*n", tofilename)
  TEST sequence
  THEN writef("Containing all selected triads*n")
  ELSE writef("Containing %n random test chords, seed=%n*n", n, seed)
  writef("Allowable chords; %n*n", set)
  writef("modes:           ")
  IF major DO writef(" major")
  IF minor DO writef(" minor")
  newline()
  writef("Positions:       ")
  IF root   DO writef(" root")
  IF first  DO writef(" first-inversion")
  IF second DO writef(" second_inversion")
  newline()

  tostream := findoutput(tofilename)
  UNLESS tostream DO
  { writef("Unable to open file: %s*n", tofilename)
    RESULTIS 0
  }

  IF seed DO setseed(seed)

  selectoutput(tostream)

  writef("$get!mushdr;*n");
  writef("\score *"Chords*" [*n");

  writef("*n\part*n");
  writef(" ( \name *"Piano part*"*n");
  writef("   $piano;*n*n")


  TEST sequence
  THEN gensequence(n, set, major, minor, root, first, second)
  ELSE gentests(n, set, major, minor, root, first, second)

  writef(" )*n")

  writef("\conductor*n");
  writef(" ( \name *"conductor*"*n");
  writef("   s1\tempo(96) |*n");
  writef("$rep!%n!   s1 |*n;*n", barcount);
  writef("   s1 ||*n");
  writef(" )*n*n");

  writef("]*n")

  endstream(tostream)
  selectoutput(stdout)
  writef("*n%n bars generated*n", barcount)

  RESULTIS 0
}

AND gensequence(n, set, major, minor, root, first, second) BE
{ FOR p = 1 TO 7 IF contains(set, p) DO
  { LET pos = p-1
    LET p0, p2, p4, p7, p9 = pos+0, pos+2, pos+4, pos+7, pos+9
    IF major & root   DO genchord(0, pos, 0, p0, p2, p4) 
    IF major & first  DO genchord(0, pos, 1, p2, p4, p7) 
    IF major & second DO genchord(0, pos, 2, p4, p7, p9) 
    IF minor & root   DO genchord(1, pos, 0, p0, p2, p4) 
    IF minor & first  DO genchord(1, pos, 1, p2, p4, p7) 
    IF minor & second DO genchord(1, pos, 2, p4, p7, p9) 
  }
}

AND genchord(mode, pos, inversion, x, y, z) BE
{ LET scale = mode=0 -> majorscale, minorscale
  IF x>=7 DO x, y, z := x-7, y-7, z-7
  sawritef("Position: %n  inversion: %n ", pos+1, inversion)
  sawritef(mode=0 -> " major", " minor")
  sawritef("    4%t4 4%t4 4%t4*n",
            notename(scale!x),
            notename(scale!y),
            notename(scale!z))

  // Place a comment
  writef("*n%%Position: %n  inversion: %n %s*n",
          pos+1,
          inversion,
          mode=0 -> " major", " minor")

  barcount := barcount+1
  writef("[4%s4$mf; 4%s 4%s] [4%s2 4%s 4%s] r4  | // %n*n",
          notename(scale!0),
          notename(scale!2),
          notename(scale!4),
          notename(scale!x),
          notename(scale!y),
          notename(scale!z),
          barcount)
}

AND gentests(n, set, major, minor, root, first, second) BE
{ FOR i = 1 TO n DO
  { LET pos = -1         // Chord position 0=tonic to 6=VII
    LET mode = -1        // 0 = major  1 = minor
    LET inversion = -1   // 0 = root  1=first  2=second
    LET scale = 0

    // Choose a random key
    LET trans = randno(12)-1 // transposition 0 to 11

    // Choose a random triad
    WHILE pos<0 DO
    { LET p = randno(7)
      IF contains(set, p) DO { pos := p-1; BREAK }
    }

    WHILE inversion<0 DO
    { // Choose a random inversion
      LET p = randno(3)
//sawritef("inversion=%n p=%n*n", inversion, p)
//abort(1000)
      IF p=1 & root   DO inversion := 0
      IF p=2 & first  DO inversion := 1
      IF p=3 & second DO inversion := 2
    }

    // Choose a random mode
    WHILE mode<0 TEST randno(100)>50
                 THEN IF major DO mode, scale := 0, majorscale
                 ELSE IF minor DO mode, scale := 1, minorscale

    
    { LET k1, k2, k3 = 0, 2, 4
      LET a1, a2, a3 = pos+0, pos+2, pos+4
      LET b1, b2, b3 = pos+2, pos+4, pos+7
      LET c1, c2, c3 = pos+4, pos+7, pos+9
      LET x1, x2, x3 = a1, a2, a3
      IF b1>=7 DO b1, b2, b3 := b1-7, b2-7, b3-7
      IF c1>=7 DO c1, c2, c3 := c1-7, c2-7, c3-7
      
      IF inversion=1 DO x1, x2, x3 := b1, b2, b3
      IF inversion=2 DO x1, x2, x3 := c1, c2, c3

      //sawritef("transposition: %n*n", trans)
      sawritef("Position: %n  inversion: %n ", pos+1, inversion)
      sawritef(mode=0 -> " major", " minor")
      sawritef("    4%t4 4%t4 4%t4*n",
                notename(scale!x1),
                notename(scale!x2),
                notename(scale!x3))

      // Place a comment
      writef("*n%%Position: %n  inversion: %n ", pos+1, inversion)
      writef(mode=0 -> " major", " minor")
      newline()

      //Set the key
      writef("*n\transposition(%s)*n", notename(trans))

      // Play the key note
      writef("4%s4~$f;$leg8; ", notename(scale!k1))

      // Play the key arpeggio, up and down one octave.
      barcount := barcount+1
      writef("s2\tuplet(4%s8$mp; 4%s 4%s 4%s' 4%s 4%s) 4%s4   | // %n*n",
              notename(scale!k1),
              notename(scale!k2),
              notename(scale!k3),
              notename(scale!k1),
              notename(scale!k3),
              notename(scale!k2),
              notename(scale!k1),
              barcount)

      // Play the key triad.
      barcount := barcount+1
      writef("[4%s2 4%s 4%s]$f; r2 | // %n*n",
              notename(scale!k1),
              notename(scale!k2),
              notename(scale!k3),
              barcount)

      // Play the test triad, twice.
      FOR i = 1 TO 2 DO
      { barcount := barcount+1
        writef("[4%s2. 4%s. 4%s.] r4 | // %n*n",
                notename(scale!x1),
                notename(scale!x2),
                notename(scale!x3),
                barcount)
      }

      // Play notes up to the root of the test triad.
      barcount := barcount+1
      writef("r2\tuplet(")
      FOR p = 0 TO a1 DO writef(" 4%s", notename(scale!p))
      writef(") ")

      // Play the test triad in root, then first and second inversions
      writef("[4%s2 4%s 4%s] | // %n*n",
              notename(scale!a1), // Root position
              notename(scale!a2),
              notename(scale!a3),
              barcount)

      barcount := barcount+1
      writef("[4%s2 4%s 4%s] [4%s 4%s 4%s] | // %n*n",
              notename(scale!b1), // First inversion
              notename(scale!b2),
              notename(scale!b3),
              notename(scale!c1), // Second inversion
              notename(scale!c2),
              notename(scale!c3),
              barcount)

      // Play the test triad, as a spread chord.
      barcount := barcount+1
      writef("[4%s4 4%s 4%s] r4 [4%s2 (r8 4%s4.) (r4 4%s4)] | // %n*n",
              notename(scale!x1), // The test chord
              notename(scale!x2),
              notename(scale!x3),
              notename(scale!x1), // The test chord
              notename(scale!x2),
              notename(scale!x3),
              barcount)

      // Play the key triad
      barcount := barcount+1
      writef("r2 [4%s2 4%s 4%s] | // %n*n",
              notename(scale!k1),
              notename(scale!k2),
              notename(scale!k3),
              barcount)

      // Play the test triad
      barcount := barcount+1
      writef("[4%s2 4%s 4%s] r2 | // %n*n",
              notename(scale!x1),
              notename(scale!x2),
              notename(scale!x3),
              barcount)

      // One bar's rest at the end of this test
      barcount := barcount+1
      writef("r1 | // %n*n", barcount)
    }
  }
}

AND contains(s, p) = VALOF
{ WHILE s DO
  { IF p = s MOD 10 RESULTIS TRUE
    s := s/10
  }
  RESULTIS FALSE
}

AND notename(n) = VALOF SWITCHON n INTO
{ DEFAULT: RESULTIS "XXX"

  CASE  0:  RESULTIS "c"
  CASE  1:  RESULTIS "des"
  CASE  2:  RESULTIS "d"
  CASE  3:  RESULTIS "ees"
  CASE  4:  RESULTIS "e"
  CASE  5:  RESULTIS "f"
  CASE  6:  RESULTIS "ges"
  CASE  7:  RESULTIS "g"
  CASE  8:  RESULTIS "aes"
  CASE  9:  RESULTIS "a"
  CASE 10:  RESULTIS "bes"
  CASE 11:  RESULTIS "b"
  CASE 12:  RESULTIS "c'"
  CASE 13:  RESULTIS "des'"
  CASE 14:  RESULTIS "d'"
  CASE 15:  RESULTIS "ees'"
  CASE 16:  RESULTIS "e'"
  CASE 17:  RESULTIS "f'"
  CASE 18:  RESULTIS "ges'"
  CASE 19:  RESULTIS "g'"
  CASE 20:  RESULTIS "aes'"
  CASE 21:  RESULTIS "a'"
  CASE 22:  RESULTIS "bes'"
  CASE 23:  RESULTIS "b'"
}

