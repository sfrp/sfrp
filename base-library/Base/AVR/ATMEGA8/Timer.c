#include<avr/io.h>
#include <avr/interrupt.h>

static unsigned int elapsed_clock_div256 = 0;

ISR(TIMER0_OVF_vect)
{
  elapsed_clock_div256++;
}

void initialize_timer() {
  static int flag = 0;
  if (flag) return;
  cli();
  TIMSK = 0b00000001;
  TCCR0 = 0b00000001; // No prescaling
  sei();
  flag = 1;
}

int get_dsec(clk_io_kilohertz) {
  static unsigned int last = 0;
  unsigned int current;
  unsigned int dsec;
  initialize_timer();

  current = elapsed_clock_div256;
  dsec = (current - last) / (clk_io_kilohertz * 4); // clk_io_kilohertz * 1024 / 256
  last = current - (current - last) % (clk_io_kilohertz * 4);
  return dsec;
}

// Param clk_io_kilohertz should be a even number.
int get_dmsec(clk_io_kilohertz) {
  static unsigned int last = 0;
  unsigned int current;
  unsigned int dmsec;
  initialize_timer();

  current = elapsed_clock_div256;
  dmsec = (current - last) / (clk_io_kilohertz / 2); // clk_io_kilohertz * 1024 / 256 / 8
  last = current - (current - last) % (clk_io_kilohertz / 2);
  return dmsec * 125;
}

// This function assumes 0.97656(=1000/1024)msec as 1msec
// so accumulates about 2% numerical error.
// Argument which is not multiple of 256 also causes numerical error.
int get_uncertain_dmsec(clk_io_kilohertz) {
  static unsigned int last = 0;
  unsigned int current;
  unsigned int dmsec;
  initialize_timer();

  current = elapsed_clock_div256;
  dmsec = (current - last) / (clk_io_kilohertz / 256); // clk_io_kilohertz * 1024 / 256 / 1024
  last = current - (current - last) % (clk_io_kilohertz / 256);
  return dmsec;
}
