#ifndef AikoDevices_h
#define AikoDevices_h

#include "Arduino.h"

using namespace std;

#define EnableAikoDeviceBlink
#define EnableAikoDeviceButton
#define EnableAikoDevicePotentialmeter
#define EnableAikoDeviceTemperatureDS1820

#ifdef EnableAikoDeviceTemperatureDS1820
#include "../OneWire/OneWire.h"
#endif

namespace Aiko {
  namespace Device {
#include "aiko_devices/AikoDeviceBlink.h"
#include "aiko_devices/AikoDeviceButton.h"
#include "aiko_devices/AikoDevicePotentiometer.h"
#include "aiko_devices/AikoDeviceTemperatureDS1820.h"
  }
}

#endif
