help:
	@echo
	@echo "bench       Run cobench"
	@echo "bencht      Run cobench with tracing"
	@echo "sim         Run cosim"
	@echo "simt        Run cosim with tracing"
	@echo "test        Run cotest"
	@echo "clean       Delete compiled files"
	@echo "help        Display the help infomation"
	@echo


bench:	cobench
	echo "cobench" | time cinterp

bencht:	cobench
	echo "cobench -n 3 -k 2 -t" | time cinterp

test:	cotest
	echo "cotest" | cinterp

sim:	cosim
	echo "cosim" | time cinterp

simt:	cosim
	echo "cosim -n 5 -s 1000 -p 500 -t" | cinterp

cobench:	cobench.b
	echo "c b cobench" | cinterp

cotest:	cotest.b
	echo "c b cotest" | cinterp

cosim:	cosim.b
	echo "c b cosim" | cinterp

clean:
	rm -f cobench cotest cosim *~



