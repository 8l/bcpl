/*
** This is a 32 bit CINTCODE interpreter written in C designed
** to run on most machines with Unix-like C libraries.
**
** (c) Copyright:  Martin Richards  27 May 2013
**
*/

// Test this sort of comment.

/*
15/04/13
Added sys(Sys_opengl,...) to provide an interface to the OpenGL graphics library.

22/06/12
Added sys(Sys_sdl,...) to provide an interface to the SDL graphics library.

06/03/12
Implemented debug counts by defining incdcount(n) and sys(Sys_incdcount,n).
There were related changes to cintsys.h, cintpos.h, cintpos.c g/libhdr.h and 
com/dcount.b

07/02/11
Changed the format of BCPL filenames to use '/' (or '\') as separators of file
name components. Such names are converted to target system names before
use. The targets are UNIXNAMES for Linux style, WINNAMES for Windows style and
VMSNAMES for VMS style. Separators in path list can be ether semicolons or
colons, except under Window when only semicolons are allowed.

12/01/11
Made INT.h define the macro FormD to have values like
"d" or "ld" depending on whether BCPLWORD is int or long. FormX
is similarly defined as "X" or "lX". These are used in printf formats
taking advantage of the C feature that concatenates consecutive string
constants at compile time, as in: printf("x = %5" FormD "\n", (BCPLWORD) x);
Made systematic changes to cintsys.c, cintsys.h and kblib.c to make use
of FormD and FormX in all calls of printf.

04/12/10
Changed the implementation of Sys_delay to use select() rather than
usleep() or nanosleep().

03/05/10
Removed Sys_usleep and reimplemented Sys_delay to sleep for a time
in msecs (possibly >= 1000).

07/04/10
Change BCPL epoc of 1 Jan 1978 to 1 Jan 1970 to be the same
as that used by Unix and Windows. Made corresponding changes
to blib.
Changed INT32 and INT64 to BCPLINT32 and BCPLINT64
Changed CHAR to UNSIGNEDCHAR

29/03/10
Made systematic changes to measure time in msecs rather than ticks.
This is equivalent to setting tickspersecond to 1000, but the code is
simpler.

05/02/10
Added the low level trace functions trpush, settrcount and gettrcount,
together with the sys operations Sys_trpush, Sys_settrcount and Sys_gettrval.
These can all be safely called from any thread. The circular trace buffer
can hold 4096 values.

07/10/09
Renamed files cinterp.h to cintsys.h (and for cintpos, cinterp.h to
cintpos.h) to distinguish between the two versions of cinterp.h

05/10/09
Moved some some configuration statements to cintsys.h and added VMSNAMES

17/07/09
Added forVmsItanium and forVmsVax features, including the following:
Implemented vmsfile(filename, vmsfilename) to convert
most Linux file names to Vax filenames.

19/02/08
Round up the address of the Cintcode memory to a double word boundary.  (malloc
probably already does this).

07/12/07
Added and initialised the rootnode fields rtn_mc0 to rtn_mc3 to hold the m/c
address of the Cintcode memory and other system dependent values used by the MC
dynamic native code package.

21/11/06
Force sardch to treat RUBOUT (ie the backspace key) to return Backspace (=8)
not rubout (=127). Add sys(Sys_delay, ticks) and tickspersecond to delay
for a given number of ticks using sleep and usleep.

10/11/06
Added the -slow option to force using the slow interpreter (interpret) all
the time. This is useful if there seems to be a bug in cinterp or fasterp.

08/11/06
Added the -d option to set the dump flag in the rootnode (equivalent to calling
the command: dumpmem on). This will cause the entire Cintcode memory to be
dumped to DUMP.mem in a compacted form if the Cintcode system returns with a
non zero return code. The file DUMP.mem can be printed in a readable form using
the dumpsys command (always assuming you have a working BCPL system).

07/11/06
Added -v option to trace the progress of the booting process. This is primarily
to help people a new installation of Cintcode BCPL.
Added -vv option to trace the progress of the booting process. It behaves like
-v above but also does some Cintcode instruction level tracing.
Added -f option to cintsys to trace the use of environment variables such as
BCPLPATH by pathinput. This is helps to track down installation problems.

26/07/06
Made changes to cause loadseg to look first in the BCPLPATH directories then
the current directory and finally in the cin directory of BCPLROOT.  To
simplify this change, the first argument of pathinput was changes from a BCPL
string to a C string, together with related changes.  There are now three work
C strings chbuf1, chbuf2 and chbuf3. Made cintsys.c more compatible with
cintpos.c

22/06/06
Making a version for the GP2X handheld Linux machine.

21/06/06
Defined CHAR in cintpos.h and cintsys.h to be unsigned char and replaced nearly
all occurences of char with CHAR. This avoids a warning from some compilers.
Changed most file names to lower case to simplify use of windows machines.

18/01/06
Added -s, -c and -- parameters to cintpos, to prepend characters before the
start of stdin (as suggested by Dave Lewis).

01/01/06
Change -m and -t options to specify sizes in words (not thousands of words).

24/04/04
Made many changes to make cintsys more compatible with cintpos

22/06/00
Made a correction to muldiv to stop it looping on #x8000000 This Cintcode
instruction MDIV is now not invoked since it sometimes causes a floating
point(!!) exception on a Pentium.

05/04/00
Added -m and -t command line options to specify the Cintcode memory size and
tally vector size in thousands of words.  Added the -h option.

06/01/00
Made changes to make cintsys.c more compatible with the Windows CE version.

26/2/99
Changed loadseg to accept binary hunks as well as hex hunks.

6/11/98
Implemented changes to replace sys(14,name) by sys(14,name,pathname). If
pathname is 0 or the specified shell variable is unset, there should be no
noticeable difference. The new version searches for the file in the current
working directory, then the directories given by the shell variable pathname
until successfully opened.  It is designed to work on both Windows and
unix. The convention will be that if the shell variable is set it will specify
a path used by loadseg (ie the initial loading of SYSLIB, BOOT, BLIB, CLI and
CLI commands) as well as for header files. There are small related changes to
libhdr, BLIB.b and bcpl.b.

5/11/98
The comment character in object modules has changed from semicolon(';') to hash
('#').

12/6/96 Move the definition of
INT32pt, WD, UWD, PT, BP, SBP, HP and SHP to cintpos.h, and define SIGNEDCHAR
in cintpos.h to solve a problem with char being unsigned on some
implementations.

31/5/96
Added handler for SIGINT to restore tty settings

30/4/96
Added call of fflush(fp) to case 13: in dosys, with corresponding changes to
libhdr and BLIB.b (added flush())

24/11/95
Improved the efficiency of the calls of fread and fwrite
Reduced the size of chbuf from 1024 to 256

25/10/95
Use ANSI clock() instead of ftime(), adding TICKS_PER_MS.  Change #define names
to forMAC, forMIPS, forSUN4 etc Add and set external tallyv

*/

/* cintsys.h and cintpos.h contains machine/OS dependent #defines  */
#include "cintsys64.h"
#include <math.h>
#include "time.h"

/* Function defined in callc.c  */
extern BCPLWORD callc(BCPLWORD *args, BCPLWORD *g);

BCPLWORD trcount = -1; // trpush initially disabled
BCPLWORD trvec[4096];  // 4096 elements in the trpush circular buffer

/* Low level trace functions */

void trpush(BCPLWORD val);
BCPLWORD settrcount(BCPLWORD count); // Set trcount and returns its old value
BCPLWORD gettrval(BCPLWORD count); // Get the specified trace value
BCPLWORD incdcount(BCPLWORD n);


/* Functions defined in kblib.c  */
extern int Readch(void);
extern int pollReadch(void);
extern int init_keyb(void);
extern int close_keyb(void);
extern int intflag(void);

/* Function defined in soundfn.c */
BCPLWORD soundfn(BCPLWORD *args, BCPLWORD *g);

/* Function defined in openglfn.c */
BCPLWORD openglfn(BCPLWORD *args, BCPLWORD *g, BCPLWORD *W);

/* Function defined in sdlfn.c */
BCPLWORD sdlfn(BCPLWORD *args, BCPLWORD *g, BCPLWORD *W);

/* Functions defined in rastlib.c (or nullrastlib.c)  */
extern BCPLWORD setraster(BCPLWORD n, BCPLWORD val);

/* Function defined in graphics.c  */
#ifdef forWinCE
extern BCPLWORD sysGraphics(BCPLWORD p);
#else
BCPLWORD sysGraphics(BCPLWORD p) { return 0; } /* Dummy definition */
#endif

#define Stackupb     500L
#define Globupb     1000L

BCPLWORDpt W;  /* This will hold the pointer to the Cintcode memory */

BCPLWORD *lastWp;    /* Latest setting of Wp  */
BCPLWORD *lastWg;    /* Latest setting of Wg  */
BCPLWORD  lastst;    /* Latest setting of st  */

BCPLWORD rootvarstr = 0;
BCPLWORD pathvarstr = 0;
BCPLWORD hdrsvarstr = 0;
BCPLWORD scriptsvarstr = 0;

BCPLWORD prefixstr = 0; /* Position in the Cintcode memory of the filename */
                        /* prefix. The prefixstr is prepended to all non */
                        /* absolute file names. prefixstr is set by */
                        /* sys(Sys_setprefix, str) and read by */
                        /* sys(Sys_getprefix). */
char *prefixbp;         /* Address of byte holding the length of the prefix */

BCPLWORD stackbase;
BCPLWORD globbase;
BCPLWORD result2;

static char chbuf1[256]; /* These buffers are used to hold filenames */
static char chbuf2[256];
static char chbuf3[256];
static char chbuf4[256];
static char* rootvar = "BCPL64ROOT"; /* The default setting */
static char* pathvar = "BCPL64PATH"; /* The default setting */
static char* hdrsvar = "BCPL64HDRS"; /* The default setting */
static char* scriptsvar = "BCPL64SCRIPTS"; /* The default setting */

int tracing = 0;
int filetracing = 0;
int dumpflag = 0;
int slowflag = 0;   /* If non zero always use the slow interpreter */
int boottrace = 0;

BCPLWORD memupb;
BCPLWORD tallyupb, tallyvec, *tallyv, tallylim=0;
BCPLWORD vecstatsvupb, vecstatsvec, *vecstatsv;    /* Stats of getvec/freevec */
BCPLWORD dcountv;    /* To hold the BCPL pointer to the debug count vector */

BCPLWORD taskname[4];         /* Used in getvec for debugging */

BCPLWORD concatsegs(BCPLWORD seg1, BCPLWORD seg2);
BCPLWORD loadsysseg(char *name);
BCPLWORD loadseg(char *name);
void  unloadseg(BCPLWORD segl);
BCPLWORD rdhex(FILEPT fp);
BCPLWORD globin(BCPLWORD segl, BCPLWORD g);
BCPLWORD getvec(BCPLWORD upb);
BCPLWORD freevec(BCPLWORD p);
BCPLWORD muldiv(BCPLWORD a, BCPLWORD b, BCPLWORD c);
FILEPT pathinput(char *name, char *pathname);
BCPLWORD dosys(BCPLWORD p, BCPLWORD g);
BCPLWORD doflt(BCPLWORD op, BCPLWORD a, BCPLWORD b);
char *prepend_prefix(char *fromstr, char *tostr);
char *vmsfname(char *name, char *vmsname);
char *osfname(char *name, char *osname);
void c2b_str(char *cstr, BCPLWORD bstr);
char *b2c_str(BCPLWORD bstr, char *cstr);
BCPLWORD syscin2b_str(char *cstr, BCPLWORD bstr);
char *catstr2c_str(char *cstr1, char *cstr2, char *str);
void  wrcode(char *form, BCPLWORD f, BCPLWORD a);
void  wrfcode(BCPLWORD f);
void  trace(BCPLWORD pc, BCPLWORD p, BCPLWORD a, BCPLWORD b);
void  dumpmem(BCPLWORD *mem, BCPLWORD upb, BCPLWORD context);
BCPLWORD timestamp(BCPLWORD *v);
void msecdelay(unsigned int delaymsecs);

extern int cintasm(BCPLWORD regs, BCPLWORDpt mem);
extern int interpret(BCPLWORD regs, BCPLWORDpt mem);

#define Globword       0x8F8F0000L

#define Gn_globsize    0
#define Gn_start       1
#define Gn_sys         3
#define Gn_currco      7
#define Gn_colist      8
#define Gn_rootnode    9
#define Gn_result2    10
#define Gn_cli_returncode    137

/* relocatable object blocks  */
#define T_hunk    1000L
#define T_reloc   1001L
#define T_end     1002L
#define T_hunk64  2000L
#define T_reloc64 2001L
#define T_end64   2002L
#define T_bhunk   3000L
#define T_bhunk64 4000L

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
  /* Test vmsfname */
  /*
  vmsfname("echo.b", chbuf4);
  vmsfname("com/echo.b", chbuf4);
  vmsfname("/mrich177/distribution/bcpl/g/libhdr.h", chbuf4);
  vmsfname("vd10$disk:/mrich177/junk.b", chbuf4);
  vmsfname("../cintcode/com/bcplfe.b", chbuf4);
  vmsfname("/junk", chbuf4);
  */
  return bad;
}

/* The following four functions are necessary since the type FILE*
** is too large for a BCPL word on some machines (such as the DEC Alpha)
*/

#if defined(forALPHA) || defined(forLinuxAMD64)
#define Fnolim 100

FILEPT fpvec[Fnolim];

int initfpvec(void)
{ BCPLWORD i;
  for(i=1;i<Fnolim;i++) fpvec[i]=NULL;
  return 0;
}

BCPLWORD newfno(FILEPT fp)
{ BCPLWORD i;
  for(i=1;i<Fnolim;i++) if(fpvec[i]==NULL){ fpvec[i]=fp; return i; }
  return 0;
}

BCPLWORD freefno(BCPLWORD fno)
{ if(0<fno && fno<Fnolim){fpvec[fno]=NULL; return 1; }
  return 0;
}

FILEPT findfp(BCPLWORD fno)
{ if(0<fno && fno<Fnolim) return fpvec[fno];
  return 0;
}

#else

int   initfpvec(void)    { return 0; }
BCPLWORD newfno(FILEPT fp)   { return WD (long)fp; }
BCPLWORD freefno(BCPLWORD fno) { return fno; }
FILEPT findfp(BCPLWORD fno)  { return (FILEPT )(long)fno; }

#endif

int mainpid=0;
extern BCPLWORD exitflag; /* Set to one on receiving SIGINT or SIGGEGV */

#ifndef forWinCE
void (*old_inthandler)(int);
void (*old_segvhandler)(int);

void inthandler(int sig)
{ 
  PRINTF("\nSIGINT received\n");
  old_inthandler = signal(SIGINT, old_inthandler);

  close_keyb();
  PRINTF("\nLeaving Cintsys64\n");
  if(W[rootnode+Rtn_dumpflag])
  { W[rootnode+Rtn_lastp] = lastWp-W;
    W[rootnode+Rtn_lastg] = lastWg-W;
    dumpmem(W, memupb, 1);
    PRINTF("\nMemory dumped to DUMP.mem, context=1\n");
  }
  /*if(mainpid) { kill(mainpid, SIGKILL); mainpid = 0; } */
  exit(0);
}

void segvhandler(int sig)
{ 
  PRINTF("\nSIGSEGV received\n");
  old_segvhandler  = signal(SIGSEGV,  old_segvhandler);

  close_keyb();
  PRINTF("\nLeaving Cintsys64\n");
  if(W[rootnode+Rtn_dumpflag])
  { W[rootnode+Rtn_lastp] = lastWp-W;
    W[rootnode+Rtn_lastg] = lastWg-W;
    dumpmem(W, memupb, 2);
    PRINTF("\nMemory dumped to DUMP.mem, context=2\n");
  }
  /*if(mainpid) { kill(mainpid, SIGKILL); mainpid = 0; } */
  exit(0);
}
#endif

char *inbuf = NULL;	/* Buffer for input to interpreter */
int reattach_stdin = 0;	/* FALSE, if true switch to stdin after inbuf is empty */

/* Replacement for Readch() when taking stdin from a command line parameter */
int inbuf_next()
{
  static int idx = 0;
  int c = inbuf[idx];
  if (c) {
    idx++;
    return c;
  }
  else return EOF; /* -1 */
}

/*
Set up a stream of characters to be prepended to the standard input, for the
cli to read before those in the normal input stream.  If leading_string is
provided, it is prepended to stream of characters.  This is used to support
executable cintcode files and CLI scripts on Unix systems. The leading_string
feature permits support of scripts by running the "c" command followed by its
command line arguments.
*/
void prepend_stdin(char *leading_string, int argc, char* argv[], int argvpos) {
  int j;
  int inbuf_len;
  /* Total number of fields to prepend to standard input stream */
  int field_count = (leading_string?1:0) + argc - argvpos - 1;
  if (field_count == 0) {
    return; /* nothing to prepend */
  }
  /* Count space to allocate, beginning with leading_string */
  inbuf_len = leading_string ? strlen(leading_string) : 0;
  /* Add space for remaining fields */
  for (j=argvpos+1; j<argc; j++) {
    inbuf_len += strlen(argv[j]);
  }
  /* Add room for spaces between fields plus a trailing <cr> */
  /* plus a null terminator */
  inbuf_len += field_count + 1;
  /* Allocate buffer for input stream */
  if (!(inbuf = (char*)malloc(inbuf_len))) {
    perror("malloc");
    exit(-1);
  }
  inbuf[0] = 0;
  /* Fill the buffer */
  /* First prepend the leading string, if any */
  if (leading_string) strcat(inbuf, leading_string);
  /* Concatenate remaining args, separated by spaces */
  for (argvpos++; argvpos<argc; argvpos++) {
    if (inbuf[0]) strcat(inbuf, " ");
    strcat(inbuf, argv[argvpos]);
  }
  strcat(inbuf, "\n"); /* Simulate interactive end of line */

  /*PRINTFS("\nPrepended string:\n%s\n", inbuf); */
}

/* The MC package printf function */
BCPLWORD mcprf(char *format, BCPLWORD a) {
  printf(format, a);
  return 0;
}

int main(int argc, char* argv[])
{ int rc;
  int i;           /* for FOR loops  */
  BCPLWORD res;    /* result of interpret  */

  for (i=0; i<4; i++) taskname[i] = 0;

#ifdef forWinCE
  argc = 0;     /* temporary fiddle for Windows CE */
  memupb   = 2000000L;
  tallyupb =  200000L;
#else
  memupb   = 4000000L;
  tallyupb = 1000000L;
#endif

  vecstatsvupb = 20000L;

#ifndef forWinCE
  mainpid = getpid();
#endif

  /*for (i=0; i<argc; i++) printf("%2" FormD ": %s\n", i, argv[i]); */

  for (i=1; i<argc; i++) {

    if (strcmp(argv[i], "-m")==0) {
      memupb   = atoi(argv[++i]);
      continue;
    }

    if (strcmp(argv[i], "-t")==0) {
      tallyupb = atoi(argv[++i]);
      continue;
    }

    if (strcmp(argv[i], "-cin")==0) {
      pathvar = argv[++i];
      continue;
    }

    if (strcmp(argv[i], "-f")==0) {
      filetracing = 1;
      continue;
    }

    if (strcmp(argv[i], "-d")==0) {
      dumpflag = 1;
      continue;
    }

    if (strcmp(argv[i], "-slow")==0) {
      slowflag = 1;
      continue;
    }

    if (strcmp(argv[i], "-s")==0) {
      /*
      Invoke a CLI command interpreter giving it the current file to
      execute as a sequence of commands.  It is used to enable executable CLI
      scripts to be invoke from Unix.

      Example: Make and executable file test1 containing something like:

      #!/home/mr/distribution/Cintpos/cintpos/cintpos -s
      bcpl com/bcpl.b to junk
      echo "*nCompilation done*n"

      #!/home/mr/distribution/BCPL/cintcode/cintsys -s
      bcpl com/bcpl.b to junk
      echo "*nCompilation done*n"

      and run it by typing the Unix command: test1
      */

      char *fname = argv[i + 1];
      if (!fname) {
        fprintf(stderr, "missing parameter for -s\n");
        exit(-1);
      }
      prepend_stdin("c", argc, argv, i);
      break;
    }

    if (strcmp(argv[i], "--")== 0) {
      /* Like -c but reattach standard input after exhausting command */
      /* line characters. */
      reattach_stdin = 1; /* TRUE */
    }

    if (strcmp(argv[i], "-c")== 0 || strcmp(argv[i], "--")== 0) {
      /* Allocate a buffer to hold remaining args as a string and pass
      ** remainder of command line to the interpreter.

      ** Typical usage:

      ** cintpos -c bcpl com/bcpl.b to junk
      ** cintsys -c bcpl com/bcpl.b to junk
      */

      prepend_stdin(NULL, argc, argv, i);
      break;
    }

    if (strcmp(argv[i], "-v")== 0) { boottrace=1; continue; }

    if (strcmp(argv[i], "-vv")== 0) { boottrace=2; continue; }

    if (strcmp(argv[i], "-h")!=0) PRINTF("Unknown command option: %s\n", argv[i]);

    PRINTF("\nValid arguments:\n\n") ;
    PRINTF("-h            Output this help information\n");
    PRINTF("-m n          Set Cintcode memory size to n words\n");
    PRINTF("-t n          Set Tally vector size to n words\n");
    PRINTF("-c args       "
           "Pass args to interpreter as standard input (executable bytecode)\n");
    PRINTF("-- args       "
           "Pass args to interpreter standard input, then re-attach stdin\n");
    PRINTF("-s file args  "
           "Invoke command interpreter on file with args (executable scripts)\n");
    PRINTF("-cin name     Set the pathvar environment variable name\n");
    PRINTF("-f            Trace the use of environment variables in pathinput\n");
    PRINTF("-v            Trace the bootstrapping process\n");
    PRINTF("-vv           As -v, but also include some Cincode level tracing\n");

    PRINTF("-d            Cause a dump of the Cintcode memory to DUMP.mem\n");
    PRINTF("              if a fault/error is encountered\n");

    PRINTF("-slow         Force the slow interpreter to always be selected\n");

    return 0;
  }

  if(boottrace>0) PRINTFD("Boot tracing level is set to %d\n", boottrace);

  if (memupb<50000 || tallyupb<0) {
    PRINTF("Bad -m or -t size\n");
    return 10;
  }

  if(boottrace) {
    char *bytestr = "ABCD1234";
    int litend = 0;
    printf("\ncintsys64 27 May 2013  20:26\n\n");
    printf("bytestr=%s word 0 = %8" FormX "\n", bytestr, *((BCPLWORD*)bytestr));
    if(((BCPLWORD*)bytestr)[0]&255=='A') litend = 1;
#ifdef BIGENDER
    printf("BIGENDER is defined");
    if(litend==0)  printf(" but the host machine is a little ender");
#else
    printf("BIGENDER is not defined");
    if(litend==1)  printf(" but the host machine is a big ender");
#endif
    printf("\n");
    printf("sizeof(int)        = %d\n", (int)sizeof(int));
    printf("sizeof(long)       = %d\n", (int)sizeof(long));
    printf("sizeof(BCPLWORD)   = %d\n", (int)sizeof(BCPLWORD));
    printf("sizeof(BCPLWORD *) = %d\n", (int)sizeof(BCPLWORD *));
    printf("FormD is \"%s\"\n", FormD);
    printf("FormX is \"%s\"\n", FormX);
  }

  if(badimplementation())
  { PRINTF("This implementation of C is not suitable\n");
    return 0;
  }

  initfpvec();

  W = PT malloc((memupb+tallyupb+vecstatsvupb+7)<<B2Wsh);

  if(W==NULL)
  { PRINTF("Insufficient memory for memvec\n");
    return 0;
  }
  /*  printf("Cintcode memory %8" FormX " (unrounded)\n", (UBCPLWORD) W); */
  W = PT(((long) W + 7L) & -8L);
  /*  printf("Cintcode memory %8" FormX" (rounded)\n", (UBCPLWORD)W);  */

  lastWp = W;
  lastWg = W;
  lastst = 3; /* Pretend to be in the interrupt service routine */

  for (i=0; i<memupb; i++) W[i] = 0xDEADC0DE;

  if (boottrace>0) PRINTFD("Cintcode memory (upb=%" FormD ") allocated\n", memupb);

  W[0] = memupb+1;  /* Initialise heap space */
  W[memupb] = 0;

  tallylim = 0;
  tallyvec = memupb+1;
  tallyv = &W[tallyvec];
  tallyv[0] = tallyupb;
  for(i=1; i<=tallyupb; i++) tallyv[i] = 0;

  vecstatsvec = tallyvec + tallyupb + 1;
  vecstatsv = &W[vecstatsvec];
  for(i=0; i<=vecstatsvupb; i++) vecstatsv[i] = 0;
 
  getvec(rootnode-12);  /* Allocate space for interrupt vectors */

  // Allocate the rootnode in exactly the correct place in Cintcode memory
  if (rootnode != (i=getvec(100L)+1)) {
    printf("The root node was at %d not at %d\n", i, rootnode);
  }

  // Allocate space for the environment variable names
  // and file prefix string.
  rootvarstr    = getvec(5*16);
  pathvarstr    = rootvarstr+1*16;
  hdrsvarstr    = rootvarstr+2*16;
  scriptsvarstr = rootvarstr+3*16;
  prefixstr     = rootvarstr+4*16;
  prefixbp      = (char *)(&W[prefixstr]);
  for(i=0; i<=5*16; i++) W[rootvarstr+i] = 0;

  c2b_str(rootvar, rootvarstr);
  c2b_str(pathvar, pathvarstr);
  c2b_str(hdrsvar, hdrsvarstr);
  c2b_str(scriptsvar, scriptsvarstr);

  dcountv    = getvec(511);                // Allocate the debug counts vector
  W[dcountv] = 511;
  for(i=1; i<=511; i++) W[dcountv+i] = 0;

  if(filetracing) {
    char *path = getenv(rootvar);
    PRINTFS("Environment variable %s", rootvar);
    PRINTFS(" = %s\n", path);
    path = getenv(pathvar);
    PRINTFS("Environment variable %s", pathvar);
    PRINTFS(" = %s\n", path);
    path = getenv(hdrsvar);
    PRINTFS("Environment variable %s", hdrsvar);
    PRINTFS(" = %s\n", path);
    path = getenv(scriptsvar);
    PRINTFS("Environment variable %s", scriptsvar);
    PRINTFS(" = %s\n", path);
  }

  stackbase = getvec(Stackupb+6);  /* +6 because it will be a coroutine */
  globbase  = getvec(Globupb);
  result2 = 0L;

  if (boottrace>0) PRINTF("Boot's stack allocated at %" FormD "\n", stackbase);

  W[stackbase] = Stackupb; /* Tell boot how large its stack is. */
  for(i=1; i<=Stackupb+6; i++) W[stackbase+i] = 0xABCD1234;
  /* boot will turn this stack into a coroutine stack */

  if (boottrace>0)
    PRINTF("Boot's global vector allocated at %" FormD "\n", globbase);

  for(i = 0; i<=Globupb; i++) W[globbase+i] = Globword+i;
  W[globbase+Gn_globsize] = Globupb;
  W[globbase+Gn_rootnode] = rootnode;

  for(i=0; i<=Rtn_upb; i++) W[rootnode+i] = 0;

  W[rootnode+Rtn_membase]      = 0;
  W[rootnode+Rtn_memsize]      = memupb;
  W[rootnode+Rtn_blklist]      = 0;
  W[rootnode+Rtn_tallyv]       = tallyvec;
  W[rootnode+Rtn_vecstatsv]    = vecstatsvec;
  W[rootnode+Rtn_vecstatsvupb] = vecstatsvupb;
  W[rootnode+Rtn_boottrace]    = (BCPLWORD) boottrace;
  W[rootnode+Rtn_dumpflag]     = dumpflag;
  { // This fudge is for systems where the size of BCPLWORD
    // and BCPLWORD* are different. The fields mc1 to mc3 are
    // only used by the MC package
    union { BCPLWORD *p;
            BCPLWORD v[2];} pv;
    union { BCPLWORD (*f)(char*, BCPLWORD);
            BCPLWORD v[2];} fv;
    pv.v[0] = pv.v[1] = 0;
    pv.p = W;               /* Cintcode memory */
    W[rootnode+Rtn_mc0]          = pv.v[0];
    W[rootnode+Rtn_mc1]          = pv.v[1];
    fv.v[0] = fv.v[1] = 0;
    fv.f = mcprf;           /* The MC prf fn */
    W[rootnode+Rtn_mc2]          = fv.v[0];
    W[rootnode+Rtn_mc3]          = fv.v[1];
  }
  W[rootnode+Rtn_rootvar]      = rootvarstr;
  W[rootnode+Rtn_pathvar]      = pathvarstr;
  W[rootnode+Rtn_hdrsvar]      = hdrsvarstr;
  W[rootnode+Rtn_scriptsvar]   = scriptsvarstr;

  W[rootnode+Rtn_dcountv]      = dcountv;

  if (boottrace>0) PRINTF("Rootnode allocated at %d\n", rootnode);

  if (boottrace>0) PRINTF("Loading resident programs and libraries\n");

  { BCPLWORD seg = loadseg("syscin/boot");
    if(seg==0) {
      PRINTF("\nUnable to find syscin/boot\n");
      PRINTF("This is probably caused by incorrect settings of\n");
      PRINTF("environment variables such as BCPLROOT and BCPL64PATH\n");
      PRINTF("Try entering cintsys using the command\n");
      PRINTF("\ncintsys64 -f -v\n\n");
      PRINTF("to see what is happening\n");
      return 20;
    }
    W[rootnode+Rtn_boot] = globin(seg, globbase);
    if(W[rootnode+Rtn_boot]==0) {
      PRINTF("Can't globin boot\n");
      return 20;
    }

    if (boottrace>0) PRINTF("syscin/boot loaded successfully\n");

    seg = loadseg("syscin/blib");
    if(seg==0) { PRINTF("Can't load syscin/blib\n"); return 20; }
    if (boottrace>0) PRINTF("syscin/blib loaded successfully\n");

    seg = concatsegs(seg, loadseg("syscin/syslib"));
    if(seg==0) { PRINTF("Can't load syscin/syslib\n"); return 20; }
    if (boottrace>0) PRINTF("syscin/syslib loaded successfully\n");

    seg = concatsegs(seg, loadseg("syscin/dlib"));
    if(seg==0) { PRINTF("Can't load syscin/dlib\n"); return 20; }
    if (boottrace>0) PRINTF("syscin/dlib loaded successfully\n");

    W[rootnode+Rtn_blib] = globin(seg, globbase);
    if(W[rootnode+Rtn_blib]==0) {
      PRINTF("Can't globin {blib,syslib,dlib}\n");
      return 20;
    }
  }

#ifndef forWinCE
  /* Set handler for CTRL-C */
  old_inthandler  = signal(SIGINT, inthandler); /* To catch CTRL-C */
  /* Set handler for segment violation */
  old_segvhandler  = signal(SIGSEGV, segvhandler); /* To catch segv */
#endif

  /* Make sys available via the root node */
  W[rootnode+Rtn_sys] = W[globbase+Gn_sys];
  //printf("sys code is %16llX\n", W[globbase+Gn_sys]);

  /*
  boot has no coroutine environment.  Note that boot's global vector is also
  used by interrupt service routines. The chain of stack frames in such an
  environment must be terminated by a zero link (for DEBUG to work properly).
  */
  W[globbase+Gn_currco] = 0;
  W[globbase+Gn_colist] = 0;

  /* Set the boot registers ready for the Cintcode interpreter */

  W[bootregs+0] = 0;                /* A */
  W[bootregs+1] = 0;                /* B */
  W[bootregs+2] = 0;                /* C */
  W[bootregs+3] = stackbase<<B2Wsh; /* P */
  W[bootregs+4] = globbase<<B2Wsh;  /* G */
  W[bootregs+5] = 2;                /* ST -- in boot, interrupts disabled */
  W[bootregs+6] = W[globbase+1];    /* PC (start in boot) */
  W[bootregs+7] = -1;               /* Count */
  W[bootregs+8] = 0;                /* MW */

  /* A debbugging aid!! */
  /* tracing = 1; */

  init_keyb();
  /* Call the slow interpreter even though Count=-1 */
  if (boottrace>0) PRINTF("Calling the interpreter\n");
  if (boottrace>1)
  { PRINTF("Turning instruction tracing on\n");
    tracing = 1;
  }

  res = interpret(bootregs, W);
  if (boottrace>0)
    PRINTFD("interpreter returned control to cintsys, res=%" FormD "\n", res);

  close_keyb();

  if (res) {
    PRINTFD("\nExecution finished, return code %" FormD"\n", res);

    if (res && W[rootnode+Rtn_dumpflag]) {
      dumpmem(W, memupb, 3);
      PRINTF("\nCintpos memory dumped to DUMP.mem, context=3\n");
    }
  }
  PRINTF("\n");
  /*Change suggested by Dave Lewis - return cli_returncode rather than res */
  return W[globbase+Gn_cli_returncode]; /* MR 17/01/06 */
  /*return res; */
}

BCPLWORD concatsegs(BCPLWORD seg1, BCPLWORD seg2) {
  BCPLWORD p = seg1;
  if(p==0 || seg2==0) return 0;
  while(W[p]) p = W[p];
  /*PRINTFD("concatsegs: seg1 %" FormD" ", seg1); */
  /*PRINTFD("seg2 %" FormD " ", seg2); */
  /*PRINTFD("p %" FormD "\n", p); */
  W[p] = seg2;
  return seg1;
}

BCPLWORD loadsegfp(FILEPT fp)
{ BCPLWORD list  = 0;
  BCPLWORD liste = 0;

  for(;;)
  { BCPLWORD type = rdhex(fp);
    /*PRINTFD("loadsegtype = %" FormD "\n", type); */
    switch((int)type)
    { default:
          err:   unloadseg(list);
                 list = 0;
      case -1:   
                 return list;
		 
      case T_hunk64:
               { BCPLWORD i, n=rdhex(fp);
                 BCPLWORD space = getvec(n);
		 /*
                 PRINTFD("loading hunk size %" FormD " ", n);
		 PRINTFD("to %" FormD "\n", space);
                 */
                 if(space==0) goto err;
                 W[space] = 0;
                 for(i = 1; i<=n; i++) W[space+i] = rdhex(fp);
		 //if(n<=24)for(i = 1; i<=n; i++)
		 //printf("%5lld  %5lld: %16llX\n",  space, i, W[space+i]);
                 if(list==0) list=space;
                 else W[liste] = space;
                 liste = space;
                 continue;
               }
		 
      case T_bhunk64: /* For hunks in binary (not hex) */
                { BCPLWORD n;
                  BCPLWORD space;
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
		 
      case T_end64:
	          break;
    }		 
  }		 
} 		 

BCPLWORD loadseg(char *file)
{ BCPLWORD list  = 0;
  BCPLWORD liste = 0;

  //PRINTF("loadseg: attempting to load file %s\n", file);

  // First look in the current directory
  FILEPT fp = pathinput(file, 0);

  if (fp)
  { list = loadsegfp(fp);
    fclose(fp);
    if (list) return list;
    fp = 0;
  }
 
  // The module was not found in the current directory or it
  // was invalid so look in the directories specified by the environment
  // variable whose name is in the pathvar entry of the rootnode.
  if(fp==NULL) {
    char envname[256];
    fp = pathinput(file, b2c_str(W[rootnode+Rtn_pathvar], envname));
  }

  //if(fp==NULL) {
  //  char chbuf[256];
  //  /* It was not found in the BCPL64PATH directories so */
  //  /* look in <BCPL64ROOT>/cin, ie preprend cin/ to file */
  //  /*PRINTFS("loadseg: searching for %s in $BCPL64ROOT/cin\n", file); */
  //  fp = pathinput(catstr2c_str("cin/", file, chbuf), "BCPL64ROOT");
  //}
  if(fp==NULL) return 0;

  list = loadsegfp(fp);
  fclose(fp);
  return list;
}

void unloadseg(BCPLWORD segl)
{ while(segl) { BCPLWORD s = W[segl];
                freevec(segl);
                segl = s;
              }
}

/* rdhex reads in one hex number including the terminating character
   and returns its BCPLWORD value. EOF returns -1.
*/
BCPLWORD rdhex(FILEPT fp)
{  BCPLWORD w = 0;
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
		 
BCPLWORD globin(BCPLWORD segl, BCPLWORD g)
{ BCPLWORD  a = segl, globsize = W[g];
  /*PRINTFD("globin segl = %6" FormD"  ", segl); */
  /*PRINTFD("g = %6" FormD "\n", g); */
  while (a) { BCPLWORD base = (a+1)<<B2Wsh;
              BCPLWORD i = a + W[a+1];
              if (W[i]>globsize) return 0;
	      /*PRINTFD("globin:  base %6" FormD "  ", a+1); */ 
	      /*PRINTFD("to %6" FormD "  ", i); */
	      /*PRINTFD("size: %5" FormD "\n", W[a+1]); */ 
              for(;;) { i -= 2;
                        if (W[i+1]==0) break;
                        W[g+W[i]] = base + W[i+1];
			/*
                        PRINTFD("globin:  g[%3" FormD "] ", W[i]);
			PRINTFD("= %6" FormD "\n", base+W[i+1]);
                        */
                      }
              a = W[a];
            }
  return segl;
}

BCPLWORD getvec(BCPLWORD requpb)
{ BCPLWORD upb = requpb+4+4;  /* Allocate 4 words at the end for safety */
                              /* plus 4 words of task name. */
  BCPLWORD p;
  BCPLWORD q = 0; /* The start of the block list */
  BCPLWORD n = (upb+1+1+1) & 0xFFFFFFFE;  /* Add 1 word for size and alloc bit
                                          and 1 word for word zero and
                                          then round up to an even size */
  
  do
  { p = q;
    for(;;) { BCPLWORD size = W[p];
              if((size&1) != 0) break;
              if( size == 0)    return 0;
              p += size;
            }
    q = p;  /* find next used block */
    for(;;) { BCPLWORD size = W[q];
              if((size&1) == 0) break;
              q += size-1;
            }
  } while(q-p<n);
  
  if(p+n!=q)
    W[p+n] = q-p-n+1; /* If splitting, the size of the other part with a
                         flag of 1 indicating that it is free */
  W[p] = n;           /* The size of this block in words with a flag of zero
                         indicating that it is allocated */
  /* The following improves the safety of memory allocation */
  /* by adding some checkable redundancy */
  W[p+n-9] = 0xCCCCCCCC;  /* Funny pattern for possible roundup word */
  W[p+n-8] = 0x55555555;  /* Special patterns */
  W[p+n-7] = 0xAAAAAAAA;
  W[p+n-6] = requpb;      /* The requested upb */

  W[p+n-5] = taskname[0]; /* The taskname, if any */
  W[p+n-4] = taskname[1]; /* The taskname, if any */
  W[p+n-3] = taskname[2]; /* The taskname, if any */
  W[p+n-2] = taskname[3]; /* The taskname, if any */

  W[p+n-1] = p;           /* Pointer to base of this memory block */
  /*PRINTFD("getvec: allocating block %6" FormD "  ", p); */
  /*PRINTFD("upb %4" FormD "\n", upb); */

  if(requpb>vecstatsvupb) requpb = vecstatsvupb;
  W[vecstatsvec+requpb]++;
  return p+1;
}

BCPLWORD freevec(BCPLWORD p)
{ BCPLWORD res = -1;  /* =TRUE */
  BCPLWORD n, upb;

  if(p==0) return res;

  p--;       /* All getvec'ed blocks start on odd addresses */
  n = W[p];

  if(n & 1) {
    PRINTFD("\n#### freevec: block at %" FormD " already free\n", p);
    return 0;
  }

  /*PRINTFD("#### freevec: Freeing block at %" FormD "\n", p); */

  if(W[p+n-1]!=p ||
     W[p+n-7]!=0xAAAAAAAA ||
     W[p+n-8]!=0x55555555) {
       PRINTFD("\n#### freevec: block at %" FormD " ", p);
       PRINTFD("size %" FormD " corrupted", n);
       PRINTFD("\n#### freevec: last 4 words %8" FormX " ", (UBCPLWORD)W[p+n-8]);
       PRINTFD("%8" FormX " ",                              (UBCPLWORD)W[p+n-7]);
       PRINTFD("%6" FormD " ",                              W[p+n-6]);
       PRINTFD("%7" FormD "\n",                             W[p+n-1]);
       PRINTFD("#### freevec: should be    55555555 AAAAAAAA requpb %7" FormD "\n\n",
                p);
       res = 0;
  }
  W[p] |= 1;
  /* Deal with getvec allocation statistics */
  upb = W[p+n-6];       /* The requested size */
  if(upb>vecstatsvupb) upb = vecstatsvupb;
  W[vecstatsvec+upb]--; /* Decrement count of block of this size */
  return res;
}

BCPLWORD muldiv1(BCPLWORD a, BCPLWORD b, BCPLWORD c) // Not for 64-bit BCPL
{ // This version produces the same results as muldiv1
  // and seem to run about 60% faster.
  // It is used by the MDIV instruction (and the syslib muldiv function).
  BCPLINT64 ab = (BCPLINT64)a * (BCPLINT64)b;
  if(c==0) c=1;
  result2 = (BCPLWORD)(ab % c);
  return (BCPLWORD)(ab / c);
}

BCPLWORD muldiv(BCPLWORD a, BCPLWORD b, BCPLWORD c)
{ // This is used by sys(Sys_muldiv,...)
  unsigned BCPLWORD q=0, r=0, qn, rn;
  unsigned BCPLWORD ua, ub, uc;
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
               if(r>=uc) { q++; r -= uc; }
             }
    ua >>= 1;
    qn <<= 1;
    rn <<= 1;
    if(rn>=uc) { qn++; rn -= uc; }
  }
  result2 = rneg ? -(BCPLWORD)r : r;
  return    qneg ? -(BCPLWORD)q : q;
}

int relfilename(char *name) {
/*
name is a C string representing a Cintsys/Cintpos file name.
If it starts with '/' (or '\') or contains a colon ':', it
represents an absolute file name otherwise it is relative.
This function returns
   0 if absolute,
   1 if relative.
*/
  if(name[0]=='/' || name[0]=='\\') return 0;
  while(*name) if(*name++==':') return 0;
  return 1; 
}

/* pathinput does not use any of chbuf1, chbuf2 or chbuf3. */
FILEPT pathinput(char *name, char *pathname)
/* name is a Linux style filename using '/' (not '\') as the separator.
   If pathname is null, name is looked up in the current directory,
   otherwise name is looked up in the directories that the environment
   variable pathname specifies. These directories should now be separated 
   by ';' (nor ':') even under Linux or Cygwin.
*/
{ FILEPT fp = 0;

  if ( pathname==0 || !relfilename(name)) {
    /* If no pathname given or name is absolute just search the current directory */
    //printf("pathinput: pathname=0\n");
    fp = fopen(osfname(name, chbuf4), "rb");
    if(filetracing)
    { PRINTFS("Trying: %s in the current directory - ", name);
      if(fp) {
        PRINTF("found\n");
      } else {
        PRINTF("not found\n");
      }
    }
    return fp;
  }

  //printf("pathinput: pathname=%s\n", pathname);

  /* Look through the PATH directories if pathname is given. */
  { char *path = getenv(pathname);
 
    if(filetracing) {
      PRINTFS("pathinput: attempting to open %s", name);
      PRINTFS(" using\n  %s", pathname);
      PRINTFS(" = %s\n", path);
    }

    /* Try prefixing with each directory in the path until the
       file can be openned successfully */
    while(path)
    { char str[256];
      char *filename = &str[0];
      char *f=filename;
      char *n=name;
      char lastch=0;
      // f points to the next character of constructed filename
      // n points to the next character of name

      // Prefix the next directory name after skipping over
      // a separator, if necessary.
      while(1)
      { char ch = *path;
        if(ch==';') { path++; continue; }
#ifndef WINNAMES
        if(ch==':') { path++; continue; }
#endif
        break;
      }
      if(*path==0) break;
      /* Copy the directory name into filename */
      while(1)
      { char ch = *path;
        if(ch==0) break;
        path++;
        if(ch==';') break;
#ifndef WINNAMES
	if(ch==':') break;
#endif
        *f++ = ch;
        lastch = ch;
      }
      /* Insert a filename '/' if necessary. */
      if(lastch!='/' && lastch!='\\') *f++ = '/';

      /* Append the given file name */
      while(1)
      { char ch = *n++;
        *f++ = ch;
        if(ch==0) break;
      }

      fp = fopen(osfname(filename, chbuf4), "rb");
      if(filetracing)
      { PRINTFS("Trying: %s - ", filename);
        if(fp) {
          PRINTF("found\n");
	} else {
          PRINTF("not found\n");
	}
      }
      if(fp) return fp;
      // Try using the next directory in the path
    }
    // Not found in any of the path directories so look in the
    // current directory

    fp = fopen(osfname(name, chbuf4), "rb");
    if(filetracing)
    { PRINTFS("Trying: %s in the current directory - ", name);
      if(fp) {
        PRINTF("found\n");
      } else {
        PRINTF("not found\n");
      }
    }
    return fp;
  }
}

BCPLWORD dosys(register BCPLWORD p, register BCPLWORD g)
{ register BCPLWORD i;
  /*PRINTFD("dosys(%" FormD ", ", p); */
  /*PRINTFD("%" FormD, g); */
  /*PINTFD(") P3=%" FormD " ", W[p+3]); */
  /*PRINTFD("P4=%" FormD "\n",  W[p+4]); */
  switch((int)(W[p+3]))
  { default: PRINTFD("\nBad sys number: %" FormD "\n", W[p+3]);
             return W[p+3];

    /* case Sys_setcount: set count               -- done in cinterp
    ** case Sys_quit:     return from interpreter -- done in cinterp

    ** case Sys_rti:      sys(Sys_rti, regs)      -- done in cinterp  Cintpos
    ** case Sys_saveregs: sys(Sys_saveregs, regs) -- done in cinterp  Cintpos
    ** case Sys_setst:    sys(Sys_setst, st)      -- done in cinterp  Cintpos
    */
    case Sys_tracing:  /* sys(Sys_tracing, b) */
            tracing = W[p+4];
            return 0;
    /* case Sys_watch:    sys(Sys_watch, addr)    -- done in cinterp
    */

    case  Sys_tally:         /* sys(Sys_tally, flag)     */
             if(W[p+4]) {
                tallylim = tallyupb;
                for(i=1; i<=tallylim; i++) tallyv[i] = 0;
              } else {
                tallylim = 0;
              }
              return 0;
     
    case Sys_interpret: /* call interpreter (recursively) */
            { BCPLWORD regsv = W[p+4];
		//printf("Sys_interpret: regsv=%lld\n", regsv);
		//printf("Sys_interpret: W[regsv+7]=%lld\n", W[regsv+7]);
              if(W[regsv+7]>=0 || slowflag) return interpret(regsv, W);
	      //printf("Sys_interpret: Calling CINTASM\n");
              return CINTASM  (regsv, W);
            }

    case Sys_sardch:
              { int ch;

                if (inbuf) {
                  /* Input taken from command line */
                  ch = inbuf_next();
                  if (ch == EOF) { /* inbuf is now empty */
                    if (reattach_stdin) {
                      free(inbuf);
                      inbuf = 0; /* Don't try to read more characters */
		                 /* from the buffer */
                      /* Continue with normal read from stdin */
                    } else {
                      return ch; /* EOF */
                    }
                  } else {
                    return ch; /* valid character */
                  }
                }
                /* Normal case, stdin input to interpreter */

                ch = Readch(); /* get the keyboard character  */
		/*PRINTFD("Sys_sardch: ch = %d\n", ch); */
		if(ch==127) /* RUBOUT from the keyboard */
		  ch = 8;   /* Replace by BS */
                if (ch>=0) putchar(ch);
                if(ch==13) { ch = 10; putchar(10); }
                fflush(stdout);
		/*PRINTFD("Sys_sardch returning ch = %d\n", ch); */
                //incdcount(1);
                return ch;
              }

    case Sys_sawrch:
#ifdef forCYGWIN32
              if(W[p+4] == 10) putchar(13);
#endif
              putchar((char)W[p+4]);
              fflush(stdout);
              //incdcount(2);
              return 0;

    case Sys_read:  /* bytesread := sys(Sys_read, fp, buf, bytecount) */
              { FILEPT fp = findfp(W[p+4]);
                BCPLWORD bbuf = W[p+5]<<B2Wsh;
                BCPLWORD len   = (int) W[p+6];
#ifndef forWinCE
                clearerr(fp); /* clear eof and error flag */
#endif
                len = fread(&(BP W)[bbuf], (size_t)1, (size_t)len, fp);
#ifndef forWinCE
                if(ferror(fp)) { perror("sys_read");
                                 return -1; /* check for errors */
		}
#endif
                return len;
              }

    case Sys_write:
      { FILEPT fp = findfp(W[p+4]);
        BCPLWORD bbuf = W[p+5]<<B2Wsh;
        BCPLWORD len = W[p+6];
        /*fseek(fp, 0L, SEEK_CUR); */ /* Why?? MR 9/7/04 */
        len = WD fwrite(&(BP W)[bbuf], (size_t)1, (size_t)len, fp);
        fflush(fp);
        return len;
      }

    case Sys_openread:
      { char *name = b2c_str(W[p+4], chbuf1);
        FILEPT fp;
        fp = pathinput(name,                      /* Filename */
	               b2c_str(W[p+5], chbuf2));  /* Environment
	      				             variable */
        if(fp==0) return 0L;
        return newfno(fp);
      }

    case Sys_openwrite:
      { char *name = b2c_str(W[p+4], chbuf1);
        FILEPT fp;
        fp = fopen(osfname(name, chbuf4), "wb");
        if(fp==0) return 0L;
        return newfno(fp);
      }

    case Sys_openappend:
      { char *name = b2c_str(W[p+4], chbuf1);
        FILEPT fp;
        fp = fopen(osfname(name, chbuf4), "ab");
        if(fp==0) return 0L;
        return newfno(fp);
      }

    case Sys_openreadwrite:
      { char *name = b2c_str(W[p+4], chbuf1);
	FILEPT fp;
        fp = fopen(osfname(name, chbuf4), "rb+");
        if(fp==0) fp = fopen(name, "wb+");
        if(fp==0) return 0L;
        return newfno(fp);
      }

    case Sys_close:
    { BCPLWORD res = fclose(findfp(W[p+4]));
      freefno(W[p+4]);
      return res==0 ? -1 : 0; /* res==0 means success */
    }

    case Sys_deletefile:
    { char *name = b2c_str(W[p+4], chbuf1);
      FILEPT fp;
      name = osfname(name, chbuf4);
#ifdef VMSNAMES
      { /* Append ';*' to name */
        int len = 0;
        while (name[len]) len++;
        name[len++] = ';';
        name[len++] = '*';
        name[len] = 0;
      }
#endif
      return ! REMOVE(name);
    }

    case Sys_renamefile:
    { char *name1 = b2c_str(W[p+4], chbuf1);
      char *name2 = b2c_str(W[p+5], chbuf2);
      int len = 0;
      name1 = osfname(name1, chbuf3);
      name2 = osfname(name2, chbuf4);
#ifdef VMSNAMES
      { /* Append ';*' to name2 */
        len = 0;
        while (name2[len]) len++;
        name2[len]   = ';';
        name2[len+1] = '*';
        name2[len+2] = 0;
      }
#endif
      REMOVE(name2);
#ifdef VMSNAMES
      name2[len] = 0;
#endif
      return ! rename(name1, name2);
    }

    case Sys_getvec:
              { BCPLWORD tcb = W[rootnode+Rtn_crntask];
                BCPLWORD *tn = &W[tcb+Tcb_namebase];
	        taskname[0] = (tcb==0) ? 0 : tn[0];
	        taskname[1] = (tcb==0) ? 0 : tn[1];
	        taskname[2] = (tcb==0) ? 0 : tn[2];
	        taskname[3] = (tcb==0) ? 0 : tn[3];
                return getvec(W[p+4]);
	      }

    case Sys_freevec:
                return freevec(W[p+4]);

    case Sys_loadseg:
              { BCPLWORD tcb = W[rootnode+Rtn_crntask];
                BCPLWORD *tn = &W[tcb+Tcb_namebase];
                char *name = b2c_str(W[p+4], chbuf2);
	        taskname[0] = (tcb==0) ? 0 : tn[0];
	        taskname[1] = (tcb==0) ? 0 : tn[1];
	        taskname[2] = (tcb==0) ? 0 : tn[2];
	        taskname[3] = (tcb==0) ? 0 : tn[3];
                return loadseg(name);
	      }

    case Sys_globin:
                return globin(W[p+4], g);

    case Sys_unloadseg:
                unloadseg(W[p+4]);                    return 0;

    case Sys_muldiv:
    { BCPLWORD res =  muldiv1(W[p+4], W[p+5], W[p+6]);
      W[g+Gn_result2] = result2;
      return res;
    }

    case Sys_intflag:
      return intflag() ? -1L : 0L;

    case Sys_setraster:
      return setraster(W[p+4], W[p+5]);

    case Sys_cputime: /* Return CPU time in milliseconds  */
      return muldiv(clock(), 1000, TICKS_PER_SEC);

#ifndef forWinCE
    case Sys_filemodtime:
    /* sys(Sys_filemodtime, filename, datv)
       Set the elements of datv to represent the date and time of
       the last modification of the given file, returning TRUE if
       successful and FALSE otherwise. datv!0 is the number of days
       since 1 January 1970, datv!1 is the number of milli-seconds
       since midnight and datv!2=-1 indicating that the new date and
       time format is being used.
       If the file does not exist or there is an error then
       FALSE is returned and the elements of datv are set to 0, 0 and
       -1, respectively.
    */
    { struct stat buf;
      BCPLWORD days, secs, msecs;
      char *name = b2c_str(W[p+4], chbuf1);
      BCPLWORD datestamp = W[p+5];
      if (stat(osfname(name, chbuf4), &buf)) {
        W[datestamp]   = 0;
        W[datestamp+1] = 0;
        W[datestamp+2] = -1;
        return 0;
      }
      secs = buf.st_mtime;
      // nsecs = buf.st_mtimensec; // nano second time, if poss
      days = secs / (24*60*60);
      msecs = (secs % (24*60*60)) * 1000;
      W[datestamp] = days;
      W[datestamp+1] = msecs;
      W[datestamp+2] = -1;  // New dat format
      //printf("filemodtime: name=%s days=%" FormD " msecs=%" FormD "\n",
      //        name, days, msecs);
      return -1;
    }
#endif

    case Sys_setprefix: /* Set the file name prefix string  */
    { BCPLWORD str = W[p+4];
      char *fp = (char*)(&W[str]);
      char *tp = (char*)(&W[prefixstr]);
      int i, len=*fp;
      if(len>63) return 0;
      for (i=0; i<=len; i++) *tp++ = *fp++;
      return prefixstr;
    }

    case Sys_getprefix: /* Return the file name prefix string  */
      return prefixstr;

    case Sys_graphics: /* Perform an operation on the graphics window  */
      return sysGraphics(p);

    case 35: /* Return TRUE if no keyboard character is available */
#ifdef forWinCE
              return chBufEmpty() ? -1 : 0;
#else
              return -1;
#endif

    case 36:   return 0; /* Spare */

    case 37:   return 0; /* Spare  */

    case Sys_seek:  /* res := sys(Sys_seek, fd, pos)   */
    { FILEPT fp = findfp(W[p+4]);
      BCPLWORD pos = W[p+5];
      BCPLWORD res = fseek(fp, pos, SEEK_SET);
      W[g+Gn_result2] = errno;
      /*PRINTFD("fseek pos=%" FormD " ", pos); */
      /*PRINTFD("=> res=%" FormD "\n", res); */
      /*PRINTFD("errno=%d\n", errno); */
      return res==0 ? -1 : 0; /* res=0 succ, res=-1 error  */
    }

    case Sys_tell: /* pos := sys(Sys_tell,fd)  */
    { FILEPT fp = findfp(W[p+4]);
      BCPLWORD pos = ftell(fp);
      W[g+Gn_result2] = errno;
      /*PRINTFD("tell => %" FormD "\n", pos); */
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
                        /* and generate interrupts */
      /*
      pthread_mutex_unlock(&irq_mutex);
      */
      return 0;

    case Sys_devcom: /* res := sys(Sys_devcom, dcb, com, arg) */
      return 0; /*devcommand(W[p+4], W[p+5], W[p+6]); */

    case Sys_datstamp: /* res := sys(Sys_datstamp, v)  */
    // Set v!0 = days  since 1 January 1970
    //     v!1 = msecs since midnight
    //     v!2 = ticks =-1 for new dat format
    // Return -1 if successful
                return timestamp(&W[W[p+4]]);

    case Sys_filesize:  /* res := sys(Sys_filesize, fd)   */
      { FILEPT fp   = findfp(W[p+4]);
        long pos  = ftell(fp);
        BCPLWORD rc   = fseek(fp, 0, SEEK_END);
        BCPLWORD size = ftell(fp);
        rc  = fseek(fp, pos, SEEK_SET);
        if (rc) size = -1;
        return size; /* >=0 succ, -1=error  */
      }

    case Sys_getsysval: /* res := sys(Sys_getsysval, addr) */
              { BCPLWORD addr = W[p+4];
                return W[addr];
              }

    case Sys_putsysval: /* res := sys(Sys_putsysval, addr, val) */
              { BCPLWORD addr = W[p+4];
                W[addr] = W[p+5];
                return 0;
              }

#ifndef forWinCE
    case Sys_shellcom: /* res := sys(Sys_shellcom, comstr) */
              { BCPLWORD comstr = W[p+4]<<B2Wsh;
	        int i;
                char com[256];
                int len = ((char *)W)[comstr];
                for(i=0; i<len; i++) com[i] = ((char *)W)[comstr+i+1];
                com[len] = 0;
		/*PRINTFS("\nmain: calling shell command %s\n", com); */
                return system(com);
              }
#endif

#ifndef forWinCE
    case Sys_getpid: /* res := sys(Sys_getpid) */
                return getpid();
#endif

    case Sys_dumpmem: /* sys(Sys_dumpmem, context) */
                dumpmem(W, memupb, W[p+4]);
                PRINTFD("\nMemory dumped to DUMP.mem, context=%" FormD "\n",
                        W[p+4]);
                return 0;

    case Sys_callnative: /* res := sys(Sys_callnative, fn, a1, a2, a3) */
              { /* Call native code. */
                union { /* To allow conversion from pointer to function */
		  BCPLWORD *p;
		  BCPLWORD(*f)(BCPLWORD, BCPLWORD, BCPLWORD);
                } func;

                func.p = &W[W[p+4]];
                return (func.f)(W[p+5],W[p+6],W[p+7]);
              }

    case Sys_platform:
              { /* Return platform code, 0 if unknown */
		BCPLWORD res = 0;
#ifdef forMAC
		res = 1;
#endif
#ifdef forMIPS
		res = 2;
#endif
#ifdef forSGI
		res = 3;
#endif
#ifdef forARM
		res = 4;
#endif
#ifdef forLinux
		res = 5;
#endif
#ifdef forLinuxamd64
		res = 6;
#endif
#ifdef forCYGWIN32
		res = 7;
#endif
#ifdef forLinuxPPC
		res = 8;
#endif
#ifdef forSUN4
		res = 9;
#endif
#ifdef forSPARC
		res = 10;
#endif
#ifdef forALPHA
		res = 11;
#endif
#ifdef forMSDOS
		res = 12;
#endif
#ifdef forOS2
		res = 13;
#endif
#ifdef forSHwinCE
		res = 14;
#endif
#ifdef forMIPSwinCE
		res = 15;
#endif
                return res;
              }              

    case Sys_inc: /* newval := sys(Sys_inc, ptr, amount) */
              { /* !ptr := !ptr + amount; RESULTIS !ptr */
                return W[W[p+4]] += W[p+5];
              }

    case Sys_buttons: /* Return bit pattern of buttons currently
                          pressed on the GP2X */
#ifdef forGP2X
              { unsigned long buttons = 0;
	        int fd = open("/dev/GPIO", O_RDWR | O_NDELAY);
	        if (fd<0) return -1;
                if (read(fd, &buttons, 4) != 4) return -2;
                close(fd);
                return (BCPLWORD)buttons;
              }
#else
              return -3;

#endif

    case Sys_delay: /* sys(Sys_delay, msecs) */
              { unsigned int msecs = (unsigned int)W[p+4];
                msecdelay(msecs);
                return 0;
              }

    case Sys_sound: /* res := sys(Sys_sound, fno, a1, a2,...) */
#ifdef SOUND
                return soundfn(&W[p+4], &W[g]);
#else
                return 0;
#endif

    case Sys_sdl: /* res := sys(Sys_sdl, fno, a1, a2,...) */
      return sdlfn(&W[p+4], &W[g], W);

    case Sys_callc: /* res := sys(Sys_callc, fno, a1, a2,...) */
#ifdef CALLC
      /*
         printf("dosys: sys(Sys_callc, %" FormD ", %" FormD ", %" FormD", ...)\n",
                 W[p+4], W[p+5], W[p+6]);
      */
                return callc(&W[p+4], &W[g]);
#else
                return -1;
#endif

    case Sys_trpush: /* sys(Sys_trpush, val) */
                trpush(W[p+4]);
                return 0;

    case Sys_settrcount: /* res := sys(Sys_settrcount, count) */
                return settrcount(W[p+4]);

    case Sys_gettrval: /* res := sys(Sys_gettrval, count) */
                return gettrval(W[p+4]);

    case Sys_flt: /* res := sys(Sys_flt, op, a, b)) */
              { BCPLWORD res = doflt(W[p+4], W[p+5], W[p+6]);
                W[g+Gn_result2] = result2;
		//if(W[p+4]==35)
		//printf("sys_flt: op=%d res=%08" FormX " result2=%08" FormX "\n",
                //       W[p+4], (UBCPLWORD)res, (UBCPLWORD)result2);
                return res;
              }

    case Sys_pollsardch: /* res := sys(Sys_pollsardch) */
              {
                // Return a character if available otherwise pollch (=-3)
                return pollReadch();
              }

    case Sys_incdcount: /* res := sys(Sys_incdcount, n) */
                return incdcount(W[p+4]);


#ifndef forWinCE
    case 135:
    { /* Return system date and time in VEC 5 */
      time_t clk = time(0);
      struct tm *now = gmtime(&clk);
      BCPLWORD *arg = &W[W[p+4]];
      arg[0] = now->tm_year+1900;
      arg[1] = now->tm_mon+1;
      arg[2] = now->tm_mday;
      arg[3] = now->tm_hour;
      arg[4] = now->tm_min;
      arg[5] = now->tm_sec;
      return 0;
    }
#endif

  }
  // This is unreadchable
  // return 0;
}

void msecdelay(unsigned int delaymsecs) {
#if (defined(forWIN32) || defined(forWinCE))
  { Sleep(delaymsecs); // ?????????????????
                return;
              }
#else
	      /*
              { while(delaymsecs>=1000) {
                  usleep(990000);
                  msecs -= 990;
                }
                if (delaymsecs>0) usleep(delaymsecs*1000);
                return;
              }
              */
              { // This version uses select() rather than usleep() or
                // nanosleep() since these seem to have problems on some
                // systems.
                const BCPLWORD msecsperday = 24*60*60*1000;
                BCPLWORD days, msecs;
                BCPLWORD tv[3]; // to hold [days, msecs, -1]
                struct timeval timeout;
                timestamp(tv);
                // calculate the wakeup time
                days = tv[0];               
                msecs = tv[1] + delaymsecs;
                if (msecs>=msecsperday) { days++; msecs -= msecsperday; }

                while(1) {
                  BCPLWORD diffdays, diffmsecs;
                  timestamp(tv);
                  diffdays = days - tv[0];
                  diffmsecs = msecs - tv[1];
                  if (diffdays>0) { diffdays--; diffmsecs += msecsperday; }
		  //printf("Sys_delay: diffmsecs = %" FormD " msec\n", diffmsecs);
                  if (diffmsecs<=0) return;
                  if (diffmsecs>900) diffmsecs = 900;
                  timeout.tv_sec = 0;
                  timeout.tv_usec = diffmsecs * 1000;
		  //printf("Sys_delay: waiting for %" FormD " msec\n", diffmsecs);
                  select(FD_SETSIZE, NULL, NULL, NULL, &timeout);
                }
              }
#endif
}

#ifdef NOFLOAT

BCPLWORD doflt(BCPLWORD op, BCPLWORD a, BCPLWORD b) {
  return 0;
}

#else

BCPLWORD doflt(BCPLWORD op, BCPLWORD a, BCPLWORD b) {
  // Typically a is left operand
  // and b is the right operand, if required
  union { BCPLWORD i; float f; } x, y;
  double dx, dy;

  //printf("doflt entered op=%" FormD " fl_mk=%" FormD "\n", op, fl_mk);

  switch (op) {
  default:
    printf("doflt(%" FormD ", %" FormD ", %" FormD ") not implemented\n", op, a, b);

  case fl_avail:
    return -1;

  case fl_mk:
  { // a=mantissa, b=exponent
    double res = (double) a;
    while(b> 5) { res *= 100000.0; b-=5; }
    while(b> 0) { res *=     10.0; b--;  }
    while(b<-5) { res /= 100000.0; b+=5; }
    while(b< 0) { res /=     10.0; b++;  }
    x.f = (float) res;
    return x.i;
  }
  case fl_unmk:
  { BCPLWORD mantissa, exponent=0;
    double d;
    int neg = 0;
    x.i = a;
    d = x.f;
    //printf("d = %15.9g %" FormD "\n", d, exponent);
    if (d<0.0) { d = -d; neg = 1; }
    //printf("d = %15.9g %" FormD "\n", d, exponent);
    while (d>=100000.0) {
      d /= 100000.0; exponent+=5;
      //printf("d = %15.9g %" FormD "\n", d, exponent);
    }
    while (d>=1.0) {
      d /= 10.0; exponent++;
      //printf("d = %15.9g %" FormD "\n", d, exponent);
    }
    while (d<=0.00001 && exponent>=-400) {
      d *= 100000.0; exponent-=5;
      //printf("d = %15.9g %" FormD "\n", d, exponent);
    }
    while (d<0.1 && exponent>=-400) {
      d *= 10.0; exponent--;
      //printf("d = %15.9g %" FormD "\n", d, exponent);
    }
    if (exponent>=-400) {
      mantissa = (BCPLWORD) (d * 1000000000.0 + 0.5);
      exponent -= 9;
    } else {
      mantissa = 0;
      exponent = 0;
    }
    result2 = exponent;
    if (neg) mantissa = -mantissa;
    return mantissa;
  }    

  case fl_float:
    x.f = (float)a; 
    return x.i;

  case fl_fix:
    x.i = a;
    if(x.f<0) return (BCPLWORD)(x.f - 0.5);
    return (BCPLWORD)(x.f + 0.5);

  case fl_abs:
    x.i = a;
    if (x.f<0.0) x.f = -x.f;
    return x.i;

  case fl_mult:
    x.i = a; y.i = b;
    x.f = x.f * y.f;
    return x.i;

  case fl_div:
    x.i = a; y.i = b;
    x.f = x.f / y.f;
    return x.i;

  case fl_plus:
    x.i = a; y.i = b;
    x.f = x.f + y.f;
    return x.i;

  case fl_minus:
    x.i = a; y.i = b;
    x.f = x.f - y.f;
    return x.i;

  case fl_pos:
    return a;

  case fl_neg:
    x.i = a;
    x.f = -x.f;
    return x.i;

  case fl_eq:
    x.i = a; y.i = b;
    return x.f == y.f ? -1 : 0;

  case fl_ne:
    x.i = a; y.i = b;
    return x.f != y.f ? -1 : 0;

  case fl_ls:
    x.i = a; y.i = b;
    return x.f < y.f ? -1 : 0;

  case fl_gr:
    x.i = a; y.i = b;
    return x.f > y.f ? -1 : 0;

  case fl_le:
    x.i = a; y.i = b;
    return x.f <= y.f ? -1 : 0;

  case fl_ge:
    x.i = a; y.i = b;
    return x.f >= y.f ? -1 : 0;

  case fl_acos:
    x.i = a;
    x.f = acos(x.f);
    return x.i;

  case fl_asin:
    x.i = a;
    x.f = asin(x.f);
    return x.i;

  case fl_atan:
    x.i = a;
    x.f = atan(x.f);
    return x.i;

  case fl_atan2:
    x.i = a; y.i = b;
    x.f = atan2(x.f, y.f);
    return x.i;

  case fl_cos:
    x.i = a;
    x.f = cos(x.f);
    return x.i;

  case fl_sin:
    x.i = a;
    x.f = sin(x.f);
    return x.i;

  case fl_tan:
    x.i = a;
    x.f = tan(x.f);
    return x.i;

  case fl_cosh:
    x.i = a;
    x.f = cosh(x.f);
    return x.i;

  case fl_sinh:
    x.i = a;
    x.f = sinh(x.f);
    return x.i;

  case fl_tanh:
    x.i = a;
    x.f = tanh(x.f);
    return x.i;

  case fl_exp:
    x.i = a;
    x.f = exp(x.f);
    return x.i;

  case fl_frexp:
  { int r2;
    x.i = a;
    x.f = frexp(x.f, &r2);
    result2 = r2;
    return x.i;
  }

  case fl_ldexp:
    x.i = a;
    x.f = ldexp(x.f, b);
    return x.i;

  case fl_log:
    x.i = a;
    x.f = log(x.f);
    return x.i;

  case fl_log10:
    x.i = a;
    x.f = log10(x.f);
    return x.i;

  case fl_modf:
    { double r1, r2;
      x.i = a;
      //printf("modfx.f=%15.6g => ", x.f);
      r1 = modf((double)x.f, &r2);
      //printf("%15.6g %15.6g\n", r1, r2);
      x.f = (float)r1;
      //printf("%15.6g %08" FormX "\n", x.f, (UBCPLWORD)x.i);
      result2 = (BCPLWORD)r2;

      //printf("modf set result2=%08" FormX " returning %08" FormX "\n",
      //        result2, (BCPLWORD)x.i);
      return (BCPLWORD)x.i;
    }

  case fl_pow:
    x.i = a; y.i = b;
    x.f = pow(x.f, y.f);
    return x.i;

  case fl_sqrt:
    x.i = a;
    x.f = sqrt(x.f);
    return x.i;

  case fl_ceil:
    x.i = a;
    x.f = ceil(x.f);
    return x.i;

  case fl_floor:
    x.i = a;
    x.f = floor(x.f);
    return x.i;

  case fl_fmod:
    x.i = a; y.i = b;
    x.f = fmod(x.f, y.f);
    return x.i;
  };
  //printf("doflt(%" FormD ", %" FormD ", %" FormD ") not implemented\n", op, a, b);

  //return 0;
}
#endif

BCPLWORD timestamp(BCPLWORD *v) {
  // Set v[0] = days since 1 January 1970
  //     v[1] = msecs since midnight
  //     v[2] = -1 for new dat format
  // Return -1 if successful
#if defined(forWinCE) || defined(forMacOSPPC) || defined(forMacOSX)
  v[0]=v[1]=0;
  v[2]=-1;
  return 0;   /* To indicate failure */
#else
  unsigned int days  = 0;
  BCPLINT64    secs = 0;
  unsigned int msecs = 0;

  const unsigned int secsperday = 60*60*24;

#if defined(forWIN32) || defined(forCYGWIN32) || defined(forLinux)
  { // Code for Windows, Cygwin and Linux
    // ftime is obsolete and the advice is to use
    // gettimeofday or clock_gettime
    // neither of these are widely available yet.
    struct timeb tb;
    ftime(&tb);
    secs = tb.time;
    //if(tb.dstflag) secs += 60*60;
    secs -= tb.timezone * 60;
    //printf("tb.dstflag=%" FormD " tb.timezone=%" FormD "\n",
    //        tb.dstflag, tb.timezone);
    msecs = tb.millitm;
  }
#else
  // Code for systems having the function gettimeofday.
  struct timeval tv;
  gettimeofday(&tv, NULL);
  secs = tv.tv_sec;
  msecs = tv.tv_usec / 1000;
  secs += 60*60;     /* Fudge -- Add one hour for BST */
#endif

  // secs  = seconds since 1 January 1970
  // msecs = micro seconds since start of current second

  secs += W[rootnode+Rtn_adjclock] * 60; /* Add adjustment */

  days  += secs / secsperday; // convert secs to days
  secs  %= secsperday; // Seconds since midnight
  msecs += secs*1000;  // milliseconds since midnight

  v[0] = days;  // days  since on 1 January 1970
  v[1] = msecs; // msecs  since midnight
  v[2] = -1;    // For new dat format
  //  printf("days=%" FormD " msecs=%" FormD "\n", days, msecs);
  return -1;   /* To indicate success */
#endif
}

char *vmsfname(char *name, char *vmsname) {
/*
This function converts a cintsys/cintpos filename to a VMS filename

Examples:

Name                       VMS name

echo.b                     echo.b
com/echo.b                 [.com]echo.b
/mrich177/distribution/bcpl/g/libhdr.h
                           [mrich177.distribution.bcpl.g]libhdr.h
vd10$disk:/mrich177/junk.b vd10$disk:[mrich177]junk.b
../cintcode/com/bcplfe.b   [-.cintcode.com]bcplfe.b
*/
  int ch;
  int i=0; // Next character in name
  int j=0; // Next character in vmsname
  int lastslashpos=-1; // Position of last slash in name

  /* If name contains a colon, copy all
     characters up to and including the colon.
  */
  while (1) {
    int ch = name[i];
    if (ch==0) {
      /* No colon in name */
      i = 0;
      break;
    }
    if (ch==':') {
      /* Copy up to and including the colon */
      while (j<=i) { vmsname[j] = name[j]; j++; }
      i = j;
      break;
    }
    i++;
  }
  /* Find position of last slash, if any */
  while (1) {
    int ch = name[i];
    if(ch==0) break;
    if(ch=='/') lastslashpos = i;
    i++;
  }

  /* No slashes  => nothing
     Leading /   => [
     Slashes but no leading slash so insert [. or [-

     name is then copied converting all slashes except the leading
     and last ones to dots, and converting the last slash to ].
  */
  i = j;
  if(name[i]=='/') {
    /* if leading slash but not the last convert it to [ */
    if (i!=lastslashpos) vmsname[j++] = '[';
    /* Otherwise skip over this leading slash */
    i++;
  } else {
    if (lastslashpos>=0) {
      /* Slashes but no leading slash, so insert [. or [-  */
      vmsname[j++] = '[';
      if(name[i]!='.' || name[i+1]!='.') {
        vmsname[j++] = '.';
      }
    }
  }

  while (1) {
    /* Copy characters
       replacing last /      by ]
       and       non last /  by .
       and       ..          by -
    */
    int ch = name[i];
    if(ch=='.' && name[i+1]=='.') {
      /* Convert .. to - */
      ch = '-';
      i++;
    }
    if(ch=='/') {
      if (i==lastslashpos) ch = ']';
      else                 ch = '.';
    }
    vmsname[j++] = ch;
    if(ch==0) break;
    i++;
  }
  /*
  printf("vmsfname of %s\n", name);
  printf("gives:      %s\n", vmsname);
  */

  return vmsname;
}

char *winfname(char *name, char *osname) {
/*
This function converts a cintsys/cintpos filename to a WIN filename

This copies name to winname replacing all '/' characters by '\'s.
*/
  char *p = osname;
  while(1) {
    int ch = *name++;
    if(ch=='/') ch = '\\';
    *p++ = ch;
    if(ch==0) return osname;
  }
}

char *unixfname(char *name, char *osname) {
/*
This function converts a cintsys/cintpos filename to a Unix filename
This copies name to winname replacing all '/' characters by '\'s.
*/
  char *p = osname;
  //printf("unixfname: name=%s\n", name);
  while(1) {
    int ch = *name++;
    if(ch=='\\') ch = '/';
    *p++ = ch;
    if(ch==0) return osname;
  }
}

char *osfname(char *name, char *osname) {
/*
This function converts the cintsys/cintpos filename to the OS filename
format. The possible formats are UNIX, WIN or VMS.
*/
  char *res=0;
  char buf[256];

  //printf("osfname: name=%s\n", name);

#ifdef VMSNAMES
  res = vmsfname(prepend_prefix(name, buf), osname);
#endif
#ifdef WINNAMES
  res = winfname(prepend_prefix(name, buf), osname);
#endif
#ifdef UNIXNAMES
  res = unixfname(prepend_prefix(name, buf), osname);
#endif
  if(res==0) {
    printf("Configuration error: ");
    printf("One of UNIXNAMES, WINNAMES or VMSNAMES must be set\n");
    return 0;
  }
  if(filetracing) {
    printf("osfname: %s => %s\n", name, res);
  }
  return res;
}

/*
Copy the prefix string into tostr and then append the fromstr
inserting '/' if necessary.
*/
char *prepend_prefix(char *fromstr, char *tostr)
{ char *pfxp = prefixbp;
  int pfxlen = *pfxp++;
  int i = 0;
  //printf("prepend_prefix: fromstr=%s pfxlen=%d\n", fromstr, pfxlen);
  if(pfxlen==0) return fromstr;
  if(!relfilename(fromstr)) return fromstr;

  //printf("prepend_prefix: prepending the prefix\n");

  while(pfxlen--) tostr[i++] = *pfxp++;
  /* Insert separator '/' between the prefix and name, if necessary. */
  if(tostr[i-1]!='/' || tostr[i-1]!='\\') tostr[i++] = '/';

  while (1)
  { char ch = *fromstr++;
    tostr[i++] = ch;
    if(ch==0) break;
  }
  //printf("prepend_prefix: gives tostr=%s\n", tostr);
  return tostr;
}

/*
** c2b_str converts a C string to a BCPL string.
*/
void c2b_str(char *cstr, BCPLWORD bstr)
{ int len = 0;
  char *p = cstr;
  char *str = ((char*)(W+bstr));
  while (*p && len<64) str[++len] = *p++; 
  str[0] = len;
}

/* b2c_str converts a BCPL string to a C character string. */
char *b2c_str(BCPLWORD bstr, char *cstr)
{ BCPLWORD bp = bstr<<B2Wsh;
  char *p = cstr;
  int len = (BP W)[bp++];
  if (bstr==0) return 0;
  while (len--) *p++ = (BP W)[bp++];
  *p = 0;
  return cstr;
}

/* syscin2b_str converts a syscin filename string to a BCPL string. */
BCPLWORD syscin2b_str(char *cstr, BCPLWORD bstr)
{  char *prfx = "syscin/";    /* System cin directory */
   char *bp = &((char *)W)[bstr<<B2Wsh];
   int len = 0;
   int i = 0;
   while (prfx[i]) { bp[++len] = prfx[i++]; }
   i = 0;
   while (cstr[i]) { bp[++len] = cstr[i++]; }
   bp[0] = len;
   return bstr;
}

/* catstr2c_str concatenates two optional C strings into str. */
char *catstr2c_str(char *cstr1, char *cstr2, char *str) {
  char *p = str;
  if (cstr1)
    while(*cstr1) *p++ = *cstr1++;
  if (cstr1)
    while(*cstr2) *p++ = *cstr2++;
  *p = 0;
  return str;
}

void wrcode(char *form, BCPLWORD f, BCPLWORD a)
{  wrfcode(f);
   PRINTF ("  ");
   PRINTFD(form, a);
   PRINTF ("\n");
} 

void wrfcode(BCPLWORD f)
{ char *s;
  int i, n = (f>>5) & 7;
  switch((int)f&31)
  { default:
    case  0: s = "     -     K   LLP     L    LP    SP    AP     A"; break;
    case  1: s = " FLTOP    KH  LLPH    LH   LPH   SPH   APH    AH"; break;
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
    case 15: s = "   LM1   L2G  L2G1  L2GH  LP15  SP15   BTC  MDIV"; break;
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
    case 30: s = "  JEQ0  JNE0  JLS0  JGR0  JLE0  JGE0 ST1P4 SELLD"; break;
    case 31: s = " JEQ0$ JNE0$ JLS0$ JGR0$ JLE0$ JGE0$    MW SELST"; break;
  }

  for(i = 6*n; i<=6*n+5; i++) putchar(s[i]);
} 

void trval(BCPLWORD w) {
  BCPLWORD gw = w & 0xFFFF0000;
  BCPLWORD gn = w & 0x0000FFFF;
    if(gw==Globword && gn<=1000) {
      PRINTFD("     #G%03" FormD"# ", gn);
    } else {
      if(-10000000<=w && w<=10000000) {
        PRINTFD(" %10" FormD " ", w);
      } else {
        PRINTFD(" #x%8" FormX " ", (UBCPLWORD)w);
      }
    }
}

void trace(BCPLWORD pc, BCPLWORD p, BCPLWORD a, BCPLWORD b)
{ PRINTFD("A="); trval(a);
  PRINTFD("B="); trval(b);
  PRINTFD("P=%5" FormD " ", p);
  PRINTFD("%9" FormD ": ", pc);
  wrcode("(%3" FormD ")", WD (BP W)[pc], WD (BP W)[pc+1]);
  putchar(13);
}

void dumpmem(BCPLWORD *mem, BCPLWORD upb, BCPLWORD context)
{ FILEPT fp;
  BCPLWORD count = upb;
  BCPLWORD p=0, q, r=0;
  int len = 0;
  BCPLWORD datstamp[3];

  fp = fopen("DUMP.mem", "wb");
  if(fp==0) goto bad;

  mem[rootnode + Rtn_lastp]   = lastWp-W;
  mem[rootnode + Rtn_lastg]   = lastWg-W;
  mem[rootnode + Rtn_lastst]  = lastst;

  mem[rootnode + Rtn_context] = context;
  /* context = 1   SIGINT received                 (lastp, lastg)
  ** context = 2   SIGSEGV received                (lastp, lastg)
  ** context = 3   fault while running boot        (bootregs)
  ** context = 4   user called sys(Sys_quit, -2)   (klibregs)
  ** context = 5   fault while user running        (klibregs)
  */

  datstamp[0]=datstamp[1]=datstamp[2]=0;
  timestamp(datstamp);
  mem[rootnode + Rtn_days]  = datstamp[0]; // days
  mem[rootnode + Rtn_msecs] = datstamp[1]; // msecs
  mem[rootnode + Rtn_ticks] = -1;          // new dat format

  /* Write out size of cintcode memory */
  /*PRINTFD("\n%8" FormD " Memory upb\n", upb); */
  len = fwrite((char*)&count, (size_t)4, (size_t)1, fp);
  if(len!=1) goto bad;

  while(r<=upb)
  { BCPLWORD dataword = mem[r];
    q = r;
    while(r<=upb && mem[++r]==dataword) continue;
    if(r<=upb && r-q < 200) continue;

    /* mem[p]..mem[q-1] is the block
    ** mem[q]..mem[r-1] are repeated occurrences of dataword
    ** Write out count of words in next block
    */
    count = q-p; /* count>=0 */
    if(count)
    { /*PRINTFD("%8" FormD " BLOCK\n", count); */
      len = fwrite((char*)&count, (size_t)4, (size_t)1, fp);
      if(len!=1) goto bad;
      len = fwrite((char*)&mem[p], (size_t)4, (size_t)count, fp);
      if(len!=count) goto bad;
    }

    /* Write out repetition count (negated) followed by the data word */
    count = q-r; /* count<=0 */
    if(count) {
      /*printf("%8" FormD " x %8" FormX "\n", -count, (UBCPLWORD)dataword); */
      len = fwrite((char*)&count,    (size_t)4, (size_t)1, fp);
      if(len!=1) goto bad;
      len = fwrite((char*)&dataword, (size_t)4, (size_t)1, fp);
      if(len!=1) goto bad;
    }

    p = r;
  }

 bad:
  if(fp) fclose(fp);
  /*PRINTFD("\nMemory dumped to DUMP.mem, context=%" FormD "\n", context); */
  return; 
}

void trpush(BCPLWORD val) {
  // If trcount>=0 push val into the circular trace buffer
  // possibly preceeded by a time stamp.
  // Note that trpush is disabled if trcount=-1
  /*  pthread_mutex_lock(&trpush_mutex); */
  if(trcount>=0) {
#if defined(forWinCE) || defined(forMacOSPPC) || defined(forMacOSX)
#else
    BCPLWORD v[3];
    BCPLWORD msecs;
    timestamp(v);
    msecs = v[1]; /* milli-seconds since midnight */
    // Push the time stamp: hex 66000000 + <msecs since midnight>
    trvec[trcount++ & 4095] = 0x66000000 + msecs%60000;
#endif
    trvec[trcount++ & 4095] = val;
  }
  /*  pthread_mutex_unlock(&trpush_mutex); */
}

BCPLWORD settrcount(BCPLWORD count) {
  // Set trcount returning the previous value.
  // Setting trcount to -1 disables trpush.
  BCPLWORD res;
  /* pthread_mutex_lock(&trpush_mutex); */
  res = trcount;
  trcount = count;
  /* pthread_mutex_unlock(&trpush_mutex); */
  return res;
}

BCPLWORD gettrval(BCPLWORD count) {
  // Return the trace value corresponding to position count.
  // The result is only valid if the circular buffer has not overflowed
  BCPLWORD res;
  //pthread_mutex_lock(&trpush_mutex);
  res = trvec[count & 4095];
  //pthread_mutex_unlock(&trpush_mutex);
  return res;
}

BCPLWORD incdcount(BCPLWORD n) {
  BCPLWORD dv = W[rootnode + Rtn_dcountv];
    if(0 < n && n <= W[dv]) return ++W[dv+n];
  return -1;
}

#ifdef SOUND
#include "soundfn.c"
#endif

