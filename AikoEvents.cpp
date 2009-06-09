#include "AikoEvents.h"
#include <wiring.h>

/*
 * TODO
 *
 * - Prevent registering too many handlers.
 * - Add a removeHandler method.
 */
 
namespace Aiko {

  EventManager Events;
  
  EventManager::EventManager() {
    reset();
  }
  
  void EventManager::addHandler(void (*handler)(), unsigned int interval) {
    handlers_[handlerCount_].interval_ = interval;
    handlers_[handlerCount_].handler_  = handler;
    handlers_[handlerCount_].counter_  = 0; 
    handlerCount_++;
  }

  void EventManager::loop() {
    static unsigned long old_time = 0;
    unsigned long new_time = millis();
    if (old_time == 0) old_time = new_time;
    unsigned long elapsed = new_time - old_time;
    for (int i = 0; i < handlerCount_; i++) handlers_[i].loop(elapsed);
    old_time = new_time;
  }

  void EventManager::reset() {
    handlerCount_ = 0;
  }

};
