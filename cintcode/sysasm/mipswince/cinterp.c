/*
** This is a 32 bit CINTCODE interpreter written in C
**
** (c) Copyright:  Martin Richards  9 October 1995
*/

//#include <stdio.h>
//#include <stdlib.h>

/* cinterp.h contains machine/system dependent #defines  */
#include "cinterp.h"

#define TRACINGyes
#define TALLYyes

extern INT32 result2;

extern int tracing;

extern INT32 *tallyv;
extern INT32 tallylim;

extern INT32 dosys(INT32 p, INT32 g);
extern INT32 muldiv(INT32 a, INT32 b, INT32 c);

extern void wrcode(char *form, INT32 f, INT32 a); 
extern void wrfcode(INT32 f);
extern void trace(INT32 pc, INT32 p, INT32 a, INT32 b);

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


/* The function interpret is designed to be separately compiled,
// and possibly implemented in assembly language.
//
// Unless either TRACINGyes or TALLYyes are defined, its only free
// variable is the function dosys(p, g).
//
// mem  is the pointer to the cintcode memory.
// regs is the position in the Cintcode memory where the initial
//      value of the Cintcode registers.
//
// interpret executes Cintcode instructions and returns with an
// integer result as follows:
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


int interpret(INT32 regs, INT32pt mem)
{ register INT32pt W = mem;

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

   register INT32           a  = W[regs+0];
   register INT32           b  = W[regs+1];
   INT32                    c  = W[regs+2];
   register INT32           p  = W[regs+3]>>2;
   register INT32           g  = W[regs+4]>>2;
   INT32                    st = W[regs+5];
   register INT32           pc = W[regs+6];
   register INT32        count = W[regs+7];

   register INT32pt Wp  = W+p,    /* Optimise access to the stack */
                    Wg  = W+g,    /* Optimise access to the global vector */
                    Wg1 = W+g+256;

   INT32  res, k, i;

   if (pc<0) goto negpc;
   
fetch:
   /* count>=0  means execute count instructions (slow interpreter)
      count=-1  means go on for ever (fast interpreter)
      count=-2  means single step the fast interpreter */
   if (count>=0)
   { if (count==0) { res = 3; goto ret; }
     count--;
   }
#ifdef TRACINGyes
   if (tracing) trace(pc, p, a, b);
#endif

#ifdef TALLYyes
   if (pc<tallylim && pc>0) tallyv[pc]++;
#endif

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
                 
   case F_rv+6:  a = W[a+6]; goto fetch;
   case F_rv+5:  a = W[a+5]; goto fetch;
   case F_rv+4:  a = W[a+4]; goto fetch;
   case F_rv+3:  a = W[a+3]; goto fetch;
   case F_rv+2:  a = W[a+2]; goto fetch;
   case F_rv+1:  a = W[a+1]; goto fetch;
   case F_rv:    a = W[a+0]; goto fetch;

   case F_st+3:  W[a+3] = b; goto fetch;
   case F_st+2:  W[a+2] = b; goto fetch;
   case F_st+1:  W[a+1] = b; goto fetch;
   case F_st:    W[a+0] = b; goto fetch;

   case F_chgco: W[Wg[Gn_currco]] = Wp[0];     /* !currco := !p    */
                 pc = Wp[1];                   /* pc      := p!1   */
                 Wg[Gn_currco] = Wp[4];        /* currco  := cptr  */
                 p = W[Wp[4]]>>2;              /* p       := !cptr */
                 Wp = W+p;
                 goto fetch;

   case F_mdiv:  a = muldiv(Wp[3], Wp[4], Wp[5]);
                 Wg[Gn_result2] = result2;
                 /* fall through to return  */
   case F_rtn:   pc = Wp[1]; p  = W[p]>>2;  Wp = W+p; goto fetch;

   case F_gbyt: a = B[a+(b<<2)];            goto fetch;
   case F_pbyt: B[a+(b<<2)] = (char)c;      goto fetch;
   case F_xpbyt:B[b+(a<<2)] = (char)c;      goto fetch;
   case F_atc:  c = a;                      goto fetch;
   case F_btc:  c = b;                      goto fetch;
   case F_atb:  b = a;                      goto fetch;
   case F_xch:  a = a^b; b = a^b; a = a^b;  goto fetch;

   case F_swb: { INT32 n,k,val,i=1;
                 k = (pc+1)>>1;
                 n = H[k];
                 while(i<=n)
                 { i = i+i;
                   val = H[k+i];
                   if (a==val) { k += i; break; }
                   if (a<val) i++;
                 }
                 k++;
                 pc = (k<<1) + SH[k];
                 goto fetch;
               }

   case F_swl: { INT32 n,q;
                 q = (pc+1)>>1;
                 n = H[q++];
                 if(0<=a && a<n) q = q + a + 1;
                 pc = (q<<1) + SH[q];
                 goto fetch;
               }

   case F_sys: if(a<=0) {
                 if(a==0)  { res = Wp[4]; goto ret; }  /* finish      */
                 if(a==-1) {       /* oldcount := sys(-1, newcount)   */
                   a = count;
                   count = Wp[4];
                   res = -1;
                   goto ret;
                 }
               }
               a = dosys(p, g); 
               goto fetch;                          /* system call */

   case F_lp0+16:  b = a; a = Wp[16]; goto fetch;
   case F_lp0+15:  b = a; a = Wp[15]; goto fetch;
   case F_lp0+14:  b = a; a = Wp[14]; goto fetch;
   case F_lp0+13:  b = a; a = Wp[13]; goto fetch;
   case F_lp0+12:  b = a; a = Wp[12]; goto fetch;
   case F_lp0+11:  b = a; a = Wp[11]; goto fetch;
   case F_lp0+10:  b = a; a = Wp[10]; goto fetch;
   case F_lp0+9:   b = a; a = Wp[9];  goto fetch;
   case F_lp0+8:   b = a; a = Wp[8];  goto fetch;
   case F_lp0+7:   b = a; a = Wp[7];  goto fetch;
   case F_lp0+6:   b = a; a = Wp[6];  goto fetch;
   case F_lp0+5:   b = a; a = Wp[5];  goto fetch;
   case F_lp0+4:   b = a; a = Wp[4];  goto fetch;
   case F_lp0+3:   b = a; a = Wp[3];  goto fetch;

   case F_lp:   b = a; a = Wp[B[pc++]];          goto fetch;
   case F_lph:  b = a; a = Wp[GH(pc)];  pc += 2; goto fetch;
   case F_lpw:  b = a; a = Wp[GW(pc)];  pc += 4; goto fetch;

   case F_llp:  b = a; a = p+B[pc++];             goto fetch;
   case F_llph: b = a; a = p+GH(pc);     pc += 2; goto fetch;
   case F_llpw: b = a; a = p+GW(pc);     pc += 4; goto fetch;

   case F_sp0+16: Wp[16] = a; goto fetch;
   case F_sp0+15: Wp[15] = a; goto fetch;
   case F_sp0+14: Wp[14] = a; goto fetch;
   case F_sp0+13: Wp[13] = a; goto fetch;
   case F_sp0+12: Wp[12] = a; goto fetch;
   case F_sp0+11: Wp[11] = a; goto fetch;
   case F_sp0+10: Wp[10] = a; goto fetch;
   case F_sp0+9:  Wp[9]  = a; goto fetch;
   case F_sp0+8:  Wp[8]  = a; goto fetch;
   case F_sp0+7:  Wp[7]  = a; goto fetch;
   case F_sp0+6:  Wp[6]  = a; goto fetch;
   case F_sp0+5:  Wp[5]  = a; goto fetch;
   case F_sp0+4:  Wp[4]  = a; goto fetch;
   case F_sp0+3:  Wp[3]  = a; goto fetch;

   case F_sp:    Wp[B[pc++]] = a;                  goto fetch;
   case F_sph:   Wp[GH(pc)]  = a;         pc += 2; goto fetch;
   case F_spw:   Wp[GW(pc)]  = a;         pc += 4; goto fetch;

   case F_lgh:   b = a; a = Wg[GH(pc)];   pc += 2; goto fetch;
   case F_lg1:   b = a; a = Wg1[B[pc++]];          goto fetch;
   case F_lg:    b = a; a = Wg[B[pc++]];           goto fetch;

   case F_sgh:   Wg[GH(pc)]   = a;        pc += 2; goto fetch;
   case F_sg1:   Wg1[B[pc++]] = a;                 goto fetch;
   case F_sg:    Wg[B[pc++]]  = a;                 goto fetch;

   case F_llgh: b = a; a = g+GH(pc);      pc += 2; goto fetch;
   case F_llg1: b = a; a = g+256+B[pc++];          goto fetch;
   case F_llg:  b = a; a = g+B[pc++];              goto fetch;

   case F_ll+1: i = (pc>>1) + B[pc];
                i = (i<<1) + SH[i];
                b = a; a = W[i>>2];          pc++; goto fetch;

   case F_ll:   b = a; a = W[(pc+SB[pc])>>2];pc++; goto fetch;

   case F_sl+1: i = (pc>>1) + B[pc];
                i = (i<<1) + SH[i];
                W[i>>2] = a;                 pc++; goto fetch;

   case F_sl:   W[(pc+SB[pc])>>2] = a;       pc++; goto fetch;
   
   case F_lll+1:i = (pc>>1) + B[pc];
                i = (i<<1) + SH[i];
                b = a; a = i>>2;             pc++; goto fetch;

   case F_lll:  b = a; a = (pc+SB[pc])>>2;   pc++; goto fetch;
   
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

   case F_l:     b = a; a = B[pc++];               goto fetch;
   case F_lh:    b = a; a = GH(pc);       pc += 2; goto fetch;
   case F_lw:    b = a; a = GW(pc);       pc += 4; goto fetch;

   case F_lm:    b = a; a = - WD(B[pc++]);         goto fetch;
   case F_lmh:   b = a; a = - WD(GH(pc)); pc += 2; goto fetch;
                
   case F_lf+1:  b = a;
                 a = (pc>>1) + B[pc];
                 a = (a<<1) + SH[a];         pc++; goto fetch;

   case F_lf:    b = a; a = pc + SB[pc];     pc++; goto fetch;
 
   case F_k0gh+11: Wp[11] = p<<2; p += 11; goto applygh;
   case F_k0gh+10: Wp[10] = p<<2; p += 10; goto applygh;
   case F_k0gh+9:  Wp[ 9] = p<<2; p +=  9; goto applygh;
   case F_k0gh+8:  Wp[ 8] = p<<2; p +=  8; goto applygh;
   case F_k0gh+7:  Wp[ 7] = p<<2; p +=  7; goto applygh;
   case F_k0gh+6:  Wp[ 6] = p<<2; p +=  6; goto applygh;
   case F_k0gh+5:  Wp[ 5] = p<<2; p +=  5; goto applygh;
   case F_k0gh+4:  Wp[ 4] = p<<2; p +=  4; goto applygh;
   case F_k0gh+3:  Wp[ 3] = p<<2; p +=  3;
   applygh:        Wp    = W+p;
                   Wp[1] = pc + 2;
                   pc    = Wg[GH(pc)];
                   Wp[2] = pc;
                   Wp[3] =  a;
                   if (pc>=0) goto fetch;
                   goto negpc;

   case F_k0g1+11: Wp[11] = p<<2; p += 11; goto applyg1;
   case F_k0g1+10: Wp[10] = p<<2; p += 10; goto applyg1;
   case F_k0g1+9:  Wp[ 9] = p<<2; p +=  9; goto applyg1;
   case F_k0g1+8:  Wp[ 8] = p<<2; p +=  8; goto applyg1;
   case F_k0g1+7:  Wp[ 7] = p<<2; p +=  7; goto applyg1;
   case F_k0g1+6:  Wp[ 6] = p<<2; p +=  6; goto applyg1;
   case F_k0g1+5:  Wp[ 5] = p<<2; p +=  5; goto applyg1;
   case F_k0g1+4:  Wp[ 4] = p<<2; p +=  4; goto applyg1;
   case F_k0g1+3:  Wp[ 3] = p<<2; p +=  3;
   applyg1:        Wp    = W+p;
                   Wp[1] = pc + 1;
                   pc    = Wg1[B[pc]];
                   Wp[2] = pc;
                   Wp[3] = a;
                   if (pc>=0) goto fetch;
                   goto negpc;
 
   case F_k0g+11: Wp[11] = p<<2; p += 11; goto applyg;
   case F_k0g+10: Wp[10] = p<<2; p += 10; goto applyg;
   case F_k0g+9:  Wp[ 9] = p<<2; p +=  9; goto applyg;
   case F_k0g+8:  Wp[ 8] = p<<2; p +=  8; goto applyg;
   case F_k0g+7:  Wp[ 7] = p<<2; p +=  7; goto applyg;
   case F_k0g+6:  Wp[ 6] = p<<2; p +=  6; goto applyg;
   case F_k0g+5:  Wp[ 5] = p<<2; p +=  5; goto applyg;
   case F_k0g+4:  Wp[ 4] = p<<2; p +=  4; goto applyg;
   case F_k0g+3:  Wp[ 3] = p<<2; p +=  3;
   applyg:        Wp    = W+p;
                  Wp[1] = pc + 1;
                  pc    = Wg[B[pc]];
                  Wp[2] = pc;
                  Wp[3] = a;
                  if (pc>=0) goto fetch;
                  goto negpc;
 
   case F_k0+11:  Wp[11] = p<<2; p += 11; goto applyk;
   case F_k0+10:  Wp[10] = p<<2; p += 10; goto applyk;
   case F_k0+9:   Wp[ 9] = p<<2; p +=  9; goto applyk;
   case F_k0+8:   Wp[ 8] = p<<2; p +=  8; goto applyk;
   case F_k0+7:   Wp[ 7] = p<<2; p +=  7; goto applyk;
   case F_k0+6:   Wp[ 6] = p<<2; p +=  6; goto applyk;
   case F_k0+5:   Wp[ 5] = p<<2; p +=  5; goto applyk;
   case F_k0+4:   Wp[ 4] = p<<2; p +=  4; goto applyk;
   case F_k0+3:   Wp[ 3] = p<<2; p +=  3;
   applyk:        Wp    = W+p;
                  Wp[1] = WD pc;
                  pc    = a;
                  Wp[2] = pc;
                  Wp[3] = a = b;
                  if (pc>=0) goto fetch;
                  goto negpc;

   case F_k:      k = B[pc]; Wp[k] = p<<2; p +=  k;
                  Wp    = W+p;
                  Wp[1] = pc + 1;
                  pc    = a;
                  Wp[2] = pc;
                  Wp[3] = a = b;
                  if (pc>=0) goto fetch;
                  goto negpc;

   case F_kh:     k = GH(pc); Wp[k] = p<<2; p +=  k;
                  Wp    = W+p;
                  Wp[1] = pc + 2;
                  pc    = a;
                  Wp[2] = pc;
                  Wp[3] = a = b;
                  if (pc>=0) goto fetch;
                  goto negpc;

   case F_kw:     k = GW(pc); Wp[k] = p<<2; p +=  k;
                  Wp    = W+p;
                  Wp[1] = pc + 4;
                  pc    = a;
                  Wp[2] = pc;
                  Wp[3] = a = b;
                  if (pc>=0) goto fetch;
                  goto negpc;

   case F_jeq:   if(b==a) { pc += SB[pc];   goto fetch; }
                 pc++; goto fetch;
   case F_jeq+1: if(b==a) goto indjump;
                 pc++; goto fetch;
   case F_jeq+2: if(a==0) { pc += SB[pc];   goto fetch; }
                 pc++; goto fetch;
   case F_jeq+3: if(a==0) goto indjump;
                 pc++; goto fetch;

   case F_jne:   if(b!=a) { pc += SB[pc];   goto fetch; }
                 pc++; goto fetch;
   case F_jne+1: if(b!=a) goto indjump;
                 pc++; goto fetch;
   case F_jne+2: if(a!=0) { pc += SB[pc];   goto fetch; }
                 pc++; goto fetch;
   case F_jne+3: if(a!=0) goto indjump;
                 pc++; goto fetch;

   case F_jls:   if(b<a) { pc += SB[pc];   goto fetch; }
                 pc++; goto fetch;
   case F_jls+1: if(b<a) goto indjump;
                 pc++; goto fetch;
   case F_jls+2: if(a<0) { pc += SB[pc];   goto fetch; }
                 pc++; goto fetch;
   case F_jls+3: if(a<0) goto indjump;
                 pc++; goto fetch;

   case F_jgr:   if(b>a) { pc += SB[pc];   goto fetch; }
                 pc++; goto fetch;
   case F_jgr+1: if(b>a) goto indjump;
                 pc++; goto fetch;
   case F_jgr+2: if(a>0) { pc += SB[pc];   goto fetch; }
                 pc++; goto fetch;
   case F_jgr+3: if(a>0) goto indjump;
                 pc++; goto fetch;

   case F_jle:   if(b<=a) { pc += SB[pc];   goto fetch; }
                 pc++; goto fetch;
   case F_jle+1: if(b<=a) goto indjump;
                 pc++; goto fetch;
   case F_jle+2: if(a<=0) { pc += SB[pc];   goto fetch; }
                 pc++; goto fetch;
   case F_jle+3: if(a<=0) goto indjump;
                 pc++; goto fetch;

   case F_jge:   if(b>=a) { pc += SB[pc];   goto fetch; }
                 pc++; goto fetch;
   case F_jge+1: if(b>=a) goto indjump;
                 pc++; goto fetch;
   case F_jge+2: if(a>=0) { pc += SB[pc];   goto fetch; }
                 pc++; goto fetch;
   case F_jge+3: if(a>=0) goto indjump;
                 pc++; goto fetch;

   case F_j:     pc += SB[pc];        goto fetch;

 indjump:
   case F_j+1:   pc = (pc>>1) + B[pc];
                 pc = (pc<<1) + SH[pc];
                 goto fetch;

   case F_ap0+12: a = a + Wp[12]; goto fetch;
   case F_ap0+11: a = a + Wp[11]; goto fetch;
   case F_ap0+10: a = a + Wp[10]; goto fetch;
   case F_ap0+9:  a = a + Wp[ 9]; goto fetch;
   case F_ap0+8:  a = a + Wp[ 8]; goto fetch;
   case F_ap0+7:  a = a + Wp[ 7]; goto fetch;
   case F_ap0+6:  a = a + Wp[ 6]; goto fetch;
   case F_ap0+5:  a = a + Wp[ 5]; goto fetch;
   case F_ap0+4:  a = a + Wp[ 4]; goto fetch;
   case F_ap0+3:  a = a + Wp[ 3]; goto fetch;

   case F_ap:    a += Wp[B[pc++]];         goto fetch;
   case F_aph:   a += Wp[GH(pc)]; pc += 2; goto fetch;
   case F_apw:   a += Wp[GW(pc)]; pc += 4; goto fetch;
   case F_agh:   a += Wg[GH(pc)]; pc += 2; goto fetch;
   case F_ag1:   a += Wg1[B[pc++]];        goto fetch;
   case F_ag:    a += Wg[B[pc++]];         goto fetch;

   case F_a0+5: a += 5; goto fetch;
   case F_a0+4: a += 4; goto fetch;
   case F_a0+3: a += 3; goto fetch;
   case F_a0+2: a += 2; goto fetch;
   case F_a0+1: a += 1; goto fetch;
   case F_nop:          goto fetch;

   case F_a:    a += B[pc++];           goto fetch;
   case F_ah:   a += GH(pc);   pc += 2; goto fetch;
   case F_aw:   a += GW(pc);   pc += 4; goto fetch;
   case F_s:    a -= B[pc++];           goto fetch;
   case F_sh:   a -= GH(pc);   pc += 2; goto fetch;

   case F_s0+4: a -= 4; goto fetch;
   case F_s0+3: a -= 3; goto fetch;
   case F_s0+2: a -= 2; goto fetch;
   case F_s0+1: a -= 1; goto fetch;

   case F_l0p0+12: b = a; a = W[Wp[12]+0]; goto fetch;
   case F_l0p0+11: b = a; a = W[Wp[11]+0]; goto fetch;
   case F_l0p0+10: b = a; a = W[Wp[10]+0]; goto fetch;
   case F_l0p0+9:  b = a; a = W[Wp[ 9]+0]; goto fetch;
   case F_l0p0+8:  b = a; a = W[Wp[ 8]+0]; goto fetch;
   case F_l0p0+7:  b = a; a = W[Wp[ 7]+0]; goto fetch;
   case F_l0p0+6:  b = a; a = W[Wp[ 6]+0]; goto fetch;
   case F_l0p0+5:  b = a; a = W[Wp[ 5]+0]; goto fetch;
   case F_l0p0+4:  b = a; a = W[Wp[ 4]+0]; goto fetch;
   case F_l0p0+3:  b = a; a = W[Wp[ 3]+0]; goto fetch;

   case F_l1p0+6:  b = a; a = W[Wp[ 6]+1]; goto fetch;
   case F_l1p0+5:  b = a; a = W[Wp[ 5]+1]; goto fetch;
   case F_l1p0+4:  b = a; a = W[Wp[ 4]+1]; goto fetch;
   case F_l1p0+3:  b = a; a = W[Wp[ 3]+1]; goto fetch;

   case F_l2p0+5:  b = a; a = W[Wp[ 5]+2]; goto fetch;
   case F_l2p0+4:  b = a; a = W[Wp[ 4]+2]; goto fetch;
   case F_l2p0+3:  b = a; a = W[Wp[ 3]+2]; goto fetch;

   case F_l3p0+4:  b = a; a = W[Wp[ 4]+3]; goto fetch;
   case F_l3p0+3:  b = a; a = W[Wp[ 3]+3]; goto fetch;

   case F_l4p0+4:  b = a; a = W[Wp[ 4]+4]; goto fetch;
   case F_l4p0+3:  b = a; a = W[Wp[ 3]+4]; goto fetch;

   case F_l0gh:  b = a; a = W[Wg[GH(pc)]+0]; pc += 2; goto fetch;
   case F_l1gh:  b = a; a = W[Wg[GH(pc)]+1]; pc += 2; goto fetch;
   case F_l2gh:  b = a; a = W[Wg[GH(pc)]+2]; pc += 2; goto fetch;
   case F_l0g1:  b = a; a = W[Wg1[B[pc++]]+0];        goto fetch;
   case F_l1g1:  b = a; a = W[Wg1[B[pc++]]+1];        goto fetch;
   case F_l2g1:  b = a; a = W[Wg1[B[pc++]]+2];        goto fetch;
   case F_l0g:   b = a; a = W[Wg[B[pc++]]+0];         goto fetch;
   case F_l1g:   b = a; a = W[Wg[B[pc++]]+1];         goto fetch;
   case F_l2g:   b = a; a = W[Wg[B[pc++]]+2];         goto fetch;

   case F_s0gh:  W[Wg[GH(pc)]+0] = a;        pc += 2; goto fetch;
   case F_s0g1:  W[Wg1[B[pc++]]+0] = a;               goto fetch;
   case F_s0g:   W[Wg[B[pc++]]+0] = a;                goto fetch;

   case F_stp0+5: W[a+Wp[5]] = b; goto fetch;
   case F_stp0+4: W[a+Wp[4]] = b; goto fetch;
   case F_stp0+3: W[a+Wp[3]] = b; goto fetch;

   case F_st0p0+4: W[Wp[4]+0] = a; goto fetch;
   case F_st0p0+3: W[Wp[3]+0] = a; goto fetch;

   case F_st1p0+4: W[Wp[4]+1] = a; goto fetch;
   case F_st1p0+3: W[Wp[3]+1] = a; goto fetch;
   
   case F_rvp0+7: a = W[a+Wp[7]]; goto fetch;
   case F_rvp0+6: a = W[a+Wp[6]]; goto fetch;
   case F_rvp0+5: a = W[a+Wp[5]]; goto fetch;
   case F_rvp0+4: a = W[a+Wp[4]]; goto fetch;
   case F_rvp0+3: a = W[a+Wp[3]]; goto fetch;
   }

negpc:
   res = 4;  /* negative pc  */ 
ret:
   W[regs+0]  = a;    /* Save the machine registers  */
   W[regs+1]  = b;
   W[regs+2]  = c;
   W[regs+3]  = p<<2;
   W[regs+4]  = g<<2;
   W[regs+5]  = st;
   W[regs+6]  = pc;
   W[regs+7]  = count;
   
   return res;
}

