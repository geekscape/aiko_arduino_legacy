#ifndef AikoEvents_h
#define AikoEvents_h

namespace Aiko {
  
  class EventsSingleton {
    public:
      EventsSingleton();
      void registerHandler(unsigned int interval, void (*handler)());
      void runLoop();
      
      void timerHandler();
      
    private:  
      struct Handler {
        unsigned int interval;
        void (*handler)();
        unsigned char trigger;
      };
      
      int handlerCount_;
      Handler handlers_[10];
      
      unsigned char hour_;
      unsigned char minute_;  
      unsigned char second_;
      int  millisecond_;
  };
  
  extern EventsSingleton Events;
  
};

#endif
