/*
** Program 10_7_1 - evaluate the nth hexadecimal digit of pi
** from Number Theory, A Programmer's Guide by Mark Herkommer

** Slightly modified by Martin Richards to aid the debugging
** of a BCPL version
*/
#include "numtype.h"
#include <math.h>

#define EPSILON 1e-16

void main(int argc, char *argv[])
{
  INT    i, n;
  double s, t;
  char   str[8];

  //  if (argc == 2) {
  //  n = atol(argv[1]);
  //} else {
  //  printf("Evaluate the nth hexadecimal digit of pi\n\n");
  //  printf("n = ");
  //  scanf("%lu", &n);
  //}

  printf("\n       3.");
  for(i=0; i<=1000; i++) {
    if(i%50==0) printf("\n%5d: ", (int)i);
    printf("%1X", pihexdig(i));
  }
  printf("\n");
}

int pihexdig(INT n) {
/* compute the digits up to n */
  INT    i;
  double s, t;
  char   str[8];


  for (i = 0, s = 0; i < n; i++)
  { double a = 4.0 * (double) PowMod(16L, n - i, (8*i + 1)) / (8*i + 1);
    double b = 2.0 * (double) PowMod(16L, n - i, (8*i + 4)) / (8*i + 4);
    double c =       (double) PowMod(16L, n - i, (8*i + 5)) / (8*i + 5);
    double d =       (double) PowMod(16L, n - i, (8*i + 6)) / (8*i + 6); 

    s += a - b - c - d;
    //printf("a=%19.15f ", a);
    //printf("b=%19.15f ", b);
    //printf("c=%19.15f ", c);
    //printf("d=%19.15f ", d);
    //printf("s=%19.15f\n", s);

    //s += 4.0 * (double) PowMod(16L, n - i, (8*i + 1)) / (8*i + 1) - 
    //     2.0 * (double) PowMod(16L, n - i, (8*i + 4)) / (8*i + 4) - 
    //           (double) PowMod(16L, n - i, (8*i + 5)) / (8*i + 5) - 
    //           (double) PowMod(16L, n - i, (8*i + 6)) / (8*i + 6); 
    //printf("i=%4d: %19.15f\n", (int)i, s);
  }
  //printf("s=%19.15f\n", s);

/* compute additional terms until they are too tiny to matter */

  for (t = 1.0; t > EPSILON; i++, t /= 16.0) 
  { double a = 4.0 * t / (8*i + 1);
    double b = 2.0 * t / (8*i + 4);
    double c =       t / (8*i + 5);
    double d =       t / (8*i + 6);

    s += a - b - c - d;
    //printf("a=%19.15f ", a);
    //printf("b=%19.15f ", b);
    //printf("c=%19.15f ", c);
    //printf("d=%19.15f ", d);
    //printf("s=%19.15f\n", s);

    //s += 4.0 * t / (8*i + 1) - 
    //     2.0 * t / (8*i + 4) - 
    //           t / (8*i + 5) - 
    //           t / (8*i + 6);

    //printf("i=%4d: %19.15f\n", (int)i, s);
  }

  //  printf("s=%19.15f  => %19.15f\n", s, s - floor(s));

  return (s - floor(s)) * 16;

/* print the result */

//  ConvertHexFraction(s, sizeof(str), str);
//  printf("[%ld] (%lf) = 3.%s%8.8s\n", n, s, (n ? " ... " : ""), str);
}

/*
** Convert the decimal fraction of a double to hexadecimal fraction
*/

void ConvertHexFraction(double n, int nc, char str[])
{
  char hex[] = "0123456789abcdef";
  int  i;

  for (i = 0; i < nc; i++)
  {
    n = (n - floor(n)) * 16;
    str[i] = hex[(int) n];
  }
}

/*
** PowMod - computes r for aü ð r (mod m) given a, n, and m
*/
#include "numtype.h"

NAT PowMod(NAT a, NAT n, NAT m)
{
  NAT r;

  r = 1;
  while (n > 0)
  {
    if (n & 1)                          /* test lowest bit */
      r = MulMod(r, a, m);              /* multiply (mod m) */
    a = MulMod(a, a, m);                /* square */
    n >>= 1;                            /* divided by 2 */
  }

  return(r);
}

/*
** MulMod - computes r for a * b ð r (mod m) given a, b, and m
*/
#include "numtype.h"

NAT MulMod(NAT a, NAT b, NAT m)
{
  NAT r;

  if (m == 0) return(a * b);            /* (mod 0) */

  r = 0;
  while (a > 0)
  {
    if (a & 1)                          /* test lowest bit */
      if ((r += b) > m) r %= m;         /* add (mod m) */
    a >>= 1;                            /* divided by 2 */
    if ((b <<= 1) > m) b %= m;          /* times 2 (mod m) */
  }

  return(r);
}
