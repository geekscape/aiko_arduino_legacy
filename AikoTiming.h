#ifndef AikoTiming_h
#define AikoTiming_h

namespace Aiko {

  class TimingManager {
    public:
      void setup(bool disable_arduino_timer = false);
      unsigned long millis(void);
  };

  extern TimingManager Timing;

};

#endif

