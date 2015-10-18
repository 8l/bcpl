SECTION "Pento3"

GET "libhdr"

GLOBAL { n:200; p:201; board:202; count:203; trycount:204  }

LET put(c, piece, s1, s2, s3, s4) BE
{ c!0, c!s1, c!s2, c!s3 ,c!s4 := piece, piece, piece, piece, piece
  p!piece := FALSE
  n := n+1

  TEST n=12 THEN { count := count+1; pr()  }
            ELSE try(c)

  n := n-1
  p!piece := TRUE
  c!0, c!s1, c!s2, c!s3, c!s4 := 0, 0, 0, 0, 0
}

AND try(c) BE
{ UNTIL c!0=0 DO c := c+1  // find next unused square
  trycount := trycount + 1

  IF c!01=0 DO
  { IF c!02=0 DO { IF c!03=0 DO { IF c!04=0 & p!2  DO put(c, 2,01,02,03,04)
                                  IF c!16=0 & p!3  DO put(c, 3,01,02,03,16)
                                  IF c!17=0 & p!11 DO put(c,11,01,02,03,17)
                                  IF c!18=0 & p!11 DO put(c,11,01,02,03,18)
                                  IF c!19=0 & p!3  DO put(c, 3,01,02,03,19)
                               }
                   IF c!16=0 DO { IF c!15=0 & p!4  DO put(c, 4,01,02,16,15)
                                  IF c!17=0 & p!5  DO put(c, 5,01,02,16,17)
                                  IF c!18=0 & p!7  DO put(c, 7,01,02,16,18)
                                  IF c!32=0 & p!8  DO put(c, 8,01,02,16,32)
                                }
                   IF c!17=0 DO { IF c!18=0 & p!5  DO put(c, 5,01,02,17,18)
                                  IF c!33=0 & p!6  DO put(c, 6,01,02,17,33)
                                }
                   IF c!18=0 DO { IF c!19=0 & p!4  DO put(c, 4,01,02,18,19)
                                  IF c!34=0 & p!8  DO put(c, 8,01,02,18,34)
                                }
                 }
    IF c!16=0 DO { IF c!15=0 DO { IF c!14=0 & p!4  DO put(c, 4,01,16,15,14)
                                  IF c!31=0 & p!9  DO put(c, 9,01,16,15,31)
                                  IF c!17=0 & p!5  DO put(c, 5,01,16,15,17)
                                  IF c!32=0 & p!1  DO put(c, 1,01,16,15,32)
                                }
                   IF c!17=0 DO { IF c!18=0 & p!5  DO put(c, 5,01,16,17,18)
                                  IF c!32=0 & p!5  DO put(c, 5,01,16,17,32)
                                  IF c!33=0 & p!5  DO put(c, 5,01,16,17,33)
                                }
                   IF c!32=0 DO { IF c!31=0 & p!12 DO put(c,12,01,16,32,31)
                                  IF c!33=0 & p!7  DO put(c, 7,01,16,32,33)
                                  IF c!48=0 & p!3  DO put(c, 3,01,16,32,48)
                                }
                 }
    IF c!17=0 DO { IF c!18=0 DO { IF c!19=0 & p!4  DO put(c, 4,01,17,18,19)
                                  IF c!34=0 & p!9  DO put(c, 9,01,17,18,34)
                               // IF c!33=0 & p!1  DO put(c, 1,01,17,18,33)
                                }
                   IF c!33=0 DO { IF c!32=0 & p!7  DO put(c, 7,01,17,33,32)
                                  IF c!34=0 & p!12 DO put(c,12,01,17,33,34)
                                  IF c!49=0 & p!3  DO put(c, 3,01,17,33,49)
                                }
                 }
  }
  IF c!16=0 DO
  { IF c!15=0 DO { IF c!14=0 DO { IF c!13=0 & p!3  DO put(c, 3,16,15,14,13)
                                  IF c!30=0 & p!12 DO put(c,12,16,15,14,30)
                                  IF c!17=0 & p!11 DO put(c,11,16,15,14,17)
                                  IF c!32=0 & p!6  DO put(c, 6,16,15,14,32)
                                  IF c!31=0 & p!1  DO put(c, 1,16,15,14,31)
                                }
                   IF c!31=0 DO { IF c!30=0 & p!9  DO put(c, 9,16,15,31,30)
                                  IF c!32=0 & p!5  DO put(c, 5,16,15,31,32)
                                  IF c!47=0 & p!4  DO put(c, 4,16,15,31,47)
                               // IF c!17=0 & p!1  DO put(c, 1,16,15,31,17)
                                }
                   IF c!17=0 DO { IF c!18=0 & p!11 DO put(c,11,16,15,17,18)
                                  IF c!32=0 & p!10 DO put(c,10,16,15,17,32)
                               // IF c!33=0 & p!1  DO put(c, 1,16,15,17,33)
                                }
                   IF c!32=0 DO { IF c!48=0 & p!11 DO put(c,11,16,15,32,48)
                               // IF c!33=0 & p!1  DO put(c, 1,16,15,32,33)
                                }
                 }
    IF c!17=0 DO { IF c!18=0 DO { IF c!02=0 & p!7  DO put(c, 7,16,17,18,02)
                                  IF c!19=0 & p!3  DO put(c, 3,16,17,18,19)
                                  IF c!32=0 & p!6  DO put(c, 6,16,17,18,32)
                                  IF c!34=0 & p!12 DO put(c,12,16,17,18,34)
                               // IF c!33=0 & p!1  DO put(c, 1,16,17,18,33)
                                }
                   IF c!32=0 DO { IF c!33=0 & p!5  DO put(c, 5,16,17,32,33)
                                  IF c!48=0 & p!11 DO put(c,11,16,17,32,48)
                               // IF c!31=0 & p!1  DO put(c, 1,16,17,32,31)
                                }
                   IF c!33=0 DO { IF c!34=0 & p!9  DO put(c, 9,16,17,33,34)
                                  IF c!49=0 & p!4  DO put(c, 4,16,17,33,49)
                                }
                 }
    IF c!32=0 DO { IF c!31=0 DO { IF c!30=0 & p!8  DO put(c, 8,16,32,31,30)
                                  IF c!47=0 & p!4  DO put(c, 4,16,32,31,47)
                                  IF c!33=0 & p!6  DO put(c, 6,16,32,31,33)
                                  IF c!48=0 & p!11 DO put(c,11,16,32,31,48)
                                }
                   IF c!33=0 DO { IF c!34=0 & p!8  DO put(c, 8,16,32,33,34)
                                  IF c!48=0 & p!11 DO put(c,11,16,32,33,48)
                                  IF c!49=0 & p!4  DO put(c, 4,16,32,33,49)
                                }
                   IF c!48=0 DO { IF c!47=0 & p!3  DO put(c, 3,16,32,48,47)
                                  IF c!49=0 & p!3  DO put(c, 3,16,32,48,49)
                                  IF c!64=0 & p!2  DO put(c, 2,16,32,48,64)
                                }
                 }
  }
}

AND pr() BE
{ writef("Solution number %n  trycount %n*n", count, trycount)
/*
  FOR i = 0 TO 11*16 BY 16 DO
  { FOR j = i+5 TO i+12 DO
    { LET piece = board!j
      LET ch = '**'
      IF piece = 0 DO ch := '.'
      IF 1<=piece<=12 DO ch := "123456789ABC"%piece
      writef(" %C", ch)
    }
    newline()
  }
  newline()
*/
}


AND start() = VALOF
{ LET v1 = VEC 12
  LET v2 = VEC 1023

  p, board := v1, v2

  writes("Penta version 3 entered*n")

  FOR piece = 0 TO 12 DO p!piece := TRUE  // mark all pieces unused

  FOR i = 0 TO 1023 DO board!i := 13
  FOR i = 1 TO 10 FOR j = 16*i+6 TO 16*i+11 DO board!j := 0

  n, count, trycount := 0, 0, 0

  writes("Starting search*n")

  try(board)

  writef("*nThe total number of solutions is %n  trycount is %n*n",
          count, trycount)
  RESULTIS 0
}


