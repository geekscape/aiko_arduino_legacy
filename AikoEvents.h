#ifndef AikoEvents_h
#define AikoEvents_h

#include "AikoTiming.h"

using namespace std;

namespace Aiko {
  
  struct EventHandler {
    void loop(unsigned int elapsed) {
      if (counter_ <= elapsed) {
        counter_ += interval_;
        (*handler_)();
      }
      counter_ -= elapsed;
    }

    unsigned int interval_;
    void (*handler_)();
    unsigned int counter_;
    struct EventHandler* next_;
  };

  class EventHandlerList {
    public:
      EventHandlerList() { flush(); }
      void add(EventHandler* handler);
      void flush();
      EventHandler* next();
      void remove(EventHandler* handler);
      void resetIterator();

    private:
      EventHandler* firstHandler_;
      EventHandler* nextHandler_;

      EventHandler* handlerBefore(EventHandler* handler);
      EventHandler* last();
  };

  class EventManager {
    public:
      EventManager() { reset(); }
      void addHandler(EventHandler* handler);
      void addHandler(void (*handler)(), unsigned int interval);
      void loop(unsigned long time = Timing.millis());
      void removeHandler(EventHandler* handler);
      void reset();
      
    private:
      void start(unsigned long time);

      bool              isRunning_;
      unsigned long     lastLoopTime_;
      EventHandlerList  handlerList_;
  };
  
  extern EventManager Events;
  
};

#endif
