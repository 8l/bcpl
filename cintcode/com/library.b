SECTION "LIBRARY"

GET "libhdr"

MANIFEST { yes      =  TRUE
           no       = FALSE
           nameupb  = 11  // upb of a section name
         }


// TRIPOS library command.  It loads an object module
//  and adds the segment to the end of the BLIB
//  library chain. (!!)
// It will also cancel a loaded section.

LET start() BE
// LIBRARY [[FROM] file] [OVERRIDE] [CANCEL secname]]

{ LET cancelname = 0
  LET cancelvec  = VEC nameupb/bytesperword
  LET tcb        = rootnode!rtn_tasktab!taskid
  LET blibe      = (tcb_seglist ! tcb) + 2
  LET blib       = !blibe
  LET segment    = 0

  LET argv       = VEC 50

  IF rdargs("from,override/s,cancel/k", argv, 50) = 0 THEN
  { writes("Invalid parameters*N")
    stop(20)
  }

  IF argv!2 DO                               // CANCEL
  { cancelname := cancelvec
    copy.section.name(argv!2, cancelname)
  }

  IF argv!0 DO                               // FROM
  { LET secname = VEC nameupb/bytesperword

    segment    := loadseg(argv!0)

    UNLESS segment DO
    { writef("Unable to load segment *"%s*"*n", argv!0)
      stop(20)
    }

    // See if segment is already loaded

    IF extract.section.name(segment+1, secname) & argv!1 = 0 &
       (cancelname = 0 | compstring(secname, cancelname)) &
       find.section(blib, secname) DO
    { writef("Library %s already loaded*n", secname)
      unloadseg(segment)
      stop(20)
    }

    // Now that the library has been loaded, initialise
    //  its globals.  (In case the original library is
    //  about to be cancelled)!.

    UNLESS globin(segment) DO
      writes("Warning: global initialisation ended in error*n")

    // Now add to the end of the chain

    !findptr(blibe, 0) := segment
  }

  // Deal with CANCEL parameter

  IF cancelname DO
  { LET sec  = find.section(blib, cancelname)

    TEST sec = 0
    THEN { writef("Failed to find section *"%S*"*N",cancelname)
           returncode := 10
         }
    ELSE { // Delete the section
           LET secp  = findptr(blibe, sec)
           !secp := !sec
           freevec(sec)
         }
  }
}

AND findptr(lv.chain, hunk) = VALOF
{ UNTIL !lv.chain = hunk | !lv.chain = 0 DO lv.chain := !lv.chain
  RESULTIS lv.chain
}

AND copy.section.name(name, v) BE
{ FOR j = 1 TO 11 DO v%j := j > name%0 -> ' ', name%j
  v%0 := 11
}

AND extract.section.name(hunk, v) = VALOF
// Returns TRUE if there is a valid section name.
{ LET size = hunk!0
  IF size >= 11 & hunk!1 = sectword & (hunk+2)%0 = 11 /*was 17 */ DO
  { copy.section.name(hunk+2, v)
    RESULTIS yes
  }
  RESULTIS no
}



AND find.section(list, name) = VALOF
{ WHILE list DO
  { LET v = VEC nameupb/bytesperword
    IF extract.section.name(list+1, v)      &
       compstring(v, "**************") \= 0 &
       compstring(v, name)              = 0 BREAK
    list := !list
  }
  RESULTIS list
}
