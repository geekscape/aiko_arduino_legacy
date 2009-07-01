#include "AikoTiming.h"
#include <avr/interrupt.h>
#include <wiring.h>

namespace Aiko {

  union TimerCounter {
    unsigned long intervalCount;  // Increments on every 250th overflow interrupt,
                                  // which is every 256ms on a 16MHz processor.
                                  // Will wrap around after ~35 years.
    struct {
      unsigned int intervalCountLo, intervalCountHi;
      unsigned char overflowCountdown;  // Decrements on each overflow interrupt.
    };
  };

  static volatile union TimerCounter timer1Counter;

  ISR(TIMER1_OVF_vect) {
    if (--timer1Counter.overflowCountdown == 0) {
      timer1Counter.overflowCountdown = 250;
      if (++timer1Counter.intervalCountLo == 0)
        ++timer1Counter.intervalCountHi;
    }
  }

  TimingManager Timing;

  TimingManager::TimingManager() {
    isSetUp_ = false;
  }

  void TimingManager::disableArduinoTimer() {
    bitClear(TIMSK0, TOIE0);
  }

  unsigned long TimingManager::millis() {
    if (!isSetUp_) setup();

    TimerCounter counter;

    uint8_t oldSREG = SREG;
    cli();
    unsigned int extraTicks   = TCNT1;
    if ((TIFR1 & _BV(TOV1)) && extraTicks == 0) extraTicks = 256; // The timer has overflowed, but the interrupt hasn't fired yet.
    counter.overflowCountdown = timer1Counter.overflowCountdown;
    counter.intervalCount     = timer1Counter.intervalCount;
    SREG = oldSREG;
  
    extraTicks += (unsigned int)(250 - counter.overflowCountdown) << 8;
    unsigned int extraMillis = extraTicks/250;
    
    return (counter.intervalCount << 8) + extraMillis;
  }

  void TimingManager::setup() {
    timer1Counter.intervalCount = 0;
    timer1Counter.overflowCountdown = 250;    

    bitSet  (TCCR1B, WGM12); // Put timer 1 in Fast PWM, 8-bit mode.
    bitClear(TCCR1A, WGM11);
    bitSet  (TCCR1A, WGM10);
 
    bitSet  (TIMSK1, TOIE1); // Enable timer 1 overflow interrupts.

    isSetUp_ = true;
  }

};

