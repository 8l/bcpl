GET "libhdr"

LET start() = VALOF
{ LET rastfile = findoutput("RASTER")
  LET fhilim = 34000000
  LET mhilim = 210000
  LET kval, sval = 10000, 40
  LET datalines = fhilim/kval
  LET bsize = datalines/20
  LET Ylen = mhilim/sval

  selectoutput(rastfile)
  writef("K%n S%n*n", kval, sval)
  FOR i = 1 TO datalines DO 
  { LET w = i * Ylen / datalines
    LET b = i REM bsize
    writef("W%nB%nN*n", w, ((Ylen/20)*b)/bsize+1)
  }
  endwrite()
}