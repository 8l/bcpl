/*
** This is CLIB for BCPL compiled into native code
**
** It is based on cintsys.c from the BCPL Cintcode system and is
** meant to run on most machines with a Unix-like C libraries.
**
** (c) Copyright:  Martin Richards  4 September 2009
**
*/

// Test this sort of comment.

/*
Change History

04/09/09
Started to make changes for the Vax under VMS

10/04/06
Made change to natbcpl to make rdch read the command argument characters before
reading from stdin, for compatibility with cintsys.

21/04/04
Made many changes and improvements suggested by Colin Liebenrood

07/11/96
Systematic changes to allow 64 bit implementation on the ALPHA

23/07/96
First implementation
*/

#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <string.h>

#if defined(forVmsItanium) || defined(forVmsVax)
#include <timeb.h>
#else
#include <sys/timeb.h>
#endif

/* bcpl.h contains machine/system dependent #defines  */
#include "bcpl.h"

static BCPLWORD result2;
static BCPLWORD prefix;
BCPLWORD rootnode[Rtn_upb+1];
static char *parms;  /* vector of command-line arguments */
static int  parmp=1; /* subscript of next command-line character. */
static int  ttyinp;  /* =1 if stdin is a tty, =0 otherwise */

/* prototypes for forward references */
static BCPLWORD muldiv(BCPLWORD a, BCPLWORD b, BCPLWORD c);
static char *b2c_fname(BCPLWORD bstr, char *cstr);
static char *vmsfname(char *name, char *vaxname);
static char *b2c_str(BCPLWORD bstr, char *cstr);
static BCPLWORD c2b_str(char *cstr, BCPLWORD bstr);

/* Function normally defined in graphics.c  */
extern BCPLWORD sysGraphics(BCPLWORD *p);
BCPLWORD sysGraphics(BCPLWORD *p) { return 0; } /* Dummy definition */

/* Function defined in mlib.mar */
BCPLWORD callstart(BCPLWORD *p, BCPLWORD *g);

#define Globword      0x8F8F0000L
#define Gn_result2    10

int badimplementation(void)
{ int bad = 0;
  int A='A';
  SIGNEDCHAR c = (SIGNEDCHAR)255;
  if(sizeof(BCPLWORD)!=(1<<B2Wsh)) {
       PRINTF("Size of a BCPL word is not %d\n", 1<<B2Wsh);
       bad = 1;
  }
  if(A!=65) {
       PRINTF("Character set is not ASCII\n");
       bad = 1;
  }
  if (c/-1 != 1) {
    PRINTF("There is a problem with SIGNEDCHAR\n");
    bad = 1;
  }
  return bad;
}

void initfpvec(void)    { return; }
BCPLWORD newfno(FILE *fp)   { return WD fp; }
BCPLWORD freefno(BCPLWORD fno) { return fno; }
FILE *findfp(BCPLWORD fno)  { return (FILE *)fno; }

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
{ int i;      /* for FOR loops  */
  BCPLWORD *globbase;
  BCPLWORD *stackbase;
  BCPLWORD res;

  if ( badimplementation() )
  { printf("This implementation of C is not suitable\n");
    return 20;
  }

  /* Try to reconstruct the command line arguments from argv */
  parms = (char *)(MALLOC(256));

  { int p=0;
    parms[0] = 0;

    for (i=1; i<argc; i++) {
      char *arg = argv[i];
      int len = strlen(arg);
      int j;
      int is_string = 0; /* =1 if arg contains ", space, or newline.white space */
      /*printf("clib: getting command line, len=%d\n", len); */
      for (j=0; j<len; j++)
        if( arg[j]=='"' || arg[j]==' ' || arg[j]=='\n') is_string = 1;
      /*printf("clib: getting command line, is_string=%d\n", is_string); */
      parms[++p] = ' ';
      if(is_string)
      { parms[++p] = '"';
        for (j=0; j<len; j++)
        { int ch = arg[j];
          if(ch=='\n') { parms[p++] = '*'; parms[++p] = 'n'; }
          if(ch=='"')  { parms[p++] = '*'; parms[++p] = '"'; }
	  else parms[++p] = ch;
        }
        parms[++p] = '"';
      } else {
        for (j=0; j<len; j++) parms[++p] = arg[j];
      }
    }
    parms[++p] = '\n';  /* Put a newline at the end of the argument string */
    parms[0] = p; /* Fill in the BCPL string length */
    parmp = 1;    /* Subscript of the first character of the */
                  /* command-line argument */

    /*printf("clib: args: len=%d\n", parms[0]); */
    /*for(i=1; i<=parms[0];i++) printf("parm[%d]=%d\n", i, parms[i]); */
    /*printf("\n"); */
  }

  /*  parms = (BCPLWORD *)(MALLOC(argc+1)); */
  /*parms[0] = argc > 1 ? argc : 0; */
  /*for (i = 0; i < argc; i++) { */
  /*  BCPLWORD v = (BCPLWORD)(MALLOC(1+strlen(argv[i]) >> B2Wsh)) >> B2Wsh; */
  /*  c2b_str(argv[i], v); */
  /*  parms[1+i] = v; */
  /*} */

  old_handler = signal(SIGINT, handler);
  initfpvec();

  globbase  = (BCPLWORD *)(calloc((gvecupb +1), 1<<B2Wsh));
  if(globbase==0) 
    { printf("unable to allocate space for globbase\n");
      exit(20);
    }

  stackbase = (BCPLWORD *)(calloc((stackupb+1), 1<<B2Wsh));
  if(stackbase==0) 
    { printf("unable to allocate space for stackbase\n");
      exit(20);
    }

  for(i=0; i<=Rtn_upb; i++) rootnode[i] = 0;

  globbase[0] = gvecupb;

  for (i=1;i<=gvecupb;i++) globbase[i] = Globword + i;
  globbase[Gn_rootnode] = ((BCPLWORD)rootnode)>>B2Wsh;

  for (i=0;i<=stackupb;i++) stackbase[i] = 0;

  /*  printf("clib: gvecupb=%d stackupb=%d\n", gvecupb, stackupb); */
  /* initsections, gvecupb and stackupb are defined in the file */
  /* (typically) initprog.c created by a call of the command makeinit. */

  initsections(globbase);
  ttyinp = init_keyb();

  /* Enter BCPL start function: callstart is defined in mlib.s */
  res = callstart(stackbase, globbase);


  close_keyb();

  if (res) printf("\nExecution finished, return code %ld\n", (long)res);

  free(globbase);
  free(stackbase);
  free(parms);

  return res;
}


BCPLWORD muldiv(BCPLWORD a, BCPLWORD b, BCPLWORD c)
{ unsigned BCPLWORD q=0, r=0, qn, rn;
  unsigned BCPLWORD ua, ub, uc;
  int qneg=0, rneg=0;
  /*  printf("muldiv: a=%d b=%d c=%d\n", a, b, c); */
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

static char chbuf1[256], chbuf2[256]; /* to hold filenames */
static char chbuf3[256], chbuf4[256]; /* to hold filenames */

int tracing = 0;
int filetracing = 0;

int relfilename(char *name)
{ if(name[0]==FILE_SEP_CH ||
     /* The following is fiddle for MSDOS/Windows */
     FILE_SEP_CH=='\\' && 'A'<=name[0] && name[0]<='Z' && name[1]==':')
       return 0; /* Absolute file names don't use paths */
  return 1; 
}

/* pathinput does not use any of chbuf1, chbuf2 or chbuf3. */
FILEPT pathinput(char *name, char *pathname)
/* If pathname is not null, name is looked up in the directories
   it specified, otherwise name is looked up in the current directory
*/
{ FILEPT fp = 0;

  /* Look through the PATH directories if pathname is given. */
  if (pathname) {
    char str[256];
    char *filename = &str[0];
    int itemsep = FILE_SEP_CH=='/' ? ':' : ';';
#if defined(forVmsItanium) || defined(forVmsVax)
    itemsep = ';';
#endif
    /*PRINTFS("pathinput: searching for %s in path %s\n", name, pathname); */
    if (relfilename(name))
    { char *path = getenv(pathname);
      if(filetracing) {
        PRINTFS("pathinput: using %s", pathname);
        PRINTFS(" = %s\n", path);
      }
      /*PRINTFS("pathinput: searching directories %s\n", path); */
      /* Try prefixing with each directory in the path. */
      while(path && fp==0)
      { char *f=filename;
        char *n=name;
        while(*path==itemsep) path++;
        if(*path==0) break;
        /* Copy the directory name into filename */
        while(*path!=0 && *path!=itemsep)
        { char ch = *path++;
          if(ch=='/' || ch=='\\') ch = FILE_SEP_CH;
          *f++ = ch;
        }
        /* Insert a filename seperator if necessary. */
        if(f[-1]!=FILE_SEP_CH) *f++ = FILE_SEP_CH;

        /* Append the given file name */
        while(*n)
        { char ch = *n++;
          if(ch=='/' || ch=='\\') ch = FILE_SEP_CH;
          *f++ = ch;
        }
        *f = 0;
#if defined(forVmsItanium) || defined(forVmsVax)
        filename = vmsfname(filename, chbuf4);
#endif
        fp = fopen(filename, "rb");
        if(filetracing)
        { PRINTFS("Trying: %s - ", filename);
	  if(fp) {
            PRINTF("found\n");
	  } else {
            PRINTF("not found\n");
	  }
        }
      }
    }
  } else {
    /* If pathname was NULL, search the current directory */
    /*PRINTFS("Searching for %s in the current directory\n", name); */
#if defined(forVmsItanium) || defined(forVmsVax)
    fp = fopen(vmsfname(name, chbuf4), "rb");
#else
    fp = fopen(name, "rb");
#endif
    if(filetracing)
    { PRINTFS("Trying: %s in the current directory - ", name);
      if(fp) {
        PRINTF("found\n");
      } else {
        PRINTF("not found\n");
      }
    }
  }

  /*if(fp==0) PRINTFS("pathinput: failed to find %s anywhere\n", name); */
  /*else      PRINTF("pathinput: success\n"); */

  return fp;
}
/*
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
*/

/* dosys(P, G) called from mlib.s in response to
** BCPL call res := sys(n, x, y, ....). Arguments p & g are the
** OCODE stack-pointer P and Global vector pointer G. The arguments
** to sys() are n = p[3], x = p[4] ....
** sys(0, r) is trapped in mlib.s
*/

BCPLWORD dosys(register BCPLWORD *p, register BCPLWORD *g)
{ register BCPLWORD i;

  switch((int)(p[3]))
  { default: printf("\nBad sys %ld\n", (long)p[3]);  return p[3];
  
    /*
    case Sys_setcount: set count               -- done in cinterp
    case Sys_quit:     return from interpreter -- done in cinterp

    case Sys_rti:      sys(Sys_rti, regs)      -- done in cinterp  Cintpos
    case Sys_saveregs: sys(Sys_saveregs, regs) -- done in cinterp  Cintpos
    case Sys_setst:    sys(Sys_setst, st)      -- done in cinterp  Cintpos
    case Sys_tracing:  // sys(Sys_tracing, b) 
      tracing = p[4];
      return 0;
    case Sys_watch:    sys(Sys_watch, addr)    -- done in cinterp

    case  Sys_tally:         // sys(Sys_tally, flag) 
      if(p[4]) {
        tallylim = tallyupb;
        for(i=1; i<=tallylim; i++) tallyv[i] = 0;
      } else {
        tallylim = 0;
      }
      return 0;
     
    case Sys_interpret: // call interpreter (recursively) 
    { BCPLWORD regsv = p[4];
      if(W[regsv+7]<0) return CINTASM  (regsv, W);
      return interpret(regsv, W);
    }
    */

    case Sys_sardch:
    { BCPLWORD ch;
      /*printf("parmp=%d parms[0]=%d\n", parmp, parms[0]); */
      if(parmp<=parms[0]) {  /* Added MR 10/04/06 */
        /* Read the command arguments (without echo) first. */
        /*printf("sardch: parmp=%d parms[0]=%d\n", parmp, parms[0]); */
        /*printf("sardch: returning %d\n", parms[parmp]); */
        return parms[parmp++];
      }
      ch = Readch();
      if (ttyinp) {  /* echo tty input only */
        if (ch>=0) putchar((char)ch);
        if(ch==13) { ch = 10; putchar(10); }
        fflush(stdout);
      }
      return ch;
    }

    case Sys_sawrch:
      if(p[4] == 10) putchar(13);
      putchar((char)p[4]);
      fflush(stdout);
      return 0;

    case Sys_read:  /* bytesread := sys(Sys_read, fp, buf, bytecount) */
    { FILE *fp = findfp(p[4]);
      char *bbuf = (char *)(p[5]<<B2Wsh);
      BCPLWORD len   = p[6];
      len = fread(bbuf, (size_t)1, (size_t)len, fp);
      return len;
    }

    case Sys_write:
    { FILE *fp = findfp(p[4]);
      char *bbuf = (char *)(p[5]<<B2Wsh);
      BCPLWORD len = p[6];
      len = WD fwrite(bbuf, (size_t)1, (size_t)len, fp);
      fflush(fp);
      return len;
    }

    case Sys_openread:
    { char *name = b2c_fname(p[4], chbuf1);
      FILEPT fp;
#if defined(forVmsItanium) || defined(forVmsVax)
      name = vmsfname(name, chbuf4);
#endif

      fp = pathinput(name,                    /* Filename */
                     b2c_str(p[5], chbuf2));  /* Environment variable */
      if(fp==0) return 0L;
      return newfno(fp);
    }

    case Sys_openwrite:
    { char *name = b2c_fname(p[4], chbuf1);
      FILEPT fp;
#if defined(forVmsItanium) || defined(forVmsVax)
      name = vmsfname(name, chbuf4);
#endif

      fp = fopen(name, "wb");
      if(fp==0) return 0L;
      return newfno(fp);
    }

    case Sys_openreadwrite:
    { char *name = b2c_fname(p[4], chbuf1);
      FILEPT fp;
#if defined(forVmsItanium) || defined(forVmsVax)
      name = vmsfname(name, chbuf4);
#endif

       fp = fopen(name, "rb+");
      if(fp==0) fp = fopen(name, "wb+");
      if(fp==0) return 0L;
      return newfno(fp);
    }

    case Sys_close:
    { BCPLWORD res = ! fclose(findfp(p[4]));
      freefno(p[4]);
      return res;
    }

    case Sys_deletefile:
    { char *name = b2c_fname(p[4], chbuf1);
      FILEPT fp;
#if defined(forVmsItanium) || defined(forVmsVax)
      name = vmsfname(name, chbuf4);
      { /* Append ';*' to name */
        int len = 0;
        while(name[len]) len++;
        name[len] = ';';
        name[len] = '*';
        name[len] = 0;
      }
#endif
      return ! REMOVE(name);
    }

    case Sys_renamefile:
    { char *name1 = b2c_fname(p[4], chbuf1);
      char *name2 = b2c_fname(p[5], chbuf2);
      int len = 0;
#if defined(forVmsItanium) || defined(forVmsVax)
      name1 = vmsfname(name1, chbuf3);
      name2 = vmsfname(name2, chbuf4);
      { /* Append ';*' to name2 */
        len = 0;
        while(name2[len]) len++;
        name2[len] = ';';
        name2[len] = '*';
        name2[len] = 0;
      }
#endif
      REMOVE(name2);
#if defined(forVmsItanium) || defined(forVmsVax)
      name2[len] = 0;
#endif
      return ! rename(name1, name2);
    }

    case Sys_getvec:
      return ((BCPLWORD)(malloc((1+p[4])<<B2Wsh)))>>B2Wsh;

    case Sys_freevec:
      free((void *)(p[4]<<B2Wsh)); return -1;
/*
    case Sys_loadseg:
      return loadseg(b2c_str(p[4], chbuf1));
    case Sys_globin:
      return globin(p[4], g);
    case Sys_unloadseg:
      unloadseg(p[4]);                    return 0;
*/

    case Sys_muldiv:
    { BCPLWORD res =  muldiv(p[4], p[5], p[6]);
      g[Gn_result2] = result2;
      return res;
    }

    case Sys_intflag:
      return intflag() ? -1L : 0L;

/*
    case Sys_setraster:
      return setraster(p[4], p[5]);
*/

    case Sys_cputime: /* Return CPU time in milliseconds  */
      return muldiv(clock(), 1000, TICKS_PER_SEC);

    case Sys_filemodtime: /* Return time of last modification of file
                             whose name is in p[4]  */
    { struct stat buf;
      char *name = b2c_fname(p[4], chbuf1);
      FILEPT fp;
#if defined(forVmsItanium) || defined(forVmsVax)
      name = vmsfname(name, chbuf4);
#endif
      if (stat(name, &buf)) return 0;
      return buf.st_mtime;
    }

    case Sys_setprefix: /* Set the file prefix string  */
      prefix = p[4];
      return prefix;

    case Sys_getprefix: /* Return the file prefix string  */
      return prefix;

    case Sys_graphics: /* Perform an operation on the graphics window  */
      return sysGraphics(p);

    case Sys_seek:  /* res := seek(fd, pos)   */
    { FILEPT fp = findfp(p[4]);
      BCPLWORD pos = p[5];
      BCPLWORD res = fseek(fp, pos, SEEK_SET);
      /*printf("fseek => res=%d errno=%d\n", res, errno); */
      /*g[Gn_result2] = errno; */
      return res==0 ? -1 : 0; /* res=0 succ, res=-1 error  */
    }

    case Sys_tell: /* pos := sys(Sys_tell,fd)  */
    { FILE *fp = findfp(p[4]);
      BCPLWORD pos = ftell(fp);
      /*g[Gn_result2] = errno; */
      return pos; /* >=0 succ, -1=error */
    }

    case Sys_waitirq: /* Wait for irq */
      /*
      pthread_mutex_lock  (         &irq_mutex);
      pthread_cond_wait   (&irq_cv, &irq_mutex);
      pthread_mutex_unlock(         &irq_mutex);
      */
      return 0;

    case Sys_lockirq: /* Stop all devices from modifying */
                      /* packets or generating interrupts */
      /*
      pthread_mutex_lock(&irq_mutex);
      */
      return 0;

    case Sys_unlockirq: /* Allow devices to modify packets */
                        /* and generate interrput */
      /*
      pthread_mutex_unlock(&irq_mutex);
      */
      return 0;

     case Sys_devcom: /* res := sys(Sys_devcom, com, arg) */
       return 0; /*devcommand(W[p+4], W[p+5], W[p+6]); */

     case Sys_ftime: /* return result of calling ftime */
     { struct timeb tb;
       BCPLWORD *v = (BCPLWORD*)(p[4]<<2);
       int daylight=0;
       int timezone=0;
       ftime(&tb);

       /* **************** BEWARE ************************ */
       /* The date will OVERFLOW on 19-Jan-2038 at 3:14:07 */
       v[0] = 0; /*(BCPLWORD)(tb.time>>32); */
       v[1] = (BCPLWORD)tb.time;  /* Seconds since epoch */
       v[2] = tb.millitm;     /* milli-seconds */
       /*v[3] = tb.timezone;*/    /* Minutes west of Greenwich */
       /*v[4] = tb.dstflag; */    /* non zero => Daylight saving time
                                 applies */

       daylight = 1;          /* Fudge for windows */
       daylight = 0;          /* Fudge for windows MR 31/10/03 */
       /*tzset();*/               /* Should be done separately */
       /*
       printf("cintpos: timezone=%d daylight=%d %s %s\n",
               (BCPLWORD)timezone,(BCPLWORD)daylight, tzname[0],
	       tzname[1]);
       */
       if(((BCPLWORD)timezone)%3600==0) /* Fudge for windows */
         v[1] -= (BCPLWORD)timezone;    /* Correct for timezone */
       if (daylight)
         v[1] += 60*60;             /* Add one hour in DST */
       v[1] += rootnode[Rtn_adjclock] * 60; /* Add adjustment */
       return -1;
     }

     case Sys_usleep: /* usleep for some micro-seconds */
       return 0; /*usleep(p[4]);  */
              
     case Sys_filesize:  /* res := sys(Sys_filesize, fd)   */
     { FILE *fp   = findfp(p[4]);
       BCPLWORD pos  = ftell(fp);
       BCPLWORD rc   = fseek(fp, 0, SEEK_END);
       BCPLWORD size = ftell(fp);
       rc  = fseek(fp, pos, SEEK_SET);
       if (rc) size = -1;
       return size; /* >=0 succ, -1=error  */
     }

     case Sys_getsysval: /* res := sys(Sys_getsysval, addr) */
     { BCPLWORD *addr = (BCPLWORD*)p[4];
       return *addr;
     }

     case Sys_putsysval: /* res := sys(Sys_putsysval, addr, val) */
     { BCPLWORD *addr = (BCPLWORD*)p[4];
       *addr = p[5];
       return 0;
     }

     case Sys_shellcom: /* res := sys(Sys_shellcom, comstr) */
     { char *comstr = (char*)(p[4]<<2);
       int i;
       char com[256];
       int len = strlen(comstr);
       for(i=0; i<len; i++) com[i] = comstr[i+1];
       com[len] = 0;
       /*
       printf("\ndosys: calling shell command %s\n", com);
       */
       return system(com);
     }

     case Sys_getpid: /* res := sys(Sys_getpid) */
       return 0; //getpid();

     case Sys_dumpmem: /* sys(Sys_dumpmem, context) */
       printf("\nCintpos memory not dumped to DUMP.mem\n");
       return 0;

     case Sys_callnative:
     { /* Call native code. */
       int(*rasmfn)(void) = (int(*)(void))&p[4];
       return rasmfn();
     }              

     case 135: /* Return system date and time in VEC 5 */
     { time_t clk = time(0);
       struct tm *now = gmtime(&clk);
       BCPLWORD *arg = PT(p[4] << B2Wsh);
       arg[0] = now->tm_year+1900;
       arg[1] = now->tm_mon+1;
       arg[2] = now->tm_mday;
       arg[3] = now->tm_hour;
       arg[4] = now->tm_min;
       arg[5] = now->tm_sec;
       return 0;
     }

     case 136: /* Return current directory in VEC 1 + 256/bytesperword */
     {
#if defined(forVmsItanium) || defined(forVmsVax)
#else
       getcwd(chbuf1, 256);
       c2b_str(chbuf1, p[4]);
#endif
       return 0;
     }

    case 137:
      return (BCPLWORD)parms >> B2Wsh;
  }
} 

char *vmsfname(char *name, char *vmsname) {
/*
This function converts a BCPL filename to a VMS filename
Examples:

Name                         VMS name

echo.b                       echo.b
com/echo.b                   [.com]echo.b
/mrich177/distribution/bcpl.g/libhdr.h
                             [mrich177.distribution.bcpl.g]libhdr.h
vd10$disk:/mrich177/junk.b   vd10$disk:[mrich177]junk.b
../cintcode/com/bcplfe.b     [-.cintcode.com]bcplfe.b
*/
  int ch, i=0, j=0, len=0, lastslashpos=-1;
  /* If name contains a colon, copy all
     characters up to and including the colon.
  */
  while (1) {
    int ch = name[i];
    if (ch==0) break; /* No colon in name */
    if (ch==':') {
      /* Copy up to and including the colon */
      while (len<=i) { vmsname[len] = name[len]; len++; }
      j = len;
      break;
    }
    i++;
  }
  /* Find position of last slash, if any */
  while (1) {
    int ch = name[j];
    if(ch==0) break;
    if(ch=='/') lastslashpos = j;
    j++;
  }

  /* No slashes  => nothing
     Leading /   => [
     Slashes but no leading slash so insert [. or [-

     name is then copied converting all slashes except the leading
     and last ones to dots, and converting the last slash to ].
  */
  j = i;
  if(name[j]=='/') {
    /* if leading slash but not the last convert it to [ */
    if (j!=lastslashpos) vmsname[len++] = '[';
    j++;
  } else {
    if (lastslashpos>=0) {
      /* Slashes but no leading slash, so insert [. or [-  */
      vmsname[len++] = '[';
      if(name[j]!='.' || name[j+1]!='.') {
        vmsname[len++] = '.';
      }
    }
  }

  while (1) {
    /* Replace last / by ]
       and non last / by .
       and .. by -
    */
    int ch = name[j];
    if(ch=='.' && name[j+1]=='.') {
      /* Convert .. to - */
      ch = '-';
      j++;
    }
    if(ch=='/') {
      if (j==lastslashpos) ch = ']';
      else                 ch = '.';
    }
    vmsname[len++] = ch;
    if(ch==0) break;
    j++;
  }
  return vmsname;
}

/* b2c_fname converts the BCPL string for a file name to a C character
** string.  The character '/' (or '\') is treated as a separator and is
** converted to FILE_SEP_CH ('/' for unix, '\' for MSDOS or ':' for MAC).
** If prefix is set and the filename is relative, the prefix is prepended.
*/
char *b2c_fname(BCPLWORD bstr, char * cstr)
{  char *bp = (char*)(bstr<<2);
   int len;
   int i=0;
   if (bstr==0) return 0; /* No path given */
   len = *bp++;
   if (prefix && relfilename((char*)bstr))
   { /* Prepend the filename with prefix */
     char *pfxp = (char*)(prefix<<2);
     int pfxlen = *pfxp++;
     while(pfxlen--)
     { char ch = *pfxp++;
       if(ch=='/' || ch=='\\' || ch==':') ch = FILE_SEP_CH;
       cstr[i++] = ch;
     }
     if (cstr[i-1] != FILE_SEP_CH) cstr[i++] = FILE_SEP_CH;
   }

   while (len--)
   { char ch = *bp++;
     if(ch=='/' || ch=='\\' || ch==':') ch = FILE_SEP_CH;
     cstr[i++] = ch;
   }
   cstr[i] = 0;
   /*if (prefix) printfs("filename = %s\n", cstr); */
   /*printfs("b2c_fname: cstr = %s\n", cstr); */
   return cstr;
}

/* b2c_str converts the BCPL string for a file name to a C character
** string.  The character '/' (or '\') is treated as a separator and is
** converted to FILE_SEP_CH ('/' for unix, '\' for MSDOS or ':' for MAC)
*/
char *b2c_str(BCPLWORD bstr, char * cstr)
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
BCPLWORD c2b_str(char *cstr, BCPLWORD bstr) {
  char *bp = (char *)(bstr << B2Wsh);
  int len = 0;
  while (cstr[len]) {
    bp[len+1] = cstr[len];
      ++len;
  }
  bp[0] = len;
  return bstr;
}
