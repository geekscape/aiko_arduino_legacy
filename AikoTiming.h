#ifndef AikoTiming_h
#define AikoTiming_h

namespace Aiko {

  class TimingManager {
    public:
      TimingManager();
      void disableArduinoTimer();
      unsigned long millis(void);

    private:
      void setup();

      bool isSetUp_;
  };

  extern TimingManager Timing;

};

#endif

