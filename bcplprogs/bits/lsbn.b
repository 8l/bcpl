// This program tries out various methods to compute lsbno(s) where
// n = lsbn(w) is the number of the least significant occurring one in w.
// w=#x00000000 => -1
// w=#x00000001 =>  0
// w=#x00000002 =>  1
// w=#x00000004 =>  2
// w=#x80000000 =>  31



// Implemented in Cintcode BCPL by Martin Richards (c) Nov 2003

GET "libhdr"

LET start() = VALOF
{ LET t = TABLE //         Cintcode instruction executed

//  test data  result   lsbn  lsbna lsbnb lsbnc lsbnd lsbne lsbnf

   #x00000000, // -1:   420      3    16   356    23    23    14
   #x00000001, //  0:     8     14    15    10    21    10    14
   #x00000012, //  1:    21     14    15    21    21    10    12 
   #x00000123, //  0:     8     14    15    10    21    10    14 
   #x00001234, //  2:    34     14    15    32    21    10    12 
   #x00001FFF, //  0:     8     14    15    10    21    10    14 
   #x00004000, // 14:   190     14    18   164    21    17    12 
   #x00008000, // 15:   203     14    18   175    21    17    12 
   #x0000FFFF, //  0:     8     14    15    10    21    10    14 
   #x00010000, // 16:   216     14    18   186    21    22    12 
   #x00012345, //  0:     8     14    15    10    21    10    14 
   #x00123456, //  1:    21     14    15    21    21    10    12 
   #x01234567, //  0:     8     14    15    10    21    10    14 
   #x10101010, //  4:    60     14    15    54    21    10    12 
   #x12345678, //  3:    47     14    15    43    21    10    12 
   #x20202020, //  5:    73     14    15    65    21    10    12 
   #x40000000, // 30:   398     14    16   340    21    23    12 
   #x40404040, //  6:    86     14    15    76    21    10    12 
   #x7FF23456, //  1:    21     14    15    21    21    10    12 
   #x7FFFFFFF, //  0:     8     14    15    10    21    10    14 
   #x80000000, // 31:   411     14    16   351    23    23    12 
   #x80808080, //  7:    99     14    15    87    21    10    12 
   #x87654321, //  0:     8     14    15    10    21    10    14 
   #xF0F0F0F0, //  4:    60     14    15    54    21    10    12 
   #xFFFFFFFF  //  0:     8     14    15    10    21    10    14 

  writef("*nTest various implementations of lsbn*n*n")

  { trial(!t)
    IF !t=-1 BREAK
    t := t+1
  } REPEAT
  FOR i = 0 TO 31 DO { trial(1<<i); LOOP; trial(1<<i | 1); trial(3<<i) }
  writef("*n*nEnd of test*n")
  RESULTIS 0
}

AND trial(w) BE
{ LET n = lsbn(w)
  writef("%x8 %i2: ", w, n)
//newline()
  try(w, lsbn);  try(w, lsbna); try(w, lsbnb); try(w, lsbnc)
  try(w, lsbnd); try(w, lsbne); try(w, lsbnf)
  newline()
}

AND try(w, f) BE writef(" %i3%c", instrcount(f, w), lsbn(w)=f(w) -> ' ', '#')
//AND try(w, f) BE UNLESS lsbn(w)=f(w) DO
//{ writef("%x8 => %i3 should be %i3*n", w, f(w), lsbn(w))
//  abort(1000)
//}

AND lsbn(w) = VALOF
{
//writef("lsbn*n")
  FOR n = 0 TO 31 DO
  { UNLESS (w&1)=0 RESULTIS n
    w := w>>1
  }
  RESULTIS -1
}

AND lsbna(w) = w=0 -> -1, VALOF
{ LET t = TABLE  0, 1, 2,27, 3,24,28,-1, 4,17,25,31,29,12,-1,14, 5, 8,
                18,-1,26,23,-1,16,30,11,13, 7,-1,22,15,10, 6,21, 9,20,19
  LET bit = w & -w
  RESULTIS t!((bit>>1) REM 37)
}

AND lsbnb(w) = VALOF
{ LET t = TABLE -25,0,1,0,2,0,1,0,3,0,1,0,2,0,1,0,
                  4,0,1,0,2,0,1,0,3,0,1,0,2,0,1,0,
                  5,0,1,0,2,0,1,0,3,0,1,0,2,0,1,0,
                  4,0,1,0,2,0,1,0,3,0,1,0,2,0,1,0,
                  6,0,1,0,2,0,1,0,3,0,1,0,2,0,1,0,
                  4,0,1,0,2,0,1,0,3,0,1,0,2,0,1,0,
                  5,0,1,0,2,0,1,0,3,0,1,0,2,0,1,0,
                  4,0,1,0,2,0,1,0,3,0,1,0,2,0,1,0,
                  7,0,1,0,2,0,1,0,3,0,1,0,2,0,1,0,
                  4,0,1,0,2,0,1,0,3,0,1,0,2,0,1,0,
                  5,0,1,0,2,0,1,0,3,0,1,0,2,0,1,0,
                  4,0,1,0,2,0,1,0,3,0,1,0,2,0,1,0,
                  6,0,1,0,2,0,1,0,3,0,1,0,2,0,1,0,
                  4,0,1,0,2,0,1,0,3,0,1,0,2,0,1,0,
                  5,0,1,0,2,0,1,0,3,0,1,0,2,0,1,0,
                  4,0,1,0,2,0,1,0,3,0,1,0,2,0,1,0

  TEST (w&#x0000FFFF)=0
  THEN TEST (w&#x00FF0000)=0 THEN RESULTIS t!(w>>24)        + 24
                             ELSE RESULTIS t!(w>>16 & #xFF) + 16
  ELSE TEST (w&#x000000FF)=0 THEN RESULTIS t!(w>> 8 & #xFF) +  8
                             ELSE RESULTIS t!(w     & #xFF)
}
  
AND lsbnc(w) = VALOF
{
  FOR n = 0 TO 31 UNLESS (w>>n & 1) = 0 RESULTIS n
  RESULTIS -1
}

AND lsbnd(w) = 
 (w&#x0000ffff)=0 ->
   (w&#x00ff0000)=0 ->
   (w&#x0f000000)=0 -> (w&#x30000000)=0 -> (w&#x40000000)=0 -> (w->31,-1),  30,
                                           (w&#x10000000)=0 -> 29,  28,
                       (w&#x03000000)=0 -> (w&#x04000000)=0 -> 27,  26,
                                           (w&#x01000000)=0 -> 25,  24,
   (w&#x000f0000)=0 -> (w&#x00300000)=0 -> (w&#x00400000)=0 -> 23,  22,
                                           (w&#x00100000)=0 -> 21, 20,
                       (w&#x00030000)=0 -> (w&#x00040000)=0 -> 19, 18,
                                           (w&#x00010000)=0 -> 17, 16,
   (w&#x000000ff)=0 ->
   (w&#x00000f00)=0 -> (w&#x00003000)=0 -> (w&#x00004000)=0 -> 15, 14,
                                           (w&#x00001000)=0 -> 13, 12,
                       (w&#x00000300)=0 -> (w&#x00200400)=0 -> 11, 10,
                                           (w&#x00800100)=0 ->  9,  8,
   (w&#x0000000f)=0 -> (w&#x0c000030)=0 -> (w&#x02000040)=0 ->  7,  6,
                                           (w&#x08000010)=0 ->  5,  4,
                       (w&#xc0000003)=0 -> (w&#x20000004)=0 ->  3,  2,
                                           (w&#x80000001)=0 ->  1,  0

AND lsbne(w) = VALOF
{ LET a = ?
  LET t = TABLE -25,0,1,0,2,0,1,0,3,0,1,0,2,0,1,0,
                  4,0,1,0,2,0,1,0,3,0,1,0,2,0,1,0,
                  5,0,1,0,2,0,1,0,3,0,1,0,2,0,1,0,
                  4,0,1,0,2,0,1,0,3,0,1,0,2,0,1,0,
                  6,0,1,0,2,0,1,0,3,0,1,0,2,0,1,0,
                  4,0,1,0,2,0,1,0,3,0,1,0,2,0,1,0,
                  5,0,1,0,2,0,1,0,3,0,1,0,2,0,1,0,
                  4,0,1,0,2,0,1,0,3,0,1,0,2,0,1,0,
                  7,0,1,0,2,0,1,0,3,0,1,0,2,0,1,0,
                  4,0,1,0,2,0,1,0,3,0,1,0,2,0,1,0,
                  5,0,1,0,2,0,1,0,3,0,1,0,2,0,1,0,
                  4,0,1,0,2,0,1,0,3,0,1,0,2,0,1,0,
                  6,0,1,0,2,0,1,0,3,0,1,0,2,0,1,0,
                  4,0,1,0,2,0,1,0,3,0,1,0,2,0,1,0,
                  5,0,1,0,2,0,1,0,3,0,1,0,2,0,1,0,
                  4,0,1,0,2,0,1,0,3,0,1,0,2,0,1,0

  a := w & #x000000FF; IF a RESULTIS t!a
  a := w & #x0000FF00; IF a RESULTIS t!(a>> 8) +  8
  a := w & #x00FF0000; IF a RESULTIS t!(a>>16) + 16
                            RESULTIS t!(w>>24) + 24
}
  
AND lsbnf(w) = VALOF SWITCHON ((w & -w)>>1) REM 37 INTO
{ DEFAULT: RESULTIS -2
  CASE  0: RESULTIS  w -> 0, -1
  CASE  1: RESULTIS  1
  CASE  2: RESULTIS  2
  CASE  3: RESULTIS 27
  CASE  4: RESULTIS  3
  CASE  5: RESULTIS 24
  CASE  6: RESULTIS 28
  CASE  7: RESULTIS -2
  CASE  8: RESULTIS  4
  CASE  9: RESULTIS 17
  CASE 10: RESULTIS 25
  CASE 11: RESULTIS 31
  CASE 12: RESULTIS 29
  CASE 13: RESULTIS 12
  CASE 14: RESULTIS -2
  CASE 15: RESULTIS 14
  CASE 16: RESULTIS  5
  CASE 17: RESULTIS  8
  CASE 18: RESULTIS 18
  CASE 19: RESULTIS -2
  CASE 20: RESULTIS 26
  CASE 21: RESULTIS 23
  CASE 22: RESULTIS -2
  CASE 23: RESULTIS 16
  CASE 24: RESULTIS 30
  CASE 25: RESULTIS 11
  CASE 26: RESULTIS 13
  CASE 27: RESULTIS  7
  CASE 28: RESULTIS -2
  CASE 29: RESULTIS 22
  CASE 30: RESULTIS 15
  CASE 31: RESULTIS 10
  CASE 32: RESULTIS  6
  CASE 33: RESULTIS 21
  CASE 34: RESULTIS  9
  CASE 35: RESULTIS 20
  CASE 36: RESULTIS 19
}

