GET "libhdr"

GLOBAL { s1:ug; s2 }

LET start() = VALOF
{ LET argv = VEC 200

  UNLESS rdargs("S1/A,S2/A", argv, 200) DO
  { writef("Bad arguments for LCS*n")
    RESULTIS 0
  }

  s1, s2 := argv!0, argv!1

  writef("s1=%s*n", s1)
  writef("s2=%s*n", s2)
  writef("Length of longest common substring is %n*n", lcslen(s1%0, s2%0))
  RESULTIS 0
}

AND lcslen(i, j) = VALOF
{ LET res = lcslen1(i, j)
  writef("lcslen(%n, %n) => %n*n",  i, j, res)
  RESULTIS res
}

AND lcslen1(i, j) = VALOF
{ LET r1, r2 = ?, ?
  IF i=0 | j=0 RESULTIS 0
  IF s1%i=s2%j RESULTIS lcslen(i-1, j-1) + 1
  r1, r2 := lcslen(i, j-1), lcslen(i-1,j)
  RESULTIS r1>r2 -> r1, r2 
}

