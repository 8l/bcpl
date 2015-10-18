//    TRNHDR

GET "libhdr"

MANIFEST {    // Parse tree and MCODE operators
s_numb=1;     s_ln=1
s_vid=2
s_cid=3
s_string=4
s_true=5
s_false=6
s_query=7
s_tablab=8    // replacement for s_string and s_table

              s_lp=10
              s_lg=11
              s_llp=13
              s_llg=14

s_comma=16;   s_sp=16
              s_sg=17
              s_lf=18
              s_lx=19

s_lv=20
s_neg=21
s_abs=22
s_not=23
s_bitnot=24
s_vec=25
s_cvec=26
s_valof=27
s_table=28
s_ltable=29; s_callc=29

s_call=30
s_indw=31
s_indw0=32
s_indb=33
s_indb0=34
s_lsh=35   // same order as op:= operators
s_rsh=36
s_mult=37
s_div=38
s_mod=39
s_bitand=40
s_xor=41
s_plus=42
s_sub=43
s_bitor=44

s_eq=45
s_ne=46
s_le=47
s_ge=48
s_ls=49
s_gr=50
s_rel=51

s_and=55
s_or=56

s_cond=58

s_ptr=59
s_dots=60;     s_ll=60
               s_lll=61
s_peq=62;      s_sl=62
s_pne=63;      s_lpath=63
s_ple=64;      s_llpath=64
s_pge=65;      s_spath=65
s_pls=66;      s_stw=66
s_pgr=67;      s_stb=67
               s_lvindw=68
               s_cpr=69
s_pass=70;     s_jt=70

// same order as the expression operator
s_plshass=71;  s_jf=71
s_prshass=72;  s_lab=72
s_pmultass=73; s_stack=73
s_pdivass=74
s_pmodass=75
s_pandass=76
s_pxorass=77
s_pplusass=78
s_psubass=79;  s_dup=79
s_porass=80;   s_lr=80
               s_str=81
s_pand=82;     s_jump=82
s_por=83;      s_dlab=83
               s_dw=84
s_inc1=85;     s_db=85
s_inc4=86;     s_dl=86
s_dec1=87;     s_ds=87
s_dec4=88

s_inc1b=90
s_inc4b=91
s_dec1b=92
s_dec4b=93
s_inc1a=94
s_inc4a=95
s_dec1a=96
s_dec4a=97

s_let=100
s_scope=101
s_goto=103
s_raise=104
s_handle=105
s_test=106
s_if=109
s_unless=110
s_while=112
s_until=113
s_repeatwhile=114
s_repeatuntil=115
s_repeat=116
s_for=117
s_match=120
s_every=121
s_result=122
s_exit=123
s_return=124
s_break=125
s_loop=126
s_seq=127

s_ass=130

s_lshass=131    // same order as the expression operators
s_rshass=132
s_multass=133
s_divass=134
s_modass=135
s_andass=136
s_xorass=137
s_plusass=138
s_subass=139
s_orass=140

s_allass=141

s_module=145
s_endmodule=146
s_external=147
s_static=148
s_manifest=149
s_global=150
s_fun=151
s_cfun=152
s_funpat=153;  s_endfun=153
s_sdef=154
s_mdef=155
s_gdef=156; s_unhandle=156
s_xdef=157; s_line=157

s_file=158
s_setargs=159
s_fnargs=160
s_locs=161
}

MANIFEST {     //  Selectors
h1=0; h2=1; h3=2; h4=3; h5=4; h6=5; h7=6

}

GLOBAL  {
//fin_p:237; fin_l:238; findfilename:241

trnext:300; trans:301
findid:307
trnerr:311
jumpcond:320
transfor:322

preplhs:328
preplhsop:329
assign:330
assignall:331
assignop:332
load:333
loadlv:335
loadargs:336
isconst:337
evalconst:338
transvid:339
checkdistinct:340
outglobinits:341

nextlab:343; labnumber:344
newblk:346; retblk:348; retblks:349
wrc:350; mcount:351; wrn:353; wrpn:354

extlist:360
funlist:361
manlist:362
globlist:363; lastgn:364
statlist:365
sdlist:366
loclist:367
scopeptr:368
blklist:369

comline:370; procname:371
resultlab:372; defaultlab:373; exitlab:374
looplab:375; breaklab:376; ssp:377; nptr:378
outstring:380; out1:381; out2:382; out3:383; outline:384
matchpos:390; matchlen:391; matchlab:392
matchhdepth:393; rephdepth:394; valofhdepth:395; hdepth:396
}


LET nextlab() = VALOF
{  labnumber := labnumber + 1
   RESULTIS labnumber
}

AND trnerr(mess, a) BE
{  selectoutput(sysprint)
   writef("Error in %s ", findfilename(comline>>24))
   writef("near line %n", comline&#xFFFFFF)
   UNLESS procname=0 DO writef(" in %s", @h3!procname)
   writes(": ")
   writef(mess, a)
   newline()
   errcount := errcount + 1
   IF errcount >= errmax DO {  writes("*nCompilation aborted*n")
                               longjump(fin_p, fin_l)
                            }
   selectoutput(mcodeout)
}

// Allocation and freeing of 4-word blocks is provided by
// newblk, retblk and retblks.

// Such blocks are used in the following lists:

// extlist, globlist, funlist, manlist, statlist, sdlist and loclist

LET newblk(x, y, z, t) = VALOF
{  LET p = blklist

   TEST p=0
   THEN {  p := treep - 4
           IF treevec>p DO {  errmax := 0        // Make it fatal.
                              trnerr("More workspace needed")
                           }
        }
   ELSE blklist := h1!blklist

   p!0, p!1, p!2, p!3 := x, y, z, t
   treep := p
   RESULTIS p
}

AND retblk(p) BE
{  IF p=0 DO abort(1234)
   h1!p := blklist
   blklist := p
}

// Return all the blocks on list p to blklist up to but not
// including q. It must work even when p or q are zero.
AND retblks(p, q) BE UNTIL p=q
{  LET a = p  // a points to the block to return
   p := h1!p
   retblk(a)
}

// translate is the main routine of TRN, it translates the
// parse tree of a complete module into MCODE.

AND translate(x) BE
{  // If module occurs at all it will be the leading operator
   IF x~=0 & h1!x=s_module   // x -> [module, Vid, Body, ln]
   {  LET vid = h2!x
      comline := h4!x
      out1(s_module)
      outstring(@h3!vid)
      x:=h3!x
   }

   resultlab, breaklab, looplab, exitlab := -2, -2, -2, -2
   // -2 above means such jumps to such labels are out of context.

   comline, procname, mcount, labnumber := 1, 0, 0, 1
   ssp, nptr := 0, 0

   // hdepth is used to hold the depth of current exception
   // handler within the current function.

   hdepth := 0

   // It is needed in the implementation of GOTO, BREAK, LOOP, EXIT
   // and RETURN. The difference between hdepth and matchhdepth,
   // rephdepth, valofhdepth indicates how many UNHANDLEs to generate.

   matchhdepth, rephdepth, valofhdepth := 0, 0, 0

   // matchpos is the stack location
   // of the first MATCH argument, it is used in a SETARGS statement.
   // matchlen holds the number argument locations allocated.

   matchpos, matchlen, matchlab := 0, 0, 0

   // blklist holds the list of free 4-word blocks
   blklist := 0

   // manlist structure is as follows
   // L -> 0
   //   |  [L, Cid, val, -]
   // manlist is built first by a sequential scan through the program.
   manlist := 0
   mkmanlist(x)

   // extlist structure is as follows
   // L -> 0
   //   |  [L, vid,   0, -]  imported MCPL function
   //   |  [L, vid, vid, -]  imported C function (2nd vid is the type)
   // extlist is built next.
   extlist := 0
   mkextlist(x)

   // globlist structure is as follows
   // L -> 0
   //   |  [L, vid, gn,   0]  an uninitialised global variable
   //   |  [L, vid, gn, lab]  an initialised global variable
   // The lab is inserted when the global function in translated.
   // globlist is built next, evaluating constant expressions
   //          in the scope of manlist (already built).
   globlist, lastgn := 0, 0
   mkgloblist(x)

   // funlist structure is as follows
   // L -> 0
   //   |  [L, vid,  -1, lab]  local or global MCPL function
   //   |  [L, vid,   0, lab]  exported MCPL function
   //   |  [L, vid, vid, lab]  exported C function (2nd vid is the type)
   // funlist is built next checking for matches in globlist or extlist.
   funlist := 0
   mkfunlist(x)

   // statlist structure is as follows
   // L -> 0
   //   |  [L, vid, lab, -]
   // statlist is built next possibly using manlist and funlist.
   statlist := 0
   mkstatlist(x)

   // loclist structure is as follows
   // L -> 0
   //   |  [L, Vid, q, i]  where q,i is the path for a local variable
   // loclist changes on entry and exit to/from dynamic scopes.
   // The names declared from loclist up to but not including scopeptr
   // are in the current dynamic scope.
   loclist, scopeptr := 0, 0

   // sdlist structure is used in the compilation of static constant
   // expressions and is as follows
   // L -> 0
   //   |  [L, vid, s_dw, k]
   //   |  [L, vid, s_dl, lab]
   sdlist := 0

   trfunbodies(x)

   outglobinits()

   out1(s_endmodule)
   newline()
}


AND mkmanlist(x) BE UNTIL x=0 SWITCHON h1!x INTO
{  DEFAULT:  trnerr("Compiler error in mkmanlist")

   CASE s_global:
   CASE s_external:
   CASE s_static: x := h3!x;    LOOP

   CASE s_fun:    x := h4!x;    LOOP

   CASE s_manifest: // x -> [manifest, Mlist, Body, ln]
         {  LET p, val = h2!x, -1
            comline := h4!x
            UNTIL p=0 DO
            {  LET e = h3!p
               TEST e=0 THEN val := val+1
                        ELSE val := evalconst(e)
               manlist := newblk(manlist, h2!p, val)
               p := h4!p
            }
            x := h3!x
            LOOP
         }
}

AND mkextlist(x) BE UNTIL x=0 SWITCHON h1!x INTO
{  DEFAULT:  trnerr("Compiler error in declexts")

   CASE s_manifest:
   CASE s_global:
   CASE s_static: x := h3!x;    LOOP

   CASE s_fun:    x := h4!x;    LOOP

   CASE s_external:
               {  LET p = h2!x
                  LET id = h2!p
                  comline := h4!x
                  UNLESS findid(id, extlist)=0 DO
                      trnerr("External %s already declared", @h3!id)
                  UNTIL p=0 DO
                  {  extlist := newblk(extlist, h2!p, h3!p, 0)
                     p := h4!p
                  }
                  x := h3!x
                  LOOP
               }
}

AND mkgloblist(x) BE UNTIL x=0 SWITCHON h1!x INTO
{  DEFAULT:  trnerr("Compiler error in mkgloblist")

   CASE s_manifest:
   CASE s_external:
   CASE s_static: x := h3!x;    LOOP

   CASE s_fun:    x := h4!x;    LOOP

   CASE s_global: // x -> [global, Glist, Body, ln]
         {  LET p = h2!x
            LET id = h2!p
            comline := h4!x
            UNLESS findid(id, globlist)=0 DO
                trnerr("Global %s already declared", @h3!id)
            UNTIL p=0 DO
            {  LET e = h3!p
               TEST e=0 THEN lastgn := lastgn+1
                        ELSE lastgn := evalconst(e)
               globlist := newblk(globlist, h2!p, lastgn, 0)
               p := h4!p
            }
            x := h3!x
            LOOP
         }
}

AND mkfunlist(x) BE UNTIL x=0 SWITCHON h1!x INTO
{  DEFAULT:  trnerr("Compiler error in mkfunlist")

   CASE s_external:
   CASE s_manifest:
   CASE s_global:
   CASE s_static: x := h3!x;     LOOP

   CASE s_fun: {  LET id, lab, type = h2!x, nextlab(), -1
                  LET t = ?
                  comline := h6!x
                  UNLESS findid(id, funlist)=0 DO
                      trnerr("Function %s already declared", @h3!id)
                  t := findid(id, extlist)
                  UNLESS t=0 DO type := h4!t // plant the EXTERNAL type
                  t := findid(id, globlist)
                  UNLESS t=0 DO type, h4!t := -2, lab  // Mark as global
                  funlist := newblk(funlist, id, type, lab)
                  h5!x := lab
                  x := h4!x
                  LOOP
               }
}

AND mkstatlist(x) BE UNTIL x=0 SWITCHON h1!x INTO
{  DEFAULT:  trnerr("Compiler error in mkstatlist")

   CASE s_external:
   CASE s_manifest:
   CASE s_global: x := h3!x;     LOOP

   CASE s_fun:    x := h4!x;     LOOP

   CASE s_static: // x -> [static,   Slist, Body, ln]
         {  LET p = h2!x
            comline := h4!x
            UNTIL p=0 DO // p -> [sdef, Vid, 0, Slist]
                         //   or [sdef, Vid, SK, Slist]
            {  LET vid, e, lab = h2!p, h3!p, nextlab()
               UNLESS e=0 DO trnstat(e)
               out2(s_dlab, lab)
               TEST e=0 THEN out2(s_dw, 0)
                        ELSE {  LET q = sdlist
                                out2(h2!q, h3!q)
                                sdlist := h1!q
                                retblk(q)
                             }

               UNLESS findid(vid, funlist)=0 & findid(vid, statlist)=0 DO
                      trnerr("Name %s already declared", @h3!vid)
               statlist := newblk(statlist, vid, lab)
               p := h4!p
            }
            x := h3!x
            LOOP
         }
}

AND trfunbodies(x) BE UNTIL x=0 SWITCHON h1!x INTO
{  DEFAULT:  trnerr("Compiler error in trfunbodies")

   CASE s_manifest: // x -> [manifest, Mlist, Body, ln]
   CASE s_global:   // x -> [global,   Glist, Body, ln]
   CASE s_static:   // x -> [static,   Slist, Body, ln]
   CASE s_external: // x -> [external, Xlist, Body, ln]
            x := h3!x;            LOOP

   CASE s_fun:      // x -> [fun, Vid, Fndef, Body, -, ln]
            transfun(x)
            x := h4!x
            LOOP
}

AND trnstat(x) BE SWITCHON h1!x INTO
{  DEFAULT:      sdlist := newblk(sdlist, s_dw, evalconst(x))
                 RETURN

   CASE s_comma: trnstat(h3!x)
                 trnstat(h2!x)
                 RETURN

   CASE s_lv: {  LET y, t = h2!x, 0
                 IF h1!y=s_vid & findid(y, loclist)=0 DO
                    t := findid(y, statlist)
                 IF t=0 DO trnerr("STATIC variable needed after '@'")
                 // t -> [link, vid, lab]
                 sdlist := newblk(sdlist, s_dl, h3!t)
                 RETURN
              }

   CASE s_table:  // x -> [table, SKlist]
   CASE s_ltable: // x -> [ltable, SKlist]
              {  LET p, lab = sdlist, nextlab()
                 trnstat(h2!x)
                 out2(s_dlab, lab)
                 UNTIL sdlist=p DO
                 {  LET q = sdlist
                    out2(h2!q, h3!q)
                    sdlist := h1!q
                    retblk(q)
                 }
                 sdlist := newblk(sdlist, s_dl, lab)
                 RETURN
              }

   CASE s_string: // x -> [string, <upb>, <bytes>]
              {  LET upb, s, lab = h2!x, @h3!x, nextlab()
                 out2(s_dlab, lab)
                 FOR i = 0 TO upb DO out2(s_db, s%i)
                 out2(s_db, 0) // strings are terminated by 0
                 sdlist := newblk(sdlist, s_dl, lab)
                 RETURN
              }

   CASE s_vec:  // x -> [vec, K, -]
   CASE s_cvec: // x -> [cvec, K, -]
              {  LET upb, lab = evalconst(h2!x), nextlab()
                 IF h1!x=s_cvec DO upb := upb/4
                 out2(s_dlab, lab)
                 out2(s_ds, upb+1)
                 sdlist := newblk(sdlist, s_dl, lab)
                 RETURN
              }

   CASE s_vid:
              {  LET t = findid(x, funlist)
                 IF t=0 DO trnerr("FUN %s not declared", @h3!x)
                 // t -> [link, vid, type, lab]
                 sdlist := newblk(sdlist, s_dl, h4!t)
                 RETURN
              }
}

// tablabs compiles the static data for strings and tables that
// occur in function bodies.
AND tablabs(x) BE UNTIL x=0 SWITCHON h1!x INTO
{  DEFAULT:  trnerr("Error in tablabs, op %n", h1!x)
             RETURN

   CASE s_numb:
   CASE s_vid:
   CASE s_cid:
   CASE s_true:
   CASE s_false:
   CASE s_query:
   CASE s_tablab:   // replacement for s_string and s_table
   CASE s_vec:
   CASE s_cvec:
   CASE s_por:
   CASE s_dots:
   CASE s_break:
   CASE s_loop:
             RETURN

   CASE s_string:
   CASE s_table:
          {  LET p = sdlist
             trnstat(x)
             // sdlist -> [link, s_dl, lab]
             h1!x, h2!x := s_tablab, h3!sdlist
             retblk(sdlist)
             sdlist := p
             RETURN
          }

   CASE s_sdef: // used in [let, slist, ln]
                // Slist -> 0
                //        | [SDEF, vid, 0, Slist]
                //        | [SDEF, vid, E, Slist]
   CASE s_cond:
             tablabs(h2!x)
             tablabs(h3!x)
             x := h4!x; LOOP

   CASE s_call:
   CASE s_indb:
   CASE s_indw:
   CASE s_lsh:
   CASE s_rsh:
   CASE s_bitand:
   CASE s_mult:
   CASE s_div:
   CASE s_mod:
   CASE s_xor:
   CASE s_bitor:
   CASE s_plus:
   CASE s_sub:
   CASE s_rel:
   CASE s_and:
   CASE s_or:
   CASE s_eq:
   CASE s_ne:
   CASE s_le:
   CASE s_ge:
   CASE s_ls:
   CASE s_gr:
   CASE s_pand:
   CASE s_comma:
   CASE s_seq:
             tablabs(h2!x)
             x := h3!x; LOOP

   CASE s_for:
             comline := h7!x
             tablabs(h3!x)
             comline := h7!x
             tablabs(h4!x)
             comline := h7!x
             tablabs(h5!x)
             comline := h7!x
             x := h6!x; LOOP

   CASE s_test:
   CASE s_funpat:
             comline := h5!x
             tablabs(h2!x)
             comline := h5!x
             tablabs(h3!x)
             comline := h5!x
             x := h4!x; LOOP

   CASE s_repeatwhile:
   CASE s_repeatuntil:
   CASE s_handle:
   CASE s_if:
   CASE s_unless:
   CASE s_while:
   CASE s_until:
   CASE s_every:
   CASE s_match:
   CASE s_ass:
   CASE s_allass:
   CASE s_lshass:
   CASE s_rshass:
   CASE s_andass:
   CASE s_multass:
   CASE s_divass:
   CASE s_modass:
   CASE s_xorass:
   CASE s_plusass:
   CASE s_subass:
   CASE s_orass:
             comline := h4!x
             tablabs(h2!x)
             comline := h4!x
             x := h3!x; LOOP

   CASE s_let:
   CASE s_repeat:
   CASE s_raise:
   CASE s_goto:
   CASE s_result:
   CASE s_exit:
   CASE s_return:
             comline := h3!x
             x := h2!x; LOOP

   CASE s_inc1a:
   CASE s_inc4a:
   CASE s_dec1a:
   CASE s_dec4a:
   CASE s_inc1b:
   CASE s_inc4b:
   CASE s_dec1b:
   CASE s_dec4b:

   CASE s_neg:
   CASE s_bitnot:
   CASE s_not:
   CASE s_abs:
   CASE s_lv:
   CASE s_indb0:
   CASE s_indw0:
   CASE s_ptr:
   CASE s_peq:
   CASE s_pne:
   CASE s_ple:
   CASE s_pge:
   CASE s_pls:
   CASE s_pgr:
   CASE s_pass:
   CASE s_plshass:
   CASE s_prshass:
   CASE s_pmultass:
   CASE s_pdivass:
   CASE s_pmodass:
   CASE s_pandass:
   CASE s_pxorass:
   CASE s_pplusass:
   CASE s_psubass:
   CASE s_porass:

   CASE s_valof:
   CASE s_ltable:
   CASE s_scope:
             x := h2!x; LOOP
}

// The following function is used to measure the approx size
// of an expression.  It is called during the translation of
// WHILE and UNTIL to see if it is worth translating the controlling
// expression twice.  Large expressions or expressions containing
// assignments should only be translated once.
// It is also used to decide which operand of a symetric operator
// to compile first.

AND expsize(x) = VALOF
{  LET res = 1
   IF x=0 RESULTIS 0
   SWITCHON h1!x INTO
   {  DEFAULT:  RESULTIS 100

      CASE s_cond:  res := res + expsize(h4!x)

      CASE s_call:
      CASE s_indb:
      CASE s_indw:
      CASE s_lsh:
      CASE s_rsh:
      CASE s_bitand:
      CASE s_mult:
      CASE s_div:
      CASE s_mod:
      CASE s_xor:
      CASE s_bitor:
      CASE s_plus:
      CASE s_sub:
      CASE s_rel:
      CASE s_and:
      CASE s_or:
      CASE s_eq:
      CASE s_ne:
      CASE s_le:
      CASE s_ge:
      CASE s_ls:
      CASE s_gr:
      CASE s_comma:  res := res + expsize(h3!x)

      CASE s_inc1a:
      CASE s_inc4a:
      CASE s_dec1a:
      CASE s_dec4a:
      CASE s_inc1b:
      CASE s_inc4b:
      CASE s_dec1b:
      CASE s_dec4b:

      CASE s_neg:
      CASE s_bitnot:
      CASE s_not:
      CASE s_abs:
      CASE s_lv:
      CASE s_indb0:
      CASE s_indw0:  res := res + expsize(h2!x)

      CASE s_numb:
      CASE s_vid:
      CASE s_cid:
      CASE s_true:
      CASE s_false:
      CASE s_query:
      CASE s_tablab: RESULTIS res
   }
}

// The following procedure generates LOCS statements for dynamic variables
// and vectors, and adds the names of local variables to loclist.
AND decldyn(x) BE UNTIL x=0 SWITCHON h1!x INTO
{  DEFAULT:  trnerr("Error in decldyn, op %n", h1!x)
             RETURN

   CASE s_numb:
   CASE s_vid:
   CASE s_cid:
   CASE s_true:
   CASE s_false:
   CASE s_string:
   CASE s_table:
   CASE s_query:
   CASE s_tablab:   // replacement for s_string and s_table
   CASE s_por:
   CASE s_break:
   CASE s_loop:
   CASE s_valof:
   CASE s_for:
   CASE s_scope:
             RETURN

   CASE s_let:    // x -> [let, Slist, ln]
                  // Slist -> 0
                  //        | [sdef, vid, E, Slist]
                  //        | [sdef, vid, 0, Slist]
          {  LET p = h2!x
             comline := h3!x
             UNTIL p=0 DO
             {  checkdistinct(h2!p)
                loclist := newblk(loclist, h2!p, 0, ssp)
                out2(s_locs, 1) // for the vid
                ssp := ssp+1
                decldyn(h3!p)   // decl locals in E
                p := h4!p
             }
             RETURN
          }

   CASE s_vec:  // x -> [vec, K, q]
   CASE s_cvec: // x -> [cvec, K, q]
          {  LET upb = evalconst(h2!x)
             IF h1!x=s_cvec DO upb := upb/4
             UNLESS upb>=0 DO trnerr("Bad vector upper bound")
             h3!x := ssp
             out2(s_locs, upb+1)
             ssp := ssp + upb + 1
             RETURN
          }

   CASE s_ltable: // x -> [ltable, Elist, q]
          {  LET len = listlen(h2!x)
             out2(s_locs, len)
             h3!x := ssp
             ssp := ssp + len
             x := h2!x
             LOOP
          }

   // The arguments of a MATCH or EVERY construct
   // are in the current dynamic scope, but NOT the body.
   CASE s_match:
   CASE s_every:
             x := h2!x; LOOP

   CASE s_cond:
             decldyn(h2!x)
             decldyn(h3!x)
             x := h4!x; LOOP

   CASE s_call:
   CASE s_indb:
   CASE s_indw:
   CASE s_lsh:
   CASE s_rsh:
   CASE s_bitand:
   CASE s_mult:
   CASE s_div:
   CASE s_mod:
   CASE s_xor:
   CASE s_bitor:
   CASE s_plus:
   CASE s_sub:
   CASE s_rel:
   CASE s_and:
   CASE s_or:
   CASE s_eq:
   CASE s_ne:
   CASE s_le:
   CASE s_ge:
   CASE s_ls:
   CASE s_gr:
   CASE s_pand:
   CASE s_comma:
   CASE s_seq:
             decldyn(h2!x)
             x := h3!x; LOOP

   CASE s_test:
             comline := h5!x
             decldyn(h2!x)
             comline := h5!x
             decldyn(h3!x)
             comline := h5!x
             x := h4!x; LOOP

   CASE s_repeatwhile:
   CASE s_repeatuntil:
   CASE s_if:
   CASE s_unless:
   CASE s_while:
   CASE s_until:
   CASE s_ass:
   CASE s_allass:
   CASE s_lshass:
   CASE s_rshass:
   CASE s_multass:
   CASE s_divass:
   CASE s_modass:
   CASE s_andass:
   CASE s_xorass:
   CASE s_plusass:
   CASE s_subass:
   CASE s_orass:
             comline := h4!x
             decldyn(h2!x)
             comline := h4!x
             x := h3!x; LOOP

   CASE s_handle:
             comline := h4!x
             x := h2!x; LOOP

   CASE s_repeat:
   CASE s_raise:
   CASE s_goto:
   CASE s_result:
   CASE s_exit:
   CASE s_return:
             comline := h3!x
             x := h2!x; LOOP

   CASE s_inc1a:
   CASE s_inc4a:
   CASE s_dec1a:
   CASE s_dec4a:
   CASE s_inc1b:
   CASE s_inc4b:
   CASE s_dec1b:
   CASE s_dec4b:

   CASE s_neg:
   CASE s_bitnot:
   CASE s_not:
   CASE s_abs:
   CASE s_lv:
   CASE s_indb0:
   CASE s_indw0:
             x := h2!x; LOOP
}

// The following function is used to translate function definitions.
AND transfun(x) BE
{  LET t, numbargs = 0, ?
   // x -> [fun, vid, Fndef, Body, lab, ln]
   procname := h2!x
   comline := h6!x

   hdepth := 0
   matchhdepth, rephdepth, valofhdepth := 0, 0, 0
   matchpos, matchlen := 0, 0

   matchlab := -2
   breaklab,  looplab := -2, -2
   resultlab, exitlab := -2, nextlab()

   tablabs(h3!x) // replace all occurrences of
                 // [string,..] and [table,..]
                 // by [tablab,lab]

   t := findid(procname, funlist)

   comline := h6!x
   outline()

   TEST -2<=h3!t<=0 THEN {  out2(s_fun, h5!x)
                            outstring(@h3!procname)
                         }
                    ELSE {  // t -> [link, vid, type, lab]
                            out2(s_cfun, h5!x)
                            outstring(@h3!procname)
                            outstring(h3!t+2)
                         }

   numbargs := maxpatlen(h3!x)
   out2(s_fnargs, numbargs)   // allocate space for function arguments
   ssp := 3 + numbargs

   trmatch(h3!x, 3, numbargs) // first arg (if any) is in P!3

   out2(s_ln, 0)
   out2(s_raise, 1)
   out2(s_lab, exitlab)
   out1(s_return)
   out1(s_endfun)
   procname := 0
}

// The following function translates a list of match items
// of the form :
//       : Plist => Clist
//         ...
//       : Plist => Clist
// which can occur as the body of function definition, in a
// MATCH or EVERY construct or in the HANDLE construct.
//   x        is the list of match items
//   ssp1     is the position of the first argument
//   numbargs is 3 for the HANDLE construct otherwise it is the
//            the maximum number of expected arguments.
// On entry ssp is the stack position of the first argument????

AND trmatch(x, ssp1, numbargs) BE
{  LET ptr0 = ssp      // the Q number of the next pattern pointer
   //  ssp1 is the Q number of the first argument (if any)
   LET omp, omlen, oml, omhd = matchpos, matchlen, matchlab, matchhdepth

   matchpos, matchlen, matchlab := ssp1, numbargs, nextlab()
   matchhdepth := hdepth
   out2(s_lab, matchlab)
   out3(s_match, numbargs, matchpos)

   UNTIL x=0 DO
   {  // x -> [funpat, Plist, Clist, Fndef, ln]
      LET flab = nextlab()     // match failure label
      LET oldscopeptr = scopeptr
      scopeptr := loclist
      comline := h5!x
      outline()

      allocptrs(h2!x, 0, ssp1) // allocate space for the access pointers
                               // for this pattern list

      // declare vids and dynamic quantities in the pattern
      nptr := ptr0  // the Q number of the first access pointer
      declpatids(h2!x, 0, ssp1)

      nptr := ptr0
      initptrs(h2!x, 0, ssp1)

      // compile pattern tests, match failure jumps to lab
      nptr := ptr0  // the Q number of the first access pointer
      trnpat(h2!x, 0, ssp1, flab)

      // compile pattern assignment operations
      nptr := ptr0  // the Q number of the first access pointer
      trnpatinits(h2!x, 0, ssp1)

      // compiler the command list in given context
      {  LET q, oldscopeptr = ssp, scopeptr
         scopeptr := loclist
         decldyn(h3!x)
         trans(h3!x)
         // exitlab=0 if in an EVERY statement
         IF exitlab>0 DO out2(s_jump, exitlab)
         retblks(loclist, scopeptr)
         loclist := scopeptr
         scopeptr := oldscopeptr
         UNLESS ssp=q DO {  out2(s_stack, q); ssp := q }
      }

      out2(s_lab, flab)
      retblks(loclist, scopeptr)
      loclist := scopeptr
      scopeptr := oldscopeptr
      UNLESS ssp=ptr0 DO {  out2(s_stack, ptr0); ssp := ptr0 }

      x := h4!x   // deal with next match item (if any)
   }

   matchpos, matchlen, matchlab, matchhdepth := omp, omlen, oml, omhd
   ssp := ptr0
}

AND maxpatlen(x) = VALOF
{  LET res = 0
   UNTIL x=0 DO {  LET len = listlen(h2!x)
                   IF res<len DO res := len
                   x := h4!x
                }
   RESULTIS res
}

AND listlen(p) = VALOF
{  LET res = 1
   IF p=0 RESULTIS 0
   WHILE h1!p=s_comma DO res, p := res+1, h3!p
   RESULTIS res
}

// Allocate space for the access pointers for pattern x
// n, i gives the address of the location to be matched by the
// pattern. (0,i) corresponds to cell P!i, and (n,i) corresponds
// to cell P!n!i.
AND allocptrs(x, n, i) BE UNLESS x=0 SWITCHON h1!x INTO
{  DEFAULT:      RETURN

   CASE s_comma: allocptrs(h2!x, n, i)
                 allocptrs(h3!x, n, i+1)
                 RETURN

   CASE s_pand:  allocptrs(h2!x, n, i)
                 allocptrs(h3!x, n, i)
                 RETURN

   CASE s_ptr:   out1(s_ptr)
                 ssp := ssp + 1
                 allocptrs(h2!x, ssp-1, 0)
}

// Initialise the access pointers for pattern x
AND initptrs(x, n, i) BE UNLESS x=0 SWITCHON h1!x INTO
{  DEFAULT:      RETURN

   CASE s_comma: initptrs(h2!x, n, i)
                 initptrs(h3!x, n, i+1)
                 RETURN

   CASE s_pand:  initptrs(h2!x, n, i)
                 initptrs(h3!x, n, i)
                 RETURN

   CASE s_ptr:   lpath(n, i)
                 ssp := ssp+1
                 out2(s_sp, nptr) // initialise new access pointer
                 ssp := ssp-1
                 nptr := nptr + 1
                 initptrs(h2!x, nptr-1, 0)
}

// This function declares dynamic names by placing them in loclist,
// and generates LOCS to allocate space for dynamic vectors occurring
// within the pattern.
AND declpatids(x, n, i) BE UNLESS x=0 SWITCHON h1!x INTO
{  DEFAULT:      //trnerr("Error in declpatids, op %n", h1!x)
                 RETURN

   CASE s_peq:
   CASE s_pne:
   CASE s_ple:
   CASE s_pge:
   CASE s_pls:
   CASE s_pgr:
   CASE s_pass:
   CASE s_plshass:
   CASE s_prshass:
   CASE s_pmultass:
   CASE s_pdivass:
   CASE s_pmodass:
   CASE s_pandass:
   CASE s_pxorass:
   CASE s_pplusass:
   CASE s_psubass:
   CASE s_porass:
                 decldyn(h2!x)
                 RETURN

   CASE s_comma: declpatids(h2!x, n, i)
                 declpatids(h3!x, n, i+1)
                 RETURN

   CASE s_pand:  declpatids(h2!x, n, i)
                 declpatids(h3!x, n, i)
                 RETURN

   CASE s_vid:   checkdistinct(x)
                 loclist := newblk(loclist, x, n, i)
                 RETURN

   CASE s_ptr:   nptr := nptr+1
                 declpatids(h2!x, nptr-1, 0)
                 RETURN
}

// In the following function (n,i) denotes the current argument,
// b gives the sense of the jump (TRUE -> jt, FALSE -> jf), lab is the
// destination label.  x is the pattern.
AND trnkpat(x, n, i, b, lab) BE UNLESS x=0 SWITCHON h1!x INTO
{  DEFAULT:    //trnerr("trnkpat %n", h1!x)
               RETURN

   CASE s_cid:
   CASE s_numb:     lpath(n, i)
                    ssp := ssp+1
                    load(x)
                    out3(s_eq, (b->s_jt,s_jf), lab)
                    ssp := ssp-2
                    RETURN

   CASE s_true:     lpath(n, i)
                    ssp := ssp+1
                    out2((b->s_jt,s_jf), lab)
                    ssp := ssp-1
                    RETURN

   CASE s_false:    lpath(n, i)
                    ssp := ssp+1
                    out2((b->s_jf,s_jt), lab)
                    ssp := ssp-1
                    RETURN

   CASE s_dots:  TEST b
                 THEN {  LET m = nextlab()
                         lpath(n, i)
                         ssp := ssp+1
                         load(h2!x)
                         out3(s_ge, s_jf, m)
                         ssp := ssp-2
                         lpath(n, i)
                         ssp := ssp+1
                         load(h3!x)
                         out3(s_le, s_jt, lab)
                         ssp := ssp-2
                         out2(s_lab, m)
                      }
                 ELSE {  lpath(n, i)
                         ssp := ssp+1
                         load(h2!x)
                         out3(s_ge, s_jf, lab)
                         ssp := ssp-2
                         lpath(n, i)
                         ssp := ssp+1
                         load(h3!x)
                         out3(s_le, s_jf, lab)
                         ssp := ssp-2
                      }
                 RETURN
}

AND trnpat(x, n, i, lab) BE UNLESS x=0 SWITCHON h1!x INTO
{  DEFAULT:      RETURN

   CASE s_comma: trnpat(h2!x, n, i, lab)
                 trnpat(h3!x, n, i+1, lab)
                 RETURN

   CASE s_pand:  trnpat(h2!x, n, i, lab)
                 trnpat(h3!x, n, i, lab)
                 RETURN

   CASE s_por:{  LET m = nextlab()
                 WHILE h1!x=s_por DO
                 {  trnkpat(h2!x, n, i, TRUE, m)
                    x := h3!x
                 }
                 trnkpat(x, n, i, FALSE, lab)
                 out2(s_lab, m)
                 RETURN
              }

   CASE s_cid:
   CASE s_numb:
   CASE s_true:
   CASE s_false:
   CASE s_dots:  trnkpat(x, n, i, FALSE, lab)

   CASE s_vid:
   CASE s_query: RETURN

   CASE s_ptr:   nptr := nptr+1
                 trnpat(h2!x, nptr-1, 0, lab)
                 RETURN

   CASE s_peq:
   CASE s_pne:
   CASE s_ple:
   CASE s_pge:
   CASE s_pls:
   CASE s_pgr:
                 lpath(n, i)
                 ssp := ssp+1
                 load(h2!x)
                 out3(s_eq+h1!x-s_peq, s_jf, lab)
                 ssp := ssp-2
                 RETURN
}

AND lpath(n, i) BE TEST n=0 THEN out2(s_lp, i)
                   ELSE out3(s_lpath, n, i)


AND llpath(n, i) BE TEST n=0 THEN out2(s_llp, i)
                    ELSE out3(s_llpath, n, i)

AND spath(n, i) BE TEST n=0 THEN out2(s_sp, i)
                   ELSE out3(s_spath, n, i)

AND trnpatinits(x, n, i) BE UNLESS x=0 SWITCHON h1!x INTO
{  DEFAULT:      RETURN

   CASE s_comma: trnpatinits(h2!x, n, i)
                 trnpatinits(h3!x, n, i+1)
                 RETURN

   CASE s_pand:  trnpatinits(h2!x, n, i)
                 trnpatinits(h3!x, n, i)
                 RETURN

   CASE s_ptr:   nptr := nptr + 1
                 trnpatinits(h2!x, nptr-1, 0)
                 RETURN

   CASE s_pass:  load(h2!x)
                 spath(n, i)
                 ssp := ssp-1
                 RETURN

   CASE s_plshass:
   CASE s_prshass:
   CASE s_pmultass:
   CASE s_pdivass:
   CASE s_pmodass:
   CASE s_pandass:
   CASE s_pxorass:
   CASE s_pplusass:
   CASE s_psubass:
   CASE s_porass:
                 lpath(n, i)
                 ssp := ssp+1
                 load(h2!x)
                 out1(s_lsh+h1!x-s_plshass)
                 ssp := ssp-1
                 spath(n, i)
                 ssp := ssp-1
                 RETURN
}

// The structure of an id list is as follows:
//
// t -> 0
//   |  [t, id, a, b]   where a and b depend on the kind of id list
//
// findid(id, t) returns the pointer to the matching id node
//                       or zero if not found
AND findid(id, t) = VALOF
{  UNTIL t=0 | id=h2!t DO t := h1!t
   RESULTIS t
}

// The following routine translates commands and expressions.
// Expression results are left in RES.

LET trans(x) BE
{  LET sw = FALSE

   IF x=0 RETURN

   SWITCHON h1!x INTO
   {  DEFAULT: load(x); out1(s_str); ssp := ssp-1
               RETURN

      CASE s_and:CASE s_or:
         {  LET lab, lab1 = nextlab(), nextlab()
            jumpcond(x, FALSE, lab)
            out2(s_true, s_str)
            out2(s_jump, lab1)
            out2(s_lab, lab)
            out2(s_false, s_str)
            out2(s_lab, lab1)
            RETURN
         }

      CASE s_cond:  {  LET l, m = nextlab(), nextlab()
                       jumpcond(h2!x, FALSE, m)
                       trans(h3!x)
                       out2(s_jump, l)
                       out2(s_lab, m)
                       trans(h4!x)
                       out2(s_lab, l)
                       RETURN
                    }

      CASE s_valof: {  LET oldscopeptr, q, rl = scopeptr, ssp, resultlab
                       LET oldvalofhdepth = valofhdepth
                       valofhdepth := hdepth
                       scopeptr := loclist
                       resultlab := nextlab()
                       decldyn(h2!x)
                       trans(h2!x)
                       out2(s_lab, resultlab)
                       UNLESS ssp=q DO {  ssp := q; out2(s_stack, ssp) }
                       retblks(loclist, scopeptr)
                       loclist, resultlab := scopeptr, rl
                       valofhdepth := oldvalofhdepth
                       scopeptr := oldscopeptr
                       RETURN
                    }

      CASE s_scope: {  LET oldscopeptr, q = scopeptr, ssp
                       scopeptr := loclist
                       decldyn(h2!x)
                       trans(h2!x)
                       UNLESS ssp=q DO {  ssp := q; out2(s_stack, ssp) }
                       retblks(loclist, scopeptr)
                       loclist := scopeptr
                       scopeptr := oldscopeptr
                       RETURN
                    }

      CASE s_match:
      CASE s_every:
           {  LET s, argpos, elab = ssp, ssp, exitlab
              LET len, mplen = listlen(h2!x), maxpatlen(h3!x)
              IF len>mplen DO
                 trnerr("Too many MATCH or EVERY arguments")
              exitlab := h1!x=s_match -> nextlab(), 0
              comline := h4!x
              outline()
              out2(s_locs, mplen)
              ssp := ssp + mplen
              loadargs(h2!x)
              out3(s_setargs, len, argpos)
              ssp := ssp-len
              trmatch(h3!x, argpos, mplen)
              IF h1!x=s_match DO {  out2(s_ln, 0)
                                    out2(s_raise, 1)
                                    out2(s_lab, exitlab)
                                 }
              exitlab := elab
              UNLESS ssp=s DO {  ssp := s; out2(s_stack, ssp) }
              RETURN
           }

      CASE s_call:
      {  LET s = ssp
         LET fe = h2!x
         LET argno = listlen(h3!x)
         comline := h4!x
         outline()
         out2(s_stack, ssp+3)
         ssp := ssp+3
         loadargs(h3!x)
         load(fe)
         IF h1!fe=s_vid &
            findid(fe, loclist)=0 &
            findid(fe, statlist)=0 &
            findid(fe, funlist)=0 DO
         {  LET t = findid(fe, extlist)
            UNLESS t=0 | h3!t=0 DO
            {  out2(s_callc, s)
               outstring(h3!t+2)
               ssp := s
               RETURN
            }
         }
         out2(s_call, s)
         ssp := s
         RETURN
      }

      CASE s_let:
      {  LET p = h2!x
         comline := h3!x
         outline()
         UNTIL p=0 DO
         {  UNLESS h3!p=0 DO assign(h2!p, h3!p)
            p := h4!p
         }
         RETURN
      }

      CASE s_ass:
         comline := h4!x
         outline()
         assign(h2!x, h3!x)
         RETURN

      CASE s_allass:
         comline := h4!x
         outline()
         assignall(1, h2!x, h3!x)
         RETURN

      CASE s_lshass:
      CASE s_rshass:
      CASE s_multass:
      CASE s_divass:
      CASE s_modass:
      CASE s_andass:
      CASE s_xorass:
      CASE s_plusass:
      CASE s_subass:
      CASE s_orass:
         comline := h4!x
         outline()
         assignop(h1!x+s_lsh-s_lshass, h2!x, h3!x)
         RETURN

      CASE s_goto:
      {  LET q, len = ssp, listlen(h2!x)
         comline := h3!x
         outline()
         IF len>matchlen DO trnerr("Too many GOTO arguments")
         loadargs(h2!x)
         out3(s_setargs, len, matchpos)
         ssp := q
         FOR i = 1 TO hdepth-matchhdepth DO out1(s_unhandle)
         out2(s_jump, matchlab)
         RETURN
      }

      CASE s_raise:
      {  LET q, count = ssp, ?
         comline := h3!x
         outline()
         loadargs(h2!x)
         count := ssp-q
         UNLESS 1<=count<=3 DO trnerr("RAISE must have from 1 to 3 arguments")
         out2(s_raise, count)
         ssp := q
         RETURN
      }

      CASE s_handle:  // x -> [Handle, C, Fndef, ln]
      {  LET lab, elab = nextlab(), exitlab
         exitlab := nextlab()
         comline := h4!x
         outline()
         out2(s_handle, lab)
         ssp := ssp+3
         hdepth := hdepth+1
         trans(h2!x)
         out1(s_unhandle)
         hdepth := hdepth-1
         out2(s_jump, exitlab)

         IF maxpatlen(h3!x) > 3 DO trnerr("Handler pattern too long")
         out2(s_lab, lab)
         trmatch(h3!x, ssp-3, 3)

         out2(s_lp, ssp-3)
         out2(s_lp, ssp-2)
         out2(s_lp, ssp-1)
         out2(s_raise, 3)
         out2(s_lab, exitlab)
         ssp := ssp-3
         out2(s_stack, ssp)
         exitlab := elab
         RETURN
      }

      CASE s_unless: sw := TRUE
      CASE s_if:
      {  LET lab = nextlab()
         comline := h4!x
         outline()
         jumpcond(h2!x, sw, lab)
         trans(h3!x)
         out2(s_lab, lab)
         RETURN
      }

      CASE s_test:
      {  LET l, m = nextlab(), nextlab()
         comline := h5!x
         outline()
         jumpcond(h2!x, FALSE, l)
         trans(h3!x)
         out2(s_jump, m)
         out2(s_lab, l)
         trans(h4!x)
         out2(s_lab, m)
         RETURN
      }

      CASE s_loop:
         comline := h2!x
         outline()
         IF looplab<0 DO trnerr("Illegal use of LOOP")
         IF looplab=0 DO looplab := nextlab()
         FOR i = 1 TO rephdepth-hdepth DO out1(s_unhandle)
         out2(s_jump, looplab)
         RETURN

      CASE s_break:
         comline := h2!x
         outline()
         IF breaklab=-2 DO trnerr("Illegal use of BREAK")
         IF breaklab= 0 DO breaklab := nextlab()
         FOR i = 1 TO rephdepth-hdepth DO out1(s_unhandle)
         out2(s_jump, breaklab)
         RETURN

      CASE s_exit:   ///?????
         comline := h3!x
         outline()
         IF exitlab=-2 DO trnerr("Illegal use of EXIT")
         trans(h2!x)
         IF exitlab=0 DO exitlab := nextlab()
         FOR i = 1 TO matchhdepth-hdepth DO out1(s_unhandle)
         out2(s_jump, exitlab)
         RETURN

      CASE s_return:
         trans(h2!x)
         FOR i = 1 TO hdepth DO out1(s_unhandle)
         out1(s_return)
         RETURN

      CASE s_result:
         comline := h3!x
         outline()
         UNLESS resultlab>0 DO trnerr("RESULT out of context")
         trans(h2!x)
         FOR i = 1 TO valofhdepth-hdepth DO out1(s_unhandle)
         out2(s_jump, resultlab)
         RETURN

      CASE s_while: sw := TRUE
      CASE s_until:
      {  LET lab = nextlab()
         LET bl, ll = breaklab, looplab
         LET oldrephdepth = rephdepth
         rephdepth := hdepth
         comline := h4!x
         outline()
         breaklab, looplab := nextlab(), 0
         TEST expsize(h2!x)<10
         THEN jumpcond(h2!x, ~sw, breaklab)
         ELSE {  looplab := nextlab(); out2(s_jump, looplab) }
         out2(s_lab, lab)
         trans(h3!x)
         UNLESS looplab=0 DO out2(s_lab, looplab)
         comline := h4!x
         jumpcond(h2!x, sw, lab)
         out2(s_lab, breaklab)
         rephdepth := oldrephdepth
         breaklab, looplab := bl, ll
         RETURN
      }

      CASE s_repeatwhile: sw := TRUE
      CASE s_repeatuntil:
      {  LET lab, bl, ll = nextlab(), breaklab, looplab
         LET oldrephdepth = rephdepth
         rephdepth := hdepth
         comline := h4!x
         breaklab, looplab := 0, 0
         out2(s_lab, lab)
         trans(h2!x)
         UNLESS looplab=0 DO out2(s_lab, looplab)
         comline := h4!x
         outline()
         jumpcond(h3!x, sw, lab)
         UNLESS breaklab=0 DO out2(s_lab, breaklab)
         rephdepth := oldrephdepth
         breaklab, looplab := bl, ll
         RETURN
      }

      CASE s_repeat:
      {  LET bl, ll = breaklab, looplab
         LET oldrephdepth = rephdepth
         rephdepth := hdepth
         comline := h3!x
         outline()
         breaklab, looplab := 0, nextlab()
         out2(s_lab, looplab)
         trans(h2!x)
         out2(s_jump, looplab)
         IF breaklab>0 DO out2(s_lab, breaklab)
         rephdepth := oldrephdepth
         breaklab, looplab := bl, ll
         RETURN
      }

      CASE s_for:
         transfor(x)
         RETURN

      CASE s_seq:
         trans(h2!x)
         x := h3!x
   }
} REPEAT

AND checkdistinct(id) BE
{  LET p = loclist
   UNTIL p=0 | p=scopeptr DO
   {  IF id=h2!p DO trnerr("Name %s already declared", @h3!id)
      p := h1!p
   }
}

LET jumpcond(x, b, l) BE
{  LET sw = b

   SWITCHON h1!x INTO
   {  CASE s_false: b := NOT b
      CASE s_true:  IF b DO out2(s_jump, l)
                    RETURN

      CASE s_not:   jumpcond(h2!x, NOT b, l)
                    RETURN

      CASE s_and:   sw := NOT sw
      CASE s_or:    TEST sw THEN {  jumpcond(h2!x, b, l)
                                    jumpcond(h3!x, b, l)
                                 }
                            ELSE {  LET m = nextlab()
                                    jumpcond(h2!x, NOT b, m)
                                    jumpcond(h3!x, b, l)
                                    out2(s_lab, m)
                                 }
                    RETURN

      CASE s_rel: TEST b
                  THEN {  LET lab = 0
                          load(h2!x)
                          {  x := h3!x
                             load(h2!x)
                             IF h3!x=0 BREAK
                             IF lab=0 DO lab := nextlab()
                             out1(s_cpr)
                             out3(h1!x, s_jf, lab)
                             ssp := ssp-2
                             out1(s_lr)
                             ssp := ssp+1
                          } REPEAT
                          out3(h1!x, s_jt, l)
                          ssp := ssp-2
                          UNLESS lab=0 DO out2(s_lab, lab)
                          RETURN
                       }
                  ELSE    load(h2!x)
                          x := h3!x
                          {  LET rel = h1!x
                             load(h2!x)
                             x := h3!x
                             UNLESS x=0 DO out1(s_cpr)
                             out3(rel, s_jf, l)
                             ssp := ssp-2
                             IF x=0 RETURN
                             out1(s_lr)
                             ssp := ssp+1
                          } REPEAT

        DEFAULT:
                    load(x)
                    out2((b -> s_jt, s_jf), l)
                    ssp := ssp-1
                    RETURN
   }
}

AND transfor(x) BE
{  LET oldscopeptr, oldlocs, oldssp = scopeptr, loclist, ssp
   LET lab = nextlab()
   LET bl, ll = breaklab, looplab
   LET k, n, step = 0, 0, 1
   LET qctrl = 0
   LET oldrephdepth = rephdepth
   rephdepth := hdepth

   breaklab, looplab := nextlab(), 0

   comline := h7!x
   outline()

   // allocate space for dynamic quantities in the initial value
   // and end limit expressions
   scopeptr := loclist
   decldyn(h3!x)
   decldyn(h4!x)

   out2(s_locs, 1)  // allocate space for the control variable
   qctrl := ssp
   ssp := ssp+1
   loclist := newblk(loclist, h2!x, 0, qctrl)

   TEST h1!(h4!x)=s_numb
   THEN    k, n := s_ln, h2!(h4!x)
   ELSE {  k, n := s_lp, ssp
           out2(s_locs, 1)  // allocate space for end limit
           ssp := ssp+1
        }

   load(h3!x)
   out2(s_sp, qctrl)    // initialise control variable
   ssp := ssp-1

   IF k=s_lp DO {  load(h4!x)
                   out2(s_sp, n) // set end limit
                   ssp := ssp-1
                }

   UNLESS h5!x=0 DO step := evalconst(h5!x)

   TEST k=s_ln & h1!(h3!x)=s_numb  // check for constant limits
   THEN {  LET initval = h2!(h3!x)
           IF step>=0 & initval>n | step<0 & initval<n DO
                                          out2(s_jump, breaklab)
        }
   ELSE {  out2(s_lp, qctrl)
           out2(k, n)
           out1(step>=0 -> s_gr, s_ls)
           out2(s_jt, breaklab)
        }

   comline := h7!x

   scopeptr := loclist // new dynamic scope for the body
   decldyn(h6!x)

   out2(s_lab, lab)
   trans(h6!x)
   UNLESS looplab=0 DO out2(s_lab, looplab)
   out2(s_lp, qctrl); out2(s_ln, step); out1(s_plus); out2(s_sp, qctrl)
   out2(s_lp, qctrl); out2(k,n)
   out1(step>=0 -> s_le, s_ge)
   out2(s_jt, lab)
   out2(s_lab, breaklab)

   retblks(loclist, oldlocs)
   loclist := oldlocs // leave both dynamic scopes
   scopeptr := oldscopeptr
   rephdepth := oldrephdepth
   breaklab, looplab := bl, ll
   ssp := oldssp
   out2(s_stack, ssp)
}


LET load(x) BE
{  LET op = ?

   IF x=0 DO {  out1(s_query); ssp := ssp+1; RETURN }

   op := h1!x

   IF isconst(x) DO
   {  out2(s_ln, evalconst(x))
      ssp := ssp + 1
      RETURN
   }

   SWITCHON op INTO
   {  DEFAULT:
      CASE s_call:     trans(x)
                       out1(s_lr)
                       ssp := ssp+1
                       RETURN


      CASE s_seq:      trans(h2!x)
                       load(h3!x)
                       RETURN

      CASE s_true: CASE s_false: CASE s_query:
                       out1(op)
                       ssp := ssp+1
                       RETURN

      CASE s_vid:      transvid(x, lpath, s_lg, s_ll, s_lf, s_lx)
                       ssp := ssp+1
                       RETURN

      CASE s_cid:  {  LET c = findid(x, manlist)
                      IF c=0 DO trnerr("Constant %s not declared", @h3!x)
                      // c -> [link, cid, k]
                      out2(s_ln, h3!c)
                      ssp := ssp+1
                      RETURN
                   }

      CASE s_tablab:   // x -> [tablab, lab]
                       out2(s_lll, h2!x)
                       ssp := ssp+1
                       RETURN

      CASE s_numb:     // x -> [numb, k]
                       out2(s_ln, h2!x); ssp := ssp+1; RETURN

      CASE s_ltable:   // x -> [ltable, Elist, q]
                       initltab(h2!x, h3!x)

      CASE s_vec:      // x -> [vec,       K, q]
      CASE s_cvec:     // x -> [cvec,      K, q]
                       out2(s_llp, h3!x)
                       ssp := ssp+1
                       RETURN

      CASE s_inc1a:
      CASE s_inc4a:
      CASE s_dec1a:
      CASE s_dec4a:
      CASE s_inc1b:
      CASE s_inc4b:
      CASE s_dec1b:
      CASE s_dec4b:
                       loadlv(h2!x)
                       out1(op)
                       RETURN

      CASE s_lv:       loadlv(h2!x); RETURN

      CASE s_indb:
      CASE s_indw:
      CASE s_div: CASE s_mod: CASE s_sub:
      CASE s_lsh: CASE s_rsh:
                       load(h2!x); load(h3!x)
                       out1(op)
                       ssp := ssp-1
                       RETURN

      CASE s_mult: CASE s_plus:
      CASE s_bitand: CASE s_bitor: CASE s_xor:
         {  LET a, b = h2!x, h3!x
            TEST expsize(a)<expsize(b) THEN {  load(b); load(a) }
                                       ELSE {  load(a); load(b) }
            out1(op)
            ssp := ssp-1
            RETURN
         }

      CASE s_neg: CASE s_not: CASE s_bitnot: CASE s_abs:
      CASE s_indb0: CASE s_indw0:
            load(h2!x)
            out1(op)
            RETURN

      CASE s_rel:
            {  LET lab1, lab2 = 0, 0
               load(h2!x)
               x := h3!x
               {  LET rel = h1!x
                  load(h2!x)
                  x := h3!x
                  IF x=0 DO {  out1(rel)
                               ssp := ssp-1
                               BREAK
                            }
                  out1(s_str)
                  IF lab1=0 DO lab1, lab2 := nextlab(), nextlab()
                  out3(rel, s_jf, lab1)
                  ssp := ssp-2
                  out1(s_lr)
                  ssp := ssp+1
               } REPEAT
               UNLESS lab1=0 DO {  out1(s_true)
                                   ssp := ssp+1
                                   out2(s_jump, lab2)
                                   ssp := ssp-1
                                   out2(s_stack, ssp)
                                   out2(s_lab, lab1)
                                   out1(s_false)
                                   ssp := ssp+1
                                   out2(s_lab, lab2)
                                }
               RETURN
            }
   }
}


AND initltab(x, q) BE UNTIL x=0 SWITCHON h1!x INTO
{  DEFAULT:      load(x)
                 out2(s_sp, q)
                 ssp := ssp-1
                 RETURN

   CASE s_comma: initltab(h2!x, q)
                 x, q := h3!x, q+1
                 LOOP
}

AND loadlv(x) BE
{  UNLESS x=0 SWITCHON h1!x INTO
   {  DEFAULT:         ENDCASE

      CASE s_vid:      transvid(x, llpath, s_llg, s_lll, 0, 0)
                       ssp := ssp+1
                       RETURN

      CASE s_indb0:
      CASE s_indw0:    load(h2!x)
                       RETURN

      CASE s_indb:     load(h2!x)
                       load(h3!x)
                       out1(s_plus)
                       ssp := ssp-1
                       RETURN

      CASE s_indw:     load(h2!x)
                       load(h3!x)
                       out1(s_lvindw)
                       ssp := ssp-1
                       RETURN
   }

   trnerr("Ltype expression needed")
   out2(s_ln, 0)
   ssp := ssp+1
}

// Arguments are loaded in increasing stack locations
// loadargs is used in calls, MATCH, EVERY, GOTO and RAISE
AND loadargs(x) BE UNLESS x=0 TEST h1!x=s_comma
                              THEN {  load(h2!x)
                                      loadargs(h3!x)
                                   }
                              ELSE load(x)


LET evalconstrel(a, x) = VALOF
{  LET b = evalconst(h2!x)
   SWITCHON h1!x INTO
   {  DEFAULT: trnerr("Bad rel %n", h1!x)

      CASE s_eq: UNLESS a=b RESULTIS FALSE
                 ENDCASE
      CASE s_ne: UNLESS a~=b RESULTIS FALSE
                 ENDCASE
      CASE s_le: UNLESS a<=b RESULTIS FALSE
                 ENDCASE
      CASE s_ge: UNLESS a>=b RESULTIS FALSE
                 ENDCASE
      CASE s_ls: UNLESS a<b RESULTIS FALSE
                 ENDCASE
      CASE s_gr: UNLESS a>b RESULTIS FALSE
                 ENDCASE
   }
   a, x := b, h3!x
   IF x=0 RESULTIS TRUE
} REPEAT


LET isconst(x) = VALOF
{  IF x=0 RESULTIS FALSE

   SWITCHON h1!x INTO
   {  CASE s_cid:
      CASE s_numb:
      CASE s_true:
      CASE s_false:
      CASE s_query:  RESULTIS TRUE

      CASE s_cond:
          RESULTIS isconst(h2!x) & isconst(h3!x) & isconst(h4!x)


      CASE s_neg:
      CASE s_abs:
      CASE s_not:
      CASE s_bitnot: RESULTIS isconst(h2!x)

      CASE s_rel:
      CASE s_lsh:
      CASE s_rsh:
      CASE s_mult:
      CASE s_div:
      CASE s_mod:
      CASE s_bitand:
      CASE s_xor:
      CASE s_plus:
      CASE s_sub:
      CASE s_bitor:
      CASE s_and:
      CASE s_or:     IF isconst(h2!x) & isconst(h3!x)
                        RESULTIS TRUE

      DEFAULT:       RESULTIS FALSE
   }
}

LET evalconst(x) = VALOF
{  LET a, b = 0, 0

   IF x=0 DO {  trnerr("Compiler error in Evalconst")
                RESULTIS 0
             }

   SWITCHON h1!x INTO
   {  CASE s_cid:
        {  LET c = findid(x, manlist)
           UNLESS c=0 RESULTIS h3!c
           trnerr("Constant %s not declared", @h3!x)
           RESULTIS 0
        }

      CASE s_numb:   RESULTIS h2!x
      CASE s_true:   RESULTIS TRUE
      CASE s_false:  RESULTIS FALSE
      CASE s_query:  RESULTIS 0

      CASE s_cond:
          RESULTIS evalconst(h2!x) -> evalconst(h3!x), evalconst(h4!x)

      CASE s_rel:   RESULTIS evalconstrel(evalconst(h2!x), h3!x)

      CASE s_neg:
      CASE s_abs:
      CASE s_not:
      CASE s_bitnot: a := evalconst(h2!x)
                     ENDCASE

      CASE s_lsh:
      CASE s_rsh:
      CASE s_mult:
      CASE s_div:
      CASE s_mod:
      CASE s_bitand:
      CASE s_xor:
      CASE s_plus:
      CASE s_sub:
      CASE s_bitor:
      CASE s_and:
      CASE s_or:     a, b := evalconst(h2!x), evalconst(h3!x)
                     ENDCASE

      DEFAULT:
   }

   SWITCHON h1!x INTO
   {  CASE s_neg:    RESULTIS  -  a
      CASE s_abs:    RESULTIS ABS a
      CASE s_bitnot:
      CASE s_not:    RESULTIS NOT a

      CASE s_lsh:    RESULTIS a   <<   b
      CASE s_rsh:    RESULTIS a   >>   b
      CASE s_mult:   RESULTIS a   *    b
      CASE s_and:
      CASE s_bitand: RESULTIS a   &    b
      CASE s_xor:    RESULTIS a  NEQV  b
      CASE s_plus:   RESULTIS a   +    b
      CASE s_sub:    RESULTIS a   -    b
      CASE s_or:
      CASE s_bitor:  RESULTIS a   |    b

      CASE s_div:    UNLESS b=0 RESULTIS a   /    b
      CASE s_mod:    UNLESS b=0 RESULTIS a  REM   b

      DEFAULT:
   }

   trnerr("Error in manifest expression")
   RESULTIS 0
}


AND assign(x, y) BE
{  IF x=0 | y=0 DO {  trnerr("Compiler error in assign")
                      RETURN
                   }

   UNLESS (h1!x=s_comma)=(h1!y=s_comma) DO
   {  trnerr("LHS and RHS of different lengths")
      RETURN
   }

   IF h1!x=s_comma DO
   {  preplhs(h2!x)
      load(h2!y)
      assign(h3!x, h3!y)
      doass(h2!x)
      RETURN
   }

   preplhs(x)
   load(y)
   doass(x)
}

AND preplhs(x) BE SWITCHON h1!x INTO
{  DEFAULT:       trnerr("Bad LHS")

   CASE s_vid:    RETURN

   CASE s_indb0:
   CASE s_indb:
   CASE s_indw0:
   CASE s_indw:   loadlv(x)
                  RETURN
}

// In the  following function assop is  s_stw or s_stb
// if the LHS has leading operator ! or %, otherwise it
// is s_vid indicating that the LHS is a variable.

AND doass(x) BE SWITCHON h1!x INTO
{  DEFAULT:       trnerr("Bad LHS")
                  RETURN

   CASE s_vid:    transvid(x, spath, s_sg, s_sl, 0, 0)
                  ssp := ssp-1
                  RETURN

   CASE s_indb0:
   CASE s_indb:   out1(s_stb)
                  ssp := ssp-2
                  RETURN

   CASE s_indw0:
   CASE s_indw:   out1(s_stw)
                  ssp := ssp-2
                  RETURN
}

// In the follow procedure t is the number of the temporary variable
// holding the value of the RHS
AND assignall(i, x, rhs) BE
{  IF x=0 DO {  trnerr("Compiler error in assignall")
                RETURN
             }

   IF h1!x=s_comma DO
   {  preplhs(h2!x)
      assignall(i+1, h3!x, rhs)
      out1(s_lr)
      ssp := ssp+1
      doass(h2!x)
      RETURN
   }
   preplhs(x)
   load(rhs)
   IF i>1 DO { out1(s_str); out1(s_lr) }
   doass(x)

}

// In the following function op is one of the  expression
// operators allowed in assignments, i.e. s_lsh, s_rsh, etc.

AND assignop(op, x, y) BE
{  IF x=0 | y=0 DO {  trnerr("Compiler error in assignop")
                      RETURN
                   }

   UNLESS (h1!x=s_comma)=(h1!y=s_comma) DO
   {  trnerr("LHS and RHS of different lengths")
      RETURN
   }

   IF h1!x=s_comma DO
   {  preplhsop(op, h2!x, h2!y)
      assignop(op, h3!x, h3!y)
      doass(h2!x)
      RETURN
   }
   preplhsop(op, x, y)
   doass(x)
}

AND preplhsop(op, x, y) BE
{  SWITCHON h1!x INTO
   {  CASE s_vid:    transvid(x, lpath, s_lg, s_ll, 0, 0)
                     ssp := ssp+1
                     ENDCASE

      CASE s_indb0:
      CASE s_indb:   loadlv(x)
                     out1(s_dup)
                     ssp := ssp+1
                     out1(s_indb0)
                     ENDCASE

      CASE s_indw0:
      CASE s_indw:   loadlv(x)
                     out1(s_dup)
                     ssp := ssp+1
                     out1(s_indw0)
                     ENDCASE

      DEFAULT:       trnerr("Compiler error in preplhsop %n", h1!x)
   }

   load(y)
   out1(op)
   ssp := ssp-1
}

// transvid may load or store so the caller must update ssp.
AND transvid(id, locproc, g, s, f, x) BE
{  LET name = @h3!id
   LET c = findid(id, loclist)

   UNLESS c=0 DO {  // c -> [link, vid, n, i]
                    locproc(h3!c, h4!c)
                    RETURN
                 }

   c := findid(id, statlist)
   UNLESS c=0 DO {  // c -> [link, vid, lab, -]
                    out2(s, h3!c)
                    RETURN
                 }

   c := findid(id, globlist)
   UNLESS c=0 DO {  // c -> [link, vid, lab, -]
                    out2(g, h3!c)
                    RETURN
                 }

   c := findid(id, funlist)
   UNLESS c=0 DO
   {  // c -> [link, vid, type, lab]
      IF f=0 DO
      {  trnerr("Misuse of FUN name %s", name)
         RETURN
      }
      out2(f, h4!c)
      RETURN
   }

   c := findid(id, extlist)
   UNLESS c=0 DO
   {  // c -> [link, vid, type]
      IF x=0 DO
      {  trnerr("Misuse of EXTERNAL name %s", name)
         RETURN
      }
      out1(s_lx)
      outstring(name)
      RETURN
   }

   trnerr("Name %s not declared", name)
}

AND outglobinits() BE
{  LET p, n = globlist, 0
   // p -> 0
   //   -> [next, vid, gn,   0]  for a global variable
   //   -> [next, vid, gn, lab]  for a global function
   UNTIL p=0 DO {  UNLESS h4!p=0 DO n := n+1
                   p := h1!p
                }
   p := globlist
   out2(s_global, n)
   UNTIL p=0 DO {  UNLESS h4!p=0 DO out2(h3!p, h4!p)
                   p := h1!p
                }
}

AND out1(x) BE {  wrn(x); wrc('*s') }

AND out2(x, y) BE {  out1(x); out1(y) }

AND out3(x, y, z) BE {  out1(x); out1(y); out1(z) }

AND outstring(s) BE FOR i = 0 TO s%0 DO out1(s%i)

AND outline() BE out3(s_line, comline>>24, comline&#xFFFFF)

AND wrn(n) BE
{  IF n<0 DO {  wrc('-'); n := - n
                IF n<0 DO {  LET ndiv10 = (n>>1)/5
                             wrpn(ndiv10)
                             n:=n-ndiv10*10
                          }
             }
   wrpn(n)
}

AND wrpn(n) BE {  IF n>9 DO wrpn(n/10)
                  wrc(n REM 10 + '0')
               }

AND wrc(ch) BE
{  mcount := mcount + 1
   IF mcount>62 & ch='*s' DO mcount, ch := 0, '*n'
   wrch(ch)
}

