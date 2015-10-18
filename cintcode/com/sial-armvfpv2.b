/*
############### UNDER DEVELOPMENT #######################

This program compiles .sial files to .s files for the
ARMv6 CPU on the Raspberry Pi which provides the VFPv2
floating point instruction set.

Implemented by Martin Richards (c) February 2015.

Change history

31/01/2015
Started the conversion from the Pentium codegenerator sial-686.b.

20/08/2014
Adding floating point operations
FIX, FLOAT, #ABS, #*, #/, #+, #-, #=, #~=, #<=, #>=, #< and #>. 
*/

SECTION "sial-armvfdv2"

GET "libhdr"

GET "sial.h"

MANIFEST {
  k_q=0   // Value not known to be in a memory location

  b_a=1   // value is in A
  b_b=2   // Value is in B
  b_x=8   // Value is in X  -- never allow L and R to both be in X
  b_p=16  // Value is in Pn
  b_g=32  // Value is in Gn
  b_l=64  // Value is in Ln
  b_m=128 // Value is in Mn

  b_none=0
  b_all= b_a+b_b+b_x+b_p+b_g+b_l+b_m
  b_ap= b_a+b_p
  b_ag= b_a+b_g
  b_al= b_a+b_l
  b_am= b_a+b_m
  b_bp= b_b+b_p
  b_bg= b_b+b_g
  b_bl= b_b+b_l
  b_bm= b_b+b_m
  b_ab= b_a+b_b
  b_abx= b_a+b_b+b_x
  b_pglm=b_p+b_g+b_l+b_m

  bn_a= b_all - b_a
  bn_b= b_all - b_b
  bn_x= b_all - b_x
  bn_p= b_all - b_p
  bn_g= b_all - b_g
  bn_l= b_all - b_l
  bn_m= b_all - b_m
}

GLOBAL {
sialin: ug
asmout; stdin; stdout

rdf; rdp; rdg; rdk; rdw; rdl; rdc
rdcode

nextfcode // =0 or is the peeked next F code
peekfcode // If nextfcode=0 call rdf to peek next code
          // and set nextfcode to its value.

pval; gval; kval; wval; lval; mval

scan
cvf; cvfp; cvfg; cvfk; cvfw; cvfl

sectname
modletter
charv
labnumber

lbits  // Bit pattern saying where the value of L can be found
rbits  // Bit pattern saying where the value of R can be foun
ln     // n if lbits contains b_p, b_g, b_l or b_m
rn     // n if rbits contains b_p, b_g, b_l or b_m


regr_k; rn // Describes the value in the right hand operand R
               // It must be one of Pn, Gn, Ln, Mn or Q
               // If R is known to be in a register or in S then
               // one or more of RinA, RinB, RinS or RinX will be TRUE.

regl_k; ln // Describes what should be in the left operand L

/*
Abstract registers L and R typically hold the left and right hand
operands. There are two physical integer registers A and B and one
floating point register called X. The machine registers %ebx and
%ecx hold the values of A and B and the floating point accumulator
%s0 holds X.

The following variables remember which of L and R hold copies of A, B
and R.

*/

tracing  // =TRUE causes debuggin info to be inserted in the
         // assembly code file as commens
prstate

moveR2L  // Compile code move R to L
moveR2A  // Compile code to ensure R is in A
moveR2B  // Compile code to ensure R is in B
moveR2S  // Compile code to ensure R is in S
moveR2X  // Compile code to ensure R is in X

moveL2R  // Compile code move L to R
moveL2A  // Compile code to ensure L is in A
moveL2B  // Compile code to ensure L is in B
moveL2S  // Compile code to ensure L is in S
moveL2X  // Compile code to ensure L is in X

}

/*
Optimisation

Sial is an assembly language for a simple machine having registers
such as A, B, P, G and PC. These registers typically map into central
registers of the target machine. For this implementation, A is %ebx, B
is %ecx, P is %ebp, G is %esi etc. Sial instructions such as LP P3
cause A to be set to the value of P!3 and this translates to 

      movl 12(%ebp),%ebx.

Unfortunately, now that Sial includes floating point operators, the LP
instruction should not necessarily update %ebx. For example, consider
the compilation of x := x #+ y whose Sial code might be

 LP P3           A := P!3
 ATBLP P4        B := A; A := P!4
 FADD            A := B #+ A; B := ?
 SP P3           P!3 := A

The code we might like to generate is

 flds  12(%ebp)   push P!3 into %s0 
 fadds 16(%ebp)   %s0 := %s0 #+ P!4
 fstps 12(%ebp)   pop st(0) to P!3

So, for floating point operations such as FADD, the LP instruction
should move P!3 into %s0 rather than %ebx. To achieve this, this
translator delays the generation of code by introducing two abstract
registers L and R whose actual values may be held in any of the
physical registers A, B or X, or possibly held in a memory location S
or one addressed relative to P or G, or accessed using an L or M
label. There are two variables lbits and rbits that identify where the
values of L and R can be found. The constants b_a, b_b, b_x, b_p,
b_g, b_l and b_m identify bit positions in lbits and rbits specifying
where the values of L and R can be found.

If (lbits & b_a) > 0 then the value of L is in the A register.
If (lbits & b_b) > 0 then the value of L is in the B register.
If (lbits & b_x) > 0 then the value of L is in the floating point
                     register X addressed by %st.
If (lbits & b_p) > 0 then the value of L is in the local variable
                     location addressed by P!n where n is held in ln.
If (lbits & b_g) > 0 then the value of L is in the global variable
                     location addressed by G!n where n is held in ln.
If (lbits & b_l) > 0 then the value of L is in the memory location
                     addressed by label Ln where n is held in ln.
If (lbits & b_m) > 0 then the value of L is in the memory location
                     addressed by label Mn where n is held in ln.
In none of these bits are set in lbits the the value of L is undefined.

The meaning of the bits in rbits is defined similarly, but using rn
to specify n.

By convention the values of L and R same register (A, B, S or X) at
the same time.

The register S is actually on the run time stack with address (%esp).

The state variables typically change when reading Sial statements or
generating machine instructions. These changes need to be done with
care to ensure the result is always consistent and that no information
is lost. For example, observe how the variables change during the
translation of the Sial code given above code.

 Sial          Code            State

 LP P3
                               L=   R=P3
 ATBLP P4
                               L=P3  R=P4
 FADD
               flds 12(%ebp)
                               L=XP3  R=P4
               fadds 16(%ebp)
                               L=   R=X
 SP P3
               fstps 12(%ebp)
                               L=   R=P3

This shows that the LP P3 statement specifies that the value of R is
in local variable 3 (R=P3). We assume that the value of L at that
moment is unspecified. The instruction ATBLP P4 causes the value in R
to be moved to L before specifying that R is in local variable P4. The
statement FADD must compile code to perform the floating point
addition of P3 and P4. It does this by pushing P3 onto the floating
point stack (flds 12(%ebp)). At this point L=XP3 stating that the
value of L is in both X and local variable 3 having been pushed there
by flds. The instruction fadd 16(%ebp) then performs the floating
point addition of local 4 (P4). The resulting state shows that R holds
the result in X and that L has become undefined.  Finally, the
statement SP P3, pops %s0 from the floating point stack storing X
in local 3 (at address 12(%ebp)). R is now known to be in local 3
(R=P3) but not in X because the floating point stack has been popped
(by fstps).

To move a value from say A (%ebx) to the floating point register X
(%s0), it is necessary to use a memory location. Often the stack
location S (%esp) is used as in:

  push %ebx
  flds (%esp)

When the values of L and R are held in A and B, L normally prefers to
use B and R prefers A.

*/

LET trace(str, a, b, c) BE IF tracing DO
  writef(str, a, b, c)

LET start() = VALOF
{ LET argv = VEC 20
  LET v    = VEC 20
  LET cv   = VEC 256/bytesperword

  sectname := v
  sectname%0 := 0
  modletter := 'A'
  charv := cv
  labnumber := 0

  asmout := 0
  stdout := output()
  IF rdargs("FROM,TO/K,-t/s", argv, 20)=0 DO
  { writes("Bad args for sial-686*n")
    RESULTIS 20
  }
  IF argv!0=0 DO argv!0 := "prog.sial"  // FROM
  IF argv!1=0 DO argv!1 := "prog.s"     // TO/K
  tracing := argv!2                     // -t/s

  sialin := findinput(argv!0)
  IF sialin=0 DO
  { writef("Trouble with file %s*n", argv!0)
    RESULTIS 20
  }
  asmout := findoutput(argv!1)
   
  IF asmout=0 DO
  { writef("Trouble with file %s*n", argv!1)
    RESULTIS 20
  }
   
  //writef("Converting %s to %s*n", argv!0, argv!1)
  selectinput(sialin)
  selectoutput(asmout)

  // Initialise the state
  lbits, rbits := 0, 0
  ln, rn := 0, 0

  nextfcode := 0 // Initialise the F code peeking mechanism

  writef("# Code generated by sial-686*n*n")
  writef(".text*n.align 16*n")

  scan()

  endread()
  UNLESS asmout=stdout DO endwrite()
  selectoutput(stdout)
  writef("Conversion complete*n")
  RESULTIS 0
}

AND nextlab() = VALOF
{ labnumber := labnumber+1
  RESULTIS labnumber
}

AND rdcode(letter) = VALOF
{ // Read an Sial iten of the form <let>n
  // <let> is one of F, P, G, K, W, L, M or C
  LET a, ch, neg = 0, ?, FALSE

  ch := rdch() REPEATWHILE ch='*s' | ch='*n'

  IF ch=endstreamch RESULTIS -1

  UNLESS ch=letter DO
    error("Bad item, looking for %c found %c*n", letter, ch)

  ch := rdch()

  IF ch='-' DO { neg := TRUE; ch := rdch() }

  WHILE '0'<=ch<='9' DO { a := 10*a + ch - '0'; ch := rdch()  }

  RESULTIS neg -> -a, a
}

AND peekfcode() = VALOF
{ UNLESS nextfcode DO nextfcode := rdcode('F')
  RESULTIS nextfcode
}

AND rdf() = VALOF
{ TEST nextfcode
  THEN { LET f = nextfcode
         nextfcode := 0
         RESULTIS f
       }
  ELSE { RESULTIS rdcode('F')
       }
}

AND rdp() = VALOF { pval := rdcode('P'); RESULTIS pval }
AND rdg() = VALOF { gval := rdcode('G'); RESULTIS gval }
AND rdk() = VALOF { kval := rdcode('K'); RESULTIS kval }
AND rdw() = VALOF { wval := rdcode('W'); RESULTIS wval }
AND rdl() = VALOF { lval := rdcode('L'); RESULTIS lval }
AND rdm() = VALOF { mval := rdcode('M'); RESULTIS mval }
AND rdc() = rdcode('C')

AND error(mess, a, b, c) BE
{ LET out = output()
  UNLESS out=stdout DO
  { selectoutput(stdout)
    writef(mess, a, b, c)
    selectoutput(out)
  }
  writef(mess, a, b, c)
}

AND prstate() BE IF tracing DO
{ writef("# L=")
  IF (lbits&b_a)>0 DO wrch('A')
  IF (lbits&b_b)>0 DO wrch('B')
  IF (lbits&b_x)>0 DO wrch('X')
  IF (lbits&b_p)>0 DO writef("P%n", ln)
  IF (lbits&b_g)>0 DO writef("G%n", ln)
  IF (lbits&b_l)>0 DO writef("L%n", ln)
  IF (lbits&b_m)>0 DO writef("M%n", ln)

  writef("    R=")
  IF (rbits&b_a)>0 DO wrch('A')
  IF (rbits&b_b)>0 DO wrch('B')
  IF (rbits&b_x)>0 DO wrch('X')
  IF (rbits&b_p)>0 DO writef("P%n", rn)
  IF (rbits&b_g)>0 DO writef("G%n", rn)
  IF (rbits&b_l)>0 DO writef("L%n", rn)
  IF (rbits&b_m)>0 DO writef("M%n", rn)

  IF (lbits & rbits & (b_absx)) > 0 DO
    writef("  ### ERROR")
  newline()
}

AND moveR2L() BE
{ // Generate code for L := R
  trace("# moveR2L*n")
  lbits, ln := rbits, rn
  rbits := 0
  prstate()
}

AND moveL2R() BE
{ // Generate code for R := A
  trace("# moveL2R*n")
  rbits, rn := lbits, ln
  lbits := 0
  prstate()
}

AND moveR2A() BE
{ // Compile code to ensure that R is in A
  // and L is not in A
  // ie that (rbits & b_a) > 0 and
  // that (lbits & b_a) = 0

  trace("# moveR2A*n")

  IF lbits = b_a DO
  { // L is in A only so move it to B
    TEST rbits = b_b
    THEN { // Exchange A and B
           writef(" xchgl %%ebx,%%ecx*n")
           rbits := b_a
         }
    ELSE { writef(" movl %%ebx,%%ecx*n")
         }
    lbits := b_b
    prstate()
  }

  lbits := lbits & bn_a

  // R is not in A

  IF (rbits & b_a) > 0 RETURN

  UNLESS rbits DO
  { // R is undefined so give it the value in A
    rbits := b_a
    prstate()
    RETURN
  }

  IF (rbits & b_b) > 0 DO
  { // R is in B so move it to A
    writef(" movl %%ecx,%%ebx*n")
    rbits := b_a
    prstate()
    RETURN
  }

  IF rbits = b_x DO
  { // R is in X only so move it to A via S
//    IF lbits = b_s DO
//    { // We must preserve L so move it to B.
//      // Note that R is not in A
//      writef(" movl (%%esp),%%ecx*n")
//      lbits := b_b
//      prstate()
//    }

    // Now pop X to S
//    writef(" fstps (%%esp)*n")
//    rbits := b_s
//    prstate()
  }

  // R is in S or a memory location

//  IF (rbits & b_s) > 0 DO
//  { // R is in S so move it to A
//    writef(" movl (%%esp),%%ebx*n")
//    rbits := rbits | b_a
//    prstate()
//    RETURN
//  }

  // R must be in a memory location
  genopmemreg("movl", rbits, rn, "%ebx")
  rbits := rbits | b_a
  prstate()
}

AND moveL2A() BE
{ // Compile code to ensure that L is in A
  // and R is not in A
  // ie that (lbits & b_a) > 0 and
  // that (rbits & b_a) = 0

  trace("# moveL2A*n")

  IF rbits = b_a DO
  { // R is in A only so move it to B
    TEST lbits = b_b
    THEN { // Exchange A and B
           writef(" xchgl %%ecx,%%ebx*n")
           lbits := b_a
         }
    ELSE { writef(" movl %%ecx,%%ebx*n")
         }
    rbits := b_b
    prstate()
  }

  rbits := rbits & bn_a

  // R is not in A

  IF (lbits & b_a) > 0 RETURN

  UNLESS lbits DO
  { // L is undefined so give it the value in A
    lbits := b_a
    prstate()
    RETURN
  }

  IF (lbits & b_b) > 0 DO
  { // L is in B so move it to A
    writef(" movl %%ecx,%%ebx*n")
    lbits := b_a
    prstate()
    RETURN
  }

  IF lbits = b_x DO
  { // L is in X only so move it to A
//    IF rbits = b_s DO
//    { // We must preserve R so move it to B.
//      // Note that L is not in A
//      writef(" movl (%%esp),%%ecx*n")
//      rbits := b_b
//      prstate()
//    }

    // Now pop X to S
//    writef(" fstps (%%esp)*n")
//    lbits := b_s
//    prstate()
  }

  // L is a memory location

//  IF (lbits & b_s) > 0 DO
//  { // L is in S so move it to A
//    writef(" movl (%%esp),%%ebx*n")
//    lbits := lbits + b_a
//    prstate()
//    RETURN
//  }

  // R must be in a memory location
  genopmemreg("movl", rbits, rn, "%ebx")
  rbits := rbits | b_a
  prstate()
}

AND moveR2B() BE
{ // Compile code to ensure that R is in B
  // and L is not in B
  // ie that (rbits & b_b) > 0 and
  // that (lbits & b_b) = 0

  trace("# moveR2B*n")

  IF lbits = b_b DO
  { // L is in B only so move it to A
    TEST rbits = b_a
    THEN { // Exchange A and B
           writef(" xchgl %%ecx,%%ebx*n")
           rbits := b_b
         }
    ELSE { writef(" movl %%ecx,%%ebx*n")
         }
    lbits := b_a
    prstate()
  }

  lbits := lbits & bn_b

  IF (rbits & b_b) > 0 RETURN

  UNLESS rbits DO
  { // R is undefined so give it the value in B
    rbits := b_b
    prstate()
    RETURN
  }

  IF (rbits & b_a) > 0 DO
  { // R is in A so move it to B
    writef(" movl %%ebx,%%ecx*n")
    rbits := b_b
    prstate()
    RETURN
  }

  IF rbits = b_x DO
  { // R is in X only so move it to B via S
    IF lbits = b_s DO
    { // We must preserve L so move it to A.
      // Note that R is not in B
      writef(" movl (%%esp),%%ebx*n")
      lbits := b_a
      prstate()
    }

    // Now pop X to S
//    writef(" fstps (%%esp)*n")
//    rbits := b_s
//    prstate()
  }

  // R must be in a memory location
  genopmemreg("movl", rbits, rn, "%ecx")
  rbits := rbits | b_b
  prstate()
}

AND moveL2B() BE
{ // Compile code to ensure that L is in B
  // and R is not in B
  // ie that (lbits & b_b) > 0 and
  // that (rbits & b_b) = 0

  trace("# moveL2B*n")

  IF rbits = b_b DO
  { // R is in B only so move it to A
    TEST lbits = b_a
    THEN { // Exchange A and B
           writef(" xchgl %%ecx,%%ebx*n")
           lbits := b_b
         }
    ELSE { writef(" movl %%ecx,%%ebx*n")
         }
    rbits := b_a
    prstate()
  }

  rbits := rbits & bn_b

  IF (lbits & b_b) > 0 RETURN

  UNLESS lbits DO
  { // L is undefined so give it the value in B
    lbits := b_b
    prstate()
    RETURN
  }

  IF (lbits & b_a) > 0 DO
  { // L is in A so move it to B
    writef(" movl %%ebx,%%ecx*n")
    lbits := b_b
    prstate()
    RETURN
  }

  IF lbits = b_x DO
  { // L is in X only so move it to B
    // Now pop X to B
//    writef(" fstps (%%esp)*n")
    lbits := b_b
    prstate()
  }

  // L must be in a memory location
  genopmemreg("movl", lbits, ln, "%ecx")
  lbits := lbits | b_b
  prstate()
}

AND moveR2X() BE
{ // Compile code to ensure that R is in X
  // and L is not in X
  // ie that (rbits & b_x) > 0 and
  // that (lbits & b_x) = 0

  trace("# moveR2X*n")

  // First ensure L is not in X
  IF lbits = b_x DO
  { //IF rbits = b_s DO
//    { // L is only in X and R is only in S
//      // so swap X and S
//      writef(" flds (%%esp)*n")
//      writef(" fxch %%st(1),%%st*n")
//      writef(" fstp (%%esp)*n")
//      lbits := lbits XOR b_sx  // L moved to S
//      rbits := rbits XOR b_sx  // R moved to X
//      prstate()
//      RETURN
//    }
    // Move X to S
//    writef(" fstp (%%esp)*n")
//    lbits := lbits XOR b_sx  // L moved to S
//    prstate()
  }

  lbits := lbits & bn_x

  // L is no longer in X

  
  { // L is in X only so move it to S
//    IF (rbits = b_s) > 0 DO
//    { // R is in S so swap X and S
//      writef(" fstp (%%esp)*n")
//      // L is now only in S
//      lbits := b_s
//      prstate()
//    }
//  }

//  IF lbits = b_x & rbits = b_s DO
//  { // L is only in X and R is only in S
//    // so swap X and S
//    writef(" flds (%%esp)*n")
//    writef(" fxch %%st(1),%%st*n")
//    writef(" fstp (%%esp)*n")
//    lbits := lbits XOR b_sx  // L copied to S
//    rbits := rbits XOR b_sx  // R copied to X
//    prstate()
//  }

  // L is no longer in X

  UNLESS rbits DO
  { // R is undefined so give it an arbitrary value
    writef(" fld1*n")
    rbits := b_x
    prstate()
    RETURN
  }

  IF (rbits & b_pglm) > 0 DO
  { // R is in a memory location (PGLM) so move R to X
    genopmem("flds", rbits, rn)
    rbits := rbits | b_x
    prstate()
    RETURN
  }

  // R is in A, B or X
  IF (rbits & b_x) > 0 RETURN

  // R must be in A or B so move it to X via S

  // R is in A or B and L.

  TEST (rbits & b_a) > 0
  THEN writef(" movl %%ebx,(%%esp)*n")
  ELSE writef(" movl %%ecx,(%%esp)*n")

  rbits := rbits | b_s
  prstate()
  writef(" flds (%%esp)*n")
  rbits := rbits | b_x  // R is in X
  prstate()
}

AND moveL2X() BE
{ // Generate code to move L to X
  // ie (lbits & b_x) > 0 and
  // rbits ~= b_x
  trace("# moveL2X*n")

  // First ensure R is not in X
  IF rbits = b_x DO
  { // R is in X only
//    IF (lbits & b_s) = 0 DO
//    { // and L not in S -- move R to S
//      writef(" fstp (%%esp)*n")
//      // R is now only in S
//      rbits := b_s
//      prstate()
//    }
  }

//  IF rbits = b_x & lbits = b_s DO
//  { // R is only in X and L is only in S
//    // so swap X and S
//    writef(" flds (%%esp)*n")
//    writef(" fxch %%st(1),%%st*n")
//    writef(" fstp (%%esp)*n")
//    rbits := rbits XOR b_sx  // R copied to S
//    lbits := lbits XOR b_sx  // L copied to X
//    prstate()
//  }

  // R is no longer in X

  UNLESS lbits DO
  { // L is undefined so give it the value zero
    writef(" fld1*n")
    lbits := b_x
    prstate()
  }

  IF (lbits & b_x) > 0 RETURN

  // If L is in a memory location (PGLM) move L to X

  IF (lbits % b_pglm) > 0 DO
  { genopmem("flds", lbits, ln)
    lbits := lbits | b_x
    prstate()
    RETURN
  }

  // L must be in A or B so move it to X via S
  // First ensure R is not using S

  // L is in A or B and R is not using S.

  TEST (lbits & b_a) > 0
  THEN writef(" movl %%ebx,(%%esp)*n")
  ELSE writef(" movl %%ecx,(%%esp)*n")

  writef(" flds (%%esp)*n")
  lbits := lbits | b_x  // L is in X
  prstate()
}

AND moveR2anyreg() BE
{ // Ensure R is in A, B or X
  trace("# moveR2anyreg*n")

  // If R in X make sure L is not is X
  IF (rbits & b_x) > 0 DO
  { IF lbits = b_x DO
    { // Move L to S
      writef(" fstps (%%esp)*n")
    } 
  }

  moveR2A()
}

AND moveL2anyreg() BE
{ // Ensure L is in A, B or X
  trace("# moveL2anyreg*n")

  // If L in X make sure L is not is X
  IF (lbits & b_x) > 0 RETURN

  moveL2B()
}

AND moveR2mem() BE
{ // Ensure R is in Pn, Gn, Ln, Mn or S
  trace("# moveR2mem*n")

  IF (rbits & b_pglm) > 0 RETURN // Already im memory

  // R is not in memory so move it to S

  // First check L is not in S

  IF lbits = b_s DO moveL2B()
  lbits := lbits & bn_s
  prstate()

  moveR2S()
}

AND moveL2mem() BE
{ // Ensure L is in Pn, Gn, Ln, Mn or S
  trace("# moveL2mem*n")

  IF (lbits & b_pglm) > 0 RETURN // Already im memory

  // L is not in memory so move it to S

  // First check R is not in S

  IF rbits = b_s DO moveR2A()
  rbits := rbits & bn_s
  prstate()

  moveL2S()
}

AND genaddr(bits, n) BE
{ // (bits, n) must correspond to a memory address
  // ie must contain b_s, b_p, b_g, b_l or b_m

  IF (bits & b_s) > 0 DO
  { writef("(%%esp)")
    RETURN
  }

  IF (bits & b_p) > 0 DO
  { writef("%n(%%ebp)", 4*n)
    RETURN
  }

  IF (bits & b_g) > 0 DO
  { writef("%n(%%esi)", 4*n)
    RETURN
  }

  IF (bits & b_l) > 0 DO
  { writef("L%c%n", modletter, n)
    RETURN
  }

  IF (bits & b_m) > 0 DO
  { writef("M%c%n", modletter, n)
    RETURN
  }
}

AND genopmem(opstr, bits, n) BE
{ writef(" %s ", opstr)
  genaddr(bits, n)
  newline()
}

AND genopmemreg(opstr, bits, n, regstr) BE
{ writef(" %s ", opstr)
  genaddr(bits, n)
  writef(",%s*n", regstr)
}

AND genopregmem(opstr, regstr, bits, n) BE
{ writef(" %s ", opstr)
  writef("%s,", regstr)
  genaddr(bits, n)
  newline()
}

AND scan() BE
{ LET op = rdf()

  SWITCHON op INTO

  { DEFAULT:       error("# Bad op %n*n", op); LOOP

    CASE -1:       RETURN
      
    CASE f_lp:     cvfp("LP") // R := P!n
                   // Specify that the value of R is now in Pn
                   rbits, rn := b_p, pval
                   ENDCASE

    CASE f_lg:     cvfg("LG") // R := G!n
                   // Specify that the value of R is now in Gn
                   rbits, rn := b_g, gval
                   ENDCASE

    CASE f_ll:     cvfl("LL") // R := !Ln
                   // Specify that the value of R is now in Ln
                   rbits, rn := b_l, lval
                   ENDCASE

    CASE f_llp:    cvfp("LLP") // R := @ P!n
                   IF (lbits & b_a) > 0 DO
                   { writef(" movl %%ebx,%%ecx*n")
                     lbits := b_b
                     prstate()
                   }
                   genopmemreg("leal", b_p, pval, "%ebx")
                   writef(" shrl $2,%%ebx*n")
                   rbits := b_a
                   prstate()
                   ENDCASE

    CASE f_llg:    cvfg("LLG") // R := @ G!n
                   IF (lbits & b_a) > 0 DO
                   { writef(" movl %%ebx,%%ecx*n")
                     lbits := b_b
                     prstate()
                   }
                   genopmemreg("leal", b_g, gval, "%ebx")
                   writef(" shrl $2,%%ebx*n")
                   rbits := b_a
                   prstate()
                   ENDCASE

    CASE f_lll:    cvfl("LLL") // R := @ !Ln
                   IF (lbits & b_a) > 0 DO
                   { writef(" movl %%ebx,%%ecx*n")
                     lbits := b_b
                     prstate()
                   }
                   genopmemreg("leal", b_l, lval, "%ebx")
                   writef(" shrl $2,%%ebx*n")
                   rbits := b_a
                   prstate()
                   ENDCASE

    CASE f_lf:     cvfl("LF") // R := byte address of Ln
                   IF (lbits & b_a) > 0 DO
                   { writef(" movl %%ebx,%%ecx*n")
                     lbits := b_b
                     prstate()
                   }
                   genopmemreg("leal", b_l, lval, "%ebx")
                   rbits := b_a
                   prstate()
                   ENDCASE

    CASE f_lw:     cvfm("LW") // R := Mn
                   // Specify that the value of R is now in Mn
                   rbits, rn := b_m, mval
                   ENDCASE

    CASE f_l:      cvfk("L") // R := n
                   IF (lbits & b_a) > 0 DO
                   { writef(" movl %%ebx,%%ecx*n")
                     lbits := b_b
                     prstate()
                   }
                   TEST kval
                   THEN writef(" movl $%n,%%ebx*n", kval)
                   ELSE writef(" xorl %%ebx,%%ebx*n")
                   rbits := b_a
                   prstate()
                   ENDCASE

    CASE f_lm:     cvfk("LM") // a := -n
                   IF (lbits & b_a) > 0 DO
                   { writef(" movl %%ebx,%%ecx*n")
                     lbits := b_b
                     prstate()
                   }
                   TEST kval
                   THEN writef(" movl $-%n,%%ebx*n", kval)
                   ELSE writef(" xorl %%ebx,%%ebx*n")
                   rbits := b_a
                   prstate()
                   ENDCASE

    CASE f_sp:     cvfp("SP") // P!n := R
                   IF lbits=b_p & ln=pval DO moveL2anyreg()

                   moveR2anyreg() // Move R into A, B or X
                   IF (rbits & b_x) > 0 DO
                   { genopmem("fstps", FALSE, b_p, pval)
                     rbits, rn := b_p, pval
                     lbits := lbits & bn_p
                     ENDCASE
                   }
                   TEST (rbits & b_a) > 0
                   THEN { genopregmem("movl", "%ebx", b_p, pval)
                          rbits, rn := b_ap, pval
                        }
                   ELSE { genopregmem("movl", "%ecx", b_p, pval)
                          rbits, rn := b_bp, pval
                        }
                   lbits := lbits & bn_p
                   ENDCASE

    CASE f_sg:     cvfg("SG") // G!n := R
                   IF lbits=b_g & ln=gval DO moveL2anyreg()

                   moveR2anyreg() // Move R into A, B or X

                   IF (rbits & b_x) > 0 DO
                   { genopmem("fstps", FALSE, b_g, gval)
                     rbits, rn := b_g, gval
                     lbits := lbits & bn_g
                     ENDCASE
                   }
                   TEST (rbits & b_a) > 0
                   THEN { genopregmem("movl", "%ebx", b_g, gval)
                          rbits, rn := b_ag, gval
                        }
                   ELSE { genopregmem("movl", "%ecx", b_g, gval)
                          rbits, rn := b_bg, gval
                        }
                   lbits := lbits & bn_g
                   ENDCASE

    CASE f_sl:     cvfl("SL") // !Ln := a
                   moveR2A()
                   genopregmem("movl", "%ebx", b_l, lval)
                   rbits, rn := b_al, lval
                   lbits := lbits & bn_l
                   prstate()
                   ENDCASE

    CASE f_ap:     cvfp("AP") // a := a + P!n
                   moveR2A()
                   genopmemreg("addl", b_p, pval, "%ebx")
                   rbits := b_a
                   prstate() 
                   ENDCASE

    CASE f_ag:     cvfg("AG") // a := a + G!n
                   moveR2A()
                   writef(" addl %n(%%esi),%%ebx*n", 4*gval)
                   rbits := b_a
                   prstate() 
                   ENDCASE

    CASE f_a:      cvfk("A") // a := a + n
                   moveR2A()
                   rbits := b_a 
                   IF kval=0 ENDCASE
                   IF kval=1  DO { writef(" incl %%ebx*n"); ENDCASE }
                   IF kval=-1 DO { writef(" decl %%ebx*n"); ENDCASE }
                   writef(" addl $%n,%%ebx*n", kval)
                   ENDCASE

    CASE f_s:      cvfk("S")  // a := a - n
                   moveR2A()
                   rbits := b_a 
                   IF kval=0 ENDCASE
                   IF kval=1  DO { writef(" decl %%ebx*n"); ENDCASE }
                   IF kval=-1 DO { writef(" incl %%ebx*n"); ENDCASE }
                   writef(" subl $%n,%%ebx*n", kval)
                   ENDCASE

    CASE f_lkp:    cvfkp("LKP") // a := P!n!k
                   moveR2A()
                   writef(" movl %n(%%ebp),%%eax*n", 4*pval)
                   writef(" movl %n(,%%eax,4),%%ebx*n", 4*kval)
                   rbits := b_a
                   ENDCASE

    CASE f_lkg:    cvfkg("LKG") // a := G!n!k
                   moveR2A()
                   writef(" movl %n(%%esi),%%eax*n", 4*gval)
                   writef(" movl %n(,%%eax,4),%%ebx*n", 4*kval)
                   rbits := b_a
                   ENDCASE

    CASE f_rv:     cvf("RV")  // a := ! a
                   moveR2A()
                   writef(" movl (,%%ebx,4),%%ebx*n")
                   lbits, rbits := lbits & bn_a, b_a
                   ENDCASE

    CASE f_rvp:    cvfp("RVP") // a := P!n!a
                   moveR2A()
                   writef(" addl %n(%%ebp),%%ebx*n", 4*pval)
                   writef(" movl (,%%ebx,4),%%ebx*n")
                   lbits, rbits := lbits & bn_a, b_a
                   ENDCASE

    CASE f_rvk:    cvfk("RVK") // a := a!k
                   moveR2A()
                   writef(" movl %n(,%%ebx,4),%%ebx*n", 4*kval)
                   lbits, rbits := lbits & bn_a, b_a
                   ENDCASE

    CASE f_st:     cvf("ST") // !a := b
                   moveL2B()
                   moveR2A()
                   writef(" movl %%ecx,(,%%ebx,4)*n")
                   rbits := rbits & b_abx
                   lbits := lbits & b_abx
                   ENDCASE

    CASE f_stp:    cvfp("STP") // P!n!a := b
                   moveL2B()
                   moveR2A()
                   writef(" movl %n(%%ebp),%%eax*n", 4*pval)
                   writef(" addl %%ebx,%%eax*n")
                   writef(" movl %%ecx,(,%%eax,4)*n")
                   rbits := rbits & b_abx
                   lbits := lbits & b_abx
                   ENDCASE

    CASE f_stk:    cvfk("STK") // a!n := b
                   moveL2B()
                   moveR2A()
                   writef(" movl %%ecx,%n(,%%ebx,4)*n", 4*kval)
                   rbits := rbits & b_abx
                   lbits := lbits & b_abx
                   ENDCASE

    CASE f_stkp:   cvfkp("STKP")  // P!n!k := a
                   moveR2A()
                   writef(" movl %n(%%ebp),%%eax*n", 4*pval)
                   writef(" movl %%ebx,%n(,%%eax,4)*n", 4*kval)
                   rbits := 0
                   lbits := 0
                   ENDCASE

    CASE f_skg:    cvfkg("SKG") // G!n!k := a
                   moveR2A()
                   writef(" movl %n(%%esi),%%eax*n", 4*gval)
                   writef(" movl %%ebx,%n(,%%eax,4)*n", 4*kval)
                   rbits := rbits & b_abx
                   lbits := lbits & b_abx
                   ENDCASE

    CASE f_xst:    cvf("XST") // !b := a
                   moveL2B()
                   moveR2A()
                   writef(" movl %%ebx,(,%%ecx,4)*n")
                   rbits := rbits & b_abx
                   lbits := lbits & b_abx
                   ENDCASE

    CASE f_k:      cvfp("K") // Call  a(b,...) incrementing P by n
                   moveL2B()
                   moveR2A()
                   writef(" movl %%ebx,%%eax*n")
                   writef(" movl %%ecx,%%ebx*n")
                   writef(" leal %n(%%ebp),%%edx*n", 4*pval)
                   writef(" call **%%eax*n")
                   lbits, rbits := 0, b_a
                   ENDCASE

    CASE f_kpg:    cvfpg("KPG") // Call Gg(a,...) incrementing P by n
                   moveR2A()
                   writef(" movl %n(%%esi),%%eax*n", 4*gval)
                   writef(" leal %n(%%ebp),%%edx*n", 4*pval)
                   writef(" call **%%eax*n")
                   lbits, rbits := 0, b_a
                   ENDCASE

    CASE f_neg:    cvf("NEG") // a := - a
                   moveR2A()
                   writef(" negl %%ebx*n") 
                   rbits := b_a
                   ENDCASE

    CASE f_not:    cvf("NOT") // a := ~ a
                   moveR2A()
                   writef(" notl %%ebx*n") 
                   rbits := b_a
                   ENDCASE

    CASE f_abs:    cvf("ABS") // a := ABS a
                   moveR2A()
                 { LET l = nextlab()
                   writef(" orl %%ebx,%%ebx*n")
                   writef(" jge L%n*n", l)
                   writef(" negl %%ebx*n")
                   writef("L%n:*n", l)
                   rbits := b_a
                   ENDCASE
                 }

    CASE f_xdiv:   cvf("XDIV") // a := a / b
                   moveL2B()
                   moveR2A()
                   writef(" movl %%ebx,%%eax*n")
                   writef(" cdq*n")
                   writef(" idiv %%ecx*n")
                   writef(" movl %%eax,%%ebx*n")
                   rbits := b_a
                   ENDCASE

    CASE f_xrem:   cvf("XREM") // a := a REM b
                   moveL2B()
                   moveR2A()
                   writef(" movl %%ebx,%%eax*n")
                   writef(" cdq*n")
                   writef(" idiv %%ecx*n")
                   writef(" movl %%edx,%%ebx*n")
                   rbits := b_a
                   ENDCASE

    CASE f_xsub:   cvf("XSUB") // a := a - b
                   moveL2B()
                   moveR2A()
                   writef(" subl %%ecx,%%ebx*n")
                   rbits := b_a
                   ENDCASE

    CASE f_mul:    cvf("MUL") // a := b * a; c := ?
                   moveL2B()
                   moveR2A()
                   writef(" movl %%ecx,%%eax*n")
                   writef(" imul %%ebx*n") // currupts edx
                   writef(" movl %%eax,%%ebx*n")
                   rbits := b_a
                   ENDCASE

    CASE f_div:    cvf("DIV")  // a := b / a; c := ?
                   moveL2B()
                   moveR2A()
                   writef(" movl %%ecx,%%eax*n")
                   writef(" cdq*n")
                   writef(" idiv %%ebx*n")
                   writef(" movl %%eax,%%ebx*n")
                   rbits := b_a
                   ENDCASE

    CASE f_rem:    cvf("REM") // a := b REM a; c := ?
                   moveL2B()
                   moveR2A()
                   writef(" movl %%ecx,%%eax*n")
                   writef(" cdq*n")
                   writef(" idiv %%ebx*n")
                   writef(" movl %%edx,%%ebx*n")
                   rbits := b_a
                   ENDCASE

    CASE f_add:    cvf("ADD") // a := b + a
                   moveL2B()
                   moveR2A()
                   writef(" addl %%ecx,%%ebx*n")
                   rbits := b_a
                   ENDCASE

    CASE f_sub:    cvf("SUB") // a := b - a
                   moveL2B()
                   moveR2A()
                   writef(" subl %%ecx,%%ebx*n")
                   writef(" negl %%ebx")
                   rbits := b_a
                   ENDCASE

    CASE f_eq:     cvf("EQ") // a := b = a
                   moveL2B()
                   moveR2A()
                   writef(" cmpl %%ebx,%%ecx*n")
                   writef(" seteb %%bl*n")
                   writef(" movzbl %%bl,%%ebx*n")
                   writef(" negl %%ebx*n")
                   rbits := b_a 
                   lbits := b_b 
                   ENDCASE

    CASE f_ne:     cvf("NE") // a := b ~= a
                   moveL2B()
                   moveR2A()
                   writef(" cmpl %%ebx,%%ecx*n")
                   writef(" setneb %%bl*n")
                   writef(" movzbl %%bl,%%ebx*n")
                   writef(" negl %%ebx*n")
                   rbits := b_a 
                   lbits := b_b 
                   ENDCASE

    CASE f_ls:     cvf("LS") // a := b < a
                   moveL2B()
                   moveR2A()
                   writef(" cmpl %%ebx,%%ecx*n")
                   writef(" setlb %%bl*n")
                   writef(" movzbl %%bl,%%ebx*n")
                   writef(" negl %%ebx*n")
                   rbits := b_a 
                   lbits := b_b 
                   ENDCASE

    CASE f_gr:     cvf("GR") // a := b > a
                   moveL2B()
                   moveR2A()
                   writef(" cmpl %%ebx,%%ecx*n")
                   writef(" setgb %%bl*n")
                   writef(" movzbl %%bl,%%ebx*n")
                   writef(" negl %%ebx*n")
                   rbits := b_a 
                   lbits := b_b 
                   ENDCASE

    CASE f_le:     cvf("LE") // a := b <= a
                   moveL2B()
                   moveR2A()
                   writef(" cmpl %%ebx,%%ecx*n")
                   writef(" setleb %%bl*n")
                   writef(" movzbl %%bl,%%ebx*n")
                   writef(" negl %%ebx*n")
                   rbits := b_a 
                   lbits := b_b 
                   ENDCASE

    CASE f_ge:     cvf("GE") // a := b >= a
                   moveL2B()
                   moveR2A()
                   writef(" cmpl %%ebx,%%ecx*n")
                   writef(" setgeb %%bl*n")
                   writef(" movzbl %%bl,%%ebx*n")
                   writef(" negl %%ebx*n")
                   rbits := b_a 
                   lbits := b_b 
                   ENDCASE

    CASE f_eq0:    cvf("EQ0") // a := a = 0
                   moveR2A()
                   writef(" orl %%ebx,%%ebx*n")
                   writef(" seteb %%bl*n")
                   writef(" movzbl %%bl,%%ebx*n")
                   writef(" negl %%ebx*n")
                   rbits := b_a 
                   ENDCASE

    CASE f_ne0:    cvf("NE0") // a := a ~= 0
                   moveR2A()
                   writef(" orl %%ebx,%%ebx*n")
                   writef(" setneb %%bl*n")
                   writef(" movzbl %%bl,%%ebx*n")
                   writef(" negl %%ebx*n")
                   rbits := b_a 
                   ENDCASE

    CASE f_ls0:    cvf("LS0") // a := a < 0
                   moveR2A()
                   writef(" sarl $31,%%ebx*n")
                   rbits := b_a 
                   ENDCASE

    CASE f_gr0:    cvf("GR0") // a := a > 0
                   moveR2A()
                   writef(" orl %%ebx,%%ebx*n")
                   writef(" setgb %%bl*n")
                   writef(" movzbl %%bl,%%ebx*n")
                   writef(" negl %%ebx*n")
                   rbits := b_a 
                   ENDCASE

    CASE f_le0:    cvf("LE0") // a := a <= 0
                   moveR2A()
                   writef(" orl %%ebx,%%ebx*n")
                   writef(" setleb %%bl*n")
                   writef(" movzbl %%bl,%%ebx*n")
                   writef(" negl %%ebx*n")
                   rbits := b_a 
                   ENDCASE

    CASE f_ge0:    cvf("GE0") // a := a >= 0
                   moveR2A()
                   writef(" sarl $31,%%ebx*n")
                   writef(" notl %%ebx*n")
                   rbits := b_a 
                   ENDCASE

    CASE f_lsh:    cvf("LSH") // a := b << a; b := ?
                   moveL2B()
                   moveR2A()
                   writef(" xchgl %%ebx,%%ecx*n")
                   writef(" cmpl $32,%%ecx*n")
                   writef(" sbbl %%eax,%%eax*n")  // set eax to -1 or 0
                   writef(" andl %%eax,%%ebx*n")  // set ebx to b or 0
                   writef(" sall %%cl,%%ebx*n")   // now shift it
                   rbits := b_a 
                   lbits := 0 
                   ENDCASE

    CASE f_rsh:    cvf("RSH") // a := b >> a; b := ?
                   moveL2B()
                   moveR2A()
                   writef(" xchgl %%ebx,%%ecx*n")
                   writef(" cmpl $32,%%ecx*n")
                   writef(" sbbl %%eax,%%eax*n")  // set eax to -1 or 0
                   writef(" andl %%eax,%%ebx*n")  // set ebx to b or 0
                   writef(" shrl %%cl,%%ebx*n")   // now shift it
                   rbits := b_a 
                   lbits := 0 
                   prstate()
                   ENDCASE

    CASE f_and:    cvf("AND") // a := b & a 
                   moveL2B()
                   moveR2A()
                   writef(" andl %%ecx,%%ebx*n") 
                   rbits := b_a 
                   prstate()
                   ENDCASE

    CASE f_or:     cvf("OR") // a := b | a 
                   moveL2B()
                   moveR2A()
                   writef(" orl %%ecx,%%ebx*n") 
                   rbits := b_a 
                   prstate()
                   ENDCASE

    CASE f_xor:    cvf("XOR") // a := b NEQV a
                   moveL2B()
                   moveR2A()
                   writef(" xorl %%ecx,%%ebx*n") 
                   rbits := b_a 
                   prstate()
                   ENDCASE

    CASE f_eqv:    cvf("EQV") // a := b EQV a 
                   moveL2B()
                   moveR2A()
                   writef(" xorl %%ecx,%%ebx*n") 
                   writef(" notl %%ebx*n") 
                   rbits := b_a 
                   prstate()
                   ENDCASE

    CASE f_gbyt:   cvf("GBYT") // a := b % a
                   moveL2B()
                   moveR2A()
                   writef(" movzbl (%%ebx,%%ecx,4),%%ebx*n") 
                   rbits := b_a 
                   prstate()
                   ENDCASE

    CASE f_xgbyt:  cvf("XGBYT") // a := a % b 
                   moveL2B()
                   moveR2A()
                   writef(" movzbl (%%ecx,%%ebx,4),%%ebx*n")
                   rbits := b_a 
                   prstate()
                   ENDCASE

    CASE f_pbyt:   cvf("PBYT") // b % a := c
                   moveL2B()
                   moveR2A()
                   writef(" movb %%dl,(%%ebx,%%ecx,4)*n") 
                   rbits := rbits & b_abx
                   lbits := lbits & b_abx
                   prstate()
                   ENDCASE

    CASE f_xpbyt:  cvf("XPBYT") // a % b := c 
                   moveL2B()
                   moveR2A()
                   writef(" movb %%dl,(%%ecx,%%ebx,4)*n") 
                   rbits := rbits & b_abx
                   lbits := lbits & b_abx
                   prstate()
                   ENDCASE

// swb       Kn Ld K1 L1 ... Kn Ln   Linary chop switch, Ld default
    CASE f_swb:    cvswb()
                   ENDCASE

// swl       Kn Ld L1 ... Ln         Label vector switch, Ld default
    CASE f_swl:    cvswl()
                   ENDCASE

    CASE f_xch:    cvf("XCH") // swap a and b
                 { LET r, n = rbits, rn
                   rbits, rn := lbits, ln
                   lbits, ln := r, n
                   ENDCASE
                 }

    CASE f_atb:    cvf("ATB") // L := R
                   IF (rbits & b_a) > 0 DO
                   { TEST (lbits & b_b) > 0
                     THEN { writef(" xchgl %%ebx,%%ecx*n")
                            rbits := b_a
                          }
                     ELSE { writef(" movl %%ebx,%%ecx*n")
                          }
                     lbits := b_b
                     prstate()
                     ENDCASE
                   }
                   moveR2B()
                   lbits := b_b
                   ENDCASE

    CASE f_atc:    cvf("ATC") // c := a
                   moveR2A()
                   writef(" movl %%ebx,%%edx*n")
                   ENDCASE

    CASE f_bta:    cvf("BTA") // R := L
                   rbits, rn := lbits, ln
                   lbits := lbits & b_pglm
                   prstate()
                   ENDCASE

    CASE f_btc:    cvf("BTC") // c := b
                   moveL2B()
                   writef(" movl %%ecx,%%edx*n")
                   ENDCASE

    CASE f_atblp:  cvfp("ATBLP") // b := a; a := P!n
                   lbits, ln := rbits, rn
                   rbits, rn := b_p, pval
                   prstate()
                   ENDCASE

    CASE f_atblg:  cvfg("ATBLG") // b := a; a := G!n
                   lbits, ln := rbits, rn
                   rbits, rn := b_g, gval
                   ENDCASE

    CASE f_atbl:   cvfk("ATBL") // b := a; a := k
                   lbits, ln := rbits & bn_a, rn

                   // If R was in A, move A to B
                   IF (rbits & b_a) > 0 DO
                   { writef(" movl %%ebx,%%ecx*n")
                     lbits := b_b
                     prstate()
                   }
                   // Compile code to put k in A
                   TEST kval
                   THEN writef(" movl $%n,%%ebx*n", kval)
                   ELSE writef(" xorl %%ebx,%%ebx*n")
                   rbits := b_a
                   prstate()
                   ENDCASE

    CASE f_j:      cvfl("J") // jump to Ln
                   writef(" jmp L%c%n*n", modletter, lval)
                   lbits, rbits := 0, 0
                   prstate()
                   ENDCASE

    CASE f_rtn:    cvf("RTN") // procedure return
                   // Load A popping esp if necessary
                   moveR2A()
                   writef(" movl 4(%%ebp),%%eax*n")
                   writef(" movl 0(%%ebp),%%ebp*n")
                   writef(" jmp **%%eax*n")
                   lbits, rbits := 0, 0
                   prstate()
                   ENDCASE

    CASE f_goto:   cvf("GOTO") // jump to a
                   moveR2A()
                   writef(" jmp **%%ebx*n")
                   lbits, rbits := 0, 0
                   prstate()
                   ENDCASE

    CASE f_res:    cvf("RES")   // <res> := A
                   // RES occurs just before the jump to a result label or
                   // the label at the end of a conditional expression.
                   // It also could be just before a conditional jump in
                   // a switchon command when B = the switch expression value
                   // and B holds a case constant.
                   moveR2A()
                   moveL2B()
                   ENDCASE

    CASE f_ldres:  cvf("LDRES") // A := <res>
                   // LDRES always occurs imediately after the label
                   // jumped to by RESULTIS or the jump in a conditional
                   // expression, when the result value is in A.
                   // It is also used in switches to specify B holds
                   // the switch value. 
                   lbits, rbits := b_b, b_a
                   prstate()
                   ENDCASE

    CASE f_ikp:    cvfkp("IKP") // a := P!n + k; P!n := a
                   moveR2A()
                   writef(" movl %n(%%ebp),%%ebx*n", 4*pval)
                   TEST kval=1
                   THEN writef(" incl %%ebx*n")
                   ELSE TEST kval=-1
                        THEN writef(" decl %%ebx*n")
                        ELSE writef(" addl $%n,%%ebx*n", kval)
                   writef(" movl %%ebx,%n(%%ebp)*n", 4*pval)
                   rbits, rn := b_ap, pval
                   prstate()
                   ENDCASE

    CASE f_ikg:    cvfkg("IKG") // a := G!n + k; G!n := a
                   moveR2A()
                   writef(" movl %n(%%esi),%%ebx*n", 4*gval)
                   TEST kval=1
                   THEN writef(" incl %%ebx*n")
                   ELSE TEST kval=-1
                        THEN writef(" decl %%ebx*n")
                        ELSE writef(" addl $%n,%%ebx*n", kval)
                   writef(" movl %%ebx,%n(%%esi)*n", 4*gval)
                   rbits, rn := b_ag, gval
                   prstate()
                   ENDCASE

    CASE f_ikl:    cvfkl("IKL") // a := !Ln + k; !Ln := a
                   moveR2A()
                   writef(" movl L%c%n,%%ebx*n", modletter, lval)
                   TEST kval=1
                   THEN writef(" incl %%ebx*n")
                   ELSE TEST kval=-1
                        THEN writef(" decl %%ebx*n")
                        ELSE writef(" addl $%n,%%ebx*n", kval)
                   writef(" movl %%ebx,L%c%n*n", modletter, lval)
                   rbits, rn := b_al, lval
                   prstate()
                   ENDCASE

    CASE f_ip:     cvfp("IP") // a := P!n + a; P!n := a
                   moveR2A()
                   writef(" addl %n(%%ebp),%%ebx*n", 4*pval)
                   writef(" movl %%ebx,%n(%%ebp)*n", 4*pval)
                   rbits, rn := b_ap, pval
                   prstate()
                   ENDCASE

    CASE f_ig:     cvfg("IG") // a := G!n + a; G!n := a
                   moveR2A()
                   writef(" addl %n(%%esi),%%ebx*n", 4*gval)
                   writef(" movl %%ebx,%n(%%esi)*n", 4*gval)
                   rbits, rn := b_ag, gval
                   prstate()
                   ENDCASE

    CASE f_il:     cvfl("IL") // a := !Ln + a; !Ln := a
                   moveR2A()
                   writef(" addl L%c%n,%%ebx*n", modletter, lval)
                   writef(" movl %%ebx,L%c%n*n", modletter, lval)
                   rbits, rn := b_al, lval
                   prstate()
                   ENDCASE

    CASE f_jeq:    cvfl("JEQ") // Jump to Ln if b = a
                   moveL2B()
                   moveR2A()
                   writef(" cmpl %%ebx,%%ecx*n")
                   writef(" je L%c%n*n", modletter, lval)
                   ENDCASE

    CASE f_jne:    cvfl("JNE") // Jump to Ln if b ~= a
                   moveL2B()
                   moveR2A()
                   writef(" cmpl %%ebx,%%ecx*n")
                   writef(" jne L%c%n*n", modletter, lval)
                   ENDCASE

    CASE f_jls:    cvfl("JLS") // Jump to Ln if b < a
                   moveL2B()
                   moveR2A()
                   writef(" cmpl %%ebx,%%ecx*n")
                   writef(" jl L%c%n*n", modletter, lval)
                   ENDCASE

    CASE f_jgr:    cvfl("JGR") // Jump to Ln if b > a
                   moveL2B()
                   moveR2A()
                   writef(" cmpl %%ebx,%%ecx*n")
                   writef(" jg L%c%n*n", modletter, lval)
                   ENDCASE

    CASE f_jle:    cvfl("JLE") // Jump to Ln if b <= a
                   moveL2B()
                   moveR2A()
                   writef(" cmpl %%ebx,%%ecx*n")
                   writef(" jle L%c%n*n", modletter, lval)
                   ENDCASE

    CASE f_jge:    cvfl("JGE") // Jump to Ln if b >= a
                   moveL2B()
                   moveR2A()
                   writef(" cmpl %%ebx,%%ecx*n")
                   writef(" jge L%c%n*n", modletter, lval)
                   ENDCASE

    CASE f_jeq0:   cvfl("JEQ0") // Jump to Ln if a = 0
                   moveR2A()
                   writef(" orl %%ebx,%%ebx*n")
                   writef(" je L%c%n*n", modletter, lval)
                   ENDCASE

    CASE f_jne0:   cvfl("JNE0") // Jump to Ln if a ~= 0
                   moveR2A()
                   writef(" orl %%ebx,%%ebx*n")
                   writef(" jne L%c%n*n", modletter, lval)
                   ENDCASE

    CASE f_jls0:   cvfl("JLS0") // Jump to Ln if a < 0
                   moveR2A()
                   writef(" orl %%ebx,%%ebx*n")
                   writef(" jl L%c%n*n", modletter, lval)
                   ENDCASE

    CASE f_jgr0:   cvfl("JGR0") // Jump to Ln if a > 0
                   moveR2A()
                   writef(" orl %%ebx,%%ebx*n")
                   writef(" jg L%c%n*n", modletter, lval)
                   ENDCASE

    CASE f_jle0:   cvfl("JLE0") // Jump to Ln if a <= 0
                   moveR2A()
                   writef(" orl %%ebx,%%ebx*n")
                   writef(" jle L%c%n*n", modletter, lval)
                   ENDCASE

    CASE f_jge0:   cvfl("JGE0") // Jump to Ln if a >= 0
                   moveR2A()
                   writef(" orl %%ebx,%%ebx*n")
                   writef(" jge L%c%n*n", modletter, lval)
                   ENDCASE

    CASE f_jge0m:  cvfm("JGE0M") // Jump to Mn if a >= 0
                   moveR2A()
                   writef(" orl %%ebx,%%ebx*n")
                   writef(" jge M%c%n*n", modletter, mval)
                   ENDCASE

    // The following five opcodes are never generated by
    // the BCPL compiler
    CASE f_brk:    cvf("BRK") // Breakpoint instruction
                   writef(" unimplemented*n")
                   ENDCASE

    CASE f_nop:    cvf("NOP") // No operation
                   ENDCASE

    CASE f_chgco:  cvf("CHGCO") // Change coroutine
                   writef(" CHGCO unimplemented*n")
                   ENDCASE

    CASE f_mdiv:   cvf("MDIV") // a := Muldiv(P!3, P!4, P!5) 
                   writef(" MDIV unimplemented*n")
                   ENDCASE

    CASE f_sys:    cvf("SYS") // System function
                   writef(" SYS unimplemented*n")
                   ENDCASE

    CASE f_section:  cvfs("SECTION") // Name of section
                     FOR i = 0 TO charv%0 DO sectname%i := charv%i
                     lbits, rbits := 0, 0
                     ENDCASE

    CASE f_modstart: cvf("MODSTART") // Start of module  
                     sectname%0 := 0
                     lbits, rbits := 0, 0
                     ENDCASE

    CASE f_modend:   cvf("MODEND") // End of module 
                     modletter := modletter+1
                     lbits, rbits := 0, 0
                     ENDCASE

    CASE f_global:   cvglobal() // Global initialisation data
                     lbits, rbits := 0, 0
                     ENDCASE

    CASE f_string:   cvstring() // String constant
                     ENDCASE

    CASE f_const:    cvconst() // Large integer constant
                     ENDCASE

    CASE f_static:   cvstatic() // Static variable or table
                     ENDCASE

    CASE f_mlab:     cvfm("MLAB") // Destination of jge0m
                     writef("M%c%n:*n", modletter, mval)
                     lbits, rbits := 0, 0
                     prstate()
                     ENDCASE

    CASE f_lab:      cvfl("LAB") // Program label
                     writef("*nL%c%n:*n", modletter, lval)
                     lbits, rbits := 0, 0
                     prstate()
                     ENDCASE

    CASE f_lstr:     cvfm("LSTR") // a := Mn   (pointer to string)
                     IF lbits = b_a DO
                     { // L is in A only so move it to B
                       writef(" movl %%ebx,%%ecx*n")
                       lbits := b_b
                       prstate()
                     }
                     writef(" leal M%c%n,%%ebx*n", modletter, mval)
                     writef(" shrl $2,%%ebx*n")
                     lbits, rbits := lbits & bn_a, b_a
                     prstate()
                     ENDCASE

    CASE f_entry:    cventry() // Start of a function
                     ENDCASE

    CASE f_float:    cvf("FLOAT")
                     // Ensure L is not using X
                     IF lbits = b_x DO moveL2S()
                     // Ensure R is Pn, Gn, Ln, Mn or S
                     moveR2mem()
                     genopmem("filds", rbits, rn) // st[0] := FLOAT a
                     rbits := b_x
                     ENDCASE

    CASE f_fix:      cvf("FIX") // a := FIX a
                     moveR2X()
                     writef(" fistpl (%%esp)*n")
                     rbits := b_s
                     ENDCASE

    CASE f_fabs:     cvf("FABS") // R := #ABS R
                     moveR2X()
                     writef(" fabs*n")
                     rbits := b_x
                     prstate()
                     ENDCASE

    CASE f_fmul:     cvf("FMUL") // R := L #* R; L := ?

                     IF (lbits & b_x) > 0 DO
                     { moveR2mem()
                       genopmem("fmuls", rbits, rn)
                       lbits, rbits := 0, b_x
                       prstate()
                       ENDCASE
                     }

                     IF (rbits & b_x) > 0 DO
                     { moveL2mem()
                       genopmem("fmuls", lbits, ln)
                       lbits, rbits := 0, b_x
                       prstate()
                       ENDCASE
                     }

                     IF (lbits & b_spglm) > 0 DO
                     { genopmem("flds", lbits, ln)
                       lbits := b_x
                       moveR2mem()
                       genopmem("fmuls", rbits, rn)
                       lbits, rbits := 0, b_x
                       prstate()
                       ENDCASE
                     }

                     IF (rbits & b_spglm) > 0 DO
                     { genopmem("flds", rbits, rn)
                       rbits := b_x
                       moveL2mem()
                       genopmem("fmuls", lbits, ln)
                       lbits, rbits := 0, b_x
                       prstate()
                       ENDCASE
                     }

                     moveL2X()
                     lbits := b_x
                     moveR2mem()
                     genopmem("fmuls", rbits, rn)
                     lbits, rbits := 0, b_x
                     prstate()
                     ENDCASE
  
    CASE f_fdiv:     cvf("FDIV") // R := L #/ R; L := ?

                     IF (lbits & b_x) > 0 DO
                     { moveR2mem()
                       genopmem("fdivs", rbits, rn)
                       lbits, rbits := 0, b_x
                       prstate()
                       ENDCASE
                     }

                     IF (rbits & b_x) > 0 DO
                     { moveL2mem()
                       genopmem("fdivrs", lbits, ln)
                       lbits, rbits := 0, b_x
                       prstate()
                       ENDCASE
                     }

                     IF (lbits & b_spglm) > 0 DO
                     { genopmem("flds", lbits, ln)
                       lbits := b_x
                       moveR2mem()
                       genopmem("fdivs", rbits, rn)
                       lbits, rbits := 0, b_x
                       prstate()
                       ENDCASE
                     }

                     IF (rbits & b_spglm) > 0 DO
                     { genopmem("flds", rbits, rn)
                       rbits := b_x
                       moveL2mem()
                       genopmem("fdivrs", lbits, ln)
                       lbits, rbits := 0, b_x
                       prstate()
                       ENDCASE
                     }

                     moveL2X()
                     lbits := b_x
                     moveR2mem()
                     genopmem("fdivs", rbits, rn)
                     lbits, rbits := 0, b_x
                     prstate()
                     ENDCASE
  
    CASE f_fxdiv:    cvf("FXDIV") // R := R #/ L; L := ?

                     IF (lbits & b_x) > 0 DO
                     { moveR2mem()
                       genopmem("fdivrs", rbits, rn)
                       lbits, rbits := 0, b_x
                       prstate()
                       ENDCASE
                     }

                     IF (rbits & b_x) > 0 DO
                     { moveL2mem()
                       genopmem("fdivs", lbits, ln)
                       lbits, rbits := 0, b_x
                       prstate()
                       ENDCASE
                     }

                     IF (lbits & b_spglm) > 0 DO
                     { genopmem("flds", lbits, ln)
                       lbits := b_x
                       moveR2mem()
                       genopmem("fdivrs", rbits, rn)
                       lbits, rbits := 0, b_x
                       prstate()
                       ENDCASE
                     }

                     IF (rbits & b_spglm) > 0 DO
                     { genopmem("flds", rbits, rn)
                       rbits := b_x
                       moveL2mem()
                       genopmem("fdivs", lbits, ln)
                       lbits, rbits := 0, b_x
                       prstate()
                       ENDCASE
                     }

                     moveL2X()
                     lbits := b_x
                     moveR2mem()
                     genopmem("fdivrs", rbits, rn)
                     lbits, rbits := 0, b_x
                     prstate()
                     ENDCASE
  
    CASE f_fadd:     cvf("FADD") // R := L #+ R; L := ?

                     IF (lbits & b_x) > 0 DO
                     { moveR2mem()
                       genopmem("fadds", rbits, rn)
                       lbits, rbits := 0, b_x
                       prstate()
                       ENDCASE
                     }

                     IF (rbits & b_x) > 0 DO
                     { moveL2mem()
                       genopmem("fadds", lbits, ln)
                       lbits, rbits := 0, b_x
                       prstate()
                       ENDCASE
                     }

                     IF (lbits & b_spglm) > 0 DO
                     { genopmem("flds", lbits, ln)
                       lbits := b_x
                       moveR2mem()
                       genopmem("fadds", rbits, rn)
                       lbits, rbits := 0, b_x
                       prstate()
                       ENDCASE
                     }

                     IF (rbits & b_spglm) > 0 DO
                     { genopmem("flds", rbits, rn)
                       rbits := b_x
                       moveL2mem()
                       genopmem("fadds", lbits, ln)
                       lbits, rbits := 0, b_x
                       prstate()
                       ENDCASE
                     }

                     moveL2X()
                     lbits := b_x
                     moveR2mem()
                     genopmem("fadds", rbits, rn)
                     lbits, rbits := 0, b_x
                     prstate()
                     ENDCASE
  
    CASE f_fsub:     cvf("FSUB") // R := L #- R; L := ?

                     IF (lbits & b_x) > 0 DO
                     { moveR2mem()
                       genopmem("fsubs", rbits, rn)
                       lbits, rbits := 0, b_x
                       prstate()
                       ENDCASE
                     }

                     IF (rbits & b_x) > 0 DO
                     { moveL2mem()
                       genopmem("fsubrs", lbits, ln)
                       lbits, rbits := 0, b_x
                       prstate()
                       ENDCASE
                     }

                     IF (lbits & b_spglm) > 0 DO
                     { genopmem("flds", lbits, ln)
                       lbits := b_x
                       moveR2mem()
                       genopmem("fsubs", rbits, rn)
                       lbits, rbits := 0, b_x
                       prstate()
                       ENDCASE
                     }

                     IF (rbits & b_spglm) > 0 DO
                     { genopmem("flds", rbits, rn)
                       rbits := b_x
                       moveL2mem()
                       genopmem("fsubrs", lbits, ln)
                       lbits, rbits := 0, b_x
                       prstate()
                       ENDCASE
                     }

                     moveL2X()
                     lbits := b_x
                     moveR2mem()
                     genopmem("fsubs", rbits, rn)
                     lbits, rbits := 0, b_x
                     prstate()
                     ENDCASE
  
    CASE f_fneg:     cvf("FNEG") // R := #- R
                     moveR2X()
                     writef(" fchs*n")          // st[0] := #- a
                     rbits := b_x
                     prstate()
                     ENDCASE

    CASE f_feq:      cvf("FEQ")
                     moveL2B()
                     moveR2A()
                     writef(" pushl %%ecx*n")
                     writef(" flds (%%esp)*n")  // st[0] := b
                     writef(" pushl %%ebx*n")
                     writef(" flds (%%esp)*n")  // st[0], st[1] = a, b
                     writef(" addl $8,%%esp*n")
                     writef(" fucomip %%st(1),%%st*n")
                     writef(" fstp %%st*n")
                     writef(" seteb %%bl*n")
                     writef(" movzbl %%bl,%%ebx*n")
                     writef(" negl %%ebx*n")
                     rbits := b_a
                     prstate()
                     ENDCASE

    CASE f_fne:      cvf("FNE")
                     moveL2B()
                     moveR2A()
                     writef(" pushl %%ecx*n")
                     writef(" flds (%%esp)*n")  // st[0] := b
                     writef(" pushl %%ebx*n")
                     writef(" flds (%%esp)*n")  // st[0], st[1] = a, b
                     writef(" addl $8,%%esp*n")
                     writef(" fucomip %%st(1),%%st*n")
                     writef(" fstp %%st*n")
                     writef(" setneb %%bl*n")
                     writef(" movzbl %%bl,%%ebx*n")
                     writef(" negl %%ebx*n")
                     rbits := b_a
                     prstate()
                     ENDCASE

    CASE f_fls:      cvf("FLS")
                     moveL2B()
                     moveR2A()
                     writef(" pushl %%ecx*n")
                     writef(" flds (%%esp)*n")  // st[0] := b
                     writef(" pushl %%ebx*n")
                     writef(" flds (%%esp)*n")  // st[0], st[1] = a, b
                     writef(" addl $8,%%esp*n")
                     writef(" fucomip %%st(1),%%st*n")
                     writef(" fstp %%st*n")
                     writef(" seta %%bl*n")
                     writef(" movzbl %%bl,%%ebx*n")
                     writef(" negl %%ebx*n")
                     rbits := b_a
                     prstate()
                     ENDCASE

    CASE f_fgr:      cvf("FGR")
                     moveL2B()
                     moveR2A()
                     writef(" pushl %%ebx*n")
                     writef(" flds (%%esp)*n")  // st[0] := a
                     writef(" pushl %%ecx*n")
                     writef(" flds (%%esp)*n")  // st[0], st[1] = b, a
                     writef(" addl $8,%%esp*n")
                     writef(" fucomip %%st(1),%%st*n")
                     writef(" fstp %%st*n")
                     writef(" seta %%bl*n")
                     writef(" movzbl %%bl,%%ebx*n")
                     writef(" negl %%ebx*n")
                     rbits := b_a
                     prstate()
                     ENDCASE

    CASE f_fle:      cvf("FLE")
                     moveL2B()
                     moveR2A()
                     writef(" pushl %%ecx*n")
                     writef(" flds (%%esp)*n")  // st[0] := b
                     writef(" pushl %%ebx*n")
                     writef(" flds (%%esp)*n")  // st[0], st[1] = a, b
                     writef(" addl $8,%%esp*n")
                     writef(" fucomip %%st(1),%%st*n")
                     writef(" fstp %%st*n")
                     writef(" setae %%bl*n")
                     writef(" movzbl %%bl,%%ebx*n")
                     writef(" negl %%ebx*n")
                     rbits := b_a
                     prstate()
                     ENDCASE

    CASE f_fge:      cvf("FGE")
                     moveL2B()
                     moveR2A()
                     writef(" pushl %%ebx*n")
                     writef(" flds (%%esp)*n")  // st[0] := a
                     writef(" pushl %%ecx*n")
                     writef(" flds (%%esp)*n")  // st[0], st[1] = b, a
                     writef(" addl $8,%%esp*n")
                     writef(" fucomip %%st(1),%%st*n")
                     writef(" fstp %%st*n")
                     writef(" setae %%bl*n")
                     writef(" movzbl %%bl,%%ebx*n")
                     writef(" negl %%ebx*n")
                     rbits := b_a
                     prstate()
                     ENDCASE

    CASE f_feq0:     cvf("FEQ0")
                     moveR2X()
                     writef(" fldz*n")        // st[0], st[1] = 0.0, a
                     writef(" fucomip %%st(1),%%st*n")
                     writef(" fstp %%st*n")
                     writef(" seteb %%bl*n")
                     writef(" movzbl %%bl,%%ebx*n")
                     writef(" negl %%ebx*n")
                     rbits := b_a
                     ENDCASE

    CASE f_fne0:     cvf("FNE0")
                     moveR2X()
                     writef(" fldz*n")        // st[0], st[1] = 0.0, a
                     writef(" fucomip %%st(1),%%st*n")
                     writef(" fstp %%st*n")
                     writef(" setneb %%bl*n")
                     writef(" movzbl %%bl,%%ebx*n")
                     writef(" negl %%ebx*n")
                     rbits := b_a
                     prstate()
                     ENDCASE

    CASE f_fls0:     cvf("FLS0")
                     moveR2X()
                     writef(" fldz*n")        // st[0], st[1] = 0.0, a
                     writef(" fucomip %%st(1),%%st*n")
                     writef(" fstp %%st*n")
                     writef(" setab %%bl*n")
                     writef(" movzbl %%bl,%%ebx*n")
                     writef(" negl %%ebx*n")
                     rbits := b_a
                     prstate()
                     ENDCASE

    CASE f_fgr0:     cvf("FGR0")
                     moveR2X()
                     writef(" fldz*n")        // st[0], st[1] = 0.0, a
                     writef(" fucomip %%st(1),%%st*n")
                     writef(" fstp %%st*n")
                     writef(" setbb %%bl*n")
                     writef(" movzbl %%bl,%%ebx*n")
                     writef(" negl %%ebx*n")
                     rbits := b_a
                     prstate()
                     ENDCASE

    CASE f_fle0:     cvf("FLE0")
                     moveR2X()
                     writef(" fldz*n")        // st[0], st[1] = 0.0, a
                     writef(" fucomip %%st(1),%%st*n")
                     writef(" fstp %%st*n")
                     writef(" setaeb %%bl*n")
                     writef(" movzbl %%bl,%%ebx*n")
                     writef(" negl %%ebx*n")
                     rbits := b_a
                     prstate()
                     ENDCASE

    CASE f_fge0:     cvf("FGE0")
                     moveR2X()
                     writef(" fldz*n")        // st[0], st[1] = 0.0, a
                     writef(" fucomip %%st(1),%%st*n")
                     writef(" fstp %%st*n")
                     writef(" setbeb %%bl*n")
                     writef(" movzbl %%bl,%%ebx*n")
                     writef(" negl %%ebx*n")
                     rbits := b_a
                     prstate()
                     ENDCASE

    CASE f_jfeq:     cvfl("JFEQ")
                     moveL2B()
                     moveR2A()
                     writef(" pushl %%ecx*n")
                     writef(" flds (%%esp)*n")  // st[0] := b
                     writef(" pushl %%ebx*n")
                     writef(" flds (%%esp)*n")  // st[0], st[1] = a, b
                     writef(" addl $8,%%esp*n")
                     writef(" fucomip %%st(1),%%st*n")
                     writef(" fstp %%st*n")
                     writef(" je L%c%n*n", modletter, lval)
                     lbits, rbits := b_b, b_a
                     prstate()
                     ENDCASE

    CASE f_jfne:     cvfl("JFNE")
                     moveL2B()
                     moveR2A()
                     writef(" pushl %%ecx*n")
                     writef(" flds (%%esp)*n")  // st[0] := b
                     writef(" pushl %%ebx*n")
                     writef(" flds (%%esp)*n")  // st[0], st[1] = a, b
                     writef(" addl $8,%%esp*n")
                     writef(" fucomip %%st(1),%%st*n")
                     writef(" fstp %%st*n")
                     writef(" jne L%c%n*n", modletter, lval)
                     lbits, rbits := b_b, b_a
                     prstate()
                     ENDCASE

    CASE f_jfls:     cvfl("JFLS")
                     moveL2B()
                     moveR2A()
                     writef(" pushl %%ecx*n")
                     writef(" flds (%%esp)*n")  // st[0] := b
                     writef(" pushl %%ebx*n")
                     writef(" flds (%%esp)*n")  // st[0], st[1] = a, b
                     writef(" addl $8,%%esp*n")
                     writef(" fucomip %%st(1),%%st*n")
                     writef(" fstp %%st*n")
                     writef(" jne L%c%n*n", modletter, lval)
                     lbits, rbits := b_b, b_a
                     prstate()
                     ENDCASE

    CASE f_jfgr:     cvfl("JFGR")
                     moveL2B()
                     moveR2A()
                     writef(" pushl %%ecx*n")
                     writef(" flds (%%esp)*n")  // st[0] := b
                     writef(" pushl %%ebx*n")
                     writef(" flds (%%esp)*n")  // st[0], st[1] = a, b
                     writef(" addl $8,%%esp*n")
                     writef(" fucomip %%st(1),%%st*n")
                     writef(" fstp %%st*n")
                     writef(" jb L%c%n*n", modletter, lval)
                     lbits, rbits := b_b, b_a
                     prstate()
                     ENDCASE

    CASE f_jfle:     cvfl("JFLE")
                     moveL2B()
                     moveR2A()
                     writef(" pushl %%ecx*n")
                     writef(" flds (%%esp)*n")  // st[0] := b
                     writef(" pushl %%ebx*n")
                     writef(" flds (%%esp)*n")  // st[0], st[1] = a, b
                     writef(" addl $8,%%esp*n")
                     writef(" fucomip %%st(1),%%st*n")
                     writef(" fstp %%st*n")
                     writef(" jbe L%c%n*n", modletter, lval)
                     lbits, rbits := b_b, b_a
                     prstate()
                     ENDCASE

    CASE f_jfge:     cvfl("JFGE")
                     moveL2B()
                     moveR2A()
                     writef(" pushl %%ecx*n")
                     writef(" flds (%%esp)*n")  // st[0] := b
                     writef(" pushl %%ebx*n")
                     writef(" flds (%%esp)*n")  // st[0], st[1] = a, b
                     writef(" addl $8,%%esp*n")
                     writef(" fucomip %%st(1),%%st*n")
                     writef(" fstp %%st*n")
                     writef(" jae L%c%n*n", modletter, lval)
                     lbits, rbits := b_b, b_a
                     prstate()
                     ENDCASE

    CASE f_jfeq0:    cvfl("JFEQ0")
                     moveR2X()
                     writef(" fldz*n")        // st[0], st[1] = 0.0, a
                     writef(" fucomip %%st(1),%%st*n")
                     writef(" fstp %%st*n")
                     writef(" je L%c%n*n", modletter, lval)
                     lbits, rbits := b_b, b_a
                     prstate()
                     ENDCASE

    CASE f_jfne0:    cvfl("JFNE0")
                     moveR2X()
                     writef(" fldz*n")        // st[0], st[1] = 0.0, a
                     writef(" fucomip %%st(1),%%st*n")
                     writef(" fstp %%st*n")
                     writef(" jne L%c%n*n", modletter, lval)
                     lbits, rbits := b_b, b_a
                     prstate()
                     ENDCASE

    CASE f_jfls0:    cvfl("JFLS0")
                     moveR2X()
                     writef(" fldz*n")        // st[0], st[1] = 0.0, a
                     writef(" fucomip %%st(1),%%st*n")
                     writef(" fstp %%st*n")
                     writef(" ja L%c%n*n", modletter, lval)
                     lbits, rbits := b_b, b_a
                     prstate()
                     ENDCASE

    CASE f_jfgr0:    cvfl("JFGR0")
                     moveR2X()
                     writef(" fldz*n")        // st[0], st[1] = 0.0, a
                     writef(" fucomip %%st(1),%%st*n")
                     writef(" fstp %%st*n")
                     writef(" jb L%c%n*n", modletter, lval)
                     lbits, rbits := b_b, b_a
                     prstate()
                     ENDCASE

    CASE f_jfle0:    cvfl("JFLE0")
                     moveR2X()
                     writef(" fldz*n")        // st[0], st[1] = 0.0, a
                     writef(" fucomip %%st(1),%%st*n")
                     writef(" fstp %%st*n")
                     writef(" jae L%c%n*n", modletter, lval)
                     lbits, rbits := b_b, b_a
                     prstate()
                     ENDCASE

    CASE f_jfge0:    cvfl("JFGE0")
                     moveR2X()
                     writef(" fldz*n")        // st[0], st[1] = 0.0, a
                     writef(" fucomip %%st(1),%%st*n")
                     writef(" fstp %%st*n")
                     writef(" jbe L%c%n*n", modletter, lval)
                     lbits, rbits := b_b, b_a
                     prstate()
                     ENDCASE
  }
} REPEAT

AND cvf(s)   BE { prstate()
                  writef("# %s*n", s)
                } 
AND cvfp(s)  BE { prstate()
                  writef("# %t7 P%n*n", s, rdp())
                } 
AND cvfkp(s) BE { prstate()
                  writef("# %t7 K%n P%n*n", s, rdk(), rdp())
                } 
AND cvfg(s)  BE { prstate()
                  writef("# %t7 G%n*n", s, rdg())
                } 
AND cvfkg(s) BE { prstate()
                  writef("# %t7 K%n G%n*n", s, rdk(), rdg())
                } 
AND cvfkl(s) BE { prstate()
                  writef("# %t7 K%n L%n*n", s, rdk(), rdl())
                } 
AND cvfpg(s) BE { prstate()
                  writef("# %t7 P%n G%n*n", s, rdp(), rdg())
                } 
AND cvfk(s)  BE { prstate()
                  writef("# %t7 K%n*n", s, rdk())
                } 
AND cvfw(s)  BE { prstate()
                  writef("# %t7 W%n*n", s, rdw())
                } 
AND cvfl(s)  BE { prstate()
                  writef("# %t7 L%n*n", s, rdl())
                } 
AND cvfm(s)  BE { prstate()
                  writef("# %t7 M%n*n", s, rdm())
                } 

AND cvswl() BE
{ LET n = rdk()
  LET l = rdl()
  LET lab = nextlab()
  prstate()
  writef("# SWL K%n L%n*n", n, l)
  moveR2A()
  writef(" orl %%ebx,%%ebx*n")
  writef(" jl L%c%n*n", modletter, l)
  writef(" cmpl $%n,%%ebx*n", n)
  writef(" jge L%c%n*n", modletter, l)
  writef(" jmp **L%n(,%%ebx,4)*n", lab)
  writef(" .data*n")
  writef(" .align 4*n")
  writef("L%n:*n", lab)
  FOR i = 1 TO n DO
  { writef("# L%n*n", rdl())
    writef(" .long L%c%n*n", modletter, lval)
  }
  writef(" .text*n")
  lbits, rbits := 0, 0
  prstate()
}

AND cvswb() BE
{ LET n = rdk()
  LET l = rdl()
  prstate()
  writef("# SWB K%n L%n*n", n, l)
  moveR2A()
  FOR i = 1 TO n DO 
  { LET k = rdk()
    LET l = rdl()
    writef("# K%n L%n*n", k, l)
    writef(" cmpl $%n,%%ebx*n", k)
    writef(" je L%c%n*n", modletter, l)
  }
  writef(" jmp L%c%n*n", modletter, l)
  lbits, rbits := 0, 0
  prstate()
}

AND cvglobal() BE
{ LET n = rdk()
  moveL2B()
  moveR2A()
  writef("# GLOBAL K%n*n", n)
  IF sectname%0=0 FOR i = 0 TO 4 DO sectname%i := "prog"%i
  writef(".globl %s*n", sectname)
  writef(".globl _%s*n", sectname)
  writef("%s:*n", sectname)
  writef("_%s:*n", sectname)
  writef(" movl 4(%%esp),%%eax*n")
  FOR i = 1 TO n DO
  { LET g = rdg()
    LET n = rdl()
    writef("# G%n L%n*n", g, n)
    writef(" movl $L%c%n,%n(%%eax)*n", modletter, n, 4*g)
  }
  writef("# G%n*n", rdg())
  writef(" ret*n")
}

AND rdchars() = VALOF
{ LET n = rdk()
  charv%0 := n
  FOR i = 1 TO n DO charv%i := rdc()
  RESULTIS n
}

AND cvstring() BE
{ LET lab = rdm()
  LET n = rdchars()
  writef("# STRING  M%n K%n", lab, n)
  FOR i = 1 TO n DO writef(" C%n", charv%i)
  writef("*n.data*n")
  writef(" .align 4*n")
  writef("M%c%n:*n", modletter, lab)
  FOR i = 0 TO n DO writef(" .byte %n*n", charv%i)
  writef(" .text*n")
}

AND cvconst() BE
{ LET lab = rdm()
  LET w = rdw()
  writef("# CONST   M%n W%n*n", lab, w)
  writef(".data*n")
  writef(" .align 4*n")
  writef("M%c%n:*n", modletter, lab)
  writef(" .long %n*n", w)
  writef(" .text*n")
}

AND cvstatic() BE
{ LET lab = rdl()
  LET n = rdk()
  writef("# STATIC  L%n K%n*n", lab, n)
  writef(".data*n")
  writef(" .align 4*n")
  writef("L%c%n:*n", modletter, lab)
  FOR i = 1 TO n DO { writef("# W%n*n", rdw())
                      writef(" .long %n*n", wval)
                    }
  writef(" .text*n")
}

AND cvfs(s) BE
{ LET n = rdchars()
  writef("# %t7 K%n", s, n)
  FOR i = 1 TO n DO writef(" C%n", charv%i)
  newline()
}

AND cventry() BE
{ LET n = rdchars()
  LET op = rdf()
  LET lab = rdl()
  writef("*n# Entry to: %s*n", charv)
  writef("# %t7 K%n", "ENTRY", n)
  FOR i = 1 TO n DO writef(" C%n", charv%i)
  newline()
  TEST op=f_lab THEN writef("# LAB     L%n*n", lab)
                ELSE writef("# cventry: Bad op F%n L%n*n", op, lab)
  writef("L%c%n:*n", modletter, lab)
  writef(" movl %%ebp,(%%edx)*n")    // NP!0 := P
  writef(" movl %%edx,%%ebp*n")      // P    := NP
  writef(" popl %%edx*n")
  writef(" movl %%edx,4(%%ebp)*n")   // P!1  := return address
  writef(" movl %%eax,8(%%ebp)*n")   // P!2  := entry address
  writef(" movl %%ebx,12(%%ebp)*n")  // P!3  := arg1
  lbits := 0
  rbits, rn := b_ap, 3
  prstate()
}
