#ifndef AikoDeviceSPIBus_h
#define AikoDeviceSPIBus_h

namespace Aiko {
  namespace Device {
    
    class SPIBusManager {
      public:
        SPIBusManager(unsigned char sclkPin, unsigned char misoPin, unsigned char mosiPin, unsigned char ssPin);
        unsigned char transfer(unsigned char output);
        
      private:
        void setup();

        bool isSetUp_;
        unsigned char sclkPin_, misoPin_, mosiPin_, ssPin_;
    };

    extern SPIBusManager SPIBus;

  };
};

#endif

