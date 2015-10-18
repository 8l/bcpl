# "../" below is included to simplify compilation for a
# different architecture sharing the same filing system.
SYSC = ../cintcode/sys

# Select the appropriate definition of CC, LIBS ans SYSM
# SYSM givies the location of machine specific code (eg cintasm.s)

LIBS =

#CC = gcc -O -g -DforMAC

#CC = gcc -O -g -DforMIPS
#SYSM = ../cintcode/sys/MIPS

#CC = gcc -O -g -DforSUN4
#SYSM = ../cintcode/sys/SUN4

CC = gcc -O -g -DforALPHA
SYSM = ../cintcode/sys/ALPHA
LIBS = -lbsd

#CC = gcc -O -g -DforMSDOS
#SYSM = ../cintcode/sys/MSDOS

#CC = gcc -O -g -DforOS2
#SYSM = ../cintcode/sys/OS2

OBJ = cintmain.o cinterp.o kblib.o cintasm.o

DELABLE = Leval Xsquare bcplxref bench bgpm \
        bigprimes casech cavity charhist \
        checksum cmpltest coins coprimes crc \
        crdemo cstats d3nodes delete demo \
        edit epr163 eval evale fact \
        fail fft fft16 findperm ham2 \
        ham23 hamming hello input interp \
        jumbo make maze modsqrt msort \
        namestats net nqueens pattern penta \
        penta3 prdvi primefib primes prompt queens \
        queens12 queens2 rantree ranexpr raster \
        regions rename rotate sharetree shell23 \
        solit solitaire sortdemo squad stack \
        stats tally triangle tstmuldiv ttt \
        typehex unpreload warshll

run:	cinterp
	cinterp

debug:	cinterp
	stty sane
	dbx cinterp

RUN:	rasterp
	rasterp

cintmain.o:	$(SYSC)/cintmain.c
	$(CC) -c $(SYSC)/cintmain.c

cinterp.o:	$(SYSC)/cinterp.c
	$(CC) -c $(SYSC)/cinterp.c

cintasm.o:	$(SYSM)/cintasm.s
#	as -o cintasm.o -g3 $(SYSS)/cintasm.s
	as -o cintasm.o $(SYSM)/cintasm.s

rasterp.o:	$(SYSC)/rasterp.c
	$(CC) -c $(SYSC)/rasterp.c

nullrastlib.o:	$(SYSC)/nullrastlib.c
	$(CC) -c $(SYSC)/nullrastlib.c

rastlib.o:	$(SYSC)/rastlib.c
	$(CC) -c $(SYSC)/rastlib.c

cinterp:	$(OBJ) nullrastlib.o
	$(CC) -o cinterp $(OBJ) nullrastlib.o $(LIBS)

rasterp:	$(OBJ) rasterp.o rastlib.o 
	$(CC) -o rasterp $(OBJ) rasterp.o rastlib.o $(LIBS)

kblib.o:	$(SYSC)/kblib.c
	$(CC) -c $(SYSC)/kblib.c

clean:
	rm -f OCODE COMFILE core
	rm -f *~ sys/*~ com/*~ doc/*~ sys/*/*~
	rm -f *.cin

vclean: clean
	rm -f cinterp *.o
	rm -f $(DELABLE)




