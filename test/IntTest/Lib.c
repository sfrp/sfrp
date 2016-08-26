#include "Lib.h"
#include <stdio.h>
#include <stdlib.h>

int add(int x, int y) {
  return x + y;
}

int mul(int x, int y) {
  return x * y;
}

int getInt() {
  int x;
  if (scanf("%d", &x) == EOF) {
    exit(0);
  }
  return x;
}

int putInt(int x) {
  printf("%d\n", x);
  return 0;
}
