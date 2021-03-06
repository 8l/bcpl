/*
An Experimental  Tautology Checker

Implemented in BCPL by Martin Richards (c) Novemebr 1999


This is an experimental tautology checker that uses the conjunction of
relations to represent the boolean expression being tested.  In this
implementation the relations are over 3 variables (ternary relations)
and a maximum of 256 different variables are allowed. The variable v0
is permanently false and variable v1 is permanently true. The other
variables, v2 to v255, and can take either value.

A term is represented as a 32 bit pattern:

             x        y        z       rel
          ........ ........ ........ ........


Rel is a bit pattern specifying the setting of variables x, y and z
that are permitted.

x    1 1 1 1 0 0 0 0
y    1 1 0 0 1 1 0 0
z    1 0 1 0 1 0 1 0
     a b c d e f g h
                   h=1 <=> 000 in Rel  ie x=0,y=0,z=0 is allowed
                 g=1 <=> 001 in Rel    ie x=0,y=0,z=1 is allowed
               f=1 <=> 010 in Rel      ie x=0,y=1,z=0 is allowed
             e=1 <=> 011 in Rel        ie x=0,y=1,z=1 is allowed
	   d=1 <=> 100 in Rel          ie x=1,y=0,z=0 is allowed
         c=1 <=> 101 in Rel            ie x=1,y=0,z=1 is allowed
       b=1 <=> 110 in Rel              ie x=1,y=1,z=0 is allowed
     a=1 <=> 111 in Rel                ie x=1,y=1,z=1 is allowed

So the relation:  v7 = (v5 -> v2) could be represented by:

           v7       v5       v2      rel
        00000111 00000101 00000010 10110100  v7v5v2 in {111,101,010,001}

ie.  rel = {111,101,100,010}

which corresponds to:        v7    v5   v2
                             T = ( T -> T )
                             T = ( F -> T )
                             T = ( F -> F )
                             F = ( T -> F )

Any boolean expression can be converted into the conjunction of such terms
which in this implementation consists of a vector of 32 bit terms.  The number
of terms is held in the zeroth element of this vector.

Term Canonicalisation

A term specifies what values its variables may take. Of the different
terms that specify the same constraints it is always possible to find
a unique canonical version. This is done by removing redundant
variables from the term and then reordering the remaining variables.

Simplification

If a variable occurs twice in a term, one of them may be replaced by
zero with an corresponding change in the rel bit pattern. For example:

           v3       v3       v7      Rel
        00000011 00000011 00000111 11010001  v3v3v7 in {111,100,010,001}

Since v3v3v7 cannot be 100 or 010, an equivalent relation is

           v3       v3       v7      Rel
        00000011 00000011 00000111 10000001  v3v3v7 in {111,001}

which can be further simplified to:

           v0        v3       v7      Rel
        00000000 00000011 00000111 00001001  v0v3v7 in {011,001}

remembering that v0 is always false.

If the rel bit pattern places no constraint on a variable, that variable
may be eliminated. So:

           v2        v3       v7      Rel
        00000010 00000011 00000111 10011001  v0v3v7 in {111,101,011,001}

can be replaced by:

           v0        v3       v7      Rel
        00000000 00000011 00000111 00001001  v0v3v7 in {011,001}

Reordering

If two terms have identical canonical forms one of them may be eliminated.

If the canonical form is:   

           v0        v0       v0      Rel
        00000000 00000000 00000000 00000001  v0v0v0 in {000}

it is always satisfied and so can be omitted. If no relations remain
the given boolean expression is always satisfied.

If the canonical form is:   

           v0        v0       v0      Rel
        00000000 00000000 00000000 00000000  v0v0v0 in {}

it can never be satisfied and so the given boolean expression is always
false.



The final stage of canonicalisation is to arrange the variables in
increasing order.  For example, the term:

           v7       v2       v5      rel
        00000111 00000010 00000101 11001010  v7v2v5 in {111,110,100,001}

is replaced by:

           v2       v5       v7      Rel
        00000111 00000010 00000101 11010001  v2v5v7 in {111,101,010,001}



A term containing only one non zero variable may place no constraint on that
variable and so the term can be eliminated, otherwise it will constrain that
variable to hold a certain value. In which case this term is eliminated and all
other terms referring to this variable can be modified appropriately.

Binary Relations

Any term containing just two non zero variables specifies a binary
relation.  Such a term is removed and passed to a separate structure
which can accummulates binary relations efficiently.  This structure
can recognize simple rewriting relations such as a variable being
true, false, or equal to another variable or its complement.  Such
rewriting relations are applied to the whole set of terms as soon as
they are discovered.

The binary relation structure

There are 16 binary relations on two boolean variables, four are
implication relations, one is always true and can be removed, one is
always false and indicates an inconsistency, and the remaining 10 are
rewrite relations such as vi=vj or vi=~vj where j may be zero.
Whenever a rewrite relation is found all occurrences of the larger
numbered variable replaced replaced before any more deductions are
made.

Binary relations are held in two separate structures: a rewrite table
and an implication graph.

The rewrite table is represented by an integer vector rw.

    rw!i =  0 means nothing known about variable i
    rw!i =  1 means vi is true
    rw!i = -1 means vi is false
    rw!i =  j (0<=j<i) means vi =  vj
    rw!i = -j (0<=j<i) means vi = ~vj

The implication graph is a sparse matrix represented by a vector
(impv) of adjacency lists.  The list impv!i contains information about
variable i and all other variables that it is related to. An adjacency
node is a 4-tuples [link, rel, i, j] where link is null or points to
another node, i and j are both greater than 0, and rel is an
implication relation between vi and vj.

Incremental building of the structure

Each binary relation is added to the structure one at a time. If it
is a rewrite relation rewriting is performed immediately, otherwise
it is added to the implication matrix. This may cause a cascade of
other relations to add.  
*/


GET "libhdr"

GLOBAL {
 rw:         200  // Rewrite vector
 impv:       201  // Implication lists
 newRw:      202  // Rewrites to apply to the implication lists
 newRel2:    203  // new relations yet to be processed.
 
 spacev:     210
 spacep:     211
 spacet:     212
 blks:       213  // List of free blocks (4-tuples)
}

MANIFEST {
 Vmax=5000      // Maximum number of variables
 Size=100000    // Size of free store
}

LET initialise() = VALOF
{ 
  rw     := getvec(Vmax)
  impv   := getvec(Vmax)
  spacev := getvec(Size)

  FOR i = 0 TO Vmax DO rw!i, impv!i := 0, 0
  newRw := 0
  newRel2 := 0

  // Initialise the list of free blocks
  spacet := spacev + Size
  spacep := spacet
  blks := 0
  // Form initial free list
  { spacep := spacep - 4
    IF spacep<spacev BREAK
    spacep!0 := blks
    blks := spacep
  } REPEAT
}

AND freespace() BE 
{ freevec(spacev)
  freevec(rw)
  freevec(impv)
}

AND newBlk(link, x, y, z) = VALOF
{ LET p = blks
  UNLESS p DO { writef("No more space*n")
                abort(1000)
                RESULTIS 0
              } 
  blks := !p  // Remove one block from the free list
  p!0, p!1, p!2, p!3 := link, x, y, z
  RESULTIS p
}

AND freeBlk(p) BE
{ p!0 := blks
  blks := p
}

LET prEqs() BE
{ writef("Rewrites: ")
  FOR i = 2 TO 100 IF rw!i DO writef(" %n=%n", i, rw!i)
  newline()
}

LET prrel2(r, i, j) BE SWITCHON r INTO
{ DEFAULT:     writef(" [%b4,%n,%n]", r, i, j); ENDCASE
//  CASE #b1101: writef(" %n>%n",  i,  j);        ENDCASE
//  CASE #b1110: writef(" %n>%n",  i, -j);        ENDCASE
//  CASE #b0111: writef(" %n>%n", -i,  j);        ENDCASE
//  CASE #b1011: writef(" %n>%n", -i, -j);        ENDCASE
}

LET prImps() BE
{ writef("Implications:*n")
  FOR i = 2 TO 100 DO
  { LET r = impv!i
    IF r DO
    { WHILE r DO { prrel2(r!1, r!2, r!3); r := !r }
      newline()
    }
  }
}

LET prnewRel2() BE
{ LET p = newRel2
  writef("newRel2:*n")
  WHILE p DO { prrel2(p!1, p!2, p!3); p := !p }
  newline()
}

LET prnewRws() BE
{ LET p = newRw
  writef("newRw:")
  WHILE p DO { writef(" %n", p!1); p := !p }
  newline()
}

LET replacement(i) = -1<=i<=1 -> i,  // Replacement is True or False
                     VALOF TEST i>0
  THEN { LET r = rw!i
         IF  r=0 RESULTIS i          // Nothing known about Vi
         r := replacement(r)
         UNLESS rw!i=r DO { rw!i := r; setEq(i, r) }
         RESULTIS r
       }
  ELSE { LET pi = -i
         LET r = -rw!pi
         IF r=0 RESULTIS i           // Nothing known about Vi
         r := replacement(r)
         UNLESS rw!pi=-r DO { rw!pi := -r; setEq(pi, -r) }
         RESULTIS r
       }

AND inconsistent() BE
{ writef("Inconsistent*n")
  prEqs()
  prImps()
  prnewRws()
  prnewRel2()
  writef("Aborting in inconsistent:")
  abort(1234)
}

AND setEq(i, j) BE // This is called whenever rw!i is changed
// i > ABS(j) > 0
// Store i in list of variables to rewrite (newRw)
// These will be looked at later by doClosure
{ LET p = @newRw
  LET q = !p
//  writef("setEq: %i4 %i4*n", i, j)
  // Find, in the sorted list, where to put i
  WHILE q & q!1<i DO { p := q; q := !p }
  IF q & q!1=i RETURN  // i already there so return
  // Insert at this point
  !p := newBlk(q, i)
//  prnewRws()
} 

AND addEq(i, j) BE
{ // Preconditions: i, j ~= 0 
  LET ri = replacement(i)
  LET rj = replacement(j)
  LET pri = ABS(ri)
  LET prj = ABS(rj)
  writef("addEq: i=%n j=%n ri=%n rj=%n*n", i, j, ri, rj)
  IF ri=rj RETURN // both false, true or both equal
  IF pri=prj DO { inconsistent(); RETURN }

  TEST pri>prj
  THEN { rw!pri := ri>0 -> rj, -rj; setEq(pri, rw!pri) }
  ELSE { rw!prj := rj>0 -> ri, -ri; setEq(prj, rw!prj) }

//  prEqs()
}

// [r, x, y] is equivalent to [negx(r), -x, y]
AND negx(r) = r!TABLE #b0000, #b0100, #b1000, #b1100,
                      #b0001, #b0101, #b1001, #b1101,
                      #b0010, #b0110, #b1010, #b1110,
                      #b0011, #b0111, #b1011, #b1111

AND chkNegx() BE
{ writef("Checking negx*n")
  FOR r = 0 TO 15 FOR x = 0 TO 1 FOR y = 0 TO 1 DO
   UNLESS evalRel(r, x, y)=evalRel(negx(r), 1-x, y) DO
     writef("Bug [%b4 %n %n] ~= [%b4 %n %n]*n",
                   r, x, y,   negx(r), 1-x, y)
  writef("Done*n")
}

// [r, x, y] is equivalent to [negy(r), x, -y]
AND negy(r) = r!TABLE #b0000, #b0010, #b0001, #b0011,
                      #b1000, #b1010, #b1001, #b1011,
                      #b0100, #b0110, #b0101, #b0111,
                      #b1100, #b1110, #b1101, #b1111

AND chkNegy() BE
{ writef("Checking negy*n")
  FOR r = 0 TO 15 FOR x = 0 TO 1 FOR y = 0 TO 1 DO
   UNLESS evalRel(r, x, y)=evalRel(negy(r), x, 1-y) DO
     writef("Bug [%b4 %n %n] ~= [%b4 %n %n]*n",
                   r, x, y,   negy(r), x, 1-y)
  writef("Done*n")
}

// [r, x, y] is equivalent to [swap2(r), y, x]
AND swap2(r) = r!TABLE #b0000, #b0001, #b0100, #b0101,
                       #b0010, #b0011, #b0110, #b0111,
                       #b1000, #b1001, #b1100, #b1101,
                       #b1010, #b1011, #b1110, #b1111

AND chkSwap2() BE
{ writef("Checking swap2*n")
  FOR r = 0 TO 15 FOR x = 0 TO 1 FOR y = 0 TO 1 DO
   UNLESS evalRel(r, x, y)=evalRel(swap2(r), y, x) DO
     writef("Bug [%b4 %n %n] ~= [%b4 %n %n]*n",
                   r, x, y,   swap2(r), y, x)
  writef("Done*n")
}

// [r, x, y] and  [s, y, z] implies [comp2(r,s), x, z]
AND comp2(r, s) = VALOF
{ LET spread1 = r!TABLE
       #b00000000,#b00000011,#b00110000,#b00110011,
       #b00001100,#b00001111,#b00111100,#b00111111,
       #b11000000,#b11000011,#b11110000,#b11110011,
       #b11001100,#b11001111,#b11111100,#b11111111
  LET spread2 = s!TABLE
       #b00000000,#b00000101,#b00001010,#b00001111,
       #b01010000,#b01010101,#b01011010,#b01011111,
       #b10100000,#b10100101,#b10101010,#b10101111,
       #b11110000,#b11110101,#b11111010,#b11111111
  LET w = spread1 & spread2
  RESULTIS (w>>4 | w) & #b1111
}

AND chkComp2() BE
{ writef("Checking comp2*n")
  FOR r = 0 TO 15 FOR s = 0 TO 15 
    FOR x = 0 TO 1 FOR z = 0 TO 1 DO
      UNLESS ( evalRel(r,x,0) & evalRel(s,0,z) | 
               evalRel(r,x,1) & evalRel(s,1,z) ) =
             evalRel(comp2(r,s), x, z) DO
                         writef("Bug [%b4 %n y] [%b4 y %n] [%b4 %n %n]*n",
                                      r,   x,    s,    z,  comp2(r,s),x,z)
  writef("Done*n")
}

AND combineImps(r, x, p) BE WHILE !p DO
// Relation [r, x, y] holds and p is a list of relations of the form [s, y, z]
// For each [r, x, y] and [s, y, z] add a new relation [r*s, x, z]
{ newRel2 := newBlk(newRel2, comp2(r, p!1), x, p!3)
  writef("Combining [%b4,%n,%n] and [%b4,%n,%n] gives [%b4,%n,%n]*n",
                     r, x, p!2,      p!1,p!2,p!3,      newRel2!1, x, p!3)
  p := !p
}

AND insertRel2(r, i, j) = VALOF
// This will ensure that [r, i, j] and [r', j, i] are in the impv structure
// (The impv structure is only permitted to hold implications).
// r is an implication relation (0111, 1011, 1101 or 1110)
// i, j are both > 1 
// It returns TRUE if a relation was actually inserted in the impv structure.
// This is the only function that inserts relations into the impv structure.
{ LET res = FALSE
  LET p = @impv!i
  LET q = !p

  writef("insertRel2: %b4 %n %n*n", r, i, j)

//  IF q DO writef("insertRel2: inspecting %b4 %n %n*n", q!1, q!2, q!3)
  WHILE q & j>q!3 DO { p := q; q := !p } // Find place to insert

  TEST q & j=q!3         // Does q -> [s, i, j]?
  THEN UNLESS r=q!1 DO { // The resulting relation is not an implication
                         // so transfer it to the newRel2 list
                         q!1 := r & q!1
writef("insertRel2: transferring %b4 %n %n*n", q!1, q!2, q!3)
                         !p  := !q
                         !q  := newRel2
                         newRel2 := q 
                         prnewRel2()
                       }
  ELSE { !p := newBlk(!p, r, i, j)     // Insert new entry
//         writef("insertRel2: adding %b4 %n %n*n", r, i, j)
//         prImps()
         res := TRUE
       }

  // Now insert [r', j, i] (=[r, i, j])
  p := @impv!j
  q := !p
  r := swap2(r)

//  IF q DO writef("insertRel2: inspecting %b4 %n %n*n", q!1, q!2, q!3)
  WHILE q & i>q!3 DO { p := q; q := !p } // find place to insert

  TEST q & i=q!3         // Does q -> [s, j, i]?
  THEN UNLESS r=q!1 DO { // The resulting relation is not an implication
                         // so transfer it to the newRel2 list
                         q!1 := r & q!1
writef("insertRel2: transferring %b4 %n %n*n", q!1, q!2, q!3)
                         !p  := !q
                         !q  := newRel2
                         newRel2 := q
                         prnewRel2()
                       }
  ELSE { !p := newBlk(!p, r, j, i)     // Insert new entry inserted
//         writef("insertRel2: adding %b4 %n %n*n", r, j, i)
//         prImps()
         res := TRUE
       }

//  writef("Returning from insertRel2 with:*n")
//  prImps()
//  prnewRws()
//  prnewRel2()
//  newline()
  RESULTIS res                // TRUE if a new entry was added
}

AND addRel2(r, i, j) BE
{ writef("Processing [%b4 %i4 %i4]*n", r, i, j)
  i := replacement(i)
  j := replacement(j)
  writef("Same as    [%b4 %i4 %i4]*n", r, i, j)
  IF i<0 DO { r := negx(r); i := -i }
  writef("Same as    [%b4 %i4 %i4]*n", r, i, j)
  IF j<0 DO { r := negy(r); j := -j }
  writef("Same as    [%b4 %i4 %i4]*n", r, i, j)
  IF i=1 DO r := r & #b1100
  IF j=1 DO r := r & #b1010
  IF i=j DO r := r & #b1001
  writef("Same as    [%b4 %i4 %i4]*n", r, i, j)

  SWITCHON r INTO
  { CASE #b0000: inconsistent()
                 RETURN
    CASE #b0001: addEq(i, -1)
                 addEq(j, -1)
                 RETURN
    CASE #b0010: addEq(i, -1)
                 addEq(j,  1)
                 RETURN
    CASE #b0011: addEq(i, -1)
                 RETURN
    CASE #b0100: addEq(i,  1)
                 addEq(j, -1)
                 RETURN
    CASE #b0101: addEq(j, -1)
                 RETURN
    CASE #b0110: addEq(i, -j)
                 RETURN
    CASE #b1000: addEq(i,  1)
                 addEq(j,  1)
                 RETURN
    CASE #b1001: addEq(i,  j)
                 RETURN
    CASE #b1010: addEq(j,  1)
                 RETURN
    CASE #b1100: addEq(i,  1)
                 RETURN

    CASE #b1111: RETURN
  
    CASE #b0111: // The implication operators
    CASE #b1011:
    CASE #b1101:
    CASE #b1110:  // Insert [r, i, j] and [r', j, i]
                  // but if already there do nothing
                 UNLESS insertRel2(r, i, j) RETURN
                 // For each [s,j,k] add [r*s,i,k]
                 combineImps(      r,  i, impv!j)
                 // For each [s,i,k] add [r'*s,j,k]
                 combineImps(swap2(r), j, impv!i)
                 RETURN
  }
}

AND doClosure() BE
{ // Deal with rewrites first
  { LET p = newRw
    LET i, j, pj = ?, ?, ?
    IF p=0 TEST newRel2 THEN BREAK   // Some new relations to deal with
                        ELSE RETURN  // Closure complete
    newRw := !p
    i := p!1              // Variable i has recently been renamed
    freeBlk(p)
    j := replacement(i)
    pj := ABS(j)          // i >= pj > 0
    UNLESS i>=pj>0 DO abort(1001)
    IF i=pj DO { IF j<0 DO inconsistent()
                 LOOP
               }
    // i > pj > 0

    writef("Applying rewrite %n with %n*n", i, j)

    // Remove all relations involving i in every impv list
    // by transferring them to newRel2 which will be processed
    // when newRw is empty.

    // For each [r, i, y], transfer it and [s, y, i] to the newRel2 list
    // to be processed later.
    p := @impv!i
    WHILE !p DO
    { LET q = !p  // q -> [r, i, y]
      LET y = q!3

      // Attempt to transfer [s, y, i] to newRel2
      LET a = @impv!y
      LET b = !a
      WHILE b & i>b!3 DO { a := b; b := !a }
      IF b & i=b!3 DO { // Relation [s, y, i] found so remove it.
                        !a := !b
                        freeBlk(b)
                      }
      p := q
    }
    // Transfer all relations [r, i, y] to the newRel2 by prefixing impv!i
    // on the front of newRel2.
    !p := newRel2
    newRel2 := impv!i
    impv!i := 0

//    prImps()
//    prnewRws()
//    prnewRel2()
  } REPEAT

  

  IF newRel2 DO
  { LET p = newRel2
    newRel2 := !p
    // process relation p -> [r, x, y]
    addRel2(p!1, p!2, p!3) // This might add items to newRw or newRel2
    freeBlk(p)
  }
} REPEAT

AND evalRel(r, x, y) = VALOF
{ LET n = 2*x + y
  RESULTIS (r>>n) & 1
}

AND doCommands() BE
{ LET num, a, b = 0, 0, 0
  { LET ch = sys(10)
    SWITCHON ch INTO
    { DEFAULT:   writef("Bad ch '%c'*n", ch)
                 ENDCASE

      CASE '*n':
      CASE '*s': IF num DO { b := a; a := num; num := 0 }
                 ENDCASE

      CASE '0':CASE '1':CASE '2':CASE '3':CASE '4':
      CASE '5':CASE '6':CASE '7':CASE '8':CASE '9':
                 num := 10*num + ch - '0'
                 ENDCASE

      CASE '-':  IF num DO { b := a; a := -num; num := 0 }
                 ENDCASE

      CASE '=':  IF num DO { b := a; a := num; num := 0 }
                 newline()
                 newRel2 := newBlk(newRel2, #b1001, b, a)
                 doClosure()
                 prImps()
                 prEqs()
                 ENDCASE

      CASE '>':  IF num DO { b := a; a := num; num := 0 }
                 newline()
                 newRel2 := newBlk(newRel2, #b1011, b, a)
                 doClosure()
                 prImps()
                 prEqs()
                 ENDCASE

      CASE 'c':  newline()
                 writef("Doing Closure*n")
                 doClosure()
                 ENDCASE

      CASE 'x':  newline()
                 { LET N = 99
                   LET x, y, z = randno(100), randno(N)+1, randno(N)+1
                   IF x>90 DO z := -z
                   newRel2 := newBlk(newRel2, #b1011, y, z)
                   writef("New relation %n -> %n*n", y, z)
                 }
                 doClosure()
                 prImps()
                 prEqs()
                 ENDCASE
                 
      CASE 'y':  newline()
                 { LET N = 19
                   LET x, y, z = randno(100), randno(N)+1, randno(N)+1
                   IF x>90 DO z := -z
                   newRel2 := newBlk(newRel2, #b1011, y, z)
                   writef("New relation %n -> %n*n", y, z)
                 }
                 doClosure()
                 prImps()
                 prEqs()
                 ENDCASE
                 
      CASE 'z':  newline()
                 { LET N = 9
                   LET x, y, z = randno(100), randno(N)+1, randno(N)+1
                   IF x>90 DO z := -z
                   newRel2 := newBlk(newRel2, #b1011, y, z)
                   writef("New relation %n -> %n*n", y, z)
                 }
                 doClosure()
                 prImps()
                 prEqs()
                 ENDCASE
                 
      CASE 't':  newline()
                 chkNegx()
                 chkNegy()
                 chkSwap2()
                 chkComp2()
                 ENDCASE

      CASE 'p':  newline()
                 prEqs()
                 prImps()
                 prnewRws()
                 prnewRel2()
                 ENDCASE

      CASE 'q':  newline()
                 BREAK

      CASE 'r':  IF num DO { b := a; a := num; num := 0 }
                 { ch := sys(10)
                   UNLESS '0'<=ch<='1' BREAK
                   num := num+num+ch-'0'
                 } REPEAT
                 newRel2 := newBlk(newRel2, num&#b1111, b, a)
                 doClosure()
                 prEqs()
                 prImps()
                 ENDCASE
    }
  } REPEAT
}

LET start() = VALOF
{ 
  writef("Chk3 entered*n")
  initialise()

  doCommands()

  freespace()
  RESULTIS 0
}


