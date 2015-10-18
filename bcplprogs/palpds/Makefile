

pal:	pal.b palhdr.h
	cintsys -c xbcpl pal.b to pal

xref:	pal.b palhdr.h
	cintsys -c xbcpl pal.b xref >rawxref
	cintsys -c sortxref rawxref to xrefpal
	rm rawxref

