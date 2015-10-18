SECTION "expcial"

GET "libhdr"

MANIFEST
$(
// Cial opcodes and directives
f_k0   =   0
f_lf   =  12
f_lm   =  14
f_lm1  =  15
f_l0   =  16

f_jeq  =  28
f_jeq0 =  30

f_k    =  32
f_kh   =  33
f_kw   =  34
f_k0g  =  32
f_s0g  =  44
f_l0g  =  45
f_l1g  =  46
f_l2g  =  47
f_lg   =  48
f_sg   =  49
f_llg  =  50
f_ag   =  51
f_mul  =  52
f_div  =  53
f_rem  =  54
f_xor  =  55
f_sl   =  56
f_ll   =  58
f_jne  =  60
f_jne0 =  62

f_llp  =  64
f_llph =  65
f_llpw =  66

f_add  =  84
f_sub  =  85
f_lsh  =  86
f_rsh  =  87
f_and  =  88
f_or   =  89
f_lll  =  90
f_jls  =  92
f_jls0 =  94

f_l    =  96
f_lh   =  97
f_lw   =  98

f_rv   = 116
f_rtn  = 123
f_jgr  = 124
f_jgr0 = 126

f_lp   = 128
f_lph  = 129
f_lpw  = 130
f_lp0  = 128
f_swb  = 146
f_swl  = 147
f_st   = 148
f_st0  = 148
f_stp0 = 149
f_goto = 155
f_jle  = 156
f_jle0 = 158

f_sp   = 160
f_sph  = 161
f_spw  = 162
f_sp0  = 160
f_s0   = 176
f_xch  = 181
f_gbyt = 182
f_pbyt = 183
f_atc  = 184
f_atb  = 185
f_j    = 186
f_jge  = 188
f_jge0 = 190

f_ap   = 192
f_aph  = 193
f_apw  = 194
f_ap0  = 192
f_xpbyt= 205
f_lmh  = 206
f_btc  = 207
f_nop  = 208
f_a0   = 208
f_rvp0 = 211
f_st0p0= 216
f_st1p0= 218

f_a    = 224
f_ah   = 225
f_aw   = 226
f_l0p0 = 224
f_s    = 237
f_sh   = 238
f_mdiv = 239
f_chgco= 240
f_neg  = 241
f_not  = 242
f_l1p0 = 240
f_l2p0 = 244
f_l3p0 = 247
f_l4p0 = 249


f_section  = 256
f_modstart = 257
f_modend   = 258
f_abs      = 259
f_global   = 260
f_string   = 261
f_eq       = 262
f_ne       = 263
f_ls       = 264
f_gr       = 265
f_le       = 266
f_ge       = 267
f_eq0      = 268
f_ne0      = 269
f_ls0      = 270
f_gr0      = 271
f_le0      = 272
f_ge0      = 273
f_eqv      = 274
f_wdata    = 275
f_dlab     = 276
f_mlab     = 277
f_lab      = 278
f_jge0m    = 279
f_lstr     = 280
f_entry    = 281

f_incg     = 534
f_decg     = 535
f_incp3    = 536
f_incp4    = 537
f_incp5    = 538
f_decp3    = 539
f_decp4    = 540
f_decp5    = 541
$)

GLOBAL $(
codein:   200
cialout:  201
stdin:    202
stdout:   203
error:    204

rdf:      210
rdp:      211
rdg:      212
rdk:      213
rdh:      214
rdw:      215
rdl:      216
rdm:      217
rdc:      218
rdcode:   219

scan:     230
cvf:      231
cvfp:     232
cvfg:     233
cvfk:     234
cvfh:     235
cvfw:     236
cvfl:     237
cvfm:     238

mkstream: 240

codev:    250
codep:    251
codet:    252

Fstr:     253
Pstr:     254
Gstr:     255
Kstr:     256
Hstr:     257
Wstr:     258
Cstr:     259
Lstr:     260
Mstr:     261

labmax:   270
mlabmax:  271

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

s_nextfn=  0
s_a=       1
s_b=       2
s_c=       3
s_code=    4
s_sh=      5
s_pos=     6
s_count=   7
s_action=  8
s_buf=     9
s_upb=     s_buf

t_chunk=   2000
hashtabupb= 255
}

LET load(s, val) = VALOF
{ s_c!s := s_b!s
  s_b!s := s_a!s
  s_a!s := val
  RESULTIS val
}

AND save(s, val) BE
{ LET pos = (s_pos!s + 1) & 31
  s_buf!s!pos := val
}


AND rdhex() = VALOF
$( LET ch, res = rdch(), 0

   WHILE ch='*s' | ch='*n' DO ch := rdch()
   IF ch=';' DO
   { UNTIL ch='*n' | ch=endstreamch DO ch := rdch()
     LOOP
   }

   $( TEST '0'<=ch<='9'
      THEN res := res<<4 | ch-'0'
      ELSE TEST 'A'<=ch<='F'
           THEN res := res<<4 | ch-'A'+10
           ELSE TEST 'a'<=ch<='z'
                THEN res := res<<4 | ch-'a'+10
                ELSE BREAK
      ch := rdch()
   $) REPEAT
   
//writef("rdhex: %x8*n", res)
   RESULTIS res
$) REPEAT
   
LET next(s) = (s!s_nextfn)(s)

LET nextN(s) = VALOF
{ LET code = ?

  IF s_count!s>0 DO
  { LET action = s_action!s
    s_count!s := s_count!s - 1
    SWITCHON action & 7 INTO
    { DEFAULT: error("Bad action %n %n*n", action&7, action>>3)
               ENDCASE
      CASE c_a: RESULTIS load(s, s_a!s)
      CASE c_b: RESULTIS load(s, s_b!s)
      CASE c_c: RESULTIS load(s, s_c!s)
      CASE c_l: RESULTIS load(s, action>>3)
      CASE c_m: RESULTIS load(s, -(action>>3))
    }
  }
  code := s_code!s
sw:
  SWITCHON code&15 INTO
  { DEFAULT: error("Bad Ncode %b*n", code)
    CASE #b0000: code := !codep
//writef("Ncode %x8*n", code)
                 codep := codep + 1
                 GOTO sw

    CASE #b1000: s_code!s := code>>20     // L <16bits>
                 RESULTIS code>>4 & #xFFFF
    CASE #b0100: s_code!s := 0            // L <rest of word>
                 RESULTIS code>>4
    CASE #b1100: s_code!s := 0           // LW
                 code := !codep
                 codep := codep + 1
                 RESULTIS code
    CASE #b0010:
    CASE #b1010:
    CASE #b0110:
    CASE #b1110: s_code!s := code>>5     // L <3 bits>
                 RESULTIS code>>2 & 7
    CASE #b0001:
    CASE #b1001:
    CASE #b0101:
    CASE #b1101: s_code!s := code>>10     // L <8 bits>
                 RESULTIS code>>2 & 255
    CASE #b0011:
    CASE #b1011:
    CASE #b0111:
    CASE #b1111: s_code!s := code>>14     // L <12 bits>
                 RESULTIS code>>2 & 4095 
  }
}

AND nextF(s) = VALOF
{ LET code = s_code!s
  LET hashtab = s_buf!s
  LET a = s_a!s
  LET hashval = a REM (hashtabupb+1)
  LET count = s_count!s

  IF hashtab=0 DO
  { hashtab := getvec(hashtabupb)
    FOR i = 0 TO hashtabupb DO hashtab!i := f_l
    s_buf!s := hashtab
  }

//writef("predicting F%n*n", hashtab!hashval)

  IF count>0 DO
  { a := hashtab!hashval
    s_a!s, s_count!s := a, count-1
//writef("pred*n")
    RESULTIS a
  }

sw:
//  writef("Fsw: %b7*n", code&127)
  SWITCHON code&127 INTO
  { CASE #b0000000: //     0000  NEXT
    CASE #b0010000:
    CASE #b0100000:
    CASE #b0110000:
    CASE #b1000000:
    CASE #b1010000:
    CASE #b1100000:
    CASE #b1110000: code := !codep
//writef("Fcode %x8*n", code)
                    codep := codep + 1
                    GOTO sw

    CASE #b0001000: //    1000 pred 3_10
    CASE #b0011000:
    CASE #b0101000:
    CASE #b0111000:
    CASE #b1001000:
    CASE #b1011000:
    CASE #b1101000:
    CASE #b1111000: s_code!s := code>>7
                    s_count!s := (code>>4 & 7)+2
                    a := hashtab!hashval
                    s_a!s := a
//writef("pred*n")
                    RESULTIS a

    CASE #b0000100: //     100  PRED1
    CASE #b0001100:
    CASE #b0010100:
    CASE #b0011100:
    CASE #b0100100:
    CASE #b0101100:
    CASE #b0110100:
    CASE #b0111100:
    CASE #b1000100:
    CASE #b1001100:
    CASE #b1010100:
    CASE #b1011100:
    CASE #b1100100:
    CASE #b1101100:
    CASE #b1110100:
    CASE #b1111100: s_code!s := code>>3
//writef("pred1*n")
                    a := hashtab!hashval; ENDCASE

    CASE #b0000001: //    0001 LAB
    CASE #b0010001:
    CASE #b0100001:
    CASE #b0110001:
    CASE #b1000001:
    CASE #b1010001:
    CASE #b1100001:
    CASE #b1110001: s_code!s := code>>4
                    a := f_lab; ENDCASE

    CASE #b0000101: //    0101 LG
    CASE #b0010101:
    CASE #b0100101:
    CASE #b0110101:
    CASE #b1000101:
    CASE #b1010101:
    CASE #b1100101:
    CASE #b1110101: s_code!s := code>>4
                    a := f_lg; ENDCASE


    CASE #b0001001: //    1001  L <7-bit>
    CASE #b0011001:
    CASE #b0101001:
    CASE #b0111001:
    CASE #b1001001:
    CASE #b1011001:
    CASE #b1101001:
    CASE #b1111001: s_code!s := code>>11
                    a := (code>>4 & 127); ENDCASE


    CASE #b0001101: //   01101  RTN
    CASE #b0101101:
    CASE #b1001101:
    CASE #b1101101: s_code!s := code>>5
                    a := f_rtn; ENDCASE

    CASE #b0011101: //   11101  J
    CASE #b0111101:
    CASE #b1011101:
    CASE #b1111101: s_code!s := code>>5
                    a := f_j; ENDCASE

    CASE #b0000010: //   00010 SG
    CASE #b0100010:
    CASE #b1000010:
    CASE #b1100010: s_code!s := code>>5
                    a := f_sg; ENDCASE

    CASE #b0010010: //   10010 LP3
    CASE #b0110010:
    CASE #b1010010:
    CASE #b1110010: s_code!s := code>>5
                    a := f_lp0+3; ENDCASE

    CASE #b0000110: //  000110 LP4
    CASE #b1000110: s_code!s := code>>6
                    a := f_lp0+4; ENDCASE

    CASE #b0010110: //  010110 SP7
    CASE #b1010110: s_code!s := code>>6
                    a := f_sp+7; ENDCASE

    CASE #b0100110: //  100110 L0
    CASE #b1100110: s_code!s := code>>6
                    a := f_l0; ENDCASE

    CASE #b0110110: //  110110 XCH
    CASE #b1110110: s_code!s := code>>6
                    a := f_xch; ENDCASE

    CASE #b0001010: //  001010 K3G
    CASE #b1001010: s_code!s := code>>6
                    a := f_k0g+3; ENDCASE

    CASE #b0011010: //  011010 K4G
    CASE #b1011010: s_code!s := code>>6
                    a := f_k0g+4; ENDCASE

    CASE #b0101010: //  101010 K5G
    CASE #b1101010: s_code!s := code>>6
                    a := f_k0g+5; ENDCASE

    CASE #b0111010: //  111010 K6G
    CASE #b1111010: s_code!s := code>>6
                    a := f_k0g+6; ENDCASE

    CASE #b0001110: //  001110 K7G
    CASE #b1001110: s_code!s := code>>6
                    a := f_k0g+7; ENDCASE

    CASE #b0011110: //  011110 STRING
    CASE #b1011110: s_code!s := code>>6
                    a := f_string; ENDCASE

    CASE #b0101110: //  101110 LSTR
    CASE #b1101110: s_code!s := code>>6
                    a := f_lstr; ENDCASE

    CASE #b0111110: //  111110 JNE
    CASE #b1111110: s_code!s := code>>6
                    a := f_jne; ENDCASE


    CASE #b0000011: // 0000011 LP5
                    s_code!s := code>>7; a := f_lp0+5; ENDCASE
    CASE #b0010011: // 0010011 LP6
                    s_code!s := code>>7; a := f_lp0+6; ENDCASE
    CASE #b0100011: // 0100011 SP3
                    s_code!s := code>>7; a := f_sp0+3; ENDCASE
    CASE #b0110011: // 0110011 SP4
                    s_code!s := code>>7; a := f_sp0+4; ENDCASE
    CASE #b1000011: // 1000011 SP5
                    s_code!s := code>>7; a := f_sp0+5; ENDCASE
    CASE #b1010011: // 1010011 SP6
                    s_code!s := code>>7; a := f_sp0+6; ENDCASE
    CASE #b1100011: // 1100011 SP8
                    s_code!s := code>>7; a := f_sp0+8; ENDCASE
    CASE #b1110011: // 1110011 SP9
                    s_code!s := code>>7; a := f_sp0+9; ENDCASE
    CASE #b0000111: // 0000111 SP10
                    s_code!s := code>>7; a := f_sp0+10; ENDCASE
    CASE #b0010111: // 0010111 SP11
                    s_code!s := code>>7; a := f_sp0+11; ENDCASE
    CASE #b0100111: // 0100111 K
                    s_code!s := code>>7; a := f_k; ENDCASE
    CASE #b0110111: // 0110111 L1
                    s_code!s := code>>7; a := f_l0+1; ENDCASE
    CASE #b1000111: // 1000111 JEQ
                    s_code!s := code>>7; a := f_jeq; ENDCASE
    CASE #b1010111: // 1010111 JEQ0
                    s_code!s := code>>7; a := f_jeq0; ENDCASE
    CASE #b1100111: // 1100111 JGR
                    s_code!s := code>>7; a := f_jgr; ENDCASE
    CASE #b1110111: // 1110111 L1P3
                    s_code!s := code>>7; a := f_l1p0+3; ENDCASE

    CASE #b0001011: //    1011     L <7-bit>+128
    CASE #b0011011:
    CASE #b0101011:
    CASE #b0111011:
    CASE #b1001011:
    CASE #b1011011:
    CASE #b1101011:
    CASE #b1111011: s_code!s := code>>11
                    a := (code>>4 & 127)+128; ENDCASE

    CASE #B0001111: // 01111  L
    CASE #b0101111:
    CASE #b1001111:
    CASE #b1101111: s_code!s := code>>5
                    a := f_l; ENDCASE

    CASE #b0011111: // 11111     L <5-bit>+256
    CASE #b0111111:
    CASE #b1011111:
    CASE #b1111111: s_code!s := code>>10
                    a := (code>>5 & 31)+256; ENDCASE
  }

  s_a!s, hashtab!hashval := a, a
  RESULTIS a
}

AND nextG(s, val) = VALOF
{ LET buf = s_buf!s
  LET code = s_code!s

//       00000  NEXT
//       10000  BUF2
//        1000  BUF1
//      ddd100  BUF ddd+3
//          10  BUF0
//  <9-bit>001  L <9-bit>
//     ddd0101  ADD ddd+1
//     ddd1101  SUB ddd+1
//    ddd00011  INCBUF ddd+1
//    ddd01011  INCBUF ddd+1
//    ddd10011  INC2BUF ddd+1
//    ddd11011  INC2BUF ddd+1
// <12-bit>111  L <12-bit>

  IF buf=0 DO 
  { buf := getvec(10)
    FOR i = 0 TO 10 DO buf!i := i
    s_buf!s := buf
  }

sw:
  IF code=0 DO
  { code := !codep
    //writef("Gcode %x8*n", code)
    codep := codep + 1
  }

  SWITCHON code&31 INTO
  { DEFAULT: error("Bad Gcode %b8*n", code)
             abort(100)

    CASE #b00000: code := 0; GOTO sw
  
    CASE #b00010: //   #b10   BUF0
    CASE #b00110:
    CASE #b01010:
    CASE #b01110:
    CASE #b10010:
    CASE #b10110:
    CASE #b11010:
    CASE #b11110:
         s_code!s := code>>2
         RESULTIS buf!0

    CASE #b01000: // #b1000   BUF1
    CASE #b11000:
         s_code!s := code>>4
         { LET t = buf!1
           buf!1 := buf!0
           buf!0 := t
           RESULTIS t
         }

    CASE #b10000: // #b10000   BUF2
       s_code!s := code>>5
       { LET t = buf!2
         buf!2 := buf!1
         buf!1 := buf!0
         buf!0 := t
         RESULTIS t
       }

    CASE #b00100: //   #b100  BUF <3-bit>+3
    CASE #b01100: 
    CASE #b10100: 
    CASE #b11100: 
         s_code!s := code>>6
         { LET p = (code>>3 & 7) + 3 
           LET t = buf!p
           FOR i = p TO 1 BY -1 DO buf!i := buf!(i-1)
           buf!0 := t
           RESULTIS t
         }

    CASE #b00011: // #b00011  INCBUF1 - INCBUF8 
         s_code!s := code>>8
         { LET p = (code>>5 & 7) + 1 
           LET t = buf!p+1
           FOR i = p TO 1 BY -1 DO buf!i := buf!(i-1)
           buf!0 := t
           RESULTIS t
         }

    CASE #b01011: // #b01011  DECBUF1 - DECBUF8 
         s_code!s := code>>8
         { LET p = (code>>5 & 7) + 1 
           LET t = buf!p-1
           FOR i = p TO 1 BY -1 DO buf!i := buf!(i-1)
           buf!0 := t
           RESULTIS t
         }

    CASE #b10011: // #b10011  INC2BUF1 - INC2BUF8 
         s_code!s := code>>8
         { LET p = (code>>5 & 7) + 1 
           LET t = buf!p+2
           FOR i = p TO 1 BY -1 DO buf!i := buf!(i-1)
           buf!0 := t
           RESULTIS t
         }

    CASE #b11011: // #b11011  DEC2BUF1 - DEC2BUF8 
         s_code!s := code>>8
         { LET p = (code>>5 & 7) + 1 
           LET t = buf!p-2
           FOR i = p TO 1 BY -1 DO buf!i := buf!(i-1)
           buf!0 := t
           RESULTIS t
         }

    CASE #b00101: //  #b0101  ADD <3-bit>+1
    CASE #b10101:
         s_code!s := code>>7
         { LET p = (code>>4 & 7) + 1
           LET t = buf!0 + p
           FOR i = 10 TO 1 BY -1 DO buf!i := buf!(i-1)
           buf!0 := t
           RESULTIS t
         }

    CASE #b01101: //  #b1101  SUB <3-bit>+1
    CASE #b11101:
         s_code!s := code>>7
         { LET p = (code>>4 & 7) + 1
           LET t = buf!0 - p
           FOR i = 10 TO 1 BY -1 DO buf!i := buf!(i-1)
           buf!0 := t
           RESULTIS t
         }

    CASE #b00001: //   #b001  L <9-bit>
    CASE #b01001:
    CASE #b10001:
    CASE #b11001:
         s_code!s := code>>12
         { LET t = (code>>3 & #x1FF)
           FOR i = 10 TO 1 BY -1 DO buf!i := buf!(i-1)
           buf!0 := t
           RESULTIS t
         }

    CASE #b00111: //   #b111  L <12-bit>
    CASE #b01111:
    CASE #b10111:
    CASE #b11111:
         s_code!s := code>>15
         { LET t = (code>>3 & #xFFF)
           FOR i = 10 TO 1 BY -1 DO buf!i := buf!(i-1)
           buf!0 := t
           RESULTIS t
         }
  }
}

AND nextK(s) = VALOF
{ LET code, val, a = s_code!s, ?, s_a!s
sw:
  IF code=0 DO
  { code := !codep
//    writef("Kcode %x8*n", code)
    codep := codep + 1
  }

//writef("Kop = %bB  A = %n*n", code&#x7FF, a)

  SWITCHON code&7 INTO
  { DEFAULT: error("Bad Kcode %b8*n", code)
             abort(100)

    CASE #b100: s_code!s := code>>3
                RESULTIS a

    CASE #b000: s_code!s := code>>11
                val := code>>3 & 255
                s_a!s := val
                RESULTIS val

    CASE #b010:
    CASE #b110: s_code!s := code>>5
                val := code>>2 & 7
                s_a!s := val
                RESULTIS val

    CASE #b001:
    CASE #b101: s_code!s := code>>8
                val := (code>>2 & 63) + 8
                s_a!s := val
                RESULTIS val

    CASE #b011:
    CASE #b111: s_code!s := code>>8
                val := (code>>2 & 63) + 72
                s_a!s := val
                RESULTIS val
  }
}

AND nextL(s, val) = VALOF
{ LET buf = s_buf!s
  LET code, val, a, b = s_code!s, ?, ?, ?

  IF buf=0 DO 
  { buf := getvec(2)
    FOR i = 0 TO 2 DO buf!i := i
    s_buf!s := buf
  }

  a, b := buf!0, buf!1

sw:
  IF code=0 DO
  { code := !codep
//    writef("Lcode %x8*n", code)
    codep := codep + 1
  }

//writef("Lop = %b4  buf = %i4 %i4 %i4*n", code&15, a, b, buf!2)

  SWITCHON code&15 INTO
  { DEFAULT: error("Bad L or Mcode %b8*n", code)
             abort(100)

    CASE #b0000: code := 0; GOTO sw
  
    CASE #b1000:                      //   #b1000   BUF0
         s_code!s := code>>4
         RESULTIS a

    CASE #b0100:                      //   #b1000   DECBUF0
         s_code!s := code>>4
         val := a-1
         UNLESS val=b DO buf!2 := b
         buf!1 := a
         buf!0 := val
         RESULTIS val

    CASE #b1100:                      //   #b1100   INC2BUF0
         s_code!s := code>>4
         val := a+2
         UNLESS val=b DO buf!2 := b
         buf!1 := a
         buf!0 := val
         RESULTIS val

    CASE #b0001:                      //   #b01   INCBUF0
    CASE #b0101:
    CASE #b1001:
    CASE #b1101:
         s_code!s := code>>2
         val := a+1
         UNLESS val=b DO buf!2 := b
         buf!1 := a
         buf!0 := val
         RESULTIS val


    CASE #b0010:                      //   #b10   INCBUF1
    CASE #b0110:
    CASE #b1010:
    CASE #b1110:
         s_code!s := code>>2
         val := b+1
         buf!2 := b
         buf!1 := a
         buf!0 := val
         RESULTIS val

    CASE #b0011:                      //  #b00011   BUF1
         s_code!s := code>>5          //  #b10011   BUF2
         val := b
         UNLESS (code&#b10000)=0 DO { val := buf!2; buf!2 := b }
         buf!1 := a
         buf!0 := val
         RESULTIS val

    CASE #b1011:                      //   #b1011  DEC2BUF0 - DEC65BUF0
         s_code!s := code>>10
         val := a - (code>>4 & 63) - 2
         buf!2 := b
         buf!1 := a
         buf!0 := val
         RESULTIS val

    CASE #b0111:                      //   #b0111  INC3BUF0 - INC66BUF0
         s_code!s := code>>10
         val := a + (code>>4 & 63) + 3
         buf!2 := b
         buf!1 := a
         buf!0 := val
         RESULTIS val

    CASE #b1111:                 //   #b1111  L <16-bit>
         s_code!s := code>>20
         val := (code>>4 & #xFFFF)
         buf!2 := b
         buf!1 := a
         buf!0 := val
         RESULTIS val
  }
}

LET nextC(s) = VALOF
{ MANIFEST { hashtabupb=511 }
  LET code = s_code!s
  LET ch = ?
  
  LET a, b, sh  = s_a!s, s_b!s, s_c!s

  LET hashval = (b<<6 NEQV a) REM (hashtabupb+1) 
  LET hashtab = s_buf!s

  IF hashtab=0 DO 
  { hashtab := getvec(hashtabupb/bytesperword)
    FOR i = 0 TO hashtabupb DO hashtab%i := ' '
    s_buf!s := hashtab
  }

sw:
  IF code=0 DO
  { code := !codep
    //writef("Ccode %x8*n", code)
    codep := codep + 1
  }

  SWITCHON code&15 INTO
  { DEFAULT: error("Bad Ccode %b8*n", code)
             abort(100)
             code := 0
             GOTO sw

    CASE #b0000: SWITCHON code>>4 & 15 INTO
         { CASE #b0000: code := !codep
                        //writef("Ccode %x8*n", code)
                        codep := codep + 1
                        GOTO sw
           CASE #b1000:
           CASE #b0100:
           CASE #b1100: error("Bad Ccode %b8*n", code)
                        ch := '0';  ENDCASE  

           CASE #b0010: ch := '*n'; ENDCASE  // *n
           CASE #b0110: ch := '%';  ENDCASE  //  %
           CASE #b1010: ch := '8';  ENDCASE  //  8
           CASE #b1110: ch := '9';  ENDCASE  //  9

           CASE #b0001: ch := '0';  ENDCASE  //  0
           CASE #b0011: ch := '1';  ENDCASE  //  1
           CASE #b0101: ch := '2';  ENDCASE  //  2
           CASE #b0111: ch := '3';  ENDCASE  //  3
           CASE #b1001: ch := '4';  ENDCASE  //  4
           CASE #b1011: ch := '5';  ENDCASE  //  5
           CASE #b1101: ch := '6';  ENDCASE  //  6
           CASE #b1111: ch := '7';  ENDCASE  //  7
         }
         s_code!s := code>>8; ENDCASE

    CASE #b1000: ch := '*s'                  // *s
                 s_code!s := code>>4; ENDCASE

    CASE #b0100:
    CASE #b1100: SWITCHON code>>3 & 3 INTO
         { CASE #b00: ch := 'e';  ENDCASE  //  E or e
           CASE #b01: ch := 'l';  ENDCASE  //  L or l
           CASE #b10: ch := 'r';  ENDCASE  //  R or r
           CASE #b11: ch := 's';  ENDCASE  //  S or s
         }
         ch := ch + sh
         s_code!s := code>>5; ENDCASE


    CASE #b0010:                           //  PRED
    CASE #b0110:
    CASE #b1010:
    CASE #b1110: ch := hashtab%hashval
                 s_code!s := code>>2; ENDCASE

    CASE #b0001:
    CASE #b0101:
    CASE #b1001:
    CASE #b1101: SWITCHON code>>2 & 15 INTO
         { CASE #b0000: ch := 'n';  ENDCASE  //  N or n
           CASE #b0001: ch := 'a';  ENDCASE  //  A or a
           CASE #b0010: ch := 't';  ENDCASE  //  T or t
           CASE #b0011: ch := 'o';  ENDCASE  //  O or o
           CASE #b0100: ch := 'i';  ENDCASE  //  I or i
           CASE #b0101: ch := 'p';  ENDCASE  //  P or p
           CASE #b0110: ch := 'c';  ENDCASE  //  C or c
           CASE #b0111: ch := 'd';  ENDCASE  //  D or d
           CASE #b1000: ch := 'g';  ENDCASE  //  G or g
           CASE #b1001: ch := 'b';  ENDCASE  //  B or b
           CASE #b1010: ch := 'm';  ENDCASE  //  M or m
           CASE #b1011: ch := 'f';  ENDCASE  //  F or f
           CASE #b1100: ch := 'h';  ENDCASE  //  H or h
           CASE #b1101: ch := 'k';  ENDCASE  //  K or k
           CASE #b1110: ch := 'u';  ENDCASE  //  U or u
           CASE #b1111: ch := 'w';  ENDCASE  //  W or w
         }
         ch := ch + sh
         s_code!s := code>>6; ENDCASE


    CASE #b0011: ch := (code>>4 & 31) + 32;    // L <5-bits>+32
                 s_code!s := code>>9; ENDCASE

    CASE #b1011: ch := (code>>4 & 31) + 64;    // L <5-bits>+64
                 s_code!s := code>>9; ENDCASE

    CASE #b0111: ch := (code>>4 & 31) + 96;    // L <5-bits>+96
                 s_code!s := code>>9; ENDCASE

    CASE #b1111: ch := (code>>4 & 127);        // L <8-bits>
                 s_code!s := code>>12; ENDCASE
  }

  IF 'a'<=ch<='z' DO s_c!s := 0
  IF 'A'<=ch<='Z' DO s_c!s := 'A' - 'a'
  hashtab%hashval := ch
  s_a!s, s_b!s := ch, a

  RESULTIS ch
}


AND mkstream(nextfn) = VALOF
{ LET s = getvec(s_upb)
  IF s=0 DO error("Unable to make a stream")
  FOR i = 0 TO s_upb DO s!i := 0
  s_nextfn!s := nextfn
  s_sh!s     := 32
  RESULTIS s
}

AND unmkstream(str) BE
{ UNLESS s_buf!str=0 DO freevec(s_buf!str)
  freevec(str)
}
 
AND openstreams() BE
{ Fstr := mkstream(nextF)
  Pstr := mkstream(nextN)
  Gstr := mkstream(nextG)
  Kstr := mkstream(nextK)
  Hstr := mkstream(nextN)
  Wstr := mkstream(nextN)
  Cstr := mkstream(nextC)
  Lstr := mkstream(nextL)
  Mstr := mkstream(nextL)
}

AND closestreams() BE
{ unmkstream(Fstr); Fstr := 0
  unmkstream(Pstr); Pstr := 0
  unmkstream(Gstr); Gstr := 0
  unmkstream(Kstr); Kstr := 0
  unmkstream(Hstr); Hstr := 0
  unmkstream(Wstr); Wstr := 0
  unmkstream(Cstr); Cstr := 0
  unmkstream(Lstr); Lstr := 0
  unmkstream(Mstr); Mstr := 0
}

LET start() = VALOF
$( LET argv = VEC 20

   cialout := 0
   stdout := output()
   IF rdargs("FROM,TO/K", argv, 20)=0 DO
   $( writes("Bad args for expcial*n")
      RESULTIS 20
   $)
   IF argv!0=0 DO argv!0 := "CODE"
   IF argv!1=0 DO argv!1 := "res"
   codein := findinput(argv!0)
   IF codein=0 DO
   $( writef("Trouble with file %s*n", argv!0)
      RESULTIS 20
   $)
   cialout := findoutput(argv!1)
   
   IF cialout=0 DO
   $( writef("Trouble with file %s*n", argv!1)
      RESULTIS 20
   $)
   
   writef("Expanding cial %s to %s*n", argv!0, argv!1)
   selectinput(codein)
   selectoutput(cialout)

   { LET type, size = rdhex(), 0
     UNLESS type=t_chunk BREAK
     size := rdhex()
     labmax := rdhex()
     mlabmax := rdhex()
     
     codev := getvec(size)
   
     IF codev=0 DO
     $( writef("Unable to allocate code vector*n")
        RESULTIS 20
     $)

     FOR i = 0 TO size-1 DO codev!i := rdhex()
     codep, codet := codev, codev+size

     openstreams()
     scan()
     closestreams()

     freevec(codev)
   } REPEAT

   endread()
   UNLESS cialout=stdout DO endwrite()
   selectoutput(stdout)
   writef("Conversion complete*n")
   RESULTIS 0
$)

// argument may be of form Ln
AND rdcode(let) = VALOF
$( LET a, ch = 0, ?

   ch := rdch() REPEATWHILE ch='*s' | ch='*n'

   IF ch=endstreamch RESULTIS -1

//   UNLESS ch=let DO error("Bad item, looking for %c found %c*n", let, ch)

//   ch := rdch()

   WHILE '0'<=ch<='9' DO $( a := 10*a + ch - '0'; ch := rdch()  $)

   RESULTIS a
$)

AND rdf() = next(Fstr)
AND rdp() = next(Pstr)
AND rdg() = next(Gstr)
AND rdk() = next(Kstr)
AND rdh() = next(Hstr)
AND rdw() = next(Wstr)
AND rdl() = next(Lstr)
AND rdm() = next(Mstr)
AND rdc() = next(Cstr)

AND wrcode(let, x) BE writef("%c%n*n", let, x)

AND wrf(x) BE wrcode('F', x)
AND wrp(x) BE wrcode('P', x)
AND wrg(x) BE wrcode('G', x)
AND wrk(x) BE wrcode('K', x)
AND wrh(x) BE wrcode('H', x)
AND wrw(x) BE wrcode('W', x)
AND wrl(x) BE wrcode('L', x)
AND wrm(x) BE wrcode('M', x)
AND wrc(x) BE wrcode('C', x)

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

//writef("F%n*n", op)
   SWITCHON op INTO

   $( DEFAULT:          error("Bad op %n*n", op); LOOP

      CASE -1:          RETURN
      
      CASE f_k0+3:      cvf(op); ENDCASE
      CASE f_k0+4:      cvf(op); ENDCASE
      CASE f_k0+5:      cvf(op); ENDCASE
      CASE f_k0+6:      cvf(op); ENDCASE
      CASE f_k0+7:      cvf(op); ENDCASE
      CASE f_k0+8:      cvf(op); ENDCASE
      CASE f_k0+9:      cvf(op); ENDCASE
      CASE f_k0+10:     cvf(op); ENDCASE
      CASE f_k0+11:     cvf(op); ENDCASE
      CASE f_lf:        cvfl(op); ENDCASE
      CASE f_lm:        cvfk(op); ENDCASE
      CASE f_lm1:       cvf(op); ENDCASE
      CASE f_l0:        cvf(op); ENDCASE    
      CASE f_l0+1:      cvf(op); ENDCASE
      CASE f_l0+2:      cvf(op); ENDCASE
      CASE f_l0+3:      cvf(op); ENDCASE
      CASE f_l0+4:      cvf(op); ENDCASE
      CASE f_l0+5:      cvf(op); ENDCASE
      CASE f_l0+6:      cvf(op); ENDCASE
      CASE f_l0+7:      cvf(op); ENDCASE
      CASE f_l0+8:      cvf(op); ENDCASE
      CASE f_l0+9:      cvf(op); ENDCASE
      CASE f_l0+10:     cvf(op); ENDCASE
//      CASE f_fhop: //=  27
      CASE f_jeq:       cvfl(op); ENDCASE
      CASE f_jeq0:      cvfl(op); ENDCASE

      CASE f_k:         cvfp(op); ENDCASE
      CASE f_kh:        cvfh(op); ENDCASE
      CASE f_kw:        cvfw(op); ENDCASE
      CASE f_k0g+3:     cvfg(op); ENDCASE
      CASE f_k0g+4:     cvfg(op); ENDCASE
      CASE f_k0g+5:     cvfg(op); ENDCASE
      CASE f_k0g+6:     cvfg(op); ENDCASE
      CASE f_k0g+7:     cvfg(op); ENDCASE
      CASE f_k0g+8:     cvfg(op); ENDCASE
      CASE f_k0g+9:     cvfg(op); ENDCASE
      CASE f_k0g+10:    cvfg(op); ENDCASE
      CASE f_k0g+11:    cvfg(op); ENDCASE
      CASE f_s0g:       cvfg(op); ENDCASE
      CASE f_l0g:       cvfg(op); ENDCASE
      CASE f_l1g:       cvfg(op); ENDCASE
      CASE f_l2g:       cvfg(op); ENDCASE
      CASE f_lg:        cvfg(op); ENDCASE
      CASE f_sg:        cvfg(op); ENDCASE
      CASE f_llg:       cvfg(op); ENDCASE
      CASE f_ag:        cvfg(op); ENDCASE
      CASE f_mul:       cvf(op); ENDCASE
      CASE f_div:       cvf(op); ENDCASE
      CASE f_rem:       cvf(op); ENDCASE
      CASE f_xor:       cvf(op); ENDCASE
      CASE f_sl:        cvfl(op); ENDCASE
      CASE f_ll:        cvfl(op); ENDCASE
      CASE f_jne:       cvfl(op); ENDCASE
      CASE f_jne0:      cvfl(op); ENDCASE

      CASE f_llp:       cvfp(op); ENDCASE
      CASE f_llph:      cvfh(op); ENDCASE
      CASE f_llpw:      cvfw(op); ENDCASE
      CASE f_add:       cvf(op); ENDCASE
      CASE f_sub:       cvf(op); ENDCASE
      CASE f_lsh:       cvf(op); ENDCASE
      CASE f_rsh:       cvf(op); ENDCASE
      CASE f_and:       cvf(op); ENDCASE
      CASE f_or:        cvf(op); ENDCASE
      CASE f_lll:       cvfl(op); ENDCASE
      CASE f_jls:       cvfl(op); ENDCASE
      CASE f_jls0:      cvfl(op); ENDCASE

      CASE f_l:         cvfk(op); ENDCASE
      CASE f_lh:        cvfh(op); ENDCASE
      CASE f_lw:        cvfw(op); ENDCASE
      CASE f_rv:        cvf(op); ENDCASE
      CASE f_rv+1:      cvf(op); ENDCASE
      CASE f_rv+2:      cvf(op); ENDCASE
      CASE f_rv+3:      cvf(op); ENDCASE
      CASE f_rv+4:      cvf(op); ENDCASE
      CASE f_rv+5:      cvf(op); ENDCASE
      CASE f_rv+6:      cvf(op); ENDCASE
      CASE f_rtn:       cvf(op); ENDCASE
      CASE f_jgr:       cvfl(op); ENDCASE
      CASE f_jgr0:      cvfl(op); ENDCASE

      CASE f_lp:        cvfp(op); ENDCASE
      CASE f_lph:       cvfh(op); ENDCASE
      CASE f_lpw:       cvfw(op); ENDCASE
      CASE f_lp0+3:     cvf(op); ENDCASE
      CASE f_lp0+4:     cvf(op); ENDCASE
      CASE f_lp0+5:     cvf(op); ENDCASE
      CASE f_lp0+6:     cvf(op); ENDCASE
      CASE f_lp0+7:     cvf(op); ENDCASE
      CASE f_lp0+8:     cvf(op); ENDCASE
      CASE f_lp0+9:     cvf(op); ENDCASE
      CASE f_lp0+10:    cvf(op); ENDCASE
      CASE f_lp0+11:    cvf(op); ENDCASE
      CASE f_lp0+12:    cvf(op); ENDCASE
      CASE f_lp0+13:    cvf(op); ENDCASE
      CASE f_lp0+14:    cvf(op); ENDCASE
      CASE f_lp0+15:    cvf(op); ENDCASE
      CASE f_lp0+16:    cvf(op); ENDCASE
      CASE f_swb:       cvswb(op); ENDCASE
      CASE f_swl:       cvswl(op); ENDCASE
      CASE f_st:        cvf(op); ENDCASE
      CASE f_st0+1:     cvf(op); ENDCASE
      CASE f_st0+2:     cvf(op); ENDCASE
      CASE f_st0+3:     cvf(op); ENDCASE
      CASE f_stp0+3:    cvf(op); ENDCASE
      CASE f_stp0+4:    cvf(op); ENDCASE
      CASE f_stp0+5:    cvf(op); ENDCASE
      CASE f_goto:      cvf(op); ENDCASE
      CASE f_jle:       cvfl(op); ENDCASE
      CASE f_jle0:      cvfl(op); ENDCASE

      CASE f_sp:        cvfp(op); ENDCASE
      CASE f_sph:       cvfh(op); ENDCASE
      CASE f_spw:       cvfw(op); ENDCASE
      CASE f_sp0+3:     cvf(op); ENDCASE
      CASE f_sp0+4:     cvf(op); ENDCASE
      CASE f_sp0+5:     cvf(op); ENDCASE
      CASE f_sp0+6:     cvf(op); ENDCASE
      CASE f_sp0+7:     cvf(op); ENDCASE
      CASE f_sp0+8:     cvf(op); ENDCASE
      CASE f_sp0+9:     cvf(op); ENDCASE
      CASE f_sp0+10:    cvf(op); ENDCASE
      CASE f_sp0+11:    cvf(op); ENDCASE
      CASE f_sp0+12:    cvf(op); ENDCASE
      CASE f_sp0+13:    cvf(op); ENDCASE
      CASE f_sp0+14:    cvf(op); ENDCASE
      CASE f_sp0+15:    cvf(op); ENDCASE
      CASE f_sp0+16:    cvf(op); ENDCASE
      CASE f_s0+1:      cvf(op); ENDCASE
      CASE f_s0+2:      cvf(op); ENDCASE
      CASE f_s0+3:      cvf(op); ENDCASE
      CASE f_s0+4:      cvf(op); ENDCASE
      CASE f_xch:       cvf(op); ENDCASE
      CASE f_gbyt:      cvf(op); ENDCASE
      CASE f_pbyt:      cvf(op); ENDCASE
      CASE f_atc:       cvf(op); ENDCASE
      CASE f_atb:       cvf(op); ENDCASE
      CASE f_j:         cvfl(op); ENDCASE
      CASE f_jge:       cvfl(op); ENDCASE
      CASE f_jge0:      cvfl(op); ENDCASE

      CASE f_ap:        cvfp(op); ENDCASE
      CASE f_aph:       cvfh(op); ENDCASE
      CASE f_apw:       cvfw(op); ENDCASE
      CASE f_ap0+3:     cvf(op); ENDCASE
      CASE f_ap0+4:     cvf(op); ENDCASE
      CASE f_ap0+5:     cvf(op); ENDCASE
      CASE f_ap0+6:     cvf(op); ENDCASE
      CASE f_ap0+7:     cvf(op); ENDCASE
      CASE f_ap0+8:     cvf(op); ENDCASE
      CASE f_ap0+9:     cvf(op); ENDCASE
      CASE f_ap0+10:    cvf(op); ENDCASE
      CASE f_ap0+11:    cvf(op); ENDCASE
      CASE f_ap0+12:    cvf(op); ENDCASE
      CASE f_xpbyt:     cvf(op); ENDCASE
      CASE f_lmh:       cvfh(op); ENDCASE
      CASE f_btc:       cvf(op); ENDCASE
      CASE f_nop:       cvf(op); ENDCASE
      CASE f_a0+1:      cvf(op); ENDCASE
      CASE f_a0+2:      cvf(op); ENDCASE
      CASE f_a0+3:      cvf(op); ENDCASE
      CASE f_a0+4:      cvf(op); ENDCASE
      CASE f_a0+5:      cvf(op); ENDCASE
      CASE f_rvp0+3:    cvf(op); ENDCASE
      CASE f_rvp0+4:    cvf(op); ENDCASE
      CASE f_rvp0+5:    cvf(op); ENDCASE
      CASE f_rvp0+6:    cvf(op); ENDCASE
      CASE f_rvp0+7:    cvf(op); ENDCASE

      CASE f_st0p0+3:   cvf(op); ENDCASE
      CASE f_st0p0+4:   cvf(op); ENDCASE
      CASE f_st1p0+3:   cvf(op); ENDCASE
      CASE f_st1p0+4:   cvf(op); ENDCASE

      CASE f_a:          cvfk(op); ENDCASE
      CASE f_ah:         cvfh(op); ENDCASE
      CASE f_aw:         cvfw(op); ENDCASE
      CASE f_l0p0+3:     cvf(op); ENDCASE
      CASE f_l0p0+4:     cvf(op); ENDCASE
      CASE f_l0p0+5:     cvf(op); ENDCASE
      CASE f_l0p0+6:     cvf(op); ENDCASE
      CASE f_l0p0+7:     cvf(op); ENDCASE
      CASE f_l0p0+8:     cvf(op); ENDCASE
      CASE f_l0p0+9:     cvf(op); ENDCASE
      CASE f_l0p0+10:    cvf(op); ENDCASE
      CASE f_l0p0+11:    cvf(op); ENDCASE
      CASE f_l0p0+12:    cvf(op); ENDCASE
      CASE f_s:          cvfk(op); ENDCASE
      CASE f_sh:         cvfh(op); ENDCASE
      CASE f_mdiv:       cvf(op); ENDCASE
      CASE f_chgco:      cvf(op); ENDCASE
      CASE f_neg:        cvf(op); ENDCASE
      CASE f_not:        cvf(op); ENDCASE

      CASE f_l1p0+3:     cvf(op); ENDCASE
      CASE f_l1p0+4:     cvf(op); ENDCASE
      CASE f_l1p0+5:     cvf(op); ENDCASE
      CASE f_l1p0+6:     cvf(op); ENDCASE
      CASE f_l2p0+3:     cvf(op); ENDCASE
      CASE f_l2p0+4:     cvf(op); ENDCASE
      CASE f_l2p0+5:     cvf(op); ENDCASE
      CASE f_l3p0+3:     cvf(op); ENDCASE
      CASE f_l3p0+4:     cvf(op); ENDCASE
      CASE f_l4p0+3:     cvf(op); ENDCASE
      CASE f_l4p0+4:     cvf(op); ENDCASE

      CASE f_section:    cvfs(op); ENDCASE
      CASE f_modstart:   cvf(op); ENDCASE
      CASE f_modend:     cvf(op); RETURN
      CASE f_abs:        cvf(op); ENDCASE
      CASE f_global:     cvglobal(op); ENDCASE
      CASE f_string:     cvstring(op); ENDCASE
      CASE f_eq:         cvf(op); ENDCASE
      CASE f_ne:         cvf(op); ENDCASE
      CASE f_ls:         cvf(op); ENDCASE
      CASE f_gr:         cvf(op); ENDCASE
      CASE f_le:         cvf(op); ENDCASE
      CASE f_ge:         cvf(op); ENDCASE
      CASE f_eq0:        cvf(op); ENDCASE
      CASE f_ne0:        cvf(op); ENDCASE
      CASE f_ls0:        cvf(op); ENDCASE
      CASE f_gr0:        cvf(op); ENDCASE
      CASE f_le0:        cvf(op); ENDCASE
      CASE f_ge0:        cvf(op); ENDCASE
      CASE f_eqv:        cvf(op); ENDCASE
      CASE f_wdata:      cvfw(op); ENDCASE
      CASE f_dlab:       cvfl(op); ENDCASE
      CASE f_lstr:       cvfm(op); ENDCASE
      CASE f_lab:        cvfl(op); ENDCASE
      CASE f_mlab:       cvfm(op); ENDCASE
      CASE f_jge0m:      cvfm(op); ENDCASE
      CASE f_entry:      cventry(op); ENDCASE
   $)
$) REPEAT

AND cvf(f)  BE wrf(f)
AND cvfp(f) BE { wrf(f); wrp(rdp()) }
AND cvfg(f) BE { wrf(f); wrg(rdg()) }
AND cvfk(f) BE { wrf(f); wrk(rdk()) }
AND cvfh(f) BE { wrf(f); wrh(rdh()) }
AND cvfw(f) BE { wrf(f); wrw(rdw()) }
AND cvfl(f) BE { wrf(f); wrl(rdl()) }
AND cvfm(f) BE { wrf(f); wrm(rdm()) }

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

AND cvfs(f) BE
$( LET n = rdk()
   wrf(f)
   wrk(n)
   FOR i = 1 TO n DO wrc(rdc())
$)

AND cventry(f) BE
$( LET n = rdk()
   LET v = VEC 256
   v%0 := n
   FOR i = 1 TO n DO v%i := rdc()
   wrf(f)
   wrk(n)
   FOR i = 1 TO n DO wrc(v%i)
$)
