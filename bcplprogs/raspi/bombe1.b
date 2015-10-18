/*
############ THIS PROGRAM IS UNDER DEVELOPMENT ############

This program attempts to find the enigma machine setting
given a long enough crib consisting of plain text and its
encryption. It uses a method based on that used by the bombe
machine developed by Alan Turing and others in Bletchley Park
in 1940.

Implemented by Martin Richards (c) October 2013

*/

GET "libhdr"

GLOBAL
{ spacev:ug; spacep; spacet

  inchar    // Plain text
  outchar   // Corresponding encrypted text
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

  visited   // Nodes already visited
  edges0    // Edges  0 to 31 already used
  edges1    // Edges 32 to 63 already used

  posmapv   // For mapping at position pos
  patch     // The pluboard mapping
}

MANIFEST {
  // Fields of a node
  n_parent=0 // Pointer to parent node, or zero if root
  n_letter   // The letter (0..25) of this node
  n_succs    // Number of successor nodes
  n_list     // List of successors
  n_edges    // If this node is a root, this field holds the number
             // of edges in this component
  n_upb = n_edges

  // Fields of a successor list item
  s_next=0   // Pointer to next item or zero
  s_dest     // Destination node for this edge
  s_pos      // The position of the edge in the crib (1.. upwards)
  s_upb = s_pos

  // instruction op codes
  c_new=1
  c_tst
  c_fin
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
  LET spaceupb = 5000

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
  inchar    := newvec(255)
  outchar   := newvec(255)

  nodetab   := newvec(25)
  codev     := newvec(64*4-1)
  codep := 0

  posmapv := newvec(64)
  // Allocate mapping vectors for each position
  FOR pos = 1 TO 64 DO
    posmapv!pos := newvec(25)

  patch := newvec(25)

  FOR i = 0 TO 25 DO plugboard!i := i

//writef("Set the the example message and its encryption*n")

  {  LET s1 = "DERFUEHRERISTTODXDERKAMPFGEHTWEITERXDOENITZX" // Plain
     LET s2 = "QBLTWLDAHHYEOEFPTWYBLENDPMKOXLDFAMUDWIJDXRJZ" // Encrypted
     len := s1%0
     FOR i = 1 TO len DO inchar!i, outchar!i := s1%i, s2%i
  }

len := 26

  maps      := newvec(26*len)
  mapM      := newvec(25)
  mapL      := newvec(25)

  // The following vectors hold the rotor letter positions
  // for each position (1 to len) in the message string.
  posLv     := newvec(len)
  posMv     := newvec(len)
  posRv     := newvec(len)

  writef("*nMemory used = %n*n", spacet-spacep)

  // Compile the crib
  trans(len, inchar, outchar)
  writef("*nMemory used after trans = %n*n", spacet-spacep)

  // Output the graph
  prgraph()

  // Generate code
  gencode()

  // Output the corresponding test code
  prcode()


  setvec(reflectorB, reflector)
  reflectorname := "B"
  rotorLname := setrotor(1, rotorFL, rotorBL)
  ringL, notchL := 'F'-'A', result2-'A'
  rotorMname := setrotor(2, rotorFM, rotorBM)
  ringM, notchM := 'V'-'A', result2-'A'
  rotorRname := setrotor(5, rotorFR, rotorBR)
  ringR, notchR := 'N'-'A', result2-'A'

  ringL, ringM, ringR := 0, 0, 0

  writef("*nreflector %s rotors %s %s %s  notches %c%c%c*n",
  reflectorname, rotorLname, rotorMname, rotorRname,
  notchL+'A', notchM+'A', notchR+'A')

  solutioncount := 0

  //FOR letl = 'X'-'A' TO 25 FOR letm = 'W'-'A' TO 25 FOR letr = 'B'-'A' TO 25 DO
  FOR letl = 'A'-'A' TO 25 DO
  { writef("Trying setting posL=%c*n", letl+'A')
    FOR letm = 'A'-'A' TO 25 FOR letr = 'A'-'A' TO 25 DO
    {
      //writef("Trying setting %c %c %c*n", letl+'A', letm+'A', letr+'A')
      testsetting(letl, letm, letr)
  IF tracing DO abort(1001)
    }
  }

  //tryreflector(reflectorB, "B")
  //tryreflector(reflectorC, "C")

  writef("*n%n solution%ps found*n", solutioncount, solutioncount)

fin:
  IF spacev DO freevec(spacev)
  RESULTIS 0
}
/*
AND tryreflector(reflstr, name) BE
{ setvec(reflstr, reflector)
  reflectorname := name
  tryrotorL(#b11111)
}

AND tryrotorL(poss) BE
{ FOR i = 0 TO 4 DO
  //FOR i = 0 TO 0 DO
  { LET bit = 1<<i
    UNLESS (poss & bit)=0 DO
    { rotorLname := setrotor(i+1, rotorFL, rotorBL)
      notchL := result2-'A'
      tryrotorM(poss - bit)
    }
  }
}

AND tryrotorM(poss) BE
{ FOR i = 0 TO 4 DO
  //FOR i = 1 TO 1 DO
  { LET bit = 1<<i
    UNLESS (poss & bit)=0 DO
    { rotorMname := setrotor(i+1, rotorFM, rotorBM)
      notchM := result2-'A'
      tryrotorR(poss - bit)
    }
  }
}

AND tryrotorR(poss) BE
{ FOR i = 0 TO 4 DO
  //FOR i = 4 TO 4 DO
  { LET bit = 1<<i
    UNLESS (poss & bit)=0 DO
    { rotorRname := setrotor(i+1, rotorFR, rotorBR)
      notchR := result2-'A'
      //writef("reflector %s rotors %s %s %s  notches %c%c%c*n",
      //        reflectorname, rotorLname, rotorMname, rotorRname,
      //        notchL+'A', notchM+'A', notchR+'A')
      
      // deal with ring setting later
      ringL := 06-1; ringM := 22-1; ringR := 14-1

      //posL, posM, posR := 0, 0, 0
      posL, posM, posR := 'X'-'A', 'W'-'A', 'B'-'A'
      { 
      writef("reflector %s rotors %s %s %s  notches %c%c%c pos %c%c%c*n",
              reflectorname, rotorLname, rotorMname, rotorRname,
              notchL+'A', notchM+'A', notchR+'A',
              posL+'A', posM+'A', posR+'A')
//abort(1000)
        tryplugs() 
        step_rotors()
//        RETURN
      } REPEATUNTIL 0=posL=posM=posR
    }
  }
}

AND tryplugs() BE
{ LET ids, pls = 0, 0

  writef("reflector %s rotors %s %s %s  notches %c%c%c  pos %c%c%c*n",
  reflectorname, rotorLname, rotorMname, rotorRname,
  notchL+'A', notchM+'A', notchR+'A',
  posL+'A', posM+'A', posR+'A')
  // Unset the plug board
  FOR i = 0 TO 25 DO plugboard!i := -1

  // Try setting the correct plug board connections
  plugboard!('A'-'A') := 'A'-'A'; ids :=ids+1
  plugboard!('B'-'A'), plugboard!('G'-'A') := 'G'-'A', 'B'-'A'; pls := pls+1
  plugboard!('C'-'A'), plugboard!('D'-'A') := 'D'-'A', 'C'-'A'; pls := pls+1
  plugboard!('E'-'A'), plugboard!('R'-'A') := 'R'-'A', 'E'-'A'; pls := pls+1
  plugboard!('F'-'A'), plugboard!('V'-'A') := 'V'-'A', 'F'-'A'; pls := pls+1
  plugboard!('H'-'A'), plugboard!('N'-'A') := 'N'-'A', 'H'-'A'; pls := pls+1
  plugboard!('I'-'A'), plugboard!('U'-'A') := 'U'-'A', 'I'-'A'; pls := pls+1
  plugboard!('J'-'A'), plugboard!('K'-'A') := 'K'-'A', 'J'-'A'; pls := pls+1
  plugboard!('L'-'A'), plugboard!('M'-'A') := 'M'-'A', 'L'-'A'; pls := pls+1
  plugboard!('O'-'A'), plugboard!('P'-'A') := 'P'-'A', 'O'-'A'; pls := pls+1
//  plugboard!('Q'-'A') := 'Q'-'A'; ids :=ids+1
//  plugboard!('S'-'A') := 'S'-'A'; ids :=ids+1
//  plugboard!('T'-'A'), plugboard!('Y'-'A') := 'Y'-'A', 'T'-'A'; pls := pls+1
//  plugboard!('W'-'A') := 'W'-'A'; ids :=ids+1
//  plugboard!('X'-'A') := 'X'-'A'; ids :=ids+1
//  plugboard!('Z'-'A') := 'Z'-'A'; ids :=ids+1

  posLv!0, posMv!0, posRv!0 := posL, posM, posR
  setmaps(0) // Initialise mapR, mapL and maps

  tryplugpos(ids, pls, 1, maps) // idents, cables, pos, map
}

AND tryplugpos(idents, cables, pos, map) BE
{ // map is the map from iFR -> oFB for the current pos
  LET ich, och = inchar!pos-'A', outchar!pos-'A'
  LET iFR, oBR = ?, ?

  //writef("*nidents=%n cables=%2i pos=%2i len=%2i ich=%c och=%c*n",
  //        idents, cables, pos, len, ich+'A', och+'A')
  //prplugboardpairs(map, pos)
  //writef("   AA BG CD DC ER FV GB HN IU JK KJ LM ML NH OP PO QQ RE SS TY UI VF WW XX YT ZZ*n")

//abort(1000)

  IF pos>len DO
  { // Solution found
    writef("*nSolution found*n")
    longjump(finP, finL)
  }

  iFR := plugboard!ich

  IF iFR<0 DO
  { // We must set a plugboard entry for ich
  //  writef("ich=%c  iFR=***n", ich+'A')
    IF idents<6 DO
    { // First try the identity mappping
      //writef("*n1 pos=%n Try setting plug %c=%c*n", pos, ich+'A', ich+'A')
      //prplugboardpairs(map, pos)
      plugboard!ich := ich
      //prplugboardpairs(map, pos)
  //writef("   AA BG CD DC ER FV GB HN IU JK KJ LM ML NH OP PO QQ RE SS TY UI VF WW XX YT ZZ*n")

      // Re-try this position with the modified plugboard
      //writef("Re-try with new plugboard setting pos=%n*n", pos)
      tryplugpos(idents+1, cables, pos, map)

      // restore previous setting of the plugboard
      //writef("*n2 pos=%n Unset plug %c=%c*n", pos, ich+'A', ich+'A')
      //prplugboardpairs(map, pos)
      plugboard!ich := -1
      //prplugboardpairs(map, pos)
    }

    // Now try all other possible settings nch<->ich for plugboard!ich

    IF cables<10 FOR nch = 0 TO 25 IF nch~=ich &
                                      plugboard!nch<0 DO
    { // A cable must be available
      // nch ~= ich
      // plugboard!nch < 0

      //writef("*n3 pos=%n Set plug %c<->%c*n", pos, ich+'A', nch+'A')
      //prplugboardpairs(map, pos)
      plugboard!ich, plugboard!nch := nch, ich
      //prplugboardpairs(map, pos)
  //writef("   AA BG CD DC ER FV GB HN IU JK KJ LM ML NH OP PO QQ RE SS TY UI VF WW XX YT ZZ*n")

      // Re-try this position with modified plugboard
      //writef("Re-try with new plugboard setting pos=%n*n", pos)
      tryplugpos(idents, cables+1, pos, map)

      // Restore previous plugboard
      //writef("*n4 pos=%n Unset plug %c<->%c*n", pos, ich+'A', nch+'A')
      //prplugboardpairs(map, pos)
      plugboard!ich, plugboard!nch := -1, -1
      //prplugboardpairs(map, pos)
    }
    //writef("Backtrack pos=%n*n", pos)
    RETURN // None of these worked, so backtrack
  }

  // plugboards!ich is already set

  oBR := map!iFR

//writef("ich=%c  iFR=%c iBR=%c => ", ich+'A', iFR+'A', oBR+'A')
//writef("%c*n", plugboard!oBR<0 -> '**', plugboard!oBR+'A')

  IF plugboard!oBR>=0 DO
  { // The plugboard entry is set
    // If it is set to the right value advance one position
    IF plugboard!oBR=och DO
    { //writef("Advance pos=%n*n", pos+1)
      tryplugpos(idents, cables, pos+1, map+26)
    }
    //writef("Backtrack pos=%n*n", pos)
    RETURN // Backtrack
  }

  // plugboard!oBR is unset

  // Try setting it to och, if allowed
  IF oBR=och DO
  { IF idents<6 DO
    { //writef("*n5 pos=%n Set %c=%c*n", pos, oBR+'A', oBR+'A')
      //prplugboardpairs(map, pos)
      plugboard!oBR := oBR
      //prplugboardpairs(map, pos)
  //writef("   AA BG CD DC ER FV GB HN IU JK KJ LM ML NH OP PO QQ RE SS TY UI VF WW XX YT ZZ*n")

      tryplugpos(idents+1, cables, pos+1, map+26)

      //writef("*n6 pos=%n Unset %c=%c*n", pos, oBR+'A', oBR+'A')
      //prplugboardpairs(map, pos)
      plugboard!oBR := -1
      //prplugboardpairs(map, pos)
    }
    //writef("Backtrack pos=%n*n", pos)
    RETURN // Backtrack
  }

  // oBR is not equal to och
  IF plugboard!och<0 & cables<10 DO
  { // Try setting a cable between oBR and och

    //writef("*n7 pos=%n Set plug %c<=>%c*n", pos, oBR+'A', och+'A')
    //prplugboardpairs(map, pos)
    plugboard!oBR, plugboard!och := och, oBR
    //prplugboardpairs(map, pos)
//  writef("   AA BG CD DC ER FV GB HN IU JK KJ LM ML NH OP PO QQ RE SS TY UI VF WW XX YT ZZ*n")

    //writef("Advance with new plugboard setting pos=%n*n", pos+1)
    tryplugpos(idents, cables+1, pos+1, map+26)

    //writef("*n8 pos=%n Unset plug %c<=>%c*n", pos, oBR+'A', och+'A')
    //prplugboardpairs(map, pos)

UNLESS plugboard!oBR=och & plugboard!och=oBR DO abort(3333)

    plugboard!oBR, plugboard!och := -1, -1
    //prplugboardpairs(map, pos)

    //writef("Backtrack pos=%n*n", pos)
    RETURN // Backtrack
  }
}
*/
/*
AND prplugboardpairs(mapR, pos) BE
{ posL, posM, posR := posLv!pos, posMv!pos, posRv!pos
  //writef("Pos=%i2 %c%c%c*n", pos, posL+'A', posM+'A', posR+'A')
  //writef("%i2: ", pos)
  //FOR i = 1 TO pos DO wrch(inchar!i)
  //newline()
  //writef("  ")
  //FOR i = 0 TO 25 DO
  //  writef(" %c%c", i+'A', plugboard!i<0 -> '**', plugboard!i+'A')
/*
  writef("*nL:")
  FOR i = 0 TO 25 DO
    writef(" %c%c", i+'A', mapL!i+'A')
  writef("*nl:")
  FOR i = 0 TO 25 DO
    writef(" %c%c", i+'A', enigmaLfn(i)+'A')
  writef("*nM:")
  FOR i = 0 TO 25 DO
    writef(" %c%c", i+'A', mapM!i+'A') 
 writef("*nm:")
  FOR i = 0 TO 25 DO
    writef(" %c%c", i+'A', enigmaMfn(i)+'A')
  writef("*nR:")
  FOR i = 0 TO 25 DO
    writef(" %c%c", i+'A', mapR!i+'A')
 writef("*nr:")
  FOR i = 0 TO 25 DO
    writef(" %c%c", i+'A', enigmaRfn(i)+'A')
*/
//  newline()
}
*/

AND step_rotors(pos) BE
{ // nr is in range 0 to 25
  // turnpattern
  // =1  M steps at pos=nr and nr+26
  // =2  L and M steps at pos=nr
  //     M steps at pos=nr+1
  // =3  M steps at pos=nr
  //     L and M step at pos=nr+26
  // =4  M steps at pos=nr    -- double turn over at nr
  //     L and M step at pos=nr+1
  //     M steps at pos=nr+26
  // =5  M steps at pos=nr    -- double turn over at nr+26
  //     M steps at pos=nr+26
  //     L and M step at pos=nr+26+1
  LET advL, advM = FALSE, FALSE

  SWITCHON turnpattern INTO
  { DEFAULT:
      writef("System error in step_rotors*n")
      abort(999)
      RETURN
    CASE 1: // M steps at pos=nr and nr+26
      IF pos=nr | pos=nr+26 DO advM := TRUE
      ENDCASE
    CASE 2: // L and M step at pos=nr
            // M steps at pos=nr+26
      IF pos=nr DO { advL, advM := TRUE, TRUE; ENDCASE }
      IF pos=nr+26 DO advM := TRUE
      ENDCASE
    CASE 3: // M steps at pos=nr
            // L and M step at pos=nr+26
      IF pos=nr DO { advM := TRUE; ENDCASE }
      IF pos=nr+26 DO advL, advM := TRUE, TRUE
      ENDCASE
    CASE 4: // M steps at pos=nr   -- double turnover at nr
            // L and M step at pos=nr+1
            // M steps at pos=nr+26
      IF pos=nr DO { advM := TRUE; ENDCASE }
      IF pos=nr+1 DO advL, advM := TRUE, TRUE
      IF pos=nr+26 DO advM := TRUE
      ENDCASE
    CASE 5: // M steps at pos=nr   -- double turnover at nr+26
            // M steps at pos=nr+26
            // L and M step at pos=nr+26+1
      IF pos=nr DO { advM := TRUE; ENDCASE }
      IF pos=nr+26 DO advM := TRUE
      IF pos=nr+26+1 DO advL, advM := TRUE, TRUE
      ENDCASE
  }

  IF advL DO
  { posL := (posL+1) MOD 26 // Step the left rotor
   }
  IF advM DO
  { posM := (posM+1) MOD 26 // Step the middle rotor
  }
  posR := (posR+1) MOD 26   // Step the right hand rotor
}

AND rotorfn(x, map, pos, ring) = VALOF
{ LET a = (x+pos-ring+26) MOD 26
  LET b = map!a
  LET c = (b-pos+ring+26) MOD 26
  RESULTIS c
}
/*
AND setmapL(pos) BE
{ FOR i = 0 TO 25 DO
  { LET a   = rotorfn(i, rotorFL, posL, ringL)
    LET b   = reflector!a
    mapL!i := rotorfn(b, rotorBL, posL, ringL)
  }
  posLv!pos := posL
}

AND setmapM(pos) BE
{ FOR i = 0 TO 25 DO
  { LET a   = rotorfn(i, rotorFM, posM, ringM)
    LET b   = mapL!a
    mapM!i := rotorfn(b, rotorBM, posM, ringM)
  }
  posMv!pos := posM
}

AND setmapR(map, pos) BE
{ FOR i = 0 TO 25 DO
  { LET a  = rotorfn(i, rotorFR, posR, ringR)
    LET b  = mapM!a
    map!i := rotorfn(b, rotorBR, posR, ringR)
  }
  posRv!pos := posR
}
*/

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
/*
AND enigmaMfn(x) = VALOF
{ // Rotors right to left
  x := rotorfn(x, rotorFM, posM, ringM)
  x := rotorfn(x, rotorFL, posL, ringL)
  // Reflector
  x := reflector!x
  // Rotors left to right
  x := rotorfn(x, rotorBL, posL, ringL)
  x := rotorfn(x, rotorBM, posM, ringM)

  RESULTIS x
}

AND enigmaLfn(x) = VALOF
{ // Rotors right to left
  x := rotorfn(x, rotorFL, posL, ringL)
  // Reflector
  x := reflector!x
  // Rotors left to right
  x := rotorfn(x, rotorBL, posL, ringL)

  RESULTIS x
}

AND setmaps() BE
{ // posL, posM and posR have been initialised
  LET map = maps
  setmapL(0)   // Initialise mapL
  setmapM(0)   // Initialise mapM

  FOR pos = 1 TO len DO
  { step_rotors(pos)
    // Initialise mapR for each rotor position in the message
    setmapR(map, pos)
    posLv!pos := posL
    posMv!pos := posM
    posRv!pos := posR
    prplugboardpairs(map,pos)
    map := map+26
  } 
  // Debugging aid
//  FOR pos = 0 TO len DO
//    writef("pos %i2 %c%c%c*n",
//            pos, posLv!pos+'A', posMv!pos+'A', posRv!pos+'A')
//  abort(2000)
}
*/

AND trans(len, plaintext, encryptedtext) BE
{ // Allocate the nodes
  FOR let = 0 TO 25 DO
  { LET node = newvec(n_upb)
    nodetab!let := node
    n_parent!node := 0
    n_letter!node := let
    n_succs !node := 0
    n_list  !node := 0
    n_edges !node := 0
  }
  newline()
  FOR pos = 1 TO len DO
  { LET a, b = plaintext!pos, encryptedtext!pos
    addedge(a, b, pos)
    addedge(b, a, pos)
  }
}

AND addedge(a, b, pos) BE
{ // Add and edge from letter a to letter b at position pos
  LET na = nodetab!(a-'A')
  LET nb = nodetab!(b-'A')
  LET ra = findroot(na)
  LET rb = findroot(nb)

  UNLESS ra=rb DO
  { // This edge joins two previously unconnected components
    // Make ra the root of the combined components
    n_parent!rb := ra
    n_edges!ra := n_edges!ra + n_edges!rb
  }
  n_list!na := mk3(n_list!na, nb, pos)
  n_succs!na := n_succs!na + 1
  n_edges!ra := n_edges!ra + 1
}

AND findroot(x) = VALOF
{ LET p = n_parent!x
  UNLESS p RESULTIS x
  p := findroot(p)
  n_parent!x := p
  RESULTIS p
}

AND prgraph() BE
{ newline()
  FOR let = 0 TO 25 DO
  { LET node  = nodetab!let
    LET list  = n_list!node
    LET root  = findroot(node)
    LET edges = n_edges!root
    LET succs = n_succs!node

    sawritef("%c: ", let+'A')
    WHILE list DO
    { sawritef(" %2i%c", s_pos!list, n_letter!(s_dest!list)+'A')
      list := s_next!list
    }
    sawritef("*n")
  }
}

AND gencode() BE
{ LET bestnode, bestroot, bestedges, bestsuccs = 0, 0, 0, 0
  FOR let = 0 TO 25 DO
  { LET node = nodetab!let
    LET root = findroot(node)
    LET edges = n_edges!root
    LET succs = n_succs!node
    IF edges>bestedges DO
      bestnode, bestroot, bestedges, bestsuccs := node, root, edges, succs
    IF edges=bestedges & succs>bestsuccs DO
      bestnode, bestroot, bestedges, bestsuccs := node, root, edges, succs
  }
  //writef("gencode: bestnode = %c bestedges=%n bestsuccs=%n*n",
  //        n_letter!bestnode+'A', bestedges, bestsuccs)

  visited := 1<<(n_letter!bestnode)  // Nodes already visited
  edges0, edges1 := 0, 0             // Edges used
  explore(bestnode)
  gen1(c_fin)
}

AND explore(node) BE
{ LET s = n_list!node
  LET bestsuccs, bestedge = ?, ?

  //writef("explore: node=%c succs=%n*n", n_letter!node+'A', n_succs!node)

  WHILE s DO
  { LET dest = s_dest!s
    LET pos  = s_pos!s
    s := s_next!s

  //writef("explore: considering for tst %n%c*n", pos, n_letter!dest+'A')

    IF (visited & (1<<n_letter!dest)) ~= 0 DO
    { // We have an edge to an already visited node.
      // Check that this edge has not been used before.
      LET bit = 1 << (pos & 31)
      TEST pos<32
      THEN TEST (edges0 & bit)=0
           THEN edges0 := edges0 + bit
           ELSE LOOP
      ELSE TEST (edges1 & bit)=0
           THEN edges1 := edges1 + bit
           ELSE LOOP

      // The edge has not been used before, so use it
      gen4(c_tst, n_letter!node, n_letter!dest, pos)
    }
  }
  // Choose the best successor edge, ie one that has not been
  // used before and points to an unvisited node with the
  // largest number of successors.
  s := n_list!node
  bestsuccs, bestedge := 0, 0

  WHILE s DO
  { LET edge = s
    LET dest = s_dest!s
    LET pos  = s_pos!s
    LET bit = 1 << (pos & 31)
    LET destletter = n_letter!dest

    //writef("explore: considering for new %n%c*n", pos, destletter+'A')

    s := s_next!s

    // Skip the edge if its destination has already been visited.
    IF (visited & (1 << destletter)) ~= 0 LOOP

    // Skip the edge if it has already been used.
    TEST pos<32
    THEN IF (edges0 & bit)~=0 LOOP
    ELSE IF (edges1 & bit)~=0 LOOP

    // The edge has not been used before and points to an
    // unvisited node.
    IF n_succs!dest>bestsuccs DO
       bestsuccs, bestedge := n_succs!dest, edge
  }

  UNLESS bestedge RETURN

  // Use this edge
  { LET dest = s_dest!bestedge
    LET pos  = s_pos !bestedge
    LET bit = 1 << (pos & 31)
    LET destletter = n_letter!dest

    //writef("bestsuccessor=%c bestsuccs=%n*n",
    //        destletter+'A', bestsuccs)

    gen4(c_new, n_letter!node, destletter, pos)

    visited := visited + (1 << destletter)
    TEST pos<32
    THEN edges0 := edges0 + bit
    ELSE edges1 := edges1 + bit

//abort(1000)
    explore(dest)
  }
} REPEAT

AND gen1(a) BE
{ codev!codep := a
  codep := codep+1
}

AND gen4(a,b,c,d) BE
{ gen1(a)
  gen1(b)
  gen1(c)
  gen1(d)
  //writef("gen: %s %c %c %n*n", (a=c_new->"new", "tst"), b+'A', c+'A', d)
}

AND prcode() BE
{ LET p = 0

  writef("*nCode:*n")

  WHILE p<codep DO
  { LET instr = codev+p
    LET opstring = "tst"

    SWITCHON instr!0 INTO
    { DEFAULT:    writef("Bad code*n")
                  RETURN

      CASE c_new: opstring := "new"
      CASE c_tst: writef("%s %c %c %n*n",
                         opstring, instr!1+'A', instr!2+'A', instr!3)
                  p := p+4
                  LOOP

      CASE c_fin: writef("fin*n")
                  RETURN
    }
  }
}

AND testsetting(letl, letm, letr) BE
{ LET p = 0
  LET rootlet = codev!1
  initposL, initposM, initposR := letl, letm, letr

//  FOR tp = 1 TO 5 DO
  FOR tp = 1 TO 1 DO
  { // tp
    // =1  M steps at pos=nr and nr+26
    // =2  L and M steps at pos=nr
    //     M steps at pos=nr+1
    // =3  M steps at pos=nr
    //     L and M step at pos=nr+26
    // =4  M steps at pos=nr    -- double turn over at nr
    //     L and M step at pos=nr+1
    //     M steps at pos=nr+26
    // =4  M steps at pos=nr    -- double turn over at nr
    //     L and M step at pos=nr+1
    //     M steps at pos=nr+26
    // =5  M steps at pos=nr    -- double turn over at nr+26
    //     M steps at pos=nr+26
    //     L and M step at pos=nr+26+1

    turnpattern := tp

    //IF tracing DO
    //writef("turnpattern=%n*n", turnpattern)

    FOR n = 1 TO 26 DO
    { nr := n
      //IF tracing DO
      //writef("tunrnpattern=%n nr=%n*n", turnpattern, nr)

      posL, posM, posR :=   initposL, initposM, initposR

      FOR pos = 1 TO len DO
      { LET map = posmapv!pos
        step_rotors(pos)
        //writef("%2i: %c%c%c  ", pos, posL+'A', posM+'A', posR+'A')
        FOR let = 0 TO 25 DO
        { map!let := enigmaRfn(let)
          //wrch(map!let+'A')
        }
        //newline()
      }
//abort(1000)

      FOR let = 0 TO 25 DO patch!let := -1

      FOR guesslet = 0 TO 25 DO
      { IF tracing DO writef("guess letter = %c*n", guesslet+'A')

        //writef("Set patch %c to %c*n", rootlet+'A', guesslet+'A')
        //writef("Set patch %c to %c*n", guesslet+'A', rootlet+'A')
        patch!rootlet := guesslet
        patch!guesslet := rootlet
        executecode(0)
        //writef("Unset patch %c*n", rootlet+'A')
        //writef("Unset patch %c*n", guesslet+'A')
        patch!rootlet := -1
        patch!guesslet := -1

IF tracing DO writef("Guess letter %c failed*n*n", guesslet+'A')
       //abort(1002)
      }
    }
  }

  IF tracing DO writef("All guesses tried for this rotor setting*n")
  //IF tracing DO
    //abort(1005)
}

AND executecode(p) BE
{ LET op, a, b, pos = codev!(p+0), codev!(p+1), codev!(p+2), codev!(p+3)
  LET opstring = op=c_new -> "new", "tst"

  SWITCHON op INTO
  { CASE c_fin:
           solutioncount := solutioncount+1
           writef("*nSolution found*n")
           writef("*nreflector %s rotors %s %s %s  notches %c%c%c*n",
           reflectorname, rotorLname, rotorMname, rotorRname,
           notchL+'A', notchM+'A', notchR+'A')

           writef("Rotor setting %c %c %c*n",
                   initposL+'A', initposM+'A', initposR+'A')
           writef("nr=%n turnpattern=%n*n", nr, turnpattern)
           writef("so ringR=%c*n", (nr+notchR+26) MOD 26 + 'A')
           prpatch()
           abort(1004)
           RETURN

    CASE c_new:    
    CASE c_tst:    
         { LET ia = patch!a
           LET ib = patch!b
           LET nib = (posmapv!pos)!ia
           IF tracing DO writef("%s %c %c %n*n", opstring, a+'A', b+'A', pos)
           //writef("%c%n%c*n", ia+'A', pos, nib+'A')
//abort(1000)  
           IF patch!b = nib DO
           { //writef("Patch %c is %c, which is OK*n", b+'A', nib+'A')
             executecode(p+4)
             RETURN
           }

           IF op=c_tst RETURN

           IF patch!b<0 & patch!nib<0 DO
           { //writef("patch %c and %c are both unset, so*n", b+'A', nib+'A')
             //writef("Set patch %c to %c*n", b+'A', nib+'A')
             //writef("Set patch %c to %c*n", nib+'A', b+'A')
             patch!b := nib
             patch!nib := b
             executecode(p+4)
             //writef("Unset patch %c*n", b+'A')
             //writef("Unset patch %c*n", nib+'A')
             patch!b := -1
             patch!nib := -1
             RETURN
           }
               
           // Patch not OK so backtrack
           RETURN
         }
  }
}

AND prpatch() BE
{ FOR let = 0 TO 25 DO
  { LET c = patch!let
    IF c>=let DO writef(" %c%c", let+'A', c+'A')
  }
  newline()
}
