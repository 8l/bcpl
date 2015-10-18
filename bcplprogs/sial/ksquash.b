// This program reads a file of integers and compresses them. It
// is an experimantal program to try out possible techniques for
// use in the compression of SIAL code. This version is for the 
// K stream.

// Written by Martin Richards  22 July 1998
 
GET "libhdr"

GET "sial.h"

GLOBAL {
 data: 200
 lenv: 201
 infile: 202
 outfile: 203
 stdin: 204
 stdout: 205
 infilename:206
 outfilename:207
 debug: 208
 frqv: 209
 mtfbuf: 210
 codelen:212
 actbitcount: 213
 datap: 214
}

MANIFEST {
  mtfbufupb=4095
  maxhlen=18
}

LET start() = VALOF
{ LET argv = VEC 50
  LET bitcount = 0

  stdin := input()
  stdout := output()

  IF rdargs("DATA,TO/K,D/K", argv, 50)=0 DO
  { writes("Bad arguments for gsquash*n")
    RESULTIS 10
  }

  infilename := argv!0 -> argv!0, "Kstr"
  outfilename := argv!1 -> argv!1, "**"
  debug := argv!2 -> str2numb(argv!2), 0

  data := getvec(10000)
  lenv := getvec(10000)
  frqv := getvec(256)
  mtfbuf := getvec(mtfbufupb)
  FOR i = 0 TO 256 DO frqv!i := 0
  FOR i = 0 TO mtfbufupb DO mtfbuf!i := i

  outfile := findoutput(outfilename)

  IF outfile=0 DO
  { writef("Can't open file %s*n", outfilename)
    datap := 0
    outfile := stdout
  }

  codelen := getvec(255)
  initcodelen()
  actbitcount := 0

  selectoutput(outfile)

  datap := 0
  readdata(infilename)

  IF (debug&2)>0 DO
    FOR i = 0 TO 256 IF frqv!i DO writef("%i2: %i3*n", i, frqv!i)

  IF datap>1 DO
  { bitcount := huffgen(frqv, lenv, 256)

    // Compare with a constant predefined Huffman table
    FOR i =  0 TO 15 DO codelen!i := 2 + i/2
    FOR i = 16 TO 31 DO codelen!i := 12

    FOR i = 0 TO datap-1 DO
    { //writef("%i6: %i3  %i3*n", actbitcount, data!i, codelen!(data!i))
      actbitcount := actbitcount + codelen!(data!i)
    }
    IF (debug&1)>0 DO
    { writef("Huffman codes:*n*n")

      FOR i = 0 TO 255 DO
      { LET len = lenv!i
        IF len=0 LOOP
        writef(" %i3 %i2: ", i, len)
        writebin(frqv!i, len)
        newline()
      }
    }
  }
  writef("*nLength of optimally encoded data = %n bits (%n bytes)*n",
          bitcount, (bitcount+7)/8)
  writef("*nActual length = %n bits (%n bytes)*n",
          actbitcount, (actbitcount+7)/8)

  UNLESS outfile=stdout DO
  { endwrite()
    selectoutput(stdout)
  }
  freevec(frqv)
  freevec(data)
  freevec(lenv)
  RESULTIS 0
}

AND readdata(filename, v) = VALOF
{ LET instr = findinput(filename)
  LET stdin = input()
  LET count = 0
  LET n     = 0

  UNLESS instr DO
  { writef("Can't open file: %s*n", filename)
    RESULTIS -1
  }

  selectinput()

  { LET val = readn()

    IF val=0 & result2<0 BREAK // on EOF

    insert(val)
  } REPEAT

  endread()
  selectinput(stdin)
  RESULTIS n
}

AND insert(x) BE
{ MANIFEST { Bits=11; N=1<<Bits; Mask=N-1 }
  UNTIL 0<=x<=Mask DO
  { insert1((x&Mask)+N)
    x := x>>Bits
  }
  insert1(x)
}

AND insert1(x) BE
{ MANIFEST { Bits=7; N=1<<Bits; Mask=N-1 }
  x := mtf(x, mtfbuf, mtfbufupb)  // This saves about 131 bytes
  UNTIL 0<=x<=Mask DO
  { insertval((x&Mask)+N)
    x := x>>Bits
  }
  insertval(x)
}

AND insertval(x) BE
{ frqv!x := frqv!x + 1
  IF (debug&64)>0 DO writef("%i3: %i3*n", datap, x)
  data!datap := x
  datap := datap+1
}

AND mtf(val, buf, upb) = VALOF
{ FOR p = 0 TO upb IF buf!p=val DO
  { FOR q = p TO 1 BY -1 DO buf!q := buf!(q-1)
    buf!0 := val
/*
writef("%i3: ", p)
FOR i = 0 TO p DO writef(" %i2", buf!i)
newline()
*/
    RESULTIS p
  }
  RESULTIS -1
}


AND shell(v, pt, n) BE
{ LET k = (n+3)/5
  WHILE k>0 DO
  { FOR p=0 TO n-k-1 DO
    { LET x = v!(pt!(p+k))
      IF x < v!(pt!p) DO
      { LET q  = p-k
        LET pk = pt!(p+k)
        pt!(p+k) := pt!p
        WHILE q>=0 & v!(pt!q)>x DO { pt!(q+k) := pt!q; q := q-k }
        pt!(q+k) := pk
      } 
    }
    k := (k+1)/3
  }
}

AND initcodelen() BE
{ LET v = codelen
  FOR i = 0 TO 255 DO codelen!i := 10
}

AND huffgen(f, len, n) = VALOF
{
  /* f!0 ... f!(n-1) contain frequencies of items 0...n-1
   * On return:
   *   f!i contains code for item i
   *   len!i contains the bit length of code for item i
   *   the result is the bit length of the huffman encoded data
   *   (= the sum of the internal node frequencies)
  */
  LET m, p, q = ?, ?, ?
  LET bits = ?
  LET mlim = 0
  LET u = 0
  LET r = maxhlen //22
  LET cts = VEC 50
  LET pt = getvec(n)
  LET type, sum = ?, ?

  FOR j=n-1 TO 0 BY -1 DO
  { LET x = f!j
    IF x DO { pt!mlim := j; mlim := mlim+1; u := u+x }
    len!j := 0
  }
  /* pt now contains pointers (subscripts) to the non-zero elements of f
   * mlim = no of non-zero elements of f
   * u = the cumulative total of the frequencies, ie SUM(f!i)
  */

  type := getvec(mlim)
  sum  := getvec(mlim)

  // Now sort pt!0...pt!(mlim-1) so that i => f!pt!i<=f!pt!(i+1)

  shell(f,pt,mlim)

  FOR j=0 TO mlim-2 IF f!(pt!j) > f!(pt!(j+1)) DO writef("bug %n*n", j)

js:
  FOR m=0 TO mlim-1 DO sum!m := #x7000000 // no f!i will be this big
  m := 0
  p := 0
  q := 0

  /* Form the Huffman tree by successively combining nodes
   * (whether leaf or internal) which have the lowest pair of
   * frequencies.
   *
   * f!pt!0...f!pt!(mlim-1) give the leaf node frequencies
   * sum!0...sum!(mlim-2) give the internal node frequencies
   *        (both are in increasing frequency order)
   *
   * type!i describes how internal node i was formed
   *                 0 => leaf     + leaf
   *                 1 => internal + leaf
   *                 2 => internal + internal
   * The values in type uniquely specify the tree shape.
   *
   * Example:
   *
   * f!(pt!*)     1  1  1  1  1  1  1  1  2  4  5
   * type!*       0  0  0  0  1  2  1  2  1  2
   * sum!*        2  2  2  2  4  4  6  8 11 19
   *
   * The tree is formed as follows:
   *
   *    Type 0 => N0(2)  = L0(1) + L1(1)
   *    Type 0 => N1(2)  = L2(1) + L3(1)
   *    Type 0 => N2(2)  = L4(1) + L5(1)
   *    Type 0 => N3(2)  = L6(1) + L7(1)
   *    Type 1 => N4(4)  = N0(2) + L8(2)
   *    Type 2 => N5(4)  = N1(2) + N2(2)
   *    Type 1 => N6(6)  = N3(2) + L9(4)
   *    Type 2 => N7(8)  = N4(4) + N5(4)
   *    Type 1 => N8(11) = N6(6) + L10(5)
   *    Type 2 => N9(19) = N7(8) + N8(11)
  */ 
  WHILE q<mlim-1 DO
  { IF m+1<mlim & f!(pt!(m+1))<=sum!p DO
    { type!q := 0              // Combine two leaf nodes 
      sum!q := f!(pt!m) + f!(pt!(m+1))
      q := q+1
      m := m+2
      LOOP
    }
    IF m<mlim & sum!(p+1)<f!(pt!m) | m=mlim DO
    { type!q := 2;             // Combine two internal nodes
      sum!q := sum!p + sum!(p+1)
      q := q+1
      p := p+2;
      LOOP
    }
    type!q := 1;               // Combine an internal with a leaf node
    sum!q := sum!p + f!(pt!m)
    q := q+1
    p := p+1
    m := m+1
  }

  IF (debug&4)>0 DO
  { FOR j=0 TO mlim-2 DO
    { LET t = type!j
      LET ts = t=0 -> "LL", t=1 -> "LN", "NN"
      writef("%i6: %s %i6*n", f!(pt!j), ts, sum!j)
    }
    writef("%i6:*n", f!(pt!(mlim-1)))
  }

  /* Calculate the total bit length of the data when encoded
   * using this Huffman tree.
   * This length equals the sum of the internal node frequencies.
   * Do this before the vector sum is used for other purposes.
  */ 
  bits := 0; 
  FOR j=0 TO mlim-2 DO bits := bits + sum!j

  /* cts!j will equal the number of codes of length j
   * using sum!i to hold the distance of internal node i
   * from the root.
  */
  FOR j=0 TO 49 DO cts!j := 0
  sum!(q-1) := 0              // Internal node q-1 is the root
  WHILE q DO
  { LET y = ?
    q := q-1
    y := sum!q+1    // the code length for children of node q 
    SWITCHON type!q INTO
    { CASE 2: p := p-1
              sum!p := y
              p := p-1
              sum!p := y
              ENDCASE
      CASE 1: m := m-1
              len!(pt!m) := y
              p := p-1
              sum!p := y
              cts!y := cts!y + 1
              ENDCASE
      CASE 0: m := m-1
              len!(pt!m) := y
              m := m-1
              len!(pt!m) := y
              cts!y := cts!y + 2
              ENDCASE
    }
  }

  IF (debug&8)>0 DO
  { writef("Length counts*n")
    FOR i = 0 TO 23 IF cts!i DO writef("cts!%i3 is %i2*n", i, cts!i)
  }
  IF len!(pt!0) > maxhlen DO
  { /* The length of the longest code is > maxhlen (=24?
     * Adjust the frequencies of the least frequent items
     * without changing the cumulative total to reduce the
     * longest code length.
     * On each attempt we approximately double the frequency
     * of the least common items.
    */
    LET x = (u>>r)+1  // Choose a frequency to give to the 
                      // least common items
    LET z = 0
    LET q = 0
    r := r-1

    WHILE z>=0 DO
    { z := z + x - f!(pt!q)          // z = the change in the cumulative total
      f!(pt!q) := x
      q := q+1
    }
    f!(pt!(q-1)) := f!(pt!(q-1)) - z // Adjust to correct the cumulative total 
    GOTO js
  }

  /* cts!m now holds the number of Huffman codes of length m, m=0..23
   * (we have taken care that there are no codes longer than 23)
   * 
   *             0  1  2  3  4  5  6  7  8  9 10
   * f!(pt!*)    1  1  1  1  1  1  1  1  2  4  5
   * type!*      0  0  0  0  1  2  1  2  1  2
   * sum!*       3  3  3  3  2  2  2  1  1  0
   * len!(pt!*)  4  4  4  4  4  4  4  4  3  3  2
   *
   * The tree is formed as follows:
   *
   *    Type 0 => N0(2)  = L0(1) + L1(1)
   *    Type 0 => N1(2)  = L2(1) + L3(1)
   *    Type 0 => N2(2)  = L4(1) + L5(1)
   *    Type 0 => N3(2)  = L6(1) + L7(1)
   *    Type 1 => N4(4)  = N0(2) + L8(2)
   *    Type 2 => N5(4)  = N1(2) + N2(2)
   *    Type 1 => N6(6)  = N3(2) + L9(4)
   *    Type 2 => N7(8)  = N4(4) + N5(4)
   *    Type 1 => N8(11) = N6(6) + L10(5)
   *    Type 2 => N9(19) = N7(8) + N8(11)
   *
   * cts(2) = 1, cts(3) = 2, cts(4) = 8, all others are zero.
   *
   * These can be used to allocate the codes, for example
   *
   *  symb  f(symb)  len(symb)        code
   *
   *   0      2         3              101
   *   1      1         4         0111
   *   5      1         4         0110
   *   6      1         4         0101
   *   7      5         2                  11
   *  10      1         4         0100
   *  11      4         3              100
   *  12      1         4         0011
   *  13      1         4         0010
   *  20      1         4         0001
   *  21      1         4         0000
   *
   * Smallest code of for length  0000 100 11
   * Number of codes                 8   2  1
   *
   * Note that the symb->code mapping can be deduced from
   * the symbb->len mapping. 
  */

  { LET x = 0
    FOR m=49 TO 0 BY -1 DO
    { LET y = cts!m
      cts!m := x   // Set the smallest Huffman code of length m
      x := x+y     // Allocate y codes of this length
      x := x>>1    // Calculate the smallest code of length m-1
    }
  }
  // Replace elements of f with their corresponding  Huffman codes
  FOR m = n-1 TO 0 BY -1 DO
    IF len!m DO { LET code = cts!(len!m)
                  f!m := code
                  cts!(len!m) := code + 1
                }

  freevec(pt)
  freevec(sum)
  freevec(type)
  RESULTIS bits
}


