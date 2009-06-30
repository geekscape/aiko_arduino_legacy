#include "AikoTiming.h"
#include <avr/interrupt.h>
#include <wiring.h>

namespace Aiko {

  union TimerCounter {
    struct {
      unsigned int interval_count_lo, interval_count_hi;
      unsigned char overflow_countdown;
    };
    unsigned long interval_count;
  };

  volatile union TimerCounter timer1_counter;

  ISR(TIMER1_OVF_vect) {
    if (--timer1_counter.overflow_countdown == 0) {
      timer1_counter.overflow_countdown = 250;
      if (++timer1_counter.interval_count_lo == 0)
        ++timer1_counter.interval_count_hi == 0;
    }
  }

  void Timing::setup(void) {
    timer1_counter.interval_count = 0;
    timer1_counter.overflow_countdown = 250;    

    bitSet  (TCCR1B, WGM12); // Put timer 1 in Fast PWM, 8-bit mode
    bitClear(TCCR1A, WGM11);
    bitSet  (TCCR1A, WGM10);
   
    bitSet  (TIMSK1, TOIE1); // Enable timer 1 overflow interrupts
  }

  unsigned long Timing::millis(void) {
    TimerCounter counter;

    uint8_t oldSREG = SREG;
    cli();
    unsigned int extra_ticks   = TCNT1;
    if ((TIFR1 & _BV(TOV1)) && extra_ticks == 0) extra_ticks = 256; // The timer has overflowed, but the interrupt hasn't fired yet.
    counter.overflow_countdown = timer1_counter.overflow_countdown;
    counter.interval_count     = timer1_counter.interval_count;
    SREG = oldSREG;
    
    extra_ticks += (unsigned int)(250 - counter.overflow_countdown) << 8; // Add TCNT1 for more accuracy.
    unsigned int extra_millis = extra_ticks/250;
    
    return (counter.interval_count << 8) + extra_millis;
  }

};

