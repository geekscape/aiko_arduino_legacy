#include "AikoDeviceMCP320x.h"
#include <wiring.h>

namespace Aiko {
  namespace Device {

    MCP320x::MCP320x(unsigned char slaveSelectPin, SPIBusManager &spiBus) {
      slaveSelectPin_ = slaveSelectPin;
      spiBus_         = &spiBus;
      isSetUp_        = false;
    }

    void MCP320x::deselect() {
      digitalWrite(slaveSelectPin_, HIGH);
    }
  
    unsigned int MCP320x::readChannel(unsigned char channel) {
      if (!isSetUp_) setup();
      select();
      spiBus_->transfer(B00000110 | (channel >> 2));
      unsigned char msb = spiBus_->transfer((channel << 6) & 0xFF) & 0x0F;
      unsigned char lsb = spiBus_->transfer(0);
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
