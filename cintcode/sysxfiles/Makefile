
all:
	(cd ..; \
	cintsys -c xcencode bin list sysxfiles/cintsys-files to sysxfiles/cintsys.xc)

send:	all
	mail mrich177@ford.com -s cintsys-xc    <cintsys.xc

SONY8GB:	all
	(cd ..; cp -r sysxfiles /media/SONY8GB/)

HPA8GB:	all
	(cd ..; cp -r sysxfiles /media/HPA8GB/)

HPB8GB:	all
	(cd ..; cp -r sysxfiles /media/HPB8GB/)

SANDISC32:	all
	(cd ..; cp -r sysxfiles /media/SANDISC32/)


