#include "AikoDeviceMCP320x.h"
#include "AikoDeviceSPIMaster.h"
#include <wiring.h>

namespace Aiko {
  namespace Device {

    MCP320x::MCP320x(SPIMaster& spiMaster, unsigned char slaveSelectPin) {
      spiMaster_      = &spiMaster;
      slaveSelectPin_ = slaveSelectPin;
    }

    void MCP320x::setup() {
      pinMode(slaveSelectPin_, OUTPUT);
      digitalWrite(slaveSelectPin_, HIGH); // Slave select is active low.
    }
  
    void MCP320x::select() {
      digitalWrite(slaveSelectPin_, LOW);
    }
  
    void MCP320x::deselect() {
      digitalWrite(slaveSelectPin_, HIGH);
    }
  
    unsigned int MCP320x::readChannel(unsigned char channel) {
      select();
      spiMaster_->transfer(B00000110 | (channel >> 2));
      unsigned char msb = spiMaster_->transfer((channel << 6) & 0xFF) & 0xF;
      unsigned char lsb = spiMaster_->transfer(0);
      deselect();
      return ((unsigned int)msb << 8) | lsb;
    }

  };
};
