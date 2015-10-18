/* this module defines the machine dependent keyboard interface

   int Readch(void)     returns the ASCII code for the next key pressed
                        without echo.
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

#if defined(forMIPS) || defined(forSUN4) || defined(forALPHA)
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

int intflag(void)
{ return 0;
}
#endif

#if defined(forLINUX) || defined(forSPARC)
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <termios.h>

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
  if ( read(STDIN_FILENO, &ch, 1) )
    return ch==0x04 ? -1 : ch;
 
  return -1; // endstreamch
}

int init_keyb(void)
{ 
  if ( isatty(STDIN_FILENO) ) {
    set_input_mode();
    return 1;
  }
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

#ifdef forMSDOS
extern int getch(void);

int Readch()
{ return getch();
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


