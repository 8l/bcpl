/*

This is a simple demonstration of a genetic algorithm

Implemented in BCPL by Martin Richards August 2001
*/

GET "libhdr"

GLOBAL
{ pop:ug
  val
}

MANIFEST
{ upb         = 1000
  elite       = 10
  generations = 80
  mprob       = 50
}

// The problem is to find a w that maximises eval(w)

//LET eval(w) =  -10000<w<10000 -> w*w & #x7FFFFFFF, w>>16

LET eval(w) = w=0 -> 0, 1+eval(w&(w-1))

LET start() = VALOF
{ writef("Population = %n  Elite = %n*n", upb, elite)

  pop := getvec(upb)
  val := getvec(upb)

  FOR i = 1 TO upb DO pop!i := rand()

  FOR i = 1 TO generations DO
  { 
    // Calculate the fitness of each member of the population
    FOR i = 1 TO upb DO val!i := eval(pop!i)

    // Sort into decreasing order of fitness
    sort(1, upb)

//UNLESS i REM 10 DO
{   writef("*nGeneration %n*n", i)
    FOR i = 1 TO upb>20 -> 20, upb DO
    { writef(" %i9/%x8", val!i, pop!i)
      UNLESS i REM 4 DO newline()
    }
//abort(1000)
}
    // Mate pairs
    FOR r = upb TO elite+1 BY -1 DO
    { // Choose random parents
      LET p = randno(r)
      LET q = randno(r)
      LET a, b = pop!p, pop!q
      LET mask = rand()
      LET x = a NEQV b
 
//writef("mask = %x8 m1=%x8 m2=%x8*n", mask, m1, m2)
      
//writef("a = %bW*n", a)
//writef("b = %bW*n", b)
//writef("m = %bW*n", mask)
      a := a NEQV x & mask
//writef("a = %bW*n", a)
//abort(1001)

      pop!r := a
    }

    // Mutate mprob% of non elite members
    FOR i = elite+1 TO upb IF randno(100)<=mprob DO
      pop!i := pop!i NEQV 1 << (randno(100000) & 31)

    // Do it again -- to allow a possible 2 bit mutation
    FOR i = elite+1 TO upb IF randno(100)<=mprob DO
      pop!i := pop!i NEQV 1 << (randno(100000) & 31)
  }

  freevec(pop)
  freevec(val)
  RESULTIS 0
}

AND rand() = randno(100000) NEQV randno(10000)<<20

AND sort(l, r) BE
{ WHILE l+8<r DO
  { LET midpt = (l+r)/2
    // Select a good(ish) median value.
    LET med = middle(val!l, val!midpt, val!r)
    LET i = partition(med, l, r)
//writef("l=%i4  r=%i4  med=%i6  i=%i4*n",
//        l,     r,     med,     i)
//abort(1001)
    // Only use recursion on the smaller partition.
    TEST i>midpt THEN { sort(i, r);   r := i-1 }
                 ELSE { sort(l, i-1); l := i   }
  }

  FOR p = l+1 TO r DO  // Now perform insertion sort.
  { LET w, x = pop!p, val!p
    FOR q = p TO l+1 BY -1 DO
    { LET y = val!(q-1)
      IF y>=x DO
      { pop!q, val!q := w, x
        BREAK
      }
      pop!q, val!q := pop!(q-1), y
    }
  }
//  sorted(l+1, r)
}

AND middle(a, b, c) = a<b -> b<c ->        b,
                                    a<c -> c,
                                           a,
                             b<c -> a<c -> a,
                                           c,
                                           b

AND partition(median, p, q) = VALOF
{ LET t = ?
  WHILE val!p > median DO p := p+1
  WHILE val!q < median DO q := q-1

  IF p>=q RESULTIS p

  t  := pop!p; pop!p := pop!q; pop!q := t
  t  := val!p; val!p := val!q; val!q := t
  p, q := p+1, q-1
} REPEAT

AND sorted(p, q) BE FOR i = p TO q-1 UNLESS val!p>=val!(p+1) DO abort(9999)
