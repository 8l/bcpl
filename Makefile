# This makefile is used to create .tgz .zip versions
# of the BCPL distribution.

PUB = /homes/mr/public_html

# Public HTML directory if not mountable on this machine
# and the shared drive is called E: (/dose on Linux).
# Remember to call ssh-add before calling make sshpub.
SSHPUB = sandy.cl.cam.ac.uk:public_html

help:
	@echo
	@echo "make all      Construct the files: bcpl.tgz and bcpl.zip"
	@echo "make dosd     Put them in my D drive"
	@echo "make dose     Put them in my E drive"
	@echo "make pub      Put them also in my home page"
	@echo "make sshpubd  Put them in /dosd and my home page using scp"
	@echo "make sshpube  Put them in /dose and my home page using scp"
	@echo

all:	
	rm -f *~ */*~
	echo >TGZDATE
	echo -n "Distributed from machine: " >>TGZDATE
	hostname >>TGZDATE
	date >>TGZDATE
	rm -f FILES
	cp cintcode/doc/README .
	(cd cintcode; make vclean)
	(cd natbcpl; make clean)
	(cd bcplprogs; make vclean)
	(cd ..; tar cvzf bcpl.tgz BCPL)
	(cd ..; rm -f bcpl.zip)
	(cd ..;  zip -rv9 bcpl.zip BCPL)
	cp TGZDATE FILES
	ls -l ../bcpl.tgz ../bcpl.zip>>FILES

pub:	dosd
	cp README FILES ../bcpl.tgz ../bcpl.zip $(PUB)/BCPL
	cat FILES

sshpubd:	dosd
	scp README FILES ../bcpl.tgz ../bcpl.zip $(SSHPUB)/BCPL
	cat FILES

sshpube:	dose
	scp README FILES ../bcpl.tgz ../bcpl.zip $(SSHPUB)/BCPL
	cat FILES

ssh:
	scp README $(SSHPUB)/BCPL

dosd:	all
	cp ../bcpl.tgz ../bcpl.zip /dosd

dose:	all
	cp ../bcpl.tgz ../bcpl.zip /dose
