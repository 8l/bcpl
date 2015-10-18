/*

This is a sytematically edited version of the PAL compiler preserved
as the dump of an IBM 370 PDS.  It can now be compiled for the BCPL
Cintsys system using the the extended compiler called xbcpl.

Due to obvious problems with the library functions and such disallowed
features as assignments to non global functions, the compiled version
does not yet run.

Martin Richards 18 Oct 2010


As time allows I am reformating the source and will ultimately attempt
to make it run. Simultaneously, I am constructing a new implementation
of PAL as it was in 1968. The current state of this is freely
available via the PAL distribution in my home page.

*/

/*
This first section provides the interface between the library functions
used byt the IBM 360/370 version of PAL and the Cintsys library.
*/

SECTION "INTERFACE"

GET "pal75hdr"
GET "libhdr"

STATIC {
datstr=0
}

LET dummy (a) = a
 
LET getbyte(s, i) = s%i

LET putbyte(s, i, byte) BE s%i := byte
 
LET time() = sys(Sys_cputime)

LET cinabort(n) = abort(n)

LET load(s1, s2) BE
{ sawritef("load: %s %s*n", s1, s2)
  //cinabort(1000)
}

LET timeofday() = VALOF
{ LET dv = VEC 1
  datstr := TABLE 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
  datstamp(dv)
  dat_to_strings(dv, datstr)
  RESULTIS datstr
}

LET date() = VALOF
{ LET dv = VEC 1
  datstr := TABLE 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
  datstamp(dv)
  dat_to_strings(dv, datstr)
sawritef("*ndate=>%s*n", datstr+5)
  RESULTIS datstr+5
}

.

//./       ADD LIST=ALL,NAME=ADD
SECTION "ADD"
 
GET "pal75hdr"
 
MANIFEST { ny0 = -y0 }

STATIC {
 sg  = 0
 ga1 = 0
 ga2 = 0
 ga3 = 0
 ga4 = 0
}

LET add (a, b) = VALOF SWITCHON coerce (@a, TRUE) INTO
{
  CASE s_num:
    RESULTIS sadd (a+b+signbit)

  CASE s_numj:
    IF numarg RESULTIS longas1 (b, a, TRUE)
    UNLESS (a NEQV b)>=ysg RESULTIS longadd (a, b)
    { LET c = longcmp (a, b)
      IF c=0 RESULTIS y0
      IF c<0 DO { LET t = a; a, b := b, t }
    }
    RESULTIS longsub (a, b)

  CASE s_ratn:
    IF numarg DO
      { IF a=y0 DO RESULTIS b
        a := smul (a, h1!b)
        TEST a<=0
        THEN a := sadd (a+h2!b+signbit)
        ELSE a := longas1 (a, h2!b, TRUE)
        TEST a<=0
        THEN sg := s_ratn
        ELSE sg := s_ratl
        RESULTIS get4 (sg, h1!b, a, 0)
      }
    IF worse DO   // A is NUMJ
    { a := longmul1 (a, h1!b)
      a := longas1 (a, h2!b, TRUE)  // H1!B>Y1 -> A+H2!B is still long
      RESULTIS get4 (s_ratl, h1!b, a, 0)
    }
    { LET u, v = h1!a, h1!b
      ga1 := igcd (u+ny0, v+ny0)
      a := smul (h2!a, (v+ny0)/ga1+y0)
      u := (u+ny0)/ga1+y0
      b := smul (h2!b, u)
      TEST a<=0 & b<=0
      THEN a := sadd (a+b+signbit)
      ELSE a := add (a, b)       // LEAVES GA1
      IF a=y0 RESULTIS y0
      UNLESS ga1=1 DO
      { TEST a<=0
        THEN ga1 := igcd (a+ny0, ga1) <>
             a := (a+ny0)/ga1+y0
        ELSE ga1 := gcd1 (a, ga1+y0) <>
             a := longdiv1 (a, ga1+y0)
        v := (v+ny0)/ga1+y0
      }
      u := smul (u, v)
      IF u=y1 RESULTIS a
      TEST a<=0 & u<=0
      THEN sg := s_ratn
      ELSE sg := s_ratl
      RESULTIS get4 (sg, u, a, 0)
    }

   CASE s_ratl:
   CASE s_ratp:
     IF worse DO
     { IF a=y0 RESULTIS b
       a := mul (a, h1!b)
       a := add (a, h2!b)    // now A ~= Y0
       RESULTIS get4 (!b, h1!b, a, h3!b)
     }
     { LET u, v = h1!a, h1!b
       { LET d = gcda (u, v)
         TEST d=y1
         THEN a := mul (h2!a, v)
         ELSE { u := div (u, d)
                { LET t = div (v, d)
                  a := mul (h2!a, t)
                }
              }
         b := mul (h2!b, u)
         a := add (a, b)
         IF a=y0 RESULTIS y0
         UNLESS d=y1 DO
         { d := gcda (a, d)
           UNLESS d=y1 DO a, v := div (a, d), div (v, d)
         }
       }
       u := mul (u, v)
       IF u=y1 RESULTIS a
       TEST a<=0 & u<=0
       THEN sg := s_ratn
       ELSE TEST u>0 & !u=s_poly
            THEN RESULTIS get4 (s_ratp, u, a, h3!u)
            ELSE sg := s_ratl
       RESULTIS get4 (sg, u, a, 0)
     }

   CASE s_poly:
     IF worse RESULTIS addp1 (a, b)
     RESULTIS addpoly (a, b)

   CASE s_flt:
     RESULTIS getx (s_flt, 0, gw1 #+ gw2, 0)

   CASE s_fpl:
     msg1 (14)

   DEFAULT:
     IF a=y0 RESULTIS b
     IF b=y0 RESULTIS a
     RESULTIS arithfn (a, b, a_plus)
}
 
 
LET minu (a, b) = VALOF SWITCHON coerce (@a, FALSE) INTO
{
  CASE s_num:
    RESULTIS sadd (a-b)

  CASE s_numj:
    IF numarg TEST worse1
              THEN RESULTIS longas1 (a, b, FALSE)
              ELSE RESULTIS longas1 (b NEQV ysg, a, TRUE)
    IF (a NEQV b)>=ysg RESULTIS longadd (a, b)
    { LET c = longcmp (a, b)
      IF c=0 RESULTIS y0
      IF c<0 DO
      { c := a
        a := b NEQV ysg
        b := c
      }
    }
    RESULTIS longsub (a, b)

  CASE s_ratn:
    IF numarg TEST worse1
              THEN { IF b=y0 RESULTIS a
                     b := smul (h1!a, b)
                     TEST b<=0
                     THEN b := sadd (h2!a-b)
                     ELSE b := longas1 (b NEQV ysg, h2!a, TRUE)
                     TEST b<=0
                     THEN sg := s_ratn
                     ELSE sg := s_ratl
                     RESULTIS get4 (sg, h1!a, b, 0)
                   }
              ELSE { a := smul (a, h1!b)
                     TEST a<=0
                     THEN a := sadd (a-h2!b)
                     ELSE a := longas1 (a, h2!b, FALSE)
                     TEST a<=0
                     THEN sg := s_ratn
                     ELSE sg := s_ratl
                     RESULTIS get4 (sg, h1!b, a, 0)
                   }
    IF worse TEST worse1
             THEN { b := longmul1 (b NEQV ysg, h1!a)
                    b := longas1 (b, h2!a, TRUE)
                    RESULTIS get4 (s_ratl, h1!a, b, 0)
                  }
             ELSE { a := longmul1 (a, h1!b)
                    a := longas1 (a, h2!b, FALSE)
                    RESULTIS get4 (s_ratl, h1!b, a, 0)
                  }
    { LET u, v = h1!a, h1!b
      ga1 := igcd (u+ny0, v+ny0)
      a := smul (h2!a, (v+ny0)/ga1+y0)
      u := (u+ny0)/ga1+y0
      b := smul (h2!b, u)
      TEST a<=0 & b<=0
      THEN a := sadd (a-b)
      ELSE a := minu (a, b)      // LEAVES GA1
      IF a=y0 RESULTIS y0
      UNLESS ga1=1 DO
      { TEST a<=0
        THEN ga1 := igcd (a+ny0, ga1) <>
             a := (a+ny0)/ga1+y0
        ELSE ga1 := gcd1 (a, ga1+y0) <>
             a := longdiv1 (a, ga1+y0)
        v := (v+ny0)/ga1+y0
      }
      u := smul (u, v)
      IF u=y1 RESULTIS a
      TEST a<=0 & u<=0
      THEN sg := s_ratn
      ELSE sg := s_ratl
      RESULTIS get4 (sg, u, a, 0)
    }

  CASE s_ratl:
  CASE s_ratp:
    IF worse DO
    { TEST worse1
      THEN { IF b=y0 RESULTIS a
             gw1 := mul (h1!a, b)
             b := a
             a := minu (h2!a, gw1)
           }
      ELSE { a := mul (a, h1!b)
             a := minu (a, h2!b)
           }
      RESULTIS get4 (!b, h1!b, a, h3!b)
    }
    { LET u, v = h1!a, h1!b
      { LET d = gcda (u, v)
        TEST d=y1
        THEN a := mul (h2!a, v)
        ELSE { u := div (u, d)
               { LET t = div (v, d)
                 a := mul (h2!a, t)
               }
             }
        b := mul (h2!b, u)
        a := minu (a, b)
        IF a=y0 RESULTIS y0
        UNLESS d=y1 DO
        { d := gcda (a, d)
          UNLESS d=y1 DO a, v := div (a, d), div (v, d)
        }
      }
      u := mul (u, v)
      IF u=y1 RESULTIS a
      TEST a<=0 & u<=0
      THEN sg := s_ratn
      ELSE TEST u>0 & !u=s_poly
           THEN RESULTIS get4 (s_ratp, u, a, h3!u)
           ELSE sg := s_ratl
      RESULTIS get4 (sg, u, a, 0)
    }
 
  CASE s_poly:
    IF worse DO
    { LET t = a
      TEST worse1
      THEN { IF b=y0 RESULTIS a
             a := neg (b)
           }
      ELSE t := b NEQV ysg
      RESULTIS addp1 (a, t)
    }
    RESULTIS addpoly (a, b NEQV ysg)

  CASE s_flt:
    RESULTIS getx (s_flt, 0, gw1 #- gw2, 0)

  CASE s_fpl:
    msg1 (14)

  DEFAULT:
    IF b=y0 RESULTIS a
    IF eqlv (a, b) RESULTIS y0
    RESULTIS arithfn (a, b, a_minu)
}

.
//./       ADD LIST=ALL,NAME=ARITH
SECTION "ARITH"

GET "pal75hdr"

LET arithv (p) = VALOF
{ IF p>0 DO
  { LET p0 = !p
    UNLESS s_flt<=p0<=s_poly RESULTIS FALSE
  }
  RESULTIS TRUE
}
 
// IF THIS WAS CLEVERER, WE COULD MISS 'IF ... =Y0 ...' IN ADD ETC
 
 
AND arithfn (p, q, f) = VALOF
{ LET e, v, w = ze, z, z
  TEST af0 (@p, @e)
  THEN GOTO l
  ELSE TEST af0 (@q, @e)
       THEN p := af1 (@e, p)
       ELSE { v := gensym ()
              w := v
              p := af1 (@e, p)
     l:       q := af1 (@e, q)
            }
  f := (h3!(h2!f))(p, q, f)
  RESULTIS mclos1 (e, v, f)
}
 
 
// ALL THIS TO TRY AND AVOID GENSYMS
 
 
AND af0 (ap, ae) = VALOF
 { LET p = !ap
 IF p>0
 SWITCHON !p INTO
 {
 CASE s_clos:
 CASE s_aclos:
 !ae, 1!ae, 2!ae := h1!p, h2!p, h2!p
 !ap := h3!p
 RESULTIS TRUE
 CASE s_clos2:
 CASE s_eclos:
 !ae, 1!ae := h1!p, h2!p
 2!ae := rev (h2!p)
 !ap := h3!p
 RESULTIS TRUE
 }
 RESULTIS FALSE
 }
 
 
AND af1 (ae, b) = VALOF
 { IF b<=0
 RESULTIS b
 SWITCHON !b INTO
 {
 CASE s_aclos:
 CASE s_clos2:
 CASE s_eclos:
 CASE s_fclos:
 IF eqlv (h1!b, !ae)
 { IF eqlv (h2!b, 1!ae)
 RESULTIS h3!b
 RESULTIS mlet (h2!b, 2!ae, h3!b) }
 CASE s_jclos:
 CASE s_tuple:
 CASE s_xtupl:
 b := mqu (b)
 RESULTIS ap1 (b, 2!ae)
 CASE s_clos: IF eqlv (h1!b, !ae)
 RESULTIS h3!b
 CASE s_flt:
 CASE s_fpl:
 CASE s_numj:
 CASE s_ratn:
 CASE s_ratl:
 CASE s_ratp:
 CASE s_poly: RESULTIS b
 DEFAULT: msg1 (22, b)
 }
 }
 
 
// Return the worse case; if commut, swap if it makes the first arg better
// if not commut, flag WORSE1
// Sometimes flag NUMARG, WORSE
// Note that RATL & RATN -> not WORSE
// POLY and RATP are ordered together by main-ness
 
 
LET coerce (a, commut) = VALOF
 { numarg, worse, worse1 := FALSE, FALSE, FALSE
 { LET p = !a
 IF p<=0
 { UNLESS p<-1
 TEST p=0
 !a := y0
 ELSE !a := y1
 numarg := TRUE
 { LET q = 1!a
 IF q<=0
 { UNLESS q<-1
 TEST q=0
 1!a := y0
 ELSE 1!a := y1
 RESULTIS s_num }
 SWITCHON !q INTO
 {
 CASE s_loc: 1!a := h1!q
 LOOP
 CASE s_flt: gw1 := FLOAT (!a-y0)
 gw2 := h2!q
 CASE s_fpl:
 CASE s_ratl:
 CASE s_poly:
 CASE s_ratp: worse := TRUE
 CASE s_numj:
 CASE s_ratn: RESULTIS !q
 DEFAULT: RESULTIS s_loc
 }
 } REPEAT
 }
 
 SWITCHON !p INTO
 {
 CASE s_loc: !a := h1!p
 LOOP
 CASE s_numj: { LET q = 1!a
 IF q<=0
 { UNLESS q<-1
 TEST q=0
 1!a := y0
 ELSE 1!a := y1
 numarg := TRUE
 TEST commut
 !a, 1!a := q, p
 ELSE worse1 := TRUE
 RESULTIS s_numj }
 SWITCHON !q INTO
 {
 CASE s_loc: 1!a := h1!q
 LOOP
 CASE s_numj: RESULTIS s_numj
 CASE s_ratn:
 CASE s_ratl:
 CASE s_ratp:
 CASE s_poly: worse := TRUE
 RESULTIS !q
 CASE s_flt:
 CASE s_fpl: msg1 (14)
 DEFAULT: RESULTIS s_loc
 }
 } REPEAT
 CASE s_ratn: { LET q = 1!a
 IF q<=0
 { UNLESS q<-1
 TEST q=0
 1!a := y0
 ELSE 1!a := y1
 numarg := TRUE
 TEST commut
 !a, 1!a := q, p
 ELSE worse1 := TRUE
 RESULTIS s_ratn }
 SWITCHON !q INTO
 {
 CASE s_loc: 1!a := h1!q
 LOOP
 CASE s_numj: worse := TRUE
 TEST commut
 !a, 1!a := q, p
 ELSE worse1 := TRUE
 CASE s_ratn: RESULTIS s_ratn
 CASE s_fpl:
 CASE s_ratp:
 CASE s_poly: worse := TRUE
 RESULTIS !q
 CASE s_ratl: RESULTIS s_ratl
 CASE s_flt: gw1 := FLOAT (h2!p-y0) #/ FLOAT (h1!p-y0)
 gw2 := h2!q
 RESULTIS s_flt
 DEFAULT: RESULTIS s_loc
 }
 } REPEAT
 CASE s_ratl: { LET q = 1!a
 IF q<=0
 { UNLESS q<-1
 TEST q=0
 1!a := y0
 ELSE 1!a := y1
 worse := TRUE
 TEST commut
 !a, 1!a := q, p
 ELSE worse1 := TRUE
 RESULTIS s_ratl }
 SWITCHON !q INTO
 {
 CASE s_loc: 1!a := h1!q
 LOOP
 CASE s_numj: worse := TRUE
 TEST commut
 !a, 1!a := q, p
 ELSE worse1 := TRUE
 CASE s_ratn:
 CASE s_ratl: RESULTIS s_ratl
 CASE s_ratp:
 CASE s_poly: worse := TRUE
 RESULTIS !q
 CASE s_flt:
 CASE s_fpl: msg1 (14)
 DEFAULT: RESULTIS s_loc
 }
 } REPEAT
 CASE s_ratp: { LET q = 1!a
 IF q<=0
 { UNLESS q<-1
 TEST q=0
 1!a := y0
 ELSE 1!a := y1
 worse := TRUE
 TEST commut
 !a, 1!a := q, p
 ELSE worse1 := TRUE
 RESULTIS s_ratp }
 SWITCHON !q INTO
 {
 CASE s_loc: 1!a := h1!q
 LOOP
 CASE s_numj:
 CASE s_ratn:
 CASE s_ratl:
 CASE s_flt:
 CASE s_fpl: TEST commut
 !a, 1!a := q, p
 ELSE worse1 := TRUE
 worse := TRUE
 RESULTIS s_ratp
 CASE s_poly: worse := TRUE
 IF h3!p>=h3!q
 { TEST commut
 !a, 1!a := q, p
 ELSE worse1 := TRUE
 RESULTIS s_ratp }
 RESULTIS s_poly
 CASE s_ratp: TEST h3!p>h3!q
 { TEST commut
 !a, 1!a := q, p
 ELSE worse1 := TRUE
 worse := TRUE }
 ELSE UNLESS h3!p=h3!q
 worse := TRUE
 RESULTIS s_ratp
 DEFAULT: RESULTIS s_loc
 }
 } REPEAT
 CASE s_poly: { LET q = 1!a
 IF q<=0
 { UNLESS q<-1
 TEST q=0
 1!a := y0
 ELSE 1!a := y1
 worse := TRUE
 TEST commut
 !a, 1!a := q, p
 ELSE worse1 := TRUE
 RESULTIS s_poly }
 SWITCHON !q INTO
 {
 CASE s_loc: 1!a := h1!q
 LOOP
 CASE s_numj:
 CASE s_ratn:
 CASE s_ratl:
 CASE s_flt:
 CASE s_fpl: TEST commut
 !a, 1!a := q, p
 ELSE worse1 := TRUE
 worse := TRUE
 RESULTIS s_poly
 CASE s_poly: TEST h3!p>h3!q
 { TEST commut
 !a, 1!a := q, p
 ELSE worse1 := TRUE
 worse := TRUE }
 ELSE UNLESS h3!p=h3!q
 worse := TRUE
 RESULTIS s_poly
 CASE s_ratp: worse := TRUE
 IF h3!p>h3!q
 { TEST commut
 !a, 1!a := q, p
 ELSE worse1 := TRUE
 RESULTIS s_poly }
 RESULTIS s_ratp
 DEFAULT: RESULTIS s_loc
 }
 } REPEAT
 CASE s_flt: gw1 := h2!p
 { LET q = 1!a
 IF q<=0
 { TEST q<-1
 gw2 := FLOAT (q-y0)
 ELSE TEST q=0
 gw2 := 0.0
 ELSE gw2 := 1.0
 RESULTIS s_flt }
 SWITCHON !q INTO
 {
 CASE s_loc: 1!a := h1!q
 LOOP
 CASE s_ratn: gw2 := FLOAT (h2!q-y0) #/ FLOAT (h1!q-y0)
 RESULTIS s_flt
 CASE s_flt: gw2 := h2!q
 RESULTIS s_flt
 CASE s_fpl:
 CASE s_numj:
 CASE s_ratl: msg1 (14)
 CASE s_ratp:
 CASE s_poly: worse := TRUE
 RESULTIS !q
 DEFAULT: RESULTIS s_loc
 }
 } REPEAT
 CASE s_fpl: { LET q = 1!a
 IF q<=0
 { UNLESS q<-1
 TEST q=0
 1!a := y0
 ELSE 1!a := y1
 numarg := TRUE
 TEST commut
 !a, 1!a := q, p
 ELSE worse1 := TRUE
 RESULTIS s_fpl }
 SWITCHON !q INTO
 {
 CASE s_loc: 1!a := h1!q
 LOOP
 CASE s_flt:
 CASE s_numj:
 CASE s_ratn:
 CASE s_ratl: worse := TRUE
 TEST commut
 !a, 1!a := q, p
 ELSE worse1 := TRUE
 RESULTIS s_fpl
 CASE s_ratp:
 CASE s_poly: worse := TRUE
 RESULTIS !q
 DEFAULT: RESULTIS s_loc
 }
 } REPEAT
 CASE s_string:
 { LET q = 1!a
 IF q>=yloc
 q := h1!q
 IF q>0 & !q=s_string
 RESULTIS s_string }
 DEFAULT: RESULTIS s_loc
 }
 } REPEAT
 }
 
 
.
//./       ADD LIST=ALL,NAME=BLIB
 SECTION "BLIB"
 
 
GET "pal75hdr"
 
 
MANIFEST
 { entrymask = #xFFF0FFFF
 entryword = #x9040F000
 nargsmask = #x000F0000
 globword = #xC7D3F000
 bcplbit = #x800000
 evenstack = #x5C40E2E3
 oddstack = #xC3D2405C
 overflow = 0
 unset = 1 //   STACKHWM()  RESULTS
 countword1 = #x45EB0000 | 20
 countword2 = countword1+60
 }
 
 
LET setio () BE
{ STATIC { zz = 0 }
  zero := @zz | signbit
///sawritef("setio: setting zero = %x8*n", zero)
  wrc, writep := wrch, writen
  sysout := output() ///findoutput ("SYSPRINT")
  chc, chz := 0, 130
  q_output := 0
  TEST sysout=0
  THEN { LET s = findlog ()
         IF s=0 DO writetolog ("NO SYSPRINT") <>
                   stop (104)
         selectoutput (s)
       }
  ELSE q_seloutput (sysout)
  sysin := input() ///findinput ("SYSIN")
  ch, rch := endstreamch, rch0
  q_input := 0
  q_selinput (sysin)
}

LET q_selinput (s) BE
  UNLESS q_input=s | s=0 DO
  { UNLESS q_input=0 DO unrdch ()
    selectinput (s)
    q_input := s
    ch := rdch ()
  }

AND q_seloutput (s) BE
  UNLESS q_output=s | s=0 DO
  { UNLESS chc=0 | q_output=0 DO wrc ('*N')
    selectoutput (s)
    q_output := s
    chc := 0
  }
 
 
AND q_endread (s) BE
  UNLESS s=0 TEST q_input=s
  THEN { endread ()
         q_input := 0
         ch := endstreamch
       }
  ELSE { selectinput (s)
         endread ()
  UNLESS q_input=0
  selectinput (q_input)
}
 
 
AND q_endwrite (s) BE
 UNLESS s=0
 TEST q_output=s
 { endwrite ()
 q_output := 0
 chc := 0 }
 ELSE { selectoutput (s)
 endwrite ()
 UNLESS q_output=0
 selectoutput (q_output) }
 
 
AND rch0 () = VALOF
 { LET c = ch
 ch := rdch ()
 RESULTIS c }
 
 
AND rch1 () = VALOF
 { LET c = rch0 ()
 UNLESS c=endstreamch
 { IF chc=0
 writes ("# ")
 wch (c) }
 RESULTIS c }
 
 
AND peepch () = VALOF
 { LET c = rdch ()
 unrdch ()
 RESULTIS c }
 
 
AND wch (b) BE
 { TEST b='*N'
 chc := 0
 ELSE TEST chc>=chz
 { writes ("*N      ")
 chc := 7 }
 ELSE chc := chc+1
 wrc (b) }
 
 
AND wch1 (b) BE
 TEST b='*N'
 escw ('N')
 ELSE TEST b='*'' | b='*"' | b='#'
 escw (b)
 ELSE wch (b)
 
 
AND escw (c) BE
 { LET t = chc
 chc := chc+1
 wch ('#')
 IF chc<t
 chc := chc+1
 wrc (c) }
 
 
AND tab (n) BE
 { TEST n<=chc
 newline ()
 ELSE IF n>chz
 { newline ()
 RETURN }
 UNTIL n<=chc
 wch (' ') }
 
 
AND xtab (n) BE
 tab (n+chc)
 
 
AND ytab (n) BE
 UNLESS n=0 | chc=0
 xtab (n-chc REM n)
 
 
AND ztab (n) BE
 { ytab (n)
 IF chc+n>=chz
 newline () }
 
 
AND writes (s) BE
  FOR i=1 TO getbyte (s, 0) DO
    wch (getbyte (s, i))
 
 
AND unpackstring (s, v) BE
 FOR i=0 TO getbyte (s, 0) DO
 v!i := getbyte (s, i)
 
 
AND packstring (v, s) = VALOF
 
 { LET n = !v & #xFF
 LET i = n/4
 LET x = v!i       //       SAVE IN CASE  S=V
 
 s!i := 0
 FOR p=0 TO n DO
 putbyte (s, p, v!p)
 putbyte (s, i, x)
 RESULTIS i }
 
 
AND eqdd (p, q) = VALOF
 { FOR i=0 TO getbyte (p, 0)
 UNLESS (getbyte (p, i) & ~#x40)=(getbyte (q, i) & ~#x40)
 RESULTIS FALSE
 RESULTIS TRUE }
 
 
AND writef (format, a, b, c, d, e, f) BE
 
 { LET t = @a
 
 FOR p=1 TO getbyte (format, 0) DO
 { LET ch = getbyte (format, p)
 
 TEST ch='%' THEN
 { LET f, arg, n = 0, !t, 0
 p := p+1
 
 { LET type = getbyte (format, p)
 SWITCHON type INTO
 
 {
 DEFAULT: wch (type)
 ENDCASE
 
 CASE 'P': f := writep
 GOTO l
 CASE 'A': f := writearg
 GOTO l
 CASE 'E': f := arg
 t, arg := t+1, !t
 GOTO l
 CASE 'T': wtime (time ())
 LOOP
 CASE 'U': f := wtime
 GOTO l
 CASE 'V': f := wtime1
 GOTO l
 CASE 'Y': f := ytab
 GOTO l
 CASE 'Z': f := ztab
 GOTO l
 CASE 'F': f := wrflt
 GOTO l
 CASE 'S': f := writes
 GOTO l
 CASE 'C': f := wch
 GOTO l
 CASE 'O': f := writeoct
 GOTO l1
 CASE 'X': f := writehex
 GOTO l1
 CASE 'I': f := writed
 GOTO l1
 CASE 'J': f := writel
 GOTO l1
 CASE 'N': f := writed
 GOTO l
 CASE 'M': UNLESS chc=0
 newline ()
 LOOP
 
 l1:         p := p+1
 n := getbyte (format, p)
 n := ('0'<=n<='9') -> n-'0', n+10-'A'
 
 l:          f (arg, n)
 t := t+1
 }}}
 
 ELSE wch (ch)
 }
 }
 
 
 
 
//      THE ROUTINES THAT FOLLOW PROVIDE POST-MORTEM INFORMATION IN
//      THE SPECIFIC ENVIRONMENT OF O.S. FOR THE IBM/360-370.
//
//      THE ROUTINES ARE INTERDEPENDENT WITH ROUTINES IN 'BCPLMAIN'
 
 
AND wtime (t) BE
{ t := 26*t/1000
  TEST t>1000
  THEN writef ("%N.%J2 s", t/1000, (t REM 1000)/10)
  ELSE writef ("%N ms", t)
}
 
 
AND wtime1 (t) BE
{ t := 26*t/10000
  writef ("%N.%J2", t/100, t REM 100)
}
 
 
AND validcode (p) = VALOF
 { p := p & p_addr
 IF (loadpoint & pagemask)<=p<=stackbase
 RESULTIS TRUE
 RESULTIS FALSE }
 
 
AND validentry (p) = VALOF
 { IF validcode (p) & (!p & entrymask)=entryword & getbyte (p, -8)<8
 RESULTIS TRUE
 RESULTIS FALSE }
 
 
AND nargs (f) = ((!f & nargsmask)>>16)-6
 
 
AND abort (code, addr, oldstack, data) BE
 
 { MANIFEST
 { globcon79 = globword+4*79
 globcon129 = globword+4*129
 globcon137 = globword+4*137
 globcon138 = globword+4*138 }
 setio ()
 
 { LET scc, ucc = (code>>12) & #xFFF, code & #xFFF
 LET user = (scc=0)
 LET soft = user
 LET svalid = oldstack=!(@code-2)
 code := user -> ucc, scc
 
 TEST user THEN
 writef ("*N*NSTEP ABEND USER CODE %N (%T)*N", code)
 
 ELSE SWITCHON code INTO
 
 {
 CASE #xC0:
 CASE #xC1:
 CASE #xC2:
 CASE #xC3:
 CASE #xC4:
 CASE #xC5:
 CASE #xC6:
 CASE #xC7:
 CASE #xC8:
 CASE #xC9:
 CASE #xCA:
 CASE #xCB:
 CASE #xCC:
 CASE #xCD:
 CASE #xCE:
 CASE #xCF: { LET gaddr = (addr-globword-2 & #xFFFFFF)>>2
 writef ("*N*NPROGRAM INTERRUPT %X3 AT %N(%X6)*N",
 code, addr>>2, addr)
 IF 0<gaddr<10000 DO
 writef ("*NIS G%N DEFINED?*N", gaddr) }
 ENDCASE
 
 CASE #x0D1: writef ("*N*NCOMP EXHAUSTED AT %N AFTER %U*N", addr>>2, data)
 soft := TRUE
 
 CASE #x0D2: ENDCASE //    FATAL I/O ERROR
 
 CASE #x0D3: writes ("*N*NSTACK OVERFLOW*N")
 ENDCASE
 
 DEFAULT: writef ("*N*NSTEP ABEND SYSTEM CODE %X3 (%T)*N", code)
 soft := TRUE
 }
 
 IF soft
 UNLESS softerror=globcon129
 { UNLESS svalid
 erlev, erlab := level (), l
 softerror (code, svalid) }
 
 l: UNLESS userpostmortem=globcon79
 userpostmortem (code, svalid)
 
 TEST svalid
 UNLESS sysout=0
 backtrace ()
 ELSE { writef ("*NSTACK PTR LOST %N*N", @code-3)
 UNLESS sysout=0 | stackb=globcon137 | stackl=globcon138
 { LET q = stackb
 l: { LET f, r = (!q & p_addr)+16*1024, q<<2
 FOR p=q+3 TO stackl
 { IF 1!p=r & validentry ((!p & p_addr)>>2)
 { LET p2 = 2!p & p_addr
 IF validcode (p2>>2) & p2<f
 { q := p
 GOTO l } } } }
 TEST q>stackb
 { writef ("CONJECTURED BACKTRACE FROM %N(%A)", q, !q)
 backtr (stackb, q) }
 ELSE { writef ("STACK FROM %N TO %N*N", stackb, stackl)
 FOR i=stackb TO stackl
 writef ("%Z%N %A", 12, i, !i) }
 }
 }
 
 UNLESS sysout=0 DO
 mapstore ()
 }
 
 stop (100)
 }
 
 
AND errormessage (fault, format, routine, ddname) BE
 
 { LET ostream, sysout = output (), 0
 
 UNLESS eqdd ("SYSPRINT", ddname)
 sysout := findoutput ("SYSPRINT")
 IF sysout=0 DO
 sysout := findlog ()
 IF sysout=0 DO
 { writetolog ("ERROR MESSAGES REQUIRE SYSPRINT")
 RETURN }
 
 selectoutput (sysout)
 writef ("*N*NFAULT %N IN ROUTINE %S*N", fault, routine)
 writef (format, ddname)
 writes ("*N*N")
 selectoutput (ostream)
 }
 
 
AND stackhwm () = VALOF
 
 { LET q = !(stackend-1)  //   INITIALISATION LIMIT
 
 UNLESS !(stackend-2)=evenstack
 RESULTIS overflow
 UNLESS stackbase<=q<stackend
 RESULTIS overflow
 
 UNLESS !q=evenstack
 RESULTIS unset
 
 FOR p=q-2 TO stackbase BY -2 DO
 
 { UNLESS p!1=oddstack
 RESULTIS p+2
 UNLESS p!0=evenstack
 RESULTIS p+1
 }}
 
 
AND mapstore () BE
{ LET mapseg (s, p1, p2) BE
  { LET map = (s=0)
 
    IF map DO writef ("*NMAP AND COUNTS FROM %N(%X6) TO %N*N",
                      p1, p1<<2, p2)
 
    FOR p=p1 TO (p2-10) DO
    { IF map & validentry (p+2) DO
      { writef ("%Z%I7/%S", 19, p+2, p)
        LOOP
      }
 
      IF p!0=loadpoint!0 & p!1=loadpoint!1 & (p!4>>24)=11 & (p!7>>24)<=8 DO
      { UNLESS s=0 DO
        { IF map RETURN
          TEST eqdd (s, p+7)
          THEN map := TRUE
          ELSE LOOP
        }
        writef ("*N*N%I7  SECTION %S   ", p, p+7)
        writef ("COMPILED ON%S   LENGTH %N WORDS*N",
                p+4, (p!2 & #xFFFF)>>2)
        LOOP
      }
 
      IF map & (p!0=countword1 | p!0=countword2) DO
        writef ("%Z%I7:%I7", 19, p, p!1)
    }
  }

  LET mapload (s) BE
  { LET p = (savearea!29)>>2    //   HEAD OF LOAD LIST
    UNTIL p=0 DO
    { IF (p!9 & bcplbit)~=0 & (s=0 | eqdd (s, p+7)) DO
      { writef ("*N*N*N*NLOADED MODULE *"%S*"*N", p+7)
        mapseg (0, (p!3)>>2, (p!4)>>2)
      }
      p := !p>>2
    }
  }

  LET hwm = stackhwm ()
 
  writes ("*N*NEXTENT OF STACK*N*N")
  writef ("     LIMIT OF STACK      %I7*N", stackend)
  writes ("     HIGH WATER MARK   ")
  TEST hwm=overflow
  THEN writes ("     BRIM*N")
  ELSE TEST hwm=unset
       THEN writes ("    UNSET*N")
       ELSE writef ("%I9*N", hwm)
  writef ("     BASE OF STACK       %I7*N*N*N", stackbase)
 
  mapgvec ()
  mapseg (0, loadpoint, endpoint)   //   MAIN PROGRAM AREA
  mapload (0)
 
  writes ("*N*N")
}
 
 
AND mapgvec () BE
{ writef ("*NGLOBAL VECTOR(%N) ", @g0)
  TEST 80<=g0<=10000
  THEN writef ("%N GLOBALS ALLOCATED*N", g0)
  ELSE { g0 := 400
         writes ("GLOBAL ZERO LOST*N")
       }
 
  FOR t=1 TO g0 UNLESS (@g0)!t=globword+(t<<2) DO
    writef ("%ZG%I4 %A", 12, t, (@g0)!t)
 
  writes ("*N*N*N")
}
 
 
AND backtrace () BE
  backtr (stackbase, level ()>>2)
 
 
AND backtr (l, p) BE
{ writes ("*N*NBACKTRACE CALLED*N")
 
  FOR i=1 TO 500 DO
  { LET q = p
    p := 1!p>>2
    IF p<l | p=q DO
    { writes ("*N   FLOOR")
      BREAK
    }
 
    tab (123)
    writef ("<%N", (2!q & p_addr)-(!p & p_addr))
 
    writef ("*N%I6: %A", p, !p)
    UNLESS wframe (p, q, writearg) BREAK
  }
 
  writes ("*N*NEND OF BACKTRACE*N*N")
}
 
 
AND wframe (p, q, r) = VALOF
{ IF q>p+18 DO q := p+18
 FOR t=p+3 TO q-1 DO
 { ztab (20)
   IF chc=0 DO tab (20)
   r (!t, FALSE)
 }
 RESULTIS validcode (!p>>2)
}
 
 
AND writearg (v) BE
{ LET a = v & p_addr
  { LET f = a>>2
    IF validcode (f) DO
    { TEST validentry (f)
      THEN writef ("'%S'", f-2)
      ELSE writef ("*"%X2:%N", v>>24, f)
      RETURN
    }
  }
  IF validcode (v) DO writef ("'%X2:%N", v>>24, a) <>
                      RETURN
 
  IF v=evenstack | v=oddstack DO writes ("STACK") <>
                                 RETURN
 
  IF v>p_addr | v<-p_addr DO writef ("%X2:%N", v>>24, a) <>
                             RETURN
 
  writen (v)
}
 
 
 
// THE DEFINITIONS THAT FOLLOW ARE MACHINE INDEPENDENT
 
 
AND wn (n, d, c) BE
{ LET t = VEC 10
  AND i, k = 0, -n
  IF n<0 DO d, k := d-1, n
  t!i, k, i := -(k REM 10), k/10, i+1 REPEATUNTIL k=0
  FOR j=i+1 TO d DO wch (c)
  IF n<0 DO wch ('-')
  FOR j=i-1 TO 0 BY -1 DO wch (t!j+'0')
}
 
 
AND writed (n, d) BE
  wn (n, d, '*S')
 
 
AND writel (n, d) BE
  wn (ABS n, d, '0')
 
 
AND writen (n) BE
  wn (n, 0)
 
 
AND newline () BE
  wch ('*N')
 
 
AND readn () = VALOF
{ LET neg = FALSE
  WHILE ch='*S' | ch='*N'
  rch ()
  IF ch='+' | ch='-' DO { neg := ch='-'; rch () }
  { LET sum = rbase (10)
    IF neg RESULTIS -sum
    RESULTIS sum
  }
}
 
AND rbase (base) = VALOF
{ LET sum = 0
  { LET d = nval (ch)
    IF d>=base RESULTIS sum
    sum := base*sum+d
    rch ()
  } REPEAT
}
 
 
AND nval (c) = VALOF
{ IF '0'<=c<='9' RESULTIS c-'0'
 IF 'A'<=c<='F' RESULTIS c-'A'+10
 RESULTIS 4096
}
 
 
AND readsn (p, i) = VALOF
{ LET k, n = getbyte (p, 0), 0
  { IF i>=k RESULTIS n
    i := i+1
    { LET q = getbyte (p, i)
      UNLESS '0'<=q<='9' RESULTIS n
      n := 10*n+q-'0'
    }
  } REPEAT
}
 
 
AND writeoct (n, d) BE
{ IF d>1 DO writeoct (n>>3, d-1)
 wch ((n & 7)+'0')
}
 
 
AND writehex (n, d) BE
{ IF d>1 DO writehex (n>>4, d-1)
 wch ((n & 15)! TABLE '0', '1', '2', '3', '4', '5', '6', '7',
                      '8', '9', 'A', 'B', 'C', 'D', 'E', 'F')
}
 
 
AND writeo (n) BE
  writeoct (n, 8)
 
 
AND writex (n) BE
  writehex (n, 8)
 
 
AND wrflt (x) BE
{ IF x #= 0.0 DO writes ("0.0") <>
                 RETURN
  IF x #< 0.0 DO wch ('-') <>
                 x :=  #- x
  { LET e = 7
    UNTIL x #> 1000000.0 DO x := x #* 10.0 <>
                            e := e-1
    UNTIL x #< 10000000.0 DO x := x #/ 10.0 <>
                             e := e+1
    x := (FIX x+5)/10
    TEST x<100000
    THEN x := 100000
    ELSE WHILE x>=1000000 DO x, e := x/10, e+1
    TEST e=1
    THEN wch ('0'+x/100000) <>
         e, x := 0, x REM 100000
    ELSE wch ('0')
    wch ('.')
    writel (x, 5)
    UNLESS e=0 DO wch ('E') <>
                  writen (e)
  }
}
 
 
.
//./       ADD LIST=ALL,NAME=DIFR
 SECTION "DIFR"
 
 
GET "pal75hdr"
 
 
LET difr (p, n) = VALOF
 { FOR i=y1 TO g_posint (n)
 p := difr1 (p)
 RESULTIS p }
 
 
AND difr1 (p) = VALOF
 { IF @p>stackl
 stkover ()
 { IF p<=0
 RESULTIS y0
 SWITCHON !p INTO
 {
 CASE s_loc: p := h1!p
 LOOP
 CASE s_numj:
 CASE s_ratn:
 CASE s_ratl:
 CASE s_flt:
 CASE s_fpl: RESULTIS y0
 DEFAULT: msg1 (16, difr1, p)
 
 CASE s_ratp: { LET s1 = difr1 (h2!p)
 s1 := mul (s1, h1!p)
 { LET s2 = difr1 (h1!p)
 s2 := mul (s2, h2!p)
 s1 := minu (s1, s2) }
 IF s1=y0
 RESULTIS y0
 p := mul (h1!p, h1!p)
 RESULTIS div (s1, p) }
 
 CASE s_poly: { LET r = y0
 { LET q = mdash (h2!p)
 q := find (q, e)
 TEST q=z
 q := y0
 ELSE UNLESS q=y0
 { LET p1 = h1!p NEQV (p & ysg)
 IF h3!p1=y0
 p1 := h1!p1 NEQV (p1 & ysg)
 r := get4 (s_poly, zsy, h2!p, h3!p)
 { LET r0 = r
 { LET t = mul (h2!p1, h3!p1)
 t := get4 (s_polyj, zsy, t, h3!p1-1)+(p1 & ysg)
 h1!r0, r0 := t, t
// The sign of P1 should be OK now
 p1 := h1!p1 } REPEATUNTIL p1=z
 TEST h3!r0=y0
 TEST r0<ysg
 r := h2!r0
 ELSE r := neg (h2!r0)
 ELSE h1!r0 := z
 }
 r := mul (r, q)
 }
 }
 { LET p1 = h1!p NEQV (p & ysg)
 { LET d = difr1 (h2!p1)
 UNLESS d=y0
 { TEST h3!p1=y0
 IF p1>=ysg
 d := neg (d)
 ELSE { LET t = get4 (s_polyj, z, y1, h3!p1)
 t := get4 (s_poly, t, h2!p, h3!p)+(p1 & ysg)
 d := mul (d, t) }
 r := add (r, d) }
 p1 := h1!p1 NEQV (p1 & ysg)
 } REPEATUNTIL (p1 & p_addr)=z
 }
 RESULTIS r
 }
 }
 } REPEAT
 }
 
 
.
//./       ADD LIST=ALL,NAME=ERMSG
 SECTION "ERMSG"
 
 
GET "pal75hdr"
 
 
LET msg0 (n, a, b, c, d) BE
 { LET s, w = zero, wrc
 wrc := wrch
 selectoutput (sysout)
 writef ("*N*N# (%T) ")
 SWITCHON n INTO
 {
 DEFAULT: msg1 (13, msg0)
 CASE 1:  s := "Doubt about %A"
 ENDCASE
 CASE 2:  s := "Load/unload error %S"
 ENDCASE
 CASE 3:  s := "Bad print (%N)"
 ENDCASE }
 writef (s, a, b, c, d)
 newline ()
 selectoutput (q_output)
 wrc := w
 }
 
 
AND msg1 (n, a, b, c, d) BE
 { LET s = zero
 wrc := wrch
 q_seloutput (sysout)
 writef ("*N*N# (%T) ")
 SWITCHON n INTO
 {
 DEFAULT: a := n
 s := "System error %N"
 GOTO l2
 CASE 0:  GOTO l1
 CASE 1:  s := "Trap while Pal region unavailable*N"
 GOTO l3
 CASE 2:  s := "Cannot load %S (code %N)*N"
 GOTO l3
 CASE 3:  s := "Stack overflow"
 GOTO l1
 CASE 4:  s := "Operating system trap %X3"
 GOTO l1
 CASE 5:  s := "Buffer overflow: %P"
 GOTO l1
 CASE 6:  s := "conformality: %P,%P"
 GOTO l1
 CASE 7:  s := "DIVISION BY 0"
 GOTO l1
 CASE 8:  s := "Poly division not exact: %P,%P"
 GOTO l1
 CASE 9:  s := "I-O error: %S %S*N"
 GOTO l3
 CASE 10: s := "Only %N words"
 GOTO l1
 CASE 11: s := "Cannot bind %P,%P"
 GOTO l1
 CASE 12: s := "Cannot assign %P:=%P"
 GOTO l1
 CASE 13: s := "System error in %A"
 GOTO l2
 CASE 14: s := "Arith overflow"
 GOTO l1
 CASE 15: s := "New name: %P"
 GOTO l1
 CASE 16: s := "Bad arg for %A (%P)"
 GOTO l1
 CASE 17: s := "ap global %P unset"
 GOTO l1
 CASE 18: s := "Poly exponent overflow: %P"
 GOTO l1
 CASE 19: s := "Peculiar semantics (%P)"
 GOTO l1
 CASE 20: s := "Bad arg for %P (%P)"
 GOTO l1
 CASE 21: s := "Bad args for %P (%P,%P)"
 GOTO l1
 CASE 22: s := "Bad arith arg (%P)"
 GOTO l1
 CASE 23: s := "Bad arith args (%P,%P)"
 GOTO l1
 CASE 24: s := "Bad list arg (%P)"
 GOTO l1
 CASE 25: s := "Unset value"
 GOTO l1
 CASE 26: s := "%S not yet implemented"
 GOTO l1
 CASE 27: s := "Open-code global problem"
 GOTO l1
 CASE 28: s := "%P should be %P-tuple"
 GOTO l1
 CASE 29: s := "%P should be positive integer"
 GOTO l1
 CASE 30: s := "Stack broken (%N)"
 GOTO l2
 CASE 31: s := "Dump broken (%N)"
 GOTO l2
 CASE 32: s := "%A lost"
 GOTO l2
 CASE 33: s := "%S broken (%P)"
 GOTO l2
 CASE 34: s := "Trap in %A"
 GOTO l2
 CASE 35: s := "Re-decl global %P"
 GOTO l1
 CASE 36: s := "Ref unset global %P"
 GOTO l1
 CASE 37: s := "Bad arg for BCPL: %P"
 GOTO l1
 CASE 38: s := "Insufficient region"
 GOTO l1
 CASE 39: s := "Store jam"
 GOTO l2
 CASE 40: s := "Bad arg in code: %P, %P"
 GOTO l1
 CASE 41: s := "undecl global in code"
 GOTO l1
 }
 l1: writef (s, a, b, c, d)
 IF paramz
 { backtr (erlev>>2, level ()>>2)
 pmap (paramc) }
 longjump (erlev, erlab)
 l2: writef (s, a, b, c, d)
 TEST erz=z | ~paramd
 { backtrace ()
 pmap (paramc)
 mapstore () }
 ELSE eval (erz)
 stop (16)
 l3: writef (s, a, b, c, d)
 stop (12)
 }
 
 
AND softerror (c) BE
 msg1 (4, c)
 
 
AND msg2 (a) BE
 msg1 (33, "Tree", a)
 
 
AND msg3 (a) BE
 msg1 (36, a)
 
 
AND writeargp (a, f) BE
 { IF a<=0
 { prin (a)
 RETURN }
 { LET b = a & p_addr
 IF st1<=b<=st2
 { LET b0 = !b
 TEST 0<=b0<=typsz
 TEST f & okpal
 printa (b)
 ELSE writef ("(%N#%N# %P)", b, b0, b)
 ELSE TEST st1<=b0<=st2
 writes ("#s")
 ELSE writef ("?%X2:%N (%X2:%N)", a>>24, b, b0>>24, b0 & p_addr)
 RETURN }
 }
 writef ("?%N", a)
 }
 
 
AND errorp (p) BE
 writeargp (p, FALSE)
 
 
AND pmap (b) =VALOF
 { tempusp ("Pmap", 0)
 { LET ee, jj = e, j
 LET q1 = @b-3
 { LET q = 1!q1>>2
 IF q<=stackbase
 BREAK
 { LET qq = !q
 IF qq<0
 { writef ("*N%A   ", qq)
 IF !q1=abort
 q1 := q+nargs ((qq & p_addr)>>2)+3
 FOR t=q+3 TO q1-1
 { TEST b
 tab (10)
 ELSE { ztab (12)
 IF chc=0
 xtab (12) }
 writeargp (!t, b) }
 IF qq=eval
 { IF okpal
 { prine (ee)
 prind (q!4)
 prinj (jj) }
 ee, jj := q!6, q!7 }
 }
 }
 q1 := q
 } REPEAT
 }
 tempusp ("End pmap", 0)
 RESULTIS z
 }
 
 
AND pframe (p, q) = VALOF
 { LET t = writearg
 IF !p<0
 { wch ('p')
 t := writeargp }
 RESULTIS pframe (p, q, t) }
 
 
.
//./       ADD LIST=ALL,NAME=EVAL
 SECTION "EVAL"
 
 
GET "pal75hdr"
 
 
LET eval (c) = VALOF
 { LET f, p1, p2, p3 = z, -m, e, j
 j, m := zj, s_j
 IF @c>stackl
 stkover ()
 
 { {   // extend frame
 ll_ev:   cycles := cycles+1
 IF c<=0
 arg1 := c <> BREAK
 
 SWITCHON !c INTO
 {
 DEFAULT: arg1 := c
 BREAK
 
 CASE s_loc: c := h1!c
 LOOP
 
 CASE s_cd: GOTO h3!c
 
 CASE s_tra: dotrace (c, arg1)
 
 CASE s_mb: msg2 (c)
 CASE s_glz: msg3 (c)
 CASE s_glg:
 CASE s_glo:
 CASE s_qu: arg1 := h2!c
 BREAK
 
 CASE s_gensy:
 CASE s_name: { LET g = e
 { IF c=h3!g
 arg1 := h2!g <> ENDCASE
 g := h1!g } REPEATUNTIL g=z }
 msg1 (15, c)
 BREAK
 
 CASE s_unset:
 msg1 (25)
 CASE s_unset1:
 BREAK
 
 CASE s_e: arg1 := e
 BREAK
 
 CASE s_j: TEST f=z
 { IF m>=s_mz
 m := m-jgap
 j := keep2 (j) }
 ELSE j := keep1 (j, f)
 arg1 := j
 BREAK
 
 CASE s_clos:
 CASE s_aclos:
 CASE s_clos2:
 CASE s_eclos:
 CASE s_fclos:
 arg1 := get4 (!c, e, h2!c, h3!c)
 BREAK
 
 CASE s_rec: e := get4 (s_e, e, zsy, h2!c)
 CASE s_dash: f, m, c := get4 (m, f, h3!c, h2!c)+yfj, s_mmf2r, h1!c
 LOOP
 
 CASE s_reca: e := get4 (s_e, e, zsy, h2!c)
 arg1 := h1!c
 UNLESS arg1<=0
 arg1 := (fff!!arg1)(arg1)
 arg1 := (h3!c)(arg1, h2!c)
 BREAK
 
 CASE s_seq: f, m, c := get4 (m, f, h2!c, z)+yfj, s_mms, h1!c
 LOOP
 
 CASE s_seqa: arg1 := h1!c
 (fff!!arg1)(arg1)
 c := h2!c
 LOOP
 
 CASE s_apz: msg1 (17, h1!c)
 BREAK
 
 CASE s_apply:
 f, m, c := get4 (m, f, h2!c, zsy)+yfj, s_mmal, h1!c
 LOOP
 
 CASE s_apple:
 arg1 := h2!c
 UNLESS arg1<=0
 arg1 := (fff!!arg1)(arg1)
 c := h1!c
 UNLESS c<=0
 c := (fff!!c)(c)
 GOTO ll_ap
 
 CASE s_aa1: f, m, c := get4 (m, f, h3!c, z)+yfj, s_mma1, h2!c
 LOOP
 
 CASE s_a1a: arg1 := h2!c
 UNLESS arg1<=0
 arg1 := (fff!!arg1)(arg1)
 c := h3!c
 UNLESS f=z
 j, f, m := get4 (m, e, j, f)+yfj, z, s_mz
 la_a1:            e := get4 (s_e, h1!c, arg1, h2!c)
 c := h3!c
 LOOP
 
 CASE s_aa:
 CASE s_ap1: f, m, c := get4 (m, f, h3!c, z)+yfj, s_mmf1, h2!c
 LOOP
 
 CASE s_zz:
 CASE s_apv: f, m, c := get4 (m, f, h3!c, z)+yfj, s_mmf1a, h2!c
 LOOP
 
 CASE s_aa2: { LET c1 = h2!c
 f, m, c := get4 (m, f, h3!c, h2!c1)+yfj, s_mma2l, h2!(h1!c1) }
 LOOP
 
 CASE s_ap2: { LET c1 = h2!c
 f, m, c := get4 (m, f, h3!c, h2!c1)+yfj, s_mmf2l, h2!(h1!c1) }
 LOOP
 
 CASE s_a1e: arg1 := h2!c
 UNLESS arg1<=0
 arg1 := (fff!!arg1)(arg1)
 arg1 := (h3!c)(arg1)
 BREAK
 
 CASE s_ave: arg1 := h2!c
 UNLESS arg1<=0
 { arg1 := (fff!!arg1)(arg1)
 IF arg1>=yloc
 arg1 := h1!arg1 }
 arg1 := (h3!c)(arg1)
 BREAK
 
 CASE s_a2a: arg1 := h2!c
 { LET a2 = h2!(h1!arg1)
 UNLESS a2<=0
 a2 := (fff!!a2)(a2)
 arg1 := h2!arg1
 UNLESS arg1<=0
 arg1 := (fff!!arg1)(arg1)
 c := h3!c
 UNLESS f=z
 j, f, m := get4 (m, e, j, f)+yfj, z, s_mz
 { LET u = h2!c
 e := get4 (s_e, h1!c, a2, h2!u)
 e := get4 (s_e, e, arg1, h2!(h1!u)) }
 }
 c := h3!c
 LOOP
 
 CASE s_a2e: arg1 := h2!c
 { LET a2 = h2!(h1!arg1)
 UNLESS a2<=0
 a2 := (fff!!a2)(a2)
 arg1 := h2!arg1
 UNLESS arg1<=0
 arg1 := (fff!!arg1)(arg1)
 arg1 := (h3!c)(arg1, a2)
 BREAK }
 
 CASE s_aea: arg1 := ff_tuple (h2!c)
 UNLESS f=z
 j, f, m := get4 (m, e, j, f)+yfj, z, s_mz
 c := h3!c
 la_ae:            e := binda (h2!c, arg1, h1!c)
 c := h3!c
 LOOP
 
 CASE s_aaa: f, m, c := get4 (m, f, h3!c, z)+yfj, s_mmaa, h2!c
 CASE s_tuple:
 f, m, c := get4 (m, f, h1!c, z)+yfj, s_mmt, h2!c
 LOOP
 
 CASE s_apq: f, m, c := get4 (m, f, h2!(h1!c), h3!c)+yfj, s_mmaq, h2!c
 LOOP
 
 CASE s_aqe: arg1 := h2!c
 UNLESS arg1<=0
 arg1 := (fff!!arg1)(arg1)
 { LET t = h3!c
 c := h2!(h1!c)
 GOTO t }
 
 CASE s_retu: f, c := z, h2!c
 TEST j<yfj
 TEST j=zj
 m := s_j
 ELSE m := s_z
 ELSE m := s_mz
 LOOP
 
 CASE s_cond: f, m, c := get4 (m, f, h2!c, h3!c)+yfj, s_mmcond, h1!c
 LOOP
 
 CASE s_conda:
 CASE s_condb:
 { LET a = h1!c
 a := (fff!!a)(a)
 IF a=z | (a>=yloc & h1!a=z)
 c := h3!c <> LOOP
 c := h2!c
 LOOP }
 
 CASE s_let: f, m, c := get4 (m, f, h1!c, h2!c)+yfj, s_mmlet, h3!c
 LOOP
 
 CASE s_leta: arg1 := h3!c
 UNLESS arg1<=0
 arg1 := (fff!!arg1)(arg1)
 UNLESS f=z
 j, f, m := get4 (m, e, j, f)+yfj, z, s_mz
 e := bind (h2!c, arg1, e)
 c := h1!c
 LOOP
 
 CASE s_letb: arg1 := h3!c
 UNLESS arg1<=0
 arg1 := (fff!!arg1)(arg1)
 UNLESS f=z
 j, f, m := get4 (m, e, j, f)+yfj, z, s_mz
 e := get4 (s_e, e, arg1, h2!c)
 c := h1!c
 LOOP
 
 CASE s_colon:       // declare labels mutually recursively
 UNLESS f=z
 j, f, m := get4 (m, e, j, f)+yfj, z, s_z
 j := keep2 (j)
 { LET e1 = get4 (s_e, ze, zsy, z)
 { LET a = get4 (s_kclos, e1, j, h3!c)
 e := get4 (s_e, e, a, h1!c)
 c := h2!c } REPEATWHILE c>0 & !c=s_colon
 h1!e1, h2!e1, h3!e1 := h1!e, h2!e, h3!e }
 LOOP
 
 ll_ex:            c := gw2
 f, m := get4 (m, f, gw0, gw1)+yfj, s_mmf2r
 LOOP
 }
 BREAK
 } REPEAT
 
 {
 ll_zc:   SWITCHON m INTO
 {
 CASE s_j: m, e, j := -p1, p2, p3
 RESULTIS arg1
 
 CASE s_z: m := !j
 IF FALSE
 {
 CASE s_mz:     m := !j
 !j, stackp := stackp, j & p_addr }
 e, f, j := h1!j, h3!j, h2!j
 LOOP
 
 ll_rsc:  CASE s_mcc: m := !j
 IF FALSE
 {
 CASE s_mmcc:   m := !j
 !j, stackp := stackp, j & p_addr }
 e, c, j := h1!j, h3!j, h2!j
 GOTO h3!c
 
 ll_rsf:  CASE s_mcf: m := !j
 IF FALSE
 {
 CASE s_mmcf:   m := !j
 !j, stackp := stackp, j & p_addr }
 e, f, j := h1!j, h3!j, h2!j
 c := h3!f
 GOTO h3!c
 
 CASE s_mck: m := !j
 e, f, j := h1!j, h3!j, h2!j
 c := h3!f
 f := get4 (s_mmcf, h1!f, arg1, z)+yfj
 GOTO h3!c
 
 CASE s_mmck: m := !j
 !j, stackp := stackp, j & p_addr
 e, f, j := h1!j, h3!j, h2!j
 h2!f := arg1
 c := h3!f
 GOTO h3!c
 
 DEFAULT: msg1 (30, m)
 
 CASE s_mmal:
 CASE s_mal: h3!f := arg1
 c := h2!f
 m := m+1   // M := S_MMAR or S_MAR
 BREAK
 
 CASE s_mar: m := !f
 IF FALSE
 {
 CASE s_mmar:   m := !f
 !f, stackp := stackp, f & p_addr }
 c := h3!f
 f := h1!f
 ll_ap:            IF c<=0
 { arg1 := c
 LOOP }      // ??A??
 SWITCHON !c INTO
 {
 DEFAULT: arg1 := c
 LOOP      // ??A??
 
 CASE s_glz: msg3(c)
 CASE s_glg: CASE s_glo: CASE s_qu: arg1 := ap1(c,arg1)
 LOOP
 
 la_aploc:         CASE s_loc: c := h1!c
 GOTO ll_ap
 
 la_entx:          CASE s_cdx: UNLESS f=z
 j, f, m := get4 (m, e, j, f)+yfj, z, s_mz
 ll_entx:                   e := bind (h3!c, arg1, h2!c)
 c := h1!c
 GOTO h3!c
 
 la_enty:          CASE s_cdy: UNLESS f=z
 j, f, m := get4 (m, e, j, f)+yfj, z, s_mz
 ll_enty:                   e := h2!c
 c := h1!c
 GOTO h3!c
 
 la_entz:          CASE s_cdz: UNLESS f=z
 j, f, m := get4 (m, e, j, f)+yfj, z, s_mz
 ll_entz:                   e := get4 (s_e, ze, arg1, h2!c)
 c := h1!c
 GOTO h3!c
 
 CASE s_unset:
 msg1 (25)
 CASE s_unset1:
 LOOP
 
 CASE s_rds: q_selinput (h2!c-y0)
 arg1 := rea ()
 LOOP
 
 CASE s_wrs: q_seloutput (h2!c-y0)
 prch (arg1)
 LOOP
 
 CASE s_bcplf:
 arg1 := callbcpl (c)
 LOOP
 
 CASE s_bcplr:
 callbcpl (c)
 arg1 := z
 LOOP
 
 CASE s_bcplv:
 gw0 := callbcpl (c)
 arg1 := transpal (gw0)
 LOOP
 
 CASE s_codev:
 IF arg1>=yloc
 arg1 := h1!arg1
 CASE s_code0:
 CASE s_code1:
 arg1 := (h2!c)(arg1)
 LOOP
 
 la_apcode2:       CASE s_code2:
 UNTIL arg1>0 & !arg1=s_tuple & h3!arg1=y2
 { IF arg1>=yloc
 arg1 := h1!arg1 <> LOOP
 msg1 (28, arg1, y2) }
 arg1 := (h2!c)(h2!(h1!arg1), h2!arg1)
 LOOP
 
 CASE s_code3:
 arg1 := g_nt (arg1, y3)
 gw0 := h1!arg1
 arg1 := (h2!c)(h2!(h1!gw0), h2!gw0, h2!arg1)
 LOOP
 
 CASE s_code4:
 arg1 := g_nt (arg1, y0+4)
 gw0 := h1!arg1
 gw1 := h2!gw0
 gw0 := h1!gw0
 gw2 := h2!c       // ?BCPL
 arg1 := gw2 (h2!(h1!gw0), h2!gw0, gw1, h2!arg1)
 LOOP
 
 la_aptup:         CASE s_tuple:
 UNLESS arg1<0
 { IF arg1>=yloc
 arg1 := h1!arg1
 UNLESS arg1<0
 { IF arg1=0
 { arg1 := c
 LOOP }
 IF !arg1=s_tuple
 { LET t = mqu (h1!arg1)
 f, m := get4 (m, f, t, zsy)+yfj, s_mmal
 arg1 := h2!arg1
 GOTO la_aptup }
 msg1 (20, c, arg1) }
 }
 UNLESS y0<arg1<=h3!c
 arg1 := z <> LOOP
 FOR i=arg1+1 TO h3!c
 c := h1!c
 arg1 := h2!c
 LOOP
 
 CASE s_xtupl:
 UNLESS arg1<0
 { IF arg1>=yloc
 arg1 := h1!arg1
 UNLESS arg1<0
 msg1 (20, c, arg1) }
 IF arg1<=y0
 arg1 := z <> LOOP
 { LET c3 = h3!c
 IF arg1<=c3
 l:    { FOR i=arg1 TO c3
 c := h1!c
 arg1 := h2!c
 LOOP }
 { LET c2, a = h2!c, arg1
 { LET c31 = c3+1
 apply (c2, c31)
 TEST h3!c=c3
 { h1!c := get4 (s_tuple, h1!c, arg1, c31)
 h3!c := c31
 IF c31=a
 BREAK
 c3 := c31 }
 ELSE { c3 := h3!c
 IF c3>=a
 { arg1 := a
 GOTO l } }
 } REPEAT
 }
 }
 LOOP
 
 CASE s_poly: IF arg1>=yloc
 arg1 := h1!arg1
 IF arg1=z // ??P??
 { arg1 := evalpoly (c)
 LOOP }
 UNLESS arg1<0
 msg1 (29, arg1)
 gw1 := c
 c, gw1 := h1!c, gw1 NEQV c REPEATUNTIL c=z | arg1<=h3!c
 TEST c=z | arg1<h3!c
 arg1 := y0
 ELSE TEST gw1<ysg
 arg1 := h2!c
 ELSE arg1 := neg (h2!c)
 LOOP
 
 CASE s_j:
 CASE s_z:
 CASE s_mcc:
 CASE s_mcf:
 CASE s_mck:
 CASE s_mal:
 CASE s_mar:
 CASE s_ms:
 CASE s_mt:
 CASE s_maa:
 CASE s_ma1:
 CASE s_mf1:
 CASE s_mf1a:
 CASE s_ma2l:
 CASE s_ma2r:
 CASE s_mf2l:
 CASE s_mf2r:
 CASE s_maq:
 CASE s_mlet:
 CASE s_mcond:
 { LET c1 = h1!c  // ??J?? jval or stack ?
 UNLESS c1>0 & !c1=s_e
 msg1 (19, c) }
 arg1 := get4 (s_jclos, z, c, arg1)        // C & P_ADDR
 LOOP
 
 CASE s_e: UNLESS f=z
 j, f, m := get4 (m, e, j, f)+yfj, z, s_mz
 e, c := c, arg1
 BREAK
 
 CASE s_clos: UNLESS f=z
 j, f, m := get4 (m, e, j, f)+yfj, z, s_mz
 e, c := h1!c, h3!c
 BREAK
 
 CASE s_aclos:
 UNLESS f=z
 j, f, m := get4 (m, e, j, f)+yfj, z, s_mz
 e := get4 (s_e, h1!c, arg1, h2!c)
 c := h3!c
 BREAK
 
 la_apclos2:       CASE s_clos2:
 la_apeclos:       CASE s_eclos:
 UNLESS f=z
 j, f, m := get4 (m, e, j, f)+yfj, z, s_mz
 ll_apeclos:                { LET c2 = h2!c
 UNTIL arg1>0 & !arg1=s_tuple & h3!arg1=h3!c2
 { IF arg1>=yloc
 arg1 := h1!arg1 <> LOOP
 msg1 (6, c2, arg1) }
 e := binda (c2, arg1, h1!c) }
 c := h3!c
 BREAK
 
 la_apfclos:       CASE s_fclos:
 UNLESS f=z
 j, f, m := get4 (m, e, j, f)+yfj, z, s_mz
 ll_apfclos:                e := bind (h2!c, arg1, h1!c)
 c := h3!c
 BREAK
 
 CASE s_jclos:
 j := h2!c
 TEST j=zj
 m := s_j
 ELSE m := s_z
 c, f := h3!c, z
 GOTO ll_ap
 
 CASE s_kclos:
 e, j := h1!c, h2!c
 TEST j=zj
 m := s_j
 ELSE m := s_z
 c, f := h3!c, z
 BREAK
 }
 
 CASE s_ms: m := !f
 IF FALSE
 {
 CASE s_mms:    m := !f
 !f, stackp := stackp, f & p_addr }
 c := h2!f
 f := h1!f
 BREAK
 
 CASE s_mmt: { LET t = h3!f
 TEST t=z
 arg1 := get4 (s_tuple, z, arg1, y1)
 ELSE arg1 := get4 (s_tuple, t, arg1, h3!t+1) }
 c := h2!f
 IF c=z
 { m := !f
 !f, stackp := stackp, f & p_addr
 f := h1!f
 LOOP }
 h2!f, h3!f := h1!c, arg1
 m, c := s_mmt, h2!c
 BREAK
 
 CASE s_mt: { LET t = h3!f
 TEST t=z
 arg1 := get4 (s_tuple, z, arg1, y1)
 ELSE arg1 := get4 (s_tuple, t, arg1, h3!t+1) }
 c := h2!f
 IF c=z
 { m := !f
 f := h1!f
 LOOP }
 f := get4 (!f, h1!f, h1!c, arg1)+yfj
 m, c := s_mmt, h2!c
 BREAK
 
 CASE s_maa: m := !f
 IF FALSE
 {
 CASE s_mmaa:   m := !f
 !f, stackp := stackp, f & p_addr }
 c := h2!f
 f := h1!f
 UNLESS f=z
 j, f, m := get4 (m, e, j, f)+yfj, z, s_mz
 e := binda (h2!c, arg1, h1!c)
 c := h3!c
 BREAK
 
 CASE s_ma1: m := !f
 IF FALSE
 {
 CASE s_mma1:   m := !f
 !f, stackp := stackp, f & p_addr }
 c := h2!f
 f := h1!f
 UNLESS f=z
 j, f, m := get4 (m, e, j, f)+yfj, z, s_mz
 e := get4 (s_e, h1!c, arg1, h2!c)
 c := h3!c
 BREAK
 
 CASE s_mf1a: IF arg1>=yloc
 arg1 := h1!arg1
 CASE s_mf1: m := !f
 IF FALSE
 {
 CASE s_mmf1a:  IF arg1>=yloc
 arg1 := h1!arg1
 CASE s_mmf1:   m := !f
 !f, stackp := stackp, f & p_addr }
 c := h2!f
 f := h1!f
 arg1 := c (arg1)
 LOOP
 
 CASE s_mma2l:
 c := h3!f
 h3!f := arg1
 m := s_mma2r
 BREAK
 
 CASE s_ma2l: c := h3!f
 f := get4 (!f, h1!f, h2!f, arg1)+yfj
 m := s_mma2r
 BREAK
 
 CASE s_ma2r: m := !f
 IF FALSE
 {
 CASE s_mma2r:  m := !f
 !f, stackp := stackp, f & p_addr }
 c := h2!f
 { LET v = h3!f
 f := h1!f
 UNLESS f=z
 j, f, m := get4 (m, e, j, f)+yfj, z, s_mz
 { LET u = h2!c
 e := get4 (s_e, h1!c, v, h2!u)
 e := get4 (s_e, e, arg1, h2!(h1!u)) } }
 c := h3!c
 BREAK
 
 CASE s_mmf2l:
 c := h3!f
 h3!f := arg1
 m := s_mmf2r
 BREAK
 
 CASE s_mf2l: c := h3!f
 f := get4 (!f, h1!f, h2!f, arg1)+yfj
 m := s_mmf2r
 BREAK
 
 CASE s_mf2r: m := !f
 IF FALSE
 {
 CASE s_mmf2r:  m := !f
 !f, stackp := stackp, f & p_addr }
 c, gw0 := h2!f, h3!f
 f := h1!f
 arg1 := c (arg1, gw0)
 LOOP
 
 CASE s_maq: m := !f
 IF FALSE
 {
 CASE s_mmaq:   m := !f
 !f, stackp := stackp, f & p_addr }
 c := h2!f
 { LET t = h3!f
 f := h1!f
 GOTO t }
 
 CASE s_mlet: m := !f
 IF FALSE
 {
 CASE s_mmlet:  m := !f
 !f, stackp := stackp, f & p_addr }
 c := h2!f
 { LET v = h3!f
 f := h1!f
 UNLESS f=z
 j, f, m := get4 (m, e, j, f)+yfj, z, s_mz
 e := bind (v, arg1, e)
 BREAK }
 
 CASE s_mcond:
 m := !f
 IF FALSE
 {
 CASE s_mmcond: m := !f
 !f, stackp := stackp, f & p_addr }
 TEST arg1=z | (arg1>=yloc & h1!arg1=z)
 c := h3!f
 ELSE c := h2!f
 f := h1!f
 BREAK
 }} REPEAT
// }} REPEAT
 
 ls_er: msg1 (40, c, f)
 ///ls_glz:
 ll_glz:///
 msg1 (41)
 
 ///ls_cy:
 ll_cy: arg1 := h2!c
 c := h1!c
 GOTO h3!c
 //ls_cyf:
 ll_cyf:
 f := get4 (s_mmcf, f, h2!c, z)+yfj
 c := h1!c
 GOTO h3!c
 ///ls_na: arg1 := h1!(h1!e)
 ll_na: arg1 := h1!(h1!e)
 FOR i=4+y0 TO h2!c
 arg1 := h1!arg1
 arg1 := h2!arg1
 c := h1!c
 GOTO h3!c
 //ls_na1:
 ll_na1:
 arg1 := h2!e
 c := h1!c
 GOTO h3!c
 ///ls_na2:
 ll_na2:
 arg1 := h2!(h1!e)
 c := h1!c
 GOTO h3!c
 ///ls_naf:
 ll_naf:
 arg1 := h1!(h1!e)
 FOR i=4+y0 TO h2!c
 arg1 := h1!arg1
 f := get4 (s_mmcf, f, h2!arg1, z)+yfj
 c := h1!c
 GOTO h3!c
 ///ls_na1f:
 ll_na1f:
 f := get4 (s_mmcf, f, h2!e, z)+yfj
 c := h1!c
 GOTO h3!c
 ///ls_na2f:
 ll_na2f:
 f := get4 (s_mmcf, f, h2!(h1!e), z)+yfj
 c := h1!c
 GOTO h3!c
 
 ///ls_st: f := get4 (s_mmcf, f, arg1, z)+yfj
 ll_st: f := get4 (s_mmcf, f, arg1, z)+yfj
 c := h1!c
 GOTO h3!c
 ///ls_us: IF f>=yfj
 ll_us: IF f>=yfj
 !f, stackp := stackp, f & p_addr
 arg1 := h2!f
 f := h1!f
 c := h1!c
 GOTO h3!c
 
 ///ls_tup:
 ll_tup:
 gw0 := get4 (s_tuple, h2!f, arg1, h2!c)
 TEST f>=yfj
 h2!f := gw0
 ELSE f := get4 (s_mmcf, h1!f, gw0, z)+yfj
 c := h1!c
 GOTO h3!c
 ///ls_tupa:
 ll_tupa:
 gw0 := get4 (s_tuple, z, arg1, y1)
 f := get4 (s_mmcf, f, gw0, z)+yfj
 c := h1!c
 GOTO h3!c
 ///ls_tupz:
 ll_tupz:
 TEST f<yfj
 { arg1 := get4 (s_tuple, h2!f, arg1, h2!c)
 f := h1!f }
 ELSE { LET t = f & p_addr
 f := h1!f
 !t, h1!t, h2!t, h3!t := s_tuple, h2!t, arg1, h2!c   // ugh
 arg1 := t }
 c := h1!c
 GOTO h3!c
 ///ls_1tup:
 ll_1tup:
 arg1 := get4 (s_tuple, z, arg1, y1)
 c := h1!c
 GOTO h3!c
 
 ///ls_closl:
 ll_closl:
 arg1 := h2!c
 arg1 := get4 (!arg1, e, h2!arg1, h3!arg1)
 c := h1!c
 GOTO h3!c
 ///ls_closx:
 ll_closx:
 arg1 := h2!c
 arg1 := get4 (!arg1, h1!arg1, e, h3!arg1)
 c := h1!c
 GOTO h3!c
 
 ///ls_bind:
 ll_bind:
 e := bind (h2!c, arg1, e)
 c := h1!c
 GOTO h3!c
 ///ls_unbind:
 ll_unbind:
 FOR i=y1 TO h2!c
 e := h1!e
 c := h1!c
 GOTO h3!c
 
 //ls_lv: UNLESS arg1>=yloc
 ll_lv: UNLESS arg1>=yloc
 arg1 := get4 (s_loc, arg1, 0, 0)+yloc
 IF FALSE
 ///ls_rv: IF arg1>=yloc
 ll_rv: IF arg1>=yloc
 arg1 := h1!arg1
 ///ls_binde:
 ll_binde:
 e := get4 (s_e, e, arg1, h2!c)
 c := h1!c
 GOTO h3!c
 
 ///ls_bvf:
 ll_bvf:
 arg1 := h2!f
 h2!f := h1!arg1
 arg1 := h2!arg1
 c := h1!c
 GOTO h3!c
 ///ls_bvfe:
 ll_bvfe:
 arg1 := h2!f
 h2!f := h1!arg1
 e := get4 (s_e, e, h2!arg1, h2!c)
 c := h1!c
 GOTO h3!c
 ///ls_bvfa:
 ll_bvfa:
 f := get4 (s_mmcf, f, h1!arg1, z)+yfj
 ///ls_bvf1:
 ll_bvf1:
 arg1 := h2!arg1
 c := h1!c
 GOTO h3!c
 ///ls_bvfz:
 ll_bvfz:
 arg1 := h2!(h2!f)
 !f, stackp := stackp, f & p_addr
 f := h1!f
 c := h1!c
 GOTO h3!c
 ///ls_bve:
 ll_bve:
 e := get4 (s_e, e, h2!arg1, h2!c)
 arg1 := h1!arg1
 c := h1!c
 GOTO h3!c
 ///ls_bvez:
 ll_bvez:
 arg1 := h2!arg1
 e := get4 (s_e, e, arg1, h2!c)
 c := h1!c
 GOTO h3!c
 
 { LET v = 0
 ll_ent2:
 { LET t = h2!c
 c := h1!c   // CD (CD . BV1 BV2) E LL_ENT2
 e := get4 (s_e, t, v, h3!c) } }
 e := get4 (s_e, e, arg1, h2!c)
 c := h1!c
 GOTO h3!c
 
 //ls_apv:
 ll_apv:
 IF arg1>=yloc
 arg1 := h1!arg1
 ///ls_ap1:
 ll_ap1:
 arg1 := (h2!c)(arg1)
 c := h1!c
 GOTO h3!c
 ///ls_hdv:
 ll_hdv:
 IF arg1>=yloc
 arg1 := h1!arg1
 TEST arg1>0 & !arg1>=mm3
 arg1 := h2!arg1
 ELSE arg1 := z
 c := h1!c
 GOTO h3!c
 ///ls_miv:
 ll_miv:
 IF arg1>=yloc
 arg1 := h1!arg1
 TEST arg1>0 & !arg1>=mm3
 arg1 := h3!arg1
 ELSE arg1 := z
 c := h1!c
 GOTO h3!c
 //ls_tlv:
 ll_tlv:
 IF arg1>=yloc
 arg1 := h1!arg1
 TEST arg1>0
 arg1 := h1!arg1
 ELSE arg1 := z
 c := h1!c
 GOTO h3!c
 ///ls_null:
 ll_null:
 IF arg1>=yloc
 arg1 := h1!arg1
 arg1 := arg1=z
 c := h1!c
 GOTO h3!c
 ///ls_atom:
 ll_atom:
 IF arg1>=yloc
 arg1 := h1!arg1
 TEST arg1<=0
 arg1 := TRUE
 ELSE arg1 := !arg1<=s_glo
 c := h1!c
 GOTO h3!c
 
 ///ls_ap2s:
 ll_ap2s:
 arg1 := (h2!c)(h2!f, arg1)
 IF FALSE
 ///ls_ap2: arg1 := (h2!c)(arg1, h2!f)
 ll_ap2: arg1 := (h2!c)(arg1, h2!f)
 IF f>=yfj
 !f, stackp := stackp, f & p_addr
 f := h1!f
 c := h1!c
 GOTO h3!c
 ///ls_ap2sf:
 ll_ap2sf:
 gw0 := (h2!c)(h2!f, arg1)
 IF FALSE
 ///ls_ap2f: gw0 := (h2!c)(arg1, h2!f)
 ll_ap2f: gw0 := (h2!c)(arg1, h2!f)
 TEST f>=yfj
 h2!f := gw0
 ELSE f := get4 (s_mmcf, h1!f, gw0, z)+yfj
 c := h1!c
 GOTO h3!c
 
 ///ls_xcons:
 ll_xcons:
 { LET t = arg1
 arg1 := h2!f
 IF FALSE
 ll_cons: t := h2!f
 TEST arg1<=0
 { UNLESS arg1=z
 GOTO ls_er
 arg1 := get4 (s_tuple, z, t, y1) }
 ELSE { UNTIL !arg1=s_tuple
 { IF arg1>=yloc
 { arg1 := h1!arg1
 LOOP }
 GOTO ls_er }
 arg1 := get4 (s_tuple, arg1, t, h3!arg1+1) }
 }
 IF f>=yfj
 !f, stackp := stackp, f & p_addr
 f := h1!f
 c := h1!c
 GOTO h3!c
 ///ls_xconsf:
 ll_xconsf:
 { LET s, t = h2!f, arg1
 IF FALSE
 ll_consf: s, t := arg1, h2!f
 TEST s<=0
 { UNLESS s=z
 GOTO ls_er
 TEST f>=yfj
 h2!f := get4 (s_tuple, z, t, y1)
 ELSE { s := get4 (s_tuple, z, t, y1)
 f := get4 (s_mmcf, h1!f, s, z)+yfj } }
 ELSE { UNTIL !s=s_tuple
 { IF s>=yloc
 { s := h1!s
 LOOP }
 GOTO ls_er }
 TEST f>=yfj
 h2!f := get4 (s_tuple, s, t, h3!s+1)
 ELSE { s := get4 (s_tuple, s, t, h3!s+1)
 f := get4 (s_mmcf, h1!f, s, z)+yfj } }
 }
 c := h1!c
 GOTO h3!c
 
 ///ls_e: arg1 := e
 ll_e: arg1 := e
 c := h1!c
 GOTO h3!c
 ///ls_j: IF m>=s_mz
 ll_j: IF m>=s_mz
 m := m-jgap
 j := keep2 (j)
 arg1 := j
 c := h1!c
 GOTO h3!c
 
 ///ls_rec0:
 ll_rec0:
 e := get4 (s_e, e, zsy, h2!c)
 c := h1!c
 GOTO h3!c
 ///ls_rec1:
 ll_rec1:
 arg1 := (h2!c)(arg1, h3!e)
 c := h1!c
 GOTO h3!c
 ///ls_dash:
 ll_dash:
 arg1 := difr (arg1, h2!c)
 c := h1!c
 GOTO h3!c
 
 ll_cond:
 TEST arg1=z | (arg1>=yloc & h1!arg1=z)
 c := h1!c
 ELSE c := h2!c
 GOTO h3!c
 
 ll_apnf:
 IF f>=yfj
 ll_apnf1: !f, stackp := stackp, f & p_addr
 { LET t = h2!f
 f := h1!f
 TEST f<yfj
 f := get4 (s_mmcf, h1!f, h2!f, h1!c)+yfj
 ELSE h3!f := h1!c
 c := t }
 j, f, m := get4 (m, e, j, f)+yfj, z, s_mmcf
 GOTO ll_ap
 
 ll_apnk:
 TEST f<yfj
 { LET t = h2!f
 f := get4 (s_mmcf, h1!f, z, h1!c)+yfj
 c := t }
 ELSE { h3!f := h1!c
 c := h2!f }
 j, f, m := get4 (m, e, j, f)+yfj, z, s_mmck
 GOTO ll_ap
 
 ll_apnc:
 j, m := get4 (m, e, j, h1!c)+yfj, s_mmcc
 ll_apnj:
 c := h2!f
 IF f>=yfj
 !f, stackp := stackp, f & p_addr
 f := z
 GOTO ll_ap
 
 ll_apcf:     // Apply known code
 TEST f<yfj
 f := get4 (s_mmcf, h1!f, h2!f, h1!c)+yfj
 OR
 ll_apcf1: h3!f := h1!c
 j, f, m := get4 (m, e, j, f)+yfj, z, s_mmcf
 c := h2!c
 e := h2!c
 c := h1!c
 GOTO h3!c
 
 ll_apck:
 f := get4 (s_mmcf, f, z, h1!c)+yfj
 j, f, m := get4 (m, e, j, f)+yfj, z, s_mmck
 c := h2!c
 e := h2!c
 c := h1!c
 GOTO h3!c
 
 ll_apcc:
 j, m := get4 (m, e, j, h1!c)+yfj, s_mmcc
 c := h2!c
 e := h2!c
 c := h1!c
 GOTO h3!c
// No need for LL_APCJ
 
 ll_apbf:
 TEST f<yfj
 f := get4 (s_mmcf, h1!f, h2!f, h1!c)+yfj
 OR
 ll_apbf1: h3!f := h1!c
 j, f, m := get4 (m, e, j, f)+yfj, z, s_mmcf
 c := h2!c
 e := get4 (s_e, ze, arg1, h2!c)
 c := h1!c
 GOTO h3!c
 
 ll_apbk:
 f := get4 (s_mmcf, f, z, h1!c)+yfj
 j, f, m := get4 (m, e, j, f)+yfj, z, s_mmck
 c := h2!c
 e := get4 (s_e, ze, arg1, h2!c)
 c := h1!c
 GOTO h3!c
 
 ll_apbc:
 j, m := get4 (m, e, j, h1!c)+yfj, s_mmcc
 c := h2!c
 e := get4 (s_e, ze, arg1, h2!c)
 c := h1!c
 GOTO h3!c
 
 ll_apkf:     // Apply known tree
 c := h1!c
 TEST f<yfj
 f := get4 (s_mmcf, h1!f, h2!f, h1!c)+yfj
 OR
 ll_apkf1: h3!f := h1!c
 j, f, m := get4 (m, e, j, f)+yfj, z, s_mmcf
 { LET t = h3!c
 c := h2!c
 GOTO t }
 
 ll_apkk:
 c := h1!c
 f := get4 (s_mmcf, f, z, h1!c)+yfj
 j, f, m := get4 (m, e, j, f)+yfj, z, s_mmck
 { LET t = h3!c
 c := h2!c
 GOTO t }
 
 ll_apkc:
 c := h1!c
 j, m := get4 (m, e, j, h1!c)+yfj, s_mmcc
 { LET t = h3!c
 c := h2!c
 GOTO t }
 ll_apkj:
 c := h1!c
 { LET t = h3!c
 c := h2!c
 GOTO t }
 
 ll_svc:
 j, m := get4 (m, e, j, h2!c)+yfj, s_mmcc
 c := h1!c
 GOTO h3!c
 ll_svf:
 TEST f<yfj
 f := get4 (s_mmcf, h1!f, h2!f, h2!c)+yfj
 ELSE
 ll_svf1: h3!f := h2!c
 j, f, m := get4 (m, e, j, f)+yfj, z, s_mmcf
 c := h1!c
 GOTO h3!c
 
 }}
 
/*
///
LET fixbcpl1 () BE     // "Too many globals"
{ ///ll_glz := ls_glz
 ///ll_cy := ls_cy
 ///ll_cyf := ls_cyf
 ///ll_na := ls_na
 ///ll_na1 := ls_na1
 ///ll_na2 := ls_na2
 ///ll_naf := ls_naf
 ///ll_na1f := ls_na1f
 ///ll_na2f := ls_na2f
 ///ll_st := ls_st
 ///ll_us := ls_us
 ///ll_tup := ls_tup
 ///ll_tupa := ls_tupa
 ///ll_tupz := ls_tupz
 ///ll_1tup := ls_1tup
 ///ll_closl := ls_closl
 ///ll_closx := ls_closx
 ///ll_lv := ls_lv
 ///ll_rv := ls_rv
 //ll_bvf := ls_bvf
 ///ll_bvfe := ls_bvfe
 ///ll_bvfa := ls_bvfa
 ///ll_bvf1 := ls_bvf1
 ///ll_bvfz := ls_bvfz
 ///ll_bve := ls_bve
 ///ll_bvez := ls_bvez
 ///ll_bind := ls_bind
 ///ll_binde := ls_binde
 ///ll_unbind := ls_unbind
 ///ll_apv := ls_apv
 ///ll_ap1 := ls_ap1
 ///ll_hdv := ls_hdv
 ///ll_miv := ls_miv
 ///ll_tlv := ls_tlv
 ///ll_null := ls_null
 ///ll_atom := ls_atom
 ///ll_ap2s := ls_ap2s
 ///ll_ap2 := ls_ap2
 ///ll_ap2sf := ls_ap2sf
 ///ll_ap2f := ls_ap2f
 ///ll_xcons := ls_xcons
 ///ll_xconsf := ls_xconsf
 ///ll_e := ls_e
 ///ll_j := ls_j
 ///ll_rec0 := ls_rec0
 ///ll_rec1 := ls_rec1
 ///ll_dash := ls_dash
 }
///
*/
 
.
//./       ADD LIST=ALL,NAME=EVALA
 SECTION "EVALA"
 
 
GET "pal75hdr"
 
 
LET evsy (a) = VALOF
 { IF paramy
 RESULTIS FALSE
 { IF a<=0
 RESULTIS TRUE
 IF fff!!a=msg2
 RESULTIS FALSE
 SWITCHON !a INTO
 {
 DEFAULT: RESULTIS TRUE
 CASE s_tuple:
 { UNLESS evsy (h2!a)
 RESULTIS FALSE
 a := h1!a } REPEATUNTIL a=z
 RESULTIS TRUE
 CASE s_aa:
 CASE s_zz: a := h2!a
 LOOP
 CASE s_dash: a := h1!a
 LOOP
 }
 } REPEAT
 }
 
 
// CONSTRUCTION OF E-TREES PREVENTS THEIR BEING RE-ENTRANT
// SO WE CAN MISS STACK-CHECKING
 
 
AND ff_clos (a) = get4 (!a, e, h2!a, h3!a)
 
 
AND ff_reca (a) = VALOF
 { e := get4 (s_e, e, zsy, h2!a)
 { LET b = h1!a
 UNLESS b<=0
 b := (fff!!b)(b)
 RESULTIS (h3!a)(b, h2!a) } }
 
 
AND ff_dash (a) = VALOF
 { LET b = h1!a
 UNLESS b<=0
 b := (fff!!b)(b)
 RESULTIS difr (b, h2!a) }
 
 
AND ff_e () = e
 
 
AND ff_a1e (a) = VALOF
 { LET b = h2!a
 UNLESS b<=0
 b := (fff!!b)(b)
 RESULTIS (h3!a)(b) }
 
 
AND ff_ave (a) = VALOF
 { LET b = h2!a
 UNLESS b<=0
 b := (fff!!b)(b)
 IF b>=yloc
 b := h1!b
 RESULTIS (h3!a)(b) }
 
 
AND ff_a2e (a) = VALOF
 { LET b1 = h2!a
 LET b2 = h2!(h1!b1)
 UNLESS b2<=0
 b2 := (fff!!b2)(b2)
 b1 := h2!b1
 UNLESS b1<=0
 b1 := (fff!!b1)(b1)
 RESULTIS (h3!a)(b1, b2) }
 
 
AND ff_tuple (a) = VALOF
 { LET p, l = z, y0
 { LET b = h2!a
 UNLESS b<=0
 b := (fff!!b)(b)
 l := l+1
 p := get4 (s_tuple, p, b, l)
 a := h1!a } REPEATUNTIL a=z
 RESULTIS p }
 
 
AND ff_condb (a) = VALOF
 { { LET a1 = h1!a
 a1 := (fff!!a1)(a1)
 TEST a1=z | (a1>=yloc & h1!a1=z)
 a := h3!a
 ELSE a := h2!a }
 UNLESS a<=0
 a := (fff!!a)(a)
 RESULTIS a }
 
 
AND ff_seqa (a) = VALOF
 { { LET a1 = h1!a
 (fff!!a1)(a1) }
 a := h2!a
 UNLESS a<=0
 a := (fff!!a)(a)
 RESULTIS a }
 
 
AND ff_argt (v, a, e) = VALOF
 { { e := get4 (s_e, e, zsy, h2!v)
 v := h1!v } REPEATUNTIL v=z
 v := e
 { LET a2 = h2!a
 IF a2>0
 a2 := (fff!!a2)(a2)
 h2!v := a2
 a := h1!a
 IF a=z
 RESULTIS e
 v := h1!v } REPEAT
 }
 
 
.
//./       ADD LIST=ALL,NAME=FLATTEN
 SECTION "FLATTEN"
 
 
GET "pal75hdr"
 
 
MANIFEST
 { fvaru = signbit>>1 }
 
 
STATIC
 { ll = 0 }
 
 
LET msgf (n, a, b, c, d) BE
 { LET s, f, w = zero, dummy, wrc
 writes ("*N*N# ")
 SWITCHON n INTO
 {
 DEFAULT: a := n
 s := "Unknown error %N in flatten"
 ENDCASE
 CASE 0:  s := "Error %N in flatten"
 f := backtrace
 ENDCASE
 CASE 1:  s := "Bad arg for flatten: %P"
 ENDCASE
 CASE 2:  s := "Cannot find %P"
 ENDCASE
 CASE 3:  s := "Undecl %P"
 f, n := prine, b
 ENDCASE
 CASE 4:  s := "Cannot flatten %P"
 ENDCASE
 CASE 5:  s := "Flatten cannot yet cope with %P"
 ENDCASE
 CASE 6:  s := "Bad bv part %P"
 ENDCASE
 CASE 7:  s := "Undef global %P"
 ENDCASE
 }
 writef (s, a, b, c, d)
 f (n)
 wrc := w
 longjump (flevel (flatten), l_flatten)
 }
 
 
AND revf (c, d) = VALOF
 { UNTIL c=zsy
 { LET t = h1!c
 h1!c := d
 d, c := c, t }
 RESULTIS d }
 
 
AND flatten (a) = VALOF
 { IF a>0
 SWITCHON !a INTO
 {
 CASE s_loc: a := h1!a
 LOOP
 CASE s_gensy:
 CASE s_name: { LET g = e
 { IF h3!g=a
 { LET t = flatten (h2!g)
 h2!g := t
 RESULTIS t }
 g := h1!g } REPEATUNTIL g=z }
 msgf (2, a)
 CASE s_glg:
 CASE s_glo: { LET a2 = flatten (h2!a)
 fixapf (a2, h3!a)
 h3!a := h2!a
 h2!a := a2
 RESULTIS a }
 CASE s_tuple:
 lmap (flatten, a)
 RESULTIS z
 CASE s_clos:
 CASE s_aclos:
 CASE s_clos2:
 CASE s_eclos:
 CASE s_fclos:
 { LET a1, a2 = h1!a, h2!a
 LET e = simenv (a1, a2)
 LET c = flat0 (h3!a, e)
 LET f = result2<fvaru
 h3!a := c
 TEST fbv (a2)
 TEST f & simname (a2)
 { ll := s_cdz
 a1, a2 := a2, ll_entz
 c := loadn (c, y1, 0) }
 ELSE { c := flatbv (c, a2)
 ll := s_cdy }
 ELSE ll := s_cdx
 RESULTIS get4 (ll, c, a1, a2)
 }
 }
 msgf (1, a)
 l_flatten:
 RESULTIS z
 } REPEAT
 
 
AND efsy (a, n) = VALOF
 { IF n>0    // dont get too embroiled
 RESULTIS y0
 IF a>0
 SWITCHON !a INTO
 {
 DEFAULT: RESULTIS y0
 CASE s_string:
 CASE s_flt:
 CASE s_fpl:
 CASE s_numj:
 CASE s_ratn:
 CASE s_ratl:
 CASE s_ratp:
 CASE s_poly:
 CASE s_gensy:
 CASE s_name:
 CASE s_glz:
 CASE s_glg:
 CASE s_glo:
 CASE s_qu: ENDCASE
 CASE s_loc: a := h1!a
 LOOP
 CASE s_tuple:
 CASE s_ap2:
 CASE s_a2e: RESULTIS y2
 CASE s_apply:
 CASE s_apple:
 CASE s_aa1:
 CASE s_a1a:
 CASE s_aa2:
 CASE s_a2a:
 CASE s_aaa:
 CASE s_aea:
 CASE s_apq:
 CASE s_aqe: RESULTIS y2
 CASE s_cond:
 CASE s_conda:
 CASE s_condb:
 { LET t = efsy (h2!a, n+1)
 a := efsy (h3!a, n+1)
 TEST a>t
 RESULTIS t
 ELSE RESULTIS a }
 CASE s_seq:
 CASE s_seqa: a, n := h2!a, n+1
 LOOP
 }
 RESULTIS y1
 } REPEAT
 
 
// GSEQF chains COND-nodes, to reduce repetition;
// its top byte indicates global properties of the function: eg FVARU
 
 
AND flat0 (a, e) = VALOF
 { LET g, sv = zsy, gseqf | signbit
 gseqf := @g
 { LET c = flat1 (a, zc, e, z, FALSE)
 UNTIL g=zsy
 { LET t, n = h1!g, h2!g
 WHILE !n=s_mb    // the same COND-node with diff targets
 n := h2!n
 !g, h1!g, h2!g, h3!g := !n, h1!n, h2!n, h3!n
 g := t }
 result2 := gseqf & maxint
 gseqf := sv
 RESULTIS c
 }
 }
 
 
AND flat1 (a, c, e, f, cstac) = VALOF
 { IF @a>stackl
 stkover ()
 { IF c=zc & (f~=z | cstac)
 msgf (0, 1)
 TEST a>0
 SWITCHON !a INTO
 {
 DEFAULT: msgf (4, a)
 
 CASE s_glg:
 CASE s_glo:
 CASE s_qu: a := h2!a
 CASE s_string:
 CASE s_flt:
 CASE s_fpl:
 CASE s_numj:
 CASE s_ratn:
 CASE s_ratl:
 CASE s_ratp:
 CASE s_poly: TEST cstac
 ll := ll_cyf
 ELSE ll := ll_cy
 ENDCASE
 CASE s_loc: a := h1!a
 LOOP
 CASE s_cd: TEST c=zc
 RESULTIS a
 ELSE TEST cstac
 ll := ll_apck
 ELSE TEST f=z
 ll := ll_apcc
 ELSE ll := ll_apcf
 ENDCASE
 CASE s_glz: TEST cstac
 ll := ll_cyf
 ELSE ll := ll_cy
 c := get4 (s_cd, c, zsy, ll)
 c := get4 (s_cd, c, h3!a, ll_glz)
 h3!a := c
 RESULTIS c
 CASE s_gensy:
 CASE s_name: { LET n, g = y1, e
 { IF h3!g=a
 { IF !g=s_e
 gseqf := gseqf | fvaru
 TEST n=y1
 TEST cstac
 ll := ll_na1f
 ELSE ll := ll_na1
 ELSE TEST n=y2
 TEST cstac
 ll := ll_na2f
 ELSE ll := ll_na2
 ELSE { a := n
 TEST cstac
 ll := ll_naf
 ELSE ll := ll_na }
 UNLESS cstac
 c := loadn (c, n, 0)
 ENDCASE
 }
 n, g := n+1, h1!g
 } REPEATUNTIL g=z
 msgf (3, a, e)
 }
 CASE s_tuple:
 { LET t = rev (a)
 LET n, l = h3!a, ll_tup
 TEST n=y1
 { TEST cstac
 l := ll_tupa
 ELSE l := ll_1tup
}
 ELSE { UNLESS cstac
 l := ll_tupz
 { LET f0 = get4 (s_mb, f, zsy, z)
 { c := get4 (s_cd, c, n, l)
 c := flat1 (h2!t, c, e, f0, FALSE)
 n, l, t := n-1, ll_tup, h1!t } REPEATUNTIL h1!t=z }
 l := ll_tupa }
  c := get4 (s_cd, c, n, l)
 a, cstac := h2!t, FALSE
 LOOP
 }
 CASE s_clos:
 CASE s_aclos:
 CASE s_clos2:
 CASE s_eclos:
 CASE s_fclos:
 IF cstac
 c := get4 (s_cd, c, z, ll_st)
 a := flatten (a)
 ll := ll_closx
 ENDCASE
 CASE s_rec:
 CASE s_reca: IF cstac
 c := get4 (s_cd, c, z, ll_st)
 c := get4 (s_cd, c, h3!a, ll_rec1)
 e := simenv (e, h2!a)
 c := flat1 (h1!a, c, e, f, FALSE)
 ll := ll_rec0
 a := h2!a
 ENDCASE
 CASE s_dash: IF cstac
 c := get4 (s_cd, c, z, ll_st)
 c := get4 (s_cd, c, h2!a, ll_dash)
 a, cstac := h1!a, FALSE
 LOOP
 CASE s_let:
 CASE s_leta:
 CASE s_letb: IF cstac
 c := get4 (s_cd, c, z, ll_st)
 c := get4 (s_cd, c, z, ll_rsc)     // ?L OK in seq
 { LET g = simenv (e, h2!a)
 c := flat1 (h1!a, c, g, f, FALSE) }
 TEST fbv (h2!a) & matchbv (h2!a, h3!a, FALSE)
 c := flatbv (c, h2!a)
 ELSE c := get4 (s_cd, c, h2!a, ll_bind)
 c := get4 (s_cd, c, z, ll_svc)
 a, cstac := h3!a, FALSE
 LOOP
 CASE s_apply:
 CASE s_apple:
 CASE s_aa1:
 CASE s_a1a:
 CASE s_aa2:
 CASE s_a2a:
 CASE s_aaa:
 CASE s_aea:
 CASE s_apq:
 CASE s_aqe: { LET a1 = h1!a        // A1 is MB ?F
 IF tyv (a1)=a_qu
 { LET l, v = ll_ap, h2!a1
 IF v<=0
 { a := v
 LOOP }
 SWITCHON !v INTO
 {
 CASE s_unset:
 msgf (7, a1)
 CASE s_cdz: TEST c=zc
 c, v, ll := h1!v, h2!v, ll_entz
 ELSE TEST cstac
 ll := ll_apbk
 ELSE TEST f=z
 ll := ll_apbc
 ELSE ll := ll_apbf
 c := get4 (s_cd, c, v, ll)
 a, cstac := h2!a, FALSE
 LOOP
 CASE s_cdy: IF matchbv (h3!v, h2!a, FALSE)
 { TEST c=zc
 c, v, ll := h1!v, h2!v, ll_enty
 ELSE TEST cstac
 ll := ll_apck
 ELSE TEST f=z
 ll := ll_apcc
 ELSE ll := ll_apcf
 c := get4 (s_cd, c, v, ll)
 a, cstac := h2!a, FALSE
 LOOP
 }
 msgf (0, 4)
 CASE s_cdx: l := ll_entx
 ENDCASE
 CASE s_aclos:
 l := la_a1
 ENDCASE
 CASE s_code2:
 l := la_apcode2
 ENDCASE
 CASE s_clos2:
 CASE s_eclos:
 TEST matchbv (h2!v, h2!a, FALSE)
 l := la_ae
 ELSE l := ll_apeclos
 ENDCASE
 CASE s_fclos:
 l := ll_apfclos
 ENDCASE
 CASE s_loc: l := la_aploc
 ENDCASE
 CASE s_tuple:
 l := la_aptup
 ENDCASE
 }
 TEST c=zc
 ll := ll_apkj
 ELSE TEST cstac
 ll := ll_apkk
 ELSE TEST f=z
 ll := ll_apkc
 ELSE ll := ll_apkf
 c := get4 (s_cd, c, v, l)
 c := get4 (s_cd, c, h3!a1, ll)
 h3!a1 := c
 a, cstac := h2!a, FALSE
 LOOP
 }
 TEST c=zc
 ll := ll_apnj
 ELSE TEST cstac
 ll := ll_apnk
 ELSE TEST f=z
 ll := ll_apnc
 ELSE ll := ll_apnf
 c := get4 (s_cd, c, z, ll)
 { LET f0 = get4 (s_mb, f, zsy, z)
 c := flat1 (h2!a, c, e, f0, FALSE) }
 a, cstac := a1, TRUE
 LOOP
 }
 CASE s_ap1:
 CASE s_a1e: IF cstac
 c := get4 (s_cd, c, z, ll_st)
 c := get4 (s_cd, c, h3!a, ll_ap1)
 a, cstac := h2!a, FALSE
 LOOP
 CASE s_apv:
 CASE s_ave: IF cstac
 c := get4 (s_cd, c, z, ll_st)
 { LET a3 = h3!a
 TEST a3=hdv
 ll := ll_hdv
 ELSE TEST a3=tlv
 ll := ll_tlv
 ELSE TEST a3=miv
 ll := ll_miv
 ELSE TEST a3=atom
 ll := ll_atom
 ELSE TEST a3=null
 ll := ll_null
 ELSE ll := ll_apv
 c := get4 (s_cd, c, a3, ll)
 a, cstac := h2!a, FALSE
 LOOP
 }
 CASE s_ap2:
 CASE s_a2e: { LET swap, a3 = FALSE, h3!a
 LET arg1 = h2!a
 LET arg2 = h2!(h1!arg1)
 arg1 := h2!arg1
 IF efsy (arg1, -3)>efsy (arg2, -3)
 { LET t = arg1
 arg1, arg2 := arg2, t
 swap := TRUE }
 TEST a3=aug
 { a3 := z
 TEST cstac
 TEST swap
 ll := ll_xconsf
 ELSE ll := ll_consf
 ELSE TEST swap
 ll := ll_xcons
 ELSE ll := ll_cons }
 ELSE TEST cstac
 TEST swap
 ll := ll_ap2sf
 ELSE ll := ll_ap2f
 ELSE TEST swap
 ll := ll_ap2s
 ELSE ll := ll_ap2
 c := get4 (s_cd, c, a3, ll)
 { LET f0 = get4 (s_mb, f, zsy, z)
 c := flat1 (arg1, c, e, f0, FALSE) }
 a, cstac := arg2, TRUE
 LOOP
 }
 CASE s_e: ll := ll_e
 IF FALSE
 CASE s_j:   ll := ll_j
 IF cstac
 c := get4 (s_cd, c, z, ll_st)
 a := z
 ENDCASE
 CASE s_cond:
 CASE s_conda:
 CASE s_condb:
 { LET n = get4 (!a, h1!a, h2!a, h3!a)
 LET c0 = get4 (s_cd, zsy, zsy, ll_cond)
 !a, h1!a, h2!a, h3!a := s_mb, !gseqf, n, get4 (s_mb, c0, c, f)
 !gseqf := a
 h2!c0 := flat1 (h2!n, c, e, f, cstac)
 h1!c0 := flat1 (h3!n, c, e, f, cstac)
 a, c, cstac := h1!n, c0, FALSE
 LOOP }
 CASE s_seq:
 CASE s_seqa: c := flat1 (h2!a, c, e, f, cstac)
 a, cstac := h1!a, FALSE
 LOOP
 CASE s_mb: { LET a3 = h3!a
 a := h2!a
 IF h2!a3=c
 { UNLESS h3!a3=f
 msgf (0, 2)
 c, a, cstac := h1!a3, h1!a, FALSE }
 LOOP }
 }
 ELSE TEST cstac
 ll := ll_cyf
 ELSE ll := ll_cy
 RESULTIS get4 (s_cd, c, a, ll)
 } REPEAT
 }
 
 
AND loadn (c, n, m) = VALOF
 { IF c=z | m<-3
 RESULTIS c
 IF n=y1 & h3!c=ll_na1 | n=y2 & h3!c=ll_na2 | n=h2!c & h3!c=ll_na
 RESULTIS loadn (h1!c, n, m)
 IF n=y1 & h3!c=ll_na1f | n=y2 & h3!c=ll_na2f | n=h2!c & h3!c=ll_naf
 { c := loadn (h1!c, n, m)
 RESULTIS get4 (s_cd, c, z, ll_st) }
 IF (h3!c & sva)=0
 RESULTIS c
 IF h3!c=ll_cond
 { LET t1 = loadn (h1!c, n, m)
 LET t2 = loadn (h2!c, n, m)
 IF t1=h1!c & t2=h2!c
 RESULTIS c
 RESULTIS get4 (s_cd, t1, t2, ll_cond) }
 { LET t1 = loadn (h1!c, n, m-1)
 IF t1=h1!c
 RESULTIS c
 RESULTIS get4 (s_cd, t1, h2!c, h3!c) }
 }
 
 
AND fbv (b) = VALOF
 { IF b>0
 SWITCHON !b INTO
 {
 CASE s_loc: b := h1!b
 LOOP
 CASE s_tuple:
 { UNLESS fbv (h2!b)
 RESULTIS FALSE
 b := h1!b } REPEATUNTIL b=z
 RESULTIS TRUE
 CASE s_qu: RESULTIS FALSE }
 RESULTIS TRUE
 } REPEAT
 
 
AND flatbv (c, b) = VALOF
 { IF @b>stackl
 stkover ()
 { IF b>0
 SWITCHON !b INTO
 {
 CASE s_loc: b := h1!b
 LOOP
 CASE s_tuple:
 b := rev (b)
 IF simtup (b)
 { c := loadn (c, y1, 0)
 ll := ll_bvez
 l1:                       { c := get4 (s_cd, c, h2!b, ll)
 ll := ll_bve
 b := h1!b } REPEATUNTIL b=z
 RESULTIS c }
 c := flatbv (c, h2!b)
 b := h1!b
 IF b=z | simtup (b)
 { c := get4 (s_cd, c, z, ll_bvf1)
 UNLESS b=z
 { ll := ll_bve
 GOTO l1 }
 RESULTIS c }
 c := get4 (s_cd, c, z, ll_bvfz)
 UNTIL h1!b=z
 { LET b2 = h2!b
 TEST simname (b2)
 c := get4 (s_cd, c, b2, ll_bvfe)
 ELSE { c := flatbv (c, b2)
 c := get4 (s_cd, c, z, ll_bvf) }
 b := h1!b }
 c := flatbv (c, h2!b)
 RESULTIS get4 (s_cd, c, z, ll_bvfa)
 CASE s_aa: ll := ll_lv
 GOTO l0
 CASE s_zz: ll := ll_rv
 l0:                 c := loadn (c, y1, 0)
 RESULTIS get4 (s_cd, c, h2!b, ll)
 CASE s_gensy:
 CASE s_name:
 CASE s_dash: c := loadn (c, y1, 0)
 RESULTIS get4 (s_cd, c, b, ll_binde)
 }
 UNLESS b=z
 msgf (6, b)
 RESULTIS c
 } REPEAT
 }
 
 
AND simenv (e, v) = VALOF
 { IF v>0
 SWITCHON !v INTO
 {
 CASE s_loc: v := h1!v
 LOOP
 CASE s_tuple:
 { e := simenv (e, h2!v)
 v := h1!v } REPEATUNTIL v=z
 RESULTIS e
 CASE s_qu:
 CASE s_aa:
 CASE s_zz: v := h2!v
 LOOP
 CASE s_gensy:
 CASE s_name:
 CASE s_dash: RESULTIS get4 (s_mb, e, zsy, v)
 }
 UNLESS v=z
 msgf (6, v)
 RESULTIS e
 } REPEAT
 
 
AND fixapf (v, l) BE
 UNTIL l=z
 { LET l2, l3 = h2!l, h3!l
 TEST l3=ll_glz
 { LET l1 = h1!l
 h1!l, h2!l, h3!l := h1!l1, v, h3!l1 }
 ELSE TEST !v=s_cdz
 { TEST l3=ll_apkj
 { h1!l, h2!l, h3!l := h1!v, h2!v, ll_entz
 l := l2
 LOOP }
 ELSE TEST l3=ll_apkk
 ll := ll_apbk
 ELSE TEST l3=ll_apkc
 ll := ll_apbc
 ELSE TEST l3=ll_apkf
 ll := ll_apbf
 ELSE msgf (0, 3)
 h1!l, h2!l, h3!l := h1!(h1!l), v, ll
 }
 ELSE { TEST l3=ll_apkj
 { h1!l, h2!l, h3!l := h1!v, h2!v, ll_enty
 l := l2
 LOOP }
 ELSE TEST l3=ll_apkk
 ll := ll_apck
 ELSE TEST l3=ll_apkc
 ll := ll_apcc
 ELSE TEST l3=ll_apkf
 ll := ll_apcf
 ELSE msgf (0, 3)
 h1!l, h2!l, h3!l := h1!(h1!l), v, ll
 }
 l := l2
 }
 
 
.
//./       ADD LIST=ALL,NAME=J
 SECTION "J"
 
 
GET "pal75hdr"
 
 
LET keep1 (k, f) = VALOF        // F~=Z
 { LET t = h1!f
 IF t<yfj
 { IF t=z
 { t := !f
 IF t>=s_mz
 !f := t-jgap }
 RESULTIS keep2 (k) }
 f := t } REPEAT
 
 
AND keep2 (k) = VALOF   // K=J
 { UNTIL k<yfj
 { TEST !k>=s_mz
 !k := !k-jgap
 ELSE BREAK
 h3!k := keep3 (h3!k)
 { LET k2 = h2!k
 IF k2=z
 BREAK
 h2!k := k2 & p_addr
 k := k2 } }
 RESULTIS j & p_addr
 }
 
 
AND keep3 (f) = VALOF   // F~=Z
 { LET g = f
 WHILE !g>=s_mz    // not CD
 { !g := !g-jgap
 { LET g1 = h1!g
 IF g1<yfj
 BREAK
 h1!g := g1 & p_addr
 g := g1 } }
 RESULTIS f & p_addr }
 
 
AND apply (c1, c2) = VALOF
 { arg1, c2 := c2, z
 { LET p1, p2, p3 = -m, e, j
 j, m := zj, s_j
 IF @c1>stackl
 stkover ()
 (-3)!(@c1) := eval
 iv ()
 GOTO ll_ap } }
 
 
AND erroreval (s) = VALOF
 { LET l1, l2 = -erlev, -erlab
 LET q1, q2 = -q_input, -q_output
 LET p1, p2, p3 = -m, e, j
 erlev, erlab := level (), l
 s := eval (s)
 erlev, erlab := -l1, -l2
 RESULTIS s
 l: erlev, erlab := -l1, -l2
 m, e, j := -p1, p2, p3
 q_selinput (-q1)
 q_seloutput (-q2)
 UNLESS okpal
 msg1 (1)
 writef ("*N# Erroreval failed on: %E*N", printa, s)
 RESULTIS z
 }
 
 
.
//./       ADD LIST=ALL,NAME=LONGA
 SECTION "LONGA"
 
 
GET "pal75hdr"
 
 
MANIFEST
 { numbb = numba-1 }
 
 
STATIC
 { sg = 0
 cy = 0
 gl1 = 0
 gl2 = 0
 gl3 = 0 }
 
// Some of these routines may not be happy about long integers that
// are actually only one word long
 
 
LET longcmp (a, b) = VALOF      // A>B -> 1  ...
 { LET f = 0
 { TEST h3!a>h3!b
 f := 1
 ELSE UNLESS h3!a=h3!b
 f := -1
 TEST h2!a>h2!b
 f := 1
 ELSE UNLESS h2!a=h2!b
 f := -1
 a, b := h1!a, h1!b
 IF a=b
 RESULTIS f
 IF a=z
 RESULTIS -1
 IF b=z
 RESULTIS 1
 } REPEAT
 }
 
 
AND sadd (n) = VALOF
 { IF ABS n<numba
 RESULTIS n+y0
 TEST n<0
 n, sg := -n, ysg
 ELSE sg := 0
 RESULTIS getx (s_numj, z, 1, n-numba)+sg }
 
 
AND longadd (a, b) = VALOF
 { LET c, c0 = z, @b | signbit       // ??B?? C0=@C-1
 sg, cy := a & ysg, 0
 { gw1 := h3!a+h3!b+cy
 TEST gw1>=numba
 { gw1 := gw1-numba
 cy := 1 }
 ELSE cy := 0
 gw2 := h2!a+h2!b+cy
 TEST gw2>=numba
 { gw2 := gw2-numba
 cy := 1 }
 ELSE cy := 0
 a, b := h1!a, h1!b
 h1!c0 := getx (s_numj, zsy, gw2, gw1)
 c0 := h1!c0
 IF a=z
 { h1!c0 := b
 IF cy=0
 RESULTIS c+sg
 a := b
 GOTO l }
 } REPEATUNTIL b=z
 IF cy=0
 h1!c0 := a <> RESULTIS c+sg
 { gw1 := h3!a+1
 UNLESS gw1=numba
 { gw2 := h2!a
 BREAK }
 gw2 := h2!a+1
 UNLESS gw2=numba
 { gw1 := 0
 BREAK }
 a := h1!a
 h1!c0 := getx (s_numj, zsy, 0, 0)
 c0 := h1!c0
 l:    IF a=z
 { h1!c0 := getx (s_numj, z, 0, 1)
 RESULTIS c+sg }
 } REPEAT
 h1!c0 := getx (s_numj, h1!a, gw2, gw1)
 RESULTIS c+sg
 }
 
 
AND longsub (a, b) = VALOF      // |A| > |B|
 { LET c = zsy
 sg, cy := a & ysg, 0
 { gw1 := h3!a-h3!b-cy
 TEST gw1<0
 { gw1 := gw1+numba
 cy := 1 }
 ELSE cy := 0
 gw2 := h2!a-h2!b-cy
 TEST gw2<0
 { gw2 := gw2+numba
 cy := 1 }
 ELSE cy := 0
 a, b := h1!a, h1!b
 c := getx (s_numj, c, gw2, gw1)
 } REPEATUNTIL b=z
 { LET s = a
 TEST cy~=0     // -> A ~= Z
 { LET s0 = @c | signbit    // ??B?? S0=@S-1
 { UNLESS h3!a=0
 { gw1 := h3!a-1
 gw2 := h2!a
 BREAK }
 UNLESS h2!a=0
 { gw2 := h2!a-1
 gw1 := numbb
 GOTO l1 }
 a := h1!a
 h1!s0 := getx (s_numj, zsy, numbb, numbb)
 s0 := h1!s0
 } REPEAT        // A ~= Z
 TEST gw1=0=gw2 & h1!a=z
 TEST s=a
 { s := z
 GOTO l2 }
 ELSE h1!s0 := z
 OR
 l1:   h1!s0 := getx (s_numj, h1!a, gw2, gw1)
 }
 ELSE IF a=z
 {
 l2:      WHILE h2!c=0     // here S=Z
 { IF h3!c=0
 { c := h1!c    // nb will not overshoot since A ~= B
 LOOP }
 IF h1!c=zsy
 TEST sg=0
 RESULTIS h3!c+y0
 ELSE RESULTIS y0-h3!c
 BREAK }
 }
 { LET t = h1!c
 h1!c := s
 IF t=zsy
 RESULTIS c+sg
 s, c := c, t } REPEAT
 }
 }
 
 
// -NUMBA < N-Y0 < NUMBA
 
 
AND longas1 (a, n, f) = VALOF   // F -> ADD1,SUB1
 { sg := a & ysg
 TEST n<=y0
 { IF n=y0
 RESULTIS a
 gw1 := y0-n
 IF f NEQV sg>0
 GOTO l }
 ELSE { gw1 := n-y0
 IF f NEQV sg=0
 GOTO l }
 gw1 := h3!a+gw1
 UNLESS gw1>=numba
 RESULTIS getx (s_numj, h1!a, h2!a, gw1)+sg
 gw1 := gw1-numba
 gw2 := h2!a+1
 UNLESS gw2=numba
 RESULTIS getx (s_numj, h1!a, gw2, gw1)+sg
 a := h1!a
 { LET c = getx (s_numj, zsy, 0, gw1)
 LET c0 = c
 { gw1 := h3!a+1
 UNLESS gw1=numba
 { gw2 := h2!a
 BREAK }
 gw2 := h2!a+1
 UNLESS gw2=numba
 { gw1 := 0
 BREAK }
 a := h1!a
 h1!c0 := getx (s_numj, zsy, 0, 0)
 c0 := h1!c0
 IF a=z
 { h1!c0 := getx (s_numj, z, 0, 1)
 RESULTIS c+sg }
 } REPEAT
 h1!c0 := getx (s_numj, h1!a, gw2, gw1)
 RESULTIS c+sg
 }
 l:   gw1 := h3!a-gw1
 UNLESS gw1<=0
 RESULTIS getx (s_numj, h1!a, h2!a, gw1)+sg
 gw1 := gw1+numba
 gw2 := h2!a-1
 a := h1!a
 UNLESS gw2<0
 { IF gw2=0 & a=z
 TEST sg=0
 RESULTIS gw1+y0
 ELSE RESULTIS y0-gw1
 RESULTIS getx (s_numj, a, gw2, gw1)+sg }
 { LET c = getx (s_numj, zsy, numbb, gw1)
 LET c0 = c
 { UNLESS h3!a=0
 { gw1 := h3!a-1
 gw2 := h2!a
 BREAK }
 UNLESS h2!a=0
 { gw2 := h2!a-1
 gw1 := numbb
 BREAK }
 a := h1!a
 h1!c0 := getx (s_numj, zsy, numbb, numbb)
 c0 := h1!c0
 } REPEAT      // A~=Z
 TEST gw2=0=gw1 & h1!a=z
 h1!c0 := z
 ELSE h1!c0 := getx (s_numj, h1!a, gw2, gw1)
 RESULTIS c+sg
 }
 }
 
 
AND smul (a, b) = VALOF
 { LET c = muldiv (a-y0, b-y0, numba)
 IF c=0
 RESULTIS result2+y0
 TEST result2<0
 result2, c, sg := -result2, -c, ysg
 ELSE sg := 0
 RESULTIS getx (s_numj, z, c, result2)+sg }
 
 
// -NUMBA < N-Y0 < NUMBA
 
 
AND longmul1 (a, n) = VALOF
 { LET n0 = @a | signbit     // ??B?? N0=@N-1
 gl1, n := n-y0, z
 TEST gl1>1
 sg := a & ysg
 ELSE TEST gl1<-1
 gl1, sg := -gl1, (a & ysg) NEQV ysg
 ELSE TEST gl1=0
 RESULTIS y0
 ELSE TEST gl1=1
 RESULTIS a
 ELSE RESULTIS a NEQV ysg
 gl2 := 0
 { { LET t = muldiv (h3!a, gl1, numba)
 gw3 := gl2+result2
 IF gw3>=numba
 { gw3 := gw3-numba
 t := t+1 }
 gl2 := muldiv (h2!a, gl1, numba)
 gw2 := t+result2
 IF gw2>=numba
 { gw2 := gw2-numba
 gl2 := gl2+1 }
 }
 a := h1!a
 h1!n0 := getx (s_numj, zsy, gw2, gw3)
 n0 := h1!n0
 } REPEATUNTIL a=z
 TEST gl2=0
 h1!n0 := z
 ELSE h1!n0 := getx (s_numj, z, 0, gl2)
 RESULTIS n+sg
 }
 
 
AND longmul (a, b) = VALOF
 { LET c = getx (s_numj, zsy, 0, 0)+((a NEQV b) & ysg)
 LET cc = c
 
 { LET a1, b1 = h1!a, b
 UNTIL a1=z
 { c := getx (s_numj, c, 0, 0)
 a1 := h1!a1 }
 { c := getx (s_numj, c, 0, 0)
 b1 := h1!b1 } REPEATUNTIL b1=z }
 
 { LET c0 = c
 { LET b1, c1 = b, c0
 gl1, gl3 := 0, h3!a
 { gw3 := h3!c1+gl1
 gw2 := h2!c1+muldiv (gl3, h3!b1, numba)
 IF gw3>=numba
 { gw3 := gw3-numba
 gw2 := gw2+1 }
 gw3 := gw3+result2
 IF gw3>=numba
 { gw3 := gw3-numba
 gw2 := gw2+1 }
 h3!c1 := gw3
 gl1 := muldiv (gl3, h2!b1, numba)
 IF gw2>=numba
 { gw2 := gw2-numba
 gl1 := gl1+1 }
 gw2 := gw2+result2
 IF gw2>=numba
 { gw2 := gw2-numba
 gl1 := gl1+1 }
 h2!c1 := gw2
 b1, c1 := h1!b1, h1!c1
 } REPEATUNTIL b1=z
 h3!c1 := gl1
 gl3, a := h2!a, h1!a
 IF gl3=0
 { IF a=z
 BREAK
 c0 := h1!c0
 LOOP }
 b1, c1 := b, c0
 gw2 := h2!c1
 { gl1 := muldiv (gl3, h3!b1, numba)
 IF gw2>=numba
 { gw2 := gw2-numba
 gl1 := gl1+1 }
 gw2 := gw2+result2
 IF gw2>=numba
 { gw2 := gw2-numba
 gl1 := gl1+1 }
 h2!c1 := gw2
 c1 := h1!c1
 gw3 := h3!c1+gl1
 gw2 := h2!c1+muldiv (gl3, h2!b1, numba)
 IF gw3>=numba
 { gw3 := gw3-numba
 gw2 := gw2+1 }
 gw3 := gw3+result2
 IF gw3>=numba
 { gw3 := gw3-numba
 gw2 := gw2+1 }
 h3!c1 := gw3
 b1 := h1!b1
 } REPEATUNTIL b1=z
 h2!c1 := gw2
 c0 := h1!c0
 } REPEATUNTIL a=z
 TEST h2!cc=0=h3!cc
// here, if C0 already = CC, then H3!CC ~= 0 (???)
 { UNTIL h1!c0=cc
 c0 := h1!c0
 h1!c0 := z }
 ELSE h1!cc := z
 }
 RESULTIS c
 }
 
 
// 0<=A<C;  RESULT2 := remainder
 
 
AND sdiv (a, b, c) = VALOF
 { LET t1 = muldiv (a, numba, c)
 LET t2 = b/c
 result2 := result2+b REM c
 IF result2>=c
 { result2 := result2-c
 t2 := t2+1 }
 RESULTIS t1+t2 }
 
 
// -NUMBA < N-Y0 < NUMBA
 
 
AND longdiv1 (a, n) = VALOF
// could try IF H1!A=Z ...
 { gl1, n := n-y0, zsy
 TEST gl1>1
 sg := a & ysg
 ELSE TEST gl1<-1
 gl1, sg := -gl1, (a & ysg) NEQV ysg
 ELSE TEST gl1=0
 msg1 (7) <> RESULTIS z
 ELSE { result2 := 0
 TEST gl1=1
 RESULTIS a
 ELSE RESULTIS a NEQV ysg }
 { n := getx (s_numj, n, h2!a, h3!a)
 a := h1!a } REPEATUNTIL a=z
 a := n
 UNLESS h2!n=0
 { result2 := h2!n REM gl1
 h2!n := h2!n/gl1
 GOTO l }
 result2 := h3!n REM gl1
 h3!n := h3!n/gl1
 IF h3!n=0
 a := h1!a
 n := h1!n // H2!N=0 -> H1!N ~= ZSY
 { h2!n := sdiv (result2, h2!n, gl1)
 l:      h3!n := sdiv (result2, h3!n, gl1)
 n := h1!n } REPEATUNTIL n=zsy
 IF sg>0
 result2 := -result2
 IF h1!a=zsy & h2!a=0
 TEST sg=0
 RESULTIS h3!a+y0
 ELSE RESULTIS y0-h3!a
 { LET b = z      // Unreverse A
 { LET t = h1!a
 h1!a := b
 IF t=zsy
 RESULTIS a+sg
 b, a := a, t } REPEAT }
 }
 
 
AND longdiv (a, b) = msg1 (26, "longdiv")
 
 
AND lgcd (a, b) = msg1 (26, "LGCD")
 
 
.
//./       ADD LIST=ALL,NAME=MARK
 SECTION "MARK"
 
 
GET "pal75hdr"
 
 
STATIC
 { gc1 = 0
 w = 0 }
 
 
LET gpfn (f) BE
 IF validcode (!f>>2)
 !f := !f | signbit
 
 
// NB THROWS AT LEAST ONCE
// Throwable chains end up at ZSY
 
 
AND throw (aa) BE
 { LET a = !aa
 !aa := z  // Unset the handle
 !a := stackp
 { LET t = h1!a
 cons := cons+4
 IF t=zsy
 { stackp := a
 RETURN }
 !t, a := a, t } REPEAT }
 
 
AND clock (b) BE
 { STATIC
 { timing = FALSE
 t = 0 }
 IF b=timing
 RETURN
 timing := ~timing
 TEST b
 rtime := rtime+time ()-t
 ELSE t := time () }
 
 
AND tempusp (s, f) BE
 { selectoutput (sysout)
 writef ("%M# %S after %V+%V s", s, time ()-rtime, rtime)
 UNLESS f=0
 f ()
 newline ()
 selectoutput (q_output) }
 
 
AND tt (a) BE
 { STATIC
 { stx = 0 }
 tab (26)
 writef ("%N%% heap used", (ssz-w-(st1-@a))*100/ssz)
 IF paramk
 { writef ("   %N cycles; %N cons", cycles-y0, cons-y0)
 UNLESS stx=st1
 { stx := st1
 tab (68)
 writef ("BCPL/gap/PAL %N/%N/%N words",
 @a-stackbase, st1-@a, st2-st1) } }
 }
 
 
AND squas () BE
 { LET n = squash ()
 IF n=0 & w<kwords
 msg1 (39)
 TEST n<5
 ksq := ksq/2
 ELSE IF n>10
 ksq := (ksq*3)/2 }
 
 
AND stkover () BE       // Try recrem
 stack (kstack)
 
 
AND stack (n) BE
 { n := n+(@n+fr_s) & ~3
 IF n<=st1
 { IF n>=@n+fr_s
 { LET t = stackp
 st1 := st1-4
 stackp := st1
 UNTIL st1<=n
 { st1 := st1-4
 4!st1 := st1
 cons := cons+4 }
 !st1 := t
 stackl := st1-fr_s
 RETURN
 }
 msg1 (16, stack, n)
 }
 clock (FALSE)
 okpal := FALSE
 
// N>ST1;  Shovel heap up past N
 
 l0:  FOR i=svv TO st2 BY 4
 !i := -!i
 FOR i=@e TO @erz
 IF !i>0
 marka (!i)
 { LET q1 = @n-3
 { LET q = 1!q1>>2
 IF q<=stackbase
 BREAK
 IF !q<0
 FOR i=q+3 TO q1-1
 IF !i>0
 marka (!i)
 q1 := q } REPEAT }
 
 FOR i=svv TO st2 BY 4
 !i := -!i
 stackp, w, gc1 := 0, 0, st1
 { LET p = n
 IF p>=svu
 msg1 (38)
 { UNTIL !p>0  // note that this loop precedes the next
 { !p := -!p
 p := p+4 }
 UNTIL !st1<=0
 { IF st1>=n
 GOTO l1
 st1 := st1+4 }
 IF p>svu
 { FOR i=st1 TO n-4 BY 4
 !i := ABS (!i)
 scanp (indir)
 IF squash ()=0
 msg1 (39)
 GOTO l0 }
 !p, h1!p, h2!p, h3!p := -!st1, h1!st1, h2!st1, h3!st1
 !st1 := p
 p := p+4
 st1 := st1+4
 } REPEAT
 l1: FOR i=p TO svu BY 4
 TEST !i<=0
 !i := -!i
 ELSE !i, stackp, w := stackp, i, w+4
 }
 scanp (indir)
 cons := cons+w
 okpal := TRUE
 clock (TRUE)
 IF paramv
 tempusp ("GC1", tt)
 IF paramd // ?D
 verify ()      // ?D
 IF w<ksq
 squas ()
 }
 
 
AND get4 (a, b, c, d) = VALOF
{ IF stackp=0 DO
  { a := -a
sawritef("get4: calling rec0() stackp=%n*n", stackp)
    rec0 ()
    a := -a
  }
sawritef("get4: stackp=%n*n", stackp)
  { LET p = stackp
    stackp, !p, 1!p, 2!p, 3!p := !stackp, a, b, c, d
    RESULTIS p
  }
}
 
 
AND getx (a, b, c, d) = VALOF
{ IF stackp=0 DO
  { STATIC      // may not be nec
    { cc = 0
      dd = 0
    }
    cc, dd := c, d
    a, c, d := -a, 0, 0
    rec0 ()
    a, c, d := -a, cc, dd
  }
  { LET p = stackp
    stackp, !p, 1!p, 2!p, 3!p := !stackp, a, b, c, d
    RESULTIS p
  }
}
 
 
AND rec0 () BE
{ { LET t = 0
    IF st1-@t>2*kstack DO
    { stack (kstack)
      RETURN
    }
  }
  clock (FALSE)
  okpal := FALSE
 
  FOR i=svv TO st2 BY 4 DO !i := -!i
  FOR i=@e TO @erz IF !i>0 DO marka (!i)
  { LET q1 = @q1-3
    { LET q = 1!q1>>2
      IF q<=stackbase BREAK
      IF !q<0 FOR i=q+3 TO q1-1 IF !i>0 DO marka (!i)
      q1 := q
    } REPEAT
  }
 
  FOR i=svv TO st2 BY 4 DO !i := -!i
  w := 0
  FOR p=st1 TO svu BY 4 TEST !p<=0
    THEN !p := -!p
    ELSE !p, stackp, w := stackp, p, w+4
  cons := cons+w
 
  okpal := TRUE
  clock (TRUE)
  IF paramv DO tempusp ("GC", tt)
  UNLESS trz=z IF cons>h3!trz DO dotrap ()
  IF w<ksq DO squas ()
}
 
 
AND indir (p) BE
{ LET q = !p
  IF q>0 DO
  { LET r = q & p_addr
    IF gc1<=r<st1 DO !p := !r+(q & p_tag)
  }
}
 
 
AND scanp (f) BE
{ FOR i=st1 TO st2 BY 4 DO
  { IF !i>=mm3 DO f (i+3) <>
                  f (i+2)
    f (i+1)
  }
  FOR i=@e TO @a_null DO f (i)
  FOR i=typ TO typ+typsz DO f (i)
  scanst (f)
}
 
 
AND scanst (f) BE
{ LET q1 = (-2)!(@f)>>2
  { LET q = 1!q1>>2
    IF q<=stackbase RETURN
    IF !q<0 FOR i=q+3 TO q1-1 DO f (i)
    q1 := q
  } REPEAT
}
 
 
AND flevel (f) = VALOF
{ LET q = (-2)!(@f)>>2
  { q := 1!q>>2
    IF !q=f RESULTIS q<<2
  } REPEATUNTIL q<=stackbase
  msg1 (32, f)
}
 
 
 
 
// This one stores (+ve) reverse link in ptr word, having marked hdr word
 
 
LET marka (p) BE
{ { LET u = !p
    IF u<=0 RETURN
    IF u<mm3 DO
    { { !p := -u
        p := h1!p
        IF p<=0 RETURN
        u := !p
      } REPEATWHILE u>0
      RETURN
    }
    !p := -u
  }
  { LET k, n, q, t = @p+fr_gc, 3, 0, 0
    (fr_gc-1)!(@p) := 0
    { {/*P*/ IF n=0 DO
        { k := k-1
          p := !k-1
          IF p<0 RETURN
          n := p & 3
          p := p-n
        }      // assert: N~=0
        t := n!p
        IF t<=0 DO
        { n := n-1
          LOOP
        }

 l1:    { LET u = !t
          IF u<=0 DO
          { n := n-1
            LOOP
          }
          IF u<mm3 DO
          { { !t := -u
              t := h1!t
              IF t<=0 BREAK
              u := !t
            } REPEATWHILE u>0
            n := n-1
            LOOP
          }
          !t := -u
          { LET nn = h3!t>0 -> 3,
                     h2!t>0 -> 2,
                     h1!t>0 -> 1, 0
            IF nn=0 DO
            { n := n-1
              LOOP
            }
            UNLESS n=1 DO
            { IF k>=st1 DO
              { n!p := q
                q := p+n
                p, n := t, nn
                t := n!p
                GOTO l2
              }
              !k := p+n
              k := k+1
            }
            p, n := t, nn
            t := n!p
            GOTO l1
          }
        }
      }/*P*/ REPEAT
      {/*P*/ IF n=0 DO
        { IF q=0 BREAK
          { LET t = !q
            !q := p
            p := q-1
            n := p & 3
            p := p-n
            q := t
          }
          LOOP
        }
        t := n!p
        IF t<=0 DO
        { n := n-1
          LOOP
        }
 l2:    { LET u = !t
          IF u<=0 DO
          { n := n-1
            LOOP
          }
          IF u<mm3 DO
          { { !t := -u
              t := h1!t
              IF t<=0 BREAK
              u := !t
            } REPEATWHILE u>0
            n := n-1
            LOOP
          }
          !t := -u
          { LET nn = h3!t>0 -> 3,
                     h2!t>0 -> 2,
                     h1!t>0 -> 1, 0
            IF nn=0 DO
            { n := n-1
              LOOP
            }
            n!p := q
            q := p+n
            p, n := t, nn
            t := n!p
            GOTO l2
          }
        }
      }/*P*/ REPEAT
    } REPEAT
  }
}

 
 
 
 
// This one stores (-ve) reverse link in hdr word, and stores (+ve) hdr
// in ptr word
 
// P,Q ARE SAME TYPE, COMPOSITE; AND P ~= Q
 
 
AND eql (p, q) = VALOF
{ LET b, m, n = TRUE, p, 3
  okpal := FALSE
  !p, !q := -!p, -!q
  GOTO l
 
  {/*1*/ UNLESS b & n~=0 DO
    { LET s, t = -!p, -!q
      IF p=m DO
      { !p, !q := s, t
        okpal := TRUE
        RESULTIS b
      }
      !p, !q := !s, !t
      !t := q
      TEST b
      THEN !s := q
      ELSE !s := p
      n := s & 3
      p, q, n := s-n, t-n, n-1
      LOOP
    }
 l: { LET u, v = n!p, n!q
      IF u=v DO
      { n := n-1
        LOOP
      }
      IF u<=0 | v<=0 DO
      { b := FALSE
        LOOP
      }
      { LET s, t = !u, !v
        // IF S=T<0 GIVE UP FOR NOW
        UNLESS s=t & s>=0 DO
        { b := FALSE
          LOOP
        }
        SWITCHON s INTO
        {
          CASE s_gensy:
          CASE s_name:
          CASE s_glz:
          CASE s_glg:
          CASE s_glo:
          CASE s_loc:
          CASE s_xtupl:
          CASE s_unset:
          CASE s_unset1:
          CASE s_tra:
            b := FALSE   // since U~=V
            LOOP
          CASE s_flt:
            UNLESS h2!u #= h2!v DO b := FALSE <>
                                   LOOP
            ENDCASE
          CASE s_fpl:
            msg1 (14)
          CASE s_ratn:
            UNLESS h1!u=h1!v DO b := FALSE <>
                                LOOP
          CASE s_rds:
          CASE s_wrs:
          CASE s_bcplf:
          CASE s_bcplr:
          CASE s_bcplv:
          CASE s_codev:
          CASE s_code0:
          CASE s_code1:
          CASE s_code2:
          CASE s_code3:
          CASE s_code4:
            UNLESS h2!u=h2!v DO b := FALSE <>
                                LOOP
            ENDCASE
          CASE s_numj:
            IF (u NEQV v)<ysg DO
            { CASE s_string:
                { UNLESS h2!u=h2!v & h3!u=h3!v BREAK
                  u, v := h1!u, h1!v
                  IF u=v ENDCASE
                } REPEATUNTIL u=z | v=z
            }
            b := FALSE
            LOOP
          CASE s_poly:
            IF h3!u=h3!v DO
            { LET f = u NEQV v
              { u, v := h1!u, h1!v
                IF u=v TEST u=z
                THEN ENDCASE
                ELSE TEST f<ysg
                     THEN ENDCASE
                     ELSE BREAK
                IF u=z | v=z BREAK
                UNLESS h3!u=h3!v BREAK
                f := f NEQV (u NEQV v)
              } REPEATWHILE eqpoly (h2!u, h2!v, f<ysg)
            }
            b := FALSE
            LOOP
          DEFAULT:
            !u, !v := -p-n, -q-n
            n!p, n!q := s, t
            p, q, n := u, v, 3
            LOOP
        }
        n := n-1
      }
    }
  }/*1*/ REPEAT
} 
 
.
//./       ADD LIST=ALL,NAME=MUL
 SECTION "MUL"
 
 
GET "pal75hdr"
 
 
MANIFEST
 { ny0 = -y0 }
 
 
STATIC
 { sg = 0
 ga1 = 0
 ga2 = 0
 ga3 = 0
 ga4 = 0 }
 
 
// In MUL and DIV, G=Yn -> gcd removed from polys of degree n and more;
// G=Y0 -> numeric gcd removed
 
 
LET mul (a, b) = VALOF
 { LET g = 0
 { SWITCHON coerce (@a, TRUE) INTO
 {
 CASE s_flt: RESULTIS getx (s_flt, 0, gw1 #* gw2, 0)
 CASE s_fpl: msg1 (14)
 CASE s_num: RESULTIS smul (a, b)
 CASE s_numj: IF numarg
 RESULTIS longmul1 (b, a)
 RESULTIS longmul (a, b)
 CASE s_ratn: IF numarg
 { IF a=y1
 RESULTIS b
 TEST g=y0
 { a := smul (a, h2!b)
 b := h1!b }
 ELSE { IF a=y0
 RESULTIS y0
 ga1 := igcd (a+ny0, h1!b+ny0)
 a := smul ((a+ny0)/ga1+y0, h2!b)
 b := (h1!b+ny0)/ga1+y0
 IF b=y1
 RESULTIS a }
 TEST a<=0
 sg := s_ratn
 ELSE sg := s_ratl
 RESULTIS get4 (sg, b, a, 0)
 }
 IF worse      // A is NUMJ
 { TEST g=y0
 { a := longmul1 (a, h2!b)
 b := h1!b }
 ELSE { ga1 := gcd1 (a, h1!b)
 a := longdiv1 (a, ga1+y0)
 TEST a<=0
 a := smul (a, h2!b)
 ELSE a := longmul1 (a, h2!b)
 b := (h1!b+ny0)/ga1+y0
 IF b=y1
 RESULTIS a }
 TEST a<=0
 sg := s_ratn
 ELSE sg := s_ratl
 RESULTIS get4 (sg, b, a, 0)
 }
 TEST g=y0
 { LET t = smul (h2!a, h2!b)
 b := smul (h1!a, h1!b)
 a := t }
 ELSE { LET t = h1!a
 ga1 := igcd (h2!a+ny0, h1!b+ny0)
 ga2 := igcd (t+ny0, h2!b+ny0)
 a := smul ((h2!a+ny0)/ga1+y0, (h2!b+ny0)/ga2+y0)
 b := smul ((t+ny0)/ga2+y0, (h1!b+ny0)/ga1+y0)
 IF b=y1
 RESULTIS a }
 TEST a<=0 & b<=0
 sg := s_ratn
 ELSE sg := s_ratl
 RESULTIS get4 (sg, b, a, 0)
 CASE s_ratl: IF worse
 { IF a=y1
 RESULTIS b
 IF g=y0
 { a := mul (a, h2!b)
 RESULTIS get4 (s_ratl, h1!b, a, 0) }
 IF a=y0
 RESULTIS y0
 a := div (a, h1!b)
 b := h2!b
 g := y0
 LOOP
 }
 IF g=y0
 { LET c = mul (h2!a, h2!b)
 b := mul (h1!a, h1!b)
 RESULTIS get4 (s_ratl, b, c, 0) }
 { LET c = div (h2!b, h1!a)
 a := div (h2!a, h1!b)
 b := c
 g := y0
 LOOP }
 CASE s_poly: IF worse
 RESULTIS polymapf (b, a, mul)
 RESULTIS mulpoly (a, b)
 CASE s_ratp: IF worse
 { IF a=y1
 RESULTIS b
 IF g<=h3!b
 { a := mul (a, h2!b)
 RESULTIS get4 (s_ratp, h1!b, a, h3!b) }
 IF a=y0
 RESULTIS y0
 a := div (a, h1!b)
 g := h3!b
 b := h2!b
 LOOP
 }
 IF g<=h3!b
 { LET c = mul (h1!a, h1!b)
 a := mul (h2!a, h2!b)
 RESULTIS get4 (s_ratp, c, a, h3!b) }
 { LET c = div (h2!b, h1!a)
 a := div (h2!a, h1!b)
 g := h3!b
 b := c
 LOOP }
 DEFAULT: IF a=y0 | b=y0
 RESULTIS y0
 IF a=y1
 RESULTIS b
 IF b=y1
 RESULTIS a
 RESULTIS arithfn (a, b, a_mul)
 }
 } REPEAT
 }
 
 
AND div (a, b) = VALOF
 { LET g = 0
 { SWITCHON coerce (@a, FALSE) INTO
 {
 CASE s_num: ga1, ga2 := a+ny0, b+ny0
 IF ga2=0
 msg1 (7) <> RESULTIS z
 ga3 := ga1 REM ga2
 IF ga3=0
 RESULTIS ga1/ga2+y0
 TEST g=y0
 ga3 := 1
 ELSE ga3 := igcd (ga2, ga3)
 IF ga2<0
 ga3 := -ga3
 RESULTIS get4 (s_ratn, ga2/ga3+y0, ga1/ga3+y0, 0)
 
 CASE s_numj: IF numarg
 { IF worse1
 { IF g=y0
 { IF b<y0
 b, a := signbit-b, a NEQV ysg
 IF b=y1
 RESULTIS a
 RESULTIS get4 (s_ratl, b, a, 0) }
 ga1 := longdiv1 (a, b)
 IF result2=0
 RESULTIS ga1
 ga1 := igcd (b+ny0, result2)
 IF b<y0
 ga1 := -ga1
 UNLESS ga1=1
 { b := (b+ny0)/ga1+y0
 a := longdiv1 (a, ga1+y0) }
 IF b=y1
 RESULTIS a
 TEST a<=0
 sg := s_ratn
 ELSE sg := s_ratl
 RESULTIS get4 (sg, b, a, 0)
 }
 IF g=y0
 { IF b>=ysg
 b, a := b NEQV ysg, signbit-a
 RESULTIS get4 (s_ratl, b, a, 0) }
 IF a=y0
 RESULTIS y0
 ga1 := gcd1 (b, a)
 IF b>=ysg
 ga1 := -ga1
 UNLESS ga1=1
 { a := (a+ny0)/ga1+y0
 b := longdiv1 (b, ga1+y0) }
 TEST b<=0
 sg := s_ratn
 ELSE sg := s_ratl
 RESULTIS get4 (sg, b, a, 0)
 }
 IF g=y0
 { IF b>=ysg
 b, a := b NEQV ysg, a NEQV ysg
 RESULTIS get4 (s_ratl, b, a, 0) }
 { LET c = longdiv (a, b)
 IF result2=y0
 RESULTIS c
 c := lgcd (b, c)
 IF b>=ysg
 c := neg (c)
 UNLESS c=y1
 a, b := div (a, c), div (b, c) }
 TEST a<=0 & b<=0
 sg := s_ratn
 ELSE sg := s_ratl
 RESULTIS get4 (sg, b, a, 0)
 
 CASE s_ratn: IF numarg
 TEST worse1
 { IF b=y1
 RESULTIS a        // opt
 IF b=ym
 RESULTIS neg (a)  // opt
 TEST g=y0
 { TEST b<y0
 gw1, a := signbit-h1!a, signbit-h2!a
 ELSE gw1, a := h1!a, h2!a
 b := smul (gw1, b) }
 ELSE { IF b=y0
 msg1 (7) <> RESULTIS z
 ga1 := igcd (h2!a+ny0, b+ny0)
 IF b<y0
 ga1 := -ga1
 b := smul (h1!a, (b+ny0)/ga1+y0)
 a := (h2!a+ny0)/ga1+y0 }
 TEST b<=0
 sg := s_ratn
 ELSE sg := s_ratl
 RESULTIS get4 (sg, b, a, 0)
 }
 ELSE { TEST g=y0
 { TEST h2!b<y0
 gw1, b := signbit-h1!b, signbit-h2!b
 ELSE gw1, b := h1!b, h2!b
 a := smul (a, gw1) }
 ELSE { IF a=y0
 RESULTIS y0
 ga1 := igcd (a+ny0, h2!b+ny0)
 IF h2!b<y0
 ga1 := -ga1
 a := smul ((a+ny0)/ga1+y0, h1!b)
 b := (h2!b+ny0)/ga1+y0 }
 IF b=y1
 RESULTIS a
 TEST a<=0
 sg := s_ratn
 ELSE sg := s_ratl
 RESULTIS get4 (sg, b, a, 0)
 }
 IF worse
 TEST worse1        // B is NUMJ
 { TEST g=y0
 { TEST b>=ysg
 gw1, a := signbit-h1!a, signbit-h2!a
 ELSE gw1, a := h1!a, h2!a
 b := longmul1 (b, gw1) }
 ELSE { ga1 := gcd1 (b, h2!a)
 IF b>=ysg
 ga1 := -ga1
 b := longdiv1 (b, ga1+y0)      // Now B is positive
 TEST b<=0
 b := smul (b, h1!a)
 ELSE b := longmul1 (b, h1!a)
 a := (h2!a+ny0)/ga1+y0 }
 TEST b<=0
 sg := s_ratn
 ELSE sg := s_ratl
 RESULTIS get4 (sg, b, a, 0)
 }
 ELSE { TEST g=y0
 { TEST h2!b<y0
 gw1, b := signbit-h1!b, signbit-h2!b
 ELSE gw1, b := h1!b, h2!b
 a := longmul1 (a, gw1) }
 ELSE { ga1 := gcd1 (a, h2!b)
 IF h2!b<y0
 ga1 := -ga1
 a := longdiv1 (a, ga1+y0)
 TEST a<=0
 a := smul (a, h1!b)
 ELSE a := longmul1 (a, h1!b)
 b := (h2!b+ny0)/ga1+y0 }
 IF b=y1
 RESULTIS a
 TEST a<=0
 sg := s_ratn
 ELSE sg := s_ratl
 RESULTIS get4 (sg, b, a, 0)
 }
 TEST g=y0
 { LET t = h2!b
 TEST t<y0
 t, gw1 := signbit-t, signbit-h1!b
 ELSE gw1 := h1!b
 b := smul (h2!a, gw1)
 a := smul (h1!a, t) }
 ELSE { LET t = h2!b
 ga1 := igcd (h2!a+ny0, t+ny0)
 ga2 := igcd (h1!a+ny0, h1!b+ny0)
 IF t<y0
 ga1 := -ga1
 b := smul ((h2!a+ny0)/ga1+y0, (h1!b+ny0)/ga2+y0)
 a := smul ((h1!a+ny0)/ga2+y0, (t+ny0)/ga1+y0)
 IF a=y1
 RESULTIS b }
 TEST a<=0 & b<=0
 sg := s_ratn
 ELSE sg := s_ratl
 RESULTIS get4 (sg, a, b, 0)
 
 CASE s_ratl: IF worse
 { IF worse1
 { IF b=y1
 RESULTIS a     // opt
 IF b=ym
 RESULTIS neg (a)       // opt
 IF g=y0
 { b := mul (h1!a, b)
 a := h2!a
 UNLESS positive (b)
 b, a := neg (b), neg (a)
 RESULTIS get4 (s_ratl, b, a, 0) }
 gw1 := div (h2!a, b)
 b := h1!a
 a := gw1
 g := y0
 LOOP
 }
 IF g=y0
 { a := mul (a, h1!b)
 b := h2!b
 UNLESS positive (b)
 b, a := neg (b), neg (a)
 RESULTIS get4 (s_ratl, b, a, 0) }
 IF a=y0
 RESULTIS y0
 gw1 := div (h2!b, a)
 a := h1!b
 b := gw1
 g := y0
 LOOP
 }
 IF g=y0
 { LET c = mul (h2!a, h1!b)
 b := mul (h1!a, h2!b)
 UNLESS positive (b)
 b, c := neg (b), neg (c)
 RESULTIS get4 (s_ratl, b, c, 0) }
 { LET c = div (h2!a, h2!b)
 b := div (h1!a, h1!b)
 a := c
 g := y0
 LOOP }
 
 CASE s_poly: TEST worse
 TEST worse1
 { IF b=y0
 msg1 (7) <> RESULTIS z
 RESULTIS polymapf (a, b, div) }
 ELSE IF a=y0
 RESULTIS y0
 ELSE IF g>h3!b
 { ga1 := divpoly (a, b)
 IF result2=y0
 RESULTIS ga1
 { LET c = lcoef
 IF result2>0 & !result2=s_poly & h3!result2=h3!b
 { LET r = polygcd (b, result2)
 UNLESS r=y1
 { c := div (c, lcoef)
 c := polymapf (r, c, mul) } }
 UNLESS c=y1
 { a := div (a, c)
 b := div (b, c) } }
 RESULTIS get4 (s_ratp, b, a, h3!b)
 }
 b := monicpoly (b)
 UNLESS lcoef=y1
 a := div (a, lcoef)
 RESULTIS get4 (s_ratp, b, a, h3!b)
 
 CASE s_ratp: IF worse
 TEST worse1
 { IF b=y1
 RESULTIS a        // opt
 IF b=ym
 RESULTIS neg (a)  // opt
 IF g<=h3!a
 { LET a1 = h1!a
 IF b>0 & !b=s_poly & h3!b=h3!a
 { b := monicpoly (b)
 TEST lcoef=y1
 a := h2!a
 ELSE a := div (h2!a, lcoef)
 b := mul (a1, b)
 RESULTIS get4 (s_ratp, b, a, h3!b) }
 a := div (h2!a, b)
 RESULTIS get4 (s_ratp, a1, a, h3!a1)
 }
 { LET t = div (h2!a, b)
 b := h1!a
 g := h3!a
 a := t }
 LOOP
 }
 ELSE { IF g<=h3!b
 { a := mul (a, h1!b)
 b := h2!b
 LOOP }
 IF a=y0
 RESULTIS y0
 { LET t = div (h2!b, a)
 a := h1!b
 g := h3!b
 b := t }
 LOOP
 }
 IF g<=h3!b
 { LET b2 = h2!b
 IF b2>0 & !b2=s_poly & h3!b2=h3!a
 { b2 := monicpoly (b2)
 TEST lcoef=y1
 b := h1!b
 ELSE b := div (h1!b, lcoef)
 b2 := mul (h1!a, b2)
 b := mul (h2!a, b)
 RESULTIS get4 (s_ratp, b2, b, h3!a) }
 b2 := div (h2!a, b2)
 b := mul (b2, h1!b)
 RESULTIS get4 (s_ratp, h1!a, b, h3!a)
 }
 { LET c = div (h2!a, h2!b)
 b := div (h1!a, h1!b)
 g := h3!a
 a := c
 LOOP }
 
 CASE s_flt: IF gw2 #= 0.0
 msg1 (7) <> RESULTIS z
 RESULTIS getx (s_flt, 0, gw1 #/ gw2, 0)
 CASE s_fpl: msg1 (14)
 DEFAULT: IF b=y1
 RESULTIS a
 IF a=y0
 RESULTIS y0
 IF eqlv (a, b)
 RESULTIS y1
 RESULTIS arithfn (a, b, a_div)
 }
 } REPEAT
 }
 
 
AND modv (a, b) = VALOF
 { coerce (@a, FALSE)
 IF b<=0
 { IF b=y0
 msg1 (7) <> RESULTIS z
 IF a<=0
 RESULTIS (a+ny0) REM (b+ny0)+y0
 SWITCHON !a INTO
 {
 CASE s_numj: longdiv1 (a, b)
 RESULTIS result2+y0
 CASE s_poly: RESULTIS y0
 DEFAULT: GOTO l }
 }
 SWITCHON !b INTO
 {
 CASE s_numj: IF a<=0
 RESULTIS a
 SWITCHON !a INTO
 {
 CASE s_numj: longdiv (a, b)
 RESULTIS result2
 CASE s_poly: RESULTIS y0
 DEFAULT: GOTO l }
 CASE s_poly: IF a<=0
 RESULTIS a
 SWITCHON !a INTO
 {
 CASE s_flt:
 CASE s_fpl:
 CASE s_numj:
 CASE s_ratn:
 CASE s_ratl: RESULTIS a
 CASE s_poly: IF worse
 TEST worse1
 RESULTIS y0
 ELSE RESULTIS a
 divpoly (a, b)
 RESULTIS result2
 DEFAULT: GOTO l
 }
 l:   DEFAULT: msg1 (23, a, b)
 }
 }
 
 
STATIC
 { ga0 = 0 }
 
 
LET pow (a, b) = VALOF
 { coerce (@a, FALSE)
 IF a=y0 | a=y1
 RESULTIS a
 UNLESS b<0
 msg1 (23, a, b)
 TEST b<=y0
 { IF b=y0
 RESULTIS y1
 ga0 := y0-b
 a := recip (a) }
 ELSE ga0 := b-y0
 IF ga0=1
 RESULTIS a
 b := y1
 { UNLESS (ga0 & 1)=0
 { b := mul (a, b)
 IF ga0=1
 RESULTIS b }
 ga0 := ga0>>1
 a := mul (a, a) } REPEAT
 }
 
 
.
//./       ADD LIST=ALL,NAME=PALDD
 SECTION "PALDD"
 
 
GET "pal75hdr"
 
 
STATIC
 { l0 = 0
 dd0 = 0
 dd1 = 0
 dd2 = 0
 dd3 = 0 }
 
 
LET valglob (n) = sadd ((@g0)!n)
 
 
AND setglob (n1, n2) BE
 { (@g0)!n1 := (@g0)!n2
 writef ("*N# Global %N set to %A*N", n2, (@g0)!n2) }
 
 
AND validp (p) = VALOF
 { IF p<=0
 RESULTIS TRUE
 { LET q = p & p_addr
 LET qq = p-q
 UNLESS qq=0 | qq=ysg | qq=yfj | qq=p_tagp
 RESULTIS FALSE
 UNLESS st1<=q<=st2
 RESULTIS FALSE
 UNLESS 0<=!q<=typsz
 RESULTIS FALSE }
 RESULTIS TRUE
 }
 
 
AND lastditch (a) BE
 l (a, 0)
 
 
AND l (a, n) BE
 { newline ()
 tab (n*20)
 writeargp (a, FALSE)
 UNLESS st1<=(a & p_addr)<=st2
 RETURN
 IF n=3
 { tab (85)
 writes ("#...etc")
 RETURN }
 FOR i=1 TO 3
 l (a!i, n+1)
 }
 
 
AND verify () = VALOF
 { writef ("*N# checking heap (%T):")
 { LET s, n = stackp, 0
 UNTIL s=0
 { LET t = !s
 !s, h1!s := 0, t | signbit
 s := t
 n := n+4 }
 writef (" %N words free;*N", n) }
 l0, dd0 := ll, TRUE
 scanp (verh)
 ll:  { LET s = stackp
 UNTIL s=0
 !s, s := h1!s & p_addr, !s }
 writef ("*N# end of check (%T)*N")
 IF dd0
 RESULTIS TRUE
 okpal := TRUE
 writef ("*N# Bad link: %E (%N) -> %E*N", errorp, dd1, dd2, errorp, dd3)
 writeargp (dd1, TRUE)
 IF st1<=dd3<=st2
 { newline ()
 writeargp (h2!dd3, TRUE)
 newline ()
 writeargp (h3!dd3, TRUE) }
 q_selinput (sysin)
 rch := rch1
 { LET v = readx ()
 UNLESS v=z
 { writes ("*NRe-start DD")
 eval (v)
 stop (16) } }
 mapheap (FALSE)
 erz := zsy
 msg1 (13, verify)
 }
 
 
AND verh (p) BE
 { LET q = !p
 IF q>0
 { UNLESS validp (q)
 { dd0, dd1, dd2, dd3 := FALSE, p & ~3, p & 3, q
 longjump (flevel (verify), l0) }
 IF !q=0
 { writef ("%ZTANGLE %N-%N", 8, p, q)
 dd0 := FALSE
 dd1, dd2, dd3 := p & ~3, p & 3, q } } }
 
 
AND mapheap (f) BE
 { writef ("*N*N# HEAP (%T)*N")
 FOR i=st1 TO svu BY 4
 { ztab (4)
 writeargp (i, f) }
 writes ("*N #cold region#*N")
 FOR i=svv TO st2 BY 4
 { ztab (4)
 writeargp (i, f) }
 writef ("*N# END OF HEAP (%T)*N*N") }
 
 
AND userpostmortem (code, svalid) BE
 { userpostmortem := dummy
 errorreset ()
 IF paramk
 { UNLESS svalid
 abort (0)
 backtrace ()
 pmap (paramc)
 mapstore ()
 stop (20) } }
 
 
AND paldd (style, s, n, a, b, c, d, e, f) BE
 { writef ("*N# %S (%T)", s)
 FOR i=@a TO @a+n-1
 { ztab (10)
 style (!i) }
 newline () }
 
 
AND chpoly (a) BE
 { LET s = zero
 UNLESS a>0
 RETURN
 IF @a>stackl
 stkover ()
 UNLESS validp (a)
 errorp (a)
 IF !a=s_ratp
 { IF h2!a=y0
 s := "RATP" <> GOTO l
 chpoly (h1!a)
 chpoly (h2!a)
 RETURN }
 IF !a=s_poly
 { LET p = h1!a
 UNTIL p=z
 { IF (p & p_addr)=zsy | h2!p=y0
 s := "POLY" <> GOTO l
 p := h1!p }
 RETURN }
 RETURN
 l: writef ("*N*N# CHPOLY: BAD %S (%T)*N", s)
 printa (a)
 msg1 (0)
 }
 
 
AND ddadd (a, b) = VALOF
 { LET c = ddadd (a, b)
 chpoly (c)
 RESULTIS c }
 
 
AND ddminu (a, b) = VALOF
 { LET c = ddminu (a, b)
 chpoly (c)
 RESULTIS c }
 
 
AND ddmul (a, b) = VALOF
 { LET c = ddmul (a, b)
 chpoly (c)
 RESULTIS c }
 
 
AND dddiv (a, b) = VALOF
 { LET c = dddiv (a, b)
 chpoly (c)
 RESULTIS c }
 
 
AND ddaddpoly (a, b) = VALOF
 { LET c = ddaddpoly (a, b)
 chpoly (c)
 charith1 ()
 { LET t = add (c, b NEQV ysg)
 charith1 ()
 IF eqlv (t, a)
 RESULTIS c
 writef ("*N# +: (%E) + (%E) = %E*N", printa, a, printa, b, printa, c)
 msg1 (0)
 RESULTIS c }
 }
 
 
AND ddmulpoly (a, b) = VALOF
 { LET c = ddmulpoly (a, b)
 chpoly (c)
 IF c=y0
 RESULTIS c
 charith1 ()
 { LET t = div (c, b)
 charith1 ()
 IF eqlv (t, a)
 RESULTIS c
 writef ("*N# **: (%E) ** (%E) = %E*N", printa, a, printa, b, printa, c)
 msg1 (0)
 RESULTIS c }
 }
 
 
AND dddivpoly (a, b) = VALOF
 { LET c = dddivpoly (a, b)
 LET d1, d2, d3 = result2, lcoef, ldeg
 chpoly (c)
 chpoly (d1)
 charith1 ()
 { LET t = mul (b, c)
 t := add (t, d1)
 charith1 ()
 IF eqlv (t, a)
 { result2, lcoef, ldeg := d1, d2, d3
 RESULTIS c }
 writef ("*N# /: (%E) / (%E) = %E*N", printa, a, printa, b, printa, c)
 result2, lcoef, ldeg := d1, d2, d3
 msg1 (0)
 RESULTIS c
 }
 }
 
 
AND ddpseu (a, b) = VALOF
 { LET c = ddpseu (a, b)
 LET d2, d3 = lcoef, ldeg
 chpoly (c)
 charith1 ()
 { LET t = minu (a, c)
 t := div (t, b)
 charith1 ()
 IF result2=y0
 { lcoef, ldeg := d2, d3
 RESULTIS c }
 writef ("*N# REM: (%E) REM (%E) = %E*N", printa, a, printa, b, printa, c)
 lcoef, ldeg := d2, d3
 msg1 (0)
 RESULTIS c
 }
 }
 
 
AND ddequp (a, b, f) = VALOF
 { LET c = ddequp (a, b, f)
 charith1 ()
 { LET t = (f -> minu, add)(a, b)
 IF c=(t=y0)
 { charith1 ()
 RESULTIS c }
 writef ("*N# Q: (%E) = (%E) with %P : %P*N", printa, a, printa, b, f, c)
 msg1 (0)
 RESULTIS c } }
 
 
AND charith () BE
{ { LET t = add
    add, ddadd := ddadd | signbit, t | signbit
  }
  { LET t = minu
    minu, ddminu := ddminu | signbit, t | signbit
  }
  { LET t = mul
    mul, ddmul := ddmul | signbit, t | signbit
  }
  { LET t = div
    div, dddiv := dddiv | signbit, t | signbit
  }
}
 
AND charith1 () BE
{ charith ()
  { LET t = addpoly
    addpoly, ddaddpoly := ddaddpoly | signbit, t | signbit
  }
  { LET t = mulpoly
    mulpoly, ddmulpoly := ddmulpoly | signbit, t | signbit
  }
  { LET t = divpoly
    divpoly, dddivpoly := dddivpoly | signbit, t | signbit
  }
  { LET t = pseudorempoly
    pseudorempoly, ddpseu := ddpseu | signbit, t | signbit
  }
  { LET t = eqpoly
    eqpoly, ddequp := ddequp | signbit, t | signbit
  }
}
 
.

//./       ADD LIST=ALL,NAME=PALM1
 SECTION "PALM1"
 
 
GET "pal75hdr"
 
// Mainly print routines_
// Print routines can mangle structure;
// but not PRIN, which must be short, and not use any heap_
// It may ?? be safe to try printing when the heap is partially mangled,
// eg during gc
 
 
STATIC
 { s0 = 0
 s1 = 0
 kk = 0
 nn = 0 }
 
 
LET stream (r, s1, s2) = VALOF
 { LET n = r (s1, s2)
 IF n=0
 msg1 (9, s1, s2)
 RESULTIS n+y0 }
 
 
AND rds (s) = VALOF
 { LET n = stream (findinput, s, zero)
 IF n=y0
 RESULTIS z
 RESULTIS get4 (s_rds, 0, n, 0) }
 
 
AND wrs (s) = VALOF
 { LET n = stream (findoutput, s, zero)
 IF n=y0
 RESULTIS z
 RESULTIS get4 (s_wrs, 0, n, 0) }
 
 
AND rea () = rch ()+y0
 
 
AND prinpars (f, a, b) BE
 { wch ('(')
 f (a, b)
 wch (')') }
 
 
AND prin (a) = VALOF
 { LET x = a
 { s0, s1 := zero, 0
 IF x<=0
 { TEST ABS (x-y0)<=numba
 writen (x-y0)
 ELSE TEST x=0
 { s0 := "NIL"
 GOTO l1 }
 ELSE TEST x=-1
 { s0 := "TRUE"
 GOTO l1 }
 ELSE writef ("[%A]", x)
 RESULTIS a
 }
 SWITCHON !x INTO
 {
 DEFAULT: { LET t = !x
 IF 0<=t<=typsz
 { writef ("#%N#", t)
 x := tyv (x)
 LOOP }
 writef ("#?%N(%N)#", x, t)
 RESULTIS a }
 CASE s_tra: writes ("#trace#")
 x := h2!x
 LOOP
 CASE s_loc: x := h1!x
 LOOP
 CASE s_unset:
 CASE s_unset1:
 s0 := "#unset#"
 GOTO l1
 CASE s_flt: wrflt (h2!x)
 RESULTIS a
 CASE s_numj: writef ("...%N", h3!x)
 RESULTIS a
 CASE s_fpl: prfpl (x)
 RESULTIS a
 CASE s_ratn:
 CASE s_ratl:
 CASE s_ratp: s0, s1 := "#%Nrat#", h3!x
 IF s1<0
 s1 := s1-y0
 GOTO l2
 CASE s_rds:
 CASE s_wrs: s0 := "#stream#"
 GOTO l1
 CASE s_codev:
 CASE s_code0:
 CASE s_code1:
 CASE s_code2:
 CASE s_code3:
 CASE s_code4:
 CASE s_bcplf:
 CASE s_bcplr:
 CASE s_bcplv:
 s0, s1 := "%A", h2!x
 GOTO l2
 CASE s_tuple:
 s0, s1 := "#%N-tuple#", h3!x-y0
 GOTO l2
 CASE s_xtupl:
 s0, s1 := "#%N-xtuple#", h3!x-y0
 GOTO l2
 CASE s_poly: s0, s1 := "#poly%N#", h3!x-y0
 GOTO l2
 CASE s_polyj:
 s0, s1 := "#term%N#", h3!x-y0
 GOTO l2
 CASE s_cdx:
 CASE s_cdy: s0, s1 := "#hcode(%P)#", h3!x
 GOTO l2
 CASE s_cdz: s0 := "#codez(%P)#"
 IF FALSE
 CASE s_cd:  s0 := "#code(%P)#"
 s1 := h2!x
 GOTO l2
 CASE s_name: x := h2!x
 IF FALSE
 CASE s_glz:
 CASE s_glg:
 CASE s_glo: wch ('.')
 x := h1!x
 CASE s_string:
 prs (x, wch)
 RESULTIS a
 CASE s_gensy:
 s0, s1 := "#G%N", h2!x-y0
 l2:            writef (s0, s1)
 RESULTIS a
 CASE s_clos:
 CASE s_aclos:
 CASE s_clos2:
 CASE s_eclos:
 CASE s_fclos:
 s0 := "#fn#"
 GOTO l1
 CASE s_jclos:
 s0 := "#jfn#"
 GOTO l1
 CASE s_kclos:
 s0 := "#kfn#"
 GOTO l1
 CASE s_e: s0 := "#env#"
 GOTO l1
 CASE s_j: s0 := "#jval#"
 l1:            writes (s0)
 RESULTIS a
 }
 } REPEAT
 }
 
 
AND prs (s, f) BE
 IF s>0 & !s=s_string
 { FOR i=str1 TO str2
 { LET b = getbyte (s, i)
 IF b=0
 RETURN
 f (b) }
 s := h1!s } REPEATUNTIL s=z
 
 
AND prins (s) BE
 prs (s, wch)
 
 
AND prins1 (s, c) BE
 { wch (c)
 prs (s, wch1)
 wch (c) }
 
 
AND prch (c) = VALOF
 { wch (c-y0)
 RESULTIS c }
 
 
AND prnum (p) BE
 { LET f, q = writen, z
 IF p>=ysg
 wch ('-')
 { LET t = h1!p
 IF t=z
 BREAK
 h1!p := q
 q, p := p, t } REPEAT
 UNLESS h2!p=0
 { writen (h2!p)
 f := writel }
 f (h3!p, numwi)
 UNTIL q=z
 { { LET t = h1!q
 h1!q := p
 p, q := q, t }
 writel (h2!p, numwi)
 writel (h3!p, numwi) }
 }
 
 
AND prfpl (n) BE
 { LET e, l = h2!n, h3!n
 msg1 (26, "prfpl") }
 
 
AND prinpoly (p, f, b, c) BE    // F -> minus pending
 { IF p<=0
 { TEST f
 writen (y0-p)
 ELSE writen (p-y0)
 RETURN }
 TEST !p=s_ratp
 { IF b
 wch ('(')
 prinpoly (h2!p, f, TRUE, FALSE)
 wch ('/')
 prinpoly (h1!p, FALSE, TRUE, FALSE) }
 ELSE TEST !p=s_poly
 { LET a, s0, s1 = h2!p, zero, "- " | signbit  // ??B??
 f := f NEQV (p>=ysg)
 p := h1!p
 TEST h1!p=z
 b := FALSE
 ELSE IF b
 wch ('(')
 { LET p2, y = h2!p, h3!p>y0
 TEST c
 s0, s1 := " + " | signbit, " - " | signbit    // ??B??
 ELSE c := TRUE
 f := f NEQV (p>=ysg)
 TEST p2<=0
 TEST p2<y0
 { writes (f -> s0, s1)
 TEST p2=ym & y
 GOTO l
 ELSE writen (y0-p2) }
 ELSE { writes (f -> s1, s0)
 TEST p2=y1 & y
 GOTO l
 ELSE writen (p2-y0) }
 ELSE TEST !p2=s_poly | !p2=s_ratp
 TEST y
 TEST h1!(h1!p2)=z  // -> P2 is poly
 prinpoly (p2, f, FALSE, s0~=zero)
 ELSE { writes (s0)
 prinpoly (p2, f, TRUE, FALSE) }
 ELSE prinpoly (p2, f, FALSE, FALSE)
 ELSE { writes (f -> s1, s0)       // ??P?? Not yet got right
 prc (p2, 30+y0) }
 IF y
 { wch ('**')
 l:       prc (a, 50+y0)
 UNLESS h3!p=y1
 { wch ('^')
 writen (h3!p-y0) } }
 p := h1!p
 } REPEATUNTIL p=z
 }
 ELSE { IF b
 wch ('(')
 IF f
 wch ('-')        // ??P?? This is wrong too
 prc (p,y0) }
 IF b
 wch (')')
 }
 
 
AND pcode (a) BE
 { kk, nn := 0, signbit
 pcode1 (a)
 UNTIL kk=0
 { LET t = !kk & p_addr
 !kk := s_cd
 kk := t } }
 
 
AND pcode1 (a) BE
 { ztab (20)
 wch ('#')
 { LET a0, a2, a3 = !a, h2!a, h3!a
 UNLESS a0=s_cd
 { IF a0>0
 { msg0 (3, a0)
 RETURN }
 writef (" ...%N", (a0 & p_tagp)>>24)
 RETURN }
 IF a3=ll_zc
 { wch ('Q')
 RETURN }
 nn := nn+(p_addr+1)
 !a := nn+(kk & p_addr)
 kk := a
 FOR i=@ll_zc TO @ll_zc+ocmsz
 IF a3=!i
 { s0 := i-@ll_zc+ocm
 GOTO l0 }
 writearg (a3)
 GOTO l1
 l0: FOR i=0 TO 3
 wch (getbyte (s0, i))
 wch (' ')
 TEST a2>0 & (!a2=s_cd | !a2<0)
 { wch ('(')
 pcode1 (a2)
 wch (')') }
 ELSE prin (a2)   // ?P FOR NOW
 }
 l1:  a := h1!a
 } REPEATUNTIL a=z
 
 
AND princlo (a) BE
 { prin (a)
 { wch (' ')
 prinbv (h2!a)
 a := h3!a } REPEATWHILE tyv (a)=a_fclos
 writes (" . ")
 prc (a, y2) }
 
 
AND prinbv (a) BE
 TEST a>0 & !a=s_tuple
 prinpars (print0, a, prinbv)
 ELSE prc (a, 9+y0)
 
 
AND prinl (l) = VALOF
 { IF l>0
 { IF !l=s_tuple
 { LET p, c = l, '('+signbit
 IF @l>stackl
 writes ("#etc#") <> RESULTIS l
 { wch (c)
 c := '*S'+signbit
 prinl (h2!p)
 p := h1!p } REPEATUNTIL p=z
 wch (')')
 RESULTIS l }
 IF l>=yloc | !l=s_xtupl
 l := h1!l <> LOOP
 }
 RESULTIS print (l)
 } REPEAT
 
 
// H3 := +ve; EVAL of such tuples is undefined, but should be safe
 
 
AND print0 (p, f) BE    // P is a tuple
 { LET n, q = h3!p, z
 IF @p>stackl
 writes ("#etc#") <> RETURN
 { n := n-1
 IF h3!p>=0
 { writes ("#loop#")
 IF q=z
 RETURN
 BREAK }
 h3!p := q
 q, p := p, h1!p } REPEATUNTIL p=z
 { n := n+1
 f (h2!q)       // before unlinking
 p := h3!q
 h3!q := n
 IF p=z
 RETURN
 q := p
 writes (", ") } REPEAT
 }
 
 
AND print (a) = VALOF
 { IF a>0
 SWITCHON !a INTO
 {
 CASE s_loc:
 CASE s_xtupl:
 a := h1!a
 LOOP
 CASE s_tuple:
 prinpars (print0, a, print)
 RESULTIS a
 CASE s_string:
 prs (a, wch)
 RESULTIS a
 DEFAULT: prc (a, y0)
 RESULTIS a
 }
 RESULTIS prin (a)
 } REPEAT
 
 
AND prc (c, b) BE
 { IF @c>stackl
 { writes ("#etc#")
 RETURN }
 { IF c>0
 { SWITCHON !c INTO
 {
 DEFAULT: prin (c)
 CASE s_unset1:
 RETURN
 CASE s_numj: prnum (c)
 RETURN
 CASE s_ratn:
 CASE s_ratl: b := b>30+y0
 IF b
 wch ('(')
 prc (h2!c, y0)
 wch ('/')
 prc (h1!c, y0)
 ENDCASE
 CASE s_ratp:
 CASE s_poly: prinpoly (c, FALSE, b>=25+y0, FALSE)
 RETURN
 CASE s_polyj:
 writes ("#term[")
 !zu, h1!zu, h2!zu := s_poly, c, zj      // fake a poly
 prinpoly (zu, FALSE, FALSE, FALSE)
 h1!zu := z
 wch (']')
 RETURN
 CASE s_string:
 prins1 (c, '*"')
 RETURN
 CASE s_glg: apply (h1!c, h2!c)
 RETURN
 CASE s_xtupl:
 writes ("#xtuple#")
 prc (h2!c, 48+y0)
 c := h1!c
 CASE s_tuple:
 b := b>8+y0
 IF b
 wch ('(')
 { prc (h2!c, 9+y0)
 c := h1!c
 IF c=z
 ENDCASE
 writes (", ") } REPEAT
 CASE s_tra: writes ("#trace#")
 c := h2!c
 LOOP
 CASE s_loc: c := h1!c
 LOOP
 CASE s_colon:
 wch ('[')
 prin (h1!c)
 wch (':')
 prc (h3!c, y0)
 wch (']')
 c := h2!c
 LOOP
 CASE s_cdz: writef ("*N#codez %P", h2!c)
 IF FALSE
 {
 CASE s_cdx:
 CASE s_cdy:    writes ("*N#hcode# ")
 prinbv (h3!c) }
 c := h1!c
 IF FALSE
 CASE s_cd:  newline ()
 pcode (c)
 newline ()
 RETURN
 CASE s_clos:
 CASE s_aclos:
 CASE s_clos2:
 CASE s_eclos:
 CASE s_fclos:
 TEST b>y2
 prinpars (princlo, c)
 ELSE princlo (c)
 RETURN
 CASE s_rec:
 CASE s_reca: b := b>y2
 IF b
 wch ('(')
 writes ("REC ")
 prinbv (h2!c)
 c := h1!c
 WHILE tyv (c)=a_fclos
 { wch (' ')
 prinbv (h2!c)
 c := h3!c }
 writes (" . ")
 prc (c, y2)
 ENDCASE
 CASE s_let:
 CASE s_leta:
 CASE s_letb: b := b>y1
 IF b
 wch ('(')
 writes ("LET ")
 prinbv (h2!c)
 { LET c3 = h3!c
 WHILE tyv (c3)=a_fclos
 { wch (' ')
 prinbv (h2!c3)
 c3 := h3!c3 }
 writes (" = ")
 prc (c3, y1) }
 UNLESS h1!c=ze
 writes (" IN ") <> prc (h1!c, y1)
 ENDCASE
 CASE s_cond:
 CASE s_conda:
 CASE s_condb:
 b := b>10+y0
 IF b
 wch ('(')
 prc (h1!c, 10+y0)
 writes (" -> ")
 prc (h2!c, 10+y0)
 c := h3!c
 UNLESS c=z
 { writes (", ")
 prc (c, 10+y0) }
 ENDCASE
 CASE s_seq:
 CASE s_seqa: { LET p = y2
 TEST b>9+y0
 b := TRUE
 ELSE { IF b>y2
 p := 9+y0
 b := FALSE }
 IF b
 wch ('(')
 prc (h1!c, p+1)
 writes (p=y2 -> "; ", " <> ")
 prc (h2!c, p)
 ENDCASE
 }
 CASE s_e: wch ('E')
 RETURN
 CASE s_j: wch ('J')
 RETURN
 CASE s_retu: b := b>35+y0
 IF b
 wch ('(')
 prins (h1!tyv (c))
 wch (' ')
 prc (h2!c, 35+y0)
 ENDCASE
 CASE s_qu:
 CASE s_aa:
 CASE s_zz: b := b>35+y0
 IF b
 wch ('(')
 prins (h1!tyv (c))
 prc (h2!c, 35+y0)
 ENDCASE
 CASE s_aa2:
 CASE s_a2a:
 CASE s_ap2:
 CASE s_a2e: { LET c1, s = h2!c, h1!c
 IF h3!s<0
 { s0 := getbyte (s, 12) & 127    // IF S0=0, probably FOR
 b := b>(s0 & 63)+y0
 IF b
 wch ('(')
 { LET b1 = s0>63 | s0<6
 prc (h2!c1, getbyte (s, 13)+y0)
 (b1 -> prins1, prins)(h1!s, ' ')
 prc (h2!(h1!c1), getbyte (s, 14)+y0)
 ENDCASE } }
 b := b>10+y0
 IF b
 wch ('(')
 prc (h2!c1, 11+y0)
 writes (" %")
 prc (s, 50+y0)       // ??C??
 wch (' ')
 prc (h2!(h1!c1), 11+y0)
 ENDCASE
 }
 CASE s_apz:
 CASE s_apply:
 CASE s_apple:
 CASE s_aa1:
 CASE s_a1a:
 CASE s_ap1:
 CASE s_a1e:
 CASE s_apv:
 CASE s_ave:
 CASE s_aaa:
 CASE s_aea:
 CASE s_apq:
 CASE s_aqe: b := b>38+y0
 IF b
 wch ('(')
 prc (h1!c, 38+y0)
 wch (' ')
 prc (h2!c, 41+y0)
 ENDCASE
 CASE s_dash: b := b>39+y0
 IF b DO
 wch ('(')
 prc (h1!c, 36+y0)
 FOR i=y1 TO h2!c
 wch ('*'')
 ENDCASE
 }
 IF b
 wch (')')
 RETURN
 }
 prin (c)
 RETURN
 } REPEAT
 }
 
 
AND printa (c) = VALOF
 prc (c, y0) <> RESULTIS c
 
 
.
//./       ADD LIST=ALL,NAME=PALM2
 SECTION "PALM2"
 
 
GET "pal75hdr"
 
 
LET prink (f, p, n) = VALOF
 { STATIC
 { g = 0 }
 LET w0 (c) BE
 g := g-1
 LET w1, w2 = -wrc, -chc
 wrc := w0
 g := g_posint (n)
// WE MUST DO THE WHOLE LOT WITHOUT LONGJUMP, BECAUSE SOME
// PRINT ROUTINES MANGLE STRUCTURE
 f (p)
 wrc, chc := -w1, -w2
 TEST g>=y0
 f (p) <> RESULTIS TRUE
 ELSE RESULTIS FALSE
 }
 
 
AND prine (e) = VALOF
 { IF e>0 & !e=s_e
 { LET f = print
 UNLESS paramc
 f := prin
 writes ("*N*N environment:")
 IF e=ze
 { writes (" empty*N")
 RESULTIS e }
 FOR i=y0 TO y0+8
 { IF e=ze
 BREAK
 writef ("*N%P%Z", h3!e, 15)
 f (h2!e)
 e := h1!e }
 writes (e=ze -> "*N end of environment*N", "*N etc*N")
 }
 RESULTIS e
 }
 
 
AND prinj (j) = VALOF   // ??C??
 { writes ("*N*N Pal backtrace:")
 UNLESS tyv (j)=zj & j~=zj
 { writes (" empty*N")
 RESULTIS z }
 FOR i=y0 TO y0+8
 { UNLESS tyv (j)=zj & j~=zj
 GOTO l
 prine (h1!j)
 { LET k = h3!j
 IF tyv (k)=zj
 prind (k) }
 j := h2!j }
 writes ("*N etc")
 l:   writes ("*N end of backtrace*N")
 RESULTIS j
 }
 
 
AND prind (f) = VALOF
 { LET g = printa
 UNLESS paramc
 g := prin
 writes ("*N stack frame:")
 FOR i=y0 TO y0+8
 { UNLESS tyv (f)=zj
 GOTO n
 writef ("*N cell %E%Zand %E", g, h3!f, 15, g, h2!f)
 f := h1!f }
 writes ("*N etc")
 n: writes ("*N end of frame*N")
 }
 
 
AND show (a) = VALOF
 TEST !((-2)!(@a)>>2)=eval
 { gw0, gw1, gw2 := show1, a, a
 longjump (flevel (eval), ll_ex) }
 ELSE { LET b = eval (a)
 RESULTIS show1 (b, a) }
 
 
AND show1 (a, f) = VALOF
 { writef ("*N*N%E%Y%E", printa, f, 15, print, a)
 RESULTIS a }
 
 
.
//./       ADD LIST=ALL,NAME=PALM3
 SECTION "PALM3"
 
 
GET "pal75hdr"
 
 
STATIC
 { c0 = 0 }
 
 
LET linkword (n, a, a2, a3) = VALOF
 { LET g = @root | signbit   // ??B??
 n, c0 := -n, 0
 UNTIL c0!g=z
 g, c0 := c0!g, compl (a, h1!(h2!g))+2 <>
 IF c0=2
 RESULTIS g  // found
 a := get4 (-n, a, a2, a3)
 c0!g := get4 (s_name, z, a, z)
 RESULTIS c0!g }
 
 
AND findword (a) = VALOF
 { LET g = @root | signbit   // ??B??
 c0 := 0
 UNTIL c0!g=z
 g, c0 := c0!g, compl (a, h1!(h2!g))+2 <>
 IF c0=2
 RESULTIS g
 RESULTIS 0 }
 
 
AND putword (b) = VALOF
 { LET a, g = h1!b, @root | signbit  // ??B??
 c0 := 0
 UNTIL c0!g=z
 g, c0 := c0!g, compl (a, h1!(h2!g))+2 <>
 IF c0=2
 msg1 (13, putword)
 c0!g := get4 (s_name, z, b, z)
 RESULTIS c0!g }
 
 
AND stov (s, v, m) = VALOF
 { LET s1, n = s, 0
 IF s1>0 & !s1=s_string
 { FOR i=str1 TO str2
 { LET b = getbyte (s1, i)
 IF b=0
 GOTO l
 IF n>=m
 msg1 (5, s) <> GOTO l
 n := n+1
 v!n := b }
 s1 := h1!s1 } REPEATUNTIL s1=z
 l: !v := n
 RESULTIS v
 }
 
 
AND ttov (a, v, m) = VALOF
 { LET a1 = a
 !v := 0
 IF a1>0 & !a1=s_tuple
 { LET l = h3!a1-y0
 IF l>m
 msg1 (5, a) <> RESULTIS v
 FOR i=l TO 1 BY -1
 v!i := rvv (h2!a1) <> a1 := h1!a1
 !v := l }
 RESULTIS v
 }
 
 
AND compl (a, b) = VALOF        // A<B -> -1, A=B -> 0, A>B -> 1
 { TEST h2!a<h2!b
 RESULTIS -1
 ELSE UNLESS h2!a=h2!b
 RESULTIS 1
 TEST h3!a<h3!b
 RESULTIS -1
 ELSE UNLESS h3!a=h3!b
 RESULTIS 1
 a, b := h1!a, h1!b
 IF a=b
 RESULTIS 0
 IF a=z
 RESULTIS -1
 IF b=z
 RESULTIS 1
 } REPEAT
 
 
.
//./       ADD LIST=ALL,NAME=PALM4
 SECTION "PALM4"
 
 
GET "pal75hdr"
 
 
LET sel1 (a) = h1!a
 
 
AND sel2 (a) = h2!a
 
 
AND g_posint (n) = VALOF
 { MANIFEST
 { yz = y0+numba }
 IF y0<n<yz
 RESULTIS n
 IF n>=yloc
 n := h1!n <> LOOP
 msg1 (29, n) } REPEAT
 
 
AND g_np (a, t) = VALOF
 { UNLESS a>0 & !a=t
 { IF a>=yloc
 a := h1!a <> LOOP
 msg1 (22, a) }
 RESULTIS a } REPEAT
 
 
AND g_nt (a, n) = VALOF
 { UNLESS a>0 & !a=s_tuple & h3!a=n
 { IF a>=yloc | a>0 & !a=s_xtupl
 a := h1!a <> LOOP
 msg1 (28, a, n) }
 RESULTIS a } REPEAT
 
 
AND lvv (p) = p>=yloc -> p, get4 (s_loc, p, 0, 0)+yloc
 
 
AND rvv (p) = p>=yloc -> h1!p, p
 
 
LET tyv (p) = VALOF
 { IF p>0
 RESULTIS typ!!p
 IF p>=-1
 RESULTIS p
 RESULTIS a_num }
 
 
AND hdv (p) = VALOF
 { IF p>0 & !p>=mm3
 RESULTIS h2!p
 RESULTIS z }
 
 
AND miv (p) = VALOF
 { IF p>0 & !p>=mm3
 RESULTIS h3!p
 RESULTIS z }
 
 
AND tlv (p) = VALOF
 { IF p>0
 RESULTIS h1!p
 RESULTIS z }
 
 
AND null (p) = p=z
 
 
AND iv (a) = a
 
 
AND order (p) = VALOF
 { IF p<=0
 TEST p=z
 RESULTIS y0
 ELSE RESULTIS y1
 IF !p=s_tuple
 RESULTIS h3!p
 RESULTIS y1 }
 
 
AND lmap (f, a) = VALOF
 { f := f | signbit
 { f (h2!a)
 a := h1!a } REPEATUNTIL a=z
 RESULTIS z }
 
 
AND lmapl (f, a) = VALOF
 { LET q = z
 f := f | signbit
 { LET t = f (h2!a)
 q := aug (q, t)
 a := h1!a } REPEATUNTIL a=z
 RESULTIS q }
 
 
AND lmapt (f, n) = VALOF
 { LET m, q = y1, z
 UNTIL m>n
 { LET t = apply (f, m)
 q := aug (q, t)
 m := m+1 }
 RESULTIS q }
 
 
AND dofor (v, p) = VALOF        // ?-
 { UNLESS v>0 & !v=s_tuple
 RESULTIS apply (p, v)
 { LET i, w = y1, h2!v
 TEST h3!v=y3
 { v := h1!v
 i := h2!v }
 ELSE UNLESS h3!v=y2
 msg1 (16, dofor, v)
 v := h2!(h1!v)
 { LET f = positive (i)
 UNTIL f -> gtv (v, w), gtv (w, v)
 { apply (p, v)
 v := add (i, v) } }
 RESULTIS z
 }
 }
 
 
AND aug (p, q) = VALOF
 { IF p<=0
 { IF p=z
 RESULTIS get4 (s_tuple, z, q, y1)
 GOTO l }
 IF !p=s_tuple
 RESULTIS get4 (s_tuple, p, q, h3!p+1)
 IF p>=yloc | !p=s_xtupl
 { p := h1!p
 LOOP }
 IF p=zsy
 RESULTIS get4 (s_tuple, p, q, y1)
 l:   msg1 (24, p)
 RESULTIS z
 } REPEAT
 
 
AND isv (p, q) = p=q
 
 
AND assg (p, q) = VALOF
 { IF q>=yloc
 q := h1!q
 IF p>=yloc
 { h1!p := q
 RESULTIS p }
 IF p>0 & !p=s_tuple
 { UNLESS q>0 & !q=s_tuple & h3!q=h3!p
 msg1 (6, p, q)
 { LET n = h3!q
 { LET t = q
 { h3!t := rvv (h2!t)
 t := h1!t } REPEATUNTIL t=z }
 FOR i=n TO y1 BY -1
 { assg (h2!p, h3!q)
 h3!q := i
 p, q := h1!p, h1!q }
 RESULTIS z }
 }
 msg1 (12, p, q)
 }
 
 
AND rev (p) = VALOF
 { IF p>0 & !p=s_tuple
 { LET q, l = z, y1
 q, l, p := get4 (s_tuple, q, h2!p, l), l+1, h1!p REPEATUNTIL p=z
 RESULTIS q }
 RESULTIS z }
 
 
AND revd (p) = VALOF    // Destructive reverse: P is a tuple
 { LET q, l = z, y1
 { LET t = h1!p
 h1!p, h3!p := q, l
 IF t=zsy
 RESULTIS p
 q, p := p, t
 l := l+1 } REPEAT }
 
 
LET getv (s) = g_get (findinput, s, zero)
 
 
AND getmv (s1, s2) = g_get (inputmember, s1, s2)
 
 
AND g_get (r, s1, s2) = VALOF
 { r := stream (r, s1, s2)
 UNLESS r=y0
 { s1, s2 := -q_input, -rch
 q_selinput (r-y0)
 rch := rch0
 rp ()
 q_selinput (-s1)
 rch := -s2
 IF rch=rch1
 wch (' ') }
 RESULTIS zsc
 }
 
 
AND getex (s) = VALOF
 { s := stream (findinput, s, zero)
 UNLESS s=y0
 { LET s1, s2 = -q_input, -rch
 q_selinput (s-y0)
 rch := rch0
 s := readx ()
 q_selinput (-s1)
 rch := -s2
 IF rch=rch1
 wch (' ') }
 RESULTIS s
 }
 
 
AND xtuple (p) = get4 (s_xtupl, z, p, y0)
 
 
AND find (n, e) = VALOF
 { e := g_np (e, s_e)
 IF n>=yloc
 n := h1!n
 { IF eqlv (h3!e, n)
 RESULTIS h2!e
 e := h1!e } REPEATUNTIL e=z
 RESULTIS z }
 
 
AND put (n, v, e) = VALOF
 { UNLESS e>=yloc & g_np (e, s_e)~=z
 { msg1 (16, put, e)
 RESULTIS z }
 h1!e := get4 (s_e, h1!e, v, n)
 RESULTIS v }
 
 
.
//./       ADD LIST=ALL,NAME=PALM5
 SECTION "PALM5"
 
 
GET "pal75hdr"
 
 
STATIC
 { v = 0 }
 
 
LET code (n) = VALOF    // ??C??
 { LET f = (@g0)!(n-y0)
 LET g = (f & p_addr)>>2
 UNLESS validentry (g)
 msg1 (17, code, n)
 { LET s = nargs (g)
 TEST s>4
 s := s_code4
 ELSE s := s_code0+s
 RESULTIS get4 (s, 0, f | signbit, f<0) } }
 
 
AND bcplf (n) = VALOF
 { LET f = (@g0)!(n-y0)
 RESULTIS get4 (s_bcplf, 0, f | signbit, f<0) }
 
 
AND bcplr (n) = VALOF
 { LET f = (@g0)!(n-y0)
 RESULTIS get4 (s_bcplr, 0, f | signbit, f<0) }
 
 
AND bcplv (n) = VALOF
 { LET f = (@g0)!(n-y0)
 RESULTIS get4 (s_bcplv, 0, f | signbit, f<0) }
 
 
AND callbcpl (f) = VALOF
 { v := buffp
 TEST h3!f
 f := h2!f
 ELSE f := h2!f & p_addr
 v := transbcpl (arg1, buffp+buffl)
 UNLESS arg1>0 & !arg1=s_tuple
 RESULTIS f (v)
 FOR i=5 TO !buffp
 (@f+fr_callbcpl)!i := buffp!i
 RESULTIS f (buffp!1, buffp!2, buffp!3, buffp!4)
 }
 
 
AND transbcpl (a, n) = VALOF
 { IF a<=0
 { IF ABS (a-y0)<numba
 RESULTIS a-y0
 RESULTIS a }
 SWITCHON !a INTO
 {
 CASE s_xtupl:
 CASE s_loc: a := h1!a
 LOOP
 DEFAULT: RESULTIS a
 CASE s_rds:
 CASE s_wrs: RESULTIS h2!a-y0
 CASE s_flt:
 CASE s_codev:
 CASE s_code0:
 CASE s_code1:
 CASE s_code2:
 CASE s_code3:
 CASE s_code4:
 CASE s_bcplf:
 CASE s_bcplr:
 CASE s_bcplv:
 CASE s_qu: RESULTIS h2!a
 CASE s_numj: IF h1!a=z
 { LET t = h2!a*numba
 IF t/numba=h2!a
 { t := t+h3!a
 IF t>=numba | t=signbit
 TEST a<ysg
 RESULTIS t
 ELSE RESULTIS -t } }
 msg1 (37, a)
 CASE s_string:
 { LET u = v
 LET l = packstring (stov (a, u, n-u), u)
 v := u+l+1
 RESULTIS u }
 CASE s_tuple:
 { LET u, l = v, h3!a-y0
 IF @l>stackl
 stkover ()
 IF u+l>n
 msg1 (5, a) <> l := n-u
 v := u+l+1
 FOR i=l TO 1 BY -1
 u!i := transbcpl (h2!a, n) <>
 a := h1!a
 !u := l
 RESULTIS u
 }} REPEAT
} 
 
AND transpal (a) = VALOF
 { IF a=signbit
 { a := transpal (signbit/2)
 RESULTIS add (a, a) }
 IF ABS a<numba
 RESULTIS a+y0
 TEST a<0
 a, v := -a, ysg
 ELSE v := 0
 RESULTIS getx (s_numj, z, a/numba, a REM numba)+v }
 
 
LET tempus (a) = VALOF
 { writef ("*N*N# Tempus fugit (%P) after %V+%V s*N*N",
 a, time ()-rtime, rtime)
 RESULTIS a }
 
 
AND error (a) = VALOF
 { writes ("*N*N# Error: ")
 print (a)
 msg1 (0)
 RESULTIS z }
 
 
AND errorset (s) = VALOF
 { erz := s
 RESULTIS s }
 
 
AND num (a) = VALOF
 { IF a<-1
 RESULTIS TRUE
 RESULTIS tyv (a)=a_num }
 
 
AND rat (a) = VALOF
 { IF a<=0
 RESULTIS FALSE
 IF s_ratn<=!a<=s_ratp
 RESULTIS TRUE
 RESULTIS FALSE }
 
 
AND mainvar(a) = VALOF { UNLESS arithv(a)
 msg1(16,mainvar,a)
 IF a<=0 RESULTIS z
 IF !a=s_ratp
 a := h1!a
 IF !a=s_poly RESULTIS h2!a
 RESULTIS z }
 
AND atom (a) = VALOF
 { IF a<=0
 RESULTIS TRUE
 RESULTIS !a<=s_glo }
 
 
AND tuple (a) = VALOF
 { IF a<=0
 RESULTIS a=z   // ??Z??
 RESULTIS !a=s_tuple }
 
 
AND function (a) = VALOF
 { IF a<=0
 RESULTIS FALSE
 IF s_clos<=!a<=s_kclos
 RESULTIS TRUE
 RESULTIS FALSE }
 
 
AND syn (a) = VALOF
 { IF a<=0
 RESULTIS FALSE
 IF s_rec<=!a<=s_zz
 RESULTIS TRUE
 RESULTIS FALSE }
 
 
STATIC
 { c0 = 0
 c1 = 0
 c2 = 0 }
 
 
LET number (v) = VALOF
 { MANIFEST
 { nw2 = 2*numwi }
 STATIC
 { n = 0
 m = 0 }
 c0, v := v & p_addr, z
 c2 := c0+!c0
 { IF c0>=c2
 RESULTIS y0
 c0 := c0+1 } REPEATWHILE !c0='0'
 c1 := c0+(c2-c0+1) REM nw2
 UNLESS c0=c1
 { n, m := 0, 0
 UNTIL c0>=c1-numwi
 n := n*10+!c0-'0' <> c0 := c0+1
 UNTIL c0=c1
 m := m*10+!c0-'0' <> c0 := c0+1
 IF c0>c2 & n=0
 RESULTIS m+y0
 v := getx (s_numj, z, n, m) }
 UNTIL c0>c2
 { n, m := 0, 0
 c1 := c0+numwi
 UNTIL c0=c1
 n := n*10+!c0-'0' <> c0 := c0+1
 c1 := c0+numwi
 UNTIL c0=c1
 m := m*10+!c0-'0' <> c0 := c0+1
 v := getx (s_numj, v, n, m) }
 RESULTIS v
 }
 
 
AND string (v) = VALOF
 { LET g = zs
 LET gg = @v | signbit     // ??B?? GG=@G-1
 c1 := maxint
 FOR i=signbit+1 TO signbit+!v
 { IF c1>str2
 c1, h1!gg, gg := str1, getx (s_string, zsy, 0, 0), h1!gg
 putbyte (gg, c1, v!i)
 c1 := c1+1 }
 UNLESS g=zs
 h1!gg := z
 RESULTIS g
 }
 
 
AND name (a) = VALOF
 { IF a>0 & !a=s_string
 RESULTIS linkword (s_glz, a, zsy, z)
 msg1 (16, name, a)
 RESULTIS z }
 
 
AND gensym () = VALOF
 { gensymn := gensymn+1
 RESULTIS get4 (s_gensy, 0, gensymn, 0) }
 
 
AND asym (n) = get4 (s_gensy, 0, n, 0)
 
 
AND globa (a) = h2!name (a)
 
 
AND genglo (n, v) = VALOF
 { IF n<0
 msg1 (16, genglo, n)
 RESULTIS get4 (s_glg, n, v, z) }
 
 
.
//./       ADD LIST=ALL,NAME=PALM6
 SECTION "PALM6"
 
 
GET "pal75hdr"
 
 
MANIFEST
 { ny0 = -y0 }
 
 
STATIC
 { ga1 = 0
 ga2 = 0
 ga3 = 0
 ga4 = 0 }
 
// RATN:   A | (B>0)
 
 
LET neg (p) = VALOF
 { IF p<=0
 { IF p>=-1
 TEST p=0
 RESULTIS y0
 ELSE RESULTIS ym
 RESULTIS signbit-p }
 SWITCHON !p INTO
 {
 CASE s_loc: p := h1!p
 LOOP
 CASE s_fpl: msg1 (14)
 CASE s_numj:
 CASE s_poly: RESULTIS p NEQV ysg
 CASE s_ratn: RESULTIS get4 (s_ratn, h1!p, signbit-h2!p, 0)
 CASE s_ratl:
 CASE s_ratp: { LET t = neg (h2!p)
 RESULTIS get4 (!p, h1!p, t, h3!p) }
 CASE s_flt: RESULTIS getx (s_flt, 0,  #- h2!p, 0)
 DEFAULT: RESULTIS arithfn (y0, p, a_minu)
 }
 } REPEAT
 
 
AND positive (p) = VALOF
 { IF p<=0
 RESULTIS p>=y0
 SWITCHON !p INTO
 {
 CASE s_loc: p := h1!p
 LOOP
 CASE s_fpl: msg1 (14)
 CASE s_ratn: RESULTIS h2!p>=y0
 CASE s_numj: RESULTIS p<ysg
 CASE s_ratl: p := h2!p
 LOOP
 CASE s_flt: RESULTIS h2!p #>= 0.0
 DEFAULT: msg1 (16, positive, p)
 RESULTIS z
 }
 } REPEAT
 
 
AND recip (p) = VALOF
 { IF p<=0
 { IF p>=-1
 TEST p=0
 p := y0
 ELSE RESULTIS y1
 IF p<=y0
 { IF p=y0
 msg1 (7) <> RESULTIS z
 IF p=ym
 RESULTIS ym
 RESULTIS get4 (s_ratn, signbit-p, ym, 0) }
 IF p=y1
 RESULTIS y1
 RESULTIS get4 (s_ratn, p, y1, 0)
 }
 SWITCHON !p INTO
 {
 CASE s_loc: p := h1!p
 LOOP
 CASE s_fpl: msg1 (14)
 CASE s_numj: IF p<ysg
 RESULTIS get4 (s_ratl, p, y1, 0)
 RESULTIS get4 (s_ratl, p NEQV ysg, ym, 0)
 CASE s_ratn: { LET q = h2!p
 TEST q>y0
 p := h1!p
 ELSE q, p := signbit-q, signbit-h1!p
 IF q=y1
 RESULTIS p
 RESULTIS get4 (s_ratn, q, p, 0) }
 CASE s_ratl: { LET q = h2!p
 TEST positive (q)
 p := h1!p
 ELSE { q := neg (q)
 p := neg (h1!p) }
 IF q=y1
 RESULTIS p
 RESULTIS get4 (s_ratl, q, p, 0) }
 CASE s_ratp: RESULTIS div (h1!p, h2!p)
 CASE s_poly: p := monicpoly (p)
 { LET q = recip (lcoef)
 RESULTIS get4 (s_ratp, p, q, h3!p) }
 CASE s_flt: IF h2!p #= 0.0
 msg1 (7)
 RESULTIS getx (s_flt, 0, 1.0 #/ h2!p, 0)
 DEFAULT: RESULTIS arithfn (y1, p, a_div)
 }
 } REPEAT
 
 
AND gcda (a, b) = VALOF
 SWITCHON coerce (@a, TRUE) INTO
 {
 CASE s_num: RESULTIS igcd (a+ny0, b+ny0)+y0
 CASE s_numj: IF numarg
 RESULTIS gcd1 (b, a)+y0
 RESULTIS lgcd (a, b)
 CASE s_poly: IF worse
 { IF a=y0
 RESULTIS b
 RESULTIS y1 }
 a := polygcd (a, b)
 TEST a=y1 | lcoef=y1
 RESULTIS a
 ELSE RESULTIS monicpoly (a)   // or DIV (A, LCOEF)
 DEFAULT: msg1 (23, a, b)
 }
 
 
AND fixv (p) = VALOF
 { IF p<=0
 { IF p>=-1
 TEST p=0
 RESULTIS y0
 ELSE RESULTIS y1
 RESULTIS p }
 SWITCHON !p INTO
 {
 CASE s_loc: p := h1!p
 LOOP
 CASE s_flt: RESULTIS sadd (FIX (h2!p))
 CASE s_fpl: msg1 (14)
 CASE s_ratn: RESULTIS (h2!p+ny0)/(h1!p+ny0)+y0
 CASE s_ratl: { LET f, q = longdiv, h1!p
 IF q<=0
 f := longdiv1
 RESULTIS f (h2!p, q) }
 CASE s_ratp: RESULTIS divpoly (h2!p, h1!p)
 DEFAULT: RESULTIS p
 }
 } REPEAT
 
 
AND floatv (p) = VALOF
 { IF p<=0
 { IF p>=-1
 TEST p=0
 p := y0
 ELSE p := y1
 RESULTIS getx (s_flt, 0, FLOAT (p+ny0), 0) }
 SWITCHON !p INTO
 {
 CASE s_loc: p := h1!p
 LOOP
 CASE s_flt:
 CASE s_fpl: RESULTIS p
 CASE s_numj: msg1 (14)
 CASE s_ratn: RESULTIS getx (s_flt, 0, FLOAT (h2!p+ny0) #/ FLOAT (h1!p+ny0), 0)
 CASE s_ratl: msg1 (14)
 DEFAULT: msg1 (16, floatv, p)
 RESULTIS z
 }
 } REPEAT
 
 
AND absv (p) = VALOF
 { IF positive (p)
 RESULTIS p
 RESULTIS neg (p) }
 
 
LET igcd (a, b) = VALOF
 { UNTIL b=0
 { LET r = a REM b
 a, b := b, r }
 RESULTIS ABS a }
 
 
AND gcd1 (a, n) = VALOF
 { IF n=y0
 RESULTIS a
 longdiv1 (a, n)
 RESULTIS igcd (n+ny0, result2) }
 
 
.
//./       ADD LIST=ALL,NAME=PALM7
 SECTION "PALM7"
 
 
GET "pal75hdr"
 
 
LET lookup (a) = VALOF
 { LET ee = e        // Possibly now EE=ZE, but not EE=Z
 { IF a=h3!ee
 RESULTIS h2!ee
 ee := h1!ee } REPEATUNTIL ee=z
 msg1 (15, a)
 RESULTIS a }
 
 
AND bind (v, w, k) = VALOF
 { IF v>0
 SWITCHON !v INTO
 {
 CASE s_loc: v := h1!v
 LOOP
 CASE s_tuple:
 UNTIL w>0 & !w=s_tuple & h3!v=h3!w
 { IF w>=yloc
 w := h1!w <> LOOP
 IF order (w)=y1
 w := lmapt (w, h3!v) <>
 LOOP
 msg1 (6, v, w) }
 IF @w>stackl
 RESULTIS bind1 (v, w, k)
 { k := bind (h2!v, h2!w, k)
 v := h1!v
 IF v=z
 RESULTIS k
 w := h1!w } REPEAT
 CASE s_qu: w := get4 (s_clos, e, z, w) // But bad scene if W is CD? Maybe OK
 v := h2!v
 LOOP
 CASE s_aa: UNLESS w>=yloc
 w := get4 (s_loc, w, 0, 0)+yloc
 v := h2!v
 LOOP
 CASE s_zz: IF w>=yloc
 w := h1!w
 v := h2!v
 LOOP
 CASE s_gensy:
 CASE s_name:
 CASE s_dash: RESULTIS get4 (s_e, k, w, v)
 CASE s_glg:
 CASE s_glo: h2!v := w
 RESULTIS k
 CASE s_glz: !v := s_glo
 h2!v := w
 fixap (h3!v)
 h3!v := z
 RESULTIS k
 }
 UNLESS v=z        // ??Z??
 msg1 (11, v, w)
 RESULTIS k
 } REPEAT
 
 
AND bind1 (v, w, k) = VALOF
 { LET f = z
 { TEST v>0
 SWITCHON !v INTO
 {
 CASE s_loc: v := h1!v
 LOOP
 CASE s_tuple:
 UNTIL w>0 & !w=s_tuple & h3!v=h3!w
 { IF w>=yloc
 w := h1!w <> LOOP
 IF order (w)=y1
 w := lmapt (w, h3!v) <>
 LOOP
 msg1 (6, v, w) }
 f := get4 (s_mb, f, h1!v, h1!w)+yfj
 v, w := h2!v, h2!w
 LOOP
 CASE s_qu: w := get4 (s_clos, e, z, w)      // ??C??
 v := h2!v
 LOOP
 CASE s_aa: UNLESS w>=yloc
 w := get4 (s_loc, w, 0, 0)+yloc
 v := h2!v
 LOOP
 CASE s_zz: IF w>=yloc
 w := h1!w
 v := h2!v
 LOOP
 CASE s_gensy:
 CASE s_name:
 CASE s_dash: k := get4 (s_e, k, w, v)
 ENDCASE
 CASE s_glg:
 CASE s_glo: h2!v := w
 ENDCASE
 CASE s_glz: !v := s_glo
 h2!v := w
 fixap (h3!v)
 h3!v := z
 ENDCASE
 l:       DEFAULT: msg1 (11, v, w)
 }
 ELSE UNLESS v=z  // ??Z??
 GOTO l
 { IF f=z
 RESULTIS k
 { LET f2 = h2!f
 UNLESS f2=z
 { LET f3 = h3!f
 v, w, h2!f, h3!f := h2!f2, h2!f3, h1!f2, h1!f3
 BREAK } }
 !f, stackp := stackp, f
 f := h1!f } REPEAT
 } REPEAT
 }
 
 
AND binda (v, w, k) = VALOF
 { k := get4 (s_e, k, h2!w, h2!v)
 v := h1!v
 IF v=z
 RESULTIS k
 w := h1!w } REPEAT
 
 
AND bindr (v, w) BE
 RETURN
 
// There are bizarre possibilities about REC 'F . ...
 
 
AND dorec (a, b) = VALOF
 { LET e1 = e
 e := h1!e
 { LET e2 = bind (b, a, e)
 h1!e1, h2!e1, h3!e1 := h1!e2, h2!e2, h3!e2 }
 RESULTIS a }
 
 
AND doreca (a) = VALOF
 { h2!e := a
 e := h1!e
 RESULTIS a }
 
 
.
//./       ADD LIST=ALL,NAME=PALM8
 SECTION "PALM8"
 
 
GET "pal75hdr"
 
 
LET trace (a, b) = VALOF
 { LET f = a
 { IF a>0
 SWITCHON !a INTO
 {
 CASE s_gensy:
 CASE s_name: a := lookup (a)
 LOOP
 CASE s_glz:
 CASE s_glg:
 CASE s_glo: a := h2!a
 LOOP
 CASE s_clos:
 CASE s_aclos:
 CASE s_clos2:
 CASE s_eclos:
 CASE s_fclos:
 h3!a := get4 (s_tra, f, h3!a, b)
 RESULTIS a
 }
 msg1 (16, trace, a)
 } REPEAT
 }
 
 
AND untrace (a) = VALOF
 { IF a>0
 { { LET a3 = h3!a
 IF a3>0 & !a3=s_tra
 { h3!a := h2!a3
 RESULTIS a } }
 IF !a=s_tuple
 { lmap (untrace, a)
 RESULTIS z } }
 msg1 (16, untrace, a) }
 
 
AND dotrace (c, a) BE
 { writef ("*N# Argument for %P: %E*N", h1!c, print, a)
 UNLESS h3!c=z
 { apply (h3!c, a)
 arg1 := a   // ??A??
 }
 gw0, gw1, gw2 := dotrace1, h1!c, h2!c
 longjump (flevel (eval), ll_ex) }
 
 
AND dotrace1 (a, f) = VALOF
 { writef ("*N# Done %P: val %E*N", f, print, arg1)
 RESULTIS a }
 
 
AND trap (a, n, b) BE
 { n := n+cons-y0
 { LET s = (@trz-1) | signbit     // ?B
 { LET s1 = h1!s
 IF s1=z
 BREAK
 IF h3!s1>=n
 { IF h3!s1>n
 h1!s := get4 (s_mb, s1, b, n)
 GOTO lx }
 s := s1 } REPEAT
 h1!s := get4 (s_mb, z, b, n)
 }
 lx:  gw0, gw1, gw2 := dotrap1, b, a
 longjump (flevel (eval), ll_ex)
 }
 
 
.
//./       ADD LIST=ALL,NAME=PALM9
 SECTION "PALM9"
 
 
GET "pal75hdr"
 
 
LET eqlv (p, q) = VALOF
 { IF p=q
 RESULTIS TRUE
 IF p<=0
 { UNLESS q>=yloc
 RESULTIS FALSE
 RESULTIS p=h1!q }
 IF q<=0
 { UNLESS p>=yloc
 RESULTIS FALSE
 RESULTIS h1!p=q }
 UNLESS !p=!q
 { IF p>=yloc
 p := h1!p <> LOOP
 IF q>=yloc
 q := h1!q <> LOOP
 RESULTIS FALSE }
 SWITCHON !p INTO
 {
 CASE s_loc: p, q := h1!p, h1!q
 LOOP
 CASE s_gensy:
 CASE s_name:
 CASE s_glz:
 CASE s_glg:
 CASE s_glo:
 CASE s_xtupl:
 CASE s_unset:
 CASE s_unset1:
 CASE s_tra: RESULTIS FALSE        // since P~=Q
 CASE s_flt: RESULTIS h2!p #= h2!q
 CASE s_fpl: msg1 (14)
 CASE s_ratn: UNLESS h1!p=h1!q
 RESULTIS FALSE
 CASE s_rds:
 CASE s_wrs:
 CASE s_bcplf:
 CASE s_bcplr:
 CASE s_bcplv:
 CASE s_codev:
 CASE s_code0:
 CASE s_code1:
 CASE s_code2:
 CASE s_code3:
 CASE s_code4:
 RESULTIS h2!p=h2!q
 CASE s_numj: IF (p NEQV q)<ysg
 CASE s_string: { UNLESS h2!p=h2!q & h3!p=h3!q
 RESULTIS FALSE
 p, q := h1!p, h1!q
 IF p=q
 RESULTIS TRUE } REPEATUNTIL p=z | q=z
 RESULTIS FALSE
 CASE s_poly: IF h3!p=h3!q
 { LET f = (p NEQV q)<ysg
 { p, q := h1!p, h1!q
 IF p=q
 TEST p=z
 RESULTIS TRUE
 ELSE RESULTIS f
 IF p=z | q=z
 RESULTIS FALSE
 UNLESS h3!p=h3!q
 RESULTIS FALSE
 f := f NEQV (p NEQV q)>=ysg
 } REPEATWHILE eqpoly (h2!p, h2!q, f)
 }
 RESULTIS FALSE
 DEFAULT: RESULTIS eql (p, q)
 }
 } REPEAT
 
 
STATIC
 { ga1 = 0
 ga2 = 0
 ga3 = 0
 ga4 = 0 }
 
 
LET gtv (p, q) = VALOF
 { SWITCHON coerce (@p, FALSE) INTO
 {
 CASE s_num: RESULTIS p>q
 CASE s_numj: IF numarg
 TEST worse1
 RESULTIS p<ysg
 ELSE RESULTIS q>=ysg
 IF (p NEQV q)>=ysg
 RESULTIS p<ysg
 { LET c = longcmp (p, q)
 IF c=0
 RESULTIS FALSE
 RESULTIS c>0 NEQV p>=ysg }
 CASE s_ratn: IF numarg
 { TEST worse1
 { ga1 := (h2!p-y0)/(h1!p-y0)+y0
 IF ga1>q
 RESULTIS TRUE
 IF ga1<q
 RESULTIS FALSE
 IF ga1=y0
 RESULTIS h2!p>y0
 RESULTIS ga1>y0 }
 ELSE { ga1 := (h2!q-y0)/(h1!q-y0)+y0
 IF p>ga1
 RESULTIS TRUE
 IF p<ga1
 RESULTIS FALSE
 IF p=y0
 RESULTIS h2!q<y0
 RESULTIS p<y0 }
 }
 IF worse
 TEST worse1
 RESULTIS q>=ysg
 ELSE RESULTIS p<ysg
 ga1, ga2 := h2!p-y0, h1!p-y0
 ga3, ga4 := h2!q-y0, h1!q-y0
 { LET f = ga1/ga2-ga3/ga4
 IF f>0
 RESULTIS TRUE
 IF f<0
 RESULTIS FALSE }
 ga1 := muldiv (ga1, ga4, numba)
 ga4 := result2
 ga2 := muldiv (ga2, ga3, numba)
 IF ga1=ga2
 RESULTIS ga4>result2
 RESULTIS ga1>ga2
 CASE s_ratl: TEST worse
 TEST worse1
 q, p := mul (h1!p, q), h2!p
 ELSE p, q := mul (p, h1!q), h2!q
 ELSE { LET t = mul (h2!p, h1!q)
 q := mul (h1!p, h2!q)
 p := t }
 LOOP
 CASE s_poly:
 CASE s_ratp: RESULTIS worse1
 CASE s_flt: RESULTIS gw1 #> gw2
 CASE s_fpl: msg1 (14)
 CASE s_string:
 RESULTIS compl (p, q)>0
 DEFAULT: msg1 (23, p, q)
 RESULTIS z
 }
 } REPEAT
 
 
AND shlv (a, b) = msg1 (26, "SHL")
 
 
AND shrv (a, b) = msg1 (26, "SHR")
 
 
.
//./       ADD LIST=ALL,NAME=POLY
 SECTION "POLY"
 
 
GET "pal75hdr"
 
 
MANIFEST
 { yz = y0+numba }
 
 
STATIC
 { sg = 0 }
 
 
// POLY REPR:     S_POLY    | POLYJ    | INDET | #MAINNESS>Y0
// POLYJ REPR:    S_POLYJ   | POLYJ(Z) | FAC   | #POW
 
// A POLY IS NOT EMPTY, NOR CONSTANT
 
 
LET algatom (p, n) = VALOF
 { LET q = get4 (s_polyj, z, y1, y1)
 n := g_posint (n)
 RESULTIS get4 (s_poly, q, p, n) }
 
 
AND alg (n) = VALOF
 { IF n>0
 { IF !n=s_name
 { algn := algn+1
 RESULTIS algatom (n, algn) }
 IF !n=s_tuple
 RESULTIS lmapl (alg, n) }
 msg1 (16, alg, n) }
 
 
AND pol (s, p) = VALOF
 { p := g_np (p, s_poly)
 RESULTIS get4 (s_poly, h1!p, s, h3!p)+(p & ysg) }
 
 
AND evalpoly (p) = VALOF
 { LET a = h2!p
 IF arithv (a)
 { LET aa, n, q = y1, y0, y0
 p := h1!p NEQV (p & ysg)
 { UNTIL n=h3!p
 { n := n+1
 aa := mul (a, aa) }
 { LET r = mul (h2!p, aa)
 q := (p<ysg -> add, minu)(q, r) }
 p := h1!p NEQV (p & ysg) } REPEATUNTIL (p & p_addr)=z
 RESULTIS q }
 RESULTIS p
 }
 
 
// P,Q ARE SAME POLYS
 
 
AND addpoly (p, q) = VALOF
 { LET r = get4 (s_poly, zsy, h2!p, h3!p)
 LET r1 = r
 IF @p>stackl
 stkover ()
 p, q := h1!p NEQV (p & ysg), h1!q NEQV (q & ysg)
 { IF h3!q>h3!p
 l:       { LET q3 = h3!q
 { sg := p & ysg
 { LET t = get4 (s_polyj, zsy, h2!p, h3!p)+sg
 h1!r1, r1 := t NEQV (r1 & ysg), t
 p := h1!p
 IF p=z
 { h1!r1 := q NEQV (r1 & ysg)
 RESULTIS r }
 p := p NEQV sg } } REPEATWHILE h3!p<q3 }
 IF h3!p>h3!q
 { LET p3 = h3!p
 { LET t = get4 (s_polyj, zsy, h2!q, h3!q)+(q & ysg)
 h1!r1, r1 := t NEQV (r1 & ysg), t
 q := h1!q NEQV (q & ysg)
 IF (q & p_addr)=z
 { h1!r1 := p NEQV (r1 & ysg)
 RESULTIS r } } REPEATWHILE p3>h3!q
 UNLESS p3=h3!q
 GOTO l }
 { LET f = (p NEQV q)<ysg -> add, minu
 f := f (h2!p, h2!q)
 UNLESS f=y0
 { f := get4 (s_polyj, zsy, f, h3!p)+(p & ysg)
 h1!r1, r1 := f NEQV (r1 & ysg), f }
 p, q := h1!p NEQV (p & ysg), h1!q NEQV (q & ysg) }
 IF (p & p_addr)=z
 { TEST (q & p_addr)=z
 { IF r1=r
 RESULTIS y0
 IF h3!r1=y0
 TEST r1<ysg
 RESULTIS h2!r1
 ELSE RESULTIS neg (h2!r1)
 h1!r1 := z }
 ELSE h1!r1 := q NEQV (r1 & ysg)
 RESULTIS r
 }
 IF (q & p_addr)=z
 { h1!r1 := p NEQV (r1 & ysg)
 RESULTIS r }
 } REPEAT
 }
 
 
// P IS POLY, A BETTER;   TRY ADDP1 (A, P, B)
 
 
AND addp1 (a, p) = VALOF
 { IF a=y0
 RESULTIS p
 { LET r = get4 (s_poly, zsy, h2!p, h3!p)
 p := h1!p NEQV (p & ysg)
 IF h3!p=y0
 { LET f = p<ysg -> add, minu
 a := f (a, h2!p)
 p := h1!p NEQV (p & ysg) // H1!P ~= Z
 IF a=y0
 { h1!r := p
 RESULTIS r } }
 h1!r := get4 (s_polyj, p, a, y0)
 RESULTIS r
 }
 }
 
 
 
// P IS POLY, A BETTER
 
 
AND polymapf (p, a, f) = VALOF  // F is like MUL
 { IF a=y0
 RESULTIS y0
 IF a=y1
 RESULTIS p
 IF a=ym
 RESULTIS p NEQV ysg
 { LET q = get4 (s_poly, zsy, h2!p, h3!p)+(p & ysg)
 LET qq = q
 p := h1!p
 { LET r = f (h2!p, a)
 r := get4 (s_polyj, zsy, r, h3!p)+(p & ysg)
 h1!qq, qq := r, r
 p := h1!p } REPEATUNTIL p=z
 h1!qq := z
 RESULTIS q }
 }
 
 
// P,Q ARE SAME POLYS
// As we build up the answer in R, we use the fact that H3!ZSY is large
 
 
// TRY MAKING Q POSITIVE
 
 
AND mulpoly (p, q) = VALOF
 { LET r0 = get4 (s_poly, zsy, h2!p, h3!p)
 LET r1, r = r0, r0+((p NEQV q) & ysg)
// R0 ^ latest immutable term in answer
// R1 ^ current target
 IF @p>stackl
 stkover ()
 p, q := h1!p, h1!q
 { LET q1, p2 = q NEQV (p & ysg), h2!p
// P2 = Y1,YM ?
 LET p3 = h3!p
 LET q3 = p3+h3!q1-y0
 IF q3>=yz
 msg1 (18, q3)
 { LET r1a = h1!r0
 UNTIL h3!r1a>=q3
 { r0 := r1a
 r1a := h1!r1a }
 r1 := r0
 { { LET t = mul (p2, h2!q1)
 TEST h3!r1a>q3        // insert term
 { IF q1>=ysg
 t := neg (t)
 t := get4 (s_polyj, r1a, t, q3)
 h1!r1, r1 := t, t }
 ELSE { { LET f = q1<ysg -> add, minu
 t := f (h2!r1a, t) }
 TEST t=y0
 { r1a := h1!r1a
 h1!r1 := r1a }   // nb destructive
 ELSE { h2!r1a := t
 r1 := r1a
 r1a := h1!r1a } }
 }
// That leaves R1A=H1!R1
 q1 := h1!q1 NEQV (q1 & ysg)
 IF (q1 & p_addr)=z
 BREAK
 q3 := p3+h3!q1-y0
 IF q3>=yz
 msg1 (18, q3)
 UNTIL h3!r1a>=q3
 { r1 := r1a
 r1a := h1!r1a }
 } REPEAT
 }
 p := h1!p NEQV (p & ysg)
 } REPEATUNTIL (p & p_addr)=z
 h1!r1 := z        // remove ZSY
 RESULTIS r
 }
 
 
// P,Q ARE SAME POLYS
// LCOEF, LDEG, RESULT2 := lcoef and degree of divisor, remainder
 
 
AND divpoly (p, q) = VALOF
 { LET r = z
 IF @p>stackl
 stkover ()
 { LET u = copyu (h1!p NEQV (p & ysg))
 LET v = copyv (h1!q NEQV (q & ysg))
 LET f = div
 q := h2!v
 IF q=y1
 f := iv
 FOR k=h3!u-h3!v+y0 TO y0 BY -1
 { LET rr = f (h2!u, q)
 u := h1!u
 UNLESS rr=y0
 { r := get4 (s_polyj, r, rr, k)
 { LET uu = u
 AND vv = h1!v
 UNLESS vv=z
 { FOR i=y2 TO h3!vv
 uu := h1!uu
 { LET t = mul (rr, h2!vv)
 h2!uu := minu (h2!uu, t)
 uu, vv := h1!uu, h1!vv } } REPEATUNTIL vv=z } }
 }
 IF r=z
 { lcoef, ldeg, result2 := q, h3!v, p
 RESULTIS y0 }
 u := uncopy (u)
 TEST u=z
 u := y0
 ELSE TEST h3!u=y0 & h1!u=z
 u := h2!u
 ELSE u := get4 (s_poly, u, h2!p, h3!p)
 TEST h3!r=y0 & h1!r=z
 r := h2!r   // R is positive
 ELSE r := get4 (s_poly, r, h2!p, h3!p)
 lcoef, ldeg, result2 := q, h3!v, u
 }
 RESULTIS r
 }
 
 
AND pseudorempoly (p, q) = VALOF
 { IF @p>stackl
 stkover ()
 { LET u = copyu (h1!p NEQV (p & ysg))
 LET ua = u
 LET v = copyv (h1!q NEQV (q & ysg))
 LET f = mul
 q := h2!v
 IF q=y1
 f := iv
 FOR k=h3!u TO h3!v BY -1
 { LET rr = h2!u
 u := h1!u
 { LET uu = u
 AND vv = h1!v
 UNLESS vv=z
 { FOR i=y2 TO h3!vv
 { h2!uu := f (h2!uu, q)
 uu := h1!uu }
 { LET t = mul (rr, h2!vv)
 LET s = f (h2!uu, q)
 h2!uu := minu (s, t)
 uu, vv := h1!uu, h1!vv } } REPEATUNTIL vv=z
 UNLESS q=y1
 UNTIL uu=zsy       // the last time round, UU already = ZSY
 { h2!uu := f (h2!uu, q)
 uu := h1!uu }
 }
 }
 IF u=ua
 { lcoef, ldeg := q, h3!v
 RESULTIS p }
 u := uncopy (u)
 TEST u=z
 u := y0
 ELSE TEST h3!u=y0 & h1!u=z
 u := h2!u
 ELSE u := get4 (s_poly, u, h2!p, h3!p)
 lcoef, ldeg := q, h3!v
 RESULTIS u
 }
 }
 
 
// These make reverse copies for U/V,
// noting that the copy of U must be dense,
// but the copy of V can be sparse (perhaps with funny entries as exponents)
 
 
AND copyu (p) = VALOF
 { LET q, q3 = zsy, y0
 { { LET p3 = h3!p
 UNTIL q3=p3
 { q := get4 (s_polyj, q, y0, q3)
 q3 := q3+1 } }
 { LET t = h2!p
 IF p>=ysg
 t := neg (t)
 q := get4 (s_polyj, q, t, q3) }
 q3 := q3+1
 p := h1!p NEQV (p & ysg)
 } REPEATUNTIL (p & p_addr)=z
 RESULTIS q
 }
 
 
AND copyv (p) = VALOF
 { LET q, p3 = z, 0
 { LET t = h2!p
 IF p>=ysg
 t := neg (t)
 UNLESS q=z
 h3!q := h3!p-p3+y0
 q := get4 (s_polyj, q, t, zsy)
 p3 := h3!p
 p := h1!p NEQV (p & ysg) } REPEATUNTIL (p & p_addr)=z
 h3!q := p3
 RESULTIS q
 }
 
 
AND uncopy (p) = VALOF
 { LET q = z
 { LET t = h1!p
 UNLESS h2!p=y0
 { h1!p := q
 q := p }
 p := t } REPEATUNTIL p=zsy
 RESULTIS q }
 
 
AND monicpoly (a) = VALOF
 { LET q = h1!a NEQV (a & ysg)
 UNTIL h1!q=z
 q := h1!q NEQV (q & ysg)
 { LET t = h2!q
 IF q>=ysg
 t := neg (t)
 IF t=y1
 { lcoef := t
 RESULTIS a }
// ??SS?? TEST RATP(Y1)=RATP(YM)
 q := q & p_addr
 { LET r = get4 (s_poly, zsy, h2!a, h3!a)+(a & ysg)
 LET rr = r
 a := h1!a
 UNTIL (a & p_addr)=q
 { LET s = div (h2!a, t)
 s := get4 (s_polyj, zsy, s, h3!a)+(a & ysg)
 h1!rr, rr := s, s NEQV (rr & ysg)
 a := h1!a }
 h1!rr := get4 (s_polyj, z, y1, h3!q) NEQV (rr & ysg)
 lcoef := t
 RESULTIS r
 }
 }
 }
 
 
AND polygcd (p, q) = VALOF
 { LET d0 = 0
 LET l1, d1 = 0, h1!p
 
 UNTIL h1!d1=z
 d1 := h1!d1
 d1 := h3!d1
 
 { LET r = pseudorempoly (p, q)
 UNLESS r>0 & !r=s_poly & h3!r=h3!q
 TEST r=y0
 RESULTIS q
 ELSE RESULTIS y1
 { LET  tl , td = lcoef, ldeg
 p := q
 TEST d0=0
 q := r
 ELSE { LET c = pow (l1, d0-d1+y1)
 TEST c=y1
 q := r
 ELSE q := polymapf (r, c, div) }
 d0 := d1
 l1, d1 :=  tl , td
 }
 } REPEAT
 }
 
 
 
// This is the price we pay for not having a canonical form for the signs of
// polynomial terms_
// F -> we want P=Q, else we want P=-Q
 
 
AND eqpoly (a, b, f) = VALOF
 { IF a=b
 RESULTIS f
 IF a<=0
 { IF b<=0
 UNLESS f
 RESULTIS a+b=signbit
 RESULTIS FALSE }
 IF b<=0
 RESULTIS FALSE
 UNLESS !a=!b
 RESULTIS FALSE
 IF @a>stackl
 stkover ()
 SWITCHON !a INTO
 {
 CASE s_flt: TEST f
 RESULTIS h2!a #= h2!b
 ELSE RESULTIS h2!a #=  #- h2!b
 CASE s_fpl: msg1 (14)
 CASE s_numj: IF f=((a NEQV b)<ysg)
 RESULTIS compl (a, b)=0
 RESULTIS FALSE
 CASE s_ratn: UNLESS h1!a=h1!b
 RESULTIS FALSE
 a, b := h2!a, h2!b
 LOOP
 CASE s_ratp: UNLESS h3!a=h3!b
 RESULTIS FALSE
 CASE s_ratl: UNLESS eqlv (h1!a, h1!b)
 RESULTIS FALSE
 a, b := h2!a, h2!b
 LOOP
 CASE s_poly: IF h3!a=h3!b
 { f := f NEQV (a NEQV b)>=ysg
 { a, b := h1!a, h1!b
 IF a=b
 TEST a=z
 RESULTIS TRUE
 ELSE RESULTIS f
 IF a=z | b=z
 RESULTIS FALSE
 f := f NEQV (a NEQV b)>=ysg } REPEATWHILE h3!a=h3!b & eqpoly (h2!a, h2!b, f)
 }
 RESULTIS FALSE
 DEFAULT: msg1 (33, "Poly", a)
 }
 } REPEAT
 
 
.
//./       ADD LIST=ALL,NAME=SETUP
SECTION "SETUP"

GET "pal75hdr"

// Allocation at top of heap, for use before free-store package is under way

LET gg0 (s, f) = get4 (s, 0, !f | signbit, !f<0)        // !F<0 concerns BCPLF

AND g3s (f, g) = get4 (s_code2, 0, !f | signbit, g | signbit)

LET s0 (s) = VALOF
 { unpackstring (s, buffp)
 RESULTIS string (buffp) }
 
 
AND ds (s, g1, g2, p1, p2, p3) = VALOF
 { s := s0 (s)
 g1 := g3s (g1, g2)
 p1 := prios (s_diadop, p1, p2, p3)
 RESULTIS h2!linkword (s_glo, s, g1, p1) }
 
 
AND dt (s, g1, g2, p1, p2, p3) = VALOF
 { s := s0 (s)
 g1 := g3s (g1, g2)
 p1 := prios (s_relop, p1, p2, p3)
 RESULTIS h2!linkword (s_glo, s, g1, p1) }
 
 
AND du (s, f, g, n) = VALOF
 { s := s0 (s)
 f := gg0 (f, g)
 RESULTIS h2!linkword (s_glo, s, f, n | signbit) }
 
 
AND dv (s, f, g, n, p) = VALOF
 { s := s0 (s)
 f := gg0 (f, g)
 n := prios1 (n, p)
 RESULTIS h2!linkword (s_glo, s, f, n) }
 
 
AND dy (s, v, n) = VALOF
 { s := s0 (s)
 RESULTIS h2!linkword (s_glo, s, v, n | signbit) }
 
 
AND set_p (s, n) = VALOF
 { LET a = s0 (s)
 RESULTIS h2!linkword (s_glo, a, iv, n | signbit) }
 
 
AND set_q (s, f, n, p1, p2, p3) = VALOF
 { LET a = s0 (s)
 RESULTIS h2!linkword (s_glo, a, f | signbit, prios (n, p1, p2, p3)) }
 
 
AND prios1 (n, a) = n+(a<<8) | signbit
 
 
AND prios (n, a, b, c) = n+(a<<24)+(b<<16)+(c<<8) | signbit
 
 
AND set_d (s, f) = d (s, s_code1, f)
 
 
AND set_v (s, f) = d (s, s_codev, f)
 
 
AND set_c (s, f) = d (s, s_code2, f)
 
 
AND set_f (s, f) = d (s, s_bcplf, f)
 
 
AND set_r (s, f) = d (s, s_bcplr, f)
 
 
AND d (s, n, f) = VALOF
 { LET a = s0 (s)
 LET b = gg0 (n, f)
 RESULTIS h2!linkword (s_glo, a, b, zsy) }
 
 
AND set_z (n, s, a2, a3) = VALOF
 { s := s0 (s)
 RESULTIS h2!linkword (n, s, a2, a3) }
 
 
LET setup () BE
{ ///fixbcpl1 ()
  rtime := 0
  stackb := level ()>>2     // this will last
  stackp := 0
  cons, cycles := y0, y0
  gensymn, algn := y0, y0
  gseq, gseqf := 0, 0
 
  parama, paramb, paramc, paramd := FALSE, FALSE, FALSE, FALSE
  parami, paramj, paramk, paramm := FALSE, FALSE, FALSE, FALSE
  paramn, paramq, paramv, paramy := FALSE, FALSE, FALSE, FALSE
  paramz := TRUE
 
  ksq, kwords, kstack := 2048, 1024, 1024
  ssz := stackend-stackbase
///sawritef("setup: ssz=%n*n*n", ssz)
///sawritef("setup: calling param(parms)*n")
  ////param (parms)
 
  region := ((stackend+pagesize) & pagemask)-(loadpoint & pagemask)
  writef ("*N# Pal system at %S on %S;  parm '%S';  Region %NK bytes*N",
           timeofday (), date (), parms, region>>8)
  IF paramk DO
    writef ("# Version%S;  code/heap %N/%N words;  heap %N%% of region",
            loadpoint+4, endpoint-loadpoint, ssz, ssz*100/region)
 
  FOR i=@error TO @g0+maxglob DO gpfn (i)
 
  { LET t = "DHAMMA  "
    FOR i=0 TO 8 DO putbyte (buffp+buffl-2, i, getbyte (t, i+1))
    buffp!buffl := (@g0)<<2
  }
 
  { LET d (n, s) BE        // OP mnemonic names
    { n := n-@ll_zc+ocm
      FOR i=0 TO 3 DO putbyte (n, i, getbyte (s, i+1))
    }
    AND a (n, s) BE
    { !n := !n | sva
      d (n, s)
    }
    FOR i=1 TO ocmsz DO d (@ll_zc+i, "NNN ")
    d (@ll_zc, "Q   ")
    d (@la_entx, "IEX ")
    d (@la_enty, "IEY ")
    d (@la_entz, "IEZ ")
    d (@la_aploc, "IAL ")
    d (@la_aptup, "IAT ")
    d (@la_apcode2, "IAB2")
    d (@la_apclos2, "IAE2")
    d (@la_apeclos, "IAE ")
    d (@la_apfclos, "IAF ")
    d (@ll_entx, "KEX ")
    d (@ll_enty, "KEY ")
    d (@ll_entz, "KEZ ")
    d (@ll_apeclos, "KAE ")
    d (@ll_apfclos, "KAF ")
    d (@la_a1, "IA1 ")
    d (@la_ae, "IAE ")
    d (@ll_ap, "IA  ")
    a (@ll_rsc, "QC  ")
    a (@ll_rsf, "QF  ")
    a (@ll_svc, "SVC ")
    a (@ll_svf, "SVF ")
    a (@ll_svf1, "SVF1")
    d (@ll_closl, "CLL ")
    d (@ll_closx, "CLX ")
    d (@ll_bind, "BV  ")
    a (@ll_binde, "BE  ")
    d (@ll_lv, "BVLV")
    d (@ll_rv, "BVRV")
    d (@ll_bvf, "BVF ")
    d (@ll_bvfe, "BVFE")
    d (@ll_bvfa, "BVFA")
    d (@ll_bvf1, "BVF1")
    d (@ll_bvfz, "BVFZ")
    d (@ll_bve, "BVE ")
    d (@ll_bvez, "BVEZ")
    a (@ll_unbind, "UBV ")
    d (@ll_cy, "L   ")
    a (@ll_cyf, "LF  ")
    d (@ll_na, "N   ")
    d (@ll_na1, "N1  ")
    d (@ll_na2, "N2  ")
    a (@ll_naf, "NF  ")
    a (@ll_na1f, "NF1 ")
    a (@ll_na2f, "NF2 ")
    a (@ll_st, "S   ")
    d (@ll_us, "F   ")
    a (@ll_rec0, "REC0")
    d (@ll_rec1, "REC1")
    d (@ll_e, "E   ")
    d (@ll_j, "J   ")
    a (@ll_cond, "->  ")
    a (@ll_tup, "AUG ")
    a (@ll_tupa, "AUGA")
    d (@ll_tupz, "AUGZ")
    d (@ll_1tup, "AUG1")
    d (@ll_apv, "B1V ")
    d (@ll_ap1, "B1  ")
    d (@ll_hdv, "HD  ")
    d (@ll_miv, "MI  ")
    d (@ll_tlv, "TL  ")
    d (@ll_null, "NULL")
    d (@ll_atom, "ATOM")
    d (@ll_ap2, "B2  ")
    a (@ll_ap2f, "B2F ")
    d (@ll_ap2s, "B2S ")
    a (@ll_ap2sf, "B2SF")
    d (@ll_cons, "AU  ")
    a (@ll_consf, "AUF ")
    d (@ll_xcons, "XAU ")
    a (@ll_xconsf, "XAUF")
    d (@ll_apnf, "APF ")
    d (@ll_apnf1, "APF1")
    d (@ll_apnk, "APK ")
    d (@ll_apnc, "APC ")
    d (@ll_apnj, "APJ ")
    d (@ll_apcf, "ACF ")
    d (@ll_apcf1, "ACF1")
    d (@ll_apck, "ACK ")
    d (@ll_apcc, "ACC ")
    d (@ll_apbf, "ABF ")
    d (@ll_apbf1, "ABF1")
    d (@ll_apbk, "ABK ")
    d (@ll_apbc, "ABC ")
    d (@ll_apkf, "ATF ")
    d (@ll_apkk, "ATK ")
    d (@ll_apkc, "ATC ")
    d (@ll_apkj, "ATJ ")
  }
 
  initff ()
 
 
// HEAP:
//      | ST1     (SVU SVV)     ST2 |
 
 
// MARK FROM @E TO @ERZ
// RELOCATE FROM @E TO @A_NULL, AND TYP
 
  st1 := stackbase+ssz & ~3
  st2 := st1-4
  ///UNLESS stackb+kstack+1024<=st1<=stackend GOTO ll // ??T??

  stack (kstack)
  IF stackb>stackl DO
  { ll: { writef ("*N# INSUFFICIENT REGION: STACK %NK BYTES*N", ssz>>8)
          stop (8)
        }
  }
 
  m := s_j
 
  FOR i=@e TO @a_null DO !i := z
 
sawritef("setup: breakpoint*n"); cinabort(1009)
  zsy := get4 (s_unset, z, y0, y0+numba)
sawritef("setup: breakpoint*n"); cinabort(1010)
  zu := get4 (s_mb, 0, 0, zsy)      // keep this from being squashed
  zsq := get4 (s_mb, zsy+p_tagp, zsy+p_tagp, zsy+p_tagp)    // "maxint" for Pal
  zc := get4 (s_cd, z, z, ll_zc)
  ze := get4 (s_e, z, z, z)
  e := ze
  zj := get4 (s_j, ze, z, z)
  zs := get4 (s_string, z, 0, 0)
  zsc := get4 (s_unset1, 0, 0, 0)
 
  svv, svu := zsc, zsc-4
 
  FOR i=typ TO typ+typsz DO !i := zsy
 
  typ!s_string := set_f ("STRING", @string)
  a_num := set_v ("NUM", @num)
  FOR i=s_flt TO s_ratl DO typ!i := a_num
  typ!s_poly := set_c ("POL", @pol) // ??P??
  typ!s_polyj := typ!s_poly
  typ!s_loc := set_d ("LV", @lvv)
  typ!s_cdx := set_v ("FLATTEN", @flatten)
  FOR i=s_cdy TO s_cd
  typ!i := typ!s_cdx
  typ!s_bcplf := set_v ("BCPLF", @bcplf)
  typ!s_bcplr := set_v ("BCPLR", @bcplr)
  typ!s_bcplv := set_v ("BCPLV", @bcplv)
  typ!s_codev := set_v ("CODE", @code)
  FOR i=s_code0 TO s_code4 DO typ!i := typ!s_code0
  typ!s_rds := set_f ("RDS", @rds)
  typ!s_wrs := set_f ("WRS", @wrs)
  typ!s_gensy := d ("GENSYM", s_code0, @gensym)
  typ!s_name := set_v ("NAME", @name)
  a_qu := dv ("'", s_codev, @mqu, s_qu, 35)
  set_z (!a_qu, "qu", h2!a_qu, prios1 (s_qu, 2))
  FOR i=s_glz TO s_qu DO typ!i := a_qu
  typ!s_tuple := set_v ("TUPLE", @tuple)
  typ!s_xtupl := set_v ("SAVE", @xtuple)
  typ!s_tra := set_c ("TRACE", @trace)
  typ!s_e := ze
  a_fclos := du ("lambda", s_code2, @fn, s_fclos)
  FOR i=s_clos TO s_fclos DO typ!i := a_fclos
  set_z (!a_fclos, "fn", h2!a_fclos, h3!a_fclos)
  typ!s_rec := du ("rec", s_code2, @rec, s_rec)
  typ!s_reca := typ!s_rec
  typ!s_let := du ("let", s_code3, @mlet, s_let)
  FOR i=s_leta TO s_letb DO typ!i := typ!s_let
  typ!s_retu := dv ("return", s_codev, @retu, s_retu, 35)
  typ!s_cond := du ("->", s_code3, @mcond, s_cond)
  FOR i=s_conda TO s_condb DO typ!i := typ!s_cond
  typ!s_seq := ds (";", @mseq, seq, 2, 3, 2)
  typ!s_seqa := typ!s_seq
  set_z (!(typ!s_seq), "<>", h2!(typ!s_seq), prios (s_diadop, 9, 10, 9))
  typ!s_colon := du (":", s_code2, @mcolon, s_colon)
  typ!s_dash := set_v ("DF", @mdash)
  typ!s_aa := dv ("@", s_codev, @mk_aa, s_aa, 35)
  typ!s_zz := dv ("!", s_codev, @mk_zz, s_zz, 35)
  typ!s_apz := set_c ("AP", @ap1)
  FOR i=s_apply TO s_aqe DO typ!i := typ!s_apz
  FOR i=s_j TO s_mb DO typ!i := zj
 
  ds (":=", @assg, ap2, 4, 5, 4)
  ds ("aug", @aug, mk_aug, 12+64, 12, 13)
  ds ("<<", @shlv, ap2, 19, 19, 22)
  ds (">>", @shrv, ap2, 19, 19, 22)
  dt ("is", @isv, ap2, 20+64, 21, 21)
  a_eq := dt ("=", @eqlv, ap2, 20, 21, 21)
  a_gt := dt (">", @gtv, ap2, 20, 21, 21)
  a_plus := ds ("+", @add, mk_plus, 25, 25, 25)
  a_minu := ds ("-", @minu, mk_minu, 25, 25, 26)
  a_mul := ds ("**", @mul, mk_mul, 30, 30, 30)
  a_div := ds ("/", @div, mk_div, 30, 30, 31)
  ds ("mod", @modv, ap2, 30+64, 30, 31)
  ds ("^", @pow, mk_pow, 32, 33, 32)
 
  a_null := set_v ("NULL", @null)
  dv ("~", s_codev, @mnull, s_null, 35)
  set_p ("nil", s_nil)
  set_d ("ERROR", @error)
  set_d ("I", @iv)
  set_p ("do", s_do)
  set_p ("then", s_then)
  set_p ("or", s_or)
  set_p ("else", s_else)
  set_p ("by", s_by)
  set_p ("if", s_if)
  set_p ("unless", s_unless)
  set_p ("while", s_while)
  set_p ("until", s_until)
  set_p ("repeat", s_repeat)
  set_p ("for", s_for)
  set_f ("PARAM", @param)
  set_v ("ABS", @absv)
  set_r ("YTAB", @ytab)
  set_r ("ZTAB", @ztab)
  d ("READ", s_code0, @rea)
  set_c ("GCD", @gcda)
  set_p ("fin", s_fin)
  set_f ("UNDUMP", @undump)
  set_v ("PMAP", @pmap)
  set_v ("GLOBAL", @globa)
  set_f ("NUMBER", @number)
  set_r ("STACK", @stack)
  dy ("true", TRUE, s_pp)
  set_v ("PRINJ", @prinj)
  d ("INPUT", s_bcplv, @input)
  set_r ("NEWLINE", @newline)
  d ("READX", s_code0, @readx)
  set_f ("GET", @getv)
  set_v ("PRINTA", @printa)
  set_v ("PRCH", @prch)
  d ("OUTPUT", s_bcplv, @output)
  set_p ("within", s_within)
  set_v ("PRINL", @prinl)
  set_v ("SHOW", @show)
  set_v ("ORDER", @order)
  set_v ("HD", @hdv)
  set_v ("MI", @miv)
  set_v ("TL", @tlv)
  set_v ("TY", @tyv)
  set_v ("RATIONAL", @rat)
  set_f ("GETM", @getmv)
  d ("TRAP", s_code3, @trap)
  set_v ("ALG", @alg)
  set_c ("ALGATOM", @algatom)
  set_v ("ATOM", @atom)
  set_v("MAINVAR", @mainvar)
  set_v ("TEMPUS", @tempus)
  set_r ("PRINF", @writef)
  set_v ("PRIN", @prin)
  set_v ("FLOAT", @floatv)
  set_v ("FIX", @fixv)
  set_c ("RATAPPROX", @ratapprox)
  set_r ("XTAB", @xtab)
  set_r ("TAB", @tab)
  set_v ("UNTRACE", @untrace)
  set_v ("ERRORSET", @errorset)
  set_v ("ERROREVAL", @erroreval)
  set_p ("in", s_in)
  set_f ("LOAD", @g_load)
  set_c ("FIND", @find)
  d ("PUT", s_code3, @put)
  set_p ("where", s_where)
  set_f ("UNLOAD", @g_unload)
  set_v ("PRINT", @print)
  set_c ("GENGLO", @genglo)
  set_v ("SYN", @syn)
  set_f ("DUMP", @dump)
  set_v ("PRINE", @prine)
  dy ("E", ze, s_pp)
  dy ("J", zj, s_pp)
  set_p ("and", s_and)
  set_v ("REV", @rev)
  d ("PRINK", s_code3, @prink)
  set_v ("FUNCTION", @function)     // ??F??
 
  set_p ("(", s_lpar)
  set_p (")", s_rpar)
  set_q ("|", mk_logor, s_diadop, 0, 14, 13)
  set_q ("&", mk_logand, s_diadop, 0, 16, 15)
  set_q ("~=", mk_ne, s_relop, 20, 21, 21)
  set_q (">=", mk_ge, s_relop, 20, 21, 21)
  set_q ("<=", mk_le, s_relop, 20, 21, 21)
  set_q ("<", mk_lt, s_relop, 20, 21, 21)
  set_p ("*"", s_q2)
  set_p ("#", s_sh1)
  set_p (".", s_dot)
  set_p ("?", s_qr)
  set_p ("%", s_infix)
  set_p (",", s_tuple)
  dv ("$", s_codev, @mdol, s_dlr, 35)
 
// BALANCE ()
 
  clock (TRUE)
  tempusp ("Starting", 0)
  newline ()
  okpal := TRUE
}
 
 
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
 
 
GET "pal75hdr"
 
 
STATIC
 { n = 0
 w = 0 }
 
 
// n.b. HDR>0   ?H
 
 
LET sqff () BE
 { fff!0 := 0        // Lock out free-chain
 FOR i=1 TO mtypsz
 fff!i := zsq
 fff!s_loc := 0    // Lock these out
 fff!s_name := 0   // ?GENSY
 fff!s_glz := 0
 fff!s_glo := 0
 fff!s_xtupl := 0
 fff!s_tra := 0
 fff!s_apz := 0
 FOR i=mtypsz+1 TO typsz
 fff!i := 0
 }
 
 
AND squash () = VALOF
 { clock (FALSE)
 IF paramd // ?D
 verify ()
 okpal := FALSE
 
 { LET s = stackp
 UNTIL s=0
 { LET t = !s
 h1!s, !s := t, 0
 s := t } }
 
 FOR i=svv TO st2 BY 4
 !i := (!i<<24)+signbit
 
 sqff ()   // ?-
 fff!s_ratl := 0
 FOR i=st1 TO svu BY 4
 IF h1!i<0
 squash2 (i)
 
// Now marked store is  1.......[FORWARD]
//                  or          [ chain FFF->ZSQ ]
//                  or  1 <HDR> 0
 
 FOR i=1 TO mtypsz
 { LET s = fff!i
 IF s=0
 LOOP
 WHILE s<0
 s := h3!s
 UNTIL s=zsq
 { LET t = !s
 !s := (i<<24)+signbit
 s := t } }
 
// now 1.......[FORWARD]
//  or 1 <HDR> 0     ?+
 
 sqff ()
 FOR i=@e TO @a_null
 IF !i>0
 !i := squash1 (!i)
 FOR i=typ TO typ+typsz
 IF !i>0
 !i := squash1 (!i)
 { LET q1 = @q1-3
 { LET q = 1!q1>>2
 IF q<=stackbase
 BREAK
 IF !q<0
 FOR i=q+3 TO q1-1
 IF !i>0
 !i := squash1 (!i)
 q1 := q } REPEAT }
 
// now 1.......[FORWARD]
//  or 1 <HDR> [0, or CHAIN -> ZSQ]
 
 { LET s = fff!s_ratl     // FOR I=S_RATN TO S_RATL
 WHILE s<0
 s := h1!s
 UNTIL s=zsq
 { LET t = h1!s
 h1!s, h3!s := h3!s, 0
 s := t }
 fff!s_ratl := 0 }
 
 FOR i=1 TO mtypsz
 { LET s = fff!i
 IF s=0
 LOOP
 WHILE s<0
 s := h1!s
 UNTIL s=zsq
 { LET t = h1!s
 h1!s := 0
 s := t } }
 
 FOR i=svv TO st2 BY 4
 rtails (i)
 
 w := 0
 FOR i=st1 TO svu BY 4
 { LET j = !i
 IF j<0
 TEST (j & p_tagp)=0
 { h1!i, stackp := stackp, i
 w := w+4 }
 ELSE rtails (i) }
 
 { LET s = stackp
 UNTIL s=0
 { LET t = h1!s
 !s, s := t, t } }
 
 n := w*100/ssz
 initff ()
 okpal := TRUE
 clock (TRUE)
 IF paramv
 { LET t () BE
 writef ("   %N%% (%N words) heap reclaimed", n, w)
 tempusp ("SQUASH", t) }
 IF paramd // ?D
 verify ()
 RESULTIS n
 }
 
 
AND fixc (a) BE
 { LET w = !a
 IF w>0
 { LET x = !w
 IF x<0 & (x & p_tagp)=0
 !a := (x & p_addr)+(w & p_tag) } }
 
 
AND rtails (i) BE
 { LET p = !i
 { LET t = (p & p_tagp)>>24
 IF t>=mm3
 fixc (i+3) <> fixc (i+2)
 !i := t }
 IF (p & p_addr)=0
 RETURN
 { LET t = h1!p
 h1!p := i+(t & p_tag)
 IF (t & p_addr)=zsq
 RETURN
 p := t } REPEAT
 }
 
 
AND rtails1 (a, b) BE
 { LET a0, b0 = !a, !b
 IF (b0 & p_addr)=0
 { b0 := zsq+(b0 & p_tag)
 !b := b0 }
 b := b-1
 { LET ay, a2, a3 = (!a0 & p_tagp), h2!a0, h3!a0
 WHILE h2!b0<a2
 { b := b0
 b0 := h1!b0 }
 IF h2!b0=a2
 { WHILE h3!b0<a3
 { b := b0
 b0 := h1!b0
 IF h2!b0>a2
 GOTO lx }
 IF h3!b0=a3
 { WHILE (!b0 & p_tagp)<ay
 { b := b0
 b0 := h1!b0
 IF h2!b0>a2 | h3!b0>a3
 GOTO lx }
 IF (!b0 & p_tagp)=ay
 { LET a1 = h1!a0 & p_tag
 WHILE (h1!b0 & p_tag)<a1
 { b := b0
 b0 := h1!b0
 IF h2!b0>a2 | h3!b0>a3 | (!b0 & p_tagp)>ay
 GOTO lx }
 IF (h1!b0 & p_tag)=a1
 { msg0 (1, rtails1)
 a := a0
 a0 := h1!a0
 UNLESS (!a & p_addr)=0
 rtails1 (a, b0)
 !a := (b0 & p_addr)+signbit    // share
 LOOP }
 }
 }
 }
 lx: a := a0
 a0 := h1!a0
 h1!a := (b0 & p_addr)+(a0 & p_tag)
 { LET t = (a & p_addr)+(b0 & p_tag)
 h1!b, b := t, t }
 } REPEATUNTIL (a0 & p_addr)=zsq
 }
 
 
AND squash1 (a) = VALOF
 { LET q, n = 0, 3
 { LET u = !a
 IF u<=0
 TEST (u & p_tagp)=0
 RESULTIS (u & p_addr)+(a & p_tag)
 ELSE RESULTIS a
 IF u<mm3
 n := 1
 !a := (u<<24)+signbit }
 { IF n=0
 { UNLESS a>=yfj
 a := squash3 (a)
 IF q=0
 RESULTIS a
 { LET t = !q
 !q := a
 a := q-1
 n, a := a & 3, a-n
 q := t }
 LOOP
 }
 { LET t = n!a
 IF t<=0
 { n := n-1
 LOOP }
 { LET u = !t
 IF u<=0
 { IF (u & p_tagp)=0
 n!a := (u & p_addr)+(t & p_tag)
 n := n-1
 LOOP }
 !t := (u<<24)+signbit
 n!a := q
 q := a+n
 a := t
 TEST u<mm3
 n := 1
 ELSE n := 3
 }
 }
 } REPEAT
 }
 
 
AND squash2 (a) BE      // ?-
 { LET a1, a2, a3 = h1!a, h2!a, h3!a // ~= ZSY
 LET s1 = fff-3+!a
 LET s2 = h3!s1
 IF s2=0   // Locked out
 { !a := (!a<<24)+signbit
 RETURN }
 
 { LET t1, t2 = 0, 0
 
// scan rough chain through H3
 WHILE s2<0
 { IF h1!s2<=a1
 { { IF h1!s2<a1
 { t1 := !s2
 t2 := !t1
 GOTO l1 }
 IF h2!s2<=a2
 { { IF h2!s2<a2
 { t1 := !s2
 t2 := !t1
 GOTO l1 }
 t1 := !s2
 IF h3!t1<=a3
 { IF h3!t1<a3
 { t2 := !t1
 GOTO l1 }
 !a := t1 // share
 RETURN }
 s1 := s2
 s2 := h3!s2
 IF s2>0
 BREAK
 IF h1!s2<a1
 { t1 := !s2
 t2 := !t1
 GOTO l1 }
 } REPEAT
 BREAK
 }
 s1 := s2
 s2 := h3!s2
 } REPEATWHILE s2<0
 BREAK
 }
 s1 := s2
 s2 := h3!s2
 }
 
 t1, t2 := h3+s1, s2
 
 l1: UNTIL h1!t2>=a1
 { t1 := t2
 t2 := !t2 }
 IF h1!t2=a1 & h2!t2<=a2
 { IF h2!t2<a2
 { { t1 := t2
 t2 := !t2
 IF h1!t2>a1
 GOTO lx } REPEATWHILE h2!t2<a2
 IF h2!t2>a2
 GOTO lx }
 IF h3!t2<=a3
 { IF h3!t2<a3
 { { t1 := t2
 t2 := !t2
 IF h2!t2>a2 | h1!t2>a1
 GOTO lx } REPEATWHILE h3!t2<a3
 IF h3!t2>a3
 GOTO lx }
 !a := t2+signbit   // share
 h3!a := s2 // put in rough chain
 h3!s1 := a+signbit
 RETURN
 }
 }
 
// insert
 lx: !a := t2
 !t1 := a
 RETURN
 }
 }
 
 
// (!A&P_ADDR)~=0 means cyclic list;
// we must re-direct its parents (RTAILS1) if we leave a
// forwarding-address_
// n.b. fortunately, RATL cannot be cyclic
 
 
AND squash3 (a) = VALOF
 { LET a0, a1, a2, a3 = !a & p_tagp, h1!a, h2!a, h3!a
 LET s1 = fff-1+(a0>>24)
 LET s2 = h1!s1
 IF s2=0 | a2=zsy | a3=zsy // Locked out
 RESULTIS a
 
 IF a1<=0
 { IF a1<0
 { UNLESS !a=s_ratl      // S_RATN<=!A<=S_RATL
 msg1 (13, squash3)
 h3!a, h1!a := a1, 0
 a3, a1 := a1, 0 }
 
 { LET t1, t2 = 0, 0
 
// scan rough chain through H1
 WHILE s2<0
 { IF h2!s2<=a2
 { { IF h2!s2<a2
 { t1 := !s2
 t2 := h1!t1
 GOTO l1 }
 IF h3!s2<=a3
 { IF h3!s2<a3
 { t1 := !s2
 t2 := h1!t1
 GOTO l1 }
 UNLESS (!a & p_addr)=0
 rtails1 (a, !s2)
 !a := !s2   // share
 RESULTIS (!s2 & p_addr)+(a & p_tag) }
 s1 := s2
 s2 := h1!s2
 } REPEATWHILE s2<0
 BREAK
 }
 s1 := s2
 s2 := h1!s2
 }
 
 t1, t2 := s1, s2
 
 l1: UNTIL h2!t2>=a2
 { t1 := t2
 t2 := h1!t2 }
 IF h2!t2=a2 & h3!t2<=a3
 { IF h3!t2<a3
 { { t1 := t2
 t2 := h1!t2
 IF h2!t2>a2
 GOTO lx } REPEATWHILE h3!t2<a3
 IF h3!t2>a3
 GOTO lx }
 UNLESS (!a & p_addr)=0
 rtails1 (a, t2)
 !a := t2+signbit   // share
 h1!a := s2 // put in rough chain
 h1!s1 := (a & p_addr)+signbit
 RESULTIS t2+(a & p_tag)
 }
 
// insert
 lx: h1!a := t2
 h1!t1 := a & p_addr
 RESULTIS a
 }
 }
 
 IF a1=zsy
 RESULTIS a
 
 { LET a1t = a1 & p_tag
 LET b = !a1
 IF (b & p_addr)=0
 { h1!a := a1t+zsq
 !a1 := (a & p_addr)+(b & p_tag)
 RESULTIS a }
 a1 := a1-1
 
 UNTIL h2!b>=a2
 { a1 := b
 b := h1!b }
 IF h2!b=a2 & h3!b<=a3
 { IF h3!b<a3
 { { a1 := b
 b := h1!b
 IF h2!b>a2
 GOTO lx } REPEATWHILE h3!b<a3
 IF h3!b>a3
 GOTO lx }
 IF (!b & p_tagp)<=a0
 { IF (!b & p_tagp)<a0
 { { a1 := b
 b := h1!b
 IF h3!b>a3 | h2!b>a2
 GOTO lx } REPEATWHILE (!b & p_tagp)<a0
 IF (!b & p_tagp)>a0
 GOTO lx }
 IF (h1!b & p_tag)<=a1t
 { IF (h1!b & p_tag)<a1t
 { { a1 := b
 b := h1!b
 IF (!b & p_tagp)>a0 | h3!b>a3 | h2!b>a2
 GOTO lx } REPEATWHILE (h1!b & p_tag)<a1t
 IF (h1!b & p_tag)>a1t
 GOTO lx }
 UNLESS (!a & p_addr)=0
 rtails1 (a, b)
 !a := (b & p_addr)+signbit   // share
 RESULTIS (b & p_addr)+(a & p_tag)
 }
 }
 }
 
// insert
 lx: h1!a := (b & p_addr)+a1t
 h1!a1 := (a & p_addr)+(b & p_tag)
 RESULTIS a
 }
 }
 
 
.
//./       ADD LIST=ALL,NAME=START
SECTION "START"

GET "pal75hdr"

LET start () = VALOF
{ LET u = VEC buffl
  LET argv = VEC 50 /// MR 19/11/2010
///sawritef("*nstart: entered*n")
  UNLESS rdargs("parms", argv, 50) DO
  { sawritef("Bad arguments for PAL*n")
    RESULTIS 0
  }
  parms := "D"
  IF argv!0 DO parms := argv!0

  stackbase := currco
  stackend := stackbase + currco!co_size
///sawritef("start: stackbase=%n stackend=%n*n", stackbase, stackend)
  loadpoint := rootnode!rtn_membase
  endpoint := loadpoint + rootnode!rtn_memsize
///sawritef("start: loadpoint=%n endpoint=%n*n", loadpoint, endpoint)

///cinabort(1000)
  buffp := u+signbit
  ocm :=  TABLE 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0, 0   // (120) OP mnemonic

  typ :=  TABLE 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0, 0   // TYPSZ

  fff :=  TABLE 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0, 0   // TYPSZ

  okpal := FALSE
///sawritef("*nstart: entered*n")
///cinabort(1000)
  erlev, erlab := level(), l
  //stackb, stackl := stackbase, stackend
  stackb, stackl := currco, currco + currco!co_size
///sawritef("start: stackb=%n stackl=%n*n", stackb, stackl)

  { // Swap setio and psetio
    LET t = setio
    setio, psetio := psetio, t
  }

  { // Swap wframe and pframe
    LET t = wframe
    wframe, pframe := pframe, t
  }

  setio ()
// cinabort(1002)

///sawritef("*nstart: NOT calling g_load SETUP PALSYS*n")
  ///g_load ("SETUP", "PALSYS")

sawritef("*nstart: calling setup (=%n)*n", setup)
///cinabort(1003)
  setup ()
sawritef("*nstart: calling g_unload (*"SETUP*")*n")
cinabort(1004)
  g_unload ("SETUP")
 
  u := findinput ("SUPERVIS")
  TEST u=0
  THEN rp ()
  ELSE { u := getex ("SUPERVIS")
         eval (u)
       }
  end (0)
  RESULTIS 0
 
l:setio ()
  UNLESS okpal DO msg1 (1)
  UNLESS erz=z DO
  { arg1 := erz
    erz := z
    tempusp ("Re-start", 0)
    eval (arg1)
  }
  end (4)
  RESULTIS 4
}
 
 
AND initff () BE
 { FOR i=0 TO typsz
 fff!i := msg2
 FOR i=s_string TO s_polyj
 fff!i := iv
 fff!s_glz := msg3
 FOR i=s_glg TO s_qu
 fff!i := sel2
 FOR i=s_gensy TO s_name
 fff!i := lookup
 fff!s_tuple := ff_tuple
 fff!s_e := ff_e
 FOR i=s_clos TO s_fclos
 fff!i := ff_clos
 fff!s_reca := ff_reca
 fff!s_condb := ff_condb
 fff!s_seqa := ff_seqa
 fff!s_dash := ff_dash
 fff!s_a1e := ff_a1e
 fff!s_aa := ff_a1e
 fff!s_ave := ff_ave
 fff!s_zz := ff_ave
 fff!s_a2e := ff_a2e
 }
 
 
AND psetio () BE
{
///sawritef("psetio entered*n")
///cinabort(1000)
  psetio ()  /// Strange code but possibly OK, since psetio is updated.
  writep := prin
}
 
 
AND param (p) = VALOF
{ LET i, j, r = getbyte (p, 0), 0, FALSE
///sawritef("param: p=%n*n%s*n",p,p)
  { LET b, s = TRUE, TRUE
 n: IF j>=i RESULTIS r
    j := j+1
    SWITCHON getbyte (p, j) INTO
    {
      CASE '-':
        b := FALSE
        GOTO n
      CASE '?':
        s := FALSE
        GOTO n
      CASE 'A':
        r := parama
        IF s DO parama := b
        LOOP
      CASE 'B':
        r := paramb
        IF s DO paramb := b
        LOOP
      CASE 'C':
        r := paramc
        IF s DO paramc := b
        LOOP
      CASE 'D':
        r := paramd
        IF s DO
        { paramd := b
          IF b DO g_load ("PALDD", "PALSYS")
        }
        LOOP
      CASE 'F':
      { LET t = readsn (p, j)
        ((@g0)!t)()
        LOOP
      }
      CASE 'I':
        r := parami
        IF s DO parami := b
        LOOP
      CASE 'J':
        r := paramj
        IF s DO paramj := b
        LOOP
      CASE 'K':
        r := paramk
        IF s DO paramk := b
        LOOP
      CASE 'L':
        r := rch=rch1
        IF s DO rch := b -> rch1, rch0
        LOOP
      CASE 'M':
        r := paramm
        IF s DO paramm := b
        LOOP
      CASE 'N':
        r := paramn
        IF s DO paramn := b
        LOOP
      CASE 'Q':
        r := paramq
        IF s DO paramq := b
        LOOP
      CASE 'R':
        r := kwords+y0
        IF s DO
        { LET t = readsn (p, j) & ~3
          IF t>=1024 DO kwords := t
        }
        LOOP
      CASE 'S':
        r := kstack+y0
        IF s DO
        { LET t = readsn (p, j)
          IF t>=128 DO kstack := t
        }
        LOOP
      CASE 'T':
        r := ssz+y0
        IF s DO ssz := readsn (p, j)
        LOOP
      CASE 'U':
        r := ksq+y0
        IF s DO ksq := readsn (p, j)
        LOOP
      CASE 'V':
        r := paramv
        IF s DO paramv := b
        LOOP
      CASE 'W':
        r := chz+y0
        IF s DO
        { LET t = readsn (p, j)
          IF 20<=t<=132 DO chz := t
        }
        LOOP
      CASE 'Y':
        r := paramy
        IF s DO paramy := b
        LOOP
      CASE 'Z':
        r := paramz
        IF s DO paramz := b
        LOOP
    }
  } REPEAT
}
 
 
AND g_load (s1, s2) = VALOF
 { LET l = load (s1, s2)
 IF l=0
 RESULTIS TRUE
 msg1 (2, s1, l)
 RESULTIS FALSE }
 
 
AND g_unload (s) = VALOF
 { IF unload (s)
 RESULTIS TRUE
 msg0 (2, s)
 RESULTIS FALSE }
 
 
AND end (n) BE
 { tempusp ("Stopping", 0)
 selectoutput (sysout)
 writef ("# %N cycles; %N cons; value %P*N", cycles-y0, cons-y0, arg1)
 stop (n) }
 
 
LET dump (a) = a
 
 
AND undump (a) = a
 
 
.
//./       ADD LIST=ALL,NAME=SYN
 SECTION "SYN"
 
 
GET "pal75hdr"
 
 
STATIC
 { sym = 0
 lprio = 0
 rprio = 0
 s0 = 0
 s1 = 0
 s2 = 0 }
 
 
LET rp () = VALOF
 { LET e1 = e
 { IF rch=rch1
 UNLESS chc=0
 newline ()
 { LET v = readx ()
 IF rch=rch1
 TEST ch='*N'
 rch ()
 ELSE newline ()
 v := eval (v)
 IF v>0 & !v=s_e
 e := v }
 } REPEATUNTIL q_input=0
 ll_sy: e := e1
 RESULTIS arg1
 }
 
 
AND synerror (n) BE
 { writef ("*N*N# Syntax error %N(%N)*N ... ", n, sym)
 UNLESS q_input=0
 { FOR i=1 TO 32
 rch1 ()
 writes (" ...*N") }
 IF paramd
 msg1 (34, synerror)
 q_endread (q_input)
 longjump (flevel (rp), ll_sy) }
 
 
AND checkrpar () BE
 UNLESS sym=s_rpar
 synerror (10)
 
 
AND checkfor (s, n) BE
 UNLESS sym=s
 synerror (n)
 
 
AND ignore () = VALOF
 { LET t = y3
 TEST sym=s_do
 t := y2
 ELSE UNLESS sym=s_then
 RESULTIS t
 rsym (FALSE)
 RESULTIS t }
 
 
AND ignore1 () = VALOF
 { LET t = y3
 TEST sym=s_or
 t := y2
 ELSE UNLESS sym=s_else
 RESULTIS z
 rsym (FALSE)
 RESULTIS t }
 
 
// The symbols ' . are treated funnily
 
 
AND rsym (b) BE // B -> GLOBAL
 { IF ch='*''
 { sym := s_dash
 rch ()
 RETURN }
 WHILE ch='*S' | ch='*N'
 rch ()
 
 { LET alph, alphc = FALSE, FALSE
 s0, s1 := 0, 0
 { TEST 'A'<=ch<='Z'
 alph, alphc := TRUE, TRUE
 ELSE TEST 'a'<=ch<='z'
 alph := TRUE
 ELSE TEST '0'<=ch<='9'
 UNLESS alph
 s1 := s1*10+ch-'0'
 ELSE BREAK
 IF s0=buffl
 synerror (2)
 s0, buffp!s0 := s0+1, rch ()
 } REPEAT
 
 TEST s0>0
 TEST alph
 { !buffp := s0
 s0 := string (buffp)
 IF alphc & h1!s0=z
 { MANIFEST
 { lwc = ~#x40404040 }
 STATIC
 { k2 = 0
 k3 = 0 }
 k2, k3 := h2!s0, h3!s0
 h2!s0, h3!s0 := k2 & lwc, k3 & lwc
 s1 := findword (s0)
 IF s1~=0 & h3!(h2!s1)<0
 { s0 := s1
 GOTO rx }
 h2!s0, h3!s0 := k2, k3
 }
 s0 := name (s0)
 }
 ELSE TEST ch='.' & VALOF
 { LET c = peepch ()
 RESULTIS '0'<=c<='9' }
 { IF s0>numwi
 msg1 (14)
 s1, s2 := FLOAT s1, 0
 { rch ()
 UNLESS '0'<=ch<='9'
 BREAK
 s2 := s2-1
 s1 := s1 #* 10.0 #+ FLOAT (ch-'0') } REPEAT
 IF ch='E'
 { rch ()
 s2 := s2+readn () }
 TEST s2>0
 UNTIL s2=0
 s1 := s1 #* 10.0 <> s2 := s2-1
 ELSE UNTIL s2=0
 s1 := s1 #/ 10.0 <> s2 := s2+1
 sym, s0 := s_flt, getx (s_flt, 0, s1, 0)
 RETURN
 }
 ELSE { sym := s_num
 TEST s0>numwi
 { !buffp := s0
 s0 := number (buffp) }
 ELSE s0 := s1+y0
 RETURN }
 
 ELSE { LET a = getx (s_string, z, 0, 0)
 putbyte (a, str1, rch ())
 putbyte (a, str1+1, ch)
 s0 := findword (a)       // try 2 characters
 TEST s0=0
 { putbyte (a, str1+1, 0)     // or 1 character
 s0 := findword (a)
 IF s0=0
 TEST ch=endstreamch
 { sym := s_fin
 GOTO ll }
 ELSE synerror (3) }
 ELSE rch ()
 }
 }
 
 rx:  s1 := h2!s0
 IF b
 { s0 := s1
 RETURN }
 IF h3!s1>=0
 { sym := s_name
 RETURN }
 mfn := h2!s1
 IF mfn>0
 { LET m3 = h3!mfn
 TEST m3<-1  // funny CODE2 ?
 mfn := m3
 ELSE mfn := h2!mfn }
 lprio, rprio, sym := getbyte (s1, 13)+y0, getbyte (s1, 14)+y0, getbyte (s1, 15)
 
 SWITCHON sym INTO
 {
 DEFAULT: RETURN
 
 ll:  CASE s_fin: q_endread (q_input)
 RETURN
 
 CASE s_infix:
 rsym (FALSE)
 TEST sym=s_dot
 rsym (TRUE)
 ELSE TEST ch='%' { rch()
 s1 := mqu(s1) }
 ELSE { checkfor(s_name,8)
 s1 := s0 }
  mfn :=  ma2
 lprio, rprio, sym := 11+y0, 11+y0, s_diadop
 RETURN
 
 CASE s_q2: s0 := rs ('*"')
 sym := s_string
 RETURN
 
 CASE s_pp: s0 := h2!s1
 RETURN
 
 CASE s_sh1: s1 := rch ()
 SWITCHON s1 INTO
 {
 CASE '*S': UNTIL ch='*N' | ch=endstreamch
 rch ()
 CASE '*N': LOOP
 
 CASE 'b':  CASE 'B': s1 := 2
 GOTO l
 CASE 'o':  CASE 'O': s1 := 8
 GOTO l
 CASE 'x':  CASE 'X': s1 := 16
 l:                     s1 := rbase (s1) & p_addr       // 24 bits
 ENDCASE
 
 CASE '#': s1 := rch ()
 ENDCASE
 CASE 'n':  CASE 'N': s1 := '*N'
 ENDCASE
 CASE 's':  CASE 'S': s1 := '*S'
 ENDCASE
 CASE 'z':  CASE 'Z': s1 := endstreamch
 }
 sym, s0 := s_num, s1+y0
 RETURN
 }} REPEAT
 
 
AND rs (gg) = VALOF
 { LET g = zs
 s0, gg := gg, @gg | signbit       // ??B??  GG = @G-1
 s2 := maxint
 UNTIL ch=s0
 { IF ch=endstreamch
 synerror (16)
 s1 := ch
 IF ch='#'
 { rch ()
 IF ch='*N' | ch='*S'
 { rch () REPEATUNTIL ch='#' | ch=endstreamch
 GOTO l }
 TEST ch='N'|ch='n'
  s1 := '*N'
 ELSE TEST ch='S'|ch='s'
 s1 := '*S'
 ELSE TEST ch='Z'|ch='z'
 s1 := endstreamch
 ELSE s1 := ch
}
 IF s2>str2
 s2, h1!gg, gg := str1, getx (s_string, zsy, 0, 0), h1!gg
 putbyte (gg, s2, s1)
 s2 := s2+1
 l:       rch ()
 }
 rch ()
 UNLESS g=zs
 h1!gg := z
 RESULTIS g
 }
 
 
AND readx () = VALOF
 { LET g, sv = zsy, gseq | signbit
 IF q_input=0
 RESULTIS z
 gseq := @g
 { LET e = rexp (y0)
 UNTIL g=zsy
 { LET g0, a = g, h2!g
 g := h1!g
 IF a=0
 LOOP
 a := linseq (a, z, z, signbit)
 IF a<=0
 a := mqu (a)  // fake
 !g0, h1!g0, h2!g0, h3!g0 := !a, h1!a, h2!a, h3!a }
 gseq := sv
 RESULTIS e
 }
 }
 
 
AND rexq (n) = VALOF    // skip RSYM
 { (-3)!(@n) := rexp
 iv ()
 GOTO ll_rx }
 
 
AND rexp (n) = VALOF
 { IF @n>stackl
 stkover ()
 rsym (FALSE)
 ll_rx: { LET e = z
 SWITCHON sym INTO
 {
 CASE s_let: { LET e1 = @n | signbit   // ??B?? E1=@E-1
 { h1!e1 := mlet (zsy, zsy, zsy)
 e1 := h1!e1
 rdef (y0, e1)
 mlet1 (e1) } REPEATWHILE sym=s_let
 TEST sym=s_in
 { h1!e1 := rexp (y1)
 RESULTIS e }
 ELSE h1!e1 := ze }
 ENDCASE
 CASE s_cond: e := rexp (9+y0)
 { LET e1 = z
 IF sym=s_tuple
 e1 := rexp (9+y0)
 e := cond (e, zsc, e1) }
 ENDCASE
 CASE s_dash: mfn, rprio := mqu, 35+y0  // recover
 CASE s_qu:
 CASE s_retu:
 CASE s_aa:
 CASE s_zz:
 CASE s_null:
 CASE s_dlr: { LET f = mfn
 LET e1 = rexp (rprio)
 e := f (e1) }
 ENDCASE
 CASE s_fclos:
 rsym (FALSE)
 e := rfndef (s_dot+y0, y2)
 ENDCASE
 CASE s_rec: rsym (FALSE)
 { LET e1 = rbvlist (s_dot+y0)
 LET e2 = rfndef (s_dot+y0, y2)
 e := rec (e1, e2) }
 ENDCASE
 CASE s_tuple:
 e := zsc
 ENDCASE
 CASE s_for: rsym (FALSE)
 { LET d = rbv (s_relop+y0)
 LET e1 = rexp (8+y0)
 LET e2, e3, e4 = z, y1, z
 IF sym=s_tuple
 e2 := rexp (8+y0)
 IF sym=s_by
 e3 := rexp (8+y0)
 rprio := ignore ()
 e := rexq (rprio)
 rprio := ignore1 ()
 UNLESS rprio=0
 e4 := rexq (rprio)
 e := mfor (d, e1, e2, e3, e, e4)
 }
 ENDCASE
 CASE s_unless:
 { LET s = TRUE
 ////////////////////IF FALSE
///////////////////// CASE s_if: s := FALSE
 e := rexp (6+y0)
 rprio := ignore ()
 { LET e1 = rexq (rprio)
 LET e2 = z
 rprio := ignore1 ()
 UNLESS rprio=0
 e2 := rexq (rprio)
 IF s
 { s := e1
 e1, e2 := e2, s }
 e := cond (e, e1, e2) }
 }
 ENDCASE
 CASE s_until:
 { LET e1 = TRUE
 //////////////////IF FALSE
 //////////////////CASE s_while: e1 := FALSE
 e := rexp (6+y0)
 IF e1
 e := mnull (e)
 rprio := ignore ()
 e1 := rexq (rprio)
 e := mwhi (e, e1) }
 ENDCASE
 CASE s_diadop:
 { LET f, s = mfn, s1
 LET e1 = rexp (rprio)
 e := f (y0, e1, s) }
 ENDCASE
 CASE s_lpar: e := rexp (y0)
 checkrpar ()
 GOTO m1
 CASE s_dot: IF ch='*S' | ch='*N' | ch=endstreamch
 ENDCASE
 rsym (TRUE)
 CASE s_pp:
 CASE s_num:
 CASE s_flt:
 CASE s_string:
 CASE s_name: e := s0
 CASE s_nil:
 m1:         rsym (FALSE)
 }
 { LET e2 = z
 SWITCHON sym INTO
 {
 CASE s_where:
 IF n>=y2
 DEFAULT:    RESULTIS e
 e2 := mlet (zsy, zsy, zsy)
 rdef (y0, e2)
 mlet1 (e2)
 h1!e2 := e
 e := e2
 LOOP
 CASE s_colon:
 UNLESS !e=s_name
 synerror (7)
 e2 := rexp (n)
 RESULTIS colon (e, e2)
 CASE s_tuple:
 IF n>=8+y0
 RESULTIS e
 e := aug (zsy, e)
 { e2 := rexp (8+y0)
 e := aug (e, e2) } REPEATWHILE sym=s_tuple
 e := revd (e)
 LOOP
 CASE s_cond: IF n>=10+y0
 RESULTIS e
 { LET e1 = rexp (9+y0)
 IF sym=s_tuple
 e2 := rexp (9+y0)
 e := cond (e, e1, e2)
 LOOP }
 CASE s_relop:
 IF n>=lprio
 RESULTIS e
 { LET f, s = mfn, s1
 LET e1 = rexp (rprio)
 e := f (e, e1, s)
 WHILE sym=s_relop
 { LET f, s = mfn, s1
 LET e2 = rexp (rprio)
 LET e3 = f (e1, e2, s)
 e1 := e2
 e := mk_logand (e, e3) } }
 LOOP
 CASE s_diadop:
 IF n>=lprio
 RESULTIS e
 { LET f, s = mfn, s1
 LET e1 = rexp (rprio)
 e := f (e, e1, s) }
 LOOP
 CASE s_dash: { rsym (FALSE)
 e := mdash (e) } REPEATWHILE sym=s_dash
 LOOP
 CASE s_lpar: e2 := rexp (y0)
 checkrpar ()
 GOTO m2
 CASE s_qu:
 CASE s_aa:
 CASE s_zz:
 CASE s_null:
 CASE s_dlr: { LET f = mfn
 LET e1 = rexp (rprio)
 e2 := f (e1) }
 GOTO m3
 CASE s_qr: UNLESS 'A'<=ch<='Z' | 'a'<=ch<='z' | '0'<=ch<='9'
 RESULTIS e
 rsym (TRUE)
 e2, e := e, s0
 GOTO m2
 CASE s_dot: IF ch='*S' | ch='*N' | ch=endstreamch
 RESULTIS e
 rsym (TRUE)
 CASE s_pp:
 CASE s_num:
 CASE s_flt:
 CASE s_string:
 CASE s_name: e2 := s0
 CASE s_nil:
 m2:         rsym (FALSE)
 m3:         e := ap1 (e, e2)
 }} REPEAT
 }}
 
 
AND rdef (n, d) BE
 { rsym (FALSE)
 SWITCHON sym INTO
 {
 CASE s_lpar: rdef (y0, d)
 checkrpar ()
 rsym (FALSE)
 ENDCASE
 DEFAULT: h2!d := rbvlist (s_relop+y0)
 h3!d := rfndef (s_relop+y0, y1)
 ENDCASE
 CASE s_rec: rdef (3+y0, d)
 h3!d := rec (h2!d, h3!d)
 }
 { SWITCHON sym INTO
 {
 CASE s_within:
 IF n>=3+y0
 DEFAULT:    RETURN
 { LET d2, d3 = h2!d, h3!d
 rdef (y0, d)
 n := fn (d2, h3!d)
 h3!d := ap1 (n, d3)
 RETURN }
 CASE s_and: IF n>=6+y0
 RETURN
 { LET d2 = aug (z, h2!d)
 LET d3 = aug (zsy, h3!d)
 { rdef (6+y0, d)
 d2 := aug (d2, h2!d)
 d3 := aug (d3, h3!d) } REPEATWHILE sym=s_and
 h2!d, h3!d := d2, revd (d3)
 }} REPEAT
 }
 }
 
AND rfndef (s, n) = VALOF
 { IF sym=s-y0
 RESULTIS rexp (n)
 { LET d = rbvlist (s)
 IF d=zsc
 RESULTIS rexq (n)
 n := rfndef (s, n)
 RESULTIS fn (d, n) } }
 
 
AND rbv (s) = VALOF
 { IF sym=s-y0
 RESULTIS z
 IF sym=s_tuple
 RESULTIS z
 { LET d = z
 SWITCHON sym INTO
 {
 DEFAULT: RESULTIS zsc
 CASE s_lpar: rsym (FALSE)
 d := rbvlist (s_rpar+y0)
 checkrpar ()
 ENDCASE
 CASE s_dlr: mfn := mdolv
 CASE s_qu:
 CASE s_aa:
 CASE s_zz: { LET f = mfn
 rsym (FALSE)
 d := rbv (s)
 RESULTIS f (d) }
 CASE s_dot: rsym (TRUE)        // but not LAMBDA .a ...
 CASE s_name: d := s0
 CASE s_nil:
 }
 rsym (FALSE)
 WHILE sym=s_dash
 { rsym (FALSE)
 d := mdash (d) }
 RESULTIS d
 }
 }
 
 
AND rbvlist (s) = VALOF
 { LET d = rbv (s)
 UNLESS sym=s_tuple
 RESULTIS d
 d := aug (z, d)
 { rsym (FALSE)
 { LET d1 = rbv (s)
 d := aug (d, d1) } } REPEATWHILE sym=s_tuple
 RESULTIS d }
 
 
.
//./       ADD LIST=ALL,NAME=TRANS
 SECTION "TRANS"
 
 
GET "pal75hdr"
 
 
STATIC
 { sg = 0 }
 
 
LET simname (a) = VALOF
 { IF a>0 & !a=s_name | !a=s_gensy | !a=s_dash
 RESULTIS TRUE
 RESULTIS FALSE }
 
 
AND simtup (a) = VALOF
 { { UNLESS simname (h2!a)
 RESULTIS FALSE
 a := h1!a } REPEATUNTIL a=z
 RESULTIS TRUE }
 
 
AND fn (a, b) = mclos1 (ze, a, b)
 
 
AND rec (a, b) = VALOF
 { LET f = dorec
 IF b<=0
 RESULTIS b
 TEST evsy (b)
 sg := s_reca
 ELSE sg := s_rec
 IF simname (a)
 f := doreca
 RESULTIS get4 (sg, b, a, f) }
 
 
AND mlet (a, b, c) = VALOF
 { IF c<=0
 RESULTIS mseq (b, c)
 TEST evsy (b)
 TEST simname (a)
 sg := s_letb
 ELSE sg := s_leta
 ELSE sg := s_let    // LET2?
 RESULTIS get4 (sg, c, a, b) }
 
 
AND mlet1 (a) BE
 IF evsy (h3!a)
 TEST simname (h2!a)
 !a := s_letb
 ELSE !a := s_leta
 
 
AND retu (a) = get4 (s_retu, 0, a, 0)
 
 
AND mqu (a) = get4 (s_qu, 0, a, 0)
 
 
AND mnull (a) = mk_a1v (a_null, a, null)
 
 
AND mdash (a) = VALOF
 { LET n = y1
 IF a<=0
 RESULTIS y0
 IF !a=s_dash
 { n := h2!a+1
 a := h1!a }
 RESULTIS get4 (s_dash, a, n, difr) }
 
 
AND mdol (a) = VALOF
 { a := mk_zz (a)
 RESULTIS mk_aa (a) }
 
 
AND mdolv (a) = VALOF   // in BV part, it has to be the other way round
 { a := mk_aa (a)
 RESULTIS mk_zz (a) }
 
 
AND mk_aa (a) = get4 (s_aa, 0, a, lvv)
 
 
AND mk_zz (a) = get4 (s_zz, 0, a, iv)   // ?RVV
 
 
// F (EVAL) looks at LVs, but ~F (OCODE) flattens them
 
 
AND matchbv (c, d, f) = VALOF
 { UNLESS f
 IF d>=yloc
 d := h1!d
 IF tyv (d)=a_qu
 { d := h2!d
 UNLESS f
 IF d>=yloc
 d := h1!d }
 { IF c>0
 SWITCHON !c INTO
 {
 CASE s_loc: IF f
 RESULTIS FALSE
 c := h1!c
 LOOP
 CASE s_tuple:
 UNLESS d>0 & !d=s_tuple & h3!c=h3!d
 RESULTIS FALSE
 { UNLESS matchbv (h2!c, h2!d, f)
 RESULTIS FALSE
 c, d := h1!c, h1!d } REPEATUNTIL d=z
 ENDCASE
 CASE s_qu: RESULTIS FALSE
 CASE s_aa:
 CASE s_zz: RESULTIS simname (h2!c)
 }
 RESULTIS TRUE
 } REPEAT
 }
 
 
AND fixap (a) BE
 UNTIL a=z
 { LET a3 = h3!a
 LET s = ap1 (h1!a, h2!a)
 IF s<=0
 msg1 (13, ap1)
 !a, h1!a, h2!a, h3!a := !s, h1!s, h2!s, h3!s
 a := a3 }
 
 
AND ap1 (a, b) = VALOF
 { { LET t = tyv (a)
 TEST t=a_qu
 { LET l, v = ll_ap, h2!a
 IF v<=0
 RESULTIS a
 SWITCHON !v INTO
 {
 CASE s_unset:
 h3!a := get4 (s_apz, a, b, h3!a)
 RESULTIS h3!a
 CASE s_cdy: TEST matchbv (h3!v, b, TRUE)
 l := la_enty
 OR
 CASE s_cdx: l := la_entx
 ENDCASE
 CASE s_aclos:
 RESULTIS mk_a (a, b, v)
 CASE s_codev:
 RESULTIS mk_a1v (a, b, h2!v)
 CASE s_code1:
 RESULTIS mk_a1 (a, b, h2!v)
 CASE s_code2:
 IF b>0 & !b=s_tuple & h3!b=y2
 { LET v3 = h3!v
 IF v3<-1 & v3~=ap2
 RESULTIS (v3)(h2!b, h2!(h1!b), a)
 TEST evsy (b)
 sg := s_a2e
 ELSE sg := s_ap2
 RESULTIS get4 (sg, a, b, h2!v) }
 l := la_apcode2
 ENDCASE
 CASE s_clos2:
 IF b>0 & !b=s_tuple & h3!b=y2
 { TEST evsy (b)
 sg := s_a2a
 ELSE sg := s_aa2
 RESULTIS get4 (sg, a, b, v) }
 l := la_apclos2
 ENDCASE
 CASE s_eclos:
 IF b>0 & !b=s_tuple & h3!b=h3!(h2!v)
 { TEST evsy (b)
 sg := s_aea
 ELSE sg := s_aaa
 RESULTIS get4 (sg, a, b, v) }
 l := la_apeclos
 ENDCASE
 CASE s_fclos:
 l := la_apfclos
 ENDCASE
 CASE s_loc: l := la_aploc
 ENDCASE
 CASE s_tuple:
 l := la_aptup
 ENDCASE
 }
 TEST evsy (b)
 sg := s_aqe
 ELSE sg := s_apq
 RESULTIS get4 (sg, a, b, l)
 }
 ELSE IF t=a_fclos & h1!a=ze
 RESULTIS mlet (h2!a, b, h3!a)
 }
 IF a<=0
 RESULTIS a
 TEST evsy (a) & evsy (b)
 sg := s_apple
 ELSE sg := s_apply
 RESULTIS get4 (sg, a, b, z)
 }
 
 
AND ma2 (a, b, f) = VALOF
 { b := aug (z, b)
 b := aug (b, a)
 RESULTIS ap1 (f, b) }
 
 
AND mk_a (a, b, f) = VALOF
 { TEST evsy (b)
 sg := s_a1a
 ELSE sg := s_aa1
 RESULTIS get4 (sg, a, b, f) }
 
 
AND mk_a1v (a, b, f) = VALOF
 { TEST evsy (b)
 sg := s_ave
 ELSE sg := s_apv
 RESULTIS get4 (sg, a, b, f) }
 
 
AND mk_a1 (a, b, f) = VALOF
 { TEST evsy (b)
 sg := s_a1e
 ELSE sg := s_ap1
 RESULTIS get4 (sg, a, b, f) }
 
 
AND ap2 (a, b, f) = VALOF
 { TEST evsy (a) & evsy (b)
 sg := s_a2e
 ELSE sg := s_ap2
 b := aug (z, b)
 b := aug (b, a)
 RESULTIS get4 (sg, f, b, h2!(h2!f)) }
 
 
AND mclos1 (e, v, f) = VALOF    // ??U??
 { TEST v<=0 // ??Z??
 sg := s_clos
 ELSE TEST simname (v)
 sg := s_aclos
 ELSE TEST !v=s_tuple & simtup (v)
 TEST h3!v=y2
 sg := s_clos2
 ELSE sg := s_eclos
 ELSE sg := s_fclos
 RESULTIS get4 (sg, e, v, f)
 }
 
 
AND mk_aug (a, b, f) = VALOF
 { IF a=z
 RESULTIS aug (z, b)
 RESULTIS ap2 (a, b, f) }
 
 
AND mk_logor (a, b) = mcond (a, TRUE, b)        // nb not destructive
 
 
AND mk_logand (a, b) = mcond (a, b, FALSE)      // nb not destructive
 
 
AND mk_ne (a, b) = VALOF
 { a := ap2 (a, b, a_eq)
 RESULTIS mnull (a) }
 
 
AND mk_ge (a, b) = VALOF
 { a := ap2 (b, a, a_gt)
 RESULTIS mnull (a) }
 
 
AND mk_lt (a, b) = ap2 (b, a, a_gt)
 
 
AND mk_le (a, b) = VALOF
 { a := ap2 (a, b, a_gt)
 RESULTIS mnull (a) }
 
 
AND mk_plus (a, b, f) = VALOF
 { IF a=y0
 RESULTIS b
 IF b=y0
 RESULTIS a
 IF arithv(a)&arithv(b) RESULTIS add(a,b)
 RESULTIS ap2 (a, b, f) }
 
 
AND mk_minu (a, b, f) = VALOF
 { IF b=y0
 RESULTIS a
 IF arithv(a) & arithv (b)
 RESULTIS minu (a,b)
 RESULTIS ap2 (a, b, f) }
 
 
AND mk_mul (a, b, f) = VALOF
 { IF a=y0 | b=y0
 RESULTIS y0
 IF a=y1
 RESULTIS b
 IF b=y1
 RESULTIS a
 IF arithv(a) & arithv (b)
 RESULTIS mul (a,b)
 RESULTIS ap2 (a, b, f)
 }
 
 
AND mk_div (a, b, f) = VALOF
 { IF arithv (a) & arithv (b)
 RESULTIS div (a, b)
 IF a=y0
 RESULTIS y0
 IF b=y1
 RESULTIS a
 RESULTIS ap2 (a, b, f) }
 
 
AND mk_pow (a, b, f) = VALOF
 {
 IF arithv(a)&arithv(b) RESULTIS pow(a,b)
 IF b=y0
 RESULTIS y1
 IF b=y1 | a=y0 | a=y1
 RESULTIS a
 RESULTIS ap2 (a, b, f) }
 
 
AND mwhi (e, f) = VALOF         // (REC A NIL. [E] -> [F] <> A NIL) NIL
 { LET a = asym (y0)
 { LET k = ap1 (a, z)
 f := seq (f, k) }
 e := cond (e, f, z)
 e := fn (z, e)
 e := rec (a, e)
 RESULTIS ap1 (e, z) }
 
 
AND mfor (i, l, r, s, f, v) = VALOF
 { LET a = asym (y0)
 IF r=z
 { IF s=y1     // (REC A B. (FN I. I -> [F] <> A(B+1), [V])(L B)) 1
 { { LET b = asym (ym)
 { LET k = mk_plus (b, y1, a_plus)
 k := ap1 (a, k)
 f := seq (f, k) }
 f := cond (i, f, v)
 f := fn (i, f)
 l := ap1 (l, b)
 f := ap1 (f, l)
 f := fn (b, f) }
 f := rec (a, f)
 RESULTIS ap1 (f, y1)
 }
// (REC A I. I -> [F] <> A S, [V]) L
 s := ap1 (a, s)
 f := seq (f, s)
 f := cond (i, f, v)
 f := fn (i, f)
 f := rec (a, f)
 RESULTIS ap1 (f, l)
 }
// (REC A I. I <=/>= R -> [F] <> A(I+S), [V]) L
 { LET k = mk_plus (i, s, a_plus)
 k := ap1 (a, k)
 f := seq (f, k)
 TEST gtv (s, y0)
 k := mk_le
 ELSE k := mk_ge
 k := k (i, r)
 f := cond (k, f, v) }
 f := fn (i, f)
 f := rec (a, f)
 RESULTIS ap1 (f, l)
 }
 
 
AND mcolon (a, b) = VALOF
 { LET b1 = b
 WHILE b1>0 & !b1=s_colon
 b1 := h2!b1
 IF b1<=0 | a<=0
 RESULTIS b
 RESULTIS get4 (s_colon, a, b, b1) }
 
 
AND mseq (e, f) = VALOF
 { IF e<=0
 RESULTIS f
 { LET f2 = f
 WHILE f2>0 & !f2=s_colon
 f2 := h2!f2
 TEST evsy (e) & evsy (f2)
 sg := s_seqa
 ELSE sg := s_seq
 e := get4 (sg, e, f2, z)
 UNTIL f=f2
 { e := get4 (s_colon, h1!f, e, h3!f)
 f := h2!f }
 RESULTIS e
 }
 }
 
 
AND mcond (a, b, c) = VALOF
 { WHILE a>0 & h3!a=null & (!a=s_apv | !a=s_ave)
 { LET t = b
 b, c := c, t
 a := h2!a }
 { LET b2, c2 = b, c
 WHILE b2>0 & !b2=s_colon
 b2 := h2!b2
 WHILE c2>0 & !c2=s_colon
 c2 := h2!c2
 TEST a<=0
 TEST a<0
 a := b
 ELSE a := c
 ELSE { TEST evsy (a)
 TEST evsy (b2) & evsy (c2)
 sg := s_condb
 ELSE sg := s_conda
 ELSE sg := s_cond
 a := get4 (sg, a, b2, c2) }
 UNTIL b=b2
 { a := get4 (s_colon, h1!b, a, h3!b)
 b := h2!b }
 UNTIL c=c2
 { a := get4 (s_colon, h1!c, a, h3!c)
 c := h2!c }
 RESULTIS a
 }
 }
 
 
AND colon (a, b) = VALOF
 { IF a<=0
 RESULTIS b
 IF b>0 & !b=s_mb
 { h2!b := get4 (s_colon, a, h2!b, 0)
 RESULTIS b }
 b := get4 (s_colon, a, b, 0)
 b := get4 (s_mb, !gseq, b, 0)
 !gseq := b
 RESULTIS b }
 
 
AND seq (a, b) = VALOF
 { IF a<=0
 RESULTIS b
 IF !a=s_mb
 { IF b>0 & !b=s_mb
 { LET b0 = b
 b := h2!b
 h2!b0 := 0 }
 h2!a := get4 (s_seq, h2!a, b, 0)
 RESULTIS a }
 IF b>0 & !b=s_mb
 { h2!b := get4 (s_seq, a, h2!b, 0)
 RESULTIS b }
 a := get4 (s_seq, a, b, 0)
 a := get4 (s_mb, !gseq, a, 0)
 !gseq := a
 RESULTIS a
 }
 
 
AND cond (a, b, c) = VALOF
 { IF a<=0
 a := get4 (s_seq, z, a, 0)     // fake
 IF !a=s_mb
 { IF b>0 & !b=s_mb
 { LET b0 = b
 b := h2!b
 h2!b0 := 0 }
 IF c>0 & !c=s_mb
 { LET c0 = c
 c := h2!c
 h2!c0 := 0 }
 h2!a := get4 (s_cond, h2!a, b, c)
 RESULTIS a
 }
 IF b>0 & !b=s_mb
 { IF c>0 & !c=s_mb
 { LET c0 = c
 c := h2!c
 h2!c0 := 0 }
 h2!b := get4 (s_cond, a, h2!b, c)
 RESULTIS b }
 IF c>0 & !c=s_mb
 { h2!c := get4 (s_cond, a, b, h2!c)
 RESULTIS c }
 a := get4 (s_cond, a, b, c)
 a := get4 (s_mb, !gseq, a, 0)
 !gseq := a
 RESULTIS a
 }
 
 
AND linseq (a, e, f, x) = VALOF
 { IF @a>stackl
 stkover ()
 { IF a>0
 SWITCHON !a INTO
 {
 CASE s_seq:
 CASE s_seqa: e := linseq (h2!a, e, f, x)
 a, x := h1!a, FALSE
 LOOP
 CASE s_cond:
 CASE s_conda:
 CASE s_condb:
 f := linseq (h3!a, e, f, x)
 e := linseq (h2!a, e, f, x)
 a, x := h1!a, TRUE
 LOOP
 CASE s_colon:
 e := linseq (h2!a, e, f, x)
 RESULTIS mcolon (h1!a, e)
 CASE s_mb: msg1 (-1)        // ?D
 }
 IF x=signbit
 RESULTIS a
 TEST x
 RESULTIS mcond (a, e, f)
 ELSE RESULTIS mseq (a, e)
 } REPEAT
 }
 
 
.
//./       ENDUP

