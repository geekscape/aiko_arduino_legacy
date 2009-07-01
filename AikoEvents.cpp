#include "AikoEvents.h"
#include "AikoTiming.h"
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

  void EventManager::loop(unsigned long time) {
    if (!isRunning_) start(time);
    unsigned long elapsed = time - lastLoopTime_;
    for (int i = 0; i < handlerCount_; i++) handlers_[i].loop(elapsed);
    lastLoopTime_ = time;
  }

  void EventManager::reset() {
    handlerCount_ = 0;
    isRunning_ = false;
  }

  void EventManager::start(unsigned long time) {
    lastLoopTime_ = time;
    isRunning_ = true;
  }
  
};
