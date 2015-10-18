/*
############ THIS PROGRAM IS UNDER DEVELOPMENT ############

This program attempts to find the enigma machine setting
given a long enough crib consisting of plain text and its
encryption. It uses a method based on that used by the bombe
machine developed by Alan Turing and others in Bletchley Park
in 1940.

Implemented by Martin Richards (c) October 2013

*/

SECTION "bombe"

GET "libhdr"

GLOBAL
{ spacev:ug; spacep; spacet

  inlet    // Plain text
  outlet   // Corresponding encrypted text
  len       // Number of characters in the crib

  tracing   // =TRUE causes tracing output

  rotorI;   notchI
  rotorII;  notchII
  rotorIII; notchIII
  rotorIV;  notchIV
  rotorV;   notchV
  reflectorB
  reflectorC

  rotorLname; rotorMname; rotorRname
  reflectorname

  // Ring and notch settings of the selected rotors
  ringL;  ringM;  ringR
  notchL; notchM; notchR

  // Rotor start positions at the beginning of the message
  initposL; initposM; initposR
  // Rotor current positions
  posL; posM; posR;
  notchposM; notchposR 

  nr
  turnpattern
  solutioncount

  // The following vectors have subscripts from 0 to 25
  // representing letters A to Z
  plugboard 
  rotorFR; rotorFM; rotorFL
  reflector
  rotorBL; rotorBM; rotorBR // Inverse rotors

  maps; mapM; mapL  // For the pre-computed map
  posLv; posMv; posRv

  // Variables for printing signal path
  pluginF
  rotorRinF; rotorMinF; rotorLinF
  reflin
  rotorLinB; rotorMinB; rotorRinB
  pluginB; plugoutB

  finP; finL

  // Global functions
  newvec; setvec
  setplugpair; prplugboardspairs; setrotor
  step_rotors; rotorfn

  setmaps
  setmapL
  setmapM
  setmapR

  nodetab   // Subscripts 0 to 25
  codev     // Code with intructions
            //   new X n Y
            //   tst X n Y
            //   fin
  codep     // Position of next code instruction

  gen1      // Generate interpretive instructions
  gen2
  gen4

  testsetting

  edgeused  // Vector of length len indicating which edges
            // have been used
  edgeusedcount

  posmapv   // For mapping at position pos
  patch     // The pluboard mapping
  prcode
}

MANIFEST {
  // Fields of a node
  n_parent=0 // Pointer to parent node, or zero if root
  n_letter   // The letter (0..25) of this node
  n_len      // Number of successor nodes
  n_list     // List of successors
  n_size     // If this node is a root, this field holds the number
             // of edges in this component
  n_visited  // This node has been visited during the tranlation process
  n_compiled // This node has been compiled
  n_upb = n_compiled

  // Fields of a successor list item
  e_next=0   // Pointer to next item or zero
  e_pos      // The position of the edge in the crib (1.. upwards)
  e_dest     // Destination node for this edge
  e_upb = e_dest

  // Instruction op codes
  c_guess=1   // Arg:  letter
  c_edge      // Args: src pos dest
  c_fin       // Args: none
}

LET newvec(upb) = VALOF
{ LET p = spacep - upb -1
  IF p<spacev DO
  { writef("More space needed*n")
    longjump(finP, finL)
    RESULTIS 0
  }
  spacep := p
  RESULTIS p
}

LET mk3(a, b, c) = VALOF
{ LET res = newvec(2)
  res!0, res!1, res!2 := a, b, c
//writef("mk3: %n -> [%n %n %n]*n", res, a, b, c)
  RESULTIS res
}

LET setvec(str, v) BE
  IF v FOR i = 0 TO 25 DO v!i := str%(i+1) - 'A'

LET setrotor(i, rf, rb) = VALOF
{ // i is the rotor number
  // rf is the forwad mapping vector
  // rb is the backward mapping vector
  // The result is the rotor name
  // result2 is the notch letter

  LET str, name, notchletter = 0,0,0

  SWITCHON i INTO
  { DEFAULT:  writef("*nBad rotor number %n*n", i)
              RESULTIS 0
    CASE 1:   str, name, notchletter := rotorI,   "I  ", notchI
              ENDCASE
    CASE 2:   str, name, notchletter := rotorII,  "II ", notchII
              ENDCASE
    CASE 3:   str, name, notchletter := rotorIII, "III", notchIII
              ENDCASE
    CASE 4:   str, name, notchletter := rotorIV,  "IV ", notchIV
              ENDCASE
    CASE 5:   str, name, notchletter := rotorV,   "V  ", notchV
              ENDCASE
  }
   
  FOR i = 0 TO 25 DO
  { LET j = str%(i+1)-'A'
    rf!i, rb!j := j, i
  }
  result2 := notchletter
  RESULTIS name
}

LET start() = VALOF
{ LET argv = VEC 50
  LET spaceupb = 500000 // just enough

  finP, finL := level(), fin

  UNLESS rdargs("-t/s", argv, 50) DO
  { writef("Bad arguments for enigma-m3*n")
    RESULTIS 0
  }

writef("*nEnigma message decoder*n")

  tracing := FALSE
  IF argv!0 DO tracing := ~tracing             // -t/s

  spacev := getvec(spaceupb)
  spacet := spacev+spaceupb
  spacep := spacet

// Set the rotor and reflector wirings
// and the notch positions. 

// Input      "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  rotorI   := "EKMFLGDQVZNTOWYHXUSPAIBRCJ";  notchI   := 'Q'
  rotorII  := "AJDKSIRUXBLHWTMCQGZNPYFVOE";  notchII  := 'E'
  rotorIII := "BDFHJLCPRTXVZNYEIWGAKMUSQO";  notchIII := 'V'
  rotorIV  := "ESOVPZJAYQUIRHXLNFTGKDCMWB";  notchIV  := 'J'
  rotorV   := "VZBRGITYUPSDNHLXAWMJQOFECK";  notchV   := 'Z'

  reflectorB := "YRUHQSLDPXNGOKMIEBFZCWVJAT"
  reflectorC := "FVPJIAOYEDRZXWGCTKUQSBNMHL"

// Allocate several vectors
  rotorFL   := newvec(25)
  rotorFM   := newvec(25)
  rotorFR   := newvec(25)
  rotorBL   := newvec(25)
  rotorBM   := newvec(25)
  rotorBR   := newvec(25)
  plugboard := newvec(25)
  reflector := newvec(25)
  inlet    := newvec(255)
  outlet   := newvec(255)

  nodetab   := newvec(25)
  codev     := newvec(64*4-1)
  codep := 0

  mapL      := newvec(25)
  mapM      := newvec(25)
  edgeused  := newvec(64)
  posmapv   := newvec(64)
  // Allocate mapping vectors for each position
  FOR pos = 1 TO 64 DO
    posmapv!pos := newvec(25)

  maps := newvec(26*26*26*26)

  patch := newvec(25)

  FOR i = 0 TO 25 DO plugboard!i := i

//writef("Set the the example message and its encryption*n")

  {  LET s1 = "DERFUEHRERISTTODXDERKAMPFGEHTWEITERXDOENITZX" // Plain
     LET s2 = "QBLTWLDAHHYEOEFPTWYBLENDPMKOXLDFAMUDWIJDXRJZ" // Encrypted
     len := s1%0
     FOR i = 1 TO len DO inlet!i, outlet!i := s1%i-'A', s2%i-'A' 
     // To test shorter cribs uncomment one of the following lines.
     // Tested on my Toshiba Laptop, using natbcpl.
     len := 29 // This finds  1 possible solution, refl B all rotors, 3m28s
     //len := 24 // This finds  2 possible solution, refl B all rotors, 2m58s
     //len := 16 // This finds  2 possible solutions, refl B all rotors, 3m19s 
     //len := 14 // This finds 53 possible solutions, refl B all rotors, 2m36s
     // On a 256Mb Raspberry Pi it takes 28m55s
  }

  // The following vectors hold the rotor letter positions
  // for each position (1 to len) in the message string.
  posLv     := newvec(len)
  posMv     := newvec(len)
  posRv     := newvec(len)

  writef("*nMemory used = %n*n", spacet-spacep)

  // Compile the crib
  trans(len, inlet, outlet)
  writef("Memory used after trans = %n*n", spacet-spacep)

  // Output the graph
  prgraph()

  // Generate code
  compilegraph()
  gen1(c_fin)  // Mark the end of the interpretive code

  // Output the corresponding test code
  prcode()

  solutioncount := 0

  tryreflector(reflectorB, "B")
  //tryreflector(reflectorC, "C")

  writef("*n%n solution%ps found*n", solutioncount, solutioncount)

fin:
  IF spacev DO freevec(spacev)
  RESULTIS 0
}

AND tryreflector(reflstr, name) BE
{ setvec(reflstr, reflector)
  reflectorname := name
  chooserotors()
}

AND chooserotors() BE
{ tryLrotor(1)
  //tryLrotor(2)
  //tryLrotor(3)
  //tryLrotor(4)
  //tryLrotor(5)
}

AND tryLrotor(rl) BE
{ rotorLname := setrotor(rl, rotorFL, rotorBL)
  notchL := result2-'A'
  //tryMrotor(rl, 1)
  tryMrotor(rl, 2)
  //tryMrotor(rl, 3)
  //tryMrotor(rl, 4)
  //tryMrotor(rl, 5)
}

AND tryMrotor(rl,rm) BE UNLESS rl=rm DO
{ rotorMname := setrotor(rm, rotorFM, rotorBM)
  notchM := result2-'A'
  //tryRrotor(rl, rm, 1)
  //tryRrotor(rl, rm, 2)
  //tryRrotor(rl, rm, 3)
  //tryRrotor(rl, rm, 4)
  tryRrotor(rl, rm, 5)
}

AND tryRrotor(rl, rm, rr) BE UNLESS rr=rl | rr=rm DO
{ rotorRname := setrotor(rr, rotorFR, rotorBR)
  notchR := result2-'A'
  writef("*nTesting reflector %s rotors %s %s %s  notches %c%c%c*n",
          reflectorname, rotorLname, rotorMname, rotorRname,
          notchL+'A', notchM+'A', notchR+'A')
  computemaps() // Pre-compute all 17576 maps putting them in posmapv

  // Test all rotor core positions
  FOR letl = 'A'-'A' TO 25 DO
  { writef("Trying posL=%c*n", letl+'A')
    FOR letm = 'A'-'A' TO 25 FOR letr = 'A'-'A' TO 25 DO
      testsetting(letl, letm, letr)
  }
}

AND computemaps() BE
{ //pre-compute the maps
  LET pos = maps

  ringL, ringM, ringR := 0, 0, 0

  FOR lpos = 0 TO 25 DO
  { setmapL(lpos, mapL)
    FOR mpos = 0 TO 25 DO
    { setmapM(mpos, mapM)
      FOR rpos = 0 TO 25 DO
      { setmapR(rpos, pos)
        pos := pos + 26
      }
    }
  }
}

AND step_rotors() BE
{ LET advM, advL = FALSE, FALSE
  IF posR=notchposR | posM=notchposM DO advM := TRUE 
  IF posM=notchposM DO advL := TRUE
  posR := (posR+1) MOD 26
  IF advM DO posM := (posM+1) MOD 26
  IF advL DO posL := (posL+1) MOD 26
}

AND rotorfn(x, map, pos) = VALOF
{ LET a = (x+pos+26) MOD 26
  LET b = map!a
  LET c = (b-pos+26) MOD 26
  RESULTIS c
}

AND setmapL(lpos, map) BE
{ FOR i = 0 TO 25 DO
  { LET a   = rotorfn(i, rotorFL, lpos)
    LET b   = reflector!a
    map!i := rotorfn(b, rotorBL, lpos)
  }
}

AND setmapM(mpos, map) BE
{ FOR i = 0 TO 25 DO
  { LET a   = rotorfn(i, rotorFM, mpos)
    LET b   = mapL!a
    map!i := rotorfn(b, rotorBM, mpos)
  }
}

AND setmapR(rpos, map) BE
{ FOR i = 0 TO 25 DO
  { LET a  = rotorfn(i, rotorFR, rpos)
    LET b  = mapM!a
    map!i := rotorfn(b, rotorBR, rpos)
  }
}

AND enigmaRfn(x) = VALOF
{ // Rotors right to left
  x := rotorfn(x, rotorFR, posR, ringR)
  x := rotorfn(x, rotorFM, posM, ringM)
  x := rotorfn(x, rotorFL, posL, ringL)
  // Reflector
  x := reflector!x
  // Rotors left to right
  x := rotorfn(x, rotorBL, posL, ringL)
  x := rotorfn(x, rotorBM, posM, ringM)
  x := rotorfn(x, rotorBR, posR, ringR)

  RESULTIS x
}

AND trans(len, plaintext, encryptedtext) BE
{ // Allocate the nodes
  FOR let = 0 TO 25 DO
  { // Create empty letter nodes
    LET node = newvec(n_upb)
    nodetab!let := node
    n_parent   !node := 0
    n_letter   !node := let
    n_len      !node := 0
    n_list     !node := 0
    n_size     !node := 0
    n_visited  !node := FALSE
    n_compiled !node := FALSE
  }
  newline()
  FOR pos = 1 TO len DO
  { LET a, b = plaintext!pos, encryptedtext!pos
    // a and b are in range 0 to 25
    addedge(a, pos, b)
  }
}

AND addedge(a, pos, b) BE
{ // Add edges a->b and b->a at position pos
  LET na = nodetab!a
  LET nb = nodetab!b
  LET ra = findroot(na)
  LET rb = findroot(nb)

  // Add edge a->b
  n_list!na := mk3(n_list!na, pos, nb)
  n_len!na := n_len!na + 1

  // Add edge b->a
  n_list!nb := mk3(n_list!nb, pos, na)
  n_len!nb := n_len!nb + 1

  TEST ra=rb
  THEN { n_size!ra := n_size!ra + 1
       }
  ELSE { // This edge joins two previously unconnected components
         // Choose the larger of ra and rb as the newroot and
         // combined the components.
         LET newsize = n_size!ra + n_size!rb + 1
         TEST n_size!ra < n_size!rb
         THEN { // rb becomes the new root
                n_size!rb := newsize
                n_parent!ra := rb
              }
         ELSE { // ra becomes the new root
                n_size!ra := newsize
                n_parent!rb := ra
              }
  }
}

AND findroot(x) = VALOF
{ LET p = n_parent!x
  UNLESS p RESULTIS x
  p := findroot(p)
  // As an optimisation, make the parent link of x
  // point directly to the root node.
  n_parent!x := p
  RESULTIS p
}

AND prgraph() BE
{ newline()
  FOR let = 0 TO 25 DO
  { LET node  = nodetab!let
    LET list  = n_list!node
    LET root  = findroot(node)
    LET size  = n_size!root
    LET len   = n_len!node

    sawritef("%c: %c %i2 ", let+'A', n_letter!root+'A', n_size!root)
    WHILE list DO
    { writef(" %2i%c", e_pos!list, n_letter!(e_dest!list)+'A')
      list := e_next!list
    }
    newline()
  }
}

AND compilegraph() BE
{ FOR i = 1 TO len DO edgeused!i := FALSE
  edgeusedcount := 0

  FOR let = 0 TO 25 DO
  { LET node = nodetab!let
    n_compiled!node, n_visited!node := FALSE, FALSE
  }
  // Generate code for all the components
  gencode()
  // generate a fin instruction to indicate that all edges have been
  // processed and no inconsistencies have been found.
  gen1(c_fin)
}

AND gencode() BE WHILE edgeusedcount<len DO
{ // While there are still unused edges choose a good starting node
  // and the compile its component.

  // First search for an unvisited node belonging to one of the
  // largest components and having the most loops of length two.
  LET startnode = choosestartnode()
  gen2(c_guess, n_letter!startnode)
  n_visited!startnode := TRUE

  // Compile the component that the start node is in.
  compilecomponent()

  // Mark all visited nodes as compiled so that they will play no
  // further part in the compilation.
  FOR let = 0 TO 25 DO
  { LET node = nodetab!let
    IF n_visited!node DO n_compiled!node := TRUE
  }

//writef("Component with start node %c compiled*n", n_letter!startnode+'A')
//abort(1111)
}

AND choosestartnode() = VALOF
{ // Find a node that belongs to a largest component of uncompiled
  // nodes prefering one that is in the largest number of loops of
  // size two. If this search fails, choose one with the largest
  // number of edges.
  LET bestnode, bestsize, bestlen, bestcount = nodetab!0, 0, 0, 0

  FOR let = 0 TO 25 DO
  { LET node = nodetab!let
    UNLESS n_compiled!node DO
    { LET root = findroot(node)
      LET size = n_size!root
//writef("Considering node %c size %n bestsize %n*n",
//        let+'A', size, bestsize) 
      IF size > bestsize DO
        bestnode, bestsize, bestcount := node, size, 0
      IF size=bestsize DO
      { // Count the number of loops of size 2
        LET p = n_list!node

        // If no loops of size zero choose a node with most edges
        IF bestcount=0 & n_len!node > bestlen DO
          bestnode, bestlen := node, n_len!node

        //Check for loops of length two
        WHILE p DO
        { LET destp = e_dest!p
          LET q = e_next!p
          LET count = 0
//          writef("%c%n%c  ", let+'A', e_pos!p, n_letter!destp+'A')
          WHILE q DO
          { LET destq = e_dest!q
            IF destq=destp DO count := count+1
//            writef(" %n%c", e_pos!q, n_letter!destq+'A')
            q := e_next!q
          }
//          writef("  count=%n*n", count)
          IF count > bestcount DO
            bestnode, bestcount := node, count
          IF count=bestcount & n_len!node > n_len!bestnode DO
            bestnode, bestlen := node, n_len!node
//          writef("bestnode %c bestsize=%n bestlen=%n bestcount=%n*n",
//                  n_letter!bestnode+'A', bestsize, bestlen, bestcount)
          p := e_next!p
        }
//        abort(2345)
      }
    }
//writef("Considering node %c bestnode %c bestsize %n bestlen %n bestcount %n*n",
//        let+'A', n_letter!bestnode+'A', bestsize, bestlen, bestcount) 
  }
//abort(1234)

  RESULTIS bestnode
}


AND compilecomponent() BE
{ // Generate edge instructions for all unused edges from visited
  // nodes attempting to choose then in an efficient order.

again:
  // When we generate an edge instruction to an unvisited edge, we
  // return to the start compilecomponent.
 
  // Search for edges from a visited node to another visited node.
  FOR pos = 1 TO len UNLESS edgeused!pos DO
  { LET src, dest = nodetab!(inlet!pos), nodetab!(outlet!pos)
    //writef("Considering edge %c%n%c*n",
    //        n_letter!src+'A', pos, n_letter!dest+'A')
    // Check that neither src or dest have been visited
    UNLESS n_visited!src & n_visited!dest LOOP
    gen4(c_edge, n_letter!src, pos, n_letter!dest)
    edgeused!pos := TRUE
    edgeusedcount := edgeusedcount+1
  }

  // Now search for unused edges from visited nodes to unvisited nodes
  // that have at least one onther edge to a visited node.
  FOR pos = 1 TO len UNLESS edgeused!pos DO
  { LET src, dest = nodetab!(inlet!pos), nodetab!(outlet!pos)
    LET count = 0 // count of edges from dest to visited nodes
    //writef("Considering edge %c%n%c*n",
    //        n_letter!src+'A', pos, n_letter!dest+'A')

    // Ignore the edge if both src and dest have been visited
    IF n_visited!src & n_visited!dest LOOP

    // Ignore the edge if neither src and dest have been visited
    UNLESS n_visited!src | n_visited!dest LOOP

    // Just one of src and dest have been visited.
    // Swap them if necessary to make src the one that has been visited

    UNLESS n_visited!src DO
    { LET t = src
      src := dest
      dest := t
    }

    // The src has been visited and dest has not.

    // Check whether the destination has any edges to visited nodes
    { LET p = n_list!dest
      WHILE p DO
      { IF n_visited!(e_dest!p) DO count := count+1
        p := e_next!p
      }
      IF count>1 DO
      { // There is an edge other that the one at position pos
        // whose destination has been visited. So use the current edge.
        gen4(c_edge, n_letter!src, pos, n_letter!dest)
        edgeused!pos := TRUE
        edgeusedcount := edgeusedcount+1
        n_visited!dest := TRUE
        GOTO again
      }
    }
  }
  
  // We now look for an unused edge from a visited node to an
  // unvisited node with the most edges.

  { LET bestsrc, bestpos, bestdest, bestlen = 0, 0, 0, 0

    FOR pos = 1 TO len UNLESS edgeused!pos DO
    { LET src, dest = nodetab!(inlet!pos), nodetab!(outlet!pos)

      //writef("Considering edge %c%n%c*n",
      //        n_letter!src+'A', pos, n_letter!dest+'A')


      // Ignore the edge if both src and dest have been visited
      IF n_visited!src & n_visited!dest LOOP

      // Ignore the edge if neither src and dest have been visited
      UNLESS n_visited!src | n_visited!dest LOOP

      // Just one of src and dest have been visited.
      // Swap them if necessary to make src the one that has been visited

      UNLESS n_visited!src DO
      { LET t = src
        src := dest
        dest := t
      }

      // The src has been visited and dest has not.

      IF bestsrc=0 DO
        bestsrc, bestpos, bestdest, bestlen := src, pos, dest, n_len!dest

      IF n_len!dest>bestlen DO
        bestsrc, bestpos, bestdest, bestlen := src, pos, dest, n_len!dest
    }      

    // If there are no unused edges left in this component return.
    UNLESS bestsrc RETURN

    gen4(c_edge, n_letter!bestsrc, bestpos, n_letter!bestdest)
    edgeused!bestpos := TRUE
    edgeusedcount := edgeusedcount+1
    n_visited!bestdest := TRUE
    GOTO again
  }
}

AND gen1(a) BE
{ codev!codep := a
  codep := codep+1
}

AND gen2(a,b) BE
{ gen1(a)
  gen1(b)
  //writef("*nguess %c*n", b+'A')
}

AND gen4(a,b,c,d) BE
{ gen1(a)
  gen1(b)
  gen1(c)
  gen1(d)
  //writef("edge   %c %n %c*n", b+'A', c, d+'A')
}

AND prcode() BE
{ LET p = 0

  writef("*nCode:*n")

  WHILE p<codep DO
  { LET op = codev+p

    SWITCHON op!0 INTO
    { DEFAULT:
        writef("Bad code*n")
        RETURN

      CASE c_guess:
        writef("guess %c*n", op!1+'A')
        p := p+2
        LOOP

      CASE c_edge:
        writef("edge %c %i2 %c*n", op!1+'A', op!2, op!3+'A')
        p := p+4
        LOOP

      CASE c_fin:
        writef("fin*n")
        RETURN
    }
  }
}

AND testsetting(letl, letm, letr) BE
{ LET p = 0
  LET rootlet = codev!1
  initposL, initposM, initposR := letl, letm, letr

  FOR tp = 1 TO 4 DO
  { turnpattern := tp


    FOR n = 0 TO 25 DO
    { nr := n

      posL, posM, posR :=   initposL, initposM, initposR

      notchposR := (initposR+nr) MOD 26

      SWITCHON turnpattern INTO
      { DEFAULT: writef("System error in testsetting*n")
                 abort(999)
                 RETURN

        CASE 1:  // Left hand rotor does not move, eg
                 // nr=0    nr=1   nr=2   nr=3 ...   nr=24  nr=25
                 //    ZA     ZB     ZC     ZD         ZY     ZZ
                 //   AAA    AAA    AAA    AAA ...    AAA    AAA
                 // 1 ABB  1 AAB  1 AAB  1 AAB ...  1 AAB  1 AAB
                 // 2 ABC  2 ABC  2 AAC  2 AAC ...  2 AAC  2 AAC
                 // 3 ABD  3 ABD  3 ABD  3 AAD ...  3 AAD  3 AAD
                 // 4 ABD  4 ABD  4 ABD  4 ABE ...  4 AAD  4 AAD
                 //   ...    ...    ...        ...    ...
                 //24 ABY 24 ABY 24 ABY 24 ABY ... 24 AAY 24 AAY
                 //25 ABZ 25 ABZ 25 ABZ 25 ABZ ... 25 ABZ 25 AAZ
                 //26 ABA 26 ABA 26 ABA 26 ABA ... 26 ABA 26 ABA
                 //27 ACB 27 ABB 27 ABB 27 ABB ... 27 ABB 27 ABB
                 //28 ACC 28 ACC 28 ABC 28 ABC ... 28 ABC 28 ABC
                 //29 ACD 29 ACD 29 ACD 28 ABD ... 29 ABD 29 ABD
                 // If nr>len same as nr-1 
                 // If nr=len same as nr=0 starting ABA 
                 IF nr>=len BREAK
                 notchposM := (initposM+25) MOD 26
                 ENDCASE

        CASE 2:  // Left and middle rotor step at start
                 // nr=0    nr=1   nr=2   nr=3 ...  nr=24  nr=25
                 //    AA     AB     AC     AD        AY     AZ
                 //   AAA    AAA    AAA    AAA ...   AAA    AAA
                 // 1 BBB  1 BAB  1 BAB  1 BAB ... 1 BAB  1 BAB
                 // 2 BBC  2 BBC  2 BAC  2 BAC ... 2 BAC  2 BAC
                 // 3 BBD  3 BBD  3 BBD  3 BAD ... 3 BAD  3 BAD
                 // 4 BBD  4 BBD  4 BBD  4 BBE ... 4 BAD  4 BAD
                 //   ...    ...    ...    ... ...    ...
                 //24 BBY 24 BBY 24 BBY 24 BBY ...24 BAY 24 BAY
                 //25 BBZ 25 BBZ 25 BBZ 25 BBZ ...25 BBZ 25 BAZ
                 //26 BCA 26 BBA 26 BBA 26 BBA ...26 BBA 26 BBA
                 //27 BCB 27 BBB 27 BBB 27 BBB ...27 BBB 27 BBB
                 //28 BCC 28 BCC 28 BBC 28 BBC ...28 BBC 28 BBC
                 //29 BCD 29 BCD 29 BCD 28 BBD ...29 BBD 29 BBD
                 // Same as turnpattern=1 but starting at ZAA
                 BREAK  // Leave FOR n = 0 TO ... LOOP
                 notchposM := initposM
                 ENDCASE

        CASE 3:  // Double step at nr
                 // nr=0    nr=1   nr=2   nr=3 ...  nr=24  nr=25
                 //    BA     BB     BC     BD        BY     BZ
                 //   AAA    AAA    AAA    AAA ...   AAA    AAA
                 // 1 ABB  1 AAB  1 AAB  1 AAB ... 1 AAB  1 AAB
                 // 2 BBC  2 ABC  2 AAC  2 AAC ... 2 AAC  2 AAC
                 // 3 BBD  3 BCD  3 ABD  3 AAD ... 3 AAD  3 AAD
                 // 4 BBD  4 BCD  4 BCD  4 ABE ... 4 AAD  4 AAD
                 //   ...    ...    ...    ... ...    ...
                 //24 BBY 24 BCY 24 BCY 24 BCY ...24 AAY 24 AAY
                 //25 BBZ 25 BCZ 25 BCZ 25 BCZ ...25 ABZ 25 AAZ
                 //26 BCA 26 BCA 26 BCA 26 BCA ...26 BCA 26 ABA
                 //27 BCB 27 BCB 27 BCB 27 BCB ...27 BCB 27 BCB
                 //28 BCC 28 BDC 28 BCC 28 BCC ...28 BCC 28 BCC
                 //29 BCD 29 BDD 29 BDD 28 BCD ...29 BCD 29 BCD
                 // If nr>=len same as nr-1
                 IF nr>=len BREAK 
                 notchposM := (initposM+1) MOD 26
                 ENDCASE

        CASE 4:  // Double step at nr+26 -- lot in common with 1
                 // nr=0    nr=1   nr=2   nr=3 ...  nr=24  nr=25
                 //    CA     CB     CC     CD        CY     CZ
                 //   AAA    AAA    AAA    AAA ...   AAA    AAA
                 // 1 ABB  1 AAB  1 AAB  1 AAB ... 1 AAB  1 AAB
                 // 2 ABC  2 ABC  2 AAC  2 AAC ... 2 AAC  2 AAC
                 // 3 ABD  3 ABD  3 ABD  3 AAD ... 3 AAD  3 AAD
                 // 4 ABD  4 ABD  4 ABD  4 ABE ... 4 AAD  4 AAD
                 //   ...    ...    ...    ... ...    ...
                 //24 ABY 24 ABY 24 ABY 24 ABY ...24 AAY 24 AAY
                 //25 ABZ 25 ABZ 25 ABZ 25 ABZ ...25 ABZ 25 AAZ
                 //26 ABA 26 ABA 26 ABA 26 ABA ...26 ABA 26 ABA
                 //27 ACB 27 AAB 27 ABB 27 ABB ...27 ABB 27 ABB
                 //28 BDC 28 ACC 28 ABC 28 ABC ...28 ABC 28 ABC
                 //29 BDD 29 BCD 29 ACD 28 ABD ...29 ABD 29 ABD
                 // If nr+27>=len same as turnpattern=1
                 IF nr+27>=len BREAK
                 notchposM := (initposM+2) MOD 26
                 ENDCASE
      }

      IF tracing DO
        writef("turnpattern=%n nr=%n notches=%c%c*n",
                turnpattern, nr, notchposM+'A', notchposR+'A')

      FOR pos = 1 TO len DO
      { step_rotors()
        IF tracing DO
          writef("%2i: %c%c%c  ", pos, posL+'A', posM+'A', posR+'A')
        posmapv!pos := maps+((posL*26+posM)*26+posR)*26
        IF tracing DO
        { FOR let = 0 TO 25 DO wrch((posmapv!pos)!let+'a')
          newline()
        }
      }
      //abort(5555)
      FOR let = 0 TO 25 DO patch!let := -1

      executecode(0)
    }
  }

  IF tracing DO
  { writef("*nAll guesses tried for this rotor setting*n")
    abort(1005)
  }
}

AND executecode(p) BE
{ LET op, a, pos, b = codev!(p+0), codev!(p+1), codev!(p+2), codev!(p+3)

  //writef("executecode: %n %n %n %n*n", op, a, b, pos)
//abort(2222)
  SWITCHON op INTO
  { DEFAULT:
           writef("System error: Bad code %n %n %n %n*n", op, a, b, pos)
           abort(999)
           RETURN

    CASE c_fin:
           solutioncount := solutioncount+1
           writef("*nSolution found*n")
           writef("*nreflector %s rotors %s %s %s  notches %c%c%c*n",
           reflectorname, rotorLname, rotorMname, rotorRname,
           notchL+'A', notchM+'A', notchR+'A')

           writef("Rotor setting %c %c %c*n",
                   initposL+'A', initposM+'A', initposR+'A')
           writef("nr=%n turnpattern=%n*n", nr, turnpattern)
           // The following call needs more thought
           //writef("Possible initial positions %c %c %c*n",
           //        (-notchL+initposL+26) MOD 26 + 'A',
           //        (-notchM+initposM+26) MOD 26 + 'A',
           //        (notchR-nr+26) MOD 26 + 'A')
           prpatch()
           //abort(1004)
           RETURN

    CASE c_guess:  // guess letter
         { LET ia = patch!a
           IF ia>=0 DO
           { // The outer letter a has already had an inner
             // letter assigned, so there is nothing to do.
             IF tracing DO
             { writef("*nGuess %c -- Plugboard %c already set to %c*n",
                      a+'A', ia+'a')
               abort(1000)
             }
             executecode(p+2)
             RETURN
           }
           FOR let = 0 TO 25 IF patch!let<0 DO
           { IF tracing DO
             { writef("*nGuess %c -- trying inner=%c*n", a+'A', let+'a')
               abort(1000)
               writef("  Guess setting pluboard %c to %c*n", a+'A', let+'a')
               UNLESS a=let DO
                 writef("  Guess setting pluboard %c to %c*n", let+'A', a+'a')
             }
             patch!a := let
             patch!let := a
             executecode(p+2)
             IF tracing DO
             { writef("  Guess unsetting plugboars %c*n", a+'A')
               UNLESS a=let DO
                 writef("  Guess unsetting plugboard %c*n", let+'A')
             }
             patch!a := -1
             patch!let := -1
           }
           RETURN
         }

    CASE c_edge:
         { LET ia = patch!a
           LET ib = patch!b
           LET nib = (posmapv!pos)!ia
           IF tracing DO
           { writef("edge %c %n %c*n", a+'A', pos, b+'A')
             writef("  %c%n%c*n", ia+'a', pos, nib+'a')
           }
//abort(1111)  
           IF patch!b = nib DO
           { IF tracing DO
               writef("  Plugboard %c is already %c, which is OK*n",
                      b+'A', nib+'a')
             executecode(p+4)
             RETURN
           }

           IF patch!b<0 & patch!nib<0 DO
           { IF tracing DO
             { writef("  Plugboard %c and %c are both unset, so*n",
                      b+'A', nib+'A')
               writef("  Edge setting plugboard %c to %c*n",
                      b+'A', nib+'a')
               UNLESS b=nib DO
                 writef("  Edge setting plugboard %c to %c*n",
                        nib+'A', b+'a')
             }
             patch!b := nib
             patch!nib := b
             executecode(p+4)
             IF tracing DO
             { writef("  Edge unsetting plugboard %c*n", b+'A')
               UNLESS b=nib DO
                 writef("  Edge unsetting plugboard %c*n", nib+'A')
             }
             patch!b := -1
             patch!nib := -1
             RETURN
           }
           IF tracing DO
           { TEST patch!b>=0
             THEN { writef("  Plugboard %c is already set to %c, ",
                           b+'A', patch!b+'a')
                    writef("so cannot be set %c to %c -- Backtrack*n",
                           b+'A', nib+'a')
                  }
             ELSE { writef("  Plugboard %c is already set to %c, ",
                           nib+'A', patch!nib+'a')
                    writef("so cannot set %c to %c -- Backtrack*n",
                           nib+'A', b+'a')
                  }
           }
           // Patch not OK so backtrack
           RETURN
         }
  }
}

AND prpatch() BE
{ writef("Plugboard setting:  ")
  FOR let = 0 TO 25 DO
  { LET c = patch!let
    IF c>=let DO writef(" %c%c", let+'A', c+'A')
  }
  newline()
}
