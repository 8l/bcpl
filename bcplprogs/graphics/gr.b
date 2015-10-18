SECTION "GRAPHICS"

// This test the graphics features of the BCPL Cintcode system
// only available under Windows CE -- Now obsolete

GET "libhdr"

MANIFEST {
  gr_hide    = 3
  gr_show    = 4
  gr_cx      = 5
  gr_cy      = 6
  gr_bpr     = 7
  gr_display = 8
  gr_palette = 9
}

GLOBAL {
  prevx:200
  prevy:201
  colour:202
  cx:203
  cy:204
  bv:205
  bitmap:206
  fin:207
  prevdrawn:208
  bpr:209
}

LET start() = VALOF
{ LET count = 0

  writes("Graphics test*n")
  sys(34, gr_show)
  cx := sys(34, gr_cx)
  cy := sys(34, gr_cy)
  bpr := sys(34, gr_bpr)
  bitmap := getvec(cx*bpr/4 + 3)

  writef("cx=%n cy=%n bpr=%n*n", cx, cy, bpr)
  UNLESS bitmap DO {
    writef("Unable to allocate bitmap*n")
    RESULTIS 20
  }

  bv := bitmap + 3
  bitmap!0 := cx
  bitmap!1 := cy
  bitmap!2 := bpr

  FOR i = 0 TO bpr*cx-1 DO bv%i := (31 * (i REM bpr))/bpr
  sys(34, gr_display, bitmap)

  setcolour(0)
  moveto(30, 50)
  drawto(70, 100)
  sys(34, gr_display, bitmap)
  setcolour(1)
  drawto(30, 100)
  sys(34, gr_display, bitmap)

  moveto(randno(cx)/2, randno(cy)/2)

  FOR i = 1 TO 300 DO
  { LET x = randno(cx-1)
    AND y = randno(cy-1)
    IF (i&15)=0 DO
    { LET v = VEC 63
      FOR j = 0 TO 63 DO v!i := randno(#xFFFFFF)
      v!0 := #xFF0000
      v!1 := #x00FF00
      v!2 := #x0000FF
      v!3 := #xFFFF00
      v!4 := #xFF00FF
      v!5 := #x00FFFF
      v!6 := #xFFFFFF
      v!7 := #x000000
      sys(34, gr_palette, 64, v)
    }
    setcolour(i & 7)
    //writef("x=%i3 y=%i3 col=%n*n", x, y, colour)
    drawto(x, y)
    sys(34, gr_display, bitmap)
  } 
  freevec(bitmap)   
  RESULTIS 0
}

AND setcolour(col) BE colour := col

AND moveto(x, y) BE
  prevx, prevy, prevdrawn := x, y, FALSE

AND drawto(x, y) BE 
{ UNLESS prevdrawn DO
  { point(prevx, prevy)
    prevdrawn := TRUE
  }
 
  { LET mx = (x+prevx)>>1
    LET my = (y+prevy)>>1
    IF (mx=prevx | mx=x) & (my=prevy | my=y) BREAK
    drawto(mx, my)
  } REPEAT

  point(x, y)
}

AND point(x, y) BE
{ bv%(y*bpr+x) := colour
  prevx, prevy := x, y
}
