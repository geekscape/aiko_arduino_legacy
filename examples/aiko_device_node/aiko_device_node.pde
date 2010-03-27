#include <AikoDevices.h>
#include <AikoEvents.h>

using namespace Aiko;
using namespace Device;

void setup() {
  Serial.begin(38400);
  Events.addHandler(nodeHandler, 1000);
}

void loop() {
  Events.loop();
}
