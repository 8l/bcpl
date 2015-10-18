GET "libhdr"

LET start() = VALOF
{ LET root2 = sqrt(3.0)
  writef("root2 = %9.7d*n", FIX (root2 #* 10000000.0))
  RESULTIS 0
}

AND sqrt(x) = VALOF
{ LET res = x
  LET prev = 0.0
  writef("x     = %9.7d*n", FIX (res #* 10000000.0))
  //UNTIL (#ABS( res #- prev)) #< 0.00000000001 DO
  UNTIL res=prev DO
  { prev := res
    writef("res   = %9.7d*n", FIX (res #* 10000000.0))
    res := (res #+ x #/ res) #/ 2.0
  }
  RESULTIS res
}
