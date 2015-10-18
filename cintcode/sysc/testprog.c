#include <stdio.h>

#define BCPLWORD int
#define SHP (short *)
#define SH (SHP W)
#define HP (unsigned short *)
#define H (HP W)
#define B ((unsigned char *)W)

extern BCPLWORD tst(BCPLWORD, BCPLWORD, BCPLWORD*);

int main() {
  BCPLWORD W[10000000];
  BCPLWORD a, pc, tab;

  pc = 51621;

  //skip over possible fill, n and the default label
  tab = ((pc+1)>>1)+2;

  // Fill in n, the defauilt label and the case labels
  SH[tab-2] = 128;   // the table size
  SH[tab-1] = -2000; // default rel address
  for(a=0; a<128; a++) SH[tab+a] = -(1000+a);

  for(a=0; a<100; a++) tst(a,pc,W);

  return 0;
}

BCPLWORD tst(BCPLWORD a, BCPLWORD pc, BCPLWORD*W) {
  switch(a) {
    default: //break;

    case 93:
    { BCPLWORD n,q;
      q = (pc+1)>>1;
      n = H[q++];
      if(0<=a && a<n) q += a+1;
      pc = (q<<1) + SH[q];
printf("case 93: a=%d n=%d q=%d SH[q]=%d pc=%d\n", a, n, q, SH[q], pc);
      break;
    }
  }

  return pc;
}
