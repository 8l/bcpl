/*
** This is a version of the CINTCODE interpreter that can genearate
** memory reference data that allows memory address/time graphs
** to be constructed. It should be linked as a replacement for cintasm.
** When linked with rastlib it is capable of generating Postscript pictures
** of the execution history of a program.
**
** (c) Copyright:  Martin Richards  26 October 1995
*/


#include <stdio.h>

/* cinterp.h contains machine/system dependent #defines  */
#include "cintsys64.h"

extern BCPLWORD result2;

extern BCPLWORD tallylim;

extern BCPLWORD dosys(BCPLWORD p, BCPLWORD g);
extern BCPLWORD muldiv(BCPLWORD a, BCPLWORD b, BCPLWORD c);


/* functions in rastlib.c  */
extern BCPLWORD fcount;
extern BCPLWORD setraster(BCPLWORD, BCPLWORD); /* not called from this module */
extern void rasterpoint(BCPLWORD);

#define Gn_currco      7
#define Gn_result2    10

/* CINTCODE function codes  */

#define F_0       0

#define F_brk     2
#define F_k0      0
#define F_lf     12
#define F_lm     14
#define F_lm1    15
#define F_l0     16
#define F_fhop   27
#define F_jeq    28

#define F_k      32
#define F_kh     33
#define F_kw     34
#define F_k0g    32
#define F_k0g1   (F_k0g+32)
#define F_k0gh   (F_k0g+64)
#define F_s0g    44
#define F_s0g1   (F_s0g+32)
#define F_s0gh   (F_s0g+64)
#define F_l0g    45
#define F_l0g1   (F_l0g+32)
#define F_l0gh   (F_l0g+64)
#define F_l1g    46
#define F_l1g1   (F_l1g+32)
#define F_l1gh   (F_l1g+64)
#define F_l2g    47
#define F_l2g1   (F_l2g+32)
#define F_l2gh   (F_l2g+64)
#define F_lg     48
#define F_lg1    (F_lg+32)
#define F_lgh    (F_lg+64)
#define F_sg     49
#define F_sg1    (F_sg+32)
#define F_sgh    (F_sg+64)
#define F_llg    50
#define F_llg1   (F_llg+32)
#define F_llgh   (F_llg+64)
#define F_ag     51
#define F_ag1    (F_ag+32)
#define F_agh    (F_ag+64)
#define F_mul    52
#define F_div    53
#define F_rem    54
#define F_xor    55
#define F_sl     56
#define F_ll     58
#define F_jne    60

#define F_llp    64
#define F_llph   65
#define F_llpw   66
#define F_add    84
#define F_sub    85
#define F_lsh    86
#define F_rsh    87
#define F_and    88
#define F_or     89
#define F_lll    90
#define F_jls    92

#define F_l      96
#define F_lh     97
#define F_lw     98
#define F_rv    116
#define F_rtn   123
#define F_jgr   124

#define F_lp    128
#define F_lph   129
#define F_lpw   130
#define F_lp0   128
#define F_sys   145
#define F_swb   146
#define F_swl   147
#define F_st    148
#define F_st0   148
#define F_stp0  149
#define F_goto  155
#define F_jle   156

#define F_sp    160
#define F_sph   161
#define F_spw   162
#define F_sp0   160
#define F_s0    176
#define F_xch   181
#define F_gbyt  182
#define F_pbyt  183
#define F_atc   184
#define F_atb   185
#define F_j     186
#define F_jge   188

#define F_ap    192
#define F_aph   193
#define F_apw   194
#define F_ap0   192

#define F_xpbyt 205
#define F_lmh   206
#define F_btc   207
#define F_nop   208
#define F_a0    208
#define F_rvp0  211
#define F_st0p0 216
#define F_st1p0 218

#define F_a     224
#define F_ah    225
#define F_aw    226
#define F_l0p0  224
#define F_s     237
#define F_sh    238

#define F_mdiv  239
#define F_chgco 240
#define F_neg   241
#define F_not   242
#define F_l1p0  240
#define F_l2p0  244
#define F_l3p0  247 
#define F_l4p0  249

#define F_255   255


/* The function cintasm is designed to be separately compiled,
// and possibly implemented in assembly language for speed.
//
// mem  is the pointer to the cintcode memory.
// regs is the position in the Cintcode memory where the initial
//      value of the Cintcode registers.
//
// interpret (or cintasm) executes Cintcode instructions and returns with
// an integer result as follows:
//     0      sys(0, 0) called
//     1      Non existant instruction
//     2      Brk instruction
//     3      Zero count
//     4      Negative pc
//     5      Division by zero
//     n      sys(0, n) called
//
// On return the Cintcode registers are dumped back in the vector regs
*/


void Rb(BCPLWORD a)
{
  if (tallylim) rasterpoint(a);
}

void Rh(BCPLWORD a)
{
  if (tallylim) rasterpoint(a<<1);
}

void Rw(BCPLWORD a)
{
  if (tallylim) rasterpoint(a<<B2Wsh);
}


int cintasm(BCPLWORD regs, BCPLWORDpt mem)
{ register BCPLWORDpt W = mem;

#define B (BP W)
#define SB (SBP W)
#define H (HP W)
#define SH (SHP W)

#ifdef BIGENDER
#define GH(x) ((WD B[x+0]<<8) | B[x+1])
#define GW(x) ((((((WD B[x]<<8)|B[x+1])<<8)|B[x+2])<<8)|B[x+3])
#else
#define GH(x) ((WD B[x+1]<<8) | B[x])
#define GW(x) ((((((WD B[x+3]<<8)|B[x+2])<<8)|B[x+1])<<8)|B[x])
#endif

   register BCPLWORD           a  = W[regs+0];
   register BCPLWORD           b  = W[regs+1];
   BCPLWORD                    c  = W[regs+2];
   register BCPLWORD           p  = W[regs+3]>>B2Wsh;
   register BCPLWORD           g  = W[regs+4]>>B2Wsh;
   BCPLWORD                    st = W[regs+5];
   register BCPLWORD           pc = W[regs+6];
   register BCPLWORD        count = W[regs+7];

   register BCPLWORDpt Wp  = W+p,    /* Optimise access to the stack */
                    Wg  = W+g,    /* Optimise access to the global vector */
                    Wg1 = W+g+256;

   BCPLWORD  res, k, i;
   Rw(regs+0); 
   Rw(regs+1); 
   Rw(regs+2); 
   Rw(regs+3); 
   Rw(regs+4); 
   Rw(regs+5); 
   Rw(regs+6); 
   Rw(regs+7); 

   if (pc<0) goto negpc;
   
fetch:
   if (tallylim) fcount++;
   Rb(pc);
   switch((int) B[pc++])

{  default:      /* Cases F_0 and F_255 have been added explicitly to   */
   case F_0:     /* improve the compiled code (with luck)               */
   case F_255:   res = 1; pc--; goto ret; /* Unimplemented instruction  */

   case F_mul:   a = b * a;        goto fetch;
   case F_div:   if(a==0) {res = 5; pc--; goto ret; } /* Division by zero */
                 a = b / a;        goto fetch;
   case F_rem:   if(a==0) {res = 5; pc--; goto ret; } /* Division by zero */
                 a = b % a;        goto fetch;
   case F_add:   a = b + a;        goto fetch;
   case F_sub:   a = b - a;        goto fetch;
   case F_neg:   a = - a;          goto fetch;

   case F_fhop:  a = 0; pc++;      goto fetch;

   case F_lsh:   if (a>31) b=0; /* bug */
                 a = b << a;       goto fetch;
   case F_rsh:   if (a>31) b=0; /* bug */
                 a = WD((UWD b)>>a); goto fetch;
   case F_not:   a = ~ a;          goto fetch;
   case F_and:   a = b & a;        goto fetch;
   case F_or:    a = b | a;        goto fetch;
   case F_xor:   a = b ^ a;        goto fetch;

   case F_goto:  pc = a;           goto fetch;

   case F_brk:   res = 2; pc--; goto ret;  /* BREAKPOINT  */
                 
   case F_rv+6:  Rw(a+6); a = W[a+6]; goto fetch;
   case F_rv+5:  Rw(a+5); a = W[a+5]; goto fetch;
   case F_rv+4:  Rw(a+4); a = W[a+4]; goto fetch;
   case F_rv+3:  Rw(a+3); a = W[a+3]; goto fetch;
   case F_rv+2:  Rw(a+2); a = W[a+2]; goto fetch;
   case F_rv+1:  Rw(a+1); a = W[a+1]; goto fetch;
   case F_rv:    Rw(a+0); a = W[a+0]; goto fetch;

   case F_st+3:  Rw(a+3); W[a+3] = b; goto fetch;
   case F_st+2:  Rw(a+2); W[a+2] = b; goto fetch;
   case F_st+1:  Rw(a+1); W[a+1] = b; goto fetch;
   case F_st:    Rw(a+0); W[a+0] = b; goto fetch;

   case F_chgco: Rw(p+0); Rw(g+Gn_currco); Rw(Wg[Gn_currco]); 
                 W[Wg[Gn_currco]] = Wp[0];     /* !currco := !p    */
                 Rw(p+1); 
                 pc = Wp[1];                   /* pc      := p!1   */
                 Rw(p+4); Rw(g+Gn_currco); 
                 Wg[Gn_currco] = Wp[4];        /* currco  := cptr  */
                 Rw(p+4); Rw(Wp[4]); 
                 p = W[Wp[4]]>>B2Wsh;              /* p       := !cptr */
                 Wp = W+p;
                 goto fetch;

   case F_mdiv:  Rw(p+3); Rw(p+4); Rw(p+5); 
                 a = muldiv(Wp[3], Wp[4], Wp[5]);
                 Rw(g+Gn_result2); 
                 Wg[Gn_result2] = result2;
                 /* fall through to return  */
   case F_rtn:   Rw(p+1); 
                 pc = Wp[1];
                 Rw(p+0); 
                 p  = Wp[0]>>B2Wsh;  Wp = W+p; goto fetch;

   case F_gbyt: Rb(a+(b<<B2Wsh));
                a = B[a+(b<<B2Wsh)];            goto fetch;
   case F_pbyt: Rb(a+(b<<B2Wsh));
                B[a+(b<<B2Wsh)] = c;            goto fetch;
   case F_xpbyt:Rb(b+(a<<B2Wsh));
                B[b+(a<<B2Wsh)] = c;            goto fetch;
   case F_atc:  c = a;                      goto fetch;
   case F_btc:  c = b;                      goto fetch;
   case F_atb:  b = a;                      goto fetch;
   case F_xch:  a = a^b; b = a^b; a = a^b;  goto fetch;

   case F_swb: { BCPLWORD n,k,val,i=1;
                 k = (pc+1)>>1;
                 Rh(k);
                 n = H[k];
                 while(i<=n)
                 { i = i+i;
                   Rh(k+i);
                   val = H[k+i];
                   if (a==val) { k += i; break; }
                   if (a<val) i++;
                 }
                 k++;
                 Rh(k);
                 pc = (k<<1) + SH[k];
                 goto fetch;
               }

   case F_swl: { BCPLWORD n,q;
                 q = (pc+1)>>1;
                 Rh(q);
                 n = H[q++];
                 if(0<=a && a<n) q = q + a + 1;
                 Rh(q);
                 pc = (q<<1) + SH[q];
                 goto fetch;
               }

   case F_sys: switch(a) {
                 default: // system call -- general case
 
                         W[regs+0]  = a;    // Save the registers
                         W[regs+1]  = b;    // for debugging purposes
                         W[regs+2]  = c;
                         W[regs+3]  = p<<B2Wsh;
                         W[regs+4]  = g<<B2Wsh;
                         W[regs+5]  = st;
                         W[regs+6]  = pc;
                         W[regs+7]  = count;
  
                         a = dosys(p, g); 
                         goto fetch;

                 case Sys_setcount:
                         /* oldcount := sys(Sys_setcount, newcount)  */
                         a = count; 
		         Rw(p+4); count = Wp[4];
                         res = -1; // Leave and immediately re-enter
                         goto ret; // the interpreter

                 case Sys_quit:
                         Rw(p+4); res = Wp[4];
                         goto ret;

		 // case Sys_rti: //  sys(Sys_rti, regs)
                 // case Sys_saveregs: // sys(Sys_saveregs, regs)
                 // case Sys_setst: // sys(Sys_setst, st)

                 // case Sys_watch:  // sys(Sys_watch, addr)
               }

   case F_lp0+16:  b = a; Rw(p+16); a = Wp[16]; goto fetch;
   case F_lp0+15:  b = a; Rw(p+15); a = Wp[15]; goto fetch;
   case F_lp0+14:  b = a; Rw(p+14); a = Wp[14]; goto fetch;
   case F_lp0+13:  b = a; Rw(p+13); a = Wp[13]; goto fetch;
   case F_lp0+12:  b = a; Rw(p+12); a = Wp[12]; goto fetch;
   case F_lp0+11:  b = a; Rw(p+11); a = Wp[11]; goto fetch;
   case F_lp0+10:  b = a; Rw(p+10); a = Wp[10]; goto fetch;
   case F_lp0+9:   b = a; Rw(p+9);  a = Wp[9];  goto fetch;
   case F_lp0+8:   b = a; Rw(p+8);  a = Wp[8];  goto fetch;
   case F_lp0+7:   b = a; Rw(p+7);  a = Wp[7];  goto fetch;
   case F_lp0+6:   b = a; Rw(p+6);  a = Wp[6];  goto fetch;
   case F_lp0+5:   b = a; Rw(p+5);  a = Wp[5];  goto fetch;
   case F_lp0+4:   b = a; Rw(p+4);  a = Wp[4];  goto fetch;
   case F_lp0+3:   b = a; Rw(p+3);  a = Wp[3];  goto fetch;

   case F_lp:   Rb(pc); Rw(p+B[pc]);
                b = a; a = Wp[B[pc++]];          goto fetch;
   case F_lph:  Rb(pc); Rw(p+GH(pc));
                b = a; a = Wp[GH(pc)];  pc += 2; goto fetch;
   case F_lpw:  Rb(pc); Rw(p+GW(pc));
                b = a; a = Wp[GW(pc)];  pc += 4; goto fetch;

   case F_llp:  b = a;  Rb(pc); a = p+B[pc++];             goto fetch;
   case F_llph: b = a;  Rb(pc); a = p+GH(pc);     pc += 2; goto fetch;
   case F_llpw: b = a;  Rb(pc); a = p+GW(pc);     pc += 4; goto fetch;

   case F_sp0+16: Rw(p+16); Wp[16] = a; goto fetch;
   case F_sp0+15: Rw(p+15); Wp[15] = a; goto fetch;
   case F_sp0+14: Rw(p+14); Wp[14] = a; goto fetch;
   case F_sp0+13: Rw(p+13); Wp[13] = a; goto fetch;
   case F_sp0+12: Rw(p+12); Wp[12] = a; goto fetch;
   case F_sp0+11: Rw(p+11); Wp[11] = a; goto fetch;
   case F_sp0+10: Rw(p+10); Wp[10] = a; goto fetch;
   case F_sp0+9:  Rw(p+9);  Wp[9]  = a; goto fetch;
   case F_sp0+8:  Rw(p+8);  Wp[8]  = a; goto fetch;
   case F_sp0+7:  Rw(p+7);  Wp[7]  = a; goto fetch;
   case F_sp0+6:  Rw(p+6);  Wp[6]  = a; goto fetch;
   case F_sp0+5:  Rw(p+5);  Wp[5]  = a; goto fetch;
   case F_sp0+4:  Rw(p+4);  Wp[4]  = a; goto fetch;
   case F_sp0+3:  Rw(p+3);  Wp[3]  = a; goto fetch;

   case F_sp:    Rb(pc); Rw(p+B[pc]);
                 Wp[B[pc++]] = a;                  goto fetch;
   case F_sph:   Rb(pc); Rw(p+GH(pc));
                 Wp[GH(pc)]  = a;         pc += 2; goto fetch;
   case F_spw:   Rb(pc); Rw(p+GW(pc));
                 Wp[GW(pc)]  = a;         pc += 4; goto fetch;

   case F_lgh:   Rb(pc); Rw(g+GH(pc));
                 b = a; a = Wg[GH(pc)];   pc += 2; goto fetch;
   case F_lg1:   Rb(pc); Rw(g+256+B[pc]);
                 b = a; a = Wg1[B[pc++]];          goto fetch;
   case F_lg:    Rb(pc); Rw(g+B[pc]);
                 b = a; a = Wg[B[pc++]];           goto fetch;

   case F_sgh:   Rb(pc); Rw(g+GH(pc));
                 Wg[GH(pc)]   = a;        pc += 2; goto fetch;
   case F_sg1:   Rb(pc); Rw(g+256+B[pc]);
                 Wg1[B[pc++]] = a;                 goto fetch;
   case F_sg:    Rb(pc); Rw(g+B[pc]);
                 Wg[B[pc++]]  = a;                 goto fetch;

   case F_llgh: b = a; Rb(pc); a = g+GH(pc);      pc += 2; goto fetch;
   case F_llg1: b = a; Rb(pc); a = g+256+B[pc++];          goto fetch;
   case F_llg:  b = a; Rb(pc); a = g+B[pc++];              goto fetch;

   case F_ll+1: Rb(pc); i = (pc>>1) + B[pc];
                Rh(i);  i = (i<<1) + SH[i];
                Rw(i>>B2Wsh); b = a; a = W[i>>B2Wsh];          pc++; goto fetch;

   case F_ll:   Rb(pc); Rw((pc+SB[pc])>>B2Wsh);
                b = a; a = W[(pc+SB[pc])>>B2Wsh];pc++; goto fetch;

   case F_sl+1: Rb(pc); i = (pc>>1) + B[pc];
                Rh(i); i = (i<<1) + SH[i];
                Rw(i>>B2Wsh); W[i>>B2Wsh] = a;                 pc++; goto fetch;

   case F_sl:   Rb(pc); Rw((pc+SB[pc])>>B2Wsh);
                W[(pc+SB[pc])>>B2Wsh] = a;       pc++; goto fetch;
   
   case F_lll+1:Rb(pc); i = (pc>>1) + B[pc];
                Rh(i); i = (i<<1) + SH[i];
                b = a; a = i>>B2Wsh;             pc++; goto fetch;

   case F_lll:  Rb(pc); b = a; a = (pc+SB[pc])>>B2Wsh;   pc++; goto fetch;
   
   case F_l0+10: b = a; a = 10; goto fetch;
   case F_l0+9:  b = a; a =  9; goto fetch;
   case F_l0+8:  b = a; a =  8; goto fetch;
   case F_l0+7:  b = a; a =  7; goto fetch;
   case F_l0+6:  b = a; a =  6; goto fetch;
   case F_l0+5:  b = a; a =  5; goto fetch;
   case F_l0+4:  b = a; a =  4; goto fetch;
   case F_l0+3:  b = a; a =  3; goto fetch;
   case F_l0+2:  b = a; a =  2; goto fetch;
   case F_l0+1:  b = a; a =  1; goto fetch;
   case F_l0:    b = a; a =  0; goto fetch;
   case F_l0-1:  b = a; a = -1; goto fetch; 

   case F_l:     Rb(pc); b = a; a = B[pc++];               goto fetch;
   case F_lh:    Rb(pc); b = a; a = GH(pc);       pc += 2; goto fetch;
   case F_lw:    Rb(pc); b = a; a = GW(pc);       pc += 4; goto fetch;

   case F_lm:    Rb(pc); b = a; a = - WD(B[pc++]);         goto fetch;
   case F_lmh:   Rb(pc); b = a; a = - WD(GH(pc)); pc += 2; goto fetch;
                
   case F_lf+1:  b = a;
                 Rb(pc); a = (pc>>1) + B[pc];
                 Rh(a); a = (a<<1) + SH[a];         pc++; goto fetch;

   case F_lf:    Rb(pc); b = a; a = pc + SB[pc];     pc++; goto fetch;
 
   case F_k0gh+11: Rw(p+11); Wp[11] = p<<B2Wsh; p += 11; goto applygh;
   case F_k0gh+10: Rw(p+10); Wp[10] = p<<B2Wsh; p += 10; goto applygh;
   case F_k0gh+9:  Rw(p+9);  Wp[ 9] = p<<B2Wsh; p +=  9; goto applygh;
   case F_k0gh+8:  Rw(p+8);  Wp[ 8] = p<<B2Wsh; p +=  8; goto applygh;
   case F_k0gh+7:  Rw(p+7);  Wp[ 7] = p<<B2Wsh; p +=  7; goto applygh;
   case F_k0gh+6:  Rw(p+6);  Wp[ 6] = p<<B2Wsh; p +=  6; goto applygh;
   case F_k0gh+5:  Rw(p+5);  Wp[ 5] = p<<B2Wsh; p +=  5; goto applygh;
   case F_k0gh+4:  Rw(p+4);  Wp[ 4] = p<<B2Wsh; p +=  4; goto applygh;
   case F_k0gh+3:  Rw(p+3);  Wp[ 3] = p<<B2Wsh; p +=  3;
   applygh:        Wp    = W+p;
                   Rw(p+1); Wp[1] = pc + 2;
                   Rb(pc); Rw(g+GH(pc)); pc    = Wg[GH(pc)];
                   Rw(p+2); Wp[2] = pc;
                   Rw(p+3); Wp[3] =  a;
                   if (pc>=0) goto fetch;
                   goto negpc;

   case F_k0g1+11: Rw(p+11); Wp[11] = p<<B2Wsh; p += 11; goto applyg1;
   case F_k0g1+10: Rw(p+10); Wp[10] = p<<B2Wsh; p += 10; goto applyg1;
   case F_k0g1+9:  Rw(p+9);  Wp[ 9] = p<<B2Wsh; p +=  9; goto applyg1;
   case F_k0g1+8:  Rw(p+8);  Wp[ 8] = p<<B2Wsh; p +=  8; goto applyg1;
   case F_k0g1+7:  Rw(p+7);  Wp[ 7] = p<<B2Wsh; p +=  7; goto applyg1;
   case F_k0g1+6:  Rw(p+6);  Wp[ 6] = p<<B2Wsh; p +=  6; goto applyg1;
   case F_k0g1+5:  Rw(p+5);  Wp[ 5] = p<<B2Wsh; p +=  5; goto applyg1;
   case F_k0g1+4:  Rw(p+4);  Wp[ 4] = p<<B2Wsh; p +=  4; goto applyg1;
   case F_k0g1+3:  Rw(p+3);  Wp[ 3] = p<<B2Wsh; p +=  3;
   applyg1:        Wp    = W+p;
                   Rw(p+1); Wp[1] = pc + 1;
                   Rb(pc); Rw(g+256+B[pc]); pc    = Wg1[B[pc]];
                   Rw(p+2); Wp[2] = pc;
                   Rw(p+3); Wp[3] = a;
                   if (pc>=0) goto fetch;
                   goto negpc;
 
   case F_k0g+11: Rw(p+11); Wp[11] = p<<B2Wsh; p += 11; goto applyg;
   case F_k0g+10: Rw(p+10); Wp[10] = p<<B2Wsh; p += 10; goto applyg;
   case F_k0g+9:  Rw(p+9);  Wp[ 9] = p<<B2Wsh; p +=  9; goto applyg;
   case F_k0g+8:  Rw(p+8);  Wp[ 8] = p<<B2Wsh; p +=  8; goto applyg;
   case F_k0g+7:  Rw(p+7);  Wp[ 7] = p<<B2Wsh; p +=  7; goto applyg;
   case F_k0g+6:  Rw(p+6);  Wp[ 6] = p<<B2Wsh; p +=  6; goto applyg;
   case F_k0g+5:  Rw(p+5);  Wp[ 5] = p<<B2Wsh; p +=  5; goto applyg;
   case F_k0g+4:  Rw(p+4);  Wp[ 4] = p<<B2Wsh; p +=  4; goto applyg;
   case F_k0g+3:  Rw(p+3);  Wp[ 3] = p<<B2Wsh; p +=  3;
   applyg:        Wp    = W+p;
                  Rw(p+1); Wp[1] = pc + 1;
                  Rb(pc); Rw(g+B[pc]); pc    = Wg[B[pc]];
                  Rw(p+2); Wp[2] = pc;
                  Rw(p+3); Wp[3] = a;
                  if (pc>=0) goto fetch;
                  goto negpc;
 
   case F_k0+11:  Rw(p+11); Wp[11] = p<<B2Wsh; p += 11; goto applyk;
   case F_k0+10:  Rw(p+10); Wp[10] = p<<B2Wsh; p += 10; goto applyk;
   case F_k0+9:   Rw(p+9);  Wp[ 9] = p<<B2Wsh; p +=  9; goto applyk;
   case F_k0+8:   Rw(p+8);  Wp[ 8] = p<<B2Wsh; p +=  8; goto applyk;
   case F_k0+7:   Rw(p+7);  Wp[ 7] = p<<B2Wsh; p +=  7; goto applyk;
   case F_k0+6:   Rw(p+6);  Wp[ 6] = p<<B2Wsh; p +=  6; goto applyk;
   case F_k0+5:   Rw(p+5);  Wp[ 5] = p<<B2Wsh; p +=  5; goto applyk;
   case F_k0+4:   Rw(p+4);  Wp[ 4] = p<<B2Wsh; p +=  4; goto applyk;
   case F_k0+3:   Rw(p+3);  Wp[ 3] = p<<B2Wsh; p +=  3;
   applyk:        Wp    = W+p;
                  Rw(p+1); Wp[1] = WD pc;
                  pc    = a;
                  Rw(p+2); Wp[2] = pc;
                  Rw(p+3); Wp[3] = a = b;
                  if (pc>=0) goto fetch;
                  goto negpc;

   case F_k:      Rb(pc); k = B[pc]; Rw(p+k); Wp[k] = p<<B2Wsh; p +=  k;
                  Wp    = W+p;
                  Rw(p+1); Wp[1] = pc + 1;
                  pc    = a;
                  Rw(p+2); Wp[2] = pc;
                  Rw(p+3); Wp[3] = a = b;
                  if (pc>=0) goto fetch;
                  goto negpc;

   case F_kh:     Rb(pc); k = GH(pc); Rw(p+k); Wp[k] = p<<B2Wsh; p +=  k;
                  Wp    = W+p;
                  Rw(p+1); Wp[1] = pc + 2;
                  pc    = a;
                  Rw(p+2); Wp[2] = pc;
                  Rw(p+3); Wp[3] = a = b;
                  if (pc>=0) goto fetch;
                  goto negpc;

   case F_kw:     Rb(pc); k = GW(pc); Rw(p+k); Wp[k] = p<<B2Wsh; p +=  k;
                  Wp    = W+p;
                  Rw(p+1); Wp[1] = pc + 4;
                  pc    = a;
                  Rw(p+2); Wp[2] = pc;
                  Rw(p+3); Wp[3] = a = b;
                  if (pc>=0) goto fetch;
                  goto negpc;

   case F_jeq:   if(b==a) { Rb(pc); pc += SB[pc];   goto fetch; }
                 pc++; goto fetch;
   case F_jeq+1: if(b==a) goto indjump;
                 pc++; goto fetch;
   case F_jeq+2: if(a==0) { Rb(pc); pc += SB[pc];   goto fetch; }
                 pc++; goto fetch;
   case F_jeq+3: if(a==0) goto indjump;
                 pc++; goto fetch;

   case F_jne:   if(b!=a) { Rb(pc); pc += SB[pc];   goto fetch; }
                 pc++; goto fetch;
   case F_jne+1: if(b!=a) goto indjump;
                 pc++; goto fetch;
   case F_jne+2: if(a!=0) { Rb(pc); pc += SB[pc];   goto fetch; }
                 pc++; goto fetch;
   case F_jne+3: if(a!=0) goto indjump;
                 pc++; goto fetch;

   case F_jls:   if(b<a) { Rb(pc); pc += SB[pc];   goto fetch; }
                 pc++; goto fetch;
   case F_jls+1: if(b<a) goto indjump;
                 pc++; goto fetch;
   case F_jls+2: if(a<0) { Rb(pc); pc += SB[pc];   goto fetch; }
                 pc++; goto fetch;
   case F_jls+3: if(a<0) goto indjump;
                 pc++; goto fetch;

   case F_jgr:   if(b>a) { Rb(pc); pc += SB[pc];   goto fetch; }
                 pc++; goto fetch;
   case F_jgr+1: if(b>a) goto indjump;
                 pc++; goto fetch;
   case F_jgr+2: if(a>0) { Rb(pc); pc += SB[pc];   goto fetch; }
                 pc++; goto fetch;
   case F_jgr+3: if(a>0) goto indjump;
                 pc++; goto fetch;

   case F_jle:   if(b<=a) {Rb(pc);  pc += SB[pc];   goto fetch; }
                 pc++; goto fetch;
   case F_jle+1: if(b<=a) goto indjump;
                 pc++; goto fetch;
   case F_jle+2: if(a<=0) { Rb(pc); pc += SB[pc];   goto fetch; }
                 pc++; goto fetch;
   case F_jle+3: if(a<=0) goto indjump;
                 pc++; goto fetch;

   case F_jge:   if(b>=a) { Rb(pc); pc += SB[pc];   goto fetch; }
                 pc++; goto fetch;
   case F_jge+1: if(b>=a) goto indjump;
                 pc++; goto fetch;
   case F_jge+2: if(a>=0) { Rb(pc); pc += SB[pc];   goto fetch; }
                 pc++; goto fetch;
   case F_jge+3: if(a>=0) goto indjump;
                 pc++; goto fetch;

   case F_j:     Rb(pc); pc += SB[pc];        goto fetch;

 indjump:
   case F_j+1:   Rb(pc); pc = (pc>>1) + B[pc];
                 Rh(pc); pc = (pc<<1) + SH[pc];
                 goto fetch;

   case F_ap0+12: Rw(p+12); a = a + Wp[12]; goto fetch;
   case F_ap0+11: Rw(p+11); a = a + Wp[11]; goto fetch;
   case F_ap0+10: Rw(p+10); a = a + Wp[10]; goto fetch;
   case F_ap0+9:  Rw(p+9);  a = a + Wp[ 9]; goto fetch;
   case F_ap0+8:  Rw(p+8);  a = a + Wp[ 8]; goto fetch;
   case F_ap0+7:  Rw(p+7);  a = a + Wp[ 7]; goto fetch;
   case F_ap0+6:  Rw(p+6);  a = a + Wp[ 6]; goto fetch;
   case F_ap0+5:  Rw(p+5);  a = a + Wp[ 5]; goto fetch;
   case F_ap0+4:  Rw(p+4);  a = a + Wp[ 4]; goto fetch;
   case F_ap0+3:  Rw(p+3);  a = a + Wp[ 3]; goto fetch;

   case F_ap:    Rb(pc); Rw(p+B[pc]);     a += Wp[B[pc++]];         goto fetch;
   case F_aph:   Rb(pc); Rw(p+GH(pc));    a += Wp[GH(pc)]; pc += 2; goto fetch;
   case F_apw:   Rb(pc); Rw(p+GW(pc));    a += Wp[GW(pc)]; pc += 4; goto fetch;
   case F_agh:   Rb(pc); Rw(g+GH(pc));    a += Wg[GH(pc)]; pc += 2; goto fetch;
   case F_ag1:   Rb(pc); Rw(g+256+B[pc]); a += Wg1[B[pc++]];        goto fetch;
   case F_ag:    Rb(pc); Rw(g+B[pc]);     a += Wg[B[pc++]];         goto fetch;

   case F_a0+5: a += 5; goto fetch;
   case F_a0+4: a += 4; goto fetch;
   case F_a0+3: a += 3; goto fetch;
   case F_a0+2: a += 2; goto fetch;
   case F_a0+1: a += 1; goto fetch;
   case F_nop:          goto fetch;

   case F_a:    Rb(pc); a += B[pc++];           goto fetch;
   case F_ah:   Rb(pc); a += GH(pc);   pc += 2; goto fetch;
   case F_aw:   Rb(pc); a += GW(pc);   pc += 4; goto fetch;
   case F_s:    Rb(pc); a -= B[pc++];           goto fetch;
   case F_sh:   Rb(pc); a -= GH(pc);   pc += 2; goto fetch;

   case F_s0+4: a -= 4; goto fetch;
   case F_s0+3: a -= 3; goto fetch;
   case F_s0+2: a -= 2; goto fetch;
   case F_s0+1: a -= 1; goto fetch;

   case F_l0p0+12: Rw(p+12); Rw(Wp[12]+0);
                   b = a; a = W[Wp[12]+0]; goto fetch;
   case F_l0p0+11: Rw(p+11); Rw(Wp[11]+0);
                   b = a; a = W[Wp[11]+0]; goto fetch;
   case F_l0p0+10: Rw(p+10); Rw(Wp[10]+0);
                   b = a; a = W[Wp[10]+0]; goto fetch;
   case F_l0p0+9:  Rw(p+9);   Rw(Wp[9]+0);
                   b = a; a = W[Wp[ 9]+0]; goto fetch;
   case F_l0p0+8:  Rw(p+8);   Rw(Wp[8]+0);
                   b = a; a = W[Wp[ 8]+0]; goto fetch;
   case F_l0p0+7:  Rw(p+7);   Rw(Wp[7]+0);
                   b = a; a = W[Wp[ 7]+0]; goto fetch;
   case F_l0p0+6:  Rw(p+6);   Rw(Wp[6]+0);
                   b = a; a = W[Wp[ 6]+0]; goto fetch;
   case F_l0p0+5:  Rw(p+5);   Rw(Wp[5]+0);
                   b = a; a = W[Wp[ 5]+0]; goto fetch;
   case F_l0p0+4:  Rw(p+4);   Rw(Wp[4]+0);
                   b = a; a = W[Wp[ 4]+0]; goto fetch;
   case F_l0p0+3:  Rw(p+3);   Rw(Wp[3]+0);
                   b = a; a = W[Wp[ 3]+0]; goto fetch;

   case F_l1p0+6:  Rw(p+6);   Rw(Wp[6]+1);
                   b = a; a = W[Wp[ 6]+1]; goto fetch;
   case F_l1p0+5:  Rw(p+5);   Rw(Wp[5]+1);
                   b = a; a = W[Wp[ 5]+1]; goto fetch;
   case F_l1p0+4:  Rw(p+4);   Rw(Wp[4]+1);
                   b = a; a = W[Wp[ 4]+1]; goto fetch;
   case F_l1p0+3:  Rw(p+3);   Rw(Wp[3]+1);
                   b = a; a = W[Wp[ 3]+1]; goto fetch;

   case F_l2p0+5:  Rw(p+5);   Rw(Wp[5]+2);
                   b = a; a = W[Wp[ 5]+2]; goto fetch;
   case F_l2p0+4:  Rw(p+4);   Rw(Wp[4]+2);
                   b = a; a = W[Wp[ 4]+2]; goto fetch;
   case F_l2p0+3:  Rw(p+3);   Rw(Wp[3]+2);
                   b = a; a = W[Wp[ 3]+2]; goto fetch;

   case F_l3p0+4:  Rw(p+4);   Rw(Wp[4]+3);
                   b = a; a = W[Wp[ 4]+3]; goto fetch;
   case F_l3p0+3:  Rw(p+3);   Rw(Wp[3]+3);
                   b = a; a = W[Wp[ 3]+3]; goto fetch;

   case F_l4p0+4:  Rw(p+4);   Rw(Wp[4]+4);
                   b = a; a = W[Wp[ 4]+4]; goto fetch;
   case F_l4p0+3:  Rw(p+3);   Rw(Wp[3]+4);
                   b = a; a = W[Wp[ 3]+4]; goto fetch;

   case F_l0gh:  Rb(pc); Rw(g+GH(pc)); Rw(Wg[GH(pc)]+0);
                 b = a; a = W[Wg[GH(pc)]+0]; pc += 2; goto fetch;
   case F_l1gh:  Rb(pc); Rw(g+GH(pc)); Rw(Wg[GH(pc)]+1);
                 b = a; a = W[Wg[GH(pc)]+1]; pc += 2; goto fetch;
   case F_l2gh:  Rb(pc); Rw(g+GH(pc)); Rw(Wg[GH(pc)]+2);
                 b = a; a = W[Wg[GH(pc)]+2]; pc += 2; goto fetch;
   case F_l0g1:  Rb(pc); Rw(g+256+B[pc]); Rw(Wg1[B[pc]]+0);
                 b = a; a = W[Wg1[B[pc++]]+0];        goto fetch;
   case F_l1g1:  Rb(pc); Rw(g+256+B[pc]); Rw(Wg1[B[pc]]+1);
                 b = a; a = W[Wg1[B[pc++]]+1];        goto fetch;
   case F_l2g1:  Rb(pc); Rw(g+256+B[pc]); Rw(Wg1[B[pc]]+2);
                 b = a; a = W[Wg1[B[pc++]]+2];        goto fetch;
   case F_l0g:   Rb(pc); Rw(g+B[pc]); Rw(Wg[B[pc]]+0);
                 b = a; a = W[Wg[B[pc++]]+0];         goto fetch;
   case F_l1g:   Rb(pc); Rw(g+B[pc]); Rw(Wg[B[pc]]+1);
                 b = a; a = W[Wg[B[pc++]]+1];         goto fetch;
   case F_l2g:   Rb(pc); Rw(g+B[pc]); Rw(Wg[B[pc]]+2);
                 b = a; a = W[Wg[B[pc++]]+2];         goto fetch;

   case F_s0gh:  Rb(pc); Rw(g+GH(pc)); Rw(Wg[GH(pc)]+0);
                 W[Wg[GH(pc)]+0] = a;        pc += 2; goto fetch;
   case F_s0g1:  Rb(pc); Rw(g+256+B[pc]); Rw(Wg1[B[pc]]+0);
                 W[Wg1[B[pc++]]+0] = a;               goto fetch;
   case F_s0g:   Rb(pc); Rw(g+B[pc]); Rw(Wg[B[pc]]+0);
                 W[Wg[B[pc++]]+0] = a;                goto fetch;

   case F_stp0+5: Rw(p+5); Rw(a+Wp[5]); W[a+Wp[5]] = b; goto fetch;
   case F_stp0+4: Rw(p+4); Rw(a+Wp[4]); W[a+Wp[4]] = b; goto fetch;
   case F_stp0+3: Rw(p+3); Rw(a+Wp[3]); W[a+Wp[3]] = b; goto fetch;

   case F_st0p0+4: Rw(p+4); Rw(Wp[4]+0); W[Wp[4]+0] = a; goto fetch;
   case F_st0p0+3: Rw(p+3); Rw(Wp[3]+0); W[Wp[3]+0] = a; goto fetch;

   case F_st1p0+4: Rw(p+4); Rw(Wp[4]+1); W[Wp[4]+1] = a; goto fetch;
   case F_st1p0+3: Rw(p+3); Rw(Wp[3]+1); W[Wp[3]+1] = a; goto fetch;
   
   case F_rvp0+7: Rw(p+7); Rw(a+Wp[7]); a = W[a+Wp[7]]; goto fetch;
   case F_rvp0+6: Rw(p+6); Rw(a+Wp[6]); a = W[a+Wp[6]]; goto fetch;
   case F_rvp0+5: Rw(p+5); Rw(a+Wp[5]); a = W[a+Wp[5]]; goto fetch;
   case F_rvp0+4: Rw(p+4); Rw(a+Wp[4]); a = W[a+Wp[4]]; goto fetch;
   case F_rvp0+3: Rw(p+3); Rw(a+Wp[3]); a = W[a+Wp[3]]; goto fetch;
   }

negpc:
   res = 4;  /* negative pc  */ 
ret:
   Rw(regs+0); W[regs+0]  = a;    /* Save the machine registers  */
   Rw(regs+1); W[regs+1]  = b;
   Rw(regs+2); W[regs+2]  = c;
   Rw(regs+3); W[regs+3]  = p<<B2Wsh;
   Rw(regs+4); W[regs+4]  = g<<B2Wsh;
   Rw(regs+5); W[regs+5]  = st;
   Rw(regs+6); W[regs+6]  = pc;
   Rw(regs+7); W[regs+7]  = count;
   
   return res;
}

