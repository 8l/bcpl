SECTION "DrFlight"

GET "libhdr"

MANIFEST 
{ BPW    = 32                  // bits per word
  ROWUPB = 896/BPW             // word upb of raster line
  XMAX   = BPW*(ROWUPB+1) - 1  // largest valid x
  YMAX   = 450                 // largest valid y
}

GLOBAL {
ribv:     200
ribp:     201
spacev:   202
spacet:   203
spacep:   204

currx:    205
curry:    206
currz:    207

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


LET mk4(a, b, c, d) = VALOF
{ LET p = spacep - 4
  IF p<spacev RESULTIS 0
  p!0, p!1, p!2, p!3 := a, b, c, d
  spacep := p
  RESULTIS p
}

LET initpic() BE FOR i=0 TO YMAX DO
{ LET v = @ bits!(i*(ROWUPB+1))
  map!i := v
  FOR j = 0 TO ROWUPB DO v!j := 0
}

LET writepbm() BE
{ writes("P1*n")
  writef("# flight.pbm*n")
  writef("%n %n*n", XMAX+1, YMAX+1)
  FOR i=YMAX TO 0 BY -1 DO
  { LET p = map!i

    FOR j = 0 TO ROWUPB DO
    { LET w = p!j
      FOR pos = 0 TO BPW-1 DO writef(" %n", (w>>pos) & 1)
    }
    newline()
  }
}

AND drawpt(x, y) BE IF 0<=x<=XMAX & 0<=y<=YMAX DO
{ LET row = map!y
  LET i, j = x/BPW,  x REM BPW
  row!i := row!i | 1<<j
}

AND drawto(x, y) BE
{ LET mx, my = (currx+x)/2, (curry+y)/2

  TEST (mx=x | mx=currx) & (my=y | my=curry)
  THEN   drawpt(x, y)
  ELSE { drawto(mx, my)
         drawto(x, y)
       }

  currx := x
  curry := y
}

AND moveto(x, y) BE currx, curry := x, y

AND drawby(dx, dy) BE drawto(currx+dx, curry+dy)

AND moveby(dx, dy) BE currx, curry := currx+dx, curry+dy

AND scrx(x, y, z) = 100 + (4*x + 2*y)/40

AND scry(x, y, z) = 100 + (4*z + y)/40

AND scrz(x, y, z) = 100 + (4*y - 2*x)/40 // suitable depth for the 
                                         // painter algorithm

AND scrdrawto(x, y, z) BE drawto(scrx(x, y, z), scry(x, y, z))

AND scrmoveto(x, y, z) BE moveto(scrx(x, y, z), scry(x, y, z))

AND storerib(x, y, y0, dc) BE
{ IF prevribx=x & prevriby=y & prevriby0=y0 & dc&1=0 RETURN

  IF ribp >= 20000 RETURN

  ribp := ribp+1
  ribv!ribp := mk4(x, y, y0, dc)
  prevribx  := x
  prevriby  := y
  prevriby0 := y0
/*  writef("Rib %i7 %i7 %i7 %i7 %i7*n", i, x, y, y0, dc) */
}

AND draw3pt(x, y, z, clr) BE // clr=0 for White  clr=1 for Black
{ LET sx, sy, sy0  = scrx(x,y,z), scry(x,y,z), scry(x,y,0)
  LET sz = scrz(x,y,z)

  IF sx<0 | sx>XMAX | z<0 RETURN

  IF sy0 < 0    DO sy0 := 0
  IF sy  > YMAX DO sy  := YMAX
  IF sy  < sy0  DO sy  := sy0
  IF x=0 & y=0  DO clr := 1

  storerib(sx, sy, sy0, 2*sz-clr)
}

AND move3to(x, y, z) BE currx, curry, currz := x, y, z

AND draw3to(x, y, z) BE
{ LET mx, my, mz = (currx+x)/2, (curry+y)/2, (currz+z)/2

  IF scrx(mx,my,mz)=scrx(currx, curry, currz) & 
     scry(mx,my,mz)=scry(currx, curry, currz) &
     scrx(mx,my,mz)=scrx(x, y, z) & 
     scry(mx,my,mz)=scry(x, y, z) DO
  { draw3pt(x, y, z, 0)
    currx := x
    curry := y
    currz := z
    RETURN
  }
//  TEST (mx=x | mx=currx) & (my=y | my=curry) & (mz=z | mz=currz)
//  THEN   draw3pt(x, y, z, 0)
//  ELSE { 
    draw3to(mx, my, mz)
    draw3to( x,  y,  z)
//       }

  currx := x
  curry := y
  currz := z
}

AND sortribs(v, upb) BE
{ LET m = 1
  UNTIL m>upb DO m := m*3 + 1  // Find first suitable value in the
                                // series:  1, 4, 13, 40, 121, 364, ...
  { m := m/3
    FOR i = m+1 TO upb DO
    { LET vi = v!i
      LET key = vi!3
      LET j = i
      { LET k = j - m
        IF k<=0 | v!k!0 < key BREAK
        v!j := v!k
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
    LET x, y, y0, clr = rib!0, rib!1, rib!2, rib!3 & 1
    LET j, k = x/BPW, x REM BPW
    LET bit = 1<<k
    writef("Rib %i6 %i6 %i6 %i6 %i6 %i6*n", i, x, y, y0, clr, rib!3)
    map!y!j  := map!y !j | bit
    map!y0!j := map!y0!j | bit
    TEST clr>0 
    THEN FOR k=y0+1 TO y-1 DO map!k!j := map!k!j |  bit
    ELSE FOR k=y0+1 TO y-1 DO map!k!j := map!k!j & ~bit
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
  IF argv!1=0 DO argv!1 := "FLIGHT.pbm"

  writef("Drawing Flight from %s to %s*n", argv!0, argv!1)

  stdin   := input()
  stdout  := output()
  infile  := 0
  outfile := 0
  map     := getvec(YMAX)
  bits    := getvec((YMAX+1)*(ROWUPB+1)-1)
  ribv    := getvec(20000)
  spacev  := getvec(80000)
  spacet  := spacev+80000

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
    TEST count=0 THEN move3to(x, y, z)
                 ELSE draw3to(x, y, z)
    count := count+1
    IF count REM 1 = 0 DO draw3pt(x, y, z, 1)
  } REPEAT

  selectinput(stdin)

  drawribs()

  selectoutput(outfile)  
  writepbm()
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
  


