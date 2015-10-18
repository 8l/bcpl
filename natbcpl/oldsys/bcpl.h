/* This header file contains machine/system dependent #defines
** These are dependent on the -D parameter specified in Makefile.
** The possible -D parameters are:
**
**  -DforMAC           for Apple MAC (not recently tested)
**  -DforMIPS          for DEC R2000/3000 Workstations under Ultrix 4.3
**  -DforLINUX         for Linux
**  -DforSUN4          for Sun4m under SunOS 4.1.3
**  -DforSPARC         for Sun4m spac under SunOS 5.4
**  -DforALPHA         for DEC Alpha under OSF1 V3.2 17 (64 bit wordsize)
**  -DforMSDOS         for MSDOS 32 bit protected mode using Borland C v4.0
**  -DforOS2           for OS/2 V2.1 using Cset/2 and Borland Tasm
*/

/* The MAC version just about works on a Power Macitosh 7100/66
** using Symantec Think C 6.0
** I used cintmain.c cinterp.c kblib.c and nullrastlib.c linked
** with the standard libraries ANSI and unix. The partition size was 5000K
** and #define forMAC was edited into this file. (I don't know how to
** get Think C to do that #definition for me).
** The command command files bc bs bp bco and bso had to be edited to
** change /s to :s and ../ to :: etc. These versions are in sys/MAC.
** If someone would suggest how to get a visible cursor I would be grateful.
*/

/*
** Cintmain and cinterp need the type signed char but this is
** not available on all implementations of C. On some the type char
** is signed, and on some (if fact most) signed char is allowed.
** Comment out of the following definitions of SIGNEDCHAR. A test in
** the function badimplementation in cintmain.c will determine whether
** you have made the right choice.
*/

#define SIGNEDCHAR signed char
/* #define SIGNEDCHAR char */

#ifdef forMAC
#include <unix.h>
#include <time.h.h>
#define WORD long
#define B2Wsh 2
#define BPW 4
#define MALLOC(n) malloc((n)*BPW)
#define TICKS_PER_SEC (CLOCKS_PER_SEC)
#define CINTASM interpret
#define REMOVE unlink
#define FILE_SEP_CH ':'
#define BIGENDER
#endif

#ifdef forMIPS
#include <sys/types.h>
#include <sys/stat.h>
#include <time.h>
#define WORD long
#define B2Wsh 2
#define BPW 4
#define MALLOC(n) malloc((n)*BPW)
#define TICKS_PER_SEC (CLOCKS_PER_SEC)
#define CINTASM interpret
#define REMOVE unlink
#define FILE_SEP_CH '/'
#endif

#ifdef forLINUX
#include <sys/stat.h>
#include <time.h>
#define WORD long
#define B2Wsh 2
#define BPW 4
#define MALLOC(n) malloc((n)*BPW)
#define TICKS_PER_SEC (CLOCKS_PER_SEC)
#define CINTASM cintasm
#define REMOVE unlink
#define FILE_SEP_CH '/'
#endif

#ifdef forSUN4
#include <sys/stat.h>
#define WORD long
#define B2Wsh 2
#define BPW 4
#define MALLOC(n) malloc((n)*BPW)
#define TICKS_PER_SEC (1000000)
#define CINTASM interpret
#define REMOVE unlink
#define FILE_SEP_CH '/'
#define BIGENDER
#endif

#ifdef forSPARC
#include <sys/stat.h>
#include <time.h>
#define WORD long
#define B2Wsh 2
#define BPW 4
#define MALLOC(n) malloc((n)*BPW)
#define TICKS_PER_SEC (CLOCKS_PER_SEC)
#define CINTASM interpret
#define REMOVE unlink
#define FILE_SEP_CH '/'
#define BIGENDER
#endif

#ifdef forALPHA
#include <sys/stat.h>
#include <stdlib.h>
#define WORD long long
#define B2Wsh 3
#define BPW 8
#define MALLOC(n) malloc((n)*BPW)
#define TICKS_PER_SEC (CLOCKS_PER_SEC)
#define CINTASM cintasm
#define REMOVE unlink
#define FILE_SEP_CH '/'
#endif

#ifdef forMSDOS
#include <sys\stat.h>
#include <time.h>
#define WORD long
#define B2Wsh 2
#define BPW 4
#define MALLOC(n) malloc((n)*BPW)
#define TICKS_PER_SEC (CLK_TCK)
#define CINTASM cintasm
#define REMOVE unlink
#define FILE_SEP_CH '\\'
#endif

#ifdef forOS2
#include <sys\stat.h>
#define WORD long
#define B2Wsh 2
#define BPW 4
#define MALLOC(n) malloc((n)*BPW)
#define TICKS_PER_SEC (CLOCKS_PER_SEC)
#define CINTASM interpret
#define REMOVE remove
#define FILE_SEP_CH '\\'
#endif


typedef WORD *WORDpt;

#define WD (WORD)
#define UWD (unsigned WORD)
#define PT (WORD *)
#define BP (unsigned char *)
#define SBP (SIGNEDCHAR *)
#define HP (unsigned short *)
#define SHP (short *)

/* Functions defined in kblib.c  */
extern int Readch(void);
extern int init_keyb(void);
extern int close_keyb(void);
extern int intflag(void);

/* externals defined in init*.c  */
extern WORD stackupb;
extern WORD gvecupb;
extern void initsections(WORD *);

