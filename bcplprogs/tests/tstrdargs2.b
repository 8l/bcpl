// Test the rdargs2 function

GET "libhdr"

LET start() = VALOF
{ LET format1 = "from/a/p,to/k,ver/p,flag/s/p,num/n/p,"
  LET format2 = "fromx/a/p,tox/k,verx/p,flagx/s/p,numx/n/p"
  LET argv = VEC 250

  LET w = rdargs2(format1, format2, argv, 250)
  UNLESS w DO
  { writef("Bad arguments for tstrdargs2 %s%s*n", format1, format2)
    RESULTIS 0
  }
 
  TEST argv!0 THEN writef("from/a/p:  %s*n", argv!0)
              ELSE writef("from/a/p:  %s*n", "<unset>")
  TEST argv!1 THEN writef("to/k:      %s*n", argv!1)
              ELSE writef("to/k:      %s*n", "<unset>")
  TEST argv!2 THEN writef("ver/p:     %s*n", argv!2)
              ELSE writef("ver/p:     %s*n", "<unset>")
  TEST argv!3 THEN writef("flag/s/p:  true*n")
              ELSE writef("flag/s/p:  false*n")
  TEST argv!4 THEN writef("num/n/p:   %n*n", !argv!4)
              ELSE writef("num/n/p:   %s*n", "<unset>")

  TEST argv!5 THEN writef("fromx/a/p: %s*n", argv!5)
              ELSE writef("fromx/a/p: %s*n", "<unset>")
  TEST argv!6 THEN writef("tox/k:     %s*n", argv!6)
              ELSE writef("tox/k:     %s*n", "<unset>")
  TEST argv!7 THEN writef("verx/p:    %s*n", argv!7)
              ELSE writef("verx/p:    %s*n", "<unset>")
  TEST argv!8 THEN writef("flagx/s/p: true*n")
              ELSE writef("flagx/s/p: false*n")
  TEST argv!9 THEN writef("numx/n/p:  %n*n", !argv!9)
              ELSE writef("numx/n/p:  %s*n", "<unset>")

  RESULTIS 0
}
