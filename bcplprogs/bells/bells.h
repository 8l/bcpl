// BCPL library header 01-May-1974
 
 
//DSPHDR
//DISPLAY COMMANDS
//COPY OF CUP FILE
 
 
 
 
MANIFEST
        $(
        d.pln=#50000
        d.bd=#76000
        d.chars=#110037
        d.pir=4
        d.mcr=5
        d.ir=6
        d.wcr=7
        d.xr=8
        d.yr=9
        d.zr=10
        d.air=11
        d.ior=12
        d.mar=14
        d.spr=15
        d.tgr=16
        d.psr=17
        d.nmr=18
        d.csr=19
        d.dxr=20
        d.dyr=21
        d.dzr=22
 
        d.med=#100000
        d.mec=#40000
        d.mep=#20000
        d.mek=#4000
        d.mdb=#1000
        d.mph=#400
        d.ms1=#200
 
        d.nop=#0
        d.spc=#20000
        d.hlt=#30000
        d.ld=#40000
        d.or=#50000
        d.an=#60000
        d.ad=#70000
        d.lds=#44000
        d.ors=#54000
        d.ans=#64000
        d.sts=#74000
        d.stsm=#74200
        d.vr=#10000
        d.vrix=#10001
        d.vriy=#10002
        d.va=#10004
        d.vaix=#10005
        d.vaiy=#10006
        d.dvxy=#10010
        d.dvyy=#10011
        d.dvxx=#10012
        d.ch=#10017
        d.chi=#10016
 
 
        d.dsh=#20
        d.dot=#40
        d.pnt=#60
        d.l=#0
        d.d=#4
        d.m=#10
        d.dt=#14
        d.ai=#0
        d.x=#1
        d.y=#2
        d.se=#100
        d.s0=#0
        d.s1=#20
        d.s2=#40
        d.s3=#60
        d.v=#200
 
 
        d.p=#100000
        d.t=#1
        d.term=#24
        $)
 
 
//VGHDR        -  21 September 1974  -  Stewart Lang
 
GLOBAL
    $(               //DDX library
    forcedisp   : 519     //force display
    startdisp   : 520     //start display
    special     : 527     //test for VG stack hardware
    $)
 
 
GLOBAL
    $(                //coordinator library
    coord       : 330     //coordinator routine, global number in COORD.MAC &
    enter       : 331     //process entry routine,  in NEWHDR also
    current     : 332     //pointer to current process base, used in DD.PAL
    channel     : 333     //pointer to TX/RX channel number vector
    coordinit   : 334     //routine to initialise coordinator
    create      : 335     //routine to create separate process
    createwait  : 336     //routine to create a sub process
    kill        : 337     //routine to kill current procees and enter another
    wait        : 338     //routine to wait    "       "     "    "      "
    tx          : 339     //routine to communicate to another procees
    rx          : 340     //routine to receive comm. from another, waits for TX
    coordstack  : 341     //stack to be used on entry from interrupts
    pending     : 342     //pointer to pcb chain of pending tasks
    $)
 
 
 
GLOBAL
    $(                //vector general library
    vglib.mode  : 378     //controls level of interactive info in the code
    vgbuf.used  : 379     //size of buffer used - set on closing
    init.vglib  : 380     //initialise library
    close.vglib : 381     //close lib. result = used space
    vg.inst     : 382     //apply a VG instance
    vg.uninst   : 383     //exit from a VG instance
    setscale    : 384     //set scale to arg
    setorigin   : 385     //set X,Y,Z origin
    moveby      : 386     //move by X,Y
    moveto      : 387     //move to X,Y
    drawby      : 388     //draw by X,Y
    drawto      : 389     //draw to X,Y
    vgstack     : 390     //stack a 15 bit value
    vgunstack   : 391     //pop the stack by N items
    vgblink     : 392     //cause blinking
    vgunblink   : 393     //remove blinking
    setcue      : 394     //set cue reg to N
    penon       : 395     //enable the light pen
    penoff      : 396     //disable the light pen
    jump        : 397     //jump to arg
    subjump     : 398     //subroutine jump to arg
    subexit     : 399     //exit from subroutine
    phalt       : 400     //set end of display file
    $)
 
 
GLOBAL $( nbells:201; which:202; bellgap:203; cycle:204; method:205
          falltime:206; falltimeplus:207; periodminus:208; period:209
          drop:210; rise:211; dropslope:212; riseslope:213
          low:214; slp:215; tailbot:216; connector:217; dangle:218
 
          xvec:220; timevec:221; handvec:222; placevec:223
          wherevec:224; changevec:225
 
          ticktock:226; told:227; tnew:228; tpo:229; expectedtime:230
          pulldelay:231; meandelay:232; totaldelay:233; expectedpulls:234
          strokes:235
 
          calculateready:236; pullingoff:237; gonext:238; holdingup:239
          dontstop:240; thatsall:241
 
          lights:242; messbuf:243; messptr:244; buffront:245
          keybuf:246; nmode:247; defaults:248
 
          initialiseready:249; blackout:250; freepicture:251
          ringdivsready:252; pause:253; tbells:254
 
 
          setstartvalues:261; setlights:262; vgtab:263; messtab:264
          vgfin:265; display:266; message:267; wwbyte:268; rrbyte:269
          keyboard:270; ticker:271
 
          waitn:275; initialise:276; askquestions:277; getdata:278
          knownmethod:279; definemethod:280; checkplace:281
          cant:282; readline:283; nonspacebeforenl:284; noteanswers:285
 
          setrounds:286; setplainbob:287; setstedman:288; setcambridge:289
          places:290; preparetogo:291
 
          ringdivs:292; shift:293; displayall:294; drawropes:295
          drawsquares:296; drawstrikemetre:297; dispvec:298
       $)
 
MANIFEST $( maxbells=16; maxdivisions=65; lookroundtime=400
            ceiling=2047; floor=-1024; shp=1950; ddrop=850; rrise=1900
            sally=500; tail=200; sthick=20; sdelta=10; tthick=10; tdelta=5
         $)
