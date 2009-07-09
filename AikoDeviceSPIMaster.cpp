#include "AikoDeviceSPIMaster.h"
#include <wiring.h>

#define bitValue(bit, bitValue) ((bitValue) ? (1UL << (bit)) : 0)

namespace Aiko {
  namespace Device {

    SPIMaster::SPIMaster(unsigned char sclkPin, unsigned char misoPin, unsigned char mosiPin) {
       sclkPin_ = sclkPin;
       misoPin_ = misoPin;
       mosiPin_ = mosiPin;
    }

    void SPIMaster::setup() {
      pinMode(mosiPin_, OUTPUT);
      pinMode(misoPin_, INPUT);
      pinMode(sclkPin_, OUTPUT);

      digitalWrite(mosiPin_, LOW);
      digitalWrite(sclkPin_, LOW);
    
      bitClear(SPSR, SPI2X);    // Double SPI Speed      (off)
    
      SPCR = bitValue(SPE,  1)  // SPI Enable            (on)
           | bitValue(SPIE, 0)  // Interrupt Enable      (off)
           | bitValue(DORD, 0)  // Data Order            (MSB first)
           | bitValue(MSTR, 1)  // Master/Slave Select   (master)
           | bitValue(CPOL, 0)  // Clock Polarity        (mode 0)
           | bitValue(CPHA, 0)  // Clock Phase           (mode 0)
           | bitValue(SPR1, 0)  // SPI Clock Rate Select (1/16th of CPU clock)
           | bitValue(SPR0, 1);
    }
    
    unsigned char SPIMaster::transfer(unsigned char output) {
      SPDR = output;
      while (bitRead(SPSR, SPIF) == 0); // FIXME: This can lock us up if we're not careful!
      return SPDR;
    }

  };
};
