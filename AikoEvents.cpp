#include "AikoEvents.h"
#include <MsTimer2.h>

namespace Aiko {

  EventsSingleton Events;
  
  static void fred(void) {
    Events.timerHandler();
  }
  
  EventsSingleton::EventsSingleton() {
    handlerCount_ = 0;
    hour_ = minute_ = second_ = millisecond_ = 0;

    MsTimer2::set(1, fred);  // 1 millisecond interrupt rate
    MsTimer2::start();
  }
  
  void EventsSingleton::registerHandler(unsigned int interval, void (*handler)()) {
    handlers_[handlerCount_].interval = interval;
    handlers_[handlerCount_].handler  = handler;
    handlers_[handlerCount_].trigger  = false;    
    handlerCount_++;
  }
  
  void EventsSingleton::runLoop() {
    for(;;) {
      for (int i = 0; i < handlerCount_; i++) {
        if (handlers_[i].trigger) {
          handlers_[i].trigger = false;
          (*handlers_[i].handler)();
        }
      }
    }
  }
  
  void EventsSingleton::timerHandler() {
    if ((++ millisecond_) == 1000) {
      millisecond_ = 0;
      if ((++ second_) == 60) {
        second_ = 0;
        if ((++ minute_) == 60) {
          minute_ = 0;
          if ((++ hour_) == 99) hour_ = 0;  // Maximum: 99 hours, 59 minutes, 59 seconds
        }
      }
    }
    
    for (int i = 0; i < handlerCount_; i++) {
      if (millisecond_ % handlers_[i].interval == 0)
        handlers_[i].trigger = true;
    }
  }

};
