/*
This command outputs the value of a given logical variable name.
If none is given it lists the names and values of all logical variables.

3/5/04 Initial implementation.
*/

SECTION "getlogname"

GET "libhdr"

LET start() = VALOF
{ LET argv = VEC 50
  LET value = 0

  UNLESS rdargs("NAME", argv, 50) DO
  { writef("Bad arguments for getlogname*n")
    RESULTIS 20
  }

  UNLESS argv!0 DO                          // NAME
  { LET p = rootnode!rtn_envlist
    WHILE p DO
    { writef("%tP = %s*n", p!1, p!2)
      p := !p
    }
    RETURN
  }

  value := getlogname(argv!0)
  UNLESS value DO value := "<UNSET>"
  writef("%s = %s*n", argv!0, value)
  RESULTIS 0
}
  
    
