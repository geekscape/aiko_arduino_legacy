#ifndef Wiring_H
#define Wiring_H

#include <stdint.h>

#define _BV(bit) (1 << (bit))
#define bitSet(value, bit) ((value) |= (1UL << (bit)))
#define bitClear(value, bit) ((value) &= ~(1UL << (bit)))

#endif
