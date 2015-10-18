GET "libhdr"
GET "chk3.h"

LET bug(mess, a,b,c) BE
{ writef(mess, a, b, c)
  abort(999)
}

AND mk2(x, y) = VALOF
{ LET res = ?
//writef("mk2: x=%n y=%n*n", x,y)
  UNLESS freepairs DO
  { freepairs := getvec(4000)
    UNLESS freepairs DO
    { writef("out of space*n")
      abort(999)
      RESULTIS 0
    }
    !freepairs := pairblks
    pairblks := freepairs

    //writef("pair block %n allocated*n", pairblks)
    // Form free list of pairs
    res := pairblks+4000-1
    freepairs := 0
    UNTIL res<=pairblks DO
    { res!0, res!1 := freepairs, 0
      freepairs := res
      res := res-2
    }
  }
  res := freepairs
  freepairs := !freepairs
  res!0, res!1 := x, y
  RESULTIS res
}

AND unmk2(p) BE
{ !p := freepairs
  freepairs := p
}

LET rdrels(name) = VALOF
{ // Reads the specified file of relations. Each relation consists of 8
  // hex numbers for the 256-bit pattern followed by 8 non negative
  // integers specifying the variables.
  // The result is TRUE if successful, FALSE otherwise.
  // reln is set to the number of relations read
  // relv!1 to relv!reln pointer to the relation nodes.
  // The relation nodes are placed in relspace.
  LET res = FALSE
  LET p = 1 // The position in relspace of the next relation.
  LET oldin = input()
  LET data = findinput(name)
  LET value = ?

  reln := 0  // Number of relations read

  UNLESS data GOTO fin
  selectinput(data)
  ch := rdch()
  lex()

  UNTIL token=s_eof DO
  { LET rel = newrel()
    LET v, w = @rel!r_v0, @rel!r_w0
    UNLESS token=s_bits BREAK

    w!0 := lexval
    lex()

    FOR i = 1 TO 1 DO      // Read the bit pattern words
    { UNLESS token=s_bits BREAK
      w!i := lexval
      lex()
    }

    UNLESS token=s_var DO
    { writef("Bad relation data -- variable expected*n")
      BREAK
    }

    FOR i = 0 TO 2 DO      // Read the variable identifiers
    { UNLESS token=s_var BREAK
      v!i := lexval
      lex()
    }

    // Fill in the relation properties
    rel!r_instack := FALSE  // changed -- no
    rel!r_weight := 9999    // weight -- dummy value
    rel!r_varcount := 3     // varcount
    rel!r_numb := reln      // Relation number
  }

fin:
  IF data UNLESS data=oldin DO endread()
  selectinput(oldin)
  RESULTIS reln>0
}

AND newrel() = VALOF
// Allocate a blank relation
{ LET rel = @relspace!relspacep

  // Allocate a new relation
  relspacep := relspacep + r_upb + 1
  IF relspacep > relspaceupb DO
  { writef("Insufficient space*n")
    RESULTIS 0
  }
  reln := reln+1
  relv!reln := rel
  FOR i = 0 TO r_upb DO rel!i := 0
  RESULTIS rel
}

AND mkrel(bits, a, b, c) = VALOF
{ LET rel = newrel()
  rel!r_w0 := bits
  rel!r_v0 := a
  rel!r_v1 := b
  rel!r_v2 := c
  RESULTIS rel  
}

AND lex() BE
{ SWITCHON ch INTO
  { DEFAULT:  writef("Bad relation data, ch=%n '%c'*n", ch, ch)

    CASE endstreamch:
               token := s_eof
               RETURN

    CASE '*s':                              // White space
    CASE '*n': ch := rdch()
               LOOP

    CASE '#':                               // Comment
              ch := rdch() REPEATUNTIL ch='*n' | ch=endstreamch
              LOOP

    CASE 'v':                               // A variable
    CASE 'V': ch := rdch()
              lexval := rdnum()
              token := s_var
              RETURN

    CASE '0':CASE '1':                      // Relation bit pattern
              lexval := rdbin()
              token := s_bits
              RETURN
  }
} REPEAT


// Read a relation bit pattern
AND rdbin() = VALOF
{ LET res = 0

  WHILE '0'<=ch<='1' DO
  { res := (res<<1) + ch - '0'
    ch := rdch()
  }

  RESULTIS res
}

// Read a decimal number
AND rdnum() = VALOF
{ LET res = 0

  { LET dig = -1
    IF '0'<=ch<='9' DO dig := ch - '0'
    IF dig<0 BREAK
    res := res*10 + dig
    ch := rdch()
  } REPEAT

  RESULTIS res
} REPEAT

// Write out all the relations
AND wrrels(verbose) BE
{ FOR i = 1 TO reln DO wrrel(relv!i, verbose)
  newline()
}

// Write out a particular relation
AND wrrel(rel, verbose) BE
{ LET upb = 2

  IF FALSE DO
  { writes("*na2  ")
    FOR i = 0 TO upb DO writef("10101010 ")
    newline()
  }

  IF verbose DO writef("%i2: ", rel!r_numb)

  writef("%b8 ", rel!r_w0)

  upb := 2
  WHILE upb>0 DO
  { IF rel!(r_v0+upb) BREAK
    upb := upb-1
  }

  FOR i = r_v0 TO r_v0+upb DO writef("v%n ",  origid(rel!i))

  IF tracing DO writef(" S:%n W:%n N:%n",
                        rel!r_instack,  rel!r_weight, rel!r_varcount)
  newline()
}

AND wrvars() BE
{ // varinfo!i holds information about new variable Vi
  // = -2     means the variable is not used in any relation
  // = -1     means the variable is used in exactly one relation
  // = 0      means the variable is known to have value 0
  // = 1      means the variable is known to have value 1
  // = 2j     means Vi =  Vj, 0<j<i
  // = 2j+1   means Vi = ~Vj, 0<j<i

  FOR id = 1 TO maxid DO
  { LET rl, count = refs!id, refcount!id
    LET info = varinfo!id
    LET i = info/2
    writef("v%n: ", origid(id))
    SWITCHON info INTO
    { DEFAULT:  IF info>0 DO
                { writef("%cv%n ", info REM 2 -> '~', ' ', origid(info/2))
                  ENDCASE
                }
                writef("???? "); ENDCASE
      CASE -2:  writef("X    "); ENDCASE
      CASE -1:  writef("     "); ENDCASE
      CASE  0:  writef("0    "); ENDCASE
      CASE  1:  writef("1    "); ENDCASE
    }
    WHILE rl DO
    { writef("  %i3", rl!1!r_numb)
      rl := !rl
    }
    newline()
  }
}

AND origid(id) = VALOF
{ LET tab = id2orig
  WHILE tab DO
  { id := tab!id
    tab := !tab
  }
  RESULTIS id
}

// formlists allocates and initialises the following vectors from
// the given set of relations.

// refs        refs!id is the list of relations using id
// refcount    refcount!id hold the number of uses of each new id
// id2orig     a vector mapping new ids to old ids
// varinfo     a vector holding information about each new ids

// It also allocates and clears mata,..,matd and mataprev,...,matdprev

AND formlists(rv, n) BE // rv!1 to rv!n are the given relations
{ LET maxoldid, old2new = 0, 0

  // Find maxoldid
  FOR i = 1 TO n DO
  { LET rel = rv!i
    LET v = @rel!r_v0
    FOR j = 0 TO 2 DO
    { LET id = v!j  // Look at every variable used by every relation
      IF maxoldid<id DO maxoldid := id  // Maximum old identifier
    }
  }
  writef("Maximum old variable number = %n*n", maxoldid)

  old2new := getvec(maxoldid)

  UNLESS old2new DO
  { writef("More space needed for old2new*n")
    abort(999)
    GOTO fin
  }
  // Re-number the variables keeping them in the same order.

  // Mark all variables that have been used
  FOR id = 0 TO maxoldid DO old2new!id := 0
  FOR r = 1 TO n DO // Look at every relation
  { LET rel = rv!r
    LET v = @rel!r_v0
    FOR arg = 0 TO 2 DO // Look at every relation argument
    { LET id = v!arg
      IF id DO old2new!id := -1 // This old id has been used
    }
  }

  // Allocate new variable numbers, filling in the old2new table entries
  // and calculating maxid (the maximum new variable number).
  maxid := 0
  old2new!0 := 0 // Identifier 0 always maps to zero
  FOR id = 1 TO maxoldid IF old2new!id DO
  { maxid := maxid+1
    old2new!id := maxid
  }

  writef("Maximum new variable number = %n*n", maxid)

  // Allocate the refs vector and others
  refs     := getvec(maxid)
  refcount := getvec(maxid)
  id2orig  := getvec(maxid)
  varinfo  := getvec(maxid)

  UNLESS refs & refcount & id2orig & varinfo DO
  { writef("More space needed*n")
    abort(999)
    GOTO fin
  }

  FOR id = 0 TO maxid DO
  { id2orig!id  := 0    // Later set to the original variable number
    varinfo!id  := -1   // Nothing known
    refs!id     := 0    // List of relation containing this variable
    refcount!id := 0    // The length of refs!id
  }

  // Construct the refs lists
  FOR r = 1 TO n DO // Look at every relation
  { LET rel = rv!r
    LET v = @rel!r_v0
    FOR arg = 0 TO 2 DO // Look at every relation argument
    { LET id = v!arg    // Look at every variable used in the relation
      IF id DO
      { LET newid = old2new!id
        v!arg := newid       // Renumber the variable in the relation
        id2orig!newid := id  // Remember the mapping
        refs!newid := mk2(refs!newid, rel) // add to refs list
        refcount!newid := refcount!newid + 1 // Increment its ref count
      }
    }
  }

  setweights()

  // Allocate the boolean matrices

  bm_setmatsize(maxid<32 -> 32, maxid)

  mata     := bm_mkmat()
  matb     := bm_mkmat()
  matc     := bm_mkmat()
  matd     := bm_mkmat()

  mataprev := bm_mkmat()
  matbprev := bm_mkmat()
  matcprev := bm_mkmat()
  matdprev := bm_mkmat()

fin:
  IF old2new  DO freevec(old2new)
}

AND length(p) = VALOF
{ LET res = 0
  WHILE p DO res, p := res+1, !p
  RESULTIS res
}

AND sortpairs(v, w, upb) BE  // (v!i,w!i) is the key for item i
{ LET m = 1
  UNTIL m>upb DO m := m*3 + 1  // Find first suitable value in the
                               // series:  1, 4, 13, 40, 121, 364, ...
  { m := m/3
    FOR i = m+1 TO upb DO
    { LET vi, wi = v!i, w!i
      LET j = i
      { LET k = j - m
        IF k<=0 | v!k < vi | v!k=vi & w!k<wi BREAK
        v!j, w!j := v!k, w!k
        j := k
      } REPEAT
      v!j, w!j := vi, wi
    }
  } REPEATUNTIL m=1
}

AND prpairs(v, w, upb) BE FOR i = 1 TO upb DO
  writef("%i3:  %i4  %i4*n", i, v!i, w!i)

AND setweights() BE FOR r = 1 TO reln IF relv!r DO
{ LET rel = relv!r
  LET v = @rel!r_v0
  LET weight, count = 0, 0
  FOR arg = 0 TO 2 DO
  { LET id = v!arg
    UNLESS id LOOP
    count := count + 1
    weight := weight + refcount!id
  }
  rel!r_varcount := count
  rel!r_weight   := weight
}

AND pushrel(r) BE UNLESS r!r_instack DO
{ // Push a relation onto the stack if it is not already there
  // because the relation has changed and must be inspected.
  r!r_instack := TRUE
  IF relstackp>=relstackupb DO
  { writef("relstack too small*n")
    abort(999)
    RETURN
  }
  relstackp := relstackp + 1
  relstack!relstackp := r

  //newline()
  //wrrel(r, TRUE)
  //writef("pushrel:  ")
  //FOR i = 1 TO relstackp DO writef(" %n", relstack!i!r_numb)
  //newline()
//abort(4444)
}

AND poprel() = VALOF
{ // Pop a relation from the stack, returning 0 if the stack is empty
  LET rel = relstack!relstackp
  UNLESS relstackp RESULTIS 0
  rel!r_instack := FALSE

  //writef("*npoprel:   ")
  //FOR i = 1 TO relstackp DO writef(" %n", relstack!i!r_numb)
  //newline()
//wrrel(rel, TRUE)
//abort(4444)
  relstackp := relstackp -1
  RESULTIS rel
}

// Unlink one reference to rel in refs!id
AND rmref(rel, id) BE
{ LET a = @refs!id
  //wrrel(rel, TRUE)
  //writef("rmref: rel %n v%n*n", rel!r_numb, id)
//abort(5555)
  WHILE !a DO
  { LET rl = !a
    LET next = !rl
    IF rl!1=rel DO
    { // Reference to rel found
      !a, refcount!id := next, refcount!id -1 
      RETURN
    }
    rl := !next
  }
  writef("rmrel: relation not found, numb=%n v%n*n", rel!r_numb, id)
  abort(999)
}



