/*
** numtype.h -- include file declares the data types for the book:
**              Programmer's Field Guide to Number Theory
**              by Mark A. Herkommer, 1998
*/
#ifndef NUMTYPE_H
#define NUMTYPE_H

#include <ctype.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef _MSC_VER
#include <conio.h>
#include <malloc.h>
#include <memory.h>
#if _MSC_VER <= 800
#include <graph.h>
#endif
#endif

/* typedefs and data structures */

typedef long int                INT;
typedef unsigned long int       NAT;

typedef struct fraction_ {
  NAT w, n, d;          /* whole, numerator, denominator */
} FRACTION;

typedef struct zint_ {
  INT re, im;           /* real, imaginary */
} ZINT;

typedef struct {
  INT x, y;             /* lattice point: x, y */
} LPOINT;

/* prototypes */

int cfSquareRoot(INT, INT[], INT);
int LegendreSymbol(NAT, NAT);
int SearchArray(NAT, NAT[], NAT);
int SeiveOverFactorBase(INT, INT[], char[], NAT);
int SolveLinearDioEq(INT, INT, INT, INT*, INT*);

INT ECAddPointsMod(LPOINT*, LPOINT*, LPOINT*, INT, INT, INT);
INT iCubeRoot(INT, INT*, INT*);
INT Mobius(NAT);
INT SolveExponentialCongruence(INT, INT, INT);
INT SolveLinearCongruence(INT, INT, INT);
INT SolveLinearCongruenceN(INT[], INT[], INT, INT, INT, INT);
INT SolveQuadraticCongruence(INT, INT, INT, INT, INT*, INT*);

NAT BuildFactorBase(INT, INT[], NAT);
NAT ComputeInverse(NAT, NAT);
NAT EulerCriterion(NAT, NAT);
NAT EulerTotient(NAT);
NAT Factor(NAT, NAT[]);
NAT FractionCalc(char, FRACTION*, FRACTION*, FRACTION*);
NAT GCD(NAT, NAT), LRA(NAT, NAT), RSBGCD(NAT, NAT), LSBGCD(NAT, NAT);
NAT IndMod(NAT, NAT, NAT);
NAT IPOW(NAT, NAT);
NAT iSquareRoot(NAT, NAT*, NAT*);
NAT LCM(NAT, NAT);
NAT Li(NAT);
NAT MulMod(NAT, NAT, NAT);
NAT PositiveDivisors(NAT);
NAT PowMod(NAT, NAT, NAT);
NAT PrimitiveRoot(NAT);
NAT QuadraticResidue(NAT, NAT);
NAT SumDigits(NAT);
NAT SumDivisors(NAT);

void ConvertHexFraction(double, int, char*);

/* macros */

#define ABS(a)   ((a) < 0 ? -(a) : (a))
#define MIN(a,b) ((a) < (b) ? (a) : (b))
#define MAX(a,b) ((a) > (b) ? (a) : (b))
#define OK 0
#define ER 1

#endif

