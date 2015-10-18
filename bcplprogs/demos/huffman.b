// This program reads a file of integer frequency counts and
// outputs information about its Huffman encoding.

// Written by Martin Richards  6 July 1998
// (Based on a C program by D.J.Wheeler.)
 
GET "libhdr"

GLOBAL {
 data: 200;  lenv
 infile; outfile; stdin; stdout
 infilename; outfilename
 debug1; debug2; debug3; debug4
}

LET start() = VALOF
{ LET argv = VEC 50
  LET n = 0
  LET bitcount = 0

  stdin := input()
  stdout := output()

  IF rdargs("DATA,TO/K,HELP/S,D1/S,D2/S,D3/S,D4/S", argv, 50)=0 DO
  { writes("Bad arguments for huffman*n")
    RESULTIS 10
  }

  infilename := argv!0 -> argv!0, "FREQS"
  outfilename := argv!1 -> argv!1, "**"

  IF argv!2 DO
  { writes("*nThis program reads a file of integers that represent*n")
    writes("the frequencies of a set of symbols. It computes*n")
    writes("a Huffman tree and output statistical information*n")
    writes("controlled by the switch arguments D1, D2, D3 and D4*n")
    writes("*n")
    writes("D1    output the Huffman encodings*n")
    writes("D2    output the frequency table*n")
    writes("D3    output the Huffman tree*n")
    writes("D4    output the number of codes of each length*n")
    writes("*n")
    writes("DATA  name of frequency counts file*n")
    writes("TO    name of the output file")
    writes("*n")
    RESULTIS 0
  }
  debug1 := argv!3
  debug2 := argv!4
  debug3 := argv!5
  debug4 := argv!6

  data := getvec(10000)
  lenv := getvec(10000)

  n := readdata(infilename, data)

  IF debug2 DO
  { writef("*nFrequency counts*n*n")
    FOR i = 0 TO n-1 DO writef("%i3: %i3*n", i, data!i)
  }
  outfile := findoutput(outfilename)
  IF outfile=0 DO
  { writef("Can't open file %s*n", outfilename)
    n := 0
    outfile := stdout
  }

  selectoutput(outfile)

  IF n>1 DO
  { bitcount := huffgen(data, lenv, n)

    IF debug1 DO
    { writef("*nHuffman codes:*n*n")

      FOR i = 0 TO n-1 DO
      { LET len = lenv!i
        IF len=0 LOOP
        writef(" %i3 %i2: ", i, len)
        writebin(data!i, len)
        newline()
      }
    }

    writef("*nLength of encoded data = %n bits (%n bytes)*n",
            bitcount, (bitcount+7)/8)
  }

  UNLESS outfile=stdout DO
  { endwrite()
    selectoutput(stdout)
  }
  freevec(data)
  freevec(lenv)
  RESULTIS 0
}

AND readdata(filename, v) = VALOF
{ LET instr = findinput(filename)
  LET stdin = input()

  LET n = 0

  IF instr=0 DO
  { writef("Can't open file: %s*n", filename)
    RESULTIS -1
  }

  selectinput()

  { LET val = readn()
    IF val=0 & result2<0 BREAK
    v!n := val
    n := n+1
  } REPEAT

  endread()
  selectinput(stdin)
  RESULTIS n
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
  LET r = 22
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

  IF debug3 DO
  { FOR j=0 TO mlim-2 DO
    { LET t = type!j
      LET ts = t=0 -> "LL", t=1 -> "LN", "NN"
      writef("  %i6 %s*n", sum!j, ts)
    }
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

  IF debug4 DO
  { writef("*nLength counts*n*n")
    FOR i = 0 TO 23 IF cts!i DO writef("%i3 codes of length %n*n", cts!i, i)
  }

  IF len!(pt!0) >= 24 DO
  { /* The length of the longest code is >= 24
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


