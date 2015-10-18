/*
** This is a 32 bit CINTCODE interpreter written in C designed
** to run on most machines with a Unix-like C libraries.
** It was originally implemented on a MAC+  in 1991 using LightspeedC,
** compatibility with this machine has not been maintained.
** It runs on the IBM PC under MSDOS in 32 bit protected mode using
** Borland C version 4.0. It also once ran under OS/2 using
** IBM's Cset/2 compiler.
** Other Unix systems on which it is known to work are:
**    DEC Mips workstations run Ultrix 4.3
**    DEC Alpha machines running OSF/1
**    Sun4m       running SunOS 4.1
**    Sun4m sparc running SunOS 5.4
**    IBM PC running Linux
**
** (c) Copyright:  Martin Richards  24 November 1995
**
*/

/*
5/4/00
Added -m and -t command line options to specify the Cintcode memory
size and tally vector size in thousands of words.
Added the -h option.
6/1/00
Made changes to make cintmain.c more compatible with the
Windows CE version.
26/2/99
Changed loadseg to accept binary hunks as well as hex hunks.
6/11/98  Implemented changes to replace sys(14,name) by
         sys(14,name,pathname). If pathname is 0 or the specified
         shell variable is unset, there should be no noticeable
         difference. The new version searches for the file in the
         current working directory, then the directories given by
         the shell variable pathname until successfully opened.
         It is designed to work on both Windows and unix. The 
         convention will be that if the shell variable is set
         it will specify a path used by loadseg (ie the initial
         loading of SYSLIB, BOOT, BLIB, CLI and CLI commands) as
         well as for header files. There are small related changes
         to libhdr, BLIB.b and bcpl.b.
5/11/98  The comment character in object modules has changed from
         semicolon(';') to hash ('#').
12/6/96  Move the definition of INT32pt, WD, UWD, PT, BP, SBP, HP
         and SHP to cinterp.h, and define SIGNEDCHAR in cinterp.h
         to solve a problem with char being unsigned on some
         implementations.
31/5/96  Added handler for SIGINT to restore tty settings
30/4/96  Added call of fflush(fp) to case 13: in dosys, with
         corresponding changes to libhdr and BLIB.b (added flush())
24/11/95 Improve the efficiency of the calls of fread and fwrite
         Reduce the size of chbuf from 1024 to 256
25/10/95 Use ANSI clock() instead of ftime(), adding TICKS_PER_MS.
         Change #define names to forMAC, forMIPS, forSUN4 etc
         Add and set external tallyv
18/10/95 Remove compatibility with non protected mode MSDOS (now
         using Borland C version 4.0).
24/9/93  Replace word by INT32
         Put in code for DEC Alpha and Sun-4 machines
         The #define is now in the Makefile
         Change to Ansi C conventions
         Other minor modifications in main and dosys
22/6/93  Remove aptovec
24/5/93  Allow ';' comments in object modules (mainly for SYSLIB)
*/


//#include <stdio.h>
//#include <stdlib.h>
//#include <signal.h>

/* cinterp.h contains machine/system dependent #defines  */
#include "cinterp.h"

FILEPT logfp = NULL;

/* Functions defined in kblib.c  */
extern int Readch(void);
extern int init_keyb(void);
extern int close_keyb(void);
extern int intflag(void);

/* Functions defined in rastlib.c (or nrastlib.c)  */
extern INT32 setraster(INT32 n, INT32 val);

/* Function defined in graphics.c  */
extern INT32 sysGraphics(INT32 p);

#define Stackupb     500L
#define Globupb      250L

#define Rtn_membase   0L
#define Rtn_memsize   1L
#define Rtn_blklist   2L
#define Rtn_tallyv    3L
#define Rtn_syslib    4L
#define Rtn_blib      5L
#define Rtn_boot      6L
#define Rtn_upb      20L

INT32pt W;  /* This will hold the pointer to the Cintcode memory */

INT32 prefix = 0; // Position in the Cintcode memory of the filename
                  // prefix. Zero means no prefix. The prefix is 
                  // prepended to all non absolute file names.
                  // prefix is set by sys(32, str) 
                  // and read by sys(33).

INT32 bstring,
      rootregs,
      rootnode,
      stackbase,
      globbase,
      result2;

int tracing = 0;

INT32 memupb, tallyupb, tallyvec, *tallyv, tallylim=0;

INT32 loadseg(INT32 name);
void unloadseg(INT32 segl);
INT32 rdhex(FILEPT fp);
INT32 globin(INT32 segl, INT32 g);
INT32 getvec(INT32 upb);
void freevec(INT32 p);
INT32 muldiv(INT32 a, INT32 b, INT32 c);
FILEPT pathinput(INT32 name, char *pathname);
INT32 dosys(INT32 p, INT32 g);
char *b2c_fname(INT32 bstr, char *cstr);
char *b2c_str(INT32 bstr, char *cstr);
INT32 c2b_str(char *cstr, INT32 bstr);
void wrcode(char *form, INT32 f, INT32 a);
void wrfcode(INT32 f);
void trace(INT32 pc, INT32 p, INT32 a, INT32 b);

extern int cintasm(INT32 regs, INT32pt mem);
extern int interpret(INT32 regs, INT32pt mem);

#define Globword  0xEFEF0000L

#define Gn_globsize    0
#define Gn_start       1
#define Gn_currco      7
#define Gn_colist      8
#define Gn_rootnode    9
#define Gn_result2    10

/* relocatable object blocks  */
#define T_hunk  1000L
#define T_bhunk 3000L
#define T_end   1002L

int badimplementation(void)
{ int bad = 0, A='A';
  SIGNEDCHAR c = (SIGNEDCHAR)255;
  if(sizeof(INT32)!=4 || A!=65) bad = 1;
  if (c/-1 != 1) { printfd("There is a problem with SIGNEDCHAR\n", 0);
                   bad = 1;
                 }
  return bad;
}

/* The following four functions are necessary since the type FILE*
** is too large for a BCPL word on some machines (such as the DEC Alpha)
*/

#ifdef forALPHA
#define Fnolim 100

FILEPT fpvec[Fnolim];

int initfpvec(void)
{ INT32 i;
  for(i=1;i<Fnolim;i++) fpvec[i]=NULL;
  return 0;
}

INT32 newfno(FILEPT fp)
{ INT32 i;
  for(i=1;i<Fnolim;i++) if(fpvec[i]==NULL){ fpvec[i]=fp; return i; }
  return 0;
}

INT32 freefno(INT32 fno)
{ if(0<fno && fno<Fnolim){fpvec[fno]=NULL; return 1; }
  return 0;
}

FILEPT findfp(INT32 fno)
{ if(0<fno && fno<Fnolim) return fpvec[fno];
  return 0;
}

#else

int   initfpvec(void)    { return 0; }
INT32 newfno(FILEPT fp)   { return WD fp; }
INT32 freefno(INT32 fno) { return fno; }
FILEPT findfp(INT32 fno)  { return (FILEPT )fno; }

#endif


int main(int argc, char* argv[])
{  INT32 i;      /* for FOR loops  */
   INT32 res;    /* result of interpret  */
   argc = 0;     /* temporary fiddle for Windows CE */
   memupb   = 2000000L;
   tallyupb = 80000L;

   for (i=1; i<argc; i++) {
     if (strcmp(argv[i], "-m")==0) {
       memupb   = 1000 * atoi(argv[++i]);
       continue;
     }
     if (strcmp(argv[i], "-k")==0) {
       tallyupb = 1000 * atoi(argv[++i]);
       continue;
     }
     if (strcmp(argv[i], "-h")!=0) printfd("Unknown command option\n", 0);

     printfd("\nValid arguments:\n\n", 0) ;
     printfd("-h    -- Output this help information\n", 0);
     printfd("-m n  -- Set Cintcode memory size to 1000n words\n", 0);
     printfd("-t n  -- Set Tally vector size to 1000n words\n", 0);
     return 0;
   }

   if (memupb<50000 || tallyupb<0) {
     printfd("Bad -m or -k size\n", 0);
     return 10;
   }

   if(badimplementation())
   { printfd("This implementation of C is not suitable\n", 0);
     return 0;
   }

   initfpvec();

   W = PT MALLOC(memupb+tallyupb+3);

   if(W==NULL)
   { printfd("Insufficient memory for memvec\n", 0);
     return 0;
   }
   W = PT(((long) W + 3L) & -4L);

   W[0] = memupb+1;  /* Initialise heap space */
   W[memupb] = 0;

   tallylim = 0;
   tallyvec = memupb+1;
   tallyv = &W[tallyvec];
   tallyv[0] = tallyupb;
   for(i=1; i<=tallyupb; i++) tallyv[i] = 0;

   bstring   = getvec(8L);       // Workspace for c2b_str
   rootregs  = getvec(8L);
   rootnode  = getvec(Rtn_upb);
   stackbase = getvec(Stackupb);
   globbase  = getvec(Globupb);
   result2 = 0L;

   for(i = 0; i<=Globupb; i++) W[globbase+i] = Globword+i;
   W[globbase+Gn_globsize] = Globupb;
   W[globbase+Gn_rootnode] = rootnode;

   W[rootnode+Rtn_membase] = 0;
   W[rootnode+Rtn_memsize] = memupb;
   W[rootnode+Rtn_blklist] = 0;
   W[rootnode+Rtn_tallyv]  = tallyvec;
   W[rootnode+Rtn_syslib]  = globin(loadseg(c2b_str("SYSLIB",bstring)), globbase);
   if (W[rootnode+Rtn_syslib]==0) printfd("Failed to load SYSLIB\n", 0);
   W[rootnode+Rtn_blib]    = globin(loadseg(c2b_str("BLIB",bstring)),   globbase);
   if (W[rootnode+Rtn_blib]==0) printfd("Failed to load BLIB\n", 0);
   W[rootnode+Rtn_boot]    = globin(loadseg(c2b_str("BOOT",bstring)),   globbase);
   if (W[rootnode+Rtn_boot]==0) printfd("Failed to load BOOT\n", 0);

   for(i=0; i<=Stackupb; i++) W[stackbase+i] = 0;

   W[rootregs+0] = 0;                /* A      */
   W[rootregs+1] = 0;                /* B      */
   W[rootregs+2] = 0;                /* C      */
   W[rootregs+3] = stackbase<<2;     /* P      */
   W[rootregs+4] = globbase<<2;      /* G      */
   W[rootregs+5] = 0;                /* ST     */
   W[rootregs+6] = W[globbase+1];    /* PC     */
   W[rootregs+7] = -1;               /* Count  */

   init_keyb();
   res = interpret(rootregs, W);
   close_keyb();

   if (res) printfd("\nExecution finished, return code %ld\n", (long)res);

   return res;
}

INT32 loadseg(INT32 file)
{ INT32 list  = 0;
  INT32 liste = 0;

  FILEPT fp = pathinput(file, "BCPLPATH");
  if(fp==NULL) return 0;
  for(;;)
  { INT32 type = rdhex(fp);

    switch((int)type)
    { default:
          err:    unloadseg(list);
                  list = 0;
      case -1:    fclose(fp);
                  return list;

      case T_hunk:
               {  INT32 i, n=rdhex(fp);
                  INT32 space = getvec(n);
                  if(space==0) goto err;
                  W[space] = 0;
                  for(i = 1; i<=n; i++) W[space+i] = rdhex(fp);
                  if(list==0) list=space;
                  else W[liste] = space;
                  liste = space;
                  continue;
                }

      case T_bhunk: /* For hunks in binary (not hex) */
               {  INT32 n;
                  INT32 space;
                  int len = fread((char *)&n, (size_t)4, (size_t)1, fp);
                  if (len!=1 && len!=4) goto err;
                  space = getvec(n);
                  if(space==0) goto err;
                  W[space] = 0;
                  len = fread((char *)&W[space+1], (size_t)4, (size_t)n, fp);
                  if (len!=n && len!=4*n) goto err;
                  if(list==0) list=space;
                  else W[liste] = space;
                  liste = space;
                  continue;
                } 

      case T_end:;
    }
  }
} 

void unloadseg(INT32 segl)
{ while(segl) { INT32 s = W[segl];
                freevec(segl);
                segl = s;
              }
}

/* rdhex reads in one hex number including the terminating character
   and returns its INT32 value. EOF returns -1.
*/
INT32 rdhex(FILEPT fp)
{  INT32 w = 0;
   int ch = fgetc(fp);

   while(ch==' ' || ch=='\n' || ch=='\r') ch = fgetc(fp);

   if (ch=='#') { /* remove comments from object modules */
                  while (ch != '\n' && ch != EOF) ch = fgetc(fp);
                  return rdhex(fp);
                }

   for(;;)
   {  int d = 100;
      if('0'<=ch && ch<='9') d = ch-'0';
      if('A'<=ch && ch<='F') d = ch-'A'+10;
      if('a'<=ch && ch<='f') d = ch-'a'+10;

      if(d==100) return ch==EOF ? -1 : w;
      w = (w<<4) | d;
      ch = fgetc(fp);
   }
}

INT32 globin(INT32 segl, INT32 g)
{ INT32  a = segl, globsize = W[g];
 
  while (a) { INT32 base = (a+1)<<2;
              INT32 i = a + W[a+1];
              if (W[i]>globsize) return 0;
              for(;;) { i -= 2;
                        if (W[i+1]==0) break;
                        W[g+W[i]] = base + W[i+1];
                      }
              a = W[a];
            }
  return segl;
}

INT32 getvec(INT32 upb)
{ INT32 p;
  INT32 q = 0; /* the start of the block list */
  INT32 n = (upb+3) & 0xFFFFFFFE;  /* round up to an even size */
  
  do
  { p = q;
    for(;;) { INT32 size = W[p];
              if((size&1) != 0) break;
              if( size == 0)    return 0;
              p += size;
            }
    q = p;  /* find next used block */
    for(;;) { INT32 size = W[q];
              if((size&1) == 0) break;
              q += size-1;
            }
  } while(q-p<n);
  
  if(p+n!=q) W[p+n] = q-p-n+1;
  W[p] = n;
  return p+1;
}

void freevec(INT32 p)
{ W[p-1] |= 1;
}

INT32 muldiv(INT32 a, INT32 b, INT32 c)
{ unsigned INT32 q=0, r=0, qn, rn;
  unsigned INT32 ua, ub, uc;
  int qneg=0, rneg=0;
  if(c==0) c=1;
  if(a<0) { qneg=!qneg; rneg=!rneg; ua = -a; }
  else                              ua =  a;
  if(b<0) { qneg=!qneg; rneg=!rneg; ub = -b; }
  else                              ub =  b;
  if(c<0) { qneg=!qneg;             uc = -c; }
  else                              uc =  c;
  
  qn = ub / uc;
  rn = ub % uc;
  
  while(ua)
  { if(ua&1) { q += qn;
               r += rn;
               if(r>=c) { q++; r -= uc; }
             }
    ua >>= 1;
    qn <<= 1;
    rn <<= 1;
    if(rn>=uc) {qn++; rn -= uc; }
  }
  result2 = rneg ? -r : r;
  return qneg ? -q : q;
}

static char chbuf[256], chbuf2[256]; /* to hold filenames */

int relfilename(INT32 name)
{ char *bp = BP(&W[name]);
  if(bp[1]=='/' || bp[1]=='\\' ||
     /* The following is fiddle for MSDOS/Windows */
     FILE_SEP_CH=='\\' && 'A'<=bp[1] && bp[1]<='Z' && bp[2]==':')
       return 0; /* Absolute file names don't use paths */
  return 1; 
}

FILEPT pathinput(INT32 name, char *pathname)
{ // First try to open filename name, prefixed by prefix if relative
  FILEPT fp = fopen(b2c_fname(name, chbuf), "r");
  if (fp==0)
  { char filename[256];
    int itemsep = FILE_SEP_CH=='/' ? ':' : ';';
    if (pathname && relfilename(name))
    { char *path = getenv(pathname);
      // Try prefixing with each directory in the path.
      while(path && fp==0)
      { char *f=filename;
        char *n=BP (&W[name]);
        int len = *n++;
        while(*path==itemsep) path++;
        if(*path==0) break;
        while(*path!=0 && *path!=itemsep)
        { char ch = *path++;
          if(ch=='/' || ch=='\\') ch = FILE_SEP_CH;
          *f++ = ch;
        }
        if(f[-1]!=FILE_SEP_CH) *f++ = FILE_SEP_CH;
        while(len--)
        { char ch = *n++;
          if(ch=='/' || ch=='\\') ch = FILE_SEP_CH;
          *f++ = ch;
        }
        *f = 0;
        //printfs("trying filename = %s\n", filename);// busywait(2000);
        fp = fopen(filename, "r");
      }
    }
  }
  return fp;
}

INT32 dosys(register INT32 p, register INT32 g)
{ register INT32 i;
  switch((int)(W[p+3]))
  {  default: printfd("\nBad sys %ld\n", (long)W[p+3]);
              return W[p+3];
  
     case 1: /* use CINTASM if count register is less than 0 */
            { INT32 regsv = W[p+4];
              if(W[regsv+7]<0) return CINTASM  (regsv, W);
              else             return interpret(regsv, W);
            }

     case  2: tracing = 1;                     return 0;
     case  3: tracing = 0;                     return 0;

     case  4: tallylim = tallyupb;
              for(i=1; i<=tallylim; i++) tallyv[i] = 0;
/*              logfp = fopen("LOGFILE", "w");*/
              return 0;
     case  5: tallylim = 0;
/*              fclose(logfp);*/
/*              logfp = NULL;*/
              return 0;

     case 10: { INT32 ch = Readch();
                if (ch>=0) putchar((char)ch);
                if(ch==13) { ch = 10; putchar(10); }
//                fflush(stdout);
                return ch;
              }

     case 11: if(W[p+4] == 10) putchar(13);
              putchar((char)W[p+4]);
//              fflush(stdout);
              return 0;

     case 12: { FILEPT fp = findfp(W[p+4]);
                INT32 bbuf = W[p+5]<<2;
                INT32 len   = (int) W[p+6];
                len = fread(&(BP W)[bbuf], (size_t)1, (size_t)len, fp);
                return len;
              }

     case 13: { FILEPT fp = findfp(W[p+4]);
                INT32 bbuf = W[p+5]<<2;
                INT32 len = W[p+6];
                len = WD fwrite(&(BP W)[bbuf], (size_t)1, (size_t)len, fp);
                fflush(fp);
                return len;
              }

     case 14: { FILEPT fp = pathinput(W[p+4], b2c_str(W[p+5], chbuf2));
                if (fp==0) return 0L;
                return newfno(fp);
              }

     case 15: { FILEPT fp = fopen(b2c_fname(W[p+4], chbuf), "w");
                if (fp==0) return 0L;
                return newfno(fp);
              }

     case 16: { INT32 res = ! fclose(findfp(W[p+4]));
                freefno(W[p+4]);
                return res;
              }
     case 17: return ! REMOVE(b2c_fname(W[p+4], chbuf));
     case 18: REMOVE(b2c_fname(W[p+5], chbuf2));
              return ! rename(b2c_fname(W[p+4], chbuf), chbuf2);

     case 21: return getvec(W[p+4]);
     case 22: freevec(W[p+4]);
              return 0;
     case 23: return loadseg(W[p+4]);
     case 24: return globin(W[p+4], g);
     case 25: unloadseg(W[p+4]);
              return 0;
     case 26: { INT32 res =  muldiv(W[p+4], W[p+5], W[p+6]);
                W[g+Gn_result2] = result2;
                return res;
              }
     case 27: return setraster(W[p+4], W[p+5]);

     case 28: return intflag() ? -1L : 0L;

     case 29: return 0; /* was aptovec(f, upb) */

     case 30: /* Return CPU time in milliseconds  */
              return muldiv(clock(), 1000, TICKS_PER_SEC);

     case 31: /* Return time of last modification of file
                 whose name is in p[4]  */
              return 0;
//              { struct stat buf;
//                if (stat(b2c_fname(W[p+4], chbuf), &buf)) return 0;
//                return buf.st_mtime;
//              }

     case 32: /* Set the file prefix string  */
              prefix = W[p+4];
              return prefix;

     case 33: /* Return the file prefix string  */
              return prefix;

     case 34: /* Perform an operation on the graphics window  */
              return sysGraphics(p);

     case 35: /* Return TRUE if no keyboard character is available */
              return chBufEmpty() ? -1 : 0;
  }
  return 0;
} 

/* b2c_fname converts the BCPL string for a file name to a C character
** string.  The character '/' (or '\') is treated as a separator and is
** converted to FILE_SEP_CH ('/' for unix, '\' for MSDOS or ':' for MAC).
** If prefix is set and the filename is relative, the prefix is prepended.
*/
char *b2c_fname(INT32 bstr, char * cstr)
{  INT32 bp = bstr<<2;
   int len = (BP W)[bp++];
   int i=0;
   if (bstr==0) return 0;
   if (prefix && relfilename(bstr))
   { // Prepend the filename with prefix
     INT32 pfxp = prefix<<2;
     int pfxlen = (BP W)[pfxp++];
     while(pfxlen--)
     { char ch = (BP W)[pfxp++];
       if(ch=='/' || ch=='\\') ch = FILE_SEP_CH;
       cstr[i++] = ch;
     }
     if (cstr[i-1] != FILE_SEP_CH) cstr[i++] = FILE_SEP_CH;
   }

   while (len--)
   { char ch = (BP W)[bp++];
     if(ch=='/' || ch=='\\') ch = FILE_SEP_CH;
     cstr[i++] = ch;
   }
   cstr[i] = 0;
   //if (prefix) { printfs("filename = %s\n", cstr); busywait(2000); }
   return cstr;
}

/* b2c_str converts a BCPL string to a C character string. */
char *b2c_str(INT32 bstr, char * cstr)
{  INT32 bp = bstr<<2;
   char *p = cstr;
   int len = (BP W)[bp++];
   if (bstr==0) return 0;
   while (len--) *p++ = (BP W)[bp++];
   *p = 0;
   return cstr;
}

/* c2b_str converts the C string to a BCPL string. */
INT32 c2b_str(char *cstr, INT32 bstr)
{  char *bp = &(BP W)[bstr<<2];
   int len = 0;
   while (cstr[len]) { bp[len+1] = cstr[len]; len++; }
   bp[0] = len;
   return bstr;
}

void wrcode(char *form, INT32 f, INT32 a)
{  wrfcode(f);
   printfd("  ", 0);
   printfd(form, (long)a);
   printfd("\n", 0);
} 

void wrfcode(INT32 f)
{ char *s;
  int i, n = (f>>5) & 7;
  switch((int)f&31)
  { default:
    case  0: s = "     -     K   LLP     L    LP    SP    AP     A"; break;
    case  1: s = "     -    KH  LLPH    LH   LPH   SPH   APH    AH"; break;
    case  2: s = "   BRK    KW  LLPW    LW   LPW   SPW   APW    AW"; break;
    case  3: s = "    K3   K3G  K3G1  K3GH   LP3   SP3   AP3  L0P3"; break;
    case  4: s = "    K4   K4G  K4G1  K4GH   LP4   SP4   AP4  L0P4"; break;
    case  5: s = "    K5   K5G  K5G1  K5GH   LP5   SP5   AP5  L0P5"; break;
    case  6: s = "    K6   K6G  K6G1  K6GH   LP6   SP6   AP6  L0P6"; break;
    case  7: s = "    K7   K7G  K7G1  K7GH   LP7   SP7   AP7  L0P7"; break;
    case  8: s = "    K8   K8G  K8G1  K8GH   LP8   SP8   AP8  L0P8"; break;
    case  9: s = "    K9   K9G  K9G1  K9GH   LP9   SP9   AP9  L0P9"; break;
    case 10: s = "   K10  K10G K10G1 K10GH  LP10  SP10  AP10 L0P10"; break;
    case 11: s = "   K11  K11G K11G1 K11GH  LP11  SP11  AP11 L0P11"; break;
    case 12: s = "    LF   S0G  S0G1  S0GH  LP12  SP12  AP12 L0P12"; break;
    case 13: s = "   LF$   L0G  L0G1  L0GH  LP13  SP13 XPBYT     S"; break;
    case 14: s = "    LM   L1G  L1G1  L1GH  LP14  SP14   LMH    SH"; break;
    case 15: s = "   LM1   L2G  L2G1  L2GH  LP15  SP15   BTC     -"; break;
    case 16: s = "    L0    LG   LG1   LGH  LP16  SP16   NOP CHGCO"; break;
    case 17: s = "    L1    SG   SG1   SGH   SYS    S1    A1   NEG"; break;
    case 18: s = "    L2   LLG  LLG1  LLGH   SWB    S2    A2   NOT"; break;
    case 19: s = "    L3    AG   AG1   AGH   SWL    S3    A3  L1P3"; break;
    case 20: s = "    L4   MUL   ADD    RV    ST    S4    A4  L1P4"; break;
    case 21: s = "    L5   DIV   SUB   RV1   ST1   XCH    A5  L1P5"; break;
    case 22: s = "    L6   REM   LSH   RV2   ST2  GBYT  RVP3  L1P6"; break;
    case 23: s = "    L7   XOR   RSH   RV3   ST3  PBYT  RVP4  L2P3"; break;
    case 24: s = "    L8    SL   AND   RV4  STP3   ATC  RVP5  L2P4"; break;
    case 25: s = "    L9   SL$    OR   RV5  STP4   ATB  RVP6  L2P5"; break;
    case 26: s = "   L10    LL   LLL   RV6  STP5     J  RVP7  L3P3"; break;
    case 27: s = "  FHOP   LL$  LLL$   RTN  GOTO    J$ ST0P3  L3P4"; break;
    case 28: s = "   JEQ   JNE   JLS   JGR   JLE   JGE ST0P4  L4P3"; break;
    case 29: s = "  JEQ$  JNE$  JLS$  JGR$  JLE$  JGE$ ST1P3  L4P4"; break;
    case 30: s = "  JEQ0  JNE0  JLS0  JGR0  JLE0  JGE0 ST1P4     -"; break;
    case 31: s = " JEQ0$ JNE0$ JLS0$ JGR0$ JLE0$ JGE0$     -     -"; break;
  }

  for(i = 6*n; i<=6*n+5; i++) putchar(s[i]);
} 

void trace(INT32 pc, INT32 p, INT32 a, INT32 b)
{ printfd("%9ld: ", (long)pc);
  printfd("A=%9ld  ", (long)a);
  printfd("B=%9ld    ", (long)b);
  printfd("P=%5ld ", (long)p);
  wrcode("(%3ld)", WD (BP W)[pc], WD (BP W)[pc+1]);
  putchar(13);
}







