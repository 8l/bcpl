GET "libhdr"

LET start() = VALOF
{ FOR i = 0 TO 32 SWITCHON 1<<i INTO
  { DEFAULT:    writef("%n BAD*n", i); LOOP
    CASE 1<< 0: writef("%n OK*n", i); LOOP
    CASE 1<< 1: writef("%n OK*n", i); LOOP
    CASE 1<< 2: writef("%n OK*n", i); LOOP
    CASE 1<< 3: writef("%n OK*n", i); LOOP
    CASE 1<< 4: writef("%n OK*n", i); LOOP
    CASE 1<< 5: writef("%n OK*n", i); LOOP
    CASE 1<< 6: writef("%n OK*n", i); LOOP
    CASE 1<< 7: writef("%n OK*n", i); LOOP
    CASE 1<< 8: writef("%n OK*n", i); LOOP
    CASE 1<< 9: writef("%n OK*n", i); LOOP
    CASE 1<<10: writef("%n OK*n", i); LOOP
    CASE 1<<11: writef("%n OK*n", i); LOOP
    CASE 1<<12: writef("%n OK*n", i); LOOP
    CASE 1<<13: writef("%n OK*n", i); LOOP
    CASE 1<<14: writef("%n OK*n", i); LOOP
    CASE 1<<15: writef("%n OK*n", i); LOOP
    CASE 1<<16: writef("%n OK*n", i); LOOP
    CASE 1<<17: writef("%n OK*n", i); LOOP
    CASE 1<<18: writef("%n OK*n", i); LOOP
    CASE 1<<19: writef("%n OK*n", i); LOOP
    CASE 1<<20: writef("%n OK*n", i); LOOP
    CASE 1<<21: writef("%n OK*n", i); LOOP
    CASE 1<<22: writef("%n OK*n", i); LOOP
    CASE 1<<23: writef("%n OK*n", i); LOOP
    CASE 1<<24: writef("%n OK*n", i); LOOP
    CASE 1<<25: writef("%n OK*n", i); LOOP
    CASE 1<<26: writef("%n OK*n", i); LOOP
    CASE 1<<27: writef("%n OK*n", i); LOOP
    CASE 1<<28: writef("%n OK*n", i); LOOP
    CASE 1<<29: writef("%n OK*n", i); LOOP
    CASE 1<<30: writef("%n OK*n", i); LOOP
    CASE 1<<31: writef("%n OK*n", i); LOOP
  }
}
