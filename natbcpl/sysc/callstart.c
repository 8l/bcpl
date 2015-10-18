int f(int n) {
  if(n<=1) return 1;
  return f(n-1) + f(n-2);
}

int callstart(int *g, int *p, int n) {
  int res = 100;
  if (n>0) res = f(*g);
  return res;
}
