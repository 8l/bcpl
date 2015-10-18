GET "libhdr"

LET start() = VALOF
{ LET days, msecs, filler = 0, 0, 0
  datstamp(@days)
  writef("days=%n msecs=%n filler=%n*n", days, msecs, filler)

  // Output the time in hh:mm:ss.mmm format
  writef("The time is %2i:%2z:%2z.%3z*n",
          msecs/(60*60*1000),      // The hours
          msecs/(60*1000) MOD 60,  // The minutes
          msecs/1000 MOD 60,       // The seconds
          msecs MOD 1000)          // The milli-seconds
  RESULTIS 0
}

