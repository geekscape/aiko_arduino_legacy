#include <AikoDevices.h>

#ifdef EnableAikoDeviceTemperatureDS1820
OneWire oneWire(PIN_ONE_WIRE);  // Maxim DS18B20 temperature sensor
#endif

namespace Aiko {
  namespace Device {
#include "aiko_devices/AikoDeviceBlink.cpp"
#include "aiko_devices/AikoDeviceButton.cpp"
#include "aiko_devices/AikoDeviceLCD4096.cpp"
#include "aiko_devices/AikoDevicePotentiometer.cpp"
#include "aiko_devices/AikoDeviceTemperatureDS1820.cpp"
  }
}
