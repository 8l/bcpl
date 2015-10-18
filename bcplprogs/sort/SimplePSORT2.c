/*   the code sorts the specified sequence into ascending order.     */
/*   The sorting algorithm is the simple version of proportion       */
/*   extend sort. This algorithm offers O(n*log(n) performance,      */
/*   but not robust. For details, see the paper "proportion          */
/*   extend sort",SIAM Journal on Computing, Vol.31,323-330 (2001)   */
/*   Coded by Chen Jingchao.                                         */
/*   Date : 2005/10/12, version 2.0                                  */
/*   Copyright (C) 2003 Jingchao Chen                                */
/*   Any comment is welcome. For any question, email to              */
/*   chen-jc@dhu.edu.cn or chenjingchao@yahoo.com                    */

#include <stdio.h>
//#include <conio.h>
//#include <stdlib.h>
//#include <dos.h>
//#include <time.h>

#define swap(a,b)   {int t = *(a); *(a) = *(b); * (b) = t;}
#define p  16
#define SIZE_n  30000
int  n=SIZE_n, key[SIZE_n];

// compare two integer member
int cmp(const void * a,const void *b)
{
     return *(int *)a - *(int *)b;
}

void check(int * a)
{    int i;
     //printf("[%d]",a[n-1]);
     for (i=0; i< n-1; i++)
     {
         if (a[i]>a[i+1])
         {
               printf( "The array has not been correctly sorted\n");
               //getch();
               return;
         }
     }
}

void psort( int *a, int sorted, int n,int (*cmp)(const void *,const void *));

int main(void)
{
    int  i;

    printf("\n Proportion extend sort n=%d p=%d\n",n,p);

    srand(88);
    for(i=0;i<n;i++) key[i]=rand()%n;   // generate a random integer in [0,32767],
    psort(key,1,n-1,cmp);        // Note: the 2nd parameter is n-1, not n
    check(key);
    for(i=0;i<50;i++) printf("%7d ",key[i]);
    printf("\n");
    //getchar();
    return 0;
}

void psort( int *a, int s, int n,int (*cmp)(const void *,const void *))
{
  int *pi,*pj,*pb,*pc,*pm,n1,s1,s2,s3;
  int ll,rr;

  while (1) {
    if( s <= 0 ) s=1;

    if (n < 7) {
      for (; s <= n; s++){
	for ( pj = a+s; pj > a && cmp(pj-1,pj) > 0; pj--) {
	  swap(pj,pj-1);
	}
      }
      return;
    }
    if( s > n ) return;

    s1=(s-1)/2;
    pm = a+s1;
    s3=((p+1)*p*s) > n ? n : (p+1)*s;
      
    ll=a[s-1];  
    rr=a[s3];
    a[s-1]=a[s3]=*pm; 
    pb=pi=a+s;
    pc=a+s3-1;
    while( pb <= pc ){
      while (cmp(pb, pm) < 0 ) pb++;
      while (cmp(pc, pm) > 0 ) pc--;
      if (pb >= pc) break;
      swap(pb,pc); 
      pc--; pb++;
    }
    if(cmp(&rr, pm) >= 0 ) a[s3]=rr;
    else{
      a[s3]= *pb;
      *pb = rr;
      pb++; 
    }	
    a[s-1]=ll;
    pj=pb;
    do{ pi--;pj--; swap(pi, pj);}
    while(pi > pm); 

    s2=s-s1-1;
    n1= pb-a-s2-2;
    psort(a, s1, n1, cmp);
    psort(pb-s2, s2, s3-n1-2, cmp);
    s=s3+1;
  }
}
