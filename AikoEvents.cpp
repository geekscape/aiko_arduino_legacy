#include "AikoEvents.h"
#include "AikoTiming.h"
#include <stdlib.h>
#include <wiring.h>

namespace Aiko {

  /* EventHanderList */

  void EventHandlerList::add(EventHandler* handler) {
    if (firstHandler_)
      last()->next_ = handler;
    else
      firstHandler_ = handler;
    if (!nextHandler_) nextHandler_ = handler;
    handler->next_ = 0;
  }

  void EventHandlerList::flush() {
    firstHandler_ = 0;
    nextHandler_  = 0;
  }

  EventHandler* EventHandlerList::handlerBefore(EventHandler* handler) {
    EventHandler* previousHandler = firstHandler_;
    while (previousHandler && previousHandler->next_ != handler) previousHandler = previousHandler->next_;
    return previousHandler;
  }

  EventHandler* EventHandlerList::last() {
    EventHandler* lastHandler = firstHandler_;
    while (lastHandler->next_) lastHandler = lastHandler->next_;
    return lastHandler;
  }
  
  EventHandler* EventHandlerList::next() {
    EventHandler* handler = nextHandler_;
    if (handler) nextHandler_ = handler->next_;
    return handler;
  }

  void EventHandlerList::remove(EventHandler* handler) {
    if (handler == firstHandler_)
      firstHandler_ = handler->next_;
    else
      handlerBefore(handler)->next_ = handler->next_;
    if (handler == nextHandler_) nextHandler_ = handler->next_;
    handler->next_ = 0;
  }

  void EventHandlerList::resetIterator() {
    nextHandler_    = firstHandler_;
  }


  /* EventManager */

  EventManager Events;
 
  void EventManager::addHandler(EventHandler* handler) {
    handlerList_.add(handler);
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
    handlerList_.resetIterator();
    while (EventHandler* handler = handlerList_.next()) handler->loop(elapsed);
    lastLoopTime_ = time;
  }

  void EventManager::removeHandler(EventHandler* handler) {
    handlerList_.remove(handler);
  }

  void EventManager::reset() {
    handlerList_.flush();
    isRunning_ = false;
  }

  void EventManager::start(unsigned long time) {
    lastLoopTime_ = time;
    isRunning_ = true;
  }
  
};
