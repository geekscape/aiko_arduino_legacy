#ifndef AikoEvents_h
#define AikoEvents_h

#include "AikoTiming.h"
#include "AikoCallback.h"

using namespace std;

namespace Aiko {

  struct EventHandler {
    Callback callback_;
    unsigned int period_;
    long countdown_;
    struct EventHandler* next_;

    void fire() { callback_(); }
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
      void addHandler(void (*handler)(), unsigned int interval, unsigned int delay = 0);
      void addOneShotHandler(void (*handler)(), unsigned int delay);
      void loop(unsigned long time = Timing.millis());
      void removeHandler(EventHandler* handler);
      void reset();

    private:
      void start(unsigned long time);
      void loopRepeatingHandler(EventHandler* handler);
      void loopOneShotHandler(EventHandler* handler);

      bool              isRunning_;
      unsigned long     lastLoopTime_;
      EventHandlerList  handlerList_;
  };

  extern EventManager Events;

};

#endif
