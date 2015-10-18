/*
This is a straightforward translation of Strachey's GPM
from CPL to BCPL as given in

C. Strachey
"General Purpose Macrogenerator"
CJ Vol.8 No 3 Oct 1965 from CPL to BCPL.

This version has a comment mechanism using the warning
character '`' to remove the rest of the current line
and then all white space until the next non white space
charater. It only does this when reading from standard
input or a file. It required a small change in NextCh.

Otherwise, this is a close approximation to the original
CPL version as printer in the CJ paper. I have even used
[] for subscription (nor !), but have had to modify the
CPL simultaneous assignments since in BCPL these are not
truely simultaneous. Global variables have been used for
most of the GPM state variables. Most of the labels and
GOTO statements have been retained, even though many
could be removed using BREAK, LOOP and represt loops.
*/

SECTION "gpm"

GET "libhdr"

GLOBAL {
ST:ug; S; H; P; F; C; E; A; W; q
ch; sysin; sysout; fromstream; tostream
upb
Load; NextCh; Find
tracing

// Labels in gpm() used by longjump()
gpm_level
Monitor7       // used in longjump from Find()
start_level
Fin
Start
Copy
Apply
EndFn
DEF
VAL
UPDATE
BIN
DEC
BAR
}

MANIFEST {
s_eof = -1; s_marker = -2

// Machine macros
s_def = -1; s_val=-2; s_update=-3; s_bin=-4; s_dec=-5; s_bar=-6

// Warning characters
c_call   = '['; c_apply  = ']'; c_sep = '\'; c_skip = '`' 
c_lquote = '{'; c_rquote = '}'; c_arg = '^'; c_skip = '`'
}

LET start() = VALOF
{ LET argv = VEC 40
  LET MST = TABLE
    -1,4,'D','E','F',s_def,
     0,4,'V','A','L',s_val,
     6,7,'U','P','D','A','T','E',s_update,
    12,4,'B','I','N',s_bin,
    21,4,'D','E','C',s_dec,
    27,4,'B','A','R',s_bar

  IF rdargs("FROM,TO/K,UPB/K/N,-t/S", argv, 40)=0 DO
  { writes("Bad arguments for GPM*n"); RESULTIS 20 }

  upb := 500_000
  IF argv!2 DO upb := !(argv!2)             // UPB/K/N
  IF upb<500 DO upb := 500
  ST := getvec(upb)
  IF ST=0 DO
  { writef("Unable to allocate work space (upb = %n)*n", upb)
    RESULTIS 20
  }

  tracing := argv!3                         // -t/S

  sysin := input()
  fromstream := sysin
  UNLESS argv!0=0 DO                        // FROM
  { fromstream := findinput(argv!0)
    IF fromstream=0 DO
    { writef("Unable to read file %s*n", argv!0); RESULTIS 20 }
  }
  selectinput(fromstream)

  sysout := output()
  tostream := sysout
  UNLESS argv!1=0 DO                        // TO/K
  { tostream := findoutput(argv!1)
    IF tostream=0 DO
    { writef("Unable to write to file %s*n", argv!1)
      UNLESS fromstream=sysin DO endread()
      RESULTIS 20 }
  }
  selectoutput(tostream)

  H, P, F, C := 0, 0, 0, 0
  S, E, q := 39, 33, 1
  FOR k = 0 TO 38 DO ST[k] := MST[k]

  start_level := level()

  gpm()

Fin:
  UNLESS fromstream=sysin DO endread()
  UNLESS tostream=sysout  DO endwrite()
  selectinput(sysin)
  selectoutput(sysout)
  freevec(ST)
  RESULTIS 0
}

AND Load() BE
  TEST H=0
  THEN wrch(A)
  ELSE { ST[S] := A; S := S+1 }

AND NextCh() BE
  TEST C=0
  THEN { A := rdch()
         WHILE A=c_skip DO // Extension
         { // Ignore all character until the end of the line
           A := rdch() REPEATUNTIL A='*n' | A='*p' | A=endstreamch
           // Now ignore all white space characters
           WHILE A='*n' | A='*p' | A='*s' | A='*t' DO A := rdch()
         }
       }
  ELSE { A := ST[C]; C := C+1 }


AND Find(x) BE
{ A, W := E, x
//writef("Find:*n")
//FOR i= 0 TO 38 TEST 32<=ST[i]<127 THEN writef(" %c", ST[i])
//                                  ELSE writef(" %n", ST[i])
//newline()

  { //writef("Find: A=%n W=%n*n", A, W)
    FOR r = 0 TO ST[W]-1 DO
    { //writef("r=%n ST[W+r]=%n ST[A+r+1]=%n*n", r, ST[W+r], ST[A+r+1])
      UNLESS ST[W+r]=ST[A+r+1] GOTO Next
    }
    W := A+1+ST[W]
    //writef("Found W=%n*n", W)
    RETURN
Next:
    //writef("A=%n ST[A]=%n*n", A, ST[A])
    A := ST[A]
    //writef("A=%n*n", A)
    //abort(1000)
  } REPEATUNTIL A<0

  longjump(gpm_level, Monitor7)
}

AND Number(ch) = '0'<=ch<='9' -> ch-'0', -1

AND Char(x) = x+'0'

AND gpm() BE
{ // Main cycle
  gpm_level := level()  // Used by some jumps to Monito labels

Start:
//writef("Start: reached*n")
  NextCh()
//writef("gpm: A=%n", A)
//IF 32<=A<=126 DO writef(" '%c'")
//newline()
//writef("gpm:*n")
//FOR i= 0 TO 38 TEST 32<=ST[i]<127 THEN writef(" %c", ST[i])
//                                  ELSE writef(" %n", ST[i])
//newline()

  SWITCHON A INTO
  { DEFAULT:
//writef("default: H=%n S=%n F=%n P=%n*n", H, S, F, P)

Copy:
      { Load()
Scan:   IF q=1 GOTO Start
q2:     NextCh()
        IF A=c_lquote DO { q := q+1; GOTO Copy }
        UNLESS A=c_rquote GOTO Copy
        q := q-1
        IF q=1 GOTO Start
        GOTO Copy
      }

    CASE c_lquote:
//writef("lquote*n")
      q := q+1
      GOTO q2

    CASE c_call:
//writef("call: H=%n S=%n F=%n P=%n*n", H, S, F, P)
      ST[S]   := H
      ST[S+1] := F
      ST[S+2] := 0
      ST[S+3] := 0
      F := S+1
      H := S+3
      S := S+4
//writef("call1: H=%n S=%n F=%n P=%n*n", H, S, F, P)
      GOTO Start

    CASE c_sep:
//writef("sep: H=%n S=%n F=%n P=%n*n", H, S, F, P)
      IF H=0 GOTO Copy
      ST[H] := S-H-ST[H]
      ST[S] := 0
      H := S
      S := S+1
//writef("sep1: H=%n S=%n F=%n P=%n*n", H, S, F, P)
      GOTO Start
      
    CASE c_apply:
Apply:
//writef("apply: H=%n S=%n F=%n P=%n*n", H, S, F, P)
      IF P>F GOTO Monitor1
      IF H=0 GOTO Copy
    { LET H0, F0 = ST[F-1], ST[F] // Previous H and F
      ST[H] := S-H
      ST[S] := s_marker
      ST[F-1] := S-F+2
      ST[F] := P
      ST[F+1] := C
      P := F
      S := S+1
      H := H0
      F := F0
    }
//writef("apply1: H=%n S=%n F=%n P=%n*n", H, S, F, P)
      UNLESS H=0 DO ST[H] := ST[H] + ST[P-1]
      Find(P+2)
      TEST ST[W]<0
      THEN GOTO MachineMacro(ST[W])
      ELSE C := W+1
      GOTO Start

    CASE c_arg:
//writef("arg: H=%n S=%n F=%n P=%n*n", H, S, F, P)
      IF P=0 GOTO H=0 -> Copy, Monitor2
      NextCh()
      W := P+2
      IF Number(A)<0 GOTO Monitor3
      FOR r = 0 TO Number(A)-1 DO
      { W := W+ST[W]
        IF ST[W]=s_marker GOTO Monitor4
      }
      FOR r = 1 TO ST[W]-1 DO
      { A := ST[W+r]
        Load()
      }
//writef("arg1: H=%n S=%n F=%n P=%n*n", H, S, F, P)
      GOTO Start

    CASE s_marker: // Marks the end of a macro body
EndFn:
//writef("EndFn: H=%n S=%n F=%n P=%n*n", H, S, F, P)
//prstate()
      IF P=0 DO
      { A := 'M'
        Load()
        longjump(start_level, Fin)
//abort(1111)
      }

      IF F>P GOTO Monitor5
      ST!S := E
      A := S
      // Adjust environment chain pointers in the result
      WHILE ST[A] >= P-1+ST[P-1] DO
      { LET A1 = ST[A]
        ST!A := A1 - ST[P-1]
        A := A1
      }
      W := ST[A]
      // W points to the first definition in or below the current macro call
      // Remove definitions embedded in the call.
      WHILE W>P-1 DO W := ST[W]
      // W points to the first definition below the current macro call
//writef("EndFn: setting env pointer at %n to %n*n", A, W)
      ST[A] := W
      E := ST[S]
//writef("EndFn: E now equals %n*n", E)
      UNLESS H=0 TEST H>P
        THEN H := H - ST[P-1]
        ELSE ST[H] := ST[H] - ST[P-1]
      C := ST[P+1]
      S := S - ST[P-1]
      A := P-1         // Destination of the copy
      W := P-1+ST[P-1] // Source of the copy
      P := ST[P]
      // Copy the results and defs over the call.
      UNTIL A=S DO
      { ST[A] := ST[W]
        A := A+1
        W := W+1
      }
//writef("EndFn done: H=%n S=%n F=%n P=%n*n", H, S, F, P)
//prstate()
      GOTO Start

    CASE c_rquote:
    CASE s_eof:
//writef("eof*n")
      UNLESS C=H=0 GOTO Monitor8
      RETURN

// Machine Code Macros

  DEF:
    UNLESS H=0 DO ST[H] := ST[H] - ST[P-1] + 6
    // Pretend there is a macro call laid out
    // from P-1 to P+4 and that the result (which is a definition)
    // starts at P+5. This will be copied back over the call by the code
    // at EndFn.
    ST[P-1] := 6
    ST[P+5] := E
    E := P+5
    GOTO EndFn

  VAL:
    Find(P+6)
    UNTIL ST[W+1]=s_marker DO
    { A := ST[W+1]
      W := W+1
      Load()
    }
    GOTO EndFn

  UPDATE:
    Find(P+9)
    A := P+9+ST[P+9]
    IF ST[A] > ST[W] GOTO Monitor9
    FOR r = 1 TO ST[A] DO ST[W+r] := ST[A+r]
    GOTO EndFn
    
  BIN:
    W := 0
    A := ST[P+7]='+' -> P+8,
         ST[P+7]='-' -> P+8,
         P+7
    UNTIL ST[A]=s_marker DO
    { LET x = Number(ST[A])
      UNLESS 0<=x<=9 GOTO Monitor10
      W := 10*W + x
      A := A+1
    }
    ST[S] := ST[P+7]='-' -> -W, W
    S := S+1
    GOTO EndFn

  DEC:
    W := ST[P+7]
    IF W<0 DO
    { W := -W
      A := '-'
      Load()
    }
    { LET W1 = 1
      UNTIL 10*W1 > W DO W1 := 10*W1
      { A  := Char(W / W1)
        W  := W MOD W1
        W1 := W1 / 10
        Load()
      } REPEATUNTIL W1<1
    }
    GOTO EndFn

  BAR:
    W := ST[P+9]
    A := ST[P+11]
    A := ST[P+7]='+'  -> W  +  A,
         ST[P+7]='-'  -> W  -  A,
         ST[P+7]='**' -> W  *  A,
         ST[P+7]='/'  -> W  /  A,
                         W MOD A
    Load()
    GOTO EndFn

// Monitor for errors

Monitor1:
    // Unmatched ] in definition string. Treat as {]}
    writef("*nMONITOR: Unmatched ] in definition of ")
    Item(P+2)
    writef("*nIf this had been quoted the result would be*n")
    GOTO Copy

Monitor2:
    // Unquoted ^ in argument list in input stream. Treated as {^}
    writef("*nMONITOR: Unquoted ^ in argument list of ")
    Item(F+2)
    writef("*nIf this had been quoted the result would be*n")
    GOTO Copy
    longjump(gpm_level, Copy)
    
Monitor3:
    // Impossible character as argument number
    writef("*nMONITOR: Impossible argument number in definition of ")
    Item(P+2)
    writef("*nIf this argument reference is ignored the result would be*n")
    GOTO Monitor11

Monitor4:
    // Not enough arguments supplied in call. Terminate.
    writef("*nMONITOR: No argument ")
    H := 0
    Load()
    writef(" in call for ")
    Item(P+2)
    GOTO Monitor11

Monitor5:
    // Terminator in impossible place; if C=0, this is the input stream.
    // Probably machine error: Terminate. If C non zero, this is
    // an argument list. Probably due to a missing ]: Final ] inserted.
    writef("*nMONITOR: Terminator in ")
    IF C=0 DO
    { writef("input stream. Probably machine error.")
      GOTO Monitor11
    }
    writef(" argument list for ")
    Item(F+2)
    writef("*nProbably due to a ] missing from the definition of ")
    Item(P+2)
    writef("*nIf a final ] is added the result is*n")
    C := C-1
    GOTO Apply

Monitor7:
    // Undefined macro name: Terminate.
    writef("*nMONITOR: Undefined name: ")
    Item(W)
    GOTO Monitor11

Monitor8:
    // Wrong exit (not C=H=0). Machine error: Terminate.
    writef("*nMONITOR: Unmatched }. Probably machine error.")
    GOTO Monitor11

Monitor9:
    // Update string too long: Terminate.
    writef("*nMONITOR: Update argument too long for ")
    Item(P+9)
    GOTO Monitor11

Monitor10:
    // Non-digit in number for BIN. Terminate.
    writef("*nMONITOR: Non-digit in number*n")
    GOTO Monitor11

Monitor11:
    // General monitor after irremedial errors.
    W := 20
    writef("*nCurrent macros are")
    UNTIL P=F=0 DO
    { LET W1 = ?
      TEST P>F
      THEN { W1 := P+2
             P := ST[P]
             writef("*nAlready entered*n")
           }
      ELSE { W1 := F+2
             F := ST[F]
             writef("*nNot yet entered*n")
           }
      FOR r = 1 TO W DO
      { //writef("W1=%n ST!W!=%n*n", W1, ST!W1)
        Item(W1)
        IF ST[W1]=0 BREAK // W1 was an incomplete argument
        W1 := W1 + ST[W1]
        IF ST[W1]=s_marker BREAK
        UNLESS W=1 DO writef("*nArg%n: ", r)
      }
      W := 1
    }
    writef("*nEnd of monitor printing*n")
    A := 'Q'
    Load()
//writef("F=%n P=%n*n", F, P)
    IF P=0 DO C := 0  // Modification
writef("*n*nPress c to continue after the abort*n")
abort(1000)
    IF P>F GOTO EndFn
    GOTO Start

  }
} REPEAT

AND MachineMacro(m) = VALOF SWITCHON m INTO
{ DEFAULT:
    writef("System error: Unknown machine macro*n")
    abort(999)
    RESULTIS Start

  CASE s_def:    RESULTIS DEF
  CASE s_val:    RESULTIS VAL
  CASE s_update: RESULTIS UPDATE
  CASE s_bin:    RESULTIS BIN
  CASE s_dec:    RESULTIS DEC
  CASE s_bar:    RESULTIS BAR
}

AND Item(x) BE
{ LET a, h = A, H
  H := 0
  FOR k = 1 TO ST[x]=0 -> S-x-1, ST[x]-1 DO
  { A := ST[x+k]
    Load()
  }
  IF ST[x]=0 DO writef("... (Incomplete)*n")
  A, H := a, h
}

AND prstate() BE
{ writef("*nState    P=%n F=%n E=%n H=%n S=%n", P, F, E, H, S)
  FOR i = 0 TO S-1 DO
  { LET x = ST[i]
    IF i MOD 10 = 0 DO writef("*n%i3:", i)
    writef(" %i3", ST[i])
    TEST 32<=x<=127
    THEN writef("=%c", x)
    ELSE writef("  ")
  }
  newline()
  writef("Def chain*n")
  { LET p = E
    { LET a = p+1 + ST[p+1]
      writef("%i3: ", p)
      Item(p+1)
      writef(" ")
      TEST ST[a]<0
      THEN writef("%n", ST[a])
      ELSE Item(a)
      newline()
      p := ST[p]
      IF p<0 BREAK
    } REPEAT
  }
}
