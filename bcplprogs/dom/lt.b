/* 
This is a simple implementation of the Lengauer-Tarjan algorithm
for computing the dominator tree of a flowgraph.

This implementation compares the efficiency of three different
implementations of eval and link.

Ref:
Lengauer,T. and Tarjan R.E.
A Fast Algorithm for Finding Dominators in a Flowgraph.
ACM Trans on Programming Languages and Systems, Vol 1, No. 1, July 1979.

Also influenced by
Muchnick, S.S.
Advanced Compiler Design Implementation
Morgan Kaufmann Publishers, 1997

Implemented in BCPL by Martin Richards (c) April 2001

The sophisticated algorithm is better than the O(n log n) one, provided
the graph is large enough and has at least about 3 times as many edges as
vertices. Try the calls:

Call                              Instruction Counts
    Nodes   Edges Seed     v.simple     simple   sophisticated

lt   1000    1500   1       311671      285439       328346
lt   1000    2000   1       543460      333994       369395
lt   1000    2500   1      1568707      398925       404413
lt   1000    3000   1      3357486      473709       434642
lt   1000    5000   1      7942067      675828       570509
lt   1000   10000   1     18072476     1131823       905586
lt  10000   50000   1    475843115     7083489      5736513
lt  10000  100000   1   1353711323    11785784      9103018
lt 100000  400000   1            -    60774694     51198153

lt 100000  123289   1 f          -    26591295     33179341

For the last few I entered the interpreter by:

       cintsys -m 200000

and obeyed the command:

       stack 200000
*/

GET "libhdr"

MANIFEST {

// Structure of a node
Id=0     // DFS discovery time -- used as id in the algorithm
Parent   // DFS tree parent
Dom      // Immediate dominator
Semi     // Semi dominator
Ancestor // Set in link and used in eval
Best     // The node in the ancestor tree with min sdom
Succ     // List of successors
Pred     // List of predecessors
Bucket   // List of nodes whose semidominators are this node
Size
Child
NodeSize
NodeUpb=NodeSize-1
}

GLOBAL {
vertex:ug       // Vector of nodes in dfs order

root            // Root of the flow graph
nodes           // Number of nodes in the graph
edges           // Number of edges in the graph

newvec; initspace; freespace; mkNode; mk2; freelist
dfs
eval; link
dominators      // set the dom field of each node to
                // its immediate dominator
edge            // add an edge when building a graph
mkdefaultgraph1 // make the default graph as in the paper
mkdefaultgraph2 // make the default graph as in the paper
mkgraph         // make a random flow graph
prnodes
prstruct
hashgraph
hashtree
prevhash

spacev; spacep; spacet  // Pointers in the free space
mk2list                 // free list of mk2 nodes
debug                   // debug flag
flow                    // flow flag
loadp
clab; blab; glab
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

LET initspace(nodes, edges) BE
{ LET upb = nodes*(NodeSize + 2) + edges*5 + 2
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
  nodes := nodes+1
  Id!p := nodes
  vertex!nodes := p
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

LET dfs(v) BE  // DFS on previously unseen vertex v
{ LET p = Succ!v
  nodes := nodes+1
  vertex!nodes := v      // vertex holds nodes in discovery time order
  Id!v         := nodes  // Set the discovery time of this node
  Semi!v       := v      // Initialise semi
  Best!v       := v      //            best
  Ancestor!v   := 0      // and        ancestor
  Child!v      := 0
  Size!v       := 1

  WHILE p DO         // Apply DFS to all unseen successors
  { LET w = p!1      // w = a successor
    p := !p
    UNLESS Semi!w DO
    { Parent!w := v  // Put edge into the DFS spanning tree
      dfs(w)
    }
    Pred!w := mk2(Pred!w, v) // Add v to list of predecessors
    edges := edges+1
  }
}

// The very simple version of eval and link

AND eval1(v) = VALOF
{ LET a = Ancestor!v
//writef("eval1: v=%n a=%n*n", v, a)
  UNLESS a RESULTIS v
  WHILE Ancestor!a DO
  { IF Id!(Semi!v) > Id!(Semi!a) DO v := a
    a := Ancestor!a
  }
  RESULTIS v
}
  
AND link1(v, w) BE
{ IF debug DO writef("link1: %n --> %n*n", Id!v, Id!w)
  Ancestor!w := v
}

// The Simple version of compress, eval and link
// using compression but no balancing
AND compress2(v) BE
{ LET a = Ancestor!v
  UNLESS Ancestor!a RETURN
  compress2(a)
  IF Id!(Semi!(Best!a)) < Id!(Semi!(Best!v)) DO Best!v := Best!a
  Ancestor!v := Ancestor!a
}

AND eval2(v) = VALOF
{ IF Ancestor!v DO compress2(v)
  RESULTIS Best!v
}

AND link2(v, w) BE
{ IF debug DO writef("link2: %n --> %n*n", Id!v, Id!w)
  Ancestor!w := v
}

// The Sophisticated version of compress, eval and link
// using compression and balancing

AND compress3(v) BE
{ LET a = Ancestor!v
  UNLESS Ancestor!a RETURN
  compress3(a)
  IF Id!(Semi!(Best!a)) < Id!(Semi!(Best!v)) DO Best!v := Best!a
  Ancestor!v := Ancestor!a
}

AND eval3(v) = VALOF
{ LET a, b = ?, ?
  UNLESS Ancestor!v RESULTIS Best!v
  compress3(v)
  a, b := Best!(Ancestor!v), Best!v
  RESULTIS Id!(Semi!a) < Id!(Semi!b) -> a, b
}

AND link3(v, w) BE
{ LET s = ?
  LET c = Child!w

  IF debug DO writef("link3: %n --> %n*n", Id!v, Id!w)

  IF c & Id!(Semi!(Best!w)) < Id!(Semi!(Best!c)) DO
  { // Vertex w was processed just before this call link(v, w). 
    // Id!(Semi!w) may be smaller than the last time link was called.
    // This affect the validity of the child chain. This is corrected
    // by the following WHILE loop.

    WHILE c & Child!c & Id!(Semi!(Best!w)) < Id!(Semi!(Best!(Child!c))) DO
    { // Combine c and cc to form new child of w
      LET cc  = Child!c           // cc = child(r1)
      LET ccc = Child!cc          // cc = child(child(r1))

      LET sc = Size!c             // sc   = size(r1)
      LET scc = Size!cc           // scc  = size(child(r1)
      LET sccc = 0
      IF ccc DO sccc := Size!ccc  // sccc = size(child(child(r1))

      TEST sc - scc >= scc - sccc // Compare the subtree sizes
      THEN { Ancestor!cc := c;  Child!c := ccc }
      ELSE { Ancestor!c := cc;  Child!w := cc; Size!cc := sc; c := cc }
    }
    Best!c := Best!w
  }

  s := w
  IF Size!v < Size!w DO { LET t = s; s := Child!v; Child!v := t }
  Size!v := Size!v + Size!w
  WHILE s DO { Ancestor!s := v; s := Child!s }
  IF debug DO prforest()
}

AND dominators(r) BE
{ 
// Step1:
  nodes, edges := 0, 0
  dfs(r)
  writef("nodes = %n  edges = %n*n", nodes, edges)

  IF debug DO
  { writef("Nodes after step1*n")
    prnodes(nodes)
  }

  FOR i = nodes TO 2 BY -1 DO
  { LET w = vertex!i
    LET p = Pred!w         // p is the list of predecessors
    LET q = ?

// step2:
//writef("step2 i=%n p=%n*n", i, p)
//abort(1000)

    WHILE p DO
    { LET v = p!1          // For each predecessor v
      LET u = eval(v)
      IF debug DO
        writef("Step 2:  node %i4  eval(%i4)=%i4*n", Id!w, Id!v, Id!u)
      IF Id!(Semi!u) < Id!(Semi!w) DO Semi!w := Semi!u
      p := !p             // look for next predecessor
    }
    // Add w to the Bucket of Semi(w) ready for step 3
    Bucket!(Semi!w) := mk2(Bucket!(Semi!w), w)

    p := Parent!w
    link(p, w)           // add edge (p,w) to the forest

// Step3:

    q := Bucket!p

    WHILE q DO
    { LET v = q!1 // for each v in bucket(parent(w))
      LET u = eval(v)
      Dom!v := Id!(Semi!u) < Id!(Semi!v) -> u, p
      IF debug DO writef("Step 3: set Dom(%i4) to %i4*n",
                                          Id!v,   Id!(Dom!v))
      q := !q
    }
    IF Bucket!p DO { freelist(Bucket!p); Bucket!p := 0 }
  }

  IF debug DO
  { writes("*nNodes after step 3:*n")
    prnodes(nodes)
  }

// Step4:

  FOR i = 2 TO nodes DO  // Do step 4 -- nodes in dfs order
  { LET w = vertex!i
    UNLESS Dom!w = Semi!w DO
    { IF debug DO writef("Step 4: change Dom(%i4) from %i4 to %i4*n",
                                     Id!w, Id!(Dom!w), Id!(Dom!(Dom!w)))
      Dom!w := Dom!(Dom!w)
    }
  }
  Dom!(vertex!1) := 0

  IF debug DO { writes("*nStep 4: Final result*n"); prres(nodes) }
}

AND start() = VALOF
{ LET argv = VEC 50
  LET seed = setseed(12345)  // get previous seed
  LET n, e = 0, 0

  stdout := output()
  tostream := stdout
  
  UNLESS rdargs("NODES,EDGES,SEED,TO/K,D=DEBUG/S,F=FLOW/S", argv, 50) DO
  { writef("Bad arguments for lt*n")
    RESULTIS 20
  }

  debug := FALSE
  IF argv!0 DO n     := str2numb(argv!0)    // NODES
  IF argv!1 DO e     := str2numb(argv!1)    // EDGES
  IF argv!2 DO seed  := str2numb(argv!2)    // SEED
  IF argv!3 DO
  { tostream := findoutput(argv!3)          // TO
    UNLESS tostream DO
    { writef("trouble with stream %s*n", argv!3)
      RESULTIS 20
    }
  }
  debug := argv!4                           // DEBUG
  flow  := argv!5                           // FLOW

  IF e < n-1 DO e := n-1

  selectoutput(tostream)

  check(0)             // Inititalise prevhash
  IF n<=10000 DO try(1, n, e, seed, flow)
  try(2, n, e, seed, flow)
  try(3, n, e, seed, flow)

fin:
  IF tostream & tostream ~= stdout DO
  { endwrite()
    selectoutput(stdout)
  }

  RESULTIS 0
}

AND try(t, n, e, seed, f) BE
{ LET mess = ?

  LET newgraph = n=0 -> mkdefaultgraph1,
                 n=1 -> mkdefaultgraph2,
                 mkgraph

  IF f DO newgraph := mkflow

  setseed(seed)

  SWITCHON t INTO
  { DEFAULT:
    CASE 1: // Very simple version
            eval, link := eval1, link1
            mess :=  "very simple"
            ENDCASE
    CASE 2: // Simple version
            eval, link := eval2, link2
            mess :=  "simple"
            ENDCASE
    CASE 3: // Very simple version
            eval, link := eval3, link3
            mess :=  "sophisticated"
            ENDCASE
  }

  newline()

  root := newgraph(n, e)

  writef("Finding dominator tree*n")
  writef("using %s version of eval*n", mess)

  writef("*n*nInstruction count = %n*n",
           instrcount(dominators, root))

  FOR i = 1 TO 4 DO // Print a few immediate dominators
  { LET w = 2*nodes/3 + i
    IF w > nodes BREAK
    writef("Dom!%n = %n*n", w, Id!(Dom!(vertex!w)))
  }

  { LET h1, h2 = hashgraph(), hashtree()
    writef("Graph hash: %n  Dominator Tree hash: %n*n", h1, h2)
    check(h1+h2) // Check that the hash values are the same as before
  }

  freespace()
}

AND edge(i, j) BE
{ LET vi, vj = vertex!i, vertex!j
  Succ!vi := mk2(Succ!vi, vj)
  edges := edges+1
}

AND mkdefaultgraph1() = VALOF
{ // Make the graph used in the paper
  initspace(13, 21)
  nodes, edges := 0, 0
  FOR i = 1 TO 13 DO mkNode(i)

  edge( 1, 11); edge( 1,  8); edge( 1,  2)
  edge( 2,  6); edge( 2,  3)
  edge( 3,  4)
  edge( 4,  5)
  edge( 5,  4); edge( 5,  1)
  edge( 6,  4); edge( 6,  7)
  edge( 7,  4)
  edge( 8, 12); edge( 8, 11); edge( 8,  9)
  edge( 9, 10)
  edge(10,  9); edge(10,  5)
  edge(11, 12)
  edge(12, 13)
  edge(13, 10)

  RESULTIS vertex!1
}

AND mkdefaultgraph2() = VALOF
{ // Make the graph used in my talk
  initspace(25, 38)
  nodes, edges := 0, 0
  FOR i = 1 TO 25 DO mkNode(i)

  edge( 1, 14); edge( 1,  2)
  edge( 2, 21); edge( 2,  3)
  edge( 3, 18); edge( 3, 11); edge( 3,  4)
  edge( 4,  5)
  edge( 5,  9); edge( 5,  6)
  edge( 6,  7)
  edge( 7,  1); edge( 7,  8)
  edge( 8,  6)
  edge( 9, 10); edge( 9,  7)
  edge(10,  7)
  edge(11, 15); edge(11, 14); edge(11, 12)
  edge(12, 13); edge(12,  9)
  edge(14, 15)
  edge(15, 16)
  edge(16, 17)
  edge(17, 15); edge(17,  8)
  edge(18, 24); edge(18, 21); edge(18, 19)
  edge(19, 20); edge(19, 15)
  edge(21, 24); edge(21, 22); edge(21, 20)
  edge(22, 23)
  edge(23, 16)
  edge(24, 25)

  RESULTIS vertex!1
}

AND mktree1(n) = n<=0 -> 0, VALOF
{ // Make a random tree with given number of nodes
  LET v = mkNode() // Make a root node

  IF n>1 DO
  { // k = the number of nodes in the left branch of the random tree
    //LET k = 0 
    //LET k = 1 
    LET k = n/10 
    //LET k = n/3
    //LET k = n/2
    //LET k = randno(n-1)
    LET c = mktree1(k)     // Make the left tree
    IF c DO edge(v, c)
    c := mktree1(n-k-1)    // Make the right tree
    IF c DO edge(v, c)
  }
  RESULTIS v
}

AND mktree2(n) = VALOF
{ // Make a random tree with a given number of nodes
  vertex!1 := 0
  FOR i = 1 TO n DO
  { mkNode()
    IF i>1 DO edge(randno(i-1), i) // give node i a random parent
  }
  RESULTIS vertex!1
}

AND mkgraph(n, e) = VALOF
{ // Make a random flow graph
  initspace(n, e)

  nodes, edges := 0, 0
  mktree2(n)           // First create a tree

  // Then add some additional random edges
  UNTIL edges>=e DO
  { LET p = randno(n)
    LET q = p + randno(200) - 100
    UNLESS 1<=q<=n LOOP
    edge(p, q)  // Add edge to nearby node
  }

  RESULTIS vertex!1  // return the root
}

AND mkflow(n) = VALOF
{ // Make a random flow graph (program like) with exactly n nodes
  initspace(n, 2*n)

  vertex!1 := 0
  // First make the nodes
  nodes, edges := 0, 0
  FOR i = 1 TO n DO mkNode()
  clab, blab, glab := 0, 0, 0 // continue, break and goto labels
  loadp := 1   // Position of next instruction to compile
  trnC(n-1)    // Compile C; return in n-1 nodes
  genj("stop")
  RESULTIS vertex!1  // return the root
}

AND trnC(n) BE
// Compiler n nodes of code
{ LET m = ?
  LET r = randno(100)

  IF n<=0 DO abort(1000)

  IF n=1 DO
  { IF prob(5) & clab DO
    { genfl("continue", clab)          //     continue  Lclab 
      RETURN
    }
    IF prob(5) & blab DO               //     break  Lblab
    { genfl("break", blab)
      RETURN
    }
    IF prob(5) & glab DO
    { genfl("goto", glab)              //     goto  Lglab 
      RETURN
    }
    genf("com")                        //     com
    RETURN
  }

  IF r<25 & n>5 DO // if E then C
                   // => E; jf l1; C; lab l1
  { LET g = glab
    LET L1 = loadp+n-1
    IF prob(10) DO
       glab := loadp + randno(n) - 1
    genf("exp")                         //     E
    genfl("jf", L1)                     //     jf  L1 
    trnC(n-3)                           //     C
    genf("lab")                         // L1:
    glab := g
    RETURN
  }

  IF r<35 & n>7 DO // if E then C else C
                   // => E; jf l; C; jump m; lab l; C; lab m
  { LET g = glab
    LET m = randno(n-6)  // size of C1  1 <= m <= n-6
    LET L1 = loadp + m + 3
    LET L2 = loadp + n - 1
    IF prob(10) DO
      glab := loadp + randno(n) - 1
    genf("exp")                         //     E
    genfl("jf", L1)                     //     jf  L1
    trnC(m)                             //     C
    genjl("jmp", L2)                    //     jmp L2
    genf("lab")                         // L1:
    trnC(n-m-5)                         //     C
    genf("lab")                         // L2:
    glab := g
    RETURN
  }

  IF r<55 & n>8 DO // while E do C
  { LET c, b, g = clab, blab, glab
    LET L1 = loadp + 1
    clab  := loadp + n - 4
    blab  := loadp + n - 1
    IF prob(10) DO  // possibly change goto target
       glab := loadp + randno(n) - 1
    genjl("jmp", clab)                  //        jmp Lclab
    genf("lab")                         // L1:
    trnC(n-6)                           //        C
    genf("lab")                         // Lclab:
    genf("exp")                         //        E
    genfl("jt", L1)                     //        jt  L1
    genf("lab")                         // Lblab:
    clab, blab, glab := c, b, g
    RETURN
  }


  IF r<75 & 10<n<1000 DO // switch E { C1;..;Ck }
  { LET s = loadp    // Position of switch instruction
    LET elab = loadp + n - 1
    genj("switch")
    n := n-1

    UNTIL n<=1 DO
    { LET m = randno(100) + 4   // Choose a case size
      IF m+5>n DO m := n-1      // make this the last case
      edge(s, loadp)            // Compile next case from p to m
      genf("caselab")
      trnC(m-2)
      genjl("endcase", elab)
      n := n-m
    }
    edge(s, loadp)
    genf("endswitch")
    RETURN
  }

  // Otherwise compile:  C1; C2
  m := randno(n-1) // size of C1
  trnC(m)                                //      C1
  trnC(n-m)                              //      C2
}  

AND genf(str) BE
{ IF debug DO
     writef("%i3: %s*n", loadp, str)
  edge(loadp, loadp+1)
  loadp := loadp+1
}

AND genfl(str, lab) BE
{ IF debug DO
     writef("%i3: %t8 %n*n", loadp, str, lab)
  edge(loadp, lab)
  edge(loadp, loadp+1)
  loadp := loadp+1
}

AND genj(str) BE
{ IF debug DO
     writef("%i3: %s*n", loadp, str)
  loadp := loadp+1
}

AND genjl(str, lab) BE
{ IF debug DO
     writef("%i3: %t8 %n*n", loadp, str, lab)
  edge(loadp, lab)
  loadp := loadp+1
}

AND prob(percent) = randno(100)<=percent

AND prnodes(n) BE
{ newline()
  FOR i = 1 TO n DO
  { LET p = vertex!i
    LET q = Succ!p
    writef("%i4:",                 Id!p)
    writef(" P:%i4", Parent!p   -> Id!(Parent!p),   0)
    writef(" D:%i4", Dom!p      -> Id!(Dom!p),      0)
    writef(" S:%i4", Semi!p     -> Id!(Semi!p),     0)
    writef(" A:%i4", Ancestor!p -> Id!(Ancestor!p), 0)
    writef(" L:%i4", Best!p     -> Id!(Best!p),    0)
    writef(" -> ")
    WHILE q DO { writef(" %i4", Id!(q!1)); q := !q }
    newline()
  }
}

AND prres(n) BE
{ newline()
  FOR i = 1 TO n DO
  { LET p = vertex!i
    LET q = Succ!p
    writef("%i4:", Id!p)
    writef(" P:%i4", Parent!p   -> Id!(Parent!p),   0)
    writef(" D:%i4", Dom!p      -> Id!(Dom!p),      0)
    writef(" S:%i4", Semi!p     -> Id!(Semi!p),     0)
    writef(" ->")
    WHILE q DO { writef(" %i4", Id!(q!1)); q := !q }
    newline()
  }
}

AND prstruct() BE
{ writef("*nN: ")
  FOR i = 1 TO nodes DO writef(" %i2", i)
  writef("*nS: ")
  FOR i = 1 TO nodes DO { LET v = Semi!(vertex!i)
                          writef(" %i2", Id!v)
                        }
  writef("*nB: ")
  FOR i = 1 TO nodes DO { LET v = Best!(vertex!i)
                          writef(" %i2", v -> Id!v, 0)
                        }
  writef("*nZ: ")
  FOR i = 1 TO nodes DO { LET v = vertex!i
                          writef(" %i2", Size!v)
                        }
  writef("*nA: ")
  FOR i = 1 TO nodes DO { LET v = Ancestor!(vertex!i)
                          writef(" %i2", v -> Id!v, 0)
                        }
  writef("*nC: ")
  FOR i = 1 TO nodes DO { LET v = Child!(vertex!i)
                          writef(" %i2", v -> Id!v, 0)
                        }
  newline()
}

AND prforest() BE
{ FOR i = 1 TO nodes DO
  { LET v = vertex!i
    IF Size!v>1 & Ancestor!v=0 DO
    { IF Child!v & Id!(Child!v)<i DO abort(9999)
      prvtree(v)
      writes("*n*n")
    } 
  }
  FOR i = 1 TO nodes DO
  { LET v = vertex!i
    Size!v := ABS(Size!v) // Restore original size
  }
}

AND prvtree(t) BE
{ prstree(t)        // Print subtree
  Size!t := -Size!t // Mark this subtree as printed
  t := Child!t
  UNLESS t RETURN
  writes("=>*n")
} REPEAT

AND prstree(t) BE
{ LET id = Id!t
  LET first = TRUE
  writef("%n:%n", id, Id!(Semi!t), Id!(Best!t))

  FOR i = 1 TO nodes DO // Find any sub branches
  { LET vi = vertex!i
    IF t=Ancestor!vi DO
    { wrch(first -> '(', ' ')
      first := FALSE
      prstree(vi)
    }
  }
  UNLESS first DO wrch(')')
}

AND hashgraph() = VALOF
{ LET res = 34567
  FOR i = 1 TO nodes DO
  { LET p = vertex!i
    LET q = Succ!p
    res := 31*res + Id!p
    WHILE q DO { res := res*13 + Id!(q!1); q := !q }
  }
  RESULTIS (res>>1) REM 1000000
}

AND hashtree() = VALOF
{ LET res = 34567
  FOR i = 2 TO nodes DO
  { LET p = vertex!i
    res := 31*res + Id!p
    res := 13*res + Id!(Dom!p)
  }
  RESULTIS (res>>1) REM 1000000
}

AND check(hash) BE
{ IF prevhash & hash & prevhash~=hash DO
     writef("ERROR: dominator tree different*n")
  prevhash := hash
} 
