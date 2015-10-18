GET "libhdr"

GLOBAL { x : ug; y; z }

LET start() = VALOF
{ LET a, b, c = 0, #b_1011100_10100100_00101000_10100101_01001001, #x80000000
  LET d, e, f = 1, #b_0001100_01100011_10010110_01100010_00111100, #x80000000
  LET g, h, i = 1, #b_1101001_00001001_01001101_10100011_10110001, #x00000000
  LET res = next(a,b,c,d,e,f,g,h,i)

  writef("%n %bW %n*n", a, b, c>>31)
  writef("%n %bW %n*n", d, e, f>>31)
  writef("%n %bW %n*n", g, h, i>>31)

  newline()
  writef("x %bW*n", x)
  writef("y %bW*n", y)
  writef("z %bW*n", z)
  newline()

  writef("  %bW*n", res)
  writef("Instruction count:  %n*n", 
          instrcount(next, a,b,c,d,e,f,g,h,i))
  RESULTIS 0
}

// Calculate the next generation of the life game
AND next(al, a, ar, bl, b, br, cl, c, cr) = VALOF
{ // The arguments provide 3x32 bits of three consecutive
  // raster lines, arranged as follows:

  //  . . . . al  a  ar . . . .
  //  . . . . bl  b  br . . . .
  //  . . . . cl  c  cr . . . .

  // The function returns the replacement for b

  //  a is the bit pattern:  . . . l m n . . .
  //  b is the bit pattern:  . . . p q r . . .
  //  c is the bit pattern:  . . . u v w . . .

  //  Assume q is at bit position i in b

  //  count is the count of neighbours of q (in range 0 .. 8)
  //        its value = l+m+n+p+r+u+v+w

  x, y, z := a XOR c, a & c, 0

  inc((al<<31) + (a>>1))
  inc((ar>>31) + (a<<1))
  inc((bl<<31) + (b>>1))
  inc((br>>31) + (b<<1))
  inc((cl<<31) + (c>>1))
  inc((cr>>31) + (c<<1))

  // Position i is alive if it had exactly 3 neighbours,
  //                        or was alive and had 2 neighbours
  RESULTIS (x | ~x & b) & // odd count  or  even count and alive
           y & ~z         // count is 2 or 3
}

AND inc(bits) BE
{ LET carry = x & bits   // Carry from bit 0 of each counts
  z := z  |  y & carry   // Overflow bits for each count
  y := y XOR carry       // Bit 1 of each count
  x := x XOR bits        // Bit 0 of each count (least significant)
}

/* The program outputs:

0 10100100001010001010010101001001 1
1 01100011100101100110001000111100 1
1 00001001010011011010001110110001 0

x 01010111111110100111110100010010
y 01111111111100100011010000000110
z 10000000000011011100001111111001

  01110111111100100011010000000110
Instruction count:  185
*/


