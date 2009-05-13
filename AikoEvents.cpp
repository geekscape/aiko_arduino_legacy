#include "AikoEvents.h"
#include <wiring.h>

/*
 * TODO
 *
 * - Prevent registering too many handlers.
 */
 
namespace Aiko {

  EventManager Events;
  
  EventManager::EventManager() {
    handlerCount_ = 0;
  }
  
  void EventManager::registerHandler(unsigned int interval, void (*handler)()) {
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

};
