/*
A simple program to generate Fourier transform results
mainly for checking the correctness of FFT algorithms.

Implemented by Martin Richards (c) Jan 2008
*/

#include <stdio.h>
#include <math.h>

#define pi 3.1415926535897932384626433832795

#define K 4

#define N (1<<K)

double rv[N]; // Time domain data
double iv[N];

double rw[N]; // Freq dommain result
double iw[N];


void fft(double *rdata, double *idata, // The time domain data
         double *rres,  double *ires,  // The frequency domain result
         int n) {
  int i, k;

  for(i=0; i<n; i++) { // Initialise the result
    rres[i] = 0.0;
    ires[i] = 0.0;
  }

  for(k=0; k<n; k++) {
    for(i=0; i<n; i++) {
      double rfac =  cos(2 * pi * k * i / n);
      double ifac =  sin(2 * pi * k * i / n);
      rres[k] += rdata[i]*rfac - idata[i]*ifac;
      ires[k] += rdata[i]*ifac + idata[i]*rfac;
    }
    printf("%3d %12.4f %12.4f    => %12.4f %12.4f\n",
           k, rdata[k], idata[k],rres[k], ires[k]);
  }
}

void invfft(double *rdata, double *idata, // The frequency domain
            double *rres,  double *ires,  // The time domain data result
            int n) {
  int i, k;

  for(i=0; i<n; i++) { // Initialise the result
    rres[i] = 0.0;
    ires[i] = 0.0;
  }

  for(k=0; k<n; k++) {
    for(i=0; i<n; i++) {
      double rfac =  cos(2 * pi * k * i / n);
      double ifac = -sin(2 * pi * k * i / n);
      rres[k] += rdata[i]*rfac - idata[i]*ifac;
      ires[k] += rdata[i]*ifac + idata[i]*rfac;
    }
    rres[k] /= n;
    ires[k] /= n;

    printf("%3d %12.4f %12.4f    => %12.4f %12.4f\n",
           k, rdata[k], idata[k], rres[k], ires[k]);
  }
}

int main() {
  int i;
  for(i=0; i<N; i++) {
    rv[i] = i;
    iv[i] = 0;
  }

  fft   (rv, iv, rw, iw, N);

  printf("\n");

  invfft(rw, iw, rv, iv, N);

  return 0;
}
