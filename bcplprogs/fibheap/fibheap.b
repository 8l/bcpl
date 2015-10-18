/*
This is a demonstration of the Fibonacci Heap Algorithm
(based on Chapter 21 of Algorithms by Cormen, Leiserson and Rivest)

Implemented in BCPL by martin Richards (c) November 2010
*/

GET "libhdr"

MANIFEST {
  // Upper bounds
  spacevupb = 1_000_000
  nodevupb = 100_000

  // Selectors for Fib nodes
  H_min=0       // Null or pointer to the node with minimum key
  H_count       // Number of trees in the root list
  H_upb=H_count

  // Fib node selectors
  F_next=0; F_back=1 // Forward and Back for the sibling chain
  F_parent           // Null or pointer to the parent
  F_child            // Null or a pointer to a child
  F_degree           // Number of children
  F_mark             // FALSE is no child yet deleted from this node
  F_sn               // Serial number of node
  F_key
  F_upb=F_key
}

GLOBAL {
  spacev: ug        // Space allocated by newvec
  spacep; spacet
  nodev             // Vector of allocated fib nodes
  nodet
}

LET start() = VALOF
{ // Make two empty fibonacci heaps
  LET m1, c1 = 0, 0 // Fields of heap1
  LET m2, c2 = 0, 0 // Fields of heap2
  // Create two empty heaps
  LET heap1 = @m1  // heap1 -> [0, 0]
  LET heap2 = @m2  // heap2 -> [0, 0]

  writef("*nA demonstration of the Fibonacci Heap Algorithm*n*n")

  spacev, nodev := 0, 0

  spacev := getvec(spacevupb)
  UNLESS spacev DO
  { writef("*nUnable to allocate spacev*n")
    GOTO fin
  }
  spacet := spacev+spacevupb
  spacep := spacet+1

  nodev := getvec(nodevupb)
  UNLESS spacev DO
  { writef("*nUnable to allocate nodev*n")
    GOTO fin
  }
  FOR i = 0 TO nodevupb DO nodev!i := 0
  // Create some fib nodes
  nodev!1  := mkfibnode( 1, 12)
  nodev!2  := mkfibnode( 2, 30)
  nodev!3  := mkfibnode( 3, 20)
  nodev!4  := mkfibnode( 4, 26)
  nodev!5  := mkfibnode( 5, 11)
  nodev!6  := mkfibnode( 6,  5)
  nodev!7  := mkfibnode( 7, 15)

  nodev!8  := mkfibnode( 8, 22)
  nodev!9  := mkfibnode( 9, 33)
  nodev!10 := mkfibnode(10, 14)
  nodev!11 := mkfibnode(11, 24)
  nodev!12 := mkfibnode(12,  9)
  nodev!13 := mkfibnode(13,  7)
  nodev!14 := mkfibnode(14, 16)

  nodev!15 := mkfibnode(15,  2)
  nodev!16 := mkfibnode(16, 17)
  nodev!17 := mkfibnode(17, 35)
  nodev!18 := mkfibnode(18, 26)
  nodev!19 := mkfibnode(19, 54)
  nodev!20 := mkfibnode(20,  4)
  nodev!21 := mkfibnode(21, 14)
  nodev!22 := mkfibnode(22, 25)
  nodev!23 := mkfibnode(23, 43)
  nodev!24 := mkfibnode(24, 37)
  nodev!25 := mkfibnode(25, 28)

  writef("*nInserting nodes into heap1*n")
  FOR i = 1 TO 7 DO insert(heap1, nodev!i)

  writef("*nThe heap1 is now*n")
  prheap(heap1)

  writef("*nInserting nodes into heap2*n")
  FOR i = 8 TO 14 DO insert(heap2, nodev!i)

  writef("*nThe heap2 is now*n")
  prheap(heap2)

  writef("*nCalling extractmin of heap1*n")

  { LET p = extractmin(heap1)
    TEST p
    THEN writef("*nmin key was %n*n", F_key!p)
    ELSE writef("The heap is empty*n")
  }

  writef("*nThe heap1 is now*n")
  prheap(heap1)

  writef("*nCalling extractmin of heap2*n")

  { LET p = extractmin(heap2)
    TEST p
    THEN writef("*nmin key of heap2 was %n*n", F_key!p)
    ELSE writef("The heap is empty*n")
  }

  writef("*nThe heap2 is now*n")
  prheap(heap2)

  writef("*nMerging heap2 into heap1*n")
  merge(heap1, heap2)

  writef("*nThe heap1 is now*n")
  prheap(heap1)

  writef("*nInserting nodes into heap1*n")
  FOR i = 15 TO 25 DO insert(heap1, nodev!i)

  writef("*nThe heap1 is now*n")
  prheap(heap1)

  writef("*nCalling extractmin of heap1*n")

  { LET p = extractmin(heap1)
    TEST p
    THEN writef("*nmin key was %n*n", F_key!p)
    ELSE writef("The heap is empty*n")
  }

  writef("*nThe heap1 is now*n")
  prheap(heap1)

  writef("*nCalling decreasekey of node 04 from %n to 23 in heap1*n",
          F_key!(nodev!4))
  decreasekey(heap1, nodev!4, 23)

  writef("*nThe heap1 is now*n")
  prheap(heap1)

  writef("*nCalling decreasekey of node 04 from %n to 13 in heap1*n",
          F_key!(nodev!4))
  decreasekey(heap1, nodev!4, 13)

  writef("*nThe heap1 is now*n")
  prheap(heap1)

  writef("*nCalling decreasekey of node 18 from %n to 12 in heap1*n",
          F_key!(nodev!18))
  decreasekey(heap1, nodev!18, 12)

  writef("*nThe heap1 is now*n")
  prheap(heap1)

  writef("*nCalling decreasekey of node 11 from %n to 12 in heap1*n",
          F_key!(nodev!11))
  decreasekey(heap1, nodev!11, 12)

  writef("*nThe heap1 is now*n")
  prheap(heap1)

  writef("*nCalling decreasekey of node 17 from %n to 7 in heap1*n",
          F_key!(nodev!17))
  decreasekey(heap1, nodev!17, 7)

  writef("*nThe heap1 is now*n")
  prheap(heap1)


  writef("*nCalling extractmin of heap1*n")

  { LET p = extractmin(heap1)
    TEST p
    THEN writef("*nmin key was %n*n", F_key!p)
    ELSE writef("The heap is empty*n")
  }

  writef("*nThe heap1 is now*n")
  prheap(heap1)

  writef("*nClear heap1*n*n")
  H_min!heap1, H_count!heap1 := 0, 0

  

  FOR i = 1 TO 5 DO
  { LET key = 100-2*i
    LET x = mkfibnode(100, 1)
    LET y = mkfibnode(101, 100)
    nodev!(2*i)   := mkfibnode(2*i, key)
    nodev!(2*i+1) := mkfibnode(2*i+1, key+1)
    insert(heap1, nodev!(2*i))
    insert(heap1, nodev!(2*i+1))
    insert(heap1, mkfibnode(100, 1))
    writef("heap1 is now:*n")
    prheap(heap1)
    writef("extractmin(heap1)*n")
    extractmin(heap1)
    writef("heap1 is now:*n")
    prheap(heap1)
    writef("delete node with id=%n*n", 2*i+1)
    delete(heap1, nodev!(2*i+1))
    writef("heap1 is now:*n")
    prheap(heap1)
  }

fin:
  IF spacev DO freevec(spacev)
  IF nodev  DO freevec(nodev)
  RESULTIS 0
}

AND newvec(upb) = VALOF
{ LET p = spacep - upb - 1
  IF p<0 DO
  { writef("*nOut of space*n")
    abort(999)
  }
  spacep := p
  RESULTIS spacev+p
}

AND insert(h, node) BE
{ // Append a new fib node onto the end of the root list of heap h
  LET minnode = H_min!h
  writef("Insert key %n*n", F_key!node)
  F_mark!node, F_parent!node := FALSE, 0
  TEST minnode
  THEN { combine(minnode, node)
         IF F_key!minnode > F_key!node DO H_min!h := node
       }
  ELSE { H_min!h := node
       }
  H_count!h := H_count!h + 1
}

AND mkfibnode(sn, key) = VALOF
{ // Make a singleton fib node with given key.
  LET n = newvec(F_upb)
  F_next!n, F_back!n, F_degree!n := n, n, 0
  F_parent!n := 0
  F_mark!n := FALSE
  F_sn!n := sn
  F_key!n := key
  RESULTIS n
}

AND first(h) = H_min!h

AND merge(h1, h2) BE
{ // Merge all the fib nodes in heap h2 into heap h1
  LET m1, count1 = H_min!h1, H_count!h1
  LET m2, count2 = H_min!h2, H_count!h2

  UNLESS m2 RETURN     // No nodes in heap h2

  UNLESS m1 DO
  { // No nodes in heap1
    // so copy heap h2 into heap h1
    H_min!h1, H_count!h1 := m2, count2
    RETURN
  }
  // Both heaps have nodes
  combine(m1, m2) // Combine the root lists
  // Update the min pointer, if necessary
  IF F_key!m1 > F_key!m2 DO H_min!h1 := m2
  // Update the count
  H_count!h1 := count1 + count2
}

AND extractmin(h) = VALOF
{ LET res = H_min!h
  IF res DO
  { // res points to a fib node with the minimum key.
    // Remove it from the root chain.
    LET child  = F_child!res  // One of the children, if any.
    LET degree = F_degree!res // The number of children

    // Remove the extracted node from the root list
    H_count!h := H_count!h - 1
    TEST H_count!h
    THEN { // We are about to dequeue the minimum node
           // so set min to some other node (not necessarily the next minimum)
           H_min!h := F_next!res
           dequeue(res)
         }
    ELSE H_min!h := 0

    // Reset the parent and marked fields of every child
    FOR i = 1 TO degree DO
    { LET nextchild = F_next!child
      F_parent!child := 0
      F_mark!child := FALSE
      // Make child into a singlton
      F_next!child, F_back!child := child, child
      // Insert this child into the root list
      TEST H_min!h
      THEN combine(H_min!h, child)
      ELSE H_min!h := child
      H_count!h := H_count!h + 1
      child := nextchild
    }

    consolidate(h)
  }

  RESULTIS res
}

AND consolidate(h) BE
{ // Ensure that all root trees have distinct degrees
  // and update min, if necessary.
  LET v = VEC 40 // No fib node will have degree greater than 40
  LET node = H_min!h // First tree in the root list

  UNLESS H_count!h DO
  { // There are no fib nodes in the heap
    H_min!h := 0
    RETURN
  }
  FOR i = 0 TO 40 DO v!i := 0

  FOR i = 1 TO H_count!h DO
  { // node points to a root tree fib node to deal with
    LET d = F_degree!node // The degree of node
    LET p = node
    LET nextnode = F_next!node
  
    WHILE v!d DO
    { // Combine p with another node of the degree d
      LET q = v!d
      v!d := 0
      IF F_key!p > F_key!q DO { LET t=p; p:=q; q:=t }
      // q has a key no smaller than the key of p.
      // Make q a singleton
      F_next!q, F_back!q := q, q
      // Add q to the children of p
      TEST F_child!p
      THEN combine(F_child!p, q) // Combine the 2 circular lists
      ELSE F_child!p := q
      F_parent!q := p
      // p now has degree d+1
      d := d+1
      F_degree!p := d
    }
    // There is no other node of degree d
    // Make p a singleton
    F_next!p, F_back!p := p, p
    v!d := p
    // Deal with the next root node
    node := nextnode
  }

  // Form a new root list by combining all the fib nodes in v
  // remembering which has the least key.
  { LET list, count, min_node, min_key = 0, 0, 0, 0

    FOR d = 0 TO 40 IF v!d DO
    { LET p = v!d
      // Add p to list
      TEST list
      THEN combine(list, p)
      ELSE list := p
      // Correct min_node
      IF min_node=0 | F_key!p < min_key DO
        min_node, min_key := p, F_key!p
      count := count + 1
    }
    H_min!h, H_count!h := min_node, count
  }
}

AND decreasekey(h, node, newkey) BE
{ LET p = F_parent!node

  IF newkey > F_key!node DO
  { writef("Bad newkey=%n oldkey=%nin decreasekey*n", newkey, F_key!node) 
    RETURN
  }
  F_key!node := newkey
  IF p & newkey < F_key!p DO
  { cut(h, node, p)
    cascading_cut(h, p)
  }
  IF newkey < F_key!(H_min!h) DO H_min!h := node
}

AND cut(h, x, y) BE
{ // Remove x from the child list of y, decrementing its degree
  IF F_child!y=x DO F_child!y := F_next!x
  dequeue(x)
  F_degree!y := F_degree!y - 1
  IF F_degree!y=0 DO F_child!y := 0
  // Add x to the root list of h, incrementing count
  combine(H_min!h, x)
  H_count!h := H_count!h + 1
  IF F_key!x < F_key!(H_min!h) DO H_min!h := x
  // Reset the parent and mark of x
  F_parent!x, F_mark!x := 0, FALSE
}

AND cascading_cut(h, y) BE WHILE F_parent!y DO
{ LET z = F_parent!y
  UNLESS F_mark!y DO { F_mark!y := TRUE; RETURN }
  cut(h, y, z)
  y := z
}

AND delete(h, node) BE
{ decreasekey(h, node, minint)
  extractmin(h)
}

AND combine(n1, n2) = VALOF
{ // Combine two circular fibnode chains into one chain
  // by appending n2 onto the end of n1.
  UNLESS n1 RESULTIS n2
  UNLESS n2 RESULTIS n1

  { // Both lists are non null
    LET m1 = F_back!n1
    LET m2 = F_back!n2

    F_next!m1 := n2
    F_next!m2 := n1

    F_back!n1 := m2 
    F_back!n2 := m1 

    RESULTIS n1
  }
}

AND dequeue(node) = VALOF
{ // Remove a node from a circular list
  LET next, prev = F_next!node, F_back!node

  F_next!prev := next
  F_back!next := prev 

  // Make the dequeued node a singleton
  F_next!node, F_back!node := node, node

  RESULTIS node
}

AND wrlist(p) BE
{ LET first = p
  writef("=>")
  UNLESS p DO { writef("Empty*n"); RETURN }
  { writef(" %n:%2z", F_key!p, F_sn!p)
    p := F_next!p
//writef("*nwrlist: first=%n p=%n*n", first, p)
//abort(1002)
  } REPEATUNTIL p=first
  newline() 
}

AND prheap(h) BE
{ plist(H_min!h, H_count!h, 0, 5)
  newline()
}

AND plist(x, count, n, d) BE IF x DO
{ LET v = TABLE 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

//  wrlist(x)

  FOR i = 1 TO count DO
  { newline()
    FOR j=0 TO n-1 DO writes( v!j )
    TEST n=d 
    THEN { writes("Etc"); RETURN
         }
    ELSE { writef("**-%n id %2z", F_key!x, F_sn!x)
           IF F_mark!x DO writef(" marked")
           v!n := i=count->"  ","! "
           plist(F_child!x, F_degree!x, n+1, d)
         }
    x := F_next!x
  }
}

/* When run this program outputs the following:

A demonstration of the Fibonacci Heap Algorithm


Inserting nodes into heap1
Insert key 12
Insert key 30
Insert key 20
Insert key 26
Insert key 11
Insert key 5
Insert key 15

The heap1 is now

*-5 id 06
*-11 id 05
*-12 id 01
*-30 id 02
*-20 id 03
*-26 id 04
*-15 id 07

Inserting nodes into heap2
Insert key 22
Insert key 33
Insert key 14
Insert key 24
Insert key 9
Insert key 7
Insert key 16

The heap2 is now

*-7 id 13
*-9 id 12
*-14 id 10
*-22 id 08
*-33 id 09
*-24 id 11
*-16 id 14

Calling extractmin of heap1

min key was 5

The heap1 is now

*-11 id 05
! *-12 id 01
! *-20 id 03
!   *-30 id 02
*-15 id 07
  *-26 id 04

Calling extractmin of heap2

min key of heap2 was 7

The heap2 is now

*-9 id 12
! *-14 id 10
! *-22 id 08
!   *-33 id 09
*-16 id 14
  *-24 id 11

Merging heap2 into heap1

The heap1 is now

*-9 id 12
! *-14 id 10
! *-22 id 08
!   *-33 id 09
*-16 id 14
! *-24 id 11
*-11 id 05
! *-12 id 01
! *-20 id 03
!   *-30 id 02
*-15 id 07
  *-26 id 04

Inserting nodes into heap1
Insert key 2
Insert key 17
Insert key 35
Insert key 26
Insert key 54
Insert key 4
Insert key 14
Insert key 25
Insert key 43
Insert key 37
Insert key 28

The heap1 is now

*-2 id 15
*-9 id 12
! *-14 id 10
! *-22 id 08
!   *-33 id 09
*-16 id 14
! *-24 id 11
*-11 id 05
! *-12 id 01
! *-20 id 03
!   *-30 id 02
*-15 id 07
! *-26 id 04
*-17 id 16
*-35 id 17
*-26 id 18
*-54 id 19
*-4 id 20
*-14 id 21
*-25 id 22
*-43 id 23
*-37 id 24
*-28 id 25

Calling extractmin of heap1

min key was 2

The heap1 is now

*-4 id 20
! *-14 id 21
! *-25 id 22
!   *-43 id 23
*-9 id 12
! *-14 id 10
! *-22 id 08
! ! *-33 id 09
! *-11 id 05
! ! *-12 id 01
! ! *-20 id 03
! !   *-30 id 02
! *-15 id 07
!   *-26 id 04
!   *-16 id 14
!   ! *-24 id 11
!   *-17 id 16
!     *-35 id 17
!     *-26 id 18
!       *-54 id 19
*-28 id 25
  *-37 id 24

Calling decreasekey of node 04 from 26 to 23 in heap1

The heap1 is now

*-4 id 20
! *-14 id 21
! *-25 id 22
!   *-43 id 23
*-9 id 12
! *-14 id 10
! *-22 id 08
! ! *-33 id 09
! *-11 id 05
! ! *-12 id 01
! ! *-20 id 03
! !   *-30 id 02
! *-15 id 07
!   *-23 id 04
!   *-16 id 14
!   ! *-24 id 11
!   *-17 id 16
!     *-35 id 17
!     *-26 id 18
!       *-54 id 19
*-28 id 25
  *-37 id 24

Calling decreasekey of node 04 from 23 to 13 in heap1

The heap1 is now

*-4 id 20
! *-14 id 21
! *-25 id 22
!   *-43 id 23
*-9 id 12
! *-14 id 10
! *-22 id 08
! ! *-33 id 09
! *-11 id 05
! ! *-12 id 01
! ! *-20 id 03
! !   *-30 id 02
! *-15 id 07 marked
!   *-16 id 14
!   ! *-24 id 11
!   *-17 id 16
!     *-35 id 17
!     *-26 id 18
!       *-54 id 19
*-28 id 25
! *-37 id 24
*-13 id 04

Calling decreasekey of node 18 from 26 to 12 in heap1

The heap1 is now

*-4 id 20
! *-14 id 21
! *-25 id 22
!   *-43 id 23
*-9 id 12
! *-14 id 10
! *-22 id 08
! ! *-33 id 09
! *-11 id 05
! ! *-12 id 01
! ! *-20 id 03
! !   *-30 id 02
! *-15 id 07 marked
!   *-16 id 14
!   ! *-24 id 11
!   *-17 id 16 marked
!     *-35 id 17
*-28 id 25
! *-37 id 24
*-13 id 04
*-12 id 18
  *-54 id 19

Calling decreasekey of node 11 from 24 to 12 in heap1

The heap1 is now

*-4 id 20
! *-14 id 21
! *-25 id 22
!   *-43 id 23
*-9 id 12
! *-14 id 10
! *-22 id 08
! ! *-33 id 09
! *-11 id 05
! ! *-12 id 01
! ! *-20 id 03
! !   *-30 id 02
! *-15 id 07 marked
!   *-16 id 14 marked
!   *-17 id 16 marked
!     *-35 id 17
*-28 id 25
! *-37 id 24
*-13 id 04
*-12 id 18
! *-54 id 19
*-12 id 11

Calling decreasekey of node 17 from 35 to 7 in heap1

The heap1 is now

*-4 id 20
! *-14 id 21
! *-25 id 22
!   *-43 id 23
*-9 id 12
! *-14 id 10
! *-22 id 08
! ! *-33 id 09
! *-11 id 05
!   *-12 id 01
!   *-20 id 03
!     *-30 id 02
*-28 id 25
! *-37 id 24
*-13 id 04
*-12 id 18
! *-54 id 19
*-12 id 11
*-7 id 17
*-17 id 16
*-15 id 07
  *-16 id 14 marked

Calling extractmin of heap1

min key was 4

The heap1 is now

*-7 id 17
! *-17 id 16
! *-12 id 11
! ! *-13 id 04
! *-12 id 18
! ! *-54 id 19
! ! *-28 id 25
! !   *-37 id 24
! *-9 id 12
!   *-14 id 10
!   *-22 id 08
!   ! *-33 id 09
!   *-11 id 05
!     *-12 id 01
!     *-20 id 03
!       *-30 id 02
*-14 id 21
*-15 id 07
  *-16 id 14 marked
  *-25 id 22
    *-43 id 23

Clear heap1

Insert key 98
Insert key 99
Insert key 1
heap1 is now:

*-1 id 100
*-98 id 02
*-99 id 03
extractmin(heap1)
heap1 is now:

*-98 id 02
  *-99 id 03
delete node with id=3
heap1 is now:

*-98 id 02
Insert key 96
Insert key 97
Insert key 1
heap1 is now:

*-1 id 100
*-96 id 04
*-98 id 02
*-97 id 05
extractmin(heap1)
heap1 is now:

*-96 id 04
! *-98 id 02
*-97 id 05
delete node with id=5
heap1 is now:

*-96 id 04
  *-98 id 02
Insert key 94
Insert key 95
Insert key 1
heap1 is now:

*-1 id 100
*-94 id 06
*-96 id 04
! *-98 id 02
*-95 id 07
extractmin(heap1)
heap1 is now:

*-94 id 06
  *-95 id 07
  *-96 id 04
    *-98 id 02
delete node with id=7
heap1 is now:

*-94 id 06
  *-96 id 04
    *-98 id 02
Insert key 92
Insert key 93
Insert key 1
heap1 is now:

*-1 id 100
*-92 id 08
*-94 id 06
! *-96 id 04
!   *-98 id 02
*-93 id 09
extractmin(heap1)
heap1 is now:

*-92 id 08
  *-93 id 09
  *-94 id 06
    *-96 id 04
      *-98 id 02
delete node with id=9
heap1 is now:

*-92 id 08
  *-94 id 06
    *-96 id 04
      *-98 id 02
Insert key 90
Insert key 91
Insert key 1
heap1 is now:

*-1 id 100
*-90 id 10
*-92 id 08
! *-94 id 06
!   *-96 id 04
!     *-98 id 02
*-91 id 11
extractmin(heap1)
heap1 is now:

*-90 id 10
  *-91 id 11
  *-92 id 08
    *-94 id 06
      *-96 id 04
        *-98 id 02
delete node with id=11
heap1 is now:

*-90 id 10
  *-92 id 08
    *-94 id 06
      *-96 id 04
        *-98 id 02
*/
