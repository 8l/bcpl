// (C) Copyright 1979 Tripos Research Group
//     University of Cambridge
//     Computer Laboratory

// BCPL-ARGS

SECTION "ARGS"

GET ":COM.BCPL.BCPL"

LET start() = VALOF
 $( LET argv = VEC 80
    LET args = "FROM,TO,OCODE/K,*
               *MC/K,CHARCODE/K,VER/K,OPT/K"
    LET ocodename = "T:BCPL-T00-OCODE"
    LET ocodelen = 0
    LET cgname = "SYS:L.BCPL-CG"
    LET cglen = 0
    LET cg = 0
    LET errarg = "Bad args*N"
    LET errstr = "Run out of store*N"
    LET errcde = "Error in CHARCODE table*N"
    LET errfil = "Can't open %S*N"
    LET oldoutput = output()

    rc := 0
    transchars, charcode := FALSE, 0
    sourcestream, ocodestream, codestream := 0, 0, 0
    verstream := oldoutput
    IF rdargs(args, argv, 80)=0 DO
    $( writes(errarg)
       GOTO fail
    $)

    UNLESS argv!5=0 DO
    $( verstream := findoutput(argv!5)
       IF verstream=0 DO
       $( writef(errfil,argv!5)
          GOTO fail $)
       selectoutput(verstream)
    $)

    UNLESS argv!4=0 DO
    $( charcode := getvec(127)
       IF charcode=0 DO
       $( writes(errstr)
          GOTO fail $)
       transchars := TRUE
       codestream := findinput(argv!4)
       IF codestream=0 DO
       $( writef(errfil,argv!4)
          GOTO fail $)
       selectinput(codestream)
       FOR i = 0 TO 127 DO charcode!i := readoctal()
       closeinput(codestream)
       codestream := 0
       IF rc>0 DO
       $( writes(errcde)
          GOTO fail $)
    $)

    UNLESS argv!0=0 DO
    $( LET from = argv!0
       LET len = from%0
       fromfile := getvec(len/bytesperword)
       IF fromfile=0 DO
       $( writes(errstr)
          GOTO fail
       $)
       FOR i = 0 TO len DO fromfile%i := from%i
       sourcestream := findinput(from)
       IF sourcestream=0 DO
       $( writef(errfil,from)
          GOTO fail $)
    $)

    UNLESS argv!1=0 DO
    $( codestream := findoutput(argv!1)
       IF codestream=0 DO
       $( writef(errfil,argv!1)
          GOTO fail $)
    $)

    keepocode := argv!2\=0
    IF keepocode DO ocodename := argv!2
    ocodelen := ocodename%0
    ocodefile := getvec(ocodelen/bytesperword)
    IF ocodefile=0 DO
    $( writes(errstr)
       GOTO fail $)
    FOR i = 0 TO ocodelen DO ocodefile%i := ocodename%i
    UNLESS keepocode DO
    $( ocodefile%9  := '0'+(taskid/10) REM 10
       ocodefile%10 := '0'+taskid REM 10
    $)

    cglen := cgname%0
    UNLESS argv!3=0 DO cglen := cglen+1+argv!3%0
    cg := getvec(cglen/bytesperword)
    IF cg=0 DO
    $( writes(errstr)
       GOTO fail $)
    FOR i = 1 TO 13 DO cg%i := cgname%i
    UNLESS argv!3=0 DO
    $( cg%14 := '-'
       FOR i = 15 TO cglen DO cg%i := argv!3%(i-14)
    $)
    cg%0 := cglen

    UNLESS sourcestream=0 DO
    $( ocodestream := findoutput(ocodefile)
       IF ocodestream=0 DO
       $( writef(errfil,ocodefile)
          GOTO fail $)
    $)

    treesize := 10000
    declsize := 1800
    savespacesize := 2
    printtree := FALSE

    cgworksize := 5000
    cglisting := FALSE
    naming, altobj := TRUE, FALSE
    callcounting, profcounting := FALSE, FALSE
    stkchking, restricted := FALSE, FALSE
    cg.y, cg.z := FALSE, FALSE
    cg.a, cg.b := 0, 0

    IF datstring(datvec)=0 DO
       FOR i = 0 TO 9 DO datvec%i := "         "%i

    UNLESS argv!6=0 DO
    $( LET opts = argv!6
       LET i = 0

       LET rdn(opts,lvi) = VALOF
        $( LET n = 0
           LET i = !lvi+1
           LET ch = opts%i
           WHILE i<=opts%0 & '0'<=ch<='9' DO
           $( n := n*10+ch-'0'
              i := i+1
              ch := opts%i
           $)
           !lvi := i-1
           RESULTIS n
        $)

       WHILE i<=opts%0 DO
       $( SWITCHON capitalch(opts%i) INTO
          $( CASE 'T': printtree := TRUE
                       ENDCASE

             CASE 'S': savespacesize := rdn(opts,@i)
                       ENDCASE

             CASE 'L': treesize := rdn(opts,@i)
                       ENDCASE

             CASE 'D': declsize := rdn(opts,@i)
                       ENDCASE

             CASE '/': BREAK
          $)
          i := i+1
       $)

       WHILE i<=opts%0 DO
       $( SWITCHON capitalch(opts%i) INTO
          $( CASE 'R': restricted := TRUE
                       ENDCASE

             CASE 'L': cglisting := TRUE
                       ENDCASE

             CASE 'O': altobj := TRUE
                       ENDCASE

             CASE 'C': stkchking := TRUE
                       ENDCASE

             CASE 'N': naming := FALSE
                       ENDCASE

             CASE 'P': profcounting := TRUE
             CASE 'K': callcounting := TRUE
                       ENDCASE

             CASE 'Y': cg.y := TRUE
                       ENDCASE

             CASE 'Z': cg.z := TRUE
                       ENDCASE

             CASE 'A': cg.a := rdn(opts,@i)
                       ENDCASE

             CASE 'B': cg.b := rdn(opts,@i)
                       ENDCASE

             CASE 'W': cgworksize := rdn(opts,@i)
                       ENDCASE
          $)
          i := i+1
       $)

    $)

    UNLESS sourcestream=0 DO
    $( writef("Tree space %I5*N", treesize)

       treevec := getvec(treesize)
       IF treevec=0 DO
       $( writes("Can't get tree space*N")
          GOTO fail $)

       selectinput(sourcestream)
       linecount := 1
       reportcount := 0
    $)

    RESULTIS cg


fail:
    closeinput(sourcestream)
    closeoutput(ocodestream)
    closeoutput(codestream)
    UNLESS verstream=oldoutput DO
       closeoutput(verstream)
    UNLESS charcode=0 DO freevec(charcode)
    rc := 20
    RESULTIS cg
 $)


AND closeoutput(s) BE UNLESS s=0 DO
 $( selectoutput(s)
    endwrite() $)

AND closeinput(s) BE UNLESS s=0 DO
 $( selectinput(s)
    endread() $)


AND readoctal() = VALOF
 $( LET n = 0
    LET ch = '*S'
    WHILE ch='*S' | ch='*T' | ch='*N' DO ch := rdch()
    FOR i = 1 TO 3 DO
    $( UNLESS '0'<=ch<='7' DO rc := 10
       n := n*8+ch-'0'
       ch := rdch()
    $)
    UNLESS ch='*S' | ch='*T' | ch='*N' DO rc := 10
    unrdch()
    RESULTIS n
 $)


