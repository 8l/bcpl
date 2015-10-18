GET "libhdr"

MANIFEST {
 x0 = #b00001111
 x1 = #b11110000
 y0 = #b00110011
 y1 = #b11001100
 z0 = #b01010101
 z1 = #b10101010
}

LET start() = VALOF
{ selectoutput(findoutput("NAMES"))

  A(x0)
  A(x1)
  A(y0)
  A(y1)
  A(z0)
  A(z1)

  AandB(x0, y0)
  AandB(x0, y1)
  AandB(x0, z0)
  AandB(x0, z1)
  AandB(x1, y0)
  AandB(x1, y1)
  AandB(x1, z0)
  AandB(x1, z1)
  AandB(y0, z0)
  AandB(y0, z1)
  AandB(y1, z0)
  AandB(y1, z1)

  AorB(x0, y0)
  AorB(x0, y1)
  AorB(x0, z0)
  AorB(x0, z1)
  AorB(x1, y0)
  AorB(x1, y1)
  AorB(x1, z0)
  AorB(x1, z1)
  AorB(y0, z0)
  AorB(y0, z1)
  AorB(y1, z0)
  AorB(y1, z1)

  AeqB(x0, y0)
  AeqB(x0, y1)
  AeqB(x0, z0)
  AeqB(x0, z1)
  AeqB(x1, y0)
  AeqB(x1, y1)
  AeqB(x1, z0)
  AeqB(x1, z1)
  AeqB(y0, z0)
  AeqB(y0, z1)
  AeqB(y1, z0)
  AeqB(y1, z1)

  AneqB(x0, y0)
  AneqB(x0, y1)
  AneqB(x0, z0)
  AneqB(x0, z1)
  AneqB(x1, y0)
  AneqB(x1, y1)
  AneqB(x1, z0)
  AneqB(x1, z1)
  AneqB(y0, z0)
  AneqB(y0, z1)
  AneqB(y1, z0)
  AneqB(y1, z1)

  AimpB(x0, y0)
  AimpB(x0, y1)
  AimpB(x0, z0)
  AimpB(x0, z1)
  AimpB(x1, y0)
  AimpB(x1, y1)
  AimpB(x1, z0)
  AimpB(x1, z1)
  AimpB(y0, x0)
  AimpB(y0, x1)
  AimpB(y0, z0)
  AimpB(y0, z1)
  AimpB(y1, x0)
  AimpB(y1, x1)
  AimpB(y1, z0)
  AimpB(y1, z1)
  AimpB(z0, x0)
  AimpB(z0, x1)
  AimpB(z0, y0)
  AimpB(z0, y1)
  AimpB(z1, x0)
  AimpB(z1, x1)
  AimpB(z1, y0)
  AimpB(z1, y1)

  AeqBandC(x0, y0, z0)
  AeqBandC(x0, y0, z1)
  AeqBandC(x0, y1, z0)
  AeqBandC(x0, y1, z1)
  AeqBandC(x1, y0, z0)
  AeqBandC(x1, y0, z1)
  AeqBandC(x1, y1, z0)
  AeqBandC(x1, y1, z1)
  AeqBandC(y0, x0, z0)
  AeqBandC(y0, x0, z1)
  AeqBandC(y0, x1, z0)
  AeqBandC(y0, x1, z1)
  AeqBandC(y1, x0, z0)
  AeqBandC(y1, x0, z1)
  AeqBandC(y1, x1, z0)
  AeqBandC(y1, x1, z1)
  AeqBandC(z0, x0, y0)
  AeqBandC(z0, x0, y1)
  AeqBandC(z0, x1, y0)
  AeqBandC(z0, x1, y1)
  AeqBandC(z1, x0, y0)
  AeqBandC(z1, x0, y1)
  AeqBandC(z1, x1, y0)
  AeqBandC(z1, x1, y1)

  AeqBorC(x0, y0, z0)
  AeqBorC(x0, y0, z1)
  AeqBorC(x0, y1, z0)
  AeqBorC(x0, y1, z1)
  AeqBorC(x1, y0, z0)
  AeqBorC(x1, y0, z1)
  AeqBorC(x1, y1, z0)
  AeqBorC(x1, y1, z1)
  AeqBorC(y0, x0, z0)
  AeqBorC(y0, x0, z1)
  AeqBorC(y0, x1, z0)
  AeqBorC(y0, x1, z1)
  AeqBorC(y1, x0, z0)
  AeqBorC(y1, x0, z1)
  AeqBorC(y1, x1, z0)
  AeqBorC(y1, x1, z1)
  AeqBorC(z0, x0, y0)
  AeqBorC(z0, x0, y1)
  AeqBorC(z0, x1, y0)
  AeqBorC(z0, x1, y1)
  AeqBorC(z1, x0, y0)
  AeqBorC(z1, x0, y1)
  AeqBorC(z1, x1, y0)
  AeqBorC(z1, x1, y1)

  AeqBeqC(x0, y0, z0)
  AeqBeqC(x0, y0, z1)
  AeqBeqC(x0, y1, z0)
  AeqBeqC(x0, y1, z1)
  AeqBeqC(x1, y0, z0)
  AeqBeqC(x1, y0, z1)
  AeqBeqC(x1, y1, z0)
  AeqBeqC(x1, y1, z1)
  AeqBeqC(y0, x0, z0)
  AeqBeqC(y0, x0, z1)
  AeqBeqC(y0, x1, z0)
  AeqBeqC(y0, x1, z1)
  AeqBeqC(y1, x0, z0)
  AeqBeqC(y1, x0, z1)
  AeqBeqC(y1, x1, z0)
  AeqBeqC(y1, x1, z1)
  AeqBeqC(z0, x0, y0)
  AeqBeqC(z0, x0, y1)
  AeqBeqC(z0, x1, y0)
  AeqBeqC(z0, x1, y1)
  AeqBeqC(z1, x0, y0)
  AeqBeqC(z1, x0, y1)
  AeqBeqC(z1, x1, y0)
  AeqBeqC(z1, x1, y1)

  AeqBneqC(x0, y0, z0)
  AeqBneqC(x0, y0, z1)
  AeqBneqC(x0, y1, z0)
  AeqBneqC(x0, y1, z1)
  AeqBneqC(x1, y0, z0)
  AeqBneqC(x1, y0, z1)
  AeqBneqC(x1, y1, z0)
  AeqBneqC(x1, y1, z1)
  AeqBneqC(y0, x0, z0)
  AeqBneqC(y0, x0, z1)
  AeqBneqC(y0, x1, z0)
  AeqBneqC(y0, x1, z1)
  AeqBneqC(y1, x0, z0)
  AeqBneqC(y1, x0, z1)
  AeqBneqC(y1, x1, z0)
  AeqBneqC(y1, x1, z1)
  AeqBneqC(z0, x0, y0)
  AeqBneqC(z0, x0, y1)
  AeqBneqC(z0, x1, y0)
  AeqBneqC(z0, x1, y1)
  AeqBneqC(z1, x0, y0)
  AeqBneqC(z1, x0, y1)
  AeqBneqC(z1, x1, y0)
  AeqBneqC(z1, x1, y1)

  AneqBeqC(x0, y0, z0)
  AneqBeqC(x0, y0, z1)
  AneqBeqC(x0, y1, z0)
  AneqBeqC(x0, y1, z1)
  AneqBeqC(x1, y0, z0)
  AneqBeqC(x1, y0, z1)
  AneqBeqC(x1, y1, z0)
  AneqBeqC(x1, y1, z1)
  AneqBeqC(y0, x0, z0)
  AneqBeqC(y0, x0, z1)
  AneqBeqC(y0, x1, z0)
  AneqBeqC(y0, x1, z1)
  AneqBeqC(y1, x0, z0)
  AneqBeqC(y1, x0, z1)
  AneqBeqC(y1, x1, z0)
  AneqBeqC(y1, x1, z1)
  AneqBeqC(z0, x0, y0)
  AneqBeqC(z0, x0, y1)
  AneqBeqC(z0, x1, y0)
  AneqBeqC(z0, x1, y1)
  AneqBeqC(z1, x0, y0)
  AneqBeqC(z1, x0, y1)
  AneqBeqC(z1, x1, y0)
  AneqBeqC(z1, x1, y1)

  AneqBneqC(x0, y0, z0)
  AneqBneqC(x0, y0, z1)
  AneqBneqC(x0, y1, z0)
  AneqBneqC(x0, y1, z1)
  AneqBneqC(x1, y0, z0)
  AneqBneqC(x1, y0, z1)
  AneqBneqC(x1, y1, z0)
  AneqBneqC(x1, y1, z1)
  AneqBneqC(y0, x0, z0)
  AneqBneqC(y0, x0, z1)
  AneqBneqC(y0, x1, z0)
  AneqBneqC(y0, x1, z1)
  AneqBneqC(y1, x0, z0)
  AneqBneqC(y1, x0, z1)
  AneqBneqC(y1, x1, z0)
  AneqBneqC(y1, x1, z1)
  AneqBneqC(z0, x0, y0)
  AneqBneqC(z0, x0, y1)
  AneqBneqC(z0, x1, y0)
  AneqBneqC(z0, x1, y1)
  AneqBneqC(z1, x0, y0)
  AneqBneqC(z1, x0, y1)
  AneqBneqC(z1, x1, y0)
  AneqBneqC(z1, x1, y1)

  AandBandC(x0, y0, z0)
  AandBandC(x0, y0, z1)
  AandBandC(x0, y1, z0)
  AandBandC(x0, y1, z1)
  AandBandC(x1, y0, z0)
  AandBandC(x1, y0, z1)
  AandBandC(x1, y1, z0)
  AandBandC(x1, y1, z1)

  AandBorC(x0, y0, z0)
  AandBorC(x0, y0, z1)
  AandBorC(x0, y1, z0)
  AandBorC(x0, y1, z1)
  AandBorC(x1, y0, z0)
  AandBorC(x1, y0, z1)
  AandBorC(x1, y1, z0)
  AandBorC(x1, y1, z1)
  AandBorC(y0, x0, z0)
  AandBorC(y0, x0, z1)
  AandBorC(y0, x1, z0)
  AandBorC(y0, x1, z1)
  AandBorC(y1, x0, z0)
  AandBorC(y1, x0, z1)
  AandBorC(y1, x1, z0)
  AandBorC(y1, x1, z1)
  AandBorC(z0, x0, y0)
  AandBorC(z0, x0, y1)
  AandBorC(z0, x1, y0)
  AandBorC(z0, x1, y1)
  AandBorC(z1, x0, y0)
  AandBorC(z1, x0, y1)
  AandBorC(z1, x1, y0)
  AandBorC(z1, x1, y1)

  AorBandC(x0, y0, z0)
  AorBandC(x0, y0, z1)
  AorBandC(x0, y1, z0)
  AorBandC(x0, y1, z1)
  AorBandC(x1, y0, z0)
  AorBandC(x1, y0, z1)
  AorBandC(x1, y1, z0)
  AorBandC(x1, y1, z1)
  AorBandC(y0, x0, z0)
  AorBandC(y0, x0, z1)
  AorBandC(y0, x1, z0)
  AorBandC(y0, x1, z1)
  AorBandC(y1, x0, z0)
  AorBandC(y1, x0, z1)
  AorBandC(y1, x1, z0)
  AorBandC(y1, x1, z1)
  AorBandC(z0, x0, y0)
  AorBandC(z0, x0, y1)
  AorBandC(z0, x1, y0)
  AorBandC(z0, x1, y1)
  AorBandC(z1, x0, y0)
  AorBandC(z1, x0, y1)
  AorBandC(z1, x1, y0)
  AorBandC(z1, x1, y1)

  AandBeqC(x0, y0, z0)
  AandBeqC(x0, y0, z1)
  AandBeqC(x0, y1, z0)
  AandBeqC(x0, y1, z1)
  AandBeqC(x1, y0, z0)
  AandBeqC(x1, y0, z1)
  AandBeqC(x1, y1, z0)
  AandBeqC(x1, y1, z1)
  AandBeqC(y0, x0, z0)
  AandBeqC(y0, x0, z1)
  AandBeqC(y0, x1, z0)
  AandBeqC(y0, x1, z1)
  AandBeqC(y1, x0, z0)
  AandBeqC(y1, x0, z1)
  AandBeqC(y1, x1, z0)
  AandBeqC(y1, x1, z1)
  AandBeqC(z0, x0, y0)
  AandBeqC(z0, x0, y1)
  AandBeqC(z0, x1, y0)
  AandBeqC(z0, x1, y1)
  AandBeqC(z1, x0, y0)
  AandBeqC(z1, x0, y1)
  AandBeqC(z1, x1, y0)
  AandBeqC(z1, x1, y1)

  AandBneqC(x0, y0, z0)
  AandBneqC(x0, y0, z1)
  AandBneqC(x0, y1, z0)
  AandBneqC(x0, y1, z1)
  AandBneqC(x1, y0, z0)
  AandBneqC(x1, y0, z1)
  AandBneqC(x1, y1, z0)
  AandBneqC(x1, y1, z1)
  AandBneqC(y0, x0, z0)
  AandBneqC(y0, x0, z1)
  AandBneqC(y0, x1, z0)
  AandBneqC(y0, x1, z1)
  AandBneqC(y1, x0, z0)
  AandBneqC(y1, x0, z1)
  AandBneqC(y1, x1, z0)
  AandBneqC(y1, x1, z1)
  AandBneqC(z0, x0, y0)
  AandBneqC(z0, x0, y1)
  AandBneqC(z0, x1, y0)
  AandBneqC(z0, x1, y1)
  AandBneqC(z1, x0, y0)
  AandBneqC(z1, x0, y1)
  AandBneqC(z1, x1, y0)
  AandBneqC(z1, x1, y1)

  AorBeqC(x0, y0, z0)
  AorBeqC(x0, y0, z1)
  AorBeqC(x0, y1, z0)
  AorBeqC(x0, y1, z1)
  AorBeqC(x1, y0, z0)
  AorBeqC(x1, y0, z1)
  AorBeqC(x1, y1, z0)
  AorBeqC(x1, y1, z1)
  AorBeqC(y0, x0, z0)
  AorBeqC(y0, x0, z1)
  AorBeqC(y0, x1, z0)
  AorBeqC(y0, x1, z1)
  AorBeqC(y1, x0, z0)
  AorBeqC(y1, x0, z1)
  AorBeqC(y1, x1, z0)
  AorBeqC(y1, x1, z1)
  AorBeqC(z0, x0, y0)
  AorBeqC(z0, x0, y1)
  AorBeqC(z0, x1, y0)
  AorBeqC(z0, x1, y1)
  AorBeqC(z1, x0, y0)
  AorBeqC(z1, x0, y1)
  AorBeqC(z1, x1, y0)
  AorBeqC(z1, x1, y1)

  AorBneqC(x0, y0, z0)
  AorBneqC(x0, y0, z1)
  AorBneqC(x0, y1, z0)
  AorBneqC(x0, y1, z1)
  AorBneqC(x1, y0, z0)
  AorBneqC(x1, y0, z1)
  AorBneqC(x1, y1, z0)
  AorBneqC(x1, y1, z1)
  AorBneqC(y0, x0, z0)
  AorBneqC(y0, x0, z1)
  AorBneqC(y0, x1, z0)
  AorBneqC(y0, x1, z1)
  AorBneqC(y1, x0, z0)
  AorBneqC(y1, x0, z1)
  AorBneqC(y1, x1, z0)
  AorBneqC(y1, x1, z1)
  AorBneqC(z0, x0, y0)
  AorBneqC(z0, x0, y1)
  AorBneqC(z0, x1, y0)
  AorBneqC(z0, x1, y1)
  AorBneqC(z1, x0, y0)
  AorBneqC(z1, x0, y1)
  AorBneqC(z1, x1, y0)
  AorBneqC(z1, x1, y1)

  AorBorC(x0, y0, z0)
  AorBorC(x0, y0, z1)
  AorBorC(x0, y1, z0)
  AorBorC(x0, y1, z1)
  AorBorC(x1, y0, z0)
  AorBorC(x1, y0, z1)
  AorBorC(x1, y1, z0)
  AorBorC(x1, y1, z1)

  endwrite()
  RESULTIS 0
}

AND str(a) = VALOF SWITCHON a INTO
{ DEFAULT:   RESULTIS "?"
  CASE x0:   RESULTIS "~x"
  CASE x1:   RESULTIS "x"
  CASE y0:   RESULTIS "~y"
  CASE y1:   RESULTIS "y"
  CASE z0:   RESULTIS "~z"
  CASE z1:   RESULTIS "z"
}

AND A(a) BE
  writef("  CASE #b%b8: RESULTIS *"%s*"*n",
          a, str(a))

AND AandB(a, b) BE
  writef("  CASE #b%b8: RESULTIS *"%s&%s*"*n",
          a & b, str(a), str(b))

AND AorB(a, b) BE
  writef("  CASE #b%b8: RESULTIS *"%s|%s*"*n",
          a | b, str(a), str(b))

AND AeqB(a, b) BE
  writef("  CASE #b%b8: RESULTIS *"%s=%s*"*n",
          a EQV b, str(a), str(b))

AND AneqB(a, b) BE
  writef("  CASE #b%b8: RESULTIS *"%s#%s*"*n",
          a XOR b, str(a), str(b))

AND AimpB(a, b) BE
  writef("  CASE #b%b8: RESULTIS *"%s->%s*"*n",
          ~a | b, str(a), str(b))

AND AeqBandC(a, b, c) BE
  writef("  CASE #b%b8: RESULTIS *"%s=(%s&%s)*"*n",
          a EQV (b&c), str(a), str(b), str(c))

AND AneqBandC(a, b, c) BE
  writef("  CASE #b%b8: RESULTIS *"%s#(%s&%s)*"*n",
          a XOR (b&c), str(a), str(b), str(c))

AND AeqBorC(a, b, c) BE
  writef("  CASE #b%b8: RESULTIS *"%s=(%s|%s)*"*n",
          a EQV (b|c), str(a), str(b), str(c))

AND AneqBorC(a, b, c) BE
  writef("  CASE #b%b8: RESULTIS *"%s#(%s|%s)*"*n",
          a XOR (b|c), str(a), str(b), str(c))

AND AeqBeqC(a, b, c) BE
  writef("  CASE #b%b8: RESULTIS *"%s=(%s=%s)*"*n",
          a EQV (b EQV c), str(a), str(b), str(c))

AND AneqBeqC(a, b, c) BE
  writef("  CASE #b%b8: RESULTIS *"%s#(%s=%s)*"*n",
          a XOR (b EQV c), str(a), str(b), str(c))

AND AeqBneqC(a, b, c) BE
  writef("  CASE #b%b8: RESULTIS *"%s=(%s#%s)*"*n",
          a EQV (b XOR c), str(a), str(b), str(c))

AND AneqBneqC(a, b, c) BE
  writef("  CASE #b%b8: RESULTIS *"%s#%s#%s*"*n",
          a XOR (b XOR c), str(a), str(b), str(c))

AND AandBandC(a, b, c) BE
  writef("  CASE #b%b8: RESULTIS *"%s&%s&%s*"*n",
          a&b&c, str(a), str(b), str(c))

AND AandBorC(a, b, c) BE
  writef("  CASE #b%b8: RESULTIS *"%s&(%s|%s)*"*n",
          a&(b|c), str(a), str(b), str(c))

AND AandBeqC(a, b, c) BE
  writef("  CASE #b%b8: RESULTIS *"%s&(%s=%s)*"*n",
          a&(b EQV c), str(a), str(b), str(c))

AND AandBneqC(a, b, c) BE
  writef("  CASE #b%b8: RESULTIS *"%s&(%s#%s)*"*n",
          a&(b XOR c), str(a), str(b), str(c))

AND AorBandC(a, b, c) BE
  writef("  CASE #b%b8: RESULTIS *"%s|(%s&%s)*"*n",
          a|(b&c), str(a), str(b), str(c))

AND AorBorC(a, b, c) BE
  writef("  CASE #b%b8: RESULTIS *"%s|%s|%s*"*n",
          a|b|c, str(a), str(b), str(c))

AND AorBeqC(a, b, c) BE
  writef("  CASE #b%b8: RESULTIS *"%s|(%s=%s)*"*n",
          a|(b EQV c), str(a), str(b), str(c))

AND AorBneqC(a, b, c) BE
  writef("  CASE #b%b8: RESULTIS *"%s|(%s#%s)*"*n",
          a|(b XOR c), str(a), str(b), str(c))













