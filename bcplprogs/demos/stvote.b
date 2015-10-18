/*
************** STILL UNDER DEVELOPMENT *************

This is an implementation of Meek's method for
a single transferable vote election.

Ref Hill,I.D., Wichmann, B.A. and Woodall, D.R
"Singel transferable vote by Meek's method"
Computer J 30 (1987) 277-281.

Implemented in BCPL by Martin Richards (c) Oct 2000
*/

GET "libhdr"

GLOBAL {
cmax:ug   // Number of candidates, named A, B, C, etc
smax      // Number of seats
emax      // Number of electors

count     // Number of candidates elected so far
state     // state!c  Candidate state Elected, Hopeful or Excluded
w         // w!c      Candidate's current weight
vote      // vote!c   Canditae's vote
excess    // Excess votes
totalvotes

scale     // All scaled arithmetic done to this scale
          // (intially 1000, but may change)

paper     // paper!e  Elector's ballot paper as a string
          // eg      "AFG BD HI E"
}

MANIFEST {
Elected=0; Hopeful; Excluded
}

LET start() = VALOF
{
  scale := 1000  // scale of scaled arithmetic

  cmax  := 10
  smax  := 5
  emax  := 20

  w     := getvec(cmax)
  state := getvec(cmax)
  paper := getvec(emax)

  FOR e = 1 TO emax DO paper!e := 0

  paper! 1 := "A BCD EF GHI J"
  paper! 2 := "DF G AE C HI J B"
  paper! 3 := "E F BDH J IC GA"
  paper! 4 := "B G A DE J H F CI"
  paper! 5 := "DA C B GEI JF H"
  paper! 6 := "A GHF E IC DBJ"
  paper! 7 := "C E GH BF IJ D A"
  paper! 8 := "E G DA H FCI JB"
  paper! 9 := "DEB FA GIH J C"
  paper!10 := "B D F G A E C I J H"

  FOR c = 1 TO cmax DO w!c, state!c := scale, Hopeful
  count := 0  // Number of elected candidates

  { //
    LET old count = count
    excess := 0
    FOR i = 1 TO cmax DO vote!c := 0

    FOR e = 1 TO emax IF paper!e DO
    { totalvotes := totalvotes + scale
      processpaper(paper!e)
    }

    quota := (totalvotes-excess)/(smax+1)

    FOR c = 1 TO cmax IF vote!c>quota DO
      state!c, count := Elected, count+1

    IF count=oldcount DO
    { // No Hopeful candidate was elected so
      // exclude a candidate with the lowest vote
      LET cand = 0
      LET candvote = maxint
      FOR c = 1 TO cmax IF state!c=Hopeful & vote!c<candvote DO
          cand, candvote := c, vote!c
      state!cand := Excluded
    }
    
    { // Set the weight of the elected candidated
      LET change = FALSE
      FOR c = 1 TO cmax IF status!c=Elected DO
      { LET wc := w!c - (vote!c-quota)
        UNLESS wc=w!c DO
        { w!c, change := wc, TRUE
          writef("w!%i2 = %i5*n", c, wc) 
        }
        excess := 0
        FOR i = 1 TO cmax DO vote!c := 0

        FOR e = 1 TO emax IF paper!e DO
        { totalvotes := totalvotes + scale
          processpaper(paper!e)
        }

        quota := (totalvotes-excess)/(smax+1)
      }
    } REPEAT

  } REPEATWHILE count<smax

  writef("Ballot papers:*n*n")
  FOR e = 1 TO emax IF paper!e DO writef("%i4: %s*n", e, paper!e)
  
  writef("*nElected candidates:  ")
  FOR c = 1 TO cmax IF state!c=Elected DO writef(" %c", c+'A'-1)
  newline()

  freevec(w)
  freevec(state)
  freevec(paper)
  RESULTIS 0
}