// (C) Copyright 1979 Tripos Research Group
//     University of Cambridge
//     Computer Laboratory

GET "libhdr"

GLOBAL
$(
absloc           : ug +  0 // Absolute section location counter
addrmode         : ug +  1 // Operand address mode
addrval          : ug +  2 // Operand address word value
ch               : ug +  3 // Last character read
exptype          : ug +  4 // Expression type
expval           : ug +  5 // Expression value
location         : ug +  6 // Current location counter
radix            : ug +  7 // Default radix for reading numbers
ws.size          : ug +  8 // Total work space allocated
relloc           : ug +  9 // Relocatable section location counter
warncount        : ug + 10 // Count of warnings issued
declsyswords     : ug + 11 // Sets up initial symbol table
symb             : ug + 12 // Pointer to symbol table entry
symbtype         : ug + 13 // Type of symbol
symbval          : ug + 14 // Value of symbol
tagv             : ug + 15 // Vector used for reading tags

absmin           : ug + 16
absmax           : ug + 17
absvec           : ug + 18
absrp            : ug + 19
absrvec          : ug + 20

relmin           : ug + 21
relmax           : ug + 22
relvec           : ug + 23
relrp            : ug + 24
relrvec          : ug + 25

minloc           : ug + 26
maxloc           : ug + 27
codevec          : ug + 28
relp             : ug + 29
relocvec         : ug + 30
locmode          : ug + 31

tagtable         : ug + 32

outbuf           : ug + 33
outbufp          : ug + 34
nerrs            : ug + 35
printres         : ug + 36
charpos          : ug + 37

ended            : ug + 38
pass1            : ug + 39
pass2            : ug + 40
ttused           : ug + 41
ilength          : ug + 42

valpntr          : ug + 43
typepntr         : ug + 44
listing          : ug + 45
listlev          : ug + 46
errcount         : ug + 47
locsave          : ug + 48
addrtype         : ug + 49

buildword        : ug + 50
dodir            : ug + 51
doinstr          : ug + 52
readnumber       : ug + 53
readtag          : ug + 54
skiplayout       : ug + 55
changemode       : ug + 56
readsymb         : ug + 57
readabsexp       : ug + 58
setloc           : ug + 59
complain         : ug + 60
readexp          : ug + 61
error            : ug + 62
rch              : ug + 63
unrch            : ug + 64
lookup           : ug + 65
putn             : ug + 66
printloc         : ug + 67
skipcomma        : ug + 68
putb             : ug + 69
skiprest         : ug + 70

outcode          : ug + 72
morewords        : ug + 73
morebytes        : ug + 74
gbyte            : ug + 75
tidy.up.and.stop : ug + 76
stvec.chain      : ug + 77 // Chain of symbol table blocks
current.stvec    : ug + 78 // Latest block allocated
stvec.offset     : ug + 79 // Offset in latest block

codestream       : ug + 81

sourcestream     : ug + 84
liststream       : ug + 85
progname         : ug + 86
putloc           : ug + 87
reportundefs     : ug + 88
gvec             : ug + 89
clearbits        : ug + 90
$)


MANIFEST
$(
// Symbol types
s.abs   =  1     // Tag with absolute value
s.dir   =  2     // Assembler directive
s.dot   =  3     // Location counter symbol
s.instr =  4     // Instruction mnemonic
s.new   =  5     // Newly created symbol table entry
s.none  =  6     // No symbol found before end of line
s.reg   =  7     // Register tag
s.rel   =  8     // Tag with relocatable value
s.labr  =  9     // Left angle bracket
s.number= 10     // Number (e.g. 123 or 'e )
s.monop = 11     // Monadic operator
s.pcent = 12     // Percent

// Operators

op.plus   = 1
op.minus  = 2
op.times  = 3
op.over   = 4
op.and    = 5
op.or     = 6

// Symbol table type field bits

stb.muldef = #400
stb.setnow = #200
stb.setever= #100
stb.temp   = #1000
stb.nrc    = #2000  // For non range-compatible
                    // instructions

// Instruction types

i.a     =  1     // Single address operand
i.aa    =  2     // Two address operands
i.bch   =  3     // Branch instruction
i.r     =  4     // Single register operand
i.rd    =  5     // Register, destination operands
i.ro    =  6     // Register, offset operands
i.sr    =  7     // Source, register operands
i.zop   =  8     // Zero operands
i.3n    =  9     // Operand is a 3 bit number
i.6n    = 10     // Operand is a 6 bit number
i.8n    = 11     // Operand is an 8 bit number

// Symbol table types for instructions.
// These are the type fields for entries for the
// instruction tags in the symbol table.

sti.a   =  (i.a   << 11) + s.instr
sti.aa  =  (i.aa  << 11) + s.instr
sti.bch =  (i.bch << 11) + s.instr
sti.r   =  (i.r   << 11) + s.instr
sti.rd  =  (i.rd  << 11) + s.instr
sti.ro  =  (i.ro  << 11) + s.instr
sti.sr  =  (i.sr  << 11) + s.instr
sti.zop =  (i.zop << 11) + s.instr
sti.3n  =  (i.3n  << 11) + s.instr
sti.6n  =  (i.6n  << 11) + s.instr
sti.8n  =  (i.8n  << 11) + s.instr

// Instruction types for instructions which are
// not available on all PDP-11s.

sti.az  = sti.a   | stb.nrc
sti.rz  = sti.r   | stb.nrc
sti.rdz = sti.rd  | stb.nrc
sti.roz = sti.ro  | stb.nrc
sti.srz = sti.sr  | stb.nrc
sti.zopz= sti.zop | stb.nrc
sti.3nz = sti.3n  | stb.nrc
sti.6nz = sti.6n  | stb.nrc

// Directive types

d.ascii =  1     // ASCII string
d.asciz =  2     // ASCII string ending with zero byte
d.asect =  3     // Start/resume absolute section
d.blkb  =  4     // Reserve n bytes
d.blkw  =  5     // Reserve n words
d.byte  =  6     // Assemble byte value(s)
d.csect =  7     // Start/resume relocatable section
d.end   =  8     // End of source
d.even  =  9     // Align to word boundary
d.limit = 10     // Assemble 2 words for prog limits
d.list  = 11     // Increment list count
d.nlist = 12     // Decrement list level
d.odd   = 13     // Align to odd byte boundary
d.psect = 14     // Start/resume relocatable section
d.radix = 15     // Set default radix for reading numbers
d.unimp = 17     // Unimplemented DOS MACRO directive
d.word  = 18     // Assemble word value(s)

// Expression types

e.abs   =  1     // Absolute expression
e.reg   =  2     // Register expression
e.rel   =  3     // Relocatable expression

// Object module section identifiers

t.hunk    = 1000
t.reloc   = 1001
t.end     = 1002
t.abshunk = 1003
t.absrel  = 1004

// Miscellaneous values

tagchars=  6     // Max. number of chars in a tag
tagsize = (tagchars + bytesperword - 1)/bytesperword
                 // Number of words needed for tag
tagbyteupb = (tagsize * bytesperword) - 1
                 // Last byte offset in TAGSIZE words
maxwol  =  3     // Max words printed on a line
maxbol  =  6     // Max bytes printed on a line

// Symbol table entry offsets

st.type =  tagsize + 1 // Symbol type, use bits, intruction type
st.value=  tagsize + 2 // Symbol value

// Basic constants

avsize       =    120/bytesperword
tagtablesize =     50
maxint       =  32767
initobp      =     38  // Initial value of OUTBUFP
outbuflim    =    120
stvecupb     =    200 // Unit in which symbol table blocks are allocated
$)

