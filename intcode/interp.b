/*
This program was an ASCII INTCODE assembler and interpreter
for a 16 bit EBCDIC machine. The original version was tested
in 1982 on the IBM 370(a 32 bit EBCDIC machine).

This version is a modification of the program to run under 32-bit
Cintcode BCPL. It is still under development.

Implemented by Martin Richards (c) September 2012

To compile and run a BCPL program, type eg

bcplint com/hello.b to hello.int
type hello.int
bcplint sysb/blib.b to blib.int
bcplint sysb/dlib.b to dlib.int
interp blib.int dlib.int hello.int

The above sequence is nowhere near working yet, given time who knows.

30/09/12
Initial modification of the original interp.b. At least it compiles.

*/
 
GET "libhdr"
 
GLOBAL {
stdout:ug
stdin
tracing

source
tofile
tostream
progsize

etoa       // EBCDIC -> ASCII  table
atoe       // ASCII  -> EBCDIC table
progvec

g
p
ch
cyclecount
labv
cp
a
b
c
d
w
}
 
MANIFEST {
fshift=13
ibit=#10000; pbit=#4000; gbit=#2000; dbit=#1000
abits=dbit-1
wordsize=16; bytesize=8
lig1=0<<fshift | ibit | gbit | 1 //#012001
k3  =6<<fshift |  3              //#140003
x22 =7<<fshift | 22              //#160026
}
 
 
LET assemble(filename) BE
{ LET f = 0
  LET oldin = input()
  LET filestream = findinput(filename)
  LET v = VEC 2000
  labv := v

  UNLESS filestream DO
  { writef("Trouble with file: %s*n", filename)
    RETURN
  }

  selectinput(filestream)
 
clear:   // Start reading the next section, if any.
  FOR i = 0 TO 2000 DO labv!i := 0
  cp := 4
 
next:
  rch()

sw:
  SWITCHON ch INTO
  { DEFAULT: IF ch=endstreamch DO
             { endstream(filestream)
               selectinput(oldin)
               RETURN
             }
             writef("*nBad ch %c at p = %n*n", ch, p)
             GOTO next
 
    CASE '0':CASE '1':CASE '2':CASE '3':CASE '4':         // n   set a label
    CASE '5':CASE '6':CASE '7':CASE '8':CASE '9':
             setlab(rdn())
             cp := 4
             GOTO sw
 
    CASE '$':    // Marks the start of a function
    CASE '*s':
    CASE '*n':
            GOTO next
 
    CASE 'L': f := 0; ENDCASE
    CASE 'S': f := 1; ENDCASE
    CASE 'A': f := 2; ENDCASE
    CASE 'J': f := 3; ENDCASE
    CASE 'T': f := 4; ENDCASE
    CASE 'F': f := 5; ENDCASE
    CASE 'K': f := 6; ENDCASE
    CASE 'X': f := 7; ENDCASE
 
    CASE 'C': rch(); stc(rdn()); GOTO sw   // Cn     assemble a character

    CASE 'D': rch()
              TEST ch='L'
              THEN { rch()                 // DLn
                     stw(0)
                     labref(rdn(), p-1)
                   }
              ELSE stw(rdn())              // Dn
              GOTO sw
 
    CASE 'G':
            { LET gn, ln = ?,?
              rch()                  // GgLn   set global g to Ln
              gn := rdn()
              a := gn + g
              TEST ch='L'
              THEN rch()
              ELSE writef("*nbad code at p = %n*n", p)
              ln := rdn()
              !a := 0
              labref(ln, a)
//writef("assemble: G %n L%n*n", gn, ln)
              GOTO sw
            }
 
    CASE 'Z': // End of section
              FOR i = 0 TO 500 IF labv!i>0 DO writef("L%n unset*n", i)
              GOTO clear
  }
 
 
  w := f<<fshift                       // Assemble an instruction
  rch()
  IF ch='I' DO { w := w+ibit; rch() }
  IF ch='P' DO { w := w+pbit; rch() }
  IF ch='G' DO { w := w+gbit; rch() }

  TEST ch='L'
  THEN { rch()
         stw(w+dbit)
         stw(0)
         labref(rdn(), p-1)
       }
  ELSE { LET a = rdn()
         TEST (a&abits)=a
         THEN stw(w+a)
         ELSE { stw(w+dbit); stw(a)  }
       }
 
  GOTO sw
}
 
AND stw(w) BE { !p := w
                 p, cp := p+1, 4
              }
 
AND stc(c) BE { IF cp>=4 DO { stw(0)
                              cp := 0
                           }
                (p-1)%cp := c
                cp := cp+1
              }
 
AND rch() BE { ch := rdch()
               UNLESS ch='/' RETURN          // Comment character
               UNTIL ch='*n' DO ch := rdch()
             } REPEAT

AND rdn() = VALOF
{ LET a, b = 0, FALSE
  IF ch='-' DO { b := TRUE; rch()  }
  WHILE '0'<=ch<='9' DO { a := 10*a + ch - '0'; rch()  }
  IF b DO a := -a
  RESULTIS a
}
 
AND setlab(n) BE
{ LET k = labv!n
  IF k<0 DO writef("L%n already set TO %n at p = %n*n",n,-k,p)
  WHILE k>0 DO { LET n = !k
                 !k := p
                 k := n
               }
  labv!n := -p
}

AND labref(n, a) BE
{ LET k = labv!n
  TEST k<0 THEN k := -k ELSE labv!n := a
  !a := !a + k
}

AND fstr(f) = VALOF SWITCHON f INTO
{ DEFAULT: RESULTIS "?"
  CASE 0:  RESULTIS "L"
  CASE 1:  RESULTIS "S"
  CASE 2:  RESULTIS "A"
  CASE 3:  RESULTIS "J"
  CASE 4:  RESULTIS "T"
  CASE 5:  RESULTIS "F"
  CASE 6:  RESULTIS "K"
  CASE 7:  RESULTIS "X"
}

AND interpret() = VALOF
{ // Start of main loop

  IF tracing DO
  { LET w = !c
    LET op = w>>fshift
    LET opstr = fstr(op)
    writef("a=%11i  b=%11i  p=%i6 %7i: %s",a, b, p, c, opstr)
    IF (w & ibit) ~= 0 DO wrch('I')
    IF (w & pbit) ~= 0 DO wrch('P')
    IF (w & gbit) ~= 0 DO wrch('G')
    IF (w & dbit) ~= 0 DO wrch('D')
    writef("%n", w&abits)
  }

  cyclecount := cyclecount + 1
  w := !c
  c := c + 1
 
  TEST (w&dbit)=0 THEN d := w&abits
                  ELSE { d := !c; c := c+1  }
 
  IF (w & pbit) ~= 0 DO d := d + p
  IF (w & gbit) ~= 0 DO d := d + g
  IF (w & ibit) ~= 0 DO d := !d

  IF tracing DO
  { IF (w&dbit) ~=0 DO writef("  %n", d)
    newline()
  }
 
  SWITCHON w>>fshift INTO
 
  { error:
    DEFAULT: selectoutput(stdout)
             writef("*nintcode error at c = %n*n", c-1)
             RESULTIS -1
 
    CASE 0: b := a; a := d; LOOP     // L
 
    CASE 1: !d := a;        LOOP     // S
 
    CASE 2: a := a + d;     LOOP     // A
 
    CASE 3: c := d;         LOOP     // J
 
    CASE 4: IF a DO c := d; LOOP     // T
 
    CASE 5: UNLESS a DO c := d; LOOP // F
 
    CASE 6: d := p + d               // K
            d!0, d!1, d!2 := p, c, a
            p, c := d, a
            LOOP
 
    CASE 7: SWITCHON d INTO          // X
 
    { DEFAULT: GOTO error
 
      CASE 1:  a := !a;      LOOP
      CASE 2:  a := -a;      LOOP
      CASE 3:  a := NOT a;   LOOP
      CASE 4:  c := p!1     // FNRN
               p := p!0
               LOOP
      CASE 5:  a := b * a;   LOOP
      CASE 6:  a := b / a;   LOOP
      CASE 7:  a := b MOD a; LOOP
      CASE 8:  a := b + a;   LOOP
      CASE 9:  a := b - a;   LOOP
      CASE 10: a := b = a;   LOOP
      CASE 11: a := b ~= a;  LOOP
      CASE 12: a := b < a;   LOOP
      CASE 13: a := b >= a;  LOOP
      CASE 14: a := b > a;   LOOP
      CASE 15: a := b <= a;  LOOP
      CASE 16: a := b << a;  LOOP
      CASE 17: a := b >> a;  LOOP
      CASE 18: a := b & a;   LOOP
      CASE 19: a := b | a;   LOOP
      CASE 20: a := b XOR a; LOOP
      CASE 21: a := b EQV a; LOOP
 
      CASE 22: RESULTIS a         // FINISH  ie leave the interpreter
 
      CASE 23: b, d := c!0, c!1   // SWITCHON n dlab
               UNTIL b=0 DO
               { b, c := b-1, c+2 // case k and label
                 IF a=c!0 DO
                 { d := c!1
                   BREAK
                 }
               }
               c := d             // Jump to default
               LOOP
      CASE 24: a := b % a; LOOP
      CASE 25: b % a := p!(c!0)
               c := c+1
               LOOP
      CASE 26: a := ABS a; LOOP
 
      CASE 27: // The sys function
               //writef("SYS %n %n %n*n", p!3, p!4, p!5)
               a := sys(p!3, p!4, p!5, p!6, p!7)
               LOOP

// cases 40 upwards are only called from the following
// hand written intcode library - iclib:
 
//    11 LIP2 X40 X4 G11L11 /selectinput
//    12 LIP2 X41 X4 G12L12 /selectoutput
//    13 X42 X4      G13L13 /rdch
//    14 LIP2 X43 X4 G14L14 /wrch
//    42 LIP2 X44 X4 G42L42 /findinput
//    41 LIP2 X45 X4 G41L41 /findoutput
//    30 LIP2 X46 X4 G30L30 /stop
//    31 X47 X4 G31L31 /level
//    32 LIP3 LIP2 X48 G32L32 /longjump
//    46 X49 X4 G46L46 /endread
//    47 X50 X4 G47L47 /endwrite
//    40 LIP3 LIP2 X51 G40L40 /aptovec
//    85 LIP3 LIP2 X52 X4 G85L85 / getbyte
//    86 LIP3 LIP2 X53 X4 G86L86 / putbyte
//    Z
 
      CASE 40: selectinput(a); LOOP
      CASE 41: selectoutput(a); LOOP
      //CASE 42: a := etoa!rdch(); LOOP
      CASE 42: a := rdch(); LOOP
      //CASE 43: wrch(atoe!a); LOOP
      CASE 43: wrch(a); LOOP
      //CASE 44: a := findinput(string370(a)); LOOP
      CASE 44: a := findinput(a); LOOP
      //CASE 45: a := findoutput(string370(a)); LOOP
      CASE 45: a := findoutput(a); LOOP
      CASE 46: RESULTIS a  // stop(a)
      CASE 47: a := p!0; LOOP  // used in level()
      CASE 48: p, c := a, b;         // used in longjump(p,l)
               LOOP
      CASE 49: endread(); LOOP
      CASE 50: endwrite(); LOOP
      CASE 51: d := p+b+1        // used in aptovec(f, n)
               d!0, d!1, d!2, d!3 := p!0, p!1, p, b
               p, c := d, a
               LOOP
      //CASE 52: a := icgetbyte(a, b)  // getbyte(s, i)
      //CASE 52: a := a%b  // getbyte(s, i)
      CASE 36: 
//writef("X36: a=%n b=%n b%%a=>%n*n", a, b, b%a)
               a := b%a  // getbyte(s, i)
               LOOP
      //CASE 53: icputbyte(a, b, p!4)  // putbyte(s, i, ch)
      //CASE 53: a%b := p!4  // putbyte(s, i, ch)
      CASE 37: 
             { LET s = a!1
               LET i = a!2
               LET ch = a!0
//writef("*nX37: writing %n%%%n := %n*n", s, i, ch)
               s%i := ch  // putbyte(s, i, ch)
               LOOP
             }
      CASE 38: a := ABS a  // abs
               LOOP
    }
  }
} REPEAT
 
 
AND string370(s) = VALOF                 // Not used
{ LET t = TABLE 0,0,0,0,0,0,0,0
 
  t%0 := icgetbyte(s, 0)
  FOR i = 1 TO icgetbyte(s,0) DO t%i := atoe!icgetbyte(s,i)
  RESULTIS t
}
 
AND icgetbyte(s, i) = VALOF              // Not used
{ LET w = s!(i/2)
  IF (i&1)=0 DO w := w>>8
  RESULTIS w&255
}
 
AND icputbyte(s, i, ch) BE              // Not used
{ LET p = @s!(i/2)
  LET w = !p
  TEST (i&1)=0 THEN !p := w&#x00FF | ch<<8
               ELSE !p := w&#xFF00 | ch
}
 
LET start() = VALOF
{ LET introotnode = ?
  LET argv = VEC 100
 
  writes("intcode system entered*n")

  UNLESS rdargs(",,,,,,,,,,TO/K,SIZE/K/N,TRACE/S", argv, 100) DO
  { writef("Bad arguments for interp*n")
    RESULTIS 0
  }

  tofile := 0
  IF argv!10 DO tofile := argv!10            // TO/K

  progsize := 1_000_000
  IF argv!11 DO progsize := !(argv!11)       // SIZE/K/N

  tracing := argv!12                         // TRACE/S

  g, progvec := getvec(1000), getvec(progsize)
  FOR i = 0 TO 1000 DO g!i := 0
  FOR i = 0 TO progsize DO progvec!i := 0

  // Initialise some globals
  g!0 := 1000
  introotnode := progvec+100
  g!g_rootnode := introotnode

  // Initialise some rootnode elements
  FOR n = 0 TO 49 DO introotnode!n := rootnode!n

  // Leave space for the rootnode
  p := progvec+200

  stdin  := input()
  stdout := output()
 
  c := p       // Initial program counter
  p!0 := lig1  // Initial orders
  p!1 := k3
  p!2 := x22
  p := p+3

  // Load the Intcode programs
  FOR i = 0 TO 9 IF argv!i DO assemble(argv!i)
 
  IF FALSE 
  IF tracing DO
  { writef("Loaded program*n*n")
    FOR i = 200 TO 220 DO
    { LET w = progvec!i
      writef("%i3: %x5: %8x", i, progvec+i, w)
      IF (w>>(fshift+3)=0) DO
      { writef("  %s", fstr(w>>fshift))
        IF (w & ibit) ~= 0 DO wrch('I')
        IF (w & pbit) ~= 0 DO wrch('P')
        IF (w & gbit) ~= 0 DO wrch('G')
        TEST (w & dbit) ~= 0
        THEN writef("D %8x", progvec!(i+1))
        ELSE writef("%n", w&abits)
      }
      newline()
    }

    //writef("*nGlobals*n*n")
    //FOR i = 0 TO 10 DO writef("G%i3: %x8 %n*n", i, g!i, g!i)

    //writef("*nRootnode*n*n")
    //FOR i = 0 TO 49 DO writef("Rootnode!%i2: %x8 %n*n",
    //                           i, introotnode!i, introotnode!i)
  }
  writef("*nProgram size = %n*n", p-progvec-200)
 
  atoe := 1+TABLE -1,
          0,  0,  0,  0,  0,  0,  0,  0,  // ascii to ebcdic
          0,  5, 21,  0, 12,  0,  0,  0,  // '*t' '*n' '*p'
          0,  0,  0,  0,  0,  0,  0,  0,
          0,  0,  0,  0,  0,  0,  0,  0,
 
         64, 90,127,123, 91,108, 80,125, // '*s' ! " # $ % & '
         77, 93, 92, 78,107, 96, 75, 97, //   (  ) * + , - . /
        240,241,242,243,244,245,246,247, //   0  1 2 3 4 5 6 7
        248,249,122, 94, 76,126,110,111, //   8  9 : ; < = > ?
        124,193,194,195,196,197,198,199, //   @  A B C D E F G
        200,201,209,210,211,212,213,214, //   H  I J K L M N O
        215,216,217,226,227,228,229,230, //   P  Q R S T U V W
        231,232,233, 66, 98, 67,101,102, //   X  Y Z [ \ ] ? ?
         64,129,130,131,132,133,134,135, //      a b c d e f g
        136,137,145,146,147,148,149,150, //   h  i j k l m n o
        151,152,153,162,163,164,165,166, //   p  q r s t u v w
        167,168,169, 64, 79, 64, 95,255  //   x  y z   |   ~
 
 
  etoa := 1+TABLE -1,
      0,   0,   0,   0,   0, #11,   0,   0,
      0,   0,   0, #13, #14, #15,   0,   0,
      0,   0,   0,   0,   0, #12,   0,   0,
      0,   0,   0,   0,   0,   0,   0,   0,
      0,   0,   0,   0,   0, #12,   0,   0,
      0,   0,   0,   0,   0,   0,   0,   0,
      0,   0,   0,   0,   0,   0,   0,   0,
      0,   0,   0,   0,   0,   0,   0,   0,
    #40,   0,#133,#135,   0,   0,   0,   0,
      0,   0,   0, #56, #74, #50, #53,#174,
    #46,   0,   0,   0,   0,   0,   0,   0,
      0,   0, #41, #44, #52, #51, #73,#176,
    #55, #57,#134,   0,   0,#136,#137,   0,
      0,   0,   0, #54, #45,#140, #76, #77,
      0,   0,   0,   0,   0,   0,   0,   0,
      0,   0, #72, #43,#100, #47, #75, #42,
      0,#141,#142,#143,#144,#145,#146,#147,
   #150,#151,   0,   0,   0,   0,   0,   0,
      0,#152,#153,#154,#155,#156,#157,#160,
   #161,#162,   0,   0,   0,   0,   0,   0,
      0,   0,#163,#164,#165,#166,#167,#170,
   #171,#172,   0,   0,   0,   0,   0,   0,
      0,   0,   0,   0,   0,   0,   0,   0,
      0,   0,   0,   0,   0,   0,   0,   0,
      0,#101,#102,#103,#104,#105,#106,#107,
   #110,#111,   0,   0,   0,   0,   0,   0,
      0,#112,#113,#114,#115,#116,#117,#120,
   #121,#122,   0,   0,   0,   0,   0,   0,
      0,   0,#123,#124,#125,#126,#127,#130,
   #131,#132,   0,   0,   0,   0,   0,   0,
    #60, #61, #62, #63, #64, #65, #66, #67,
    #70, #71,   0,   0,   0,   0,   0,   0
 
  a, b := 0, 0
  //c := TABLE lig1, k3, x22
 
  cyclecount := 0

  a := interpret()
 
  freevec(g)
  freevec(progvec)

  selectoutput(stdout)
  writef("*n*nExecution complete cycles = %n", cyclecount)
  IF a DO writef(" return code = %n", a)
  newline()
}
 
 
 
