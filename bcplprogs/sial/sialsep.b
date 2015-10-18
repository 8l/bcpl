// This program separates an Sial file into its
// eleven streams.

// Implemented by Martin Richards (c) August 2007

GET "libhdr"

GET "sial.h"

GLOBAL {
  fstr: 200
  pstr: 201
  gstr: 202
  kstr: 203
  nstr: 204
  rstr: 205
  wstr: 206
  cstr: 207
  tstr: 208
  lstr: 209
  mstr: 210

  infile: 220

  bining: 221
}

LET start() = VALOF
{ LET argv = VEC 50
  LET sialfile = "bcpl.sial"
  LET stdin = input()
  LET stdout = output()
  LET modno = 0
  LET curmod = 0

  IF rdargs("FROM,M/K,BIN/S", argv, 50)=0 DO
  { writes("Bad arguments for sialsep*n")
    RESULTIS 10
  }

  TEST argv!0
  THEN sialfile := argv!0
  ELSE sialfile := "bcpl.sial"

  TEST argv!1 THEN modno := str2numb(argv!1)
              ELSE modno := 0

  bining := argv!2

  infile := findinput(sialfile)

  IF infile=0 DO
  { writef("Can't open file: %s*n", sialfile)
    RESULTIS 10
  }

  fstr := findoutput("Fstr")
  pstr := findoutput("Pstr")
  gstr := findoutput("Gstr")
  kstr := findoutput("Kstr")
  nstr := findoutput("Nstr")
  rstr := findoutput("Rstr")
  wstr := findoutput("Wstr")
  cstr := findoutput("Cstr")
  tstr := findoutput("Tstr")
  lstr := findoutput("Lstr")
  mstr := findoutput("Mstr")

  UNLESS fstr & pstr & gstr & kstr & nstr & rstr &
         wstr & cstr & tstr & lstr & mstr DO 
  { writes("Trouble with an output file*n")
    RESULTIS 10
  }

  selectinput(infile)

  { LET ch = rdch()
    LET val = ?

    IF ch=' ' | ch='*n' LOOP
    IF ch=endstreamch BREAK

    val := readn()

    SWITCHON ch INTO
    { DEFAULT:  abort(1000)
      CASE 'F': IF val=f_modstart DO curmod := curmod + 1
                selectoutput(fstr); ENDCASE
      CASE 'P': selectoutput(pstr); ENDCASE
      CASE 'G': selectoutput(gstr); ENDCASE
      CASE 'K': selectoutput(kstr); ENDCASE
      CASE 'N': selectoutput(nstr); ENDCASE
      CASE 'R': selectoutput(rstr); ENDCASE
      CASE 'W': selectoutput(wstr); ENDCASE
      CASE 'C': selectoutput(cstr); ENDCASE
      CASE 'T': selectoutput(tstr); ENDCASE
      CASE 'L': selectoutput(lstr); ENDCASE
      CASE 'M': selectoutput(mstr); ENDCASE
    }

    IF modno=0 | modno=curmod TEST bining
    THEN wrbytes(val)
    ELSE writef("%n*n", val)
  } REPEAT

  endread()
  selectoutput(fstr); endwrite()
  selectoutput(pstr); endwrite()
  selectoutput(gstr); endwrite()
  selectoutput(kstr); endwrite()
  selectoutput(nstr); endwrite()
  selectoutput(rstr); endwrite()
  selectoutput(wstr); endwrite()
  selectoutput(cstr); endwrite()
  selectoutput(tstr); endwrite()
  selectoutput(lstr); endwrite()
  selectoutput(mstr); endwrite()

  selectinput(stdin)
  selectoutput(stdout)
  writef("Splitting of file %s complete*n", sialfile)
  RESULTIS 0
}

AND wrbytes(w) BE
{ wrch(w); RETURN
UNTIL -10<=w<224-10 DO { wrch(224+(w&31)); w := w/32 } 
  wrch(w+10)
}

