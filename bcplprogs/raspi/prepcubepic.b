/*

This program read pigcube.txt and generates cubepic.txt which is
suitable data for cubepic.b which plots a 3D image of the optimum
strategy for the pig dice game.

Implemented by Martin Richards (c) March 2014

The file cubepic.txt contains one line for each (opponent score, own
score) pair. The rest of the line contains then run length encoding of
which turn scores have play the die as the optimum strategy. For
instance one line of cubepic.txt is as follows.

36 42 21 70 9

This states that when the opponent score is 36 and the player's score
is 42, then the optimum strategy for turn scores 0 to 20 is PLAY, 21
to 90 is HOLD and 91 to 99 is PLAY. Note that 21+70+9=100. The lines
occur in random order.
*/

GET "libhdr"

GLOBAL {
  stdin:ug
  stdout
  probsstream
  picstream
  bitsv
  randv
  picbytes
  playcount
}

MANIFEST {
  bitssize = 100 / bitsperword + 1
  bitsvupb = 100*100*bitssize - 1
  randvupb = 100*100 - 1
}

LET start() = VALOF
{ 
  stdin := input()
  stdout := output()
  probsstream := findinput( "pigcube.txt")
  picstream   := findoutput("cubepic.txt")
  bitsv := getvec(bitsvupb)
  randv := getvec(randvupb)

  UNLESS probsstream DO
  { writef("Trouble with file: pigcube.txt*n")
    GOTO fin
  }

  UNLESS picstream DO
  { writef("Trouble with file: cubepic.txt*n")
    GOTO fin
  }

  UNLESS bitsv & randv DO
  { writef("More memory needed*n")
    GOTO fin
  }

  FOR i = 0 TO bitsvupb DO bitsv!i := 0

  selectinput(probsstream)

  // Setup the bit map
  FOR op = 0 TO 99 FOR my = 0 TO 99 DO
  { LET i = op*100 + my
    LET bitv = @bitsv!(i*bitssize)
    LET ts = 0

    WHILE ts<100 DO
    { LET ch = rdch()
      IF ch=endstreamch BREAK
      IF ch='H' | ch='P' DO
      { LET p  = ts  /  bitsperword
        LET sh = ts MOD bitsperword
        LET bit = 1 << sh
        IF ch='P' DO bitv!p := bitv!p | bit
//writef("%i2 %i2 %i2: %c %i3 %32b %32b*n", op, my, ts, ch, p, bit, bitv!p)
//abort(6666)
        ts := ts+1
      }
    }
  }

  selectoutput(picstream)

  picbytes := 0
  playcount := 0

  // Output info for each (op,my) pair
  FOR op = 99 TO 0 BY -1 FOR my = 99 TO 0 BY -1 DO

  { //LET w = randv!i
    LET bitv = bitsv + (op*100 + my) * bitssize
    LET p, count = 0, 0
    LET total = 0
    writef("%i2 %i2  ", op, my)
    picbytes := picbytes+2

//writef("*n%32b %32b *n%32b %32b*n", bitv!0, bitv!1, bitv!2, bitv!3)
//abort(1000)
//LOOP
    WHILE p<100 DO
    { WHILE p<100 & bitset(bitv, p)=1 DO
        count, p := count+1, p+1  // Increment PLAY count
      IF count DO
      { writef(" %i3", count)
        picbytes := picbytes+1
        playcount := playcount+count
      }
      total := total + count
//newline()
//abort(1001)
      count := 0

      WHILE p<100 & bitset(bitv, p)=0 DO
        count, p := count+1, p+1  // Increment HOLD count
      IF count DO
      { writef(" %i3", count)
        picbytes := picbytes+1
      }
      total := total + count
//newline()
//abort(1002)
      count := 0
    }
    newline()
    UNLESS total=100 DO
    { sawritef("op=%n my=%n total=%n*n", op, my, total)
      abort(999)
    }
//abort(1000)
  }

  selectoutput(stdout)
  writef("*nPicture data size = %n bytes, playcount = %n*n",
            picbytes, playcount)

fin:  
  IF probsstream DO endstream(probsstream)
  IF picstream DO endstream(picstream)
  IF bitsv DO freevec(bitsv)
  IF randv DO freevec(randv)

  RESULTIS 0
}

AND bitset(v, i) = VALOF
{ LET p  = i  /  bitsperword
  LET sh = i MOD bitsperword
  RESULTIS (v!p >> sh) & 1
}
