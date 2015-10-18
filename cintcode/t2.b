GET "libhdr"

LET start() = VALOF
{ FOR ch = 0 TO 1 FOR line = 0 TO 11 DO write_ch_slice(ch, line)
  RESULTIS 0
}

AND write_ch_slice(ch, line) BE
{ LET charbase = TABLE
         #XFFFFFFFF, #XFFFFFFFF, #XFF000000,
         #X11223344, #X55667788, #X8899AABB

  { LET w = 0 //VALOF SWITCHON line INTO
/*
    { CASE  0: RESULTIS charbase!0>>24
      CASE  1: RESULTIS charbase!0>>16
      CASE  2: RESULTIS charbase!0>> 8
      CASE  3: RESULTIS charbase!0
      CASE  4: RESULTIS charbase!1>>24
      CASE  5: RESULTIS charbase!1>>16
      CASE  6: RESULTIS charbase!1>> 8
      CASE  7: RESULTIS charbase!1
      CASE  8: RESULTIS charbase!2>>24
      CASE  9: RESULTIS charbase!2>>16
      CASE 10: RESULTIS charbase!2>> 8
      CASE 11: RESULTIS charbase!2
    }
*/

    charbase := charbase + 3*ch

writef("writeslice: ch=%n line=%i2 w=%b8 bits=%x8 %x8 %x8*n",
        ch, line, 0, charbase!0, charbase!1, charbase!2)

  }
}

AND drawpoint(x, y) BE RETURN
