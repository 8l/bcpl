GET "libhdr"

LET start() = VALOF
{
  FOR i = 0 TO #3000 DO
  { IF i MOD 32 = 0 DO writef("*n%x4:", i)
    writef(" %#", i)
  }

  RESULTIS 0
}
