// Test the rdargs function

GET "libhdr"

LET start() = VALOF
{ LET format = "from/a/p,to/k,ver/p,flag/s/p,num/n/p"
  LET argv = VEC 50

  LET w = rdargs(format, argv, 50)
  UNLESS w DO
  { writef("Bad arguments for tstrdargs %s*n", format)
    RESULTIS 0
  }
 
  TEST argv!0 THEN writef("from/a/p: %s*n", argv!0)
              ELSE writef("from/a/p: %s*n", "<unset>")
  TEST argv!1 THEN writef("to/k:     %s*n", argv!1)
              ELSE writef("to/k:     %s*n", "<unset>")
  TEST argv!2 THEN writef("ver/p:    %s*n", argv!2)
              ELSE writef("ver/p:    %s*n", "<unset>")
  TEST argv!3 THEN writef("flag/s/p: true*n")
              ELSE writef("flag/s/p: false*n")
  TEST argv!4 THEN writef("num/n/p:  %n*n", !argv!4)
              ELSE writef("num/n/p:  %s*n", "<unset>")

  RESULTIS 0
}
