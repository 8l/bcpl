GET "libhdr"

/* This is a program to show that there are 120549 elements in
   the domain D3 as described on pages 113-115 of "Denotational
   Semantics" by J.E.Stoy.

   The program is by M.Richards and the following diagram is a
   clue to how it works.



       #10
       |
-------A----------------------- p10
       |
       #9
       |
-------A----------------------- p9
      /|
     / |
    /  |
   #8  |
   |   |
---A---B----------------------- p8
   |   |
   |   #7
   |   |
---B---A----------------------- p7
   |  /|
   | / |
   |/  |
   #6  |
   |   |
---A---B----------------------- p6
   |   |
   |   #5
   |   |
---B---A----------------------- p5
   |\  |
   | \ |
   |  \|
   |   #4
   |   |
---B---A----------------------- p4
   |   |
   #3  |
   |   |
---A---B----------------------- p3
   |  /
   | /
   |/
   #2
   |
---A--------------------------- p2
   |
   #1
   |
---A--------------------------- p1
   |

    The diagram represents a directed graph with 10 vertices #1,... #10.

The relation <= is defined as follows:

   #i <= #j  iff the exists a downward path from #j to #i or #i=#j.

f if a function whose argument and result are both elements of the set

#1,... #10 and having the following property:

    #1<=x<=#10 /\ #1<=y<=#10 /\ x<=y  =>  f(x)<=f(y)

    How many different functions exist with this property?

    The answer is 120549.
*/


GLOBAL $( tab:150; count:151  $)

LET start() BE
$( LET v = VEC 512
   v!512:= #b1111111111
   v!256:= #b0111111111
   v!128:= #b0010101111
   v!64 := #b0001111111
   v!32 := #b0000101111
   v!16 := #b0000011011
   v!8  := #b0000001011
   v!4  := #b0000000111
   v!2  := #b0000000011
   v!1  := #b0000000001

   tab := v

   count := 0
   try(p10, #b1111111111)
   writef("Number of elements in D3 = %n*n", count)
$)

AND try(p, a, b) BE UNTIL a=0 DO
$( LET x = a & -a
   a := a - x
   p(tab!x, b)
$)

AND p10(a)    BE try(p9, a)

AND p9(a)    BE try(p8, a, a)

AND p8(a, b) BE try(p7, b, a)

AND p7(a, b) BE try(p6, a&b, a)

AND p6(a, b) BE try(p5, b, a)

AND p5(a, b) BE try(p4, a&b, b)

AND p4(a, b) BE try(p3, b, a)

AND p3(a, b) BE try(p2, a&b)

AND p2(a)    BE try(p1, a)

AND p1()    BE count := count + 1

