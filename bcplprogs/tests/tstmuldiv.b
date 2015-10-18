// This is to test various versions of muldiv
// for both speed and accuracy.

GET "libhdr"

LET start() = VALOF
{
  t1()
  t2()
  t3(31000123, 35000123, 541000123)
  t4()
  RESULTIS 0
}

AND t1() BE
{ LET a = 31000123
  LET b = 25000123
  LET c = 29000123
  LET t0 = sys(Sys_cputime)
  FOR i = 1 TO 1_000_000 DO
  { muldiv( a,  b,  c)
    muldiv(-a,  b,  c)
    muldiv( a, -b,  c)
    muldiv(-a, -b,  c)
    muldiv( a,  b, -c)
    muldiv(-a,  b, -c)
    muldiv( a, -b, -c)
    muldiv(-a, -b, -c)
    muldiv( a,  b,  c)
    muldiv( a,  b,  c)
  }

  writef("time taken t1 = %4.3d  -- 10,000,000 calls of muldiv(...)*n",
          sys(Sys_cputime)-t0)
}

AND t2() BE
{ LET a = 31000123
  LET b = 25000123
  LET c = 29000123
  LET t0 = sys(Sys_cputime)
  FOR i = 1 TO 1_000_000 DO
  { sys(Sys_muldiv,  a,  b,  c)
    sys(Sys_muldiv, -a,  b,  c)
    sys(Sys_muldiv,  a, -b,  c)
    sys(Sys_muldiv, -a, -b,  c)
    sys(Sys_muldiv,  a,  b, -c)
    sys(Sys_muldiv, -a,  b, -c)
    sys(Sys_muldiv,  a, -b, -c)
    sys(Sys_muldiv, -a, -b, -c)
    sys(Sys_muldiv,  a,  b,  c)
    sys(Sys_muldiv,  a,  b,  c)
  }

  writef("time taken t2 = %4.3d  -- 10,000,000 calls of sys(Sys_muldiv,...)*n",
          sys(Sys_cputime)-t0)
}

AND t3(a, b, c) BE
{ LET a1 = muldiv(a,b,c)
  LET r1 = result2
  LET a2 = sys(Sys_muldiv, a, b, c)
  LET r2 = result2
  LET a3 = (a*b)/c
  LET r3 = (a*b) MOD c

  UNLESS a1=a2 & r1=r2 DO
    writef("muldiv(%n,%n,%n) => %n rem %n  muldiv1 => %n rem %n*n",
            a,b,c, a1, r1, a2, r2)
  IF a=1 | b=1 UNLESS a1=a3 & r1=r3 DO
    writef("muldiv(%n,%n,%n) => %n rem %n  (a**b)/c => %n rem %n*n",
            a,b,c, a1, r1, a3, r3)
}

AND t4() BE
{ FOR i = 0 TO 5 DO
  {
    t3(0+i, 100, 110)
    t3(0-i, 100, 110)
    t3(minint+i, 100, 110) 
    t3(maxint-i, 100, 110) 

    t3(0+i, -100, 110)
    t3(0-i, -100, 110)
    t3(minint+i, -100, 110) 
    t3(maxint-i, -100, 110) 

    t3(0+i, 100, -110)
    t3(0-i, 100, -110)
    t3(minint+i, 100, -110) 
    t3(maxint-i, 100, -110) 

    t3(0+i, -100, -110)
    t3(0-i, -100, -110)
    t3(minint+i, -100, -110) 
    t3(maxint-i, -100, -110) 


    t3(0+i, 1, 110)
    t3(0-i, 1, 110)
    t3(minint+i, 1, 110) 
    t3(maxint-i, 1, 110) 

    t3(0+i, -1, 110)
    t3(0-i, -1, 110)
    t3(minint+i, -1, 110) 
    t3(maxint-i, -1, 110) 

    t3(0+i, 1, -110)
    t3(0-i, 1, -110)
    t3(minint+i, 1, -110) 
    t3(maxint-i, 1, -110) 

    t3(0+i, -1, -110)
    t3(0-i, -1, -110)
    t3(minint+i, -1, -110) 
    t3(maxint-i, -1, -110) 
  }
}
