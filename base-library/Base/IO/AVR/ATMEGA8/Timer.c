#include<avr/io.h>
#include <avr/interrupt.h>

static unsigned int elapsed_time_counter = 0;

ISR(TIMER0_OVF_vect)
{
  elapsed_time_counter++;
}

void initialize() {
  cli();
  TIMSK = 0b00000001;
  //TCCR0 = 0b00000011;
  TCCR0 = 0b00000010;
  sei();
}

int elapsed_time() {
  static int initial = 1;
  int res;
  if (initial) {
    initialize();
    initial = 0;
  }
  res = elapsed_time_counter * 2;
  elapsed_time_counter = 0;
  return res;
}
