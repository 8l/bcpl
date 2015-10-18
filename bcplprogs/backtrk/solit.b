SECTION "Solit"

GET "libhdr"

GLOBAL { scorev:200; fn:201  }

MANIFEST {
Pbits = #x7FFF; SH = #X10000; Upb = Pbits

p1 = 1<<0;  p2 = 1<<1;  p3 = 1<<2;  p4 = 1<<3;  p5 = 1<<4
p6 = 1<<5;  p7 = 1<<6;  p8 = 1<<7;  p9 = 1<<8;  pa = 1<<9
pb = 1<<10; pc = 1<<11; pd = 1<<12; pe = 1<<13; pf = 1<<14

h1 = p1*SH; h2 = p2*SH; h3 = p3*SH; h4 = p4*SH; h5 = p5*SH
h6 = p6*SH; h7 = p7*SH; h8 = p8*SH; h9 = p9*SH; ha = pa*SH
hb = pb*SH; hc = pc*SH; hd = pd*SH; he = pe*SH; hf = pf*SH

ph1= p1+h1; ph2= p2+h2; ph3= p3+h3; ph4= p4+h4; ph5= p5+h5
ph6= p6+h6; ph7= p7+h7; ph8= p8+h8; ph9= p9+h9; pha= pa+ha
phb= pb+hb; phc= pc+hc; phd= pd+hd; phe= pe+he; phf= pf+hf
}

LET trypos(pos) = VALOF
{ LET poss = pos & Pbits
  LET score = scorev!poss
  IF score<0 DO { score := 0  // Calculate score for this position.
                  UNTIL poss=0 DO { LET p = poss & -poss
                                    poss := poss - p
                                    score := score + (fn!p)(pos)
                                  }
                  // Fill in the score for this position.
                  scorev!(pos&Pbits) := score
                }
  RESULTIS score
}

AND trymove(pos, tijk, mijk) = (pos&tijk)=0 -> trypos(pos NEQV mijk), 0

AND f1(pos) = trymove(pos, h1+h2+p4, ph1+ph2+ph4) +
              trymove(pos, h1+h3+p6, ph1+ph3+ph6)
   
AND f2(pos) = trymove(pos, h2+h4+p7, ph2+ph4+ph7) +
              trymove(pos, h2+h5+p9, ph2+ph5+ph9)

AND f3(pos) = trymove(pos, h3+h5+p8, ph3+ph5+ph8) +
              trymove(pos, h3+h6+pa, ph3+ph6+pha)

AND f4(pos) = trymove(pos, h4+h2+p1, ph4+ph2+ph1) +
              trymove(pos, h4+h5+p6, ph4+ph5+ph6) +
              trymove(pos, h4+h7+pb, ph4+ph7+phb) +
              trymove(pos, h4+h8+pd, ph4+ph8+phd)

AND f5(pos) = trymove(pos, h5+h8+pc, ph5+ph8+phc) +
              trymove(pos, h5+h9+pe, ph5+ph9+phe)

AND f6(pos) = trymove(pos, h6+h3+p1, ph6+ph3+ph1) +
              trymove(pos, h6+h5+p4, ph6+ph5+ph4) +
              trymove(pos, h6+h9+pd, ph6+ph9+phd) +
              trymove(pos, h6+ha+pf, ph6+pha+phf)

AND f7(pos) = trymove(pos, h7+h4+p2, ph7+ph4+ph2) +
              trymove(pos, h7+h8+p9, ph7+ph8+ph9)

AND f8(pos) = trymove(pos, h8+h5+p3, ph8+ph5+ph3) +
              trymove(pos, h8+h9+pa, ph8+ph9+pha)

AND f9(pos) = trymove(pos, h9+h5+p2, ph9+ph5+ph2) +
              trymove(pos, h9+h8+p7, ph9+ph8+ph7)

AND fa(pos) = trymove(pos, ha+h6+p3, pha+ph6+ph3) +
              trymove(pos, ha+h9+p8, pha+ph9+ph8)

AND fb(pos) = trymove(pos, hb+h7+p4, phb+ph7+ph4) +
              trymove(pos, hb+hc+pd, phb+phc+phd)

AND fc(pos) = trymove(pos, hc+h8+p5, phc+ph8+ph5) +
              trymove(pos, hc+hd+pe, phc+phd+phe)

AND fd(pos) = trymove(pos, hd+h8+p4, phd+ph8+ph4) +
              trymove(pos, hd+h9+p6, phd+ph9+ph6) +
              trymove(pos, hd+hc+pb, phd+phc+phb) +
              trymove(pos, hd+he+pf, phd+phe+phf)

AND fe(pos) = trymove(pos, he+h9+p5, phe+ph9+ph5) +
              trymove(pos, he+hd+pc, phe+phd+phc)

AND ff(pos) = trymove(pos, hf+ha+p6, phf+pha+ph6) +
              trymove(pos, hf+he+pd, phf+phe+phd)

LET start() = VALOF
{ LET v1 = getvec(Upb)
  LET v2 = getvec(Upb)

  scorev, fn := v1, v2
  FOR i = 0 TO Upb DO scorev!i := -1

  fn!p1 := f1; fn!p2 := f2; fn!p3 := f3; fn!p4 := f4; fn!p5 := f5
  fn!p6 := f6; fn!p7 := f7; fn!p8 := f8; fn!p9 := f9; fn!pa := fa
  fn!pb := fb; fn!pc := fc; fn!pd := fd; fn!pe := fe; fn!pf := ff

  scorev!p1 := 1       // Set score for final position
  writef("Number of solutions = %n*n",
          trypos(       h1+
                      p2+p3+
                     p4+p5+p6+
                   p7+p8+p9+pa+
                  pb+pc+pd+pe+pf  ))
   
  { LET k1, k2 = 0, 0
    FOR i = 0 TO Upb IF scorev!i>=0 DO
    { k1 := k1+1
      IF scorev!i>0 DO k2 := k2+1
    }
    writef("%i4 positions reachable from the initial position*n", k1)
    writef("%i4 positions on paths to a solution*n",              k2)
  }
  freevec(v1)
  freevec(v2)
  RESULTIS 0
}

