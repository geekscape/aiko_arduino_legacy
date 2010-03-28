#ifndef AikoDevices_h
#define AikoDevices_h

#ifndef Wiring_h
#include "wiring.h"
#endif

using namespace std;

#define ENABLE_AIKO_DEVICE_BLINK
#define ENABLE_AIKO_DEVICE_BUTTON
#define ENABLE_AIKO_DEVICE_POTENTIOMETER

namespace Aiko {
  namespace Device {
#include "aiko_devices/AikoDeviceBlink.h"
#include "aiko_devices/AikoDeviceButton.h"
#include "aiko_devices/AikoDevicePotentiometer.h"
  }
}

#endif
