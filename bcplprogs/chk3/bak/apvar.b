// The apply newly discovered information about a variable
// or a pair of variables

// These apply to all relations

// apvarset1(i)        apply  vi  =   1 and eliminate vi
// apvarset0(i)        apply  vi  =   0 and eliminate vi

// apvareq(i, j)       apply  vi  =  vj and eliminate vj, i<j
// apvarne(i, j)       apply  vi  = ~vj and eliminate vj, i<j

// apvarimppp(i, j)    apply  vi ->  vj
// apvarimppn(i, j)    apply  ai -> ~vj
// apvarimpnp(i, j)    apply  vi ->  vj
// apvarimpnn(i, j)    apply ~vi -> ~vj

SECTION "applyfns"

GET "libhdr"
GET "chk3.h"

LET ignorevar(rel, i) BE
{ LET v = @rel!r_v0
  FOR a = 0 TO 2 IF v!a=i DO ignorearg(rel, a)
}

LET apvarset1(i) BE
{ // For every relation involving vi
  // set it to 1,
  // remove that variable from the relation
  // and push the relation onto the stack if it is not already there.
  LET rl = refs!i
  writef("apvarset1: v%n = 1*n", origid(i))

  varinfo!i := 1  // Remember that vi=1

  WHILE rl DO
  { LET rel = rl!1
    LET v = @rel!r_v0
    LET a = 7
    rl := !rl

    // Find the argument number of vi
    UNTIL a<0 | v!a=i DO a := a-1
    IF a<0 DO
    { wrrel(rel, TRUE)
      bug("apvarset1: v%n is not in this relation*n", origid(i))
      LOOP
    }
    // Find and eliminate all occurrences of vi
    { IF v!a=i DO
      { newline()
        wrrel(rel, TRUE)
        apset1(rel, a)
        //standardise(rel)
        pushrel(rel)
      }
      a := a-1
    } REPEATUNTIL a<0
  }
  refcount!i := 0
abort(3333)
}

AND apvarset0(i) BE
{ // For every relation involving vi
  // set it to 0,
  // remove that variable from the relation
  // and push the relation onto the stack if it is not already there.
  LET rl = refs!i
  writef("apvarset0: v%n = 0*n", origid(i))

  varinfo!i := 0  // Remember that vi=0

  WHILE rl DO
  { LET rel = rl!1
    LET v = @rel!r_v0
    LET a = 7
    rl := !rl


    // Find the argument number of vi
    UNTIL a<0 | v!a=i DO a := a-1
    IF a<0 DO
    { wrrel(rel, TRUE)
      bug("apvarset0: v%n is not in this relation*n", origid(i))
      LOOP
    }

    // Find and eliminate all occurrences of vi
    { IF v!a=i DO
      { newline()
        wrrel(rel, TRUE)
        apset0(rel, a)
        //standardise(rel)
        pushrel(rel)
      }
      a := a-1
    } REPEATUNTIL a<0
    //wrrel(rel, TRUE)
  }
  refcount!i := 0
abort(3333)
}

AND apvareq(i, j) BE
{ // Assume i<j
  // For every relation involving vi and vj
  // set vj=vi and remove vj from the relation
  // and push the relation onto the stack if it is not already there.
  LET rl = refs!i
writef("apvareq: v%n =  v%n*n", origid(i), origid(j))

  varinfo!i := 2*j  // Remember that vi=vj

  WHILE rl DO
  { LET rel = rl!1
    LET v = @rel!r_v0
    LET a, b = 2, 2
    rl := !rl

    // Find the argument number of vj if it occurs
    UNTIL b<0 | v!b=j DO b := b-1

    IF b<0 LOOP // vj is not in this relation
//wrrel(rel, TRUE)
    // Find the argument number of vi
    UNTIL a<0 | v!a=i DO a := a-1
    IF a<0 DO
    { wrrel(rel, TRUE)
      bug("apvareq: v%n is not in this relation*n", origid(i))
      LOOP
    }
    newline()
    wrrel(rel, TRUE)

    // Find and eliminate all occurrences of vj
    { IF v!b=j DO apeq(rel, a, b)
      b := b-1
    } REPEATUNTIL b<0

    pushrel(rel)
//    wrrel(rel, TRUE)
  }
  refcount!j := 0
abort(3333)
}

AND apvarne(i, j) BE
{ // Assume i<j
  // For every relation involving vi and vj
  // set vj=~vi and remove vj from the relation
  // and push the relation onto the stack if it is not already there.
  LET rl = refs!i
writef("apvarne: v%n =  v%n*n", origid(i), origid(j))

  varinfo!i := 2*j + 1  // Remember that vi = ~vj

  WHILE rl DO
  { LET rel = rl!1
    LET v = @rel!r_v0
    LET a, b = 2, 2
    rl := !rl

    // Find the argument number of vj if it occurs
    UNTIL b<0 | v!b=j DO b := b-1

    IF b<0 LOOP // vj is not in this relation
//wrrel(rel, TRUE)
    // Find the argument number of vi
    UNTIL a<0 | v!a=i DO a := a-1
    IF a<0 DO
    { wrrel(rel, TRUE)
      bug("apvarne: v%n is not in this relation*n", origid(i))
      LOOP
    }
    newline()
    wrrel(rel, TRUE)

    // Find and eliminate all occurrences of vj
    { IF v!b=j DO apne(rel, a, b)
      b := b-1
    } REPEATUNTIL b<0

    pushrel(rel)
//wrrel(rel, TRUE)
  }
  refcount!j := 0
abort(3333)
}

AND apvarimppp(i, j) BE
{ // Assume i<j
  // For every relation involving vi and vj
  // impose the constraint vi->vj
  // and push the relation onto the stack if it is not already there.
  LET rl = refs!i
writef("apvarimppp:  v%n ->  v%n*n", origid(i), origid(j))

  WHILE rl DO
  { LET rel = rl!1
    LET v = @rel!r_v0
    LET a, b = 2, 2
    rl := !rl

    // Find the argument number of vj if it occurs
    UNTIL b<0 | v!b=j DO b := b-1
    IF b<0 LOOP // vj is not in this relation
    //wrrel(rel, TRUE)
    // Find the argument number of vi
    UNTIL a<0 | v!a=i DO a := a-1
    IF a<0 DO
    { newline()
      wrrel(rel, TRUE)
      bug("apvarne: v%n is not in this relation*n", origid(i))
      LOOP
    }
    newline()
    wrrel(rel, TRUE)
    // Apply vi->vj for all occurrences of vj ???????????????
    { IF v!b=j DO apimppp(rel, a, b)
      b := b-1
    } REPEATUNTIL b<0
    //wrrel(rel, TRUE)
  }
  refcount!j := 0
abort(3333)
}


AND apvarimppn(i, j) BE
{ // Assume i<j
  // For every relation involving vi and vj
  // impose the constraint vi->~vj
  // and push the relation onto the stack if it is not already there.
writef("apvarimppn:  v%n -> ~v%n*n", origid(i), origid(j))
  abort(8888)
  RETURN
}

AND apvarimpnp(i, j) BE
{ // Assume i<j
  // For every relation involving vi and vj
  // impose the constraint ~vi->vj
  // and push the relation onto the stack if it is not already there.
writef("apvarimpnp: ~v%n ->  v%n*n", origid(i), origid(j))
  abort(8888)
  RETURN
}

AND apvarimpnn(i, j) BE
{ // Assume i<j
  // For every relation involving vi and vj
  // impose the constraint ~vi->~vj
  // and push the relation onto the stack if it is not already there.
writef("apvarimpnn: ~v%n -> ~v%n*n", origid(i), origid(j))
  abort(8888)
  RETURN
}

