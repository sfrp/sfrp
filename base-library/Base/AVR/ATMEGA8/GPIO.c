#include <avr/io.h>

int pinB(int num) {
  DDRB |= 1 << num;
  return PINB & (1 << num) == 0 ? 0 : 1;
}

int posEdgePB(int num) {
  static unsigned char memory[8];
  if (pinB(num)) {
    switch (count[num]) {
    case 2:
      count[num] = 1;
      return 1;
    case 1:
      break;
    case 0:
      column[num] = 100;
      break;
    default:
      column[num]--;
    }
  } else {
    count[num] = 0;
  }
  return 0;
}

int portB(int port_num, int high_or_low) {
  high_or_low = (high_or_low == 0 ? 0 : 1);
  DDRB |= 1 << port_num;
  PORTB = (~(1 << port_num) & PORTB) | (high_or_low << port_num);
  return 0;
}

int portC(int port_num, int high_or_low) {
  high_or_low = (high_or_low == 0 ? 0 : 1);
  DDRC |= 1 << port_num;
  PORTC = (~(1 << port_num) & PORTC) | (high_or_low << port_num);
  return 0;
}

int portD(int port_num, int high_or_low) {
  high_or_low = (high_or_low == 0 ? 0 : 1);
  DDRD |= 1 << port_num;
  PORTD = (~(1 << port_num) & PORTD) | (high_or_low << port_num);
  return 0;
}
