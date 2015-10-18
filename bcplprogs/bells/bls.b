GET "libhdr"

// A bell ringing tutor -- originally written by Frank King in 1974
// to run on PDP 11/45 driving a Vector General Display

// Modified by Martin Richards to run on the BCPL Cintcode system
// under Windows CE 2.0 -- July 1999

GLOBAL
{ nbells:201 // No of bells in the tower, 2-16, an even number
  which:202  // 0 or the user's bell
  bellgap:203
  cycle:204
  method:205
  falltime:206
  falltimeplus:207
  periodminus:208
  period:209
  drop:210
  rise:211
  dropslope:212
  riseslope:213
  low:214
  slp:215
  tailbot:216
  connector:217
  dangle:218
 
  xvec:220
  timevec:221
  handvec:222
  placevec:223
  wherevec:224
  changevec:225
 
  ticktock:226
  told:227
  tnew:228
  tpo:229
  expectedtime:230
  pulldelay:231
  meandelay:232
  totaldelay:233
  expectedpulls:234
  strokes:235
 
  calculateready:236
  pullingoff:237
  gonext:238
  holdingup:239
  dontstop:240
  thatsall:241
 
  lights:242
  messbuf:243
  messptr:244
  buffront:245
  keybuf:246
  nmode:247
  defaults:248
 
  initialiseready:249
  blackout:250
  freepicture:251
  ringdivsready:252
  pause:253
  tbells:254
 
  setstartvalues:261
  setlights:262
  vgtab:263
  messtab:264
  vgfin:265
  display:266
  message:267
  wwbyte:268
  rrbyte:269
  keyboard:270
  ticker:271
 
  waitn:275
  initialise:276
  askquestions:277
  getdata:278
  knownmethod:279
  definemethod:280
  checkplace:281
  cant:282
  readline:283
  nonspacebeforenl:284
  noteanswers:285
 
  setrounds:286
  setplainbob:287
  setstedman:288
  setcambridge:289
  places:290
  preparetogo:291
 
  ringdivs:292
  shift:293
  displayall:294
  drawropes:295
  drawsquares:296
  drawstrikemetre:297
  dispvec:298

  drawlights: 299
}
 
MANIFEST
{ maxbells=16
  maxdivisions=65
  lookroundtime=400
  ceiling=2047
  floor=-1024
  shp=1950
  ddrop=850
  rrise=1900
  sally=500
  tail=200
  sthick=20
  sdelta=10
  tthick=10
  tdelta=5
}


// Start of graphics library

MANIFEST { // 	0perators in sys(34, op, a, b) calls
  gr_hide    = 3  // hide the graphics window
  gr_show    = 4  // show the graphics window
  gr_cx      = 5  // return x size of graphics window
  gr_cy      = 6  // return y size of graphics window
  gr_bpr     = 7  // return bytes per row in bitmap (one byte per pixel)
  gr_display = 8  // copy bitmap to display
  gr_palette = 9  // set the (8-bit) palette
                  //   a = no of colours
                  //   b = vector of 24-bit RGB colours
}

GLOBAL {
  initgraphics  : 400
  closeGraphics : 401
  setcolour     : 402
  point         : 403
  moveto        : 404
  moveby        : 405
  drawto        : 406
  drawby        : 407
  
  prevx:     500
  prevy:     501
  colour:    502  // current 8-bit colour
  cx:        503  // no of columns in the graphics window
  cy:        504  // no of rows in the graphics window
  bv:        505  // the bitmap bits vector
  bitmap:    506  // bitmap structure used in sys(34, gr_display, bitmap)
  fin:       507
  prevdrawn: 508  // pixel prevx,prevy has been drawn
  bpr:       509  // bytes per row in the graphics window
}

LET initgraphics() = VALOF
{ LET count = 0
  LET palette = TABLE #x000000,  // Black 
                      #xFF0000,  // Red
                      #x00FF00,  // Blue
                      #x0000FF,  // Green
                      #xFFFF00,
                      #xFF00FF,
                      #x00FFFF,
                      #xFFFFFF   // White
      
  sys(34, gr_palette, 8, palette)
  sys(34, gr_show)
  cx := sys(34, gr_cx)
  cy := sys(34, gr_cy)
  bpr := sys(34, gr_bpr)
  bitmap := getvec(cx*bpr/4 + 3) // +3 for cx, cy and bpr fields

//  writef("cx=%n cy=%n bpr=%n*n", cx, cy, bpr)
  UNLESS bitmap DO {
    writef("Unable to allocate bitmap*n")
    RESULTIS 20
  }

  bv := bitmap + 3
  bitmap!0 := cx
  bitmap!1 := cy
  bitmap!2 := bpr

  FOR i = 0 TO bpr*cx-1 DO bv%i := 1  // Red
  sys(34, gr_display, bitmap)

  setcolour(0)
  moveto(1500, 0)
/*
  writef("2500,1000*n")
  drawto(2500, 1000)
  sys(34, gr_display, bitmap)
  setcolour(4)
  writef("1000,-1000*n")
  drawto(0, 3000)
  sys(34, gr_display, bitmap)
  drawto(-4000,0)
  sys(34, gr_display, bitmap)
  drawto(0,2000)
  sys(34, gr_display, bitmap)
  drawto(2000,3000)
  sys(34, gr_display, bitmap)
  setcolour(2)  // Green
  drawto(-200, 100)
*/
  sys(34, gr_display, bitmap)

  RESULTIS 0
}

AND closeGraphics() BE freevec(bitmap)

AND setcolour(col) BE colour, prevdrawn := col, FALSE

AND smoveto(x, y) BE
  prevx, prevy, prevdrawn := x, y, FALSE

AND sdrawto(x, y) BE 
{ LET mx, my = ?, ?
  //writef("dt %i5 %i5*n", x, y)
  IF x<0 & prevx<0     |
     y<0 & prevy<0     |
     x>=cx & prevx>=cx |
     y>=cy & prevy>=cy DO { prevx, prevy, prevdrawn := x, y, FALSE
                            RETURN
                          }

  UNLESS prevdrawn DO spoint(prevx, prevy)
 
  mx := (x+prevx)/2
  my := (y+prevy)/2
  //writef("x %i4 %i4 %i4*n", prevx, mx, x)
  //writef("y %i4 %i4 %i4*n", prevy, my, y)
//abort(999)
  TEST (mx=prevx | mx=x) & (my=prevy | my=y)
  THEN spoint(x, y)
  ELSE { sdrawto(mx, my)
         sdrawto(x, y)
       } 
}

AND spoint(x, y) BE
{ IF 0<=x<cx & 0<=y<cy DO
  { bv%(y*bpr+x) := colour
    prevdrawn := TRUE
    //sys(34, gr_display, bitmap)
  }
  //writef("pt %i4 %i4*n", x, y)
  prevx, prevy := x, y
}

AND moveto(x, y) = smoveto((x+2048)*cx/4096, (y+2048)*cy/4096)
AND drawto(x, y) = sdrawto((x+2048)*cx/4096, (y+2048)*cy/4096)
AND moveby(dx, dy) = smoveto(prevx+dx*cx/4096, prevy+dy*cy/4096)
AND drawby(dx, dy) = sdrawto(prevx+dx*cx/4096, prevy+dy*cy/4096)

AND point(x, y)  = spoint ((x+2048)*cx/4096, (y+2048)*cy/4096)

AND cls() BE
{ FOR i = 0 TO (cx*bpr)/4 DO bv!i := #x01010101  // all red
  display()
}

// End of graphics library

// Fudge declarations

GLOBAL {
  rbyte:           450
  wbyte:           451
  coordvec:        452
  coord:           453
  coordinit:       454
}

LET rbyte(p) = 0%p 

LET wbyte(ch, p) BE 0%p := ch

MANIFEST { tx=10; rx=11 }

LET coordinit() BE
  coordvec := TABLE 0, 0, 0, 0, 0, 0, 0
  // coordvec!i=1 means channel i has an outstanding tx
  // channel usage:
  // 0: tx sent by clock hardware every 10? msecs
  // 1:
  // 2:
  // 3:
  // 4: tx sent by ticker when pause>10(0) provided ...
  // 5:
  // 6: G or S received by keyboard when initializeready

LET coord(f, a) BE SWITCHON f INTO
{ DEFAULT: RETURN

  CASE tx: coordvec!a := 1
           writef("%i5: sending tx %n*n", currco, a)
           cowait(0)
           ENDCASE

  CASE rx: UNTIL coordvec!a=1 DO // poll until a tx on channel a
           { writef("%i5: waiting for tx %n*n", currco, a)
             cowait()
           }
           coordvec!a := 0
           writef("%i5: resuming rx %n*n", currco, a)
           RETURN
}

// End of fudge
 
LET start() = VALOF
{ LET argv = VEC 50
  LET c_keyboard = 0
  LET c_ticker = 0
  LET c_initialise = 0
  LET c_ringdivs = 0

  AND v = VEC 300

  UNLESS rdargs("DEBUG", argv, 50) DO
  { writes("Bad argument for BELLS*n")
    RESULTIS 20
  }
  xvec := v

  timevec := xvec + maxbells + 1
  handvec := timevec + maxbells + 1
  placevec := handvec + maxbells + 1
  wherevec := placevec + maxbells + 1
  changevec := wherevec + maxbells + 1

  coordinit()

  setstartvalues()
  c_keyboard := createco(keyboard, 200)
  c_ticker := createco(ticker, 200)

  initgraphics()

  c_initialise := createco(initialise, 300)
  c_ringdivs := createco(ringdivs, 2000)


  { // simulate 4 processes with round robin scheduling 
    writes("calling keyboard*n")
    callco(c_keyboard, 0)
    writes("calling ticker*n")
    callco(c_ticker, 0)
    writes("calling initialise*n")
    callco(c_initialise, 0)
    writes("calling ringdivs*n")
    callco(c_ringdivs, 0)
    setlights(0)
  } REPEATUNTIL intflag()

  closeGraphics()
  IF c_keyboard   DO deleteco(c_keyboard)
  IF c_ticker     DO deleteco(c_ticker)
  IF c_initialise DO deleteco(c_initialise)
  IF c_ringdivs   DO deleteco(c_ringdivs)
  RESULTIS 0
}
 
AND setstartvalues() BE
{ ticktock := 0
  keybuf := 0
  messbuf := 5 + TABLE 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, //messtab() + 5
                       0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
                       0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
                       0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
  messptr := 0
  lights := 0 //#77674  H/W Lights on the PDP 11
  freepicture := FALSE
  pause := 0
  nbells := 6
  bellgap := 100
  method := 'R'
  tbells := TRUE
  nmode := FALSE
  initialiseready := FALSE
  ringdivsready := FALSE
  blackout := FALSE
}
 
AND setlights(n) BE
{ LET t = TABLE 0, 0, 0, 0, 0
  t!n := (t!n + 1) & 7
  lights := (((((t!4<<3)+t!3)<<3)+t!2<<3)+t!1<<3)+t!0
  drawlights()
  sys(34, gr_display, bitmap)
}
 
AND display(p) BE
  sys(34, gr_display, bitmap)
 
AND message(code,cc) BE
{ LET p = 4*messbuf
  LET k = cc<<2
  SWITCHON code INTO
  { CASE 'S': wwbyte('*n',p)
    CASE 'T': FOR i=1 TO cc%0 DO wwbyte(cc%i,p)
              //IF code='S' DO newline()
              //writef("%s*n", cc)
              ENDCASE
 
    CASE 'C': wwbyte(cc,p)
              //writef("%c", cc)
              ENDCASE
 
    CASE 'E': { messbuf%messptr := 0
                IF messptr=0 ENDCASE
                messptr := messptr-1
              } REPEAT
  }
  writef("mess: ")
  FOR i = 0 TO messptr-1 DO wrch(messbuf%i)
  newline()
}
 
AND wwbyte(c,p) BE
{ IF messptr>158 DO messptr := 158
  messbuf%messptr := c
  messptr := messptr+1
//  writef("wwbyte: '%c'*n", c)
}
 
AND rrbyte(q) = VALOF
{ LET ch = messbuf%(!q)
  !q := (!q) + 1
//  writef("rrbyte %c*n", ch)
  RESULTIS ch
}
 
AND keyboard() BE
{ LET ch = 0
  LET t = 0
  LET del = 0
  { setlights(4)
    //coord(rx,1)   // wait for a keyboard character
    writes("type ch, / or \> ")
    ch := sys(10)               // MR
    newline()
    IF ch='/' DO { abort(999); ch := 0 }
    IF ch='\' DO ch := 0
    UNLESS ch = 0 DO
    { keybuf := ch
      wbyte((keybuf='*n' -> '.',keybuf),4*messbuf-2)
      IF '!'<=keybuf<=')' DO keybuf := keybuf | #20
      IF 'a'<=keybuf<='z' DO keybuf := keybuf&#177737
      writef("keybuf %i3 '%c'*n", keybuf, keybuf)
      TEST nmode
      THEN
      { SWITCHON keybuf INTO
        { CASE #177: UNLESS messptr=buffront DO
                     { messptr := messptr - 1
                       message('C',' ')
                       messptr := messptr - 1
                     }
                     ENDCASE
 
          CASE '*n':  nmode := FALSE
          DEFAULT:    message('C',keybuf)
        }
      }
      ELSE
        { SWITCHON keybuf INTO
          { CASE 'B': t := ticktock
                      dontstop := FALSE
                      IF calculateready DO
                      { pulldelay := t - expectedtime
                        calculateready := FALSE
                        del := ABS pulldelay
                        IF del < 5000 DO
                               totaldelay := totaldelay + del
                      }
                      ENDCASE
 
           CASE ' ': pause := 0; ENDCASE
 
           CASE 'T': tbells := TRUE; ENDCASE
 
           CASE 'H': tbells := FALSE; ENDCASE
 
           CASE 'G':
           CASE 'S': IF initialiseready DO coord(tx,6)
         }
       }
     }
     cowait(0)
   } REPEAT
}
 
AND ticker() BE
{ //abort(999)
  setlights(3)
  //coord(rx,0)   // wait for a clock tick  (10 msecs period?)
  writef("pause=%i4 ticktock=%i3*n", pause, ticktock)
  TEST pause>10 //100
  THEN
  { ticktock := ticktock + 1
    IF freepicture&ringdivsready DO coord(tx,4)
  }
  ELSE  pause := pause+1
  cowait()
} REPEAT


LET waitn(n) BE
{ LET t = ticktock
  writef("wait %n until %n*n", n, t+5)
  IF n>5 DO n := 5 // debugging
  UNTIL ticktock >= t+n DO cowait(0)
}
 
AND initialise() BE
{ LET lastnbells = nbells
  message('S',"WELCOME TO THE TOWER")
  waitn(200)
  //message('C','*n'); message('C','*n')
  message('S',"Frank  King*'s  Tower")
  waitn(175)
  coord(rx,5)  // wait for keyboard
  { setlights(2)
    IF keybuf='S' DO
    { IF which>0 DO
      writef("YOUR MEAN STRIKING ERROR WAS %N MILLI-SECONDS*N",
                                                   10*meandelay)
      message('S',"TYPE")
      message('S',"  G TO GO AGAIN")
      message('S',"  S TO START AFRESH")
      message('S',"  F TO FINISH")
      keybuf := 0
//      WHILE keybuf = 0 DO waitn(10)
      WHILE keybuf = 0 DO waitn(1)
      IF keybuf = 'F' DO
      { //startdisp(vgfin())
        FINISH
      }
    }
    UNLESS keybuf ='G' DO
    { askquestions(@lastnbells)
      noteanswers(@lastnbells)
    }
    writes("calling preparetogo*n")
    preparetogo()
    message('E',0)
    freepicture := TRUE
    initialiseready := TRUE
    coord(rx,6)
    initialiseready := FALSE
    blackout := TRUE
    waitn(35)
    freepicture := FALSE
    waitn(10)
    blackout := FALSE

    cowait()
  } REPEAT
}
 
AND askquestions(lnb) BE
{ keybuf := 0
  message('E',0)
  defaults := FALSE
  nbells   := getdata("How many bells?     ",1,16,nbells)
  IF nbells REM 2 = 1 DO nbells := nbells + 1
  which    := getdata("Which do you want?  ",0,nbells,0)
  bellgap  := getdata("Inter-bell gap?     ",15,500,2*(32-nbells))
  period   := getdata("Bell period?        ",bellgap,
                        (nbells-1)*bellgap-10,2*(nbells-1)*bellgap/3)
  falltime := getdata("Sally falltime?     ",5,3*period/8,period/4)
  defaults := FALSE
  method   := getdata("Which method?       ",-1,lnb,method)
}
 
AND getdata(question,low,high,deflt) = VALOF
{ LET ok = FALSE
  LET num = -2
  UNLESS defaults DO
  { message('S',question)
    writef("%s", question)
    buffront := messptr
    UNTIL ok DO
    { TEST low < 0
      THEN { num := readline('M',0)
             IF num = -2 DO
                num := ((method='#')&(nbells NE !high))->-1,method
             ok := knownmethod(num)
           }
      ELSE { num := readline('N',0)
             ok := (num=-2) | (low<=num<=high)
           }
      UNLESS ok DO cant()
    }
  }
  RESULTIS num = -2 -> deflt,num
}
 
AND knownmethod(m) = VALOF
{ SWITCHON m INTO
  { CASE 'R':
    CASE 'D':
    CASE '#': RESULTIS TRUE
 
    CASE 'P': RESULTIS (nbells>=4)
 
    CASE 'S':
    CASE 'C': RESULTIS (nbells>=6)
 
    DEFAULT:  RESULTIS FALSE
  }
}
 
AND definemethod() BE
{ LET leadend = FALSE
  LET ok = FALSE
  LET place = 0
  LET i = 0
  message('E',0)
  message('S',"Define method:")
  IF nbells>12 DO message('C',#22)
  //message('C','*n')
  //message('C','*n')
  UNTIL leadend DO
  { buffront := messptr
    UNTIL ok DO
    { place := readline('P',@leadend)
      place := checkplace(place)
      TEST (place=-1) |
           (leadend&(place NE #3)& (place NE (#1 | (#1<<(nbells-1)))))
      THEN { leadend := FALSE
             cant()
           }
      ELSE ok := TRUE
    }
    UNLESS leadend DO
    { i := i+1
      changevec!i := place
      ok := FALSE
    }
  }
  changevec!0 := i + i
  FOR j=1 TO (i-1) DO
  changevec!(i+j) := changevec!(i-j)
  changevec!(i+i) := place
  changevec!(i+i+1) := #177777
}
 
AND checkplace(place) = VALOF
{ LET p = place
  LET s = 0
  LET b = 0
  LET onenoted = FALSE
  UNTIL s = nbells DO
  { b := p&#1
    p := p>>1
    s := s + 1
    TEST b = #1
    THEN onenoted := TRUE
    ELSE TEST s = nbells
        THEN place := place | (#1<<(nbells-1))
      ELSE 
        {  b := p&#1
           p := p>>1
           s := s + 1
           IF b = #1 DO
           { TEST onenoted
             THEN RESULTIS #177777
           ELSE 
              { place := (place | #1)
                onenoted := TRUE
              }
           }
         }
  }
  RESULTIS p=0 -> place,#177777
}
 
AND cant() BE
{ messptr := messptr -1
  message('T',"  CAN*'T")
  waitn(100)
  messptr := buffront
  //message('T',"                                 ")
  messptr := buffront
  defaults := FALSE
}
 
AND readline(code,leadend) = VALOF
{ LET n = 0
  LET ch = 0
  LET place = #0
  LET q = buffront
  nmode := TRUE
  WHILE nmode DO waitn(10)
  ch := rrbyte(@q) REPEATWHILE ch = ' '
  //ch := rdch() REPEATWHILE ch = ' '
  IF code = 'M' RESULTIS 'A'<=ch<='Z' -> ch,
                         ch='*n'      -> -2,
                                         -1
  SWITCHON ch INTO
  { CASE 'X': IF code='N' | nonspacebeforenl(@q) RESULTIS -1
 
    CASE '*n': RESULTIS code='P' -> place,-2
 
    CASE 'D': defaults := TRUE
              RESULTIS code='P' | nonspacebeforenl(@q) -> -1, -2
 
    CASE 'L': IF code='N' DO RESULTIS -1
              !leadend := TRUE
              ch := rrbyte(@q) REPEATWHILE ch=' ' | ch='E'
//            ch := rdch() REPEATWHILE ch=' ' | ch='E'
 
    DEFAULT:  UNLESS '0'<=ch<='9' DO RESULTIS -1
  }
 
  { SWITCHON ch INTO
    { CASE '*n':
      CASE ' ': TEST code = 'N'
                THEN
                 { UNTIL ch = '*n' DO
                   { TEST ch = 'D'
                     THEN defaults := TRUE
                     ELSE UNLESS ch=' ' DO RESULTIS -1
                     ch := rrbyte(@q)
//                   ch := rdch()
                   }
                   RESULTIS n
                 }
              ELSE 
                 { IF n>0 DO
                   { place := place | (#1<<(n-1))
                     n := 0
                   }
                   IF ch='*n' DO RESULTIS (place=0) -> -1,place
                 }
                 ENDCASE
 
       DEFAULT:  TEST '0'<=ch<='9'
                 THEN n := 10*n + ch - '0'
                 ELSE RESULTIS -1
     }
     ch := rrbyte(@q)
//   ch := rdch()
  } REPEAT
}
 
AND nonspacebeforenl(qv) = VALOF
{ LET ch = ' '
  UNTIL ch = '*n' DO
  { UNLESS ch=' ' RESULTIS TRUE
    ch := rrbyte(qv)
//  ch := rdch()
  }
  RESULTIS FALSE
}
 
AND noteanswers(lnb) BE
{ LET inc = 4096/(nbells - (which=0 -> 0,1))
  LET x = -inc/2 - 2048
  LET i = which + 1
  cycle := nbells*bellgap
  UNTIL i=which DO
  { TEST i>nbells
    THEN i:= 0
  ELSE 
    { UNLESS i=0 DO
      { x := x+inc
        xvec!i := x
      }
      i := i + 1
    }
  }
  xvec!which := 0
  xvec!0 := nbells
  cycle := nbells*bellgap
  dropslope := ddrop/falltime
  riseslope := rrise/(period - 2*falltime)
  drop := dropslope*falltime
  rise := riseslope*(period - 2*falltime)
  low := shp - rise
  slp := low - drop
  tailbot := slp + (sally+tail)/2
  connector := rise - (sally+tail)/2
  dangle := (connector-(sally-tail)/2)/2
  periodminus := period - falltime
  falltimeplus := falltime +
                   ((riseslope+(sally-tail))/2 + 2*tdelta)/riseslope
  SWITCHON method INTO
  { DEFAULT:
    CASE 'R':
    CASE 'P': setplainbob(); ENDCASE
 
    CASE 'S': setstedman(); ENDCASE
 
    CASE 'C': setcambridge(); ENDCASE
 
    CASE 'D': definemethod(); ENDCASE
 
    CASE '#':
  }
  !lnb := nbells
  writef("  %I2 BELLS*n",    nbells)
  writef("RINGING  %I3*n",   which)
  writef("BELLGAP  %I3*n",   bellgap)
  writef("PERIOD   %I3*n",   period)
  writef("FALLTIME %I3*n",   falltime)
  writef("METHOD   *'%C'*n", method)
  IF method = 'D' DO method := '#'
}
 
AND setplainbob() BE
 { LET n = 2*nbells
    changevec!0 := n
    FOR i = 1 TO (n-3) BY 2 DO
     { changevec!i := places(0,0,0,0)
       changevec!(i+1) := places(1,nbells,0,0)
     }
    changevec!(n-1) := places(0,0,0,0)
    changevec!n :=  places(1,2,0,0)
    changevec!(n+1) := #177777
 }
 
AND setstedman() BE
 { changevec!0 := 12
    changevec!1 := places(3,nbells,0,0)
    changevec!2 := places(1,nbells,0,0)
    changevec!3 := places(nbells-1,nbells,0,0)
    changevec!4 := places(3,nbells,0,0)
    changevec!5 := places(1,nbells,0,0)
    changevec!6 := places(3,nbells,0,0)
    changevec!7 := places(1,nbells,0,0)
    changevec!8 := places(3,nbells,0,0)
    changevec!9 := places(nbells-1,nbells,0,0)
    changevec!10 := places(1,nbells,0,0)
    changevec!11 := places(3,nbells,0,0)
    changevec!12 := places(1,nbells,0,0)
    changevec!13 := #177777
 }
 
AND setcambridge() BE
 { LET h = 2*nbells
    changevec!0 := 4*nbells
    FOR i=1 TO nbells DO
     { changevec!(i+i-1) := #0
        changevec!(i+i) := checkplace(places(((i<3) -> 0,(i-1)),
                                          ((i>nbells-4) -> 0,(i+2)),0,0))
     }
    FOR i=1 TO (h-1) DO
        changevec!(h+i) := changevec!(h-i)
    changevec!(h+h) := places(1,2,0,0)
    changevec!(h+h+1) := #177777
 }
 
AND places(a,b,c,d) = VALOF
{ LET p = a>0 -> #1<<(a-1),#0
  LET q = b>0 -> #1<<(b-1),#0
  LET r = c>0 -> #1<<(c-1),#0
  LET s = d>0 -> #1<<(d-1),#0
  RESULTIS p | q | r | s
}
 
AND preparetogo() BE
{ FOR i=0 TO nbells DO
  { timevec!i := i=0 -> nbells,-lookroundtime-(i-1)*bellgap
    handvec!i := i=0 -> nbells,TRUE
    placevec!i:= i=0 -> nbells,i
    wherevec!i:= i=0 -> nbells,(changevec!0)+1
  }
  ticktock := 0
  expectedtime := which=0 -> 0,-(timevec!which)
  pulldelay := 0
  meandelay := 0
  totaldelay := 0
  expectedpulls := 0
  told := 0
  tnew := 0
  tpo := expectedtime + cycle
  strokes := 0
  calculateready := TRUE
  pullingoff := TRUE
  gonext := FALSE
  holdingup := TRUE
  dontstop := FALSE
  thatsall := -1
}



LET ringdivs() BE
{ LET tdif = 0
  LET bufsize = 800
  LET buf1 = VEC 800
  LET buf2 = VEC 800
  LET buf = 0
  LET where = 0
  LET change = 0
  LET place = 0
  LET s = 0
  LET t = 0
  coord(tx,5)

  { setlights(1)
    ringdivsready := TRUE
    coord(rx,4)
    ringdivsready := FALSE
    buf := buf1
    buf1 := buf2
    buf2 := buf
    tnew := ticktock
    tdif := tnew - told
    told := tnew
    FOR i=1 TO nbells DO
    { timevec!i := timevec!i + tdif
    }
    displayall()
    IF thatsall >= 0 DO
    { thatsall := thatsall + tdif
      IF thatsall > 300 DO thatsall := -100
    }
    IF tnew > 30000 DO
    { ticktock := ticktock - 25000
      told := told - 25000
      tnew := tnew - 25000
      tpo  := tpo  - 25000
      expectedtime := expectedtime - 25000
    }
    FOR i=1 TO nbells DO
      IF timevec!i >= period DO
        { where := wherevec!i
          change := changevec!where
          place := placevec!i
          s := shift(change,place)
          handvec!i := NOT (handvec!i)
          timevec!i := (timevec!i) - cycle -
                         (((handvec!i) -> 1,0)+s)*bellgap
          TEST where < changevec!0
          THEN wherevec!i := where + 1
        ELSE 
          { TEST where = changevec!0
            THEN
            { TEST (strokes<((nbells-1)*nbells*changevec!0))
              THEN wherevec!i := 1
            ELSE 
                   {  wherevec!i := changevec!0 + 1
                      IF thatsall < 0 DO thatsall := thatsall + 1
                   }
            }
          ELSE 
            { IF (strokes = 2*nbells) DO strokes := 0
              IF (strokes = 0)&(method NE 'R')&((which=0) | 
                 ((expectedpulls>3)&(meandelay<40)))
              DO gonext := TRUE
              IF gonext DO wherevec!i := 1
            }
          }
          strokes := strokes + 1
          IF gonext&(strokes=nbells) DO gonext := FALSE
          placevec!i := place + s
          IF i=which DO holdingup := TRUE
        }
        IF (which>0)&holdingup&((timevec!which)>0) DO
        { holdingup := FALSE
          tpo := tnew + cycle/2
          expectedpulls := expectedpulls + 1
          meandelay := totaldelay/expectedpulls
        }
        IF (which>0)&(tnew > tpo) DO
        { t := timevec!which
          TEST t>0
          THEN expectedtime := tnew + cycle - t +
                               (((handvec!which) -> 0,1) +
                shift(changevec!(wherevec!which),placevec!which))*bellgap
          ELSE   expectedtime := tnew - t
          tpo := expectedtime + cycle
          TEST calculateready
          THEN
          {  dontstop := TRUE
             totaldelay := totaldelay + cycle
          }
          ELSE calculateready := TRUE
        }
    cowait(0)
  } REPEAT
}
 
AND drawsal() BE
{ drawby(sthick,sdelta)
  drawby(0,sally-2*sdelta)
  drawby(-sthick,sdelta)
  drawby(-sthick,-sdelta)
  drawby(0,-sally+2*sdelta)
  drawby(sthick,-sdelta)
  moveby(0,sally)
  drawby(0,ceiling-sally)
}

AND drawloz() BE
{ drawby(50,50)
  drawby(-50,50)
  drawby(-50,-50)
  drawby(50,-50)
}

AND shift(change,place) = VALOF
{ LET k = 0
  LET s = 1
  UNTIL s = place DO
  { IF (change&#1) = #0 DO k := k + 1
    change := change >> 1
    s := s + 1
  }
  TEST (change&#1) = #1
  THEN RESULTIS 0
ELSE   RESULTIS k REM 2 = 0 -> 1,-1
}
 
AND displayall() BE
{ UNLESS blackout DO
  { cls()
    TEST tbells
    THEN drawropes()
    ELSE drawsquares()
    moveto(2047,-1024)
    drawby(-4095,0)
    IF gonext DO
    { moveto(-340,-1536)
      //wrch(#23)
      writes("GO NEXT!")
    }
    IF thatsall >= 0 DO
    { moveto(-340,-1536)
      //wrch(#23)
      writes("THAT*'S ALL")
    }
    TEST tnew < lookroundtime + 50
    THEN
    { moveto(-315,-1536)
      //wrch(#23)
      IF lookroundtime-300 < tnew < lookroundtime-100 DO
          writes("Treble*'s Going")
      IF tnew > lookroundtime DO
          writes("TREBLE*'S GONE")
    }
  ELSE 
    { UNLESS (which = 0) | gonext | (thatsall >= 0) DO
           drawstrikemetre()
    }
  }
  drawlights()
  display()
}
 
AND drawlights() BE
{ LET w = lights
  FOR i = 0 TO 14 DO
  { TEST (w & (1<<i))=0 THEN setcolour(0)  // black
                        ELSE setcolour(4)  // yellow
    moveto( (10-i - (i/3)*2)*100, -1500)
    drawby( 30,   0)
    drawby(  0,  60)
    drawby(-30,   0)
    drawby(  0, -60)
    setcolour(0) // black
  }
}

AND drawropes(salbuf) BE
{ LET tailshowing = 0
  LET x,t = 0,0
  LET bs,ts = 0,0
  LET bt,tt = 0,0
  LET bb = 0
  FOR i=1 TO nbells DO
    UNLESS i=which DO
      { tailshowing := TRUE
        x := xvec!i
        t := timevec!i
        UNLESS handvec!i DO t := period - t
        TEST t<falltime
        THEN
        { bs := low - (t<=0 -> 0,t*dropslope)
          bb := bs - dangle
          IF bb<floor DO bb := floor
          tailshowing := FALSE
        }
      ELSE  TEST t<periodminus
           THEN
            { bs := slp + (t-falltime)*riseslope
              bb := (bs + tailbot - connector)/2
              IF bb<floor DO bb := floor
              TEST t<falltimeplus
              THEN tailshowing := FALSE
            ELSE 
              { tt := tailbot
                IF tt>bs DO tt := bs
                bt := tailbot - tail
              }
            }
          ELSE 
              { bs := shp
                UNLESS t>period DO
                bs := bs - (period-t)*dropslope
                tt := bs - connector
                bt := tt - tail
                bb := tt
              }
          ts := bs + sally
          moveto(x,-800)
          moveby(0,bs+800)
          //vg.inst(salbuf,2047)
          drawsal()  // MR
          IF bs<0 DO
          { moveto(x,bs+ceiling)
            drawby(0,-bs)
          }
          moveto(x,bs)
          drawby(0,bb-bs)         //    DRAWTO(X,BB)   doesn't work!
          IF tailshowing DO
          { moveto(x,bt)
            drawby(tthick,tdelta)          // DRAWBYs work
            drawby(0,tt-bt-2*tdelta)       // DRAWTOs don't
            drawby(-tthick,tdelta)
            drawby(-tthick,-tdelta)
            drawby(0,-tt+bt+2*tdelta)
            drawby(tthick,-tdelta)
          }
          IF i=1 DO
          { moveto(x-10,-1024)
            drawby(10,-40)
            drawby(10,40)
          }
        }
}
 
AND drawsquares() BE
{ LET t=0
  LET thouoverp = 1000/period
  FOR i=1 TO nbells DO
    UNLESS i = which DO
    { moveto(xvec!i,-800)
      t := timevec!i
      UNLESS handvec!i DO t := period - t
      IF t < 0 DO t := 0
      IF t > period DO t := period
      moveby(0,t*thouoverp)
      drawloz()  // MR
      IF i=1 DO
      { moveto((xvec!i)-10,-1024)
        drawby(10,-40)
        drawby(10,40)
      }
    }
}
 
AND drawstrikemetre() BE
{ LET h = 30*(meandelay<100 -> meandelay,100)
  LET x = 12*pulldelay
  LET d = x<0 -> -x,x
  LET x1 = 12*(bellgap<100 -> bellgap,100)
  LET y1 = 400 - 19*x1/60
  moveto(-1800,-1024)
  moveby(-248,0)
  drawby(0,h)
  drawby(20,0)
  drawby(0,-h)
  TEST dontstop
  THEN
  { moveto(-306,-1536)
    //wrch(#23)
    writes("DON*'T STOP*n")
  }
ELSE 
  { moveto(-1748,-1536)
    drawby(100,0)
    moveto(-1220,-1536)
    drawby(2440,0)
    moveto(1648,-1536)
    drawby(100,0)
    moveto(1698,-1486)
    drawby(0,-100)
    moveto(x1,-1536-y1)
    drawby(0,y1+y1)
    IF d>1200 DO
    { d := 1200
      x := x<0 -> -1200,1200
    }
    d := 400 - 19*d/60
    moveto(x+d,-1536)
    drawby(-d,d)
    drawby(-d,-d)
    drawby(d,-d)
    drawby(d,d)
    moveto(0,-1136)
    drawby(0,-800)
    moveto(-x1,-1536-y1)
    drawby(0,y1+y1)
  }
}

