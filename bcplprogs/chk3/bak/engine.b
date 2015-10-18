/*

This is the main recursive search engine of the tautology checker
based on the analysis of the conjunction of a set of relations over 3
Boolean variables.

Implemented in BCPL by Martin Richards (c) October 2005
*/

SECTION "engine"

GET "libhdr"
GET "chk3.h"

/*

explore(rv, n, vn, ma, mb, mc, md)

The function returns FALSE if the relations are inconsitent otherwise it
returns TRUE with the boolean matrices set with any information
about implications between pairs of variables.
The relations are in rv!1 to rv!n.
Variables identifiers are between 1 and vn.
The matrices are of size vn x vn

Algorithm:

save old mata,... matd, prevmata,.. prevmatd,
         refs, refcount, varval
etc

formlists
standardise all relations
put them all into the relation stack

(1) pop each relation from the stack and apply findimps to it
(2) Apply findnewinfo putting any relation that is changed onto
    the stack
If stack non empty goto (1)

(3) For each variable
    (3.1) If it is used only once eliminate it
    (3.2) If it is used exactly twice and the two relations
          can be combined, combine them and eliminate the variable
    (3.3) For each pair of relations sharing this variable and
          have >= 3 variables in common, let each restrict the other.
    Any relation changed by this process is put onto the stack.

If stack non empty goto (1)

(4) Combine any combinable relations preferring those with the
    greatest number of variables in common, putting the resulting
    relations on the stack.

If stack non empty goto (1)

(5) Split any relation that can be factorised into the conjunction
    of two relations over disjoint variables, puting the factors
    into the stack.

If stack non empty goto (1)

At this point no progress can be made by simple means so the problem
must split into sub problems.

(6) Choose a relations with the greatest influence and fewest ones
    in its relation bit pattern. Form two sub-problems by anding
    its bit pattern with a random bit pattern and its complement.
    Recursively call explore on these two sub problems. If neither
    is satisfiable the the original problem was not satisfiable.
    If just one is potentially satisfiable return its set of matrices.
    If both are potentially satisfiable return the intersection of its
    set of matrices.

(7) Apply findnewinfo putting any relation that is changed onto
    the stack

If stack non empty goto (1)

Either give up,
or arrange to recurse to a greater depth,
or do the recursion based on a different relation,
or split the relation into more mutually exclusive relations,
   possibly one for each of the <255 possible settings of its
   variables.
or split pairs, triple or more relations simultaneously.
*/

LET explore(rv, n, vval, vmax, ba, bb, bc, bd) = VALOF
{ 
  writef("explore entered*n")

  FOR i = 1 TO reln DO pushrel(relv!i)

  WHILE relstackp DO // Iterate through the contents of the stack
  { 
    // Eliminate any variables that are only used once
    FOR id = 1 TO maxid IF refcount!id=1 DO
    { LET rel = refs!id!1
//writef("eliminating v%n from relation %n*n", origid(id), rel!r_numb)
      ignorevar(rel, id)
      refs!id := 0
      refcount!id := 0
      varinfo!id := -2
    }

    writef("*nRelation Stack size %n:*n", relstackp)
    FOR i = 1 TO relstackp DO wrrel(relstack!i, TRUE)
    newline()
    abort(6666)

    WHILE relstackp DO // Iterate through the contents of the stack
    { LET rel = poprel()
      newline()
      wrrel(rel, TRUE)
      //newline()
      writef("cost of standardise is %n*n", instrcount(standardise, rel))
//abort(1111)
      newline()
      wrrel(rel, TRUE)
      writef("cost of findimps:  %i8*n", instrcount(findimps, rel))
    }

    writef("*n*nCalling bm_findnewinfo()*n*n")
    bm_findnewinfo()
    abort(1111)
  }

  RESULTIS FALSE
}
