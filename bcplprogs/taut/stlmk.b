GET "libhdr"

/* 
This is an algorithm for tautology checking

implemented in BCPL by M. Richards. (c) November 2002

It is based on Stalmarck's algorithm as described in the paper:

G. Stalmarck and M. Saflund, Modelling and Verifying Systems and
Software in Propositional Logic, IFAC, SAFECOMP90, London, UK 1990

Stalmarck's algorithm is patented.
*/

MANIFEST { Bpw=bytesperword }

STATIC {
  debug=0
  tmax=?                  // Max number of terms
  str=?; strp=?; strt=?   // String to compile and pointers
  ch=?; token=?; lexval=? // Lex variables
  varn=0; lasteid=0       // Variable numbers
  varmap=0                // Base of the varmap vector
}

LET bug(mess, a, b,c ,d) = VALOF
{ writef(mess, a, b, c, d)
  abort(999)
}

LET raise(code, mess) BE bug("Exception %n raised*n", code)

MANIFEST {

Id=1; Lparen; Rparen; Eof  // Lexical tokens

// There are 256 relations over 3 boolean variable. Use one byte (8 bits)
// to represent any particular relation.

//  [rel x y z]

//  x   1 1 1 1 0 0 0 0
//  y   1 1 0 0 1 1 0 0
//  z   1 0 1 0 1 0 1 0

//      a b c d e f g h
//                    h=1 <=> 000 in rel
//                  g=1 <=> 001 in rel
//                f=1 <=> 010 in rel
//              e=1 <=> 011 in rel        
//            d=1 <=> 100 in rel
//          c=1 <=> 101 in rel
//        b=1 <=> 110 in rel
//      a=1 <=> 111 in rel

NotY=#b00111100
And =#b10000111
Or  =#b11100001
Imp =#b10110100
Eqv =#b10010110
}

// Convert an 8-bit relation into a mnemonic string
LET relstr(relop) = VALOF SWITCHON relop INTO
{ DEFAULT:         RESULTIS "BadOp"

  CASE #b00000000: RESULTIS "FF"
  CASE #b00000000: RESULTIS "False"
  CASE #b00000001: RESULTIS "~x&~y&~z"
  CASE #b00000010: RESULTIS "~x&~y&z"
  CASE #b00000011: RESULTIS "~x&~y"
  CASE #b00000100: RESULTIS "~x&y&~z"
  CASE #b00000101: RESULTIS "~x&~z"
  CASE #b00000110: RESULTIS "~x&(y#z)"
  CASE #b00000111: RESULTIS "~(x|z&y)"
  CASE #b00001000: RESULTIS "~x&y&z"
  CASE #b00001001: RESULTIS "~x&(y=z)"
  CASE #b00001010: RESULTIS "~x&z"
  CASE #b00001011: RESULTIS "~x&(~y|z)"
  CASE #b00001100: RESULTIS "~x&y"
  CASE #b00001101: RESULTIS "~x&(z->y)"
  CASE #b00001110: RESULTIS "~x&(y|z)"
  CASE #b00001111: RESULTIS "~x"
  CASE #b00010000: RESULTIS "x&~(z|y)"
  CASE #b00010000: RESULTIS "x&~y&~z"
  CASE #b00010001: RESULTIS "~y&~z"
  CASE #b00010010: RESULTIS "~y&(x#z)"
  CASE #b00010011: RESULTIS "~y&(~x|~z)"
  CASE #b00010100: RESULTIS "~z&(x#y)"
  CASE #b00010101: RESULTIS "~z&(~x|~y)"
  CASE #b00010110: RESULTIS "y|z&x#z|x"
  CASE #b00010111: RESULTIS "y|(z=x)#z|x"
  CASE #b00011000: RESULTIS "(y#x)&(z#x)"
  CASE #b00011001: RESULTIS "z#(y->z&x)"
  CASE #b00011010: RESULTIS "z|y&x#x"
  CASE #b00011011: RESULTIS "y=(y#x)&z"
  CASE #b00011100: RESULTIS "y|z&x#x"
  CASE #b00011101: RESULTIS "y|(z=x)#x"
  CASE #b00011110: RESULTIS "x#(y|z)"
  CASE #b00011111: RESULTIS "~x|(~y&~z)"
  CASE #b00100000: RESULTIS "x&~y&z"
  CASE #b00100001: RESULTIS "~y&(x=z)"
  CASE #b00100010: RESULTIS "~y&z"
  CASE #b00100011: RESULTIS "~y&(~x|z)"
  CASE #b00100100: RESULTIS "(y#x)&(z#y)"
  CASE #b00100101: RESULTIS "(x->z&y)#z"
  CASE #b00100110: RESULTIS "y#z|y&x"
  CASE #b00100111: RESULTIS "y#z|(y=x)"
  CASE #b00101000: RESULTIS "(x#y)&z"
  CASE #b00101000: RESULTIS "z&(x=~y)"
  CASE #b00101001: RESULTIS "(x=y)#z|x&y"
  CASE #b00101010: RESULTIS "z&(~x|~y)"
  CASE #b00101011: RESULTIS "(y#x)|(z#x)=z"
  CASE #b00101100: RESULTIS "(z|y)&(y#x)"
  CASE #b00101101: RESULTIS "x=(~y&z)"
  CASE #b00101110: RESULTIS "y|(z#x)#x"
  CASE #b00101111: RESULTIS "~x|(~y&z)"
  CASE #b00110000: RESULTIS "x&~y"
  CASE #b00110001: RESULTIS "~y&(x|~z)"
  CASE #b00110010: RESULTIS "~y&(x|z)"
  CASE #b00110011: RESULTIS "~y"
  CASE #b00110100: RESULTIS "x|z&y#y"
  CASE #b00110101: RESULTIS "x|(z=y)#y"
  CASE #b00110110: RESULTIS "y#z|x"
  CASE #b00110111: RESULTIS "~y|(~x&~z)"
  CASE #b00111000: RESULTIS "x#y&(z|x)"
  CASE #b00111001: RESULTIS "y=(~x&z)"
  CASE #b00111010: RESULTIS "x|(z#y)#y"
  CASE #b00111011: RESULTIS "~y|~x&z"
  CASE #b00111100: RESULTIS "x#y"
  CASE #b00111101: RESULTIS "z|y->y#x"
  CASE #b00111110: RESULTIS "(y#x)|~x&z"
  CASE #b00111111: RESULTIS "~x|~y"
  CASE #b01000000: RESULTIS "x&y&~z"
  CASE #b01000001: RESULTIS "~z&(x#~y)"
  CASE #b01000001: RESULTIS "~z&(x=y)"
  CASE #b01000001: RESULTIS "~z&(y=x)"
  CASE #b01000001: RESULTIS "~z&(~x#y)"
  CASE #b01000001: RESULTIS "~z&(~x=~y)"
  CASE #b01000010: RESULTIS "(z#x)&(z#y)"
  CASE #b01000011: RESULTIS "x#(y->z&x)"
  CASE #b01000100: RESULTIS "y&~z"
  CASE #b01000100: RESULTIS "y&~z"
  CASE #b01000101: RESULTIS "~z&(x->y)"
  CASE #b01000101: RESULTIS "~z&(~x|y)"
  CASE #b01000110: RESULTIS "y|z&x#z"
  CASE #b01000111: RESULTIS "y|(z=x)#z"
  CASE #b01001000: RESULTIS "y&(x#z)"
  CASE #b01001000: RESULTIS "y&(x=~z)"
  CASE #b01001000: RESULTIS "y&(z#x)"
  CASE #b01001000: RESULTIS "y&(~x#~z)"
  CASE #b01001000: RESULTIS "y&(~x=z)"
  CASE #b01001001: RESULTIS "y|z&x=(z#x)"
  CASE #b01001010: RESULTIS "(z|y)&(z#x)"
  CASE #b01001011: RESULTIS "x=(y&~z)"
  CASE #b01001011: RESULTIS "x=y&~z"
  CASE #b01001011: RESULTIS "~x=(~y|z)"
  CASE #b01001100: RESULTIS "y&(~x|~z)"
  CASE #b01001100: RESULTIS "y&~(z&x)"
  CASE #b01001101: RESULTIS "y|(z=x)#z&x"
  CASE #b01001110: RESULTIS "z|y#z&x"
  CASE #b01001111: RESULTIS "x->y&~z"
  CASE #b01001111: RESULTIS "~x|(y&~z)"
  CASE #b01010000: RESULTIS "x&~z"
  CASE #b01010000: RESULTIS "x&~z"
  CASE #b01010001: RESULTIS "(y->x)&~z"
  CASE #b01010001: RESULTIS "~z&(x|~y)"
  CASE #b01010010: RESULTIS "x|z&y#z"
  CASE #b01010011: RESULTIS "x|(z=y)#z"
  CASE #b01010100: RESULTIS "(y|x)&~z"
  CASE #b01010100: RESULTIS "~z&(x|y)"
  CASE #b01010101: RESULTIS "~z"
  CASE #b01010101: RESULTIS "~z"
  CASE #b01010110: RESULTIS "y|x#z"
  CASE #b01010110: RESULTIS "z=(~x&~y)"
  CASE #b01010110: RESULTIS "~z=(x|y)"
  CASE #b01010111: RESULTIS "~((y|x)&z)"
  CASE #b01010111: RESULTIS "~z|(~x&~y)"
  CASE #b01011000: RESULTIS "(y|x)&(z#x)"
  CASE #b01011001: RESULTIS "(y->x)#z"
  CASE #b01011001: RESULTIS "z=(~x&y)"
  CASE #b01011001: RESULTIS "~z=(x|~y)"
  CASE #b01011010: RESULTIS "x#z"
  CASE #b01011010: RESULTIS "x=~z"
  CASE #b01011010: RESULTIS "z#x"
  CASE #b01011010: RESULTIS "~x#~z"
  CASE #b01011010: RESULTIS "~x=z"
  CASE #b01011011: RESULTIS "z|y->z#x"
  CASE #b01011100: RESULTIS "x|(z#y)#z"
  CASE #b01011101: RESULTIS "~z|(~x&y)"
  CASE #b01011101: RESULTIS "~z|~x&y"
  CASE #b01011110: RESULTIS "x|y&~z#z"
  CASE #b01011111: RESULTIS "x->~z"
  CASE #b01011111: RESULTIS "z->~x"
  CASE #b01011111: RESULTIS "~(z&x)"
  CASE #b01011111: RESULTIS "~x|~z"
  CASE #b01100000: RESULTIS "x&(y#z)"
  CASE #b01100000: RESULTIS "x&(y=~z)"
  CASE #b01100000: RESULTIS "x&(z#y)"
  CASE #b01100000: RESULTIS "x&(~y#~z)"
  CASE #b01100000: RESULTIS "x&(~y=z)"
  CASE #b01100001: RESULTIS "x|z&y=(z#y)"
  CASE #b01100010: RESULTIS "(z|x)&(z#y)"
  CASE #b01100011: RESULTIS "x&~z=y"
  CASE #b01100011: RESULTIS "y=(x&~z)"
  CASE #b01100011: RESULTIS "~y=(~x|z)"
  CASE #b01100100: RESULTIS "(y|x)&(z#y)"
  CASE #b01100101: RESULTIS "x&~y=z"
  CASE #b01100101: RESULTIS "z=(x&~y)"
  CASE #b01100101: RESULTIS "~z=(~x|y)"
  CASE #b01100110: RESULTIS "y#z"
  CASE #b01100110: RESULTIS "y=~z"
  CASE #b01100110: RESULTIS "z#y"
  CASE #b01100110: RESULTIS "~y#~z"
  CASE #b01100110: RESULTIS "~y=z"
  CASE #b01100111: RESULTIS "z|x->z#y"
  CASE #b01101000: RESULTIS "(z|y)&(y=(z#x))"
  CASE #b01101001: RESULTIS "x#(y=z)"
  CASE #b01101001: RESULTIS "x#(~y=~z)"
  CASE #b01101001: RESULTIS "x#y#~z"
  CASE #b01101001: RESULTIS "x#~y#z"
  CASE #b01101001: RESULTIS "x=(y#z)"
  CASE #b01101001: RESULTIS "x=(y=~z)"
  CASE #b01101001: RESULTIS "x=(~y#~z)"
  CASE #b01101001: RESULTIS "x=(~y=z)"
  CASE #b01101001: RESULTIS "y#(x=z)"
  CASE #b01101001: RESULTIS "y#(~x=~z)"
  CASE #b01101001: RESULTIS "y#x#~z"
  CASE #b01101001: RESULTIS "y#~x#z"
  CASE #b01101001: RESULTIS "y=(x#z)"
  CASE #b01101001: RESULTIS "y=(x=~z)"
  CASE #b01101001: RESULTIS "y=(z#x)"
  CASE #b01101001: RESULTIS "y=(~x#~z)"
  CASE #b01101001: RESULTIS "y=(~x=z)"
  CASE #b01101001: RESULTIS "z#(x=y)"
  CASE #b01101001: RESULTIS "z#(~x=~y)"
  CASE #b01101001: RESULTIS "z#x#~y"
  CASE #b01101001: RESULTIS "z#~x#y"
  CASE #b01101001: RESULTIS "z=(x#y)"
  CASE #b01101001: RESULTIS "z=(x=~y)"
  CASE #b01101001: RESULTIS "z=(~x#~y)"
  CASE #b01101001: RESULTIS "z=(~x=y)"
  CASE #b01101001: RESULTIS "~x#(y=~z)"
  CASE #b01101001: RESULTIS "~x#(~y=z)"
  CASE #b01101001: RESULTIS "~x#y#z"
  CASE #b01101001: RESULTIS "~x#~y#~z"
  CASE #b01101001: RESULTIS "~x=(y#~z)"
  CASE #b01101001: RESULTIS "~x=(y=z)"
  CASE #b01101001: RESULTIS "~x=(~y#z)"
  CASE #b01101001: RESULTIS "~x=(~y=~z)"
  CASE #b01101001: RESULTIS "~y#(x=~z)"
  CASE #b01101001: RESULTIS "~y#(~x=z)"
  CASE #b01101001: RESULTIS "~y#x#z"
  CASE #b01101001: RESULTIS "~y#~x#~z"
  CASE #b01101001: RESULTIS "~y=(x#~z)"
  CASE #b01101001: RESULTIS "~y=(x=z)"
  CASE #b01101001: RESULTIS "~y=(~x#z)"
  CASE #b01101001: RESULTIS "~y=(~x=~z)"
  CASE #b01101001: RESULTIS "~z#(x=~y)"
  CASE #b01101001: RESULTIS "~z#(~x=y)"
  CASE #b01101001: RESULTIS "~z#x#y"
  CASE #b01101001: RESULTIS "~z#~x#~y"
  CASE #b01101001: RESULTIS "~z=(x#~y)"
  CASE #b01101001: RESULTIS "~z=(x=y)"
  CASE #b01101001: RESULTIS "~z=(~x#y)"
  CASE #b01101001: RESULTIS "~z=(~x=~y)"
  CASE #b01101010: RESULTIS "z#y&x"
  CASE #b01101010: RESULTIS "z=(~x|~y)"
  CASE #b01101010: RESULTIS "~z=(x&y)"
  CASE #b01101011: RESULTIS "(y#x)=(y|x)&z"
  CASE #b01101100: RESULTIS "y#z&x"
  CASE #b01101100: RESULTIS "y=(~x|~z)"
  CASE #b01101100: RESULTIS "~y=(x&z)"
  CASE #b01101101: RESULTIS "(x#y&(z|x))=z"
  CASE #b01101110: RESULTIS "(z#y)|~x&z"
  CASE #b01101111: RESULTIS "x->z#y"
  CASE #b01101111: RESULTIS "~x|(y#z)"
  CASE #b01101111: RESULTIS "~x|(y=~z)"
  CASE #b01101111: RESULTIS "~x|(~y#~z)"
  CASE #b01101111: RESULTIS "~x|(~y=z)"
  CASE #b01110000: RESULTIS "x&(~y|~z)"
  CASE #b01110000: RESULTIS "x&~(z&y)"
  CASE #b01110001: RESULTIS "x|(z=y)#z&y"
  CASE #b01110010: RESULTIS "z|x#z&y"
  CASE #b01110011: RESULTIS "~y|(x&~z)"
  CASE #b01110011: RESULTIS "~y|x&~z"
  CASE #b01110100: RESULTIS "y|(z#x)#z"
  CASE #b01110101: RESULTIS "x&~y|~z"
  CASE #b01110101: RESULTIS "~z|(x&~y)"
  CASE #b01110110: RESULTIS "x&~y|(z#y)"
  CASE #b01110111: RESULTIS "y->~z"
  CASE #b01110111: RESULTIS "z->~y"
  CASE #b01110111: RESULTIS "~(z&y)"
  CASE #b01110111: RESULTIS "~y|~z"
  CASE #b01111000: RESULTIS "x#z&y"
  CASE #b01111000: RESULTIS "x=(~y|~z)"
  CASE #b01111000: RESULTIS "~x=(y&z)"
  CASE #b01111001: RESULTIS "(z|y)&(y#x)=z"
  CASE #b01111010: RESULTIS "x&~y|(z#x)"
  CASE #b01111011: RESULTIS "y->z#x"
  CASE #b01111011: RESULTIS "~y|(x#z)"
  CASE #b01111011: RESULTIS "~y|(x=~z)"
  CASE #b01111011: RESULTIS "~y|(~x#~z)"
  CASE #b01111011: RESULTIS "~y|(~x=z)"
  CASE #b01111100: RESULTIS "(y#x)|y&~z"
  CASE #b01111101: RESULTIS "(y#x)|~z"
  CASE #b01111101: RESULTIS "~z|(x#y)"
  CASE #b01111101: RESULTIS "~z|(x=~y)"
  CASE #b01111101: RESULTIS "~z|(~x#~y)"
  CASE #b01111101: RESULTIS "~z|(~x=y)"
  CASE #b01111110: RESULTIS "(y#x)|(z#x)"
  CASE #b01111111: RESULTIS "~(y&(z&x))"
  CASE #b01111111: RESULTIS "~x|~y|~z"
  CASE #b10000000: RESULTIS "x&y&z"
  CASE #b10000000: RESULTIS "y&(z&x)"
  CASE #b10000001: RESULTIS "(z=y)&(z=x)"
  CASE #b10000010: RESULTIS "z&(x#~y)"
  CASE #b10000010: RESULTIS "z&(x=y)"
  CASE #b10000010: RESULTIS "z&(y=x)"
  CASE #b10000010: RESULTIS "z&(~x#y)"
  CASE #b10000010: RESULTIS "z&(~x=~y)"
  CASE #b10000011: RESULTIS "(x->z)&(y=x)"
  CASE #b10000100: RESULTIS "y&(x#~z)"
  CASE #b10000100: RESULTIS "y&(x=z)"
  CASE #b10000100: RESULTIS "y&(z=x)"
  CASE #b10000100: RESULTIS "y&(~x#z)"
  CASE #b10000100: RESULTIS "y&(~x=~z)"
  CASE #b10000101: RESULTIS "(z->y)&(z=x)"
  CASE #b10000110: RESULTIS "(z|y)&(y#(z#x))"
  CASE #b10000111: RESULTIS "x=(y&z)"
  CASE #b10000111: RESULTIS "x=z&y"
  CASE #b10000111: RESULTIS "~x=(~y|~z)"
  CASE #b10001000: RESULTIS "y&z"
  CASE #b10001000: RESULTIS "z&y"
  CASE #b10001001: RESULTIS "(z=y)&(x->z)"
  CASE #b10001010: RESULTIS "z&(x->y)"
  CASE #b10001010: RESULTIS "z&(~x|y)"
  CASE #b10001011: RESULTIS "y|(z#x)=z"
  CASE #b10001100: RESULTIS "(x->z)&y"
  CASE #b10001100: RESULTIS "y&(~x|z)"
  CASE #b10001101: RESULTIS "z|x=z&y"
  CASE #b10001110: RESULTIS "x|(z=y)=z&y"
  CASE #b10001111: RESULTIS "x->z&y"
  CASE #b10001111: RESULTIS "~x|(y&z)"
  CASE #b10010000: RESULTIS "x&(y#~z)"
  CASE #b10010000: RESULTIS "x&(y=z)"
  CASE #b10010000: RESULTIS "x&(z=y)"
  CASE #b10010000: RESULTIS "x&(~y#z)"
  CASE #b10010000: RESULTIS "x&(~y=~z)"
  CASE #b10010001: RESULTIS "(y->x)&(z=y)"
  CASE #b10010010: RESULTIS "(z|x)&(y=z&x)"
  CASE #b10010011: RESULTIS "y=(x&z)"
  CASE #b10010011: RESULTIS "y=z&x"
  CASE #b10010011: RESULTIS "~y=(~x|~z)"
  CASE #b10010100: RESULTIS "(y|x)&(y#(z#x))"
  CASE #b10010101: RESULTIS "z=(x&y)"
  CASE #b10010101: RESULTIS "z=y&x"
  CASE #b10010101: RESULTIS "~z=(~x|~y)"
  CASE #b10010110: RESULTIS "x#(y=~z)"
  CASE #b10010110: RESULTIS "x#(~y=z)"
  CASE #b10010110: RESULTIS "x#y#z"
  CASE #b10010110: RESULTIS "x#~y#~z"
  CASE #b10010110: RESULTIS "x=(y#~z)"
  CASE #b10010110: RESULTIS "x=(y=z)"
  CASE #b10010110: RESULTIS "x=(~y#z)"
  CASE #b10010110: RESULTIS "x=(~y=~z)"
  CASE #b10010110: RESULTIS "y#(x=~z)"
  CASE #b10010110: RESULTIS "y#(z#x)"
  CASE #b10010110: RESULTIS "y#(~x=z)"
  CASE #b10010110: RESULTIS "y#x#z"
  CASE #b10010110: RESULTIS "y#~x#~z"
  CASE #b10010110: RESULTIS "y=(x#~z)"
  CASE #b10010110: RESULTIS "y=(x=z)"
  CASE #b10010110: RESULTIS "y=(~x#z)"
  CASE #b10010110: RESULTIS "y=(~x=~z)"
  CASE #b10010110: RESULTIS "z#(x=~y)"
  CASE #b10010110: RESULTIS "z#(~x=y)"
  CASE #b10010110: RESULTIS "z#x#y"
  CASE #b10010110: RESULTIS "z#~x#~y"
  CASE #b10010110: RESULTIS "z=(x#~y)"
  CASE #b10010110: RESULTIS "z=(x=y)"
  CASE #b10010110: RESULTIS "z=(~x#y)"
  CASE #b10010110: RESULTIS "z=(~x=~y)"
  CASE #b10010110: RESULTIS "~x#(y=z)"
  CASE #b10010110: RESULTIS "~x#(~y=~z)"
  CASE #b10010110: RESULTIS "~x#y#~z"
  CASE #b10010110: RESULTIS "~x#~y#z"
  CASE #b10010110: RESULTIS "~x=(y#z)"
  CASE #b10010110: RESULTIS "~x=(y=~z)"
  CASE #b10010110: RESULTIS "~x=(~y#~z)"
  CASE #b10010110: RESULTIS "~x=(~y=z)"
  CASE #b10010110: RESULTIS "~y#(x=z)"
  CASE #b10010110: RESULTIS "~y#(~x=~z)"
  CASE #b10010110: RESULTIS "~y#x#~z"
  CASE #b10010110: RESULTIS "~y#~x#z"
  CASE #b10010110: RESULTIS "~y=(x#z)"
  CASE #b10010110: RESULTIS "~y=(x=~z)"
  CASE #b10010110: RESULTIS "~y=(~x#~z)"
  CASE #b10010110: RESULTIS "~y=(~x=z)"
  CASE #b10010110: RESULTIS "~z#(x=y)"
  CASE #b10010110: RESULTIS "~z#(~x=~y)"
  CASE #b10010110: RESULTIS "~z#x#~y"
  CASE #b10010110: RESULTIS "~z#~x#y"
  CASE #b10010110: RESULTIS "~z=(x#y)"
  CASE #b10010110: RESULTIS "~z=(x=~y)"
  CASE #b10010110: RESULTIS "~z=(~x#~y)"
  CASE #b10010110: RESULTIS "~z=(~x=y)"
  CASE #b10010111: RESULTIS "z&y=(z|y)&x"
  CASE #b10011000: RESULTIS "(z|x)&(z=y)"
  CASE #b10011001: RESULTIS "y#~z"
  CASE #b10011001: RESULTIS "y=z"
  CASE #b10011001: RESULTIS "z=y"
  CASE #b10011001: RESULTIS "~y#z"
  CASE #b10011001: RESULTIS "~y=~z"
  CASE #b10011010: RESULTIS "x&~y#z"
  CASE #b10011010: RESULTIS "z=(~x|y)"
  CASE #b10011010: RESULTIS "~z=(x&~y)"
  CASE #b10011011: RESULTIS "(y|x)&z=y"
  CASE #b10011100: RESULTIS "x&~z#y"
  CASE #b10011100: RESULTIS "y=(~x|z)"
  CASE #b10011100: RESULTIS "~y=(x&~z)"
  CASE #b10011101: RESULTIS "z=y&(z|x)"
  CASE #b10011110: RESULTIS "x|z&y#(z#y)"
  CASE #b10011111: RESULTIS "x->z=y"
  CASE #b10011111: RESULTIS "~x|(y#~z)"
  CASE #b10011111: RESULTIS "~x|(y=z)"
  CASE #b10011111: RESULTIS "~x|(~y#z)"
  CASE #b10011111: RESULTIS "~x|(~y=~z)"
  CASE #b10100000: RESULTIS "x&z"
  CASE #b10100000: RESULTIS "z&x"
  CASE #b10100001: RESULTIS "(y->x)&(z=x)"
  CASE #b10100010: RESULTIS "(y->x)&z"
  CASE #b10100010: RESULTIS "z&(x|~y)"
  CASE #b10100011: RESULTIS "x|(z#y)=z"
  CASE #b10100100: RESULTIS "(z|y)&(z=x)"
  CASE #b10100101: RESULTIS "x#~z"
  CASE #b10100101: RESULTIS "x=z"
  CASE #b10100101: RESULTIS "z=x"
  CASE #b10100101: RESULTIS "~x#z"
  CASE #b10100101: RESULTIS "~x=~z"
  CASE #b10100110: RESULTIS "(y->x)=z"
  CASE #b10100110: RESULTIS "z=(x|~y)"
  CASE #b10100110: RESULTIS "~z=(~x&y)"
  CASE #b10100111: RESULTIS "(y|x)&z=x"
  CASE #b10101000: RESULTIS "(y|x)&z"
  CASE #b10101000: RESULTIS "z&(x|y)"
  CASE #b10101001: RESULTIS "y|x=z"
  CASE #b10101001: RESULTIS "z=(x|y)"
  CASE #b10101001: RESULTIS "~z=(~x&~y)"
  CASE #b10101010: RESULTIS "z"
  CASE #b10101010: RESULTIS "z"
  CASE #b10101011: RESULTIS "y|x->z"
  CASE #b10101011: RESULTIS "z|(~x&~y)"
  CASE #b10101100: RESULTIS "x|(z=y)=z"
  CASE #b10101101: RESULTIS "x|z&y=z"
  CASE #b10101110: RESULTIS "z|(~x&y)"
  CASE #b10101110: RESULTIS "z|~x&y"
  CASE #b10101111: RESULTIS "x->z"
  CASE #b10101111: RESULTIS "x->z"
  CASE #b10101111: RESULTIS "~x|z"
  CASE #b10101111: RESULTIS "~z->~x"
  CASE #b10110000: RESULTIS "x&(y->z)"
  CASE #b10110000: RESULTIS "x&(~y|z)"
  CASE #b10110001: RESULTIS "z|y=z&x"
  CASE #b10110010: RESULTIS "y|(z=x)=z&x"
  CASE #b10110011: RESULTIS "y->z&x"
  CASE #b10110011: RESULTIS "~y|(x&z)"
  CASE #b10110100: RESULTIS "x#y&~z"
  CASE #b10110100: RESULTIS "x=(~y|z)"
  CASE #b10110100: RESULTIS "~x=(y&~z)"
  CASE #b10110101: RESULTIS "z=(z|y)&x"
  CASE #b10110110: RESULTIS "y|z&x#(z#x)"
  CASE #b10110111: RESULTIS "y->z=x"
  CASE #b10110111: RESULTIS "~y|(x#~z)"
  CASE #b10110111: RESULTIS "~y|(x=z)"
  CASE #b10110111: RESULTIS "~y|(~x#z)"
  CASE #b10110111: RESULTIS "~y|(~x=~z)"
  CASE #b10111000: RESULTIS "y|(z=x)=z"
  CASE #b10111001: RESULTIS "y|z&x=z"
  CASE #b10111010: RESULTIS "x&~y|z"
  CASE #b10111010: RESULTIS "z|(x&~y)"
  CASE #b10111011: RESULTIS "y->z"
  CASE #b10111011: RESULTIS "y->z"
  CASE #b10111011: RESULTIS "~y|z"
  CASE #b10111011: RESULTIS "~z->~y"
  CASE #b10111100: RESULTIS "(y#x)|z&y"
  CASE #b10111101: RESULTIS "(y#x)|(z=y)"
  CASE #b10111110: RESULTIS "(y#x)|z"
  CASE #b10111110: RESULTIS "z|(x#y)"
  CASE #b10111110: RESULTIS "z|(x=~y)"
  CASE #b10111110: RESULTIS "z|(~x#~y)"
  CASE #b10111110: RESULTIS "z|(~x=y)"
  CASE #b10111111: RESULTIS "y&x->z"
  CASE #b10111111: RESULTIS "~x|~y|z"
  CASE #b11000000: RESULTIS "x&y"
  CASE #b11000000: RESULTIS "y&x"
  CASE #b11000001: RESULTIS "(z->y)&(y=x)"
  CASE #b11000010: RESULTIS "(z|y)&(y=x)"
  CASE #b11000011: RESULTIS "x#~y"
  CASE #b11000011: RESULTIS "x=y"
  CASE #b11000011: RESULTIS "y=x"
  CASE #b11000011: RESULTIS "~x#y"
  CASE #b11000011: RESULTIS "~x=~y"
  CASE #b11000100: RESULTIS "y&(x|~z)"
  CASE #b11000100: RESULTIS "y&(z->x)"
  CASE #b11000101: RESULTIS "x|(z#y)=y"
  CASE #b11000110: RESULTIS "y=(x|~z)"
  CASE #b11000110: RESULTIS "y=(z->x)"
  CASE #b11000110: RESULTIS "~y=(~x&z)"
  CASE #b11000111: RESULTIS "x=y&(z|x)"
  CASE #b11001000: RESULTIS "y&(x|z)"
  CASE #b11001000: RESULTIS "y&(z|x)"
  CASE #b11001001: RESULTIS "y=(x|z)"
  CASE #b11001001: RESULTIS "y=z|x"
  CASE #b11001001: RESULTIS "~y=(~x&~z)"
  CASE #b11001010: RESULTIS "x|(z=y)=y"
  CASE #b11001011: RESULTIS "x|z&y=y"
  CASE #b11001100: RESULTIS "y"
  CASE #b11001100: RESULTIS "y"
  CASE #b11001101: RESULTIS "y|(~x&~z)"
  CASE #b11001101: RESULTIS "z|x->y"
  CASE #b11001110: RESULTIS "y|(~x&z)"
  CASE #b11001110: RESULTIS "y|~x&z"
  CASE #b11001111: RESULTIS "x->y"
  CASE #b11001111: RESULTIS "x->y"
  CASE #b11001111: RESULTIS "~x|y"
  CASE #b11001111: RESULTIS "~y->~x"
  CASE #b11010000: RESULTIS "(z->y)&x"
  CASE #b11010000: RESULTIS "x&(y|~z)"
  CASE #b11010001: RESULTIS "y|(z#x)=x"
  CASE #b11010010: RESULTIS "(z->y)=x"
  CASE #b11010010: RESULTIS "x=(y|~z)"
  CASE #b11010010: RESULTIS "~x=(~y&z)"
  CASE #b11010011: RESULTIS "y=(z|y)&x"
  CASE #b11010100: RESULTIS "(y#x)|(z#x)#z"
  CASE #b11010101: RESULTIS "~z|(x&y)"
  CASE #b11010101: RESULTIS "~z|y&x"
  CASE #b11010110: RESULTIS "(y|x#z)|y&x"
  CASE #b11010111: RESULTIS "~z|(x#~y)"
  CASE #b11010111: RESULTIS "~z|(x=y)"
  CASE #b11010111: RESULTIS "~z|(y=x)"
  CASE #b11010111: RESULTIS "~z|(~x#y)"
  CASE #b11010111: RESULTIS "~z|(~x=~y)"
  CASE #b11011000: RESULTIS "y=z|(y=x)"
  CASE #b11011001: RESULTIS "(z=y)|y&x"
  CASE #b11011010: RESULTIS "(z#x)|z&y"
  CASE #b11011011: RESULTIS "(z#x)|(z=y)"
  CASE #b11011100: RESULTIS "x&~z|y"
  CASE #b11011100: RESULTIS "y|(x&~z)"
  CASE #b11011101: RESULTIS "y|~z"
  CASE #b11011101: RESULTIS "z->y"
  CASE #b11011101: RESULTIS "z->y"
  CASE #b11011101: RESULTIS "~y->~z"
  CASE #b11011110: RESULTIS "y|(x#z)"
  CASE #b11011110: RESULTIS "y|(x=~z)"
  CASE #b11011110: RESULTIS "y|(z#x)"
  CASE #b11011110: RESULTIS "y|(~x#~z)"
  CASE #b11011110: RESULTIS "y|(~x=z)"
  CASE #b11011111: RESULTIS "z&x->y"
  CASE #b11011111: RESULTIS "~x|y|~z"
  CASE #b11100000: RESULTIS "(z|y)&x"
  CASE #b11100000: RESULTIS "x&(y|z)"
  CASE #b11100001: RESULTIS "x=(y|z)"
  CASE #b11100001: RESULTIS "z|y=x"
  CASE #b11100001: RESULTIS "~x=(~y&~z)"
  CASE #b11100010: RESULTIS "y|(z=x)=x"
  CASE #b11100011: RESULTIS "y|z&x=x"
  CASE #b11100100: RESULTIS "y#(y#x)&z"
  CASE #b11100101: RESULTIS "(z=x)|y&x"
  CASE #b11100110: RESULTIS "(z#y)|z&x"
  CASE #b11100111: RESULTIS "(z#y)|(z=x)"
  CASE #b11101000: RESULTIS "(y|z&x)&(z|x)"
  CASE #b11101001: RESULTIS "y|z&x=z|x"
  CASE #b11101010: RESULTIS "z|(x&y)"
  CASE #b11101010: RESULTIS "z|y&x"
  CASE #b11101011: RESULTIS "z|(x#~y)"
  CASE #b11101011: RESULTIS "z|(x=y)"
  CASE #b11101011: RESULTIS "z|(y=x)"
  CASE #b11101011: RESULTIS "z|(~x#y)"
  CASE #b11101011: RESULTIS "z|(~x=~y)"
  CASE #b11101100: RESULTIS "y|(x&z)"
  CASE #b11101100: RESULTIS "y|z&x"
  CASE #b11101101: RESULTIS "y|(x#~z)"
  CASE #b11101101: RESULTIS "y|(x=z)"
  CASE #b11101101: RESULTIS "y|(z=x)"
  CASE #b11101101: RESULTIS "y|(~x#z)"
  CASE #b11101101: RESULTIS "y|(~x=~z)"
  CASE #b11101110: RESULTIS "y|z"
  CASE #b11101110: RESULTIS "z|y"
  CASE #b11101110: RESULTIS "~y->z"
  CASE #b11101110: RESULTIS "~z->y"
  CASE #b11101111: RESULTIS "x->z|y"
  CASE #b11101111: RESULTIS "~x|y|z"
  CASE #b11110000: RESULTIS "x"
  CASE #b11110000: RESULTIS "x"
  CASE #b11110001: RESULTIS "x|(~y&~z)"
  CASE #b11110001: RESULTIS "z|y->x"
  CASE #b11110010: RESULTIS "x|(~y&z)"
  CASE #b11110010: RESULTIS "x|~y&z"
  CASE #b11110011: RESULTIS "x|~y"
  CASE #b11110011: RESULTIS "y->x"
  CASE #b11110011: RESULTIS "y->x"
  CASE #b11110011: RESULTIS "~x->~y"
  CASE #b11110100: RESULTIS "x|(y&~z)"
  CASE #b11110100: RESULTIS "x|y&~z"
  CASE #b11110101: RESULTIS "x|~z"
  CASE #b11110101: RESULTIS "z->x"
  CASE #b11110101: RESULTIS "z->x"
  CASE #b11110101: RESULTIS "~x->~z"
  CASE #b11110110: RESULTIS "x|(y#z)"
  CASE #b11110110: RESULTIS "x|(y=~z)"
  CASE #b11110110: RESULTIS "x|(z#y)"
  CASE #b11110110: RESULTIS "x|(~y#~z)"
  CASE #b11110110: RESULTIS "x|(~y=z)"
  CASE #b11110111: RESULTIS "x|~y|~z"
  CASE #b11110111: RESULTIS "z&y->x"
  CASE #b11111000: RESULTIS "x|(y&z)"
  CASE #b11111000: RESULTIS "x|z&y"
  CASE #b11111001: RESULTIS "x|(y#~z)"
  CASE #b11111001: RESULTIS "x|(y=z)"
  CASE #b11111001: RESULTIS "x|(z=y)"
  CASE #b11111001: RESULTIS "x|(~y#z)"
  CASE #b11111001: RESULTIS "x|(~y=~z)"
  CASE #b11111010: RESULTIS "x|z"
  CASE #b11111010: RESULTIS "z|x"
  CASE #b11111010: RESULTIS "~x->z"
  CASE #b11111010: RESULTIS "~z->x"
  CASE #b11111011: RESULTIS "x|~y|z"
  CASE #b11111011: RESULTIS "y->z|x"
  CASE #b11111100: RESULTIS "x|y"
  CASE #b11111100: RESULTIS "y|x"
  CASE #b11111100: RESULTIS "~x->y"
  CASE #b11111100: RESULTIS "~y->x"
  CASE #b11111101: RESULTIS "x|y|~z"
  CASE #b11111101: RESULTIS "y|(z->x)"
  CASE #b11111110: RESULTIS "x|y|z"
  CASE #b11111110: RESULTIS "y|(z|x)"
  CASE #b11111111: RESULTIS "True"




  CASE         -1: RESULTIS "Void     "
}


MANIFEST {
  E_syntax=100; E_Space        // Exceptions
  E_FalseTermFound
  E_NoTerms

// Rows in the matrix representation of the propositional expression
// are of the form: [rel, x, y, z]
// where rel is a relation over three booleans
// and x, y and z are variable ids, some occuring in the expression
// while others are generated automatically. The ids are represented by
// integers: 0, 1, 2,...
// Id 0 is always false
// Id 1 is always true
// Id 2 is an unconstrained (don't care) value

// the other ids hold unknown boolean values

// Terms sometimes allow information about their variables to be
// deduced.  For example: [And, x, 1, 1] => x=1
//                        [Imp, 0, y, z] => y=1 and z=0
//                        [Imp, x, y, 0] => x=~y
//                        [Imp, 0, y, y] is inconsistent


// There are 37 possible operand patterns for the term [rel, x, y, z]
// taking into account the following conditions:
//   x=0  x=1  y=0  y=1  z=0  z=1  y=z  z=x  and  x=y

// These patterns have the following manifest names
// (Note that they are also relations)

P000=#b00000001; P001=#b00000010; P00z=#b00000011;
P010=#b00000100; P011=#b00001000; P01z=#b00001100;
P0y0=#b00000101; P0y1=#b00001010; P0yy=#b00001001; P0yz=#b00001111;
P100=#b00010000; P101=#b00100000; P10z=#b00110000;
P110=#b01000000; P111=#b10000000; P11z=#b11000000;
P1y0=#b01010000; P1y1=#b10100000; P1yy=#b10010000; P1yz=#b11110000;
Px00=#b00010001; Px01=#b00100010; Px0x=#b00100001; Px0z=#b00110011;
Px10=#b01000100; Px11=#b10001000; Px1x=#b10000100; Px1z=#b11001100;
Pxx0=#b01000001; Pxx1=#b10000010; Pxxx=#b10000001; Pxxz=#b11000011;
Pxy0=#b01010101; Pxy1=#b10101010; Pxyx=#b10100101; Pxyy=#b10011001;
Pxyz=#b11111111
}


LET patstr(pat) = VALOF SWITCHON pat INTO  // return string for pattern
{ DEFAULT:    RESULTIS "P???"
  CASE P000: RESULTIS "P000"
  CASE P001: RESULTIS "P001"
  CASE P00z: RESULTIS "P00z"
  CASE P010: RESULTIS "P010"
  CASE P011: RESULTIS "P011"
  CASE P01z: RESULTIS "P01z"
  CASE P0y0: RESULTIS "P0y0"
  CASE P0y1: RESULTIS "P0y1"
  CASE P0yy: RESULTIS "P0yy"
  CASE P0yz: RESULTIS "P0yz"
  CASE P100: RESULTIS "P100"
  CASE P101: RESULTIS "P101"
  CASE P10z: RESULTIS "P10z"
  CASE P110: RESULTIS "P110"
  CASE P111: RESULTIS "P111"
  CASE P11z: RESULTIS "P11z"
  CASE P1y0: RESULTIS "P1y0"
  CASE P1y1: RESULTIS "P1y1"
  CASE P1yy: RESULTIS "P1yy"
  CASE P1yz: RESULTIS "P1yz"
  CASE Px00: RESULTIS "Px00"
  CASE Px01: RESULTIS "Px01"
  CASE Px0x: RESULTIS "Px0x"
  CASE Px0z: RESULTIS "Px0z"
  CASE Px10: RESULTIS "Px10"
  CASE Px11: RESULTIS "Px11"
  CASE Px1x: RESULTIS "Px1x"
  CASE Px1z: RESULTIS "Px1z"
  CASE Pxx0: RESULTIS "Pxx0"
  CASE Pxx1: RESULTIS "Pxx1"
  CASE Pxxx: RESULTIS "Pxxx"
  CASE Pxxz: RESULTIS "Pxxz"
  CASE Pxy0: RESULTIS "Pxy0"
  CASE Pxy1: RESULTIS "Pxy1"
  CASE Pxyx: RESULTIS "Pxyx"
  CASE Pxyy: RESULTIS "Pxyy"
  CASE Pxyz: RESULTIS "Pxyz"
}


// pattern(rel, x, y, z) returns the operand pattern

LET pattern(x, y, z) = VALOF // Return pattern of operands
{ LET pat = #b11111111
  IF x=0 DO pat := pat & #b00001111
  IF x=1 DO pat := pat & #b11110000
  IF y=0 DO pat := pat & #b00110011
  IF y=1 DO pat := pat & #b11001100
  IF z=0 DO pat := pat & #b01010101
  IF z=1 DO pat := pat & #b10101010
  IF y=z DO pat := pat & #b10011001
  IF z=x DO pat := pat & #b10100101
  IF x=y DO pat := pat & #b11000011
//writef("pattern: %i5 %i5 %i5   %b8 %s*n", x, y, z, res, relstr(res))
  RESULTIS pat
}

// As mentioned above, information can sometimes be deduced from
// the operator of a term and the pattern of its arguments.
// For example: [And, x, 1, 1] => x=1
//              [Imp, 0, y, z] => y=1 and z=0
//              [Imp, x, y, 0] => x=~y
//              [Imp, 0, y, y] is inconsistent

// There are 12 possible mapping actions.


MANIFEST {  // For term: [rel, x, y, z]

  Ax0 = #b000000_000001  //  x -> 0
  Ax1 = #b000000_000010  //  x -> 1
  Ay0 = #b000000_000100  //  y -> 0
  Ay1 = #b000000_001000  //  y -> 1
  Az0 = #b000000_010000  //  z -> 0
  Az1 = #b000000_100000  //  z -> 1
  Aypz= #b000001_000000  //  y -> z
  Azpx= #b000010_000000  //  z -> x
  Axpy= #b000100_000000  //  x -> y
  Aynz= #b001000_000000  //  y -> ~z
  Aznx= #b010000_000000  //  z -> ~x
  Axny= #b100000_000000  //  x -> ~y
}

/*
LET actstr
: Ax0   => "Ax0  " : Ax1   => "Ax1  "
: Ay0   => "Ay0  " : Ay1   => "Ay1  "
: Az0   => "Az0  " : Az1   => "Az1  "
: Aypz  => "Aypz " : Azpx  => "Azpx " : Axpy  => "Axpy "
: Aynz  => "Aynz " : Aznx  => "Aznx " : Axny  => "Axny "
:       => "Aerr "
*/

STATIC {
// The following variables will hold byte vectors of length 256
// to map one 8-bit relation to another.

  notx=?      // Maps rel->rel' where [rel x y z] = [rel' ~x  y  z]
  noty=?      // Maps rel->rel' where [rel x y z] = [rel'  x ~y  z]
  notz=?      // Maps rel->rel' where [rel x y z] = [rel'  x  y ~z]
  swapyz=?    // Maps rel->rel' where [rel x y z] = [rel'  x  z  y]
  swapzx=?    // Maps rel->rel' where [rel x y z] = [rel'  z  y  x]
  swapxy=?    // Maps rel->rel' where [rel x y z] = [rel'  y  x  z]

  dontcarex=? // Maps rel->rel' where [rel x y z] = [rel'  0  y  z]
              //                when x occurs only in this term
  dontcarey=? // Maps rel->rel' where [rel x y z] = [rel'  x  0  z]
              //                when y occurs only in this term
  dontcarez=? // Maps rel->rel' where [rel x y z] = [rel'  x  y  0]
              //                when z occurs only in this term

  // The following is a vector of 32 bit words
  rel2act=?   // Maps rel to set of actions
}

LET close_tabs() BE
{ freevec(notx)
  freevec(noty)
  freevec(notz)
  freevec(swapyz)
  freevec(swapzx)
  freevec(swapxy)
  freevec(dontcarex)
  freevec(dontcarey)
  freevec(dontcarez)
  freevec(rel2act)
}

// These vectors are allocated and initialised by the following function

LET init_tabs() = VALOF
{ notx      := getvec(#b11111111/Bpw)
  noty      := getvec(#b11111111/Bpw)
  notz      := getvec(#b11111111/Bpw)
  swapyz    := getvec(#b11111111/Bpw)
  swapzx    := getvec(#b11111111/Bpw)
  swapxy    := getvec(#b11111111/Bpw)
  dontcarex := getvec(#b11111111/Bpw)
  dontcarey := getvec(#b11111111/Bpw)
  dontcarez := getvec(#b11111111/Bpw)
  rel2act   := getvec(#b11111111)

  UNLESS swapyz    & swapzx    & swapxy    &
         notx      & noty      & notz      &
         dontcarex & dontcarey & dontcarez &
         rel2act DO raise(E_Space)

  FOR w = #b00000000 TO #b11111111 DO
  { LET acts = 0

    notx%w   := (w & #b11110000)>>4 |  // abcdefgh -> efghabcd
                (w & #b00001111)<<4
    noty%w   := (w & #b11001100)>>2 |  // abcdefgh -> cdabghef
                (w & #b00110011)<<2
    notz%w   := (w & #b10101010)>>1 |  // abcdefgh -> badcfehg
                (w & #b01010101)<<1
    swapyz%w :=  w & #b10011001     |  // abcdefgh -> acbdegfh
                (w & #b01000100)>>1 |
                (w & #b00100010)<<1
    swapzx%w :=  w & #b10100101     |  // abcdefgh -> aecgbfdh
                (w & #b01010000)>>3 |
                (w & #b00001010)<<3
    swapxy%w :=  w & #b11000011     |  // abcdefgh -> abefcdgh
                (w & #b00110000)>>2 |
                (w & #b00001100)<<2

    dontcarex%w := (w>>4 | w) & #b00001111 // abcdefgh -> 0000abcd &
                                           //             0000efgh
    dontcarey%w := (w>>2 | w) & #b00110011 // abcdefgh -> 00ab00ef &
                                           //             00cd00gh
    dontcarez%w := (w>>2 | w) & #b01010101 // abcdefgh -> 0a0c0e0g &
                                           //             0b0d0f0h

    UNLESS w & #b11110000 DO acts := acts + Ax0
    UNLESS w & #b00001111 DO acts := acts + Ax1
    UNLESS w & #b11001100 DO acts := acts + Ay0
    UNLESS w & #b00110011 DO acts := acts + Ay1
    UNLESS w & #b10101010 DO acts := acts + Az0
    UNLESS w & #b01010101 DO acts := acts + Az1
    UNLESS w & #b01100110 | acts & (Ay0+Ay1) DO acts := acts + Aypz
    UNLESS w & #b01011010 | acts & (Ax0+Ax1) DO acts := acts + Azpx
    UNLESS w & #b00111100 | acts & (Ax0+Ax1) DO acts := acts + Axpy
    UNLESS w & #b10011001 | acts & (Ay0+Ay1) DO acts := acts + Aynz
    UNLESS w & #b10100101 | acts & (Ax0+Ax1) DO acts := acts + Aznx
    UNLESS w & #b11000011 | acts & (Ax0+Ax1) DO acts := acts + Axny

    rel2act!w := acts
  }

  IF debug<100 RETURN

  writef("*nTest tables*n*n")
  FOR i = 0 TO 255 DO
  { LET w = i                                 //    [w x y z] = [i x y z]
    writef("%b8 %s  ", w, relstr(w))          // ie [w x y z] = [i x y z]
    writef("%b8 %s  ", notx%w, relstr(notx%w))
    writef("%b8 %s  ", noty%w, relstr(noty%w))
    writef("%b8 %s*n", notz%w, relstr(notz%w))
    w := swapyz%i                             //    [w x z y] = [i x y z]
    writef("%b8 %s  ", w, relstr(w))          // ie [w x y z] = [i x z y]
    writef("%b8 %s  ", notx%w, relstr(notx%w))
    writef("%b8 %s  ", noty%w, relstr(noty%w))
    writef("%b8 %s*n", notz%w, relstr(notz%w))
    w := swapxy%i                             //    [w y x z] = [i x y z]
    writef("%b8 %s  ", w, relstr(w))          // ie [w x y z] = [i y x z]
    writef("%b8 %s  ", notx%w, relstr(notx%w))
    writef("%b8 %s  ", noty%w, relstr(noty%w))
    writef("%b8 %s*n", notz%w, relstr(notz%w))
    w := swapyz%(swapxy%i)                    //    [w y z x] = [i x y z]
    writef("%b8 %s  ", w, relstr(w))          // ie [w x y z] = [i z x y]
    writef("%b8 %s  ", notx%w, relstr(notx%w))
    writef("%b8 %s  ", noty%w, relstr(noty%w))
    writef("%b8 %s*n", notz%w, relstr(notz%w))
    w := swapxy%(swapyz%i)                    //    [w z x y] = [i x y z]
    writef("%b8 %s  ", w, relstr(w))          // ie [w x y z] = [i y z x]
    writef("%b8 %s  ", notx%w, relstr(notx%w))
    writef("%b8 %s  ", noty%w, relstr(noty%w))
    writef("%b8 %s*n", notz%w, relstr(notz%w))
    w := swapzx%i                             //    [w z y x] = [i x y z]
    writef("%b8 %s  ", w, relstr(w))          // ie [w x y z] = [i z y x]
    writef("%b8 %s  ", notx%w, relstr(notx%w))
    writef("%b8 %s  ", noty%w, relstr(noty%w))
    writef("%b8 %s*n", notz%w, relstr(notz%w))
    newline()
  }
}

// A term is represented by a 4-tuple: [rel, x, y, z]

// Aside: when the number of distinct variables becomes less than 256
// the tuple may one day be packed into a 32 bits: 8-8-8-8, to save
// space and improve processor cache performance.

// The 4-tuples are held in a vector of 4 word cells [rel, x, y, z]
// but later versions may use 5-tuples [rel, v3,v2,v1,v0] for 
// relational terms over 4 variable, or even 16-tuples for relations
// over 8 variables [r7,r6,r5,r4,r3,r2,r1,r0, v7,v6,v5,v4,v3,v2,v1,v0]

MANIFEST { // Term fields for the 4-tuple version [rel, x,y,z]
  Trel=0   // An 8-bit relation on variables x, y and z
  Tx       // The integer id of the first  argument
  Ty       // The integer id of the second argument
  Tz       // The integer id of the third  argument
  Tsize    // The size of a term
}

STATIC {
  curts=?     // The current termset
  term1=?     // Pointer to the first term in curts
  termp=?     // next free term position in the curts
  termt=?     // Pointer to the last element of the curts vector
  termcount=0 // Count of number of terms in curts
}
                  // Termset fields
MANIFEST {
  TsVm=0    // 0 or first varmap
  TsVmax    // largest variable id in use
  TsTerm1   // Pointer to the first term (on a 16 byte boundary)
  TsTermt   // Pointer to the last possible term position
  TsTn      // Actual number of terms in the set
  TsSortv   // Vector of term pointers for sorting, or zero
  TsSysSize
}

LET alloc_termset(tmax) = VALOF // Allocate a termset large enough to
                                // hold tmax terms.

{ LET tsupb = TsSysSize+15+Tsize*(tmax+1) // Leave room alignment space.
  LET ts    = getvec(tsupb)
  LET t = ?

  IF ts=0 DO raise(E_Space, "no space for termset vector*n")

  ts!TsVm    := 0  // No varmap
  ts!TsVmax  := 0  // Max variable number, when known

  t := @ts!TsSysSize
  WHILE (t&15)~=0 DO t := t+1 // Round up to next 16-byte (4-word) boundary.
  
  ts!TsTerm1 := t
  ts!TsTermt := @t!(Tsize*tmax)
  IF @ts!tsupb < @t!(Tsize*(tmax+1)) DO // Check that there is room
     bug("alloc_termset error")         // for tmax terms

  ts!TsTn    := 0           // No terms in the set yet
  ts!TsSortv := 0           // No sort vector
  RESULTIS ts
}

/*
LET mkcopy_termset(ts) = VALOF
  LET n = ts!TsTn
  LET nts = alloc_termset n // Allocate a termset of the right size
  LET p =  ts!TsTerm1
  LET q = nts!TsTerm1
  FOR i = 1 TO n MATCH (p, q)
  : [r,x,y,z,np], [:=r,:=x,:=y,:=z, nq] => p, q := @np, @nq
  .
  RETURN nts
*/

LET close_termset(ts) BE
{ IF ts!TsVm    DO freevec(ts!TsVm)
  IF ts!TsSortv DO freevec(ts!TsSortv)
  freevec(ts)
}


LET mkterm(rel, y, z) = VALOF
{ varn := varn + 2
  pushterm(rel, varn, y, z)
  RESULTIS varn
}

AND pushterm(rel, x, y, z) = VALOF
{ LET p = termp
  IF p>termt DO raise(E_Space, "Too many terms*n")

  p!0, p!1, p!2, p!3 := rel, x, y, z
writef("pushterm: "); prterm(p)
  termcount := termcount+1
  termp := termp+4
}

/*
// Variables such as x, y and z in terms [rel,x,y,z] are identified
// by positive integers. Variables may get renamed by such actions
// as: Azpx (set x=z) or Axny (set x=~y). The accumulated collection
// of mappings is held in the current mapping vector varmap.

// If varmap!x>=0 then x maps to variable varmap!x
// If varmap!x<0  then x maps to the complement of variable -varmap!x


AND compact_vars(ts) = VALOF
  LET vm   = ts!TsVm       // get the varmap vector, if allocated
  LET vmax = ts!TsVmax
  UNLESS vm DO vm := getvec vmax
  UNLESS vm raise(E_Space, "Can't allocate a varmap vector size %n*n", vmax)

  FOR i = 3 TO vmax DO vm!i := 0
  LET n = ts!TsTn
  LET p = ts!TsTerm1

  FOR i = 1 TO n MATCH p
  : [rel, x, y, z, np] => (vm!x)++  // Mark variables in use
                          (vm!y)++
                          (vm!z)++
                          p := @np
  .

  LET var = 3
  vm!0 := 0  // False
  vm!1 := 1  // true
  vm!2 := 2  // Don't care
  FOR i = 3 TO vmax IF vm!i TEST vm!i=1 THEN vm!i := 2     // Don't care
                                        ELSE vm!i := var++
  p := ts!TsTerm1

  FOR i = 1 TO n MATCH p    // Rename variables
  : [rel, x(:=vm!x), y(:=vm!y), z(:=vm!z), np] => p := @np
  .

  IF vm DO freevec(vm       // Free the old mapping vector

  ts!TsVm   := getvec var   // Allocate a new varmap
  ts!TsVmax := var

AND compact_terms(ts) = VALOF // remove void or duplicate terms

  mark_duplicates ts      // mark duplicates as void

  LET n = ts!TsTn         // Number of terms
  LET p = ts!TsTerm1      // Next term to look at
  LET k = 0               // Count of remaining terms
  LET q = p               // Next free term position

  FOR i = 1 TO n MATCH (p, q)
  : [ <0,x,y,z,np],                     ?  => p = @np // Skip void term

  : [rel,x,y,z,np], [:=rel,:=x,:=y,:=z,nq] => k++     // Copy term
                                              p, q := @np, @nq
  .
  ts!TsTn := k
  IF debug>3 & k<n DO { writef("Compacted to %n terms*n", k)
                          prterms ts
                        }
  UNLESS n raise(E_NoTerms


AND mark_duplicates(ts) = VALOF // Mark duplicates as void
//  writef "mark_duplicates*n"

  LET n = ts!TsTn
  LET k = 0            // Count of non void terms
  LET v = getvec n     // Allocate sort vector
  IF v=0 raise(E_Space

  IF ts!TsSortv DO freevec(ts!TsSortv)
  ts!TsSortv := v  // Save the sort vector in ts so that it can be freed

  LET p = ts!TsTerm1

  FOR i = 1 TO n DO    // Put non void terms in the sort vector
  { UNLESS !p<0 DO { canonterm p; v!++k := p }
    p := @p!Tsize
  }

//  prmapping ts
//  writef("Terms for sorting*n")
//  FOR i = 1 TO k DO prterm(v!i)
//  newline()

  sort(v, k, cmpfull)  // Sort the non void terms

  FOR i = 1 TO k-1 DO
  { LET t  = v!i
    LET t' = v!(i+1)
    IF t!Trel>0 MATCH (t, t') // Compare adjacent two terms
                : [rel,x,y,z], [=rel,=x,=y,=z] => rel := -1
                :                              => LOOP
  }

//  writef("Terms after marking duplicated*n")
//  FOR i = 1 TO k DO prterm(v!i)
  freevec(v  // Free the sort vector
*/

AND prterm(t) BE
  writef("%b8 %s %i5 %i5 %i5*n", t!0, t!1, t!2, t!3)

AND prterms(ts) BE
{ LET n = ts!TsTn     // The number of terms
  LET p = ts!TsTerm1

  writef("Terms:*n")

  FOR i = 1 TO n DO { IF !p>=0 DO { writef("%i5  ", i)
                                    prterm(p)
                                  }
                      p := @p!Tsize
                    }
  prmapping(ts)
}


AND prmapping(ts) BE
{ LET k = 0         // For layout
  LET vm = ts!TsVm
  writef("Mapping:")
  UNLESS vm DO { writef(" No mapping vector*n"); RETURN }
  FOR i = 0 TO ts!TsVmax UNLESS i = vm!i DO
  { UNLESS k REM 10 DO newline()
    k := k+1
    writef("  %n->%n", i, vm!i)
  }
  newline()
}

/*
LET check(ts) = VALOF // It may raise(E_FalseTermFound
                  //              E_NoTerms
                  //              E_Space
{ apply_simple_rules  ts
  apply_dilemma_rule1 ts
  apply_dilemma_rule2 ts
  apply_dilemma_rule3 ts

  RETURN "Unable to decide whether it is a tautology*n"
} HANDLE : E_FalseTermFound => "It is a tautology*n"
         : E_NoTerms        => "It is NOT a tautology*n"
         : E_Space          => "Ran out of space*n"
         .

LET apply_dilemma_rule1(ts) = VALOF
  writef "dilemma rule1 not implemented*n"

LET apply_dilemma_rule2(ts) = VALOF
  writef "dilemma rule2 not implemented*n"

LET apply_dilemma_rule3(ts) = VALOF
  writef "dilemma rule3 not implemented*n"

STATIC
  change  // Set to TRUE whenever the variable mapping changes

LET apply_simple_rules(ts) = VALOF
             // It may raise(E_FalseTermFound
             //              E_NoTerms
             //              E_Space

  IF debug>0 DO writef "*nApplying simple rules*n"

  compact_vars ts

  varmap := ts!TsVm
  FOR i = 0 TO ts!TsVmax DO varmap!i := i // null mapping

  IF debug>0 DO { writef "Initial terms are:*n"
                  prterms ts
                }

  // The root variable was set to 0, so if the conjunction
  // of terms can be satisfied, the given expression
  // can evaluate to false.

  change := FALSE

  { apply_unit_rules ts
    compact_terms ts
    IF debug>3 DO prterms ts

    apply_pair_rules ts
    compact_terms ts
    IF debug>3 DO prterms ts

  } REPEATWHILE change

LET mapterm([rel, x, y, z]) = VALOF // On entry, x, y and z >=0
                                // On return, x =0 or >2,
                                //            y =0 or >2
                                //        and z =0 or >2

  MATCH mapof x : t(<0) => rel := notx%rel
                           x   := -t
                : t     => x   :=  t
                .
  MATCH mapof y : t(<0) => rel := noty%rel
                           y   := -t
                : t     => y   :=  t
                .
  MATCH mapof z : t(<0) => rel := notz%rel
                           z   := -t
                : t     => z   :=  t
                .

  IF x=2 DO rel, x := dontcarex%rel, 0  // Check for don't-cares
  IF y=2 DO rel, y := dontcarey%rel, 0
  IF z=2 DO rel, z := dontcarez%rel, 0

  IF x=1 DO rel, x := notx%rel, 0       // Check for True
  IF y=1 DO rel, y := noty%rel, 0
  IF z=1 DO rel, z := notz%rel, 0


LET mapof(x) = VALOF
  LET t = varmap!x

  TEST t<0 THEN UNLESS t = varmap!(-t) DO { t := -mapof(-t)
                                            varmap!x := t
                                          }
           ELSE UNLESS t = varmap!t    DO { t := mapof t
                                            varmap!x := t
                                          }
  RETURN t

LET canonterm
:[ <0, :=0, :=0, :=0] => RETURN // A void term

:p[rel, x, y, z] =>

  mapterm p
  // x =0 or >2, y =0 or >2  and z =0 or >2

  // rel=abcdabcd => don't care x, so set x=0 in this term
  UNLESS (rel>>4 XOR rel) & #b00001111 DO { x := 0
                                            rel &:= #b00001111
                                          }
  // rel=ababcdcd => don't care y, so set y=0 in this term
  UNLESS (rel>>2 XOR rel) & #b00110011 DO { y := 0
                                            rel &:= #b00110011
                                          }
  // rel=aabbccdd => don't care z, so set z=0 in this term
  UNLESS (rel>>1 XOR rel) & #b01010101 DO { z := 0
                                            rel &:= #b01010101
                                          }
  // [rel 1 y z] => [rel' 0 y z]
  IF x=1 DO rel, x := notx%rel, 0
  // [rel x 1 z] => [rel' x 0 z]
  IF y=1 DO rel, y := noty%rel, 0
  // [rel x y 1] => [rel' x y 0]
  IF x=1 DO rel, x := notx%rel, 0

  // [rel x y y] => [rel' x y 0]          rel abcdefgh->aaddeehh
  IF 0<y=z DO { rel :=  rel & #b10011001     |
                       (rel & #b10001000)>>1 |
                       (rel & #b00010001)<<1
                z := 0
              }
  // [rel x y x] => [rel' x y 0]          rel abcdefgh->aaccffhh
  IF 0<x=z DO { rel :=  rel & #b10100101     |
                       (rel & #b10100000)>>1 |
                       (rel & #b00000101)<<1
                z := 0
              }
  // [rel x x z] => [rel' x 0 z]          rel abcdefgh->ababghgh
  IF 0<x=y DO { rel :=  rel & #b11000011     |
                       (rel & #b11000000)>>2 |
                       (rel & #b00000011)<<2
                y := 0
              }

//  IF rel=#b00000001 & x=y=z=0 DO { rel := -1; RETURN }

  // Finally, sort x y z

  IF x>y DO rel, x, y := swapxy%rel, y, x
  IF y>z DO { rel, y, z := swapyz%rel, z, y
              IF x>y DO rel, x, y := swapxy%rel, y, x
            }


LET apply_unit_rules(ts) = VALOF
                       // This function applied the mapping (in
                       // vector ts!TsVm) to the terms in ts, and
                       // applies the unit rule until convergence,
                       // leaving the final mapping in the varmap.
  varmap := ts!TsVm

  { change := FALSE // changes to TRUE if the variable mapping changes

    IF debug>0 DO writef("*n   Applying unit rules*n")

    IF debug>3 DO { prmapping ts
                    prterms ts
                    newline()
                  }

    LET n = ts!TsTn
    LET p = ts!TsTerm1

    FOR i = 1 TO n DO { UNLESS !p<0 DO apply_unit_rule p
                        p := @p!Tsize
                      }
  } REPEATWHILE change // repeat if the mapping has changed

LET apply_unit_rule
:  [ <0, x, y, z] => // A void term 

: p[rel, x, y, z] =>

    mapterm p

    IF rel<0 RETURN

    LET rel0 = rel

    LET pat = pattern(x, y, z)
    rel &:= pat

    IF rel=0 raise(E_FalseTermFound

    IF rel=pat DO
    { IF debug>2 DO 
        writef("unit:  %b8 %s %i5 %i5 %i5 Pat %s => satisfied*n",
                       rel, relstr rel, x, y, z, relstr pat)
      rel := -1
      RETURN
    }

    LET acts = rel2act!rel - rel2act!pat

    WHILE acts DO                // Iterate over the actions
    { LET act = acts & -acts
      acts -:= act
      IF debug>2 DO
        writef("unit:  %b8 %s %i5 %i5 %i5 Pat %s => %s*n",
                       rel0, relstr rel0, x, y, z, relstr pat, actstr act)

      rel, change := -1, TRUE // All action change varmap 
                              // and remove the term.
      MATCH act
      : Ax0  =>               varmap!x :=  0        // Set x=0
      : Ax1  =>               varmap!x :=  1        // Set x=1
      : Ay0  =>               varmap!y :=  0        // Set y=0
      : Ay1  =>               varmap!y :=  1        // Set y=1
      : Az0  =>               varmap!z :=  0        // Set z=0
      : Az1  =>               varmap!z :=  1        // Set z=1

      : Aypz => TEST y>z THEN varmap!y :=  z        // Set y=z
                         ELSE varmap!z :=  y        // Set z=y
      : Azpx => TEST z>x THEN varmap!z :=  x        // Set z=x
                         ELSE varmap!x :=  z        // Set x=z
      : Axpy => TEST x>y THEN varmap!x :=  y        // Set x=y
                         ELSE varmap!y :=  x        // Set z=x
      : Aynz => TEST y>z THEN varmap!y := -z        // Set y=~z
                         ELSE varmap!z := -y        // Set z=~y
      : Aznx => TEST z>x THEN varmap!z := -x        // Set z=~x
                         ELSE varmap!x := -z        // Set x=~z
      : Axny => TEST x>y THEN varmap!x := -y        // Set x=~y
                         ELSE varmap!y := -x        // Set y=~x

      : act  => bug("  Unknown action %12b*n", act)
      .
      //IF debug>2 DO prterms curts
    }




LET apply_pair_rules : ts =>

  IF debug>0 DO writes "*n   Applying pair rules*n"

  // Look for pairs of the form: [rel ,   x , y,  z ]
  //                             [rel',   x', y', z']
  // with z=z' and deduce whatever is possible.

  LET n = ts!TsTn
  LET k = 0

  LET v = getvec(3*n)  // Up to 3 variables per term
  UNLESS v raise(E_Space

  IF ts!TsSortv DO freevec(ts!TsSortv)
  ts!TsSortv := v  // Save the sort vector in ts so that it can be freed

  LET p = ts!TsTerm1 
  IF p & 15 DO bug "Alignment error*n" // Check p is on a 16 byte boundary

  varmap := ts!TsVm

  FOR i = 1 TO n DO
  { UNLESS !p<0 DO { mapterm p
                     canonterm p
                     IF p!Tx DO v!++k := @p!Tx
                     IF p!Ty DO v!++k := @p!Ty
                     IF p!Tz DO v!++k := @p!Tz
                   }
    p := @p!Tsize
  }

//  prmapping ts
//  writef("Terms for sorting*n")
//  FOR i = 1 TO k DO prterm(v!i & -16)
//  newline()
  sort(v, k, cmpval)

//  writef("Terms for pair search*n")
//  FOR i = 1 TO k DO prterm(v!i & -16)

  IF debug>3 DO
  { writef "Sorted vars:"
    FOR i = 1 TO k DO writef(" %n", !(v!i))
    newline()
  }

  FOR i = 0 TO k-1 DO
  { MATCH @v!i
    : [[x], p[y(>2)], [z]] => IF i>0 & x=y LOOP
                              IF i<k & y=z LOOP
                              LET t = p & -16
                              IF debug>2 DO
                              { writef("Var %i5 eliminated in: ", y)
                                prterm t
                              }
                              y := 2
                              mapterm t
                              change := TRUE
    :                      => LOOP
  }

  FOR i = 1 TO k DO
  { LET p = v!i & -16
    FOR j = i+1 TO k DO 
    { IF !p<0 BREAK         // Term p is has become void
      LET q = v!j & -16
      UNLESS pair_rule(p, q) BREAK // BREAK if terms p and q have
                                   // no variables in common.
    }      
  }

  freevec(v

LET pair_rule(p[rel, x, y, z], q[rel', x', y', z']) = VALOF

    // Find out how many variable are in common and pass the terms
    // to pair_rule1, pair_rule2 or pair_rule3 and return TRUE.
    // If there are no variables in common, return FALSE.

    IF p=q OR rel<0 OR rel'<0 RETURN TRUE

    UNLESS rel & rel' raise(E_FalseTermFound

    // x, y, and z are all distinct, unless zero.

    // The possible equalities are
    // z=z' z=y' z=x' y=z' y=y' y=x' x=z' x=y' x=x'
    UNTIL z=z' MATCH q
    : [?,  ?, =z,  ?] => rel', y', z' := swapyz%rel', z', y'; BREAK 
    : [?, =z,  ?,  ?] => rel', x', z' := swapzx%rel', z', x'; BREAK 
    : [?,  ?,  ?, =y] => rel,  y,  z  := swapyz%rel,  z,  y;  BREAK 
    : [?,  ?, =y,  ?] => rel,  y,  z  := swapyz%rel,  z,  y
                         rel', y', z' := swapyz%rel', z', y'; BREAK 
    : [?, =y,  ?,  ?] => rel,  y,  z  := swapyz%rel,  z,  y
                         rel', x', z' := swapzx%rel', z', x'; BREAK 
    : [?,  ?,  ?, =x] => rel,  x,  z  := swapzx%rel,  z,  x;  BREAK 
    : [?,  ?, =x,  ?] => rel,  x,  z  := swapzx%rel,  z,  x
                         rel', y', z' := swapyz%rel', z', y'; BREAK 
    : [?, =x,  ?,  ?] => rel,  x,  z  := swapzx%rel,  z,  x
                         rel', x', z' := swapzx%rel', z', x'; BREAK 
    :                 => RETURN FALSE // No variables in common 
    .
    // z=z'

    // The possible equalities are
    // y=y' y=x' x=y' x=x'
    UNTIL y=y' MATCH q
    : [?, =y,  ?,  ?] => rel', x', y' := swapxy%rel', y', x'; BREAK 
    : [?,  ?, =x,  ?] => rel,  x,  y  := swapxy%rel,  y,  x;  BREAK 
    : [?, =x,  ?,  ?] => rel,  x,  y  := swapxy%rel,  y,  x
                         rel', x', y' := swapxy%rel', y', x'; BREAK 
    :                 => pair_rule1(p, q) // Only one var in common 
                         RETURN TRUE
    .
    // y=y' and z=z'

    // The possible equalities are
    // x=x'
    TEST x=x' THEN pair_rule3(p, q) // All three vars in common 
              ELSE pair_rule2(p, q) // Only two vars in common 
    RETURN TRUE


LET pair_rule1(p[rel, x, y, z], q[rel', x', y', z']) = VALOF RETURN

LET pair_rule2(p[rel, x, y, z], q[rel', x', y', z']) = VALOF

    IF p=q OR rel<=0 OR rel'<=0  OR
        x=x'  OR   y~=y'  OR  z~=z' DO bug "Bug found in pair_rule2*n"


    IF debug>3 DO { writef("pair_rule2: "); prterm p
                    writef("      with: "); prterm q
                    newline()
                  }

    // rel = pppp_qqqq
    // a   = pppp_pppp_qqqq_qqqq
    LET a = #b0_0001_0001 * ((rel & #b1111_0000)<<4 |
                              rel & #b0000_1111)
    // rel' = rrrr_ssss
    // b    = rrrr_ssss_rrrr_ssss
    LET b = #b1_0000_0001 * rel'
    LET crel = a & b

    IF debug>3 DO writef("crel: %16b*n", crel)

    // All the information in the terms: [rel,  x,  y, z]
    //                                   [rel', x', y, z]
    // is now contained in:           [crel, x, x', y, z]

    // Let's see what this tells us...

    IF crel=0 raise(E_FalseTermFound // The term is unsatisfiable

    LET w = crel | crel>>4         // calculate new rel and rel'
    rel := w>>4 & #b11110000 | w&#b1111

    rel' := (crel>>8 | crel) & #b1111_1111

    UNLESS crel & #b0000_1111_1111_0000 DO // x must= x' ?
    { IF debug>2 DO { writef("pair_rule2: "); prterm p
                      writef("      with: "); prterm q
                      writes "gives: Axpx'*n"
                     }
      TEST x>x' THEN { varmap!x  := x'; mapterm p }
                ELSE { varmap!x' := x;  mapterm q }
      change := TRUE
      pair_rule3(p, q)  // Since now x = x'
    }

    UNLESS crel & #b1111_0000_0000_1111 DO // x must= ~x' ?
    { IF debug>2 DO { writef("pair_rule2: "); prterm p
                      writef("      with: "); prterm q
                      writes "gives: Axnx'*n"
                     }
      TEST x>x' THEN { varmap!x  := -x'; mapterm p }
                ELSE { varmap!x' := -x;  mapterm q }
      change := TRUE
      pair_rule3(p, q)  // Since now x = x'
    }

    apply_unit_rule p
    apply_unit_rule q


LET pair_rule3(p[rel, x, y, z], q[rel', x', y', z']) = VALOF

    IF p=q OR rel<=0 OR rel'<=0 OR
        x~=x' OR  y~=y'  OR z~=z' DO bug "Bug found in pair_rule3*n"

    IF debug>2 & rel' ~= rel&rel' DO
    { writef("pair_rule3: "); prterm p
      writef("      with: "); prterm q
    }

    rel' &:= rel

    IF debug>2 & rel' ~= rel&rel' DO
    {  writef("     gives: "); prterm q
    }

    rel := -1

    apply_unit_rule q



//********************* Sort Function ******************

STATIC cmpfn  // cmpfn(p, q)=TRUE iff term p < term q

LET cmpval([<z], [z]) = VALOF TRUE
           :           => FALSE

LET cmpfull(p[ r, x, y, z], q[r', x', y', z']) = VALOF
//  writef "Cmpfull: "; prterm p
//  writef "   with: "; prterm q
  IF z<z' RETURN TRUE
  IF z>z' RETURN FALSE
  IF y<y' RETURN TRUE
  IF y>y' RETURN FALSE
  IF x<x' RETURN TRUE
  IF x>x' RETURN FALSE
  IF r<r' RETURN TRUE
  IF r>r' RETURN FALSE
  RETURN TRUE

LET sort(v, n, f) = VALOF cmpfn := f
                      qsort(@v!1, @v!n)

LET qsort(l, r) = VALOF
  WHILE @l!8<r DO
  { LET midpt = ((l+r)/2) & -Bpw
    // Select a good(ish) median value.
    LET val   = middle(!l, !midpt, !r)
    LET p = partition(val, l, r)
    // Only use recursion on the smaller partition.
    TEST p>midpt THEN { qsort(p, r);     r := @p!-1 }
                 ELSE { qsort(l, @p!-1); l := p     }
   }
   FOR p = @l!1 TO r BY Bpw DO  // Now perform insertion sort.
     FOR q = @p!-1 TO l BY -Bpw DO
         TEST cmpfn(q!0,q!1) THEN BREAK
                             ELSE q!0, q!1 := q!1, q!0


LET middle(a, b, c) = VALOF cmpfn(a,b) -> cmpfn(b,c) -> b,
                                      cmpfn(a,c) -> c,
                                                    a,
                        cmpfn(b,c) -> cmpfn(a,c) -> a,
                                                    c,
                        b

LET partition(median, p, q) = VALOF
{  WHILE cmpfn(!p, median) DO p+++
   WHILE cmpfn(median, !q) DO q---
   IF p>=q RETURN p
   !p, !q := !q, !p
   p+++
   q---
} REPEAT

*/

//********************* Syntax Analyser ******************

// This converts the ASCII representation of a propositional
// expression into a set of terms, each of the form
//        [op, x, y, z]
// where x, y, and z are variable ids
// It returns the id of the root of the entire expression.

// 0 .. 1 -->  0 .. 1
// A .. Z -->  2, 4, 6, ..., 52
// ~x     -->  [NotY, t, x, 0]
// x & y  -->  [And,  t, x, y]
// x | y  -->  [Or,   t, x, y]
// x -> y -->  [Imp,  t, x, y]
// x = y  -->  [Eqv,  t, x, y]


LET rch() = VALOF
{ IF strp>strt RESULTIS 0
  ch := str%strp
  strp := strp+1
//writef("ch = %c*n", ch)
}

LET lex_init(s) BE
{ str, strp, strt := s, 1, s%0
  rch()
}

LET lex() BE
{ SWITCHON ch INTO

  { DEFAULT:   raise(E_syntax)

    CASE ' ':
    CASE '*n': rch(); lex(); RETURN

    CASE '0':
    CASE '1':  token, lexval := Id, ch-'0'  // 0->0 1->1
               rch()
               RETURN

    CASE 'A': CASE 'B': CASE 'C': CASE 'D': CASE 'E':
    CASE 'F': CASE 'G': CASE 'H': CASE 'I': CASE 'J':
    CASE 'K': CASE 'L': CASE 'M': CASE 'N': CASE 'O':
    CASE 'P': CASE 'Q': CASE 'R': CASE 'S': CASE 'T':
    CASE 'U': CASE 'V': CASE 'W': CASE 'X': CASE 'Y':
    CASE 'Z': token, lexval := Id, 2*(ch-'A')+4    // A->4 B->6 ...
              rch()
              RETURN
    CASE '(': token := Lparen; rch(); RETURN
    CASE ')': token := Rparen; rch(); RETURN
    CASE '~': token := NotY;   rch(); RETURN
    CASE '&': token := And;    rch(); RETURN
    CASE '|': token := Or;     rch(); RETURN
    CASE '=': token := Eqv;    rch(); RETURN

    CASE '-': rch()
              UNLESS ch='>' DO raise(E_syntax, "-> expected")
              rch()
              RETURN
    CASE 0:   token := Eof
              RETURN
  }
}

LET parse(str, ts) = VALOF
{ lex_init(str)
  varn  := 1       // Generated  ids are odd,  next available is 3
  lasteid := 20    // Expression ids are even, next available is 4
                   // Remember: 0 = False
                   //           1 = True
                   //           2 = Don't care, does not matter which
                   //           even>2 -- user variable
                   //           odd>1  -- system generated variable
  termp := ts!TsTerm1
  termt := ts!TsTermt
  termcount := 0

  pushterm(Eqv, 1, nexp(0), 0) // Parse the given expression
                              // test if it is FALSE

  IF varn<lasteid DO varn := lasteid

  IF ts!TsVm DO freevec(ts!TsVm)       // Free previous vm, if any
  ts!TsVm    := 0                      // No varmap vector
  ts!TsVmax  := varn                   // Maximum variable identifier used
  ts!TsTn    := termcount              // the number of terms
  IF ts!TsSortv DO freevec(ts!TsSortv) // Free previous sort vector, if any
  ts!TsSortv := 0                      // No sort vector yet
  curts := ts
}

AND prim() = VALOF
{ SWITCHON token INTO
  { DEFAULT:     raise(E_syntax, "Bad expression*n")

    CASE Id:     { LET a = lexval  // 0->0 1->1 A->4 B->6 C->8 ...
                   IF lasteid<a DO lasteid := a
                   lex()
                   RESULTIS a
                 }
    CASE Lparen: { LET a = nexp(0)
                   UNLESS token=Rparen DO raise(E_syntax, "')' missing*n")
                   lex()
                   RESULTIS a
                 }
    CASE NotY:   RESULTIS mkterm(NotY, nexp(3), 0)
  }
}

AND nexp(n) = VALOF
{ lex()
  RESULTIS exp(n)
}

AND exp(n) = VALOF
{ LET a = prim()

  { SWITCHON token INTO
    { DEFAULT:  RESULTIS a

      CASE And: IF n>=3 RESULTIS a
                a := mkterm(And, a, nexp(3))
                LOOP 
      CASE Or:  IF n>=2 RESULTIS a
                a := mkterm(Or, a, nexp(2))
                LOOP 
      CASE Imp: IF n>=1 RESULTIS a
                a := mkterm(Imp, a, nexp(1))
                LOOP 
      CASE Eqv: IF n>=1 RESULTIS a
                a := mkterm(Eqv, a, nexp(1))
                LOOP 
    }
  } REPEAT
}

//********************* Main Program **********************

LET try(e) = VALOF 
{ LET mess = ""
  writef("*nTesting: %s*n", e)

  parse(e, curts)  // Puts the terms representing expression e
                   // into the given term set, and updates its
                   // vmax field.

//  mess := check(curts)
//  compact_terms(curts)
  IF debug>0 DO prterms(curts)

  writef("-------- %s*n", mess)
}

// Propositional examples supplied by Larry Paulson 
// and modified by MR

LET start() = VALOF
{ LET argv = VEC 50
  LET sysout = output()
  LET out    = 0

  IF rdargs("D,TMAX,TO/K", argv, 50)=0 DO
  { writef("Bad arguments for STLMK*n")
    RESULTIS 20
  }

  debug := 0
  IF argv!0 DO debug := str2numb(argv!0) // Set the debugging level

  tmax := 100000
  IF argv!1 DO tmax := str2numb(argv!1) // Set max number of terms

  IF argv!2 DO { out := findoutput(argv!2)
                 IF out=0 DO
                 { writef("Bad arguments for STLMK*n")
                   RESULTIS 20
                 }
                 selectoutput(out)
               }

  curts := alloc_termset(tmax)
  init_tabs()

  writef("*nAssociative laws of & and |*n")
  try("(P & Q) & R  =  P & (Q & R)")
  try("(P | Q) | R  =  P | (Q | R)")

  writef("*nDistributive laws of & and |*n")
  try("(P & Q) | R  = (P | R) & (Q | R)")
  try("(P | Q) & R  = (P & R) | (Q & R)")

  writef("*nLaws involving implication*n")
  try("(P|Q -> R) = (P->R) & (Q->R)")
  try("(P & Q -> R) = (P-> (Q->R))")
  try("(P -> Q & R) = (P->Q)  &  (P->R)")

  writef("*nClassical theorems*n")
  try("P | Q  ->  P | ~P & Q")
  try("(P->Q)&( ~P->R)  ->  (P&Q | R)")
  try("P & Q | ~P & R =  (P->Q) & (~P->R)")
  try("(P->Q) | (P->R) = (P -> Q | R)")
  try("(P = Q) = (Q = P)")

  /* Sample problems from F.J. Pelletier,
     Seventy-Five Problems for Testing Automatic Theorem Provers,
     J. Automated Reasoning 2 (1986), 191-216.
  */

  writef("*nProblem 5*n")
  try("((P|Q)->(P|R)) -> (P|(Q->R))")

  writef("*nProblem 9*n")
  try("((P|Q) & ( ~P | Q) & (P | ~Q)) ->  ~( ~P | ~Q)")

  writef("*nProblem 12.  Dijkstra's law*n")
  try("((P  =  Q)  =  R)  ->  (P  =  (Q  =  R))")

  writef("*nProblem 17*n")
  try("(P & (Q->R) -> S) = (( ~P | Q | S) & ( ~P | ~R | S))")

  writef("*nFALSE GOALS*n")
  try("(P | Q -> R) = (P -> (Q->R))")
  try("(P->Q) = (Q ->  ~P)")
  try(" ~(P->Q) -> (Q = P)")
  try("((P->Q) -> Q)  ->  P")
  try("((P | Q) & (~P | Q) & (P | ~Q)) ->  ~(~P | Q)")

  writef("*nIndicates need for subsumption*n")
  try("((P & (Q = R)) = S) = (( ~P | Q | S) & ( ~P | ~R | S))")

// Prove that the circuit
//      -----
// X --| NOT |--> Y
//      -----
// is equivalent to:
//      -----       -----       -----
// A --| NOT |--B--| NOT |--C--| NOT |--> D
//      -----       -----       -----
  writef("*nProof of the correctness of a circuit*n")
  try("(Y=~X) & ((D=~C) & (C=~B) & (B=~A)) & (X=A)  ->  (Y=D)")

  writef("*nSuffix rule test*n")
  try("((X=A)->B) & (~(A=X)|B)")

  close_tabs()
  close_termset(curts)
  IF out DO endwrite()
  RESULTIS 0
}
