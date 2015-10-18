GET "libhdr"
GET "bells.h"

// Fudge declarations

GLOBAL {
  rbyte:           500
  wbyte:           501
}

// End of fudge
 
LET start() = VALOF

{ LET coordvec = VEC 200
  AND keyboardvec = VEC 200
  AND tickervec = VEC 200
  AND initialisevec = VEC 300
  AND ringdivsvec = VEC 2000
  AND v = VEC 300
  AND spr = VEC 100                                //give SPR some space
//coordvec := coordvec&
//keyboardvec := keyboardvec&#77777
//tickervec := tickervec&#77777
//initialisevec := initialisevec&#77777
//ringdivsvec := ringdivsvec&#77777
  coordvec!0 := 200
  keyboardvec!0 := 200
  tickervec!0 := 200
  initialisevec!0 := 300
  ringdivsvec!0 := 2000
  xvec := v
  timevec := xvec + maxbells + 1
  handvec := timevec + maxbells + 1
  placevec := handvec + maxbells + 1
  wherevec := placevec + maxbells + 1
  changevec := wherevec + maxbells + 1
  setstartvalues()
//(vgtab())!12 :=
//    ((spr&#77777)>>11) | (spr<<4) | d.t //set SPR up for use in vglib

//startdisp(vgtab())
//startdisp(messtab())
//coordinit(0,coordvec,0)
//coord(create,keyboard,keyboardvec,5)
//coord(create,ticker,tickervec,4)
  writes("Program entered*n")
//coord(create,initialise,initialisevec,3)
//coord(create,ringdivs,ringdivsvec,3)
//setlights(0) REPEAT
  RESULTIS 0
}
 
AND setstartvalues() BE
 { ticktock := 0
    keybuf := 0
    messbuf := messtab() + 5
    messptr := 0
    lights := #77674
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
    t!n := t!n + 1 & 7
    !lights := (((((t!4<<3)+t!3)<<3)+t!2<<3)+t!1<<3)+t!0
 }
 
AND vgtab() = TABLE
    d.ld+d.pir,
    0,
    d.med+d.mec+d.mek+d.ms1,
    0,
    0,
    0,
    0,
    0,
    0,
    d.pln,
    #77760+d.t,
    d.ld+d.spr,
    d.t,                  //SPR goes here  = VGTAB()!12
    d.ld+d.psr+d.p,
    #77760,
    0,
    #77760,
    0,
    0,
    0,
    #77760,0,0,
    0,#77760,0,
    0,0,#77760+d.t
 
AND messtab() = TABLE
    d.ld+d.dxr,
    (300*16)+d.t,
    d.ch+d.se+d.s2,
    #6414,
    #6400,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    d.term,
    d.ld+d.dxr,
    d.t,
    d.hlt+d.p,
    d.hlt
 
AND vgfin() = TABLE
    d.ld + d.mcr,
    0 + d.t,
    d.hlt
 
AND display(p) BE
 { messbuf!83 := d.hlt + d.p
    messbuf!84 := ((p&#77777)>>11) | (p<<4) | d.t
    messbuf!83 := d.ld + d.mar
 }
 
AND message(code,cc) BE
 { LET p = 2*messbuf
    LET k = cc<<1
    SWITCHON code INTO
     { CASE 'S': wwbyte(#15,p)
        CASE 'T': FOR i=1 TO rbyte(k) DO
                      wwbyte(rbyte(k+i),p)
                  ENDCASE
 
        CASE 'C': wwbyte(cc,p)
                  ENDCASE
 
        CASE 'E': FOR i=messptr TO 0 BY -1 DO wbyte(0,p+i)
                  messptr := 0
                  ENDCASE
     }
 }
 
AND wwbyte(c,p) BE
 { wbyte(c,p+(messptr>158->158,messptr))
    messptr := messptr + (messptr>=159 -> 0,1)
 }
 
AND rrbyte(q) = VALOF
 { LET p = 2*messbuf + (!q)
    !q := (!q) + 1
    RESULTIS rbyte(p)
 }
 
AND keyboard() BE
 { LET ch = 0
    LET t = 0
    LET del = 0
    LET vgpio = #167776>>1
     { setlights(4)
        coord(rx,1)
        !vgpio := 1
        ch := (!vgpio)>>8
        !vgpio := #4000
        UNLESS ch = 0 DO
         { keybuf := ch
            wbyte((keybuf=#15 -> '.',keybuf),2*messbuf-2)
            IF '!'<=keybuf<=')' DO keybuf := keybuf | #20
            IF 'a'<=keybuf<='z' DO keybuf := keybuf&#177737
            TEST nmode
            THEN
             { SWITCHON keybuf INTO
                 { CASE #177: UNLESS messptr=buffront DO
                                { messptr := messptr - 1
                                   message('C',' ')
                                   messptr := messptr - 1
                                }
                               ENDCASE
 
                    CASE #15:  nmode := FALSE
                    DEFAULT:   message('C',keybuf)
                 }
             }
             OR
             { SWITCHON keybuf INTO
                 { CASE 'B': t := ticktock
                              dontstop := FALSE
                              IF calculateready DO
                               { pulldelay := t - expectedtime
                                  calculateready := FALSE
                                  del := pulldelay<0 ->
                                                    -pulldelay,pulldelay
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
     } REPEAT
 }
 
AND ticker() BE
 { setlights(3)
    coord(rx,0)
    TEST pause>100
    THEN
     { ticktock := ticktock + 1
        IF freepicture&ringdivsready DO coord(tx,4)
     }
     OR pause := pause+1
 } REPEAT


LET waitn(n) BE
{ LET t = ticktock
  UNTIL ticktock >= t+n abort(1234)
}
 
AND initialise() BE
{ LET lastnbells = nbells
  message('S',"             WELCOME TO THE TOWER")
  waitn(200)
  message('C',#15); message('C',#15)
  message('S',"             Frank  King*'s  Tower")
  waitn(175)
  coord(rx,5)
  { setlights(2)
    IF keybuf='S' DO
    { IF which>0 DO
      writef("YOUR MEAN STRIKING ERROR WAS %N MILLI-SECONDS*N",
                                                   10*meandelay)
      message('S',"TYPE")
      message('S',"   G TO GO AGAIN")
      message('S',"   S TO START AFRESH")
      message('S',"   F TO FINISH")
      keybuf := 0
      WHILE keybuf = 0 DO waitn(10)
      IF keybuf = 'F' DO
      { startdisp(vgfin())
        FINISH
      }
    }
    UNLESS keybuf ='G' DO
    { askquestions(@lastnbells)
      noteanswers(@lastnbells)
    }
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
    buffront := messptr
    UNTIL ok DO
    { TEST low < 0
      THEN
       {  num := readline('M',0)
          IF num = -2 DO
             num := ((method='#')&(nbells NE !high))->-1,method
          ok := knownmethod(num)
       }
      OR
       {  num := readline('N',0)
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
  message('C',#15)
  message('C',#15)
  UNTIL leadend DO
  { buffront := messptr
    UNTIL ok DO
    { place := readline('P',@leadend)
      place := checkplace(place)
      TEST (place=-1) | (leadend&(place NE #3)&
                                (place NE (#1 | (#1<<(nbells-1)))))
      THEN
       {  leadend := FALSE
          cant()
       }
      OR  ok := TRUE
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
    OR  TEST s = nbells
        THEN place := place | (#1<<(nbells-1))
        OR
        {  b := p&#1
           p := p>>1
           s := s + 1
           IF b = #1 DO
           { TEST onenoted
             THEN RESULTIS #177777
             OR
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
  message('T',"                                 ")
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
  IF code = 'M' DO RESULTIS ('A'<=ch<='Z') -> ch, (ch=#15-> -2,-1)
  SWITCHON ch INTO
  { CASE 'X': IF ((code='N') | nonspacebeforenl(@q)) DO RESULTIS -1
 
    CASE #15: RESULTIS (code='P') -> place,-2
 
    CASE 'D': defaults := TRUE
              RESULTIS ((code='P') | nonspacebeforenl(@q)) -> -1,-2
 
    CASE 'L': IF code='N' DO RESULTIS -1
              !leadend := TRUE
              ch := rrbyte(@q) REPEATWHILE((ch=' ') | (ch='E'))
 
    DEFAULT:  UNLESS '0'<=ch<='9' DO RESULTIS -1
  }
 
  { SWITCHON ch INTO
    { CASE #15:
      CASE ' ': TEST code = 'N'
                THEN
                 { UNTIL ch = #15 DO
                   { TEST ch = 'D'
                     THEN defaults := TRUE
                     OR  UNLESS ch=' ' DO RESULTIS -1
                         ch := rrbyte(@q)
                   }
                   RESULTIS n
                 }
                OR
                 { IF n>0 DO
                   { place := place | (#1<<(n-1))
                     n := 0
                   }
                   IF ch=#15 DO RESULTIS (place=0) -> -1,place
                 }
                 ENDCASE
 
       DEFAULT:  TEST '0'<=ch<='9'
                 THEN n := 10*n + ch - '0'
                 OR  RESULTIS -1
     }
     ch := rrbyte(@q)
  } REPEAT
}
 
AND nonspacebeforenl(qv) = VALOF
{ LET ch = ' '
  UNTIL ch = #15 DO
  { UNLESS ch=' ' RESULTIS TRUE
    ch := rrbyte(qv)
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
    OR
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
  writef("%I2 BELLS, RINGING%I3, BELLGAP=%I3, ",nbells,which,bellgap)
  writef("PERIOD=%I3, FALLTIME=%I3, METHOD=*'%C'*N",
          period,falltime,method)
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
    LET salbuf = VEC 60
    LET lozbuf = VEC 60
    init.vglib(salbuf,60,2)
    moveto(0,0)
    drawby(sthick,sdelta)
    drawby(0,sally-2*sdelta)
    drawby(-sthick,sdelta)
    drawby(-sthick,-sdelta)
    drawby(0,-sally+2*sdelta)
    drawby(sthick,-sdelta)
    moveby(0,sally)
    drawby(0,ceiling-sally)
    vg.uninst()
    close.vglib()
    init.vglib(lozbuf,60,2)
    moveto(0,0)
    drawby(50,50)
    drawby(-50,50)
    drawby(-50,-50)
    drawby(50,-50)
    vg.uninst()
    close.vglib()
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
        displayall(buf,bufsize,salbuf,lozbuf)
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
                 OR
                 { TEST where = changevec!0
                    THEN
                     { TEST (strokes<((nbells-1)*nbells*changevec!0))
                        THEN wherevec!i := 1
                         OR
                         {  wherevec!i := changevec!0 + 1
                             IF thatsall < 0 DO thatsall := thatsall + 1
                         }
                     }
                     OR
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
             OR  expectedtime := tnew - t
            tpo := expectedtime + cycle
            TEST calculateready
            THEN
             {  dontstop := TRUE
                 totaldelay := totaldelay + cycle
             }
             OR  calculateready := TRUE
         }
     } REPEAT
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
     OR  RESULTIS k REM 2 = 0 -> 1,-1
 }
 
AND displayall(buf,bufsize,salbuf,lozbuf) BE
 { init.vglib(buf,bufsize,2)
    UNLESS blackout DO
     { TEST tbells
        THEN drawropes(salbuf)
         OR  drawsquares(lozbuf)
        moveto(2047,-1024)
        drawby(-4095,0)
        IF gonext DO
         { moveto(-340,-1536)
            wrch(#23)
            writes("GO NEXT!")
         }
        IF thatsall >= 0 DO
         { moveto(-340,-1536)
            wrch(#23)
            writes("THAT*'S ALL")
         }
        TEST tnew < lookroundtime + 50
        THEN
         { moveto(-315,-1536)
            wrch(#23)
            IF lookroundtime-300 < tnew < lookroundtime-100 DO
                writes("Treble*'s Going")
            IF tnew > lookroundtime DO
                writes("TREBLE*'S GONE")
         }
         OR
         { UNLESS (which = 0) | gonext | (thatsall >= 0) DO
                drawstrikemetre()
         }
     }
    phalt()
    close.vglib()
    display(buf)
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
             OR TEST t<periodminus
                THEN
                 { bs := slp + (t-falltime)*riseslope
                    bb := (bs + tailbot - connector)/2
                    IF bb<floor DO bb := floor
                    TEST t<falltimeplus
                    THEN tailshowing := FALSE
                     OR
                     {  tt := tailbot
                         IF tt>bs DO tt := bs
                         bt := tailbot - tail
                     }
                 }
                 OR
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
            vg.inst(salbuf,2047)
            IF bs<0 DO
             { moveto(x,bs+ceiling)
                drawby(0,-bs)
             }
            moveto(x,bs)
            drawby(0,bb-bs)                    //    DRAWTO(X,BB)   doesn't work!
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
 
AND drawsquares(lozbuf) BE
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
            vg.inst(lozbuf,2047)
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
        wrch(#23)
        writes("DON*'T STOP")
     }
     OR
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

