GET "libhdr"

LET start() = VALOF
{ LET x = 1.5213e4
  LET y = FLOAT 15213
  LET i = FIX x
  LET j = FIX y

  newline()
  //writef("x = %32b*n", x)
  //writef("y = %32b*n", y)
  //writef("i = %n*n", i)
  //writef("j = %n*n", j)

  writef("FIX 10.0 = %n*n", FIX 10.0)
  writef("FIX 10.1 = %n*n", FIX 10.1)
  writef("FIX 10.2 = %n*n", FIX 10.2)
  writef("FIX 10.3 = %n*n", FIX 10.3)
  writef("FIX 10.4 = %n*n", FIX 10.4)
  writef("FIX 10.5 = %n*n", FIX 10.5)
  writef("FIX 10.6 = %n*n", FIX 10.6)
  writef("FIX 10.7 = %n*n", FIX 10.7)
  writef("FIX 10.8 = %n*n", FIX 10.8)
  writef("FIX #-10.9 = %n*n", FIX #-10.9)
  writef("FIX 11.0 = %n*n", FIX 11.0)

  writef("3.6 #** 3.0 = %n*n", FIX (3.6 #* 3.0))

  writef("1000.0 #/ 3.0 = %n*n", FIX (1000.0 #/ 3.0))
  writef("1000.0 #+ 3.0 = %n*n", FIX (1000.0 #+ 3.0))
  writef("1000.0 #- 3.0 = %n*n", FIX (1000.0 #- 3.0))

  writef("#-1000.0 = %n*n", FIX (#-(1000.0#+0.0)))
  writef("#+1000.0 = %n*n", FIX (#+(1000.0#+0.0)))

  writef("1000.0 #=  3.0 = %i5*n", 1000.0 #=  3.0)
  writef("1000.0 #~= 3.0 = %i5*n", 1000.0 #~= 3.0)
  writef("1000.0 #<  3.0 = %i5*n", 1000.0 #<  3.0)
  writef("1000.0 #>  3.0 = %i5*n", 1000.0 #>  3.0)
  writef("1000.0 #<= 3.0 = %i5*n", 1000.0 #<= 3.0)
  writef("1000.0 #>= 3.0 = %i5*n", 1000.0 #>= 3.0)

  writef("   3.0 #=  3.0 = %i5*n",    3.0 #=  3.0)
  writef("   3.0 #~= 3.0 = %i5*n",    3.0 #~= 3.0)
  writef("   3.0 #<  3.0 = %i5*n",    3.0 #<  3.0)
  writef("   3.0 #>  3.0 = %i5*n",    3.0 #>  3.0)
  writef("   3.0 #<= 3.0 = %i5*n",    3.0 #<= 3.0)
  writef("   3.0 #>= 3.0 = %i5*n",    3.0 #>= 3.0)

  writef("   2.9 #=  3.0 = %i5*n", 2.9 #=  3.0)
  writef("   2.9 #~= 3.0 = %i5*n", 2.9 #~= 3.0)
  writef("   2.9 #<  3.0 = %i5*n", 2.9 #<  3.0)
  writef("   2.9 #>  3.0 = %i5*n", 2.9 #>  3.0)
  writef("   2.9 #<= 3.0 = %i5*n", 2.9 #<= 3.0)
  writef("   2.9 #>= 3.0 = %i5*n", 2.9 #>= 3.0)

  { LET a = sys(Sys_flt, fl_unmk, 1234.56789)
    LET b = result2
    writef("unmk(1234.56789) => %n result2 = %n*n", a, b)
  }
  { LET a = sys(Sys_flt, fl_unmk, #-1234.56789)
    LET b = result2
    writef("unmk(#-1234.56789) => %n result2 = %n*n", a, b)
  }

  RESULTIS 0
}
