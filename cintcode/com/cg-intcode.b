// This is an OCODE to Intcode codegenerator dated 1982 approx

// This is being modified to run under the current version of BCPL.
// It will be the codegenerator of a new compiler called bcplint.b

// Implemented by Martin Richards (c) Sept 2012
/*
28/09/12
Began major modifications
Made into one section.

*/

//    CGHDR

SECTION "CG-INTCODE"

GET "libhdr"
GET "bcplfecg"

MANIFEST {
  s_char=200  // Extras
  s_iteml
  s_end=0
}


// Code Generator Globals:

GLOBAL
{}



GLOBAL
{
cgsects: cgg
ssp
state
ad_a
ad_k
datav
datap
datat
proglength
linep
param

maxgn
maxlab
maxssp

op
readop

rdl
gencode
force_nil
force_ad
force_ac
force_acad
swap
load
storein
cgstring
data
nextparam
code
complab
opcode
wr
wrk
wrdata
checklab
labnumber
cgerror

}

MANIFEST {
    m_n=0
    m_i
    m_p
    m_ip
    m_l
    m_il
    m_g
    m_ig
    f_l           = 'L'
    f_s           = 'S'
    f_a           = 'A'
    f_j           = 'J'
    f_t           = 'T'
    f_f           = 'F'
    f_k           = 'K'
    f_x           = 'X'
    f_d           = 'D'
    f_c           = 'C'
    nil=0
    ad
    ac
    acad
}


//.

//SECTION "IC-CG1"



//    CG1


//GET ""


LET cgsects(workvec, vecsize) BE UNTIL op=0 DO
{ LET p = workvec
/*
   tempv := p
   p := p+90
   tempt := p
   casek := p
   p := p+400
   casel := p
   p := p+400
   labv := p
   dp := workvec+vecsize
   labnumber := (dp-p)/10+10
   p := p+labnumber
   FOR lp = labv TO p-1 DO !lp := -1
   stv := p
   stvp := 0
   incode := FALSE
   maxgn := 0
   maxlab := 0
   maxssp := 0
   procdepth := 0
   info_a, info_b := 0, 0
   initstack(3)
   initdatalists()

   codew(0)  // For size of module.
   IF op=s_section DO
   { MANIFEST { upb=11 } // Max length of entry name
      LET n = rdn()
      LET v = VEC upb/bytesperword
      v%0 := upb
      // Pack up to 11 character of the name into v including
      // the first and last five.
      TEST n<=11
      THEN { FOR i = 1 TO n DO v%i := rdn()
             FOR i = n+1 TO 11 DO v%i := '*s'
           }
      ELSE { FOR i = 1 TO 5   DO v%i := rdn()
             FOR i = 6 TO n-6 DO rdn() // Ignore the middle characters
             FOR i = 6 TO 11  DO v%i := rdn()
             IF n>11 DO v%6 := '*''
           }
      IF naming DO { codew(sectword)
                      codew(pack4b(v%0, v%1, v% 2, v% 3))
                      codew(pack4b(v%4, v%5, v% 6, v% 7))
                      codew(pack4b(v%8, v%9, v%10, v%11))
                   }
      op := rdn()
   }

   scan()
   op := rdn()
   putw(0, stvp/4)  // Plant size of module.
   outputsection()
   progsize := progsize + stvp
*/
}

LET readop() = rdn()

// Read in an OCODE label.
AND rdl() = VALOF
{ LET l = rdn()
  //IF maxlab<l DO { maxlab := l; checklab() }
  RESULTIS l
}

// Read in a global number.
AND rdgn() = VALOF
{ LET g = rdn()
   IF maxgn<g DO maxgn := g
   RESULTIS g
}


///.


///SECTION "IC-CG2"


//    CG2


///GET ""

LET modestr(m) = VALOF SWITCHON m INTO
{ DEFAULT:   RESULTIS "Unknown mode"

  CASE m_n:  RESULTIS "N"
  CASE m_i:  RESULTIS "I"
  CASE m_p:  RESULTIS "P"
  CASE m_ip: RESULTIS "IP"
  CASE m_l:  RESULTIS "L"
  CASE m_il: RESULTIS "IL"
  CASE m_g:  RESULTIS "G"
  CASE m_ig: RESULTIS "IG"
}

LET statestr(s) = VALOF SWITCHON s INTO
{ DEFAULT:   RESULTIS "Unknown state"

  CASE nil:  RESULTIS "NIL"
  CASE ad:   RESULTIS "AD"
  CASE ac:   RESULTIS "AC"
  CASE acad: RESULTIS "ACAD"
}

LET opstr(op) = VALOF SWITCHON op INTO
{ DEFAULT:         RESULTIS "Unknown op"

  CASE s_abs:      RESULTIS "abs"
  CASE s_datalab:  RESULTIS "datalab"
  CASE s_div:      RESULTIS "div"
  CASE s_end:      RESULTIS "end"
  CASE s_endfor:   RESULTIS "endfor"
  CASE s_endproc:  RESULTIS "endproc"
  CASE s_entry:    RESULTIS "entry"
  CASE s_eq:       RESULTIS "eq"
  CASE s_eqv:      RESULTIS "eqv"
  CASE s_false:    RESULTIS "false"
  CASE s_finish:   RESULTIS "finish"
  CASE s_fnap:     RESULTIS "fnap"
  CASE s_fnrn:     RESULTIS "fnrn"
  CASE s_ge:       RESULTIS "ge"
  CASE s_getbyte:  RESULTIS "getbyte"
  CASE s_global:   RESULTIS "global"
  CASE s_goto:     RESULTIS "goto"
  CASE s_gr:       RESULTIS "gr"
  CASE s_itemn:    RESULTIS "itemn"
  CASE s_jf:       RESULTIS "jf"
  CASE s_jt:       RESULTIS "jt"
  CASE s_jump:     RESULTIS "jump"
  CASE s_lab:      RESULTIS "lab"
  CASE s_le:       RESULTIS "le"
  CASE s_lf:       RESULTIS "lf"
  CASE s_lg:       RESULTIS "lg"
  CASE s_ll:       RESULTIS "ll"
  CASE s_llg:      RESULTIS "llg"
  CASE s_lll :     RESULTIS "lll"
  CASE s_llp:      RESULTIS "llp"
  CASE s_ln:       RESULTIS "ln"
  CASE s_logand:   RESULTIS "logand"
  CASE s_logor:    RESULTIS "logor"
  CASE s_lp:       RESULTIS "lp"
  CASE s_ls:       RESULTIS "ls"
  CASE s_lshift:   RESULTIS "lshift"
  CASE s_lstr:     RESULTIS "lstr"
  CASE s_sub:      RESULTIS "sub"
  CASE s_mul:      RESULTIS "mul"
  CASE s_ne:       RESULTIS "ne"
  CASE s_neg:      RESULTIS "neg"
  CASE s_neqv:     RESULTIS "neqv"
  CASE s_none:     RESULTIS "none"
  CASE s_not:      RESULTIS "not"
  CASE s_add:      RESULTIS "add"
  CASE s_putbyte:  RESULTIS "putbyte"
  CASE s_query:    RESULTIS "query"
  CASE s_rem:      RESULTIS "rem"
  CASE s_res:      RESULTIS "res"
  CASE s_rshift:   RESULTIS "rshift"
  CASE s_rstack:   RESULTIS "rstack"
  CASE s_rtap:     RESULTIS "rtap"
  CASE s_rtrn:     RESULTIS "rtrn"
  CASE s_rv:       RESULTIS "rv"
  CASE s_save:     RESULTIS "save"
  CASE s_section:  RESULTIS "section"
  CASE s_sg:       RESULTIS "sg"
  CASE s_sl:       RESULTIS "sl"
  CASE s_sp:       RESULTIS "sp"
  CASE s_stack:    RESULTIS "stack"
  CASE s_stind:    RESULTIS "stind"
  CASE s_store:    RESULTIS "store"
  CASE s_switchon: RESULTIS "switchon"
  CASE s_true:     RESULTIS "true"


/*
// The following have been added for the extended compiler xbcpl

// Floating point operators and assignment operators, added 15/07/10

s_fnum // Floating point constants
s_float; s_fix; s_fabs
s_fmul; s_fdiv; s_fadd; s_fsub;  s_fpos; s_fneg
s_feq; s_fne; s_fls; s_fgr; s_fle; s_fge

// Assign operators -- added 15/07/10
s_assvecap
s_assmul; s_assdiv; s_assrem; s_assadd; s_asssub
s_assfmul; s_assfdiv; s_assfadd; s_assfsub
s_asslshift; s_assrshift
s_asslogand; s_asslogor; s_asseqv; s_assneqv


s_selld; s_selst // Added 19/07/10

s_fltop  // FLTOP is followed by one of the fl_ codes
         // eg FLTOP FADD to do a := b #+ a
         // or FLTOP FLOAT to do a := FLOAT a

sf_none=0     // Assignment operators
sf_vecap
sf_fmul
sf_fdiv
sf_fadd
sf_fsub
sf_mul
sf_div
sf_rem
sf_add
sf_sub
sf_lshift
sf_rshift
sf_logand
sf_logor
sf_eqv
sf_neqv
*/
}

LET gencode() BE
{
//writef("gencode: op=%s*n", opstr(op))
IF debug>1 DO
      writef("IC-CG: STATE=%s, SSP=%N, AD_A=%N, AD_K=%s*N",
                     statestr(state), ssp, ad_a, modestr(ad_k))
  SWITCHON op INTO
  { DEFAULT:
      selectoutput(sysprint)
      writef("IC-CG: unknown OCODE number:  %N*N", op)
      selectoutput(gostream)
      ENDCASE

    CASE s_none:
    CASE s_end:
IF debug>0 DO writef("*n// %s*n", opstr(op))
    //CASE 0:
      RETURN

    CASE s_needs:
      wr('*N')
      writes("/ NEEDS ")
      FOR i=1 TO rdn() DO wrch(rdn())
      wr('*N')
      ENDCASE

    CASE s_lp:
    { LET p = rdn()
IF debug>0 DO writef("*n// %s P%n*n", opstr(op), p)
      load(p, m_ip)
      ENDCASE
    }

    CASE s_lg:
    { LET g = rdn()
IF debug>0 DO writef("*n// %s G%n*n", opstr(op), g)
      load(g, m_ig)
      ENDCASE
    }

    CASE s_ll:
    { LET l = rdl()
IF debug>0 DO writef("*n// %s L%n*n", opstr(op), l)
      load(l, m_il)
      ENDCASE
    }

    CASE s_lf:
    { LET l = rdl()
IF debug>0 DO writef("*n// %s %n*n", opstr(op), l)
      load(l, m_l)
      ENDCASE
    }

    CASE s_ln:
    { LET n = rdl()
IF debug>0 DO writef("*n// %s L%n*n", opstr(op), n)
      load(n, m_n)
      ENDCASE
    }

    CASE s_lstr:
      cgstring(rdn())
      ENDCASE

    CASE s_true:
IF debug>0 DO writef("*n// %s*n", opstr(op))
      load(-1, m_n)
      ENDCASE

    CASE s_false:
IF debug>0 DO writef("*n// %s*n", opstr(op))
      load(0, m_n)
      ENDCASE

    CASE s_llp:
    { LET p = rdn()
IF debug>0 DO writef("*n// %s P%n*n", opstr(op), p)
      load(p, m_p)
      ENDCASE
    }

    CASE s_llg:
    { LET g = rdn()
IF debug>0 DO writef("*n// %s G%n*n", opstr(op), g)
      load(g, m_g)
      ENDCASE
    }

    CASE s_lll:
    { LET l = rdl()
IF debug>0 DO writef("*n// %s L%n*n", opstr(op), l)
      load(l, m_l)
      ENDCASE
    }

    CASE s_sp:
    { LET p = rdn()
IF debug>0 DO writef("*n// %s P%n*n", opstr(op), p)
      storein(p, m_p)
      ENDCASE
    }

    CASE s_sg:
    { LET g = rdn()
IF debug>0 DO writef("*n// %s G%n*n", opstr(op), g)
      storein(g, m_g)
      ENDCASE
    }

    CASE s_sl:
    { LET l = rdl()
IF debug>0 DO writef("*n// %s L%n*n", opstr(op), l)
      storein(l, m_l)
      ENDCASE
    }

    CASE s_stind:
IF debug>0 DO writef("*n// %s*n", opstr(op))
      force_acad()
      code(f_s, ad_a, ad_k)
      ssp, state := ssp-2, nil
      ENDCASE

    CASE s_putbyte:
      // args on the stack are as follows:
      //         top of stack  ->  arg1
      //                           arg2
      //                           arg3
      // where the operation is  arg2%arg1 := arg3
IF debug>0 DO writef("*n// %s*n", opstr(op))
      force_nil()
      code(f_l, ssp-3, m_p)    // load address of vector on stack!
      code(f_x, opcode(s_putbyte), m_n)
      ssp := ssp-3
      state := nil
      ENDCASE

    CASE s_mul:    CASE s_div:     CASE s_rem:
    CASE s_sub:   CASE s_eq:      CASE s_ne:
    CASE s_ls:      CASE s_gr:      CASE s_le:
    CASE s_ge:      CASE s_lshift:  CASE s_rshift:
    CASE s_logand:  CASE s_logor:   CASE s_neqv:
    CASE s_eqv:     CASE s_getbyte:
IF debug>0 DO writef("*n// %s*n", opstr(op))
      force_acad()
      code(f_l, ad_a, ad_k)
      code(f_x, opcode(op), m_n)
      state, ssp := ac, ssp-1
      ENDCASE

    CASE s_rv:      CASE s_neg:     CASE s_not:
    CASE s_abs:
IF debug>0 DO writef("*n// %s*n", opstr(op))
      force_ac()
      code(f_x, opcode(op), m_n)
      ENDCASE

    CASE s_add:
IF debug>0 DO writef("*n// %s*n", opstr(op))
      force_acad()
      code(f_a, ad_a, ad_k)
      state, ssp := ac, ssp-1
      ENDCASE

    CASE s_jump:
    { LET l = rdl()
IF debug>0 DO writef("*n// %s L%n*n", opstr(op), l)
      force_nil()
      code(f_j, l, m_l)
      ENDCASE
    }

    CASE s_jt:
    CASE s_jf:
    { LET l = rdl()
IF debug>0 DO writef("*n// %s L%n*n", opstr(op), l)
      force_ac()
      code(op=s_jt->f_t,f_f, l, m_l)
      ssp, state := ssp-1, nil
      ENDCASE
    }

    CASE s_endfor:
      // Simulate the effect of the OCODE
      //       SUB LN 0 LE JT
      // the label follows the ENDFOR code
IF debug>0 DO writef("*n// %s*n", opstr(op))
      force_acad()
      code(f_l, ad_a, ad_k)
      code(f_x, opcode(s_sub), m_n)
      state := ac
      ssp := ssp - 1
      load(0, m_n)
      code(f_l, ad_a, ad_k)
      code(f_x, opcode(s_le), m_n)
      code(f_t, rdl(), m_l)
      ssp := ssp - 2
      state := nil
      ENDCASE

    CASE s_goto:
IF debug>0 DO writef("*n// %s*n", opstr(op))
      force_ad()
      code(f_j, ad_a, ad_k)
      ssp, state := ssp-1, nil
      ENDCASE

    CASE s_lab:
    { LET l = rdl()
IF debug>0 DO writef("*n// %s L%n*n", opstr(op), l)
      force_nil()
      complab(l)
      ENDCASE
    }

    CASE s_query:
IF debug>0 DO writef("*n// %s*n", opstr(op))
      force_nil()
      ssp := ssp + 1
      ENDCASE

    CASE s_stack:
      force_nil()
      ssp := rdn()
IF debug>0 DO writef("*n// %s %n*n", opstr(op), ssp)
      ENDCASE

    CASE s_store:
IF debug>0 DO writef("*n// %s*n", opstr(op))
      force_nil()
      ENDCASE

    CASE s_entry:
    { LET l = rdl()
      LET n = rdn()
IF debug>0 DO  writef("*n// %s L%n %n*n", opstr(op), l, n)

      wr('*n')
      wr('$')
      wr('*s')
      wr('/')
  FOR i = 1 TO n DO wrch(rdn()) // Write the function name
      wr('*n')
      wr(' ')
      complab(l)
      state, ad_a, ad_k := nil, 0, m_n
      ENDCASE
    }

    CASE s_save:
      ssp := rdn()
IF debug>0 DO writef("*n// %s %n*n", opstr(op), ssp)
      ENDCASE

    CASE s_endproc:
IF debug>0 DO writef("*n// %s*n", opstr(op))
      ENDCASE

    CASE s_rtap:
    CASE s_fnap:
    { LET k = rdn()
IF debug>0 DO writef("*n// %s %n*n", opstr(op), k)
      force_ac()
      code(f_k, k, m_n)
      TEST op=s_fnap
      THEN { ssp := k+1
             state := ac
           }
      ELSE { ssp := k
             state := nil
           }
      ENDCASE
    }

    CASE s_fnrn:
      force_ac()
      ssp := ssp - 1
    CASE s_rtrn:
IF debug>0 DO writef("*n// %s*n", opstr(op))
      code(f_x, opcode(s_rtrn), m_n)
      state := nil
      ENDCASE

    CASE s_res:
    { LET l = rdl()
IF debug>0 DO writef("*n// %s L%n*n", opstr(op), l)
      force_ac()
      code(f_j, l, m_l)
      ssp, state := ssp-1, nil
      ENDCASE
   }

    CASE s_rstack:
    { LET n = rdl()
IF debug>0 DO writef("*n// %s %n*n", opstr(op), n)
      force_nil()
      ssp, state := n+1, ac
      ENDCASE
    }

    CASE s_finish:
IF debug>0 DO writef("*n// %s*n", opstr(op))
      code(f_x, opcode(op), m_n)
      ENDCASE

    CASE s_switchon:
    { LET n = rdn()
      LET d = rdl()
IF debug>0 DO writef("*n// %s %n L%n*n", opstr(op), n, d)
      force_ac()
      code(f_x, opcode(op), m_n)
      code(f_d, n, m_n)
      code(f_d, d, m_l)
      ssp, state := ssp-1, nil
      FOR i = 1 TO n DO
      { code(f_d, rdn(), m_n)
        code(f_d, rdl(), m_l)
      }
      ENDCASE
    }

    CASE s_global:
    { LET n = rdn()
IF debug>0 DO writef("*n// %s %n*n", opstr(op), n)
      wr('*n')
      FOR i = 0 TO datap-2 BY 2 DO wrdata(datav!i, datav!(i+1))
      wr('*n')
      FOR i = 1 TO n DO
      { wr('G')
        wrk(rdn())
        wr('L')
        wrk(rdl())
        wr('*s')
      }
      wr('*n')
      wr('Z')
      wr('*n')
      RETURN
    }

    CASE s_datalab:
    CASE s_iteml:
      data(op, rdl())
      ENDCASE

    CASE s_itemn:
      data(op, rdn())
      ENDCASE
  }

  op := readop()

} REPEAT







///.

///SECTION "IC-CG3"



//    CG3


///GET ""




//
//  This code deals with the generation of INTCODE for loads and stores.
//


//  The INTCODE stack may be in one of four states (kept in STATE):
//
//     STATE = NIL
//          top of stack - (offset SSP-1) - in stack frame
//          second of stack - (offset SSP-2) - in stack frame
//          INTCODE accumulator A is empty
//          No pending load
//
//     STATE = AC
//          top of stack - (offset SSP-1) - in INTCODE register A
//          second of stack - (offset SSP-2) - in stack frame
//          No pending load
//
//     STATE = AD
//          top of stack - (offset SSP-1) - in pending load variables
//          second of stack - (offset SSP-2) - in stack frame
//          INTCODE accumulator A is empty
//
//     STATE = ACAD
//          top of stack - (offset SSP-1) - in pending load variables
//          second of stack - (offset SSP-2) - in INTCODE register A
//
//  The two variables AD_A and AD_K hold the address and address modifier
//  of a pending load.  This load will be performed when next necessary.

// LOADS are made into variables on the stack - and hence use M_IP
// STORES are made from addresses on the stack - and hence use M_P

LET force_nil() BE SWITCHON state INTO
// Forces NIL state - so that INTCODE register A is empty and there are
// no pending loads.
{ CASE acad:
    code(f_s, ssp-2, m_p)
  CASE ad:
    code(f_l, ad_a, ad_k)
  CASE ac:
    code(f_s, ssp-1, m_p)
    state := nil
  CASE nil:
}

AND force_ad() BE SWITCHON state INTO
// Forces AD state in which the variables AD_A and AD_K hold details of a
// pending load and INTCODE register A is empty.
{ CASE acad:
    code(f_s, ssp-2, m_p)
    GOTO l

  CASE ac:
    code(f_s, ssp-1, m_p)
  CASE nil:
    ad_a := ssp-1
    ad_k := m_ip
l:  state := ad
  CASE ad:
}

AND force_ac() BE SWITCHON state INTO
// Forces AC state in which the INTCODE register A holds the top of stack
// and there are no pending loads.
{ CASE nil:
    code(f_l, ssp-1, m_ip)
    GOTO l

  CASE acad:
    code(f_s, ssp-2, m_p)
  CASE ad:
    code(f_l, ad_a, ad_k)
l:  state := ac
  CASE ac:
}

AND force_acad() BE SWITCHON state INTO
// Forces state ACAD in which AD_A and AD_K hold details of the pending
// load of the top of stack and INTCODE register A holds the next of stack.
{ CASE ad:
    code(f_l, ssp-2, m_ip)
    GOTO l

  CASE ac:
    code(f_s, ssp-1, m_p)
  CASE nil:
    code(f_l, ssp-2, m_ip)
    ad_a := ssp-1
    ad_k := m_ip
l:  state := acad
  CASE acad:
}


AND swap() BE
// This procedure swaps the top two elements on the stack represented
// in state STATE and leaves the stack in state ACAD.  (with the top
// two registers pending and in the A register respectively).
{ state := acad   // for most of them:
  SWITCHON state INTO
  { CASE nil:
      // load A register with the top of stack:
      code(f_l, ssp-1, m_ip)
      ENDCASE

    CASE ad:
      // Do pending load
      code(f_l, ad_a, ad_k)

    CASE ac:
      // Store A into top of stack (instead of second of stack)
      code(f_s, ssp-1, m_p)
      ENDCASE

    CASE acad:
      // We want to load the stack in the order
      //       <pending load>
      //       <intcode register A>
      // this would mean saving register A whilst it is used for
      // stacking the pending load.  However, we can save the
      // intcode register A first if we are sure that it does not
      // affect the pending load which will have to be done subsequently
      // - i.e. so long as the pending load is not from the top
      // of stack to which we will write register A.
      TEST ad_a=ssp-1 & (ad_k=m_p | ad_k=m_ip)
      THEN { // too bad - we'll have to save A first
             code(f_s, ssp, m_p)
             code(f_l, ad_a, ad_k)   // do pending load
             code(f_s, ssp-2, m_p)   // put in swapped position
             code(f_l, ssp, m_p)     // get A back
             state := ac
           }
      ELSE { code(f_s, ssp-1, m_p)
             code(f_l, ad_a, ad_k)
             code(f_s, ssp-2, m_p)   // put back into second of stack
             state := nil
           }
  }
  ad_a := ssp-2      // for when STATE = AD or ACAD
  ad_k := m_ip
}

AND load(a, k) BE SWITCHON state INTO
// A - the new contents of the accumulator A
// K - the kind (mode) in which the operand is to be fetched
//     (an M_<flags> constant typically)
// This procedure frees the pending load given in AD_A and AD_K (if there
// is one) and then loads A and K into them.
{ CASE nil: state := ad
            GOTO m

  CASE acad:
  CASE ad:  force_ac()
  CASE ac:  state := acad
  m:        ad_a, ad_k := a, k
            ssp := ssp + 1
}

AND storein(a, k) BE
{ force_ac()
  code(f_s, a, k)
  ssp, state := ssp-1, nil
}

AND cgstring(n) BE
{ LET l = nextparam()
IF debug>0 DO writef("*n// %s %n*n", opstr(op), n)
  data(s_datalab, l)
  data(s_char, n)
  FOR i = 1 TO n DO data(s_char, rdn())
  load(l, m_l)
}

AND data(k, v) BE
{ LET p = datap
  datav!p, datav!(p+1) := k, v
  datap := datap + 2
  IF datap>datat DO
  { selectoutput(sysprint)
    writes("IC-CG: too many constants*N")
    selectoutput(gostream)
    datap := 0
  }
}


AND nextparam() = VALOF
{ param := param - 1

  IF  param < 0  THEN
  {
    selectoutput( sysprint )
    writes( "IC-CG:  too many labels (!)*N" )
    selectoutput( gostream )

    param  :=  100  // ????
  }

  RESULTIS param
}

AND checklab() BE IF maxlab>=labnumber DO
{
  writef("checklab: maxlab=%n labnumber=%n*n", maxlab, labnumber)
  cgerror("Too many labels - increase workspace")
  errcount := errcount+1
  longjump(fin_p, fin_l)
}

///.

///SECTION "IC-CG4"



//    CG4


///GET ""


LET code(f, a, k) BE
// F - function = F_L  F_S  F_A  F_J  F_T  F_F  F_K  or  F_X
// A - data (D field in INTCODE)
// K - mode in which data is to be fetched, one of:
//        M_N    -  normal
//        M_I    -  indirect
//        M_IG   -  indirect global
//        M_P    -  local variable (relative to stack frame)
//        M_IP   -  indirect local
//        M_L    -  label
//        M_IL   -  indirect label
{ wr(f)
  SWITCHON k INTO
  { CASE m_i: wr('I')
    CASE m_n: ENDCASE

    CASE m_ig: wr('I')
    CASE m_g:  wr('G')
                  ENDCASE

    CASE m_ip: wr('I')
    CASE m_p:  wr('P'); ENDCASE

    CASE m_il: wr('I')
    CASE m_l:  wr('L'); ENDCASE
  }

  wrk(a)
  wr(' ')
  proglength := proglength + 1
}

AND complab(n) BE
{ // writes out an INTCODE label
  wrk(n)
  wr(' ')
}

AND wrdata(k, n) BE SWITCHON k INTO
// writes out an OCODE data item in INTCODE
{ CASE s_datalab: complab(n);      RETURN

  CASE s_itemn: code(f_d, n, m_n); RETURN

  CASE s_iteml: code(f_d, n, m_l); RETURN

  CASE s_char:  code(f_c, n, m_n); RETURN
}

AND opcode(op) = VALOF SWITCHON op INTO
// returns INTCODE number <n> in X<n> for OCODE opcode OP
{ CASE s_rv:       RESULTIS 1
  CASE s_neg:      RESULTIS 2
  CASE s_not:      RESULTIS 3
  CASE s_rtrn:     RESULTIS 4
  CASE s_mul:      RESULTIS 5
  CASE s_div:      RESULTIS 6
  CASE s_rem:      RESULTIS 7
  CASE s_add:      RESULTIS 8
  CASE s_sub:      RESULTIS 9
  CASE s_eq:       RESULTIS 10
  CASE s_ne:       RESULTIS 11
  CASE s_ls:       RESULTIS 12
  CASE s_ge:       RESULTIS 13
  CASE s_gr:       RESULTIS 14
  CASE s_le:       RESULTIS 15
  CASE s_lshift:   RESULTIS 16
  CASE s_rshift:   RESULTIS 17
  CASE s_logand:   RESULTIS 18
  CASE s_logor:    RESULTIS 19
  CASE s_neqv:     RESULTIS 20
  CASE s_eqv:      RESULTIS 21
  CASE s_finish:   RESULTIS 22
  CASE s_switchon: RESULTIS 23
  CASE s_getbyte:  RESULTIS 36
  CASE s_putbyte:  RESULTIS 37
  CASE s_abs:      RESULTIS 38

  DEFAULT: selectoutput(sysprint)
                 writef("IC-CG: unknown op %N*N", op)
                 selectoutput(gostream)
                 RESULTIS 0
    }


AND wr(ch) BE
{ //writef("wr: ch='%c' linep=%n*n", ch, linep)
  IF ch='*n' DO
  { wrch('*n')
    linep := 0
    RETURN
  }

  IF linep=71 DO
  { wrch('/')
    wrch('*n')
    linep := 0
//writef("wr: end of line*n")
  }
  linep := linep + 1
  wrch(ch)
  deplete(cos)
}


AND wrk(n) BE
{ IF n<0 THEN
  { wr('-')
    n := -n
  }
  IF n>9 DO wrk(n/10)
  wr(n MOD 10 + '0')
}

AND wrn1 (n) BE
{ LET t    = VEC 10
   LET i, k = 0, -n

   IF n<0 DO k := n
   t!i, k, i := -(k REM 10), k/10, i+1 REPEATUNTIL k=0
   IF n<0 THEN wr('-')
   FOR j = i-1 TO 0 BY -1 DO wr(t!j+'0')
}




///.


///SECTION "IC-CG5"



//    CG5


///GET ""




LET codegenerate(workspace, workspacesize) BE
{ //LET workspace = ?
  //LET v = VEC 50

  writes("cg-intcode 28 Sept 2012*n")

  IF workspacesize<2000 DO { cgerror("Too little workspace")
                             errcount := errcount+1
                             longjump(fin_p, fin_l)
                           }

   datav, datat := workspace, workspacesize

   proglength := 0

   selectoutput(gostream)

   {
     op := readop()
//writef("op=%n %s*n", op, opstr(op))
     IF op=0 BREAK

     IF op=s_section DO
     { wr('*n')
       writes("/ SECTION ")
       FOR i=1 TO rdn() DO wrch(rdn())
       wr('*n')
       op := readop()
     }
     ssp, state := 2, nil
     ad_a, ad_k := 0, m_n
     datap, linep,  param := 0, 0, 1000

     gencode()
//writef("before repeatuntil op=%n %s*n", op, opstr(op))
   } REPEATUNTIL op=s_end

   selectoutput(sysprint)
   writef("Program size = %n words*n", proglength)

exit.label:
   RETURN
}
