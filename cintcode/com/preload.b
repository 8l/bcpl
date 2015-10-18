// Written by M. Richards  (c) June 2006

SECTION "PRELOAD"

GET "libhdr"

LET start() = VALOF // PRELOAD [NAME] commandname
{ LET v = VEC 50

  IF rdargs(",,,,,,,,,",v,50) = 0 DO
  { writes("Parameters no good for PRELOAD*N")
    RESULTIS 20
  }

  IF v!0=0 DO wrpreloadlist()
  FOR i = 0 TO 9 UNLESS v!i=0 DO preload(v!i)
  RESULTIS 0
}

AND wrpreloadlist() BE
{ LET p = cli_preloadlist
  IF p=0 DO writes("No preloaded commands*n")
  UNTIL p=0 DO
  { LET q = p!1
    AND name = @ p!2
    AND size = 0
    WHILE q DO { size := size+q!1
                 q := !q
               }
    writef("%tF  size %i5 bytes*n", name, size<<2)
    p := !p
  }
}

AND preload(name) BE
{ LET module = loadseg(name)
  AND p = cli_preloadlist
  AND len = name%0
  UNLESS module DO { writef("Unable to preload %s*n", name)
                     RETURN
                   }
  // Replace the previous preloaded version if it exists.
  WHILE p DO { IF compstring(name, @p!2)=0 DO
               { unloadseg(p!1)
                 p!1 := module
                 RETURN
               }
               p := !p
             }
  // Insert a new item in the preload list.
  p := getvec(3 + len/bytesperword)
  UNLESS p DO { writef("Unable to preload %s*n", name)
                RETURN
              }
  p!0 := cli_preloadlist
  p!1 := module
  FOR i = 0 TO len DO (@p!2)%i := name%i
  cli_preloadlist := p
}
