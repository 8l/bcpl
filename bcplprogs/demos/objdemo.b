GET "libhdr"

/*
1. Object oriented programming in BCPL.


It is commonly thought that object oriented programming and type
systems are inseparably mixed, but some features of an object oriented
programming language can be incorporated in a typeless language to
give it many of the benefits of OOP programming.

An object is an encapsulated combination of data values (fields) and
procedures (often called methods). Communication with objects is by
means of messages and returned results. The class of an object
specifies the types of the fields and the types of the methods.  In
BCPL all the fields would be of the same size and would form a
vector. Similarly, the methods could be placed in a vector. Although
the methods could reside in the same vector as the fields, it is
sensible to hold them in separate vectors so that all objects of a
class can share the same methods vector.  In a typeless language the
natural way to represent an object is as a pointer to its fields
vector with its zeroth element pointing to the methods vector.

2. Class definition

It is convenient, though not compulsory, to define a class (eg A) by
means of a header file (eg A.h) and code file (A.b). The header file
might be:
*/

GLOBAL
{ mkfns_A:200 }  // A function to make the methods vector for class A

MANIFEST
{ Af_init=0; Af_destroy=1  // All classes have these two methods 
  Af_f=2; Af_g=3           // methods belonging to A
  Af_upb=3                 // size and upb of fns vector for A
}

/*
By convention the first two methods of every object are init to initialise 
the object, and destroy for its destruction.

3. Message sending

Assuming an object of class A has been created it can be sent a message
(x, y,..., z) using method f, say, by the following call:

    res := ((!obj)!A_f)(obj, x, y,..., z)

which is more readable in its sugared form:

    res := A_f#(obj, x, y,..., z)

The hash (#) is to distinguish this from an ordinary function call.

If greater efficiency if required, something like the following
could be used:

    LET f = (!obj)!A_f
    ...
    res := f(obj, x, y,..., z)


4. The body of a class

By way of example, consider the body file A.b for class A which could
be as follows:

GET "libhdr"
GET "A.h"
*/

MANIFEST {
A_fns=0                 // the methods vector for A
A_a=1; A_b=2; A_c=3     // the fields
A_upb=3                 // the upb
}

LET mkfns_A() = VALOF   // Make the fns vector for class A.
{ LET fns = getvec(Af_upb)
  UNLESS fns=0 DO
  { fns!Af_init    := initA    // Methods for A
    fns!Af_destroy := destroyA
    fns!Af_f       := fA
    fns!Af_g       := gA
  }
  RESULTIS fns
}

// Definition of the method functions for A

AND initA(a) BE FOR i = 1 TO A_upb DO a!i := 0

AND destroyA(a) BE freevec(a)

AND fA(a, x, y) BE 
{ writef("Method f of A called with args %i2 and %i2*n", x, y)
}

AND gA(a, x, y) BE 
{ writef("Method g of A called with args %i2 and %i2*n", x, y)
}

/*
6. Object creation

An object is normally created using the mkobj function defined in
BLIB, as follows:

LET mkobj(upb, fns, a, b, c, d, e, f, g, h, i, j, k) = VALOF
{ LET obj = getvec(upb)
  UNLESS obj=0 DO
  { A_fns!a := fns
    InitObj#(obj, @a)    // Send the init message to the object
  }
  RESULTIS obj
}

As can be seen, mkobj take two arguments: upb the upper bound of the
fields vector, and fns the vector of methods for the class.  As an
illustration, an object belonging to class A can be made by the
following statement:

     LET fns_A = mkfns_A()
     LET objA = mkobj(A_upb, fns_A)

This will create the following:

         fields                methods
          ----                  ----
objA --> |  *-|--------------> |    | Af_init
         |----|                |----|
    A_a  |    |                |    | Af_destroy
         |----|                |----|
    A_b  |    |                |    | Af_f
         |----|                |----|
    A_c  |    |                |    | Af_g
          ----                  ---- 


7. Derived classes

A sub-class can be derived from another class.  The derived class
requires a methods vector at least as large as the methods vector
of the parent class, and similarly its fields vector may be no
smaller than the parent's fields vector. Consider the construction
of a class B derived from class A defined above.


         fields       methods for B       methods for A
          ----            ----                ----
obj ---> |  *-|--------> |    | Bf_init      |    | Af_init 
         |----|          |----|              |----|
A_a B_a  |    |          |    | Bf_destroy   |    | Af_destroy 
         |----|          |----|              |----|
A_b B_b  |    |          |    | Bf_f         |    | Af_f
         |----|          |----|              |----|
A_c B_c  |    | A_upb    |    | Bf_g         |    | Af_g    Af_upb
         |----|          |----|               ----
    B_d  |    |          |    | Bf_prevf
         |----|          |----|
    B_e  |    | B_upb    |    | Bf_g  Bf_upb
          ----            ----

Class A has fields a, b and c and methods init, destroy, f and g while
B id derrived from A having two additional fields d and e, and an
additional method h. It also has a copy of the f method belonging to
A.  The header file B.h for B could be as follows:
*/

GLOBAL { mkfns_B:201 }

MANIFEST {
Bf_init=0; Bf_destroy=1  // The two standard methods.
Bf_f=2; Bf_g=3           // methods belonging to B and A.
Bf_prevf=4               // copy of parental method for f.
Bf_h=5                   // method in B but not in A.
Bf_upb=5                 // upb of fns vector for B
}

/*
8. Body file for class B

The body file B.b is

GET "libhdr"
GET "A.h"  
GET "B.h"
*/

MANIFEST {
B_fns=0               // the methods vector for B
B_a=1; B_b=2; B_c=3   // the fields in common with the parent
B_d=4; B_e=5          // fields belonging to B only
B_upb=5               // upb
}

LET mkfns_B(pfns) = VALOF // Make the fns vector for class B.
                          // pfns is the parent's methods vector.
                          // A copy of a parental method must be made
                          // in the new fns vector if
                          //     (a) the method has been overridden
                          // and (b) the previous methon is needed.
                          // Such a situation is considered rare.
{ LET fns = getvec(Bf_upb)
  UNLESS fns=0 DO
  { UNLESS pfns=0 DO              // copy previous methods, if any
      FOR i = 1 TO Af_upb DO fns!i := pfns!i
    fns!Bf_init    := initB       // override with new versions
    fns!Bf_destroy := destroyB    // with ne versions of init, destroy
    fns!Bf_f       := fB          // and f, but not g.
    fns!Bf_prevf   := pfns!Af_f   // private copy of parental method f
    fns!Bf_h       := hB          // A method in B but not in A
  }
  RESULTIS fns
}

// Definition of the method functions for A

AND initB(b) BE FOR i = 1 TO B_upb DO b!i := 0

AND destroyB(b) BE freevec(b)

AND fB(b, x, y) BE
{ writef("Method f of B called with args %i2 and %i2*n", x, y)
  // parental method f can be invoked by call:
  Bf_prevf#(b, x+10, y+10 )
}

AND hB(b, x, y) BE
{ writef("Method h of B called with args %i2 and %i2*n", x, y)
}

LET start() = VALOF
{
// An object belonging to class A can be constructed by the following code:

  LET fns_A = mkfns_A()
  LET objA = mkobj(A_upb, fns_A)

// An object belonging to class B can be constructed by the following code:
 
  LET fns_B = mkfns_B(fns_A)
  LET objB = mkobj(B_upb, fns_B)

// Let us now send some messages to these classes

  Af_f#(objA, 1, 2)
  Af_g#(objA, 3, 4)
  Bf_f#(objB, 5, 6)
  Bf_g#(objB, 7, 8)
  Bf_h#(objB, 9, 10)

  Af_destroy#(objA)
  Bf_destroy#(objB)

  freevec(fns_A)
  freevec(fns_B)

  writef("End of demo*n")
  RESULTIS 0
}

/* When this program is run it output:

Method f of A called with args  1 and  2
Method g of A called with args  3 and  4
Method f of B called with args  5 and  6
Method f of A called with args 15 and 16
Method g of A called with args  7 and  8
Method h of B called with args  9 and 10
End of demo

*/