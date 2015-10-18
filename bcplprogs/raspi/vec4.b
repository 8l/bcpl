GET "libhdr"

LET start() = VALOF
{ LET v1, v2 = 0, 0
  v1 := getvec(100_000)
  writef("getvec(100_000) => %n*n", v1)
  v2 := getvec(3_000_000)
  writef("getvec(3_000_000) => %n*n", v2)
  IF v1 DO freevec(v1)
  //IF v2 DO freevec(v2)  // Forget to free v2
  RESULTIS 0
}
