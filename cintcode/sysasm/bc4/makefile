BC4=E:\BC4
BC4LIB=$(BC4)\LIB
CC=Bcc32 -DforBC4 -I$(BC4)\INCLUDE 

run:	cinterp.exe
	cinterp
	
cinterp : cinterp.exe

cinterp.exe : cintasm.obj cintmain.obj kblib.obj nrastlib.obj cinterp.obj
  TLink32 @&&|
 /v -L$(BC4LIB) -Tpe -ax -x +
c0x32.obj+cintasm.obj+cintmain.obj+kblib.obj+nrastlib.obj+cinterp.obj
$<,$*
bwcc32.lib+import32.lib+cw32.lib
|

cintasm.obj :  sys\BC4\cintasm.asm
  Tasm32 /ml sys\BC4\cintasm.asm , cintasm.obj

cintmain.obj :  sys\cintmain.c sys\BC4\cinterp.cfg
  $(CC) +sys\BC4\cinterp.cfg -o$@ sys\cintmain.c

kblib.obj :  sys\kblib.c sys\BC4\cinterp.cfg
  $(CC) +sys\BC4\cinterp.cfg -o$@ sys\kblib.c

nrastlib.obj :  sys\nrastlib.c sys\BC4\cinterp.cfg
  $(CC) +sys\BC4\cinterp.cfg -o$@ sys\nrastlib.c

cinterp.obj :  sys\cinterp.c sys\BC4\cinterp.cfg
  $(CC) +sys\BC4\cinterp.cfg -o$@ sys\cinterp.c


clean:
	del cintmain.obj
	del cinterp.obj
	del cintasm.obj
	del kblib.obj
	del nrastlib.obj

