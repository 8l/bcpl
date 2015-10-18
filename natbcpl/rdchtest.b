SECTION "prog"

GET "libhdr"
LET start() = VALOF {
	LET c = VEC 5
	FOR i = 1 TO 5 DO c!i := rdch()
	FOR i = 1 TO 5 writef(" %x2", c!i)
	newline()
	RESULTIS 0
}
