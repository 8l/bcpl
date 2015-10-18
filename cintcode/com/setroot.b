// This command can set or inspect the rootnode
// variables: rootvar, pathvar, hdrsvar and scriptvar

GET "libhdr"

LET start() = VALOF
{ LET argv = VEC 50
  LET rootvar    = "<unset>"
  LET pathvar    = rootvar
  LET hdrsvar    = rootvar
  LET scriptsvar = rootvar

  UNLESS rdargs("root,path,hdrs,scripts", argv, 50) DO
  { writef("Bad arguments for SETROOT*n")
    RESULTIS 0
  }

  UNLESS argv!0 | argv!1 | argv!2 | argv!4 DO
  { // Output the current settings
    IF rootnode!rtn_rootvar DO rootvar := rootnode!rtn_rootvar
    IF rootnode!rtn_pathvar DO pathvar := rootnode!rtn_pathvar
    IF rootnode!rtn_hdrsvar DO hdrsvar := rootnode!rtn_hdrsvar
    IF rootnode!rtn_scriptsvar DO scriptsvar := rootnode!rtn_scriptsvar
    writef("ROOTVAR    = *"%s*"*n", rootvar)
    writef("PATHVAR    = *"%s*"*n", pathvar)
    writef("HDRSVAR    = *"%s*"*n", hdrsvar)
    writef("SCRIPTSVAR = *"%s*"*n", scriptsvar)
    RESULTIS 0
  }

  IF argv!0 DO copystr(argv!0, rootnode!rtn_rootvar)
  IF argv!1 DO copystr(argv!1, rootnode!rtn_pathvar)
  IF argv!2 DO copystr(argv!2, rootnode!rtn_hdrsvar)
  IF argv!3 DO copystr(argv!3, rootnode!rtn_scriptsvar)

  RESULTIS 0
}

AND copystr(s1, s2) BE
{ LET len = s1%0
  TEST len>39
  THEN writef("String %s too long*n", s1)
  ELSE FOR i = 0 TO s1%0 DO s2%i := s1%i
}
