SECTION "GRAPHICS"

// This test the graphics features of the BCPL Cintcode system
// only available under Windows CE -- Now obsolete

GET "libhdr"

MANIFEST {
  gr_hide    = 3
  gr_show    = 4
  gr_cx      = 5
  gr_cy      = 6
  gr_size    = 7
  gr_display = 8
}

LET start() = VALOF
{ LET cx = 0
  LET cy = 0
  LET size = 0
  LET bitmap = 0
  LET count = 0

  writes("Graphics test*n")
  sys(34, gr_show)
  cx := sys(34, gr_cx)
  cy := sys(34, gr_cy)
  size := sys(34, gr_size)
  bitmap := getvec(size/4 + 3)

  writef("cx=%n cy=%n size=%n*n", cx, cy, size)
  UNLESS bitmap DO {
    writef("Unable to allocate bitmap*n")
    RESULTIS 20
  }
  FOR i = 1 TO 10 DO
  { LET b = bitmap + 3
    bitmap!0 := cx
    bitmap!1 := cy
    bitmap!2 := size
    FOR i = 0 TO size-1 DO b%i := ((i>>3)+count) & 7
    //writef("Display bits %n*n", count)
    sys(34, gr_display, bitmap)
    count := count+1
  }  
   freevec(bitmap)   
  RESULTIS 0
}
