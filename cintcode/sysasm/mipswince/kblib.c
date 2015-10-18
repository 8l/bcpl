/* this module defines the machine dependent keyboard interface

   int Readch(void)     returns the ASCII code for the next key pressed
                        without echo.
   int init_keyb(void)  initialises the keyboard interface.
   int close_keyb(void) restores the keyboard to its original state.
   int intflag(void)    returns 1 if interrupt key combination pressed.
*/

//#include <stdio.h>
//#include <stdlib.h>

/* cinterp.h contains machine/system dependent #defines  */
#include "cinterp.h"


extern int getch(void);

int Readch()
{ return chBufGet();
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

// Unix style library

FILEPT fopen(char *name, char *str) {
	FILEPT fp=NULL;
	TCHAR szName[100];
	int i;
	for (i=0; *name; i++) szName[i] = *name++;
	szName[i] = 0;

	if (str[0]=='r')
		fp = CreateFile(szName,
	                  GENERIC_READ,
					  FILE_SHARE_READ,
	                  NULL, // Security
					  OPEN_EXISTING,
					  FILE_ATTRIBUTE_NORMAL,
					  0);
	if (str[0]=='w')
		fp = CreateFile(szName,
	                  GENERIC_WRITE,
					  FILE_SHARE_WRITE,
	                  NULL, // Security
					  CREATE_ALWAYS,
					  FILE_ATTRIBUTE_NORMAL,
					  0);
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

int fread(char *buf, int size, int len, FILEPT fp) {
	DWORD n=0;
	ReadFile(fp, buf, size*len, &n, NULL);
	return n;
}

int fwrite(char *buf, int size, int len, FILEPT fp) {
	DWORD n=0;
	WriteFile(fp, buf, size*len, &n, NULL);
	return n;
}

int unlink(char *name) {
	// Delete (remove) a named file.
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

char *getenv(char *name) {
	return "\\BCPL\\cintcode";
}

