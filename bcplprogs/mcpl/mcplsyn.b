//   SYNHDR

GET "libhdr"

MANIFEST {     // Tokens and Parse Tree operators

s_eof=0
s_numb=1
s_vid=2
s_cid=3
s_string=4
s_true=5
s_false=6
s_query=7

s_sbra=10
s_sket=11
s_rbra=12
s_rket=13
s_cbra=14
s_cket=15

s_comma=16
s_semicolon=17
s_colon=18
s_dot=19

s_lv=20
s_neg=21
s_abs=22
s_not=23
s_bitnot=24
s_vec=25
s_cvec=26
s_valof=27
s_table=28
s_ltable=29

s_call=30
s_indw=31
s_indw0=32
s_indb=33
s_indb0=34

s_lsh=35  // same order as op:= operators
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
s_mthap=52

s_and=55
s_or=56

s_cond=58

s_ptr=59
s_dots=60
s_peq=62
s_pne=63
s_ple=64
s_pge=65
s_pls=66
s_pgr=67

s_pass=70

s_plshass=71 // same order as the expression operator
s_prshass=72
s_pmultass=73
s_pdivass=74
s_pmodass=75
s_pandass=76
s_pxorass=77
s_pplusass=78
s_psubass=79
s_porass=80

s_pand=82
s_por=83

s_inc1=85
s_inc4=86
s_dec1=87
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
s_be=102
s_goto=103
s_raise=104
s_handle=105
s_test=106
s_then=107
s_else=108
s_if=109
s_unless=110
s_do=111
s_while=112
s_until=113
s_repeatwhile=114
s_repeatuntil=115
s_repeat=116
s_for=117
s_to=118
s_by=119
s_match=120
s_every=121
s_result=122
s_exit=123
s_return=124
s_break=125
s_loop=126
s_seq=127

s_ass=130

s_lshass=131   // same order as the expression operators
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
s_all=142

s_module=145
s_get=146
s_external=147
s_static=148
s_manifest=149
s_global=150
s_fun=151
s_rarrow=152
s_funpat=153

s_sdef=154
s_mdef=155
s_gdef=156
s_xdef=157

// Other MCODE operator(s)

s_file=158
}

GLOBAL {                     // Globals used in LEX
decval:201; getstreams:202; charv:203
readnumber:212; rdstrch:213
token:215; wordnode:216
rdtag:218; performget:219
lex:220; declsyswords:222; nlpending:223
lookup:225
skiptag:230; wrchbuf:231
rec_p:235; rec_l:236

// GLOBALS USED IN SYN
rcom:246
nametable:248; nametablesize:249
synerr:251; plist:252
rexplist:255; rdseq:256
rdplist:257
mk1:261; mk2:262; mk3:263
mk4:264; mk5:265; mk6:266; mk7:267
newvec:268
rnexp:271; rexp:272; rbexp:274

}


MANIFEST {                          //  Selectors
h1=0; h2=1; h3=2; h4=3; h5=4; h6=5; h7=6
nametablesize=256
charvupb=4095

c_backspace =  8
c_tab       =  9
c_newline   = 10
c_newpage   = 12
c_cr        = 13
c_escape    = 27
c_space     = 32
}


LET findfileno(filename) = VALOF
{  LET len = filename%0
   LET p, i = filelist, 0
   UNTIL p=0 | i>len TEST filename%i=(p+2)%i THEN i := i+1
                                             ELSE p, i := !p, 0
   IF p=0 DO
   {  LET oldout = output()
      p := getvec(3+len/4)
      IF p=0 RESULTIS 0
      h1!p, h2!p := filelist, filelist=0->2, h2!filelist+1
      FOR i = 0 TO len DO (p+2)%i := filename%i
      filelist := p
      selectoutput(mcodeout)
      writef("%n %n ", s_file, h2!p)
      FOR i = 0 TO len DO writef(" %n", filename%i)
      newline()
      selectoutput(oldout)
   }
   RESULTIS h2!p
}

AND findfilename(fno) = VALOF
{  LET p = filelist
   UNTIL p = 0 DO {  IF h2!p=fno RESULTIS @h3!p
                     p := h1!p
                  }
   RESULTIS "Unknown"
}

AND freefilelist(p) BE UNLESS p=0 DO { freefilelist(h1!p)
                                       freevec(p)
                                     }

LET lex() BE
{  decval, nlpending := 0, FALSE

   {  SWITCHON ch INTO

      {  CASE '*p':
         CASE '*n':
               lineno := lineno + 1
               nlpending := TRUE  // IGNORABLE CHARACTERS
         CASE '*t':
         CASE '*s':
               rch() REPEATWHILE ch='*s'
               LOOP

         CASE '0':CASE '1':CASE '2':CASE '3':CASE '4':
         CASE '5':CASE '6':CASE '7':CASE '8':CASE '9':
              token := s_numb
              readnumber(10)
              RETURN

         CASE 'a':CASE 'b':CASE 'c':CASE 'd':CASE 'e':
         CASE 'f':CASE 'g':CASE 'h':CASE 'i':CASE 'j':
         CASE 'k':CASE 'l':CASE 'm':CASE 'n':CASE 'o':
         CASE 'p':CASE 'q':CASE 'r':CASE 's':CASE 't':
         CASE 'u':CASE 'v':CASE 'w':CASE 'x':CASE 'y':
         CASE 'z':
              token := lookup(rdtag(ch), s_vid)
              RETURN

         CASE 'A':CASE 'B':CASE 'C':CASE 'D':CASE 'E':
         CASE 'F':CASE 'G':CASE 'H':CASE 'I':CASE 'J':
         CASE 'K':CASE 'L':CASE 'M':CASE 'N':CASE 'O':
         CASE 'P':CASE 'Q':CASE 'R':CASE 'S':CASE 'T':
         CASE 'U':CASE 'V':CASE 'W':CASE 'X':CASE 'Y':
         CASE 'Z':
              token := lookup(rdtag(ch), s_cid)
              IF token=s_mod | token=s_xor | token=s_all DO
              {  IF ch=':' DO
                 {  rch()
                    IF ch='=' DO
                    {  token := token=s_mod -> s_modass,
                                token=s_xor -> s_xorass,
                                s_allass
                       BREAK
                    }
                    synerr("Bad MOD:=, XOR:= or ALL:=")
                 }
                 IF token=s_all DO synerr("Trouble with ALL")
                 RETURN
              }
              IF token=s_get DO {  performget(); LOOP  }
              RETURN

         CASE '$':
              //  $$tag  sets tag to true if not previously declared
              //         otherwise complements its value
              //  $<tag ... $>tag  includes the enclosed tokens
              //                   if the tag is true
              //                   otherwise skips the enclosed material
              rch()
              IF ch='$' | ch='<' | ch='>' DO
              {  LET k = ch
                 token := lookup(rdtag('<'),0)

                 IF k='>' DO
                 {  IF skiptag=wordnode DO skiptag := 0
                    LOOP
                 }

                 UNLESS skiptag=0 LOOP

                 IF k='$' DO
                 {  h1!wordnode := token=s_true -> s_false, s_true
                    LOOP
                 }

                 // K must be '<'
                 IF token=s_true LOOP
                 skiptag := wordnode
                 UNTIL skiptag=0 DO lex()
                 RETURN
              }

              synerr("Unexpected $")
              RETURN

         CASE '#':
              rch()
              token := s_numb
              IF '0'<=ch<='7' | ch='_'
                                 DO {         readnumber(8);  RETURN  }
              IF ch='b' | ch='B' DO {  rch(); readnumber(2);  RETURN  }
              IF ch='o' | ch='O' DO {  rch(); readnumber(8);  RETURN  }
              IF ch='x' | ch='X' DO {  rch(); readnumber(16); RETURN  }
              token := s_mthap
              RETURN

         CASE '[': token := s_sbra;      BREAK
         CASE ']': token := s_sket;      BREAK
         CASE '(': token := s_rbra;      BREAK
         CASE ')': token := s_rket;      BREAK
         CASE '{': token := s_cbra;      BREAK
         CASE '}': token := s_cket;      BREAK
         CASE '?': token := s_query;     BREAK
         CASE '+': rch()
                   IF ch=':' DO {  rch()
                                   IF ch='=' DO {  token := s_plusass
                                                   BREAK
                                                }
                                   synerr("Bad +:= symbol")
                                }
                   IF ch='+' DO {  rch()
                                   IF ch='+' DO {  token := s_inc4; BREAK }
                                   token := s_inc1
                                   RETURN
                                }
                   token := s_plus
                   RETURN
         CASE ',': token := s_comma;     BREAK
         CASE ';': token := s_semicolon; BREAK
         CASE '@': token := s_lv;        BREAK
         CASE '&': rch()
                   IF ch=':' DO {  rch()
                                   IF ch='=' DO {  token := s_andass
                                                   BREAK
                                                }
                                   synerr("Bad &:= symbol")
                                }
                   token := s_bitand
                   RETURN
         CASE '|': rch()
                   IF ch=':' DO {  rch()
                                   IF ch='=' DO {  token := s_orass
                                                   BREAK
                                                }
                                   synerr("Bad |:= symbol")
                                }
                   token := s_bitor
                   RETURN
         CASE '=': rch()
                   IF ch='>' DO {  token := s_rarrow; BREAK }
                   token := s_eq
                   RETURN
         CASE '!': token := s_indw; BREAK
         CASE '%': token := s_indb; BREAK
         CASE '**':rch()
                   IF ch=':' DO {  rch()
                                   IF ch='=' DO {  token := s_multass
                                                   BREAK
                                                }
                                   synerr("Bad **:= symbol")
                                }
                   token := s_mult
                   RETURN

         CASE '/':
              rch()
              IF ch='/' DO
              {  rch() REPEATUNTIL ch='*n' | ch=endstreamch
                 LOOP
              }

              IF ch='**' DO
              {  LET depth = 1

                 {  rch()
                    IF ch='**' DO
                    {  rch() REPEATWHILE ch='**'
                       IF ch='/' DO {  depth := depth-1; LOOP }
                    }
                    IF ch='/' DO
                    {  rch()
                       IF ch='**' DO {  depth := depth+1; LOOP }
                    }
                    IF ch='*n' DO lineno := lineno+1
                    IF ch=endstreamch DO synerr("Missing '**/'")
                 } REPEATUNTIL depth=0

                 rch()
                 LOOP
              }

              IF ch=':' DO {  rch()
                              IF ch='=' DO {  token := s_divass
                                              BREAK
                                           }
                              synerr("Bad /:= symbol")
                           }
              token := s_div
              RETURN

         CASE '~':
              rch()
              IF ch='=' DO {  token := s_ne;     BREAK }
              token := s_bitnot
              RETURN

         CASE '<': rch()
              IF ch='=' DO {  token := s_le;     BREAK }
              UNLESS ch='<' DO {  token := s_ls; RETURN }
              rch()
              IF ch=':' DO {  rch()
                              IF ch='=' DO {  token := s_lshass
                                              BREAK
                                           }
                              synerr("Bad <<:= symbol")
                           }
              token := s_lsh
              RETURN

         CASE '>': rch()
              IF ch='=' DO {  token := s_ge;     BREAK }
              UNLESS ch='>' DO {  token := s_gr; RETURN }
              rch()
              IF ch=':' DO {  rch()
                              IF ch='=' DO {  token := s_rshass
                                              BREAK
                                           }
                              synerr("Bad >>:= symbol")
                           }
              token := s_rsh
              RETURN

         CASE '-': rch()
              IF ch='>' DO {  token := s_cond; BREAK  }
              IF ch='-' DO {  rch()
                              IF ch='-' DO {  token := s_dec4; BREAK }
                              token := s_dec1
                              RETURN
                           }

              IF ch=':' DO {  rch()
                              IF ch='=' DO {  token := s_subass
                                              BREAK
                                           }
                              synerr("Bad -:= symbol")
                           }
              token := s_sub
              RETURN

         CASE ':': rch()
              IF ch='=' DO {  token := s_ass; BREAK  }
              token := s_colon
              RETURN

         CASE '"':
           {  LET len, strch = 0, ?
              rch()

              UNTIL ch='"' DO
              {  IF len=charvupb DO synerr("String too long")
                 strch := rdstrch()
                 IF strch>=0 DO {  len := len + 1
                                   charv%len := strch
                                }
              }

              charv%0 := len
              wordnode := newvec(len/bytesperword+3)
              h1!wordnode := s_string
              h2!wordnode := len-1
              FOR i = 0 TO len-1 DO (@h3!wordnode)%i := charv%(i+1)
              token := s_string
              BREAK
           }

         CASE '*'':
            {  LET i, strch = 0, ?
               decval := 0
               rch()
               {  IF ch='*'' | i=4 BREAK
                  strch := rdstrch()
                  IF strch>=0 DO decval, i := decval<<8 | strch, i+1
               } REPEAT
               token := s_numb
               UNLESS ch='*'' DO synerr("Bad character constant")
               BREAK
            }

         DEFAULT:
              UNLESS ch=endstreamch | ch='.' DO
              {  LET badch = ch
                 ch := '*s'
                 synerr("Illegal character %x2", badch)
              }

         CASE '.':
              IF ch='.' DO
              {  rch()
                 IF ch='.' DO {  token := s_dots; BREAK }
                 token := s_dot
                 RETURN
              }

              IF getstreams=0 DO {  token := s_eof
                                    RETURN
                                 }
              endread()
              ch           := h4!getstreams
              lineno       := h3!getstreams
              sourcestream := h2!getstreams
              getstreams   := h1!getstreams
              selectinput(sourcestream)
              LOOP
      }
   } REPEAT

   rch()
}


LET lookup(word, token) = VALOF
{  LET len, i = word%0, 0
   LET hashval = 19609 // This and 31397 are primes.
   FOR i = 0 TO len DO hashval := (hashval NEQV word%i) * 31397
   hashval := (hashval>>1) REM nametablesize

   wordnode := nametable!hashval

   UNTIL wordnode=0 | i>len TEST (@h3!wordnode)%i=word%i
                            THEN i := i+1
                            ELSE wordnode, i := h2!wordnode, 0

   IF wordnode=0 DO
   {  wordnode := newvec(len/bytesperword+3)
      h1!wordnode, h2!wordnode := token, nametable!hashval
      FOR i = 0 TO len DO (@h3!wordnode)%i := word%i
      nametable!hashval := wordnode
   }

   RESULTIS h1!wordnode
}

AND declsyswords() BE
{  lookup("AND", s_and)
   lookup("ABS", s_abs)
   lookup("ALL", s_all)
   lookup("BE", s_be)
   lookup("BREAK", s_break)
   lookup("BY", s_by)
   lookup("DO", s_do)
   lookup("ELSE", s_else)
   lookup("EVERY", s_every)
   lookup("EXIT", s_exit)
   lookup("EXTERNAL", s_external)
   lookup("FALSE", s_false)
   lookup("FOR", s_for)
   lookup("FUN", s_fun)
   lookup("GET", s_get)
   lookup("GLOBAL", s_global)
   lookup("GOTO", s_goto)
   lookup("HANDLE", s_handle)
   lookup("IF", s_if)
   lookup("LET", s_let)
   lookup("LOOP", s_loop)
   lookup("MANIFEST", s_manifest)
   lookup("MATCH", s_match)
   lookup("MOD", s_mod)
   lookup("NOT", s_not)
   lookup("OR", s_or)
   lookup("RAISE", s_raise)
   lookup("REPEAT", s_repeat)
   lookup("REPEATUNTIL", s_repeatuntil)
   lookup("REPEATWHILE", s_repeatwhile)
   lookup("RESULT", s_result)
   lookup("RETURN", s_return)
   lookup("MODULE", s_module)
   lookup("STATIC", s_static)
   lookup("TABLE", s_table)
   lookup("TEST", s_test)
   lookup("THEN", s_do)
   lookup("TO", s_to)
   lookup("TRUE", s_true)
   lookup("UNLESS", s_unless)
   lookup("UNTIL", s_until)
   lookup("VALOF", s_valof)
   lookup("VEC", s_vec)
   lookup("CVEC", s_cvec)
   lookup("WHILE", s_while)
   lookup("XOR", s_xor)
}

LET rch() BE
{  ch := rdch()
   chcount := chcount + 1
   chbuf%(chcount&63) := ch
}

AND wrchbuf() BE
{  newline()
   IF chcount>64 DO writes("...")
   FOR p = chcount-63 TO chcount DO
   {  LET k = chbuf%(p&63)
      IF 0<k<255 DO wrch(k)
   }
   newline()
}

AND rdtag(ch1) = VALOF
{  LET upb = 1

   charv%1 := ch1

   {  rch()
      UNLESS 'a'<=ch<='z' | 'A'<=ch<='Z' |
             '0'<=ch<='9' | ch='_' | ch='*'' BREAK
      upb := upb+1
      charv%upb := ch
   } REPEAT

   charv%0 := upb
   RESULTIS charv
}

AND performget() BE
{  LET stream = ?
   lex()
   UNLESS token=s_string DO synerr("Bad GET directive")
   stream := findinput(charv)
   TEST stream=0
   THEN synerr("GET file %s unreadable", charv)
   ELSE {  getstreams := mk4(getstreams, sourcestream, lineno, ch)
           sourcestream := stream
           selectinput(sourcestream)
           lineno := findfileno(charv)<<24 | 1
           rch()
        }
}

AND readnumber(radix) BE
{  LET d = 0
   WHILE ch='_' DO rch()
   d := value(ch)
   decval := d
   IF d>=radix DO synerr("Bad number")

   {  rch() REPEATWHILE ch='_'
      d := value(ch)
      IF d>=radix RETURN
      decval := radix*decval + d
   } REPEAT
}

AND value(ch) = '0'<=ch<='9' -> ch-'0',
                'A'<=ch<='F' -> ch-'A'+10,
                'a'<=ch<='f' -> ch-'a'+10,
                100

AND rdstrch() = VALOF
{  LET k = ch

   IF k='*n' | k='*p' DO
   {  lineno := lineno+1
      synerr("Unescaped newline character")
   }

   IF k='\' DO
   {  rch()
      k := capitalch(ch)
      SWITCHON k INTO
      {  CASE '*n':
         CASE '*p':
         CASE '*s':
         CASE '*t': WHILE ch='*n' | ch='*p' | ch='*s' | ch='*t' DO
                    {  IF ch='*n' | ch='*p' DO lineno := lineno+1
                       rch()
                    }
                    IF ch='\' DO {  rch(); RESULTIS -1 }

         DEFAULT:   synerr("Bad string or character constant")

         CASE '\':
         CASE '*'':
         CASE '"':                    ENDCASE

         CASE 'T':  k := c_tab;       ENDCASE
         CASE 'S':  k := c_space;     ENDCASE
         CASE 'N':  k := c_newline;   ENDCASE
         CASE 'B':  k := c_backspace; ENDCASE
         CASE 'C':
         CASE 'R':  k := c_cr;        ENDCASE
         CASE 'P':
         CASE 'F':  k := c_newpage;   ENDCASE
         CASE 'E':  k := c_escape;    ENDCASE

         CASE '^':  rch()
                    k := 1 + capitalch(ch) - 'A'
                    ENDCASE

         CASE '0':CASE '1':CASE '2':CASE '3':CASE '4':
         CASE '5':CASE '6':CASE '7':CASE '8':CASE '9':
                    k := 0
                    WHILE '0'<=ch<='9' DO
                    {  k := 10*k + ch - '0'
                       rch()
                    }
                    IF k>255 DO
                       synerr("Bad string or character constant")
                    RESULTIS k
      }
   }

   rch()
   RESULTIS k
}


LET newvec(n) = VALOF
{  treep := treep - n - 1
   IF treep<=treevec DO
   {  errmax := 0  // Make it fatal
      synerr("More workspace needed")
   }
   RESULTIS treep
}

AND mk1(x) = VALOF
{  LET p = newvec(0)
   p!0 := x
   RESULTIS p
}

AND mk2(x, y) = VALOF
{  LET p = newvec(1)
   p!0, p!1 := x, y
   RESULTIS p
}

AND mk3(x, y, z) = VALOF
{  LET p = newvec(2)
   p!0, p!1, p!2 := x, y, z
   RESULTIS p
}

AND mk4(x, y, z, t) = VALOF
{  LET p = newvec(3)
   p!0, p!1, p!2, p!3 := x, y, z, t
   RESULTIS p
}

AND mk5(x, y, z, t, u) = VALOF
{  LET p = newvec(4)
   p!0, p!1, p!2, p!3, p!4 := x, y, z, t, u
   RESULTIS p
}

AND mk6(x, y, z, t, u, v) = VALOF
{  LET p = newvec(5)
   p!0, p!1, p!2, p!3, p!4, p!5 := x, y, z, t, u, v
   RESULTIS p
}

AND mk7(x, y, z, t, u, v, w) = VALOF
{  LET p = newvec(6)
   p!0, p!1, p!2, p!3, p!4, p!5, p!6 := x, y, z, t, u, v, w
   RESULTIS p
}

AND formtree() =  VALOF
{  rec_p, rec_l := level(), rec

   getstreams := 0
   charv      := newvec((charvupb+1)/bytesperword)
   nametable  := newvec(nametablesize)
   FOR i = 0 TO nametablesize DO nametable!i := 0
   skiptag, decval := 0, 0
   declsyswords()

   lex()

   IF token=s_query DO            // For debugging lex.
   {  lex()
      IF token=s_eof RESULTIS 0
      writef("token = %i3   ", token)
      IF token=s_numb DO writef("%n", decval)
      IF token=s_vid | token=s_cid | token=s_string | 100<=token<130 DO
         writef("%s", charv)
      newline()
   } REPEAT

rec:
   RESULTIS rdprog()
}

AND synerr(mess, a) BE
{  errcount := errcount + 1
   writef("*nError in %s line %n:  ",
          findfilename(lineno>>24), lineno & #xFFFFF)
   writef(mess, a)
   wrchbuf()
   IF errcount > errmax DO
   {  writes("*nCompilation aborted*n")
      longjump(fin_p, fin_l)
   }
   nlpending := FALSE

   UNTIL ch='*n' | ch='*p' | ch=endstreamch DO rch()

   UNTIL token=s_manifest | token=s_global | token=s_static |
         token=s_external | token=s_fun | token=s_eof
         DO lex()

   longjump(rec_p, rec_l)
}

AND rdprog() = VALOF
{  LET a, b, ln = 0, 0, lineno
   LET res, moduleln, modulename = 0, ln, 0
   LET ptr = @res
   LET recp, recl = rec_p, rec_l
   rec_p, rec_l := level(), recover

   IF token=s_module DO
   {  lex()
      UNLESS token=s_vid DO synerr("Bad MODULE directive")
      modulename := wordnode
      lex()
   }

recover:
   UNTIL token=s_eof DO
   {  ln := lineno
      SWITCHON token INTO
      {  DEFAULT:  synerr("Bad outer level declaration")

         CASE s_manifest:
              lex()
              a := mk4(s_manifest, rdmlist(), 0, ln)
              !ptr := a
              ptr := @ h3!a
              LOOP
         CASE s_global:
              lex()
              a := mk4(s_global, rdglist(), 0, ln)
              !ptr := a
              ptr := @ h3!a
              LOOP
         CASE s_static:
              lex()
              a := mk4(s_static, rdslist(), 0, ln)
              !ptr := a
              ptr := @ h3!a
              LOOP
         CASE s_external:
              lex()
              a := mk4(s_external, rdxlist(), 0, ln)
              !ptr := a
              ptr := @ h3!a
              LOOP
         CASE s_fun:
              lex()
              a := rdvid()
              a := mk6(s_fun, a, rdfundef(), 0, 0, ln)
              !ptr := a
              ptr := @ h4!a
              LOOP
      }
   }

   UNLESS modulename=0 DO
       res := mk4(s_module, modulename, res, moduleln)

   rec_p, rec_l := recp, recl
   RESULTIS res
}

AND rdmlist() = VALOF
{  LET res = 0
   LET ptr = @res

   {  LET a, b = rdcid(), 0
      IF token=s_eq DO b := rnexp(0)
      a := mk4(s_mdef, a, b, 0)
      !ptr :=a
      ptr := @h4!a
      UNLESS token=s_comma BREAK
      lex()
   } REPEAT

   RESULTIS res
}

AND rdglist() = VALOF
{  LET res = 0
   LET ptr = @res

   {  LET a, b = rdvid(), 0
      IF token=s_colon DO b := rnexp(0)
      a := mk4(s_gdef, a, b, 0)
      !ptr :=a
      ptr := @h4!a
      UNLESS token=s_comma BREAK
      lex()
   } REPEAT

   RESULTIS res
}

AND rdslist() = VALOF
{  LET res = 0
   LET ptr = @res

   {  LET a, b = rdvid(), 0
      IF token=s_eq DO b := rnexp(0)
      a := mk4(s_sdef, a, b, 0)
      !ptr :=a
      ptr := @h4!a
      UNLESS token=s_comma BREAK
      lex()
   } REPEAT

   RESULTIS res
}

AND rdxlist() = VALOF
{  LET res = 0
   LET ptr = @res

   {  LET a, b = rdvid(), 0
      IF token=s_div DO {  lex(); b := rdvid() }
      a := mk4(s_xdef, a, b, 0)
      !ptr :=a
      ptr := @h4!a
      UNLESS token=s_comma BREAK
      lex()
   } REPEAT

   RESULTIS res
}

AND rdfundef() = VALOF
{  LET res, a, b, ln = 0, 0, 0, 0
   LET ptr = @res

   UNLESS token=s_colon DO synerr("':' expected")

   WHILE token=s_colon DO
   {  lex()
      a := rdplist(0)
      UNLESS token=s_rarrow DO synerr("'=>' expected")
      ln := lineno
      lex()
      b := rdseq()
      a := mk5(s_funpat, a, b, 0, ln)
      !ptr :=a
      ptr := @h4!a
   }

   ignoredot()

   RESULTIS res
}

AND ignoredot() BE SWITCHON token INTO
{ DEFAULT:  synerr("'.' expected")

  CASE s_dot: lex(); RETURN

  CASE s_fun:
  CASE s_manifest:
  CASE s_static:
  CASE s_global:
  CASE s_external:
  CASE s_cket:
  CASE s_eof:        RETURN
} 

AND ignoredo() BE SWITCHON token INTO
{ DEFAULT:  synerr("'DO' expected")

  CASE s_do: lex(); RETURN

  CASE s_every:
  CASE s_match:
  CASE s_raise:
  CASE s_goto:
  CASE s_result:
  CASE s_return:
  CASE s_exit:
  CASE s_if:
  CASE s_unless:
  CASE s_while:
  CASE s_until:
  CASE s_test:
  CASE s_for:
  CASE s_loop:
  CASE s_break: RETURN
} 

// rdseq read a Clist. These only occur after => or {.
// Clist -> C ; C ;...; C
// but C can be empty and ';' can be omitted if at the end of a line.

AND rdseq() = VALOF
{  LET a, b = rcom(), ?
   TEST token=s_semicolon
   THEN lex()
   ELSE TEST nlpending
        THEN nlpending := FALSE
        ELSE RESULTIS a
   // Only read more of the sequence
   // if there was a semicolon or a newline
   b := rdseq()
   IF a=0 RESULTIS b
   IF b=0 RESULTIS a
   RESULTIS mk3(s_seq, a, b) // operands of seq always non zero
}

AND rdvidlist() = VALOF
{  LET a = rdvid()
   UNLESS token=s_comma RESULTIS a
   lex()
   RESULTIS mk3(s_comma, a, rdvidlist())
}

AND rdvid() = VALOF
{  LET a = wordnode
   UNLESS token=s_vid DO synerr("Variable name expected")
   lex()
   RESULTIS a
}

AND rdcid() = VALOF
{  LET a = wordnode
   UNLESS token=s_cid DO synerr("Constant name expected")
   lex()
   RESULTIS a
}

LET rbexp() = VALOF
{  LET a, b, op = 0, 0, token

   SWITCHON token INTO

   {  DEFAULT:       RESULTIS 0

      CASE s_true:
      CASE s_false:
      CASE s_query:  lex()
                     RESULTIS mk1(op)
      CASE s_vid:
      CASE s_cid:
      CASE s_string: a := wordnode
                     lex()
                     RESULTIS a

      CASE s_numb:   a := mk2(s_numb, decval)
                     lex()
                     RESULTIS a

      CASE s_rbra:   a := rnexp(0)
                     UNLESS token=s_rket DO synerr("Missing ')'")
                     lex()
                     RESULTIS a

      CASE s_sbra:   lex()
                     a := mk3(s_ltable, rexplist(), 0)
                     UNLESS token=s_sket DO synerr("Missing ']'")
                     lex()
                     RESULTIS a

      CASE s_vec:
      CASE s_cvec:   RESULTIS mk3(op, rnexp(14), 0)

      CASE s_inc1:   RESULTIS mk2(s_inc1b, rnexp(12))
      CASE s_inc4:   RESULTIS mk2(s_inc4b, rnexp(12))
      CASE s_dec1:   RESULTIS mk2(s_dec1b, rnexp(12))
      CASE s_dec4:   RESULTIS mk2(s_dec4b, rnexp(12))

      CASE s_plus:   RESULTIS rnexp(10)  // prefixed

      CASE s_sub:    a := rnexp(10)      // prefixed
                     TEST h1!a=s_numb THEN h2!a := - h2!a
                                      ELSE a := mk2(s_neg, a)
                     RESULTIS a

      CASE s_abs:    RESULTIS mk2(s_abs, rnexp(10))
      CASE s_bitnot: RESULTIS mk2(s_bitnot, rnexp(10))

      CASE s_indb:   RESULTIS mk2(s_indb0, rnexp(10))
      CASE s_indw:   RESULTIS mk2(s_indw0, rnexp(10))
      CASE s_lv:     RESULTIS mk2(op, rnexp(10))

      CASE s_not:    RESULTIS mk2(s_not, rnexp(4))

      CASE s_table:  lex()
                     UNLESS token=s_sbra DO
                         synerr("Bad TABLE [ .. ]")
                     a := rbexp()
                     UNLESS a=0 DO h1!a := s_table
                     RESULTIS a

      CASE s_valof:  lex()
                     RESULTIS mk2(s_valof, rcom())

      CASE s_every:
      CASE s_match:
                 {  LET ln = lineno
                    lex()
                    a := rdalist()
                    RESULTIS mk4(op, a, rdfundef(), ln)
                 }
   }
}

AND rnexp(n) = VALOF
{  LET a = ?
   lex()
   a := rexp(n)
   IF a=0 DO synerr("Error in expression")
   RESULTIS a
}

AND rexp(n) = VALOF
{  LET a, b, p = rbexp(), 0, 0

   IF a=0 RESULTIS 0

   {  LET op = token

      SWITCHON op INTO

      {  DEFAULT:       RESULTIS a

         CASE s_rbra:CASE s_sbra:
         CASE s_vid:CASE s_cid:CASE s_query:CASE s_numb:
         CASE s_string:CASE s_true:CASE s_false:
                     {  LET args, ln = 0, lineno
                        IF nlpending RESULTIS a
                        args := op=s_rbra->rdalist(),rbexp()
                        a := mk4(s_call, a, args, ln)
                        LOOP
                     }

         CASE s_mthap:{  LET args, ln, e1 = 0, lineno, 0
                         IF nlpending RESULTIS a
                         lex()
                         UNLESS token=s_rbra   | token=s_sbra |
                                token=s_vid    | token=s_cid  |
                                token=s_query  | token=s_numb |
                                token=s_string | token=s_true |
                                token=s_false DO synerr("Bad argument")
                         args := token=s_rbra->rdalist(),rbexp()
                         IF args=0 DO synerr("argument expression missing")
                         TEST h1!args=s_comma
                         THEN e1 := h2!args
                         ELSE e1 := args
                         a := mk3(s_indw, mk2(s_indw0, e1), a)
                         a := mk4(s_call, a, args, ln)
                         LOOP
                      }

         CASE s_inc1:   IF nlpending RESULTIS a
                        a := mk2(s_inc1a, a); lex(); LOOP
         CASE s_inc4:   IF nlpending RESULTIS a
                        a := mk2(s_inc4a, a); lex(); LOOP
         CASE s_dec1:   IF nlpending RESULTIS a
                        a := mk2(s_dec1a, a); lex(); LOOP
         CASE s_dec4:   IF nlpending RESULTIS a
                        a := mk2(s_dec4a, a); lex(); LOOP

         CASE s_indb:
         CASE s_indw:   IF nlpending RESULTIS a
                        p := 11; ENDCASE

         CASE s_lsh:
         CASE s_rsh:    IF n>=9 RESULTIS a
                        a := mk3(op, a, rnexp(9))
                        LOOP


         CASE s_bitand:
         CASE s_mult:
         CASE s_div:
         CASE s_mod:    p := 8; ENDCASE

         CASE s_xor:    p := 7; ENDCASE

         CASE s_bitor:  p := 6; ENDCASE

         CASE s_plus:
         CASE s_sub:    IF nlpending RESULTIS a
                        p := 6; ENDCASE

         CASE s_eq:CASE s_le:CASE s_ls:
         CASE s_ne:CASE s_ge:CASE s_gr:
                        IF n>=5 RESULTIS a
                        a := mk3(s_rel, a, 0)
                        b := a
                        WHILE  s_eq<=token<=s_gr DO
                        {  LET c = b
                           op := token
                           b := mk3(op, rnexp(5), 0)
                           h3!c := b
                        }
                        LOOP

         CASE s_and:    p := 3; ENDCASE
         CASE s_or:     p := 2; ENDCASE

         CASE s_cond:   IF n>=1 RESULTIS a
                        b := rnexp(0)
                        UNLESS token=s_comma DO
                               synerr("Bad conditional expression")
                        a := mk4(s_cond, a, b, rnexp(0))
                        LOOP
      }

      IF n>=p RESULTIS a
      a := mk3(op, a, rnexp(p))
   } REPEAT

   RESULTIS a
}

AND rexplist() = VALOF
{  LET res, a = 0, rexp(0)
   LET ptr = @res

   IF a=0 DO synerr("Bad epression list")

   WHILE token=s_comma DO {  !ptr := mk3(s_comma, a, 0)
                             ptr := @h3!(!ptr)
                             a := rnexp(0)
                          }
   !ptr := a
   RESULTIS res
}

AND rdalist() = VALOF
{  LET a = 0

   UNLESS token=s_rbra RESULTIS rexp(0)

   lex()
   UNLESS token=s_rket DO a := rexplist()
   UNLESS token=s_rket DO synerr("Missing ')'")
   lex()
   RESULTIS a
}

AND rdplist() = VALOF
{  LET a = rdp()
   UNLESS token=s_comma RESULTIS a
   lex()
   RESULTIS mk3(s_comma, a, rdplist())
}


AND rdp() = VALOF
{  LET a = rdbp()
   IF a=0 RESULTIS 0
   {  LET b = rdbp()
      IF b=0 RESULTIS a
      a := mk3(s_pand, a, b)
   } REPEAT
}

AND rdbp() = VALOF SWITCHON token INTO
   {  DEFAULT:  RESULTIS 0

      CASE s_cid:CASE s_numb:
      CASE s_true:CASE s_false:
      CASE s_sub: CASE s_plus:
                  {  LET a = rbexp()
                     IF token=s_dots DO
                     {  lex()
                        UNLESS token=s_cid | token=s_numb |
                               token=s_true | token=s_false |
                               token=s_sub | token=s_plus DO
                            synerr("Bad pattern")
                        a := mk3(s_dots, a, rbexp())
                     }
                     UNLESS token=s_bitor RESULTIS a
                     lex()
                     UNLESS token=s_cid | token=s_numb |
                            token=s_true | token=s_false |
                            token=s_sub | token=s_plus DO
                        synerr("Bad pattern")
                     RESULTIS mk3(s_por, a, rdbp())
                  }

      CASE s_vid:
      CASE s_query:   RESULTIS rbexp()

      CASE s_rbra: {  LET a = ?
                      lex()
                      a := rdp()
                      UNLESS token=s_rket DO synerr("Bad pattern")
                      lex()
                      RESULTIS a
                   }
      CASE s_sbra: {  LET a = ?
                      lex()
                      a := rdplist()
                      UNLESS token=s_sket DO synerr("Bad pattern")
                      lex()
                      RESULTIS mk2(s_ptr, a)
                   }

      CASE s_eq:      RESULTIS mk2(s_peq, rnexp(0))
      CASE s_ne:      RESULTIS mk2(s_pne, rnexp(0))
      CASE s_le:      RESULTIS mk2(s_ple, rnexp(0))
      CASE s_ge:      RESULTIS mk2(s_pge, rnexp(0))
      CASE s_ls:      RESULTIS mk2(s_pls, rnexp(0))
      CASE s_gr:      RESULTIS mk2(s_pgr, rnexp(0))

      CASE s_ass:     RESULTIS mk2(s_pass, rnexp(0))

      CASE s_lshass:  RESULTIS mk2(s_plshass,  rnexp(0))
      CASE s_rshass:  RESULTIS mk2(s_prshass,  rnexp(0))
      CASE s_multass: RESULTIS mk2(s_pmultass, rnexp(0))
      CASE s_divass:  RESULTIS mk2(s_pdivass,  rnexp(0))
      CASE s_modass:  RESULTIS mk2(s_pmodass,  rnexp(0))
      CASE s_andass:  RESULTIS mk2(s_pandass,  rnexp(0))
      CASE s_xorass:  RESULTIS mk2(s_pxorass,  rnexp(0))
      CASE s_plusass: RESULTIS mk2(s_pplusass, rnexp(0))
      CASE s_subass:  RESULTIS mk2(s_psubass,  rnexp(0))
      CASE s_orass:   RESULTIS mk2(s_porass,   rnexp(0))
}

LET rbcom() = VALOF
{  LET a, b, op, ln = 0, 0, token, lineno

   SWITCHON token INTO
   {  DEFAULT: RESULTIS 0

      // All tokens that can start an expression.
      CASE s_vid:CASE s_cid:CASE s_numb:CASE s_string:
      CASE s_rbra:CASE s_sbra:
      CASE s_true:CASE s_false:
      CASE s_inc1:CASE s_inc4:
      CASE s_dec1:CASE s_dec4:
      CASE s_lv:CASE s_abs:CASE s_bitnot:CASE s_not:
      CASE s_vec:CASE s_cvec:CASE s_table:CASE s_valof:
      CASE s_indb:CASE s_indw:
      CASE s_plus:CASE s_sub:
      CASE s_query:
      CASE s_every:CASE s_match:

            a := rexplist()

            IF token=s_ass | token=s_lshass | token=s_rshass |
               token=s_multass | token=s_divass | token=s_modass |
               token=s_andass | token=s_xorass |
               token=s_plusass | token=s_subass | token=s_orass DO
            {  op := token
               lex()
               RESULTIS mk4(op, a, rexplist(), ln)
            }

            IF token=s_allass DO
               RESULTIS mk4(s_allass, a, rnexp(0), ln)

            IF h1!a=s_comma DO synerr("Bad command")
            RESULTIS a

      CASE s_cbra: {  LET a = ?
                      lex()
                      a := rdseq()
                      UNLESS token=s_cket DO synerr("Missing '}'")
                      lex()
                      RESULTIS mk2(s_scope, a)
                   }


      CASE s_let:  lex()
                   RESULTIS mk3(s_let, rdslist(), ln)

      CASE s_raise:
      CASE s_goto:
            lex()
            RESULTIS mk3(op, rdalist(), ln)

      CASE s_result:
      CASE s_return:
      CASE s_exit:
            lex()
            RESULTIS mk3(op,(nlpending->0, rexp(0)), ln)

      CASE s_if:
      CASE s_unless:
      CASE s_while:
      CASE s_until:
            a := rnexp(0)
            ignoredo()
            RESULTIS mk4(op, a, rcom(), ln)

      CASE s_test:
            a := rnexp(0)
            ignoredo()
            b := rcom()
            UNLESS token=s_else DO synerr("ELSE missing")
            lex()
            RESULTIS mk5(s_test, a, b, rcom(), ln)

      CASE s_for:
         {  LET i, j, k = 0, 0, 0
            lex()
            a := rdvid()
            UNLESS token=s_eq DO synerr("Missing '='")
            i := rnexp(0)
            UNLESS token=s_to DO synerr("TO missing")
            j := rnexp(0)
            IF token=s_by DO k := rnexp(0)
            ignoredo()
            RESULTIS mk7(s_for, a, i, j, k, rcom(), ln)
         }

      CASE s_loop:
      CASE s_break:
            lex()
            RESULTIS mk2(op, ln)

   }
}

AND rcom() = VALOF
{  LET a = rbcom()

   IF a=0 RESULTIS 0

   WHILE token=s_handle | token=s_repeat |
         token=s_repeatwhile | token=s_repeatuntil DO
   {  LET op, ln = token, lineno
      IF op=s_handle DO {  lex()
                           a := mk4(op, a, rdfundef(), ln)
                           LOOP
                        }
      IF op=s_repeat DO {  a := mk3(op, a, ln)
                           lex()
                           LOOP
                        }
      a := mk4(op, a, rnexp(0), ln)
   }

   RESULTIS a
}

LET plist2(x) BE
{  writef("*nName table contents, size = %n*n", nametablesize)
   FOR i = 0 TO nametablesize-1 DO
   {  LET p, n = nametable!i, 0
      UNTIL p=0 DO p, n := p!1, n+1
      writef("%i3:%n", i, n)
      p := nametable!i
      UNTIL p=0 DO {  writef(" %s", p+2); p := p!1  }
      newline()
   }
}


LET plist(x, n, d) BE UNTIL x=0 SWITCHON h1!x INTO
{  DEFAULT:   RETURN

   CASE s_module:
   CASE s_manifest:
   CASE s_global:
   CASE s_static:
   CASE s_external: newline()
                    plist1(x, 0, 20)
                    x := h3!x
                    LOOP

   CASE s_fun:      newline()
                    plist1(x, 0, 20)
                    x := h4!x
                    LOOP

}

AND plist1(x, n, d) BE
{  LET opstr, size, ln = 0, 0, 0
   LET v = TABLE 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

   IF x=0 DO {  writes("Nil"); RETURN  }

   SWITCHON h1!x INTO
   {  CASE s_numb:     writen(h2!x);      RETURN

      CASE s_vid:
      CASE s_cid:      writef("%s", x+2); RETURN

      CASE s_string:
             {  LET len = h2!x
                AND s = x+2
                wrch('"')
                FOR i = 0 TO len DO wrch(s%i)
                wrch('"')
                RETURN
             }

// Expressions
      CASE s_true:   opstr, size := "TRUE", 0; ENDCASE
      CASE s_false:  opstr, size := "FALSE", 0; ENDCASE
      CASE s_query:  opstr, size := "QUERY", 0; ENDCASE
      CASE s_valof:  opstr, size := "VALOF", 1; ENDCASE
      CASE s_lv:     opstr, size := "LV", 1; ENDCASE
      CASE s_inc1b:  opstr, size := "INC1B", 1; ENDCASE
      CASE s_inc4b:  opstr, size := "INC4B", 1; ENDCASE
      CASE s_dec1b:  opstr, size := "DEC1B", 1; ENDCASE
      CASE s_dec4b:  opstr, size := "DEC4B", 1; ENDCASE
      CASE s_neg:    opstr, size := "NEG", 1; ENDCASE
      CASE s_ltable: opstr, size := "LTABLE", 1; ENDCASE
      CASE s_table:  opstr, size := "TABLE", 1; ENDCASE
      CASE s_vec:    opstr, size := "VEC", 1; ENDCASE
      CASE s_cvec:   opstr, size := "CVEC", 1; ENDCASE
      CASE s_not:    opstr, size := "NOT", 1; ENDCASE
      CASE s_bitnot: opstr, size := "BITNOT", 1; ENDCASE
      CASE s_abs:    opstr, size := "ABS", 1; ENDCASE
      CASE s_call:   opstr, size, ln := "CALL", 2, h4!x; ENDCASE
      CASE s_indb:   opstr, size := "INDB", 2; ENDCASE
      CASE s_indb0:  opstr, size := "INDB0", 1; ENDCASE
      CASE s_indw:   opstr, size := "INDW", 2; ENDCASE
      CASE s_indw0:  opstr, size := "INDW0", 1; ENDCASE
      CASE s_inc1a:  opstr, size := "INC1A", 1; ENDCASE
      CASE s_inc4a:  opstr, size := "INC4A", 1; ENDCASE
      CASE s_dec1a:  opstr, size := "DEC1A", 1; ENDCASE
      CASE s_dec4a:  opstr, size := "DEC4A", 1; ENDCASE
      CASE s_mod:    opstr, size := "MOD", 2; ENDCASE
      CASE s_mult:   opstr, size := "MULT", 2; ENDCASE
      CASE s_div:    opstr, size := "DIV", 2; ENDCASE
      CASE s_plus:   opstr, size := "PLUS", 2; ENDCASE
      CASE s_sub:    opstr, size := "SUB", 2; ENDCASE
      CASE s_eq:     opstr, size := "EQ", 2; ENDCASE
      CASE s_ne:     opstr, size := "NE", 2; ENDCASE
      CASE s_le:     opstr, size := "LE", 2; ENDCASE
      CASE s_ge:     opstr, size := "GE", 2; ENDCASE
      CASE s_ls:     opstr, size := "LS", 2; ENDCASE
      CASE s_gr:     opstr, size := "GR", 2; ENDCASE
      CASE s_rel:    opstr, size := "REL", 2; ENDCASE
      CASE s_lsh:    opstr, size := "LSH", 2; ENDCASE
      CASE s_rsh:    opstr, size := "RSH", 2; ENDCASE
      CASE s_bitand: opstr, size := "BITAND", 2; ENDCASE
      CASE s_bitor:  opstr, size := "BITOR", 2; ENDCASE
      CASE s_xor:    opstr, size := "XOR", 2; ENDCASE
      CASE s_or:     opstr, size := "OR", 2; ENDCASE
      CASE s_and:    opstr, size := "AND", 2; ENDCASE
      CASE s_cond:   opstr, size := "COND", 3; ENDCASE
      CASE s_comma:  opstr, size := "COMMA", 2; ENDCASE

// Patterns
      CASE s_dots:     opstr, size := "DOTS", 2; ENDCASE
      CASE s_ptr:      opstr, size := "PTR", 1; ENDCASE
      CASE s_peq:      opstr, size := "PEQ", 1; ENDCASE
      CASE s_pne:      opstr, size := "PNE", 1; ENDCASE
      CASE s_ple:      opstr, size := "PLE", 1; ENDCASE
      CASE s_pge:      opstr, size := "PGE", 1; ENDCASE
      CASE s_pls:      opstr, size := "PLS", 1; ENDCASE
      CASE s_pgr:      opstr, size := "PGR", 1; ENDCASE
      CASE s_pass:     opstr, size := "PASS", 1; ENDCASE
      CASE s_plshass:  opstr, size := "PLSHASS", 1; ENDCASE
      CASE s_prshass:  opstr, size := "PRSHASS", 1; ENDCASE
      CASE s_pmultass: opstr, size := "PMULTASS", 1; ENDCASE
      CASE s_pdivass:  opstr, size := "PDIVASS", 1; ENDCASE
      CASE s_pmodass:  opstr, size := "PMODASS", 1; ENDCASE
      CASE s_pandass:  opstr, size := "PANDASS", 1; ENDCASE
      CASE s_pxorass:  opstr, size := "PXORASS", 1; ENDCASE
      CASE s_pplusass: opstr, size := "PPLUSASS", 1; ENDCASE
      CASE s_psubass:  opstr, size := "PSUBASS", 1; ENDCASE
      CASE s_porass:   opstr, size := "PORASS", 1; ENDCASE
      CASE s_pand:     opstr, size := "PAND", 2; ENDCASE
      CASE s_por:      opstr, size := "POR", 2; ENDCASE

// Commands
      CASE s_seq:    opstr, size     := "SEQ", 2; ENDCASE
      CASE s_scope:  opstr, size     := "SCOPE", 1; ENDCASE
      CASE s_repeat: opstr, size, ln := "REPEAT", 1, h3!x; ENDCASE
      CASE s_repeatuntil:
                     opstr, size, ln := "REPEATUNTIL", 2, h4!x; ENDCASE
      CASE s_repeatwhile:
                     opstr, size, ln := "REPEATWHILE", 2, h4!x; ENDCASE
      CASE s_handle: opstr, size, ln := "HANDLE", 2, h4!x; ENDCASE
      CASE s_let:    opstr, size, ln := "LET", 1, h3!x; ENDCASE
      CASE s_raise:  opstr, size, ln := "RAISE", 1, h3!x; ENDCASE
      CASE s_goto:   opstr, size, ln := "GOTO", 1, h3!x; ENDCASE
      CASE s_test:   opstr, size, ln := "TEST", 3, h5!x; ENDCASE
      CASE s_if:     opstr, size, ln := "IF", 2, h4!x; ENDCASE
      CASE s_unless: opstr, size, ln := "UNLESS", 2, h4!x; ENDCASE
      CASE s_until:  opstr, size, ln := "UNTIL", 2, h4!x; ENDCASE
      CASE s_while:  opstr, size, ln := "WHILE", 2, h4!x; ENDCASE
      CASE s_for:    opstr, size, ln := "FOR", 5, h7!x; ENDCASE
      CASE s_every:  opstr, size, ln := "EVERY", 2, h4!x; ENDCASE
      CASE s_match:  opstr, size, ln := "MATCH", 2, h4!x; ENDCASE
      CASE s_result: opstr, size, ln := "RESULT", 1, h3!x; ENDCASE
      CASE s_exit:   opstr, size, ln := "EXIT", 1, h3!x; ENDCASE
      CASE s_return: opstr, size, ln := "RETURN", 1, h3!x; ENDCASE
      CASE s_loop:   opstr, size, ln := "LOOP", 0, h2!x; ENDCASE
      CASE s_break:  opstr, size, ln := "BREAK", 0, h2!x; ENDCASE
      CASE s_ass:    opstr, size, ln := "ASS", 2, h4!x; ENDCASE
      CASE s_allass: opstr, size, ln := "ALLASS", 2, h4!x; ENDCASE
      CASE s_lshass: opstr, size, ln := "LSHASS", 2, h4!x; ENDCASE
      CASE s_rshass: opstr, size, ln := "RSHASS", 2, h4!x; ENDCASE
      CASE s_multass:opstr, size, ln := "MULTASS", 2, h4!x; ENDCASE
      CASE s_divass: opstr, size, ln := "DIVASS", 2, h4!x; ENDCASE
      CASE s_modass: opstr, size, ln := "MODASS", 2, h4!x; ENDCASE
      CASE s_andass: opstr, size, ln := "ANDASS", 2, h4!x; ENDCASE
      CASE s_xorass: opstr, size, ln := "XORASS", 2, h4!x; ENDCASE
      CASE s_plusass:opstr, size, ln := "PLUSASS", 2, h4!x; ENDCASE
      CASE s_subass: opstr, size, ln := "SUBASS", 2, h4!x; ENDCASE
      CASE s_orass:  opstr, size, ln := "ORASS", 2, h4!x; ENDCASE

// Declarations
      CASE s_module:   opstr, size, ln := "MODULE", 2, h4!x; ENDCASE
      CASE s_fun:      opstr, size, ln := "FUN", 2, h6!x; ENDCASE
      CASE s_funpat:   opstr, size, ln := "FUNPAT", 3, h5!x; ENDCASE
      CASE s_manifest: opstr, size, ln := "MANIFEST", 1, h4!x; ENDCASE
      CASE s_mdef:     opstr, size := "MDEF", 3; ENDCASE
      CASE s_global:   opstr, size, ln := "GLOBAL", 1, h4!x; ENDCASE
      CASE s_gdef:     opstr, size := "GDEF", 3; ENDCASE
      CASE s_static:   opstr, size, ln := "STATIC", 1, h4!x; ENDCASE
      CASE s_sdef:     opstr, size := "SDEF", 3; ENDCASE
      CASE s_external: opstr, size, ln := "EXTERNAL", 1, h4!x; ENDCASE
      CASE s_xdef:     opstr, size := "XDEF", 3; ENDCASE

      DEFAULT:  opstr, size := "Unknown", 0; ENDCASE
   }

   IF n=d DO {  writes("Etc"); RETURN }

   writef("%s", opstr)
   IF ln>0 DO writef("  line %n/%n", ln>>24, ln & #xFFFFFF)
   FOR i = 1 TO size DO {  newline()
                           FOR j=0 TO n-1 DO writes( v!j )
                           writes("**-")
                           v!n := i=size->"  ","! "
                           plist1(x!i, n+1, d)
                        }
}



