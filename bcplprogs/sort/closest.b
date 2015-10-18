// This is a demo implementation of the closest pair of points
// algorithm described by Sedgewick.

// Implemented in BCPL by Martin Richards (c) January 2001

GET "libhdr"

GLOBAL {
  pts:  ug              // list of points
  N                     // number of points
  min                   // minimum distance
  cp; cq                // closest pair of points
  distcount             // how many distances measured

  k1; k2; k3            // Statistics counts

  spacev                // pointer base of heap space
  spacep                // pointer to last node allocated
  spacet                // pointer to just after end of heap space
}

MANIFEST {
  Upb=1000000           // Words of heap space
  p_nxt=0; p_x; p_y     // Fields in point nodes
  p_size                // Size of point nodes
}

// Points are linked into lists holding pairs of coordinates: [link, x, y]

LET mk3(link, x, y) = VALOF
{ LET p = spacep-p_size
  IF p<spacev DO 
  { writef("Out of space*n")
    abort(999)
    RESULTIS 0
  }
  p_nxt!p, p_x!p, p_y!p := link, x, y
  spacep := p
  RESULTIS p
}

LET addpoint(x, y) BE 
{ pts := mk3(pts, x, y)
  N := N+1
}

LET sqrt(n) = n<=0 -> 0, VALOF
{ LET r = n
  { LET s = (r + n/r)/2
    IF r<=s RESULTIS r
    r := s
  } REPEAT
}

LET distance(p, q) = VALOF
{ LET dx, dy = p_x!p - p_x!q, p_y!p - p_y!q
  distcount := distcount+1
  IF ABS dx + ABS dy > 10000 RESULTIS 10000
  RESULTIS sqrt(dx*dx + dy*dy)
}
 
LET pr(p, n) BE
{ writef("%n points*n", n)
  WHILE p DO
  { writef("%i5 %i5*n", p!1, p!2)
    p := !p
  }
}

// Find closest pairs by exhaustive search
AND prclosest(p, min) BE WHILE p DO
{ LET q = !p
  WHILE q DO 
  { LET d = distance(p, q)
    IF d<=min DO writef("(%i4, %i4) -- (%i4, %i4)  distance %i4*n",
                          p!1, p!2,     q!1, q!2,           d)
    IF d<min DO { writef("##### BUG ######*n"); abort(999) }
    q := !q
  }
  p := !p
}

LET mergex(p, q) = VALOF
{ LET res = ?
  LET last = @res

  UNTIL p=0 | q=0 TEST p_x!p <= p_x!q
    THEN { !last := p
           last := p
           p := !p
         }
    ELSE { !last := q
           last := q
           q := !q
         }

  !last := p=0 -> q, p
  RESULTIS res
}

LET sortx(p, n) = n=1 -> p, VALOF
{ LET a, b = p, ?
  LET na = n/2
  LET nb = n - na
  FOR i = 2 TO na DO p := !p
  b := !p
  !p := 0
  RESULTIS mergex(sortx(a, na), sortx(b, nb)) // sorting on x
}

LET mergey(p, q) = VALOF
{ LET res = ?
  LET last = @res

  UNTIL p=0 | q=0 TEST p_y!p <= p_y!q
    THEN { !last := p
           last := p
           p := !p
         }
    ELSE { !last := q
           last := q
           q := !q
         }

  !last := p=0 -> q, p
  RESULTIS res
}

LET sorty(p, n) = n=1 -> p, VALOF
{ LET a, b, midx = p, ?, ?
  LET na = n/2
  LET nb = n - na
  LET p1, p2, p3 = 0, 0, 0
  FOR i = 2 TO na DO p := p_nxt!p
  b := p_nxt!p
  p_nxt!p := 0
  midx := p_x!b
  p :=  mergey(sorty(a, na), sorty(b, nb)) // sorting on y

  a := p
  WHILE a DO
  { IF ABS(p_x!a - midx) < min DO
    { LET y0 = p_y!a - min
      LET d  = ?

      IF p1 & p_y!p1>y0 DO
      { d := distance(a, p1)
        IF d<min DO { min := d
                      cp, cq := a,  p1
                      k1 := k1+1
                    }
      }
      IF p2 & p_y!p2>y0 DO
      { d := distance(a, p2)
        IF d<min DO { min := d
                      cp, cq := a,  p2
                      k2 := k2+1
                    }
      }
      IF p3 & p_y!p3>y0 DO
      { d := distance(a, p3)
        IF d<min DO { min := d
                      cp, cq := a,  p3
                      k3 := k3+1
                    }
      }
      p3 := p2
      p2 := p1
      p1 := a
    }
    a := !a
  }

  RESULTIS p
}

LET start() = VALOF
{ spacev := getvec(Upb)
  spacet := spacev+Upb
  spacep := spacet

  pts, N := 0, 0

  FOR i = 1 TO 100000 DO addpoint(randno(1000000), randno(1000000))

//  pr(pts, N)

  min := 10000           // A big distance
  cp, cq     := 0, 0     // for closest pair
  k1, k2, k3 := 0, 0, 0  // Statistics
  distcount := 0

  pts := sortx(pts, N)
  pts := sorty(pts, N)

  writef("Closest pair: (%n,%n)-(%n,%n) distance %n*n",
          cp!1, cp!2, cq!1, cq!2, min)
  writef("Number of points %n   distcount %n*n", N, distcount)
  writef("k1 = %i5*n", k1)
  writef("k2 = %i5*n", k2)
  writef("k3 = %i5*n", k3)

//  writef("*nNow checking the result by testing all pairs of points*n")
//  prclosest(pts, min)
  freevec(spacev)
  RESULTIS 0
}

