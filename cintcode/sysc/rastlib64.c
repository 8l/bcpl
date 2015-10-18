/* A new version of rastlib that generated a relatively compact
** file using run length encoding
**
** K1000              1000 instruction per raster line
** W10B3W1345B1N      10 white 3 black 1345 white 1 black newline
** W13B3W12B2N        etc
** ...
*/

#include <stdio.h>
#include <stdlib.h>

/* cinterp.h contains machine/system dependent #defines  */
#include "cintsys64.h"

/* Upb of address references buffer */
#define UPB 50000

static FILE *rasterfile;
static BCPLWORD addr[UPB+1], addp;
static BCPLWORD p=0;
static BCPLWORD count=1000, scale=12, fcounttrig;
BCPLWORD fcount=0;

extern char *b2c_fname(BCPLWORD bstr, char *cstr);
extern char *osfname(char *name, char *osname);

static void wrline(void);

static int initraster(char *filename)
{ fcounttrig = count;
  addp = 0;
  fcount = 0;
  rasterfile = fopen(filename, "w");
  fprintf(rasterfile, "K%" FormD " S%" FormD "\n", count, scale);
  if(rasterfile) return 0;
  return 1;
}


static int endraster(void)
{ if (rasterfile)
  { wrline();
    return fclose(rasterfile); // Return 0 if successful
  }
  return -1;
}

BCPLWORD setraster(BCPLWORD n, BCPLWORD val)
{ char chbuf[256];
  switch((int)n)
  { case 0: if (val) return initraster(osfname(val, chbuf));
            else     return endraster(); // Return 0 if successful
            return 1;
    case 1: if(val>=0) count = val; return count;
    case 2: if(val>=0) scale = val; return scale;
    case 3: return 0;  // Rastering is available
  }
}

void sort(BCPLWORD p, BCPLWORD q)
{ if(p<q)
  { BCPLWORD t;
    BCPLWORD m = addr[(p+q)>>1];
    BCPLWORD i=p, j=q;
    while(1)
    { while(addr[i]<m) i++;
      /* all k in p..i-1 => addr[k]<m
      ** addr[i] >= m
      */
      while(j>i && addr[j]>=m) j--;
      /* all k in j+1 .. q => addr[k]>=m
      ** j>=i
      */
      if(i==j) break;
      /* j>i and addr[i]>m and addr[j]<m
      */
      t = addr[i];
      addr[i] = addr[j];
      addr[j] = t;
      /* j>i and addr[i]<m and addr[j]>m
      */
      i++;
    }
    sort(p, i-1);
    j = q;
    while(1)
    { while(i<=j && addr[i]==m) i++;
      while(addr[j]!=m) j--;
      if (j<i) break;
      addr[j] = addr[i];
      addr[i] = m;
      i++;
    }
    sort(i, q);
  }
}

static void wrline(void)
{ BCPLWORD i=1, k, a=0, b;
  sort(1, addp);
  while(i<=addp && addr[i]<0) i++;
  
  while(i<=addp)
  { 
    b = addr[i++]; /* addr of next black */
    k = b-a;       /* white count, possibly zero */
    fprintf(rasterfile, "W%ld", (long)k);
    a = b; /* start of next black region */
    /* find next white */
    b++;
    while (i<=addp && addr[i]<=b) b=addr[i++]+1; 
    k = b-a;
    a = b; /* start of next white region */
    fprintf(rasterfile, "B%ld", (long)k);
  }
  fprintf(rasterfile, "N\n");
  addp = 0;
  fcounttrig += count;
  if(fcount%1000000==0) printf("fcount = %ld\n", (long)fcount);
}

void rasterpoint(BCPLWORD p)
{ BCPLWORD a = p/scale;
  if (addp<UPB) addr[++addp] = a;
/*  printf("%7ld %7ld\n", (long)addp, (long)a);*/
  if (fcount >= fcounttrig) wrline();
}





