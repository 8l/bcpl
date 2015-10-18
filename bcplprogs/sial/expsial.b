SECTION "expsial"

GET "libhdr"

GET "sial.h"

GLOBAL $(
codein:   200
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
codesh:   248

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

debug:    283

codeword: 290
bitcount: 291
initinput: 292
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

s_unpackfn=   0
s_a=        1
s_b=        2
s_c=        3
s_bytes=    9
s_items=   10
s_totlen=  11
s_letter=  12
s_buf=     13
s_upb=     s_buf

t_chunk=   2000
}

LET unpack1(s) = (s!s_unpackfn)(s)

AND unpack(s) = VALOF
{ LET val = unpack1(s)
  IF (debug&1)=1 DO writef("unpack: %c%n*n", s!s_letter, val)
  RESULTIS val
}

AND shift(n) BE
{ IF (debug&2)=2 DO
  { writebin(codeword, n)
    newline()
  }
  codeword := codeword>>n
  bitcount := bitcount-n
  WHILE bitcount<=24 DO
  { LET byte = rdch()
    UNLESS byte=endstreamch DO codeword := codeword + (byte<<bitcount)
    bitcount := bitcount+8
//writef("%x8 %i2*n", codeword, bitcount)
  }
}

AND initinput() BE
{ codeword := 0
  bitcount := 0
  shift(0)
}

LET unpackW(s) = VALOF
{ //            11 =>      PREV
  //            01 =>       INC
  //  <3-bits>  10 =>   <3-bit>
  //  <8-bits> 100 =>  <8-bits>
  // <16-bits>1000 => <16-bits>
  // <32-bits>0000 => <32-bits>
  LET a = s_a!s
  LET val = ?
  SWITCHON codeword & #b1111 INTO
  { CASE #b1111:              //        11  PREV
    CASE #b0111:
    CASE #b1011:
    CASE #b0011: val := a
                 shift(2)
                 ENDCASE

    CASE #b1101:              //        01  INC
    CASE #b0101:
    CASE #b1001:
    CASE #b0001: val := a+1
                 shift(2)
                 ENDCASE
    CASE #b1110:              //        10  <3-bits>
    CASE #b0110:
    CASE #b1010:
    CASE #b0010: val := (codeword>>2) & #b111
                 shift(5)
                 ENDCASE
    CASE #b1100:              //       100  <8-bits>
    CASE #b0100: val := (codeword>>3) & #xFF
                 shift(11)
                 ENDCASE
    CASE #b1000: val := (codeword>>4) & #xFFFF
                 shift(20)
                 ENDCASE
    CASE #b0000: shift(4)
                 val := codeword
                 shift(32)
                 ENDCASE
  }
  s_a!s := val
  RESULTIS val
}

AND unpackF(s) = VALOF
//            11  PRED (predicted value)
// <8-bits>   01  <8-bits>
//          0010 KPG
//          0110 SP
//         01010 L
//         11010 LP
//         01110 LAB
//         11110 LG
//           etc
{ MANIFEST { hashtabupb=255 }
  LET a       = s_a!s // Previous value
  LET val     = ?
  LET hashval = a REM (hashtabupb+1)
  LET hashtab = s_buf!s
  IF hashtab=0 DO 
  { hashtab := getvec(hashtabupb)
    FOR i = 0 TO hashtabupb DO hashtab!i := i
    s_buf!s := hashtab
  }

  IF (codeword&#b11)=#b11 DO
  { val := hashtab!hashval
    shift(2)
    s_a!s := val
    RESULTIS val
   }
  IF (codeword&#b11)=#b01 DO
  { val := (codeword>>2)&#xFF
    s_a!s := val
    hashtab!hashval := val
    shift(10)
    RESULTIS val
  }

  val := 0
  SWITCHON codeword & #b1111 INTO
  { CASE #b0010: shift(4); val := f_kpg; ENDCASE
    CASE #b0110: shift(4); val := f_sp;  ENDCASE
  }
  IF val DO
  { s_a!s := val
    hashtab!hashval := val
    RESULTIS val
  }
  SWITCHON codeword & #b11111 INTO
  { CASE #b01010: shift(5); val := f_l;   ENDCASE
    CASE #b11010: shift(5); val := f_lp;  ENDCASE
    CASE #b01110: shift(5); val := f_lab; ENDCASE
    CASE #b11110: shift(5); val := f_lg;  ENDCASE
  }
  IF val DO
  { s_a!s := val
    hashtab!hashval := val
    RESULTIS val
  }
  SWITCHON codeword & #b111111 INTO
  { CASE #b000100: shift(6); val := f_rtn;   ENDCASE
    CASE #b001100: shift(6); val := f_lkp;   ENDCASE
    CASE #b010100: shift(6); val := f_sg;    ENDCASE
    CASE #b011100: shift(6); val := f_j;     ENDCASE
    CASE #b100100: shift(6); val := f_atbl;  ENDCASE
    CASE #b101100: shift(6); val := f_atblp; ENDCASE
    CASE #b110100: shift(6); val := f_atblg; ENDCASE
    CASE #b111100: shift(6); val := f_jeq0;  ENDCASE
  }
  IF val DO
  { s_a!s := val
    hashtab!hashval := val
    RESULTIS val
  }
  SWITCHON codeword & #b1111111 INTO
  { CASE #b0001000: shift(7); val := f_lstr;  ENDCASE
    CASE #b0011000: shift(7); val := f_jne;   ENDCASE
    CASE #b0101000: shift(7); val := f_entry; ENDCASE
    CASE #b0111000: shift(7); val := f_jgr;   ENDCASE
    CASE #b1001000: shift(7); val := f_jne0;  ENDCASE
  }
  IF val DO
  { s_a!s := val
    hashtab!hashval := val
    RESULTIS val
  }
  SWITCHON codeword & #b11111111 INTO
  { CASE #b01011000: shift(8); val := f_string; ENDCASE
    CASE #b11011000: shift(8); val := f_lm;     ENDCASE
    CASE #b01101000: shift(8); val := f_jle;    ENDCASE
    CASE #b11101000: shift(8); val := f_ap;     ENDCASE
    CASE #b01111000: shift(8); val := f_jeq;    ENDCASE
    CASE #b11111000: shift(8); val := f_s;      ENDCASE
    CASE #b00010000: shift(8); val := f_ikg;    ENDCASE
    CASE #b00110000: shift(8); val := f_lkg;    ENDCASE
    CASE #b01010000: shift(8); val := f_ikp;    ENDCASE
    CASE #b01110000: shift(8); val := f_jls;    ENDCASE
    CASE #b10010000: shift(8); val := f_atb;    ENDCASE
  }
  IF val DO
  { s_a!s := val
    hashtab!hashval := val
    RESULTIS val
  }
  SWITCHON codeword & #b111111111 INTO
  { CASE #b010110000: shift(9); val := f_stkp; ENDCASE
    CASE #b110110000: shift(9); val := f_a;    ENDCASE
    CASE #b011010000: shift(9); val := f_atc;  ENDCASE
    CASE #b111010000: shift(9); val := f_jle0; ENDCASE
    CASE #b011110000: shift(9); val := f_bta;  ENDCASE
    CASE #b111110000: shift(9); val := f_jls0; ENDCASE
  }
  IF val DO
  { s_a!s := val
    hashtab!hashval := val
    RESULTIS val
  }
  SWITCHON codeword & #b1111111111 INTO
  { CASE #b0000100000: shift(10); val := f_skg;  ENDCASE
    CASE #b0001100000: shift(10); val := f_pbyt; ENDCASE
    CASE #b0010100000: shift(10); val := f_gbyt; ENDCASE
    CASE #b0011100000: shift(10); val := f_xsub; ENDCASE
    CASE #b0100100000: shift(10); val := f_swl;  ENDCASE
    CASE #b0101100000: shift(10); val := f_rvp;  ENDCASE
    CASE #b0110100000: shift(10); val := f_lf;   ENDCASE
    CASE #b0111100000: shift(10); val := f_jge;  ENDCASE
    CASE #b1000100000: shift(10); val := f_and;  ENDCASE
    CASE #b1001100000: shift(10); val := f_sub;  ENDCASE
    CASE #b1010100000: shift(10); val := f_neg;  ENDCASE
    CASE #b1011100000: shift(10); val := f_swb;  ENDCASE
    CASE #b1100100000: shift(10); val := f_mul;  ENDCASE
    CASE #b1101100000: shift(10); val := f_div;  ENDCASE
    CASE #b1110100000: shift(10); val := f_jge0; ENDCASE
    CASE #b1111100000: shift(10); val := f_stk;  ENDCASE
  }
  IF val DO
  { s_a!s := val
    hashtab!hashval := val
    RESULTIS val
  }
  SWITCHON codeword & #b11111111111 INTO
  { CASE #b00001000000: shift(11); val := f_jgr0;    ENDCASE
    CASE #b00011000000: shift(11); val := f_xch;     ENDCASE
    CASE #b00101000000: shift(11); val := f_rsh;     ENDCASE
    CASE #b00111000000: shift(11); val := f_llg;     ENDCASE
    CASE #b01001000000: shift(11); val := f_ag;      ENDCASE
    CASE #b01011000000: shift(11); val := f_not;     ENDCASE
    CASE #b01101000000: shift(11); val := f_k;       ENDCASE
    CASE #b01111000000: shift(11); val := f_rv;      ENDCASE
    CASE #b10001000000: shift(11); val := f_llp;     ENDCASE
    CASE #b10011000000: shift(11); val := f_or;      ENDCASE
    CASE #b10101000000: shift(11); val := f_rem;     ENDCASE
    CASE #b10111000000: shift(11); val := f_xst;     ENDCASE
    CASE #b11001000000: shift(11); val := f_stp;     ENDCASE
    CASE #b11011000000: shift(11); val := f_section; ENDCASE
    CASE #b11101000000: shift(11); val := f_st;      ENDCASE
    CASE #b11111000000: shift(11); val := f_xgbyt;   ENDCASE
  }
  IF val DO
  { s_a!s := val
    hashtab!hashval := val
    RESULTIS val
  }

  error("Trouble with unpackF*n")
  RESULTIS 0
}

AND unpackP(s) = VALOF
{ LET val = ?

  SWITCHON codeword & #b11 INTO
  { CASE #b01: shift(2); RESULTIS 3
    CASE #b11: shift(2); RESULTIS 4
  }
  SWITCHON codeword & #b1111 INTO
  { CASE #b0010: shift(4); RESULTIS 5
    CASE #b0110: shift(4); RESULTIS 6
    CASE #b1010: shift(4); RESULTIS 7
    CASE #b1110: shift(4); RESULTIS 8
  }
  SWITCHON codeword & #b11111 INTO
  { CASE #b00100: shift(5); RESULTIS 9
    CASE #b01100: shift(5); RESULTIS 10
    CASE #b10100: shift(5); RESULTIS 11
    CASE #b11100: shift(5); RESULTIS 12
  }
  SWITCHON codeword & #b111111 INTO
  { CASE #b000000: shift(6);  val := codeword & #xFFFFFF
                   shift(24); RESULTIS val
    CASE #b100000: shift(6);  val := (codeword & 63)+21
                   shift(6);  RESULTIS val
    CASE #b001000: shift(6);  RESULTIS 13
    CASE #b011000: shift(6);  RESULTIS 14
    CASE #b101000: shift(6);  RESULTIS 15
    CASE #b111000: shift(6);  RESULTIS 16
  }
  SWITCHON codeword & #b1111111 INTO
  { CASE #b0010000: shift(7); RESULTIS 17
    CASE #b0110000: shift(7); RESULTIS 18
    CASE #b1010000: shift(7); RESULTIS 19
    CASE #b1110000: shift(7); RESULTIS 20
  }

  error("Trouble in unpackP*n")  
}


AND unpackG(s) = VALOF
{ LET val = unpackG1(s)
  //writef("=> G%n*n", val)
  RESULTIS val
}

AND unpackG1(s) = VALOF
{ LET buf, a = s_buf!s, ?
  LET val = 0

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

//writef("unpackG:")
//FOR i = 0 TO 10 DO writef(" G%n", buf!i)
//newline()
  a := buf!0

  IF (codeword&#b111) = #b001 DO // BUF0
  { shift(3)
    RESULTIS a
  }

  IF (codeword&#b11) = #b11 DO // BUF1
  { shift(2)
    val := buf!1
    buf!0, buf!1 := val, a
    RESULTIS val
  }

  IF (codeword&#b1111) = #b1010 DO // BUF2
  { shift(4)
    val := buf!2
    buf!2 := buf!1
    buf!0, buf!1 := val, a
    RESULTIS val
  }

  IF (codeword&#b111) = #b101 DO                   // BUF3 - BUF10
  { LET p = ((codeword>>3)&#b111) + 3
    shift(6)
    val := buf!p
    FOR i = p TO 1 BY -1 DO buf!i := buf!(i-1)
    buf!0 := val
    RESULTIS val
  }

  IF (codeword&#b1111) = #b0010 DO                   // INCBUF1 - INCBUF8 
  { LET p = ((codeword>>4)&#b111) + 1
    shift(7)
    val := buf!p + 1
    FOR i = p TO 1 BY -1 DO buf!i := buf!(i-1)
    buf!0 := val
    RESULTIS val
  }

  IF (codeword&#b1111) = #b1100 DO                   // DECBUF1 - DECBUF8 
  { LET p = ((codeword>>4)&#b111) + 1
    shift(7)
    val := buf!p - 1
    FOR i = p TO 1 BY -1 DO buf!i := buf!(i-1)
    buf!0 := val
    RESULTIS val
  }

  IF (codeword&#b11111) = #b10000 DO                 // INC2BUF1 - INC2BUF8 
  { LET p = ((codeword>>5)&#b111) + 1
    shift(8)
    val := buf!p + 2
    FOR i = p TO 1 BY -1 DO buf!i := buf!(i-1)
    buf!0 := val
    RESULTIS val
  }

  IF (codeword&#b1111) = #b0100 DO                   // DEC2BUF1 - DEC2BUF8 
  { LET p = ((codeword>>4)&#b111) + 1
    shift(7)
    val := buf!p - 2
    FOR i = p TO 1 BY -1 DO buf!i := buf!(i-1)
    buf!0 := val
    RESULTIS val
  }

  IF (codeword&#b11111) = #b01000 DO                  // SUB 1 - 8
  { LET val = a - 1 - ((codeword>>5)&#b111)
    shift(8)
    FOR i = 10 TO 1 BY -1 DO buf!i := buf!(i-1)
    buf!0 := val
    RESULTIS val
  }

  IF (codeword&#b11111) = #b11000 DO                  // ADD 1 - 8
  { LET val = a + 1 + ((codeword>>5)&#b111)
    shift(8)
    FOR i = 10 TO 1 BY -1 DO buf!i := buf!(i-1)
    buf!0 := val
    RESULTIS val
  }

  IF (codeword&#b111) = #b110 DO                  // L <9-bits>
  { LET val = (codeword>>3) & #b111111111

    shift(12)
    FOR i = 10 TO 1 BY -1 DO buf!i := buf!(i-1)
    buf!0 := val
    RESULTIS val
  }

  IF (codeword&#b11111) = #b00000 DO                  // L <12-bits>
  { LET val = (codeword>>5) & #xFFF
    shift(17)
    FOR i = 10 TO 1 BY -1 DO buf!i := buf!(i-1)
    buf!0 := val
    RESULTIS val
  }

  error("Trouble in unpackG*n")
}

LET unpackK(s, val) = VALOF
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
{ SWITCHON codeword&#b111 INTO
  { CASE #b110: shift(3); RESULTIS 0
    CASE #b010: shift(3); RESULTIS 1
    CASE #b100: shift(3); RESULTIS 2
  }
  IF (codeword&#b1111)=#b1000 DO
  { shift(4)
    RESULTIS 3
  }
  IF (codeword&#b11)=#b11 DO
  { LET val = 4 + ((codeword>>2)&#b111)
    shift(5)
    RESULTIS val
  }
  IF (codeword&#b11)=#b01 DO
  { LET val = -10 + ((codeword>>2)&#b1111111)
    shift(9)
    RESULTIS val
  }
  IF (codeword&#b11111)=#b10000 DO
  { LET val = 118 + ((codeword>>5)&#xFF)
    shift(13)
    RESULTIS val
  }
  IF (codeword&#b111111)=#b100000 DO
  { LET val = ((codeword>>6)&#xFFFF)
    shift(22)
    RESULTIS val
  }
  IF (codeword&#b1111111)=#b1000000 DO
  { LET val = (codeword>>7)&#xFFFFFF
    shift(31)
    RESULTIS val
  }
  IF (codeword&#b1111111)=#b0000000 DO
  { LET val = - ((codeword>>7)&#xFFFFFF)
    shift(31)
    RESULTIS val
  }

  error("Trouble in unpackK, codeword = %bD*n", codeword)
}

AND unpackL1(s) = VALOF
{ LET val = unpackL1(s)
  writef("=> L%n*n", val)
  abort(999)
  RESULTIS val
}

AND unpackL(s) = VALOF
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
  LET val = ?
//writef("unpackL: a=%n b=%n codeword=%bD*n", a, b, codeword)

  IF (codeword&#b111)=#b010 DO         // a
  { shift(3)
    RESULTIS a
  }
  IF (codeword&#b1)=#b1 DO             // a+1
  { shift(1)
    val   := a+1
    s_b!s := a
    s_a!s := val
    RESULTIS val
  }
  IF (codeword&#b1111)=#b0110 DO       // a-1
  { shift(4)
    val   := a-1
    s_b!s := a
    s_a!s := val
    RESULTIS val
  }
  IF (codeword&#b1111)=#b1110 DO       // b+1
  { shift(4)
    val   := b+1
    s_b!s := a
    s_a!s := val
    RESULTIS val
  }
  IF (codeword&#b11111)=#b10000 DO     // b
  { shift(5)
    val   := b
    s_b!s := a
    s_a!s := val
    RESULTIS val
  }
  IF (codeword&#b111111)=#b100000 DO   // a+2
  { shift(6)
    val   := a+2
    s_b!s := a
    s_a!s := val
    RESULTIS val
  }
  IF (codeword&#b111)=#b100 DO         // a-32 + <6-bits>
  { val := a - 32 + ((codeword>>3)&#b111111)
    shift(9)
    s_b!s := a
    s_a!s := val
    RESULTIS val
  }
  IF (codeword&#b1111)=#b1000 DO       // a-255 + <9-bits>
  { val := a - 255 + ((codeword>>4)&#b111111111)
    shift(13)
    s_b!s := a
    s_a!s := val
    RESULTIS val
  }
  IF (codeword&#b111111)=#b000000 DO   // a-255 + <16-bits>
  { val := (codeword>>6)&#xFFFF
    shift(22)
    s_b!s := a
    s_a!s := val
    RESULTIS val
  }

  error("Trouble in unpackL*n")
}

AND unpackC(s) = VALOF
//  <3-bits>  1   0-7
//  <4-bits> 10   8-23
//  <8-bits> 00   <8-bits>
//  Then lookup in MTF buffer (initially " abcd...012...%*n" etc)
//  The Uppercase letter change letter shift
//  Then put letter in current shift (initially lower)
{ LET buf = s_buf!s
  LET val = ?
  LET p = 0
  IF buf=0 DO
  { LET str = " abcdefghijklmnopqrstuvwxyz0123456789%*n"
    buf := getvec(255)
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

  TEST (codeword&1)=1
  THEN { p := (codeword>>1 & 7)
         shift(4)
       }
  ELSE TEST (codeword&#b11)=#b10
       THEN { p := ((codeword>>2) & 15) + 8
              shift(6)
            }
       ELSE { p := (codeword>>2) & 255
              shift(10)
            }

  val := buf!p
///  writef("p=%n*n", p)
  WHILE p>0 DO { buf!p := buf!(p-1); p := p-1 }
  buf!0 := val
///  FOR i = 0 TO 30 DO writef("%c", buf!i)
//newline()

  IF 'A'<=val<='Z' DO s_a!s, val := 1-s_a!s, val+'a'-'A'
  IF s_a!s & 'a'<=val<='z' DO val := val+'A'-'a'

  RESULTIS val
}

AND mkstream(unpackfn, letter) = VALOF
{ LET s = getvec(s_upb)
  IF s=0 DO error("Unable to make a stream")
  FOR i = 0 TO s_upb DO s!i := 0
  s_unpackfn!s := unpackfn
  s_letter!s := letter
  RESULTIS s
}

AND unmkstream(str) BE UNLESS str=0 DO
{ UNLESS s_buf!str=0 DO freevec(s_buf!str)
  freevec(str)
}
 
AND openstreams() BE
{ Fstr := mkstream(unpackF, 'F')
  Pstr := mkstream(unpackP, 'P')
  Gstr := mkstream(unpackG, 'G')
  Kstr := mkstream(unpackK, 'K')
  Wstr := mkstream(unpackW, 'W')
  Cstr := mkstream(unpackC, 'C')
  Lstr := mkstream(unpackL, 'L')
  Mstr := mkstream(unpackL, 'M')
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
   IF argv!0=0 DO argv!0 := "CODE"
   IF argv!1=0 DO argv!1 := "SIAL"

   TEST argv!2=0
   THEN debug := 0
   ELSE debug := str2numb(argv!2)

   IF debug DO writef("Debugging bits %b6*n", debug)

   codein := findinput(argv!0)
   IF codein=0 DO
   $( writef("Trouble with file %s*n", argv!0)
      RESULTIS 20
   $)
   codeout := findoutput(argv!1)
   
   IF codeout=0 DO
   $( writef("Trouble with file %s*n", argv!1)
      RESULTIS 20
   $)
   
   writef("Expanding %s to %s*n", argv!0, argv!1)
   selectinput(codein)
   selectoutput(codeout)

   code := getvec(50000)
   
   IF code=0 DO
   $( writef("Unable to allocate code vector*n")
      RESULTIS 20
   $)
   codep, codet := code, code+50000
   codesh := 32
   labmax, mlabmax := 0, 0 

   initinput()

   UNTIL rdch()=endstreamch DO
   { unrdch()
     openstreams()
     scan()
     closestreams()
   }

   UNLESS codeout=stdout DO endwrite()

   selectoutput(stdout)

   freevec(code)
   endread()

   writef("Conversion complete*n")
   RESULTIS 0
$)

AND rdf() = unpack(Fstr)
AND rdp() = unpack(Pstr)
AND rdg() = unpack(Gstr)
AND rdk() = unpack(Kstr)
AND rdw() = unpack(Wstr)
AND rdl() = VALOF
{ LET lab = unpack(Lstr)
  IF labmax<lab DO labmax := lab
  RESULTIS lab
}
AND rdm() = VALOF
{ LET mlab = unpack(Mstr)
  IF mlabmax<mlab DO mlabmax := mlab
  RESULTIS mlab
}

AND rdc() = unpack(Cstr)

AND wrf(x) BE writef("F%n*n", x)
AND wrp(x) BE writef("P%n*n", x)
AND wrg(x) BE writef("G%n*n", x)
AND wrk(x) BE writef("K%n*n", x)
AND wrw(x) BE writef("W%n*n", x)
AND wrl(x) BE writef("L%n*n", x)
AND wrm(x) BE writef("M%n*n", x)
AND wrc(x) BE writef("C%n*n", x)

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
//writef("scan: Just read F%n*n", op)
//abort(999)
   SWITCHON op INTO

   $( DEFAULT:       error("Bad op %n*n", op)
abort(888)
                     RETURN
      
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

      CASE f_swb:    cvswb(op); ENDCASE
      CASE f_swl:    cvswl(op); ENDCASE

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
      CASE f_modstart:   labmax, mlabmax := 0, 0
                         cvf(op)
                         ENDCASE
      CASE f_modend:     cvf(op)
                         // The module is rounded up to a
                         // byte boundary by 1(0)*
                         FOR i = 1 TO 8 DO
                         { IF (codeword&1)=1 BREAK
                           shift(1)
                         }
                         UNLESS (codeword&1)=1 DO abort(1000)
                         shift(1)
                         RETURN
   $)
$) REPEAT

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

