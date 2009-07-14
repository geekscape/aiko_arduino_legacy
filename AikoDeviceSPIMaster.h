#ifndef AikoDeviceSPIMaster_h
#define AikoDeviceSPIMaster_h

namespace Aiko {
  namespace Device {
    
    class SPIMaster {
      public:
        SPIMaster(unsigned char sclkPin = 13, unsigned char misoPin = 12, unsigned char mosiPin = 11, unsigned char ssPin = 12);
        void setup();
        unsigned char transfer(unsigned char output);
        
      private:
        unsigned char sclkPin_, misoPin_, mosiPin_, ssPin_;
    };

  };
};

#endif

