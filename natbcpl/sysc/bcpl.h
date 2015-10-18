/* This header file contains machine/system dependent #defines
** These are dependent on the -D parameter specified in Makefile.
** The possible -D parameters are:
**
**  -DforMAC           for Apple MAC (not recently tested)
**  -DforMIPS          for DEC R2000/3000 Workstations under Ultrix 4.3
**  -DforSGI           for SGI MIPS machines under Ultrix
**  -DforARM           for ARM under RISC OS (under development)
**  -DforLINUX         for Linux on a Pentium
**  -DforVmsItanium    for the Itanium under VMS
**  -DforVmsVax        for the Vax under VMS
**  -DforLINUX64       for 64-bit Linux
**  -DforGP2X          for the GP2X handheld Linux gaming machine
**  -DforLINUXAMD64    for Linux on the AMD 64
**  -DforLINUXPPC      for Linux on a PowerMac G4
**  -DforMacOSPPC      for Mac OS X on a Mac Power PC G4
**  -DforMacOSX        for Mac OS X
**  -DforSUN4          for Sun4m under SunOS 4.1.3
**  -DforSPARC         for Sun4m spac under SunOS 5.4
**  -DforALPHA         for DEC Alpha under OSF1 V3.2 17
**  -DforMSDOS         for MSDOS 32 bit protected mode usinf Borland C v4.0
**  -DforWin32         for Windows (eg XP) using Microsoft Visual C
**  -DforCYGWIN32      for Windows (eg XP) using GNU Cygnus Solutions
**  -DforBC4           for Windows (eg XP) using Borland C 4.0 and TASM
**  -DforOS2           for OS/2 V2.1 using Cset/2 and Borland Tasm
**  -DforSHwinCE       for WinCE 2.0 (SH3 processor)
*/

/* INT.h is created by mkint-h (source mkint-h.c), it defines
** the macros BCPLINT32 and BCPLINT64
*/
#include "INT.h"

#ifndef forWinCE
#include <stdio.h>
#endif

#ifndef forWIN32
#include <unistd.h>
#endif

#ifndef forWinCE
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#endif

#ifndef forWIN32
#include <sys/time.h>
#endif

#ifndef forWinCE
#include <time.h>
#include <errno.h>
#include <math.h>
#endif

/* For 32-bit implementations -- uncomment the following */
#define B2Wsh 2
#define BperW 32
#define BCPLWORD BCPLINT32
#define UBCPLWORD BCPLUINT32
#define FormD FormD32
#define FormX FormX32

/* For 64-bit implementations -- uncomment the following */
/*
#define B2Wsh 3
#define BperW 64
#define BCPLWORD BCPLINT64
#define UBCPLWORD BCPLUINT64
#define FormD FormD64
#define FormX FormX64
*/

/*
** Cintsys/Cintpos and cinterp need the type signed char but this is
** not available on all implementations of C. On some the type char
** is signed, and on some (in fact most) signed char is allowed.
** Comment out of the following definitions of SIGNEDCHAR. A test in
** the function badimplementation will determine whether you have made
** the right choice.
*/

#define UNSIGNEDCHAR unsigned char
#define SIGNEDCHAR signed char
/* #define SIGNEDCHAR char */

#define PRINTFS printf
#define PRINTFD printf
#define PRINTF printf
#define FILEPT FILE*

#ifdef forLINUX
#include <sys/stat.h>
#include <time.h>
#include <fcntl.h>
#include <sys/wait.h>
#include <sys/time.h>
#include <sys/timeb.h>
#ifdef SOUND
#include <sys/ioctl.h>
#include <sys/unistd.h>
#include <sys/fcntl.h>
#include <sys/soundcard.h>
#endif
#define MALLOC(n) malloc((n)<<B2Wsh)
#define TICKS_PER_SEC (CLOCKS_PER_SEC)
#define REMOVE unlink
#define UNIXNAMES
#endif

#ifdef forARM
#include <sys/stat.h>
#include <time.h>
#include <fcntl.h>
#include <sys/wait.h>
#include <sys/time.h>
#include <sys/timeb.h>
#ifdef SOUND
#include <sys/ioctl.h>
#include <sys/unistd.h>
#include <sys/fcntl.h>
#include <sys/soundcard.h>
#endif
#define MALLOC(n) malloc((n)<<B2Wsh)
#define TICKS_PER_SEC (CLOCKS_PER_SEC)
#define REMOVE unlink
#define UNIXNAMES
#endif

#ifdef forVmsItanium
#define VMSNAMES
#include <stat.h>
#include <time.h>
#include <fcntl.h>
#include <wait.h>
#include <time.h>
#include <timeb.h>
#include <unistd.h>
#include <inet.h>
#define MALLOC(n) malloc((n)<<B2Wsh)
#define TICKS_PER_SEC (1000)
#define REMOVE unlink
#define VMSNAMES
#undef CINTASM
#define CINTASM interpret
typedef unsigned int socklen_t;
#endif

#ifdef forVmsVax
#define VMSNAMES
#include <stat.h>
#include <time.h>
#include <fcntl.h>
#include <wait.h>
#include <time.h>
#include <timeb.h>
#include <unistd.h>
#define MALLOC(n) malloc((n)<<B2Wsh)
#define TICKS_PER_SEC (1000)
#define REMOVE unlink
#define VMSNAMES
#endif

#ifdef forGP2X
#include <sys/stat.h>
#include <time.h>
#include <fcntl.h>
#include <sys/wait.h>
#include <sys/time.h>
#include <sys/timeb.h>
#define MALLOC(n) malloc((n)<<B2Wsh)
#define TICKS_PER_SEC (CLOCKS_PER_SEC)
#define REMOVE unlink
#define UNIXNAMES
#endif

#ifdef forLINUXAMD64
#include <sys/stat.h>
#include <time.h>
#include <sys/timeb.h>
#define MALLOC(n) malloc((n)<<B2Wsh)
#define TICKS_PER_SEC (CLOCKS_PER_SEC)
#define REMOVE unlink
#define UNIXNAMES
#endif

#ifdef forMacOSPPC
#include <sys/stat.h>
#include <time.h>
#include <sys/timeb.h>
#define MALLOC(n) malloc((n)<<B2Wsh)
#define TICKS_PER_SEC (CLOCKS_PER_SEC)
#define REMOVE unlink
#define UNIXNAMES
#define BIGENDER
#endif

#ifdef forMacOSX
#include <sys/stat.h>
#include <time.h>
#include <sys/timeb.h>
#define MALLOC(n) malloc((n)<<B2Wsh)
#define TICKS_PER_SEC (CLOCKS_PER_SEC)
#define REMOVE unlink
#define UNIXNAMES
#endif

#ifdef forCYGWIN32
#include <sys/stat.h>
#include <time.h>
#include <sys/timeb.h>
#define MALLOC(n) malloc((n)<<B2Wsh)
#define TICKS_PER_SEC (CLOCKS_PER_SEC)
#define REMOVE unlink
#define UNIXNAMES
#endif

#ifdef forLINUXPPC
#include <sys/stat.h>
#include <time.h>
#include <sys/timeb.h>
#define MALLOC(n) malloc((n)<<B2Wsh)
#define TICKS_PER_SEC (CLOCKS_PER_SEC)
#define REMOVE unlink
#define UNIXNAMES
#define BIGENDER
#endif

#ifdef forSUN4
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/timeb.h>
#define MALLOC(n) malloc((n)<<B2Wsh)
#define TICKS_PER_SEC (1000000)
#define REMOVE unlink
#define UNIXNAMES
#define BIGENDER
#endif

#ifdef forSPARC
#include <sys/stat.h>
#include <time.h>
#include <sys/timeb.h>
#define MALLOC(n) malloc((n)<<B2Wsh)
#define TICKS_PER_SEC (CLOCKS_PER_SEC)
#define REMOVE unlink
#define UNIXNAMES
#define BIGENDER
#endif

#ifdef forALPHA
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/timeb.h>
#include <stdlib.h>
#define MALLOC(n) malloc((n)<<B2Wsh)
#define TICKS_PER_SEC (CLOCKS_PER_SEC)
#define REMOVE unlink
#define UNIXNAMES
#endif

#ifdef forMSDOS
#include <sys\stat.h>
#include <time.h>
#include <sys/timeb.h>
#define MALLOC(n) malloc((n)<<B2Wsh)
#define TICKS_PER_SEC (CLK_TCK)
#define REMOVE unlink
#define WINNAMES
#endif

#ifdef forBC4
#include <sys\stat.h>
#include <time.h>
#include <sys/timeb.h>
#define MALLOC(n) malloc((n)<<B2Wsh)
#define TICKS_PER_SEC (CLK_TCK)
#define REMOVE unlink
#define WINNAMES
#endif

#ifdef forOS2
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/timeb.h>
#define MALLOC(n) malloc((n)<<B2Wsh)
#define TICKS_PER_SEC (CLOCKS_PER_SEC)
#define REMOVE remove
#define WINNAMES
#endif

#ifdef forWIN32
#include <sys/stat.h>
#include <time.h>
#include <sys/timeb.h>
#include <windows.h>
#include <mmsystem.h>
#define MALLOC(n) malloc((n)<<B2Wsh)
#define TICKS_PER_SEC (CLK_TCK)
#define REMOVE _unlink
#define tzset _tzset
#define WINNAMES
#endif

#ifdef forSHwinCE
#define forWinCE
#endif

#ifdef forWinCE
#undef BCPLWORD
#define BCPLWORD long
#define MALLOC(n) LocalAlloc(LPTR, (n)<<B2Wsh)
#define TICKS_PER_SEC 1000
#define REMOVE unlink
#define WINNAMES
/*#include <sys\stat.h> */
/*#include <time.h> */
#include <windows.h>         /* For all that Windows stuff */
#include <commctrl.h>        /* Command bar includes */
#include "../sysasm/shWinCE/ceBCPL.h" /* Program-specific stuff */
#include "Objidl.h"
#include <stdlib.h>

#define PRINTFS printfs
#define PRINTFD printfd
#define PRINTF(s) printfd(s, 0)
#define FILEPT HANDLE

/* Unix style library declarations */

#define FILEPT HANDLE

#define SEEK_SET FILE_BEGIN
#define SEEK_END FILE_END

int fclose(FILEPT fp);
int fgetc(FILEPT fp);
void putchar(char ch);
void fflush(FILEPT fp);
FILEPT fopen(char *, char *);
int fread(char *buf, size_t size, size_t len, FILEPT fp);
int fwrite(char *buf, size_t size, size_t len, FILEPT fp);
int fseek(FILEPT fp, long pos, int method);
int ftell(FILEPT fp);
int unlink(char *);
int rename(char *, char *);
int clock();
char *getenv(char *);
int main();

FILEPT stdout=0;

#define EOF -1

#else

#define PRINTFS printf
#define PRINTFD printf
#define PRINTF printf
#define FILEPT FILE*

#endif

void trpush(BCPLWORD val);

typedef BCPLWORD *BCPLWORDpt;

#define WD (BCPLWORD)
#define UWD (unsigned BCPLWORD)
#define PT (BCPLWORD *)
#define BP (unsigned char *)
#define SBP (SIGNEDCHAR *)
#define HP (unsigned short *)
#define SHP (short *)

#define Gn_sys         3
#define Gn_currco      7
#define Gn_colist      8
#define Gn_rootnode    9
#define Gn_result2    10

/* Functions defined in kblib.c  */
extern int Readch(void);
extern int init_keyb(void);
extern int close_keyb(void);
extern int intflag(void);

/* externals defined in init*.c  */
extern BCPLWORD stackupb;
extern BCPLWORD gvecupb;
extern void initsections(BCPLWORD *);

#define Rtn_tasktab       0L
#define Rtn_devtab        1L
#define Rtn_tcblist       2L
#define Rtn_crntask       3L
#define Rtn_blklist       4L
#define Rtn_tallyv        5L
#define Rtn_clkintson     6L
#define Rtn_lastch        7L
#define Rtn_insadebug     8L
#define Rtn_bptaddr       9L
#define Rtn_bptinstr     10L
#define Rtn_dbgvars      11L
#define Rtn_clwkq        12L
#define Rtn_membase      13L
#define Rtn_memsize      14L
#define Rtn_info         15L
#define Rtn_sys          16L
#define Rtn_boot         17L
#define Rtn_klib         18L
#define Rtn_blib         19L
#define Rtn_keyboard     20L
#define Rtn_screen       21L
#define Rtn_vecstatsv    22L
#define Rtn_vecstatsvupb 23L
#define Rtn_intflag      24L
#define Rtn_dumpflag     25L
#define Rtn_envlist      26L
#define Rtn_abortcode    27L
#define Rtn_context      28L
#define Rtn_lastp        29L
#define Rtn_lastg        30L
#define Rtn_lastst       31L
#define Rtn_idletcb      32L
#define Rtn_adjclock     33L
#define Rtn_dcountv      34L
#define Rtn_rootvar      35L
#define Rtn_pathvar      36L
#define Rtn_hdrsvar      37L
#define Rtn_scriptsvar   38L
#define Rtn_boottrace    39L
#define Rtn_days         40L
#define Rtn_msecs        41L
#define Rtn_ticks        42L
#define Rtn_mc0          43L
#define Rtn_mc1          44L
#define Rtn_mc2          45L
#define Rtn_mc3          46L

#define Rtn_upb          50L


#define Tcb_namebase     19L /* Space for upto 15 chars of task name */


/* SYS functions */

#define Sys_setcount      (-1)
#define Sys_quit            0
#define Sys_rti             1
#define Sys_saveregs        2
#define Sys_setst           3
#define Sys_tracing         4
#define Sys_watch           5
#define Sys_tally           6
#define Sys_interpret       7

#define Sys_sardch         10
#define Sys_sawrch         11
#define Sys_read           12
#define Sys_write          13
#define Sys_openread       14
#define Sys_openwrite      15
#define Sys_close          16
#define Sys_deletefile     17
#define Sys_renamefile     18
#define Sys_openappend     19

#define Sys_getvec         21
#define Sys_freevec        22
#define Sys_loadseg        23
#define Sys_globin         24
#define Sys_unloadseg      25
#define Sys_muldiv         26
#define Sys_intflag        28
#define Sys_setraster      29
#define Sys_cputime        30
#define Sys_filemodtime    31
#define Sys_setprefix      32
#define Sys_getprefix      33
#define Sys_graphics       34       /* Windows CE only */

#define Sys_seek           38
#define Sys_tell           39
#define Sys_waitirq        40
#define Sys_lockirq        41
#define Sys_unlockirq      42
#define Sys_devcom         43
#define Sys_datstamp       44

#define Sys_filesize       46
#define Sys_openreadwrite  47
#define Sys_getsysval      48
#define Sys_putsysval      49
#define Sys_shellcom       50
#define Sys_getpid         51
#define Sys_dumpmem        52
#define Sys_callnative     53
#define Sys_platform       54
#define Sys_inc            55
#define Sys_buttons        56
#define Sys_delay          57
#define Sys_sound          58
#define Sys_callc          59
#define Sys_trpush         60
#define Sys_settrcount     61
#define Sys_gettrval       62
#define Sys_flt            63
#define Sys_pollsardch     64
#define Sys_incdcount      65
#define Sys_sdl            66

#define fl_avail  0
#define fl_mk     1
#define fl_unmk   2
#define fl_float  3
#define fl_fix    4
#define fl_abs    5
#define fl_mul    6
#define fl_div    7
#define fl_add    8
#define fl_sub    9
#define fl_pos   10 
#define fl_neg   11
#define fl_eq    12
#define fl_ne    13
#define fl_ls    14
#define fl_gr    15
#define fl_le    16
#define fl_ge    17

#define fl_acos  20
#define fl_asin  21
#define fl_atan  22
#define fl_atan2 23
#define fl_cos   24
#define fl_sin   25
#define fl_tan   26
#define fl_cosh  27
#define fl_sinh  28
#define fl_tanh  29
#define fl_exp   30
#define fl_frexp 31
#define fl_ldexp 32
#define fl_log   33
#define fl_log10 34
#define fl_modf  35
#define fl_pow   36
#define fl_sqrt  37
#define fl_ceil  38
#define fl_floor 39
#define fl_fmod  40

#define fl_N2F   41
#define fl_F2N   42
#define fl_radius2   43
#define fl_radius3   44

