#include <stdio.h>

int f(int a, int b, int c) {
  return a+b+c;
}

int main() {
  int res = f(111,222,333);

  unsigned int a, b;
  a = res;
  b = a+1;

  if(a<=b) res = 1;
  if(a<b) res = 1;
  if(a>=b) res = 1;
  if(a>b) res = 1;

  if(a<=10) res = 1;
  if(a<10) res = 1;
  if(a>=10) res = 1;
  if(a>10) res = 1;
  return 0;
}
