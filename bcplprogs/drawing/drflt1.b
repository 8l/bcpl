SECTION "DrFlight"

GET "libhdr"

MANIFEST 
{ BPW    = 32                  // bits per word
  MSB    = BPW-1
  ROWUPB = 896/BPW             // word upb of raster line
  XMAX   = BPW*(ROWUPB+1) - 1  // largest valid x
  YMAX   = 450                 // largest valid y
  RIBSUPB = 20000
}

GLOBAL {
ribv:     200
ribp:     201
spacev:   202
spacet:   203
spacep:   204

currx:    205
curry:    206

fltx:     207
flty:     208
fltz:     209

stdin:    210
stdout:   211
infile:   212
outfile:  213

map:      220
bits:     221

prevribx: 230
prevriby: 231
prevriby0:232
}


LET mkrib(sx, sy, sy0, depth, clr) = VALOF
{ LET p = spacep - 5
  IF p<spacev RESULTIS 0
  p!0, p!1, p!2, p!3, p!4 := sx, sy, sy0, depth, clr
  spacep := p
  RESULTIS p
}

LET initpic() BE FOR i=0 TO YMAX DO
{ LET v = @ bits!(i*(ROWUPB+1))
  map!i := v
  FOR j = 0 TO ROWUPB DO v!j := 0
}

MANIFEST {
  DPI = 300

  // A4 paper size
  A4H = 117 // A4 Height (Inches x 10)
  A4W = 83  // A4 Width (Inches x 10)

  // A4 margins
  A4Tmarg = 10 // Top  (Inches x 10)
  A4Bmarg = 10 // Bottom
  A4Lmarg =  5 // Left
  A4Rmarg =  5 // Right

  A5fac =  71 // percent
  A4fac = 100 // percent
  A3fac = 141 // percent
  A2fac = 200 // percent
  A1fac = 282 // percent
  A0fac = 400 // percent

  Afac = A4fac

  // diagram size in inches x 10  
  YINSx10 = (A4W-A4Lmarg-A4Rmarg)*Afac/100 // allow margins on both sided
  XINSx10 = (A4H-A4Tmarg-A4Bmarg)*Afac/100 // allow margins on top and bottom

  // Margin sizes in pixels
  Tmarg = (DPI*A4Tmarg/10)*Afac/100
  Bmarg = (DPI*A4Bmarg/10)*Afac/100
  Lmarg = (DPI*A4Lmarg/10)*Afac/100
  Rmarg = (DPI*A4Rmarg/10)*Afac/100

  // diagram size in pixels
  YLEN = YINSx10*DPI/10  // pixels across
  XLEN = XINSx10*DPI/10  // number of raster lines
}

LET writeps() BE
{ writes("%%!PS-Adobe-0.0*n")

  writef("/pl { dup*n")
  writef("      length 8 mul 1 true [ 1 0 0 1 0 0 ]*n")
  writef("      4 index*n")
  writef("      imagemask*n")
  writef("      pop*n")
  writef("      0 -1 translate*n") // move down one pixel
  writef("    } bind def*n")

  writef("72 %n div dup scale*n", DPI)  // make 1 unit = 1 pixel
  writef("%n %n translate*n", 
          Lmarg, XLEN+Bmarg) // allow left and bottom margins

  writef("2 2 scale*n")

  writef("%n %n*n", XMAX+1, YMAX+1)
  FOR i=YMAX TO 0 BY -1 DO
  { LET p = map!i
    writef("<")

    FOR j = 0 TO ROWUPB DO
    { LET w = p!j
      IF j REM 8 = 0 DO newline()
      writef("%x8 ", p!j)
    }
    writef(">pl")
  }

  writef("*nshowpage*n")

}

AND drawpt(sx, sy) BE IF 0<=sx<=XMAX & 0<=sy<=YMAX DO
{ LET row = map!sy
  LET i, j = sx/BPW,  MSB - sx REM BPW
  row!i := row!i | 1<<j
}

AND drawto(sx, sy) BE
{ LET mx, my = (currx+sx)/2, (curry+sy)/2

  TEST (mx=sx | mx=currx) & (my=sy | my=curry)
  THEN   drawpt(sx, sy)
  ELSE { drawto(mx, my)
         drawto(sx, sy)
       }

  currx := sx
  curry := sy
}

AND moveto(sx, sy) BE currx, curry := sx, sy

AND drawby(dx, dy) BE drawto(currx+dx, curry+dy)

AND moveby(dx, dy) BE currx, curry := currx+dx, curry+dy

AND scrx(x, y, z) = 100 + (4*x + 2*y)/40

AND scry(x, y, z) = 100 + (4*z + y)/40

AND scrd(x, y, z) = 100 + (4*y - 2*x)/40 // suitable depth for the 
                                         // painter algorithm

AND scrdrawto(x, y, z) BE drawto(scrx(x, y, z), scry(x, y, z))

AND scrmoveto(x, y, z) BE moveto(scrx(x, y, z), scry(x, y, z))

AND storerib(sx, sy, sy0, depth, clr) BE
{ IF prevribx=sx & prevriby=sy & prevriby0=sy0 & clr=0 RETURN

  IF ribp >= RIBSUPB RETURN

  ribp := ribp+1
  ribv!ribp := mkrib(sx, sy, sy0, depth, clr)
  prevribx  := sx
  prevriby  := sy
  prevriby0 := sy0
/*  writef("Rib %i6 %i6 %i6 %i6 %i6*n", i, sx, sy, sy0, depth, clr) */
}

AND fltpt(x, y, z, clr) BE // clr=0 for White  clr=1 for Black
{ LET sx, sy, sy0  = scrx(x,y,z), scry(x,y,z), scry(x,y,0)
  LET sd = scrd(x,y,z)

  fltx, flty, fltz := x, y, z

  IF sx<0 | sx>XMAX | z<0 RETURN

  IF sy0 < 0    DO sy0 := 0
  IF sy  > YMAX DO sy  := YMAX
  IF sy  < sy0  DO sy  := sy0

  storerib(sx, sy, sy0, sd, clr)
}

AND flyto(x, y, z) BE
{ LET mx, my, mz = (fltx+x)/2, (flty+y)/2, (fltz+z)/2
  LET sx, sy = scrx(mx, my, mz), scry(mx, my, mz)

  IF sx=scrx(fltx, flty, fltz) & 
     sy=scry(fltx, flty, fltz) |
     sx=scrx(x, y, z) & 
     sy=scry(x, y, z) RETURN

  flyto(mx, my, mz)
  fltpt(mx, my, mz, 0)
  flyto( x,  y,  z)
}

AND sortribs(v, upb) BE
{ LET m = 1
  UNTIL m>upb DO m := m*3 + 1  // Find first suitable value in the
                                // series:  1, 4, 13, 40, 121, 364, ...
  { m := m/3
    FOR i = m+1 TO upb DO
    { LET vi = v!i
      LET depth = vi!3
      LET j = i
      { LET k = j - m
        LET vk = v!k
        IF k<=0 | vk!3 > depth BREAK
        v!j := vk
        j := k
      } REPEAT
      v!j := vi
    }
  } REPEATUNTIL m=1
}

AND drawribs() BE
{ sortribs(ribv, ribp)

  FOR i = 1 TO ribp DO
  { LET rib = ribv!i
    LET sx, sy, sy0, clr = rib!0, rib!1, rib!2, rib!4
    LET j, k = sx/BPW, MSB - sx REM BPW
    LET jl, kl = (sx-1)/BPW, MSB - (sx-1) REM BPW
    LET jr, kr = (sx+1)/BPW, MSB - (sx+1) REM BPW
    LET bitl, bit, bitr = 1<<kl, 1<<k, 1<<kr
    writef("Rib %i6 %i6 %i6 %i6 %i6 %n*n", i, sx, sy, sy0, rib!3, clr)
    map!sy !jl := map!sy !jl | bitl
    map!sy !j  := map!sy !j  | bit
    map!sy !jr := map!sy !jr | bitr
    map!sy0!jl := map!sy0!jl | bitl
    map!sy0!j  := map!sy0!j  | bit
    map!sy0!jr := map!sy0!jr | bitr
    TEST clr>0 
    THEN FOR k=sy0+1 TO sy-1 DO
         { map!k!jl := map!k!jl | bitl
           map!k!j  := map!k!j  | bit
           map!k!jr := map!k!jr | bitr
         }
    ELSE FOR k=sy0+1 TO sy-1 DO map!k!j := map!k!j & ~bit
  }
}

LET start() = VALOF
{ LET count, retcode = 0, 0
  LET argv = VEC 40
  
  IF rdargs("FROM,TO/K", argv, 40)=0 DO
  { writes("bad arguments for DrFlight*n")
    RESULTIS 20
  }

  IF argv!0=0 DO argv!0 := "FLIGHT"
  IF argv!1=0 DO argv!1 := "FLIGHT.ps"

  writef("Drawing Flight from %s to %s*n", argv!0, argv!1)

  stdin   := input()
  stdout  := output()
  infile  := 0
  outfile := 0
  map     := getvec(YMAX)
  bits    := getvec((YMAX+1)*(ROWUPB+1)-1)
  ribv    := getvec(RIBSUPB)
  spacev  := getvec(5*RIBSUPB)
  spacet  := spacev+5*RIBSUPB

  spacep := spacet
  ribp   := 0;
  
  IF map=0 | bits=0 | ribv=0 | spacev=0 DO 
  { writef("Insufficient space*n")
    retcode := 20
    GOTO ret
  }
    
  infile := findinput(argv!0)
  IF infile=0 DO 
  { writef("Trouble with file %s*n", argv!0)
    retcode := 20
    GOTO ret
  }
    
  outfile := findoutput(argv!1)
  IF outfile=0 DO 
  { writef("Trouble with file %s*n", argv!1)
    retcode := 20
    GOTO ret
  }

  initpic()

  // First draw a frame around the picture
  moveto(0,    0)
  drawto(XMAX, 0)
  drawto(XMAX, YMAX)
  drawto(0,    YMAX)
  drawto(0,    0)
  
  // Now draw the projected ground plane
  FOR i = 0 TO 5 DO { scrmoveto(     0, i*1000, 0)
                      scrdrawto(  5000, i*1000, 0)
                      scrmoveto(i*1000,      0, 0)
                      scrdrawto(i*1000,   5000, 0)
                    }

  // Draw a 1000m vertical line at the origin
  scrmoveto(   0,   0,    0)
  scrdrawto(   0,   0, 1000)
                         
  selectinput(infile)
 
  prevribx, prevriby, prevriby0 := 0, 0, 0 // impossible values


  { LET x = readn()
    LET y = readn()
    LET z = readn()
    IF z<=0 BREAK
    writef("%i7 %i7 %i7*n", x, y, z)
    TEST count=0 THEN fltx, flty, fltz := x, y, z
                 ELSE flyto(x, y, z)
    count := count+1
    IF count REM 1 = 0 DO fltpt(x, y, z, 1)
  } REPEAT

  selectinput(stdin)

  drawribs()

  selectoutput(outfile)  
  writeps()
  selectoutput(stdout)

  writef("Drawing done  ribp = %n*n", ribp)

ret:
  UNLESS map=0    DO freevec(map)
  UNLESS bits=0   DO freevec(bits)
  UNLESS ribv=0   DO freevec(ribv)
  UNLESS spacev=0 DO freevec(spacev)
  UNLESS infile=0 | infile=stdin DO { selectinput(infile); endread() }
  UNLESS outfile=0 | outfile=stdout DO { selectoutput(outfile); endwrite() }

  selectinput(stdin)
  selectoutput(stdout)
  RESULTIS retcode
}
  


