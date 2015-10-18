/*
########## UNDER DEVEOPMENT ###################################

The strategy used by this program seems to be too slow to be useful
unless th solution has a rather small number of moves. Another
strategy is being considered and will be implemented in rubik.b.

This program attempts to solve Rubik Cube problems, given a textual
specification of an initial position, it will hopefully output a
sequence of rotations to solve the cube.

Implemented by Martin Richards (c) January 2015

This program currently requires a lot of work space and
should be run by a command such as the following:

cintsys -m 300000000 -c "c b rubik; rubik -s 1 -c"

Even this runs out of space but tuning the atgoal function
may heap.
*/

GET "libhdr"

MANIFEST {
  // This program assumes the cube is always in the same  orientation
  // with upper face being white and the front face red.
  // The other faces are
  //    right  blue
  //    back   orange
  //    left   green
  //    down   yellow

  // Corner piece definitions
  // orientation 0 means W/Y piece face is parallel to up face
  //             1 means the piece was rotated anticlockwise once
  //                     when looking towards its corner.
  //             2 means the piece was rotated anticlockwise twice
  WRB0=0<<2|0; WRB1=0<<2|1; WRB2=0<<2|2 // Corner 0
  WBO0=1<<2|0; WBO1=1<<2|1; WBO2=1<<2|2 // Corner 1
  WOG0=2<<2|0; WOG1=2<<2|1; WOG2=2<<2|2 // Corner 2
  WGR0=3<<2|0; WGR1=3<<2|1; WGR2=3<<2|2 // Corner 3

  YBR0=4<<2|0; YBR1=4<<2|1; YBR2=4<<2|2 // Corner 4
  YOB0=5<<2|0; YOB1=5<<2|1; YOB2=5<<2|2 // Corner 5
  YGO0=6<<2|0; YGO1=6<<2|1; YGO2=6<<2|2 // Corner 6
  YRG0=7<<2|0; YRG1=7<<2|1; YRG2=7<<2|2 // Corner 7

  // There are 12 Edge pieces
  // The edge directions are
  //   0->1  1->2  2->3  3->0
  //   0->4  1->5  2->6  3->7
  //   4->7  5->4  6->5  7->6
  // orientation 0 means the first colour is on the left when
  //                     looking forward along the edge
  // orientation 1 means the first colour is on the right when
  //                     looking forward along the edge

  // Upper level edges
  WR0= 0<<1|0; WR1= 0<<1|1  // in edge  0->1
  WB0= 1<<1|0; WB1= 1<<1|1  // in edge  1->2
  WO0= 2<<1|0; WO1= 2<<1|1  // in edge  2->3
  WG0= 3<<1|0; WG1= 3<<1|1  // in edge  3->0

  // Middle layer edges
  BR0= 4<<1|0; BR1= 4<<1|1  // in edge  0->4
  OB0= 5<<1|0; OB1= 5<<1|1  // in edge  1->5
  GO0= 6<<1|0; GO1= 6<<1|1  // in edge  2->6
  RG0= 7<<1|0; RG1= 7<<1|1  // in edge  3->7

  // Down layer edges
  YR0= 8<<1|0; YR1= 8<<1|1  // in edge  4->7
  YB0= 9<<1|0; YB1= 9<<1|1  // in edge  5->4
  YO0=10<<1|0; YO1=10<<1|1  // in edge  6->5 
  YG0=11<<1|0; YG1=11<<1|1  // in edge  7->6

 // 8 Corner byte position indexes on the cube
 iWRB=0; iWBO; iWOG; iWGR // White corners 
 iYBR;   iYOB; iYGO; iYRG // Yellow corners

 // 12 Edge byte position indexes on the cube
 iWR; iWB; iWO; iWG
 iBR; iOB; iGO; iRG
 iYR; iYB; iYO; iYG

 s_chain= iYG / bytesperword + 1 // Hash chain field
 s_link                          // Link to next node with the same dist value
 s_dist                          // -1 or distance from start node
 s_prev                          // Immediate predecessor
 s_move                          // The move from predecessor to this node
 nodeupb = s_move

 spacevupb = 100_000_000
 hashtabsize = 17_389  // The 2000th prime
 hashtabupb = hashtabsize-1
 listvupb = 200

 // Moves for Upper, Front, Right, Back, Left and Down
 //   c = clockwise
 //   a = anti clockwise
 // These are used to record the sequence of moves
 mUc='U'; mUa='u'
 mFc='F'; mFa='f'
 mRc='R'; mRa='r'
 mBc='B'; mBa='b'
 mLc='L'; mLa='l'
 mDc='D'; mDa='d'
}

GLOBAL {
 // 8 Corner positions on the p cube as global variables
 pWRB:ug; pWBO; pWOG; pWGR // White corners 
 pYBR;    pYOB; pYGO; pYRG // Yellow corners
 pWR; pWB; pWO; pWG // 12 Edge positions on the p cube
 pBR; pOB; pGO; pRG
 pYR; pYB; pYO; pYG
 
 // 8 Corner positions on the q cube as global variables
 qWRB; qWBO; qWOG; qWGR // White corners 
 qYBR; qYOB; qYGO; qYRG // Yellow corners
 qWR; qWB; qWO; qWG     // 12 Edge positions on the q cube
 qBR; qOB; qGO; qRG
 qYR; qYB; qYO; qYG
 
 spacev; spacep; spacet
 nodecount
 hashtab
 listv
 cube          // A packed cube -- 20 bytes = 5 words
 colour        // colour!0 .. colour!53
 errors        // =TRUE if an error has occurred
 moves         // Initialising moves supplied by -m argument
 dist          // Current distance from the starting position
 prnode
 tracing
 compact       // =TRUE for compact configuration output
 randomise     // Set by the -r or -s options
}

LET hashfn(node) = VALOF
{ // Return a hash value in range 0 to hashtabupb
  LET w = node!0 XOR node!1 XOR node!2 XOR node!3 XOR node!4
  LET h = w MOD hashtabsize
  UNLESS 0 <= h <= hashtabupb DO
  { prnode(node)
    writef("%x8 %x8 %x8 %x8 %x8*n",
           node!0, node!1, node!2, node!3, node!4)
    writef("w = %x8 => hashval = %n*n", w, h)
    abort(999)
  }
  RESULTIS h
}
AND newnode(cube, prev, dist, move) = VALOF
{ // Find the node that matches the configuration in cube
  // prev=0 or is the immediate predecessor
  // dist is the distance from the starting node
  // move=0 or is the move to reach this node
  // These values are only used if the node has not been seen before.
  // It return 0 if the node already exists, otherwise it return
  // a newly created node.
  LET hashval = hashfn(cube)
  LET node    = hashtab!hashval
//writef("hashval=%n node=%n*n", hashval, node)
  WHILE node DO
  { IF cube!0=node!0 &
       cube!1=node!1 &
       cube!2=node!2 &
       cube!3=node!3 &
       cube!4=node!4 DO
    { //writef("node %n has been seen before*n", node)
      RESULTIS 0  // The node already exists
    }
    node := s_chain!node
  }
//writef("Matching node not found so create one*n")

  // The matching node has not been found so create one.

  node := mkvec(nodeupb)
  UNLESS node DO
  { writef("Mode space needed*n")
    abort(999)
    RESULTIS 0
  }
  // Fill in all its fields
  node!0 := cube!0 // The corners
  node!1 := cube!1
  node!2 := cube!2 // The edges
  node!3 := cube!3
  node!4 := cube!4

  // Fill in its remaining fields
  s_dist!node := dist
  s_prev!node := prev
  s_move!node := move
  // Insert into its list
  s_link!node := listv!dist
  listv!dist := node

 // Insert it into its hash chain
  s_chain!node := hashtab!hashval
  hashtab!hashval := node

  nodecount := nodecount+1

  //writef("New node %n, nodecount=%n*n", node, nodecount)
  IF tracing DO
  { writef("Inserted node %n at head of list %n, nodecount=%n*n",
            node, dist, nodecount)
    prnode(node)
  }

  RESULTIS node
}

AND mkvec(upb) = VALOF
{ LET p = spacep
  spacep := spacep+upb+1
  IF spacep>spacet DO
  { writef("Insufficient space*n")
    abort(999)
    RESULTIS 0
  }
  RESULTIS p
}

LET start() = VALOF
{ LET argv = VEC 50
  LET v    = VEC nodeupb
  LET c    = VEC 6*9-1
  LET lv   = VEC listvupb
  LET root = 0

  cube   := v     // Structure representing the current state of the cube
  colour := c
  listv  := lv
  errors := FALSE

  UNLESS rdargs("W,R,B,O,G,Y,-m/K,-s/K/N,-r/S,-t/S,-c/S", argv, 50) DO
  { writef("Bad arguments for Rubik*n")
    RESULTIS 0
  }

  // Set default colours of the solved cube
  FOR i =  0 TO  8 DO colour!i := 'W'
  FOR i =  9 TO 17 DO colour!i := 'R'
  FOR i = 18 TO 26 DO colour!i := 'B'
  FOR i = 27 TO 35 DO colour!i := 'O'
  FOR i = 36 TO 44 DO colour!i := 'G'
  FOR i = 45 TO 53 DO colour!i := 'Y'

  // Set user specified colours
  IF argv!0 DO setface(0, 'W', argv!0) // W
  IF argv!1 DO setface(1, 'R', argv!1) // R
  IF argv!2 DO setface(2, 'B', argv!2) // B
  IF argv!3 DO setface(3, 'O', argv!3) // O
  IF argv!4 DO setface(4, 'G', argv!4) // G
  IF argv!5 DO setface(5, 'Y', argv!5) // Y

  moves   := argv!6                    // -m/K

  randomise := FALSE

  IF argv!7 DO                         // -s/K/N
  { writef("calling setseed(%n)*n", !(argv!7))
    setseed(!(argv!7))
    randomise := TRUE
  }
  IF argv!8 DO randomise := TRUE       // -r/S
  tracing := argv!9                    // -t/S
  compact := argv!10                   // -c/S

  cols2cube(colour, cube)
  cube2pieces(cube, @pWRB)

  // Make initial moves, if any
  IF moves FOR i = 1 TO moves%0 DO
  { SWITCHON moves%i INTO
    { DEFAULT:  writef("Bad initial moves %s*n", moves)
                errors := TRUE
                BREAK

      CASE 'U': rotateUc(); ENDCASE
      CASE 'u': rotateUa(); ENDCASE
      CASE 'F': rotateFc(); ENDCASE
      CASE 'f': rotateFa(); ENDCASE
      CASE 'R': rotateRc(); ENDCASE
      CASE 'r': rotateRa(); ENDCASE
      CASE 'B': rotateBc(); ENDCASE
      CASE 'b': rotateBa(); ENDCASE
      CASE 'L': rotateLc(); ENDCASE
      CASE 'l': rotateLa(); ENDCASE
      CASE 'D': rotateDc(); ENDCASE
      CASE 'd': rotateDa(); ENDCASE
    }
    movecubeq2p()
  }
  
  // Possibly randomise the cube
  IF randomise FOR i = 1 TO 200 DO
  { SWITCHON randno(15) INTO
    { DEFAULT:  LOOP

      CASE  1: rotateUc(); ENDCASE
      CASE  2: rotateUa(); ENDCASE
      CASE  3: rotateFc(); ENDCASE
      CASE  4: rotateFa(); ENDCASE
      CASE  5: rotateRc(); ENDCASE
      CASE  6: rotateRa(); ENDCASE
      CASE  7: rotateBc(); ENDCASE
      CASE  8: rotateBa(); ENDCASE
      CASE  9: rotateLc(); ENDCASE
      CASE 10: rotateLa(); ENDCASE
      CASE 11: rotateDc(); ENDCASE
      CASE 12: rotateDa(); ENDCASE
    }
    movecubeq2p()
  }
  
  IF errors RESULTIS 0

  // Pack the starting position in cube
  pieces2cube(@pWRB, cube)

  writef("*nThe starting position is:*n*n")
  //prpieces(@pWRB); newline()
  prnode(cube)
  newline()
//abort(1000)

  spacev := getvec(spacevupb)

  UNLESS spacev DO
  { writef("Insufficient space available*n")
    RESULTIS 20
  }

  spacep, spacet := spacev, spacev+spacevupb

  hashtab := mkvec(hashtabupb)
  FOR i = 0 TO hashtabupb DO hashtab!i := 0

  // Initialise the listv table
  listv   := mkvec(listvupb)
  FOR i = 0 TO listvupb DO listv!i := 0

  nodecount := 0

  // The starting node configuration is now in cube

  writef("Creating the starting position*n")

  // Create a node for the starting position at dist=0
  dist := 0
  listv!0 := 0
  // Create a new node with prev=0, dist=0 and no move
  root := newnode(cube, 0, 0, 0)

  // Search for node satifying goal 1 that is closest to root
  // and make this the new root

// Try to find optimal paths from one goal to another
// using a selection of goals.

  //root := exploreroot(root,  1)
  //root := exploreroot(root,  2)
  //root := exploreroot(root,  3)
  //root := exploreroot(root,  4)
  root := exploreroot(root,  5)
  //root := exploreroot(root,  6)
  //root := exploreroot(root,  7)
  //root := exploreroot(root,  8)
  root := exploreroot(root,  9)
  root := exploreroot(root, 10)
  root := exploreroot(root, 11)
  root := exploreroot(root, 12)
  root := exploreroot(root, 13)
  root := exploreroot(root, 14)
  root := exploreroot(root, 15)
  //root := exploreroot(root, 16)
  //root := exploreroot(root, 17)
  //root := exploreroot(root, 18)
  //root := exploreroot(root, 19)
  //root := exploreroot(root, 20)

  writef("*nSolution*n*n")
  prsolution(root)

  writef("*nnodecount = %n*n", nodecount)
  writef("space used: %n out of %n*n",
         spacep-spacev, spacet-spacev)

  IF spacev  DO freevec(spacev)
  RESULTIS 0
}

AND exploreroot(root, goal) = VALOF
{ // root is a new root node from which to start a breadth first search
  // to find a nearest node satifying goal.
  // The return is this node, or zero if no solution can be found.
  LET node = root

  // Does this root satisfy the goal
  IF atgoal(root, goal) RESULTIS root

  dist := s_dist!node

  writef("exploreroot: goal=%i2 dist=%i3 space used = %n*n",
          goal, dist, spacep-spacev)
  prnode(root)

  // Make it the only item in listv!dist
  s_link!root := 0
  listv!dist := root

  IF explorelist(dist, goal) RESULTIS result2
  RESULTIS 0
}

AND explorelist(dist, goal) = VALOF
{ // Add all successors of the nodes in listv!dist to listv!(dist+1)
  // Return TRUE is a node is found satifying goal.
  // returning this node is returned in result2
  LET node = listv!dist
  dist := dist+1
  listv!dist := 0 // Initialise the next list

  WHILE node DO
  { // Test to see this node already satifies the goal
    IF atgoal(node, goal) DO
    { writef("explore: This node already satisfies goal %n*n", goal)
      abort(2003)
      result2 := node
      RESULTIS TRUE
    }

    //writef("explorelist: Looking at successors of*n")
    //prnode(node)
    //abort(1000)

    // Try the 12 possible successors of this node
    // in the list.

    // First unpack node in pWRB, etc
    cube2pieces(node, @pWRB)

    IF try(rotateUc, node, mUc, goal) RESULTIS TRUE
    IF try(rotateUa, node, mUa, goal) RESULTIS TRUE
    IF try(rotateFc, node, mFc, goal) RESULTIS TRUE
    IF try(rotateFa, node, mFa, goal) RESULTIS TRUE
    IF try(rotateRc, node, mRc, goal) RESULTIS TRUE
    IF try(rotateRa, node, mRa, goal) RESULTIS TRUE
    IF try(rotateBc, node, mBc, goal) RESULTIS TRUE
    IF try(rotateBa, node, mBa, goal) RESULTIS TRUE
    IF try(rotateLc, node, mLc, goal) RESULTIS TRUE
    IF try(rotateLa, node, mLa, goal) RESULTIS TRUE
    IF try(rotateDc, node, mDc, goal) RESULTIS TRUE
    IF try(rotateDa, node, mDa, goal) RESULTIS TRUE
    // Now deal with the next node in the list
    node := s_link!node
  }
} REPEAT

AND try(rotfn, prev, move, goal) = VALOF
{ // Try a successor of node prev
  LET node = ?
  //writef("try: move=%c*n", move)
  //prpieces(@pWRB)
  rotfn()  // q cube := p cube with one face rotated
  //newline()
  //prpieces(@qWRB)
  //abort(1000)
  pieces2cube(@qWRB, cube)
  node := newnode(cube, prev, s_dist!prev+1, move)

  IF node & atgoal(node, goal) DO
  { // We have found a node that satisfies goal
    //writef("Try: Found a node that satisfies goal %n*n", goal)
    //prnode(node)
    //abort(2005)
    result2 := node
    RESULTIS TRUE
  }
  RESULTIS FALSE
}

AND pieces2cube(pieces, cube) BE
{ cube%iWRB := pieces!iWRB
  cube%iWBO := pieces!iWBO
  cube%iWOG := pieces!iWOG
  cube%iWGR := pieces!iWGR
  cube%iYBR := pieces!iYBR
  cube%iYOB := pieces!iYOB
  cube%iYGO := pieces!iYGO
  cube%iYRG := pieces!iYRG

  cube%iWR  := pieces!iWR
  cube%iWB  := pieces!iWB
  cube%iWO  := pieces!iWO
  cube%iWG  := pieces!iWG

  cube%iBR  := pieces!iBR
  cube%iOB  := pieces!iOB
  cube%iGO  := pieces!iGO
  cube%iRG  := pieces!iRG

  cube%iYR  := pieces!iYR
  cube%iYB  := pieces!iYB
  cube%iYO  := pieces!iYO
  cube%iYG  := pieces!iYG
}

AND cube2pieces(cube, pieces) BE
{ pieces!iWRB := cube%iWRB
  pieces!iWBO := cube%iWBO
  pieces!iWOG := cube%iWOG
  pieces!iWGR := cube%iWGR
  pieces!iYBR := cube%iYBR
  pieces!iYOB := cube%iYOB
  pieces!iYGO := cube%iYGO
  pieces!iYRG := cube%iYRG

  pieces!iWR  := cube%iWR
  pieces!iWB  := cube%iWB
  pieces!iWO  := cube%iWO
  pieces!iWG  := cube%iWG

  pieces!iBR  := cube%iBR
  pieces!iOB  := cube%iOB
  pieces!iGO  := cube%iGO
  pieces!iRG  := cube%iRG

  pieces!iYR  := cube%iYR
  pieces!iYB  := cube%iYB
  pieces!iYO  := cube%iYO
  pieces!iYG  := cube%iYG
}

AND rotc(piece) = VALOF SWITCHON piece INTO
{ // Rotate a corner piece one position clockwise
  DEFAULT:  writef("rotc: System error, piece=%n*n", piece)
            abort(999)
            RESULTIS piece

  CASE WRB1: CASE WRB2: CASE WBO1: CASE WBO2:
  CASE WOG1: CASE WOG2: CASE WGR1: CASE WGR2:
  CASE YBR1: CASE YBR2: CASE YOB1: CASE YOB2:
  CASE YGO1: CASE YGO2: CASE YRG1: CASE YRG2:
            RESULTIS piece-1

  CASE WRB0: CASE WBO0: CASE WOG0: CASE WGR0:
  CASE YOB0: CASE YBR0: CASE YGO0: CASE YRG0:
            RESULTIS piece+2
}

AND rota(piece) = VALOF SWITCHON piece INTO
{ // Rotate a corner piece one position anti-clockwise
  DEFAULT:  writef("rot1: System error, piece=%n*n", piece)
            abort(999)
            RESULTIS piece


  CASE WRB0: CASE WRB1: CASE WBO0: CASE WBO1:
  CASE WOG0: CASE WOG1: CASE WGR0: CASE WGR1:
  CASE YBR0: CASE YBR1: CASE YOB0: CASE YOB1:
  CASE YGO0: CASE YGO1: CASE YRG0: CASE YRG1:
            RESULTIS piece+1

  CASE WRB2: CASE WBO2: CASE WOG2: CASE WGR2:
  CASE YOB2: CASE YBR2: CASE YGO2: CASE YRG2:
            RESULTIS piece-2
}

AND flip(piece) = piece XOR 1 // Flip an edge piece

AND rotateUc() BE
{ // Rotate the upper face clockwise by a quarter turn
  qWRB, qWBO, qWOG, qWGR := pWBO, pWOG, pWGR, pWRB // Rotated
  qYBR, qYOB, qYGO, qYRG := pYBR, pYOB, pYGO, pYRG // Not rotated
  qWR, qWB, qWO, qWG := pWB, pWO, pWG, pWR // Rotated
  qBR, qOB, qGO, qRG := pBR, pOB, pGO, pRG // Not rotated
  qYR, qYB, qYO, qYG := pYR, pYB, pYO, pYG // Not rotated
}

AND rotateUa() BE
{ // Rotate the upper face anti-clockwise by a quarter turn
  qWRB, qWBO, qWOG, qWGR := pWGR, pWRB, pWBO, pWOG // Rotated
  qYBR, qYOB, qYGO, qYRG := pYBR, pYOB, pYGO, pYRG // Not rotated
  qWR, qWB, qWO, qWG := pWG, pWR, pWB, pWO // Rotated
  qBR, qOB, qGO, qRG := pBR, pOB, pGO, pRG // Not rotated
  qYR, qYB, qYO, qYG := pYR, pYB, pYO, pYG // Not rotated
}

AND rotateDc() BE
{ // Rotate the down face clockwise by a quarter turn
  qWRB, qWBO, qWOG, qWGR := pWRB, pWBO, pWOG, pWGR // Not rotated
  qYBR, qYOB, qYGO, qYRG := pYRG, pYBR, pYOB, pYGO // Rotated
  qWR, qWB, qWO, qWG := pWR, pWB, pWO, pWG // Not rotated
  qBR, qOB, qGO, qRG := pBR, pOB, pGO, pRG // Not rotated
  qYR, qYB, qYO, qYG := pYG, pYR, pYB, pYO // Rotated
}

AND rotateDa() BE
{ // Rotate the down face anti-clockwise by a quarter turn
  qWRB, qWBO, qWOG, qWGR := pWRB, pWBO, pWOG, pWGR // Not rotated
  qYBR, qYOB, qYGO, qYRG := pYOB, pYGO, pYRG, pYBR // Rotated
  qWR, qWB, qWO, qWG := pWR, pWB, pWO, pWG // Not rotated
  qBR, qOB, qGO, qRG := pBR, pOB, pGO, pRG // Not rotated
  qYR, qYB, qYO, qYG := pYB, pYO, pYG, pYR // Rotated
}

AND rotateFc() BE
{ // Rotate the front face clockwise by a quarter turn
  qWRB, qYBR, qYRG, qWGR := rotc(pWGR), rota(pWRB), rotc(pYBR), rota(pYRG) // Rotated
  qWBO, qYOB, qYGO, qWOG := pWBO, pYOB, pYGO, pWOG // Not rotated
  qWR, qBR, qYR, qRG := flip(pRG), pWR, pBR, flip(pYR) // Rotated
  qWB, qYB, qYG, qWG := pWB, pYB, pYG, pWG // Not rotated
  qWO, qOB, qYO, qGO := pWO, pOB, pYO, pGO // Not rotated
}

AND rotateFa() BE
{ // Rotate the front face anti-clockwise by a quarter turn
  qWRB, qYBR, qYRG, qWGR := rotc(pYBR), rota(pYRG), rotc(pWGR), rota(pWRB) // Rotated
  qWBO, qYOB, qYGO, qWOG := pWBO, pYOB, pYGO, pWOG // Not rotated
  qWR, qBR, qYR, qRG := pBR, pYR, flip(pRG), flip(pWR) // Rotated
  qWB, qYB, qYG, qWG := pWB, pYB, pYG, pWG // Not rotated
  qWO, qOB, qYO, qGO := pWO, pOB, pYO, pGO // Not rotated
}

AND rotateBc() BE
{ // Rotate the back face clockwise by a quarter turn
  qWBO, qWOG, qYGO, qYOB := rota(pYOB), rotc(pWBO), rota(pWOG), rotc(pYGO) // Rotated
  qWRB, qWGR, qYRG, qYBR := pWRB, pWGR, pYRG, pYBR // Not rotated
  qWO, qGO, qYO, qOB := flip(pOB), pWO, pGO, flip(pYO) // Rotated
  qWB, qWG, qYG, qYB := pWB, pWG, pYG, pYB // Not rotated
  qWR, qRG, qYR, qBR := pWR, pRG, pYR, pBR // Not rotated
}

AND rotateBa() BE
{ // Rotate the back face anti-clockwise by a quarter turn
  qWBO, qWOG, qYGO, qYOB := rota(pWOG), rotc(pYGO), rota(pYOB), rotc(pWBO) // Rotated
  qWRB, qWGR, qYRG, qYBR := pWRB, pWGR, pYRG, pYBR // Not rotated
  qWO, qGO, qYO, qOB := pGO, pYO, flip(pOB), flip(pWO) // Rotated
  qWB, qWG, qYG, qYB := pWB, pWG, pYG, pYB // Not rotated
  qWR, qRG, qYR, qBR := pWR, pRG, pYR, pBR // Not rotated
}

AND rotateRc() BE
{ // Rotate the right face clockwise by a quarter turn
  qWRB, qWBO, qYOB, qYBR := rota(pYBR), rotc(pWRB), rota(pWBO), rotc(pYOB) // Rotated
  qWGR, qYRG, qYGO, qWOG := pWGR, pYRG, pYGO, pWOG // Not rotated
  qWB, qOB, qYB, qBR := flip(pBR), pWB, pOB, flip(pYB) // Rotated
  qWR, qWO, qYO, qYR := pWR, pWO, pYO, pYR // Not rotated
  qWG, qRG, qYG, qGO := pWG, pRG, pYG, pGO // Not rotated
}

AND rotateRa() BE
{ // Rotate the right face anti-clockwise by a quarter turn
  qWRB, qWBO, qYOB, qYBR := rota(pWBO), rotc(pYOB), rota(pYBR), rotc(pWRB) // Rotated
  qWGR, qYRG, qYGO, qWOG := pWGR, pYRG, pYGO, pWOG // Not rotated
  qWB, qOB, qYB, qBR := pOB, pYB, flip(pBR), flip(pWB) // Rotated
  qWR, qWO, qYO, qYR := pWR, pWO, pYO, pYR // Not rotated
  qWG, qRG, qYG, qGO := pWG, pRG, pYG, pGO // Not rotated
}

AND rotateLc() BE
{ // Rotate the left face clockwise by a quarter turn
  qWGR, qYRG, qYGO, qWOG := rotc(pWOG), rota(pWGR), rotc(pYRG), rota(pYGO) // Rotated
  qWBO, qYOB, qYBR, qWRB := pWBO, pYOB, pYBR, pWRB // Not rotated
  qWG, qRG, qYG, qGO := flip(pGO), pWG, pRG, flip(pYG) // Rotated
  qWR, qYR, qYO, qWO := pWR, pYR, pYO, pWO // Not rotated
  qWB, qOB, qYB, qBR := pWB, pOB, pYB, pBR // Not rotated
}

AND rotateLa() BE
{ // Rotate the left face anti-clockwise by a quarter turn
  qWGR, qYRG, qYGO, qWOG := rotc(pYRG), rota(pYGO), rotc(pWOG), rota(pWGR) // Rotated
  qWBO, qYOB, qYBR, qWRB := pWBO, pYOB, pYBR, pWRB // Not rotated
  qWG, qRG, qYG, qGO := pRG, pYG, flip(pGO), flip(pWG) // Rotated
  qWR, qYR, qYO, qWO := pWR, pYR, pYO, pWO // Not rotated
  qWB, qOB, qYB, qBR := pWB, pOB, pYB, pBR // Not rotated
}

AND movecubep2q() BE
{ qWRB, qWBO, qWOG, qWGR := pWRB, pWBO, pWOG, pWGR
  qYBR, qYOB, qYGO, qYRG := pYBR, pYOB, pYGO, pYRG
  qWR, qWB, qWO, qWG := pWR, pWB, pWO, pWG
  qBR, qOB, qGO, qRG := pBR, pOB, pGO, pRG
  qYR, qYB, qYO, qYG := pYR, pYB, pYO, pYG
}

AND movecubeq2p() BE
{ pWRB, pWBO, pWOG, pWGR := qWRB, qWBO, qWOG, qWGR
  pYBR, pYOB, pYGO, pYRG := qYBR, qYOB, qYGO, qYRG
  pWR, pWB, pWO, pWG := qWR, qWB, qWO, qWG
  pBR, pOB, pGO, pRG := qBR, qOB, qGO, qRG
  pYR, pYB, pYO, pYG := qYR, qYB, qYO, qYG
}

AND prnodelist(n) BE
{ LET node = listv!n
  writef("Node list %n*n", n)
  WHILE node DO
  { prnode(node)
    node := s_link!node
  }
}

AND prsolution(node) BE
{ IF s_prev!node DO
  { prsolution(s_prev!node)
    writef("move %c*n", s_move!node)
  }
  prcube(node)
}

AND prpieces(pieces) BE
{ LET c = VEC 4
  pieces2cube(pieces, c)
  writef(" WRB:%n/%n", c% 0>>2, c% 0&3)
  writef(" WBO:%n/%n", c% 1>>2, c% 1&3)
  writef(" WOG:%n/%n", c% 2>>2, c% 2&3)
  writef(" WGR:%n/%n", c% 3>>2, c% 3&3)
  writef(" YBR:%n/%n", c% 4>>2, c% 4&3)
  writef(" YOB:%n/%n", c% 5>>2, c% 5&3)
  writef(" YGO:%n/%n", c% 6>>2, c% 6&3)
  writef(" YRG:%n/%n", c% 7>>2, c% 7&3)
  newline()
  writef(" WR:%i2/%n", c% 8>>1, c% 8&1)
  writef(" WB:%i2/%n", c% 9>>1, c% 9&1)
  writef(" WO:%i2/%n", c%10>>1, c%10&1)
  writef(" WG:%i2/%n", c%11>>1, c%11&1)
  writef(" BR:%i2/%n", c%12>>1, c%12&1)
  writef(" OB:%i2/%n", c%13>>1, c%13&1)
  writef(" GO:%i2/%n", c%14>>1, c%14&1)
  writef(" RG:%i2/%n", c%15>>1, c%15&1)
  writef(" YR:%i2/%n", c%16>>1, c%16&1)
  writef(" YB:%i2/%n", c%17>>1, c%17&1)
  writef(" YO:%i2/%n", c%18>>1, c%18&1)
  writef(" YG:%i2/%n", c%19>>1, c%19&1)
  newline()
  prcube(c)
}

AND prnode(node) BE
{  //writef("node=%n link=%n dist=%n prev=%n*n",
   //        node, s_link!node, s_dist!node, s_prev!node)
   prcube(node)
}

AND prcube(cube) BE
{ /* Typical output is either

  WWWWWWWWW GGGGGGGGG RRRRRRRRR BBBBBBBBB OOOOOOOOO YYYYYYYYY

  or

          W W W
          W W W
          W W W
   G G G  R R R  B B B  O O O
   G G G  R R R  B B B  O O O
   G G G  R R R  B B B  O O O
          Y Y Y
          Y Y Y
          Y Y Y
  */

  cube2cols(cube, colour)

  IF compact DO
  { writef("%c%c%c%c%c%c%c%c%c ",          // Upper face
             colour!0, colour!1, colour!2,
             colour!3, colour!4, colour!5,
             colour!6, colour!7, colour!8)
    writef("%c%c%c%c%c%c%c%c%c ",          // Left face
             colour!36, colour!37, colour!38,
             colour!39, colour!40, colour!41,
             colour!42, colour!43, colour!44)
    writef("%c%c%c%c%c%c%c%c%c ",          // Front face
             colour! 9, colour!10, colour!11,
             colour!12, colour!13, colour!14,
             colour!15, colour!16, colour!17)
    writef("%c%c%c%c%c%c%c%c%c ",          // Right face
             colour!18, colour!19, colour!20,
             colour!21, colour!22, colour!23,
             colour!24, colour!25, colour!26)
    writef("%c%c%c%c%c%c%c%c%c ",          // Back face
             colour!27, colour!28, colour!29,
             colour!30, colour!31, colour!32,
             colour!33, colour!34, colour!35)
    writef("%c%c%c%c%c%c%c%c%c*n",          // Down face
             colour!45, colour!46, colour!47,
             colour!48, colour!49, colour!50,
             colour!51, colour!52, colour!53)
    RETURN
  }

  writef("         %c %c %c*n", colour!0, colour!1, colour!2)
  writef("         %c %c %c*n", colour!3, colour!4, colour!5)
  writef("         %c %c %c*n", colour!6, colour!7, colour!8)

  writef(" %c %c %c  ", colour!36, colour!37, colour!38)
  writef(" %c %c %c  ", colour! 9, colour!10, colour!11)
  writef(" %c %c %c  ", colour!18, colour!19, colour!20)
  writef(" %c %c %c*n", colour!27, colour!28, colour!29)

  writef(" %c %c %c  ", colour!39, colour!40, colour!41)
  writef(" %c %c %c  ", colour!12, colour!13, colour!14)
  writef(" %c %c %c  ", colour!21, colour!22, colour!23)
  writef(" %c %c %c*n", colour!30, colour!31, colour!32)

  writef(" %c %c %c  ", colour!42, colour!43, colour!44)
  writef(" %c %c %c  ", colour!15, colour!16, colour!17)
  writef(" %c %c %c  ", colour!24, colour!25, colour!26)
  writef(" %c %c %c*n", colour!33, colour!34, colour!35)

  writef("         %c %c %c*n", colour!45, colour!46, colour!47)
  writef("         %c %c %c*n", colour!48, colour!49, colour!50)
  writef("         %c %c %c*n", colour!51, colour!52, colour!53)

}

AND setface(n, ch, str) BE
{ LET face = @colour!(9*n)
  UNLESS str%0=9 & str%5=ch DO
  { writef("Bad face colours %c %s*n", ch, str)
    errors := TRUE
  }
  FOR i = 1 TO str%0 DO face!(i-1) := str%i
}

AND corner(a, b, c) = VALOF SWITCHON a<<16 | b<<8 | c INTO
{ DEFAULT:  writef("*nBad corner: %c%c%c*n", a, b, c)
            errors := TRUE
            RESULTIS 0

  CASE 'W'<<16 | 'R'<<8 | 'B': RESULTIS WRB0
  CASE 'B'<<16 | 'W'<<8 | 'R': RESULTIS WRB1
  CASE 'R'<<16 | 'B'<<8 | 'W': RESULTIS WRB2

  CASE 'W'<<16 | 'B'<<8 | 'O': RESULTIS WBO0
  CASE 'O'<<16 | 'W'<<8 | 'B': RESULTIS WBO1
  CASE 'B'<<16 | 'O'<<8 | 'W': RESULTIS WBO2

  CASE 'W'<<16 | 'O'<<8 | 'G': RESULTIS WOG0
  CASE 'G'<<16 | 'W'<<8 | 'O': RESULTIS WOG1
  CASE 'O'<<16 | 'G'<<8 | 'W': RESULTIS WOG2

  CASE 'W'<<16 | 'G'<<8 | 'R': RESULTIS WGR0
  CASE 'R'<<16 | 'W'<<8 | 'G': RESULTIS WGR1
  CASE 'G'<<16 | 'R'<<8 | 'W': RESULTIS WGR2

  CASE 'Y'<<16 | 'B'<<8 | 'R': RESULTIS YBR0
  CASE 'R'<<16 | 'Y'<<8 | 'B': RESULTIS YBR1
  CASE 'B'<<16 | 'R'<<8 | 'Y': RESULTIS YBR2

  CASE 'Y'<<16 | 'O'<<8 | 'B': RESULTIS YOB0
  CASE 'B'<<16 | 'Y'<<8 | 'O': RESULTIS YOB1
  CASE 'O'<<16 | 'B'<<8 | 'Y': RESULTIS YOB2

  CASE 'Y'<<16 | 'G'<<8 | 'O': RESULTIS YGO0
  CASE 'O'<<16 | 'Y'<<8 | 'G': RESULTIS YGO1
  CASE 'G'<<16 | 'O'<<8 | 'Y': RESULTIS YGO2

  CASE 'Y'<<16 | 'R'<<8 | 'G': RESULTIS YRG0
  CASE 'G'<<16 | 'Y'<<8 | 'R': RESULTIS YRG1
  CASE 'R'<<16 | 'G'<<8 | 'Y': RESULTIS YRG2
}

AND edge(a, b) = VALOF SWITCHON a<<8 | b INTO
{ DEFAULT:  writef("*nBad edge: %c%c*n", a, b)
            errors := TRUE
            RESULTIS 0

  CASE 'W'<<8 | 'R': RESULTIS WR0
  CASE 'R'<<8 | 'W': RESULTIS WR1
  CASE 'W'<<8 | 'B': RESULTIS WB0
  CASE 'B'<<8 | 'W': RESULTIS WB1
  CASE 'W'<<8 | 'O': RESULTIS WO0
  CASE 'O'<<8 | 'W': RESULTIS WO1
  CASE 'W'<<8 | 'G': RESULTIS WG0
  CASE 'G'<<8 | 'W': RESULTIS WG1

  CASE 'B'<<8 | 'R': RESULTIS BR0
  CASE 'R'<<8 | 'B': RESULTIS BR1
  CASE 'O'<<8 | 'B': RESULTIS OB0
  CASE 'B'<<8 | 'O': RESULTIS OB1
  CASE 'G'<<8 | 'O': RESULTIS GO0
  CASE 'O'<<8 | 'G': RESULTIS GO1
  CASE 'R'<<8 | 'G': RESULTIS RG0
  CASE 'G'<<8 | 'R': RESULTIS RG1

  CASE 'Y'<<8 | 'R': RESULTIS YR0
  CASE 'R'<<8 | 'Y': RESULTIS YR1
  CASE 'Y'<<8 | 'B': RESULTIS YB0
  CASE 'B'<<8 | 'Y': RESULTIS YB1
  CASE 'Y'<<8 | 'O': RESULTIS YO0
  CASE 'O'<<8 | 'Y': RESULTIS YO1
  CASE 'Y'<<8 | 'G': RESULTIS YG0
  CASE 'G'<<8 | 'Y': RESULTIS YG1
}

AND cols2cube(cv, cube) BE
{ // Colour coordinates

  //            0  1  2
  //            3  4  5
  //            6  7  8
  // 36 37 38   9 10 11  18 19 20  27 28 29
  // 39 40 41  12 13 14  21 22 23  30 31 32
  // 42 43 44  15 16 17  24 25 26  33 34 35
  //           45 46 47
  //           48 49 50
  //           51 52 53

  cube%iWRB := corner(cv! 8, cv!11, cv!18)
  cube%iWBO := corner(cv! 2, cv!20, cv!27)
  cube%iWOG := corner(cv! 0, cv!29, cv!36)
  cube%iWGR := corner(cv! 6, cv!38, cv! 9)
  cube%iYBR := corner(cv!47, cv!24, cv!17)
  cube%iYOB := corner(cv!53, cv!33, cv!26)
  cube%iYGO := corner(cv!51, cv!42, cv!35)
  cube%iYRG := corner(cv!45, cv!15, cv!44)

  cube%iWR  := edge(cv! 7, cv!10)
  cube%iWB  := edge(cv! 5, cv!19)
  cube%iWO  := edge(cv! 1, cv!28)
  cube%iWG  := edge(cv! 3, cv!37)

  cube%iBR  := edge(cv!21, cv!14)
  cube%iOB  := edge(cv!30, cv!23)
  cube%iGO  := edge(cv!39, cv!32)
  cube%iRG  := edge(cv!12, cv!41)

  cube%iYR  := edge(cv!46, cv!16)
  cube%iYB  := edge(cv!50, cv!25)
  cube%iYO  := edge(cv!52, cv!34)
  cube%iYG  := edge(cv!48, cv!43)
}

AND cube2cols(cube, cv) BE
{ // Colour coordinates

  //            0  1  2
  //            3  4  5
  //            6  7  8
  // 36 37 38   9 10 11  18 19 20  27 28 29
  // 39 40 41  12 13 14  21 22 23  30 31 32
  // 42 43 44  15 16 17  24 25 26  33 34 35
  //           45 46 47
  //           48 49 50
  //           51 52 53

  cv! 4 := 'W'  // Fixed colours
  cv!13 := 'R'
  cv!22 := 'B'
  cv!31 := 'O'
  cv!40 := 'G'
  cv!49 := 'Y'

  setcornercols(cv, cube%iWRB,  8, 11, 18) // Corner pieces
  setcornercols(cv, cube%iWBO,  2, 20, 27) 
  setcornercols(cv, cube%iWOG,  0, 29, 36) 
  setcornercols(cv, cube%iWGR,  6, 38,  9) 
  setcornercols(cv, cube%iYBR, 47, 24, 17) 
  setcornercols(cv, cube%iYOB, 53, 33, 26) 
  setcornercols(cv, cube%iYGO, 51, 42, 35) 
  setcornercols(cv, cube%iYRG, 45, 15, 44)
 
  setedgecols(cv, cube%iWR,  7, 10)  // edge piece, left sq, right sq
  setedgecols(cv, cube%iWB,  5, 19)
  setedgecols(cv, cube%iWO,  1, 28)
  setedgecols(cv, cube%iWG,  3, 37)

  setedgecols(cv, cube%iBR, 21, 14)
  setedgecols(cv, cube%iOB, 30, 23)
  setedgecols(cv, cube%iGO, 39, 32)
  setedgecols(cv, cube%iRG, 12, 41)

  setedgecols(cv, cube%iYR, 46, 16)
  setedgecols(cv, cube%iYB, 50, 25)
  setedgecols(cv, cube%iYO, 52, 34)
  setedgecols(cv, cube%iYG, 48, 43)
}

AND setcornercols(cv, piece, i, j, k) BE
{ // i, j, k are corner face numbers in anti-clockwise order
  //writef("setcornercols %i2 %i2 %i2 %i2*n", piece, i, j, k)
  SWITCHON piece INTO
{ DEDAULT:    writef("System error in setcornercols: piece=%n*n", piece)

  CASE WRB0:  cv!i, cv!j, cv!k := 'W', 'R', 'B'; RETURN
  CASE WRB1:  cv!j, cv!k, cv!i := 'W', 'R', 'B'; RETURN
  CASE WRB2:  cv!k, cv!i, cv!j := 'W', 'R', 'B'; RETURN
  CASE WBO0:  cv!i, cv!j, cv!k := 'W', 'B', 'O'; RETURN
  CASE WBO1:  cv!j, cv!k, cv!i := 'W', 'B', 'O'; RETURN
  CASE WBO2:  cv!k, cv!i, cv!j := 'W', 'B', 'O'; RETURN
  CASE WOG0:  cv!i, cv!j, cv!k := 'W', 'O', 'G'; RETURN
  CASE WOG1:  cv!j, cv!k, cv!i := 'W', 'O', 'G'; RETURN
  CASE WOG2:  cv!k, cv!i, cv!j := 'W', 'O', 'G'; RETURN
  CASE WGR0:  cv!i, cv!j, cv!k := 'W', 'G', 'R'; RETURN
  CASE WGR1:  cv!j, cv!k, cv!i := 'W', 'G', 'R'; RETURN
  CASE WGR2:  cv!k, cv!i, cv!j := 'W', 'G', 'R'; RETURN

  CASE YBR0:  cv!i, cv!j, cv!k := 'Y', 'B', 'R'; RETURN
  CASE YBR1:  cv!j, cv!k, cv!i := 'Y', 'B', 'R'; RETURN
  CASE YBR2:  cv!k, cv!i, cv!j := 'Y', 'B', 'R'; RETURN
  CASE YOB0:  cv!i, cv!j, cv!k := 'Y', 'O', 'B'; RETURN
  CASE YOB1:  cv!j, cv!k, cv!i := 'Y', 'O', 'B'; RETURN
  CASE YOB2:  cv!k, cv!i, cv!j := 'Y', 'O', 'B'; RETURN
  CASE YGO0:  cv!i, cv!j, cv!k := 'Y', 'G', 'O'; RETURN
  CASE YGO1:  cv!j, cv!k, cv!i := 'Y', 'G', 'O'; RETURN
  CASE YGO2:  cv!k, cv!i, cv!j := 'Y', 'G', 'O'; RETURN
  CASE YRG0:  cv!i, cv!j, cv!k := 'Y', 'R', 'G'; RETURN
  CASE YRG1:  cv!j, cv!k, cv!i := 'Y', 'R', 'G'; RETURN
  CASE YRG2:  cv!k, cv!i, cv!j := 'Y', 'R', 'G'; RETURN
}
}

AND setedgecols(cv, piece, i, j) BE
{ //writef("setedgecols(%i2, %i2, %i2)*n", piece, i, j)
 SWITCHON piece INTO
{ DEFAULT:    writef("System error in setedgecols: piece=%n*n", piece)
              abort(999)

  CASE WR0:  cv!i, cv!j := 'W', 'R'; RETURN
  CASE WR1:  cv!j, cv!i := 'W', 'R'; RETURN
  CASE WB0:  cv!i, cv!j := 'W', 'B'; RETURN
  CASE WB1:  cv!j, cv!i := 'W', 'B'; RETURN
  CASE WO0:  cv!i, cv!j := 'W', 'O'; RETURN
  CASE WO1:  cv!j, cv!i := 'W', 'O'; RETURN
  CASE WG0:  cv!i, cv!j := 'W', 'G'; RETURN
  CASE WG1:  cv!j, cv!i := 'W', 'G'; RETURN

  CASE BR0:  cv!i, cv!j := 'B', 'R'; RETURN
  CASE BR1:  cv!j, cv!i := 'B', 'R'; RETURN
  CASE OB0:  cv!i, cv!j := 'O', 'B'; RETURN
  CASE OB1:  cv!j, cv!i := 'O', 'B'; RETURN
  CASE GO0:  cv!i, cv!j := 'G', 'O'; RETURN
  CASE GO1:  cv!j, cv!i := 'G', 'O'; RETURN
  CASE RG0:  cv!i, cv!j := 'R', 'G'; RETURN
  CASE RG1:  cv!j, cv!i := 'R', 'G'; RETURN

  CASE YR0:  cv!i, cv!j := 'Y', 'R'; RETURN
  CASE YR1:  cv!j, cv!i := 'Y', 'R'; RETURN
  CASE YB0:  cv!i, cv!j := 'Y', 'B'; RETURN
  CASE YB1:  cv!j, cv!i := 'Y', 'B'; RETURN
  CASE YO0:  cv!i, cv!j := 'Y', 'O'; RETURN
  CASE YO1:  cv!j, cv!i := 'Y', 'O'; RETURN
  CASE YG0:  cv!i, cv!j := 'Y', 'G'; RETURN
  CASE YG1:  cv!j, cv!i := 'Y', 'G'; RETURN
}
}

AND atgoal(cube, goal) = VALOF
{ LET k = 0

  //writef("atgoal: goal=%n*n", goal)
  //prnode(cube)
//writef("upper edges WR=%n/%n WB=%n/%n WO=%n/%n WG=%n/%n*n",
//        cube%iWR, WR0,
//        cube%iWB, WB0,
//        cube%iWO, WO0,
//        cube%iWG, WG0)
  // Upper edges
  IF cube%iWR=WR0 DO k := k+1
  IF cube%iWB=WB0 DO k := k+1
  IF cube%iWO=WO0 DO k := k+1
  IF cube%iWG=WG0 DO k := k+1
  //writef("atgoal: k=%n*n", k)
//abort(4000)
  IF goal=1 RESULTIS k>=1
  IF goal=2 RESULTIS k>=2
  IF goal=3 RESULTIS k>=3
  IF goal=4 RESULTIS k>=4

  IF k<4 RESULTIS FALSE

  // Upper four edges are correct

  // Upper corners
  IF cube%iWRB=WRB0 DO k := k+1
  IF cube%iWBO=WBO0 DO k := k+1
  IF cube%iWOG=WOG0 DO k := k+1
  IF cube%iWGR=WGR0 DO k := k+1
  //writef("atgoal: k=%n*n", k)

  IF goal=5 RESULTIS k>=5
  IF goal=6 RESULTIS k>=6
  IF goal=7 RESULTIS k>=7
  IF goal=8 RESULTIS k>=8

  IF k<8 RESULTIS FALSE
  
  // Upper layer is now correct

  // Middle layer edges

  IF cube%iBR=BR0 DO k := k+1
  IF cube%iOB=OB0 DO k := k+1
  IF cube%iGO=GO0 DO k := k+1
  IF cube%iRG=RG0 DO k := k+1
  //writef("atgoal: k=%n*n", k)

  IF goal= 9 RESULTIS k>= 9
  IF goal=10 RESULTIS k>=10
  IF goal=11 RESULTIS k>=11
  IF goal=12 RESULTIS k>=12

  IF k<12 RESULTIS FALSE

  // Upper and middle layers are now correct

  IF cube%iYR=YR0 DO k := k+1
  IF cube%iYB=YB0 DO k := k+1
  IF cube%iYO=YO0 DO k := k+1
  IF cube%iYG=YG0 DO k := k+1
  //writef("atgoal: k=%n*n", k)

  IF goal=13 RESULTIS k>=13
  IF goal=14 RESULTIS k>=14
  IF goal=15 RESULTIS k>=15
  IF goal=16 RESULTIS k>=16

  IF k<16 RESULTIS FALSE

  // Upper and middle layers are now correct
  // and down face edges are correct

  IF cube%iYBR=YBR0 DO k := k+1
  IF cube%iYOB=YOB0 DO k := k+1
  IF cube%iYGO=YGO0 DO k := k+1
  IF cube%iYRG=YRG0 DO k := k+1
  //writef("atgoal: k=%n*n", k)

  IF goal=17 RESULTIS k>=17
  IF goal=18 RESULTIS k>=18
  IF goal=19 RESULTIS k>=19
  IF goal=20 RESULTIS k>=20
  //writef("atgoal: k=%n*n", k)

  IF k<20 RESULTIS FALSE

  // All positions are correct so the Rubik Cube has been solved
  RESULTIS TRUE
} 
