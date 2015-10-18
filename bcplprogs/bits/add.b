// This program tries out various methods to add multiple small integers.

// Implemented in BCPL by Martin Richards (c) Mar 2001

GET "libhdr"

LET start() = VALOF
{ LET t = TABLE //             Cintcode instruction executions
 //  test x           y     result   add   add1  add2  add3
   #x80000000, // 0256BFEE 8256BFEE  213    45    35    37
   #xFF000000, // FDA94012 FFA94012  215    45    35    37 
   #x74500000, // 0256BFEE 76A6BFEE  213    45    35    37 
   #x467C0000, // FDA94012 FFFF4012  217    45    35    37 
   #x87658000, // 0256BFEE 89BBFFEE  214    45    35    37 
   #x7FF23400, // FDA94012 FFFB7412  216    45    35    37 
   #x12345600, // 0256BFEE 148AFFEE  215    45    35    37 
   #x0123E000, // FDA94012 FECCF012  214    45    35    37 
   #x00123400, // 0256BFEE 0268EFEE  214    45    35    37 
   #x00012340, // FDA94012 FDAA6352  213    45    35    37 
   #x00001204, // 0256BFEE 0256CFEF  215    45    35    37 
   #x00000120, // FDA94012 FDA94132  213    45    35    37 
   #x00000012, // 0256BFEE 0256BFFF  214    45    35    37 
   #x00000001, // FDA94012 FDA94013  213    45    35    37 
   #xF0F0F0F0, // 0256BFEE F2F6FFFE  216    45    35    37 
   #x80808000, // FDA94012 FDF9C012  215    45    35    37 
   #x40400000, // 0256BFEE 4296BFEE  213    45    35    37 
   #x20000000, // FDA94012 FDA94012  214    45    35    37 
   #x10000010, // 0256BFEE 1256BFFE  213    45    35    37 
   #x0000FFFF, // FDA94012 FDA9FFFF  216    45    35    37 
   #x00001FFF, // 0256BFEE 0256CFFF  216    45    35    37 
   #x00000000  // FDA94012 FDA94012  213    45    35    37 

  LET x, y = 0, #xFDA94012
  LET k = 0
  LET bit = 0

  writef("*nTest various implementations of add*n*n")

  { x := !t
    y := -y
    t := t+1
    bit := add(x, y)
    writef("%x8 %x8 %x8", x, y, bit)
    try(x,y, add);  try(x,y, add1); try(x,y, add2); try(x,y, add3)
    newline()
  } REPEATWHILE x

  writef("*n*nEnd of test*n")
  RESULTIS 0
}

AND try(x, y, f) BE
  writef("  %i3%c", instrcount(f, x, y), add(x,y)=f(x,y) -> ' ', '#')

AND add(x, y) = VALOF
{ LET r = 0
  FOR sh = 0 TO 28 BY 4 DO
  { LET s = ((x>>sh & 15) + (y>>sh & 15))
    IF s>15 DO s := 15
    r := r | s<<sh
  }
  RESULTIS r
}

AND add1(x,y) = VALOF
{ LET a = x & #x88888888 //  0000 0000 1000 1000 0000 0000 1000 1000
  LET b = y & #x88888888 //  0000 1000 0000 1000 0000 1000 0000 1000
  LET c = a & b          //  0000 0000 0000 1000 0000 0000 0000 1000
  LET d = a NEQV b       //  0000 1000 1000 0000 0000 1000 1000 0000
  x := x - a             //  0xxx 0xxx 0xxx 0xxx 0xxx 0xxx 0xxx 0xxx
  y := y - b             //  0yyy 0yyy 0yyy 0yyy 0yyy 0yyy 0yyy 0yyy
  x := x + y             //  0zzz 0zzz 0zzz 0zzz 1zzz 1zzz 1zzz 1zzz
  b := x & d             //  0000 0000 0000 0000 0000 1000 1000 0000
  b := b | c             //  0000 0000 0000 1000 0000 1000 1000 1000
  a := b + b             //  0001 0000 0001 0000 0001 0001 0001 0000
  b := b>>3              //  0000 0000 0000 0001 0000 0001 0000 0001
  a := a - b             //  0000 0000 0000 1111 0000 1111 1111 1111
  RESULTIS x | a | d     //  0zzz 1zzz 1zzz 1111 1zzz 1111 1111 1111
}

AND add2(x,y) = VALOF
{ LET a = x & #x88888888        //  0000 0000 1000 1000 0000 0000 1000 1000
  LET b = y & #x88888888        //  0000 1000 0000 1000 0000 1000 0000 1000
  LET d = a NEQV b              //  0000 1000 1000 0000 0000 1000 1000 0000
  x := -(a+b)+x+y               //  0zzz 0zzz 0zzz 0zzz 1zzz 1zzz 1zzz 1zzz
  b := a & b | d & x            //  0000 0000 0000 1000 0000 1000 1000 1000
  RESULTIS (b>>3)*15 | d | x    //  0zzz 1zzz 1zzz 1111 1zzz 1111 1111 1111
}

AND add3(x,y) = VALOF
{ LET a = x & #x88888888        //  0000 0000 1000 1000 0000 0000 1000 1000
  LET b = y & #x88888888        //  0000 1000 0000 1000 0000 1000 0000 1000
  LET s = x-a + y-b             //  0zzz 0zzz 0zzz 0zzz 1zzz 1zzz 1zzz 1zzz
  LET d = a NEQV b              //  0000 1000 1000 0000 0000 1000 1000 0000
  LET t = a & b | d & s         //  0000 0000 0000 1000 0000 1000 1000 1000
  RESULTIS (t>>3)*15 | d | s    //  0zzz 1zzz 1zzz 1111 1zzz 1111 1111 1111
}







