// (C) Copyright 1978 Tripos Research Group
//     University of Cambridge
//     Computer Laboratory

// BCPL-ERR

SECTION "ERR"

GET ":COM.BCPL.BCPL-TRN"

LET start(a) BE
    TEST a=0 THEN
    $( FOR i = 0 TO errcount-1 DO
       $( LET p = 3*i
          LET n = errvec!p
          LET s = 0
          IF testflags(1) DO
          $( rc := 20
             n := 0 $)

s := VALOF SWITCHON n INTO
  $( DEFAULT:
        RESULTIS "%N"
     CASE 101: CASE 105:
        RESULTIS "Illegal use of CASE or DEFAULT"
     CASE 104:
        RESULTIS "Illegal use of BREAK, LOOP or RESULTIS"
     CASE 106:
        RESULTIS "Two cases with the same constant"
     CASE 109: CASE 113:
        RESULTIS "L-type expression expected"
     CASE 110: CASE 112:
        RESULTIS "LHS and RHS do not match"
     CASE 115:
        RESULTIS "Name not declared"
     CASE 116:
        RESULTIS "Dynamic free variable used"
     CASE 117: CASE 118: CASE 119:
        RESULTIS "Invalid constant expression"
     CASE 141:
        RESULTIS "Too many cases"
     CASE 142:
        RESULTIS "Name declared twice"
     CASE 143:
        RESULTIS "Too many names declared"
     CASE 144:
        RESULTIS "Too many globals initialised"
     CASE 0:
        writes("****BREAK - ")
        BREAK
     CASE 1:
        writes("Run out of store - ")
        BREAK
  $)

          writes("Error. ")
          writef(s,n)
          writef("*N%N commands compiled*N", errvec!(p+2))
          plist(errvec!(p+1), 0, 4)
          newline()
       $)
       IF reportcount>=reportmax DO
          writes("Too many errors - ")
       IF rc>=20 DO writes("Compilation aborted*N")
    $)
    ELSE
    $( writes("AE tree*N")
       plist(a, 0, 30)
       newline()
    $)


AND plist(x, n, d) BE
 $( LET size = 0
    LET v = TABLE 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
                  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    IF n=0 DO err.p, err.l := level(), exit
    IF testflags(1) DO
    $( writes("*N****BREAK")
       longjump(err.p, err.l) $)

    IF x=0 DO
    $( writes("nil")
       RETURN $)

    IF smallnumber(x) DO
    $( writen(x)
       RETURN
    $)

    SWITCHON h1!x INTO
    $( CASE s.number:
            writen(h2!x)
            RETURN

       CASE s.name:
            writes(x+2)
            RETURN

       CASE s.string:
            writef("*"%S*"",x+1)
            RETURN

       CASE s.semicolonlist:
       CASE s.commalist: size := h2!x + 2
                         goto out
       CASE s.for:
            size := size+2

       CASE s.cond:CASE s.fndef:CASE s.rtdef:
       CASE s.test:
            size := size+1

       CASE s.needs:CASE s.section:CASE s.vecap:
       CASE s.byteap:CASE s.fnap:CASE s.mult:
       CASE s.div:CASE s.rem:CASE s.plus:CASE s.minus:
       CASE s.eq:CASE s.ne:CASE s.ls:CASE s.gr:
       CASE s.le:CASE s.ge:CASE s.lshift:CASE s.rshift:
       CASE s.logand:CASE s.logor:CASE s.eqv:CASE s.neqv:
       CASE s.comma:CASE s.and:CASE s.valdef:
       CASE s.vecdef:CASE s.ass:CASE s.rtap:CASE s.colon:
       CASE s.if:CASE s.unless:CASE s.while:CASE s.until:
       CASE s.repeatwhile:CASE s.repeatuntil:CASE s.let:
       CASE s.switchon:CASE s.case:
       CASE s.manifest:CASE s.static:CASE s.global:
            size := size+1

       CASE s.valof:CASE s.lv:CASE s.rv:CASE s.neg:
       CASE s.not:CASE s.abs:CASE s.table:CASE s.goto:
       CASE s.resultis:CASE s.repeat:CASE s.default:
            size := size+1

       CASE s.loop:CASE s.break:CASE s.return:
       CASE s.finish:CASE s.endcase:CASE s.true:
       CASE s.false:CASE s.query:
       DEFAULT:
            size := size+1

out:        IF n=d DO
            $( writes("etc")
               RETURN $)
            writes("OP")
            writen(h1!x)
            FOR i = 2 TO size DO
            $( newline()
               FOR j = 0 TO n-1 DO writes(v!j)
               writes("**-")
               v!n := i= size-> "  ","! "
               plist(h1!(x+i-1), n+1, d)
            $)
    $)
exit:
 $)


