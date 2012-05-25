#ifndef AikoDevices_h
#define AikoDevices_h

#include "Arduino.h"

using namespace std;

#define ENABLE_AIKO_DEVICE_BLINK
#define ENABLE_AIKO_DEVICE_BUTTON
#define ENABLE_AIKO_DEVICE_POTENTIOMETER
#define ENABLE_AIKO_DEVICE_TEMPERATUREDS1820

#ifdef ENABLE_AIKO_DEVICE_TEMPERATUREDS1820
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
