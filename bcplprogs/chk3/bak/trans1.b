// Unit transformations on a single relation

// exchargs(rel, i, j)    exchange the positions of arguments i and j
// ignorearg(rel, i)      remove arg i, assuming it is unconstrained
// dontcare(rel, i) => TRUE if the relation places no constraint on arg i
// standardise(rel)       sort arguments and remove duplicates

// split(rel)             split rel into two if possible

SECTION "trans1"

GET "libhdr"
GET "chk3.h"

// Exchange arguments i and j in a relation
LET exchargs(rel, i, j) BE
// Assume i and j are in the range 0..2
{ LET a = rel!r_w0
  LET v = @rel!r_v0
  LET t = v!i
newline()
wrrel(rel)
writef("exchargs: args %n %n*n", i, j)
  v!i := v!j    // Swap variable identifiers
  v!j := t

  // Adjust the bit pattern
  SWITCHON i*8 + j INTO
  { DEFAULT:
      ENDCASE  // Either i=j or an error
    CASE #21: CASE #12:
      rel!r_w0 := a&#xC3 | a<<2 & #x30 | a>>2 & #x0C
      ENDCASE
    CASE #20: CASE #02:
      rel!r_w0 := a&#xA5 | a<<3 & #x50 | a>>3 & #x0A
      ENDCASE
    CASE #10: CASE #01:
      rel!r_w0 := a&#x99 | a<<1 & #x44 | a>>1 & #x22
      ENDCASE
  }
wrrel(rel)
}

// ignorearg(rel, i)      remove arg i, assuming it is unconstrained
AND ignorearg(rel, i) BE
{ LET a = rel!r_w0

//newline()
//wrrel(rel)
writef("ignorearg: %n*n", i)
  SWITCHON i INTO
  { DEFAULT:  RETURN
    CASE 2: rel!r_w0 := (a | a>>4) & #x0F; ENDCASE
    CASE 1: rel!r_w0 := (a | a>>2) & #x33; ENDCASE
    CASE 0: rel!r_w0 := (a | a>>1) & #x55; ENDCASE
  }
//writef("ignorearg: i=%n sh=%n mask=%n*n", i, sh, mask)

ret:
  rmref(rel, i)
  wrrel(rel)
}

AND dontcare(rel, i) = VALOF
{ LET res = dontcare1(rel, i)
  //writef("dontcase => %n*n", res)
  RESULTIS res
}

// dontcare(rel, i) => TRUE if the relation places no constraint on arg i
AND dontcare1(rel, i) = VALOF
{ LET a = rel!r_w0
  LET sh, mask = ?, ?

//wrrel(rel);newline()
//writef("dontcare: %n*n", i)
  SWITCHON i INTO
  { DEFAULT:  bug("dontcase: Bad argument number %n*n", i)
              RESULTIS FALSE
    CASE 2:  RESULTIS ((a XOR a>>4) & #x0F) = 0 -> TRUE, FALSE
    CASE 1:  RESULTIS ((a XOR a>>2) & #x33) = 0 -> TRUE, FALSE
    CASE 0:  RESULTIS ((a XOR a>>1) & #x55) = 0 -> TRUE, FALSE
  }
}

AND standardise(rel) BE
// Standardise a relation
{ LET v = @rel!r_v0

//wrvars()

writef("standardise:*n")
wrrel(rel, TRUE)

  // Remove arguments not constrained by this relation
  FOR i = 0 TO 2 IF v!i & dontcare(rel, i) DO
  { 
writef("standardise: remove irrelevant variable v%n*n", origid(v!i))
    rmref(rel, v!i)
    v!i := 0
  }

  // Sort the arguments, removing duplicates
  FOR i = 0 TO 1 DO
  { LET min, p = maxint, -1
    // Find the next smallest variable
    FOR j = i TO 2 DO
    { LET var = v!j
      IF var & var<min DO min, p := var, j
    }
    IF p<0 BREAK // No more variables

    UNLESS v!i=v!p DO exchargs(rel, i, p)

    // Check whether there are any repetitions
    FOR j = p+1 TO 2 IF v!j=min DO
    { apeq(rel, i, j)
      ignorearg(rel, j)
    }
  }

  // Clear unused bits of the bit pattern
  IF v!2 DO { rel!r_w0 := rel!r_w0 & #xFF; wrrel(rel, TRUE); RETURN }
  IF v!1 DO { rel!r_w0 := rel!r_w0 & #x0F; wrrel(rel, TRUE); RETURN }
  IF v!0 DO { rel!r_w0 := rel!r_w0 & #x03; wrrel(rel, TRUE); RETURN }
  rel!r_w0 := rel!r_w0 & #x01
  wrrel(rel, TRUE)
}

AND teststandardise() BE
  testallvars(teststandardise1)

AND teststandardise1(a, b, c) BE
{ // a,b and c take all values between 0 and 3
  FOR relbits = 0 TO #b11111111 DO
  { // Ensure there are no relations,
    // varinfo, ref and refcount all initialised
    LET r1, r2 = 0, 0
    inittest()
    r1 := mkrel(1, relbits, a, b, c)
    r2 := mkrel(2, relbits, a, b, c)
    formlists()
    // The global data is now set up.

    standardise(r1)
    checkeqv(r1, r2)
  }
}
