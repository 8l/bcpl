SECTION "RAST2PS"

GET "libhdr"

GLOBAL
{ rasterfile: ug
  rastv
  ml
  mh
  mrange
  mg
  m2yfact
  fl
  fh
  frange
  fg
  f2xfact
  inclfile

  fcount

  maxaddr

  ygrid
  ygrid1
  datafile
  kval
  sval
  ch
  stdin
  stdout

  asize
  Afac
  DPI

  Tmarg
  Bmarg
  Lmarg
  Rmarg

  YINSx10
  XINSx10

  YLEN
  XLEN
}

MANIFEST
{
  // A4 paper size
  A4H = 117 // A4 Height (Inches x 10)
  A4W = 83  // A4 Width (Inches x 10)

  // A4 margins
  A4Tmarg =  5 // Top  (Inches x 10)
  A4Bmarg = 10 // Bottom
  A4Lmarg =  5 // Left
  A4Rmarg = 10 // Right

  A5fac =  71 // percent
  A4fac = 100 // percent
  A3fac = 141 // percent
  A2fac = 200 // percent
  A1fac = 282 // percent
  A0fac = 400 // percent
}
  

LET initpsraster(scale) BE // scale is a percentage
{ LET h,t,u = scale/100, scale/10 REM 10, scale REM 10
  LET xmax = A4H*Afac*72/1000
  LET ymax = A4W*Afac*72/1000
  selectoutput(rasterfile)

  writes("%!PS-Adobe-0.0*n")
  writef("%%%%BoundingBox: %n %n %n %n*n",
           18*scale/100, 30*scale/100,
           ymax*scale/100, xmax*scale/100)

  writef("save*n")
  writef("%n.%n%n %n.%n%n scale*n", h,t,u, h,t,u)

  writef("/YMAX %n def*n", A4W*Afac*72/1000)
  writef("/XMAX %n def*n", A4H*Afac*72/1000)
  writef("/DPI %n def*n", DPI)
  writef("/FL %n 1000000 div def*n", fl)
  writef("/FH %n 1000000 div def*n", fh)
  writef("/ML %n 1000 div def*n", ml)
  writef("/MH %n 1000 div def*n", mh)
  writef("/NMAX %n def*n", XLEN) // Number of raster lines
  writef("/N 0 def*n")

  writef("/SC{dup stringwidth pop -2 div -5 rmoveto show}bind def*n")
  writef("/SL{dup stringwidth pop neg -5 rmoveto show}bind def*n")

  writef("/F1 /Helvetica  findfont 12 scalefont def*n")
  writef("/F2 /Times      findfont 12 scalefont def*n")
  writef("/F3 /Times-Bold findfont 14 scalefont def*n")

  writef("F1 setfont*n")
  writef("YMAX 0 translate*n")
  writef("90 rotate*n")
  writes("% Landscape A%n, origin bottom left, unit=pt*n", asize)

  writef("/FMAX XMAX %n sub def*n", A4Tmarg*72*Afac/1000)
  writef("/MMAX YMAX %n sub def*n", A4Lmarg*72*Afac/1000)

  writef("/F0 %n def*n", A4Bmarg*72*Afac/1000)
  writef("/M0 %n def*n", A4Rmarg*72*Afac/1000)
  writef("/FFAC FMAX F0 sub FH FL sub div def*n")
  writef("/FBAS F0 FL FFAC mul sub def*n")
  writef("/MFAC MMAX M0 sub MH ML sub div def*n")
  writef("/MBAS M0 ML MFAC mul sub def*n")
  
  writef("/FSCALE {FFAC mul FBAS add} bind def*n")
  writef("/MSCALE {MFAC mul MBAS add} bind def*n")
  writef("/SCALE {exch FSCALE exch MSCALE} def*n")
  writef("/MVT {SCALE moveto} def*n")

  writef("/PDL {save 3 index 3 index SCALE translate*n")
  writef("/A 2 index 10 mul def /B 2 index 17.3 mul def*n")
  writef("0 0 moveto A B lineto*n")
  writef("0 6 moveto 0 0 lineto 5.2 3 lineto stroke*n")
  writef("A B moveto 5 9 rmoveto 4 index SC*n")
  writef("restore pop pop pop pop*n")
  writef("} bind def*n")

  writef("/PUL {save 3 index 3 index SCALE translate*n")
  writef("/A 2 index 10 mul def /B 2 index -17.3 mul def*n")
  writef("0 0 moveto A B lineto*n")
  writef("0 -6 moveto 0 0 lineto 5.2 -3 lineto stroke*n")
  writef("A B moveto 5 -9 rmoveto 4 index SC*n")
  writef("restore pop pop pop pop*n")
  writef("} bind def*n")

  writef("/PDR {save 3 index 3 index SCALE translate*n")
  writef("/A 2 index -10 mul def /B 2 index 17.3 mul def*n")
  writef("0 0 moveto A B lineto*n")
  writef("0 6 moveto 0 0 lineto -5.2 3 lineto stroke*n")
  writef("A B moveto -5 9 rmoveto 4 index SC*n")
  writef("restore pop pop pop pop*n")
  writef("} bind def*n")

  writef("/PUR {save 3 index 3 index SCALE translate*n")
  writef("/A 2 index -10 mul def /B 2 index -17.3 mul def*n")
  writef("0 0 moveto A B lineto*n")
  writef("0 -6 moveto 0 0 lineto -5.2 -3 lineto stroke*n")
  writef("A B moveto -5 -9 rmoveto 4 index SC*n")
  writef("restore pop pop pop pop*n")
  writef("} bind def*n")

  writef("/pl { dup length 8 mul 1 true [0 1 1 0 0 N neg] 5 -1 roll*n")
  writef("      imagemask*n")
  writef("/N N 1 add def*n")
  writef("    } bind def*n")

  writef("/TITLE {*n")
  writef("FMAX F0 sub 2 div F0 add M0 40 sub moveto SC} bind def*n")

  IF inclfile DO
  { LET psfile = findinput(inclfile)
    IF psfile DO
    { LET oldin = input()
      LET ch = 0
      selectinput(psfile)
      { LET ch = rdch()
        IF ch=endstreamch BREAK
        wrch(ch)
      } REPEAT
      newline()
      endread()
      selectinput(oldin)
    }
  }    

  writef("F1 setfont*n")
  { //LET g = ml REM mg
    //IF g DO g := ml - g
    LET g = (ml/mg)*mg
    WHILE g <= mh DO
    { writef("M0 %n MSCALE moveto (%nK ) SL*n", g/1000, g/1000)
      g := g + mg
    }
  }

  { //LET g = fl REM fg
    //IF g DO g := fl - g
    LET g = (fl/mg)*mg
    WHILE g <= fh DO
    { LET m = g / 100_000 / 10
      AND d = g / 100_000 REM 10
      writef("%n.%n FSCALE M0 12 sub moveto (%n.%nM) SC*n", m, d, m, d)
      g := g + fg
    }
  }

  writef("F0 M0 translate*n")
  writef("72 DPI div dup scale*n")

  selectoutput(stdout)
}

AND setline(c) BE
  FOR i=0 TO YLEN+1 DO rastv!i := c


AND wrline() BE
{ LET byte, count = 0, 0

  { LET i=ygrid1
    WHILE i<YLEN-1 DO { rastv!i := 1; rastv!(i+1) := 1; i := i+ygrid }
  }
  selectoutput(rasterfile)
  writef("<*n")

  FOR i=0 TO YLEN DO
  { byte := (byte<<1) | rastv!i
    count := count+1
    IF count REM 8 = 0 DO { writehex(byte, 2); byte := 0 }
    IF count REM 256 = 0 DO newline()
  }
  WHILE(byte ~= 0)
  { byte := (byte<<1)
    count := count+1
    IF count REM 8 = 0 DO { writehex(byte, 2); byte := 0 }
    IF count REM 256 = 0 DO newline()
  }
  writef(">pl")
  selectoutput(stdout)
}

AND start() = VALOF
{ LET argv = VEC 50
  LET fromfile = "rastdata"
  LET tofile = "raster.ps"
  LET form =
"FROM,SCALE,TO/K,ML,MH,MG,FL,FH,FG,DPI/K,INCL/K,A5/S,A4/S,A3/S,A2/S,A1/S,A0/S"
  LET scale = 80

  IF rdargs(form, argv, 50)=0 DO
  { writef("Bad args for RAST2PS*n")
    RESULTIS 20
  }

  // Default settings
  ml :=        0
  mh :=   800100
  mg :=   100000
  fl :=        0
  fh := 27100000
  fg :=  5000000

  IF argv!0 DO fromfile := argv!0
  IF argv!1 DO scale := str2numb(argv!1)
  IF argv!2 DO tofile   := argv!2

  IF argv!3 DO ml := str2numb(argv!3)
  IF argv!4 DO mh := str2numb(argv!4)
  IF argv!5 DO mg := str2numb(argv!5)
  IF argv!6 DO fl := str2numb(argv!6)
  IF argv!7 DO fh := str2numb(argv!7)
  IF argv!8 DO fg := str2numb(argv!8)

  // Choose defaults
  Afac, asize := A4fac, 4   // Choose A0, A1, A2, A3, A4 or A5
  DPI  :=   300            // Choose 300 or 600

  IF argv!9  DO DPI := str2numb(argv!9)
  inclfile := "psincl"
  IF argv!10 DO inclfile := argv!10

  IF argv!11 DO Afac, asize := A5fac, 5
  IF argv!12 DO Afac, asize := A4fac, 4
  IF argv!13 DO Afac, asize := A3fac, 3
  IF argv!14 DO Afac, asize := A2fac, 2
  IF argv!15 DO Afac, asize := A1fac, 1
  IF argv!16 DO Afac, asize := A0fac, 0

  // diagram size in inches x 10  
  YINSx10 := (A4W-A4Lmarg-A4Rmarg)*Afac/100 // allow margins on both sided
  XINSx10 := (A4H-A4Tmarg-A4Bmarg)*Afac/100 // allow margins on top and bottom

  // Margin sizes in pixels
  Tmarg := (DPI*A4Tmarg*Afac/1000)
  Bmarg := (DPI*A4Bmarg*Afac/1000)
  Lmarg := (DPI*A4Lmarg*Afac/1000)
  Rmarg := (DPI*A4Rmarg*Afac/1000)

  // diagram size in pixels
  YLEN := YINSx10*DPI/10  // pixels across
  XLEN := XINSx10*DPI/10  // number of raster lines

  mrange  := mh - ml
  m2yfact := muldiv(mrange,         1000, YLEN)
  ygrid   := muldiv(mg,             1000, m2yfact)
  ygrid1  := muldiv(mg - ml REM mg, 1000, m2yfact)
  ygrid1  := ygrid1 REM ygrid

  frange  := fh - fl
  f2xfact := muldiv(frange, 10, XLEN)
  
  fcount := 0
  maxaddr:= 0

  stdin := input()
  stdout := output()

  rastv, datafile, rasterfile := 0, 0, 0

  datafile := findinput(fromfile)
  IF datafile=0 DO
  { writef("Trouble with file: %s*n", fromfile)
    RESULTIS 20
  }

  selectinput(datafile)

  rasterfile := findoutput(tofile)

  IF rasterfile=0 DO
  { writef("Trouble with file: %s*n", tofile)
    endread()
    RESULTIS 20
  }

  writef("Converting %s to %s  size A%n at %n DPI*n",
          fromfile, tofile, asize, DPI)
  writef("Memory from %n to %n*n", ml, mh)
  writef("Fcount from %n to %n*n", fl, fh)

  initpsraster(scale)  // scale is a percentage, default 80   

  scan()

  selectoutput(rasterfile)
  writef("*nshowpage*n")
  endwrite()
  selectoutput(stdout)

  newline()

  selectinput(datafile)
  endread()
  selectinput(stdin)

  freevec(rastv)

  RESULTIS 0
}

AND mark(a, b) BE
{ LET i = muldiv(a*sval - ml, 1000, m2yfact)
  LET j = muldiv(b*sval - ml, 1000, m2yfact)
  IF i>YLEN | j<0 RETURN
  IF i<0 DO i := 0
  IF j>YLEN DO j := YLEN
  FOR p = i TO j DO rastv!p := 1
  rastv!(j+1) := 1
}

AND rdn() = VALOF
{ LET res = 0
  WHILE '0'<=ch<='9' DO { res := 10*res + ch - '0'; ch := rdch() }
  RESULTIS res
}

AND scan() BE
{ LET a, b, tally = 0, 0, 0
  ch := rdch()
  IF ch='K' DO { ch := rdch(); kval := rdn() }
  WHILE ch=' ' DO ch := rdch()
  IF ch='S' DO { ch := rdch(); sval := rdn() }

  rastv := getvec(YLEN+1)

  IF rastv=0 DO
  { writef("Insufficient memory to allocate rastv*n")
    RETURN
  }

  setline(1)
  FOR i=1 TO 2 DO wrline()
  setline(0)

  fcount := 0
  // Skip to beginning of window
  UNTIL fcount>=fl | ch=endstreamch DO
  { UNTIL ch='N' | ch=endstreamch DO ch := rdch()
    IF ch='N' DO { ch := rdch(); fcount := fcount+kval }
  }

  { SWITCHON ch INTO
    { DEFAULT:  writef("Bad ch '%c'*n", ch); abort(1111)
      CASE ' ':
      CASE '*c':
      CASE '*n':ch := rdch(); LOOP

      CASE 'W': ch := rdch(); a := a + rdn(); LOOP
      CASE 'B': ch := rdch()
                b := a + rdn()
                mark(a,b)
                a := b
                LOOP

      CASE 'N': a := 0
                ch := rdch()
      CASE endstreamch:
              
                IF fcount REM fg < kval DO setline(1)
                fcount := fcount + kval
                IF fcount REM 1000000 = 0 DO writef("*nfcount %i8 ", fcount)
                tally := tally - XLEN
                IF tally>=0 LOOP

                { tally := tally + (fh-fl)/kval
                  wrline()
                } REPEATUNTIL tally>0

                IF fcount>=fh RETURN
                setline(0)
                LOOP
    } REPEAT
  }
}






