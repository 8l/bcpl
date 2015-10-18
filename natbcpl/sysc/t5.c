#include <stdio.h>

typedef union fi {
  int i;
  float f;
} FI;

int releq(float x, float y) {
  return x==y;
    }

int relne(float x, float y) {
  return x==y;
    }

int rells(float x, float y) {
  return x==y;
    }

int relgr(float x, float y) {
  return x==y;
    }

int relle(float x, float y) {
  return x==y;
    }

int relge(float x, float y) {
  return x==y;
    }


int releq0(float x) {
  return x==0.0;
    }

int relne0(float x) {
  return x==0.0;
    }

int rells0(float x) {
  return x==0.0;
    }

int relgr0(float x) {
  return x==0.0;
    }

int relle0(float x) {
  return x==0.0;
    }

int relge0(float x) {
  return x==0.0;
    }


int main() {
  int a;
  int b;
  int c;
  a = 3;
  b = 33;
  c = (float) a < 0.0;

  return 0;
}
