gltst:	tigermothmodel.mdl gltst.b
	cintsys -c c b gltst
	cintsys -- gltst obj


sdltst:	tigermothmodel.mdl
	gcc -o sdltst sdltst.c `sdl-config --cflags --libs`

tigermothmodel.mdl: mktigermothmodel
	cintsys -c mktigermothmodel


mktigermothmodel: mktigermothmodel.b
	cintsys -c c b mktigermothmodel

xreftiger:
	cintsys -c c b tiger xref >rawxref
	cintsys -c sortxref rawxref to xtiger
	rm rawxref

xrefrubik:
	cintsys -c c b rubik xref >rawxref
	cintsys -c sortxref rawxref to xrubik
	rm rawxref

clean:
	rm -f mktigermothmodel tigermothmodel.mdl gltst
