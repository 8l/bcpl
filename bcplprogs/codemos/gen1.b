GET "libhdr"

GLOBAL {
  pos: ug
  av
  stack
  s
  scope
  U
  V
  maxu
  maxv
  prev
  ppro
  npro
  val
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

LET push(x) BE
{ stack!s := x
  s := s+1
}

LET pop() = VALOF
{ s := s-1
  RESULTIS stack!s
}

LET genfn(k, l) BE
{ 
sw:
//  writef("k=%n pos!k=%i2 s=%i2  val=%i2  l=%n*n", k, pos!k, s, val, l)
//  abort(1000)

  SWITCHON pos!k INTO
  { CASE 1:
             //writef("%i2: awake0*n", k)
             IF maxu!k DO { pos!k := 2
                            push(k)
                            push(l)
                            l := k
                            k := maxu!k
                            GOTO sw
                          }

    CASE 2:  IF val DO { pos!k := 1
IF s=1 RETURN
                         l := pop()
                         k := pop()
                         GOTO sw
                       }
             av!k := 1
             val := TRUE
             pos!k := 3
IF s=1 RETURN
             l := pop()
             k := pop()
             GOTO sw

    CASE 3:
             //writef("%i2: asleep1*n", k)
             IF maxv!k DO { pos!k := 4
                            push(k)
                            push(l)
                            l := k
                            k := maxv!k
                            GOTO sw
                          }

    CASE 4:  IF val DO { pos!k := 3
IF s=1 RETURN
                         l := pop()
                         k := pop()
                         GOTO sw
                       }
             TEST prev!k > l THEN { pos!k := 5
                                    push(k)
                                    push(l)
                                    k := prev!k
                                    GOTO sw
                                  }
                             ELSE { val := FALSE;
                                    pos!k := 6
IF s=1 RETURN
                                    l := pop()
                                    k := pop()
                                    GOTO sw
                                  }
    CASE 5:  pos!k := 6
IF s=1 RETURN
             l := pop()
             k := pop()
             GOTO sw

    CASE 6:  
             //writef("%i2: awake1*n", k)
             IF maxv!k DO { pos!k := 7
                            push(k)
                            push(l)
                            l := k
                            k := maxv!k
                            GOTO sw
                          }

    CASE 7:  IF val DO { pos!k := 6
IF s=1 RETURN
                         l := pop()
                         k := pop()
                         GOTO sw
                       }
             av!k := 0
             val := TRUE
             pos!k := 8
IF s=1 RETURN
             l := pop()
             k := pop()
             GOTO sw

    CASE 8:  
             //writef("%i2: asleep0*n", k)
             IF maxu!k DO { pos!k := 9
                            push(k)
                            push(l)
                            l := k
                            k := maxu!k
                            GOTO sw
                          }
    CASE 9:  IF val DO { pos!k := 8
IF s=1 RETURN
                         l := pop()
                         k := pop()
                         GOTO sw
                       }

             TEST prev!k > l THEN { pos!k := 10
                                    push(k)
                                    push(l)
                                    k := prev!k
                                    GOTO sw
                                  }
                             ELSE { pos!k := 1
IF s=1 RETURN
                                    l := pop()
                                    k := pop()
                                    GOTO sw
                                  }

    CASE 10: { pos!k := 1
IF s=1 RETURN
               l := pop()
               k := pop()
               GOTO sw
             }

    CASE 11: //????
  }
}

LET start() = VALOF
{ LET v1 = VEC upb
  LET v2 = VEC upb
  LET v3 = VEC upb
  LET v4 = VEC upb
  LET v5 = VEC 2*upb+1

  pos, av, stack := v1, v2, v5
  s := 1

  U, V := v3, v4

  scope := TABLE ?, 9,5,4,4,5,7,7,9,9  // Not used
  maxu  := TABLE ?, 9,5,0,0,0,0,0,9,0
  maxv  := TABLE ?, 8,4,4,0,0,7,0,0,0
  prev  := TABLE ?, 0,0,0,0,3,2,4,7,6
  ppro  := TABLE ?, 1,2,3,3,5,6,6,1,9
  npro  := TABLE ?, 0,0,0,4,0,0,7,8,8

  FOR i = 1 TO upb DO av!i := 0
  av!6, av!7 := 1, 1
  FOR i = 1 TO upb DO pos!i := av!i -> 6, 1


  FOR i = 1 TO 60 DO
  { FOR i = 1 TO upb DO writef("%n", av!i)
    newline()
    val := FALSE
    genfn(1, 1)
  }

fin:
  writef("End of test*n")
  RESULTIS 0
}
