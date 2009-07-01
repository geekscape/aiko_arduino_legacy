#ifndef Interrupt_H
#define Interrupt_H

#include <stdint.h>

#define ISR(name) void interrupt_handler_##name(void)

extern uint8_t SREG;   // AVR Status Register
#define cli()

extern uint8_t TCCR1A; // Timer/Counter1 Control Register A
#define WGM10 0        // Waveform Generation Mode bit 0
#define WGM11 1        // Waveform Generation Mode bit 1

extern uint8_t TCCR1B; // Timer/Counter1 Control Register B
#define WGM12 3        // Waveform Generation Mode bit 1

extern uint8_t TIMSK1; // Timer/Counter Interrupt Mask Register
#define TOIE1 0        // Timer/Counter0 Overflow Interrupt Enable

extern uint8_t TIFR1;  // Timer/Counter1 Interrupt Flag Register
#define TOV1 0         // Timer/Counter1, Overflow Flag

extern uint16_t TCNT1; // Timer/Counter1


#endif

