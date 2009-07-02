#include "AikoEvents.h"
#include "AikoTiming.h"
#include <stdlib.h>
#include <wiring.h>

namespace Aiko {

  EventManager Events;
 
  EventManager::EventManager() {
    reset();
  }

  void EventManager::addHandler(EventHandler* handler) {
    if (firstHandler_)
      lastHandler()->next_ = handler;
    else
      firstHandler_ = handler;
    handler->next_ = 0;
  }

  EventHandler* EventManager::handlerBefore(EventHandler* handler) {
    EventHandler* previousHandler = firstHandler_;
    while (previousHandler && previousHandler->next_ != handler) previousHandler = previousHandler->next_;
    return previousHandler;
  }

  EventHandler* EventManager::lastHandler() {
    EventHandler* lastHandler = firstHandler_;
    while (lastHandler->next_) lastHandler = lastHandler->next_;
    return lastHandler;
  }

  void EventManager::removeHandler(EventHandler* handler) {
    if (handler == firstHandler_)
      firstHandler_ = handler->next_;
    else
      handlerBefore(handler)->next_ = handler->next_;
    handler->next_ = 0;
  }

  void EventManager::addHandler(void (*handlerFunction)(), unsigned int interval) {
    EventHandler* handler = static_cast<EventHandler*>(malloc(sizeof(EventHandler)));
    handler->interval_ = interval;
    handler->handler_  = handlerFunction;
    handler->counter_  = 0;
    addHandler(handler);
  }

  void EventManager::loop(unsigned long time) {
    if (!isRunning_) start(time);
    unsigned long elapsed = time - lastLoopTime_;
    for (EventHandler* handler = firstHandler_; handler; handler = handler->next_) {
      handler->loop(elapsed);
    }
    lastLoopTime_ = time;
  }

  void EventManager::reset() {
    firstHandler_ = 0;
    isRunning_ = false;
  }

  void EventManager::start(unsigned long time) {
    lastLoopTime_ = time;
    isRunning_ = true;
  }
  
};
