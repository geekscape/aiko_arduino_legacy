#include <AikoDevices.h>
#include <AikoEvents.h>

using namespace Aiko;
using namespace Device;

void setup() {
  Events.addHandler(blinkHandler, 500);
}

void loop() {
  Events.loop();
}
