#if defined(ARDUINO) && ARDUINO >= 100
  #include "Arduino.h"
#else
  #include "WProgram.h"
#endif

#include <AikoDevices.h>

namespace Aiko {
  namespace Device {
#include "aiko_devices/AikoDeviceBlink.cpp"
#include "aiko_devices/AikoDeviceButton.cpp"
#include "aiko_devices/AikoDevicePotentiometer.cpp"
  }
}
