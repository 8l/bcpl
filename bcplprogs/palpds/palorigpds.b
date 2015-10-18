//./       ADD LIST=ALL,NAME=ADD
 SECTION "ADD"
 
 
GET "PALHDR"
 
 
MANIFEST
 $( NY0 = -Y0 $)
 
 
STATIC
 $( SG = 0
 GA1 = 0
 GA2 = 0
 GA3 = 0
 GA4 = 0 $)
 
 
LET ADD (A, B) = VALOF
 SWITCHON COERCE (@A, TRUE) INTO
 $(
 CASE S.NUM: RESULTIS SADD (A+B+SIGNBIT)
 CASE S.NUMJ: IF NUMARG
 RESULTIS LONGAS1 (B, A, TRUE)
 UNLESS (A NEQV B)>=YSG
 RESULTIS LONGADD (A, B)
 $( LET C = LONGCMP (A, B)
 IF C=0
 RESULTIS Y0
 IF C<0
 $( LET T = A
 A, B := B, T $) $)
 RESULTIS LONGSUB (A, B)
 CASE S.RATN: IF NUMARG
 $( IF A=Y0
 RESULTIS B
 A := SMUL (A, H1!B)
 TEST A<=0
 A := SADD (A+H2!B+SIGNBIT)
 OR A := LONGAS1 (A, H2!B, TRUE)
 TEST A<=0
 SG := S.RATN
 OR SG := S.RATL
 RESULTIS GET4 (SG, H1!B, A, 0)
 $)
 IF WORSE    // A is NUMJ
 $( A := LONGMUL1 (A, H1!B)
 A := LONGAS1 (A, H2!B, TRUE)  // H1!B>Y1 -> A+H2!B is still long
 RESULTIS GET4 (S.RATL, H1!B, A, 0) $)
 $( LET U, V = H1!A, H1!B
 GA1 := IGCD (U+NY0, V+NY0)
 A := SMUL (H2!A, (V+NY0)/GA1+Y0)
 U := (U+NY0)/GA1+Y0
 B := SMUL (H2!B, U)
 TEST A<=0 & B<=0
 A := SADD (A+B+SIGNBIT)
 OR A := ADD (A, B)       // LEAVES GA1
 IF A=Y0
 RESULTIS Y0
 UNLESS GA1=1
 $( TEST A<=0
 GA1 := IGCD (A+NY0, GA1) <>
 A := (A+NY0)/GA1+Y0
 OR GA1 := GCD1 (A, GA1+Y0) <>
 A := LONGDIV1 (A, GA1+Y0)
 V := (V+NY0)/GA1+Y0 $)
 U := SMUL (U, V)
 IF U=Y1
 RESULTIS A
 TEST A<=0 & U<=0
 SG := S.RATN
 OR SG := S.RATL
 RESULTIS GET4 (SG, U, A, 0)
 $)
 CASE S.RATL:
 CASE S.RATP: IF WORSE
 $( IF A=Y0
 RESULTIS B
 A := MUL (A, H1!B)
 A := ADD (A, H2!B)    // now A ~= Y0
 RESULTIS GET4 (!B, H1!B, A, H3!B) $)
 $( LET U, V = H1!A, H1!B
 $( LET D = GCDA (U, V)
 TEST D=Y1
 A := MUL (H2!A, V)
 OR $( U := DIV (U, D)
 $( LET T = DIV (V, D)
 A := MUL (H2!A, T) $) $)
 B := MUL (H2!B, U)
 A := ADD (A, B)
 IF A=Y0
 RESULTIS Y0
 UNLESS D=Y1
 $( D := GCDA (A, D)
 UNLESS D=Y1
 A, V := DIV (A, D), DIV (V, D) $)
 $)
 U := MUL (U, V)
 IF U=Y1
 RESULTIS A
 TEST A<=0 & U<=0
 SG := S.RATN
 OR TEST U>0 & !U=S.POLY
 RESULTIS GET4 (S.RATP, U, A, H3!U)
 OR SG := S.RATL
 RESULTIS GET4 (SG, U, A, 0)
 $)
 CASE S.POLY: IF WORSE
 RESULTIS ADDP1 (A, B)
 RESULTIS ADDPOLY (A, B)
 CASE S.FLT: RESULTIS GETX (S.FLT, 0, GW1 #+ GW2, 0)
 CASE S.FPL: MSG1 (14)
 DEFAULT: IF A=Y0
 RESULTIS B
 IF B=Y0
 RESULTIS A
 RESULTIS ARITHFN (A, B, A.PLUS)
 $)
 
 
LET MINU (A, B) = VALOF
 SWITCHON COERCE (@A, FALSE) INTO
 $(
 CASE S.NUM: RESULTIS SADD (A-B)
 CASE S.NUMJ: IF NUMARG
 TEST WORSE1
 RESULTIS LONGAS1 (A, B, FALSE)
 OR RESULTIS LONGAS1 (B NEQV YSG, A, TRUE)
 IF (A NEQV B)>=YSG
 RESULTIS LONGADD (A, B)
 $( LET C = LONGCMP (A, B)
 IF C=0
 RESULTIS Y0
 IF C<0
 $( C := A
 A := B NEQV YSG
 B := C $) $)
 RESULTIS LONGSUB (A, B)
 CASE S.RATN: IF NUMARG
 TEST WORSE1
 $( IF B=Y0
 RESULTIS A
 B := SMUL (H1!A, B)
 TEST B<=0
 B := SADD (H2!A-B)
 OR B := LONGAS1 (B NEQV YSG, H2!A, TRUE)
 TEST B<=0
 SG := S.RATN
 OR SG := S.RATL
 RESULTIS GET4 (SG, H1!A, B, 0)
 $)
 OR $( A := SMUL (A, H1!B)
 TEST A<=0
 A := SADD (A-H2!B)
 OR A := LONGAS1 (A, H2!B, FALSE)
 TEST A<=0
 SG := S.RATN
 OR SG := S.RATL
 RESULTIS GET4 (SG, H1!B, A, 0) $)
 IF WORSE
 TEST WORSE1
 $( B := LONGMUL1 (B NEQV YSG, H1!A)
 B := LONGAS1 (B, H2!A, TRUE)
 RESULTIS GET4 (S.RATL, H1!A, B, 0) $)
 OR $( A := LONGMUL1 (A, H1!B)
 A := LONGAS1 (A, H2!B, FALSE)
 RESULTIS GET4 (S.RATL, H1!B, A, 0) $)
 $( LET U, V = H1!A, H1!B
 GA1 := IGCD (U+NY0, V+NY0)
 A := SMUL (H2!A, (V+NY0)/GA1+Y0)
 U := (U+NY0)/GA1+Y0
 B := SMUL (H2!B, U)
 TEST A<=0 & B<=0
 A := SADD (A-B)
 OR A := MINU (A, B)      // LEAVES GA1
 IF A=Y0
 RESULTIS Y0
 UNLESS GA1=1
 $( TEST A<=0
 GA1 := IGCD (A+NY0, GA1) <>
 A := (A+NY0)/GA1+Y0
 OR GA1 := GCD1 (A, GA1+Y0) <>
 A := LONGDIV1 (A, GA1+Y0)
 V := (V+NY0)/GA1+Y0 $)
 U := SMUL (U, V)
 IF U=Y1
 RESULTIS A
 TEST A<=0 & U<=0
 SG := S.RATN
 OR SG := S.RATL
 RESULTIS GET4 (SG, U, A, 0)
 $)
 CASE S.RATL:
 CASE S.RATP: IF WORSE
 $( TEST WORSE1
 $( IF B=Y0
 RESULTIS A
 GW1 := MUL (H1!A, B)
 B := A
 A := MINU (H2!A, GW1) $)
 OR $( A := MUL (A, H1!B)
 A := MINU (A, H2!B) $)
 RESULTIS GET4 (!B, H1!B, A, H3!B) $)
 $( LET U, V = H1!A, H1!B
 $( LET D = GCDA (U, V)
 TEST D=Y1
 A := MUL (H2!A, V)
 OR $( U := DIV (U, D)
 $( LET T = DIV (V, D)
 A := MUL (H2!A, T) $) $)
 B := MUL (H2!B, U)
 A := MINU (A, B)
 IF A=Y0
 RESULTIS Y0
 UNLESS D=Y1
 $( D := GCDA (A, D)
 UNLESS D=Y1
 A, V := DIV (A, D), DIV (V, D) $)
 $)
 U := MUL (U, V)
 IF U=Y1
 RESULTIS A
 TEST A<=0 & U<=0
 SG := S.RATN
 OR TEST U>0 & !U=S.POLY
 RESULTIS GET4 (S.RATP, U, A, H3!U)
 OR SG := S.RATL
 RESULTIS GET4 (SG, U, A, 0)
 $)
 CASE S.POLY: IF WORSE
 $( LET T = A
 TEST WORSE1
 $( IF B=Y0
 RESULTIS A
 A := NEG (B) $)
 OR T := B NEQV YSG
 RESULTIS ADDP1 (A, T) $)
 RESULTIS ADDPOLY (A, B NEQV YSG)
 CASE S.FLT: RESULTIS GETX (S.FLT, 0, GW1 #- GW2, 0)
 CASE S.FPL: MSG1 (14)
 DEFAULT: IF B=Y0
 RESULTIS A
 IF EQLV (A, B)
 RESULTIS Y0
 RESULTIS ARITHFN (A, B, A.MINU)
 $)
 
 
.
//./       ADD LIST=ALL,NAME=ARITH
 SECTION "ARITH"
 
 
GET "PALHDR"
 
 
LET ARITHV (P) = VALOF
 $( IF P>0
 $( LET P0 = !P
 UNLESS S.FLT<=P0<=S.POLY
 RESULTIS FALSE $)
 RESULTIS TRUE $)
 
 
// IF THIS WAS CLEVERER, WE COULD MISS 'IF ... =Y0 ...' IN ADD ETC
 
 
AND ARITHFN (P, Q, F) = VALOF
 $( LET E, V, W = ZE, Z, Z
 TEST AF0 (@P, @E)
 GOTO L
 OR TEST AF0 (@Q, @E)
 P := AF1 (@E, P)
 OR $( V := GENSYM ()
 W := V
 P := AF1 (@E, P)
 L:       Q := AF1 (@E, Q) $)
 F := (H3!(H2!F))(P, Q, F)
 RESULTIS MCLOS1 (E, V, F)
 $)
 
 
// ALL THIS TO TRY AND AVOID GENSYMS
 
 
AND AF0 (AP, AE) = VALOF
 $( LET P = !AP
 IF P>0
 SWITCHON !P INTO
 $(
 CASE S.CLOS:
 CASE S.ACLOS:
 !AE, 1!AE, 2!AE := H1!P, H2!P, H2!P
 !AP := H3!P
 RESULTIS TRUE
 CASE S.CLOS2:
 CASE S.ECLOS:
 !AE, 1!AE := H1!P, H2!P
 2!AE := REV (H2!P)
 !AP := H3!P
 RESULTIS TRUE
 $)
 RESULTIS FALSE
 $)
 
 
AND AF1 (AE, B) = VALOF
 $( IF B<=0
 RESULTIS B
 SWITCHON !B INTO
 $(
 CASE S.ACLOS:
 CASE S.CLOS2:
 CASE S.ECLOS:
 CASE S.FCLOS:
 IF EQLV (H1!B, !AE)
 $( IF EQLV (H2!B, 1!AE)
 RESULTIS H3!B
 RESULTIS MLET (H2!B, 2!AE, H3!B) $)
 CASE S.JCLOS:
 CASE S.TUPLE:
 CASE S.XTUPL:
 B := MQU (B)
 RESULTIS AP1 (B, 2!AE)
 CASE S.CLOS: IF EQLV (H1!B, !AE)
 RESULTIS H3!B
 CASE S.FLT:
 CASE S.FPL:
 CASE S.NUMJ:
 CASE S.RATN:
 CASE S.RATL:
 CASE S.RATP:
 CASE S.POLY: RESULTIS B
 DEFAULT: MSG1 (22, B)
 $)
 $)
 
 
// Return the worse case; if commut, swap if it makes the first arg better
// if not commut, flag WORSE1
// Sometimes flag NUMARG, WORSE
// Note that RATL & RATN -> not WORSE
// POLY and RATP are ordered together by main-ness
 
 
LET COERCE (A, COMMUT) = VALOF
 $( NUMARG, WORSE, WORSE1 := FALSE, FALSE, FALSE
 $( LET P = !A
 IF P<=0
 $( UNLESS P<-1
 TEST P=0
 !A := Y0
 OR !A := Y1
 NUMARG := TRUE
 $( LET Q = 1!A
 IF Q<=0
 $( UNLESS Q<-1
 TEST Q=0
 1!A := Y0
 OR 1!A := Y1
 RESULTIS S.NUM $)
 SWITCHON !Q INTO
 $(
 CASE S.LOC: 1!A := H1!Q
 LOOP
 CASE S.FLT: GW1 := FLOAT (!A-Y0)
 GW2 := H2!Q
 CASE S.FPL:
 CASE S.RATL:
 CASE S.POLY:
 CASE S.RATP: WORSE := TRUE
 CASE S.NUMJ:
 CASE S.RATN: RESULTIS !Q
 DEFAULT: RESULTIS S.LOC
 $)
 $) REPEAT
 $)
 
 SWITCHON !P INTO
 $(
 CASE S.LOC: !A := H1!P
 LOOP
 CASE S.NUMJ: $( LET Q = 1!A
 IF Q<=0
 $( UNLESS Q<-1
 TEST Q=0
 1!A := Y0
 OR 1!A := Y1
 NUMARG := TRUE
 TEST COMMUT
 !A, 1!A := Q, P
 OR WORSE1 := TRUE
 RESULTIS S.NUMJ $)
 SWITCHON !Q INTO
 $(
 CASE S.LOC: 1!A := H1!Q
 LOOP
 CASE S.NUMJ: RESULTIS S.NUMJ
 CASE S.RATN:
 CASE S.RATL:
 CASE S.RATP:
 CASE S.POLY: WORSE := TRUE
 RESULTIS !Q
 CASE S.FLT:
 CASE S.FPL: MSG1 (14)
 DEFAULT: RESULTIS S.LOC
 $)
 $) REPEAT
 CASE S.RATN: $( LET Q = 1!A
 IF Q<=0
 $( UNLESS Q<-1
 TEST Q=0
 1!A := Y0
 OR 1!A := Y1
 NUMARG := TRUE
 TEST COMMUT
 !A, 1!A := Q, P
 OR WORSE1 := TRUE
 RESULTIS S.RATN $)
 SWITCHON !Q INTO
 $(
 CASE S.LOC: 1!A := H1!Q
 LOOP
 CASE S.NUMJ: WORSE := TRUE
 TEST COMMUT
 !A, 1!A := Q, P
 OR WORSE1 := TRUE
 CASE S.RATN: RESULTIS S.RATN
 CASE S.FPL:
 CASE S.RATP:
 CASE S.POLY: WORSE := TRUE
 RESULTIS !Q
 CASE S.RATL: RESULTIS S.RATL
 CASE S.FLT: GW1 := FLOAT (H2!P-Y0) #/ FLOAT (H1!P-Y0)
 GW2 := H2!Q
 RESULTIS S.FLT
 DEFAULT: RESULTIS S.LOC
 $)
 $) REPEAT
 CASE S.RATL: $( LET Q = 1!A
 IF Q<=0
 $( UNLESS Q<-1
 TEST Q=0
 1!A := Y0
 OR 1!A := Y1
 WORSE := TRUE
 TEST COMMUT
 !A, 1!A := Q, P
 OR WORSE1 := TRUE
 RESULTIS S.RATL $)
 SWITCHON !Q INTO
 $(
 CASE S.LOC: 1!A := H1!Q
 LOOP
 CASE S.NUMJ: WORSE := TRUE
 TEST COMMUT
 !A, 1!A := Q, P
 OR WORSE1 := TRUE
 CASE S.RATN:
 CASE S.RATL: RESULTIS S.RATL
 CASE S.RATP:
 CASE S.POLY: WORSE := TRUE
 RESULTIS !Q
 CASE S.FLT:
 CASE S.FPL: MSG1 (14)
 DEFAULT: RESULTIS S.LOC
 $)
 $) REPEAT
 CASE S.RATP: $( LET Q = 1!A
 IF Q<=0
 $( UNLESS Q<-1
 TEST Q=0
 1!A := Y0
 OR 1!A := Y1
 WORSE := TRUE
 TEST COMMUT
 !A, 1!A := Q, P
 OR WORSE1 := TRUE
 RESULTIS S.RATP $)
 SWITCHON !Q INTO
 $(
 CASE S.LOC: 1!A := H1!Q
 LOOP
 CASE S.NUMJ:
 CASE S.RATN:
 CASE S.RATL:
 CASE S.FLT:
 CASE S.FPL: TEST COMMUT
 !A, 1!A := Q, P
 OR WORSE1 := TRUE
 WORSE := TRUE
 RESULTIS S.RATP
 CASE S.POLY: WORSE := TRUE
 IF H3!P>=H3!Q
 $( TEST COMMUT
 !A, 1!A := Q, P
 OR WORSE1 := TRUE
 RESULTIS S.RATP $)
 RESULTIS S.POLY
 CASE S.RATP: TEST H3!P>H3!Q
 $( TEST COMMUT
 !A, 1!A := Q, P
 OR WORSE1 := TRUE
 WORSE := TRUE $)
 OR UNLESS H3!P=H3!Q
 WORSE := TRUE
 RESULTIS S.RATP
 DEFAULT: RESULTIS S.LOC
 $)
 $) REPEAT
 CASE S.POLY: $( LET Q = 1!A
 IF Q<=0
 $( UNLESS Q<-1
 TEST Q=0
 1!A := Y0
 OR 1!A := Y1
 WORSE := TRUE
 TEST COMMUT
 !A, 1!A := Q, P
 OR WORSE1 := TRUE
 RESULTIS S.POLY $)
 SWITCHON !Q INTO
 $(
 CASE S.LOC: 1!A := H1!Q
 LOOP
 CASE S.NUMJ:
 CASE S.RATN:
 CASE S.RATL:
 CASE S.FLT:
 CASE S.FPL: TEST COMMUT
 !A, 1!A := Q, P
 OR WORSE1 := TRUE
 WORSE := TRUE
 RESULTIS S.POLY
 CASE S.POLY: TEST H3!P>H3!Q
 $( TEST COMMUT
 !A, 1!A := Q, P
 OR WORSE1 := TRUE
 WORSE := TRUE $)
 OR UNLESS H3!P=H3!Q
 WORSE := TRUE
 RESULTIS S.POLY
 CASE S.RATP: WORSE := TRUE
 IF H3!P>H3!Q
 $( TEST COMMUT
 !A, 1!A := Q, P
 OR WORSE1 := TRUE
 RESULTIS S.POLY $)
 RESULTIS S.RATP
 DEFAULT: RESULTIS S.LOC
 $)
 $) REPEAT
 CASE S.FLT: GW1 := H2!P
 $( LET Q = 1!A
 IF Q<=0
 $( TEST Q<-1
 GW2 := FLOAT (Q-Y0)
 OR TEST Q=0
 GW2 := 0.0
 OR GW2 := 1.0
 RESULTIS S.FLT $)
 SWITCHON !Q INTO
 $(
 CASE S.LOC: 1!A := H1!Q
 LOOP
 CASE S.RATN: GW2 := FLOAT (H2!Q-Y0) #/ FLOAT (H1!Q-Y0)
 RESULTIS S.FLT
 CASE S.FLT: GW2 := H2!Q
 RESULTIS S.FLT
 CASE S.FPL:
 CASE S.NUMJ:
 CASE S.RATL: MSG1 (14)
 CASE S.RATP:
 CASE S.POLY: WORSE := TRUE
 RESULTIS !Q
 DEFAULT: RESULTIS S.LOC
 $)
 $) REPEAT
 CASE S.FPL: $( LET Q = 1!A
 IF Q<=0
 $( UNLESS Q<-1
 TEST Q=0
 1!A := Y0
 OR 1!A := Y1
 NUMARG := TRUE
 TEST COMMUT
 !A, 1!A := Q, P
 OR WORSE1 := TRUE
 RESULTIS S.FPL $)
 SWITCHON !Q INTO
 $(
 CASE S.LOC: 1!A := H1!Q
 LOOP
 CASE S.FLT:
 CASE S.NUMJ:
 CASE S.RATN:
 CASE S.RATL: WORSE := TRUE
 TEST COMMUT
 !A, 1!A := Q, P
 OR WORSE1 := TRUE
 RESULTIS S.FPL
 CASE S.RATP:
 CASE S.POLY: WORSE := TRUE
 RESULTIS !Q
 DEFAULT: RESULTIS S.LOC
 $)
 $) REPEAT
 CASE S.STRING:
 $( LET Q = 1!A
 IF Q>=YLOC
 Q := H1!Q
 IF Q>0 & !Q=S.STRING
 RESULTIS S.STRING $)
 DEFAULT: RESULTIS S.LOC
 $)
 $) REPEAT
 $)
 
 
.
//./       ADD LIST=ALL,NAME=BLIB
 SECTION "BLIB"
 
 
GET "PALHDR"
 
 
MANIFEST
 $( ENTRYMASK = #XFFF0FFFF
 ENTRYWORD = #X9040F000
 NARGSMASK = #X000F0000
 GLOBWORD = #XC7D3F000
 BCPLBIT = #X800000
 EVENSTACK = #X5C40E2E3
 ODDSTACK = #XC3D2405C
 OVERFLOW = 0
 UNSET = 1 //   STACKHWM()  RESULTS
 COUNTWORD1 = #X45EB0000 | 20
 COUNTWORD2 = COUNTWORD1+60
 $)
 
 
LET DUMMY (A) = A
 
 
LET SETIO () BE
 $( STATIC
 $( ZZ = 0 $)
 ZERO := @ZZ | SIGNBIT
 WRC, WRITEP := WRCH, WRITEN
 SYSOUT := FINDOUTPUT ("SYSPRINT")
 CHC, CHZ := 0, 130
 Q.OUTPUT := 0
 TEST SYSOUT=0
 $( LET S = FINDLOG ()
 IF S=0
 WRITETOLOG ("NO SYSPRINT") <>
 STOP (104)
 SELECTOUTPUT (S) $)
 OR Q.SELOUTPUT (SYSOUT)
 SYSIN := FINDINPUT ("SYSIN")
 CH, RCH := ENDSTREAMCH, RCH0
 Q.INPUT := 0
 Q.SELINPUT (SYSIN)
 $)
 
 
LET Q.SELINPUT (S) BE
 UNLESS Q.INPUT=S | S=0
 $( UNLESS Q.INPUT=0
 UNRDCH ()
 SELECTINPUT (S)
 Q.INPUT := S
 CH := RDCH () $)
 
 
AND Q.SELOUTPUT (S) BE
 UNLESS Q.OUTPUT=S | S=0
 $( UNLESS CHC=0 | Q.OUTPUT=0
 WRC ('*N')
 SELECTOUTPUT (S)
 Q.OUTPUT := S
 CHC := 0 $)
 
 
AND Q.ENDREAD (S) BE
 UNLESS S=0
 TEST Q.INPUT=S
 $( ENDREAD ()
 Q.INPUT := 0
 CH := ENDSTREAMCH $)
 OR $( SELECTINPUT (S)
 ENDREAD ()
 UNLESS Q.INPUT=0
 SELECTINPUT (Q.INPUT) $)
 
 
AND Q.ENDWRITE (S) BE
 UNLESS S=0
 TEST Q.OUTPUT=S
 $( ENDWRITE ()
 Q.OUTPUT := 0
 CHC := 0 $)
 OR $( SELECTOUTPUT (S)
 ENDWRITE ()
 UNLESS Q.OUTPUT=0
 SELECTOUTPUT (Q.OUTPUT) $)
 
 
AND RCH0 () = VALOF
 $( LET C = CH
 CH := RDCH ()
 RESULTIS C $)
 
 
AND RCH1 () = VALOF
 $( LET C = RCH0 ()
 UNLESS C=ENDSTREAMCH
 $( IF CHC=0
 WRITES ("# ")
 WCH (C) $)
 RESULTIS C $)
 
 
AND PEEPCH () = VALOF
 $( LET C = RDCH ()
 UNRDCH ()
 RESULTIS C $)
 
 
AND WCH (B) BE
 $( TEST B='*N'
 CHC := 0
 OR TEST CHC>=CHZ
 $( WRITES ("*N      ")
 CHC := 7 $)
 OR CHC := CHC+1
 WRC (B) $)
 
 
AND WCH1 (B) BE
 TEST B='*N'
 ESCW ('N')
 OR TEST B='*'' | B='*"' | B='#'
 ESCW (B)
 OR WCH (B)
 
 
AND ESCW (C) BE
 $( LET T = CHC
 CHC := CHC+1
 WCH ('#')
 IF CHC<T
 CHC := CHC+1
 WRC (C) $)
 
 
AND TAB (N) BE
 $( TEST N<=CHC
 NEWLINE ()
 OR IF N>CHZ
 $( NEWLINE ()
 RETURN $)
 UNTIL N<=CHC
 WCH (' ') $)
 
 
AND XTAB (N) BE
 TAB (N+CHC)
 
 
AND YTAB (N) BE
 UNLESS N=0 | CHC=0
 XTAB (N-CHC REM N)
 
 
AND ZTAB (N) BE
 $( YTAB (N)
 IF CHC+N>=CHZ
 NEWLINE () $)
 
 
AND WRITES (S) BE
 FOR I=1 TO GETBYTE (S, 0) DO
 WCH (GETBYTE (S, I))
 
 
AND UNPACKSTRING (S, V) BE
 FOR I=0 TO GETBYTE (S, 0) DO
 V!I := GETBYTE (S, I)
 
 
AND PACKSTRING (V, S) = VALOF
 
 $(1 LET N = !V & #XFF
 LET I = N/4
 LET X = V!I       //       SAVE IN CASE  S=V
 
 S!I := 0
 FOR P=0 TO N DO
 PUTBYTE (S, P, V!P)
 PUTBYTE (S, I, X)
 RESULTIS I $)1
 
 
AND EQDD (P, Q) = VALOF
 $( FOR I=0 TO GETBYTE (P, 0)
 UNLESS (GETBYTE (P, I) & ~#X40)=(GETBYTE (Q, I) & ~#X40)
 RESULTIS FALSE
 RESULTIS TRUE $)
 
 
AND WRITEF (FORMAT, A, B, C, D, E, F) BE
 
 $(1 LET T = @A
 
 FOR P=1 TO GETBYTE (FORMAT, 0) DO
 $( LET CH = GETBYTE (FORMAT, P)
 
 TEST CH='%' THEN
 $(2 LET F, ARG, N = 0, !T, 0
 P := P+1
 
 $( LET TYPE = GETBYTE (FORMAT, P)
 SWITCHON TYPE INTO
 
 $(
 DEFAULT: WCH (TYPE)
 ENDCASE
 
 CASE 'P': F := WRITEP
 GOTO L
 CASE 'A': F := WRITEARG
 GOTO L
 CASE 'E': F := ARG
 T, ARG := T+1, !T
 GOTO L
 CASE 'T': WTIME (TIME ())
 LOOP
 CASE 'U': F := WTIME
 GOTO L
 CASE 'V': F := WTIME1
 GOTO L
 CASE 'Y': F := YTAB
 GOTO L
 CASE 'Z': F := ZTAB
 GOTO L
 CASE 'F': F := WRFLT
 GOTO L
 CASE 'S': F := WRITES
 GOTO L
 CASE 'C': F := WCH
 GOTO L
 CASE 'O': F := WRITEOCT
 GOTO L1
 CASE 'X': F := WRITEHEX
 GOTO L1
 CASE 'I': F := WRITED
 GOTO L1
 CASE 'J': F := WRITEL
 GOTO L1
 CASE 'N': F := WRITED
 GOTO L
 CASE 'M': UNLESS CHC=0
 NEWLINE ()
 LOOP
 
 L1:         P := P+1
 N := GETBYTE (FORMAT, P)
 N := ('0'<=N<='9') -> N-'0', N+10-'A'
 
 L:          F (ARG, N)
 T := T+1
 $)2
 
 OR WCH (CH)
 $)
 $)1
 
 
 
 
//      THE ROUTINES THAT FOLLOW PROVIDE POST-MORTEM INFORMATION IN
//      THE SPECIFIC ENVIRONMENT OF O.S. FOR THE IBM/360-370.
//
//      THE ROUTINES ARE INTERDEPENDENT WITH ROUTINES IN 'BCPLMAIN'
 
 
AND WTIME (T) BE
 $( T := 26*T/1000
 TEST T>1000
 WRITEF ("%N.%J2 s", T/1000, (T REM 1000)/10)
 OR WRITEF ("%N ms", T) $)
 
 
AND WTIME1 (T) BE
 $( T := 26*T/10000
 WRITEF ("%N.%J2", T/100, T REM 100) $)
 
 
AND VALIDCODE (P) = VALOF
 $( P := P & P.ADDR
 IF (LOADPOINT & PAGEMASK)<=P<=STACKBASE
 RESULTIS TRUE
 RESULTIS FALSE $)
 
 
AND VALIDENTRY (P) = VALOF
 $( IF VALIDCODE (P) & (!P & ENTRYMASK)=ENTRYWORD & GETBYTE (P, -8)<8
 RESULTIS TRUE
 RESULTIS FALSE $)
 
 
AND NARGS (F) = ((!F & NARGSMASK)>>16)-6
 
 
AND ABORT (CODE, ADDR, OLDSTACK, DATA) BE
 
 $(AB MANIFEST
 $( GLOBCON79 = GLOBWORD+4*79
 GLOBCON129 = GLOBWORD+4*129
 GLOBCON137 = GLOBWORD+4*137
 GLOBCON138 = GLOBWORD+4*138 $)
 SETIO ()
 
 $(1 LET SCC, UCC = (CODE>>12) & #XFFF, CODE & #XFFF
 LET USER = (SCC=0)
 LET SOFT = USER
 LET SVALID = OLDSTACK=!(@CODE-2)
 CODE := USER -> UCC, SCC
 
 TEST USER THEN
 WRITEF ("*N*NSTEP ABEND USER CODE %N (%T)*N", CODE)
 
 OR SWITCHON CODE INTO
 
 $(C
 CASE #XC0:
 CASE #XC1:
 CASE #XC2:
 CASE #XC3:
 CASE #XC4:
 CASE #XC5:
 CASE #XC6:
 CASE #XC7:
 CASE #XC8:
 CASE #XC9:
 CASE #XCA:
 CASE #XCB:
 CASE #XCC:
 CASE #XCD:
 CASE #XCE:
 CASE #XCF: $( LET GADDR = (ADDR-GLOBWORD-2 & #XFFFFFF)>>2
 WRITEF ("*N*NPROGRAM INTERRUPT %X3 AT %N(%X6)*N",
 CODE, ADDR>>2, ADDR)
 IF 0<GADDR<10000 DO
 WRITEF ("*NIS G%N DEFINED?*N", GADDR) $)
 ENDCASE
 
 CASE #X0D1: WRITEF ("*N*NCOMP EXHAUSTED AT %N AFTER %U*N", ADDR>>2, DATA)
 SOFT := TRUE
 
 CASE #X0D2: ENDCASE //    FATAL I/O ERROR
 
 CASE #X0D3: WRITES ("*N*NSTACK OVERFLOW*N")
 ENDCASE
 
 DEFAULT: WRITEF ("*N*NSTEP ABEND SYSTEM CODE %X3 (%T)*N", CODE)
 SOFT := TRUE
 $)C
 
 IF SOFT
 UNLESS SOFTERROR=GLOBCON129
 $( UNLESS SVALID
 ERLEV, ERLAB := LEVEL (), L
 SOFTERROR (CODE, SVALID) $)
 
 L: UNLESS USERPOSTMORTEM=GLOBCON79
 USERPOSTMORTEM (CODE, SVALID)
 
 TEST SVALID
 UNLESS SYSOUT=0
 BACKTRACE ()
 OR $( WRITEF ("*NSTACK PTR LOST %N*N", @CODE-3)
 UNLESS SYSOUT=0 | STACKB=GLOBCON137 | STACKL=GLOBCON138
 $( LET Q = STACKB
 L: $( LET F, R = (!Q & P.ADDR)+16*1024, Q<<2
 FOR P=Q+3 TO STACKL
 $( IF 1!P=R & VALIDENTRY ((!P & P.ADDR)>>2)
 $( LET P2 = 2!P & P.ADDR
 IF VALIDCODE (P2>>2) & P2<F
 $( Q := P
 GOTO L $) $) $) $)
 TEST Q>STACKB
 $( WRITEF ("CONJECTURED BACKTRACE FROM %N(%A)", Q, !Q)
 BACKTR (STACKB, Q) $)
 OR $( WRITEF ("STACK FROM %N TO %N*N", STACKB, STACKL)
 FOR I=STACKB TO STACKL
 WRITEF ("%Z%N %A", 12, I, !I) $)
 $)
 $)
 
 UNLESS SYSOUT=0 DO
 MAPSTORE ()
 $)1
 
 STOP (100)
 $)AB
 
 
AND ERRORMESSAGE (FAULT, FORMAT, ROUTINE, DDNAME) BE
 
 $( LET OSTREAM, SYSOUT = OUTPUT (), 0
 
 UNLESS EQDD ("SYSPRINT", DDNAME)
 SYSOUT := FINDOUTPUT ("SYSPRINT")
 IF SYSOUT=0 DO
 SYSOUT := FINDLOG ()
 IF SYSOUT=0 DO
 $( WRITETOLOG ("ERROR MESSAGES REQUIRE SYSPRINT")
 RETURN $)
 
 SELECTOUTPUT (SYSOUT)
 WRITEF ("*N*NFAULT %N IN ROUTINE %S*N", FAULT, ROUTINE)
 WRITEF (FORMAT, DDNAME)
 WRITES ("*N*N")
 SELECTOUTPUT (OSTREAM)
 $)
 
 
AND STACKHWM () = VALOF
 
 $(HWM LET Q = !(STACKEND-1)  //   INITIALISATION LIMIT
 
 UNLESS !(STACKEND-2)=EVENSTACK
 RESULTIS OVERFLOW
 UNLESS STACKBASE<=Q<STACKEND
 RESULTIS OVERFLOW
 
 UNLESS !Q=EVENSTACK
 RESULTIS UNSET
 
 FOR P=Q-2 TO STACKBASE BY -2 DO
 
 $( UNLESS P!1=ODDSTACK
 RESULTIS P+2
 UNLESS P!0=EVENSTACK
 RESULTIS P+1
 $)HWM
 
 
AND MAPSTORE () BE
 
 $(MS LET MAPSEG (S, P1, P2) BE
 $(MO LET MAP = (S=0)
 
 IF MAP
 WRITEF ("*NMAP AND COUNTS FROM %N(%X6) TO %N*N",
 P1, P1<<2, P2)
 
 FOR P=P1 TO (P2-10) DO
 $( IF MAP & VALIDENTRY (P+2)
 $( WRITEF ("%Z%I7/%S", 19, P+2, P)
 LOOP $)
 
 IF P!0=LOADPOINT!0 & P!1=LOADPOINT!1 & (P!4>>24)=11 & (P!7>>24)<=8 DO
 $( UNLESS S=0
 $( IF MAP
 RETURN
 TEST EQDD (S, P+7)
 MAP := TRUE
 OR LOOP $)
 WRITEF ("*N*N%I7  SECTION %S   ", P, P+7)
 WRITEF ("COMPILED ON%S   LENGTH %N WORDS*N",
 P+4, (P!2 & #XFFFF)>>2)
 LOOP
 $)
 
 IF MAP & (P!0=COUNTWORD1 | P!0=COUNTWORD2) DO
 WRITEF ("%Z%I7:%I7", 19, P, P!1)
 $)
 $)MO
 LET MAPLOAD (S) BE
 $( LET P = (SAVEAREA!29)>>2    //   HEAD OF LOAD LIST
 UNTIL P=0 DO
 $( IF (P!9 & BCPLBIT)~=0 & (S=0 | EQDD (S, P+7))
 $( WRITEF ("*N*N*N*NLOADED MODULE *"%S*"*N", P+7)
 MAPSEG (0, (P!3)>>2, (P!4)>>2) $)
 P := !P>>2 $) $)
 LET HWM = STACKHWM ()
 
 WRITES ("*N*NEXTENT OF STACK*N*N")
 WRITEF ("     LIMIT OF STACK      %I7*N", STACKEND)
 WRITES ("     HIGH WATER MARK   ")
 TEST HWM=OVERFLOW THEN
 WRITES ("     BRIM*N")
 OR TEST HWM=UNSET THEN
 WRITES ("    UNSET*N")
 OR WRITEF ("%I9*N", HWM)
 WRITEF ("     BASE OF STACK       %I7*N*N*N", STACKBASE)
 
 MAPGVEC ()
 MAPSEG (0, LOADPOINT, ENDPOINT)   //   MAIN PROGRAM AREA
 MAPLOAD (0)
 
 WRITES ("*N*N")
 $)MS
 
 
AND MAPGVEC () BE
 $( WRITEF ("*NGLOBAL VECTOR(%N) ", @G0)
 TEST 80<=G0<=10000
 WRITEF ("%N GLOBALS ALLOCATED*N", G0)
 OR $( G0 := 400
 WRITES ("GLOBAL ZERO LOST*N") $)
 
 FOR T=1 TO G0
 UNLESS (@G0)!T=GLOBWORD+(T<<2)
 WRITEF ("%ZG%I4 %A", 12, T, (@G0)!T)
 
 WRITES ("*N*N*N")
 $)
 
 
AND BACKTRACE () BE
 BACKTR (STACKBASE, LEVEL ()>>2)
 
 
AND BACKTR (L, P) BE
 $(1 WRITES ("*N*NBACKTRACE CALLED*N")
 
 FOR I=1 TO 500 DO
 $( LET Q = P
 P := 1!P>>2
 IF P<L | P=Q
 $( WRITES ("*N   FLOOR")
 BREAK $)
 
 TAB (123)
 WRITEF ("<%N", (2!Q & P.ADDR)-(!P & P.ADDR))
 
 WRITEF ("*N%I6: %A", P, !P)
 UNLESS WFRAME (P, Q, WRITEARG)
 BREAK
 $)
 
 WRITES ("*N*NEND OF BACKTRACE*N*N")
 $)1
 
 
AND WFRAME (P, Q, R) = VALOF
 $( IF Q>P+18
 Q := P+18
 FOR T=P+3 TO Q-1 DO
 $( ZTAB (20)
 IF CHC=0
 TAB (20)
 R (!T, FALSE) $)
 RESULTIS VALIDCODE (!P>>2) $)
 
 
AND WRITEARG (V) BE
 
 $( LET A = V & P.ADDR
 $( LET F = A>>2
 IF VALIDCODE (F)
 $( TEST VALIDENTRY (F)
 WRITEF ("'%S'", F-2)
 OR WRITEF ("*"%X2:%N", V>>24, F)
 RETURN $) $)
 IF VALIDCODE (V)
 WRITEF ("'%X2:%N", V>>24, A) <>
 RETURN
 
 IF V=EVENSTACK | V=ODDSTACK
 WRITES ("STACK") <> RETURN
 
 IF V>P.ADDR | V<-P.ADDR
 WRITEF ("%X2:%N", V>>24, A) <>
 RETURN
 
 WRITEN (V)
 $)
 
 
 
// THE DEFINITIONS THAT FOLLOW ARE MACHINE INDEPENDENT
 
 
AND WN (N, D, C) BE
 $( LET T = VEC 10
 AND I, K = 0, -N
 IF N<0 DO
 D, K := D-1, N
 T!I, K, I := -(K REM 10), K/10, I+1 REPEATUNTIL K=0
 FOR J=I+1 TO D DO
 WCH (C)
 IF N<0 DO
 WCH ('-')
 FOR J=I-1 TO 0 BY -1 DO
 WCH (T!J+'0')
 $)
 
 
AND WRITED (N, D) BE
 WN (N, D, '*S')
 
 
AND WRITEL (N, D) BE
 WN (ABS N, D, '0')
 
 
AND WRITEN (N) BE
 WN (N, 0)
 
 
AND NEWLINE () BE
 WCH ('*N')
 
 
AND READN () = VALOF
 $(1 LET NEG = FALSE
 WHILE CH='*S' | CH='*N'
 RCH ()
 IF CH='+' | CH='-'
 $( NEG := CH='-'
 RCH () $)
 $( LET SUM = RBASE (10)
 IF NEG
 RESULTIS -SUM
 RESULTIS SUM
 $)1
 
 
AND RBASE (BASE) = VALOF
 $( LET SUM = 0
 $( LET D = NVAL (CH)
 IF D>=BASE
 RESULTIS SUM
 SUM := BASE*SUM+D
 RCH () $) REPEAT $)
 
 
AND NVAL (C) = VALOF
 $( IF '0'<=C<='9'
 RESULTIS C-'0'
 IF 'A'<=C<='F'
 RESULTIS C-'A'+10
 RESULTIS 4096 $)
 
 
AND READSN (P, I) = VALOF
 $( LET K, N = GETBYTE (P, 0), 0
 $( IF I>=K
 RESULTIS N
 I := I+1
 $( LET Q = GETBYTE (P, I)
 UNLESS '0'<=Q<='9'
 RESULTIS N
 N := 10*N+Q-'0' $) $) REPEAT $)
 
 
AND WRITEOCT (N, D) BE
 $( IF D>1 DO
 WRITEOCT (N>>3, D-1)
 WCH ((N & 7)+'0') $)
 
 
AND WRITEHEX (N, D) BE
 $( IF D>1 DO
 WRITEHEX (N>>4, D-1)
 WCH ((N & 15)! TABLE '0', '1', '2', '3', '4', '5', '6', '7',
 '8', '9', 'A', 'B', 'C', 'D', 'E', 'F') $)
 
 
AND WRITEO (N) BE
 WRITEOCT (N, 8)
 
 
AND WRITEX (N) BE
 WRITEHEX (N, 8)
 
 
AND WRFLT (X) BE
 $( IF X #= 0.0
 WRITES ("0.0") <> RETURN
 IF X #< 0.0
 WCH ('-') <> X :=  #- X
 $( LET E = 7
 UNTIL X #> 1000000.0
 X := X #* 10.0 <> E := E-1
 UNTIL X #< 10000000.0
 X := X #/ 10.0 <> E := E+1
 X := (FIX X+5)/10
 TEST X<100000
 X := 100000
 OR WHILE X>=1000000
 X, E := X/10, E+1
 TEST E=1
 WCH ('0'+X/100000) <> E, X := 0, X REM 100000
 OR WCH ('0')
 WCH ('.')
 WRITEL (X, 5)
 UNLESS E=0
 WCH ('E') <> WRITEN (E)
 $)
 $)
 
 
.
//./       ADD LIST=ALL,NAME=DIFR
 SECTION "DIFR"
 
 
GET "PALHDR"
 
 
LET DIFR (P, N) = VALOF
 $( FOR I=Y1 TO G.POSINT (N)
 P := DIFR1 (P)
 RESULTIS P $)
 
 
AND DIFR1 (P) = VALOF
 $( IF @P>STACKL
 STKOVER ()
 $( IF P<=0
 RESULTIS Y0
 SWITCHON !P INTO
 $(
 CASE S.LOC: P := H1!P
 LOOP
 CASE S.NUMJ:
 CASE S.RATN:
 CASE S.RATL:
 CASE S.FLT:
 CASE S.FPL: RESULTIS Y0
 DEFAULT: MSG1 (16, DIFR1, P)
 
 CASE S.RATP: $( LET S1 = DIFR1 (H2!P)
 S1 := MUL (S1, H1!P)
 $( LET S2 = DIFR1 (H1!P)
 S2 := MUL (S2, H2!P)
 S1 := MINU (S1, S2) $)
 IF S1=Y0
 RESULTIS Y0
 P := MUL (H1!P, H1!P)
 RESULTIS DIV (S1, P) $)
 
 CASE S.POLY: $( LET R = Y0
 $( LET Q = MDASH (H2!P)
 Q := FIND (Q, E)
 TEST Q=Z
 Q := Y0
 OR UNLESS Q=Y0
 $( LET P1 = H1!P NEQV (P & YSG)
 IF H3!P1=Y0
 P1 := H1!P1 NEQV (P1 & YSG)
 R := GET4 (S.POLY, ZSY, H2!P, H3!P)
 $( LET R0 = R
 $( LET T = MUL (H2!P1, H3!P1)
 T := GET4 (S.POLYJ, ZSY, T, H3!P1-1)+(P1 & YSG)
 H1!R0, R0 := T, T
// The sign of P1 should be OK now
 P1 := H1!P1 $) REPEATUNTIL P1=Z
 TEST H3!R0=Y0
 TEST R0<YSG
 R := H2!R0
 OR R := NEG (H2!R0)
 OR H1!R0 := Z
 $)
 R := MUL (R, Q)
 $)
 $)
 $( LET P1 = H1!P NEQV (P & YSG)
 $( LET D = DIFR1 (H2!P1)
 UNLESS D=Y0
 $( TEST H3!P1=Y0
 IF P1>=YSG
 D := NEG (D)
 OR $( LET T = GET4 (S.POLYJ, Z, Y1, H3!P1)
 T := GET4 (S.POLY, T, H2!P, H3!P)+(P1 & YSG)
 D := MUL (D, T) $)
 R := ADD (R, D) $)
 P1 := H1!P1 NEQV (P1 & YSG)
 $) REPEATUNTIL (P1 & P.ADDR)=Z
 $)
 RESULTIS R
 $)
 $)
 $) REPEAT
 $)
 
 
.
//./       ADD LIST=ALL,NAME=ERMSG
 SECTION "ERMSG"
 
 
GET "PALHDR"
 
 
LET MSG0 (N, A, B, C, D) BE
 $( LET S, W = ZERO, WRC
 WRC := WRCH
 SELECTOUTPUT (SYSOUT)
 WRITEF ("*N*N# (%T) ")
 SWITCHON N INTO
 $(
 DEFAULT: MSG1 (13, MSG0)
 CASE 1:  S := "Doubt about %A"
 ENDCASE
 CASE 2:  S := "Load/unload error %S"
 ENDCASE
 CASE 3:  S := "Bad print (%N)"
 ENDCASE $)
 WRITEF (S, A, B, C, D)
 NEWLINE ()
 SELECTOUTPUT (Q.OUTPUT)
 WRC := W
 $)
 
 
AND MSG1 (N, A, B, C, D) BE
 $( LET S = ZERO
 WRC := WRCH
 Q.SELOUTPUT (SYSOUT)
 WRITEF ("*N*N# (%T) ")
 SWITCHON N INTO
 $(
 DEFAULT: A := N
 S := "System error %N"
 GOTO L2
 CASE 0:  GOTO L1
 CASE 1:  S := "Trap while Pal region unavailable*N"
 GOTO L3
 CASE 2:  S := "Cannot load %S (code %N)*N"
 GOTO L3
 CASE 3:  S := "Stack overflow"
 GOTO L1
 CASE 4:  S := "Operating system trap %X3"
 GOTO L1
 CASE 5:  S := "Buffer overflow: %P"
 GOTO L1
 CASE 6:  S := "conformality: %P,%P"
 GOTO L1
 CASE 7:  S := "DIVISION BY 0"
 GOTO L1
 CASE 8:  S := "Poly division not exact: %P,%P"
 GOTO L1
 CASE 9:  S := "I-O error: %S %S*N"
 GOTO L3
 CASE 10: S := "Only %N words"
 GOTO L1
 CASE 11: S := "Cannot bind %P,%P"
 GOTO L1
 CASE 12: S := "Cannot assign %P:=%P"
 GOTO L1
 CASE 13: S := "System error in %A"
 GOTO L2
 CASE 14: S := "Arith overflow"
 GOTO L1
 CASE 15: S := "New name: %P"
 GOTO L1
 CASE 16: S := "Bad arg for %A (%P)"
 GOTO L1
 CASE 17: S := "ap global %P unset"
 GOTO L1
 CASE 18: S := "Poly exponent overflow: %P"
 GOTO L1
 CASE 19: S := "Peculiar semantics (%P)"
 GOTO L1
 CASE 20: S := "Bad arg for %P (%P)"
 GOTO L1
 CASE 21: S := "Bad args for %P (%P,%P)"
 GOTO L1
 CASE 22: S := "Bad arith arg (%P)"
 GOTO L1
 CASE 23: S := "Bad arith args (%P,%P)"
 GOTO L1
 CASE 24: S := "Bad list arg (%P)"
 GOTO L1
 CASE 25: S := "Unset value"
 GOTO L1
 CASE 26: S := "%S not yet implemented"
 GOTO L1
 CASE 27: S := "Open-code global problem"
 GOTO L1
 CASE 28: S := "%P should be %P-tuple"
 GOTO L1
 CASE 29: S := "%P should be positive integer"
 GOTO L1
 CASE 30: S := "Stack broken (%N)"
 GOTO L2
 CASE 31: S := "Dump broken (%N)"
 GOTO L2
 CASE 32: S := "%A lost"
 GOTO L2
 CASE 33: S := "%S broken (%P)"
 GOTO L2
 CASE 34: S := "Trap in %A"
 GOTO L2
 CASE 35: S := "Re-decl global %P"
 GOTO L1
 CASE 36: S := "Ref unset global %P"
 GOTO L1
 CASE 37: S := "Bad arg for BCPL: %P"
 GOTO L1
 CASE 38: S := "Insufficient region"
 GOTO L1
 CASE 39: S := "Store jam"
 GOTO L2
 CASE 40: S := "Bad arg in code: %P, %P"
 GOTO L1
 CASE 41: S := "undecl global in code"
 GOTO L1
 $)
 L1: WRITEF (S, A, B, C, D)
 IF PARAMZ
 $( BACKTR (ERLEV>>2, LEVEL ()>>2)
 PMAP (PARAMC) $)
 LONGJUMP (ERLEV, ERLAB)
 L2: WRITEF (S, A, B, C, D)
 TEST ERZ=Z | ~PARAMD
 $( BACKTRACE ()
 PMAP (PARAMC)
 MAPSTORE () $)
 OR EVAL (ERZ)
 STOP (16)
 L3: WRITEF (S, A, B, C, D)
 STOP (12)
 $)
 
 
AND SOFTERROR (C) BE
 MSG1 (4, C)
 
 
AND MSG2 (A) BE
 MSG1 (33, "Tree", A)
 
 
AND MSG3 (A) BE
 MSG1 (36, A)
 
 
AND WRITEARGP (A, F) BE
 $( IF A<=0
 $( PRIN (A)
 RETURN $)
 $( LET B = A & P.ADDR
 IF ST1<=B<=ST2
 $( LET B0 = !B
 TEST 0<=B0<=TYPSZ
 TEST F & OKPAL
 PRINTA (B)
 OR WRITEF ("(%N#%N# %P)", B, B0, B)
 OR TEST ST1<=B0<=ST2
 WRITES ("#s")
 OR WRITEF ("?%X2:%N (%X2:%N)", A>>24, B, B0>>24, B0 & P.ADDR)
 RETURN $)
 $)
 WRITEF ("?%N", A)
 $)
 
 
AND ERRORP (P) BE
 WRITEARGP (P, FALSE)
 
 
AND PMAP (B) =VALOF
 $( TEMPUSP ("Pmap", 0)
 $( LET EE, JJ = E, J
 LET Q1 = @B-3
 $( LET Q = 1!Q1>>2
 IF Q<=STACKBASE
 BREAK
 $( LET QQ = !Q
 IF QQ<0
 $( WRITEF ("*N%A   ", QQ)
 IF !Q1=ABORT
 Q1 := Q+NARGS ((QQ & P.ADDR)>>2)+3
 FOR T=Q+3 TO Q1-1
 $( TEST B
 TAB (10)
 OR $( ZTAB (12)
 IF CHC=0
 XTAB (12) $)
 WRITEARGP (!T, B) $)
 IF QQ=EVAL
 $( IF OKPAL
 $( PRINE (EE)
 PRIND (Q!4)
 PRINJ (JJ) $)
 EE, JJ := Q!6, Q!7 $)
 $)
 $)
 Q1 := Q
 $) REPEAT
 $)
 TEMPUSP ("End pmap", 0)
 RESULTIS Z
 $)
 
 
AND PFRAME (P, Q) = VALOF
 $( LET T = WRITEARG
 IF !P<0
 $( WCH ('p')
 T := WRITEARGP $)
 RESULTIS PFRAME (P, Q, T) $)
 
 
.
//./       ADD LIST=ALL,NAME=EVAL
 SECTION "EVAL"
 
 
GET "PALHDR"
 
 
LET EVAL (C) = VALOF
 $( LET F, P1, P2, P3 = Z, -M, E, J
 J, M := ZJ, S.J
 IF @C>STACKL
 STKOVER ()
 
 $(R $(U   // extend frame
 LL.EV:   CYCLES := CYCLES+1
 IF C<=0
 ARG1 := C <> BREAK
 
 SWITCHON !C INTO
 $(
 DEFAULT: ARG1 := C
 BREAK
 
 CASE S.LOC: C := H1!C
 LOOP
 
 CASE S.CD: GOTO H3!C
 
 CASE S.TRA: DOTRACE (C, ARG1)
 
 CASE S.MB: MSG2 (C)
 CASE S.GLZ: MSG3 (C)
 CASE S.GLG:
 CASE S.GLO:
 CASE S.QU: ARG1 := H2!C
 BREAK
 
 CASE S.GENSY:
 CASE S.NAME: $( LET G = E
 $( IF C=H3!G
 ARG1 := H2!G <> ENDCASE
 G := H1!G $) REPEATUNTIL G=Z $)
 MSG1 (15, C)
 BREAK
 
 CASE S.UNSET:
 MSG1 (25)
 CASE S.UNSET1:
 BREAK
 
 CASE S.E: ARG1 := E
 BREAK
 
 CASE S.J: TEST F=Z
 $( IF M>=S.MZ
 M := M-JGAP
 J := KEEP2 (J) $)
 OR J := KEEP1 (J, F)
 ARG1 := J
 BREAK
 
 CASE S.CLOS:
 CASE S.ACLOS:
 CASE S.CLOS2:
 CASE S.ECLOS:
 CASE S.FCLOS:
 ARG1 := GET4 (!C, E, H2!C, H3!C)
 BREAK
 
 CASE S.REC: E := GET4 (S.E, E, ZSY, H2!C)
 CASE S.DASH: F, M, C := GET4 (M, F, H3!C, H2!C)+YFJ, S.MMF2R, H1!C
 LOOP
 
 CASE S.RECA: E := GET4 (S.E, E, ZSY, H2!C)
 ARG1 := H1!C
 UNLESS ARG1<=0
 ARG1 := (FFF!!ARG1)(ARG1)
 ARG1 := (H3!C)(ARG1, H2!C)
 BREAK
 
 CASE S.SEQ: F, M, C := GET4 (M, F, H2!C, Z)+YFJ, S.MMS, H1!C
 LOOP
 
 CASE S.SEQA: ARG1 := H1!C
 (FFF!!ARG1)(ARG1)
 C := H2!C
 LOOP
 
 CASE S.APZ: MSG1 (17, H1!C)
 BREAK
 
 CASE S.APPLY:
 F, M, C := GET4 (M, F, H2!C, ZSY)+YFJ, S.MMAL, H1!C
 LOOP
 
 CASE S.APPLE:
 ARG1 := H2!C
 UNLESS ARG1<=0
 ARG1 := (FFF!!ARG1)(ARG1)
 C := H1!C
 UNLESS C<=0
 C := (FFF!!C)(C)
 GOTO LL.AP
 
 CASE S.AA1: F, M, C := GET4 (M, F, H3!C, Z)+YFJ, S.MMA1, H2!C
 LOOP
 
 CASE S.A1A: ARG1 := H2!C
 UNLESS ARG1<=0
 ARG1 := (FFF!!ARG1)(ARG1)
 C := H3!C
 UNLESS F=Z
 J, F, M := GET4 (M, E, J, F)+YFJ, Z, S.MZ
 LA.A1:            E := GET4 (S.E, H1!C, ARG1, H2!C)
 C := H3!C
 LOOP
 
 CASE S.AA:
 CASE S.AP1: F, M, C := GET4 (M, F, H3!C, Z)+YFJ, S.MMF1, H2!C
 LOOP
 
 CASE S.ZZ:
 CASE S.APV: F, M, C := GET4 (M, F, H3!C, Z)+YFJ, S.MMF1A, H2!C
 LOOP
 
 CASE S.AA2: $( LET C1 = H2!C
 F, M, C := GET4 (M, F, H3!C, H2!C1)+YFJ, S.MMA2L, H2!(H1!C1) $)
 LOOP
 
 CASE S.AP2: $( LET C1 = H2!C
 F, M, C := GET4 (M, F, H3!C, H2!C1)+YFJ, S.MMF2L, H2!(H1!C1) $)
 LOOP
 
 CASE S.A1E: ARG1 := H2!C
 UNLESS ARG1<=0
 ARG1 := (FFF!!ARG1)(ARG1)
 ARG1 := (H3!C)(ARG1)
 BREAK
 
 CASE S.AVE: ARG1 := H2!C
 UNLESS ARG1<=0
 $( ARG1 := (FFF!!ARG1)(ARG1)
 IF ARG1>=YLOC
 ARG1 := H1!ARG1 $)
 ARG1 := (H3!C)(ARG1)
 BREAK
 
 CASE S.A2A: ARG1 := H2!C
 $( LET A2 = H2!(H1!ARG1)
 UNLESS A2<=0
 A2 := (FFF!!A2)(A2)
 ARG1 := H2!ARG1
 UNLESS ARG1<=0
 ARG1 := (FFF!!ARG1)(ARG1)
 C := H3!C
 UNLESS F=Z
 J, F, M := GET4 (M, E, J, F)+YFJ, Z, S.MZ
 $( LET U = H2!C
 E := GET4 (S.E, H1!C, A2, H2!U)
 E := GET4 (S.E, E, ARG1, H2!(H1!U)) $)
 $)
 C := H3!C
 LOOP
 
 CASE S.A2E: ARG1 := H2!C
 $( LET A2 = H2!(H1!ARG1)
 UNLESS A2<=0
 A2 := (FFF!!A2)(A2)
 ARG1 := H2!ARG1
 UNLESS ARG1<=0
 ARG1 := (FFF!!ARG1)(ARG1)
 ARG1 := (H3!C)(ARG1, A2)
 BREAK $)
 
 CASE S.AEA: ARG1 := FF.TUPLE (H2!C)
 UNLESS F=Z
 J, F, M := GET4 (M, E, J, F)+YFJ, Z, S.MZ
 C := H3!C
 LA.AE:            E := BINDA (H2!C, ARG1, H1!C)
 C := H3!C
 LOOP
 
 CASE S.AAA: F, M, C := GET4 (M, F, H3!C, Z)+YFJ, S.MMAA, H2!C
 CASE S.TUPLE:
 F, M, C := GET4 (M, F, H1!C, Z)+YFJ, S.MMT, H2!C
 LOOP
 
 CASE S.APQ: F, M, C := GET4 (M, F, H2!(H1!C), H3!C)+YFJ, S.MMAQ, H2!C
 LOOP
 
 CASE S.AQE: ARG1 := H2!C
 UNLESS ARG1<=0
 ARG1 := (FFF!!ARG1)(ARG1)
 $( LET T = H3!C
 C := H2!(H1!C)
 GOTO T $)
 
 CASE S.RETU: F, C := Z, H2!C
 TEST J<YFJ
 TEST J=ZJ
 M := S.J
 OR M := S.Z
 OR M := S.MZ
 LOOP
 
 CASE S.COND: F, M, C := GET4 (M, F, H2!C, H3!C)+YFJ, S.MMCOND, H1!C
 LOOP
 
 CASE S.CONDA:
 CASE S.CONDB:
 $( LET A = H1!C
 A := (FFF!!A)(A)
 IF A=Z | (A>=YLOC & H1!A=Z)
 C := H3!C <> LOOP
 C := H2!C
 LOOP $)
 
 CASE S.LET: F, M, C := GET4 (M, F, H1!C, H2!C)+YFJ, S.MMLET, H3!C
 LOOP
 
 CASE S.LETA: ARG1 := H3!C
 UNLESS ARG1<=0
 ARG1 := (FFF!!ARG1)(ARG1)
 UNLESS F=Z
 J, F, M := GET4 (M, E, J, F)+YFJ, Z, S.MZ
 E := BIND (H2!C, ARG1, E)
 C := H1!C
 LOOP
 
 CASE S.LETB: ARG1 := H3!C
 UNLESS ARG1<=0
 ARG1 := (FFF!!ARG1)(ARG1)
 UNLESS F=Z
 J, F, M := GET4 (M, E, J, F)+YFJ, Z, S.MZ
 E := GET4 (S.E, E, ARG1, H2!C)
 C := H1!C
 LOOP
 
 CASE S.COLON:       // declare labels mutually recursively
 UNLESS F=Z
 J, F, M := GET4 (M, E, J, F)+YFJ, Z, S.Z
 J := KEEP2 (J)
 $( LET E1 = GET4 (S.E, ZE, ZSY, Z)
 $( LET A = GET4 (S.KCLOS, E1, J, H3!C)
 E := GET4 (S.E, E, A, H1!C)
 C := H2!C $) REPEATWHILE C>0 & !C=S.COLON
 H1!E1, H2!E1, H3!E1 := H1!E, H2!E, H3!E $)
 LOOP
 
 LL.EX:            C := GW2
 F, M := GET4 (M, F, GW0, GW1)+YFJ, S.MMF2R
 LOOP
 $)
 BREAK
 $)U REPEAT
 
 $(F
 LL.ZC:   SWITCHON M INTO
 $(M
 CASE S.J: M, E, J := -P1, P2, P3
 RESULTIS ARG1
 
 CASE S.Z: M := !J
 IF FALSE
 $(
 CASE S.MZ:     M := !J
 !J, STACKP := STACKP, J & P.ADDR $)
 E, F, J := H1!J, H3!J, H2!J
 LOOP
 
 LL.RSC:  CASE S.MCC: M := !J
 IF FALSE
 $(
 CASE S.MMCC:   M := !J
 !J, STACKP := STACKP, J & P.ADDR $)
 E, C, J := H1!J, H3!J, H2!J
 GOTO H3!C
 
 LL.RSF:  CASE S.MCF: M := !J
 IF FALSE
 $(
 CASE S.MMCF:   M := !J
 !J, STACKP := STACKP, J & P.ADDR $)
 E, F, J := H1!J, H3!J, H2!J
 C := H3!F
 GOTO H3!C
 
 CASE S.MCK: M := !J
 E, F, J := H1!J, H3!J, H2!J
 C := H3!F
 F := GET4 (S.MMCF, H1!F, ARG1, Z)+YFJ
 GOTO H3!C
 
 CASE S.MMCK: M := !J
 !J, STACKP := STACKP, J & P.ADDR
 E, F, J := H1!J, H3!J, H2!J
 H2!F := ARG1
 C := H3!F
 GOTO H3!C
 
 DEFAULT: MSG1 (30, M)
 
 CASE S.MMAL:
 CASE S.MAL: H3!F := ARG1
 C := H2!F
 M := M+1   // M := S.MMAR or S.MAR
 BREAK
 
 CASE S.MAR: M := !F
 IF FALSE
 $(
 CASE S.MMAR:   M := !F
 !F, STACKP := STACKP, F & P.ADDR $)
 C := H3!F
 F := H1!F
 LL.AP:            IF C<=0
 $( ARG1 := C
 LOOP $)      // ??A??
 SWITCHON !C INTO
 $(
 DEFAULT: ARG1 := C
 LOOP      // ??A??
 
 CASE S.GLZ: MSG3(C)
 CASE S.GLG: CASE S.GLO: CASE S.QU: ARG1 := AP1(C,ARG1)
 LOOP
 
 LA.APLOC:         CASE S.LOC: C := H1!C
 GOTO LL.AP
 
 LA.ENTX:          CASE S.CDX: UNLESS F=Z
 J, F, M := GET4 (M, E, J, F)+YFJ, Z, S.MZ
 LL.ENTX:                   E := BIND (H3!C, ARG1, H2!C)
 C := H1!C
 GOTO H3!C
 
 LA.ENTY:          CASE S.CDY: UNLESS F=Z
 J, F, M := GET4 (M, E, J, F)+YFJ, Z, S.MZ
 LL.ENTY:                   E := H2!C
 C := H1!C
 GOTO H3!C
 
 LA.ENTZ:          CASE S.CDZ: UNLESS F=Z
 J, F, M := GET4 (M, E, J, F)+YFJ, Z, S.MZ
 LL.ENTZ:                   E := GET4 (S.E, ZE, ARG1, H2!C)
 C := H1!C
 GOTO H3!C
 
 CASE S.UNSET:
 MSG1 (25)
 CASE S.UNSET1:
 LOOP
 
 CASE S.RDS: Q.SELINPUT (H2!C-Y0)
 ARG1 := REA ()
 LOOP
 
 CASE S.WRS: Q.SELOUTPUT (H2!C-Y0)
 PRCH (ARG1)
 LOOP
 
 CASE S.BCPLF:
 ARG1 := CALLBCPL (C)
 LOOP
 
 CASE S.BCPLR:
 CALLBCPL (C)
 ARG1 := Z
 LOOP
 
 CASE S.BCPLV:
 GW0 := CALLBCPL (C)
 ARG1 := TRANSPAL (GW0)
 LOOP
 
 CASE S.CODEV:
 IF ARG1>=YLOC
 ARG1 := H1!ARG1
 CASE S.CODE0:
 CASE S.CODE1:
 ARG1 := (H2!C)(ARG1)
 LOOP
 
 LA.APCODE2:       CASE S.CODE2:
 UNTIL ARG1>0 & !ARG1=S.TUPLE & H3!ARG1=Y2
 $( IF ARG1>=YLOC
 ARG1 := H1!ARG1 <> LOOP
 MSG1 (28, ARG1, Y2) $)
 ARG1 := (H2!C)(H2!(H1!ARG1), H2!ARG1)
 LOOP
 
 CASE S.CODE3:
 ARG1 := G.NT (ARG1, Y3)
 GW0 := H1!ARG1
 ARG1 := (H2!C)(H2!(H1!GW0), H2!GW0, H2!ARG1)
 LOOP
 
 CASE S.CODE4:
 ARG1 := G.NT (ARG1, Y0+4)
 GW0 := H1!ARG1
 GW1 := H2!GW0
 GW0 := H1!GW0
 GW2 := H2!C       // ?BCPL
 ARG1 := GW2 (H2!(H1!GW0), H2!GW0, GW1, H2!ARG1)
 LOOP
 
 LA.APTUP:         CASE S.TUPLE:
 UNLESS ARG1<0
 $( IF ARG1>=YLOC
 ARG1 := H1!ARG1
 UNLESS ARG1<0
 $( IF ARG1=0
 $( ARG1 := C
 LOOP $)
 IF !ARG1=S.TUPLE
 $( LET T = MQU (H1!ARG1)
 F, M := GET4 (M, F, T, ZSY)+YFJ, S.MMAL
 ARG1 := H2!ARG1
 GOTO LA.APTUP $)
 MSG1 (20, C, ARG1) $)
 $)
 UNLESS Y0<ARG1<=H3!C
 ARG1 := Z <> LOOP
 FOR I=ARG1+1 TO H3!C
 C := H1!C
 ARG1 := H2!C
 LOOP
 
 CASE S.XTUPL:
 UNLESS ARG1<0
 $( IF ARG1>=YLOC
 ARG1 := H1!ARG1
 UNLESS ARG1<0
 MSG1 (20, C, ARG1) $)
 IF ARG1<=Y0
 ARG1 := Z <> LOOP
 $( LET C3 = H3!C
 IF ARG1<=C3
 L:    $( FOR I=ARG1 TO C3
 C := H1!C
 ARG1 := H2!C
 LOOP $)
 $( LET C2, A = H2!C, ARG1
 $( LET C31 = C3+1
 APPLY (C2, C31)
 TEST H3!C=C3
 $( H1!C := GET4 (S.TUPLE, H1!C, ARG1, C31)
 H3!C := C31
 IF C31=A
 BREAK
 C3 := C31 $)
 OR $( C3 := H3!C
 IF C3>=A
 $( ARG1 := A
 GOTO L $) $)
 $) REPEAT
 $)
 $)
 LOOP
 
 CASE S.POLY: IF ARG1>=YLOC
 ARG1 := H1!ARG1
 IF ARG1=Z // ??P??
 $( ARG1 := EVALPOLY (C)
 LOOP $)
 UNLESS ARG1<0
 MSG1 (29, ARG1)
 GW1 := C
 C, GW1 := H1!C, GW1 NEQV C REPEATUNTIL C=Z | ARG1<=H3!C
 TEST C=Z | ARG1<H3!C
 ARG1 := Y0
 OR TEST GW1<YSG
 ARG1 := H2!C
 OR ARG1 := NEG (H2!C)
 LOOP
 
 CASE S.J:
 CASE S.Z:
 CASE S.MCC:
 CASE S.MCF:
 CASE S.MCK:
 CASE S.MAL:
 CASE S.MAR:
 CASE S.MS:
 CASE S.MT:
 CASE S.MAA:
 CASE S.MA1:
 CASE S.MF1:
 CASE S.MF1A:
 CASE S.MA2L:
 CASE S.MA2R:
 CASE S.MF2L:
 CASE S.MF2R:
 CASE S.MAQ:
 CASE S.MLET:
 CASE S.MCOND:
 $( LET C1 = H1!C  // ??J?? jval or stack ?
 UNLESS C1>0 & !C1=S.E
 MSG1 (19, C) $)
 ARG1 := GET4 (S.JCLOS, Z, C, ARG1)        // C & P.ADDR
 LOOP
 
 CASE S.E: UNLESS F=Z
 J, F, M := GET4 (M, E, J, F)+YFJ, Z, S.MZ
 E, C := C, ARG1
 BREAK
 
 CASE S.CLOS: UNLESS F=Z
 J, F, M := GET4 (M, E, J, F)+YFJ, Z, S.MZ
 E, C := H1!C, H3!C
 BREAK
 
 CASE S.ACLOS:
 UNLESS F=Z
 J, F, M := GET4 (M, E, J, F)+YFJ, Z, S.MZ
 E := GET4 (S.E, H1!C, ARG1, H2!C)
 C := H3!C
 BREAK
 
 LA.APCLOS2:       CASE S.CLOS2:
 LA.APECLOS:       CASE S.ECLOS:
 UNLESS F=Z
 J, F, M := GET4 (M, E, J, F)+YFJ, Z, S.MZ
 LL.APECLOS:                $( LET C2 = H2!C
 UNTIL ARG1>0 & !ARG1=S.TUPLE & H3!ARG1=H3!C2
 $( IF ARG1>=YLOC
 ARG1 := H1!ARG1 <> LOOP
 MSG1 (6, C2, ARG1) $)
 E := BINDA (C2, ARG1, H1!C) $)
 C := H3!C
 BREAK
 
 LA.APFCLOS:       CASE S.FCLOS:
 UNLESS F=Z
 J, F, M := GET4 (M, E, J, F)+YFJ, Z, S.MZ
 LL.APFCLOS:                E := BIND (H2!C, ARG1, H1!C)
 C := H3!C
 BREAK
 
 CASE S.JCLOS:
 J := H2!C
 TEST J=ZJ
 M := S.J
 OR M := S.Z
 C, F := H3!C, Z
 GOTO LL.AP
 
 CASE S.KCLOS:
 E, J := H1!C, H2!C
 TEST J=ZJ
 M := S.J
 OR M := S.Z
 C, F := H3!C, Z
 BREAK
 $)
 
 CASE S.MS: M := !F
 IF FALSE
 $(
 CASE S.MMS:    M := !F
 !F, STACKP := STACKP, F & P.ADDR $)
 C := H2!F
 F := H1!F
 BREAK
 
 CASE S.MMT: $( LET T = H3!F
 TEST T=Z
 ARG1 := GET4 (S.TUPLE, Z, ARG1, Y1)
 OR ARG1 := GET4 (S.TUPLE, T, ARG1, H3!T+1) $)
 C := H2!F
 IF C=Z
 $( M := !F
 !F, STACKP := STACKP, F & P.ADDR
 F := H1!F
 LOOP $)
 H2!F, H3!F := H1!C, ARG1
 M, C := S.MMT, H2!C
 BREAK
 
 CASE S.MT: $( LET T = H3!F
 TEST T=Z
 ARG1 := GET4 (S.TUPLE, Z, ARG1, Y1)
 OR ARG1 := GET4 (S.TUPLE, T, ARG1, H3!T+1) $)
 C := H2!F
 IF C=Z
 $( M := !F
 F := H1!F
 LOOP $)
 F := GET4 (!F, H1!F, H1!C, ARG1)+YFJ
 M, C := S.MMT, H2!C
 BREAK
 
 CASE S.MAA: M := !F
 IF FALSE
 $(
 CASE S.MMAA:   M := !F
 !F, STACKP := STACKP, F & P.ADDR $)
 C := H2!F
 F := H1!F
 UNLESS F=Z
 J, F, M := GET4 (M, E, J, F)+YFJ, Z, S.MZ
 E := BINDA (H2!C, ARG1, H1!C)
 C := H3!C
 BREAK
 
 CASE S.MA1: M := !F
 IF FALSE
 $(
 CASE S.MMA1:   M := !F
 !F, STACKP := STACKP, F & P.ADDR $)
 C := H2!F
 F := H1!F
 UNLESS F=Z
 J, F, M := GET4 (M, E, J, F)+YFJ, Z, S.MZ
 E := GET4 (S.E, H1!C, ARG1, H2!C)
 C := H3!C
 BREAK
 
 CASE S.MF1A: IF ARG1>=YLOC
 ARG1 := H1!ARG1
 CASE S.MF1: M := !F
 IF FALSE
 $(
 CASE S.MMF1A:  IF ARG1>=YLOC
 ARG1 := H1!ARG1
 CASE S.MMF1:   M := !F
 !F, STACKP := STACKP, F & P.ADDR $)
 C := H2!F
 F := H1!F
 ARG1 := C (ARG1)
 LOOP
 
 CASE S.MMA2L:
 C := H3!F
 H3!F := ARG1
 M := S.MMA2R
 BREAK
 
 CASE S.MA2L: C := H3!F
 F := GET4 (!F, H1!F, H2!F, ARG1)+YFJ
 M := S.MMA2R
 BREAK
 
 CASE S.MA2R: M := !F
 IF FALSE
 $(
 CASE S.MMA2R:  M := !F
 !F, STACKP := STACKP, F & P.ADDR $)
 C := H2!F
 $( LET V = H3!F
 F := H1!F
 UNLESS F=Z
 J, F, M := GET4 (M, E, J, F)+YFJ, Z, S.MZ
 $( LET U = H2!C
 E := GET4 (S.E, H1!C, V, H2!U)
 E := GET4 (S.E, E, ARG1, H2!(H1!U)) $) $)
 C := H3!C
 BREAK
 
 CASE S.MMF2L:
 C := H3!F
 H3!F := ARG1
 M := S.MMF2R
 BREAK
 
 CASE S.MF2L: C := H3!F
 F := GET4 (!F, H1!F, H2!F, ARG1)+YFJ
 M := S.MMF2R
 BREAK
 
 CASE S.MF2R: M := !F
 IF FALSE
 $(
 CASE S.MMF2R:  M := !F
 !F, STACKP := STACKP, F & P.ADDR $)
 C, GW0 := H2!F, H3!F
 F := H1!F
 ARG1 := C (ARG1, GW0)
 LOOP
 
 CASE S.MAQ: M := !F
 IF FALSE
 $(
 CASE S.MMAQ:   M := !F
 !F, STACKP := STACKP, F & P.ADDR $)
 C := H2!F
 $( LET T = H3!F
 F := H1!F
 GOTO T $)
 
 CASE S.MLET: M := !F
 IF FALSE
 $(
 CASE S.MMLET:  M := !F
 !F, STACKP := STACKP, F & P.ADDR $)
 C := H2!F
 $( LET V = H3!F
 F := H1!F
 UNLESS F=Z
 J, F, M := GET4 (M, E, J, F)+YFJ, Z, S.MZ
 E := BIND (V, ARG1, E)
 BREAK $)
 
 CASE S.MCOND:
 M := !F
 IF FALSE
 $(
 CASE S.MMCOND: M := !F
 !F, STACKP := STACKP, F & P.ADDR $)
 TEST ARG1=Z | (ARG1>=YLOC & H1!ARG1=Z)
 C := H3!F
 OR C := H2!F
 F := H1!F
 BREAK
 $)F REPEAT
 $)R REPEAT
 
 LS.ER: MSG1 (40, C, F)
 LS.GLZ:
 MSG1 (41)
 
 LS.CY: ARG1 := H2!C
 C := H1!C
 GOTO H3!C
 LS.CYF:
 F := GET4 (S.MMCF, F, H2!C, Z)+YFJ
 C := H1!C
 GOTO H3!C
 LS.NA: ARG1 := H1!(H1!E)
 FOR I=4+Y0 TO H2!C
 ARG1 := H1!ARG1
 ARG1 := H2!ARG1
 C := H1!C
 GOTO H3!C
 LS.NA1:
 ARG1 := H2!E
 C := H1!C
 GOTO H3!C
 LS.NA2:
 ARG1 := H2!(H1!E)
 C := H1!C
 GOTO H3!C
 LS.NAF:
 ARG1 := H1!(H1!E)
 FOR I=4+Y0 TO H2!C
 ARG1 := H1!ARG1
 F := GET4 (S.MMCF, F, H2!ARG1, Z)+YFJ
 C := H1!C
 GOTO H3!C
 LS.NA1F:
 F := GET4 (S.MMCF, F, H2!E, Z)+YFJ
 C := H1!C
 GOTO H3!C
 LS.NA2F:
 F := GET4 (S.MMCF, F, H2!(H1!E), Z)+YFJ
 C := H1!C
 GOTO H3!C
 
 LS.ST: F := GET4 (S.MMCF, F, ARG1, Z)+YFJ
 C := H1!C
 GOTO H3!C
 LS.US: IF F>=YFJ
 !F, STACKP := STACKP, F & P.ADDR
 ARG1 := H2!F
 F := H1!F
 C := H1!C
 GOTO H3!C
 
 LS.TUP:
 GW0 := GET4 (S.TUPLE, H2!F, ARG1, H2!C)
 TEST F>=YFJ
 H2!F := GW0
 OR F := GET4 (S.MMCF, H1!F, GW0, Z)+YFJ
 C := H1!C
 GOTO H3!C
 LS.TUPA:
 GW0 := GET4 (S.TUPLE, Z, ARG1, Y1)
 F := GET4 (S.MMCF, F, GW0, Z)+YFJ
 C := H1!C
 GOTO H3!C
 LS.TUPZ:
 TEST F<YFJ
 $( ARG1 := GET4 (S.TUPLE, H2!F, ARG1, H2!C)
 F := H1!F $)
 OR $( LET T = F & P.ADDR
 F := H1!F
 !T, H1!T, H2!T, H3!T := S.TUPLE, H2!T, ARG1, H2!C   // ugh
 ARG1 := T $)
 C := H1!C
 GOTO H3!C
 LS.1TUP:
 ARG1 := GET4 (S.TUPLE, Z, ARG1, Y1)
 C := H1!C
 GOTO H3!C
 
 LS.CLOSL:
 ARG1 := H2!C
 ARG1 := GET4 (!ARG1, E, H2!ARG1, H3!ARG1)
 C := H1!C
 GOTO H3!C
 LS.CLOSX:
 ARG1 := H2!C
 ARG1 := GET4 (!ARG1, H1!ARG1, E, H3!ARG1)
 C := H1!C
 GOTO H3!C
 
 LS.BIND:
 E := BIND (H2!C, ARG1, E)
 C := H1!C
 GOTO H3!C
 LS.UNBIND:
 FOR I=Y1 TO H2!C
 E := H1!E
 C := H1!C
 GOTO H3!C
 
 LS.LV: UNLESS ARG1>=YLOC
 ARG1 := GET4 (S.LOC, ARG1, 0, 0)+YLOC
 IF FALSE
 LS.RV: IF ARG1>=YLOC
 ARG1 := H1!ARG1
 LS.BINDE:
 E := GET4 (S.E, E, ARG1, H2!C)
 C := H1!C
 GOTO H3!C
 
 LS.BVF:
 ARG1 := H2!F
 H2!F := H1!ARG1
 ARG1 := H2!ARG1
 C := H1!C
 GOTO H3!C
 LS.BVFE:
 ARG1 := H2!F
 H2!F := H1!ARG1
 E := GET4 (S.E, E, H2!ARG1, H2!C)
 C := H1!C
 GOTO H3!C
 LS.BVFA:
 F := GET4 (S.MMCF, F, H1!ARG1, Z)+YFJ
 LS.BVF1:
 ARG1 := H2!ARG1
 C := H1!C
 GOTO H3!C
 LS.BVFZ:
 ARG1 := H2!(H2!F)
 !F, STACKP := STACKP, F & P.ADDR
 F := H1!F
 C := H1!C
 GOTO H3!C
 LS.BVE:
 E := GET4 (S.E, E, H2!ARG1, H2!C)
 ARG1 := H1!ARG1
 C := H1!C
 GOTO H3!C
 LS.BVEZ:
 ARG1 := H2!ARG1
 E := GET4 (S.E, E, ARG1, H2!C)
 C := H1!C
 GOTO H3!C
 
 $( LET V = 0
 LL.ENT2:
 $( LET T = H2!C
 C := H1!C   // CD (CD . BV1 BV2) E LL.ENT2
 E := GET4 (S.E, T, V, H3!C) $) $)
 E := GET4 (S.E, E, ARG1, H2!C)
 C := H1!C
 GOTO H3!C
 
 LS.APV:
 IF ARG1>=YLOC
 ARG1 := H1!ARG1
 LS.AP1:
 ARG1 := (H2!C)(ARG1)
 C := H1!C
 GOTO H3!C
 LS.HDV:
 IF ARG1>=YLOC
 ARG1 := H1!ARG1
 TEST ARG1>0 & !ARG1>=MM3
 ARG1 := H2!ARG1
 OR ARG1 := Z
 C := H1!C
 GOTO H3!C
 LS.MIV:
 IF ARG1>=YLOC
 ARG1 := H1!ARG1
 TEST ARG1>0 & !ARG1>=MM3
 ARG1 := H3!ARG1
 OR ARG1 := Z
 C := H1!C
 GOTO H3!C
 LS.TLV:
 IF ARG1>=YLOC
 ARG1 := H1!ARG1
 TEST ARG1>0
 ARG1 := H1!ARG1
 OR ARG1 := Z
 C := H1!C
 GOTO H3!C
 LS.NULL:
 IF ARG1>=YLOC
 ARG1 := H1!ARG1
 ARG1 := ARG1=Z
 C := H1!C
 GOTO H3!C
 LS.ATOM:
 IF ARG1>=YLOC
 ARG1 := H1!ARG1
 TEST ARG1<=0
 ARG1 := TRUE
 OR ARG1 := !ARG1<=S.GLO
 C := H1!C
 GOTO H3!C
 
 LS.AP2S:
 ARG1 := (H2!C)(H2!F, ARG1)
 IF FALSE
 LS.AP2: ARG1 := (H2!C)(ARG1, H2!F)
 IF F>=YFJ
 !F, STACKP := STACKP, F & P.ADDR
 F := H1!F
 C := H1!C
 GOTO H3!C
 LS.AP2SF:
 GW0 := (H2!C)(H2!F, ARG1)
 IF FALSE
 LS.AP2F: GW0 := (H2!C)(ARG1, H2!F)
 TEST F>=YFJ
 H2!F := GW0
 OR F := GET4 (S.MMCF, H1!F, GW0, Z)+YFJ
 C := H1!C
 GOTO H3!C
 
 LS.XCONS:
 $( LET T = ARG1
 ARG1 := H2!F
 IF FALSE
 LL.CONS: T := H2!F
 TEST ARG1<=0
 $( UNLESS ARG1=Z
 GOTO LS.ER
 ARG1 := GET4 (S.TUPLE, Z, T, Y1) $)
 OR $( UNTIL !ARG1=S.TUPLE
 $( IF ARG1>=YLOC
 $( ARG1 := H1!ARG1
 LOOP $)
 GOTO LS.ER $)
 ARG1 := GET4 (S.TUPLE, ARG1, T, H3!ARG1+1) $)
 $)
 IF F>=YFJ
 !F, STACKP := STACKP, F & P.ADDR
 F := H1!F
 C := H1!C
 GOTO H3!C
 LS.XCONSF:
 $( LET S, T = H2!F, ARG1
 IF FALSE
 LL.CONSF: S, T := ARG1, H2!F
 TEST S<=0
 $( UNLESS S=Z
 GOTO LS.ER
 TEST F>=YFJ
 H2!F := GET4 (S.TUPLE, Z, T, Y1)
 OR $( S := GET4 (S.TUPLE, Z, T, Y1)
 F := GET4 (S.MMCF, H1!F, S, Z)+YFJ $) $)
 OR $( UNTIL !S=S.TUPLE
 $( IF S>=YLOC
 $( S := H1!S
 LOOP $)
 GOTO LS.ER $)
 TEST F>=YFJ
 H2!F := GET4 (S.TUPLE, S, T, H3!S+1)
 OR $( S := GET4 (S.TUPLE, S, T, H3!S+1)
 F := GET4 (S.MMCF, H1!F, S, Z)+YFJ $) $)
 $)
 C := H1!C
 GOTO H3!C
 
 LS.E: ARG1 := E
 C := H1!C
 GOTO H3!C
 LS.J: IF M>=S.MZ
 M := M-JGAP
 J := KEEP2 (J)
 ARG1 := J
 C := H1!C
 GOTO H3!C
 
 LS.REC0:
 E := GET4 (S.E, E, ZSY, H2!C)
 C := H1!C
 GOTO H3!C
 LS.REC1:
 ARG1 := (H2!C)(ARG1, H3!E)
 C := H1!C
 GOTO H3!C
 LS.DASH:
 ARG1 := DIFR (ARG1, H2!C)
 C := H1!C
 GOTO H3!C
 
 LL.COND:
 TEST ARG1=Z | (ARG1>=YLOC & H1!ARG1=Z)
 C := H1!C
 OR C := H2!C
 GOTO H3!C
 
 LL.APNF:
 IF F>=YFJ
 LL.APNF1: !F, STACKP := STACKP, F & P.ADDR
 $( LET T = H2!F
 F := H1!F
 TEST F<YFJ
 F := GET4 (S.MMCF, H1!F, H2!F, H1!C)+YFJ
 OR H3!F := H1!C
 C := T $)
 J, F, M := GET4 (M, E, J, F)+YFJ, Z, S.MMCF
 GOTO LL.AP
 
 LL.APNK:
 TEST F<YFJ
 $( LET T = H2!F
 F := GET4 (S.MMCF, H1!F, Z, H1!C)+YFJ
 C := T $)
 OR $( H3!F := H1!C
 C := H2!F $)
 J, F, M := GET4 (M, E, J, F)+YFJ, Z, S.MMCK
 GOTO LL.AP
 
 LL.APNC:
 J, M := GET4 (M, E, J, H1!C)+YFJ, S.MMCC
 LL.APNJ:
 C := H2!F
 IF F>=YFJ
 !F, STACKP := STACKP, F & P.ADDR
 F := Z
 GOTO LL.AP
 
 LL.APCF:     // Apply known code
 TEST F<YFJ
 F := GET4 (S.MMCF, H1!F, H2!F, H1!C)+YFJ
 OR
 LL.APCF1: H3!F := H1!C
 J, F, M := GET4 (M, E, J, F)+YFJ, Z, S.MMCF
 C := H2!C
 E := H2!C
 C := H1!C
 GOTO H3!C
 
 LL.APCK:
 F := GET4 (S.MMCF, F, Z, H1!C)+YFJ
 J, F, M := GET4 (M, E, J, F)+YFJ, Z, S.MMCK
 C := H2!C
 E := H2!C
 C := H1!C
 GOTO H3!C
 
 LL.APCC:
 J, M := GET4 (M, E, J, H1!C)+YFJ, S.MMCC
 C := H2!C
 E := H2!C
 C := H1!C
 GOTO H3!C
// No need for LL.APCJ
 
 LL.APBF:
 TEST F<YFJ
 F := GET4 (S.MMCF, H1!F, H2!F, H1!C)+YFJ
 OR
 LL.APBF1: H3!F := H1!C
 J, F, M := GET4 (M, E, J, F)+YFJ, Z, S.MMCF
 C := H2!C
 E := GET4 (S.E, ZE, ARG1, H2!C)
 C := H1!C
 GOTO H3!C
 
 LL.APBK:
 F := GET4 (S.MMCF, F, Z, H1!C)+YFJ
 J, F, M := GET4 (M, E, J, F)+YFJ, Z, S.MMCK
 C := H2!C
 E := GET4 (S.E, ZE, ARG1, H2!C)
 C := H1!C
 GOTO H3!C
 
 LL.APBC:
 J, M := GET4 (M, E, J, H1!C)+YFJ, S.MMCC
 C := H2!C
 E := GET4 (S.E, ZE, ARG1, H2!C)
 C := H1!C
 GOTO H3!C
 
 LL.APKF:     // Apply known tree
 C := H1!C
 TEST F<YFJ
 F := GET4 (S.MMCF, H1!F, H2!F, H1!C)+YFJ
 OR
 LL.APKF1: H3!F := H1!C
 J, F, M := GET4 (M, E, J, F)+YFJ, Z, S.MMCF
 $( LET T = H3!C
 C := H2!C
 GOTO T $)
 
 LL.APKK:
 C := H1!C
 F := GET4 (S.MMCF, F, Z, H1!C)+YFJ
 J, F, M := GET4 (M, E, J, F)+YFJ, Z, S.MMCK
 $( LET T = H3!C
 C := H2!C
 GOTO T $)
 
 LL.APKC:
 C := H1!C
 J, M := GET4 (M, E, J, H1!C)+YFJ, S.MMCC
 $( LET T = H3!C
 C := H2!C
 GOTO T $)
 LL.APKJ:
 C := H1!C
 $( LET T = H3!C
 C := H2!C
 GOTO T $)
 
 LL.SVC:
 J, M := GET4 (M, E, J, H2!C)+YFJ, S.MMCC
 C := H1!C
 GOTO H3!C
 LL.SVF:
 TEST F<YFJ
 F := GET4 (S.MMCF, H1!F, H2!F, H2!C)+YFJ
 OR
 LL.SVF1: H3!F := H2!C
 J, F, M := GET4 (M, E, J, F)+YFJ, Z, S.MMCF
 C := H1!C
 GOTO H3!C
 
 $( LET FIXBCPL1 () BE     // "Too many globals"
 $( LL.GLZ := LS.GLZ
 LL.CY := LS.CY
 LL.CYF := LS.CYF
 LL.NA := LS.NA
 LL.NA1 := LS.NA1
 LL.NA2 := LS.NA2
 LL.NAF := LS.NAF
 LL.NA1F := LS.NA1F
 LL.NA2F := LS.NA2F
 LL.ST := LS.ST
 LL.US := LS.US
 LL.TUP := LS.TUP
 LL.TUPA := LS.TUPA
 LL.TUPZ := LS.TUPZ
 LL.1TUP := LS.1TUP
 LL.CLOSL := LS.CLOSL
 LL.CLOSX := LS.CLOSX
 LL.LV := LS.LV
 LL.RV := LS.RV
 LL.BVF := LS.BVF
 LL.BVFE := LS.BVFE
 LL.BVFA := LS.BVFA
 LL.BVF1 := LS.BVF1
 LL.BVFZ := LS.BVFZ
 LL.BVE := LS.BVE
 LL.BVEZ := LS.BVEZ
 LL.BIND := LS.BIND
 LL.BINDE := LS.BINDE
 LL.UNBIND := LS.UNBIND
 LL.APV := LS.APV
 LL.AP1 := LS.AP1
 LL.HDV := LS.HDV
 LL.MIV := LS.MIV
 LL.TLV := LS.TLV
 LL.NULL := LS.NULL
 LL.ATOM := LS.ATOM
 LL.AP2S := LS.AP2S
 LL.AP2 := LS.AP2
 LL.AP2SF := LS.AP2SF
 LL.AP2F := LS.AP2F
 LL.XCONS := LS.XCONS
 LL.XCONSF := LS.XCONSF
 LL.E := LS.E
 LL.J := LS.J
 LL.REC0 := LS.REC0
 LL.REC1 := LS.REC1
 LL.DASH := LS.DASH
 $)
 
 $)
 $)
 
 
.
//./       ADD LIST=ALL,NAME=EVALA
 SECTION "EVALA"
 
 
GET "PALHDR"
 
 
LET EVSY (A) = VALOF
 $( IF PARAMY
 RESULTIS FALSE
 $( IF A<=0
 RESULTIS TRUE
 IF FFF!!A=MSG2
 RESULTIS FALSE
 SWITCHON !A INTO
 $(
 DEFAULT: RESULTIS TRUE
 CASE S.TUPLE:
 $( UNLESS EVSY (H2!A)
 RESULTIS FALSE
 A := H1!A $) REPEATUNTIL A=Z
 RESULTIS TRUE
 CASE S.AA:
 CASE S.ZZ: A := H2!A
 LOOP
 CASE S.DASH: A := H1!A
 LOOP
 $)
 $) REPEAT
 $)
 
 
// CONSTRUCTION OF E-TREES PREVENTS THEIR BEING RE-ENTRANT
// SO WE CAN MISS STACK-CHECKING
 
 
AND FF.CLOS (A) = GET4 (!A, E, H2!A, H3!A)
 
 
AND FF.RECA (A) = VALOF
 $( E := GET4 (S.E, E, ZSY, H2!A)
 $( LET B = H1!A
 UNLESS B<=0
 B := (FFF!!B)(B)
 RESULTIS (H3!A)(B, H2!A) $) $)
 
 
AND FF.DASH (A) = VALOF
 $( LET B = H1!A
 UNLESS B<=0
 B := (FFF!!B)(B)
 RESULTIS DIFR (B, H2!A) $)
 
 
AND FF.E () = E
 
 
AND FF.A1E (A) = VALOF
 $( LET B = H2!A
 UNLESS B<=0
 B := (FFF!!B)(B)
 RESULTIS (H3!A)(B) $)
 
 
AND FF.AVE (A) = VALOF
 $( LET B = H2!A
 UNLESS B<=0
 B := (FFF!!B)(B)
 IF B>=YLOC
 B := H1!B
 RESULTIS (H3!A)(B) $)
 
 
AND FF.A2E (A) = VALOF
 $( LET B1 = H2!A
 LET B2 = H2!(H1!B1)
 UNLESS B2<=0
 B2 := (FFF!!B2)(B2)
 B1 := H2!B1
 UNLESS B1<=0
 B1 := (FFF!!B1)(B1)
 RESULTIS (H3!A)(B1, B2) $)
 
 
AND FF.TUPLE (A) = VALOF
 $( LET P, L = Z, Y0
 $( LET B = H2!A
 UNLESS B<=0
 B := (FFF!!B)(B)
 L := L+1
 P := GET4 (S.TUPLE, P, B, L)
 A := H1!A $) REPEATUNTIL A=Z
 RESULTIS P $)
 
 
AND FF.CONDB (A) = VALOF
 $( $( LET A1 = H1!A
 A1 := (FFF!!A1)(A1)
 TEST A1=Z | (A1>=YLOC & H1!A1=Z)
 A := H3!A
 OR A := H2!A $)
 UNLESS A<=0
 A := (FFF!!A)(A)
 RESULTIS A $)
 
 
AND FF.SEQA (A) = VALOF
 $( $( LET A1 = H1!A
 (FFF!!A1)(A1) $)
 A := H2!A
 UNLESS A<=0
 A := (FFF!!A)(A)
 RESULTIS A $)
 
 
AND FF.ARGT (V, A, E) = VALOF
 $( $( E := GET4 (S.E, E, ZSY, H2!V)
 V := H1!V $) REPEATUNTIL V=Z
 V := E
 $( LET A2 = H2!A
 IF A2>0
 A2 := (FFF!!A2)(A2)
 H2!V := A2
 A := H1!A
 IF A=Z
 RESULTIS E
 V := H1!V $) REPEAT
 $)
 
 
.
//./       ADD LIST=ALL,NAME=FLATTEN
 SECTION "FLATTEN"
 
 
GET "PALHDR"
 
 
MANIFEST
 $( FVARU = SIGNBIT>>1 $)
 
 
STATIC
 $( LL = 0 $)
 
 
LET MSGF (N, A, B, C, D) BE
 $( LET S, F, W = ZERO, DUMMY, WRC
 WRITES ("*N*N# ")
 SWITCHON N INTO
 $(
 DEFAULT: A := N
 S := "Unknown error %N in flatten"
 ENDCASE
 CASE 0:  S := "Error %N in flatten"
 F := BACKTRACE
 ENDCASE
 CASE 1:  S := "Bad arg for flatten: %P"
 ENDCASE
 CASE 2:  S := "Cannot find %P"
 ENDCASE
 CASE 3:  S := "Undecl %P"
 F, N := PRINE, B
 ENDCASE
 CASE 4:  S := "Cannot flatten %P"
 ENDCASE
 CASE 5:  S := "Flatten cannot yet cope with %P"
 ENDCASE
 CASE 6:  S := "Bad bv part %P"
 ENDCASE
 CASE 7:  S := "Undef global %P"
 ENDCASE
 $)
 WRITEF (S, A, B, C, D)
 F (N)
 WRC := W
 LONGJUMP (FLEVEL (FLATTEN), L.FLATTEN)
 $)
 
 
AND REVF (C, D) = VALOF
 $( UNTIL C=ZSY
 $( LET T = H1!C
 H1!C := D
 D, C := C, T $)
 RESULTIS D $)
 
 
AND FLATTEN (A) = VALOF
 $( IF A>0
 SWITCHON !A INTO
 $(
 CASE S.LOC: A := H1!A
 LOOP
 CASE S.GENSY:
 CASE S.NAME: $( LET G = E
 $( IF H3!G=A
 $( LET T = FLATTEN (H2!G)
 H2!G := T
 RESULTIS T $)
 G := H1!G $) REPEATUNTIL G=Z $)
 MSGF (2, A)
 CASE S.GLG:
 CASE S.GLO: $( LET A2 = FLATTEN (H2!A)
 FIXAPF (A2, H3!A)
 H3!A := H2!A
 H2!A := A2
 RESULTIS A $)
 CASE S.TUPLE:
 LMAP (FLATTEN, A)
 RESULTIS Z
 CASE S.CLOS:
 CASE S.ACLOS:
 CASE S.CLOS2:
 CASE S.ECLOS:
 CASE S.FCLOS:
 $( LET A1, A2 = H1!A, H2!A
 LET E = SIMENV (A1, A2)
 LET C = FLAT0 (H3!A, E)
 LET F = RESULT2<FVARU
 H3!A := C
 TEST FBV (A2)
 TEST F & SIMNAME (A2)
 $( LL := S.CDZ
 A1, A2 := A2, LL.ENTZ
 C := LOADN (C, Y1, 0) $)
 OR $( C := FLATBV (C, A2)
 LL := S.CDY $)
 OR LL := S.CDX
 RESULTIS GET4 (LL, C, A1, A2)
 $)
 $)
 MSGF (1, A)
 L.FLATTEN:
 RESULTIS Z
 $) REPEAT
 
 
AND EFSY (A, N) = VALOF
 $( IF N>0    // dont get too embroiled
 RESULTIS Y0
 IF A>0
 SWITCHON !A INTO
 $(
 DEFAULT: RESULTIS Y0
 CASE S.STRING:
 CASE S.FLT:
 CASE S.FPL:
 CASE S.NUMJ:
 CASE S.RATN:
 CASE S.RATL:
 CASE S.RATP:
 CASE S.POLY:
 CASE S.GENSY:
 CASE S.NAME:
 CASE S.GLZ:
 CASE S.GLG:
 CASE S.GLO:
 CASE S.QU: ENDCASE
 CASE S.LOC: A := H1!A
 LOOP
 CASE S.TUPLE:
 CASE S.AP2:
 CASE S.A2E: RESULTIS Y2
 CASE S.APPLY:
 CASE S.APPLE:
 CASE S.AA1:
 CASE S.A1A:
 CASE S.AA2:
 CASE S.A2A:
 CASE S.AAA:
 CASE S.AEA:
 CASE S.APQ:
 CASE S.AQE: RESULTIS Y2
 CASE S.COND:
 CASE S.CONDA:
 CASE S.CONDB:
 $( LET T = EFSY (H2!A, N+1)
 A := EFSY (H3!A, N+1)
 TEST A>T
 RESULTIS T
 OR RESULTIS A $)
 CASE S.SEQ:
 CASE S.SEQA: A, N := H2!A, N+1
 LOOP
 $)
 RESULTIS Y1
 $) REPEAT
 
 
// GSEQF chains COND-nodes, to reduce repetition;
// its top byte indicates global properties of the function: eg FVARU
 
 
AND FLAT0 (A, E) = VALOF
 $( LET G, SV = ZSY, GSEQF | SIGNBIT
 GSEQF := @G
 $( LET C = FLAT1 (A, ZC, E, Z, FALSE)
 UNTIL G=ZSY
 $( LET T, N = H1!G, H2!G
 WHILE !N=S.MB    // the same COND-node with diff targets
 N := H2!N
 !G, H1!G, H2!G, H3!G := !N, H1!N, H2!N, H3!N
 G := T $)
 RESULT2 := GSEQF & MAXINT
 GSEQF := SV
 RESULTIS C
 $)
 $)
 
 
AND FLAT1 (A, C, E, F, CSTAC) = VALOF
 $( IF @A>STACKL
 STKOVER ()
 $( IF C=ZC & (F~=Z | CSTAC)
 MSGF (0, 1)
 TEST A>0
 SWITCHON !A INTO
 $(
 DEFAULT: MSGF (4, A)
 
 CASE S.GLG:
 CASE S.GLO:
 CASE S.QU: A := H2!A
 CASE S.STRING:
 CASE S.FLT:
 CASE S.FPL:
 CASE S.NUMJ:
 CASE S.RATN:
 CASE S.RATL:
 CASE S.RATP:
 CASE S.POLY: TEST CSTAC
 LL := LL.CYF
 OR LL := LL.CY
 ENDCASE
 CASE S.LOC: A := H1!A
 LOOP
 CASE S.CD: TEST C=ZC
 RESULTIS A
 OR TEST CSTAC
 LL := LL.APCK
 OR TEST F=Z
 LL := LL.APCC
 OR LL := LL.APCF
 ENDCASE
 CASE S.GLZ: TEST CSTAC
 LL := LL.CYF
 OR LL := LL.CY
 C := GET4 (S.CD, C, ZSY, LL)
 C := GET4 (S.CD, C, H3!A, LL.GLZ)
 H3!A := C
 RESULTIS C
 CASE S.GENSY:
 CASE S.NAME: $( LET N, G = Y1, E
 $( IF H3!G=A
 $( IF !G=S.E
 GSEQF := GSEQF | FVARU
 TEST N=Y1
 TEST CSTAC
 LL := LL.NA1F
 OR LL := LL.NA1
 OR TEST N=Y2
 TEST CSTAC
 LL := LL.NA2F
 OR LL := LL.NA2
 OR $( A := N
 TEST CSTAC
 LL := LL.NAF
 OR LL := LL.NA $)
 UNLESS CSTAC
 C := LOADN (C, N, 0)
 ENDCASE
 $)
 N, G := N+1, H1!G
 $) REPEATUNTIL G=Z
 MSGF (3, A, E)
 $)
 CASE S.TUPLE:
 $( LET T = REV (A)
 LET N, L = H3!A, LL.TUP
 TEST N=Y1
 $( TEST CSTAC
 L := LL.TUPA
 OR L := LL.1TUP
$)
 OR $( UNLESS CSTAC
 L := LL.TUPZ
 $( LET F0 = GET4 (S.MB, F, ZSY, Z)
 $( C := GET4 (S.CD, C, N, L)
 C := FLAT1 (H2!T, C, E, F0, FALSE)
 N, L, T := N-1, LL.TUP, H1!T $) REPEATUNTIL H1!T=Z $)
 L := LL.TUPA $)
  C := GET4 (S.CD, C, N, L)
 A, CSTAC := H2!T, FALSE
 LOOP
 $)
 CASE S.CLOS:
 CASE S.ACLOS:
 CASE S.CLOS2:
 CASE S.ECLOS:
 CASE S.FCLOS:
 IF CSTAC
 C := GET4 (S.CD, C, Z, LL.ST)
 A := FLATTEN (A)
 LL := LL.CLOSX
 ENDCASE
 CASE S.REC:
 CASE S.RECA: IF CSTAC
 C := GET4 (S.CD, C, Z, LL.ST)
 C := GET4 (S.CD, C, H3!A, LL.REC1)
 E := SIMENV (E, H2!A)
 C := FLAT1 (H1!A, C, E, F, FALSE)
 LL := LL.REC0
 A := H2!A
 ENDCASE
 CASE S.DASH: IF CSTAC
 C := GET4 (S.CD, C, Z, LL.ST)
 C := GET4 (S.CD, C, H2!A, LL.DASH)
 A, CSTAC := H1!A, FALSE
 LOOP
 CASE S.LET:
 CASE S.LETA:
 CASE S.LETB: IF CSTAC
 C := GET4 (S.CD, C, Z, LL.ST)
 C := GET4 (S.CD, C, Z, LL.RSC)     // ?L OK in seq
 $( LET G = SIMENV (E, H2!A)
 C := FLAT1 (H1!A, C, G, F, FALSE) $)
 TEST FBV (H2!A) & MATCHBV (H2!A, H3!A, FALSE)
 C := FLATBV (C, H2!A)
 OR C := GET4 (S.CD, C, H2!A, LL.BIND)
 C := GET4 (S.CD, C, Z, LL.SVC)
 A, CSTAC := H3!A, FALSE
 LOOP
 CASE S.APPLY:
 CASE S.APPLE:
 CASE S.AA1:
 CASE S.A1A:
 CASE S.AA2:
 CASE S.A2A:
 CASE S.AAA:
 CASE S.AEA:
 CASE S.APQ:
 CASE S.AQE: $( LET A1 = H1!A        // A1 is MB ?F
 IF TYV (A1)=A.QU
 $( LET L, V = LL.AP, H2!A1
 IF V<=0
 $( A := V
 LOOP $)
 SWITCHON !V INTO
 $(
 CASE S.UNSET:
 MSGF (7, A1)
 CASE S.CDZ: TEST C=ZC
 C, V, LL := H1!V, H2!V, LL.ENTZ
 OR TEST CSTAC
 LL := LL.APBK
 OR TEST F=Z
 LL := LL.APBC
 OR LL := LL.APBF
 C := GET4 (S.CD, C, V, LL)
 A, CSTAC := H2!A, FALSE
 LOOP
 CASE S.CDY: IF MATCHBV (H3!V, H2!A, FALSE)
 $( TEST C=ZC
 C, V, LL := H1!V, H2!V, LL.ENTY
 OR TEST CSTAC
 LL := LL.APCK
 OR TEST F=Z
 LL := LL.APCC
 OR LL := LL.APCF
 C := GET4 (S.CD, C, V, LL)
 A, CSTAC := H2!A, FALSE
 LOOP
 $)
 MSGF (0, 4)
 CASE S.CDX: L := LL.ENTX
 ENDCASE
 CASE S.ACLOS:
 L := LA.A1
 ENDCASE
 CASE S.CODE2:
 L := LA.APCODE2
 ENDCASE
 CASE S.CLOS2:
 CASE S.ECLOS:
 TEST MATCHBV (H2!V, H2!A, FALSE)
 L := LA.AE
 OR L := LL.APECLOS
 ENDCASE
 CASE S.FCLOS:
 L := LL.APFCLOS
 ENDCASE
 CASE S.LOC: L := LA.APLOC
 ENDCASE
 CASE S.TUPLE:
 L := LA.APTUP
 ENDCASE
 $)
 TEST C=ZC
 LL := LL.APKJ
 OR TEST CSTAC
 LL := LL.APKK
 OR TEST F=Z
 LL := LL.APKC
 OR LL := LL.APKF
 C := GET4 (S.CD, C, V, L)
 C := GET4 (S.CD, C, H3!A1, LL)
 H3!A1 := C
 A, CSTAC := H2!A, FALSE
 LOOP
 $)
 TEST C=ZC
 LL := LL.APNJ
 OR TEST CSTAC
 LL := LL.APNK
 OR TEST F=Z
 LL := LL.APNC
 OR LL := LL.APNF
 C := GET4 (S.CD, C, Z, LL)
 $( LET F0 = GET4 (S.MB, F, ZSY, Z)
 C := FLAT1 (H2!A, C, E, F0, FALSE) $)
 A, CSTAC := A1, TRUE
 LOOP
 $)
 CASE S.AP1:
 CASE S.A1E: IF CSTAC
 C := GET4 (S.CD, C, Z, LL.ST)
 C := GET4 (S.CD, C, H3!A, LL.AP1)
 A, CSTAC := H2!A, FALSE
 LOOP
 CASE S.APV:
 CASE S.AVE: IF CSTAC
 C := GET4 (S.CD, C, Z, LL.ST)
 $( LET A3 = H3!A
 TEST A3=HDV
 LL := LL.HDV
 OR TEST A3=TLV
 LL := LL.TLV
 OR TEST A3=MIV
 LL := LL.MIV
 OR TEST A3=ATOM
 LL := LL.ATOM
 OR TEST A3=NULL
 LL := LL.NULL
 OR LL := LL.APV
 C := GET4 (S.CD, C, A3, LL)
 A, CSTAC := H2!A, FALSE
 LOOP
 $)
 CASE S.AP2:
 CASE S.A2E: $( LET SWAP, A3 = FALSE, H3!A
 LET ARG1 = H2!A
 LET ARG2 = H2!(H1!ARG1)
 ARG1 := H2!ARG1
 IF EFSY (ARG1, -3)>EFSY (ARG2, -3)
 $( LET T = ARG1
 ARG1, ARG2 := ARG2, T
 SWAP := TRUE $)
 TEST A3=AUG
 $( A3 := Z
 TEST CSTAC
 TEST SWAP
 LL := LL.XCONSF
 OR LL := LL.CONSF
 OR TEST SWAP
 LL := LL.XCONS
 OR LL := LL.CONS $)
 OR TEST CSTAC
 TEST SWAP
 LL := LL.AP2SF
 OR LL := LL.AP2F
 OR TEST SWAP
 LL := LL.AP2S
 OR LL := LL.AP2
 C := GET4 (S.CD, C, A3, LL)
 $( LET F0 = GET4 (S.MB, F, ZSY, Z)
 C := FLAT1 (ARG1, C, E, F0, FALSE) $)
 A, CSTAC := ARG2, TRUE
 LOOP
 $)
 CASE S.E: LL := LL.E
 IF FALSE
 CASE S.J:   LL := LL.J
 IF CSTAC
 C := GET4 (S.CD, C, Z, LL.ST)
 A := Z
 ENDCASE
 CASE S.COND:
 CASE S.CONDA:
 CASE S.CONDB:
 $( LET N = GET4 (!A, H1!A, H2!A, H3!A)
 LET C0 = GET4 (S.CD, ZSY, ZSY, LL.COND)
 !A, H1!A, H2!A, H3!A := S.MB, !GSEQF, N, GET4 (S.MB, C0, C, F)
 !GSEQF := A
 H2!C0 := FLAT1 (H2!N, C, E, F, CSTAC)
 H1!C0 := FLAT1 (H3!N, C, E, F, CSTAC)
 A, C, CSTAC := H1!N, C0, FALSE
 LOOP $)
 CASE S.SEQ:
 CASE S.SEQA: C := FLAT1 (H2!A, C, E, F, CSTAC)
 A, CSTAC := H1!A, FALSE
 LOOP
 CASE S.MB: $( LET A3 = H3!A
 A := H2!A
 IF H2!A3=C
 $( UNLESS H3!A3=F
 MSGF (0, 2)
 C, A, CSTAC := H1!A3, H1!A, FALSE $)
 LOOP $)
 $)
 OR TEST CSTAC
 LL := LL.CYF
 OR LL := LL.CY
 RESULTIS GET4 (S.CD, C, A, LL)
 $) REPEAT
 $)
 
 
AND LOADN (C, N, M) = VALOF
 $( IF C=Z | M<-3
 RESULTIS C
 IF N=Y1 & H3!C=LL.NA1 | N=Y2 & H3!C=LL.NA2 | N=H2!C & H3!C=LL.NA
 RESULTIS LOADN (H1!C, N, M)
 IF N=Y1 & H3!C=LL.NA1F | N=Y2 & H3!C=LL.NA2F | N=H2!C & H3!C=LL.NAF
 $( C := LOADN (H1!C, N, M)
 RESULTIS GET4 (S.CD, C, Z, LL.ST) $)
 IF (H3!C & SVA)=0
 RESULTIS C
 IF H3!C=LL.COND
 $( LET T1 = LOADN (H1!C, N, M)
 LET T2 = LOADN (H2!C, N, M)
 IF T1=H1!C & T2=H2!C
 RESULTIS C
 RESULTIS GET4 (S.CD, T1, T2, LL.COND) $)
 $( LET T1 = LOADN (H1!C, N, M-1)
 IF T1=H1!C
 RESULTIS C
 RESULTIS GET4 (S.CD, T1, H2!C, H3!C) $)
 $)
 
 
AND FBV (B) = VALOF
 $( IF B>0
 SWITCHON !B INTO
 $(
 CASE S.LOC: B := H1!B
 LOOP
 CASE S.TUPLE:
 $( UNLESS FBV (H2!B)
 RESULTIS FALSE
 B := H1!B $) REPEATUNTIL B=Z
 RESULTIS TRUE
 CASE S.QU: RESULTIS FALSE $)
 RESULTIS TRUE
 $) REPEAT
 
 
AND FLATBV (C, B) = VALOF
 $( IF @B>STACKL
 STKOVER ()
 $( IF B>0
 SWITCHON !B INTO
 $(
 CASE S.LOC: B := H1!B
 LOOP
 CASE S.TUPLE:
 B := REV (B)
 IF SIMTUP (B)
 $( C := LOADN (C, Y1, 0)
 LL := LL.BVEZ
 L1:                       $( C := GET4 (S.CD, C, H2!B, LL)
 LL := LL.BVE
 B := H1!B $) REPEATUNTIL B=Z
 RESULTIS C $)
 C := FLATBV (C, H2!B)
 B := H1!B
 IF B=Z | SIMTUP (B)
 $( C := GET4 (S.CD, C, Z, LL.BVF1)
 UNLESS B=Z
 $( LL := LL.BVE
 GOTO L1 $)
 RESULTIS C $)
 C := GET4 (S.CD, C, Z, LL.BVFZ)
 UNTIL H1!B=Z
 $( LET B2 = H2!B
 TEST SIMNAME (B2)
 C := GET4 (S.CD, C, B2, LL.BVFE)
 OR $( C := FLATBV (C, B2)
 C := GET4 (S.CD, C, Z, LL.BVF) $)
 B := H1!B $)
 C := FLATBV (C, H2!B)
 RESULTIS GET4 (S.CD, C, Z, LL.BVFA)
 CASE S.AA: LL := LL.LV
 GOTO L0
 CASE S.ZZ: LL := LL.RV
 L0:                 C := LOADN (C, Y1, 0)
 RESULTIS GET4 (S.CD, C, H2!B, LL)
 CASE S.GENSY:
 CASE S.NAME:
 CASE S.DASH: C := LOADN (C, Y1, 0)
 RESULTIS GET4 (S.CD, C, B, LL.BINDE)
 $)
 UNLESS B=Z
 MSGF (6, B)
 RESULTIS C
 $) REPEAT
 $)
 
 
AND SIMENV (E, V) = VALOF
 $( IF V>0
 SWITCHON !V INTO
 $(
 CASE S.LOC: V := H1!V
 LOOP
 CASE S.TUPLE:
 $( E := SIMENV (E, H2!V)
 V := H1!V $) REPEATUNTIL V=Z
 RESULTIS E
 CASE S.QU:
 CASE S.AA:
 CASE S.ZZ: V := H2!V
 LOOP
 CASE S.GENSY:
 CASE S.NAME:
 CASE S.DASH: RESULTIS GET4 (S.MB, E, ZSY, V)
 $)
 UNLESS V=Z
 MSGF (6, V)
 RESULTIS E
 $) REPEAT
 
 
AND FIXAPF (V, L) BE
 UNTIL L=Z
 $( LET L2, L3 = H2!L, H3!L
 TEST L3=LL.GLZ
 $( LET L1 = H1!L
 H1!L, H2!L, H3!L := H1!L1, V, H3!L1 $)
 OR TEST !V=S.CDZ
 $( TEST L3=LL.APKJ
 $( H1!L, H2!L, H3!L := H1!V, H2!V, LL.ENTZ
 L := L2
 LOOP $)
 OR TEST L3=LL.APKK
 LL := LL.APBK
 OR TEST L3=LL.APKC
 LL := LL.APBC
 OR TEST L3=LL.APKF
 LL := LL.APBF
 OR MSGF (0, 3)
 H1!L, H2!L, H3!L := H1!(H1!L), V, LL
 $)
 OR $( TEST L3=LL.APKJ
 $( H1!L, H2!L, H3!L := H1!V, H2!V, LL.ENTY
 L := L2
 LOOP $)
 OR TEST L3=LL.APKK
 LL := LL.APCK
 OR TEST L3=LL.APKC
 LL := LL.APCC
 OR TEST L3=LL.APKF
 LL := LL.APCF
 OR MSGF (0, 3)
 H1!L, H2!L, H3!L := H1!(H1!L), V, LL
 $)
 L := L2
 $)
 
 
.
//./       ADD LIST=ALL,NAME=J
 SECTION "J"
 
 
GET "PALHDR"
 
 
LET KEEP1 (K, F) = VALOF        // F~=Z
 $( LET T = H1!F
 IF T<YFJ
 $( IF T=Z
 $( T := !F
 IF T>=S.MZ
 !F := T-JGAP $)
 RESULTIS KEEP2 (K) $)
 F := T $) REPEAT
 
 
AND KEEP2 (K) = VALOF   // K=J
 $( UNTIL K<YFJ
 $( TEST !K>=S.MZ
 !K := !K-JGAP
 OR BREAK
 H3!K := KEEP3 (H3!K)
 $( LET K2 = H2!K
 IF K2=Z
 BREAK
 H2!K := K2 & P.ADDR
 K := K2 $) $)
 RESULTIS J & P.ADDR
 $)
 
 
AND KEEP3 (F) = VALOF   // F~=Z
 $( LET G = F
 WHILE !G>=S.MZ    // not CD
 $( !G := !G-JGAP
 $( LET G1 = H1!G
 IF G1<YFJ
 BREAK
 H1!G := G1 & P.ADDR
 G := G1 $) $)
 RESULTIS F & P.ADDR $)
 
 
AND APPLY (C1, C2) = VALOF
 $( ARG1, C2 := C2, Z
 $( LET P1, P2, P3 = -M, E, J
 J, M := ZJ, S.J
 IF @C1>STACKL
 STKOVER ()
 (-3)!(@C1) := EVAL
 IV ()
 GOTO LL.AP $) $)
 
 
AND ERROREVAL (S) = VALOF
 $( LET L1, L2 = -ERLEV, -ERLAB
 LET Q1, Q2 = -Q.INPUT, -Q.OUTPUT
 LET P1, P2, P3 = -M, E, J
 ERLEV, ERLAB := LEVEL (), L
 S := EVAL (S)
 ERLEV, ERLAB := -L1, -L2
 RESULTIS S
 L: ERLEV, ERLAB := -L1, -L2
 M, E, J := -P1, P2, P3
 Q.SELINPUT (-Q1)
 Q.SELOUTPUT (-Q2)
 UNLESS OKPAL
 MSG1 (1)
 WRITEF ("*N# Erroreval failed on: %E*N", PRINTA, S)
 RESULTIS Z
 $)
 
 
.
//./       ADD LIST=ALL,NAME=LONGA
 SECTION "LONGA"
 
 
GET "PALHDR"
 
 
MANIFEST
 $( NUMBB = NUMBA-1 $)
 
 
STATIC
 $( SG = 0
 CY = 0
 GL1 = 0
 GL2 = 0
 GL3 = 0 $)
 
// Some of these routines may not be happy about long integers that
// are actually only one word long
 
 
LET LONGCMP (A, B) = VALOF      // A>B -> 1  ...
 $( LET F = 0
 $( TEST H3!A>H3!B
 F := 1
 OR UNLESS H3!A=H3!B
 F := -1
 TEST H2!A>H2!B
 F := 1
 OR UNLESS H2!A=H2!B
 F := -1
 A, B := H1!A, H1!B
 IF A=B
 RESULTIS F
 IF A=Z
 RESULTIS -1
 IF B=Z
 RESULTIS 1
 $) REPEAT
 $)
 
 
AND SADD (N) = VALOF
 $( IF ABS N<NUMBA
 RESULTIS N+Y0
 TEST N<0
 N, SG := -N, YSG
 OR SG := 0
 RESULTIS GETX (S.NUMJ, Z, 1, N-NUMBA)+SG $)
 
 
AND LONGADD (A, B) = VALOF
 $( LET C, C0 = Z, @B | SIGNBIT       // ??B?? C0=@C-1
 SG, CY := A & YSG, 0
 $( GW1 := H3!A+H3!B+CY
 TEST GW1>=NUMBA
 $( GW1 := GW1-NUMBA
 CY := 1 $)
 OR CY := 0
 GW2 := H2!A+H2!B+CY
 TEST GW2>=NUMBA
 $( GW2 := GW2-NUMBA
 CY := 1 $)
 OR CY := 0
 A, B := H1!A, H1!B
 H1!C0 := GETX (S.NUMJ, ZSY, GW2, GW1)
 C0 := H1!C0
 IF A=Z
 $( H1!C0 := B
 IF CY=0
 RESULTIS C+SG
 A := B
 GOTO L $)
 $) REPEATUNTIL B=Z
 IF CY=0
 H1!C0 := A <> RESULTIS C+SG
 $( GW1 := H3!A+1
 UNLESS GW1=NUMBA
 $( GW2 := H2!A
 BREAK $)
 GW2 := H2!A+1
 UNLESS GW2=NUMBA
 $( GW1 := 0
 BREAK $)
 A := H1!A
 H1!C0 := GETX (S.NUMJ, ZSY, 0, 0)
 C0 := H1!C0
 L:    IF A=Z
 $( H1!C0 := GETX (S.NUMJ, Z, 0, 1)
 RESULTIS C+SG $)
 $) REPEAT
 H1!C0 := GETX (S.NUMJ, H1!A, GW2, GW1)
 RESULTIS C+SG
 $)
 
 
AND LONGSUB (A, B) = VALOF      // |A| > |B|
 $( LET C = ZSY
 SG, CY := A & YSG, 0
 $( GW1 := H3!A-H3!B-CY
 TEST GW1<0
 $( GW1 := GW1+NUMBA
 CY := 1 $)
 OR CY := 0
 GW2 := H2!A-H2!B-CY
 TEST GW2<0
 $( GW2 := GW2+NUMBA
 CY := 1 $)
 OR CY := 0
 A, B := H1!A, H1!B
 C := GETX (S.NUMJ, C, GW2, GW1)
 $) REPEATUNTIL B=Z
 $( LET S = A
 TEST CY~=0     // -> A ~= Z
 $( LET S0 = @C | SIGNBIT    // ??B?? S0=@S-1
 $( UNLESS H3!A=0
 $( GW1 := H3!A-1
 GW2 := H2!A
 BREAK $)
 UNLESS H2!A=0
 $( GW2 := H2!A-1
 GW1 := NUMBB
 GOTO L1 $)
 A := H1!A
 H1!S0 := GETX (S.NUMJ, ZSY, NUMBB, NUMBB)
 S0 := H1!S0
 $) REPEAT        // A ~= Z
 TEST GW1=0=GW2 & H1!A=Z
 TEST S=A
 $( S := Z
 GOTO L2 $)
 OR H1!S0 := Z
 OR
 L1:   H1!S0 := GETX (S.NUMJ, H1!A, GW2, GW1)
 $)
 OR IF A=Z
 $(
 L2:      WHILE H2!C=0     // here S=Z
 $( IF H3!C=0
 $( C := H1!C    // nb will not overshoot since A ~= B
 LOOP $)
 IF H1!C=ZSY
 TEST SG=0
 RESULTIS H3!C+Y0
 OR RESULTIS Y0-H3!C
 BREAK $)
 $)
 $( LET T = H1!C
 H1!C := S
 IF T=ZSY
 RESULTIS C+SG
 S, C := C, T $) REPEAT
 $)
 $)
 
 
// -NUMBA < N-Y0 < NUMBA
 
 
AND LONGAS1 (A, N, F) = VALOF   // F -> ADD1,SUB1
 $( SG := A & YSG
 TEST N<=Y0
 $( IF N=Y0
 RESULTIS A
 GW1 := Y0-N
 IF F NEQV SG>0
 GOTO L $)
 OR $( GW1 := N-Y0
 IF F NEQV SG=0
 GOTO L $)
 GW1 := H3!A+GW1
 UNLESS GW1>=NUMBA
 RESULTIS GETX (S.NUMJ, H1!A, H2!A, GW1)+SG
 GW1 := GW1-NUMBA
 GW2 := H2!A+1
 UNLESS GW2=NUMBA
 RESULTIS GETX (S.NUMJ, H1!A, GW2, GW1)+SG
 A := H1!A
 $( LET C = GETX (S.NUMJ, ZSY, 0, GW1)
 LET C0 = C
 $( GW1 := H3!A+1
 UNLESS GW1=NUMBA
 $( GW2 := H2!A
 BREAK $)
 GW2 := H2!A+1
 UNLESS GW2=NUMBA
 $( GW1 := 0
 BREAK $)
 A := H1!A
 H1!C0 := GETX (S.NUMJ, ZSY, 0, 0)
 C0 := H1!C0
 IF A=Z
 $( H1!C0 := GETX (S.NUMJ, Z, 0, 1)
 RESULTIS C+SG $)
 $) REPEAT
 H1!C0 := GETX (S.NUMJ, H1!A, GW2, GW1)
 RESULTIS C+SG
 $)
 L:   GW1 := H3!A-GW1
 UNLESS GW1<=0
 RESULTIS GETX (S.NUMJ, H1!A, H2!A, GW1)+SG
 GW1 := GW1+NUMBA
 GW2 := H2!A-1
 A := H1!A
 UNLESS GW2<0
 $( IF GW2=0 & A=Z
 TEST SG=0
 RESULTIS GW1+Y0
 OR RESULTIS Y0-GW1
 RESULTIS GETX (S.NUMJ, A, GW2, GW1)+SG $)
 $( LET C = GETX (S.NUMJ, ZSY, NUMBB, GW1)
 LET C0 = C
 $( UNLESS H3!A=0
 $( GW1 := H3!A-1
 GW2 := H2!A
 BREAK $)
 UNLESS H2!A=0
 $( GW2 := H2!A-1
 GW1 := NUMBB
 BREAK $)
 A := H1!A
 H1!C0 := GETX (S.NUMJ, ZSY, NUMBB, NUMBB)
 C0 := H1!C0
 $) REPEAT      // A~=Z
 TEST GW2=0=GW1 & H1!A=Z
 H1!C0 := Z
 OR H1!C0 := GETX (S.NUMJ, H1!A, GW2, GW1)
 RESULTIS C+SG
 $)
 $)
 
 
AND SMUL (A, B) = VALOF
 $( LET C = MULDIV (A-Y0, B-Y0, NUMBA)
 IF C=0
 RESULTIS RESULT2+Y0
 TEST RESULT2<0
 RESULT2, C, SG := -RESULT2, -C, YSG
 OR SG := 0
 RESULTIS GETX (S.NUMJ, Z, C, RESULT2)+SG $)
 
 
// -NUMBA < N-Y0 < NUMBA
 
 
AND LONGMUL1 (A, N) = VALOF
 $( LET N0 = @A | SIGNBIT     // ??B?? N0=@N-1
 GL1, N := N-Y0, Z
 TEST GL1>1
 SG := A & YSG
 OR TEST GL1<-1
 GL1, SG := -GL1, (A & YSG) NEQV YSG
 OR TEST GL1=0
 RESULTIS Y0
 OR TEST GL1=1
 RESULTIS A
 OR RESULTIS A NEQV YSG
 GL2 := 0
 $( $( LET T = MULDIV (H3!A, GL1, NUMBA)
 GW3 := GL2+RESULT2
 IF GW3>=NUMBA
 $( GW3 := GW3-NUMBA
 T := T+1 $)
 GL2 := MULDIV (H2!A, GL1, NUMBA)
 GW2 := T+RESULT2
 IF GW2>=NUMBA
 $( GW2 := GW2-NUMBA
 GL2 := GL2+1 $)
 $)
 A := H1!A
 H1!N0 := GETX (S.NUMJ, ZSY, GW2, GW3)
 N0 := H1!N0
 $) REPEATUNTIL A=Z
 TEST GL2=0
 H1!N0 := Z
 OR H1!N0 := GETX (S.NUMJ, Z, 0, GL2)
 RESULTIS N+SG
 $)
 
 
AND LONGMUL (A, B) = VALOF
 $( LET C = GETX (S.NUMJ, ZSY, 0, 0)+((A NEQV B) & YSG)
 LET CC = C
 
 $( LET A1, B1 = H1!A, B
 UNTIL A1=Z
 $( C := GETX (S.NUMJ, C, 0, 0)
 A1 := H1!A1 $)
 $( C := GETX (S.NUMJ, C, 0, 0)
 B1 := H1!B1 $) REPEATUNTIL B1=Z $)
 
 $( LET C0 = C
 $( LET B1, C1 = B, C0
 GL1, GL3 := 0, H3!A
 $( GW3 := H3!C1+GL1
 GW2 := H2!C1+MULDIV (GL3, H3!B1, NUMBA)
 IF GW3>=NUMBA
 $( GW3 := GW3-NUMBA
 GW2 := GW2+1 $)
 GW3 := GW3+RESULT2
 IF GW3>=NUMBA
 $( GW3 := GW3-NUMBA
 GW2 := GW2+1 $)
 H3!C1 := GW3
 GL1 := MULDIV (GL3, H2!B1, NUMBA)
 IF GW2>=NUMBA
 $( GW2 := GW2-NUMBA
 GL1 := GL1+1 $)
 GW2 := GW2+RESULT2
 IF GW2>=NUMBA
 $( GW2 := GW2-NUMBA
 GL1 := GL1+1 $)
 H2!C1 := GW2
 B1, C1 := H1!B1, H1!C1
 $) REPEATUNTIL B1=Z
 H3!C1 := GL1
 GL3, A := H2!A, H1!A
 IF GL3=0
 $( IF A=Z
 BREAK
 C0 := H1!C0
 LOOP $)
 B1, C1 := B, C0
 GW2 := H2!C1
 $( GL1 := MULDIV (GL3, H3!B1, NUMBA)
 IF GW2>=NUMBA
 $( GW2 := GW2-NUMBA
 GL1 := GL1+1 $)
 GW2 := GW2+RESULT2
 IF GW2>=NUMBA
 $( GW2 := GW2-NUMBA
 GL1 := GL1+1 $)
 H2!C1 := GW2
 C1 := H1!C1
 GW3 := H3!C1+GL1
 GW2 := H2!C1+MULDIV (GL3, H2!B1, NUMBA)
 IF GW3>=NUMBA
 $( GW3 := GW3-NUMBA
 GW2 := GW2+1 $)
 GW3 := GW3+RESULT2
 IF GW3>=NUMBA
 $( GW3 := GW3-NUMBA
 GW2 := GW2+1 $)
 H3!C1 := GW3
 B1 := H1!B1
 $) REPEATUNTIL B1=Z
 H2!C1 := GW2
 C0 := H1!C0
 $) REPEATUNTIL A=Z
 TEST H2!CC=0=H3!CC
// here, if C0 already = CC, then H3!CC ~= 0 (???)
 $( UNTIL H1!C0=CC
 C0 := H1!C0
 H1!C0 := Z $)
 OR H1!CC := Z
 $)
 RESULTIS C
 $)
 
 
// 0<=A<C;  RESULT2 := remainder
 
 
AND SDIV (A, B, C) = VALOF
 $( LET T1 = MULDIV (A, NUMBA, C)
 LET T2 = B/C
 RESULT2 := RESULT2+B REM C
 IF RESULT2>=C
 $( RESULT2 := RESULT2-C
 T2 := T2+1 $)
 RESULTIS T1+T2 $)
 
 
// -NUMBA < N-Y0 < NUMBA
 
 
AND LONGDIV1 (A, N) = VALOF
// could try IF H1!A=Z ...
 $( GL1, N := N-Y0, ZSY
 TEST GL1>1
 SG := A & YSG
 OR TEST GL1<-1
 GL1, SG := -GL1, (A & YSG) NEQV YSG
 OR TEST GL1=0
 MSG1 (7) <> RESULTIS Z
 OR $( RESULT2 := 0
 TEST GL1=1
 RESULTIS A
 OR RESULTIS A NEQV YSG $)
 $( N := GETX (S.NUMJ, N, H2!A, H3!A)
 A := H1!A $) REPEATUNTIL A=Z
 A := N
 UNLESS H2!N=0
 $( RESULT2 := H2!N REM GL1
 H2!N := H2!N/GL1
 GOTO L $)
 RESULT2 := H3!N REM GL1
 H3!N := H3!N/GL1
 IF H3!N=0
 A := H1!A
 N := H1!N // H2!N=0 -> H1!N ~= ZSY
 $( H2!N := SDIV (RESULT2, H2!N, GL1)
 L:      H3!N := SDIV (RESULT2, H3!N, GL1)
 N := H1!N $) REPEATUNTIL N=ZSY
 IF SG>0
 RESULT2 := -RESULT2
 IF H1!A=ZSY & H2!A=0
 TEST SG=0
 RESULTIS H3!A+Y0
 OR RESULTIS Y0-H3!A
 $( LET B = Z      // Unreverse A
 $( LET T = H1!A
 H1!A := B
 IF T=ZSY
 RESULTIS A+SG
 B, A := A, T $) REPEAT $)
 $)
 
 
AND LONGDIV (A, B) = MSG1 (26, "longdiv")
 
 
AND LGCD (A, B) = MSG1 (26, "LGCD")
 
 
.
//./       ADD LIST=ALL,NAME=MARK
 SECTION "MARK"
 
 
GET "PALHDR"
 
 
STATIC
 $( GC1 = 0
 W = 0 $)
 
 
LET GPFN (F) BE
 IF VALIDCODE (!F>>2)
 !F := !F | SIGNBIT
 
 
// NB THROWS AT LEAST ONCE
// Throwable chains end up at ZSY
 
 
AND THROW (AA) BE
 $( LET A = !AA
 !AA := Z  // Unset the handle
 !A := STACKP
 $( LET T = H1!A
 CONS := CONS+4
 IF T=ZSY
 $( STACKP := A
 RETURN $)
 !T, A := A, T $) REPEAT $)
 
 
AND CLOCK (B) BE
 $( STATIC
 $( TIMING = FALSE
 T = 0 $)
 IF B=TIMING
 RETURN
 TIMING := ~TIMING
 TEST B
 RTIME := RTIME+TIME ()-T
 OR T := TIME () $)
 
 
AND TEMPUSP (S, F) BE
 $( SELECTOUTPUT (SYSOUT)
 WRITEF ("%M# %S after %V+%V s", S, TIME ()-RTIME, RTIME)
 UNLESS F=0
 F ()
 NEWLINE ()
 SELECTOUTPUT (Q.OUTPUT) $)
 
 
AND TT (A) BE
 $( STATIC
 $( STX = 0 $)
 TAB (26)
 WRITEF ("%N%% heap used", (SSZ-W-(ST1-@A))*100/SSZ)
 IF PARAMK
 $( WRITEF ("   %N cycles; %N cons", CYCLES-Y0, CONS-Y0)
 UNLESS STX=ST1
 $( STX := ST1
 TAB (68)
 WRITEF ("BCPL/gap/PAL %N/%N/%N words",
 @A-STACKBASE, ST1-@A, ST2-ST1) $) $)
 $)
 
 
AND SQUAS () BE
 $( LET N = SQUASH ()
 IF N=0 & W<KWORDS
 MSG1 (39)
 TEST N<5
 KSQ := KSQ/2
 OR IF N>10
 KSQ := (KSQ*3)/2 $)
 
 
AND STKOVER () BE       // Try recrem
 STACK (KSTACK)
 
 
AND STACK (N) BE
 $( N := N+(@N+FR.S) & ~3
 IF N<=ST1
 $( IF N>=@N+FR.S
 $( LET T = STACKP
 ST1 := ST1-4
 STACKP := ST1
 UNTIL ST1<=N
 $( ST1 := ST1-4
 4!ST1 := ST1
 CONS := CONS+4 $)
 !ST1 := T
 STACKL := ST1-FR.S
 RETURN
 $)
 MSG1 (16, STACK, N)
 $)
 CLOCK (FALSE)
 OKPAL := FALSE
 
// N>ST1;  Shovel heap up past N
 
 L0:  FOR I=SVV TO ST2 BY 4
 !I := -!I
 FOR I=@E TO @ERZ
 IF !I>0
 MARKA (!I)
 $( LET Q1 = @N-3
 $( LET Q = 1!Q1>>2
 IF Q<=STACKBASE
 BREAK
 IF !Q<0
 FOR I=Q+3 TO Q1-1
 IF !I>0
 MARKA (!I)
 Q1 := Q $) REPEAT $)
 
 FOR I=SVV TO ST2 BY 4
 !I := -!I
 STACKP, W, GC1 := 0, 0, ST1
 $( LET P = N
 IF P>=SVU
 MSG1 (38)
 $( UNTIL !P>0  // note that this loop precedes the next
 $( !P := -!P
 P := P+4 $)
 UNTIL !ST1<=0
 $( IF ST1>=N
 GOTO L1
 ST1 := ST1+4 $)
 IF P>SVU
 $( FOR I=ST1 TO N-4 BY 4
 !I := ABS (!I)
 SCANP (INDIR)
 IF SQUASH ()=0
 MSG1 (39)
 GOTO L0 $)
 !P, H1!P, H2!P, H3!P := -!ST1, H1!ST1, H2!ST1, H3!ST1
 !ST1 := P
 P := P+4
 ST1 := ST1+4
 $) REPEAT
 L1: FOR I=P TO SVU BY 4
 TEST !I<=0
 !I := -!I
 OR !I, STACKP, W := STACKP, I, W+4
 $)
 SCANP (INDIR)
 CONS := CONS+W
 OKPAL := TRUE
 CLOCK (TRUE)
 IF PARAMV
 TEMPUSP ("GC1", TT)
 IF PARAMD // ?D
 VERIFY ()      // ?D
 IF W<KSQ
 SQUAS ()
 $)
 
 
AND GET4 (A, B, C, D) = VALOF
 $( IF STACKP=0
 $( A := -A
 REC0 ()
 A := -A $)
 $( LET P = STACKP
 STACKP, !P, 1!P, 2!P, 3!P := !STACKP, A, B, C, D
 RESULTIS P $) $)
 
 
AND GETX (A, B, C, D) = VALOF
 $( IF STACKP=0
 $( STATIC      // may not be nec
 $( CC = 0
 DD = 0 $)
 CC, DD := C, D
 A, C, D := -A, 0, 0
 REC0 ()
 A, C, D := -A, CC, DD $)
 $( LET P = STACKP
 STACKP, !P, 1!P, 2!P, 3!P := !STACKP, A, B, C, D
 RESULTIS P $)
 $)
 
 
AND REC0 () BE
 $( $( LET T = 0
 IF ST1-@T>2*KSTACK
 $( STACK (KSTACK)
 RETURN $) $)
 CLOCK (FALSE)
 OKPAL := FALSE
 
 FOR I=SVV TO ST2 BY 4
 !I := -!I
 FOR I=@E TO @ERZ
 IF !I>0
 MARKA (!I)
 $( LET Q1 = @Q1-3
 $( LET Q = 1!Q1>>2
 IF Q<=STACKBASE
 BREAK
 IF !Q<0
 FOR I=Q+3 TO Q1-1
 IF !I>0
 MARKA (!I)
 Q1 := Q $) REPEAT $)
 
 FOR I=SVV TO ST2 BY 4
 !I := -!I
 W := 0
 FOR P=ST1 TO SVU BY 4
 TEST !P<=0
 !P := -!P
 OR !P, STACKP, W := STACKP, P, W+4
 CONS := CONS+W
 
 OKPAL := TRUE
 CLOCK (TRUE)
 IF PARAMV
 TEMPUSP ("GC", TT)
 UNLESS TRZ=Z
 IF CONS>H3!TRZ
 DOTRAP ()
 IF W<KSQ
 SQUAS ()
 $)
 
 
AND INDIR (P) BE
 $( LET Q = !P
 IF Q>0
 $( LET R = Q & P.ADDR
 IF GC1<=R<ST1
 !P := !R+(Q & P.TAG) $) $)
 
 
AND SCANP (F) BE
 $( FOR I=ST1 TO ST2 BY 4
 $( IF !I>=MM3
 F (I+3) <> F (I+2)
 F (I+1) $)
 FOR I=@E TO @A.NULL
 F (I)
 FOR I=TYP TO TYP+TYPSZ
 F (I)
 SCANST (F) $)
 
 
AND SCANST (F) BE
 $( LET Q1 = (-2)!(@F)>>2
 $( LET Q = 1!Q1>>2
 IF Q<=STACKBASE
 RETURN
 IF !Q<0
 FOR I=Q+3 TO Q1-1
 F (I)
 Q1 := Q $) REPEAT $)
 
 
AND FLEVEL (F) = VALOF
 $( LET Q = (-2)!(@F)>>2
 $( Q := 1!Q>>2
 IF !Q=F
 RESULTIS Q<<2 $) REPEATUNTIL Q<=STACKBASE
 MSG1 (32, F) $)
 
 
 
 
// This one stores (+ve) reverse link in ptr word, having marked hdr word
 
 
LET MARKA (P) BE
 $( $( LET U = !P
 IF U<=0
 RETURN
 IF U<MM3
 $( $( !P := -U
 P := H1!P
 IF P<=0
 RETURN
 U := !P $) REPEATWHILE U>0
 RETURN $)
 !P := -U
 $)
 $( LET K, N, Q, T = @P+FR.GC, 3, 0, 0
 (FR.GC-1)!(@P) := 0
 $( $(P IF N=0
 $( K := K-1
 P := !K-1
 IF P<0
 RETURN
 N, P := P & 3, P-N $)      // assert: N~=0
 T := N!P
 IF T<=0
 $( N := N-1
 LOOP $)
 L1:      $( LET U = !T
 IF U<=0
 $( N := N-1
 LOOP $)
 IF U<MM3
 $( $( !T := -U
 T := H1!T
 IF T<=0
 BREAK
 U := !T $) REPEATWHILE U>0
 N := N-1
 LOOP $)
 !T := -U
 $( LET NN = H3!T>0 -> 3, H2!T>0 -> 2, H1!T>0 -> 1, 0
 IF NN=0
 $( N := N-1
 LOOP $)
 UNLESS N=1
 $( IF K>=ST1
 $( N!P := Q
 Q := P+N
 P, N := T, NN
 T := N!P
 GOTO L2 $)
 !K := P+N
 K := K+1 $)
 P, N := T, NN
 T := N!P
 GOTO L1
 $)P REPEAT
 $(P IF N=0
 $( IF Q=0
 BREAK
 $( LET T = !Q
 !Q := P
 P := Q-1
 N, P := P & 3, P-N
 Q := T $)
 LOOP $)
 T := N!P
 IF T<=0
 $( N := N-1
 LOOP $)
 L2:      $( LET U = !T
 IF U<=0
 $( N := N-1
 LOOP $)
 IF U<MM3
 $( $( !T := -U
 T := H1!T
 IF T<=0
 BREAK
 U := !T $) REPEATWHILE U>0
 N := N-1
 LOOP $)
 !T := -U
 $( LET NN = H3!T>0 -> 3, H2!T>0 -> 2, H1!T>0 -> 1, 0
 IF NN=0
 $( N := N-1
 LOOP $)
 N!P := Q
 Q := P+N
 P, N := T, NN
 T := N!P
 GOTO L2
 $)P REPEAT
 $) REPEAT
 $)
 $)
 
 
 
 
// This one stores (-ve) reverse link in hdr word, and stores (+ve) hdr
// in ptr word
 
// P,Q ARE SAME TYPE, COMPOSITE; AND P ~= Q
 
 
AND EQL (P, Q) = VALOF
 $( LET B, M, N = TRUE, P, 3
 OKPAL := FALSE
 !P, !Q := -!P, -!Q
 GOTO L
 
 $(1 UNLESS B & N~=0
 $( LET S, T = -!P, -!Q
 IF P=M
 $( !P, !Q := S, T
 OKPAL := TRUE
 RESULTIS B $)
 !P, !Q := !S, !T
 !T := Q
 TEST B
 !S := Q
 OR !S := P
 N := S & 3
 P, Q, N := S-N, T-N, N-1
 LOOP
 $)
 L:    $( LET U, V = N!P, N!Q
 IF U=V
 $( N := N-1
 LOOP $)
 IF U<=0 | V<=0
 $( B := FALSE
 LOOP $)
 $( LET S, T = !U, !V
// IF S=T<0 GIVE UP FOR NOW
 UNLESS S=T & S>=0
 $( B := FALSE
 LOOP $)
 SWITCHON S INTO
 $(
 CASE S.GENSY:
 CASE S.NAME:
 CASE S.GLZ:
 CASE S.GLG:
 CASE S.GLO:
 CASE S.LOC:
 CASE S.XTUPL:
 CASE S.UNSET:
 CASE S.UNSET1:
 CASE S.TRA: B := FALSE   // since U~=V
 LOOP
 CASE S.FLT: UNLESS H2!U #= H2!V
 B := FALSE <> LOOP
 ENDCASE
 CASE S.FPL: MSG1 (14)
 CASE S.RATN: UNLESS H1!U=H1!V
 B := FALSE <> LOOP
 CASE S.RDS:
 CASE S.WRS:
 CASE S.BCPLF:
 CASE S.BCPLR:
 CASE S.BCPLV:
 CASE S.CODEV:
 CASE S.CODE0:
 CASE S.CODE1:
 CASE S.CODE2:
 CASE S.CODE3:
 CASE S.CODE4:
 UNLESS H2!U=H2!V
 B := FALSE <> LOOP
 ENDCASE
 CASE S.NUMJ: IF (U NEQV V)<YSG
 CASE S.STRING: $( UNLESS H2!U=H2!V & H3!U=H3!V
 BREAK
 U, V := H1!U, H1!V
 IF U=V
 ENDCASE $) REPEATUNTIL U=Z | V=Z
 B := FALSE
 LOOP
 CASE S.POLY: IF H3!U=H3!V
 $( LET F = U NEQV V
 $( U, V := H1!U, H1!V
 IF U=V
 TEST U=Z
 ENDCASE
 OR TEST F<YSG
 ENDCASE
 OR BREAK
 IF U=Z | V=Z
 BREAK
 UNLESS H3!U=H3!V
 BREAK
 F := F NEQV (U NEQV V)
 $) REPEATWHILE EQPOLY (H2!U, H2!V, F<YSG)
 $)
 B := FALSE
 LOOP
 DEFAULT: !U, !V := -P-N, -Q-N
 N!P, N!Q := S, T
 P, Q, N := U, V, 3
 LOOP
 $)
 N := N-1
 $)1 REPEAT
 $)
 
 
.
//./       ADD LIST=ALL,NAME=MUL
 SECTION "MUL"
 
 
GET "PALHDR"
 
 
MANIFEST
 $( NY0 = -Y0 $)
 
 
STATIC
 $( SG = 0
 GA1 = 0
 GA2 = 0
 GA3 = 0
 GA4 = 0 $)
 
 
// In MUL and DIV, G=Yn -> gcd removed from polys of degree n and more;
// G=Y0 -> numeric gcd removed
 
 
LET MUL (A, B) = VALOF
 $( LET G = 0
 $( SWITCHON COERCE (@A, TRUE) INTO
 $(
 CASE S.FLT: RESULTIS GETX (S.FLT, 0, GW1 #* GW2, 0)
 CASE S.FPL: MSG1 (14)
 CASE S.NUM: RESULTIS SMUL (A, B)
 CASE S.NUMJ: IF NUMARG
 RESULTIS LONGMUL1 (B, A)
 RESULTIS LONGMUL (A, B)
 CASE S.RATN: IF NUMARG
 $( IF A=Y1
 RESULTIS B
 TEST G=Y0
 $( A := SMUL (A, H2!B)
 B := H1!B $)
 OR $( IF A=Y0
 RESULTIS Y0
 GA1 := IGCD (A+NY0, H1!B+NY0)
 A := SMUL ((A+NY0)/GA1+Y0, H2!B)
 B := (H1!B+NY0)/GA1+Y0
 IF B=Y1
 RESULTIS A $)
 TEST A<=0
 SG := S.RATN
 OR SG := S.RATL
 RESULTIS GET4 (SG, B, A, 0)
 $)
 IF WORSE      // A is NUMJ
 $( TEST G=Y0
 $( A := LONGMUL1 (A, H2!B)
 B := H1!B $)
 OR $( GA1 := GCD1 (A, H1!B)
 A := LONGDIV1 (A, GA1+Y0)
 TEST A<=0
 A := SMUL (A, H2!B)
 OR A := LONGMUL1 (A, H2!B)
 B := (H1!B+NY0)/GA1+Y0
 IF B=Y1
 RESULTIS A $)
 TEST A<=0
 SG := S.RATN
 OR SG := S.RATL
 RESULTIS GET4 (SG, B, A, 0)
 $)
 TEST G=Y0
 $( LET T = SMUL (H2!A, H2!B)
 B := SMUL (H1!A, H1!B)
 A := T $)
 OR $( LET T = H1!A
 GA1 := IGCD (H2!A+NY0, H1!B+NY0)
 GA2 := IGCD (T+NY0, H2!B+NY0)
 A := SMUL ((H2!A+NY0)/GA1+Y0, (H2!B+NY0)/GA2+Y0)
 B := SMUL ((T+NY0)/GA2+Y0, (H1!B+NY0)/GA1+Y0)
 IF B=Y1
 RESULTIS A $)
 TEST A<=0 & B<=0
 SG := S.RATN
 OR SG := S.RATL
 RESULTIS GET4 (SG, B, A, 0)
 CASE S.RATL: IF WORSE
 $( IF A=Y1
 RESULTIS B
 IF G=Y0
 $( A := MUL (A, H2!B)
 RESULTIS GET4 (S.RATL, H1!B, A, 0) $)
 IF A=Y0
 RESULTIS Y0
 A := DIV (A, H1!B)
 B := H2!B
 G := Y0
 LOOP
 $)
 IF G=Y0
 $( LET C = MUL (H2!A, H2!B)
 B := MUL (H1!A, H1!B)
 RESULTIS GET4 (S.RATL, B, C, 0) $)
 $( LET C = DIV (H2!B, H1!A)
 A := DIV (H2!A, H1!B)
 B := C
 G := Y0
 LOOP $)
 CASE S.POLY: IF WORSE
 RESULTIS POLYMAPF (B, A, MUL)
 RESULTIS MULPOLY (A, B)
 CASE S.RATP: IF WORSE
 $( IF A=Y1
 RESULTIS B
 IF G<=H3!B
 $( A := MUL (A, H2!B)
 RESULTIS GET4 (S.RATP, H1!B, A, H3!B) $)
 IF A=Y0
 RESULTIS Y0
 A := DIV (A, H1!B)
 G := H3!B
 B := H2!B
 LOOP
 $)
 IF G<=H3!B
 $( LET C = MUL (H1!A, H1!B)
 A := MUL (H2!A, H2!B)
 RESULTIS GET4 (S.RATP, C, A, H3!B) $)
 $( LET C = DIV (H2!B, H1!A)
 A := DIV (H2!A, H1!B)
 G := H3!B
 B := C
 LOOP $)
 DEFAULT: IF A=Y0 | B=Y0
 RESULTIS Y0
 IF A=Y1
 RESULTIS B
 IF B=Y1
 RESULTIS A
 RESULTIS ARITHFN (A, B, A.MUL)
 $)
 $) REPEAT
 $)
 
 
AND DIV (A, B) = VALOF
 $( LET G = 0
 $( SWITCHON COERCE (@A, FALSE) INTO
 $(
 CASE S.NUM: GA1, GA2 := A+NY0, B+NY0
 IF GA2=0
 MSG1 (7) <> RESULTIS Z
 GA3 := GA1 REM GA2
 IF GA3=0
 RESULTIS GA1/GA2+Y0
 TEST G=Y0
 GA3 := 1
 OR GA3 := IGCD (GA2, GA3)
 IF GA2<0
 GA3 := -GA3
 RESULTIS GET4 (S.RATN, GA2/GA3+Y0, GA1/GA3+Y0, 0)
 
 CASE S.NUMJ: IF NUMARG
 $( IF WORSE1
 $( IF G=Y0
 $( IF B<Y0
 B, A := SIGNBIT-B, A NEQV YSG
 IF B=Y1
 RESULTIS A
 RESULTIS GET4 (S.RATL, B, A, 0) $)
 GA1 := LONGDIV1 (A, B)
 IF RESULT2=0
 RESULTIS GA1
 GA1 := IGCD (B+NY0, RESULT2)
 IF B<Y0
 GA1 := -GA1
 UNLESS GA1=1
 $( B := (B+NY0)/GA1+Y0
 A := LONGDIV1 (A, GA1+Y0) $)
 IF B=Y1
 RESULTIS A
 TEST A<=0
 SG := S.RATN
 OR SG := S.RATL
 RESULTIS GET4 (SG, B, A, 0)
 $)
 IF G=Y0
 $( IF B>=YSG
 B, A := B NEQV YSG, SIGNBIT-A
 RESULTIS GET4 (S.RATL, B, A, 0) $)
 IF A=Y0
 RESULTIS Y0
 GA1 := GCD1 (B, A)
 IF B>=YSG
 GA1 := -GA1
 UNLESS GA1=1
 $( A := (A+NY0)/GA1+Y0
 B := LONGDIV1 (B, GA1+Y0) $)
 TEST B<=0
 SG := S.RATN
 OR SG := S.RATL
 RESULTIS GET4 (SG, B, A, 0)
 $)
 IF G=Y0
 $( IF B>=YSG
 B, A := B NEQV YSG, A NEQV YSG
 RESULTIS GET4 (S.RATL, B, A, 0) $)
 $( LET C = LONGDIV (A, B)
 IF RESULT2=Y0
 RESULTIS C
 C := LGCD (B, C)
 IF B>=YSG
 C := NEG (C)
 UNLESS C=Y1
 A, B := DIV (A, C), DIV (B, C) $)
 TEST A<=0 & B<=0
 SG := S.RATN
 OR SG := S.RATL
 RESULTIS GET4 (SG, B, A, 0)
 
 CASE S.RATN: IF NUMARG
 TEST WORSE1
 $( IF B=Y1
 RESULTIS A        // opt
 IF B=YM
 RESULTIS NEG (A)  // opt
 TEST G=Y0
 $( TEST B<Y0
 GW1, A := SIGNBIT-H1!A, SIGNBIT-H2!A
 OR GW1, A := H1!A, H2!A
 B := SMUL (GW1, B) $)
 OR $( IF B=Y0
 MSG1 (7) <> RESULTIS Z
 GA1 := IGCD (H2!A+NY0, B+NY0)
 IF B<Y0
 GA1 := -GA1
 B := SMUL (H1!A, (B+NY0)/GA1+Y0)
 A := (H2!A+NY0)/GA1+Y0 $)
 TEST B<=0
 SG := S.RATN
 OR SG := S.RATL
 RESULTIS GET4 (SG, B, A, 0)
 $)
 OR $( TEST G=Y0
 $( TEST H2!B<Y0
 GW1, B := SIGNBIT-H1!B, SIGNBIT-H2!B
 OR GW1, B := H1!B, H2!B
 A := SMUL (A, GW1) $)
 OR $( IF A=Y0
 RESULTIS Y0
 GA1 := IGCD (A+NY0, H2!B+NY0)
 IF H2!B<Y0
 GA1 := -GA1
 A := SMUL ((A+NY0)/GA1+Y0, H1!B)
 B := (H2!B+NY0)/GA1+Y0 $)
 IF B=Y1
 RESULTIS A
 TEST A<=0
 SG := S.RATN
 OR SG := S.RATL
 RESULTIS GET4 (SG, B, A, 0)
 $)
 IF WORSE
 TEST WORSE1        // B is NUMJ
 $( TEST G=Y0
 $( TEST B>=YSG
 GW1, A := SIGNBIT-H1!A, SIGNBIT-H2!A
 OR GW1, A := H1!A, H2!A
 B := LONGMUL1 (B, GW1) $)
 OR $( GA1 := GCD1 (B, H2!A)
 IF B>=YSG
 GA1 := -GA1
 B := LONGDIV1 (B, GA1+Y0)      // Now B is positive
 TEST B<=0
 B := SMUL (B, H1!A)
 OR B := LONGMUL1 (B, H1!A)
 A := (H2!A+NY0)/GA1+Y0 $)
 TEST B<=0
 SG := S.RATN
 OR SG := S.RATL
 RESULTIS GET4 (SG, B, A, 0)
 $)
 OR $( TEST G=Y0
 $( TEST H2!B<Y0
 GW1, B := SIGNBIT-H1!B, SIGNBIT-H2!B
 OR GW1, B := H1!B, H2!B
 A := LONGMUL1 (A, GW1) $)
 OR $( GA1 := GCD1 (A, H2!B)
 IF H2!B<Y0
 GA1 := -GA1
 A := LONGDIV1 (A, GA1+Y0)
 TEST A<=0
 A := SMUL (A, H1!B)
 OR A := LONGMUL1 (A, H1!B)
 B := (H2!B+NY0)/GA1+Y0 $)
 IF B=Y1
 RESULTIS A
 TEST A<=0
 SG := S.RATN
 OR SG := S.RATL
 RESULTIS GET4 (SG, B, A, 0)
 $)
 TEST G=Y0
 $( LET T = H2!B
 TEST T<Y0
 T, GW1 := SIGNBIT-T, SIGNBIT-H1!B
 OR GW1 := H1!B
 B := SMUL (H2!A, GW1)
 A := SMUL (H1!A, T) $)
 OR $( LET T = H2!B
 GA1 := IGCD (H2!A+NY0, T+NY0)
 GA2 := IGCD (H1!A+NY0, H1!B+NY0)
 IF T<Y0
 GA1 := -GA1
 B := SMUL ((H2!A+NY0)/GA1+Y0, (H1!B+NY0)/GA2+Y0)
 A := SMUL ((H1!A+NY0)/GA2+Y0, (T+NY0)/GA1+Y0)
 IF A=Y1
 RESULTIS B $)
 TEST A<=0 & B<=0
 SG := S.RATN
 OR SG := S.RATL
 RESULTIS GET4 (SG, A, B, 0)
 
 CASE S.RATL: IF WORSE
 $( IF WORSE1
 $( IF B=Y1
 RESULTIS A     // opt
 IF B=YM
 RESULTIS NEG (A)       // opt
 IF G=Y0
 $( B := MUL (H1!A, B)
 A := H2!A
 UNLESS POSITIVE (B)
 B, A := NEG (B), NEG (A)
 RESULTIS GET4 (S.RATL, B, A, 0) $)
 GW1 := DIV (H2!A, B)
 B := H1!A
 A := GW1
 G := Y0
 LOOP
 $)
 IF G=Y0
 $( A := MUL (A, H1!B)
 B := H2!B
 UNLESS POSITIVE (B)
 B, A := NEG (B), NEG (A)
 RESULTIS GET4 (S.RATL, B, A, 0) $)
 IF A=Y0
 RESULTIS Y0
 GW1 := DIV (H2!B, A)
 A := H1!B
 B := GW1
 G := Y0
 LOOP
 $)
 IF G=Y0
 $( LET C = MUL (H2!A, H1!B)
 B := MUL (H1!A, H2!B)
 UNLESS POSITIVE (B)
 B, C := NEG (B), NEG (C)
 RESULTIS GET4 (S.RATL, B, C, 0) $)
 $( LET C = DIV (H2!A, H2!B)
 B := DIV (H1!A, H1!B)
 A := C
 G := Y0
 LOOP $)
 
 CASE S.POLY: TEST WORSE
 TEST WORSE1
 $( IF B=Y0
 MSG1 (7) <> RESULTIS Z
 RESULTIS POLYMAPF (A, B, DIV) $)
 OR IF A=Y0
 RESULTIS Y0
 OR IF G>H3!B
 $( GA1 := DIVPOLY (A, B)
 IF RESULT2=Y0
 RESULTIS GA1
 $( LET C = LCOEF
 IF RESULT2>0 & !RESULT2=S.POLY & H3!RESULT2=H3!B
 $( LET R = POLYGCD (B, RESULT2)
 UNLESS R=Y1
 $( C := DIV (C, LCOEF)
 C := POLYMAPF (R, C, MUL) $) $)
 UNLESS C=Y1
 $( A := DIV (A, C)
 B := DIV (B, C) $) $)
 RESULTIS GET4 (S.RATP, B, A, H3!B)
 $)
 B := MONICPOLY (B)
 UNLESS LCOEF=Y1
 A := DIV (A, LCOEF)
 RESULTIS GET4 (S.RATP, B, A, H3!B)
 
 CASE S.RATP: IF WORSE
 TEST WORSE1
 $( IF B=Y1
 RESULTIS A        // opt
 IF B=YM
 RESULTIS NEG (A)  // opt
 IF G<=H3!A
 $( LET A1 = H1!A
 IF B>0 & !B=S.POLY & H3!B=H3!A
 $( B := MONICPOLY (B)
 TEST LCOEF=Y1
 A := H2!A
 OR A := DIV (H2!A, LCOEF)
 B := MUL (A1, B)
 RESULTIS GET4 (S.RATP, B, A, H3!B) $)
 A := DIV (H2!A, B)
 RESULTIS GET4 (S.RATP, A1, A, H3!A1)
 $)
 $( LET T = DIV (H2!A, B)
 B := H1!A
 G := H3!A
 A := T $)
 LOOP
 $)
 OR $( IF G<=H3!B
 $( A := MUL (A, H1!B)
 B := H2!B
 LOOP $)
 IF A=Y0
 RESULTIS Y0
 $( LET T = DIV (H2!B, A)
 A := H1!B
 G := H3!B
 B := T $)
 LOOP
 $)
 IF G<=H3!B
 $( LET B2 = H2!B
 IF B2>0 & !B2=S.POLY & H3!B2=H3!A
 $( B2 := MONICPOLY (B2)
 TEST LCOEF=Y1
 B := H1!B
 OR B := DIV (H1!B, LCOEF)
 B2 := MUL (H1!A, B2)
 B := MUL (H2!A, B)
 RESULTIS GET4 (S.RATP, B2, B, H3!A) $)
 B2 := DIV (H2!A, B2)
 B := MUL (B2, H1!B)
 RESULTIS GET4 (S.RATP, H1!A, B, H3!A)
 $)
 $( LET C = DIV (H2!A, H2!B)
 B := DIV (H1!A, H1!B)
 G := H3!A
 A := C
 LOOP $)
 
 CASE S.FLT: IF GW2 #= 0.0
 MSG1 (7) <> RESULTIS Z
 RESULTIS GETX (S.FLT, 0, GW1 #/ GW2, 0)
 CASE S.FPL: MSG1 (14)
 DEFAULT: IF B=Y1
 RESULTIS A
 IF A=Y0
 RESULTIS Y0
 IF EQLV (A, B)
 RESULTIS Y1
 RESULTIS ARITHFN (A, B, A.DIV)
 $)
 $) REPEAT
 $)
 
 
AND MODV (A, B) = VALOF
 $( COERCE (@A, FALSE)
 IF B<=0
 $( IF B=Y0
 MSG1 (7) <> RESULTIS Z
 IF A<=0
 RESULTIS (A+NY0) REM (B+NY0)+Y0
 SWITCHON !A INTO
 $(
 CASE S.NUMJ: LONGDIV1 (A, B)
 RESULTIS RESULT2+Y0
 CASE S.POLY: RESULTIS Y0
 DEFAULT: GOTO L $)
 $)
 SWITCHON !B INTO
 $(
 CASE S.NUMJ: IF A<=0
 RESULTIS A
 SWITCHON !A INTO
 $(
 CASE S.NUMJ: LONGDIV (A, B)
 RESULTIS RESULT2
 CASE S.POLY: RESULTIS Y0
 DEFAULT: GOTO L $)
 CASE S.POLY: IF A<=0
 RESULTIS A
 SWITCHON !A INTO
 $(
 CASE S.FLT:
 CASE S.FPL:
 CASE S.NUMJ:
 CASE S.RATN:
 CASE S.RATL: RESULTIS A
 CASE S.POLY: IF WORSE
 TEST WORSE1
 RESULTIS Y0
 OR RESULTIS A
 DIVPOLY (A, B)
 RESULTIS RESULT2
 DEFAULT: GOTO L
 $)
 L:   DEFAULT: MSG1 (23, A, B)
 $)
 $)
 
 
STATIC
 $( GA0 = 0 $)
 
 
LET POW (A, B) = VALOF
 $( COERCE (@A, FALSE)
 IF A=Y0 | A=Y1
 RESULTIS A
 UNLESS B<0
 MSG1 (23, A, B)
 TEST B<=Y0
 $( IF B=Y0
 RESULTIS Y1
 GA0 := Y0-B
 A := RECIP (A) $)
 OR GA0 := B-Y0
 IF GA0=1
 RESULTIS A
 B := Y1
 $( UNLESS (GA0 & 1)=0
 $( B := MUL (A, B)
 IF GA0=1
 RESULTIS B $)
 GA0 := GA0>>1
 A := MUL (A, A) $) REPEAT
 $)
 
 
.
//./       ADD LIST=ALL,NAME=PALDD
 SECTION "PALDD"
 
 
GET "PALHDR"
 
 
STATIC
 $( L0 = 0
 DD0 = 0
 DD1 = 0
 DD2 = 0
 DD3 = 0 $)
 
 
LET VALGLOB (N) = SADD ((@G0)!N)
 
 
AND SETGLOB (N1, N2) BE
 $( (@G0)!N1 := (@G0)!N2
 WRITEF ("*N# Global %N set to %A*N", N2, (@G0)!N2) $)
 
 
AND VALIDP (P) = VALOF
 $( IF P<=0
 RESULTIS TRUE
 $( LET Q = P & P.ADDR
 LET QQ = P-Q
 UNLESS QQ=0 | QQ=YSG | QQ=YFJ | QQ=P.TAGP
 RESULTIS FALSE
 UNLESS ST1<=Q<=ST2
 RESULTIS FALSE
 UNLESS 0<=!Q<=TYPSZ
 RESULTIS FALSE $)
 RESULTIS TRUE
 $)
 
 
AND LASTDITCH (A) BE
 L (A, 0)
 
 
AND L (A, N) BE
 $( NEWLINE ()
 TAB (N*20)
 WRITEARGP (A, FALSE)
 UNLESS ST1<=(A & P.ADDR)<=ST2
 RETURN
 IF N=3
 $( TAB (85)
 WRITES ("#...etc")
 RETURN $)
 FOR I=1 TO 3
 L (A!I, N+1)
 $)
 
 
AND VERIFY () = VALOF
 $( WRITEF ("*N# checking heap (%T):")
 $( LET S, N = STACKP, 0
 UNTIL S=0
 $( LET T = !S
 !S, H1!S := 0, T | SIGNBIT
 S := T
 N := N+4 $)
 WRITEF (" %N words free;*N", N) $)
 L0, DD0 := LL, TRUE
 SCANP (VERH)
 LL:  $( LET S = STACKP
 UNTIL S=0
 !S, S := H1!S & P.ADDR, !S $)
 WRITEF ("*N# end of check (%T)*N")
 IF DD0
 RESULTIS TRUE
 OKPAL := TRUE
 WRITEF ("*N# Bad link: %E (%N) -> %E*N", ERRORP, DD1, DD2, ERRORP, DD3)
 WRITEARGP (DD1, TRUE)
 IF ST1<=DD3<=ST2
 $( NEWLINE ()
 WRITEARGP (H2!DD3, TRUE)
 NEWLINE ()
 WRITEARGP (H3!DD3, TRUE) $)
 Q.SELINPUT (SYSIN)
 RCH := RCH1
 $( LET V = READX ()
 UNLESS V=Z
 $( WRITES ("*NRe-start DD")
 EVAL (V)
 STOP (16) $) $)
 MAPHEAP (FALSE)
 ERZ := ZSY
 MSG1 (13, VERIFY)
 $)
 
 
AND VERH (P) BE
 $( LET Q = !P
 IF Q>0
 $( UNLESS VALIDP (Q)
 $( DD0, DD1, DD2, DD3 := FALSE, P & ~3, P & 3, Q
 LONGJUMP (FLEVEL (VERIFY), L0) $)
 IF !Q=0
 $( WRITEF ("%ZTANGLE %N-%N", 8, P, Q)
 DD0 := FALSE
 DD1, DD2, DD3 := P & ~3, P & 3, Q $) $) $)
 
 
AND MAPHEAP (F) BE
 $( WRITEF ("*N*N# HEAP (%T)*N")
 FOR I=ST1 TO SVU BY 4
 $( ZTAB (4)
 WRITEARGP (I, F) $)
 WRITES ("*N #cold region#*N")
 FOR I=SVV TO ST2 BY 4
 $( ZTAB (4)
 WRITEARGP (I, F) $)
 WRITEF ("*N# END OF HEAP (%T)*N*N") $)
 
 
AND USERPOSTMORTEM (CODE, SVALID) BE
 $( USERPOSTMORTEM := DUMMY
 ERRORRESET ()
 IF PARAMK
 $( UNLESS SVALID
 ABORT (0)
 BACKTRACE ()
 PMAP (PARAMC)
 MAPSTORE ()
 STOP (20) $) $)
 
 
AND PALDD (STYLE, S, N, A, B, C, D, E, F) BE
 $( WRITEF ("*N# %S (%T)", S)
 FOR I=@A TO @A+N-1
 $( ZTAB (10)
 STYLE (!I) $)
 NEWLINE () $)
 
 
AND CHPOLY (A) BE
 $( LET S = ZERO
 UNLESS A>0
 RETURN
 IF @A>STACKL
 STKOVER ()
 UNLESS VALIDP (A)
 ERRORP (A)
 IF !A=S.RATP
 $( IF H2!A=Y0
 S := "RATP" <> GOTO L
 CHPOLY (H1!A)
 CHPOLY (H2!A)
 RETURN $)
 IF !A=S.POLY
 $( LET P = H1!A
 UNTIL P=Z
 $( IF (P & P.ADDR)=ZSY | H2!P=Y0
 S := "POLY" <> GOTO L
 P := H1!P $)
 RETURN $)
 RETURN
 L: WRITEF ("*N*N# CHPOLY: BAD %S (%T)*N", S)
 PRINTA (A)
 MSG1 (0)
 $)
 
 
AND DDADD (A, B) = VALOF
 $( LET C = DDADD (A, B)
 CHPOLY (C)
 RESULTIS C $)
 
 
AND DDMINU (A, B) = VALOF
 $( LET C = DDMINU (A, B)
 CHPOLY (C)
 RESULTIS C $)
 
 
AND DDMUL (A, B) = VALOF
 $( LET C = DDMUL (A, B)
 CHPOLY (C)
 RESULTIS C $)
 
 
AND DDDIV (A, B) = VALOF
 $( LET C = DDDIV (A, B)
 CHPOLY (C)
 RESULTIS C $)
 
 
AND DDADDPOLY (A, B) = VALOF
 $( LET C = DDADDPOLY (A, B)
 CHPOLY (C)
 CHARITH1 ()
 $( LET T = ADD (C, B NEQV YSG)
 CHARITH1 ()
 IF EQLV (T, A)
 RESULTIS C
 WRITEF ("*N# +: (%E) + (%E) = %E*N", PRINTA, A, PRINTA, B, PRINTA, C)
 MSG1 (0)
 RESULTIS C $)
 $)
 
 
AND DDMULPOLY (A, B) = VALOF
 $( LET C = DDMULPOLY (A, B)
 CHPOLY (C)
 IF C=Y0
 RESULTIS C
 CHARITH1 ()
 $( LET T = DIV (C, B)
 CHARITH1 ()
 IF EQLV (T, A)
 RESULTIS C
 WRITEF ("*N# **: (%E) ** (%E) = %E*N", PRINTA, A, PRINTA, B, PRINTA, C)
 MSG1 (0)
 RESULTIS C $)
 $)
 
 
AND DDDIVPOLY (A, B) = VALOF
 $( LET C = DDDIVPOLY (A, B)
 LET D1, D2, D3 = RESULT2, LCOEF, LDEG
 CHPOLY (C)
 CHPOLY (D1)
 CHARITH1 ()
 $( LET T = MUL (B, C)
 T := ADD (T, D1)
 CHARITH1 ()
 IF EQLV (T, A)
 $( RESULT2, LCOEF, LDEG := D1, D2, D3
 RESULTIS C $)
 WRITEF ("*N# /: (%E) / (%E) = %E*N", PRINTA, A, PRINTA, B, PRINTA, C)
 RESULT2, LCOEF, LDEG := D1, D2, D3
 MSG1 (0)
 RESULTIS C
 $)
 $)
 
 
AND DDPSEU (A, B) = VALOF
 $( LET C = DDPSEU (A, B)
 LET D2, D3 = LCOEF, LDEG
 CHPOLY (C)
 CHARITH1 ()
 $( LET T = MINU (A, C)
 T := DIV (T, B)
 CHARITH1 ()
 IF RESULT2=Y0
 $( LCOEF, LDEG := D2, D3
 RESULTIS C $)
 WRITEF ("*N# REM: (%E) REM (%E) = %E*N", PRINTA, A, PRINTA, B, PRINTA, C)
 LCOEF, LDEG := D2, D3
 MSG1 (0)
 RESULTIS C
 $)
 $)
 
 
AND DDEQUP (A, B, F) = VALOF
 $( LET C = DDEQUP (A, B, F)
 CHARITH1 ()
 $( LET T = (F -> MINU, ADD)(A, B)
 IF C=(T=Y0)
 $( CHARITH1 ()
 RESULTIS C $)
 WRITEF ("*N# Q: (%E) = (%E) with %P : %P*N", PRINTA, A, PRINTA, B, F, C)
 MSG1 (0)
 RESULTIS C $) $)
 
 
AND CHARITH () BE
 $( $( LET T = ADD
 ADD, DDADD := DDADD | SIGNBIT, T | SIGNBIT $)
 $( LET T = MINU
 MINU, DDMINU := DDMINU | SIGNBIT, T | SIGNBIT $)
 $( LET T = MUL
 MUL, DDMUL := DDMUL | SIGNBIT, T | SIGNBIT $)
 $( LET T = DIV
 DIV, DDDIV := DDDIV | SIGNBIT, T | SIGNBIT $) $)
 
 
AND CHARITH1 () BE
 $( CHARITH ()
 $( LET T = ADDPOLY
 ADDPOLY, DDADDPOLY := DDADDPOLY | SIGNBIT, T | SIGNBIT $)
 $( LET T = MULPOLY
 MULPOLY, DDMULPOLY := DDMULPOLY | SIGNBIT, T | SIGNBIT $)
 $( LET T = DIVPOLY
 DIVPOLY, DDDIVPOLY := DDDIVPOLY | SIGNBIT, T | SIGNBIT $)
 $( LET T = PSEUDOREMPOLY
 PSEUDOREMPOLY, DDPSEU := DDPSEU | SIGNBIT, T | SIGNBIT $)
 $( LET T = EQPOLY
 EQPOLY, DDEQUP := DDEQUP | SIGNBIT, T | SIGNBIT $)
 $)
 
 
.
//./       ADD LIST=ALL,NAME=PALHDR
 // SECTION "PALHDR"
 
 
MANIFEST
 $( ENDSTREAMCH = -1
 BYTESPERWORD = 4
 MAXINT = -1>>1
 SIGNBIT = ~MAXINT
 PAGEMASK = #XFFFFFE00
 PAGESIZE = #X200
 P.ADDR = #XFFFFFF
 P.TAG = #XFF000000
 P.TAGP = P.TAG-SIGNBIT
 FLTEN = 10E0
 
 BUFFL = 128
 NUMBA = 1000000000
 NUMWI = 9
 
 H0 = 0    // selectors
 H1 = 1
 H2 = 2
 H3 = 3
 
 S.NUM = 0
 S.STRING = 1
 S.FLT = 2
 S.FPL = 3
 S.NUMJ = 4
 S.RATN = 5
 S.RATL = 6
 S.RATP = 7
 S.POLY = 8
 S.POLYJ = 9
 
 S.LOC = 10
 
 S.CDX = 11
 S.CDY = 12
 S.CDZ = 13
 S.CD = 14
 
 S.BCPLF = 15
 S.BCPLR = 16
 S.BCPLV = 17
 S.CODEV = 20
 S.CODE0 = 21
 S.CODE1 = 22
 S.CODE2 = 23
 S.CODE3 = 24
 S.CODE4 = 25
 
 S.RDS = 26
 S.WRS = 27
 
 S.UNSET = 29
 S.UNSET1 = 30
 
 S.GENSY = 31
 S.NAME = 32
 S.GLZ = 33
 S.GLG = 34
 S.GLO = 35
 S.QU = 36
 
 S.TUPLE = 38
 S.XTUPL = 39
 
 S.TRA = 40
 
 S.E = 41
 S.CLOS = 42
 S.ACLOS = 43
 S.CLOS2 = 44
 S.ECLOS = 45
 S.FCLOS = 46
 S.JCLOS = 47
 S.KCLOS = 48
 
 S.REC = 49
 S.RECA = 50
 S.LET = 51
 S.LETA = 52
 S.LETB = 53
 S.COND = 54
 S.CONDA = 55
 S.CONDB = 56
 
 S.SEQ = 57
 S.SEQA = 58
 S.COLON = 59
 S.RETU = 60
 S.DASH = 61
 S.AA = 62
 S.ZZ = 63
 
 S.APZ = 64
 S.APPLY = 65
 S.APPLE = 66
 S.AA1 = 67
 S.A1A = 68
 S.AP1 = 69
 S.A1E = 70
 S.APV = 71
 S.AVE = 72
 S.AA2 = 73
 S.A2A = 74
 S.AP2 = 75
 S.A2E = 76
 S.AAA = 77
 S.AEA = 78
 S.APQ = 79
 S.AQE = 80
 
 S.J = 81
 S.Z = 82
 
 S.MCC = 83
 S.MCF = 84
 S.MCK = 85
 
 S.MAL = 86
 S.MAR = 87
 S.MS = 88
 S.MT = 89
 S.MAA = 90
 S.MA1 = 91
 S.MF1 = 92
 S.MF1A = 93
 S.MA2L = 94
 S.MA2R = 95
 S.MF2L = 96
 S.MF2R = 97
 S.MAQ = 98
 S.MLET = 99
 S.MCOND = 100
 
 S.MZ = 101
 S.MMCC = 102
 S.MMCF = 103
 S.MMCK = 104
 
 S.MMAL = 105
 S.MMAR = 106
 S.MMS = 107
 S.MMT = 108
 S.MMAA = 109
 S.MMA1 = 110
 S.MMF1 = 111
 S.MMF1A = 112
 S.MMA2L = 113
 S.MMA2R = 114
 S.MMF2L = 115
 S.MMF2R = 116
 S.MMAQ = 117
 S.MMLET = 118
 S.MMCOND = 119
 
 S.MB = 120
 
 S.IF = 121
 S.UNLESS = 122
 S.WHILE = 123
 S.UNTIL = 124
 S.REPEAT = 125
 S.FOR = 126
 S.DO = 127
 S.THEN = 128
 S.OR = 129
 S.ELSE = 130
 S.DIADOP = 131
 S.RELOP = 132
 S.LPAR = 133
 S.RPAR = 134
 S.IN = 135
 S.AND = 136
 S.WITHIN = 137
 S.WHERE = 138
 S.Q2 = 139
 S.SH1 = 140
 S.INFIX = 141
 S.DOT = 142
 S.FIN = 143
 S.NIL = 144
 S.NULL = 145
 S.PP = 146
 S.DLR = 147
 S.BY = 148
 S.QR = 149
 
 STR1 = BYTESPERWORD*2
 STR2 = STR1+7
 
 FR.CALLBCPL = 3
 FR.GC = 12
 FR.S = 64
 
 Z = 0
 Y0 = -(SIGNBIT>>1)
 Y1 = Y0+1
 Y2 = Y0+2
 Y3 = Y0+3
 YM = Y0-1
 
 MM3 = S.RATL
 MTYPSZ = S.MZ-1
 TYPSZ = S.MB
 JGAP = S.MZ-S.Z
 
 YLOC = SIGNBIT>>1
 YFJ = SIGNBIT>>1
 YSG = SIGNBIT>>2
 SVA = SIGNBIT>>2
 $)
 
 
GLOBAL
 $( G0:0
 START:1
 ABORT:3
 BACKTRACE:4
 ERRORMESSAGE:5
 SAVEAREA:6
 UNLOADALL:7
 LOADFORT:8
 UNLOAD:9
 LOAD:10
 SELECTINPUT:11
 SELECTOUTPUT:12
 RDCH:13
 WRCH:14
 UNRDCH:15
 INPUT:16
 OUTPUT:17
 INCONTROL:18
 OUTCONTROL:19
 TRIMINPUT:20
 SETWINDOW:21
 BINARYINPUT:22
 READREC:23
 WRITEREC:24
 WRITESEG:25
 SKIPREC:26
 TIMEOFDAY:27
 TIME:28
 DATE:29
 STOP:30
 LEVEL:31
 LONGJUMP:32
 BINWRCH:34
 REWIND:35
 FINDLOG:36
 WRITETOLOG:37
 FINDTPUT:38
 FINDPARM:39
 APTOVEC:40
 FINDOUTPUT:41
 FINDINPUT:42
 FINDLIBRARY:43
 INPUTMEMBER:44
 PARMS:45
 ENDREAD:46
 ENDWRITE:47
 CLOSELIBRARY:48
 OUTPUTMEMBER:49
 ENDTOINPUT:51
 LOADPOINT:52
 ENDPOINT:53
 STACKBASE:54
 STACKEND:55
 STACKHWM:56
// G57 IS 'OS' OR 'CMS'
 WRITES:60
 WRITEN:62
 NEWLINE:63
 NEWPAGE:64
 WRITEO:65
 PACKSTRING:66
 UNPACKSTRING:67
 WRITED:68
 WRITEARG:69
 READN:70
 TERMINATOR:71
 CH:71
 LOADPAGE:72
 TURNPAGE:73
 WRITEX:74
 WRITEHEX:75
 WRITEF:76
 WRITEOCT:77
 MAPSTORE:78
 USERPOSTMORTEM:79
 CALLIFORT:80
 CALLRFORT:81
 SETBREAK:82
 ISBREAK:83
 ERRORRESET:84
 GETBYTE:85
 PUTBYTE:86
 GETVEC:87
 FREEVEC:88
 RANDOM:89
 MULDIV:90
 RESULT2:91
 BLOCKSIZE:92
 CREATEBLOCKFILE:93
 OPENBLOCKFILE:94
 CLOSEBLOCKFILE:95
 READBLOCK:96
 WRITEBLOCK:97
 WRNEXTBLOCK:98
 MOVEBLOCK:99
 
 DUMMY:100
 ZERO:101
 WRC:102
 WCH:103
 WCH1:104
 CHC:105
 CHZ:106
 WRITEP:107
 WRITEL:108
 WRFLT:109
 TAB:110
 XTAB:111
 YTAB:112
 ZTAB:113
 Q.INPUT:114
 Q.OUTPUT:115
 Q.SELINPUT:116
 Q.SELOUTPUT:117
 Q.ENDREAD:118
 Q.ENDWRITE:119
 SYSIN:120
 SYSOUT:121
 RCH:122
 RCH0:123
 RCH1:124
 PEEPCH:125
 RBASE:126
 READSN:127
 SETIO:128
 SOFTERROR:129
 MAPGVEC:130
 MAPSEG:131
 MAPLOAD:132
 VALIDCODE:133
 VALIDENTRY:134
 ERLEV:135
 ERLAB:136
 STACKB:137
 STACKL:138
 BACKTR:139
 NARGS:140
 WFRAME:141
 
 STACKP:150
 ST1:152
 ST2:153
 SVU:154
 SVV:155
 SSZ:156
 REGION:157
 
 STACK:161
 SCANP:162
 SCANST:163
 MARKA:164
 STKOVER:165
 GPFN:166
 SQUASH:167
 
 EQL:170
 
 SADD:171
 SMUL:172
 SDIV:173
 
 OKPAL:174
 REC0:175
 REC1:176
 THROW:177
 
 KSQ:179
 KWORDS:180
 KSTACK:181
 
 LASTDITCH:184
 WRITEARGP:185
 ERRORP:186
 PFRAME:187
 PMAP:188
 FLEVEL:189
 MAPHEAP:190
 VERIFY:191
 PALDD:192
 
 SETUP:193
 INITFF:194
 SETGLOB:195
 VALGLOB:196
 STOV:197
 TTOV:198
 FIXBCPL1:199
 
 PARAMA:200
 PARAMB:201
 PARAMC:202
 PARAMD:203
 PARAMI:204
 PARAMJ:205
 PARAMK:206
 PARAMM:207
 PARAMN:208
 PARAMQ:209
 PARAMV:210
 PARAMY:211
 PARAMZ:212
 PARAM:213
 
 GW0:214
 GW1:215
 GW2:216
 GW3:217
 GW4:218
 
 MSG0:220
 MSG1:221
 MSG2:222
 MSG3:223
 
 CODE:225
 BCPLF:226
 BCPLR:227
 BCPLV:228
 GETV:229
 GETMV:230
 STREAM:231
 
 G.LOAD:232
 G.UNLOAD:233
 
 SEL1:235
 SEL2:236
 G.POSINT:237
 G.NP:238
 G.NT:239
 
 CALLBCPL:240
 TRANSPAL:241
 
 BUFFP:242
 RTIME:243
 TEMPUS:244
 TEMPUSP:245
 CLOCK:246
 
 CONS:249
 CYCLES:250
 GENSYMN:251
 ALGN:252
 LCOEF:253
 LDEG:254
 FRAG:255
 MFN:256
 NUMARG:257
 WORSE:258
 WORSE1:259
 GSEQ:260
 GSEQF:261
 
 OCM:262
 TYP:263
 FFF:264
 EVSY:265
 KEEP1:266
 KEEP2:267
 
 PATCH0:268
 PATCH1:269
 PATCH2:270
 PATCH3:271
 PATCH4:272
 PATCH5:273
 
 M:275
 ZC:276
 ZE:277
 ZJ:278
 ZS:279
 ZSY:280
 ZSC:281
 ZSQ:282
 ZU:283
 
 E:294
 J:295
 ARG1:296
 ROOT:297
 TRZ:298
 ERZ:299
 
 A.NUM:300
 A.QU:301
 A.FCLOS:302
 A.EQ:303
 A.GT:304
 A.PLUS:305
 A.MINU:306
 A.MUL:307
 A.DIV:308
 A.NULL:309
 
 ERROR:320
 ERRORSET:321
 ERROREVAL:322
 
 LL.SY:330
 LL.RX:331
 RP:334
 READX:335
 REXQ:336
 REXP:337
 RDEF:338
 RFNDEF:339
 RBV:340
 RBVLIST:341
 RSYM:342
 RS:343
 GETEX:346
 
 RDS:351
 WRS:352
 REA:355
 PRIN:357
 PRCH:358
 PRINL:360
 PRINT:361
 PRINTA:362
 PRINK:363
 PRINE:365
 PRINJ:366
 PRIND:367
 
 TRAP:430
 DOTRAP:431
 DOTRAP1:432
 TRACE:435
 UNTRACE:436
 DOTRACE:437
 DOTRACE1:438
 
 SHOW:440
 SHOW1:445
 
 FIXV:470
 FLOATV:471
 ABSV:472
 RATAPPROX:480
 SHLV:486
 SHRV:487
 
 LVV:490
 RVV:491
 TYV:492
 HDV:493
 MIV:494
 TLV:495
 NULL:496
 IV:497
 ORDER:498
 LMAP:500
 LMAPL:501
 LMAPT:502
 
 DOFOR:509
 AUG:511
 ISV:512
 ASSG:513
 GENGLO:514
 GENSYM:515
 ASYM:516
 REV:517
 REVD:518
 XTUPLE:520
 FIND:521
 PUT:522
 
 ARITHV:529
 COERCE:530
 ARITHFN:531
 EQLV:532
 GTV:533
 ADD:538
 MINU:539
 MUL:540
 DIV:541
 MODV:542
 POW:543
 NEG:544
 POSITIVE:545
 RECIP:546
 GCDA:547
 
 MAINVAR:550
 NUM:551
 ATOM:552
 TUPLE:553
 RAT:555
 SYN:556
 FUNCTION:557
 
 APPLY:560
 EVAL:561
 GET4:562
 GETX:563
 
 LINKWORD:572
 FINDWORD:573
 PUTWORD:574
 COMPL:575
 
 POL:576
 EQPOLY:577
 EVALPOLY:578
 ALG:579
 ALGATOM:580
 ADDPOLY:581
 ADDP1:582
 POLYMAPF:583
 MULPOLY:584
 DIVPOLY:585
 PSEUDOREMPOLY:586
 COPYU:587
 COPYV:588
 UNCOPY:589
 MONICPOLY:590
 POLYGCD:591
 
 MATCHBV:599
 SIMNAME:600
 SIMTUP:601
 FN:602
 REC:603
 MLET:604
 MLET1:605
 COLON:606
 MCOLON:607
 SEQ:608
 MSEQ:609
 COND:610
 MCOND:611
 LINSEQ:612
 RETU:613
 MQU:614
 AP1:615
 AP2:616
 MDOL:617
 MK.AA:618
 MK.ZZ:619
 MDASH:620
 MNULL:621
 MCLOS1:622
 MA2:623
 
 MK.AUG:624
 MK.LOGOR:625
 MK.LOGAND:626
 MK.NE:627
 MK.GE:628
 MK.LT:629
 MK.LE:630
 MK.PLUS:632
 MK.MINU:633
 MK.MUL:634
 MK.DIV:635
 MK.POW:636
 MFOR:637
 MWHI:638
 MDOLV:639
 
 FIXAP:640
 
 NUMBER:671
 STRING:673
 NAME:674
 GLOBA:675
 
 DUMP:695
 UNDUMP:696
 
 LONGADD:701
 LONGSUB:702
 LONGAS1:703
 LONGMUL:704
 LONGMUL1:705
 LONGCMP:706
 LONGDIV1:707
 LONGDIV:708
 
 LOOKUP:710
 BIND:711
 BIND1:712
 BINDA:713
 BINDR:714
 DOREC:716
 DORECA:717
 
 DIFR:720
 DIFR1:721
 
 IGCD:725
 GCD1:726
 LGCD:727
 
 L.FLATTEN:734
 FLATTEN:735
 FLAT1:736
 FIXAPF:737
 FLATBV:738
 SIMENV:739
 LOADN:740
 
 FF.CLOS:755
 FF.RECA:756
 FF.TUPLE:757
 FF.CONDB:758
 FF.SEQA:759
 FF.DASH:760
 FF.E:761
 FF.A1E:763
 FF.AVE:764
 FF.A2E:765
 
 LL.ZC:780
 LA.ENTX:781
 LA.ENTY:782
 LA.ENTZ:783
 LA.APLOC:784
 LA.APTUP:785
 LA.APCODE2:786
 LA.APCLOS2:787
 LA.APECLOS:788
 LA.APFCLOS:789
 
 LL.ENTX:790
 LL.ENTY:791
 LL.ENTZ:792
 LL.APECLOS:793
 LL.APFCLOS:794
 LA.A1:795
 LA.AE:796
 
 LL.EV:797
 LL.EX:798
 LL.AP:800
 LL.GLZ:801
 LL.RSC:802
 LL.RSF:803
 LL.SVC:804
 LL.SVF:805
 LL.SVF1:806
 
 LL.BIND:811
 LL.BINDE:816
 LL.UNBIND:817
 LL.CY:820
 LL.CYF:821
 LL.NA:822
 LL.NA1:823
 LL.NA2:824
 LL.NAF:825
 LL.NA1F:826
 LL.NA2F:827
 LL.ST:830
 LL.US:831
 
 LL.REC0:833
 LL.REC1:834
 LL.DASH:835
 LL.E:836
 LL.J:837
 LL.COND:838
 
 LL.TUP:840
 LL.TUPA:841
 LL.TUPZ:842
 LL.1TUP:843
 LL.CLOSL:845
 LL.CLOSX:847
 LL.APV:850
 LL.AP1:851
 LL.HDV:852
 LL.MIV:853
 LL.TLV:854
 LL.NULL:855
 LL.ATOM:856
 LL.AP2:857
 LL.AP2F:858
 LL.AP2S:859
 LL.AP2SF:860
 LL.CONS:861
 LL.CONSF:862
 LL.XCONS:863
 LL.XCONSF:864
 
 LL.LV:869
 LL.RV:870
 LL.BVF:872
 LL.BVFE:873
 LL.BVFA:874
 LL.BVF1:875
 LL.BVFZ:876
 LL.BVE:877
 LL.BVEZ:878
 LL.ENT2:879
 
 LL.APCF:880
 LL.APCF1:881
 LL.APCK:882
 LL.APCC:883
 LL.APBF:884
 LL.APBF1:885
 LL.APBK:886
 LL.APBC:887
 LL.APKF:888
 LL.APKK:889
 LL.APKC:890
 LL.APKJ:891
 LL.APNF:892
 LL.APNF1:893
 LL.APNK:894
 LL.APNC:895
 LL.APNJ:896
 $)
 
 
MANIFEST
 $( OCMSZ = 120
 MAXGLOB = 896 $)
//./       ADD LIST=ALL,NAME=PALM1
 SECTION "PALM1"
 
 
GET "PALHDR"
 
// Mainly print routines.
// Print routines can mangle structure;
// but not PRIN, which must be short, and not use any heap.
// It may ?? be safe to try printing when the heap is partially mangled,
// eg during gc
 
 
STATIC
 $( S0 = 0
 S1 = 0
 KK = 0
 NN = 0 $)
 
 
LET STREAM (R, S1, S2) = VALOF
 $( LET N = R (S1, S2)
 IF N=0
 MSG1 (9, S1, S2)
 RESULTIS N+Y0 $)
 
 
AND RDS (S) = VALOF
 $( LET N = STREAM (FINDINPUT, S, ZERO)
 IF N=Y0
 RESULTIS Z
 RESULTIS GET4 (S.RDS, 0, N, 0) $)
 
 
AND WRS (S) = VALOF
 $( LET N = STREAM (FINDOUTPUT, S, ZERO)
 IF N=Y0
 RESULTIS Z
 RESULTIS GET4 (S.WRS, 0, N, 0) $)
 
 
AND REA () = RCH ()+Y0
 
 
AND PRINPARS (F, A, B) BE
 $( WCH ('(')
 F (A, B)
 WCH (')') $)
 
 
AND PRIN (A) = VALOF
 $( LET X = A
 $( S0, S1 := ZERO, 0
 IF X<=0
 $( TEST ABS (X-Y0)<=NUMBA
 WRITEN (X-Y0)
 OR TEST X=0
 $( S0 := "NIL"
 GOTO L1 $)
 OR TEST X=-1
 $( S0 := "TRUE"
 GOTO L1 $)
 OR WRITEF ("[%A]", X)
 RESULTIS A
 $)
 SWITCHON !X INTO
 $(
 DEFAULT: $( LET T = !X
 IF 0<=T<=TYPSZ
 $( WRITEF ("#%N#", T)
 X := TYV (X)
 LOOP $)
 WRITEF ("#?%N(%N)#", X, T)
 RESULTIS A $)
 CASE S.TRA: WRITES ("#trace#")
 X := H2!X
 LOOP
 CASE S.LOC: X := H1!X
 LOOP
 CASE S.UNSET:
 CASE S.UNSET1:
 S0 := "#unset#"
 GOTO L1
 CASE S.FLT: WRFLT (H2!X)
 RESULTIS A
 CASE S.NUMJ: WRITEF ("...%N", H3!X)
 RESULTIS A
 CASE S.FPL: PRFPL (X)
 RESULTIS A
 CASE S.RATN:
 CASE S.RATL:
 CASE S.RATP: S0, S1 := "#%Nrat#", H3!X
 IF S1<0
 S1 := S1-Y0
 GOTO L2
 CASE S.RDS:
 CASE S.WRS: S0 := "#stream#"
 GOTO L1
 CASE S.CODEV:
 CASE S.CODE0:
 CASE S.CODE1:
 CASE S.CODE2:
 CASE S.CODE3:
 CASE S.CODE4:
 CASE S.BCPLF:
 CASE S.BCPLR:
 CASE S.BCPLV:
 S0, S1 := "%A", H2!X
 GOTO L2
 CASE S.TUPLE:
 S0, S1 := "#%N-tuple#", H3!X-Y0
 GOTO L2
 CASE S.XTUPL:
 S0, S1 := "#%N-xtuple#", H3!X-Y0
 GOTO L2
 CASE S.POLY: S0, S1 := "#poly%N#", H3!X-Y0
 GOTO L2
 CASE S.POLYJ:
 S0, S1 := "#term%N#", H3!X-Y0
 GOTO L2
 CASE S.CDX:
 CASE S.CDY: S0, S1 := "#hcode(%P)#", H3!X
 GOTO L2
 CASE S.CDZ: S0 := "#codez(%P)#"
 IF FALSE
 CASE S.CD:  S0 := "#code(%P)#"
 S1 := H2!X
 GOTO L2
 CASE S.NAME: X := H2!X
 IF FALSE
 CASE S.GLZ:
 CASE S.GLG:
 CASE S.GLO: WCH ('.')
 X := H1!X
 CASE S.STRING:
 PRS (X, WCH)
 RESULTIS A
 CASE S.GENSY:
 S0, S1 := "#G%N", H2!X-Y0
 L2:            WRITEF (S0, S1)
 RESULTIS A
 CASE S.CLOS:
 CASE S.ACLOS:
 CASE S.CLOS2:
 CASE S.ECLOS:
 CASE S.FCLOS:
 S0 := "#fn#"
 GOTO L1
 CASE S.JCLOS:
 S0 := "#jfn#"
 GOTO L1
 CASE S.KCLOS:
 S0 := "#kfn#"
 GOTO L1
 CASE S.E: S0 := "#env#"
 GOTO L1
 CASE S.J: S0 := "#jval#"
 L1:            WRITES (S0)
 RESULTIS A
 $)
 $) REPEAT
 $)
 
 
AND PRS (S, F) BE
 IF S>0 & !S=S.STRING
 $( FOR I=STR1 TO STR2
 $( LET B = GETBYTE (S, I)
 IF B=0
 RETURN
 F (B) $)
 S := H1!S $) REPEATUNTIL S=Z
 
 
AND PRINS (S) BE
 PRS (S, WCH)
 
 
AND PRINS1 (S, C) BE
 $( WCH (C)
 PRS (S, WCH1)
 WCH (C) $)
 
 
AND PRCH (C) = VALOF
 $( WCH (C-Y0)
 RESULTIS C $)
 
 
AND PRNUM (P) BE
 $( LET F, Q = WRITEN, Z
 IF P>=YSG
 WCH ('-')
 $( LET T = H1!P
 IF T=Z
 BREAK
 H1!P := Q
 Q, P := P, T $) REPEAT
 UNLESS H2!P=0
 $( WRITEN (H2!P)
 F := WRITEL $)
 F (H3!P, NUMWI)
 UNTIL Q=Z
 $( $( LET T = H1!Q
 H1!Q := P
 P, Q := Q, T $)
 WRITEL (H2!P, NUMWI)
 WRITEL (H3!P, NUMWI) $)
 $)
 
 
AND PRFPL (N) BE
 $( LET E, L = H2!N, H3!N
 MSG1 (26, "prfpl") $)
 
 
AND PRINPOLY (P, F, B, C) BE    // F -> minus pending
 $( IF P<=0
 $( TEST F
 WRITEN (Y0-P)
 OR WRITEN (P-Y0)
 RETURN $)
 TEST !P=S.RATP
 $( IF B
 WCH ('(')
 PRINPOLY (H2!P, F, TRUE, FALSE)
 WCH ('/')
 PRINPOLY (H1!P, FALSE, TRUE, FALSE) $)
 OR TEST !P=S.POLY
 $( LET A, S0, S1 = H2!P, ZERO, "- " | SIGNBIT  // ??B??
 F := F NEQV (P>=YSG)
 P := H1!P
 TEST H1!P=Z
 B := FALSE
 OR IF B
 WCH ('(')
 $( LET P2, Y = H2!P, H3!P>Y0
 TEST C
 S0, S1 := " + " | SIGNBIT, " - " | SIGNBIT    // ??B??
 OR C := TRUE
 F := F NEQV (P>=YSG)
 TEST P2<=0
 TEST P2<Y0
 $( WRITES (F -> S0, S1)
 TEST P2=YM & Y
 GOTO L
 OR WRITEN (Y0-P2) $)
 OR $( WRITES (F -> S1, S0)
 TEST P2=Y1 & Y
 GOTO L
 OR WRITEN (P2-Y0) $)
 OR TEST !P2=S.POLY | !P2=S.RATP
 TEST Y
 TEST H1!(H1!P2)=Z  // -> P2 is poly
 PRINPOLY (P2, F, FALSE, S0~=ZERO)
 OR $( WRITES (S0)
 PRINPOLY (P2, F, TRUE, FALSE) $)
 OR PRINPOLY (P2, F, FALSE, FALSE)
 OR $( WRITES (F -> S1, S0)       // ??P?? Not yet got right
 PRC (P2, 30+Y0) $)
 IF Y
 $( WCH ('**')
 L:       PRC (A, 50+Y0)
 UNLESS H3!P=Y1
 $( WCH ('^')
 WRITEN (H3!P-Y0) $) $)
 P := H1!P
 $) REPEATUNTIL P=Z
 $)
 OR $( IF B
 WCH ('(')
 IF F
 WCH ('-')        // ??P?? This is wrong too
 PRC (P,Y0) $)
 IF B
 WCH (')')
 $)
 
 
AND PCODE (A) BE
 $( KK, NN := 0, SIGNBIT
 PCODE1 (A)
 UNTIL KK=0
 $( LET T = !KK & P.ADDR
 !KK := S.CD
 KK := T $) $)
 
 
AND PCODE1 (A) BE
 $( ZTAB (20)
 WCH ('#')
 $( LET A0, A2, A3 = !A, H2!A, H3!A
 UNLESS A0=S.CD
 $( IF A0>0
 $( MSG0 (3, A0)
 RETURN $)
 WRITEF (" ...%N", (A0 & P.TAGP)>>24)
 RETURN $)
 IF A3=LL.ZC
 $( WCH ('Q')
 RETURN $)
 NN := NN+(P.ADDR+1)
 !A := NN+(KK & P.ADDR)
 KK := A
 FOR I=@LL.ZC TO @LL.ZC+OCMSZ
 IF A3=!I
 $( S0 := I-@LL.ZC+OCM
 GOTO L0 $)
 WRITEARG (A3)
 GOTO L1
 L0: FOR I=0 TO 3
 WCH (GETBYTE (S0, I))
 WCH (' ')
 TEST A2>0 & (!A2=S.CD | !A2<0)
 $( WCH ('(')
 PCODE1 (A2)
 WCH (')') $)
 OR PRIN (A2)   // ?P FOR NOW
 $)
 L1:  A := H1!A
 $) REPEATUNTIL A=Z
 
 
AND PRINCLO (A) BE
 $( PRIN (A)
 $( WCH (' ')
 PRINBV (H2!A)
 A := H3!A $) REPEATWHILE TYV (A)=A.FCLOS
 WRITES (" . ")
 PRC (A, Y2) $)
 
 
AND PRINBV (A) BE
 TEST A>0 & !A=S.TUPLE
 PRINPARS (PRINT0, A, PRINBV)
 OR PRC (A, 9+Y0)
 
 
AND PRINL (L) = VALOF
 $( IF L>0
 $( IF !L=S.TUPLE
 $( LET P, C = L, '('+SIGNBIT
 IF @L>STACKL
 WRITES ("#etc#") <> RESULTIS L
 $( WCH (C)
 C := '*S'+SIGNBIT
 PRINL (H2!P)
 P := H1!P $) REPEATUNTIL P=Z
 WCH (')')
 RESULTIS L $)
 IF L>=YLOC | !L=S.XTUPL
 L := H1!L <> LOOP
 $)
 RESULTIS PRINT (L)
 $) REPEAT
 
 
// H3 := +ve; EVAL of such tuples is undefined, but should be safe
 
 
AND PRINT0 (P, F) BE    // P is a tuple
 $( LET N, Q = H3!P, Z
 IF @P>STACKL
 WRITES ("#etc#") <> RETURN
 $( N := N-1
 IF H3!P>=0
 $( WRITES ("#loop#")
 IF Q=Z
 RETURN
 BREAK $)
 H3!P := Q
 Q, P := P, H1!P $) REPEATUNTIL P=Z
 $( N := N+1
 F (H2!Q)       // before unlinking
 P := H3!Q
 H3!Q := N
 IF P=Z
 RETURN
 Q := P
 WRITES (", ") $) REPEAT
 $)
 
 
AND PRINT (A) = VALOF
 $( IF A>0
 SWITCHON !A INTO
 $(
 CASE S.LOC:
 CASE S.XTUPL:
 A := H1!A
 LOOP
 CASE S.TUPLE:
 PRINPARS (PRINT0, A, PRINT)
 RESULTIS A
 CASE S.STRING:
 PRS (A, WCH)
 RESULTIS A
 DEFAULT: PRC (A, Y0)
 RESULTIS A
 $)
 RESULTIS PRIN (A)
 $) REPEAT
 
 
AND PRC (C, B) BE
 $( IF @C>STACKL
 $( WRITES ("#etc#")
 RETURN $)
 $(P IF C>0
 $( SWITCHON !C INTO
 $(
 DEFAULT: PRIN (C)
 CASE S.UNSET1:
 RETURN
 CASE S.NUMJ: PRNUM (C)
 RETURN
 CASE S.RATN:
 CASE S.RATL: B := B>30+Y0
 IF B
 WCH ('(')
 PRC (H2!C, Y0)
 WCH ('/')
 PRC (H1!C, Y0)
 ENDCASE
 CASE S.RATP:
 CASE S.POLY: PRINPOLY (C, FALSE, B>=25+Y0, FALSE)
 RETURN
 CASE S.POLYJ:
 WRITES ("#term[")
 !ZU, H1!ZU, H2!ZU := S.POLY, C, ZJ      // fake a poly
 PRINPOLY (ZU, FALSE, FALSE, FALSE)
 H1!ZU := Z
 WCH (']')
 RETURN
 CASE S.STRING:
 PRINS1 (C, '*"')
 RETURN
 CASE S.GLG: APPLY (H1!C, H2!C)
 RETURN
 CASE S.XTUPL:
 WRITES ("#xtuple#")
 PRC (H2!C, 48+Y0)
 C := H1!C
 CASE S.TUPLE:
 B := B>8+Y0
 IF B
 WCH ('(')
 $( PRC (H2!C, 9+Y0)
 C := H1!C
 IF C=Z
 ENDCASE
 WRITES (", ") $) REPEAT
 CASE S.TRA: WRITES ("#trace#")
 C := H2!C
 LOOP
 CASE S.LOC: C := H1!C
 LOOP
 CASE S.COLON:
 WCH ('[')
 PRIN (H1!C)
 WCH (':')
 PRC (H3!C, Y0)
 WCH (']')
 C := H2!C
 LOOP
 CASE S.CDZ: WRITEF ("*N#codez %P", H2!C)
 IF FALSE
 $(
 CASE S.CDX:
 CASE S.CDY:    WRITES ("*N#hcode# ")
 PRINBV (H3!C) $)
 C := H1!C
 IF FALSE
 CASE S.CD:  NEWLINE ()
 PCODE (C)
 NEWLINE ()
 RETURN
 CASE S.CLOS:
 CASE S.ACLOS:
 CASE S.CLOS2:
 CASE S.ECLOS:
 CASE S.FCLOS:
 TEST B>Y2
 PRINPARS (PRINCLO, C)
 OR PRINCLO (C)
 RETURN
 CASE S.REC:
 CASE S.RECA: B := B>Y2
 IF B
 WCH ('(')
 WRITES ("REC ")
 PRINBV (H2!C)
 C := H1!C
 WHILE TYV (C)=A.FCLOS
 $( WCH (' ')
 PRINBV (H2!C)
 C := H3!C $)
 WRITES (" . ")
 PRC (C, Y2)
 ENDCASE
 CASE S.LET:
 CASE S.LETA:
 CASE S.LETB: B := B>Y1
 IF B
 WCH ('(')
 WRITES ("LET ")
 PRINBV (H2!C)
 $( LET C3 = H3!C
 WHILE TYV (C3)=A.FCLOS
 $( WCH (' ')
 PRINBV (H2!C3)
 C3 := H3!C3 $)
 WRITES (" = ")
 PRC (C3, Y1) $)
 UNLESS H1!C=ZE
 WRITES (" IN ") <> PRC (H1!C, Y1)
 ENDCASE
 CASE S.COND:
 CASE S.CONDA:
 CASE S.CONDB:
 B := B>10+Y0
 IF B
 WCH ('(')
 PRC (H1!C, 10+Y0)
 WRITES (" -> ")
 PRC (H2!C, 10+Y0)
 C := H3!C
 UNLESS C=Z
 $( WRITES (", ")
 PRC (C, 10+Y0) $)
 ENDCASE
 CASE S.SEQ:
 CASE S.SEQA: $( LET P = Y2
 TEST B>9+Y0
 B := TRUE
 OR $( IF B>Y2
 P := 9+Y0
 B := FALSE $)
 IF B
 WCH ('(')
 PRC (H1!C, P+1)
 WRITES (P=Y2 -> "; ", " <> ")
 PRC (H2!C, P)
 ENDCASE
 $)
 CASE S.E: WCH ('E')
 RETURN
 CASE S.J: WCH ('J')
 RETURN
 CASE S.RETU: B := B>35+Y0
 IF B
 WCH ('(')
 PRINS (H1!TYV (C))
 WCH (' ')
 PRC (H2!C, 35+Y0)
 ENDCASE
 CASE S.QU:
 CASE S.AA:
 CASE S.ZZ: B := B>35+Y0
 IF B
 WCH ('(')
 PRINS (H1!TYV (C))
 PRC (H2!C, 35+Y0)
 ENDCASE
 CASE S.AA2:
 CASE S.A2A:
 CASE S.AP2:
 CASE S.A2E: $( LET C1, S = H2!C, H1!C
 IF H3!S<0
 $( S0 := GETBYTE (S, 12) & 127    // IF S0=0, probably FOR
 B := B>(S0 & 63)+Y0
 IF B
 WCH ('(')
 $( LET B1 = S0>63 | S0<6
 PRC (H2!C1, GETBYTE (S, 13)+Y0)
 (B1 -> PRINS1, PRINS)(H1!S, ' ')
 PRC (H2!(H1!C1), GETBYTE (S, 14)+Y0)
 ENDCASE $) $)
 B := B>10+Y0
 IF B
 WCH ('(')
 PRC (H2!C1, 11+Y0)
 WRITES (" %")
 PRC (S, 50+Y0)       // ??C??
 WCH (' ')
 PRC (H2!(H1!C1), 11+Y0)
 ENDCASE
 $)
 CASE S.APZ:
 CASE S.APPLY:
 CASE S.APPLE:
 CASE S.AA1:
 CASE S.A1A:
 CASE S.AP1:
 CASE S.A1E:
 CASE S.APV:
 CASE S.AVE:
 CASE S.AAA:
 CASE S.AEA:
 CASE S.APQ:
 CASE S.AQE: B := B>38+Y0
 IF B
 WCH ('(')
 PRC (H1!C, 38+Y0)
 WCH (' ')
 PRC (H2!C, 41+Y0)
 ENDCASE
 CASE S.DASH: B := B>39+Y0
 IF B DO
 WCH ('(')
 PRC (H1!C, 36+Y0)
 FOR I=Y1 TO H2!C
 WCH ('*'')
 ENDCASE
 $)
 IF B
 WCH (')')
 RETURN
 $)
 PRIN (C)
 RETURN
 $)P REPEAT
 $)
 
 
AND PRINTA (C) = VALOF
 PRC (C, Y0) <> RESULTIS C
 
 
.
//./       ADD LIST=ALL,NAME=PALM2
 SECTION "PALM2"
 
 
GET "PALHDR"
 
 
LET PRINK (F, P, N) = VALOF
 $( STATIC
 $( G = 0 $)
 LET W0 (C) BE
 G := G-1
 LET W1, W2 = -WRC, -CHC
 WRC := W0
 G := G.POSINT (N)
// WE MUST DO THE WHOLE LOT WITHOUT LONGJUMP, BECAUSE SOME
// PRINT ROUTINES MANGLE STRUCTURE
 F (P)
 WRC, CHC := -W1, -W2
 TEST G>=Y0
 F (P) <> RESULTIS TRUE
 OR RESULTIS FALSE
 $)
 
 
AND PRINE (E) = VALOF
 $( IF E>0 & !E=S.E
 $( LET F = PRINT
 UNLESS PARAMC
 F := PRIN
 WRITES ("*N*N environment:")
 IF E=ZE
 $( WRITES (" empty*N")
 RESULTIS E $)
 FOR I=Y0 TO Y0+8
 $( IF E=ZE
 BREAK
 WRITEF ("*N%P%Z", H3!E, 15)
 F (H2!E)
 E := H1!E $)
 WRITES (E=ZE -> "*N end of environment*N", "*N etc*N")
 $)
 RESULTIS E
 $)
 
 
AND PRINJ (J) = VALOF   // ??C??
 $( WRITES ("*N*N Pal backtrace:")
 UNLESS TYV (J)=ZJ & J~=ZJ
 $( WRITES (" empty*N")
 RESULTIS Z $)
 FOR I=Y0 TO Y0+8
 $( UNLESS TYV (J)=ZJ & J~=ZJ
 GOTO L
 PRINE (H1!J)
 $( LET K = H3!J
 IF TYV (K)=ZJ
 PRIND (K) $)
 J := H2!J $)
 WRITES ("*N etc")
 L:   WRITES ("*N end of backtrace*N")
 RESULTIS J
 $)
 
 
AND PRIND (F) = VALOF
 $( LET G = PRINTA
 UNLESS PARAMC
 G := PRIN
 WRITES ("*N stack frame:")
 FOR I=Y0 TO Y0+8
 $( UNLESS TYV (F)=ZJ
 GOTO N
 WRITEF ("*N cell %E%Zand %E", G, H3!F, 15, G, H2!F)
 F := H1!F $)
 WRITES ("*N etc")
 N: WRITES ("*N end of frame*N")
 $)
 
 
AND SHOW (A) = VALOF
 TEST !((-2)!(@A)>>2)=EVAL
 $( GW0, GW1, GW2 := SHOW1, A, A
 LONGJUMP (FLEVEL (EVAL), LL.EX) $)
 OR $( LET B = EVAL (A)
 RESULTIS SHOW1 (B, A) $)
 
 
AND SHOW1 (A, F) = VALOF
 $( WRITEF ("*N*N%E%Y%E", PRINTA, F, 15, PRINT, A)
 RESULTIS A $)
 
 
.
//./       ADD LIST=ALL,NAME=PALM3
 SECTION "PALM3"
 
 
GET "PALHDR"
 
 
STATIC
 $( C0 = 0 $)
 
 
LET LINKWORD (N, A, A2, A3) = VALOF
 $( LET G = @ROOT | SIGNBIT   // ??B??
 N, C0 := -N, 0
 UNTIL C0!G=Z
 G, C0 := C0!G, COMPL (A, H1!(H2!G))+2 <>
 IF C0=2
 RESULTIS G  // found
 A := GET4 (-N, A, A2, A3)
 C0!G := GET4 (S.NAME, Z, A, Z)
 RESULTIS C0!G $)
 
 
AND FINDWORD (A) = VALOF
 $( LET G = @ROOT | SIGNBIT   // ??B??
 C0 := 0
 UNTIL C0!G=Z
 G, C0 := C0!G, COMPL (A, H1!(H2!G))+2 <>
 IF C0=2
 RESULTIS G
 RESULTIS 0 $)
 
 
AND PUTWORD (B) = VALOF
 $( LET A, G = H1!B, @ROOT | SIGNBIT  // ??B??
 C0 := 0
 UNTIL C0!G=Z
 G, C0 := C0!G, COMPL (A, H1!(H2!G))+2 <>
 IF C0=2
 MSG1 (13, PUTWORD)
 C0!G := GET4 (S.NAME, Z, B, Z)
 RESULTIS C0!G $)
 
 
AND STOV (S, V, M) = VALOF
 $( LET S1, N = S, 0
 IF S1>0 & !S1=S.STRING
 $( FOR I=STR1 TO STR2
 $( LET B = GETBYTE (S1, I)
 IF B=0
 GOTO L
 IF N>=M
 MSG1 (5, S) <> GOTO L
 N := N+1
 V!N := B $)
 S1 := H1!S1 $) REPEATUNTIL S1=Z
 L: !V := N
 RESULTIS V
 $)
 
 
AND TTOV (A, V, M) = VALOF
 $( LET A1 = A
 !V := 0
 IF A1>0 & !A1=S.TUPLE
 $( LET L = H3!A1-Y0
 IF L>M
 MSG1 (5, A) <> RESULTIS V
 FOR I=L TO 1 BY -1
 V!I := RVV (H2!A1) <> A1 := H1!A1
 !V := L $)
 RESULTIS V
 $)
 
 
AND COMPL (A, B) = VALOF        // A<B -> -1, A=B -> 0, A>B -> 1
 $( TEST H2!A<H2!B
 RESULTIS -1
 OR UNLESS H2!A=H2!B
 RESULTIS 1
 TEST H3!A<H3!B
 RESULTIS -1
 OR UNLESS H3!A=H3!B
 RESULTIS 1
 A, B := H1!A, H1!B
 IF A=B
 RESULTIS 0
 IF A=Z
 RESULTIS -1
 IF B=Z
 RESULTIS 1
 $) REPEAT
 
 
.
//./       ADD LIST=ALL,NAME=PALM4
 SECTION "PALM4"
 
 
GET "PALHDR"
 
 
LET SEL1 (A) = H1!A
 
 
AND SEL2 (A) = H2!A
 
 
AND G.POSINT (N) = VALOF
 $( MANIFEST
 $( YZ = Y0+NUMBA $)
 IF Y0<N<YZ
 RESULTIS N
 IF N>=YLOC
 N := H1!N <> LOOP
 MSG1 (29, N) $) REPEAT
 
 
AND G.NP (A, T) = VALOF
 $( UNLESS A>0 & !A=T
 $( IF A>=YLOC
 A := H1!A <> LOOP
 MSG1 (22, A) $)
 RESULTIS A $) REPEAT
 
 
AND G.NT (A, N) = VALOF
 $( UNLESS A>0 & !A=S.TUPLE & H3!A=N
 $( IF A>=YLOC | A>0 & !A=S.XTUPL
 A := H1!A <> LOOP
 MSG1 (28, A, N) $)
 RESULTIS A $) REPEAT
 
 
AND LVV (P) = P>=YLOC -> P, GET4 (S.LOC, P, 0, 0)+YLOC
 
 
AND RVV (P) = P>=YLOC -> H1!P, P
 
 
LET TYV (P) = VALOF
 $( IF P>0
 RESULTIS TYP!!P
 IF P>=-1
 RESULTIS P
 RESULTIS A.NUM $)
 
 
AND HDV (P) = VALOF
 $( IF P>0 & !P>=MM3
 RESULTIS H2!P
 RESULTIS Z $)
 
 
AND MIV (P) = VALOF
 $( IF P>0 & !P>=MM3
 RESULTIS H3!P
 RESULTIS Z $)
 
 
AND TLV (P) = VALOF
 $( IF P>0
 RESULTIS H1!P
 RESULTIS Z $)
 
 
AND NULL (P) = P=Z
 
 
AND IV (A) = A
 
 
AND ORDER (P) = VALOF
 $( IF P<=0
 TEST P=Z
 RESULTIS Y0
 OR RESULTIS Y1
 IF !P=S.TUPLE
 RESULTIS H3!P
 RESULTIS Y1 $)
 
 
AND LMAP (F, A) = VALOF
 $( F := F | SIGNBIT
 $( F (H2!A)
 A := H1!A $) REPEATUNTIL A=Z
 RESULTIS Z $)
 
 
AND LMAPL (F, A) = VALOF
 $( LET Q = Z
 F := F | SIGNBIT
 $( LET T = F (H2!A)
 Q := AUG (Q, T)
 A := H1!A $) REPEATUNTIL A=Z
 RESULTIS Q $)
 
 
AND LMAPT (F, N) = VALOF
 $( LET M, Q = Y1, Z
 UNTIL M>N
 $( LET T = APPLY (F, M)
 Q := AUG (Q, T)
 M := M+1 $)
 RESULTIS Q $)
 
 
AND DOFOR (V, P) = VALOF        // ?-
 $( UNLESS V>0 & !V=S.TUPLE
 RESULTIS APPLY (P, V)
 $( LET I, W = Y1, H2!V
 TEST H3!V=Y3
 $( V := H1!V
 I := H2!V $)
 OR UNLESS H3!V=Y2
 MSG1 (16, DOFOR, V)
 V := H2!(H1!V)
 $( LET F = POSITIVE (I)
 UNTIL F -> GTV (V, W), GTV (W, V)
 $( APPLY (P, V)
 V := ADD (I, V) $) $)
 RESULTIS Z
 $)
 $)
 
 
AND AUG (P, Q) = VALOF
 $( IF P<=0
 $( IF P=Z
 RESULTIS GET4 (S.TUPLE, Z, Q, Y1)
 GOTO L $)
 IF !P=S.TUPLE
 RESULTIS GET4 (S.TUPLE, P, Q, H3!P+1)
 IF P>=YLOC | !P=S.XTUPL
 $( P := H1!P
 LOOP $)
 IF P=ZSY
 RESULTIS GET4 (S.TUPLE, P, Q, Y1)
 L:   MSG1 (24, P)
 RESULTIS Z
 $) REPEAT
 
 
AND ISV (P, Q) = P=Q
 
 
AND ASSG (P, Q) = VALOF
 $( IF Q>=YLOC
 Q := H1!Q
 IF P>=YLOC
 $( H1!P := Q
 RESULTIS P $)
 IF P>0 & !P=S.TUPLE
 $( UNLESS Q>0 & !Q=S.TUPLE & H3!Q=H3!P
 MSG1 (6, P, Q)
 $( LET N = H3!Q
 $( LET T = Q
 $( H3!T := RVV (H2!T)
 T := H1!T $) REPEATUNTIL T=Z $)
 FOR I=N TO Y1 BY -1
 $( ASSG (H2!P, H3!Q)
 H3!Q := I
 P, Q := H1!P, H1!Q $)
 RESULTIS Z $)
 $)
 MSG1 (12, P, Q)
 $)
 
 
AND REV (P) = VALOF
 $( IF P>0 & !P=S.TUPLE
 $( LET Q, L = Z, Y1
 Q, L, P := GET4 (S.TUPLE, Q, H2!P, L), L+1, H1!P REPEATUNTIL P=Z
 RESULTIS Q $)
 RESULTIS Z $)
 
 
AND REVD (P) = VALOF    // Destructive reverse: P is a tuple
 $( LET Q, L = Z, Y1
 $( LET T = H1!P
 H1!P, H3!P := Q, L
 IF T=ZSY
 RESULTIS P
 Q, P := P, T
 L := L+1 $) REPEAT $)
 
 
LET GETV (S) = G.GET (FINDINPUT, S, ZERO)
 
 
AND GETMV (S1, S2) = G.GET (INPUTMEMBER, S1, S2)
 
 
AND G.GET (R, S1, S2) = VALOF
 $( R := STREAM (R, S1, S2)
 UNLESS R=Y0
 $( S1, S2 := -Q.INPUT, -RCH
 Q.SELINPUT (R-Y0)
 RCH := RCH0
 RP ()
 Q.SELINPUT (-S1)
 RCH := -S2
 IF RCH=RCH1
 WCH (' ') $)
 RESULTIS ZSC
 $)
 
 
AND GETEX (S) = VALOF
 $( S := STREAM (FINDINPUT, S, ZERO)
 UNLESS S=Y0
 $( LET S1, S2 = -Q.INPUT, -RCH
 Q.SELINPUT (S-Y0)
 RCH := RCH0
 S := READX ()
 Q.SELINPUT (-S1)
 RCH := -S2
 IF RCH=RCH1
 WCH (' ') $)
 RESULTIS S
 $)
 
 
AND XTUPLE (P) = GET4 (S.XTUPL, Z, P, Y0)
 
 
AND FIND (N, E) = VALOF
 $( E := G.NP (E, S.E)
 IF N>=YLOC
 N := H1!N
 $( IF EQLV (H3!E, N)
 RESULTIS H2!E
 E := H1!E $) REPEATUNTIL E=Z
 RESULTIS Z $)
 
 
AND PUT (N, V, E) = VALOF
 $( UNLESS E>=YLOC & G.NP (E, S.E)~=Z
 $( MSG1 (16, PUT, E)
 RESULTIS Z $)
 H1!E := GET4 (S.E, H1!E, V, N)
 RESULTIS V $)
 
 
.
//./       ADD LIST=ALL,NAME=PALM5
 SECTION "PALM5"
 
 
GET "PALHDR"
 
 
STATIC
 $( V = 0 $)
 
 
LET CODE (N) = VALOF    // ??C??
 $( LET F = (@G0)!(N-Y0)
 LET G = (F & P.ADDR)>>2
 UNLESS VALIDENTRY (G)
 MSG1 (17, CODE, N)
 $( LET S = NARGS (G)
 TEST S>4
 S := S.CODE4
 OR S := S.CODE0+S
 RESULTIS GET4 (S, 0, F | SIGNBIT, F<0) $) $)
 
 
AND BCPLF (N) = VALOF
 $( LET F = (@G0)!(N-Y0)
 RESULTIS GET4 (S.BCPLF, 0, F | SIGNBIT, F<0) $)
 
 
AND BCPLR (N) = VALOF
 $( LET F = (@G0)!(N-Y0)
 RESULTIS GET4 (S.BCPLR, 0, F | SIGNBIT, F<0) $)
 
 
AND BCPLV (N) = VALOF
 $( LET F = (@G0)!(N-Y0)
 RESULTIS GET4 (S.BCPLV, 0, F | SIGNBIT, F<0) $)
 
 
AND CALLBCPL (F) = VALOF
 $( V := BUFFP
 TEST H3!F
 F := H2!F
 OR F := H2!F & P.ADDR
 V := TRANSBCPL (ARG1, BUFFP+BUFFL)
 UNLESS ARG1>0 & !ARG1=S.TUPLE
 RESULTIS F (V)
 FOR I=5 TO !BUFFP
 (@F+FR.CALLBCPL)!I := BUFFP!I
 RESULTIS F (BUFFP!1, BUFFP!2, BUFFP!3, BUFFP!4)
 $)
 
 
AND TRANSBCPL (A, N) = VALOF
 $(S IF A<=0
 $( IF ABS (A-Y0)<NUMBA
 RESULTIS A-Y0
 RESULTIS A $)
 SWITCHON !A INTO
 $(
 CASE S.XTUPL:
 CASE S.LOC: A := H1!A
 LOOP
 DEFAULT: RESULTIS A
 CASE S.RDS:
 CASE S.WRS: RESULTIS H2!A-Y0
 CASE S.FLT:
 CASE S.CODEV:
 CASE S.CODE0:
 CASE S.CODE1:
 CASE S.CODE2:
 CASE S.CODE3:
 CASE S.CODE4:
 CASE S.BCPLF:
 CASE S.BCPLR:
 CASE S.BCPLV:
 CASE S.QU: RESULTIS H2!A
 CASE S.NUMJ: IF H1!A=Z
 $( LET T = H2!A*NUMBA
 IF T/NUMBA=H2!A
 $( T := T+H3!A
 IF T>=NUMBA | T=SIGNBIT
 TEST A<YSG
 RESULTIS T
 OR RESULTIS -T $) $)
 MSG1 (37, A)
 CASE S.STRING:
 $( LET U = V
 LET L = PACKSTRING (STOV (A, U, N-U), U)
 V := U+L+1
 RESULTIS U $)
 CASE S.TUPLE:
 $( LET U, L = V, H3!A-Y0
 IF @L>STACKL
 STKOVER ()
 IF U+L>N
 MSG1 (5, A) <> L := N-U
 V := U+L+1
 FOR I=L TO 1 BY -1
 U!I := TRANSBCPL (H2!A, N) <>
 A := H1!A
 !U := L
 RESULTIS U
 $)S REPEAT
 
 
AND TRANSPAL (A) = VALOF
 $( IF A=SIGNBIT
 $( A := TRANSPAL (SIGNBIT/2)
 RESULTIS ADD (A, A) $)
 IF ABS A<NUMBA
 RESULTIS A+Y0
 TEST A<0
 A, V := -A, YSG
 OR V := 0
 RESULTIS GETX (S.NUMJ, Z, A/NUMBA, A REM NUMBA)+V $)
 
 
LET TEMPUS (A) = VALOF
 $( WRITEF ("*N*N# Tempus fugit (%P) after %V+%V s*N*N",
 A, TIME ()-RTIME, RTIME)
 RESULTIS A $)
 
 
AND ERROR (A) = VALOF
 $( WRITES ("*N*N# Error: ")
 PRINT (A)
 MSG1 (0)
 RESULTIS Z $)
 
 
AND ERRORSET (S) = VALOF
 $( ERZ := S
 RESULTIS S $)
 
 
AND NUM (A) = VALOF
 $( IF A<-1
 RESULTIS TRUE
 RESULTIS TYV (A)=A.NUM $)
 
 
AND RAT (A) = VALOF
 $( IF A<=0
 RESULTIS FALSE
 IF S.RATN<=!A<=S.RATP
 RESULTIS TRUE
 RESULTIS FALSE $)
 
 
AND MAINVAR(A) = VALOF $( UNLESS ARITHV(A)
 MSG1(16,MAINVAR,A)
 IF A<=0 RESULTIS Z
 IF !A=S.RATP
 A := H1!A
 IF !A=S.POLY RESULTIS H2!A
 RESULTIS Z $)
 
AND ATOM (A) = VALOF
 $( IF A<=0
 RESULTIS TRUE
 RESULTIS !A<=S.GLO $)
 
 
AND TUPLE (A) = VALOF
 $( IF A<=0
 RESULTIS A=Z   // ??Z??
 RESULTIS !A=S.TUPLE $)
 
 
AND FUNCTION (A) = VALOF
 $( IF A<=0
 RESULTIS FALSE
 IF S.CLOS<=!A<=S.KCLOS
 RESULTIS TRUE
 RESULTIS FALSE $)
 
 
AND SYN (A) = VALOF
 $( IF A<=0
 RESULTIS FALSE
 IF S.REC<=!A<=S.ZZ
 RESULTIS TRUE
 RESULTIS FALSE $)
 
 
STATIC
 $( C0 = 0
 C1 = 0
 C2 = 0 $)
 
 
LET NUMBER (V) = VALOF
 $( MANIFEST
 $( NW2 = 2*NUMWI $)
 STATIC
 $( N = 0
 M = 0 $)
 C0, V := V & P.ADDR, Z
 C2 := C0+!C0
 $( IF C0>=C2
 RESULTIS Y0
 C0 := C0+1 $) REPEATWHILE !C0='0'
 C1 := C0+(C2-C0+1) REM NW2
 UNLESS C0=C1
 $( N, M := 0, 0
 UNTIL C0>=C1-NUMWI
 N := N*10+!C0-'0' <> C0 := C0+1
 UNTIL C0=C1
 M := M*10+!C0-'0' <> C0 := C0+1
 IF C0>C2 & N=0
 RESULTIS M+Y0
 V := GETX (S.NUMJ, Z, N, M) $)
 UNTIL C0>C2
 $( N, M := 0, 0
 C1 := C0+NUMWI
 UNTIL C0=C1
 N := N*10+!C0-'0' <> C0 := C0+1
 C1 := C0+NUMWI
 UNTIL C0=C1
 M := M*10+!C0-'0' <> C0 := C0+1
 V := GETX (S.NUMJ, V, N, M) $)
 RESULTIS V
 $)
 
 
AND STRING (V) = VALOF
 $( LET G = ZS
 LET GG = @V | SIGNBIT     // ??B?? GG=@G-1
 C1 := MAXINT
 FOR I=SIGNBIT+1 TO SIGNBIT+!V
 $( IF C1>STR2
 C1, H1!GG, GG := STR1, GETX (S.STRING, ZSY, 0, 0), H1!GG
 PUTBYTE (GG, C1, V!I)
 C1 := C1+1 $)
 UNLESS G=ZS
 H1!GG := Z
 RESULTIS G
 $)
 
 
AND NAME (A) = VALOF
 $( IF A>0 & !A=S.STRING
 RESULTIS LINKWORD (S.GLZ, A, ZSY, Z)
 MSG1 (16, NAME, A)
 RESULTIS Z $)
 
 
AND GENSYM () = VALOF
 $( GENSYMN := GENSYMN+1
 RESULTIS GET4 (S.GENSY, 0, GENSYMN, 0) $)
 
 
AND ASYM (N) = GET4 (S.GENSY, 0, N, 0)
 
 
AND GLOBA (A) = H2!NAME (A)
 
 
AND GENGLO (N, V) = VALOF
 $( IF N<0
 MSG1 (16, GENGLO, N)
 RESULTIS GET4 (S.GLG, N, V, Z) $)
 
 
.
//./       ADD LIST=ALL,NAME=PALM6
 SECTION "PALM6"
 
 
GET "PALHDR"
 
 
MANIFEST
 $( NY0 = -Y0 $)
 
 
STATIC
 $( GA1 = 0
 GA2 = 0
 GA3 = 0
 GA4 = 0 $)
 
// RATN:   A | (B>0)
 
 
LET NEG (P) = VALOF
 $( IF P<=0
 $( IF P>=-1
 TEST P=0
 RESULTIS Y0
 OR RESULTIS YM
 RESULTIS SIGNBIT-P $)
 SWITCHON !P INTO
 $(
 CASE S.LOC: P := H1!P
 LOOP
 CASE S.FPL: MSG1 (14)
 CASE S.NUMJ:
 CASE S.POLY: RESULTIS P NEQV YSG
 CASE S.RATN: RESULTIS GET4 (S.RATN, H1!P, SIGNBIT-H2!P, 0)
 CASE S.RATL:
 CASE S.RATP: $( LET T = NEG (H2!P)
 RESULTIS GET4 (!P, H1!P, T, H3!P) $)
 CASE S.FLT: RESULTIS GETX (S.FLT, 0,  #- H2!P, 0)
 DEFAULT: RESULTIS ARITHFN (Y0, P, A.MINU)
 $)
 $) REPEAT
 
 
AND POSITIVE (P) = VALOF
 $( IF P<=0
 RESULTIS P>=Y0
 SWITCHON !P INTO
 $(
 CASE S.LOC: P := H1!P
 LOOP
 CASE S.FPL: MSG1 (14)
 CASE S.RATN: RESULTIS H2!P>=Y0
 CASE S.NUMJ: RESULTIS P<YSG
 CASE S.RATL: P := H2!P
 LOOP
 CASE S.FLT: RESULTIS H2!P #>= 0.0
 DEFAULT: MSG1 (16, POSITIVE, P)
 RESULTIS Z
 $)
 $) REPEAT
 
 
AND RECIP (P) = VALOF
 $( IF P<=0
 $( IF P>=-1
 TEST P=0
 P := Y0
 OR RESULTIS Y1
 IF P<=Y0
 $( IF P=Y0
 MSG1 (7) <> RESULTIS Z
 IF P=YM
 RESULTIS YM
 RESULTIS GET4 (S.RATN, SIGNBIT-P, YM, 0) $)
 IF P=Y1
 RESULTIS Y1
 RESULTIS GET4 (S.RATN, P, Y1, 0)
 $)
 SWITCHON !P INTO
 $(
 CASE S.LOC: P := H1!P
 LOOP
 CASE S.FPL: MSG1 (14)
 CASE S.NUMJ: IF P<YSG
 RESULTIS GET4 (S.RATL, P, Y1, 0)
 RESULTIS GET4 (S.RATL, P NEQV YSG, YM, 0)
 CASE S.RATN: $( LET Q = H2!P
 TEST Q>Y0
 P := H1!P
 OR Q, P := SIGNBIT-Q, SIGNBIT-H1!P
 IF Q=Y1
 RESULTIS P
 RESULTIS GET4 (S.RATN, Q, P, 0) $)
 CASE S.RATL: $( LET Q = H2!P
 TEST POSITIVE (Q)
 P := H1!P
 OR $( Q := NEG (Q)
 P := NEG (H1!P) $)
 IF Q=Y1
 RESULTIS P
 RESULTIS GET4 (S.RATL, Q, P, 0) $)
 CASE S.RATP: RESULTIS DIV (H1!P, H2!P)
 CASE S.POLY: P := MONICPOLY (P)
 $( LET Q = RECIP (LCOEF)
 RESULTIS GET4 (S.RATP, P, Q, H3!P) $)
 CASE S.FLT: IF H2!P #= 0.0
 MSG1 (7)
 RESULTIS GETX (S.FLT, 0, 1.0 #/ H2!P, 0)
 DEFAULT: RESULTIS ARITHFN (Y1, P, A.DIV)
 $)
 $) REPEAT
 
 
AND GCDA (A, B) = VALOF
 SWITCHON COERCE (@A, TRUE) INTO
 $(
 CASE S.NUM: RESULTIS IGCD (A+NY0, B+NY0)+Y0
 CASE S.NUMJ: IF NUMARG
 RESULTIS GCD1 (B, A)+Y0
 RESULTIS LGCD (A, B)
 CASE S.POLY: IF WORSE
 $( IF A=Y0
 RESULTIS B
 RESULTIS Y1 $)
 A := POLYGCD (A, B)
 TEST A=Y1 | LCOEF=Y1
 RESULTIS A
 OR RESULTIS MONICPOLY (A)   // or DIV (A, LCOEF)
 DEFAULT: MSG1 (23, A, B)
 $)
 
 
AND FIXV (P) = VALOF
 $( IF P<=0
 $( IF P>=-1
 TEST P=0
 RESULTIS Y0
 OR RESULTIS Y1
 RESULTIS P $)
 SWITCHON !P INTO
 $(
 CASE S.LOC: P := H1!P
 LOOP
 CASE S.FLT: RESULTIS SADD (FIX (H2!P))
 CASE S.FPL: MSG1 (14)
 CASE S.RATN: RESULTIS (H2!P+NY0)/(H1!P+NY0)+Y0
 CASE S.RATL: $( LET F, Q = LONGDIV, H1!P
 IF Q<=0
 F := LONGDIV1
 RESULTIS F (H2!P, Q) $)
 CASE S.RATP: RESULTIS DIVPOLY (H2!P, H1!P)
 DEFAULT: RESULTIS P
 $)
 $) REPEAT
 
 
AND FLOATV (P) = VALOF
 $( IF P<=0
 $( IF P>=-1
 TEST P=0
 P := Y0
 OR P := Y1
 RESULTIS GETX (S.FLT, 0, FLOAT (P+NY0), 0) $)
 SWITCHON !P INTO
 $(
 CASE S.LOC: P := H1!P
 LOOP
 CASE S.FLT:
 CASE S.FPL: RESULTIS P
 CASE S.NUMJ: MSG1 (14)
 CASE S.RATN: RESULTIS GETX (S.FLT, 0, FLOAT (H2!P+NY0) #/ FLOAT (H1!P+NY0), 0)
 CASE S.RATL: MSG1 (14)
 DEFAULT: MSG1 (16, FLOATV, P)
 RESULTIS Z
 $)
 $) REPEAT
 
 
AND ABSV (P) = VALOF
 $( IF POSITIVE (P)
 RESULTIS P
 RESULTIS NEG (P) $)
 
 
LET IGCD (A, B) = VALOF
 $( UNTIL B=0
 $( LET R = A REM B
 A, B := B, R $)
 RESULTIS ABS A $)
 
 
AND GCD1 (A, N) = VALOF
 $( IF N=Y0
 RESULTIS A
 LONGDIV1 (A, N)
 RESULTIS IGCD (N+NY0, RESULT2) $)
 
 
.
//./       ADD LIST=ALL,NAME=PALM7
 SECTION "PALM7"
 
 
GET "PALHDR"
 
 
LET LOOKUP (A) = VALOF
 $( LET EE = E        // Possibly now EE=ZE, but not EE=Z
 $( IF A=H3!EE
 RESULTIS H2!EE
 EE := H1!EE $) REPEATUNTIL EE=Z
 MSG1 (15, A)
 RESULTIS A $)
 
 
AND BIND (V, W, K) = VALOF
 $( IF V>0
 SWITCHON !V INTO
 $(
 CASE S.LOC: V := H1!V
 LOOP
 CASE S.TUPLE:
 UNTIL W>0 & !W=S.TUPLE & H3!V=H3!W
 $( IF W>=YLOC
 W := H1!W <> LOOP
 IF ORDER (W)=Y1
 W := LMAPT (W, H3!V) <>
 LOOP
 MSG1 (6, V, W) $)
 IF @W>STACKL
 RESULTIS BIND1 (V, W, K)
 $( K := BIND (H2!V, H2!W, K)
 V := H1!V
 IF V=Z
 RESULTIS K
 W := H1!W $) REPEAT
 CASE S.QU: W := GET4 (S.CLOS, E, Z, W) // But bad scene if W is CD? Maybe OK
 V := H2!V
 LOOP
 CASE S.AA: UNLESS W>=YLOC
 W := GET4 (S.LOC, W, 0, 0)+YLOC
 V := H2!V
 LOOP
 CASE S.ZZ: IF W>=YLOC
 W := H1!W
 V := H2!V
 LOOP
 CASE S.GENSY:
 CASE S.NAME:
 CASE S.DASH: RESULTIS GET4 (S.E, K, W, V)
 CASE S.GLG:
 CASE S.GLO: H2!V := W
 RESULTIS K
 CASE S.GLZ: !V := S.GLO
 H2!V := W
 FIXAP (H3!V)
 H3!V := Z
 RESULTIS K
 $)
 UNLESS V=Z        // ??Z??
 MSG1 (11, V, W)
 RESULTIS K
 $) REPEAT
 
 
AND BIND1 (V, W, K) = VALOF
 $( LET F = Z
 $( TEST V>0
 SWITCHON !V INTO
 $(B
 CASE S.LOC: V := H1!V
 LOOP
 CASE S.TUPLE:
 UNTIL W>0 & !W=S.TUPLE & H3!V=H3!W
 $( IF W>=YLOC
 W := H1!W <> LOOP
 IF ORDER (W)=Y1
 W := LMAPT (W, H3!V) <>
 LOOP
 MSG1 (6, V, W) $)
 F := GET4 (S.MB, F, H1!V, H1!W)+YFJ
 V, W := H2!V, H2!W
 LOOP
 CASE S.QU: W := GET4 (S.CLOS, E, Z, W)      // ??C??
 V := H2!V
 LOOP
 CASE S.AA: UNLESS W>=YLOC
 W := GET4 (S.LOC, W, 0, 0)+YLOC
 V := H2!V
 LOOP
 CASE S.ZZ: IF W>=YLOC
 W := H1!W
 V := H2!V
 LOOP
 CASE S.GENSY:
 CASE S.NAME:
 CASE S.DASH: K := GET4 (S.E, K, W, V)
 ENDCASE
 CASE S.GLG:
 CASE S.GLO: H2!V := W
 ENDCASE
 CASE S.GLZ: !V := S.GLO
 H2!V := W
 FIXAP (H3!V)
 H3!V := Z
 ENDCASE
 L:       DEFAULT: MSG1 (11, V, W)
 $)B
 OR UNLESS V=Z  // ??Z??
 GOTO L
 $( IF F=Z
 RESULTIS K
 $( LET F2 = H2!F
 UNLESS F2=Z
 $( LET F3 = H3!F
 V, W, H2!F, H3!F := H2!F2, H2!F3, H1!F2, H1!F3
 BREAK $) $)
 !F, STACKP := STACKP, F
 F := H1!F $) REPEAT
 $) REPEAT
 $)
 
 
AND BINDA (V, W, K) = VALOF
 $( K := GET4 (S.E, K, H2!W, H2!V)
 V := H1!V
 IF V=Z
 RESULTIS K
 W := H1!W $) REPEAT
 
 
AND BINDR (V, W) BE
 RETURN
 
// There are bizarre possibilities about REC 'F . ...
 
 
AND DOREC (A, B) = VALOF
 $( LET E1 = E
 E := H1!E
 $( LET E2 = BIND (B, A, E)
 H1!E1, H2!E1, H3!E1 := H1!E2, H2!E2, H3!E2 $)
 RESULTIS A $)
 
 
AND DORECA (A) = VALOF
 $( H2!E := A
 E := H1!E
 RESULTIS A $)
 
 
.
//./       ADD LIST=ALL,NAME=PALM8
 SECTION "PALM8"
 
 
GET "PALHDR"
 
 
LET TRACE (A, B) = VALOF
 $( LET F = A
 $( IF A>0
 SWITCHON !A INTO
 $(
 CASE S.GENSY:
 CASE S.NAME: A := LOOKUP (A)
 LOOP
 CASE S.GLZ:
 CASE S.GLG:
 CASE S.GLO: A := H2!A
 LOOP
 CASE S.CLOS:
 CASE S.ACLOS:
 CASE S.CLOS2:
 CASE S.ECLOS:
 CASE S.FCLOS:
 H3!A := GET4 (S.TRA, F, H3!A, B)
 RESULTIS A
 $)
 MSG1 (16, TRACE, A)
 $) REPEAT
 $)
 
 
AND UNTRACE (A) = VALOF
 $( IF A>0
 $( $( LET A3 = H3!A
 IF A3>0 & !A3=S.TRA
 $( H3!A := H2!A3
 RESULTIS A $) $)
 IF !A=S.TUPLE
 $( LMAP (UNTRACE, A)
 RESULTIS Z $) $)
 MSG1 (16, UNTRACE, A) $)
 
 
AND DOTRACE (C, A) BE
 $( WRITEF ("*N# Argument for %P: %E*N", H1!C, PRINT, A)
 UNLESS H3!C=Z
 $( APPLY (H3!C, A)
 ARG1 := A   // ??A??
 $)
 GW0, GW1, GW2 := DOTRACE1, H1!C, H2!C
 LONGJUMP (FLEVEL (EVAL), LL.EX) $)
 
 
AND DOTRACE1 (A, F) = VALOF
 $( WRITEF ("*N# Done %P: val %E*N", F, PRINT, ARG1)
 RESULTIS A $)
 
 
AND TRAP (A, N, B) BE
 $( N := N+CONS-Y0
 $( LET S = (@TRZ-1) | SIGNBIT     // ?B
 $( LET S1 = H1!S
 IF S1=Z
 BREAK
 IF H3!S1>=N
 $( IF H3!S1>N
 H1!S := GET4 (S.MB, S1, B, N)
 GOTO LX $)
 S := S1 $) REPEAT
 H1!S := GET4 (S.MB, Z, B, N)
 $)
 LX:  GW0, GW1, GW2 := DOTRAP1, B, A
 LONGJUMP (FLEVEL (EVAL), LL.EX)
 $)
 
 
.
//./       ADD LIST=ALL,NAME=PALM9
 SECTION "PALM9"
 
 
GET "PALHDR"
 
 
LET EQLV (P, Q) = VALOF
 $( IF P=Q
 RESULTIS TRUE
 IF P<=0
 $( UNLESS Q>=YLOC
 RESULTIS FALSE
 RESULTIS P=H1!Q $)
 IF Q<=0
 $( UNLESS P>=YLOC
 RESULTIS FALSE
 RESULTIS H1!P=Q $)
 UNLESS !P=!Q
 $( IF P>=YLOC
 P := H1!P <> LOOP
 IF Q>=YLOC
 Q := H1!Q <> LOOP
 RESULTIS FALSE $)
 SWITCHON !P INTO
 $(
 CASE S.LOC: P, Q := H1!P, H1!Q
 LOOP
 CASE S.GENSY:
 CASE S.NAME:
 CASE S.GLZ:
 CASE S.GLG:
 CASE S.GLO:
 CASE S.XTUPL:
 CASE S.UNSET:
 CASE S.UNSET1:
 CASE S.TRA: RESULTIS FALSE        // since P~=Q
 CASE S.FLT: RESULTIS H2!P #= H2!Q
 CASE S.FPL: MSG1 (14)
 CASE S.RATN: UNLESS H1!P=H1!Q
 RESULTIS FALSE
 CASE S.RDS:
 CASE S.WRS:
 CASE S.BCPLF:
 CASE S.BCPLR:
 CASE S.BCPLV:
 CASE S.CODEV:
 CASE S.CODE0:
 CASE S.CODE1:
 CASE S.CODE2:
 CASE S.CODE3:
 CASE S.CODE4:
 RESULTIS H2!P=H2!Q
 CASE S.NUMJ: IF (P NEQV Q)<YSG
 CASE S.STRING: $( UNLESS H2!P=H2!Q & H3!P=H3!Q
 RESULTIS FALSE
 P, Q := H1!P, H1!Q
 IF P=Q
 RESULTIS TRUE $) REPEATUNTIL P=Z | Q=Z
 RESULTIS FALSE
 CASE S.POLY: IF H3!P=H3!Q
 $( LET F = (P NEQV Q)<YSG
 $( P, Q := H1!P, H1!Q
 IF P=Q
 TEST P=Z
 RESULTIS TRUE
 OR RESULTIS F
 IF P=Z | Q=Z
 RESULTIS FALSE
 UNLESS H3!P=H3!Q
 RESULTIS FALSE
 F := F NEQV (P NEQV Q)>=YSG
 $) REPEATWHILE EQPOLY (H2!P, H2!Q, F)
 $)
 RESULTIS FALSE
 DEFAULT: RESULTIS EQL (P, Q)
 $)
 $) REPEAT
 
 
STATIC
 $( GA1 = 0
 GA2 = 0
 GA3 = 0
 GA4 = 0 $)
 
 
LET GTV (P, Q) = VALOF
 $( SWITCHON COERCE (@P, FALSE) INTO
 $(
 CASE S.NUM: RESULTIS P>Q
 CASE S.NUMJ: IF NUMARG
 TEST WORSE1
 RESULTIS P<YSG
 OR RESULTIS Q>=YSG
 IF (P NEQV Q)>=YSG
 RESULTIS P<YSG
 $( LET C = LONGCMP (P, Q)
 IF C=0
 RESULTIS FALSE
 RESULTIS C>0 NEQV P>=YSG $)
 CASE S.RATN: IF NUMARG
 $( TEST WORSE1
 $( GA1 := (H2!P-Y0)/(H1!P-Y0)+Y0
 IF GA1>Q
 RESULTIS TRUE
 IF GA1<Q
 RESULTIS FALSE
 IF GA1=Y0
 RESULTIS H2!P>Y0
 RESULTIS GA1>Y0 $)
 OR $( GA1 := (H2!Q-Y0)/(H1!Q-Y0)+Y0
 IF P>GA1
 RESULTIS TRUE
 IF P<GA1
 RESULTIS FALSE
 IF P=Y0
 RESULTIS H2!Q<Y0
 RESULTIS P<Y0 $)
 $)
 IF WORSE
 TEST WORSE1
 RESULTIS Q>=YSG
 OR RESULTIS P<YSG
 GA1, GA2 := H2!P-Y0, H1!P-Y0
 GA3, GA4 := H2!Q-Y0, H1!Q-Y0
 $( LET F = GA1/GA2-GA3/GA4
 IF F>0
 RESULTIS TRUE
 IF F<0
 RESULTIS FALSE $)
 GA1 := MULDIV (GA1, GA4, NUMBA)
 GA4 := RESULT2
 GA2 := MULDIV (GA2, GA3, NUMBA)
 IF GA1=GA2
 RESULTIS GA4>RESULT2
 RESULTIS GA1>GA2
 CASE S.RATL: TEST WORSE
 TEST WORSE1
 Q, P := MUL (H1!P, Q), H2!P
 OR P, Q := MUL (P, H1!Q), H2!Q
 OR $( LET T = MUL (H2!P, H1!Q)
 Q := MUL (H1!P, H2!Q)
 P := T $)
 LOOP
 CASE S.POLY:
 CASE S.RATP: RESULTIS WORSE1
 CASE S.FLT: RESULTIS GW1 #> GW2
 CASE S.FPL: MSG1 (14)
 CASE S.STRING:
 RESULTIS COMPL (P, Q)>0
 DEFAULT: MSG1 (23, P, Q)
 RESULTIS Z
 $)
 $) REPEAT
 
 
AND SHLV (A, B) = MSG1 (26, "SHL")
 
 
AND SHRV (A, B) = MSG1 (26, "SHR")
 
 
.
//./       ADD LIST=ALL,NAME=POLY
 SECTION "POLY"
 
 
GET "PALHDR"
 
 
MANIFEST
 $( YZ = Y0+NUMBA $)
 
 
STATIC
 $( SG = 0 $)
 
 
// POLY REPR:     S.POLY    | POLYJ    | INDET | #MAINNESS>Y0
// POLYJ REPR:    S.POLYJ   | POLYJ(Z) | FAC   | #POW
 
// A POLY IS NOT EMPTY, NOR CONSTANT
 
 
LET ALGATOM (P, N) = VALOF
 $( LET Q = GET4 (S.POLYJ, Z, Y1, Y1)
 N := G.POSINT (N)
 RESULTIS GET4 (S.POLY, Q, P, N) $)
 
 
AND ALG (N) = VALOF
 $( IF N>0
 $( IF !N=S.NAME
 $( ALGN := ALGN+1
 RESULTIS ALGATOM (N, ALGN) $)
 IF !N=S.TUPLE
 RESULTIS LMAPL (ALG, N) $)
 MSG1 (16, ALG, N) $)
 
 
AND POL (S, P) = VALOF
 $( P := G.NP (P, S.POLY)
 RESULTIS GET4 (S.POLY, H1!P, S, H3!P)+(P & YSG) $)
 
 
AND EVALPOLY (P) = VALOF
 $( LET A = H2!P
 IF ARITHV (A)
 $( LET AA, N, Q = Y1, Y0, Y0
 P := H1!P NEQV (P & YSG)
 $( UNTIL N=H3!P
 $( N := N+1
 AA := MUL (A, AA) $)
 $( LET R = MUL (H2!P, AA)
 Q := (P<YSG -> ADD, MINU)(Q, R) $)
 P := H1!P NEQV (P & YSG) $) REPEATUNTIL (P & P.ADDR)=Z
 RESULTIS Q $)
 RESULTIS P
 $)
 
 
// P,Q ARE SAME POLYS
 
 
AND ADDPOLY (P, Q) = VALOF
 $( LET R = GET4 (S.POLY, ZSY, H2!P, H3!P)
 LET R1 = R
 IF @P>STACKL
 STKOVER ()
 P, Q := H1!P NEQV (P & YSG), H1!Q NEQV (Q & YSG)
 $( IF H3!Q>H3!P
 L:       $( LET Q3 = H3!Q
 $( SG := P & YSG
 $( LET T = GET4 (S.POLYJ, ZSY, H2!P, H3!P)+SG
 H1!R1, R1 := T NEQV (R1 & YSG), T
 P := H1!P
 IF P=Z
 $( H1!R1 := Q NEQV (R1 & YSG)
 RESULTIS R $)
 P := P NEQV SG $) $) REPEATWHILE H3!P<Q3 $)
 IF H3!P>H3!Q
 $( LET P3 = H3!P
 $( LET T = GET4 (S.POLYJ, ZSY, H2!Q, H3!Q)+(Q & YSG)
 H1!R1, R1 := T NEQV (R1 & YSG), T
 Q := H1!Q NEQV (Q & YSG)
 IF (Q & P.ADDR)=Z
 $( H1!R1 := P NEQV (R1 & YSG)
 RESULTIS R $) $) REPEATWHILE P3>H3!Q
 UNLESS P3=H3!Q
 GOTO L $)
 $( LET F = (P NEQV Q)<YSG -> ADD, MINU
 F := F (H2!P, H2!Q)
 UNLESS F=Y0
 $( F := GET4 (S.POLYJ, ZSY, F, H3!P)+(P & YSG)
 H1!R1, R1 := F NEQV (R1 & YSG), F $)
 P, Q := H1!P NEQV (P & YSG), H1!Q NEQV (Q & YSG) $)
 IF (P & P.ADDR)=Z
 $( TEST (Q & P.ADDR)=Z
 $( IF R1=R
 RESULTIS Y0
 IF H3!R1=Y0
 TEST R1<YSG
 RESULTIS H2!R1
 OR RESULTIS NEG (H2!R1)
 H1!R1 := Z $)
 OR H1!R1 := Q NEQV (R1 & YSG)
 RESULTIS R
 $)
 IF (Q & P.ADDR)=Z
 $( H1!R1 := P NEQV (R1 & YSG)
 RESULTIS R $)
 $) REPEAT
 $)
 
 
// P IS POLY, A BETTER;   TRY ADDP1 (A, P, B)
 
 
AND ADDP1 (A, P) = VALOF
 $( IF A=Y0
 RESULTIS P
 $( LET R = GET4 (S.POLY, ZSY, H2!P, H3!P)
 P := H1!P NEQV (P & YSG)
 IF H3!P=Y0
 $( LET F = P<YSG -> ADD, MINU
 A := F (A, H2!P)
 P := H1!P NEQV (P & YSG) // H1!P ~= Z
 IF A=Y0
 $( H1!R := P
 RESULTIS R $) $)
 H1!R := GET4 (S.POLYJ, P, A, Y0)
 RESULTIS R
 $)
 $)
 
 
 
// P IS POLY, A BETTER
 
 
AND POLYMAPF (P, A, F) = VALOF  // F is like MUL
 $( IF A=Y0
 RESULTIS Y0
 IF A=Y1
 RESULTIS P
 IF A=YM
 RESULTIS P NEQV YSG
 $( LET Q = GET4 (S.POLY, ZSY, H2!P, H3!P)+(P & YSG)
 LET QQ = Q
 P := H1!P
 $( LET R = F (H2!P, A)
 R := GET4 (S.POLYJ, ZSY, R, H3!P)+(P & YSG)
 H1!QQ, QQ := R, R
 P := H1!P $) REPEATUNTIL P=Z
 H1!QQ := Z
 RESULTIS Q $)
 $)
 
 
// P,Q ARE SAME POLYS
// As we build up the answer in R, we use the fact that H3!ZSY is large
 
 
// TRY MAKING Q POSITIVE
 
 
AND MULPOLY (P, Q) = VALOF
 $( LET R0 = GET4 (S.POLY, ZSY, H2!P, H3!P)
 LET R1, R = R0, R0+((P NEQV Q) & YSG)
// R0 ^ latest immutable term in answer
// R1 ^ current target
 IF @P>STACKL
 STKOVER ()
 P, Q := H1!P, H1!Q
 $( LET Q1, P2 = Q NEQV (P & YSG), H2!P
// P2 = Y1,YM ?
 LET P3 = H3!P
 LET Q3 = P3+H3!Q1-Y0
 IF Q3>=YZ
 MSG1 (18, Q3)
 $( LET R1A = H1!R0
 UNTIL H3!R1A>=Q3
 $( R0 := R1A
 R1A := H1!R1A $)
 R1 := R0
 $( $( LET T = MUL (P2, H2!Q1)
 TEST H3!R1A>Q3        // insert term
 $( IF Q1>=YSG
 T := NEG (T)
 T := GET4 (S.POLYJ, R1A, T, Q3)
 H1!R1, R1 := T, T $)
 OR $( $( LET F = Q1<YSG -> ADD, MINU
 T := F (H2!R1A, T) $)
 TEST T=Y0
 $( R1A := H1!R1A
 H1!R1 := R1A $)   // nb destructive
 OR $( H2!R1A := T
 R1 := R1A
 R1A := H1!R1A $) $)
 $)
// That leaves R1A=H1!R1
 Q1 := H1!Q1 NEQV (Q1 & YSG)
 IF (Q1 & P.ADDR)=Z
 BREAK
 Q3 := P3+H3!Q1-Y0
 IF Q3>=YZ
 MSG1 (18, Q3)
 UNTIL H3!R1A>=Q3
 $( R1 := R1A
 R1A := H1!R1A $)
 $) REPEAT
 $)
 P := H1!P NEQV (P & YSG)
 $) REPEATUNTIL (P & P.ADDR)=Z
 H1!R1 := Z        // remove ZSY
 RESULTIS R
 $)
 
 
// P,Q ARE SAME POLYS
// LCOEF, LDEG, RESULT2 := lcoef and degree of divisor, remainder
 
 
AND DIVPOLY (P, Q) = VALOF
 $( LET R = Z
 IF @P>STACKL
 STKOVER ()
 $( LET U = COPYU (H1!P NEQV (P & YSG))
 LET V = COPYV (H1!Q NEQV (Q & YSG))
 LET F = DIV
 Q := H2!V
 IF Q=Y1
 F := IV
 FOR K=H3!U-H3!V+Y0 TO Y0 BY -1
 $( LET RR = F (H2!U, Q)
 U := H1!U
 UNLESS RR=Y0
 $( R := GET4 (S.POLYJ, R, RR, K)
 $( LET UU = U
 AND VV = H1!V
 UNLESS VV=Z
 $( FOR I=Y2 TO H3!VV
 UU := H1!UU
 $( LET T = MUL (RR, H2!VV)
 H2!UU := MINU (H2!UU, T)
 UU, VV := H1!UU, H1!VV $) $) REPEATUNTIL VV=Z $) $)
 $)
 IF R=Z
 $( LCOEF, LDEG, RESULT2 := Q, H3!V, P
 RESULTIS Y0 $)
 U := UNCOPY (U)
 TEST U=Z
 U := Y0
 OR TEST H3!U=Y0 & H1!U=Z
 U := H2!U
 OR U := GET4 (S.POLY, U, H2!P, H3!P)
 TEST H3!R=Y0 & H1!R=Z
 R := H2!R   // R is positive
 OR R := GET4 (S.POLY, R, H2!P, H3!P)
 LCOEF, LDEG, RESULT2 := Q, H3!V, U
 $)
 RESULTIS R
 $)
 
 
AND PSEUDOREMPOLY (P, Q) = VALOF
 $( IF @P>STACKL
 STKOVER ()
 $( LET U = COPYU (H1!P NEQV (P & YSG))
 LET UA = U
 LET V = COPYV (H1!Q NEQV (Q & YSG))
 LET F = MUL
 Q := H2!V
 IF Q=Y1
 F := IV
 FOR K=H3!U TO H3!V BY -1
 $( LET RR = H2!U
 U := H1!U
 $( LET UU = U
 AND VV = H1!V
 UNLESS VV=Z
 $( FOR I=Y2 TO H3!VV
 $( H2!UU := F (H2!UU, Q)
 UU := H1!UU $)
 $( LET T = MUL (RR, H2!VV)
 LET S = F (H2!UU, Q)
 H2!UU := MINU (S, T)
 UU, VV := H1!UU, H1!VV $) $) REPEATUNTIL VV=Z
 UNLESS Q=Y1
 UNTIL UU=ZSY       // the last time round, UU already = ZSY
 $( H2!UU := F (H2!UU, Q)
 UU := H1!UU $)
 $)
 $)
 IF U=UA
 $( LCOEF, LDEG := Q, H3!V
 RESULTIS P $)
 U := UNCOPY (U)
 TEST U=Z
 U := Y0
 OR TEST H3!U=Y0 & H1!U=Z
 U := H2!U
 OR U := GET4 (S.POLY, U, H2!P, H3!P)
 LCOEF, LDEG := Q, H3!V
 RESULTIS U
 $)
 $)
 
 
// These make reverse copies for U/V,
// noting that the copy of U must be dense,
// but the copy of V can be sparse (perhaps with funny entries as exponents)
 
 
AND COPYU (P) = VALOF
 $( LET Q, Q3 = ZSY, Y0
 $( $( LET P3 = H3!P
 UNTIL Q3=P3
 $( Q := GET4 (S.POLYJ, Q, Y0, Q3)
 Q3 := Q3+1 $) $)
 $( LET T = H2!P
 IF P>=YSG
 T := NEG (T)
 Q := GET4 (S.POLYJ, Q, T, Q3) $)
 Q3 := Q3+1
 P := H1!P NEQV (P & YSG)
 $) REPEATUNTIL (P & P.ADDR)=Z
 RESULTIS Q
 $)
 
 
AND COPYV (P) = VALOF
 $( LET Q, P3 = Z, 0
 $( LET T = H2!P
 IF P>=YSG
 T := NEG (T)
 UNLESS Q=Z
 H3!Q := H3!P-P3+Y0
 Q := GET4 (S.POLYJ, Q, T, ZSY)
 P3 := H3!P
 P := H1!P NEQV (P & YSG) $) REPEATUNTIL (P & P.ADDR)=Z
 H3!Q := P3
 RESULTIS Q
 $)
 
 
AND UNCOPY (P) = VALOF
 $( LET Q = Z
 $( LET T = H1!P
 UNLESS H2!P=Y0
 $( H1!P := Q
 Q := P $)
 P := T $) REPEATUNTIL P=ZSY
 RESULTIS Q $)
 
 
AND MONICPOLY (A) = VALOF
 $( LET Q = H1!A NEQV (A & YSG)
 UNTIL H1!Q=Z
 Q := H1!Q NEQV (Q & YSG)
 $( LET T = H2!Q
 IF Q>=YSG
 T := NEG (T)
 IF T=Y1
 $( LCOEF := T
 RESULTIS A $)
// ??SS?? TEST RATP(Y1)=RATP(YM)
 Q := Q & P.ADDR
 $( LET R = GET4 (S.POLY, ZSY, H2!A, H3!A)+(A & YSG)
 LET RR = R
 A := H1!A
 UNTIL (A & P.ADDR)=Q
 $( LET S = DIV (H2!A, T)
 S := GET4 (S.POLYJ, ZSY, S, H3!A)+(A & YSG)
 H1!RR, RR := S, S NEQV (RR & YSG)
 A := H1!A $)
 H1!RR := GET4 (S.POLYJ, Z, Y1, H3!Q) NEQV (RR & YSG)
 LCOEF := T
 RESULTIS R
 $)
 $)
 $)
 
 
AND POLYGCD (P, Q) = VALOF
 $( LET D0 = 0
 LET L1, D1 = 0, H1!P
 
 UNTIL H1!D1=Z
 D1 := H1!D1
 D1 := H3!D1
 
 $( LET R = PSEUDOREMPOLY (P, Q)
 UNLESS R>0 & !R=S.POLY & H3!R=H3!Q
 TEST R=Y0
 RESULTIS Q
 OR RESULTIS Y1
 $( LET  TL , TD = LCOEF, LDEG
 P := Q
 TEST D0=0
 Q := R
 OR $( LET C = POW (L1, D0-D1+Y1)
 TEST C=Y1
 Q := R
 OR Q := POLYMAPF (R, C, DIV) $)
 D0 := D1
 L1, D1 :=  TL , TD
 $)
 $) REPEAT
 $)
 
 
 
// This is the price we pay for not having a canonical form for the signs of
// polynomial terms.
// F -> we want P=Q, else we want P=-Q
 
 
AND EQPOLY (A, B, F) = VALOF
 $( IF A=B
 RESULTIS F
 IF A<=0
 $( IF B<=0
 UNLESS F
 RESULTIS A+B=SIGNBIT
 RESULTIS FALSE $)
 IF B<=0
 RESULTIS FALSE
 UNLESS !A=!B
 RESULTIS FALSE
 IF @A>STACKL
 STKOVER ()
 SWITCHON !A INTO
 $(
 CASE S.FLT: TEST F
 RESULTIS H2!A #= H2!B
 OR RESULTIS H2!A #=  #- H2!B
 CASE S.FPL: MSG1 (14)
 CASE S.NUMJ: IF F=((A NEQV B)<YSG)
 RESULTIS COMPL (A, B)=0
 RESULTIS FALSE
 CASE S.RATN: UNLESS H1!A=H1!B
 RESULTIS FALSE
 A, B := H2!A, H2!B
 LOOP
 CASE S.RATP: UNLESS H3!A=H3!B
 RESULTIS FALSE
 CASE S.RATL: UNLESS EQLV (H1!A, H1!B)
 RESULTIS FALSE
 A, B := H2!A, H2!B
 LOOP
 CASE S.POLY: IF H3!A=H3!B
 $( F := F NEQV (A NEQV B)>=YSG
 $( A, B := H1!A, H1!B
 IF A=B
 TEST A=Z
 RESULTIS TRUE
 OR RESULTIS F
 IF A=Z | B=Z
 RESULTIS FALSE
 F := F NEQV (A NEQV B)>=YSG $) REPEATWHILE H3!A=H3!B & EQPOLY (H2!A, H2!B, F)
 $)
 RESULTIS FALSE
 DEFAULT: MSG1 (33, "Poly", A)
 $)
 $) REPEAT
 
 
.
//./       ADD LIST=ALL,NAME=SETUP
 SECTION "SETUP"
 
 
GET "PALHDR"
 
 
// Allocation at top of heap, for use before free-store package is under way
 
 
LET GG0 (S, F) = GET4 (S, 0, !F | SIGNBIT, !F<0)        // !F<0 concerns BCPLF
 
 
AND G3S (F, G) = GET4 (S.CODE2, 0, !F | SIGNBIT, G | SIGNBIT)
 
 
LET S0 (S) = VALOF
 $( UNPACKSTRING (S, BUFFP)
 RESULTIS STRING (BUFFP) $)
 
 
AND DS (S, G1, G2, P1, P2, P3) = VALOF
 $( S := S0 (S)
 G1 := G3S (G1, G2)
 P1 := PRIOS (S.DIADOP, P1, P2, P3)
 RESULTIS H2!LINKWORD (S.GLO, S, G1, P1) $)
 
 
AND DT (S, G1, G2, P1, P2, P3) = VALOF
 $( S := S0 (S)
 G1 := G3S (G1, G2)
 P1 := PRIOS (S.RELOP, P1, P2, P3)
 RESULTIS H2!LINKWORD (S.GLO, S, G1, P1) $)
 
 
AND DU (S, F, G, N) = VALOF
 $( S := S0 (S)
 F := GG0 (F, G)
 RESULTIS H2!LINKWORD (S.GLO, S, F, N | SIGNBIT) $)
 
 
AND DV (S, F, G, N, P) = VALOF
 $( S := S0 (S)
 F := GG0 (F, G)
 N := PRIOS1 (N, P)
 RESULTIS H2!LINKWORD (S.GLO, S, F, N) $)
 
 
AND DY (S, V, N) = VALOF
 $( S := S0 (S)
 RESULTIS H2!LINKWORD (S.GLO, S, V, N | SIGNBIT) $)
 
 
AND SET.P (S, N) = VALOF
 $( LET A = S0 (S)
 RESULTIS H2!LINKWORD (S.GLO, A, IV, N | SIGNBIT) $)
 
 
AND SET.Q (S, F, N, P1, P2, P3) = VALOF
 $( LET A = S0 (S)
 RESULTIS H2!LINKWORD (S.GLO, A, F | SIGNBIT, PRIOS (N, P1, P2, P3)) $)
 
 
AND PRIOS1 (N, A) = N+(A<<8) | SIGNBIT
 
 
AND PRIOS (N, A, B, C) = N+(A<<24)+(B<<16)+(C<<8) | SIGNBIT
 
 
AND SET.D (S, F) = D (S, S.CODE1, F)
 
 
AND SET.V (S, F) = D (S, S.CODEV, F)
 
 
AND SET.C (S, F) = D (S, S.CODE2, F)
 
 
AND SET.F (S, F) = D (S, S.BCPLF, F)
 
 
AND SET.R (S, F) = D (S, S.BCPLR, F)
 
 
AND D (S, N, F) = VALOF
 $( LET A = S0 (S)
 LET B = GG0 (N, F)
 RESULTIS H2!LINKWORD (S.GLO, A, B, ZSY) $)
 
 
AND SET.Z (N, S, A2, A3) = VALOF
 $( S := S0 (S)
 RESULTIS H2!LINKWORD (N, S, A2, A3) $)
 
 
LET SETUP () BE
 $( FIXBCPL1 ()
 RTIME := 0
 STACKB := LEVEL ()>>2     // this will last
 STACKP := 0
 CONS, CYCLES := Y0, Y0
 GENSYMN, ALGN := Y0, Y0
 GSEQ, GSEQF := 0, 0
 
 PARAMA, PARAMB, PARAMC, PARAMD := FALSE, FALSE, FALSE, FALSE
 PARAMI, PARAMJ, PARAMK, PARAMM := FALSE, FALSE, FALSE, FALSE
 PARAMN, PARAMQ, PARAMV, PARAMY := FALSE, FALSE, FALSE, FALSE
 PARAMZ := TRUE
 
 KSQ, KWORDS, KSTACK := 2048, 1024, 1024
 SSZ := STACKEND-STACKBASE
 PARAM (PARMS)
 
 REGION := ((STACKEND+PAGESIZE) & PAGEMASK)-(LOADPOINT & PAGEMASK)
 WRITEF ("*N# Pal system at%S on%S;  parm '%S';  Region %NK bytes.*N",
 TIMEOFDAY (), DATE (), PARMS, REGION>>8)
 IF PARAMK
 WRITEF ("# Version%S;  code/heap %N/%N words;  heap %N%% of region",
 LOADPOINT+4, ENDPOINT-LOADPOINT, SSZ, SSZ*100/REGION)
 
 FOR I=@ERROR TO @G0+MAXGLOB
 GPFN (I)
 
 $( LET T = "DHAMMA  "
 FOR I=0 TO 8
 PUTBYTE (BUFFP+BUFFL-2, I, GETBYTE (T, I+1))
 BUFFP!BUFFL := (@G0)<<2 $)
 
 $( LET D (N, S) BE        // OP mnemonic names
 $( N := N-@LL.ZC+OCM
 FOR I=0 TO 3
 PUTBYTE (N, I, GETBYTE (S, I+1)) $)
 AND A (N, S) BE
 $( !N := !N | SVA
 D (N, S) $)
 FOR I=1 TO OCMSZ
 D (@LL.ZC+I, "NNN ")
 D (@LL.ZC, "Q   ")
 D (@LA.ENTX, "IEX ")
 D (@LA.ENTY, "IEY ")
 D (@LA.ENTZ, "IEZ ")
 D (@LA.APLOC, "IAL ")
 D (@LA.APTUP, "IAT ")
 D (@LA.APCODE2, "IAB2")
 D (@LA.APCLOS2, "IAE2")
 D (@LA.APECLOS, "IAE ")
 D (@LA.APFCLOS, "IAF ")
 D (@LL.ENTX, "KEX ")
 D (@LL.ENTY, "KEY ")
 D (@LL.ENTZ, "KEZ ")
 D (@LL.APECLOS, "KAE ")
 D (@LL.APFCLOS, "KAF ")
 D (@LA.A1, "IA1 ")
 D (@LA.AE, "IAE ")
 D (@LL.AP, "IA  ")
 A (@LL.RSC, "QC  ")
 A (@LL.RSF, "QF  ")
 A (@LL.SVC, "SVC ")
 A (@LL.SVF, "SVF ")
 A (@LL.SVF1, "SVF1")
 D (@LL.CLOSL, "CLL ")
 D (@LL.CLOSX, "CLX ")
 D (@LL.BIND, "BV  ")
 A (@LL.BINDE, "BE  ")
 D (@LL.LV, "BVLV")
 D (@LL.RV, "BVRV")
 D (@LL.BVF, "BVF ")
 D (@LL.BVFE, "BVFE")
 D (@LL.BVFA, "BVFA")
 D (@LL.BVF1, "BVF1")
 D (@LL.BVFZ, "BVFZ")
 D (@LL.BVE, "BVE ")
 D (@LL.BVEZ, "BVEZ")
 A (@LL.UNBIND, "UBV ")
 D (@LL.CY, "L   ")
 A (@LL.CYF, "LF  ")
 D (@LL.NA, "N   ")
 D (@LL.NA1, "N1  ")
 D (@LL.NA2, "N2  ")
 A (@LL.NAF, "NF  ")
 A (@LL.NA1F, "NF1 ")
 A (@LL.NA2F, "NF2 ")
 A (@LL.ST, "S   ")
 D (@LL.US, "F   ")
 A (@LL.REC0, "REC0")
 D (@LL.REC1, "REC1")
 D (@LL.E, "E   ")
 D (@LL.J, "J   ")
 A (@LL.COND, "->  ")
 A (@LL.TUP, "AUG ")
 A (@LL.TUPA, "AUGA")
 D (@LL.TUPZ, "AUGZ")
 D (@LL.1TUP, "AUG1")
 D (@LL.APV, "B1V ")
 D (@LL.AP1, "B1  ")
 D (@LL.HDV, "HD  ")
 D (@LL.MIV, "MI  ")
 D (@LL.TLV, "TL  ")
 D (@LL.NULL, "NULL")
 D (@LL.ATOM, "ATOM")
 D (@LL.AP2, "B2  ")
 A (@LL.AP2F, "B2F ")
 D (@LL.AP2S, "B2S ")
 A (@LL.AP2SF, "B2SF")
 D (@LL.CONS, "AU  ")
 A (@LL.CONSF, "AUF ")
 D (@LL.XCONS, "XAU ")
 A (@LL.XCONSF, "XAUF")
 D (@LL.APNF, "APF ")
 D (@LL.APNF1, "APF1")
 D (@LL.APNK, "APK ")
 D (@LL.APNC, "APC ")
 D (@LL.APNJ, "APJ ")
 D (@LL.APCF, "ACF ")
 D (@LL.APCF1, "ACF1")
 D (@LL.APCK, "ACK ")
 D (@LL.APCC, "ACC ")
 D (@LL.APBF, "ABF ")
 D (@LL.APBF1, "ABF1")
 D (@LL.APBK, "ABK ")
 D (@LL.APBC, "ABC ")
 D (@LL.APKF, "ATF ")
 D (@LL.APKK, "ATK ")
 D (@LL.APKC, "ATC ")
 D (@LL.APKJ, "ATJ ")
 $)
 
 INITFF ()
 
 
// HEAP:
//      | ST1     (SVU SVV)     ST2 |
 
 
// MARK FROM @E TO @ERZ
// RELOCATE FROM @E TO @A.NULL, AND TYP
 
 ST1 := STACKBASE+SSZ & ~3
 ST2 := ST1-4
 UNLESS STACKB+KSTACK+1024<=ST1<=STACKEND  // ??T??
 GOTO LL
 STACK (KSTACK)
 IF STACKB>STACKL
 LL:     $( WRITEF ("*N# INSUFFICIENT REGION: STACK %NK BYTES*N", SSZ>>8)
 STOP (8) $)
 
 M := S.J
 
 FOR I=@E TO @A.NULL
 !I := Z
 
 ZSY := GET4 (S.UNSET, Z, Y0, Y0+NUMBA)
 ZU := GET4 (S.MB, 0, 0, ZSY)      // keep this from being squashed
 ZSQ := GET4 (S.MB, ZSY+P.TAGP, ZSY+P.TAGP, ZSY+P.TAGP)    // "maxint" for Pal
 ZC := GET4 (S.CD, Z, Z, LL.ZC)
 ZE := GET4 (S.E, Z, Z, Z)
 E := ZE
 ZJ := GET4 (S.J, ZE, Z, Z)
 ZS := GET4 (S.STRING, Z, 0, 0)
 ZSC := GET4 (S.UNSET1, 0, 0, 0)
 
 SVV, SVU := ZSC, ZSC-4
 
 FOR I=TYP TO TYP+TYPSZ
 !I := ZSY
 
 TYP!S.STRING := SET.F ("STRING", @STRING)
 A.NUM := SET.V ("NUM", @NUM)
 FOR I=S.FLT TO S.RATL
 TYP!I := A.NUM
 TYP!S.POLY := SET.C ("POL", @POL) // ??P??
 TYP!S.POLYJ := TYP!S.POLY
 TYP!S.LOC := SET.D ("LV", @LVV)
 TYP!S.CDX := SET.V ("FLATTEN", @FLATTEN)
 FOR I=S.CDY TO S.CD
 TYP!I := TYP!S.CDX
 TYP!S.BCPLF := SET.V ("BCPLF", @BCPLF)
 TYP!S.BCPLR := SET.V ("BCPLR", @BCPLR)
 TYP!S.BCPLV := SET.V ("BCPLV", @BCPLV)
 TYP!S.CODEV := SET.V ("CODE", @CODE)
 FOR I=S.CODE0 TO S.CODE4
 TYP!I := TYP!S.CODE0
 TYP!S.RDS := SET.F ("RDS", @RDS)
 TYP!S.WRS := SET.F ("WRS", @WRS)
 TYP!S.GENSY := D ("GENSYM", S.CODE0, @GENSYM)
 TYP!S.NAME := SET.V ("NAME", @NAME)
 A.QU := DV ("'", S.CODEV, @MQU, S.QU, 35)
 SET.Z (!A.QU, "qu", H2!A.QU, PRIOS1 (S.QU, 2))
 FOR I=S.GLZ TO S.QU
 TYP!I := A.QU
 TYP!S.TUPLE := SET.V ("TUPLE", @TUPLE)
 TYP!S.XTUPL := SET.V ("SAVE", @XTUPLE)
 TYP!S.TRA := SET.C ("TRACE", @TRACE)
 TYP!S.E := ZE
 A.FCLOS := DU ("lambda", S.CODE2, @FN, S.FCLOS)
 FOR I=S.CLOS TO S.FCLOS
 TYP!I := A.FCLOS
 SET.Z (!A.FCLOS, "fn", H2!A.FCLOS, H3!A.FCLOS)
 TYP!S.REC := DU ("rec", S.CODE2, @REC, S.REC)
 TYP!S.RECA := TYP!S.REC
 TYP!S.LET := DU ("let", S.CODE3, @MLET, S.LET)
 FOR I=S.LETA TO S.LETB
 TYP!I := TYP!S.LET
 TYP!S.RETU := DV ("return", S.CODEV, @RETU, S.RETU, 35)
 TYP!S.COND := DU ("->", S.CODE3, @MCOND, S.COND)
 FOR I=S.CONDA TO S.CONDB
 TYP!I := TYP!S.COND
 TYP!S.SEQ := DS (";", @MSEQ, SEQ, 2, 3, 2)
 TYP!S.SEQA := TYP!S.SEQ
 SET.Z (!(TYP!S.SEQ), "<>", H2!(TYP!S.SEQ), PRIOS (S.DIADOP, 9, 10, 9))
 TYP!S.COLON := DU (":", S.CODE2, @MCOLON, S.COLON)
 TYP!S.DASH := SET.V ("DF", @MDASH)
 TYP!S.AA := DV ("@", S.CODEV, @MK.AA, S.AA, 35)
 TYP!S.ZZ := DV ("!", S.CODEV, @MK.ZZ, S.ZZ, 35)
 TYP!S.APZ := SET.C ("AP", @AP1)
 FOR I=S.APPLY TO S.AQE
 TYP!I := TYP!S.APZ
 FOR I=S.J TO S.MB
 TYP!I := ZJ
 
 DS (":=", @ASSG, AP2, 4, 5, 4)
 DS ("aug", @AUG, MK.AUG, 12+64, 12, 13)
 DS ("<<", @SHLV, AP2, 19, 19, 22)
 DS (">>", @SHRV, AP2, 19, 19, 22)
 DT ("is", @ISV, AP2, 20+64, 21, 21)
 A.EQ := DT ("=", @EQLV, AP2, 20, 21, 21)
 A.GT := DT (">", @GTV, AP2, 20, 21, 21)
 A.PLUS := DS ("+", @ADD, MK.PLUS, 25, 25, 25)
 A.MINU := DS ("-", @MINU, MK.MINU, 25, 25, 26)
 A.MUL := DS ("**", @MUL, MK.MUL, 30, 30, 30)
 A.DIV := DS ("/", @DIV, MK.DIV, 30, 30, 31)
 DS ("mod", @MODV, AP2, 30+64, 30, 31)
 DS ("^", @POW, MK.POW, 32, 33, 32)
 
 A.NULL := SET.V ("NULL", @NULL)
 DV ("~", S.CODEV, @MNULL, S.NULL, 35)
 SET.P ("nil", S.NIL)
 SET.D ("ERROR", @ERROR)
 SET.D ("I", @IV)
 SET.P ("do", S.DO)
 SET.P ("then", S.THEN)
 SET.P ("or", S.OR)
 SET.P ("else", S.ELSE)
 SET.P ("by", S.BY)
 SET.P ("if", S.IF)
 SET.P ("unless", S.UNLESS)
 SET.P ("while", S.WHILE)
 SET.P ("until", S.UNTIL)
 SET.P ("repeat", S.REPEAT)
 SET.P ("for", S.FOR)
 SET.F ("PARAM", @PARAM)
 SET.V ("ABS", @ABSV)
 SET.R ("YTAB", @YTAB)
 SET.R ("ZTAB", @ZTAB)
 D ("READ", S.CODE0, @REA)
 SET.C ("GCD", @GCDA)
 SET.P ("fin", S.FIN)
 SET.F ("UNDUMP", @UNDUMP)
 SET.V ("PMAP", @PMAP)
 SET.V ("GLOBAL", @GLOBA)
 SET.F ("NUMBER", @NUMBER)
 SET.R ("STACK", @STACK)
 DY ("true", TRUE, S.PP)
 SET.V ("PRINJ", @PRINJ)
 D ("INPUT", S.BCPLV, @INPUT)
 SET.R ("NEWLINE", @NEWLINE)
 D ("READX", S.CODE0, @READX)
 SET.F ("GET", @GETV)
 SET.V ("PRINTA", @PRINTA)
 SET.V ("PRCH", @PRCH)
 D ("OUTPUT", S.BCPLV, @OUTPUT)
 SET.P ("within", S.WITHIN)
 SET.V ("PRINL", @PRINL)
 SET.V ("SHOW", @SHOW)
 SET.V ("ORDER", @ORDER)
 SET.V ("HD", @HDV)
 SET.V ("MI", @MIV)
 SET.V ("TL", @TLV)
 SET.V ("TY", @TYV)
 SET.V ("RATIONAL", @RAT)
 SET.F ("GETM", @GETMV)
 D ("TRAP", S.CODE3, @TRAP)
 SET.V ("ALG", @ALG)
 SET.C ("ALGATOM", @ALGATOM)
 SET.V ("ATOM", @ATOM)
 SET.V("MAINVAR", @MAINVAR)
 SET.V ("TEMPUS", @TEMPUS)
 SET.R ("PRINF", @WRITEF)
 SET.V ("PRIN", @PRIN)
 SET.V ("FLOAT", @FLOATV)
 SET.V ("FIX", @FIXV)
 SET.C ("RATAPPROX", @RATAPPROX)
 SET.R ("XTAB", @XTAB)
 SET.R ("TAB", @TAB)
 SET.V ("UNTRACE", @UNTRACE)
 SET.V ("ERRORSET", @ERRORSET)
 SET.V ("ERROREVAL", @ERROREVAL)
 SET.P ("in", S.IN)
 SET.F ("LOAD", @G.LOAD)
 SET.C ("FIND", @FIND)
 D ("PUT", S.CODE3, @PUT)
 SET.P ("where", S.WHERE)
 SET.F ("UNLOAD", @G.UNLOAD)
 SET.V ("PRINT", @PRINT)
 SET.C ("GENGLO", @GENGLO)
 SET.V ("SYN", @SYN)
 SET.F ("DUMP", @DUMP)
 SET.V ("PRINE", @PRINE)
 DY ("E", ZE, S.PP)
 DY ("J", ZJ, S.PP)
 SET.P ("and", S.AND)
 SET.V ("REV", @REV)
 D ("PRINK", S.CODE3, @PRINK)
 SET.V ("FUNCTION", @FUNCTION)     // ??F??
 
 SET.P ("(", S.LPAR)
 SET.P (")", S.RPAR)
 SET.Q ("|", MK.LOGOR, S.DIADOP, 0, 14, 13)
 SET.Q ("&", MK.LOGAND, S.DIADOP, 0, 16, 15)
 SET.Q ("~=", MK.NE, S.RELOP, 20, 21, 21)
 SET.Q (">=", MK.GE, S.RELOP, 20, 21, 21)
 SET.Q ("<=", MK.LE, S.RELOP, 20, 21, 21)
 SET.Q ("<", MK.LT, S.RELOP, 20, 21, 21)
 SET.P ("*"", S.Q2)
 SET.P ("#", S.SH1)
 SET.P (".", S.DOT)
 SET.P ("?", S.QR)
 SET.P ("%", S.INFIX)
 SET.P (",", S.TUPLE)
 DV ("$", S.CODEV, @MDOL, S.DLR, 35)
 
// BALANCE ()
 
 CLOCK (TRUE)
 TEMPUSP ("Starting", 0)
 NEWLINE ()
 OKPAL := TRUE
 $)
 
 
//  IF    -   6   2/3,2/3
// WHILE  -   6   2/3
//   ;    2   3   2      (<>   9  10  9)
//  :=    4   5   4
//   ,    -   8   8
//  ->    -  10   9,9
//   %   10  11  11
// AUG   12  12  13
//   |    -  14  13
//   &    -  16  15
//  <<   19  19  22
//  IS   20  21  21
//   +   25  25  25
//   -   25  25  26
//   *   30  30  30
// MOD   30  30  31
//   ^   32  33  32
//  AP   38  38  41
//   '   39  36   -      (dash)
 
 
//   ~   35
//   @   35
//   !   35
//  QU   2   ('   35)
// GOTO  35
// RETU  35
//   $   35
 
 
.
//./       ADD LIST=ALL,NAME=SQUASH
 SECTION "SQUASH"
 
 
GET "PALHDR"
 
 
STATIC
 $( N = 0
 W = 0 $)
 
 
// n.b. HDR>0   ?H
 
 
LET SQFF () BE
 $( FFF!0 := 0        // Lock out free-chain
 FOR I=1 TO MTYPSZ
 FFF!I := ZSQ
 FFF!S.LOC := 0    // Lock these out
 FFF!S.NAME := 0   // ?GENSY
 FFF!S.GLZ := 0
 FFF!S.GLO := 0
 FFF!S.XTUPL := 0
 FFF!S.TRA := 0
 FFF!S.APZ := 0
 FOR I=MTYPSZ+1 TO TYPSZ
 FFF!I := 0
 $)
 
 
AND SQUASH () = VALOF
 $( CLOCK (FALSE)
 IF PARAMD // ?D
 VERIFY ()
 OKPAL := FALSE
 
 $( LET S = STACKP
 UNTIL S=0
 $( LET T = !S
 H1!S, !S := T, 0
 S := T $) $)
 
 FOR I=SVV TO ST2 BY 4
 !I := (!I<<24)+SIGNBIT
 
 SQFF ()   // ?-
 FFF!S.RATL := 0
 FOR I=ST1 TO SVU BY 4
 IF H1!I<0
 SQUASH2 (I)
 
// Now marked store is  1.......[FORWARD]
//                  or          [ chain FFF->ZSQ ]
//                  or  1 <HDR> 0
 
 FOR I=1 TO MTYPSZ
 $( LET S = FFF!I
 IF S=0
 LOOP
 WHILE S<0
 S := H3!S
 UNTIL S=ZSQ
 $( LET T = !S
 !S := (I<<24)+SIGNBIT
 S := T $) $)
 
// now 1.......[FORWARD]
//  or 1 <HDR> 0     ?+
 
 SQFF ()
 FOR I=@E TO @A.NULL
 IF !I>0
 !I := SQUASH1 (!I)
 FOR I=TYP TO TYP+TYPSZ
 IF !I>0
 !I := SQUASH1 (!I)
 $( LET Q1 = @Q1-3
 $( LET Q = 1!Q1>>2
 IF Q<=STACKBASE
 BREAK
 IF !Q<0
 FOR I=Q+3 TO Q1-1
 IF !I>0
 !I := SQUASH1 (!I)
 Q1 := Q $) REPEAT $)
 
// now 1.......[FORWARD]
//  or 1 <HDR> [0, or CHAIN -> ZSQ]
 
 $( LET S = FFF!S.RATL     // FOR I=S.RATN TO S.RATL
 WHILE S<0
 S := H1!S
 UNTIL S=ZSQ
 $( LET T = H1!S
 H1!S, H3!S := H3!S, 0
 S := T $)
 FFF!S.RATL := 0 $)
 
 FOR I=1 TO MTYPSZ
 $( LET S = FFF!I
 IF S=0
 LOOP
 WHILE S<0
 S := H1!S
 UNTIL S=ZSQ
 $( LET T = H1!S
 H1!S := 0
 S := T $) $)
 
 FOR I=SVV TO ST2 BY 4
 RTAILS (I)
 
 W := 0
 FOR I=ST1 TO SVU BY 4
 $( LET J = !I
 IF J<0
 TEST (J & P.TAGP)=0
 $( H1!I, STACKP := STACKP, I
 W := W+4 $)
 OR RTAILS (I) $)
 
 $( LET S = STACKP
 UNTIL S=0
 $( LET T = H1!S
 !S, S := T, T $) $)
 
 N := W*100/SSZ
 INITFF ()
 OKPAL := TRUE
 CLOCK (TRUE)
 IF PARAMV
 $( LET T () BE
 WRITEF ("   %N%% (%N words) heap reclaimed", N, W)
 TEMPUSP ("SQUASH", T) $)
 IF PARAMD // ?D
 VERIFY ()
 RESULTIS N
 $)
 
 
AND FIXC (A) BE
 $( LET W = !A
 IF W>0
 $( LET X = !W
 IF X<0 & (X & P.TAGP)=0
 !A := (X & P.ADDR)+(W & P.TAG) $) $)
 
 
AND RTAILS (I) BE
 $( LET P = !I
 $( LET T = (P & P.TAGP)>>24
 IF T>=MM3
 FIXC (I+3) <> FIXC (I+2)
 !I := T $)
 IF (P & P.ADDR)=0
 RETURN
 $( LET T = H1!P
 H1!P := I+(T & P.TAG)
 IF (T & P.ADDR)=ZSQ
 RETURN
 P := T $) REPEAT
 $)
 
 
AND RTAILS1 (A, B) BE
 $( LET A0, B0 = !A, !B
 IF (B0 & P.ADDR)=0
 $( B0 := ZSQ+(B0 & P.TAG)
 !B := B0 $)
 B := B-1
 $( LET AY, A2, A3 = (!A0 & P.TAGP), H2!A0, H3!A0
 WHILE H2!B0<A2
 $( B := B0
 B0 := H1!B0 $)
 IF H2!B0=A2
 $( WHILE H3!B0<A3
 $( B := B0
 B0 := H1!B0
 IF H2!B0>A2
 GOTO LX $)
 IF H3!B0=A3
 $( WHILE (!B0 & P.TAGP)<AY
 $( B := B0
 B0 := H1!B0
 IF H2!B0>A2 | H3!B0>A3
 GOTO LX $)
 IF (!B0 & P.TAGP)=AY
 $( LET A1 = H1!A0 & P.TAG
 WHILE (H1!B0 & P.TAG)<A1
 $( B := B0
 B0 := H1!B0
 IF H2!B0>A2 | H3!B0>A3 | (!B0 & P.TAGP)>AY
 GOTO LX $)
 IF (H1!B0 & P.TAG)=A1
 $( MSG0 (1, RTAILS1)
 A := A0
 A0 := H1!A0
 UNLESS (!A & P.ADDR)=0
 RTAILS1 (A, B0)
 !A := (B0 & P.ADDR)+SIGNBIT    // share
 LOOP $)
 $)
 $)
 $)
 LX: A := A0
 A0 := H1!A0
 H1!A := (B0 & P.ADDR)+(A0 & P.TAG)
 $( LET T = (A & P.ADDR)+(B0 & P.TAG)
 H1!B, B := T, T $)
 $) REPEATUNTIL (A0 & P.ADDR)=ZSQ
 $)
 
 
AND SQUASH1 (A) = VALOF
 $( LET Q, N = 0, 3
 $( LET U = !A
 IF U<=0
 TEST (U & P.TAGP)=0
 RESULTIS (U & P.ADDR)+(A & P.TAG)
 OR RESULTIS A
 IF U<MM3
 N := 1
 !A := (U<<24)+SIGNBIT $)
 $( IF N=0
 $( UNLESS A>=YFJ
 A := SQUASH3 (A)
 IF Q=0
 RESULTIS A
 $( LET T = !Q
 !Q := A
 A := Q-1
 N, A := A & 3, A-N
 Q := T $)
 LOOP
 $)
 $( LET T = N!A
 IF T<=0
 $( N := N-1
 LOOP $)
 $( LET U = !T
 IF U<=0
 $( IF (U & P.TAGP)=0
 N!A := (U & P.ADDR)+(T & P.TAG)
 N := N-1
 LOOP $)
 !T := (U<<24)+SIGNBIT
 N!A := Q
 Q := A+N
 A := T
 TEST U<MM3
 N := 1
 OR N := 3
 $)
 $)
 $) REPEAT
 $)
 
 
AND SQUASH2 (A) BE      // ?-
 $( LET A1, A2, A3 = H1!A, H2!A, H3!A // ~= ZSY
 LET S1 = FFF-3+!A
 LET S2 = H3!S1
 IF S2=0   // Locked out
 $( !A := (!A<<24)+SIGNBIT
 RETURN $)
 
 $( LET T1, T2 = 0, 0
 
// scan rough chain through H3
 WHILE S2<0
 $( IF H1!S2<=A1
 $( $( IF H1!S2<A1
 $( T1 := !S2
 T2 := !T1
 GOTO L1 $)
 IF H2!S2<=A2
 $( $( IF H2!S2<A2
 $( T1 := !S2
 T2 := !T1
 GOTO L1 $)
 T1 := !S2
 IF H3!T1<=A3
 $( IF H3!T1<A3
 $( T2 := !T1
 GOTO L1 $)
 !A := T1 // share
 RETURN $)
 S1 := S2
 S2 := H3!S2
 IF S2>0
 BREAK
 IF H1!S2<A1
 $( T1 := !S2
 T2 := !T1
 GOTO L1 $)
 $) REPEAT
 BREAK
 $)
 S1 := S2
 S2 := H3!S2
 $) REPEATWHILE S2<0
 BREAK
 $)
 S1 := S2
 S2 := H3!S2
 $)
 
 T1, T2 := H3+S1, S2
 
 L1: UNTIL H1!T2>=A1
 $( T1 := T2
 T2 := !T2 $)
 IF H1!T2=A1 & H2!T2<=A2
 $( IF H2!T2<A2
 $( $( T1 := T2
 T2 := !T2
 IF H1!T2>A1
 GOTO LX $) REPEATWHILE H2!T2<A2
 IF H2!T2>A2
 GOTO LX $)
 IF H3!T2<=A3
 $( IF H3!T2<A3
 $( $( T1 := T2
 T2 := !T2
 IF H2!T2>A2 | H1!T2>A1
 GOTO LX $) REPEATWHILE H3!T2<A3
 IF H3!T2>A3
 GOTO LX $)
 !A := T2+SIGNBIT   // share
 H3!A := S2 // put in rough chain
 H3!S1 := A+SIGNBIT
 RETURN
 $)
 $)
 
// insert
 LX: !A := T2
 !T1 := A
 RETURN
 $)
 $)
 
 
// (!A&P.ADDR)~=0 means cyclic list;
// we must re-direct its parents (RTAILS1) if we leave a
// forwarding-address.
// n.b. fortunately, RATL cannot be cyclic
 
 
AND SQUASH3 (A) = VALOF
 $( LET A0, A1, A2, A3 = !A & P.TAGP, H1!A, H2!A, H3!A
 LET S1 = FFF-1+(A0>>24)
 LET S2 = H1!S1
 IF S2=0 | A2=ZSY | A3=ZSY // Locked out
 RESULTIS A
 
 IF A1<=0
 $( IF A1<0
 $( UNLESS !A=S.RATL      // S.RATN<=!A<=S.RATL
 MSG1 (13, SQUASH3)
 H3!A, H1!A := A1, 0
 A3, A1 := A1, 0 $)
 
 $( LET T1, T2 = 0, 0
 
// scan rough chain through H1
 WHILE S2<0
 $( IF H2!S2<=A2
 $( $( IF H2!S2<A2
 $( T1 := !S2
 T2 := H1!T1
 GOTO L1 $)
 IF H3!S2<=A3
 $( IF H3!S2<A3
 $( T1 := !S2
 T2 := H1!T1
 GOTO L1 $)
 UNLESS (!A & P.ADDR)=0
 RTAILS1 (A, !S2)
 !A := !S2   // share
 RESULTIS (!S2 & P.ADDR)+(A & P.TAG) $)
 S1 := S2
 S2 := H1!S2
 $) REPEATWHILE S2<0
 BREAK
 $)
 S1 := S2
 S2 := H1!S2
 $)
 
 T1, T2 := S1, S2
 
 L1: UNTIL H2!T2>=A2
 $( T1 := T2
 T2 := H1!T2 $)
 IF H2!T2=A2 & H3!T2<=A3
 $( IF H3!T2<A3
 $( $( T1 := T2
 T2 := H1!T2
 IF H2!T2>A2
 GOTO LX $) REPEATWHILE H3!T2<A3
 IF H3!T2>A3
 GOTO LX $)
 UNLESS (!A & P.ADDR)=0
 RTAILS1 (A, T2)
 !A := T2+SIGNBIT   // share
 H1!A := S2 // put in rough chain
 H1!S1 := (A & P.ADDR)+SIGNBIT
 RESULTIS T2+(A & P.TAG)
 $)
 
// insert
 LX: H1!A := T2
 H1!T1 := A & P.ADDR
 RESULTIS A
 $)
 $)
 
 IF A1=ZSY
 RESULTIS A
 
 $( LET A1T = A1 & P.TAG
 LET B = !A1
 IF (B & P.ADDR)=0
 $( H1!A := A1T+ZSQ
 !A1 := (A & P.ADDR)+(B & P.TAG)
 RESULTIS A $)
 A1 := A1-1
 
 UNTIL H2!B>=A2
 $( A1 := B
 B := H1!B $)
 IF H2!B=A2 & H3!B<=A3
 $( IF H3!B<A3
 $( $( A1 := B
 B := H1!B
 IF H2!B>A2
 GOTO LX $) REPEATWHILE H3!B<A3
 IF H3!B>A3
 GOTO LX $)
 IF (!B & P.TAGP)<=A0
 $( IF (!B & P.TAGP)<A0
 $( $( A1 := B
 B := H1!B
 IF H3!B>A3 | H2!B>A2
 GOTO LX $) REPEATWHILE (!B & P.TAGP)<A0
 IF (!B & P.TAGP)>A0
 GOTO LX $)
 IF (H1!B & P.TAG)<=A1T
 $( IF (H1!B & P.TAG)<A1T
 $( $( A1 := B
 B := H1!B
 IF (!B & P.TAGP)>A0 | H3!B>A3 | H2!B>A2
 GOTO LX $) REPEATWHILE (H1!B & P.TAG)<A1T
 IF (H1!B & P.TAG)>A1T
 GOTO LX $)
 UNLESS (!A & P.ADDR)=0
 RTAILS1 (A, B)
 !A := (B & P.ADDR)+SIGNBIT   // share
 RESULTIS (B & P.ADDR)+(A & P.TAG)
 $)
 $)
 $)
 
// insert
 LX: H1!A := (B & P.ADDR)+A1T
 H1!A1 := (A & P.ADDR)+(B & P.TAG)
 RESULTIS A
 $)
 $)
 
 
.
//./       ADD LIST=ALL,NAME=START
 SECTION "START"
 
 
GET "PALHDR"
 
 
LET START () BE
 $( LET U = VEC BUFFL
 BUFFP := U+SIGNBIT
 OCM :=  TABLE 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0, 0   // (120) OP mnemonic
 TYP :=  TABLE 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0, 0   // TYPSZ
 FFF :=  TABLE 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0, 0   // TYPSZ
 OKPAL := FALSE
 ERLEV, ERLAB := LEVEL (), L
 STACKB, STACKL := STACKBASE, STACKEND
 $( LET T = SETIO
 SETIO, PSETIO := PSETIO, T $)
 $( LET T = WFRAME
 WFRAME, PFRAME := PFRAME, T $)
 SETIO ()
 
 G.LOAD ("SETUP", "PALSYS")
 SETUP ()
 G.UNLOAD ("SETUP")
 
 U := FINDINPUT ("SUPERVIS")
 TEST U=0
 RP ()
 OR $( U := GETEX ("SUPERVIS")
 EVAL (U) $)
 END (0)
 
 L: SETIO ()
 UNLESS OKPAL
 MSG1 (1)
 UNLESS ERZ=Z
 $( ARG1 := ERZ
 ERZ := Z
 TEMPUSP ("Re-start", 0)
 EVAL (ARG1) $)
 END (4)
 $)
 
 
AND INITFF () BE
 $( FOR I=0 TO TYPSZ
 FFF!I := MSG2
 FOR I=S.STRING TO S.POLYJ
 FFF!I := IV
 FFF!S.GLZ := MSG3
 FOR I=S.GLG TO S.QU
 FFF!I := SEL2
 FOR I=S.GENSY TO S.NAME
 FFF!I := LOOKUP
 FFF!S.TUPLE := FF.TUPLE
 FFF!S.E := FF.E
 FOR I=S.CLOS TO S.FCLOS
 FFF!I := FF.CLOS
 FFF!S.RECA := FF.RECA
 FFF!S.CONDB := FF.CONDB
 FFF!S.SEQA := FF.SEQA
 FFF!S.DASH := FF.DASH
 FFF!S.A1E := FF.A1E
 FFF!S.AA := FF.A1E
 FFF!S.AVE := FF.AVE
 FFF!S.ZZ := FF.AVE
 FFF!S.A2E := FF.A2E
 $)
 
 
AND PSETIO () BE
 $( PSETIO ()
 WRITEP := PRIN $)
 
 
AND PARAM (P) = VALOF
 $( LET I, J, R = GETBYTE (P, 0), 0, FALSE
 $( LET B, S = TRUE, TRUE
 N: IF J>=I
 RESULTIS R
 J := J+1
 SWITCHON GETBYTE (P, J) INTO
 $(
 CASE '-': B := FALSE
 GOTO N
 CASE '?': S := FALSE
 GOTO N
 CASE 'A': R := PARAMA
 IF S THEN
 PARAMA := B
 LOOP
 CASE 'B': R := PARAMB
 IF S THEN
 PARAMB := B
 LOOP
 CASE 'C': R := PARAMC
 IF S THEN
 PARAMC := B
 LOOP
 CASE 'D': R := PARAMD
 IF S
 $( PARAMD := B
 IF B
 G.LOAD ("PALDD", "PALSYS") $)
 LOOP
 CASE 'F': $( LET T = READSN (P, J)
 ((@G0)!T)()
 LOOP $)
 CASE 'I': R := PARAMI
 IF S THEN
 PARAMI := B
 LOOP
 CASE 'J': R := PARAMJ
 IF S THEN
 PARAMJ := B
 LOOP
 CASE 'K': R := PARAMK
 IF S THEN
 PARAMK := B
 LOOP
 CASE 'L': R := RCH=RCH1
 IF S THEN
 RCH := B -> RCH1, RCH0
 LOOP
 CASE 'M': R := PARAMM
 IF S THEN
 PARAMM := B
 LOOP
 CASE 'N': R := PARAMN
 IF S THEN
 PARAMN := B
 LOOP
 CASE 'Q': R := PARAMQ
 IF S THEN
 PARAMQ := B
 LOOP
 CASE 'R': R := KWORDS+Y0
 IF S
 $( LET T = READSN (P, J) & ~3
 IF T>=1024
 KWORDS := T $)
 LOOP
 CASE 'S': R := KSTACK+Y0
 IF S
 $( LET T = READSN (P, J)
 IF T>=128
 KSTACK := T $)
 LOOP
 CASE 'T': R := SSZ+Y0
 IF S
 SSZ := READSN (P, J)
 LOOP
 CASE 'U': R := KSQ+Y0
 IF S
 KSQ := READSN (P, J)
 LOOP
 CASE 'V': R := PARAMV
 IF S THEN
 PARAMV := B
 LOOP
 CASE 'W': R := CHZ+Y0
 IF S
 $( LET T = READSN (P, J)
 IF 20<=T<=132
 CHZ := T $)
 LOOP
 CASE 'Y': R := PARAMY
 IF S THEN
 PARAMY := B
 LOOP
 CASE 'Z': R := PARAMZ
 IF S THEN
 PARAMZ := B
 LOOP
 $)
 $) REPEAT
 $)
 
 
AND G.LOAD (S1, S2) = VALOF
 $( LET L = LOAD (S1, S2)
 IF L=0
 RESULTIS TRUE
 MSG1 (2, S1, L)
 RESULTIS FALSE $)
 
 
AND G.UNLOAD (S) = VALOF
 $( IF UNLOAD (S)
 RESULTIS TRUE
 MSG0 (2, S)
 RESULTIS FALSE $)
 
 
AND END (N) BE
 $( TEMPUSP ("Stopping", 0)
 SELECTOUTPUT (SYSOUT)
 WRITEF ("# %N cycles; %N cons; value %P*N", CYCLES-Y0, CONS-Y0, ARG1)
 STOP (N) $)
 
 
LET DUMP (A) = A
 
 
AND UNDUMP (A) = A
 
 
.
//./       ADD LIST=ALL,NAME=SYN
 SECTION "SYN"
 
 
GET "PALHDR"
 
 
STATIC
 $( SYM = 0
 LPRIO = 0
 RPRIO = 0
 S0 = 0
 S1 = 0
 S2 = 0 $)
 
 
LET RP () = VALOF
 $( LET E1 = E
 $( IF RCH=RCH1
 UNLESS CHC=0
 NEWLINE ()
 $( LET V = READX ()
 IF RCH=RCH1
 TEST CH='*N'
 RCH ()
 OR NEWLINE ()
 V := EVAL (V)
 IF V>0 & !V=S.E
 E := V $)
 $) REPEATUNTIL Q.INPUT=0
 LL.SY: E := E1
 RESULTIS ARG1
 $)
 
 
AND SYNERROR (N) BE
 $( WRITEF ("*N*N# Syntax error %N(%N)*N ... ", N, SYM)
 UNLESS Q.INPUT=0
 $( FOR I=1 TO 32
 RCH1 ()
 WRITES (" ...*N") $)
 IF PARAMD
 MSG1 (34, SYNERROR)
 Q.ENDREAD (Q.INPUT)
 LONGJUMP (FLEVEL (RP), LL.SY) $)
 
 
AND CHECKRPAR () BE
 UNLESS SYM=S.RPAR
 SYNERROR (10)
 
 
AND CHECKFOR (S, N) BE
 UNLESS SYM=S
 SYNERROR (N)
 
 
AND IGNORE () = VALOF
 $( LET T = Y3
 TEST SYM=S.DO
 T := Y2
 OR UNLESS SYM=S.THEN
 RESULTIS T
 RSYM (FALSE)
 RESULTIS T $)
 
 
AND IGNORE1 () = VALOF
 $( LET T = Y3
 TEST SYM=S.OR
 T := Y2
 OR UNLESS SYM=S.ELSE
 RESULTIS Z
 RSYM (FALSE)
 RESULTIS T $)
 
 
// The symbols ' . are treated funnily
 
 
AND RSYM (B) BE // B -> GLOBAL
 $(N IF CH='*''
 $( SYM := S.DASH
 RCH ()
 RETURN $)
 WHILE CH='*S' | CH='*N'
 RCH ()
 
 $(1 LET ALPH, ALPHC = FALSE, FALSE
 S0, S1 := 0, 0
 $( TEST 'A'<=CH<='Z'
 ALPH, ALPHC := TRUE, TRUE
 OR TEST 'a'<=CH<='z'
 ALPH := TRUE
 OR TEST '0'<=CH<='9'
 UNLESS ALPH
 S1 := S1*10+CH-'0'
 OR BREAK
 IF S0=BUFFL
 SYNERROR (2)
 S0, BUFFP!S0 := S0+1, RCH ()
 $) REPEAT
 
 TEST S0>0
 TEST ALPH
 $( !BUFFP := S0
 S0 := STRING (BUFFP)
 IF ALPHC & H1!S0=Z
 $( MANIFEST
 $( LWC = ~#X40404040 $)
 STATIC
 $( K2 = 0
 K3 = 0 $)
 K2, K3 := H2!S0, H3!S0
 H2!S0, H3!S0 := K2 & LWC, K3 & LWC
 S1 := FINDWORD (S0)
 IF S1~=0 & H3!(H2!S1)<0
 $( S0 := S1
 GOTO RX $)
 H2!S0, H3!S0 := K2, K3
 $)
 S0 := NAME (S0)
 $)
 OR TEST CH='.' & VALOF
 $( LET C = PEEPCH ()
 RESULTIS '0'<=C<='9' $)
 $( IF S0>NUMWI
 MSG1 (14)
 S1, S2 := FLOAT S1, 0
 $( RCH ()
 UNLESS '0'<=CH<='9'
 BREAK
 S2 := S2-1
 S1 := S1 #* FLTEN #+ FLOAT (CH-'0') $) REPEAT
 IF CH='E'
 $( RCH ()
 S2 := S2+READN () $)
 TEST S2>0
 UNTIL S2=0
 S1 := S1 #* FLTEN <> S2 := S2-1
 OR UNTIL S2=0
 S1 := S1 #/ FLTEN <> S2 := S2+1
 SYM, S0 := S.FLT, GETX (S.FLT, 0, S1, 0)
 RETURN
 $)
 OR $( SYM := S.NUM
 TEST S0>NUMWI
 $( !BUFFP := S0
 S0 := NUMBER (BUFFP) $)
 OR S0 := S1+Y0
 RETURN $)
 
 OR $( LET A = GETX (S.STRING, Z, 0, 0)
 PUTBYTE (A, STR1, RCH ())
 PUTBYTE (A, STR1+1, CH)
 S0 := FINDWORD (A)       // try 2 characters
 TEST S0=0
 $( PUTBYTE (A, STR1+1, 0)     // or 1 character
 S0 := FINDWORD (A)
 IF S0=0
 TEST CH=ENDSTREAMCH
 $( SYM := S.FIN
 GOTO LL $)
 OR SYNERROR (3) $)
 OR RCH ()
 $)
 $)1
 
 RX:  S1 := H2!S0
 IF B
 $( S0 := S1
 RETURN $)
 IF H3!S1>=0
 $( SYM := S.NAME
 RETURN $)
 MFN := H2!S1
 IF MFN>0
 $( LET M3 = H3!MFN
 TEST M3<-1  // funny CODE2 ?
 MFN := M3
 OR MFN := H2!MFN $)
 LPRIO, RPRIO, SYM := GETBYTE (S1, 13)+Y0, GETBYTE (S1, 14)+Y0, GETBYTE (S1, 15)
 
 SWITCHON SYM INTO
 $(
 DEFAULT: RETURN
 
 LL:  CASE S.FIN: Q.ENDREAD (Q.INPUT)
 RETURN
 
 CASE S.INFIX:
 RSYM (FALSE)
 TEST SYM=S.DOT
 RSYM (TRUE)
 OR TEST CH='%' $( RCH()
 S1 := MQU(S1) $)
 OR $( CHECKFOR(S.NAME,8)
 S1 := S0 $)
  MFN :=  MA2
 LPRIO, RPRIO, SYM := 11+Y0, 11+Y0, S.DIADOP
 RETURN
 
 CASE S.Q2: S0 := RS ('*"')
 SYM := S.STRING
 RETURN
 
 CASE S.PP: S0 := H2!S1
 RETURN
 
 CASE S.SH1: S1 := RCH ()
 SWITCHON S1 INTO
 $(
 CASE '*S': UNTIL CH='*N' | CH=ENDSTREAMCH
 RCH ()
 CASE '*N': LOOP
 
 CASE 'b':  CASE 'B': S1 := 2
 GOTO L
 CASE 'o':  CASE 'O': S1 := 8
 GOTO L
 CASE 'x':  CASE 'X': S1 := 16
 L:                     S1 := RBASE (S1) & P.ADDR       // 24 bits
 ENDCASE
 
 CASE '#': S1 := RCH ()
 ENDCASE
 CASE 'n':  CASE 'N': S1 := '*N'
 ENDCASE
 CASE 's':  CASE 'S': S1 := '*S'
 ENDCASE
 CASE 'z':  CASE 'Z': S1 := ENDSTREAMCH
 $)
 SYM, S0 := S.NUM, S1+Y0
 RETURN
 $)N REPEAT
 
 
AND RS (GG) = VALOF
 $( LET G = ZS
 S0, GG := GG, @GG | SIGNBIT       // ??B??  GG = @G-1
 S2 := MAXINT
 UNTIL CH=S0
 $( IF CH=ENDSTREAMCH
 SYNERROR (16)
 S1 := CH
 IF CH='#'
 $( RCH ()
 IF CH='*N' | CH='*S'
 $( RCH () REPEATUNTIL CH='#' | CH=ENDSTREAMCH
 GOTO L $)
 TEST CH='N'|CH='n'
  S1 := '*N'
 OR TEST CH='S'|CH='s'
 S1 := '*S'
 OR TEST CH='Z'|CH='z'
 S1 := ENDSTREAMCH
 OR S1 := CH
$)
 IF S2>STR2
 S2, H1!GG, GG := STR1, GETX (S.STRING, ZSY, 0, 0), H1!GG
 PUTBYTE (GG, S2, S1)
 S2 := S2+1
 L:       RCH ()
 $)
 RCH ()
 UNLESS G=ZS
 H1!GG := Z
 RESULTIS G
 $)
 
 
AND READX () = VALOF
 $( LET G, SV = ZSY, GSEQ | SIGNBIT
 IF Q.INPUT=0
 RESULTIS Z
 GSEQ := @G
 $( LET E = REXP (Y0)
 UNTIL G=ZSY
 $( LET G0, A = G, H2!G
 G := H1!G
 IF A=0
 LOOP
 A := LINSEQ (A, Z, Z, SIGNBIT)
 IF A<=0
 A := MQU (A)  // fake
 !G0, H1!G0, H2!G0, H3!G0 := !A, H1!A, H2!A, H3!A $)
 GSEQ := SV
 RESULTIS E
 $)
 $)
 
 
AND REXQ (N) = VALOF    // skip RSYM
 $( (-3)!(@N) := REXP
 IV ()
 GOTO LL.RX $)
 
 
AND REXP (N) = VALOF
 $(E IF @N>STACKL
 STKOVER ()
 RSYM (FALSE)
 LL.RX: $( LET E = Z
 SWITCHON SYM INTO
 $(
 CASE S.LET: $( LET E1 = @N | SIGNBIT   // ??B?? E1=@E-1
 $( H1!E1 := MLET (ZSY, ZSY, ZSY)
 E1 := H1!E1
 RDEF (Y0, E1)
 MLET1 (E1) $) REPEATWHILE SYM=S.LET
 TEST SYM=S.IN
 $( H1!E1 := REXP (Y1)
 RESULTIS E $)
 OR H1!E1 := ZE $)
 ENDCASE
 CASE S.COND: E := REXP (9+Y0)
 $( LET E1 = Z
 IF SYM=S.TUPLE
 E1 := REXP (9+Y0)
 E := COND (E, ZSC, E1) $)
 ENDCASE
 CASE S.DASH: MFN, RPRIO := MQU, 35+Y0  // recover
 CASE S.QU:
 CASE S.RETU:
 CASE S.AA:
 CASE S.ZZ:
 CASE S.NULL:
 CASE S.DLR: $( LET F = MFN
 LET E1 = REXP (RPRIO)
 E := F (E1) $)
 ENDCASE
 CASE S.FCLOS:
 RSYM (FALSE)
 E := RFNDEF (S.DOT+Y0, Y2)
 ENDCASE
 CASE S.REC: RSYM (FALSE)
 $( LET E1 = RBVLIST (S.DOT+Y0)
 LET E2 = RFNDEF (S.DOT+Y0, Y2)
 E := REC (E1, E2) $)
 ENDCASE
 CASE S.TUPLE:
 E := ZSC
 ENDCASE
 CASE S.FOR: RSYM (FALSE)
 $( LET D = RBV (S.RELOP+Y0)
 LET E1 = REXP (8+Y0)
 LET E2, E3, E4 = Z, Y1, Z
 IF SYM=S.TUPLE
 E2 := REXP (8+Y0)
 IF SYM=S.BY
 E3 := REXP (8+Y0)
 RPRIO := IGNORE ()
 E := REXQ (RPRIO)
 RPRIO := IGNORE1 ()
 UNLESS RPRIO=0
 E4 := REXQ (RPRIO)
 E := MFOR (D, E1, E2, E3, E, E4)
 $)
 ENDCASE
 CASE S.UNLESS:
 $( LET S = TRUE
 IF FALSE
 CASE S.IF: S := FALSE
 E := REXP (6+Y0)
 RPRIO := IGNORE ()
 $( LET E1 = REXQ (RPRIO)
 LET E2 = Z
 RPRIO := IGNORE1 ()
 UNLESS RPRIO=0
 E2 := REXQ (RPRIO)
 IF S
 $( S := E1
 E1, E2 := E2, S $)
 E := COND (E, E1, E2) $)
 $)
 ENDCASE
 CASE S.UNTIL:
 $( LET E1 = TRUE
 IF FALSE
 CASE S.WHILE: E1 := FALSE
 E := REXP (6+Y0)
 IF E1
 E := MNULL (E)
 RPRIO := IGNORE ()
 E1 := REXQ (RPRIO)
 E := MWHI (E, E1) $)
 ENDCASE
 CASE S.DIADOP:
 $( LET F, S = MFN, S1
 LET E1 = REXP (RPRIO)
 E := F (Y0, E1, S) $)
 ENDCASE
 CASE S.LPAR: E := REXP (Y0)
 CHECKRPAR ()
 GOTO M1
 CASE S.DOT: IF CH='*S' | CH='*N' | CH=ENDSTREAMCH
 ENDCASE
 RSYM (TRUE)
 CASE S.PP:
 CASE S.NUM:
 CASE S.FLT:
 CASE S.STRING:
 CASE S.NAME: E := S0
 CASE S.NIL:
 M1:         RSYM (FALSE)
 $)
 $(2 LET E2 = Z
 SWITCHON SYM INTO
 $(
 CASE S.WHERE:
 IF N>=Y2
 DEFAULT:    RESULTIS E
 E2 := MLET (ZSY, ZSY, ZSY)
 RDEF (Y0, E2)
 MLET1 (E2)
 H1!E2 := E
 E := E2
 LOOP
 CASE S.COLON:
 UNLESS !E=S.NAME
 SYNERROR (7)
 E2 := REXP (N)
 RESULTIS COLON (E, E2)
 CASE S.TUPLE:
 IF N>=8+Y0
 RESULTIS E
 E := AUG (ZSY, E)
 $( E2 := REXP (8+Y0)
 E := AUG (E, E2) $) REPEATWHILE SYM=S.TUPLE
 E := REVD (E)
 LOOP
 CASE S.COND: IF N>=10+Y0
 RESULTIS E
 $( LET E1 = REXP (9+Y0)
 IF SYM=S.TUPLE
 E2 := REXP (9+Y0)
 E := COND (E, E1, E2)
 LOOP $)
 CASE S.RELOP:
 IF N>=LPRIO
 RESULTIS E
 $( LET F, S = MFN, S1
 LET E1 = REXP (RPRIO)
 E := F (E, E1, S)
 WHILE SYM=S.RELOP
 $( LET F, S = MFN, S1
 LET E2 = REXP (RPRIO)
 LET E3 = F (E1, E2, S)
 E1 := E2
 E := MK.LOGAND (E, E3) $) $)
 LOOP
 CASE S.DIADOP:
 IF N>=LPRIO
 RESULTIS E
 $( LET F, S = MFN, S1
 LET E1 = REXP (RPRIO)
 E := F (E, E1, S) $)
 LOOP
 CASE S.DASH: $( RSYM (FALSE)
 E := MDASH (E) $) REPEATWHILE SYM=S.DASH
 LOOP
 CASE S.LPAR: E2 := REXP (Y0)
 CHECKRPAR ()
 GOTO M2
 CASE S.QU:
 CASE S.AA:
 CASE S.ZZ:
 CASE S.NULL:
 CASE S.DLR: $( LET F = MFN
 LET E1 = REXP (RPRIO)
 E2 := F (E1) $)
 GOTO M3
 CASE S.QR: UNLESS 'A'<=CH<='Z' | 'a'<=CH<='z' | '0'<=CH<='9'
 RESULTIS E
 RSYM (TRUE)
 E2, E := E, S0
 GOTO M2
 CASE S.DOT: IF CH='*S' | CH='*N' | CH=ENDSTREAMCH
 RESULTIS E
 RSYM (TRUE)
 CASE S.PP:
 CASE S.NUM:
 CASE S.FLT:
 CASE S.STRING:
 CASE S.NAME: E2 := S0
 CASE S.NIL:
 M2:         RSYM (FALSE)
 M3:         E := AP1 (E, E2)
 $)2 REPEAT
 $)E
 
 
AND RDEF (N, D) BE
 $( RSYM (FALSE)
 SWITCHON SYM INTO
 $(
 CASE S.LPAR: RDEF (Y0, D)
 CHECKRPAR ()
 RSYM (FALSE)
 ENDCASE
 DEFAULT: H2!D := RBVLIST (S.RELOP+Y0)
 H3!D := RFNDEF (S.RELOP+Y0, Y1)
 ENDCASE
 CASE S.REC: RDEF (3+Y0, D)
 H3!D := REC (H2!D, H3!D)
 $)
 $(2 SWITCHON SYM INTO
 $(
 CASE S.WITHIN:
 IF N>=3+Y0
 DEFAULT:    RETURN
 $( LET D2, D3 = H2!D, H3!D
 RDEF (Y0, D)
 N := FN (D2, H3!D)
 H3!D := AP1 (N, D3)
 RETURN $)
 CASE S.AND: IF N>=6+Y0
 RETURN
 $( LET D2 = AUG (Z, H2!D)
 LET D3 = AUG (ZSY, H3!D)
 $( RDEF (6+Y0, D)
 D2 := AUG (D2, H2!D)
 D3 := AUG (D3, H3!D) $) REPEATWHILE SYM=S.AND
 H2!D, H3!D := D2, REVD (D3)
 $)2 REPEAT
 $)
 
 
AND RFNDEF (S, N) = VALOF
 $( IF SYM=S-Y0
 RESULTIS REXP (N)
 $( LET D = RBVLIST (S)
 IF D=ZSC
 RESULTIS REXQ (N)
 N := RFNDEF (S, N)
 RESULTIS FN (D, N) $) $)
 
 
AND RBV (S) = VALOF
 $( IF SYM=S-Y0
 RESULTIS Z
 IF SYM=S.TUPLE
 RESULTIS Z
 $( LET D = Z
 SWITCHON SYM INTO
 $(
 DEFAULT: RESULTIS ZSC
 CASE S.LPAR: RSYM (FALSE)
 D := RBVLIST (S.RPAR+Y0)
 CHECKRPAR ()
 ENDCASE
 CASE S.DLR: MFN := MDOLV
 CASE S.QU:
 CASE S.AA:
 CASE S.ZZ: $( LET F = MFN
 RSYM (FALSE)
 D := RBV (S)
 RESULTIS F (D) $)
 CASE S.DOT: RSYM (TRUE)        // but not LAMBDA .a ...
 CASE S.NAME: D := S0
 CASE S.NIL:
 $)
 RSYM (FALSE)
 WHILE SYM=S.DASH
 $( RSYM (FALSE)
 D := MDASH (D) $)
 RESULTIS D
 $)
 $)
 
 
AND RBVLIST (S) = VALOF
 $( LET D = RBV (S)
 UNLESS SYM=S.TUPLE
 RESULTIS D
 D := AUG (Z, D)
 $( RSYM (FALSE)
 $( LET D1 = RBV (S)
 D := AUG (D, D1) $) $) REPEATWHILE SYM=S.TUPLE
 RESULTIS D $)
 
 
.
//./       ADD LIST=ALL,NAME=TRANS
 SECTION "TRANS"
 
 
GET "PALHDR"
 
 
STATIC
 $( SG = 0 $)
 
 
LET SIMNAME (A) = VALOF
 $( IF A>0 & !A=S.NAME | !A=S.GENSY | !A=S.DASH
 RESULTIS TRUE
 RESULTIS FALSE $)
 
 
AND SIMTUP (A) = VALOF
 $( $( UNLESS SIMNAME (H2!A)
 RESULTIS FALSE
 A := H1!A $) REPEATUNTIL A=Z
 RESULTIS TRUE $)
 
 
AND FN (A, B) = MCLOS1 (ZE, A, B)
 
 
AND REC (A, B) = VALOF
 $( LET F = DOREC
 IF B<=0
 RESULTIS B
 TEST EVSY (B)
 SG := S.RECA
 OR SG := S.REC
 IF SIMNAME (A)
 F := DORECA
 RESULTIS GET4 (SG, B, A, F) $)
 
 
AND MLET (A, B, C) = VALOF
 $( IF C<=0
 RESULTIS MSEQ (B, C)
 TEST EVSY (B)
 TEST SIMNAME (A)
 SG := S.LETB
 OR SG := S.LETA
 OR SG := S.LET    // LET2?
 RESULTIS GET4 (SG, C, A, B) $)
 
 
AND MLET1 (A) BE
 IF EVSY (H3!A)
 TEST SIMNAME (H2!A)
 !A := S.LETB
 OR !A := S.LETA
 
 
AND RETU (A) = GET4 (S.RETU, 0, A, 0)
 
 
AND MQU (A) = GET4 (S.QU, 0, A, 0)
 
 
AND MNULL (A) = MK.A1V (A.NULL, A, NULL)
 
 
AND MDASH (A) = VALOF
 $( LET N = Y1
 IF A<=0
 RESULTIS Y0
 IF !A=S.DASH
 $( N := H2!A+1
 A := H1!A $)
 RESULTIS GET4 (S.DASH, A, N, DIFR) $)
 
 
AND MDOL (A) = VALOF
 $( A := MK.ZZ (A)
 RESULTIS MK.AA (A) $)
 
 
AND MDOLV (A) = VALOF   // in BV part, it has to be the other way round
 $( A := MK.AA (A)
 RESULTIS MK.ZZ (A) $)
 
 
AND MK.AA (A) = GET4 (S.AA, 0, A, LVV)
 
 
AND MK.ZZ (A) = GET4 (S.ZZ, 0, A, IV)   // ?RVV
 
 
// F (EVAL) looks at LVs, but ~F (OCODE) flattens them
 
 
AND MATCHBV (C, D, F) = VALOF
 $( UNLESS F
 IF D>=YLOC
 D := H1!D
 IF TYV (D)=A.QU
 $( D := H2!D
 UNLESS F
 IF D>=YLOC
 D := H1!D $)
 $( IF C>0
 SWITCHON !C INTO
 $(
 CASE S.LOC: IF F
 RESULTIS FALSE
 C := H1!C
 LOOP
 CASE S.TUPLE:
 UNLESS D>0 & !D=S.TUPLE & H3!C=H3!D
 RESULTIS FALSE
 $( UNLESS MATCHBV (H2!C, H2!D, F)
 RESULTIS FALSE
 C, D := H1!C, H1!D $) REPEATUNTIL D=Z
 ENDCASE
 CASE S.QU: RESULTIS FALSE
 CASE S.AA:
 CASE S.ZZ: RESULTIS SIMNAME (H2!C)
 $)
 RESULTIS TRUE
 $) REPEAT
 $)
 
 
AND FIXAP (A) BE
 UNTIL A=Z
 $( LET A3 = H3!A
 LET S = AP1 (H1!A, H2!A)
 IF S<=0
 MSG1 (13, AP1)
 !A, H1!A, H2!A, H3!A := !S, H1!S, H2!S, H3!S
 A := A3 $)
 
 
AND AP1 (A, B) = VALOF
 $( $( LET T = TYV (A)
 TEST T=A.QU
 $( LET L, V = LL.AP, H2!A
 IF V<=0
 RESULTIS A
 SWITCHON !V INTO
 $(
 CASE S.UNSET:
 H3!A := GET4 (S.APZ, A, B, H3!A)
 RESULTIS H3!A
 CASE S.CDY: TEST MATCHBV (H3!V, B, TRUE)
 L := LA.ENTY
 OR
 CASE S.CDX: L := LA.ENTX
 ENDCASE
 CASE S.ACLOS:
 RESULTIS MK.A (A, B, V)
 CASE S.CODEV:
 RESULTIS MK.A1V (A, B, H2!V)
 CASE S.CODE1:
 RESULTIS MK.A1 (A, B, H2!V)
 CASE S.CODE2:
 IF B>0 & !B=S.TUPLE & H3!B=Y2
 $( LET V3 = H3!V
 IF V3<-1 & V3~=AP2
 RESULTIS (V3)(H2!B, H2!(H1!B), A)
 TEST EVSY (B)
 SG := S.A2E
 OR SG := S.AP2
 RESULTIS GET4 (SG, A, B, H2!V) $)
 L := LA.APCODE2
 ENDCASE
 CASE S.CLOS2:
 IF B>0 & !B=S.TUPLE & H3!B=Y2
 $( TEST EVSY (B)
 SG := S.A2A
 OR SG := S.AA2
 RESULTIS GET4 (SG, A, B, V) $)
 L := LA.APCLOS2
 ENDCASE
 CASE S.ECLOS:
 IF B>0 & !B=S.TUPLE & H3!B=H3!(H2!V)
 $( TEST EVSY (B)
 SG := S.AEA
 OR SG := S.AAA
 RESULTIS GET4 (SG, A, B, V) $)
 L := LA.APECLOS
 ENDCASE
 CASE S.FCLOS:
 L := LA.APFCLOS
 ENDCASE
 CASE S.LOC: L := LA.APLOC
 ENDCASE
 CASE S.TUPLE:
 L := LA.APTUP
 ENDCASE
 $)
 TEST EVSY (B)
 SG := S.AQE
 OR SG := S.APQ
 RESULTIS GET4 (SG, A, B, L)
 $)
 OR IF T=A.FCLOS & H1!A=ZE
 RESULTIS MLET (H2!A, B, H3!A)
 $)
 IF A<=0
 RESULTIS A
 TEST EVSY (A) & EVSY (B)
 SG := S.APPLE
 OR SG := S.APPLY
 RESULTIS GET4 (SG, A, B, Z)
 $)
 
 
AND MA2 (A, B, F) = VALOF
 $( B := AUG (Z, B)
 B := AUG (B, A)
 RESULTIS AP1 (F, B) $)
 
 
AND MK.A (A, B, F) = VALOF
 $( TEST EVSY (B)
 SG := S.A1A
 OR SG := S.AA1
 RESULTIS GET4 (SG, A, B, F) $)
 
 
AND MK.A1V (A, B, F) = VALOF
 $( TEST EVSY (B)
 SG := S.AVE
 OR SG := S.APV
 RESULTIS GET4 (SG, A, B, F) $)
 
 
AND MK.A1 (A, B, F) = VALOF
 $( TEST EVSY (B)
 SG := S.A1E
 OR SG := S.AP1
 RESULTIS GET4 (SG, A, B, F) $)
 
 
AND AP2 (A, B, F) = VALOF
 $( TEST EVSY (A) & EVSY (B)
 SG := S.A2E
 OR SG := S.AP2
 B := AUG (Z, B)
 B := AUG (B, A)
 RESULTIS GET4 (SG, F, B, H2!(H2!F)) $)
 
 
AND MCLOS1 (E, V, F) = VALOF    // ??U??
 $( TEST V<=0 // ??Z??
 SG := S.CLOS
 OR TEST SIMNAME (V)
 SG := S.ACLOS
 OR TEST !V=S.TUPLE & SIMTUP (V)
 TEST H3!V=Y2
 SG := S.CLOS2
 OR SG := S.ECLOS
 OR SG := S.FCLOS
 RESULTIS GET4 (SG, E, V, F)
 $)
 
 
AND MK.AUG (A, B, F) = VALOF
 $( IF A=Z
 RESULTIS AUG (Z, B)
 RESULTIS AP2 (A, B, F) $)
 
 
AND MK.LOGOR (A, B) = MCOND (A, TRUE, B)        // nb not destructive
 
 
AND MK.LOGAND (A, B) = MCOND (A, B, FALSE)      // nb not destructive
 
 
AND MK.NE (A, B) = VALOF
 $( A := AP2 (A, B, A.EQ)
 RESULTIS MNULL (A) $)
 
 
AND MK.GE (A, B) = VALOF
 $( A := AP2 (B, A, A.GT)
 RESULTIS MNULL (A) $)
 
 
AND MK.LT (A, B) = AP2 (B, A, A.GT)
 
 
AND MK.LE (A, B) = VALOF
 $( A := AP2 (A, B, A.GT)
 RESULTIS MNULL (A) $)
 
 
AND MK.PLUS (A, B, F) = VALOF
 $( IF A=Y0
 RESULTIS B
 IF B=Y0
 RESULTIS A
 IF ARITHV(A)&ARITHV(B) RESULTIS ADD(A,B)
 RESULTIS AP2 (A, B, F) $)
 
 
AND MK.MINU (A, B, F) = VALOF
 $( IF B=Y0
 RESULTIS A
 IF ARITHV(A) & ARITHV (B)
 RESULTIS MINU (A,B)
 RESULTIS AP2 (A, B, F) $)
 
 
AND MK.MUL (A, B, F) = VALOF
 $( IF A=Y0 | B=Y0
 RESULTIS Y0
 IF A=Y1
 RESULTIS B
 IF B=Y1
 RESULTIS A
 IF ARITHV(A) & ARITHV (B)
 RESULTIS MUL (A,B)
 RESULTIS AP2 (A, B, F)
 $)
 
 
AND MK.DIV (A, B, F) = VALOF
 $( IF ARITHV (A) & ARITHV (B)
 RESULTIS DIV (A, B)
 IF A=Y0
 RESULTIS Y0
 IF B=Y1
 RESULTIS A
 RESULTIS AP2 (A, B, F) $)
 
 
AND MK.POW (A, B, F) = VALOF
 $(
 IF ARITHV(A)&ARITHV(B) RESULTIS POW(A,B)
 IF B=Y0
 RESULTIS Y1
 IF B=Y1 | A=Y0 | A=Y1
 RESULTIS A
 RESULTIS AP2 (A, B, F) $)
 
 
AND MWHI (E, F) = VALOF         // (REC A NIL. [E] -> [F] <> A NIL) NIL
 $( LET A = ASYM (Y0)
 $( LET K = AP1 (A, Z)
 F := SEQ (F, K) $)
 E := COND (E, F, Z)
 E := FN (Z, E)
 E := REC (A, E)
 RESULTIS AP1 (E, Z) $)
 
 
AND MFOR (I, L, R, S, F, V) = VALOF
 $( LET A = ASYM (Y0)
 IF R=Z
 $( IF S=Y1     // (REC A B. (FN I. I -> [F] <> A(B+1), [V])(L B)) 1
 $( $( LET B = ASYM (YM)
 $( LET K = MK.PLUS (B, Y1, A.PLUS)
 K := AP1 (A, K)
 F := SEQ (F, K) $)
 F := COND (I, F, V)
 F := FN (I, F)
 L := AP1 (L, B)
 F := AP1 (F, L)
 F := FN (B, F) $)
 F := REC (A, F)
 RESULTIS AP1 (F, Y1)
 $)
// (REC A I. I -> [F] <> A S, [V]) L
 S := AP1 (A, S)
 F := SEQ (F, S)
 F := COND (I, F, V)
 F := FN (I, F)
 F := REC (A, F)
 RESULTIS AP1 (F, L)
 $)
// (REC A I. I <=/>= R -> [F] <> A(I+S), [V]) L
 $( LET K = MK.PLUS (I, S, A.PLUS)
 K := AP1 (A, K)
 F := SEQ (F, K)
 TEST GTV (S, Y0)
 K := MK.LE
 OR K := MK.GE
 K := K (I, R)
 F := COND (K, F, V) $)
 F := FN (I, F)
 F := REC (A, F)
 RESULTIS AP1 (F, L)
 $)
 
 
AND MCOLON (A, B) = VALOF
 $( LET B1 = B
 WHILE B1>0 & !B1=S.COLON
 B1 := H2!B1
 IF B1<=0 | A<=0
 RESULTIS B
 RESULTIS GET4 (S.COLON, A, B, B1) $)
 
 
AND MSEQ (E, F) = VALOF
 $( IF E<=0
 RESULTIS F
 $( LET F2 = F
 WHILE F2>0 & !F2=S.COLON
 F2 := H2!F2
 TEST EVSY (E) & EVSY (F2)
 SG := S.SEQA
 OR SG := S.SEQ
 E := GET4 (SG, E, F2, Z)
 UNTIL F=F2
 $( E := GET4 (S.COLON, H1!F, E, H3!F)
 F := H2!F $)
 RESULTIS E
 $)
 $)
 
 
AND MCOND (A, B, C) = VALOF
 $( WHILE A>0 & H3!A=NULL & (!A=S.APV | !A=S.AVE)
 $( LET T = B
 B, C := C, T
 A := H2!A $)
 $( LET B2, C2 = B, C
 WHILE B2>0 & !B2=S.COLON
 B2 := H2!B2
 WHILE C2>0 & !C2=S.COLON
 C2 := H2!C2
 TEST A<=0
 TEST A<0
 A := B
 OR A := C
 OR $( TEST EVSY (A)
 TEST EVSY (B2) & EVSY (C2)
 SG := S.CONDB
 OR SG := S.CONDA
 OR SG := S.COND
 A := GET4 (SG, A, B2, C2) $)
 UNTIL B=B2
 $( A := GET4 (S.COLON, H1!B, A, H3!B)
 B := H2!B $)
 UNTIL C=C2
 $( A := GET4 (S.COLON, H1!C, A, H3!C)
 C := H2!C $)
 RESULTIS A
 $)
 $)
 
 
AND COLON (A, B) = VALOF
 $( IF A<=0
 RESULTIS B
 IF B>0 & !B=S.MB
 $( H2!B := GET4 (S.COLON, A, H2!B, 0)
 RESULTIS B $)
 B := GET4 (S.COLON, A, B, 0)
 B := GET4 (S.MB, !GSEQ, B, 0)
 !GSEQ := B
 RESULTIS B $)
 
 
AND SEQ (A, B) = VALOF
 $( IF A<=0
 RESULTIS B
 IF !A=S.MB
 $( IF B>0 & !B=S.MB
 $( LET B0 = B
 B := H2!B
 H2!B0 := 0 $)
 H2!A := GET4 (S.SEQ, H2!A, B, 0)
 RESULTIS A $)
 IF B>0 & !B=S.MB
 $( H2!B := GET4 (S.SEQ, A, H2!B, 0)
 RESULTIS B $)
 A := GET4 (S.SEQ, A, B, 0)
 A := GET4 (S.MB, !GSEQ, A, 0)
 !GSEQ := A
 RESULTIS A
 $)
 
 
AND COND (A, B, C) = VALOF
 $( IF A<=0
 A := GET4 (S.SEQ, Z, A, 0)     // fake
 IF !A=S.MB
 $( IF B>0 & !B=S.MB
 $( LET B0 = B
 B := H2!B
 H2!B0 := 0 $)
 IF C>0 & !C=S.MB
 $( LET C0 = C
 C := H2!C
 H2!C0 := 0 $)
 H2!A := GET4 (S.COND, H2!A, B, C)
 RESULTIS A
 $)
 IF B>0 & !B=S.MB
 $( IF C>0 & !C=S.MB
 $( LET C0 = C
 C := H2!C
 H2!C0 := 0 $)
 H2!B := GET4 (S.COND, A, H2!B, C)
 RESULTIS B $)
 IF C>0 & !C=S.MB
 $( H2!C := GET4 (S.COND, A, B, H2!C)
 RESULTIS C $)
 A := GET4 (S.COND, A, B, C)
 A := GET4 (S.MB, !GSEQ, A, 0)
 !GSEQ := A
 RESULTIS A
 $)
 
 
AND LINSEQ (A, E, F, X) = VALOF
 $( IF @A>STACKL
 STKOVER ()
 $( IF A>0
 SWITCHON !A INTO
 $(
 CASE S.SEQ:
 CASE S.SEQA: E := LINSEQ (H2!A, E, F, X)
 A, X := H1!A, FALSE
 LOOP
 CASE S.COND:
 CASE S.CONDA:
 CASE S.CONDB:
 F := LINSEQ (H3!A, E, F, X)
 E := LINSEQ (H2!A, E, F, X)
 A, X := H1!A, TRUE
 LOOP
 CASE S.COLON:
 E := LINSEQ (H2!A, E, F, X)
 RESULTIS MCOLON (H1!A, E)
 CASE S.MB: MSG1 (-1)        // ?D
 $)
 IF X=SIGNBIT
 RESULTIS A
 TEST X
 RESULTIS MCOND (A, E, F)
 OR RESULTIS MSEQ (A, E)
 $) REPEAT
 $)
 
 
.
//./       ENDUP
