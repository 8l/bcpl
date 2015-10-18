#include <stdio.h>
 
int count;
int all;

void try(int ld, int row, int rd) {
  if (row==all) {
    count++;
  } else {
    int poss = all & (~(ld | row | rd));
    while(poss) {
      int p = poss & (-poss);
      poss -= p;
      try((ld+p) << 1, (row+p), (rd+p) >> 1);
    }
  }
}

int main() {
  int i;
  all = 1;
  
  for (i=1; i<=16; i++) {
    count = 0;
    try(0, 0, 0);
    printf("Number of solutions to %2d-queens is %9d\n", i, count);
    all = 2*all + 1;
  }

  return 0;
}
