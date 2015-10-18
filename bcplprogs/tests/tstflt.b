// Test simple floating point.
// numbers, #FIX #FLOAT #* #/ #+ #- 
// #= #~= #< #> #<= #>=

//GET "libhdr"

LET start() = VALOF
{ LET i = 1234
  AND x = 1.234
  AND y = 1.234000000000e-10
  AND z = 0e10
  x := x #+ y #* 2.34
  //writef("tstflt entered*n")

  //testconstants()

  RESULTIS 0
}
/*
AND testconstants() BE
{ LET a = 1//.0
  //AND b = 1.234
  writef("Testing floating point constants*n")

}
*/
