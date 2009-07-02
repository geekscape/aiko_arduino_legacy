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
  };
  
  class EventManager {
    public:
      EventManager();
      void addHandler(void (*handler)(), unsigned int interval);
      void loop(unsigned long time = Timing.millis());
      void reset();
      
    private:
      void start(unsigned long time);

      bool          isRunning_;
      unsigned long lastLoopTime_;
      int           handlerCount_;
      EventHandler  handlers_[10];
  };
  
  extern EventManager Events;
  
};

#endif
