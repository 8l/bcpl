all:	chk3
	cintsys

chk3:	chk3.b chk3.h
	echo "c b chk3" | cintsys

xref:
	echo "c compall xref" | cintsys |\
	egrep " [MSFG]:" |\
	tr -d "\015" |\
	sed -e "s/\./<dot>/g" |\
	sort -u |\
	sed -e "s/<dot>/\./g" > xrefdata

clean:
	rm -f *~ chk3 trans1 apfns apvar tests bmat utils debug

