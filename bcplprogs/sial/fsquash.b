// This program reads a file of integers and compresses them. It
// is an experimantal program to try out possible techniques for
// use in the compression of SIAL code.

// Written by Martin Richards  7 July 1998
 
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
 hashtab: 210
 hashbits: 211
 codelen:212
 actbitcount: 213
}

MANIFEST {
//  hashupb=4092
  hashupb=4095
  maxhlen=10
}

LET start() = VALOF
{ LET argv = VEC 50
  LET n = 0
  LET bitcount = 0

  stdin := input()
  stdout := output()

  IF rdargs("DATA,TO/K,D/K", argv, 50)=0 DO
  { writes("Bad arguments for huffman*n")
    RESULTIS 10
  }

  infilename := argv!0 -> argv!0, "Fstr"
  outfilename := argv!1 -> argv!1, "**"
  debug := argv!2 -> str2numb(argv!2), 0

  data := getvec(10000)
  lenv := getvec(10000)
  frqv := getvec(256)
  hashtab := getvec(hashupb)
  FOR i = 0 TO 256 DO frqv!i := 0
  FOR i = 0 TO hashupb DO hashtab!i := f_sp
  hashbits := 0

  outfile := findoutput(outfilename)

  IF outfile=0 DO
  { writef("Can't open file %s*n", outfilename)
    n := 0
    outfile := stdout
  }

  codelen := getvec(255)
  initcodelen()
  actbitcount := 0

  selectoutput(outfile)

  n := readdata(infilename, data)

  IF (debug&2)>0 DO
    FOR i = 0 TO 256 IF frqv!i DO writef("%i2: %i3*n", i, frqv!i)

  IF n>1 DO
  { bitcount := huffgen(frqv, lenv, 256)

    FOR i = 0 TO n-1 DO
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
  LET a, b, c = 0, 0, 0
  LET count = 0

  LET n = 0

  IF instr=0 DO
  { writef("Can't open file: %s*n", filename)
    RESULTIS -1
  }

  selectinput()

  { LET val = readn()
    LET predicted = ?
    LET hashval = (b*255+a) & 4095 //REM (hashupb+1)
    c := b
    b := a
    a := val
    IF val=0 & result2<0 BREAK

    predicted := hashtab!hashval
    hashtab!hashval :=  val

//    IF val=predicted DO val := f_1               // => 2409
    IF val=predicted DO { count := count+1; LOOP } // => 2329
                                                  // bred => 2236

    WHILE count DO
    { LET dig = (count&1)>0 -> f_1, f_2
      count := (count-1)>>1
      frqv!dig := frqv!dig + 1
      v!n := dig
      IF (debug&64)>0 DO writef("%i3*n", dig)
      n := n+1
    }
    
    frqv!val := frqv!val + 1
    v!n := val
    IF (debug&64)>0 DO writef("%i3*n", val)
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

AND initcodelen() BE
{ LET v = codelen
  FOR i = 0 TO 255 DO codelen!i := 10
/*
  v!f_lp    :=  4 // lp
  v!f_lg    :=  4 // lg
  v!f_l     :=  4 // l
  v!f_sp    :=  4 // sp
  v!f_sg    :=  6 // sg
  v!f_ap    :=  6 // ap
  v!f_s     :=  7 // s
  v!f_lkp   :=  6 // lkp
  v!f_lkg   :=  7 // lkg
  v!f_kpg   :=  4 // kpg
  v!f_atblp :=  5 // atblp
  v!f_atblg :=  7 // atblg
  v!f_atbl  :=  6 // atbl
  v!f_l     :=  6 // j
  v!f_rtn   :=  5 // rtn
//  v!f_jne :=  8 // jne
  v!f_jeq0  :=  7 //jeq0
  v!f_lab   :=  4 // lab
  v!f_entry :=  6 // entry
  v!f_1     :=  2 // 1
  v!f_2     :=  4 // 2
*/
   v!f_1      :=  2 //       11  // 1     1972

   v!f_2      :=  4 //     1101  // 2      788
   v!f_sp     :=  4 //     0101  // sp     641
   v!f_kpg    :=  4 //     1001  // kpg    631
   v!f_l      :=  4 //     0001  // l      558
   v!f_lp     :=  4 //     1110  // lp     536
   v!f_lab    :=  4 //     0110  // lab    518

   v!f_lg     :=  5 //    11010  // lg     370
   v!f_rtn    :=  5 //    01010  // rtn    284
   v!f_lkp    :=  5 //    10010  // lkp    230
   v!f_sg     :=  5 //    00010  // sg     228

   v!f_j      :=  6 //   111100  // j      178
   v!f_atblp  :=  6 //   011100  // atblp  171
   v!f_atbl   :=  6 //   101100  // atbl   145
   v!f_atblg  :=  6 //   001100  // atblg  117
   v!f_lstr   :=  6 //   110100  // lstr   105
   v!f_entry  :=  6 //   010100  // entry   92
   v!f_jeq0   :=  6 //   100100  // jeq0    86

   v!f_jne    :=  7 //  1000100  // jne     82
   v!f_string :=  7 //  0000100  // string  71
/*
   v!f_lm     :=  7 //  1111000  // lm      63
   v!f_jne0   :=  7 //  0111000  // jne0    62
   v!f_ap     :=  7 //  1011000  // ap      62
   v!f_s      :=  7 //  0011000  // s       54
   v!f_lkg    :=  7 //  1101000  // lkg     53
   v!f_jeq    :=  7 //  0101000  // jeq     58
   v!f_ikg    :=  7 //  1001000  // ikg     45

   v!f_ikp    :=  8 // 10001000  // ikp     45
*/
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
      writef("%i6: %n %i6*n", f!(pt!j), type!j, sum!j)
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


