
run:	mctest mci386 mctest tst1 mcsystest mcqueens cachetest
	cintsys -- mcsystest

mctest:	mctest.b mc.h
	cintsys -c c b mctest

mcsystest:	mcsystest.b mcsystest.h mc.h
	cintsys -c c b mcsystest

tst1:	tst1.b mc.h
	cintsys -c c b tst1

check:	mccheck.b mc.h mci386
	cintsys -c c b mccheck
	cintsys -c mccheck

mci386:	mci386.b mc.h
	cintsys -c c b mci386

mcqueens:	mcqueens.b mc.h mci386
	cintsys -c c b mcqueens

cachetest:	cachetest.b mc.h mci386
	cintsys -c c b cachetest

xref:
	cintsys -c c b mci386 xref |\
	egrep " [MSFG]:" |\
        tr -d "\015" |\
	sed -e "s/\./<dot>/g" |\
	sort -u |\
	sed -e "s/<dot>/\./g" > xrefdata

asm:
	as -a -o tst.o tst.s

t1:
	as -a -o t1.o t1.s

install:
	cp mc.h ../../cintcode/g
	cp mci386.b ../../cintcode/com
	cp mcqueens.b ../demos/
	(cd ../../cintcode; cintsys -c c bc mci386)

clean:
	rm -f OCODE COMFILE core mci386
	rm -f *~ 
	rm -f *.obj *.o
	rm -f *.o junk*

