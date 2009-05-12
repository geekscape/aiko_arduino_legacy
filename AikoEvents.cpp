#include "AikoEvents.h"
#include <avr/interrupt.h>
#include <wiring.h>

/*
 * TODO
 *
 * - Prevent registering too many handlers.
 */
 
namespace Aiko {

  EventManager Events;
  
  ISR(TIMER1_OVF_vect) {
    Events.tick();
  }
  
  EventManager::EventManager() {
    handlerCount_ = 0;
  }
  
  void EventManager::registerHandler(unsigned int interval, void (*handler)()) {
    handlers_[handlerCount_].interval_ = interval;
    handlers_[handlerCount_].handler_  = handler;
    handlers_[handlerCount_].counter_  = 0;
    handlers_[handlerCount_].trigger_  = false;    
    handlerCount_++;
  }
  
  void EventManager::start() {
    /*
      The Arduino library uses all 3 of the Atmega168/328 timers to do
      PWM outputs. Each timer handles two outputs. All timers are run
      with a prescale of 64, which means they trigger every 64 * 256 =
      16384 clock cycles, which is a fraction over 1ms.
      
      The overflow interrupt on timer 0 is used for the Arduino to do
      its own real-time calculations.
      
      We hack into timer 1 and put our own interrupt handler on it to
      trigger our handlers.
      
      The only trick we have to pull is to take timer 1 out of phase
      correct mode, which means it'll no longer be quite so good for
      driving servos. (See section 13.9 of the Atmega docs.)
    */
    bitSet  (TCCR1B, WGM12); // Put timer 1 in Fast PWM, 8-bit mode
    bitClear(TCCR1A, WGM11);
    bitSet  (TCCR1A, WGM10);

    bitSet  (TIMSK1, TOIE1); // Enable timer 1 overflow interrupts
  }

  void EventManager::loop() {
    for (int i = 0; i < handlerCount_; i++) handlers_[i].loop();
  }

  void EventManager::tick() {
    for (int i = 0; i < handlerCount_; i++) handlers_[i].tick();
  }

};
