#include "AikoDeviceMCP320x.h"
#include "AikoDeviceSPIBus.h"
#include <wiring.h>

namespace Aiko {
  namespace Device {

    MCP320x::MCP320x(unsigned char slaveSelectPin) {
      slaveSelectPin_ = slaveSelectPin;
      isSetUp_        = false;
    }

    void MCP320x::deselect() {
      digitalWrite(slaveSelectPin_, HIGH);
    }
  
    unsigned int MCP320x::readChannel(unsigned char channel) {
      if (!isSetUp_) setup();
      select();
      SPIBus.transfer(B00000110 | (channel >> 2));
      unsigned char msb = SPIBus.transfer((channel << 6) & 0xFF) & 0x0F;
      unsigned char lsb = SPIBus.transfer(0);
      deselect();
      return ((unsigned int)msb << 8) | lsb;
    }

    void MCP320x::select() {
      digitalWrite(slaveSelectPin_, LOW);
    }
  
    void MCP320x::setup() {
      pinMode(slaveSelectPin_, OUTPUT);
      digitalWrite(slaveSelectPin_, HIGH); // Slave select is active low.
      isSetUp_ = true;
    }
  
  };
};
