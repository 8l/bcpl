// This tests the functionality of the coroutine 
// functions: callco, cowait and resumeco.

// Implemented by Martin Richards (c) March 2004

GET "libhdr"

GLOBAL { a_co:ug; b_co; c_co }

LET start() = VALOF
{ a_co := createco(a_fn, 200)
  b_co := createco(b_fn, 200)
  c_co := createco(c_fn, 200)

  writef("*nTest: root -> a -> root*n")
  writef("root: callco(a_co,  100)*n")
  writef("root: callco(a_co,  100) => %n*n", callco(a_co, 100))

  writef("*nTest: root -> a -> root, ie check: c:=fn(cowait(c)) REPEAT*n")
  writef("root: callco(a_co,  200)*n")
  writef("root: callco(a_co,  200) => %n*n", callco(a_co, 200))

  writef("*nTest: root -> b -> a -> b -> root*n")
  writef("root: callco(b_co,  300)*n")
  writef("root: callco(a_co,  300) => %n*n", callco(b_co, 300))

  writef("*nTest: root -> b -> a -> b -> root  again*n")
  writef("root: callco(b_co,  400)*n")
  writef("root: callco(b_co,  400) => %n*n", callco(b_co, 400))

  writef("*nTest: root -> c -> a -> root, ie check resumeco in c_co*n")
  writef("root: callco(c_co,  500)*n")
  writef("root: callco(c_co,  500) => %n*n", callco(c_co, 500))

  writef("*nTest: root -> c -> root*n")
  writef("root: callco(c_co,  600)*n")
  writef("root: callco(c_co,  600) => %n*n", callco(c_co, 600))

  deleteco(a_co)
  deleteco(b_co)
  deleteco(c_co)

  writef("*nEnd of test*n")
  RESULTIS 0
}

AND a_fn(x) = VALOF
{ writef("a_co: entered*n")
  writef("a_co: returning %n*n", x+10)
  RESULTIS x+10
}

AND b_fn(x) = VALOF
{ writef("b_co: entered*n")
  writef("b_co: callco(a_co, 2000)*n")
  writef("b_co: callco(a_co, 2000) => %n*n", callco(a_co, 2000))
  writef("b_co: returning %n*n", x+20)
  RESULTIS x+20
}

AND c_fn(x) = VALOF
{ writef("c_co: entered*n")
  writef("c_co: resumeco(a_co, 3000)*n")
  writef("c_co: resumeco(a_co, 3000) => %n*n", resumeco(a_co,3000))
  writef("c_co: returning %n*n", x+30)
  RESULTIS x+30
}

/* This program should generate the following output:

Test: root -> a -> root
root: callco(a_co,  100)
a_co: entered
a_co: returning 110
root: callco(a_co,  100) => 110

Test: root -> a -> root, ie check: c:=fn(cowait(c)) REPEAT
root: callco(a_co,  200)
a_co: entered
a_co: returning 210
root: callco(a_co,  200) => 210

Test: root -> b -> a -> b -> root
root: callco(b_co,  300)
b_co: entered
b_co: callco(a_co, 2000)
a_co: entered
a_co: returning 2010
b_co: callco(a_co, 2000) => 2010
b_co: returning 320
root: callco(a_co,  300) => 320

Test: root -> b -> a -> b -> root  again
root: callco(b_co,  400)
b_co: entered
b_co: callco(a_co, 2000)
a_co: entered
a_co: returning 2010
b_co: callco(a_co, 2000) => 2010
b_co: returning 420
root: callco(b_co,  400) => 420

Test: root -> c -> a -> root, ie check resumeco in c_co
root: callco(c_co,  500)
c_co: entered
c_co: resumeco(a_co, 3000)
a_co: entered
a_co: returning 3010
root: callco(c_co,  500) => 3010

Test: root -> c -> root
root: callco(c_co,  600)
c_co: resumeco(a_co, 3000) => 600
c_co: returning 530
root: callco(c_co,  600) => 530

End of test

*/


