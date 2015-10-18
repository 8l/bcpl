SECTION "shellcom"

GET "libhdr"

LET start() BE
{ LET argv = VEC 80

  UNLESS rdargs("COM/A", argv, 80) DO
  { writef("Bad argument for SHELLCOM*n")
    stop(20)
  }

  sys(Sys_shellcom, argv!0)
}


