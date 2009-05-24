#ifndef AikoEvents_h
#define AikoEvents_h

namespace Aiko {
  
  struct EventHandler {
    void loop(unsigned int elapsed) {
      counter_ += elapsed;
      if (counter_ >= interval_) {
        counter_ -= interval_;
        (*handler_)();
      }
    }

    unsigned int interval_;
    void (*handler_)();
    unsigned int counter_;
  };
  
  class EventManager {
    public:
      EventManager();
      void addHandler(void (*handler)(), unsigned int interval);
      void loop();
      
    private:
      int handlerCount_;
      EventHandler handlers_[10];
  };
  
  extern EventManager Events;
  
};

#endif
