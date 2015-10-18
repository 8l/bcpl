/*
  3 rotor German Enigma simulation
  Translated from a C program (written by Fauzan Mirza)
  into BCPL by Martin Richards

  It encodes: ABCDEFGHIJKLMNOPQRSTUVWXYZ
  as:         VRRUK CELJM CXREB GYBUA BXYUB W

*/

GET "libhdr"

GLOBAL
{ rotor:ug
  ref
  notch
  flag
  order
  rings
  pos
  plug
}

LET start() = VALOF
{ LET n = 0

// Rotor wirings 

  rotor := TABLE 0,0,0,0,0,0

// Input     "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  rotor!1 := "EKMFLGDQVZNTOWYHXUSPAIBRCJ"
  rotor!2 := "AJDKSIRUXBLHWTMCQGZNPYFVOE"
  rotor!3 := "BDFHJLCPRTXVZNYEIWGAKMUSQO"
  rotor!4 := "ESOVPZJAYQUIRHXLNFTGKDCMWB"
  rotor!5 := "VZBRGITYUPSDNHLXAWMJQOFECK"

  ref     := "YRUHQSLDPXNGOKMIEBFZCWVJAT"

  notch   := "QEVJZ"
  flag    := 0

// Encryption parameters follow

  order   := TABLE ?, 3, 1, 2 
  rings   := "WXT"
  pos     := "AWE"
  plug    := "AMTE"


  { LET ch = capitalch(rdch())
    IF ch=endstreamch | ch='.' BREAK

    UNLESS 'A'<=ch<='Z' LOOP
//writef("pos = %s*n", pos)
//writef("ch = %c*n", ch)
// Step up first rotor 
    pos%1 := pos%1 + 1
    IF pos%1>'Z' DO pos%1 := pos%1 - 26
//writef("pos = %s*n", pos)

// Check if second rotor reached notch last time */
   IF flag DO
   { // Step up both second and third rotors
     pos%2 := pos%2+1
     IF pos%2>'Z' DO pos%2 := pos%2 - 26
     pos%3 := pos%3+1
     IF pos%3>'Z' DO pos%3 := pos%3 - 26
     flag := FALSE
   }

//  Step up second rotor if first rotor reached notch
   IF pos%1=notch%(order!1) DO
   { pos%2 := pos%2 + 1
     IF pos%2>'Z' DO pos%2 := pos%2 - 26;
// Set flag if second rotor reached notch
     IF pos%2=notch%(order!2) DO flag := TRUE
   }

//  Swap pairs of letters on the plugboard
    FOR i = 1 TO plug%0 BY 2 DO
    { TEST ch=plug%i
      THEN ch := plug%(i+1)
      ELSE IF ch=plug%(i+1) DO ch := plug%i
    }

//writef("After plug board  ch = %c*n", ch)
//writef("pos = %s*n", pos)

//  Rotors (forward)
    FOR i = 1 TO 3 DO
    { ch := ch + pos%i-'A'
      IF ch>'Z' DO ch := ch - 26
//writef("rotor %n ch = %c*n", i, ch)
      ch := ch - (rings%i-'A')
      IF ch<'A' DO ch := ch + 26
//writef("rotor %n ch = %c after ring shift*n", i, ch)

      ch := (rotor!(order!i))%(ch-'A'+1)
//writef("rotor %n ch = %c after rotor*n", i, ch)

      ch := ch + rings%i-'A'
      IF ch>'Z' DO ch := ch - 26
//writef("rotor %n ch = %c after ring unshift*n", i, ch)

      ch := ch - (pos%i-'A')
      IF ch<'A' DO ch := ch + 26
//writef("ch = %c after rotor %n*n", ch, i)
    }
//writef("ch = %c before reflector*n", ch)

//  Reflecting rotor
    ch := ref%(ch-'A'+1)
//writef("ch = %c after reflector*n", ch)

//  Rotors (reverse)
    FOR i = 3 TO 1 BY -1 DO
    { ch := ch + pos%i-'A'
      IF ch>'Z' DO ch := ch - 26

      ch := ch - rings%i+'A'
      IF ch<'A' DO ch := ch + 26

      FOR j = 1 TO 26 DO
        IF (rotor!(order!i))%j=ch DO
        { ch := j+'A'-1
          BREAK
        }

      ch := ch + rings%i-'A'
      IF ch>'Z' DO ch := ch - 26

      ch := ch - pos%i+'A'
      IF ch<'A' DO ch := ch + 26
    }
//writef("ch = %c before plugboard*n", ch)
	
//  Plugboard
    FOR i = 1 TO plug%0 BY 2 DO
    { TEST ch=plug%i
      THEN ch := plug%(i+1)
      ELSE IF ch=plug%(i+1) DO ch := plug%i
    }
//writef("ch = %c after plugboard*n", ch)

    n := n+1
    wrch(ch)
    IF n REM 5 = 0 TEST n REM 55 = 0
                   THEN newline()
                   ELSE wrch(' ')
  } REPEAT
}

