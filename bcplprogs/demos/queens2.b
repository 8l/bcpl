GET "libhdr"
 
GLOBAL { count:ug; all; instrs  }
 
LET try(ld, row, rd) BE
{ LET poss = all & ~(ld | row | rd)

  TEST poss
  THEN { LET p = poss & -poss
         try(ld+p << 1, row+p, rd+p >> 1)
         poss := poss - p
       } REPEATWHILE poss
  ELSE IF row=all DO count := count+1
}

LET start() = VALOF
{ all := 1
  FOR i = 1 TO 18 DO  // Compare the efficiency of try with try1
  { LET filename = "resA"
    LET t = 0
    filename%4 := 'A'+i-1
    selectoutput(findoutput(filename))
    count := 0
    t := sys(30)
    try(0, 0, 0)
    t := sys(30) - t
    writef("%i2-queens: solutions: %iA  in %iA msecs*n", 
            i,                     count,   t)
    endwrite()
    all := 2*all + 1
  }
  RESULTIS 0
}

