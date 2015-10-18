/*

This is a program to find a good permutation sequence for the split
function. The requirements are:

1) The sequence consists of permutations of 01234567.

2) The upper 4 values must always include 7.

3) The upper two value must include all 28 possible pair

4) The upper three values must include all 56 possible triple.

5) The upper four variables must inclue all 35 possible quartets.

6) Each permutation is derived from its previous permutation by a
single exchange.

7) It should attempt to minimise the total cost of the exchanges baring
in mind that some exchanges are more costly than others.

Note:
 28 = C(8,2) =  8*7  /  1*2     number of pairs selected from 01234567
 56 = C(8,3) = 8*7*6 / 1*2*3    number of triples selected from 01234567
 35 = C(7,3) = 7*6*5 / 1*2*3    number of quartets each including a 7
 24 = 4!                        Number of permutations of 4 items

Implemented in BCPL by Martin Richards (c) July 2003

*/

GET "libhdr"

GLOBAL {
 bitsv: ug   // Each element corresponds to a setting of the upper
             // four values of the permutation.
             // Eg: #b00100000_00000100_10000000_00000010 corresponds to
             // the last four values of the permutation being 5271
             // This vector is precomputed to hold all possible quartets
 succs       // Each element points to a vector containing the 9 
             // subscripts corresponding to the successors of the
             // current item.
 cn2         // Each element is an integer in the range 1 to 28
             // identifying which pair of values are in the upper
             // two argument positions
 cn3         // Each element is an integer in the range 1 to 56
             // identifying which pair of values are in the upper
             // three argument positions
 cn4         // Each element is an integer in the range 1 to 35
             // identifying which pair of values are in the upper
             // four argument positions
 counter2    // Each element holds a count of how often particular
             // pair has occurred in the current permutation sequence.
             // The subscripts range from 1 to 28.
 counter3    // Each element holds a count of how often particular
             // triple has occurred in the current permutation sequence.
             // The subscripts range from 1 to 56 and each count is always
             // zero or one since the required permutation sequence is
             // of length 56 and no triple is repeated.
 counter4    // Each element holds a count of how often particular
             // quartet has occurred in the current permutation sequence.
             // The subscripts range from 1 to 35.
 pairv       // A precomputed vector of 28 legal pairs
 tripv       // A precomputed vector of 56 legal triple
 quadv       // A precomputed vector of 35 legal quartets
 solnv       // solnv!1 to solnv!56 will hold a solution
 spacev      // This is the vector from which all other vectors are
             // allocated.
 n           // The number of possible settings of the last four values
             // it should be 35*24 (=840)
 paircount   // Count of distinct pairs in the current path
 quadcount   // Count of distinct quartets in the current path
 time0       // Time at start of search
}

LET start() = VALOF
{ LET v = getvec(20000)

  UNLESS v DO
  { writef("Insufficient space*n")
    RESULTIS 0
  }

  FOR i = 0 TO 20000 DO v!i := 0

  bitsv := v; v := v+35*24+1
  succs := v; v := v+535*24+1

  cn2      := v; v := v+35*24+1
  cn3      := v; v := v+35*24+1
  cn4      := v; v := v+35*24+1
  counter2 := v; v := v+28+1
  counter3 := v; v := v+56+1
  counter4 := v; v := v+35+1
  pairv    := v; v := v+28+1
  tripv    := v; v := v+56+1
  quadv    := v; v := v+35+1
  solnv    := v; v := v+56+1


  writef("space used = %n*n", v-bitsv)

  // Precompute the elements of bitsv. cn2, cn3 and cn4
  // and also pairv, tripv and quadv.
  n := 0
  FOR a = 0 TO 4 FOR b = a+1 TO 5 FOR c = b+1 TO 6 DO
  { LET d = 7
    LET ab, bb, cb, db = 1<<a, 1<<b, 1<<c, 1<<d
    n := n+1
    cn2!n   := find(pairv,           cb | db)  // a b c d
    cn3!n   := find(tripv,      bb | cb | db)
    cn4!n   := find(quadv, ab | bb | cb | db)
    bitsv!n := pack(       ab,  bb,  cb,  db)
    n := n+1
    cn2!n   := find(pairv,           db | cb)  // a b d c
    cn3!n   := find(tripv,      bb | db | cb)
    cn4!n   := find(quadv, ab | bb | db | cb)
    bitsv!n := pack(       ab,  bb,  db,  cb)
    n := n+1
    cn2!n   := find(pairv,           bb | db)  // a c b d
    cn3!n   := find(tripv,      cb | bb | db)
    cn4!n   := find(quadv, ab | cb | bb | db)
    bitsv!n := pack(       ab,  cb,  bb,  db)
    n := n+1
    cn2!n   := find(pairv,           db | bb)  // a c d b
    cn3!n   := find(tripv,      cb | db | bb)
    cn4!n   := find(quadv, ab | cb | db | bb)
    bitsv!n := pack(       ab,  cb,  db,  bb)
    n := n+1
    cn2!n   := find(pairv,           bb | cb)  // a d b c
    cn3!n   := find(tripv,      db | bb | cb)
    cn4!n   := find(quadv, ab | db | bb | cb)
    bitsv!n := pack(       ab,  db,  bb,  cb)
    n := n+1
    cn2!n   := find(pairv,           cb | bb)  // a d c b
    cn3!n   := find(tripv,      db | cb | bb)
    cn4!n   := find(quadv, ab | db | cb | bb)
    bitsv!n := pack(       ab,  db,  cb,  bb)
    n := n+1
    cn2!n   := find(pairv,           cb | db)  // b a c d
    cn3!n   := find(tripv,      ab | cb | db)
    cn4!n   := find(quadv, bb | ab | cb | db)
    bitsv!n := pack(       bb,  ab,  cb,  db)
    n := n+1
    cn2!n   := find(pairv,           db | cb)  // b a d c
    cn3!n   := find(tripv,      ab | db | cb)
    cn4!n   := find(quadv, bb | ab | db | cb)
    bitsv!n := pack(       bb,  ab,  db,  cb)
    n := n+1
    cn2!n   := find(pairv,           ab | db)  // b c a d
    cn3!n   := find(tripv,      cb | ab | db)
    cn4!n   := find(quadv, bb | cb | ab | db)
    bitsv!n := pack(       bb,  cb,  ab,  db)
    n := n+1
    cn2!n   := find(pairv,           db | ab)  // b c d a
    cn3!n   := find(tripv,      cb | db | ab)
    cn4!n   := find(quadv, bb | cb | db | ab)
    bitsv!n := pack(       bb,  cb,  db,  ab)
    n := n+1
    cn2!n   := find(pairv,           ab | cb)  // b d a c
    cn3!n   := find(tripv,      db | ab | cb)
    cn4!n   := find(quadv, bb | db | ab | cb)
    bitsv!n := pack(       bb,  db,  ab,  cb)
    n := n+1
    cn2!n   := find(pairv,           cb | ab)  // b d c a
    cn3!n   := find(tripv,      db | cb | ab)
    cn4!n   := find(quadv, bb | db | cb | ab)
    bitsv!n := pack(       bb,  db,  cb,  ab)
    n := n+1
    cn2!n   := find(pairv,           bb | db)  // c a b d
    cn3!n   := find(tripv,      ab | bb | db)
    cn4!n   := find(quadv, cb | ab | bb | db)
    bitsv!n := pack(       cb,  ab,  bb,  db)
    n := n+1
    cn2!n   := find(pairv,           db | bb)  // c a d b
    cn3!n   := find(tripv,      ab | db | bb)
    cn4!n   := find(quadv, cb | ab | db | bb)
    bitsv!n := pack(       cb,  ab,  db,  bb)
    n := n+1
    cn2!n   := find(pairv,           ab | db)  // c b a d
    cn3!n   := find(tripv,      bb | ab | db)
    cn4!n   := find(quadv, cb | bb | ab | db)
    bitsv!n := pack(       cb,  bb,  ab,  db)
    n := n+1
    cn2!n   := find(pairv,           db | ab)  // c b d a
    cn3!n   := find(tripv,      bb | db | ab)
    cn4!n   := find(quadv, cb | bb | db | ab)
    bitsv!n := pack(       cb,  bb,  db,  ab)
    n := n+1
    cn2!n   := find(pairv,           ab | bb)  // c d a b
    cn3!n   := find(tripv,      db | ab | bb)
    cn4!n   := find(quadv, cb | db | ab | bb)
    bitsv!n := pack(       cb,  db,  ab,  bb)
    n := n+1
    cn2!n   := find(pairv,           bb | ab)  // c d b a
    cn3!n   := find(tripv,      db | bb | ab)
    cn4!n   := find(quadv, cb | db | bb | ab)
    bitsv!n := pack(       cb,  db,  bb,  ab)
    n := n+1
    cn2!n   := find(pairv,           bb | cb)  // d a b c
    cn3!n   := find(tripv,      ab | bb | cb)
    cn4!n   := find(quadv, db | ab | bb | cb)
    bitsv!n := pack(       db,  ab,  bb,  cb)
    n := n+1
    cn2!n   := find(pairv,           cb | bb)  // d a c b
    cn3!n   := find(tripv,      ab | cb | bb)
    cn4!n   := find(quadv, db | ab | cb | bb)
    bitsv!n := pack(       db,  ab,  cb,  bb)
    n := n+1
    cn2!n   := find(pairv,           ab | cb)  // d b a c
    cn3!n   := find(tripv,      bb | ab | cb)
    cn4!n   := find(quadv, db | bb | ab | cb)
    bitsv!n := pack(       db,  bb,  ab,  cb)
    n := n+1
    cn2!n   := find(pairv,           cb | ab)  // d b c a
    cn3!n   := find(tripv,      bb | cb | ab)
    cn4!n   := find(quadv, db | bb | cb | ab)
    bitsv!n := pack(       db,  bb,  cb,  ab)
    n := n+1
    cn2!n   := find(pairv,           ab | bb)  // d c a b
    cn3!n   := find(tripv,      cb | ab | bb)
    cn4!n   := find(quadv, db | cb | ab | bb)
    bitsv!n := pack(       db,  cb,  ab,  bb)
    n := n+1
    cn2!n   := find(pairv,           bb | ab)  // d c b a
    cn3!n   := find(tripv,      cb | bb | ab)
    cn4!n   := find(quadv, db | cb | bb | ab)
    bitsv!n := pack(       db,  cb,  bb,  ab)
  }
  writef("n=%n*n", n)

  // Create and fill in the 
  FOR p = 1 TO n DO
  { LET w = bitsv!p
    LET a, b, c, d = w>>24, w>>16&255, w>>8&255, w&255
    LET e, f, g, h = 1, ?, ?, ?
    WHILE e=a | e=b | e=c | e=d DO e := e<<1
    f := e<<1
    WHILE f=a | f=b | f=c | f=d DO f := f<<1
    g := f<<1
    WHILE g=a | g=b | g=c | g=d DO g := g<<1
    h := g<<1
    WHILE h=a | h=b | h=c | h=d DO h := h<<1
    //writef("%b8 %b8 %b8 %b8 %b8 %b8 %b8 %b8*n", a,b,c,d,e,f,g,h)
    //abort(1000)

    UNLESS (a|b|c|d|e|f|g|h) = #b11111111 DO abort(999)

    succs!p := v
    UNLESS a=#b10000000 DO
    { v!0 := find(bitsv, pack(e,b,c,d)) // Select one of the other values
      v!1 := find(bitsv, pack(f,b,c,d))
      v!2 := find(bitsv, pack(g,b,c,d))
      v!3 := find(bitsv, pack(h,b,c,d))
      v := v+4
    }
    UNLESS b=#b10000000 DO
    { v!0 := find(bitsv, pack(a,e,c,d))
      v!1 := find(bitsv, pack(a,f,c,d))
      v!2 := find(bitsv, pack(a,g,c,d))
      v!3 := find(bitsv, pack(a,h,c,d))
      v := v+4
    }
    UNLESS c=#b10000000 DO
    { v!0 := find(bitsv, pack(a,b,e,d))
      v!1 := find(bitsv, pack(a,b,f,d))
      v!2 := find(bitsv, pack(a,b,g,d))
      v!3 := find(bitsv, pack(a,b,h,d))
      v := v+4
    }
    UNLESS d=#b10000000 DO
    { v!0 := find(bitsv, pack(a,b,c,e))
      v!1 := find(bitsv, pack(a,b,c,f))
      v!2 := find(bitsv, pack(a,b,c,g))
      v!3 := find(bitsv, pack(a,b,c,h))
      v := v+4
    }

    v!0 := find(bitsv, pack(b,a,c,d))  // Swap pairs
    v!1 := find(bitsv, pack(c,b,a,d))
    v!2 := find(bitsv, pack(d,b,c,a))
    v!3 := find(bitsv, pack(a,c,b,d))
    v!4 := find(bitsv, pack(a,d,c,b))
    v!5 := find(bitsv, pack(a,b,d,c))
    v := v+6
/*
    writef("successors of %i3: ", p); wrquad(w); writef(" are:*n")
    FOR i = 0 TO 17 DO
    { wrquad(bitsv!(v!i))
      IF i REM 10 = 9 DO newline()
    }
    newline()
*/
    //abort(1000)
  }

  //FOR i = 1 TO 28 DO
  IF FALSE FOR i = 1 TO 256 DO
  { UNLESS pairv!i BREAK
    writef("%b8 ", pairv!i)
    IF i REM 7 = 0 DO newline()
  }
  newline()
  //FOR i = 1 TO 56 DO
  IF FALSE FOR i = 1 TO 256 DO
  { UNLESS tripv!i BREAK
    writef("%b8 ", tripv!i)
    IF i REM 7 = 0 DO newline()
  }
  newline()
  //FOR i = 1 TO 35 DO
  IF FALSE FOR i = 1 TO 256 DO
  { UNLESS quadv!i BREAK
    writef("%b8 ", quadv!i)
    IF i REM 7 = 0 DO newline()
  }

  // Now search for solutions
  paircount, quadcount := 0, 0
  time0 := sys(30)
  try(find(bitsv, pack(1<<4,1<<5,1<<6,1<<7)), 1)
  freevec(v)

  writes("*nend of test*n")
  RESULTIS 0
}

AND find(v, w) = VALOF
{ LET i = 1

  { LET x = v!i
    //writef("find: i=%i3 w=%b8 x=%b8*n", i, w, x)
    UNLESS x DO { v!i := w; BREAK }
    IF x=w BREAK
    i := i+1
  } REPEAT

  //writef("%i2: %b8*n", i, w)
  RESULTIS i
}

AND pack(a,b,c,d) = VALOF
{ //writef("%b8 %b8 %b8 %b8*n", a, b, c, d)//; abort(1000) 
  RESULTIS ((a<<8 | b)<<8 | c)<<8 | d
}

AND try(p, i) BE UNLESS counter3!(cn3!p) DO
{ // 1<=p<=840
  LET sv = succs!p
  LET n2 = counter2 + cn2!p
  LET n3 = counter3 + cn3!p
  LET n4 = counter4 + cn4!p
//writef("i=%i2 p=%i3: ", i, p)
//wrquad(bitsv!p)
//newline()
//  writef("p=%i3  cn3!p=%i2 counter3!(cn3!p)=%n*n", p, cn3!p, counter3!(cn3!p))
//  IF counter3!(cn3!p) RETURN

// encourage finding lots of pairs early
IF paircount<27 & paircount < 76*i/100 - 2 RETURN
// 60 =>   5000 msecs
// 61 =>   2900 msecs
// 62 =>  ????? msecs
// 62 =>   9430 msecs
// 64 =>     20 msecs
// 65 =>    100 msecs
// 66 =>  36810 msecs
// 67 =>  10230 msecs
// 68 =>  ????? msecs
// 69 =>  41400 msecs
// 70 =>    660 msecs
// 71 =>  ????? msecs
// 72 =>  ????? msecs
// 73 =>  ????? msecs
// 74 =>  ????? msecs
// 75 =>    210 msecs
// 76 =>     10 msecs
// 77 =>  14970 msecs
// 78 =>  ????? msecs
// 79 =>  ????? msecs
// 80 =>   3280 msecs
  solnv!i := p
  IF !n2=0 DO paircount := paircount + 1
  IF !n4=0 DO quadcount := quadcount + 1
  !n2 := !n2 + 1
  !n3 := 1
  !n4 := !n4 + 1

//writef("*np=%i3  cn3!p=%i2 counter3!(cn3!p)=%n*n", p, cn3!p, counter3!(cn3!p))
//writef("i=%i2 p=%i3: ", i, p)
//wrquad(bitsv!p)
//writef("  paircount=%i2 quadcount=%i2*n", paircount, quadcount)
//abort(1000)
//newline()
//FOR i = 1 TO 28 IF counter2!i DO
// writef(" %b8: %i3", pairv!i, counter2!i)
//newline()

//FOR i = 1 TO 56 IF counter3!i DO
//  writef(" i=%i2 %b8:%n*n", i, tripv!i, counter3!i)
//newline()

//FOR i = 1 TO 35 IF counter4!i DO
//  writef(" %b8: %n", quadv!i, counter4!i)
//newline()

  //IF i=-1 DO
{ STATIC { last=0 }
  IF FALSE & i>last DO
  { last := i
    writef("%i2: paircount=%i2  quadcount=%i2*n", i, paircount, quadcount)
    FOR j = 1 TO i DO
    { wrquad(bitsv!(solnv!j))
      IF j REM 15 = 0 DO newline()
    }
    newline()
  }
}


//writef("%i2: successors of %i3: ", i, p); wrquad(bitsv!p); writef(" are:*n")
//FOR i = 0 TO 17 DO
//{ wrquad(bitsv!(sv!i))
//  IF i REM 10 = 9 DO newline()
//}
//newline()

//abort(1000)

  TEST i=56 & paircount=28 & quadcount=35
  THEN { LET time1 = sys(30)
         writef("####################  Solution: #########################*n")
         FOR j = 1 TO i DO
         { wrquad(bitsv!(solnv!j))
           IF j REM 15 = 0 DO newline()
         }
         newline()
writef("*nTime %n msecs*n", time1-time0)
abort(9999)
time0 := sys(30)
       }
  ELSE FOR j = 0 TO 17 DO
  { //writef("calling try j=%i2 next perm: ", j)
    //wrquad(bitsv!(sv!j))
    //newline()
    try(sv!j, i+1)
  }

  //writef("Backtracking*n")
  //FOR j=1 TO i DO
  //{ wrquad(bitsv!(solnv!j))
  //  IF j REM 15 = 0 DO newline()
  //}
  //newline()
  //abort(1000)

  !n4 := !n4 - 1
  !n3 := 0
  !n2 := !n2 - 1
  IF !n4=0 DO quadcount := quadcount - 1
  IF !n2=0 DO paircount := paircount - 1
}

AND wrquad(w) BE
{ LET a, b, c, d = lg(w>>24), lg(w>>16&255), lg(w>>8&255), lg(w&255)
  writef(" %n%n%n%n", a, b, c, d)
}

AND lg(w) = w ! TABLE
      0,0,1,1,2,2,2,2,3,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,
      5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,
      6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,
      6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,
      7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,
      7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,
      7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,
      7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7


