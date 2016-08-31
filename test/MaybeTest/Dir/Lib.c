#include <stdio.h>
#include <stdlib.h>

int getMaybeIntRaw(int* flag, int* val) {
  if (scanf("%d", val) == EOF) {
    exit(0);
  }
  *flag = *val >= 0;
  return 0;
}

int putInt(int x) {
  printf("%d\n", x);
  return 0;
}
