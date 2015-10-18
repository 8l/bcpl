GET "libhdr"

// Safe version
LET fib1(n) = VALOF
{ LET a, b = 0, 1 
  FOR i = 1 TO n DO { LET c = a+b
                      a := b
                      b := c
                    }
  RESULTIS a
}

LET fib2(n) = VALOF
{ LET a, b = 0, 1

  WHILE n>9 DO { LET c, d = 34*a+55*b, 55*a+89*b
                 a, b, n := c, d, n-10
               }
  WHILE n>0 DO { LET c, d = b, a+b
                 a, b, n := c, d, n-1
               }
  RESULTIS a
}

LET fib3(n) = VALOF
{ LET a, b = 0, 1

  WHILE n>9 DO { LET c, d = 34*a+55*b, 55*a+89*b
                 a, b, n := c, d, n-10
               }
  
  SWITCHON n INTO
  { DEFAULT: writef("n was negative*n")
             RESULTIS 0

    CASE 9: RESULTIS 21*a + 34*b
    CASE 8: RESULTIS 13*a + 21*b
    CASE 7: RESULTIS  8*a + 13*b
    CASE 6: RESULTIS  5*a +  8*b
    CASE 5: RESULTIS  3*a +  5*b
    CASE 4: RESULTIS  2*a +  3*b
    CASE 3: RESULTIS    a +  2*b
    CASE 2: RESULTIS    a +    b
    CASE 1: RESULTIS           b
    CASE 0: RESULTIS    a
  }
}

// Since there are only 46 possible 32-bit answers let's make a table of them.
AND fib4(n) = n ! TABLE
          0,         1,         1,         2,         3,
          5,         8,        13,        21,        34,
         55,        89,       144,       233,       377,
        610,       987,      1597,      2584,      4181,
       6765,     10946,     17711,     28657,     46368,
      75025,    121393,    196418,    317811,    514229,
     832040,   1346269,   2178309,   3524578,   5702887,
    9227465,  14930352,  24157817,  39088169,  63245986,
  102334155, 165580141, 267914296, 433494437, 701408733,
 1134903170



LET start() = VALOF
{ FOR i = 0 TO 45 DO
  { IF i MOD 5 = 0 DO newline()
    writef(" %3i:%10i", i, fib4(i))
  }
  newline()

  writef("*nInstruction counts*n*n")
  writef(" n      answer        fib1       fib2       fib3       fib4*n*n")

  FOR i = 0 TO 45 DO
  { writef("%i2: %10i ", i, fib1(i))
    writef(" %10i", instrcount(fib1, i))
    writef(" %10i", instrcount(fib2, i))
    writef(" %10i", instrcount(fib3, i))
    writef(" %10i", instrcount(fib4, i))
    newline()
  }
  RESULTIS 0
}
/*

Typical run:

0> c b fib
bcpl fib.b to fib hdrs BCPLHDRS 

BCPL (27 Jul 2006)
Code size =   808 bytes
0>    
0> 
0> fib

   0:         0   1:         1   2:         1   3:         2   4:         3
   5:         5   6:         8   7:        13   8:        21   9:        34
  10:        55  11:        89  12:       144  13:       233  14:       377
  15:       610  16:       987  17:      1597  18:      2584  19:      4181
  20:      6765  21:     10946  22:     17711  23:     28657  24:     46368
  25:     75025  26:    121393  27:    196418  28:    317811  29:    514229
  30:    832040  31:   1346269  32:   2178309  33:   3524578  34:   5702887
  35:   9227465  36:  14930352  37:  24157817  38:  39088169  39:  63245986
  40: 102334155  41: 165580141  42: 267914296  43: 433494437  44: 701408733
  45:1134903170

Instruction counts

 n      answer        fib1       fib2       fib3       fib4

 0:          0          10         11         12          3
 1:          1          22         23         12          3
 2:          1          34         35         13          3
 3:          2          46         47         15          3
 4:          3          58         59         19          3
 5:          5          70         71         19          3
 6:          8          82         83         19          3
 7:         13          94         95         19          3
 8:         21         106        107         19          3
 9:         34         118        119         19          3
10:         55         130         38         39          3
11:         89         142         50         39          3
12:        144         154         62         40          3
13:        233         166         74         42          3
14:        377         178         86         46          3
15:        610         190         98         46          3
16:        987         202        110         46          3
17:       1597         214        122         46          3
18:       2584         226        134         46          3
19:       4181         238        146         46          3
20:       6765         250         65         66          3
21:      10946         262         77         66          3
22:      17711         274         89         67          3
23:      28657         286        101         69          3
24:      46368         298        113         73          3
25:      75025         310        125         73          3
26:     121393         322        137         73          3
27:     196418         334        149         73          3
28:     317811         346        161         73          3
29:     514229         358        173         73          3
30:     832040         370         92         93          3
31:    1346269         382        104         93          3
32:    2178309         394        116         94          3
33:    3524578         406        128         96          3
34:    5702887         418        140        100          3
35:    9227465         430        152        100          3
36:   14930352         442        164        100          3
37:   24157817         454        176        100          3
38:   39088169         466        188        100          3
39:   63245986         478        200        100          3
40:  102334155         490        119        120          3
41:  165580141         502        131        120          3
42:  267914296         514        143        121          3
43:  433494437         526        155        123          3
44:  701408733         538        167        127          3
45: 1134903170         550        179        127          3
10> 

*/
