all:	chk8 data/a.rel data/m4.rel
	@echo
	cintsys

chk8:	chk8.b chk8.h
	cintsys -c c b chk8

data/a.rel:	data/a.exp data/exp2rel
	(cd data; make)

data/m4.rel:	data/m4.exp data/exp2rel
	(cd data; make)

data/exp2rel:	data/exp2rel.b
	(cd data; make)

xref:
	cintsys -c c compall xref |\
	egrep " [MSFG]:" |\
	tr -d "\015" |\
	sed -e "s/\./<dot>/g" |\
	sort -u |\
	sed -e "s/<dot>/\./g" > xrefdata

clean:
	rm -f *~ chk8


