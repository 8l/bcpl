#include <stdio.h>

#define INT32 int

INT32 result2, result2a;

INT32 muldiva(INT32 a, INT32 b, INT32 c)
{ long ab, q, r, la=a, lb=b, lc=c;
  int qneg=0, rneg=0;
  if(lc==0) lc=1;
  if(la<0) { qneg=!qneg; rneg=!rneg; la = -la; }
  if(lb<0) { qneg=!qneg; rneg=!rneg; lb = -lb; }
  if(lc<0) { qneg=!qneg;             lc = -lc; }
  
  ab = la*lb;
  q = (long) (((double)ab) / ((double) lc));
  r = ab - lc*q;
  if (r<0)        { r += lc; q--; }
  else if (r>=lc) { r -= lc; q++; }
  if(r<0 || r>=lc) printf("%8lx, %8lx, %8lx  r =  %8lx\n",
                            la, lb, lc, r);

  result2a= rneg ? -r : r;
  return qneg ? -q : q;
}

INT32 muldiv(INT32 a, INT32 b, INT32 c)
{ INT32 q=0, r=0, qn, rn;
  unsigned long la=a, lb=b, lc=c;
  int qneg=0, rneg=0;
  if(lc==0) lc=1;
  if(la<0) { qneg=!qneg; rneg=!rneg; la = -la; }
  if(lb<0) { qneg=!qneg; rneg=!rneg; lb = -lb; }
  if(lc<0) { qneg=!qneg;             lc = -lc; }
  
  qn = lb / lc;
  rn = lb % lc;
  
  while(la)
  { if(la&1) { q += qn;
               r += rn;
               if(r>=lc) { q++; r -= lc; }
            }
    la  >>= 1;
/*    la = la & 0x7FFFFFFF;*/
    qn <<= 1;
    rn <<= 1;
    if(rn>=lc) {qn++; rn -= lc; }
  }
  result2 = rneg ? -r : r;
  return qneg ? -q : q;
}

void try(INT32 a, INT32 b, INT32 c)
{ INT32 x = muldiv(a, b, c), y = muldiva(a, b, c);
  printf("muldiv (%8x, %8x, %8x) = %8x,  remainder %8x\n",
          a, b, c, x, result2);
  printf("muldiva(%8x, %8x, %8x) = %8x,  remainder %8x\n\n",
          a, b, c, y, result2a);
}

int main()
{ int i,j,k;
  INT32 w = 0x80000000;

  try(4,5,6);
  try(-5,6,7);
  try(-5,-6,7);
  try(-5,6,-7);
  try(5,-6,7);
  try(5,-6,-7);
  try( 5000000, 6000000, 7000000);
  try( 5000000, 6000000,-7000000);
  try( 5000000,-6000000, 7000000);
  try( 5000000,-6000000,-7000000);
  try(-5000000, 6000000, 7000000);
  try(-5000000, 6000000,-7000000);
  try(-5000000,-6000000, 7000000);
  try(-5000000,-6000000,-7000000);
  
  for(i=-2; i<=2; i++)
  for(j=-2; j<=2; j++)
  for(k=-2; k<=2; k++) try(w+i, w+j, w+k);
}


