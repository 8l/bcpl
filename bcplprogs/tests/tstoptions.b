// This program tests the OPT mechanism of the BCPL compiler.

GET "libhdr"

LET start() = VALOF
{ writef("This program tests for compile time options: abc, def_12 and a.3*n")
  writef("eg type*n*n")
  writef("c b tstoptions opt *"opt abc+a.3*"*n")
  writef("tstoptions*n*n")

  $<abc
    writef("Compile time option abc was given*n")
  $>abc
  $~abc
    writef("Compile time option abc was not given*n")
  $>abc

  $<def_12
    writef("Compile time option def_12 was given*n")
  $>def_12
  $~def_12
    writef("Compile time option def_12 was not given*n")
  $>def_12

  $<a.3
    writef("Compile time option a.3 was given*n")
  $>a.3
  $~a.3
    writef("Compile time option a.3 was not given*n")
  $>a.3

  writef("*nEnd of test*n")
}

