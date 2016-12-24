#include <avr/io.h>

int debouncing(unsigned char count[], int pin_val, int num) {
  if (pin_val) {
    switch (count[num]) {
    case 2:
      count[num] = 1;
      return 1;
    case 1:
      break;
    case 0:
      count[num] = 10;
      break;
    default:
      count[num]--;
    }
  } else {
    count[num] = 0;
  }
  return 0;
}


// PB

int pinB(int num) {
  DDRB &= ~(1 << num);
  return (PINB & (1 << num)) == 0 ? 0 : 1;
}

int posEdgePB(int num) {
  static unsigned char count[8];
  return debouncing(count, pinB(num), num);
}

int portB(int port_num, int high_or_low) {
  high_or_low = (high_or_low == 0 ? 0 : 1);
  DDRB |= 1 << port_num;
  PORTB = (~(1 << port_num) & PORTB) | (high_or_low << port_num);
  return 0;
}

int portBs(int output) {
  DDRB = 0b11111111;
  PORTB = output;
  return 0;
}

// PC

int pinC(int num) {
  DDRC &= ~(1 << num);
  return (PINC & (1 << num)) == 0 ? 0 : 1;
}

int posEdgePC(int num) {
  static unsigned char count[8];
  return debouncing(count, pinC(num), num);
}

int portC(int port_num, int high_or_low) {
  high_or_low = (high_or_low == 0 ? 0 : 1);
  DDRC |= 1 << port_num;
  PORTC = (~(1 << port_num) & PORTC) | (high_or_low << port_num);
  return 0;
}

int portCs(int output) {
  DDRC = 0b11111111;
  PORTC = output;
  return 0;
}

// PD

int pinD(int num) {
  DDRD &= ~(1 << num);
  return (PIND & (1 << num)) == 0 ? 0 : 1;
}

int posEdgePD(int num) {
  static unsigned char count[8];
  return debouncing(count, pinD(num), num);
}

int portD(int port_num, int high_or_low) {
  high_or_low = (high_or_low == 0 ? 0 : 1);
  DDRD |= 1 << port_num;
  PORTD = (~(1 << port_num) & PORTD) | (high_or_low << port_num);
  return 0;
}

int portDs(int output) {
  DDRD = 0b11111111;
  PORTD = output;
  return 0;
}
