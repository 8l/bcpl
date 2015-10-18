#include <stdio.h>
#include <math.h>

unsigned long seed = 12345ul;
double q[11];
double ln2;
int h1[1000], h2[1000];

double rndno() {
//  if(seed&1) seed = seed>>1 ^ 0x7BB88888;
//  else       seed = seed>>1;
  seed = 2147001325ul * seed + 715136305ul;
  return ((double)seed)/0xfffffffful;
}

double negexp1() {
  return -log(rndno());
}

double negexp() { // Exponential distribution mean 1.0
  double u = rndno();
  double v,w;
  int j = 0;
  int k;
  while(1) {
    u = 2 * u;
    if(u<1) break;
    u -= 1;
    j++;
  }
  if(u<ln2) return j * ln2 + u;

  v = rndno();
  for(k=2; k<11; k++) {
    double w = rndno();
    if(v>=w) v = w;
    if(u<q[k]) break;
  }
  return (j+v)*ln2;  
}

int main() {
  int k;
  double tk = 1.0l;
  double qk = 0.0l;
  ln2 = log(2.0l);

  for(k=1; k<11; k++) { // Initialise the q[k] values
    tk = (tk*ln2)/k;
    qk = qk + tk;
    q[k] = qk;
    printf("q[%2d] = %15.9lf %8x\n",
            k, qk, (unsigned long)(qk*0x7FFFFFFFul));
  }

  for(k=0; k<1000; k++) h1[k]=h2[k]=0;

  { double sum = 0;
    int count=100000;
    int i;
    for(i=1; i<5; i++) {
      sum = 0;
      for(k=1; k<=count; k++) sum += negexp();
      printf("Average delay: %13.6f\n", sum/count);
    }
    for(i=1; i<5; i++) {
      sum = 0;
      for(k=1; k<=count; k++) sum += negexp1();
      printf("Average delay: %13.6f\n", sum/count);
    }
  }

  for(k=1; k<1000000; k++){
    int p1 = floor(negexp()*100);
    int p2 = floor(negexp1()*100);
    if(p1>999) p1=999;
    if(p2>999) p2=999;
    h1[p1]++;
    h2[p2]++;
  }

  for(k=0; k<1000; k++) {
    if(k%5 == 0) printf("\n%4d: ", k);
    printf("   %5d %5d", h1[k], h2[k]);
  }
  printf("\n");

  for(k=1; k<=200; k++) {
    printf(" %12.6f", negexp());
    if(k%5==0) printf("\n");
  }

  return 0;
}

