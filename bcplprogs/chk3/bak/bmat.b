// Boolean matrix functions for chk8

// bm_setmatsize(n)
// bm_mkmat()
// bm_clrmat(a, b, c, d)
// bm_setbitpp(i, j)
// bm_setbitpn(i, j)
// bm_setbitnp(i, j)
// bm_setbitnn(i, j)
// bm_setvar0(i)
// bm_setvar1(i)
// bm_setbit(m, i, j)
// bm_warshall(a, b, c, d)
// bm_prmat(a,b,c,d)
// bm_findnewinfo(a,b,c,d)

GET "libhdr"
GET "chk3.h"

LET bm_setmatsize(n) BE
{ matn := n           // Rows and columns are numbered 1..n
  matnw := n/32 + 1   // Number of 32-bit words in a row
}

AND bm_mkmat() = VALOF
{ LET upb = matnw * matn - 1
  LET mat = getvec(upb)
  UNLESS mat DO
  { writef("bm_mkmat: more store needed*n")
    abort(999)
    RESULTIS 0
  }
  FOR i = 0 TO upb DO mat!i := 0
//writef("bm_mkmat => %n*n", mat)
  RESULTIS mat
}

AND bm_clrmat(a, b, c, d) BE
{ LET upb = matnw * matn - 1
  FOR i = 0 TO upb DO a!i, b!i, c!i, d!i := 0, 0, 0, 0
}

AND bm_setbitpp(i, j) BE
{ bm_setbit(mata, i, j)         //  vi ->  vj
  bm_setbit(matd, j, i)         // ~vj -> ~vi
wrvars(); abort(1111)
  UNLESS varinfo!i=1 | varinfo!j=1 DO
    writef(" v%n -> v%n*n", origid(i), origid(j))
}

AND bm_setbitpn(i, j) BE
{ bm_setbit(matb, i, j)         //  vi -> ~vj
  bm_setbit(matb, j, i)         //  vj -> ~vi
wrvars(); abort(1111)
  UNLESS varinfo!i=0 | varinfo!j=0 DO
    writef(" v%n ->~v%n*n", origid(i), origid(j))
}

AND bm_setbitnp(i, j) BE
{ bm_setbit(matc, i, j)         // ~vi ->  vj
  bm_setbit(matc, j, i)         // ~vj ->  vi
wrvars(); abort(1111)
  UNLESS varinfo!i=1 | varinfo!j=1 DO
    writef("~v%n -> v%n*n", origid(i), origid(j))
}

AND bm_setbitnn(i, j) BE
{ bm_setbit(matd, i, j)         // ~vi -> ~vj
  bm_setbit(mata, j, i)         //  vj ->  vi
wrvars(); abort(1111)
  UNLESS varinfo!i=1 | varinfo!j=0 DO
    writef("~v%n ->~v%n*n", origid(i), origid(j))
}

AND bm_setvar0(i) BE
{ writef(" v%n = 0*n", origid(i))
  varinfo!i := 0
  bm_setbit(matb, i, i)         //  vi -> ~vi
}

AND bm_setvar1(i) BE
{ writef(" v%n = 1*n", origid(i))
  varinfo!i := 1
  bm_setbit(matc, i, i)         // ~vi -> vi
}

AND bm_setvareq(i, j) BE
{ writef(" v%n = v%n*n", origid(i), origid(j))
  varinfo!i := 2*j
  bm_setbit(mata, i, j)         // vi -> vj
  bm_setbit(mata, j, i)         // vj -> vi
}

AND bm_setvarne(i, j) BE
{ writef(" v%n = ~v%n*n", origid(i), origid(j))
  varinfo!i := 2*j+1
  bm_setbit(matb, i, j)         // vi -> ~vj
  bm_setbit(matb, j, i)         // vj -> ~vi
}

AND bm_setbit(m, i, j) BE IF i DO
{ LET p = m + ((i-1)*matnw) + (j-1)/32 // Ptr to word containing bit
  AND bit = 1<<((j-1) & 31)
  !p := !p | bit                       // Set the bit
}

AND bm_warshall(a, b, c, d) BE
{ // Perform Warshall's algorithm on the 2n x 2n matrix:
  //     ( a b )
  //     ( c d )

  FOR k = 1 TO matn DO // Go down column k of matrices a and c
  { LET offk = (k-1)/32               // Word offset within a row
    LET bitk = 1 << ((k-1) REM 32)    // 
    LET rowka = a + (k-1)*matnw
    LET rowkb = b + (k-1)*matnw
    FOR i = 1 TO matn DO              // Inspect bits in col k of a
    { LET rowia = a + (i-1)*matnw
      LET rowib = b + (i-1)*matnw
      UNLESS (rowia!offk & bitk)=0 DO
      { // a[i,k]=1 so OR row k of (a b) into row i of (a b)
        //writef("ORing row %n of (a b) into row %n of (a b)*n", k, i) 
        FOR j = 0 TO matnw-1 DO
        { rowia!j := rowia!j | rowka!j
          rowib!j := rowib!j | rowkb!j
        }
      }
    }
    FOR i = 1 TO matn DO              // Inspect bits in col k of c
    { LET rowic = c + (i-1)*matnw
      LET rowid = d + (i-1)*matnw
      UNLESS (rowic!offk & bitk)=0 DO
      { // c[i,k]=1 so OR row k of (a b) into row i of (c d) 
        //writef("ORing row %n of (a b) into row %n of (c d)*n", k, i) 
        FOR j = 0 TO matnw-1 DO
        { rowic!j := rowic!j | rowka!j
          rowid!j := rowid!j | rowkb!j
        }
      }
    }
  }

  FOR k = 1 TO matn DO // Go down column k of matrices b and d
  { LET offk = (k-1)/32               // Word offset within a row
    LET bitk = 1 << ((k-1) REM 32)    // 
    LET rowkc = c + (k-1)*matnw
    LET rowkd = d + (k-1)*matnw
    FOR i = 1 TO matn DO              // Inspect bits in col k of b
    { LET rowia = a + (i-1)*matnw
      LET rowib = b + (i-1)*matnw
      UNLESS (rowib!offk & bitk)=0 DO
      { // b[i,k]=1 so OR row k of (c d) into row i of (a b) 
        //writef("ORing row %n of (c d) into row %n of (a b)*n", k, i) 
        FOR j = 0 TO matnw-1 DO
        { rowia!j := rowia!j | rowkc!j
          rowib!j := rowib!j | rowkd!j
        }
      }
    }
    FOR i = 1 TO matn DO              // Inspect bits in col k of d
    { LET rowic = c + (i-1)*matnw
      LET rowid = d + (i-1)*matnw
      UNLESS (rowid!offk & bitk)=0 DO
      { // d[i,k]=1 so OR row k of (c d) into row i of (c d) 
        //writef("ORing row %n of (c d) into row %n of (c d)*n", k, i) 
        FOR j = 0 TO matnw-1 DO
        { rowic!j := rowic!j | rowkc!j
          rowid!j := rowid!j | rowkd!j
        }
      }
    }
  }
}

AND bm_prmat(a, b, c, d) BE
{ FOR i = 1 TO matn DO
  { prmatrow(a, i)
    wrch('*s')
    prmatrow(b, i)
    newline()
  }
  newline()
  FOR i = 1 TO matn DO
  { prmatrow(c, i)
    wrch('*s')
    prmatrow(d, i)
    newline()
  }
}

AND prmatrow(m, i) BE FOR j = 1 TO matn DO
{ LET p   = m + (i-1)*matnw + (j-1)/32
  AND bit = 1 << (j-1) REM 32
  wrch((!p & bit) = 0 -> '.', '**')
}

AND bm_findnewinfo() BE
{ // First make the transitive closure
  bm_warshall(mata, matb, matc, matd)

//  FOR i = 1 TO maxid IF 0<=varinfo!i<=1 DO
//    writef("v%n=%n ", origid(i), varinfo!i)
//  newline()

  // For each i,
  // look for new information of the form vi=0 or vi=1
  // then new information of the form vi=vj or vi=~vj, i<j
  // then new information of the form vi->vj, vi->~vj, ~vi=vj or ~vi->~vj, i<j
 
  // Look for new ones in Bii and Cii
//  FOR i = 1 TO matn UNLESS 0<=varinfo!i<=1 DO
  FOR i = 1 TO matn DO
  { // vi not known to be 0 or 1
    LET row = (i-1)*matnw
    LET j, sh = (i-1)/32, (i-1) REM 32
    LET w = matbprev!(row+j) XOR matb!(row+j)

    // See if vi->~vi ie vi=0 is new info
    UNLESS ((w>>sh)&1)=0 DO
    { //writef("findnewinfo:  v%n = 0*n", origid(i))
      apvarset0(i)
    }
    w := matcprev!(row+j) XOR matc!(row+j)
    // See if ~vi->vi ie vi=1 is new info
    UNLESS ((w>>sh)&1)=0 DO
    { //writef("findnewinfo:  v%n = 1*n", origid(i))
      apvarset1(i)
    }
  }

  FOR i = 1 TO matn UNLESS 0<=varinfo!i<=1 DO
  { // Provided vi is not already known to be 0 or 1
    // look for any vj that is not already set to 0 or 1
    // for which vi=vj, vi=~vj,
    // vi->vj, vi->~vj,~vi->vj or ~vi->~vj is new information
    // preferring vi=vj, vi=~vj, if possible.

    LET row = (i-1)*matnw
    FOR r = 0 TO matnw-1 DO
    { LET k = row+r
      LET awold, awnew = mataprev!k, mata!k
      AND bwold, bwnew = matbprev!k, matb!k
      AND cwold, cwnew = matcprev!k, matc!k
      AND dwold, dwnew = matdprev!k, matd!k
      AND w = ?

      w := (awold XOR awnew) | (dwold XOR dwnew)

      // Each bit in w corresponds to either or both
      // Aij=1 or Dij=1 being new information implying that
      // one or more of: vi=vj, vi->vj and ~vi->~vj are new.

      IF w DO 
      { LET bit, j = 1, 1 + r*32
        LET wad = awnew & dwnew          // (A^D)ij =1 

        { // Iterate through the ones in w
          IF (w&bit)~=0 DO
          {  w := w - bit
            // One of vi=vj, vi->vj and/or ~vi->~vj is new
            UNLESS i>=j | 0<=varinfo!j<=1 DO
              // i<j and vj is not 0 or 1
              TEST (wad&bit)~=0
              THEN apvareq(i, j)         // (A^D)ij = 1 is new
              ELSE TEST ((awold XOR awnew)&bit)~=0
                   THEN apvarimppp(i, j) // Aij = 1 is new
                   ELSE apvarimpnn(i, j) // Dij = 1 is new
          }
          bit, j := bit<<1, j+1
        } REPEATWHILE w
      }

      w := (bwold XOR bwnew) | (cwold XOR cwnew) // Bij=1 or Cij=1 new

      // Each bit in w corresponds to either or both
      // Bij=1 or Cij=1 being new information implying that
      // one or more of: vi=~vj, vi->~vj and ~vi->vj are new.

      IF w DO 
      { LET bit, j = 1, 1 + r*32
        LET wbc = bwnew & cwnew          // (B^C)ij =1 

        { // Iterate through the ones in w
          IF (w&bit)~=0 DO
          { w := w - bit
            // One of vi=~vj, vi->~vj and/or ~vi->vj is new
            UNLESS i>=j | 0<=varinfo!j<=1 DO
              // i<j and vj is not 0 or 1
              TEST (wbc&bit)~=0
              THEN apvarne(i, j)         // (B^C)ij = 1 is new
              ELSE TEST ((bwold XOR cwnew)&bit)~=0
                   THEN apvarimppn(i, j) // Bij = 1 is new
                   ELSE apvarimpnp(i, j) // Cij = 1 is new
          }
          bit, j := bit<<1, j+1
        } REPEATWHILE w
      }
    }
  }

  // Remember the current state of the matrices
  FOR i = 0 TO matn-1 DO
  { LET row = i*matnw
     FOR k = row TO row+matnw-1 DO
     { mataprev!k := mata!k
       matbprev!k := matb!k
       matcprev!k := matc!k
       matdprev!k := matd!k
     }
   }
}

