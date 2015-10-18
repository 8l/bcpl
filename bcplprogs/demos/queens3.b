GET "libhdr"
 
// A functional solution to the  eight queens problem
 
LET start() = VALOF
{ LET count = instrcount(t8, 0, 0, #x8001,#x2004,#x0810,#x0240,
                                   #x0180,#x0420,#x1008,#x4002)
  writes("*nEight Queens*n")
  writef("*nNumber of solutions is %n, instruction count: %n*n",
          t8(0, 0, #x8001,#x2004,#x0810,#x0240,
                   #x0180,#x0420,#x1008,#x4002), count)
  RESULTIS 0
}
 
AND t8(diag, p, a,b,c,d,e,f,g,h) = (diag&p) ~= 0 -> 0, VALOF
{ LET di = diag+p << 2
  RESULTIS t7(di, a,   b,c,d,e,f,g,h) +
           t7(di, b, a,  c,d,e,f,g,h) +
           t7(di, c, a,b,  d,e,f,g,h) +
           t7(di, d, a,b,c,  e,f,g,h) +
           t7(di, e, a,b,c,d,  f,g,h) +
           t7(di, f, a,b,c,d,e,  g,h) +
           t7(di, g, a,b,c,d,e,f,  h) +
           t7(di, h, a,b,c,d,e,f,g  )
}
 
AND t7(diag, p, a,b,c,d,e,f,g) = (diag&p) ~= 0 -> 0, VALOF
{ LET di = diag+p << 2
  RESULTIS t6(di, a,   b,c,d,e,f,g) +
           t6(di, b, a,  c,d,e,f,g) +
           t6(di, c, a,b,  d,e,f,g) +
           t6(di, d, a,b,c,  e,f,g) +
           t6(di, e, a,b,c,d,  f,g) +
           t6(di, f, a,b,c,d,e,  g) +
           t6(di, g, a,b,c,d,e,f  )
}
 
AND t6(diag, p, a,b,c,d,e,f) = (diag&p) ~= 0 -> 0, VALOF
{ LET di = diag+p << 2
  RESULTIS t5(di, a,   b,c,d,e,f) +
           t5(di, b, a,  c,d,e,f) +
           t5(di, c, a,b,  d,e,f) +
           t5(di, d, a,b,c,  e,f) +
           t5(di, e, a,b,c,d,  f) +
           t5(di, f, a,b,c,d,e  )
}
 
AND t5(diag, p, a,b,c,d,e) = (diag&p) ~= 0 -> 0, VALOF
{ LET di = diag+p << 2
  RESULTIS t4(di, a,   b,c,d,e) +
           t4(di, b, a,  c,d,e) +
           t4(di, c, a,b,  d,e) +
           t4(di, d, a,b,c,  e) +
           t4(di, e, a,b,c,d  )
}
 
AND t4(diag, p, a,b,c,d) = (diag&p) ~= 0 -> 0, VALOF
{ LET di = diag+p << 2
  RESULTIS t3(di, a,   b,c,d) +
           t3(di, b, a,  c,d) +
           t3(di, c, a,b,  d) +
           t3(di, d, a,b,c  )
}
 
AND t3(diag, p, a,b,c) = (diag&p) ~= 0 -> 0, VALOF
{ LET di = diag+p << 2
  RESULTIS t2(di, a,   b,c) +
           t2(di, b, a,  c) +
           t2(di, c, a,b  )
}
 
AND t2(diag, p, a,b) = (diag&p) ~= 0 -> 0, VALOF
{ LET di = diag+p << 2
  RESULTIS t1(di, a,   b) +
           t1(di, b, a  )
}
 
AND t1(diag, p, a) = (diag&p) ~= 0 -> 0, VALOF
{ LET di = diag+p << 2
  RESULTIS t0(di, a)
}
 
AND t0(diag, p) = (diag&p) ~= 0 -> 0, 1

