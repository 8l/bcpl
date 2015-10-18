#include <stdio.h>

extern void f(int a, int b);

void f1(float a, float b) {
  int c;
  float d = a + b;
  c = a==b; f(c, 11);
  //printf("%10.4f == %10.4f  result %d\n",   a, b, c);
  c = a!=b; f(c, 22);
  //printf("%10.4f != %10.4f  result %d\n",   a, b, c);
  c = a<=b; f(c, 33);
  //printf("%10.4f <= %10.4f  result %d\n",   a, b, c);
  c = a>=b; f(c, 44);
  //printf("%10.4f >= %10.4f  result %d\n",   a, b, c);
  c = a<b; f(c, 55);
  //printf("%10.4f <  %10.4f  result %d\n",   a, b, c);
  c = a>b; f(c, 66);
  //printf("%10.4f >  %10.4f  result %d\n\n", a, b, c);
  return;
}

int main() {
  f1(7.0, 6.0);
  f1(6.0, 7.0);
  f1(7.0, 7.0);
  f1(7.0, -7.0);
  f1(-7.0, 7.0);
  f1(-7.0, -7.0);
  return 0;
}
