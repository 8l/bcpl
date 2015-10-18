/* 

This a program to generate random lists of scales, appeggios, dominant
sevenths, dimished sevenths and cromatic scales for horn grade 7 and
8.

Implemented by Martin Richards (c) October 2009

usage:

scales "to/k,grage/k/n,g8/s,major/s,minor/s,
        arpeg/s,dom7/s,dim7/s,chrom/s,whole/s,rand/k/n,sig/s"

to <filename>  destination file
grade <num>    grade number, currently only 7 or 8
major          generate major keys
minor          generate minor keys
arpeg          generate arpeggios
dom7           generate dominant sevenths
dim7           generate diminished sevenths
chrom          generate chomatic scales
whole          generate whole to scales
rand 0         do not randomise the list
rand n         randomise the list using random seed n
sig            generate the key signature

Examples

scales grade 7 to g7scales.txt sig
scales grade 7 to g7scales1.txt rand 1
*/

GET "libhdr"

GLOBAL {
  toname: ug
  tostream
  stdin
  stdout
  data     // -> [upb, pos, v] v has upper bound upb
           //                  v!1 to v!pos currently valid
           // v is enlarged as necessary
  t        // Add a scale to v
  shuffle  // Shuffle the elements of v

  grade    // = 1<<7 or 1<<8
  genmajor //      generate major keys
  genminor //      generate minor keys
  genscale //      generate arpeggios
  genarpeg //      generate arpeggios
  gendom7  //      generate dominant sevenths
  gendim7  //      generate diminished sevenths
  genchromatic //      generate chomatic scales
  genwhole //      generate whole to scales
  sortseed //      random number seed
  gensig   //      generate the key signature

}

MANIFEST {
  A=1; Aes; Ais
  B;   Bes; Bis
  C;   Ces; Cis
  D;   Des; Dis
  E;   Ees; Eis
  F;   Fes; Fis
  G;   Ges; Gis

  Major; Minor; MelMinor; HarMinor
  Arpeg; MinArpeg
  Chromatic
  Whole
  Dim7; Dom7

  Lo = 1; Hi=2

  Slurred  = 1
  Legato   = 2
  Staccato = 3

  G7 = 1<<7
  G8 = 1<<8
}


LET start() = VALOF
{ LET argv = VEC 50
  LET upb, n, v = 0, 0, 0
  data := @upb

  stdin, stdout := input(), output()
  toname, tostream := 0, 0

  grade := 1<<7
  sortseed := 0
  gensig := FALSE

  UNLESS rdargs("to/k,grade/k/n,major/s,minor/s,scale/s,arpeg/s,*
                *dom7/s,dim7/s,chrom/s,whole/s,rand/k/n,sig/s", argv, 50) DO
  { writef("Bad arguments for SCALES*n")
    GOTO fin
  }

  IF argv!0 DO toname := argv!0        // to/k
  IF argv!1 DO grade := 1<<!(argv!1)   // grade/k/n
  genmajor := argv!2                   // major/s
  genminor := argv!3                   // minor/s
  genscale := argv!4                   // scale/s
  genarpeg := argv!5                   // arpeg/s
  gendom7  := argv!6                   // dom7/s
  gendim7  := argv!7                   // dim7/s
  genchromatic := argv!8               // chromatic/s
  genwhole  := argv!9                  // whole/s

  IF argv!10 DO sortseed := !(argv!10) // seed/k/n
  gensig := argv!11                    // sig/s

  UNLESS genmajor | genminor DO genmajor, genminor := TRUE, TRUE

  UNLESS genscale | genarpeg | gendom7 | gendim7 |
         genchromatic | genwhole DO
  { genscale, genarpeg, gendom7, gendim7 := TRUE, TRUE, TRUE, TRUE
    genchromatic, genwhole := TRUE, TRUE
  }

  scales()

//writef("sortseed = %n*n", sortseed)

  IF sortseed DO
  { setseed(sortseed)
    // Shuffle the elements of v
    FOR i = n TO 2 BY -1 DO
    { LET k = randno(i) // random in range 1..i
      LET x, y = v!k, v!i
//writef("Swapping %i3 with %i3*n", k, i)
      v!k, v!i := y, x
    }
  }

  IF toname DO
  { tostream := findoutput(toname)
    IF tostream DO selectoutput(tostream)
  }

  FOR i = 1 TO n DO prscale(i, v!i)

  selectoutput(stdout)
fin:
  IF v DO freevec(v)
  IF tostream DO endstream(tostream)
  RESULTIS 0
}

AND scales() BE {
// t(key-sig, note, grades, octaves, high)

t(-4, Aes, Major, G7+G8, 2, Lo)
t( 3, A,   Major, G7,    2, Lo+Hi)
t( 3, A,   Major, G8,    3, Lo)
t(-2, Bes, Major, G7,    2, Lo+Hi)
t(-2, Bes, Major, G8,    3, Lo)
t( 5, B,   Major, G7,    2, Lo)
t( 5, B,   Major, G8,    3, Lo)
t( 0, C,   Major, G7+G8, 2, Lo)
t(-5, Des, Major, G7+G8, 2, Lo)
t( 2, D,   Major, G7+G8, 2, Lo)
t(-3, Ees, Major, G7+G8, 2, Lo)
t(-1, F,   Major, G7+G8, 2, Lo)
t( 4, E,   Major, G7+G8, 2, Lo)
t( 6, Fis, Major, G7+G8, 2, Lo)
t( 1, G,   Major, G7+G8, 2, Lo)
t( 1, G,   Major, G7+G8, 2, Lo)

t( 0, A,   MelMinor, G7,    2, Lo+Hi)
t( 0, A,   MelMinor, G8,    3, Lo)
t( 0, A,   HarMinor, G7,    2, Lo+Hi)
t( 0, A,   HarMinor, G8,    3, Lo)
t(-5, Bes, MelMinor, G7,    2, Lo+Hi)
t(-5, Bes, MelMinor, G8,    3, Lo)
t(-5, Bes, HarMinor, G7,    2, Lo+Hi)
t(-5, Bes, HarMinor, G8,    3, Lo)
t( 2, B,   MelMinor, G7,    2, Lo)
t( 2, B,   MelMinor, G8,    3, Lo)
t( 2, B,   HarMinor, G7,    2, Lo)
t( 2, B,   HarMinor, G8,    3, Lo)
t(-3, C,   MelMinor, G7+G8, 2, Lo)
t(-3, C,   HarMinor, G7+G8, 2, Lo)
t( 4, Cis, MelMinor, G7+G8, 2, Lo)
t( 4, Cis, HarMinor, G7+G8, 2, Lo)
t(-1, D,   MelMinor, G7+G8, 2, Lo)
t(-1, D,   HarMinor, G7+G8, 2, Lo)
t(-6, Ees, MelMinor, G7+G8, 2, Lo)
t(-6, Ees, HarMinor, G7+G8, 2, Lo)
t( 1, E,   MelMinor, G7+G8, 2, Lo)
t( 1, E,   HarMinor, G7+G8, 2, Lo)
t(-4, F,   MelMinor, G7+G8, 2, Lo)
t(-4, F,   HarMinor, G7+G8, 2, Lo)
t( 3, Fis, MelMinor, G7+G8, 2, Lo)
t( 3, Fis, HarMinor, G7+G8, 2, Lo)
t(-2, G,   MelMinor, G7+G8, 2, Lo)
t(-2, G,   HarMinor, G7+G8, 2, Lo)
t( 5, Gis, MelMinor, G7+G8, 2, Lo)

t( 0, C,   Chromatic, G7+G8, 2, Lo)
t( 0, Cis, Chromatic, G7+G8, 2, Lo)
t( 0, D,   Chromatic, G7+G8, 2, Lo)
t( 0, Dis, Chromatic, G7+G8, 2, Lo)
t( 0, E,   Chromatic, G7+G8, 2, Lo)
t( 0, F,   Chromatic, G7+G8, 2, Lo)
t( 0, Fis, Chromatic, G7+G8, 2, Lo)
t( 0, G,   Chromatic, G7+G8, 2, Lo)
t( 0, Gis, Chromatic, G7+G8, 2, Lo)
t( 0, A,   Chromatic, G7+G8, 2, Lo+Hi)
t( 0, Bes, Chromatic, G7+G8, 2, Lo+Hi)
t( 0, B,   Chromatic, G7+G8, 2, Lo)

t(-4, Aes, Arpeg, G7+G8, 2, Lo)
t( 3, A,   Arpeg, G7,    2, Lo+Hi)
t( 3, A,   Arpeg, G8,    3, Lo)
t(-2, Bes, Arpeg, G7,    2, Lo+Hi)
t(-2, Bes, Arpeg, G8,    3, Lo)
t( 5, B,   Arpeg, G7,    2, Lo)
t( 5, B,   Arpeg, G8,    3, Lo)
t( 0, C,   Arpeg, G7+G8, 2, Lo)
t(-5, Des, Arpeg, G7+G8, 2, Lo)
t( 2, D,   Arpeg, G7+G8, 2, Lo)
t(-3, Ees, Arpeg, G7+G8, 2, Lo)
t( 4, E,   Arpeg, G7+G8, 2, Lo)
t( 6, Fis, Arpeg, G7+G8, 2, Lo)
t( 1, G,   Arpeg, G7+G8, 2, Lo)
t( 1, G,   Arpeg, G7+G8, 2, Lo)

t( 0, A,   MinArpeg, G7,    2, Lo+Hi)
t( 0, A,   MinArpeg, G8,    3, Lo)
t(-5, Bes, MinArpeg, G7,    2, Lo+Hi)
t(-5, Bes, MinArpeg, G8,    3, Lo)
t( 2, B,   MinArpeg, G7,    2, Lo)
t( 2, B,   MinArpeg, G8,    3, Lo)
t(-3, C,   MinArpeg, G7+G8, 2, Lo)
t( 4, Cis, MinArpeg, G7+G8, 2, Lo)
t(-1, D,   MinArpeg, G7+G8, 2, Lo)
t(-6, Ees, MinArpeg, G7+G8, 2, Lo)
t( 1, E,   MinArpeg, G7+G8, 2, Lo)
t(-4, F,   MinArpeg, G7+G8, 2, Lo)
t( 3, Fis, MinArpeg, G7+G8, 2, Lo)
t(-2, G,   MinArpeg, G7+G8, 2, Lo)
t( 5, Gis, MinArpeg, G7+G8, 2, Lo)

t(-4, Aes, Dom7, G8,    2, Lo)
t( 3, A,   Dom7, G8,    2, Lo)
t(-2, Bes, Dom7, G8,    2, Lo)
t( 5, B,   Dom7, G7+G8, 2, Lo)
t( 0, C,   Dom7, G7+G8, 2, Lo)
t(-5, Des, Dom7, G7+G8, 2, Lo)
t( 2, D,   Dom7, G7+G8, 2, Lo)
t(-3, Ees, Dom7, G8,    2, Lo)
t( 4, E,   Dom7, G8,    2, Lo)
t(-1, F,   Dom7, G8,    2, Lo)
t( 6, Fis, Dom7, G8,    2, Lo)
t( 1, G,   Dom7, G8,    2, Lo)

t( 0, G,   Dim7, G8,    2, Lo)
t( 0, Aes, Dim7, G7+G8, 2, Lo)
t( 0, A,   Dim7, G8,    2, Lo)
t( 0, C,   Dim7, G7,    2, Lo)

t( 0, C,   Whole, G8,    2, Lo)
t( 0, B,   Whole, G8,    2, Lo)

}

AND t(keysig, note, type, grades, octaves, high) BE IF (grade&grades)~=0 DO
{ // type = Major      Major scale
  //        MelMinor   Melodic Minor
  //        HarMinor   Harmonic Minor
  //        Arpeg      Major Arpeggio
  //        MinArpeg   Minor Arpeggio
  //        Dom7       Dominant seventh
  //        Dim7       Diminished seventh starting on
  //        Chromatic  Chromatic scale starting on
  //        Whole      Whole tone scale starting on
  LET w = 8+keysig |
          octaves<<4 |
          note<<8  |
          type<<16

  SWITCHON type INTO
  { DEFAULT: RETURN
    CASE Major:     // Major scale
      UNLESS genmajor & genscale RETURN
      ENDCASE
    CASE MelMinor:  // Melodic Minor
      UNLESS genminor & genscale RETURN
      ENDCASE
    CASE HarMinor:  // Harmonic Minor
      UNLESS genminor & genscale RETURN
      ENDCASE
    CASE Arpeg:     // Major Arpeggio
      UNLESS genmajor & genarpeg RETURN
      ENDCASE
    CASE MinArpeg:  // Minor Arpeggio
      UNLESS genminor & genarpeg RETURN
      ENDCASE
    CASE Dom7:      // Dominant seventh
      UNLESS gendom7 RETURN
      ENDCASE
    CASE Dim7:      // Diminished seventh starting on
      UNLESS gendim7 RETURN
      ENDCASE
    CASE Chromatic: // Chromatic scale starting on
      UNLESS genchromatic RETURN
      ENDCASE
    CASE Whole:     // Whole tone scale starting on
      UNLESS genwhole RETURN
      ENDCASE
  }

  push(data, w + (Slurred<<28))
  push(data, w + (Legato<<28))
  push(data, w + (Staccato<<28))
  IF (high&Hi)~=0 DO
  { push(data, w + (1<<24) + (Slurred<<28))
    push(data, w + (1<<24) + (Legato<<28))
    push(data, w + (1<<24) + (Staccato<<28))
  }
}

AND prscale(i, w) BE
{ LET keysig  = (w & #x0F) - 8
  LET octaves = (w>>4) & #xF
  LET note    = (w>>8) & #xFF
  LET type    = (w>>16) & #xFF
  LET hi      = (w>>24) & #x0F
  LET tonging = w>>28

  writef("%i3:  ", i)

  IF gensig DO
  { TEST keysig
    THEN TEST keysig<0
         THEN writef("%nb", -keysig)
         ELSE writef("%n#",  keysig)
    ELSE      writef("  ")
  }

  SWITCHON type INTO
  { DEFAULT:
    CASE Major:     // Major scale
      writef(" %t2 Major Scale", op2str(note))
      ENDCASE
    CASE MelMinor:  // Melodic Minor
      writef(" %t2 Melodic Minor Scale", op2str(note))
      ENDCASE
    CASE HarMinor:  // Harmonic Minor
      writef(" %t2 Harmonic Minor Scale", op2str(note))
      ENDCASE
    CASE Arpeg:     // Major Arpeggio
      writef(" %t2 Major Arpeggio", op2str(note))
      ENDCASE
    CASE MinArpeg:  // Minor Arpeggio
      writef(" %t2 Minor Arpeggio", op2str(note))
      ENDCASE
    CASE Dom7:      // Dominant seventh
      writef(" %t2 Dominant seventh", op2str(note))
      ENDCASE
    CASE Dim7:      // Diminished seventh starting on
      writef("    Diminished seventh starting on %s", op2str(note))
      ENDCASE
    CASE Chromatic: // Chromatic scale starting on
      writef("    Chromatic scale starting on %s", op2str(note))
      ENDCASE
    CASE Whole:     // Whole tone scale starting on
      writef("    Whole-tone scale starting on %s", op2str(note))
      ENDCASE
  }

  writef(", %n octaves", octaves)
  IF hi DO writef(", high")
  IF tonging=Slurred  DO writef(", Slurred")
  IF tonging=Legato   DO writef(", Legato")
  IF tonging=Staccato DO writef(", Staccato")
  newline()
}

AND push(dv, w) BE
{ LET upb = dv!0
  LET pos = dv!1
  LET v   = dv!2

  IF pos>=upb DO
  { LET nupb = 2*upb + 100
    LET nv = getvec(nupb)
    FOR i = 1 TO pos DO nv!i := v!i
    freevec(v)
    upb, v := nupb, nv
    dv!0, dv!2 := upb, v
  }
  pos := pos+1
  dv!1, v!pos := pos, w
//sawritef("push: pos=%i3 w=%x8*n", pos, w)
}

AND op2str(op) = VALOF SWITCHON op INTO
{ DEFAULT: RESULTIS "Bad note"
  CASE A:   RESULTIS "A"
  CASE Aes: RESULTIS "Ab"
  CASE Ais: RESULTIS "A#"
  CASE B:   RESULTIS "B"
  CASE Bes: RESULTIS "Bb"
  CASE Bis: RESULTIS "B#"
  CASE C:   RESULTIS "C"
  CASE Ces: RESULTIS "Cb"
  CASE Cis: RESULTIS "C#"
  CASE D:   RESULTIS "D"
  CASE Des: RESULTIS "Db"
  CASE Dis: RESULTIS "D#"
  CASE E:   RESULTIS "E"
  CASE Ees: RESULTIS "Eb"
  CASE Eis: RESULTIS "E#"
  CASE F:   RESULTIS "F"
  CASE Fes: RESULTIS "Fb"
  CASE Fis: RESULTIS "F#"
  CASE G:   RESULTIS "G"
  CASE Ges: RESULTIS "Gb"
  CASE Gis: RESULTIS "G#"
}
