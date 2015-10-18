# This is the Makefile for the native code version of BCPL

# Implemented by Martin Richards (c) June 2013

# Last updated 5 Jan 2014

# It uses the BCPL to SIAL compiler bcpl2sial and various
# SIAL to native code codegenerators, such as:

# sial-386 sial-alpha sial-vax sial-arm

# sial-arm is currently under development and will be tested
# on the Raspberry-Pi machine.

# Location of the SD card unde Cygwin
#SD = /cygdrive/g

# Location of the SD card unde Linux
SD = /media/535A-B0C2

# "../" below is included to simplify compilation for a
# different architectures sharing the same filing system.

CINTCODE = ../cintcode
BCPLPROGS = ../bcplprogs
DEMOS = $(BCPLPROGS)/demos
EDSAC = $(BCPLPROGS)/edsac
SORT = $(BCPLPROGS)/sort
TESTS = $(BCPLPROGS)/tests
COM = $(CINTCODE)/com
RASPI = $(BCPLPROGS)/raspi

LIBS =  obj/mlib.o obj/clib.o obj/blib.o obj/dlib.o obj/kblib.o obj/sdlfn.o

# The following line is for cross compilation to the GP2X
# for use when running under Cygwin. The location of the
# ARM development kit may need changing for your machine.
# Floating point is not available on the GP2X

# The following for armgcc under cygwin
#GP2XCC = /cygdrive/c/devkitGP2X/bin/arm-linux-gcc -O9 -static -DforGP2X -DNOFLOAT

# The following for arm-linux-gcc for GP2X under Linux
GP2XCC = /home/mr10/devkitPro/devkitGP2X/bin/arm-linux-gcc -O9 -static -DforGP2X -DNOFLOAT

# The following for arm gnueabi-gcc under Linux
#GP2XCC = arm-none-linux-gnueabi-gcc -O9 -static -DforLINUX -DNOFLOAT

# Location of the SD card under Cygwin
#SD = /cygdrive/g

# Location of the SD card under Linux on Solestreet
SD = /media/535A-B0C2


# Select the appropriate definition of CC, LIBS and SYSM
# SYSM gives the location of machine specific code (eg cintasm.s)

#CC = gcc -O9 -DforMAC
#NB = nbmac

#CC = gcc -O9 -DforMIPS
#NB = nbmips

# For ARM Linux without the SDL feature
#CC = gcc -O2 -DforARM
#MLIB = arm/mlib.s
#SYSM = ../cintcode/sysasm/arm
#NB = nbarm

# For ARM Linux with the SDL feature
#CC = gcc -O4 -DforARM -DSDLavail `sdl-config --cflags`
#SDLLIBS =  `sdl-config --libs`
#MLIB = arm/mlib.s
#SYSM = ../cintcode/sysasm/arm
#NB = nbarm

# For Linux without SDL
CC = gcc -O9 -DforLINUX
MLIB = i386/mlib.s
#NB = nb386
NB = nb686

# For Linux with SDL
#SDLLIBS =  `sdl-config --libs`
#CC = gcc -O4 -DforLINUX -DSDLavail `sdl-config --cflags`
#MLIB = i386/mlib.s
#NB = nb386

# For Linux with GL
#SDLLIBS =  `sdl-config --libs`
#CC = gcc -O4 -DforLINUX -DSDLavail -DGLavail `sdl-config --cflags`
#MLIB = i386/mlib.s
#NB = nb386

#CC = gcc -O9 -DforARM
#MLIB = arm/mlib.s
#NB = nbarm

#CC = $(GP2XCC)
#MLIB = arm/mlib.s
#NB = nbarm

#CC = gcc -O9 -DforVAX
#NB = nbvax

#CC = gcc -O9 -DforSUN4
#NB = nbsun4

#CC = gcc -O9 -DforSPARC
#NB = nbsparc

#CC = gcc -O9 -DforALPHA
#NB = nbalpha

#CC = gcc -O9 -DforMSDOS
#NB = nbmsdos

#CC = gcc -O9 -DforOS2
#NB = nbos2

#run:	prog bench100 cmpltest crdemo edsac natbcpl b2sial
run:	fcmpltest
	./fcmpltest
#	./tst
#	cintsys -c "sial-sasm sial/fcmpltest.sial"
#	./tstfloat
#	./cmpltest
#	./crdemo
#	./b2sial $(DEMOS)/queens.b to queens.sial
#	time natbcpl $(CINTCODE)/com/bcpl.b to junk
#	time ./bench100
#	./prog y yyyyy x xxxxx
#	@echo
#	@echo "To run an Edsac program type: rcq"
#	@echo
#	./edsac

# INT.h

sysc/INT.h:	sysc/mkint-h.c
	gcc -o mkint-h sysc/mkint-h.c
	./mkint-h >sysc/INT.h
	rm -f mkint-h

tempc/INT.h:	sysc/INT.h
	cp sysc/INT.h tempc

tempc/bcpl.h:	sysc/bcpl.h
	cp sysc/bcpl.h tempc

# bench100

bench100.gpu: obj/bench100.o
	$(CC) -O2 -Wall -Werror \
	obj/bench100.o \
	-o bench100.gpu \
	-L$(DEVKITGP2X)/lib -Wl,-rpath,$(DEVKITGP2X)/lib \
	-static -lpthread -lSDL -lutil

bench100:	obj/initbench100.o obj/bench100.o $(LIBS)
	echo "linking bench100"
	$(CC) -o bench100 obj/initbench100.o obj/bench100.o $(LIBS) -lm 

obj/bench100.o:	temps/bench100.s
	$(CC) -o obj/bench100.o -c temps/bench100.s

temps/bench100.s:	$(TESTS)/bench100.b tempc/INT.h tempc/bcpl.h Makefile
	cintsys -c "c $(NB) $(TESTS) bench100"
	echo bench100.b compiled to temps/bench100.s

obj/initbench100.o:	tempc/initbench100.c tempc/bcpl.h tempc/INT.h
	$(CC) -o obj/initbench100.o -c tempc/initbench100.c

tempc/initbench100.c:	$(TESTS)/bench100.b
	cintsys -c "makeinit $(TESTS)/bench100.b to tempc/initbench100.c"

# prog

prog:	obj/initprog.o obj/prog.o $(LIBS) sysc/INT.h
	$(CC) -o prog obj/initprog.o obj/prog.o $(LIBS) -lm

obj/prog.o:	temps/prog.s
	$(CC) -o obj/prog.o -c temps/prog.s

temps/prog.s:	prog.b Makefile
	cintsys -c "c $(NB) . prog"
	echo prog.b compiled to temps/prog.s

obj/initprog.o:	tempc/initprog.c tempc/INT.h tempc/bcpl.h
	$(CC) -o obj/initprog.o -c tempc/initprog.c

tempc/initprog.c:	prog.b
	cintsys -c "makeinit prog.b to tempc/initprog.c"

# tstfloat

tstfloat:	obj/inittstfloat.o obj/tstfloat.o $(LIBS) sysc/INT.h
	$(CC) -o tstfloat obj/inittstfloat.o obj/tstfloat.o $(LIBS) -lm

obj/tstfloat.o:	temps/tstfloat.s
	$(CC) -o obj/tstfloat.o -c temps/tstfloat.s

temps/tstfloat.s:	$(COM)/tstfloat.b Makefile
	cintsys -c "c $(NB) $(COM) tstfloat"
	echo $(COM)/tstfloat.b compiled to temps/tstfloat.s

obj/inittstfloat.o:	tempc/inittstfloat.c tempc/INT.h tempc/bcpl.h
	$(CC) -o obj/inittstfloat.o -c tempc/inittstfloat.c

tempc/inittstfloat.c:	$(COM)/tstfloat.b
	cintsys -c "makeinit $(COM)/tstfloat.b to tempc/inittstfloat.c"

# tst

tst:	obj/inittst.o obj/tst.o $(LIBS)
	$(CC) -o tst obj/inittst.o obj/tst.o $(LIBS) -lm

tst.s:	tempc/tst.c tempc/bcpl.h tempc/INT.h
	$(CC) -O5 -S -c tempc/tst.c

obj/callstart.o:	sysc/callstart.c sysc/bcpl.h sysc/INT.h
	$(CC) -o obj/callstart.o -c sysc/callstart.c

callstart.s:	sysc/callstart.c sysc/bcpl.h sysc/INT.h
	$(CC) -O5 -S -c sysc/callstart.c

obj/tst.o:	temps/tst.s
	$(CC) -o obj/tst.o -c temps/tst.s

tst.txt:	temps/tst.s
	$(CC) -c -Wa,-alh temps/tst.s

temps/tst.s:	$(COM)/tst.b Makefile
	cintsys -c "c $(NB) $(COM) tst"
	echo tst.b compiled to temps/tst.s
	cintsys -c "sial-sasm sial/tst.sial"

obj/inittst.o:	tempc/inittst.c tempc/bcpl.h tempc/INT.h
	$(CC) -o obj/inittst.o -c tempc/inittst.c

tempc/inittst.c:	$(COM)/tst.b
	cintsys -c "makeinit $(COM)/tst.b to tempc/inittst.c"

# cmpltest

cmpltest:	obj/initcmpltest.o obj/cmpltest.o $(LIBS)
	$(CC) -o cmpltest obj/initcmpltest.o obj/cmpltest.o $(LIBS) -lm

obj/cmpltest.o:	temps/cmpltest.s
	$(CC) -o obj/cmpltest.o -c temps/cmpltest.s

temps/cmpltest.s:	$(COM)/cmpltest.b Makefile
	cintsys -c "c $(NB) $(COM) cmpltest"
	echo cmpltest.b compiled to temps/cmpltest.s

obj/initcmpltest.o:	tempc/initcmpltest.c tempc/bcpl.h tempc/INT.h
	$(CC) -o obj/initcmpltest.o -c tempc/initcmpltest.c

tempc/initcmpltest.c:	$(COM)/cmpltest.b
	cintsys -c "makeinit $(COM)/cmpltest.b to tempc/initcmpltest.c"

# fcmpltest

fcmpltest:	obj/initfcmpltest.o obj/fcmpltest.o $(LIBS)
	$(CC) -o fcmpltest obj/initfcmpltest.o obj/fcmpltest.o $(LIBS) -lm

obj/fcmpltest.o:	temps/fcmpltest.s
	echo "assembling temps/fcmpltest.s"
	ls -lrt temps/fcmpltest.s
	date
	$(CC) -o obj/fcmpltest.o -c temps/fcmpltest.s

temps/fcmpltest.s:	$(COM)/fcmpltest.b Makefile
	cintsys -c "c $(NB) $(COM) fcmpltest"
	echo fcmpltest.b compiled to temps/fcmpltest.s
	cintsys -c "sial-sasm sial/fcmpltest.sial"

obj/initfcmpltest.o:	tempc/initfcmpltest.c tempc/bcpl.h tempc/INT.h
	$(CC) -o obj/initfcmpltest.o -c tempc/initfcmpltest.c

tempc/initfcmpltest.c:	$(COM)/fcmpltest.b
	cintsys -c "makeinit $(COM)/fcmpltest.b to tempc/initfcmpltest.c"

# crdemo

crdemo:	obj/initcrdemo.o obj/crdemo.o $(LIBS)
	$(CC) -o crdemo obj/initcrdemo.o obj/crdemo.o $(LIBS) -lm

obj/crdemo.o:	temps/crdemo.s
	$(CC) -o obj/crdemo.o -c temps/crdemo.s

temps/crdemo.s:	$(DEMOS)/crdemo.b Makefile
	cintsys -c "c $(NB) $(DEMOS) crdemo"
	echo crdemo.b compiled to temps/crdemo.s

obj/initcrdemo.o:	tempc/initcrdemo.c tempc/bcpl.h tempc/INT.h
	$(CC) -o obj/initcrdemo.o -c tempc/initcrdemo.c

tempc/initcrdemo.c:	$(DEMOS)/crdemo.b
	cintsys -c "makeinit $(DEMOS)/crdemo.b to tempc/initcrdemo.c"

# edsac

edsac:	obj/initedsac.o obj/edsac.o $(LIBS)
	$(CC) -o edsac obj/initedsac.o obj/edsac.o $(LIBS) -lm

obj/edsac.o:	temps/edsac.s
	$(CC) -o obj/edsac.o -c temps/edsac.s

temps/edsac.s:	$(EDSAC)/edsac.b Makefile
	cintsys -c "c $(NB) $(EDSAC) edsac"
	echo edsac.b compiled to temps/edsac.s

obj/initedsac.o:	tempc/initedsac.c tempc/bcpl.h tempc/INT.h
	$(CC) -o obj/initedsac.o -c tempc/initedsac.c

tempc/initedsac.c:	$(EDSAC)/edsac.b
	cintsys -c "makeinit $(EDSAC)/edsac.b to tempc/initedsac.c"

# medfind

medfind:	obj/initmedfind.o obj/medfind.o $(LIBS)
	$(CC) -o medfind obj/initmedfind.o obj/medfind.o $(LIBS) -lm

obj/medfind.o:	temps/medfind.s
	$(CC) -o obj/medfind.o -c temps/medfind.s

temps/medfind.s:	$(SORT)/medfind.b Makefile
	cintsys -c "c $(NB) $(SORT) medfind"
	echo medfind.b compiled to temps/medfind.s

obj/initmedfind.o:	tempc/initmedfind.c tempc/bcpl.h tempc/INT.h
	$(CC) -o obj/initmedfind.o -c tempc/initmedfind.c

tempc/initmedfind.c:	$(SORT)/medfind.b
	cintsys -c "makeinit $(SORT)/medfind.b to tempc/initmedfind.c"

# b2sial

b2sial:	obj/initbcpl2sial.o obj/bcpl2sial.o $(LIBS)
	$(CC) -o b2sial obj/initbcpl2sial.o obj/bcpl2sial.o $(LIBS) -lm

obj/bcpl2sial.o:	temps/bcpl2sial.s
	$(CC) -o obj/bcpl2sial.o -c temps/bcpl2sial.s

temps/bcpl2sial.s:	$(COM)/bcpl2sial.b $(CINTCODE)/g/sial.h Makefile
	cintsys -c "c $(NB) $(COM) bcpl2sial"
	echo bcpl2sial.b compiled to temps/bcpl2sial.s

obj/initbcpl2sial.o:	tempc/initbcpl2sial.c tempc/bcpl.h tempc/INT.h
	$(CC) -o obj/initbcpl2sial.o -c tempc/initbcpl2sial.c

tempc/initbcpl2sial.c:	$(COM)/bcpl2sial.b
	cintsys -c "makeinit $(COM)/bcpl2sial.b to tempc/initbcpl2sial.c"

# natbcpl

natbcpl:	obj/initbcpl.o obj/bcpl.o $(LIBS)
	$(CC) -o natbcpl obj/initbcpl.o obj/bcpl.o $(LIBS) -lm

obj/bcpl.o:	temps/bcpl.s
	$(CC) -o obj/bcpl.o -c temps/bcpl.s

temps/bcpl.s:	$(COM)/bcpl.b Makefile
	cintsys -c "c $(NB) $(COM) bcpl"
	echo "$(COM)/bcpl.b compiled to temps/bcpl.s"

obj/initbcpl.o:	tempc/initbcpl.c tempc/bcpl.h tempc/INT.h
	$(CC) -o obj/initbcpl.o -c tempc/initbcpl.c

tempc/initbcpl.c:	$(COM)/bcpl.b
	cintsys -c "makeinit $(COM)/bcpl.b to tempc/initbcpl.c"



# The libraries

obj/blib.o:	temps/blib.s
	$(CC) -o obj/blib.o -c temps/blib.s

temps/blib.s:	sysb/blib.b Makefile
	cintsys -c "c $(NB) sysb blib"
	echo blib.b compiled to temps/blib.s

obj/dlib.o:	temps/dlib.s
	$(CC) -o obj/dlib.o -c temps/dlib.s

temps/dlib.s:	sysb/dlib.b Makefile
	cintsys -c "c $(NB) $(CINTCODE)/sysb dlib"
	echo dlib.b compiled to temps/dlib.s

obj/clib.o:	sysc/clib.c sysc/bcpl.h sysc/INT.h
	$(CC) -o obj/clib.o -c sysc/clib.c

clib.s:	sysc/clib.c sysc/bcpl.h sysc/INT.h
	$(CC) -S -c sysc/clib.c

obj/kblib.o:	sysc/kblib.c sysc/bcpl.h sysc/INT.h
	$(CC) -o obj/kblib.o -c sysc/kblib.c

obj/sdlfn.o:	sysc/sdlfn.c sysc/bcpl.h sysc/INT.h
	$(CC) -o obj/sdlfn.o -c sysc/sdlfn.c

obj/sdldrawlib.o:  sysc/sdldrawlib.c
	$(CC) -o obj/sdldrawlib.o -c sysc/sdldrawlib.c

obj/mlib.o:	$(MLIB)
	$(CC) -o obj/mlib.o -c $(MLIB)


demo.txt:	arm/demo.s
	$(CC) -c -Wa,-alh arm/demo.s >demo.txt


gp2xinstall:	tst
	rm -f $(SD)/Bin/tst
	cp -r tst $(SD)/Bin/tst


clean:
	rm -f core OCODE SIAL junk*
	rm -f *~ */*~ */*/*~
	rm -f sysc/INT.h tempc/INT.h
	rm -f  obj/* sial/*
	rm -f temps/*
	rm -f tempc/*
	rm -f cmpltest fcmpltest crdemo edsac medfind natbcpl
	rm -f bench100 prog tstfloat bucket tiger tst






