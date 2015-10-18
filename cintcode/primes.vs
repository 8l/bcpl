static count, isprime[1000]

let start() = valof
{ for i = 2 to 999 do isprime[i] := true;  // Until proved otherwise.
  count := 0;
  for p = 2 to 999 do if isprime[p] do
  { let i = p*p;
    while i<=999 do { isprime[i] := false; i := i+p };
    out(p)
  };
  resultis 0
}
 
let out(n) be
{ if count mod 10 = 0 do printf("\n");
  printf(" %3d", n);
  count := count+1
}
