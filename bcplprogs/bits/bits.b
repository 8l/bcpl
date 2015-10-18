
// This program tries out various methods to count the number
// of ones in a word.
// Implemented in Cintcode BCPL by Martin Richards (c) Feb 2001

GET "libhdr"

LET start() = VALOF
{ LET t = TABLE //            Cintcode instruction executions
 // test data      result  bts  bts1 bts2 bts3 bts4 bts5 bts6 bts7
   #x80000000, //      1:  419   15   39   38   51  308   96   31
   #xFFFFFFFF, //     32:  419  294   39   38   51  658   96   31
   #x74500000, //      6:  406   60   39   38   51  462   96   31
   #x467C0000, //      8:  406   78   39   38   51  504   96   31
   #x87658000, //      9:  419   87   39   38   51  532   96   31
   #x7FF23400, //     15:  406  141   39   38   51  560   96   31
   #x12345600, //      9:  380   87   39   38   51  490   96   31
   #x0123E000, //      7:  328   69   39   38   51  448   85   31
   #x00123400, //      5:  276   51   39   38   51  406   74   31
   #x00012340, //      5:  224   51   39   38   51  406   63   31
   #x00001204, //      3:  172   33   39   38   51  336   52   31
   #x00000120, //      2:  120   24   39   38   51  308   41   31
   #x00000012, //      2:   68   24   39   38   51  294   30   31
   #x00000001, //      1:   16   15   39   38   51  238   19   31
   #xF0F0F0F0, //     16:  419  150   39   38   51  560   96   31
   #x80808000, //      3:  419   33   39   38   51  392   96   31
   #x40400000, //      2:  406   24   39   38   51  364   96   31
   #x20000000, //      1:  393   15   39   38   51  308   96   31
   #x10000010, //      2:  380   24   39   38   51  364   96   31
   #x0000FFFF, //     16:  211  150   39   38   51  518   52   31
   #x00001FFF, //     13:  172  123   39   38   51  462   52   31
   #x00000000  //      0:    3    6   39   38   51  238    8   31

  LET w = 0
  LET k = 0
  LET bit = 0

  writef("*nTest various implementations of bts*n*n")

  { w := !t
    t := t+1
    bit := bts(w)
    writef("%x8 %i2: ", w, bit)
    try(w, bts);  try(w, bts1); try(w, bts2); try(w, bts3)
    try(w, bts4); try(w, bts5); try(w, bts6); try(w, bts7)
    newline()
  } REPEATWHILE w

  writef("*n*nEnd of test*n")
  RESULTIS 0
}

AND try(w, f) BE
  writef(" %i3%c", instrcount(f, w), bts(w)=f(w) -> ' ', '#')

AND bts(w) = w=0 -> 0, (w&1) + bts(w>>1)

AND bts1(w) = VALOF
{ LET r = 0
  WHILE w DO r, w := r+1, w & (w-1)
  RESULTIS r
}

AND bts2(w) = VALOF
{ w := (w    & #x11111111) +
       (w>>1 & #x11111111) +
       (w>>2 & #x11111111) +
       (w>>3 & #x11111111)

  w := (w    & #x0f0f0f0f) +
       (w>>4 & #x0f0f0f0f)

  RESULTIS (w * #x01010101) >> 24
}

AND bts3a(w) = VALOF
{ w := (w    & #10101010101) +
       (w>>1 & #10101010101) +
       (w>>2 & #10101010101) +
       (w>>3 & #10101010101) +
       (w>>4 & #10101010101) +
       (w>>5 & #10101010101)

  w := (w    & #07777777777) + (w>>30)
  w :=  w    * #00101010101

  RESULTIS (w >> 24) & 63
}

AND bts3(w) = VALOF
{ w := (w    & #04444444445) +
       (w>>1 & #04444444445) +
       (w>>2 & #04444444444)
  w := w + (w&3)*3             // w contains 10 3-bit numbers
  w := (w    & #03434343434) +
       (w>>3 & #03434343434)
  RESULTIS (w* #00101010101) >> 26
}

AND bts4(w) = VALOF
{ w := (w & #x55555555) + ((w>> 1) & #x55555555)
  w := (w & #x33333333) + ((w>> 2) & #x33333333)
  w := (w & #x0f0f0f0f) + ((w>> 4) & #x0f0f0f0f)
  w := (w & #x00ff00ff) + ((w>> 8) & #x00ff00ff)
  w := (w & #x0000ffff) + ((w>>16) & #x0000ffff)
  RESULTIS w
}

AND add(bts, p) BE WHILE bts DO
{ LET w = !p
  !p := w NEQV bts
  bts, p := w & bts, p+1
}

AND val(p) = VALOF
{ LET r = p!5 & 1
  FOR i = 4 TO 0 BY -1 DO r := 2*r + (p!i & 1)
  RESULTIS r
}

AND bts5(a,b,c,d,e,f) = VALOF
{ b, c, d, e, f := 0, 0, 0, 0, 0
  add(a>>16, @a)
  add(b>> 8, @b); add(a>>8,@a)
  add(c>> 4, @c); add(b>>4,@b); add(a>>4,@a)
  add(d>> 2, @d); add(c>>2,@c); add(b>>2,@b); add(a>>2,@a)
  add(e>> 1, @e); add(d>>1,@d); add(c>>1,@c); add(b>>1,@b); add(a>>1,@a)
  RESULTIS val(@a)
}

AND bts6(w) = VALOF
{ LET r = 0
  LET t = TABLE 0,1,1,2,1,2,2,3,1,2,2,3,2,3,3,4
  WHILE w DO { r := r + t!(w&15); w := w>>4 }
  RESULTIS r
}

AND bts7(w) = VALOF
{ LET t = TABLE
    0,1,1,2,1,2,2,3,1,2,2,3,2,3,3,4,1,2,2,3,2,3,3,4,2,3,3,4,3,4,4,5,
    1,2,2,3,2,3,3,4,2,3,3,4,3,4,4,5,2,3,3,4,3,4,4,5,3,4,4,5,4,5,5,6,
    1,2,2,3,2,3,3,4,2,3,3,4,3,4,4,5,2,3,3,4,3,4,4,5,3,4,4,5,4,5,5,6,
    2,3,3,4,3,4,4,5,3,4,4,5,4,5,5,6,3,4,4,5,4,5,5,6,4,5,5,6,5,6,6,7,
    1,2,2,3,2,3,3,4,2,3,3,4,3,4,4,5,2,3,3,4,3,4,4,5,3,4,4,5,4,5,5,6,
    2,3,3,4,3,4,4,5,3,4,4,5,4,5,5,6,3,4,4,5,4,5,5,6,4,5,5,6,5,6,6,7,
    2,3,3,4,3,4,4,5,3,4,4,5,4,5,5,6,3,4,4,5,4,5,5,6,4,5,5,6,5,6,6,7,
    3,4,4,5,4,5,5,6,4,5,5,6,5,6,6,7,4,5,5,6,5,6,6,7,5,6,6,7,6,7,7,8

  RESULTIS t!(w & 255)+t!(w>>8 & 255)+t!(w>>16 & 255) + t!(w>>24 & 255)
}

