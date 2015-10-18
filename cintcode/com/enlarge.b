// (C) Copyright 1979 Tripos Research Group
//     University of Cambridge
//     Computer Laboratory

// Program to display text as large characters
// Author: Brian Knight  14 Feb 79
//
// Table of styles created by:
//   Martyn Johnson
//   Carl Dellar
//   Paul Bond

// Can be CALLSEGed or used as a command
SECTION "Enlarge"

GET "libhdr"

MANIFEST { maxchars = 8 /* For vdu */ }


LET start(s) BE
{ LET argv = VEC 50
  LET outstream = 0
  LET ch = ?

  IF s DO
  { // Program was called from CALLSEG
    enlarge(s)
    RETURN
  }

  ch := rdch()
  WHILE ch=' ' DO ch := rdch()
  TEST ch = '?'
  THEN { enlarge("/a,to/k:")
         UNTIL ch='*n' | ch='*e' | ch=endstreamch DO ch := rdch()
       }
  ELSE unrdch()

  UNLESS rdargs("/a,to/k", argv, 50) DO
  { enlarge("Bad args")
    stop(20)
  }

  IF argv!1 DO
  { // Output file specified
    outstream := findoutput(argv!1)
    UNLESS outstream DO
    { writef("Can't open %S for output*N", argv!1)
      stop(20)
    }
    selectoutput(outstream)
  }

  enlarge(argv!0)

  IF outstream DO endwrite()
}


AND enlarge(s) BE
{ LET len = s%0<maxchars -> s%0, maxchars
  LET offset = (maxchars - len) * 5

  FOR line = 0 TO 7 DO
  { FOR m=1 TO offset DO wrch(' ')
    FOR n=1 TO len DO
    { wrch(' ')
      write_ch_slice(s%n, line)
      wrch(' ')
    }
    newline()
  }
}


AND write_ch_slice(ch, line) BE
{
  // Writes the horizontal slice consisting
  // of the given line of character ch.

  LET c = ch<'*S' -> '*S', ch
  LET charbase = ((c & #X7F) - '*S') * 4 +
        TABLE
         #X0000, #X0000, #X0000, #X0000, // space
         #X0000, #X00DF, #XDF00, #X0000, // !
         #X0007, #X0700, #X0007, #X0700, // "
         #X2424, #XFF24, #X24FF, #X2424, // #
         #X4689, #X89FF, #XFF89, #X8972, // $
         #X8046, #X2610, #X0864, #X6201, // %
         #X42A5, #X9189, #X5125, #X4280, // &
         #X0000, #X0007, #X0700, #X0000, // '
         #X0000, #X0000, #X3C7E, #XC300, // (
         #X00C3, #X7E3C, #X0000, #X0000, // )
         #X004A, #X2C18, #X7E18, #X2C4A, // *
         #X0008, #X0808, #X7E08, #X0808, // +
         #X0060, #XE000, #X0000, #X0000, // ,
         #X0008, #X0808, #X0808, #X0808, // -
         #X00C0, #XC000, #X0000, #X0000, // .
         #X4060, #X3018, #X0804, #X0602, // /
         #X3C7E, #XC3C3, #XC3C3, #X7E3C, // 0
         #X0004, #X06FF, #XFF00, #X0000, // 1
         #X84C6, #XC3E3, #XE3D3, #XDECC, // 2
         #X2466, #XC3CB, #XCBCB, #X7E3C, // 3
         #X080C, #X0E0B, #XFFFF, #X0808, // 4
         #X2F6F, #XCBCB, #XCBCB, #X7B33, // 5
         #X3E7F, #XCBCB, #XCBCB, #X7B32, // 6
         #X0383, #XC363, #X331B, #X0F07, // 7
         #X76FF, #XCBCB, #XCBCB, #XFF76, // 8
         #X44CE, #XCBCB, #XCBCB, #XFE7C, // 9
         #X0000, #X00D8, #XD800, #X0000, // :
         #X0000, #X0058, #XD800, #X0000, // ;
         #X0000, #X0810, #X2442, #X8100, // <
         #X0028, #X2828, #X2828, #X2828, // =
         #X0081, #X4224, #X1008, #X0000, // >
         #X0203, #X03DB, #XDB0B, #X0F06, // ?
         #X7E81, #X99A5, #XA5BD, #XA1BE, // @
         #XFCFE, #X0B0B, #X0B0B, #XFEFC, // A
         #XFFFF, #XCBCB, #XCBCB, #XFF76, // B
         #X3C7E, #XC3C3, #XC3C3, #XC342, // C
         #XFFFF, #XC3C3, #XC3C3, #X7E3C, // D
         #XFFFF, #XCBCB, #XCBCB, #XC3C3, // E
         #XFFFF, #X0B0B, #X0B0B, #X0303, // F
         #X7EFF, #XC3C3, #XCBCB, #XFB7A, // G
         #XFFFF, #X0808, #X0808, #XFFFF, // H
         #XC3C3, #XC3FF, #XFFC3, #XC3C3, // I
         #XC3C3, #XC3FF, #X7F03, #X0303, // J
         #XFFFF, #X0818, #X3466, #XC381, // K
         #XFFFF, #XC0C0, #XC0C0, #XC0C0, // L
         #XFFFF, #X060C, #X0C06, #XFFFF, // M
         #XFFFF, #X060C, #X3870, #XFFFF, // N
         #X7EFF, #XC3C3, #XC3C3, #XFF7E, // O
         #XFFFF, #X0B0B, #X0B0B, #X0F06, // P
         #X7EFF, #XC3C3, #XD3E3, #X7FBE, // Q
         #XFFFF, #X1B1B, #X3B7B, #XDF8E, // R
         #X4ECF, #XCBCB, #XCBCB, #XFB72, // S
         #X0303, #X03FF, #XFF03, #X0303, // T
         #X7FFF, #XC0C0, #XC0C0, #XFF7F, // U
         #X1F3F, #X60C0, #XC060, #X3F1F, // V
         #XFFFF, #X6030, #X3060, #XFFFF, // W
         #XC366, #X3408, #X0834, #X66C3, // X
         #X0306, #X0CF8, #XF80C, #X0603, // Y
         #XE3F3, #XDBCB, #XCBC7, #XC7C3, // Z
         #X0000, #XFFFF, #XC3C3, #X0000, // [
         #X0206, #X0408, #X1830, #X6040, // \
         #X0000, #XC3C3, #XFFFF, #X0000, // ]
         #X0203, #X03DB, #XDB0B, #X0F06, // ^
         #X0808, #X0808, #X4A2C, #X1808, // _
         #X0203, #X03DB, #XDB0B, #X0F06, // `
         #XFCFE, #X0B0B, #X0B0B, #XFEFC, // a
         #XFFFF, #XCBCB, #XCBCB, #XFF76, // b
         #X3C7E, #XC3C3, #XC3C3, #XC342, // c
         #XFFFF, #XC3C3, #XC3C3, #X7E3C, // d
         #XFFFF, #XCBCB, #XCBCB, #XC3C3, // e
         #XFFFF, #X0B0B, #X0B0B, #X0303, // f
         #X7EFF, #XC3C3, #XCBCB, #XFB7A, // g
         #XFFFF, #X0808, #X0808, #XFFFF, // h
         #XC3C3, #XC3FF, #XFFC3, #XC3C3, // i
         #XC3C3, #XC3FF, #X7F03, #X0303, // j
         #XFFFF, #X0818, #X3466, #XC381, // k
         #XFFFF, #XC0C0, #XC0C0, #XC0C0, // l
         #XFFFF, #X060C, #X0C06, #XFFFF, // m
         #XFFFF, #X060C, #X3870, #XFFFF, // n
         #X7EFF, #XC3C3, #XC3C3, #XFF7E, // o
         #XFFFF, #X0B0B, #X0B0B, #X0F06, // p
         #X7EFF, #XC3C3, #XD3E3, #X7FBE, // q
         #XFFFF, #X1B1B, #X3B7B, #XDF8E, // r
         #X4ECF, #XCBCB, #XCBCB, #XFB72, // s
         #X0303, #X03FF, #XFF03, #X0303, // t
         #X7FFF, #XC0C0, #XC0C0, #XFF7F, // u
         #X1F3F, #X60C0, #XC060, #X3F1F, // v
         #XFFFF, #X6030, #X3060, #XFFFF, // w
         #XC366, #X3408, #X0834, #X66C3, // x
         #X0306, #X0CF8, #XF80C, #X0603, // y
         #XE3F3, #XDBCB, #XCBC7, #XC7C3, // z
         #X0000, #X0000, #X3C7E, #XC300, // {
         #X0203, #X03DB, #XDB0B, #X0F06, // |
         #X00C3, #X7E3C, #X0000, #X0000, // }
         #X0203, #X03DB, #XDB0B, #X0F06, // ~
         #XFFFF, #XFFFF, #XFFFF, #XFFFF  // rubout


  FOR z=0 TO 3 DO
  { TEST ((charbase!z >> (8+line)) & 1) = 1 THEN wrch('#')
                                            ELSE wrch(' ')

    TEST ((charbase!z >> line) & 1) = 1     THEN wrch('#')
                                            ELSE wrch(' ')
  }
}
