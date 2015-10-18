/* this module defines the machine dependent keyboard interface

   int Readch(void)     returns the ASCII code for the next key pressed
                        without echo.
   int pollReadch(void) returns the next character or -3 if none available.
   int init_keyb(void)  initialises the keyboard interface.
   int close_keyb(void) restores the keyboard to its original state.
   int intflag(void)    returns 1 if interrupt key combination pressed.

Following Colin Liebenrood's suggestion (for LINUX),

   init_keyb return 1 is stdin is a tty, 0 otherwise
and
   Readch() return endstreamch if the stdin is exhausted or ^D read.
*/

#include <stdio.h>
#include <stdlib.h>

/* bcpl.h contains machine/system dependent #defines  */
#include "bcpl.h"

#if defined(forMIPS) || defined(forSUN4) || defined(forALPHA) || \
    defined(forLINUXPPC) || defined(forMacOSPPC) || defined(forMacOSX)
#include <sys/ioctl.h>
#include <sgtty.h>

int init_keyb(void)
{ struct sgttyb ttyb;

  ioctl(0, TIOCGETP, &ttyb);
  ttyb.sg_flags = CBREAK+EVENP+ODDP+CRMOD;
  ioctl(0, TIOCSETP, &ttyb);
  return 0;
}

int close_keyb(void)
{ struct sgttyb ttyb;
  ioctl(0, TIOCGETP, &ttyb);
  ttyb.sg_flags = ECHO+EVENP+ODDP+CRMOD;
  ioctl(0, TIOCSETP, &ttyb);
  return 0;
}

int Readch(void)
{ return getchar();
}

int pollReadch(void)
{ return Readch();
}

int intflag(void)
{ return 0;
}
#endif

#if defined(forVmsItanium1)
// This is for an Itanium running VMS
typedef unsigned long uLong;
typedef unsigned long long uQuad;
typedef unsigned short uWord;
typedef unsigned char uByte;

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include dcdef
#include iodef
#include ssdef
#include tt2def

static uByte originalmodes[12];		/* original terminal modes */
static uWord ttchan = 0;		/* 0: channel has not been assigned yet */
					/* else: i/o channel to the terminal */
static char keybuf[256];                /* Bytes received from TT */
static int keyp=0;                      /* position of next byte in keybuf */
static int keylen=0;                    /* Number of bytes in keylen */

uLong sys$assign ();
uLong sys$dassgn ();
uLong sys$exit ();
uLong sys$gettim ();
uLong sys$qio ();
uLong sys$qiow ();
uLong sys$setast ();
uLong sys$setimr ();
uLong sys$synch ();

int init_keyb(void)
{ char *p, *ttname;
  struct { uLong size;
           char *buff;
         } ttdesc;
  uLong sts;

  struct { uWord sts, len;
           char trm[4];
         } iosb;

  /* Assign I/O channel to terminal */

  ttname = "TT";
  ttdesc.size = strlen (ttname);
  ttdesc.buff = ttname;
  sts = sys$assign (&ttdesc, &ttchan, 0, 0);
  if (!(sts & 1)) {
    fprintf (stderr, "error 0x%x assigning channel to terminal %s\n", sts, ttname);
    return sts;
  }

  /* Sense mode - get original modes and make sure it is a terminal */

  sts = sys$qiow (1, ttchan, IO$_SENSEMODE, &iosb, 0, 0,
                  originalmodes, sizeof originalmodes,
                  0, 0, 0, 0);
  if (sts & 1) sts = iosb.sts;
  if (!(sts & 1)) {
    fprintf (stderr, "error 0x%x sensing terminal %s modes\n", sts, ttname);
    sys$exit (sts);
  }
  if (originalmodes[0] != DC$_TERM) {
    fprintf (stderr, "device %s is not a terminal\n", ttname);
    return SS$_IVDEVNAM;
  }
  return 0;
}

int close_keyb(void)
{ sys$dassgn(ttchan);
  return 0;
}

int readkeyseq(char *keystr, int flag) {
  // If flag!=0 read at least one key press into keystr
  // otherwise read as many as are currently available.
  // Return the number of bytes read.
  int  len = 0;
  int i;
  char buf[256];
  struct { uWord sts, len;
           char termchr;
           char fill1;
           char termlen;
           char fill2;
         } iosb;
  uLong sts;

  if(flag) {
    /* Read without echoing, wait for one character */

    sts = sys$qiow (1, ttchan, IO$_READVBLK | IO$M_NOECHO,
                    &iosb, 0, 0, buf, 1,
                    0, 0, 0, 0);

    /* Check termination status, treat any error like an eof */

    if (sts & 1) sts = iosb.sts;
    if (!(sts & 1)) return -1;                // EOF

    /* Concat any fetched data to string */

    for (i=0; i<iosb.len; i++) keystr[len++] = buf[i];
    for (i=0; i<iosb.termlen; i++) keystr[len++] = (&iosb.termchr)[i];
  }

  /* Read again, but just get whatever happens to be in read-ahead, don't wait */

  sts = sys$qiow (1, ttchan, IO$_READVBLK | IO$M_NOECHO | IO$M_TIMED,
                  &iosb, 0, 0,
                  buf, sizeof buf,
                  0, 0, 0, 0);

  /* Check termination status, treat any error like an eof */

  if (sts & 1) sts = iosb.sts;
  if (sts == SS$_TIMEOUT) sts |= 1;
  if (!(sts & 1)) return  -1;                  // EOF

  /* Concat any fetched data to string */

  for (i=0; i<iosb.len; i++) keystr[len++] = buf[i];
  for (i=0; i<iosb.termlen; i++) keystr[len++] = (&iosb.termchr)[i];
  keystr[len] = 0;

  if(len==0) len = -3; // pollingch
  return len;
}

int Readch(void)
{ if (keyp>=keylen) {
    keylen = readkeyseq(keybuf, 1);
    keyp = 0;
  }
  return keybuf[keyp++];
}

int pollReadch(void)
{ if (keyp>=keylen) {
    keylen = readkeyseq(keybuf, 0); // Read what is available
    keyp = 0;
  }
  if(keylen==-3 || keylen==-1) return keylen; // pollingch or endstreamch
  return keybuf[keyp++];
}

int intflag(void)
{ return 0;
}
#endif

#if defined(forLINUX)||defined(forCYGWIN32)||defined(forSPARC)||\
    defined(forGP2X)||defined(forLINUXAMD64)||defined(forARM)
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <termios.h>
#include <errno.h>

/* Use this variable to remember original terminal attributes.  */
     
struct termios saved_attributes;
     
void
reset_input_mode (void)
{
  tcsetattr (STDIN_FILENO, TCSANOW, &saved_attributes);
}
     
void
set_input_mode (void)
{
  struct termios tattr;

  if (!isatty(STDIN_FILENO)) return;  
   
  /* Save the terminal attributes so we can restore them later.  */
  tcgetattr (STDIN_FILENO, &saved_attributes);
  atexit (reset_input_mode);

  /* Set the funny terminal modes.  */
  tcgetattr (STDIN_FILENO, &tattr);
  tattr.c_lflag &= ~(ICANON|ECHO); /* Clear ICANON and ECHO.   */
  tattr.c_cc[VMIN] = 1;
  tattr.c_cc[VTIME] = 0;
  tcsetattr (STDIN_FILENO, TCSAFLUSH, &tattr);
}
     
int Readch()
{ char ch;
  int rc = read(STDIN_FILENO, &ch, 1);
  if(rc==0) ch = -1;
  //if(rc==0) 
  //printf("rc=%d ch=%3d errno=%d\n", rc, ch, errno);
  return ch;
}

int pollReadch(void)
{ struct timeval tv;
  fd_set read_fd;
  int rc=0;
  tv.tv_sec  = 0;
  tv.tv_usec = 0;
  FD_ZERO(&read_fd);
  FD_SET(0, &read_fd);
  rc=select(1, &read_fd, 0, 0, &tv);
  if(rc==0) return -3; // pollingch
  if(rc>0 && FD_ISSET(0, &read_fd)) return Readch();
  return -1; // Error or EOF
}

int init_keyb(void)
{ set_input_mode();
  return 0;
}

int close_keyb(void)
{ return 0;
}

int intflag(void)
{ return 0;
}
#endif

#ifdef forMAC
#include <console.h>

int Readch(void)
{ int ch = EOF;
  while (ch==EOF) ch = getchar(); /* horrible!!!! */
  return ch;
}

int pollReadch(void)
{ return Readch();
}

int init_keyb(void)
{ console_options.title = "\pBCPL Cintcode";
  console_options.pause_atexit = 0;
  cshow(stdin);
  csetmode(C_RAW, stdin);
  return 0;
}

int close_keyb()
{ return 0;
}

int intflag(void)
{ long theKeys[4];
  GetKeys(theKeys);
  return theKeys[1]==0x8005;  /* Command-Option-Shift depressed  */
}
#endif

#if defined(forMSDOS) || defined(forBC4) || defined(forVmsItanium)
#include <signal.h>

extern int getch(void);

int Readch()
//{ int ch=getch();
{ int ch=getchar();  // Itanium version
  if(ch==3) { /* ctrl-C */
    raise(SIGINT);
  }
  return ch;
}

int pollReadch(void)
{ return Readch();
}

int init_keyb(void)
{ return 0;
}

int close_keyb(void)
{ return 0;
}

int intflag(void)
{ return 0;
}
#endif

#ifdef forWIN32
#include <conio.h>
#include <signal.h>

extern int getch(void);

int Readch()
{ int ch=_getch();
  if(ch==3) { /* ctrl-C */
    raise(SIGINT);
  }
  return ch;
}

int pollReadch(void)
{ if (_kbhit()) return _getch();
  return -3; /* pollingch */
}

int init_keyb(void)
{ return 0;
}

int close_keyb(void)
{ return 0;
}

int intflag(void)
{ return 0;
}
#endif

#ifdef forOS2
#include <conio.h>

int Readch(void)
{ int ch = getch();
  return ch;
}

int pollReadch(void)
{ return Readch();
}

int init_keyb(void)
{ return 0;
}

int close_keyb(void)
{ return 0;
}

int intflag(void)
{ return 0;
}
#endif

#ifdef forSHwinCE

extern int getch(void);

int Readch()
{ return chBufGet();
}

int pollReadch(void)
{ return Readch();
}

int init_keyb(void)
{ return 0;
}

int close_keyb(void)
{ return 0;
}

int intflag(void)
{ INT32 flag = Interrupted;
  Interrupted = 0;
  return flag;
}

/* Unix style library */

FILEPT fopen(char *name, char *str) {
	FILEPT fp=NULL;
	TCHAR szName[100];
	DWORD access = 0;
	DWORD mode = 0;
        DWORD share = 0;
        DWORD creation = 0;
        DWORD attrs = 0;
	int i;
	for (i=0; *name; i++) szName[i] = *name++;
	szName[i] = 0;

	while(*str) {
	  if (str[0]=='r') {
            access =   GENERIC_READ;
            share =    FILE_SHARE_READ;
            creation = OPEN_EXISTING; /* fail if doesn't exist */
            attrs =    FILE_ATTRIBUTE_NORMAL;
          }
          if(*str=='w') {
            access =   GENERIC_WRITE;
            share =    FILE_SHARE_WRITE;
            creation = CREATE_ALWAYS; /* create or truncate */
            attrs =    FILE_ATTRIBUTE_NORMAL;
	  }
          if(*str=='+') {
            access =   GENERIC_READ | GENERIC_WRITE;
            share =    FILE_SHARE_READ | FILE_SHARE_WRITE;
            creation = OPEN_ALWAYS; /* Open or create, no truncation */
            attrs =    FILE_FLAG_RANDOM_ACCESS;
	  }
          str++;
	}
        fp = CreateFile(szName, access, share, NULL, creation, attrs, 0);
	if (fp==INVALID_HANDLE_VALUE) fp = 0;
	return fp;
}

int fclose(FILEPT fp) {
	return CloseHandle(fp) ? 0 : 1;
}

int clock() {
	return GetTickCount();
}

void putchar(char ch) {
	Wrch(ch);
}

void fflush(FILEPT fp) {
	return;
}

int fread(char *buf, size_t size, size_t len, FILEPT fp) {
	DWORD n=0;
	BOOL rc = ReadFile(fp, buf, (DWORD)size*len, &n, NULL);
	if(!rc) {
          DWORD err = GetLastError();
	  /*
          PRINTFD("fread: ReadFile, err=%" FormD "\n", (DWORD)err);
	  */
          return -1;
	}
	/*
	PRINTFD("fread trying to read from fd=%" FormD "\n", (DWORD)fp);
	PRINTFD("fread trying to read %" FormD " bytes, ", (DWORD)(size*len));
	PRINTFD("got %" FormD "\n", n);
	*/
	return n;
}

int fwrite(char *buf, size_t size, size_t len, FILEPT fp) {
	DWORD n=0;
	if(WriteFile(fp, buf, (DWORD)size*len, &n, NULL))
	  return n; /* Success */
	return -1;
}

int fseek(FILEPT fp, INT32 pos, int method) { /* Set the file position */
  SetFilePointer(fp, (LONG)pos, NULL, method);
  return 0;
}

int ftell(FILEPT fp) { /* Return the current file position */
  return SetFilePointer(fp, 0, NULL, FILE_CURRENT);
}


int unlink(char *name) {
        /* Delete (remove) a named file. */
	TCHAR szName[100];
	int i;
	for (i=0; *name; i++) szName[i] = *name++;
	szName[i] = 0;
	return ! DeleteFile(szName);
}

int rename(char *from, char *to) {
	TCHAR szFrom[100];
	TCHAR szTo[100];
	int i;
	for (i=0; *from; i++) szFrom[i] = *from++;
	szFrom[i] = 0;
	for (i=0; *to; i++) szTo[i] = *to++;
	szTo[i] = 0;
	return ! MoveFile(szFrom, szTo);
}

int fgetc(FILEPT fp) {
	BYTE ch;
	DWORD n=0;
	ReadFile(fp, &ch, 1, &n, NULL);

	return n==0 ? EOF : ch;
}

int eqstr(char *s1, char *s2) {
  while(*s1 && *s2) if(*s1++ != *s2++) return 0;
  return *s1==*s2;
}

char *getenv(char *name) {
 if(eqstr(name, "BCPLPATH")) return "\\BCPL\\cintcode\\cin";
 if(eqstr(name, "BCPLROOT")) return "\\BCPL\\cintcode";
 if(eqstr(name, "BCPLHDRS")) return "\\BCPL\\cintcode\\g";
 return "";
}
#endif

