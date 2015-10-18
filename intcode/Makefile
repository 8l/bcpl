
# The is the make file to BCPL Intcode System

# Implemented by Martin Richards (c) October 2012

xrefinterp:	interp.b ../cintcode/g/bcplfecg.h
	cintsys -c c b interp xref >rawxref
	cintsys -c sortxref rawxref to xrefinterp
	rm rawxref

