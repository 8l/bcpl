
run:	cinterp.exe
	cinterp
	
cinterp : cinterp.exe

cinterp.exe : cintasm.obj cintmain.obj kblib.obj cinterp.obj
  TLink32 @&&|
 /v -LD:\BC4\LIB -Tpe -ax -LD:\BC4\LIB -x +
D:\BC4\LIB\c0x32.obj+cintasm.obj+cintmain.obj+kblib.obj+cinterp.obj
$<,$*
D:\BC4\LIB\dpmi32.lib+D:\BC4\LIB\bidsf.lib+D:\BC4\LIB\tv32.lib+
D:\BC4\LIB\cw32.lib
|

cintasm.obj :  sys\cintasm.asm
  Tasm32 /ml D:\DISTRIB\BC4CINT\sys\cintasm.asm , cintasm.obj

cintmain.obj :  sys\cintmain.c cinterp.cfg
  Bcc32 +cinterp.cfg -o$@ sys\cintmain.c

kblib.obj :  sys\kblib.c cinterp.cfg
  Bcc32 +cinterp.cfg -o$@ sys\kblib.c

cinterp.obj :  sys\cinterp.c cinterp.cfg
  Bcc32 +cinterp.cfg -o$@ sys\cinterp.c


clean:
	del cintmain.obj
	del cinterp.obj
	del cintasm.obj
	del kblib.obj

