#ifndef AikoTiming_h
#define AikoTiming_h

namespace Aiko {

  class TimingManager {
    public:
      TimingManager() { isSetUp_ = false; }
      unsigned long millis(void);
      void disableArduinoTimer();

    private:
      void setup();

      bool isSetUp_;
  };

  extern TimingManager Timing;

};

#endif

