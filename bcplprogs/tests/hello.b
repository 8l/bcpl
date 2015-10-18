SECTION "tst"

GET "libhdr"

LET start() = VALOF
{ RESULTIS 88
  writef("Hello World!*n")
  RESULTIS 0
}
