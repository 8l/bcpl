GET "libhdr"
 
// A nearly functional solution to the  eight queens problem
 
GLOBAL { count:ug; k }

LET start() = VALOF
{ count := 0
  k := instrcount(t8, 0, 0, #x8001,#x2004,#x0810,#x0240,
                            #x0180,#x0420,#x1008,#x4002)
  count := 0
  t8(0, 0, #x8001,#x2004,#x0810,#x0240,
           #x0180,#x0420,#x1008,#x4002)

  writes("*nEight Queens*n")
  writef("*nNumber of solutions is %n, instruction count: %n*n",
                                   count,                 k)
  RESULTIS 0
}
 
AND t8(diag, p, a,b,c,d,e,f,g,h) BE IF (diag&p) = 0 DO
{ LET di = diag+p << 2
  t7(di, a,   b,c,d,e,f,g,h)
  t7(di, b, a,  c,d,e,f,g,h)
  t7(di, c, a,b,  d,e,f,g,h)
  t7(di, d, a,b,c,  e,f,g,h)
  t7(di, e, a,b,c,d,  f,g,h)
  t7(di, f, a,b,c,d,e,  g,h)
  t7(di, g, a,b,c,d,e,f,  h)
  t7(di, h, a,b,c,d,e,f,g  )
}
 
AND t7(diag, p, a,b,c,d,e,f,g) BE IF (diag&p)=0 DO
{ LET di = diag+p << 2
  t6(di, a,   b,c,d,e,f,g)
  t6(di, b, a,  c,d,e,f,g)
  t6(di, c, a,b,  d,e,f,g)
  t6(di, d, a,b,c,  e,f,g)
  t6(di, e, a,b,c,d,  f,g)
  t6(di, f, a,b,c,d,e,  g)
  t6(di, g, a,b,c,d,e,f  )
}
 
AND t6(diag, p, a,b,c,d,e,f) BE IF (diag&p)=0 DO
{ LET di = diag+p << 2
  t5(di, a,   b,c,d,e,f)
  t5(di, b, a,  c,d,e,f)
  t5(di, c, a,b,  d,e,f)
  t5(di, d, a,b,c,  e,f)
  t5(di, e, a,b,c,d,  f)
  t5(di, f, a,b,c,d,e  )
}
 
AND t5(diag, p, a,b,c,d,e) BE IF (diag&p)=0 DO
{ LET di = diag+p << 2
  t4(di, a,   b,c,d,e)
  t4(di, b, a,  c,d,e)
  t4(di, c, a,b,  d,e)
  t4(di, d, a,b,c,  e)
  t4(di, e, a,b,c,d  )
}
 
AND t4(diag, p, a,b,c,d) BE IF (diag&p)=0 DO
{ LET di = diag+p << 2
  t3(di, a,   b,c,d)
  t3(di, b, a,  c,d)
  t3(di, c, a,b,  d)
  t3(di, d, a,b,c  )
}
 
AND t3(diag, p, a,b,c) BE IF (diag&p)=0 DO
{ LET di = diag+p << 2
  t2(di, a,   b,c)
  t2(di, b, a,  c)
  t2(di, c, a,b  )
}
 
AND t2(diag, p, a,b) BE IF (diag&p)=0 DO
{ LET di = diag+p << 2
  t1(di, a,   b)
  t1(di, b, a  )
}
 
AND t1(diag, p, a) BE IF (diag&p)=0 DO
{ LET di = diag+p << 2
  t0(di, a)
}
 
AND t0(diag, p) BE IF (diag&p) = 0 DO count := count+1

