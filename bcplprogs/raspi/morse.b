/*
This will be a morse code decoder one day.

Implemented my Martin Richards (c) July 2013

It uses the SDL library to access keyboard events. Currently the morse
code is tapped in using the space bar. In due course, a morse code key
connected to the Raspberry Pi via the PiFace interface will be used.

Ideally a dot is one unit of time and a dash is 3. The space between
dots and dashes is one unit. Between characters is 3 units and between
words is 7 unit.

The unit of time is based on one third of the observed length of 
dashes. The length of a dot must be greater than 1/25 sec. Initially 1
unit is set to 0.1 sec.

The morse code is as follows:

A  .-
B  -...
C  -.-.
D  -..
E .
F  ..-.
G  --.
H  ....
I  ..
J  .---
K  -.-
L  .-..
M  --
N  -.
O  ---
P  .--.
Q  --.-
R  .-.
S  ...
T  -
U  ..-
V  ...-
W  .--
X  -..-
Y  -.--
Z  --..

0  -----
1  .----
2  ..---
3  ...--
4  ....-
5  .....
6  -....
7  --...
8  ---..
9  ----.

*/

GET "libhdr"
GET "sdl.h"
GET "sdl.b"          // Insert the library source code
.
GET "libhdr"
GET "sdl.h"

GLOBAL {
  done:ug

  keydown
  keydownmsecs       // Time of last keydown
  keyupmsecs         // Time of last keyup
  downlen            // Length of last dot or dash
  nowmsecs
  dotlen             // Current dot length in msecs
  dashlen            // Current dash length in msecs

  unitmsecs          // Estimated unit time in msecs
  debugging

  newsymb            // New symbol detected
                     // 1 = dot, 2=dash, 0=up for >2.5 units
                     // -1 = up for >6 units
  code               // code currently being formed

  ch                 // zero or latest decoded character
  str                // String of decoded characters
  strp               // Length of string of decoded characters
  lineno

  sent0
  sentm1
}


LET start() = VALOF
{ LET t0, t1 = sdlmsecs(), ?
  LET stepmsecs = 2  // ie 1/100 sec
  LET v = VEC 256/bytesperword
  str, strp := v, 0
  str%0, str%1, str%2 := 2, 'A', 'B'

  sent0, sentm1 := TRUE, TRUE

  IF sys(Sys_sdl, sdl_avail) DO writef("*nSDL is available*n")

  initsdl()

  // Create an OpenGL window
  mkscreen("Morse decoder", 800, 500)

  done := FALSE
  keydown := FALSE
  keydownmsecs := 0
  keyupmsecs := 0
  downlen := 0
  nowmsecs := 0
  dotlen := 100
  dashlen := 300
  lineno := 1
 
  UNTIL done DO
  { processevents()

    UNLESS keydown DO
    { LET uptime = sdlmsecs() - keyupmsecs
      UNLESS sent0  IF uptime > 4*dashlen/3 DO
      { newsymb(0)
        sent0 := TRUE
      }
      UNLESS sentm1 IF uptime > 3*dashlen DO
      { newsymb(-1)
        sentm1 := TRUE
      }
    }

    plotscreen()
    updatescreen()
    //sdldelay(stepmsecs)
  }

  writef("*nQuitting*n")
  closesdl()
  RESULTIS 0
}

AND plotscreen() BE
{ LET c_white = maprgb(255, 255, 255)
  LET c_gray  = maprgb(200, 200, 200)
  LET c_dgray = maprgb( 64,  64,  64)
  LET c_cyan  = maprgb( 32, 255, 255)
  LET c_red   = maprgb(255,   0,   0)

  selectsurface(screen, screenxsize, screenysize)
  fillsurf(c_dgray)

  setcolour(c_white)
  plotf(10,  screenysize-15*lineno, str)
  plotf(10, 20, "dotlen=%3i  dashlen=%3i", dotlen, dashlen)
}

AND processevents() BE WHILE getevent() SWITCHON eventtype INTO
{ DEFAULT:
    //writef("Unknown event type = %n*n", eventtype)
    LOOP

  CASE sdle_keydown:
    SWITCHON capitalch(eventa2) INTO
    { DEFAULT:                                     LOOP

      CASE 'Q':  done := TRUE;                     LOOP

      CASE 'D':  debugging := ~debugging;          LOOP

      CASE '*s': keydown := TRUE
                 keydownmsecs := sdlmsecs()
                 LOOP

      CASE '*c':
      CASE '*n': lineno := lineno+1
                 str%0, strp := 0, 0;              LOOP
    }
    LOOP

  CASE sdle_keyup:
    SWITCHON capitalch(eventa2) INTO
    { DEFAULT:                                     LOOP

      CASE '*s': keydown := FALSE
                 keyupmsecs := sdlmsecs()
                 downlen := keyupmsecs - keydownmsecs
                 TEST downlen+downlen > (dotlen+dashlen)
                 THEN { newsymb(2)
                        dashlen := (9*dashlen + downlen)/10
                        IF dashlen<80  DO dashlen := 80
                        IF dashlen>500 DO dashlen := 500
                      }
                 ELSE { newsymb(1)
                        dotlen := (9*dotlen + downlen)/10
                        IF dotlen<30  DO dotlen := 30
                        IF dotlen>200 DO dotlen := 200
                      }

                 sent0, sentm1 := FALSE, FALSE
                 LOOP
    }
    LOOP

  CASE sdle_quit:             // 12
    done := TRUE
    writef("QUIT*n");
    LOOP
}

AND newsymb(symb) BE SWITCHON symb INTO
{ DEFAULT: RETURN

  CASE 1:
  CASE 2: code := 10*code + symb
          RETURN

  CASE 0: // End of character
          ch := decode(code)
          code := 0
          strp := strp+1
          str%strp := ch
          str%0 := strp
          RETURN

  CASE -1: ch := '*s' // End of word
           strp := strp+1
           str%strp := ch
           str%0 := strp
           RETURN
}

AND decode(pattern) = VALOF SWITCHON pattern INTO
{ DEFAULT: RESULTIS '?'

  CASE 12:    RESULTIS 'A'
  CASE 2111:  RESULTIS 'B'
  CASE 2121:  RESULTIS 'C'
  CASE 211:   RESULTIS 'D'
  CASE 1:     RESULTIS 'E'
  CASE 1121:  RESULTIS 'F'
  CASE 221:   RESULTIS 'G'
  CASE 1111:  RESULTIS 'H'
  CASE 11:    RESULTIS 'I'
  CASE 1222:  RESULTIS 'J'
  CASE 212:   RESULTIS 'K'
  CASE 1211:  RESULTIS 'L'
  CASE 22:    RESULTIS 'M'
  CASE 21:    RESULTIS 'N'
  CASE 222:   RESULTIS 'O'
  CASE 1221:  RESULTIS 'P'
  CASE 2212:  RESULTIS 'Q'
  CASE 121:   RESULTIS 'R'
  CASE 111:   RESULTIS 'S'
  CASE 2:     RESULTIS 'T'
  CASE 112:   RESULTIS 'U'
  CASE 1112:  RESULTIS 'V'
  CASE 122:   RESULTIS 'W'
  CASE 2112:  RESULTIS 'X'
  CASE 2122:  RESULTIS 'Y'
  CASE 2211:  RESULTIS 'Z'

  CASE 22222: RESULTIS '0'
  CASE 12222: RESULTIS '1'
  CASE 11222: RESULTIS '2'
  CASE 11122: RESULTIS '3'
  CASE 11112: RESULTIS '4'
  CASE 11111: RESULTIS '5'
  CASE 21111: RESULTIS '6'
  CASE 22111: RESULTIS '7'
  CASE 22211: RESULTIS '8'
  CASE 22221: RESULTIS '9'
}




