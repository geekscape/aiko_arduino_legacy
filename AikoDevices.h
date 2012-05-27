#ifndef AikoDevices_h
#define AikoDevices_h

#include "Arduino.h"

using namespace std;

#define EnableAikoDeviceBlink
#define EnableAikoDeviceButton
#define EnableAikoDeviceLCD4096
#define EnableAikoDevicePotentiometer
#define EnableAikoDeviceTemperatureDS1820

#ifdef EnableAikoDeviceTemperatureDS1820
#include "../OneWire/OneWire.h"
#endif

namespace Aiko {
  namespace Device {
#include "aiko_devices/AikoDeviceBlink.h"
#include "aiko_devices/AikoDeviceButton.h"
#include "aiko_devices/AikoDeviceLCD4096.h"
#include "aiko_devices/AikoDevicePotentiometer.h"
#include "aiko_devices/AikoDeviceTemperatureDS1820.h"
  }
}

#endif
