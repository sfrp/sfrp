#include <stdio.h>
#include <stdlib.h>

int get_int() {
  int x;
  if (scanf("%d", &x) == EOF) {
    exit(0);
  }
  return x;
}

int put_int(int x) {
  printf("%d\n", x);
  return 0;
}

float get_float() {
  float x;
  if (scanf("%f", &x) == EOF) {
    exit(0);
  }
  return x;
}

int put_float(float x) {
  printf("%f\n", x);
  return 0;
}

int get_int_pair(int* a, int* b) {
  if (scanf("%d %d", a, b) == EOF) {
    exit(0);
  }
  return 0;
}

int put_int_pair(int a, int b) {
  printf("(%d, %d)\n", a, b);
  return 0;
}
