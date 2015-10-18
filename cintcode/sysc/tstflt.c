#include <stdio.h>

typedef union fi {
  float f;
  int i;
} FI;


int f(int x, int y) {
  FI xfi, yfi;
  xfi.i = x;
  yfi.i = y;
  xfi.f = xfi.f + yfi.f * xfi.f / 1.5;
  return xfi.i;
}

