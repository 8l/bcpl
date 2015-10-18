/*
** This is CLIB for native code BCPL.
**
** It is based on cintmain.c from the BCPL Cintcode system and is
** meant to run on most machines with a Unix-like C libraries.
**
** (c) Copyright:  Martin Richards  21 April 2004
**
** This code contains many improvements suggested by Colin Liebenrood.
**
*/

/*
21/4/04  Made many changes and improvements suggested by Colin Liebenrood
7/11/96  Systematic changes to allow 64 bit implementation on the ALPHA
23/7/96  First implementation
*/

#include <stdio.h>
#include <stdlib.h>
#include <signal.h>

/* bcpl.h contains machine/system dependent #defines  */
#include "bcpl.h"

static WORD result2;
static WORD *parms;  // vector of command-line arguments
static WORD ttyinp;  // true if stdin is a tty

/* prototypes for forward references */
static WORD muldiv(WORD a, WORD b, WORD c);
static char *b2c_str(WORD bstr, char *cstr);
static WORD c2b_str(char *cstr, WORD bstr);

#define Globword  0xEFEF0000L
#define Gn_result2    10

int badimplementation(void)
{ int bad = 0, A='A';
  SIGNEDCHAR c = 255;
  if(sizeof(WORD)!=BPW || A!=65) bad = 1;
  if (c/-1 != 1) { printf("There is a problem with SIGNEDCHAR\n");
                   bad = 1;
                 }
  return bad;
}

void initfpvec(void)    { return; }
WORD newfno(FILE *fp)   { return WD fp; }
WORD freefno(WORD fno)  { return fno; }
FILE *findfp(WORD fno)  { return (FILE *)fno; }

/* storage for SIGINT handler */
void (*old_handler)(int);

void handler(int sig)
{ 
  printf("SIGINT received\n");
  old_handler = signal(SIGINT, old_handler);
  close_keyb();
  exit(20);
}

int main(int argc, char *argv[])
{ WORD i;      /* for FOR loops  */

  if ( badimplementation() )
  { printf("This implementation of C is not suitable\n");
    return 20;
  }

  parms = (WORD *)(MALLOC(argc+1));
  parms[0] = argc > 1 ? argc : 0;
  for (i = 0; i < argc; i++) {
    WORD v = (WORD)(MALLOC(1+strlen(argv[i]) / BPW)) >> B2Wsh;
    c2b_str(argv[i], v);
    parms[1+i] = v;
  }

  old_handler = signal(SIGINT, handler);
  initfpvec();

  WORD *globbase  = (WORD *)(calloc((gvecupb +1), BPW));
  if(globbase==0) 
    { printf("unable to allocate space for globbase\n");
      exit(20);
    }

  WORD *stackbase = (WORD *)(calloc((stackupb+1), BPW));
  if(stackbase==0) 
    { printf("unable to allocate space for stackbase\n");
      exit(20);
    }

  globbase[0] = gvecupb;

  for (i=1;i<=gvecupb;i++) globbase[i] = Globword + i;
  for (i=0;i<=stackupb;i++) stackbase[i] = 0;

  initsections(globbase);
  ttyinp = init_keyb();

  /* Enter BCPL start function: callstart is defined in mlib.s */
  WORD res = callstart(stackbase, globbase);

  close_keyb();

  if (res) printf("\nExecution finished, return code %ld\n", (long)res);

  free(globbase);
  free(stackbase);
  free(parms);

  return res;
}


WORD muldiv(WORD a, WORD b, WORD c)
{ WORD q=0, r=0, qn, rn;
  int qneg=0, rneg=0;
  if(c==0) c=1;
  if(a<0) { qneg=!qneg; rneg=!rneg; a = -a; }
  if(b<0) { qneg=!qneg; rneg=!rneg; b = -b; }
  if(c<0) { qneg=!qneg;             c = -c; }
  
  qn = b / c;
  rn = b % c;
  
  while(a)
  { if(a&1) { q += qn;
              r += rn;
              if(r>=c) { q++; r -= c; }
            }
    a  >>= 1;
    qn <<= 1;
    rn <<= 1;
    if(rn>=c) {qn++; rn -= c; }
  }
  result2 = rneg ? -r : r;
  return qneg ? -q : q;
}

static char chbuf[256], chbuf2[256]; /* to hold filenames */

int relfilename(char *name)
{ if(name[0]==FILE_SEP_CH ||
     /* The following is fiddle for MSDOS/Windows */
     FILE_SEP_CH=='\\' && 'A'<=name[0] && name[0]<='Z' && name[1]==':')
       return 0; /* Absolute file names don't use paths */
  return 1; 
}

FILE *pathinput(char *name, char *pathname)
{ FILE *fp = fopen(name, "r");
  char filename[1024];
  int itemsep = FILE_SEP_CH=='/' ? ':' : ';';
  if (fp==0)
  { if (pathname && relfilename(name))
    { char *path = getenv(pathname);
      while(path && fp==0)
      { char *f=filename,
             *n=name;
        while(*path==itemsep) path++;
        if(*path==0) break;
        while(*path!=0 && *path!=itemsep) *f++ = *path++;
        if(f[-1]!=FILE_SEP_CH) *f++ = FILE_SEP_CH;
        while(*n) *f++ = *n++;
        *f = 0;
        fp = fopen(filename, "r");
      }
    }
  }
  return fp;
}

/* dosys(P, G) called from mlib.s in response to
** BCPL call res := sys(n, x, y, ....). Arguments p & g are the
** OCODE stack-pointer P and Global vector pointer G. The arguments
** to sys() are n = p[3], x = p[4] ....
** sys(0, r) is trapped in mlib.s
*/

WORD dosys(register WORD *p, register WORD *g)
{ register WORD i;

  switch((int)(p[3]))
  {  default: printf("\nBad sys %ld\n", (long)p[3]);  return p[3];
  
     case 10: { WORD ch = Readch();
                if (ttyinp) {  // echo tty input only
                   if (ch>=0) putchar((char)ch);
                   if(ch==13) { ch = 10; putchar(10); }
                   fflush(stdout);
		}
                return ch;
              }

     case 11: if(p[4] == 10) putchar(13);
              putchar((char)p[4]);
              fflush(stdout);
              return 0;

     case 12: { FILE *fp = findfp(p[4]);
                char *bbuf = (char *)(p[5]<<B2Wsh);
                WORD len   = p[6];
                len = fread(bbuf, (size_t)1, (size_t)len, fp);
                return len;
              }

     case 13: { FILE *fp = findfp(p[4]);
                char *bbuf = (char *)(p[5]<<B2Wsh);
                WORD len = p[6];
                len = WD fwrite(bbuf, (size_t)1, (size_t)len, fp);
                fflush(fp);
                return len;
              }

     case 14: { FILE *fp = pathinput(b2c_str(p[4], chbuf),
                                     b2c_str(p[5], chbuf2));
                if (fp==0) return 0L;
                return newfno(fp);
              }
     case 15: { FILE *fp = fopen(b2c_str(p[4], chbuf), "w");
                if(fp==0) return 0L;
                return newfno(fp);
              }

     case 16: { WORD res = ! fclose(findfp(p[4]));
                freefno(p[4]);
                return res;
              }
     case 17: return ! REMOVE(b2c_str(p[4], chbuf));
     case 18: REMOVE(b2c_str(p[5], chbuf2));
              return ! rename(b2c_str(p[4], chbuf), chbuf2);

     case 21: return ((WORD)(malloc((1+p[4])*BPW)))>>B2Wsh;
     case 22: free((void *)(p[4]<<B2Wsh));                      return 0;
/*
     case 23: return loadseg(b2c_str(p[4], chbuf));
     case 24: return globin(p[4], g);
     case 25: unloadseg(p[4]);                    return 0;
*/
     case 26: { WORD res =  muldiv(p[4], p[5], p[6]);
                g[Gn_result2] = result2;
                return res;
              }
/*
     case 27: return setraster(p[4], p[5]);
*/
     case 28: return intflag() ? -1L : 0L;

     case 29: return 0; /* was aptovec(f, upb) */

     case 30: /* Return CPU time in milliseconds  */
              return muldiv(clock(), 1000, TICKS_PER_SEC);

     case 31: /* Return time of last modification of file
                 whose name is in p[4]  */
              { struct stat buf;
                if (stat(b2c_str(p[4], chbuf), &buf)) return 0;
                return buf.st_mtime;
              }

	      // cases 32-34 not used

     case 35: { /* Return system date and time in VEC 5 */
              time_t clk = time(0);
	      struct tm *now = gmtime(&clk);
	      WORD *arg = PT(p[4] << B2Wsh);
              arg[0] = now->tm_year+1900;
	      arg[1] = now->tm_mon+1;
	      arg[2] = now->tm_mday;
	      arg[3] = now->tm_hour;
	      arg[4] = now->tm_min;
	      arg[5] = now->tm_sec;
              return 0;
     }

     case 36: { /* Return current directory in VEC 1 + 256/bytesperword */
              getcwd(chbuf, 256);
              c2b_str(chbuf, p[4]);
              return 0;
    }
    case 37:  return (WORD)parms >> B2Wsh;
  }
} 

/* b2c_str converts the BCPL string for a file name to a C character
** string.  The character '/' (or '\') is treated as a separator and is
** converted to FILE_SEP_CH ('/' for unix, '\' for MSDOS or ':' for MAC)
*/
char *b2c_str(WORD bstr, char * cstr)
{  char *bp, i, len;
   if (bstr==0) return 0;
   bp = (char *)(bstr<<B2Wsh);
   len = *bp++;
   for(i = 0; i<len; i++)
   { char ch = *bp++;
     if(ch=='/' || ch=='\\') ch = FILE_SEP_CH;
     cstr[i] = ch;
   }
   cstr[len] = 0;
   return cstr;
} 

/*
** c2b_str converts a C string into a BCPL string
*/
WORD c2b_str(char *cstr, WORD bstr) {
  char *bp = (char *)(bstr << B2Wsh);
  int len = 0;
  while (cstr[len]) {
    bp[len+1] = cstr[len];
      ++len;
  }
  bp[0] = len;
  return bstr;
}
