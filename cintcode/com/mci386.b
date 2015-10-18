/*
This is the i386 version of the MC dynamic code generation package.

Martin Richards (c) March 2014

08/04/2008
Allowed MUL UMUL, DIV and UDIV to take an immediate integer operand
that is stores in the data area (with sharing).

#### Special Note ###########

The Cintcode memory used to be allocated in cintsys.c using
malloc(..). Under Windows this seems to create an area of memory that
has read, write and execute permission as needed by the MC
package. However, under some versions of Linux execution permission is
not set, causing mcCall to fail. On such systems cintsys now uses mmap
rather than malloc to allocate the Cintcode memory.

On the pentium instructions and data share the same cache and so the
MC package does not have to flush the cache before entering the
dynamically generated code. I believe the same is true of ARM
processors.

#### End of special note #######

mcb := mcInit(maxfno, dsize, csize)
  Create a dynamic code generation instance, to allow maxfno functions
  in data space of dsize words and code space of csize words. mcInit
  allocates a single block of memory (with read, write and execute
  permissions) large enough to hold the mc control block, the function
  dispatch table (to map function numbers to entry points), the data
  area for static data and the code area for instructions. It also
  allocates and initialises space to deal with labels and forward
  references. This space expands as needed during codegeneration and
  is releases when codegeneration is completed (by the call
  mcF(mc_end)).

mcSelect(mcb)
  Select the specified dynamic code generation instance.

mcCall(fno,x,y,z) // Call the function with number fno with three
                  // arguments x, y and z.
mcClose()
  Close down the current dynamic code generation instance freeing all
  its workspace.

mcPRF(format, reg)
  This calls the C function printf with the given format string and an
argument holding the current value of the specified MC register.  The
condition code and all the registers are preserved. The format is a
BCPL string which is converted to a C string and packed in the data
area for use by printf. An unrecognised register is treated as MC
register A.

mcNextlab()
  This returns the next available label.

mcComment(format, a, b,..., k)
  Write a message using writef if the least significant bit of
mcDebug is a one.

res := mcDatap()
res := mcCodep()
  Return the current positions in the data and code areas,
  respectively.
*/

SECTION "mci386"

GET "libhdr"
GET "mc.h"

MANIFEST {
// i386 register codes.

  Eax = 0 // %eax     A
  Ecx = 1 // %ecx     C
  Edx = 2 // %edx     D
  Ebx = 3 // %ebx     B
  Esp = 4 // %esp
  Ebp = 5 // %ebp
  Esi = 6 // %esi     E
  Edi = 7 // %edi     F

/*
The machine independent codegeneration functions are declared in mc.h
together with the machine operation mnemonics and directives.

The machine dependent low level (i386) code is compiled using ia
codegeneration functions such as iaRK, iaRR etc. The letters following 
ia indicate the types of the arguments.

F     No operands
K     An integer
R     An i386 register, eg Eax, Ebx,...
A     An argument of the current function
V     A local variable of the current function.
G     A BCPL global variable.
M     A BCPL pointer into Cintcode memory.
D     A memory reference with absolute address.
DX    A memory reference with offset and index register.
DXs   A memory reference with offset and scaled index register.
DXsB  A memory reference with offset, scaled index and base registers.
S     A label reference assuming an 8-bit operand is sufficient.
L     A label reference assuming an 8-bit operand is not sufficient.
*/

// i386 machine operations (all 32-bit unless otherwise specified).


  ia_addl=1 //  RK RR RL RM RDX RDXs RDXsB mRL mRM mRDX1 mRDXs mRDXsB
  ia_addcl  //  RK RR RL RM RDX RDXs RDXsB mRL mRM mRDX1 mRDXs mRDXsB
  ia_andl   //  RK RR RL RM RDX RDXs RDXsB mRL mRM mRDX1 mRDXs mRDXsB
  ia_call
  ia_cdq
  ia_cmpl   //  RK RR RL RM RDX RDXs RDXsB mRL mRM mRDX1 mRDXs mRDXsB
  ia_decl   //     RR RL RM RDX RDXs RDXsB
  ia_divl   //  K  R  L  M  D DX  DXs  DXsB
  ia_idivl  //  K  R  L  M  D DX  DXs  DXsB
  ia_imull  //  K  R  L  M  D DX  DXs  DXsB
  ia_incl   //     RR RL RM RDX RDXs RDXsB

  ia_je     //  J           set ls byte to 0 or 1
  ia_jne    //  J           set ls byte to 0 or 1
  ia_jl     //  J           set ls byte to 0 or 1
  ia_jle    //  J           set ls byte to 0 or 1
  ia_jg     //  J           set ls byte to 0 or 1
  ia_jge    //  J           set ls byte to 0 or 1
  ia_ja     //  J           set ls byte to 0 or 1
  ia_jae    //  J           set ls byte to 0 or 1
  ia_jb     //  J           set ls byte to 0 or 1
  ia_jbe    //  J           set ls byte to 0 or 1


  ia_jmp    //  J           eg: iaJL(ia_jmp, 32, TRUE)
  ia_leal
  ia_movb   //  RK RR RL RM RDX RDXs RDXsB mRL mRM mRDX1 mRDXs mRDXsB
  ia_movl   //  RK RR RL RM RDX RDXs RDXsB mRL mRM mRDX1 mRDXs mRDXsB
  ia_movw   //  RK RR RL RM RDX RDXs RDXsB mRL mRM mRDX1 mRDXs mRDXsB
  ia_movsbl //  RK RR RL RM RDX RDXs RDXsB mRL mRM mRDX1 mRDXs mRDXsB
  ia_movswl //  RK RR RL RM RDX RDXs RDXsB mRL mRM mRDX1 mRDXs mRDXsB
  ia_movzbl //  RK RR RL RM RDX RDXs RDXsB mRL mRM mRDX1 mRDXs mRDXsB
  ia_movzwl //  RK RR RL RM RDX RDXs RDXsB mRL mRM mRDX1 mRDXs mRDXsB
  ia_mull   //  K  R  L  M  D DX  DXs  DXsB
  ia_negl   //  K  R  L  M  D DX  DXs  DXsB
  ia_nop    //  F
  ia_notl   //  RK RR RL RM RDX RDXs RDXsB
  ia_orl    //  RK RR RL RM RDX RDXs RDXsB mRL mRM mRDX1 mRDXs mRDXsB
  ia_popl   //     RR RL RM RDX RDXs RDXsB
  ia_popal  //   F
  ia_popfl  //   F
  ia_pushl  //   K  R  L  M  DX  DXs  DXsB
  ia_pushal //   F
  ia_pushfl //   F
  ia_ret    //   F  K
  ia_shll
  ia_shrl

  ia_sete   //  R
  ia_setne  //  R
  ia_setl   //  R
  ia_setle  //  R
  ia_setg   //  R
  ia_setge  //  R
  ia_seta   //  R
  ia_setae  //  R
  ia_setb   //  R
  ia_setbe  //  R

  ia_shld   //  KRR KRL KRM KRDX KRDXs KRDXsB    double shift by k
            //   RR  RL  RM  RDX  RDXs  RDXsB    double shift by CL
  ia_shrd   //  KRR KRL KRM KRDX KRDXs KRDXsB    double shift by k
            //   RR  RL  RM  RDX  RDXs  RDXsB    double shift by CL
  ia_sbbl   //  RK RR RL RM RDX RDXs RDXsB mRL mRM mRDX1 mRDXs mRDXsB
  ia_subl   //  RK RR RL RM RDX RDXs RDXsB mRL mRM mRDX1 mRDXs mRDXsB
  ia_xchgl  //     RR RL RM RDX RDXs RDXsB
  ia_xorl   //  RK RR RL RM RDX RDXs RDXsB mRL mRM mRDX1 mRDXs mRDXsB

  // Directives
  ia_lab    // L
  ia_dlab   // L
  ia_datab  // K
  ia_datak  // K
  ia_datal  // L
  ia_datac  // K
  ia_alignc // K
  ia_alignd // K
  ia_entry  // KKK
  ia_endfn  // F
  ia_end    // F
}

GLOBAL {
  mod00:900 // Generate a Mod R/M byte of code: mm_rop_rrr
  mod01     // eg mod10(reg_op, r_m) 
  mod10
  mod11
  modmm     // eg modmm(mm, reg_op, r_m)

  sib00     // Generate a SIB byte of code:     ss_iii_bbb
  sib01     // eg sib01(index, base)
  sib10
  sib11
  sibss     // eg sibss(scale, index, base) where scale = 1,2,4 or 8

  get1
  put1
  put4


  csize
  dsize 

  mcupb     // Upperbound of mc
  mcblock   // The getvec block of store to the mc instance
  mcbase    // is mcblock rounded up to a double word boundary

  maxfno    // The largest function number allowed
  fnv       // Base of the fns vector -- points into mc
  currfno   // The current function number or -1
  maxarg    // The number arguments the current function has
  maxvar    // The number local variables the current function has.
            // It is the upb of frefv.

  datab     // Byte subscript of first byte of data
  datap     // Byte subscript of next byte of data
  datat     // Byte subscript of end of data space

  codeb     // Byte subscript of first byte of code (=datat)
  codep     // Byte subscript of next byte of code
  codet     // Byte subscript of end of code space

  labv      // Label vector -- labv!n=0 if Ln unset
  labvupb   // Upper bound of labv (and refv)
  labno     // Latest label allocated

  blocklist // List of blocks of space to hold 2-tuples
            // blocklist=0 or points to the next block.
            // Blocks are linked through the zeroth elements.
  freelist  // List of free 2-tuples.

  klist     // List of positions in the data area holding
            // read only constants used by MUL, UMUL, DIV and UDIV.
            // Each node in klist -> [next, datapos].

  refv      // Vector of forward references to data or code labels.
  frefv     // Vector of forward references to functions.

  // Forward reference 2-tuples are used for both label and function
  // references. As soon as a label or function entry is set, its
  // forward reference list is processed and the 2-tuples returned to
  // the freelist.

  // A typical 2-tuple is [next, x] where next is zero or points to
  // the next 2-tuple and x identifies the location and type of the
  // forward reference. If x is negative the reference is short (byte 
  // sized) otherwise it is long (32 bits in length). ABS x (=addr, say)
  // is the subscript (of mc) pointing to the byte just after the
  // reference byte or word. 

  mk2      // eg: refv!n := mk2(refv!n, x)
  setrefs  // eg: setrefs(refv!n, val); refv!n := 0
           // This is called when a label or function entry point
           // is set. It deals with its outstanding forward refs.

// Auxiliary MC functions

  mcDebug   // Holds the current debugging level

  db1wrf    // Calls writef if mcDebug>=1, tracing mc ops.
  db2wrf    // Calls writef if mcDebug>=2, tracing ia ops.
  db3wrf    // Calls writef if mcDebug>=3. tracing compiled bytes.
  db3nl     // Calls newline if mcDebug>=3

  iaC1      // Generate 1 byte of code
  iaC2      // Generate 2 bytes of code
  iaC3      // Generate 3 bytes of code
  iaC4      // Generate 4 bytes of code// Default initialise MC environment.

  iaD1      // Generate 1 byte of data
  iaD2      // Generate 2 bytes of data
  iaD3      // Generate 3 bytes of data
  iaD4      // Generate 4 bytes of data

// Operations with one or no operands
  iaF       // op                    eg: nop
  iaK       // op k                  eg: mul $10
  iaR       // op r                  eg: negl %ebx
  iaL       // op <data Ln>          eg: negl L32
  iaD       // op D                  eg: negl 1234
  iaDX      // op DX                 eg: negl 12(%ebx)
  iaDXs     // op DXs                eg: negl 12(,%ebx,4)
  iaDXsB    // op DXsB               eg: negl 12(%eax,%ebx,4)

//Dyadic operations with register as target
  iaRK      // r op:= k              eg: addl k,r
  iaRR      // r op:= s              eg: addl s,r
  iaRL      // r op:= <data Ln>      eg: addl Ln,%ebx
  iaRD      // r op:= <addr a>       eg: addl 1234,%ebx
  iaRDX     // r op:= DX             eg: addl 12(%ebx),%ebx
  iaRDXs    // r op:= DXs            eg: addl 12(,%ebx,4),%ebx
  iaRDXsB   // r op:= DXsB           eg: addl 12(%eax,%ebx,4),%ebx

// Dyadic operations with memory as target
  iaLR      // <data Ln> op:= r      eg: addl %ebx,Ln
  iaDR      // <addr a> op:= r       eg: addl %ebx,1234
  iaDXR     // DX   op:= r           eg: addl %edx,12(%ebp)
  iaDXsR    // DXs  op:= r           eg: addl %edx,12(,%ebp,4)
  iaDXsBR   // DXsB op:= r           eg: addl %edx,12(%ebx,%ebp,4)

  iaLK      // <data Ln> op:= k      eg: addl $45,Ln
  iaDK      // <addr a> op:= k       eg: addl $45,1234
  iaDXK     // DX   op:= k           eg: addl $45,12(%ebp)
  iaDXsK    // DXs  op:= k           eg: addl $45,12(,%ebp,4)
  iaDXsBK   // DXsB op:= k           eg: addl $45,12(%ebx,%ebp,4)

// Jump operations
  iaJL      // op L                  eg: jmp L32
  iaJR      // op L                  eg: jmp *%eax

  mcr2iar
  iarname
  iarname16
  iarname8
  iarname8h
  mcrname

/*  Low level byte generation functions

  ia_j
  ia_fno
  ia_f
  ia_fnr
  ia_fnrk1
  ia_fnrk4
  ia_fk1
  ia_fk4

  ia_fd
  ia_fdx
  ia_fdxs
  ia_fdxsb

  ia_fdr
  ia_fdxr
  ia_fdxsr
  ia_fdxsbr

  ia_fdk1
  ia_fdxk1
  ia_fdxsk1
  ia_fdxsbk1

  ia_fdk4
  ia_fdxk4
  ia_fdxsk4
  ia_fdxsbk4

  ia_fnk1
  ia_fnk4
  ia_fnr
  ia_fnrk1
  ia_fnrk4

  ia_fnd
  ia_fndx
  ia_fndxs
  ia_fndxsb

  ia_fndr
  ia_fndxr
  ia_fndxsr
  ia_fndxsbr

  ia_fndk1
  ia_fndxk1
  ia_fndxsk1
  ia_fndxsbk1

  ia_fndk4
  ia_fndxk4
  ia_fndxsk4
  ia_fndxsbk4
*/
}


LET mcInit(maxfno, dsize, csize) = VALOF
{ // Create an MC instance and return its control block.
  // Return 0 on failure

  // First allocate the workspace and vectors

  LET mcupb = 32 +            // For the control block
              maxfno + 1 +    // for the dispatch table -- 0 to maxfn
              dsize  +        // for the static data
              csize +         // for the code
              2               // for possible round ups (mcblock and datab)
  LET mcblock = getvec(mcupb) // Allocate space for the MC control block
                              // dispatch table, data and code.

  LET frefv = getvec(maxfno)  // Function forard ref lists

  UNLESS mcblock & frefv DO
  { writef("More store needed*n")
    abort(1000)
    GOTO fin
  }

  // Clear all the space
  FOR i = 0 TO mcupb DO mcblock!i := 0

  // Check that the Cintcode memory is double word aligned
  UNLESS ((rootnode!rtn_mc0) & 7) = 0 DO
  { writef("Error: The Cintcode memory is not double word aligned*n")
    GOTO fin
  }

  // mcbase is mcblock rounded up to be double word aligned.
  mcbase := mcblock
  UNLESS (mcbase & 1) = 0 DO mcbase := mcbase+1

  // Initialise the MC instance

  fnv := mcbase + 32                   // The function dispatch table

  datab := (32+maxfno+1)*bytesperword  // (byte subscript of mcbase)
  datab := (datab+7) & -8              // Round up to double word alignment
  datap := datab                       // Position of next data byte
  datat := datab + dsize*bytesperword  // Limit of data space

  codeb := datat                       // Base of the code space
  codep := codeb                       // Position of next code byte
  codet := codeb + csize*bytesperword  // Limit of code space

  klist := 0                           // read only data constants

  FOR n = 0 TO maxfno  DO fnv!n,  frefv!n := 0, 0

//writef("*nmcupb=%n, mcblock=%n, mbase=%n, frefv=%n*n",
//        mcupb, mcblock, mcbase, frefv)
//writef("fnv=%n, datab=%n, codeb=%n, codet=%n*n",
//        fnv, datab, codeb, codet)
//abort(1000)

  // Save the MC state in the control block
  mcbase! 0 := mcupb  // Upb of the mc space
  mcbase! 1 := maxfno // The largest allowable function number
                      // It is the upb of fnv and frefv
  mcbase! 2 := dsize  // Size of the data area in words
  mcbase! 3 := csize  // Size of the code area in words
  mcbase! 4 := fnv    // The function dispatch table holding entry addresses
  mcbase! 5 := -1     // Current upb of labv and refv
  mcbase! 6 := 0      // Label vector
  mcbase! 7 := 0      // Label forward reference lists
  mcbase! 8 := frefv  // Function forward reference lists
  mcbase! 9 := datab  // Base of data bytes (double word aligned)
  mcbase!10 := datap  // Position of next data byte
  mcbase!11 := datat  // End of data bytes (=codep)
  mcbase!12 := codeb  // Base of code bytes
  mcbase!13 := codep  // Position of next code byte
  mcbase!14 := codet  // End of code bytes
  mcbase!15 := 0      // The current function number
  mcbase!16 := maxarg // The number of arguments expected for current function
  mcbase!17 := maxvar // The number of local variables for current function
  mcbase!18 := 0      // Latest label allocated
  mcbase!19 := 0      // The current debugging level
  mcbase!20 := 0      // List of allocated blocks
  mcbase!21 := 0      // List of free 2-tuples (within the allocated blocks)
  mcbase!22 := mcblock// Unrounded mcbase
  mcbase!23 := klist  // read only data constants

  // Successful return from mcInit(...)
  RESULTIS mcbase

fin:
abort(1000)
  IF frefv   DO freevec(frefv)
  IF mcblock DO freevec(mcblock)
  RESULTIS 0
}

AND mcSelect(mcb) BE
{ // Select an MC instance

  // First save the current instance, if any.
  IF mc DO
  {  // Save the MC state in the control block
    mc! 0 := mcupb      // upb of the mc space
    mc! 1 := maxfno     // The largest allowable function number
    mc! 2 := dsize      // size of the data area in words
    mc! 3 := csize      // size of the code area in words
    mc! 4 := fnv        // vector of 8-bit relative refs // function dispatch table
    mc! 5 := labvupb    // upb of labv
    mc! 6 := labv       // Label vector
    mc! 7 := refv       // label forward refs
    mc! 8 := frefv      // function forward refs
    mc! 9 := datab      // Base of data bytes
    mc!10 := datap      // Pos of next data byte
    mc!11 := datat      // End of data bytes
    mc!12 := codeb      // base of code bytes
    mc!13 := codep      // position of next code byte
    mc!14 := codet      // End of code bytes (=datab)
    mc!15 := currfno    // The current function number
    mc!16 := maxarg     // The number of arguments expected
    mc!17 := maxvar     // The number of local variables
    mc!18 := labno      // The largest user label used
    mc!19 := mcDebug    // The current debugging level
    mc!20 := blocklist  // List of allocated blocks
    mc!21 := freelist   // List of free 2-tuples
    mc!22 := mcblock    // Unrounded mcbase
    mc!23 := klist      // read only data constants
  }
  // Now extract the state of the new MC instance
  IF mcb DO
  { mc       := mcb
    mcupb    := mc! 0  // upb of mc
    maxfno   := mc! 1  // The largest allowable function number
    dsize    := mc! 2  // size of the data area in words
    csize    := mc! 3  // size of the code area in words
    fnv      := mc! 4  // vector of 8-bit relative refs // function dispatch table
    labvupb  := mc! 5  // upb of labv
    labv     := mc! 6  // Label vector
    refv     := mc! 7  // upb of ref32v
    frefv    := mc! 8  // vector of 32-bit relative refs
    datab    := mc! 9  // Base of data bytes
    datap    := mc!10  // Pos of next data byte
    datat    := mc!11  // End of data bytes
    codeb    := mc!12  // base of code bytes
    codep    := mc!13  // position of next code byte
    codet    := mc!14  // End of code bytes (=datab)
    currfno  := mc!15  // The current function number
    maxarg   := mc!16  // The number of arguments expected
    maxvar   := mc!17  // The number of local variables
    labno    := mc!18  // Latest label allocated
    mcDebug  := mc!19  // The current debugging level
    blocklist:= mc!20  // List of allocated blocks
    freelist := mc!21  // List of free 2-tuples
    mcblock  := mc!22  // Unrounded mcbase 
    klist    := mc!23  // read only data constants
 }
//writef("2: mc=%n labv=%n*n", mc, labv)


//writef("mcSelect: labvupb=%n labv=%n*n", labvupb, labv)
}

// Call the function specified by fno.

LET mcCall(fno, a, b, c) = VALOF
{
//sawritef("mcCall(%n, %n, %n, %n): mc=%n %n!%n = %n*n",
//          fno, a, b, c, mc, fnv, fno, fnv!fno)
  RESULTIS sys(Sys_callnative,
               mc + fnv!fno/bytesperword, // entry point for function fno
               a, b, c
              )
}

AND mcClose() BE IF mc DO
{
  //writef("Closing mc=%n*n", mc)

  IF mc DO
  { //writef("Freeing mcblock %n*n", mcblock)
//abort(1000)
    freevec(mcblock)
    mc := 0
  }

  WHILE blocklist DO
  { LET next = !blocklist
    //writef("Freeing block %n*n", blocklist)
    freevec(blocklist)
    blocklist := next
  }

  IF labv DO
  { //writef("Freeing labv %n*n", labv)
    freevec(labv)
    labv := 0
  }
  IF refv DO
  { //writef("Freeing refv %n*n", refv)
    freevec(refv)
    refv := 0
  }
  IF frefv DO
  { //writef("Freeing frefv %n*n", frefv)
    freevec(frefv)
    frefv := 0
  }
}

AND mcPRF(mess, reg) BE
{ LET r = VALOF SWITCHON reg INTO
          { DEFAULT:
              RESULTIS Eax
            CASE mc_a: CASE mc_b: CASE mc_c:
            CASE mc_d: CASE mc_e: CASE mc_f:
              RESULTIS reg
          }
  LET rname = mcrname(r)
  LET iar = mcr2iar(r)

  IF mcDebug>=1 DO
  {
    writef("//    PRF *"")
    FOR i=1 TO mess%0 DO
    { LET ch = mess%i
      SWITCHON ch INTO
      { DEFAULT:   wrch(ch);       ENDCASE
        CASE '*n': writef("**n");  ENDCASE
        CASE '*t': writef("**t");  ENDCASE
        CASE '*"': writef("***""); ENDCASE
        CASE '*'': writef("***'"); ENDCASE
        CASE '*p': writef("**p");  ENDCASE
        CASE '*b': writef("**b");  ENDCASE
      }
    }
    writef("*",%s*n", rname)
  }

  { LET prf = rootnode!rtn_mc2
    LET format = mc*4 + rootnode!rtn_mc0 + datap
    db3datap()
    db3wrf(" datab ") 
    FOR i = 1 TO mess%0 DO iaD1(mess%i)
    iaD1(0)
    db3nl()

    iaF(ia_pushfl)               // Push the flags
    iaF(ia_pushal)               // Push all registers

    iaR( ia_pushl, iar)          // Push the argument for prf
    iaK( ia_pushl, format)       // Push the format for prf
    iaD( ia_call,  prf-(rootnode!rtn_mc0+4*mc+codep+5)) // Call prf(mess, reg)
    iaR( ia_popl,  Eax)          // pop the format
    iaR( ia_popl,  Eax)          // pop the argument

    iaF(ia_popal)                // Pop all registers
    iaF(ia_popfl)                // Pop the flags
  }
}


// ************** Debugging Trace Functions *********************

// The LS bits of mcDebug control the debugging trace as follows

//        x x x x b b b b
//        \     / | | | |
//         test   | | | * - Trace comments
//        number  | | *---- Trace MC instructions
//                | *------ Trace generated i386 instruction
//                *-------- Trace generated binary code and data

AND db0wrf(form, a, b, c, d, e, f, g, h, i, j, k) BE
  UNLESS (mcDebug & 1)=0 DO
    writef(form, a, b, c, d, e, f, g, h, i, j, k)

AND db1wrf(form, a, b, c, d, e, f, g, h, i, j, k) BE
  UNLESS (mcDebug & 2)=0 DO
    writef(form, a, b, c, d, e, f, g, h, i, j, k)

AND db2wrf(form, a, b, c, d, e, f, g, h, i, j, k) BE
  UNLESS (mcDebug & 4)=0 DO
    writef(form, a, b, c, d, e, f, g, h, i, j, k)

AND db3wrf(form, a, b, c, d, e, f, g, h, i, j, k) BE
  UNLESS (mcDebug & 8)=0 DO
    writef(form, a, b, c, d, e, f, g, h, i, j, k)

AND db3codep() BE
  UNLESS (mcDebug & 8)=0 DO writef("%i5: ", codep)

AND db3datap() BE
  UNLESS (mcDebug & 8)=0 DO writef("%i5: ", datap)

AND db3nl() BE
  UNLESS (mcDebug & 8)=0 DO newline()

//************** MC Code generation functions ***********************

/*

*/

LET mcNextlab() = VALOF
{ labno := labno + 1
  IF labno > labvupb DO
  { LET newlabvupb = labvupb+500
    LET newlabv = getvec(newlabvupb)
    LET newrefv = getvec(newlabvupb)
//writef("*nnewlabvupb=%n, newlabv=%n, newrefv=%n*n", newlabvupb, newlabv, newrefv)
//abort(1000)
    UNLESS newlabv & newrefv DO
    { IF newlabv DO freevec(newlabv)
      IF newrefv DO freevec(newrefv)
      writef("Error: Unable to expand the label vector*n")
      RESULTIS 0
    }
    
    FOR n = 0 TO labvupb DO
      newlabv!n, newrefv!n := labv!n, refv!n
    FOR n = labvupb+1 TO newlabvupb DO
      newlabv!n, newrefv!n := 0, 0
    IF labv DO freevec(labv)
    IF refv DO freevec(refv)
    labv, refv := newlabv, newrefv
    labvupb := newlabvupb
  }

  RESULTIS labno
}

AND debugtest(n) BE SWITCHON n INTO
{ DEFAULT:
        writef("Error: Unknown debug test %n*n", n)
        RETURN

  CASE 10:
        FOR x = Eax TO Edi DO iaDXsB(ia_negl, 12, x, 4, Eax)
        RETURN

  CASE 11:
        FOR x = Eax TO Edi DO iaRR(ia_movl, Eax, x)
        RETURN

  CASE 12:
        FOR x = Eax TO Edi DO iaDXsR(ia_movl, Eax, 12, x, 4)
        RETURN

  CASE 21:
        FOR x = Eax TO Edi DO
        { iaRDX(ia_movl, Eax, 0, x)
          iaRDX(ia_movl, Eax, 20, x)
          iaRDX(ia_movl, Eax, 200, x)
        }
        RETURN

  CASE 22:
        FOR x = Eax TO Edi UNLESS x=Esp DO
          iaRDXs(ia_movl, Eax, 20, x, 2)
        RETURN

  CASE 24:
        FOR x = Eax TO Edi UNLESS x=Esp DO
          iaRDXs(ia_movl, Eax, 20, x, 4)
        RETURN

  CASE 28:
        FOR x = Eax TO Edi UNLESS x=Esp DO
          iaRDXs(ia_movl, Eax, 20, x, 8)
        RETURN

  CASE 31:
        FOR b = Ebp TO Esi DO
        FOR x = Eax TO Edi UNLESS x=Esp DO
        { iaRDXsB(ia_movl, Eax, 0, x, 1, b)
          iaRDXsB(ia_movl, Eax, 20, x, 1, b)
          iaRDXsB(ia_movl, Eax, 200, x, 1, b)
        }
        RETURN

  CASE 32:
        FOR b = Ebp TO Esi DO
        FOR x = Eax TO Edi UNLESS x=Esp DO
          iaRDXsB(ia_movl, Eax, 20, x, 2, b)
        RETURN

  CASE 34:
        FOR b = Ebp TO Esi DO
        FOR x = Eax TO Edi UNLESS x=Esp DO
          iaRDXsB(ia_movl, Eax, 20, x, 4, b)
        RETURN

  CASE 38:
        FOR b = Ebp TO Esi DO
        FOR x = Eax TO Edi UNLESS x=Esp DO
          iaRDXsB(ia_movl, Eax, 20, x, 8, b)
        RETURN

}

AND mcComment(mess, a, b, c, d, e, f, g, h, i, j, k) BE
  db0wrf(mess, a, b, c, d, e, f, g, h, i, j, k)

AND mcDatap() = datap

AND mcCodep() = codep

AND mcF(op) BE
// cdq end endfn nop rtn
{ LET f = 0

  db1wrf("//    %s*n", mcop2str(op))

  SWITCHON op INTO
  { DEFAULT:       mcbadop(op, "F"); RETURN

    CASE mc_cdq:   f := ia_cdq;   ENDCASE // Sign extend A into D (for mc_div)

    CASE mc_endfn: // Resolve local labels and unset current function.
                   f := ia_endfn; ENDCASE // End of function code

    CASE mc_end:   // Check forward refs, then release all temp storage.
                   f := ia_end;   ENDCASE // End of assembly
    CASE mc_nop:   f := ia_nop;   ENDCASE // No operation

    CASE mc_rtn:   // Return from a routine

    // Now Esp -> [V(mv),V(mv-1),...,V1,    where mv = number of locals
    // and Ebp ->  Edi',Esi',Ebx',Ebp',<ret addr>,<arg1>,...,<arg ma.]

      iaRR(ia_movl, Esp, Ebp)  // movl %ebp, %esp
      iaR(ia_popl,  Edi)       // popl %edi
      iaR(ia_popl,  Esi)       // popl %esi
      iaR(ia_popl,  Ebx)       // popl %ebx
      iaR(ia_popl,  Ebp)       // popl %ebp
      //iaK(ia_ret,   4*maxarg)  // ret 4*maxarg
      iaF(ia_ret)  // ret
      // Note: the arguments are popped by the caller.
      RETURN
  }
  iaF(f)
}

AND mcK(op, k) BE
// alignc alignd datab datak debug div mul push udiv umul
{ LET f = 0

  db1wrf("//    %s $%n*n", mcop2str(op), k)

  SWITCHON op INTO
  { DEFAULT:
    bad:            mcbadop(op, "K"); RETURN

    CASE mc_alignc: f := ia_alignc; ENDCASE
    CASE mc_alignd: f := ia_alignd; ENDCASE
    CASE mc_datak:  f := ia_datak;  ENDCASE
    CASE mc_datab:  f := ia_datab;  ENDCASE
    CASE mc_debug:  mcDebug := k
                    IF mcDebug>=16 DO debugtest(k>>4)
                    RETURN
    CASE mc_push:   f := ia_pushl;  ENDCASE

    CASE mc_div:    iaD(ia_idivl, dataconst(k)); RETURN
    CASE mc_mul:    iaD(ia_imull, dataconst(k)); RETURN
    CASE mc_udiv:   iaD(ia_divl,  dataconst(k)); RETURN
    CASE mc_umul:   iaD(ia_mull,  dataconst(k)); RETURN
  }
  iaK(f, k)
}

AND dataconst(k) = VALOF
{ // Return the machine address in the data area of the required
  // read only constant.
  LET p = klist
  LET base = mc*4 + rootnode!rtn_mc0
//writef("dataconst: k=%n base=4**%x8+%x8 = %x8*n", k, mc, rootnode!rtn_mc0, base)
  UNTIL p=0 | mc!(p!1>>2)=k DO p := !p
  UNLESS p DO
  { iaK(ia_alignd, 4)
    p := mk2(klist, datap)
    klist := p
    iaK(ia_datak, k)
    //writef("dataconst: const k=%n allocated at %n*n", k, p!1)
  }
//writef("dataconst: const k=%n found at %n*n", k, p!1)
  RESULTIS p!1 + base
}

AND mcR(op, r) BE
// dec div inc mul neg not pop push
// seq sne slt sle sgt sge udiv umul uslt usle usgt usge
{ LET rname = mcrname(r)
  LET iar   = mcr2iar(r)
  LET f  = 0

  db1wrf("//    %s %s*n", mcop2str(op), rname)

  SWITCHON op INTO
  { DEFAULT:
bad:             mcbadop(op, "R"); RETURN

    CASE mc_dec:  f := ia_decl;  ENDCASE // decl r
    CASE mc_div:  f := ia_idivl; ENDCASE // idivl r
    CASE mc_inc:  f := ia_incl;  ENDCASE // incl r
    CASE mc_mul:  f := ia_imull; ENDCASE // imull r
    CASE mc_neg:  f := ia_negl;  ENDCASE // negl r
    CASE mc_not:  f := ia_notl;  ENDCASE // notl r
    CASE mc_pop:  f := ia_popl;  ENDCASE // popl r
    CASE mc_push: f := ia_pushl; ENDCASE // pushl r
    CASE mc_seq:  iaR(ia_sete, r)        // sete r
                  iaRR(ia_movzbl, r, r)  // movzbl r,r
                  RETURN
    CASE mc_sne:  iaR(ia_setne, r)       // setne r
                  iaRR(ia_movzbl, r, r)  // movzbl r,r
                  RETURN
    CASE mc_slt:  iaR(ia_setl, r)        // setl r
                  iaRR(ia_movzbl, r, r)  // movzbl r,r
                  RETURN
    CASE mc_sle:  iaR(ia_setle, r)       // setle r
                  iaRR(ia_movzbl, r, r)  // movzbl r,r
                  RETURN
    CASE mc_sgt:  iaR(ia_setg, r)        // setg r
                  iaRR(ia_movzbl, r, r)  // movzbl r,r
                  RETURN
    CASE mc_sge:  iaR(ia_setge, r)       // setge r
                  iaRR(ia_movzbl, r, r)  // movzbl r,r
                  RETURN

    CASE mc_uslt:  iaR(ia_setb, r)       // setb r
                  iaRR(ia_movzbl, r, r)  // movzbl r,r
                  RETURN
    CASE mc_usle:  iaR(ia_setbe, r)      // setbe r
                  iaRR(ia_movzbl, r, r)  // movzbl r,r
                  RETURN
    CASE mc_usgt:  iaR(ia_seta, r)       // seta r
                  iaRR(ia_movzbl, r, r)  // movzbl r,r
                  RETURN
    CASE mc_usge:  iaR(ia_setae, r)      // setae r
                  iaRR(ia_movzbl, r, r)  // movzbl r,r
                  RETURN
    CASE mc_udiv: f := ia_divl;  ENDCASE // divl r
    CASE mc_umul: f := ia_mull;  ENDCASE // mull r
  }
  iaR(f, iar)
}

AND mcA(op, n) BE
// div jmp mul neg not pop push
// seq sne slt sle sgt sge udiv umul uslt usle usgt usge
{ LET f = 0
 
  db1wrf("//    %s A%n*n", mcop2str(op), n)

  UNLESS 1 <= n <= maxarg DO
  { writef("Error: A%n not in range A1 to A%n*n", n, maxarg)
    RETURN 
  }

  SWITCHON op INTO
  { DEFAULT:    mcbadop(op, "A"); RETURN

    CASE mc_div:  f := ia_idivl; ENDCASE // idivl r
    CASE mc_mul:  f := ia_imull; ENDCASE // imull r
    CASE mc_neg:  f := ia_negl;  ENDCASE // negl r
    CASE mc_not:  f := ia_notl;  ENDCASE // notl r
    CASE mc_pop:  f := ia_popl;  ENDCASE // popl r
    CASE mc_push: f := ia_pushl; ENDCASE // pushl r
    CASE mc_seq:  f := ia_sete;  ENDCASE // sete r
    CASE mc_sne:  f := ia_setne; ENDCASE // setne r
    CASE mc_slt:  f := ia_setl;  ENDCASE // setl r
    CASE mc_sle:  f := ia_setle; ENDCASE // setle r
    CASE mc_sgt:  f := ia_setg;  ENDCASE // setg r
    CASE mc_sge:  f := ia_setge; ENDCASE // setge r
    CASE mc_udiv: f := ia_divl;  ENDCASE // divl r
    CASE mc_umul: f := ia_mull;  ENDCASE // mull r
    CASE mc_uslt: f := ia_setb;  ENDCASE // setb r
    CASE mc_usle: f := ia_setbe; ENDCASE // setbe r
    CASE mc_usgt: f := ia_seta;  ENDCASE // seta r
    CASE mc_usge: f := ia_setae; ENDCASE // setae r
  }
  iaDX(f, 16 + 4*n, Ebp) 
}

AND mcV(op, n) BE
// div jmp mul neg not pop push
// seq sne slt sle sgt sge udiv umul uslt usle usgt usge
{ LET f = 0
 
  db1wrf("//    %s V%n*n", mcop2str(op), n)

  UNLESS 1 <= n <= maxvar DO
  { writef("Error: V%n not in range V1 to V%n*n", n, maxvar)
    RETURN 
  }

  SWITCHON op INTO
  { DEFAULT:    mcbadop(op, "V"); RETURN

    CASE mc_div:  f := ia_idivl; ENDCASE // idivl Vn
    CASE mc_mul:  f := ia_imull; ENDCASE // imull Vn
    CASE mc_neg:  f := ia_negl;  ENDCASE // negl Vn
    CASE mc_not:  f := ia_notl;  ENDCASE // notl Vn
    CASE mc_pop:  f := ia_popl;  ENDCASE // popl Vn
    CASE mc_push: f := ia_pushl; ENDCASE // pushl Vn
    CASE mc_seq:  f := ia_sete;  ENDCASE // sete Vn
    CASE mc_sne:  f := ia_setne; ENDCASE // setne Vn
    CASE mc_slt:  f := ia_setl;  ENDCASE // setl Vn
    CASE mc_sle:  f := ia_setle; ENDCASE // setle Vn
    CASE mc_sgt:  f := ia_setg;  ENDCASE // setg Vn
    CASE mc_sge:  f := ia_setge; ENDCASE // setge Vn
    CASE mc_udiv: f := ia_divl;  ENDCASE // divl Vn
    CASE mc_umul: f := ia_mull;  ENDCASE // mull Vn
    CASE mc_uslt: f := ia_setb;  ENDCASE // setb Vn
    CASE mc_usle: f := ia_setbe; ENDCASE // setbe Vn
    CASE mc_usgt: f := ia_seta;  ENDCASE // seta Vn
    CASE mc_usge: f := ia_setae; ENDCASE // setae Vn
  }
  iaDX(f, -4 - 4*n, Ebp) 
}

AND mcG(op, n) BE
// div jmp mul neg not pop push
// seq sne slt sle sgt sge udiv umul uslt usle usgt usge
{ LET f = 0
 
  db1wrf("//    %s G%n*n", mcop2str(op), n)

  SWITCHON op INTO
  { DEFAULT:    mcbadop(op, "G"); RETURN

    CASE mc_div:  f := ia_idivl; ENDCASE // idivl Gn
    CASE mc_mul:  f := ia_imull; ENDCASE // imull Gn
    CASE mc_neg:  f := ia_negl;  ENDCASE // negl Gn
    CASE mc_not:  f := ia_notl;  ENDCASE // notl Gn
    CASE mc_pop:  f := ia_popl;  ENDCASE // popl Gn
    CASE mc_push: f := ia_pushl; ENDCASE // pushl Gn
    CASE mc_seq:  f := ia_sete;  ENDCASE // sete Gn
    CASE mc_sne:  f := ia_setne; ENDCASE // setne Gn
    CASE mc_slt:  f := ia_setl;  ENDCASE // setl Gn
    CASE mc_sle:  f := ia_setle; ENDCASE // setle Gn
    CASE mc_sgt:  f := ia_setg;  ENDCASE // setg Gn
    CASE mc_sge:  f := ia_setge; ENDCASE // setge Gn
    CASE mc_udiv: f := ia_divl;  ENDCASE // divl Gn
    CASE mc_umul: f := ia_mull;  ENDCASE // mull Gn
    CASE mc_uslt: f := ia_setb;  ENDCASE // setb Gn
    CASE mc_usle: f := ia_setbe; ENDCASE // setbe Gn
    CASE mc_usgt: f := ia_seta;  ENDCASE // seta Gn
    CASE mc_usge: f := ia_setae; ENDCASE // setae Gn
  }
  iaD(f, rootnode!rtn_mc0 + 4*(@globsize+n)) 
}

AND mcM(op, a) BE
// div jmp mul neg not pop push
// seq sne slt sle sgt sge udiv umul uslt usle usgt usge
{ LET f = 0
 
  db1wrf("//    %s M%n*n", mcop2str(op), a)

  SWITCHON op INTO
  { DEFAULT:    mcbadop(op, "M"); RETURN

    CASE mc_div:  f := ia_idivl; ENDCASE // idivl Ma
    CASE mc_mul:  f := ia_imull; ENDCASE // imull Ma
    CASE mc_neg:  f := ia_negl;  ENDCASE // negl Ma
    CASE mc_not:  f := ia_notl;  ENDCASE // notl Ma
    CASE mc_pop:  f := ia_popl;  ENDCASE // popl Ma
    CASE mc_push: f := ia_pushl; ENDCASE // pushl Ma
    CASE mc_seq:  f := ia_sete;  ENDCASE // sete Ma
    CASE mc_sne:  f := ia_setne; ENDCASE // setne Ma
    CASE mc_slt:  f := ia_setl;  ENDCASE // setl Ma
    CASE mc_sle:  f := ia_setle; ENDCASE // setle Ma
    CASE mc_sgt:  f := ia_setg;  ENDCASE // setg Ma
    CASE mc_sge:  f := ia_setge; ENDCASE // setge Ma
    CASE mc_udiv: f := ia_divl;  ENDCASE // divl Ma
    CASE mc_umul: f := ia_mull;  ENDCASE // mull Ma
    CASE mc_uslt: f := ia_setb;  ENDCASE // setb Ma
    CASE mc_usle: f := ia_setbe; ENDCASE // setbe Ma
    CASE mc_usgt: f := ia_seta;  ENDCASE // seta Ma
    CASE mc_usge: f := ia_setae; ENDCASE // setae Ma
  }
  iaD(f, rootnode!rtn_mc0 + 4*a) 
}

AND mcL(op, n) BE
// dlab lab
// div jmp mul neg not pop push
// seq sne slt sle sgt sge udiv umul uslt usle usgt usge
{ LET f = 0
 
  IF op=mc_lab | op=mc_dlab DO db1wrf("*n")

  db1wrf("//    %s L%n*n", mcop2str(op), n)

  SWITCHON op INTO
  { DEFAULT:    mcbadop(op, "L"); RETURN

    CASE mc_div:  f := ia_idivl; ENDCASE // idivl Ln
    CASE mc_datal:f := ia_datal; ENDCASE // datal Ln
    CASE mc_dlab: f := ia_dlab;  ENDCASE // dlab Ln
    CASE mc_lab:  f := ia_lab;   ENDCASE // lab Ln
    CASE mc_mul:  f := ia_imull; ENDCASE // imull Ln
    CASE mc_neg:  f := ia_negl;  ENDCASE // negl Ln
    CASE mc_not:  f := ia_notl;  ENDCASE // notl Ln
    CASE mc_pop:  f := ia_popl;  ENDCASE // popl Ln
    CASE mc_push: f := ia_pushl; ENDCASE // pushl Ln
    CASE mc_seq:  f := ia_sete;  ENDCASE // sete Ln
    CASE mc_sne:  f := ia_setne; ENDCASE // setne Ln
    CASE mc_slt:  f := ia_setl;  ENDCASE // setl Ln
    CASE mc_sle:  f := ia_setle; ENDCASE // setle Ln
    CASE mc_sgt:  f := ia_setg;  ENDCASE // setg Ln
    CASE mc_sge:  f := ia_setge; ENDCASE // setge Ln
    CASE mc_udiv: f := ia_divl;  ENDCASE // divl Ln
    CASE mc_umul: f := ia_mull;  ENDCASE // mull Ln
    CASE mc_uslt: f := ia_setb;  ENDCASE // setb Ln
    CASE mc_usle: f := ia_setbe; ENDCASE // setbe Ln
    CASE mc_usgt: f := ia_seta;  ENDCASE // seta Ln
    CASE mc_usge: f := ia_setae; ENDCASE // setae Ln
  }
  iaL(f, n) 
}

AND mcD(op, d) BE
// div lab mul neg not pop push
// seq sne slt sle sgt sge udiv umul uslt usle usgt usge
{ LET f = 0
 
  db1wrf("//    %s %n*n", mcop2str(op), d)

  SWITCHON op INTO
  { DEFAULT:    mcbadop(op, "D"); RETURN

    CASE mc_div:  f := ia_idivl; ENDCASE // idivl d
    CASE mc_lab:  f := ia_lab;   ENDCASE // lab d
    CASE mc_mul:  f := ia_imull; ENDCASE // imull d
    CASE mc_neg:  f := ia_negl;  ENDCASE // negl d
    CASE mc_not:  f := ia_notl;  ENDCASE // notl d
    CASE mc_pop:  f := ia_popl;  ENDCASE // popl d
    CASE mc_push: f := ia_pushl; ENDCASE // pushl d
    CASE mc_seq:  f := ia_sete;  ENDCASE // sete d
    CASE mc_sne:  f := ia_setne; ENDCASE // setne d
    CASE mc_slt:  f := ia_setl;  ENDCASE // setl d
    CASE mc_sle:  f := ia_setle; ENDCASE // setle d
    CASE mc_sgt:  f := ia_setg;  ENDCASE // setg d
    CASE mc_sge:  f := ia_setge; ENDCASE // setge d
    CASE mc_udiv: f := ia_divl;  ENDCASE // divl d
    CASE mc_umul: f := ia_mull;  ENDCASE // mull d
    CASE mc_uslt: f := ia_setb;  ENDCASE // setb d
    CASE mc_usle: f := ia_setbe; ENDCASE // setbe d
    CASE mc_usgt: f := ia_seta;  ENDCASE // seta d
    CASE mc_usge: f := ia_setae; ENDCASE // setae d
  }
  iaD(f, d) 
}

AND mcDX(op, d, x) BE
// div lab mul neg not pop push
// seq sne slt sle sgt sge udiv umul uslt usle usgt usge
{ LET xname = mcrname(x)
  LET iax = mcr2iar(x)
  LET f = 0
 
  db1wrf("//    %s %n(%s)*n", mcop2str(op), d, xname)

  SWITCHON op INTO
  { DEFAULT:    mcbadop(op, "DX"); RETURN

    CASE mc_div:  f := ia_idivl; ENDCASE // idivl d(x)
    CASE mc_lab:  f := ia_lab;   ENDCASE // lab d(x)
    CASE mc_mul:  f := ia_imull; ENDCASE // imull d(x)
    CASE mc_neg:  f := ia_negl;  ENDCASE // negl d(x)
    CASE mc_not:  f := ia_notl;  ENDCASE // notl d(x)
    CASE mc_pop:  f := ia_popl;  ENDCASE // popl d(x)
    CASE mc_push: f := ia_pushl; ENDCASE // pushl d(x)
    CASE mc_seq:  f := ia_sete;  ENDCASE // sete d(x)
    CASE mc_sne:  f := ia_setne; ENDCASE // setne d(x)
    CASE mc_slt:  f := ia_setl;  ENDCASE // setl d(x)
    CASE mc_sle:  f := ia_setle; ENDCASE // setle d(x)
    CASE mc_sgt:  f := ia_setg;  ENDCASE // setg d(x)
    CASE mc_sge:  f := ia_setge; ENDCASE // setge d(x)
    CASE mc_udiv: f := ia_divl;  ENDCASE // divl d(x)
    CASE mc_umul: f := ia_mull;  ENDCASE // mull d(x)
    CASE mc_uslt: f := ia_setb;  ENDCASE // setb d(x)
    CASE mc_usle: f := ia_setbe; ENDCASE // setbe d(x)
    CASE mc_usgt: f := ia_seta;  ENDCASE // seta d(x)
    CASE mc_usge: f := ia_setae; ENDCASE // setae d(x)
  }
  iaDX(f, d, iax) 
}

AND mcDXs(op, d, x, s) BE
// div lab mul neg not pop push
// seq sne slt sle sgt sge udiv umul uslt usle usgt usge
{ LET xname = mcrname(x)
  LET iax = mcr2iar(x)
  LET f = 0
 
  db1wrf("//    %s %n(%s**%n)*n", mcop2str(op), d, xname, s)

  SWITCHON op INTO
  { DEFAULT:    mcbadop(op, "DXs"); RETURN

    CASE mc_div:  f := ia_idivl; ENDCASE // idivl d(x,s)
    CASE mc_lab:  f := ia_lab;   ENDCASE // lab d(x,s)
    CASE mc_mul:  f := ia_imull; ENDCASE // imull d(x,s)
    CASE mc_neg:  f := ia_negl;  ENDCASE // negl d(x,s)
    CASE mc_not:  f := ia_notl;  ENDCASE // notl d(x,s)
    CASE mc_pop:  f := ia_popl;  ENDCASE // popl d(x,s)
    CASE mc_push: f := ia_pushl; ENDCASE // pushl d(x,s)
    CASE mc_seq:  f := ia_sete;  ENDCASE // sete d(x,s)
    CASE mc_sne:  f := ia_setne; ENDCASE // setne d(x,s)
    CASE mc_slt:  f := ia_setl;  ENDCASE // setl d(x,s)
    CASE mc_sle:  f := ia_setle; ENDCASE // setle d(x,s)
    CASE mc_sgt:  f := ia_setg;  ENDCASE // setg d(x,s)
    CASE mc_sge:  f := ia_setge; ENDCASE // setge d(x,s)
    CASE mc_udiv: f := ia_divl;  ENDCASE // divl d(x,s)
    CASE mc_umul: f := ia_mull;  ENDCASE // mull d(x,s)
    CASE mc_uslt: f := ia_setb;  ENDCASE // setb d(x,s)
    CASE mc_usle: f := ia_setbe; ENDCASE // setbe d(x,s)
    CASE mc_usgt: f := ia_seta;  ENDCASE // seta d(x,s)
    CASE mc_usge: f := ia_setae; ENDCASE // setae d(x,s)
  }
  iaDXs(f, d, iax, s) 
}

AND mcDXsB(op, d, x, s, b) BE
// div lab mul neg not pop push
// seq sne slt sle sgt sge udiv umul uslt usle usgt usge
{ LET xname = mcrname(x)
  LET bname = mcrname(b)
  LET iax = mcr2iar(x)
  LET iab = mcr2iar(b)
  LET f = 0
 
  db1wrf("//    %s %n(%s**%n+%s)*n", mcop2str(op), d, xname, s, bname)

  SWITCHON op INTO
  { DEFAULT:    mcbadop(op, "DXsB"); RETURN

    CASE mc_div:  f := ia_idivl; ENDCASE // idivl d(x,s,b)
    CASE mc_lab:  f := ia_lab;   ENDCASE // lab d(x,s,b)
    CASE mc_mul:  f := ia_imull; ENDCASE // imull d(x,s,b)
    CASE mc_neg:  f := ia_negl;  ENDCASE // negl d(x,s,b)
    CASE mc_not:  f := ia_notl;  ENDCASE // notl d(x,s,b)
    CASE mc_pop:  f := ia_popl;  ENDCASE // popl d(x,s,b)
    CASE mc_push: f := ia_pushl; ENDCASE // pushl d(x,s,b)
    CASE mc_seq:  f := ia_sete;  ENDCASE // sete d(x,s,b)
    CASE mc_sne:  f := ia_setne; ENDCASE // setne d(x,s,b)
    CASE mc_slt:  f := ia_setl;  ENDCASE // setl d(x,s,b)
    CASE mc_sle:  f := ia_setle; ENDCASE // setle d(x,s,b)
    CASE mc_sgt:  f := ia_setg;  ENDCASE // setg d(x,s,b)
    CASE mc_sge:  f := ia_setge; ENDCASE // setge d(x,s,b)
    CASE mc_udiv: f := ia_divl;  ENDCASE // divl d(x,s,b)
    CASE mc_umul: f := ia_mull;  ENDCASE // mull d(x,s,b)
    CASE mc_uslt: f := ia_setb;  ENDCASE // setb d(x,s,b)
    CASE mc_usle: f := ia_setbe; ENDCASE // setbe d(x,s,b)
    CASE mc_usgt: f := ia_seta;  ENDCASE // seta d(x,s,b)
    CASE mc_usge: f := ia_setae; ENDCASE // setae d(x,s,b)
  }
  iaDXsB(f, d, iax, s, iab) 
}

AND mcJS(op, n) BE mcJ(op, n, TRUE)

AND mcJL(op, n) BE mcJ(op, n, FALSE)

AND mcJ(op, n, short) BE
// jmp jeq jne jlt jle jgt jge

// If short is TRUE, forward refs are assumed to be rel8
{ LET f = 0

  db1wrf("//    %s L%n*n", mcop2str(op), n)

  SWITCHON op INTO
  { DEFAULT:     mcbadop(op, short -> "JS", "JL"); RETURN

    CASE mc_jmp: f := ia_jmp; ENDCASE // jmp Ln
    CASE mc_jeq: f := ia_je;  ENDCASE // je Ln
    CASE mc_jne: f := ia_jne; ENDCASE // jne Ln
    CASE mc_jlt: f := ia_jl;  ENDCASE // jl Ln
    CASE mc_jle: f := ia_jle; ENDCASE // jle Ln
    CASE mc_jgt: f := ia_jg;  ENDCASE // jg Ln
    CASE mc_jge: f := ia_jge; ENDCASE // jge Ln
    CASE mc_ujlt:f := ia_jb;  ENDCASE // jb Ln
    CASE mc_ujle:f := ia_jbe; ENDCASE // jbe Ln
    CASE mc_ujgt:f := ia_ja;  ENDCASE // ja Ln
    CASE mc_ujge:f := ia_jae; ENDCASE // jae Ln
  }
  iaJL(f, n, short)
}

AND mcJR(op, r) BE
{ LET rname = mcrname(r)
  LET iar = mcr2iar(r)

  db1wrf("//    %s **%s*n", mcop2str(op), rname)

  SWITCHON op INTO
  { DEFAULT:
      mcbadop(op, "JR")
      RETURN

    CASE mc_jmp: iaJR(ia_jmp, iar); RETURN
  }
}

AND mcRA(op, r, n) BE
// add and cmp lea lsh mv mvsxb mvsxh mvzxb mzxh rsh or sub xor
{ LET rname  = mcrname(r)
  LET iar    = mcr2iar(r)
  LET f = 0

  db1wrf("//    %s %s,A%n*n", mcop2str(op), rname, n)

  UNLESS 1 <= n <= maxarg DO
  { writef("*nError: Argument out of range  %i6: %s %s,A%n*n",
            codep, mcop2str(op), rname, n)
    RETURN
  }

  SWITCHON op INTO
  { DEFAULT:      mcbadop(op, "RA"); RETURN

    CASE mc_add:   f := ia_addl;   ENDCASE // r +:= <arg n>
    CASE mc_addc:  f := ia_addcl;  ENDCASE // r +:= <arg n> + carry
    CASE mc_and:   f := ia_andl;   ENDCASE // r &:= <arg n>
    CASE mc_cmp:   f := ia_cmpl;   ENDCASE // condition := r - <arg n>
    CASE mc_lea:   f := ia_leal;   ENDCASE // r := @ <arg n>
    CASE mc_lsh:   f := ia_shll;   ENDCASE // r <<:= <arg n>
    CASE mc_mv:    f := ia_movl;   ENDCASE // r := <arg n>
    CASE mc_mvsxb: f := ia_movsbl; ENDCASE // r := sign extend byte <arg n>
    CASE mc_mvsxh: f := ia_movswl; ENDCASE // r := sign extend word <arg n>
    CASE mc_mvzxb: f := ia_movzbl; ENDCASE // r := zero extend byte <arg n>
    CASE mc_mvzxh: f := ia_movzwl; ENDCASE // r := zero extend word <arg n>
    CASE mc_rsh:   f := ia_shrl;   ENDCASE // r >>:= <arg n>
    CASE mc_or:    f := ia_orl;    ENDCASE // r |:= <arg n>
    CASE mc_sub:   f := ia_subl;   ENDCASE // r -:= <arg n>
    CASE mc_subc:  f := ia_sbbl;   ENDCASE // r -:= <arg n> + borrow
    CASE mc_xchg:  f := ia_xchgl;  ENDCASE // r <=> <arg n>
    CASE mc_xor:   f := ia_xorl;   ENDCASE // r xor:= <arg n>
  }
  iaRDX(f, iar, 16+4*n, Ebp)
}

AND mcRV(op, r, n) BE
// add and cmp lea lsh mv mvsxb mvsxh mvzxb mzxh rsh or sub xor
{ LET rname  = mcrname(r)
  LET iar    = mcr2iar(r)
  LET f = 0

  db1wrf("//    %s %s,V%n*n", mcop2str(op), rname, n)

  UNLESS 1 <= n <= maxvar DO
  { writef("*nError: Variable out of range  %i6: %s %s,V%n*n",
            codep, mcop2str(op), rname, n)
    RETURN
  }

  SWITCHON op INTO
  { DEFAULT:      mcbadop(op, "RV"); RETURN

    CASE mc_add:   f := ia_addl;   ENDCASE // r +:= <var n>
    CASE mc_addc:  f := ia_addcl;  ENDCASE // r +:= <var n> + carry
    CASE mc_and:   f := ia_andl;   ENDCASE // r &:= <var n>
    CASE mc_cmp:   f := ia_cmpl;   ENDCASE // condition := r - <var n>
    CASE mc_lea:   f := ia_leal;   ENDCASE // r := @ <var n>
    CASE mc_lsh:   f := ia_shll;   ENDCASE // r <<:= <var n>
    CASE mc_mv:    f := ia_movl;   ENDCASE // r := <var n>
    CASE mc_mvsxb: f := ia_movsbl; ENDCASE // r := sign extend byte <var n>
    CASE mc_mvsxh: f := ia_movswl; ENDCASE // r := sign extend word <var n>
    CASE mc_mvzxb: f := ia_movzbl; ENDCASE // r := zero extend byte <var n>
    CASE mc_mvzxh: f := ia_movzwl; ENDCASE // r := zero extend word <var n>
    CASE mc_rsh:   f := ia_shrl;   ENDCASE // r >>:= <var n>
    CASE mc_or:    f := ia_orl;    ENDCASE // r |:= <var n>
    CASE mc_sub:   f := ia_subl;   ENDCASE // r -:= <var n>
    CASE mc_subc:  f := ia_sbbl;   ENDCASE // r -:= <var n> + carry
    CASE mc_xchg:  f := ia_xchgl;  ENDCASE // r <=> <var n>
    CASE mc_xor:   f := ia_xorl;   ENDCASE // r xor:= <var n>
  }
  iaRDX(f, iar, -4-4*n, Ebp)
}

AND mcRG(op, r, n) BE
// add and cmp lea lsh mv mvsxb mvsxh mvzxb mzxh rsh or sub xor
{ LET rname  = mcrname(r)
  LET iar    = mcr2iar(r)
  LET f = 0

  db1wrf("//    %s %s,G%n*n", mcop2str(op), rname, n)

  UNLESS 0 <= n <= globsize DO
  { writef("*nError: Global variable out of range  %i6: %s %s,G%n*n",
            codep, mcop2str(op), rname, n)
    RETURN
  }

  SWITCHON op INTO
  { DEFAULT:      mcbadop(op, "RG"); RETURN

    CASE mc_add:   f := ia_addl;   ENDCASE // r +:= <global n>
    CASE mc_addc:  f := ia_addcl;  ENDCASE // r +:= <global n> + carry
    CASE mc_and:   f := ia_andl;   ENDCASE // r &:= <global n>
    CASE mc_cmp:   f := ia_cmpl;   ENDCASE // condition := r - <global n>
    CASE mc_lea:   f := ia_leal;   ENDCASE // r := @ <global n>
    CASE mc_lsh:   f := ia_shll;   ENDCASE // r <<:= <global n>
    CASE mc_mv:    f := ia_movl;   ENDCASE // r := <global n>
    CASE mc_mvsxb: f := ia_movsbl; ENDCASE // r := sign extend byte <global n>
    CASE mc_mvsxh: f := ia_movswl; ENDCASE // r := sign extend word <global n>
    CASE mc_mvzxb: f := ia_movzbl; ENDCASE // r := zero extend byte <global n>
    CASE mc_mvzxh: f := ia_movzwl; ENDCASE // r := zero extend word <global n>
    CASE mc_rsh:   f := ia_shrl;   ENDCASE // r >>:= <global n>
    CASE mc_or:    f := ia_orl;    ENDCASE // r |:= <global n>
    CASE mc_sub:   f := ia_subl;   ENDCASE // r -:= <global n>
    CASE mc_subc:  f := ia_sbbl;   ENDCASE // r -:= <global n> + carry
    CASE mc_xchg:  f := ia_xchgl;  ENDCASE // r <=> <global n>
    CASE mc_xor:   f := ia_xorl;   ENDCASE // r xor:= <global n>
  }
  iaRD(f, iar, rootnode!rtn_mc0 +(@globsize + n)*4)
}

AND mcRM(op, r, a) BE
// add and cmp lea lsh mv mvsxb mvsxh mvzxb mzxh rsh or sub xor
{ LET rname = mcrname(r)
  LET iar   = mcr2iar(r)
  LET f  = 0

  db1wrf("//    %s %s,M%n*n", mcop2str(op), rname, a)

  SWITCHON op INTO
  { DEFAULT:      mcbadop(op, "RM"); RETURN

    CASE mc_add:   f := ia_addl;   ENDCASE // r +:= <mem a>
    CASE mc_addc:  f := ia_addcl;  ENDCASE // r +:= <mem a> + carry
    CASE mc_and:   f := ia_andl;   ENDCASE // r &:= <mem a>
    CASE mc_cmp:   f := ia_cmpl;   ENDCASE // condition := r - <mem a>
    CASE mc_lea:   f := ia_leal;   ENDCASE // r := @ <mem a>
    CASE mc_lsh:   f := ia_shll;   ENDCASE // r <<:= <mem a>
    CASE mc_mv:    f := ia_movl;   ENDCASE // r := <mem a>
    CASE mc_mvsxb: f := ia_movsbl; ENDCASE // r := sign extend byte <mem a>
    CASE mc_mvsxh: f := ia_movswl; ENDCASE // r := sign extend word <mem a>
    CASE mc_mvzxb: f := ia_movzbl; ENDCASE // r := zero extend byte <mem a>
    CASE mc_mvzxh: f := ia_movzwl; ENDCASE // r := zero extend word <mem a>
    CASE mc_rsh:   f := ia_shrl;   ENDCASE // r >>:= <mem a>
    CASE mc_or:    f := ia_orl;    ENDCASE // r |:= <mem a>
    CASE mc_sub:   f := ia_subl;   ENDCASE // r -:= <mem a>
    CASE mc_subc:  f := ia_sbbl;   ENDCASE // r -:= <mem a> + carry
    CASE mc_xchg:  f := ia_xchgl;  ENDCASE // r <=> <mem a>
    CASE mc_xor:   f := ia_xorl;   ENDCASE // r xor:= <mem a>
  }
  iaRD(f, iar, rootnode!rtn_mc0 + a*4)
}

AND mcRL(op, r, n) BE
// add and cmp lea lsh mv mvsxb mvsxh mvzxb mzxh rsh or sub xor
{ LET mem = rootnode!rtn_mc0
  LET rname = mcrname(r)
  LET iar = mcr2iar(r)
  LET f = 0
  LET val = labv!n

  db1wrf("//    %s %s,L%n*n",
          mcop2str(op), rname, n)

  UNLESS val DO
  { writef("*nError: Data label not set  %i6: %s %s,L%n*n",
            codep, mcop2str(op), rname, n)
    RETURN
  }

  SWITCHON op INTO
  { DEFAULT:       mcbadop(op, "RL"); RETURN

    CASE mc_add:   f := ia_addl;   ENDCASE // r +:= <data Ln>
    CASE mc_addc:  f := ia_addcl;  ENDCASE // r +:= <data Ln> + carry
    CASE mc_and:   f := ia_andl;   ENDCASE // r &:= <data Ln>
    CASE mc_cmp:   f := ia_cmpl;   ENDCASE // condition := r - <data Ln>
    CASE mc_lea:   f := ia_leal;   ENDCASE // r := @ <data Ln>
    CASE mc_lsh:   f := ia_shll;   ENDCASE // r <<:= <data Ln>
    CASE mc_mv:    f := ia_movl;   ENDCASE // r := <data Ln>
    CASE mc_mvsxb: f := ia_movsbl; ENDCASE // r := sign extend byte <data Ln>
    CASE mc_mvsxh: f := ia_movswl; ENDCASE // r := sign extend word <data Ln>
    CASE mc_mvzxb: f := ia_movzbl; ENDCASE // r := zero extend byte <data Ln>
    CASE mc_mvzxh: f := ia_movzwl; ENDCASE // r := zero extend word <data Ln>
    CASE mc_rsh:   f := ia_shrl;   ENDCASE // r >>:= <data Ln>
    CASE mc_or:    f := ia_orl;    ENDCASE // r |:= <data Ln>
    CASE mc_sub:   f := ia_subl;   ENDCASE // r -:= <data Ln>
    CASE mc_subc:  f := ia_sbbl;   ENDCASE // r -:= <data Ln> + carry
    CASE mc_xchg:  f := ia_xchgl;  ENDCASE // r <=> <data Ln>
    CASE mc_xor:   f := ia_xorl;   ENDCASE // r xor:= <data Ln>
  }
  iaRL(f, iar, n)
}

AND mcRD(op, r, d) BE
// add and cmp lea lsh mv mvsxb mvsxh mvzxb mzxh rsh or sub xor
{ 
  LET rname = mcrname(r)
  LET iar   = mcr2iar(r)
  LET f = 0

  db1wrf("//    %s %s,%n*n",
          mcop2str(op), rname, d)

  SWITCHON op INTO
  { DEFAULT:       mcbadop(op, "RD"); RETURN

    CASE mc_add:   f := ia_addl;   ENDCASE // r +:= d
    CASE mc_addc:  f := ia_addcl;  ENDCASE // r +:= d + carry
    CASE mc_and:   f := ia_andl;   ENDCASE // r &:= d
    CASE mc_cmp:   f := ia_cmpl;   ENDCASE // condition := r - d
    CASE mc_lea:   f := ia_leal;   ENDCASE // r := @ d
    CASE mc_lsh:   f := ia_shll;   ENDCASE // r <<:= d
    CASE mc_mv:    f := ia_movl;   ENDCASE // r := d
    CASE mc_mvsxb: f := ia_movsbl; ENDCASE // r := sign extend byte d
    CASE mc_mvsxh: f := ia_movswl; ENDCASE // r := sign extend word d
    CASE mc_mvzxb: f := ia_movzbl; ENDCASE // r := zero extend byte d
    CASE mc_mvzxh: f := ia_movzwl; ENDCASE // r := zero extend word d
    CASE mc_rsh:   f := ia_shrl;   ENDCASE // r >>:= d
    CASE mc_or:    f := ia_orl;    ENDCASE // r |:= d
    CASE mc_sub:   f := ia_subl;   ENDCASE // r -:= d
    CASE mc_subc:  f := ia_sbbl;   ENDCASE // r -:= d + carry
    CASE mc_xchg:  f := ia_xchgl;  ENDCASE // r <=> d
    CASE mc_xor:   f := ia_xorl;   ENDCASE // r xor:= d
  }
  iaRD(f, iar, d)
}

AND mcRDX(op, r, d, x) BE
// add and cmp lea lsh mv mvsxb mvsxh mvzxb mzxh rsh or sub xor
{ 
  LET rname = mcrname(r)
  LET xname = mcrname(x)
  LET iar   = mcr2iar(r)
  LET iax   = mcr2iar(x)
  LET f = 0

  db1wrf("//    %s %s,%n(%s)*n",
          mcop2str(op), rname, d, xname)

  SWITCHON op INTO
  { DEFAULT:       mcbadop(op, "RDX"); RETURN

    CASE mc_add:   f := ia_addl;   ENDCASE // r +:= d(x)
    CASE mc_addc:  f := ia_addcl;  ENDCASE // r +:= d(x) + carry
    CASE mc_and:   f := ia_andl;   ENDCASE // r &:= d(x)
    CASE mc_cmp:   f := ia_cmpl;   ENDCASE // condition := r - d(x)
    CASE mc_lea:   f := ia_leal;   ENDCASE // r := @ d(x)
    CASE mc_lsh:   f := ia_shll;   ENDCASE // r <<:= d(x)
    CASE mc_mv:    f := ia_movl;   ENDCASE // r := d(x)
    CASE mc_mvsxb: f := ia_movsbl; ENDCASE // r := sign extend byte d(x)
    CASE mc_mvsxh: f := ia_movswl; ENDCASE // r := sign extend word d(x)
    CASE mc_mvzxb: f := ia_movzbl; ENDCASE // r := zero extend byte d(x)
    CASE mc_mvzxh: f := ia_movzwl; ENDCASE // r := zero extend word d(x)
    CASE mc_rsh:   f := ia_shrl;   ENDCASE // r >>:= d(x)
    CASE mc_or:    f := ia_orl;    ENDCASE // r |:= d(x)
    CASE mc_sub:   f := ia_subl;   ENDCASE // r -:= d(x)
    CASE mc_subc:  f := ia_sbbl;   ENDCASE // r -:= d(x) + carry
    CASE mc_xchg:  f := ia_xchgl;  ENDCASE // r <=> d(x)
    CASE mc_xor:   f := ia_xorl;   ENDCASE // r xor:= d(x)
  }
  iaRDX(f, iar, d, iax)
}

AND mcRDXs(op, r, d, x, s) BE
// add and cmp lea lsh mv mvsxb mvsxh mvzxb mzxh rsh or sub xor
{ 
  LET rname = mcrname(r)
  LET xname = mcrname(x)
  LET iar   = mcr2iar(r)
  LET iax   = mcr2iar(x)
  LET f = 0

  db1wrf("//    %s %s,%n(%s**%n)*n",
          mcop2str(op), rname, d, xname, s)

  SWITCHON op INTO
  { DEFAULT:       mcbadop(op, "RDXs"); RETURN

    CASE mc_add:   f := ia_addl;   ENDCASE // r +:= d(x,s)
    CASE mc_addc:  f := ia_addcl;  ENDCASE // r +:= d(x,s) + carry
    CASE mc_and:   f := ia_andl;   ENDCASE // r &:= d(x,s)
    CASE mc_cmp:   f := ia_cmpl;   ENDCASE // condition := r - d(x,s)
    CASE mc_lea:   f := ia_leal;   ENDCASE // r := @ d(x,s)
    CASE mc_lsh:   f := ia_shll;   ENDCASE // r <<:= d(x,s)
    CASE mc_mv:    f := ia_movl;   ENDCASE // r := d(x,s)
    CASE mc_mvsxb: f := ia_movsbl; ENDCASE // r := sign extend byte d(x,s)
    CASE mc_mvsxh: f := ia_movswl; ENDCASE // r := sign extend word d(x,s)
    CASE mc_mvzxb: f := ia_movzbl; ENDCASE // r := zero extend byte d(x,s)
    CASE mc_mvzxh: f := ia_movzwl; ENDCASE // r := zero extend word d(x,s)
    CASE mc_rsh:   f := ia_shrl;   ENDCASE // r >>:= d(x,s)
    CASE mc_or:    f := ia_orl;    ENDCASE // r |:= d(x,s)
    CASE mc_sub:   f := ia_subl;   ENDCASE // r -:= d(x,s)
    CASE mc_subc:  f := ia_sbbl;   ENDCASE // r -:= d(x,s) + carry
    CASE mc_xchg:  f := ia_xchgl;  ENDCASE // r <=> d(x,s)
    CASE mc_xor:   f := ia_xorl;   ENDCASE // r xor:= d(x,s)
  }
//writef("mcRDXs: calling iaRDXs(f, %n, %n, %n, %n)*n", iar, d, iax, s)
  iaRDXs(f, iar, d, iax, s)
}

AND mcRDXsB(op, r, d, x, s, b) BE
// add and cmp lea lsh mv mvsxb mvsxh mvzxb mzxh rsh or sub xor
{ 
  LET rname = mcrname(r)
  LET xname = mcrname(x)
  LET bname = mcrname(b)
  LET iar   = mcr2iar(r)
  LET iax   = mcr2iar(x)
  LET iab   = mcr2iar(b)
  LET f = 0

  db1wrf("//    %s %s,%n(%s**%n+%s)*n",
          mcop2str(op), rname, d, xname, s, bname)

  SWITCHON op INTO
  { DEFAULT:       mcbadop(op, "RDXsB"); RETURN

    CASE mc_add:   f := ia_addl;   ENDCASE // r +:= d(x,s,b)
    CASE mc_addc:  f := ia_addcl;  ENDCASE // r +:= d(x,s,b) + carry
    CASE mc_and:   f := ia_andl;   ENDCASE // r &:= d(x,s,b)
    CASE mc_cmp:   f := ia_cmpl;   ENDCASE // condition := r - d(x,s,b)
    CASE mc_lea:   f := ia_leal;   ENDCASE // r := @ d(x,s,b)
    CASE mc_lsh:   f := ia_shll;   ENDCASE // r <<:= d(x,s,b)
    CASE mc_mv:    f := ia_movl;   ENDCASE // r := d(x,s,b)
    CASE mc_mvsxb: f := ia_movsbl; ENDCASE // r := sign extend byte d(x,s,b)
    CASE mc_mvsxh: f := ia_movswl; ENDCASE // r := sign extend word d(x,s,b)
    CASE mc_mvzxb: f := ia_movzbl; ENDCASE // r := zero extend byte d(x,s,b)
    CASE mc_mvzxh: f := ia_movzwl; ENDCASE // r := zero extend word d(x,s,b)
    CASE mc_rsh:   f := ia_shrl;   ENDCASE // r >>:= d(x,s,b)
    CASE mc_or:    f := ia_orl;    ENDCASE // r |:= d(x,s,b)
    CASE mc_sub:   f := ia_subl;   ENDCASE // r -:= d(x,s,b)
    CASE mc_subc:  f := ia_sbbl;   ENDCASE // r -:= d(x,s,b) + carry
    CASE mc_xchg:  f := ia_xchgl;  ENDCASE // r <=> d(x,s,b)
    CASE mc_xor:   f := ia_xorl;   ENDCASE // r xor:= d(x,s,b)
  }
  iaRDXsB(f, iar, d, iax, s, iab)
}

AND mcRR(op, r, t) BE  // r is destination
// add and cmp ld lsh mv mvsxb mvsxh mvzxb mvzxh or rsh sub xchg xor
{ LET rname = mcrname(r)
  LET tname = mcrname(t)
  LET iar = mcr2iar(r)
  LET iat = mcr2iar(t)
  LET f = 0

  db1wrf("//    %s %s,%s*n", mcop2str(op), rname, tname)

  SWITCHON op INTO
  { DEFAULT:        mcbadop(op, "RR"); RETURN

    CASE mc_add: f := ia_addl; ENDCASE // r +:= t
    CASE mc_addc:f := ia_addcl;ENDCASE // r +:= t + carry
    CASE mc_and: f := ia_andl; ENDCASE // r &:= t
    CASE mc_cmp: f := ia_cmpl; ENDCASE // condition := r - t
    CASE mc_mv:  IF r=t RETURN
                 f := ia_movl; ENDCASE // r := t
    CASE mc_mvsxb: f := ia_movsbl; ENDCASE // r := sign extend byte(t)
    CASE mc_mvsxh: f := ia_movswl; ENDCASE // r := sign extend halfword(t)
    CASE mc_mvzxb: f := ia_movzbl; ENDCASE // r := zero extend byte(t)
    CASE mc_mvzxh: f := ia_movzwl; ENDCASE // r := zero extend halfword(t)
    CASE mc_lsh: UNLESS t=mc_c DO
                 { writef("Shift amount must either be a constant or be in C*n")
                   RETURN
                 }
                 f := ia_shll; ENDCASE // r := r << C

    CASE mc_or:  f := ia_orl;  ENDCASE // r |:= t
    CASE mc_rsh: UNLESS t=mc_c DO
                 { writef("Shift amount must either be a constant or be in C*n")
                   RETURN
                 }
                 f := ia_shrl; ENDCASE // r := r >> C

    CASE mc_sub: f := ia_subl; ENDCASE // r -:= t
    CASE mc_subc:f := ia_sbbl; ENDCASE // r -:= t + carry
    CASE mc_xchg:f := ia_xchgl;ENDCASE // xchg(r, t)
    CASE mc_xor: f := ia_xorl; ENDCASE // r xor:= t
  }
  iaRR(f, iar, iat) // iar is destination
}

AND mcAR(op, n, r) BE
// add and cmp lsh mv mvb mvh rsh or sub xor
{ LET rname = mcrname(r)
  LET iar = mcr2iar(r)
  LET f = 0

  db1wrf("//    %s A%n,%s*n", mcop2str(op), n, rname)

  UNLESS 1 <= n <= maxarg DO
  { writef("*nError: Argument out of range  %i6: %s A%n,%s*n",
            codep, mcop2str(op), n, rname)
    RETURN
  }

  SWITCHON op INTO
  { DEFAULT:      mcbadop(op, "AR"); RETURN

    CASE mc_add:  f := ia_addl;   ENDCASE // <arg n> +:= r
    CASE mc_addc: f := ia_addcl;  ENDCASE // <arg n> +:= r + carry
    CASE mc_and:  f := ia_andl;   ENDCASE // <arg n> &:= r
    CASE mc_cmp:  f := ia_cmpl;   ENDCASE // condition := <arg n> - r
    CASE mc_lsh:  f := ia_shll;   ENDCASE // <arg n> <<:= r
    CASE mc_mv:   f := ia_movl;   ENDCASE // <arg n> := r
    CASE mc_mvb:  f := ia_movb;   ENDCASE // <arg n> := r (byte)
    CASE mc_mvh:  f := ia_movw;   ENDCASE // <arg n> := r (halfword)
    CASE mc_or:   f := ia_orl;    ENDCASE // <arg n> |:= r
    CASE mc_rsh:  f := ia_shrl;   ENDCASE // <arg n> >>:= r
    CASE mc_sub:  f := ia_subl;   ENDCASE // <arg n> -:= r
    CASE mc_subc: f := ia_sbbl;   ENDCASE // <arg n> -:= r + carry
    CASE mc_xor:  f := ia_xorl;   ENDCASE // <arg n> xor:= r
  }
  iaDXR(f, 16+4*n, Ebp, iar)
}

AND mcVR(op, n, r) BE
// add and cmp lsh mv mvb mvh or rsh sub xor
{ LET rname = mcrname(r)
  LET iar = mcr2iar(r)
  LET f = 0

  db1wrf("//    %s V%n,%s*n", mcop2str(op), n, rname)

  UNLESS 1 <= n <= maxvar DO
  { writef("*nError: Variable out of range  %i6: %s V%n,%s*n",
            codep, mcop2str(op), n, rname)
    RETURN
  }

  SWITCHON op INTO
  { DEFAULT:      mcbadop(op, "VR"); RETURN

    CASE mc_add:  f := ia_addl; ENDCASE // <var n> +:= r
    CASE mc_addc: f := ia_addcl;ENDCASE // <var n> +:= r + carry
    CASE mc_and:  f := ia_andl; ENDCASE // <var n> &:= r
    CASE mc_cmp:  f := ia_cmpl; ENDCASE // condition := <var n> - r
    CASE mc_lsh:  f := ia_shll; ENDCASE // <var n> <<:= r
    CASE mc_mv:   f := ia_movl; ENDCASE // <var n> := r
    CASE mc_mvb:  f := ia_movb; ENDCASE // <var n> := k (byte)
    CASE mc_mvh:  f := ia_movw; ENDCASE // <var n> := k (halfword)
    CASE mc_or:   f := ia_orl;  ENDCASE // <var n> |:= r
    CASE mc_rsh:  f := ia_shrl; ENDCASE // <var n> >>:= r
    CASE mc_sub:  f := ia_subl; ENDCASE // <var n> -:= r
    CASE mc_subc: f := ia_sbbl; ENDCASE // <var n> -:= r + carry
    CASE mc_xor:  f := ia_xorl; ENDCASE // <var n> xor:= r
  }
  iaDXR(f, -4-4*n, Ebp, iar)
}

AND mcGR(op, n, r) BE
// add and cmp lsh mv rsh or sub xor
{ LET rname = mcrname(r)
  LET iar = mcr2iar(r)
  LET f = 0

  db1wrf("//    %s G%n,%s*n", mcop2str(op), n, rname)

  UNLESS 0 <= n <= globsize DO
  { writef("*nError: Global variable out of range  %i6: %s G%n,%s*n",
            codep, mcop2str(op), n, rname)
    RETURN
  }

  SWITCHON op INTO
  { DEFAULT:      mcbadop(op, "GR"); RETURN

    CASE mc_add:  f := ia_addl; ENDCASE // <global n> +:= r
    CASE mc_addc: f := ia_addcl;ENDCASE // <global n> +:= r + carry
    CASE mc_and:  f := ia_andl; ENDCASE // <global n> &:= r
    CASE mc_cmp:  f := ia_cmpl; ENDCASE // condition := <global n> - r
    CASE mc_lsh:  f := ia_shll; ENDCASE // <global n> <<:= r
    CASE mc_mv:   f := ia_movl; ENDCASE // <global n> := r
    CASE mc_mvb:  f := ia_movb; ENDCASE // <global n> := k (byte)
    CASE mc_mvh:  f := ia_movw; ENDCASE // <global n> := k (halfword)
    CASE mc_or:   f := ia_orl;  ENDCASE // <global n> |:= r
    CASE mc_rsh:  f := ia_shrl; ENDCASE // <global n> >>:= r
    CASE mc_sub:  f := ia_subl; ENDCASE // <global n> -:= r
    CASE mc_subc: f := ia_sbbl; ENDCASE // <global n> -:= r + carry
    CASE mc_xor:  f := ia_xorl; ENDCASE // <global n> xor:= r
  }
  iaDR(f, rootnode!rtn_mc0 +(@globsize + n)*4, iar)
}

AND mcMR(op, a, r) BE
// add and cmp lsh mv rsh or sub xor
{ LET mem = rootnode!rtn_mc0
  LET rname = mcrname(r)
  LET iar = mcr2iar(r)
  LET f = 0

  db1wrf("//    %s M%n,%s*n", mcop2str(op), a, rname)

  SWITCHON op INTO
  { DEFAULT:      mcbadop(op, "MR"); RETURN

    CASE mc_add:  f := ia_addl; ENDCASE // <mem a> +:= r
    CASE mc_addc: f := ia_addcl;ENDCASE // <mem a> +:= r + carry
    CASE mc_and:  f := ia_andl; ENDCASE // <mem a> &:= r
    CASE mc_cmp:  f := ia_cmpl; ENDCASE // condition := <mem a> - r
    CASE mc_lsh:  f := ia_shll; ENDCASE // <mem a> <<:= r
    CASE mc_mv:   f := ia_movl; ENDCASE // <mem a> := r
    CASE mc_mvb:  f := ia_movb; ENDCASE // <mem a> := k (byte)
    CASE mc_mvh:  f := ia_movw; ENDCASE // <mem a> := k (halfword)
    CASE mc_or:   f := ia_orl;  ENDCASE // <mem a> |:= r
    CASE mc_rsh:  f := ia_shrl; ENDCASE // <mem a> >>:= r
    CASE mc_sub:  f := ia_subl; ENDCASE // <mem a> -:= r
    CASE mc_subc: f := ia_sbbl; ENDCASE // <mem a> -:= r + carry
    CASE mc_xor:  f := ia_xorl; ENDCASE // <mem a> xor:= r
  }
  iaDR(f, mem+4*a, iar)
}

AND mcLR(op, n, r) BE
// add and cmp lsh mv rsh or sub xor
{ LET mem = rootnode!rtn_mc0
  LET rname = mcrname(r)
  LET iar = mcr2iar(r)
  LET f = 0
  LET val = labv!n

  db1wrf("//    %s L%n,%s*n", mcop2str(op), n, rname)

  UNLESS val DO
  { writef("*nError: Data label not set  %i6: %s L%n,%s*n",
            codep, mcop2str(op), n, rname)
    RETURN
  }

  SWITCHON op INTO
  { DEFAULT:      mcbadop(op, "LR"); RETURN

    CASE mc_add:  f := ia_addl; ENDCASE // <data Ln> +:= r
    CASE mc_addc: f := ia_addcl;ENDCASE // <data Ln> +:= r + carry
    CASE mc_and:  f := ia_andl; ENDCASE // <data Ln> &:= r
    CASE mc_cmp:  f := ia_cmpl; ENDCASE // condition := <data Ln> - r
    CASE mc_lsh:  f := ia_shll; ENDCASE // <data Ln> <<:= r
    CASE mc_mv:   f := ia_movl; ENDCASE // <data Ln> := r
    CASE mc_mvb:  f := ia_movb; ENDCASE // <data Ln> := k (byte)
    CASE mc_mvh:  f := ia_movw; ENDCASE // <data Ln> := k (halfword)
    CASE mc_or:   f := ia_orl;  ENDCASE // <data Ln> |:= r
    CASE mc_rsh:  f := ia_shrl; ENDCASE // <data Ln> >>:= r
    CASE mc_sub:  f := ia_subl; ENDCASE // <data Ln> -:= r
    CASE mc_subc: f := ia_sbbl; ENDCASE // <data Ln> -:= r + carry
    CASE mc_xor:  f := ia_xorl; ENDCASE // <data Ln> xor:= r
  }
  iaDR(f, mem+4*mc+val, iar)
}

AND mcDR(op, d, r) BE
// add and cmp lsh mv rsh or sub xor
{ LET mem = rootnode!rtn_mc0
  LET rname = mcrname(r)
  LET iar = mcr2iar(r)
  LET f = 0

  db1wrf("//    %s %n,%s*n", mcop2str(op), d, rname)

  SWITCHON op INTO
  { DEFAULT:      mcbadop(op, "DR"); RETURN

    CASE mc_add:  f := ia_addl; ENDCASE // <addr d> +:= r
    CASE mc_addc: f := ia_addcl;ENDCASE // <addr d> +:= r + carry
    CASE mc_and:  f := ia_andl; ENDCASE // <addr d> &:= r
    CASE mc_cmp:  f := ia_cmpl; ENDCASE // condition := <addr d> - r
    CASE mc_lsh:  f := ia_shll; ENDCASE // <addr d> <<:= r
    CASE mc_mv:   f := ia_movl; ENDCASE // <addr d> := r
    CASE mc_mvb:  f := ia_movb; ENDCASE // <addr d> := k (byte)
    CASE mc_mvh:  f := ia_movw; ENDCASE // <addr d> := k (halfword)
    CASE mc_or:   f := ia_orl;  ENDCASE // <addr d> |:= r
    CASE mc_rsh:  f := ia_shrl; ENDCASE // <addr d> >>:= r
    CASE mc_sub:  f := ia_subl; ENDCASE // <addr d> -:= r
    CASE mc_subc: f := ia_sbbl; ENDCASE // <addr d> -:= r + carry
    CASE mc_xor:  f := ia_xorl; ENDCASE // <addr d> xor:= r
  }
  iaDR(f, d, iar)
}

AND mcDXR(op, d, x, r) BE
// add and cmp lsh mv rsh or sub xor
{ LET xname = mcrname(x)
  LET rname = mcrname(r)
  LET iax   = mcr2iar(x)
  LET iar   = mcr2iar(r)
  LET f  = 0

  db1wrf("//    %s %n(%s),%s*n", mcop2str(op), d, xname, rname)

  SWITCHON op INTO
  { DEFAULT:      mcbadop(op, "DXR"); RETURN

    CASE mc_add:  f := ia_addl; ENDCASE // d(x) +:= r
    CASE mc_addc: f := ia_addcl;ENDCASE // d(x) +:= r + carry
    CASE mc_and:  f := ia_andl; ENDCASE // d(x) &:= r
    CASE mc_cmp:  f := ia_cmpl; ENDCASE // condition := d(x) - r
    CASE mc_lsh:  f := ia_shll; ENDCASE // d(x) <<:= r
    CASE mc_mv:   f := ia_movl; ENDCASE // d(x) := r
    CASE mc_mvb:  f := ia_movb; ENDCASE // d(x) := k (byte)
    CASE mc_mvh:  f := ia_movw; ENDCASE // d(x) := k (halfword)
    CASE mc_or:   f := ia_orl;  ENDCASE // d(x) |:= r
    CASE mc_rsh:  f := ia_shrl; ENDCASE // d(x) >>:= r
    CASE mc_sub:  f := ia_subl; ENDCASE // d(x) -:= r
    CASE mc_subc: f := ia_sbbl; ENDCASE // d(x) -:= r + carry
    CASE mc_xor:  f := ia_xorl; ENDCASE // d(x) xor:= r
  }
  iaDXR(f, d, iax, iar)
}

AND mcDXsR(op, d, x, s, r) BE
// add and cmp lsh mv rsh or sub xor
{ LET xname = mcrname(x)
  LET rname = mcrname(r)
  LET iax   = mcr2iar(x)
  LET iar   = mcr2iar(r)
  LET f = 0

  db1wrf("//    %s %n(%s**%n),%s*n", mcop2str(op), d, xname, s, rname)

  SWITCHON op INTO
  { DEFAULT:      mcbadop(op, "DXsR"); RETURN

    CASE mc_add:  f := ia_addl; ENDCASE // d(x*4) +:= r
    CASE mc_addc: f := ia_addcl;ENDCASE // d(x*4) +:= r + carry
    CASE mc_and:  f := ia_andl; ENDCASE // d(x*4) &:= r
    CASE mc_cmp:  f := ia_cmpl; ENDCASE // condition := d(x*4) - r
    CASE mc_lsh:  f := ia_shll; ENDCASE // d(x*4) <<:= r
    CASE mc_mv:   f := ia_movl; ENDCASE // d(x*4) := r
    CASE mc_mvb:  f := ia_movb; ENDCASE // d(x*s) := r (byte)
    CASE mc_mvh:  f := ia_movw; ENDCASE // d(x*s) := r (halfword)
    CASE mc_or:   f := ia_orl;  ENDCASE // d(x*4) |:= r
    CASE mc_rsh:  f := ia_shrl; ENDCASE // d(x*4) >>:= r
    CASE mc_sub:  f := ia_subl; ENDCASE // d(x*4) -:= r
    CASE mc_subc: f := ia_sbbl; ENDCASE // d(x*4) -:= r + carry
    CASE mc_xor:  f := ia_xorl; ENDCASE // d(x*4) xor:= r
  }
  iaDXsR(f, d, iax, s, iar)
}

AND mcDXsBR(op, d, x, s, b, r) BE
// add and cmp lsh mv rsh or sub xor
{ LET xname = mcrname(x)
  LET bname = mcrname(b)
  LET rname = mcrname(r)
  LET iax   = mcr2iar(x)
  LET iab   = mcr2iar(b)
  LET iar   = mcr2iar(r)
  LET f  = 0

  db1wrf("//    %s %s,%n(%s**%n+%s)*n", mcop2str(op), rname, d, xname, s, bname)

  SWITCHON op INTO
  { DEFAULT:      mcbadop(op, "DXsBR"); RETURN

    CASE mc_add:  f := ia_addl; ENDCASE // d(x*4+b) +:= r
    CASE mc_addc: f := ia_addcl;ENDCASE // d(x*4+b) +:= r + carry
    CASE mc_and:  f := ia_andl; ENDCASE // d(x*4+b) &:= r
    CASE mc_cmp:  f := ia_cmpl; ENDCASE // condition := d(x*4+b) - r
    CASE mc_lsh:  f := ia_shll; ENDCASE // d(x*4+b) <<:= r
    CASE mc_mv:   f := ia_movl; ENDCASE // d(x*4+b) := r
    CASE mc_mvb:  f := ia_movb; ENDCASE // d(b,x,s) := k (byte)
    CASE mc_mvh:  f := ia_movw; ENDCASE // d(b,x,s) := k (halfword)
    CASE mc_or:   f := ia_orl;  ENDCASE // d(x*4+b) |:= r
    CASE mc_rsh:  f := ia_shrl; ENDCASE // d(x*4+b) >>:= r
    CASE mc_sub:  f := ia_subl; ENDCASE // d(x*4+b) -:= r
    CASE mc_subc: f := ia_sbbl; ENDCASE // d(x*4+b) -:= r + carry
    CASE mc_xor:  f := ia_xorl; ENDCASE // d(x*4+b) xor:= r
  }
  iaDXsBR(f, d, iax, s, iab, iar)
}


AND mcRK(op, r, k) BE
// add and cmp ld lsh or rsh sub xor
{ LET iar = mcr2iar(r)
  LET rname = mcrname(r)
  LET f = 0

  db1wrf("//    %s %s,$%n*n", mcop2str(op), rname, k)

  SWITCHON op INTO
  { DEFAULT:       mcbadop(op, "RK"); RETURN

    CASE mc_add:   f := ia_addl; ENDCASE // r +:= k
    CASE mc_addc:  f := ia_addcl;ENDCASE // r +:= k + carry
    CASE mc_and:   f := ia_andl; ENDCASE // r &:= k
    CASE mc_cmp:   f := ia_cmpl; ENDCASE // condition := r - k
    CASE mc_mv:    UNLESS k DO
                   { iaRR(ia_xorl, iar, iar) // r := 0
                     RETURN
                   }
                   f := ia_movl; ENDCASE // r := k

    CASE mc_lsh:   IF k<0 | k>31 DO      // r <<:= k
                   { iaRR(ia_xorl, iar, iar)
                     RETURN
                   }
                   f := ia_shll; ENDCASE
    CASE mc_or:    f := ia_orl;  ENDCASE // r |:= k
    CASE mc_rsh:   IF k<0 | k>31 DO      // r >>:= k
                   { iaRR(ia_xorl, iar, iar)
                     RETURN
                   }
                   f := ia_shrl; ENDCASE // r <<:= k
    CASE mc_sub:   f := ia_subl; ENDCASE // r -:= k
    CASE mc_subc:  f := ia_sbbl; ENDCASE // r -:= k + carry
    CASE mc_xor:   f := ia_xorl; ENDCASE // r xor:= k
  }
  iaRK(f, iar, k)
}

AND mcAK(op, n, k) BE
// add and cmp lsh mv mvb mvh rsh or sub xor
{ LET f = 0
  LET d = 16+4*n

  db1wrf("//    %s A%n,$%n*n", mcop2str(op), n, k)

  UNLESS 1 <= n <= maxarg DO
  { writef("*nError: Variable out of range  %i6: %s A%n,$%n*n",
            codep, mcop2str(op), n, k)
    RETURN
  }

  SWITCHON op INTO
  { DEFAULT:      mcbadop(op, "AK"); RETURN

    CASE mc_add:  f := ia_addl; ENDCASE // <arg n> +:= k
    CASE mc_addc: f := ia_addcl;ENDCASE // <arg n> +:= k + carry
    CASE mc_and:  f := ia_andl; ENDCASE // <arg n> &:= k
    CASE mc_cmp:  f := ia_cmpl; ENDCASE // condition := <arg n> - k
    CASE mc_lsh:  f := ia_shll; ENDCASE // <arg n> <<:= k
    CASE mc_mv:   f := ia_movl; ENDCASE // <arg n> := k
    CASE mc_mvb:  f := ia_movb; ENDCASE // <arg n> := k (byte)
    CASE mc_mvh:  f := ia_movw; ENDCASE // <arg n> := k (halfword)
    CASE mc_or:   f := ia_orl;  ENDCASE // <arg n> |:= k
    CASE mc_rsh:  f := ia_shrl; ENDCASE // <arg n> >>:= k
    CASE mc_sub:  f := ia_subl; ENDCASE // <arg n> -:= k
    CASE mc_subc: f := ia_sbbl; ENDCASE // <arg n> -:= k + carry
    CASE mc_xor:  f := ia_xorl; ENDCASE // <arg n> xor:= k
  }
  iaDXK(f, d, Ebp, k)
}

AND mcVK(op, n, k) BE
// add and cmp lsh mv rsh or sub xor
{ LET d, f = -4-4*n, 0

  db1wrf("//    %s V%n,$%n*n", mcop2str(op), n, k)

  UNLESS 1 <= n <= maxvar DO
  { writef("*nError: Variable out of range  %i6: %s V%n,$%n*n",
            codep, mcop2str(op), n, k)
    RETURN
  }

  SWITCHON op INTO
  { DEFAULT:      mcbadop(op, "VR"); RETURN

    CASE mc_add:  f := ia_addl; ENDCASE // <var n> +:= k
    CASE mc_addc: f := ia_addcl;ENDCASE // <var n> +:= k + carry
    CASE mc_and:  f := ia_andl; ENDCASE // <var n> &:= k
    CASE mc_cmp:  f := ia_cmpl; ENDCASE // condition := <var n> - k
    CASE mc_lsh:  f := ia_shll; ENDCASE // <var n> <<:= k
    CASE mc_mv:   f := ia_movl; ENDCASE // <var n> := k
    CASE mc_mvb:  f := ia_movb; ENDCASE // <var n> := k (byte)
    CASE mc_mvh:  f := ia_movw; ENDCASE // <var n> := k (halfword)
    CASE mc_or:   f := ia_orl;  ENDCASE // <var n> |:= k
    CASE mc_rsh:  f := ia_shrl; ENDCASE // <var n> >>:= k
    CASE mc_sub:  f := ia_subl; ENDCASE // <var n> -:= k
    CASE mc_subc: f := ia_sbbl; ENDCASE // <var n> -:= k + carry
    CASE mc_xor:  f := ia_xorl; ENDCASE // <var n> xor:= k
  }
  iaDXK(f, d, Ebp, k)
}

AND mcGK(op, n, k) BE
// add and cmp lsh mv rsh or sub xor
{ LET d, f =  rootnode!rtn_mc0 +(@globsize + n)*4, 0

  db1wrf("//    %s G%n,$%n*n", mcop2str(op), n, k)

  UNLESS 0 <= n <= globsize DO
  { writef("*nError: Global variable out of range  %i6: %s G%n,$%n*n",
            codep, mcop2str(op), n, k)
    RETURN
  }

  SWITCHON op INTO
  { DEFAULT:      mcbadop(op, "GK"); RETURN

    CASE mc_add:  f := ia_addl; ENDCASE // <global n> +:= k
    CASE mc_addc: f := ia_addcl;ENDCASE // <global n> +:= k + carry
    CASE mc_and:  f := ia_andl; ENDCASE // <global n> &:= k
    CASE mc_cmp:  f := ia_cmpl; ENDCASE // condition := <global n> - k
    CASE mc_lsh:  f := ia_shll; ENDCASE // <global n> <<:= k
    CASE mc_mv:   f := ia_movl; ENDCASE // <global n> := k
    CASE mc_mvb:  f := ia_movb; ENDCASE // <global n> := k (byte)
    CASE mc_mvh:  f := ia_movw; ENDCASE // <global n> := k (halfword)
    CASE mc_or:   f := ia_orl;  ENDCASE // <global n> |:= k
    CASE mc_rsh:  f := ia_shrl; ENDCASE // <global n> >>:= k
    CASE mc_sub:  f := ia_subl; ENDCASE // <global n> -:= k
    CASE mc_subc: f := ia_sbbl; ENDCASE // <global n> -:= k + carry
    CASE mc_xor:  f := ia_xorl; ENDCASE // <global n> xor:= k
  }
  iaDK(f, d, k)
}

AND mcMK(op, a, k) BE
// add and cmp lsh mv rsh or sub xor
{ LET mem = rootnode!rtn_mc0
  LET d, f = mem+4*a, 0

  db1wrf("//    %s M%n,$%n*n", mcop2str(op), a, k)

  SWITCHON op INTO
  { DEFAULT:      mcbadop(op, "MK"); RETURN

    CASE mc_add:  f := ia_addl; ENDCASE // <mem a> +:= k
    CASE mc_addc: f := ia_addcl;ENDCASE // <mem a> +:= k + carry
    CASE mc_and:  f := ia_andl; ENDCASE // <mem a> &:= k
    CASE mc_cmp:  f := ia_cmpl; ENDCASE // condition := <mem a> - k
    CASE mc_lsh:  f := ia_shll; ENDCASE // <mem a> <<:= k
    CASE mc_mv:   f := ia_movl; ENDCASE // <mem a> := k
    CASE mc_mvb:  f := ia_movb; ENDCASE // <mem a> := k (byte)
    CASE mc_mvh:  f := ia_movw; ENDCASE // <mem a> := k (halfword)
    CASE mc_or:   f := ia_orl;  ENDCASE // <mem a> |:= k
    CASE mc_rsh:  f := ia_shrl; ENDCASE // <mem a> >>:= k
    CASE mc_sub:  f := ia_subl; ENDCASE // <mem a> -:= k
    CASE mc_subc: f := ia_sbbl; ENDCASE // <mem a> -:= k + carry
    CASE mc_xor:  f := ia_xorl; ENDCASE // <mem a> xor:= k
  }
  iaDK(f, d, k)
}

AND mcLK(op, n, k) BE
// add and cmp lsh mv rsh or sub xor
{ LET mem = rootnode!rtn_mc0
  LET val = labv!n
  LET d, f = mem+4*mc+val, 0

  db1wrf("//    %s L%n,$%n*n", mcop2str(op), n, k)

  UNLESS val DO
  { writef("*nError: Data label not set  %i6: %s L%n,$%n*n",
            codep, mcop2str(op), n, k)
    RETURN
  }

  SWITCHON op INTO
  { DEFAULT:      mcbadop(op, "LK"); RETURN

    CASE mc_add:  f := ia_addl; ENDCASE // <data Ln> +:= k
    CASE mc_addc: f := ia_addcl;ENDCASE // <data Ln> +:= k + carry
    CASE mc_and:  f := ia_andl; ENDCASE // <data Ln> &:= k
    CASE mc_cmp:  f := ia_cmpl; ENDCASE // condition := <data Ln> - k
    CASE mc_lsh:  f := ia_shll; ENDCASE // <data Ln> <<:= k
    CASE mc_mv:   f := ia_movl; ENDCASE // <data Ln> := k
    CASE mc_mvb:  f := ia_movb; ENDCASE // <data Ln> := k (byte)
    CASE mc_mvh:  f := ia_movw; ENDCASE // <data Ln> := k (halfword)
    CASE mc_or:   f := ia_orl;  ENDCASE // <data Ln> |:= k
    CASE mc_rsh:  f := ia_shrl; ENDCASE // <data Ln> >>:= k
    CASE mc_sub:  f := ia_subl; ENDCASE // <data Ln> -:= k
    CASE mc_subc: f := ia_sbbl; ENDCASE // <data Ln> -:= k + carry
    CASE mc_xor:  f := ia_xorl; ENDCASE // <data Ln> xor:= k
  }
  iaDK(f, d, k)
}

AND mcDK(op, d, k) BE
// add and cmp lsh mv rsh or sub xor
{ LET mem = rootnode!rtn_mc0
  LET f = 0

  db1wrf("//    %s %n,$%n*n", mcop2str(op), d, k)

  SWITCHON op INTO
  { DEFAULT:      mcbadop(op, "DK"); RETURN

    CASE mc_add:  f := ia_addl; ENDCASE // <addr d> +:= k
    CASE mc_addc: f := ia_addcl;ENDCASE // <addr d> +:= k + carry
    CASE mc_and:  f := ia_andl; ENDCASE // <addr d> &:= k
    CASE mc_cmp:  f := ia_cmpl; ENDCASE // condition := <addr d> - k
    CASE mc_lsh:  f := ia_shll; ENDCASE // <addr d> <<:= k
    CASE mc_mv:   f := ia_movl; ENDCASE // <addr d> := k
    CASE mc_mvb:  f := ia_movb; ENDCASE // <addr d> := k (byte)
    CASE mc_mvh:  f := ia_movw; ENDCASE // <addr d> := k (halfword)
    CASE mc_or:   f := ia_orl;  ENDCASE // <addr d> |:= k
    CASE mc_rsh:  f := ia_shrl; ENDCASE // <addr d> >>:= k
    CASE mc_sub:  f := ia_subl; ENDCASE // <addr d> -:= k
    CASE mc_subc: f := ia_sbbl; ENDCASE // <addr d> -:= k + carry
    CASE mc_xor:  f := ia_xorl; ENDCASE // <addr d> xor:= k
  }
  iaDK(f, d, k)
}

AND mcDXK(op, d, x, k) BE
// add and cmp lsh mv rsh or sub xor
{ LET xname = mcrname(x)
  LET iax  = mcr2iar(x)
  LET f = 0

  db1wrf("//    %s %n(%s),$%n*n", mcop2str(op), d, xname, k)

  SWITCHON op INTO
  { DEFAULT:      mcbadop(op, "DXK"); RETURN

    CASE mc_add:  f := ia_addl; ENDCASE // d(x) +:= k
    CASE mc_addc: f := ia_addcl;ENDCASE // d(x) +:= k + carry
    CASE mc_and:  f := ia_andl; ENDCASE // d(x) &:= k
    CASE mc_cmp:  f := ia_cmpl; ENDCASE // condition := d(x) - k
    CASE mc_lsh:  f := ia_shll; ENDCASE // d(x) <<:= k
    CASE mc_mv:   f := ia_movl; ENDCASE // d(x) := k
    CASE mc_mvb:  f := ia_movb; ENDCASE // d(x) := k (byte)
    CASE mc_mvh:  f := ia_movw; ENDCASE // d(x) := k (halfword)
    CASE mc_or:   f := ia_orl;  ENDCASE // d(x) |:= k
    CASE mc_rsh:  f := ia_shrl; ENDCASE // d(x) >>:= k
    CASE mc_sub:  f := ia_subl; ENDCASE // d(x) -:= k
    CASE mc_subc: f := ia_sbbl; ENDCASE // d(x) -:= k + carry
    CASE mc_xor:  f := ia_xorl; ENDCASE // d(x) xor:= k
  }
  iaDXK(f, d, iax, k)
}

AND mcDXsK(op, d, x, s, k) BE
// add and cmp lsh mv rsh or sub xor
{ LET xname = mcrname(x)
  LET iax  = mcr2iar(x)
  LET f = 0

  db1wrf("//    %s %n(%s**%n),$%n*n", mcop2str(op), d, xname, s, k)

  SWITCHON op INTO
  { DEFAULT:      mcbadop(op, "DXsK"); RETURN

    CASE mc_add:  f := ia_addl; ENDCASE // d(,x,s) +:= k
    CASE mc_addc: f := ia_addcl;ENDCASE // d(,x,s) +:= k + carry
    CASE mc_and:  f := ia_andl; ENDCASE // d(,x,s) &:= k
    CASE mc_cmp:  f := ia_cmpl; ENDCASE // condition := d(,x,s) - k
    CASE mc_lsh:  f := ia_shll; ENDCASE // d(,x,s) <<:= k
    CASE mc_mv:   f := ia_movl; ENDCASE // d(,x,s) := k
    CASE mc_mvb:  f := ia_movb; ENDCASE // d(,x,s) := k (byte)
    CASE mc_mvh:  f := ia_movw; ENDCASE // d(,x,s) := k (halfword)
    CASE mc_or:   f := ia_orl;  ENDCASE // d(,x,s) |:= k
    CASE mc_rsh:  f := ia_shrl; ENDCASE // d(,x,s) >>:= k
    CASE mc_sub:  f := ia_subl; ENDCASE // d(,x,s) -:= k
    CASE mc_subc: f := ia_sbbl; ENDCASE // d(,x,s) -:= k + carry
    CASE mc_xor:  f := ia_xorl; ENDCASE // d(,x,s) xor:= k
  }
  iaDXsK(f, d, iax, s, k)
}

AND mcDXsBK(op, d, x, s, b, k) BE
// add and cmp lsh mv rsh or sub xor
{ LET xname = mcrname(x)
  LET bname = mcrname(b)
  LET iax   = mcr2iar(x)
  LET iab   = mcr2iar(b)
  LET f  = 0

  db1wrf("//    %s %n(%s**%n+%s),$%n*n", mcop2str(op), d, xname, s, bname, k)

  SWITCHON op INTO
  { DEFAULT:      mcbadop(op, "DXsBK"); RETURN

    CASE mc_add:  f := ia_addl; ENDCASE // d(x*4+b) +:= k
    CASE mc_addc: f := ia_addcl;ENDCASE // d(x*4+b) +:= k + carry
    CASE mc_and:  f := ia_andl; ENDCASE // d(x*4+b) &:= k
    CASE mc_cmp:  f := ia_cmpl; ENDCASE // condition := d(x*4+b) - k
    CASE mc_lsh:  f := ia_shll; ENDCASE // d(x*4+b) <<:= k
    CASE mc_mv:   f := ia_movl; ENDCASE // d(x*4+b) := k
    CASE mc_mvb:  f := ia_movb; ENDCASE // d(x*4+b) := k (byte)
    CASE mc_mvh:  f := ia_movw; ENDCASE // d(x*4+b) := k (halfword)
    CASE mc_or:   f := ia_orl;  ENDCASE // d(x*4+b) |:= k
    CASE mc_rsh:  f := ia_shrl; ENDCASE // d(x*4+b) >>:= k
    CASE mc_sub:  f := ia_subl; ENDCASE // d(x*4+b) -:= k
    CASE mc_subc: f := ia_sbbl; ENDCASE // d(x*4+b) -:= k + carry
    CASE mc_xor:  f := ia_xorl; ENDCASE // d(x*4+b) xor:= k
  }
  iaDXsBK(f, d, iax, s, iab, k)
}

AND mcKK(op, fno, args) BE
{ // call

  db1wrf("*n//    %s F%n %n*n", mcop2str(op), fno, args)

  SWITCHON op INTO
  { DEFAULT:  mcbadop(op, "KK");  RETURN

    CASE mc_call:
      { UNLESS 1<=fno<=maxfno DO
        { writef("Error: Bad fno=%n for CALL*n", fno)
          RETURN
        }

        iaFno(ia_call, fno)
        IF args DO iaRK(ia_addl, Esp, 4*args)
      }
  }
}

AND mcKKK(op, fno, maxa, maxv) BE SWITCHON op INTO
// entry  -- with maxa arguments and maxv local variables
{ DEFAULT:
      mcbadop(op, "KKK")
      RETURN

  CASE mc_entry: // fno, x=num of args, y=num of locals
      db1wrf("*n//    ENTRY F%n %n %n*n", fno, maxa, maxv)

      IF fno>maxfno DO
      { writef("ENTRY function number too large*n")
        RETURN
      }

      IF fnv!fno DO
      { writef("Function F%n defined more than once at codep=%n*n", fno, codep)
abort(999)
        RETURN
      }

      currfno := fno // Set current function indicator.
      maxarg := maxa
      maxvar := maxv

      // On entry Esp -> [<Ret addr>, <arg1>,...,<arg ma>]

      iaK(ia_alignc, 4)
      iaK(ia_entry, currfno)
      iaR(ia_pushl, Ebp)             // pushl %ebp
      iaR(ia_pushl, Ebx)             // pushl %ebx
      iaR(ia_pushl, Esi)             // pushl %esi
      iaR(ia_pushl, Edi)             // pushl %edi
      iaRR(ia_movl, Ebp, Esp)        // movl  %esp, %ebp

      IF maxvar DO
        iaRK(ia_subl, Esp, 4*maxvar) // subl $4*maxvar, %esp

      // Now Esp -> [V(maxv),V(maxv-1),...,V1,
      // and Ebp ->  Edi',Esi',Ebx',Ebp',<ret addr>,<arg1>,...,<arg maxa>.]

      // Note: <arg i> has address 16+4*i(Ebp)
      //  and: <var i> has address -4-4*i(Ebp)
      RETURN
}

AND mcbadop(op, str) BE
{ LET opstr = mcop2str(op)
  writef("Error: mc%s(", str)
  writef(opstr, op)
  writef(",..) not available*n")
}

AND mcop2str(op) = VALOF SWITCHON op INTO
{ DEFAULT:          RESULTIS "UNKNOWN:%n"

  CASE mc_add:      RESULTIS "ADD"
  CASE mc_addc:     RESULTIS "ADDC"
  CASE mc_alignc:   RESULTIS "ALIGNC"
  CASE mc_alignd:   RESULTIS "ALIGND"
  CASE mc_and:      RESULTIS "AND"
  CASE mc_call:     RESULTIS "CALL"
  CASE mc_cdq:      RESULTIS "CDQ"
  CASE mc_cmp:      RESULTIS "CMP"
  CASE mc_datab:    RESULTIS "DATAB"
  CASE mc_datak:    RESULTIS "DATAK"
  CASE mc_datal:    RESULTIS "DATAL"
  CASE mc_debug:    RESULTIS "DEBUG"
  CASE mc_dec:      RESULTIS "DEC"
  CASE mc_div:      RESULTIS "DIV"
  CASE mc_dlab:     RESULTIS "DLAB"
  CASE mc_end:      RESULTIS "END"
  CASE mc_endfn:    RESULTIS "ENDFN"
  CASE mc_entry:    RESULTIS "ENTRY"
  CASE mc_inc:      RESULTIS "INC"
  CASE mc_jeq:      RESULTIS "JEQ"
  CASE mc_jge:      RESULTIS "JGE"
  CASE mc_jgt:      RESULTIS "JGT"
  CASE mc_jle:      RESULTIS "JLE"
  CASE mc_jlt:      RESULTIS "JLT"
  CASE mc_jmp:      RESULTIS "JMP"
  CASE mc_jne:      RESULTIS "JNE"
  CASE mc_lab:      RESULTIS "LAB"
  CASE mc_lea:      RESULTIS "LEA"
  CASE mc_lsh:      RESULTIS "LSH"
  CASE mc_mul:      RESULTIS "MUL"
  CASE mc_mv:       RESULTIS "MV"
  CASE mc_mvb:      RESULTIS "MVB"
  CASE mc_mvh:      RESULTIS "MVH"
  CASE mc_mvsxb:    RESULTIS "MVSXB"
  CASE mc_mvzxb:    RESULTIS "MVBZX"
  CASE mc_mvsxh:    RESULTIS "MVSXH"
  CASE mc_mvzxh:    RESULTIS "MVZXH"
  CASE mc_neg:      RESULTIS "NEG"
  CASE mc_not:      RESULTIS "NOT"
  CASE mc_or:       RESULTIS "OR"
  CASE mc_pop:      RESULTIS "POP"
  CASE mc_push:     RESULTIS "PUSH"
  CASE mc_rsh:      RESULTIS "RSH"
  CASE mc_rtn:      RESULTIS "RTN"
  CASE mc_seq:      RESULTIS "SEQ"
  CASE mc_sge:      RESULTIS "SGE"
  CASE mc_sgt:      RESULTIS "SGT"
  CASE mc_sle:      RESULTIS "SLE"
  CASE mc_slt:      RESULTIS "SLT"
  CASE mc_sne:      RESULTIS "SNE"
  CASE mc_sub:      RESULTIS "SUB"
  CASE mc_subc:     RESULTIS "SUBC"
  CASE mc_udiv:     RESULTIS "UDIV"
  CASE mc_ujge:     RESULTIS "UJGE"
  CASE mc_ujgt:     RESULTIS "UJGT"
  CASE mc_ujle:     RESULTIS "UJLE"
  CASE mc_ujlt:     RESULTIS "UJLT"
  CASE mc_umul:     RESULTIS "UMUL"
  CASE mc_usge:     RESULTIS "USGE"
  CASE mc_usgt:     RESULTIS "USGT"
  CASE mc_usle:     RESULTIS "USLE"
  CASE mc_uslt:     RESULTIS "USLT"
  CASE mc_xchg:     RESULTIS "XCHG"
  CASE mc_xor:      RESULTIS "XOR"
}

AND mcrname(r) = VALOF SWITCHON r INTO
{ 
  DEFAULT:   writef("mcname(%n): Bad MC register*n", r)
             RESULTIS "?"
  CASE mc_a: RESULTIS "A"
  CASE mc_b: RESULTIS "B"
  CASE mc_c: RESULTIS "C"
  CASE mc_d: RESULTIS "D"
  CASE mc_e: RESULTIS "E"
  CASE mc_f: RESULTIS "F"
}


// ************** i386 instruction assembly functions ************

// The order of the operands of ia functions are the same as those
// in the GNU i386 assembly language. Ie assignments are typically
// from left to right.

AND iaF(op) BE
// cdq end endfn nop popal popfl pushal pushfl ret
{ LET f = 0

  db2wrf("        %s*n", iaop2str(op))

  SWITCHON op INTO
  { DEFAULT:  iabadop(op, "F"); RETURN

    CASE ia_cdq:    f := #x99; ENDCASE       // cdq

    CASE ia_end:                          // end
      // Check for no remaining label or function forward refs
      FOR n = 1 TO maxfno IF frefv!n DO
        writef("Function %n not defined*n", n)
      // Fall into endfn to check the local labels

    CASE ia_endfn:                        // endfn
      // Check for no remaining label forward refs
      FOR n = 1 TO labvupb DO
      { LET val = labv!n
        TEST val
        THEN IF codeb<val<codet DO labv!n := 0 // Unset local label
        ELSE IF refv!n DO writef("Label L%n note set*n", n)
      }
      currfno := 0
      IF op=ia_end DO
      { // IF end directive, free all temporary workspace
        LET p = blocklist
        blocklist := 0

        WHILE p DO
        { LET next = !p
          freevec(p)
          p := next
        }
        IF labv  DO { freevec(labv);  labv  := 0 }
        IF refv  DO { freevec(refv);  refv  := 0 }
        IF frefv DO { freevec(frefv); frefv := 0 }
      }
      RETURN

    CASE ia_nop:    f := #x90; ENDCASE       // nop
    CASE ia_popal:  f := #x61; ENDCASE       // ret
    CASE ia_popfl:  f := #x9D; ENDCASE       // ret
    CASE ia_pushal: f := #x60; ENDCASE       // ret
    CASE ia_pushfl: f := #x9C; ENDCASE       // ret
    CASE ia_ret:    f := #xC3; ENDCASE       // ret
  }
  ia_f(f)
}

AND iaK(op, k) BE
// alignc alignd datab datak push ret
{ db2wrf("        %s $%n*n", iaop2str(op), k)
//writef("iaK: op=%n (%s) k=%n*n", op, iaop2str(op), k)
  SWITCHON op INTO
  { DEFAULT:  iabadop(op, "K");    RETURN

    CASE ia_alignc:                        // alignc k
              UNLESS codep MOD k = 0 DO
              { db3codep()
                UNTIL codep MOD k = 0 DO iaC1(#x90) // nop
                db3nl()
              }
              RETURN

    CASE ia_alignd:                        // alignd k
              UNLESS datap MOD k = 0 DO
              { db3datap()
                UNTIL datap MOD k = 0 DO iaD1(#x00)
                db3nl()
              }
              RETURN

    CASE ia_datab:                        // datab k
              db3datap()
              iaD1(k)
              db3nl()
              RETURN

    CASE ia_datak:                        // datab k
              db3datap()
              iaD4(k)
              db3nl()
              RETURN

    CASE ia_entry:                        // entry fno
            { LET fno = k
              db3codep()
              db3wrf("F%n:*n", fno)
//writef("F%n=%n*n", fno, codep)
              fnv!fno := codep
              setrefs(frefv!fno, codep) // Deal with refs to this function
              frefv!fno := 0
              RETURN
            }

    CASE ia_pushl:                        // pushl $k
              db3codep()
              iaC1(#x68); iaC4(k)
              db3nl()
              RETURN

    CASE ia_ret:                          // ret $k
              db3codep()
              iaC1(#xC2); iaC2(k)
              db3nl()
              RETURN

  }
}

AND iaR(op, r) BE
// call decl divl idivl imull incl mull negl notl popl pushl
// seta setae setb setbe sete setg setge setl setle setne
{ LET rname = iarname(r)
  LET iaf, f, n = 0, 0, 0

  db2wrf("        %s  %s*n", iaop2str(op), rname)

  SWITCHON op INTO
  { DEFAULT:
      iabadop(op, "R")
      RETURN

    // iaR(ia_call,..) is not used
    CASE ia_call: iaf, f, n := ia_fnr, #xFF, 2; ENDCASE // call r

    CASE ia_decl: iaf, f    := ia_f,   #x48+r;  ENDCASE // decl r
    CASE ia_divl: iaf, f, n := ia_fnr, #xF7, 6; ENDCASE // divl r
    CASE ia_idivl:iaf, f, n := ia_fnr, #xF7, 7; ENDCASE // idivl r
    CASE ia_imull:iaf, f, n := ia_fnr, #xF7, 5; ENDCASE // imull r
    CASE ia_incl: iaf, f    := ia_f,   #x40+r;  ENDCASE // incl r
    CASE ia_mull: iaf, f, n := ia_fnr, #xF7, 4; ENDCASE // mull r
    CASE ia_negl: iaf, f, n := ia_fnr, #xF7, 3; ENDCASE // negl r
    CASE ia_notl: iaf, f, n := ia_fnr, #xF7, 2; ENDCASE // notl r
    CASE ia_popl: iaf, f    := ia_f,   #x58+r;  ENDCASE // popl r
    CASE ia_pushl:iaf, f    := ia_f,   #x50+r;  ENDCASE // pushl r

    CASE ia_sete: iaf, f    := ia_fnr, #x0F94;  ENDCASE // sete r
    CASE ia_setne:iaf, f    := ia_fnr, #x0F95;  ENDCASE // setne r
    CASE ia_setl: iaf, f    := ia_fnr, #x0F9C;  ENDCASE // setl r
    CASE ia_setle:iaf, f    := ia_fnr, #x0F9E;  ENDCASE // setle r
    CASE ia_setg: iaf, f    := ia_fnr, #x0F9F;  ENDCASE // setg r
    CASE ia_setge:iaf, f    := ia_fnr, #x0F9D;  ENDCASE // setge r
    CASE ia_seta: iaf, f    := ia_fnr, #x0F97;  ENDCASE // seta r
    CASE ia_setae:iaf, f    := ia_fnr, #x0F93;  ENDCASE // setae r
    CASE ia_setb: iaf, f    := ia_fnr, #x0F92;  ENDCASE // setb r
    CASE ia_setbe:iaf, f    := ia_fnr, #x0F96;  ENDCASE // setbe r
  }
  iaf(f, n, r)
}

AND iaL(op, n) BE
// datal dlab div idiv imul lab mul negl notl popl pushl
{
  db2wrf("        %s L%n*n", iaop2str(op), n)

  SWITCHON op INTO
  { // op with operand Ln using 32-bit relative address.

    DEFAULT:
      iabadop(op, "L")
      RETURN

    CASE ia_datal:
    { // Allocate a data word containing the value of label Ln
      LET mem = rootnode!rtn_mc0
      LET val = labv!n
      db3datap()
      TEST val
      THEN iaD4(mem + 4*mc + val)
      ELSE { iaD4(mem + 4*mc)
             refv!n := mk2(refv!n, datap)
           }
      db3nl()
      RETURN
    }

    CASE ia_dlab:
    { // Set a Ln to the current data location

      // Check if label limit reached..

      // Create a new label and store details in label vector.

      IF labv!n DO { // Check name is not already used.
        writef("Attempted to duplicate a label L%n", n)
        RETURN
      }

      db3datap()
      db3wrf("L%n:", n)
      labv!n := datap
      db3nl()
      // Resolve any outstanding refs to this label
      setrefs(refv!n, datap)
      refv!n := 0
      RETURN
    }

    CASE ia_lab: // Set a Ln to the current code location
    { // Check that the label is declared.
      UNLESS 0< n <= labvupb DO
      { writef("Error: Label number out of range: L%n*n", n)
        RETURN
      }

      IF labv!n DO // Check that the label is not already set.
      { writef("Error: Label L%n is already set to %n*n", n, labv!n)
        RETURN
      }

//writef("iaL: ia_lab L%n = %n refv!n=%n*n", n, labv!n, refv!n)
      db3codep()
      db3wrf("L%n:*n", n)
      labv!n := codep
      // resolve any outstanding refs to this label
      setrefs(refv!n, codep)
      refv!n := 0
      RETURN
    }

    CASE ia_mull: // unsigned multiply by static Ln
    { // Check that the label is declared.
      UNLESS 0< n <= labvupb DO
      { writef("Error: Label number out of range: L%n*n", n)
        RETURN
      }

      UNLESS labv!n DO // Check that static Ln is declared.
      { writef("Error: Static L%n is not declared*n", n)
        RETURN
      }

      ia_fnd(#xF7, 4, rootnode!rtn_mc0+4*mc+labv!n)
      RETURN
    }

    CASE ia_negl: // Negate static Ln
    { // Check that the label is declared.
      UNLESS 0< n <= labvupb DO
      { writef("Error: Label number out of range: L%n*n", n)
        RETURN
      }

      UNLESS labv!n DO // Check that static Ln is declared.
      { writef("Error: Static L%n is not declared*n", n)
        RETURN
      }

      ia_fnd(#xF7, 3, rootnode!rtn_mc0+4*mc+labv!n)
      RETURN
    }

    CASE ia_notl: // Complement static Ln
    { // Check that the label is declared.
      UNLESS 0< n <= labvupb DO
      { writef("Error: Label number out of range: L%n*n", n)
        RETURN
      }

      UNLESS labv!n DO // Check that static Ln is declared.
      { writef("Error: Static L%n is not declared*n", n)
        RETURN
      }

//writef("iaL: ia_lab L%n = %n refv!n=%n*n", n, labv!n, refv!n)
      ia_fnd(#xF7, 2, rootnode!rtn_mc0+4*mc+labv!n)
      RETURN
    }

    CASE ia_popl: // Pop the top of stack into static Ln
    { // Check that the label is declared.
      UNLESS 0< n <= labvupb DO
      { writef("Error: Label number out of range: L%n*n", n)
        RETURN
      }

      UNLESS labv!n DO // Check that static Ln is declared.
      { writef("Error: Static L%n is not declared*n", n)
        RETURN
      }

//writef("iaL: ia_lab L%n = %n refv!n=%n*n", n, labv!n, refv!n)
      ia_fnd(#x8F, 0, rootnode!rtn_mc0+4*mc+labv!n)
      RETURN
    }

    CASE ia_pushl: // Push static Ln onto the stack
    { // Check that the label is declared.
      UNLESS 0< n <= labvupb DO
      { writef("Error: Label number out of range: L%n*n", n)
        RETURN
      }

      UNLESS labv!n DO // Check that static Ln is declared.
      { writef("Error: Static L%n is not declared*n", n)
        RETURN
      }

//writef("iaL: ia_lab L%n = %n refv!n=%n*n", n, labv!n, refv!n)
      ia_fnd(#xFF, 6, rootnode!rtn_mc0+4*mc+labv!n)
      RETURN
    }
  }
}

AND iaFno(op, fno) BE
{ // call

  db2wrf("        %s  F%n*n", iaop2str(op), fno)

  SWITCHON op INTO
  { DEFAULT:      iabadop(op, "Fno");  RETURN

    CASE ia_call: ia_fno(#xE8, fno)
                  RETURN
  }
}

AND iaD(op, d) BE
{ // decl incl negl notl popl pushl shll shrl
  LET f, n = 0, 0

  db2wrf("        %s  %n*n", iaop2str(op), d)

  SWITCHON op INTO
  { DEFAULT:
      iabadop(op, "D")
      RETURN

    // iaD(ia_call,..) is only used by mcPRF
    CASE ia_call:  ia_fd(  #xE8, d); RETURN  // call d

    CASE ia_decl:  f, n := #xFF, 1;  ENDCASE // decl d
    CASE ia_divl:  f, n := #xF7, 6;  ENDCASE // divl d
    CASE ia_idivl: f, n := #xF7, 7;  ENDCASE // idivl d
    CASE ia_imull: f, n := #xF7, 5;  ENDCASE // imull d
    CASE ia_incl:  f, n := #xFF, 0;  ENDCASE // incl d
    CASE ia_mull:  f, n := #xF7, 4;  ENDCASE // mull d
    CASE ia_negl:  f, n := #xF7, 3;  ENDCASE // negl d
    CASE ia_notl:  f, n := #xF7, 2;  ENDCASE // notl d
    CASE ia_popl:  f, n := #x8F, 0;  ENDCASE // popl d
    CASE ia_pushl: f, n := #xFF, 6;  ENDCASE // pushl d
    CASE ia_shll:  f, n := #xD3, 4;  ENDCASE // shll d,%cl
    CASE ia_shrl:  f, n := #xD3, 5;  ENDCASE // shrl d,%cl
  }
  ia_fnd(f, n, d)
}

AND iaDX(op, d, x) BE
// call decl divl idivl imull incl mull negl notl popl pushl shll shrl
{ LET xname = iarname(x)
  LET f, n = 0, 0

  db2wrf("        %s  %n(%s)*n", iaop2str(op), d, xname)

  SWITCHON op INTO
  { DEFAULT: iabadop(op, "DX"); RETURN

    // iaDX(ia_call,..) is not used
    CASE ia_call: f, n := #xFF, 2; ENDCASE // call d(x)

    CASE ia_decl:  f, n := #xFF, 1; ENDCASE // decl d(x)
    CASE ia_divl:  f, n := #xF7, 6; ENDCASE // divl d(x)
    CASE ia_idivl: f, n := #xF7, 7; ENDCASE // idivl d(x)
    CASE ia_imull: f, n := #xF7, 5; ENDCASE // idivl d(x)
    CASE ia_incl:  f, n := #xFF, 0; ENDCASE // incl d(x)
    CASE ia_mull:  f, n := #xF7, 4; ENDCASE // mull d(x)
    CASE ia_negl:  f, n := #xF7, 3; ENDCASE // negl d(x)
    CASE ia_notl:  f, n := #xF7, 2; ENDCASE // notl d(x)
    CASE ia_popl:  f, n := #x8F, 0; ENDCASE // popl d(x)
    CASE ia_pushl: f, n := #xFF, 6; ENDCASE // pushl d(x)
    CASE ia_shll:  f, n := #xD3, 4; ENDCASE // shll d(x),%cl
    CASE ia_shrl:  f, n := #xD3, 5; ENDCASE // shrl d(x),%cl
  }
  ia_fndx(f, n, d, x)
}

AND iaDXs(op, d, x, s) BE
{ LET xname = iarname(x)
  LET f, n = 0, 0

  db2wrf("        %s  %n(%s**%n)*n", iaop2str(op), d, xname, s)

  SWITCHON op INTO
  { DEFAULT:
      iabadop(op, "DXs")
      RETURN

    // iaDXs(ia_call,..) is not used
    CASE ia_call:  f, n := #xFF, 2; ENDCASE // call d(,x,s)

    CASE ia_decl:  f, n := #xFF, 1; ENDCASE // decl d(,x,s)
    CASE ia_divl:  f, n := #xF7, 6; ENDCASE // divl d(,x,s)
    CASE ia_idivl: f, n := #xF7, 7; ENDCASE // idivl d(,x,s)
    CASE ia_imull: f, n := #xF7, 5; ENDCASE // idivl d(,x,s)
    CASE ia_incl:  f, n := #xFF, 0; ENDCASE // incl d(,x,s)
    CASE ia_mull:  f, n := #xF7, 4; ENDCASE // mull d(,x,s)
    CASE ia_negl:  f, n := #xF7, 3; ENDCASE // negl d(,x,s)
    CASE ia_notl:  f, n := #xF7, 2; ENDCASE // notl d(,x,s)
    CASE ia_popl:  f, n := #x8F, 0; ENDCASE // popl d(,x,s)
    CASE ia_pushl: f, n := #xFF, 6; ENDCASE // pushl d(,x,s)
    CASE ia_shll:  f, n := #xD3, 4; ENDCASE // shll d(,x,s),%cl
    CASE ia_shrl:  f, n := #xD3, 5; ENDCASE // shrl d(,x,s),%cl
  }
  ia_fndxs(f, n, d, x, s)
}

AND iaDXsB(op, d, x, s, b) BE
{ LET xname = iarname(x)
  LET bname = iarname(b)
  LET f, n = 0, 0

  db2wrf("        %s  %n(%s, %s, %n)*n", iaop2str(op), d, bname, xname, s)

  SWITCHON op INTO
  { DEFAULT:
      iabadop(op, "DXsB")
      RETURN

    // iaDXsB(ia_call,..) is not used
    CASE ia_call:  f, n := #xFF, 2; ENDCASE // call d(b,x,s)

    CASE ia_decl:  f, n := #xFF, 1; ENDCASE // decl d(b,x,s)
    CASE ia_divl:  f, n := #xF7, 6; ENDCASE // divl d(b,x,s)
    CASE ia_idivl: f, n := #xF7, 7; ENDCASE // idivl d(b,x,s)
    CASE ia_imull: f, n := #xF7, 5; ENDCASE // idivl d(b,x,s)
    CASE ia_incl:  f, n := #xFF, 0; ENDCASE // incl d(b,x,s)
    CASE ia_mull:  f, n := #xF7, 4; ENDCASE // mull d(b,x,s)
    CASE ia_negl:  f, n := #xF7, 3; ENDCASE // negl d(b,x,s)
    CASE ia_notl:  f, n := #xF7, 2; ENDCASE // notl d(b,x,s)
    CASE ia_popl:  f, n := #x8F, 0; ENDCASE // popl d(b,x,s)
    CASE ia_pushl: f, n := #xFF, 6; ENDCASE // pushl d(b,x,s)
    CASE ia_shll:  f, n := #xD3, 4; ENDCASE // shll d(b,x,s),%cl
    CASE ia_shrl:  f, n := #xD3, 5; ENDCASE // shrl d(b,x,s),%cl
  }
  ia_fndxsb(f, n, d, x, s, b)
}

AND iaRR(op, r, t) BE // r is destination
// addl addcl andl movl movsbl movzbl orl sbbl shll shrl subl xorl 
{ LET rname = iarname(r)
  LET tname = iarname(t)
  LET f = 0

  db2wrf("        %s  %s, %s*n", iaop2str(op), tname, rname)

  SWITCHON op INTO
  { DEFAULT:      iabadop(op, "RR"); RETURN

    CASE ia_addl: f := #x01; ENDCASE          // addl t,r
    CASE ia_addcl:f := #x11; ENDCASE          // addcl t,r
    CASE ia_andl: f := #x21; ENDCASE          // andl t,r
    CASE ia_movl: UNLESS r=t DO
                    ia_fnr(#x89, t, r)        // movl t,r
                  RETURN

    CASE ia_movsbl: ia_fnr(#x0FBE,r,t); RETURN // movsbl t,r
    CASE ia_movswl: ia_fnr(#x0FBF,r,t); RETURN // movswl t,r
    CASE ia_movzbl: ia_fnr(#x0FB6,r,t); RETURN // movzbl t,r
    CASE ia_movzwl: ia_fnr(#x0FB7,r,t); RETURN // movzbl t,r

    CASE ia_orl:    f := #x09; ENDCASE        // orl t,r
    CASE ia_shll:   UNLESS t=Ecx DO
                    { writef("Shift amount must be in C*n")
                      RETURN
                    }
                    f := #xD3; t:=4; ENDCASE  // shll t,%cl
    CASE ia_shrl:   UNLESS t=Ecx DO
                    { writef("Shift amount must be in C*n")
                      RETURN
                    }
                    f := #xD3; t:=7; ENDCASE  // shll t,%cl
    CASE ia_sbbl:   f := #x19; ENDCASE        // sbbl t,r
    CASE ia_subl:   f := #x29; ENDCASE        // subl t,r
    CASE ia_xchgl:  IF r=Eax DO { ia_f(#x90+t); RETURN }
                    IF t=Eax DO { ia_f(#x90+r); RETURN }
                    f := #x87; ENDCASE        // xchgl t,r
    CASE ia_xorl:   f := #x31; ENDCASE        // xorl t,r
  }
  ia_fnr(f, t, r) // r is the destination
}

AND iaRK(op, r, k) BE
// addl addcl andl cmpl movl orl sbbl shll shrl subl xorl 
{ LET rname = iarname(r)
  SWITCHON op INTO
  { DEFAULT:
      iabadop(op, "RK")
      RETURN

    CASE ia_addl:
      db2wrf("        addl $%n, %s*n", k, rname)
      TEST -128<=k<=127
      THEN ia_fnrk1(#x83, 0, r, k)        // addl $k, r
      ELSE TEST r=Eax
           THEN ia_fk4(#x05, k)           // addl $k,%eax
           ELSE ia_fnrk4(#x81, 0, r, k)   // addl $k, r
      RETURN

    CASE ia_addcl:
      db2wrf("        addcl $%n, %s*n", k, rname)
      TEST -128<=k<=127
      THEN ia_fnrk1(#x83, 2, r, k)        // addcl $k, r
      ELSE TEST r=Eax
           THEN ia_fk4(#x15, k)           // addcl $k,%eax
           ELSE ia_fnrk4(#x81, 2, r, k)   // addcl $k, r
      RETURN

    CASE ia_andl:
      db2wrf("        andl $%n, %s*n", k, rname)
      TEST -128<=k<=127
      THEN ia_fnrk1(#x83, 4, r, k)        // andl $k, r
      ELSE TEST r=Eax
           THEN ia_fk4(#x25, k)           // andl $k,%eax
           ELSE ia_fnrk4(#x81, 4, r, k)   // andl $k, r
      RETURN

    CASE ia_cmpl:
      db2wrf("        cmpl $%n, %s*n", k, rname)
      TEST -128<=k<=127
      THEN ia_fnrk1(#x83, 7, r, k)        // cmpl $k, r
      ELSE TEST r=Eax
           THEN ia_fk4(#x35, k)           // cmpl $k,%eax
           ELSE ia_fnrk4(#x81, 7, r, k)   // cmpl $k, r
      RETURN

    CASE ia_movl:
      db2wrf("        movl $%n, %s*n", k, rname)
      ia_fk4(#xB8+r, k)         // movl $k, r
      RETURN

    CASE ia_orl:
      db2wrf("        orl $%n, %s*n", k, rname)
      TEST -128<=k<=127
      THEN ia_fnrk1(#x83, 1, r, k)        // orl $k, r
      ELSE TEST r=Eax
           THEN ia_fk4(#x0D, k)           // orl $k,%eax
           ELSE ia_fnrk4(#x81, 1, r, k)   // orl $k, r
      RETURN

    CASE ia_shll:
      db2wrf("        shll $%n, %s*n", k, rname)
      IF k=0 RETURN
      TEST k=1
      THEN ia_fnr(#xD1, 4, r)             // shll $1, r
      ELSE ia_fnrk1(#xC1, 4, r, k)        // shll $k, r
      RETURN

    CASE ia_shrl:
      db2wrf("        shrl $%n, %s*n", k, rname)
      IF k=0 RETURN
      TEST k=1
      THEN ia_fnr(#xD1, 5, r)             // shll $1, r
      ELSE ia_fnrk1(#xC1, 5, r, k)        // shll $k, r
      RETURN

    CASE ia_sbbl:
      db2wrf("        sbbl $%n, %s*n", k, rname)
      TEST -128<=k<=127
      THEN ia_fnrk1(#x83, 3, r, k)        // sbbl $k, r
      ELSE TEST r=Eax
           THEN ia_fk4(#x1D, k)           // sbbl $k,%eax
           ELSE ia_fnrk4(#x81, 3, r, k)   // sbbl $k, r
      RETURN

    CASE ia_subl:
      db2wrf("        subl $%n, %s*n", k, rname)
      TEST -128<=k<=127
      THEN ia_fnrk1(#x83, 5, r, k)        // subl $k, r
      ELSE TEST r=Eax
           THEN ia_fk4(#x2D, k)           // subl $k,%eax
           ELSE ia_fnrk4(#x81, 5, r, k)   // subl $k, r
      RETURN

    CASE ia_xorl:
      db2wrf("        xorl $%n, %s*n", k, rname)
      TEST -128<=k<=127
      THEN ia_fnrk1(#x83, 6, r, k)        // xorl $k, r
      ELSE TEST r=Eax
           THEN ia_fk4(#x35, k)           // xorl $k,%eax
           ELSE ia_fnrk4(#x81, 6, r, k)   // xorl $k, r
      RETURN
  }
}

AND iaRL(op, r, n) BE
// addl andl cmpl leal movl movsbl movswl movzxbl movzwl
// orl subl xchgl xorl
{ // r is destination (but cmpl does not update r)
  LET rname = iarname(r)
  LET mem = rootnode!rtn_mc0
  LET val = labv!n
  LET d = mem+4*mc+val
  LET f = 0

  db2wrf("        %s %n,%s*n", iaop2str(op), d, rname)

  UNLESS val DO
  { writef("Error: Data label not declared: %i5: %s L%n,%s*n",
            iaop2str(op), n, rname)
    RETURN
  }

  SWITCHON op INTO
  { DEFAULT:       iabadop(op, "RL");  RETURN

    CASE ia_addl:   f := #x03;   ENDCASE  // addl Ln,r
    CASE ia_addcl:  f := #x13;   ENDCASE  // addcl Ln,r
    CASE ia_andl:   f := #x23;   ENDCASE  // andl Ln,r
    CASE ia_cmpl:   f := #x3B;   ENDCASE  // cmpl Ln,r
    CASE ia_leal:   f := #x8D;   ENDCASE  // leal Ln,r
    CASE ia_movl:   IF r=Eax DO
                    { ia_fd(#xA1, d)
                      RETURN
                    }
                    f := #x8B;   ENDCASE  // movl Ln,r
    CASE ia_movsbl: f := #x0FBE; ENDCASE  // movsbl Ln,r
    CASE ia_movswl: f := #x0FBF; ENDCASE  // movswl Ln,r
    CASE ia_movzbl: f := #x0FB6; ENDCASE  // movzbl Ln,r
    CASE ia_movzwl: f := #x0FB7; ENDCASE  // movzwl Ln,r
    CASE ia_orl:    f := #x0B;   ENDCASE  // orl Ln,r
    CASE ia_sbbl:   f := #x1B;   ENDCASE  // sbbl Ln,r
    CASE ia_subl:   f := #x2B;   ENDCASE  // subl Ln,r
    CASE ia_xchgl:  f := #x87;   ENDCASE  // xchgl Ln,r
    CASE ia_xorl:   f := #x33;   ENDCASE  // xorl Ln,r
  }
//writef("m/c address = %n*n", mem+4*mc+val)
  ia_fnd(f, r, d)       // eg addl %eax,Ln
//abort(1000)
}

AND iaRD(op, r, d) BE
// addl addcl andl cmpl leal movl movsbl movswl movzxbl movzwl
// orl sbbl subl xchgl xorl
{ // r is destination (but cmpl does not update r)
  LET rname = iarname(r)
  LET f = 0

  db2wrf("        %s %n,%s*n", iaop2str(op), d, rname)

  SWITCHON op INTO
  { DEFAULT:       iabadop(op, "RD");  RETURN

    CASE ia_addl:   f := #x03;   ENDCASE  // addl d,r
    CASE ia_addcl:  f := #x13;   ENDCASE  // addcl d,r
    CASE ia_andl:   f := #x23;   ENDCASE  // andl d,r
    CASE ia_cmpl:   f := #x3B;   ENDCASE  // cmpl d,r
    CASE ia_leal:   f := #x8D;   ENDCASE  // leal d,r
    CASE ia_movl:   f := #x8B;   ENDCASE  // movl d,r
    CASE ia_movsbl: f := #x0FBE; ENDCASE  // movsbl d,r
    CASE ia_movswl: f := #x0FBF; ENDCASE  // movswl d,r
    CASE ia_movzbl: f := #x0FB6; ENDCASE  // movzbl d,r
    CASE ia_movzwl: f := #x0FB7; ENDCASE  // movzwl d,r
    CASE ia_orl:    f := #x0B;   ENDCASE  // orl d,r
    CASE ia_sbbl:   f := #x1B;   ENDCASE  // sbbl d,r
    CASE ia_subl:   f := #x2B;   ENDCASE  // subl d,r
    CASE ia_xchgl:  f := #x87;   ENDCASE  // xchgl d,r
    CASE ia_xorl:   f := #x33;   ENDCASE  // xorl d,r
  }
  ia_fnd(f, r, d)         // eg addl 63, %eax
}

AND iaRDX(op, r, d, x) BE
// addl addcl andl cmpl leal movl movsbl movswl movzxbl movzwl
// orl sbbl subl xchgl xorl
{ // r is destination (but cmpl does not update r)
  LET rname = iarname(r)
  LET xname = iarname(x)
  LET f = 0

  db2wrf("        %s %n(%s),%s*n", iaop2str(op), d, xname, rname)

  SWITCHON op INTO
  { DEFAULT:        iabadop(op, "RDX");  RETURN

    CASE ia_addl:   f := #x03;   ENDCASE  // addl d(x),r
    CASE ia_addcl:  f := #x13;   ENDCASE  // addcl d(x),r
    CASE ia_andl:   f := #x23;   ENDCASE  // andl d(x),r
    CASE ia_cmpl:   f := #x3B;   ENDCASE  // cmpl d(x),r
    CASE ia_leal:   f := #x8D;   ENDCASE  // leal d(x),r
    CASE ia_movl:   f := #x8B;   ENDCASE  // movl d(x),r
    CASE ia_movsbl: f := #x0FBE; ENDCASE  // movsbl d(x),r
    CASE ia_movswl: f := #x0FBF; ENDCASE  // movswl d(x),r
    CASE ia_movzbl: f := #x0FB6; ENDCASE  // movzbl d(x),r
    CASE ia_movzwl: f := #x0FB7; ENDCASE  // movzwl d(x),r
    CASE ia_orl:    f := #x0B;   ENDCASE  // orl d(x),r
    CASE ia_sbbl:   f := #x1B;   ENDCASE  // sbbl d(x),r
    CASE ia_subl:   f := #x2B;   ENDCASE  // subl d(x),r
    CASE ia_xchgl:  f := #x87;   ENDCASE  // xchgl d(x),r
    CASE ia_xorl:   f := #x33;   ENDCASE  // xorl d(x),r
  }
  ia_fndx(f, r, d, x)         // eg addl 63(%ebx), %eax
}

AND iaRDXs(op, r, d, x, s) BE
{ LET rname = iarname(r)
  LET xname = iarname(x)
  LET f = 0

  db2wrf("        %s %n(,%s,%n),%s*n", iaop2str(op), d, xname, s, rname)

  SWITCHON op INTO
  { DEFAULT:        iabadop(op, "RDXs");  RETURN

    CASE ia_addl:   f := #x03;   ENDCASE  // addl d(,x,s),r
    CASE ia_addcl:  f := #x13;   ENDCASE  // addcl d(,x,s),r
    CASE ia_andl:   f := #x23;   ENDCASE  // andl d(,x,s),r
    CASE ia_cmpl:   f := #x3B;   ENDCASE  // cmpl d(,x,s),r
    CASE ia_leal:   f := #x8D;   ENDCASE  // leal d(,x,s),r
    CASE ia_movl:   f := #x8B;   ENDCASE  // movl d(,x,s),r
    CASE ia_movsbl: f := #x0FBE; ENDCASE  // movsbl d(,x,s),r
    CASE ia_movswl: f := #x0FBF; ENDCASE  // movswl d(,x,s),r
    CASE ia_movzbl: f := #x0FB6; ENDCASE  // movzbl d(,x,s),r
    CASE ia_movzwl: f := #x0FB7; ENDCASE  // movzwl d(,x,s),r
    CASE ia_orl:    f := #x0B;   ENDCASE  // orl d(,x,s),r
    CASE ia_sbbl:   f := #x1B;   ENDCASE  // sbbl d(,x,s),r
    CASE ia_subl:   f := #x2B;   ENDCASE  // subl d(,x,s),r
    CASE ia_xchgl:  f := #x87;   ENDCASE  // xchgl d(,x,s),r
    CASE ia_xorl:   f := #x33;   ENDCASE  // xorl d(,x,s),r
  }
  ia_fndxs(f, r, d, x, s)         // eg addl 64(,%ebx,4), %eax
}

AND iaRDXsB(op, r, d, x, s, b) BE
{ // eg: movl 24(%edx,%edi,4),%ebx
  LET rname = iarname(r)
  LET xname = iarname(x)
  LET bname = iarname(b)
  LET f = 0

  db2wrf("        %s %n(%s,%s,%n),%s*n", iaop2str(op), d, bname, xname, s, rname)

  SWITCHON op INTO
  { DEFAULT:        iabadop(op, "RDXsB");  RETURN

    CASE ia_addl:   f := #x03;   ENDCASE  // addl d(b,x,s),r
    CASE ia_addcl:  f := #x13;   ENDCASE  // addcl d(b,x,s),r
    CASE ia_andl:   f := #x23;   ENDCASE  // andl d(b,x,s),r
    CASE ia_cmpl:   f := #x3B;   ENDCASE  // cmpl d(b,x,s),r
    CASE ia_leal:   f := #x8D;   ENDCASE  // leal d(b,x,s),r
    CASE ia_movl:   f := #x8B;   ENDCASE  // movl d(b,x,s),r
    CASE ia_movsbl: f := #x0FBE; ENDCASE  // movsbl d(b,x,s),r
    CASE ia_movswl: f := #x0FBF; ENDCASE  // movswl d(b,x,s),r
    CASE ia_movzbl: f := #x0FB6; ENDCASE  // movzbl d(b,x,s),r
    CASE ia_movzwl: f := #x0FB7; ENDCASE  // movzwl d(b,x,s),r
    CASE ia_orl:    f := #x0B;   ENDCASE  // orl d(b,x,s),r
    CASE ia_sbbl:   f := #x1B;   ENDCASE  // sbbl d(b,x,s),r
    CASE ia_subl:   f := #x2B;   ENDCASE  // subl d(b,x,s),r
    CASE ia_xchgl:  f := #x87;   ENDCASE  // xchgl d(b,x,s),r
    CASE ia_xorl:   f := #x33;   ENDCASE  // xorl d(b,x,s),r
  }
  ia_fndxsb(f, r, d, x, s, b)   // eg addl 64(%edx,%ebx,4), %eax
}

AND iaDR(op, d, r) BE
{ // memory is the destination
  // eg: addl %ebx,24
  LET rname = iarname(r)
  LET f = 0

  db2wrf("        %s %s,%n*n", iaop2str(op), rname, d)

  SWITCHON op INTO
  { DEFAULT:        iabadop(op, "DR");  RETURN

    CASE ia_addl:   f := #x01;   ENDCASE  // addl r,d
    CASE ia_addcl:  f := #x11;   ENDCASE  // addcl r,d
    CASE ia_andl:   f := #x21;   ENDCASE  // andl r,d
    CASE ia_cmpl:   f := #x39;   ENDCASE  // cmpl r,d
    CASE ia_movb:   f := #x88;   ENDCASE  // movb r,d
    CASE ia_movl:   f := #x89;   ENDCASE  // movl r,d
    CASE ia_movw:   f := #x6689; ENDCASE  // movw r,d
    CASE ia_movsbl: f := #x0FBE; ENDCASE  // movsbl r,d
    CASE ia_movswl: f := #x0FBF; ENDCASE  // movswl r,d
    CASE ia_movzbl: f := #x0FB6; ENDCASE  // movzbl r,d
    CASE ia_movzwl: f := #x0FB7; ENDCASE  // movzwl r,d
    CASE ia_orl:    f := #x09;   ENDCASE  // orl r,d
    CASE ia_sbbl:   f := #x19;   ENDCASE  // sbbl r,d
    CASE ia_subl:   f := #x29;   ENDCASE  // subl r,d
    CASE ia_xchgl:  f := #x87;   ENDCASE  // xchgl r,d
    CASE ia_xorl:   f := #x31;   ENDCASE  // xorl r,d
  }
  ia_fnd(f, r, d)   // eg addl %eax,64
}

AND iaDXR(op, d, x, r) BE
{ // memory is the destination
  // eg: addl %ebx,24(%edx)
  LET rname = iarname(r)
  LET xname = iarname(x)
  LET f = 0

  db2wrf("        %s %s,%n(%s)*n", iaop2str(op), rname, d, xname)

  SWITCHON op INTO
  { DEFAULT:        iabadop(op, "DXR");  RETURN

    CASE ia_addl:   f := #x01;   ENDCASE  // addl r,d(x)
    CASE ia_addcl:  f := #x11;   ENDCASE  // addcl r,d(x)
    CASE ia_andl:   f := #x21;   ENDCASE  // andl r,d(x)
    CASE ia_cmpl:   f := #x39;   ENDCASE  // cmpl r,d(x)
    CASE ia_movb:   f := #x88;   ENDCASE  // movb r,d(x)
    CASE ia_movl:   f := #x89;   ENDCASE  // movl r,d(x)
    CASE ia_movw:   f := #x6689; ENDCASE  // movw r,d(x)
    CASE ia_movsbl: f := #x0FBE; ENDCASE  // movsbl r,d(x)
    CASE ia_movswl: f := #x0FBF; ENDCASE  // movswl r,d(x)
    CASE ia_movzbl: f := #x0FB6; ENDCASE  // movzbl r,d(x)
    CASE ia_movzwl: f := #x0FB7; ENDCASE  // movzwl r,d(x)
    CASE ia_orl:    f := #x09;   ENDCASE  // orl r,d(x)
    CASE ia_sbbl:   f := #x19;   ENDCASE  // sbbl r,d(x)
    CASE ia_subl:   f := #x29;   ENDCASE  // subl r,d(x)
    CASE ia_xchgl:  f := #x87;   ENDCASE  // xchgl r,d(x)
    CASE ia_xorl:   f := #x31;   ENDCASE  // xorl r,d(x)
  }
  ia_fndx(f, r, d, x)   // eg addl %eax,64(%ebp)
}

AND iaDXsR(op, d, x, s, r) BE
{ // memory is the destination
  // eg: addl %ebx,24(,%edi,4)
  LET rname = iarname(r)
  LET xname = iarname(x)
  LET f = 0

  db2wrf("        %s %s,%n(,%s,%n)*n", iaop2str(op), rname, d, xname, s)

  SWITCHON op INTO
  { DEFAULT:        iabadop(op, "RDXsR");  RETURN

    CASE ia_addl:   f := #x01;   ENDCASE  // addl r,d(,x,s)
    CASE ia_addcl:  f := #x11;   ENDCASE  // addcl r,d(,x,s)
    CASE ia_andl:   f := #x21;   ENDCASE  // andl r,d(,x,s)
    CASE ia_cmpl:   f := #x39;   ENDCASE  // cmpl r,d(,x,s)
    CASE ia_movb:   f := #x88;   ENDCASE  // movb r,d(,x,s)
    CASE ia_movl:   f := #x89;   ENDCASE  // movl r,d(,x,s)
    CASE ia_movw:   f := #x6689; ENDCASE  // movw r,d(,x,s)
    CASE ia_movsbl: f := #x0FBE; ENDCASE  // movsbl r,d(,x,s)
    CASE ia_movswl: f := #x0FBF; ENDCASE  // movswl r,d(,x,s)
    CASE ia_movzbl: f := #x0FB6; ENDCASE  // movzbl r,d(,x,s)
    CASE ia_movzwl: f := #x0FB7; ENDCASE  // movzwl r,d(,x,s)
    CASE ia_orl:    f := #x09;   ENDCASE  // orl r,d(,x,s)
    CASE ia_sbbl:   f := #x19;   ENDCASE  // sbbl r,d(,x,s)
    CASE ia_subl:   f := #x29;   ENDCASE  // subl r,d(,x,s)
    CASE ia_xchgl:  f := #x87;   ENDCASE  // xchgl r,d(,x,s)
    CASE ia_xorl:   f := #x31;   ENDCASE  // xorl r,d(,x,s)
  }
  ia_fndxs(f, r, d, x, s)   // eg addl %eax,64(,%ebx,4)
}

AND iaDXsBR(op, d, x, s, b, r) BE
{ // memory is the destination
  // eg: addl %ebx,24(%edx,%edi,4)
  LET rname = iarname(r)
  LET xname = iarname(x)
  LET bname = iarname(b)
  LET f = 0

  db2wrf("        %s %s,%n(%s,%s,%n)*n", iaop2str(op), rname, d, bname, xname, s)

  SWITCHON op INTO
  { DEFAULT:        iabadop(op, "RDXsBR");  RETURN

    CASE ia_addl:   f := #x01;   ENDCASE  // addl r,d(b,x,s)
    CASE ia_addcl:  f := #x11;   ENDCASE  // addcl r,d(b,x,s)
    CASE ia_andl:   f := #x21;   ENDCASE  // andl r,d(b,x,s)
    CASE ia_cmpl:   f := #x39;   ENDCASE  // cmpl r,d(b,x,s)
    CASE ia_movb:   f := #x88;   ENDCASE  // movb r,d(b,x,s)
    CASE ia_movl:   f := #x89;   ENDCASE  // movl r,d(b,x,s)
    CASE ia_movw:   f := #x6689; ENDCASE  // movw r,d(b,x,s)
    CASE ia_movsbl: f := #x0FBE; ENDCASE  // movsbl r,d(b,x,s)
    CASE ia_movswl: f := #x0FBF; ENDCASE  // movswl r,d(b,x,s)
    CASE ia_movzbl: f := #x0FB6; ENDCASE  // movzbl r,d(b,x,s)
    CASE ia_movzwl: f := #x0FB7; ENDCASE  // movzwl r,d(b,x,s)
    CASE ia_orl:    f := #x09;   ENDCASE  // orl r,d(b,x,s)
    CASE ia_sbbl:   f := #x19;   ENDCASE  // sbbl r,d(b,x,s)
    CASE ia_subl:   f := #x29;   ENDCASE  // subl r,d(b,x,s)
    CASE ia_xchgl:  f := #x87;   ENDCASE  // xchgl r,d(b,x,s)
    CASE ia_xorl:   f := #x31;   ENDCASE  // xorl r,d(b,x,s)
  }
  ia_fndxsb(f, r, d, x, s, b)   // eg addl %eax,64(%edx,%ebx,4)
}

AND iaDK(op, d, k) BE
{ // addl addc andl movb movl movw orl sbbl shll shrl subl xorl
  // Memory is the destination with k as source
  // eg: addl $20,24
  LET f8, f32, n = 0, 0, 0

  db2wrf("        %s $%n,%n*n", iaop2str(op), k, d)

  SWITCHON op INTO
  { DEFAULT:
      iabadop(op, "DK")
      RETURN

    CASE ia_addl:  f8, f32, n := #x83, #x81, 0; ENDCASE // addl $k,d
    CASE ia_addcl: f8, f32, n := #x83, #x81, 2; ENDCASE // addcl $k,d
    CASE ia_andl:  f8, f32, n := #x83, #x81, 4; ENDCASE // andl $k,d
    CASE ia_cmpl:  f8, f32, n := #x83, #x81, 7; ENDCASE // cmpl $k,d
    CASE ia_movb:  ia_fdk1(#xC6,d,k);           RETURN  // movl $k,d
    CASE ia_movl:  ia_fdk4(#xC7,d,k);           RETURN  // movl $k,d
    CASE ia_movw:  ia_fdk2(#x66C7,d,k);         RETURN  // movl $k,d
    CASE ia_orl:   f8, f32, n := #x83, #x81, 1; ENDCASE // orl  $k,d
    CASE ia_shll:  UNLESS 0<=k<=31 DO
                   { ia_fdk4(#xC7,d,0)                  // movl $0,d
                     RETURN
                   }
                   f8,      n := #xC0,       5; ENDCASE // shll $k,d
    CASE ia_shrl:  UNLESS 0<=k<=31 DO
                   { ia_fdk4(#xC7,d,0)                  // movl $0,d
                     RETURN
                   }
                   f8,      n := #xC1,       5; ENDCASE // shll $k,d
    CASE ia_sbbl:  f8, f32, n := #x83, #x81, 3; ENDCASE // sbbl $k,d
    CASE ia_subl:  f8, f32, n := #x83, #x81, 5; ENDCASE // subl $k,d
    CASE ia_xorl:  f8, f32, n := #x83, #x81, 6; ENDCASE // xorl $k,d
  }
  TEST -128<=k<127
  THEN ia_fndk1(f8,  n, d, k)
  ELSE ia_fndk4(f32, n, d, k)
}

AND iaDXK(op, d, x, k) BE
{ // addl addcl andl cmpl movb movl movw orl sbbl shll shrl subl xorl
  // Memory is the destination with k as source
  // eg: addl $20,24(%edi)
  LET xname = iarname(x)
  LET f8, f32, n = 0, 0, 0

  db2wrf("        %s $%n,%n(%s)*n", iaop2str(op), k, d, xname)

  SWITCHON op INTO
  { DEFAULT:
      iabadop(op, "DXK")
      RETURN

    CASE ia_addl:  f8, f32, n := #x83, #x81, 0; ENDCASE // addl $k,d(x)
    CASE ia_addcl: f8, f32, n := #x83, #x81, 2; ENDCASE // addcl $k,d(x)
    CASE ia_andl:  f8, f32, n := #x83, #x81, 4; ENDCASE // andl $k,d(x)
    CASE ia_cmpl:  f8, f32, n := #x83, #x81, 7; ENDCASE // cmpl $k,d(x)
    CASE ia_movb:  ia_fdxk1(#xC6,d,x,k)                 // movb $k,d(x)
                   RETURN
    CASE ia_movl:  ia_fdxk4(#xC7,d,x,k)                 // movl $k,d(x)
                   RETURN
    CASE ia_movw:  ia_fdxk2(#x66C7,d,x,k)               // movw $k,d(x)
                   RETURN
    CASE ia_orl:   f8, f32, n := #x83, #x81, 1; ENDCASE // orl  $k,d(x)
    CASE ia_shll:  UNLESS 0<=k<=31 DO
                   { ia_fdxk4(#xC7,d,x,0)               // movl $0,d(x)
                     RETURN
                   }
                   f8,      n := #xC0,       5; ENDCASE // shll $k,d(x)
    CASE ia_shrl:  UNLESS 0<=k<=31 DO
                   { ia_fdxk4(#xC7,d,x,0)               // movl $0,d(x)
                     RETURN
                   }
                   f8,      n := #xC1,       5; ENDCASE // shll $k,d(x)
    CASE ia_sbbl:  f8, f32, n := #x83, #x81, 3; ENDCASE // sbbl $k,d(x)
    CASE ia_subl:  f8, f32, n := #x83, #x81, 5; ENDCASE // subl $k,d(x)
    CASE ia_xorl:  f8, f32, n := #x83, #x81, 6; ENDCASE // xorl $k,d(x)
  }
  TEST -128<=k<127
  THEN ia_fndxk1(f8,  n, d, x, k)
  ELSE ia_fndxk4(f32, n, d, x, k)
}

AND iaDXsK(op, d, x, s, k) BE
{ // addl addcl andl cmpl movl orl sbbl shll shrl subl xorl
  // Memory is the destination with k as source
  // eg: addl $20,24(,%edi,4)
  LET xname = iarname(x)
  LET f8, f32, n = 0, 0, 0

  db2wrf("        %s $%n,%n(,%s,%n)*n", iaop2str(op), k, d, xname, s)

  SWITCHON op INTO
  { DEFAULT:       iabadop(op, "DXsK"); RETURN

    CASE ia_addl:  f8, f32, n := #x83, #x81, 0; ENDCASE // addl $k,d(,x,s)
    CASE ia_addcl: f8, f32, n := #x83, #x81, 2; ENDCASE // addcl $k,d(,x,s)
    CASE ia_andl:  f8, f32, n := #x83, #x81, 4; ENDCASE // andl $k,d(,x,s)
    CASE ia_cmpl:  f8, f32, n := #x83, #x81, 7; ENDCASE // cmpl $k,d(,x,s)
    CASE ia_movb:  ia_fdxsk1(#xC6,d,x,s,k);     RETURN  // movb $k,d(,x,s)
    CASE ia_movl:  ia_fdxsk4(#xC7,d,x,s,k);     RETURN  // movl $k,d(b,x,s)
    CASE ia_movw:  ia_fdxsk2(#x66C7,d,x,s,k);   RETURN  // movw $k,d(,x,s)
    CASE ia_orl:   f8, f32, n := #x83, #x81, 1; ENDCASE // orl  $k,d(,x,s)
    CASE ia_shll:  UNLESS 0<=k<=31 DO
                   { ia_fdxsk4(#xC7,d,x,s,0)            // movl $0,d(,x,s)
                     RETURN
                   }
                   f8,      n := #xC0,       5; ENDCASE // shll $k,d(,x,s)
    CASE ia_shrl:  UNLESS 0<=k<=31 DO
                   { ia_fdxsk4(#xC7,d,x,s,0)            // movl $0,d(,x,s)
                     RETURN
                   }
                   f8,      n := #xC1,       5; ENDCASE // shll $k,d(,x,s)
    CASE ia_sbbl:  f8, f32, n := #x83, #x81, 3; ENDCASE // sbbl $k,d(,x,s)
    CASE ia_subl:  f8, f32, n := #x83, #x81, 5; ENDCASE // subl $k,d(,x,s)
    CASE ia_xorl:  f8, f32, n := #x83, #x81, 6; ENDCASE // xorl $k,d(,x,s)
  }
  TEST -128<=k<127
  THEN ia_fndxsk1(f8,  n, d, x, s, k)
  ELSE ia_fndxsk4(f32, n, d, x, s, k)
}

AND iaDXsBK(op, d, x, s, b, k) BE
{ // addl addcl andl cmpl movl orl sbbl shll shrl subl xorl
  // Memory is the destination with k as source
  // eg: addl $20,24(%edx,%edi,4)
  LET xname = iarname(x)
  LET bname = iarname(b)
  LET f8, f32, n = 0, 0, 0

  db2wrf("        %s $%n,%n(%s,%s,%n)*n", iaop2str(op), k, d, bname, xname, s)

  SWITCHON op INTO
  { DEFAULT:       iabadop(op, "DXsBK"); RETURN

    CASE ia_addl:  f8, f32, n := #x83, #x81, 0; ENDCASE // addl $k,d(b,x,s)
    CASE ia_addcl: f8, f32, n := #x83, #x81, 2; ENDCASE // addcl $k,d(b,x,s)
    CASE ia_andl:  f8, f32, n := #x83, #x81, 4; ENDCASE // andl $k,d(b,x,s)
    CASE ia_cmpl:  f8, f32, n := #x83, #x81, 7; ENDCASE // cmpl $k,d(b,x,s)
    CASE ia_movb:  ia_fdxsbk1(#xC6,d,x,s,b,k);  RETURN  // movb $k,d(b,x,s)
    CASE ia_movl:  ia_fdxsbk4(#xC7,d,x,s,b,k);  RETURN  // movl $k,d(b,x,s)
    CASE ia_movw:  ia_fdxsbk2(#x66C7,d,x,s,b,k);RETURN  // movw $k,d(b,x,s)
    CASE ia_orl:   f8, f32, n := #x83, #x81, 1; ENDCASE // orl  $k,d(b,x,s)
    CASE ia_shll:  UNLESS 0<=k<=31 DO
                   { ia_fdxsbk4(#xC7,d,x,s,b,0)         // movl $0,d(b,x,s)
                     RETURN
                   }
                   f8,      n := #xC0,       5; ENDCASE // shll $k,d(b,x,s)
    CASE ia_shrl:  UNLESS 0<=k<=31 DO
                   { ia_fdxsbk4(#xC7,d,x,s,b,0)         // movl $0,d(b,x,s)
                     RETURN
                   }
                   f8,      n := #xC1,       5; ENDCASE // shll $k,d(b,x,s)
    CASE ia_sbbl:  f8, f32, n := #x83, #x81, 3; ENDCASE // sbbl $k,d(b,x,s)
    CASE ia_subl:  f8, f32, n := #x83, #x81, 5; ENDCASE // subl $k,d(b,x,s)
    CASE ia_xorl:  f8, f32, n := #x83, #x81, 6; ENDCASE // xorl $k,d(b,x,s)
  }
  TEST -128<=k<127
  THEN ia_fndxsbk1(f8,  n, d, x, s, b, k)
  ELSE ia_fndxsbk4(f32, n, d, x, s, b, k)
}

AND iaJL(op, n, short) BE
// jmp je jne jl jle jg jge ja jae jb jbe

// short is TRUE if forward refs are assumed to be rel8
{ LET f8, f32 = 0, 0

  db2wrf("        %s L%n*n", iaop2str(op), n)

  SWITCHON op INTO
  { DEFAULT:     writef("Error: Bad op for iaJL*n"); RETURN

    CASE ia_jmp: f8, f32 := #xEB,   #xE9; ENDCASE // jmp Ln
    CASE ia_je:  f8, f32 := #x74, #x0F84; ENDCASE // je Ln
    CASE ia_jne: f8, f32 := #x75, #x0F85; ENDCASE // jne Ln
    CASE ia_jl:  f8, f32 := #x7C, #x0F8C; ENDCASE // jl Ln
    CASE ia_jle: f8, f32 := #x7E, #x0F8E; ENDCASE // jle Ln
    CASE ia_jg:  f8, f32 := #x7F, #x0F8F; ENDCASE // jg Ln
    CASE ia_jge: f8, f32 := #x7D, #x0F8D; ENDCASE // jge Ln
    CASE ia_ja:  f8, f32 := #x77, #x0F87; ENDCASE // ja Ln
    CASE ia_jae: f8, f32 := #x73, #x0F83; ENDCASE // jae Ln
    CASE ia_jb:  f8, f32 := #x72, #x0F82; ENDCASE // jb Ln
    CASE ia_jbe: f8, f32 := #x76, #x0F86; ENDCASE // jbe Ln
  }
  ia_j(f8, f32, n, short)
}

AND iaJR(op, r) BE
// jmp
{ LET rname = iarname(r)
  db2wrf("        %s **%s*n", iaop2str(op), rname)

  SWITCHON op INTO
  { DEFAULT:     writef("Error: Bad op for iaJR*n"); RETURN

    CASE ia_jmp: ia_fnr(#xFF, 4, r); ENDCASE // jmp Ln
  }
}

// *****************  Assemble i386 instructions *****************

// The following function are to assemble i386 instructions.
// No optimisation is performed except for the compare instructions.

// Each ia generation function (such ad iaRR) assembles just one
// machine instruction. Most optimisations are performed by the MC
// generation functions.


/*
32-bit i386 protected mode instruction format

op-byte                     d8  or  d32
op-byte modRM               d8  or  d32
op-byte modRM SIB           d8  or  d32

  modRM
00_rrr_sss                      [sss]     sss~=100
01_rrr_sss                    d8[sss]     sss~=100
10_rrr_sss                   d32[sss]     sss~=100
11_rrr_sss                       sss      sss~=100

00_rrr_101                       d32

00_rrr_100 tt_xxx_101         d32[xxx<<tt]
01_rrr_100 tt_xxx_bbb          d8[xxx<<tt + bbb]
10_rrr_100 tt_xxx_bbb         d32[xxx<<tt + bbb]
*/

// Form a ModR/M byte:          < mm            reg/op      r/m>
AND mod00(reg_op, rm)     = iaC1(#b00_000_000 + (reg_op<<3) + rm)
AND mod01(reg_op, rm)     = iaC1(#b01_000_000 + (reg_op<<3) + rm)
AND mod10(reg_op, rm)     = iaC1(#b10_000_000 + (reg_op<<3) + rm)
AND mod11(reg_op, rm)     = iaC1(#b11_000_000 + (reg_op<<3) + rm)
AND modmm(mm, reg_op, rm) = iaC1( (mm<<6)     + (reg_op<<3) + rm)

// Form a SIB byte:              < ss            index       base>
AND sib00(index, base)     = iaC1(#b00_000_000 + (index<<3) + base)
AND sib01(index, base)     = iaC1(#b01_000_000 + (index<<3) + base)
AND sib10(index, base)     = iaC1(#b10_000_000 + (index<<3) + base)
AND sib11(index, base)     = iaC1(#b11_000_000 + (index<<3) + base)

AND sibss(scale, index, base) = VALOF SWITCHON scale INTO
{ DEFAULT: writef("sibss: bad scale=%n*n", scale)
           abort(999)
           RESULTIS 0
  CASE 1: RESULTIS sib00(index, base)
  CASE 2: RESULTIS sib01(index, base)
  CASE 4: RESULTIS sib10(index, base)
  CASE 8: RESULTIS sib11(index, base)
}

AND mcr2iar(r) = VALOF SWITCHON r INTO
{ // Map MC register numbers to i386 register numbers
  DEFAULT:   writef("mcr2iar(%n): Bad MC register*n", r)
             RETURN
  CASE mc_a: RESULTIS Eax
  CASE mc_b: RESULTIS Ebx
  CASE mc_c: RESULTIS Ecx
  CASE mc_d: RESULTIS Edx
  CASE mc_e: RESULTIS Esi
  CASE mc_f: RESULTIS Edi
}

AND iarname(r) = VALOF SWITCHON r INTO
{ // 32-bit registers  EAX, EBX, ECX, EDX, ESP, EBP, ESI and EDI 
  DEFAULT:
    writef("iarname(%n): Bad i386 register*n", r)
abort(1000)
    RESULTIS "%???"
  CASE Eax: RESULTIS "%eax"
  CASE Ecx: RESULTIS "%ecx"
  CASE Edx: RESULTIS "%edx"
  CASE Ebx: RESULTIS "%ebx"
  CASE Esp: RESULTIS "%esp"
  CASE Ebp: RESULTIS "%ebp"
  CASE Esi: RESULTIS "%esi"
  CASE Edi: RESULTIS "%edi"
}

AND iarname16(r) = VALOF SWITCHON r INTO
{ // 16-bit registers AX, BX, CX, DX, SP, BP, SI and DI 
  DEFAULT:
    writef("iarname(%n): Bad i386 register*n", r)
    RESULTIS "%???"
  CASE Eax: RESULTIS "%ax"
  CASE Ecx: RESULTIS "%cx"
  CASE Edx: RESULTIS "%dx"
  CASE Ebx: RESULTIS "%bx"
  CASE Esp: RESULTIS "%sp"
  CASE Ebp: RESULTIS "%bp"
  CASE Esi: RESULTIS "%si"
  CASE Edi: RESULTIS "%di"
}

AND iarname8(r) = VALOF SWITCHON r INTO
{ // 8-bit registers AL, BL, CL and DL
  DEFAULT:
    writef("iarname8(%n): Bad i386 register*n", r)
    RESULTIS "%???"
  CASE Eax: RESULTIS "%al"
  CASE Ecx: RESULTIS "%cl"
  CASE Edx: RESULTIS "%dl"
  CASE Ebx: RESULTIS "%bl"
}

AND iarname8h(r) = VALOF SWITCHON r INTO
{ // 8-bit registers AH, BH, CH and DH
  DEFAULT:
    writef("iarname8h(%n): Bad i386 register*n", r)
    RESULTIS "%???"
  CASE Eax: RESULTIS "%ah"
  CASE Ecx: RESULTIS "%ch"
  CASE Edx: RESULTIS "%dh"
  CASE Ebx: RESULTIS "%bh"
}

AND iabadop(op, str) BE
{ LET opstr = iaop2str(op)
  writef("Error: ia%s(", str)
  writef(opstr, op)
  writef(",..) not available*n")
}

AND iaop2str(op) = VALOF SWITCHON op INTO
{ DEFAULT:           RESULTIS "unknown:%n"

  CASE ia_addl:      RESULTIS "addl"
  CASE ia_addcl:     RESULTIS "addcl"
  CASE ia_andl:      RESULTIS "andl"
  CASE ia_alignc:    RESULTIS "alignc"
  CASE ia_alignd:    RESULTIS "alignd"
  CASE ia_call:      RESULTIS "call"
  CASE ia_cdq:       RESULTIS "cdq"
  CASE ia_cmpl:      RESULTIS "cmpl"
  CASE ia_datab:     RESULTIS "datab"
  CASE ia_datak:     RESULTIS "datak"
  CASE ia_datal:     RESULTIS "datal"
  CASE ia_decl:      RESULTIS "decl"
  CASE ia_divl:      RESULTIS "divl"
  CASE ia_dlab:      RESULTIS "dlab"
  CASE ia_endfn:     RESULTIS "endfn"
  CASE ia_end:       RESULTIS "end"
  CASE ia_entry:     RESULTIS "entry"
  CASE ia_idivl:     RESULTIS "idivl"
  CASE ia_imull:     RESULTIS "imull"
  CASE ia_incl:      RESULTIS "incl"
  CASE ia_je:        RESULTIS "je"
  CASE ia_jne:       RESULTIS "jne"
  CASE ia_jl:        RESULTIS "jl"
  CASE ia_jg:        RESULTIS "jg"
  CASE ia_jle:       RESULTIS "jle"
  CASE ia_jge:       RESULTIS "jge"
  CASE ia_lab:       RESULTIS "lab"
  CASE ia_leal:      RESULTIS "leal"
  CASE ia_movb:      RESULTIS "movb"
  CASE ia_movl:      RESULTIS "movl"
  CASE ia_movw:      RESULTIS "movw"
  CASE ia_movsbl:    RESULTIS "movsbl"
  CASE ia_movswl:    RESULTIS "movswl"
  CASE ia_movzbl:    RESULTIS "movzbl"
  CASE ia_movzwl:    RESULTIS "movzwl"
  CASE ia_mull:      RESULTIS "mull"
  CASE ia_negl:      RESULTIS "negl"
  CASE ia_notl:      RESULTIS "notl"
  CASE ia_orl:       RESULTIS "orl"
  CASE ia_popl:      RESULTIS "popl"
  CASE ia_popal:     RESULTIS "popal"
  CASE ia_popfl:     RESULTIS "popfl"
  CASE ia_pushl:     RESULTIS "pushl"
  CASE ia_pushal:    RESULTIS "pushal"
  CASE ia_pushfl:    RESULTIS "pushfl"
  CASE ia_ret:       RESULTIS "ret"
  CASE ia_seta:      RESULTIS "seta"
  CASE ia_setae:     RESULTIS "setae"
  CASE ia_setb:      RESULTIS "setb"
  CASE ia_setbe:     RESULTIS "setbe"
  CASE ia_sete:      RESULTIS "sete"
  CASE ia_setg:      RESULTIS "setg"
  CASE ia_setge:     RESULTIS "setge"
  CASE ia_setne:     RESULTIS "setne"
  CASE ia_setl:      RESULTIS "setl"
  CASE ia_setle:     RESULTIS "setle"
  CASE ia_shld:      RESULTIS "shld"
  CASE ia_shrd:      RESULTIS "shrd"
  CASE ia_shll:      RESULTIS "shll"
  CASE ia_shrl:      RESULTIS "shrl"
  CASE ia_sbbl:      RESULTIS "sbbl"
  CASE ia_subl:      RESULTIS "subl"
  CASE ia_xchgl:     RESULTIS "xchgl"
  CASE ia_xorl:      RESULTIS "xorl"
}

// ************ Code and Data Byte Generation Functions *************

AND iaD1(b) BE
{ IF datap > datat DO
  { writef("*niaD1: data space overflow*n")
    RETURN
  }
  db3wrf(" %x2", b)
  mc%datap := b
  datap := datap + 1
}

AND iaD2(num) BE { iaD1(num); iaD1(num>>8) }
AND iaD3(num) BE { iaD1(num); iaD1(num>>8); iaD1(num>>16) }
AND iaD4(num) BE { iaD1(num); iaD1(num>>8); iaD1(num>>16); iaD1(num>>24) }

AND iaC1(b) BE
{ IF codep >= codet DO
  { writef("*niaC1: code space overflow, codep=%n codet=%n*n", codep, codet)
    RETURN
  }
  db3wrf(" %x2", b)
  mc%codep := b
  codep := codep + 1
}

AND iaC2(num) BE { iaC1(num); iaC1(num>>8) }
AND iaC3(num) BE { iaC1(num); iaC1(num>>8); iaC1(num>>16) }
AND iaC4(num) BE { iaC1(num); iaC1(num>>8); iaC1(num>>16); iaC1(num>>24) }

AND get4(a) = mc%(a) | mc%(a+1)<<8 | mc%(a+2)<<16 | mc%(a+3)<<24

AND put1(a, val) BE
{ db3wrf("%i5: %x2                -- 8-bit forward reference*n", a, val)
  mc%(a  ) := val
}

AND put4(a, val) BE
{ db3wrf("%i5: %x2 %x2 %x2 %x2       -- 32-bit forward reference*n",
          a, val, val>>8, val>>16, val>>24)
  mc%(a  ) := val
  mc%(a+1) := val>>8
  mc%(a+2) := val>>16
  mc%(a+3) := val>>24
}

AND setrefs(p, val) BE WHILE p DO
{ LET next = !p
  LET pos = p!1
//writef("setrefs: %n -> [%n, %n]*n", p, next, pos)
  TEST pos<0
  THEN { // Resolve short (8-bit) forward reference
         LET rel = val + pos
         UNLESS -128 <= rel <=127 DO
         { writef("Error: Reference for %n to %n out of range*n", pos, val)
           LOOP
         }
         put1(-pos-1, rel)
       }
  ELSE { // Resolve a long (32-bit) forward reference
         LET p = pos-4
         LET newval = val + get4(p)
         put4(p, newval)
       }
  p := next
}

AND mk2(next, val) = VALOF
{ LET p = freelist

  UNLESS p DO
  { // Allocate a new block
    LET blkupb = 1000
    LET blk = getvec(blkupb)
//writef("*nmk2: blkupb=%n, blk=%n*n", blkupb, blk)
//abort(1000)
    UNLESS blk DO
    { writef("Error: more memory needed*n")
      RESULTIS 0
    }
    // Link it into the blocklist
    !blk := blocklist
    blocklist := blk
//writef("blocklist=%n*n", blocklist)
//abort(1000)
    // Use the block to make 2-tuple for the freelist.
    FOR q = blk+1 TO blk+blkupb-2 BY 2 DO
    { !q := freelist
      q!1 := 0
      freelist := q
    }
    p := freelist
  }
  // Unlink a 2-tuple from freelist
  freelist := !p
  // Initialise is fields
  p!0 := next
  p!1 := val
//writef("*nmk2: Created %i5 -> [%n, %n]*n", p, next, val)
  RESULTIS p
}

// All ia_... functions are defined below

AND ia_j(fs, fl, n, short) BE
{ LET val = labv!n
  db3codep()
  TEST val
  THEN { // Compile a backwards jump instruction
         LET rel = val - codep - 2
         TEST -128 <= rel <= 127 
         THEN { iaC1(fs)
                iaC1(rel)
              }
         ELSE { IF fl>>8 DO iaC1(fl>>8)
                iaC1(fl)
                iaC4(val-codep-4)  // a 32-bit relative address
              }
       }
  ELSE TEST short
       THEN { // Compile an 8-bit relative forward ref
              iaC1(fs)
              iaC1(0)
              refv!n := mk2(refv!n, -codep)
            }
       ELSE { // Compile a 32-bit relative forward ref
              IF fl>>8 DO iaC1(fl>>8)
              iaC1(fl)
              iaC4(-codep-4)
              refv!n := mk2(refv!n, codep)
            }
  db3nl()
}

AND ia_fno(f, fno) BE
{ // Only used by the CALL instructtion
  LET fval = fnv!fno
  db3codep()
  TEST fval
  THEN { // Compile a backwards jump instruction
         LET rel32 = fval - codep - 5
         IF f>=256 DO iaC1(f>>8)
         iaC1(f); iaC4(rel32)  // a 32-bit relative address
//writef("ia_fno: CALL F%n  fval=%n rel32=%n codep=%n*n", fno, fval, rel32, codep)
       }
  ELSE { // Compile a 32-bit relative forward ref
         IF f>=256 DO iaC1(f>>8)
         iaC1(f); iaC4(-codep-4)
         frefv!fno := mk2(frefv!fno, codep)
       }
  db3nl()
}

AND ia_f(f) BE // eg 58+r   -- popl r
{ db3codep()
  IF f>=256 DO iaC1(f>>8)
  iaC1(f)
  db3nl()
}

// ia_f{k1,k4} functions

AND ia_fk1(f, k) BE // not used
{ db3codep()
  writef("ia_fk1 called*n"); abort(999)
  IF f>=256 DO iaC1(f>>8)
  iaC1(f); iaC1(k)
  db3nl()
}

AND ia_fk4(f, k) BE // eg 05 id  -- addl $k,%eax
{ db3codep()
  IF f>=256 DO iaC1(f>>8)
  iaC1(f); iaC4(k)
  db3nl()
}

// ia_f<mem> functions

AND ia_fd(f, d) BE // Always 32-bit displacement
{ db3codep()
  IF f>=256 DO iaC1(f>>8)
  iaC1(f); iaC4(d)
  db3nl()
}

AND notimpl(mess) BE
{ writef(mess)
  abort(999)
}

AND ia_fdx(f, d, x) BE notimpl("ia_fdx not implemented*n")
AND ia_fdxs(f, d, x, s) BE notimpl("ia_fdxs not implemented*n")
AND ia_fdxsb(f, d, x, s, b) BE notimpl("ia_fdxsb not implemented*n")

// ia_f<mem>r functions
AND ia_fdr(f, d, r) BE notimpl("ia_fdr not implemented*n")
AND ia_fdxr(f, d, x, r) BE notimpl("ia_fdxr not implemented*n")
AND ia_fdxsr(f, d, x, s, r) BE notimpl("ia_fdxsr not implemented*n")
AND ia_fdxsbr(f, d, x, s, b, r) BE notimpl("ia_fdxsbr not implemented*n")


// ia_f<mem>k1 functions
AND ia_fdk1(f, d, k) BE
{ db3codep()
  IF f>=256 DO iaC1(f>>8)
  iaC1(f); mod00(0,5); iaC4(d); iaC1(k)
  db3nl()
}

AND ia_fdxk1(f, d, x, k) BE
{ db3codep()
  IF f>=256 DO iaC1(f>>8)
  iaC1(f)
  TEST -128<=d<=127
  THEN { mod01(0,x); iaC1(d) }
  ELSE { mod10(0,x); iaC4(d) }
  iaC1(k)
  db3nl()
}

AND ia_fdxsk1(f, d, x, s, k) BE
{
//writef("ia_fdxsk4(f, n=%n, d=%n, x=%n, s=%n)*n", n,d,x,s)
  IF s=1 DO
  { ia_fdxk1(f, d, x, k) // eg  movw $1234,24(%ecx)
    RETURN
  }

  IF x=Esp DO
  { writef("Error: Cannot scale %%esp*n")
    RETURN
  }
  // s should be 2, 4 or 8
  // eg: movb $127,200(,ecx,4)
  db3codep()
  IF f>=256 DO iaC1(f>>8)
  iaC1(f)
  mod00(0, 4)
  sibss(s, x, 5)
  iaC4(d)
  iaC1(k)
  db3nl()
}


AND ia_fdxsbk1(f, d, x, s, b, k) BE
{ // s should be 1, 2, 4 or 8
  db3codep()
  IF f>=256 DO iaC1(f>>8)
  iaC1(f)

  IF d=0 DO
  { // eg: movw $1234,(%ebx,ecx,4)
    mod00(0,4); sibss(s,x,b); iaC1(k)
    db3nl()
    RETURN
  }

  IF -128<=d<=127 DO
  { // eg: movw $1234,20(%ebx,ecx,4)
    mod01(0,4); sibss(s,x,b); iaC1(d); iaC1(k)
    db3nl()
    RETURN
  }

  // eg: movw $1234,200(%ebx,ecx,4)
  mod10(0, 4); sibss(s,x,b); iaC4(d); iaC1(k)
  db3nl()
  RETURN
}

// ia_f<mem>k2 functions
AND ia_fdk2(f, d, k) BE
{ db3codep()
  IF f>=256 DO iaC1(f>>8)
  iaC1(f); mod00(0,5); iaC4(d); iaC2(k)
  db3nl()
}

AND ia_fdxk2(f, d, x, k) BE
{ db3codep()
  IF f>=256 DO iaC1(f>>8)
  iaC1(f)
  TEST -128<=d<=127
  THEN { mod01(0,x); iaC1(d) }
  ELSE { mod10(0,x); iaC4(d) }
  iaC2(k)
  db3nl()
}


AND ia_fdxsk2(f, d, x, s, k) BE // eg  movw $1234,24(,%ecx,4)
{
//writef("ia_fdxsk4(f, n=%n, d=%n, x=%n, s=%n)*n", n,d,x,s)
  IF s=1 DO
  { ia_fdxk2(f, d, x, k) // eg  movw $1234,24(%ecx)
    RETURN
  }

  IF x=Esp DO
  { writef("Error: Cannot scale %%esp*n")
    RETURN
  }
  // s should be 2, 4 or 8
  // eg: movw $1234,200(,ecx,4)
  db3codep()
  IF f>=256 DO iaC1(f>>8)
  iaC1(f)
  mod00(0, 4)
  sibss(s, x, 5)
  iaC4(d)
  iaC2(k)
  db3nl()
}

AND ia_fdxsbk2(f, d, x, s, b, k) BE // eg  movw $1234,24(%ebx,%ecx,4)
{ // s should be 1, 2, 4 or 8
  db3codep()
  IF f>=256 DO iaC1(f>>8)
  iaC1(f)

  IF d=0 DO
  { // eg: movw $1234,(%ebx,ecx,4)
    mod00(0,4); sibss(s,x,b); iaC2(k)
    db3nl()
    RETURN
  }

  IF -128<=d<=127 DO
  { // eg: movw $1234,20(%ebx,ecx,4)
    mod01(0,4); sibss(s,x,b); iaC1(d); iaC2(k)
    db3nl()
    RETURN
  }

  // eg: movw $1234,200(%ebx,ecx,4)
  mod10(0, 4); sibss(s,x,b); iaC4(d); iaC2(k)
  db3nl()
  RETURN
}

// ia_f<mem>k4 functions
AND ia_fdk4(f, d, k) BE
{ db3codep()
  IF f>=256 DO iaC1(f>>8)
  iaC1(f); mod00(0,5); iaC4(d); iaC4(k)
  db3nl()
}

AND ia_fdxk4(f, d, x, k) BE
{ db3codep()
  IF f>=256 DO iaC1(f>>8)
  iaC1(f)
  TEST -128<=d<=127
  THEN { mod01(0,x); iaC1(d) }
  ELSE { mod10(0,x); iaC4(d) }
  iaC4(k)
  db3nl()
}


AND ia_fdxsk4(f, d, x, s, k) BE // eg  movl $1234,24(,%ecx,4)
{
//writef("ia_fdxsk4(f, n=%n, d=%n, x=%n, s=%n)*n", n,d,x,s)
  IF s=1 DO
  { ia_fdxk4(f, d, x, k) // eg  movl $1234,24(%ecx)
    RETURN
  }

  IF x=Esp DO
  { writef("Error: Cannot scale %%esp*n")
    RETURN
  }
  // s should be 2, 4 or 8
  // eg: movl $1234,200(,ecx,4)
  db3codep()
  IF f>=256 DO iaC1(f>>8)
  iaC1(f)
  mod00(0, 4)
  sibss(s, x, 5)
  iaC4(d)
  iaC4(k)
  db3nl()
}

AND ia_fdxsbk4(f, d, x, s, b, k) BE // eg  movl $1234,24(%ebx,%ecx,4)
{ // s should be 1, 2, 4 or 8
  db3codep()
  IF f>=256 DO iaC1(f>>8)
  iaC1(f)

  IF d=0 DO
  { // eg: movl $1234,(%ebx,ecx,4)
    mod00(0,4); sibss(s,x,b); iaC4(k)
    db3nl()
    RETURN
  }

  IF -128<=d<=127 DO
  { // eg: movl $1234,20(%ebx,ecx,4)
    mod01(0,4); sibss(s,x,b); iaC1(d); iaC4(k)
    db3nl()
    RETURN
  }

  // eg: movl $1234,200(%ebx,ecx,4)
  mod10(0, 4); sibss(s,x,b); iaC4(d); iaC4(k)
  db3nl()
  RETURN
}

// Below are all the ia_fn... functions

// ia_fn{k1,k4} functions
AND ia_fnk1(f, n, k) BE // not used
{ db3codep()
  writef("ia_fnk1 called*n"); abort(999)
  IF f>=256 DO iaC1(f>>8)
  iaC1(f); mod11(n, 00000); iaC1(k)
  db3nl()
}

AND ia_fnk4(f, n, k) BE // eg 81 /0 id   -- addl k,r
{ db3codep()
  writef("ia_fnk4 called*n"); abort(999)
  IF f>=256 DO iaC1(f>>8)
  iaC1(f); mod11(n, 00000); iaC4(k)
  db3nl()
}

// ia_fn{r,rk1,rk4} functions
AND ia_fnr(f, n, r) BE // eg F7 /3   -- negl r
                       // or 8B /r   -- movl n,r
{ db3codep()
  IF f>>8 DO iaC1(f>>8)
  iaC1(f); mod11(n, r)
  db3nl()
//abort(1111)
}

AND ia_fnrk1(f, n, r, k) BE // eg 83 /0 ib   -- addl k,r
{ db3codep()
  IF f>=256 DO iaC1(f>>8)
  iaC1(f); mod11(n, r); iaC1(k)
  db3nl()
}

AND ia_fnrk4(f, n, r, k) BE // eg 81 /0 id   -- addl k,r
{ db3codep()
  IF f>=256 DO iaC1(f>>8)
  iaC1(f); mod11(n, r); iaC4(k)
  db3nl()
}


// ia_fn<mem> functions
AND ia_fnd(f, n, d) BE  // Always a 32-bit displacement
{ db3codep()
  IF f>=256 DO iaC1(f>>8)
  iaC1(f)
  mod00(n, 5)
  iaC4(d)
  db3nl()
}


AND ia_fndx(f, n, d, x) BE // eg F7 /3   -- negl   d(x)
                           // or 8B /n   -- movl n,d(x)
{ db3codep()
  IF f>=256 DO iaC1(f>>8)
  iaC1(f)
  IF d=0 & x~=Ebp DO
  { TEST x=Esp
    THEN { mod00(n, 4)     // eg: negl (%esp)  or   movl (%esp),n
           sib00(4, Esp)
         }
    ELSE { mod00(n, x)     // eg: negl (x)  or   movl (x),n
         }
    db3nl()
    RETURN
  }
  IF -128<=d<=127 DO
  { TEST x=Esp
    THEN { mod00(n, 4)
           sib00(4, Esp) 
         }
    ELSE { mod01(n, x)     // eg: negl disp8(x)  or   movl disp8(x),n
         }
    iaC1(d)
    db3nl()
    RETURN
  }
  TEST x=Esp
  THEN { mod10(n, 4)     // eg: negl disp32(%esp)  or   movl disp32(%esp),n
         sib00(4, Esp)
       }
  ELSE { mod10(n, x)     // eg: negl disp32(x)  or   movl disp32(x),n
       }
  iaC4(d)
  db3nl()
  RETURN
 }

AND ia_fndxs(f, n, d, x, s) BE // negl 20(,%ebx,4)
                               // movl (,%exb,4), %eax
{
//writef("ia_fndxs(f, n=%n, d=%n, x=%n, s=%n)*n", n,d,x,s)
  IF s=1 DO
  { ia_fndx(f, n, d, x)
    RETURN
  }

  IF x=Esp DO
  { writef("Error: Cannot scale %%esp*n")
    RETURN
  }
  // s should be 2, 4 or 8
  // eg: movl 200(,ecx,4),%eax
  db3codep()
  IF f>=256 DO iaC1(f>>8)
  iaC1(f)
  mod00(n, 4)
  sibss(s, x, 5)
  iaC4(d)
  db3nl()
}

AND ia_fndxsb(f, n, d, x, s, b) BE // negl 20(%edx,%ebx,4)
                                   // movl (%edx,%exb,4), %eax
{ // s should be 1, 2, 4 or 8
  db3codep()
  IF f>=256 DO iaC1(f>>8)
  iaC1(f)

  IF d=0 DO
  { // eg: movl (%ebx,ecx,4),%eax
    mod00(n,4); sibss(s,x,b)
    db3nl()
    RETURN
  }

  IF -128<=d<=127 DO
  { // eg: movl 20(%ebx,ecx,4),%eax
    mod01(n,4); sibss(s,x,b); iaC1(d)
    db3nl()
    RETURN
  }

  // eg: movl 200(%ebx,ecx,4),%eax
  mod10(n, 4); sibss(s,x,b); iaC4(d)
  db3nl()
  RETURN
}

// ia_fn<mem>r functions
AND ia_fndr(f, n, d, x, s, b, k) BE notimpl("ia_fndr not implemented*n")
AND ia_fndxr(f, n, d, x, s, b, k) BE notimpl("ia_fndxr not implemented*n")
AND ia_fndxsr(f, n, d, x, s, b, k) BE notimpl("ia_fndxsr not implemented*n")
AND ia_fndxsbr(f, n, d, x, s, b, k) BE notimpl("ia_fndxsbr not implemented*n")

// ia_fn<mem>k1 functions
AND ia_fndk1(f, n, d, k) BE
{ db3codep()
  IF f>=256 DO iaC1(f>>8)
  iaC1(f); mod00(n,5); iaC4(d); iaC1(k)
  db3nl()
}

AND ia_fndxk1(f, n, d, x, k) BE
{ db3codep()
  IF f>=256 DO iaC1(f>>8)
  iaC1(f)
  TEST -128<=d<=127
  THEN { mod01(n,x); iaC1(d) }
  ELSE { mod10(n,x); iaC4(d) }
  iaC1(k)
  db3nl()
}

AND ia_fndxsk1(f, n, d, x, s, k) BE
{ db3codep()
  IF f>=256 DO iaC1(f>>8)
  iaC1(f)
  //TEST -128<=d<=127
  //THEN { mod01(n,4); sibss(s,x,5); iaC1(d) }
  //ELSE { mod10(n,4); sibss(s,x,5); iaC4(d) }
  mod00(n,4); sibss(s,x,5); iaC4(d)
  iaC1(k)
  db3nl()
}

AND ia_fndxsbk1(f, n, d, x, s, b, k) BE
{ db3codep()
  IF f>=256 DO iaC1(f>>8)
  iaC1(f)
  TEST d=0
  THEN { mod00(n,4); sibss(s,x,b); iaC1(k) }
  ELSE TEST -127<=d<127
       THEN { mod01(n,4); sibss(s,x,b); iaC1(d); iaC1(k) }
       ELSE { mod10(n,4); sibss(s,x,b); iaC4(d); iaC1(k) }
  db3nl()
}

// ia_fn<mem>k4 functions
AND ia_fndk4(f, n, d, k) BE
{ db3codep()
  IF f>=256 DO iaC1(f>>8)
  iaC1(f); mod00(n,5); iaC4(d); iaC4(k)
  db3nl()
}

AND ia_fndxk4(f, n, d, x, k) BE
{ db3codep()
  IF f>=256 DO iaC1(f>>8)
  iaC1(f)
  TEST -128<=d<=127
  THEN { mod01(n,x); iaC1(d) }
  ELSE { mod10(n,x); iaC4(d) }
  iaC4(k)
  db3nl()
}

AND ia_fndxsk4(f, n, d, x, s, k) BE
{ db3codep()
  IF f>=256 DO iaC1(f>>8)
  iaC1(f)
  //TEST -128<=d<=127
  //THEN { mod01(n,4); sibss(s,x,5); iaC1(d) }
  //ELSE { mod10(n,4); sibss(s,x,5); iaC4(d) }
  mod00(n,4); sibss(s,x,5); iaC4(d)
  iaC4(k)
  db3nl()
}

AND ia_fndxsbk4(f, n, d, x, s, b, k) BE
{ db3codep()
  IF f>=256 DO iaC1(f>>8)
  iaC1(f)
  TEST -128<=d<=127
  THEN { mod01(n,4); sibss(s,x,b); iaC1(d) }
  ELSE { mod10(n,4); sibss(s,x,b); iaC4(d) }
  iaC4(k)
  db3nl()
}

