#include "AikoDeviceMCP320x.h"
#include "AikoDeviceSPIBus.h"
#include "Arduino.h"

namespace Aiko {
  namespace Device {

    MCP320x::MCP320x(unsigned char slaveSelectPin) {
      slaveSelectPin_ = slaveSelectPin;
      isSetUp_        = false;
    }

    unsigned int MCP320x::readChannel(unsigned char channel) {
      if (!isSetUp_) setup();

      digitalWrite(slaveSelectPin_, LOW);
      SPIBus.transfer(B00000110 | (channel >> 2));
      unsigned char msb = SPIBus.transfer((channel << 6) & 0xFF) & 0x0F;
      unsigned char lsb = SPIBus.transfer(0);
      digitalWrite(slaveSelectPin_, HIGH);

      return ((unsigned int)msb << 8) | lsb;
    }

    void MCP320x::setup() {
      pinMode(slaveSelectPin_, OUTPUT);
      digitalWrite(slaveSelectPin_, HIGH); // Slave select is active low.
      isSetUp_ = true;
    }
  
  };
};
