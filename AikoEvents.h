#ifndef AikoEvents_h
#define AikoEvents_h

namespace Aiko {
  
  struct EventHandler {
    void loop() {
      if (trigger_) {
        trigger_ = false;
        (*handler_)();
      }
    }

    void tick() {
      if (++counter_ == interval_) {
        trigger_ = true;
        counter_ = 0; 
      }
    }

    unsigned int interval_;
    void (*handler_)();
    unsigned int counter_;
    unsigned char trigger_;
  };
  
  class EventManager {
    public:
      EventManager();
      void registerHandler(unsigned int interval, void (*handler)());
      void start();
      void loop();
      void tick();
      
    private:
      int handlerCount_;
      EventHandler handlers_[10];
  };
  
  extern EventManager Events;
  
};

#endif
