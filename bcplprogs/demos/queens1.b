GET "libhdr"
 
GLOBAL { count:ug; all; instrs  }
 
LET try(ld, row, rd) BE TEST row=all
THEN count := count+1
ELSE { LET poss = all & ~(ld | row | rd)
       WHILE poss DO
       { LET p = poss & -poss
         try(ld+p << 1, row+p, rd+p >> 1)
         poss := poss - p
       }
     }

LET try1(ld, row, rd) BE        // This is about 7% faster than try
{ LET poss = all & ~(ld | row | rd)

  TEST poss
  THEN { LET p = poss & -poss
         try1(ld+p << 1, row+p, rd+p >> 1)
         poss := poss - p
       } REPEATWHILE poss
  ELSE IF row=all DO count := count+1
}

LET start() = VALOF
{ all := 1
  
  FOR i = 1 TO 14 DO  // Compare the efficiency of try with try1
  { count := 0
    instrs := instrcount(try,  0, 0, 0)
    writef("%i2-queens: solutions: %i6  instr count: %iA*n",
            i,                     count,            instrs)

    count := 0
    instrs := instrcount(try1, 0, 0, 0)
    writef("%i2-queens: solutions: %i6  instr count: %iA*n",
            i,                     count,            instrs)
    all := 2*all + 1
  }

  RESULTIS 0
}
