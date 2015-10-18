/* 
This is a simple implementation of an algorithm to find the least
common ancestor of pairs of vertices in a tree, based on the following
paper:

Tarjan R.E.
Applications of Path Compression on Balanced Trees
Journal of the ACM, Vol 26, No. 4, October 1979, pp. 690-715.

Implemented in BCPL by Martin Richards (c) Mar 2001
*/

GET "libhdr"

MANIFEST {

// Structure of a node
Id=0     // DFS discovery time -- used as id in the algorithm
Parent   // DFS tree parent
Pairs    // List of vertex pairs
         // involving this vertex and ones with larger Ids
Best     // Hold the node with smallest Id in the same set as this node
Ancestor // (using the UNION-FIND structure)
Size
NodeSize
NodeUpb=NodeSize-1
}

GLOBAL {
vertex:200      // Vector of nodes in dfs order
previd          // Used for allocating node ids

root            // Root of the flow graph
nodes           // Number of nodes in the graph
pairs           // Number of vertex pairs
pairlist        // List of vertex pairs

newvec; initspace; freespace; mkNode; mk2; freelist

eval; link

edge            // add an edge when building a graph
mktree          // make a random flow graph
prnodes
prstruct
hashtree
hashresult

spacev; spacep; spacet  // Pointers in the free space
mk2list                 // free list of mk2 nodes
debug                   // debug level
stdout
tostream
}

LET newvec(upb) = VALOF
{ LET p = spacep - upb - 1
  IF p<spacev DO
  { writef("Out of space*n")
    abort(999)
    RESULTIS 0
  }
  spacep := p
  RESULTIS p
}

LET initspace(nodes, pairs) BE
{ LET upb = nodes*NodeSize + pairs*(4+2)
  spacev := getvec(upb)
  spacet := spacev+upb
  spacep := spacet
  mk2list := 0
  vertex := getvec(nodes)
  UNLESS spacev & vertex DO
  { writef("Not enough space*n")
    abort(999)
    RETURN
  }
  FOR i = 0 TO upb   DO spacev!i := 0
  FOR i = 0 TO nodes DO vertex!i := 0
}

LET freespace() BE
{ freevec(spacev)
  freevec(vertex)
}

LET mkNode() = VALOF
{ LET p = newvec(NodeUpb)
  UNLESS p DO { writef("Out of space*n"); abort(999) }
  FOR i = 0 TO NodeUpb DO p!i := 0
//writef("mkNode: returning %n*n", p)
  RESULTIS p
}

AND mkpair(next, v, w) = VALOF
{ LET p = newvec(3)
  UNLESS p DO { writef("Out of space*n"); abort(999) }
  !p, p!1, p!2, p!3 := next, v, w, 0
//writef("mkpair: %i2 -> %i2*n", Id!v, Id!w)
  RESULTIS p
}

AND mk2(x, y) = VALOF
{ LET p = mk2list
  TEST p THEN mk2list := !p
         ELSE p := newvec(1)
  !p, p!1 := x, y
  RESULTIS p
}

AND freelist(p) BE
{ LET rest = mk2list
  mk2list := p
  WHILE !p DO p := !p
  !p := rest
}

LET lca(r) BE
{ FOR i = nodes TO 1 BY -1 DO
  { LET v = vertex!i
    LET p = Pairs!v
    WHILE p DO { LET q = p!1
                 LET w = q!2    // Id!v < Id!w
                 q!3 := eval(w) // Compute the lca
                 p := !p
               }
    UNLESS i=1 DO link(Parent!v, v)
  }
}

// Version of eval and link using no compression

AND eval1(v) = VALOF
{ WHILE Ancestor!v DO v := Ancestor!v
  RESULTIS v
}
  
AND link1(v, w) BE Ancestor!w := v

// Version of eval and link using compression

AND compress2(v) BE
{ LET a = Ancestor!v
  IF Ancestor!a DO
  { compress2(a)
    Ancestor!v := Ancestor!a
  }
}

AND eval2(v) = VALOF
{ UNLESS Ancestor!v RESULTIS v // Return v if it is the root
  compress2(v)
  RESULTIS Ancestor!v
}

AND link2(v, w) BE Ancestor!w := v

// Version of eval and link using compression and balancing

AND compress3(v) BE
{ LET a = Ancestor!v
  IF Ancestor!a DO
  { compress3(a)
    Ancestor!v := Ancestor!a
  }
//  prstruct()
}

// Sophisticated eval and link using compression and balancing
AND eval3(v) = VALOF
{ UNLESS Ancestor!v RESULTIS Best!v // Return v if it is the root
  compress3(v)
  RESULTIS Best!(Ancestor!v)
}

AND link3(v, w) BE
{ LET min = ?

  // Change v and w to the roots of their respective trees
  IF Ancestor!w DO { compress3(w); w := Ancestor!w }
  IF Ancestor!v DO { compress3(v); v := Ancestor!v }

  min := Id!(Best!v) < Id!(Best!w) -> Best!v, Best!w

  // Make the root of the larger tree the root of the combined tree
  TEST Size!v >= Size!w
  THEN { Ancestor!w := v; Size!v, Best!v := Size!v + Size!w, min }
  ELSE { Ancestor!v := w; Size!w, Best!w := Size!w + Size!v, min }
}


AND start() = VALOF
{ LET argv = VEC 50
  LET seed = setseed(12345)
  LET n, p = 0, 0
  setseed(seed)
  randno(100)

  stdout := output()
  tostream := stdout
  
  UNLESS rdargs("NODES,PAIRS,SEED,D1/S,D2/S,TO/K", argv, 50) DO
  { writef("Bad arguments for lca*n")
    RESULTIS 20
  }

  debug := 0
  IF argv!0 DO n     := str2numb(argv!0)
  IF argv!1 DO p     := str2numb(argv!1)
  IF argv!2 DO seed  := str2numb(argv!2)
  IF argv!3 DO debug := debug+1
  IF argv!4 DO debug := debug+2
  IF argv!5 DO
  { tostream := findoutput(argv!5)
    UNLESS tostream DO
    { writef("trouble with stream %s*n", argv!5)
      RESULTIS 20
    }
  }

  IF p=0 DO p := n*50

  selectoutput(tostream)

  try(1, n, p, seed)
  try(2, n, p, seed)
  try(3, n, p, seed)

fin:
  IF tostream & tostream ~= stdout DO
  { endwrite()
    selectoutput(stdout)
  }

  RESULTIS 0
}

AND try(t, n, p, seed) BE
{ LET mess = ?

  setseed(seed)
  nodes, pairs := n, p

  IF nodes=0 DO nodes, pairs := 13, 10

  SWITCHON t INTO
  { DEFAULT:
    CASE 1: // version with no compression
            eval, link := eval1, link1
            mess :=  "no compression"
            ENDCASE
    CASE 2: // version with compression
            eval, link := eval2, link2
            mess :=  "compression"
            ENDCASE
    CASE 3: // version with compression and balancing
            eval, link := eval3, link3
            mess :=  "compression and balancing"
            ENDCASE
  }

  newline()
  writef("Compute the lca for %n pairs for a random tree with %n nodes*n",
          pairs, nodes)
  writef("using %s*n", mess)

  initspace(nodes, pairs)

  previd := 0
  root := mktree(nodes)
  mkpairs(nodes, pairs)
//prstruct()

  writef("Instruction count = %n*n", instrcount(lca, root))

  IF debug DO prlca()
  writef("Tree hash: %n  Result hash: %n*n",
                     hashtree(),      hashresult())

  freespace()
}

AND mktree(n) = n<=0 -> 0, VALOF
{ // Make a random tree with given number of nodes
  LET v = mkNode() // Make a root node
  previd := previd+1
  vertex!previd := v      // vertex holds nodes in discovery time order
  Id!v          := previd // Set to the discovery time of this node
  Parent!v      := 0
  Best!v        := v      // Node with smallest Id in same set as v
  Ancestor!v    := 0      // (using the UNION-FIND structure)
  Size!v        := 1

  IF n>1 DO
  { // k = the number of nodes in the left branch of the random tree
    //LET k = 0 
    //LET k = 1 
    LET k = n/10 
    //LET k = n/3
    //LET k = n/2
    //LET k = randno(n-1)
    LET c = mktree(k)     // Make the left tree
    IF c DO Parent!c := v
    c := mktree(n-k-1)    // Make the right tree
    IF c DO Parent!c := v
  }
  RESULTIS v
}

AND mkpairs(nodes, pairs) BE
{ pairlist := 0

  FOR i = 1 TO pairs DO
  { { LET v = vertex!randno(nodes)
      LET w = vertex!randno(nodes)
      LET p = ?
      IF v=w LOOP
      IF Id!v>Id!w DO { LET t=w; w:=v; v:=t }
      p := Pairs!v
      WHILE p DO
      { IF w=p!2 BREAK // pair already present
        p := !p
      }
      IF p LOOP // Pair (v,w) no good

      pairlist := mkpair(pairlist, v, w)
      Pairs!v  := mk2(Pairs!v, pairlist)
      BREAK
    } REPEAT
  }

  IF debug DO prlca()
}

AND prnodes() BE
{ newline()
  FOR i = 1 TO nodes DO
  { LET p = vertex!i
    writef("%i4:",                   Id!p)
    writef(" P:%i4", Parent!p     -> Id!(Parent!p),     0)
    writef(" A:%i4", Ancestor!p   -> Id!(Ancestor!p),   0)
    writef(" B:%i4", Best!p       -> Id!(Best!p),       0)
    newline()
  }
}

AND prres(n) BE
{ newline()
  FOR i = 1 TO n DO
  { LET p = vertex!i
    writef("%i4:", Id!p)
    writef(" A:%i4", Ancestor!p   -> Id!(Ancestor!p),   0)
    writef(" B:%i4", Best!p       -> Id!(Best!p),       0)
    newline()
  }
}

AND prstruct() BE
{ writef("*nI: ")
  FOR i = 1 TO nodes DO writef(" %i2", Id!(vertex!i))
  writef("*nP: ")
  FOR i = 1 TO nodes DO { LET v = Parent!(vertex!i)
                          writef(" %i2", v -> Id!v, 0)
                        }
  writef("*nB: ")
  FOR i = 1 TO nodes DO writef(" %i2", Id!(Best!(vertex!i)))
  writef("*nS: ")
  FOR i = 1 TO nodes DO { LET v = vertex!i
                          writef(" %i2", Size!v)
                        }
  writef("*nA: ")
  FOR i = 1 TO nodes DO { LET v = Ancestor!(vertex!i)
                          writef(" %i2", v -> Id!v, 0)
                        }
  newline()
}

AND hashtree() = VALOF
{ LET res = 34567
  FOR i = 2 TO nodes DO
  { LET p = vertex!i
    res := 31*res + Id!(Parent!p)
  }
  RESULTIS (res>>1) REM 1000000
}

AND hashresult() = VALOF
{ LET res = 34567
  LET p = pairlist
  WHILE p DO { res := 13*res + Id!(p!3); p := !p }
  RESULTIS (res>>1) REM 1000000
}

AND prlca() BE
{ LET p = pairlist
  writef("Least Common Ancestors*n")
  WHILE p DO
  { writef(" %i2-%i2:%i2*n",
             Id!(p!1), Id!(p!2), p!3 -> Id!(p!3), 0)
    p := !p
  }
}