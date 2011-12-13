#include "AikoDeviceSPIBus.h"
#if ARDUINO < 100
#include "wiring.h"
#else
#include "wiring_private.h"
#endif

#define bitValue(bit, bitValue) ((bitValue) ? (1UL << (bit)) : 0)

namespace Aiko {
  namespace Device {

#if defined(__AVR_ATmega168__) || defined(__AVR_ATmega328__)
    SPIBusManager SPIBus(13, 12, 11, 10);
#elif defined(__AVR_ATmega1280__)
    SPIBusManager SPIBus(52, 50, 51, 53);
#endif

    SPIBusManager::SPIBusManager(unsigned char sclkPin, unsigned char misoPin, unsigned char mosiPin, unsigned char ssPin)  {
      sclkPin_ = sclkPin;
      misoPin_ = misoPin;
      mosiPin_ = mosiPin;
      ssPin_   = ssPin;
      isSetUp_ = false;
    }

    void SPIBusManager::setup() {
      pinMode(ssPin_,   OUTPUT);
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

      isSetUp_ = true;
    }
    
    unsigned char SPIBusManager::transfer(unsigned char output) {
      if (!isSetUp_) setup();
      // FIXME: We shouldn't need to set the master flag before each write,
      // but it seems to get pulled low sometimes. There's a danger that
      // it'll get pulled low between the bitSet and SPDR being set, which
      // would cause a lockup.
      // 
      // In theory, as long as we have the SS line set high, the MSTR flag
      // should never be pulled low. I'd love to know why it happens
      // sometimes.
      // 
      // A good safety valve would be to check the MSTR flag in the loop,
      // and bomb out if it's low.
      // bitSet(SPCR, MSTR);
      SPDR = output;
      while (bitRead(SPSR, SPIF) == 0); // FIXME: This can lock us up if we're not careful!
      return SPDR;
    }

  };
};
