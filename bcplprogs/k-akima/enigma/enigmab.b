// Enigma

GET "libhdr"

STATIC {
	inbuff
	fourth = 0
	rotors
	ring
	plugs
	posn
	reflector
	ptext; ctext
}

LET TermClearScreen() BE
	sawritef("*e[1;1H*e[2J")
LET TermClearEoL() BE
	sawritef("*e[K")
LET TermMoveCursor(row, col) BE
	sawritef("*e[%i1;%i1H", row + 1, col + 1)

LET start() = VALOF {
	LET Prompt(prompt) = VALOF {
		LET c, i = ?, 1
		sawritef("%s: ", prompt)
		{
			c := rdch()
			SWITCHON c INTO {
			CASE 9:
				IF 1 < i i := i = 1
				ENDCASE
			CASE '*n':
				BREAK
			DEFAULT:
				inbuff!i, i := c, i + 1
				ENDCASE
			}
		} REPEAT
		RESULTIS i - 1
	}
	LET ConfigRotor(r) = VALOF {
		LET v = getvec(3)
		LET w, n = RotorWiring(r), RotorNotches(r)
		v!1 := getvec(26)
		FOR i = 1 TO 26 v!1!i := w%i - 'A'
		v!2 := getvec(26)
		FOR i = 1 TO 26 v!2!(w%i - 'A' + 1) := i - 1
		v!3, v!3!1 := getvec(3), n%0
		FOR i = 1 TO n%0 v!3!(i+1) := n%i - 'A'
		RESULTIS v
	}
	AND RotorWiring(r) = VALOF {
		SWITCHON r INTO {
			DEFAULT:	RESULTIS "EKMFLGDQVZNTOWYHXUSPAIBRCJ"
			CASE '2':	RESULTIS "AJDKSIRUXBLHWTMCQGZNPYFVOE"
			CASE '3':	RESULTIS "BDFHJLCPRTXVZNYEIWGAKMUSQO"
			CASE '4':	RESULTIS "ESOVPZJAYQUIRHXLNFTGKDCMWB"
			CASE '5':	RESULTIS "VZBRGITYUPSDNHLXAWMJQOFECK"
			CASE '6':	RESULTIS "JPGVOUMFYQBENHZRDKASXLICTW"
			CASE '7':	RESULTIS "NZJHGRCXMYSWBOUFAIVLPEKQDT"
			CASE '8':	RESULTIS "FKQHTLXOCBJSPDZRAMEWNIUYGV"
			CASE 'b':	RESULTIS "LEYJVCNIXWPBQMDRTAKZGFUHOS"
			CASE 'g':	RESULTIS "FSOKANUERHMBTIYCWLQPZXVGJD"
		}
		RESULTIS ""
	}
	AND RotorNotches(r) = VALOF {
		SWITCHON r INTO {
		DEFAULT:	RESULTIS "Q"
		CASE '2':	RESULTIS "E"
		CASE '3':	RESULTIS "V"
		CASE '4':	RESULTIS "J"
		CASE '5':	RESULTIS "Z"
		CASE '6':
		CASE '7':
		CASE '8':	RESULTIS "MZ"
		CASE 'b':
		CASE 'g':	RESULTIS ""
		}
		RESULTIS ""
	}
	LET AppendLetter(s, l) BE {
		FOR i = 1 TO 59 s%i := s%(i+1)
		s%60 := l
	}
	LET AtNotch(r) = VALOF {
		FOR i = 1 TO rotors!r!3!1 IF posn!r = rotors!r!3!(i+1) RESULTIS 1
		RESULTIS 0
	}
	LET Translate(r, tt, c) = VALOF {
		LET o = (ring!r - posn!r + 26) MOD 26
		c := (c - o + 26) MOD 26
		c := rotors!r!tt!(c+1)
		c := (c + o) MOD 26
		RESULTIS c
	}
	LET n = ?
	LET ch = ?

	rdch()
	TermClearScreen()
	TermMoveCursor(10, 0)
	inbuff := getvec(30)
	IF 4 = Prompt("Rotor Order") fourth := 1
	rotors := getvec(3 + fourth)
	FOR i = 1 TO 3 rotors!i := ConfigRotor(inbuff!(i+fourth))
	IF fourth      rotors!4 := ConfigRotor(inbuff!1)
	Prompt("Ring Settings")
	ring := getvec(4)
	IF fourth ring!4 := inbuff!1 - 'a'
	FOR i = 1 TO 3 ring!i := inbuff!(i + fourth) - 'a'
	n := Prompt("Plugboard Connections")
	plugs := getvec(26)
	FOR i = 1 TO 26 plugs!i := i - 1
	UNLESS n < 2 n := n - n MOD 2
	FOR i = 1 TO n BY 2 {
		LET c1, c2 = inbuff!i - 'a', inbuff!(i+1) - 'a'
		plugs!(c1+1), plugs!(c2+1) := c2, c1
	}
	posn := getvec(4)
	Prompt("Rotor Positions")
	IF fourth posn!4 := inbuff!1 - 'a'
	FOR i = 1 TO 3 posn!i := inbuff!(i + fourth) - 'a'
	reflector := getvec(26)
	TEST fourth n := "ENKQAUYWJICOPBLMDXZVFTHRGS"
	ELSE        n := "YRUHQSLDPXNGOKMIEBFZCWVJAT"
	FOR i = 1 TO 26 reflector!i := n%i - 'A'
	ptext, ptext%0 := getvec(16), 60
	ctext, ctext%0 := getvec(16), 60
	FOR i = 1 TO 61 ptext%i, ctext%i := ' ', ' '
	TermClearScreen()
	{
		TermMoveCursor(0, 27)
		sawrch('[')
		IF fourth sawrch('A' + posn!4)
		FOR i = 1 TO 3 sawrch('A' + posn!i)
		sawrch(']')
		TermMoveCursor(0, 0)
		ch := sardch()
		IF 'C' = ch {
			TermMoveCursor(2, 0);	TermClearEoL()
			TermMoveCursor(3, 0);	TermClearEoL()
			FOR i = 1 TO 61 ptext%i, ctext%i := ' ', ' '
			LOOP
		}
		IF 'R' = ch {
			TermMoveCursor(10, 0)
			Prompt("Rotor Positions")
			IF fourth posn!4 := inbuff!1 - 'a'
			FOR i = 1 TO 3 posn!i := inbuff!(i + fourth) - 'a'
			TermMoveCursor(10, 0);	TermClearEoL()
			LOOP
		}
		IF 'X' = ch BREAK
		IF 'a' <= ch <= 'z' {
			AppendLetter(ptext, ch)
			TermMoveCursor(2, 0)
			sawritef("%s", ptext)
			ch := ch - 'a'
			TEST AtNotch(2)	posn!1, posn!2 := (posn!1 + 1) MOD 26, (posn!2 + 1) MOD 26
			ELSE			IF AtNotch(3)	posn!2 := (posn!2 + 1) MOD 26
			posn!3 := (posn!3 + 1) MOD 26
			ch := plugs!(ch+1)
			FOR i = 3 TO 1 BY -1 ch := Translate(i, 1, ch)
			IF fourth ch := Translate(4, 1, ch)
			ch := reflector!(ch+1)
			IF fourth ch := Translate(4, 2, ch)
			FOR i = 1 TO 3 ch := Translate(i, 2, ch)
			ch := plugs!(ch+1)
			AppendLetter(ctext, ch + 'A')
			TermMoveCursor(3, 0)
			sawritef("%s", ctext)
		}
	} REPEAT
	TermClearScreen()
	freevec(inbuff)
	FOR i = 1 TO 3 + fourth {
		freevec(rotors!i!1)
		freevec(rotors!i!2)
		freevec(rotors!i!3)
		freevec(rotors!i)
	}
	freevec(rotors)
	freevec(ring)
	freevec(plugs)
	freevec(posn)
	freevec(reflector)
	freevec(ptext)
	freevec(ctext)

	RESULTIS 0
}
