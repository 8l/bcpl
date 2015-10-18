SECTION "optflow"

GET "b2flow.h"

GLOBAL {
charv:300; charp; chart
vrefs; name; props; dpndson; val
spacev; spacep; spacet
labv; labmax; labrefs
varmax; retcode
flowlist; flowlast
currentId
debuglevel
}

MANIFEST {
p_local    = 1<<0        // LET Vi = expression
p_arg      = 1<<1        // LET f( ... Vi ... )
p_manifest = 1<<2        // Vi = k
p_static   = 1<<3        // STATIC { ... Vi=k; ... }
p_global   = 1<<4        // GLOBAL { ... Vi:k; ... }
p_label    = 1<<5        // Vi: ...
p_entry    = 1<<6        // LET Vi(...) ...
p_table    = 1<<7        // Vi = TABLE ...
p_vec      = 1<<8        // Vi = VEC k or @local or @arg
p_heap     = 1<<9        // Vi = result of getvec
p_string   = 1<<10       // Vi = "...."

p_vplus0   = 1<<11       // Vi := Vj
p_vplusk   = 1<<12       // Vi := Vj + k
p_vplusv   = 1<<13       // Vi := Vj + Vj
p_indvplus0= 1<<14       // Vi := Vj!0
p_indvplusk= 1<<15       // Vi := Vj!k
p_indvplusv= 1<<16       // Vi := Vj!Vj
p_indv     = 1<<17
p_called   = 1<<18       // Vi(...)
p_heap0    = 1<<19       // Vi = Vj!0  where Vj = heap
p_heapk    = 1<<20       // Vi = Vj!k  where Vj = heap
p_heapv    = 1<<21       // Vi = Vj!Vk where Vj = heap
p_vec0     = 1<<22       // Vi = Vj!0  where Vj = vec
p_veck     = 1<<23       // Vi = Vj!k  where Vj = vec
p_vecv     = 1<<24       // Vi = Vj!Vk where Vj = vec
p_tab0     = 1<<25       // Vi = Vj!0  where Vj = table
p_tabk     = 1<<26       // Vi = Vj!k  where Vj = table
p_tabv     = 1<<27       // Vi = Vj!Vk where Vj = table
p_str0     = 1<<28       // Vi = Vj!0  where Vj = string
p_strk     = 1<<29       // Vi = Vj!k  where Vj = string
p_strv     = 1<<30       // Vi = Vj!Vk where Vj = string

// Info about where Vi has been used/sent

// E(..., Vi, ...)          Vi has been passed to a function
// ... := Vi                Vi has gone somewhere unknown
// ... := ... Vi ...        Vi has gone somewhere unknown


// Info about vector elements

// Vi!0  := Vj  where Vi is a table, vector, string or arg vector
// Vi!k  := Vj
// Vi!Vj := Vk
}

MANIFEST {
Next=0
Op; Id; Depth; Dominator;
LiveSet; W0
A1; A2; A3; A4
}

LET start() = VALOF
{ LET argv = VEC 20
  LET flowin = ?
  AND flowout = 0
  LET stdin = input()
  LET sysprint = output()

  writef("OPTFLOW 23 Feb 2000*n")

  IF rdargs("FROM,TO/K,VARMAX/K,D1/S,D2/S", argv, 20)=0 DO
  { writes("Bad args for optflow*n")
    RESULTIS 20
  }
  IF argv!0=0 DO argv!0 := "FLOW"
  IF argv!1=0 DO argv!1 := "OPT"
  flowin := findinput(argv!0)
  IF flowin=0 DO
  { writef("Trouble with file %s*n", argv!0)
    RESULTIS 20
  }
  flowout := findoutput(argv!1)
   
  IF flowout=0 DO
  { writef("Trouble with file %s*n", argv!1)
    RESULTIS 20
  }

  varmax := argv!2 -> str2numb(argv!2), 5000

  debuglevel := 0
  IF argv!3 DO debuglevel := debuglevel+1
  IF argv!4 DO debuglevel := debuglevel+2

  UNLESS allocatevecs() DO
  { writes("Insufficient space*n")
    retcode := 20
    GOTO fin
  }
   
  writef("Optimizing %s to %s*n", argv!0, argv!1)
  selectinput(flowin)
  currentId := 0
  scan()
  UNLESS flowin= stdin DO endread()
  selectinput(stdin)
  selectoutput(sysprint)
  writef("Optimization complete*n")
  debuglevel := 1
  IF debuglevel DO debug()

fin:
  UNLESS flowout=sysprint DO { selectoutput(flowout); endwrite() }
  freevecs()
  RESULTIS retcode
}

AND allocatevecs() = VALOF
{ charv   := getvec(4000)
  charp, chart := 1, 4000<<B2Wsh
  spacev  := getvec(200000)
  spacet  := spacev+200000
  spacep  := spacet
  labv    := getvec(5000)
  labrefs := getvec(5000)
  labmax  := 5000
  FOR i = 0 TO labmax DO labv!i, labrefs!i := 0, 0
  vrefs   := getvec(varmax)
  name    := getvec(varmax)
  props   := getvec(varmax)
  dpndson := getvec(varmax)
  val     := getvec(varmax)
  UNLESS charv & spacev & vrefs & name & props & dpndson & val &
         labv & labrefs RESULTIS FALSE
  FOR i = 0 TO varmax DO
    vrefs!i, name!i, props!i, dpndson!i, val!i := 0, 0, 0, 0, 0
  flowlist, flowlast := 0, @flowlist
  RESULTIS TRUE
}

AND freevecs() BE
{ IF charv   DO freevec(charv)
  IF spacev  DO freevec(spacev)
  IF labv    DO freevec(labv)
  IF labrefs DO freevec(labrefs)
  IF vrefs   DO freevec(vrefs)
  IF name    DO freevec(name)
  IF props   DO freevec(props)
  IF dpndson DO freevec(dpndson)
  IF val     DO freevec(val)
}

AND mkvec(n) = VALOF
{ LET p = spacep - n - 1
  IF p<spacev DO
  { writes("Insufficient space*n")
    abort(999)
    RESULTIS 0
  }
  spacep := p
  RESULTIS p
}

AND mk(n, a, b, c, d, e, f, g, h, i, k) = VALOF
{ LET p = mkvec(n)
  LET t = @a
  UNLESS p DO { writef("mk: Out of space*n")
                abort(999)
                RESULTIS 0
              }
  FOR i = 0 TO n-1 DO p!i := t!i
  RESULTIS p
}

// argument may be of form Ln
AND rdn() = VALOF
{ LET a, ch, sign = 0, ?, '+'

  ch := rdch() REPEATWHILE ch='*s' | ch='*n'

  IF ch=endstreamch RESULTIS 0

  IF ch='-' DO { sign := '-'; ch := rdch() }

  WHILE '0'<=ch<='9' DO { a := 10*a + ch - '0'; ch := rdch()  }

  IF sign='-' RESULTIS -a
  RESULTIS a
}

AND rdstr() = VALOF
{ LET n = rdn()
  LET res = charp
  charv%charp := n
  charp := charp+1
  FOR i = 1 TO n DO
  { charv%charp := rdn()
    charp := charp + 1
  }
  RESULTIS res
}

AND addnode(node) = VALOF
{ !flowlast := node
  flowlast := node
  RESULTIS node
}

AND nextid() = VALOF
{ currentId := currentId + 1
  RESULTIS currentId
}

AND addnodeOp(op) = VALOF
{ LET node = mkvec(W0)
  FOR i = 0 TO W0 DO node!i := 0
  Id!node := nextid()
  Op!node := op
  addnode(node)
  RESULTIS node
}

AND addnodeOpA1(op, a1) = VALOF
{ LET node = mkvec(A1)
  FOR i = 0 TO A1 DO node!i := 0
  Id!node := nextid()
  Op!node := op
  A1!node := a1
  addnode(node)
  RESULTIS node
}

AND addnodeOpA1A2(op, a1, a2) = VALOF
{ LET node = mkvec(A2)
  FOR i = 0 TO A2 DO node!i := 0
  Id!node := nextid()
  Op!node := op
  A1!node := a1
  A2!node := a2
  addnode(node)
  RESULTIS node
}

AND addnodeOpA1A2A3(op, a1, a2, a3) = VALOF
{ LET node = mkvec(A3)
  FOR i = 0 TO A3 DO node!i := 0
  Id!node := nextid()
  Op!node := op
  A1!node := a1
  A2!node := a2
  A3!node := a3
  addnode(node)
  RESULTIS node
}

AND addnodeOpA1A2A3A4(op, a1, a2, a3, a4) = VALOF
{ LET node = mkvec(A4)
  FOR i = 0 TO A4 DO node!i := 0
  Id!node := nextid()
  Op!node := op
  A1!node := a1
  A2!node := a2
  A3!node := a3
  A4!node := a4
  addnode(node)
  RESULTIS node
}

AND labuse(lab, node) BE
{ labrefs!lab := mk(2, labrefs!lab, node)
}

AND addvref(vi, node) BE
{ vrefs!vi := mk(2, vrefs!vi, node)
}

AND scan() BE
{ LET op = rdn()
  LET vi, vj, vk = 0, 0, 0
  LET gn, lab, n, k, v = 0, 0, 0, 0, 0
  LET str = 0
  LET node = 0

  IF debuglevel=3 DO writef("op: %n*n", op)

  SWITCHON op INTO

  { DEFAULT:         writef("Bad FLOW op %n*n", op)
                     LOOP

    CASE 0:          RETURN
      
    CASE s_section:  
    CASE s_needs:    // op str
                     str := rdstr()
                     addnodeOpA1(op, str)
                     ENDCASE

    CASE s_string:   // op Vi str
                     vi := rdn()
                     str := rdstr()
                     addnodeOpA1A2(op, vi, str)
                     ENDCASE

    CASE s_table:    // op Vi vec
                     vi := rdn()
                     n := rdn()
                     v := mkvec(n)
                     FOR i = 0 TO n-1 DO v!i := rdn()
                     addnodeOpA1A2A3(op, vi, n, v)
                     ENDCASE


    CASE s_finish:
    CASE s_rtrn:
    CASE s_endproc:  // op
                     addnodeOp(op)
                     ENDCASE

    CASE s_fnrn:
    CASE s_goto:
    CASE s_true:
    CASE s_false:
    CASE s_query:    // op Vi
                     vi := rdn()
                     node := addnodeOpA1(op, vi)
                     addvref(vi, node)
                     ENDCASE

    CASE s_not:
    CASE s_neg:
    CASE s_abs:
    CASE s_llv:
    CASE s_stind:
    CASE s_lv:
    CASE s_rv:
    CASE s_ld:       // op Vi Vj
                     vi := rdn()
                     vj := rdn()
                     node := addnodeOpA1A2(op, vi, vj)
                     addvref(vi, node)
                     addvref(vj, node)
                     ENDCASE

    CASE s_getbyte:
    CASE s_putbyte:
    CASE s_vecap:
    CASE s_mult:
    CASE s_div:
    CASE s_rem:
    CASE s_plus:
    CASE s_minus:
    CASE s_eq:
    CASE s_ne:
    CASE s_ls:
    CASE s_gr:
    CASE s_le:
    CASE s_ge:
    CASE s_lshift:
    CASE s_rshift:
    CASE s_logand:
    CASE s_logor:
    CASE s_eqv:
    CASE s_neqv:     // op Vi Vj Vk
                     vi := rdn()
                     vj := rdn()
                     vk := rdn()
                     node := addnodeOpA1A2A3(op, vi, vj, vk)
                     addvref(vi, node)
                     addvref(vj, node)
                     addvref(vk, node)
                     ENDCASE

    CASE s_jt:       
    CASE s_jf:       // op Vi lab
                     vi := rdn()
                     lab := rdn()
                     node := addnodeOpA1A2(op, vi, lab)
                     addvref(vi, node)
                     labuse(lab, node)
                     ENDCASE

    CASE s_jump:     lab := rdn()
                     node := addnodeOpA1(op, lab)
                     labuse(lab, node)
                     ENDCASE

    CASE s_lab:      // op lab
                     lab := rdn()
                     labv!lab := addnodeOpA1(op, lab)
                     ENDCASE


    CASE s_fnap:     vi := rdn()     // FNAP Vi Vj n args
                     vj := rdn()
                     n := rdn()
                     v := mkvec(n)
                     node := addnodeOpA1A2A3A4(op, vi, vj, n, v)
                     addvref(vi, node)
                     addvref(vj, node)
                     FOR i = 0 TO n-1 DO { v!i := rdn()
                                           addvref(v!i, node)
                                         }
                     ENDCASE

    CASE s_rtap:     vi := rdn()       // RTAP Vi n args
                     n := rdn()
                     v := mkvec(n)
                     node := addnodeOpA1A2A3(op, vi, n, v)
                     addvref(vi, node)
                     FOR i = 0 TO n-1 DO { v!i := rdn()
                                           addvref(v!i, node)
                                         }
                     ENDCASE

    CASE s_switchon: vi := rdn()          // control variable
                     n := rdn()           // number of cases
                     lab := rdn()         // default lab
                     v := mkvec(2*n)
                     node := addnodeOpA1A2A3A4(op, vi, n, lab, v)
                     addvref(vi, node)
                     labuse(lab, node)
                     FOR i = 0 TO n-1 DO
                     { LET p = @v!(i+i)
                       p!0 := rdn()       // Ki
                       p!1 := rdn()       // Li
                       labuse(p!1, node)
                     }
                     ENDCASE


    CASE s_entry:    lab := rdn()
                     str := rdstr()
                     labv!lab := addnodeOpA1A2(op, lab, str)
                     ENDCASE

    CASE s_name:     vi := rdn()
                     str := rdstr()
                     name!vi := str
                     ENDCASE

    CASE s_manifest: vi := rdn()
                     k := rdn()
                     props!vi := p_manifest
                     val!vi := k
                     ENDCASE

    CASE s_static:   vi := rdn()
                     k := rdn()
                     props!vi := p_static
                     val!vi := k
                     ENDCASE

    CASE s_local:    vi := rdn()      // LOCAL Vi
                     props!vi := p_local
                     val!vi := 0
                     ENDCASE

    CASE s_arg:      vi := rdn()      // ARG Vi n
                     n := rdn()
                     props!vi := p_arg
                     val!vi := n
                     ENDCASE

    CASE s_vec:      vi := rdn()
                     k := rdn()
                     props!vi := p_vec
                     val!vi := k
                     ENDCASE

    CASE s_global:   vi := rdn()      // GLOBAL Vi Gn
                     n := rdn()
                     props!vi := p_global
                     val!vi := n
                     ENDCASE

    CASE s_globinit: gn := rdn()
                     lab := rdn()
                     ENDCASE
  }
} REPEAT

AND op2str(op) = VALOF SWITCHON op INTO
{ DEFAULT:          RESULTIS "Unknown op"
      
  CASE s_section:   RESULTIS "section"
  CASE s_needs:     RESULTIS "needs"
  CASE s_string:    RESULTIS "string"
  CASE s_table:     RESULTIS "table"
  CASE s_finish:    RESULTIS "finish"
  CASE s_rtrn:      RESULTIS "rtrn"
  CASE s_endproc:   RESULTIS "endproc"
  CASE s_fnrn:      RESULTIS "fnrn"
  CASE s_goto:      RESULTIS "goto"
  CASE s_true:      RESULTIS "true"
  CASE s_false:     RESULTIS "false"
  CASE s_query:     RESULTIS "query"
  CASE s_not:       RESULTIS "not"
  CASE s_neg:       RESULTIS "neg"
  CASE s_abs:       RESULTIS "abs"
  CASE s_llv:       RESULTIS "llv"
  CASE s_stind:     RESULTIS "stind"
  CASE s_lv:        RESULTIS "lv"
  CASE s_rv:        RESULTIS "rv"
  CASE s_ld:        RESULTIS "ld"
  CASE s_getbyte:   RESULTIS "getbyte"
  CASE s_putbyte:   RESULTIS "putbyte"
  CASE s_vecap:     RESULTIS "vecap"
  CASE s_mult:      RESULTIS "mult"
  CASE s_div:       RESULTIS "div"
  CASE s_rem:       RESULTIS "rem"
  CASE s_plus:      RESULTIS "plus"
  CASE s_minus:     RESULTIS "minus"
  CASE s_eq:        RESULTIS "eq"
  CASE s_ne:        RESULTIS "ne"
  CASE s_ls:        RESULTIS "ls"
  CASE s_gr:        RESULTIS "gr"
  CASE s_le:        RESULTIS "le"
  CASE s_ge:        RESULTIS "ge"
  CASE s_lshift:    RESULTIS "lshift"
  CASE s_rshift:    RESULTIS "rshift"
  CASE s_logand:    RESULTIS "logand"
  CASE s_logor:     RESULTIS "logor"
  CASE s_eqv:       RESULTIS "eqv"
  CASE s_neqv:      RESULTIS "neqv"
  CASE s_jt:        RESULTIS "jt"
  CASE s_jf:        RESULTIS "jf"
  CASE s_jump:      RESULTIS "jump"
  CASE s_lab:       RESULTIS "lab"
  CASE s_fnap:      RESULTIS "fnap"
  CASE s_rtap:      RESULTIS "rtap"
  CASE s_switchon:  RESULTIS "switchon"
  CASE s_entry:     RESULTIS "entry"
  CASE s_name:      RESULTIS "name"
  CASE s_manifest:  RESULTIS "manifest"
  CASE s_static:    RESULTIS "static"
  CASE s_local:     RESULTIS "local"
  CASE s_arg:       RESULTIS "arg"
  CASE s_vec:       RESULTIS "vec"
  CASE s_global:    RESULTIS "global"
  CASE s_globinit:  RESULTIS "globinit"
}

AND prvarinfo() BE
{ newline()
  FOR i = 0 TO varmax IF props!i | name!i | vrefs!i DO
  { LET str = name!i
    LET ps = props!i
    LET r = vrefs!i
    LET a = val!i
    LET len = 0
   
    writef("V%i4:", i)
    IF str DO len := charv%str
    wrch(' ')
    FOR j = 1 TO len DO wrch(charv%(str+j))
    FOR i = len+1 TO 9 DO wrch(' ')

    UNLESS (ps & p_local)=0    DO writef(" LOCAL")
    UNLESS (ps & p_arg)=0      DO writef(" ARG %n", a)
    UNLESS (ps & p_manifest)=0 DO writef(" MANIFEST %n", a)
    UNLESS (ps & p_static)=0   DO writef(" STATIC %n", a)
    UNLESS (ps & p_global)=0   DO writef(" GLOBAL %n", a)
    UNLESS (ps & p_entry)=0    DO writef(" ENTRY")
    UNLESS (ps & p_label)=0    DO writef(" LABEL")
    UNLESS (ps & p_vec)=0      DO writef(" VEC %n", a)
    UNLESS (ps & p_table)=0    DO writef(" TABLE")
    IF r DO writef(" Used:")
    WHILE r DO
    { writef(" %n", Id!(r!1))
      r := !r
    }
    newline()
  }
}

AND debug() BE
{ LET ch = 0

  UNTIL ch=endstreamch DO
  { writes("# ")
    ch := sardch()
    SWITCHON ch INTO
    { DEFAULT:   writef("Bad ch '%c'*n", ch)
                 LOOP

      CASE ' ':
      CASE '*t':
      CASE '*n': LOOP

      CASE 'v':  prvarinfo()
                 LOOP

      CASE 'f':  prflowgraph()
                 LOOP

      CASE 'l':  prlabinfo()
                 LOOP

      CASE 'q':  newline()
                 RETURN

      CASE 'h':  
        newline()
        writes("v  print var information*n")
        writes("f  print the flow graph*n")
        writes("l  print label information*n")
        writes("q  quit*n")
        LOOP
    }
  } REPEAT 
}

AND prlabinfo() BE
{ newline()
  FOR lab = 1 TO labmax IF labv!lab
  { LET labval, refs = labv!lab, labrefs!lab
    writef("L%i4: %i4  used:", lab, Id!labval)
    WHILE refs DO
    { writef(" %n", Id!(refs!1))
      refs := !refs
    }
    newline()
  }
}

AND prflowgraph() BE
{ LET p = flowlist
  writef("*nprflowgraph*n")
  WHILE p DO
  { prinstruction(p)
    p := Next!p
  }
}

AND prinstruction(p) BE
{ LET op = Op!p
  LET n, v = 0, 0
  LET str = 0
  MANIFEST { t_op=1; t_v; t_vv; t_vvv; t_l; t_vl; t_vnl }

  LET type = t_op

  SWITCHON op INTO

  { DEFAULT:         

    CASE s_name:
    CASE s_manifest:
    CASE s_static:
    CASE s_local:    
    CASE s_arg:      
    CASE s_vec:      
    CASE s_global:   
    CASE s_globinit:
    CASE s_section:  
    CASE s_needs:
    CASE s_string:
    CASE s_table:    writef("Unexpected op: %s*n", op2str(op))
                     RETURN

    CASE s_finish:
    CASE s_rtrn:
    CASE s_endproc:  // op
                     ENDCASE

    CASE s_fnrn:
    CASE s_goto:
    CASE s_true:
    CASE s_false:
    CASE s_query:    // op Vi
                     type := t_v
                     ENDCASE

    CASE s_not:
    CASE s_neg:
    CASE s_abs:
    CASE s_llv:
    CASE s_stind:
    CASE s_lv:
    CASE s_rv:
    CASE s_ld:       // op Vi Vj
                     type := t_vv
                     ENDCASE

    CASE s_getbyte:
    CASE s_putbyte:
    CASE s_vecap:
    CASE s_mult:
    CASE s_div:
    CASE s_rem:
    CASE s_plus:
    CASE s_minus:
    CASE s_eq:
    CASE s_ne:
    CASE s_ls:
    CASE s_gr:
    CASE s_le:
    CASE s_ge:
    CASE s_lshift:
    CASE s_rshift:
    CASE s_logand:
    CASE s_logor:
    CASE s_eqv:
    CASE s_neqv:     // op Vi Vj Vk
                     type := t_vvv
                     ENDCASE

    CASE s_jt:       
    CASE s_jf:       // op Vi lab
                     type := t_vl
                     ENDCASE

    CASE s_jump:     // op lab
                     type := t_l
                     ENDCASE

    CASE s_lab:      // op lab
                     type := t_l
                     ENDCASE


    CASE s_fnap:     type := t_vv     // FNAP Vi Vj n args
                     n := A3!p
                     v := A4!p
                     ENDCASE

    CASE s_rtap:     type := t_v      // RTAP Vi n args
                     n := A2!p
                     v := A3!p
                     ENDCASE

    CASE s_switchon: type := t_vnl       // control variable
                     ENDCASE

    CASE s_entry:    type := t_l
                     str := A2!p
                     ENDCASE

  }

  writef("%i4: D %i3  Dom %i4 %t9",
          Id!p, Depth!p, Dominator!p, op2str(op))
  
  //IF type=t_k   DO writef("K%n",         A1!p)
  IF type=t_l   DO writef("L%n",         A1!p)
  //IF type=t_vk  DO writef("V%n K%n",     A1!p, A2!p)
  //IF type=t_vg  DO writef("V%n G%n",     A1!p, A2!p)
  IF type=t_vl  DO writef("V%n L%n",     A1!p, A2!p)
  //IF type=t_gl  DO writef("G%n L%n",     A1!p, A2!p)
  IF type=t_vnl  DO writef("V%n %n L%n",      A1!p, A2!p, A3!p)
  IF type=t_v   DO writef("V%n",         A1!p)
  IF type=t_vv  DO writef("V%n V%n",     A1!p, A2!p)
  IF type=t_vvv DO writef("V%n V%n V%n", A1!p, A2!p, A3!p)

  IF str DO { writef(" *"")
              FOR i = 1 TO charv%str DO
              { LET ch = charv%(str+i)
                IF i REM 15 = 0 DO newline()
                TEST 32<=ch<=127 THEN wrch(ch)
                                 ELSE wrch('?')
              }
              wrch('*"')
            }

  newline()
  IF op=s_switchon DO
  { LET n, v = A2!p, A4!p
    FOR i = 0 TO n-1 DO
    { LET k, lab = v!(2*i), v!(2*i+1)
      writef("      K%i3   L%i3*n", k, lab)
    }
  }
}

