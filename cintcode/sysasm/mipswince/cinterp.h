/* This header file contains machine/system dependent #defines
** These are dependent on the -D parameter specified in Makefile.
** The possible -D parameters are:
**
**  -DforMAC           for Apple MAC (not recently tested)
**  -DforMIPS          for DEC R2000/3000 Workstations under Ultrix 4.3
**  -DforMIPSwinCE     for WinCE 2.0 (MIPS processor)
**  -DforLINUX         for Linux
**  -DforSUN4          for Sun4m under SunOS 4.1.3
**  -DforSPARC         for Sun4m spac under SunOS 5.4
**  -DforALPHA         for DEC Alpha under OSF1 V3.2 17
**  -DforMSDOS         for MSDOS 32 bit protected mode usinf Borland C v4.0
**  -DforOS2           for OS/2 V2.1 using Cset/2 and Borland Tasm
**  -DforSHwinCE       for WinCE 2.0 (SH3 processor)
*/

#define forMIPSwinCE

/* The MAC version just about works on a Power Macintosh 7100/66
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

#include <windows.h>                 // For all that Windows stuff
#include <commctrl.h>                // Command bar includes
#include "ceBCPL.h"          // Program-specific stuff

#define SIGNEDCHAR signed char
/* #define SIGNEDCHAR char */



//#include <sys\stat.h>
//#include <time.h>
#define INT32 long
#define MALLOC(n) LocalAlloc(LPTR, (n)<<2)
#define TICKS_PER_SEC 1000
#define CINTASM interpret
#define REMOVE unlink
#define FILE_SEP_CH '\\'

// Unix style library declarations

#define FILEPT HANDLE

int fclose(FILEPT );
int fgetc(FILEPT );
void putchar(char ch);
void fflush(FILEPT );
FILEPT fopen(char *, char *);
int fread(char *buf, int size, int len, FILEPT fp);
int fwrite(char *buf, int size, int len, FILEPT fp);
int unlink(char *);
int rename(char *, char *);
int clock();

char *getenv(char *);
int main();

#define EOF -1

typedef INT32 *INT32pt;

#define WD (INT32)
#define UWD (unsigned INT32)
#define PT (INT32 *)
#define BP (unsigned char *)
#define SBP (SIGNEDCHAR *)
#define HP (unsigned short *)
#define SHP (short *)

