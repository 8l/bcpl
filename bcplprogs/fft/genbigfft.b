// ################### UNDER DEVELOPMENT ###########################
// This program is intended to generate an evaluation DAG to
// compute the FFT of some values. As with bigfft.b it uses modular
// arithmetic. Each arithmetic operation generates an evaluation node
// rather than actually performing the operation.

/*
The node tyoes are:

[Data, id, val, succlist]       Original data
[Add, id, x, y, val, succlist]  Wait for two values then send the sum
                                to every successor, if val changed
[Sub, id, x, y, val, succlist]  Wait for two values then send the difference
                                to every successor, if val changed
[Mulk, id, x, val, k, succlist] Wait for a value then multiply it by k
                                and send to every successor, if value changed
[Divk, id, x, val, k, succlist] Wait for a value then divide it by k
                                and send to every successor, if val changed
[Res, id, x, val]               A result node

x and y are the ids of the source operands.
*/

GET "libhdr"

MANIFEST {
modulus = #x10001  // 2**16 + 1

$$ln3   // Set condition compilation flag to select data size
//$$walsh

$<ln16 omega = #x00003; ln = 16 $>ln16  // omega**(2**16) = 1
$<ln12 omega = #x0ADF3; ln = 12 $>ln12  // omega**(2**12) = 1
$<ln10 omega = #x096ED; ln = 10 $>ln10  // omega**(2**10) = 1
$<ln4  omega = #x08000; ln = 4  $>ln4   // omega**(2**4)  = 1
$<ln3  omega = #x0FFF1; ln = 3  $>ln3   // omega**(2**3)  = 1

$<walsh    omega=1           $>walsh    // The Walsh transform (permuted)

N       = 1<<ln    // N is a power of 2
upb     = N-1
prupb   = upb      // Upper bound for printing
//prupb   = 31       // Upper bound for printing

Data = 1; Add; Sub; Mulk; Divk; Res // Node types
h1=0; h2; h3; h4; h5; h6            // Selectors
}

GLOBAL {
idv:ug       // Id vector
dagv         // Vector of DAG nodes
             // dagv!id points to the node with that id.
nodeid       // id of last node created
spacev
spacep
spacet
}

LET start() = VALOF
{  writef("fft with N = %n and omega = %n modulus = %n*n*n",
                    N,         omega,     modulus)

   idv, dagv, spacev := 0, 0, 0
   idv  := getvec(upb)
   dagv := getvec(upb*ln+400)
   spacev := getvec(upb*ln*50)
   spacep := spacev
   spacet := spacev + upb*ln*50
   nodeid := 0

   UNLESS omega=1 DO   // Unless doing Walsh tranform
     check(omega, N)   //   check that omega and N are consistent

   FOR i = 0 TO upb DO idv!i := mkdata()

   fft(idv, ln, omega)

   fft(idv, ln, ovr(1,omega))
   FOR i = 0 TO upb DO idv!i := mkdivk(idv!i, N)
   FOR i = 0 TO upb DO idv!i := mkres(idv!i)
   mklists()
   prnodes()

fin:
   IF idv DO freevec(idv)
   IF dagv DO freevec(dagv)
   IF spacev DO freevec(spacev)
   RESULTIS 0
}

AND fft(v, ln, w) BE  // ln = log2 n    w = nth root of unity
{ LET n = 1<<ln
  LET vn = v+n
  LET n2 = n>>1

  // First do the perfect shuffle
  reorder(v, n)

  // Then do all the butterfly operations
  FOR s = 1 TO ln DO
  { LET m = 1<<s
    LET m2 = m>>1
    LET wk, wkfac = 1, w
    FOR i = s+1 TO ln DO wkfac := mul(wkfac, wkfac)
    FOR j = 0 TO m2-1 DO
    { LET p = v+j
      WHILE p<vn DO { butterfly(p, p+m2, wk); p := p+m }
      wk := mul(wk, wkfac)
    }
  }
}

AND butterfly(p, q, wk) BE { LET a, b = !p, mkmulk(!q, wk)
                             !p, !q := mkadd(a, b), mksub(a, b)
                           }

AND reorder(v, n) BE
{ LET j = 0
  FOR i = 0 TO n-2 DO
  { LET k = n>>1
    // j is i with its bits is reverse order
    IF i<j DO { LET t = v!j; v!j := v!i; v!i := t }
    // k  =  100..00       10..0000..00
    // j  =  0xx..xx       11..10xx..xx
    // j' =  1xx..xx       00..01xx..xx
    // k' =  100..00       00..0100..00
    WHILE k<=j DO { j := j-k; k := k>>1 } //) "increment" j
    j := j+k                              //)
  }
}

AND check(w, n) BE
{ // Check that w is a principal nth root of unity
  LET x = 1
  FOR i = 1 TO n-1 DO { x := mul(x, w)
                        IF x=1 DO writef("omega****%n = 1*n", i)
                      }
  UNLESS mul(x, w)=1 DO writef("Bad omega**%n should be  1*n", n)
}

// Node allocation package

AND push(a) BE
{ IF spacep>spacet DO
  { writef("Make spacev larger*n")
    abort(999)
    spacep := spacev
  }
  !spacep := a
  //writef("%i6: %i5*n", spacep, a)
  spacep := spacep+1
}

// [Data, id, succlist, val]       Original data
AND mkdata() = VALOF
{ nodeid := nodeid+1
  dagv!nodeid := spacep
  push(Data)
  push(nodeid)
  push(0)
  push(0)
  //sawritef("%i4: Data %i5 %i5*n", nodeid, 0, 0)
  RESULTIS nodeid
}


//[Add, id, x, y, val, succlist]  Wait for two values then send the sum
//                                to every successor, if val changed
AND mkadd(x, y) = VALOF
{ nodeid := nodeid+1
  dagv!nodeid := spacep
  push(Add)
  push(nodeid)
  push(x)
  push(y)
  push(0)
  push(0)
  //sawritef("%i4: Add  %i5 %i5 %i5 %i5*n", nodeid, x, y, 0, 0)
  RESULTIS nodeid
}

//[Sub, id, succlist, x, y, val]  Wait for two values then send the difference
//                                to every successor, if val changed
AND mksub(x, y) = VALOF
{ nodeid := nodeid+1
  dagv!nodeid := spacep
  push(Sub)
  push(nodeid)
  push(0)
  push(x)
  push(y)
  push(0)
  //sawritef("%i4: Sub  %i5 %i5 %i5 %i5*n", nodeid, x, y, 0, 0)
  RESULTIS nodeid
}

//[Mulk, id, succlist, x, val, k] Wait for a value then multiply it by k
//                                and send to every successor, if value changed
AND mkmulk(x, k) = VALOF
{ nodeid := nodeid+1
  dagv!nodeid := spacep
  push(Mulk)
  push(nodeid)
  push(0)
  push(x)
  push(k)
  push(0)
  //sawritef("%i4: Mulk %i5 %i5 %i5 %i5*n", nodeid, x, k, 0, 0)
  RESULTIS nodeid
}

//[Divk, id, succlist, x, val, k] Wait for a value then divide it by k
//                                and send to every successor, if val changed
AND mkdivk(x, k) = VALOF
{ nodeid := nodeid+1
  dagv!nodeid := spacep
  push(Divk)
  push(nodeid)
  push(0)
  push(x)
  push(k)
  push(0)
  //sawritef("%i4: Divk %i5 %i5 %i5*n", nodeid, x, k, 0, 0)
  RESULTIS nodeid
}

//[Res, id, succlist, x, val]     A result node
AND mkres(x) = VALOF
{ nodeid := nodeid+1
  dagv!nodeid := spacep
  push(Res)
  push(nodeid)
  push(0)
  push(x)
  push(0)
  push(0)
  //sawritef("%i4: Res  %i5 %i5 %i5*n", nodeid, x, 0, 0)
  RESULTIS nodeid
}

//[succ, next]                     A successor node
AND mksucc(succ) = VALOF
{ LET res = spacep
  push(succ)
  push(0)
  RESULTIS res
}

AND mklists() BE
{ FOR id = 1 TO nodeid DO
  { LET node = dagv!id
    SWITCHON node!h1 INTO
    { DEFAULT: writef("mklists: Bad node type %n*n", node!id)
               LOOP

      CASE Data: // [Data, id, succlist, val]
               LOOP
      CASE Add: // [Add, id, suclist, x, y, val]
               //apsucc(h4!node, h2!node)
               //apsucc(h5!node, h2!node)
               LOOP
      CASE Sub: // [Sub, id, succlist,x, y, val]
               LOOP
      CASE Mulk: // [Mulk, id, succlist, x, val, k]
               LOOP
      CASE Divk: // [Divk, id, succlist, x, val, k]
               LOOP
      CASE Res: // [Res, id, succlist, x, val]
               LOOP
    }
  }
}

AND apsucc(id, succ) BE
{ // Append a successor node for succ
  LET p = @h3!(dagv!id)
  WHILE !p DO p := !p
  !p := mksucc(succ)
}

AND  prnodes() BE
{ FOR id = 1 TO nodeid DO
  { LET node = dagv!id
    SWITCHON h1!node INTO
    { DEFAULT: writef("prnodes: Bad node %i5 type %n*n", node, h1!node)
               FOR i = 0 TO 4 DO
                 writef("%i6: %i5*n", node+i, node!i)
               abort(1000)
               LOOP

      CASE Data: // [Data, id, succlist, val]
               writef("%i5: Data ", h2!node)
               prsuccs(h3!node)
               LOOP
      CASE Add: // [Add, id, suclist, x, y, val]
               writef("%i5: Add  %i5 %i5 ", h2!node, h4!node, h5!node)
               prsuccs(h3!node)
               LOOP
      CASE Sub: // [Sub, id, succlist,x, y, val]
               writef("%i5: Sub  %i5 %i5 ", h2!node, h4!node, h5!node)
               prsuccs(h3!node)
               LOOP
      CASE Mulk: // [Mulk, id, succlist, x, val, k]
               writef("%i5: Mulk %i5 %i5 ", h2!node, h4!node, h6!node)
               prsuccs(h3!node)
               LOOP
      CASE Divk: // [Divk, id, succlist, x, val, k]
               writef("%i5: Divk %i5 %i5 ", h2!node, h4!node, h6!node)
               prsuccs(h3!node)
               LOOP
      CASE Res: // [Res, id, succlist, x, val]
               writef("%i5: Res  %i5*n", h2!node, h4!node)
               LOOP
    }
  }
}

AND prsuccs(list) BE
{ writef("[")
  WHILE list DO
  { writef("%n ", h1!list)
    list := h2!list
  }
  writef("]*n")
}

// Modular arithmetic package

AND dv(a, m, b, n) = a=1 -> m,
                     a=0 -> m-n,
                     a<b -> dv(a, m, b REM a, m*(b/a)+n),
                     dv(a REM b, m+n*(a/b), b, n)


AND inv(x) = dv(x, 1, modulus-x, 1)

AND add(x, y) = VALOF
{ LET a = x+y
  IF a<modulus RESULTIS a
  RESULTIS a-modulus
}

AND sub(x, y) = add(x, neg(y))

AND neg(x)    = modulus-x

AND mul(x, y) = x=0 -> 0,
                (x&1)=0 -> mul(x>>1, add(y,y)),
                add(y, mul(x>>1, add(y,y)))

AND ovr(x, y) = mul(x, inv(y))
