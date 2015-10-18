/*
** This is a 32 bit CINTCODE interpreter written in C
** with modifications for the Cintpos system.
**
** (c) Copyright:  Martin Richards  October 2010
**
** If FASTyes if defined, most of the debugging aids are
** disabled making it functionally equivalent to the
** handwritten assembly code versions provided for some
** architectures.
**
** The fast version defines the function cintasm
** while the slow version defines interpret.

09/04/10
Put time the time stamp (days, msecs) in the rootnode every 10000 cintcode
instructions.
*/

#ifndef forSHwinCE
#include <stdio.h>
#include <stdlib.h>
#endif

/* cintsys.h contains machine/system dependent #defines  */
#include "cintsys.h"

#ifndef FASTyes

#define TRACINGyes
#define TALLYyes
#define WATCHyes
#define MEMCHKyes
#define COUNTyes

#endif

#ifdef MEMCHKyes
#define MC1(a) if((UBCPLWORD)a>memupb){W[3]=a; res=12; pc--;  goto ret; }
#define MC2(a) if((UBCPLWORD)a>memupb){W[3]=a; res=12; pc-=2; goto ret; }
#define MC3(a) if((UBCPLWORD)a>memupb){W[3]=a; res=12; pc-=3; goto ret; }
#define MC5(a) if((UBCPLWORD)a>memupb){W[3]=a; res=12; pc-=5; goto ret; }
#else
#define MC1(a)
#define MC2(a)
#define MC3(a)
#define MC5(a)
#endif

extern BCPLWORD result2;

extern BCPLWORD *lastWp;    /* Latest setting of Wp */
extern BCPLWORD *lastWg;    /* Latest setting of Wg */

extern int tracing;
extern BCPLWORD memupb;
UBCPLWORD memupbb;

extern BCPLWORD *tallyv;
extern BCPLWORD tallylim;

#ifdef TALLYyes
UBCPLWORD tallylimb;
#endif

extern BCPLWORD dosys(BCPLWORD p, BCPLWORD g);
extern BCPLWORD doflt(BCPLWORD op, BCPLWORD a, BCPLWORD b);
extern BCPLWORD muldiv(BCPLWORD a, BCPLWORD b, BCPLWORD c);

extern void wrcode(char *form, BCPLWORD f, BCPLWORD a); 
extern void wrfcode(BCPLWORD f);
extern void trace(BCPLWORD pc, BCPLWORD p, BCPLWORD a, BCPLWORD b);
extern BCPLWORD timestamp(BCPLWORD *datstamp);


#define Gn_currco      7
#define Gn_result2    10

/* CINTCODE function codes  */

#define F_0       0

#define F_fltop   1
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

#define F_mw    223

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

#define F_selld 254
#define F_selst 255
#define F_255   255

#define sf_none    0     // Assignment operators
#define sf_vecap   1
#define sf_fmul    2
#define sf_fdiv    3
#define sf_fadd    4
#define sf_fsub    5
#define sf_mul     6
#define sf_div     7
#define sf_rem     8
#define sf_add     9
#define sf_sub    10
#define sf_lshift 11
#define sf_rshift 12
#define sf_logand 13
#define sf_logor  14
#define sf_eqv    15
#define sf_neqv   16

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

//    -2      sys(Sys_dumpmem) cause a memory dump to DUMP.mem
//    -1 *    sys(Sys_setcount, val) called
//     0 *    sys(Sys_quit, 0) called
//     1      Non existent instruction
//     2      Brk instruction
//     3      Zero count
//     4      PC too large or negative
//     5      Division by zero
//    10      Cintasm single step trap
//    11      Contents of watch address has changed
//    12      Memory address too large or negative
//    13      SIGINT received
//    14      Unknown floating point operation
//    15
//    16      P pointer too large or negative
//     n      sys(Sys_quit, n) called
//
// On return the Cintcode registers are dumped back in the vector regs
*/

#ifdef FASTyes
extern BCPLWORD *watchaddr, watchval;
#else
BCPLWORD *watchaddr=0, watchval=0;
#endif

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

//#ifndef NOFLOAT

//static float itof(BCPLWORD a) {
//  union { BCPLWORD i; float f; } x;
//  x.i = a;
//  return x.f;
//}

//#endif

#ifdef FASTyes
int cintasm(BCPLWORD regs, BCPLWORDpt mem)
#else
int interpret(BCPLWORD regs, BCPLWORDpt mem)
#endif

{  BCPLWORDpt W = mem;

   register int icount = 0;

   register BCPLWORD           a  = W[regs+0];
   register BCPLWORD           b  = W[regs+1];
   BCPLWORD                    c  = W[regs+2];
   BCPLWORD                    p  = W[regs+3]>>B2Wsh;
   BCPLWORD                    g  = W[regs+4]>>B2Wsh;
   BCPLWORD                    st = W[regs+5];
   register BCPLWORD           pc = W[regs+6];
   BCPLWORD                    count = W[regs+7];
   BCPLWORD                    mw = W[regs+8];

   register BCPLWORDpt Wp  = W+p,    /* Optimise access to the stack */
                       Wg  = W+g,    /* Optimise access to the global vector */
                       Wg1 = W+g+256;

   BCPLWORD res, k, i;

   UBCPLWORD memupbb = memupb<<B2Wsh;

#ifdef TALLYyes
   UBCPLWORD tallylimb = tallylim<<B2Wsh;
#endif

   /*   tracing = 1; */

fetchchk:
   // Check PC is in range
   if((UBCPLWORD)pc > memupbb) goto badpc;

fetch:

#ifdef WATCHyes
   /* Special watch debugging aid */
   if(watchaddr && *watchaddr!=watchval)
   { /*
       printf("%7" FormD ": changed from %7" FormD "(%8" FormX ") to %7" FormD
              "(%8" FormX ")\n",
              watchaddr-W, watchval, (UBCPLWORD)watchval,
              *watchaddr, (UBCPLWORD)*watchaddr);
     */
     watchval = *watchaddr;
     W[1] = watchaddr-W;
     W[2] = watchval;
     res = 11;        /* Contents of watch address has changed */
     goto ret;
   }
   /* End of watch code */
#endif

   /* count>=0  means execute count instructions (slow interpreter)
      count=-1  means go on for ever (fast interpreter)
      count=-2  means single step the fast interpreter
   */
#ifdef COUNTyes
   if (count>=0)
   { if (count==0) { res = 3; goto ret; }
     count--;
   }
#endif

#ifdef TRACINGyes
   if (tracing) trace(pc, p, a, b);
#endif

#ifdef TALLYyes
   if ((UBCPLWORD)pc < tallylimb) tallyv[pc]++;
#endif

if(--icount<=0) {
  // Update the days and msecs fields in the rootnode
  timestamp(&W[rootnode+Rtn_days]);
  icount = 10000;
  // icount     bench100 time
  //   1      923.370
  //   10      99.780
  //   100     16.040
  //   1000     7.470
  //   10000    6.600 (gcc -O9)
  //   100000   6.510 (gcc -O3)
  //            5.550 without this code omitted (gcc -O1)
  //trpush(0x11000000+W[rootnode+Rtn_msecs]);
}

// Uncommenting the next line increase the bench100 time
// from 6.310 to 7.180 and is not a very useful check.
//if((UBCPLWORD)p > memupbb) { res = 16; goto ret; }

switch(B[pc++])
{  default:
   case F_0:     /* Cases F_0 and F_255 have been added explicitly to   */
     //case F_255:   /* improve the compiled code (with luck)               */
                 res = 1; pc--; goto ret; /* Unimplemented instruction  */

     // Added 21/7/10
   case F_fltop:
     { BCPLWORD op = B[pc++];

#ifdef NOFLOAT
       a = 0;
       goto fetch;
#else
       //printf("fltop op=%" FormD "\n", op);
       switch (op) {
       default:
         res = 14; pc -=2; goto ret;

       case fl_avail:
         a = -1; goto fetch;

       case fl_mk:
       { BCPLWORD exponent = B[pc++]; // Signed byte
         if (exponent>=128) exponent = exponent-256;
	 //printf("fl_mk calling doflt(%" FormD ", %" FormD ", %" FormD ")\n",
         //        op, a, exponent);
         a = doflt(op, a, exponent);
         goto fetch;
       }

       case fl_float:
       case fl_fix:
       case fl_pos:
       case fl_neg:
       case fl_abs:
         a = doflt(op, a, 0);
         goto fetch;

       case fl_mul:
       case fl_div:
       case fl_add:
       case fl_sub:
       case fl_eq:
       case fl_ne:
       case fl_ls:
       case fl_gr:
       case fl_le:
       case fl_ge:
         a = doflt(op, b, a);
         goto fetch;
       }
#endif
     }

     // Added 21/7/10
   case F_selld:  // load a field  SELLD len sh
     { BCPLWORD len = B[pc++];
       BCPLWORD sh  = B[pc++];
       BCPLWORD mask = -1;
       if (len) mask = (1<<len) - 1;
       a = (W[a]>>sh) & mask;
       goto fetch;
     }

     // Added 21/7/10
   case F_selst: // SLCT len:sh:0 OF <arg1> op:= <arg2>
                 //      len sh         a   op      b
     { BCPLWORD *ptr = &W[a];
       BCPLWORD op  = B[pc++];
       BCPLWORD len = B[pc++];
       BCPLWORD sh  = B[pc++];
       BCPLWORD mask;
       BCPLWORD val;
       BCPLWORD oldval;
       union IorF { BCPLWORD i; float f; } x, y;

       if(len==0) {
         mask = UWD(-1) >> sh;
       } else {
         mask = (1<<len) - 1;
       }
       val = WD(((UWD*ptr)>>sh)) & mask;
       oldval = val; // Old value shifted down

       // val and oldval are both the old field value shifted down
       switch(op) {
       default:          a = 0; goto fetch;
       case sf_none:     val = b;                 break;
       case sf_vecap:    val = W[val + b];        break;
       case sf_fmul:     x.i = val; y.i = b;
                         x.f = x.f * y.f;
                         val = x.i;               break;
       case sf_fdiv:     x.i = val; y.i = b;
                         x.f = x.f / y.f;
                         val = x.i;               break;
       case sf_fadd:     x.i = val; y.i = b;
                         x.f = x.f + y.f;
                         val = x.i;               break;
       case sf_fsub:     x.i = val; y.i = b;
                         x.f = x.f - y.f;
                         val = x.i;               break;
       case sf_mul:      val *= b;                break;
       case sf_div:      val /= b;                break;
       case sf_rem:      val %= b;                break;
       case sf_add:      val += b;                break;
       case sf_sub:      val -= b;                break;
       case sf_lshift:   if (b>=BperW) val=0; /* bug */
                         val <<= b;               break;
       case sf_rshift:   if (b>=BperW) val=0; /* bug */
	                 val = WD((UWD val)>>b);  break;
       case sf_logand:   val &= b;                break;
       case sf_logor:    val |= b;                break;
       case sf_eqv:      val = ~(val ^ b);        break;
       case sf_neqv:     val ^= b;                break;
       }
       //printf("selst: op=%" FormD " len=%" FormD " sh=%" FormD
       //         " oldval=%08" FormX " val=%08" FormX " mask=%08" FormX "\n",
       //       op, len, sh, (UBCPLWORD)oldval, (UBCPLWORD)val, (UBCPLWORD)mask);
       // Replace field by new value
       *ptr ^= ((val ^ oldval)&mask) << sh;
       goto fetch;
     }

   case F_mul:   a = b * a;        goto fetch;
   case F_div:   if(a==0) {res = 5; pc--; goto ret; } /* Division by zero */
                 a = b / a;        goto fetch;
   case F_rem:   if(a==0) {res = 5; pc--; goto ret; } /* Division by zero */
                 a = b % a;        goto fetch;
   case F_add:   a = b + a;        goto fetch;
   case F_sub:   a = b - a;        goto fetch;
   case F_neg:   a = - a;          goto fetch;

   case F_fhop:  a = 0; pc++;      goto fetch;

   case F_lsh:   if (a>=BperW) b=0; /* bug */
                 a = b << a;       goto fetch;
   case F_rsh:   if (a>=BperW) b=0; /* bug */
                 a = WD((UWD b)>>a); goto fetch;
   case F_not:   a = ~ a;          goto fetch;
   case F_and:   a = b & a;        goto fetch;
   case F_or:    a = b | a;        goto fetch;
   case F_xor:   a = b ^ a;        goto fetch;

   case F_goto:  pc = a;           goto fetchchk;

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

   case F_chgco: W[Wg[Gn_currco]] = Wp[0]; /* !currco := !p    */
                 pc = Wp[1];               /* pc      := p!1   */
                 Wg[Gn_currco] = Wp[4];    /* currco  := cptr  */
                 p = W[Wp[4]]>>B2Wsh;      /* p       := !cptr */
                 Wp = W+p;
                 goto fetchchk;

   case F_mdiv:
               { BCPLINT64 ab = (BCPLINT64)(Wp[3]) * (BCPLINT64)(Wp[4]);
                 BCPLWORD c = Wp[5];
                 if(c==0) c=1;
                 Wg[Gn_result2] = (BCPLWORD)(ab % c);
                 a = (BCPLWORD)(ab / c);
                 /* fall through to return  */
               }
   case F_rtn:   pc = Wp[1];
                 p  = W[p]>>B2Wsh;
                 Wp = W+p; 
                 goto fetchchk;

   case F_gbyt: a = B[a+(b<<B2Wsh)];
                goto fetch;
   case F_pbyt: B[a+(b<<B2Wsh)] = (char)c;  goto fetch;
   case F_xpbyt:B[b+(a<<B2Wsh)] = (char)c;  goto fetch;
   case F_atc:  c = a;                      goto fetch;
   case F_btc:  c = b;                      goto fetch;
   case F_atb:  b = a;                      goto fetch;
   case F_xch:  a = a^b; b = a^b; a = a^b;  goto fetch;

   case F_swb: { BCPLWORD n, k, val, i=1;
                 k = (pc+1)>>1;
                 n = H[k];
                 while(i<=n)
                 { i += i;
                   val = H[k+i];
                   if (a==val) { k += i; break; }
                   if (a<val) i++;
                 }
                 k++;
                 pc = (k<<1) + SH[k];
                 goto fetchchk;
               }

   case F_swl: { BCPLWORD n,q;
                 q = (pc+1)>>1;
                 n = H[q++];
                 if(0<=a && a<n) q += a + 1;
                 pc = (q<<1) + SH[q];
                 goto fetchchk;
               }

   case F_sys: switch(a) {
                 default: // system call -- general case
 
		         W[regs+0]  = a;    /* Save all the registers */
		         W[regs+1]  = b;    /* for debugging purposes */
                         W[regs+2]  = c;
                         W[regs+3]  = p<<B2Wsh;
                         W[regs+4]  = g<<B2Wsh;
                         W[regs+5]  = st;
                         W[regs+6]  = pc;
                         W[regs+7]  = count;
                         W[regs+8]  = mw;
  
                         a = dosys(p, g); 
                         goto fetch;

                 case Sys_setcount:
                         /* oldcount := sys(Sys_setcount, newcount)  */
                         a = count; 
		         count = Wp[4];
                         res = -1; /* Leave and immediately re-enter */
                         goto ret; /* the interpreter */

                 case Sys_quit:
                         res = Wp[4];
                         goto ret;

	      /*
                 case Sys_rti:  //  sys(Sys_rti, regs)
                 case Sys_saveregs: // sys(Sys_saveregs, regs)
                 case Sys_setst: // sys(Sys_setst, st)
              */
		 case Sys_watch:  /* sys(Sys_watch, addr) */
                       { watchaddr = &W[Wp[4]];
	                 watchval = *watchaddr;
                         goto fetch;
                       }
               }

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
                b = a; a = W[i>>B2Wsh];          pc++; goto fetch;

   case F_ll:   b = a; a = W[(pc+SB[pc])>>B2Wsh];pc++; goto fetch;

   case F_sl+1: i = (pc>>1) + B[pc];
                i = (i<<1) + SH[i];
                W[i>>B2Wsh] = a;                 pc++; goto fetch;

   case F_sl:   W[(pc+SB[pc])>>B2Wsh] = a;       pc++; goto fetch;
   
   case F_lll+1:i = (pc>>1) + B[pc];
                i = (i<<1) + SH[i];
                b = a; a = i>>B2Wsh;             pc++; goto fetch;

   case F_lll:  b = a; a = (pc+SB[pc])>>B2Wsh;   pc++; goto fetch;
   
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
 
   case F_k0gh+11: Wp[11] = p<<B2Wsh; p += 11; goto applygh;
   case F_k0gh+10: Wp[10] = p<<B2Wsh; p += 10; goto applygh;
   case F_k0gh+9:  Wp[ 9] = p<<B2Wsh; p +=  9; goto applygh;
   case F_k0gh+8:  Wp[ 8] = p<<B2Wsh; p +=  8; goto applygh;
   case F_k0gh+7:  Wp[ 7] = p<<B2Wsh; p +=  7; goto applygh;
   case F_k0gh+6:  Wp[ 6] = p<<B2Wsh; p +=  6; goto applygh;
   case F_k0gh+5:  Wp[ 5] = p<<B2Wsh; p +=  5; goto applygh;
   case F_k0gh+4:  Wp[ 4] = p<<B2Wsh; p +=  4; goto applygh;
   case F_k0gh+3:  Wp[ 3] = p<<B2Wsh; p +=  3;
   applygh:        Wp    = W+p;
                   Wp[1] = pc + 2;
                   pc    = Wg[GH(pc)];
                   Wp[2] = pc;
                   Wp[3] =  a;
                   goto fetchchk;

   case F_k0g1+11: Wp[11] = p<<B2Wsh; p += 11; goto applyg1;
   case F_k0g1+10: Wp[10] = p<<B2Wsh; p += 10; goto applyg1;
   case F_k0g1+9:  Wp[ 9] = p<<B2Wsh; p +=  9; goto applyg1;
   case F_k0g1+8:  Wp[ 8] = p<<B2Wsh; p +=  8; goto applyg1;
   case F_k0g1+7:  Wp[ 7] = p<<B2Wsh; p +=  7; goto applyg1;
   case F_k0g1+6:  Wp[ 6] = p<<B2Wsh; p +=  6; goto applyg1;
   case F_k0g1+5:  Wp[ 5] = p<<B2Wsh; p +=  5; goto applyg1;
   case F_k0g1+4:  Wp[ 4] = p<<B2Wsh; p +=  4; goto applyg1;
   case F_k0g1+3:  Wp[ 3] = p<<B2Wsh; p +=  3;
   applyg1:        Wp    = W+p;
                   Wp[1] = pc + 1;
                   pc    = Wg1[B[pc]];
                   Wp[2] = pc;
                   Wp[3] = a;
                   goto fetchchk;
 
   case F_k0g+11: Wp[11] = p<<B2Wsh; p += 11; goto applyg;
   case F_k0g+10: Wp[10] = p<<B2Wsh; p += 10; goto applyg;
   case F_k0g+9:  Wp[ 9] = p<<B2Wsh; p +=  9; goto applyg;
   case F_k0g+8:  Wp[ 8] = p<<B2Wsh; p +=  8; goto applyg;
   case F_k0g+7:  Wp[ 7] = p<<B2Wsh; p +=  7; goto applyg;
   case F_k0g+6:  Wp[ 6] = p<<B2Wsh; p +=  6; goto applyg;
   case F_k0g+5:  Wp[ 5] = p<<B2Wsh; p +=  5; goto applyg;
   case F_k0g+4:  Wp[ 4] = p<<B2Wsh; p +=  4; goto applyg;
   case F_k0g+3:  Wp[ 3] = p<<B2Wsh; p +=  3;
   applyg:        Wp    = W+p;
                  Wp[1] = pc + 1;
                  pc    = Wg[B[pc]];
                  Wp[2] = pc;
                  Wp[3] = a;
                  goto fetchchk;
 
   case F_k0+11:  Wp[11] = p<<B2Wsh; p += 11; goto applyk;
   case F_k0+10:  Wp[10] = p<<B2Wsh; p += 10; goto applyk;
   case F_k0+9:   Wp[ 9] = p<<B2Wsh; p +=  9; goto applyk;
   case F_k0+8:   Wp[ 8] = p<<B2Wsh; p +=  8; goto applyk;
   case F_k0+7:   Wp[ 7] = p<<B2Wsh; p +=  7; goto applyk;
   case F_k0+6:   Wp[ 6] = p<<B2Wsh; p +=  6; goto applyk;
   case F_k0+5:   Wp[ 5] = p<<B2Wsh; p +=  5; goto applyk;
   case F_k0+4:   Wp[ 4] = p<<B2Wsh; p +=  4; goto applyk;
   case F_k0+3:   Wp[ 3] = p<<B2Wsh; p +=  3;
   applyk:        Wp    = W+p;
                  Wp[1] = WD pc;
                  pc    = a;
                  Wp[2] = pc;
                  Wp[3] = a = b;
                  goto fetchchk;

   case F_k:      k = B[pc]; Wp[k] = p<<B2Wsh; p +=  k;
                  Wp    = W+p;
                  Wp[1] = pc + 1;
                  pc    = a;
                  Wp[2] = pc;
                  Wp[3] = a = b;
                  goto fetchchk;

   case F_kh:     k = GH(pc); Wp[k] = p<<B2Wsh; p +=  k;
                  Wp    = W+p;
                  Wp[1] = pc + 2;
                  pc    = a;
                  Wp[2] = pc;
                  Wp[3] = a = b;
                  goto fetchchk;

   case F_kw:     k = GW(pc); Wp[k] = p<<B2Wsh; p +=  k;
                  Wp    = W+p;
                  Wp[1] = pc + 4;
                  pc    = a;
                  Wp[2] = pc;
                  Wp[3] = a = b;
                  goto fetchchk;

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

   // mv is only used in 64-bit Cintcode
   // Commented out to avoid a warning
   //case F_mw:   mw = GW(pc)<<32;   pc += 4; goto fetch;

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

badpc:
   res = 4;  /* pc too large or negative  */
 
ret:
   tracing = 0;
   //printf("cinterp: returning from interpret, res=%" FormD "\n", res);
   W[regs+0]  = a;    /* Save the machine registers  */
   W[regs+1]  = b;
   W[regs+2]  = c;
   W[regs+3]  = p<<B2Wsh;
   W[regs+4]  = g<<B2Wsh;
   W[regs+5]  = st;
   W[regs+6]  = pc;
   W[regs+7]  = count;
   W[regs+8]  = mw;

   /* Save p in currco resumption point, for debugging purposes     */
   /* currco must always be set to the coroutine stack containing p */
   //W[Wg[Gn_currco]] = p;
   
   return res;  // Return from this invocation of interpret
}

