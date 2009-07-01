#include "AikoTiming.h"
#include <avr/interrupt.h>
#include <wiring.h>

namespace Aiko {

#if F_CPU == 16000000L
  #define OVERFLOWS_PER_INTERVAL          250
  #define TICKS_PER_MILLISECOND           250
  #define MILLISECONDS_PER_INTERVAL_SHIFT 8
#elif F_CPU == 8000000L
  #define OVERFLOWS_PER_INTERVAL          250
  #define TICKS_PER_MILLISECOND           125
  #define MILLISECONDS_PER_INTERVAL_SHIFT 9
#else
  #error Unsupported clock speed
#endif

  union TimerCounter {
    unsigned long intervalCount;  // Increments on every 250th overflow interrupt,
                                  // which is every 256ms on a 16MHz processor.
                                  // This will wrap around after ~35 years.
    struct {
      unsigned int intervalCountLo, intervalCountHi;
      unsigned char overflowCountdown;  // Decrements on each overflow interrupt.
    };
  };

  static volatile union TimerCounter timer1Counter;

  ISR(TIMER1_OVF_vect) {
    if (--timer1Counter.overflowCountdown == 0) {
      timer1Counter.overflowCountdown = OVERFLOWS_PER_INTERVAL;
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
  
    extraTicks += (unsigned int)(OVERFLOWS_PER_INTERVAL - counter.overflowCountdown) << 8;
    unsigned int extraMillis = extraTicks / TICKS_PER_MILLISECOND;
    
    return (counter.intervalCount << MILLISECONDS_PER_INTERVAL_SHIFT) + extraMillis;
  }

  void TimingManager::setup() {
    timer1Counter.intervalCount = 0;
    timer1Counter.overflowCountdown = OVERFLOWS_PER_INTERVAL;    

    bitSet  (TCCR1B, WGM12); // Put timer 1 in Fast PWM, 8-bit mode.
    bitClear(TCCR1A, WGM11);
    bitSet  (TCCR1A, WGM10);
 
    bitSet  (TIMSK1, TOIE1); // Enable timer 1 overflow interrupts.

    isSetUp_ = true;
  }

};

