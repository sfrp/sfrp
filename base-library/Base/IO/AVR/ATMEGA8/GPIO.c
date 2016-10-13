#include <avr/io.h>

int portD(int port_num, int high_or_low) {
  high_or_low = (high_or_low == 0 ? 0 : 1);
  DDRD |= 1 << port_num;
  PORTD = (~(1 << port_num) & PORTD) | (high_or_low << port_num);
  return 0;
}
