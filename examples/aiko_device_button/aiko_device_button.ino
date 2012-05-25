#include <OneWire.h>
#include <AikoDevices.h>
#include <AikoEvents.h>

using namespace Aiko;
using namespace Device;

void setup() {
  Serial.begin(38400);

  Events.addHandler(buttonHandler,  100);
  Events.addHandler(outputHandler, 1000);
}

void loop() {
  Events.loop();
}

void outputHandler(void) {
  Serial.println(buttonValue);
}
