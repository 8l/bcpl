/*
This command either lists the current logical name value pairs
or adds a new pair to the list. The list is held in the root node.

8/7/03 Initial implementation.
*/

SECTION "setlogname"

GET "libhdr"

LET start() = VALOF
{ LET argv = VEC 50
  LET peername = 0

  UNLESS rdargs("NAME,VALUE", argv, 50) DO
  { writef("Bad arguments for setlogname*n")
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

  setlogname(argv!0, argv!1)                // NAME, VALUE
  RESULTIS 0
}
  
    
