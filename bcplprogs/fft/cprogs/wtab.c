/*
This program is meant to generate a table of (sin x)/4 for x = 0 to pi/2. The
numbers will be given as 32-bit unsigned fixed point fractions in hex.
*/

#include <stdio.h>
#include <math.h>

#define Pi 3.14159265358979323846264338327950l

#define K 10

#define N (1<<K)

int main() {
  int i;

  for (i=0; i<=N; i++) {
    int y = nearbyint(sin((double)Pi*i/(2.0*N)) * 0x40000000);
    if(i%7==0) printf("\n");
    printf("#x%08x,", y);
  }
  printf("\n");
  return 0;
}
