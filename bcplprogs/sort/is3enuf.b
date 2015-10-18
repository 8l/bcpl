/* 
This program tests to see if 3 points are sufficient in
the buffer of points used in the merge phase of the closest pair of
points algorthm.

Implemented in BCPL be Martin Richards   1 December 2000
*/


/*
Assume the points are as follows:

(-n,n)     (0,n)       (n,n)
   .-------p-.-----b-----.
   |         |           |
   c         |           |          Case A
   |         |           a
   |         |q          |
   .---------.-----------.
(-n,0)     (0,0)       (n,0)
or
   .------p--.-----------.
   b         |           |
   |         |           |          Case B
   |         |           a
   |  c      | q         |
   .---------.-----------.

Note that either Cases A and B are both possible, 
or neither are possible so we need only consider case A.
 
The constraints are:

The size of the rectangle is 2n x n composed of two nxn squares.
The minimum known separation is n+1.
Each pair on the same square has a separation >n.
p is on the top edge of the right hand square.
pq is the closest all pairs with a separation d<=n.
Every other pair crossing the divide has a separation >d.
No point in the rectangle is lower than q.

*/


GET "libhdr"

GLOBAL {
 n : ug
 px; py
 qx; qy
 ax; ay
 bx; by
 cx; cy
 d
}
 
LET start() = VALOF
{ n := 100
  FOR x = -n TO 0 DO tryp(x, n)

/*
newline()
FOR y = n TO 0 BY -1 DO
{ FOR x = 0 TO n DO writef(" %i2", dist(x, y, 0, 0))
  newline()
}
*/
  RESULTIS 0
}

AND tryp(x, y) BE                     // Place p at (x,y)
{ px, py := x, y                      // (in left square, top line)
  FOR ty = n TO 0 BY -1 DO            // Find a place for q
                                      //  top down, left to right
  { IF dist(px, py, 0, ty)>n RETURN
    FOR tx = 0 TO n DO
    { d := dist(px, py, tx, ty)       // d = distance pq
      IF d>n BREAK
      tryq(tx, ty)
    }
  }
}

AND tryq(x, y) BE                         // Place q at (x,y)
{ qx, qy := x, y                          // in right square, pq = d <= n

  FOR ty = n TO qy BY -1 DO               // Find a place for a
                                          //    top down, on right edge
  { UNLESS dist(qx, qy, n, ty)>n RETURN  // Test qa>n
    UNLESS dist(px, py, n, ty)>d BREAK   // and  pa>d
    trya(n, ty)                         
  }
}

AND trya(x, y) BE                         // Place a at (x,y)
{ ax, ay := x, y

  FOR tx = n TO qx BY -1 DO               // Find a place for b
                                          //    top edge, right to left
  { UNLESS dist(qx, qy, tx, n)>n BREAK   // test qb > n
    UNLESS dist(px, py, tx, n)>d BREAK   // and  pb > d
    UNLESS dist(ax, ay, tx, n)>n LOOP    // and  ab > n
    tryb(tx, n)                           // b is ok
  }
}

AND tryb(x, y) BE
{ bx, by := x, y

  FOR ty = qy TO n DO                    // Find a place for c
                                         //  left edge, bottom up
  { UNLESS dist(px, py, -n, ty)>n BREAK
    UNLESS dist(qx, qy, -n, ty)>d LOOP
    tryc(-n, ty)
  }
}

AND tryc(x, y) BE
{ cx, cy := x, y
writef("pqabc = (%i3,%i3)  (%i3,%i3)  (%i3,%i3)  (%i3,%i3)  (%i3,%i3)*n",
                px, py,    qx, qy,    ax, ay,    bx, by,     cx, cy)
writef("distances = %i3 %i3 %i3 %i3 %i3 %i3 %i3 %i3 %i3 %i3*n",
     dist(px, py, qx, qy),dist(px, py, ax, ay),dist(px, py, bx, by),
                                               dist(px, py, cx, cy),
     dist(qx, qy, ax, ay),dist(qx, qy, bx, by),dist(qx, qy, cx, cy),
     dist(ax, ay, bx, by),dist(ax, ay, cx, cy),
     dist(bx, by, cx, cy))
}

AND sqrt(n) = n<=0 -> 0, VALOF
{ LET r = n
  { LET s = (r + n/r)/2
    IF r<=s RESULTIS r
    r := s
  } REPEAT
}

AND dist(x1, y1, x2, y2) = VALOF
{ LET dx, dy = x1-x2, y1-y2
  RESULTIS ABS(dx) + ABS(dy)
  RESULTIS sqrt(dx*dx + dy*dy)
}
 
