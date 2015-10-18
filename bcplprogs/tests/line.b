/* Test line drawing code
*/

GET "libhdr"

LET start() = VALOF
{ writef("*ndrawline1*n*n")
  drawline1(0, 0, 25, 19)

  writef("*ndrawline2*n*n")
  drawline2(0, 0, 25, 19)

  writef("*ndrawline3*n*n")
  drawline3(0, 0, 25, 19)


  writef("drawline1: %i6 instructions*n", instrcount(t1,0))
  writef("drawline2: %i6 instructions*n", instrcount(t2,0))
  writef("drawline3: %i6 instructions*n", instrcount(t3,0))
  RESULTIS 0
}

AND drawline1(x,y, x2,y2) BE
// This is Bresenham's algorithm
{ LET dx = x2-x
  AND dy = y2-y

  // Assume dx>=0,  dy>=0 and dx>=dy
  // need to deal with the other seven cases
  LET i1 = 2*dy    // >=0
  LET dd = i1-dx
  LET i2 = dd-dx   // <=0

  WHILE x<=x2 DO
  { //writef("%i3 %i3*n", x, y)
    TEST dd>=0
    THEN { dd := dd+i2; y := y+1} 
    ELSE { dd := dd+i1 }
    x := x+1
  }

}

AND drawline2(x,y, x2,y2) BE
{ LET dx = x2-x
  AND dy = y2-y

  // Assume dx>=0,  dy>=0 and dx>=dy
  LET d0 = 0
  LET d  = 0 

  WHILE x<=x2 DO
  { //writef("%i3 %i3*n", x, y)
    d := d+dy
    IF d-d0 >= d0+dx-d DO
    { d0 := d0+dx; y := y+1 } 
    x := x+1
  }
}

AND drawline3(x,y, x2,y2) BE
{ LET dx = x2-x
  AND dy = y2-y
  LET dx2, dy2 = 2*dx, 2*dy

  // Assume dx>=0,  dy>=0 and dx>=dy
  LET dd = dx-dy2
  LET i1 = dy2-dx2

  { //writef("%i3 %i3*n", x, y)
    TEST dd <= 0
    THEN { dd := dd-i1; y := y+1 } 
    ELSE { dd := dd-dy2 }
    x := x+1
  } REPEATWHILE x<=x2
}

AND t1(n) BE drawline1(0,0, 25, 19)
AND t2(n) BE drawline2(0,0, 25, 19)
AND t3(n) BE drawline3(0,0, 25, 19)

//AND t1(n) BE drawline1(0,0, 2500, 1900)
//AND t2(n) BE drawline2(0,0, 2500, 1900)
//AND t3(n) BE drawline3(0,0, 2500, 1900)
