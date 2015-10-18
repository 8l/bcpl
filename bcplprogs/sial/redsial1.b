SECTION "redsial"

GET "libhdr"

MANIFEST
$(
// sial opcodes and directives
f_lp=     1
f_lg=     2
f_ll=     3

f_llp=    4
f_llg=    5
f_lll=    6
f_lf=     7
f_lw=     8

f_l=      10
f_lm=     11

f_sp=     12
f_sg=     13
f_sl=     14

f_ap=     15
f_ag=     16
f_a=      17
f_s=      18

f_lkp=    20
f_lkg=    21
f_rv=     22
f_rvp=    23
f_rvk=    24
f_st=     25
f_stp=    26
f_stk=    27
f_stkp=   28
f_skg=    29
f_xst=    30

f_k=      35
f_kpg=    36

f_neg=    37
f_not=    38
f_abs=    39

f_xdiv=   40
f_xrem=   41
f_xsub=   42

f_mul=    45
f_div=    46
f_rem=    47
f_add=    48
f_sub=    49

f_eq=     50
f_ne=     51
f_ls=     52
f_gr=     53
f_le=     54
f_ge=     55
f_eq0=    56
f_ne0=    57
f_ls0=    58
f_gr0=    59
f_le0=    60
f_ge0=    61

f_lsh=    65
f_rsh=    66
f_and=    67
f_or=     68
f_xor=    69
f_eqv=    70

f_gbyt=   74
f_xgbyt=  75
f_pbyt=   76
f_xpbyt=  77

f_swb=    78
f_swl=    79

f_xch=    80
f_atb=    81
f_atc=    82
f_bta=    83
f_btc=    84
f_atblp=  85
f_atblg=  86
f_atbl=   87

f_j=      90
f_rtn=    91
f_goto=   92

f_ikp=    93
f_ikg=    94
f_ikl=    95
f_ip=     96
f_ig=     97
f_il=     98

f_jeq=    100
f_jne=    101
f_jls=    102
f_jgr=    103
f_jle=    104
f_jge=    105
f_jeq0=   106
f_jne0=   107
f_jls0=   108
f_jgr0=   109
f_jle0=   110
f_jge0=   111
f_jge0m=  112

f_brk=    120
f_nop=    121
f_chgco=  122
f_mdiv=   123
f_sys=    124

f_section=  130
f_modstart= 131
f_modend=   132
f_global=   133
f_string=   134
f_const=    135
f_static=   136
f_mlab=     137
f_lab=      138
f_lstr=     139
f_entry=    140
$)

GLOBAL $(
sialin:   200
codeout:  201
stdin:    202
stdout:   203
error:    204

rdf:      210
rdp:      211
rdg:      212
rdk:      213
rdw:      215
rdl:      216
rdm:      217
rdc:      218
rdcode:   219
wrcode:   220

scan:     230
cvf:      231
cvfp:     232
cvfg:     233
cvfk:     234
cvfkl:    235
cvfw:     236
cvfl:     237
cvfm:     238

mkstream: 240

code:     245
codep:    246
codet:    247
codeword: 249
bitcount: 250
initpack: 251

Fstr:     253
Pstr:     254
Gstr:     255
Kstr:     256
Wstr:     258
Cstr:     259
Lstr:     260
Mstr:     261

labmax:   270
mlabmax:  271

statv:    280
statd:    281
statp:    282
debug:    283
debuglet: 284
stats:    285
wrstats:  286

curcode:  289

totalbits:290
$)


MANIFEST {
c_next=  0
c_a=     1
c_b=     2
c_c=     3
c_l=     4
c_m=     5
c_g=     6
c_add=   7
c_sub=   8
c_v=     9
c_lw=   10
c_rep=  11

s_packfn=   0
s_a=        1
s_b=        2
s_c=        3
s_items=   10
s_totlen=  11
s_letter=  12
s_buf=     13
s_upb=     s_buf

t_chunk=   2000
}

LET pack(s, val) = (s!s_packfn)(s, val)

LET stuff(s, bits, len) BE
{ totalbits := totalbits + len // Stats gathering
  s_totlen!s := s_totlen!s + len
  s_items!s := s_items!s + 1
  stuffP(s, bits, len)
}

AND initpack() BE codeword, bitcount, totalbits := 0, 0, 0

AND wrbyte(byte) BE { code%codep := byte
                      codep := codep+1
                     }

AND stuffP(s, bits, len) BE
{ IF (debug&1)=1 DO
  { writebin(bits, len)
    newline()
  }
  IF len>24 DO
  { stuffP(s, bits&255, 8)
    bits, len := bits>>8, len-8
  }
  // len is now <= 24, so there is romm in codeword
  codeword := codeword + (bits<<bitcount)
  bitcount := bitcount + len
  UNTIL bitcount<8 DO
  { wrbyte(codeword & 255)
    codeword, bitcount := codeword>>8, bitcount-8
  }
  UNLESS (totalbits+8-bitcount) REM 8 = 0 DO abort(887)
}

AND flushcodeword() BE
// The bit stream is rounded up to a byte boundary by the addition
// of 1 to 8 bits: 1, 10, 100, ... 10000000
{ UNTIL totalbits REM 8 = 7 DO stuff(Fstr, 0, 1)
  stuff(Fstr, 1, 1)
}

LET packW(s, val) BE
{ //            11 =>      PREV
  //            01 =>       INC
  //  <3-bits>  10 =>   <3-bit>
  //  <8-bits> 100 =>  <8-bits>
  // <16-bits>1000 => <16-bits>
  // <32-bits>0000 => <32-bits>

  LET a = s_a!s
  s_a!s := val

  IF val=a DO         { stuff(s,              #b11,  2); RETURN }
  IF val=a+1 DO       { stuff(s,              #b01,  2); RETURN }
  IF val>=0 DO
  { IF val<=7 DO      { stuff(s, (val<<2) +   #b10,  5); RETURN }
    IF val<=#xFF DO   { stuff(s, (val<<3) +  #b100, 11); RETURN }
    IF val<=#xFFFF DO { stuff(s, (val<<4) + #b1000, 20); RETURN }
  }
  stuff(s, #b0000, 4)
  stuff(s, val, 32)
}

AND mtf(val, buf, upb) = VALOF
{ FOR p = 0 TO upb IF buf!p=val DO
  { FOR q = p TO 1 BY -1 DO buf!q := buf!(q-1)
    buf!0 := val
    RESULTIS p
  }
  RESULTIS -1
}

AND initfntab(buf, upb) BE
{ LET fv = TABLE
           f_kpg,      f_sp,      f_l,      f_lp,
           f_lab,      f_lg,      f_rtn,    f_lkp,
           f_sg,       f_j,       f_atbl,   f_atblp,
           f_atblg,    f_jeq0,    f_lstr,   f_jne,  
           f_entry,    f_jgr,     f_jne0,   f_string,
           f_lm,       f_jle,     f_ap,     f_jeq,   
           f_s,        f_ikg,     f_lkg,    f_ikp,   
           f_jls,      f_atb,     f_stkp,   f_a,     
           f_atc,      f_jle0,    f_bta,    f_jls0,  
           f_skg,      f_pbyt,    f_gbyt,   f_xsub,
           f_swl,      f_rvp,     f_lf,     f_jge,   
           f_and,      f_sub,     f_neg,    f_swb,   
           f_mul,      f_div,     f_jge0,   f_stk,   
           f_jgr0,     f_xch,     f_rsh,    f_llg,   
           f_ag,       f_not,     f_k,      f_rv,    
           f_llp,      f_or,      f_rem,    f_xst,   
           f_stp,      f_section, f_st,     f_xgbyt, 
           f_ll,       f_lll,     f_lw,     f_sl,
           f_rvk,      f_abs,     f_xdiv,   f_xrem,
           f_add,      f_eq,      f_ne,     f_ls,
           f_gr,       f_le,      f_ge,     f_eq0,
           f_ne0,      f_ls0,     f_gr0,    f_le0,
           f_ge0,      f_lsh,     f_xor,    f_eqv,
           f_xpbyt,    f_btc,     f_goto,   f_ikl,
           f_ip,       f_ig,      f_il,     f_jge0m,
           f_modstart, f_modend,  f_global, f_const,
           f_static,   f_mlab,
           f_brk,      f_nop,     f_chgco,  f_mdiv,
           f_sys,      0

  LET p = 0
  WHILE fv!p DO
  { IF p>upb DO abort(1234)
    buf!p := fv!p
    p := p+1
  }
}

AND packF(s, val) BE
// Look val up in MTF buffer giving position p
// then encode p
{ MANIFEST { upb=127 }
  
  LET buf = s_buf!s
  LET pos = ?

  IF buf=0 DO 
  { buf := getvec(upb)
    initfntab(buf, upb)
    s_buf!s := buf
  }

  pos := mtf(val, buf, upb)

  IF pos <0 DO abort(1234)

  IF pos<8 DO
  { stuff(s, (pos<<1) | #b0, 4)    //  <3-bits> 0 => <3-bits>
    RETURN
  }
  stuff(s, (pos-8)<<1 | #b1, 8)    //  <7-bits> 1 => <7-bits> + 8
}


AND packP(s, val) BE
{ SWITCHON val INTO
  { DEFAULT: ENDCASE
    CASE  3: stuff(s,      #b01, 2); RETURN
    CASE  4: stuff(s,      #b11, 2); RETURN
    CASE  5: stuff(s,    #b0010, 4); RETURN
    CASE  6: stuff(s,    #b0110, 4); RETURN
    CASE  7: stuff(s,    #b1010, 4); RETURN
    CASE  8: stuff(s,    #b1110, 4); RETURN
    CASE  9: stuff(s,   #b00100, 5); RETURN
    CASE 10: stuff(s,   #b01100, 5); RETURN
    CASE 11: stuff(s,   #b10100, 5); RETURN
    CASE 12: stuff(s,   #b11100, 5); RETURN
    CASE 13: stuff(s,  #b001000, 6); RETURN
    CASE 14: stuff(s,  #b011000, 6); RETURN
    CASE 15: stuff(s,  #b101000, 6); RETURN
    CASE 16: stuff(s,  #b111000, 6); RETURN
    CASE 17: stuff(s, #b0010000, 7); RETURN
    CASE 18: stuff(s, #b0110000, 7); RETURN
    CASE 19: stuff(s, #b1010000, 7); RETURN
    CASE 20: stuff(s, #b1110000, 7); RETURN
  }

  IF 21<=val<=21+63 DO
  { stuff(s, (val-21<<6) + #b100000, 12)
    RETURN
  }

  IF 1<=val<=#xFFFFFF DO
  { stuff(s, (val<<6) + #b000000, 30)
    RETURN
  }

  error("Unable to stuff bits=%n in P stream*n", val)  
}

AND packG(s, val) BE
{ LET buf, a = s_buf!s, ?

// <12-bit> 00000  L <12-bit>
//      ddd 10000  INC2BUF ddd+1
//      ddd 01000  SUB ddd+1
//      ddd 11000  ADD ddd+1
//      ddd  0100  DEC2BUF ddd+1
//      ddd  1100  DECBUF ddd+1
//      ddd  0010  INCBUF ddd+1
//           1010  BUF2
//  <9-bit>   110  L <9-bit>
//            001  BUF0
//      ddd   101  BUF ddd+3
//             11  BUF1

  IF buf=0 DO 
  { buf := getvec(10)
    FOR i = 0 TO 10 DO buf!i := i
    s_buf!s := buf
  }

//writef("packG: ")
//FOR i = 0 TO 10 DO writef("G%n ", buf!i)
//writef("*nG%n*n", val)
  
  a := buf!0
  IF val=a DO                                      // BUF0 
  { stuff(s, #b001, 3)
//stats(0)
    RETURN
  }

  IF val=buf!1 DO
  { stuff(s, #b11, 2)                              // BUF1
//stats(1000)
    buf!0, buf!1 := val, a
    RETURN
  }

  IF val=buf!2 DO
  { stuff(s, #b1010, 4)                            // BUF2
//stats(2000)
    buf!2 := buf!1
    buf!0, buf!1 := val, a
    RETURN
  }

  FOR p = 3 TO 10 IF val=buf!p DO
  { stuff(s, (p-3)<<3 | #b101, 6)                  // BUF3 - BUF10
//stats(3000)//+p-3)
    FOR i = p TO 1 BY -1 DO buf!i := buf!(i-1)
    buf!0 := val
    RETURN
  }

  FOR p = 1 TO 8 IF val=buf!p+1 DO
  { stuff(s, (p-1)<<4 | #b0010, 7)                 // INCBUF1 - INCBUF8 
//stats(4000)//+p-1)
    FOR i = p TO 1 BY -1 DO buf!i := buf!(i-1)
    buf!0 := val
    RETURN
  }

  FOR p = 1 TO 8 IF val=buf!p-1 DO
  { stuff(s, (p-1)<<4 | #b1100, 7)                 // DECBUF1 - DECBUF8 
//stats(5000)//+p-1)
    FOR i = p TO 1 BY -1 DO buf!i := buf!(i-1)
    buf!0 := val
    RETURN
  }

  FOR p = 1 TO 8 IF val=buf!p+2 DO
  { stuff(s, (p-1)<<5 | #b10000, 8)                 // INC2BUF1 - INC2BUF8 
//stats(6000)//+p-1)
    FOR i = p TO 1 BY -1 DO buf!i := buf!(i-1)
    buf!0 := val
    RETURN
  }

  FOR p = 1 TO 8 IF val=buf!p-2 DO
  { stuff(s, (p-1)<<4 | #b0100, 7)                 // DEC2BUF1 - DEC2BUF8 
//stats(7000)//+p-1)
    FOR i = p TO 1 BY -1 DO buf!i := buf!(i-1)
    buf!0 := val
    RETURN
  }

  IF a-8<=val<=a+8 DO
  { IF a>val DO { stuff(s, (a-val-1)<<5 | #b01000, 8) // SUB 1 - 8
//                  stats(8000)//+a-val-1)
                }
    IF a<val DO { stuff(s, (val-a-1)<<5 | #b11000, 8) // ADD 1 - 8
//                  stats(9000)//+val-a-1)
                }
    FOR i = 10 TO 1 BY -1 DO buf!i := buf!(i-1)
    buf!0 := val
    RETURN
  }

  IF 0<=val<=#x1FF DO
  { stuff(s, val<<3 | #b110, 12)                   // L <9-bit>
//stats(10000)//+val)
    FOR i = 10 TO 1 BY -1 DO buf!i := buf!(i-1)
    buf!0 := val
    RETURN
  }  

  IF 0<val<=#xFFF DO
  { stuff(s, val<<5 | #b00000, 17)                   // L <12-bit>
//stats(11000)//+val)
    FOR i = 10 TO 1 BY -1 DO buf!i := buf!(i-1)
    buf!0 := val
    RETURN
  }  

  error("Unable to stuff bits=%n in G stream*n", val)
}

LET packK(s, val) BE
// <24-bits>0000000   -<24-bits>       -FFFFFF to 0
// <24-bits>1000000    <24-bits>             0 to FFFFFF
//  <16-bits>100000    <16-bits>             0 to FFFF
//    <8-bits>10000    <8-bits> + 118      118 to 373
//             1000    3                        3
//              100    2                        2
//              010    1                        1
//              110    0                        0
//       <7-bits>01    <7-bits> -  10      -10 to 117
//       <3-bits>11    <3-bits> +   4        4 to  11

{ SWITCHON val INTO
  { DEFAULT: ENDCASE
    CASE  0: stuff(s,       #b110,  3); RETURN
    CASE  1: stuff(s,       #b010,  3); RETURN
    CASE  2: stuff(s,       #b100,  3); RETURN
    CASE  3: stuff(s,      #b1000,  4); RETURN
  }
  IF 4<=val<=4+7 DO
  { stuff(s, ((val-4)<<2)+#b11, 5)
    RETURN
  }
  IF -10<=val<=-10+127 DO
  { stuff(s, (val+10<<2)+#b01, 9)
    RETURN
  }
  IF 118<=val<=118+255 DO
  { stuff(s, ((val-118)<<5)+#b10000, 13)
    RETURN
  }
  IF 0<=val<=#xFFFF DO
  { stuff(s, (val<<6)+#b100000, 22)
    RETURN
  }
  IF 0<=val<=#xFFFFFF DO
  { stuff(s, (val<<7)+#b1000000, 31)
    RETURN
  }
  IF -#xFFFFFF<=val<=0 DO
  { stuff(s, (-val<<7)+#b0000000, 31)
    RETURN
  }

  error("Unable to stuff bits=%n in K stream*n", val)
}


AND packL(s, val) BE
//                1     a +   1
//              010     a
//  <6-bits>    100     a -  32 + <6-bits>
//  <9-bits>   1000     a - 255 + <9-bits>
//             0110     a -   1
//             1110     b +   1
//            10000     b
//           100000     a +   2
// <16-bits> 000000     <16-bits>

{ LET a, b = s_a!s, s_b!s    // last two different values
IF (debug&32)=32 DO writef("packL: a=%n b=%n*n", a, b)
  IF val=a DO 
  { stuff(s, #b010, 3)                      // a
    RETURN
  }

  s_b!s := a
  s_a!s := val

  IF val=a+1 DO
  { stuff(s, #b1, 1)                         // a+1
    RETURN
  }
  IF val=a-1 DO
  { stuff(s, #b0110, 4)                      // a-1
    RETURN
  }
  IF val=b+1 DO
  { stuff(s, #b1110, 4)                      // b+1
    RETURN
  }
  IF val=b DO
  { stuff(s, #b10000, 5)                     // b
    RETURN
  }  
  IF val=a+2 DO
  { stuff(s, #b100000, 6)                    // a+2
    RETURN

  }
  IF a-32<=val<=a-32+63 DO
  { stuff(s, (val-a+32)<<3 | #b100, 9)       // a-32 + <6-bits>
    RETURN
  }
  IF a-255<=val<=a-255+511 DO
  { stuff(s, (val-a+255)<<4 | #b1000, 13)    // a-255 + <9-bits>
    RETURN
  }
  IF 0<=val<=#xFFFF DO
  { stuff(s, val<<5 | #b000000, 22)          // 0 - FFFF
    RETURN
  }  

  error("Unable to stuff bits=%n in L stream*n", val)
}

AND packC(s, val) BE
//  If val a letter in the other shift make letter UC
//  else make letter LC
//  Do MTF encoding
//  then encode as follows:
//  <3-bits>  1   0-7
//  <4-bits> 10   8-23
//  <8-bits> 00   <8-bits>
{ LET buf = s_buf!s
  LET p = 0
  IF buf=0 DO
  { LET str = " abcdefghijklmnopqrstuvwxyz0123456789%*n"
    buf := getvec(255)
    IF buf=0 DO abort(9999)
    FOR i= 0 TO 255 DO buf!i := i // The MTF buffer
    FOR i = str%0 TO 1 BY -1 DO
    { LET ch = str%i
      p := 0
      UNTIL buf!p=ch DO p := p+1
      WHILE p>0 DO { buf!p := buf!(p-1); p := p-1 }
      buf!0 := ch
    }
    s_buf!s := buf
    s_a!s := 0 // Last letter was lowercase
  }
  TEST 'a'<=val<='z'
  THEN UNLESS s_a!s=0 DO s_a!s, val := 0, val-'a'+'A'
  ELSE IF 'A'<=val<='Z' TEST s_a!s=0
                        THEN s_a!s := 1
                        ELSE val := val-'A'+'a'
  p := 0
  UNTIL buf!p=val DO p := p+1

//  writef("p=%n*n", p)
  FOR i=p TO 1 BY -1 DO buf!i := buf!(i-1)
  buf!0 := val
//  FOR i = 0 TO 30 DO writef("%c", buf!i)
//  newline()
  IF p<8 DO   { stuff(s,     (p<<1) +  #b1,  4); RETURN }
  IF p<24 DO  { stuff(s, ((p-8)<<2) + #b10,  6); RETURN }
  IF p<256 DO { stuff(s,     (p<<2) + #b00, 10); RETURN }
  error("Trouble in packC*n")
  abort(9999)
}

AND mkstream(packfn, letter) = VALOF
{ LET s = getvec(s_upb)
  IF s=0 DO error("Unable to make a stream")
  FOR i = 0 TO s_upb DO s!i := 0
  s_packfn!s := packfn
  s_letter!s := letter
  RESULTIS s
}

AND unmkstream(str) BE UNLESS str=0 DO
{ UNLESS s_buf!str=0 DO freevec(s_buf!str)
  freevec(str)
}
 
AND openstreams() BE
{ Fstr := mkstream(packF, 'F')
  Pstr := mkstream(packP, 'P')
  Gstr := mkstream(packG, 'G')
  Kstr := mkstream(packK, 'K')
  Wstr := mkstream(packW, 'W')
  Cstr := mkstream(packC, 'C')
  Lstr := mkstream(packL, 'L')
  Mstr := mkstream(packL, 'M')
}

AND closestreams() BE
{ unmkstream(Fstr); Fstr := 0
  unmkstream(Pstr); Pstr := 0
  unmkstream(Gstr); Gstr := 0
  unmkstream(Kstr); Kstr := 0
  unmkstream(Wstr); Wstr := 0
  unmkstream(Cstr); Cstr := 0
  unmkstream(Lstr); Lstr := 0
  unmkstream(Mstr); Mstr := 0
}

LET start() = VALOF
$( LET argv = VEC 20

   codeout := 0
   stdout := output()
   IF rdargs("FROM,TO/K,DEBUG/K", argv, 20)=0 DO
   $( writes("Bad args for redsial*n")
      RESULTIS 20
   $)
   IF argv!0=0 DO argv!0 := "bcpl.sial"
   IF argv!1=0 DO argv!1 := "CODE"

   TEST argv!2=0
   THEN debug := 0
   ELSE debug := str2numb(argv!2)

   IF debug DO writef("Debugging bits %b6*n", debug)

   debuglet := 'Z'

   sialin := findinput(argv!0)
   IF sialin=0 DO
   $( writef("Trouble with file %s*n", argv!0)
      RESULTIS 20
   $)
   codeout := findoutput(argv!1)
   
   IF codeout=0 DO
   $( writef("Trouble with file %s*n", argv!1)
      RESULTIS 20
   $)
   
   writef("Reducing sial %s to %s*n", argv!0, argv!1)
   selectinput(sialin)
   selectoutput(codeout)

   code := getvec(50000)
   
   IF code=0 DO
   $( writef("Unable to allocate code vector*n")
      RESULTIS 20
   $)
   codep, codet := 0, 50000*bytesperword
   labmax, mlabmax := 0, 0 

   statv, statd, statp := getvec(50000), getvec(50000), 0

   initpack()
   scan()
   UNLESS codeout=stdout DO endwrite()

   selectoutput(stdout)
//   wrstats()
   freevec(statv)
   freevec(statd)

   freevec(code)
   endread()

   writef("Conversion complete, total length %n bytes*n", totalbits/8)
   RESULTIS 0
$)

// argument may be of form Ln
AND rdcode(let) = VALOF
$( LET a, ch, neg = 0, ?, FALSE

   ch := rdch() REPEATWHILE ch='*s' | ch='*n'

   IF ch=endstreamch RESULTIS -1

   UNLESS ch=let DO error("Bad item, looking for %c found %c*n", let, ch)

   ch := rdch()

   IF ch='-' DO { neg := TRUE; ch := rdch() }

   WHILE '0'<=ch<='9' DO $( a := 10*a + ch - '0'; ch := rdch()  $)

   IF neg DO a := -a

// IF let=debuglet DO stats(a)
/*
   IF debug & let=debuglet SWITCHON let INTO
   { DEFAULT:                      ENDCASE
     CASE 'F': wrfcode(a);         ENDCASE
     CASE 'P': writef("P%i3 ", a); ENDCASE
     CASE 'G': writef("G%i3 ", a); ENDCASE
     CASE 'K': writef("K%i6 ", a); ENDCASE
     CASE 'W': writef("W%i9 ", a); ENDCASE
     CASE 'C': TEST a<=32 
               THEN writef("%i2 ", a)
               ELSE writef(" %c ", a)
               ENDCASE
     CASE 'L': writef("L%i4 ", a); ENDCASE
     CASE 'M': writef("M%i3 ", a); ENDCASE
   }
*/
   IF (debug&2)=2 DO writef("%c%n*n", let, a)
   curcode := a
   RESULTIS a
$)

AND rdf() = rdcode('F')
AND rdp() = rdcode('P')
AND rdg() = rdcode('G')
AND rdk() = rdcode('K')
AND rdw() = rdcode('W')
AND rdl() = VALOF
{ LET lab = rdcode('L')
  IF labmax<lab DO labmax := lab
  RESULTIS lab
}
AND rdm() = VALOF
{ LET mlab = rdcode('M')
  IF mlabmax<mlab DO mlabmax := mlab
  RESULTIS mlab
}
AND rdc() = rdcode('C')

AND stats(a) BE
{ statp := statp + 1
//  statv!statp := capitalch(a)
//writef("Stats: %n*n", a)
    statv!statp := a
}

AND wrstats() BE
{ LET p, q, i, total = 0, 0, 1, 0

//  writef("Statistics:*n")

  sort(statv, statd, statp, cmp1)

  WHILE i<statp DO
  { LET val = statv!i
    LET count = 0

    i, count := i+1, count+1 REPEATWHILE i<=statp & val=statv!i

    q := q+1
    statv!q, statd!q := val, count
  }
  
  sort(statv, statd, q, cmp2)

  FOR i = 1 TO q DO
  { total := total + statd!i
//    writef("'%c'", statv!i)
//    writef("P%i5", statv!i)
//    writef("K%i7", statv!i)
//    writef("L+%i7", statv!i)
//    writef("G+%i7", statv!i)
//    wrfcode(statv!i)
//    writef("  %i6  freq %i4  Total %i5*n", statv!i, statd!i, total)
  }
}

AND wrfcode(f) BE
$( LET s = VALOF SWITCHON f INTO
   $( DEFAULT:       RESULTIS "-"

      CASE 200:      RESULTIS "PRED"

      CASE f_lp:     RESULTIS "LP"
      CASE f_lg:     RESULTIS "LG"
      CASE f_ll:     RESULTIS "LL"

      CASE f_llp:    RESULTIS "LLP"
      CASE f_llg:    RESULTIS "LLG"
      CASE f_lll:    RESULTIS "LLL"
      CASE f_lf:     RESULTIS "LF"
      CASE f_lw:     RESULTIS "LW"

      CASE f_l:      RESULTIS "L"
      CASE f_lm:     RESULTIS "LM"

      CASE f_sp:     RESULTIS "SP"
      CASE f_sg:     RESULTIS "SG"
      CASE f_sl:     RESULTIS "SL"

      CASE f_ap:     RESULTIS "AP"
      CASE f_ag:     RESULTIS "AG"
      CASE f_a:      RESULTIS "A"
      CASE f_s:      RESULTIS "S"

      CASE f_lkp:    RESULTIS "LKP"
      CASE f_lkg:    RESULTIS "LKG"
      CASE f_rv:     RESULTIS "RV"
      CASE f_rvp:    RESULTIS "RVP"
      CASE f_rvk:    RESULTIS "RVK"
      CASE f_st:     RESULTIS "ST"
      CASE f_stp:    RESULTIS "STP"
      CASE f_stk:    RESULTIS "STK"
      CASE f_stkp:   RESULTIS "STKP"
      CASE f_skg:    RESULTIS "SKG"
      CASE f_xst:    RESULTIS "XST"

      CASE f_k:      RESULTIS "K"
      CASE f_kpg:    RESULTIS "KPG"

      CASE f_neg:    RESULTIS "NEG"
      CASE f_not:    RESULTIS "NOT"
      CASE f_abs:    RESULTIS "ABS"

      CASE f_xdiv:   RESULTIS "XDIV"
      CASE f_xrem:   RESULTIS "XREM"
      CASE f_xsub:   RESULTIS "XSUB"

      CASE f_mul:    RESULTIS "MUL"
      CASE f_div:    RESULTIS "DIV"
      CASE f_rem:    RESULTIS "REM"
      CASE f_add:    RESULTIS "ADD"
      CASE f_sub:    RESULTIS "SUB"

      CASE f_eq:     RESULTIS "EQ"
      CASE f_ne:     RESULTIS "NE"
      CASE f_ls:     RESULTIS "LS"
      CASE f_gr:     RESULTIS "GR"
      CASE f_le:     RESULTIS "LE"
      CASE f_ge:     RESULTIS "GE"
      CASE f_eq0:    RESULTIS "EQ0"
      CASE f_ne0:    RESULTIS "NE0"
      CASE f_ls0:    RESULTIS "LS0"
      CASE f_gr0:    RESULTIS "GR0"
      CASE f_le0:    RESULTIS "LE0"
      CASE f_ge0:    RESULTIS "GE0"

      CASE f_lsh:    RESULTIS "LSH"
      CASE f_rsh:    RESULTIS "RSH"

      CASE f_and:    RESULTIS "AND"
      CASE f_or:     RESULTIS "OR"
      CASE f_xor:    RESULTIS "XOR"
      CASE f_eqv:    RESULTIS "EQV"

      CASE f_gbyt:   RESULTIS "GBYT"
      CASE f_xgbyt:  RESULTIS "XGBYT"
      CASE f_pbyt:   RESULTIS "PBYT"
      CASE f_xpbyt:  RESULTIS "XPBYT"

      CASE f_swb:    RESULTIS "SWB"
      CASE f_swl:    RESULTIS "SWL"

      CASE f_xch:    RESULTIS "XCH"
      CASE f_atb:    RESULTIS "ATB"
      CASE f_atc:    RESULTIS "ATC"
      CASE f_bta:    RESULTIS "BTA"
      CASE f_btc:    RESULTIS "BTC"
      CASE f_atblp:  RESULTIS "ATBLP"
      CASE f_atblg:  RESULTIS "ATBLG"
      CASE f_atbl:   RESULTIS "ATBL"

      CASE f_j:      RESULTIS "J"
      CASE f_rtn:    RESULTIS "RTN"
      CASE f_goto:   RESULTIS "GOTO"

      CASE f_ikp:    RESULTIS "IKP"
      CASE f_ikg:    RESULTIS "IKG"
      CASE f_ikl:    RESULTIS "IKL"
      CASE f_ip:     RESULTIS "IP"
      CASE f_ig:     RESULTIS "IG"
      CASE f_il:     RESULTIS "IL"

      CASE f_jeq:    RESULTIS "JEQ"
      CASE f_jne:    RESULTIS "JNE"
      CASE f_jls:    RESULTIS "JLS"
      CASE f_jgr:    RESULTIS "JGR"
      CASE f_jle:    RESULTIS "JLE"
      CASE f_jge:    RESULTIS "JGE"
      CASE f_jeq0:   RESULTIS "JEQ0"
      CASE f_jne0:   RESULTIS "JNE0"
      CASE f_jls0:   RESULTIS "JLS0"
      CASE f_jgr0:   RESULTIS "JGR0"
      CASE f_jle0:   RESULTIS "JLE0"
      CASE f_jge0:   RESULTIS "JGE0"
      CASE f_jge0m:  RESULTIS "JGE0M"

      CASE f_brk:    RESULTIS "BRK"
      CASE f_nop:    RESULTIS "NOP"
      CASE f_chgco:  RESULTIS "CHGCO"
      CASE f_mdiv:   RESULTIS "MDIV"
      CASE f_sys:    RESULTIS "SYS"

      CASE f_section:  RESULTIS "SECTION"
      CASE f_modstart: RESULTIS "MODSTART"
      CASE f_modend:   RESULTIS "MODEND"
      CASE f_global:   RESULTIS "GLOBAL"
      CASE f_string:   RESULTIS "STRING"
      CASE f_const:    RESULTIS "CONST"
      CASE f_static:   RESULTIS "STATIC"
      CASE f_mlab:     RESULTIS "MLAB"
      CASE f_lab:      RESULTIS "LAB"
      CASE f_lstr:     RESULTIS "LSTR"
      CASE f_entry:    RESULTIS "ENTRY"
   $)

   writef("%t8 ", s)
$)


AND sort(v, d, upb, cmpfn) BE
$( LET m = 1
   UNTIL m>upb DO m := m*3 + 1  // Find first suitable value in the
                                // series:  1, 4, 13, 40, 121, 364, ...
   $( m := m/3
//writef("sort: m = %n*n", m)
      FOR i = m+1 TO upb DO
      $( LET vi = v!i
         LET di = d!i
         LET j = i
         $( LET k = j - m
            IF k<=0 | cmpfn(v!k, d!k, vi, di) BREAK
            v!j := v!k
            d!j := d!k
            j := k
         $) REPEAT
         v!j := vi
         d!j := di
      $)
   $) REPEATUNTIL m=1
//writef("sort: done*n")

$)

AND cmp1(v1, d1, v2, d2) = v1<=v2

AND cmp2(v1, d1, v2, d2) = d1<=d2

AND wrcode(let, x) BE //writef("%c%n*n", let, x)
                      writef("%n*n", x)

AND wrf(x) BE pack(Fstr, x)
AND wrp(x) BE pack(Pstr, x)
AND wrg(x) BE pack(Gstr, x)
AND wrk(x) BE pack(Kstr, x)
AND wrw(x) BE pack(Wstr, x)
AND wrl(x) BE pack(Lstr, x)
AND wrm(x) BE pack(Mstr, x)
AND wrc(x) BE pack(Cstr, x)

AND error(mess, a, b, c) BE
$( LET out = output()
   UNLESS out=stdout DO
   $( selectoutput(stdout)
      writef(mess, a, b, c)
      selectoutput(out)
   $)
   writef(mess, a, b, c)
$)

AND scan() BE
$( LET op = rdf()

   IF (debug&4)=4 DO wrfcode(op)

   SWITCHON op INTO

   $( DEFAULT:       error("Bad op %n*n", op)
      CASE -1:       RETURN
      
      CASE f_lp:     cvfp(op); ENDCASE
      CASE f_lg:     cvfg(op); ENDCASE
      CASE f_ll:     cvfl(op); ENDCASE

      CASE f_llp:    cvfp(op); ENDCASE
      CASE f_llg:    cvfg(op); ENDCASE
      CASE f_lll:    cvfl(op); ENDCASE
      CASE f_lf:     cvfl(op); ENDCASE
      CASE f_lw:     cvfm(op); ENDCASE

      CASE f_l:      cvfk(op); ENDCASE
      CASE f_lm:     cvfk(op); ENDCASE

      CASE f_sp:     cvfp(op); ENDCASE
      CASE f_sg:     cvfg(op); ENDCASE
      CASE f_sl:     cvfl(op); ENDCASE

      CASE f_ap:     cvfp(op); ENDCASE
      CASE f_ag:     cvfg(op); ENDCASE
      CASE f_a:      cvfk(op); ENDCASE
      CASE f_s:      cvfk(op); ENDCASE

      CASE f_lkp:    cvfkp(op); ENDCASE
      CASE f_lkg:    cvfkg(op); ENDCASE
      CASE f_rv:     cvf(op); ENDCASE
      CASE f_rvp:    cvfp(op); ENDCASE
      CASE f_rvk:    cvfk(op); ENDCASE
      CASE f_st:     cvf(op); ENDCASE
      CASE f_stp:    cvfp(op); ENDCASE
      CASE f_stk:    cvfk(op); ENDCASE
      CASE f_stkp:   cvfkp(op); ENDCASE
      CASE f_skg:    cvfkg(op); ENDCASE
      CASE f_xst:    cvf(op); ENDCASE

      CASE f_k:      cvfp(op); ENDCASE
      CASE f_kpg:    cvfpg(op); ENDCASE

      CASE f_neg:    cvf(op); ENDCASE
      CASE f_not:    cvf(op); ENDCASE
      CASE f_abs:    cvf(op); ENDCASE

      CASE f_xdiv:   cvf(op); ENDCASE
      CASE f_xrem:   cvf(op); ENDCASE
      CASE f_xsub:   cvf(op); ENDCASE

      CASE f_mul:    cvf(op); ENDCASE
      CASE f_div:    cvf(op); ENDCASE
      CASE f_rem:    cvf(op); ENDCASE
      CASE f_add:    cvf(op); ENDCASE
      CASE f_sub:    cvf(op); ENDCASE

      CASE f_eq:     cvf(op); ENDCASE
      CASE f_ne:     cvf(op); ENDCASE
      CASE f_ls:     cvf(op); ENDCASE
      CASE f_gr:     cvf(op); ENDCASE
      CASE f_le:     cvf(op); ENDCASE
      CASE f_ge:     cvf(op); ENDCASE
      CASE f_eq0:    cvf(op); ENDCASE
      CASE f_ne0:    cvf(op); ENDCASE
      CASE f_ls0:    cvf(op); ENDCASE
      CASE f_gr0:    cvf(op); ENDCASE
      CASE f_le0:    cvf(op); ENDCASE
      CASE f_ge0:    cvf(op); ENDCASE

      CASE f_lsh:    cvf(op); ENDCASE
      CASE f_rsh:    cvf(op); ENDCASE
      CASE f_and:    cvf(op); ENDCASE
      CASE f_or:     cvf(op); ENDCASE
      CASE f_xor:    cvf(op); ENDCASE
      CASE f_eqv:    cvf(op); ENDCASE

      CASE f_gbyt:   cvf(op); ENDCASE
      CASE f_xgbyt:  cvf(op); ENDCASE
      CASE f_pbyt:   cvf(op); ENDCASE
      CASE f_xpbyt:  cvf(op); ENDCASE

      CASE f_swb:       cvswb(op); ENDCASE
      CASE f_swl:       cvswl(op); ENDCASE

      CASE f_xch:    cvf(op); ENDCASE
      CASE f_atb:    cvf(op); ENDCASE
      CASE f_atc:    cvf(op); ENDCASE
      CASE f_bta:    cvf(op); ENDCASE
      CASE f_btc:    cvf(op); ENDCASE
      CASE f_atblp:  cvfp(op); ENDCASE
      CASE f_atblg:  cvfg(op); ENDCASE
      CASE f_atbl:   cvfk(op); ENDCASE

      CASE f_j:      cvfl(op); ENDCASE
      CASE f_rtn:    cvf(op); ENDCASE
      CASE f_goto:   cvf(op); ENDCASE

      CASE f_ikp:    cvfkp(op); ENDCASE
      CASE f_ikg:    cvfkg(op); ENDCASE
      CASE f_ikl:    cvfkl(op); ENDCASE
      CASE f_ip:     cvfp(op);   ENDCASE
      CASE f_ig:     cvfg(op);   ENDCASE
      CASE f_il:     cvfl(op);   ENDCASE

      CASE f_jeq:    cvfl(op); ENDCASE
      CASE f_jne:    cvfl(op); ENDCASE
      CASE f_jls:    cvfl(op); ENDCASE
      CASE f_jgr:    cvfl(op); ENDCASE
      CASE f_jle:    cvfl(op); ENDCASE
      CASE f_jge:    cvfl(op); ENDCASE
      CASE f_jeq0:   cvfl(op); ENDCASE
      CASE f_jne0:   cvfl(op); ENDCASE
      CASE f_jls0:   cvfl(op); ENDCASE
      CASE f_jgr0:   cvfl(op); ENDCASE
      CASE f_jle0:   cvfl(op); ENDCASE
      CASE f_jge0:   cvfl(op); ENDCASE
      CASE f_jge0m:  cvfm(op); ENDCASE

      CASE f_brk:    cvf(op); ENDCASE
      CASE f_nop:    cvf(op); ENDCASE
      CASE f_chgco:  cvf(op); ENDCASE
      CASE f_mdiv:   cvf(op); ENDCASE
      CASE f_sys:    cvf(op); ENDCASE

      CASE f_global:   cvglobal(op); ENDCASE
      CASE f_string:   cvstring(op); ENDCASE
      CASE f_const:    cvconst(op); ENDCASE
      CASE f_static:   cvstatic(op); ENDCASE
      CASE f_mlab:     cvfm(op); ENDCASE
      CASE f_lab:      cvfl(op); ENDCASE
      CASE f_lstr:     cvfm(op); ENDCASE
      CASE f_entry:    cvfs(op); ENDCASE

      CASE f_section:    cvfs(op); ENDCASE
      CASE f_modstart:   codep, labmax, mlabmax := 0, 0, 0
                         openstreams()
                         cvf(op)
                         ENDCASE
      CASE f_modend:     cvf(op)
                         flushcodeword()
                         outputmodule()
   selectoutput(stdout)
   writef("Size: %i4 = F%n+P%n+G%n+K%n+W%n+C%n+L%n+M%n*n",
           (s_totlen!Fstr+
            s_totlen!Pstr+
            s_totlen!Gstr+
            s_totlen!Kstr+
            s_totlen!Wstr+
            s_totlen!Cstr+
            s_totlen!Lstr+
            s_totlen!Mstr+
            7
           )/8,

           (s_totlen!Fstr+7)/8,
           (s_totlen!Pstr+7)/8,
           (s_totlen!Gstr+7)/8,
           (s_totlen!Kstr+7)/8,
           (s_totlen!Wstr+7)/8,
           (s_totlen!Cstr+7)/8,
           (s_totlen!Lstr+7)/8,
           (s_totlen!Mstr+7)/8)

           selectoutput(codeout)
           closestreams()
           ENDCASE
   $)
$) REPEAT

AND outputmodule() BE
{ //binwrword(t_chunk)
  //binwrword(codep)
  //binwrword(labmax)
  //binwrword(mlabmax)
  IF debug RETURN
  FOR i = 0 TO codep-1 DO wrch(code%i)
}

/*
AND binwrword(w) BE
{ binwrch(w     & 255)
  binwrch(w>>8  & 255)
  binwrch(w>>16 & 255)
  binwrch(w>>24 & 255)
}

AND binwrch(ch) BE wrch(ch)
*/

AND cvf(f)   BE wrf(f)
AND cvfp(f)  BE { wrf(f); wrp(rdp()) }
AND cvfkp(f) BE { wrf(f); wrk(rdk()); wrp(rdp()) }
AND cvfg(f)  BE { wrf(f); wrg(rdg()) }
AND cvfkg(f) BE { wrf(f); wrk(rdk()); wrg(rdg()) }
AND cvfpg(f) BE { wrf(f); wrp(rdp()); wrg(rdg()) }
AND cvfk(f)  BE { wrf(f); wrk(rdk()) }
AND cvfkl(f) BE { wrf(f); wrk(rdk()); wrl(rdl()) }
AND cvfw(f)  BE { wrf(f); wrw(rdw()) }
AND cvfl(f)  BE { wrf(f); wrl(rdl()) }
AND cvfm(f)  BE { wrf(f); wrm(rdm()) }

AND cvswl(f) BE
$( LET n = rdk()
   LET l = rdl()
   wrf(f)
   wrk(n)
   wrl(l)
   FOR i = 1 TO n DO wrl(rdl())
$)

AND cvswb(f) BE
$( LET n = rdk()
   LET l = rdl()
   wrf(f)
   wrk(n)
   wrl(l)
   FOR i = 1 TO n DO 
   $( LET k = rdk()
      LET l = rdl()
      wrk(k)
      wrl(l)
   $)
$)

AND cvglobal(f) BE
$( LET n = rdk()
   wrf(f)
   wrk(n)
   FOR i = 1 TO n DO
   $( LET g = rdg()
      LET n = rdl()
      wrg(g)
      wrl(n)
   $)
   wrg(rdg())
$)

AND cvstring(f) BE
$( LET lab = rdm()
   LET n = rdk()
   wrf(f)
   wrm(lab)
   wrk(n)
   FOR i = 1 TO n DO wrc(rdc())
$)

AND cvconst(f) BE
{ LET lab = rdm()
  LET w = rdw()
  wrf(f)
  wrm(lab)
  wrw(w)
}

AND cvstatic(f) BE
{ LET lab = rdl()
  LET n = rdk()
  wrf(f)
  wrl(lab)
  wrk(n)
  FOR i = 1 TO n DO wrw(rdw())
}

AND cvfs(f) BE
$( LET n = rdk()
   wrf(f)
   wrk(n)
   FOR i = 1 TO n DO wrc(rdc())
$)

