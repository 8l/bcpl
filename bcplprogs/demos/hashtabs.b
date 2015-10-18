GET "libhdr"

GLOBAL {
  tab:ug   // The hash table with tabsize entries
  p0       // The latest primary probe
  hash2    // the latest result of the second hash function
  entries  // Number of entries in the table
  prcount  // count of probes
  maxprcount // The longest probe sequence needed to lookup a key
  tabsize  // Hash table size
  initseed     // Random number seed
}

LET start() = VALOF
{ LET argv = VEC 50

  UNLESS rdargs("size,seed,np=notprime", argv, 50) DO
  { writef("Bad argument*n")
    RESULTIS 0
  }

  tabsize, initseed := 541, 1
  IF argv!0 & string.to.number(argv!0) DO tabsize := result2
  IF argv!1 & string.to.number(argv!1) DO initseed := result2

  UNLESS argv!2 UNTIL isprime(tabsize) DO tabsize := tabsize+1

  writef("tabsize=%n  seed=%n*n", tabsize, initseed)

  tab := getvec(tabsize)
  UNLESS tab DO
  { writef("Unable to allocate the hash table*n")
    RESULTIS 0
  }

  try("sh1", ph, sh1, 50)
  //try("sh1", ph, sh1, 60)
  try("sh1", ph, sh1, 70)
  //try("sh1", ph, sh1, 80)
  try("sh1", ph, sh1, 90)
  try("sh1", ph, sh1, 95)
  //try("sh1", ph, sh1, 99)
  newline()
  
  try("sh2", ph, sh2, 50)
  //try("sh2", ph, sh2, 60)
  try("sh2", ph, sh2, 70)
  //try("sh2", ph, sh2, 80)
  try("sh2", ph, sh2, 90)
  try("sh2", ph, sh2, 95)
  //try("sh2", ph, sh2, 99)
  newline()
  
  try("sh3", ph, sh3, 50)
  //try("sh3", ph, sh3, 60)
  try("sh3", ph, sh3, 70)
  //try("sh3", ph, sh3, 80)
  try("sh3", ph, sh3, 90)
  try("sh3", ph, sh3, 95)
  //try("sh3", ph, sh3, 99)
  newline()
  
  try("sh4", ph, sh4, 50)
  //try("sh4", ph, sh4, 60)
  try("sh4", ph, sh4, 70)
  //try("sh4", ph, sh4, 80)
  try("sh4", ph, sh4, 90)
  try("sh4", ph, sh4, 95)
  //try("sh4", ph, sh4, 99)
  newline()
  
  try("sh5", ph, sh5, 50)
  //try("sh5", ph, sh5, 60)
  try("sh5", ph, sh5, 70)
  //try("sh5", ph, sh5, 80)
  try("sh5", ph, sh5, 90)
  try("sh5", ph, sh5, 95)
  //try("sh5", ph, sh5, 99)
  newline()
  

  IF tab DO freevec(tab)
  RESULTIS 0  
}

AND isprime(n) = VALOF
{ LET i = 2
  UNTIL i*i>n TEST n MOD i = 0
              THEN RESULTIS FALSE
              ELSE i := i+1
  RESULTIS TRUE
}

AND try(method, f1, f2, u) BE
{ LET ipart, fpart, x, maxk = 0, 0, 0, 0
  LET k = tabsize * u / 100

  setseed(initseed)

  // For the raster scan pictures
  FOR i = 1 TO 10000 DO tab!0, tab!tabsize := 0, 0

  FOR i = 0 TO tabsize DO tab!i := -1
  entries := 0
  UNTIL entries>=k DO
  { LET key = randno(100_000_000)
    //writef("key=%n*n", key); entries := entries+1
    insert(key, f1, f2)
  }

  prcount := 0
  FOR i = 0 TO tabsize-1 DO
  { LET key = tab!i
    IF key >= 0 DO
    { LET k = prcount
      lookup(key, f1, f2)
      k := prcount - k
      IF maxk < k DO maxk := k
    }
  }
  //writef("k=%n  prcount=%n*n", k, prcount)
  x := muldiv(prcount, 1000, k)

  ipart, fpart := x/1000, x MOD 1000

  writef("Method %s, %i2%% used, ", method, u)
  writef("  max probes %i5  average %i4.%z3*n", maxk, ipart, fpart)
}

AND insert(key, f1, f2) BE
{
  //writef("insert: key = %n*n", key)
  f1()
  //writef("insert: probe %n*n", p0)
  IF tab!p0<0 DO
  { tab!p0 := key
    entries := entries+1
    RETURN
  }
  FOR i = 1 TO tabsize DO // Don't allow too many probes
  { LET p = f2(i)
    //writef("insert: p=%n  tab!p=%n*n", p, tab!p)
    IF tab!p<0 DO
    { tab!p := key
      entries := entries+1
      RETURN
    }
  }

  writef("Cannot insert a key*n")
  FOR i = 0 TO tabsize-1 DO
  { IF i MOD 50 = 0 DO newline()
    writef("%c", tab!i=-1 -> '.', '**')
  }
  newline()
  abort(999)
}

AND lookup(key, f1, f2) = VALOF
{ f1()
  prcount := prcount+1
  IF tab!p0<0 RESULTIS -1
  IF tab!p0 = key RESULTIS key

  FOR i = 1 TO 1000 DO // Don't allow too many probes
  { LET p = f2(i)
    prcount := prcount+1
    IF tab!p<0 RESULTIS -1
    IF tab!p = key RESULTIS key
  }

  RESULTIS -1
}

AND ph(key) = VALOF
{ hash2 := (key*key >> 1) MOD 1000
  p0 := key MOD tabsize
  RESULTIS p0
}

AND sh1(i) = (p0 + i) MOD tabsize

AND sh2(i) = (p0 + 13*i) MOD tabsize

AND sh3(i) = (p0 + 13*i + 17*i*i) MOD tabsize

AND sh4(i) = (p0 + hash2*i + 17*i*i) MOD tabsize

AND sh5(i) = (p0 + (hash2+1)*i) MOD tabsize

