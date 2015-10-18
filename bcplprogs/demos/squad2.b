/*
This is a implementation of the firing squad problem deduced from
the image: http://mathworld.wolfram.com/fimg1392.gif

The BCPL implemention is by Martin Richards

Ref:

Eric W. Weisstein, "Firing Squad Problem." From MatthWorld -- A Wolfram
Web Resource. http://mathworld.wolfram.com/FiringSquadProblem.html
*/

GET "libhdr"

MANIFEST { upb = 1000 }
 
GLOBAL { rulev: ug }

LET start() = VALOF
{ LET v = VEC upb
  AND n = 50
  LET argv = VEC 20

  UNLESS rdargs("N", argv, 20) DO
  { writes("Bad arguments for SQUAD*n")
    RESULTIS 20
  }
  UNLESS argv!0=0 DO n := str2numb(argv!0)

  UNLESS 1<=n<=upb DO
  { writef("The number of soldiers must be between 1 and %n*n", upb)
    RESULTIS 0
  }

  writef("*nFiring squad solution for %i2 soldier%-%ps*n*n", n)
  squad(v, n+2)
  RESULTIS 0
}
 
AND squad(v, n) BE
{ LET count = 0
  initrules()
  FOR i = 0 TO n+1 DO v!i := 0
  v!1, v!2, v!n := 5, 1, 5

  { LET p, a, b, c = 0, ?, v!0, v!1
    LET error = FALSE
    LET t = TABLE ' ', '1', '2', '3', 'X', '|', '**', '7',
                  '8', '9', 'A', 'B', 'C', 'D', 'E', '?'
    //LET t = TABLE '0', '1', '2', '3', '4', '5', '6', '7',
    //              '8', '9', 'A', 'B', 'C', 'D', 'E', '?'
    writef("%i3: ", count)
    count := count+1
    FOR i = 1 TO n DO
    { LET val = v!i
      writef("%c", t!val)
      IF val=#xF DO error := TRUE
    }
    newline()
    IF v!2=6 | error BREAK
    UNTIL p=n DO
    { p := p+1
      a := b
      b := c
      c := v!(p+1)
      v!p := func(a, b, c)
    }
  } REPEAT
 
  newline()
  closerules()
}

AND setrule(abc, val) BE
{ UNLESS rulev!abc = #xF DO
    writef("Error: rule #x%x3 => %x1 and %x1*n", abc, rulev!abc, val)
  rulev!abc := val
}

AND initrules() BE
{ rulev := getvec(#xFFF)
  FOR i = 0 TO #xFFF DO rulev!i := #xF

  setrule(#x051, 5)
  setrule(#x510, 3)
  setrule(#x100, 2)
  setrule(#x000, 0)
  setrule(#x005, 0)
  setrule(#x050, 5)
  setrule(#x053, 5)
  setrule(#x532, 1)
  setrule(#x320, 4)
  setrule(#x200, 3)
  setrule(#x514, 1)
  setrule(#x143, 2)
  setrule(#x430, 1)
  setrule(#x300, 1)
  setrule(#x512, 1)
  setrule(#x121, 4)
  setrule(#x211, 3)
  setrule(#x110, 4)
  setrule(#x434, 1)
  setrule(#x342, 0)
  setrule(#x420, 2)
  setrule(#x102, 0)
  setrule(#x230, 3)
  setrule(#x210, 3)
  setrule(#x023, 3)
  setrule(#x303, 0)
  setrule(#x033, 3)
  setrule(#x331, 4)
  setrule(#x310, 4)
  setrule(#x103, 0)
  setrule(#x034, 0)
  setrule(#x344, 4)
  setrule(#x442, 2)
  setrule(#x004, 0)
  setrule(#x042, 0)
  setrule(#x422, 2)
  setrule(#x223, 3)
  setrule(#x305, 2)
  setrule(#x002, 0)
  setrule(#x233, 3)
  setrule(#x332, 2)
  setrule(#x325, 4)
  setrule(#x250, 5)
  setrule(#x203, 0)
  setrule(#x324, 4)
  setrule(#x245, 0)
  setrule(#x450, 5)
  setrule(#x020, 2)
  setrule(#x032, 1)
  setrule(#x240, 0)
  setrule(#x405, 0)
  setrule(#x302, 0)
  setrule(#x201, 1)
  setrule(#x014, 1)
  setrule(#x140, 2)
  setrule(#x400, 0)
  setrule(#x021, 1)
  setrule(#x112, 1)
  setrule(#x120, 4)
  setrule(#x301, 2)
  setrule(#x013, 1)
  setrule(#x131, 2)
  setrule(#x314, 1)
  setrule(#x212, 1)
  setrule(#x125, 4)
  setrule(#x141, 1)
  setrule(#x414, 1)
  setrule(#x145, 1)
  setrule(#x511, 6)
  setrule(#x111, 6)
  setrule(#x115, 6)
  setrule(#x150, 5)
  setrule(#x334, 4)
  setrule(#x440, 1)
  setrule(#x403, 0)
  setrule(#x041, 4)
  setrule(#x410, 4)
  setrule(#x104, 0)
  setrule(#x044, 4)
  setrule(#x340, 1)
  setrule(#x404, 0)
  setrule(#x330, 3)
  setrule(#x333, 3)
  setrule(#x220, 2)
  setrule(#x222, 2)
  setrule(#x022, 2)
  setrule(#x402, 0)
  setrule(#x441, 4)
  setrule(#x444, 4)
  setrule(#x204, 0)
  setrule(#x321, 4)
  setrule(#x202, 0)
  setrule(#x241, 0)
  setrule(#x401, 0)
  setrule(#x012, 1)
  setrule(#x001, 0)
  setrule(#x205, 1)
  setrule(#x221, 4)
  setrule(#x215, 3)
  setrule(#x024, 1)
  setrule(#x243, 3)
  setrule(#x435, 2)
  setrule(#x350, 5)
  setrule(#x132, 2)
  setrule(#x124, 4)
  setrule(#x415, 1)
  setrule(#x304, 0)
  setrule(#x224, 4)
  setrule(#x432, 2)
  setrule(#x105, 3)
  setrule(#x431, 2)
  setrule(#x101, 3)
  setrule(#x443, 3)
  setrule(#x312, 1)
  setrule(#x214, 1)
  setrule(#x412, 1)
  setrule(#x043, 1)
  setrule(#x114, 1)
  setrule(#x343, 4)
  setrule(#x135, 2)
  setrule(#x142, 4)
  setrule(#x421, 1)
  setrule(#x411, 1)
  setrule(#x533, 6)
  setrule(#x335, 6)
  setrule(#x425, 1)
  setrule(#x515, 6)
}

AND closerules() BE IF rulev DO freevec(rulev)

AND func(a, b, c) = VALOF
{ LET i = a<<8 | b<<4 | c
  RESULTIS rulev!i
}

/*
0> squadf 50

Firing squad solution for 50 soldiers

  0: |1                                                 |
  1: |32                                                |
  2: |1X3                                               |
  3: |1211                                              |
  4: |1X3X2                                             |
  5: |121 23                                            |
  6: |1X3 331                                           |
  7: |121 3XX2                                          |
  8: |1X3  X223                                         |
  9: |1211  2331                                        |
 10: |1X3X2 33XX2                                       |
 11: |121 2 3XX223                                      |
 12: |1X3 2  X22331                                     |
 13: |121 23  233XX2                                    |
 14: |1X3 331 33XX223                                   |
 15: |121 3XX 3XX22331                                  |
 16: |1X3  X1  X2233XX2                                 |
 17: |1211 XX2  233XX223                                |
 18: |1X3X X223 33XX22331                               |
 19: |1211  233 3XX2233XX2                              |
 20: |1X3X2 333  X2233XX223                             |
 21: |121 2 3331  233XX22331                            |
 22: |1X3 2 33XX2 33XX2233XX2                           |
 23: |121 2 3XX22 3XX2233XX223                          |
 24: |1X3 2  X222  X2233XX22331                         |
 25: |121 23  2223  233XX2233XX2                        |
 26: |1X3 331 22331 33XX2233XX223                       |
 27: |121 3XX 233XX 3XX2233XX22331                      |
 28: |1X3  X1 33XX1  X2233XX2233XX2                     |
 29: |1211 XX 3XXXX2  233XX2233XX223                    |
 30: |1X3X X1  XXX223 33XX2233XX22331                   |
 31: |1211 XX2 XX2233 3XX2233XX2233XX2                  |
 32: |1X3X X22 X22333  X2233XX2233XX223                 |
 33: |1211  22  233331  233XX2233XX22331                |
 34: |1X3X2 223 3333XX2 33XX2233XX2233XX2               |
 35: |121 2 233 333XX22 3XX2233XX2233XX223              |
 36: |1X3 2 333 33XX222  X2233XX2233XX22331             |
 37: |121 2 333 3XX22223  233XX2233XX2233XX2            |
 38: |1X3 2 333  X2222331 33XX2233XX2233XX223           |
 39: |121 2 3331  22233XX 3XX2233XX2233XX22331          |
 40: |1X3 2 33XX2 2233XX1  X2233XX2233XX2233XX2         |
 41: |121 2 3XX22 233XXXX2  233XX2233XX2233XX223        |
 42: |1X3 2  X222 33XXXX223 33XX2233XX2233XX22331       |
 43: |121 23  222 3XXXX2233 3XX2233XX2233XX2233XX2      |
 44: |1X3 331 222  XXX22333  X2233XX2233XX2233XX223     |
 45: |121 3XX 2223 XX2233331  233XX2233XX2233XX22331    |
 46: |1X3  X1 2233 X223333XX2 33XX2233XX2233XX2233XX2   |
 47: |1211 XX 2333  23333XX22 3XX2233XX2233XX2233XX223  |
 48: |1X3X X1 33331 3333XX222  X2233XX2233XX2233XX22331 |
 49: |1211 XX 333XX 333XX22223  233XX2233XX2233XX2233XX3|
 50: |1X3X X1 33XX1 33XX2222331 33XX2233XX2233XX2233XX32|
 51: |1211 XX 3XXXX 3XX222233XX 3XX2233XX2233XX2233XX32X|
 52: |1X3X X1  XXX1  X222233XX1  X2233XX2233XX2233XX32X |
 53: |1211 XX2 XXXX2  22233XXXX2  233XX2233XX2233XX32X  |
 54: |1X3X X22 XXX223 2233XXXX223 33XX2233XX2233XX32X   |
 55: |1211  22 XX2233 233XXXX2233 3XX2233XX2233XX32X    |
 56: |1X3X2 22 X22333 33XXXX22333  X2233XX2233XX32X     |
 57: |121 2 22  23333 3XXXX2233331  233XX2233XX32X      |
 58: |1X3 2 223 33333  XXX223333XX2 33XX2233XX32X       |
 59: |121 2 233 333331 XX223333XX22 3XX2233XX32X        |
 60: |1X3 2 333 3333XX X223333XX222  X2233XX32X         |
 61: |121 2 333 333XX1  23333XX22223  233XX32X          |
 62: |1X3 2 333 33XXXX2 3333XX2222331 33XX32X           |
 63: |121 2 333 3XXXX22 333XX222233XX 3XX32X            |
 64: |1X3 2 333  XXX222 33XX222233XX1  X32X             |
 65: |121 2 3331 XX2222 3XX222233XXXX2 12X              |
 66: |1X3 2 33XX X22222  X222233XXXX2211X               |
 67: |121 2 3XX1  222223  22233XXXX22X312               |
 68: |1X3 2  XXX2 2222331 2233XXXX22X321X3              |
 69: |121 23 XX22 22233XX 233XXXX22X32X1211             |
 70: |1X3 33 X222 2233XX1 33XXXX22X32X 1X3X2            |
 71: |121 33  222 233XXXX 3XXXX22X32X  121 23           |
 72: |1X3 331 222 33XXXX1  XXX22X32X   1X3 331          |
 73: |121 3XX 222 3XXXXXX2 XX22X32X    121 3XX2         |
 74: |1X3  X1 222  XXXXX22 X22X32X     1X3  X223        |
 75: |1211 XX 2223 XXXX222  2X32X      1211  2331       |
 76: |1X3X X1 2233 XXX22223 132X       1X3X2 33XX2      |
 77: |1211 XX 2333 XX222233212X        121 2 3XX223     |
 78: |1X3X X1 3333 X2222332X1X         1X3 2  X22331    |
 79: |1211 XX 3333  222332X 12         121 23  233XX2   |
 80: |1X3X X1 33331 22332X  1X3        1X3 331 33XX223  |
 81: |1211 XX 333XX 2332X   1211       121 3XX 3XX22331 |
 82: |1X3X X1 33XX1 332X    1X3X2      1X3  X1  X2233XX3|
 83: |1211 XX 3XXXX 32X     121 23     1211 XX2  233XX32|
 84: |1X3X X1  XXX1 1X      1X3 331    1X3X X223 33XX32X|
 85: |1211 XX2 XXXX312      121 3XX2   1211  233 3XX32X |
 86: |1X3X X22 XXX321X3     1X3  X223  1X3X2 333  X32X  |
 87: |1211  22 XX32X1211    1211  2331 121 2 3331 12X   |
 88: |1X3X2 22 X32X 1X3X2   1X3X2 33XX31X3 2 33XX31X    |
 89: |121 2 22 12X  121 23  121 2 3XX32121 2 3XX3212    |
 90: |1X3 2 2211X   1X3 331 1X3 2  X32X1X3 2  X32X1X3   |
 91: |121 2 2X312   121 3XX3121 23 12X 121 23 12X 1211  |
 92: |1X3 2 1321X3  1X3  X321X3 3321X  1X3 3321X  1X3X2 |
 93: |121 2112X1211 1211 12X121 32X12  121 32X12  121 21|
 94: |1X3 131X 1X3X31X3X31X 1X3 1X 1X3 1X3 1X 1X3 1X3 13|
 95: |12121212 121X2121X212 121212 1212121212 1212121212|
 96: |1X1X1X1X11X1X11X1X11X11X1X1X11X1X1X1X1X11X1X1X1X1X|
 97: |11111111111111111111111111111111111111111111111111|
 98: |**************************************************|

30>
*/
 
