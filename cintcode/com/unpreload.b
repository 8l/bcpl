// Written by Martin Richards (c) June 2006

SECTION "UNPRELOAD"

GET "libhdr"

LET start() = VALOF // UNPRELOAD [NAME] commandname
{ LET v = VEC 100

  UNLESS rdargs(",,,,,,,,,,ALL/S",v,100) DO
  { writes("Parameters no good for UNPRELOAD*N")
    RESULTIS 20
  }

  IF v!10 DO { unpreload(0); RESULTIS 0 }
  FOR i = 0 TO 9 IF v!i DO unpreload(v!i)
  RESULTIS 0
}

AND unpreload(name) BE
{ LET p = @cli_preloadlist

  WHILE !p DO { LET q = !p
                TEST name=0 | compstring(name, @q!2)=0
                THEN { unloadseg(q!1)
                       !p := !q
                       freevec(q)
                       IF name RETURN
                     }
                 ELSE p := q
               }

  IF name DO writef("Unable to unpreload %s*n", name)
}
