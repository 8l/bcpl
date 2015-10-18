RELFILES = a.rel m4.rel 1.rel greaves.rel jnh307.rel t1.rel

all:	cnf2rel sat2cnf exp2rel $(RELFILES)


cnf2rel:	cnf2rel.b
	cintsys -c c b cnf2rel

sat2cnf:	sat2cnf.b
	cintsys -c c b sat2cnf

exp2rel:	exp2rel.b
	cintsys -c c b exp2rel

a.rel:	a.exp exp2rel
	cintsys -c exp2rel a.exp to a.rel

m4.rel:	m4.exp exp2rel
	cintsys -c exp2rel m4.exp to m4.rel

1.rel:	1.cnf cnf2rel
	cintsys -c cnf2rel 1.cnf to 1.rel

greaves.rel:	greaves.cnf cnf2rel
	cintsys -c cnf2rel greaves.cnf to greaves.rel

t1.rel:	t1.cnf cnf2rel
	cintsys -c cnf2rel t1.rel to t1.rel

jnh307.rel:	jnh307.cnf cnf2rel
	cintsys -c cnf2rel jnh307.cnf to jnh307.rel

jnh307.cnf:	jnh307.sat sat2cnf
	cintsys -c sat2cnf jnh307.sat to jnh307.cnf

xref:
	cintsys -c c b exp2rel xref |\
	egrep " [MSFG]:" |\
	tr -d "\015" |\
	sed -e "s/\./<dot>/g" |\
	sort -u |\
	sed -e "s/<dot>/\./g" > xrefdata

clean:
	rm -f *~ cnf2rel sat2cnf exp2rel junk
	rm -f a.rel 1.rel greaves.rel t1.rel jnh307.rel jnh307.cnf


