/* This is a naive attempt to determine the settings of an
enigma machine given a crib (message and ite encryption.
It attempt to do it by trying both reflectors, selecting
three rotors from five and trying to find how the ten cables
of the plug board are wired. It does this by trial and error.

It does not use the cunning techniques discovered by Alan Turing.

Implemented by Martin Richards (c) September 2013

*/

GET "libhdr"

GLOBAL
{ spacev:ug; spacep; spacet

  inchar    // String of input characters
  outchar   // String of output characters
  len       // Number of characters in the input string

  tracing   // =TRUE causes signal tracing output

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
  LET spaceupb = 2500

  finP, finL := level(), fin

  UNLESS rdargs("-t/s", argv, 50) DO
  { writef("Bad arguments for enigma-m3*n")
    RESULTIS 0
  }

writef("*nEnigma message decoder*n")

  tracing := TRUE
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

  FOR i = 0 TO 25 DO plugboard!i := i

//writef("Set the the example message and its encryption*n")

  {  LET s1 = "QBLTWLDAHHYEOEFPTWYBLENDPMKOXLDFAMUDWIJDXRJZ"
     LET s2 = "DERFUEHRERISTTODXDERKAMPFGEHTWEITERXDOENITZX"

     s1 := "RPVZLYNCQORVUSYUZUBCKNIBKDWZRPFZVLA"  // Challenge
     s1 := "RPV"  // Challenge
     s2 := "DER"
     len := s1%0
     FOR i = 1 TO len DO inchar!i, outchar!i := s1%i, s2%i
  }

  maps      := newvec(26*len)
  mapM      := newvec(25)
  mapL      := newvec(25)

  // The following vectors hold the rotor letter positions
  // for each position (1 to len) in the message string.
  posLv     := newvec(len)
  posMv     := newvec(len)
  posRv     := newvec(len)

  writef("*nMemory used = %n*n", spacet-spacep)

  tryreflector(reflectorB, "B")
  //tryreflector(reflectorC, "C")

  writef("*nNo solution found*n")

fin:
  IF spacev DO freevec(spacev)
  RESULTIS 0
}

AND tryreflector(reflstr, name) BE
{ setvec(reflstr, reflector)
  reflectorname := name
  tryrotorL(#b11111)
}

AND tryrotorL(poss) BE
{ //FOR i = 0 TO 4 DO
  FOR i = 2 TO 2 DO // Challenge
  { LET bit = 1<<i
    UNLESS (poss & bit)=0 DO
    { rotorLname := setrotor(i+1, rotorFL, rotorBL)
      notchL := result2-'A'
      tryrotorM(poss - bit)
    }
  }
}

AND tryrotorM(poss) BE
{ //FOR i = 0 TO 4 DO
  FOR i = 0 TO 0 DO // Challenge
  { LET bit = 1<<i
    UNLESS (poss & bit)=0 DO
    { rotorMname := setrotor(i+1, rotorFM, rotorBM)
      notchM := result2-'A'
      tryrotorR(poss - bit)
    }
  }
}

AND tryrotorR(poss) BE
{ //FOR i = 0 TO 4 DO
  FOR i = 1 TO 1 DO // Challenge
  { LET bit = 1<<i
    UNLESS (poss & bit)=0 DO
    { rotorRname := setrotor(i+1, rotorFR, rotorBR)
      notchR := result2-'A'
      //writef("reflector %s rotors %s %s %s  notches %c%c%c*n",
      //        reflectorname, rotorLname, rotorMname, rotorRname,
      //        notchL+'A', notchM+'A', notchR+'A')
      
      // deal with ring setting later
      ringL := 06-1; ringM := 22-1; ringR := 14-1
      ringL := 'S'-'A'; ringM := 'B'-'A'; ringR := 'E'-'A' // Challenge

      //posL, posM, posR := 0, 0, 0
      posL, posM, posR := 'X'-'A', 'W'-'A', 'B'-'A'
      posL, posM, posR := 'A'-'A', 'A'-'A', 'A'-'A' // Challenge

      { 
      writef("reflector %s rotors %s %s %s  notches %c%c%c rings %n %n %n pos %c%c%c*n",
              reflectorname, rotorLname, rotorMname, rotorRname,
              notchL+'A', notchM+'A', notchR+'A',
              ringL, ringM, ringR,
              posL+'A', posM+'A', posR+'A')
abort(1000)
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

IF TRUE DO
{ // Challenge
  FOR i = 0 TO 25 DO plugboard!i := -1

  // Try setting the correct plug board connections
  plugboard!('A'-'A'), plugboard!('F'-'A') := 'F'-'A', 'A'-'A'; pls := pls+1
  plugboard!('E'-'A'), plugboard!('R'-'A') := 'R'-'A', 'E'-'A'; pls := pls+1
  plugboard!('L'-'A'), plugboard!('D'-'A') := 'D'-'A', 'L'-'A'; pls := pls+1
}

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

AND step_rotors(pos) BE
{ LET advM = posR=notchR | posM=notchM
  LET advL = posM=notchM

  IF advL DO
  { posL := (posL+1) MOD 26 // Step the left rotor
    setmapL(pos)   // Update mapL
  }
  IF advM DO
  { posM := (posM+1) MOD 26 // Step the middle rotor
    setmapM(pos)   // Update mapM
  }
  posR := (posR+1) MOD 26   // Step the right hand rotor
}

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

AND rotorfn(x, map, pos, ring) = VALOF
{ LET a = (x+pos-ring+26) MOD 26
  LET b = map!a
  LET c = (b-pos+ring+26) MOD 26
  RESULTIS c
}

