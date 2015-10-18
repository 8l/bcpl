# This makefile is used to copy various file to my homepage.

PUB = /homes/mr/public_html

# My public HTML directory if not mountable on this machine.
# Remember to call ssh-add before calling make sshpub.
SSHPUB = rhee.cl.cam.ac.uk:public_html

help:
	@echo
	@echo "make all      Copy the g7scale files to my home page"
	@echo

all:
	scp -p g7scales.txt  g7scales1.txt  g7scales2.txt  g7scales3.txt $(SSHPUB)



