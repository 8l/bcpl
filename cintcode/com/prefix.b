GET "libhdr"

LET start() = VALOF
{ LET argv = VEC 50
  LET newstr = ?
  LET unset  = ?

  UNLESS rdargs("PREFIX,UNSET/S", argv, 50) DO
  { writef("Bad argument for PREFIX*n")
    RESULTIS 20
  }

  newstr := argv!0        // PREFIX
  unset  := argv!1        // UNSET/S

  IF newstr DO sys(Sys_setprefix, newstr)
  IF unset  DO sys(Sys_setprefix, "")

  UNLESS newstr | unset DO
  { LET prefix = sys(Sys_getprefix)
    TEST prefix%0
    THEN writef("%s*n", prefix)
    ELSE writef("No prefix*n")
  }

  RESULTIS 0
}
