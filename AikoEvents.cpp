#include "AikoEvents.h"
#include <MsTimer2.h>

/*
 * TODO
 *
 * - Prevent registering too many handlers.
 */
 
namespace Aiko {

  EventManager Events;
  
  void eventTimerHandler(void) {
    Events.tick();
  }
  
  EventManager::EventManager() {
    handlerCount_ = 0;

    MsTimer2::set(1, eventTimerHandler);  // 1 millisecond interrupt rate
    MsTimer2::start();
  }

  void EventManager::registerHandler(unsigned int interval, void (*handler)()) {
    handlers_[handlerCount_].interval_ = interval;
    handlers_[handlerCount_].handler_  = handler;
    handlers_[handlerCount_].counter_  = 0;
    handlers_[handlerCount_].trigger_  = false;    
    handlerCount_++;
  }
  
  void EventManager::loop() {
    for (int i = 0; i < handlerCount_; i++) handlers_[i].loop();
  }

  void EventManager::tick() {
    for (int i = 0; i < handlerCount_; i++) handlers_[i].tick();
  }

};
