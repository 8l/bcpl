# This makefile will compile, link and download the BCPL Cintcode
# system into a Casio Casiopeia E105 Palm-sized PC, running Windows CE.
# (c) Martin Richards -- Oct 2001

# Just type nmake after making minor edits to this file
# and installing Visual C 5.0 and the Windows CE development system

LIBPATH="E:\Program Files\DevStudio\WCE\LIB\WCE200\WCEMIPS"

CESubsystem=windowsce,2.0
CEVersion=200
CEConfigName=H/PC Ver. 2.00


!IF "$(OS)" == "Windows_NT"
NULL=
!ELSE 
NULL=nul
!ENDIF 


ALL :	ceBCPL.exe download

CLEAN :
	-@erase "ceBCPL.obj"
	-@erase "ceBCPL.res"
	-@erase "ceBCPL.pch"
	-@erase "cinterp.obj"
	-@erase "cintasm.obj"
	-@erase "cintmain.obj"
	-@erase "graphics.obj"
	-@erase "kblib.obj"
	-@erase "nrastlib.obj"
	-@erase "save.obj"

	-@erase "SCREEN.OBJ"
	-@erase "ceBCPL.trg"

CPP=clmips.exe
CPP_PROJ=/nologo /ML /W3 /O2 /D _WIN32_WCE=$(CEVersion) /D "$(CEConfigName)" /D\
 "NDEBUG" /D "MIPSx" /D "MIPS" /D "_MIPS_" /D UNDER_CE=$(CEVersion) /D "UNICODE"\
 /Fp"ceBCPL.pch" /YX /Fo".\\" /c 


RSC=rc.exe
RSC_PROJ=/l 0x409 /r /fo"ceBCPL.res" /d "MIPSx" /d "MIPS" /d "_MIPS_" /d\
 UNDER_CE=$(CEVersion) /d _WIN32_WCE=$(CEVersion) /d "$(CEConfigName)" /d\
 "UNICODE" /d "NDEBUG" 

# MTL=midl.exe
# MTL_PROJ=/nologo /D "NDEBUG" /mktyplib203 /o NUL /win32 
# BSC32=bscmake.exe
# BSC32_FLAGS=/nologo /o"ceBCPL.bsc" 
# BSC32_SBRS= \
	

LINK32=link.exe
LINK32_FLAGS=/libpath:$(LIBPATH)\
 commctrl.lib coredll.lib /nologo /entry:"WinMainCRTStartup"\
 /base:"0x00010000" /incremental:no /pdb:"ceBCPL.pdb" /machine:MIPS\
 /out:"ceBCPL.exe" /subsystem:$(CESubsystem) 
LINK32_OBJS= \
	"ceBCPL.obj" \
	"ceBCPL.res" \
	"cinterp.obj" \
	"cintmain.obj" \
	"graphics.obj" \
	"kblib.obj" \
	"nrastlib.obj" \
	"save.obj" \
	"screen.obj" \
#	"cintasm.obj"

ceBCPL.exe :  $(DEF_FILE) $(LINK32_OBJS)
    $(LINK32) $(LINK32_FLAGS) $(LINK32_OBJS)

PFILE=pfile.exe

download :  ceBCPL.exe
	$(PFILE) COPY ceBCPL.exe WCE:ceBCPL.exe

ceBCPL.obj : ceBCPL.c ceBCPL.h
	$(CPP) $(CPP_PROJ) ceBCPL.c

ceBCPL.res : ceBCPL.rc ceBCPL.h ceBCPL.ico commbtns.bmp
	$(RSC) $(RSC_PROJ) ceBCPL.rc

InputPath=cintasm.src

cintasm.obj	 : cintasm.c
	$(CPP) $(CPP_PROJ) cintasm.c

cinterp.obj : cinterp.c cinterp.h ceBCPL.h
	$(CPP) $(CPP_PROJ) cinterp.c

cintmain.obj : cintmain.c ceBCPL.h cinterp.h
	$(CPP) $(CPP_PROJ) cintmain.c

graphics.obj : graphics.c ceBCPL.h
	$(CPP) $(CPP_PROJ) graphics.c

kblib.obj : kblib.c ceBCPL.h cinterp.h
	$(CPP) $(CPP_PROJ) kblib.c

nrastlib.obj : nrastlib.c ceBCPL.h cinterp.h
	$(CPP) $(CPP_PROJ) nrastlib.c

save.obj : save.c ceBCPL.h
	$(CPP) $(CPP_PROJ) save.c

screen.obj : screen.c ceBCPL.h
	$(CPP) $(CPP_PROJ) screen.c



