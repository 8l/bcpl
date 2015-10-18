// This is a generalisation of the Advanced Encryption Standard
// using matrices of sizes 4x4, 8x8 or 16x16.

// Implemented by Martin Richards (c) June 2015

// This implementation is designed to be easy to understand
// and has made no attempt to be particularly efficient.

/*
Usage: aesnxn n/n,-t/s,stats/s

n = 4, 8 or 16 for the matrix size 4x4, 8x8 or 16x16
-t      turns on tracing
stats   generates statistcs output

For example:

0.000> aesnxn 8 stats

plain:          
 0001020304050607 08090A0B0C0D0E0F 1011121314151617 18191A1B1C1D1E1F
 2021222324252627 28292A2B2C2D2E2F 3031323334353637 38393A3B3C3D3E3F

key:            
 0000010102020303 0404050506060707 080809090A0A0B0B 0C0C0D0D0E0E0F0F
 1010111112121313 1414151516161717 181819191A1A1B1B 1C1C1D1D1E1E1F1F


Cipher text:    
 A6ACEC33EF7C8EE1 0C26D662D2AE0B17 4CD47491DBAA379B 69B254B3E3513FF6
 6C9CD2154D3E3DBD A760EAF5235ADC95 6295EE32BAB47463 52F9BE06CD22EA42

InvCipher text: 
 0001020304050607 08090A0B0C0D0E0F 1011121314151617 18191A1B1C1D1E1F
 2021222324252627 28292A2B2C2D2E2F 3031323334353637 38393A3B3C3D3E3F


Cintcode instruction counts

KeyExpansion:     35949
Cipher:          875707
InvCipher:      2126293


Encoding statistics


Histogram of the number of bits changed

   0:    0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0
  16:    0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0
  32:    0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0
  48:    0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0
  64:    0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0
  80:    0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0
  96:    0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0
 112:    0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0
 128:    0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0
 144:    0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0
 160:    0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0
 176:    0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0
 192:    0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0
 208:    0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0
 224:    1   0   1   0   0   1   1   2   4   2   2   3   7   2   6   6
 240:    8   4   7  11  12  12  13  19  16  13  14  12  13  21  21  21
 256:   17  12  16  14  22  13  11  17  16  18  10  13  13   6  10   7
 272:    7   9   3   6   3   2   3   2   1   2   1   1   1   0   0   1
 288:    0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0
 304:    0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0
 320:    0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0
 336:    0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0
 352:    0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0
 368:    0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0
 384:    0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0
 400:    0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0
 416:    0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0
 432:    0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0
 448:    0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0
 464:    0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0
 480:    0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0
 496:    0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0

Histogram of the number of times each bit changes

   0:   251  275  239  261  257  268  224  247  267  258  266  257  246  252  259  255
  16:   251  257  260  268  273  267  264  245  270  252  231  255  244  262  274  262
  32:   256  255  261  245  252  251  258  252  265  254  257  259  264  256  246  266
  48:   269  234  251  263  247  261  230  248  259  258  266  255  260  240  265  271
  64:   257  249  254  252  256  279  249  265  268  268  235  270  280  246  245  259
  80:   246  271  266  232  259  249  244  265  250  246  250  276  267  265  256  252
  96:   263  251  272  238  270  254  264  261  261  259  239  266  260  258  268  257
 112:   257  242  269  241  258  275  244  281  248  251  232  258  248  279  238  257
 128:   265  237  240  252  250  251  262  264  261  269  233  254  238  244  248  243
 144:   268  269  242  257  252  266  257  245  252  264  244  275  252  244  250  254
 160:   267  243  243  281  225  272  263  269  243  273  249  261  267  263  252  259
 176:   249  250  229  264  249  246  245  252  242  247  262  240  267  249  270  266
 192:   266  266  256  227  255  263  250  270  236  258  262  255  265  270  258  263
 208:   245  238  243  257  267  257  250  255  235  250  266  253  255  253  257  239
 224:   249  265  259  245  238  245  246  253  254  272  255  256  246  264  258  272
 240:   259  260  235  257  263  256  271  240  251  264  258  254  268  257  272  232
 256:   252  227  266  248  252  241  250  267  272  259  255  248  257  281  258  271
 272:   242  259  261  251  252  260  241  253  252  261  264  244  252  276  265  264
 288:   262  258  273  247  260  243  246  238  257  270  263  271  246  248  247  250
 304:   266  236  267  250  264  262  271  272  259  245  272  256  256  266  241  256
 320:   245  247  262  249  245  255  250  256  222  238  247  260  272  245  249  248
 336:   256  254  260  277  253  258  251  241  259  260  256  264  274  245  256  237
 352:   256  249  254  258  240  272  239  254  256  255  258  260  260  245  252  247
 368:   252  265  235  263  251  260  257  234  264  271  237  253  259  276  261  274
 384:   287  244  245  277  273  248  254  252  241  258  278  271  247  262  257  248
 400:   250  258  258  233  287  269  265  262  247  258  261  260  245  270  242  233
 416:   244  243  262  259  259  264  263  260  265  265  275  260  271  246  260  272
 432:   242  257  261  250  254  251  242  261  257  266  259  251  252  249  259  260
 448:   260  241  259  267  260  240  267  264  270  246  279  247  256  271  270  253
 464:   264  251  260  235  264  252  241  255  271  259  256  255  249  251  271  256
 480:   265  247  238  267  256  251  250  256  257  265  259  236  266  247  259  254
 496:   255  265  263  259  257  267  275  243  272  236  251  247  265  257  250  252
3.190> 
*/

GET "libhdr"

GLOBAL {
  Rkey:ug
  sbox
  rsbox
  mul
  tracing
  stats            // generate statistcs output
  MixColumns_ts
  InvMixColumns_st
  Cipher
  InvCipher
  prstate
  prbytes

  mixmat
  invmixmat

  in
  out
  plain
  key
  Rkey
  stateS
  stateT
  bitcountv    // Counts of the number of bits changed in the
               // encrypted for the test series of encryptions.
  bitsumv      // Counts of how often each bit of encrypted
               // data changes for the test series of encryptions.

  transpose

  n        // 4x4, 8x8 or 16x16 matrix sizes
  Matsize
  Nr       // Number of rounds
}

LET setmixmats() BE
{ IF n=4 DO
  { mixmat := TABLE
      2, 3, 1, 1,
      1, 2, 3, 1,
      1, 1, 2, 3,
      3, 1, 1, 2

    invmixmat := TABLE
      14,11,13, 9,
       9,14,11,13,
      13, 9,14,11,
      11,13, 9,14

    RETURN
  }

  // The following matrices and their inverses we discovered
  // with the aid of invert.b

  IF n=8 DO
  { mixmat := TABLE
      2,3,4,5,6,1,1,1,
      1,2,3,4,5,6,1,1,
      1,1,2,3,4,5,6,1,
      1,1,1,2,3,4,5,6,
      6,1,1,1,2,3,4,5,
      5,6,1,1,1,2,3,4,
      4,5,6,1,1,1,2,3,
      3,4,5,6,1,1,1,2

    invmixmat := TABLE
       73,129,196,102,231,219, 65,198,
      198, 73,129,196,102,231,219, 65,
       65,198, 73,129,196,102,231,219,
      219, 65,198, 73,129,196,102,231,
      231,219, 65,198, 73,129,196,102,
      102,231,219, 65,198, 73,129,196,
      196,102,231,219, 65,198, 73,129,
      129,196,102,231,219, 65,198, 73

    RETURN
  }

  IF n=16 DO
  { mixmat := TABLE
      2,3,4,5,6,7,8,9,8,1,1,1,1,1,1,1,
      1,2,3,4,5,6,7,8,9,8,1,1,1,1,1,1,
      1,1,2,3,4,5,6,7,8,9,8,1,1,1,1,1,
      1,1,1,2,3,4,5,6,7,8,9,8,1,1,1,1,
      1,1,1,1,2,3,4,5,6,7,8,9,8,1,1,1,
      1,1,1,1,1,2,3,4,5,6,7,8,9,8,1,1,
      1,1,1,1,1,1,2,3,4,5,6,7,8,9,8,1,
      1,1,1,1,1,1,1,2,3,4,5,6,7,8,9,8,
      8,1,1,1,1,1,1,1,2,3,4,5,6,7,8,9,
      9,8,1,1,1,1,1,1,1,2,3,4,5,6,7,8,
      8,9,8,1,1,1,1,1,1,1,2,3,4,5,6,7,
      7,8,9,8,1,1,1,1,1,1,1,2,3,4,5,6,
      6,7,8,9,8,1,1,1,1,1,1,1,2,3,4,5,
      5,6,7,8,9,8,1,1,1,1,1,1,1,2,3,4,
      4,5,6,7,8,9,8,1,1,1,1,1,1,1,2,3,
      3,4,5,6,7,8,9,8,1,1,1,1,1,1,1,2

    invmixmat := TABLE
      72,242,169,128,148, 46,252, 82, 93,203, 29, 26,247,227,192,141,
     141, 72,242,169,128,148, 46,252, 82, 93,203, 29, 26,247,227,192,
     192,141, 72,242,169,128,148, 46,252, 82, 93,203, 29, 26,247,227,
     227,192,141, 72,242,169,128,148, 46,252, 82, 93,203, 29, 26,247,
     247,227,192,141, 72,242,169,128,148, 46,252, 82, 93,203, 29, 26,
      26,247,227,192,141, 72,242,169,128,148, 46,252, 82, 93,203, 29,
      29, 26,247,227,192,141, 72,242,169,128,148, 46,252, 82, 93,203,
     203, 29, 26,247,227,192,141, 72,242,169,128,148, 46,252, 82, 93,
      93,203, 29, 26,247,227,192,141, 72,242,169,128,148, 46,252, 82,
      82, 93,203, 29, 26,247,227,192,141, 72,242,169,128,148, 46,252,
     252, 82, 93,203, 29, 26,247,227,192,141, 72,242,169,128,148, 46,
      46,252, 82, 93,203, 29, 26,247,227,192,141, 72,242,169,128,148,
     148, 46,252, 82, 93,203, 29, 26,247,227,192,141, 72,242,169,128,
     128,148, 46,252, 82, 93,203, 29, 26,247,227,192,141, 72,242,169,
     169,128,148, 46,252, 82, 93,203, 29, 26,247,227,192,141, 72,242,
     242,169,128,148, 46,252, 82, 93,203, 29, 26,247,227,192,141, 72

    RETURN
  }

  writef("*nERROR: Only 4x4, 8x8 or 16x16 matrices are allowed*n")
  stop(0, 0)
}

AND setplain(v) BE
{ // Choose some plain text depending on the state matrix size
  IF n=4 DO
  { LET key = TABLE
      #x00,#x11,#x22,#x33,#x44,#x55,#x66,#x77,#x88,#x99,#xAA,#xBB,#xCC,#xDD,#xEE,#xFF
    FOR i = 0 TO Matsize-1 DO v!i := key!i
    RETURN
  }

 IF n=8 DO
  { FOR i = 0 TO Matsize-1 DO v!i := i
    RETURN
  }

 IF n=16 DO
  { FOR i = 0 TO Matsize-1 DO v!i := i
    RETURN
  }

  writef("Bad n=%n in set plain*n", n)
  abort(1000)
}


AND setkey(v) BE
{ // Choose a key depending on the state matrix size.
  IF n=4 DO
  { LET key = TABLE
      #x00,#x01,#x02,#x03,#x04,#x05,#x06,#x07,#x08,#x09,#x0A,#x0B,#x0C,#x0D,#x0E,#x0F
    FOR i = 0 TO Matsize-1 DO v!i := key!i
    RETURN
  }

 IF n=8 DO
  { FOR i = 0 TO Matsize-1 DO v!i := i/2
    RETURN
  }

 IF n=16 DO
  { FOR i = 0 TO Matsize-1 DO v!i := (i/3) & 255
    RETURN
  }

  writef("Bad n=%n in setkey*n", n)
  abort(1000)
}


// The ShiftRows() function shifts the rows in the state to the left.
// Each row is shifted with different offset.
// Offset = Row number. So the first row is not shifted.
LET ShiftRows_st() BE
{ FOR i = 0 TO n-1 DO
  { LET rows = stateS + i*n
    AND rowt = stateT + i*n
    FOR j = 0 TO n-1 DO
      rowt!j := rows!((i+j) MOD n)
  }
}

LET InvShiftRows_ts() BE
{ FOR i = 0 TO n-1 DO
  { LET rows = stateS + i*n
    AND rowt = stateT + i*n
    FOR j = 0 TO n-1 DO
      rows!((i+j) MOD n) := rowt!j
  }
}

// The SubBytes Function Substitutes the values in the
// state matrix with values in the S-box.
LET SubBytes_ts() BE
{ // Apply sbox from t state to s state
  FOR i = 0 TO Matsize-1 DO stateS!i := sbox!(stateT!i)
}

// The InvSubBytes Function Substitutes the values in the
// state matrix with values in an RS-box.
LET InvSubBytes_st() BE
{ // Apply rsbox from s state to t state
  FOR i = 0 TO Matsize-1 DO stateT!i := rsbox!(stateS!i)
}

LET inittables() BE
{ sbox := TABLE
     99,124,119,123,242,107,111,197, 48,  1,103, 43,254,215,171,118,
    202,130,201,125,250, 89, 71,240,173,212,162,175,156,164,114,192,
    183,253,147, 38, 54, 63,247,204, 52,165,229,241,113,216, 49, 21,
      4,199, 35,195, 24,150,  5,154,  7, 18,128,226,235, 39,178,117,
      9,131, 44, 26, 27,110, 90,160, 82, 59,214,179, 41,227, 47,132,
     83,209,  0,237, 32,252,177, 91,106,203,190, 57, 74, 76, 88,207,
    208,239,170,251, 67, 77, 51,133, 69,249,  2,127, 80, 60,159,168,
     81,163, 64,143,146,157, 56,245,188,182,218, 33, 16,255,243,210,
    205, 12, 19,236, 95,151, 68, 23,196,167,126, 61,100, 93, 25,115,
     96,129, 79,220, 34, 42,144,136, 70,238,184, 20,222, 94, 11,219,
    224, 50, 58, 10, 73,  6, 36, 92,194,211,172, 98,145,149,228,121,
    231,200, 55,109,141,213, 78,169,108, 86,244,234,101,122,174,  8,
    186,120, 37, 46, 28,166,180,198,232,221,116, 31, 75,189,139,138,
    112, 62,181,102, 72,  3,246, 14, 97, 53, 87,185,134,193, 29,158,
    225,248,152, 17,105,217,142,148,155, 30,135,233,206, 85, 40,223,
    140,161,137, 13,191,230, 66,104, 65,153, 45, 15,176, 84,187, 22

  rsbox := TABLE
     82,  9,106,213, 48, 54,165, 56,191, 64,163,158,129,243,215,251,
    124,227, 57,130,155, 47,255,135, 52,142, 67, 68,196,222,233,203,
     84,123,148, 50,166,194, 35, 61,238, 76,149, 11, 66,250,195, 78,
      8, 46,161,102, 40,217, 36,178,118, 91,162, 73,109,139,209, 37,
    114,248,246,100,134,104,152, 22,212,164, 92,204, 93,101,182,146,
    108,112, 72, 80,253,237,185,218, 94, 21, 70, 87,167,141,157,132,
    144,216,171,  0,140,188,211, 10,247,228, 88,  5,184,179, 69,  6,
    208, 44, 30,143,202, 63, 15,  2,193,175,189,  3,  1, 19,138,107,
     58,145, 17, 65, 79,103,220,234,151,242,207,206,240,180,230,115,
    150,172,116, 34,231,173, 53,133,226,249, 55,232, 28,117,223,110,
     71,241, 26,113, 29, 41,197,137,111,183, 98, 14,170, 24,190, 27,
    252, 86, 62, 75,198,210,121, 32,154,219,192,254,120,205, 90,244,
     31,221,168, 51,136,  7,199, 49,177, 18, 16, 89, 39,128,236, 95,
     96, 81,127,169, 25,181, 74, 13, 45,229,122,159,147,201,156,239,
    160,224, 59, 77,174, 42,245,176,200,235,187, 60,131, 83,153, 97,
     23, 43,  4,126,186,119,214, 38,225,105, 20, 99, 85, 33, 12,125
}

LET AddRoundKey_st(i) BE
{ // Add key round i from s state to t state
  LET K = @Rkey!(Matsize*i)
  FOR i = 0 TO Matsize-1 DO stateT!i := stateS!i XOR K!i
}

LET AddRoundKey_ts(i) BE
{ // Add key round i from s state to t state
  LET K = @Rkey!(Matsize*i)
  FOR i = 0 TO Matsize-1 DO stateS!i := stateT!i XOR K!i
}

LET KeyExpansion(key) BE
{ LET rcon = 1

  // The first round key is the cipher key itself,
  // stored column by column.
  transpose(key, Rkey)

  // Add Nr more keys to the key schedule
  FOR i = 1 TO Nr DO
  { LET p = @Rkey!(Matsize*i) // Pointer to space for key in round i
    LET q = p-Matsize         // Pointer to round key i-1

    FOR i = 0 TO n-1 DO
    { LET a = n*i
      LET b = (a+2*n-1) MOD Matsize
      p!a := q!a XOR sbox!(q!b)
    }
    p!0 := p!0 XOR rcon

    FOR j = 1 TO n-1 FOR i = 0 TO n-1 DO
    { LET a = j+n*i
      p!a := q!a XOR p!(a-1)
    }

    rcon := mul(2, rcon)
  }
}

LET mul(x, y) = VALOF
{ // Return the product of x and y using GF(2**8) arithmetic
  LET res = 0
  WHILE x DO
  { IF (x & 1)>0 DO res := res XOR y
    x := x>>1
    y := y<<1
    IF y > 255 DO y := y XOR #x11B
  }
  RESULTIS res
}

// MixColumns_ts mixes the columns of the state matrix
LET MixColumns_ts() BE
{ // Compute the matrix product, eg
  // (2 3 1 1)   ( t00 t01 t02 t03)    (s00 s01 s02 s03)
  // (1 2 3 1) x ( t10 t11 t12 t13) => (s10 s11 s12 s13)
  // (1 1 2 3)   ( t20 t21 t22 t23)    (s20 s21 s22 s23)
  // (3 1 1 2)   ( t30 t31 t32 t33)    (s30 s31 s32 s33)

  matmul(mixmat, stateT, stateS)
}

// IncMixColumns_st unmixes the columns of the state matrix.
AND InvMixColumns_st() BE
{ // Compute the matrix product, eg
  // (14 11 13  9)   (s00 s01 s02 s03)    (t00 t01 t02 t03)
  // ( 9 14 11 13) x (s10 s11 s12 s13) => (t10 t11 t12 t13)
  // (13  9 14 11)   (s20 s21 s22 s23)    (t20 t21 t22 t23)
  // (11 13  9 14)   (s30 s31 s32 s33)    (t30 t31 t32 t33)

  matmul(invmixmat, stateS, stateT)
}

// Cipher is the main function that encrypts the PlainText.
AND Cipher(in, out) BE
{ // Copy the input PlainText into the state array.
  transpose(in, stateS)

  IF tracing DO
  { writef("%i2.input  ", 0); prstate(stateS)
    writef("%i2.k_sch  ", 0); prstate(Rkey)
  }

  // Add the First round key to the state before starting the rounds.
  AddRoundKey_st(0) 

  FOR round = 1 TO Nr-1 DO
  { IF tracing DO
    { writef("%i2.start  ", round); prstate(stateT) }

    SubBytes_ts()
    IF tracing DO
    { writef("%i2.s_box  ", round); prstate(stateS) }

    ShiftRows_st()
    IF tracing DO
    { writef("%i2.s_row  ", round); prstate(stateT) }

    MixColumns_ts()
    IF tracing DO
    { writef("%i2.s_col  ", round); prstate(stateS) }

    AddRoundKey_st(round)
    IF tracing DO
    { writef("%i2.k_sch  ", round); prstate(@Rkey!(Matsize*round)) }
  }
  
  // The last round is given below.
  IF tracing DO
  { writef("%i2.start  ", Nr); prstate(stateT) }

  SubBytes_ts()
  IF tracing DO
  { writef("%i2.s_box  ", Nr); prstate(stateS) }

  ShiftRows_st()
  IF tracing DO
  { writef("%i2.s_row  ", Nr); prstate(stateT) }

  // Do not mix the columns in the final round

  AddRoundKey_ts(Nr)
  IF tracing DO
  { writef("%i2.k_sch  ", Nr); prstate(@Rkey!(Matsize*Nr))
    writef("%i2.output ", Nr); prstate(stateS)
  }

  // Copy the state array to output array.
  transpose(stateS, out)
}

AND InvCipher(in, out) BE
{ // Copy the input CipherText to state array.
  transpose(in, stateS)

  IF tracing DO
  { writef("%i2.iinput ", 0); prstate(stateS)
    writef("%i2.ik_sch ", 0); prstate(@Rkey!(Matsize*Nr))
  }

  // Add the Last round key to the state before starting the rounds.
  AddRoundKey_st(Nr)

  FOR round = Nr-1 TO 1 BY -1 DO
  { IF tracing DO
    { writef("%i2.istart ", Nr-round); prstate(stateT) }

    InvShiftRows_ts()

    IF tracing DO
    { writef("%i2.is_row ", Nr-round); prstate(stateS) }

    InvSubBytes_st()
    IF tracing DO
    { writef("%i2.is_box ", Nr-round); prstate(stateT) }

    AddRoundKey_ts(round)
    IF tracing DO
    { writef("%i2.ik_sch ", Nr-round); prstate(@Rkey!(Matsize*round))
      writef("%i2.is_add ", Nr-round); prstate(stateS)
    }

    InvMixColumns_st()
  }

  IF tracing DO
  { writef("%i2.istart ", Nr); prstate(stateT) }
  
  // The final round is given below.
  InvShiftRows_ts()
  IF tracing DO
  { writef("%i2.is_row ", Nr); prstate(stateS) }

  InvSubBytes_st()
  IF tracing DO
  { writef("%i2.is_box ", Nr); prstate(stateT) }

  // Do not mix the columns in the final round
  AddRoundKey_ts(0)
  IF tracing DO
  { writef("%i2.ik_sch ", Nr); prstate(@Rkey!(Matsize*0))
    writef("%i2.ioutput", Nr); prstate(stateS)
  }

  // Copy the state array to output array.
  transpose(stateS, out)
}

AND transpose(a, b) BE
{ // Transpose matrix a into b
  // Ie copy consecutive elements of a into the columns of b
  FOR i = 0 TO n-1 DO
  { // Copy data into column i
    FOR j = 0 TO n-1 DO
    { b!(n*j+i) := !a
      a := a+1
    } 
  }
}

AND start() = VALOF
{ LET argv  = VEC 50
  LET countExpand, countCipher, countInvCipher = 0, 0, 0

  UNLESS rdargs("n/n,-t/s,stats/s", argv, 50) DO
  { writef("Bad arguments for aesnxn*n")
    RESULTIS 0
  }

  plain  := 0
  key    := 0
  in     := 0
  out    := 0
  Rkey   := 0
  stateS := 0
  stateT := 0
  bitcountv := 0
  bitsumv   := 0

  n := 4
  IF argv!0 DO n := !argv!0  // n/n   4x4, 8x8 or 16x16 matrix sizes
  Matsize := n*n
  Nr := n=4  -> 10,           // Number of rounds
        n=8  -> 23,
        n=16 -> 37,
                -1
  IF Nr<0 DO
  { writef("ERROR: n=%n must be 4, 8 or 16*n", n)
    GOTO fin
  }

  tracing := argv!1          // -t/s
  stats   := argv!2          // stats/s

  plain  := getvec(Matsize-1)
  key    := getvec(Matsize-1)
  in     := getvec(Matsize-1)
  out    := getvec(Matsize-1)
  Rkey   := getvec(Matsize*(Nr+1)) // For the key schedule of Nr+1 keys
  stateS := getvec(Matsize-1)      // For stateS
  stateT := getvec(Matsize-1)      // For stateT
  bitcountv := getvec(8*Matsize-1)    // Histogram of how many bits are
                                      // changed in encrypted data
  bitsumv   := getvec(16*Matsize/4-1) // 16-bit longitudinal counters for
                                      // each bit of the encrypted data

  UNLESS plain & key & in & out &
         Rkey & stateS & stateT &
         bitcountv & bitsumv DO
  { writef("ERROR: More memory needed*n")
    GOTO fin
  }

  setplain(plain)
  setkey(key)

  // When n = 4, the plain text and key are the same as given in
  // the detailed example in Appendix C.1 in
  // csrc.nist.gov/publications/fips/fips197/fips-197.pdf
  // This provides a useful check that this implementaion is correct.
  // Just execute: aesnxn -t

  setmixmats()
  inittables()

  //KeyExpansion(key)
  countExpand := instrcount(KeyExpansion, key)

  IF tracing DO
  { writef("*nKey schedule*n")
    FOR i = 0 TO Nr DO
    { LET p = Matsize*i
      writef("%i2: ", i)
      prstate(@Rkey!p)
    }
  }
  newline()

  writef("plain:          "); prbytes(plain); newline()
  writef("key:            "); prbytes(key);   newline()

  //Cipher(plain, out)
  countCipher := instrcount(Cipher, plain, out)

  newline()

  writef("Cipher text:    "); prbytes(out); newline()

  //InvCipher(out, in)
  countInvCipher := instrcount(InvCipher, out, in)
  IF tracing DO newline()

  writef("InvCipher text: "); prbytes(in); newline()

  writef("*nCintcode instruction counts*n*n")
  writef("KeyExpansion: %i9*n", countExpand)
  writef("Cipher:       %i9*n", countCipher)
  writef("InvCipher:    %i9*n", countInvCipher)

  IF stats DO
  { writef("*n*nEncoding statistics*n*n")
    FOR i = 0 TO    8*Matsize-1 DO bitcountv!i := 0
    // bitsumv contains 8*Matsize 16-bit counters
    // stored longitudinally. Bit zero of counters
    // 0 to 31 are held in bitsumv!0. Bit 1 of these
    // counters are held bitsumv!16, etc.  Bit zero
    // of counters 32 to 63 are held in bitsumv!1.
    // Bit 1 of these counters are held bitsumv!17, etc.
    // There are 8*Matsize counters in all, each requiring
    // 16 bits. Assuming there are 32 bits per BCPL word
    // the require upper bound of bitsumv is 16*8*Matsize/32-1
    FOR i = 0 TO 16*Matsize/4-1 DO bitsumv!i := 0

    setplain(plain)
    setkey(key)
    KeyExpansion(key)
    Cipher(plain, out) // Remember initial cipher text in out

    FOR i = 0 TO 8*Matsize-1 DO
    { LET count = 0
      setplain(plain)
      setkey(key)
      changebit(plain, i)
      //changebit(key, i)
      KeyExpansion(key)
      Cipher(plain, in)

      // Calculate the changes histogram
      FOR j = 0 TO Matsize-1 DO
        count := count + bits(in!j XOR out!j)
      bitcountv!count := bitcountv!count + 1

      // Calculate how often each bit changes
      FOR i = 0 TO Matsize/4-1 DO // Number of 32 bit words to hold
                                  // 8*Matsize bits
      { LET j = i*4
        LET w = (in!j     XOR out!j)         XOR
                (in!(j+1) XOR out!(j+1))<<8  XOR
                (in!(j+2) XOR out!(j+2))<<16 XOR
                (in!(j+3) XOR out!(j+3))<<24
        // Note that each bit position occupies n*n/4 32-bit words
        increment(@bitsumv!(16*i), w) // 16 bits per count
      }
    }

    // Test the increment function
    //increment(@bitsumv!0, #b01010)
    //increment(@bitsumv!0, #b11100)
    //increment(@bitsumv!0, #b00001)
    //increment(@bitsumv!0, #b00001)
    //increment(@bitsumv!0, #b00001)

    writef("*nHistogram of the number of bits changed*n")

    FOR i = 0 TO 8*Matsize-1 DO
    { IF i MOD 16 = 0 DO writef("*n%i4: ", i)
      writef(" %i3", bitcountv!i)
    }
    newline()

    writef("*nHistogram of the number of times each bit changes*n")

    FOR i = 0 TO 8*Matsize-1 DO
    { LET p   = i  /  32
      LET bit = 1 << (i MOD 32)
      IF i MOD 16 = 0 DO writef("*n%i4: ", i)
      writef(" %i4", countvalue(@bitsumv!(16*p), bit))
    }
    newline()
  }

fin:
  IF plain     DO freevec(plain)
  IF key       DO freevec(key)
  IF in        DO freevec(in)
  IF out       DO freevec(out)
  IF Rkey      DO freevec(Rkey)
  IF stateS    DO freevec(stateS)
  IF stateT    DO freevec(stateT)
  IF bitcountv DO freevec(bitcountv)
  IF bitsumv   DO freevec(bitsumv)

  RESULTIS 0
}

AND changebit(v, i) BE
{ LET p  = i  /  8
  LET sh = i MOD 8
  v!p := v!p XOR 1<<sh
}

AND bits(w) = w=0 -> 0, 1 + bits(w & (w-1))

AND increment(p, w) BE WHILE w DO
{ LET c = !p & w  // The carry bits
  !p := !p XOR w
  w, p := c, p+1  // The next bit position is one word later.
}

AND countvalue(p, bit) = VALOF
{ LET res = 0
  FOR j = 15 TO 0 BY -1 DO
  { res := 2*res
    UNLESS (p!j & bit) = 0 DO res := res+1
  }
  RESULTIS res
}

AND prstate(m) BE
{ // For outputting state s matrix
  LET k = n=4 -> 8,
          n=8 -> 4,
                 2
  FOR i = 0 TO n-1 DO
  { LET p = @m!i
    IF i MOD k = 0 DO newline()
    wrch(' ')
    FOR j = 0 TO n-1 DO writef("%x2", p!(n*j))
  }
  newline()
}

AND prbytes(v) BE
{ // For outputting plain and ciphered text and keys
  FOR i = 0 TO Matsize-1 DO
  { IF i MOD 32 = 0 DO newline() // Choose a suitable layout
    IF i MOD n = 0 DO wrch(' ')
    writef("%x2", v!i)
  }
  newline()
}

AND matmul(a, b, c) BE
{ // Set c = a * b where a, b and c are nxn matrices
  // using GP(2^8).
  FOR i = 0 TO n-1 DO
  { FOR j = 0 TO n-1 DO
    { // Set the (i,j) element of c to be the inner product
      // row i of a and column j of b
      LET row = a + i*n // Left most element of row i
      AND col = b + j   // Top element of column j
      LET x = 0
      FOR k = 0 TO n-1 DO
        x := x XOR mul(row!k, col!(k*n))
      c!(i*n+j) := x
    }
  }
}

