GET "libhdr"

GLOBAL {
  cov: ug
  av
  scope
  U
  V
  maxu
  maxv
  prev
  ppro
  npro
}

MANIFEST {
  upb = 9
}

/*
The spider
                        k  range    U      V     maxv maxv prev ppro npro
1                       1    9    2,6,9  4,7,8    9    8    0    1    0
*- > 2                  2    5     3,5     4      5    4    0    2    0
|    *- > 3             3    4      -      4      0    4    0    3    0
|    |    *- < 4        4    4      -      -      0    0    0    3    4
|    *- > 5             5    5      -      -      0    0    3    5    0
*- > 6                  6    7      -      7      0    7    2    6    0
|    *- < 7             7    7      -      -      0    0    4    6    7
*- < 8                  8    9      9      -      9    0    7    1    8
     *- > 9             9    9      -      -      0    0    6    9    8

ie a1 <= a2,  a1 <= a6, a1 >= a8
   a2 <= a3, a2 <= a5
   a3 >= a4
   a6 >= a7
   a8 <= a9

*/

LET genfn(k) BE
{ LET maxuk = maxu!k
  LET maxvk = maxv!k
  LET prevk = prev!k
  LET pprok = ppro!k
  LET nprok = npro!k
  LET l = ?
  writef("k=%n maxu!k=%n maxv!k=%n prev!k=%n ppro!k=%n npro!k=%n*n",
          k,   maxuk,    maxvk,    prevk,    pprok,    nprok)
  l := cowait() // Wait to be called

  IF av!k=1 GOTO awake1

  { 
awake0:
//writef("%n: awake0*n", k)
    IF maxuk WHILE callco(cov!maxuk, k) DO l := cowait(TRUE)
    av!k := 1
    l := cowait(TRUE)

asleep1:
//writef("%n: asleep1*n", k)
    IF maxvk WHILE callco(cov!maxvk, k) DO l := cowait(TRUE)
    cowait(prevk > l -> callco(cov!prevk, l), FALSE)

awake1:
//writef("%n: awake1*n", k)
    IF maxvk WHILE callco(cov!maxvk, k) DO l := cowait(TRUE)
    av!k := 0
    l := cowait(TRUE)

asleep0:
//writef("%n: asleep0*n", k)
    IF maxuk WHILE callco(cov!maxuk) DO l := cowait(TRUE)
    cowait(prevk > l -> callco(cov!prevk, l), FALSE)
  } REPEAT
}

LET start() = VALOF
{ LET v1 = VEC upb
  LET v2 = VEC upb
  LET v3 = VEC upb
  LET v4 = VEC upb

  cov, av := v1, v2
  U, V := v3, v4

  scope := TABLE ?, 9,5,4,4,5,7,7,9,9  // Not used
  maxu  := TABLE ?, 9,5,0,0,0,0,0,9,0
  maxv  := TABLE ?, 8,4,4,0,0,7,0,0,0
  prev  := TABLE ?, 0,0,0,0,3,2,4,7,6
  ppro  := TABLE ?, 1,2,3,3,5,6,6,1,9
  npro  := TABLE ?, 0,0,0,4,0,0,7,8,8

  FOR i = 1 TO upb DO cov!i, av!i := 0, 0
  av!6, av!7 := 1, 1

  FOR i = 1 TO upb DO
  { LET co = createco(genfn, 200)
    callco(co, i)
    cov!i := co
  }
  writef("%n coroutines created*n", upb)
 
  FOR i = 1 TO 60 DO
  { FOR i = 1 TO upb DO writef("%n", av!i)
    newline()
    callco(cov!1, 1)
  }

fin:
  FOR i = 1 TO upb IF cov!i DO deleteco(cov!i)
  writef("End of test*n")
  RESULTIS 0
}
