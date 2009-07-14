#ifndef AikoDeviceMCP320x_h
#define AikoDeviceMCP320x_h

#include "AikoDeviceSPIBus.h"

namespace Aiko {
  namespace Device {

    class MCP320x {
      public:
        MCP320x(unsigned char slaveSelectPin, SPIBusManager& spiBus_ = SPIBus);
        unsigned int readChannel(unsigned char channel);
      
      private:
        void deselect();
        void select();
        void setup();
  
        SPIBusManager *spiBus_;       
        unsigned char slaveSelectPin_;
        bool          isSetUp_;
    };

  };
};

#endif
