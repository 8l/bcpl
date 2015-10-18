SECTION "INTERPRETER"

GET "libhdr"

LET start() = VALOF 
{ LET argv = VEC 10
  AND val = -1
   
  IF rdargs("FAST/S,SLOW/S", argv, 10)=0 DO
  { writef("Bad argument for INTERPRETER*n")
    RESULTIS 20
  }
   
  IF argv!0 DO val := -1     // select fast interpreter (cintasm) 
  IF argv!1 DO val := maxint // select slow interpreter (cinterp) 
   
  sys(Sys_setcount, val)     // make selection

  writef("%s interpreter selected*n", val=-1 -> "Fast", "Slow")
  RESULTIS 0
}
