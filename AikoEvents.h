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

  class EventManager {
    public:
      EventManager();
      void addHandler(EventHandler* handler);
      void addHandler(void (*handler)(), unsigned int interval);
      void loop(unsigned long time = Timing.millis());
      void removeHandler(EventHandler* handler);
      void reset();
      
    private:
      EventHandler* handlerBefore(EventHandler* handler);
      EventHandler* lastHandler();
      void start(unsigned long time);

      bool              isRunning_;
      unsigned long     lastLoopTime_;
      EventHandler*     firstHandler_;
  };
  
  extern EventManager Events;
  
};

#endif
