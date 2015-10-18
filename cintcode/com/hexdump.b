// This is a program to dump files in hex and character form.
// Implemented by Martin Richards (c) June 2002

// Usage:

// hexdump filename [[n] number] [[p] recno] rl reclen
// hexdump filename [[n] number] [[p] recno] rlb reclenb
//     recno is the number of the first record to be dumped
//     number is the number of records to be dumped
//     reclen  is the record length in words
//     reclenb is the record length in bytes

// hexdump filename [[n] bytes] [[p] offset]
//     offset is the offset in the file of the first byte to be dumped
//     bytes  is the number of bytes to dump

GET "libhdr"

GLOBAL { eof: ug }

LET start() = VALOF
{ LET argv       = VEC 50
  LET sysin      = input()
  LET sysout     = output()
  LET fromname   = 0
  LET toname     = 0
  LET fromstream = 0
  LET tostream   = 0
  LET pos, n, reclen = 0, 1000000, 0

  UNLESS rdargs("FROM/A,N,P,RL/K,RLB/K,TO/K", argv, 50) DO
  { writes("bad arguments for RECDUMP*n")
    stop(20)
  }

  fromname := argv!0                                          // FROM
  IF argv!1 & string_to_number(argv!1) DO n      := result2   // N
  IF argv!2 & string_to_number(argv!2) DO pos    := result2   // P
  IF argv!3 & string_to_number(argv!3) DO reclen := result2*4 // RL
  IF argv!4 & string_to_number(argv!4) DO reclen := result2   // RLB
  toname   := argv!5                                          // TO
 
  fromstream := findinput(fromname)
  UNLESS fromstream DO
  { writef("can't open %s*n", fromname)
    stop(20)
  }

  IF toname DO
  { tostream := findoutput(toname)
    UNLESS tostream DO
    { writef("can't open %s*n", toname)
      endread()
      stop(20)
    }
    selectoutput(tostream)
  }


  selectinput(fromstream)
  eof := FALSE

  TEST reclen
  THEN writef("Dump of %s  records %n to %n  reclen=%n*n*n",
              fromname, pos, pos+n-1, reclen)
  ELSE writef("Dump of %s  from %n to %n*n*n",
              fromname, pos, pos+n-1)

  dump(pos, n, reclen)
  IF eof DO writef("End of file*n")

  selectinput(fromstream); endread()
  //endstream(fromstream)

//  UNLESS sysout=tostream DO endstream(tostream)
  UNLESS tostream=0 | sysout=tostream DO
  { selectoutput(tostream)
    endwrite()
  }

  RESULTIS 0
}

AND dump(pos, n, reclen) BE
{ // reclen is 0 or the record length in bytes
  // reclen>0 dump n records from byte record number pos
  // reclen=0 dump n bytes from byte offset pos
  LET offset = pos
  IF reclen DO offset := pos*reclen

  // Get to first byte to dump
  FOR i = 1 TO offset IF binrdch()=endstreamch DO
  { eof := TRUE
    BREAK
  }

  TEST reclen
  THEN FOR recno = pos TO pos+n-1 DO
       { dumphex(recno, ?, reclen)
         newline()
         IF eof BREAK
       }
  ELSE dumphex(pos, n, 0)
}

AND dumphex(pos, n, reclen) BE
// reclen>0   pos is the record number
//            n   is not used
// reclen=0   pos is the byte offset in the file
//            n   is the number of bytes to dump
{ LET word = #x00010203
  LET xbits = (@word)%0 // =0 for bigender,  =3 for little ender
  LET count = 0         // count of bytes read so far
  IF reclen DO n := reclen

  { LET v = VEC 15
    LET oldcount = count
    LET k = n - count   // bytes remaining to be read
    FOR i = 0 TO 15 DO v!i := -1

    UNLESS k>0 RETURN

    IF k>15 DO k := 16
 
    // k = number of bytes to attempt to read
    FOR i = 0 TO k-1 DO
    { LET ch = binrdch()
      TEST ch=endstreamch THEN eof := TRUE
                          ELSE v!i, count := ch, count+1
    }

    IF count=oldcount RETURN // Return is no bytes read

    // If at least one byte
    TEST reclen
    THEN writef("%i5/%i5:", pos,       oldcount/4)
    ELSE writef("%i5/%i5:", pos+oldcount, (pos+oldcount)/4)

    FOR p = 0 TO 15 DO
    { LET byte = v!(p XOR xbits) // Swap bytes for little ender M/Cs
      UNLESS p REM 4 DO wrch(' ')
      TEST byte>=0 THEN writef("%x2", byte)
                   ELSE writef("  ")
    }
    writes(" ")
    FOR p = 0 TO 15 DO
    { LET byte = v!p
      UNLESS p REM 4 DO wrch(' ')
      TEST byte>=0 THEN wrch(filter(byte))
                   ELSE wrch(' ')
    }

    newline()

    //IF testflags(flag_b) DO
    //{ writef("************ BREAK*n")
    //  RETURN
    //}
  } REPEAT
}


AND filter(ch) = 32<=ch<127 -> ch, '.'
