/*
This program takes the output produced by the xref compiler option
sorts it, removes duplicate lines and only keeps lines that match
a given pattern.

Implemented in BCPL by Martin Richards (c) May 2006

Usage:  mkxref "FROM/A,TO/K,PAT/K"
ie:     mkxref [from] data [to result] [pat pattern] 

eg:     mkref xreflines to xrefdata pat (F/S/G/M): 

The pattern in a regular expression with the following syntax:

E -> <ch>                Matches characters other than (,),',?,%,/,#
     '<ch>               Match any given character
     ?                   Match any character
     %                   Match a null string
     E / E               Alternation
     E E                 Concatenation
     # E                 Zero or more repetitions of E
     ( E )               Override normal precedence

The default output is to the standard output stream.
*/

GET "libhdr"

GLOBAL {
blklist: ug    // List of blocks of store to hold the
               // splay tree nodes.
blk            // Start of the current block
blkp           // Pointer to start position of the next splay tree node.
blkt           // End of current block -- blkp must be less than blkt
root           // Root node of the splay tree.

stdin          // The standard input stream
stdout         // The standard output stream
instream       // The data input stream
outstream      // The output stream for the result

// Pattern matcher globals
work
wp
succflag
pattern
aux
ch
patp
patlen
errflag
}

MANIFEST {
 // Positions in a splay tree node.
 t_parent=0  
 t_left
 t_right
 t_string

 blkupb=10000  // UPB of each block
}

// The pattern match interpreter

LET match(str) = VALOF
{ LET w = VEC 128
  LET s = 0
  work, wp, succflag := w, 0, FALSE
  put(1)
  UNLESS aux%0=0 DO put(aux%0)

  { // FIRST COMPLETE THE CLOSURE
    LET n = 1
    UNTIL n>wp DO
    { LET p = work!n
      LET k, q = pattern%p, aux%p
      SWITCHON k INTO
      { CASE '#': put(p+1)
        CASE '%': put(q)
        DEFAULT:  ENDCASE
        CASE '(':
        CASE '/': put(p+1)
                  UNLESS q=0 DO put(q)
      }
      n := n+1
    }

    IF s>=str%0 RESULTIS succflag
    IF wp=0 RESULTIS FALSE
    s := s+1
    ch := str%s

    // NOW DEAL WITH MATCH ITEMS
    n := wp
    wp, succflag := 0, FALSE

    FOR i = 1 TO n DO
    { LET p = work!i
      LET k = pattern%p
      SWITCHON k INTO
      { CASE '#':
        CASE '/':
        CASE '%':
        CASE '(': LOOP

        CASE '*'':IF ch=pattern%(p+1) DO put(aux%p)
                  LOOP
        DEFAULT:  // A MATCH ITEM
                  UNLESS ch=k LOOP
        CASE '?': // SUCCESSFUL MATCH
                  put(aux%p)
                  LOOP
      }
    }
  } REPEAT
}

AND put(n) BE TEST n=0
    THEN succflag := TRUE
    ELSE { FOR i = 1 TO wp IF work!i=n RETURN
           wp := wp+1
           work!wp := n
         }

// The Compiler

LET rch() BE TEST patp>=patlen
    THEN ch := endstreamch
    ELSE { patp := patp+1
           ch := pattern%patp
         }

AND nextitem() BE
    { IF ch='*'' DO rch()
      rch()
    }

AND prim() = VALOF
{ LET a, op = patp, ch
  nextitem()
  SWITCHON op INTO
  { CASE endstreamch:
    CASE ')':
    CASE '/': errflag := TRUE
    DEFAULT:  RESULTIS a

    CASE '#': setexits(prim(), a)
              RESULTIS a

    CASE '(': a := exp(a)
              UNLESS ch=')' DO errflag := TRUE
              nextitem()
              RESULTIS a
  }
}

AND exp(altp) = VALOF
{ LET exits = 0

  { LET a = prim()
    TEST ch='/' | ch=')' | ch=endstreamch
    THEN { exits := join(exits,a)
           UNLESS ch='/' RESULTIS exits
           aux%altp := patp
           altp := patp
           nextitem()
         }
    ELSE setexits(a, patp)
  } REPEAT
}


AND setexits(list,val) BE UNTIL list=0 DO
{ LET a = aux%list
  aux%list := val
  list := a
}

AND join(a,b) = VALOF
{ LET t = a
  IF a=0 RESULTIS b
  UNTIL aux%a=0 DO a := aux%a
  aux%a := b
  RESULTIS t
}

AND cmplpat() = VALOF
{ patp, patlen := 0, pattern%0
  errflag := FALSE
  FOR i = 0 TO patlen DO aux%i := 0
  rch()
  setexits(exp(0),0)
  RESULTIS NOT errflag
}

LET start() = VALOF
{ LET argv = VEC 100
  LET form = "FROM/A,TO/K,PAT/K"

  blklist, blk, blkp, blkt := 0, 0, 0, 0

  stdin := input()
  stdout := output()
  instream, outstream := 0, 0

  UNLESS rdargs(form, argv, 100) DO
  { writef("Bad arguments for: mkxref %s*n", form)
    RESULTIS 0
  }

  instream := findinput(argv!0)       // FROM
  UNLESS instream DO
  { writef("Unable to open: %s*n", argv!0)
    GOTO fin
  }

  outstream := stdout
  IF argv!1 DO                        // TO
  { outstream := findoutput(argv!1)
    UNLESS instream DO
    { writef("Unable to open: %s*n", argv!1)
      GOTO fin
    }
  }

  blk := getvec(blkupb)
  UNLESS blk DO
  { writef("More memory needed*n")
    GOTO fin
  }
  !blk := 0
  blklist := blk

  pattern := 0         // Zero unless a pattern is given

  IF argv!2 DO                         // PAT
  { // Allocate pattern and aux
    LET pat = argv!2
    // Calculate the upb of pattern and aux in words, allowing
    // for the added #?s at each end.
    LET wlen = (2 + pat%0 + 2)/bytesperword
    pattern := @blk!1
    aux     := pattern+wlen+1
    blkp    := aux+wlen+1

    // Form #?<pat>#? in pattern
    pattern%0 := 0
    appendstring("#?", pattern) 
    appendstring(pat,  pattern) 
    appendstring("#?", pattern)

    UNLESS cmplpat(pattern, aux) DO
    { writef("Error in the pattern: %s*n", pat)
      GOTO fin
    }
  }

  selectinput(instream)
  selectoutput(outstream)

  root := readdata()
  writetree(root)
//  match(pattern, aux, str)

fin:

  IF instream DO endstream(instream)
  selectinput(stdin)
  IF outstream & stdout~=outstream DO endstream(outstream)
  selectoutput(stdout)

  WHILE blklist DO
  { LET p = !blklist
    freevec(blklist)
    blklist := p
  }
  RESULTIS 0
}

AND appendstring(s1, s2) BE
{ LET len1 = s1%0
  LET len2 = s2%0
  FOR i = 1 TO len1 DO
  { len2 := len2+1
    s2%len2 := s1%i
  }
  s2%0 := len2
}

AND readdata() = VALOF
{ root := 0
  WHILE readline(@blk!t_string) DO
  {
    writef("readline=>%s*n", @blk!t_string)
  }
  RESULTIS 0
}

AND readline(str) = VALOF
{ LET ch = rdch()
  LET len = 0
  UNTIL ch=endstreamch | ch='*n' DO
  { len := len+1
    IF len>255 RESULTIS FALSE
    str%len := ch
    ch := rdch()
  }
  str%0 := len
  IF ch='*n' & len RESULTIS TRUE
  IF ch=endstreamch & len=0 RESULTIS FALSE
} REPEAT

AND writetree(t) BE WHILE t DO
{ writet(t!t_left)
  writef("%s*b", @t!t_string)
  t := t!t_right
}

