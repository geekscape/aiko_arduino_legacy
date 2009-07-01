#ifndef Wiring_H
#define Wiring_H

#include <stdint.h>

#define F_CPU 16000000L
#define _BV(bit) (1 << (bit))
#define bitSet(value, bit) ((value) |= (1UL << (bit)))
#define bitClear(value, bit) ((value) &= ~(1UL << (bit)))

#endif
